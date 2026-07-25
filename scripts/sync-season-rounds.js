const fs = require("node:fs");
const path = require("node:path");
const hre = require("hardhat");
const { parseSeasonManifest } = require("../functions/round_season_manifest");

const BASE_GAS_PRICE_ORACLE = "0x420000000000000000000000000000000000000F";

function requiredManifestPath() {
  const configured = String(process.env.SEASON_MANIFEST_PATH || "").trim();
  if (!configured) {
    throw new Error("SEASON_MANIFEST_PATH must point to the signed season JSON.");
  }
  const filePath = path.resolve(configured);
  if (!fs.existsSync(filePath)) throw new Error(`Season manifest not found: ${filePath}`);
  return filePath;
}

function managerAddress(chainId) {
  const artifact = require("../src/artifacts/EasyGameRoundManager.json");
  const configured = String(process.env.EASY_GAME_ROUND_MANAGER_ADDRESS || "").trim();
  const address = configured || artifact.networks?.[String(chainId)]?.address;
  if (!address || !hre.ethers.isAddress(address)) {
    throw new Error(`Missing EasyGameRoundManager address for chain ${chainId}`);
  }
  return hre.ethers.getAddress(address);
}

async function l1DataFee(transactionData, chainId) {
  if (chainId !== 8453 && chainId !== 84532) return 0n;
  const oracle = new hre.ethers.Contract(
    BASE_GAS_PRICE_ORACLE,
    ["function getL1Fee(bytes data) view returns (uint256)"],
    hre.ethers.provider,
  );
  return oracle.getL1Fee(transactionData);
}

async function waitForInitializedRound(manager, round) {
  let state;
  for (let attempt = 0; attempt < 8; attempt += 1) {
    state = await manager.getRoundState(round.config.roundId);
    if (
      state.initialized &&
      state.configHash.toLowerCase() === round.configHash.toLowerCase()
    ) {
      return state;
    }
    await new Promise((resolve) => setTimeout(resolve, 1500));
  }
  return state;
}

async function main() {
  const network = await hre.ethers.provider.getNetwork();
  const chainId = Number(network.chainId);
  const filePath = requiredManifestPath();
  const address = managerAddress(chainId);
  const manager = await hre.ethers.getContractAt("EasyGameRoundManager", address);
  const scheduleSigner = await manager.scheduleSigner();
  const payload = JSON.parse(fs.readFileSync(filePath, "utf8"));
  const parsed = parseSeasonManifest(payload, {
    chainId,
    managerAddress: address,
    signerAddress: scheduleSigner,
  });
  const season = await manager.getSeasonState(parsed.seasonId);
  if (!season.committed || season.configRoot.toLowerCase() !== parsed.configRoot.toLowerCase()) {
    throw new Error("On-chain season commitment does not match the signed manifest");
  }

  const block = await hre.ethers.provider.getBlock("latest");
  if (!block) throw new Error("Unable to read the latest Base block");
  const ready = [];
  const initialized = [];
  const scheduled = [];
  for (const round of parsed.rounds) {
    const [committedHash, state] = await Promise.all([
      manager.getCommittedRoundHash(parsed.seasonId, round.config.level),
      manager.getRoundState(round.config.roundId),
    ]);
    if (committedHash.toLowerCase() !== round.configHash.toLowerCase()) {
      throw new Error(`Committed hash mismatch for level ${round.config.level}`);
    }
    if (state.initialized) {
      if (state.configHash.toLowerCase() !== round.configHash.toLowerCase()) {
        throw new Error(`Initialized hash mismatch for level ${round.config.level}`);
      }
      initialized.push(round);
    } else if (round.config.startsAt <= BigInt(block.timestamp)) {
      ready.push(round);
    } else {
      scheduled.push(round);
    }
  }

  console.log(`Chain ID: ${chainId}`);
  console.log(`Round manager: ${address}`);
  console.log(`Season ID: ${parsed.seasonId}`);
  console.log(`Latest block timestamp: ${block.timestamp}`);
  console.log(`Already initialized: ${initialized.length}`);
  console.log(`Ready to initialize: ${ready.length}`);
  console.log(`Future committed rounds: ${scheduled.length}`);
  if (ready.length === 0) {
    console.log("Season rounds are already synchronized for the current chain time");
    return;
  }

  const [signer] = await hre.ethers.getSigners();
  if (!signer) throw new Error("No transaction signer configured");
  const expectedSigner = String(process.env.EXPECTED_DEPLOYER_ADDRESS || "").trim();
  if (
    expectedSigner &&
    hre.ethers.getAddress(expectedSigner) !== hre.ethers.getAddress(signer.address)
  ) {
    throw new Error("Transaction signer does not match EXPECTED_DEPLOYER_ADDRESS");
  }

  const feeData = await hre.ethers.provider.getFeeData();
  const gasPrice = feeData.maxFeePerGas || feeData.gasPrice;
  if (!gasPrice) throw new Error("Base Sepolia RPC did not return a gas price");
  let totalGas = 0n;
  let totalL1Fee = 0n;
  for (const round of ready) {
    const transaction = await manager.initializeRound.populateTransaction(
      round.config,
      round.signature,
    );
    totalGas += await manager.initializeRound.estimateGas(round.config, round.signature);
    totalL1Fee += await l1DataFee(transaction.data, chainId);
  }
  const estimatedCost = totalGas * gasPrice + totalL1Fee;
  const requiredWithMargin = estimatedCost * 125n / 100n;
  const balance = await hre.ethers.provider.getBalance(signer.address);
  console.log(`Transaction signer: ${signer.address}`);
  console.log(`Estimated synchronization cost: ${hre.ethers.formatEther(estimatedCost)} ETH`);
  console.log(`Signer balance: ${hre.ethers.formatEther(balance)} ETH`);
  if (balance < requiredWithMargin) {
    throw new Error(
      `Insufficient balance: ${hre.ethers.formatEther(requiredWithMargin)} ETH required`,
    );
  }
  if (process.env.CONFIRM_SYNC_SEASON !== "true") {
    throw new Error(
      "Dry run complete. Set CONFIRM_SYNC_SEASON=true to initialize started rounds.",
    );
  }

  for (const round of ready) {
    const transaction = await manager.initializeRound(round.config, round.signature);
    console.log(`Level ${round.config.level}: ${transaction.hash}`);
    await transaction.wait();
    const state = await waitForInitializedRound(manager, round);
    if (!state.initialized || state.configHash.toLowerCase() !== round.configHash.toLowerCase()) {
      throw new Error(`Level ${round.config.level} synchronization verification failed`);
    }
  }
  console.log(`Synchronized started rounds: ${ready.length}`);
}

main().catch((error) => {
  console.error(error.shortMessage || error.message || error);
  process.exitCode = 1;
});
