#!/bin/bash

psql -U musicbrainz -h db -c "DROP DATABASE musicbrainz;" postgres && /createdb.sh -fetch
