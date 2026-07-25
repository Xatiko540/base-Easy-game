const { parseAbi } = require("viem");

// Minimal ABIs used by Functions. Runtime game reads belong to the Flutter
// round services; the backend only verifies deployment links and transactions.
const CORE_LINK_ABI = [
  "function roundManager() view returns (address)",
  "function settlementContract() view returns (address)",
  "function usdcToken() view returns (address)",
  "function systemContractsFinalized() view returns (bool)",
];

const ROUND_MANAGER_LINK_ABI = [
  "function gameCore() view returns (address)",
  "function arenaSkills() view returns (address)",
  "function settlementContract() view returns (address)",
  "function systemContractsFinalized() view returns (bool)",
  "function getSeasonState(uint256 seasonId) view returns (tuple(bytes32 configRoot,uint64 firstStartsAt,uint64 lastEndsAt,bool committed))",
  "function getCommittedRoundHash(uint256 seasonId,uint8 level) view returns (bytes32)",
];

const ARENA_SKILLS_LINK_ABI = [
  "function gameCore() view returns (address)",
  "function roundManager() view returns (address)",
  "function usdcToken() view returns (address)",
];

const SETTLEMENT_LINK_ABI = [
  "function gameCore() view returns (address)",
  "function roundManager() view returns (address)",
  "function arenaSkills() view returns (address)",
  "function usdcToken() view returns (address)",
];

const CORE_RECYCLE_ABI = [
  "function hasPendingRoundRecycles(uint256 roundId) view returns (bool)",
  "function processRoundRecycles(uint256 roundId, uint256 maxSteps) returns (uint256 processed, uint256 remaining)",
  "function roundManager() view returns (address)",
];

const ROUND_CONFIG_STRUCT = "struct RoundConfig { uint256 seasonId; uint256 roundId; uint8 level; uint64 startsAt; uint64 entriesCloseAt; uint64 endsAt; uint64 freezeClosesAt; uint32 maxPlayers; uint16 maxWinners; bytes32 winningCellsRoot; uint256 ethPrice; uint256 usdcPrice; uint16 freezeLimit; uint16 paymentSplitVersion; }";

const CORE_TRANSACTION_ABI = parseAbi([
  ROUND_CONFIG_STRUCT,
  "function activateRound(RoundConfig config, bytes signature, address inviter) payable",
  "function activateRoundWithUSDC(RoundConfig config, bytes signature, address inviter)",
  "function claimReferralBonus()",
  "function claimReferralBonusUSDC()",
]);

const ARENA_SKILLS_TRANSACTION_ABI = parseAbi([
  "function buyFreezeToken(uint256 roundId)",
  "function freezePlayer(uint256 roundId, address target)",
  "function buyUnfreeze(uint256 roundId)",
]);

const SETTLEMENT_TRANSACTION_ABI = parseAbi([
  "function claimPrize()",
]);

const USDC_TRANSACTION_ABI = parseAbi([
  "function approve(address spender, uint256 amount) returns (bool)",
]);

module.exports = {
  CORE_LINK_ABI,
  CORE_RECYCLE_ABI,
  ROUND_MANAGER_LINK_ABI,
  ARENA_SKILLS_LINK_ABI,
  ARENA_SKILLS_TRANSACTION_ABI,
  CORE_TRANSACTION_ABI,
  SETTLEMENT_LINK_ABI,
  SETTLEMENT_TRANSACTION_ABI,
  USDC_TRANSACTION_ABI,
};
