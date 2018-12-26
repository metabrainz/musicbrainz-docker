#!/bin/sh

echo "listen_addresses='*'" >> /var/lib/postgresql/data/postgresql.conf
echo "shared_buffers = 512MB" >> /var/lib/postgresql/data/postgresql.conf
echo "shared_preload_libraries = 'pg_amqp.so'" >> /var/lib/postgresql/data/postgresql.conf

exec /docker-entrypoint.sh 
