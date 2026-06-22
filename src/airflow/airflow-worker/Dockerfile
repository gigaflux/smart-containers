ARG AIRFLOW_VER=3.2.2
ARG PYTHON_VER=3.12
ARG REVISION="unknown"
ARG SHA="unknown"

# Stage 1 - build
FROM apache/airflow:slim-${AIRFLOW_VER}-python${PYTHON_VER} AS builder
ARG AIRFLOW_VER
ARG PYTHON_VER
ARG REVISION
ARG SHA
ARG SPARK_VER=3.5.8
ARG CH_JDBC_VER=0.9.5
ARG CH_SPARK_VER=3.5_2.12
ARG CH_SPARK_RUNTIME_VER=0.10.0
ARG PG_JDBC_VER=42.7.11
ARG MAVEN_URL=https://repo1.maven.org/maven2
ARG CONSTRAINT_URL="https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VER}/constraints-${PYTHON_VER}.txt"

USER root

# update system and install build packets
RUN echo 'Acquire::ForceIPv4 "true";\nAcquire::http::Timeout "5";\nAcquire::https::Timeout "5";\nAcquire::Retries "5";' > /etc/apt/apt.conf.d/99custom-options \
  && apt-get update && apt-get upgrade -y \
  && apt-get update && apt-get install -y --only-upgrade perl perl-base \
  && apt-get update && apt-get install -y --no-install-recommends zip gcc g++ libc6-dev libsasl2-dev libkrb5-dev pkg-config \
  && apt-get autoremove -yqq --purge \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

USER airflow

# download airflow providers
WORKDIR /home/airflow/dist/wheels
RUN python3 -m pip install --no-cache-dir --upgrade pip \
    && python3 -m pip wheel --no-cache-dir "pyspark==${SPARK_VER}" apache-airflow-providers-apache-spark==5.6.0 \
    && python3 -m pip wheel --no-cache-dir "cryptography>=48.0.1" "python-multipart>=0.0.30" "tornado>=6.5.6" \
    && python3 -m pip wheel --no-cache-dir \
    "apache-airflow-providers-common-sql" \
    "apache-airflow-providers-postgres" \
    "apache-airflow-providers-clickhousedb" \
    "apache-airflow-providers-jdbc" \
    "apache-airflow-providers-apache-livy" \
    "apache-airflow-providers-celery" \
    "apache-airflow-providers-git" \
    --constraint "${CONSTRAINT_URL}"

# download jdbc drivers
WORKDIR /home/airflow/dist/jdbc_jars
RUN curl -LO -f "${MAVEN_URL}/com/clickhouse/clickhouse-jdbc/${CH_JDBC_VER}/clickhouse-jdbc-${CH_JDBC_VER}-all.jar" \
    && curl -LO -f "${MAVEN_URL}/com/clickhouse/spark/clickhouse-spark-runtime-${CH_SPARK_VER}/${CH_SPARK_RUNTIME_VER}/clickhouse-spark-runtime-${CH_SPARK_VER}-${CH_SPARK_RUNTIME_VER}.jar" \
    && curl -LO -f "${MAVEN_URL}/org/postgresql/postgresql/${PG_JDBC_VER}/postgresql-${PG_JDBC_VER}.jar"

WORKDIR /home/airflow/dist/spark_jars
# download new hadoop
ARG BUNDLE=hadoop
ARG NEW_VER=3.4.2
RUN for mod in client-runtime client-api yarn-server-web-proxy; do \
      curl -LO -f "${MAVEN_URL}/org/apache/${BUNDLE}/${BUNDLE}-${mod}/${NEW_VER}/${BUNDLE}-${mod}-${NEW_VER}.jar"; \
    done \
    && zip -d "${BUNDLE}-client-runtime-${NEW_VER}.jar" "*/org/eclipse/jetty/*" \
    && zip -d "${BUNDLE}-client-runtime-${NEW_VER}.jar" "META-INF/maven/org.eclipse.jetty*" \
    && zip -d "${BUNDLE}-client-runtime-${NEW_VER}.jar" "META-INF/services/org.apache.hadoop.shaded.org.eclipse.jetty*"

# download new parquet
ARG BUNDLE=parquet
ARG NEW_VER=1.15.2
RUN for mod in common column encoding format-structures hadoop jackson; do \
      curl -LO -f "${MAVEN_URL}/org/apache/${BUNDLE}/${BUNDLE}-${mod}/${NEW_VER}/${BUNDLE}-${mod}-${NEW_VER}.jar"; \
    done

