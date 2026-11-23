# Lumen Pi Server

Raspberry Pi 3 Model B on the office network. It runs the
[Lumen Asset Tracking](https://github.com/DeepakSai27/Lumen-Asset-Tracking) server 24/7,
receives reports from the ESP32-C5 checkpoints, and backs up the attendance database every night.

```
[ESP32-C5 checkpoints] --HTTP POST :8000--> [Pi: uvicorn (FastAPI) :8000] <--proxy-- [nginx :80] <-- browsers
                                                    |
                                       Server/data/lumen.db --02:00--> backups/ --09:30--> PC D:\Backups
```

Website: **http://192.168.1.45**

## The Pi

| Item | Value |
|---|---|
| Model | Raspberry Pi 3 Model B (1 GB RAM, Bluetooth 4.1) |
| OS | Raspberry Pi OS 64-bit, Debian 12 Bookworm (desktop image, 2024-03-15) |
| IP | `192.168.1.45` (static, set on the Pi) |
| Hostname | `raspberrypi` / `raspberrypi.local` |
| User | `raspberrylumen` (password kept out of this repo) |

Services enabled at boot: `ssh` (22), `nginx` (80), `lumen-asset-tracking` (8000), VNC (5900),
and the `lumen-db-backup.timer`.

## Layout on the Pi

| Path | What |
|---|---|
| `~/lumen-asset-tracking/Server/` | Server code copied from the Lumen Asset Tracking repo, with its own `.venv` |
| `~/lumen-asset-tracking/Server/lumen.env` | Settings incl. `LUMEN_API_TOKEN` (mode 600, not in git) |
| `~/lumen-asset-tracking/Server/data/lumen.db` | Live attendance database |
| `~/lumen-asset-tracking/backups/` | Nightly backups, `lumen-YYYY-MM-DD.db`, last 30 days |
| `~/lumen-asset-tracking/backup-db.py` | Backup script |

## Files in this repo

| File | Installed on the Pi as |
|---|---|
| `Pi/systemd/lumen-asset-tracking.service` | `/etc/systemd/system/` — runs uvicorn on port 8000, restarts on failure |
| `Pi/nginx/lumen-asset-tracking.conf` | `/etc/nginx/sites-available/lumen-asset-tracking` (linked in `sites-enabled`, default site removed) — proxies port 80 to 8000 |
| `Pi/backup-db.py` | `~/lumen-asset-tracking/backup-db.py` |
| `Pi/systemd/lumen-db-backup.service` / `.timer` | `/etc/systemd/system/` — runs the backup at 02:00 (catches up after power loss) |
| `Pull-Backups.ps1` | Runs on the PC (scheduled task "Lumen Pull Backups", daily 09:30) — copies new backups to `D:\Backups\Lumen Asset Tracking`, logs to `pull.log` there |
| `Setup/*.sh` | Rebuild steps for a fresh card: SSH key access, static IP, nginx |

## Common tasks

```powershell
ssh raspberrylumen@192.168.1.45                                  # log in (key-based from this PC)
ssh raspberrylumen@192.168.1.45 "journalctl -u lumen-asset-tracking -f"   # live server log
ssh raspberrylumen@192.168.1.45 "sudo systemctl restart lumen-asset-tracking"
```

**Update the server code** (from the Lumen Asset Tracking repo folder):

```bash
tar --exclude=.venv --exclude=data --exclude=__pycache__ --exclude=lumen.env -czf - Server \
  | ssh raspberrylumen@192.168.1.45 "cd ~/lumen-asset-tracking && tar -xzf - && sudo systemctl restart lumen-asset-tracking"
```

If `requirements.txt` changed, also run `Server/.venv/bin/pip install -r Server/requirements.txt` on the Pi.

**Restore a backup:**

```bash
sudo systemctl stop lumen-asset-tracking
cd ~/lumen-asset-tracking/Server/data && rm -f lumen.db-wal lumen.db-shm
cp ~/lumen-asset-tracking/backups/lumen-YYYY-MM-DD.db lumen.db
sudo systemctl start lumen-asset-tracking
```

**Add a new PC's SSH key** (asks for the Pi password once):

```powershell
Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub | ssh raspberrylumen@192.168.1.45 "cat >> ~/.ssh/authorized_keys"
```

## Open items

- **Power supply:** the Pi reports under-voltage (`vcgencmd get_throttled` = `0x50005`). Fit a 5.1 V / 2.5 A supply.
- **System upgrade:** `sudo apt full-upgrade` is on hold until the power supply is fixed.
- **Router:** reserve `192.168.1.45` for MAC `B8:27:EB:CD:0A:04` so DHCP never hands it out.
