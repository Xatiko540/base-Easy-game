part of '../views/start_page.dart';

class _HeroPanel extends StatelessWidget {
  final VoidCallback onConnect;

  const _HeroPanel({
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final walletService = Get.find<WalletConnectService>();
    final authController = Get.find<WalletAuthController>();
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 260),
      padding: const EdgeInsets.fromLTRB(34, 34, 34, 30),
      decoration: BoxDecoration(
        color: const Color(0xFF071011),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: EasyGameTheme.teal.withValues(alpha: 0.16),
            blurRadius: 40,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          return Flex(
            direction: compact ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: compact ? 0 : 6,
                child: Column(
                  crossAxisAlignment: compact
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: EasyGameTheme.blue.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: EasyGameTheme.purple.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Text(
                        'start.baseBlockchain'.tr,
                        style: TextStyle(
                          color: EasyGameTheme.tealSoft.withValues(alpha: 0.95),
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'start.heroTitle'.tr,
                      textAlign: compact ? TextAlign.center : TextAlign.left,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        height: 1.02,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'start.heroSubtitle'.tr,
                      textAlign: compact ? TextAlign.center : TextAlign.left,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment:
                          compact ? WrapAlignment.center : WrapAlignment.start,
                      children: [
                        _GradientButton(
                          onTap: onConnect,
                          child: Obx(
                            () => Text(
                              walletService.isConnecting.value
                                  ? 'top.signingIn'.tr
                                  : authController.isAuthenticated
                                      ? 'top.enterAccount'.tr
                                      : 'start.connectWallet'.tr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        _OutlineButton(
                          label: 'start.helpMe'.tr,
                          icon: CupertinoIcons.play_arrow,
                          onTap: UiNavigationService.openInformation,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!compact) const SizedBox(width: 32),
              Expanded(
                flex: compact ? 0 : 4,
                child: Padding(
                  padding: EdgeInsets.only(top: compact ? 28 : 0),
                  child: const _HeroMatrixPreview(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeroMatrixPreview extends StatelessWidget {
  const _HeroMatrixPreview();

  Map<String, CellState> _buildPreviewStates() {
    return {
      '0:-2': CellState.goldUser,
      '-1:-1': CellState.purpleStar,
      '1:-1': CellState.cyanUser,
      '-2:0': CellState.greenUser,
      '0:0': CellState.cyanGlow,
      '2:0': CellState.greenGlow,
      '-2:1': CellState.inactive,
      '-1:1': CellState.inactive,
      '1:1': CellState.inactive,
      '2:1': CellState.inactive,
      '-2:2': CellState.inactive,
      '-1:2': CellState.inactive,
      '0:2': CellState.inactive,
      '1:2': CellState.inactive,
      '2:2': CellState.inactive,
    };
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.28,
      child: NeonHoneycomb(
        padding: 12,
        states: _buildPreviewStates(),
      ),
    );
  }
}
