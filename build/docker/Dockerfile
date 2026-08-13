FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG JAG_VERSION=v1.63.0

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        file \
        git \
        python3 \
        unzip \
        xz-utils \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL "https://github.com/toitlang/jaguar/releases/download/${JAG_VERSION}/jag_linux.tgz" \
    | tar -xz -C /usr/local/bin jag \
    && chmod +x /usr/local/bin/jag

WORKDIR /workspace/lightbug

CMD ["bash"]