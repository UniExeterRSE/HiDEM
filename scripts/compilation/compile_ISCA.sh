# Get the source file path (works for sourced or executed scripts)
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # Resolve symlinks
  DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
ROOT_DIR=${SCRIPT_DIR}/../..

mkdir -p ${ROOT_DIR}/build
cd ${ROOT_DIR}/build

mkdir -p ${ROOT_DIR}/install

#CMAKE_CMD="cmake ../ -DCMAKE_INSTALL_PREFIX=${ROOT_DIR}/install -DCMAKE_TOOLCHAIN_FILE=./scripts/toolchains/HiDEM-ubuntu.cmake -DCMAKE_BUILD_TYPE=Release"
#If you want a debug build instead:
CMAKE_CMD="cmake ../ -DCMAKE_INSTALL_PREFIX=${ROOT_DIR}/install -DCMAKE_TOOLCHAIN_FILE=./scripts/toolchains/HiDEM-ubuntu.cmake -DCMAKE_BUILD_TYPE=Debug"

if ! ${CMAKE_CMD}; then
    echo "Abort..."
    exit 1
fi

make
make install
