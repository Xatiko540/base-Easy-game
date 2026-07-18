# Local round development

The local stack uses Hardhat chain `31337` and Firebase emulators. It never
writes local schedules to production Firestore.

## Start infrastructure

```bash
npx hardhat node
firebase emulators:start --only functions,firestore,auth --project lottery-advance
```

## Deploy and seed a round

```bash
npx hardhat run scripts/deploy.js --network hardhatNode
cd functions && node seed_local_round.js
```

The deploy command writes the current addresses to `src/artifacts/*.json`.
Do not reuse addresses from an older Hardhat process: a restarted local node
starts from a clean chain and receives a fresh deployment.

Run the complete contract route after deployment:

```bash
npx hardhat run scripts/smoke-ganache.js --network hardhatNode
```

The smoke covers a signed round, ETH, direct USDC activation, referral claim,
freeze/unfreeze, Merkle settlement, and winner claims.

The seed creates:

- `seasons/1`;
- one signed level-5 document in `rounds/{roundId}`;
- four private Merkle proofs in `rounds/{roundId}/winningCells`;
- one local development profile in `users/{chainId_wallet}`.

It validates the EIP-712 signature against `EasyGameRoundManager` before
writing. Re-running it replaces only emulator rounds for chain `31337`.

## Run Flutter web

```bash
flutter run -d web-server --web-port 8090 --web-hostname 127.0.0.1 \
  --dart-define=USE_FIREBASE_EMULATORS=true \
  --dart-define=EASY_GAME_CHAIN_ID=31337 \
  --dart-define=EASY_GAME_ALLOW_LOCAL_CHAINS=true \
  --dart-define=WEB3_PUBLIC_RPC_URL=http://127.0.0.1:8545 \
  --dart-define=EASY_GAME_ADDRESS=<EasyGameAdvance address> \
  --dart-define=EASY_GAME_ROUND_MANAGER_ADDRESS=<EasyGameRoundManager address> \
  --dart-define=EASY_GAME_ARENA_SKILLS_ADDRESS=<EasyGameArenaSkills address> \
  --dart-define=EASY_GAME_ROUND_SETTLEMENT_ADDRESS=<EasyGameRoundSettlement address> \
  --dart-define=USDC_TOKEN_ADDRESS=<MockUSDC address>
```

Import a funded Hardhat development account into MetaMask and add network:

- RPC: `http://127.0.0.1:8545`
- chain ID: `31337`
- symbol: `ETH`

Never use the development mnemonic or keys outside the local chain.
