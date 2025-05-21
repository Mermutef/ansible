#!/bin/bash
set -euo pipefail

BACKUP_DIR="/var/backups/gitea"
DATE=$(date +%Y-%m-%d_%H-%M-%S)

su -l gitea -s /bin/sh -c "gitea dump -c /etc/gitea/app.ini --file $BACKUP_DIR/gitea-dump-$DATE.zip"
su -l gitea -s /bin/sh -c "pg_dump giteadb" > $BACKUP_DIR/gitea-db-$DATE.sql

tar -czf $BACKUP_DIR/gitea_backup_$DATE.tar.gz -C $BACKUP_DIR \
    gitea-dump-$DATE.zip \
    gitea-db-$DATE.sql \

rm -rf $BACKUP_DIR/{gitea-dump-*,*-db-*.sql}
