import type { Wallet, BigNumber } from "ethers";
import { hex2bin, toBN, toHex } from "./encoding";
import { BigNumber as BigNumberJs } from "bignumber.js";

// export const mainCollectionIdGenerator = (creator: Wallet, index: number) => {
//     let temp =
//     BigInt(creator.address).toString(2).padStart(160,'0')+
//     BigInt(index.toString()).toString(2).padStart(96,'0')

//     return BigInt('0b' + temp).toString(10)
// };

// export const subCollectionIdGenerator = (
//   creator: Wallet,
//   workTypeIndex: 0 | 1,
//   index: number
// ) => {
//   let temp =
//   BigInt(creator.address).toString(2).padStart(160,'0')+
//   BigInt(workTypeIndex.toString(),).toString(2).padStart(1,'0') +
//   BigInt(index.toString()).toString(2).padStart(95,'0')

//   return BigInt('0b' + temp).toString(10)

// };

// export const tokenIdGenerator = (
//   creator: Wallet,
//   mainCollectionIndex: number,
//   subCollectionIndex: number,
//   isSeries: boolean,
//   episodeIndex: number | null,
//   pageIndex: number | null,
//   categoryIndex: number | null,
//   supply: number
// ) => {
//   let temp =
//   BigInt(creator.address).toString(2).padStart(160,'0')+
//   BigInt(mainCollectionIndex).toString(2).padStart(10,'0')+
//   BigInt(subCollectionIndex).toString(2).padStart(10,'0')

//   if (isSeries) {
//     if (episodeIndex && pageIndex) {
//       temp +=
//       BigInt(episodeIndex).toString(2).padStart(18,'0')+
//       BigInt(pageIndex).toString(2).padStart(18,'0')

//     } else {
//       throw "if isSeries, should provide episodeIndex and pageIndex";
//     }
//   } else {
//     if (categoryIndex) {
//         temp +=
//         BigInt(categoryIndex).toString(2).padStart(36,'0')
//     } else {
//       throw "if not isSeries, should provide categoryIndex";
//     }
//   }

//   temp +=   BigInt(supply).toString(2).padStart(40,'0')

//   return BigInt('0b' + temp).toString(10)
// };

export const tokenIdGenerator = (
  creator: Wallet,
  categoryIndex: number,
  supply: number
) => {
  let temp = BigInt(creator.address).toString(2).padStart(160, "0");

  temp += BigInt(categoryIndex).toString(2).padStart(56, "0");
  temp += BigInt(supply).toString(2).padStart(40, "0");

  return BigInt("0b" + temp).toString(10);
};
