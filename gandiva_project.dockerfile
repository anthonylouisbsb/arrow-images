FROM quay.io/pypa/manylinux2014_x86_64 as base_image
WORKDIR /

RUN yum install -y git flex curl autoconf zip wget java-1.8.0-openjdk-devel && yum clean all
ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk/

# Install CMake
ARG cmake=3.20.3
RUN wget -q https://github.com/Kitware/CMake/releases/download/v${cmake}/cmake-${cmake}-Linux-${arch_alias}.tar.gz -O - | \
    tar -xzf - --directory /usr/local --strip-components=1

# Install Ninja
ARG ninja=1.10.2
RUN mkdir /tmp/ninja && \
    wget -q https://github.com/ninja-build/ninja/archive/v${ninja}.tar.gz -O - | \
    tar -xzf - --directory /tmp/ninja --strip-components=1 && \
    cd /tmp/ninja && \
    ./configure.py --bootstrap && \
    mv ninja /usr/local/bin && \
    rm -rf /tmp/ninja

# Install ccache
ARG ccache=4.1
RUN mkdir /tmp/ccache && \
    wget -q https://github.com/ccache/ccache/archive/v${ccache}.tar.gz -O - | \
    tar -xzf - --directory /tmp/ccache --strip-components=1 && \
    cd /tmp/ccache && \
    mkdir build && \
    cd build && \
    cmake -GNinja -DCMAKE_BUILD_TYPE=Release -DZSTD_FROM_INTERNET=ON .. && \
    ninja install && \
    rm -rf /tmp/ccache

RUN git clone https://github.com/apache/arrow.git /arrow

# Install vcpkg
ARG vcpkg
RUN git clone https://github.com/microsoft/vcpkg /opt/vcpkg && \
    git -C /opt/vcpkg checkout ${vcpkg} && \
    /opt/vcpkg/bootstrap-vcpkg.sh -useSystemBinaries -disableMetrics && \
    ln -s /opt/vcpkg/vcpkg /usr/bin/vcpkg && \
    rm -rf /arrow

# Patch ports files as needed
COPY ci/vcpkg arrow/ci/vcpkg
RUN cd /opt/vcpkg && git apply --ignore-whitespace /arrow/ci/vcpkg/ports.patch

ARG build_type=debug
ENV CMAKE_BUILD_TYPE=${build_type} \
    VCPKG_FORCE_SYSTEM_BINARIES=1 \
    VCPKG_OVERLAY_TRIPLETS=/arrow/ci/vcpkg \
    VCPKG_DEFAULT_TRIPLET=x64-linux-static-${build_type} \
    VCPKG_FEATURE_FLAGS=-manifests

# Need to install the boost-build prior installing the boost packages, otherwise
# vcpkg will raise an error.
RUN vcpkg install --clean-after-build \
        boost-build:x64-linux && \
    vcpkg install --clean-after-build \
        abseil \
        aws-sdk-cpp[config,cognito-identity,core,identity-management,s3,sts,transfer] \
        boost-filesystem \
        boost-system \
        boost-date-time \
        boost-regex \
        boost-predef \
        boost-algorithm \
        boost-locale \
        boost-format \
        boost-variant \
        boost-multiprecision \
        brotli \
        bzip2 \
        c-ares \
        curl \
        flatbuffers \
        gflags \
        glog \
        grpc \
        lz4 \
        openssl \
        orc \
        protobuf \
        rapidjson \
        re2 \
        snappy \
        thrift \
        utf8proc \
        zlib \
        zstd \
        llvm[clang,default-options,target-x86,tools]

ARG python=3.8
ENV PYTHON_VERSION=${python}
RUN PYTHON_ROOT=$(find /opt/python -name cp${PYTHON_VERSION/./}-*) && \
    echo "export PATH=$PYTHON_ROOT/bin:\$PATH" >> /etc/profile.d/python.sh

COPY scripts/build_gandiva_jar.sh /

SHELL ["/bin/bash", "-i", "-c"]
ENTRYPOINT ["/bin/bash", "-i", "-c"]