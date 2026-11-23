# Copy the Lumen Asset Tracking database backups from the Pi to this PC.
# The Pi makes one backup per night (02:00, last 30 days kept); this pulls any
# the PC does not have yet. Run by the "Lumen Pull Backups" scheduled task.
param(
    [string]$PiHost = '192.168.1.45',
    [string]$PiUser = 'raspberrylumen',
    [string]$Dest   = 'D:\Backups\Lumen Asset Tracking'
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force -Path $Dest | Out-Null
$log = Join-Path $Dest 'pull.log'
$target = "$PiUser@$PiHost"

try {
    $remote = ssh -o BatchMode=yes -o ConnectTimeout=10 $target 'ls ~/lumen-asset-tracking/backups/lumen-*.db 2>/dev/null | xargs -n1 basename'
    if ($LASTEXITCODE -ne 0) { throw "cannot reach $target" }
    $new = @($remote | Where-Object { $_ -and -not (Test-Path -LiteralPath (Join-Path $Dest $_)) })
    foreach ($f in $new) {
        scp -q -o BatchMode=yes "${target}:lumen-asset-tracking/backups/$f" (Join-Path $Dest $f)
        if ($LASTEXITCODE -ne 0) { throw "scp failed for $f" }
    }
    $msg = "ok: $($new.Count) new, $(@($remote).Count) on Pi"
} catch {
    $msg = "FAILED: $_"
}
"$(Get-Date -Format 'yyyy-MM-dd HH:mm')  $msg" | Add-Content -LiteralPath $log
Write-Host $msg
