<h1 align="center">Easy Game Advance</h1>

<h2 align="center">
Matrix Probability Arena on Base
</h2>

<h3 align="center">
A Flutter + Solidity Web3 game based on a 17-level weighted binary matrix, transparent payment distribution, recycle mechanics, prize cells, freeze/unfreeze progression, and claimable on-chain rewards.
</h3>

---

## Project concept

Easy Game Advance is a Web3 matrix game built for the Base network.

The project is not a simple lottery and not a fixed one-time ticket system. It is a binary matrix probability arena where each player activates a level, receives a matrix position, gains weight, participates in level prize mechanics, moves through recycle cycles, and can unlock pending rewards through higher-level progression.

The main logic is:

```text
Activate level
→ receive matrix position
→ payment is split by fixed percentages
→ player receives level weight
→ inviter lines receive claimable bonuses and weight
→ matrix fills from left to right
→ parent closes when both child cells are filled
→ closed parent triggers recycle
→ recycle gives a new matrix position and more weight
→ prize cells can create claimable or pending rewards
→ repeated recycle without next level can freeze the level
→ activating the next higher level unfreezes lower frozen levels
→ pending rewards become claimable
```

The system is built around player position, probability weight, prize pool accounting, referral distribution, recycle movement, boxes, freeze/unfreeze state, and transparent project fees.

---

## Current Easy Game Advance logic

The active smart contract is:

```solidity
contracts/EasyGameAdvance.sol
```

The current system has:

- 17 independent levels.
- A predefined native-token price for each level.
- A separate binary matrix for each level.
- A separate prize pool for each level.
- Separate player positions per level.
- Separate player weight per level.
- Separate recycle state per level.
- Separate frozen, pending, and claimable reward state per level.

Players can activate any available level directly. They do not need to activate previous levels first.

The owner can open or close levels for staged launch. The default launch state opens levels 3 through 17 and keeps levels 1 and 2 closed until they are enabled.

---

## User flow

1. Connect wallet with MetaMask, Base Account, or another injected Web3 wallet.
2. Open the Easy Game levels screen.
3. Choose any currently available level.
4. Enter or approve the inviter/upline address.
5. Continue to payment.
6. The app reads the exact level price from the contract through `levelPrices(level)`.
7. The app calls `EasyGameAdvance.activateLevel(level, inviter)` through the connected wallet.
8. The contract validates the payment, places the player into the selected level matrix, splits the payment, updates weights, and records claimable balances.
9. After transaction confirmation, the app returns to the levels screen and refreshes on-chain state.

---

## Binary matrix placement

Each level has its own binary matrix.

New positions are filled from left to right by binary cell id.

Example structure:

```text
Cell 1
├── Cell 2
│   ├── Cell 4
│   └── Cell 5
└── Cell 3
    ├── Cell 6
    └── Cell 7
```

Placement rules:

- The player receives the next available matrix position in the selected level.
- The matrix fills left to right.
- The contract prioritizes the uppermost open parent.
- The left child is filled before the right child.
- When both child slots of a parent are filled, that parent position becomes closed.
- A closed parent can trigger recycle for the player assigned to that parent position.

This makes placement deterministic and readable for UI/indexer logic.

---

## Recycle logic

Recycle is triggered when both child cells under a player’s position are filled.

Example:

```text
Player position
├── Filled child
└── Filled child
```

When recycle happens:

1. The parent position is closed.
2. The contract emits a recycle event.
3. The player receives a new position in the same level matrix.
4. The player receives additional matrix weight.
5. The player can receive a box token.
6. The player can reach prize cells.
7. The level can enter frozen state after repeated recycle cycles if the next higher level is not active.

Recycle is not a simple payout. It is a movement mechanic that gives the player a new position and increases that player’s probability weight in the level.

---

## Prize cells

Some matrix cells are special prize positions.

Prize cells follow binary milestone positions:

```text
7, 15, 31, 63, 127, 255, ...
```

These positions match completed binary tree waves and follow the formula:

```text
2^n - 1
```

When a player reaches a prize cell:

1. The contract emits `PrizePositionReached`.
2. The player can receive a prize reward.
3. If the level is active and not frozen, the reward becomes claimable.
4. If the level is frozen, the reward becomes pending.
5. Pending rewards can become claimable after unfreeze.

---

## Freeze and unfreeze logic

