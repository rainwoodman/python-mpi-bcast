#! /bin/bash

#SBATCH -p debug
#SBATCH -t 10:00
#SBATCH -N 2
#SBATCH -J test-python-mpi-bcast
#SBATCH -o test-python-mpi-bcast.log

set -x
module load python
#
# important to wrap in a subshell, since after activate.sh module command is broken.
#
(
module swap python python/2.7-anaconda
module load mpi4py
source ./activate.sh -t
fn=`mktemp XXXXXXXX.py`
cat > $fn <<EOF
 from mpi4py import MPI; import mpi4py; import scipy; print(mpi4py.__version__, MPI.COMM_WORLD.rank, scipy);
EOF
time srun -n 64 python -m mpi4py $fn
rm $fn
)

(
module swap python python/3.5-anaconda
module load mpi4py
source ./activate.sh -t
fn=`mktemp XXXXXXXX.py`
cat > $fn <<EOF
 from mpi4py import MPI; import mpi4py; import scipy; print(mpi4py.__version__, MPI.COMM_WORLD.rank, scipy);
EOF
time srun -n 64 python -m mpi4py $fn
rm $fn
)
