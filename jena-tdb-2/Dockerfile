FROM eclipse-temurin:17-jre-jammy

# Install wget and tar
RUN apt-get update && \
    apt-get install -y wget tar jq && \
    rm -rf /var/lib/apt/lists/*

# Download and install Apache Jena
ENV JENA_VERSION=5.6.0
ENV JENA_HOME=/opt/apache-jena
ENV PATH=$JENA_HOME/bin:$PATH

RUN wget -q https://dlcdn.apache.org/jena/binaries/apache-jena-${JENA_VERSION}.tar.gz && \
    tar -xzf apache-jena-${JENA_VERSION}.tar.gz && \
    mv apache-jena-${JENA_VERSION} ${JENA_HOME} && \
    rm apache-jena-${JENA_VERSION}.tar.gz

# Set working directory
WORKDIR /data

# Increase Java heap size for xloader
ENV JVM_ARGS="-Xmx16G"

# Default command
CMD ["/bin/bash"]

