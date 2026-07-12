const assert = require("node:assert/strict");
const { concat, keccak256 } = require("ethers");
const { buildWinningCellTree, winningCellLeaf } = require("./round_merkle");

function verify(proof, root, leaf) {
  return proof.reduce((computed, sibling) => {
    return keccak256(concat([computed, sibling].sort()));
  }, leaf) === root;
}

const roundId = 77n;
const cells = [1n, 3n, 7n, 15n];
const tree = buildWinningCellTree(roundId, cells);
assert.equal(tree.proofs.length, cells.length);
cells.forEach((cellId, index) => {
  assert.equal(
    verify(tree.proofs[index], tree.root, winningCellLeaf(roundId, cellId)),
    true
  );
});
console.log("round Merkle proofs verified");
