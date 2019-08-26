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

RUN git clone https://github.com/metabrainz/sir.git /code && \
    cd /code && \
    git checkout "v${SIR_VERSION}" && \
    pip install -r requirements.txt

RUN rm -f /code/config.ini

WORKDIR /code

RUN touch /etc/consul-template.conf

ENV POSTGRES_USER musicbrainz
ENV POSTGRES_PASSWORD musicbrainz
