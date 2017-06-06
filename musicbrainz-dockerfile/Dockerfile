FROM metabrainz/base-image
MAINTAINER Jeff Sturgis <jeffsturgis@gmail.com>

RUN apt-get update && \
    apt-get install -y \
    git-core \
    postgresql \
    memcached \
    redis-server \
    build-essential \
    libxml2-dev libpq-dev \
    libexpat1-dev \
    libdb-dev \
    libicu-dev \
    liblocal-lib-perl \
    cpanminus \
    nginx

RUN git clone --recursive https://github.com/metabrainz/musicbrainz-server.git musicbrainz-server && \
    cd musicbrainz-server && \
    git checkout v-2017-05-15-schema-change

RUN curl -sL https://deb.nodesource.com/setup_6.x | bash -

RUN apt-get install -y nodejs

RUN cd /musicbrainz-server/ && eval $( perl -Mlocal::lib) && cpanm --installdeps --notest .
RUN eval $( perl -Mlocal::lib) && cpanm --notest Plack::Middleware::Debug::Base \
    Catalyst::Plugin::Cache::HTTP \
    Catalyst::Plugin::StackTrace \
    Cache::Memcached::Fast \
    JSON::Any \
    Cache::Memory \
    Digest::MD5::File \
    Term::Size::Any \
    LWP::Protocol::https \
    Starlet \
    Plack::Handler::Starlet \
    Starlet::Server \
    Server::Starter \
    TURNSTEP/DBD-Pg-3.5.9_1.tar.gz

ADD DBDefs.pm /musicbrainz-server/lib/
ADD scripts/start.sh /start.sh
ADD scripts/start_mb_renderer.pl /start_mb_renderer.pl
ADD scripts/crons.conf /crons.conf
ADD scripts/replication.sh /replication.sh
ADD scripts/createdb.sh /createdb.sh
ADD scripts/recreatedb.sh /recreatedb.sh
ADD scripts/set-token.sh /set-token.sh
ADD 001-musicbrainz /etc/nginx/sites-available/001-musicbrainz

RUN cd /musicbrainz-server/ && npm i \
    && eval $( perl -Mlocal::lib) && /musicbrainz-server/script/compile_resources.sh

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN rm /etc/nginx/nginx.conf
RUN rm /etc/nginx/sites-enabled/default
RUN ln -s /musicbrainz-server/admin/nginx/mbserver-rewrites.conf /etc/nginx/
RUN ln -s /etc/nginx/sites-available/001-musicbrainz /etc/nginx/sites-enabled/
RUN ln -s /musicbrainz-server/admin/nginx/nginx.conf /etc/nginx/
RUN crontab /crons.conf

VOLUME  ["/media/dbdump"]
WORKDIR /musicbrainz-server
CMD ["/start.sh"]
