# Роль gitea

Роль для установки и настройки Gitea - системы управления Git-репозиториями.

## Описание

Эта роль обеспечивает:

-   Установку Gitea из пакетов ALT Linux
-   Настройку системного пользователя
-   Настройку конфигурации
-   Настройку системного сервиса
-   Интеграцию с PostgreSQL

## Файлы

-   `templates/app.ini` - шаблон конфигурационного файла Gitea

## Использование

### Установка Gitea

```bash
ansible-playbook -i inventory/hosts playbooks/install-gitea.yml
```

### Установка и настройка Gitea с PostgreSQL

```bash
ansible-playbook -i inventory/hosts playbooks/install-and-configure-gitea.yml
```

## Конфигурация

Основной конфигурационный файл: `/etc/gitea/app.ini`

Важные параметры:

-   `DOMAIN` - домен Gitea
-   `ROOT_URL` - корневой URL
-   `HTTP_ADDR` - адрес прослушивания
-   `HTTP_PORT` - порт HTTP
-   `SECRET_KEY` - секретный ключ
-   `INSTALL_LOCK` - блокировка установки

## Безопасность

-   Gitea работает под системным пользователем `gitea`
-   Конфигурационный файл доступен только пользователю `gitea`
-   Данные хранятся в `/var/lib/gitea` с ограниченными правами доступа
-   Используется шифрование паролей в базе данных

## Мониторинг

-   Журналы: `/var/log/gitea/`
-   Статус сервиса: `systemctl status gitea`

## Устранение неполадок

1. Проверка статуса сервиса:

    ```bash
    systemctl status gitea
    ```

2. Проверка логов:

    ```bash
    journalctl -u gitea
    ```

3. Проверка конфигурации:

    ```bash
    gitea doctor
    ```

4. Проверка прав доступа:

    ```bash
    ls -l /etc/gitea/app.ini
    ls -l /var/lib/gitea/
    ```

5. Проверка подключения к базе данных:
    ```bash
    su -l postgres -s /bin/bash -c "psql -d giteadb -c 'SELECT 1'"
    ```
