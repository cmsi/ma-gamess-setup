#!/bin/sh
. $(dirname $0)/path.sh
test -z $BUILD_DIR && exit 127

mkdir -p $TARGET_DIR
cd $BUILD_DIR 
case "$(dpkg --print-architecture)" in
    amd64)
        dpkg-buildpackage -us -uc
        mv -f ../${PACKAGE}_$VERSION_BASE*.changes ../${PACKAGE}_$VERSION_BASE*.dsc ../${PACKAGE}_$VERSION_BASE*.tar.* ../${PACKAGE}_$VERSION_BASE*.deb $TARGET_DIR
        ;;
    i386)
        ;;
esac
