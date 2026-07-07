# Easy Game Firebase backend

The smart contract remains the source of truth. Firebase Functions index
confirmed `EasyGameAdvance` events into Firestore, confirm submitted
transactions, and send FCM notifications. Flutter signs all user transactions.

## Required Firebase setup

1. Project: `lottery-advance`.
2. Enable Anonymous Authentication.
3. Create a Firestore Native database in `us-central1`.
4. Enable Cloud Messaging and create a Web Push VAPID key.
5. Register Web, Android, and iOS apps as required.
6. Upgrade to Blaze. Firebase does not deploy Cloud Functions on Spark.

## Function configuration

Set the production Base RPC as a Firebase secret:

```bash
firebase functions:secrets:set BASE_RPC_URL
```

Set non-secret deployment parameters when prompted by `firebase deploy`:

```text
EASY_GAME_CONTRACT_ADDRESS=0x...
EASY_GAME_CHAIN_ID=8453
EASY_GAME_CONFIRMATIONS=5
EASY_GAME_START_BLOCK=<deployment block>
```

Never put a wallet private key, mnemonic, RPC secret, or service-account JSON
inside Flutter or this repository.

## Deploy

```bash
cd functions
npm install
cd ..
flutter build web \
  --dart-define=EASY_GAME_CHAIN_ID=8453 \
  --dart-define=EASY_GAME_ADDRESS=0x... \
  --dart-define=FIREBASE_RECAPTCHA_V3_SITE_KEY=... \
  --dart-define=FIREBASE_VAPID_KEY=...
firebase deploy --only functions,firestore,hosting
```

## Functions

- `syncGameEvents`: confirmed event indexer, one batch per minute.
- `confirmTransactions`: receipt confirmation every two minutes.
- `requestWalletNonce` / `linkWallet`: binds anonymous UID to a signed wallet.
- `registerDevice`: binds an FCM token to a verified wallet.
- `trackTransaction`: records a user-submitted transaction.
- `health`: exposes the current indexer checkpoint.

The Google Compute Engine VM is no longer required for normal processing. Keep
it stopped as a disaster-recovery tool, or remove it after the Functions setup
has been observed in production.
