#!/bin/bash
# Set the website's login (user name + password) and restart the server.
# Run from a PC:  ssh -t raspberrylumen@192.168.1.45 ~/lumen-asset-tracking/set-admin-password.sh
# The password is typed here (hidden) and stored only in Server/lumen.env (mode 600) on the Pi.
# Changing it signs everyone out.
set -e
ENV_FILE="$HOME/lumen-asset-tracking/Server/lumen.env"

read -rp "Admin user name [admin]: " NEW_USER
NEW_USER=${NEW_USER:-admin}
while true; do
    read -rsp "New password: " P1; echo
    read -rsp "Repeat password: " P2; echo
    if [ "$P1" != "$P2" ]; then echo "Passwords do not match, try again."; continue; fi
    if [ ${#P1} -lt 8 ]; then echo "Use at least 8 characters."; continue; fi
    case "$P1" in *[[:space:]\"\'\\]*) echo "Please avoid spaces, quotes and backslashes."; continue ;; esac
    break
done

LUMEN_NEW_USER="$NEW_USER" LUMEN_NEW_PW="$P1" python3 - "$ENV_FILE" <<'EOF'
import os, sys
path = sys.argv[1]
want = {"LUMEN_ADMIN_USER": os.environ["LUMEN_NEW_USER"], "LUMEN_ADMIN_PASSWORD": os.environ["LUMEN_NEW_PW"]}
try:
    lines = open(path).read().splitlines()
except FileNotFoundError:
    lines = []
out, done = [], set()
for line in lines:
    key = line.split("=", 1)[0].strip()
    if key in want:
        out.append(f"{key}={want[key]}"); done.add(key)
    else:
        out.append(line)
out += [f"{k}={v}" for k, v in want.items() if k not in done]
open(path, "w").write("\n".join(out) + "\n")
EOF
chmod 600 "$ENV_FILE"
unset P1 P2

sudo systemctl restart lumen-asset-tracking
sleep 3
if systemctl is-active --quiet lumen-asset-tracking; then
    echo "Done. Sign in at http://$(hostname -I | awk '{print $1}') as '$NEW_USER'."
else
    echo "Server did not start - check: journalctl -u lumen-asset-tracking -n 30"
fi
