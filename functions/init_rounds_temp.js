const { JsonRpcProvider, Contract, Wallet } = require("ethers");
const https = require("https");

const RPC = "https://sepolia.base.org";
const CHAIN_ID = 84532;
const MANAGER = "0x62AC456b26847eb74f039C0Eb34ea661F939726B";
const ADMIN_PK = "0xef16589ee5ef136266d874e3efb228149996fdc3dd674ae785d6eaf79152fcba";
const API_KEY = "AIzaSyChJ_be6rHgJ1q8VjTUmuqpI2N-ZwX-tk4";

async function fetchRoundConfigs() {
  return new Promise((resolve, reject) => {
    const url = `https://firestore.googleapis.com/v1/projects/lottery-advance/databases/(default)/documents/rounds?pageSize=50&key=${API_KEY}`;
    https.get(url, (r) => {
      let data = "";
      r.on("data", (c) => data += c);
      r.on("end", () => {
        try {
          const docs = JSON.parse(data).documents || [];
          const rounds = {};
          for (const doc of docs) {
            const roundId = doc.name.split("/").pop();
            const level = parseInt(roundId.slice(-2));
            const f = doc.fields;
            const cfg = f.config.mapValue.fields;
            const sig = f.operatorSignature.stringValue;

            rounds[level] = {
              config: {
                seasonId: BigInt(cfg.seasonId.stringValue),
                roundId: BigInt(cfg.roundId.stringValue),
                level: Number(cfg.level.integerValue),
                startsAt: Math.floor(new Date(cfg.startsAt.timestampValue).getTime() / 1000),
                entriesCloseAt: Math.floor(new Date(cfg.entriesCloseAt.timestampValue).getTime() / 1000),
                endsAt: Math.floor(new Date(cfg.endsAt.timestampValue).getTime() / 1000),
                freezeClosesAt: Math.floor(new Date(cfg.freezeClosesAt.timestampValue).getTime() / 1000),
                maxPlayers: Number(cfg.maxPlayers.integerValue),
                maxWinners: Number(cfg.maxWinners.integerValue),
                winningCellsRoot: cfg.winningCellsRoot.stringValue,
                ethPrice: BigInt(cfg.ethPriceWei.stringValue),
                usdcPrice: BigInt(cfg.usdcPrice.stringValue),
                freezeLimit: Number(cfg.freezeLimit.integerValue),
                paymentSplitVersion: Number(cfg.paymentSplitVersion.integerValue),
              },
              signature: sig,
            };
          }
          resolve(rounds);
        } catch (e) { reject(e); }
      });
    }).on("error", reject);
  });
}

async function main() {
  const rounds = await fetchRoundConfigs();
  const provider = new JsonRpcProvider(RPC, CHAIN_ID);
  const adminWallet = new Wallet(ADMIN_PK, provider);

  const MANAGER_ABI = [
    "function initializeRound(tuple(uint256 seasonId, uint256 roundId, uint8 level, uint64 startsAt, uint64 entriesCloseAt, uint64 endsAt, uint64 freezeClosesAt, uint32 maxPlayers, uint16 maxWinners, bytes32 winningCellsRoot, uint256 ethPrice, uint256 usdcPrice, uint16 freezeLimit, uint16 paymentSplitVersion) config, bytes signature) returns (bytes32)",
    "function roundBySeasonLevel(uint256, uint8) view returns (uint256)",
  ];

  const manager = new Contract(MANAGER, MANAGER_ABI, adminWallet);
  const block = await provider.getBlock("latest");
  const now = Number(block.timestamp);
  console.log("Current:", new Date(now * 1000).toISOString());

  for (let lv = 7; lv <= 14; lv++) {
    if (!rounds[lv]) continue;
    const r = rounds[lv];
    const existing = await manager.roundBySeasonLevel(2026071902n, lv);
    if (existing != 0n) {
      console.log(`L${lv}: already init (roundId=${existing})`);
      continue;
    }
    if (r.config.startsAt > now) {
      console.log(`L${lv}: startsAt ${new Date(r.config.startsAt*1000).toISOString()} future, skip`);
      continue;
    }
    console.log(`L${lv}: init round ${r.config.roundId}...`);
    try {
      const tx = await manager.initializeRound(r.config, r.signature);
      const receipt = await tx.wait();
      console.log(`L${lv}: done tx=${receipt.hash}`);
    } catch (e) {
      console.log(`L${lv}: FAILED - ${(e.message||e).slice(0,300)}`);
    }
  }
  console.log("\nDone");
}

main().catch(e => { console.error(e); process.exit(1); });
