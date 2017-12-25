#! /bin/bash
sed -e "s;@N@;$1;g" bench.template > bench-$1.slurm
sbatch -p regular bench-$1.slurm
