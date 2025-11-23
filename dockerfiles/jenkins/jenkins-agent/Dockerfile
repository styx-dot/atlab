FROM docker.io/jenkins/inbound-agent:latest

USER root

ENV DEBIAN_FRONTEND=noninteractive

# --- Base tools + AWS CLI + Terraform from HashiCorp apt repo ---
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
	wget \
        unzip \
        jq \
        python3 \
        groff \
        less \
        awscli \
        gnupg; \
    \
    # Add HashiCorp repo for Debian
    wget -O- https://apt.releases.hashicorp.com/gpg \
      | gpg --dearmor \
      > /usr/share/keyrings/hashicorp-archive-keyring.gpg; \
    \
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(. /etc/os-release && echo \"$VERSION_CODENAME\") main" \
      > /etc/apt/sources.list.d/hashicorp.list; \
    \
    apt-get update; \
    apt-get install -y terraform; \
    \
    rm -rf /var/lib/apt/lists/*


# --- Custom CA for Bitbucket / MinIO / internal services ---
COPY ../../certs/atlab-rootCA.crt /usr/local/share/ca-certificates/atlab-rootCA.crt

RUN chmod 644 /usr/local/share/ca-certificates/atlab-rootCA.crt && \
    update-ca-certificates

# --- Import CA into JVM truststore ---
RUN keytool -importcert -noprompt \
      -alias atlab-rootCA \
      -file /usr/local/share/ca-certificates/atlab-rootCA.crt \
      -keystore "$JAVA_HOME/lib/security/cacerts" \
      -storepass changeit || true

# --- Terraform plugin cache (fixes warnings) ---
ENV TF_PLUGIN_CACHE_DIR="/home/jenkins/.terraform.d/plugin-cache"

RUN mkdir -p /home/jenkins/.terraform.d/plugin-cache && \
    chown -R jenkins:jenkins /home/jenkins/.terraform.d

ENV AWS_PAGER=""

USER jenkins

