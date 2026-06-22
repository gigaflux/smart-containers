ARG PG_VER=17
ARG REVISION="unknown"
ARG SHA="unknown"
ARG GOSU_VER=1.19

FROM golang:1.25.11-alpine AS gosu-builder
ARG PG_VER
ARG REVISION
ARG SHA
ARG GOSU_VER
RUN apk add --no-cache git gcc musl-dev
RUN go install github.com/tianon/gosu@$GOSU_VER


FROM postgres:${PG_VER}-alpine
ARG PG_VER
ARG REVISION
ARG SHA
ARG GOSU_VER
EXPOSE 5432/tcp
VOLUME /var/lib/postgresql/data
LABEL org.opencontainers.image.source="https://github.com/gigaflux/smart-containers"
LABEL org.opencontainers.image.description="Postges image"
LABEL org.opencontainers.image.title="Production postges image"
LABEL org.opencontainers.image.url="https://gigaflux.dev"
LABEL org.opencontainers.image.vendor="GigFlux"
LABEL org.opencontainers.image.revision="${REVISION}"
LABEL org.opencontainers.image.authors="dev@gigaflux.dev"
LABEL org.opencontainers.image.commit-sha="${SHA}"
LABEL org.opencontainers.image.documentation="https://github.com/gigaflux/smart-containers"
LABEL org.opencontainers.image.ref.name="postgres"
LABEL org.opencontainers.image.base.name="postgres:${PG_VER}-alpine"
LABEL org.opencontainers.image.licenses="MIT"
ENV GOSU_VERSION=$GOSU_VER

RUN --mount=type=bind,from=gosu-builder,source=/go/bin/gosu,target=/tmp/gosu \
    cp -f /tmp/gosu /usr/local/bin/gosu

#USER root
#COPY entrypoint.sh /usr/local/bin/docker-entrypoint.sh
#RUN chmod +x /usr/local/bin/docker-entrypoint.sh
#USER redis


