#!/bin/bash
# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. All rights reserved.

# Detect whether an NVIDIA driver (libcuda.so.1 + a kernel device node) is
# present in the current environment.  Runs after the compat symlink check (00)
# and before the driver version check (02).  Determines whether GPU functionality
# is at all possible; if not, skips the version check entirely.
#
# Exports:
#   NVIDIA_CPU_ONLY  1 = no usable NVIDIA driver found, 0/unset = driver present

# Check if libcuda.so.1 -- the CUDA driver -- is present in the ld.so cache or in LD_LIBRARY_PATH
_LIBCUDA_FROM_LD_CACHE=$(ldconfig -p | grep libcuda.so.1 || true)
_LIBCUDA_FROM_LD_LIBRARY_PATH=$( ( IFS=: ; for i in ${LD_LIBRARY_PATH}; do ls $i/libcuda.so.1 2>/dev/null | grep -v compat; done) || true)
_LIBCUDA_FOUND="${_LIBCUDA_FROM_LD_CACHE}${_LIBCUDA_FROM_LD_LIBRARY_PATH}"

# Check if /dev/nvidiactl (like on Linux) or /dev/dxg (like on WSL2) or /dev/nvgpu (like on Tegra) is present
_DRIVER_FOUND=$(ls /dev/nvidiactl /dev/dxg /dev/nvgpu 2>/dev/null || true)

# If either is not true, then GPU functionality won't be usable.
if [[ -z "${_LIBCUDA_FOUND}" || -z "${_DRIVER_FOUND}" ]]; then
  echo
  echo "WARNING: The NVIDIA Driver was not detected.  GPU functionality will not be available."
  echo "   Ensure that the NVIDIA kernel-mode driver is installed on the system and that CUDA"
  echo "   device files (e.g. /dev/nvidiactl) are accessible in this environment."
  export NVIDIA_CPU_ONLY=1
fi
unset _LIBCUDA_FROM_LD_CACHE _LIBCUDA_FROM_LD_LIBRARY_PATH _LIBCUDA_FOUND _DRIVER_FOUND
