const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, FieldValue, Timestamp } = require("firebase-admin/firestore");
const { onCall, onRequest, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret, defineString } = require("firebase-functions/params");
const { logger } = require("firebase-functions");
const {
  Contract,
  JsonRpcProvider,
  getAddress,
  isAddress,
} = require("ethers");
const {
  createPublicClient,
  defineChain,
  getAddress: getViemAddress,
  http,
} = require("viem");
const crypto = require("crypto");
const {
  CORE_LINK_ABI,
  ROUND_MANAGER_LINK_ABI,
  ARENA_SKILLS_LINK_ABI,
  SETTLEMENT_LINK_ABI,
} = require("./game_abi");
const { parseSeasonManifest } = require("./round_season_manifest");

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
const chainIdParam = defineString("EASY_GAME_CHAIN_ID", { default: "8453" });
const confirmationsParam = defineString("EASY_GAME_CONFIRMATIONS", { default: "5" });
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
const siweAllowedOriginsParam = defineString("SIWE_ALLOWED_ORIGINS", {
  default: "https://lottery-advance.web.app,https://lottery-advance.firebaseapp.com,https://easygame.io",
});
const region = "us-central1";
const maxDeviceTokensPerWallet = 10;
const allowedPlatforms = new Set(["web", "android", "ios", "macos", "windows", "linux"]);
const zeroAddress = "0x0000000000000000000000000000000000000000";
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

function walletFirebaseUid(playerAddress) {
  return `wallet_${hashId(`${chainIdParam.value()}:${playerAddress}`).slice(0, 64)}`;
}

async function storeAuthenticatedWallet({
  bootstrapUid,
  uid,
  playerAddress,
  challengeRef,
  message,
  nonce,
  origin,
}) {
  await db.runTransaction(async (transaction) => {
    const challengeSnapshot = await transaction.get(challengeRef);
    const userRef = db.collection("users").doc(
      `${chainIdParam.value()}_${playerAddress}`,
    );
    const userSnapshot = await transaction.get(userRef);
    if (!challengeSnapshot.exists) {
      throw new HttpsError("failed-precondition", "Request SIWE nonce first");
    }
    const challenge = challengeSnapshot.data();
    if (
      challenge.bootstrapUid !== bootstrapUid ||
      challenge.wallet !== playerAddress ||
      challenge.message !== message ||
      challenge.nonce !== nonce ||
      challenge.origin !== origin
    ) {
      throw new HttpsError("permission-denied", "SIWE challenge changed");
    }
    if (challenge.used || challenge.expiresAt.toMillis() <= Date.now()) {
      throw new HttpsError("deadline-exceeded", "SIWE challenge expired or already used");
    }
    transaction.update(challengeRef, {
      used: true,
      usedAt: FieldValue.serverTimestamp(),
      authenticatedUid: uid,
    });
    transaction.set(db.collection("walletLinks").doc(uid), {
      uid,
      wallet: playerAddress,
      chainId: Number(chainIdParam.value()),
      verifiedAt: FieldValue.serverTimestamp(),
      authProvider: "siwe",
    });
    const userData = {
      wallet: playerAddress,
      chainId: Number(chainIdParam.value()),
      exists: true,
      walletVerified: true,
      profileVersion: 1,
      updatedAt: FieldValue.serverTimestamp(),
    };
    if (!userSnapshot.exists) {
      userData.registeredAt = FieldValue.serverTimestamp();
    }
    transaction.set(userRef, userData, { merge: true });
  });
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
  if (!request.auth) throw new HttpsError("unauthenticated", "Firebase session required");
  return request.auth.uid;
}

function requireWalletUser(request) {
  const uid = requireUser(request);
  const claims = request.auth?.token || {};
  const playerAddress = wallet(claims.wallet);
  const expectedChainId = Number(chainIdParam.value());
  if (
    claims.authProvider !== "siwe" ||
    !playerAddress ||
    Number(claims.chainId) !== expectedChainId ||
    uid !== walletFirebaseUid(playerAddress)
  ) {
    throw new HttpsError(
      "permission-denied",
      "Verified wallet session required",
    );
  }
  return { uid, playerAddress };
}

