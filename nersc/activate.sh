#! /bin/bash

if [[ -n $BASH_VERSION ]]; then
    _SCRIPT_LOCATION=${BASH_SOURCE[0]}
elif [[ -n $ZSH_VERSION ]]; then
    _SCRIPT_LOCATION=${funcstack[1]}
else
    echo "Only bash and zsh are supported"
    return 1
fi

if [ x"$SLURM_JOB_NUM_NODES" == x ]; then
    echo "The script is avalaible from a job script only."
    echo "Use with sbatch (for batch scripts) or salloc (for interactive)."
    return 1
fi

DIRNAME=`dirname ${_SCRIPT_LOCATION}`

source $DIRNAME/../activate.sh /dev/shm/local "srun -n $SLURM_JOB_NUM_NODES"

function __init__ {
    local SHOWTIME=
    if [ "x$1" == "x-t" ]; then
        SHOWTIME=-t
    fi 

    local ANACONDA=
    local NERSCROOT=$DIRNAME/${NERSC_HOST}

    case "$LOADEDMODULES" in
      *2.7-anaconda* )
        ANACONDA=$NERSCROOT/2.7-anaconda
        ;;
      *3.4-anaconda* )
        ANACONDA=$NERSCROOT/3.4-anaconda
        ;;
      * )
        echo "Run module load python/2.7-anaconda first"
        return 1
      ;;
    esac;

    bcast $SHOWTIME $NERSCROOT/system-libraries.tar.gz \
           $ANACONDA/python.tar.gz \
           $ANACONDA/mpi4py.tar.gz \
           $ANACONDA/fitsio.tar.gz

    bcast-userbase
}

__init__ $*
