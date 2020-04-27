#!/usr/bin/env perl

use strict;
use warnings;
use lib "/musicbrainz-server/lib";
use DBDefs;

my $socket = DBDefs->RENDERER_SOCKET;

system("rm $socket");
system("/musicbrainz-server/script/start_renderer.pl --daemonize --socket $socket");