function requireAdmin(request) {
  requireUser(request);
  if (!request.auth?.token?.admin) {
    throw new HttpsError("permission-denied", "Admin claim required");
  }
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

exports.requestSiweNonce = onCall({ region, enforceAppCheck: true }, async (request) => {
  requireApp(request);
  const bootstrapUid = requireUser(request);
  await enforceRateLimit("requestSiweNonce", bootstrapUid, 5, 60);
  const playerAddress = wallet(request.data?.wallet);
  if (!playerAddress) throw new HttpsError("invalid-argument", "Valid wallet required");
  if (Number(request.data?.chainId) !== Number(chainIdParam.value())) {
    throw new HttpsError("failed-precondition", "Switch to the configured Base network");
  }
  await enforceRateLimit("requestSiweNonceWallet", playerAddress, 20, 60 * 60);
  const origin = allowedSiweOrigin(request.data?.origin);
  const uri = new URL(origin);
  const nonce = crypto.randomBytes(24).toString("hex");
  const issuedAt = new Date();
  const expiresAt = Timestamp.fromMillis(Date.now() + 10 * 60 * 1000);
  const message = [
    `${uri.host} wants you to sign in with your Ethereum account:`,
    playerAddress,
    "",
    "Sign in to Easy Games.",
    "",
    `URI: ${origin}`,
    "Version: 1",
    `Chain ID: ${chainIdParam.value()}`,
    `Nonce: ${nonce}`,
    `Issued At: ${issuedAt.toISOString()}`,
    `Expiration Time: ${expiresAt.toDate().toISOString()}`,
    `Request ID: ${bootstrapUid}`,
  ].join("\n");
  await db.collection("walletAuthChallenges").doc(bootstrapUid).set({
    bootstrapUid,
    wallet: playerAddress,
    chainId: Number(chainIdParam.value()),
    nonce,
    origin,
    message,
    issuedAt: Timestamp.fromDate(issuedAt),
    expiresAt,
    used: false,
  });
  return { message, expiresAt: expiresAt.toMillis() };
});

exports.authenticateWallet = onCall({
  region,
  enforceAppCheck: true,
  secrets: [rpcUrl],
}, async (request) => {
  requireApp(request);
  const bootstrapUid = requireUser(request);
  await enforceRateLimit("authenticateWallet", bootstrapUid, 10, 10 * 60);
  const playerAddress = wallet(request.data?.address);
  const message = request.data?.message;
  const signature = request.data?.signature;
  if (!playerAddress || typeof message !== "string") {
    throw new HttpsError("invalid-argument", "Valid SIWE payload required");
  }
  if (typeof signature !== "string" || signature.length < 20 || signature.length > 1024) {
    throw new HttpsError("invalid-argument", "Valid wallet signature required");
  }
  const challengeRef = db.collection("walletAuthChallenges").doc(bootstrapUid);
  const challengeSnapshot = await challengeRef.get();
  if (!challengeSnapshot.exists) throw new HttpsError("failed-precondition", "Request SIWE nonce first");
  const challenge = challengeSnapshot.data();
  if (challenge.used || challenge.expiresAt.toMillis() <= Date.now()) {
    throw new HttpsError("deadline-exceeded", "SIWE challenge expired or already used");
  }
  if (challenge.wallet !== playerAddress || challenge.message !== message) {
    throw new HttpsError("permission-denied", "SIWE challenge mismatch");
  }
  validateSiwe({
    address: playerAddress,
    message,
    nonce: challenge.nonce,
    origin: challenge.origin,
  });
  const verified = await verifyWalletSignature(playerAddress, message, signature);
  if (!verified) {
    throw new HttpsError("permission-denied", "Invalid wallet signature");
  }
  const uid = walletFirebaseUid(playerAddress);
  await storeAuthenticatedWallet({
    bootstrapUid,
    uid,
    playerAddress,
    challengeRef,
    message,
    nonce: challenge.nonce,
    origin: challenge.origin,
  });
  const customToken = await getAuth().createCustomToken(uid, {
    wallet: playerAddress,
    chainId: Number(chainIdParam.value()),
    authProvider: "siwe",
  });
  return { wallet: playerAddress, uid, customToken, verified: true };
});

exports.registerDevice = onCall({ region, enforceAppCheck: true }, async (request) => {
  requireApp(request);
  const { uid, playerAddress } = requireWalletUser(request);
  await enforceRateLimit("registerDevice", uid, 10, 60 * 60);
  const link = await db.collection("walletLinks").doc(uid).get();
  if (!link.exists || wallet(link.get("wallet")) !== playerAddress) {
    throw new HttpsError("failed-precondition", "Link wallet first");
  }
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
  const { uid, playerAddress } = requireWalletUser(request);
  await enforceRateLimit("trackTransaction", uid, 20, 60 * 60);
  const hash = request.data?.transactionHash;
  if (typeof hash !== "string" || !/^0x[0-9a-fA-F]{64}$/.test(hash)) throw new HttpsError("invalid-argument", "Valid transaction hash required");
  const link = await db.collection("walletLinks").doc(uid).get();
  if (!link.exists || wallet(link.get("wallet")) !== playerAddress) {
    throw new HttpsError("failed-precondition", "Link wallet first");
  }
  await db.collection("transactions").doc(`${chainIdParam.value()}_${hash.toLowerCase()}`).set({
    chainId: Number(chainIdParam.value()),
    transactionHash: hash.toLowerCase(),
    uid,
    wallet: playerAddress,
    status: "submitted",
    createdAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  return { tracked: true };
});

exports.contractSmokeTest = onCall({
  region,
  enforceAppCheck: true,
  timeoutSeconds: 60,
  secrets: [rpcUrl],
}, async (request) => {
  requireApp(request);
  requireAdmin(request);

  const chainId = Number(chainIdParam.value());
  const addresses = {
    core: publicContractAddress(),
    roundManager: publicOptionalAddress(roundManagerAddressParam),
    arenaSkills: publicOptionalAddress(arenaSkillsAddressParam),
    settlement: publicOptionalAddress(roundSettlementAddressParam),
    usdc: publicOptionalAddress(usdcTokenAddressParam),
  };
  const missingConfig = Object.entries(addresses)
    .filter(([, address]) => !address)
    .map(([name]) => name);
  if (missingConfig.length > 0) {
    throw new HttpsError(
      "failed-precondition",
      `Deployment config is incomplete: ${missingConfig.join(", ")}`,
    );
  }

  const provider = new JsonRpcProvider(rpcUrl.value(), chainId);
  const entries = Object.entries(addresses);
  const codes = await Promise.all(
    entries.map(([, address]) => provider.getCode(address)),
  );
  const missingCode = entries
    .filter((_, index) => codes[index] === "0x")
    .map(([name]) => name);
  if (missingCode.length > 0) {
    throw new HttpsError(
      "failed-precondition",
      `Contract bytecode is missing: ${missingCode.join(", ")}`,
    );
  }

  const core = new Contract(addresses.core, CORE_LINK_ABI, provider);
  const manager = new Contract(
    addresses.roundManager,
    ROUND_MANAGER_LINK_ABI,
    provider,
  );
  const skills = new Contract(
    addresses.arenaSkills,
    ARENA_SKILLS_LINK_ABI,
    provider,
  );
  const settlement = new Contract(
    addresses.settlement,
    SETTLEMENT_LINK_ABI,
    provider,
  );
  const normalized = Object.fromEntries(
    Object.entries(addresses).map(([name, address]) => [name, address.toLowerCase()]),
  );
  const links = {
    coreRoundManager: (await core.roundManager()).toLowerCase() === normalized.roundManager,
    coreSettlement: (await core.settlementContract()).toLowerCase() === normalized.settlement,
    coreUsdc: (await core.usdcToken()).toLowerCase() === normalized.usdc,
    coreFinalized: await core.systemContractsFinalized(),
    managerCore: (await manager.gameCore()).toLowerCase() === normalized.core,
    managerSkills: (await manager.arenaSkills()).toLowerCase() === normalized.arenaSkills,
    managerSettlement:
      (await manager.settlementContract()).toLowerCase() === normalized.settlement,
    managerFinalized: await manager.systemContractsFinalized(),
    skillsCore: (await skills.gameCore()).toLowerCase() === normalized.core,
    skillsManager: (await skills.roundManager()).toLowerCase() === normalized.roundManager,
    skillsUsdc: (await skills.usdcToken()).toLowerCase() === normalized.usdc,
    settlementCore: (await settlement.gameCore()).toLowerCase() === normalized.core,
    settlementManager: (await settlement.roundManager()).toLowerCase() === normalized.roundManager,
    settlementSkills: (await settlement.arenaSkills()).toLowerCase() === normalized.arenaSkills,
    settlementUsdc: (await settlement.usdcToken()).toLowerCase() === normalized.usdc,
  };
  const brokenLinks = Object.entries(links)
    .filter(([, linked]) => !linked)
    .map(([name]) => name);
  if (brokenLinks.length > 0) {
    throw new HttpsError(
      "failed-precondition",
      `Contract links are inconsistent: ${brokenLinks.join(", ")}`,
    );
  }

  return { ok: true, chainId, addresses, links };
});

exports.publishSeasonManifest = onCall({
  region,
  enforceAppCheck: true,
  secrets: [rpcUrl],
  timeoutSeconds: 120,
}, async (request) => {
  requireApp(request);
  requireAdmin(request);
  const managerAddress = publicOptionalAddress(roundManagerAddressParam);
  const signerAddress = publicOptionalAddress(roundScheduleSignerParam);
  const coreAddress = publicContractAddress();
  const chainId = Number(chainIdParam.value());
  if (!managerAddress || !signerAddress || !coreAddress) {
    throw new HttpsError("failed-precondition", "Round deployment config is incomplete");
  }

  let season;
  try {
    season = parseSeasonManifest(request.data, {
      chainId,
      managerAddress,
      signerAddress,
    });
  } catch (error) {
    throw new HttpsError("invalid-argument", String(error?.message || error));
  }

  const provider = new JsonRpcProvider(rpcUrl.value(), chainId);
  const manager = new Contract(managerAddress, ROUND_MANAGER_LINK_ABI, provider);
  let chainSeason;
  let committedHashes;
  try {
    [chainSeason, committedHashes] = await Promise.all([
      manager.getSeasonState(season.seasonId),
      Promise.all(season.rounds.map((round) =>
        manager.getCommittedRoundHash(season.seasonId, round.config.level))),
    ]);
  } catch (error) {
    logger.error("Season commitment check failed", {
      seasonId: season.seasonId.toString(),
      error: String(error?.message || error).slice(0, 500),
    });
    throw new HttpsError("unavailable", "Unable to verify on-chain season commitment");
  }
  if (!chainSeason.committed || chainSeason.configRoot.toLowerCase() !== season.configRoot.toLowerCase()) {
    throw new HttpsError(
      "failed-precondition",
      "Commit the complete signed season on-chain before publishing it",
    );
  }
  for (let index = 0; index < season.rounds.length; index++) {
    if (committedHashes[index].toLowerCase() !== season.rounds[index].configHash.toLowerCase()) {
      throw new HttpsError(
        "failed-precondition",
        `On-chain commitment mismatch for level ${index + 1}`,
      );
    }
  }

  const seasonRef = db.collection("seasons").doc(season.seasonId.toString());
  const roundRefs = season.rounds.map((round) =>
    db.collection("rounds").doc(round.config.roundId.toString()));
  await db.runTransaction(async (transaction) => {
    const snapshots = await Promise.all([
      transaction.get(seasonRef),
      ...roundRefs.map((reference) => transaction.get(reference)),
    ]);
    if (snapshots[0].exists) {
      throw new HttpsError("already-exists", "Season manifest is immutable");
    }
    if (snapshots.slice(1).some((snapshot) => snapshot.exists)) {
      throw new HttpsError("already-exists", "A committed round is already published");
    }

    const levelStarts = {};
    const roundIdsByLevel = {};
    for (const round of season.rounds) {
      const levelKey = round.config.level.toString();
      levelStarts[levelKey] = round.config.startsAt.toString();
      roundIdsByLevel[levelKey] = round.config.roundId.toString();
    }
    transaction.create(seasonRef, {
      seasonId: season.seasonId.toString(),
      chainId,
      contractAddress: coreAddress.toLowerCase(),
      roundManagerAddress: managerAddress.toLowerCase(),
      configRoot: season.configRoot,
      committedOnChain: true,
      firstStartsAt: Timestamp.fromMillis(Number(season.firstStartsAt) * 1000),
      lastEndsAt: Timestamp.fromMillis(Number(season.lastEndsAt) * 1000),
      levelStarts,
      roundIdsByLevel,
      schemaVersion: 3,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    season.rounds.forEach((round, roundIndex) => {
      const config = round.config;
      const roundRef = roundRefs[roundIndex];
      transaction.create(roundRef, {
        chainId,
        contractAddress: coreAddress.toLowerCase(),
        roundManagerAddress: managerAddress.toLowerCase(),
        configHash: round.configHash,
        seasonConfigRoot: season.configRoot,
        seasonCommittedOnChain: true,
        operatorSignature: round.signature,
        schemaVersion: 3,
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
      round.winningCells.forEach((cellId, cellIndex) => {
        transaction.create(
          roundRef.collection("winningCells").doc(cellId.toString()),
          {
            cellId: cellId.toString(),
            proof: round.proofs[cellIndex],
            createdAt: FieldValue.serverTimestamp(),
          },
        );
      });
    });
  });
  return {
    seasonId: season.seasonId.toString(),
    configRoot: season.configRoot,
    roundIds: season.rounds.map((round) => round.config.roundId.toString()),
  };
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
    usdcTokenAddress,
    easyGameInviter: publicOptionalAddress(easyGameInviterParam),
    paymentReceiver: publicOptionalAddress(paymentReceiverParam),
    baseBuilderDataSuffix: baseBuilderDataSuffixParam.value(),
    allowLocalChains: allowLocalChainsParam.value(),
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
