import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/modules/home/views/levels.dart';
import 'package:lottery_advance/app/services/referral_link_service.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';
import 'package:url_launcher/url_launcher.dart';

class StatisticsScreen extends StatelessWidget {
  StatisticsScreen({Key? key}) : super(key: key);

  final WalletConnectService walletService = Get.find<WalletConnectService>();

  Future<_StatisticsSnapshot> _load() async {
    final contractAddress = await walletService.resolveEasyGameAddress();
    var activeLevels = 0;
    var frozenLevels = 0;
    var matrixNodes = BigInt.zero;
    var totalLevelCostWei = BigInt.zero;

    for (var level = 1; level <= 17; level++) {
      try {
        totalLevelCostWei +=
            await walletService.getEasyGameLevelPriceWei(level);
      } catch (_) {
        totalLevelCostWei += BigInt.zero;
      }

      try {
        final stats = await walletService.getEasyGameMatrixStats(level);
        matrixNodes += stats.size;
      } catch (_) {
        matrixNodes += BigInt.zero;
      }

      if (walletService.isConnected.value) {
        try {
          final state = await walletService.getEasyGameLevel(level: level);
          if (state.active) {
            activeLevels++;
          }
          if (state.frozen) {
            frozenLevels++;
          }
        } catch (_) {
          // Individual level read failures should not hide the whole screen.
        }
      }
    }

    return _StatisticsSnapshot(
      contractAddress: contractAddress,
      activeLevels: activeLevels,
      frozenLevels: frozenLevels,
      matrixNodes: matrixNodes,
      totalLevelCostWei: totalLevelCostWei,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_StatisticsSnapshot>(
      future: _load(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        return _UtilityScaffold(
          title: 'Statistics',
          icon: Icons.bar_chart,
          children: [
            _StatusCard(
              title: 'Wallet',
              value: walletService.isConnected.value
                  ? walletService.shortAddress
                  : 'Not connected',
              icon: Icons.account_balance_wallet,
            ),
            Obx(
              () => _StatusCard(
                title: 'Network chain ID',
                value: walletService.chainId.value?.toString() ?? 'Unknown',
                icon: Icons.hub,
              ),
            ),
            _StatusCard(
              title: 'EasyGame contract',
              value: data == null
                  ? snapshot.hasError
                      ? 'Not loaded'
                      : 'Loading...'
                  : _shortAddress(data.contractAddress),
              icon: Icons.description,
            ),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Active levels',
                    value: data?.activeLevels.toString() ?? '-',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'Frozen levels',
                    value: data?.frozenLevels.toString() ?? '-',
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Matrix nodes',
                    value: data?.matrixNodes.toString() ?? '-',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'All levels cost',
                    value: data == null
                        ? '-'
                        : '${_formatWei(data.totalLevelCostWei)} ETH',
                  ),
                ),
              ],
            ),
            _ActionTile(
              icon: Icons.grid_view,
              title: 'Matrix levels',
              subtitle: 'Open current Easy Game level status.',
              onTap: () => Get.to(() => LevelsScreen()),
            ),
          ],
        );
      },
    );
  }
}

class MemberPreviewScreen extends StatelessWidget {
  final String query;

  MemberPreviewScreen({
    Key? key,
    required this.query,
  }) : super(key: key);

  final WalletConnectService walletService = Get.find<WalletConnectService>();

  Future<List<EasyGameLevelState>> _loadLevels() async {
    final normalized = ReferralLinkService.normalizeAddress(query);
    if (normalized.isEmpty) {
      return const [];
    }

    final result = <EasyGameLevelState>[];
    for (var level = 1; level <= 17; level++) {
      try {
        result.add(
          await walletService.getEasyGameLevel(
            playerAddress: normalized,
            level: level,
          ),
        );
      } catch (_) {
        result.add(
          EasyGameLevelState(
            active: false,
            frozen: false,
            cycles: BigInt.zero,
            positionId: BigInt.zero,
            earnedWei: BigInt.zero,
          ),
        );
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final normalized = ReferralLinkService.normalizeAddress(query);
    final isWallet = normalized.isNotEmpty;

    return FutureBuilder<List<EasyGameLevelState>>(
      future: _loadLevels(),
      builder: (context, snapshot) {
        final states = snapshot.data ?? const <EasyGameLevelState>[];
        final activeCount = states.where((state) => state.active).length;
        final frozenCount = states.where((state) => state.frozen).length;
        final earnedWei = states.fold<BigInt>(
          BigInt.zero,
          (sum, state) => sum + state.earnedWei,
        );

        return _UtilityScaffold(
          title: 'Member preview',
          icon: Icons.manage_search,
          children: [
            _StatusCard(
              title: isWallet ? 'Wallet address' : 'Member ID',
              value: isWallet ? normalized : query,
              icon: isWallet ? Icons.account_balance_wallet : Icons.badge,
            ),
            if (!isWallet)
              const _InfoBlock(
                title: 'ID lookup',
                text:
                    'The contract does not expose a user ID registry yet. Wallet address preview is available now; ID search needs the user ID/indexer layer.',
              ),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Active levels',
                    value: isWallet
                        ? snapshot.hasData
                            ? activeCount.toString()
                            : '-'
                        : 'N/A',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'Frozen levels',
                    value: isWallet
                        ? snapshot.hasData
                            ? frozenCount.toString()
                            : '-'
                        : 'N/A',
                  ),
                ),
              ],
            ),
            _StatusCard(
              title: 'Earned on levels',
              value: isWallet
                  ? snapshot.hasData
                      ? '${_formatWei(earnedWei)} ETH'
                      : 'Loading...'
                  : 'N/A',
              icon: Icons.payments,
            ),
            _ActionTile(
              icon: Icons.grid_view,
              title: 'Open levels',
              subtitle: isWallet
                  ? 'Open program view filtered by this wallet.'
                  : 'Open program view.',
              onTap: () => Get.to(
                () => LevelsScreen(walletAddress: isWallet ? normalized : null),
              ),
            ),
          ],
        );
      },
    );
  }
}

