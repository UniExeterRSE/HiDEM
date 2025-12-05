#!/bin/bash

module purge
module load PrgEnv-cray 2>/dev/null
module load perftools-base/24.07.0
module load perftools
echo "============================================================"
echo "Modules loaded for cmake compilation:"
module list 2>&1
echo "============================================================"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR=$(realpath ${SCRIPT_DIR}/../..)

rm -rf "${ROOT_DIR}/build_pat"
mkdir -p "${ROOT_DIR}/build_pat"
cd "${ROOT_DIR}/build_pat" || exit

rm -rf "${ROOT_DIR}/install_pat"
mkdir -p "${ROOT_DIR}/install_pat"

# =====================================
# Step 1: Build code using cmake
# =====================================

CMAKE_CMD="cmake ${ROOT_DIR} \
    -DCMAKE_INSTALL_PREFIX=${ROOT_DIR}/install_pat \
    -DCMAKE_TOOLCHAIN_FILE=./scripts/toolchains/HiDEM-isambard3-cray.cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_FLAGS='-g' \
    -DCMAKE_CXX_FLAGS='-g'"

echo "Running: ${CMAKE_CMD}"
${CMAKE_CMD} || { echo "CMake failed"; exit 1; }

NPROCS=$(nproc 2>/dev/null || echo 4)
echo "Building on ${NPROCS} cores..."
make -j"${NPROCS}" || { echo "Make failed"; exit 1; }

# =====================================
# Step 2: Install executable
# =====================================

echo "Installing..."
make install || { echo "Install failed"; exit 1; }

# =====================================
# Step 3: Instrument using CrayPat 
# =====================================

pat_build -O apa \
    -o ${ROOT_DIR}/install_pat/HiDEM.inst \
    ${ROOT_DIR}/install_pat/HiDEM

echo ""
if [ -x ${ROOT_DIR}/install_pat/HiDEM.inst ]; then
    echo "------------------------------------------------------------------------"
    echo "Instrumentation completed successfully!"
    echo "Instrumented executable:"
    realpath ${ROOT_DIR}/install_pat/HiDEM.inst
    echo "------------------------------------------------------------------------"
else
    echo "ERROR: Instrumentation failed, instrumented executable not found."
    exit 1
fi
