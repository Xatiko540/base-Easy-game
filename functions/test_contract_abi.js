const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const {
  CORE_LINK_ABI,
  ROUND_MANAGER_LINK_ABI,
  ARENA_SKILLS_LINK_ABI,
  SETTLEMENT_LINK_ABI,
} = require("./game_abi");

const artifactRoot = path.join(__dirname, "..", "src", "artifacts");

function artifactFunctions(fileName) {
  const artifact = JSON.parse(
    fs.readFileSync(path.join(artifactRoot, fileName), "utf8"),
  );
  return new Set(
    artifact.abi
      .filter((entry) => entry.type === "function")
      .map((entry) => entry.name),
  );
}

function declaredFunctions(abi) {
  return abi.map((signature) => {
    const match = /^function\s+([^\s(]+)/.exec(signature);
    assert(match, `Invalid ABI signature: ${signature}`);
    return match[1];
  });
}

function assertAbiMatchesArtifact(label, abi, artifactName) {
  const available = artifactFunctions(artifactName);
  for (const functionName of declaredFunctions(abi)) {
    assert(
      available.has(functionName),
      `${label}.${functionName} is missing from ${artifactName}`,
    );
  }
}

assertAbiMatchesArtifact(
  "core",
  CORE_LINK_ABI,
  "EasyGameAdvance.json",
);
assertAbiMatchesArtifact(
  "roundManager",
  ROUND_MANAGER_LINK_ABI,
  "EasyGameRoundManager.json",
);
assertAbiMatchesArtifact(
  "arenaSkills",
  ARENA_SKILLS_LINK_ABI,
  "EasyGameArenaSkills.json",
);
assertAbiMatchesArtifact(
  "settlement",
  SETTLEMENT_LINK_ABI,
  "EasyGameRoundSettlement.json",
);
const functionsSource = fs.readFileSync(path.join(__dirname, "index.js"), "utf8");
const forbiddenLegacySymbols = [
  "getPlayerLevelFull",
  "getPlayerTokenRewards",
  "getLevelStatsUSDC",
  "levelPricesUsdc",
  "exports.syncLevel",
  "exports.syncAllLevels",
];

for (const symbol of forbiddenLegacySymbols) {
  assert(
    !functionsSource.includes(symbol),
    `Legacy Functions symbol is still present: ${symbol}`,
  );
}

console.log("Current contract ABI compatibility checks passed.");
