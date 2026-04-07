#!/bin/bash

CONDA_PREFIX="${CONDA_PREFIX:=$PREFIX}"
COMPAT_CUDA_VERSION=@compat_cuda_version@
COMPAT_DRV_VERSION=@compat_drv_version@
SUPPORTED_KMD_VERSIONS=@supported_kmd_versions@

_COMPAT_SCRIPT_DIR="${CONDA_PREFIX}/etc/cuda-compat"

# Detect GPU presence and verify KMD version before creating any symlinks.
for _script in \
    "${_COMPAT_SCRIPT_DIR}/00-gpu-driver-check.sh" \
    "${_COMPAT_SCRIPT_DIR}/01-gpu-driver-version-check.sh"; do
    [ -f "${_script}" ] && . "${_script}"
done
unset _script

# If the system driver is newer than the compat UMD, skip activation cleanly.
# (script 01 already printed an explanatory NOTE message.)
if [ "${_CUDA_COMPAT_NOT_NEEDED:-0}" -eq 1 ]; then
    unset _CUDA_COMPAT_NOT_NEEDED _COMPAT_SCRIPT_DIR
    return 0
fi

# If the KMD is unsupported, abort without touching the filesystem.
if [ "${_CUDA_COMPAT_ACTIVATION_FAILED:-0}" -eq 1 ]; then
    echo
    echo "ERROR: cuda-compat activation failed."
    unset _CUDA_COMPAT_ACTIVATION_FAILED _COMPAT_SCRIPT_DIR
    return 0
fi

# KMD is supported (or no GPU detected) — create symlinks into the conda env.
mkdir -p "${CONDA_PREFIX}/lib" "${CONDA_PREFIX}/bin"
for _f in "${CONDA_PREFIX}/cuda-compat/"*; do
    if [[ "${_f}" == *.so.* ]]; then
        ln -sf "${_f}" "${CONDA_PREFIX}/lib/$(basename "${_f}")"
    else
        ln -sf "${_f}" "${CONDA_PREFIX}/bin/$(basename "${_f}")"
    fi
done
unset _f

# Verify that the compat UMD symlinks take precedence over any system libcuda.
[ -f "${_COMPAT_SCRIPT_DIR}/02-cuda-compat-precedence-check.sh" ] && \
    . "${_COMPAT_SCRIPT_DIR}/02-cuda-compat-precedence-check.sh"
unset _COMPAT_SCRIPT_DIR

# If the precedence check failed, undo the symlinks.
if [ "${_CUDA_COMPAT_ACTIVATION_FAILED:-0}" -eq 1 ]; then
    echo
    echo "ERROR: cuda-compat activation failed.  Reverting cuda-compat symlinks."
    for _f in "${CONDA_PREFIX}/cuda-compat/"*; do
        if [[ "${_f}" == *.so.* ]]; then
            _link="${CONDA_PREFIX}/lib/$(basename "${_f}")"
        else
            _link="${CONDA_PREFIX}/bin/$(basename "${_f}")"
        fi
        [ -L "${_link}" ] && [ "$(readlink "${_link}")" = "${_f}" ] && rm "${_link}"
    done
    unset _f _link
fi
unset _CUDA_COMPAT_ACTIVATION_FAILED
