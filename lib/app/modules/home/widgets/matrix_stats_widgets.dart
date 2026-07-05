part of '../views/utility_screens.dart';

class _ArenaStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String delta;
  final Color color;

  const _ArenaStatCard({
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
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
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
              const SizedBox(height: 3),
              Text(
                title,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                delta,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PayoutDistributionPanel extends StatelessWidget {
  final BigInt totalPrizePoolWei;
  final String currency;

  const _PayoutDistributionPanel({
    required this.totalPrizePoolWei,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final rows = [
      _DistributionRow('stats.poolDraw'.tr, '75.5%', EasyGameTheme.teal, 0.755),
      _DistributionRow(
          'stats.directRef'.tr, '9.5%', EasyGameTheme.purple, 0.095),
      _DistributionRow(
          'stats.secondRef'.tr, '6%', const Color(0xFFA855F7), 0.06),
      _DistributionRow('stats.thirdRef'.tr, '4%', EasyGameTheme.blue, 0.04),
      _DistributionRow('stats.projectFee'.tr, '5%', Colors.white38, 0.05),
    ];

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.track_changes, color: EasyGameTheme.teal),
              const SizedBox(width: 10),
              Text(
                'stats.payoutDistribution'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 180,
            child: CustomPaint(
              painter: _DistributionDonutPainter(rows),
              child: Center(
                child: Text(
                  '${_formatWei(totalPrizePoolWei)}\n$currency',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final row in rows) _DistributionLine(row: row),
          const SizedBox(height: 10),
          Text(
            'stats.payoutHint'.tr,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelVolumePanel extends StatelessWidget {
  final List<_LevelArenaStat> rows;
  final String currency;

  const _LevelVolumePanel({
    required this.rows,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...rows]
      ..sort((a, b) => b.fillPercent.compareTo(a.fillPercent));
    final topRows = sorted.take(6).toList();

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'stats.levelVolume'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 170,
            width: double.infinity,
            child: CustomPaint(
              painter: _VolumeLinePainter(topRows),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'stats.topLevels'.tr,
            style: const TextStyle(
              color: Colors.white54,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          for (final row in topRows)
            _LevelProgressRow(row: row, currency: currency),
        ],
      ),
    );
  }
}

class _PowerChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _PowerChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: EasyGameTheme.cardDark,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: EasyGameTheme.borderSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: EasyGameTheme.teal, size: 16),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(width: 8),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _DistributionLine extends StatelessWidget {
  final _DistributionRow row;

  const _DistributionLine({required this.row});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: row.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              row.label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white54, fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            row.percent,
            style: TextStyle(color: row.color, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _LevelProgressRow extends StatelessWidget {
  final _LevelArenaStat row;
  final String currency;

  const _LevelProgressRow({
    required this.row,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              'Lvl ${row.level}',
              style: const TextStyle(
                  color: Colors.white54, fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (row.fillPercent / 100).clamp(0, 1),
                minHeight: 9,
                backgroundColor: const Color(0xFF2A2948),
                valueColor: const AlwaysStoppedAnimation(EasyGameTheme.teal),
              ),
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 62,
            child: Text(
              '${row.fillPercent.toStringAsFixed(2)}%',
              textAlign: TextAlign.right,
              style: const TextStyle(
                  color: Colors.white54, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              '${_formatWei(row.priceWei)} $currency',
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: EasyGameTheme.gold, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _DistributionDonutPainter extends CustomPainter {
  final List<_DistributionRow> rows;

  const _DistributionDonutPainter(this.rows);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = math.min(size.width, size.height) * 0.16;
    final rect = Offset.zero & size;
    final circleRect = Rect.fromCenter(
      center: rect.center,
      width: math.min(size.width, size.height) - stroke,
      height: math.min(size.width, size.height) - stroke,
    );
    var start = -math.pi / 2;
    for (final row in rows) {
      final sweep = row.ratio * math.pi * 2;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt
        ..color = row.color;
      canvas.drawArc(circleRect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DistributionDonutPainter oldDelegate) =>
      oldDelegate.rows != rows;
}

class _VolumeLinePainter extends CustomPainter {
  final List<_LevelArenaStat> rows;

  const _VolumeLinePainter(this.rows);

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = size.height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (rows.isEmpty) {
      return;
    }

    final path = Path();
    for (var i = 0; i < rows.length; i++) {
      final x = rows.length == 1 ? 0.0 : size.width * i / (rows.length - 1);
      final y = size.height * (1 - (rows[i].fillPercent.clamp(0, 100) / 100));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          EasyGameTheme.teal.withValues(alpha: 0.25),
          EasyGameTheme.teal.withValues(alpha: 0.02),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = EasyGameTheme.teal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _VolumeLinePainter oldDelegate) =>
      oldDelegate.rows != rows;
}
