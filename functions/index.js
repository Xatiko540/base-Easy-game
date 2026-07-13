const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue, Timestamp } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { onCall, onRequest, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { defineSecret, defineString } = require("firebase-functions/params");
const { logger } = require("firebase-functions");
const {
  Contract,
  Interface,
  JsonRpcProvider,
  Wallet,
  TypedDataEncoder,
  getAddress,
  isAddress,
  parseUnits,
  verifyTypedData,
} = require("ethers");
const {
  createPublicClient,
  defineChain,
  getAddress: getViemAddress,
  http,
} = require("viem");
const { getPaymentStatus } = require("@base-org/account");
const crypto = require("crypto");
const { GAME_ABI } = require("./game_abi");
const { buildWinningCellTree } = require("./round_merkle");

initializeApp();

const db = getFirestore();
const rpcUrl = defineSecret("BASE_RPC_URL");
const recaptchaSiteKey = defineSecret("APP_CHECK_RECAPTCHA_SITE_KEY");
const vapidKey = defineSecret("APP_MESSAGING_VAPID_KEY");
const contractAddress = defineString("EASY_GAME_CONTRACT_ADDRESS");
const roundManagerAddressParam = defineString("EASY_GAME_ROUND_MANAGER_ADDRESS", {
  default: "",
});
const roundScheduleSignerParam = defineString("EASY_GAME_ROUND_SCHEDULE_SIGNER", {
  default: "",
});
const arenaSkillsAddressParam = defineString("EASY_GAME_ARENA_SKILLS_ADDRESS", {
  default: "",
});
const roundSettlementAddressParam = defineString("EASY_GAME_ROUND_SETTLEMENT_ADDRESS", {
  default: "",
});
const basePayGatewayAddressParam = defineString("EASY_GAME_BASE_PAY_GATEWAY_ADDRESS", {
  default: "",
});
const basePayFulfillerKey = defineSecret("BASE_PAY_FULFILLER_PRIVATE_KEY");
const chainIdParam = defineString("EASY_GAME_CHAIN_ID", { default: "8453" });
const confirmationsParam = defineString("EASY_GAME_CONFIRMATIONS", { default: "5" });
const startBlockParam = defineString("EASY_GAME_START_BLOCK", { default: "0" });
const appPublicUrlParam = defineString("APP_PUBLIC_URL", { default: "https://easygame.io" });
const publicRpcUrlParam = defineString("WEB3_PUBLIC_RPC_URL", { default: "https://mainnet.base.org" });
const environmentParam = defineString("APP_ENVIRONMENT", { default: "production" });
const usdcTokenAddressParam = defineString("USDC_TOKEN_ADDRESS", { default: "" });
const easyGameInviterParam = defineString("EASY_GAME_INVITER", { default: "" });
const paymentReceiverParam = defineString("PAYMENT_RECEIVER", { default: "" });
const baseBuilderDataSuffixParam = defineString("BASE_BUILDER_DATA_SUFFIX", {
  default: "0x62635f68336c356a6c69790b0080218021802180218021802180218021",
});
const allowLocalChainsParam = defineString("EASY_GAME_ALLOW_LOCAL_CHAINS", { default: "false" });
const baseAccountAppNameParam = defineString("BASE_ACCOUNT_APP_NAME", { default: "Easy Game" });
const baseAccountAppLogoUrlParam = defineString("BASE_ACCOUNT_APP_LOGO_URL", { default: "" });
const region = "us-central1";
const iface = new Interface(GAME_ABI);
const maxDeviceTokensPerWallet = 10;
const allowedPlatforms = new Set(["web", "android", "ios", "macos", "windows", "linux"]);
const zeroAddress = "0x0000000000000000000000000000000000000000";
const roundTypes = {
  RoundConfig: [
    { name: "seasonId", type: "uint256" },
    { name: "roundId", type: "uint256" },
    { name: "level", type: "uint8" },
    { name: "startsAt", type: "uint64" },
    { name: "entriesCloseAt", type: "uint64" },
    { name: "endsAt", type: "uint64" },
    { name: "freezeClosesAt", type: "uint64" },
    { name: "maxPlayers", type: "uint32" },
    { name: "maxWinners", type: "uint16" },
    { name: "winningCellsRoot", type: "bytes32" },
    { name: "ethPrice", type: "uint256" },
    { name: "usdcPrice", type: "uint256" },
    { name: "freezeLimit", type: "uint16" },
    { name: "paymentSplitVersion", type: "uint16" },
  ],
};
const basePayGatewayAbi = [
  "function fulfillRound(bytes32 paymentId,(uint256 seasonId,uint256 roundId,uint8 level,uint64 startsAt,uint64 entriesCloseAt,uint64 endsAt,uint64 freezeClosesAt,uint32 maxPlayers,uint16 maxWinners,bytes32 winningCellsRoot,uint256 ethPrice,uint256 usdcPrice,uint16 freezeLimit,uint16 paymentSplitVersion) config,bytes signature,address player,address inviter)",
  "function processedPayments(bytes32 paymentId) view returns (bool)",
  "function fulfiller() view returns (address)",
];

function walletVerificationClient() {
  const chainId = Number(chainIdParam.value());
  const endpoint = rpcUrl.value();
  const chain = defineChain({
    id: chainId,
    name: chainId === 84532 ? "Base Sepolia" : chainId === 8453 ? "Base" : `Chain ${chainId}`,
    nativeCurrency: { name: "Ether", symbol: "ETH", decimals: 18 },
    rpcUrls: { default: { http: [endpoint] } },
  });
  return createPublicClient({ chain, transport: http(endpoint) });
}

async function verifyWalletSignature(address, message, signature) {
  try {
    return await walletVerificationClient().verifyMessage({
      address: getViemAddress(address),
      message,
      signature,
    });
  } catch (error) {
    logger.warn("Wallet signature verification failed", {
      wallet: address,
      error: String(error?.message || error).slice(0, 300),
    });
    return false;
  }
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

function runtime() {
  const address = contractAddress.value();
  if (!isAddress(address) || getAddress(address) === zeroAddress) {
    throw new Error("EASY_GAME_CONTRACT_ADDRESS is invalid or not configured");
  }
  const provider = new JsonRpcProvider(rpcUrl.value(), Number(chainIdParam.value()));
  return {
    provider,
    contract: new Contract(address, GAME_ABI, provider),
    address: getAddress(address),
    chainId: Number(chainIdParam.value()),
  };
}

function wallet(value) {
  if (typeof value !== "string" || !isAddress(value)) return null;
  return getAddress(value).toLowerCase();
}

function jsonValue(value) {
  if (typeof value === "bigint") return value.toString();
  if (Array.isArray(value)) return value.map(jsonValue);
  if (value && typeof value === "object") {
    const result = {};
    for (const [key, item] of Object.entries(value)) {
      if (!/^\d+$/.test(key)) result[key] = jsonValue(item);
    }
    return result;
  }
  return value;
}

function roundConfigFromDocument(round) {
  const source = round.get("config");
  const timestampSeconds = (name) => {
    const value = source?.[name];
    if (!(value instanceof Timestamp)) {
      throw new HttpsError("failed-precondition", `Round ${name} is invalid`);
    }
    return BigInt(Math.floor(value.toMillis() / 1000));
  };
  const integer = (name, alias = name) => {
    try {
      return BigInt(source?.[alias]);
    } catch (_) {
      throw new HttpsError("failed-precondition", `Round ${name} is invalid`);
    }
  };
  return {
    seasonId: integer("seasonId"),
    roundId: integer("roundId"),
    level: integer("level"),
    startsAt: timestampSeconds("startsAt"),
    entriesCloseAt: timestampSeconds("entriesCloseAt"),
    endsAt: timestampSeconds("endsAt"),
    freezeClosesAt: timestampSeconds("freezeClosesAt"),
    maxPlayers: integer("maxPlayers"),
    maxWinners: integer("maxWinners"),
    winningCellsRoot: String(source?.winningCellsRoot || ""),
    ethPrice: integer("ethPrice", "ethPriceWei"),
    usdcPrice: integer("usdcPrice"),
    freezeLimit: integer("freezeLimit"),
    paymentSplitVersion: integer("paymentSplitVersion"),
  };
}

function requireUser(request) {
  if (!request.auth) throw new HttpsError("unauthenticated", "Anonymous Firebase session required");
  return request.auth.uid;
}

function requireApp(request) {
  if (environmentParam.value() === "local") return;
  if (!request.app) throw new HttpsError("failed-precondition", "Firebase App Check required");
}

function hashId(value) {
  return crypto.createHash("sha256").update(String(value)).digest("hex");
}

async function enforceRateLimit(name, subject, max, windowSeconds) {
  const nowMs = Date.now();
  const ref = db.collection("rateLimits").doc(hashId(`${name}:${subject}`));
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref);
    const data = snapshot.exists ? snapshot.data() : null;
    const resetAtMs = data?.resetAt?.toMillis?.() || 0;
    const currentCount = resetAtMs > nowMs ? Number(data.count || 0) : 0;
    if (currentCount >= max) {
      throw new HttpsError("resource-exhausted", "Too many requests. Please try again later.");
    }
    transaction.set(ref, {
      name,
      subjectHash: hashId(subject),
      count: currentCount + 1,
      max,
      windowSeconds,
      resetAt: Timestamp.fromMillis(resetAtMs > nowMs ? resetAtMs : nowMs + windowSeconds * 1000),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  });
}

function eventId(chainId, log) {
  return `${chainId}_${log.transactionHash}_${log.index}`;
}

function eventWallets(name, args) {
  const candidates = [];
  for (const key of ["player", "winner", "inviter", "invitee"]) {
    const normalized = wallet(args[key]);
    if (normalized) candidates.push(normalized);
  }
  return [...new Set(candidates)];
}

async function pushToWallet(walletAddress, title, body, data = {}) {
  const snapshot = await db.collection("walletDevices").doc(walletAddress).collection("tokens").limit(20).get();
  const tokens = snapshot.docs.map((doc) => doc.get("token")).filter(Boolean);
  if (tokens.length === 0) return;
  const response = await getMessaging().sendEachForMulticast({
    tokens,
    notification: { title, body },
    data: Object.fromEntries(Object.entries(data).map(([key, value]) => [key, String(value)])),
  });
  const invalid = [];
  response.responses.forEach((item, index) => {
    if (!item.success && ["messaging/invalid-registration-token", "messaging/registration-token-not-registered"].includes(item.error?.code)) {
      invalid.push(snapshot.docs[index].ref.delete());
    }
  });
  await Promise.all(invalid);
}

async function projectEvent(parsed, log, block, chainId) {
  const name = parsed.name;
  const args = jsonValue(parsed.args.toObject());
  const id = eventId(chainId, log);
  const ref = db.collection("events").doc(id);
  if ((await ref.get()).exists) return;

  const batch = db.batch();
  batch.create(ref, {
    chainId,
    contract: log.address.toLowerCase(),
    type: name,
    args,
    blockNumber: log.blockNumber,
    blockHash: log.blockHash,
    transactionHash: log.transactionHash,
    logIndex: log.index,
    blockTimestamp: Timestamp.fromMillis(Number(block.timestamp) * 1000),
    indexedAt: FieldValue.serverTimestamp(),
  });

  const player = wallet(args.player || args.winner || args.inviter);
  const level = args.level == null ? null : Number(args.level);
  if (player) {
    batch.set(db.collection("users").doc(`${chainId}_${player}`), {
      wallet: player,
      chainId,
      exists: true,
      lastEventType: name,
      lastEventBlock: log.blockNumber,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  }
  if (player && level) {
    batch.set(db.collection("users").doc(`${chainId}_${player}`).collection("levels").doc(String(level)), {
      level,
      lastEventType: name,
      lastEventBlock: log.blockNumber,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  }
  if (level) {
    batch.set(db.collection("levels").doc(`${chainId}_${level}`), {
      chainId,
      level,
      lastEventType: name,
      lastEventBlock: log.blockNumber,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  }
  await batch.commit();

  const title = name.replace(/([A-Z])/g, " $1").trim();
  for (const target of eventWallets(name, args)) {
    await pushToWallet(target, title, `Easy Game event on level ${level || "-"}`, {
      eventId: id,
      type: name,
      level: level || "",
      transactionHash: log.transactionHash,
    });
  }
}

async function reconcilePlayer(contract, chainId, playerAddress, levels) {
  const player = jsonValue(await contract.getPlayer(playerAddress));
  const userRef = db.collection("users").doc(`${chainId}_${playerAddress}`);
  await userRef.set({ ...player, wallet: playerAddress, chainId, syncedAt: FieldValue.serverTimestamp() }, { merge: true });
  for (const level of levels.slice(0, 17)) {
    const [state, tokenRewards] = await Promise.all([
      contract.getPlayerLevelFull(playerAddress, level),
      contract.getPlayerTokenRewards(playerAddress, level),
    ]);
    await userRef.collection("levels").doc(String(level)).set({
      ...jsonValue(state),
      tokenRewards: jsonValue(tokenRewards),
      level,
      syncedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  }
}

async function reconcileLevel(contract, chainId, level) {
  const [stats, usdcStats, ethPrice, usdcPrice, available] = await Promise.all([
    contract.getLevelStats(level),
    contract.getLevelStatsUSDC(level),
    contract.levelPrices(level),
    contract.levelPricesUsdc(level),
    contract.levelAvailable(level),
  ]);
  await db.collection("levels").doc(`${chainId}_${level}`).set({
    chainId,
    level,
    available,
    ethPriceWei: ethPrice.toString(),
    usdcPrice: usdcPrice.toString(),
    stats: jsonValue(stats),
    usdcStats: jsonValue(usdcStats),
    syncedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
}

async function runIndexer() {
  const { provider, contract, address, chainId } = runtime();
  const checkpointRef = db.collection("system").doc(`indexer_${chainId}`);
  const checkpoint = await checkpointRef.get();
  const latest = await provider.getBlockNumber();
  const safeHead = Math.max(0, latest - Number(confirmationsParam.value()));
  const previous = checkpoint.exists ? Number(checkpoint.get("lastProcessedBlock")) : Number(startBlockParam.value()) - 1;
  if (safeHead <= previous) return { processed: 0, from: previous + 1, to: safeHead };

  const fromBlock = previous + 1;
  const toBlock = Math.min(safeHead, fromBlock + 499);
  const logs = await provider.getLogs({ address, fromBlock, toBlock });
  const blocks = new Map();
  const affectedPlayers = new Map();
  const affectedLevels = new Set();
  let processed = 0;

  for (const log of logs) {
    let parsed;
    try { parsed = iface.parseLog(log); } catch (_) { continue; }
    let block = blocks.get(log.blockNumber);
    if (!block) {
      block = await provider.getBlock(log.blockNumber);
      blocks.set(log.blockNumber, block);
    }
    await projectEvent(parsed, log, block, chainId);
    processed++;
    const args = parsed.args.toObject();
    const level = args.level == null ? null : Number(args.level);
    if (level) affectedLevels.add(level);
    for (const target of eventWallets(parsed.name, args)) {
      if (!affectedPlayers.has(target)) affectedPlayers.set(target, new Set());
      if (level) affectedPlayers.get(target).add(level);
    }
  }

  for (const level of [...affectedLevels].slice(0, 17)) await reconcileLevel(contract, chainId, level);
  for (const [playerAddress, levels] of [...affectedPlayers.entries()].slice(0, 20)) {
    await reconcilePlayer(contract, chainId, playerAddress, [...levels]);
  }

  const lastBlock = await provider.getBlock(toBlock);
  await checkpointRef.set({
    chainId,
    contract: address.toLowerCase(),
    lastProcessedBlock: toBlock,
    lastProcessedHash: lastBlock.hash,
    safeHead,
    latest,
    processed,
    status: "healthy",
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  return { processed, from: fromBlock, to: toBlock };
}

// NOTE: BASE_RPC_URL secret updated to sepolia.base.org (v2) — redeploy enforced
// TODO: enable when contract is deployed with real address
// exports.syncGameEvents = onSchedule({
//   schedule: "every 1 minutes",
//   region,
//   timeoutSeconds: 120,
//   memory: "256MiB",
//   maxInstances: 1,
//   secrets: [rpcUrl],
// }, async () => {
//   try {
//     logger.info("Indexer completed", await runIndexer());
//   } catch (error) {
//     logger.error("Indexer failed", error);
//     throw error;
//   }
// });

exports.requestWalletNonce = onCall({ region, enforceAppCheck: true }, async (request) => {
  requireApp(request);
  const uid = requireUser(request);
  await enforceRateLimit("requestWalletNonce", uid, 5, 60);
  const playerAddress = wallet(request.data?.wallet);
  if (!playerAddress) throw new HttpsError("invalid-argument", "Valid wallet required");
  await enforceRateLimit("requestWalletNonceWallet", playerAddress, 20, 60 * 60);
  const nonce = crypto.randomBytes(24).toString("hex");
  const expiresAt = Timestamp.fromMillis(Date.now() + 10 * 60 * 1000);
  const message = [
    "Easy Game wallet verification",
    `Wallet: ${playerAddress}`,
    `Chain ID: ${chainIdParam.value()}`,
    `Firebase UID: ${uid}`,
    `Nonce: ${nonce}`,
    `Expires: ${expiresAt.toDate().toISOString()}`,
  ].join("\n");
  await db.collection("walletNonces").doc(uid).set({ uid, wallet: playerAddress, nonce, message, expiresAt, used: false });
  return { message, expiresAt: expiresAt.toMillis() };
});

exports.linkWallet = onCall({
  region,
  enforceAppCheck: true,
  secrets: [rpcUrl],
}, async (request) => {
  requireApp(request);
  const uid = requireUser(request);
  await enforceRateLimit("linkWallet", uid, 10, 10 * 60);
  const signature = request.data?.signature;
  if (typeof signature !== "string" || signature.length < 20 || signature.length > 1024) {
    throw new HttpsError("invalid-argument", "Valid wallet signature required");
  }
  const nonceDoc = await db.collection("walletNonces").doc(uid).get();
  if (!nonceDoc.exists) throw new HttpsError("failed-precondition", "Request nonce first");
  const nonce = nonceDoc.data();
  if (nonce.used || nonce.expiresAt.toMillis() < Date.now()) throw new HttpsError("deadline-exceeded", "Nonce expired");
  const verified = await verifyWalletSignature(
    nonce.wallet,
    nonce.message,
    signature,
  );
  if (!verified) {
    throw new HttpsError("invalid-argument", "Invalid wallet signature");
  }
  const recovered = nonce.wallet;
  await db.runTransaction(async (transaction) => {
    const freshNonceDoc = await transaction.get(nonceDoc.ref);
    if (!freshNonceDoc.exists) throw new HttpsError("failed-precondition", "Request nonce first");
    const freshNonce = freshNonceDoc.data();
    if (freshNonce.used || freshNonce.expiresAt.toMillis() < Date.now()) {
      throw new HttpsError("deadline-exceeded", "Nonce expired");
    }
    if (freshNonce.wallet !== recovered || freshNonce.message !== nonce.message) {
      throw new HttpsError("permission-denied", "Nonce no longer matches wallet");
    }
    transaction.set(db.collection("walletLinks").doc(uid), {
      uid,
      wallet: recovered,
      chainId: Number(chainIdParam.value()),
      verifiedAt: FieldValue.serverTimestamp(),
    });
    transaction.set(
      db.collection("users").doc(`${chainIdParam.value()}_${recovered}`),
      {
        wallet: recovered,
        chainId: Number(chainIdParam.value()),
        exists: true,
        walletVerified: true,
        profileVersion: 1,
        registeredAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    transaction.update(nonceDoc.ref, { used: true, usedAt: FieldValue.serverTimestamp() });
  });
  return { wallet: recovered, verified: true };
});

exports.registerDevice = onCall({ region, enforceAppCheck: true }, async (request) => {
  requireApp(request);
  const uid = requireUser(request);
  await enforceRateLimit("registerDevice", uid, 10, 60 * 60);
  const link = await db.collection("walletLinks").doc(uid).get();
  if (!link.exists) throw new HttpsError("failed-precondition", "Link wallet first");
  const token = request.data?.token;
  if (typeof token !== "string" || token.length < 20 || token.length > 4096 || !/^[A-Za-z0-9_:\-]+$/.test(token)) {
    throw new HttpsError("invalid-argument", "Valid FCM token required");
  }
  const platform = String(request.data?.platform || "unknown").toLowerCase();
  if (!allowedPlatforms.has(platform)) throw new HttpsError("invalid-argument", "Valid platform required");
  const tokenId = crypto.createHash("sha256").update(token).digest("hex");
  const tokensRef = db.collection("walletDevices").doc(link.get("wallet")).collection("tokens");
  await tokensRef.doc(tokenId).set({
    token,
    uid,
    platform,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  const tokenSnapshot = await tokensRef.orderBy("updatedAt", "desc").limit(maxDeviceTokensPerWallet + 10).get();
  const staleDeletes = tokenSnapshot.docs
    .slice(maxDeviceTokensPerWallet)
    .map((doc) => doc.ref.delete());
  await Promise.all(staleDeletes);
  return { registered: true };
});

exports.trackTransaction = onCall({ region, enforceAppCheck: true }, async (request) => {
  requireApp(request);
  const uid = requireUser(request);
  await enforceRateLimit("trackTransaction", uid, 20, 60 * 60);
  const hash = request.data?.transactionHash;
  if (typeof hash !== "string" || !/^0x[0-9a-fA-F]{64}$/.test(hash)) throw new HttpsError("invalid-argument", "Valid transaction hash required");
  const link = await db.collection("walletLinks").doc(uid).get();
  if (!link.exists) throw new HttpsError("failed-precondition", "Link wallet first");
  await db.collection("transactions").doc(`${chainIdParam.value()}_${hash.toLowerCase()}`).set({
    chainId: Number(chainIdParam.value()),
    transactionHash: hash.toLowerCase(),
    uid,
    wallet: link.get("wallet"),
    status: "submitted",
    createdAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  return { tracked: true };
});

exports.syncLevel = onCall({ region, enforceAppCheck: true, secrets: [rpcUrl] }, async (request) => {
  requireApp(request);
  const uid = requireUser(request);
  await enforceRateLimit("syncLevel", uid, 30, 60 * 60);
  const level = Number(request.data?.level);
  if (level < 1 || level > 17) throw new HttpsError("invalid-argument", "Level must be 1-17");

  const { contract, chainId } = runtime();
  const [stats, usdcStats, ethPrice, usdcPrice, available] = await Promise.all([
    contract.getLevelStats(level),
    contract.getLevelStatsUSDC(level),
    contract.levelPrices(level),
    contract.levelPricesUsdc(level),
    contract.levelAvailable(level),
  ]);
  const doc = {
    chainId,
    level,
    available,
    ethPriceWei: ethPrice.toString(),
    usdcPrice: usdcPrice.toString(),
    stats: jsonValue(stats),
    usdcStats: jsonValue(usdcStats),
    syncedAt: FieldValue.serverTimestamp(),
  };
  await db.collection("levels").doc(`${chainId}_${level}`).set(doc, { merge: true });
  return { level, synced: true, ...doc };
});

exports.syncAllLevels = onCall({
  region,
  enforceAppCheck: true,
  timeoutSeconds: 120,
  secrets: [rpcUrl],
}, async (request) => {
  requireApp(request);
  const uid = requireUser(request);
  await enforceRateLimit("syncAllLevels", uid, 5, 60 * 60);

  const { contract, chainId } = runtime();
  const results = [];
  for (let level = 1; level <= 17; level++) {
    const [stats, usdcStats, ethPrice, usdcPrice, available] = await Promise.all([
      contract.getLevelStats(level),
      contract.getLevelStatsUSDC(level),
      contract.levelPrices(level),
      contract.levelPricesUsdc(level),
      contract.levelAvailable(level),
    ]);
    const doc = {
      chainId,
      level,
      available,
      ethPriceWei: ethPrice.toString(),
      usdcPrice: usdcPrice.toString(),
      stats: jsonValue(stats),
      usdcStats: jsonValue(usdcStats),
      syncedAt: FieldValue.serverTimestamp(),
    };
    await db.collection("levels").doc(`${chainId}_${level}`).set(doc, { merge: true });
    results.push({ level, synced: true });
  }
  return { synced: results.length, levels: results };
});

// TODO: enable when contract is deployed with real address
// exports.confirmTransactions = onSchedule({
//   schedule: "every 2 minutes",
//   region,
//   timeoutSeconds: 60,
//   memory: "256MiB",
//   maxInstances: 1,
//   secrets: [rpcUrl],
// }, async () => {
//   const { provider, address, chainId } = runtime();
//   const snapshot = await db.collection("transactions").where("status", "==", "submitted").limit(50).get();
//   for (const doc of snapshot.docs) {
//     const receipt = await provider.getTransactionReceipt(doc.get("transactionHash"));
//     if (!receipt) continue;
//     const validContract = receipt.to?.toLowerCase() === address.toLowerCase();
//     const walletAddress = wallet(doc.get("wallet"));
//     const validSender = walletAddress && receipt.from?.toLowerCase() === walletAddress;
//     const status = receipt.status === 1 && validContract && validSender
//       ? "confirmed"
//       : validContract && !validSender
//         ? "rejected_owner_mismatch"
//         : "failed";
//     await doc.ref.set({
//       status,
//       blockNumber: receipt.blockNumber,
//       receiptFrom: receipt.from?.toLowerCase() || null,
//       receiptTo: receipt.to?.toLowerCase() || null,
//       resolvedAt: FieldValue.serverTimestamp(),
//     }, { merge: true });
//     const target = doc.get("wallet");
//     if (target) await pushToWallet(target, status === "confirmed" ? "Transaction confirmed" : "Transaction failed", doc.get("transactionHash"), { status, chainId });
//   }
// });

exports.publishRoundManifest = onCall({
  region,
  enforceAppCheck: true,
}, async (request) => {
  requireApp(request);
  if (!request.auth?.token?.admin) {
    throw new HttpsError("permission-denied", "Admin claim required");
  }
  const managerAddress = publicOptionalAddress(roundManagerAddressParam);
  const signerAddress = publicOptionalAddress(roundScheduleSignerParam);
  const coreAddress = publicContractAddress();
  if (!managerAddress || !signerAddress || !coreAddress) {
    throw new HttpsError("failed-precondition", "Round deployment config is incomplete");
  }

  const source = request.data?.config;
  const signature = String(request.data?.signature || "");
  let winningCells;
  try {
    winningCells = (request.data?.winningCells || []).map((value) => BigInt(value));
  } catch (_) {
    throw new HttpsError("invalid-argument", "Invalid winning cells");
  }
  if (!source || !/^0x[0-9a-fA-F]{130}$/.test(signature)) {
    throw new HttpsError("invalid-argument", "Invalid round config or signature");
  }
  const integer = (name) => {
    try {
      const value = BigInt(source[name]);
      if (value < 0n) throw new Error("negative");
      return value;
    } catch (_) {
      throw new HttpsError("invalid-argument", `Invalid ${name}`);
    }
  };
  const config = {
    seasonId: integer("seasonId"),
    roundId: integer("roundId"),
    level: integer("level"),
    startsAt: integer("startsAt"),
    entriesCloseAt: integer("entriesCloseAt"),
    endsAt: integer("endsAt"),
    freezeClosesAt: integer("freezeClosesAt"),
    maxPlayers: integer("maxPlayers"),
    maxWinners: integer("maxWinners"),
    winningCellsRoot: String(source.winningCellsRoot || ""),
    ethPrice: integer("ethPrice"),
    usdcPrice: integer("usdcPrice"),
    freezeLimit: integer("freezeLimit"),
    paymentSplitVersion: integer("paymentSplitVersion"),
  };
  winningCells.sort((left, right) => left < right ? -1 : left > right ? 1 : 0);
  if (
    winningCells.length !== Number(config.maxWinners) ||
    winningCells.some((cell, index) => cell <= 0n || (index > 0 && cell === winningCells[index - 1]))
  ) {
    throw new HttpsError("invalid-argument", "Complete unique winning cells are required");
  }
  const winningTree = buildWinningCellTree(config.roundId, winningCells);
  if (
    config.level < 1n || config.level > 17n ||
    config.startsAt >= config.entriesCloseAt ||
    config.entriesCloseAt >= config.endsAt ||
    config.freezeClosesAt < config.startsAt ||
    config.freezeClosesAt > config.endsAt ||
    config.maxPlayers === 0n || config.maxWinners === 0n ||
    config.maxWinners > 8n || config.freezeLimit === 0n ||
    config.paymentSplitVersion !== 1n ||
    !/^0x[0-9a-fA-F]{64}$/.test(config.winningCellsRoot) ||
    winningTree.root.toLowerCase() !== config.winningCellsRoot.toLowerCase()
  ) {
    throw new HttpsError("invalid-argument", "Round constraints are invalid");
  }
  const domain = {
    name: "EasyGameAdvance",
    version: "2",
    chainId: Number(chainIdParam.value()),
    verifyingContract: managerAddress,
  };
  let recovered;
  try {
    recovered = verifyTypedData(domain, roundTypes, config, signature);
  } catch (_) {
    throw new HttpsError("invalid-argument", "Malformed EIP-712 signature");
  }
  if (getAddress(recovered) !== getAddress(signerAddress)) {
    throw new HttpsError("permission-denied", "Invalid schedule signer");
  }

  const configHash = TypedDataEncoder.hashStruct("RoundConfig", roundTypes, config);
  const roundRef = db.collection("rounds").doc(config.roundId.toString());
  await db.runTransaction(async (transaction) => {
    const existing = await transaction.get(roundRef);
    if (existing.exists) {
      throw new HttpsError("already-exists", "Round manifest is immutable");
    }
    transaction.create(roundRef, {
      chainId: Number(chainIdParam.value()),
      contractAddress: coreAddress.toLowerCase(),
      roundManagerAddress: managerAddress.toLowerCase(),
      configHash,
      operatorSignature: signature,
      schemaVersion: 2,
      config: {
        seasonId: config.seasonId.toString(),
        roundId: config.roundId.toString(),
        level: Number(config.level),
        startsAt: Timestamp.fromMillis(Number(config.startsAt) * 1000),
        entriesCloseAt: Timestamp.fromMillis(Number(config.entriesCloseAt) * 1000),
        endsAt: Timestamp.fromMillis(Number(config.endsAt) * 1000),
        freezeClosesAt: Timestamp.fromMillis(Number(config.freezeClosesAt) * 1000),
        maxPlayers: Number(config.maxPlayers),
        maxWinners: Number(config.maxWinners),
        winningCellsRoot: config.winningCellsRoot,
        ethPriceWei: config.ethPrice.toString(),
        usdcPrice: config.usdcPrice.toString(),
        freezeLimit: Number(config.freezeLimit),
        paymentSplitVersion: Number(config.paymentSplitVersion),
      },
      createdAt: FieldValue.serverTimestamp(),
    });
    winningCells.forEach((cellId, index) => {
      transaction.create(roundRef.collection("winningCells").doc(cellId.toString()), {
        cellId: cellId.toString(),
        proof: winningTree.proofs[index],
        createdAt: FieldValue.serverTimestamp(),
      });
    });
  });
  return { roundId: config.roundId.toString(), configHash };
});

exports.getRoundSettlementProofs = onCall({
  region,
  // requireApp() enforces verified App Check in non-local environments.
  enforceAppCheck: false,
}, async (request) => {
  requireApp(request);
  const roundId = String(request.data?.roundId || "");
  if (!/^\d+$/.test(roundId)) {
    throw new HttpsError("invalid-argument", "Invalid round ID");
  }
  const roundRef = db.collection("rounds").doc(roundId);
  const round = await roundRef.get();
  if (!round.exists) throw new HttpsError("not-found", "Round not found");
  const endsAt = round.get("config.endsAt");
  if (!(endsAt instanceof Timestamp) || Date.now() < endsAt.toMillis()) {
    throw new HttpsError("failed-precondition", "Winning cells are still sealed");
  }
  const snapshot = await roundRef.collection("winningCells").get();
  const cells = snapshot.docs.map((document) => ({
    cellId: document.get("cellId"),
    proof: document.get("proof") || [],
  })).sort((left, right) => BigInt(left.cellId) < BigInt(right.cellId) ? -1 : 1);
  return { roundId, cells };
});

exports.fulfillBasePayRound = onCall({
  region,
  enforceAppCheck: true,
  secrets: [rpcUrl, basePayFulfillerKey],
  timeoutSeconds: 120,
}, async (request) => {
  requireApp(request);
  const uid = requireUser(request);
  await enforceRateLimit("fulfillBasePayRound", uid, 10, 60 * 60);

  const paymentId = String(request.data?.paymentId || "");
  const roundId = String(request.data?.roundId || "");
  const inviter = wallet(request.data?.inviter) || zeroAddress;
  if (!/^0x[0-9a-fA-F]{64}$/.test(paymentId) || !/^\d+$/.test(roundId)) {
    throw new HttpsError("invalid-argument", "Valid payment and round IDs are required");
  }

  const gatewayAddress = publicOptionalAddress(basePayGatewayAddressParam);
  if (!gatewayAddress) {
    throw new HttpsError("failed-precondition", "Base Pay gateway is not configured");
  }
  const link = await db.collection("walletLinks").doc(uid).get();
  const player = link.exists ? wallet(link.get("wallet")) : null;
  if (!player || Number(link.get("chainId")) !== Number(chainIdParam.value())) {
    throw new HttpsError("failed-precondition", "Link the current Base wallet first");
  }

  const round = await db.collection("rounds").doc(roundId).get();
  if (!round.exists) throw new HttpsError("not-found", "Round not found");
  if (
    Number(round.get("chainId")) !== Number(chainIdParam.value()) ||
    String(round.get("contractAddress") || "").toLowerCase() !== publicContractAddress().toLowerCase()
  ) {
    throw new HttpsError("failed-precondition", "Round deployment does not match Base Pay config");
  }
  const config = roundConfigFromDocument(round);
  if (config.roundId.toString() !== roundId || config.usdcPrice <= 0n) {
    throw new HttpsError("failed-precondition", "Round does not accept USDC");
  }
  const now = BigInt(Math.floor(Date.now() / 1000));
  if (now < config.startsAt || now >= config.entriesCloseAt) {
    throw new HttpsError("failed-precondition", "Round entries are closed");
  }

  const testnet = Number(chainIdParam.value()) === 84532;
  let payment;
  try {
    payment = await getPaymentStatus({ id: paymentId, testnet });
  } catch (error) {
    logger.error("Base Pay status lookup failed", error);
    throw new HttpsError("unavailable", "Unable to verify Base Pay transaction");
  }
  if (payment.status !== "completed") {
    throw new HttpsError("failed-precondition", `Base Pay status is ${payment.status}`);
  }
  const sender = wallet(payment.sender);
  const recipient = wallet(payment.recipient);
  let paidAmount;
  try {
    paidAmount = parseUnits(String(payment.amount), 6);
  } catch (_) {
    throw new HttpsError("data-loss", "Base Pay returned an invalid amount");
  }
  if (sender !== player) throw new HttpsError("permission-denied", "Base Pay sender mismatch");
  if (recipient !== gatewayAddress.toLowerCase()) {
    throw new HttpsError("permission-denied", "Base Pay recipient mismatch");
  }
  if (paidAmount !== config.usdcPrice) {
    throw new HttpsError("permission-denied", "Base Pay amount mismatch");
  }

  const paymentRef = db.collection("basePayPayments").doc(
    `${chainIdParam.value()}_${paymentId.toLowerCase()}`,
  );
  const existing = await paymentRef.get();
  if (existing.exists) {
    if (existing.get("uid") !== uid || existing.get("wallet") !== player) {
      throw new HttpsError("already-exists", "Base Pay transaction already belongs to another order");
    }
    if (existing.get("status") === "fulfilled") {
      return {
        paymentId,
        transactionHash: existing.get("fulfillmentTransactionHash"),
        status: "fulfilled",
      };
    }
    if (["submitted", "submitted_unknown"].includes(existing.get("status"))) {
      const submittedHash = String(existing.get("fulfillmentTransactionHash") || "");
      if (/^0x[0-9a-fA-F]{64}$/.test(submittedHash)) {
        const provider = new JsonRpcProvider(rpcUrl.value(), Number(chainIdParam.value()));
        const receipt = await provider.getTransactionReceipt(submittedHash);
        if (receipt?.status === 1) {
          await paymentRef.set({
            status: "fulfilled",
            fulfillmentBlockNumber: receipt.blockNumber,
            fulfilledAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
          }, { merge: true });
          return { paymentId, transactionHash: submittedHash, status: "fulfilled" };
        }
        if (!receipt) {
          throw new HttpsError("aborted", "Base Pay fulfillment is awaiting confirmation");
        }
        await paymentRef.set({
          status: "failed",
          error: "Previous fulfillment transaction reverted",
          updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });
      }
    }
    if (existing.get("status") === "processing") {
      const updatedAt = existing.get("updatedAt");
      if (updatedAt instanceof Timestamp && Date.now() - updatedAt.toMillis() < 5 * 60 * 1000) {
        throw new HttpsError("aborted", "Base Pay fulfillment is already processing");
      }
      await paymentRef.set({
        status: "failed",
        error: "Stale fulfillment lock recovered",
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
    }
  }

  await db.runTransaction(async (transaction) => {
    const fresh = await transaction.get(paymentRef);
    if (fresh.exists && fresh.get("status") !== "failed") {
      throw new HttpsError("already-exists", "Base Pay transaction is already processing");
    }
    transaction.set(paymentRef, {
      uid,
      wallet: player,
      chainId: Number(chainIdParam.value()),
      paymentId: paymentId.toLowerCase(),
      roundId,
      inviter,
      recipient: gatewayAddress.toLowerCase(),
      amountUsdc: config.usdcPrice.toString(),
      status: "processing",
      verifiedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  });

  let fulfillmentHash = "";
  try {
    const provider = new JsonRpcProvider(rpcUrl.value(), Number(chainIdParam.value()));
    const signer = new Wallet(basePayFulfillerKey.value(), provider);
    const gateway = new Contract(gatewayAddress, basePayGatewayAbi, signer);
    if (getAddress(await gateway.fulfiller()) !== signer.address) {
      throw new Error("Firebase fulfiller does not match the Base Pay gateway");
    }
    const signature = String(round.get("operatorSignature") || "");
    if (!/^0x[0-9a-fA-F]{130}$/.test(signature)) {
      throw new Error("Round operator signature is invalid");
    }
    const transaction = await gateway.fulfillRound(
      paymentId,
      config,
      signature,
      player,
      inviter,
    );
    fulfillmentHash = transaction.hash;
    await paymentRef.set({
      fulfillmentTransactionHash: fulfillmentHash,
      status: "submitted",
      submittedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    const receipt = await transaction.wait(Number(confirmationsParam.value()));
    if (!receipt || receipt.status !== 1) throw new Error("Base Pay fulfillment reverted");
    await paymentRef.set({
      status: "fulfilled",
      fulfillmentBlockNumber: receipt.blockNumber,
      fulfilledAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    return { paymentId, transactionHash: fulfillmentHash, status: "fulfilled" };
  } catch (error) {
    logger.error("Base Pay fulfillment failed", { paymentId, roundId, fulfillmentHash, error });
    await paymentRef.set({
      status: fulfillmentHash ? "submitted_unknown" : "failed",
      error: String(error?.message || error).slice(0, 500),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    throw new HttpsError("internal", "Base Pay was verified but round fulfillment failed");
  }
});

exports.getAppConfig = onCall({
  region,
  secrets: [recaptchaSiteKey, vapidKey],
}, async (_request) => {
  const chainId = chainIdParam.value();
  const easyGameAddress = publicContractAddress();
  const publicRpc = publicRpcUrlParam.value();
  const usdcTokenAddress = publicOptionalAddress(usdcTokenAddressParam);
  return {
    recaptchaSiteKey: recaptchaSiteKey.value(),
    vapidKey: vapidKey.value(),
    appPublicUrl: appPublicUrlParam.value(),
    web3Rpc: publicRpc,
    web3PublicRpcUrl: publicRpc,
    chainId,
    targetBaseChainId: chainId,
    contractAddress: easyGameAddress,
    easyGameContractAddress: easyGameAddress,
    roundManagerAddress: publicOptionalAddress(roundManagerAddressParam),
    roundScheduleSigner: publicOptionalAddress(roundScheduleSignerParam),
    arenaSkillsAddress: publicOptionalAddress(arenaSkillsAddressParam),
    roundSettlementAddress: publicOptionalAddress(roundSettlementAddressParam),
    basePayGatewayAddress: publicOptionalAddress(basePayGatewayAddressParam),
    usdcTokenAddress,
    easyGameInviter: publicOptionalAddress(easyGameInviterParam),
    paymentReceiver: publicOptionalAddress(paymentReceiverParam),
    baseBuilderDataSuffix: baseBuilderDataSuffixParam.value(),
    allowLocalChains: allowLocalChainsParam.value(),
    baseAccountAppName: baseAccountAppNameParam.value(),
    baseAccountAppLogoUrl: baseAccountAppLogoUrlParam.value(),
    environment: environmentParam.value(),
  };
});

exports.health = onRequest({
  region,
  cors: false,
  secrets: [rpcUrl],
  timeoutSeconds: 30,
}, async (_request, response) => {
  const chainId = Number(chainIdParam.value());
  const addresses = {
    core: publicOptionalAddress(contractAddress),
    roundManager: publicOptionalAddress(roundManagerAddressParam),
    arenaSkills: publicOptionalAddress(arenaSkillsAddressParam),
    settlement: publicOptionalAddress(roundSettlementAddressParam),
    basePayGateway: publicOptionalAddress(basePayGatewayAddressParam),
    usdc: publicOptionalAddress(usdcTokenAddressParam),
  };
  const missingConfig = Object.entries(addresses)
    .filter(([, address]) => !address)
    .map(([name]) => name);
  if (missingConfig.length > 0) {
    response.status(503).json({
      ok: false,
      status: "config-incomplete",
      chainId,
      missing: missingConfig,
    });
    return;
  }

  try {
    const provider = new JsonRpcProvider(rpcUrl.value(), chainId);
    const entries = Object.entries(addresses);
    const codes = await Promise.all(
      entries.map(([, address]) => provider.getCode(address)),
    );
    const missingCode = entries
      .filter((_, index) => codes[index] === "0x")
      .map(([name]) => name);
    response.status(missingCode.length === 0 ? 200 : 503).json({
      ok: missingCode.length === 0,
      status: missingCode.length === 0 ? "ready" : "contracts-missing",
      chainId,
      missing: missingCode,
    });
  } catch (error) {
    logger.error("Health RPC check failed", error);
    response.status(503).json({
      ok: false,
      status: "rpc-unavailable",
      chainId,
    });
  }
});
