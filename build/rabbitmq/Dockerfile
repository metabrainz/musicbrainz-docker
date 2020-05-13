FROM rabbitmq:3.6.16-management
LABEL Author="yvanzo@metabrainz.org"

COPY [ "scripts/*", "/" ]

ENTRYPOINT ["/docker-entrypoint-wrapper.sh"]
