# MusicBrainz slave server with search and replication

This is a **development version** featuring Solr-based search.
Check out the branch [`master`](https://github.com/metabrainz/musicbrainz-docker/tree/master) for Lucene-based search.

[![Build Status](https://travis-ci.org/metabrainz/musicbrainz-docker.svg?branch=mbvm-38-dev)](https://travis-ci.org/metabrainz/musicbrainz-docker)

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
  * [Enable live indexing](#enable-live-indexing)
  * [Enable replication](#enable-replication)
- [Advanced configuration](#advanced-configuration)
  * [Local changes](#local-changes)
  * [Docker environment variables](#docker-environment-variables)
  * [Docker Compose overrides](#docker-compose-overrides)
- [Development setup](#development-setup)
- [Helper scripts](#helper-scripts)
  * [Recreate database](#recreate-database)
- [Update (after v1.0.0)](#update-after-v100)
- [Issues](#issues)

<!-- tocstop -->

## Prerequisites

### Recommended hardware/VM

* CPU: 16 threads (or 2 without indexed search)
* RAM: 16 GB (or 4 without indexed search)
* Disk Space: 100 GB (or 50 without indexed search)
            + system disk usage
### Required software

* Docker Compose 1.21.1 (or higher), see [how to install Docker Compose](https://docs.docker.com/compose/install/)
* Git
* GNU Bash 4 (or higher) utilities, for [admin helper scripts](admin/) only
* [ufw-docker](https://github.com/chaifeng/ufw-docker) or any other way to fix the Docker and UFW security flaw,
  if you use [UFW](https://help.ubuntu.com/community/UFW) to manage your firewall.

### External documentation

* Introduction: [Getting started with Docker](https://docs.docker.com/get-started/)
  and [Overview of Docker Compose](https://docs.docker.com/compose/)
* Command-line: [<code>docker</code> CLI reference](https://docs.docker.com/engine/reference/commandline/docker/)
  and [<code>docker-compose</code> CLI reference](https://docs.docker.com/compose/reference/overview/)
* Configuration: [Compose file version 3 reference](https://docs.docker.com/compose/compose-file/)

## Components version

* Current MB Branch: [v-2019-08-08](build/musicbrainz/Dockerfile#L32)
* Current DB_SCHEMA_SEQUENCE: [25](build/musicbrainz/DBDefs.pm#L112)
* Postgres Version: [9.5](docker-compose.yml)
  (can be changed by setting the environement variable `POSTGRES_VERSION`)
* MB Solr search server: [3.1.1](build/solr/Dockerfile#L1)
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

Download latest full data dumps and create the database with:

```bash
sudo docker-compose run --rm musicbrainz /createdb.sh -fetch
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

```bash
sudo docker-compose exec indexer python -m sir reindex
```

This step is known to take 4½ hours with 16 CPU threads and 16 GB RAM.

At this point indexed search works on the local website/webservice.
For replication, keep going!

### Enable live indexing

It is needed to automatically update search indexes during replication.

First, make indexer goes through [AMQP Setup](https://sir.readthedocs.io/en/latest/setup/index.html#amqp-setup) with:

```bash
sudo docker-compose exec indexer python -m sir amqp_setup
admin/create-amqp-extension
admin/setup-amqp-triggers install
```

Then, make indexer watch reindex messages with:

```bash
admin/configure add live-indexing-search
sudo docker-compose up -d
```

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
docker-compose up -d
```

#### Run replication once

Run replication script once to catch up with latest database updates:

```bash
sudo docker-compose exec musicbrainz /replication.sh &
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

See the [`crontab`](default/replication.cron) used by default.
To change it, see [advanced configuration](#advanced-configuration).

You can view the replication log file while it is running with:

```bash
sudo docker-compose exec musicbrainz tail --follow slave.log
```

You can view the replication log file after it is done with:

```bash
sudo docker-compose exec musicbrainz tail slave.log.1
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

#### Customize replication schedule

Create a new crontab file under [`local`](local/) directory
(or outside of the current working directory).

Then, copy [`replication-cron.yml`](compose/replication-cron.yml) to
[`local/`](local/), and edit this new compose file to replace
`default/replication.cron` with the path to that new crontab file.

Finally, use `admin/configure` script to use this new compose file
instead of `replication-cron.yml`, and makes Compose picks up changes.

## Development setup

Run the below commands instead of following the regular [installation](#installation):

```bash
git clone https://github.com/metabrainz/musicbrainz-docker.git
cd musicbrainz-docker
sudo docker-compose build
sudo docker-compose run --rm musicbrainz /createdb.sh -sample -fetch
admin/configure add musicbrainz-development
sudo docker-compose up -d
```

The two differences are:
1. sample data dump is downloaded instead of full data dumps,
2. MusicBrainz Server runs in standalone mode instead of slave mode.

[Build search indexes](#build-search-indexes) and
[Enable live indexing](#enable-live-indexing) are the same.

Replication is not applicable to development setup.

## Helper scripts

There are two directories with helper scripts:

* [`admin/`](admin/) contains helper scripts to be run from the host.
  For more information, try:

  ```bash
  admin/check-search-indexes --help
  admin/delete-search-indexes --help
  ```

  See [Docker Compose overrides](#docker-compose-overrides) for more
  information about `admin/configure`.
  See [Enable live indexing](#enable-live-indexing) for more
  information about `admin/create-amqp-extension` and
  `admin/setup-amqp-triggers`.

<!-- TODO: add help option to admin/create-amqp-extension -->
<!-- TODO: add help option to admin/setup-amqp-triggers -->

* [`build/musicbrainz/scripts/`](build/musicbrainz/scripts/) contains
  helper scripts to be run from the container attached to the service
  `musicbrainz`. Most of these scripts are not for direct use, but
  [createdb.sh](#create-database) and below-documented
  [recreatedb.sh](#recreate-database).

<!-- TODO: add help option to build/*/scripts/* -->

### Recreate database

If you need to recreate the database, you will need to enter the
postgres password set in [postgres.env](default/postgres.env):

* `sudo docker-compose run --rm musicbrainz /recreatedb.sh`

or to fetch new data dumps before recreating the database:

* `sudo docker-compose run --rm musicbrainz /recreatedb.sh -fetch`

## Update (after v1.0.0)

Check your working tree is clean with:

```bash
git status
```

List newer versions that have been released since then:

```bash
git fetch --prune origin
git log --oneline --simplify-by-decoration origin/master..master
```

Check [releases](https://github.com/metabrainz/musicbrainz-docker/releases) for update instructions.

<!-- TODO: complete schema change instructions (by release v1.0.0) -->

## Issues

If anything doesn't work please create an issue with versions info:

```bash
echo MusicBrainz Docker: `git describe --always --broken --dirty --tags` && \
echo Docker Compose: docker-compose version --short && \
docker version -f 'Docker Client/Server: {{.Client.Version}}/{{.Server.Version}}'
```
