part of '../views/profilescreen.dart';

class _AboutContractsRow extends StatelessWidget {
  final ProfileController controller;
  final ProfileDashboardSnapshot data;
  final bool isClaimingPrize;
  final bool isClaimingReferral;
  final bool isClaimingReferralUsdc;

  const _AboutContractsRow({
    required this.controller,
    required this.data,
    required this.isClaimingPrize,
    required this.isClaimingReferral,
    required this.isClaimingReferralUsdc,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 920;
        final about = _AboutEasyGamePanel(
          controller: controller,
          data: data,
          isClaimingPrize: isClaimingPrize,
          isClaimingReferral: isClaimingReferral,
          isClaimingReferralUsdc: isClaimingReferralUsdc,
        );
        final contracts = _ContractsStatsPanel(
          onCopyContract: controller.copyContractAddress,
          onOpenContract: controller.openContractExplorer,
          data: data,
          currency: Get.find<WalletConnectService>().nativeSymbol,
        );

        if (stacked) {
          return Column(
            children: [
              about,
              const SizedBox(height: 16),
              contracts,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: about),
            const SizedBox(width: 18),
            Expanded(flex: 3, child: contracts),
          ],
        );
      },
    );
  }
}

class _AboutEasyGamePanel extends StatelessWidget {
  final ProfileController controller;
  final ProfileDashboardSnapshot data;
  final bool isClaimingPrize;
  final bool isClaimingReferral;
  final bool isClaimingReferralUsdc;

  const _AboutEasyGamePanel({
    required this.controller,
    required this.data,
    required this.isClaimingPrize,
    required this.isClaimingReferral,
    required this.isClaimingReferralUsdc,
  });

  @override
  Widget build(BuildContext context) {
    final walletService = Get.find<WalletConnectService>();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: EasyGameTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EasyGameTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'profile.aboutTitle'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 640;
              final cards = [
                _ClaimMiniCard(
                  icon: CupertinoIcons.rosette,
                  value:
                      '${formatWeiToEth(data.claimablePrizeWei)} ${walletService.nativeSymbol}',
                  label: 'levelDetail.claimablePrize'.tr,
                  action: isClaimingPrize
                      ? 'common.loading'.tr
                      : 'levelDetail.claimPrize'.tr,
                  accent: EasyGameTheme.teal,
                  onTap: data.claimablePrizeWei > BigInt.zero ||
                          data.settlementPrizeUsdc > BigInt.zero
                      ? isClaimingPrize
                          ? null
                          : controller.claimPrize
                      : null,
                ),
                _ClaimMiniCard(
                  icon: CupertinoIcons.link,
                  value:
                      '${formatWeiToEth(data.referralBonusWei)} ${walletService.nativeSymbol}',
                  label: 'levelDetail.referralBonus'.tr,
                  action: isClaimingReferral
                      ? 'common.loading'.tr
                      : 'profile.claimRefShort'.tr,
                  accent: EasyGameTheme.purple,
                  onTap: data.referralBonusWei > BigInt.zero
                      ? isClaimingReferral
                          ? null
                          : controller.claimReferralBonus
                      : null,
                ),
                _ClaimMiniCard(
                  icon: CupertinoIcons.money_dollar,
                  value:
                      '${formatUsdc(data.referralBonusUsdc)} USDC',
                  label: 'profile.usdcReferralLabel'.tr,
                  action: isClaimingReferralUsdc
                      ? 'common.loading'.tr
                      : 'profile.claimRefShort'.tr,
                  accent: const Color(0xFF2775CA),
                  onTap: data.referralBonusUsdc > BigInt.zero
                      ? isClaimingReferralUsdc
                          ? null
                          : controller.claimReferralBonusUSDC
                      : null,
                ),
                _ClaimMiniCard(
                  icon: CupertinoIcons.tray_full,
                  value: data.boxTokens.toString(),
                  label: 'profile.boxTokens'.tr,
                  action: null,
                  accent: EasyGameTheme.gold,
                  onTap: null,
                ),
              ];

              if (compact) {
                return Column(
                  children: cards
                      .map(
                        (card) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: card,
                        ),
                      )
                      .toList(),
                );
              }

              return Row(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    Expanded(child: cards[i]),
                    if (i != cards.length - 1) const SizedBox(width: 12),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            'profile.aboutText'.tr,
            style: const TextStyle(
              color: Colors.white54,
              height: 1.5,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _WeightBreakdown(data: data),
        ],
      ),
    );
  }
}

class _ClaimMiniCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String? action;
  final Color accent;
  final VoidCallback? onTap;

  const _ClaimMiniCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.action,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF151528),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: EasyGameTheme.borderSoft),
        ),
        child: Column(
          children: [
            Icon(icon, color: accent, size: 22),
            const SizedBox(height: 10),
            Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white38,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            if (action != null && onTap != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onTap,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: accent.withValues(alpha: 0.55)),
                    foregroundColor: accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(
                    action!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ContractsStatsPanel extends StatelessWidget {
  final ProfileDashboardSnapshot data;
  final String currency;
  final VoidCallback onCopyContract;
  final VoidCallback onOpenContract;

  const _ContractsStatsPanel({
    required this.data,
    required this.currency,
    required this.onCopyContract,
    required this.onOpenContract,
  });

  @override
  Widget build(BuildContext context) {
    final contract = data.contractAddress;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: EasyGameTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EasyGameTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'profile.contractsTitle'.tr,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF282642),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'app.name'.tr,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  shortProfileAddress(contract),
                  style: const TextStyle(
                    color: EasyGameTheme.teal,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: onCopyContract,
                  child: const Icon(
                    CupertinoIcons.doc_on_doc,
                    color: Colors.white38,
                    size: 15,
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'profile.openExplorer'.tr,
                  child: InkWell(
                    onTap: onOpenContract,
                    child: const Icon(
                      CupertinoIcons.arrow_up_right_square,
                      color: Colors.white38,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _ContractMetric(
            label: 'profile.occupiedCells'.tr,
            value: data.totalActiveCells.toString(),
            delta: '+ ${data.activeCount}',
          ),
          const SizedBox(height: 18),
          _ContractMetric(
            label: 'profile.activations'.tr,
            value: data.tickets.toString(),
            delta: '+ ${data.recycleCount}',
          ),
          const SizedBox(height: 18),
          _ContractMetric(
            label: 'profile.prizePoolShort'.trParams({'currency': currency}),
            value: '${formatWeiToEth(data.totalPrizePoolWei)} $currency',
            delta: '+ ${formatWeiToEth(data.claimableWei)} $currency',
          ),
        ],
      ),
    );
  }
}

class _ContractMetric extends StatelessWidget {
  final String label;
  final String value;
  final String delta;

  const _ContractMetric({
    required this.label,
    required this.value,
    required this.delta,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          delta,
          style: const TextStyle(
            color: Color(0xFF28D07F),
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
