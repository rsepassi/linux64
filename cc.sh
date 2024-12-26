#!/bin/sh

set -ex

: ${ARCH:="x86_64"}
: ${BUILDDIR:="$PWD/build"}
: ${L64DIR:="$BUILDDIR/linux64/$ARCH"}
: ${OUTDIR:="$BUILDDIR/hello/$ARCH"}

CARCH=$ARCH
case $ARCH in
  arm64)
    CARCH=aarch64
    ;;
esac

[ -d $L64DIR ]

rm -rf $OUTDIR
mkdir -p $OUTDIR

cc() {
  clang \
    --target=$CARCH-linux-musl \
    --sysroot=$L64DIR/libc \
    -isystem $L64DIR/linux-headers \
    $@
}

ccld() {
  clang \
    --target=$CARCH-linux-musl \
    --sysroot=$L64DIR/libc \
    -static \
    -fuse-ld=lld \
    --rtlib=compiler-rt \
    -resource-dir=$L64DIR/rtlib \
    $@ \
    -lc
}

cc -o $OUTDIR/hello.o -c hello.c
ccld -o $OUTDIR/hello $OUTDIR/hello.o
