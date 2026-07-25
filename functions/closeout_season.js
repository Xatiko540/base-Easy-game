const { JsonRpcProvider, Contract, Wallet, formatEther } = require("ethers");

const RPC = "https://sepolia.base.org";
const CHAIN_ID = 84532;
const MANAGER_ADDR = "0x62AC456b26847eb74f039C0Eb34ea661F939726B";
const ADMIN_PK = "0xef16589ee5ef136266d874e3efb228149996fdc3dd674ae785d6eaf79152fcba";
const SEASON_ID = 2026071902n;

const MANAGER_ABI = [
  "function gameCore() view returns (address)",
  "function settlementContract() view returns (address)",
  "function arenaSkills() view returns (address)",
  "function getRoundPhase(uint256) view returns (uint8)",
  "function roundBySeasonLevel(uint256, uint8) view returns (uint256)",
  "function cancelRound(uint256)",
  "function getRoundState(uint256) view returns (bytes32 configHash, uint64 initializedAt, uint32 occupiedCells, uint16 winnersRegistered, bool initialized, bool settled, bool cancelled, bool paused)",
];

const CORE_ABI = [
  "function withdrawProjectFees()",
  "function claimReferralBonus()",
  "function projectFeesAccrued() view returns (uint256)",
];

const SETTLEMENT_ABI = [
  "function settleRound(uint256, uint256[], bytes32[][])",
  "function claimPrize()",
  "function claimableEth(address) view returns (uint256)",
  "function roundSettled(uint256) view returns (bool)",
];

const PHASE_NAMES = ["Sealed", "Open", "Locked", "SettlementReady", "Settled", "Cancelled"];

async function main() {
  const provider = new JsonRpcProvider(RPC, CHAIN_ID);
  const admin = new Wallet(ADMIN_PK, provider);
  const manager = new Contract(MANAGER_ADDR, MANAGER_ABI, admin);

  console.log("Admin:", admin.address);
  console.log("Balance:", formatEther(await provider.getBalance(admin.address)), "ETH\n");

  const coreAddr = await manager.gameCore();
  const settlementAddr = await manager.settlementContract();
  console.log("Core:", coreAddr);
  console.log("Settlement:", settlementAddr);
  console.log("Manager:", MANAGER_ADDR + "\n");

  const core = new Contract(coreAddr, CORE_ABI, admin);
  const settlement = new Contract(settlementAddr, SETTLEMENT_ABI, admin);

  const fees = await core.projectFeesAccrued();
  console.log("Project fees accrued:", formatEther(fees), "ETH\n");

  const roundsToSettle = [];
  const canCancel = [];

  for (let lv = 1; lv <= 17; lv++) {
    const roundId = await manager.roundBySeasonLevel(SEASON_ID, lv);
    if (roundId == 0n) {
      console.log(`L${lv}: not initialized`);
      continue;
    }
    const ph = Number(await manager.getRoundPhase(roundId));
    const st = await manager.getRoundState(roundId);
    console.log(`L${lv} (${roundId}): ${PHASE_NAMES[ph]||ph} | occupied=${st.occupiedCells} players=${st.winnersRegistered} init=${st.initialized} settled=${st.settled} cancelled=${st.cancelled}`);
    if (ph === 3 && !st.settled) roundsToSettle.push({ lv, roundId });
    if (ph <= 2 && Number(st.occupiedCells) === 0 && !st.settled && !st.cancelled) canCancel.push({ lv, roundId, phase: PHASE_NAMES[ph] });
  }

  console.log("\n--- Settlement ---");
  for (const r of roundsToSettle) {
    process.stdout.write(`L${r.lv} (${r.roundId})...`);
    try {
      const tx = await settlement.settleRound(r.roundId, [], []);
      const rec = await tx.wait();
      console.log(` OK ${rec.hash}`);
    } catch (e) { console.log(` FAIL ${(e.message||e).slice(0,150)}`); }
  }

  console.log("\n--- Cancel empty rounds ---");
  for (const r of canCancel) {
    process.stdout.write(`L${r.lv} (${r.roundId}) [${r.phase}]...`);
    try {
      const tx = await manager.cancelRound(r.roundId);
      const rec = await tx.wait();
      console.log(` OK ${rec.hash}`);
    } catch (e) { console.log(` FAIL ${(e.message||e).slice(0,150)}`); }
  }

  console.log("\n--- Withdraw fees ---");
  if (fees > 0n) {
    process.stdout.write(`Withdrawing ${formatEther(fees)} ETH...`);
    try {
      const tx = await core.withdrawProjectFees();
      const rec = await tx.wait();
      console.log(` OK ${rec.hash}`);
    } catch (e) { console.log(` FAIL ${(e.message||e).slice(0,150)}`); }
  } else {
    console.log("Nothing to withdraw");
  }

  console.log("\n--- Claim referral bonus ---");
  try {
    const tx = await core.claimReferralBonus();
    const rec = await tx.wait();
    console.log(`OK ${rec.hash}`);
  } catch (e) { console.log(`SKIP (${(e.message||e).slice(0,150)})`); }

  console.log("\n--- Settlement claimable ---");
  const claimable = await settlement.claimableEth(admin.address);
  if (claimable > 0n) {
    process.stdout.write(`${formatEther(claimable)} ETH claimable, claiming...`);
    try {
      const tx = await settlement.claimPrize();
      const rec = await tx.wait();
      console.log(` OK ${rec.hash}`);
    } catch (e) { console.log(` FAIL ${(e.message||e).slice(0,150)}`); }
  } else {
    console.log("Nothing claimable");
  }

  console.log("\n=== Final ===");
  console.log("Fees remaining:", formatEther(await core.projectFeesAccrued()), "ETH");
  console.log("Admin balance:", formatEther(await provider.getBalance(admin.address)), "ETH");
  console.log("Done");
}

main().catch(e => { console.error("FATAL:", e); process.exit(1); });
