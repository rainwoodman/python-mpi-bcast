#! /bin/bash

source /project/projectdirs/m779/python-mpi/activate.sh /dev/shm/local "srun -n $SLURM_JOB_NUM_NODES"

function __init__ {
    local SHOWTIME=
    if [ "x$1" == "x-t" ]; then
        SHOWTIME=-t
    fi 
    local NERSCROOT=
    local ANACONDA=

    NERSCROOT=/project/projectdirs/m779/python-mpi/nersc/${NERSC_HOST}

    case "$LOADEDMODULES" in
      *2.7-anaconda* )
        ANACONDA=$NERSCROOT/2.7-anaconda
        ;;
      *3.4-anaconda* )
        ANACONDA=$NERSCROOT/3.4-anaconda
        ;;
    esac;

    bcast $SHOWTIME $NERSCROOT/system-libraries.tar.gz \
           $ANACONDA/python.tar.gz \
           $ANACONDA/mpi4py.tar.gz \
           $ANACONDA/fitsio.tar.gz
}

__init__ $*
