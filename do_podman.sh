#!/bin/sh

set -ex

: ${ARCH:="x86_64"}
: ${KVERSION:="6.6.67"}
: ${CVERSION:="1.2.5"}

if [ $ARCH = "all" ]
then
archs="
arm64
riscv64
x86_64
"
else
archs="
$ARCH
"
fi

for arch in $archs
do
podman run \
  -v $PWD:/root/linux64 \
  --workdir=/root/linux64 \
  --network=host \
  --pids-limit -1 \
  -e ARCH=$arch \
  -e KVERSION=$KVERSION \
  -e CVERSION=$CVERSION \
  alpine:3.21 ./build.sh
done
