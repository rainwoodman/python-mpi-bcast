if [ "x$1" == "x-h" ]; then
    echo $0 filename.tar.gz  anaconda path
    exit
fi

OUTPUT=`readlink -f $1`
(
cd $2
list=
for dir in bin lib include share; do
    if [ -d $dir ]; then
        list="$list $dir"
    fi
done
tar -cf - \
    --exclude='*.html' \
    --exclude='*.jpg' \
    --exclude='*.jpeg' \
    --exclude='*.png' \
    --exclude='*.pyc' \
    --exclude='*.pyo' \
    $list | gzip -9 - > $OUTPUT
)
