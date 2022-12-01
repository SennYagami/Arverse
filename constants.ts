export const seaportAddress = "0x00000000006c3852cbef3e08e8df289169ede581";
export const chainIdDict = { goerli: 5, ethereum: 1 };
export const domainSeparatorDict = {
  goerli: "0x712fdde1f147adcbb0fabb1aeb9c2d317530a46d266db095bc40c606fe94f0c2",
  ethereum: "0xb50c8913581289bd2e066aeef89fceb9615d490d673131fd1a7047436706834e",
};

export const ArverseCollectionAddress = {
  goerli: "0x7E729DFEBCDeA00b6A9F2fE5a706EE822AC0f8f3",
  ethereum: "",
};

export const SsfLazyMintAdapterAddress = {
  goerli: "0x57049f5aDA35FeDD72396dEb6537cCcFa229f25D",
  ethereum: "",
};

export const AccessPermissionAddress = {
  goerli: "0xf5371fa4fe04652539e003908ABCE922dF5017f3",
  ethereum: "",
};

export const orderType = {
  OrderComponents: [
    { name: "offerer", type: "address" },
    { name: "zone", type: "address" },
    { name: "offer", type: "OfferItem[]" },
    { name: "consideration", type: "ConsiderationItem[]" },
    { name: "orderType", type: "uint8" },
    { name: "startTime", type: "uint256" },
    { name: "endTime", type: "uint256" },
    { name: "zoneHash", type: "bytes32" },
    { name: "salt", type: "uint256" },
    { name: "conduitKey", type: "bytes32" },
    { name: "counter", type: "uint256" },
  ],
  OfferItem: [
    { name: "itemType", type: "uint8" },
    { name: "token", type: "address" },
    { name: "identifierOrCriteria", type: "uint256" },
    { name: "startAmount", type: "uint256" },
    { name: "endAmount", type: "uint256" },
  ],
  ConsiderationItem: [
    { name: "itemType", type: "uint8" },
    { name: "token", type: "address" },
    { name: "identifierOrCriteria", type: "uint256" },
    { name: "startAmount", type: "uint256" },
    { name: "endAmount", type: "uint256" },
    { name: "recipient", type: "address" },
  ],
};
