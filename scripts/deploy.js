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
  const treasuryAddress = process.env.TREASURY_ADDRESS || deployer.address;
  const operatorWallet = process.env.OPERATOR_WALLET || treasuryAddress;

  console.log(`Deploying with account: ${deployer.address}`);
  console.log(`Network: ${network.name} (${network.chainId})`);
  console.log(`Treasury: ${treasuryAddress}`);
  console.log(`Operator wallet: ${operatorWallet}`);

  const LotteryGenerator = await hre.ethers.getContractFactory(
    "LotteryGenerator"
  );
  const lotteryGenerator = await LotteryGenerator.deploy();
  await lotteryGenerator.waitForDeployment();

  const address = await lotteryGenerator.getAddress();
  console.log(`LotteryGenerator deployed to: ${address}`);

  updateAppArtifact("LotteryGenerator", network.chainId, address);

  const EasyGame = await hre.ethers.getContractFactory("EasyGame");
  const easyGame = await EasyGame.deploy(treasuryAddress);
  await easyGame.waitForDeployment();

  const easyGameAddress = await easyGame.getAddress();
  console.log(`EasyGame deployed to: ${easyGameAddress}`);

  if (operatorWallet !== treasuryAddress) {
    const tx = await easyGame.setOperatorWallet(operatorWallet);
    await tx.wait();
    console.log(`EasyGame operator wallet set to: ${operatorWallet}`);
  }

  updateAppArtifact("EasyGame", network.chainId, easyGameAddress);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
