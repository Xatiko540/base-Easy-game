part of '../views/partner_bonus_screen.dart';

class _PersonalReferralPanel extends StatelessWidget {
  final PartnerBonusController controller;

  const _PersonalReferralPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final link = controller.referralLink;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C2D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2B2B45)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.group_outlined, color: EasyGameTheme.teal),
                const SizedBox(width: 10),
                Text(
                  'partner.personalLink'.tr,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: EasyGameTheme.cardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: EasyGameTheme.borderSoft),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      link,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: EasyGameTheme.teal,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _SmallActionButton(
                    label: 'common.copy'.tr,
                    icon: Icons.copy,
                    onTap: controller.copyReferralLink,
                  ),
                  const SizedBox(width: 8),
                  _SmallActionButton(
                    label: 'common.share'.tr,
                    icon: Icons.share,
                    gradient: true,
                    onTap: controller.shareReferralLink,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 580;
                final cards = [
                  _ReferralLineCard(
                      percent: '9.5%', label: 'partner.direct'.tr, refs: 'L1'),
                  _ReferralLineCard(
                      percent: '6.0%',
                      label: 'partner.secondLineShort'.tr,
                      refs: 'L2'),
                  _ReferralLineCard(
                      percent: '4.0%',
                      label: 'partner.thirdLineShort'.tr,
                      refs: 'L3'),
                ];
                if (compact) {
                  return Column(
                    children: cards
                        .expand((card) => [card, const SizedBox(height: 10)])
                        .toList(),
                  );
                }
                return Row(
                  children: [
                    for (var i = 0; i < cards.length; i++) ...[
                      Expanded(child: cards[i]),
                      if (i != cards.length - 1) const SizedBox(width: 10),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      );
    });
  }
}

class _ReferralRulesPanel extends StatelessWidget {
  final PartnerArenaSnapshot data;

  const _ReferralRulesPanel({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C2D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2B2B45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: EasyGameTheme.teal),
              const SizedBox(width: 10),
              Text(
                'partner.linesHowTitle'.tr,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'partner.linesHowText'.tr,
            style: const TextStyle(
              color: Colors.white54,
              height: 1.6,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          _LineRoute(
              label: 'partner.newPlayerLine'.tr,
              value: '100%',
              color: EasyGameTheme.orange),
          _LineRoute(
              label: 'partner.direct'.tr,
              value: '9.5% +100 wt',
              color: EasyGameTheme.teal),
          _LineRoute(
              label: 'partner.secondLineShort'.tr,
              value: '6% +50 wt',
              color: EasyGameTheme.purple),
          _LineRoute(
              label: 'partner.thirdLineShort'.tr,
              value: '4% +25 wt',
              color: EasyGameTheme.blue),
          const SizedBox(height: 18),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: [
              _ReferralRuleMini(
                  title: 'stats.poolDraw'.tr,
                  value: '75.5%',
                  subtitle: 'totalWeight'),
              _ReferralRuleMini(
                  title: 'partner.direct'.tr,
                  value: '9.5%',
                  subtitle: '+100 wt'),
              _ReferralRuleMini(
                  title: 'partner.secondLineShort'.tr,
                  value: '6%',
                  subtitle: '+50 wt'),
              _ReferralRuleMini(
                  title: 'partner.thirdLineShort'.tr,
                  value: '4%',
                  subtitle: '+25 wt'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool gradient;
  final VoidCallback onTap;

  const _SmallActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.gradient = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: gradient ? null : const Color(0xFF2A2948),
          gradient: gradient ? EasyGameTheme.actionGradient : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferralLineCard extends StatelessWidget {
  final String percent;
  final String label;
  final String refs;

  const _ReferralLineCard({
    required this.percent,
    required this.label,
    required this.refs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EasyGameTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EasyGameTheme.teal.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Text(
            percent,
            style: const TextStyle(
              color: EasyGameTheme.teal,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(refs,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w900)),
          Text(label,
              style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }
}

class _LineRoute extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _LineRoute({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white54)),
          ),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _ReferralRuleMini extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _ReferralRuleMini({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EasyGameTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EasyGameTheme.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: EasyGameTheme.purple,
                  fontSize: 20,
                  fontWeight: FontWeight.w900)),
          Text(subtitle,
              style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }
}
