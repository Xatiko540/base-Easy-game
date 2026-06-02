<h1 align="center">Flutter Advance base Easy game</h1>

<h2 align="center">This is a scientific experiment to predict lottery winnings based on the structure of a binary matrix

the logic of a binary matrix with 1 million participants and 1 billion cells </h2>

<h3 align="center">Implementation of the project as a proof of the theory of large numbers and winning percentages, describing the real numbers of winnings, as well as all processes of interaction with the blockchain and distribution of payments through baes </h3>

## Current Easy Game logic

Easy Game is a Flutter + Solidity Web3 application built around a 17-level binary matrix. The user connects a Web3 wallet, activates levels with ETH on Base Sepolia, and is placed into the level matrix. Each level has its own price and its own binary placement tree.

### User flow

1. Connect wallet with MetaMask or another injected Web3 wallet.
2. Open the Easy Game levels screen.
3. Choose an available level.
4. Enter or approve the upline/referral address.
5. Continue to payment.
6. The app calls `EasyGame.activateLevel(level, inviter)` through the wallet.
7. The contract places the player in the matrix and distributes the payment.

### Smart contract mechanics

The active Easy Game contract is `contracts/EasyGame.sol`.

- There are 17 levels.
- Each level has a predefined ETH price.
- A player cannot activate a level twice.
- A player cannot activate level `N` before level `N - 1`.
- Each level has a separate binary matrix.
- New positions are filled left-to-right through the first available parent node.
- When both child slots of a parent are filled, that parent position is closed.
- A closed parent triggers recycle for that player.
- After two cycles, if the next level is not active, the current level becomes frozen.
- Activating the next level unfreezes the previous frozen level.

### Payment distribution

Each level activation distributes the paid amount as:

- `80%` to the matrix parent/upline of the current level.
- `9.5%` to the direct referral.
- `0.5%` to the operator wallet.
- `6%` to the second-line referral.
- `4%` to the third-line referral.

If a referral line is missing, that part is routed to the treasury wallet. If the matrix parent is frozen, the matrix reward is routed to treasury instead of the frozen player.

### Contract events for UI

The contract emits events that can be used to build live UI state:

- `LevelActivated`
- `MatrixPlaced`
- `MatrixRewardPaid`
- `ReferralPaid`
- `Recycled`
- `LevelFrozen`
- `LevelUnfrozen`

### Flutter integration

The app uses `WalletConnectService` as the shared wallet and contract bridge.

- Wallet connection state is shared between login, levels, profile, registration, and payment screens.
- `LevelsScreen` can read on-chain level state from `EasyGame`.
- `ActivateExpressGameScreen` sends `activateLevel` transactions.
- Payment value is read from `levelPrices(level)` in the contract, so the transaction uses exact wei instead of floating-point ETH conversion.

### Deploy

Compile contracts and sync app artifacts:

```bash
npm run compile
```

Deploy to Base Sepolia:

```bash
TREASURY_ADDRESS=0x... OPERATOR_WALLET=0x... npx hardhat run scripts/deploy.js --network baseSepolia
```

The deploy script writes the deployed contract address into `src/artifacts/EasyGame.json`.

You can also pass the contract address directly to Flutter:

```bash
flutter run -d chrome --dart-define=EASY_GAME_ADDRESS=0x...
```

Optional default inviter:

```bash
flutter run -d chrome --dart-define=EASY_GAME_ADDRESS=0x... --dart-define=EASY_GAME_INVITER=0x...
```

### Tests

Run Easy Game contract tests:

```bash
npx hardhat test test/EasyGame.js
```

Current tests cover:

- First level activation.
- Previous-level requirement.
- Duplicate activation rejection.
- Exact payment validation.
- Left-to-right matrix placement.
- Buyer position correctness during recycle.
- 80/20 payment distribution.
- Freeze after two cycles.
- Frozen parent reward routing.
- Unfreeze after activating the next level.

## Projects that inspired this project

https://github.com/user-attachments/assets/58c1ac8d-a3e3-452c-8c0c-01509652a688