# download new zookeeper
ARG BUNDLE=zookeeper
ARG NEW_VER=3.7.2
RUN curl -LO -f "${MAVEN_URL}/org/apache/${BUNDLE}/${BUNDLE}/${NEW_VER}/${BUNDLE}-${NEW_VER}.jar" \
    && for mod in jute; do \
      curl -LO -f "${MAVEN_URL}/org/apache/${BUNDLE}/${BUNDLE}-${mod}/${NEW_VER}/${BUNDLE}-${mod}-${NEW_VER}.jar"; \
    done

# download new netty
ARG BUNDLE=netty
ARG NEW_VER=4.1.135.Final
RUN for mod in common handler handler-proxy buffer resolver all codec codec-socks codec-http codec-http2 transport transport-classes-kqueue transport-classes-epoll transport-native-unix-common; do \
      curl -LO -f "${MAVEN_URL}/io/${BUNDLE}/${BUNDLE}-${mod}/${NEW_VER}/${BUNDLE}-${mod}-${NEW_VER}.jar"; \
    done \
    && curl -LO -f "${MAVEN_URL}/io/${BUNDLE}/${BUNDLE}-transport-native-epoll/${NEW_VER}/${BUNDLE}-transport-native-epoll-${NEW_VER}-linux-x86_64.jar" \
    && curl -LO -f "${MAVEN_URL}/io/${BUNDLE}/${BUNDLE}-transport-native-kqueue/${NEW_VER}/${BUNDLE}-transport-native-kqueue-${NEW_VER}-osx-x86_64.jar" \
    && curl -LO -f "${MAVEN_URL}/io/${BUNDLE}/${BUNDLE}-transport-native-epoll/${NEW_VER}/${BUNDLE}-transport-native-epoll-${NEW_VER}-linux-aarch_64.jar" \
    && curl -LO -f "${MAVEN_URL}/io/${BUNDLE}/${BUNDLE}-transport-native-kqueue/${NEW_VER}/${BUNDLE}-transport-native-kqueue-${NEW_VER}-osx-aarch_64.jar"

# download new aircompessor
ARG BUNDLE=aircompressor
ARG NEW_VER=2.0.3
RUN curl -LO -f "${MAVEN_URL}/io/airlift/${BUNDLE}/${NEW_VER}/${BUNDLE}-${NEW_VER}.jar"

# download new okhttp
ARG BUNDLE=okhttp
ARG NEW_VER=4.9.3
RUN curl -LO -f "${MAVEN_URL}/com/squareup/okhttp3/${BUNDLE}/${NEW_VER}/${BUNDLE}-${NEW_VER}.jar"

# download new ivy
ARG BUNDLE=ivy
ARG NEW_VER=2.5.3
RUN curl -LO -f "${MAVEN_URL}/org/apache/${BUNDLE}/${BUNDLE}/${NEW_VER}/${BUNDLE}-${NEW_VER}.jar"

# download new gson
ARG BUNDLE=gson
ARG NEW_VER=2.8.9
RUN curl -LO -f "${MAVEN_URL}/com/google/code/${BUNDLE}/${BUNDLE}/${NEW_VER}/${BUNDLE}-${NEW_VER}.jar"

# download new lz4
ARG BUNDLE=lz4-java
ARG NEW_VER=1.10.4
RUN curl -LO -f "${MAVEN_URL}/at/yawk/lz4/${BUNDLE}/${NEW_VER}/${BUNDLE}-${NEW_VER}.jar"

# download new derby
ARG BUNDLE=derby
ARG NEW_VER=10.17.1.0
RUN curl -LO "${MAVEN_URL}/org/apache/${BUNDLE}/${BUNDLE}/${NEW_VER}/${BUNDLE}-${NEW_VER}.jar" \
    && curl -LO -f "${MAVEN_URL}/org/apache/${BUNDLE}/derbyshared/${NEW_VER}/derbyshared-${NEW_VER}.jar"

