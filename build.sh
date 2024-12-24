#!/bin/sh

set -ex

: ${KVERSION:-"6.6.67"}
: ${KARCH:-"x86_64"}

# Get sources
mkdir /root/linux64
cd /root/linux64
wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KVERSION}.tar.xz
wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KVERSION}.tar.sign
wget https://www.kernel.org/pub/linux/kernel/v6.x/sha256sums.asc

# Install build dependencies
apk add -q \
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

# Verify the checksums file
gpg2 --locate-keys autosigner@kernel.org
gpg2 --verify sha256sums.asc
rm -rf ~/.gpg

# Verify the checksum
expected_sha=$(grep "linux-${KVERSION}.tar.xz" sha256sums.asc)
actual_sha=$(sha256sum linux-${KVERSION}.tar.xz)
if [ "$expected_sha" != "$actual_sha" ]
then
  exit 1
fi

# Verify the kernel sources
unxz -k linux-${KVERSION}.tar.xz
gpg2 --locate-keys torvalds@kernel.org gregkh@kernel.org
gpg2 --verify linux-${KVERSION}.tar.sign

# Extract the kernel sources
tar xf linux-${KVERSION}.tar
cd linux-${KVERSION}

# Build
kmake() {
	make \
		LLVM=1 \
		ARCH=${KARCH} \
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

kmake defconfig
kmake -j
