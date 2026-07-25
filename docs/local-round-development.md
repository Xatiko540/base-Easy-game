# Local round development

The local stack uses Hardhat chain `31337` and Firebase emulators. It never
writes local schedules to production Firestore.

## Start infrastructure

```bash
npx hardhat node
firebase emulators:start --only functions,firestore,auth --project lottery-advance
```

## Deploy and seed a committed season

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

The seed first commits the complete signed season to the local Round Manager,
then mirrors that immutable commitment into the Firestore emulator. It creates:

- one committed `seasons/{seasonId}` document;
- exactly 17 signed level documents in `rounds/{roundId}`;
- three private Merkle proofs for every local round;
- one local development profile in `users/{chainId_wallet}`.

It validates every EIP-712 signature and `configRoot` against
`EasyGameRoundManager` before writing. Re-running it replaces only emulator
seasons and rounds for chain `31337`. This direct Admin SDK mirror is local-only;
production must use the callable `publishSeasonManifest` after the on-chain
`SeasonCommitted` transaction.

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
