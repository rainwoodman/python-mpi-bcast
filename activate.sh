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

function bundle-pip {
    $DIRNAME/tar-pip.sh $*
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
        local TMPFILE=`$DIRNAME/tar-dir.sh $*`
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

