const {
  TypedDataEncoder,
  concat,
  getAddress,
  keccak256,
  solidityPackedKeccak256,
  verifyTypedData,
} = require("ethers");

const { buildWinningCellTree } = require("./round_merkle");

const SEASON_LEVEL_COUNT = 17;
const MIN_LEVEL_OPEN_INTERVAL = 5n * 60n * 60n;
const MIN_ROUND_DURATION = 60n * 60n;
const MAX_WINNERS = 8n;
const MAX_PLAYERS = 1_000_000n;
const MAX_ETH_PRICE = 1_000n * 10n ** 18n;
const MAX_USDC_PRICE = 1_000_000_000n * 10n ** 6n;

const roundTypes = {
  RoundConfig: [
    { name: "seasonId", type: "uint256" },
    { name: "roundId", type: "uint256" },
    { name: "level", type: "uint8" },
    { name: "startsAt", type: "uint64" },
    { name: "entriesCloseAt", type: "uint64" },
    { name: "endsAt", type: "uint64" },
    { name: "freezeClosesAt", type: "uint64" },
    { name: "maxPlayers", type: "uint32" },
    { name: "maxWinners", type: "uint16" },
    { name: "winningCellsRoot", type: "bytes32" },
    { name: "ethPrice", type: "uint256" },
    { name: "usdcPrice", type: "uint256" },
    { name: "freezeLimit", type: "uint16" },
    { name: "paymentSplitVersion", type: "uint16" },
  ],
};

function unsignedInteger(source, name) {
  try {
    const value = BigInt(source[name]);
    if (value < 0n) throw new Error("negative");
    return value;
  } catch (_) {
    throw new Error(`Invalid ${name}`);
  }
}

function parseRoundManifest(source, expectedLevel) {
  if (!source || typeof source !== "object") {
    throw new Error(`Missing level ${expectedLevel} manifest`);
  }
  const rawConfig = source.config;
  const signature = String(source.signature || "");
  if (!rawConfig || !/^0x[0-9a-fA-F]{130}$/.test(signature)) {
    throw new Error(`Invalid level ${expectedLevel} config or signature`);
  }

  let winningCells;
  try {
    winningCells = (source.winningCells || []).map((value) => BigInt(value));
  } catch (_) {
    throw new Error(`Invalid level ${expectedLevel} winning cells`);
  }
  winningCells.sort((left, right) => left < right ? -1 : left > right ? 1 : 0);

  const config = {
    seasonId: unsignedInteger(rawConfig, "seasonId"),
    roundId: unsignedInteger(rawConfig, "roundId"),
    level: unsignedInteger(rawConfig, "level"),
    startsAt: unsignedInteger(rawConfig, "startsAt"),
    entriesCloseAt: unsignedInteger(rawConfig, "entriesCloseAt"),
    endsAt: unsignedInteger(rawConfig, "endsAt"),
    freezeClosesAt: unsignedInteger(rawConfig, "freezeClosesAt"),
    maxPlayers: unsignedInteger(rawConfig, "maxPlayers"),
    maxWinners: unsignedInteger(rawConfig, "maxWinners"),
    winningCellsRoot: String(rawConfig.winningCellsRoot || ""),
    ethPrice: unsignedInteger(rawConfig, "ethPrice"),
    usdcPrice: unsignedInteger(rawConfig, "usdcPrice"),
    freezeLimit: unsignedInteger(rawConfig, "freezeLimit"),
    paymentSplitVersion: unsignedInteger(rawConfig, "paymentSplitVersion"),
  };

  if (config.level !== BigInt(expectedLevel)) {
    throw new Error(`Expected level ${expectedLevel}, received ${config.level}`);
  }
  if (
    config.seasonId === 0n || config.roundId === 0n ||
    config.startsAt >= config.entriesCloseAt ||
    config.entriesCloseAt >= config.endsAt ||
    config.freezeClosesAt !== config.endsAt ||
    config.endsAt - config.startsAt < MIN_ROUND_DURATION ||
    config.maxPlayers === 0n || config.maxPlayers > MAX_PLAYERS ||
    config.maxWinners === 0n || config.maxWinners > MAX_WINNERS ||
    config.ethPrice > MAX_ETH_PRICE || config.usdcPrice > MAX_USDC_PRICE ||
    (config.ethPrice === 0n && config.usdcPrice === 0n) ||
    config.paymentSplitVersion !== 1n ||
    !/^0x[0-9a-fA-F]{64}$/.test(config.winningCellsRoot)
  ) {
    throw new Error(`Level ${expectedLevel} constraints are invalid`);
  }
  const expectedFreezeLimit =
    ((config.endsAt - config.startsAt + 86400n - 1n) / 86400n) * 10n;
  if (config.freezeLimit !== expectedFreezeLimit) {
    throw new Error(`Level ${expectedLevel} freeze limit is invalid`);
  }
  if (
    winningCells.length !== Number(config.maxWinners) ||
    winningCells.some((cell, index) =>
      cell <= 0n || (index > 0 && cell === winningCells[index - 1]))
  ) {
    throw new Error(`Level ${expectedLevel} winning cells are incomplete`);
  }
  const winningTree = buildWinningCellTree(config.roundId, winningCells);
  if (winningTree.root.toLowerCase() !== config.winningCellsRoot.toLowerCase()) {
    throw new Error(`Level ${expectedLevel} winning root does not match its cells`);
  }

  return {
    config,
    signature,
    winningCells,
    proofs: winningTree.proofs,
    configHash: TypedDataEncoder.hashStruct("RoundConfig", roundTypes, config),
  };
}

