const hre = require("hardhat");

async function main() {
  const [signer] = await hre.ethers.getSigners();
  const network = await hre.ethers.provider.getNetwork();
  const chainId = Number(network.chainId);

  const managerArtifact = require("../src/artifacts/EasyGameRoundManager.json");
  const managerAddress = managerArtifact.networks[String(chainId)]?.address;
  console.log("Manager:", managerAddress);
  console.log("Signer:", signer.address);

  const manager = await hre.ethers.getContractAt("EasyGameRoundManager", managerAddress, signer);

  const finalized = await manager.systemContractsFinalized();
  console.log("finalized:", finalized);

  const signerRole = await manager.scheduleSigner();
  console.log("scheduleSigner:", signerRole);

  const allowed = await manager.allowedScheduleSigners("0xeF9B7b298f821124c6c81D21e1cD99966a331a5A");
  console.log("allowedScheduleSigners[wallet2]:", allowed);

  const seasonId = BigInt(Math.floor(Date.now() / 1000)) * 1000n;
  const baseStart = BigInt(Math.floor(Date.now() / 1000) + 3600);

  const config = {
    seasonId,
    roundId: seasonId * 100n + 1n,
    level: 1,
    startsAt: baseStart,
    entriesCloseAt: baseStart + 43200n,
    endsAt: baseStart + 86400n,
    freezeClosesAt: baseStart + 86400n,
    maxPlayers: 1_000_000,
    maxWinners: 2,
    winningCellsRoot: "0x" + "ab".repeat(32),
    ethPrice: 100_000_000_000_000n,
    usdcPrice: 100_000n,
    freezeLimit: 10,
    paymentSplitVersion: 1,
  };

  const { Wallet } = require("ethers");
  const scheduleSigner = new Wallet("db159ae74cad9a219a481ef9a10257ff8c088e31b56967f17486fc795d8eee4c");
  const domain = {
    name: "EasyGameAdvance",
    version: "2",
    chainId,
    verifyingContract: managerAddress,
  };
  const { roundTypes } = require("../functions/round_season_manifest");
  const signature = await scheduleSigner.signTypedData(domain, roundTypes, config);

  const valid = await manager.verifyRoundConfig(config, signature);
  console.log("verifyRoundConfig:", valid);
}

main().catch((error) => {
  console.error(error.message || error);
  process.exitCode = 1;
});
