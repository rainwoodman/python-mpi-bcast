#! /bin/bash

#SBATCH -p debug
#SBATCH -t 10:00
#SBATCH -N 2
#SBATCH -J test-python-mpi-bcast
#SBATCH -o test-python-mpi-bcast.log

set -x

#
# important to wrap in a subshell, since after activate.sh module command is broken.
#
(
module swap python python/2.7-anaconda
source ./activate.sh -t
which python-mpi
time srun -n 64 python-mpi -c 'from mpi4py import MPI; import mpi4py; import scipy; print(mpi4py.__version__, MPI.COMM_WORLD.rank, scipy);'
)

(
module swap python python/3.4-anaconda
source ./activate.sh -t
which python-mpi
time srun -n 64 python-mpi -c 'from mpi4py import MPI; import mpi4py; import scipy; print(mpi4py.__version__, MPI.COMM_WORLD.rank, scipy);'
)
