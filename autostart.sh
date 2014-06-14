#!/bin/sh
apt-get install -y supervisor
cp musicbrainz.conf /etc/supervisor/conf.d/
supervisorctl reread
supervisorctl update
