# Роль backup

Роль для настройки системы резервного копирования Gitea и Woodpecker CI.

## Содержание

-   [Описание](#описание)
-   [Структура](#структура)
-   [Использование](#использование)
-   [Конфигурация](#конфигурация)
-   [Устранение неполадок](#устранение-неполадок)

## Описание

Эта роль обеспечивает:

-   Создание резервных копий Gitea и Woodpecker CI
-   Восстановление из резервных копий
-   Базовое управление резервными копиями

## Структура

```
roles/backup/
├── files/                    # Скрипты резервного копирования
│   ├── gitea_backup.sh      # Скрипт резервного копирования Gitea
│   ├── gitea_restore.sh     # Скрипт восстановления Gitea
│   ├── woodpecker_backup.sh # Скрипт резервного копирования Woodpecker
│   └── woodpecker_restore.sh # Скрипт восстановления Woodpecker
└── README.md                # Документация
```

## Использование

### Создание резервной копии

```bash
# Резервное копирование Gitea
ansible-playbook -i inventory/hosts playbooks/backup.yml -e module=gitea

# Резервное копирование Woodpecker
ansible-playbook -i inventory/hosts playbooks/backup.yml -e module=woodpecker
```

### Восстановление из резервной копии

```bash
# Восстановление Gitea
ansible-playbook -i inventory/hosts playbooks/restore.yml -e module=gitea

# Восстановление Woodpecker
ansible-playbook -i inventory/hosts playbooks/restore.yml -e module=woodpecker

# Восстановление конкретной резервной копии
ansible-playbook -i inventory/hosts playbooks/restore.yml -e "module=gitea backup_file=/path/to/backup.tar.gz"
```

## Конфигурация

### Директории резервных копий

-   `/var/backups/gitea` - резервные копии Gitea
-   `/var/backups/woodpecker` - резервные копии Woodpecker

### Права доступа

-   Владелец: `root`
-   Группа: `backup`
-   Права: `750` для директорий, `640` для файлов

## Устранение неполадок

### Проверка резервных копий

```bash
ls -l /var/backups/gitea/
ls -l /var/backups/woodpecker/
```

### Проверка прав доступа

```bash
ls -l /var/backups/
ls -l /usr/local/bin/backup.sh
```
