PYTHON=$1
for i in `seq 20`; do
    mkdir -p /tmp/tmpdir-$i
    export PYTHONPATH=/tmp/tmpdir-$i:$PYTHONPATH
    $PYTHON -c 'import sys;print(len(sys.path))'
    strace -ff -e file $PYTHON -c 'print(0)' |& wc -l
    strace -ff -e file $PYTHON -c 'import numpy' |& wc -l
    strace -ff -e file $PYTHON -c 'import scipy' |& wc -l
    strace -ff -e file $PYTHON -c 'import numba' |& wc -l
    strace -ff -e file $PYTHON -c 'import matplotlib' |& wc -l
done
