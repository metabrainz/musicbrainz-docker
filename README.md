musicbrainz slave server with search and replication
==================

This is a **development version** featuring Solr-based search.
Check out the branch [`master`](https://github.com/metabrainz/musicbrainz-docker/tree/master) for Lucene-based search.

[![Build Status](https://travis-ci.org/metabrainz/musicbrainz-docker.svg?branch=mbvm-38-dev)](https://travis-ci.org/metabrainz/musicbrainz-docker)

This repo contains everything needed to run a musicbrainz slave server with search and replication in docker.
It requires **Docker Compose 1.21.1** or higher.
You will need a little over 100 gigs of free disk space to run this with replication.
(If you create a VM to install in, provision additional disk space for your system.)

### Versions
* Current MB Branch: [v-2019-08-08](musicbrainz-dockerfile/Dockerfile#L32)
* Current DB_SCHEMA_SEQUENCE: [25](musicbrainz-dockerfile/DBDefs.pm#L112)
* Postgres Version: [9.5](docker-compose.yml)
  (can be changed by setting the environement variable `POSTGRES_VERSION`)
* MB Solr search server: [3.1.1](solr-dockerfile/Dockerfile#L1)
* Search Index Rebuilder: [1.0.2](sir-dockerfile/Dockerfile#L31)

### Installation

###### Install and Start
* Make sure you have installed docker and docker-compose then:
* `git clone https://github.com/metabrainz/musicbrainz-docker.git`
* `cd musicbrainz-docker`
* `sudo docker-compose up -d`

  Or to expose the db, mq, redis and search ports:

  `sudo docker-compose -f docker-compose.yml -f compose/public.yml up -d`
* Set the token you got from musicbrainz (see [instructions for generating a token](http://blog.musicbrainz.org/2015/05/19/schema-change-release-2015-05-18-including-upgrade-instructions/)).

  `sudo docker-compose exec musicbrainz /set-token.sh <replication token>`

### Create database
Create the database, download the latest dumps and populate the database

* `sudo docker-compose run --rm musicbrainz /createdb.sh -fetch`

Create the database, and populate the database with existing dumps

* `sudo docker-compose run --rm musicbrainz /createdb.sh`

#### Development setup

For development, load sample data instead of full dump by adding the flag `-sample` to the above commands.
Then use `compose/musicbrainz-development.yml` override file to enable standalone mode.

### Build search indexes
In order to use the search functions of the web site/API you will need to build search indexes.

* `sudo docker-compose run --rm indexer python -m sir reindex`

Depending on your machine, this can take quite a long time (not as long as the old indexer took though).

#### Live indexing
To keep the search indexes in sync with the database, you can set up live indexing as follows:

0. Start services without live indexing with:

   `sudo docker-compose up -d`

1. Configure exchanges and queues on `mq` for `indexer` with:

   `sudo docker-compose exec indexer python -m sir amqp_setup`

2. Load and configure AMQP extension in `db` for `indexer` with:

   `sudo admin/create-amqp-extension`

3. Install triggers in `db` for `indexer` with:

   `sudo admin/setup-amqp-triggers install`

Then you will be able to live index database for search as follows:

  `sudo docker-compose exec indexer python -m sir amqp_watch`

Or using `compose/live-indexing.yml` override file:

   `sudo docker-compose -f docker-compose.yml -f compose/live-indexing.yml up -d`

### Replication
Replication is run as a cronjob, you can update the [crons.conf](musicbrainz-dockerfile/scripts/crons.conf) file to change when replication will be run.

You can view the replication log file while it is running with
* `sudo docker-compose exec musicbrainz /usr/bin/tail -f slave.log`

You can view the replication log file once it is done with
* `sudo docker-compose exec musicbrainz /usr/bin/tail slave.log.1`

### If you need to recreate the database
you will need to enter the postgres password that you set in [postgres.env](postgres-dockerfile/postgres.env).
* `sudo docker-compose run --rm musicbrainz /recreatedb.sh`
or to recreate and fetch new data dumps
* `sudo docker-compose run --rm musicbrainz /recreatedb.sh -fetch`

### Handling Schema Updates
When there is a schema change you will need to follow the directions posted by the musicbrainz team to update the schema.

###### The usual process to update the schema is:

* Ensure you’ve replicated up to the most recent replication packet available with the old schema.
  (If you’re not sure, run `sudo docker-compose exec musicbrainz /replication.sh`.)
* Switch to the new code with:
* Run bash in the container: `sudo docker-compose exec musicbrainz bash`.
  * Checkout the new branch: `git fetch origin && git checkout NEW_SCHEMA_BRANCH`.
  * Run the upgrade script: `eval $( perl -Mlocal::lib ) && ./upgrade.sh`.
  * Exit bash `exit`.
* Set DB_SCHEMA_SEQUENCE to the NEW_SCHEMA_NUM in the [DBDefs.pm file](musicbrainz-dockerfile/DBDefs.pm#L112)
* `sudo docker-compose stop musicbrainz` then `sudo docker-compose build musicbrainz` then `sudo docker-compose up -d --no-deps musicbrainz`

If anything doesn't work please create an issue with environment info:
```bash
echo musicbrainz-docker version: `git describe --always --broken --dirty --tags` && \
docker-compose version && \
docker version
```
