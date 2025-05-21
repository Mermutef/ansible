# Ansible Playbook для развертывания Gitea и Woodpecker CI

Этот проект содержит Ansible playbook для автоматизированного развертывания и настройки Gitea (система управления Git-репозиториями) и Woodpecker CI (система непрерывной интеграции) на сервере ALT Linux.

## Содержание

-   [Требования](#требования)
-   [Структура проекта](#структура-проекта)
-   [Быстрый старт](#быстрый-старт)
-   [Настройка](#настройка)
-   [Использование](#использование)
-   [Резервное копирование](#резервное-копирование)
-   [Безопасность](#безопасность)
-   [Мониторинг](#мониторинг)
-   [Устранение неполадок](#устранение-неполадок)

## Требования

### 1. Требования к целевому хосту

-   ALT Linux
-   Доступ по SSH
-   Python 3.12

### 2. Требования к машине развертки

-   Ansible 2.9 или выше
-   Доступ по SSH
-   Python 3.12
-   Ansible Vault для шифрования чувствительных данных

## Структура проекта

```
.
├── inventory/           # Инвентарь Ansible
│   └── hosts          # Файл с определением хостов
├── group_vars/         # Переменные для групп хостов
│   ├── vault.yml      # Зашифрованные переменные
│   ├── gitea_vars.yml
│   ├── postgres_vars.yml
│   └── woodpecker_vars.yml
├── roles/             # Роли Ansible
│   ├── backup/        # Роль для резервного копирования
│   ├── gitea/         # Роль для установки Gitea
│   ├── postgresql/    # Роль для установки PostgreSQL
│   └── woodpecker/    # Роль для установки Woodpecker CI
└── playbooks/         # Playbook'и Ansible
    ├── sync-time.yml
    ├── template-installation.yml
    ├── deploy_backups_system.yml
    ├── install-woodpecker.yml
    ├── install-and-configure-woodpecker.yml
    ├── install-and-configure-gitea.yml
    ├── restore.yml
    ├── download_backup.yml
    ├── upload_backup.yml
    ├── backup.yml
    ├── verify-db-access.yml
    ├── install-postgres.yml
    ├── install-gitea.yml
    ├── configure-woodpecker-db.yml
    ├── configure-gitea-db.yml
    └── configure-db.yml
```

## Быстрый старт

1. Клонируйте репозиторий:

```bash
git clone <repository-url>
cd ansible
```

2. Создайте файл с паролем для Vault:

```bash
echo "your-vault-password" > .vault_pass
chmod 600 .vault_pass
```

3. Настройте инвентарь и переменные (см. раздел [Настройка](#настройка))

4. Синхронизируйте время на сервере:

```bash
ansible-playbook -i inventory/hosts playbooks/sync-time.yml
```

5. Запустите установку:

```bash
ansible-playbook -i inventory/hosts playbooks/template-installation.yml --vault-password-file .vault_pass
```

## Настройка

### 1. Настройка инвентаря

Отредактируйте файл `inventory/hosts`:

```yaml
[alt]
192.168.56.101

[alt:vars]
ansible_ssh_private_key_file=~/.ssh/id_ed25519
ansible_user=user
ansible_become_pass=12345
ansible_python_interpreter=/usr/bin/python3.12
```

### 2. Настройка переменных

#### Открытые переменные (group_vars/)

-   `gitea_vars.yml` - настройки Gitea
-   `postgres_vars.yml` - настройки PostgreSQL
-   `woodpecker_vars.yml` - настройки Woodpecker CI

#### Зашифрованные переменные (group_vars/vault.yml)

```yaml
# Создание зашифрованного файла
ansible-vault create group_vars/vault.yml
# Содержимое файла
---
# Gitea secrets
vault_gitea_db_password: "your_password"
vault_gitea_secret_key: "your_secret_key"

# Woodpecker secrets
vault_woodpecker_db_password: "your_password"
vault_woodpecker_agent_secret: "your_agent_secret"
vault_woodpecker_gitea_client_id: "your_gitea_client_id"
vault_woodpecker_gitea_client_secret: "your_gitea_client_secret"
```

## Использование

### Подготовка сервера

Перед установкой компонентов рекомендуется синхронизировать время на сервере:

```bash
ansible-playbook -i inventory/hosts playbooks/sync-time.yml
```

### Установка компонентов

1. Установка всех компонентов с развертыванием из резервной копии:

```bash
ansible-playbook -i inventory/hosts playbooks/template-installation.yml --vault-password-file .vault_pass
```

2. Отдельная установка компонентов:

```bash
# PostgreSQL
ansible-playbook -i inventory/hosts playbooks/install-postgres.yml --vault-password-file .vault_pass

# Gitea
ansible-playbook -i inventory/hosts playbooks/install-gitea.yml --vault-password-file .vault_pass

# Woodpecker CI
ansible-playbook -i inventory/hosts playbooks/install-woodpecker.yml --vault-password-file .vault_pass
```

## Резервное копирование

### Создание резервной копии

```bash
ansible-playbook -i inventory/hosts playbooks/backup.yml --vault-password-file .vault_pass
```

### Восстановление

```bash
# Восстановление последней резервной копии
ansible-playbook -i inventory/hosts playbooks/restore.yml --vault-password-file .vault_pass

# Восстановление конкретной резервной копии
ansible-playbook -i inventory/hosts playbooks/restore.yml -e "backup_file=/path/to/backup.tar.gz" --vault-password-file .vault_pass
```

### Управление резервными копиями

```bash
# Загрузка на сервер
ansible-playbook -i inventory/hosts playbooks/upload_backup.yml -e module=gitea --vault-password-file .vault_pass

# Скачивание с сервера
ansible-playbook -i inventory/hosts playbooks/download_backup.yml -e module=woodpecker --vault-password-file .vault_pass
```

## Безопасность

-   Все сервисы работают под отдельными системными пользователями
-   Используется шифрование паролей в базе данных
-   Настроены минимально необходимые права доступа
-   Все конфигурационные файлы имеют ограниченные права доступа
-   Резервные копии защищены от несанкционированного доступа
-   Чувствительные данные хранятся в зашифрованном виде с использованием Ansible Vault

## Мониторинг

### Журналы

-   Gitea: `/var/log/gitea/`
-   Woodpecker CI: `journalctl -u woodpecker-server` и `journalctl -u woodpecker-agent`
-   PostgreSQL: `journalctl -u postgresql`
-   Восстановление: `/var/log/gitea/restore.log` и `/var/log/woodpecker/restore.log`

## Устранение неполадок

### Проверка статуса сервисов

```bash
systemctl status gitea
systemctl status woodpecker-server
systemctl status woodpecker-agent
systemctl status postgresql
```

### Проверка журналов

```bash
journalctl -u gitea
journalctl -u woodpecker-server
journalctl -u woodpecker-agent
journalctl -u postgresql
```

### Проверка баз данных

```bash
su -l postgres -s /bin/bash -c "psql -d giteadb -c 'SELECT 1'"
su -l postgres -s /bin/bash -c "psql -d woodpecker -c 'SELECT 1'"
```

### Проверка резервных копий

```bash
ls -l /var/backups/
ls -l /var/backups/gitea/
ls -l /var/backups/woodpecker/
```
