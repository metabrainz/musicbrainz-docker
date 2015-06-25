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
    cron

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
    TURNSTEP/DBD-Pg-3.4.2.tar.gz

RUN cd /musicbrainz-server/ && npm i && ./node_modules/.bin/gulp

ADD DBDefs.pm /musicbrainz-server/lib/
ADD scripts/start.sh /start.sh
ADD scripts/crons.conf /crons.conf
ADD scripts/replication.sh /replication.sh
ADD scripts/createdb.sh /createdb.sh
ADD scripts/recreatedb.sh /recreatedb.sh

RUN crontab /crons.conf

EXPOSE 5000
VOLUME  ["/media/dbdump"]
WORKDIR /musicbrainz-server
CMD ["/start.sh"]