Freeze controls progression between levels.

Rules:

- After two recycle cycles, if the next higher level is not active, the current level can become frozen.
- A frozen player keeps their matrix position and weight.
- Rewards generated during freeze are not lost.
- Rewards generated during freeze are stored as pending prizes.
- Activating the next higher level can unfreeze lower frozen levels.
- After unfreeze, pending prizes move into claimable prizes.

This creates a level progression mechanic and prevents unlimited lower-level reward extraction without moving upward.

---

## Weight system

Each level has its own weight system.

A player’s level weight can increase through:

- Level activation.
- Direct referral activity.
- Second-line referral activity.
- Third-line referral activity.
- Matrix recycle.
- Box tokens.
- Loyalty mechanics.
- Boost mechanics.

Example referral weight logic:

```text
Direct inviter weight:      +100
Second-line inviter weight: +50
Third-line inviter weight:  +25
```

The contract tracks total level weight:

```solidity
totalWeightByLevel[level]
```

A player’s weighted chance is calculated conceptually as:

```text
player weight in level / total weight in level
```

Example:

```text
Player level weight: 1,000
Total level weight: 100,000

Player chance = 1,000 / 100,000 = 1%
```

---

## Payment distribution

Each level activation uses a fixed transparent split.

```text
75.5% → matrixPrizePools[level]
9.5%  → direct inviter claimable referral bonus
6.0%  → second-line inviter claimable referral bonus
4.0%  → third-line inviter claimable referral bonus
5.0%  → projectFeesAccrued
```

If a referral line is missing, that missing referral amount is routed back into `matrixPrizePools[level]`.

Project owner withdrawals are limited to:

```solidity
projectFeesAccrued
```

The owner cannot withdraw:

- Matrix prize pools.
- Player claimable referral bonuses.
- Player claimable prize rewards.
- Player pending prize rewards.

This keeps project revenue separated from player-reserved balances.

---

## Reward accounting

The contract separates the main balance types.

Player reward/accounting types:

- Claimable referral bonus.
- Claimable prize reward.
- Pending prize reward.
- Frozen state.
- Box token state.
- Matrix weight.
- Level activation state.
- Recycle count.

Accounting model:

```text
Referral bonus = earned through invite structure
Prize reward   = earned through matrix/prize/draw mechanics
Pending prize  = earned while frozen
Project fee    = platform commission only
Prize pool     = reserved for player rewards
```

---

## Weighted draw

Each level can use weighted draw mechanics.

Weighted draw winners are selected from the level’s total weight pool.

Conceptual formula:

```text
Player chance = playerLevelWeight / totalWeightByLevel
```

The current MVP uses block-based pseudo-randomness.

Production-grade deployment still needs verifiable randomness, such as Chainlink VRF or another secure randomness provider.

---

## Contract events for UI and indexer

The contract emits events that can be used to build live UI state, indexed history, analytics, and notifications.

Events:

```solidity
LevelActivated
PaymentSplit
ProjectFeeAccrued
MatrixPlaced
ReferralBonusAdded
SecondLineBonusAdded
ThirdLineBonusAdded
WeightUpdated
Recycled
BoxTokenGranted
PrizePositionReached
DrawRequested
DrawWon
ReferralBonusClaimed
PrizeClaimed
LevelFrozen
LevelUnfrozen
```

These events can support:

- Live matrix visualization.
- Player activity history.
- Level statistics.
- Referral history.
- Prize history.
- Recycle history.
- Freeze/unfreeze tracking.
- Weighted draw history.
- Claimable reward tables.

---

## Flutter integration

The app uses `WalletConnectService` as the shared wallet and contract bridge.

Wallet connection state is shared between:

- Login screen.
- Levels screen.
- Profile screen.
- Registration screen.
- Payment screen.

Current Flutter/Web3 behavior:

