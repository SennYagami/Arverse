import { ethers } from "hardhat";
import type { ArverseCollection ,AccessPermission,SharedStorefrontLazyMintAdapter} from "../../typechain-types";
import type { Wallet } from "ethers";



export async function arverseFixture(owner:Wallet,seaport:Wallet) {
    let arverseCollection: ArverseCollection;
    let accessPermission: AccessPermission;
    let sharedStorefrontLazyMintAdapter: SharedStorefrontLazyMintAdapter;

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

    
    const AccessPermission = await ethers.getContractFactory(
        "AccessPermission",
        owner
      );
      accessPermission = await AccessPermission.deploy(
        ethers.constants.AddressZero,
      );

    const SharedStorefrontLazyMintAdapter = await ethers.getContractFactory(
        "SharedStorefrontLazyMintAdapter",
        owner
      );
      sharedStorefrontLazyMintAdapter = await SharedStorefrontLazyMintAdapter.deploy(
        ethers.constants.AddressZero,
        arverseCollection.address,
        seaport.address,
      );

      return {arverseCollection,accessPermission,sharedStorefrontLazyMintAdapter}
  }