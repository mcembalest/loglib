#!/bin/bash

# Script to redeploy terminal server with updates
# Run this on your Digital Ocean droplet after making changes

set -e

echo "🔄 Redeploying loglibrary terminal server..."

# Navigate to terminal directory
cd /opt/loglibrary-terminal

# Stop current services
echo "Stopping current terminal service..."
docker-compose down || true

# Remove old container and image
echo "Cleaning up old containers and images..."
docker rm -f loglibrary-terminal 2>/dev/null || true
docker rmi -f loglibrary-terminal 2>/dev/null || true

# Pull latest code
echo "Pulling latest code..."
cd repo
git pull origin main
cd ..

# Rebuild image with latest code
echo "Rebuilding terminal image..."
docker build -t loglibrary-terminal ./repo -f ./repo/Dockerfile.terminal

# Start services
echo "Starting terminal service..."
docker-compose up -d

# Wait a moment for startup
sleep 3

# Check status
if docker-compose ps | grep -q "Up"; then
    echo "✅ Terminal server redeployed successfully!"
    echo "🌐 Available at: https://terminal.maxcembalest.com"
    echo ""
    echo "Check logs with: docker-compose logs -f terminal"
else
    echo "❌ Deployment failed. Check logs with: docker-compose logs terminal"
    exit 1
fi
