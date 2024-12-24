#!/bin/sh

set -ex

: ${ARCH:="x86_64"}
: ${CVERSION:="1.2.5"}
: ${BUILDDIR:=$PWD/build}
: ${OUTDIR:=$BUILDDIR/linux64/${ARCH}/libc}

case $ARCH in
  arm64)
    ARCH=aarch64
    ;;
esac

rm -rf \
  $OUTDIR \
  $BUILDDIR/musl-${CVERSION}

mkdir -p \
  $BUILDDIR/.apk-cache \
  $BUILDDIR/gnupg_libc \
  $OUTDIR

cd $BUILDDIR

# Install build dependencies
apk add -q \
  --cache-dir=$BUILDDIR/.apk-cache \
  gpg \
  gpg-agent \
  clang19 \
  lld \
  llvm19 \
  make

# Get sources
fetch() {
  url=$1
  file=$(basename $url)
  if [ ! -f "$file" ]
  then
    wget $url
  fi
}
fetch https://musl.libc.org/releases/musl-${CVERSION}.tar.gz
fetch https://musl.libc.org/releases/musl-${CVERSION}.tar.gz.asc
fetch https://musl.libc.org/musl.pub

# Import pgp keys
libc_key_check=$(gpg2 --homedir $BUILDDIR/gnupg_libc --list-keys | grep musl || :)
if [ -z $libc_key_check ]
then
  gpg2 --homedir=$BUILDDIR/gnupg_libc --import musl.pub
fi

# Verify the tarball
gpg2 --homedir=$BUILDDIR/gnupg_libc --verify musl-${CVERSION}.tar.gz.asc

tar xf musl-${CVERSION}.tar.gz
cd musl-${CVERSION}

# configure + make
./configure \
  --prefix=$OUTDIR \
  --target=${ARCH}-linux \
  --disable-shared \
  CC=clang \
  AR=llvm-ar \
  RANLIB=llvm-ranlib \
  CFLAGS="--target=${ARCH}-linux-musl"
make -j
make install
