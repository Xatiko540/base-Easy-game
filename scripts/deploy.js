const fs = require("fs");
const path = require("path");
const hre = require("hardhat");

function updateAppArtifact(contractName, chainId, address) {
  const artifactPath = path.join(
    __dirname,
    "..",
    "src",
    "artifacts",
    `${contractName}.json`
  );
  const sourceArtifactPath = path.join(
    __dirname,
    "..",
    "artifacts",
    "contracts",
    contractName === "Lottery" || contractName === "LotteryGenerator"
      ? "Lottery_Advance.sol"
      : `${contractName}.sol`,
    `${contractName}.json`
  );
  const artifact = JSON.parse(
    fs.readFileSync(
      fs.existsSync(artifactPath) ? artifactPath : sourceArtifactPath,
      "utf8"
    )
  );

  artifact.networks = artifact.networks || {};
  artifact.networks[String(chainId)] = {
    ...(artifact.networks[String(chainId)] || {}),
    address,
  };

  fs.writeFileSync(artifactPath, `${JSON.stringify(artifact, null, 2)}\n`);
}

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  const network = await hre.ethers.provider.getNetwork();
  const projectWallet = process.env.PROJECT_WALLET || deployer.address;
  const treasuryAddress = process.env.TREASURY_ADDRESS || deployer.address;
  const operatorWallet = process.env.OPERATOR_WALLET || deployer.address;
  const usdcAddress =
    process.env.USDC_ADDRESS || "0x0000000000000000000000000000000000000000";

  console.log(`Deploying with account: ${deployer.address}`);
  console.log(`Network: ${network.name} (${network.chainId})`);
  console.log(`Project wallet: ${projectWallet}`);
  console.log(`Treasury: ${treasuryAddress}`);
  console.log(`Operator wallet: ${operatorWallet}`);
  console.log(`USDC token: ${usdcAddress}`);

  const LotteryGenerator = await hre.ethers.getContractFactory(
    "LotteryGenerator"
  );
  const lotteryGenerator = await LotteryGenerator.deploy();
  await lotteryGenerator.waitForDeployment();

  const address = await lotteryGenerator.getAddress();
  console.log(`LotteryGenerator deployed to: ${address}`);

  updateAppArtifact("LotteryGenerator", network.chainId, address);

  const EasyGameAdvance = await hre.ethers.getContractFactory(
    "EasyGameAdvance"
  );
  const easyGame = await EasyGameAdvance.deploy(
    projectWallet,
    treasuryAddress,
    operatorWallet,
    usdcAddress
  );
  await easyGame.waitForDeployment();

  const easyGameAddress = await easyGame.getAddress();
  console.log(`EasyGameAdvance deployed to: ${easyGameAddress}`);

  updateAppArtifact("EasyGameAdvance", network.chainId, easyGameAddress);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
