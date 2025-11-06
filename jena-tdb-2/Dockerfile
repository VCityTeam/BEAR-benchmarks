FROM eclipse-temurin:17-jre-jammy

# Install required tooling
RUN apt-get update && \
    apt-get install -y gosu wget tar jq && \
    rm -rf /var/lib/apt/lists/*

# Allow the build to set the runtime user (match host UID/GID if desired)
ARG JENA_USER=jena
ARG JENA_UID=1000
ARG JENA_GID=1000

ENV JENA_USER=${JENA_USER}
ENV JENA_UID=${JENA_UID}
ENV JENA_GID=${JENA_GID}

# Create group/user that will own runtime files
RUN groupadd -g ${JENA_GID} ${JENA_USER} && \
    useradd -u ${JENA_UID} -g ${JENA_GID} -m ${JENA_USER}

# Download and install Apache Jena
ENV JENA_VERSION=5.6.0
ENV JENA_HOME=/opt/apache-jena
ENV PATH=$JENA_HOME/bin:$PATH

RUN wget -q https://dlcdn.apache.org/jena/binaries/apache-jena-${JENA_VERSION}.tar.gz && \
    tar -xzf apache-jena-${JENA_VERSION}.tar.gz && \
    mv apache-jena-${JENA_VERSION} ${JENA_HOME} && \
    rm apache-jena-${JENA_VERSION}.tar.gz && \
    # ensure installed files are owned by the runtime user
    chown -R ${JENA_USER}:${JENA_USER} ${JENA_HOME}

# Set working directory and ensure non-root ownership for data directories
WORKDIR /data
RUN mkdir -p /data/tdb-databases && \
    chown -R ${JENA_USER}:${JENA_USER} /data

# Increase Java heap size for xloader
ENV JVM_ARGS="-Xmx16G"

# Copy entrypoint that fixes ownership on bind mounts before delegating to the runtime user
COPY docker-scripts/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Default command
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/bin/bash"]

