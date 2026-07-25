const { getAuth } = require("firebase-admin/auth");
const { onCall, onRequest } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const { Contract, JsonRpcProvider } = require("ethers");
const crypto = require("crypto");
const {
  CORE_LINK_ABI,
  ROUND_MANAGER_LINK_ABI,
  ARENA_SKILLS_LINK_ABI,
  SETTLEMENT_LINK_ABI,
} = require("./game_abi");
const { parseSeasonManifest } = require("./round_season_manifest");

const {
  db,
  FieldValue,
  Timestamp,
  HttpsError,
  chainIdParam,
  rpcUrl,
  recaptchaSiteKey,
  vapidKey,
  contractAddress,
  roundManagerAddressParam,
  roundScheduleSignerParam,
  arenaSkillsAddressParam,
  roundSettlementAddressParam,
  appPublicUrlParam,
  publicRpcUrlParam,
  environmentParam,
  usdcTokenAddressParam,
  easyGameInviterParam,
  region,
  maxDeviceTokensPerWallet,
  allowedPlatforms,
  hashId,
  publicContractAddress,
  publicOptionalAddress,
  wallet,
} = require("./config");
const { allowedSiweOrigin, validateSiwe } = require("./siwe");
const {
  walletFirebaseUid,
  storeAuthenticatedWallet,
  requireWalletUser,
  requireAdmin,
  enforceRateLimit,
} = require("./auth");
const {
  verifyWalletSignature,
  walletVerificationClient,
} = require("./contract");
const {
  decodeTrackedTransaction,
  normalizedAddress,
} = require("./transaction_decoder");

exports.requestSiweNonce = onCall({ region, enforceAppCheck: true }, async (request) => {
  const playerAddress = wallet(request.data?.wallet);
  if (!playerAddress) throw new HttpsError("invalid-argument", "Valid wallet required");
  if (Number(request.data?.chainId) !== Number(chainIdParam.value())) {
    throw new HttpsError("failed-precondition", "Switch to the configured Base network");
  }
  await enforceRateLimit("requestSiweNonceWallet", playerAddress, 20, 60 * 60);
  const origin = allowedSiweOrigin(request.data?.origin);
  const uri = new URL(origin);
  const nonce = crypto.randomBytes(24).toString("hex");
  const challengeId = crypto.randomBytes(16).toString("hex");
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
    `Request ID: ${challengeId}`,
  ].join("\n");
  await db.collection("walletAuthChallenges").doc(challengeId).set({
    challengeId,
    wallet: playerAddress,
    chainId: Number(chainIdParam.value()),
    nonce,
    origin,
    message,
    issuedAt: Timestamp.fromDate(issuedAt),
    expiresAt,
    used: false,
  });
  return { message, expiresAt: expiresAt.toMillis(), challengeId };
});

