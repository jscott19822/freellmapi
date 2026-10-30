# Twinward FreeLLMAPI service wrapper (OVERKILL). Local only: 127.0.0.1:3001.
# Loads free-tier provider keys at start from the user's environment or from
# read-only files under H:\striv\secrets, builds the declarative config in
# memory (FREEAPI_CONFIG_JSON, this process only) and runs the server.
# Keys never touch the repo, the console or the log; the log lists provider
# names only. Restarts the server if it exits. Create
# C:\Users\Drex\freellmapi-data\STOP to make the loop exit.
$ErrorActionPreference = 'Continue'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$data = 'C:\Users\Drex\freellmapi-data'
$logs = Join-Path $data 'logs'
New-Item -ItemType Directory -Force $logs | Out-Null
$svcLog = Join-Path $logs 'service.log'
function Log($m) { Add-Content -Path $svcLog -Value ('{0} {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $m) }

# Files are read, never written. Only NAME=value lines whose NAME is asked for are used.
$secretFiles = @('H:\striv\secrets\freellmapi.env', 'H:\striv\secrets\hf.env')
function Get-Secret([string]$name) {
  foreach ($scope in 'Process', 'User') {
    $v = [Environment]::GetEnvironmentVariable($name, $scope)
    if ($v) { return $v.Trim() }
  }
  foreach ($f in $secretFiles) {
    if (-not (Test-Path $f)) { continue }
    foreach ($line in [IO.File]::ReadAllLines($f)) {
      $m = [regex]::Match($line, '^\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=(.*)$')
      if ($m.Success -and $m.Groups[1].Value -eq $name) {
        $v = $m.Groups[2].Value.Trim().Trim('"').Trim("'")
        if ($v) { return $v }
      }
    }
  }
  return $null
}

function Build-Config {
  $cfg = Get-Content (Join-Path $here 'freellmapi.config.example.json') -Raw | ConvertFrom-Json
  $keys = @(); $enabled = @(); $missing = @()
  # Built-in free-tier platforms. Paid keys (XAI_API_KEY, ANTHROPIC_API_KEY) and
  # Google Gemini are deliberately not listed.
  $builtin = [ordered]@{ groq = 'GROQ_API_KEY'; cerebras = 'CEREBRAS_API_KEY'; mistral = 'MISTRAL_API_KEY';
    openrouter = 'OPENROUTER_API_KEY'; nvidia = 'NVIDIA_API_KEY'; cohere = 'COHERE_API_KEY' }
  foreach ($p in $builtin.Keys) {
    $k = Get-Secret $builtin[$p]
    if ($k) { $keys += [pscustomobject]@{ platform = $p; key = $k; label = 'env' }; $enabled += $p } else { $missing += $p }
  }
  $cfAcct = Get-Secret 'CLOUDFLARE_ACCOUNT_ID'; $cfTok = Get-Secret 'CLOUDFLARE_API_TOKEN'
  if ($cfAcct -and $cfTok) { $keys += [pscustomobject]@{ platform = 'cloudflare'; key = "${cfAcct}:${cfTok}"; label = 'env' }; $enabled += 'cloudflare' } else { $missing += 'cloudflare' }
  # Hugging Face: its built-in catalog here is only China-origin models (all
  # blocked), so it goes in as a custom endpoint with non-China models pinned
  # to non-China inference providers (":provider" suffix).
  $hf = Get-Secret 'HF_TOKEN'
  if ($hf) {
    $hfProv = Get-Content (Join-Path $here 'huggingface.provider.example.json') -Raw | ConvertFrom-Json
    $hfProv | Add-Member -NotePropertyName apiKey -NotePropertyValue $hf -Force
    $cfg.customProviders = @($cfg.customProviders) + $hfProv
    $enabled += 'huggingface'
  } else { $missing += 'huggingface' }
  if ($keys.Count -gt 0) { $cfg | Add-Member -NotePropertyName keys -NotePropertyValue $keys -Force }
  Log ("providers enabled: local-ollama{0}; missing keys: {1}" -f ($(if ($enabled) { ', ' + ($enabled -join ', ') } else { '' })), ($missing -join ', '))
  return ($cfg | ConvertTo-Json -Depth 10 -Compress)
}

$envFile = Join-Path $here 'twinward.env'
if (-not (Test-Path $envFile)) { $envFile = Join-Path $here 'twinward.env.example' }
$env:FREEAPI_ENV_PATH = $envFile
if (Test-Path 'H:\striv\tools\nodejs\node.exe') { $env:Path = 'H:\striv\tools\nodejs;' + $env:Path }
$server = (Resolve-Path (Join-Path $here '..\..\server')).Path
$stop = Join-Path $data 'STOP'
Log "wrapper start pid $PID"
while (-not (Test-Path $stop)) {
  if (Get-NetTCPConnection -LocalPort 3001 -State Listen -ErrorAction SilentlyContinue) {
    Log 'port 3001 already in use; waiting'; Start-Sleep 30; continue
  }
  $env:FREEAPI_CONFIG_JSON = Build-Config
  $out = Join-Path $logs 'server.out.log'; $err = Join-Path $logs 'server.err.log'
  foreach ($f in $out, $err) { if (Test-Path $f) { Move-Item $f "$f.1" -Force } }
  $p = Start-Process -FilePath 'node' -ArgumentList '--import', 'tsx', (Join-Path $server 'src\index.ts') -WorkingDirectory $server `
    -RedirectStandardOutput $out -RedirectStandardError $err -WindowStyle Hidden -PassThru
  Remove-Item Env:\FREEAPI_CONFIG_JSON -ErrorAction SilentlyContinue
  Log "server started pid $($p.Id)"
  $p.WaitForExit()
  Log "server exited code $($p.ExitCode); restarting in 15s"
  Start-Sleep 15
}
Log 'STOP file found; wrapper exiting'