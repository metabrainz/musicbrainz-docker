ARG MB_SOLR_VERSION=4.0.0-alpha2-26-gc8c8410
FROM metabrainz/mb-solr:${MB_SOLR_VERSION}

ARG MB_SOLR_VERSION
LABEL org.metabrainz.based-on-image="metabrainz/mb-solr:${MB_SOLR_VERSION}"

COPY [ "scripts/*", "/usr/local/bin/" ]
