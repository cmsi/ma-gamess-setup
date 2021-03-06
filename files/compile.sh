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
if [ "$MD5SUM" = "977a01a8958238c67b707f125999fcec" ]; then
  VERSION="201305"
elif [ "$MD5SUM" = "6403592eaa885cb3691505964d684516" ]; then
  VERSION="201412"
elif [ "$MD5SUM" = "47ef3161ab148acf98a118997825f9a0" ]; then
  VERSION="201608"
elif [ "$MD5SUM" = "e9fa2e725ccbd69f4d996ab68bb65ff2" ]; then
  VERSION="201704"
elif [ "$MD5SUM" = "5a9370ab80a2e9693148d839c324b5ba" ]; then
  VERSION="201802"
elif [ "$MD5SUM" = "4e253a01b8f79526867b2fa8efecebef" ]; then
  VERSION="201809"
elif [ "$MD5SUM" = "b05850e2703a1e48ff5e4b28c9abbd0d" ]; then
  VERSION="201909"
elif [ "$MD5SUM" = "8186b269f5c24b38da2f91c017e0826e" ]; then
  VERSION="202006"
elif [ "$MD5SUM" = "2a0142b5a8eab8f0db8aeae3af940c0d" ]; then
  VERSION="202009"
else
  echo "Warning: unkown version. Let's assume 202006."
fi
echo "GAMESS version = $VERSION"
mkdir -p "$SHAREDIR"
echo "Extracting $SOURCE into $SHAREDIR"
tar zxf "$SOURCE" -C "$SHAREDIR"

# patch to lked
if [ -f "$SCRIPTDIR/lked-$VERSION.patch" ]; then
  echo "Applying patch to lked..."
  patch -i "$SCRIPTDIR/lked-$VERSION.patch" -p 0 -d "$GAMESSDIR"
fi

case "$(dpkg --print-architecture)" in
        amd64)
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
setenv GMS_FORTRAN gfortran
setenv GMS_GFORTRAN_VERNO 4.9
setenv GMS_MATHLIB blas
setenv GMS_MATHLIB_PATH /usr/lib
setenv GMS_DDI_COMM sockets
setenv GMS_LIBCCHEM false
setenv GMS_EIGEN_PATH
setenv GMS_PHI false
setenv GMS_SHMTYPE sysv
setenv GMS_OPENMP false
setenv GMS_FPE_FLAGS -fno-range-check
setenv GMS_MSUCC false
setenv GMS_LIBXC false
EOF
echo "Generating $GAMESSDIR/Makefile"
cat << EOF > "$GAMESSDIR/Makefile"
GMS_PATH = $GAMESSDIR
GMS_VERSION = 00
GMS_BUILD_PATH = $GAMESSDIR
include \$(GMS_PATH)/Makefile.in
EOF

# Generate tools/actvte.x
echo "Generating tools/actvte.x"
sed 's/^\*UNX/    /' "$GAMESSDIR/tools/actvte.code" > "$GAMESSDIR/tools/actvte.f"
gfortran -O2 -o "$GAMESSDIR/tools/actvte.x" "$GAMESSDIR/tools/actvte.f"

# Compile
echo "Compiling GAMESS"
make -C "$GAMESSDIR"

# patch to rungms and install into prefix/bin
if [ -f "$SCRIPTDIR/rungms-$VERSION.patch" ]; then
  echo "Applying patch to rungms..."
  patch -i "$SCRIPTDIR/rungms-$VERSION.patch" -p 0 -d "$GAMESSDIR"
fi
echo "Making symbolic to $PREFIX/bin/rungms"
mkdir -p "$PREFIX/bin"
rm -f "$PREFIX/bin/rungms"
ln -s "$GAMESSDIR/rungms" "$PREFIX/bin/rungms"
echo "Making scratch directory: $HOME/scr"
mkdir -p "$HOME/scr"
echo "Compilation Done"
