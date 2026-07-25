const { Wallet, JsonRpcProvider, TypedDataEncoder } = require("ethers");
const { buildWinningCellTree } = require("../functions/round_merkle");
const { SEASON_LEVEL_COUNT, parseSeasonManifest, roundTypes } = require("../functions/round_season_manifest");
const managerArtifact = require("../src/artifacts/EasyGameRoundManager.json");
const coreArtifact = require("../src/artifacts/EasyGameAdvance.json");

const CHAIN_ID = 84532;
const RPC = "https://sepolia.base.org";
const CORE = coreArtifact.networks[String(CHAIN_ID)]?.address;
const MANAGER = managerArtifact.networks[String(CHAIN_ID)]?.address;
const DEPLOYER_KEY = "db159ae74cad9a219a481ef9a10257ff8c088e31b56967f17486fc795d8eee4c";
const SEASON_ID = "1784819298000";
const BLOCK_TS = 1784819298;

const durationsHours = [24n, 48n, 72n, 96n, 144n];

async function main() {
  const now = BigInt(BLOCK_TS);
  const seasonId = BigInt(SEASON_ID);
  const baseStart = now + 60n;
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

  const provider = new JsonRpcProvider(RPC, CHAIN_ID);
  const manager = new (require("ethers").Contract)(MANAGER, managerArtifact.abi, provider);
  const state = await manager.getSeasonState(seasonId);
  if (!state.committed) throw new Error("Season not committed on-chain");
  console.log("Season committed, configRoot:", state.configRoot);

  // Verify hashes
  for (const r of [rounds[0], rounds[8], rounds[16]]) {
    const hash = await manager.getCommittedRoundHash(seasonId, r.config.level);
    const ok = hash.toLowerCase() === r.configHash.toLowerCase();
    console.log(`L${r.config.level} hash match:`, ok);
  }

  // Publish via REST
  const fs = require("fs");
  const firebaseConfig = JSON.parse(fs.readFileSync(require("os").homedir() + "/.config/configstore/firebase-tools.json", "utf8"));
  const token = firebaseConfig.tokens.access_token;
  const baseUrl = "https://firestore.googleapis.com/v1/projects/lottery-advance/databases/(default)/documents";

  for (const round of rounds) {
    const c = round.config;
    const docId = c.roundId.toString();
    const data = {
      fields: {
        chainId: { integerValue: String(CHAIN_ID) },
        contractAddress: { stringValue: CORE.toLowerCase() },
        roundManagerAddress: { stringValue: MANAGER.toLowerCase() },
        configHash: { stringValue: round.configHash },
        seasonConfigRoot: { stringValue: state.configRoot },
        seasonCommittedOnChain: { booleanValue: true },
        operatorSignature: { stringValue: round.signature },
        schemaVersion: { integerValue: "3" },
        config: {
          mapValue: {
            fields: {
              seasonId: { stringValue: SEASON_ID },
              roundId: { stringValue: c.roundId.toString() },
              level: { integerValue: String(c.level) },
              startsAt: { timestampValue: new Date(Number(c.startsAt) * 1000).toISOString() },
              entriesCloseAt: { timestampValue: new Date(Number(c.entriesCloseAt) * 1000).toISOString() },
              endsAt: { timestampValue: new Date(Number(c.endsAt) * 1000).toISOString() },
              freezeClosesAt: { timestampValue: new Date(Number(c.freezeClosesAt) * 1000).toISOString() },
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

    const res = await fetch(`${baseUrl}/rounds?documentId=${docId}`, {
      method: "POST",
      headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
      body: JSON.stringify(data),
    });
    const result = await res.json();
    if (result.error) { console.log(`L${c.level} error: ${result.error.message}`); }
    else { console.log(`L${c.level} doc ${docId} created`); }

    for (let i = 0; i < round.winningCells.length; i++) {
      const cellId = round.winningCells[i].toString();
      await fetch(`${baseUrl}/rounds/${docId}/winningCells?documentId=${cellId}`, {
        method: "POST",
        headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
        body: JSON.stringify({
          fields: { cellId: { stringValue: cellId }, proof: { arrayValue: { values: round.proofs[i].map(p => ({ stringValue: p })) } } },
        }),
      });
    }
  }

  const seasonRes = await fetch(`${baseUrl}/seasons?documentId=${SEASON_ID}`, {
    method: "POST",
    headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      fields: {
        seasonId: { stringValue: SEASON_ID },
        chainId: { integerValue: String(CHAIN_ID) },
        contractAddress: { stringValue: CORE.toLowerCase() },
        roundManagerAddress: { stringValue: MANAGER.toLowerCase() },
        configRoot: { stringValue: state.configRoot },
        committedOnChain: { booleanValue: true },
        schemaVersion: { integerValue: "3" },
      },
    }),
  });
  const sr = await seasonRes.json();
  if (sr.error) console.log("Season doc error:", sr.error.message);
  else console.log("Season doc created");

  console.log("Done!");
}

main().catch(e => console.error(e.message || e));
