// Minimal ABIs used by the deployment smoke test. Runtime game reads belong to
// the Flutter round services; Functions only verify that the configured
// contracts are deployed and wired to the same core/manager/USDC addresses.
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

module.exports = {
  CORE_LINK_ABI,
  ROUND_MANAGER_LINK_ABI,
  ARENA_SKILLS_LINK_ABI,
  SETTLEMENT_LINK_ABI,
};
