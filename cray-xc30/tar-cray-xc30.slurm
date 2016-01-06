#! /bin/bash

#SBATCH -N 1
#SBATCH -p debug
#SBATCH -t 00:10:00

srun -n 1 strace python-mpi -c 'from mpi4py import MPI' &> xc30.trace

grep "= 3$" xc30.trace | grep so | sed -s 's;open(";;' | sed -s 's;".*;;' > filelist

rm -rf lib
mkdir -p lib

srun -n 1 cp `cat filelist` lib/
tar -czvf cray-xc30.tar.gz lib/
