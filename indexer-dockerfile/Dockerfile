FROM airdock/oraclejdk:1.8

LABEL Author="Robert Kaye <rob@metabrainz.org>"

WORKDIR /home/search
COPY search-indexer-f297b72.jar /home/search/index.jar
COPY index.sh /home/search

VOLUME ["/home/search/indexdata"]
