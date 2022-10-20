import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const AssetContractShared = await ethers.getContractFactory(
    "AssetContractShared"
  );

  const assetContractShared = await AssetContractShared.deploy(
    "Arverse Collections",
    "ARV",
    ethers.constants.AddressZero,
    "",
    { value: ethers.utils.parseEther("1") }
  );

  const tx = await assetContractShared.deployed();

  console.log(assetContractShared.address);
  //   console.log(tx);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
