musicbrainz docker container
==================

This repo contains everything needed to run a musicbrainz slave server with replication in a docker container.

### Installation

###### Data Container
* cd to data-dockerfile
* modify the run.sh file to point to the directory on the host machine where you want to store the database
* `sudo ./build.sh`
* `sudo ./run.sh`
 
###### Postgresql Container
* cd to postgres-dockerfile
* `sudo ./build.sh`
* `sudo ./run.sh`
 
###### Musicbrainz Server Container
* cd to musicbrainz-dockerfile
* modify the run.sh file to point to a data directory on the host machine where you want to store DB dumps (over 5 gigs)
* `sudo ./build.sh`
* `sudo ./run.sh`
 
###### Autostart
* `sudo ./autostart.sh` 

### Create Database
If this is a new instance and you need to create the database:

* `sudo docker exec -ti musicbrainz bash`
* `cd /`
* `./createdb.sh`

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
