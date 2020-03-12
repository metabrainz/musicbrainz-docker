FROM metabrainz/base-image
LABEL maintainer=jeffsturgis@gmail.com

ENV DOCKERIZE_VERSION v0.6.1
RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz && \
    tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz && \
    rm -f dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz

ARG POSTGRES_VERSION=9.5
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN curl -sSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && \
    apt-get install -y \
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
        memcached \
        # Needed for Unicode::ICU::Collator
        pkg-config \
        postgresql-client-${POSTGRES_VERSION} \
        python-minimal \
        # Needed to decompress sample data
        xz-utils \
        # Needed for XML:LibXML
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

ARG MUSICBRAINZ_SERVER_VERSION=v-2020-01-20
RUN git clone --depth=1 --branch $MUSICBRAINZ_SERVER_VERSION https://github.com/metabrainz/musicbrainz-server.git musicbrainz-server

WORKDIR /musicbrainz-server

ARG NODE_VERSION=10.19.0
RUN cp docker/yarn_pubkey.txt /tmp && \
    cd /tmp && \
    apt-key add yarn_pubkey.txt && \
    apt-key adv --keyserver hkps.pool.sks-keyservers.net --refresh-keys Yarn && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update -o Dir::Etc::sourcelist="sources.list.d/yarn.list" -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0" && \
    curl -sLO https://deb.nodesource.com/node_10.x/pool/main/n/nodejs/nodejs_$NODE_VERSION-1nodesource1_amd64.deb && \
    dpkg -i nodejs_$NODE_VERSION-1nodesource1_amd64.deb && \
    apt remove -y cmdtest && \
    apt-get install -y yarn && \
    rm /tmp/* && \
    rm -rf /var/lib/apt/lists/*

RUN eval "$(perl -Mlocal::lib)" \
    && cpanm --installdeps --notest . \
    && cpanm --notest \
        Cache::Memcached::Fast \
        Cache::Memory \
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
        TURNSTEP/DBD-Pg-3.9.1.tar.gz \
    && rm -rf /root/.cpan* /root/perl5/man/

COPY DBDefs.pm /musicbrainz-server/lib/
COPY scripts/* /

# Postgres user/password would be solely needed to compile tests
ARG POSTGRES_USER=doesntmatteraslongasyoudontcompiletests
ARG POSTGRES_PASSWORD=doesntmatteraslongasyoudontcompiletests

ENV MUSICBRAINZ_STANDALONE_SERVER=0 \
    MUSICBRAINZ_WEB_SERVER_HOST=localhost \
    MUSICBRAINZ_WEB_SERVER_PORT=5000 \
    POSTGRES_USER=musicbrainz \
    POSTGRES_PASSWORD=musicbrainz

RUN yarn install --production \
    && yarn cache clean \
    && eval "$(perl -Mlocal::lib)" \
    && /musicbrainz-server/script/compile_resources.sh

CMD /start.sh
