ARG PYTHON_VERSION=2.7
FROM metabrainz/python:${PYTHON_VERSION}

ARG PYTHON_VERSION

LABEL org.metabrainz.based-on-image="metabrainz/python:${PYTHON_VERSION}"

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

ARG SIR_VERSION=1.0.2
LABEL org.metabrainz.sir.version="${SIR_VERSION}"

# hadolint ignore=DL3003
RUN git clone --depth=1 --branch "v${SIR_VERSION}" https://github.com/metabrainz/sir.git /code \
    && cd /code \
    && pip install -r requirements.txt \
    && rm -f /code/config.ini \
    && touch /etc/consul-template.conf

WORKDIR /code

ENV POSTGRES_USER=musicbrainz
ENV POSTGRES_PASSWORD=musicbrainz
