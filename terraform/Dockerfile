FROM registry.at-lab.lab/terraform:1.5.7

USER root

COPY atlab-rootCA.crt /usr/local/share/ca-certificates/atlab-rootCA.crt

RUN cat /usr/local/share/ca-certificates/atlab-rootCA.crt >> /etc/ssl/certs/ca-certificates.crt

USER 1000

