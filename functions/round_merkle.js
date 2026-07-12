const { AbiCoder, concat, keccak256 } = require("ethers");

function winningCellLeaf(roundId, cellId) {
  return keccak256(
    AbiCoder.defaultAbiCoder().encode(
      ["uint256", "uint256"],
      [roundId, cellId]
    )
  );
}

function buildWinningCellTree(roundId, cells) {
  if (!Array.isArray(cells) || cells.length === 0) {
    throw new Error("At least one winning cell is required");
  }
  const leaves = cells.map((cellId) => winningCellLeaf(roundId, cellId));
  const levels = [leaves];
  while (levels.at(-1).length > 1) {
    const current = levels.at(-1);
    const next = [];
    for (let index = 0; index < current.length; index += 2) {
      if (index + 1 === current.length) next.push(current[index]);
      else next.push(keccak256(concat([current[index], current[index + 1]].sort())));
    }
    levels.push(next);
  }
  const proofs = leaves.map((_, leafIndex) => {
    const proof = [];
    let index = leafIndex;
    for (let level = 0; level < levels.length - 1; level++) {
      const sibling = index ^ 1;
      if (sibling < levels[level].length) proof.push(levels[level][sibling]);
      index = Math.floor(index / 2);
    }
    return proof;
  });
  return { root: levels.at(-1)[0], proofs };
}

module.exports = { buildWinningCellTree, winningCellLeaf };
