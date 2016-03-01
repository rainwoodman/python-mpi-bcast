#! /bin/bash

if [ x"$SLURM_JOB_NUM_NODES" == x ]; then
    echo "The script is avalaible from a job script only."
    echo "Use with sbatch (for batch scripts) or salloc (for interactive)."
    return 1
fi
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
      * )
        echo "Run module load python/2.7-anaconda first"
        return 1
      ;;
    esac;

    bcast $SHOWTIME $NERSCROOT/system-libraries.tar.gz \
           $ANACONDA/python.tar.gz \
           $ANACONDA/mpi4py.tar.gz \
           $ANACONDA/fitsio.tar.gz
}

__init__ $*
