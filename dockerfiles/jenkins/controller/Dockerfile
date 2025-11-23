FROM docker.io/jenkins/jenkins:2.528.2-jdk21

USER root

ENV BUILDAH_ISOLATION=chroot
ENV STORAGE_DRIVER=vfs

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        buildah \
        conmon \
        netavark \
        aardvark-dns \
        git \
        jq \
        curl \
        bash; \
    which jq; \
    jq --version; \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/containers && \
    printf '%s\n' \
      '[storage]' \
      'driver = "vfs"' \
      'runroot = "/run/containers/storage"' \
      'graphroot = "/var/lib/containers/storage"' \
      '' \
      '[storage.options]' \
      'mount_program = ""' \
      > /etc/containers/storage.conf

# --- Add and trust atlab-rootCA on OS level ---
COPY ./certs/atlab-rootCA.crt /usr/local/share/ca-certificates/atlab-rootCA.crt

RUN chmod 644 /usr/local/share/ca-certificates/atlab-rootCA.crt && \
    update-ca-certificates

# --- Import CA into JVM truststore for Jenkins / plugins / Git over HTTPS ---
RUN keytool -importcert -noprompt \
      -alias atlab-rootCA \
      -file /usr/local/share/ca-certificates/atlab-rootCA.crt \
      -keystore "$JAVA_HOME/lib/security/cacerts" \
      -storepass changeit || true

USER jenkins

