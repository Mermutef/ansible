# Роль woodpecker

Роль для установки и настройки Woodpecker CI - системы непрерывной интеграции.

## Описание

Эта роль обеспечивает:

-   Установку Woodpecker CI из пакетов ALT Linux
-   Настройку системного пользователя
-   Настройку конфигурации
-   Настройку системного сервиса
-   Интеграцию с Gitea
-   Настройку агентов

## Использование

### Установка Woodpecker CI

```bash
ansible-playbook -i inventory/hosts playbooks/install-woodpecker.yml
```

### Установка и настройка Woodpecker CI с Gitea

```bash
ansible-playbook -i inventory/hosts playbooks/install-and-configure-woodpecker.yml
```

## Конфигурация

Основной конфигурационный файл: `/etc/woodpecker/config.yml`

Важные параметры:

-   `server` - настройки сервера
    -   `host` - хост сервера
    -   `port` - порт сервера
    -   `oauth2` - настройки OAuth2
-   `database` - настройки базы данных
    -   `driver` - драйвер БД
    -   `datasource` - строка подключения
-   `agent` - настройки агента
    -   `backend` - бэкенд
    -   `platform` - платформа

## Безопасность

-   Woodpecker CI работает под системным пользователем `woodpecker`
-   Конфигурационный файл доступен только пользователю `woodpecker`
-   Данные хранятся в `/var/lib/woodpecker` с ограниченными правами доступа
-   Используется OAuth2 для аутентификации
-   Настроены ограничения на подключение

## Мониторинг

-   Журналы: `/var/log/woodpecker/`
-   Статус сервиса: `systemctl status woodpecker`

## Устранение неполадок

1. Проверка статуса сервиса:

    ```bash
    systemctl status woodpecker
    ```

2. Проверка логов:

    ```bash
    journalctl -u woodpecker
    ```

3. Проверка конфигурации:

    ```bash
    woodpecker doctor
    ```

4. Проверка прав доступа:

    ```bash
    ls -l /etc/woodpecker/config.yml
    ls -l /var/lib/woodpecker/
    ```

5. Проверка подключения к Gitea:

    ```bash
    curl -s http://localhost:8000/api/health
    ```

6. Проверка агентов:
    ```bash
    woodpecker agent info
    ```
