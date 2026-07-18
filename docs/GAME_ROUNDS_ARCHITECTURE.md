# Easy Games: Season and Matrix Round Architecture

Status: design only. This document does not authorize the current contract to
run timed rounds. Runtime implementation starts only after the rules below are
accepted and covered by tests.

## 1. Sources of truth

- Solidity owns payments, round state, matrix positions, winners, freezes,
  rewards, claims, and project fees.
- Firebase prepares future season manifests, level schedules, winning cells,
  translations, and fast read models for the UI.
- A Firebase value is not trusted by Solidity until its Merkle proof is
  verified against a season root committed on-chain before the season starts.
- Flutter and GetX display state. Client timers never open, close, or settle a
  round.

## 2. Season manifest

Firebase creates one immutable manifest per season:

```text
seasonId
chainId
contractAddress
startsAt
endsAt
levels[1..17]
rounds[]
configRoot
schemaVersion
```

Every round leaf includes at least:

```text
seasonId, roundId, level
startsAt, entriesCloseAt, endsAt
ETH price, USDC price
matrixDepth, maxPlayers, maxWinners
winningCellsRoot
freezeLimit, freezeClosesAt
payment split version
```

The leaf also includes `block.chainid` and `address(this)` to prevent replay on
another network or contract.

## 3. On-chain round model

```solidity
enum RoundPhase {
    Uninitialized,
    Scheduled,
    Open,
    Locked,
    SettlementReady,
    Settled,
    Cancelled
}

struct RoundState {
    bytes32 configHash;
    bytes32 winningCellsRoot;
    uint64 startsAt;
    uint64 entriesCloseAt;
    uint64 endsAt;
    uint32 occupiedCells;
    uint16 winnerCount;
    bool initialized;
    bool settled;
    uint256 prizePoolEth;
    uint256 prizePoolUsdc;
}
```

Round configuration is initialized lazily by the first valid entry. The player
submits the Firebase manifest leaf and Merkle proof. Solidity verifies the
proof, stores only the minimum state required for execution, and continues the
normal activation in the same transaction.

## 4. Authoritative timer

`block.timestamp` is the only authoritative clock:

```text
now < startsAt
  Scheduled: reads allowed, entry rejected

startsAt <= now < entriesCloseAt
  Open: entry, boost, shield, and permitted freeze actions

entriesCloseAt <= now < endsAt
  Locked: no new entry; final matrix actions resolve

now >= endsAt and !settled
  SettlementReady: any caller can settle

settled
  Settled: claims available; state immutable
```

No scheduler is required for correctness. Firebase notifications may announce
phase changes, but a notification cannot change contract state.

## 5. Level schedule

All 17 levels belong to the same season manifest and may have different opening
times and round durations. Solidity accepts an activation only when:

```solidity
block.timestamp >= startsAt && block.timestamp < entriesCloseAt
```

The current `levelAvailable` owner switch becomes an emergency pause only. It
must not be the normal scheduling mechanism.

Adjacent levels in one season open at least five hours apart. Their durations
may differ. A player's first purchase may be any open level; every later
purchase must be exactly `highestLevel + 1`. Each activated level grants four
slots for unique direct partners. Filling those slots does not modify existing
entries, but another unique direct partner cannot register until the inviter
buys the next level.

## 6. Winning cells

Firebase selects winning cells before the season root is committed. The full
list remains in Firebase; Solidity stores only `winningCellsRoot`.

When an occupied cell is claimed as winning, Solidity verifies:

```text
MerkleProof(roundId, level, cellId)
cell exists
cell owner is recorded on-chain
cell was not registered before
round config matches the committed season root
```

Registration always credits the on-chain cell owner, not `msg.sender`. This
allows any account to submit a proof without stealing the prize.

The MVP has at most eight winning cells per round. This bounds settlement gas.
If no winning cell is occupied, the prize allocation rolls into the next round.
The unsafe block-derived weighted draw remains disabled. A future random
fallback requires verifiable randomness such as Chainlink VRF.

## 7. Settlement

Contracts do not execute automatically. Settlement is lazy and permissionless:

- the first activation in the next round may settle the previous round;
- a winner may settle while claiming;
- any account may call `settleRound`;
- a Paymaster may sponsor that transaction.

Settlement must perform bounded work only. It may iterate over the fixed winner
list, but never over every matrix participant.

If there are multiple eligible winners, the distributable round prize is split
equally. A frozen winner receives `pendingPrize`; an active winner receives
`claimablePrize`.

## 8. Freeze, shield, and unfreeze rules

Arena freeze and unfreeze are implemented in `EasyGameArenaSkills`:

- Freeze is available after entry and through the configured game window.
- A freeze action costs 0.30 USDC plus gas.
- Unfreeze costs `max(1 USDC, 7% of the player's current expected prize)`.
- The maximum successful freezes against one player is
  `ceil(roundDuration / 24 hours) * 10`.
- After surviving the limit, the player is immune for the rest of that round.
- Freeze never deletes a position, weight, ticket, or earned reward.
- A real Arena freeze on the player's highest purchased level blocks the next
  level purchase. It does not freeze or rewrite previously purchased levels.

Pricing and limits must be committed in the round leaf so Firebase cannot alter
them during a live round.

## 9. Payment and accounting invariants

Every activation keeps the current split:

```text
75.5% matrix prize pool
 9.5% direct referral
 6.0% second-line referral
 4.0% third-line referral
 5.0% project fee
```

Missing referral lines return to the matrix prize pool. At all times and for
each token:

```text
contract balance
  == matrix pools
   + project fees accrued
   + claimable referral bonuses
   + claimable prizes
   + pending prizes
```

Only `projectFeesAccrued` may be withdrawn by the owner. Player and pool funds
are never owner-withdrawable.

## 10. GetX state model

```text
GameScheduleService
  Firebase manifest, Merkle proofs, cached schedule

BlockchainGameService
  block timestamp, round state, matrix, balances, receipts

GameRoundsController
  selected level, derived phase, countdown, transaction status
```

The controller periodically updates display text, but before every action it
refreshes the latest block and contract state. Refreshing or closing the app
cannot extend or finish a round.

## 11. Implementation order

1. Approve manifest schema, timing boundaries, winner split, and freeze rules.
2. Add pure hashing and Merkle verification tests.
3. Add Season and Round storage without connecting Flutter.
4. Add lazy round initialization and phase validation.
5. Add winning-cell registration and bounded settlement.
6. Add freeze resources and economic invariant tests.
7. Add Firebase manifest builder and locked-down Firestore rules.
8. Add GetX services and replace all fake UI timers.
9. Run Ganache stress tests, then Base Sepolia deployment and verification.

## 12. Contract boundary after the EIP-712 prototype

The EIP-712 round prototype proved the schedule rules, but also raised the
`EasyGameAdvance` runtime size to 22,224 bytes. The EIP-170 limit is 24,576
bytes, leaving only 2,352 bytes for settlement, round-scoped matrices, freeze,
shield, and proof verification. Production implementation must therefore use
two contracts:

```text
EasyGameRoundManager
  signed manifests, round phases, winning roots, pause/cancel, settlement

EasyGameAdvance
  payments, referrals, player balances, matrix placement, claims
```

`EasyGameAdvance` stores the trusted manager address and asks it to validate a
round before accepting an entry. The manager never holds player funds. This
keeps payment accounting in one contract and prevents schedule functionality
from pushing the game core past the deployment size limit.
