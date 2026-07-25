const {
  decodeFunctionData,
  formatEther,
  formatUnits,
  getAddress,
} = require("viem");
const {
  ARENA_SKILLS_TRANSACTION_ABI,
  CORE_TRANSACTION_ABI,
  SETTLEMENT_TRANSACTION_ABI,
  USDC_TRANSACTION_ABI,
} = require("./game_abi");

function normalizedAddress(value) {
  if (!value) return "";
  try {
    return getAddress(value).toLowerCase();
  } catch (_) {
    return "";
  }
}

function decodeTrackedTransaction(transaction, addresses) {
  const destination = normalizedAddress(transaction.to);
  const input = transaction.input || "0x";
  const core = normalizedAddress(addresses.core);
  const skills = normalizedAddress(addresses.skills);
  const settlement = normalizedAddress(addresses.settlement);
  const usdc = normalizedAddress(addresses.usdc);

  if (destination === core) {
    return decodeCoreTransaction(input, transaction.value || 0n);
  }
  if (destination === skills) {
    return decodeSkillsTransaction(input);
  }
  if (destination === settlement) {
    return decodeSettlementTransaction(input);
  }
  if (destination === usdc) {
    return decodeUsdcTransaction(input, { core, skills });
  }
  throw new Error("Transaction destination is not an Easy Games contract");
}

function decodeCoreTransaction(input, value) {
  const decoded = decodeFunctionData({ abi: CORE_TRANSACTION_ABI, data: input });
  if (decoded.functionName === "activateRound" || decoded.functionName === "activateRoundWithUSDC") {
    const config = decoded.args[0];
    const paysWithUsdc = decoded.functionName === "activateRoundWithUSDC";
    const amount = paysWithUsdc ? config.usdcPrice : value;
    return {
      operation: paysWithUsdc ? "activateRoundUSDC" : "activateRound",
      roundId: config.roundId.toString(),
      level: Number(config.level),
      amount: paysWithUsdc ? formatUnits(amount, 6) : formatEther(amount),
      currency: paysWithUsdc ? "USDC" : "ETH",
    };
  }
  if (decoded.functionName === "claimReferralBonus") {
    return operation("claimReferralBonus", "ETH");
  }
  if (decoded.functionName === "claimReferralBonusUSDC") {
    return operation("claimReferralBonus", "USDC");
  }
  throw new Error("Unsupported Easy Games core operation");
}

function decodeSkillsTransaction(input) {
  const decoded = decodeFunctionData({
    abi: ARENA_SKILLS_TRANSACTION_ABI,
    data: input,
  });
  const roundId = decoded.args[0].toString();
  if (decoded.functionName === "buyFreezeToken") {
    return operation("buyFreezeToken", "USDC", roundId);
  }
  if (decoded.functionName === "freezePlayer") {
    return {
      ...operation("freezePlayer", "FREEZE_TOKEN", roundId),
      target: decoded.args[1].toLowerCase(),
    };
  }
  if (decoded.functionName === "buyUnfreeze") {
    return operation("buyUnfreeze", "USDC", roundId);
  }
  throw new Error("Unsupported arena skill operation");
}

function decodeSettlementTransaction(input) {
  const decoded = decodeFunctionData({
    abi: SETTLEMENT_TRANSACTION_ABI,
    data: input,
  });
  if (decoded.functionName === "claimPrize") {
    return operation("claimPrize", "MIXED");
  }
  throw new Error("Unsupported settlement operation");
}

function decodeUsdcTransaction(input, allowedSpenders) {
  const decoded = decodeFunctionData({ abi: USDC_TRANSACTION_ABI, data: input });
  const spender = normalizedAddress(decoded.args[0]);
  if (decoded.functionName !== "approve" ||
      (spender !== allowedSpenders.core && spender !== allowedSpenders.skills)) {
    throw new Error("USDC approval is not for an Easy Games contract");
  }
  return {
    operation: "approveUSDC",
    roundId: "",
    level: null,
    amount: formatUnits(decoded.args[1], 6),
    currency: "USDC",
    target: spender,
  };
}

function operation(name, currency, roundId = "") {
  return {
    operation: name,
    roundId,
    level: null,
    amount: "",
    currency,
  };
}

module.exports = {
  decodeTrackedTransaction,
  normalizedAddress,
};
