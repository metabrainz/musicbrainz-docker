#!/bin/bash
eval $( /usr/bin/perl -Mlocal::lib )
. /exports.txt
/bin/bash /musicbrainz-server/admin/cron/slave.sh
