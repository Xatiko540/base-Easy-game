const { ethers, Wallet } = require("ethers");
const { roundTypes } = require("../functions/round_season_manifest");

const provider = new ethers.JsonRpcProvider("https://sepolia.base.org");
const managerAddress = "0xD552FB90f49bB5792676C5c26ce8414F4EB7C5aB";

const iface = new ethers.Interface([
  "function commitSeason((uint256,uint256,uint8,uint64,uint64,uint64,uint64,uint32,uint16,bytes32,uint256,uint256,uint16,uint16)[], bytes[])",
  "function verifyRoundConfig((uint256,uint256,uint8,uint64,uint64,uint64,uint64,uint32,uint16,bytes32,uint256,uint256,uint16,uint16), bytes) view returns (bool)",
  "function scheduleSigner() view returns (address)",
  "function allowedScheduleSigners(address) view returns (bool)",
  "function systemContractsFinalized() view returns (bool)",
  "function getSeasonState(uint256) view returns (bytes32,uint64,uint64,bool)",
]);

async function staticCall(fn, args) {
  const data = iface.encodeFunctionData(fn, args);
  try {
    return await provider.call({ to: managerAddress, data });
  } catch (err) {
    const errData = err.info?.error?.data || err.data || "";
    if (errData && errData !== "0x") {
      const reasonHex = "0x" + errData.slice(138);
      try { return { error: ethers.toUtf8String(reasonHex) }; } catch (_) {}
    }
    return { error: err.message?.slice(0, 200) || "unknown" };
  }
}

async function main() {
  const finalized = await staticCall("systemContractsFinalized", []);
  const decoded = iface.decodeFunctionResult("systemContractsFinalized", finalized);
  console.log("finalized:", decoded[0]);

  const signerRes = await staticCall("scheduleSigner", []);
  const signerDecoded = iface.decodeFunctionResult("scheduleSigner", signerRes);
  console.log("signer:", signerDecoded[0]);

  const signerKey = "db159ae74cad9a219a481ef9a10257ff8c088e31b56967f17486fc795d8eee4c";
  const scheduleSigner = new Wallet(signerKey);
  console.log("scheduleSigner address:", scheduleSigner.address);

  const allowed = await staticCall("allowedScheduleSigners", [scheduleSigner.address]);
  const allowedDecoded = iface.decodeFunctionResult("allowedScheduleSigners", allowed);
  console.log("allowed:", allowedDecoded[0]);

  const now = BigInt(Math.floor(Date.now() / 1000));
  const seasonId = now * 1000n;
  const baseStart = now + 3600n;

  const seasonState = await staticCall("getSeasonState", [seasonId]);
  const ssDecoded = iface.decodeFunctionResult("getSeasonState", seasonState);
  console.log("season committed:", ssDecoded[3]);

  const durationsHours = [24n, 48n, 72n, 96n, 144n];
  const configs = [];
  const signatures = [];

  for (let level = 1; level <= 17; level++) {
    const roundId = seasonId * 100n + BigInt(level);
    const startsAt = baseStart + BigInt(level - 1) * 5n * 3600n;
    const durationHours = durationsHours[(level - 1) % durationsHours.length];
    const endsAt = startsAt + durationHours * 3600n;
    const config = {
      seasonId, roundId, level,
      startsAt,
      entriesCloseAt: startsAt + (endsAt - startsAt) / 2n,
      endsAt, freezeClosesAt: endsAt,
      maxPlayers: 1_000_000, maxWinners: 2,
      winningCellsRoot: "0x" + "ab".repeat(32),
      ethPrice: 100_000_000_000_000n, usdcPrice: 100_000n,
      freezeLimit: Number(((durationHours + 23n) / 24n) * 10n),
      paymentSplitVersion: 1,
    };
    const domain = {
      name: "EasyGameAdvance",
      version: "2",
      chainId: 84532,
      verifyingContract: managerAddress,
    };
    const sig = await scheduleSigner.signTypedData(domain, roundTypes, config);

    const validRes = await staticCall("verifyRoundConfig", [config, sig]);
    const validDecoded = iface.decodeFunctionResult("verifyRoundConfig", validRes);
    console.log("L" + level + " valid:", validDecoded[0]);

    configs.push(config);
    signatures.push(sig);
  }

  console.log("\nCommitting season...");
  const commitRes = await staticCall("commitSeason", [configs, signatures]);
  console.log("commit result:", commitRes);
}

main().catch((e) => console.error(e.message));
