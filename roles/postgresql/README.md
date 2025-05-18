# Роль postgresql

Роль для установки и настройки PostgreSQL для Gitea.

## Описание

Эта роль обеспечивает:

-   Установку PostgreSQL из пакетов ALT Linux
-   Настройку системного пользователя
-   Создание базы данных и пользователей
-   Настройку прав доступа

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

## Безопасность

-   PostgreSQL работает под системным пользователем `postgres`
-   Конфигурационные файлы доступны только пользователю `postgres`
-   Данные хранятся в `/var/lib/postgresql` с ограниченными правами доступа
-   Используется шифрование паролей в базе данных
-   Настроены ограничения на подключение

## Мониторинг

-   Журналы: `/var/log/postgresql/`
-   Статус сервиса: `systemctl status postgresql`

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

## Проверка работоспособности

```bash
# Проверка статуса
systemctl status postgresql

# Проверка версии
su - postgres -c "psql -c 'SELECT version();'"

# Проверка подключения
su - postgres -c "psql -d giteadb -c 'SELECT 1'"
```
