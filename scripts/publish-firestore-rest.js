const https = require("https");
const { Wallet, JsonRpcProvider, Contract, TypedDataEncoder } = require("ethers");
const { buildWinningCellTree } = require("../functions/round_merkle");
const { SEASON_LEVEL_COUNT, parseSeasonManifest, roundTypes } = require("../functions/round_season_manifest");
const managerArtifact = require("../src/artifacts/EasyGameRoundManager.json");

const CHAIN_ID = 84532;
const RPC = "https://sepolia.base.org";
const MANAGER = managerArtifact.networks[String(CHAIN_ID)]?.address;
const DEPLOYER_KEY = "db159ae74cad9a219a481ef9a10257ff8c088e31b56967f17486fc795d8eee4c";
const PROJECT = "lottery-advance";
const durationsHours = [24n, 48n, 72n, 96n, 144n];

function v(x) {
  if (typeof x === "string") return { stringValue: x };
  if (typeof x === "number") return { integerValue: String(x) };
  if (x instanceof Date) return { timestampValue: x.toISOString() };
  if (typeof x === "boolean") return { booleanValue: x };
  if (x === null || x === undefined) return { nullValue: null };
  if (Array.isArray(x)) return { arrayValue: { values: x.map(v) } };
  if (typeof x === "object") {
    const f = {};
    for (const [k, val] of Object.entries(x)) f[k] = v(val);
    return { mapValue: { fields: f } };
  }
  return { stringValue: String(x) };
}

function doc(fields) {
  return { fields: Object.fromEntries(Object.entries(fields).map(([k, val]) => [k, v(val)])) };
}

