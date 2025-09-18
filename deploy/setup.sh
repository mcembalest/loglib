#!/bin/bash

# DigitalOcean Terminal Server Setup Script
# Run this on a fresh Ubuntu 22.04 droplet

set -e

echo "🚀 Setting up loglibrary terminal server..."

# Update system
apt update && apt upgrade -y

# Install required packages
apt install -y docker.io docker-compose nginx certbot python3-certbot-nginx git curl

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Add current user to docker group (if not root)
if [ "$USER" != "root" ]; then
    usermod -aG docker $USER
fi

# Create terminal server directory
mkdir -p /opt/loglibrary-terminal
cd /opt/loglibrary-terminal

# Clone your repository for docs
git clone https://github.com/mcembalest/loglibrary.git repo

# Create docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  terminal:
    image: tsl0922/ttyd:latest
    container_name: loglibrary-terminal
    restart: unless-stopped
    ports:
      - "7681:7681"
    volumes:
      - ./repo/docs/content:/docs/content:ro
      - ./restricted_shell.sh:/restricted_shell.sh:ro
    command: [
      "--port", "7681",
      "--writable",
      "--max-clients", "50",
      "/restricted_shell.sh"
    ]
    environment:
      - TERM=xterm-256color
EOF

# Copy and modify the restricted shell script
cp repo/restricted_shell.sh .
sed -i 's|SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"|SCRIPT_DIR="/"|g' restricted_shell.sh
sed -i 's|export CONTENT_ROOT="$SCRIPT_DIR/docs/content"|export CONTENT_ROOT="/docs/content"|g' restricted_shell.sh

# Create nginx configuration
cat > /etc/nginx/sites-available/loglibrary-terminal << 'EOF'
server {
    listen 80;
    server_name DOMAIN_PLACEHOLDER;

    location / {
        proxy_pass http://localhost:7681;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 86400;
    }
}
EOF

# Create auto-update script
cat > update-docs.sh << 'EOF'
#!/bin/bash
cd /opt/loglibrary-terminal/repo
git pull origin main
docker-compose restart terminal
EOF

chmod +x update-docs.sh

# Create systemd service for auto-updates
cat > /etc/systemd/system/loglibrary-docs-update.service << 'EOF'
[Unit]
Description=Update loglibrary docs
After=network.target

[Service]
Type=oneshot
ExecStart=/opt/loglibrary-terminal/update-docs.sh
WorkingDirectory=/opt/loglibrary-terminal
EOF

cat > /etc/systemd/system/loglibrary-docs-update.timer << 'EOF'
[Unit]
Description=Update loglibrary docs every 10 minutes
Requires=loglibrary-docs-update.service

[Timer]
OnCalendar=*:0/10
Persistent=true

[Install]
WantedBy=timers.target
EOF

systemctl enable loglibrary-docs-update.timer
systemctl start loglibrary-docs-update.timer

# Start the terminal server
docker-compose up -d

echo "✅ Terminal server setup complete!"
echo ""
echo "Next steps:"
echo "1. Point your domain to this server's IP"
echo "2. Run: sudo ./configure-ssl.sh yourdomain.com"
echo "3. Update your GitHub Pages terminal config"
echo ""
echo "Terminal is running on port 7681"
echo "Check logs: docker-compose logs -f terminal"