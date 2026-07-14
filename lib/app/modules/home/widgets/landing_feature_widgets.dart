part of '../views/start_page.dart';

class _StartTimerStrip extends StatelessWidget {
  const _StartTimerStrip();

  @override
  Widget build(BuildContext context) {
    final roundsController = Get.find<GameRoundsController>();
    return Obx(
      () {
        final round = roundsController.nearestEvent;
        final text = round == null
            ? 'start.scheduleUnavailable'.tr
            : _roundTimerText(round);
        return Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: EasyGameTheme.purple.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(CupertinoIcons.timer, color: Colors.white, size: 15),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _roundTimerText(GameRoundViewState round) {
    final parameters = {
      'level': '${round.schedule.level}',
      'time': localizedRoundCountdown(round),
    };
    switch (round.phase) {
      case GameRoundPhase.scheduled:
        return 'start.roundStartsIn'.trParams(parameters);
      case GameRoundPhase.open:
        return 'start.entriesCloseIn'.trParams(parameters);
      case GameRoundPhase.locked:
        return 'start.roundEndsIn'.trParams(parameters);
      case GameRoundPhase.uninitialized:
      case GameRoundPhase.settlementReady:
      case GameRoundPhase.settled:
      case GameRoundPhase.cancelled:
      case GameRoundPhase.paused:
        return roundPhaseTranslationKey(round.phase).tr;
    }
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  @override
  Widget build(BuildContext context) {
    const items = [
      _FeatureItem(
          CupertinoIcons.shield, 'start.smartContract', 'start.onChain'),
      _FeatureItem(
          CupertinoIcons.arrow_up_right, 'start.levelsCount', 'start.weightedMatrix'),
      _FeatureItem(CupertinoIcons.person_2, '67 000+', 'start.activeNetwork'),
      _FeatureItem(CupertinoIcons.bolt, '100%', 'start.walletPayouts'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 640 ? 2 : 4;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: constraints.maxWidth < 640 ? 1.45 : 1.7,
          ),
          itemBuilder: (context, index) => _FeatureCard(item: items[index]),
        );
      },
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final _FeatureItem item;

  const _FeatureCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: EasyGameTheme.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: EasyGameTheme.purple.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: EasyGameTheme.tealSoft, size: 25),
          ),
          const SizedBox(height: 14),
          Text(
            item.title.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.subtitle.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
