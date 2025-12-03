#!/bin/bash

module purge
module load PrgEnv-cray 2>/dev/null
module load cray-mpich 2>/dev/null
module load perftools-base/24.07.0
module load perftools
echo "============================================================"
echo "Modules loaded for cmake compilation:"
module list 2>&1
echo "============================================================"

# Resolve script path
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
ROOT_DIR=${SCRIPT_DIR}/../..

rm -rf "${ROOT_DIR}/build_pat"
mkdir -p "${ROOT_DIR}/build_pat"
cd "${ROOT_DIR}/build_pat" || exit

rm -rf "${ROOT_DIR}/install_pat"
mkdir -p "${ROOT_DIR}/install_pat"

CMAKE_CMD="cmake ../ \
  -DCMAKE_INSTALL_PREFIX=${ROOT_DIR}/install_pat \
  -DCMAKE_TOOLCHAIN_FILE=./scripts/toolchains/HiDEM-cray_pat.cmake \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_FLAGS='-g' \
  -DCMAKE_CXX_FLAGS='-g'"

echo "Running: ${CMAKE_CMD}"
${CMAKE_CMD} || { echo "CMake failed"; exit 1; }

echo "Building..."
make -j$(nproc) || { echo "Make failed"; exit 1; }

echo "Installing..."
make install || { echo "Install failed"; exit 1; }


# =====================================
# Step 2: Load CrayPat instrumentation
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
