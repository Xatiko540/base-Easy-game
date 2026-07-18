const fs = require("node:fs");
const path = require("node:path");
const hre = require("hardhat");

const LEVEL_COUNT = 17;

function requiredManifestPath() {
  const configured = process.env.SEASON_MANIFEST_PATH;
  if (!configured) {
    throw new Error("SEASON_MANIFEST_PATH must point to the signed season JSON file.");
  }
  return path.resolve(configured);
}

function managerAddress(chainId) {
  const configured = process.env.EASY_GAME_ROUND_MANAGER_ADDRESS;
  if (configured && hre.ethers.isAddress(configured)) {
    return hre.ethers.getAddress(configured);
  }
  const artifactPath = path.join(
    __dirname,
    "..",
    "src",
    "artifacts",
    "EasyGameRoundManager.json",
  );
  const artifact = JSON.parse(fs.readFileSync(artifactPath, "utf8"));
  const deployed = artifact.networks?.[String(chainId)]?.address;
  if (!deployed || !hre.ethers.isAddress(deployed)) {
    throw new Error(
      `No EasyGameRoundManager address for chain ${chainId}. ` +
        "Set EASY_GAME_ROUND_MANAGER_ADDRESS.",
    );
  }
  return hre.ethers.getAddress(deployed);
}

function parseManifest(filePath) {
  const payload = JSON.parse(fs.readFileSync(filePath, "utf8"));
  if (!Array.isArray(payload.rounds) || payload.rounds.length !== LEVEL_COUNT) {
    throw new Error(`The manifest must contain exactly ${LEVEL_COUNT} rounds.`);
  }
  const configs = [];
  const signatures = [];
  payload.rounds.forEach((round, index) => {
    if (!round?.config || typeof round.signature !== "string") {
      throw new Error(`Missing config or signature for level ${index + 1}.`);
    }
    if (Number(round.config.level) !== index + 1) {
      throw new Error(`Rounds must be ordered from level 1 through ${LEVEL_COUNT}.`);
    }
    configs.push(round.config);
    signatures.push(round.signature);
  });
  return { configs, signatures };
}

async function main() {
  const network = await hre.ethers.provider.getNetwork();
  const chainId = Number(network.chainId);
  const filePath = requiredManifestPath();
  const { configs, signatures } = parseManifest(filePath);
  const address = managerAddress(chainId);
  const manager = await hre.ethers.getContractAt("EasyGameRoundManager", address);
  const expectedRoot = await manager.commitSeason.staticCall(configs, signatures);
  const transaction = await manager.commitSeason(configs, signatures);
  const receipt = await transaction.wait();
  const seasonId = configs[0].seasonId.toString();
  const state = await manager.getSeasonState(seasonId);

  if (!state.committed || state.configRoot !== expectedRoot) {
    throw new Error("Stored season commitment does not match the submitted manifest.");
  }
  console.log(`Chain ID: ${chainId}`);
  console.log(`Round manager: ${address}`);
  console.log(`Season ID: ${seasonId}`);
  console.log(`Config root: ${state.configRoot}`);
  console.log(`Transaction: ${receipt.hash}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
