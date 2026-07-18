const hre = require("hardhat");

const REQUIRED_ROLE_NAMES = [
  "PROJECT_WALLET",
  "TREASURY_ADDRESS",
  "OPERATOR_WALLET",
  "ADMIN_OWNER_ADDRESS",
  "SCHEDULE_SIGNER_ADDRESS",
  "SKILL_TREASURY_ADDRESS",
];

function requiredAddress(name) {
  const value = process.env[name];
  if (!value || !hre.ethers.isAddress(value) || value === hre.ethers.ZeroAddress) {
    throw new Error(`${name} must be configured with a non-zero address.`);
  }
  return hre.ethers.getAddress(value);
}

async function main() {
  const network = await hre.ethers.provider.getNetwork();
  if (Number(network.chainId) !== 84532) {
    throw new Error(`Expected Base Sepolia chain 84532, received ${network.chainId}.`);
  }

  const [deployer] = await hre.ethers.getSigners();
  if (!deployer) {
    throw new Error("No deployment signer configured.");
  }

  const roles = Object.fromEntries(
    REQUIRED_ROLE_NAMES.map((name) => [name, requiredAddress(name)])
  );
  const usdcAddress = requiredAddress("USDC_ADDRESS");
  const usdcCode = await hre.ethers.provider.getCode(usdcAddress);
  if (usdcCode === "0x") {
    throw new Error(`USDC_ADDRESS ${usdcAddress} has no bytecode on Base Sepolia.`);
  }

  const balance = await hre.ethers.provider.getBalance(deployer.address);
  if (balance === 0n) {
    throw new Error(`Deployer ${deployer.address} has no Base Sepolia ETH for gas.`);
  }

  console.log("Base Sepolia deployment preflight passed");
  console.log(`Deployer: ${deployer.address}`);
  console.log(`Balance: ${hre.ethers.formatEther(balance)} ETH`);
  console.log(`USDC: ${usdcAddress}`);
  for (const [name, address] of Object.entries(roles)) {
    console.log(`${name}: ${address}`);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
