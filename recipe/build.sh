#!/bin/bash

set -ex

# Install to conda style directories
[[ -d lib64 ]] && mv lib64 lib
mkdir -p "${PREFIX}/cuda-compat"

check-glibc compat/*.so.*

cp -vd compat/* "${PREFIX}/cuda-compat/"

# Copy the [de]activate scripts to $PREFIX/etc/conda/[de]activate.d.
# This will allow them to be run on environment activation.
for CHANGE in "activate" "deactivate"
do
    mkdir -p "${PREFIX}/etc/conda/${CHANGE}.d"
    sed -e "s/@cross_target_platform@/${cross_target_platform:-}/g" \
        -e "s/@arm_variant_target@/${arm_variant_target:-}/g" \
        -e "s/@default_cudaarchs@/$DEFAULT_CUDAARCHS/g" \
        -e "s/@default_nvcc_gencode@/$DEFAULT_NVCC_GENCODE/g" \
    "${RECIPE_DIR}/${CHANGE}.sh" > "${PREFIX}/etc/conda/${CHANGE}.d/cuda-compat_${CHANGE}.sh"
done
