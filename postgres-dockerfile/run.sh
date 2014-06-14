#!/bin/sh

docker run -P -d --volumes-from postgresqldata -u 0 --name postgresql postgresql-image
