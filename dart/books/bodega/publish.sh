DIR="$( cd "$( dirname "$0" )" && pwd )"
$DIR/copy_from_drive.sh && /Applications/dart/dart-sdk/bin/dart $DIR/../../bin/build.dart $DIR/bodega.egb && /Applications/dart/dart-sdk/bin/dart2js -v -c --package-root=$DIR/../../packages --out=$DIR/bodega.html.dart.js $DIR/bodega.html.dart && rsync -av -e "ssh -p 2222" $DIR/bodega.html.dart.js* $DIR/index.html filiph@visible.cz:public_html/egamebook.com/test/
