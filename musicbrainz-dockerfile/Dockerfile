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
    git checkout v-2019-05-13-schema-change

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
        TURNSTEP/DBD-Pg-3.7.4.tar.gz

ADD DBDefs.pm /musicbrainz-server/lib/
ADD scripts/start.sh /start.sh
ADD scripts/start_mb_renderer.pl /start_mb_renderer.pl
ADD scripts/crons.conf /crons.conf
ADD scripts/replication.sh /replication.sh
ADD scripts/createdb.sh /createdb.sh
ADD scripts/recreatedb.sh /recreatedb.sh
ADD scripts/set-token.sh /set-token.sh

# Postgres user/password would be solely needed to compile tests
ARG POSTGRES_USER=doesntmatteraslongasyoudontcompiletests
ARG POSTGRES_PASSWORD=doesntmatteraslongasyoudontcompiletests
RUN cd /musicbrainz-server/ && yarn install --production && \
    eval $( perl -Mlocal::lib) && /musicbrainz-server/script/compile_resources.sh

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN crontab /crons.conf

VOLUME  ["/media/dbdump"]
WORKDIR /musicbrainz-server
CMD dockerize -wait tcp://db:5432 -timeout 60s \
        -wait tcp://redis:6379 -timeout 60s \
        /start.sh
