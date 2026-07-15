const fs = require("fs");
const path = require("path");
const hre = require("hardhat");

const deploymentSummary = {
  chainId: null,
  deployer: null,
  startBlock: null,
  contracts: {},
  transactions: {},
};

async function recordDeployment(name, contract) {
  const address = await contract.getAddress();
  const transaction = contract.deploymentTransaction();
  if (!transaction) {
    throw new Error(`Deployment transaction is unavailable for ${name}.`);
  }
  const receipt = await transaction.wait();
  deploymentSummary.startBlock =
    deploymentSummary.startBlock === null
      ? receipt.blockNumber
      : Math.min(deploymentSummary.startBlock, receipt.blockNumber);
  deploymentSummary.contracts[name] = address;
  deploymentSummary.transactions[`${name}.deploy`] = {
    hash: transaction.hash,
    blockNumber: receipt.blockNumber,
    gasUsed: receipt.gasUsed.toString(),
  };
  console.log(
    `${name} deployed to: ${address} (tx: ${transaction.hash}, block: ${receipt.blockNumber})`
  );
  return address;
}

async function recordTransaction(name, transaction) {
  const receipt = await transaction.wait();
  deploymentSummary.transactions[name] = {
    hash: transaction.hash,
    blockNumber: receipt.blockNumber,
    gasUsed: receipt.gasUsed.toString(),
  };
  console.log(
    `${name} confirmed (tx: ${transaction.hash}, block: ${receipt.blockNumber})`
  );
  return receipt;
}

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
  if (!deployer) {
    throw new Error(
      "No deployment signer configured. Set DEPLOYER_PRIVATE_KEY or MNEMONIC in the ignored .env file."
    );
  }
  const network = await hre.ethers.provider.getNetwork();
  const chainId = Number(network.chainId);
  deploymentSummary.chainId = chainId;
  deploymentSummary.deployer = deployer.address;
  const expectedDeployer = process.env.EXPECTED_DEPLOYER_ADDRESS || "";
  if (
    expectedDeployer &&
    (!hre.ethers.isAddress(expectedDeployer) ||
      hre.ethers.getAddress(expectedDeployer) !==
        hre.ethers.getAddress(deployer.address))
  ) {
    throw new Error(
      `Deployment signer ${deployer.address} does not match EXPECTED_DEPLOYER_ADDRESS ${expectedDeployer}.`
    );
  }
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
  const uniformTestLevelPriceEth = String(
    process.env.TEST_UNIFORM_LEVEL_PRICE_ETH || ""
  ).trim();

  if (isLocalNetwork && process.env.LOCAL_USE_MOCK_USDC !== "false") {
    const MockUSDC = await hre.ethers.getContractFactory("MockUSDC");
    mockUsdc = await MockUSDC.deploy();
    await mockUsdc.waitForDeployment();
    usdcAddress = await recordDeployment("MockUSDC", mockUsdc);
  }

  console.log(`Deploying with account: ${deployer.address}`);
  console.log(
    `Deployer balance: ${hre.ethers.formatEther(
      await hre.ethers.provider.getBalance(deployer.address)
    )} ETH`
  );
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

    const address = await recordDeployment(
      "LotteryGenerator",
      lotteryGenerator
    );

    updateAppArtifact("LotteryGenerator", network.chainId, address);
  }

  const EasyGameRoundManager = await hre.ethers.getContractFactory(
    "EasyGameRoundManager"
  );
  const roundManager = await EasyGameRoundManager.deploy(operatorWallet);
  await roundManager.waitForDeployment();
  const roundManagerAddress = await recordDeployment(
    "EasyGameRoundManager",
    roundManager
  );

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

  const easyGameAddress = await recordDeployment("EasyGameAdvance", easyGame);

  if (uniformTestLevelPriceEth) {
    if (![84532, 1337, 31337, 5777].includes(chainId)) {
      throw new Error(
        "TEST_UNIFORM_LEVEL_PRICE_ETH is restricted to Base Sepolia and local networks."
      );
    }
    const uniformPrice = hre.ethers.parseEther(uniformTestLevelPriceEth);
    if (uniformPrice <= 0n) {
      throw new Error("TEST_UNIFORM_LEVEL_PRICE_ETH must be greater than zero.");
    }
    for (let level = 1; level <= 17; level += 1) {
      await recordTransaction(
        `EasyGameAdvance.setLevelPrice.${level}`,
        await easyGame.setLevelPrice(level, uniformPrice)
      );
    }
    console.log(
      `Configured all 17 ETH level prices to ${uniformTestLevelPriceEth} ETH.`
    );
  }

  const setCoreTx = await roundManager.setGameCore(easyGameAddress);
  await recordTransaction("RoundManager.setGameCore", setCoreTx);

  const EasyGameBasePayGateway = await hre.ethers.getContractFactory(
    "EasyGameBasePayGateway"
  );
  const basePayGateway = await EasyGameBasePayGateway.deploy(
    easyGameAddress,
    usdcAddress,
    basePayFulfiller
  );
  await basePayGateway.waitForDeployment();
  const basePayGatewayAddress = await recordDeployment(
    "EasyGameBasePayGateway",
    basePayGateway
  );
  await recordTransaction(
    "EasyGameAdvance.setBasePayGateway",
    await easyGame.setBasePayGateway(basePayGatewayAddress)
  );

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
  const arenaSkillsAddress = await recordDeployment(
    "EasyGameArenaSkills",
    arenaSkills
  );

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
  const settlementAddress = await recordDeployment(
    "EasyGameRoundSettlement",
    settlement
  );

  await recordTransaction(
    "EasyGameAdvance.setSettlementContract",
    await easyGame.setSettlementContract(settlementAddress)
  );
  await recordTransaction(
    "RoundManager.setSettlementContract",
    await roundManager.setSettlementContract(settlementAddress)
  );

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

  console.log("DEPLOYMENT_SUMMARY_START");
  console.log(JSON.stringify(deploymentSummary, null, 2));
  console.log("DEPLOYMENT_SUMMARY_END");

  const deploymentsDirectory = path.join(__dirname, "..", "deployments");
  fs.mkdirSync(deploymentsDirectory, { recursive: true });
  fs.writeFileSync(
    path.join(deploymentsDirectory, `${network.name}-${chainId}.json`),
    `${JSON.stringify(deploymentSummary, null, 2)}\n`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
