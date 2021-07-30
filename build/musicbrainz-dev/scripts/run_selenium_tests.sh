#!/usr/bin/env bash

echo "WIP: Follow instructions in commit message instead"
exit 1

cd /musicbrainz-server

# Wait for the database to start.
dockerize -wait tcp://db:5432 -timeout 60s 0

# Create the musicbrainz_test and musicbrainz_selenium DBs.
./script/create_test_db.sh
# TODO: skip prompt for password
psql postgres -U musicbrainz -h db -c "DROP DATABASE IF EXISTS musicbrainz_selenium; CREATE DATABASE musicbrainz_selenium WITH OWNER = musicbrainz TEMPLATE musicbrainz_test"

## Install the sir triggers into musicbrainz_selenium.
#export SIR_DIR=/home/musicbrainz/sir
#cd "$SIR_DIR"
#sudo -E -H -u musicbrainz sh -c '. venv/bin/activate; python -m sir amqp_setup; python -m sir extension; python -m sir triggers --broker-id=1'
#sudo -u postgres psql -U postgres -f sql/CreateExtension.sql musicbrainz_selenium
#sudo -u postgres psql -U musicbrainz -f sql/CreateFunctions.sql musicbrainz_selenium
#sudo -u postgres psql -U musicbrainz -f sql/CreateTriggers.sql musicbrainz_selenium
#rm /etc/service/sir-queue-purger/down && sv start sir-queue-purger

cd /musicbrainz-server

# Compile static resources.
make -C po all_quiet deploy
WEBPACK_MODE=development \
    ./script/compile_resources.sh server web-tests

mkdir -p junit_output

./t/selenium.js \
     | tee >(./node_modules/.bin/tap-junit > ./junit_output/selenium.xml) \
     | ./node_modules/.bin/tap-difflet

sleep 10
sudo -E -H -u musicbrainz ./node_modules/.bin/nyc report --reporter=html
