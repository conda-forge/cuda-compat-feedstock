#!/bin/bash

CONDA_PREFIX="${CONDA_PREFIX:=$PREFIX}"

# Remove cuda-compat symlinks from ${CONDA_PREFIX}/lib.
for _lib in "${CONDA_PREFIX}/cuda-compat/"*; do
    _link="${CONDA_PREFIX}/lib/$(basename "${_lib}")"
    if [ -L "${_link}" ] && [ "$(readlink "${_link}")" = "${_lib}" ]; then
        rm "${_link}"
    fi
done
unset _lib _link
