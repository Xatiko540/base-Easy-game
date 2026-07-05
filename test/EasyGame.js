const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("EasyGameAdvance", function () {
  async function deployFixture() {
    const signers = await ethers.getSigners();
    const [
      owner,
      projectWallet,
      treasuryWallet,
      operatorWallet,
      root,
      first,
      second,
      third,
      fourth,
      fifth,
      sixth,
      seventh,
      outsider,
    ] = signers;

    const MockUSDC = await ethers.getContractFactory("MockUSDC");
    const usdc = await MockUSDC.deploy();
    await usdc.waitForDeployment();

    const EasyGameAdvance = await ethers.getContractFactory("EasyGameAdvance");
    const easyGame = await EasyGameAdvance.deploy(
      projectWallet.address,
      treasuryWallet.address,
      operatorWallet.address,
      await usdc.getAddress()
    );
    await easyGame.waitForDeployment();

    return {
      easyGame,
      usdc,
      owner,
      projectWallet,
      treasuryWallet,
      operatorWallet,
      root,
      first,
      second,
      third,
      fourth,
      fifth,
      sixth,
      seventh,
      outsider,
    };
  }

  it("starts as a 17-level weighted matrix arena", async function () {
    const { easyGame } = await deployFixture();

    expect(await easyGame.LEVEL_COUNT()).to.equal(17);
    expect(await easyGame.levelPrices(1)).to.equal(ethers.parseEther("0.05"));
    expect(await easyGame.levelPrices(16)).to.equal(ethers.parseEther("8"));
    expect(await easyGame.levelPrices(17)).to.equal(ethers.parseEther("12"));
    expect(await easyGame.levelPricesUsdc(1)).to.equal(50000);
    expect(await easyGame.levelPricesUsdc(17)).to.equal(12000000);
    expect(await easyGame.levelAvailable(1)).to.equal(false);
    expect(await easyGame.levelAvailable(2)).to.equal(false);
    expect(await easyGame.levelAvailable(3)).to.equal(true);
    expect(await easyGame.levelAvailable(17)).to.equal(true);

    expect(await easyGame.MATRIX_PRIZE_BPS()).to.equal(7550);
    expect(await easyGame.DIRECT_REF_BPS()).to.equal(950);
    expect(await easyGame.SECOND_REF_BPS()).to.equal(600);
    expect(await easyGame.THIRD_REF_BPS()).to.equal(400);
    expect(await easyGame.PROJECT_FEE_BPS()).to.equal(500);
  });

  it("activates a level, places the player, and gives base weight", async function () {
    const { easyGame, root } = await deployFixture();
    const price = await easyGame.levelPrices(17);

    await expect(
      easyGame.connect(root).activateLevel(17, ethers.ZeroAddress, {
        value: price,
      })
    )
      .to.emit(easyGame, "LevelActivated")
      .withArgs(root.address, 17, price, 1)
      .and.to.emit(easyGame, "MatrixPlaced")
      .withArgs(root.address, 17, 1, 0);

    const level = await easyGame.getPlayerLevel(root.address, 17);
    expect(level.active).to.equal(true);
    expect(level.positionId).to.equal(1);
    expect(await easyGame.getPlayerWeight(root.address, 17)).to.equal(100);
    expect(await easyGame.totalWeightByLevel(17)).to.equal(100);
  });

  it("splits payments into pool, three referral lines, and project fees", async function () {
    const { easyGame, root, first, second, third, projectWallet } =
      await deployFixture();
    const price = await easyGame.levelPrices(3);

    await easyGame.connect(root).activateLevel(3, ethers.ZeroAddress, {
      value: price,
    });
    await easyGame.connect(first).activateLevel(3, root.address, {
      value: price,
    });
    await easyGame.connect(second).activateLevel(3, first.address, {
      value: price,
    });

    const beforeFourth = await ethers.provider.getBalance(projectWallet.address);
    await expect(
      easyGame.connect(third).activateLevel(3, second.address, {
        value: price,
      })
    )
      .to.emit(easyGame, "PaymentSplit")
      .withArgs(
        third.address,
        3,
        (price * 7550n) / 10000n,
        (price * 950n) / 10000n,
        (price * 600n) / 10000n,
        (price * 400n) / 10000n,
        (price * 500n) / 10000n
      );

    const secondPlayer = await easyGame.getPlayer(second.address);
    const firstPlayer = await easyGame.getPlayer(first.address);
    const rootPlayer = await easyGame.getPlayer(root.address);

    expect(secondPlayer.claimableReferralBonus).to.equal((price * 950n) / 10000n);
    expect(firstPlayer.claimableReferralBonus).to.equal(
      (price * 950n) / 10000n + (price * 600n) / 10000n
    );
    expect(rootPlayer.claimableReferralBonus).to.equal(
      (price * 950n) / 10000n + (price * 600n) / 10000n + (price * 400n) / 10000n
    );
    expect(await easyGame.projectFeesAccrued()).to.equal(
      (price * 500n * 4n) / 10000n
    );

    await expect(easyGame.withdrawProjectFees()).to.changeEtherBalance(
      projectWallet,
      await easyGame.projectFeesAccrued()
    );
    expect(await easyGame.projectFeesAccrued()).to.equal(0);
    expect(await ethers.provider.getBalance(projectWallet.address)).to.be.gt(
      beforeFourth
    );
  });

  it("keeps missing referral lines inside the matrix prize pool", async function () {
    const { easyGame, root } = await deployFixture();
    const price = await easyGame.levelPrices(4);

    await easyGame.connect(root).activateLevel(4, ethers.ZeroAddress, {
      value: price,
    });

    const expectedPool = (price * (7550n + 950n + 600n + 400n)) / 10000n;
    expect(await easyGame.matrixPrizePools(4)).to.equal(expectedPool);
  });

  it("activates with USDC without breaking native ETH payment mode", async function () {
    const { easyGame, usdc, root, first, second } = await deployFixture();
    const easyGameAddress = await easyGame.getAddress();
    const price = await easyGame.levelPricesUsdc(7);

    for (const signer of [root, first, second]) {
      await usdc.mint(signer.address, price);
      await usdc.connect(signer).approve(easyGameAddress, price);
    }

    await expect(easyGame.connect(root).activateLevelWithUSDC(7, ethers.ZeroAddress))
      .to.emit(easyGame, "TokenPaymentSplit")
      .withArgs(
        root.address,
        7,
        await usdc.getAddress(),
        (price * 7550n) / 10000n,
        (price * 950n) / 10000n,
        (price * 600n) / 10000n,
        (price * 400n) / 10000n,
        (price * 500n) / 10000n
      );

    await easyGame.connect(first).activateLevelWithUSDC(7, root.address);
    await easyGame.connect(second).activateLevelWithUSDC(7, first.address);

    expect(await easyGame.matrixPrizePoolsUsdc(7)).to.be.gt(0);
    expect(await easyGame.projectFeesAccruedUsdc()).to.equal(
      (price * 500n * 3n) / 10000n
    );
    expect(await easyGame.claimableReferralBonusUsdc(root.address)).to.equal(
      (price * 950n) / 10000n + (price * 600n) / 10000n
    );

    const before = await usdc.balanceOf(root.address);
    await easyGame.connect(root).claimReferralBonusUSDC();
    expect(await usdc.balanceOf(root.address)).to.be.gt(before);

    const ethPrice = await easyGame.levelPrices(8);
    await easyGame.connect(root).activateLevel(8, ethers.ZeroAddress, {
      value: ethPrice,
    });
    expect(await easyGame.matrixPrizePools(8)).to.be.gt(0);
  });

  it("fills binary cells left-to-right, recycles parent, and grants box weight", async function () {
    const { easyGame, root, first, second } = await deployFixture();
    const price = await easyGame.levelPrices(3);

    await easyGame.connect(root).activateLevel(3, ethers.ZeroAddress, {
      value: price,
    });
    await easyGame.connect(first).activateLevel(3, root.address, {
      value: price,
    });

    await expect(
      easyGame.connect(second).activateLevel(3, root.address, {
        value: price,
      })
    )
      .to.emit(easyGame, "Recycled")
      .withArgs(root.address, 3, 1, 4)
      .and.to.emit(easyGame, "BoxTokenGranted")
      .withArgs(root.address, 3, 1);

    const rootPosition = await easyGame.getPlayerPosition(root.address, 3);
    expect(rootPosition.positionId).to.equal(4);

    const buyerPosition = await easyGame.getPlayerPosition(second.address, 3);
    expect(buyerPosition.positionId).to.equal(3);

    const rootPlayer = await easyGame.getPlayer(root.address);
    expect(rootPlayer.recycleCount).to.equal(1);
    expect(rootPlayer.boxTokens).to.equal(1);
    expect(await easyGame.getPlayerWeight(root.address, 3)).to.equal(360);
  });

  it("credits prize-position rewards from the matrix prize pool", async function () {
    const { easyGame, root, first, second, third, fourth, fifth, sixth } =
      await deployFixture();
    const players = [root, first, second, third, fourth, fifth, sixth];
    const price = await easyGame.levelPrices(5);

    for (let i = 0; i < players.length; i++) {
      await easyGame
        .connect(players[i])
        .activateLevel(5, i === 0 ? ethers.ZeroAddress : root.address, {
          value: price,
          gasLimit: 5000000,
        });
    }

    const node = await easyGame.getMatrixNode(5, 7);
    expect(node.prizeCell).to.equal(true);

    const prizeLevel = await easyGame.getPlayerLevelFull(node.player, 5);
    expect(prizeLevel.claimablePrize).to.be.gt(0);
  });

  it("runs a weighted draw from the prize pool and records claimable prize", async function () {
    const { easyGame, root, first, second } = await deployFixture();
    const price = await easyGame.levelPrices(6);

    await easyGame.connect(root).activateLevel(6, ethers.ZeroAddress, {
      value: price,
    });
    await easyGame.connect(first).activateLevel(6, root.address, {
      value: price,
    });
    await easyGame.connect(second).activateLevel(6, first.address, {
      value: price,
    });

    const poolBefore = await easyGame.matrixPrizePools(6);
    await expect(easyGame.requestDraw(6)).to.emit(easyGame, "DrawWon");
    const poolAfter = await easyGame.matrixPrizePools(6);
    expect(poolBefore - poolAfter).to.equal((poolBefore * 1000n) / 10000n);
  });

  it("freezes after two recycle cycles and unfreezes pending prizes on next level activation", async function () {
    const {
      easyGame,
      owner,
      root,
      first,
      second,
      third,
      fourth,
      fifth,
      sixth,
      seventh,
    } = await deployFixture();
    const level1Price = await easyGame.levelPrices(1);
    await easyGame.connect(owner).setLevelAvailable(1, true);
    await easyGame.connect(owner).setLevelAvailable(2, true);

    const players = [root, first, second, third, fourth, fifth, sixth, seventh];
    for (let i = 0; i < players.length; i++) {
      await easyGame
        .connect(players[i])
        .activateLevel(1, i === 0 ? ethers.ZeroAddress : root.address, {
          value: level1Price,
          gasLimit: 6000000,
        });
    }

    expect(await easyGame.isLevelFrozen(root.address, 1)).to.equal(true);

    const level1Before = await easyGame.getPlayerLevelFull(root.address, 1);
    const poolBefore = await easyGame.matrixPrizePools(1);
    await easyGame.requestDraw(1);
    const poolAfter = await easyGame.matrixPrizePools(1);
    const level1After = await easyGame.getPlayerLevelFull(root.address, 1);

    if (level1After.pendingPrize > level1Before.pendingPrize) {
      expect(poolBefore - poolAfter).to.equal((poolBefore * 1000n) / 10000n);
    }

    const level2Price = await easyGame.levelPrices(2);
    await easyGame.connect(root).activateLevel(2, ethers.ZeroAddress, {
      value: level2Price,
      gasLimit: 5000000,
    });

    expect(await easyGame.isLevelFrozen(root.address, 1)).to.equal(false);
  });
});
