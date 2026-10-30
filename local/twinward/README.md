# Twinward local setup (OVERKILL)

Local-only FreeLLMAPI for Selah and Thaylor. Branch `twinward/local-ollama`.

- Binds to 127.0.0.1:3001 (`HOST`, `ALLOWED_HOSTS=localhost`). No customer traffic, no LAN.
- Routes to local Ollama at http://127.0.0.1:11434/v1 as a custom provider
  (mistral:7b, gemma3:12b, phi4, hermes3), strategy `priority`.
- No keys in the repo. The unified key and any provider keys live encrypted in
  `C:\Users\Drex\freellmapi-data\` (outside the repo). Free-cloud keys come from env or H:\striv\secrets (see below), never git.
- Catalog sync and update checks are off (`CATALOG_SYNC_DISABLED=1`, `FREELLMAPI_UPDATE_CHECK=off`).
- China-origin block: `server/src/lib/origin-block.ts`, enforced in
  `services/router.ts` (`routeRequest`, `routePinnedModel`) via
  `FREELLMAPI_BLOCKED_PLATFORMS` and `FREELLMAPI_BLOCKED_MODEL_PATTERNS` in
  `twinward.env.example`. A blocked row is never dispatched, even when pinned.
- Does NOT change the twins' routing. `H:\thaylor\config\thaylor.toml` still
  points where it did. Switching them is Conner's call.

Run: `powershell -File local\twinward\start-local.ps1` (after `npm ci`).
Smoke: `powershell -File local\twinward\smoke.ps1 -Model mistral:7b`.
Stealth or derived models with unclear or China-origin weights are also blocked: cogito-2.1 (DeepSeek-V3 base), big-pickle, owl-alpha.

## Free cloud providers and auto-start (Conner OK 2026-10-30 10:33 ET; twins/personal use only)
- `run-service.ps1` reads keys at start from the user environment, then the
  read-only files `H:\striv\secrets\freellmapi.env` and `H:\striv\secrets\hf.env`,
  and passes them to the server in memory (`FREEAPI_CONFIG_JSON`, process only).
  Keys are stored encrypted in `C:\Users\Drex\freellmapi-data\`, never in git or logs.
- Names it looks for: GROQ_API_KEY, CEREBRAS_API_KEY, MISTRAL_API_KEY,
  OPENROUTER_API_KEY, NVIDIA_API_KEY, COHERE_API_KEY, CLOUDFLARE_ACCOUNT_ID +
  CLOUDFLARE_API_TOKEN, HF_TOKEN. Not used: Google Gemini (dropped), XAI_API_KEY
  and ANTHROPIC_API_KEY (paid).
- Hugging Face goes in as a custom endpoint (`huggingface.provider.example.json`)
  because the built-in HF catalog is China-origin only; models are pinned to
  non-China inference providers (`:cerebras`, `:groq`, ...); `novita` is blocked.
- Auto-start: `register-task.ps1` creates task "Twinward FreeLLMAPI" (at Drex
  logon +45s, hidden, restart on failure; the wrapper also restarts the server).
  Stop: `stop-service.ps1`. Logs: `C:\Users\Drex\freellmapi-data\logs\`.
