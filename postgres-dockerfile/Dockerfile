FROM postgres:9.5
MAINTAINER jeffsturgis@gmail.com

# Update the Ubuntu and PostgreSQL repository indexes
RUN apt-get update

RUN DEBIAN_FRONTEND=noninteractive apt-get -y -q install git-core build-essential libxml2-dev libpq-dev libexpat1-dev libdb-dev libicu-dev postgresql-server-dev-9.5

RUN git clone https://github.com/metabrainz/postgresql-musicbrainz-unaccent.git && git clone https://github.com/metabrainz/postgresql-musicbrainz-collate.git

RUN cd postgresql-musicbrainz-unaccent && make && make install && cd ../postgresql-musicbrainz-collate && make && make install && cd ../

RUN echo "listen_addresses='*'" >> /var/lib/postgresql/data/postgresql.conf
