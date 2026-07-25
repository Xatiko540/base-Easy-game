const { JsonRpcProvider, Contract, Wallet, formatEther } = require("ethers");

const RPC = "https://sepolia.base.org";
const CHAIN_ID = 84532;
const MANAGER_ADDR = "0x62AC456b26847eb74f039C0Eb34ea661F939726B";
const ADMIN_PK = "0xef16589ee5ef136266d874e3efb228149996fdc3dd674ae785d6eaf79152fcba";
const SEASON_ID = 2026071902n;

const READER_ABI = [
  "function getRoundPhase(uint256) view returns (uint8)",
  "function roundBySeasonLevel(uint256, uint8) view returns (uint256)",
  "function getRoundState(uint256) view returns (bytes32, uint64, uint32, uint16, bool, bool, bool, bool)",
  "function gameCore() view returns (address)",
  "function settlementContract() view returns (address)",
  "function roundManager() view returns (address)",
  "function projectFeesAccrued() view returns (uint256)",
  "function hasPendingRoundRecycles(uint256) view returns (bool)",
  "function processRoundRecycles(uint256, uint256) returns (uint256, uint256)",
  "function cancelRound(uint256)",
  "function claimableEth(address) view returns (uint256)",
];

const PHASE_NAMES = {
  0: "Uninitialized", 1: "Scheduled", 2: "Open", 3: "Locked",
  4: "SettlementReady", 5: "Settled", 6: "Cancelled", 7: "Paused"
};

async function main() {
  const provider = new JsonRpcProvider(RPC, CHAIN_ID);
  const admin = new Wallet(ADMIN_PK, provider);
  const manager = new Contract(MANAGER_ADDR, READER_ABI, admin);

  console.log("Admin:", admin.address);
  console.log("Balance:", formatEther(await provider.getBalance(admin.address)), "ETH\n");

  const coreAddr = await manager.gameCore();
  const settlementAddr = await manager.settlementContract();
  // Check what roundManager address the core sees
  const core = new Contract(coreAddr, READER_ABI, admin);
  const settlement = new Contract(settlementAddr, READER_ABI, admin);

  const coreRM = await core.roundManager();
  const settlementRM = await settlement.roundManager();
  console.log("Core:", coreAddr);
  console.log("  roundManager ->", coreRM);
  console.log("Settlement:", settlementAddr);
  console.log("  roundManager ->", settlementRM);
  console.log("Expected RM:", MANAGER_ADDR);
  console.log("  core RM matches:", coreRM.toLowerCase() === MANAGER_ADDR.toLowerCase());
  console.log("  settlement RM matches:", settlementRM.toLowerCase() === MANAGER_ADDR.toLowerCase());
  console.log("");

  let fees = await core.projectFeesAccrued();
  console.log("Project fees:", formatEther(fees), "ETH\n");

  const roundData = [];
  for (let lv = 1; lv <= 17; lv++) {
    const roundId = await manager.roundBySeasonLevel(SEASON_ID, lv);
    if (roundId == 0n) { console.log(`L${lv}: uninitialized`); continue; }
    const ph = Number(await manager.getRoundPhase(roundId));
    const st = await manager.getRoundState(roundId);
    const pendingRecycles = await core.hasPendingRoundRecycles(roundId);
    roundData.push({ lv, roundId, ph, st, pendingRecycles });
    console.log(`L${lv} (${roundId}): ${PHASE_NAMES[ph]} | occupied=${st[2]} settled=${st[4]} cancelled=${st[6]} recycles=${pendingRecycles}`);
  }

  // Step 1: Process recycles for rounds with pending
  console.log("\n=== Process Recycles ===");
  for (const r of roundData) {
    if (!r.pendingRecycles) continue;
    process.stdout.write(`L${r.lv} (${r.roundId})...`);
    try {
      const tx = await core.processRoundRecycles(r.roundId, 4);
      const rec = await tx.wait();
      console.log(` OK ${rec.hash}`);
    } catch (e) { console.log(` FAIL ${(e.message||e).slice(0,150)}`); }
  }

  // Step 2: Cancel empty non-settled rounds (Locked/Scheduled/Open with 0 occupied)
  console.log("\n=== Cancel ===");
  for (const r of roundData) {
    if (r.st[4] || r.st[6]) continue; // already settled or cancelled
    if (Number(r.st[2]) > 0) continue; // has entries
    if (r.ph === 4 || r.ph === 5) continue; // SettlementReady or Settled
    process.stdout.write(`L${r.lv} (${r.roundId}) [${PHASE_NAMES[r.ph]}]...`);
    try {
      const tx = await manager.cancelRound(r.roundId);
      const rec = await tx.wait();
      console.log(` OK ${rec.hash}`);
    } catch (e) { console.log(` FAIL ${(e.message||e).slice(0,150)}`); }
  }

  // Step 3: For SettlementReady rounds - check why settleRound fails
  console.log("\n=== SettlementReady debug ===");
  for (const r of roundData) {
    if (r.ph !== 4 || r.st[4]) continue;
    // Check phase via core's roundManager
    const corePhase = Number(await core.getRoundPhase(r.roundId));
    const settlementPhase = Number(await settlement.getRoundPhase(r.roundId));
    console.log(`L${r.lv}: phase via manager=${PHASE_NAMES[r.ph]}, via core=${PHASE_NAMES[corePhase]}, via settlement=${PHASE_NAMES[settlementPhase]}`);
  }

  // Step 4: Withdraw fees (again if any left)
  fees = await core.projectFeesAccrued();
  if (fees > 0n) {
    console.log("\n=== Withdraw fees ===");
    process.stdout.write(`${formatEther(fees)} ETH...`);
    try { const tx = await core.withdrawProjectFees(); const rec = await tx.wait(); console.log(` OK ${rec.hash}`); }
    catch (e) { console.log(` FAIL ${(e.message||e).slice(0,150)}`); }
  }

  // Step 5: Claim referral
  console.log("\n=== Claim referral ===");
  try { const tx = await core.claimReferralBonus(); const rec = await tx.wait(); console.log(`OK ${rec.hash}`); }
  catch (e) { console.log(`SKIP: ${(e.message||e).slice(0,150)}`); }

  // Step 6: Settlement claim
  console.log("\n=== Settlement claim ===");
  const claimable = await settlement.claimableEth(admin.address);
  if (claimable > 0n) {
    process.stdout.write(`${formatEther(claimable)} ETH claiming...`);
    try { const tx = await settlement.claimPrize(); const rec = await tx.wait(); console.log(` OK ${rec.hash}`); }
    catch (e) { console.log(` FAIL ${(e.message||e).slice(0,150)}`); }
  } else {
    console.log("Nothing");
  }

  console.log("\n=== Final ===");
  console.log("Fees:", formatEther(await core.projectFeesAccrued()), "ETH");
  console.log("Balance:", formatEther(await provider.getBalance(admin.address)), "ETH");
  console.log("Remaining rounds with funds:");
  for (const r of roundData) {
    if (r.st[4] || r.st[6]) continue;
    const prize = await provider.getBalance(coreAddr); // total core balance
    // Can't easily query per-round prize without the proper ABI
    console.log(`  L${r.lv} (${r.roundId}): ${PHASE_NAMES[r.ph]} occupied=${r.st[2]}`);
  }
  const coreBal = formatEther(await provider.getBalance(coreAddr));
  console.log(`Core balance: ${coreBal} ETH`);
  console.log("Done");
}

main().catch(e => { console.error("FATAL:", e); process.exit(1); });
