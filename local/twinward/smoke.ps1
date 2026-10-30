# One chat request through FreeLLMAPI to local Ollama. Reads the unified key
# from the local DB into memory and never prints it.
param([string]$Model = 'mistral:7b', [string]$Db = 'C:\Users\Drex\freellmapi-data\freellmapi.db')
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
if (Test-Path 'H:\striv\tools\nodejs\node.exe') { $env:Path = 'H:\striv\tools\nodejs;' + $env:Path }
$env:SMOKE_DB = $Db; $env:SMOKE_MODEL = $Model
Set-Location (Join-Path $here '..\..\server')
& node (Join-Path $here 'smoke.mjs')