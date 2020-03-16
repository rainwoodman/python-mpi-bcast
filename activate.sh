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
_PYTHONMPI_OLD_PYTHONUSERBASE=$PYTHONUSERBASE

function bundle-pip {
    $_PYTHONMPIBCASTDIRNAME/tar-pip.sh $*
}

function bundle-anaconda {
    $_PYTHONMPIBCASTDIRNAME/tar-anaconda.sh $*
}

if [[ -n $_PYTHONMPIBCASTBCASTROOT ]]; then
    trap "$_PYTHONMPIBCASTAPRUN rm -rf $_PYTHONMPIBCASTBCASTROOT" EXIT TERM KILL

    # use the correct Python

    export PATH=$_PYTHONMPIBCASTBCASTROOT/bin:$PATH
    # since we use anaconda's relocated python there is no need
    # to worry about other PATH variables.
    # especially LD_LIBRARY_PATH -- anaconda packages shall use the correct rpath anyways.

    # reset PYTHONUSERBASE to avoid looking up home
    export PYTHONUSERBASE=$_PYTHONMPIBCASTBCASTROOT
    # important to make the non-cyclic object/dict deconstruction collective
    export PYTHONHASHSEED=0

    function bcast {
        $_PYTHONMPIBCASTAPRUN $_PYTHONMPIBCASTDIRNAME/bcast -p $_PYTHONMPIBCASTBCASTROOT $* || return 1
    }

    function bcast-userbase {
        local USERBASE=

        if [ -n $_PYTHONMPI_OLD_PYTHONUSERBASE ]; then
            if [ -d $_PYTHONMPI_OLD_PYTHONUSERBASE ]; then
                USERBASE=`mktemp --tmpdir XXXXXXX.tar.gz`
                bundle-anaconda $USERBASE $_PYTHONMPI_OLD_PYTHONUSERBASE
                bcast $USERBASE
                rm $USERBASE
            fi
        fi
    }

    function bcast-pip {
        local FILE=`mktemp --tmpdir XXXXXXX.tar.gz`
        $_PYTHONMPIBCASTDIRNAME/tar-pip.sh $FILE $*
        bcast $FILE
        rm $FILE
    }

    function bcast-dir-pip {
        # workaround https://github.com/pypa/pip/issues/2195
        local DIR=`mktemp -d --tmpdir XXXXXXX`
        (cd $1; python setup.py sdist -d $DIR)
        bcast-pip $DIR/*.tar.gz
        rm -rf $DIR
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

