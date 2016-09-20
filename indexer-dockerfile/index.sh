#!/bin/bash

cd /home/search
java -jar /home/search/index.jar --db-host db --db-name musicbrainz_db --db-user musicbrainz --db-password musicbrainz
