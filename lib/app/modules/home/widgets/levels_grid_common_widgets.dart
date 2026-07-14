part of '../views/levels.dart';

class _CardHeader extends StatelessWidget {
  final int level;
  final double coin;

  const _CardHeader({
    required this.level,
    required this.coin,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Lvl $level',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFB2B2B2),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const _CoinIcon(size: 14),
        const SizedBox(width: 5),
        Text(
          formatLevelPrice(coin),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _CoinIcon extends StatelessWidget {
  final double size;

  const _CoinIcon({this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFF7C948),
        shape: BoxShape.circle,
      ),
      child: Icon(
        CupertinoIcons.ticket,
        size: size * 0.68,
        color: Colors.white,
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double value;

  const _ProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0, 1).toDouble();
    return Stack(
      children: [
        Container(
          height: 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: const Color(0xFF45D0B7), width: 1),
            color: const Color(0xFF262626),
          ),
        ),
        FractionallySizedBox(
          widthFactor: clamped,
          child: Container(
            height: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFB314D4),
                  Color(0xFF586EDB),
                  Color(0xFF63D3BE),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MatrixCellGlyph extends StatelessWidget {
  final double size;

  const _MatrixCellGlyph({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.9,
      child: CustomPaint(
        painter: _MatrixCellGlyphPainter(
          color: Colors.white.withValues(alpha: 0.16),
        ),
      ),
    );
  }
}

class _MatrixCellGlyphPainter extends CustomPainter {
  final Color color;

  const _MatrixCellGlyphPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = _hexPath(size);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
    canvas.drawPath(
      path.shift(Offset(size.width * 0.35, size.height * 0.30)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeJoin = StrokeJoin.round
        ..color = color.withValues(alpha: 0.75),
    );
  }

  Path _hexPath(Size size) {
    final w = size.width * 0.62;
    final h = size.height * 0.68;
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
  bool shouldRepaint(covariant _MatrixCellGlyphPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _GradientActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GradientActionButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFB314D4),
              Color(0xFF586EDB),
              Color(0xFF00A99D),
            ],
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _SmallMetric extends StatelessWidget {
  final String value;
  final String label;
  final bool alignEnd;

  const _SmallMetric({
    required this.value,
    required this.label,
    required this.alignEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFAAAAAA),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _WeightStrip extends StatelessWidget {
  final BigInt weight;
  final BigInt chanceBps;
  final BigInt totalWeight;

  const _WeightStrip({
    required this.weight,
    required this.chanceBps,
    required this.totalWeight,
  });

  @override
  Widget build(BuildContext context) {
    final chance = chanceBps.toDouble() / 100;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: EasyGameTheme.surfaceHigh.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TinyStat(
              label: 'levelDetail.playerWeight'.tr,
              value: weight == BigInt.zero ? '-' : weight.toString(),
            ),
          ),
          Container(
            width: 1,
            height: 24,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          Expanded(
            child: _TinyStat(
              label: 'levelDetail.chance'.tr,
              value: chanceBps == BigInt.zero
                  ? '-'
                  : '${chance.toStringAsFixed(2)}%',
              alignEnd: true,
            ),
          ),
          if (totalWeight > BigInt.zero) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: 'levelDetail.totalLevelWeightHint'
                  .trParams({'weight': '$totalWeight'}),
              child: const Icon(
                CupertinoIcons.info,
                size: 14,
                color: Colors.white38,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TinyStat extends StatelessWidget {
  final String label;
  final String value;
  final bool alignEnd;

  const _TinyStat({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
