const hre = require("hardhat");
const { Wallet } = require("ethers");
const { buildWinningCellTree } = require("../functions/round_merkle");
const { SEASON_LEVEL_COUNT, roundTypes } = require("../functions/round_season_manifest");

const SCHEDULE_SIGNER_KEY = "db159ae74cad9a219a481ef9a10257ff8c088e31b56967f17486fc795d8eee4c";
const durationsHours = [24n, 48n, 72n, 96n, 144n];

async function main() {
  const [signer] = await hre.ethers.getSigners();
  const network = await hre.ethers.provider.getNetwork();
  const chainId = Number(network.chainId);

  const managerArtifact = require("../src/artifacts/EasyGameRoundManager.json");
  const managerAddress = managerArtifact.networks[String(chainId)]?.address;
  if (!managerAddress) throw new Error("No deployed RoundManager for chain " + chainId);

  const scheduleSigner = new Wallet(SCHEDULE_SIGNER_KEY);
  const domain = {
    name: "EasyGameAdvance",
    version: "2",
    chainId,
    verifyingContract: managerAddress,
  };

  const seasonId = BigInt(Math.floor(Date.now() / 1000)) * 1000n;
  const baseStart = BigInt(Math.floor(Date.now() / 1000) + 3600);

  const configs = [];
  const signatures = [];
  for (let level = 1; level <= SEASON_LEVEL_COUNT; level++) {
    const roundId = seasonId * 100n + BigInt(level);
    const startsAt = baseStart + BigInt(level - 1) * 5n * 3600n;
    const durationHours = durationsHours[(level - 1) % durationsHours.length];
    const endsAt = startsAt + durationHours * 3600n;
    const winningCells = [7n, 15n];
    const tree = buildWinningCellTree(roundId, winningCells);

    const config = {
      seasonId,
      roundId,
      level,
      startsAt,
      entriesCloseAt: startsAt + (endsAt - startsAt) / 2n,
      endsAt,
      freezeClosesAt: endsAt,
      maxPlayers: 1_000_000,
      maxWinners: winningCells.length,
      winningCellsRoot: tree.root,
      ethPrice: 100_000_000_000_000n,
      usdcPrice: 100_000n,
      freezeLimit: Number(((durationHours + 23n) / 24n) * 10n),
      paymentSplitVersion: 1,
    };
    const signature = await scheduleSigner.signTypedData(domain, roundTypes, config);
    configs.push(config);
    signatures.push(signature);
  }

  const manager = await hre.ethers.getContractAt("EasyGameRoundManager", managerAddress);

  const finalized = await manager.systemContractsFinalized();
  console.log("systemContractsFinalized:", finalized);

  const tx = await manager.commitSeason(configs, signatures);
  const receipt = await tx.wait();
  console.log("receipt.status:", receipt.status);
  console.log("tx.hash:", receipt.hash);

  console.log("seasonId:", seasonId.toString());
  const state = await manager.getSeasonState(seasonId);
  console.log("state.committed:", state.committed);
  console.log("state.configRoot:", state.configRoot);

  if (!state.committed) {
    console.log("TX succeeded but state says not committed. Checking event logs...");
    for (const log of receipt.logs) {
      try {
        const parsed = manager.interface.parseLog(log);
        if (parsed) console.log("event:", parsed.name, JSON.stringify(Object.fromEntries(
          Object.entries(parsed.args).filter(([k]) => isNaN(Number(k)))
        )));
      } catch (_) {}
    }
    throw new Error("Season commitment verification failed");
  }

  console.log(JSON.stringify({
    status: "ok",
    chainId,
    managerAddress,
    scheduleSigner: scheduleSigner.address,
    seasonId: seasonId.toString(),
    configRoot: state.configRoot,
    firstStartsAt: Number(baseStart),
    lastEndsAt: Number(state.lastEndsAt),
    transactionHash: receipt.hash,
    blockNumber: receipt.blockNumber,
    rounds: configs.map((c) => ({
      level: c.level,
      roundId: c.roundId.toString(),
      startsAt: Number(c.startsAt),
      endsAt: Number(c.endsAt),
    })),
  }, null, 2));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
