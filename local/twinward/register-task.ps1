# Registers the "Twinward FreeLLMAPI" scheduled task: at Drex's logon, hidden,
# restart on failure, runs run-service.ps1 (127.0.0.1:3001 only).
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$name = 'Twinward FreeLLMAPI'
$arg = '-NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File "' + (Join-Path $here 'run-service.ps1') + '"'
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $arg -WorkingDirectory $here
$trigger = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
$trigger.Delay = 'PT45S'
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet -Hidden -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable `
  -RestartCount 999 -RestartInterval (New-TimeSpan -Minutes 1) -ExecutionTimeLimit ([TimeSpan]::Zero) -MultipleInstances IgnoreNew
Register-ScheduledTask -TaskName $name -Action $action -Trigger $trigger -Principal $principal -Settings $settings `
  -Description 'Local-only FreeLLMAPI router for the twins (127.0.0.1:3001). Branch twinward/local-ollama.' -Force | Out-Null
Get-ScheduledTask -TaskName $name | Select-Object TaskName, State