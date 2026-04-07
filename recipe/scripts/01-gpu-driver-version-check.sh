#!/bin/bash
# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. All rights reserved.

# Determines whether cuda-compat forward compatibility is needed and supported by
# comparing the installed KMD version against the compat UMD version and the set
# of certified KMD versions.  Three outcomes are possible:
#
#   KMD version undetectable   → WARNING; activation proceeds optimistically
#   KMD major >= UMD major     → NOTE; system driver is sufficient; skip activation
#   KMD major in supported set → silent success; forward compat will be active
#   KMD major not in set       → ERROR; KMD is unsupported; activation aborted
#
# KMD version is read from nvidia-smi, with /proc/driver/nvidia/version as fallback.
# Skipped entirely when NVIDIA_CPU_ONLY=1 (set by 00-gpu-driver-check.sh).
# Runs before any symlinks are created so that failures leave no filesystem changes.
#
# Reads:
#   NVIDIA_CPU_ONLY           Skip check if 1 (no driver present)
#   COMPAT_CUDA_VERSION       UMD CUDA version bundled in this package
#   COMPAT_DRV_VERSION        UMD driver version bundled in this package
#   SUPPORTED_KMD_VERSIONS    Comma-separated list of supported KMD major versions
#
# Exports:
#   _CUDA_COMPAT_NOT_NEEDED        1 = KMD >= compat UMD; system driver suffices; activation skipped
#   _CUDA_COMPAT_ACTIVATION_FAILED 1 = KMD is unsupported; activation aborted

if [ "${NVIDIA_CPU_ONLY:-0}" -eq 0 ]; then
  _KMD_VERSION=$(nvidia-smi -i 0 --query-gpu=driver_version --format=csv,noheader 2>/dev/null || true)

  if [[ "${_KMD_VERSION}" == "[N/A]" ]]; then
    _KMD_VERSION=$(sed -n 's/^NVRM.*Kernel Module\( for [a-z0-9_]*\| \) *\([^() ]*\).*$/\2/p' /proc/driver/nvidia/version 2>/dev/null || true)
  fi

  _KMD_VERSION_MAJOR=$(echo "${_KMD_VERSION}" | cut -d. -f1)
  _COMPAT_DRV_MAJOR=$(echo "${COMPAT_DRV_VERSION}" | cut -d. -f1)

  _SUPPORTED=0
  IFS=',' read -ra _SUPPORTED_KMDS <<< "${SUPPORTED_KMD_VERSIONS}"
  for _v in "${_SUPPORTED_KMDS[@]}"; do
    if [[ "${_KMD_VERSION_MAJOR}" -eq "${_v}" ]]; then
      _SUPPORTED=1
      break
    fi
  done
  unset _SUPPORTED_KMDS _v

  if [[ ! "${_KMD_VERSION}" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
    echo
    echo "WARNING: Failed to detect NVIDIA driver version."

  elif [[ "${_KMD_VERSION_MAJOR}" -ge "${_COMPAT_DRV_MAJOR}" ]]; then
    echo
    echo "NOTE: The installed NVIDIA Driver (${_KMD_VERSION}) is at least as new as the cuda-compat"
    echo "      UMD (${COMPAT_DRV_VERSION}).  The system driver is sufficient; cuda-compat will not"
    echo "      be activated.  Ensure the system provides libcuda.so.1 on the library search path."
    export _CUDA_COMPAT_NOT_NEEDED=1

  elif [[ "${_SUPPORTED}" -eq 0 ]]; then
    _SUPPORTED_LIST="${SUPPORTED_KMD_VERSIONS//,/, }"
    _SUPPORTED_LIST="${_SUPPORTED_LIST%, *}, or ${_SUPPORTED_LIST##*, }"
    echo
    echo "ERROR: cuda-compat ${COMPAT_CUDA_VERSION} requires NVIDIA Driver ${_SUPPORTED_LIST}, but"
    echo "       version ${_KMD_VERSION} was detected."
    echo "       Forward compatibility is only available on Tegra Orin and Tesla/data-center GPUs with a"
    echo "       supported driver.  See https://docs.nvidia.com/deploy/cuda-compatibility/"
    unset _SUPPORTED_LIST
    export _CUDA_COMPAT_ACTIVATION_FAILED=1
    sleep 2

  fi

  unset _KMD_VERSION _KMD_VERSION_MAJOR _COMPAT_DRV_MAJOR _SUPPORTED
fi
