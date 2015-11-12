if [ "x$1" == "-h" ]; then
    echo $0 filename.tar.gz  anaconda path
    exit
fi

OUTPUT=`readlink -f $1`
(
cd $2
tar -czf $OUTPUT \
    --exclude='*.html' \
    --exclude='*.jpg' \
    --exclude='*.jpeg' \
    --exclude='*.png' \
    --exclude='*.pyc' \
    --exclude='*.pyo' \
    bin lib include share
)
