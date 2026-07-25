const fs = require("node:fs");
const path = require("node:path");
const hre = require("hardhat");

const { buildSignedSeasonManifest } = require("../functions/season_manifest_builder");
const { parseSeasonManifest } = require("../functions/round_season_manifest");

function requiredPath(name) {
  const value = String(process.env[name] || "").trim();
  if (!value) throw new Error(`${name} is required`);
  return path.resolve(value);
}

function managerAddress(chainId) {
  const configured = String(process.env.EASY_GAME_ROUND_MANAGER_ADDRESS || "").trim();
  if (configured && hre.ethers.isAddress(configured)) {
    return hre.ethers.getAddress(configured);
  }
  const artifact = require("../src/artifacts/EasyGameRoundManager.json");
  const deployed = artifact.networks?.[String(chainId)]?.address;
  if (!deployed || !hre.ethers.isAddress(deployed)) {
    throw new Error(
      `No EasyGameRoundManager address for chain ${chainId}; set ` +
        "EASY_GAME_ROUND_MANAGER_ADDRESS",
    );
  }
  return hre.ethers.getAddress(deployed);
}

function scheduleSigner(provider, chainId) {
  let raw = String(process.env.SCHEDULE_SIGNER_PRIVATE_KEY || "").trim();
  if (
    !raw &&
    chainId === 84532 &&
    process.env.ALLOW_TESTNET_DEPLOYER_AS_SCHEDULE_SIGNER === "true"
  ) {
    raw = String(process.env.DEPLOYER_PRIVATE_KEY || "").trim();
  }
  const normalized = raw.startsWith("0x") ? raw : `0x${raw}`;
  if (!/^0x[0-9a-fA-F]{64}$/.test(normalized)) {
    throw new Error("SCHEDULE_SIGNER_PRIVATE_KEY must contain exactly 32 bytes");
  }
  return new hre.ethers.Wallet(normalized, provider);
}

function rejectSecrets(value, location = "spec") {
  if (typeof value === "string" && /^0x[0-9a-fA-F]{64}$/.test(value)) {
    throw new Error(`32-byte hex value ${location} is forbidden in season specs`);
  }
  if (Array.isArray(value)) {
    value.forEach((entry, index) => rejectSecrets(entry, `${location}[${index}]`));
    return;
  }
  if (!value || typeof value !== "object") return;
  for (const [key, entry] of Object.entries(value)) {
    if (/(private.?key|mnemonic|secret|seed.?phrase)/i.test(key)) {
      throw new Error(`Secret-like field ${location}.${key} is forbidden in season specs`);
    }
    rejectSecrets(entry, `${location}.${key}`);
  }
}

async function main() {
  const network = await hre.ethers.provider.getNetwork();
  const chainId = Number(network.chainId);
  if (![8453, 84532].includes(chainId) && process.env.ALLOW_LOCAL_SEASON_GENERATION !== "true") {
    throw new Error(`Refusing production season generation on chain ${chainId}`);
  }

  const specPath = requiredPath("SEASON_SPEC_PATH");
  const outputPath = requiredPath("SEASON_MANIFEST_PATH");
  if (fs.existsSync(outputPath) && process.env.SEASON_OVERWRITE !== "true") {
    throw new Error(
      `${outputPath} already exists; choose a new path or set SEASON_OVERWRITE=true`,
    );
  }
  const spec = JSON.parse(fs.readFileSync(specPath, "utf8"));
  rejectSecrets(spec);

  const address = managerAddress(chainId);
  const signer = scheduleSigner(hre.ethers.provider, chainId);
  const expectedSigner = String(process.env.SCHEDULE_SIGNER_ADDRESS || "").trim();
  if (
    !expectedSigner ||
    !hre.ethers.isAddress(expectedSigner) ||
    hre.ethers.getAddress(expectedSigner) !== signer.address
  ) {
    throw new Error("Schedule signer does not match SCHEDULE_SIGNER_ADDRESS");
  }

  const manager = await hre.ethers.getContractAt("EasyGameRoundManager", address);
  const onChainSigner = await manager.scheduleSigner();
  if (hre.ethers.getAddress(onChainSigner) !== signer.address) {
    throw new Error("Schedule signer does not match EasyGameRoundManager.scheduleSigner()");
  }
  if (!(await manager.allowedScheduleSigners(signer.address))) {
    throw new Error("Schedule signer is not allowed by EasyGameRoundManager");
  }

  const payload = await buildSignedSeasonManifest(spec, {
    chainId,
    managerAddress: address,
    signer,
  });
  const parsed = parseSeasonManifest(payload, {
    chainId,
    managerAddress: address,
    signerAddress: signer.address,
  });
  for (const round of parsed.rounds) {
    if (!(await manager.verifyRoundConfig(round.config, round.signature))) {
      throw new Error(`EasyGameRoundManager rejected level ${round.config.level}`);
    }
  }

  const serialized = `${JSON.stringify(payload, null, 2)}\n`;
  const temporaryPath = `${outputPath}.tmp-${process.pid}`;
  fs.mkdirSync(path.dirname(outputPath), { recursive: true });
  fs.writeFileSync(temporaryPath, serialized, { encoding: "utf8", mode: 0o600, flag: "wx" });
  fs.renameSync(temporaryPath, outputPath);
  fs.chmodSync(outputPath, 0o600);

  console.log("Signed season manifest generated");
  console.log(`Chain ID: ${chainId}`);
  console.log(`Round manager: ${address}`);
  console.log(`Schedule signer: ${signer.address}`);
  console.log(`Season ID: ${parsed.seasonId}`);
  console.log(`Config root: ${parsed.configRoot}`);
  console.log(`Rounds: ${parsed.rounds.length}`);
  console.log(`Output: ${outputPath}`);
}

main().catch((error) => {
  console.error(error.message || error);
  process.exitCode = 1;
});
