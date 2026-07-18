# Easy Games: текущая архитектура проекта

Этот документ описывает фактическую логику экспериментальной ветки
`codex/wagmi-web-experiment`. Он является картой текущего Flutter, Firebase и
Solidity-кода после перехода на `wagmi_web`, SIWE и раунды.

## 1. Границы системы

Проект состоит из четырех слоев:

```text
Flutter Web / Mobile
  GetX UI state + wagmi_web/Reown wallet transport
                    |
                    | RPC reads, signed transactions, SIWE signature
                    v
Base / Base Sepolia contracts
  Round Manager + Core + Arena Skills + Settlement
                    |
                    | public schedule/index, auth, notifications
                    v
Firebase
  Auth + Functions + Firestore + App Check + Hosting
```

Источники истины разделены следующим образом:

- контракты определяют деньги, участие, матрицу, вес, freeze и выплаты;
- `block.timestamp` определяет on-chain фазу раунда;
- подписанный EIP-712 manifest определяет неизменяемую конфигурацию раунда;
- Firestore публикует manifest, Merkle proofs и индекс данных для быстрого UI;
- GetX хранит только реактивное клиентское представление;
- локальный таймер Flutter обновляет надпись countdown, но не открывает раунд.

Firebase не может самостоятельно начислить приз, изменить матрицу или разрешить
вход вне on-chain окна.

## 2. Активные контракты

Production-набор состоит из четырех контрактов:

1. `EasyGameRoundManager` — расписание, EIP-712 manifest и прогресс игрока.
2. `EasyGameAdvance` — платежи, рефералы, матрица, recycle и веса.
3. `EasyGameArenaSkills` — покупка freeze, атака и платная разморозка.
4. `EasyGameRoundSettlement` — Merkle-проверка победителей и claim призов.

`MockUSDC` используется только в локальных тестах. Base Pay Gateway удален.

### 2.1 EasyGameRoundManager

`RoundConfig` подписывается разрешенным schedule signer через EIP-712 и содержит:

- `seasonId`, `roundId`, `level`;
- `startsAt`, `entriesCloseAt`, `endsAt`, `freezeClosesAt`;
- `maxPlayers`, `maxWinners`;
- `winningCellsRoot`;
- `ethPrice`, `usdcPrice`;
- `freezeLimit`, `paymentSplitVersion`.

Контракт проверяет:

- уровень находится в диапазоне 1-17;
- `startsAt < entriesCloseAt < endsAt`;
- раунд длится не менее часа;
- freeze-окно заканчивается вместе с раундом;
- лимит freeze равен 10 за каждый начатый день раунда;
- есть хотя бы одна цена ETH или USDC;
- winning root не пуст, число победителей 1-8;
- соседние уровни сезона открываются с интервалом минимум пять часов;
- один уровень сезона не получает второй активный manifest;
- будущий manifest нельзя инициализировать раньше `startsAt`;
- подпись принадлежит allowlist signer.

Раунд инициализируется лениво первой допустимой транзакцией после `startsAt`.
Повторная инициализация допустима только с тем же `configHash`.

Фазы вычисляются on-chain:

```text
Uninitialized -> Scheduled -> Open -> Locked -> SettlementReady -> Settled
                         \-> Paused / Cancelled
```

- `Open`: разрешена покупка билета;
- `Locked`: вход закрыт, но игра и freeze продолжаются;
- `SettlementReady`: время завершилось, можно подводить итоги;
- `Paused`: экстренная административная остановка;
- `Cancelled`: отмена возможна только до появления участников.

#### Прогресс уровней

- Первым уровнем сезона игрок может выбрать любой открытый уровень.
- После первой покупки следующий новый уровень должен быть ровно
  `highestLevel + 1`.
- Уже купленный или более низкий уровень повторно купить нельзя.
- Freeze на текущем верхнем уровне блокирует переход на следующий.
- Уже купленные уровни freeze не удаляет и не переписывает.
- Каждая активированная ступень добавляет четыре места для уникальных прямых
  партнеров.
