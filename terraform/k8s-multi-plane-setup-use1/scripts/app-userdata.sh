#!/bin/bash

CONF_FILE="/etc/nginx/conf.d/health_check.conf"
HEALTH_ENDPOINT="/health"


# Update package repositories
sudo dnf check-update

# Install Nginx
sudo dnf install -y nginx
sudo systemctl enable nginx
# Change default port from 80 to 8080 in the configuration file

sudo semanage fcontext -a -t httpd_sys_rw_content_t "/etc/nginx/conf.d(/.*)?"
sudo restorecon -Rv /etc/nginx/conf.d

sudo sed -i 's/listen       80;/listen       8080;/g' /etc/nginx/nginx.conf
sudo sed -i 's/listen       \[::\]:80;/listen       \[::\]:8080;/g' /etc/nginx/nginx.conf

echo "Creating Nginx configuration file at $CONF_FILE..."

# Write the dedicated health check configuration
cat << 'EOF' > "$CONF_FILE"
server {
    listen 8080;
    server_name localhost;

    location = /health {
        access_log off;
        allow all;
        default_type application/json;
        return 200 '{"status":"UP","timestamp":"$time_iso8601"}';
    }
}
EOF

# Configure SELinux to allow Nginx to use port 8080
sudo semanage port -a -t http_port_t -p tcp 8080 2>/dev/null || sudo semanage port -m -t http_port_t -p tcp 8080


# Enable Nginx to start on boot and start the service now
echo "🔍 Validating Nginx configuration syntax..."
if sudo nginx -t; then
    echo "✅ Configuration syntax is valid."
    echo "🔄 Reloading Nginx service..."
    sudo systemctl reload nginx

    echo "🚀 Verifying the endpoint response..."
    sleep 1
    curl -i http://localhost:8080/health
    echo -e "\n🎉 /health endpoint successfully configured!"
else
    echo "❌ Nginx configuration test failed. Reverting changes..."
    rm -f "$CONF_FILE"
    exit 1
fi

sudo systemctl enable --now nginx