FROM docker.io/hexpm/elixir:1.20.4-erlang-29.1.1-ubuntu-resolute-20260912

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        # Git / SSH
        git \
        openssh-client \
        ca-certificates \
        # Network / HTTP
        curl \
        wget \
        # Native compilation
        build-essential \
        pkg-config \
        # Archives
        unzip \
        zip \
        # CLI utilities
        jq \
        less \
        tree \
        file \
        rsync \
        # Process / networking diagnostics
        procps \
        psmisc \
        iproute2 \
        iputils-ping \
        dnsutils \
        # Convenience
        sudo \
        zile \
    && rm -rf /var/lib/apt/lists/*

# The Hex.pm Ubuntu image already provides:
#   ubuntu:x:1000:1000:Ubuntu:/home/ubuntu:/bin/bash
#
# Give that user passwordless sudo for development.
RUN echo "ubuntu ALL=(ALL) NOPASSWD:ALL" \
        > /etc/sudoers.d/ubuntu \
    && chmod 0440 /etc/sudoers.d/ubuntu

USER ubuntu

# Install OpenCode as the development user.
RUN curl -fsSL https://opencode.ai/install | bash

ENV PATH="/home/ubuntu/.local/bin:${PATH}"
