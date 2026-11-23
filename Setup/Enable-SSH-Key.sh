#!/bin/bash
# One-shot boot script: add a public SSH key to the Pi's main user (UID 1000),
# enable SSH, record the user name on the boot partition, then remove itself.
#
# Use when you can't log in to an already set-up card:
#   1. Put PUBKEY below (contents of id_ed25519.pub on your PC).
#   2. Copy this file to the boot partition as firstrun.sh.
#   3. Append to the single line in cmdline.txt:
#        systemd.run=/boot/firmware/firstrun.sh systemd.run_success_action=reboot systemd.unit=kernel-command-line.target
#   4. Boot the Pi. It runs once, reboots, and writes pi-user.txt to the boot partition.
set +e
PUBKEY='ssh-ed25519 AAAA...replace-me... pc-to-pi'

U=$(getent passwd 1000 | cut -d: -f1)
H=$(getent passwd 1000 | cut -d: -f6)
mkdir -p "$H/.ssh"
echo "$PUBKEY" >> "$H/.ssh/authorized_keys"
chmod 700 "$H/.ssh"; chmod 600 "$H/.ssh/authorized_keys"
chown -R "$U:$U" "$H/.ssh"
systemctl enable ssh
{ echo "user=$U"; echo "home=$H"; date; } > /boot/firmware/pi-user.txt
rm -f /boot/firmware/firstrun.sh
sed -i 's| systemd.run.*||g' /boot/firmware/cmdline.txt
exit 0
