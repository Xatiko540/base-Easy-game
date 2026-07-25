const fs = require("node:fs");
const path = require("node:path");
const hre = require("hardhat");
const { parseSeasonManifest } = require("../functions/round_season_manifest");

const BASE_GAS_PRICE_ORACLE = "0x420000000000000000000000000000000000000F";

async function waitForCommittedState(manager, seasonId, expectedRoot) {
  let state;
  for (let attempt = 0; attempt < 6; attempt += 1) {
    state = await manager.getSeasonState(seasonId);
    if (
      state.committed &&
      state.configRoot.toLowerCase() === expectedRoot.toLowerCase()
    ) {
      return state;
    }
    await new Promise((resolve) => setTimeout(resolve, 1500));
  }
  return state;
}

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

async function main() {
  const network = await hre.ethers.provider.getNetwork();
  const chainId = Number(network.chainId);
  const filePath = requiredManifestPath();
  const address = managerAddress(chainId);
  const manager = await hre.ethers.getContractAt("EasyGameRoundManager", address);
  const payload = JSON.parse(fs.readFileSync(filePath, "utf8"));
  if (payload.chainId !== undefined && Number(payload.chainId) !== chainId) {
    throw new Error(`Manifest chain ${payload.chainId} does not match ${chainId}.`);
  }
  if (
    payload.managerAddress !== undefined &&
    hre.ethers.getAddress(payload.managerAddress) !== address
  ) {
    throw new Error("Manifest Round Manager does not match the deployment.");
  }
  const scheduleSigner = await manager.scheduleSigner();
  const parsed = parseSeasonManifest(payload, {
    chainId,
    managerAddress: address,
    signerAddress: scheduleSigner,
  });
  const configs = parsed.rounds.map((round) => round.config);
  const signatures = parsed.rounds.map((round) => round.signature);
  const expectedRoot = await manager.commitSeason.staticCall(configs, signatures);
  const [deployer] = await hre.ethers.getSigners();
  const expectedDeployer = String(process.env.EXPECTED_DEPLOYER_ADDRESS || "").trim();
  if (
    expectedDeployer &&
    hre.ethers.getAddress(expectedDeployer) !== hre.ethers.getAddress(deployer.address)
  ) {
    throw new Error("Commit signer does not match EXPECTED_DEPLOYER_ADDRESS");
  }
  const populated = await manager.commitSeason.populateTransaction(configs, signatures);
  const [gasEstimate, feeData, balance] = await Promise.all([
    manager.commitSeason.estimateGas(configs, signatures),
    hre.ethers.provider.getFeeData(),
    hre.ethers.provider.getBalance(deployer.address),
  ]);
  const gasPrice = feeData.maxFeePerGas || feeData.gasPrice;
  if (!gasPrice) throw new Error("Base Sepolia RPC did not return a gas price");
  let l1DataFee = 0n;
  if (chainId === 8453 || chainId === 84532) {
    const oracle = new hre.ethers.Contract(
      BASE_GAS_PRICE_ORACLE,
      ["function getL1Fee(bytes data) view returns (uint256)"],
      hre.ethers.provider,
    );
    l1DataFee = await oracle.getL1Fee(populated.data);
  }
  const estimatedCost = gasEstimate * gasPrice + l1DataFee;
  const requiredWithMargin = estimatedCost * 125n / 100n;
  console.log(`Commit gas estimate: ${gasEstimate}`);
  console.log(`Estimated commit cost: ${hre.ethers.formatEther(estimatedCost)} ETH`);
  console.log(`Balance before commit: ${hre.ethers.formatEther(balance)} ETH`);
  if (balance < requiredWithMargin) {
    throw new Error(
      `Insufficient balance for commitment with 25% safety margin: ` +
        `${hre.ethers.formatEther(requiredWithMargin)} ETH required`,
    );
  }
  const transaction = await manager.commitSeason(configs, signatures);
  const receipt = await transaction.wait();
  const seasonId = parsed.seasonId.toString();
  console.log(`Transaction: ${receipt.hash}`);
  const state = await waitForCommittedState(manager, seasonId, parsed.configRoot);

  if (
    !state.committed ||
    state.configRoot.toLowerCase() !== expectedRoot.toLowerCase() ||
    state.configRoot.toLowerCase() !== parsed.configRoot.toLowerCase()
  ) {
    throw new Error("Stored season commitment does not match the submitted manifest.");
  }
  for (const round of parsed.rounds) {
    const committed = await manager.getCommittedRoundHash(seasonId, round.config.level);
    if (committed.toLowerCase() !== round.configHash.toLowerCase()) {
      throw new Error(`Committed hash mismatch for level ${round.config.level}.`);
    }
  }
  console.log(`Chain ID: ${chainId}`);
  console.log(`Round manager: ${address}`);
  console.log(`Season ID: ${seasonId}`);
  console.log(`Config root: ${state.configRoot}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
