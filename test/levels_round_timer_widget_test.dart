import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/models/game_round_models.dart';
import 'package:lottery_advance/app/modules/home/widgets/round_card_timer.dart';
import 'package:lottery_advance/app/translations/app_translations.dart';

void main() {
  GameRoundSchedule schedule() {
    final startsAt = DateTime.utc(2026, 7, 18, 12);
    return GameRoundSchedule(
      seasonId: 1,
      roundId: 101,
      chainId: 84532,
      contractAddress: '0x1111111111111111111111111111111111111111',
      roundManagerAddress: '0x2222222222222222222222222222222222222222',
      level: 5,
      startsAt: startsAt,
      entriesCloseAt: startsAt.add(const Duration(days: 4)),
      endsAt: startsAt.add(const Duration(days: 5)),
      freezeClosesAt: startsAt.add(const Duration(days: 4)),
      ethPriceWei: BigInt.from(200000000000000000),
      usdcPrice: BigInt.from(200000),
      maxPlayers: 1024,
      maxWinners: 4,
      freezeLimit: 10,
      paymentSplitVersion: 1,
      configHash: '0x${List.filled(32, '01').join()}',
      winningCellsRoot: '0x${List.filled(32, '02').join()}',
      operatorSignature: '0x${List.filled(65, '03').join()}',
      schemaVersion: 1,
    );
  }

  Future<void> pumpTimer(
    WidgetTester tester, {
    required Locale locale,
    required GameRoundPhase phase,
    required Duration remaining,
    required bool prominent,
  }) async {
    final state = GameRoundViewState(
      schedule: schedule(),
      phase: phase,
      remaining: remaining,
      isConfigurationTrusted: true,
    );
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: locale,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 150,
              height: prominent ? 125 : 55,
              child: RoundCardTimer(
                round: state,
                prominent: prominent,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('scheduled timer fits a narrow Russian level card',
      (tester) async {
    await pumpTimer(
      tester,
      locale: const Locale('ru'),
      phase: GameRoundPhase.scheduled,
      remaining: const Duration(days: 4, hours: 3),
      prominent: true,
    );

    expect(find.text('Доступно через'), findsOneWidget);
    expect(find.text('4 дн.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('open timer fits compact activation card state', (tester) async {
    await pumpTimer(
      tester,
      locale: const Locale('en'),
      phase: GameRoundPhase.open,
      remaining: const Duration(hours: 31, minutes: 5),
      prominent: false,
    );

    expect(find.text('Entry closes in'), findsOneWidget);
    expect(find.text('31 hours'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
