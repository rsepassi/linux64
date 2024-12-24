#!/bin/sh

set -ex

./build_libc.sh
./build_kernel.sh
./build_tarball.sh
