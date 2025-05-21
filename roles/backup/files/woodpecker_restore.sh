#!/bin/bash
set -euo pipefail

BACKUP_DIR="/var/backups/woodpecker"
RESTORE_TEMP="/tmp/restore_$(date +%s)"

if [ $# -eq 1 ]; then
    BACKUP_FILE="$1"
    if [ ! -f "$BACKUP_FILE" ]; then
        echo "Error: Backup file $BACKUP_FILE does not exist"
        exit 1
    fi
else
    LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/woodpecker_backup_*.tar.gz | head -n1)
    if [ -z "$LATEST_BACKUP" ]; then
        echo "Error: No backup files found in $BACKUP_DIR"
        exit 1
    fi
    BACKUP_FILE="$LATEST_BACKUP"
fi

echo "Using backup file: $BACKUP_FILE"
mkdir -p "$RESTORE_TEMP"
tar -xzf "$BACKUP_FILE" -C "$RESTORE_TEMP"

echo "Restoring data..."
if ls "$RESTORE_TEMP"/woodpecker-data-*.tar.gz 1> /dev/null 2>&1; then
    echo "Found data archive, extracting..."
    tar -xzf "$RESTORE_TEMP"/woodpecker-data-*.tar.gz -C /var/lib
fi

echo "Restoring configuration..."
if [ -d "$RESTORE_TEMP"/woodpecker-config-* ]; then
    echo "Found configuration directory, copying..."
    cp -r "$RESTORE_TEMP"/woodpecker-config-* /etc/woodpecker
fi

# Ищем файл базы данных
DB_BACKUP=""
if ls "$RESTORE_TEMP"/woodpecker-db-*.sql 1> /dev/null 2>&1; then
    DB_BACKUP=$(ls -t "$RESTORE_TEMP"/woodpecker-db-*.sql | head -n1)
fi

if [ -n "$DB_BACKUP" ]; then
    echo "Found database backup at: $DB_BACKUP"
    echo "Restoring database..."
    chown postgres:postgres "$DB_BACKUP"
    chmod 600 "$DB_BACKUP"

    echo "Stopping services..."
    systemctl stop woodpecker-server
    systemctl stop woodpecker-agent

    if ! su -l postgres -s /bin/bash -c "psql -lqt | cut -d \| -f 1 | grep -qw woodpecker"; then
        echo "Creating database..."
        su -l postgres -s /bin/bash -c "createdb -O woodpecker woodpecker"
    fi

    echo "Resetting database schema..."
    su -l postgres -s /bin/bash -c "psql -d woodpecker -c 'DROP SCHEMA public CASCADE; CREATE SCHEMA public;'"
    su -l postgres -s /bin/bash -c "psql -d woodpecker -c 'ALTER SCHEMA public OWNER TO woodpecker;'"
    su -l postgres -s /bin/bash -c "psql -d woodpecker -c 'GRANT ALL ON SCHEMA public TO woodpecker;'"

    echo "Importing database dump..."
    su -l postgres -s /bin/bash -c "psql -d woodpecker < $DB_BACKUP"

    echo "Setting database permissions..."
    su -l postgres -s /bin/bash -c "psql -d woodpecker -c 'ALTER DATABASE woodpecker OWNER TO woodpecker;'"
    su -l postgres -s /bin/bash -c "psql -d woodpecker -c 'GRANT ALL ON ALL TABLES IN SCHEMA public TO woodpecker;'"
    su -l postgres -s /bin/bash -c "psql -d woodpecker -c 'GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO woodpecker;'"
    su -l postgres -s /bin/bash -c "psql -d woodpecker -c 'GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO woodpecker;'"

    echo "Restarting services..."
    systemctl restart postgresql
    systemctl start woodpecker-server
    systemctl start woodpecker-agent
else
    echo "Error: Database backup file not found"
    exit 1
fi

echo "Cleaning up..."
rm -rf "$RESTORE_TEMP"

echo "Finalizing permissions..."
chown -R woodpecker:woodpecker /etc/woodpecker
chmod 640 /etc/woodpecker/*.conf

echo "Restore completed successfully"