function parseSeasonManifest(payload, { chainId, managerAddress, signerAddress }) {
  const sources = payload?.rounds;
  if (!Array.isArray(sources) || sources.length !== SEASON_LEVEL_COUNT) {
    throw new Error(`A complete ${SEASON_LEVEL_COUNT}-round season is required`);
  }
  const rounds = sources.map((source, index) =>
    parseRoundManifest(source, index + 1));
  const seasonId = rounds[0].config.seasonId;
  const roundIds = new Set();
  const domain = {
    name: "EasyGameAdvance",
    version: "2",
    chainId: Number(chainId),
    verifyingContract: managerAddress,
  };

  for (let index = 0; index < rounds.length; index++) {
    const round = rounds[index];
    if (round.config.seasonId !== seasonId) {
      throw new Error(`Level ${index + 1} belongs to another season`);
    }
    const roundId = round.config.roundId.toString();
    if (roundIds.has(roundId)) throw new Error(`Duplicate round ID ${roundId}`);
    roundIds.add(roundId);
    if (
      index > 0 &&
      round.config.startsAt <
        rounds[index - 1].config.startsAt + MIN_LEVEL_OPEN_INTERVAL
    ) {
      throw new Error("Adjacent levels must open at least five hours apart");
    }
    let recovered;
    try {
      recovered = verifyTypedData(
        domain,
        roundTypes,
        round.config,
        round.signature,
      );
    } catch (_) {
      throw new Error(`Malformed level ${index + 1} EIP-712 signature`);
    }
    if (getAddress(recovered) !== getAddress(signerAddress)) {
      throw new Error(`Invalid schedule signer for level ${index + 1}`);
    }
  }

  let configRoot = solidityPackedKeccak256(
    ["uint256", "uint8"],
    [seasonId, SEASON_LEVEL_COUNT],
  );
  for (const round of rounds) {
    configRoot = keccak256(concat([configRoot, round.configHash]));
  }

  return {
    seasonId,
    rounds,
    configRoot,
    firstStartsAt: rounds[0].config.startsAt,
    lastEndsAt: rounds.reduce(
      (latest, round) => round.config.endsAt > latest ? round.config.endsAt : latest,
      rounds[0].config.endsAt,
    ),
  };
}

module.exports = {
  SEASON_LEVEL_COUNT,
  parseSeasonManifest,
  roundTypes,
};
