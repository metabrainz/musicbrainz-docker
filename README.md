musicbrainz slave server with search and replication
==================

[![Build Status](https://travis-ci.org/jsturgis/musicbrainz-docker.svg?branch=master)](https://travis-ci.org/jsturgis/musicbrainz-docker)

This repo contains everything needed to run a musicbrainz slave server with search and replication in docker.
You will need a little over 20 gigs of free space to run this with replication.

### Versions
* Current MB Branch: [v-2016-05-23-schema-change-v2](musicbrainz-dockerfile/Dockerfile#L22)
* Current DB_SCHEMA_SEQUENCE: [23](musicbrainz-dockerfile/DBDefs.pm#L95)
* Postgres Version: [9.5](postgres-dockerfile/Dockerfile#L1)

### Configuration
* Set the path where you want to store the downloaded data dumps in [docker-compose.yml](./docker-compose.yml).
* If you already have data dumps in this path they can be loaded instead of downloading new dumps, see [Create Database](#create-database).

### Installation

###### Install and Start
* Make sure you have installed docker and docker-compose then:
* `git clone this-repo`
* `cd this-repo`
* `sudo docker-compose up -d`
* Set the token you got from musicbrainz (instructions for generating a token are [here](http://blog.musicbrainz.org/2015/05/19/schema-change-release-2015-05-18-including-upgrade-instructions/)).
* `sudo docker exec musicbrainzdocker_musicbrainz_1 /set-token.sh <replication token>`

### Create database
Create the database, download the latest dumps and populate the database

* `sudo docker-compose run --rm musicbrainz /createdb.sh -fetch`

Create the database, and populate the database with existing dumps

* `sudo docker-compose run --rm musicbrainz /createdb.sh`

### Build search indexes
In order to use the search functions of the web site/API you will need to build search indexes.

* `sudo docker-compose run --rm indexer /home/search/index.sh`

### If you need to recreate the database
you will need to enter the postgres password that you set in [postgres.env](postgres-dockerfile/postgres.env).
* `sudo docker-compose run --rm musicbrainz /recreatedb.sh`

### Handling Schema Updates
When there is a schema change you will need to follow the directions posted by the musicbrainz team to update the schema.

###### The usual process to update the schema is:

* Ensure you’ve replicated up to the most recent replication packet available with the old schema. (if you’re not sure, run `sudo docker exec musicbrainzdocker_musicbrainz_1 ./admin/replication/LoadReplicationChanges`).
* Switch to the new code with:
* Run bash in the container: `sudo docker exec -ti musicbrainzdocker_musicbrainz_1 bash`.
* Checkout the new branch: `git fetch origin && git checkout NEW_SCHEMA_BRANCH`.
* Run the upgrade script: `./upgrade.sh`.
* Exit bash `exit`.
* Set DB_SCHEMA_SEQUENCE to the NEW_SCHEMA_NUM in the [DBDefs.pm file](musicbrainz-dockerfile/DBDefs.pm#L95)
* `sudo docker-compose stop musicbrainz` then `sudo docker-compose build musicbrainz` then `sudo docker-compose up -d --no-deps musicbrainz`

If anything doesn't work create an issue and submit a pull request.
