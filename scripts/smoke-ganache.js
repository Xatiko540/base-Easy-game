const hre = require("hardhat");
const { buildWinningCellTree } = require("../functions/round_merkle");

const roundTypes = {
  RoundConfig: [
    { name: "seasonId", type: "uint256" },
    { name: "roundId", type: "uint256" },
    { name: "level", type: "uint8" },
    { name: "startsAt", type: "uint64" },
    { name: "entriesCloseAt", type: "uint64" },
    { name: "endsAt", type: "uint64" },
    { name: "freezeClosesAt", type: "uint64" },
    { name: "maxPlayers", type: "uint32" },
    { name: "maxWinners", type: "uint16" },
    { name: "winningCellsRoot", type: "bytes32" },
    { name: "ethPrice", type: "uint256" },
    { name: "usdcPrice", type: "uint256" },
    { name: "freezeLimit", type: "uint16" },
    { name: "paymentSplitVersion", type: "uint16" },
  ],
};

function deployedAddress(name, chainId) {
  const artifact = require(`../src/artifacts/${name}.json`);
  const address = artifact.networks?.[String(chainId)]?.address;
  if (!address) {
    throw new Error(`${name} is not deployed for chain ${chainId}`);
  }
  return address;
}

async function expectRevert(action, label) {
  try {
    await action();
  } catch (_) {
    console.log(`PASS ${label}`);
    return;
  }
  throw new Error(`Expected revert: ${label}`);
}

