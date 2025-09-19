#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage: $0 <domain>"
    exit 1
fi

DOMAIN=$1

echo "Configuring SSL for $DOMAIN"

# Update nginx config with actual domain
sed -i "s/DOMAIN_PLACEHOLDER/$DOMAIN/g" /etc/nginx/sites-available/loglibrary-terminal

# Enable the site
ln -sf /etc/nginx/sites-available/loglibrary-terminal /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test nginx config
nginx -t

if [ $? -ne 0 ]; then
    echo "❌ Nginx configuration error"
    exit 1
fi

# Restart nginx
systemctl restart nginx

# Get SSL certificate
read -p "Enter email for SSL certificate: " EMAIL
certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email "$EMAIL"

if [ $? -eq 0 ]; then
    echo "✅ SSL configured successfully!"
    echo "Your terminal server is now available at: https://$DOMAIN"
    echo ""
    echo "Update your terminal-config.js with:"
    echo "url: 'wss://$DOMAIN'"
else
    echo "❌ SSL setup failed. Check domain DNS and try again."
    exit 1
fi