class InformationScreen extends StatelessWidget {
  const InformationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const _UtilityScaffold(
      title: 'Information',
      icon: Icons.info_outline,
      children: [
        _InfoBlock(
          title: 'Easy Game matrix',
          text:
              'Each level uses a binary matrix. New activations are placed into the next open slot, and completed positions recycle into the same level.',
        ),
        _InfoBlock(
          title: 'Reward distribution',
          text:
              'Payments are split as 80% matrix reward, 9.5% direct referral, 0.5% operations, 6% second line, and 4% third line.',
        ),
        _InfoBlock(
          title: 'Freeze rule',
          text:
              'After two cycles, a level can freeze until the player activates the next level.',
        ),
      ],
    );
  }
}

class TelegramBotsScreen extends StatelessWidget {
  const TelegramBotsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _UtilityScaffold(
      title: 'Telegram bots',
      icon: Icons.telegram,
      children: [
        _ActionTile(
          icon: Icons.notifications_active,
          title: 'Notifier bot',
          subtitle: 'Open the notifier setup screen.',
          onTap: () => Get.to(() => NotifierBotScreen()),
        ),
        _ActionTile(
          icon: Icons.support_agent,
          title: 'Support',
          subtitle: 'Open support channels.',
          onTap: () => Get.to(() => const SupportScreen()),
        ),
        const _InfoBlock(
          title: 'Configuration',
          text:
              'Production Telegram links are not configured yet. Add them through dart-define or app settings when they are ready.',
        ),
      ],
    );
  }
}

class PromoScreen extends StatelessWidget {
  PromoScreen({Key? key}) : super(key: key);

  final WalletConnectService walletService = Get.find<WalletConnectService>();

  @override
  Widget build(BuildContext context) {
    final link = ReferralLinkService.buildReferralLink(
      walletService.currentAddress.value,
    );

    return _UtilityScaffold(
      title: 'Promo',
      icon: Icons.campaign,
      children: [
        _InfoBlock(
          title: 'Partner link',
          text: link,
        ),
        _ActionTile(
          icon: Icons.copy,
          title: 'Copy partner link',
          subtitle: 'Copy your invite URL to clipboard.',
          onTap: () {
            Clipboard.setData(ClipboardData(text: link));
            Get.snackbar(
              'Copied',
              link,
              snackPosition: SnackPosition.BOTTOM,
            );
          },
        ),
        _ActionTile(
          icon: Icons.play_arrow,
          title: 'Open levels',
          subtitle: 'Go to Easy Game program view.',
          onTap: () => Get.to(() => LevelsScreen()),
        ),
      ],
    );
  }
}

class NotifierBotScreen extends StatelessWidget {
  NotifierBotScreen({Key? key}) : super(key: key);

  final WalletConnectService walletService = Get.find<WalletConnectService>();

  @override
  Widget build(BuildContext context) {
    return _UtilityScaffold(
      title: 'Notifier Bot',
      icon: Icons.notifications,
      children: [
        Obx(
          () => _StatusCard(
            title: 'Wallet notifications',
            value: walletService.isConnected.value
                ? 'Ready for ${walletService.shortAddress}'
                : 'Connect wallet first',
            icon: Icons.account_circle,
          ),
        ),
        const _InfoBlock(
          title: 'Events to notify',
          text:
              'Level activation, matrix placement, referral reward, matrix reward, recycle, freeze, and unfreeze events.',
        ),
        _ActionTile(
          icon: Icons.settings,
          title: 'Notification settings',
          subtitle: 'Open preferences for notification channels.',
          onTap: () => Get.to(() => SettingsScreen()),
        ),
      ],
    );
  }
}

class SettingsScreen extends StatelessWidget {
  SettingsScreen({Key? key}) : super(key: key);

  final WalletConnectService walletService = Get.find<WalletConnectService>();

