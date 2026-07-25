import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_advance/app/models/matrix_round_models.dart';
import 'package:lottery_advance/app/repositories/matrix_arena_repository.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';

const _currentWallet = '0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

class _FakeWalletService extends WalletConnectService {
  final Map<int, RoundMatrixNode> nodes = {};
  final Map<String, EasyGamePlayerSummary> players = {};
  final Map<String, ArenaSkillStatus> skills = {};
  int playerReads = 0;
  int skillReads = 0;

  @override
  Future<RoundMatrixNode> getRoundMatrixNode(
    BigInt roundId,
    int cellId,
  ) async {
    final node = nodes[cellId];
    if (node == null) throw StateError('missing node');
    return node;
  }

  @override
  Future<EasyGamePlayerSummary> getEasyGamePlayerSummary({
    String? address,
  }) async {
    playerReads++;
    return players[address!.toLowerCase()]!;
  }

  @override
  Future<ArenaSkillStatus> getArenaSkillStatus(
    BigInt roundId, {
    String? playerAddress,
  }) async {
    skillReads++;
    return skills[playerAddress!.toLowerCase()]!;
  }
}

void main() {
  late _FakeWalletService wallet;
  late MatrixArenaRepository repository;

  setUp(() {
    wallet = _FakeWalletService();
    wallet.currentAddress.value = _currentWallet;
    for (var cell = 1; cell <= 30; cell++) {
      final address = cell == 20
          ? _currentWallet
          : '0x${cell.toRadixString(16).padLeft(40, '0')}';
      wallet.nodes[cell] = _node(cell, address);
      wallet.players[address] = _player(
        address,
        inviter: cell == 2 ? _currentWallet : '',
      );
      wallet.skills[address] = _skill(frozen: cell == 3);
    }
    repository = MatrixArenaRepository(walletService: wallet);
  });

  test('first page always includes the current player position', () async {
    final page = await repository.loadRosterPage(
      roundId: BigInt.from(99),
      activeCells: BigInt.from(30),
      currentPlayerCellId: BigInt.from(20),
      page: 0,
      pageSize: 3,
    );

    expect(page.participants.map((item) => item.cellId),
        contains(BigInt.from(20)));
    expect(page.participants, hasLength(4));
    expect(page.hasMore, isTrue);
    expect(
        page.participants
            .singleWhere((item) => item.cellId == BigInt.two)
            .isInvited,
        isTrue);
    expect(
        page.participants
            .singleWhere((item) => item.cellId == BigInt.from(3))
            .skillStatus
            ?.frozen,
        isTrue);
  });

  test('wallet and skill reads are cached while pages remain independent',
      () async {
    Future<MatrixArenaRosterPage> load(int page) {
      return repository.loadRosterPage(
        roundId: BigInt.from(99),
        activeCells: BigInt.from(30),
        currentPlayerCellId: BigInt.zero,
        page: page,
        pageSize: 3,
      );
    }

    await load(0);
    await load(0);
    expect(wallet.playerReads, 3);
    expect(wallet.skillReads, 3);

    final second = await load(1);
    expect(second.participants.map((item) => item.cellId),
        [BigInt.from(4), BigInt.from(5), BigInt.from(6)]);
    expect(wallet.playerReads, 6);
    expect(wallet.skillReads, 6);
  });
}

RoundMatrixNode _node(int cell, String wallet) {
  return RoundMatrixNode(
    cellId: BigInt.from(cell),
    player: wallet,
    level: 1,
    parentCellId: BigInt.from(cell ~/ 2),
    leftChildCellId: BigInt.zero,
    rightChildCellId: BigInt.zero,
    closed: false,
  );
}

EasyGamePlayerSummary _player(String wallet, {required String inviter}) {
  return EasyGamePlayerSummary(
    exists: true,
    wallet: wallet,
    inviter: inviter,
    secondLine: '',
    thirdLine: '',
    totalTickets: BigInt.one,
    baseWeight: BigInt.from(100),
    referralWeight: BigInt.zero,
    loyaltyWeight: BigInt.zero,
    matrixWeight: BigInt.zero,
    nftWeight: BigInt.zero,
    totalWeight: BigInt.from(100),
    boxTokens: BigInt.zero,
    recycleCount: BigInt.zero,
    claimableReferralBonusWei: BigInt.zero,
    claimableReferralBonusUsdc: BigInt.zero,
    claimablePrizeWei: BigInt.zero,
    pendingPrizeWei: BigInt.zero,
    joinedAt: BigInt.zero,
    lastActiveAt: BigInt.zero,
  );
}

ArenaSkillStatus _skill({required bool frozen}) {
  return ArenaSkillStatus(
    frozen: frozen,
    immune: false,
    frozenUntil: null,
    freezeHits: frozen ? 1 : 0,
    freezeTokens: 0,
    unfreezePriceUsdc: BigInt.from(1000000),
  );
}
