#!/bin/bash
set -euo pipefail

BACKUP_DIR="/opt/backups"
DATE=$(date +%Y-%m-%d_%H-%M-%S)

su -l gitea -s /bin/sh -c "gitea dump -c /etc/gitea/app.ini --file $BACKUP_DIR/gitea-dump-$DATE.zip"

tar -czf $BACKUP_DIR/woodpecker-data-$DATE.tar.gz -C /var/lib woodpecker
cp -r /etc/woodpecker $BACKUP_DIR/woodpecker-config-$DATE

su -l gitea -s /bin/sh -c "pg_dump giteadb" > $BACKUP_DIR/gitea-db-$DATE.sql
su -l woodpecker -s /bin/sh -c "pg_dump woodpecker" > $BACKUP_DIR/woodpecker-db-$DATE.sql

tar -czf $BACKUP_DIR/full_backup_$DATE.tar.gz -C $BACKUP_DIR \
    gitea-dump-$DATE.zip \
    woodpecker-data-$DATE.tar.gz \
    woodpecker-config-$DATE \
    gitea-db-$DATE.sql \
    woodpecker-db-$DATE.sql

rm -rf $BACKUP_DIR/{gitea-dump-*,woodpecker-*,*-db-*.sql}
