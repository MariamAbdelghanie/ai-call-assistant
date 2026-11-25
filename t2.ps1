$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectDir
Write-Host "1/2 UDP testi calisiyor (~8 saniye)..." -ForegroundColor Cyan
& ".\.venv\Scripts\python.exe" udp_test.py *> tani1.txt
Write-Host "2/2 LiveKit kayitlari aliniyor..." -ForegroundColor Cyan
wsl -d Ubuntu-24.04 -u root docker logs livekit-server --tail 40 *> tani2.txt
Write-Host "`nBitti: tani1.txt ve tani2.txt yazildi." -ForegroundColor Green
Get-Content tani1.txt