- Login supports injected Web3 wallets such as MetaMask.
- Login prefers Base Account Sign in with Base through the Base Account SDK `wallet_connect` + `signInWithEthereum` flow.
- If Base Account SDK is unavailable in local development, login falls back to an injected wallet.
- The SIWB `message`, `signature`, and `nonce` are stored in wallet state.
- Production builds still need backend verification and nonce replay protection.
- Network validation is strict by default.
- The connected wallet chain must match `EASY_GAME_CHAIN_ID`.
- Default chain is Base Sepolia `84532`.
- For local Ganache/Hardhat testing, use `EASY_GAME_CHAIN_ID=5777` or `EASY_GAME_ALLOW_LOCAL_CHAINS=true`.
- `LevelsScreen` can read on-chain level state from `EasyGameAdvance`.
- `ActivateExpressGameScreen` sends `activateLevel` transactions.
- The app estimates gas with `eth_estimateGas`.
- The app waits for `eth_getTransactionReceipt`.
- After confirmed activation, the app returns to the levels screen and refreshes state.
- Payment value is read from `levelPrices(level)` in wei.
- Native-token payment is used instead of floating-point ETH conversion.
- Level activation supports native ETH through `activateLevel` and optional
  USDC through `activateLevelWithUSDC` after ERC-20 approval.
- Base Pay can be evaluated later for a dedicated one-tap USDC payment UX, but
  the current game flow uses direct contract calls so matrix state is updated
  atomically by `EasyGameAdvance`.
- Optional Base Builder Code attribution can be appended to calldata through `BASE_BUILDER_DATA_SUFFIX`.

---

## Deploy

Compile contracts and sync app artifacts:

```bash
npm run compile
```

Deploy to Base Sepolia:

```bash
BASE_SEPOLIA_RPC_URL=https://sepolia.base.org PROJECT_WALLET=0x... TREASURY_ADDRESS=0x... OPERATOR_WALLET=0x... USDC_ADDRESS=0x... npx hardhat run scripts/deploy.js --network baseSepolia
```

Deploy to Base Mainnet:

```bash
BASE_RPC_URL=https://mainnet.base.org PROJECT_WALLET=0x... TREASURY_ADDRESS=0x... OPERATOR_WALLET=0x... USDC_ADDRESS=0x... npx hardhat run scripts/deploy.js --network base
```

The deploy script writes the deployed contract address into:

```text
src/artifacts/EasyGameAdvance.json
```

Run Flutter with a deployed contract:

```bash
flutter run -d chrome --dart-define=EASY_GAME_ADDRESS=0x...
```

Optional default inviter:

```bash
flutter run -d chrome --dart-define=EASY_GAME_ADDRESS=0x... --dart-define=EASY_GAME_INVITER=0x...
```

Optional Base Builder Code data suffix:

```bash
flutter run -d chrome --dart-define=EASY_GAME_ADDRESS=0x... --dart-define=BASE_BUILDER_DATA_SUFFIX=0x...
```

Local testing examples:

```bash
flutter run -d chrome --dart-define=EASY_GAME_CHAIN_ID=5777
```

```bash
flutter run -d chrome --dart-define=EASY_GAME_ALLOW_LOCAL_CHAINS=true
```

---

## Tests

Run Easy Game contract tests:

```bash
npx hardhat test test/EasyGame.js
```

Current tests cover:

- 17-level setup and default availability.
- Exact payment validation.
- Duplicate activation rejection.
- Independent level activation.
- Payment distribution: 75.5% prize pool, 9.5% direct, 6% second line, 4% third line, 5% project fee.
- Missing referral line routing into the matrix prize pool.
- Left-to-right binary matrix placement.
- Buyer position correctness during recycle.
- Recycle behavior.
- Matrix weight updates.
- Box token grants.
- Freeze behavior.
- Prize-position claimable rewards.
- Weighted draw rewards.
- Project fee withdrawal isolation.
- Unfreeze after activating the next level.

---

## Implemented and tested

