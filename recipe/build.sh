#!/bin/bash

set -ex

# Install to conda style directories
[[ -d lib64 ]] && mv lib64 lib
mkdir -p ${PREFIX}/cuda-compat

check-glibc compat/*.so.*

cp -vd compat/libcuda.so* ${PREFIX}/cuda-compat/
cp -vd compat/libnvidia-nvvm.so* ${PREFIX}/cuda-compat/
cp -vd compat/libnvidia-ptxjitcompiler.so* ${PREFIX}/cuda-compat/
cp -vd compat/libcudadebugger.so* ${PREFIX}/cuda-compat/