  @override
  Widget build(BuildContext context) {
    return _UtilityScaffold(
      title: 'Settings',
      icon: Icons.settings,
      children: [
        Obx(
          () => _StatusCard(
            title: 'Connected wallet',
            value: walletService.isConnected.value
                ? walletService.currentAddress.value
                : 'Not connected',
            icon: Icons.account_balance_wallet,
          ),
        ),
        Obx(
          () => _StatusCard(
            title: 'Chain ID',
            value: walletService.chainId.value?.toString() ?? 'Unknown',
            icon: Icons.language,
          ),
        ),
        _ActionTile(
          icon: Icons.network_check,
          title: 'Check network',
          subtitle: 'Validate Base Sepolia or Ganache.',
          onTap: () async {
            try {
              await walletService.ensureBaseSepolia();
              Get.snackbar(
                'Network OK',
                'Wallet is on a supported network.',
                snackPosition: SnackPosition.BOTTOM,
              );
            } catch (e) {
              Get.snackbar(
                'Network failed',
                '$e',
                snackPosition: SnackPosition.BOTTOM,
              );
            }
          },
        ),
        _ActionTile(
          icon: Icons.logout,
          title: 'Disconnect wallet',
          subtitle: 'Clear app wallet state and return home.',
          onTap: () {
            walletService.disconnectWallet();
            Get.offAllNamed('/home');
          },
        ),
      ],
    );
  }
}

class SupportScreen extends StatelessWidget {
  const SupportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _UtilityScaffold(
      title: 'Support',
      icon: Icons.support_agent,
      children: [
        const _InfoBlock(
          title: 'Support status',
          text:
              'Production support contacts are not configured in this build yet.',
        ),
        _ActionTile(
          icon: Icons.email,
          title: 'Email support',
          subtitle: 'Open a mail draft.',
          onTap: () => _openUri('mailto:support@express.game'),
        ),
        _ActionTile(
          icon: Icons.telegram,
          title: 'Telegram channel',
          subtitle: 'Open Telegram when the public channel is available.',
          onTap: () => _openUri('https://t.me/expressgame'),
        ),
      ],
    );
  }
}

class ExpressInfoScreen extends StatelessWidget {
  const ExpressInfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const _UtilityScaffold(
      title: 'About Easy Game',
      icon: Icons.school,
      children: [
        _InfoBlock(
          title: 'Smart contract game',
          text:
              'Easy Game is driven by the EasyGame contract. Activations, placements, referral payments, rewards, recycle, and freeze state are handled on-chain.',
        ),
        _InfoBlock(
          title: 'User flow',
          text:
              'Connect MetaMask, choose an available level, confirm the upline, and pay through the EasyGame contract.',
        ),
      ],
    );
  }
}

class RecentActivityScreen extends StatelessWidget {
  const RecentActivityScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const _UtilityScaffold(
      title: 'Recent activity',
      icon: Icons.history,
      children: [
        _InfoBlock(
          title: 'Current state',
          text:
              'The profile page shows demo recent activity. A full activity feed should read EasyGame events from an indexer or event service.',
        ),
        _InfoBlock(
          title: 'Events',
          text:
              'MatrixPlaced, MatrixRewardPaid, ReferralPaid, Recycled, LevelFrozen, and LevelUnfrozen are the core activity events.',
        ),
      ],
    );
  }
}

class _UtilityScaffold extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _UtilityScaffold({
    Key? key,
    required this.title,
    required this.icon,
    required this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: const BackButton(color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.08,
          vertical: 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blueAccent, size: 32),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatusCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Row(
        children: [
          Icon(icon, color: Colors.tealAccent, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;

  const _MetricCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121722),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A3145)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String title;
  final String text;

  const _InfoBlock({
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: Colors.white),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A3145)),
      ),
      child: child,
    );
  }
}

Future<void> _openUri(String value) async {
  final uri = Uri.parse(value);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    return;
  }
  Get.snackbar('Link unavailable', value, snackPosition: SnackPosition.BOTTOM);
}

class _StatisticsSnapshot {
  final String contractAddress;
  final int activeLevels;
  final int frozenLevels;
  final BigInt matrixNodes;
  final BigInt totalLevelCostWei;

  const _StatisticsSnapshot({
    required this.contractAddress,
    required this.activeLevels,
    required this.frozenLevels,
    required this.matrixNodes,
    required this.totalLevelCostWei,
  });
}

String _shortAddress(String address) {
  if (address.length <= 12) {
    return address;
  }
  return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
}

String _formatWei(BigInt wei) {
  final base = BigInt.from(10).pow(18);
  final whole = wei ~/ base;
  final fraction = (wei % base).toString().padLeft(18, '0');
  final trimmedFraction =
      fraction.substring(0, 4).replaceFirst(RegExp(r'0+$'), '');
  if (trimmedFraction.isEmpty) {
    return whole.toString();
  }
  return '$whole.$trimmedFraction';
}
