#! /bin/bash

PREFIX=${NERSC_HOST}

echo "Installing scripts ..."
install -d /usr/common/contrib/bccp/python-mpi-bcast

(
cd ..
install bcast activate.sh tar-pip.sh tar-dir.sh tar-anaconda.sh /usr/common/contrib/bccp/python-mpi-bcast/
)

install -d /usr/common/contrib/bccp/python-mpi-bcast/nersc
install activate.sh /usr/common/contrib/bccp/python-mpi-bcast/nersc/
echo "Installing bundles ..."
rsync --exclude='*.gz-*' -ar $PREFIX /usr/common/contrib/bccp/python-mpi-bcast/nersc/

function tree {
    SEDMAGIC='s;[^/]*/;|____;g;s;____|; |;g'

    if [ "$#" -gt 0 ] ; then
       dirlist="$@"
    else
       dirlist="."
    fi

    for x in $dirlist; do
         find "$x" -printf "%p@%t\n" | sed -e "$SEDMAGIC"|awk -F @ '{printf("%-40s %s\n", $1, $2)}'
    done

}

echo "Done. Tree of files... "
(
cd /usr/common/contrib/bccp/python-mpi-bcast/;
tree nersc/$PREFIX
)
