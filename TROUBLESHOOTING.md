# Troubleshooting

## Table of contents

<!-- toc -->

- [InitDb.pl failed on macOS](#initdbpl-failed-on-macos)
- [Resolving name failed](#resolving-name-failed)
- [Loadable library and perl binaries are mismatched](#loadable-library-and-perl-binaries-are-mismatched)
- [ImportError: No module named](#importerror-no-module-named)
- [Unknown error executing apt-key](#unknown-error-executing-apt-key)

<!-- tocstop -->

## InitDb.pl failed on macOS

When creating the database:

```log
Wed Feb 24 14:29:01 2021 : Creating indexes ... (CreateIndexes.sql)
Wed Feb 24 14:29:12 2021 : psql:/musicbrainz-server/admin/sql/CreateIndexes.sql:467: server closed the connection unexpectedly
Wed Feb 24 14:29:12 2021 : 	This probably means the server terminated abnormally
Wed Feb 24 14:29:12 2021 : 	before or while processing the request.
Wed Feb 24 14:29:12 2021 : psql:/musicbrainz-server/admin/sql/CreateIndexes.sql:467: fatal: connection to server was lost
Error during CreateIndexes.sql at /musicbrainz-server/admin/InitDb.pl line 117.
Wed Feb 24 14:29:12 2021 : InitDb.pl failed
```

Solution:

Add more than 2GB memory to containers on macOS.

## Resolving name failed

When building Docker images:

```log
Err:1 http://security.debian.org/debian-security buster/updates InRelease
  Temporary failure resolving 'security.debian.org'
```

Solution:

That can be your `bridge` nework has no default gateway yet.
That can be checked by running:

```bash
docker network inspect bridge
```

In such case, try restarting docker daemon:

```bash
sudo service docker restart
```

## Loadable library and perl binaries are mismatched

Using MusicBrainz server’s development setup only,
when `musicbrainz` service doesn’t work as expected,
and after retrieving its logs as follows:

```bash
sudo docker-compose logs --timestamps musicbrainz
```

returned logs contain the following error message:

```log
ListUtil.c: loadable library and perl binaries are mismatched (got handshake key 0xdb00080, needed 0xcd00080)
```

That means the Perl dependencies have been installed with another
version of Perl. It happens after the required version of Perl for
MusicBrainz Server has changed, mostly when switching from/to
different branches or versions of `musicbrainz-server`.

Solution:

Remove installed Perl dependencies and restart `musicbrainz` service;
It will automatically reinstall them all using current Perl version:

```bash
sudo rm -fr "$MUSICBRAINZ_SERVER_LOCAL_ROOT/perl_modules/
sudo docker-compose restart musicbrainz
```

## ImportError: No module named

Using Search Index Rebuilder’s development setup only,
when `indexer` service doesn’t work as expected,
and python commands return the following:

```log
Traceback (most recent call last):
[...]
ImportError: No module named [...]
```

(where the latest `[...]` may be `sqlalchemy` or any other dependency)

Solution:

Remove all installed Python packages and installation cache as follows:

```bash
sudo docker-compose exec indexer rm -fr /code/.cache /code/venv-musicbrainz-docker
sudo docker-compose restart indexer
```

Python packages are downloaded again and installed again when the
service `indexer` restarts.

## Unknown error executing apt-key

When building Docker image for the service `musicbrainz`:

``` log
Err:1 https://deb.nodesource.com/node_20.x nodistro InRelease
  Unknown error executing apt-key
[...]
W: GPG error: https://deb.nodesource.com/node_20.x nodistro InRelease: Unknown error executing apt-key
E: The repository 'https://deb.nodesource.com/node_20.x nodistro InRelease' is not signed.
```

This may happen if your system is hindering file permissions.
You can find out by adding `RUN ls -l file` commands in the
Dockerfile.

Solution:

Configure your system to keep the file permissions defined in the Git repository
and to preserve the permissions of the files copied through Docker.

If it isn’t possible, for example with the Unraid operating system,
run additional `chmod` commands in the Dockerfile; See comments to the
issue [#263](https://github.com/metabrainz/musicbrainz-docker/pull/263).

