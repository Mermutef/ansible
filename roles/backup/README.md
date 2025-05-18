# Роль backup

Роль для настройки и управления резервным копированием Gitea и Woodpecker CI.

## Описание

Эта роль обеспечивает:

-   Создание резервных копий баз данных
-   Создание резервных копий конфигурационных файлов
-   Создание резервных копий данных пользователей
-   Создание резервных копий репозиториев
-   Восстановление из резервных копий

## Файлы

-   `files/backup.sh` - скрипт для создания резервных копий
-   `files/restore.sh` - скрипт для восстановления из резервных копий

## Использование

### Создание резервной копии

```bash
ansible-playbook -i inventory/hosts playbooks/backup.yml
```

### Восстановление из резервной копии

```bash
ansible-playbook -i inventory/hosts playbooks/restore.yml
```

### Загрузка резервной копии на сервер

```bash
ansible-playbook -i inventory/hosts playbooks/upload_backup.yml
```

### Скачивание резервной копии с сервера

```bash
ansible-playbook -i inventory/hosts playbooks/download_backup.yml
```

## Структура резервных копий

Резервные копии сохраняются в директории `/opt/backups` и включают:

-   `gitea-dump-*.zip` - дамп Gitea
-   `woodpecker-data-*.tar.gz` - данные Woodpecker CI
-   `woodpecker-config-*` - конфигурация Woodpecker CI
-   `gitea-db-*.sql` - дамп базы данных Gitea
-   `woodpecker-db-*.sql` - дамп базы данных Woodpecker CI

Все файлы объединяются в один архив `full_backup_YYYY-MM-DD_HH-MM-SS.tar.gz`.

## Безопасность

-   Резервные копии создаются с ограниченными правами доступа
-   Файлы баз данных доступны только пользователю postgres
-   Конфигурационные файлы доступны только соответствующим пользователям

## Устранение неполадок

1. Проверка наличия резервных копий:

    ```bash
    ls -l /opt/backups/
    ```

2. Проверка журналов восстановления:

    ```bash
    cat /var/log/gitea/restore.log
    ```

3. Проверка прав доступа:
    ```bash
    ls -l /opt/backups/
    ls -l /var/log/gitea/restore.log
    ```