exports.authenticateWallet = onCall({
  region,
  enforceAppCheck: true,
  secrets: [rpcUrl],
}, async (request) => {
  const playerAddress = wallet(request.data?.address);
  const message = request.data?.message;
  const signature = request.data?.signature;
  const challengeId = request.data?.challengeId;
  if (!playerAddress || typeof message !== "string") {
    throw new HttpsError("invalid-argument", "Valid SIWE payload required");
  }
  if (typeof challengeId !== "string") {
    throw new HttpsError("invalid-argument", "Challenge ID required");
  }
  if (typeof signature !== "string" || signature.length < 20 || signature.length > 1024) {
    throw new HttpsError("invalid-argument", "Valid wallet signature required");
  }
  await enforceRateLimit("authenticateWalletAddress", playerAddress, 10, 10 * 60);
  const challengeRef = db.collection("walletAuthChallenges").doc(challengeId);
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
    challengeRef,
    uid,
    playerAddress,
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

exports.trackTransaction = onCall({
  region,
  enforceAppCheck: true,
  secrets: [rpcUrl],
  timeoutSeconds: 60,
}, async (request) => {
  const { uid, playerAddress } = requireWalletUser(request);
  await enforceRateLimit("trackTransaction", uid, 20, 60 * 60);
  const hash = request.data?.transactionHash;
  if (typeof hash !== "string" || !/^0x[0-9a-fA-F]{64}$/.test(hash)) throw new HttpsError("invalid-argument", "Valid transaction hash required");
  const link = await db.collection("walletLinks").doc(uid).get();
  if (!link.exists || wallet(link.get("wallet")) !== playerAddress) {
    throw new HttpsError("failed-precondition", "Link wallet first");
  }

  const addresses = {
    core: publicOptionalAddress(contractAddress),
    skills: publicOptionalAddress(arenaSkillsAddressParam),
    settlement: publicOptionalAddress(roundSettlementAddressParam),
    usdc: publicOptionalAddress(usdcTokenAddressParam),
  };
  if (Object.values(addresses).some((address) => !address)) {
    throw new HttpsError("failed-precondition", "Transaction verification config is incomplete");
  }

  let transaction;
  let receipt;
  try {
    const client = walletVerificationClient();
    [transaction, receipt] = await Promise.all([
      client.getTransaction({ hash }),
      client.getTransactionReceipt({ hash }),
    ]);
  } catch (error) {
    logger.warn("Unable to read tracked transaction", {
      hash,
      error: String(error?.message || error).slice(0, 400),
    });
    throw new HttpsError("unavailable", "Transaction is not confirmed on the configured Base network");
  }
  if (normalizedAddress(transaction.from) !== playerAddress) {
    throw new HttpsError("permission-denied", "Transaction sender does not match the authenticated wallet");
  }

  let decoded;
  try {
    decoded = decodeTrackedTransaction(transaction, addresses);
  } catch (error) {
    throw new HttpsError("invalid-argument", String(error?.message || error));
  }

  const chainId = Number(chainIdParam.value());
  const reference = db.collection("transactions").doc(`${chainId}_${hash.toLowerCase()}`);
  const existing = await reference.get();
  const payload = {
    chainId: Number(chainIdParam.value()),
    transactionHash: hash.toLowerCase(),
    uid,
    wallet: playerAddress,
    status: receipt.status === "success" ? "confirmed" : "reverted",
    operation: decoded.operation,
    roundId: decoded.roundId,
    level: decoded.level,
    amount: decoded.amount,
    currency: decoded.currency,
    target: decoded.target || "",
    blockNumber: receipt.blockNumber.toString(),
    gasUsed: receipt.gasUsed.toString(),
    updatedAt: FieldValue.serverTimestamp(),
  };
  if (!existing.exists) payload.createdAt = FieldValue.serverTimestamp();
  await reference.set(payload, { merge: true });

  if ((decoded.operation === "activateRound" || decoded.operation === "activateRoundUSDC") && decoded.roundId) {
    try {
      const managerAddress = publicOptionalAddress(roundManagerAddressParam);
      if (managerAddress) {
        const provider = new JsonRpcProvider(rpcUrl.value(), Number(chainIdParam.value()));
        const manager = new Contract(managerAddress, ROUND_MANAGER_LINK_ABI, provider);
        const managerRoundId = BigInt(decoded.roundId);
        const [roundState, roundPhase] = await Promise.all([
          manager.getRoundState(managerRoundId),
          manager.getRoundPhase(managerRoundId),
        ]);
        await db.collection("roundCache").doc(decoded.roundId.toString()).set({
          occupiedCells: roundState.occupiedCells?.toString() || "0",
          phase: String(roundPhase),
          initialized: Boolean(roundState.initialized),
          settled: Boolean(roundState.settled),
          cancelled: Boolean(roundState.cancelled),
          paused: Boolean(roundState.paused),
          updatedAt: FieldValue.serverTimestamp(),
        });
      }
    } catch (cacheError) {
      logger.warn("Unable to update round cache", {
        roundId: decoded.roundId,
        error: String(cacheError?.message || cacheError).slice(0, 300),
      });
    }
  }

  return {
    tracked: true,
    status: payload.status,
    operation: decoded.operation,
  };
});

exports.contractSmokeTest = onCall({
  region,
  enforceAppCheck: true,
  timeoutSeconds: 60,
  secrets: [rpcUrl],
}, async (request) => {
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
  enforceAppCheck: false,
}, async (request) => {
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
  enforceAppCheck: false,
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
