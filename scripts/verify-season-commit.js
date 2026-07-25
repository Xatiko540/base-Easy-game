const fs = require("node:fs");
const path = require("node:path");
const hre = require("hardhat");
const { parseSeasonManifest } = require("../functions/round_season_manifest");

async function main() {
  const manifestPath = path.resolve(String(process.env.SEASON_MANIFEST_PATH || ""));
  if (!process.env.SEASON_MANIFEST_PATH || !fs.existsSync(manifestPath)) {
    throw new Error("SEASON_MANIFEST_PATH must point to the signed season JSON");
  }
  const network = await hre.ethers.provider.getNetwork();
  const chainId = Number(network.chainId);
  const artifact = require("../src/artifacts/EasyGameRoundManager.json");
  const deployment = require("../deployments/baseSepolia-84532.json");
  const managerAddress = artifact.networks?.[String(chainId)]?.address;
  if (!managerAddress) throw new Error(`Missing Round Manager for chain ${chainId}`);
  const manager = await hre.ethers.getContractAt("EasyGameRoundManager", managerAddress);
  const signerAddress = await manager.scheduleSigner();
  const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
  const parsed = parseSeasonManifest(manifest, {
    chainId,
    managerAddress,
    signerAddress,
  });
  const state = await manager.getSeasonState(parsed.seasonId);
  const events = await manager.queryFilter(
    manager.filters.SeasonCommitted(parsed.seasonId),
    Number(deployment.startBlock),
    "latest",
  );
  const mismatches = [];
  for (const round of parsed.rounds) {
    const [storedHash, contractHash] = await Promise.all([
      manager.getCommittedRoundHash(parsed.seasonId, round.config.level),
      manager.hashRoundConfig(round.config),
    ]);
    if (storedHash.toLowerCase() !== round.configHash.toLowerCase()) {
      mismatches.push(`stored level ${round.config.level}`);
    }
    if (contractHash.toLowerCase() !== round.configHash.toLowerCase()) {
      mismatches.push(`computed level ${round.config.level}`);
    }
  }
  console.log(`Season ID: ${parsed.seasonId}`);
  console.log(`Committed: ${state.committed}`);
  console.log(`Manifest root: ${parsed.configRoot}`);
  console.log(`On-chain root: ${state.configRoot}`);
  console.log(`First start: ${state.firstStartsAt}`);
  console.log(`Last end: ${state.lastEndsAt}`);
  console.log(`SeasonCommitted transaction: ${events.at(-1)?.transactionHash || "<missing>"}`);
  console.log(`Round hash mismatches: ${mismatches.length}`);
  if (
    !state.committed ||
    state.configRoot.toLowerCase() !== parsed.configRoot.toLowerCase() ||
    mismatches.length > 0
  ) {
    throw new Error(`Season commitment verification failed: ${mismatches.join(", ")}`);
  }
  console.log("Season commitment verification passed");
}

main().catch((error) => {
  console.error(error.message || error);
  process.exitCode = 1;
});
