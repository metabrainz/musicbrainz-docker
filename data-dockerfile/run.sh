#!/bin/sh
HOSTDATADIR="/media/jeff/storage/mbdata"
docker run -d -v $HOSTDATADIR:/dbdata --name postgresqldata postgresql_data
