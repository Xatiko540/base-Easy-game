require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config(); // Загружаем переменные окружения из .env

const MNEMONIC = process.env.MNEMONIC || "order reduce decorate family nature heavy ethics useless error clever key want";
const BASE_SEPOLIA_API_KEY = process.env.BASE_SEPOLIA_API_KEY || "7WXKWG7BHJW9D9SZEVAJT6MD8X8T752PAE";

module.exports = {
  solidity: "0.8.16", // Указываем используемую версию компилятора Solidity
  networks: {
    baseSepolia: {
      url: `https://base-sepolia.blockapi.com/v1/${BASE_SEPOLIA_API_KEY}`, // Указываем URL API для Base Sepolia
      accounts: { mnemonic: MNEMONIC }, // Генерация аккаунтов с использованием мнемонической фразы
      chainId: 11155111, // Указываем идентификатор сети Base Sepolia
    },
  },
  etherscan: {
    apiKey: BASE_SEPOLIA_API_KEY, // Для проверки контракта
  },
  paths: {
    sources: "./contracts", // Папка с контрактами
    tests: "./test", // Папка с тестами
    cache: "./cache", // Папка с кэшем
    artifacts: "./artifacts", // Папка для артефактов
  },
};