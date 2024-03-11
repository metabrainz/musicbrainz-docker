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
        bzip2 \
        gettext \
        g++ \
        git \
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
        nodejs \
        # Needed for Unicode::ICU::Collator
        pkg-config \
        postgresql-client-${POSTGRES_VERSION} \
        python2-minimal \
        # Needed to decompress sample data
        xz-utils \
        # Needed for XML:LibXML
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/* \
    # Install yarn from nodejs
    && corepack enable

ARG MUSICBRAINZ_SERVER_VERSION=v-2024-03-11
LABEL org.metabrainz.musicbrainz-server.version="${MUSICBRAINZ_SERVER_VERSION}"
RUN git clone --depth=1 --branch $MUSICBRAINZ_SERVER_VERSION https://github.com/metabrainz/musicbrainz-server.git musicbrainz-server

WORKDIR /musicbrainz-server

RUN eval "$(perl -Mlocal::lib)" \
    && cpanm --installdeps --notest . \
    && cpanm --notest \
        Catalyst::Plugin::StackTrace \
        Plack::Handler::Starlet \
        Plack::Middleware::Debug::Base \
        Server::Starter \
        Starlet \
        Starlet::Server \
        Term::Size::Any \
    && rm -rf /root/.cpan* /root/perl5/man/

RUN install -m 0755 \
    admin/replication/hooks/post-process.sample \
    admin/replication/hooks/post-process
COPY DBDefs.pm /musicbrainz-server/lib/
COPY scripts/* /usr/local/bin/
RUN cat /usr/local/bin/snippet.perllocallib.bashrc >> ~/.bashrc \
    && rm /usr/local/bin/snippet.perllocallib.bashrc \
    && ln -s /usr/local/bin/docker-entrypoint.sh /

# Postgres user/password would be solely needed to compile tests
ARG POSTGRES_USER=doesntmatteraslongasyoudontcompiletests
ARG POSTGRES_PASSWORD=doesntmatteraslongasyoudontcompiletests

ENV BASH_ENV=/noninteractive.bash_env \
    MUSICBRAINZ_BASE_DOWNLOAD_URL=https://data.metabrainz.org/pub/musicbrainz \
    MUSICBRAINZ_CATALYST_DEBUG=0 \
    MUSICBRAINZ_DB_SCHEMA_SEQUENCE=28 \
    MUSICBRAINZ_DEVELOPMENT_SERVER=0 \
    MUSICBRAINZ_SEARCH_SERVER=search:8983/solr \
    MUSICBRAINZ_SERVER_PROCESSES=10 \
    MUSICBRAINZ_STANDALONE_SERVER=0 \
    MUSICBRAINZ_WEB_SERVER_HOST=localhost \
    MUSICBRAINZ_WEB_SERVER_PORT=5000 \
    # Needed for yarn to install production dependencies only
    NODE_ENV=production \
    POSTGRES_USER=musicbrainz \
    POSTGRES_PASSWORD=musicbrainz

RUN yarn install \
    && yarn cache clean \
    && eval "$(perl -Mlocal::lib)" \
    && /musicbrainz-server/script/compile_resources.sh

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["start.sh"]
