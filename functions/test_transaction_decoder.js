const assert = require("assert");
const { encodeFunctionData } = require("viem");
const {
  ARENA_SKILLS_TRANSACTION_ABI,
  CORE_TRANSACTION_ABI,
  USDC_TRANSACTION_ABI,
} = require("./game_abi");
const { decodeTrackedTransaction } = require("./transaction_decoder");

const addresses = {
  core: "0x1000000000000000000000000000000000000001",
  skills: "0x2000000000000000000000000000000000000002",
  settlement: "0x3000000000000000000000000000000000000003",
  usdc: "0x4000000000000000000000000000000000000004",
};

const config = {
  seasonId: 2026071902n,
  roundId: 202607190201n,
  level: 1,
  startsAt: 1n,
  entriesCloseAt: 2n,
  endsAt: 3n,
  freezeClosesAt: 2n,
  maxPlayers: 1000,
  maxWinners: 6,
  winningCellsRoot: `0x${"11".repeat(32)}`,
  ethPrice: 100000000000000n,
  usdcPrice: 2500000n,
  freezeLimit: 10,
  paymentSplitVersion: 1,
};

const signature = "0x1234";
const inviter = "0x5000000000000000000000000000000000000005";

const ethActivation = decodeTrackedTransaction({
  to: addresses.core,
  value: config.ethPrice,
  input: encodeFunctionData({
    abi: CORE_TRANSACTION_ABI,
    functionName: "activateRound",
    args: [config, signature, inviter],
  }),
}, addresses);
assert.deepStrictEqual(ethActivation, {
  operation: "activateRound",
  roundId: config.roundId.toString(),
  level: 1,
  amount: "0.0001",
  currency: "ETH",
});

const usdcActivation = decodeTrackedTransaction({
  to: addresses.core,
  value: 0n,
  input: encodeFunctionData({
    abi: CORE_TRANSACTION_ABI,
    functionName: "activateRoundWithUSDC",
    args: [config, signature, inviter],
  }),
}, addresses);
assert.strictEqual(usdcActivation.operation, "activateRoundUSDC");
assert.strictEqual(usdcActivation.amount, "2.5");
assert.strictEqual(usdcActivation.currency, "USDC");

const freeze = decodeTrackedTransaction({
  to: addresses.skills,
  value: 0n,
  input: encodeFunctionData({
    abi: ARENA_SKILLS_TRANSACTION_ABI,
    functionName: "freezePlayer",
    args: [config.roundId, inviter],
  }),
}, addresses);
assert.strictEqual(freeze.operation, "freezePlayer");
assert.strictEqual(freeze.roundId, config.roundId.toString());
assert.strictEqual(freeze.target, inviter.toLowerCase());

const approval = decodeTrackedTransaction({
  to: addresses.usdc,
  value: 0n,
  input: encodeFunctionData({
    abi: USDC_TRANSACTION_ABI,
    functionName: "approve",
    args: [addresses.core, config.usdcPrice],
  }),
}, addresses);
assert.strictEqual(approval.operation, "approveUSDC");
assert.strictEqual(approval.amount, "2.5");

assert.throws(
  () => decodeTrackedTransaction({
    to: "0x9000000000000000000000000000000000000009",
    value: 0n,
    input: "0x",
  }, addresses),
  /not an Easy Games contract/,
);

console.log("Transaction decoder tests passed");
