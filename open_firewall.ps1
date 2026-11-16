$cmd = @"
Set-NetConnectionProfile -InterfaceAlias 'Wi-Fi' -NetworkCategory Private -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName 'LiveKit-SIP-Zoiper-UDP' -Direction Inbound -Action Allow -Protocol UDP -LocalPort 5060,7882,10000-10020 -Profile Any -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName 'LiveKit-SIP-Zoiper-TCP' -Direction Inbound -Action Allow -Protocol TCP -LocalPort 5060,7880,7881 -Profile Any -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName 'AI-Call-WebDialer-8080' -Direction Inbound -Action Allow -Protocol TCP -LocalPort 8080 -Profile Any -ErrorAction SilentlyContinue
"@
Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command $cmd" -Wait
Write-Output "Firewall rules updated successfully!"
