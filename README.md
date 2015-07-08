musicbrainz docker container
==================

This repo contains everything needed to run a musicbrainz slave server with replication in a docker container.
You will need a little over 20 gigs of free space to run this with replication.

### Configuration
* Set the path where you want to store the downloaded data dumps in [docker-compose.yml](./docker-compose.yml).
* If you already have data dumps in this path they can be loaded instead of downloading new dumps, see [Create Database](#create-database).
* Set REPLICATION_ACCESS_TOKEN in the [DBDefs.pm file](musicbrainz-dockerfile/DBDefs.pm#L117) to the token you got from musicbrainz (instructions for generating a token are [here](http://blog.musicbrainz.org/2015/05/19/schema-change-release-2015-05-18-including-upgrade-instructions/)).

### Installation

###### Install and Start
* Make sure you have installed docker and docker-compose then:
* `git clone this-repo`
* `cd this-repo`
* `sudo docker-compose up -d`

### Create database
Create the database, download the latest dumps and populate the database

* `sudo docker-compose run --rm  musicbrainz /createdb.sh -fetch`

Create the database, and populate the database with existing dumps

* `sudo docker-compose run --rm  musicbrainz /createdb.sh`

### Recreate database
you will need to enter the postgres password that you set in [postgres.env](postgres-dockerfile/postgres.env).
* `sudo docker-compose run -ti --rm  musicbrainz /recreatedb.sh`

### Handling Schema Updates
When there is a schema change you will need to follow the directions posted by the musicbrainz team to update the schema.

* Run the service and start bash:

`sudo docker-compose run --rm  musicbrainz bash`

The usual process to update the schema is:

* Ensure you’ve replicated up to the most recent replication packet available with the old schema. (if you’re not sure, run ./admin/replication/LoadReplicationChanges and see what it tells you).
* In the running container Switch to the new code with git fetch origin followed by git checkout $NEW_SCHEMA_BRANCH and also update the Dockerfile to the new branch.
* In the running container run ./upgrade.sh
* Set DB_SCHEMA_SEQUENCE to $NEW_SCHEMA_NUM in this repo musicbrainz-dockerfile/DBDefs.pm
* On the host machine stop and remove the musicbrainz container and image
* On the host machine make sure the postgresql container is running
* In musicbrainz-dockerfile run `sudo ./build.sh`
* In musicbrainz-dockerfile run `sudo ./run.sh`

That’s it!
