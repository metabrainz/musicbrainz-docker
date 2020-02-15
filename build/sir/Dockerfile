ARG PYTHON_VERSION=2.7
FROM metabrainz/python:${PYTHON_VERSION}

ARG PYTHON_VERSION

LABEL org.label-schema.schema-version="1.0.0-rc1" \
      org.label-schema.vendor="MetaBrainz Foundation" \
      org.metabrainz.based-on-image="metabrainz/python:${PYTHON_VERSION}"

#######################
# From metabrainz/sir #
#######################

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
                    build-essential \
                    ca-certificates \
                    cron \
                    git \
                    libpq-dev \
                    libffi-dev \
                    libssl-dev \
                    libxml2-dev \
                    libxslt1-dev && \
    rm -rf /var/lib/apt/lists/*

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
