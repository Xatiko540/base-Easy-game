part of '../views/partner_bonus_screen.dart';

class _PartnerMetricGrid extends StatelessWidget {
  final _PartnerArenaSnapshot data;
  final String currency;

  const _PartnerMetricGrid({
    required this.data,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _PartnerMetricCard(
        icon: Icons.group_outlined,
        title: 'partner.tickets'.tr,
        value: data.totalTickets.toString(),
        delta: '+${data.baseWeight} wt',
        color: EasyGameTheme.teal,
      ),
      _PartnerMetricCard(
        icon: Icons.person_outline,
        title: 'partner.teamWeight'.tr,
        value: data.referralWeight.toString(),
        delta: '+ referral',
        color: EasyGameTheme.purple,
      ),
      _PartnerMetricCard(
        icon: Icons.show_chart,
        title: 'partner.ratio'.tr,
        value: data.totalWeight == BigInt.zero
            ? '0%'
            : '${((data.referralWeight.toDouble() / data.totalWeight.toDouble()) * 100).clamp(0, 100).toStringAsFixed(0)}%',
        delta: '+ chance',
        color: Colors.greenAccent,
      ),
      _PartnerMetricCard(
        icon: Icons.monetization_on_outlined,
        title: 'partner.profits'.tr,
        value: '${_formatWei(data.claimableReferralBonusWei)} $currency',
        delta: '+ claimable',
        color: EasyGameTheme.orange,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 520
            ? 1
            : constraints.maxWidth < 900
                ? 2
                : 4;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 170,
          ),
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }
}

class _PartnerMetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String delta;
  final Color color;

  const _PartnerMetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.delta,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C2D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2B2B45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                title,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                delta,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
