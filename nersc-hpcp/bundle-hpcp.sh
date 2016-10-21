packages=`find /usr/common/contrib/hpcosmo/hpcports_gnu-9.0 -maxdepth 1 -type d`

source /usr/common/contrib/bccp/python-mpi-bcast/activate.sh

for package in $packages; do
    echo $package to `basename $package`.tar.gz 
    bundle-anaconda `basename $package`.tar.gz $package
done
