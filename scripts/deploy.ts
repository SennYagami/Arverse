import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  // deploy arverseCollection
  const ArverseCollection = await ethers.getContractFactory("ArverseCollection");
  const arverseCollection = await ArverseCollection.connect(deployer).deploy(
    "Arverse Collections",
    "ARV",
    ethers.constants.AddressZero,
    ""
  );

  //   deploy ssfLazyMintAdapter
  const SsfLazyMintAdapter = await ethers.getContractFactory("SharedStorefrontLazyMintAdapter");
  const ssfLazyMintAdapter = await SsfLazyMintAdapter.connect(deployer).deploy(
    ethers.constants.AddressZero,
    arverseCollection.address,
    "0x00000000006c3852cbEf3e08E8dF289169EdE581"
  );

  //   deploy accessPermission
  const AccessPermission = await ethers.getContractFactory("AccessPermission");
  const accessPermission = await AccessPermission.connect(deployer).deploy(
    ethers.constants.AddressZero
  );

  //   set ssfLazyMintAdapter as one of the sharedProxy of ssf, so that ssfLazyMintAdapter can transfer ssf's asset
  await arverseCollection.addSharedProxyAddress(ssfLazyMintAdapter.address);

  console.log("ArverseCollection address", arverseCollection.address);
  console.log("SharedStorefrontLazyMintAdapter address", ssfLazyMintAdapter.address);
  console.log("AccessPermission address", accessPermission.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
