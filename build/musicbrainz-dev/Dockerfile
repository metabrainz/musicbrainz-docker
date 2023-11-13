ARG METABRAINZ_BASE_IMAGE_VERSION=jammy-1.0.1-v0.4
ARG METABRAINZ_BASE_IMAGE_VARIANT=
ARG METABRAINZ_BASE_IMAGE_TAG=${METABRAINZ_BASE_IMAGE_VERSION}${METABRAINZ_BASE_IMAGE_VARIANT}
FROM metabrainz/base-image:${METABRAINZ_BASE_IMAGE_TAG}

ARG METABRAINZ_BASE_IMAGE_VERSION
ARG METABRAINZ_BASE_IMAGE_VARIANT
ARG METABRAINZ_BASE_IMAGE_TAG
LABEL org.metabrainz.based-on-image="metabrainz/base-image:${METABRAINZ_BASE_IMAGE_TAG}"

ARG DEBIAN_FRONTEND=noninteractive

ARG DOCKERIZE_VERSION=v0.6.1
RUN curl -sSLO --retry 5 https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz && \
    tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz && \
    rm -f dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz

COPY keyrings/* /etc/apt/keyrings/
ARG NODE_MAJOR_VERSION=20
ARG POSTGRES_VERSION=12
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.asc] https://deb.nodesource.com/node_${NODE_MAJOR_VERSION}.x nodistro main" > /etc/apt/sources.list.d/nodesource.list && \
    echo "deb [signed-by=/etc/apt/keyrings/pgdg.asc] http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && \
    apt-get install --no-install-recommends -qy \
        cpanminus \
        bash-completion \
        build-essential \
        bzip2 \
        gettext \
        g++ \
        git \
        # Needed to generate SVG from database schema DOT diagrams
        graphviz \
        language-pack-de \
        language-pack-el \
        language-pack-es \
        language-pack-et \
        language-pack-fi \
        language-pack-fr \
        language-pack-he \
        language-pack-it \
        language-pack-ja \
        language-pack-nl \
        language-pack-sq \
        # Needed for Cache in DB_File
        libdb-dev \
        libexpat1-dev \
        libicu-dev \
        liblocal-lib-perl \
        libpq-dev \
        libssl-dev \
        # Needed for XML::LibXML
        libxml2-dev \
        make \
        # Needed for ts
        moreutils \
        nodejs \
        # Needed for Unicode::ICU::Collator
        pkg-config \
        postgresql-${POSTGRES_VERSION} \
        # Needed to normalize database schema SVG diagrams
        scour \
        # Needed to decompress sample data
        xz-utils \
        # Needed for XML:LibXML
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/* \
    # Install yarn from nodejs
    && corepack enable

WORKDIR /musicbrainz-server
RUN git config --global --add safe.directory /musicbrainz-server

COPY DBDefs.pm /
COPY scripts/* /usr/local/bin/
RUN cat /usr/local/bin/snippet.perllocallib.bashrc >> ~/.bashrc \
    && rm /usr/local/bin/snippet.perllocallib.bashrc \
    && ln -s /usr/local/bin/docker-entrypoint.sh /

# Postgres user/password would be solely needed to compile tests
ARG POSTGRES_USER=doesntmatteraslongasyoudontcompiletests
ARG POSTGRES_PASSWORD=doesntmatteraslongasyoudontcompiletests

ENV BASH_ENV=/noninteractive.bash_env \
    MUSICBRAINZ_BASE_DOWNLOAD_URL=http://ftp.eu.metabrainz.org/pub/musicbrainz \
    MUSICBRAINZ_CATALYST_DEBUG=0 \
    MUSICBRAINZ_DEVELOPMENT_SERVER=1 \
    MUSICBRAINZ_SEARCH_SERVER=search:8983/solr \
    MUSICBRAINZ_SERVER_PROCESSES=1 \
    MUSICBRAINZ_STANDALONE_SERVER=1 \
    MUSICBRAINZ_WEB_SERVER_HOST=localhost \
    MUSICBRAINZ_WEB_SERVER_PORT=5000 \
    # Needed for yarn to install devDependencies too
    NODE_ENV=test \
    POSTGRES_USER=musicbrainz \
    POSTGRES_PASSWORD=musicbrainz

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["start.sh"]
