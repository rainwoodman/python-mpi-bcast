if [ "x$1" == "x-h" ]; then
    echo $0 filename.tar.gz  anaconda path
    exit
fi

OUTPUT=`readlink -f $1`
(
cd $2
list=
for dir in bin lib libexec sbin include share etc; do
    if [ -d $dir ]; then
        list="$list $dir"
    fi
done
tar -h --hard-dereference -czf $OUTPUT \
    --exclude='*.jpg' \
    --exclude='*.jpeg' \
    --exclude='*.png' \
    --exclude='*.pyc' \
    --exclude='*.pyo' \
    --exclude='mpl_toolkits/basemap/data/*' \
    --exclude='pandas/io/tests/data/*' \
    --exclude='*.npy' \
    --exclude='*.csv' \
    --exclude='*.dta' \
    --exclude='*.xls' \
    --exclude='*.npz' \
    --exclude='*.mat' \
    --exclude='*.arff' \
    --exclude='*.h5' \
    --exclude='*.ipynb' \
    --exclude='*.svg' \
    $list
)
# black-list readline due to https://github.com/ContinuumIO/anaconda-issues/issues/1701
exit 0
