FROM postgres:9.5
LABEL Author="jeffsturgis@gmail.com"

ARG DEBIAN_FRONTEND="noninteractive"

# Update the Ubuntu and PostgreSQL repository indexes
RUN apt-get update && \
    apt-get -y -q install \
        build-essential \
        git-core \
        libdb-dev \
        libexpat1-dev \
        libicu-dev \
        libpq-dev \
        libxml2-dev \
        postgresql-server-dev-9.5

RUN git clone https://github.com/metabrainz/postgresql-musicbrainz-unaccent.git /tmp/postgresql-musicbrainz-unaccent && \
    git clone https://github.com/metabrainz/postgresql-musicbrainz-collate.git /tmp/postgresql-musicbrainz-collate

WORKDIR /tmp/postgresql-musicbrainz-unaccent
RUN make && make install
WORKDIR /tmp/postgresql-musicbrainz-collate
RUN make && make install
WORKDIR /

COPY set-config.sh /docker-entrypoint-initdb.d

RUN rm -R /tmp/*
