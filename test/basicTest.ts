import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
import { randomHex, toHex } from "./utils/encoding";
import { faucet } from "./utils/faucet";
import {
  mainCollectionIdGenerator,
  subCollectionIdGenerator,
} from "./utils/idGenerate";

require("dotenv").config();

import type { AssetContractShared } from "../typechain-types";
describe("ArverseCollection", function () {
  let arverseCollection: AssetContractShared;
  const { provider } = ethers;
  const owner = new ethers.Wallet(randomHex(32), provider);
  const creator = new ethers.Wallet(randomHex(32), provider);
  const seller = new ethers.Wallet(randomHex(32), provider);
  const buyer = new ethers.Wallet(randomHex(32), provider);

  before(async () => {
    await faucet(owner.address, provider);
  });

  async function deployArverseCollection() {
    // Contracts are deployed using the first signer/account by default

    const ArverseCollection = await ethers.getContractFactory(
      "AssetContractShared",
      owner
    );
    arverseCollection = await ArverseCollection.deploy(
      "Arverse Collections",
      "ARV",
      ethers.constants.AddressZero,
      ""
    );
  }

  describe("Deployment", function () {
    it("deploy AverseCollection", async function () {
      await deployArverseCollection();
    });
  });

  describe("contract initilization", function () {
    it("Owner is the creator of contract", async function () {
      const arverseCollectionOwner = await arverseCollection.owner();
      expect(arverseCollectionOwner).to.equal(owner.address);
    });
  });

  describe("mint", function () {
    it("mint a single token", async function () {
      const data = ethers.utils.defaultAbiCoder.encode(
        ["uint256", "uint256", "bytes"],
        [
          mainCollectionIdGenerator(creator, 1),
          subCollectionIdGenerator(creator, 0, 1),
          ethers.utils.toUtf8Bytes("hello arverse"),
        ]
      );
      await arverseCollection.mint(buyer.address, tokenId, 1, data);
    });
  });
});
