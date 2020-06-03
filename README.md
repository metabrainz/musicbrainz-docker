# MusicBrainz slave server with search and replication

[![Build Status](https://travis-ci.org/metabrainz/musicbrainz-docker.svg?branch=master)](https://travis-ci.org/metabrainz/musicbrainz-docker)

This repo contains everything needed to run a musicbrainz slave server with search and replication in docker.

## Table of contents

<!-- toc -->

- [Prerequisites](#prerequisites)
  * [Recommended hardware/VM](#recommended-hardwarevm)
  * [Required software](#required-software)
  * [External documentation](#external-documentation)
- [Components version](#components-version)
- [Installation](#installation)
  * [Build Docker images](#build-docker-images)
  * [Create database](#create-database)
  * [Start website](#start-website)
  * [Build search indexes](#build-search-indexes)
  * [Enable replication](#enable-replication)
  * [Enable live indexing](#enable-live-indexing)
- [Advanced configuration](#advanced-configuration)
  * [Local changes](#local-changes)
  * [Docker environment variables](#docker-environment-variables)
  * [Docker Compose overrides](#docker-compose-overrides)
- [Test setup](#test-setup)
- [Development setup](#development-setup)
- [Helper scripts](#helper-scripts)
  * [Recreate database](#recreate-database)
  * [Recreate database with indexed search](#recreate-database-with-indexed-search)
- [Update](#update)
- [Issues](#issues)

<!-- tocstop -->

## Prerequisites

### Recommended hardware/VM

* CPU: 16 threads (or 2 without indexed search)
* RAM: 16 GB (or 4 without indexed search)
* Disk Space: 150 GB (or 60 without indexed search)
            + system disk usage
### Required software

* Docker Compose 1.21.1 (or higher), see [how to install Docker Compose](https://docs.docker.com/compose/install/)
* Git
* GNU Bash 4 (or higher) utilities, for [admin helper scripts](admin/) only
  (On macOS, use [Homebrew](https://brew.sh/).)
* Linux or macOS
  (Windows is not documented yet, it is recommended to use Ubuntu via VirtualBox instead.)

If you use Ubuntu 19.10 or later, the above requirements can be set up by running:
```bash
sudo apt-get update && \
sudo apt-get install docker.io docker-compose git && \
sudo systemctl enable --now docker.service
```

If you use [UFW](https://help.ubuntu.com/community/UFW) to manage your firewall:
* [ufw-docker](https://github.com/chaifeng/ufw-docker) or any other way to fix the Docker and UFW security flaw.

### External documentation

* Introduction: [Getting started with Docker](https://docs.docker.com/get-started/)
  and [Overview of Docker Compose](https://docs.docker.com/compose/)
* Command-line: [<code>docker</code> CLI reference](https://docs.docker.com/engine/reference/commandline/docker/)
  and [<code>docker-compose</code> CLI reference](https://docs.docker.com/compose/reference/overview/)
* Configuration: [Compose file version 3 reference](https://docs.docker.com/compose/compose-file/)

## Components version

* Current MB Branch: [v-2020-06-02](build/musicbrainz/Dockerfile#L50)
* Current DB_SCHEMA_SEQUENCE: [25](build/musicbrainz/DBDefs.pm#L112)
* Postgres Version: [12](docker-compose.yml)
  (can be changed by setting the environment variable `POSTGRES_VERSION`)
* MB Solr search server: [3.1.3](docker-compose.yml#L70)
  (can be changed by setting the environment variable `MB_SOLR_VERSION`)
* Search Index Rebuilder: [1.0.2](build/sir/Dockerfile#L31)

## Installation

This section is about installing MusicBrainz slave server (mirror)
with locally indexed search and automatically replicated data.

Download this repository and change current working directory with:

```bash
git clone https://github.com/metabrainz/musicbrainz-docker.git
cd musicbrainz-docker
```

### Build Docker images

Docker images for composed services should be built once using:

```bash
sudo docker-compose build
```

### Create database

:gear: Postgres shared buffers are set to 2GB by default.
Before running this step, you should consider [modifying your memory
settings](#modify-memory-settings) in order to give your database a
sufficient amount of ram, otherwise your database could run very slowly.

Download latest full data dumps and create the database with:

```bash
sudo docker-compose run --rm musicbrainz createdb.sh -fetch
```

<!-- TODO: document available FTP servers -->
<!-- TODO: document how to load local dumps -->

### Start website

Make the local website available at <http://localhost:5000> with:

```bash
sudo docker-compose up -d
```

At this point the local website will show data loaded from the dumps
only. For indexed search and replication, keep going!

### Build search indexes

Depending on your available ressources in CPU/RAM vs. bandwidth, run:

* Either:

  ```bash
  sudo docker-compose exec indexer python -m sir reindex
  ```

  :gear: Java heap for Solr is set to 2GB by default.
  Before running this step, you should consider [modifying your memory
  settings](#modify-memory-settings) in order to give your search server a
  sufficient amount of ram, otherwise your search server could run very slowly.

  (This option is known to take 4½ hours with 16 CPU threads and 16 GB RAM.)

* Or, if you have more available bandwidth than CPU/RAM:

  ```bash
  sudo docker-compose run --rm musicbrainz fetch-dump.sh search
  sudo docker-compose run --rm search load-search-indexes.sh
  ```

  (This option downloads 28GB of Zstandard-compressed archives from FTP.)

:warning: Search indexes are not included in replication.
You will have to rebuild search indexes regularly to keep it up-to-date.

At this point indexed search works on the local website/webservice.
For replication, keep going!

### Enable replication

#### Set replication token

First, copy your MetaBrainz access token
(see [instructions for generating a token](http://blog.metabrainz.org/2015/05/19/schema-change-release-2015-05-18-including-upgrade-instructions/))
and paste when prompted to by the following command:

```bash
admin/set-replication-token
```

The token will be written to the file [`local`](local/)`/secrets/metabrainz_access_token`.

Then, grant access to the token for replication with:

```bash
admin/configure add replication-token
sudo docker-compose up -d
```

#### Run replication once

Run replication script once to catch up with latest database updates:

```bash
sudo docker-compose exec musicbrainz replication.sh &
sudo docker-compose exec musicbrainz /usr/bin/tail -f slave.log
```

<!-- TODO: estimate replication time per missing day -->

#### Schedule replication

Enable replication as a cron job of `root` user in `musicbrainz`
service container with:

```bash
admin/configure add replication-cron
sudo docker-compose up -d
```

By default, it replicates data every day at 3 am UTC.
To change that, see [advanced configuration](#advanced-configuration).

You can view the replication log file while it is running with:

```bash
sudo docker-compose exec musicbrainz tail --follow slave.log
```

You can view the replication log file after it is done with:

```bash
sudo docker-compose exec musicbrainz tail slave.log.1
```

### Enable live indexing

:warning: Search indexes’ live update for slave server is **not stable** yet.
Until then, it should be considered as an experimental feature.
Do not use it if you don't want to get your hands dirty.

1. Disable [replication cron job](#schedule-replication) if you enabled it:

   ```
   admin/configure rm replication-cron
   sudo docker-compose up -d
   ```

2. Make indexer goes through [AMQP Setup](https://sir.readthedocs.io/en/latest/setup/index.html#amqp-setup) with:

   ```bash
   sudo docker-compose exec indexer python -m sir amqp_setup
   admin/create-amqp-extension
   admin/setup-amqp-triggers install
   ```

3. [Build search indexes](#build-search-indexes)
   either if it has not been built
   or if it is outdated.

4. Make indexer watch reindex messages with:

   ```bash
   admin/configure add live-indexing-search
   sudo docker-compose up -d
   ```

5. Reenable [replication cron job](#schedule-replication) if you disabled it at 1.

   ```
   admin/configure add replication-cron
   sudo docker-compose up -d
   ```

## Advanced configuration

### Local changes

You should **preferably not** locally change any file being tracked by git.
Check your working tree is clean with:

```bash
git status
```

Git is set to ignore the followings you are encouraged to write to:

* `.env` file,
* any new file under [`local`](local/) directory.

### Docker environment variables

There are many ways to set [environment variables in Docker Compose](https://docs.docker.com/compose/environment-variables/),
the most convenient here is probably to edit the hidden file `.env`.

You can then check values to be passed to containers using:

```bash
sudo docker-compose config
```

Finally, make Compose picks up configuration changes with:

```bash
sudo docker-compose up -d
```
#### Customize web server host:port

By default, the web server listens at <http://localhost:5000>

This can be changed using the two Docker environment variables
`MUSICBRAINZ_WEB_SERVER_HOST` and `MUSICBRAINZ_WEB_SERVER_PORT`.

#### Customize replication schedule

By default, there is no crontab file in `musicbrainz` service container.

If you followed the steps to [schedule replication](#schedule-replication),
then the crontab file used by `musicbrainz` service is bound to
[`default/replication.cron`](default/replication.cron).

This can be changed by creating a custom crontab file under
[`local/`](local/) directory,
[and finally](https://docs.docker.com/storage/bind-mounts/#choose-the--v-or---mount-flag)
setting the Docker environment variable `MUSICBRAINZ_CRONTAB_PATH` to
its path.

#### Customize search indexer configuration

By default, the configuration file used by `indexer` service is bound
to [`default/indexer.ini`](default/indexer.ini).

This can be changed by creating a custom configuration file under
[`local/`](local/) directory,
[and finally](https://docs.docker.com/storage/bind-mounts/#choose-the--v-or---mount-flag)
setting the Docker environment variable `SIR_CONFIG_PATH` to its path.

### Docker Compose overrides

In Docker Compose, it is possible to override the base configuration using
[multiple Compose files](https://docs.docker.com/compose/extends/#multiple-compose-files).

Some overrides are available under [`compose`](compose/) directory.
Feel free to write your own overrides under [`local`](local/) directory.

The helper script [`admin/configure`](admin/configure) is able to:
* **list** available compose files, with a descriptive summary
* **show** the value of `COMPOSE_FILE` variable in Docker environment
* set/update `COMPOSE_FILE` in `.env` file **with** a list of compose files
* set/update `COMPOSE_FILE` in `.env` file with **add**ed or
  **r**e**m**oved compose files

Try <code>admin/configure help</code> for more information.

#### Publish ports of all services

To publish ports of services `db`, `mq`, `redis` and `search`
(additionally to `musicbrainz`) on the host, simply run:

```bash
admin/configure add publishing-all-ports
sudo docker-compose up -d
```

#### Modify memory settings

By default, each of `db` and `search` services have about 2GB of RAM.
You may want to set more or less memory for any of these services,
depending on your available resources or on your priorities.

For example, to set 4GB to each of `db` and `search` services,
create a file `local/compose/memory-settings.yml` as follows:

```yaml
version: '3.1'

# Description: Customize memory settings

services:
  db:
    command: postgres -c "shared_buffers=4GB" -c "shared_preload_libraries=pg_amqp.so"
  search:
    environment:
      - SOLR_HEAP=4g
```

See [`postgres`](https://www.postgresql.org/docs/current/app-postgres.html)
for more configuration parameters and options to pass to `db` service,
and [`solr.in.sh`](https://github.com/apache/lucene-solr/blob/releases/lucene-solr/7.7.2/solr/bin/solr.in.sh)
for more environment variables to pass to `search` service,

Then enable it by running:

```bash
admin/configure add local/compose/memory-settings.yml
sudo docker-compose up -d
```

## Test setup

If you just need a small server with sample data to test your own SQL
queries and/or MusicBrainz Web Service calls, you can run the below
commands instead of following the above [installation](#installation):

```bash
git clone https://github.com/metabrainz/musicbrainz-docker.git
cd musicbrainz-docker
admin/configure add musicbrainz-standalone
sudo docker-compose build
sudo docker-compose run --rm musicbrainz createdb.sh -sample -fetch
sudo docker-compose up -d
```

The two differences are:
1. sample data dump is downloaded instead of full data dumps,
2. MusicBrainz Server runs in standalone mode instead of slave mode.

[Build search indexes](#build-search-indexes) and
[Enable live indexing](#enable-live-indexing) are the same.

Replication is not applicable to test setup.

## Development setup

Required disk space is much lesser than normal setup: 15GB to be safe.

For local development of MusicBrainz Server, you can run the below
commands instead of following the above [installation](#installation):

```bash
git clone --recursive https://github.com/metabrainz/musicbrainz-server.git
MUSICBRAINZ_SERVER_LOCAL_ROOT=$PWD/musicbrainz-server
git clone https://github.com/metabrainz/musicbrainz-docker.git
cd musicbrainz-docker
echo MUSICBRAINZ_SERVER_LOCAL_ROOT="$MUSICBRAINZ_SERVER_LOCAL_ROOT" >> .env
admin/configure add musicbrainz-dev
sudo docker-compose up -d
sudo docker-compose run --rm musicbrainz createdb.sh -sample -fetch
```

The four differences are:
1. sample data dump is downloaded instead of full data dumps,
2. MusicBrainz Server runs in standalone mode instead of slave mode,
3. development mode is enabled (but Catalyst debug),
4. MusicBrainz Server code is in `musicbrainz-server/` directory.

After changing code in `musicbrainz-server/`, it can be run as follows:

```bash
sudo docker-compose restart musicbrainz
```

[Build search indexes](#build-search-indexes) and
[Enable live indexing](#enable-live-indexing) are the same.

Replication is not applicable to development setup.

## Helper scripts

There are two directories with helper scripts:

* [`admin/`](admin/) contains helper scripts to be run from the host.
  For more information, use the `--help` option:

  ```bash
  admin/check-search-indexes --help
  admin/delete-search-indexes --help
  ```

  See also:
  * [Docker Compose overrides](#docker-compose-overrides) for more
    information about `admin/configure`.
  * [Enable live indexing](#enable-live-indexing) for more information
    about `admin/create-amqp-extension`
    and `admin/setup-amqp-triggers`.
  * [Enable replication](#enable-replication) for more information
    about `admin/set-replication-token`.

* [`build/musicbrainz/scripts/`](build/musicbrainz/scripts/) contains
  helper scripts to be run from the container attached to the service
  `musicbrainz`. Most of these scripts are not for direct use, but
  [createdb.sh](#create-database) and below-documented
  [recreatedb.sh](#recreate-database).

<!-- TODO: add help option to build/*/scripts/* -->

### Recreate database

If you need to recreate the database, you will need to enter the
postgres password set in [postgres.env](default/postgres.env):

* `sudo docker-compose run --rm musicbrainz recreatedb.sh`

or to fetch new data dumps before recreating the database:

* `sudo docker-compose run --rm musicbrainz recreatedb.sh -fetch`

### Recreate database with indexed search

If you need to recreate the database with indexed search,

```bash
admin/configure rm replication-cron # if replication is enabled
sudo docker-compose stop
sudo docker-compose run --rm musicbrainz fetch-dump.sh both
sudo docker-compose run --rm mq purge-queues.sh
sudo docker-compose run --rm search load-search-indexes.sh --force
sudo docker-compose run --rm musicbrainz recreatedb.sh
sudo docker-compose up -d
admin/setup-amqp-triggers clean
admin/setup-amqp-triggers install
admin/configure add replication-cron
sudo docker-compose up -d
```

 you will need to enter the
postgres password set in [postgres.env](default/postgres.env):

* `sudo docker-compose run --rm musicbrainz recreatedb.sh`

or to fetch new data dumps before recreating the database:

* `sudo docker-compose run --rm musicbrainz recreatedb.sh -fetch`

## Update

Check your working tree is clean with:

```bash
git status
```

Check your currently checked out version:

```bash
git describe --dirty
```

Check [releases](https://github.com/metabrainz/musicbrainz-docker/releases) for update instructions.

## Issues

If anything doesn't work please create an issue with versions info:

```bash
echo MusicBrainz Docker: `git describe --always --broken --dirty --tags` && \
echo Docker Compose: `docker-compose version --short` && \
sudo docker version -f 'Docker Client/Server: {{.Client.Version}}/{{.Server.Version}}'
```
