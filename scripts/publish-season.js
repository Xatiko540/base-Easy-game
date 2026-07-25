const admin = require("firebase-admin");
const { Wallet, Contract, JsonRpcProvider, TypedDataEncoder } = require("ethers");
const { buildWinningCellTree } = require("../functions/round_merkle");
const { SEASON_LEVEL_COUNT, parseSeasonManifest, roundTypes } = require("../functions/round_season_manifest");
const coreArtifact = require("../src/artifacts/EasyGameAdvance.json");
const managerArtifact = require("../src/artifacts/EasyGameRoundManager.json");

const CHAIN_ID = 84532;
const RPC = "https://sepolia.base.org";
const CORE = coreArtifact.networks[String(CHAIN_ID)]?.address;
const MANAGER = managerArtifact.networks[String(CHAIN_ID)]?.address;
const DEPLOYER_KEY = "db159ae74cad9a219a481ef9a10257ff8c088e31b56967f17486fc795d8eee4c";

if (!CORE) throw new Error("No core address found for chain " + CHAIN_ID);
if (!MANAGER) throw new Error("No manager address found for chain " + CHAIN_ID);

admin.initializeApp({ projectId: "lottery-advance" });
const db = admin.firestore();

const durationsHours = [24n, 48n, 72n, 96n, 144n];

async function buildSeason(block) {
  const now = BigInt(block.timestamp);
  const seasonId = now * 1000n;
  const baseStart = now + 3600n;
  const deployer = new Wallet(DEPLOYER_KEY);
  const domain = { name: "EasyGameAdvance", version: "2", chainId: CHAIN_ID, verifyingContract: MANAGER };

  const rounds = [];
  for (let level = 1; level <= SEASON_LEVEL_COUNT; level++) {
    const roundId = seasonId * 100n + BigInt(level);
    const startsAt = baseStart + BigInt(level - 1) * 5n * 3600n;
    const durationHours = durationsHours[(level - 1) % durationsHours.length];
    const endsAt = startsAt + durationHours * 3600n;
    const winningCells = [7n, 15n];
    const tree = buildWinningCellTree(roundId, winningCells);
    const config = {
      seasonId, roundId, level,
      startsAt,
      entriesCloseAt: startsAt + (endsAt - startsAt) / 2n,
      endsAt, freezeClosesAt: endsAt,
      maxPlayers: 1_000_000, maxWinners: winningCells.length,
      winningCellsRoot: tree.root,
      ethPrice: 100_000_000_000_000n, usdcPrice: 100_000n,
      freezeLimit: Number(((durationHours + 23n) / 24n) * 10n),
      paymentSplitVersion: 1,
    };
    const signature = await deployer.signTypedData(domain, roundTypes, config);
    const configHash = TypedDataEncoder.hashStruct("RoundConfig", roundTypes, config);
    rounds.push({ config, signature, winningCells, proofs: tree.proofs, configHash });
  }
  return { seasonId, rounds, baseStart };
}

