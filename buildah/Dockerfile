# Small base image with good compatibility
FROM debian:bookworm-slim

# Become root (implicit in Debian)
USER root

# Install Buildah + deps for rootless operation
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        buildah \
        uidmap \
        fuse-overlayfs \
        slirp4netns \
        iptables && \
    rm -rf /var/lib/apt/lists/*

# Create runtime directories for rootless Buildah
RUN mkdir -p /var/lib/containers/storage && \
    mkdir -p /run/buildah && \
    mkdir -p /workspace && \
    chmod 777 /run/buildah /workspace

# Rootless Buildah environment vars
ENV STORAGE_DRIVER=vfs
ENV BUILDAH_ISOLATION=chroot
ENV XDG_RUNTIME_DIR=/run/buildah
ENV TMPDIR=/workspace

# Create non-root user for Jenkins agent
RUN useradd -m -u 1000 jenkins && \
    chown -R jenkins:jenkins /workspace /var/lib/containers /run/buildah

USER jenkins
WORKDIR /workspace

CMD ["sleep", "infinity"]