- Пригласитель должен уже участвовать в этом сезоне.
- При достижении лимита новых прямых партнеров пригласитель должен купить
  следующую ступень, чтобы получить еще четыре места.

### 2.2 EasyGameAdvance

#### Активация за ETH

```text
activateRound(config, signature, inviter)
```

- требует точное `msg.value == config.ethPrice`;
- Round Manager проверяет manifest, фазу, вместимость и прогрессию;
- emergency switch уровня должен быть включен;
- игрок регистрируется и получает первую ячейку;
- создается `PlayerRound` и начисляется базовый вес;
- платеж распределяется по правилам раунда.

#### Активация за USDC

```text
approve(core, usdcPrice)
activateRoundWithUSDC(config, signature, inviter)
```

USDC переводится из кошелька игрока в Core через `transferFrom`. Даже при оплате
USDC игроку нужен ETH сети Base для gas обеих транзакций.

#### Распределение каждого платежа

```text
75.5% -> round prize pool
 9.5% -> direct inviter
 6.0% -> second-line inviter
 4.0% -> third-line inviter
 5.0% -> projectFeesAccrued
```

Если реферальной линии нет, ее доля возвращается в prize pool раунда.
Реферальная выплата становится claimable, а не отправляется push-переводом.

Иерархия игрока фиксируется при первой регистрации:

```text
inviter -> secondLine -> thirdLine
```

Самоприглашение, неизвестный адрес и замена уже сохраненного inviter запрещены
логикой регистрации.

#### Бинарная матрица

- каждый раунд имеет отдельное пространство ячеек;
- номера заполняются как binary heap: 1, 2, 3, 4...;
- parent равен `cellId / 2`;
- сначала заполняется left child, затем right child;
- после заполнения двух детей parent закрывается и его игрок попадает в FIFO
  recycle queue.

Recycle дает игроку:

- новую позицию в том же раунде;
- `cycleCount + 1`;
- `boxTokens + 1`;
- `matrixWeight + 50`;
- `nftWeight + 10`.

Одна транзакция выполняет ограниченное число recycle-операций. Остаток может
обработать любой пользователь через `processRoundRecycles(roundId, maxSteps)`,
где `maxSteps <= 64`. Settlement запрещен, пока очередь не пуста.

#### Вес

Вес игрока в раунде складывается из:

```text
baseWeight + referralWeight + matrixWeight + nftWeight
```

Текущие начисления:

- личная активация: +100 base weight;
- direct referral: +100 referral weight;
- second line: +50 referral weight;
- third line: +25 referral weight;
- recycle: +50 matrix weight;
- box: +10 NFT weight.

Каждый тип и общий вес имеют caps. Реферальный вес начисляется пригласителю
только если он сам активен в этом раунде.

#### Хранение средств

Core хранит раздельные обязательства:

- ETH/USDC prize pool каждого `roundId`;
- claimable ETH/USDC referral bonuses;
- ETH/USDC project fees.

Owner может вывести только project fee, и перевод идет на `projectWallet`.
Реферальные бонусы игрок забирает сам. Prize pool может получить только
Settlement после завершения раунда и очистки recycle queue.

### 2.3 EasyGameArenaSkills

Arena Skills работает с USDC и текущим `roundId`:

- freeze token стоит `0.30 USDC`;
- покупать и применять freeze могут только участники раунда;
- нельзя заморозить себя или неучаствующий адрес;
- каждый token используется один раз;
- продолжительность одной заморозки вычисляется из длины раунда и лимита;
- после `freezeLimit` попаданий игрок получает иммунитет;
- окно игры доступно в фазах `Open` и `Locked` до `freezeClosesAt`.

Разморозка стоит минимум `1 USDC`. Более высокая цена равна 7% ожидаемой доли
игрока в ETH+USDC prize pool. Для пересчета ETH используется зафиксированное в
manifest отношение цены билета ETH/USDC, а не клиентский курс.

Платежи за игровые skills сразу переводятся в `skillTreasury` и не входят в
призовой пул.

### 2.4 EasyGameRoundSettlement

До старта раунда список winning cell IDs фиксируется Merkle root в manifest.
После `endsAt` settlement получает полный отсортированный список ячеек и proofs.

