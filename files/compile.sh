#!/bin/sh

# Compile script for GAMESS written by Synge Todo

SOURCE="$1"
PREFIX="$2"
PREFIX=`(cd $PREFIX && pwd)`
SCRIPTDIR=`dirname $0`
SCRIPTDIR=`(cd $SCRIPTDIR && pwd)`

if [ -z $PREFIX ]; then
  echo "Usage: $0 source_tarball prefix"
  exit 127
fi

SHAREDIR="$PREFIX/share"
GAMESSDIR="$SHAREDIR/gamess"

if [ -d "$GAMESSDIR" ]; then
  echo "Error: GAMESS directory exists ($GAMESSDIR)"
  exit 127
fi

# Extract files from the tarball
if [ -f "$SOURCE" ]; then :; else
  echo "Error: source not found ($SOURCE)"
  exit 127
fi
MD5SUM=`md5sum "$SOURCE" | awk '{print $1}'`
if [ "$MD5SUM" = "5b019733bd4054cdb27a0d84dbbd5d1a" ]; then
  VERSION="202109"
else
  echo "Warning: unkown version. Let's assume latest version."
  VERSION="latest"
fi
echo "GAMESS version = $VERSION"
mkdir -p "$SHAREDIR"
echo "Extracting $SOURCE into $SHAREDIR"
tar zxf "$SOURCE" -C "$SHAREDIR"

# apply patch
if [ -f "$SCRIPTDIR/gamess-$VERSION.patch" ]; then
  echo "Applying patch..."
  patch -i "$SCRIPTDIR/gamess-$VERSION.patch" -p 1 -d "$GAMESSDIR"
fi

case "$(dpkg --print-architecture)" in
  amd64)
    _TARGET="linux64"
    ;;
  arm64)
    _TARGET="linux64"
    ;;
  i386)
    _TARGET="linux32"
    ;;
esac

# Generate config file
echo "Generating $GAMESSDIR/install.info"
cat << EOF > "$GAMESSDIR/install.info"
setenv GMS_PATH $GAMESSDIR
setenv GMS_BUILD_DIR $GAMESSDIR
setenv GMS_TARGET $_TARGET
setenv GMS_HPC_SYSTEM_TARGET generic
setenv GMS_FORTRAN gfortran
setenv GMS_GFORTRAN_VERNO $(gfortran --version | head -1 | cut -d' ' -f5 | cut -d. -f1,2)
setenv GMS_MATHLIB openblas
setenv GMS_MATHLIB_PATH $(if [ -f /usr/lib/libopenblas.a ]; then echo /usr/lib; else echo /usr/lib/$(arch)-linux-gnu; fi)
setenv GMS_DDI_COMM sockets
setenv GMS_MSUCC             false
setenv GMS_LIBCCHEM          false
setenv GMS_PHI               none
setenv GMS_SHMTYPE           sysv
setenv GMS_OPENMP            false
setenv GMS_LIBXC             false
setenv GMS_MDI               false
setenv  GMS_VM2              false
setenv  TINKER               false
setenv  VB2000               false
setenv  XMVB                 false
setenv  NEO                  false
setenv  NBO                  false
setenv GMS_FPE_FLAGS        ''        
EOF
echo "Generating $GAMESSDIR/Makefile"
cat << EOF > "$GAMESSDIR/Makefile"
GMS_PATH = $GAMESSDIR
GMS_VERSION = 00
GMS_BUILD_PATH = $GAMESSDIR
include \$(GMS_PATH)/Makefile.in
EOF

# Compile
echo "Compiling GAMESS"
make -C "$GAMESSDIR"

# install rngms into prefix/bin
echo "Making symbolic to $PREFIX/bin/rungms"
mkdir -p "$PREFIX/bin"
rm -f "$PREFIX/bin/rungms"
ln -s "$GAMESSDIR/rungms" "$PREFIX/bin/rungms"
echo "Making scratch directory: $HOME/scr"
mkdir -p "$HOME/scr"
echo "Compilation Done"
