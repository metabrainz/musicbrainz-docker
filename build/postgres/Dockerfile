ARG POSTGRES_VERSION=12
FROM postgres:${POSTGRES_VERSION}
LABEL Author="jeffsturgis@gmail.com"

ARG DEBIAN_FRONTEND="noninteractive"
# Has to be redeclared due to being in a different build stage
ARG POSTGRES_VERSION

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

# hadolint ignore=DL3003
RUN git clone https://github.com/omniti-labs/pg_amqp.git /tmp/pg_amqp \
    && cd /tmp/pg_amqp \
    && make \
    && make install \
    && rm -R /tmp/*
