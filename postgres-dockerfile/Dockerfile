FROM postgres:9.5
MAINTAINER jeffsturgis@gmail.com

ARG DEBIAN_FRONTEND="noninteractive"

# Update the Ubuntu and PostgreSQL repository indexes
RUN apt-get update && \
  apt-get -y -q install \
    git-core \
    build-essential \
    libxml2-dev \
    libpq-dev \
    libexpat1-dev \
    libdb-dev \
    libicu-dev \
    postgresql-server-dev-9.5

RUN git clone https://github.com/metabrainz/postgresql-musicbrainz-unaccent.git /tmp/postgresql-musicbrainz-unaccent && \
  git clone https://github.com/metabrainz/postgresql-musicbrainz-collate.git /tmp/postgresql-musicbrainz-collate

WORKDIR /tmp/postgresql-musicbrainz-unaccent
RUN make && make install
WORKDIR /tmp/postgresql-musicbrainz-collate
RUN make && make install
WORKDIR /

RUN rm -R /tmp/*

RUN echo "listen_addresses='*'" >> /var/lib/postgresql/data/postgresql.conf
