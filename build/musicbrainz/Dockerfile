ARG METABRAINZ_BASE_IMAGE_VERSION=focal-1.0.0-alpha1
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

ARG POSTGRES_VERSION=12
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN mkdir -p /usr/local/share/keyrings && \
    curl -sSL --retry 5 https://www.postgresql.org/media/keys/ACCC4CF8.asc > /tmp/postgres-key.asc && \
    gpg --no-default-keyring --keyring /tmp/postgres-keyring.gpg --import /tmp/postgres-key.asc && \
    gpg --no-default-keyring --keyring /tmp/postgres-keyring.gpg --export --output /usr/local/share/keyrings/apt.postgresql.org.gpg && \
    rm -f /tmp/postgres-key.asc /tmp/postgres-keyring.gpg && \
    echo "deb [signed-by=/usr/local/share/keyrings/apt.postgresql.org.gpg] http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
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
        # Needed for Unicode::ICU::Collator
        pkg-config \
        postgresql-client-${POSTGRES_VERSION} \
        python2-minimal \
        # Needed to decompress sample data
        xz-utils \
        # Needed for XML:LibXML
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

ARG MUSICBRAINZ_SERVER_VERSION=v-2023-04-17
LABEL org.metabrainz.musicbrainz-server.version="${MUSICBRAINZ_SERVER_VERSION}"
RUN git clone --depth=1 --branch $MUSICBRAINZ_SERVER_VERSION https://github.com/metabrainz/musicbrainz-server.git musicbrainz-server

WORKDIR /musicbrainz-server

ARG NODE_VERSION=16.16.0
ARG PGP_SERVERS="keys.openpgp.org keyserver.ubuntu.com pgp.mit.edu"
RUN cp docker/yarn_pubkey.txt /tmp/yarn-key.asc && \
    cd /tmp && \
    gpg --no-default-keyring --keyring /tmp/yarn-keyring.gpg --import /tmp/yarn-key.asc && \
    \
    # Refresh Yarn signing keys
    refreshed_keys=''; \
    for pgp_server in $(tr ' ' '\n' <<<"$PGP_SERVERS"); do \
        for attempt in {1..3}; do \
            gpg --no-default-keyring --keyring /tmp/yarn-keyring.gpg --keyserver "$pgp_server" --refresh-keys Yarn 2>&1 && \
            { refreshed_keys='yes'; break; } || \
            echo "Temporary failure: gpg returned error code '$?' on attempt #$attempt to reach '$pgp_server'."; \
        done; \
        if [[ $refreshed_keys == yes ]]; then break; fi; \
    done; \
    if [[ $refreshed_keys != yes ]]; then \
        echo >&2 'Fatal error: Failed all attempts to refresh PGP keys.'; \
        echo >&2 'Try passing a list of PGP servers that work for you as build argument:'; \
        echo >&2 ''; \
        echo >&2 '    docker-compose build --build-arg PGP_SERVERS="LIST" musicbrainz'; \
        echo >&2 ''; \
        echo >&2 "Current LIST is \"$PGP_SERVERS\""; \
        EX_TEMPFAIL=75; \
        exit $EX_TEMPFAIL; \
    fi; \
    unset attempt pgp_server refreshed_keys; \
    \
    gpg --no-default-keyring --keyring /tmp/yarn-keyring.gpg --export --output /usr/local/share/keyrings/dl.yarnpkg.com.gpg && \
    rm -f /tmp/yarn-key.asc /tmp/yarn-keyring.gpg && \
    echo "deb [signed-by=/usr/local/share/keyrings/dl.yarnpkg.com.gpg] https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarnpkg.list && \
    apt-get update -o Dir::Etc::sourcelist="sources.list.d/yarnpkg.list" -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0" && \
    curl -sSLO --retry 5 https://deb.nodesource.com/node_16.x/pool/main/n/nodejs/nodejs_${NODE_VERSION}-deb-1nodesource1_amd64.deb && \
    dpkg -i nodejs_${NODE_VERSION}-deb-1nodesource1_amd64.deb && \
    apt-get purge -qy cmdtest && \
    apt-get install --no-install-recommends -qy \
        yarn && \
    rm /tmp/* && \
    rm -rf /var/lib/apt/lists/*

RUN eval "$(perl -Mlocal::lib)" \
    && cpanm --installdeps --notest . \
    && cpanm --notest \
        Catalyst::Plugin::Cache::HTTP \
        Catalyst::Plugin::StackTrace \
        Digest::MD5::File \
        JSON::Any \
        LWP::Protocol::https \
        Plack::Handler::Starlet \
        Plack::Middleware::Debug::Base \
        Server::Starter \
        Starlet \
        Starlet::Server \
        Term::Size::Any \
        TURNSTEP/DBD-Pg-3.16.0.tar.gz \
    && rm -rf /root/.cpan* /root/perl5/man/

COPY DBDefs.pm /musicbrainz-server/lib/
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
    MUSICBRAINZ_DB_SCHEMA_SEQUENCE=27 \
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
