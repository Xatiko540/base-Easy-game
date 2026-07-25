const assert = require("node:assert/strict");
const { Wallet } = require("ethers");

const { buildSignedSeasonManifest } = require("./season_manifest_builder");
const { parseSeasonManifest } = require("./round_season_manifest");

const chainId = 84532;
const managerAddress = "0x1111111111111111111111111111111111111111";

function spec() {
  return {
    seasonId: "2026071901",
    firstStartsAt: "1800000000",
    levelOpenIntervalSeconds: "18000",
    entryWindowSeconds: Array.from({ length: 17 }, () => "43200"),
    roundDurationSeconds: Array.from(
      { length: 17 },
      (_, index) => String(86400 + index * 3600),
    ),
    maxPlayers: "1000000",
    ethPricesWei: Array.from({ length: 17 }, () => "100000000000000"),
    usdcPrices: Array.from({ length: 17 }, () => "100000"),
    winningCellsByLevel: Array.from({ length: 17 }, () => ["7", "15", "31"]),
  };
}

async function main() {
  const signer = Wallet.createRandom();
  const payload = await buildSignedSeasonManifest(spec(), {
    chainId,
    managerAddress,
    signer,
  });
  const parsed = parseSeasonManifest(payload, {
    chainId,
    managerAddress,
    signerAddress: signer.address,
  });
  assert.equal(parsed.rounds.length, 17);
  assert.equal(new Set(parsed.rounds.map((round) => round.config.roundId.toString())).size, 17);
  assert.equal(
    new Set(parsed.rounds.map((round) =>
      (round.config.endsAt - round.config.startsAt).toString())).size,
    17,
  );
  parsed.rounds.forEach((round) => {
    const duration = round.config.endsAt - round.config.startsAt;
    assert.equal(round.config.freezeLimit, ((duration + 86399n) / 86400n) * 10n);
  });
  assert.equal(JSON.stringify(payload).includes(signer.privateKey), false);

  const invalid = spec();
  invalid.roundDurationSeconds = Array.from({ length: 17 }, () => "86400");
  await assert.rejects(
    buildSignedSeasonManifest(invalid, { chainId, managerAddress, signer }),
    /durations must be different/,
  );
  console.log("production season manifest builder verified");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
