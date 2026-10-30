# Start FreeLLMAPI on 127.0.0.1:3001 for local use only (no customer traffic).
# Uses twinward.env if present (gitignored), else the committed example.
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$envFile = Join-Path $here 'twinward.env'
if (-not (Test-Path $envFile)) { $envFile = Join-Path $here 'twinward.env.example' }
$env:FREEAPI_ENV_PATH = $envFile
$data = 'C:\Users\Drex\freellmapi-data'
if (-not (Test-Path $data)) { New-Item -ItemType Directory -Force $data | Out-Null }
if (Test-Path 'H:\striv\tools\nodejs\node.exe') { $env:Path = 'H:\striv\tools\nodejs;' + $env:Path }
Set-Location (Join-Path $here '..\..\server')
& npx tsx src/index.ts