const {
  createPublicClient,
  defineChain,
  getAddress: getViemAddress,
  http,
} = require("viem");
const { logger } = require("firebase-functions");
const {
  HttpsError,
  rpcUrl,
  chainIdParam,
} = require("./config");

function walletVerificationClient() {
  const chainId = Number(chainIdParam.value());
  const endpoint = rpcUrl.value();
  const chain = defineChain({
    id: chainId,
    name: chainId === 84532 ? "Base Sepolia" : chainId === 8453 ? "Base" : `Chain ${chainId}`,
    nativeCurrency: { name: "Ether", symbol: "ETH", decimals: 18 },
    rpcUrls: { default: { http: [endpoint] } },
  });
  return createPublicClient({ chain, transport: http(endpoint) });
}

async function verifyWalletSignature(address, message, signature) {
  try {
    return await walletVerificationClient().verifyMessage({
      address: getViemAddress(address),
      message,
      signature,
    });
  } catch (error) {
    logger.warn("Wallet signature verification failed", {
      wallet: address,
      error: String(error?.message || error).slice(0, 300),
    });
    return false;
  }
}

module.exports = {
  walletVerificationClient,
  verifyWalletSignature,
};
