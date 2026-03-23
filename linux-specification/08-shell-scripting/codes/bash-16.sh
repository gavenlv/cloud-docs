cat > backup.sh << 'EOF'
#!/bin/bash
set -e

BACKUP_DIR="/backup"
SOURCE_DIR="/data"
DATE=$(date +%Y%m%d)

tar czf "$BACKUP_DIR/backup-$DATE.tar.gz" "$SOURCE_DIR"
echo "Backup completed: backup-$DATE.tar.gz"
EOF

chmod +x backup.sh