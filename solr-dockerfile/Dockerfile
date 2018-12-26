ARG SOLR_VERSION=7.7.2
FROM solr:${SOLR_VERSION}-alpine

ARG SOLR_VERSION

LABEL org.label-schema.schema-version="1.0.0-rc1" \
      org.label-schema.vendor="MetaBrainz Foundation" \
      org.metabrainz.based-on-image="solr:${SOLR_VERSION}-alpine"

###########################
# From metabrainz/mb-solr #
###########################

# Resetting value set in the parent image
USER root

RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    apk add --update-cache --no-cache \
            bash \
            git \
            maven \
            openjdk8 \
            openssh

###################
# Installing solr #
###################

ARG MB_SOLR_VERSION=3.1

LABEL org.metabrainz.mb-solr.version="${MB_SOLR_VERSION}"

RUN git clone --recurse-submodules --depth=1 --shallow-submodules \
       --branch v${MB_SOLR_VERSION} \
       https://github.com/metabrainz/mb-solr.git mb-solr-clone

# Caching the maven dependencies so that these are built only if
# the dependencies are changed and not the source code.
RUN mkdir mb-solr && \
    cp -p mb-solr-clone/mb-solr/pom.xml mb-solr/pom.xml
RUN mkdir brainz-mmd2-jaxb && \
    cp -p mb-solr-clone/mmd-schema/brainz-mmd2-jaxb/pom.xml brainz-mmd2-jaxb/pom.xml
RUN cd brainz-mmd2-jaxb && \
    mvn verify clean --fail-never && \
    cd ../mb-solr && \
    mvn verify clean --fail-never && \
    cd ..

RUN rm -fr brainz-mmd2-jaxb && \
    cp -r mb-solr-clone/mmd-schema/brainz-mmd2-jaxb brainz-mmd2-jaxb
RUN rm -fr mb-solr && \
    cp -r mb-solr-clone/mb-solr mb-solr
RUN cd brainz-mmd2-jaxb && \
    mvn install
RUN cd mb-solr && \
    mvn package -DskipTests
RUN mkdir -p /opt/solr/lib && \
    cp /opt/solr/mb-solr/target/mb-solr-0.0.1-SNAPSHOT-jar-with-dependencies.jar /opt/solr/lib

ENV SOLR_HOME /opt/solr/server/solr
RUN mkdir -p $SOLR_HOME/mycores && \
    cp -r mb-solr-clone/mbsssss $SOLR_HOME/mycores/mbsssss

# Pointing default Solr config to our shared lib directory
# and fix permissions
RUN sed -i'' 's|</solr>|<str name="sharedLib">/opt/solr/lib</str></solr>|' \
        /opt/solr/server/solr/solr.xml && \
    mkdir $SOLR_HOME/data && \
    chown -R solr:solr /opt/solr

USER $SOLR_USER

RUN rm -fr mb-solr-clone
