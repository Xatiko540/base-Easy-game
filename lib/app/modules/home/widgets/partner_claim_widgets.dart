part of '../views/partner_bonus_screen.dart';

class _ClaimableReferralPanel extends StatelessWidget {
  final PartnerBonusController controller;

  const _ClaimableReferralPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final data = controller.snapshot.value;
      final claimable = data.claimableReferralBonusWei;
      final totalWeight = data.totalWeight;
      return _PartnerAccordionPanel(
        icon: CupertinoIcons.money_dollar_circle,
        title: 'partner.claimableReferral'.tr,
        child: Wrap(
          spacing: 14,
          runSpacing: 14,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            _ClaimStat(
              title: 'partner.claimableReferral'.tr,
              value:
                  '${formatPartnerWei(claimable)} ${controller.walletService.nativeSymbol}',
            ),
            _ClaimStat(
              title: 'partner.totalWeight'.tr,
              value: totalWeight.toString(),
            ),
            Obx(() {
              final isPaying = controller.walletService.isPaying.value;
              final authenticatedNow =
                  Get.find<WalletAuthController>().isAuthenticated;
              final disabled =
                  !authenticatedNow || claimable == BigInt.zero || isPaying;

              return ElevatedButton(
                onPressed: disabled ? null : controller.claimReferralBonus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: EasyGameTheme.blue,
                  disabledBackgroundColor: EasyGameTheme.card,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isPaying
                      ? controller.walletService.paymentStatusLabel
                      : claimable == BigInt.zero
                          ? 'partner.noClaimableReferral'.tr
                          : 'partner.claimReferral'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              );
            }),
          ],
        ),
      );
    });
  }
}

class _ReferralFlowPanel extends StatelessWidget {
  const _ReferralFlowPanel();

  @override
  Widget build(BuildContext context) {
    return _PartnerAccordionPanel(
      icon: CupertinoIcons.arrow_2_circlepath,
      title: 'partner.referralRouting'.tr,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 740;
          final cards = [
            _FlowStep(
              title: 'partner.direct'.tr,
              percent: '9.5%',
              weight: '+100 wt',
              icon: CupertinoIcons.person_badge_plus,
            ),
            _FlowStep(
              title: 'partner.secondLineShort'.tr,
              percent: '6%',
              weight: '+50 wt',
              icon: CupertinoIcons.square_list,
            ),
            _FlowStep(
              title: 'partner.thirdLineShort'.tr,
              percent: '4%',
              weight: '+25 wt',
              icon: CupertinoIcons.arrow_2_circlepath,
            ),
          ];

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...cards.expand((card) => [card, const SizedBox(height: 10)]),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    Expanded(child: cards[i]),
                    if (i != cards.length - 1)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(
                          CupertinoIcons.chevron_forward,
                          color: EasyGameTheme.textDim,
                        ),
                      ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FlowStep extends StatelessWidget {
  final String title;
  final String percent;
  final String weight;
  final IconData icon;

  const _FlowStep({
    required this.title,
    required this.percent,
    required this.weight,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EasyGameTheme.cardDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: EasyGameTheme.borderSoft),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: EasyGameTheme.actionGradient,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$percent / $weight',
                  style: const TextStyle(
                    color: EasyGameTheme.gold,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClaimStat extends StatelessWidget {
  final String title;
  final String value;

  const _ClaimStat({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 180),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
