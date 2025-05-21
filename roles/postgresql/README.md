# Роль postgresql

Роль для установки и настройки PostgreSQL для Gitea и Woodpecker CI.

## Описание

Эта роль обеспечивает:

-   Установку PostgreSQL из пакетов ALT Linux
-   Настройку системного пользователя
-   Создание баз данных и пользователей
-   Настройку прав доступа
-   Настройку резервного копирования
-   Интеграцию с Gitea и Woodpecker CI

## Использование

### Установка PostgreSQL

```bash
ansible-playbook -i inventory/hosts playbooks/install-postgresql.yml
```

## Конфигурация

Основной конфигурационный файл: `/etc/postgresql/postgresql.conf`

Важные параметры:

-   `listen_addresses` - адреса прослушивания
-   `port` - порт PostgreSQL
-   `max_connections` - максимальное количество подключений
-   `shared_buffers` - размер разделяемой памяти
-   `work_mem` - память для операций
-   `maintenance_work_mem` - память для обслуживания
-   `wal_level` - уровень логирования WAL
-   `max_wal_senders` - максимальное количество WAL отправителей
-   `hot_standby` - включение горячего резервного копирования

## Безопасность

-   PostgreSQL работает под системным пользователем `postgres`
-   Конфигурационные файлы доступны только пользователю `postgres`
-   Данные хранятся в `/var/lib/postgresql` с ограниченными правами доступа
-   Используется шифрование паролей в базе данных
-   Настроены ограничения на подключение
-   Включено SSL-соединение
-   Настроена аутентификация по паролю

## Мониторинг

-   Журналы: `/var/log/postgresql/`
-   Статус сервиса: `systemctl status postgresql`
-   Метрики: `pg_stat_activity`
-   Производительность: `pg_stat_statements`

## Устранение неполадок

1. Проверка статуса сервиса:

    ```bash
    systemctl status postgresql
    ```

2. Проверка логов:

    ```bash
    journalctl -u postgresql
    ```

3. Проверка подключений:

    ```bash
    psql -U postgres -c "SELECT * FROM pg_stat_activity;"
    ```

4. Проверка прав доступа:

    ```bash
    ls -l /etc/postgresql/
    ls -l /var/lib/postgresql/
    ```

5. Проверка баз данных:

    ```bash
    psql -U postgres -l
    ```

6. Проверка пользователей:

    ```bash
    psql -U postgres -c "\du"
    ```

7. Проверка резервных копий:
    ```bash
    ls -l /var/backups/postgresql/
    ```

## Проверка работоспособности

```bash
# Проверка статуса
systemctl status postgresql

# Проверка версии
su - postgres -c "psql -c 'SELECT version();'"

# Проверка подключения
su - postgres -c "psql -d giteadb -c 'SELECT 1'"
su - postgres -c "psql -d woodpecker -c 'SELECT 1'"

# Проверка репликации
su - postgres -c "psql -c 'SELECT * FROM pg_stat_replication;'"
```
