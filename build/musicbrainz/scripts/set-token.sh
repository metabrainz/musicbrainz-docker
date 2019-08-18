#!/bin/bash

if [[ $# != 1 ]]; then
    echo "Usage: $0 <access token>"
    exit -1
fi

grep -v REPLICATION_ACCESS_TOKEN /musicbrainz-server/lib/DBDefs.pm > /tmp/DBDefs.pm
echo -n "sub REPLICATION_ACCESS_TOKEN { \"" >> /tmp/DBDefs.pm
echo -n $1 >> /tmp/DBDefs.pm >> /tmp/DBDefs.pm
echo "\" }" >> /tmp/DBDefs.pm
mv /tmp/DBDefs.pm /musicbrainz-server/lib/DBDefs.pm
