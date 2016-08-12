#!/bin/bash

cd /home/search
java -jar /home/search/index.jar --indexes area --db-host db --db-name musicbrainz_db --db-user musicbrainz --db-password musicbrainz
