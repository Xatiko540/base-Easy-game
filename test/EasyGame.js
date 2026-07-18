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

    const RoundManager = await ethers.getContractFactory(
      "EasyGameRoundManagerTestHarness"
    );
    const roundManager = await RoundManager.deploy(operatorWallet.address);
    await roundManager.waitForDeployment();

    const EasyGameAdvance = await ethers.getContractFactory(
      "EasyGameAdvanceTestHarness"
    );
    const easyGame = await EasyGameAdvance.deploy(
      projectWallet.address,
      treasuryWallet.address,
      operatorWallet.address,
      await usdc.getAddress(),
      await roundManager.getAddress()
    );
    await easyGame.waitForDeployment();
    await roundManager.setGameCore(await easyGame.getAddress());
    const ArenaSkills = await ethers.getContractFactory("EasyGameArenaSkills");
    const arenaSkills = await ArenaSkills.deploy(
      await easyGame.getAddress(),
      await roundManager.getAddress(),
      await usdc.getAddress(),
      projectWallet.address
    );
    await arenaSkills.waitForDeployment();
    await roundManager.setArenaSkills(await arenaSkills.getAddress());
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
    await easyGame.finalizeSystemContracts();
    await roundManager.finalizeSystemContracts();

    return {
      easyGame,
      roundManager,
      arenaSkills,
      settlement,
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
    expect(await easyGame.levelAvailable(1)).to.equal(true);
    expect(await easyGame.levelAvailable(2)).to.equal(true);
    expect(await easyGame.levelAvailable(3)).to.equal(true);
    expect(await easyGame.levelAvailable(17)).to.equal(true);

    expect(await easyGame.MATRIX_PRIZE_BPS()).to.equal(7550);
    expect(await easyGame.DIRECT_REF_BPS()).to.equal(950);
    expect(await easyGame.SECOND_REF_BPS()).to.equal(600);
    expect(await easyGame.THIRD_REF_BPS()).to.equal(400);
    expect(await easyGame.PROJECT_FEE_BPS()).to.equal(500);
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
        freezeClosesAt: BigInt(block.timestamp + 7300),
        maxPlayers: 1024,
        maxWinners: 4,
        winningCellsRoot: ethers.keccak256(ethers.toUtf8Bytes("winning-cells")),
        ethPrice: ethers.parseEther("0.2"),
        usdcPrice: 200000n,
        freezeLimit: 10,
        paymentSplitVersion: 1,
        ...overrides,
      };
      if (overrides.freezeClosesAt === undefined) {
        config.freezeClosesAt = config.endsAt;
      }
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
      if (fixture.roundManager.forceCommitRoundConfig) {
        await fixture.roundManager.forceCommitRoundConfig(config);
      }
      return { config, signature, domain };
    }

    async function signedOpenRound(fixture, overrides = {}) {
      const block = await ethers.provider.getBlock("latest");
      return signedRound(fixture, {
        startsAt: BigInt(block.timestamp - 10),
        entriesCloseAt: BigInt(block.timestamp + 1800),
        endsAt: BigInt(block.timestamp + 3600),
        freezeClosesAt: BigInt(block.timestamp + 3600),
        ...overrides,
      });
    }

    async function drainRoundWork(easyGame, roundId) {
      while ((await easyGame.getRoundRecycleQueueState(roundId)).pending > 0n) {
        await easyGame.processRoundRecycles(roundId, 64);
      }
    }

    it("lazily initializes a signed round and keeps its config immutable", async function () {
      const fixture = await deployFixture();
      const { roundManager, outsider } = fixture;
      const { config, signature } = await signedOpenRound(fixture);
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

      expect(await roundManager.getRoundPhase(config.roundId)).to.equal(2);
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
      ).to.be.revertedWithCustomError(
        roundManager,
        "SeasonRoundConfigMismatch"
      );
    });

    it("derives phases from block timestamp at exact boundaries", async function () {
      const fixture = await deployFixture();
      const { roundManager } = fixture;
      const { config, signature } = await signedRound(fixture);

      await expect(roundManager.initializeRound(config, signature))
        .to.be.revertedWithCustomError(roundManager, "RoundNotStarted")
        .withArgs(config.roundId);

      await ethers.provider.send("evm_setNextBlockTimestamp", [
        Number(config.startsAt),
      ]);
      await ethers.provider.send("evm_mine", []);
      await roundManager.initializeRound(config, signature);
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

    it("prevents a published future manifest from preempting the current round", async function () {
      const fixture = await deployFixture();
      const { easyGame, roundManager, root } = fixture;
      const block = await ethers.provider.getBlock("latest");
      const current = await signedOpenRound(fixture, {
        roundId: 1010n,
        level: 6,
      });
      const future = await signedRound(fixture, {
        seasonId: 2n,
        roundId: 1011n,
        level: 6,
        startsAt: BigInt(block.timestamp + 5000),
        entriesCloseAt: BigInt(block.timestamp + 6000),
        endsAt: BigInt(block.timestamp + 9000),
      });

      await expect(
        roundManager.initializeRound(future.config, future.signature)
      ).to.be.revertedWithCustomError(roundManager, "RoundNotStarted");
      await easyGame.connect(root).activateRound(
        current.config,
        current.signature,
        ethers.ZeroAddress,
        { value: current.config.ethPrice }
      );
      expect(await roundManager.activeRoundByLevel(6)).to.equal(
        current.config.roundId
      );
    });

    it("requires freeze protection to remain enforceable through round end", async function () {
      const fixture = await deployFixture();
      const { roundManager } = fixture;
      const block = await ethers.provider.getBlock("latest");
      const { config, signature } = await signedOpenRound(fixture, {
        roundId: 1012n,
        freezeClosesAt: BigInt(block.timestamp + 1200),
        endsAt: BigInt(block.timestamp + 3600),
      });

      await expect(roundManager.initializeRound(config, signature))
        .to.be.revertedWithCustomError(roundManager, "InvalidRoundTimeRange");
    });

    it("rejects an unauthorized signer and cross-contract replay", async function () {
      const fixture = await deployFixture();
      const { roundManager, outsider, operatorWallet } = fixture;
      const { config, domain } = await signedOpenRound(fixture);
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
      const { config, signature } = await signedOpenRound(fixture, {
        roundId: 1008n,
        freezeLimit: 0,
      });
      await expect(roundManager.initializeRound(config, signature))
        .to.be.revertedWithCustomError(roundManager, "InvalidFreezeLimit")
        .withArgs(10, 0);
    });

    it("derives the freeze immunity limit from the round duration", async function () {
      const fixture = await deployFixture();
      const block = await ethers.provider.getBlock("latest");
      const startsAt = BigInt(block.timestamp - 10);
      const endsAt = startsAt + 25n * 60n * 60n;
      const invalid = await signedOpenRound(fixture, {
        roundId: 1009n,
        startsAt,
        endsAt,
        freezeClosesAt: endsAt,
        freezeLimit: 10,
      });
      await expect(
        fixture.roundManager.initializeRound(invalid.config, invalid.signature)
      )
        .to.be.revertedWithCustomError(
          fixture.roundManager,
          "InvalidFreezeLimit"
        )
        .withArgs(20, 10);

      const valid = await signedOpenRound(fixture, {
        roundId: 1010n,
        startsAt,
        endsAt,
        freezeClosesAt: endsAt,
        freezeLimit: 20,
      });
      await expect(
        fixture.roundManager.initializeRound(valid.config, valid.signature)
      ).to.emit(fixture.roundManager, "RoundInitialized");
    });

    it("supports owner pause, resume, cancellation, and signer rotation", async function () {
      const fixture = await deployFixture();
      const { roundManager, owner, outsider, operatorWallet } = fixture;
      const { config, signature } = await signedOpenRound(fixture);
      await roundManager.initializeRound(config, signature);

      await expect(roundManager.connect(outsider).setRoundPaused(config.roundId, true))
        .to.be.revertedWith("Only owner");
      await roundManager.connect(owner).setRoundPaused(config.roundId, true);
      expect(await roundManager.getRoundPhase(config.roundId)).to.equal(7);
      await roundManager.connect(owner).setRoundPaused(config.roundId, false);
      expect(await roundManager.getRoundPhase(config.roundId)).to.equal(2);

      await roundManager.connect(owner).cancelRound(config.roundId);
      expect(await roundManager.getRoundPhase(config.roundId)).to.equal(6);

      await roundManager.connect(owner).setScheduleSigner(outsider.address);
      expect(await roundManager.scheduleSigner()).to.equal(outsider.address);

      const oldSignerManifest = await signedOpenRound(fixture, { roundId: 1002n });
      await expect(
        roundManager.initializeRound(
          oldSignerManifest.config,
          oldSignerManifest.signature
        )
      ).to.be.revertedWithCustomError(roundManager, "InvalidScheduleSignature");

      const nextManifest = await signedOpenRound(fixture, { roundId: 1003n });
      const nextSignature = await outsider.signTypedData(
        nextManifest.domain,
        roundTypes,
        nextManifest.config
      );
      await expect(
        roundManager.initializeRound(nextManifest.config, nextSignature)
      ).to.emit(roundManager, "RoundInitialized");
      expect(await roundManager.allowedScheduleSigners(operatorWallet.address))
        .to.equal(false);
    });

    it("rejects payment before round start", async function () {
      const fixture = await deployFixture();
      const { easyGame, roundManager, root } = fixture;

      const { config, signature } = await signedRound(fixture);
      await expect(
        easyGame.connect(root).activateRound(config, signature, ethers.ZeroAddress, {
          value: config.ethPrice,
        })
      ).to.be.revertedWithCustomError(roundManager, "RoundNotStarted");
      expect((await fixture.roundManager.getRoundState(config.roundId)).initialized)
        .to.equal(false);
    });

    it("uses level availability only as an owner-controlled emergency pause", async function () {
      const fixture = await deployFixture();
      const { easyGame, root } = fixture;
      const { config, signature } = await signedOpenRound(fixture, {
        roundId: 2000n,
        level: 1,
      });

      await easyGame.setLevelAvailable(1, false);
      await expect(
        easyGame.connect(root).activateRound(config, signature, ethers.ZeroAddress, {
          value: config.ethPrice,
        })
      ).to.be.revertedWithCustomError(easyGame, "LevelEmergencyPaused");

      await easyGame.setLevelAvailable(1, true);
      await expect(
        easyGame.connect(root).activateRound(config, signature, ethers.ZeroAddress, {
          value: config.ethPrice,
        })
      ).to.emit(easyGame, "RoundActivated");
    });

    it("locks USDC configuration after the immutable system contracts are wired", async function () {
      const fixture = await deployFixture();
      const { easyGame, outsider } = fixture;
      await expect(easyGame.setUsdcToken(outsider.address))
        .to.be.revertedWithCustomError(easyGame, "UsdcTokenLocked");
    });

    it("permanently pins all contracts that can release prize pools", async function () {
      const fixture = await deployFixture();
      const { easyGame, roundManager, outsider } = fixture;

      expect(await easyGame.systemContractsFinalized()).to.equal(true);
      expect(await roundManager.systemContractsFinalized()).to.equal(true);
      await expect(easyGame.setSettlementContract(outsider.address))
        .to.be.revertedWithCustomError(
          easyGame,
          "SystemContractsAlreadyFinalized"
        );
      await expect(easyGame.setRoundManager(outsider.address))
        .to.be.revertedWithCustomError(
          easyGame,
          "SystemContractsAlreadyFinalized"
        );
      await expect(roundManager.setSettlementContract(outsider.address))
        .to.be.revertedWithCustomError(
          roundManager,
          "SystemContractsAlreadyFinalized"
        );
      await expect(roundManager.setGameCore(outsider.address))
        .to.be.revertedWithCustomError(
          roundManager,
          "SystemContractsAlreadyFinalized"
        );
      await expect(roundManager.setArenaSkills(outsider.address))
        .to.be.revertedWithCustomError(
          roundManager,
          "SystemContractsAlreadyFinalized"
        );
    });

    it("commits and validates the complete 17-round season on-chain", async function () {
      const fixture = await deployFixture();
      const { roundManager, operatorWallet } = fixture;
      const block = await ethers.provider.getBlock("latest");
      const network = await ethers.provider.getNetwork();
      const domain = {
        name: "EasyGameAdvance",
        version: "2",
        chainId: network.chainId,
        verifyingContract: await roundManager.getAddress(),
      };
      const seasonId = 9901n;
      const configs = [];
      const signatures = [];
      for (let level = 1; level <= 17; level++) {
        const startsAt = BigInt(block.timestamp + 100 + (level - 1) * 18000);
        const config = {
          seasonId,
          roundId: seasonId * 100n + BigInt(level),
          level,
          startsAt,
          entriesCloseAt: startsAt + 1800n,
          endsAt: startsAt + 3600n,
          freezeClosesAt: startsAt + 3600n,
          maxPlayers: 1024,
          maxWinners: 1,
          winningCellsRoot: ethers.keccak256(
            ethers.toUtf8Bytes(`season-${seasonId}-level-${level}`)
          ),
          ethPrice: ethers.parseEther("0.01"),
          usdcPrice: 10_000n,
          freezeLimit: 10,
          paymentSplitVersion: 1,
        };
        configs.push(config);
        signatures.push(
          await operatorWallet.signTypedData(domain, roundTypes, config)
        );
      }

      await expect(roundManager.commitSeason(configs, signatures))
        .to.emit(roundManager, "SeasonCommitted");
      const season = await roundManager.getSeasonState(seasonId);
      expect(season.committed).to.equal(true);
      expect(season.firstStartsAt).to.equal(configs[0].startsAt);
      expect(season.lastEndsAt).to.equal(configs[16].endsAt);
      for (const config of configs) {
        expect(
          await roundManager.getCommittedRoundHash(seasonId, config.level)
        ).to.equal(await roundManager.hashRoundConfig(config));
      }
      await expect(roundManager.commitSeason(configs, signatures))
        .to.be.revertedWithCustomError(roundManager, "SeasonAlreadyCommitted")
        .withArgs(seasonId);

      const secondSeasonId = seasonId + 1n;
      const reusedRoundConfigs = configs.map((config) => ({
        ...config,
        seasonId: secondSeasonId,
      }));
      const reusedRoundSignatures = [];
      for (const config of reusedRoundConfigs) {
        reusedRoundSignatures.push(
          await operatorWallet.signTypedData(domain, roundTypes, config)
        );
      }
      await expect(
        roundManager.commitSeason(reusedRoundConfigs, reusedRoundSignatures)
      )
        .to.be.revertedWithCustomError(roundManager, "DuplicateSeasonRoundId")
        .withArgs(reusedRoundConfigs[0].roundId);
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
    });

    it("turns each accumulated 100 referral weight into a bonus matrix ticket", async function () {
      const fixture = await deployFixture();
      const { easyGame, root, first } = fixture;
      const { config, signature } = await signedOpenRound(fixture, {
        roundId: 2010n,
      });
      await easyGame.connect(root).activateRound(
        config,
        signature,
        ethers.ZeroAddress,
        { value: config.ethPrice }
      );
      await expect(
        easyGame.connect(first).activateRound(
          config,
          signature,
          root.address,
          { value: config.ethPrice }
        )
      ).to.emit(easyGame, "ReferralBonusPositionGranted");

      const rootRound = await easyGame.getPlayerRound(
        root.address,
        config.roundId
      );
      expect(rootRound.tickets).to.equal(2);
      expect(rootRound.cellId).to.equal(3);
      expect(
        (await easyGame.getRoundGameStats(config.roundId)).activeCells
      ).to.equal(3);
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
        seasonId: 2n,
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

    it("keeps ETH round balances equal to pools, fees, and referral liabilities", async function () {
      const fixture = await deployFixture();
      const {
        easyGame,
        projectWallet,
        root,
        first,
        second,
        third,
      } = fixture;
      const { config, signature } = await signedOpenRound(fixture, {
        roundId: 3005n,
      });
      const entries = [
        [root, ethers.ZeroAddress],
        [first, root.address],
        [second, first.address],
        [third, second.address],
      ];

      for (const [player, inviter] of entries) {
        await easyGame.connect(player).activateRound(
          config,
          signature,
          inviter,
          { value: config.ethPrice }
        );
      }

      const stats = await easyGame.getRoundGameStats(config.roundId);
      const fees = await easyGame.projectFeesAccrued();
      const referralLiabilities =
        (await easyGame.getPlayer(root.address)).claimableReferralBonus +
        (await easyGame.getPlayer(first.address)).claimableReferralBonus +
        (await easyGame.getPlayer(second.address)).claimableReferralBonus;
      const contractBalance = await ethers.provider.getBalance(
        await easyGame.getAddress()
      );

      expect(contractBalance).to.equal(config.ethPrice * 4n);
      expect(stats.prizePoolEth + fees + referralLiabilities).to.equal(
        contractBalance
      );
      const rootState = await easyGame.getPlayer(root.address);
      expect(rootState.baseWeight).to.equal(100);
      expect(rootState.referralWeight).to.equal(175);
      expect(rootState.matrixWeight).to.equal(100);
      expect(rootState.nftWeight).to.equal(20);
      expect(rootState.totalWeight).to.equal(395);

      for (const player of [root, first, second]) {
        if ((await easyGame.getPlayer(player.address)).claimableReferralBonus > 0) {
          await easyGame.connect(player).claimReferralBonus();
        }
      }
      await expect(easyGame.withdrawProjectFees()).to.changeEtherBalance(
        projectWallet,
        fees
      );
      expect(await ethers.provider.getBalance(await easyGame.getAddress()))
        .to.equal(stats.prizePoolEth);
    });

    it("keeps USDC round balances equal to pools, fees, and referral liabilities", async function () {
      const fixture = await deployFixture();
      const {
        easyGame,
        usdc,
        projectWallet,
        root,
        first,
        second,
        third,
      } = fixture;
      const { config, signature } = await signedOpenRound(fixture, {
        roundId: 3006n,
      });
      const entries = [
        [root, ethers.ZeroAddress],
        [first, root.address],
        [second, first.address],
        [third, second.address],
      ];
      const coreAddress = await easyGame.getAddress();

      for (const [player, inviter] of entries) {
        await usdc.mint(player.address, config.usdcPrice);
        await usdc.connect(player).approve(coreAddress, config.usdcPrice);
        await easyGame
          .connect(player)
          .activateRoundWithUSDC(config, signature, inviter);
      }

      const stats = await easyGame.getRoundGameStats(config.roundId);
      const fees = await easyGame.projectFeesAccruedUsdc();
      const referralLiabilities =
        (await easyGame.claimableReferralBonusUsdc(root.address)) +
        (await easyGame.claimableReferralBonusUsdc(first.address)) +
        (await easyGame.claimableReferralBonusUsdc(second.address));
      const contractBalance = await usdc.balanceOf(coreAddress);

      expect(contractBalance).to.equal(config.usdcPrice * 4n);
      expect(stats.prizePoolUsdc + fees + referralLiabilities).to.equal(
        contractBalance
      );

      for (const player of [root, first, second]) {
        if ((await easyGame.claimableReferralBonusUsdc(player.address)) > 0) {
          await easyGame.connect(player).claimReferralBonusUSDC();
        }
      }
      await expect(easyGame.withdrawProjectFeesUSDC()).to.changeTokenBalance(
        usdc,
        projectWallet,
        fees
      );
      expect(await usdc.balanceOf(coreAddress)).to.equal(stats.prizePoolUsdc);
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

    it("prices an ETH-only round unfreeze through the signed ETH/USDC ticket ratio", async function () {
      const fixture = await deployFixture();
      const { easyGame, arenaSkills, root, first } = fixture;
      const { config, signature } = await signedOpenRound(fixture, {
        roundId: 5003n,
        ethPrice: ethers.parseEther("1"),
        usdcPrice: 100_000_000n,
      });
      await easyGame.connect(root).activateRound(
        config,
        signature,
        ethers.ZeroAddress,
        { value: config.ethPrice }
      );
      await easyGame.connect(first).activateRound(
        config,
        signature,
        root.address,
        { value: config.ethPrice }
      );

      expect(await arenaSkills.getUnfreezePriceUsdc(config.roundId, first.address))
        .to.be.gt(await arenaSkills.MIN_UNFREEZE_PRICE_USDC());
    });

    it("keeps arena skills available after entries close and before round end", async function () {
      const fixture = await deployFixture();
      const { easyGame, arenaSkills, roundManager, usdc, root, first } = fixture;
      const block = await ethers.provider.getBlock("latest");
      const { config, signature } = await signedOpenRound(fixture, {
        roundId: 5002n,
        entriesCloseAt: BigInt(block.timestamp + 300),
        endsAt: BigInt(block.timestamp + 3600),
        freezeClosesAt: BigInt(block.timestamp + 3600),
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

    it("blocks settlement until the bounded recycle queue is fully processed", async function () {
      const fixture = await deployFixture();
      const { easyGame, settlement, roundManager, root } = fixture;
      const roundId = 5901n;
      const winningCells = [1n];
      const tree = winnerTree(roundId, winningCells);
      const { config, signature } = await signedOpenRound(fixture, {
        roundId,
        maxWinners: 1,
        winningCellsRoot: tree.root,
        ethPrice: ethers.parseEther("0.01"),
      });

      await easyGame.connect(root).activateRound(
        config,
        signature,
        ethers.ZeroAddress,
        { value: config.ethPrice }
      );
      for (let index = 0; index < 5; index++) {
        await easyGame.forceQueueRoundRecycle(roundId, root.address);
      }
      const pending = (await easyGame.getRoundRecycleQueueState(roundId)).pending;
      expect(pending).to.be.gt(0);

      await ethers.provider.send("evm_setNextBlockTimestamp", [Number(config.endsAt)]);
      await ethers.provider.send("evm_mine", []);
      await expect(settlement.settleRound(roundId, winningCells, tree.proofs))
        .to.be.revertedWith("Pending round recycles");

      while ((await easyGame.getRoundRecycleQueueState(roundId)).pending > 0n) {
        await easyGame.processRoundRecycles(roundId, 4);
      }
      await settlement.settleRound(roundId, winningCells, tree.proofs);
      expect((await roundManager.getRoundState(roundId)).settled).to.equal(true);
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
      await drainRoundWork(easyGame, roundId);
      const winners = [];
      const nextCell = (await easyGame.getRoundGameStats(roundId)).nextCell;
      for (const cellId of winningCells) {
        if (cellId >= nextCell) continue;
        const node = await easyGame.getRoundMatrixNode(roundId, cellId);
        if (!winners.some(({ address }) => address === node.player)) {
          winners.push({
            address: node.player,
            weight: (await easyGame.getPlayerRound(node.player, roundId))
              .totalWeight,
          });
        }
      }
      const totalWinnerWeight = winners.reduce(
        (sum, winner) => sum + winner.weight,
        0n
      );
      const expectedShares = new Map();
      let allocated = 0n;
      for (const winner of winners) {
        const share = (pool * winner.weight) / totalWinnerWeight;
        expectedShares.set(winner.address, share);
        allocated += share;
      }
      expectedShares.set(
        winners[0].address,
        expectedShares.get(winners[0].address) + pool - allocated
      );

      await expect(settlement.settleRound(roundId, winningCells, tree.proofs))
        .to.emit(settlement, "RoundPrizeAllocated")
        .withArgs(roundId, config.level, winners.length, pool, 0);
      for (const player of [root, first, second]) {
        expect(await settlement.claimableEth(player.address)).to.equal(
          expectedShares.get(player.address) ?? 0n
        );
      }
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
        endsAt: BigInt(block.timestamp + 3600),
        freezeClosesAt: BigInt(block.timestamp + 3600),
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
      await drainRoundWork(easyGame, roundId);
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
        seasonId: 2n,
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

    it("allows any first level but then requires the next higher level", async function () {
      const fixture = await deployFixture();
      const { easyGame, roundManager, root } = fixture;
      const block = await ethers.provider.getBlock("latest");
      const level3 = await signedRound(fixture, {
        roundId: 7003n,
        level: 3,
        startsAt: BigInt(block.timestamp - 19000),
        entriesCloseAt: BigInt(block.timestamp + 3600),
        endsAt: BigInt(block.timestamp + 7200),
        freezeClosesAt: BigInt(block.timestamp + 7200),
      });
      const level2 = await signedRound(fixture, {
        roundId: 7002n,
        level: 2,
        startsAt: level3.config.startsAt - 19000n,
        entriesCloseAt: BigInt(block.timestamp + 3600),
        endsAt: BigInt(block.timestamp + 7200),
        freezeClosesAt: BigInt(block.timestamp + 7200),
      });
      const level5 = await signedOpenRound(fixture, {
        roundId: 7005n,
        level: 5,
      });
      const level4 = await signedRound(fixture, {
        roundId: 7004n,
        level: 4,
        startsAt: level3.config.startsAt + 18000n,
        entriesCloseAt: BigInt(block.timestamp + 3600),
        endsAt: BigInt(block.timestamp + 7200),
        freezeClosesAt: BigInt(block.timestamp + 7200),
      });

      await easyGame.connect(root).activateRound(
        level3.config,
        level3.signature,
        ethers.ZeroAddress,
        { value: level3.config.ethPrice }
      );
      await expect(
        easyGame.connect(root).activateRound(
          level2.config,
          level2.signature,
          ethers.ZeroAddress,
          { value: level2.config.ethPrice }
        )
      ).to.be.revertedWithCustomError(
        roundManager,
        "InvalidPlayerLevelProgression"
      ).withArgs(4, 2);
      await expect(
        easyGame.connect(root).activateRound(
          level5.config,
          level5.signature,
          ethers.ZeroAddress,
          { value: level5.config.ethPrice }
        )
      ).to.be.revertedWithCustomError(
        roundManager,
        "InvalidPlayerLevelProgression"
      ).withArgs(4, 5);

      await easyGame.connect(root).activateRound(
        level4.config,
        level4.signature,
        ethers.ZeroAddress,
        { value: level4.config.ethPrice }
      );
      const progress = await roundManager.getPlayerSeasonProgress(1, root.address);
      expect(progress.startLevel).to.equal(3);
      expect(progress.highestLevel).to.equal(4);
      expect(progress.activatedLevels).to.equal(2);
      expect(progress.inviteCapacity).to.equal(8);
    });

    it("grants four unique direct invite slots per activated level", async function () {
      const fixture = await deployFixture();
      const {
        easyGame,
        roundManager,
        root,
        first,
        second,
        third,
        fourth,
        fifth,
      } = fixture;
      const block = await ethers.provider.getBlock("latest");
      const level5 = await signedRound(fixture, {
        roundId: 7105n,
        level: 5,
        startsAt: BigInt(block.timestamp - 22000),
        entriesCloseAt: BigInt(block.timestamp + 3600),
        endsAt: BigInt(block.timestamp + 7200),
        freezeClosesAt: BigInt(block.timestamp + 7200),
      });
      const level6 = await signedRound(fixture, {
        roundId: 7106n,
        level: 6,
        startsAt: level5.config.startsAt + 18000n,
        entriesCloseAt: BigInt(block.timestamp + 3600),
        endsAt: BigInt(block.timestamp + 7200),
        freezeClosesAt: BigInt(block.timestamp + 7200),
      });

      await easyGame.connect(root).activateRound(
        level5.config,
        level5.signature,
        ethers.ZeroAddress,
        { value: level5.config.ethPrice }
      );
      for (const invitee of [first, second, third, fourth]) {
        await easyGame.connect(invitee).activateRound(
          level5.config,
          level5.signature,
          root.address,
          { value: level5.config.ethPrice }
        );
      }
      await expect(
        easyGame.connect(fifth).activateRound(
          level5.config,
          level5.signature,
          root.address,
          { value: level5.config.ethPrice }
        )
      ).to.be.revertedWithCustomError(
        roundManager,
        "ReferralCapacityReached"
      ).withArgs(root.address, 4, 4);

      await easyGame.connect(root).activateRound(
        level6.config,
        level6.signature,
        ethers.ZeroAddress,
        { value: level6.config.ethPrice }
      );
      await easyGame.connect(fifth).activateRound(
        level5.config,
        level5.signature,
        root.address,
        { value: level5.config.ethPrice }
      );
      const progress = await roundManager.getPlayerSeasonProgress(1, root.address);
      expect(progress.directInvites).to.equal(5);
      expect(progress.inviteCapacity).to.equal(8);
    });

    it("blocks the next level while the player is frozen on the current level", async function () {
      const fixture = await deployFixture();
      const { easyGame, roundManager, arenaSkills, usdc, root, first } = fixture;
      const block = await ethers.provider.getBlock("latest");
      const level3 = await signedRound(fixture, {
        roundId: 7203n,
        level: 3,
        startsAt: BigInt(block.timestamp - 19000),
        entriesCloseAt: BigInt(block.timestamp + 3600),
        endsAt: BigInt(block.timestamp + 7200),
        freezeClosesAt: BigInt(block.timestamp + 7200),
      });
      const level4 = await signedRound(fixture, {
        roundId: 7204n,
        level: 4,
        startsAt: level3.config.startsAt + 18000n,
        entriesCloseAt: BigInt(block.timestamp + 3600),
        endsAt: BigInt(block.timestamp + 7200),
        freezeClosesAt: BigInt(block.timestamp + 7200),
      });
      await easyGame.connect(root).activateRound(
        level3.config,
        level3.signature,
        ethers.ZeroAddress,
        { value: level3.config.ethPrice }
      );
      await easyGame.connect(first).activateRound(
        level3.config,
        level3.signature,
        root.address,
        { value: level3.config.ethPrice }
      );

      const freezePrice = await arenaSkills.FREEZE_TOKEN_PRICE_USDC();
      await usdc.mint(root.address, freezePrice);
      await usdc.connect(root).approve(await arenaSkills.getAddress(), freezePrice);
      await arenaSkills.connect(root).buyFreezeToken(level3.config.roundId);
      await arenaSkills.connect(root).freezePlayer(level3.config.roundId, first.address);

      await expect(
        easyGame.connect(first).activateRound(
          level4.config,
          level4.signature,
          root.address,
          { value: level4.config.ethPrice }
        )
      ).to.be.revertedWithCustomError(
        roundManager,
        "PlayerProgressionFrozen"
      ).withArgs(level3.config.roundId, first.address);
    });
  });
});
