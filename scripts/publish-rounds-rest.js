// Reconstruct configs for season 1784817498000 (already committed on-chain)
// and publish to Firestore via REST API

const admin = require("firebase-admin");
const { Wallet, TypedDataEncoder } = require("ethers");
const { buildWinningCellTree } = require("../functions/round_merkle");
const { SEASON_LEVEL_COUNT, parseSeasonManifest, roundTypes } = require("../functions/round_season_manifest");
const managerArtifact = require("../src/artifacts/EasyGameRoundManager.json");

const CHAIN_ID = 84532;
const RPC = "https://sepolia.base.org";
const MANAGER = managerArtifact.networks[String(CHAIN_ID)]?.address;
const CORE = require("../src/artifacts/EasyGameAdvance.json").networks[String(CHAIN_ID)]?.address;
const DEPLOYER_KEY = "db159ae74cad9a219a481ef9a10257ff8c088e31b56967f17486fc795d8eee4c";

const durationsHours = [24n, 48n, 72n, 96n, 144n];

async function main() {
  // Use ONE specific season that's already committed
  // Season 1784817498000 was committed in the first successful run
  const blockTimestamp = 1784817498; // known from seasonId / 1000
  const now = BigInt(blockTimestamp);
  const seasonId = now * 1000n;
  const baseStart = now + 3600n;
  const sid = seasonId.toString();

  console.log("Reconstructing season " + sid + " at timestamp " + blockTimestamp);

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
    console.log(`Level ${level}: roundId=${roundId}, startsAt=${new Date(Number(startsAt)*1000).toISOString()}, configHash=${configHash}`);
  }

  // Verify on-chain
  const { ethers } = require("ethers");
  const provider = new ethers.JsonRpcProvider(RPC, CHAIN_ID);
  const manager = new ethers.Contract(MANAGER, managerArtifact.abi, provider);
  const seasonState = await manager.getSeasonState(seasonId);
  console.log("Season committed:", seasonState.committed);

  // Compare hashes
  for (const r of rounds.slice(0, 3)) {
    const onChainHash = await manager.getCommittedRoundHash(seasonId, r.config.level);
    const match = onChainHash.toLowerCase() === r.configHash.toLowerCase();
    console.log(`L${r.config.level}: on-chain=${onChainHash}, computed=${r.configHash}, match=${match}`);
  }

  // Verify manifest
  const payload = { rounds: rounds.map((r) => ({ config: r.config, signature: r.signature, winningCells: [...r.winningCells] })) };
  const parsed = parseSeasonManifest(payload, {
    chainId: CHAIN_ID, managerAddress: MANAGER, signerAddress: deployer.address,
  });
  const rootMatch = parsed.configRoot.toLowerCase() === seasonState.configRoot.toLowerCase();
  console.log("configRoot match:", rootMatch);

  if (!rootMatch) {
    console.log("Config root MISMATCH — cannot publish");
    return;
  }

  // Initialize Firebase Admin
  // Read token from firebase-tools config
  const fs = require("fs");
  const firebaseConfig = JSON.parse(fs.readFileSync(
    require("os").homedir() + "/.config/configstore/firebase-tools.json", "utf8"
  ));
  const token = firebaseConfig.tokens.access_token;

  admin.initializeApp({ projectId: "lottery-advance" });
  const db = admin.firestore();
  
  // Set auth token
  // For REST API, we'll make direct calls
  const baseUrl = "https://firestore.googleapis.com/v1/projects/lottery-advance/databases/(default)/documents";

  // Write rounds collection
  for (const round of rounds) {
    const c = round.config;
    const docId = c.roundId.toString();
    const data = {
      fields: {
        chainId: { integerValue: String(CHAIN_ID) },
        contractAddress: { stringValue: CORE.toLowerCase() },
        roundManagerAddress: { stringValue: MANAGER.toLowerCase() },
        configHash: { stringValue: round.configHash },
        seasonConfigRoot: { stringValue: parsed.configRoot },
        seasonCommittedOnChain: { booleanValue: true },
        operatorSignature: { stringValue: round.signature },
        schemaVersion: { integerValue: "3" },
        config: {
          mapValue: {
            fields: {
              seasonId: { stringValue: sid },
              roundId: { stringValue: c.roundId.toString() },
              level: { integerValue: String(c.level) },
              startsAt: { timestampValue: new Date(Number(c.startsAt)*1000).toISOString() },
              entriesCloseAt: { timestampValue: new Date(Number(c.entriesCloseAt)*1000).toISOString() },
              endsAt: { timestampValue: new Date(Number(c.endsAt)*1000).toISOString() },
              freezeClosesAt: { timestampValue: new Date(Number(c.freezeClosesAt)*1000).toISOString() },
              maxPlayers: { integerValue: String(c.maxPlayers) },
              maxWinners: { integerValue: String(c.maxWinners) },
              winningCellsRoot: { stringValue: c.winningCellsRoot },
              ethPriceWei: { stringValue: c.ethPrice.toString() },
              usdcPrice: { stringValue: c.usdcPrice.toString() },
              freezeLimit: { integerValue: String(c.freezeLimit) },
              paymentSplitVersion: { integerValue: String(c.paymentSplitVersion) },
            },
          },
        },
      },
    };

    // Use batch commit
    // For simplicity, do individual writes
    const url = `${baseUrl}/rounds?documentId=${docId}`;
    const res = await fetch(url, {
      method: "POST",
      headers: { 
        "Authorization": `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(data),
    });
    const result = await res.json();
    if (result.error) {
      console.log(`Level ${c.level} doc error: ${result.error.message}`);
    } else {
      console.log(`Level ${c.level} doc ${docId} created OK`);
    }

    // Write winningCells subcollection
    for (let i = 0; i < round.winningCells.length; i++) {
      const cellId = round.winningCells[i].toString();
      const cellUrl = `${baseUrl}/rounds/${docId}/winningCells?documentId=${cellId}`;
      const cellData = {
        fields: {
          cellId: { stringValue: cellId },
          proof: { arrayValue: { values: round.proofs[i].map(p => ({ stringValue: p })) } },
        },
      };
      const cellRes = await fetch(cellUrl, {
        method: "POST",
        headers: { 
          "Authorization": `Bearer ${token}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(cellData),
      });
      const cellResult = await cellRes.json();
      if (cellResult.error) {
        console.log(`  winningCells/${cellId} error: ${cellResult.error.message}`);
      }
    }
  }

  // Write season summary
  const seasonDocUrl = `${baseUrl}/seasons?documentId=${sid}`;
  const seasonData = {
    fields: {
      seasonId: { stringValue: sid },
      chainId: { integerValue: String(CHAIN_ID) },
      contractAddress: { stringValue: CORE.toLowerCase() },
      roundManagerAddress: { stringValue: MANAGER.toLowerCase() },
      configRoot: { stringValue: parsed.configRoot },
      committedOnChain: { booleanValue: true },
      firstStartsAt: { timestampValue: new Date(Number(parsed.firstStartsAt)*1000).toISOString() },
      lastEndsAt: { timestampValue: new Date(Number(parsed.lastEndsAt)*1000).toISOString() },
      schemaVersion: { integerValue: "3" },
    },
  };

  const seasonRes = await fetch(seasonDocUrl, {
    method: "POST",
    headers: { 
      "Authorization": `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(seasonData),
  });
  const seasonResult = await seasonRes.json();
  if (seasonResult.error) {
    console.log("Season doc error:", seasonResult.error.message);
  } else {
    console.log("Season doc created OK");
  }

  console.log("Done!");
}

main().catch((e) => console.error(e.message || e));
