#!/bin/sh

set -ex

: ${ARCH:="x86_64"}
: ${KVERSION:="6.6.67"}
: ${BUILDDIR:=$PWD/build}
: ${OUTDIR:=$BUILDDIR/linux64/${ARCH}}

case "${ARCH}" in
  x86_64)
    kpath=arch/x86/boot/bzImage
    ;;
  arm64)
    kpath=arch/arm64/boot/Image.gz
    ;;
  riscv64)
    ARCH=riscv
    kpath=arch/riscv/boot/Image
    ;;
  *)
    echo "unrecognized kernel arch ${ARCH}"
    exit 1
    ;;
esac

rm -rf \
  $OUTDIR/kernel \
  $OUTDIR/kernel.config \
  $OUTDIR/linux-headers \
  $BUILDDIR/linux-${KVERSION}

mkdir -p \
  $BUILDDIR/.apk-cache \
  $BUILDDIR/gnupg_checksums \
  $BUILDDIR/gnupg_kernel \
  $OUTDIR

cd $BUILDDIR

# Get sources
fetch() {
  url=$1
  file=$(basename $url)
  if [ ! -f "$file" ]
  then
    wget $url
  fi
}
fetch https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KVERSION}.tar.xz
fetch https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KVERSION}.tar.sign
fetch https://www.kernel.org/pub/linux/kernel/v6.x/sha256sums.asc

# Install build dependencies
apk add -q \
  --cache-dir=$BUILDDIR/.apk-cache \
  bison \
  clang19 \
  elfutils-dev \
  flex \
  gpg \
  gpg-agent \
  linux-headers \
  lld \
  llvm19 \
  make \
  musl-dev \
  ncurses-dev \
  openssl-dev \
  perl \
  rsync

# Import pgp keys
checksums_key_check=$(gpg2 --homedir $BUILDDIR/gnupg_checksums --list-keys | grep autosigner || :)
if [ -z $checksums_key_check ]
then
  gpg2 --homedir=$BUILDDIR/gnupg_checksums --locate-keys autosigner@kernel.org
fi
kernel_key_check=$(gpg2 --homedir $BUILDDIR/gnupg_kernel --list-keys | grep gregkh || :)
if [ -z $kernel_key_check ]
then
  gpg2 --homedir=$BUILDDIR/gnupg_kernel --locate-keys torvalds@kernel.org gregkh@kernel.org
fi

# Verify the checksums file
gpg2 --homedir=$BUILDDIR/gnupg_checksums --verify sha256sums.asc

# Verify the checksum
expected_sha=$(grep "linux-${KVERSION}.tar.xz" sha256sums.asc)
actual_sha=$(sha256sum linux-${KVERSION}.tar.xz)
if [ "$expected_sha" != "$actual_sha" ]
then
  exit 1
fi

# Verify the kernel sources
if [ ! -f "linux-${KVERSION}.tar" ]
then
  unxz -k linux-${KVERSION}.tar.xz
fi
gpg2 --homedir=$BUILDDIR/gnupg_kernel --verify linux-${KVERSION}.tar.sign

# Extract the kernel sources
if [ ! -d "linux-${KVERSION}" ]
then
tar xf linux-${KVERSION}.tar
fi
cd linux-${KVERSION}

# Build
kmake() {
	make \
		LLVM=1 \
		ARCH=${ARCH} \
		CC=clang \
		LD=ld.lld \
		AR=llvm-ar \
		NM=llvm-nm \
		STRIP=llvm-strip \
		OBJCOPY=llvm-objcopy \
		OBJDUMP=llvm-objdump \
		READELF=llvm-readelf \
		HOSTCC=clang \
		HOSTCXX=clang++ \
		HOSTAR=llvm-ar \
		HOSTLD=ld.lld \
		$@
}

kmake clean
kmake defconfig
kmake -j
kmake -j headers_install INSTALL_HDR_PATH=$OUTDIR/linux-headers

cp $BUILDDIR/linux-${KVERSION}/.config $OUTDIR/kernel.config
mv $BUILDDIR/linux-${KVERSION}/$kpath $OUTDIR/kernel
