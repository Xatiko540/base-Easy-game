const { JsonRpcProvider, Contract, Wallet, formatEther } = require("ethers");

const RPC = "https://sepolia.base.org";
const CHAIN_ID = 84532;
const MANAGER_ADDR = "0x62AC456b26847eb74f039C0Eb34ea661F939726B";
const ADMIN_PK = "0xef16589ee5ef136266d874e3efb228149996fdc3dd674ae785d6eaf79152fcba";
const SEASON_ID = 2026071902n;

// Indexed access: [0]=configHash [1]=initializedAt [2]=occupiedCells [3]=winnersRegistered [4]=initialized [5]=settled [6]=cancelled [7]=paused
const R = { hash: 0, initAt: 1, occCells: 2, winnersReg: 3, init: 4, settled: 5, cancelled: 6, paused: 7 };

const MANAGER_ABI = [
  "function getRoundPhase(uint256) view returns (uint8)",
  "function roundBySeasonLevel(uint256, uint8) view returns (uint256)",
  "function getRoundState(uint256) view returns (bytes32, uint64, uint32, uint16, bool, bool, bool, bool)",
  "function gameCore() view returns (address)",
  "function settlementContract() view returns (address)",
  "function arenaSkills() view returns (address)",
  "function cancelRound(uint256)",
];

const CORE_ABI = [
  "function withdrawProjectFees()",
  "function claimReferralBonus()",
  "function projectFeesAccrued() view returns (uint256)",
  "function roundManager() view returns (address)",
  "function hasPendingRoundRecycles(uint256) view returns (bool)",
  "function processRoundRecycles(uint256, uint256) returns (uint256, uint256)",
  "function roundPrizePools(uint256) view returns (uint256)",
];

const SETTLEMENT_ABI = [
  "function settleRound(uint256, uint256[], bytes32[][])",
  "function claimPrize()",
  "function claimableEth(address) view returns (uint256)",
  "function roundSettled(uint256) view returns (bool)",
  "function roundManager() view returns (address)",
];

const PNAME = { 1:"Scheduled",2:"Open",3:"Locked",4:"SettlementReady",5:"Settled",6:"Cancelled",7:"Paused",0:"Uninit" };

async function main() {
  const provider = new JsonRpcProvider(RPC, CHAIN_ID);
  const admin = new Wallet(ADMIN_PK, provider);
  const manager = new Contract(MANAGER_ADDR, MANAGER_ABI, admin);

  console.log("Admin:", admin.address, "| Balance:", formatEther(await provider.getBalance(admin.address)), "ETH\n");

  const coreAddr = await manager.gameCore();
  const settlementAddr = await manager.settlementContract();
  const core = new Contract(coreAddr, CORE_ABI, admin);
  const settlement = new Contract(settlementAddr, SETTLEMENT_ABI, admin);

  console.log("Core:", coreAddr);
  console.log("Settlement:", settlementAddr, "\n");

  const rounds = [];
  for (let lv = 1; lv <= 17; lv++) {
    const roundId = await manager.roundBySeasonLevel(SEASON_ID, lv);
    if (roundId == 0n) { console.log(`L${lv}: —`); continue; }
    const ph = Number(await manager.getRoundPhase(roundId));
    const st = await manager.getRoundState(roundId);
    const prize = await core.roundPrizePools(roundId);
    const pending = await core.hasPendingRoundRecycles(roundId);
    rounds.push({ lv, roundId, ph, st, prize, pending });
    console.log(`L${lv} (${roundId}): ${PNAME[ph]||ph} | occ=${st[R.occCells]} init=${st[R.init]} settled=${st[R.settled]} prize=${formatEther(prize)} recycles=${pending}`);
  }

  // 1. Process recycles
  console.log("\n--- Recycles ---");
  for (const r of rounds) {
    if (!r.pending) continue;
    process.stdout.write(`L${r.lv}...`);
    try {
      const tx = await core.processRoundRecycles(r.roundId, 4);
      const rec = await tx.wait();
      console.log(`OK ${rec.hash}`);
    } catch (e) { console.log(`FAIL ${(e.message||e).slice(0,150)}`); }
  }

  // 2. Cancel rounds with 0 occupied cells that aren't settled/cancelled
  console.log("\n--- Cancel ---");
  for (const r of rounds) {
    if (r.st[R.cancelled] || r.st[R.settled]) continue;
    if (Number(r.st[R.occCells]) > 0) continue;
    process.stdout.write(`L${r.lv} (${PNAME[r.ph]||r.ph})...`);
    try {
      const tx = await manager.cancelRound(r.roundId);
      const rec = await tx.wait();
      console.log(`OK ${rec.hash}`);
    } catch (e) { console.log(`FAIL ${(e.message||e).slice(0,150)}`); }
  }

  // 3. Check if L10-L13 can be settled now
  console.log("\n--- SettlementAttempt ---");
  for (const r of rounds) {
    if (r.st[R.settled] || r.st[R.cancelled]) continue;
    if (r.ph !== 4) { console.log(`L${r.lv}: skip (${PNAME[r.ph]}), wait until SettlementReady`); continue; }
    process.stdout.write(`L${r.lv}...`);
    try {
      const tx = await settlement.settleRound(r.roundId, [], []);
      const rec = await tx.wait();
      console.log(`OK ${rec.hash}`);
    } catch (e) { console.log(`FAIL ${(e.message||e).slice(0,150)}`); }
  }

  // 4. Withdraw fees
  console.log("\n--- Withdraw ---");
  const fees = await core.projectFeesAccrued();
  if (fees > 0n) {
    process.stdout.write(`${formatEther(fees)} ETH...`);
    try { const tx = await core.withdrawProjectFees(); const rec = await tx.wait(); console.log(`OK ${rec.hash}`); }
    catch (e) { console.log(`FAIL ${(e.message||e).slice(0,150)}`); }
  } else { console.log("Nothing"); }

  // 5. Claim referral
  console.log("\n--- Referral ---");
  try { const tx = await core.claimReferralBonus(); const rec = await tx.wait(); console.log(`OK ${rec.hash}`); }
  catch (e) { console.log(`SKIP ${(e.message||e).slice(0,150)}`); }

  // 6. Settlement claim
  console.log("\n--- Claim ---");
  const cl = await settlement.claimableEth(admin.address);
  if (cl > 0n) {
    process.stdout.write(`${formatEther(cl)} ETH...`);
    try { const tx = await settlement.claimPrize(); const rec = await tx.wait(); console.log(`OK ${rec.hash}`); }
    catch (e) { console.log(`FAIL ${(e.message||e).slice(0,150)}`); }
  } else { console.log("Nothing"); }

  // Final
  console.log("\n=== Final ===");
  console.log("Admin:", formatEther(await provider.getBalance(admin.address)), "ETH");
  console.log("Fees:", formatEther(await core.projectFeesAccrued()), "ETH");
  const cb = formatEther(await provider.getBalance(coreAddr));
  console.log("Core:", cb, "ETH");
  for (const r of rounds) {
    if (!r.st[R.settled] && !r.st[R.cancelled])
      console.log(`  L${r.lv} prize=${formatEther(r.prize)} ${PNAME[r.ph]||r.ph}`);
  }
  console.log("Done");
}

main().catch(e => { console.error("FATAL:", e); process.exit(1); });
