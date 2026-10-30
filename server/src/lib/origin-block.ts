// Twinward local policy: refuse to route to blocked providers or models.
//
// Two env vars, both comma-separated and empty by default (no change to
// upstream behavior when unset):
//   FREELLMAPI_BLOCKED_PLATFORMS        platform ids, exact, case-insensitive
//                                       (e.g. zhipu,modelscope)
//   FREELLMAPI_BLOCKED_MODEL_PATTERNS   case-insensitive substrings matched
//                                       against the model id
//                                       (e.g. qwen,deepseek,glm,kimi)
//
// Applied in services/router.ts (routeRequest and routePinnedModel), which is
// where every /v1, /v1/messages, /v1/responses, fusion and pinned request picks
// its upstream, so a blocked row can never be dispatched, even by an explicit
// client pin.

function parseList(raw: string | undefined): string[] {
  return (raw ?? '')
    .split(',')
    .map(s => s.trim().toLowerCase())
    .filter(s => s.length > 0);
}

let cacheKey: string | null = null;
let cachedPlatforms: Set<string> = new Set();
let cachedPatterns: string[] = [];

function load(): void {
  const p = process.env.FREELLMAPI_BLOCKED_PLATFORMS ?? '';
  const m = process.env.FREELLMAPI_BLOCKED_MODEL_PATTERNS ?? '';
  const key = p + '\u0000' + m;
  if (key === cacheKey) return;
  cacheKey = key;
  cachedPlatforms = new Set(parseList(p));
  cachedPatterns = parseList(m);
}

export function isBlockedPlatform(platform: string | null | undefined): boolean {
  load();
  return !!platform && cachedPlatforms.has(platform.toLowerCase());
}

export function isBlockedModelId(modelId: string | null | undefined): boolean {
  load();
  if (!modelId) return false;
  const low = modelId.toLowerCase();
  return cachedPatterns.some(p => low.includes(p));
}

export function isBlockedRoute(platform: string | null | undefined, modelId: string | null | undefined): boolean {
  return isBlockedPlatform(platform) || isBlockedModelId(modelId);
}