[Jump to assets](https://github.com/Xatiko540/base-Easy-game/tree/master/assets)

### Easy Game Advance

- [x] Wallet login through an injected Web3 wallet such as MetaMask.
- [x] Shared wallet state across login, levels, profile, registration, and payment screens.
- [x] 17-level Easy Game Advance contract with predefined level prices.
- [x] Base native-token level activation through `EasyGameAdvance.activateLevel(level, inviter)`.
- [x] Exact payment amount is read from `levelPrices(level)` in wei before sending the transaction.
- [x] Independent activation: any available level can be activated.
- [x] Owner-controlled level availability for staged launch.
- [x] Duplicate level activation is rejected.
- [x] Binary matrix placement for each level.
- [x] Matrix slots are filled left-to-right through the first available parent node.
- [x] Dynamic placement prioritizes the uppermost open parent in the current level matrix.
- [x] Recycle is triggered when both child slots under a parent are filled.
- [x] Recycled players receive a new position in the same level matrix.
- [x] Recycled players receive additional matrix weight.
- [x] Box token grant is supported during recycle.
- [x] Prize position detection is implemented.
- [x] Freeze is triggered after two recycle cycles if the next higher level is not active.
- [x] Frozen players keep their position and weight, while new prizes become pending.
- [x] Activating the next level unfreezes lower frozen levels and releases pending prizes.
- [x] Payment distribution: 75.5% matrix prize pool, 9.5% direct referral, 6% second line, 4% third line, 5% project fee.
- [x] Missing referral lines are routed into the level prize pool.
- [x] `PROJECT_WALLET`, `TREASURY_ADDRESS`, and `OPERATOR_WALLET` are supported by the deploy script.
- [x] Contract events are emitted for activation, placement, payment split, weights, referrals, prize positions, weighted draw, recycle, freeze, and unfreeze.
- [x] Contract view functions expose player level state, player position, matrix node data, and level matrix stats.
- [x] Claimable referral bonus functions are implemented.
- [x] Claimable prize functions are implemented.
- [x] Project fee withdrawal is isolated to accrued project fees only.
- [x] Flutter can read on-chain level status and show active, waiting, locked, and frozen states.
- [x] Registration screen lets the user enter an upline/referral address.
- [x] Referral links / invite URL parsing can fill the upline address from `?inviter=0x...`, `?ref=0x...`, `?upline=0x...`, or `/npalce/0x...`.
- [x] Contract tests cover activation, placement, payment distribution, recycle, prize positions, weighted draw, project fees, freeze, and unfreeze.
- [x] Web build succeeds with the current Flutter package versions.

### Legacy lottery module

- [x] Dashboard and controller code for community lottery contracts remains in the project.
- [x] Lotteries can be created through `LotteryGenerator`.
- [x] Lottery deletion is restricted to the lottery creator.
- [x] Lottery activation is restricted to the lottery creator.
- [x] Lottery participation uses the ETH limit configured by the creator.
- [x] Maximum entries per player are configured by the lottery creator.
- [x] Winner selection and prize transfer are implemented in the legacy `Lottery` contract.

The legacy lottery module remains in the repository, but it is not the main Easy Game Advance path.

---

## Not implemented yet

- [ ] Production-grade verifiable random winner selection for weighted draw.
- [ ] Chainlink VRF or another secure randomness provider.
- [ ] Full live matrix visualization in Flutter with all matrix nodes, child slots, and recycle movement.
- [ ] Full UI tables for claimable referral bonus, claimable prize, pending prize, prize pool, player chance, and weighted draw history.
- [ ] Real-time indexed history for `MatrixPlaced`, `PaymentSplit`, `ReferralBonusAdded`, `PrizePositionReached`, `DrawWon`, `Recycled`, `LevelFrozen`, and `LevelUnfrozen`.
- [ ] Notification system for participants, referrals, rewards, freeze, and recycle status.
- [ ] User ID system connected to wallet addresses and matrix positions.
- [ ] Persistent local user profile data for Easy Game beyond the connected wallet.
- [ ] Dedicated subgraph/indexer or backend for historical matrix and reward analytics.
- [ ] Billion-cell scalability proof with practical gas and indexing strategy.
- [ ] Production security review for reentrancy, payout policy, gas griefing, and treasury/operator management.
- [ ] Cleanup of legacy lottery/private-key wallet flows that are no longer part of the main Easy Game path.
- [ ] Flutter analyzer cleanup for existing lints, deprecated APIs, file naming, unused imports, and production `print` calls.

---

## Scalability note

The binary matrix can theoretically grow to very large sizes because new cells are created dynamically as participants enter and recycle.

However, a real billion-cell matrix should not be treated as a fully on-chain visualization problem. For very large scale, the project needs:

- Efficient on-chain storage.
- Event-based history.
- Off-chain indexing.
- Subgraph or backend analytics.
- Paginated matrix reads.
- UI virtualization.
- Gas-aware matrix operations.

The current contract supports dynamic growth, but large-scale historical visualization and analytics should be handled through an indexer/backend instead of trying to render or query every cell directly from the chain.

---

## Project screens

[Go to project screens](https://www.figma.com)

---

## License

[License](https://github.com/Xatiko540/base-Easy-game/blob/master/LICENSE)
