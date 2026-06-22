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
ARG CONSTRAINT_URL="https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VER}/constraints-${PYTHON_VER}.txt"

USER root

RUN echo 'Acquire::ForceIPv4 "true";\n\
Acquire::http::Timeout "5";\n\
Acquire::https::Timeout "5";\n\
Acquire::Retries "5";\n\
Acquire::AllowInsecureRepositories "true";\n\
Acquire::AllowUnauthenticated "true";\n\
APT::Get::AllowUnauthenticated "true";' > /etc/apt/apt.conf.d/99custom-options

# update system and install build packets
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
  apt-get update && apt-get upgrade -y \
  && apt-get update && apt-get install -y --no-install-recommends --only-upgrade perl perl-base \
  && apt-get update && apt-get install -y --no-install-recommends gcc g++ libc6-dev libsasl2-dev libkrb5-dev pkg-config
  #&& apt-get autoremove -yqq --purge \
  #&& apt-get clean \
  #&& rm -rf /var/lib/apt/lists/*

USER airflow

# download airflow providers
WORKDIR /home/airflow/dist/wheels
RUN python3 -m pip install --no-cache-dir --upgrade pip \
    && python3 -m pip wheel --no-cache-dir --no-deps "apache-airflow-providers-apache-spark==5.6.0" \
    && python3 -m pip wheel --no-cache-dir "cryptography>=48.0.1" "python-multipart>=0.0.30" "tornado>=6.5.6" \
    && python3 -m pip wheel --no-cache-dir \
    "apache-airflow-providers-common-sql" \
    "apache-airflow-providers-postgres" \
    "apache-airflow-providers-oracle" \
    "apache-airflow-providers-clickhousedb" \
    "apache-airflow-providers-jdbc" \
    "apache-airflow-providers-apache-livy" \
    "apache-airflow-providers-celery" \
    "apache-airflow-providers-git" \
    --constraint "${CONSTRAINT_URL}"


# Stage 2 - final
FROM apache/airflow:slim-${AIRFLOW_VER}-python${PYTHON_VER}
ARG AIRFLOW_VER
ARG PYTHON_VER
ARG REVISION
ARG SHA
LABEL org.opencontainers.image.source="https://github.com/gigaflux/smart-containers"
LABEL org.opencontainers.image.description="Custom Airflow core image"
LABEL org.opencontainers.image.title="Production airflow core image"
LABEL org.opencontainers.image.url="https://gigaflux.dev"
LABEL org.opencontainers.image.vendor="GigFlux"
LABEL org.opencontainers.image.revision="${REVISION}"
LABEL org.opencontainers.image.authors="dev@gigaflux.dev"
LABEL org.apache.airflow.main-image.commit-sha=""
LABEL org.apache.airflow.main-image.build-id=""
LABEL org.apache.airflow.uid=""
LABEL org.opencontainers.image.commit-sha="${SHA}"
LABEL org.opencontainers.image.documentation="https://github.com/gigaflux/smart-containers"
LABEL org.opencontainers.image.ref.name="airflow-core"
LABEL org.opencontainers.image.base.name="apache/airflow:${AIRFLOW_VER}-slim-python${PYTHON_VER}"
LABEL org.opencontainers.image.licenses="MIT"
USER root
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    echo 'Acquire::ForceIPv4 "true";\n\
Acquire::http::Timeout "5";\n\
Acquire::https::Timeout "5";\n\
Acquire::Retries "5";\n\
Acquire::AllowInsecureRepositories "true";\n\
Acquire::AllowUnauthenticated "true";\n\
APT::Get::AllowUnauthenticated "true";' > /etc/apt/apt.conf.d/99custom-options \
    && apt-get update && apt-get upgrade -y \
    && apt-get update && apt-get install -y --only-upgrade perl perl-base \
    && apt-get update && apt-get install -y --no-install-recommends libsasl2-2 libkrb5-3 \
    && apt-get autoremove -yqq --purge wget gnupg "mariadb*" "mysql*" "libmari*" "libmysql*"
    #&& apt-get clean \
    #&& rm -rf /var/lib/apt/lists/*

USER airflow

SHELL ["/bin/bash", "-c"]
RUN --mount=type=bind,from=builder,source=/home/airflow/dist,target=/tmp/dist \
    python3 -m pip install --no-cache-dir --upgrade pip \
    && python3 -m pip install --no-cache-dir --no-index --find-links=/tmp/dist/wheels "cryptography>=48.0.1" "python-multipart>=0.0.30" "tornado>=6.5.6" \
    && python3 -m pip install --no-cache-dir --no-deps --no-index --find-links=/tmp/dist/wheels "apache-airflow-providers-apache-spark==5.6.0" \
    && python3 -m pip install --no-cache-dir --no-index --find-links=/tmp/dist/wheels \
    "apache-airflow-providers-common-sql" \
    "apache-airflow-providers-postgres" \
    "apache-airflow-providers-clickhousedb" \
    "apache-airflow-providers-jdbc" \
    "apache-airflow-providers-apache-livy" \
    "apache-airflow-providers-celery" \
    "apache-airflow-providers-git" \
    && rm -rf /home/airflow/.cache/pip
