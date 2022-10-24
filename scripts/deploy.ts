import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const ArverseCollection = await ethers.getContractFactory(
    "ArverseCollection"
  );

  const arverseCollection = await ArverseCollection.deploy(
    "Arverse Collections",
    "ARV",
    ethers.constants.AddressZero,
    ""
  );

  const SharedStorefrontLazyMintAdapter = await ethers.getContractFactory(
    "SharedStorefrontLazyMintAdapter"
  );

  const sharedStorefrontLazyMintAdapter =
    await SharedStorefrontLazyMintAdapter.deploy(
      ethers.constants.AddressZero,
      arverseCollection.address,
      "0x00000000006c3852cbEf3e08E8dF289169EdE581"
    );

  const AccessPermission = await ethers.getContractFactory("AccessPermission");

  const accessPermission = await AccessPermission.deploy(
    ethers.constants.AddressZero
  );

  const tx = await arverseCollection.deployed();

  console.log("ArverseCollection address", arverseCollection.address);
  console.log(
    "SharedStorefrontLazyMintAdapter address",
    sharedStorefrontLazyMintAdapter.address
  );
  console.log("AccessPermission address", accessPermission.address);
  //   console.log(tx);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
