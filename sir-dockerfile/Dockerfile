FROM metabrainz/sir

LABEL org.label-schema.schema-version="1.0.0-rc1" \
      org.label-schema.vendor="MetaBrainz Foundation"

COPY config.ini /code/

WORKDIR /code

RUN touch /etc/consul-template.conf

ENV POSTGRES_USER musicbrainz
ENV POSTGRES_PASSWORD musicbrainz
