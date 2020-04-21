FROM metabrainz/base-image
LABEL maintainer="yvanzo@metabrainz.org"

ENV DOCKERIZE_VERSION v0.6.1
RUN curl -sSLO https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz && \
    tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz && \
    rm -f dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz

ARG NODE_VERSION=10.19.0
ARG POSTGRES_VERSION=9.5
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN curl -sSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    curl -sSL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    declare i=5 && while true; do \
        apt-key adv --keyserver hkps.pool.sks-keyservers.net --refresh-keys Yarn && \
        break || echo "apk-key failed with exit status '$?'"; \
        i=$((i - 1)); [[ $i -gt 0 ]] && echo "retrying..." || exit 1; \
    done && unset i && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update && \
    apt-get install --no-install-recommends -qy \
        python-minimal && \
    curl -sSLO https://deb.nodesource.com/node_10.x/pool/main/n/nodejs/nodejs_${NODE_VERSION}-1nodesource1_amd64.deb && \
    dpkg -i nodejs_${NODE_VERSION}-1nodesource1_amd64.deb && \
    apt-get install --no-install-recommends -qy \
        cpanminus \
        bash-completion \
        build-essential \
        bzip2 \
        gettext \
        g++ \
        git \
        language-pack-de \
        language-pack-el \
        language-pack-es \
        language-pack-et \
        language-pack-fi \
        language-pack-fr \
        language-pack-it \
        language-pack-ja \
        language-pack-nl \
        language-pack-sq \
        # Needed for Cache in DB_File
        libdb-dev \
        libexpat1-dev \
        libicu-dev \
        liblocal-lib-perl \
        libpq-dev \
        libssl-dev \
        # Needed for XML::LibXML
        libxml2-dev \
        make \
        memcached \
        # Needed for Unicode::ICU::Collator
        pkg-config \
        postgresql-${POSTGRES_VERSION} \
        # Needed to decompress sample data
        xz-utils \
        yarn \
        # Needed for XML:LibXML
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /musicbrainz-server

COPY DBDefs.pm /
COPY scripts/* /
RUN cat /snippet.perllocallib.bashrc >> ~/.bashrc \
    && rm /snippet.perllocallib.bashrc

# Postgres user/password would be solely needed to compile tests
ARG POSTGRES_USER=doesntmatteraslongasyoudontcompiletests
ARG POSTGRES_PASSWORD=doesntmatteraslongasyoudontcompiletests

ENV MUSICBRAINZ_CATALYST_DEBUG=0 \
    MUSICBRAINZ_DEVELOPMENT_SERVER=1 \
    MUSICBRAINZ_STANDALONE_SERVER=1 \
    MUSICBRAINZ_WEB_SERVER_HOST=localhost \
    MUSICBRAINZ_WEB_SERVER_PORT=5000 \
    POSTGRES_USER=musicbrainz \
    POSTGRES_PASSWORD=musicbrainz

CMD ["/start.sh"]
