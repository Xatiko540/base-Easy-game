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
  const signers = await hre.ethers.getSigners();
  const [deployer] = signers;
  const network = await hre.ethers.provider.getNetwork();
  const chainId = Number(network.chainId);
  const isLocalNetwork = [1337, 31337, 5777].includes(chainId);
  const useLocalWallets =
    isLocalNetwork && process.env.LOCAL_USE_ENV_WALLETS !== "true";
  const projectWallet = useLocalWallets
    ? deployer.address
    : process.env.PROJECT_WALLET || deployer.address;
  const treasuryAddress = useLocalWallets
    ? deployer.address
    : process.env.TREASURY_ADDRESS || deployer.address;
  const operatorWallet = useLocalWallets
    ? deployer.address
    : process.env.OPERATOR_WALLET || deployer.address;
  const basePayFulfiller = useLocalWallets
    ? deployer.address
    : process.env.BASE_PAY_FULFILLER_ADDRESS || operatorWallet;
  let usdcAddress = process.env.USDC_ADDRESS || "";
  let mockUsdc;
  const deployLegacyLottery = process.env.DEPLOY_LEGACY_LOTTERY === "true";

  if (isLocalNetwork && process.env.LOCAL_USE_MOCK_USDC !== "false") {
    const MockUSDC = await hre.ethers.getContractFactory("MockUSDC");
    mockUsdc = await MockUSDC.deploy();
    await mockUsdc.waitForDeployment();
    usdcAddress = await mockUsdc.getAddress();
    console.log(`MockUSDC deployed to: ${usdcAddress}`);
  }

  console.log(`Deploying with account: ${deployer.address}`);
  console.log(`Network: ${network.name} (${network.chainId})`);
  console.log(`Project wallet: ${projectWallet}`);
  console.log(`Treasury: ${treasuryAddress}`);
  console.log(`Operator wallet: ${operatorWallet}`);
  console.log(`Base Pay fulfiller: ${basePayFulfiller}`);
  console.log(`USDC token: ${usdcAddress}`);

  if (
    !hre.ethers.isAddress(usdcAddress) ||
    usdcAddress === hre.ethers.ZeroAddress
  ) {
    throw new Error(
      "USDC_ADDRESS must be configured with a non-zero token address before deploying EasyGameAdvance."
    );
  }

  if (deployLegacyLottery) {
    const LotteryGenerator = await hre.ethers.getContractFactory(
      "LotteryGenerator"
    );
    const lotteryGenerator = await LotteryGenerator.deploy();
    await lotteryGenerator.waitForDeployment();

    const address = await lotteryGenerator.getAddress();
    console.log(`LotteryGenerator deployed to: ${address}`);

    updateAppArtifact("LotteryGenerator", network.chainId, address);
  }

  const EasyGameRoundManager = await hre.ethers.getContractFactory(
    "EasyGameRoundManager"
  );
  const roundManager = await EasyGameRoundManager.deploy(operatorWallet);
  await roundManager.waitForDeployment();
  const roundManagerAddress = await roundManager.getAddress();
  console.log(`EasyGameRoundManager deployed to: ${roundManagerAddress}`);

  const EasyGameAdvance = await hre.ethers.getContractFactory(
    "EasyGameAdvance"
  );
  const easyGame = await EasyGameAdvance.deploy(
    projectWallet,
    treasuryAddress,
    operatorWallet,
    usdcAddress,
    roundManagerAddress
  );
  await easyGame.waitForDeployment();

  const easyGameAddress = await easyGame.getAddress();
  console.log(`EasyGameAdvance deployed to: ${easyGameAddress}`);

  const setCoreTx = await roundManager.setGameCore(easyGameAddress);
  await setCoreTx.wait();
  console.log("Round manager linked to EasyGameAdvance");

  const EasyGameBasePayGateway = await hre.ethers.getContractFactory(
    "EasyGameBasePayGateway"
  );
  const basePayGateway = await EasyGameBasePayGateway.deploy(
    easyGameAddress,
    usdcAddress,
    basePayFulfiller
  );
  await basePayGateway.waitForDeployment();
  const basePayGatewayAddress = await basePayGateway.getAddress();
  await (await easyGame.setBasePayGateway(basePayGatewayAddress)).wait();
  console.log(`EasyGameBasePayGateway deployed to: ${basePayGatewayAddress}`);

  const EasyGameArenaSkills = await hre.ethers.getContractFactory(
    "EasyGameArenaSkills"
  );
  const arenaSkills = await EasyGameArenaSkills.deploy(
    easyGameAddress,
    roundManagerAddress,
    usdcAddress,
    projectWallet
  );
  await arenaSkills.waitForDeployment();
  const arenaSkillsAddress = await arenaSkills.getAddress();
  console.log(`EasyGameArenaSkills deployed to: ${arenaSkillsAddress}`);

  const EasyGameRoundSettlement = await hre.ethers.getContractFactory(
    "EasyGameRoundSettlement"
  );
  const settlement = await EasyGameRoundSettlement.deploy(
    easyGameAddress,
    roundManagerAddress,
    arenaSkillsAddress,
    usdcAddress
  );
  await settlement.waitForDeployment();
  const settlementAddress = await settlement.getAddress();
  console.log(`EasyGameRoundSettlement deployed to: ${settlementAddress}`);

  await (await easyGame.setSettlementContract(settlementAddress)).wait();
  await (await roundManager.setSettlementContract(settlementAddress)).wait();
  console.log("Settlement linked to core and round manager");

  if (mockUsdc) {
    for (const signer of signers.slice(0, 10)) {
      await (await mockUsdc.mint(signer.address, 1_000_000_000n)).wait();
    }
    console.log("Minted 1000 MockUSDC to the first 10 local accounts");
  }

  updateAppArtifact("EasyGameRoundManager", network.chainId, roundManagerAddress);
  updateAppArtifact("EasyGameAdvance", network.chainId, easyGameAddress);
  updateAppArtifact("EasyGameArenaSkills", network.chainId, arenaSkillsAddress);
  updateAppArtifact("EasyGameRoundSettlement", network.chainId, settlementAddress);
  updateAppArtifact("EasyGameBasePayGateway", network.chainId, basePayGatewayAddress);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
