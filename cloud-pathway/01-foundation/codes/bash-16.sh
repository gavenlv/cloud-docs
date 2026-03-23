#!/bin/bash

SOURCE="/var/www/html"
DEST="/backup"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="backup_${DATE}.tar.gz"

echo "Starting backup..."
tar -czf "${DEST}/${BACKUP_FILE}" "${SOURCE}"

if [ $? -eq 0 ]; then
    echo "Backup completed: ${BACKUP_FILE}"
    
    find ${DEST} -name "backup_*.tar.gz" -mtime +7 -delete
    echo "Old backups cleaned"
else
    echo "Backup failed!"
    exit 1
fi