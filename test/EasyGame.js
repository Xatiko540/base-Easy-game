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

    const RoundManager = await ethers.getContractFactory("EasyGameRoundManager");
    const roundManager = await RoundManager.deploy(operatorWallet.address);
    await roundManager.waitForDeployment();

    const EasyGameAdvance = await ethers.getContractFactory("EasyGameAdvance");
    const easyGame = await EasyGameAdvance.deploy(
      projectWallet.address,
      treasuryWallet.address,
      operatorWallet.address,
      await usdc.getAddress(),
      await roundManager.getAddress()
    );
    await easyGame.waitForDeployment();
    await roundManager.setGameCore(await easyGame.getAddress());
    await easyGame.setLegacyActivationEnabled(true);
    const BasePayGateway = await ethers.getContractFactory(
      "EasyGameBasePayGateway"
    );
    const basePayGateway = await BasePayGateway.deploy(
      await easyGame.getAddress(),
      await usdc.getAddress(),
      operatorWallet.address
    );
    await basePayGateway.waitForDeployment();
    await easyGame.setBasePayGateway(await basePayGateway.getAddress());
    const ArenaSkills = await ethers.getContractFactory("EasyGameArenaSkills");
    const arenaSkills = await ArenaSkills.deploy(
      await easyGame.getAddress(),
      await roundManager.getAddress(),
      await usdc.getAddress(),
      projectWallet.address
    );
    await arenaSkills.waitForDeployment();
    const Settlement = await ethers.getContractFactory("EasyGameRoundSettlement");
    const settlement = await Settlement.deploy(
      await easyGame.getAddress(),
      await roundManager.getAddress(),
      await arenaSkills.getAddress(),
      await usdc.getAddress()
    );
    await settlement.waitForDeployment();
    await easyGame.setSettlementContract(await settlement.getAddress());
    await roundManager.setSettlementContract(await settlement.getAddress());

    return {
      easyGame,
      roundManager,
      arenaSkills,
      settlement,
      basePayGateway,
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

  if (false) describe("removed legacy activation compatibility", function () {
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

    const beforeFourth = await ethers.provider.getBalance(
      projectWallet.address
    );
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

    expect(secondPlayer.claimableReferralBonus).to.equal(
      (price * 950n) / 10000n
    );
    expect(firstPlayer.claimableReferralBonus).to.equal(
      (price * 950n) / 10000n + (price * 600n) / 10000n
    );
    expect(rootPlayer.claimableReferralBonus).to.equal(
      (price * 950n) / 10000n +
        (price * 600n) / 10000n +
        (price * 400n) / 10000n
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

  it("activates with USDC, credits all referral lines, and withdraws token fees", async function () {
    const { easyGame, usdc, root, first, second, third, projectWallet } =
      await deployFixture();
    const easyGameAddress = await easyGame.getAddress();
    const price = await easyGame.levelPricesUsdc(7);

    for (const signer of [root, first, second, third]) {
      await usdc.mint(signer.address, price);
      await usdc.connect(signer).approve(easyGameAddress, price);
    }

    await expect(
      easyGame.connect(root).activateLevelWithUSDC(7, ethers.ZeroAddress)
    )
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
    await easyGame.connect(third).activateLevelWithUSDC(7, second.address);

    expect(await easyGame.matrixPrizePoolsUsdc(7)).to.be.gt(0);
    expect(await easyGame.projectFeesAccruedUsdc()).to.equal(
      (price * 500n * 4n) / 10000n
    );
    expect(await easyGame.claimableReferralBonusUsdc(root.address)).to.equal(
      (price * 950n) / 10000n +
        (price * 600n) / 10000n +
        (price * 400n) / 10000n
    );

    const before = await usdc.balanceOf(root.address);
    await easyGame.connect(root).claimReferralBonusUSDC();
    expect(await usdc.balanceOf(root.address)).to.be.gt(before);

    const fees = await easyGame.projectFeesAccruedUsdc();
    const projectBefore = await usdc.balanceOf(projectWallet.address);
    await easyGame.withdrawProjectFeesUSDC();
    expect(await usdc.balanceOf(projectWallet.address)).to.equal(
      projectBefore + fees
    );
    expect(await easyGame.projectFeesAccruedUsdc()).to.equal(0);

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

    const winner = players.find(
      (player) => player.address.toLowerCase() === node.player.toLowerCase()
    );
    const prize = prizeLevel.claimablePrize;
    await expect(easyGame.connect(winner).claimPrize(5)).to.changeEtherBalance(
      winner,
      prize
    );
    expect(
      (await easyGame.getPlayerLevelFull(node.player, 5)).claimablePrize
    ).to.equal(0);
  });

  it("disables unverifiable weighted draws without changing the prize pool", async function () {
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
    await expect(easyGame.requestDraw(6)).to.be.revertedWithCustomError(
      easyGame,
      "WeightedDrawDisabled"
    );
    expect(await easyGame.matrixPrizePools(6)).to.equal(poolBefore);
  });

  it("freezes after two recycle cycles and unfreezes on next level activation", async function () {
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

    const level2Price = await easyGame.levelPrices(2);
    await easyGame.connect(root).activateLevel(2, ethers.ZeroAddress, {
      value: level2Price,
      gasLimit: 5000000,
    });

    expect(await easyGame.isLevelFrozen(root.address, 1)).to.equal(false);
  });

  it("bounds recycle processing and rejects oversized batches", async function () {
    const {
      easyGame,
      root,
      first,
      second,
      third,
      fourth,
      fifth,
      sixth,
      seventh,
      outsider,
    } = await deployFixture();
    const players = [
      root,
      first,
      second,
      third,
      fourth,
      fifth,
      sixth,
      seventh,
      outsider,
    ];
    const price = await easyGame.levelPrices(3);
    const recycledTopic = easyGame.interface.getEvent("Recycled").topicHash;

    for (let index = 0; index < players.length; index++) {
      const tx = await easyGame
        .connect(players[index])
        .activateLevel(3, index === 0 ? ethers.ZeroAddress : root.address, {
          value: price,
          gasLimit: 5000000,
        });
      const receipt = await tx.wait();
      const recycleEvents = receipt.logs.filter(
        (log) => log.topics[0] === recycledTopic
      );

      expect(recycleEvents.length).to.be.lte(
        Number(await easyGame.MAX_RECYCLE_STEPS_PER_TX())
      );
      expect(receipt.gasUsed).to.be.lt(2500000);
    }

    await expect(
      easyGame.processPendingRecycles(3, 5)
    ).to.be.revertedWithCustomError(easyGame, "InvalidRecycleBatch");
  });

  it("keeps ETH and USDC balances equal to pools, fees, and player liabilities", async function () {
    const { easyGame, usdc, root, first, second, third } =
      await deployFixture();
    const players = [root, first, second, third];
    const easyGameAddress = await easyGame.getAddress();
    const ethPrice = await easyGame.levelPrices(3);
    const usdcPrice = await easyGame.levelPricesUsdc(4);

    for (let index = 0; index < players.length; index++) {
      const inviter =
        index === 0 ? ethers.ZeroAddress : players[index - 1].address;
      await easyGame.connect(players[index]).activateLevel(3, inviter, {
        value: ethPrice,
        gasLimit: 5000000,
      });

      await usdc.mint(players[index].address, usdcPrice);
      await usdc.connect(players[index]).approve(easyGameAddress, usdcPrice);
      await easyGame
        .connect(players[index])
        .activateLevelWithUSDC(4, inviter, { gasLimit: 5000000 });
    }

    let ethPools = 0n;
    let usdcPools = 0n;
    for (let level = 1; level <= 17; level++) {
      ethPools += await easyGame.matrixPrizePools(level);
      usdcPools += await easyGame.matrixPrizePoolsUsdc(level);
    }

    let ethPlayerLiabilities = 0n;
    let usdcPlayerLiabilities = 0n;
    for (const player of players) {
      const state = await easyGame.getPlayer(player.address);
      ethPlayerLiabilities +=
        state.claimableReferralBonus +
        state.claimablePrize +
        state.pendingPrize;
      usdcPlayerLiabilities +=
        (await easyGame.claimableReferralBonusUsdc(player.address)) +
        (await easyGame.claimablePrizeUsdc(player.address)) +
        (await easyGame.pendingPrizeUsdc(player.address));
    }

    const expectedEth =
      ethPools + (await easyGame.projectFeesAccrued()) + ethPlayerLiabilities;
    const expectedUsdc =
      usdcPools +
      (await easyGame.projectFeesAccruedUsdc()) +
      usdcPlayerLiabilities;

    expect(await ethers.provider.getBalance(easyGameAddress)).to.equal(
      expectedEth
    );
    expect(await usdc.balanceOf(easyGameAddress)).to.equal(expectedUsdc);
  });

  });

  describe("signed round schedules", function () {
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

    function winnerLeaf(roundId, cellId) {
      return ethers.keccak256(
        ethers.AbiCoder.defaultAbiCoder().encode(
          ["uint256", "uint256"],
          [roundId, cellId]
        )
      );
    }

    function winnerTree(roundId, cells) {
      const leaves = cells.map((cellId) => winnerLeaf(roundId, cellId));
      const levels = [leaves];
      while (levels.at(-1).length > 1) {
        const current = levels.at(-1);
        const next = [];
        for (let index = 0; index < current.length; index += 2) {
          if (index + 1 === current.length) {
            next.push(current[index]);
          } else {
            const pair = [current[index], current[index + 1]].sort();
            next.push(ethers.keccak256(ethers.concat(pair)));
          }
        }
        levels.push(next);
      }
      const proofs = leaves.map((_, leafIndex) => {
        const proof = [];
        let index = leafIndex;
        for (let level = 0; level < levels.length - 1; level++) {
          const sibling = index ^ 1;
          if (sibling < levels[level].length) proof.push(levels[level][sibling]);
          index = Math.floor(index / 2);
        }
        return proof;
      });
      return { root: levels.at(-1)[0], proofs };
    }

    async function signedRound(fixture, overrides = {}) {
      const block = await ethers.provider.getBlock("latest");
      const network = await ethers.provider.getNetwork();
      const contractAddress = await fixture.roundManager.getAddress();
      const config = {
        seasonId: 1n,
        roundId: 1001n,
        level: 5,
        startsAt: BigInt(block.timestamp + 100),
        entriesCloseAt: BigInt(block.timestamp + 3700),
        endsAt: BigInt(block.timestamp + 7300),
        freezeClosesAt: BigInt(block.timestamp + 3000),
        maxPlayers: 1024,
        maxWinners: 4,
        winningCellsRoot: ethers.keccak256(ethers.toUtf8Bytes("winning-cells")),
        ethPrice: ethers.parseEther("0.2"),
        usdcPrice: 200000n,
        freezeLimit: 10,
        paymentSplitVersion: 1,
        ...overrides,
      };
      const domain = {
        name: "EasyGameAdvance",
        version: "2",
        chainId: network.chainId,
        verifyingContract: contractAddress,
      };
      const signature = await fixture.operatorWallet.signTypedData(
        domain,
        roundTypes,
        config
      );
      return { config, signature, domain };
    }

    async function signedOpenRound(fixture, overrides = {}) {
      const block = await ethers.provider.getBlock("latest");
      return signedRound(fixture, {
        startsAt: BigInt(block.timestamp - 10),
        entriesCloseAt: BigInt(block.timestamp + 1800),
        endsAt: BigInt(block.timestamp + 3600),
        freezeClosesAt: BigInt(block.timestamp + 1200),
        ...overrides,
      });
    }

    it("lazily initializes a signed round and keeps its config immutable", async function () {
      const fixture = await deployFixture();
      const { roundManager, outsider } = fixture;
      const { config, signature } = await signedRound(fixture);
      const configHash = await roundManager.hashRoundConfig(config);

      expect(await roundManager.verifyRoundConfig(config, signature)).to.equal(true);
      await expect(roundManager.connect(outsider).initializeRound(config, signature))
        .to.emit(roundManager, "RoundInitialized")
        .withArgs(
          config.seasonId,
          config.roundId,
          config.level,
          configHash,
          config.startsAt,
          config.entriesCloseAt,
          config.endsAt
        );

      expect(await roundManager.getRoundPhase(config.roundId)).to.equal(1);
      const state = await roundManager.getRoundState(config.roundId);
      expect(state.initialized).to.equal(true);
      expect(state.configHash).to.equal(configHash);

      const changed = { ...config, maxPlayers: 2048 };
      const network = await ethers.provider.getNetwork();
      const changedSignature = await fixture.operatorWallet.signTypedData(
        {
          name: "EasyGameAdvance",
          version: "2",
          chainId: network.chainId,
          verifyingContract: await roundManager.getAddress(),
        },
        roundTypes,
        changed
      );
      await expect(
        roundManager.initializeRound(changed, changedSignature)
      ).to.be.revertedWithCustomError(roundManager, "RoundConfigMismatch");
    });

    it("derives phases from block timestamp at exact boundaries", async function () {
      const fixture = await deployFixture();
      const { roundManager } = fixture;
      const { config, signature } = await signedRound(fixture);
      await roundManager.initializeRound(config, signature);

      await ethers.provider.send("evm_setNextBlockTimestamp", [
        Number(config.startsAt),
      ]);
      await ethers.provider.send("evm_mine", []);
      expect(await roundManager.getRoundPhase(config.roundId)).to.equal(2);

      await ethers.provider.send("evm_setNextBlockTimestamp", [
        Number(config.entriesCloseAt),
      ]);
      await ethers.provider.send("evm_mine", []);
      expect(await roundManager.getRoundPhase(config.roundId)).to.equal(3);

      await ethers.provider.send("evm_setNextBlockTimestamp", [
        Number(config.endsAt),
      ]);
      await ethers.provider.send("evm_mine", []);
      expect(await roundManager.getRoundPhase(config.roundId)).to.equal(4);
    });

    it("rejects an unauthorized signer and cross-contract replay", async function () {
      const fixture = await deployFixture();
      const { roundManager, outsider, operatorWallet } = fixture;
      const { config, domain } = await signedRound(fixture);
      const forged = await outsider.signTypedData(domain, roundTypes, config);
      await expect(
        roundManager.initializeRound(config, forged)
      ).to.be.revertedWithCustomError(roundManager, "InvalidScheduleSignature");

      const Factory = await ethers.getContractFactory("EasyGameRoundManager");
      const secondManager = await Factory.deploy(operatorWallet.address);
      await secondManager.waitForDeployment();
      const validForFirst = await operatorWallet.signTypedData(
        domain,
        roundTypes,
        config
      );
      await expect(
        secondManager.initializeRound(config, validForFirst)
      ).to.be.revertedWithCustomError(
        secondManager,
        "InvalidScheduleSignature"
      );
    });

    it("rejects a round without a freeze immunity limit", async function () {
      const fixture = await deployFixture();
      const { roundManager } = fixture;
      const { config, signature } = await signedRound(fixture, {
        roundId: 1008n,
        freezeLimit: 0,
      });
      await expect(roundManager.initializeRound(config, signature))
        .to.be.revertedWithCustomError(roundManager, "InvalidRoundCapacity");
    });

    it("supports owner pause, resume, cancellation, and signer rotation", async function () {
      const fixture = await deployFixture();
      const { roundManager, owner, outsider, operatorWallet } = fixture;
      const { config, signature } = await signedRound(fixture);
      await roundManager.initializeRound(config, signature);

      await expect(roundManager.connect(outsider).setRoundPaused(config.roundId, true))
        .to.be.revertedWith("Only owner");
      await roundManager.connect(owner).setRoundPaused(config.roundId, true);
      expect(await roundManager.getRoundPhase(config.roundId)).to.equal(7);
      await roundManager.connect(owner).setRoundPaused(config.roundId, false);
      expect(await roundManager.getRoundPhase(config.roundId)).to.equal(1);

      await roundManager.connect(owner).cancelRound(config.roundId);
      expect(await roundManager.getRoundPhase(config.roundId)).to.equal(6);

      await roundManager.connect(owner).setScheduleSigner(outsider.address);
      expect(await roundManager.scheduleSigner()).to.equal(outsider.address);

      const oldSignerManifest = await signedRound(fixture, { roundId: 1002n });
      await expect(
        roundManager.initializeRound(
          oldSignerManifest.config,
          oldSignerManifest.signature
        )
      ).to.emit(roundManager, "RoundInitialized");

      await roundManager
        .connect(owner)
        .setScheduleSignerAllowed(operatorWallet.address, false);
      const revokedManifest = await signedRound(fixture, { roundId: 1003n });
      await expect(
        roundManager.initializeRound(
          revokedManifest.config,
          revokedManifest.signature
        )
      ).to.be.revertedWithCustomError(roundManager, "InvalidScheduleSignature");
    });

    it("rejects payment before round start", async function () {
      const fixture = await deployFixture();
      const { easyGame, roundManager, root } = fixture;

      const { config, signature } = await signedRound(fixture);
      await expect(
        easyGame.connect(root).activateRound(config, signature, ethers.ZeroAddress, {
          value: config.ethPrice,
        })
      ).to.be.revertedWithCustomError(roundManager, "InvalidRoundTimeRange");
      expect((await fixture.roundManager.getRoundState(config.roundId)).initialized)
        .to.equal(false);
    });

    it("activates an open ETH round and keeps accounting round-scoped", async function () {
      const fixture = await deployFixture();
      const { easyGame, roundManager, root } = fixture;
      const { config, signature } = await signedOpenRound(fixture);

      await expect(
        easyGame.connect(root).activateRound(config, signature, ethers.ZeroAddress, {
          value: config.ethPrice,
        })
      )
        .to.emit(easyGame, "RoundActivated")
        .withArgs(root.address, config.roundId, config.level, config.ethPrice, 1, false);

      const state = await roundManager.getRoundState(config.roundId);
      const playerRound = await easyGame.getPlayerRound(root.address, config.roundId);
      const stats = await easyGame.getRoundGameStats(config.roundId);
      expect(state.occupiedCells).to.equal(1);
      expect(playerRound.active).to.equal(true);
      expect(playerRound.cellId).to.equal(1);
      expect(playerRound.totalWeight).to.equal(100);
      expect(stats.prizePoolEth).to.equal((config.ethPrice * 9500n) / 10000n);
      expect(stats.activeCells).to.equal(1);
      expect(await easyGame.matrixPrizePools(config.level)).to.equal(0);
    });

    it("isolates matrix cells and pools between consecutive rounds of one level", async function () {
      const fixture = await deployFixture();
      const { easyGame, root } = fixture;
      const first = await signedOpenRound(fixture, { roundId: 2001n });
      await easyGame.connect(root).activateRound(
        first.config,
        first.signature,
        ethers.ZeroAddress,
        { value: first.config.ethPrice }
      );

      await ethers.provider.send("evm_setNextBlockTimestamp", [
        Number(first.config.endsAt + 1n),
      ]);
      await ethers.provider.send("evm_mine", []);
      const second = await signedOpenRound(fixture, {
        roundId: 2002n,
        startsAt: first.config.endsAt + 1n,
      });
      await easyGame.connect(root).activateRound(
        second.config,
        second.signature,
        ethers.ZeroAddress,
        { value: second.config.ethPrice }
      );

      expect((await easyGame.getPlayerRound(root.address, first.config.roundId)).cellId)
        .to.equal(1);
      expect((await easyGame.getPlayerRound(root.address, second.config.roundId)).cellId)
        .to.equal(1);
      expect((await easyGame.getRoundGameStats(first.config.roundId)).activeCells)
        .to.equal(1);
      expect((await easyGame.getRoundGameStats(second.config.roundId)).activeCells)
        .to.equal(1);
    });

    it("activates an open USDC round and credits only its token pool", async function () {
      const fixture = await deployFixture();
      const { easyGame, usdc, root } = fixture;
      const { config, signature } = await signedOpenRound(fixture, {
        roundId: 3001n,
      });
      await usdc.mint(root.address, config.usdcPrice);
      await usdc.connect(root).approve(await easyGame.getAddress(), config.usdcPrice);

      await easyGame
        .connect(root)
        .activateRoundWithUSDC(config, signature, ethers.ZeroAddress);
      const stats = await easyGame.getRoundGameStats(config.roundId);
      expect(stats.prizePoolEth).to.equal(0);
      expect(stats.prizePoolUsdc).to.equal(
        (config.usdcPrice * 9500n) / 10000n
      );
    });

    it("fulfills a verified Base Pay transfer without charging the player twice", async function () {
      const fixture = await deployFixture();
      const { easyGame, basePayGateway, usdc, operatorWallet, root } = fixture;
      const { config, signature } = await signedOpenRound(fixture, {
        roundId: 3002n,
      });
      const paymentId = ethers.keccak256(ethers.toUtf8Bytes("base-pay-3002"));
      await usdc.mint(await basePayGateway.getAddress(), config.usdcPrice);

      await expect(
        basePayGateway.connect(operatorWallet).fulfillRound(
          paymentId,
          config,
          signature,
          root.address,
          ethers.ZeroAddress
        )
      )
        .to.emit(basePayGateway, "BasePayRoundFulfilled")
        .withArgs(paymentId, root.address, config.roundId, config.usdcPrice);

      const playerRound = await easyGame.getPlayerRound(
        root.address,
        config.roundId
      );
      const stats = await easyGame.getRoundGameStats(config.roundId);
      expect(playerRound.active).to.equal(true);
      expect(playerRound.cellId).to.equal(1);
      expect(stats.prizePoolUsdc).to.equal(
        (config.usdcPrice * 9500n) / 10000n
      );
      expect(await usdc.balanceOf(root.address)).to.equal(0);
      expect(await usdc.balanceOf(await basePayGateway.getAddress())).to.equal(0);
    });

    it("rejects unauthorized or replayed Base Pay fulfillment", async function () {
      const fixture = await deployFixture();
      const {
        basePayGateway,
        usdc,
        operatorWallet,
        root,
        outsider,
      } = fixture;
      const { config, signature } = await signedOpenRound(fixture, {
        roundId: 3003n,
      });
      const paymentId = ethers.keccak256(ethers.toUtf8Bytes("base-pay-3003"));
      await usdc.mint(
        await basePayGateway.getAddress(),
        config.usdcPrice * 2n
      );

      await expect(
        basePayGateway.connect(outsider).fulfillRound(
          paymentId,
          config,
          signature,
          root.address,
          ethers.ZeroAddress
        )
      ).to.be.revertedWith("Only fulfiller");

      await basePayGateway.connect(operatorWallet).fulfillRound(
        paymentId,
        config,
        signature,
        root.address,
        ethers.ZeroAddress
      );
      await expect(
        basePayGateway.connect(operatorWallet).fulfillRound(
          paymentId,
          config,
          signature,
          outsider.address,
          ethers.ZeroAddress
        )
      ).to.be.revertedWith("Payment already processed");
    });

    it("prevents cancellation after a player has entered", async function () {
      const fixture = await deployFixture();
      const { easyGame, roundManager, root } = fixture;
      const { config, signature } = await signedOpenRound(fixture, {
        roundId: 4001n,
      });
      await easyGame.connect(root).activateRound(
        config,
        signature,
        ethers.ZeroAddress,
        { value: config.ethPrice }
      );

      await expect(roundManager.cancelRound(config.roundId)).to.be.revertedWith(
        "Round has entries"
      );
    });

    it("buys a freeze token, freezes a participant, and supports paid unfreeze", async function () {
      const fixture = await deployFixture();
      const { easyGame, arenaSkills, usdc, root, first, projectWallet } = fixture;
      const { config, signature } = await signedOpenRound(fixture, {
        roundId: 5001n,
      });
      await easyGame.connect(root).activateRound(config, signature, ethers.ZeroAddress, {
        value: config.ethPrice,
      });
      await easyGame.connect(first).activateRound(config, signature, root.address, {
        value: config.ethPrice,
      });

      const freezePrice = await arenaSkills.FREEZE_TOKEN_PRICE_USDC();
      await usdc.mint(root.address, freezePrice);
      await usdc.connect(root).approve(await arenaSkills.getAddress(), freezePrice);
      await expect(arenaSkills.connect(root).buyFreezeToken(config.roundId))
        .to.changeTokenBalance(usdc, projectWallet, freezePrice);
      await expect(arenaSkills.connect(root).freezePlayer(config.roundId, first.address))
        .to.emit(arenaSkills, "PlayerFrozen");

      let status = await arenaSkills.getArenaStatus(config.roundId, first.address);
      expect(status.frozen).to.equal(true);
      expect(status.freezeHits).to.equal(1);

      const unfreezePrice = await arenaSkills.getUnfreezePriceUsdc(
        config.roundId,
        first.address
      );
      expect(unfreezePrice).to.be.gte(1_000_000n);
      await usdc.mint(first.address, unfreezePrice);
      await usdc.connect(first).approve(await arenaSkills.getAddress(), unfreezePrice);
      await arenaSkills.connect(first).buyUnfreeze(config.roundId);
      status = await arenaSkills.getArenaStatus(config.roundId, first.address);
      expect(status.frozen).to.equal(false);
    });

    it("keeps arena skills available after entries close and before round end", async function () {
      const fixture = await deployFixture();
      const { easyGame, arenaSkills, roundManager, usdc, root, first } = fixture;
      const block = await ethers.provider.getBlock("latest");
      const { config, signature } = await signedOpenRound(fixture, {
        roundId: 5002n,
        entriesCloseAt: BigInt(block.timestamp + 300),
        endsAt: BigInt(block.timestamp + 1800),
        freezeClosesAt: BigInt(block.timestamp + 1800),
      });
      await easyGame.connect(root).activateRound(config, signature, ethers.ZeroAddress, {
        value: config.ethPrice,
      });
      await easyGame.connect(first).activateRound(config, signature, root.address, {
        value: config.ethPrice,
      });

      const freezePrice = await arenaSkills.FREEZE_TOKEN_PRICE_USDC();
      await usdc.mint(root.address, freezePrice);
      await usdc.connect(root).approve(await arenaSkills.getAddress(), freezePrice);
      await arenaSkills.connect(root).buyFreezeToken(config.roundId);

      await ethers.provider.send("evm_setNextBlockTimestamp", [
        Number(config.entriesCloseAt + 1n),
      ]);
      await ethers.provider.send("evm_mine", []);
      expect(await roundManager.getRoundPhase(config.roundId)).to.equal(3);
      await expect(
        arenaSkills.connect(root).freezePlayer(config.roundId, first.address)
      ).to.emit(arenaSkills, "PlayerFrozen");
      expect(await arenaSkills.isFrozen(config.roundId, first.address)).to.equal(true);
    });

    it("settles Merkle winner cells and splits the complete round pool", async function () {
      const fixture = await deployFixture();
      const { easyGame, settlement, roundManager, root, first, second } = fixture;
      const roundId = 6001n;
      const winningCells = [1n, 3n, 7n, 15n];
      const tree = winnerTree(roundId, winningCells);
      const { config, signature } = await signedOpenRound(fixture, {
        roundId,
        maxWinners: winningCells.length,
        winningCellsRoot: tree.root,
      });
      for (const [player, inviter] of [
        [root, ethers.ZeroAddress],
        [first, root.address],
        [second, first.address],
      ]) {
        await easyGame.connect(player).activateRound(config, signature, inviter, {
          value: config.ethPrice,
        });
      }
      const pool = (await easyGame.getRoundGameStats(roundId)).prizePoolEth;
      await ethers.provider.send("evm_setNextBlockTimestamp", [Number(config.endsAt)]);
      await ethers.provider.send("evm_mine", []);

      await expect(settlement.settleRound(roundId, winningCells, tree.proofs))
        .to.emit(settlement, "RoundPrizeAllocated")
        .withArgs(roundId, config.level, 2, pool, 0);
      expect(await settlement.claimableEth(root.address)).to.equal(pool / 2n + pool % 2n);
      expect(await settlement.claimableEth(second.address)).to.equal(pool / 2n);
      expect((await roundManager.getRoundState(roundId)).settled).to.equal(true);
      expect((await easyGame.getRoundGameStats(roundId)).prizePoolEth).to.equal(0);
    });

    it("excludes a player frozen through the deadline from settlement", async function () {
      const fixture = await deployFixture();
      const { easyGame, arenaSkills, settlement, usdc, root, first } = fixture;
      const block = await ethers.provider.getBlock("latest");
      const roundId = 6002n;
      const winningCells = [1n, 2n];
      const tree = winnerTree(roundId, winningCells);
      const { config, signature } = await signedOpenRound(fixture, {
        roundId,
        maxWinners: winningCells.length,
        entriesCloseAt: BigInt(block.timestamp + 300),
        endsAt: BigInt(block.timestamp + 1800),
        freezeClosesAt: BigInt(block.timestamp + 1800),
        freezeLimit: 10,
        winningCellsRoot: tree.root,
      });
      await easyGame.connect(root).activateRound(config, signature, ethers.ZeroAddress, {
        value: config.ethPrice,
      });
      await easyGame.connect(first).activateRound(config, signature, root.address, {
        value: config.ethPrice,
      });
      const freezePrice = await arenaSkills.FREEZE_TOKEN_PRICE_USDC();
      await usdc.mint(first.address, freezePrice);
      await usdc.connect(first).approve(await arenaSkills.getAddress(), freezePrice);
      await ethers.provider.send("evm_setNextBlockTimestamp", [Number(config.endsAt - 10n)]);
      await ethers.provider.send("evm_mine", []);
      await arenaSkills.connect(first).buyFreezeToken(roundId);
      await arenaSkills.connect(first).freezePlayer(roundId, root.address);

      const pool = (await easyGame.getRoundGameStats(roundId)).prizePoolEth;
      await ethers.provider.send("evm_setNextBlockTimestamp", [Number(config.endsAt)]);
      await ethers.provider.send("evm_mine", []);
      await expect(settlement.settleRound(roundId, winningCells, tree.proofs))
        .to.emit(settlement, "FrozenWinnerSkipped")
        .withArgs(roundId, 1, root.address);
      expect(await settlement.claimableEth(root.address)).to.equal(0);
      expect(await settlement.claimableEth(first.address)).to.equal(pool);
    });

    it("rolls an unclaimed pool into the next settled round of the level", async function () {
      const fixture = await deployFixture();
      const { easyGame, settlement, root } = fixture;
      const firstRoundId = 6003n;
      const firstCells = [7n];
      const firstTree = winnerTree(firstRoundId, firstCells);
      const firstManifest = await signedOpenRound(fixture, {
        roundId: firstRoundId,
        maxWinners: 1,
        winningCellsRoot: firstTree.root,
      });
      await easyGame.connect(root).activateRound(
        firstManifest.config,
        firstManifest.signature,
        ethers.ZeroAddress,
        { value: firstManifest.config.ethPrice }
      );
      const firstPool = (await easyGame.getRoundGameStats(firstRoundId)).prizePoolEth;
      await ethers.provider.send("evm_setNextBlockTimestamp", [
        Number(firstManifest.config.endsAt),
      ]);
      await ethers.provider.send("evm_mine", []);
      await settlement.settleRound(firstRoundId, firstCells, firstTree.proofs);
      expect(await settlement.rolloverEthByLevel(5)).to.equal(firstPool);

      const secondRoundId = 6004n;
      const secondCells = [1n];
      const secondTree = winnerTree(secondRoundId, secondCells);
      const secondManifest = await signedOpenRound(fixture, {
        roundId: secondRoundId,
        maxWinners: 1,
        winningCellsRoot: secondTree.root,
      });
      await easyGame.connect(root).activateRound(
        secondManifest.config,
        secondManifest.signature,
        ethers.ZeroAddress,
        { value: secondManifest.config.ethPrice }
      );
      const secondPool = (await easyGame.getRoundGameStats(secondRoundId)).prizePoolEth;
      await ethers.provider.send("evm_setNextBlockTimestamp", [
        Number(secondManifest.config.endsAt),
      ]);
      await ethers.provider.send("evm_mine", []);
      await settlement.settleRound(secondRoundId, secondCells, secondTree.proofs);
      expect(await settlement.rolloverEthByLevel(5)).to.equal(0);
      expect(await settlement.claimableEth(root.address)).to.equal(
        firstPool + secondPool
      );
    });
  });
});
