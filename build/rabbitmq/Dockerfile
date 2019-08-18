FROM rabbitmq:3.6.5-management
LABEL Author="yvanzo@metabrainz.org"

COPY scripts/docker-entrypoint-wrapper.sh /
COPY scripts/set-config.sh /

ENTRYPOINT ["/docker-entrypoint-wrapper.sh"]
