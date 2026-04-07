#!/bin/bash

CONDA_PREFIX="${CONDA_PREFIX:=$PREFIX}"

# Remove cuda-compat symlinks from ${CONDA_PREFIX}/lib and ${CONDA_PREFIX}/bin.
for _f in "${CONDA_PREFIX}/cuda-compat/"*; do
    if [[ "${_f}" == *.so.* ]]; then
        _link="${CONDA_PREFIX}/lib/$(basename "${_f}")"
    else
        _link="${CONDA_PREFIX}/bin/$(basename "${_f}")"
    fi
    if [ -L "${_link}" ] && [ "$(readlink "${_link}")" = "${_f}" ]; then
        rm "${_link}"
    fi
done
unset _f _link
