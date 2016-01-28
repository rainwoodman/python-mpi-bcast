# run this script in cori and edison directory

function build {
    module swap python python/$1
    python=`which python`
    anaconda=`dirname $python`/..

    #bash ../../tar-anaconda.sh $1/python.tar.gz $anaconda
    #MPICC=cc bash ../../tar-pip.sh $1/mpi4py.tar.gz mpi4py
    bash ../../tar-pip.sh fitsio.tar.gz https://github.com/esheldon/fitsio/archive/v0.9.8rc2.tar.gz
}

build 2.7-anaconda
build 3.4-anaconda
