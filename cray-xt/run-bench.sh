#! /bin/bash
sed -e "s;@N@;$1;g" bench.template > bench-$1.job
qsub -q normal bench-$1.job
