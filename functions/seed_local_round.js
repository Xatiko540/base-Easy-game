const { initializeApp } = require("firebase-admin/app");
const { getFirestore, Timestamp, FieldValue } = require("firebase-admin/firestore");
const { Contract, HDNodeWallet, JsonRpcProvider } = require("ethers");

const coreArtifact = require("../src/artifacts/EasyGameAdvance.json");
const managerArtifact = require("../src/artifacts/EasyGameRoundManager.json");
const { buildSignedSeasonManifest } = require("./season_manifest_builder");
const { parseSeasonManifest } = require("./round_season_manifest");

process.env.FIRESTORE_EMULATOR_HOST ||= "127.0.0.1:8080";
initializeApp({ projectId: "lottery-advance" });

const chainId = 31337;
const coreAddress = coreArtifact.networks[String(chainId)]?.address;
const managerAddress = managerArtifact.networks[String(chainId)]?.address;
if (!coreAddress || !managerAddress) {
  throw new Error("Deploy local contracts before seeding the season");
}

const mnemonic = "test test test test test test test test test test test junk";

function localSeasonSpec(now) {
  return {
    seasonId: String(now),
    firstStartsAt: String(now - 5),
    levelOpenIntervalSeconds: String(5 * 60 * 60),
    entryWindowSeconds: Array.from({ length: 17 }, () => String(6 * 60 * 60)),
    roundDurationSeconds: Array.from(
      { length: 17 },
      (_, index) => String(24 * 60 * 60 + index * 60 * 60),
    ),
    maxPlayers: "1024",
    ethPricesWei: Array.from({ length: 17 }, () => "100000000000000"),
    usdcPrices: Array.from({ length: 17 }, () => "100000"),
    winningCellsByLevel: Array.from({ length: 17 }, () => ["7", "15", "31"]),
  };
}

async function clearLocalSchedule(db) {
  const previousRounds = await db.collection("rounds").where("chainId", "==", chainId).get();
  const previousSeasons = await db.collection("seasons").where("chainId", "==", chainId).get();
  if (previousRounds.empty && previousSeasons.empty) return;

  const cleanup = db.batch();
  for (const document of previousRounds.docs) {
    const cells = await document.ref.collection("winningCells").get();
    cells.docs.forEach((cell) => cleanup.delete(cell.ref));
    cleanup.delete(document.ref);
  }
  previousSeasons.docs.forEach((document) => cleanup.delete(document.ref));
  await cleanup.commit();
}

async function main() {
  const provider = new JsonRpcProvider("http://127.0.0.1:8545", chainId);
  const signer = HDNodeWallet.fromPhrase(mnemonic).connect(provider);
  const manager = new Contract(managerAddress, managerArtifact.abi, signer);
  const game = new Contract(coreAddress, coreArtifact.abi, provider);
  const payload = await buildSignedSeasonManifest(
    localSeasonSpec(Math.floor(Date.now() / 1000)),
    { chainId, managerAddress, signer },
  );
  const season = parseSeasonManifest(payload, {
    chainId,
    managerAddress,
    signerAddress: signer.address,
  });

  for (const round of season.rounds) {
    if (!(await manager.verifyRoundConfig(round.config, round.signature))) {
      throw new Error(`Round manager rejected level ${round.config.level}`);
    }
  }
  const commit = await manager.commitSeason(
    season.rounds.map((round) => round.config),
    season.rounds.map((round) => round.signature),
  );
  const commitReceipt = await commit.wait();
  const chainSeason = await manager.getSeasonState(season.seasonId);
  if (!chainSeason.committed || chainSeason.configRoot !== season.configRoot) {
    throw new Error("Local on-chain season commitment does not match the manifest");
  }

  const players = Array.from({ length: 7 }, (_, index) =>
    HDNodeWallet.fromPhrase(
      mnemonic,
      "",
      `m/44'/60'/0'/0/${index}`,
    ).connect(provider),
  );
  const firstRound = season.rounds[0];
  for (let index = 0; index < players.length; index += 1) {
    const inviter = index === 0
      ? "0x0000000000000000000000000000000000000000"
      : players[0].address;
    const transaction = await game.connect(players[index]).activateRound(
      firstRound.config,
      firstRound.signature,
      inviter,
      { value: firstRound.config.ethPrice },
    );
    await transaction.wait();
  }

  const db = getFirestore();
  await clearLocalSchedule(db);
  const batch = db.batch();
  const seasonRef = db.collection("seasons").doc(season.seasonId.toString());
  const levelStarts = {};
  const roundIdsByLevel = {};
  season.rounds.forEach((round) => {
    levelStarts[round.config.level.toString()] = round.config.startsAt.toString();
    roundIdsByLevel[round.config.level.toString()] = round.config.roundId.toString();
  });
  batch.create(seasonRef, {
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
    title: "Local committed development season",
    schemaVersion: 3,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });

  season.rounds.forEach((round) => {
    const config = round.config;
    const roundRef = db.collection("rounds").doc(config.roundId.toString());
    batch.create(roundRef, {
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
    round.winningCells.forEach((cellId, index) => {
      batch.create(roundRef.collection("winningCells").doc(cellId.toString()), {
        cellId: cellId.toString(),
        proof: round.proofs[index],
        createdAt: FieldValue.serverTimestamp(),
      });
    });
  });
  await batch.commit();

  await db.collection("users").doc(`${chainId}_${signer.address.toLowerCase()}`).set({
    wallet: signer.address.toLowerCase(),
    chainId,
    exists: true,
    walletVerified: false,
    profileVersion: 1,
    localDevelopmentProfile: true,
    registeredAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });

  console.log(JSON.stringify({
    seasonId: season.seasonId.toString(),
    configRoot: season.configRoot,
    levels: season.rounds.length,
    commitmentTransaction: commitReceipt.hash,
    coreAddress,
    managerAddress,
    scheduleSigner: signer.address,
    participants: players.map((player) => player.address),
  }, null, 2));
}

main().catch((error) => {
  console.error(error.message || error);
  process.exitCode = 1;
});
