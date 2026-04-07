#!/bin/bash
# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. All rights reserved.

# Detects whether an NVIDIA kernel-mode driver (KMD) is present by checking for
# CUDA device nodes (/dev/nvidiactl on Linux, /dev/dxg on WSL2, /dev/nvgpu on Tegra).
# The user-mode driver (libcuda.so.1) is not checked here because cuda-compat itself
# provides it; a pre-installed system UMD is not required.
# Runs before the KMD version check (01) and before any symlinks are created.
# Sets NVIDIA_CPU_ONLY=1 to skip the version check when no KMD is found.
#
# Exports:
#   NVIDIA_CPU_ONLY  1 = no KMD device node found, 0/unset = KMD present

# Check if /dev/nvidiactl (like on Linux) or /dev/dxg (like on WSL2) or /dev/nvgpu (like on Tegra) is present.
# Device nodes are the canonical indicator of KMD presence; libcuda.so.1 (the UMD) is either
# provided by the system or by cuda-compat itself, so it is not checked here.
_DRIVER_FOUND=$(ls /dev/nvidiactl /dev/dxg /dev/nvgpu 2>/dev/null || true)

if [[ -z "${_DRIVER_FOUND}" ]]; then
  echo
  echo "WARNING: The NVIDIA Driver was not detected.  GPU functionality will not be available."
  echo "   Ensure that the NVIDIA kernel-mode driver is installed on the system and that CUDA"
  echo "   device files (e.g. /dev/nvidiactl) are accessible in this environment."
  export NVIDIA_CPU_ONLY=1
fi
unset _DRIVER_FOUND
