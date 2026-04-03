#!/bin/bash

set -ex

# Install to conda style directories
[[ -d lib64 ]] && mv lib64 lib
mkdir -p "${PREFIX}/cuda-compat"

check-glibc compat/*.so.*

cp -vd compat/* "${PREFIX}/cuda-compat/"
rm -f "${PREFIX}/cuda-compat/libnvidia-pkcs11-openssl3.so"*

# Copy the [de]activate scripts to $PREFIX/etc/conda/[de]activate.d.
# This will allow them to be run on environment activation.
for CHANGE in "activate" "deactivate"
do
    mkdir -p "${PREFIX}/etc/conda/${CHANGE}.d"
    sed -e "s/@compat_cuda_version@/$COMPAT_CUDA_VERSION/g" \
        -e "s/@compat_drv_version@/$COMPAT_DRV_VERSION/g" \
        -e "s/@supported_kmd_versions@/$SUPPORTED_KMD_VERSIONS/g" \
    "${RECIPE_DIR}/${CHANGE}.sh" > "${PREFIX}/etc/conda/${CHANGE}.d/cuda-compat_${CHANGE}.sh"
done

# Install the numbered activation validation scripts.
mkdir -p "${PREFIX}/etc/cuda-compat"
for _script in "${RECIPE_DIR}"/scripts/*.sh; do
    cp "${_script}" "${PREFIX}/etc/cuda-compat/$(basename "${_script}")"
done
unset _script
