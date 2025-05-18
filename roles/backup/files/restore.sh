
set -euo pipefail

BACKUP_DIR="/opt/backups"
RESTORE_TEMP="/tmp/restore_$(date +%s)"
LOG_FILE="/var/log/gitea/restore.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "Starting restore process"

LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/full_backup_*.tar.gz | head -n1)
if [ -z "$LATEST_BACKUP" ]; then
    log "No backup files found"
    exit 1
fi
BACKUP_FILE="$LATEST_BACKUP"
log "Using backup file: $BACKUP_FILE"

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

log "Setting permissions"
chown -R gitea:gitea /etc/gitea/app.ini /var/lib/gitea
chmod 640 /etc/gitea/app.ini
chmod -R 750 /var/lib/gitea

if ls "$RESTORE_TEMP"/woodpecker-data-*.tar.gz 1> /dev/null 2>&1; then
    tar -xzf "$RESTORE_TEMP"/woodpecker-data-*.tar.gz -C /var/lib
fi
if [ -d "$RESTORE_TEMP"/woodpecker-config-* ]; then
    cp -r "$RESTORE_TEMP"/woodpecker-config-* /etc/woodpecker
fi

DB_BACKUP="$RESTORE_TEMP/gitea-dump/gitea-db.sql"
if [ -f "$DB_BACKUP" ]; then
    log "Found database backup: $DB_BACKUP"
    chown postgres:postgres "$DB_BACKUP"
    chmod 600 "$DB_BACKUP"

    log "Stopping services"
    systemctl stop gitea
    systemctl stop woodpecker-server
    systemctl stop woodpecker-agent

    log "Restoring Gitea database"
    
    if ! su -l postgres -s /bin/bash -c "psql -lqt | cut -d \| -f 1 | grep -qw giteadb"; then
        log "Creating giteadb database"
        su -l postgres -s /bin/bash -c "createdb -O gitea giteadb"
    fi

    log "Preparing database for restore"
    su -l postgres -s /bin/bash -c "psql -d giteadb -c 'DROP SCHEMA public CASCADE; CREATE SCHEMA public;'"
    su -l postgres -s /bin/bash -c "psql -d giteadb -c 'ALTER SCHEMA public OWNER TO gitea;'"
    su -l postgres -s /bin/bash -c "psql -d giteadb -c 'GRANT ALL ON SCHEMA public TO gitea;'"

    log "Restoring data"
    su -l postgres -s /bin/bash -c "psql -d giteadb < $DB_BACKUP"

    log "Setting database permissions"
    su -l postgres -s /bin/bash -c "psql -d giteadb -c 'ALTER DATABASE giteadb OWNER TO gitea;'"
    su -l postgres -s /bin/bash -c "psql -d giteadb -c 'GRANT ALL ON ALL TABLES IN SCHEMA public TO gitea;'"
    su -l postgres -s /bin/bash -c "psql -d giteadb -c 'GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO gitea;'"
    su -l postgres -s /bin/bash -c "psql -d giteadb -c 'GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO gitea;'"

    log "Verifying database restore"
    if ! su -l postgres -s /bin/bash -c "psql -d giteadb -c '\dt'" | grep -q "user"; then
        log "Error: Gitea database restore failed - user table not found"
        exit 1
    fi

    USER_COUNT=$(su -l postgres -s /bin/bash -c "psql -d giteadb -t -c 'SELECT COUNT(*) FROM \"user\"'")
    log "Found $USER_COUNT users in database"

    log "Checking user table structure"
    su -l postgres -s /bin/bash -c "psql -d giteadb -c '\d \"user\"'" | tee -a "$LOG_FILE"

    log "Checking for admin user"
    su -l postgres -s /bin/bash -c "psql -d giteadb -c 'SELECT id, name, email, is_admin FROM \"user\" WHERE is_admin = true'" | tee -a "$LOG_FILE"

    if ls "$RESTORE_TEMP"/woodpecker-db-*.sql 1> /dev/null 2>&1; then
        WOODPECKER_DB_BACKUP=$(ls "$RESTORE_TEMP"/woodpecker-db-*.sql)
        log "Found Woodpecker database backup: $WOODPECKER_DB_BACKUP"
        chown postgres:postgres $WOODPECKER_DB_BACKUP
        chmod 600 $WOODPECKER_DB_BACKUP

        if ! su -l postgres -s /bin/bash -c "psql -lqt | cut -d \| -f 1 | grep -qw woodpecker"; then
            log "Creating woodpecker database"
            su -l postgres -s /bin/bash -c "createdb -O woodpecker woodpecker"
        fi

        log "Preparing Woodpecker database for restore"
        su -l postgres -s /bin/bash -c "psql -d woodpecker -c 'DROP SCHEMA public CASCADE; CREATE SCHEMA public;'"
        su -l postgres -s /bin/bash -c "psql -d woodpecker -c 'ALTER SCHEMA public OWNER TO woodpecker;'"
        su -l postgres -s /bin/bash -c "psql -d woodpecker -c 'GRANT ALL ON SCHEMA public TO woodpecker;'"

        log "Restoring Woodpecker data"
        su -l postgres -s /bin/bash -c "psql -d woodpecker < $WOODPECKER_DB_BACKUP"

        log "Setting Woodpecker database permissions"
        su -l postgres -s /bin/bash -c "psql -d woodpecker -c 'ALTER DATABASE woodpecker OWNER TO woodpecker;'"
        su -l postgres -s /bin/bash -c "psql -d woodpecker -c 'GRANT ALL ON ALL TABLES IN SCHEMA public TO woodpecker;'"
        su -l postgres -s /bin/bash -c "psql -d woodpecker -c 'GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO woodpecker;'"
        su -l postgres -s /bin/bash -c "psql -d woodpecker -c 'GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO woodpecker;'"
    fi

    log "Restarting PostgreSQL"
    systemctl restart postgresql

    log "Checking database accessibility"
    sleep 5
    if ! su -l postgres -s /bin/bash -c "psql -d giteadb -c 'SELECT 1'" > /dev/null 2>&1; then
        log "Error: Gitea database is not accessible after restore"
        exit 1
    fi

    log "Checking database permissions"
    su -l postgres -s /bin/bash -c "psql -d giteadb -c 'SELECT current_user, current_database()'" | tee -a "$LOG_FILE"

    log "Starting services"
    systemctl start gitea
    systemctl start woodpecker-server
    systemctl start woodpecker-agent

    log "Checking service status"
    systemctl status gitea | tee -a "$LOG_FILE"
else
    log "Error: Database backup file not found at $DB_BACKUP"
    exit 1
fi

log "Cleaning up temporary files"
rm -rf "$RESTORE_TEMP"

log "Setting final permissions"
chown -R gitea:gitea /etc/gitea
chown -R woodpecker:woodpecker /etc/woodpecker
chmod 640 /etc/gitea/app.ini
chmod 640 /etc/woodpecker/*.conf

log "Checking Gitea configuration"
grep -E "^ROOT_URL|^DOMAIN|^HTTP_ADDR|^SECRET_KEY|^INSTALL_LOCK" /etc/gitea/app.ini | tee -a "$LOG_FILE"

log "Restore completed successfully"
