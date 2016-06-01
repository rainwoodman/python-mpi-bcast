#! /bin/bash

APRUN=$2
BCASTROOT=$1

if [[ -n $BASH_VERSION ]]; then
    _SCRIPT_LOCATION=${BASH_SOURCE[0]}
elif [[ -n $ZSH_VERSION ]]; then
    _SCRIPT_LOCATION=${funcstack[1]}
else
    echo "Only bash and zsh are supported"
    return 1
fi

DIRNAME=`dirname ${_SCRIPT_LOCATION}`
DIRNAME=`readlink -f $DIRNAME`

function bundle-pip {
    $DIRNAME/tar-pip.sh $*
}

function bundle-anaconda {
    $DIRNAME/tar-anaconda.sh $*
}

if [[ -n $BCASTROOT ]]; then
    function finish {
        $APRUN rm -rf $BCASTROOT
    }

    trap finish EXIT
    trap finish TERM
    trap finish KILL


    export PYTHONPATH=$BCASTROOT/lib/python
    export PYTHONHOME=$BCASTROOT
    export PYTHONUSERBASE=$BCASTROOT
    export LD_LIBRARY_PATH=$BCASTROOT/lib:$LD_LIBRARY_PATH
    export PATH=$BCASTROOT/bin:$PATH

    function bcast {
        $APRUN $DIRNAME/bcast -p $BCASTROOT $* || return 1
    }

    function mirror {
        # BASH gimmicks: local always return 0
        # http://unix.stackexchange.com/a/146900
        local TMPFILE
        TMPFILE=`$DIRNAME/tar-dir.sh $*`
        if ! [ $? -eq 0 ]; then
            # tar-dir must have failed
            exit 1
        fi
        bcast $TMPFILE
        rm $TMPFILE
    }

    if [[ -n $BASH_VERSION ]]; then
        hash -r
    elif [[ -n $ZSH_VERSION ]]; then
        rehash
    else
        echo "Only bash and zsh are supported"
        return 1
    fi
fi

