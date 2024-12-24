#!/bin/sh

set -ex

: ${ARCH:="x86_64"}  # x86_64, arm64, riscv64
: ${BUILDDIR:=$PWD/build}
: ${OUTDIR:=$BUILDDIR/linux64}

tar zcf $OUTDIR/linux64-${ARCH}.tar.gz -C $BUILDDIR linux64/${ARCH}
