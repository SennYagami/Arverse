import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
require("dotenv").config();

const config: HardhatUserConfig = {
  solidity: {
    // settings: { optimizer: { enabled: true, runs: 200 } },
    compilers: [
      {
        version: "0.8.14",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000000,
          },
        },
      },
    ],
  },
  networks: {
    hardhat: {},
    goerli: {
      url: `https://eth-goerli.g.alchemy.com/v2/Zf0Pex_0WB4BkhBQCA14wnt4u6PAi6UF`,
      accounts: [process.env.PRIVATE_KEY as any],
    },
  },
  gasReporter: {
    outputFile: "gas-report.txt",
    enabled: true,
    currency: "USD",
    noColors: true,
    coinmarketcap: process.env.COIN_MARKETCAP_API_KEY || "",
    token: "ETH",
  },
};
export default config;
