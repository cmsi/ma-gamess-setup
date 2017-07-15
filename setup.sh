#!/bin/sh
. $(dirname $0)/path.sh
test -z $BUILD_DIR && exit 127

rm -rf $BUILD_DIR
set -x

mkdir -p $BUILD_DIR
cp -frp $SCRIPT_DIR/debian $BUILD_DIR
if test $(lsb_release -c -s) = "wheezy"; then
  cp -fp $SCRIPT_DIR/debian7/* $BUILD_DIR/debian
fi
cp -frp $SCRIPT_DIR/files/* $BUILD_DIR
