const fs = require("node:fs");
const path = require("node:path");
const { getAddress, isAddress } = require("ethers");

const zeroAddress = "0x0000000000000000000000000000000000000000";
const baseSepoliaUsdc = "0x036CbD53842c5426634e7929541eC2318f3dCF7e";
const requiredAddresses = [
  "EASY_GAME_CONTRACT_ADDRESS",
  "EASY_GAME_ROUND_MANAGER_ADDRESS",
  "EASY_GAME_ROUND_SCHEDULE_SIGNER",
  "EASY_GAME_ARENA_SKILLS_ADDRESS",
  "EASY_GAME_ROUND_SETTLEMENT_ADDRESS",
  "USDC_TOKEN_ADDRESS",
];

function readEnv(filePath) {
  if (!fs.existsSync(filePath)) return {};
  const values = {};
  for (const rawLine of fs.readFileSync(filePath, "utf8").split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line || line.startsWith("#")) continue;
    const separator = line.indexOf("=");
    if (separator < 1) throw new Error(`Invalid env line in ${filePath}`);
    values[line.slice(0, separator).trim()] = line.slice(separator + 1).trim();
  }
  return values;
}

function defaultProjectId() {
  const firebaseRc = path.join(__dirname, "..", ".firebaserc");
  const config = JSON.parse(fs.readFileSync(firebaseRc, "utf8"));
  return String(config.projects?.default || "").trim();
}

function assertHttpsUrl(value, name) {
  let uri;
  try {
    uri = new URL(value);
  } catch (_) {
    throw new Error(`${name} must be a valid URL`);
  }
  if (uri.protocol !== "https:") throw new Error(`${name} must use HTTPS`);
}

function validateConfig() {
  const projectId = process.env.GCLOUD_PROJECT || defaultProjectId();
  if (!projectId) throw new Error("Firebase project ID is missing");
  const values = {
    ...readEnv(path.join(__dirname, ".env")),
    ...readEnv(path.join(__dirname, `.env.${projectId}`)),
  };

  for (const name of requiredAddresses) {
    const value = values[name];
    if (!value || !isAddress(value) || getAddress(value) === zeroAddress) {
      throw new Error(`${name} must contain a non-zero EVM address`);
    }
  }

  const chainId = Number(values.EASY_GAME_CHAIN_ID);
  if (!Number.isSafeInteger(chainId) || chainId <= 0) {
    throw new Error("EASY_GAME_CHAIN_ID must be a positive integer");
  }
  assertHttpsUrl(values.APP_PUBLIC_URL, "APP_PUBLIC_URL");
  assertHttpsUrl(values.WEB3_PUBLIC_RPC_URL, "WEB3_PUBLIC_RPC_URL");

  const origins = String(values.SIWE_ALLOWED_ORIGINS || "")
    .split(",")
    .map((value) => value.trim())
    .filter(Boolean);
  if (!origins.includes(new URL(values.APP_PUBLIC_URL).origin)) {
    throw new Error("SIWE_ALLOWED_ORIGINS must include APP_PUBLIC_URL");
  }
  origins.forEach((origin) => assertHttpsUrl(origin, "SIWE_ALLOWED_ORIGINS"));

  if (
    chainId === 84532 &&
    getAddress(values.USDC_TOKEN_ADDRESS) !== getAddress(baseSepoliaUsdc)
  ) {
    throw new Error("Base Sepolia must use the configured official USDC address");
  }

  console.log(`Firebase Functions config verified for ${projectId} on chain ${chainId}.`);
}

validateConfig();
