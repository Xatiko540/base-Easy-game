part of '../views/levels.dart';

class _LevelClaimPanel extends StatelessWidget {
  final int level;
  final EasyGamePlayerSummary? player;
  final bool isFrozen;

  const _LevelClaimPanel({
    required this.level,
    required this.player,
    required this.isFrozen,
  });

  @override
  Widget build(BuildContext context) {
    final walletService = Get.find<WalletConnectService>();
    final data = player;
    if (data == null) {
      return _LevelDetailPanel(
        title: 'levelDetail.rewardsWallet'.tr,
        rows: [
          DetailRow('common.status'.tr, 'common.notConnected'.tr),
          DetailRow('levelDetail.claimablePrize'.tr, '0'),
          DetailRow('levelDetail.referralBonus'.tr, '0'),
        ],
      );
    }

    final currency = walletService.nativeSymbol;
    final canClaimPrize = data.claimablePrizeWei > BigInt.zero && !isFrozen;
    final canClaimReferral = data.claimableReferralBonusWei > BigInt.zero;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EasyGameTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EasyGameTheme.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'levelDetail.rewardsWallet'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _LevelStatsStrip(
            stats: [
              DetailRow(
                'levelDetail.claimablePrize'.tr,
                '${formatWeiToEth(data.claimablePrizeWei)} $currency',
              ),
              DetailRow(
                'levelDetail.pendingPrize'.tr,
                '${formatWeiToEth(data.pendingPrizeWei)} $currency',
              ),
              DetailRow(
                'levelDetail.referralBonus'.tr,
                '${formatWeiToEth(data.claimableReferralBonusWei)} $currency',
              ),
              DetailRow(
                'levelDetail.recycleCount'.tr,
                data.recycleCount.toString(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ClaimActionButton(
                label: 'levelDetail.claimPrize'.tr,
                enabled: canClaimPrize,
                onTap: () async {
                  final tx =
                      await walletService.claimEasyGamePrize(level: level);
                  Get.snackbar(
                    'common.submitted'.tr,
                    tx,
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
              _ClaimActionButton(
                label: 'levelDetail.claimReferral'.tr,
                enabled: canClaimReferral,
                onTap: () async {
                  final tx = await walletService.claimEasyGameReferralBonus();
                  Get.snackbar(
                    'common.submitted'.tr,
                    tx,
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
            ],
          ),
          if (isFrozen && data.pendingPrizeWei > BigInt.zero) ...[
            const SizedBox(height: 10),
            Text(
              'levelDetail.pendingFrozenHint'.tr,
              style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _ClaimActionButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final Future<void> Function() onTap;

  const _ClaimActionButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
        onTap: enabled
            ? () async {
                try {
                  await onTap();
                } catch (e) {
                  Get.snackbar(
                    'common.error'.tr,
                    '$e',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              }
            : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            gradient: enabled ? EasyGameTheme.actionGradient : null,
            color: enabled ? null : EasyGameTheme.card,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelStatsStrip extends StatelessWidget {
  final List<DetailRow> stats;

  const _LevelStatsStrip({required this.stats});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 680;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stats.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isNarrow ? 2 : 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: isNarrow ? 2.2 : 2.4,
          ),
          itemBuilder: (context, index) {
            final item = stats[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F2E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.label,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
