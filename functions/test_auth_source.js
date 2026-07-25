const assert = require("assert");
const fs = require("fs");
const path = require("path");

const indexSource = fs.readFileSync(path.join(__dirname, "index.js"), "utf8");
const authSource = fs.readFileSync(path.join(__dirname, "auth.js"), "utf8");
const contractSource = fs.readFileSync(path.join(__dirname, "contract.js"), "utf8");
const siweSource = fs.readFileSync(path.join(__dirname, "siwe.js"), "utf8");
const source = [indexSource, authSource, contractSource, siweSource].join("\n");
const rules = fs.readFileSync(path.join(__dirname, "..", "firestore.rules"), "utf8");

const exportedNames = [...indexSource.matchAll(/^exports\.([A-Za-z0-9_]+)\s*=/gm)]
  .map((match) => match[1])
  .sort();
assert.deepStrictEqual(exportedNames, [
  "authenticateWallet",
  "contractSmokeTest",
  "getAppConfig",
  "getRoundSettlementProofs",
  "health",
  "publishSeasonManifest",
  "registerDevice",
  "requestSiweNonce",
  "trackTransaction",
]);

function exportedFunction(name, nextName) {
  const start = indexSource.indexOf(`exports.${name} =`);
  assert.notStrictEqual(start, -1, `${name} export is missing`);
  const end = nextName ? indexSource.indexOf(`exports.${nextName} =`, start) : indexSource.length;
  assert.notStrictEqual(end, -1, `${nextName} export is missing`);
  return indexSource.slice(start, end);
}

assert(source.includes("function requireWalletUser(request)"));
assert(source.includes('claims.authProvider !== "siwe"'));
assert(source.includes("uid !== walletFirebaseUid(playerAddress)"));
assert(source.includes("createCustomToken(uid"));
assert(source.includes("walletAuthChallenges"));
assert(contractSource.includes("verifyMessage"));
assert(siweSource.includes("validateSiwe"));

const nonce = exportedFunction("requestSiweNonce", "authenticateWallet");
assert(!nonce.includes("requireUser(request)"));
assert(nonce.includes('enforceRateLimit("requestSiweNonceWallet"'));

const register = exportedFunction("registerDevice", "trackTransaction");
const tracking = exportedFunction("trackTransaction", "contractSmokeTest");
for (const handler of [register, tracking]) {
  assert(handler.includes("requireWalletUser(request)"));
}
const proofs = exportedFunction("getRoundSettlementProofs", "getAppConfig");
assert(proofs.includes("enforceAppCheck: false"));
assert(!source.includes("getPaymentStatus"));

assert(rules.includes("function verifiedWallet()"));
assert(rules.includes("request.auth.token.authProvider == 'siwe'"));

console.log("Wallet authentication source invariants verified.");
