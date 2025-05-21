#!/bin/bash
set -euo pipefail

BACKUP_DIR="/var/backups/gitea"
RESTORE_TEMP="/tmp/restore_$(date +%s)"

if [ $# -eq 1 ]; then
    BACKUP_FILE="$1"
    if [ ! -f "$BACKUP_FILE" ]; then
        echo "Error: Backup file $BACKUP_FILE does not exist"
        exit 1
    fi
else
    LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/gitea_backup_*.tar.gz | head -n1)
    if [ -z "$LATEST_BACKUP" ]; then
        echo "Error: No backup files found in $BACKUP_DIR"
        exit 1
    fi
    BACKUP_FILE="$LATEST_BACKUP"
fi

echo "Using backup file: $BACKUP_FILE"
mkdir -p "$RESTORE_TEMP"
tar -xzf "$BACKUP_FILE" -C "$RESTORE_TEMP"

if [ ! -d "$RESTORE_TEMP/gitea-dump" ]; then
    mkdir -p "$RESTORE_TEMP/gitea-dump"
fi
unzip -o "$RESTORE_TEMP"/gitea-dump-*.zip -d "$RESTORE_TEMP/gitea-dump"
cd "$RESTORE_TEMP/gitea-dump"

echo "Restoring configuration..."
mv -f app.ini /etc/gitea/app.ini

if [ -d "data" ]; then
    echo "Restoring data directory..."
    rm -rf /var/lib/gitea/data/*
    mkdir -p /var/lib/gitea/data
    mv -f data/* /var/lib/gitea/data/
fi

if [ -d "log" ]; then
    echo "Restoring log directory..."
    rm -rf /var/lib/gitea/log/*
    mkdir -p /var/lib/gitea/log
    mv -f log/* /var/lib/gitea/log/
fi

if [ -d "repos" ]; then
    echo "Restoring repositories..."
    rm -rf /var/lib/gitea/data/gitea-repositories/*
    mkdir -p /var/lib/gitea/data/gitea-repositories
    mv -f repos/* /var/lib/gitea/data/gitea-repositories/
fi

echo "Setting permissions..."
chown -R gitea:gitea /etc/gitea/app.ini /var/lib/gitea
chmod 640 /etc/gitea/app.ini
chmod -R 750 /var/lib/gitea

# Ищем файл базы данных в обоих возможных местах
DB_BACKUP=""
if [ -f "$RESTORE_TEMP/gitea-dump/gitea-db.sql" ]; then
    DB_BACKUP="$RESTORE_TEMP/gitea-dump/gitea-db.sql"
elif ls "$RESTORE_TEMP"/gitea-db-*.sql 1> /dev/null 2>&1; then
    DB_BACKUP=$(ls -t "$RESTORE_TEMP"/gitea-db-*.sql | head -n1)
fi

if [ -n "$DB_BACKUP" ]; then
    echo "Found database backup at: $DB_BACKUP"
    echo "Restoring database..."
    chown postgres:postgres "$DB_BACKUP"
    chmod 600 "$DB_BACKUP"

    systemctl stop gitea

    if ! su -l postgres -s /bin/bash -c "psql -lqt | cut -d \| -f 1 | grep -qw giteadb"; then
        echo "Creating database..."
        su -l postgres -s /bin/bash -c "createdb -O gitea giteadb"
    fi

    echo "Resetting database schema..."
    su -l postgres -s /bin/bash -c "psql -d giteadb -c 'DROP SCHEMA public CASCADE; CREATE SCHEMA public;'"
    su -l postgres -s /bin/bash -c "psql -d giteadb -c 'ALTER SCHEMA public OWNER TO gitea;'"
    su -l postgres -s /bin/bash -c "psql -d giteadb -c 'GRANT ALL ON SCHEMA public TO gitea;'"

    echo "Importing database dump..."
    su -l postgres -s /bin/bash -c "psql -d giteadb < $DB_BACKUP"

    echo "Setting database permissions..."
    su -l postgres -s /bin/bash -c "psql -d giteadb -c 'ALTER DATABASE giteadb OWNER TO gitea;'"
    su -l postgres -s /bin/bash -c "psql -d giteadb -c 'GRANT ALL ON ALL TABLES IN SCHEMA public TO gitea;'"
    su -l postgres -s /bin/bash -c "psql -d giteadb -c 'GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO gitea;'"
    su -l postgres -s /bin/bash -c "psql -d giteadb -c 'GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO gitea;'"

    echo "Verifying database restore..."
    if ! su -l postgres -s /bin/bash -c "psql -d giteadb -c '\dt'" | grep -q "user"; then
        echo "Error: Database restore verification failed"
        exit 1
    fi

    echo "Restarting services..."
    systemctl restart postgresql
    systemctl start gitea
else
    echo "Error: Database backup file not found"
    exit 1
fi

echo "Cleaning up..."
rm -rf "$RESTORE_TEMP"

echo "Finalizing permissions..."
chown -R gitea:gitea /etc/gitea
chmod 640 /etc/gitea/app.ini

echo "Restore completed successfully"