https://github.com/user-attachments/assets/8003673a-a62f-4aed-9cfc-9b151a3e6e56

![Image 2024-11-30 at 02 35 22](https://github.com/user-attachments/assets/bc83c84e-a136-404f-bb50-e7e1b12886ce)

![image](https://github.com/user-attachments/assets/9827c830-0ba7-4259-9f9c-03e4612fdc90)

![image](https://github.com/user-attachments/assets/b22ca094-b357-4c67-8106-12e77d26ca82)

![image](https://github.com/user-attachments/assets/460be616-79b3-4d29-9181-e152b386c298)

![WhatsApp Image 2024-11-30 at 07 06 56](https://github.com/user-attachments/assets/eb0bae6e-7d97-43dc-b8cb-7c6c11633b31)








### Implemented and tested

[Jump to assets](https://github.com/Xatiko540/base-Easy-game/tree/master/assets)

#### Easy Game

- [x] Wallet login through an injected Web3 wallet such as MetaMask.
- [x] Shared wallet state across login, levels, profile, registration, and payment screens.
- [x] 17-level Easy Game contract with predefined level prices.
- [x] ETH-based level activation through `EasyGame.activateLevel(level, inviter)`.
- [x] Exact payment amount is read from `levelPrices(level)` in wei before sending the transaction.
- [x] Previous-level requirement: level `N` requires level `N - 1`.
- [x] Duplicate level activation is rejected.
- [x] Binary matrix placement for each level.
- [x] Matrix slots are filled left-to-right through the first available parent node.
- [x] Dynamic placement prioritizes the uppermost open parent in the current level matrix.
- [x] Recycle is triggered when both child slots under a parent are filled.
- [x] Recycled players receive a new position in the same level matrix.
- [x] Freeze is triggered after two cycles if the next level is not active.
- [x] Frozen players stop receiving new recycle positions.
- [x] Matrix reward is routed to treasury when the matrix parent is frozen.
- [x] Activating the next level unfreezes the previous frozen level.
- [x] Payment distribution: 80% matrix reward, 9.5% direct referral, 0.5% operator wallet, 6% second-line referral, 4% third-line referral.
- [x] Missing referral lines are routed to treasury.
- [x] `TREASURY_ADDRESS` and `OPERATOR_WALLET` are supported by the deploy script.
- [x] Contract events are emitted for level activation, placement, rewards, referrals, recycle, freeze, and unfreeze.
- [x] Contract view functions expose player level state, player position, matrix node data, and level matrix stats.
- [x] Flutter can read on-chain level status and show active, waiting, locked, and frozen states.
- [x] Registration screen lets the user enter an upline/referral address.
- [x] Referral links / invite URL parsing can fill the upline address from `?inviter=0x...`, `?ref=0x...`, `?upline=0x...`, or `/npalce/0x...`.
- [x] Contract tests cover activation, placement, payment distribution, recycle, freeze, frozen reward routing, and unfreeze.
- [x] Web build succeeds with the current Flutter package versions.

#### Legacy lottery module

- [x] Dashboard and controller code for community lottery contracts remains in the project.
- [x] Lotteries can be created through `LotteryGenerator`.
- [x] Lottery deletion is restricted to the lottery creator.
- [x] Lottery activation is restricted to the lottery creator.
- [x] Lottery participation uses the ETH limit configured by the creator.
- [x] Maximum entries per player are configured by the lottery creator.
- [x] Winner selection and prize transfer are implemented in the legacy `Lottery` contract.

### Not implemented yet

- [ ] Production-grade random winner selection for Easy Game matrix rewards. Current implementation uses the matrix parent/upline, not random selection.
- [ ] Full live matrix visualization in Flutter with all matrix nodes, child slots, and recycle movement.
- [ ] Real-time event listener in Flutter for `MatrixPlaced`, `MatrixRewardPaid`, `ReferralPaid`, `Recycled`, `LevelFrozen`, and `LevelUnfrozen`.
- [ ] Notification system for participants, referrals, rewards, freeze, and recycle status.
- [ ] User ID system connected to wallet addresses and matrix positions.
- [ ] Persistent local user profile data for Easy Game beyond the connected wallet.
- [ ] Infinite or billion-cell scalability proof on-chain. The matrix grows dynamically, but very large matrices need gas/indexing strategy and off-chain indexing.
- [ ] Dedicated subgraph/indexer or backend for historical matrix and reward analytics.
- [ ] Production security review for reentrancy, payout policy, gas griefing, and treasury/operator management.
- [ ] Cleanup of legacy lottery/private-key wallet flows that are no longer part of the main Easy Game path.
- [ ] Flutter analyzer cleanup for existing lints, deprecated APIs, file naming, unused imports, and production `print` calls.




[Go to project screens](https://www.figma.com)


### The final logic of the binary matrix with 1 million participants and 1 billion cells



Binary Matrix Structure
Total cell size: 1,000,000,000 (1 billion).
Number of participants: 1,000,000 (1 million).
How it works:
Each level contains 2^n cells, where n is the level number (starting with n = 0).
Participants are added from left to right, filling the top rows before moving to the bottom.


Calculating Filled Levels
Formula for calculating the number of participants needed to fill the first n levels:

\text{Participants} = \sum_{k=0}^{n} 2^k = 2^{n+1} - 1

Result for n = 19 :
2^{20} - 1 = 1,048,575 .
Since we only have 1,000,000 participants, only the first 19 levels are completely filled.
Remaining participants on level 20:
1,000,000 - 524,287 = 475,713 .
Available 2^{20} = 1,048,576 cells on level 20.
Filling: \frac{475,713}{1,048,576} \approx 45.36\% .

Recycles (Recycle)
Recycle conditions:
A recycle occurs when two cells under the player are filled.
The player moves to the next available level, starting with the left cell.
Number of recycles:
At the n -th level: R_n = \frac{2^n}{2} = 2^{n-1} .
For the first 19 levels (full filling):

R_{\text{19 levels}} = \sum_{n=1}^{19} 2^{n-1} = 524,287 \, \text{recycles}.

At the 20th level:
475,713 / 2 = 237,856 \, \text{recycles} .
At the 21st level:
237,856 / 2 = 118,928 \, \text{recycles} .
Total recycles:
\text{Total} = 524,287 + 237,856 + 118,928 + \dots , decreasing as you go down.


![Image 2024-12-07 at 19 42 40](https://github.com/user-attachments/assets/3011a9d1-ef32-4494-bdb5-cd8d8e2e003b)


![image](https://github.com/user-attachments/assets/1c74fee2-625a-4ca2-b0e1-5c33d119be3e)



Final distribution of participants
Full occupancy:
Levels 1–19: fully occupied.
Partial occupancy:
Level 20: 45.36\% .
Level 21: \frac{237,856}{2,097,152} \approx 11.34\% .
Level 22: the process continues with decreasing density.
Recycle dynamics:
Recycles ensure the redistribution of participants across the lower levels while there are free spaces.
Occupancy density:
With 1 million participants:

\frac{1,000,000}{1,000,000,000} \times 100\% = 0.1\%.

Most of the matrix remains unoccupied, creating space for future participants.


Basic principles of the system
Room for growth:
The binary matrix allows for a virtually unlimited number of participants.
The system remains active even with a significant increase in participants.
Recycles and movement:
Recycles support the movement of participants down the matrix, ensuring uniform filling of new cells.
Level dynamics:
Participants fill the upper levels sequentially.
Upon reaching level 19, the matrix continues to partially fill the lower levels.


Example of participant movement
Levels 1–19:
Participants 1–524,287 completely fill these levels.
Level 20:
Participants 524,288–1,000,000 occupy 45.36\% of available cells.
First wave of recycles: 237,856 participants are redistributed downwards.
Level 21:
118,928 participants occupy 11.34\% of cells.
Redistribution continues.


Potential improvements
Add a forecasting algorithm to distribute participants across levels in real time.
Visualize the movement of participants through a matrix for easy monitoring.
Develop a notification system for participants at each recycle or new level filling.



[License](https://github.com/Xatiko540/base-Easy-game/blob/master/LICENSE)




