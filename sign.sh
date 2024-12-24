#!/bin/sh
set -ex
: ${OUTDIR:=$PWD/build/linux64}
timestamp=$(date --utc +"%Y-%m-%dT%H:%M:%SZ")
minisign -S -t "$timestamp" -m $OUTDIR/*.gz
