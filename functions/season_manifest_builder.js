const { buildWinningCellTree } = require("./round_merkle");
const { SEASON_LEVEL_COUNT, roundTypes } = require("./round_season_manifest");

const MIN_LEVEL_OPEN_INTERVAL = 5n * 60n * 60n;
const MIN_ROUND_DURATION = 60n * 60n;

function unsignedInteger(value, name) {
  try {
    const parsed = BigInt(value);
    if (parsed < 0n) throw new Error("negative");
    return parsed;
  } catch (_) {
    throw new Error(`Invalid ${name}`);
  }
}

function exactArray(source, name) {
  if (!Array.isArray(source) || source.length !== SEASON_LEVEL_COUNT) {
    throw new Error(`${name} must contain exactly ${SEASON_LEVEL_COUNT} values`);
  }
  return source;
}

function normalizedWinningCells(source, level) {
  if (!Array.isArray(source) || source.length === 0 || source.length > 8) {
    throw new Error(`Level ${level} must define between 1 and 8 winning cells`);
  }
  const cells = source.map((value) => unsignedInteger(value, `level ${level} winning cell`))
    .sort((left, right) => left < right ? -1 : left > right ? 1 : 0);
  if (cells.some((cell, index) => cell === 0n || (index > 0 && cell === cells[index - 1]))) {
    throw new Error(`Level ${level} winning cells must be positive and unique`);
  }
  return cells;
}

async function buildSignedSeasonManifest(spec, context) {
  const seasonId = unsignedInteger(spec?.seasonId, "seasonId");
  const firstStartsAt = unsignedInteger(spec?.firstStartsAt, "firstStartsAt");
  const interval = unsignedInteger(
    spec?.levelOpenIntervalSeconds,
    "levelOpenIntervalSeconds",
  );
  const entryWindows = exactArray(spec?.entryWindowSeconds, "entryWindowSeconds")
    .map((value, index) => unsignedInteger(value, `level ${index + 1} entry window`));
  const durations = exactArray(spec?.roundDurationSeconds, "roundDurationSeconds")
    .map((value, index) => unsignedInteger(value, `level ${index + 1} duration`));
  const ethPrices = exactArray(spec?.ethPricesWei, "ethPricesWei")
    .map((value, index) => unsignedInteger(value, `level ${index + 1} ETH price`));
  const usdcPrices = exactArray(spec?.usdcPrices, "usdcPrices")
    .map((value, index) => unsignedInteger(value, `level ${index + 1} USDC price`));
  const winningCellsByLevel = exactArray(
    spec?.winningCellsByLevel,
    "winningCellsByLevel",
  );
  const maxPlayers = unsignedInteger(spec?.maxPlayers, "maxPlayers");

  if (seasonId === 0n) throw new Error("seasonId must be positive");
  if (interval < MIN_LEVEL_OPEN_INTERVAL) {
    throw new Error("Adjacent levels must open at least five hours apart");
  }
  if (maxPlayers === 0n || maxPlayers > 1_000_000n) {
    throw new Error("maxPlayers must be between 1 and 1000000");
  }
  if (new Set(durations.map(String)).size !== SEASON_LEVEL_COUNT) {
    throw new Error("All 17 round durations must be different");
  }

  const domain = {
    name: "EasyGameAdvance",
    version: "2",
    chainId: Number(context.chainId),
    verifyingContract: context.managerAddress,
  };
  const rounds = [];
  for (let index = 0; index < SEASON_LEVEL_COUNT; index += 1) {
    const level = index + 1;
    const duration = durations[index];
    const entryWindow = entryWindows[index];
    if (duration < MIN_ROUND_DURATION || entryWindow === 0n || entryWindow >= duration) {
      throw new Error(`Level ${level} entry window and duration are invalid`);
    }
    if (ethPrices[index] === 0n && usdcPrices[index] === 0n) {
      throw new Error(`Level ${level} must accept ETH or USDC`);
    }

    const startsAt = firstStartsAt + BigInt(index) * interval;
    const endsAt = startsAt + duration;
    const roundId = seasonId * 100n + BigInt(level);
    const winningCells = normalizedWinningCells(winningCellsByLevel[index], level);
    const tree = buildWinningCellTree(roundId, winningCells);
    const config = {
      seasonId,
      roundId,
      level,
      startsAt,
      entriesCloseAt: startsAt + entryWindow,
      endsAt,
      freezeClosesAt: endsAt,
      maxPlayers: Number(maxPlayers),
      maxWinners: winningCells.length,
      winningCellsRoot: tree.root,
      ethPrice: ethPrices[index],
      usdcPrice: usdcPrices[index],
      freezeLimit: Number(((duration + 86400n - 1n) / 86400n) * 10n),
      paymentSplitVersion: 1,
    };
    const signature = await context.signer.signTypedData(domain, roundTypes, config);
    rounds.push({
      config: Object.fromEntries(
        Object.entries(config).map(([key, value]) => [
          key,
          typeof value === "bigint" ? value.toString() : value,
        ]),
      ),
      signature,
      winningCells: winningCells.map(String),
    });
  }

  return {
    schemaVersion: 3,
    chainId: Number(context.chainId),
    managerAddress: context.managerAddress,
    scheduleSigner: context.signer.address,
    rounds,
  };
}

module.exports = {
  MIN_LEVEL_OPEN_INTERVAL,
  buildSignedSeasonManifest,
};
