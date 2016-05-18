if [ "x$1" == "x-h" ]; then
    echo "$0 path subdirs [ ... ]"
    echo "Create a bundle file for a directory tree starting from path, includes the subdirs only."
    echo "If the total size of the bundle is too big, issue a warning and die."
    exit
fi
DIR=$1
shift
OUTPUT=`mktemp --suffix=.tar.gz`

pushd $DIR

total=`du -s $* | awk '{x += $1} END{print int(x / 1e3)}'`

if [ $total -gt 50 ]; then
    (
    echo "------------------------------------------"
    echo "( $DIR/ $* ) has a total size of $total MiB. Cowardly refusing to create such a large bundle."
    echo "In $DIR "
    du -sh $*
    echo "Possible solutions: "
    echo "1. Remove unnecessary data files in the directory. This is the usual solution. "
    echo "   Refer to the output of command 'du -sh $DIR' "
    echo "2. Properly package the installable package with the bundle command. Do not use the mirror command."
    echo "   The package must conform to the pip packaging standard, with a setup.py file. "
    echo "------------------------------------------"
    ) 1>&2
    exit 1
fi
tar -cf - $* | gzip -9 - > $OUTPUT

popd

echo $OUTPUT
