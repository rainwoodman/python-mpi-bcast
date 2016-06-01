#! /bin/bash

#SBATCH -N 1
#SBATCH -p regular
#SBATCH -t 00:10:00

srun -n 1 strace python-mpi -c 'from mpi4py import MPI' &> xc30.trace

grep "= 3$" xc30.trace | grep so | sed -s 's;open(";;' | sed -s 's;".*;;' > filelist

rm -rf lib
mkdir -p lib
srun -n 1 cp `cat filelist` lib/

function backup {
if [ -f $1 ]; then
    local postfix=`stat -c %y $1 | cut -d ' ' --output-delimiter='_' -f1,2`
    mv $1 $1-$postfix
fi
}

backup system-libraries.tar.gz
tar -czvf system-libraries.tar.gz lib/
