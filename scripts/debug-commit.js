const hre = require("hardhat");

async function main() {
  await hre.network.provider.request({
    method: "hardhat_reset",
    params: [{
      forking: {
        jsonRpcUrl: "https://sepolia.base.org",
        blockNumber: 44490884,
      },
    }],
  });

  const [deployer] = await hre.ethers.getSigners();
  const { Wallet } = require("ethers");
  const { roundTypes } = require("../functions/round_season_manifest");

  const managerAddress = "0xD552FB90f49bB5792676C5c26ce8414F4EB7C5aB";
  const manager = await hre.ethers.getContractAt("EasyGameRoundManager", managerAddress, deployer);

  const scheduleSigner = new Wallet("db159ae74cad9a219a481ef9a10257ff8c088e31b56967f17486fc795d8eee4c");
  const domain = {
    name: "EasyGameAdvance",
    version: "2",
    chainId: 84532,
    verifyingContract: managerAddress,
  };

  const now = BigInt(Math.floor(Date.now() / 1000));
  const seasonId = now * 1000n;
  const baseStart = now + 3600n;
  const durationsHours = [24n, 48n, 72n, 96n, 144n];

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

    const signature = await scheduleSigner.signTypedData(domain, roundTypes, config);
    configs.push(config);
    signatures.push(signature);
  }

  for (let i = 0; i < 17; i++) {
    const valid = await manager.verifyRoundConfig(configs[i], signatures[i]);
    if (!valid) console.log("L" + configs[i].level + " invalid");
  }

  try {
    await manager.commitSeason.staticCall(configs, signatures);
    console.log("staticCall succeeded");
  } catch (e) {
    console.log("staticCall reverted:");
    console.log("  reason:", e.reason || e.message?.slice(0, 200));
    console.log("  data:", e.data?.data || e.data || "none");
    const tx = await manager.commitSeason.populateTransaction(configs, signatures);
    const estimate = await hre.ethers.provider.estimateGas(tx).catch((e2) => {
      console.log("  estimateGas error:", e2.reason || e2.message?.slice(0, 200));
    });
  }
}

main().catch((error) => {
  console.error(error.message || error);
  process.exitCode = 1;
});
