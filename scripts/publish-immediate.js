const admin = require("firebase-admin");
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

if (!CORE || !MANAGER) throw new Error("No contract addresses found");

const durationsHours = [24n, 48n, 72n, 96n, 144n];

async function main() {
  const provider = new JsonRpcProvider(RPC, CHAIN_ID);
  const block = await provider.getBlock("latest");
  const now = BigInt(block.timestamp);
  const seasonId = now * 1000n;
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

  // Commit on-chain
  const deployerWallet = new Wallet(DEPLOYER_KEY, provider);
  const iface = new (require("ethers").Interface)(managerArtifact.abi);
  const configs = rounds.map((r) => r.config);
  const signatures = rounds.map((r) => r.signature);

  console.log("Season ID:", seasonId.toString());
  console.log("L1 starts:", new Date(Number(baseStart) * 1000).toISOString());

  const seasonState = await deployerWallet.sendTransaction({
    to: MANAGER,
    data: iface.encodeFunctionData("commitSeason", [configs, signatures]),
    gasLimit: 5_000_000n,
  });
  const receipt = await seasonState.wait();
  if (receipt.status === 0) throw new Error("commitSeason reverted");
  console.log("Committed:", receipt.hash);

  // Verify
  const manager = new (require("ethers").Contract)(MANAGER, managerArtifact.abi, provider);
  const state = await manager.getSeasonState(seasonId);
  if (!state.committed) throw new Error("Not committed");
  console.log("configRoot:", state.configRoot);

  const payload = { rounds: rounds.map((r) => ({ config: r.config, signature: r.signature, winningCells: [...r.winningCells] })) };
  const parsed = parseSeasonManifest(payload, { chainId: CHAIN_ID, managerAddress: MANAGER, signerAddress: deployer.address });
  if (parsed.configRoot.toLowerCase() !== state.configRoot.toLowerCase()) throw new Error("Root mismatch");

  // Write to Firestore via REST
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
        seasonConfigRoot: { stringValue: parsed.configRoot },
        seasonCommittedOnChain: { booleanValue: true },
        operatorSignature: { stringValue: round.signature },
        schemaVersion: { integerValue: "3" },
        config: {
          mapValue: {
            fields: {
              seasonId: { stringValue: seasonId.toString() },
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
    if (result.error) { console.log(`L${c.level} doc error: ${result.error.message}`); }
    else { console.log(`L${c.level} doc ${docId} created`); }

    for (let i = 0; i < round.winningCells.length; i++) {
      const cellId = round.winningCells[i].toString();
      const cellRes = await fetch(`${baseUrl}/rounds/${docId}/winningCells?documentId=${cellId}`, {
        method: "POST",
        headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
        body: JSON.stringify({
          fields: {
            cellId: { stringValue: cellId },
            proof: { arrayValue: { values: round.proofs[i].map(p => ({ stringValue: p })) } },
          },
        }),
      });
    }
  }

  // Season summary doc
  const seasonRes = await fetch(`${baseUrl}/seasons?documentId=${seasonId.toString()}`, {
    method: "POST",
    headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      fields: {
        seasonId: { stringValue: seasonId.toString() },
        chainId: { integerValue: String(CHAIN_ID) },
        contractAddress: { stringValue: CORE.toLowerCase() },
        roundManagerAddress: { stringValue: MANAGER.toLowerCase() },
        configRoot: { stringValue: parsed.configRoot },
        committedOnChain: { booleanValue: true },
        firstStartsAt: { timestampValue: new Date(Number(parsed.firstStartsAt) * 1000).toISOString() },
        lastEndsAt: { timestampValue: new Date(Number(parsed.lastEndsAt) * 1000).toISOString() },
        schemaVersion: { integerValue: "3" },
      },
    }),
  });
  const sr = await seasonRes.json();
  if (sr.error) console.log("Season doc error:", sr.error.message);
  else console.log("Season doc created");

  console.log("Done! Season", seasonId.toString());
}

main().catch(e => console.error(e.message || e));
