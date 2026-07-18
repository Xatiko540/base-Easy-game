const fs = require("fs");
const path = require("path");
const hre = require("hardhat");

const deploymentSummary = {
  chainId: null,
  deployer: null,
  startBlock: null,
  contracts: {},
  transactions: {},
  roles: {},
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
    `${contractName}.sol`,
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
  const configuredAddress = (name, localFallback = deployer.address) => {
    const value = useLocalWallets ? localFallback : process.env[name];
    if (!value || !hre.ethers.isAddress(value) || value === hre.ethers.ZeroAddress) {
      throw new Error(`${name} must be configured with a non-zero address.`);
    }
    return hre.ethers.getAddress(value);
  };
  const projectWallet = configuredAddress("PROJECT_WALLET");
  const treasuryAddress = configuredAddress("TREASURY_ADDRESS");
  const operatorWallet = configuredAddress("OPERATOR_WALLET");
  const adminOwner = configuredAddress("ADMIN_OWNER_ADDRESS");
  const scheduleSigner = configuredAddress("SCHEDULE_SIGNER_ADDRESS");
  const skillTreasury = configuredAddress("SKILL_TREASURY_ADDRESS");
  deploymentSummary.roles = {
    projectWallet,
    treasuryAddress,
    operatorWallet,
    adminOwner,
    scheduleSigner,
    skillTreasury,
  };
  let usdcAddress = process.env.USDC_ADDRESS || "";
  let mockUsdc;

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
  console.log(`Admin owner: ${adminOwner}`);
  console.log(`Schedule signer: ${scheduleSigner}`);
  console.log(`Skill treasury: ${skillTreasury}`);
  console.log(`USDC token: ${usdcAddress}`);

  if (
    !hre.ethers.isAddress(usdcAddress) ||
    usdcAddress === hre.ethers.ZeroAddress
  ) {
    throw new Error(
      "USDC_ADDRESS must be configured with a non-zero token address before deploying EasyGameAdvance."
    );
  }

  const EasyGameRoundManager = await hre.ethers.getContractFactory(
    "EasyGameRoundManager"
  );
  const roundManager = await EasyGameRoundManager.deploy(scheduleSigner);
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

  const setCoreTx = await roundManager.setGameCore(easyGameAddress);
  await recordTransaction("RoundManager.setGameCore", setCoreTx);

  const EasyGameArenaSkills = await hre.ethers.getContractFactory(
    "EasyGameArenaSkills"
  );
  const arenaSkills = await EasyGameArenaSkills.deploy(
    easyGameAddress,
    roundManagerAddress,
    usdcAddress,
    skillTreasury
  );
  await arenaSkills.waitForDeployment();
  const arenaSkillsAddress = await recordDeployment(
    "EasyGameArenaSkills",
    arenaSkills
  );
  await recordTransaction(
    "RoundManager.setArenaSkills",
    await roundManager.setArenaSkills(arenaSkillsAddress)
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
  await recordTransaction(
    "EasyGameAdvance.finalizeSystemContracts",
    await easyGame.finalizeSystemContracts()
  );
  await recordTransaction(
    "RoundManager.finalizeSystemContracts",
    await roundManager.finalizeSystemContracts()
  );

  if (hre.ethers.getAddress(adminOwner) !== hre.ethers.getAddress(deployer.address)) {
    await recordTransaction(
      "EasyGameAdvance.transferOwnership",
      await easyGame.transferOwnership(adminOwner)
    );
    await recordTransaction(
      "RoundManager.transferOwnership",
      await roundManager.transferOwnership(adminOwner)
    );
  }

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
