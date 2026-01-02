# Procedure

1. See the error:
```
2025-01-31T20:11:52.447475-06:00 edtwardy internal_postgresql[2625]: 2025-02-01 02:11:52.447 UTC [161054] ERROR:  could not open file "base/24450/24546.1" (target block 262205): previous segment is only 95 blocks
2025-01-31T20:11:52.447607-06:00 edtwardy internal_postgresql[2625]: 2025-02-01 02:11:52.447 UTC [161054] CONTEXT:  automatic analyze of table "miniflux.public.entries"
```
1. Stop `miniflux`:
```
sudo apt purge twardyece-miniflux
```
1. Find out which ids are giving the issue:
```bash
#!/usr/bin/env sh

ids=$(psql -U postgres -d miniflux -c 'SELECT id FROM entries;' | sed -e '1,2d' | head -n -2)

IFS=$'\n'
for id in $ids; do
  (psql -U postgres -d miniflux -c "SELECT * FROM entries WHERE id=$id;") >/dev/null 2>&1
  if [ $? != "0" ]; then
    printf 'error: %d\n' "$id"
  fi
done
```
```
sudo podman exec -it internal_postgresql bash -c "$(cat postgres-dump.sh)"
error: 802
```
1. Create new database and copy the `miniflux.public.entries` database into it:
```
createdb -U postgres -O miniflux miniflux_backup
pg_dump -s -U postgres miniflux > miniflux.sql
psql -U postgres miniflux_backup < miniflux.sql
pg_dump -a -U postgres -T entries -T enclosures miniflux > miniflux.sql
psql -U postgres miniflux_backup < miniflux.sql
psql -U postgres -c 'COPY (SELECT * FROM entries WHERE id != 802) TO STDOUT;' miniflux | psql -U postgres -c 'COPY entries FROM STDIN;' miniflux_backup
COPY 1295
psql -U postgres -c 'COPY (SELECT * FROM enclosures) TO STDOUT;' miniflux | psql -U postgres -c 'COPY enclosures FROM STDIN;' miniflux_backup
COPY 196
```
1. Make a backup of the new database
```
pg_dump -U postgres miniflux_backup > miniflux-backup.sql
```
1. Point miniflux at it to test:
```diff
diff --git a/miniflux/miniflux.container b/miniflux/miniflux.container
index e5b934d..3691f08 100644
--- a/miniflux/miniflux.container
+++ b/miniflux/miniflux.container
@@ -3,8 +3,7 @@ ContainerName=public_miniflux
 Image=docker.io/miniflux/miniflux
 Network=public-services.network
 
-Secret=miniflux-postgresql-url,target=/run/secrets/postgresql-url
-Environment=DATABASE_URL_FILE=/run/secrets/postgresql-url
+Environment=DATABASE_URL=postgres://<user>:<password>@internal_postgresql/miniflux_backup?sslmode=disable
 
 [Service]
 Restart=always

```
1. Migrate the backup over the old database:
```
psql -U postgres -c 'DROP DATABASE miniflux_backup; DROP DATABASE miniflux;'
createdb -U postgres -O miniflux miniflux
psql -U postgres miniflux < miniflux-backup.sql
```
1. Check that the user is using the backup database
```
SELECT usename,datname FROM pg_stat_activity;
```
