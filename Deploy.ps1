# Publish Site/ to the Pi's web root and check the page loads.
#   .\Deploy.ps1                      # default Pi
#   .\Deploy.ps1 -PiHost 192.168.1.50 # another Pi
param(
    [string]$PiHost = '192.168.1.45',
    [string]$PiUser = 'raspberrylumen'
)
$ErrorActionPreference = 'Stop'
$site = Join-Path $PSScriptRoot 'Site'
$target = "$PiUser@$PiHost"

Write-Host "Copying $site to ${target}:/var/www/html ..."
ssh $target 'rm -rf /tmp/site-upload'
scp -r -q "$site" "${target}:/tmp/site-upload"
if ($LASTEXITCODE -ne 0) { throw 'scp failed' }
ssh $target 'sudo rsync -a --delete /tmp/site-upload/ /var/www/html/ && sudo chown -R $(whoami):www-data /var/www/html && rm -rf /tmp/site-upload'
if ($LASTEXITCODE -ne 0) { throw 'install on Pi failed' }

$code = (Invoke-WebRequest -Uri "http://$PiHost/" -UseBasicParsing -TimeoutSec 10).StatusCode
Write-Host "Done. http://$PiHost/ returned HTTP $code"
