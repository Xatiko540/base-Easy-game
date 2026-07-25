const hre = require("hardhat");

async function main() {
  const [signer] = await hre.ethers.getSigners();
  const network = await hre.ethers.provider.getNetwork();
  const chainId = Number(network.chainId);

  const managerArtifact = require("../src/artifacts/EasyGameRoundManager.json");
  const managerAddress = managerArtifact.networks[String(chainId)]?.address;
  const manager = await hre.ethers.getContractAt("EasyGameRoundManager", managerAddress, signer);

  const { Wallet } = require("ethers");
  const { roundTypes } = require("../functions/round_season_manifest");
  const scheduleSigner = new Wallet("db159ae74cad9a219a481ef9a10257ff8c088e31b56967f17486fc795d8eee4c");
  const domain = {
    name: "EasyGameAdvance",
    version: "2",
    chainId,
    verifyingContract: managerAddress,
  };

  const seasonId = BigInt(Math.floor(Date.now() / 1000)) * 1000n;
  const baseStart = BigInt(Math.floor(Date.now() / 1000) + 3600);
  const durationsHours = [24n, 48n, 72n, 96n, 144n];

  const configs = [];
  const signatures = [];

  for (let level = 1; level <= 17; level++) {
    const roundId = seasonId * 100n + BigInt(level);
    const startsAt = baseStart + BigInt(level - 1) * 5n * 3600n;
    const durationHours = durationsHours[(level - 1) % durationsHours.length];
    const endsAt = startsAt + durationHours * 3600n;

    const config = {
      seasonId,
      roundId,
      level,
      startsAt,
      entriesCloseAt: startsAt + (endsAt - startsAt) / 2n,
      endsAt,
      freezeClosesAt: endsAt,
      maxPlayers: 1_000_000,
      maxWinners: 2,
      winningCellsRoot: "0x" + "ab".repeat(32),
      ethPrice: 100_000_000_000_000n,
      usdcPrice: 100_000n,
      freezeLimit: Number(((durationHours + 23n) / 24n) * 10n),
      paymentSplitVersion: 1,
    };

    const valid = await manager.verifyRoundConfig(config, "0x" + "00".repeat(65));
    console.log(`L${level} verifyRoundConfig before sign:`, valid);

    const signature = await scheduleSigner.signTypedData(domain, roundTypes, config);
    const valid2 = await manager.verifyRoundConfig(config, signature);
    if (!valid2) {
      console.log(`L${level} INVALID after signing!`);
      continue;
    }
    configs.push(config);
    signatures.push(signature);
  }

  console.log("seasonId:", seasonId.toString());
  console.log("configs:", configs.length);

  try {
    const tx = await manager.commitSeason(configs, signatures);
    const receipt = await tx.wait();
    console.log("receipt.status:", receipt.status);
    const state = await manager.getSeasonState(seasonId);
    console.log("state.committed:", state.committed);
  } catch (e) {
    console.log("commitSeason FAILED:", e.message?.slice(0, 200) || e);
  }
}

main().catch((error) => {
  console.error(error.message || error);
  process.exitCode = 1;
});
