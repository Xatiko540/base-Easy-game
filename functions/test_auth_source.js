const assert = require("assert");
const fs = require("fs");
const path = require("path");

const source = fs.readFileSync(path.join(__dirname, "index.js"), "utf8");
const rules = fs.readFileSync(path.join(__dirname, "..", "firestore.rules"), "utf8");

function exportedFunction(name, nextName) {
  const start = source.indexOf(`exports.${name} =`);
  assert.notStrictEqual(start, -1, `${name} export is missing`);
  const end = nextName ? source.indexOf(`exports.${nextName} =`, start) : source.length;
  assert.notStrictEqual(end, -1, `${nextName} export is missing`);
  return source.slice(start, end);
}

assert(source.includes("function requireWalletUser(request)"));
assert(source.includes('claims.authProvider !== "siwe"'));
assert(source.includes("uid !== walletFirebaseUid(playerAddress)"));
assert(source.includes("createCustomToken(uid"));
assert(source.includes("walletAuthChallenges"));

const nonce = exportedFunction("requestSiweNonce", "authenticateWallet");
assert(nonce.includes("requireUser(request)"));
assert(!nonce.includes("requireWalletUser(request)"));

const register = exportedFunction("registerDevice", "trackTransaction");
const tracking = exportedFunction("trackTransaction", "contractSmokeTest");
for (const handler of [register, tracking]) {
  assert(handler.includes("requireWalletUser(request)"));
}
assert(!source.includes("getPaymentStatus"));

assert(rules.includes("function verifiedWallet()"));
assert(rules.includes("request.auth.token.authProvider == 'siwe'"));

console.log("Wallet authentication source invariants verified.");
