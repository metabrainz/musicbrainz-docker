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

ARG PERL_VERSION=5.38.2
ARG PERL_SRC_SUM=a0a31534451eb7b83c7d6594a497543a54d488bc90ca00f5e34762577f40655e

ARG CPANMINUS_VERSION=1.7047
ARG CPANMINUS_SRC_SUM=963e63c6e1a8725ff2f624e9086396ae150db51dd0a337c3781d09a994af05a5

COPY keyrings/* /etc/apt/keyrings/
ARG NODE_MAJOR_VERSION=20
ARG POSTGRES_VERSION=16
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.asc] https://deb.nodesource.com/node_${NODE_MAJOR_VERSION}.x nodistro main" > /etc/apt/sources.list.d/nodesource.list && \
    echo "deb [signed-by=/etc/apt/keyrings/pgdg.asc] http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && \
    apt-get install --no-install-recommends -qy \
        # Needed for building perl
        build-essential \
        bzip2 \
        gettext \
        g++ \
        git \
        # NOTE-LANGUAGES-1: These language packs must match the definition of MB_LANGUAGES in DBDefs.pm
        language-pack-de \
        language-pack-fr \
        language-pack-it \
        language-pack-nl \
        # Needed for Cache in DB_File
        libdb-dev \
        libexpat1-dev \
        libicu-dev \
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
        && \
    rm -rf /var/lib/apt/lists/* && \
    # Install perl (in a more recent version than available with apt)
    cd /usr/src && \
    curl -sSLO https://cpan.metacpan.org/authors/id/P/PE/PEVANS/perl-$PERL_VERSION.tar.gz && \
    echo "$PERL_SRC_SUM *perl-$PERL_VERSION.tar.gz" | sha256sum --strict --check - && \
    tar -xzf perl-$PERL_VERSION.tar.gz && \
    cd perl-$PERL_VERSION && \
    gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" && \
    archBits="$(dpkg-architecture --query DEB_BUILD_ARCH_BITS)" && \
    archFlag="$([ "$archBits" = '64' ] && echo '-Duse64bitall' || echo '-Duse64bitint')" && \
    ./Configure \
        -Darchname="$gnuArch" "$archFlag" \
        -Duselargefiles -Duseshrplib -Dusethreads \
        -Dvendorprefix=/usr/local -Dman1dir=none -Dman3dir=none \
        -des && \
    make -j$(nproc) && \
    make install && \
    rm -fr /usr/src/perl-$PERL_VERSION* && \
    # Install cpanm (needed to help with updating Perl modules)
    cd /usr/src && \
    curl -sSLO https://www.cpan.org/authors/id/M/MI/MIYAGAWA/App-cpanminus-$CPANMINUS_VERSION.tar.gz && \
    echo "$CPANMINUS_SRC_SUM *App-cpanminus-$CPANMINUS_VERSION.tar.gz" | sha256sum --strict --check - && \
    tar -xzf App-cpanminus-$CPANMINUS_VERSION.tar.gz && \
    cd App-cpanminus-$CPANMINUS_VERSION && \
    perl bin/cpanm . && \
    rm -fr /usr/src/App-cpanminus-$CPANMINUS_VERSION* && \
    cd /root && \
    # Install local::lib (needed to persistently update Perl modules)
    cpanm local::lib && \
    rm -fr /root/.cpanm && \
    # Install yarn from nodejs
    corepack enable && \
    # Clean up perl build dependencies
    apt-get purge --auto-remove -y \
        build-essential

ARG MUSICBRAINZ_SERVER_VERSION=v-2025-02-10.0
LABEL org.metabrainz.musicbrainz-server.version="${MUSICBRAINZ_SERVER_VERSION}"
RUN git clone --depth=1 --branch $MUSICBRAINZ_SERVER_VERSION https://github.com/metabrainz/musicbrainz-server.git musicbrainz-server

WORKDIR /musicbrainz-server

RUN eval "$(perl -Mlocal::lib)" && \
    cpanm Carton && \
    carton install --deployment && \
    cpanm --notest \
        Catalyst::Plugin::StackTrace \
        Plack::Handler::Starlet \
        Plack::Middleware::Debug::Base \
        Server::Starter \
        Starlet \
        Starlet::Server \
        Term::Size::Any \
        && \
    rm -rf /root/.cpan* /root/perl5/man/

RUN install -m 0755 \
    admin/replication/hooks/post-process.sample \
    admin/replication/hooks/post-process
COPY DBDefs.pm /musicbrainz-server/lib/
COPY scripts/* /usr/local/bin/
RUN cat /usr/local/bin/snippet.perllocallib.bashrc >> ~/.bashrc && \
    rm /usr/local/bin/snippet.perllocallib.bashrc && \
    ln -s /usr/local/bin/docker-entrypoint.sh /

# Postgres user/password would be solely needed to compile tests
ARG POSTGRES_USER=doesntmatteraslongasyoudontcompiletests
ARG POSTGRES_PASSWORD=doesntmatteraslongasyoudontcompiletests

ENV BASH_ENV=/noninteractive.bash_env \
    MUSICBRAINZ_BASE_DOWNLOAD_URL=https://data.metabrainz.org/pub/musicbrainz \
    MUSICBRAINZ_CATALYST_DEBUG=0 \
    MUSICBRAINZ_DB_SCHEMA_SEQUENCE=29 \
    MUSICBRAINZ_DEVELOPMENT_SERVER=0 \
    MUSICBRAINZ_POSTGRES_SERVER=db \
    MUSICBRAINZ_POSTGRES_READONLY_SERVER=db \
    MUSICBRAINZ_RABBITMQ_SERVER=mq \
    MUSICBRAINZ_REDIS_SERVER=redis \
    MUSICBRAINZ_SEARCH_SERVER=search:8983/solr \
    MUSICBRAINZ_SERVER_PROCESSES=10 \
    MUSICBRAINZ_STANDALONE_SERVER=0 \
    MUSICBRAINZ_WEB_SERVER_HOST=localhost \
    MUSICBRAINZ_WEB_SERVER_PORT=5000 \
    # Needed for yarn to install production dependencies only
    NODE_ENV=production \
    PERL_CARTON_CPANFILE=/musicbrainz-server/cpanfile \
    POSTGRES_USER=musicbrainz \
    POSTGRES_PASSWORD=musicbrainz

RUN yarn install && \
    yarn cache clean && \
    eval "$(perl -Mlocal::lib)" && \
    carton exec -- /musicbrainz-server/script/compile_resources.sh

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["start.sh"]
