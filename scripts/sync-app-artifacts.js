const fs = require("fs");
const path = require("path");

const contracts = [
  "EasyGame",
  "EasyGameAdvance",
  "EasyGameRoundManager",
  "EasyGameArenaSkills",
  "EasyGameRoundSettlement",
  "EasyGameBasePayGateway",
  "Lottery",
  "LotteryGenerator",
  "Migrations",
];

for (const contractName of contracts) {
  const hardhatArtifactPath = path.join(
    __dirname,
    "..",
    "artifacts",
    "contracts",
    contractName === "Lottery" || contractName === "LotteryGenerator"
      ? "Lottery_Advance.sol"
      : `${contractName}.sol`,
    `${contractName}.json`
  );
  const appArtifactPath = path.join(
    __dirname,
    "..",
    "src",
    "artifacts",
    `${contractName}.json`
  );

  if (!fs.existsSync(hardhatArtifactPath)) {
    continue;
  }

  const hardhatArtifact = JSON.parse(fs.readFileSync(hardhatArtifactPath, "utf8"));
  const existingArtifact = fs.existsSync(appArtifactPath)
    ? JSON.parse(fs.readFileSync(appArtifactPath, "utf8"))
    : {};

  fs.writeFileSync(
    appArtifactPath,
    `${JSON.stringify(
      {
        ...hardhatArtifact,
        networks: existingArtifact.networks || {},
      },
      null,
      2
    )}\n`
  );
}
