part of '../views/utility_screens.dart';

class _MatrixArenaPanel extends StatelessWidget {
  final _MatrixArenaSnapshot data;
  final String currency;
  final String selectedOpponent;
  final bool actionsBusy;
  final ValueChanged<String> onSelectOpponent;
  final VoidCallback onBuyFreeze;
  final VoidCallback onFreeze;
  final VoidCallback onUnfreeze;

  const _MatrixArenaPanel({
    required this.data,
    required this.currency,
    required this.selectedOpponent,
    required this.actionsBusy,
    required this.onSelectOpponent,
    required this.onBuyFreeze,
    required this.onFreeze,
    required this.onUnfreeze,
  });

  @override
  Widget build(BuildContext context) {
    final fill = data.fillPercent.clamp(0, 100).toDouble();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            EasyGameTheme.surface.withValues(alpha: 0.85),
            EasyGameTheme.cardDark.withValues(alpha: 0.92),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: EasyGameTheme.borderSoft.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 18,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              SizedBox(
                width: 300,
                child: Text(
                  'matrix.levelTitle'.trParams({'level': '${data.level}'}),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _MatrixMiniStat('${data.activeCells}', 'matrix.occupied'.tr,
                  Colors.greenAccent),
              _MatrixMiniStat(data.playerFrozen ? '1' : '0', 'common.frozen'.tr,
                  EasyGameTheme.teal),
              _MatrixMiniStat('${data.recycleCount}', 'matrix.recycle'.tr,
                  EasyGameTheme.orange),
            ],
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final treeSize =
                  (constraints.maxWidth * 0.92).clamp(280.0, 780.0);
              return SizedBox(
                height: treeSize,
                child: _MatrixTree(
                  data: data,
                  selectedOpponent: selectedOpponent,
                  onSelectOpponent: onSelectOpponent,
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          _MatrixProgressBar(
            label: 'matrix.levelFill'.trParams({'level': '${data.level}'}),
            percent: fill,
            endLabel: '${data.maxPlayers} ${'matrix.slots'.tr}',
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _PowerChip(
                icon: CupertinoIcons.star,
                label: 'levelDetail.prizePool'.tr,
                value: '${_formatWei(data.prizePoolWei)} $currency',
              ),
              _PowerChip(
                icon: CupertinoIcons.bolt,
                label: 'levelDetail.playerWeight'.tr,
                value: data.playerWeight.toString(),
              ),
              _PowerChip(
                icon: CupertinoIcons.percent,
                label: 'levelDetail.chance'.tr,
                value: _formatChance(data.chanceBps),
              ),
              _PowerChip(
                icon: CupertinoIcons.tray_full,
                label: 'levelDetail.boxTokens'.tr,
                value: data.boxTokens.toString(),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _ArenaSkillsPanel(
            data: data,
            selectedOpponent: selectedOpponent,
            actionsBusy: actionsBusy,
            onSelectOpponent: onSelectOpponent,
            onBuyFreeze: onBuyFreeze,
            onFreeze: onFreeze,
            onUnfreeze: onUnfreeze,
          ),
          const SizedBox(height: 18),
          _InfoBlock(
            title: 'matrix.howTitle'.tr,
            text: 'matrix.howText'.tr,
          ),
        ],
      ),
    );
  }
}

class _MatrixTree extends StatelessWidget {
  final _MatrixArenaSnapshot data;
  final String selectedOpponent;
  final ValueChanged<String> onSelectOpponent;

  const _MatrixTree({
    required this.data,
    required this.selectedOpponent,
    required this.onSelectOpponent,
  });

  @override
  Widget build(BuildContext context) {
    final states = _buildCellStates(data, selectedOpponent);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: NeonHoneycomb(
              zoomFactor: 1.0,
              states: states,
              onCellTap: (cellId) {
                final participant = data.participantAt(cellId);
                if (participant != null &&
                    !participant.isCurrentPlayer &&
                    participant.skillStatus?.immune != true) {
                  onSelectOpponent(participant.wallet);
                }
              },
            ),
          ),
        );
      },
    );
  }
}

class _MatrixUnavailablePanel extends StatelessWidget {
  const _MatrixUnavailablePanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 320),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: EasyGameTheme.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: EasyGameTheme.borderSoft),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.calendar_badge_minus,
            color: EasyGameTheme.orange,
            size: 46,
          ),
          const SizedBox(height: 16),
          Text(
            'matrix.noRoundTitle'.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'matrix.noRoundText'.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _MatrixMiniStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _MatrixMiniStat(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ],
    );
  }
}

class _MatrixNodeIcon extends StatelessWidget {
  final Color color;
  final IconData icon;
  final bool small;

  const _MatrixNodeIcon({
    required this.color,
    required this.icon,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = small ? 26.0 : 48.0;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MatrixHexCellPainter(
          color: color,
          strokeWidth: small ? 2 : 3,
        ),
        child: Icon(
          icon,
          color: color,
          size: small ? 15 : 23,
        ),
      ),
    );
  }
}

class _MatrixHexCellPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const _MatrixHexCellPainter({
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = _hexPath(size).shift(const Offset(0, 1));
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.24)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.24),
            EasyGameTheme.cardDark.withValues(alpha: 0.94),
            color.withValues(alpha: 0.12),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.round
        ..color = color.withValues(alpha: 0.95),
    );
  }

  Path _hexPath(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.50, 0)
      ..lineTo(w * 0.92, h * 0.24)
      ..lineTo(w * 0.92, h * 0.76)
      ..lineTo(w * 0.50, h)
      ..lineTo(w * 0.08, h * 0.76)
      ..lineTo(w * 0.08, h * 0.24)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _MatrixHexCellPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}

class _MatrixProgressBar extends StatelessWidget {
  final String label;
  final double percent;
  final String endLabel;

  const _MatrixProgressBar({
    required this.label,
    required this.percent,
    required this.endLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EasyGameTheme.cardDark.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EasyGameTheme.borderSoft),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${percent.toStringAsFixed(2)}%',
                style: const TextStyle(
                  color: EasyGameTheme.teal,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 12,
              value: (percent / 100).clamp(0, 1),
              backgroundColor: const Color(0xFF2A2948),
              valueColor: const AlwaysStoppedAnimation(EasyGameTheme.teal),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text('0',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
              const Spacer(),
              Text(endLabel,
                  style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
