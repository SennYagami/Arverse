import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
import { randomHex, toHex } from "./utils/encoding";
import { faucet } from "./utils/faucet";
import {
  mainCollectionIdGenerator,
  subCollectionIdGenerator,
  tokenIdGenerator,
} from "./utils/idGenerate";

require("dotenv").config();

import type { ArverseCollection ,AccessPermission} from "../typechain-types";
describe("ArverseCollection", function () {
  let arverseCollection: ArverseCollection;
  let accessPermission: AccessPermission;

  const { provider } = ethers;
  const owner = new ethers.Wallet(randomHex(32), provider);
  const creator = new ethers.Wallet(randomHex(32), provider);
  const seller = new ethers.Wallet(randomHex(32), provider);
  const buyer = new ethers.Wallet(randomHex(32), provider);
  const seaport = new ethers.Wallet(randomHex(32), provider);

  before(async () => {
    await faucet(owner.address, provider);
    await faucet(creator.address, provider);
    await faucet(seller.address, provider);
    await faucet(buyer.address, provider);
    await faucet(seaport.address, provider);

    
  });

  async function deployArverseCollection() {
    // Contracts are deployed using the first signer/account by default

    const ArverseCollection = await ethers.getContractFactory(
      "ArverseCollection",
      owner
    );
    arverseCollection = await ArverseCollection.deploy(
      "Arverse Collections",
      "ARV",
      ethers.constants.AddressZero,
      ""
    );
  }

  async function deployAccessPermission() {
    // Contracts are deployed using the first signer/account by default

    const AccessPermission = await ethers.getContractFactory(
      "AccessPermission",
      owner
    );
    accessPermission = await AccessPermission.deploy(
      ethers.constants.AddressZero,
    );
  }

  describe("Deployment and initialization", function () {
    it("deploy AverseCollection", async function () {
      await deployArverseCollection();
    });

    it("deploy AccessPermission", async function () {
        await deployAccessPermission();
      });
  });

  describe(" contract initilization", function () {
      it("add owner as the SharedProxyAddress", async function () {
          await arverseCollection.connect(owner).addSharedProxyAddress(seaport.address);
          const isSeaportSharedProxyAddresses = await arverseCollection.sharedProxyAddresses(seaport.address)
          expect(isSeaportSharedProxyAddresses).to.equal(true)
      });
      
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
      
      await arverseCollection.connect(seaport).mint(buyer.address, tokenIdGenerator(creator,1,2,true,12,27,null,4000), 1, data);

    //     console.log(mainCollectionIdGenerator(creator,2))
    //     console.log(subCollectionIdGenerator(creator,1,3))
    //   console.log(tokenIdGenerator(creator,1,2,true,12,27,null,1))

    //   console.log(creator.address)
    //   console.log(BigInt(mainCollectionIdGenerator(creator,2)).toString(16).padStart(64,'0'))
    //   console.log(BigInt(subCollectionIdGenerator(creator,1,3)).toString(16).padStart(64,'0'))
    //   console.log(BigInt(tokenIdGenerator(creator,1,2,true,12,27,null,1)).toString(16).padStart(64,'0'))
    });
  });
});
