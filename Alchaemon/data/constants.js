const alchemyApiKey = "2WOLLz-r47vJy7g_ie9ohs2QliXmYh3X";
const ownerAddress = "0x15FCf80d3ee270455d596c93bb37B4f1E1Aa15F7";
const contractAddress = "0x21a5550016994d91450e7e83b34d0300d4eccca5";

/*
Getnftmetadata
Getcontractsforowner
Getnftsforcollection
getnftsforowner - done
*/
export const networks = {
    sepolia: {
      chainId: '11155111', // Sepolia's chain ID
      rpcUrl: `https://eth-sepolia.g.alchemy.com/v2/${alchemyApiKey}`,
    },
  };

export { alchemyApiKey, ownerAddress, contractAddress }