Для каждой ячейки контракт проверяет:

- proof соответствует `winningCellsRoot`;
- ячейка реально создана;
- адрес игрока не пуст;
- один игрок не добавляется дважды;
- игрок не исключен freeze-состоянием;
- вес победителя больше нуля.

После проверки Settlement забирает весь prize pool из Core. Если допустимых
победителей несколько, ETH и USDC делятся пропорционально их round weight. Если
победителей нет, средства переходят в rollover следующего раунда того же уровня.

Призы сохраняются в `claimableEth` и `claimableUsdc`. Игрок вызывает один
`claimPrize()`, который выплачивает оба доступных актива.

## 3. Firebase Functions

Firebase ускоряет UI и управляет доверенной публикацией, но не заменяет
контрактные проверки.

### requestSiweNonce

- требует Firebase bootstrap user и App Check;
- проверяет wallet, Base chain ID и разрешенный origin;
- применяет rate limit;
- создает SIWE challenge на 10 минут;
- сохраняет одноразовый nonce в `walletAuthChallenges`.

### authenticateWallet

- повторно читает challenge и проверяет expiry/replay;
- проверяет SIWE message и подпись через Base RPC;
- поддерживает EOA и contract wallet verification;
- вычисляет стабильный непрозрачный Firebase UID как SHA-256 от chain+wallet;
- сохраняет `users` и `walletLinks`;
- помечает nonce использованным;
- выдает Firebase Custom Token с claims `wallet`, `chainId`, `authProvider=siwe`.

Хеш UID не является секретом. Безопасность обеспечивают подпись кошелька,
одноразовый nonce, App Check и подпись Custom Token сервисным аккаунтом Firebase.

### getAppConfig

Возвращает публичную конфигурацию клиента: chain ID, публичный RPC, адреса Core,
Manager, Skills, Settlement и USDC, signer и environment. Приватные ключи и
секреты функция не возвращает.

### publishRoundManifest

- доступна только admin;
- проверяет round constraints и интервал соседних уровней;
- строит Merkle tree winning cells;
- проверяет EIP-712 подпись разрешенного schedule signer;
- неизменно публикует season, round config, signature, config hash и proofs в
  Firestore.

Клиент не может писать manifests согласно Firestore rules.

### getRoundSettlementProofs

Возвращает опубликованный полный набор winning cells и Merkle proofs для
settlement раунда.

### contractSmokeTest

Admin-проверка перед релизом:

- bytecode существует по всем четырем адресам и адресу USDC;
- Core, Manager, Skills и Settlement ссылаются друг на друга;
- все контракты используют один USDC.

### trackTransaction

Принимает transaction hash только от подтвержденной SIWE/Firebase-сессии и
создает пользовательскую запись `submitted` для activity UI.

### registerDevice

Привязывает FCM token к проверенному wallet user, применяет rate limit и хранит
не более десяти актуальных устройств одного кошелька.

### health

HTTP health check проверяет обязательную конфигурацию и наличие bytecode.

## 4. Wallet login и сессия

Wallet transport полностью построен на `wagmi_web 2.23.0` и Reown AppKit.

```text
Connect wallet
 -> wagmi reconnect/connect
 -> switch/check Base chain
 -> requestSiweNonce
 -> wagmi signMessage
 -> authenticateWallet
 -> Firebase signInWithCustomToken
 -> LOCAL persistence
```

`WalletConnectService` отвечает за:

- инициализацию wagmi и Reown connectors;
- `watchAccount` и `watchChainId`;
- восстановление последнего connector;
- connect/disconnect и подпись message;
- native/USDC balances;
- contract reads/writes и ожидание receipts;
- ETH/USDC activation, claims и Arena actions.

`WalletAuthController` является единым GetX-состоянием авторизации. Он сверяет
подключенный wallet, chain ID и Firebase session. После reload Firebase LOCAL
session и wagmi connector восстанавливаются. Если wallet сменился, чужая session
очищается. Полный logout выполняется только явной кнопкой выхода.

