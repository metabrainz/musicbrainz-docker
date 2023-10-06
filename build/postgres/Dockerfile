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
        make \
        pkg-config \
    && apt-get install --allow-downgrades --no-install-recommends -qy \
        --target-release "n=$(. /etc/os-release && echo "$VERSION_CODENAME")-pgdg" \
        libpq5 \
        libpq-dev \
        postgresql-server-dev-${POSTGRES_VERSION} \
    && rm -rf /var/lib/apt/lists/*

# Compile en_US.UTF-8 locale specification
RUN echo en_US.UTF-8 UTF-8 >> /etc/locale.gen \
    && locale-gen

# There is no tag v0.4.2 (or 0.5.0) yet
ARG PG_AMQP_GIT_REF="240d477d40c5e7a579b931c98eb29cef4edda164"
# hadolint ignore=DL3003
RUN git clone https://github.com/omniti-labs/pg_amqp.git /tmp/pg_amqp \
    && cd /tmp/pg_amqp \
    && git checkout "$PG_AMQP_GIT_REF" \
    && make \
    && make install \
    && rm -R /tmp/*
