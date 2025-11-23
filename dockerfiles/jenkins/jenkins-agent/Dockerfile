FROM jenkins/inbound-agent:latest-jdk21

USER root

# --- Base tools + deps for terraform/awscli ---
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        unzip \
        jq \
        python3 \
        groff \
        less \
        awscli \
    && rm -rf /var/lib/apt/lists/*

# --- Custom CA for Bitbucket / MinIO / etc. ---
COPY ./certs/atlab-rootCA.crt /usr/local/share/ca-certificates/atlab-rootCA.crt

RUN chmod 644 /usr/local/share/ca-certificates/atlab-rootCA.crt && \
    update-ca-certificates

# Also import CA into JVM truststore (for Java HTTPS, incl. Jenkins remoting if needed)
RUN keytool -importcert -noprompt \
      -alias atlab-rootCA \
      -file /usr/local/share/ca-certificates/atlab-rootCA.crt \
      -keystore "$JAVA_HOME/lib/security/cacerts" \
      -storepass changeit || true

# --- Terraform CLI ---
ARG TERRAFORM_VERSION=1.9.5

RUN curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" \
      -o /tmp/terraform.zip && \
    unzip /tmp/terraform.zip -d /usr/local/bin && \
    chmod +x /usr/local/bin/terraform && \
    rm /tmp/terraform.zip

# QoL
ENV AWS_PAGER=""
ENV TF_PLUGIN_CACHE_DIR="/.terraform.d/plugin-cache"

USER jenkins

