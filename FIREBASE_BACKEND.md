# Easy Game Firebase backend

The smart contract remains the source of truth. Firebase Functions provide
secure public configuration, wallet linking, transaction tracking, manual level
sync, and FCM notifications. Flutter signs all user transactions.

## Required Firebase setup

1. Project: `lottery-advance`.
2. Enable Anonymous Authentication.
3. Create a Firestore Native database in `us-central1`.
4. Enable Cloud Messaging and create a Web Push VAPID key.
5. Register Web, Android, and iOS apps as required.
6. Upgrade to Blaze. Firebase does not deploy Cloud Functions on Spark.

## Secure configuration

Sensitive values must live in Firebase/Google Secret Manager, not in Flutter,
Firestore, or committed `.env` files.

```bash
firebase functions:secrets:set BASE_RPC_URL
firebase functions:secrets:set APP_CHECK_RECAPTCHA_SITE_KEY
firebase functions:secrets:set APP_MESSAGING_VAPID_KEY
```

Public runtime values are Firebase Functions params. They are safe to return to
the Flutter app through `getAppConfig`:

```text
EASY_GAME_CONTRACT_ADDRESS=0x...
EASY_GAME_CHAIN_ID=8453
EASY_GAME_CONFIRMATIONS=5
EASY_GAME_START_BLOCK=<deployment block>
APP_PUBLIC_URL=https://easygame.io
WEB3_PUBLIC_RPC_URL=https://mainnet.base.org
APP_ENVIRONMENT=production
USDC_TOKEN_ADDRESS=0x...
EASY_GAME_INVITER=0x...
PAYMENT_RECEIVER=0x...
BASE_BUILDER_DATA_SUFFIX=0x...
EASY_GAME_ALLOW_LOCAL_CHAINS=false
BASE_ACCOUNT_APP_NAME=Easy Game
BASE_ACCOUNT_APP_LOGO_URL=https://easygame.io/logo.png
```

`BASE_RPC_URL` is the server-side RPC used by Functions. `WEB3_PUBLIC_RPC_URL`
is the public client fallback used by Flutter event listeners. Do not put a
paid/private RPC endpoint in `WEB3_PUBLIC_RPC_URL`.

Never put a wallet private key, mnemonic, RPC secret, or service-account JSON
inside Flutter or this repository.

## Deploy

```bash
cd functions
npm install
cd ..
flutter build web \
  --dart-define=EASY_GAME_CHAIN_ID=8453 \
  --dart-define=EASY_GAME_ADDRESS=0x...
firebase deploy --only functions,firestore,hosting
```

## Functions

- `requestWalletNonce` / `linkWallet`: binds anonymous UID to a signed wallet.
- `registerDevice`: binds an FCM token to a verified wallet.
- `trackTransaction`: records a user-submitted transaction.
- `syncLevel` / `syncAllLevels`: reads contract level state through the
  server-side `BASE_RPC_URL` secret and writes denormalized level documents.
- `getAppConfig`: returns public app configuration plus public web keys loaded
  from Secret Manager.
- `health`: exposes the current indexer checkpoint.

`syncGameEvents` and `confirmTransactions` are intentionally not enabled in the
current deployment. Keep them as an explicit future backend-worker step if the
project moves from manual/on-demand sync to scheduled indexing.

The Google Compute Engine VM is no longer required for normal processing. Keep
it stopped as a disaster-recovery tool, or remove it after the Functions setup
has been observed in production.
