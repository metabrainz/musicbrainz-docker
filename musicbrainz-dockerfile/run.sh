#!/bin/bash
DBDUMP=/media/jeff/storage/mbdata

echo Starting musicbrainz...
docker run --name musicbrainz -ti -p 5000:5000 --link postgresql:db -v $DBDUMP:/media/dbdump:rw musicbrainz-image /bin/bash
