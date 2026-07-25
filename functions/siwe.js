const { getAddress, isAddress } = require("ethers");
const {
  HttpsError,
  chainIdParam,
  siweAllowedOriginsParam,
  environmentParam,
} = require("./config");

function siweField(message, name) {
  const escaped = name.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  return message.match(new RegExp(`^${escaped}:\\s*(.+)$`, "mi"))?.[1]?.trim() || "";
}

function allowedSiweOrigin(value) {
  let uri;
  try {
    uri = new URL(String(value || ""));
  } catch (_) {
    throw new HttpsError("invalid-argument", "Valid SIWE origin required");
  }
  const allowedOrigins = new Set(
    siweAllowedOriginsParam.value().split(",").map((item) => item.trim()).filter(Boolean),
  );
  const localOrigin = environmentParam.value() !== "production" &&
    (uri.hostname === "localhost" || uri.hostname === "127.0.0.1");
  if (!localOrigin && !allowedOrigins.has(uri.origin)) {
    throw new HttpsError("permission-denied", "SIWE origin is not allowed");
  }
  return uri.origin;
}

function validateSiwe({ address, message, nonce, origin }) {
  if (typeof message !== "string" || message.length < 80 || message.length > 4096) {
    throw new HttpsError("invalid-argument", "Valid SIWE message required");
  }
  if (typeof nonce !== "string" || !/^[A-Za-z0-9]{16,128}$/.test(nonce)) {
    throw new HttpsError("invalid-argument", "Valid SIWE nonce required");
  }
  if (siweField(message, "Nonce") !== nonce) {
    throw new HttpsError("permission-denied", "SIWE nonce mismatch");
  }
  if (Number(siweField(message, "Chain ID")) !== Number(chainIdParam.value())) {
    throw new HttpsError("permission-denied", "SIWE chain mismatch");
  }

  const messageAddress = message.match(/\n(0x[0-9a-fA-F]{40})\n/)?.[1] || "";
  if (!isAddress(messageAddress) || getAddress(messageAddress) !== getAddress(address)) {
    throw new HttpsError("permission-denied", "SIWE wallet mismatch");
  }

  const issuedAt = Date.parse(siweField(message, "Issued At"));
  const expirationTime = Date.parse(siweField(message, "Expiration Time"));
  const now = Date.now();
  if (!Number.isFinite(issuedAt) || issuedAt > now + 2 * 60 * 1000 || issuedAt < now - 15 * 60 * 1000) {
    throw new HttpsError("deadline-exceeded", "SIWE message expired");
  }
  if (!Number.isFinite(expirationTime) || expirationTime <= now || expirationTime > issuedAt + 15 * 60 * 1000) {
    throw new HttpsError("deadline-exceeded", "SIWE challenge expired");
  }
  if (siweField(message, "Version") !== "1") {
    throw new HttpsError("invalid-argument", "Unsupported SIWE version");
  }

  let uri;
  try {
    uri = new URL(siweField(message, "URI"));
  } catch (_) {
    throw new HttpsError("invalid-argument", "Valid SIWE URI required");
  }
  const domain = message.match(/^(.+) wants you to sign in with your Ethereum account:\s*$/m)?.[1]?.trim() || "";
  if (domain !== uri.host) {
    throw new HttpsError("permission-denied", "SIWE domain mismatch");
  }
  if (uri.origin !== allowedSiweOrigin(origin)) {
    throw new HttpsError("permission-denied", "SIWE URI mismatch");
  }
}

module.exports = {
  siweField,
  allowedSiweOrigin,
  validateSiwe,
};
