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
else
  echo "Error: unkown version or corrupted archive"
  exit 127
fi
echo "GAMESS version = $VERSION"
mkdir -p "$SHAREDIR"
echo "Extracting $SOURCE into $SHAREDIR"
tar zxvf "$SOURCE" -C "$SHAREDIR"

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
setenv GMS_GFORTRAN_VERNO 4.7
setenv GMS_MATHLIB none
setenv GMS_MATHLIB_PATH /usr/lib
setenv GMS_DDI_COMM sockets
setenv GMS_LIBCCHEM false
setenv GMS_EIGEN_PATH
setenv GMS_PHI false
setenv GMS_SHMTYPE sysv
setenv GMS_OPENMP false
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
echo "Compilation Done"
