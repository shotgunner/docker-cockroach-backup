# docker-cockroach-backup

This image runs `cockroach dump` to backup data using cronjob to folder `/backup`

## Usage:

    docker run -d \
        --env PG_HOST=mysql.host \
        --env PG_PORT=27017 \
        --env PG_USER=admin \
        --env PG_PASSWORD=password \
        --volume host.folder:/backup
        jmcarbo/docker-postgres-backup


## Parameters

    COCKROACH_HOST      the host/ip of your postgres database
    COCKROACH_PORT      the port number of your postgres database
    COCKROACH_USER      the username of your postgres database
    COCKROACH_PASSWORD      the password of your postgres database
    COCKROACH_DB        the database name to dump. Default: `--all-databases`
    CRON_TIME       the interval of cron job to run pg_dump. `0 0 * * *` by default, which is every day at 00:00
    MAX_BACKUPS     the number of backups to keep. When reaching the limit, the old backup will be discarded. No limit by default
    INIT_BACKUP     if set, create a backup when the container starts

## Restore from a backup

See the list of backups, you can run:

    docker exec docker-cockroach-backup ls /backup

To restore database from a certain backup, simply run:

    docker exec docker-postgres-backup /restore.sh /backup/2015.08.06.171901
