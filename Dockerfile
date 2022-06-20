FROM golang:1.18 AS builder

ARG APTLY_VERSION=master

RUN set -eu \
 && git clone https://github.com/aptly-dev/aptly.git \
 && cd aptly \
 && git checkout ${APTLY_VERSION} \
 && make install

FROM debian:11

COPY --from=builder --chown=root:root /go/bin/aptly /usr/bin/aptly

RUN set -eu \
 && mkdir /data \
 && useradd -s /bin/bash -M -d /data aptly \
 && chown aptly:aptly /data

RUN set -eu \
 && apt-get update && apt-get install -y build-essential xz-utils lzop lz4 zstd gnupg ca-certificates jq && apt-get clean

COPY --chown=root:root docker-entrypoint.sh /
COPY --chown=root:root mirror-update.sh /
RUN chmod 0555 /docker-entrypoint.sh /mirror-update.sh

EXPOSE 8080
VOLUME [ "/data" ]

USER aptly
WORKDIR /data

ENV GIN_MODE=release

ENV GPG_GENERATE=false \
    GPG_TYPE=default \
    GPG_LENGTH=default \
    GPG_REALNAME=Aptly \
    GPG_EMAIL=aptly@example.org \
    GPG_EXPIRE=0

ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD [ "api", "serve", "-listen=:8080" ]