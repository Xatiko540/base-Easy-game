part of '../views/profilescreen.dart';

class _RecentActivityTable extends StatelessWidget {
  final ProfileDashboardSnapshot data;

  const _RecentActivityTable({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final activeLevels = data.levels
        .where((entry) =>
            entry.state.active || entry.state.positionId > BigInt.zero)
        .take(5)
        .toList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: EasyGameTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EasyGameTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Text(
              'profile.recentTransactions'.tr,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Divider(height: 1, color: EasyGameTheme.border),
          _ActivityHeader(),
          const Divider(height: 1, color: EasyGameTheme.border),
          if (activeLevels.isEmpty)
            Padding(
              padding: const EdgeInsets.all(22),
              child: Text(
                'levels.historyAfterIndex'.tr,
                style: const TextStyle(color: Colors.white38),
              ),
            )
          else
            ...activeLevels.map(
              (entry) => _ActivityRow(
                entry: entry,
                profileId: data.player?.totalTickets.toString() ?? '0',
              ),
            ),
        ],
      ),
    );
  }
}

class _ActivityHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Expanded(flex: 2, child: _HeaderText('profile.type'.tr)),
          Expanded(flex: 3, child: _HeaderText('partner.date'.tr)),
          const Expanded(flex: 2, child: _HeaderText('ID')),
          Expanded(flex: 2, child: _HeaderText('common.level'.tr)),
          Expanded(flex: 4, child: _HeaderText('common.wallet'.tr)),
          Expanded(flex: 2, child: _HeaderText('profile.amount'.tr)),
        ],
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  final String text;

  const _HeaderText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white38,
        fontWeight: FontWeight.w900,
        fontSize: 12,
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final ProfileLevelState entry;
  final String profileId;

  const _ActivityRow({
    required this.entry,
    required this.profileId,
  });

  @override
  Widget build(BuildContext context) {
    final walletService = Get.find<WalletConnectService>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: EasyGameTheme.border),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: entry.state.frozen
                        ? EasyGameTheme.gold.withValues(alpha: 0.14)
                        : EasyGameTheme.teal.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    entry.state.frozen ? Icons.ac_unit : Icons.arrow_downward,
                    color: entry.state.frozen
                        ? EasyGameTheme.gold
                        : EasyGameTheme.teal,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'profile.onChainState'.tr,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              profileId,
              style: const TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${entry.level}',
              style: const TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              walletService.shortAddress,
              style: const TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              entry.state.frozen
                  ? 'common.frozen'.tr
                  : '+${formatWeiToEth(entry.state.earnedWei)}',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: entry.state.frozen
                    ? EasyGameTheme.gold
                    : const Color(0xFF28D07F),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
