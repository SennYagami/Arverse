import type { Wallet, BigNumber } from "ethers";
import { toBN } from "./encoding";

function convertNumber(
  n: number,
  fromBase: number,
  toBase: number,
  padNum: number = 0
) {
  if (fromBase === void 0) {
    fromBase = 10;
  }
  if (toBase === void 0) {
    toBase = 10;
  }
  return parseInt(n.toString(), fromBase)
    .toString(toBase)
    .padStart(padNum, "0");
}

export const mainCollectionIdGenerator = (creator: Wallet, index: number) => {
  const res = toBN(
    creator.address.toString() +
      Array.from({ length: 24 }, (_, i) => 0).join("")
  );

  return res.add(index);
};

export const subCollectionIdGenerator = (
  creator: Wallet,
  workTypeIndex: 0 | 1,
  index: number
) => {
  const res = toBN(
    creator.address.toString() +
      workTypeIndex.toString() +
      Array.from({ length: 23 }, (_, i) => 0).join("")
  );

  return res.add(index);
};

export const tokenIdGenerator = (
  creator: Wallet,
  mainCollectionIndex: number,
  subCollectionIndex: number,
  isSeries: boolean,
  episodeIndex: number | null,
  pageIndex: number | null,
  categoryIndex: number | null,
  supply: number
) => {
  let temp =
    convertNumber(parseInt(creator.address, 16), 10, 2, 160).toString() +
    convertNumber(mainCollectionIndex, 10, 2, 10) +
    convertNumber(subCollectionIndex, 10, 2, 10);

  if (isSeries) {
    if (episodeIndex && pageIndex) {
      temp +=
        convertNumber(episodeIndex, 10, 2, 18) +
        convertNumber(pageIndex, 10, 2, 18);
    } else {
      throw "if isSeries, should provide episodeIndex and pageIndex";
    }
  } else {
    if (categoryIndex) {
      temp += convertNumber(categoryIndex, 10, 2, 36);
    } else {
      throw "if not isSeries, should provide categoryIndex";
    }
  }

  temp += convertNumber(supply, 10, 2, 40);
};
