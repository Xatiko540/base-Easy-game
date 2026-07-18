const assert = require("node:assert/strict");
const {
  Wallet,
  concat,
  keccak256,
  solidityPackedKeccak256,
} = require("ethers");
const { buildWinningCellTree } = require("./round_merkle");
const {
  SEASON_LEVEL_COUNT,
  parseSeasonManifest,
  roundTypes,
} = require("./round_season_manifest");

const chainId = 84532;
const managerAddress = "0x1111111111111111111111111111111111111111";
const signer = Wallet.createRandom();
const domain = {
  name: "EasyGameAdvance",
  version: "2",
  chainId,
  verifyingContract: managerAddress,
};

async function seasonPayload() {
  const seasonId = 2026071801n;
  const baseStart = 1_800_000_000n;
  const durations = [24n, 48n, 1n, 96n, 12n];
  const rounds = [];
  for (let level = 1; level <= SEASON_LEVEL_COUNT; level++) {
    const roundId = seasonId * 100n + BigInt(level);
    const startsAt = baseStart + BigInt(level - 1) * 5n * 60n * 60n;
    const durationHours = durations[(level - 1) % durations.length];
    const endsAt = startsAt + durationHours * 60n * 60n;
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
    rounds.push({
      config,
      signature: await signer.signTypedData(domain, roundTypes, config),
      winningCells,
    });
  }
  return { rounds };
}

async function main() {
  const payload = await seasonPayload();
  const parsed = parseSeasonManifest(payload, {
    chainId,
    managerAddress,
    signerAddress: signer.address,
  });
  assert.equal(parsed.rounds.length, SEASON_LEVEL_COUNT);
  assert.equal(parsed.seasonId, payload.rounds[0].config.seasonId);

  let expectedRoot = solidityPackedKeccak256(
    ["uint256", "uint8"],
    [parsed.seasonId, SEASON_LEVEL_COUNT],
  );
  for (const round of parsed.rounds) {
    expectedRoot = keccak256(concat([expectedRoot, round.configHash]));
  }
  assert.equal(parsed.configRoot, expectedRoot);
  assert.equal(
    parsed.lastEndsAt,
    parsed.rounds.reduce(
      (latest, round) => round.config.endsAt > latest ? round.config.endsAt : latest,
      0n,
    ),
  );

  assert.throws(
    () => parseSeasonManifest(
      { rounds: payload.rounds.slice(0, 16) },
      { chainId, managerAddress, signerAddress: signer.address },
    ),
    /complete 17-round season/,
  );

  const invalidSpacing = await seasonPayload();
  const levelTwo = invalidSpacing.rounds[1].config;
  const shiftedStart =
    invalidSpacing.rounds[0].config.startsAt + 4n * 60n * 60n;
  const shift = levelTwo.startsAt - shiftedStart;
  levelTwo.startsAt -= shift;
  levelTwo.entriesCloseAt -= shift;
  levelTwo.endsAt -= shift;
  levelTwo.freezeClosesAt -= shift;
  await assert.rejects(
    async () => parseSeasonManifest(invalidSpacing, {
      chainId,
      managerAddress,
      signerAddress: signer.address,
    }),
    /five hours apart|signature/,
  );

  const wrongSigner = Wallet.createRandom();
  assert.throws(
    () => parseSeasonManifest(payload, {
      chainId,
      managerAddress,
      signerAddress: wrongSigner.address,
    }),
    /Invalid schedule signer/,
  );
  console.log("complete season manifest validation verified");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
