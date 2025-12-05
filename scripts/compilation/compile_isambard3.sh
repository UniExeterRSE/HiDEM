#!/bin/bash

module purge
module load PrgEnv-cray 2>/dev/null

echo "------------------------------------------------------------------------"
echo "Loaded modules:"
module list 2>&1 | cat
echo "------------------------------------------------------------------------"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR=$(realpath ${SCRIPT_DIR}/../..)

mkdir -p "${ROOT_DIR}/build"
cd "${ROOT_DIR}/build" || exit

mkdir -p "${ROOT_DIR}/install"

# =====================================
# Step 1: Build code using cmake
# =====================================

CMAKE_CMD="cmake ${ROOT_DIR} \
    -DCMAKE_INSTALL_PREFIX=${ROOT_DIR}/install \
    -DCMAKE_TOOLCHAIN_FILE=./scripts/toolchains/HiDEM-isambard3-cray.cmake \
    -DCMAKE_BUILD_TYPE=Release"
#If you want a debug build instead:
#CMAKE_CMD="cmake ${ROOT_DIR} -DCMAKE_INSTALL_PREFIX=${ROOT_DIR}/install -DCMAKE_TOOLCHAIN_FILE=./scripts/toolchains/HiDEM-isambard3-cray.cmake -DCMAKE_BUILD_TYPE=Debug"

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

echo "------------------------------------------------------------------------"
echo "Build completed successfully!"
echo "Installed to: $(realpath ${ROOT_DIR}/install)"
echo "------------------------------------------------------------------------"
