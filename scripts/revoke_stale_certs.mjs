// Pre-archive cleanup: revoke stale CI-minted development certificates so the
// account never hits Apple's "maximum number of certificates" cap.
//
// Cloud signing mints one fresh "Apple Development: Created via API" cert on
// every release run and never cleans it up, so the count climbs until the
// archive fails. Each run only needs one, so we revoke all pre-existing
// API-created DEVELOPMENT certs here; the archive step re-mints one into the
// freed space via -allowProvisioningUpdates.
//
// SAFETY: only DEVELOPMENT certs whose name contains "Created via API" are ever
// touched. Distribution certs (needed to export/upload) and any named person's
// development cert (e.g. "iOS Development: Jane Doe") are never revoked.
//
// NON-FATAL: any failure here prints a warning and exits 0. If the account was
// genuinely at the cap and cleanup couldn't run, the Archive step surfaces the
// real error — this step never blocks a release on its own.
//
// Env: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_FILEPATH (path to the .p8).
import crypto from 'node:crypto';
import fs from 'node:fs';

const KEY_ID = process.env.ASC_KEY_ID;
const ISSUER = process.env.ASC_ISSUER_ID;
const P8_PATH = process.env.ASC_KEY_FILEPATH;

function warnExit(msg) {
  console.log(`::warning::cert cleanup skipped: ${msg}`);
  process.exit(0); // never fail the release on cleanup
}

if (!KEY_ID || !ISSUER || !P8_PATH) warnExit('missing ASC_KEY_ID / ASC_ISSUER_ID / ASC_KEY_FILEPATH');

function jwt() {
  const now = Math.floor(Date.now() / 1000);
  const b64 = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
  const head = b64({ alg: 'ES256', kid: KEY_ID, typ: 'JWT' });
  const body = b64({ iss: ISSUER, iat: now, exp: now + 600, aud: 'appstoreconnect-v1' });
  const sig = crypto
    .sign('sha256', Buffer.from(`${head}.${body}`), {
      key: fs.readFileSync(P8_PATH, 'utf8'),
      dsaEncoding: 'ieee-p1363', // ASC requires the raw R||S signature, not DER
    })
    .toString('base64url');
  return `${head}.${body}.${sig}`;
}

async function api(method, path) {
  const res = await fetch(`https://api.appstoreconnect.apple.com${path}`, {
    method,
    headers: { Authorization: `Bearer ${jwt()}` },
  });
  const text = await res.text();
  return { status: res.status, body: text ? JSON.parse(text) : null };
}

const list = await api('GET', '/v1/certificates?limit=200');
if (list.status !== 200) warnExit(`list failed (HTTP ${list.status})`);

// Only ephemeral CI development certs. Distribution and named-person certs excluded.
const stale = list.body.data.filter(
  (c) => c.attributes.certificateType === 'DEVELOPMENT' && (c.attributes.name || '').includes('Created via API'),
);

console.log(`Found ${list.body.data.length} certs; ${stale.length} stale CI development certs to revoke.`);

let revoked = 0;
for (const c of stale) {
  const r = await api('DELETE', `/v1/certificates/${c.id}`);
  if (r.status === 204) {
    revoked++;
    console.log(`revoked ${c.id} (${c.attributes.name})`);
  } else {
    console.log(`::warning::could not revoke ${c.id} (HTTP ${r.status})`);
  }
}
console.log(`Revoked ${revoked}/${stale.length}; distribution and named certs untouched.`);
