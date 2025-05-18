#!/bin/bash
set -euo pipefail

BACKUP_DIR="/opt/backups"
RESTORE_TEMP="/tmp/restore_$(date +%s)"

LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/full_backup_*.tar.gz | head -n1)
if [ -z "$LATEST_BACKUP" ]; then
    exit 1
fi
BACKUP_FILE="$LATEST_BACKUP"

mkdir -p "$RESTORE_TEMP"
tar -xzf "$BACKUP_FILE" -C "$RESTORE_TEMP"

if [ ! -d "$RESTORE_TEMP/gitea-dump" ]; then
    mkdir -p "$RESTORE_TEMP/gitea-dump"
fi
unzip -o "$RESTORE_TEMP"/gitea-dump-*.zip -d "$RESTORE_TEMP/gitea-dump"
cd "$RESTORE_TEMP/gitea-dump"
mv -f app.ini /etc/gitea/app.ini

if [ -d "data" ]; then
    rm -rf /var/lib/gitea/data/*
    mkdir -p /var/lib/gitea/data
    mv -f data/* /var/lib/gitea/data/
fi

if [ -d "log" ]; then
    rm -rf /var/lib/gitea/log/*
    mkdir -p /var/lib/gitea/log
    mv -f log/* /var/lib/gitea/log/
fi

if [ -d "repos" ]; then
    rm -rf /var/lib/gitea/data/gitea-repositories/*
    mkdir -p /var/lib/gitea/data/gitea-repositories
    mv -f repos/* /var/lib/gitea/data/gitea-repositories/
fi

chown -R gitea:gitea /etc/gitea/app.ini /var/lib/gitea

if ls "$RESTORE_TEMP"/woodpecker-data-*.tar.gz 1> /dev/null 2>&1; then
    tar -xzf "$RESTORE_TEMP"/woodpecker-data-*.tar.gz -C /var/lib
fi
if [ -d "$RESTORE_TEMP"/woodpecker-config-* ]; then
    cp -r "$RESTORE_TEMP"/woodpecker-config-* /etc/woodpecker
fi

if ls "$RESTORE_TEMP"/gitea-dump/gitea-db-*.sql 1> /dev/null 2>&1; then
    DB_BACKUP=$(ls "$RESTORE_TEMP"/gitea-db-*.sql)
    chown gitea:gitea $DB_BACKUP
    su -l gitea -s /bin/bash -c "dropdb --if-exists giteadb"
    su -l gitea -s /bin/bash -c "createdb giteadb"
    su -l gitea -s /bin/bash -c "psql -U gitea -d giteadb < $DB_BACKUP"
    if ls "$RESTORE_TEMP"/woodpecker-db-*.sql 1> /dev/null 2>&1; then
        WOODPECKER_DB_BACKUP=$(ls "$RESTORE_TEMP"/woodpecker-db-*.sql)
        chown woodpecker:woodpecker $WOODPECKER_DB_BACKUP
        su -l woodpecker -s /bin/bash -c "dropdb --if-exists woodpecker"
        su -l woodpecker -s /bin/bash -c "createdb woodpecker"
        su -l woodpecker -s /bin/bash -c "psql -U woodpecker -d woodpecker < $WOODPECKER_DB_BACKUP"
    fi
fi

rm -rf "$RESTORE_TEMP"
