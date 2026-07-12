const hre = require("hardhat");

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
  const signers = await ethers.getSigners();
  const network = await ethers.provider.getNetwork();
  const chainId = Number(network.chainId);
  const artifact = require("../src/artifacts/EasyGameAdvance.json");
  const deployment = artifact.networks?.[String(chainId)];

  if (!deployment?.address) {
    throw new Error(
      `EasyGameAdvance is not deployed for chain ${chainId}. Run npm run deploy:ganache first.`
    );
  }

  const [owner, root, referral, ...matrixPlayers] = signers;
  const easyGame = await ethers.getContractAt(
    "EasyGameAdvance",
    deployment.address
  );
  const code = await ethers.provider.getCode(deployment.address);
  if (code === "0x") {
    throw new Error("EasyGameAdvance address has no contract code");
  }

  console.log(`Ganache chainId: ${chainId}`);
  console.log(`EasyGameAdvance: ${deployment.address}`);
  console.log(`Owner: ${await easyGame.owner()}`);

  if ((await easyGame.owner()).toLowerCase() !== owner.address.toLowerCase()) {
    throw new Error("Unexpected contract owner");
  }

  const ethPrice = await easyGame.levelPrices(3);
  await (
    await easyGame.connect(root).activateLevel(3, ethers.ZeroAddress, {
      value: ethPrice,
    })
  ).wait();
  const rootLevel = await easyGame.getPlayerLevel(root.address, 3);
  if (!rootLevel.active || rootLevel.positionId !== 1n) {
    throw new Error("ETH activation did not create matrix position 1");
  }
  console.log("PASS ETH activation and first matrix position");

  const usdcAddress = await easyGame.usdcToken();
  const usdc = await ethers.getContractAt("MockUSDC", usdcAddress);
  const usdcPrice = await easyGame.levelPricesUsdc(3);
  await (await usdc.mint(referral.address, usdcPrice)).wait();
  await (
    await usdc.connect(referral).approve(deployment.address, usdcPrice)
  ).wait();
  await (
    await easyGame.connect(referral).activateLevelWithUSDC(3, root.address)
  ).wait();

  const referralBonus = await easyGame.claimableReferralBonusUsdc(root.address);
  if (referralBonus !== (usdcPrice * 950n) / 10000n) {
    throw new Error("USDC direct referral bonus is incorrect");
  }
  await (await easyGame.connect(root).claimReferralBonusUSDC()).wait();
  if ((await usdc.balanceOf(root.address)) !== referralBonus) {
    throw new Error("USDC referral claim did not reach the player");
  }
  console.log("PASS USDC activation, referral accounting, and claim");

  const level5Price = await easyGame.levelPrices(5);
  const level5Players = [root, referral, ...matrixPlayers].slice(0, 7);
  for (let index = 0; index < level5Players.length; index += 1) {
    const player = level5Players[index];
    await (
      await easyGame
        .connect(player)
        .activateLevel(5, index === 0 ? ethers.ZeroAddress : root.address, {
          value: level5Price,
          gasLimit: 5_000_000,
        })
    ).wait();
  }

  const prizeNode = await easyGame.getMatrixNode(5, 7);
  if (!prizeNode.prizeCell) {
    throw new Error("Matrix cell 7 was not marked as a prize cell");
  }
  const prizeState = await easyGame.getPlayerLevelFull(prizeNode.player, 5);
  if (prizeState.claimablePrize === 0n && prizeState.pendingPrize === 0n) {
    throw new Error("Prize cell owner did not receive a prize");
  }
  console.log("PASS binary placement, recycle path, and prize cell 7");

  await expectRevert(
    () => easyGame.connect(root).withdrawProjectFees(),
    "only owner can withdraw project fees"
  );
  await expectRevert(
    () =>
      easyGame
        .connect(signers[signers.length - 1])
        .activateLevel(4, ethers.ZeroAddress, { value: 1n }),
    "incorrect ETH payment is rejected"
  );

  console.log("Ganache smoke test completed successfully.");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
