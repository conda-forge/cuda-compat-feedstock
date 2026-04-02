#!/bin/bash

# Link cuda-compat libraries into ${CONDA_PREFIX}/lib so they are on the
# default library search path when the environment is active.
mkdir -p "${CONDA_PREFIX}/lib"
for _lib in "${CONDA_PREFIX}/cuda-compat/"*; do
    ln -sf "${_lib}" "${CONDA_PREFIX}/lib/$(basename "${_lib}")"
done
unset _lib
