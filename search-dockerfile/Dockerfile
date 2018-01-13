FROM jetty:9.3.10

LABEL Author="Robert Kaye <rob@metabrainz.org>"

WORKDIR $JETTY_HOME
RUN curl -o $JETTY_HOME/webapps/ROOT.war http://ftp.eu.metabrainz.org/pub/musicbrainz/search/servlet/searchserver.war
