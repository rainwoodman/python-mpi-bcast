set -x
export OMP_NUM_THREADS=1

source ./activate.sh /tmp/local "mpirun -n 2"

# send the anaconda packages
bcast -v anaconda.tar.gz 

# location of MPI4PY in /dev/shm/local

time mpirun -n 2 python -c 'from mpi4py import MPI; print(MPI);'
