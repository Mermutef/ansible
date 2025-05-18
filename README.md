# Ansible Playbook для развертывания Gitea и Woodpecker CI

Этот проект содержит Ansible playbook для автоматизированного развертывания и настройки Gitea (система управления Git-репозиториями) и Woodpecker CI (система непрерывной интеграции) на сервере ALT Linux.

## Требования

- Ansible 2.9 или выше
- ALT Linux
- Доступ к серверу по SSH
- Python 3.12

## Структура проекта

```
.
├── inventory/           # Инвентарь Ansible
│   └── hosts          # Файл с определением хостов
├── group_vars/         # Переменные для групп хостов
│   ├── gitea_vars.yml
│   ├── postgres_vars.yml
│   └── woodpecker_vars.yml
├── roles/             # Роли Ansible
│   ├── backup/        # Роль для резервного копирования
│   ├── gitea/         # Роль для установки Gitea
│   ├── postgres/      # Роль для установки PostgreSQL
│   └── woodpecker/    # Роль для установки Woodpecker CI
└── playbooks/         # Playbook'и Ansible
    ├── install-and-configure-gitea.yml
    ├── install-gitea.yml
    ├── install-postgres.yml
    ├── install-woodpecker.yml
    ├── configure-db.yml
    ├── backup.yml
    ├── restore.yml
    ├── deploy_backups_system.yml
    ├── download_backup.yml
    └── upload_backup.yml
```

## Настройка

1. Настройте файл `inventory/hosts`:
   ```yaml
   [alt]
   192.168.56.101 

   [alt:vars]
   ansible_ssh_private_key_file=~/.ssh/id_ed25519
   ansible_user=user
   ansible_become_pass=12345
   ansible_python_interpreter=/usr/bin/python3.12
   ```

2. Настройте переменные в `group_vars/`:
   - `gitea_vars.yml` - настройки Gitea
   - `postgres_vars.yml` - настройки PostgreSQL
   - `woodpecker_vars.yml` - настройки Woodpecker CI

## Использование

### Установка всех компонентов

```bash
ansible-playbook -i inventory/hosts playbooks/template-installation.yml
```

### Отдельные операции

1. Установка PostgreSQL:
   ```bash
   ansible-playbook -i inventory/hosts playbooks/install-postgres.yml
   ```

2. Установка Gitea:
   ```bash
   ansible-playbook -i inventory/hosts playbooks/install-gitea.yml
   ```

3. Установка Woodpecker CI:
   ```bash
   ansible-playbook -i inventory/hosts playbooks/install-woodpecker.yml
   ```

4. Создание резервной копии:
   ```bash
   ansible-playbook -i inventory/hosts playbooks/backup.yml
   ```

5. Восстановление из резервной копии:
   ```bash
   ansible-playbook -i inventory/hosts playbooks/restore.yml
   ```

## Резервное копирование

Система включает в себя автоматическое резервное копирование следующих компонентов:
- База данных Gitea
- База данных Woodpecker CI
- Конфигурационные файлы
- Репозитории
- Данные пользователей

Резервные копии сохраняются в директории `/opt/backups` на сервере.

### Загрузка резервной копии на сервер

```bash
ansible-playbook -i inventory/hosts playbooks/upload_backup.yml
```

### Скачивание резервной копии с сервера

```bash
ansible-playbook -i inventory/hosts playbooks/download_backup.yml
```

## Безопасность

- Все сервисы работают под отдельными системными пользователями
- Используется шифрование паролей в базе данных
- Настроены минимально необходимые права доступа
- Все конфигурационные файлы имеют ограниченные права доступа

## Мониторинг

- Журналы Gitea: `/var/log/gitea/`
- Журналы Woodpecker CI: `journalctl -u woodpecker-server` и `journalctl -u woodpecker-agent`
- Журналы PostgreSQL: `journalctl -u postgresql`

## Устранение неполадок

1. Проверка статуса сервисов:
   ```bash
   systemctl status gitea
   systemctl status woodpecker-server
   systemctl status woodpecker-agent
   systemctl status postgresql
   ```

2. Проверка журналов:
   ```bash
   journalctl -u gitea
   journalctl -u woodpecker-server
   journalctl -u woodpecker-agent
   journalctl -u postgresql
   ```

3. Проверка доступности баз данных:
   ```bash
   su -l postgres -s /bin/bash -c "psql -d giteadb -c 'SELECT 1'"
   su -l postgres -s /bin/bash -c "psql -d woodpecker -c 'SELECT 1'"
   ``` 