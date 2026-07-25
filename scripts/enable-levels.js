const { ethers } = require("ethers");
const coreArtifact = require("../src/artifacts/EasyGameAdvance.json");

const RPC = "https://sepolia.base.org";
const CHAIN_ID = 84532;
const ADMIN_KEY = "0xef16589ee5ef136266d874e3efb228149996fdc3dd674ae785d6eaf79152fcba";
const CORE = "0x1108A36643A92bE165123bA8F89D14F040A53215";

async function main() {
  const provider = new ethers.JsonRpcProvider(RPC, CHAIN_ID);
  const admin = new ethers.Wallet(ADMIN_KEY, provider);
  const core = new ethers.Contract(CORE, coreArtifact.abi, admin);

  console.log("Admin:", admin.address);
  console.log("Balance:", ethers.formatEther(await provider.getBalance(admin.address)), "ETH");
  console.log("Contract owner:", await core.owner());

  for (let level = 1; level <= 17; level++) {
    const available = await core.levelAvailable(level);
    if (available) {
      console.log(`L${level}: already enabled`);
      continue;
    }
    console.log(`Enabling L${level}...`);
    const tx = await core.setLevelAvailable(level, true);
    await tx.wait();
    console.log(`  OK ${tx.hash}`);
  }
  console.log("All levels enabled");
}

main().catch((e) => console.error(e.message || e));
