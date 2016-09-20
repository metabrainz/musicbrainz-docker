#!/bin/bash
sleep 2m
PORT=5000
HOST='localhost'
PROTOCOL='http'
HAS_SCRIPTS=$(curl "$PROTOCOL://$HOST:$PORT/" | grep '/static/build/common' 2> /dev/null)
HAS_DATA=$(curl "$PROTOCOL://$HOST:$PORT/artist/af8e4cc5-ef54-458d-a194-7b210acf638f" | grep 'Cannibal Corpse' 2> /dev/null)

if [ "$HAS_SCRIPTS" != '' ]; then
  echo 'Musicbrainz built correctly'
else
  echo 'Musicbrainz did not build correctly'
fi

if [ "$HAS_DATA" != '' ]; then
  echo 'Musicbrainz DB was created and data was imported correctly'
else
  echo 'Musicbrainz DB was not created or data was not imported correctly'
fi

if [ "$HAS_SCRIPTS" != '' -a "$HAS_DATA" != '' ]; then
  exit 0
fi

exit 1
