#!/bin/sh

set -ex

: ${ARCH:="x86_64"}
: ${LLVM_VERSION:="19.1.6"}
: ${BUILDDIR:=$PWD/build}
: ${OUTDIR:=$BUILDDIR/linux64/${ARCH}/rtlib}

CARCH=$ARCH
case $ARCH in
  arm64)
    CARCH=aarch64
    ;;
esac

rm -rf $OUTDIR
mkdir -p \
	$BUILDDIR \
	$OUTDIR \
  $BUILDDIR/gnupg_llvm

cd $BUILDDIR

# Install build dependencies
apk add -q \
  --cache-dir=$BUILDDIR/.apk-cache \
  cmake \
  make \
  clang19 \
  lld \
  llvm19 \
  python3

# Get sources
fetch() {
  url=$1
  file=$(basename $url)
  if [ ! -f "$file" ]
  then
    wget $url
  fi
}
fetch https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/llvm-project-${LLVM_VERSION}.src.tar.xz
fetch https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/llvm-project-${LLVM_VERSION}.src.tar.xz.sig
fetch https://releases.llvm.org/release-keys.asc

# Import pgp keys
llvm_key_check=$(gpg2 --homedir $BUILDDIR/gnupg_llvm --list-keys | grep tobias || :)
if [ -z $llvm_key_check ]
then
  gpg2 --homedir=$BUILDDIR/gnupg_llvm --import release-keys.asc
fi

# Verify the tarball
gpg2 --homedir=$BUILDDIR/gnupg_llvm --verify llvm-project-${LLVM_VERSION}.src.tar.xz.sig

if [ ! -d "llvm-project-${LLVM_VERSION}.src" ]
then
tar xf llvm-project-${LLVM_VERSION}.src.tar.xz
fi
cd llvm-project-${LLVM_VERSION}.src

# Build compiler-rt
rm -rf build-crt
mkdir -p build-crt
cd build-crt

CC=clang-19 \
CFLAGS="--target=${CARCH}-linux-musl --sysroot=${BUILDDIR}/linux64/${ARCH}/libc -isystem ${BUILDDIR}/linux64/${ARCH}/linux-headers/include" \
CXXFLAGS="--target=${CARCH}-linux-musl --sysroot=${BUILDDIR}/linux64/${ARCH}/libc" \
cmake ../runtimes \
	-DCMAKE_ASM_FLAGS="--target=${CARCH}-linux-musl" \
	-DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
	-DCMAKE_SYSTEM_NAME=Linux \
	-DLLVM_HOST_TRIPLE=${CARCH}-linux-musl \
	-DCOMPILER_RT_DEFAULT_TARGET_TRIPLE=${CARCH}-linux-musl \
	-DLLVM_NATIVE_TOOL_DIR=/usr/bin \
	-DLLVM_ENABLE_RUNTIMES="compiler-rt" \
	-DCMAKE_BUILD_TYPE=Release \
	-DCOMPILER_RT_INCLUDE_TESTS=OFF \
	-DCOMPILER_RT_BUILD_SANITIZERS=OFF \
	-DCOMPILER_RT_BUILD_XRAY=OFF \
	-DCOMPILER_RT_BUILD_LIBFUZZER=OFF \
	-DCOMPILER_RT_BUILD_GWP_ASAN=OFF \
	-DCOMPILER_RT_BUILD_PROFILE=OFF \
	-DCOMPILER_RT_BUILD_CTX_PROFILE=OFF \
	-DCOMPILER_RT_BUILD_MEMPROF=OFF \
	-DCOMPILER_RT_BUILD_ORC=OFF \
	-DCMAKE_VERBOSE_MAKEFILE=ON
make -j
cd ..

# Install in the output dir
rtdir=$OUTDIR/lib/${CARCH}-unknown-linux-musl
mkdir -p $rtdir
mv build-crt/compiler-rt/lib/linux/clang_rt.crtbegin-${CARCH}.o $rtdir/clang_rt.crtbegin.o
mv build-crt/compiler-rt/lib/linux/clang_rt.crtend-${CARCH}.o $rtdir/clang_rt.crtend.o
mv build-crt/compiler-rt/lib/linux/libclang_rt.builtins-${CARCH}.a $rtdir/libclang_rt.builtins.a
