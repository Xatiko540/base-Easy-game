part of '../views/levels.dart';

class LevelCard extends StatelessWidget {
  final RoundLevelCardState data;
  final BigInt roundId;
  final String currencySymbol;
  final GameRoundViewState round;

  const LevelCard({
    Key? key,
    required this.data,
    required this.roundId,
    required this.currencySymbol,
    required this.round,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final displayProgress = data.fillPercent;
    return GestureDetector(
      onTap: () => Get.to(() => EasyGameLevelDetailScreen(
            level: data.level,
            roundId: roundId,
          )),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: EasyGameTheme.cardBorderGradient,
              ),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: EasyGameTheme.cardDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CardHeader(
                      level: data.level,
                      coin: weiToEthDouble(data.ethPriceWei),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'levels.waitingLine'.tr,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF9B9B9B),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InlineRoundCountdown(round: round),
                      ],
                    ),
                    const SizedBox(height: 7),
                    _ProgressBar(value: displayProgress / 100),
                    const SizedBox(height: 12),
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'levels.currentLineFill'.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const _MatrixCellGlyph(size: 20),
                              const SizedBox(width: 6),
                              Text(
                                '${displayProgress.toStringAsFixed(2)}%',
                                style: const TextStyle(
                                  color: EasyGameTheme.textMuted,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _WeightStrip(
                      weight: data.playerWeight,
                      chanceBps: data.playerChanceBps,
                      totalWeight: data.totalWeight,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SmallMetric(
                          value:
                              '${formatWeiToEth(data.prizePoolWei)} $currencySymbol',
                          label: 'levelDetail.prizePool'.tr,
                          alignEnd: false,
                        ),
                        _SmallMetric(
                          value: data.positionId.toString(),
                          label: 'levelDetail.position'.tr,
                          alignEnd: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -18,
            right: 18,
            child: Text(
              'levels.owned'.tr,
              style: TextStyle(
                color: const Color(0xFF7CFF85).withValues(alpha: 0.95),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ActivateCard extends StatelessWidget {
  final int level;
  final double coin;
  final String currencySymbol;
  final GameRoundViewState? round;

  const ActivateCard({
    Key? key,
    required this.level,
    required this.coin,
    required this.currencySymbol,
    this.round,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF3A3B3C),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            level: level,
            coin: coin,
          ),
          const Spacer(),
          if (round != null) ...[
            RoundCardTimer(round: round!, prominent: false),
            const SizedBox(height: 14),
          ],
          Center(
            child: Text(
              'levels.availableActivation'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _GradientActionButton(
            label: 'levels.activate'.tr,
            onTap: () {
              Get.to(
                () => RegistrationScreen(
                  LevelStatus.waiting,
                  level: level,
                  amount: coin,
                  inviter: Get.find<WalletConnectService>().activeInviter,
                  round: round,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class StatusCard extends StatelessWidget {
  final int level;
  final double coin;
  final String currencySymbol;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final GameRoundViewState? round;
  final bool showTimer;

  const StatusCard({
    Key? key,
    required this.level,
    required this.coin,
    required this.currencySymbol,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
    this.round,
    this.showTimer = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF3A3B3C),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardHeader(
              level: level,
              coin: coin,
            ),
            const Spacer(),
            if (showTimer && round != null)
              Center(child: RoundCardTimer(round: round!))
            else ...[
              Center(
                child: Icon(
                  icon,
                  size: 42,
                  color: color,
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFAAAAAA),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
