const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue, Timestamp } = require("firebase-admin/firestore");
const { HttpsError } = require("firebase-functions/v2/https");
const { defineSecret, defineString } = require("firebase-functions/params");
const { getAddress, isAddress } = require("ethers");
const crypto = require("crypto");

initializeApp();

const db = getFirestore();

const rpcUrl = defineSecret("BASE_RPC_URL");
const recaptchaSiteKey = defineSecret("APP_CHECK_RECAPTCHA_SITE_KEY");
const vapidKey = defineSecret("APP_MESSAGING_VAPID_KEY");
const contractAddress = defineString("EASY_GAME_CONTRACT_ADDRESS");
const roundManagerAddressParam = defineString("EASY_GAME_ROUND_MANAGER_ADDRESS", { default: "" });
const roundScheduleSignerParam = defineString("EASY_GAME_ROUND_SCHEDULE_SIGNER", { default: "" });
const arenaSkillsAddressParam = defineString("EASY_GAME_ARENA_SKILLS_ADDRESS", { default: "" });
const roundSettlementAddressParam = defineString("EASY_GAME_ROUND_SETTLEMENT_ADDRESS", { default: "" });
const chainIdParam = defineString("EASY_GAME_CHAIN_ID", { default: "8453" });
const appPublicUrlParam = defineString("APP_PUBLIC_URL", { default: "https://easygame.io" });
const publicRpcUrlParam = defineString("WEB3_PUBLIC_RPC_URL", { default: "https://mainnet.base.org" });
const environmentParam = defineString("APP_ENVIRONMENT", { default: "production" });
const usdcTokenAddressParam = defineString("USDC_TOKEN_ADDRESS", { default: "" });
const easyGameInviterParam = defineString("EASY_GAME_INVITER", { default: "" });
const siweAllowedOriginsParam = defineString("SIWE_ALLOWED_ORIGINS", {
  default: "https://lottery-advance.web.app,https://lottery-advance.firebaseapp.com,https://easygame.io",
});

const region = "us-central1";
const maxDeviceTokensPerWallet = 10;
const allowedPlatforms = new Set(["web", "android", "ios", "macos", "windows", "linux"]);
const zeroAddress = "0x0000000000000000000000000000000000000000";

function hashId(value) {
  return crypto.createHash("sha256").update(String(value)).digest("hex");
}

function publicContractAddress() {
  const address = contractAddress.value();
  if (!isAddress(address)) return "";
  const normalized = getAddress(address);
  return normalized === zeroAddress ? "" : normalized;
}

function publicOptionalAddress(param) {
  const address = param.value();
  if (!address || !isAddress(address)) return "";
  const normalized = getAddress(address);
  return normalized === zeroAddress ? "" : normalized;
}

function wallet(value) {
  if (typeof value !== "string" || !isAddress(value)) return null;
  return getAddress(value).toLowerCase();
}

module.exports = {
  db,
  FieldValue,
  Timestamp,
  HttpsError,
  rpcUrl,
  recaptchaSiteKey,
  vapidKey,
  contractAddress,
  roundManagerAddressParam,
  roundScheduleSignerParam,
  arenaSkillsAddressParam,
  roundSettlementAddressParam,
  chainIdParam,
  appPublicUrlParam,
  publicRpcUrlParam,
  environmentParam,
  usdcTokenAddressParam,
  easyGameInviterParam,
  siweAllowedOriginsParam,
  region,
  maxDeviceTokensPerWallet,
  allowedPlatforms,
  zeroAddress,
  hashId,
  publicContractAddress,
  publicOptionalAddress,
  wallet,
};
