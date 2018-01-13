FROM airdock/oracle-jdk:jdk-8u74

LABEL Author="Robert Kaye <rob@metabrainz.org>"

WORKDIR /home/search
RUN curl -o /home/search/index.jar ftp://ftp.eu.metabrainz.org/pub/musicbrainz/search/index/index.jar

COPY index.sh /home/search

VOLUME ["/home/search/data"]
