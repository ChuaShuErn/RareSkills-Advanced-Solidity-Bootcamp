import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import fs from "fs";

const tree = StandardMerkleTree.load(
  JSON.parse(fs.readFileSync("tree.json", "utf8"))
);

const firstAirdropAwardeeAddress = "0x0000000000000000000000000000000000000001";

for (const [i, v] of tree.entries()) {
  if (v[0] === firstAirdropAwardeeAddress) {
    console.log("Merkle Proof for Address: ", firstAirdropAwardeeAddress);
    console.log(tree.getProof(i));
    console.log("Your index is : ", v[1]);
  }
}