function api(path, method, body, token) {
  return new Promise((resolve, reject) => {
    const url = `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents${path}`;
    const b = body ? JSON.stringify(body) : "";
    const req = https.request(url, {
      method,
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${token}`,
        ...(b ? { "Content-Length": Buffer.byteLength(b) } : {}),
      },
    }, (res) => {
      let data = "";
      res.on("data", (c) => data += c);
      res.on("end", () => {
        if (res.statusCode < 300) resolve(JSON.parse(data));
        else reject(new Error(`HTTP ${res.statusCode}: ${data.slice(0, 300)}`));
      });
    });
    req.on("error", reject);
    if (b) req.write(b);
    req.end();
  });
}

async function main() {
  const cfgPath = require("path").join(require("os").homedir(), ".config/configstore/firebase-tools.json");
  const { tokens } = JSON.parse(require("fs").readFileSync(cfgPath, "utf8"));
  const token = tokens.access_token;
  console.log("Got Firebase token");

  const provider = new JsonRpcProvider(RPC, CHAIN_ID);
  const block = await provider.getBlock("latest");
  const now = BigInt(block.timestamp);
  const seasonId = now * 1000n;
  const baseStart = now + 3600n;

  const deployer = new Wallet(DEPLOYER_KEY);
  const domain = { name: "EasyGameAdvance", version: "2", chainId: CHAIN_ID, verifyingContract: MANAGER };

  const rounds = [];
  for (let level = 1; level <= SEASON_LEVEL_COUNT; level++) {
    const roundId = seasonId * 100n + BigInt(level);
    const startsAt = baseStart + BigInt(level - 1) * 5n * 3600n;
    const dh = durationsHours[(level - 1) % durationsHours.length];
    const endsAt = startsAt + dh * 3600n;
    const winningCells = [7n, 15n];
    const tree = buildWinningCellTree(roundId, winningCells);
    const config = {
      seasonId, roundId, level, startsAt,
      entriesCloseAt: startsAt + (endsAt - startsAt) / 2n, endsAt, freezeClosesAt: endsAt,
      maxPlayers: 1_000_000, maxWinners: winningCells.length, winningCellsRoot: tree.root,
      ethPrice: 100_000_000_000_000n, usdcPrice: 100_000n,
      freezeLimit: Number(((dh + 23n) / 24n) * 10n), paymentSplitVersion: 1,
    };
    const sig = await deployer.signTypedData(domain, roundTypes, config);
    const configHash = TypedDataEncoder.hashStruct("RoundConfig", roundTypes, config);
    rounds.push({ config, sig, winningCells, proofs: tree.proofs, configHash });
  }

  const manager = new Contract(MANAGER, managerArtifact.abi, provider);
  let state = await manager.getSeasonState(seasonId);
  if (!state.committed) {
    console.log("Committing on-chain...");
    const iface = new (require("ethers").Interface)(managerArtifact.abi);
    const walletSigner = new Wallet(DEPLOYER_KEY, provider);
    const tx = await walletSigner.sendTransaction({
      to: MANAGER, gasLimit: 5_000_000n,
      data: iface.encodeFunctionData("commitSeason", [rounds.map((r) => r.config), rounds.map((r) => r.sig)]),
    });
    const receipt = await tx.wait();
    if (receipt.status === 0) throw new Error("Reverted");
    console.log("Committed:", receipt.hash);
    state = await manager.getSeasonState(seasonId);
  }

  const payload = { rounds: rounds.map((r) => ({ config: r.config, signature: r.sig, winningCells: [...r.winningCells] })) };
  const parsed = parseSeasonManifest(payload, {
    chainId: CHAIN_ID, managerAddress: MANAGER, signerAddress: deployer.address,
  });
  if (parsed.configRoot.toLowerCase() !== state.configRoot.toLowerCase()) throw new Error("Root mismatch");
  console.log("Verified on-chain");

  // Write season
  const seasonIdStr = seasonId.toString();
  try {
    await api(`/seasons?documentId=${seasonIdStr}`, "POST", doc({
      seasonId: seasonIdStr, chainId: CHAIN_ID,
      contractAddress: require("../src/artifacts/EasyGameAdvance.json").networks[String(CHAIN_ID)].address.toLowerCase(),
      roundManagerAddress: MANAGER.toLowerCase(),
      configRoot: parsed.configRoot, committedOnChain: true,
      firstStartsAt: new Date(Number(parsed.firstStartsAt) * 1000),
      lastEndsAt: new Date(Number(parsed.lastEndsAt) * 1000),
      schemaVersion: 3,
    }), token);
  } catch (e) {
    if (e.message.includes("409") || e.message.includes("already exists")) {
      console.log("Season already exists");
    } else throw e;
  }
  console.log("Season written");

  // Write rounds
  for (const round of rounds) {
    const c = round.config;
    const rid = c.roundId.toString();
    try {
      await api(`/rounds?documentId=${rid}`, "POST", doc({
        chainId: CHAIN_ID,
        contractAddress: require("../src/artifacts/EasyGameAdvance.json").networks[String(CHAIN_ID)].address.toLowerCase(),
        roundManagerAddress: MANAGER.toLowerCase(),
        configHash: round.configHash, seasonConfigRoot: parsed.configRoot,
        seasonCommittedOnChain: true, operatorSignature: round.sig, schemaVersion: 3,
      }), token);
    } catch (e) {
      if (e.message.includes("409") || e.message.includes("already exists")) {
        console.log(`L${c.level} already exists`);
        continue;
      }
      throw e;
    }

    // Write config sub-fields
    const cfgData = {
      seasonId: c.seasonId.toString(), roundId: rid, level: Number(c.level),
      startsAt: new Date(Number(c.startsAt) * 1000),
      entriesCloseAt: new Date(Number(c.entriesCloseAt) * 1000),
      endsAt: new Date(Number(c.endsAt) * 1000),
      freezeClosesAt: new Date(Number(c.freezeClosesAt) * 1000),
      maxPlayers: Number(c.maxPlayers), maxWinners: Number(c.maxWinners),
      winningCellsRoot: c.winningCellsRoot,
      ethPriceWei: c.ethPrice.toString(), usdcPrice: c.usdcPrice.toString(),
      freezeLimit: Number(c.freezeLimit), paymentSplitVersion: Number(c.paymentSplitVersion),
    };
    await api(`/rounds/${rid}?updateMask.fieldPaths=config`, "PATCH",
      { fields: { config: v(cfgData) } }, token);

    // Write winning cells
    for (let i = 0; i < round.winningCells.length; i++) {
      const cellId = round.winningCells[i];
      await api(
        `/rounds/${rid}/winningCells?documentId=${cellId.toString()}`,
        "POST",
        doc({ cellId: cellId.toString(), proof: round.proofs[i] }),
        token,
      ).catch((e) => {
        if (!e.message.includes("409")) throw e;
      });
    }
    console.log(`L${c.level} OK`);
  }

  console.log("Done:", seasonIdStr);
}

main().catch((e) => console.error(e.message || e));
