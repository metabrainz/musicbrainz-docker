#!/bin/bash
DB_PORT_5432_TCP_ADDR=$(cat /etc/hosts | grep "db" | sed -r 's/[a-z]+//g' | sed 's/ *$//')
DB_PORT_5432_TCP_PORT=5432
echo $DB_PORT_5432_TCP_PORT > /test.sh 
export DB_PORT_5432_TCP_PORT 
export DB_PORT_5432_TCP_ADDR
/bin/bash /musicbrainz-server/admin/cron/slave.sh
