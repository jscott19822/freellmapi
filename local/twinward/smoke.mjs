// Smoke test: one /v1/chat/completions call to http://127.0.0.1:3001 using a
// local Ollama model. Prints model, routed-via header and the reply; never the key.
import { createRequire } from 'module';
const require = createRequire(process.cwd() + '/package.json');
const Database = require('better-sqlite3');
const db = new Database(process.env.SMOKE_DB, { readonly: true, fileMustExist: true });
const row = db.prepare("SELECT value FROM settings WHERE key = 'unified_api_key'").get();
db.close();
if (!row) { console.error('no unified key in DB yet (start the server once)'); process.exit(2); }
const model = process.env.SMOKE_MODEL || 'mistral:7b';
const t0 = Date.now();
const res = await fetch('http://127.0.0.1:3001/v1/chat/completions', {
  method: 'POST',
  headers: { 'content-type': 'application/json', authorization: 'Bearer ' + row.value },
  body: JSON.stringify({ model, max_tokens: 40, temperature: 0,
    messages: [{ role: 'user', content: 'Reply with exactly: router ok' }] }),
});
const body = await res.json().catch(() => ({}));
console.log(JSON.stringify({
  status: res.status, ms: Date.now() - t0, requested: model, served: body.model,
  routedVia: res.headers.get('x-routed-via'),
  reply: body.choices?.[0]?.message?.content?.trim() ?? body.error ?? null,
}));
process.exit(res.ok ? 0 : 1);