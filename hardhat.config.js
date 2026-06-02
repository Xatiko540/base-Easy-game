require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config(); // Загружаем переменные окружения из .env

const MNEMONIC = process.env.MNEMONIC;
const BASE_SEPOLIA_RPC_URL = process.env.BASE_SEPOLIA_RPC_URL || "";
const BASESCAN_API_KEY = process.env.BASESCAN_API_KEY || "";

module.exports = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
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
  },
  etherscan: {
    apiKey: {
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
