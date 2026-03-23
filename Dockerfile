FROM swift:6.0 AS msf-build
WORKDIR /src/swift-msf
COPY Package.swift .
RUN swift package resolve
COPY . .
RUN swift build -c release -Xswiftc -static-stdlib

FROM ubuntu:24.04 AS qclient-build
RUN apt-get update && apt-get install -y --no-install-recommends \
    git cmake g++ make pkg-config libssl-dev ca-certificates python3 python3-venv \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /src
RUN git clone --recurse-submodules -b eof https://github.com/quicr/libquicr.git
WORKDIR /src/libquicr
RUN cmake -Bbuild -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTING=ON -DQUICR_BUILD_TESTS=ON \
    -DQUICR_BUILD_C_BRIDGE=OFF \
    -DLINT=OFF -DUSE_MBEDTLS=OFF . \
    && cmake --build build --parallel $(nproc) --target qclient

FROM ubuntu:24.04
RUN apt-get update && apt-get install -y --no-install-recommends \
    jq libssl3 ca-certificates \
    && rm -rf /var/lib/apt/lists/*
COPY --from=msf-build /src/swift-msf/.build/release/msf-gen /usr/local/bin/msf-gen
COPY --from=qclient-build /src/libquicr/build/cmd/examples/qclient /usr/local/bin/qclient
COPY publish-catalog.sh /usr/local/bin/publish-catalog.sh
RUN chmod +x /usr/local/bin/publish-catalog.sh

ENTRYPOINT ["publish-catalog.sh"]
