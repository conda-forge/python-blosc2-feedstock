#!/bin/bash

set -ex

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" == "1" ]]; then
    # When cross-compiling, CMake's FindPython does not wire up the NumPy and
    # Development.Module components on its own. conda-forge's cross-python ships
    # a host interpreter that runs natively on the build machine but reports the
    # *target* configuration, so point FindPython at the interpreter and the
    # target's Python/NumPy headers explicitly. NumPy headers are architecture
    # independent, so the build-env copy is fine.
    # See https://conda-forge.org/docs/maintainer/knowledge_base/#cross-compilation
    Python_INCLUDE_DIR="$(python -c 'import sysconfig; print(sysconfig.get_path("include"))')"
    Python_NumPy_INCLUDE_DIR="$(python -c 'import numpy; print(numpy.get_include())')"
    export CMAKE_ARGS="${CMAKE_ARGS} -DPython_EXECUTABLE=${PYTHON} -DPython_INCLUDE_DIR=${Python_INCLUDE_DIR} -DPython_NumPy_INCLUDE_DIR=${Python_NumPy_INCLUDE_DIR}"
    # export CMAKE_ARGS="${CMAKE_ARGS} -DPython3_EXECUTABLE=${PYTHON} -DPython3_INCLUDE_DIR=${Python_INCLUDE_DIR} -DPython3_NumPy_INCLUDE_DIR=${Python_NumPy_INCLUDE_DIR}"

    if [[ "$(python -c 'import sysconfig; print(sysconfig.get_config_var("Py_GIL_DISABLED") or 0)')" == "1" ]]; then
        # Free-threaded (cp3xxt) cross builds additionally fail because, under
        # CMAKE_CROSSCOMPILING, FindPython refuses to run the target interpreter
        # and so cannot detect the free-threaded ABI. It then rejects the
        # pythonX.Yt headers with:
        #     Could NOT find Python (missing: Interpreter NumPy Development.Module)
        # The host interpreter actually runs natively here, so let FindPython
        # execute it (policy CMP0190) via a no-op "emulator". No QEMU is
        # required, so this works on every cross target, including osx-arm64.
        export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_CROSSCOMPILING_EMULATOR=/usr/bin/env -DCMAKE_POLICY_DEFAULT_CMP0190=NEW"
    fi
fi

${PYTHON} -m pip install . -vv
