import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import fs from "fs";

// Compile my list of airdrop awardees, and their airdrop amounts;
// my understanding is that we will have address awardee ,uint256 index
// index will help with BitMap
// this list has been sorted by address in ascending order
// and the index is 0.....N
const airDropDetailsList = [
  ["0x0000000000000000000000000000000000000001", "0"],
  ["0x1111111111111111111111111111111111111111", "1"],
  ["0x2222222222222222222222222222222222222222", "2"],
  ["0x3333333333333333333333333333333333333333", "3"],
  ["0x4444444444444444444444444444444444444444", "4"],
  ["0x5555555555555555555555555555555555555555", "5"],
  ["0x6666666666666666666666666666666666666666", "6"],
  ["0x7777777777777777777777777777777777777777", "7"],
  ["0x8888888888888888888888888888888888888888", "8"],
  ["0x9999999999999999999999999999999999999999", "9"],
];

//This tree is therefore a static tree. We won't be adding anymore awardees. IT IS DONE

const tree = StandardMerkleTree.of(airDropDetailsList, ["address", "uint256"]);

console.log("Merkle Root: ", tree.root);

fs.writeFileSync("tree.json", JSON.stringify(tree.dump(), null, 2));
