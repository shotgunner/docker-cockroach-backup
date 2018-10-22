#!/bin/bash

COCKROACH_HOST=${COCKROACH_PORT_5432_TCP_ADDR:-${COCKROACH_HOST}}
COCKROACH_PORT=${COCKROACH_PORT_5432_TCP_PORT:-${COCKROACH_PORT}}
COCKROACH_USER=${COCKROACH_USER:-${COCKROACH_ENV_COCKROACH_USER}}

[ -z "${COCKROACH_HOST}" ] && { echo "=> COCKROACH_HOST cannot be empty" && exit 1; }
[ -z "${COCKROACH_PORT}" ] && { echo "=> COCKROACH_PORT cannot be empty" && exit 1; }
[ -z "${COCKROACH_USER}" ] && { echo "=> COCKROACH_USER cannot be empty" && exit 1; }
[ -z "${COCKROACH_DB}" ] && { echo "=> COCKROACH_DB cannot be empty" && exit 1; }


BACKUP_CMD="cockroach dump ${COCKROACH_DB} --host ${COCKROACH_HOST} --port=${COCKROACH_PORT} --user=${COCKROACH_USER} --insecure > /backup/\${BACKUP_NAME}"


echo "=> Creating backup script"
rm -f /backup.sh
cat <<EOF >> /backup.sh
#!/bin/bash
MAX_BACKUPS=${MAX_BACKUPS}

BACKUP_NAME=\$(date +\%Y.\%m.\%d.\%H\%M\%S).sql

echo "=> Backup started: \${BACKUP_NAME}"
if ${BACKUP_CMD} ;then
    echo "   Backup succeeded"
    ${BACKUP_RESTIC_CMD}
else
    echo "   Backup failed"
    rm -rf /backup/\${BACKUP_NAME}
fi

if [ -n "\${MAX_BACKUPS}" ]; then
    while [ \$(ls /backup -N1 | wc -l) -gt \${MAX_BACKUPS} ];
    do
        BACKUP_TO_BE_DELETED=\$(ls /backup -N1 | sort | head -n 1)
        echo "   Backup \${BACKUP_TO_BE_DELETED} is deleted"
        rm -rf /backup/\${BACKUP_TO_BE_DELETED}
    done
fi
echo "=> Backup done"
EOF
chmod +x /backup.sh

echo "=> Creating restore script"
rm -f /restore.sh
cat <<EOF >> /restore.sh
#!/bin/bash

echo "=> Restore database from \$1"
if cockroach sql --insecure --database=${COCKROACH_DB} --user=${COCKROACH_USER} < \$1 ;then
    echo "   Restore succeeded"
else
    echo "   Restore failed"
fi
echo "=> Done"
EOF
chmod +x /restore.sh

touch /cockroach_backup.log
tail -F /cockroach_backup.log &

if [ -n "${INIT_BACKUP}" ]; then
    echo "=> Create a backup on the startup"
    /backup.sh
fi

echo "${CRON_TIME} /backup.sh >> /cockroach_backup.log 2>&1" > /crontab.conf
crontab  /crontab.conf
echo "=> Running cron job"
exec cron -f
