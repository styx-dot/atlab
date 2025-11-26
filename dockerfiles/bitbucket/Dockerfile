FROM docker.io/atlassian/bitbucket-server:8.16.1

USER root

# Copy the CA certificate
COPY ./certs/atlab-rootCA.crt /tmp/atlab-rootCA.crt

# Correct Java truststore for Bitbucket 8.x (Temurin JDK)
ENV JAVA_CACERTS="/opt/java/openjdk/lib/security/cacerts"
ENV CERT_PASS="changeit"

# Bitbucket home truststore
ENV BITBUCKET_HOME="/var/atlassian/application-data/bitbucket"
ENV BITBUCKET_CERTS="${BITBUCKET_HOME}/certs"

RUN set -eux; \
    mkdir -p "$BITBUCKET_CERTS"; \
    \
    # Copy CA into Bitbucket Git truststore directory
    cp /tmp/atlab-rootCA.crt "$BITBUCKET_CERTS/atlab-rootCA.crt"; \
    \
    # Import CA into Bitbucket Git truststore
    keytool -importcert -noprompt \
      -alias atlab-rootCA \
      -file "$BITBUCKET_CERTS/atlab-rootCA.crt" \
      -keystore "$BITBUCKET_CERTS/cacerts" \
      -storepass "$CERT_PASS"; \
    \
    # Import CA into Bitbucket JVM truststore
    keytool -importcert -noprompt \
      -alias atlab-rootCA \
      -file /tmp/atlab-rootCA.crt \
      -keystore "$JAVA_CACERTS" \
      -storepass "$CERT_PASS"; \
    \
    rm -f /tmp/atlab-rootCA.crt

USER bitbucket

