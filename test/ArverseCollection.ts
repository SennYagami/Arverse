import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
require("dotenv").config();

describe("ArverseCollection", function () {
  async function deployArverseCollection() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const ArverseCollection = await ethers.getContractFactory(
      "AssetContractShared"
    );
    const arverseCollection = await ArverseCollection.deploy(
      "Arverse Collections",
      "ARV",
      ethers.constants.AddressZero,
      ""
    );

    return { arverseCollection, owner, otherAccount };
  }

  describe("Deployment", function () {
    it("Should set the right unlockTime", async function () {
      const { arverseCollection, owner, otherAccount } = await loadFixture(
        deployArverseCollection
      );
    });
  });
});
