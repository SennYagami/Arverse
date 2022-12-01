import { ethers, network } from "hardhat";
import hre from "hardhat";
import {
  seaportAddress,
  domainSeparatorDict,
  chainIdDict,
  orderType,
  SsfLazyMintAdapterAddress,
} from "../../constants";
const fs = require("fs");
import {
  OrderComponents,
  networkOption,
  OfferItem,
  ConsiderationItem,
  CriteriaResolver,
} from "../../types/type";
import { Wallet, Contract, BigNumber } from "ethers";
import { calculateOrderHash, getItemETH, getItem721 } from "../utils/utils";
import { toBN, toHex, randomHex, toKey } from "../utils/encodings";
import { keccak256, parseEther, recoverAddress } from "ethers/lib/utils";

import { json } from "hardhat/internal/core/params/argumentTypes";

const getOrderHash = async (orderComponents: OrderComponents) => {
  const derivedOrderHash = calculateOrderHash(orderComponents);
  return derivedOrderHash;
};

// Returns signature
const signOrder = async (
  orderComponents: OrderComponents,
  signer: Wallet | Contract,
  network: networkOption,
  marketplaceContract
) => {
  const domainData = {
    name: "Seaport",
    version: "1.1",
    chainId: chainIdDict[network],
    verifyingContract: seaportAddress,
  };

  const signature = await signer._signTypedData(domainData, orderType, orderComponents);

  const orderHash = await calculateOrderHash(orderComponents);

  //   const digest = ethers.utils.keccak256(
  //     `0x1901${domainSeparatorDict[network].slice(2)}${orderHash.slice(2)}`
  //   );
  //   const recoveredAddress = recoverAddress(digest, signature);

  return signature;
};

// sign to list ens
async function list(
  offerer: Wallet | Contract,
  //   zone: undefined | string = undefined,
  offer: OfferItem[],
  consideration: ConsiderationItem[],
  orderType: number,
  criteriaResolvers?: CriteriaResolver[],
  timeFlag?: string | null,
  signer?: Wallet,
  zoneHash = ethers.constants.HashZero,
  conduitKey = ethers.constants.HashZero,
  extraCheap = false,
  network: networkOption = "goerli"
) {
  let seaportAbiRawdata = await fs.readFileSync("./scripts/abi/seaport.json");
  let seaportAbi = JSON.parse(seaportAbiRawdata);

  const marketplaceContract = await ethers.getContractAt(seaportAbi, seaportAddress);

  const counter = await marketplaceContract.getCounter(offerer.address);

  const salt = !extraCheap ? randomHex() : ethers.constants.HashZero;
  const startTime = timeFlag !== "NOT_STARTED" ? 0 : toBN("0xee00000000000000000000000000");
  const endTime = timeFlag !== "EXPIRED" ? toBN("0xff00000000000000000000000000") : 1;

  const orderParameters = {
    offerer: offerer.address,
    zone: ethers.constants.AddressZero,
    offer,
    consideration,
    totalOriginalConsiderationItems: consideration.length,
    orderType,
    zoneHash,
    salt,
    conduitKey,
    startTime,
    endTime,
  };

  const orderComponents = {
    ...orderParameters,
    counter,
  };

  const orderHash = await getOrderHash(orderComponents);

  const { isValidated, isCancelled, totalFilled, totalSize } =
    await marketplaceContract.getOrderStatus(orderHash);

  const orderStatus = {
    isValidated,
    isCancelled,
    totalFilled,
    totalSize,
  };

  const flatSig = await signOrder(orderComponents, offerer, network, marketplaceContract);

  const order = {
    parameters: orderParameters,
    // signature: !extraCheap ? flatSig : convertSignatureToEIP2098(flatSig),
    signature: flatSig,
    numerator: 1, // only used for advanced orders
    denominator: 1, // only used for advanced orders
    extraData: "0x", // only used for advanced orders
  };

  // How much ether (at most) needs to be supplied when fulfilling the order

  const value = offer
    .map((x) =>
      x.itemType === 0 ? (x.endAmount.gt(x.startAmount) ? x.endAmount : x.startAmount) : toBN(0)
    )
    .reduce((a, b) => a.add(b), toBN(0))
    .add(
      consideration
        .map((x) =>
          x.itemType === 0 ? (x.endAmount.gt(x.startAmount) ? x.endAmount : x.startAmount) : toBN(0)
        )
        .reduce((a, b) => a.add(b), toBN(0))
    );

  return {
    order,
    orderHash,
    value,
    orderStatus,
    orderComponents,
  };
}

async function main() {
  const network = "goerli";
  const rawIdentifierOrCriteria =
    "0x8705f166792eed5be37b6573752c19f574cf05ac000000000000ab0000000001";

  const identifierOrCriteria = BigNumber.from(rawIdentifierOrCriteria);

  const [offerer, buyer] = await hre.ethers.getSigners();
  const offer = [getItem721(SsfLazyMintAdapterAddress[network], identifierOrCriteria)];

  const consideration = [getItemETH(parseEther("0.01"), parseEther("0.01"), offerer.address)];

  const { order, orderHash, value, orderStatus, orderComponents } = await list(
    offerer as any,
    offer,
    consideration,
    0
  );

  //   fullfill
  let seaportAbiRawdata = await fs.readFileSync("./scripts/abi/seaport.json");
  let seaportAbi = JSON.parse(seaportAbiRawdata);

  const marketplaceContract = await ethers.getContractAt(seaportAbi, seaportAddress);

  console.log(JSON.stringify(order, null, 2));
  const tx = await marketplaceContract.connect(buyer).fulfillOrder(order, toKey(0), {
    value,
  });

  console.log({ offerer: offerer.address, buyer: buyer.address, buyerBalance: buyer.getBalance() });
  console.log({
    order: JSON.stringify(order, null, 2),
    orderHash,
    value,
    orderStatus,
    orderComponents,
  });
  console.log({ tx });

  const receipt = await tx.wait();

  console.log({ receipt });
}

main();
