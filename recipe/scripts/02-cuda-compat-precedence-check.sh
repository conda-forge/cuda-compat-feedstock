#!/bin/bash
# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. All rights reserved.

# Verifies that the cuda-compat UMD symlink in $CONDA_PREFIX/lib/libcuda.so.1
# exists, resolves into $CONDA_PREFIX/cuda-compat/, and is not shadowed by a
# system libcuda.so.1 earlier in LD_LIBRARY_PATH.  Runs after symlinks are
# created and after scripts 00-01 have confirmed that forward compatibility is
# needed and supported.  A missing or wrong-target symlink is a hard failure;
# LD_LIBRARY_PATH shadowing is a warning only.
#
# Exports:
#   NVIDIA_COMPAT_PRECEDENCE_OK      1 = compat UMD is in place, 0 = not
#   _CUDA_COMPAT_ACTIVATION_FAILED   1 = symlink is missing or resolves to wrong target

export NVIDIA_COMPAT_PRECEDENCE_OK=0

if [ -z "${CONDA_PREFIX}" ]; then
  echo
  echo "WARNING: CONDA_PREFIX is not set; cannot verify cuda-compat driver precedence."
  return 0
fi

_COMPAT_DIR="${CONDA_PREFIX}/cuda-compat"
_LIB_LINK="${CONDA_PREFIX}/lib/libcuda.so.1"

###################################
# 1. Symlink check
###################################

if [ ! -L "${_LIB_LINK}" ]; then
  echo
  echo "WARNING: ${_LIB_LINK} is not a symlink that exists."
  echo "         cuda-compat may not be activated correctly."
  unset _COMPAT_DIR _LIB_LINK
  export _CUDA_COMPAT_ACTIVATION_FAILED=1
  return 0
fi

_RESOLVED=$(readlink -f "${_LIB_LINK}")

if [[ "${_RESOLVED}" != "${_COMPAT_DIR}"/* ]]; then
  echo
  echo "WARNING: ${_LIB_LINK} resolves to ${_RESOLVED}"
  echo "         Expected a path under ${_COMPAT_DIR}"
  echo "         The system driver may take precedence over cuda-compat."
  unset _COMPAT_DIR _LIB_LINK _RESOLVED
  export _CUDA_COMPAT_ACTIVATION_FAILED=1
  return 0
fi

###################################
# 2. LD_LIBRARY_PATH ordering check
###################################

_COMPAT_LIB_DIR="${CONDA_PREFIX}/lib"
_SYSTEM_WINS=0

if [ -n "${LD_LIBRARY_PATH}" ]; then
  IFS=: read -ra _LD_PATHS <<< "${LD_LIBRARY_PATH}"
  for _path in "${_LD_PATHS[@]}"; do
    if [ "${_path}" = "${_COMPAT_LIB_DIR}" ]; then
      break
    fi
    if [ -f "${_path}/libcuda.so.1" ] && [[ "${_path}" != "${CONDA_PREFIX}"* ]]; then
      _SYSTEM_WINS=1
      echo
      echo "WARNING: A system libcuda.so.1 was found in ${_path}"
      echo "         which appears before ${_COMPAT_LIB_DIR} in LD_LIBRARY_PATH."
      echo "         cuda-compat may not take precedence over the system driver."
      break
    fi
  done
  unset _LD_PATHS _path
fi

if [ "${_SYSTEM_WINS}" -eq 0 ]; then
  export NVIDIA_COMPAT_PRECEDENCE_OK=1
fi

unset _COMPAT_DIR _LIB_LINK _RESOLVED _COMPAT_LIB_DIR _SYSTEM_WINS