async function main() {
  const provider = new JsonRpcProvider(RPC, CHAIN_ID);
  const block = await provider.getBlock("latest");
  const { seasonId, rounds, baseStart } = await buildSeason(block);
  const sid = seasonId.toString();

  console.log("Season ID:", sid);
  console.log("First startsAt:", new Date(Number(baseStart) * 1000).toISOString());

  // Commit on-chain
  const deployer = new Wallet(DEPLOYER_KEY, provider);
  const manager = new Contract(MANAGER, managerArtifact.abi, deployer);

  console.log("Checking on-chain state...");
  const seasonState = await manager.getSeasonState(seasonId);
  if (seasonState.committed) {
    console.log("Season already committed on-chain");
  } else {
    console.log("Committing season on-chain...");
    const configs = rounds.map((r) => r.config);
    const signatures = rounds.map((r) => r.signature);
    const tx = await deployer.sendTransaction({
      to: MANAGER,
      data: new (require("ethers").Interface)(managerArtifact.abi).encodeFunctionData("commitSeason", [configs, signatures]),
      gasLimit: 5_000_000n,
    });
    const receipt = await tx.wait();
    if (receipt.status === 0) throw new Error("commitSeason reverted");
    console.log("Committed tx:", receipt.hash);
  }

  const updatedState = await manager.getSeasonState(seasonId);
  if (!updatedState.committed) throw new Error("Season not committed after tx");
  console.log("configRoot:", updatedState.configRoot);

  // Verify
  const scheduleSigner = new Wallet(DEPLOYER_KEY);
  const payload = { rounds: rounds.map((r) => ({ config: r.config, signature: r.signature, winningCells: [...r.winningCells] })) };
  const parsed = parseSeasonManifest(payload, {
    chainId: CHAIN_ID, managerAddress: MANAGER, signerAddress: scheduleSigner.address,
  });
  if (parsed.configRoot.toLowerCase() !== updatedState.configRoot.toLowerCase()) {
    throw new Error("Config root mismatch");
  }
  console.log("Manifest verified OK");

  // Write to Firestore
  const seasonRef = db.collection("seasons").doc(sid);
  const existingSeason = await seasonRef.get();
  if (existingSeason.exists) {
    console.log("Season already published to Firestore — still writing rounds");
  }

  const levelStarts = {};
  const roundIdsByLevel = {};
  for (const round of rounds) {
    levelStarts[round.config.level.toString()] = round.config.startsAt.toString();
    roundIdsByLevel[round.config.level.toString()] = round.config.roundId.toString();
  }

  const batch = db.batch();

  if (!existingSeason.exists) {
    batch.set(seasonRef, {
      seasonId: sid, chainId: CHAIN_ID,
      contractAddress: CORE.toLowerCase(), roundManagerAddress: MANAGER.toLowerCase(),
      configRoot: parsed.configRoot, committedOnChain: true,
      firstStartsAt: admin.firestore.Timestamp.fromMillis(Number(parsed.firstStartsAt) * 1000),
      lastEndsAt: admin.firestore.Timestamp.fromMillis(Number(parsed.lastEndsAt) * 1000),
      levelStarts, roundIdsByLevel, schemaVersion: 3,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  for (const round of rounds) {
    const c = round.config;
    const roundRef = db.collection("rounds").doc(c.roundId.toString());
    // Use set (merge: false, but with a check) — skip if exists
    const existing = await roundRef.get();
    if (existing.exists) {
      console.log(`  Level ${c.level} round ${c.roundId} already exists — skipping`);
      continue;
    }
    batch.set(roundRef, {
      chainId: CHAIN_ID, contractAddress: CORE.toLowerCase(),
      roundManagerAddress: MANAGER.toLowerCase(),
      configHash: round.configHash, seasonConfigRoot: parsed.configRoot,
      seasonCommittedOnChain: true, operatorSignature: round.signature, schemaVersion: 3,
      config: {
        seasonId: sid, roundId: c.roundId.toString(), level: Number(c.level),
        startsAt: admin.firestore.Timestamp.fromMillis(Number(c.startsAt) * 1000),
        entriesCloseAt: admin.firestore.Timestamp.fromMillis(Number(c.entriesCloseAt) * 1000),
        endsAt: admin.firestore.Timestamp.fromMillis(Number(c.endsAt) * 1000),
        freezeClosesAt: admin.firestore.Timestamp.fromMillis(Number(c.freezeClosesAt) * 1000),
        maxPlayers: Number(c.maxPlayers), maxWinners: Number(c.maxWinners),
        winningCellsRoot: c.winningCellsRoot, ethPriceWei: c.ethPrice.toString(),
        usdcPrice: c.usdcPrice.toString(), freezeLimit: Number(c.freezeLimit),
        paymentSplitVersion: Number(c.paymentSplitVersion),
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    round.winningCells.forEach((cellId, cellIndex) => {
      const cellRef = roundRef.collection("winningCells").doc(cellId.toString());
      batch.set(cellRef, {
        cellId: cellId.toString(), proof: round.proofs[cellIndex],
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });
  }

  await batch.commit();
  console.log("Published to Firestore OK");

  console.log(JSON.stringify({
    status: "published",
    seasonId: sid,
    configRoot: parsed.configRoot,
    firstStartsAt: new Date(Number(parsed.firstStartsAt) * 1000).toISOString(),
    lastEndsAt: new Date(Number(parsed.lastEndsAt) * 1000).toISOString(),
  }, null, 2));
}

main().catch((e) => console.error(e.message || e));
