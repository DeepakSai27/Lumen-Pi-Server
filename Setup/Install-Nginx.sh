#!/bin/bash
# Install nginx, start it at boot, and let the login user own the web root.
# Usage: sudo ./Install-Nginx.sh
set -e
OWNER=${SUDO_USER:-$(getent passwd 1000 | cut -d: -f1)}

apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nginx
systemctl enable --now nginx
rm -f /var/www/html/index.nginx-debian.html
chown -R "$OWNER:www-data" /var/www/html
systemctl is-active nginx
