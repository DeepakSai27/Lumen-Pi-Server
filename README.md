# Lumen Pi Server

Raspberry Pi 3 Model B on the office network, running an nginx web server.
The site lives in `Site/` and is published to the Pi with `Deploy.ps1`.

## The Pi

| Item | Value |
|---|---|
| Model | Raspberry Pi 3 Model B (1 GB RAM, Bluetooth 4.1) |
| OS | Raspberry Pi OS 64-bit, Debian 12 Bookworm (desktop image, 2024-03-15) |
| IP | `192.168.1.45` (static, set on the Pi) |
| Hostname | `raspberrypi` / `raspberrypi.local` |
| User | `raspberrylumen` (password kept out of this repo) |
| Web root | `/var/www/html` |
| Site URL | http://192.168.1.45 |

Services enabled at boot: `ssh` (22), `nginx` (80), VNC (5900).

## Access

```powershell
ssh raspberrylumen@192.168.1.45
```

Key-based login works from a PC whose public key is in `~/.ssh/authorized_keys` on the Pi.
To add a new PC's key (asks for the Pi password once):

```powershell
Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub | ssh raspberrylumen@192.168.1.45 "cat >> ~/.ssh/authorized_keys"
```

## Publishing the site

Edit files in `Site/`, then:

```powershell
.\Deploy.ps1
```

This copies `Site/` to `/var/www/html` on the Pi and checks the page loads.

## Setup scripts

Run on the Pi (over SSH) to rebuild it from a fresh card:

| Script | What it does |
|---|---|
| `Setup/Enable-SSH-Key.sh` | One-shot boot script: adds a public key to user 1000 and enables SSH. Copy to the boot partition and hook into `cmdline.txt` (see the script header). |
| `Setup/Static-IP.sh` | Sets the static IP on `eth0` with NetworkManager. |
| `Setup/Install-Nginx.sh` | Installs nginx, enables it at boot and sets web-root ownership. |

## Open items

- **Power supply:** the Pi reports under-voltage (`vcgencmd get_throttled` = `0x50005`). Use a 5.1 V / 2.5 A supply.
- **System upgrade:** `sudo apt full-upgrade` is on hold until the power supply is fixed.
- **Router:** reserve `192.168.1.45` for MAC `B8:27:EB:CD:0A:04` so DHCP never hands it out.
