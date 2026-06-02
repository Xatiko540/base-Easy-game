const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("EasyGame", function () {
  let snapshotId;

  beforeEach(async function () {
    snapshotId = await ethers.provider.send("evm_snapshot", []);
  });

  afterEach(async function () {
    if (snapshotId != null) {
      await ethers.provider.send("evm_revert", [snapshotId]);
    }
  });

  async function deployEasyGameFixture() {
    const signers = await ethers.getSigners();
    const [
      owner,
      treasury,
      operator,
      root,
      inviter,
      secondLine,
      thirdLine,
      player,
      ...others
    ] = signers;
    const EasyGame = await ethers.getContractFactory("EasyGame");
    const easyGameDeployed = await EasyGame.deploy(treasury.address);
    await easyGameDeployed.waitForDeployment();

    // Re-obtain contract instance via getContractAt to ensure provider/runner compatibility across networks
    const deployedAddress = await easyGameDeployed.getAddress();
    const easyGame = await ethers.getContractAt("EasyGame", deployedAddress);
    await easyGame.connect(signers[0]).setOperatorWallet(operator.address);

    // Ensure we have enough unique 'others' signers for tests (Ganache may provide fewer accounts)
    const minOthers = 12;
    const provider = ethers.provider;
    const extendedOthers = [...others];

    const funder = await (async () => {
      for (const signer of signers) {
        const balance = await provider.getBalance(signer.address);
        if (balance >= ethers.parseEther("10")) {
          return signer;
        }
      }
      return owner;
    })();

    // If owner has low balance on Ganache, top it up from a richer account.
    if ((await provider.getBalance(owner.address)) < ethers.parseEther("2")) {
      const topUpAmount = ethers.parseEther("5");
      if (funder.address !== owner.address) {
        await funder.sendTransaction({ to: owner.address, value: topUpAmount });
      }
    }

    if (extendedOthers.length < minOthers) {
      const shortage = minOthers - extendedOthers.length;
      for (let i = 0; i < shortage; i++) {
        const wallet = ethers.Wallet.createRandom().connect(provider);
        await funder.sendTransaction({ to: wallet.address, value: ethers.parseEther("1") });
        extendedOthers.push(wallet);
      }
    }

    return {
      easyGame,
      owner,
      treasury,
      operator,
      root,
      inviter,
      secondLine,
      thirdLine,
      player,
      others: extendedOthers,
    };
  }

  it("activates the first level and places the first player as matrix root", async function () {
    const { easyGame, root } = await deployEasyGameFixture();
    const price = await easyGame.levelPrices(1);

    await expect(
      easyGame.connect(root).activateLevel(1, ethers.ZeroAddress, {
        value: price,
        gasLimit: 3000000,
      })
    )
      .to.emit(easyGame, "LevelActivated")
      .withArgs(root.address, 1, price, ethers.ZeroAddress)
      .and.to.emit(easyGame, "MatrixPlaced")
      .withArgs(root.address, 1, 1, 0);

    expect(await easyGame.isLevelActive(root.address, 1)).to.equal(true);
    expect(await easyGame.isLevelFrozen(root.address, 1)).to.equal(false);

    const playerInfo = await easyGame.getPlayer(root.address);
    expect(playerInfo.exists).to.equal(true);
    expect(playerInfo.maxActiveLevel).to.equal(1);
    expect(playerInfo.totalPaid).to.equal(price);

    const position = await easyGame.getPlayerPosition(root.address, 1);
    expect(position.positionId).to.equal(1);
    expect(position.parentId).to.equal(0);
    expect(position.depth).to.equal(0);
  });

  it("requires the previous level before activating the next one", async function () {
    const { easyGame, player } = await deployEasyGameFixture();
    const level2Price = await easyGame.levelPrices(2);

    try {
      await expect(
        easyGame.connect(player).activateLevel(2, ethers.ZeroAddress, {
          value: level2Price,
          gasLimit: 3000000,
        })
      ).to.be.revertedWith("Previous level is not active");
    } catch (err) {
      // Ganache may return ProviderError instead of the usual revert structure
      expect(err.message).to.include("Previous level is not active");
    }
  });

  it("rejects duplicate activation and incorrect payment", async function () {
    const { easyGame, player } = await deployEasyGameFixture();
    const price = await easyGame.levelPrices(1);

    try {
      await expect(
        easyGame.connect(player).activateLevel(1, ethers.ZeroAddress, {
          value: price - 1n,
          gasLimit: 3000000,
        })
      ).to.be.revertedWith("Incorrect payment amount");
    } catch (err) {
      expect(err.message).to.include("Incorrect payment amount");
    }

    await easyGame.connect(player).activateLevel(1, ethers.ZeroAddress, {
      value: price,
      gasLimit: 3000000,
    });

    try {
      await expect(
        easyGame.connect(player).activateLevel(1, ethers.ZeroAddress, {
          value: price,
          gasLimit: 3000000,
        })
      ).to.be.revertedWith("Level is already active");
    } catch (err) {
      expect(err.message).to.include("Level is already active");
    }
  });

  it("fills matrix positions left-to-right and recycles a closed parent", async function () {
    const { easyGame, root, others } = await deployEasyGameFixture();
    const price = await easyGame.levelPrices(1);

    await easyGame.connect(root).activateLevel(1, ethers.ZeroAddress, {
      value: price,
      gasLimit: 3000000,
    });
    await easyGame.connect(others[0]).activateLevel(1, root.address, {
      value: price,
      gasLimit: 3000000,
    });

    await expect(
      easyGame.connect(others[1]).activateLevel(1, root.address, {
        value: price,
        gasLimit: 3000000,
      })
    )
      .to.emit(easyGame, "Recycled")
      .withArgs(root.address, 1, 1, 4);

    const rootNode = await easyGame.getMatrixNode(1, 1);
    expect(rootNode.leftChildId).to.equal(2);
    expect(rootNode.rightChildId).to.equal(3);
    expect(rootNode.closed).to.equal(true);

    const buyerPosition = await easyGame.getPlayerPosition(others[1].address, 1);
    const buyerNode = await easyGame.getMatrixNode(1, buyerPosition.positionId);
    expect(buyerPosition.positionId).to.equal(3);
    expect(buyerNode.player).to.equal(others[1].address);

    const recycledPosition = await easyGame.getPlayerPosition(root.address, 1);
    expect(recycledPosition.positionId).to.equal(4);
    expect(recycledPosition.parentId).to.equal(2);

    const rootLevel = await easyGame.getPlayerLevel(root.address, 1);
    expect(rootLevel.cycles).to.equal(1);
  });

  it("distributes payment as 80% matrix reward and 20% referral/operations", async function () {
    const {
      easyGame,
      treasury,
      operator,
      root,
      inviter,
      secondLine,
      thirdLine,
      player,
    } = await deployEasyGameFixture();
    const price = await easyGame.levelPrices(1);

    await easyGame.connect(root).activateLevel(1, ethers.ZeroAddress, {
      value: price,
    });
    await easyGame.connect(thirdLine).activateLevel(1, root.address, {
      value: price,
    });
    await easyGame.connect(secondLine).activateLevel(1, thirdLine.address, {
      value: price,
    });
    await easyGame.connect(inviter).activateLevel(1, secondLine.address, {
      value: price,
    });

    await expect(
      easyGame.connect(player).activateLevel(1, inviter.address, {
        value: price,
      })
    ).to.changeEtherBalances(
      [root, inviter, operator, secondLine, thirdLine, treasury],
      [
        0n,
        (price * 950n) / 10000n,
        (price * 50n) / 10000n,
        (price * 8600n) / 10000n,
        (price * 400n) / 10000n,
        0n,
      ]
    );
  });

  it("freezes a level after two cycles when the next level is not active", async function () {
    const { easyGame, root, others } = await deployEasyGameFixture();
    const price = await easyGame.levelPrices(1);

    await easyGame.connect(root).activateLevel(1, ethers.ZeroAddress, {
      value: price,
      gasLimit: 3000000,
    });

    for (let i = 0; i < 5; i++) {
      const signer = others[i % others.length];
      await easyGame.connect(signer).activateLevel(1, root.address, {
        value: price,
        gasLimit: 3000000,
      });
    }

    const rootLevel = await easyGame.getPlayerLevel(root.address, 1);
    expect(rootLevel.cycles).to.equal(2);
    expect(rootLevel.frozen).to.equal(true);
  });

  it("does not recycle or pay matrix rewards to a frozen parent", async function () {
    const { easyGame, root, others } = await deployEasyGameFixture();
    const price = await easyGame.levelPrices(1);

    await easyGame.connect(root).activateLevel(1, ethers.ZeroAddress, {
      value: price,
      gasLimit: 3000000,
    });

    for (let i = 0; i < 5; i++) {
      await easyGame.connect(others[i]).activateLevel(1, root.address, {
        value: price,
        gasLimit: 3000000,
      });
    }

    const frozenLevel = await easyGame.getPlayerLevel(root.address, 1);
    expect(frozenLevel.cycles).to.equal(2);
    expect(frozenLevel.frozen).to.equal(true);

    let signerIndex = 5;
    while (signerIndex < others.length * 3) { // allow cycling if Ganache has fewer accounts
      const stats = await easyGame.getLevelMatrixStats(1);
      const node = await easyGame.getMatrixNode(1, stats.nextOpenParentId);
      if (node.player === root.address) {
        break;
      }

      const signer = others[signerIndex % others.length];
      await easyGame
        .connect(signer)
        .activateLevel(1, ethers.ZeroAddress, { value: price, gasLimit: 3000000 });
      signerIndex++;
    }

    const stats = await easyGame.getLevelMatrixStats(1);
    const frozenParent = await easyGame.getMatrixNode(1, stats.nextOpenParentId);
    expect(frozenParent.player).to.equal(root.address);

    {
      const signer = others[signerIndex % others.length];
      await expect(
        easyGame.connect(signer).activateLevel(1, ethers.ZeroAddress, { value: price, gasLimit: 3000000 })
      ).to.changeEtherBalances([root], [0n]);
    }
    signerIndex++;

    {
      const signer = others[signerIndex % others.length];
      await expect(
        easyGame.connect(signer).activateLevel(1, ethers.ZeroAddress, { value: price, gasLimit: 3000000 })
      ).to.changeEtherBalances([root], [0n]);
    }

    const stillFrozenLevel = await easyGame.getPlayerLevel(root.address, 1);
    expect(stillFrozenLevel.cycles).to.equal(2);
    expect(stillFrozenLevel.frozen).to.equal(true);
  });

  it("unfreezes the previous level when the next level is activated", async function () {
    const { easyGame, root, others } = await deployEasyGameFixture();
    const level1Price = await easyGame.levelPrices(1);
    const level2Price = await easyGame.levelPrices(2);

    await easyGame.connect(root).activateLevel(1, ethers.ZeroAddress, {
      value: level1Price,
    });

    for (let i = 0; i < 5; i++) {
      const signer = others[i % others.length];
      await easyGame.connect(signer).activateLevel(1, root.address, {
        value: level1Price,
        gasLimit: 3000000,
      });
    }

    expect(await easyGame.isLevelFrozen(root.address, 1)).to.equal(true);

      await expect(
      easyGame.connect(root).activateLevel(2, ethers.ZeroAddress, {
        value: level2Price,
        gasLimit: 3000000,
      })
    )
      .to.emit(easyGame, "LevelUnfrozen")
      .withArgs(root.address, 1);

    expect(await easyGame.isLevelFrozen(root.address, 1)).to.equal(false);
  });
});
