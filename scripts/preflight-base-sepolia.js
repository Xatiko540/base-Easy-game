const hre = require("hardhat");

const REQUIRED_ROLE_NAMES = [
  "PROJECT_WALLET",
  "TREASURY_ADDRESS",
  "OPERATOR_WALLET",
  "ADMIN_OWNER_ADDRESS",
  "SCHEDULE_SIGNER_ADDRESS",
  "SKILL_TREASURY_ADDRESS",
];
const EIP170_MAX_RUNTIME_BYTES = 24_576;
const LINKING_GAS_RESERVE = 1_000_000n;
const BASE_GAS_PRICE_ORACLE = "0x420000000000000000000000000000000000000F";

function configuredAddress(name) {
  const value = process.env[name];
  if (!value || !hre.ethers.isAddress(value) || value === hre.ethers.ZeroAddress) return null;
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

  const balance = await hre.ethers.provider.getBalance(deployer.address);
  const roles = Object.fromEntries(
    REQUIRED_ROLE_NAMES.map((name) => [name, configuredAddress(name)]),
  );
  const usdcAddress = configuredAddress("USDC_ADDRESS");
  const expectedDeployer = configuredAddress("EXPECTED_DEPLOYER_ADDRESS");

  console.log("Base Sepolia deployment preflight");
  console.log(`Deployer: ${deployer.address}`);
  console.log(`Balance: ${hre.ethers.formatEther(balance)} ETH`);
  console.log(`EXPECTED_DEPLOYER_ADDRESS: ${expectedDeployer || "<missing>"}`);
  console.log(`USDC: ${usdcAddress || "<missing>"}`);
  for (const [name, address] of Object.entries(roles)) {
    console.log(`${name}: ${address || "<missing>"}`);
  }

  const invalid = Object.entries(roles)
    .filter(([, address]) => !address)
    .map(([name]) => name);
  if (!usdcAddress) invalid.push("USDC_ADDRESS");
  if (!expectedDeployer) invalid.push("EXPECTED_DEPLOYER_ADDRESS");
  if (invalid.length > 0) {
    throw new Error(`Missing or invalid deployment settings: ${invalid.join(", ")}`);
  }
  if (expectedDeployer !== hre.ethers.getAddress(deployer.address)) {
    throw new Error(
      `Deployment signer ${deployer.address} does not match ` +
        `EXPECTED_DEPLOYER_ADDRESS ${expectedDeployer}.`,
    );
  }
  const usdcCode = await hre.ethers.provider.getCode(usdcAddress);
  if (usdcCode === "0x") {
    throw new Error(`USDC_ADDRESS ${usdcAddress} has no bytecode on Base Sepolia.`);
  }
  if (balance === 0n) {
    throw new Error(`Deployer ${deployer.address} has no Base Sepolia ETH for gas.`);
  }

  const nonce = await hre.ethers.provider.getTransactionCount(deployer.address, "pending");
  const future = {
    manager: hre.ethers.getCreateAddress({ from: deployer.address, nonce }),
    core: hre.ethers.getCreateAddress({ from: deployer.address, nonce: nonce + 1 }),
    skills: hre.ethers.getCreateAddress({ from: deployer.address, nonce: nonce + 3 }),
  };
  const deployments = [
    ["EasyGameRoundManager", [roles.SCHEDULE_SIGNER_ADDRESS]],
    ["EasyGameAdvance", [
      roles.PROJECT_WALLET,
      roles.TREASURY_ADDRESS,
      roles.OPERATOR_WALLET,
      usdcAddress,
      future.manager,
    ]],
    ["EasyGameArenaSkills", [
      future.core,
      future.manager,
      usdcAddress,
      roles.SKILL_TREASURY_ADDRESS,
    ]],
    ["EasyGameRoundSettlement", [
      future.core,
      future.manager,
      future.skills,
      usdcAddress,
    ]],
  ];
  const oracle = new hre.ethers.Contract(
    BASE_GAS_PRICE_ORACLE,
    ["function getL1Fee(bytes data) view returns (uint256)"],
    hre.ethers.provider,
  );
  let deploymentGas = 0n;
  let l1DataFee = 0n;
  for (const [name, args] of deployments) {
    const artifact = await hre.artifacts.readArtifact(name);
    const runtimeBytes = (artifact.deployedBytecode.length - 2) / 2;
    if (runtimeBytes > EIP170_MAX_RUNTIME_BYTES) {
      throw new Error(`${name} runtime bytecode exceeds EIP-170: ${runtimeBytes}`);
    }
    const factory = await hre.ethers.getContractFactory(name);
    const transaction = await factory.getDeployTransaction(...args);
    const gas = await hre.ethers.provider.estimateGas({
      from: deployer.address,
      data: transaction.data,
    });
    const l1Fee = await oracle.getL1Fee(transaction.data);
    deploymentGas += gas;
    l1DataFee += l1Fee;
    console.log(`${name}: runtime=${runtimeBytes} bytes, deployGas=${gas}, l1Fee=${l1Fee}`);
  }
  const feeData = await hre.ethers.provider.getFeeData();
  const gasPrice = feeData.maxFeePerGas || feeData.gasPrice;
  if (!gasPrice) throw new Error("Base Sepolia RPC did not return a gas price");
  const estimatedCost = (deploymentGas + LINKING_GAS_RESERVE) * gasPrice + l1DataFee;
  const requiredWithSafetyMargin = estimatedCost * 125n / 100n;
  console.log(`Estimated deployment gas + linking reserve: ${deploymentGas + LINKING_GAS_RESERVE}`);
  console.log(`Gas price used: ${hre.ethers.formatUnits(gasPrice, "gwei")} gwei`);
  console.log(`Estimated total cost: ${hre.ethers.formatEther(estimatedCost)} ETH`);
  console.log(
    `Required with 25% safety margin: ${hre.ethers.formatEther(requiredWithSafetyMargin)} ETH`,
  );
  if (balance < requiredWithSafetyMargin) {
    throw new Error(
      `Insufficient deployer balance: ${hre.ethers.formatEther(balance)} ETH available`,
    );
  }
  console.log("Base Sepolia deployment preflight passed");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
