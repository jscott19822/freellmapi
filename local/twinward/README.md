# Twinward local setup (OVERKILL)

Local-only FreeLLMAPI for Selah and Thaylor. Branch `twinward/local-ollama`.

- Binds to 127.0.0.1:3001 (`HOST`, `ALLOWED_HOSTS=localhost`). No customer traffic, no LAN.
- Routes to local Ollama at http://127.0.0.1:11434/v1 as a custom provider
  (mistral:7b, gemma3:12b, phi4, hermes3), strategy `priority`.
- No keys in the repo. The unified key and any provider keys live encrypted in
  `C:\Users\Drex\freellmapi-data\` (outside the repo). Free-cloud keys, if
  Conner OKs them later, go in through the dashboard, never in git.
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
