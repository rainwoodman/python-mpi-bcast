#! /bin/bash
if [ "x$1" == "x-h" ]; then
    echo $0 filename.tar.gz packages
    exit
fi

OUTPUT=`readlink -f $1`
shift
packages="$*"

DIR=`mktemp -d`

trap "rm -rf $DIR" EXIT

pip install --ignore-installed --no-deps --install-option="--prefix=$DIR" $packages || exit 1

(
cd $DIR
list=
for dir in bin lib include share; do
    if [ -d $dir ]; then
        list="$list $dir"
    fi
done

tar -czf $OUTPUT \
    --exclude='*.html' \
    --exclude='*.jpg' \
    --exclude='*.jpeg' \
    --exclude='*.png' \
    --exclude='*.pyc' \
    --exclude='*.pyo' \
    $list
) || exit 1
echo $OUTPUT created for $packages
