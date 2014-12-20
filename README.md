musicbrainz docker container
==================

This repo contains everything needed to run a musicbrainz slave server with replication.

### Installation

* cd to postgresqldata-docker
* modify the start.sh file to point to a data directory on the host machine
* `sudo ./build.sh`
* `sudo ./start.sh`
* cd to postgresql-docker
* modify the start.sh file to point to a data directory on the host machine
* `sudo ./build.sh`
* `sudo ./start.sh`
* cd to musicbrainz-docker
* modify the start.sh file to point to a data directory on the host machine
* `sudo ./build.sh`
* `sudo ./start.sh`

### Handling Schema Updates
When there is a schema change you will need to follow the directions posted by the musicbrainz team to update the schema.
You can run bash in the running musicbrainz container like this:

`sudo docker exec -ti musicbrainz bash`

The usual process to update the schema is:

* Ensure you’ve replicated up to the most recent replication packet available with the old schema. (if you’re not sure, run ./admin/replication/LoadReplicationChanges and see what it tells you).
* In the running container Switch to the new code with git fetch origin followed by git checkout $NEW_SCHEMA_BRANCH and also update the Dockerfile to the new branch.
* In the running container run ./upgrade.sh
* Set DB_SCHEMA_SEQUENCE to $NEW_SCHEMA_NUM in this repo scripts/DBDefs.pm
* On the host machine stop and remove the musicbrainz container and image
* On the host machine make sure the postgresql container is running
* On the host machine run `sudo ./build.sh`
* On the host machine run `sudo ./start.sh`

That’s it!
