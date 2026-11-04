$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectDir

Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$projectDir'; .\.venv\Scripts\python.exe -u lan_bridge.py"
Start-Sleep -Seconds 3
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$projectDir'; .\.venv\Scripts\python.exe -u web_dialer.py"
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$projectDir'; .\.venv\Scripts\python.exe -u agent.py dev"
