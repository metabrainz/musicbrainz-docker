ARG POSTGRES_VERSION=18
ARG POSTGRES_IMAGE_VARIANT=trixie
ARG POSTGRES_IMAGE_TAG=${POSTGRES_VERSION}-${POSTGRES_IMAGE_VARIANT}
FROM postgres:${POSTGRES_IMAGE_TAG}

ARG POSTGRES_VERSION
LABEL org.metabrainz.based-on-image="postgres:${POSTGRES_IMAGE_TAG}"

ARG DEBIAN_FRONTEND=noninteractive

# Update the Ubuntu and PostgreSQL repository indexes
RUN apt-get update && \
    apt-get install --allow-downgrades --no-install-recommends -qy \
        build-essential \
        ca-certificates \
        gcc \
        git \
        libicu-dev \
        make \
        pkg-config \
        sudo \
    && apt-get install --allow-downgrades --no-install-recommends -qy \
        --target-release "n=$(. /etc/os-release && echo "$VERSION_CODENAME")-pgdg" \
        libpq5 \
        libpq-dev \
        postgresql-server-dev-${POSTGRES_VERSION} \
    && rm -rf /var/lib/apt/lists/*

# Compile en_US.UTF-8 locale specification
RUN echo en_US.UTF-8 UTF-8 >> /etc/locale.gen \
    && locale-gen
