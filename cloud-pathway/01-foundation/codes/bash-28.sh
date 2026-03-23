#!/bin/bash

APP_NAME="webapp"
DEPLOY_DIR="/var/www/${APP_NAME}"
BACKUP_DIR="/backup/${APP_NAME}"
GIT_REPO="https://github.com/user/webapp.git"

echo "Starting deployment..."

if [ -d "$DEPLOY_DIR" ]; then
    echo "Backing up current version..."
    mkdir -p "$BACKUP_DIR"
    tar -czf "${BACKUP_DIR}/backup_$(date +%Y%m%d_%H%M%S).tar.gz" -C "$DEPLOY_DIR" .
fi

echo "Pulling latest code..."
if [ -d "${DEPLOY_DIR}/.git" ]; then
    cd "$DEPLOY_DIR"
    git pull
else
    git clone "$GIT_REPO" "$DEPLOY_DIR"
    cd "$DEPLOY_DIR"
fi

echo "Installing dependencies..."
npm install --production

echo "Restarting service..."
sudo systemctl restart ${APP_NAME}

echo "Deployment completed!"