const {
  db,
  FieldValue,
  Timestamp,
  HttpsError,
  chainIdParam,
  environmentParam,
  hashId,
  wallet,
} = require("./config");

function walletFirebaseUid(playerAddress) {
  return `wallet_${hashId(`${chainIdParam.value()}:${playerAddress}`).slice(0, 64)}`;
}

async function storeAuthenticatedWallet({
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

module.exports = {
  walletFirebaseUid,
  storeAuthenticatedWallet,
  requireUser,
  requireWalletUser,
  requireAdmin,
  requireApp,
  enforceRateLimit,
};