# Stage 2 - final
FROM apache/airflow:slim-${AIRFLOW_VER}-python${PYTHON_VER}
ARG AIRFLOW_VER
ARG PYTHON_VER
ARG REVISION
ARG SHA
ARG PYSPARK_JARS="/home/airflow/.local/lib/python${PYTHON_VER}/site-packages/pyspark/jars"
LABEL org.opencontainers.image.source="https://github.com/gigaflux/smart-containers"
LABEL org.opencontainers.image.description="Custom Airflow Worker Slim image with Java, pyspark and jdbc drivers"
LABEL org.opencontainers.image.title="Production airflow worker image"
LABEL org.opencontainers.image.url="https://gigaflux.dev"
LABEL org.opencontainers.image.vendor="GigFlux"
LABEL org.opencontainers.image.revision="${REVISION}"
LABEL org.opencontainers.image.authors="dev@gigaflux.dev"
LABEL org.apache.airflow.main-image.commit-sha=""
LABEL org.apache.airflow.main-image.build-id=""
LABEL org.apache.airflow.uid=""
LABEL org.opencontainers.image.commit-sha="${SHA}"
LABEL org.opencontainers.image.documentation="https://github.com/gigaflux/smart-containers"
LABEL org.opencontainers.image.ref.name="airflow-worker"
LABEL org.opencontainers.image.base.name="apache/airflow:${AIRFLOW_VER}-slim-python${PYTHON_VER}"
LABEL org.opencontainers.image.licenses="MIT"

ENV DEBIAN_FRONTEND=noninteractive

USER root
RUN echo 'Acquire::ForceIPv4 "true";\nAcquire::http::Timeout "5";\nAcquire::https::Timeout "5";\nAcquire::Retries "5";' > /etc/apt/apt.conf.d/99custom-options \
    && apt-get update && apt-get upgrade -y \
    && apt-get update && apt-get install -y \
    --only-upgrade perl perl-base \
    && apt-get update && apt-get install -y \
    --no-install-recommends libsasl2-2 libkrb5-3 wget ca-certificates gnupg \
    && mkdir -p /etc/apt/keyrings \
    && wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/adoptium.gpg > /dev/null \
    && echo "deb https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | sudo tee /etc/apt/sources.list.d/adoptium.list \
    && apt-get update && apt-get install -y \
    --no-install-recommends temurin-8-jdk \
    && rm -f /etc/apt/sources.list.d/adoptium.list \
    && rm -f /etc/apt/keyrings/adoptium.asc \
    && apt-get autoremove -yqq --purge wget gnupg "mariadb*" "mysql*" "libmari*" "libmysql*" \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/default-java
RUN JAVA_REAL_PATH=$(ls -d /usr/lib/jvm/temurin-8-jdk-*)  \
    && ln -s ${JAVA_REAL_PATH} ${JAVA_HOME} \
    && chmod 664 /etc/ssl/certs/adoptium/cacerts
ENV PATH=$JAVA_HOME/bin:$PATH
COPY --chown=airflow:root entrypoint.sh /entrypoint.sh
USER airflow

SHELL ["/bin/bash", "-c"]
RUN --mount=type=bind,from=builder,source=/home/airflow/dist,target=/tmp/dist \
    chmod +x /entrypoint.sh \
    && python3 -m pip install --no-cache-dir --upgrade pip \
    && python3 -m pip install --no-cache-dir --no-index --find-links=/tmp/dist/wheels "cryptography>=48.0.1" "python-multipart>=0.0.30" "tornado>=6.5.6" \
    && python3 -m pip install --no-cache-dir --no-index --find-links=/tmp/dist/wheels \
    "apache-airflow-providers-apache-spark==5.6.0" \
    "apache-airflow-providers-common-sql" \
    "apache-airflow-providers-postgres" \
    "apache-airflow-providers-clickhousedb" \
    "apache-airflow-providers-jdbc" \
    "apache-airflow-providers-apache-livy" \
    "apache-airflow-providers-celery" \
    "apache-airflow-providers-git" \
    && cd /tmp/dist/spark_jars \
    && for file in *.jar; do \
      [ -e "$file" ] || continue; \
      NO_EXT="${file%.jar}" \
      && VER="${NO_EXT##*-}" \
      && NAME="${NO_EXT%-*}" \
      && rm -f ${PYSPARK_JARS}/${NAME}-*.jar \
      && cp -f "${file}" "${PYSPARK_JARS}"; \
    done \
    && rm -f "${PYSPARK_JARS}/jackson-core-asl-1.9.13.jar" \
    && rm -f "$PYSPARK_JARS/jackson-mapper-asl-1.9.13.jar" \
    && rm -f "${PYSPARK_JARS}/spark-mesos_2.12-3.5.8.jar" \
    && rm -f "${PYSPARK_JARS}/mesos-1.4.3-shaded-protobuf.jar" \
    && mkdir -p /opt/airflow/jars \
    && cp /tmp/dist/jdbc_jars/*.jar /opt/airflow/jars \
    && rm -rf /home/airflow/.cache/pip


