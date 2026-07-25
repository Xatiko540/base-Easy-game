const { ethers, Wallet } = require("ethers");
const { roundTypes } = require("../functions/round_season_manifest");
const managerArtifact = require("../src/artifacts/EasyGameRoundManager.json");

const RPC = "https://sepolia.base.org";
const CHAIN_ID = 84532;
const DEPLOYER_KEY = "db159ae74cad9a219a481ef9a10257ff8c088e31b56967f17486fc795d8eee4c";
const MANAGER = "0xD552FB90f49bB5792676C5c26ce8414F4EB7C5aB";

async function main() {
  const provider = new ethers.JsonRpcProvider(RPC, CHAIN_ID);
  const wallet = new Wallet(DEPLOYER_KEY, provider);
  const manager = new ethers.Contract(MANAGER, managerArtifact.abi, wallet);

  const block = await provider.getBlock("latest");
  const now = BigInt(block.timestamp);
  const seasonId = now * 1000n;
  const baseStart = now + 3600n;
  const durationsHours = [24n, 48n, 72n, 96n, 144n];

  console.log("Deployer:", wallet.address);
  console.log("Balance:", ethers.formatEther(await provider.getBalance(wallet.address)), "ETH");
  console.log("Season:", seasonId.toString());
  console.log("First round starts at:", new Date(Number(baseStart) * 1000).toISOString());

  const configs = [];
  const signatures = [];

  for (let level = 1; level <= 17; level++) {
    const roundId = seasonId * 100n + BigInt(level);
    const startsAt = baseStart + BigInt(level - 1) * 5n * 3600n;
    const durationHours = durationsHours[(level - 1) % durationsHours.length];
    const endsAt = startsAt + durationHours * 3600n;
    const config = {
      seasonId, roundId, level,
      startsAt,
      entriesCloseAt: startsAt + (endsAt - startsAt) / 2n,
      endsAt, freezeClosesAt: endsAt,
      maxPlayers: 1_000_000, maxWinners: 2,
      winningCellsRoot: "0x" + "ab".repeat(32),
      ethPrice: 100_000_000_000_000n, usdcPrice: 100_000n,
      freezeLimit: Number(((durationHours + 23n) / 24n) * 10n),
      paymentSplitVersion: 1,
    };
    const domain = {
      name: "EasyGameAdvance",
      version: "2",
      chainId: CHAIN_ID,
      verifyingContract: MANAGER,
    };
    const sig = await wallet.signTypedData(domain, roundTypes, config);
    configs.push(config);
    signatures.push(sig);
  }

  // All 17 configs built. Use raw ABI encoding for commitSeason.
  const iface = new ethers.Interface(managerArtifact.abi);
  const data = iface.encodeFunctionData("commitSeason", [configs, signatures]);

  console.log("Sending commitSeason...");
  const tx = await wallet.sendTransaction({
    to: MANAGER,
    data,
    gasLimit: 5_000_000n,
  });
  console.log("TX:", tx.hash);

  const receipt = await tx.wait();
  console.log("Status:", receipt.status);
  if (receipt.status === 0) {
    console.log("REVERTED. Trying to get revert reason...");
    try {
      const callResult = await provider.call({ to: MANAGER, data }, block.number);
      console.log("call result:", callResult);
    } catch (e) {
      const errData = e.info?.error?.data || e.data || "";
      if (errData && errData !== "0x") {
        try {
          const reason = ethers.toUtf8String("0x" + errData.slice(138));
          console.log("Reason:", reason);
        } catch (_) {
          console.log("Raw error data:", errData.slice(0, 200));
        }
      }
      console.log("Error:", e.message?.slice(0, 300) || e);
    }
    return;
  }

  const state = await manager.getSeasonState(seasonId);
  console.log("Committed:", state.committed);
  console.log("ConfigRoot:", state.configRoot);
}

main().catch((e) => console.error(e.message || e));
