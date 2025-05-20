ARG MB_SOLR_VERSION=3.4.1
FROM metabrainz/mb-solr:${MB_SOLR_VERSION}

ARG MB_SOLR_VERSION
LABEL org.metabrainz.based-on-image="metabrainz/mb-solr:${MB_SOLR_VERSION}"

COPY [ "scripts/*", "/usr/local/bin/" ]
