const { ethers } = require("hardhat");

async function main() {
  const network = await ethers.provider.getNetwork();
  console.log("Chain ID:", network.chainId);

  const managerAddr = "0xD552FB90f49bB5792676C5c26ce8414F4EB7C5aB";
  const manager = await ethers.getContractAt("EasyGameRoundManager", managerAddr);

  for (const seasonId of ["1784750932000", "2026071902"]) {
    try {
      const state = await manager.getSeasonState(seasonId);
      console.log(`Season ${seasonId}:`);
      console.log(`  configRoot: ${state.configRoot}`);
      console.log(`  committed: ${state.committed}`);
    } catch (e) {
      console.log(`Season ${seasonId} error: ${e.message}`);
    }

    try {
      const hash = await manager.getCommittedRoundHash(seasonId, 1);
      console.log(`  L1 committedHash: ${hash}`);
    } catch (e) {
      console.log(`  L1 hash error: ${e.message}`);
    }
  }
}

main().catch(console.error);
