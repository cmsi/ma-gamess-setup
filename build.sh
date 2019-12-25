#!/bin/sh
. $(dirname $0)/path.sh
test -z $BUILD_DIR && exit 127

cd $BUILD_DIR 
dpkg-buildpackage -us -uc
mv -f ../${PACKAGE}_${VERSION}_*.changes ../${PACKAGE}_${VERSION}.changes
mkdir -p $TARGET_DIR
mv -f ../${PACKAGE}_${VERSION}* $TARGET_DIR
