FROM metabrainz/python:3.13-20250616

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
                       build-essential \
                       git \
                       libpq-dev \
                       libffi-dev \
                       libssl-dev \
    && rm -rf /var/lib/apt/lists/*

ARG ARTWORK_REDIRECT_VERSION=v-2025-07-07.0

RUN git clone --depth=1 --branch "${ARTWORK_REDIRECT_VERSION}"  https://github.com/metabrainz/artwork-redirect.git /code \
    && cd /code \
    && pip install -r requirements.txt

COPY config.ini /code

WORKDIR /code

CMD ["python", "artwork_redirect_server.py"]
