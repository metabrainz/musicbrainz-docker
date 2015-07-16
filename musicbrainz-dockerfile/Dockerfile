FROM ubuntu:latest
MAINTAINER Jeff Sturgis <jeffsturgis@gmail.com>
RUN (echo "deb http://archive.ubuntu.com/ubuntu  $(lsb_release -sc) main restricted universe multiverse" > /etc/apt/sources.list && echo "deb http://archive.ubuntu.com/ubuntu/  $(lsb_release -sc)-updates main restricted universe multiverse" >> /etc/apt/sources.list && echo "deb http://archive.ubuntu.com/ubuntu/  $(lsb_release -sc)-backports main restricted universe multiverse" >> /etc/apt/sources.list && echo "deb http://archive.ubuntu.com/ubuntu/  $(lsb_release -sc)-security main restricted universe multiverse" >> /etc/apt/sources.list)
RUN apt-get update

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y git-core postgresql-9.3
RUN apt-get install -y \
    memcached \
    redis-server \
    build-essential \
    libxml2-dev libpq-dev \
    libexpat1-dev \
    libdb-dev \
    libicu-dev \
    liblocal-lib-perl \
    cpanminus \
    cron \
    nginx

RUN git clone --recursive https://github.com/metabrainz/musicbrainz-server.git musicbrainz-server && \
    cd musicbrainz-server && \
    git checkout v-2015-05-18-schema-change

RUN echo "eval $( perl -Mlocal::lib )" >> ~/.bashrc && . ~/.bashrc
RUN curl -sL https://deb.nodesource.com/setup | sudo bash -

RUN apt-get install -y nodejs
RUN cat /musicbrainz-server/Makefile.PL | grep ^requires > cpanfile
RUN cpanm --installdeps --notest .
RUN cpanm --notest SARTAK/MooseX-Role-Parameterized-0.27.tar.gz \
    Plack::Middleware::Debug::Base \
    Catalyst::Plugin::Cache::HTTP \
    Catalyst::Plugin::StackTrace \
    Cache::Memcached::Fast \
    JSON::Any Cache::Memory \
    Digest::MD5::File \
    Term::Size::Any \
    LWP::Protocol::https \
    Starlet \
    Plack::Handler::Starlet \
    Starlet::Server \
    Server::Starter \
    TURNSTEP/DBD-Pg-3.4.2.tar.gz

RUN cd /musicbrainz-server/ && npm i && ./node_modules/.bin/gulp

ADD DBDefs.pm /musicbrainz-server/lib/
ADD scripts/start.sh /start.sh
ADD scripts/crons.conf /crons.conf
ADD scripts/replication.sh /replication.sh
ADD scripts/createdb.sh /createdb.sh
ADD scripts/recreatedb.sh /recreatedb.sh
ADD 001-musicbrainz /etc/nginx/sites-available/001-musicbrainz

RUN rm /etc/nginx/nginx.conf
RUN rm /etc/nginx/sites-enabled/default
RUN ln -s /musicbrainz-server/admin/nginx/mbserver-rewrites.conf /etc/nginx/
RUN ln -s /etc/nginx/sites-available/001-musicbrainz /etc/nginx/sites-enabled/
RUN ln -s /musicbrainz-server/admin/nginx/nginx.conf /etc/nginx/
RUN crontab /crons.conf

VOLUME  ["/media/dbdump"]
WORKDIR /musicbrainz-server
CMD ["/start.sh"]
