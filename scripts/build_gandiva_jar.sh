#!/bin/bash
set -ex

arrow_dir=${1:-/arrow}
build_dir=${2:-${arrow_dir}/cpp/build}

echo "=== Clear output directories and leftovers ==="
# Clear output directories and leftovers
rm -rf ${build_dir}

echo "=== Building Arrow C++ libraries ==="
: ${ARROW_DATASET:=OFF}
: ${ARROW_GANDIVA:=ON}
: ${ARROW_GANDIVA_JAVA:=ON}
: ${ARROW_FILESYSTEM:=OFF}
: ${ARROW_JEMALLOC:=ON}
: ${ARROW_RPATH_ORIGIN:=ON}
: ${ARROW_ORC:=OFF}
: ${ARROW_PARQUET:=OFF}
: ${ARROW_PLASMA:=OFF}
: ${ARROW_PLASMA_JAVA_CLIENT:=ON}
: ${ARROW_PYTHON:=OFF}
: ${ARROW_BUILD_TESTS:=ON}
: ${CMAKE_BUILD_TYPE:=Debug}
: ${CMAKE_UNITY_BUILD:=ON}
: ${VCPKG_FEATURE_FLAGS:=-manifests}
: ${VCPKG_TARGET_TRIPLET:=${VCPKG_DEFAULT_TRIPLET:-x64-linux-static-${CMAKE_BUILD_TYPE}}}
: ${GANDIVA_CXX_FLAGS:=-isystem;/opt/rh/devtoolset-9/root/usr/include/c++/9;-isystem;/opt/rh/devtoolset-9/root/usr/include/c++/9/x86_64-redhat-linux;-isystem;-lpthread}

export ARROW_TEST_DATA="${arrow_dir}/testing/data"
export PARQUET_TEST_DATA="${arrow_dir}/cpp/submodules/parquet-testing/data"
export AWS_EC2_METADATA_DISABLED=TRUE

pushd "${arrow_dir}"
    git submodule sync && git submodule update --init --recursive --remote
popd 

mkdir -p "${build_dir}"
pushd "${build_dir}"

cmake \
  -DARROW_BOOST_USE_SHARED=OFF \
  -DARROW_BROTLI_USE_SHARED=OFF \
  -DARROW_BUILD_SHARED=ON \
  -DARROW_BUILD_TESTS=${ARROW_BUILD_TESTS} \
  -DARROW_BUILD_UTILITIES=OFF \
  -DARROW_BZ2_USE_SHARED=OFF \
  -DARROW_DATASET=${ARROW_DATASET} \
  -DARROW_DEPENDENCY_SOURCE="VCPKG" \
  -DARROW_FILESYSTEM=${ARROW_FILESYSTEM} \
  -DARROW_GANDIVA_JAVA=${ARROW_GANDIVA_JAVA} \
  -DARROW_GANDIVA_PC_CXX_FLAGS=${GANDIVA_CXX_FLAGS} \
  -DARROW_GANDIVA=${ARROW_GANDIVA} \
  -DARROW_GRPC_USE_SHARED=OFF \
  -DARROW_JEMALLOC=${ARROW_JEMALLOC} \
  -DARROW_JNI=ON \
  -DARROW_LZ4_USE_SHARED=OFF \
  -DARROW_OPENSSL_USE_SHARED=OFF \
  -DARROW_ORC=${ARROW_ORC} \
  -DARROW_PARQUET=${ARROW_PARQUET} \
  -DARROW_PLASMA_JAVA_CLIENT=${ARROW_PLASMA_JAVA_CLIENT} \
  -DARROW_PLASMA=${ARROW_PLASMA} \
  -DARROW_PROTOBUF_USE_SHARED=OFF \
  -DARROW_PYTHON=${ARROW_PYTHON} \
  -DARROW_RPATH_ORIGIN=${ARROW_RPATH_ORIGIN} \
  -DARROW_SNAPPY_USE_SHARED=OFF \
  -DARROW_THRIFT_USE_SHARED=OFF \
  -DARROW_UTF8PROC_USE_SHARED=OFF \
  -DARROW_ZSTD_USE_SHARED=OFF \
  -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DCMAKE_INSTALL_PREFIX=${build_dir} \
  -DCMAKE_UNITY_BUILD=${CMAKE_UNITY_BUILD} \
  -DPARQUET_BUILD_EXAMPLES=OFF \
  -DPARQUET_BUILD_EXECUTABLES=OFF \
  -DPARQUET_REQUIRE_ENCRYPTION=OFF \
  -DPythonInterp_FIND_VERSION_MAJOR=3 \
  -DPythonInterp_FIND_VERSION=ON \
  -DVCPKG_MANIFEST_MODE=OFF \
  -DVCPKG_TARGET_TRIPLET=${VCPKG_TARGET_TRIPLET} \
  -GNinja \
  ${arrow_dir}/cpp
ninja install
popd

java_dir=${arrow_dir}/java
pushd "${java_dir}"
    # build the gandiva jar skipping the unit tests
    mvn clean install -T 2C -P arrow-jni -Darrow.cpp.build.dir=${build_dir} -DskipTests -pl gandiva -amd
popd