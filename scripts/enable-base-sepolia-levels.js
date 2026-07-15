const hre = require("hardhat");

const DEFAULT_CORE = "0x6d878b377e6CCE9B0134bF306A6c85880EF5B139";

function requestedLevels() {
  const source = process.env.TARGET_LEVELS || "1,2";
  const levels = source
    .split(",")
    .map((value) => Number(value.trim()))
    .filter((value) => Number.isInteger(value) && value >= 1 && value <= 17);
  if (levels.length === 0) throw new Error("TARGET_LEVELS must contain levels 1-17");
  return [...new Set(levels)];
}

async function main() {
  const network = await hre.ethers.provider.getNetwork();
  if (Number(network.chainId) !== 84532) {
    throw new Error(`Expected Base Sepolia (84532), received ${network.chainId}`);
  }

  const [signer] = await hre.ethers.getSigners();
  if (!signer) throw new Error("Configure the contract owner signer first");

  const address = process.env.EASY_GAME_CONTRACT_ADDRESS || DEFAULT_CORE;
  const core = await hre.ethers.getContractAt("EasyGameAdvance", address, signer);
  const owner = await core.owner();
  if (owner.toLowerCase() !== signer.address.toLowerCase()) {
    throw new Error(
      `Configured signer ${signer.address} is not contract owner ${owner}`
    );
  }

  const levels = requestedLevels();
  const disabled = [];
  for (const level of levels) {
    if (!(await core.levelAvailable(level))) disabled.push(level);
  }

  if (disabled.length === 0) {
    console.log(`Levels ${levels.join(", ")} are already enabled`);
    return;
  }
  if (process.env.CONFIRM_ENABLE_LEVELS !== "true") {
    throw new Error(
      `Levels ${disabled.join(", ")} are paused. Re-run with CONFIRM_ENABLE_LEVELS=true to send owner transactions.`
    );
  }

  for (const level of disabled) {
    const transaction = await core.setLevelAvailable(level, true);
    console.log(`Enabling level ${level}: ${transaction.hash}`);
    await transaction.wait();
  }
  console.log(`Enabled Base Sepolia levels: ${disabled.join(", ")}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
