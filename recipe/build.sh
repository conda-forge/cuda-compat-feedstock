#!/bin/bash

set -ex

# Install to conda style directories
[[ -d lib64 ]] && mv lib64 lib
mkdir -p ${PREFIX}/cuda-compat

check-glibc compat/*.so.*

cp -vd compat/*.so* ${PREFIX}/cuda-compat/
