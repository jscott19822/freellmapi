# Stops the Twinward FreeLLMAPI task, its wrapper and the node server.
param([switch]$KeepStopFlag)
$data = 'C:\Users\Drex\freellmapi-data'
New-Item -ItemType File -Force (Join-Path $data 'STOP') | Out-Null
Stop-ScheduledTask -TaskName 'Twinward FreeLLMAPI' -ErrorAction SilentlyContinue
Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -match 'freellmapi' -and $_.Name -match '^(node|powershell)\.exe$' -and $_.ProcessId -ne $PID } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
if (-not $KeepStopFlag) { Remove-Item (Join-Path $data 'STOP') -ErrorAction SilentlyContinue }