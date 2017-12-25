#! /bin/bash
sed -e "s;@N@;$1;g" bench.template > bench-$1.job
qsub -q low bench-$1.job
