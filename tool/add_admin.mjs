// Registra (o quita) administradores de NullCoreMaps en Firestore: admins/{correo}.
//
// Usa la sesión de `firebase login` de esta computadora (como dueño del
// proyecto), así que funciona aunque todavía no exista ningún admin.
//
// Uso:
//   node tool/add_admin.mjs correo@upjr.edu.mx "Nombre"     (agrega)
//   node tool/add_admin.mjs --remove correo@upjr.edu.mx       (quita)
//   node tool/add_admin.mjs --list                           (lista)
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const PROJECT = 'nullcoremaps';
const CLIENT_ID = '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com';
const CLIENT_SECRET = 'j9iVZfS8kkCEFUPaAeJV0sAi';
const base = `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents/admins`;

async function token() {
  const cfg = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
  const refresh = JSON.parse(fs.readFileSync(cfg, 'utf8'))?.tokens?.refresh_token;
  if (!refresh) throw new Error('No hay sesión de Firebase: corre `firebase login` primero.');
  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ client_id: CLIENT_ID, client_secret: CLIENT_SECRET, refresh_token: refresh, grant_type: 'refresh_token' }),
  });
  return (await res.json()).access_token;
}

const args = process.argv.slice(2);
const auth = { authorization: `Bearer ${await token()}` };

if (args[0] === '--list') {
  const res = await (await fetch(base, { headers: auth })).json();
  const docs = res.documents ?? [];
  console.log(docs.length ? docs.map((d) => '  ' + d.name.split('/').pop()).join('\n') : '(sin admins)');
} else if (args[0] === '--remove') {
  const email = (args[1] ?? '').toLowerCase();
  const res = await fetch(`${base}/${encodeURIComponent(email)}`, { method: 'DELETE', headers: auth });
  console.log(res.ok ? `Quitado: ${email}` : `Error: ${res.status} ${await res.text()}`);
} else {
  const email = (args[0] ?? '').toLowerCase();
  if (!email.endsWith('@upjr.edu.mx')) {
    console.error('El correo debe ser @upjr.edu.mx');
    process.exit(1);
  }
  const res = await fetch(`${base}/${encodeURIComponent(email)}`, {
    method: 'PATCH',
    headers: { ...auth, 'content-type': 'application/json' },
    body: JSON.stringify({ fields: { nombre: { stringValue: args[1] ?? '' }, desde: { timestampValue: new Date().toISOString() } } }),
  });
  console.log(res.ok ? `Admin agregado: ${email}` : `Error: ${res.status} ${await res.text()}`);
}
