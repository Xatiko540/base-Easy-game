require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config(); // Загружаем переменные окружения из .env

const MNEMONIC = process.env.MNEMONIC;
const BASE_RPC_URL = process.env.BASE_RPC_URL || "https://mainnet.base.org";
const BASE_SEPOLIA_RPC_URL = process.env.BASE_SEPOLIA_RPC_URL || "";
const BASESCAN_API_KEY = process.env.BASESCAN_API_KEY || "";

module.exports = {
  solidity: {
    version: "0.8.24",
    settings: {
      viaIR: true,
      optimizer: {
        enabled: true,
        // Deployment size is the limiting factor for the round-aware core.
        // A low run count keeps the implementation below EIP-170 on Base.
        runs: 1,
      },
    },
  },
  networks: {
    base: {
      url: BASE_RPC_URL,
      accounts: MNEMONIC ? { mnemonic: MNEMONIC } : [],
      chainId: 8453,
    },
    baseSepolia: {
      url: BASE_SEPOLIA_RPC_URL,
      accounts: MNEMONIC ? { mnemonic: MNEMONIC } : [],
      chainId: 84532,
    },
    // Local Ganache for development/testing
    localhost: {
      url: process.env.LOCALHOST_RPC_URL || "http://127.0.0.1:7545",
      chainId: Number(process.env.LOCAL_CHAIN_ID) || 1337,
    },
    hardhatNode: {
      url: "http://127.0.0.1:8545",
      chainId: 31337,
    },
  },
  etherscan: {
    apiKey: {
      base: BASESCAN_API_KEY,
      baseSepolia: BASESCAN_API_KEY,
    },
  },
  paths: {
    sources: "./contracts", // Папка с контрактами
    tests: "./test", // Папка с тестами
    cache: "./cache", // Папка с кэшем
    artifacts: "./artifacts", // Папка для артефактов
  },
};
