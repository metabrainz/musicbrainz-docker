FROM airdock/oracle-jdk:jdk-8u74

MAINTAINER Robert Kaye <rob@metabrainz.org>

WORKDIR /home/search
COPY ./index.jar /home/search
COPY index.sh /home/search

VOLUME ["/home/search/data"]
RUN ln -s /home/search/data /home/search/indexdata
