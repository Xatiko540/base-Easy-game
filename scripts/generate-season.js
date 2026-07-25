const fs = require("fs");
const path = require("path");
const { Wallet, TypedDataEncoder } = require("ethers");
const { buildWinningCellTree } = require("../functions/round_merkle");
const { SEASON_LEVEL_COUNT, roundTypes } = require("../functions/round_season_manifest");

const SCHEDULE_SIGNER_KEY = "db159ae74cad9a219a481ef9a10257ff8c088e31b56967f17486fc795d8eee4c";
const CHAIN_ID = 84532;
const MANAGER_ADDRESS = "0xD552FB90f49bB5792676C5c26ce8414F4EB7C5aB";

const durationsHours = [24n, 48n, 72n, 96n, 144n];

async function main() {
  const signer = new Wallet(SCHEDULE_SIGNER_KEY);
  const domain = {
    name: "EasyGameAdvance",
    version: "2",
    chainId: CHAIN_ID,
    verifyingContract: MANAGER_ADDRESS,
  };

  const seasonId = BigInt(Math.floor(Date.now() / 1000)) * 1000n;
  const baseStart = BigInt(Math.floor(Date.now() / 1000) + 3600);

  const rounds = [];
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
    const signature = await signer.signTypedData(domain, roundTypes, config);

    rounds.push({ config, signature, winningCells, proofs: tree.proofs });
  }

  const seasonIdStr = seasonId.toString();
  const outputDir = path.join(__dirname, "..", "seasons");
  fs.mkdirSync(outputDir, { recursive: true });
  const outputPath = path.join(outputDir, `${seasonIdStr}.json`);

  fs.writeFileSync(outputPath, JSON.stringify({ rounds }, null, 2) + "\n");
  console.log(JSON.stringify({
    seasonId: seasonIdStr,
    signer: signer.address,
    managerAddress: MANAGER_ADDRESS,
    chainId: CHAIN_ID,
    firstStartsAt: Number(baseStart),
    rounds: rounds.map((r) => ({
      level: r.config.level,
      roundId: r.config.roundId.toString(),
      startsAt: Number(r.config.startsAt),
      endsAt: Number(r.config.endsAt),
    })),
    outputPath,
  }, null, 2));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
