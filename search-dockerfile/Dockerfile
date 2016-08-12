FROM jetty:9.3.10

MAINTAINER Robert Kaye <rob@metabrainz.org>

WORKDIR $JETTY_HOME
COPY ./searchserver.war $JETTY_HOME/webapps/ROOT.war

VOLUME ["/home/search/data"]
