part of '../views/start_page.dart';

class _HeroPanel extends StatelessWidget {
  final VoidCallback onConnect;

  const _HeroPanel({
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final walletService = Get.find<WalletConnectService>();
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
                                  : walletService.isConnected.value
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
                          icon: Icons.play_arrow_rounded,
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

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.28,
      child: CustomPaint(
        painter: _MatrixPreviewPainter(),
        child: Center(
          child: Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: EasyGameTheme.surfaceHigh,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: EasyGameTheme.teal.withValues(alpha: 0.28),
                  blurRadius: 28,
                ),
              ],
            ),
            child: const Icon(
              Icons.account_tree_rounded,
              color: EasyGameTheme.tealSoft,
              size: 44,
            ),
          ),
        ),
      ),
    );
  }
}

class _MatrixPreviewPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..strokeWidth = 1.4;
    final nodes = <Offset>[
      Offset(size.width * 0.5, size.height * 0.22),
      Offset(size.width * 0.26, size.height * 0.48),
      Offset(size.width * 0.74, size.height * 0.48),
      Offset(size.width * 0.14, size.height * 0.76),
      Offset(size.width * 0.38, size.height * 0.76),
      Offset(size.width * 0.62, size.height * 0.76),
      Offset(size.width * 0.86, size.height * 0.76),
    ];
    final links = const [
      [0, 1],
      [0, 2],
      [1, 3],
      [1, 4],
      [2, 5],
      [2, 6],
    ];
    for (final link in links) {
      canvas.drawLine(nodes[link[0]], nodes[link[1]], linePaint);
    }
    for (var i = 0; i < nodes.length; i++) {
      final paint = Paint()
        ..color = i == 0
            ? EasyGameTheme.gold
            : i.isEven
                ? EasyGameTheme.purple
                : EasyGameTheme.teal;
      canvas.drawCircle(nodes[i], i == 0 ? 16 : 13, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
