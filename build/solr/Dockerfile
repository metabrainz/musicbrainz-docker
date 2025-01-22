ARG MB_SOLR_VERSION=3.4.1
FROM metabrainz/mb-solr:${MB_SOLR_VERSION}

ARG MB_SOLR_VERSION
LABEL org.metabrainz.based-on-image="metabrainz/mb-solr:${MB_SOLR_VERSION}"

USER root
RUN apt-get update && \
    apt-get install --no-install-recommends -qy libjson-perl libwww-perl && \
    rm -rf /var/lib/apt/lists/*
USER solr

COPY [ "scripts/*", "/usr/local/bin/" ]
