// Sube seed/seed.json a Firestore (proyecto nullcoremaps).
//
// Usa la sesión de `firebase login` de esta computadora: las escrituras se
// hacen como el dueño del proyecto (por IAM), así que no dependen de las
// reglas de seguridad ni de que exista un admin todavía.
//
// Uso:
//   node tool/seed_firestore.mjs            (sube todo)
//   node tool/seed_firestore.mjs --dry-run  (solo muestra qué subiría)
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const PROJECT = 'nullcoremaps';
const DRY = process.argv.includes('--dry-run');
const seedPath = path.join(path.dirname(new URL(import.meta.url).pathname.replace(/^\/(\w:)/, '$1')), '..', 'seed', 'seed.json');
const seed = JSON.parse(fs.readFileSync(seedPath, 'utf8'));

// Credenciales públicas del cliente OAuth de firebase-tools (las mismas que usa el CLI).
const CLIENT_ID = '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com';
const CLIENT_SECRET = 'j9iVZfS8kkCEFUPaAeJV0sAi';

async function accessToken() {
  const cfg = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
  const refresh = JSON.parse(fs.readFileSync(cfg, 'utf8'))?.tokens?.refresh_token;
  if (!refresh) throw new Error('No hay sesión de Firebase: corre `firebase login` primero.');
  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ client_id: CLIENT_ID, client_secret: CLIENT_SECRET, refresh_token: refresh, grant_type: 'refresh_token' }),
  });
  const json = await res.json();
  if (!json.access_token) throw new Error('No se pudo obtener el token: ' + JSON.stringify(json));
  return json.access_token;
}

// JSON -> formato de valores de Firestore REST.
function enc(v) {
  if (v === null || v === undefined) return { nullValue: null };
  if (typeof v === 'string') return { stringValue: v };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(enc) } };
  return { mapValue: { fields: Object.fromEntries(Object.entries(v).map(([k, x]) => [k, enc(x)])) } };
}

const docs = [];
const now = new Date().toISOString();
for (const t of seed.teachers) docs.push([`teachers/${t.id}`, { ...t, updatedAt: now }]);
for (const [loc, data] of Object.entries(seed.schedules)) docs.push([`schedules/${loc}`, { ...data, updatedAt: now }]);
for (const [loc, data] of Object.entries(seed.labStaff)) docs.push([`labStaff/${loc}`, { ...data, updatedAt: now }]);
for (const [id, data] of Object.entries(seed.guides ?? {})) docs.push([`guides/${id}`, { ...data, updatedAt: now }]);
for (const [id, data] of Object.entries(seed.map ?? {})) docs.push([`map/${id}`, { ...data, updatedAt: now }]);

console.log(`${docs.length} documentos:`);
for (const [p] of docs) console.log('  ' + p);
if (DRY) process.exit(0);

const token = await accessToken();
const base = `projects/${PROJECT}/databases/(default)/documents`;
const res = await fetch(`https://firestore.googleapis.com/v1/${base}:commit`, {
  method: 'POST',
  headers: { authorization: `Bearer ${token}`, 'content-type': 'application/json' },
  body: JSON.stringify({
    writes: docs.map(([p, data]) => ({ update: { name: `${base}/${p}`, fields: enc(data).mapValue.fields } })),
  }),
});
const out = await res.json();
if (!res.ok) {
  console.error('Error al subir:', JSON.stringify(out, null, 2));
  process.exit(1);
}
console.log(`Listo: ${out.writeResults?.length ?? 0} documentos escritos.`);
