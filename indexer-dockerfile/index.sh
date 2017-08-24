#!/bin/bash

cd /home/search
java -jar /home/search/index.jar --db-host db --db-name musicbrainz --db-user musicbrainz --db-password musicbrainz --indexes-dir /home/search/indexdata
