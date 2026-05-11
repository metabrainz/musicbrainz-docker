ARG POSTGRES_VERSION=18
ARG POSTGRES_IMAGE_VARIANT=trixie
ARG POSTGRES_IMAGE_TAG=${POSTGRES_VERSION}-${POSTGRES_IMAGE_VARIANT}
FROM postgres:${POSTGRES_IMAGE_TAG}

ARG POSTGRES_VERSION
LABEL org.metabrainz.based-on-image="postgres:${POSTGRES_IMAGE_TAG}"

ARG DEBIAN_FRONTEND=noninteractive

# Update the Ubuntu and PostgreSQL repository packages.
RUN apt-get update && \
    apt-get upgrade -y -o Dpkg::Options::="--force-confold" && \
    apt-get install --no-install-recommends -qy \
        sudo && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
