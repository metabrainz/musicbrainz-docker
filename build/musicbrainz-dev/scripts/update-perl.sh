#!/bin/bash

set -e -u

cd /musicbrainz-server

diff /DBDefs.pm lib/DBDefs.pm || cat /DBDefs.pm > lib/DBDefs.pm

cpanm --installdeps --notest --with-develop .
cpanm --notest \
  Catalyst::Plugin::StackTrace \
  File::Slurp \
  Plack::Handler::Starlet \
  Plack::Middleware::Debug::Base \
  Server::Starter \
  Starlet \
  Starlet::Server \
  Term::Size::Any
