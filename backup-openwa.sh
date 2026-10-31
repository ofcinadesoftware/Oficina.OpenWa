#!/usr/bin/env bash
# Backup diário do OpenWA (banco SQLite, sessões do whatsapp-web.js e mídia), 14 dias de retenção.
# Cron (04:30, depois do backup do Kid Money às 04:00):
#   30 4 * * * /opt/openwa/oficina/backup-openwa.sh >> /opt/openwa/backup.log 2>&1
# As sessões são copiadas com o Chromium aberto: o restore normalmente reconecta sem QR, mas se não
# reconectar, pare o container antes de rodar o backup (docs/11-operational-runbooks.md).
# /opt/openwa/backups pertence ao usuário do container (997): gravar e apagar ali só por dentro dele.
set -euo pipefail

docker exec -e BACKUP_DIR=/backups -e TMPDIR=/backups openwa ./scripts/backup.sh
docker exec openwa find /backups -name 'openwa-backup-*.tar.gz' -mtime +14 -delete
