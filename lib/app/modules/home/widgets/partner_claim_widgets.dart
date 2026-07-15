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
              final connectedNow = controller.walletService.isConnected.value;
              final disabled =
                  !connectedNow || claimable == BigInt.zero || isPaying;

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
