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

import type {
  ArverseCollection,
  AccessPermission,
  SharedStorefrontLazyMintAdapter,
} from "../typechain-types";
import { arverseFixture } from "./utils/fixture";
describe("ArverseCollection", function () {
  let arverseCollection: ArverseCollection;
  let accessPermission: AccessPermission;
  let sharedStorefrontLazyMintAdapter: SharedStorefrontLazyMintAdapter;

  const { provider } = ethers;
  const owner = new ethers.Wallet(randomHex(32), provider);
  const creator = new ethers.Wallet(randomHex(32), provider);
  const seller = new ethers.Wallet(randomHex(32), provider);
  const buyer = new ethers.Wallet(randomHex(32), provider);
  const fan = new ethers.Wallet(randomHex(32), provider);
  const seaport = new ethers.Wallet(randomHex(32), provider);

  before(async () => {
    await faucet(owner.address, provider);
    await faucet(creator.address, provider);
    await faucet(seller.address, provider);
    await faucet(buyer.address, provider);
    await faucet(fan.address, provider);
    await faucet(seaport.address, provider);

    ({ arverseCollection, accessPermission, sharedStorefrontLazyMintAdapter } =
      await arverseFixture(owner,seaport));
  });

  describe("contract initilization", function () {
    it("add SharedStorefrontLazyMintAdapter as one of the SharedProxyAddress of ArverseCollection", async function () {
      await arverseCollection
        .connect(owner)
        .addSharedProxyAddress(sharedStorefrontLazyMintAdapter.address);

      const is_sharedStorefrontLazyMintAdapter_sharedProxyAddress =
        await arverseCollection.sharedProxyAddresses(sharedStorefrontLazyMintAdapter.address);
      expect(is_sharedStorefrontLazyMintAdapter_sharedProxyAddress).to.equal(true);
    });

    it("Owner is the creator of contract", async function () {
      const arverseCollectionOwner = await arverseCollection.owner();
      expect(arverseCollectionOwner).to.equal(owner.address);
    });
  });

  describe("creator mint token", function () {
    it("mint a single token", async function () {
      const data =ethers.utils.toUtf8Bytes("hello arverse");

      await arverseCollection
        .connect(creator)
        .mint(
          fan.address,
          tokenIdGenerator(creator, 1, 2),
          1,
          data
        );

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