Base Pay, старые Base Account bridges, `flutter_web3`, `web3dart` transport и
локальный `WalletSession` в активной архитектуре не используются.

## 5. GetX и UI

Постоянные сервисы регистрируются один раз в `main.dart`. Экранные controllers
создаются bindings/lazyPut и освобождают Workers в `onClose`.

### Состояние раундов

- `GameClockService` периодически синхронизирует время последнего Base block;
- секундный ticker меняет только countdown presentation;
- `GameScheduleService` подписывается на Firestore rounds;
- `GameRoundsRepository` объединяет manifest, chain time и on-chain phase;
- `GameRoundsController` публикует реактивные раунды по уровням;
- `RoundLevelsRepository` загружает round/player/card data пакетами;
- `LevelsProvider` формирует 17 стабильных карточек и обновляет их без демонтажа
  всей сетки.

Карточка может показывать:

- новый раунд еще не начался и countdown;
- доступен для активации;
- активен;
- активен и заморожен;
- сначала требуется следующий допустимый уровень;
- уровень уже ниже текущего прогресса;
- вход закрыт;
- ожидание settlement;
- settled, paused, cancelled или config error.

### Регистрация и оплата

`RegistrationController` выбирает актуальный открытый round, inviter и актив
оплаты. `RoundPaymentController` перед отправкой заново проверяет:

- SIWE/Firebase auth;
- текущий manifest и `configHash`;
- фазу и актуальный `roundId`;
- Base network;
- emergency level switch;
- on-chain progression eligibility;
- баланс выбранного актива;
- наличие ETH для gas.

ETH отправляется одним вызовом `activateRound`. USDC выполняет `approve` при
недостаточном allowance, затем `activateRoundWithUSDC`.

### Matrix Arena

`MatrixArenaController` выбирает активированный игроком раунд, иначе первый
доступный уровень. Он читает реальные matrix nodes, player round, participants,
вес и Arena status. Через него выполняются:

- покупка freeze token;
- выбор и заморозка соперника;
- платная разморозка;
- отображение frozen/immune/hits/tokens и приглашенных участников.

### Остальные экраны

- Profile: wallet identity, referral link, rewards, box tokens и activity;
- Partner Bonus: три линии, referral weight и claim ETH/USDC;
- Statistics: агрегаты раундов и платежное распределение;
- Information: правила матрицы, winning cells, freeze и выплаты;
- Invite: извлекает inviter из URL и сохраняет его до регистрации;
- Notifications: приветствие и реальные локальные/FCM события без demo-записей.

RU/EN строки находятся в GetX translations. Desktop и mobile используют один
AppShell с адаптивными sidebar/topbar/content layouts.

## 6. Полный пользовательский маршрут

```text
Landing
 -> Reown wallet connection
 -> SIWE signature
 -> Firebase session restored/created
 -> Levels schedule
 -> select open round
 -> registration + inviter
 -> choose ETH or USDC
 -> preflight
 -> wallet transaction(s)
 -> matrix position + weight
 -> referrals/recycle/freeze gameplay
 -> entries locked
 -> round ends
 -> recycle queue completed
 -> Merkle settlement
 -> referral/prize claim
 -> Profile/Transactions update
```

## 7. Security and operational rules

- schedule signer key не хранится во Flutter или Firestore;
- deployer/owner, schedule signer, project wallet, operator и skill treasury
  должны быть разделены;
- project owner не может вывести prize pool или player liabilities;
- смена USDC после деплоя запрещена, потому что Skills/Settlement используют
  immutable token;
- Firebase secrets не коммитятся;
- публичный RPC допустим для теста, для production нужен dedicated Base RPC;
- App Check обязателен для callable Functions вне local environment;
- перед hosting release обязательно выполняется `contractSmokeTest`;
- новый ABI нельзя связывать со старым deployment address.

## 8. Текущий статус ветки

Локальное ядро и Flutter работают как единая round-based система без Base Pay.
Перед production-публикацией этой версии необходимо заново развернуть четыре
контракта, обновить Firebase public config, опубликовать новый подписанный сезон и
только затем обновлять Hosting. Старые адреса нельзя использовать с новым ABI.
