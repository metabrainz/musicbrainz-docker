FROM metabrainz/base-image
LABEL maintainer=jeffsturgis@gmail.com

ENV DOCKERIZE_VERSION v0.5.0
RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz && \
    tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz && \
    rm -f dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz

ARG POSTGRES_VERSION=9.5
RUN curl -sSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && \
    apt-get install -y \
        cpanminus \
        build-essential \
        gettext \
        git-core \
        libdb-dev \
        libexpat1-dev \
        libicu-dev \
        liblocal-lib-perl \
        libpq-dev \
        libxml2-dev \
        libssl-dev \
        memcached \
        postgresql-${POSTGRES_VERSION} \
        python-minimal \
        zlib1g-dev

RUN git clone https://github.com/metabrainz/musicbrainz-server.git musicbrainz-server && \
    cd musicbrainz-server && \
    git checkout v-2019-08-08

RUN cd musicbrainz-server && \
    cp docker/yarn_pubkey.txt /tmp && \
    cd /tmp && \
    apt-key add yarn_pubkey.txt && \
    apt-key adv --keyserver hkps.pool.sks-keyservers.net --refresh-keys Yarn && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update -o Dir::Etc::sourcelist="sources.list.d/yarn.list" -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0" && \
    curl -sLO https://deb.nodesource.com/node_8.x/pool/main/n/nodejs/nodejs_8.11.3-1nodesource1_amd64.deb && \
    dpkg -i nodejs_8.11.3-1nodesource1_amd64.deb && \
    apt remove -y cmdtest && \
    apt-get install -y yarn

RUN cd /musicbrainz-server/ && \
    eval $( perl -Mlocal::lib) && cpanm --installdeps --notest .
RUN eval $( perl -Mlocal::lib) && cpanm --notest \
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
        TURNSTEP/DBD-Pg-3.9.1.tar.gz

COPY DBDefs.pm /musicbrainz-server/lib/
COPY scripts/* /
RUN apt-get install -y wget

# Postgres user/password would be solely needed to compile tests
ARG POSTGRES_USER=doesntmatteraslongasyoudontcompiletests
ARG POSTGRES_PASSWORD=doesntmatteraslongasyoudontcompiletests

ENV DEVELOPMENT_MUSICBRAINZ_DOCKER=0 \
    MUSICBRAINZ_WEB_SERVER_HOST=localhost \
    MUSICBRAINZ_WEB_SERVER_PORT=5000 \
    POSTGRES_USER=musicbrainz \
    POSTGRES_PASSWORD=musicbrainz

RUN cd /musicbrainz-server/ && yarn install --production && \
    eval $( perl -Mlocal::lib) && /musicbrainz-server/script/compile_resources.sh

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

VOLUME  ["/media/dbdump"]
WORKDIR /musicbrainz-server
CMD dockerize -wait tcp://db:5432 -timeout 60s \
        -wait tcp://mq:5672 -timeout 60s \
        -wait tcp://redis:6379 -timeout 60s \
        /start.sh
