#! /bin/bash

_PYTHONMPIBCASTAPRUN=$2
_PYTHONMPIBCASTBCASTROOT=$1

if [[ -n $BASH_VERSION ]]; then
    _SCRIPT_LOCATION=${BASH_SOURCE[0]}
elif [[ -n $ZSH_VERSION ]]; then
    _SCRIPT_LOCATION=${funcstack[1]}
else
    echo "Only bash and zsh are supported"
    return 1
fi

_PYTHONMPIBCASTDIRNAME=`dirname ${_SCRIPT_LOCATION}`
_PYTHONMPIBCASTDIRNAME=`readlink -f $_PYTHONMPIBCASTDIRNAME`

function bundle-pip {
    $_PYTHONMPIBCASTDIRNAME/tar-pip.sh $*
}

function bundle-anaconda {
    $_PYTHONMPIBCASTDIRNAME/tar-anaconda.sh $*
}

if [[ -n $_PYTHONMPIBCASTBCASTROOT ]]; then
    trap "$_PYTHONMPIBCASTAPRUN rm -rf $_PYTHONMPIBCASTBCASTROOT" EXIT TERM KILL

    export PYTHONPATH=$_PYTHONMPIBCASTBCASTROOT/lib/python
    export PYTHONHOME=$_PYTHONMPIBCASTBCASTROOT
    export PYTHONUSERBASE=$_PYTHONMPIBCASTBCASTROOT
    export LD_LIBRARY_PATH=$_PYTHONMPIBCASTBCASTROOT/lib:$LD_LIBRARY_PATH
    export PATH=$_PYTHONMPIBCASTBCASTROOT/bin:$PATH

    function bcast {
        $_PYTHONMPIBCASTAPRUN $_PYTHONMPIBCASTDIRNAME/bcast -p $_PYTHONMPIBCASTBCASTROOT $* || return 1
    }

    function mirror {
        # BASH gimmicks: local always return 0
        # http://unix.stackexchange.com/a/146900
        local TMPFILE
        TMPFILE=`$_PYTHONMPIBCASTDIRNAME/tar-dir.sh $*`
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

