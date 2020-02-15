ARG POSTGRES_VERSION=9.5
FROM postgres:${POSTGRES_VERSION}
LABEL Author="jeffsturgis@gmail.com"

ARG DEBIAN_FRONTEND="noninteractive"
# Has to be redeclared due to being in a different build stage
ARG POSTGRES_VERSION

# Update the Ubuntu and PostgreSQL repository indexes
RUN apt-get update && \
    apt-get -y -q install --allow-downgrades \
        build-essential \
        git-core \
        libdb-dev \
        libexpat1-dev \
        libicu-dev \
        libpq5=${POSTGRES_VERSION}.* \
        libpq-dev=${POSTGRES_VERSION}.* \
        libxml2-dev \
        pkg-config \
        postgresql-server-dev-${POSTGRES_VERSION} \
    && rm -rf /var/lib/apt/lists/*

# hadolint ignore=DL3003
RUN git clone https://github.com/metabrainz/postgresql-musicbrainz-unaccent.git /tmp/postgresql-musicbrainz-unaccent \
    && git clone https://github.com/metabrainz/postgresql-musicbrainz-collate.git /tmp/postgresql-musicbrainz-collate \
    && git clone https://github.com/omniti-labs/pg_amqp.git /tmp/pg_amqp \
    && cd /tmp/postgresql-musicbrainz-unaccent \
    && make \
    && make install \
    && cd /tmp/postgresql-musicbrainz-collate \
    && make \
    && make install \
    && cd /tmp/pg_amqp \
    && make \
    && make install \
    && rm -R /tmp/*

WORKDIR /

COPY set-config.sh /docker-entrypoint-initdb.d
