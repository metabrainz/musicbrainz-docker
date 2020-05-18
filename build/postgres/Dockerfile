ARG POSTGRES_VERSION=12
FROM postgres:${POSTGRES_VERSION}

ARG POSTGRES_VERSION
LABEL org.metabrainz.based-on-image="postgres:${POSTGRES_VERSION}"

ARG DEBIAN_FRONTEND=noninteractive

# Update the Ubuntu and PostgreSQL repository indexes
RUN apt-get update && \
    apt-get install --allow-downgrades --no-install-recommends -qy \
        build-essential \
        ca-certificates \
        gcc \
        git \
        libicu-dev \
        libpq5=${POSTGRES_VERSION}.* \
        libpq-dev=${POSTGRES_VERSION}.* \
        make \
        pkg-config \
        postgresql-server-dev-${POSTGRES_VERSION} \
    && rm -rf /var/lib/apt/lists/*

ARG PG_AMQP_VERSION="0.4.1"
# hadolint ignore=DL3003
RUN git clone -b "v$PG_AMQP_VERSION" --depth=1 https://github.com/omniti-labs/pg_amqp.git /tmp/pg_amqp \
    && cd /tmp/pg_amqp \
    && make \
    && make install \
    && rm -R /tmp/*
