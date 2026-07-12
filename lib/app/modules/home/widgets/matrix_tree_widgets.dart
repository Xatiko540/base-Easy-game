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
  final VoidCallback onSettle;
  final VoidCallback onClaimSettlement;

  const _MatrixArenaPanel({
    required this.data,
    required this.currency,
    required this.selectedOpponent,
    required this.actionsBusy,
    required this.onSelectOpponent,
    required this.onBuyFreeze,
    required this.onFreeze,
    required this.onUnfreeze,
    required this.onSettle,
    required this.onClaimSettlement,
  });

  @override
  Widget build(BuildContext context) {
    final fill = data.fillPercent.clamp(0, 100).toDouble();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C2D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2B2B45)),
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
          SizedBox(
            height: 300,
            child: _MatrixTree(
              data: data,
              selectedOpponent: selectedOpponent,
              onSelectOpponent: onSelectOpponent,
            ),
          ),
          const SizedBox(height: 18),
          _MatrixProgressBar(
            label: 'matrix.levelFill'.trParams({'level': '${data.level}'}),
            percent: fill,
            endLabel: '2^${data.level} ${'matrix.slots'.tr}',
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
          _RoundSettlementPanel(
            data: data,
            actionsBusy: actionsBusy,
            onSettle: onSettle,
            onClaim: onClaimSettlement,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final compact = w < 520;
        final nodeRadius = compact ? 13.0 : 24.0;
        final nodes = <_TreeNodeSpec>[
          _TreeNodeSpec(1, Offset(w * 0.5, h * 0.14)),
          _TreeNodeSpec(2, Offset(w * 0.34, h * 0.43)),
          _TreeNodeSpec(3, Offset(w * 0.66, h * 0.43)),
          _TreeNodeSpec(4, Offset(w * 0.25, h * 0.68)),
          _TreeNodeSpec(5, Offset(w * 0.42, h * 0.68)),
          _TreeNodeSpec(6, Offset(w * 0.58, h * 0.68)),
          _TreeNodeSpec(7, Offset(w * 0.75, h * 0.68)),
          _TreeNodeSpec(8, Offset(w * 0.20, h * 0.92)),
          _TreeNodeSpec(9, Offset(w * 0.30, h * 0.92)),
          _TreeNodeSpec(10, Offset(w * 0.38, h * 0.92)),
          _TreeNodeSpec(11, Offset(w * 0.48, h * 0.92)),
          _TreeNodeSpec(12, Offset(w * 0.56, h * 0.92)),
          _TreeNodeSpec(13, Offset(w * 0.66, h * 0.92)),
          _TreeNodeSpec(14, Offset(w * 0.74, h * 0.92)),
          _TreeNodeSpec(15, Offset(w * 0.84, h * 0.92)),
        ];
        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _MatrixLinesPainter(nodes)),
            ),
            for (final node in nodes)
              Positioned(
                left: node.position.dx - nodeRadius,
                top: node.position.dy - nodeRadius,
                child: GestureDetector(
                  onTap: () {
                    final participant = data.participantAt(node.cellId);
                    if (participant != null && !participant.isCurrentPlayer) {
                      onSelectOpponent(participant.wallet);
                    }
                  },
                  child: _MatrixNodeIcon(
                    color: _nodeColor(node.cellId, data),
                    icon: _nodeIcon(node.cellId, data),
                    muted: BigInt.from(node.cellId) > data.activeCells &&
                        BigInt.from(node.cellId) != data.nextOpenParentId,
                    small: compact,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Color _nodeColor(int cellId, _MatrixArenaSnapshot data) {
    final participant = data.participantAt(cellId);
    if (participant?.wallet.toLowerCase() == selectedOpponent.toLowerCase()) {
      return Colors.redAccent;
    }
    if (participant?.skillStatus?.frozen == true) return Colors.lightBlueAccent;
    if (participant?.isInvited == true) return EasyGameTheme.purple;
    final id = BigInt.from(cellId);
    if (data.playerFrozen && data.playerCellId == id) return EasyGameTheme.teal;
    if (data.playerCellId == id) return EasyGameTheme.teal;
    if (cellId == 7 || cellId == 15) return EasyGameTheme.gold;
    if (data.nextOpenParentId == id) return EasyGameTheme.orange;
    if (id <= data.activeCells) return Colors.greenAccent;
    return Colors.white24;
  }

  IconData _nodeIcon(int cellId, _MatrixArenaSnapshot data) {
    final id = BigInt.from(cellId);
    if (data.playerFrozen && data.playerCellId == id) return CupertinoIcons.snow;
    if (cellId == 7 || cellId == 15) return CupertinoIcons.star;
    if (data.nextOpenParentId == id) return CupertinoIcons.refresh;
    if (id <= data.activeCells || data.playerCellId == id) {
      return CupertinoIcons.person;
    }
    return CupertinoIcons.circle;
  }
}

class _MatrixNodeIcon extends StatelessWidget {
  final Color color;
  final IconData icon;
  final bool small;
  final bool muted;

  const _MatrixNodeIcon({
    required this.color,
    required this.icon,
    this.small = false,
    this.muted = false,
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
          muted: muted,
          strokeWidth: small ? 2 : 3,
        ),
        child: Icon(
          icon,
          color: color.withValues(alpha: muted ? 0.55 : 1),
          size: small ? 15 : 23,
        ),
      ),
    );
  }
}

class _MatrixHexCellPainter extends CustomPainter {
  final Color color;
  final bool muted;
  final double strokeWidth;

  const _MatrixHexCellPainter({
    required this.color,
    required this.muted,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = _hexPath(size).shift(const Offset(0, 1));
    if (!muted) {
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.24)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: muted ? 0.05 : 0.24),
            EasyGameTheme.cardDark.withValues(alpha: 0.94),
            color.withValues(alpha: muted ? 0.04 : 0.12),
          ],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.round
        ..color = color.withValues(alpha: muted ? 0.35 : 0.95),
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
    return oldDelegate.color != color ||
        oldDelegate.muted != muted ||
        oldDelegate.strokeWidth != strokeWidth;
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

class _MatrixLinesPainter extends CustomPainter {
  final List<_TreeNodeSpec> nodes;

  const _MatrixLinesPainter(this.nodes);

  @override
  void paint(Canvas canvas, Size size) {
    final map = {for (final node in nodes) node.cellId: node.position};
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 2;
    for (final entry in map.entries) {
      final left = entry.key * 2;
      final right = left + 1;
      if (map.containsKey(left)) {
        canvas.drawLine(entry.value, map[left]!, paint);
      }
      if (map.containsKey(right)) {
        canvas.drawLine(entry.value, map[right]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MatrixLinesPainter oldDelegate) =>
      oldDelegate.nodes != nodes;
}
