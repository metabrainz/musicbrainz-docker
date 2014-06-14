FROM ubuntu:latest
MAINTAINER Jeff Sturgis <jeffsturgis@gmail.com>
RUN (echo "deb http://archive.ubuntu.com/ubuntu  $(lsb_release -sc) main restricted universe multiverse" > /etc/apt/sources.list && echo "deb http://archive.ubuntu.com/ubuntu/  $(lsb_release -sc)-updates main restricted universe multiverse" >> /etc/apt/sources.list && echo "deb http://archive.ubuntu.com/ubuntu/  $(lsb_release -sc)-backports main restricted universe multiverse" >> /etc/apt/sources.list && echo "deb http://archive.ubuntu.com/ubuntu/  $(lsb_release -sc)-security main restricted universe multiverse" >> /etc/apt/sources.list)
RUN apt-get update

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y git-core postgresql-9.3
RUN apt-get install -y memcached redis-server build-essential libxml2-dev libpq-dev libexpat1-dev libdb-dev libicu-dev liblocal-lib-perl cpanminus

RUN git clone --recursive https://github.com/metabrainz/musicbrainz-server.git musicbrainz-server && cd musicbrainz-server
RUN echo "eval $( perl -Mlocal::lib )" >> ~/.bashrc && . ~/.bashrc
RUN cat /musicbrainz-server/Makefile.PL | grep ^requires > cpanfile
RUN cpanm --installdeps --notest .
RUN cpanm Plack::Middleware::Debug::Base Catalyst::Plugin::Cache::HTTP Catalyst::Plugin::StackTrace Cache::Memcached::Fast JSON::Any Cache::Memory Digest::MD5::File Term::Size::Any

ADD DBDefs.pm /musicbrainz-server/lib/
ADD scripts/start.sh /start.sh

EXPOSE 5000
VOLUME  ["/media/dbdump"]
WORKDIR /musicbrainz-server
ENTRYPOINT ["/start.sh"]
