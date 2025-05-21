# Роль woodpecker

Роль для установки и настройки Woodpecker CI - системы непрерывной интеграции.

## Содержание

-   [Описание](#описание)
-   [Структура](#структура)
-   [Использование](#использование)
-   [Конфигурация](#конфигурация)
-   [Устранение неполадок](#устранение-неполадок)

## Описание

Эта роль обеспечивает:

-   Установку Woodpecker CI из артефактов официального репозитория
-   Настройку системного пользователя
-   Настройку конфигурации
-   Настройку системного сервиса
-   Интеграцию с Gitea
-   Настройку агентов CI

## Структура

```
roles/woodpecker/
├── templates/                    # Шаблоны конфигурации
│   ├── woodpecker-server.env.j2 # Шаблон конфигурации сервера
│   ├── woodpecker-agent.env.j2  # Шаблон конфигурации агента
│   ├── woodpecker-server.service.j2 # Шаблон сервисного файла сервера
│   └── woodpecker-agent.service.j2  # Шаблон сервисного файла агента
└── README.md                    # Документация
```

## Использование

### Установка Woodpecker CI

```bash
ansible-playbook -i inventory/hosts playbooks/install-woodpecker.yml
```

### Настройка базы данных

```bash
ansible-playbook -i inventory/hosts playbooks/configure-woodpecker-db.yml
```

## Конфигурация

Основные конфигурационные файлы:

-   `/etc/woodpecker/woodpecker-server.env` - конфигурация сервера
-   `/etc/woodpecker/woodpecker-agent.env` - конфигурация агента

Важные параметры:

-   `WOODPECKER_HOST` - хост сервера
-   `WOODPECKER_GITEA_URL` - URL Gitea
-   `WOODPECKER_GITEA_CLIENT` - OAuth2 client ID
-   `WOODPECKER_GITEA_SECRET` - OAuth2 client secret
-   `WOODPECKER_AGENT_SECRET` - секрет для аутентификации агента
-   `WOODPECKER_DATABASE_DRIVER` - драйвер БД
-   `WOODPECKER_DATABASE_DATASOURCE` - строка подключения к БД

## Устранение неполадок

### Проверка статуса сервисов

```bash
systemctl status woodpecker-server
systemctl status woodpecker-agent
```

### Проверка логов

```bash
journalctl -u woodpecker-server
journalctl -u woodpecker-agent
```

### Проверка конфигурации

```bash
cat /etc/woodpecker/woodpecker-server.env
cat /etc/woodpecker/woodpecker-agent.env
```

### Проверка подключения к Gitea

```bash
curl -s http://localhost:8000/api/health
```

### Проверка агентов

```bash
curl -s http://localhost:8000/api/agents
```
