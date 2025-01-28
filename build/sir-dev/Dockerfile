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
      build-essential \
      ca-certificates \
      cron \
      git \
      # TODO: check if this is actually needed
      libffi-dev \
      # required for connections of pip packages
      libssl-dev \
      # required for psycopg2. Installs without it but links against a wrong .so.
      libpq-dev \
      # required for testing search entities
      libsqlite3-dev \
      # required by lxml from mb-rngpy
      libxslt1-dev \
    && rm -rf /var/lib/apt/lists/*

##################
# Installing sir #
##################

ARG SIR_VERSION=py27-stage1

LABEL org.metabrainz.sir.version="${SIR_VERSION}"

ARG DOCKERIZE_VERSION=v0.6.1
RUN curl -sSLO --retry 5 https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz && \
    tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz && \
    rm -f dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz

COPY scripts/* /usr/local/bin/

RUN echo Requirements will be installed at run time from entrypoint. \
    && rm -f /code/config.ini \
    && touch /etc/consul-template.conf

WORKDIR /code

ENV MUSICBRAINZ_RABBITMQ_SERVER=mq \
    MUSICBRAINZ_POSTGRES_SERVER=db \
    MUSICBRAINZ_POSTGRES_READONLY_SERVER=db \
    MUSICBRAINZ_SEARCH_SERVER=search:8983/solr

ENV POSTGRES_USER=musicbrainz
ENV POSTGRES_PASSWORD=musicbrainz
ENV PYTHONUSERBASE="/code/venv-musicbrainz-docker"
ENV PATH="/code/venv-musicbrainz-docker/bin:$PATH"

ENTRYPOINT ["docker-entrypoint.sh"]
CMD unset PYTHONUSERBASE; my_init
