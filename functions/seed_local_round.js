const { initializeApp } = require("firebase-admin/app");
const { getFirestore, Timestamp, FieldValue } = require("firebase-admin/firestore");
const { Contract, HDNodeWallet, JsonRpcProvider, TypedDataEncoder } = require("ethers");
const coreArtifact = require("../src/artifacts/EasyGameAdvance.json");
const managerArtifact = require("../src/artifacts/EasyGameRoundManager.json");
const { buildWinningCellTree } = require("./round_merkle");

process.env.FIRESTORE_EMULATOR_HOST ||= "127.0.0.1:8080";
initializeApp({ projectId: "lottery-advance" });

const chainId = 31337;
const coreAddress = coreArtifact.networks[String(chainId)]?.address;
const managerAddress = managerArtifact.networks[String(chainId)]?.address;
if (!coreAddress || !managerAddress) {
  throw new Error("Deploy local contracts before seeding the round");
}

const mnemonic = "test test test test test test test test test test test junk";
const signer = HDNodeWallet.fromPhrase(mnemonic);
const types = {
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

async function main() {
  const now = Math.floor(Date.now() / 1000);
  const roundId = BigInt(now);
  const winningCells = [1n, 3n, 7n, 15n];
  const winners = buildWinningCellTree(roundId, winningCells);
  const config = {
    seasonId: 1n,
    roundId,
    level: 5,
    startsAt: BigInt(now - 5),
    entriesCloseAt: BigInt(now + 60 * 60),
    endsAt: BigInt(now + 2 * 60 * 60),
    freezeClosesAt: BigInt(now + 2 * 60 * 60),
    maxPlayers: 1024,
    maxWinners: winningCells.length,
    winningCellsRoot: winners.root,
    ethPrice: 200000000000000000n,
    usdcPrice: 200000n,
    freezeLimit: 10,
    paymentSplitVersion: 1,
  };
  const domain = {
    name: "EasyGameAdvance",
    version: "2",
    chainId,
    verifyingContract: managerAddress,
  };
  const signature = await signer.signTypedData(domain, types, config);
  const configHash = TypedDataEncoder.hashStruct("RoundConfig", types, config);
  const provider = new JsonRpcProvider("http://127.0.0.1:8545", chainId);
  const manager = new Contract(
    managerAddress,
    managerArtifact.abi,
    provider,
  );
  if (!(await manager.verifyRoundConfig(config, signature))) {
    throw new Error("Round manager rejected the generated manifest");
  }
  const players = Array.from({ length: 7 }, (_, index) =>
    HDNodeWallet.fromPhrase(
      mnemonic,
      "",
      `m/44'/60'/0'/0/${index}`
    ).connect(provider)
  );
  const game = new Contract(coreAddress, coreArtifact.abi, provider);
  for (let index = 0; index < players.length; index++) {
    const inviter = index === 0
      ? "0x0000000000000000000000000000000000000000"
      : players[0].address;
    const transaction = await game.connect(players[index]).activateRound(
      config,
      signature,
      inviter,
      { value: config.ethPrice }
    );
    await transaction.wait();
  }
  const db = getFirestore();
  const previousRounds = await db
    .collection("rounds")
    .where("chainId", "==", chainId)
    .get();
  if (!previousRounds.empty) {
    const cleanup = db.batch();
    previousRounds.docs.forEach((document) => cleanup.delete(document.ref));
    await cleanup.commit();
  }
  await db.collection("seasons").doc("1").set({
    seasonId: 1,
    chainId,
    title: "Local development season",
    active: true,
    updatedAt: FieldValue.serverTimestamp(),
  });
  await db.collection("rounds").doc(roundId.toString()).set({
    chainId,
    contractAddress: coreAddress.toLowerCase(),
    roundManagerAddress: managerAddress.toLowerCase(),
    configHash,
    operatorSignature: signature,
    schemaVersion: 2,
    config: {
      seasonId: "1",
      roundId: roundId.toString(),
      level: 5,
      startsAt: Timestamp.fromMillis(Number(config.startsAt) * 1000),
      entriesCloseAt: Timestamp.fromMillis(Number(config.entriesCloseAt) * 1000),
      endsAt: Timestamp.fromMillis(Number(config.endsAt) * 1000),
      freezeClosesAt: Timestamp.fromMillis(Number(config.freezeClosesAt) * 1000),
      maxPlayers: 1024,
      maxWinners: 4,
      winningCellsRoot: config.winningCellsRoot,
      ethPriceWei: config.ethPrice.toString(),
      usdcPrice: config.usdcPrice.toString(),
      freezeLimit: 10,
      paymentSplitVersion: 1,
    },
    createdAt: FieldValue.serverTimestamp(),
  });
  const winnerBatch = db.batch();
  winningCells.forEach((cellId, index) => {
    const ref = db.collection("rounds").doc(roundId.toString())
      .collection("winningCells").doc(cellId.toString());
    winnerBatch.create(ref, {
      cellId: cellId.toString(),
      proof: winners.proofs[index],
      createdAt: FieldValue.serverTimestamp(),
    });
  });
  await winnerBatch.commit();
  await db.collection("users").doc(`${chainId}_${signer.address.toLowerCase()}`).set({
    wallet: signer.address.toLowerCase(),
    chainId,
    exists: true,
    walletVerified: false,
    profileVersion: 1,
    localDevelopmentProfile: true,
    registeredAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  console.log(JSON.stringify({
    roundId: roundId.toString(),
    level: 5,
    startsAt: Number(config.startsAt),
    coreAddress,
    managerAddress,
    signer: signer.address,
    participants: players.map((player) => player.address),
  }, null, 2));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
