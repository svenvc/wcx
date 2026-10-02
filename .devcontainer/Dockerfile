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
        xz-utils \
        p7zip-full \
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

# Zig 0.16.0 exactly, Burrito refuses to build with any other version. Picking
# the tarball from `uname -m` keeps the image usable on Apple Silicon too.
ARG ZIG_VERSION=0.16.0
RUN case "$(uname -m)" in \
        x86_64) zig_arch=x86_64 ;; \
        aarch64) zig_arch=aarch64 ;; \
        *) echo "unsupported architecture: $(uname -m)" >&2; exit 1 ;; \
    esac \
    && curl -fsSL "https://ziglang.org/download/${ZIG_VERSION}/zig-${zig_arch}-linux-${ZIG_VERSION}.tar.xz" -o /tmp/zig.tar.xz \
    && mkdir -p /opt/zig \
    && tar -xf /tmp/zig.tar.xz -C /opt/zig --strip-components=1 \
    && rm /tmp/zig.tar.xz

# The Hex.pm Ubuntu image already provides:
#   ubuntu:x:1000:1000:Ubuntu:/home/ubuntu:/bin/bash
#
# Give that user passwordless sudo for development.
RUN echo "ubuntu ALL=(ALL) NOPASSWD:ALL" \
        > /etc/sudoers.d/ubuntu \
    && chmod 0440 /etc/sudoers.d/ubuntu

USER ubuntu

# Expert, the language server this project uses, see AGENTS.md. The release
# binary is self-contained, so it comes straight from the GitHub release, with
# the published checksum verified. Bump EXPERT_VERSION to update it.
ARG EXPERT_VERSION=v0.1.11
RUN case "$(uname -m)" in \
        x86_64) expert_arch=amd64 ;; \
        aarch64) expert_arch=arm64 ;; \
        *) echo "unsupported architecture: $(uname -m)" >&2; exit 1 ;; \
    esac \
    && mkdir -p "$HOME/.local/bin" \
    && release="https://github.com/expert-lsp/expert/releases/download/${EXPERT_VERSION}" \
    && curl -fsSL "$release/expert_checksums.txt" -o /tmp/expert_checksums.txt \
    && curl -fsSL "$release/expert_linux_${expert_arch}" -o "/tmp/expert_linux_${expert_arch}" \
    && (cd /tmp && grep " \./expert_linux_${expert_arch}\$" expert_checksums.txt | sha256sum -c -) \
    && mv "/tmp/expert_linux_${expert_arch}" "$HOME/.local/bin/expert" \
    && chmod 755 "$HOME/.local/bin/expert" \
    && rm /tmp/expert_checksums.txt

# Install OpenCode as the development user.
RUN curl -fsSL https://opencode.ai/install | bash

# OpenCode lands in ~/.opencode/bin and only writes its PATH line to the shell
# rc file, which the LSP processes and lifecycle hooks never read.
ENV PATH="/opt/zig:/home/ubuntu/.local/bin:/home/ubuntu/.opencode/bin:${PATH}"
