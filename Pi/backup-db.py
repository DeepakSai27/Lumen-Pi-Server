#!/usr/bin/env python3
"""Nightly backup of the Lumen Asset Tracking database (safe while the server runs).
Keeps the last KEEP_DAYS daily copies in ~/lumen-asset-tracking/backups."""
import sqlite3, time
from datetime import datetime
from pathlib import Path

KEEP_DAYS = 30
root = Path.home() / "lumen-asset-tracking"
src_path = root / "Server" / "data" / "lumen.db"
out_dir = root / "backups"
out_dir.mkdir(exist_ok=True)

out = out_dir / f"lumen-{datetime.now():%Y-%m-%d}.db"
tmp = out.with_suffix(".tmp")
src = sqlite3.connect(f"file:{src_path}?mode=ro", uri=True)
dst = sqlite3.connect(tmp)
src.backup(dst)
ok = dst.execute("PRAGMA integrity_check").fetchone()[0]
dst.close(); src.close()
if ok != "ok":
    tmp.unlink(missing_ok=True)
    raise SystemExit(f"integrity check failed: {ok}")
tmp.replace(out)

cutoff = time.time() - KEEP_DAYS * 86400
for f in out_dir.glob("lumen-*.db"):
    if f.stat().st_mtime < cutoff:
        f.unlink()
print(f"backup ok: {out} ({out.stat().st_size} bytes)")
