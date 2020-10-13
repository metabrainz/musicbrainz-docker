#!/bin/bash

set -e -u

cd /musicbrainz-server

diff /DBDefs.pm lib/DBDefs.pm || cat /DBDefs.pm > lib/DBDefs.pm

cpanm --installdeps --notest --with-develop .
cpanm --notest \
  Cache::Memcached::Fast \
  Cache::Memory \
  Catalyst::Plugin::Cache::HTTP \
  Catalyst::Plugin::StackTrace \
  Digest::MD5::File \
  File::Slurp \
  JSON::Any \
  LWP::Protocol::https \
  Plack::Handler::Starlet \
  Plack::Middleware::Debug::Base \
  Server::Starter \
  Starlet \
  Starlet::Server \
  Term::Size::Any

yarn

dockerize -wait tcp://db:5432 -timeout 60s -wait tcp://mq:5672 -timeout 60s -wait tcp://redis:6379 -timeout 60s ./script/compile_resources.sh

start_mb_renderer.pl
start_server --port=5000 -- plackup -I lib -s Starlet -E deployment --nproc ${MUSICBRAINZ_SERVER_PROCESSES} --pid fcgi.pid
