FROM docker.io/hashicorp/terraform:1.5.7

USER root

# Install additional CLI tools needed by your pipelines
RUN apk update && \
    apk add --no-cache \
        ca-certificates \
        bash \
        git \
        curl \
        jq && \
    update-ca-certificates

# Add your custom Root CA
COPY ./certs/atlab-rootCA.crt /usr/local/share/ca-certificates/atlab-rootCA.crt

RUN chmod 644 /usr/local/share/ca-certificates/atlab-rootCA.crt && \
    update-ca-certificates

WORKDIR /workspace

