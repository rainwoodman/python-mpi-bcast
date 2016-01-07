if [ "x$1" == "x-h" ]; then
    echo $0 path
    exit
fi

OUTPUT=`mktemp --suffix=.tar.gz`
(
cd $1/..
tar -cf - `basename $1` | gzip -9 - > $OUTPUT
)
echo $OUTPUT
