#!/bin/bash

module purge
module load PrgEnv-cray 2>/dev/null
module load cray-mpich 2>/dev/null

echo "------------------------------------------------------------------------"
echo "Loaded modules:"
module list 2>&1 | cat
echo "------------------------------------------------------------------------"

# Get the source file path (works for sourced or executed scripts)
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # Resolve symlinks
  DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
ROOT_DIR=${SCRIPT_DIR}/../..

mkdir -p "${ROOT_DIR}/build"
cd "${ROOT_DIR}/build" || exit

mkdir -p "${ROOT_DIR}/install"

CMAKE_CMD="cmake ../ -DCMAKE_INSTALL_PREFIX=${ROOT_DIR}/install -DCMAKE_TOOLCHAIN_FILE=./scripts/toolchains/HiDEM-cray.cmake -DCMAKE_BUILD_TYPE=Release"
#If you want a debug build instead:
#CMAKE_CMD="cmake ../ -DCMAKE_INSTALL_PREFIX=${ROOT_DIR}/install -DCMAKE_TOOLCHAIN_FILE=./scripts/toolchains/HiDEM-cray.cmake -DCMAKE_BUILD_TYPE=Debug"

echo "Running: ${CMAKE_CMD}"
if ! ${CMAKE_CMD}; then
    echo "CMake failed. Aborting..."
    exit 1
fi

echo "Building..."
if ! make -j$(nproc); then
    echo "Make failed. Aborting..."
    exit 1
fi

echo "Installing..."
if ! make install; then
    echo "Install failed. Aborting..."
    exit 1
fi

echo "------------------------------------------------------------------------"
echo "Build completed successfully!"
echo "Installed to: $(realpath ${ROOT_DIR}/install)"
echo "------------------------------------------------------------------------"
