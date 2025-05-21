#!/bin/bash
set -euo pipefail

BACKUP_DIR="/var/backups/woodpecker"
DATE=$(date +%Y-%m-%d_%H-%M-%S)

tar -czf $BACKUP_DIR/woodpecker-data-$DATE.tar.gz -C /var/lib woodpecker
cp -r /etc/woodpecker $BACKUP_DIR/woodpecker-config-$DATE
su -l woodpecker -s /bin/sh -c "pg_dump woodpecker" > $BACKUP_DIR/woodpecker-db-$DATE.sql

tar -czf $BACKUP_DIR/woodpecker_backup_$DATE.tar.gz -C $BACKUP_DIR \
    woodpecker-data-$DATE.tar.gz \
    woodpecker-config-$DATE \
    woodpecker-db-$DATE.sql

rm -rf $BACKUP_DIR/{woodpecker-*,*-db-*.sql}
