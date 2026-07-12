part of '../views/levels.dart';

class _LevelMatrixPanel extends StatelessWidget {
  final int level;
  final BigInt positionId;
  final BigInt nextOpenParentId;
  final BigInt nextCellId;
  final BigInt activeCells;
  final bool isFrozen;

  const _LevelMatrixPanel({
    required this.level,
    required this.positionId,
    required this.nextOpenParentId,
    required this.nextCellId,
    required this.activeCells,
    required this.isFrozen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: EasyGameTheme.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EasyGameTheme.borderSoft),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 760;
          final diagram = Container(
            height: narrow ? 260 : 320,
            decoration: BoxDecoration(
              color: EasyGameTheme.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: EasyGameTheme.teal.withValues(alpha: 0.28),
              ),
            ),
            child: CustomPaint(
              painter: _BinaryMatrixPainter(
                activeCells: activeCells,
                positionId: positionId,
                nextCellId: nextCellId,
              ),
              child: const SizedBox.expand(),
            ),
          );
          final details = _LevelDetailPanel(
            title: 'levelDetail.matrixSnapshot'.tr,
            rows: [
              DetailRow('common.level'.tr, '$level'),
              DetailRow('levelDetail.currentCell'.tr, positionId.toString()),
              DetailRow(
                'levelDetail.nextOpenParent'.tr,
                nextOpenParentId.toString(),
              ),
              DetailRow('levelDetail.nextCell'.tr, nextCellId.toString()),
              DetailRow('levelDetail.activeCells'.tr, activeCells.toString()),
              DetailRow(
                'common.frozen'.tr,
                isFrozen ? 'common.yes'.tr : 'common.no'.tr,
              ),
            ],
          );

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'levelDetail.binaryPlacement'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                diagram,
                const SizedBox(height: 12),
                details,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: diagram),
              const SizedBox(width: 14),
              Expanded(flex: 2, child: details),
            ],
          );
        },
      ),
    );
  }
}

class _BinaryMatrixPainter extends CustomPainter {
  final BigInt activeCells;
  final BigInt positionId;
  final BigInt nextCellId;

  const _BinaryMatrixPainter({
    required this.activeCells,
    required this.positionId,
    required this.nextCellId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final nodes = <int, Offset>{
      1: Offset(size.width * 0.5, size.height * 0.14),
      2: Offset(size.width * 0.28, size.height * 0.43),
      3: Offset(size.width * 0.72, size.height * 0.43),
      4: Offset(size.width * 0.15, size.height * 0.75),
      5: Offset(size.width * 0.39, size.height * 0.75),
      6: Offset(size.width * 0.61, size.height * 0.75),
      7: Offset(size.width * 0.85, size.height * 0.75),
    };

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 2;
    for (final edge in const [
      [1, 2],
      [1, 3],
      [2, 4],
      [2, 5],
      [3, 6],
      [3, 7],
    ]) {
      canvas.drawLine(nodes[edge[0]]!, nodes[edge[1]]!, linePaint);
    }

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (final entry in nodes.entries) {
      final cellId = entry.key;
      final center = entry.value;
      final isActive = activeCells >= BigInt.from(cellId);
      final isCurrent = positionId == BigInt.from(cellId);
      final isNext = nextCellId == BigInt.from(cellId);
      final isPrize = cellId == 7;
      final cellSize = isCurrent ? const Size(56, 50) : const Size(48, 43);
      final fill = isCurrent
          ? EasyGameTheme.teal
          : isNext
              ? EasyGameTheme.purple
              : isPrize
                  ? EasyGameTheme.gold
                  : isActive
                      ? const Color(0xFF6E7477)
                      : const Color(0xFF242729);
      final border = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isCurrent ? 3 : 2
        ..strokeJoin = StrokeJoin.round
        ..color = isCurrent
            ? Colors.white
            : EasyGameTheme.teal.withValues(alpha: 0.48);

      final rect = Rect.fromCenter(
        center: center,
        width: cellSize.width,
        height: cellSize.height,
      );
      final path = _hexPath(rect.size).shift(rect.topLeft);
      canvas.drawPath(
        path,
        Paint()
          ..color = fill.withValues(alpha: isActive || isCurrent ? 0.24 : 0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      canvas.drawPath(path, Paint()..color = fill);
      canvas.drawPath(path, border);

      textPainter.text = TextSpan(
        text: '$cellId',
        style: TextStyle(
          color: isPrize ? Colors.black : Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        center - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }

    final labelPaint = TextPainter(
      text: TextSpan(
        text: 'levelDetail.prizeCells'.tr,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.42),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 28);
    labelPaint.paint(canvas, const Offset(14, 14));
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
  bool shouldRepaint(covariant _BinaryMatrixPainter oldDelegate) {
    return oldDelegate.activeCells != activeCells ||
        oldDelegate.positionId != positionId ||
        oldDelegate.nextCellId != nextCellId;
  }
}
