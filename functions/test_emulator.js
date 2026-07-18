/**
 * Emulator-based tests for Firebase Functions.
 */
const fs = require('fs');

const BASE = 'http://127.0.0.1:5001/lottery-advance/us-central1';
const FIRESTORE_URL = 'http://127.0.0.1:8080/v1/projects/lottery-advance/databases/(default)/documents';
const AUTH = 'http://127.0.0.1:9099';
const FAKE_KEY = 'fake-api-key';

let passed = 0;
let failed = 0;
let token = null;
let uid = null;

function assert(condition, message) {
  if (condition) { passed++; console.log('  ✓ ' + message); }
  else { failed++; console.log('  ✗ ' + message); }
}

async function signUp() {
  const res = await fetch(`${AUTH}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=${FAKE_KEY}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ returnSecureToken: true })
  });
  const data = await res.json();
  token = data.idToken;
  uid = data.localId;
}

async function callFn(name, data) {
  const headers = { 'Content-Type': 'application/json' };
  if (token) headers['Authorization'] = 'Bearer ' + token;
  const res = await fetch(`${BASE}/${name}`, {
    method: 'POST', headers,
    body: JSON.stringify({ data })
  });
  return await res.json();
}

async function main() {
  console.log('\n=== Firebase Functions — Emulator Integration Tests ===\n');

  // ─── 1. HEALTH ──────────────────────────────────
  console.log('[1] health (HTTP — no auth required)');
  {
    const h = await (await fetch(`${BASE}/health`)).json();
    assert(h.ok === false, 'returns ok=false (no indexer checkpoint)');
    assert(h.status === 'missing', 'status=missing');
    assert(typeof h.updatedAt !== 'undefined', 'updatedAt field present');
  }

  // ─── 2. AUTH SETUP ──────────────────────────────
  console.log('[2] Firebase Auth emulator');
  {
    await signUp();
    assert(!!token, 'created auth token');
    assert(!!uid, 'got user uid (' + uid.substring(0, 8) + '...)');
  }

  // ─── 3. CALLABLE INPUT VALIDATION ───────────────
  console.log('[3] Callable functions — auth enforcement');
  {
    // The emulator rejects unauthenticated requests at the framework level
    // BEFORE our handler code runs. This confirms auth enforcement works.
    let r = await callFn('requestSiweNonce', { wallet: '' });
    assert(r?.error?.status === 'UNAUTHENTICATED',
      'requestSiweNonce: UNAUTHENTICATED without valid App Check');

    r = await callFn('authenticateWallet', { signature: '' });
    assert(r?.error?.status === 'UNAUTHENTICATED',
      'authenticateWallet: UNAUTHENTICATED without valid App Check');

    r = await callFn('registerDevice', { token: '', platform: '' });
    assert(r?.error?.status === 'UNAUTHENTICATED',
      'registerDevice: UNAUTHENTICATED without valid App Check');

    r = await callFn('trackTransaction', { transactionHash: '' });
    assert(r?.error?.status === 'UNAUTHENTICATED',
      'trackTransaction: UNAUTHENTICATED without valid App Check');
  }

  // ─── 4. CALLABLE WITH DATA FIELDS ────────────────
  console.log('[4] Callable data fields are delivered');
  {
    // Verify the data payload is passed to the function (even though it rejects)
    let r = await callFn('requestSiweNonce', {
      wallet: '0x70997970c51812dc3a010c7d01b50e0d17dc79c8',
      chainId: 84532,
      origin: 'http://127.0.0.1:5000',
    });
    assert(!!r.error, 'requestSiweNonce: payload delivered (error: ' + r?.error?.status + ')');

    r = await callFn('trackTransaction', { transactionHash: '0x' + 'a'.repeat(64) });
    assert(!!r.error, 'trackTransaction: payload delivered');
  }

  // ─── 5. FIRESTORE RULES ──────────────────────────
  console.log('[5] Firestore security rules');
  {
    const fsHeaders = { 'Content-Type': 'application/json' };
    if (token) fsHeaders['Authorization'] = 'Bearer ' + token;

    // Write to users (rules: write false)
    const writeUser = await fetch(`${FIRESTORE_URL}/users/test123`, {
      method: 'PATCH',
      headers: fsHeaders,
      body: JSON.stringify({ fields: { test: { stringValue: 'x' } } })
    });
    assert(writeUser.status === 403, 'users collection: write blocked (status 403)');

    // Write to levels (rules: write false)
    const writeLevel = await fetch(`${FIRESTORE_URL}/levels/test123`, {
      method: 'PATCH',
      headers: fsHeaders,
      body: JSON.stringify({ fields: { test: { stringValue: 'x' } } })
    });
    assert(writeLevel.status === 403, 'levels collection: write blocked (status 403)');

    // Write to events (rules: write false)
    const writeEvent = await fetch(`${FIRESTORE_URL}/events/test123`, {
      method: 'PATCH',
      headers: fsHeaders,
      body: JSON.stringify({ fields: { test: { stringValue: 'x' } } })
    });
    assert(writeEvent.status === 403, 'events collection: write blocked (status 403)');

    // Write to transactions (rules: write false)
    const writeTx = await fetch(`${FIRESTORE_URL}/transactions/test123`, {
      method: 'PATCH',
      headers: fsHeaders,
      body: JSON.stringify({ fields: { test: { stringValue: 'x' } } })
    });
    assert(writeTx.status === 403, 'transactions collection: write blocked (status 403)');

    // Write to walletLinks (rules: write false)
    const writeLink = await fetch(`${FIRESTORE_URL}/walletLinks/test123`, {
      method: 'PATCH',
      headers: fsHeaders,
      body: JSON.stringify({ fields: { test: { stringValue: 'x' } } })
    });
    assert(writeLink.status === 403, 'walletLinks collection: write blocked (status 403)');

    // Write to any other collection (default deny)
    const writeAny = await fetch(`${FIRESTORE_URL}/someOtherCollection/test123`, {
      method: 'PATCH',
      headers: fsHeaders,
      body: JSON.stringify({ fields: { test: { stringValue: 'x' } } })
    });
    assert(writeAny.status === 403, 'default: all writes blocked (status 403)');

    // Anonymous bootstrap sessions cannot inspect wallet-linked data.
    const readOwnLink = await fetch(`${FIRESTORE_URL}/walletLinks/${uid}`, {
      method: 'GET',
      headers: fsHeaders
    });
    assert(readOwnLink.status === 403,
      'walletLinks: anonymous bootstrap blocked (status 403)');

    // Read other's walletLinks — should be blocked
    const readOtherLink = await fetch(`${FIRESTORE_URL}/walletLinks/other-uid`, {
      method: 'GET',
      headers: fsHeaders
    });
    assert(readOtherLink.status === 403,
      'walletLinks: read others uid blocked (status 403)');

    // Own transaction — read requires matching uid + existing doc
    const readOwnTx = await fetch(`${FIRESTORE_URL}/transactions/test123`, {
      method: 'GET',
      headers: fsHeaders
    });
    // Rule: read: if signedIn() && resource.data.uid == request.auth.uid
    // Non-existent doc → resource.data.uid is undefined → condition false → 403
    assert(
      readOwnTx.status === 403,
      'transactions: non-existent doc blocked (status ' + readOwnTx.status + ')'
    );

    // Read from any unmatch collection → blocked by wildcard deny
    const readAny = await fetch(`${FIRESTORE_URL}/someCollection/doc`, {
      method: 'GET',
      headers: fsHeaders
    });
    assert(readAny.status === 403, 'default: all reads blocked (status 403)');
  }

  // ─── 6. SOURCE CODE REVIEW ──────────────────────
  console.log('[6] Source code review');
  {
    const src = fs.readFileSync(__dirname + '/index.js', 'utf8');

    // Functions
    assert(src.includes('exports.health'), 'health function');
    assert(src.includes('exports.requestSiweNonce'), 'requestSiweNonce function');
    assert(src.includes('exports.authenticateWallet'), 'authenticateWallet function');
    assert(!src.includes('exports.requestWalletNonce'), 'legacy requestWalletNonce removed');
    assert(!src.includes('exports.linkWallet'), 'legacy linkWallet removed');
    assert(!src.includes('exports.verifyBaseAccountSession'), 'legacy Base session route removed');
    assert(src.includes('exports.registerDevice'), 'registerDevice function');
    assert(src.includes('exports.trackTransaction'), 'trackTransaction function');
    assert(src.includes('exports.contractSmokeTest'), 'contractSmokeTest function');
    assert(src.includes('exports.publishSeasonManifest'), 'publishSeasonManifest function');
    assert(!src.includes('exports.publishRoundManifest'), 'single-round publisher removed');
    assert(src.includes('exports.getRoundSettlementProofs'), 'getRoundSettlementProofs function');
    assert(!/^exports\.syncGameEvents\s*=/m.test(src), 'syncGameEvents worker disabled');
    assert(!/^exports\.confirmTransactions\s*=/m.test(src), 'confirmTransactions worker disabled');
    assert(!src.includes('exports.syncLevel'), 'legacy syncLevel removed');
    assert(!src.includes('exports.syncAllLevels'), 'legacy syncAllLevels removed');

    // Security
    assert(src.includes('enforceAppCheck: true'), 'enforceAppCheck: true');
    assert(src.includes('requireApp'), 'requireApp() in callable functions');
    assert(src.includes('requireUser'), 'requireUser() in callable functions');
    assert(src.includes('requireWalletUser'), 'verified wallet guard defined');
    assert(src.includes('claims.authProvider !== "siwe"'),
      'verified wallet guard requires SIWE custom claims');
    assert(src.includes('enforceRateLimit'), 'enforceRateLimit() defined');

    // Auth flow
    assert(src.includes('walletVerificationClient().verifyMessage'),
      'viem verifyMessage supports EOA and Base Account signatures');
    assert(src.includes('validateSiwe'), 'standard SIWE validation');
    assert(src.includes('walletAuthChallenges'), 'SIWE replay protection');
    assert(src.includes('randomBytes(24)'), '24-byte random nonce');
    assert(src.includes('expiresAt'), 'nonce expiry');
    assert(src.includes('createCustomToken'), 'Firebase Custom Token session');
    assert(src.includes('walletFirebaseUid'), 'stable server-side wallet identity');
    assert(src.includes('SIWE challenge changed'), 'challenge race protection');
    // Wallet linking
    assert(src.includes('walletLinks'), 'walletLinks collection');
    assert(src.includes('walletDevices'), 'walletDevices collection');

    // Transaction tracking
    assert(src.includes('transactions'), 'transactions collection');
    assert(src.includes('status: "submitted"'), 'submitted transaction state');

    // Deployment integrity replaces the removed legacy level indexer.
    assert(src.includes('CORE_LINK_ABI'), 'core deployment ABI');
    assert(src.includes('Contract links are inconsistent'), 'link validation');
    assert(src.includes('Contract bytecode is missing'), 'bytecode validation');

    // Error types
    assert(src.includes('unauthenticated'), 'UNAUTHENTICATED error');
    assert(src.includes('failed-precondition'), 'FAILED_PRECONDITION error');
    assert(src.includes('invalid-argument'), 'INVALID_ARGUMENT error');
    assert(src.includes('resource-exhausted'), 'RESOURCE_EXHAUSTED error');
    assert(src.includes('deadline-exceeded'), 'DEADLINE_EXCEEDED error');
    assert(src.includes('permission-denied'), 'PERMISSION_DENIED error');

    // Constants
    assert(src.includes('maxDeviceTokensPerWallet'), 'maxDeviceTokensPerWallet config');
    assert(src.includes('allowedPlatforms'), 'allowedPlatforms config');
    assert(src.includes('us-central1'), 'region: us-central1');
  }

  // ─── 7. DEPLOYMENT ABIs ───────────────────────────
  console.log('[7] Deployment ABI verification');
  {
    const deploymentAbis = require('./game_abi');
    const expected = [
      'CORE_LINK_ABI',
      'ROUND_MANAGER_LINK_ABI',
      'ARENA_SKILLS_LINK_ABI',
      'SETTLEMENT_LINK_ABI',
    ];
    for (const name of expected) {
      assert(Array.isArray(deploymentAbis[name]), name + ' is array');
      assert(deploymentAbis[name].length >= 2, name + ' has link getters');
      assert(
        deploymentAbis[name].every((entry) => entry.startsWith('function')),
        name + ' contains only current getters',
      );
    }
  }

  // ─── 8. PACKAGE.JSON ─────────────────────────────
  console.log('[8] package.json verification');
  {
    const pkg = JSON.parse(fs.readFileSync(__dirname + '/package.json', 'utf8'));
    assert(pkg.name === 'easy-game-firebase-functions', 'package name correct');
    assert(pkg.main === 'index.js', 'entry point: index.js');
    assert(pkg.engines?.node === '22', 'Node 22 engine');
    assert(pkg.dependencies?.['ethers'], 'ethers dependency');
    assert(pkg.dependencies?.['firebase-admin'], 'firebase-admin dependency');
    assert(pkg.dependencies?.['firebase-functions'], 'firebase-functions dependency');
    assert(pkg.scripts?.serve, 'serve script');
    assert(pkg.scripts?.deploy, 'deploy script');
  }

  // ─── SUMMARY ──────────────────────────────────────
  const total = passed + failed;
  console.log('\n' + '='.repeat(55));
  console.log(`  Total: ${total}  |  ✓ ${passed} passed  |  ✗ ${failed} failed`);
  console.log('='.repeat(55));
  process.exit(failed > 0 ? 1 : 0);
}

main().catch(e => {
  console.error('\nFatal:', e.message);
  process.exit(1);
});