async function main() {
  const { ethers } = hre;
  const [owner, root, referral, basePayPlayer] = await ethers.getSigners();
  const network = await ethers.provider.getNetwork();
  const chainId = Number(network.chainId);

  const easyGame = await ethers.getContractAt(
    "EasyGameAdvance",
    deployedAddress("EasyGameAdvance", chainId),
  );
  const roundManager = await ethers.getContractAt(
    "EasyGameRoundManager",
    deployedAddress("EasyGameRoundManager", chainId),
  );
  const arenaSkills = await ethers.getContractAt(
    "EasyGameArenaSkills",
    deployedAddress("EasyGameArenaSkills", chainId),
  );
  const settlement = await ethers.getContractAt(
    "EasyGameRoundSettlement",
    deployedAddress("EasyGameRoundSettlement", chainId),
  );
  const basePayGateway = await ethers.getContractAt(
    "EasyGameBasePayGateway",
    deployedAddress("EasyGameBasePayGateway", chainId),
  );
  const usdc = await ethers.getContractAt("MockUSDC", await easyGame.usdcToken());

  for (const contract of [easyGame, roundManager, arenaSkills, settlement, basePayGateway]) {
    if (await ethers.provider.getCode(await contract.getAddress()) === "0x") {
      throw new Error(`Missing bytecode at ${await contract.getAddress()}`);
    }
  }

  const latest = await ethers.provider.getBlock("latest");
  const roundId = BigInt(latest.number) * 1_000n + 1n;
  const winningCells = [1n, 2n, 3n];
  const winnerTree = buildWinningCellTree(roundId, winningCells);
  const config = {
    seasonId: 1n,
    roundId,
    level: 5,
    startsAt: BigInt(latest.timestamp - 5),
    entriesCloseAt: BigInt(latest.timestamp + 600),
    endsAt: BigInt(latest.timestamp + 1200),
    freezeClosesAt: BigInt(latest.timestamp + 1200),
    maxPlayers: 32,
    maxWinners: winningCells.length,
    winningCellsRoot: winnerTree.root,
    ethPrice: ethers.parseEther("0.2"),
    usdcPrice: 200_000n,
    freezeLimit: 10,
    paymentSplitVersion: 1,
  };
  const signature = await owner.signTypedData(
    {
      name: "EasyGameAdvance",
      version: "2",
      chainId: network.chainId,
      verifyingContract: await roundManager.getAddress(),
    },
    roundTypes,
    config,
  );

  console.log(`Chain ID: ${chainId}`);
  console.log(`Round ID: ${roundId}`);

  const ethActivation = await (
    await easyGame.connect(root).activateRound(
      config,
      signature,
      ethers.ZeroAddress,
      { value: config.ethPrice },
    )
  ).wait();
  console.log(`PASS ETH round activation (${ethActivation.gasUsed} gas)`);

  await (await usdc.connect(referral).approve(await easyGame.getAddress(), config.usdcPrice)).wait();
  const usdcActivation = await (
    await easyGame.connect(referral).activateRoundWithUSDC(
      config,
      signature,
      root.address,
    )
  ).wait();
  const directBonus = await easyGame.claimableReferralBonusUsdc(root.address);
  if (directBonus !== (config.usdcPrice * 950n) / 10_000n) {
    throw new Error("Direct USDC referral accounting is incorrect");
  }
  await (await easyGame.connect(root).claimReferralBonusUSDC()).wait();
  console.log(`PASS USDC activation and referral claim (${usdcActivation.gasUsed} gas)`);

  await (await usdc.connect(basePayPlayer).transfer(
    await basePayGateway.getAddress(),
    config.usdcPrice,
  )).wait();
  const paymentId = ethers.keccak256(
    ethers.toUtf8Bytes(`local-base-pay-${roundId}`),
  );
  await (
    await basePayGateway.connect(owner).fulfillRound(
      paymentId,
      config,
      signature,
      basePayPlayer.address,
      root.address,
    )
  ).wait();
  console.log("PASS Base Pay gateway fulfillment");

  const participants = [root, referral, basePayPlayer];
  for (let index = 0; index < participants.length; index += 1) {
    const state = await easyGame.getPlayerRound(participants[index].address, roundId);
    if (!state.active || state.cellId < 1n) {
      throw new Error(`Player ${index + 1} was not registered in the round matrix`);
    }
  }
  const stats = await easyGame.getRoundGameStats(roundId);
  if (stats.activeCells < 3n || stats.prizePoolEth === 0n || stats.prizePoolUsdc === 0n) {
    throw new Error("Round pools or matrix cells were not recorded");
  }
  console.log(`PASS round matrix state (${stats.activeCells} active cells)`);

  const freezePrice = await arenaSkills.FREEZE_TOKEN_PRICE_USDC();
  await (await usdc.connect(root).approve(await arenaSkills.getAddress(), freezePrice)).wait();
  await (await arenaSkills.connect(root).buyFreezeToken(roundId)).wait();
  await (await arenaSkills.connect(root).freezePlayer(roundId, referral.address)).wait();
  if (!(await arenaSkills.isFrozen(roundId, referral.address))) {
    throw new Error("Freeze skill did not update on-chain state");
  }
  const unfreezePrice = await arenaSkills.getUnfreezePriceUsdc(roundId, referral.address);
  await (await usdc.connect(referral).approve(await arenaSkills.getAddress(), unfreezePrice)).wait();
  await (await arenaSkills.connect(referral).buyUnfreeze(roundId)).wait();
  if (await arenaSkills.isFrozen(roundId, referral.address)) {
    throw new Error("Paid unfreeze did not clear on-chain state");
  }
  console.log("PASS freeze token, target freeze, and paid unfreeze");

  await expectRevert(
    () => easyGame.connect(referral).withdrawProjectFees(),
    "only owner can withdraw project fees",
  );
  await expectRevert(
    () => basePayGateway.connect(referral).fulfillRound(
      ethers.keccak256(ethers.toUtf8Bytes("unauthorized-payment")),
      config,
      signature,
      referral.address,
      ethers.ZeroAddress,
    ),
    "only the configured fulfiller can complete Base Pay",
  );

  await ethers.provider.send("evm_setNextBlockTimestamp", [Number(config.endsAt)]);
  await ethers.provider.send("evm_mine", []);
  await (
    await settlement.settleRound(roundId, winningCells, winnerTree.proofs)
  ).wait();
  if (!(await settlement.roundSettled(roundId))) {
    throw new Error("Round settlement flag was not recorded");
  }
  if ((await roundManager.getRoundPhase(roundId)) !== 5n) {
    throw new Error("Round manager did not move to Settled phase");
  }

  for (const participant of participants) {
    const ethClaim = await settlement.claimableEth(participant.address);
    const usdcClaim = await settlement.claimableUsdc(participant.address);
    if (ethClaim === 0n || usdcClaim === 0n) {
      throw new Error("A verified winner did not receive both pool allocations");
    }
    await (await settlement.connect(participant).claimPrize()).wait();
    if (
      (await settlement.claimableEth(participant.address)) !== 0n ||
      (await settlement.claimableUsdc(participant.address)) !== 0n
    ) {
      throw new Error("Settlement claim was not cleared");
    }
  }
  console.log("PASS Merkle settlement and ETH/USDC winner claims");
  console.log("Local round smoke test completed successfully.");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
