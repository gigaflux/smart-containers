ARG REDIS_VER=7.2
ARG REVISION="unknown"
ARG SHA="unknown"

FROM redis:${REDIS_VER}-alpine
ARG REDIS_VER
ARG REVISION
ARG SHA
EXPOSE 6379/tcp
VOLUME /data
LABEL org.opencontainers.image.source="https://github.com/gigaflux/smart-containers"
LABEL org.opencontainers.image.description="Redis image"
LABEL org.opencontainers.image.title="Production redis image"
LABEL org.opencontainers.image.url="https://gigaflux.dev"
LABEL org.opencontainers.image.vendor="GigFlux"
LABEL org.opencontainers.image.revision="${REVISION}"
LABEL org.opencontainers.image.authors="dev@gigaflux.dev"
LABEL org.opencontainers.image.commit-sha="${SHA}"
LABEL org.opencontainers.image.documentation="https://github.com/gigaflux/smart-containers"
LABEL org.opencontainers.image.ref.name="redis"
LABEL org.opencontainers.image.base.name="redis:${REDIS_VER}-alpine"
LABEL org.opencontainers.image.licenses="MIT"

USER root
COPY entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
USER redis


