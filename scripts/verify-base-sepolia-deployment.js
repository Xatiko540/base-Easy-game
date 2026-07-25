const fs = require("node:fs");
const path = require("node:path");
const hre = require("hardhat");

function same(left, right) {
  return hre.ethers.getAddress(left) === hre.ethers.getAddress(right);
}

function requireLink(label, actual, expected) {
  if (!same(actual, expected)) {
    throw new Error(`${label}: expected ${expected}, received ${actual}`);
  }
  console.log(`${label}: ${actual}`);
}

async function main() {
  const network = await hre.ethers.provider.getNetwork();
  if (Number(network.chainId) !== 84532) {
    throw new Error(`Expected Base Sepolia 84532, received ${network.chainId}`);
  }
  const deploymentPath = path.join(__dirname, "..", "deployments", "baseSepolia-84532.json");
  const deployment = JSON.parse(fs.readFileSync(deploymentPath, "utf8"));
  const addresses = deployment.contracts;
  const roles = deployment.roles;
  const usdc = hre.ethers.getAddress(process.env.USDC_ADDRESS);
  const required = [
    "EasyGameRoundManager",
    "EasyGameAdvance",
    "EasyGameArenaSkills",
    "EasyGameRoundSettlement",
  ];
  for (const name of required) {
    const code = await hre.ethers.provider.getCode(addresses[name]);
    if (code === "0x") throw new Error(`${name} has no bytecode at ${addresses[name]}`);
    console.log(`${name}: ${addresses[name]} (${(code.length - 2) / 2} runtime bytes)`);
  }
  if (await hre.ethers.provider.getCode(usdc) === "0x") {
    throw new Error(`USDC has no bytecode at ${usdc}`);
  }

  const manager = await hre.ethers.getContractAt(
    "EasyGameRoundManager",
    addresses.EasyGameRoundManager,
  );
  const core = await hre.ethers.getContractAt("EasyGameAdvance", addresses.EasyGameAdvance);
  const skills = await hre.ethers.getContractAt(
    "EasyGameArenaSkills",
    addresses.EasyGameArenaSkills,
  );
  const settlement = await hre.ethers.getContractAt(
    "EasyGameRoundSettlement",
    addresses.EasyGameRoundSettlement,
  );

  requireLink("Core.roundManager", await core.roundManager(), addresses.EasyGameRoundManager);
  requireLink(
    "Core.settlementContract",
    await core.settlementContract(),
    addresses.EasyGameRoundSettlement,
  );
  requireLink("Core.usdcToken", await core.usdcToken(), usdc);
  requireLink("Core.owner", await core.owner(), roles.adminOwner);
  requireLink("Core.projectWallet", await core.projectWallet(), roles.projectWallet);
  requireLink("Core.treasuryWallet", await core.treasuryWallet(), roles.treasuryAddress);
  requireLink("Core.operatorWallet", await core.operatorWallet(), roles.operatorWallet);
  if (!(await core.systemContractsFinalized())) throw new Error("Core is not finalized");

  requireLink("Manager.gameCore", await manager.gameCore(), addresses.EasyGameAdvance);
  requireLink("Manager.arenaSkills", await manager.arenaSkills(), addresses.EasyGameArenaSkills);
  requireLink(
    "Manager.settlementContract",
    await manager.settlementContract(),
    addresses.EasyGameRoundSettlement,
  );
  requireLink("Manager.owner", await manager.owner(), roles.adminOwner);
  requireLink("Manager.scheduleSigner", await manager.scheduleSigner(), roles.scheduleSigner);
  if (!(await manager.allowedScheduleSigners(roles.scheduleSigner))) {
    throw new Error("Schedule signer is not allowed");
  }
  if (!(await manager.systemContractsFinalized())) throw new Error("Manager is not finalized");

  requireLink("Skills.gameCore", await skills.gameCore(), addresses.EasyGameAdvance);
  requireLink("Skills.roundManager", await skills.roundManager(), addresses.EasyGameRoundManager);
  requireLink("Skills.usdcToken", await skills.usdcToken(), usdc);
  requireLink("Skills.skillTreasury", await skills.skillTreasury(), roles.skillTreasury);
  requireLink("Settlement.gameCore", await settlement.gameCore(), addresses.EasyGameAdvance);
  requireLink(
    "Settlement.roundManager",
    await settlement.roundManager(),
    addresses.EasyGameRoundManager,
  );
  requireLink(
    "Settlement.arenaSkills",
    await settlement.arenaSkills(),
    addresses.EasyGameArenaSkills,
  );
  requireLink("Settlement.usdcToken", await settlement.usdcToken(), usdc);

  console.log("Core.systemContractsFinalized: true");
  console.log("Manager.systemContractsFinalized: true");
  console.log(`USDC: ${usdc}`);
  console.log("Base Sepolia deployment verification passed");
}

main().catch((error) => {
  console.error(error.message || error);
  process.exitCode = 1;
});
