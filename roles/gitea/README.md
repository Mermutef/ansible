# Роль gitea

Роль для установки и настройки Gitea - системы управления Git-репозиториями.

## Содержание

-   [Описание](#описание)
-   [Структура](#структура)
-   [Использование](#использование)
-   [Конфигурация](#конфигурация)
-   [Устранение неполадок](#устранение-неполадок)

## Описание

Эта роль обеспечивает:

-   Установку Gitea из пакетов ALT Linux
-   Настройку системного пользователя
-   Настройку конфигурации
-   Настройку системного сервиса

## Структура

```
roles/gitea/
├── templates/           # Шаблоны конфигурации
│   └── app.ini        # Шаблон конфигурации Gitea
└── README.md          # Документация
```

## Использование

### Установка Gitea

```bash
ansible-playbook -i inventory/hosts playbooks/install-gitea.yml
```

### Настройка базы данных

```bash
ansible-playbook -i inventory/hosts playbooks/configure-gitea-db.yml
```

## Конфигурация

Основной конфигурационный файл: `/etc/gitea/app.ini`

Важные параметры:

-   `[server]` - настройки сервера
    -   `DOMAIN` - домен сервера
    -   `ROOT_URL` - корневой URL
    -   `HTTP_ADDR` - адрес для HTTP
    -   `HTTP_PORT` - порт для HTTP
-   `[database]` - настройки базы данных
    -   `DB_TYPE` - тип БД
    -   `HOST` - хост БД
    -   `NAME` - имя БД
    -   `USER` - пользователь БД
    -   `PASSWD` - пароль БД
-   `[security]` - настройки безопасности
    -   `INSTALL_LOCK` - блокировка установки
    -   `SECRET_KEY` - секретный ключ
-   `[oauth2]` - настройки OAuth2
    -   `ENABLE` - включение OAuth2
    -   `JWT_SECRET` - секрет JWT

## Устранение неполадок

### Проверка статуса сервиса

```bash
systemctl status gitea
```

### Проверка логов

```bash
journalctl -u gitea
```

### Проверка конфигурации

```bash
cat /etc/gitea/app.ini
```

### Проверка прав доступа

```bash
ls -l /etc/gitea/app.ini
ls -l /var/lib/gitea/
```

### Проверка подключения

```bash
curl -s http://localhost:4000/api/v1/version
```
