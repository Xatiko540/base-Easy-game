part of '../views/profilescreen.dart';

class _ProfileHeader extends StatelessWidget {
  final String profileId;
  final ProfileDashboardSnapshot data;
  final String referralLink;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  const _ProfileHeader({
    required this.profileId,
    required this.data,
    required this.referralLink,
    required this.onCopy,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 760;
        final profile = _UserIdentity(
          profileId: profileId,
          data: data,
        );
        final link = _ReferralCard(
          referralLink: referralLink,
          onCopy: onCopy,
          onShare: onShare,
        );

        if (stacked) {
          return Column(
            children: [
              profile,
              const SizedBox(height: 14),
              link,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: profile),
            const SizedBox(width: 22),
            SizedBox(width: 430, child: link),
          ],
        );
      },
    );
  }
}

class _UserIdentity extends StatelessWidget {
  final String profileId;
  final ProfileDashboardSnapshot data;

  const _UserIdentity({
    required this.profileId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final walletService = Get.find<WalletConnectService>();
    return Obx(
      () {
        final sessionStatus = resolveProfileSessionStatus(
          walletConnected: walletService.isConnected.value &&
              walletService.currentAddress.value.isNotEmpty,
          playerExists: data.player?.exists == true,
        );
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: EasyGameTheme.surface.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: EasyGameTheme.border),
          ),
          child: Row(
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF26312D),
                  border: Border.all(color: const Color(0xFF33413C), width: 8),
                  boxShadow: [
                    BoxShadow(
                      color: EasyGameTheme.teal.withValues(alpha: 0.18),
                      blurRadius: 28,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.person,
                  color: Color(0xFF63D3BE),
                  size: 46,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'ID $profileId',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        _StatusPill(
                          label: _profileSessionLabel(sessionStatus),
                          color:
                              sessionStatus == ProfileSessionStatus.disconnected
                                  ? EasyGameTheme.gold
                                  : EasyGameTheme.teal,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      walletService.isConnected.value
                          ? walletService.currentAddress.value
                          : 'common.walletNotConnected'.tr,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        _MiniStat(
                          label: 'profile.totalWeight'.tr,
                          value: data.player?.totalWeight.toString() ?? '0',
                        ),
                        _MiniStat(
                          label: 'levelDetail.boxTokens'.tr,
                          value: data.boxTokens.toString(),
                        ),
                        _MiniStat(
                          label: 'profile.cycles'.tr,
                          value: data.recycleCount.toString(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      walletService.authProviderLabel,
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                    if (sessionStatus == ProfileSessionStatus.connected) ...[
                      const SizedBox(height: 4),
                      Text(
                        'profile.activateToRegister'.tr,
                        style: const TextStyle(
                          color: EasyGameTheme.gold,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

String _profileSessionLabel(ProfileSessionStatus status) {
  switch (status) {
    case ProfileSessionStatus.disconnected:
      return 'common.notLoggedIn'.tr;
    case ProfileSessionStatus.connected:
      return 'profile.walletConnected'.tr;
    case ProfileSessionStatus.registered:
      return 'profile.registered'.tr;
  }
}

class _ReferralCard extends StatelessWidget {
  final String referralLink;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  const _ReferralCard({
    required this.referralLink,
    required this.onCopy,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF18203A), Color(0xFF101523)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'profile.personalLink'.tr,
            style: const TextStyle(
                color: Colors.white70, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            referralLink.replaceFirst('https://', ''),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF4D78FF),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _SmallAction(
                label: 'common.copy'.tr,
                onTap: onCopy,
              ),
              const SizedBox(width: 8),
              _SmallAction(
                label: 'common.share'.tr,
                onTap: onShare,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
