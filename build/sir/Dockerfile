ARG PYTHON_VERSION=2.7
ARG BASE_IMAGE_DATE=20220421
FROM metabrainz/python:$PYTHON_VERSION-$BASE_IMAGE_DATE

ARG PYTHON_VERSION
ARG BASE_IMAGE_DATE

LABEL org.metabrainz.based-on-image="metabrainz/python:${PYTHON_VERSION}-${BASE_IMAGE_DATE}"

ARG DEBIAN_FRONTEND=noninteractive

#######################
# From metabrainz/sir #
#######################

RUN apt-get update \
    && apt-get install --no-install-recommends -qy \
      ca-certificates \
      cron \
      gcc \
      git \
      libc6-dev \
      # TODO: check if this is actually needed
      libffi-dev \
      # required for connections of pip packages
      libssl-dev \
      # required for psycopg2. Installs without it but links against a wrong .so.
      libpq-dev \
      # required by lxml from mb-rngpy
      libxslt1-dev \
    && rm -rf /var/lib/apt/lists/*

##################
# Installing sir #
##################

ARG SIR_VERSION=3.0.1
LABEL org.metabrainz.sir.version="${SIR_VERSION}"

# hadolint ignore=DL3003
RUN git clone --depth=1 --branch "v${SIR_VERSION}" https://github.com/metabrainz/sir.git /code \
    && cd /code \
    && pip install -r requirements.txt \
    && rm -f /code/config.ini \
    && touch /etc/consul-template.conf

WORKDIR /code

ENV MUSICBRAINZ_RABBITMQ_SERVER=mq \
    MUSICBRAINZ_POSTGRES_SERVER=db \
    MUSICBRAINZ_POSTGRES_READONLY_SERVER=db \
    MUSICBRAINZ_SEARCH_SERVER=search:8983/solr

ENV POSTGRES_USER=musicbrainz
ENV POSTGRES_PASSWORD=musicbrainz

