# Troubleshooting

## Table of contents

<!-- toc -->

- [InitDb.pl failed on macOS](#initdbpl-failed-on-macos)
- [Resolving name failed](#resolving-name-failed)

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
