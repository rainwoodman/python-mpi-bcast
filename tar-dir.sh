if [ "x$1" == "x-h" ]; then
    echo "$0 path subdirs [ ... ]"
    exit
fi
DIR=$1
shift
OUTPUT=`mktemp --suffix=.tar.gz`
(
cd $DIR
tar -cf - $* | gzip -9 - > $OUTPUT
)
echo $OUTPUT
