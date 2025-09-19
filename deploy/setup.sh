#!/bin/bash

# DigitalOcean Terminal Server Setup Script
# Run this on a fresh Ubuntu 22.04 droplet

set -e

echo "Setting up loglibrary terminal"

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

# Build custom terminal image that matches local setup exactly
docker build -t loglibrary-terminal ./repo -f ./repo/Dockerfile.terminal

# Create docker-compose.yml that replicates local terminal behavior
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  terminal:
    image: loglibrary-terminal
    container_name: loglibrary-terminal
    restart: unless-stopped
    ports:
      - "7681:7681"
    command: [
      "ttyd",
      "--port", "7681",
      "--max-clients", "20",
      "--writable",
      "/restricted_shell.sh"
    ]
    environment:
      - TERM=xterm-256color
      - CONTENT_ROOT=/docs/content
    volumes:
      - terminal_workspace:/workspace
    working_dir: /workspace

volumes:
  terminal_workspace:
EOF

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
# Rebuild the terminal image with updated content
docker build -t loglibrary-terminal . -f ./Dockerfile.terminal
# Restart the terminal service
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

echo "Terminal server setup complete"
echo ""
echo "Next steps:"
echo "1. Point your domain to this server's IP"
echo "2. Run: sudo ./configure-ssl.sh yourdomain.com"
echo "3. Update your GitHub Pages terminal config"
echo ""
echo "Terminal is running on port 7681"
echo "Check logs: docker-compose logs -f terminal"