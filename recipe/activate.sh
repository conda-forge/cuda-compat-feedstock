#!/bin/bash

CONDA_PREFIX="${CONDA_PREFIX:=$PREFIX}"
COMPAT_CUDA_VERSION=@compat_cuda_version@
COMPAT_DRV_VERSION=@compat_drv_version@
SUPPORTED_KMD_VERSIONS=@supported_kmd_versions@

# Link cuda-compat libraries into ${CONDA_PREFIX}/lib so they are on the
# default library search path when the environment is active.
mkdir -p "${CONDA_PREFIX}/lib"
for _lib in "${CONDA_PREFIX}/cuda-compat/"*; do
    ln -sf "${_lib}" "${CONDA_PREFIX}/lib/$(basename "${_lib}")"
done
unset _lib

# Validate compat library precedence and driver compatibility.
_COMPAT_SCRIPT_DIR="${CONDA_PREFIX}/etc/cuda-compat"
for _script in \
    "${_COMPAT_SCRIPT_DIR}/00-cuda-compat-precedence-check.sh" \
    "${_COMPAT_SCRIPT_DIR}/01-gpu-driver-check.sh" \
    "${_COMPAT_SCRIPT_DIR}/02-gpu-driver-version-check.sh"; do
    [ -f "${_script}" ] && . "${_script}"
done
unset _COMPAT_SCRIPT_DIR _script

_remove_cuda_compat_symlinks() {
    for _lib in "${CONDA_PREFIX}/cuda-compat/"*; do
        _link="${CONDA_PREFIX}/lib/$(basename "${_lib}")"
        if [ -L "${_link}" ] && [ "$(readlink "${_link}")" = "${_lib}" ]; then
            rm "${_link}"
        fi
    done
    unset _lib _link
}

# If the system driver is newer than the compat UMD, remove the symlinks silently
# (script 02 already printed an explanatory message).
if [ "${_CUDA_COMPAT_NOT_NEEDED:-0}" -eq 1 ]; then
    _remove_cuda_compat_symlinks
fi
unset _CUDA_COMPAT_NOT_NEEDED

# If any script reported a hard failure, undo the symlinks.
if [ "${_CUDA_COMPAT_ACTIVATION_FAILED:-0}" -eq 1 ]; then
    echo
    echo "ERROR: cuda-compat activation failed.  Reverting cuda-compat symlinks."
    _remove_cuda_compat_symlinks
fi
unset _CUDA_COMPAT_ACTIVATION_FAILED
unset -f _remove_cuda_compat_symlinks
