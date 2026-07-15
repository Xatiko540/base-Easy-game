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
              const Icon(CupertinoIcons.location, color: EasyGameTheme.teal),
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

class _LevelVolumePanel extends StatefulWidget {
  final List<_LevelArenaStat> rows;
  final String currency;

  const _LevelVolumePanel({
    required this.rows,
    required this.currency,
  });

  @override
  State<_LevelVolumePanel> createState() => _LevelVolumePanelState();
}

class _LevelVolumePanelState extends State<_LevelVolumePanel> {
  int? _highlightedIndex;
  late DateTimeRange _selectedPeriod;

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    _selectedPeriod = DateTimeRange(
      start: DateTime(today.year, today.month - 5, 1),
      end: today,
    );
  }

  Future<void> _openCalendar() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year - 3),
      lastDate: today,
      initialDateRange: _selectedPeriod,
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: const ColorScheme.dark(
              primary: EasyGameTheme.teal,
              onPrimary: Color(0xFF071A18),
              surface: Color(0xFF1C1C2D),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF1C1C2D),
            ),
          ),
          child: child!,
        );
      },
    );
    if (selected != null && mounted) {
      setState(() => _selectedPeriod = selected);
    }
  }

  void _highlightAt(Offset position, double width, int itemCount) {
    if (itemCount == 0) return;
    final plotWidth = math.max(1.0, width - 62);
    final relativeX = (position.dx - 46).clamp(0.0, plotWidth);
    final index =
        itemCount == 1 ? 0 : (relativeX / plotWidth * (itemCount - 1)).round();
    if (_highlightedIndex != index) {
      setState(() => _highlightedIndex = index);
    }
  }

  String _periodLabel(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    return '${localizations.formatCompactDate(_selectedPeriod.start)} — '
        '${localizations.formatCompactDate(_selectedPeriod.end)}';
  }

  @override
  Widget build(BuildContext context) {
    final rowsByLevel = {
      for (final row in widget.rows) row.level: row,
    };
    final allRows = List<_LevelArenaStat>.generate(17, (index) {
      final level = index + 1;
      return rowsByLevel[level] ??
          _LevelArenaStat(
            level: level,
            priceWei: BigInt.zero,
            activeCells: BigInt.zero,
            prizePoolWei: BigInt.zero,
            totalWeight: BigInt.zero,
          );
    });
    final chartRows = allRows;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 14,
            runSpacing: 12,
            children: [
              Text(
                'stats.levelVolume'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openCalendar,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: EasyGameTheme.teal.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: EasyGameTheme.teal.withValues(alpha: 0.34),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.calendar,
                          color: EasyGameTheme.teal,
                          size: 17,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _periodLabel(context),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 7),
                        const Icon(
                          CupertinoIcons.chevron_down,
                          color: EasyGameTheme.teal,
                          size: 13,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 250,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
            decoration: BoxDecoration(
              color: const Color(0xFF171727),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2B2B45)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return MouseRegion(
                  cursor: SystemMouseCursors.precise,
                  onHover: (event) => _highlightAt(
                    event.localPosition,
                    constraints.maxWidth,
                    chartRows.length,
                  ),
                  onExit: (_) {
                    if (_highlightedIndex != null) {
                      setState(() => _highlightedIndex = null);
                    }
                  },
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (details) => _highlightAt(
                      details.localPosition,
                      constraints.maxWidth,
                      chartRows.length,
                    ),
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _VolumeLinePainter(
                        rows: chartRows,
                        highlightedIndex: _highlightedIndex,
                        levelLabel: 'common.level'.tr,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'levels.allLevels'.tr,
            style: const TextStyle(
              color: Colors.white54,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          for (final row in allRows)
            _LevelProgressRow(row: row, currency: widget.currency),
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
  final int? highlightedIndex;
  final String levelLabel;

  const _VolumeLinePainter({
    required this.rows,
    required this.highlightedIndex,
    required this.levelLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const left = 46.0;
    const right = 16.0;
    const top = 14.0;
    const bottom = 34.0;
    final plotRect = Rect.fromLTRB(
      left,
      top,
      math.max(left, size.width - right),
      math.max(top, size.height - bottom),
    );
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    for (var i = 0; i < 5; i++) {
      final ratio = i / 4;
      final y = plotRect.bottom - plotRect.height * ratio;
      canvas.drawLine(
        Offset(plotRect.left, y),
        Offset(plotRect.right, y),
        gridPaint,
      );
      _drawText(
        canvas,
        '${(ratio * 100).round()}%',
        Offset(0, y - 7),
        const TextStyle(color: Colors.white38, fontSize: 10),
      );
    }

    if (rows.isEmpty) {
      return;
    }

    final points = <Offset>[];
    for (var i = 0; i < rows.length; i++) {
      final x = rows.length == 1
          ? plotRect.center.dx
          : plotRect.left + plotRect.width * i / (rows.length - 1);
      final ratio = rows[i].fillPercent.clamp(0, 100) / 100;
      points.add(Offset(x, plotRect.bottom - plotRect.height * ratio));
    }

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final controlX = (previous.dx + current.dx) / 2;
      path.cubicTo(
        controlX,
        previous.dy,
        controlX,
        current.dy,
        current.dx,
        current.dy,
      );
    }

    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, plotRect.bottom)
      ..lineTo(points.first.dx, plotRect.bottom)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          EasyGameTheme.teal.withValues(alpha: 0.25),
          EasyGameTheme.teal.withValues(alpha: 0.02),
        ],
      ).createShader(plotRect);
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = EasyGameTheme.teal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    final pointPaint = Paint()..color = EasyGameTheme.teal;
    for (final point in points) {
      canvas.drawCircle(point, 2.6, pointPaint);
    }

    final labelStep = size.width < 520 ? 4 : (rows.length > 10 ? 2 : 1);
    for (var i = 0; i < rows.length; i++) {
      if (i % labelStep != 0 && i != rows.length - 1) continue;
      final label = rows[i].level.toString();
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(points[i].dx - textPainter.width / 2, plotRect.bottom + 10),
      );
    }

    final selected = highlightedIndex;
    if (selected == null || selected < 0 || selected >= points.length) return;
    final point = points[selected];
    canvas.drawLine(
      Offset(point.dx, plotRect.top),
      Offset(point.dx, plotRect.bottom),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.48)
        ..strokeWidth = 1,
    );
    canvas.drawCircle(point, 7, Paint()..color = Colors.white);
    canvas.drawCircle(point, 4, Paint()..color = EasyGameTheme.teal);

    const tooltipWidth = 112.0;
    const tooltipHeight = 56.0;
    final tooltipLeft = (point.dx + 10)
        .clamp(plotRect.left, math.max(plotRect.left, size.width - 124))
        .toDouble();
    final tooltipTop = point.dy - tooltipHeight - 12 < plotRect.top
        ? point.dy + 12
        : point.dy - tooltipHeight - 12;
    final tooltipRect = Rect.fromLTWH(
      tooltipLeft,
      tooltipTop,
      tooltipWidth,
      tooltipHeight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(tooltipRect, const Radius.circular(10)),
      Paint()..color = const Color(0xFF10101C),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(tooltipRect, const Radius.circular(10)),
      Paint()
        ..color = const Color(0xFF393958)
        ..style = PaintingStyle.stroke,
    );
    _drawText(
      canvas,
      '$levelLabel ${rows[selected].level}',
      Offset(tooltipRect.left + 12, tooltipRect.top + 9),
      const TextStyle(color: Colors.white54, fontSize: 11),
    );
    _drawText(
      canvas,
      '${rows[selected].fillPercent.toStringAsFixed(2)}%',
      Offset(tooltipRect.left + 12, tooltipRect.top + 29),
      const TextStyle(
        color: EasyGameTheme.teal,
        fontSize: 14,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _VolumeLinePainter oldDelegate) =>
      oldDelegate.rows != rows ||
      oldDelegate.highlightedIndex != highlightedIndex ||
      oldDelegate.levelLabel != levelLabel;
}
