# Troubleshooting

## Table of contents

<!-- toc -->

- [InitDb.pl failed on macOS](#initdbpl-failed-on-macos)
- [Resolving name failed](#resolving-name-failed)
- [Loadable library and perl binaries are mismatched](#loadable-library-and-perl-binaries-are-mismatched)
- [ImportError: No module named](#importerror-no-module-named)
- [Unknown error executing apt-key](#unknown-error-executing-apt-key)
- [amqp.exceptions.AccessRefused](#amqpexceptionsaccessrefused)
- [Connection errors during reindex](#connection-errors-during-reindex)

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
docker compose logs --timestamps musicbrainz
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
docker compose restart musicbrainz
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
docker compose exec indexer rm -fr /code/.cache /code/venv-musicbrainz-docker
docker compose restart indexer
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

## amqp.exceptions.AccessRefused

When running `sir amqp_setup` to prepare live indexing:

```log
amqp.exceptions.AccessRefused: (0, 0): (403) ACCESS_REFUSED - Login was refused using authentication mechanism AMQPLAIN. For details see the broker logfile.
```

The service `mq` is sometimes not creating the user `sir` as expected.


Solution:

Recreate the container `mq` as follows:

```bash
docker compose up --force-recreate -d mq
```

Check if it started with creating the user `sir`:

```bash
docker compose logs -t mq | grep 'Creating user .sir.'
```

If it doesn’t mention _creating user sir_, try recreating `mq` again.

## Connection errors during reindex

When running **reindex** on the **indexer** service, if the command output emits errors like:

* `pysolr.SolrError: Failed to connect to server`
* `ConnectionRefusedError: [Errno 111] Connection refused.`
* `ConnectionResetError: [Errno 104] Connection reset by peer`
* `pysolr.SolrError: Failed to connect to server at http://search:8983/solr/recording/update/`
* `('Connection aborted.', RemoteDisconnected('Remote end closed connection without response'))`
* `pysolr.SolrError: Solr responded with an error (HTTP 404): [Reason: None]`
* `(psycopg2.OperationalError) server closed the connection unexpectedly`
* `pysolr.SolrError: Failed to connect to server at http://search:8983/solr/recording/update/`
* `Failed to resolve 'search' ([Errno -2] Name or service not known)")`

These might all be symptoms of the **search** service having insufficient memory, causing the Solr process to end abruptly then restart.

For further evidence, look at the docker logs of the **search** service.  When the Solr process stops abruptly, you might see diagnostics like:
```text
... [elided] ...
2025-11-25 04:00:25.510 INFO  (searcherExecutor-83-thread-2-processing-172.18.0.6:8983_solr recording_shard4_replica_n1 recording shard4 core_node3) [c:recording s:shard4 r:core_node3 x:recording_shard4_replica_n1 t:] o.a.s.c.SolrCore Registered new searcher autowarm time: 0 ms
2025-11-25 04:00:26.528 INFO  (searcherExecutor-72-thread-2-processing-172.18.0.6:8983_solr recording_shard3_replica_n6 recording shard3 core_node8) [c:recording s:shard3 r:core_node8 x:recording_shard3_replica_n6 t:] o.a.s.c.SolrCore Registered new searcher autowarm time: 64 ms
Killed
Executing /opt/solr/docker/scripts/start-musicbrainz-solrcloud
/opt/solr/docker/scripts/start-musicbrainz-solrcloud: running /docker-entrypoint-initdb.d/10-install-musicbrainz-conf.sh
Starting Solr
Java 17 detected. Enabled workaround for SOLR-16463
[0.012s][warning][pagesize] UseLargePages disabled, no large pages configured and available on the system.
CompileCommand: exclude com/github/benmanes/caffeine/cache/BoundedLocalCache.put bool exclude = true
WARNING: A command line option has enabled the Security Manager
WARNING: The Security Manager is deprecated and will be removed in a future release
2025-11-25 04:00:34.759 INFO  (main) [c: s: r: x: t:] o.e.j.s.Server jetty-10.0.22; built: 2024-06-27T16:03:51.502Z; git: 5c8471e852d377fd726ad9b1692c35ffc5febb09; jvm 17.0.15+6
2025-11-25 04:00:35.441 WARN  (main) [c: s: r: x: t:] o.e.j.u.DeprecationWarning Using @Deprecated Class org.eclipse.jetty.servlet.listener.ELContextCleaner
2025-11-25 04:00:35.501 INFO  (main) [c: s: r: x: t:] o.a.s.s.CoreContainerProvider Using logger factory org.apache.logging.slf4j.Log4jLoggerFactory
2025-11-25 04:00:35.525 INFO  (main) [c: s: r: x: t:] o.a.s.s.CoreContainerProvider  ___      _       Welcome to Apache Solr™ version 9.7.0
2025-11-25 04:00:35.526 INFO  (main) [c: s: r: x: t:] o.a.s.s.CoreContainerProvider / __| ___| |_ _   Starting in cloud mode on port 8983
2025-11-25 04:00:35.526 INFO  (main) [c: s: r: x: t:] o.a.s.s.CoreContainerProvider \__ \/ _ \ | '_|  Install dir: /opt/solr-9.7.0
2025-11-25 04:00:35.527 INFO  (main) [c: s: r: x: t:] o.a.s.s.CoreContainerProvider |___/\___/_|_|    Start time: 2025-11-25T04:00:35.527071965Z
2025-11-25 04:00:35.536 INFO  (main) [c: s: r: x: t:] o.a.s.s.CoreContainerProvider Solr started with "-XX:+CrashOnOutOfMemoryError" that will crash on any OutOfMemoryError exception. The cause of the OOME will be logged in the crash file at the following path: /var/solr/logs/jvm_crash_8.log
... [elided] ...
```

The first action to take is to provide more memory to the Solr software in the **search** service, as described in 
["Modify memory settings" in the README](https://github.com/metabrainz/musicbrainz-docker?tab=readme-ov-file#modify-memory-settings).

A second action to take is to provide more memory to the Docker compose, allowing it to devote more memory to the **search** service. 

If you are using the Docker.desktop app to run the Musicbrainz-docker compose, then increase the overall Memory Limit as follows:
- In the main Docker.desktop window, push the Settings button (the gear icon in upper-right). A Settings dialogue appears.
- In the left pane, click on the Resources entry. The right pane shows the Resources controls.
- Move the slider labelled, "Memory Limit" to allow more memory.
  - As of November 2025 on macOS 14, 16 GB is necessary to run reindex entity by entity, and 22+ GB is required to completely reindex at once. 
- Press the **Apply & restart** button in the lower-right corner of the Settings dialogue. The Docker compose restarts.
- Close the Settings dialogue.

A third action to take is to run the **reindex** operation in multiple parts. Use the `--entity-type` option multiple times to select some 
but not all of the Cores.
