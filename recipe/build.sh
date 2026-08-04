#!/bin/bash

set -ex

# Install to conda style directories
[[ -d lib64 ]] && mv lib64 lib
mkdir -p ${PREFIX}/cuda-compat

# The Tegra redistributable unpacks its libraries into compat_orin instead of compat.
COMPAT_DIR="${COMPAT_DIR:-compat}"

check-glibc ${COMPAT_DIR}/*.so*

cp -vd ${COMPAT_DIR}/*.so* ${PREFIX}/cuda-compat/
