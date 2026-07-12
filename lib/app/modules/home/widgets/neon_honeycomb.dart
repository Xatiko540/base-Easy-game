import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Публичное перечисление состояний ячейки соты.
enum CellState {
  inactive,
  cyanUser,
  greenUser,
  blueUser,
  goldUser,
  purpleStar,
  cyanGlow,
  greenGlow,
  blueGlow,
  goldGlow,
  purpleGlow,
}

class CellVisual {
  const CellVisual({
    required this.active,
    required this.color,
    required this.fillColor,
  });
  const CellVisual.active({
    required this.color,
    required this.fillColor,
  }) : active = true;
  final bool active;
  final Color color;
  final Color fillColor;
}

class _HexCell {
  const _HexCell({required this.q, required this.r, required this.state});
  final int q;
  final int r;
  final CellState state;
}

class _GridBounds {
  const _GridBounds({
    required this.minX,
    required this.minY,
    required this.widthFactor,
    required this.heightFactor,
  });
  final double minX;
  final double minY;
  final double widthFactor;
  final double heightFactor;
}

_GridBounds _calcGridBounds(List<_HexCell> cells) {
  double minX = double.infinity;
  double minY = double.infinity;
  double maxX = double.negativeInfinity;
  double maxY = double.negativeInfinity;
  for (final cell in cells) {
    final x = 1.5 * cell.q;
    final y = math.sqrt(3) * (cell.r + cell.q / 2);
    minX = math.min(minX, x - 1);
    maxX = math.max(maxX, x + 1);
    minY = math.min(minY, y - math.sqrt(3) / 2);
    maxY = math.max(maxY, y + math.sqrt(3) / 2);
  }
  return _GridBounds(
    minX: minX,
    minY: minY,
    widthFactor: maxX - minX,
    heightFactor: maxY - minY,
  );
}

Offset _axialPixel({
  required int q,
  required int r,
  required double radius,
  required Offset offset,
}) {
  final x = radius * 1.5 * q;
  final y = radius * math.sqrt(3) * (r + q / 2);
  return Offset(offset.dx + x, offset.dy + y);
}

Path _hexPath({required Offset center, required double radius}) {
  final path = Path();
  for (int i = 0; i < 6; i++) {
    final angle = math.pi / 3 * i;
    final point = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
    if (i == 0) {
      path.moveTo(point.dx, point.dy);
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }
  path.close();
  return path;
}

CellVisual _visualForState(CellState state) {
  switch (state) {
    case CellState.cyanUser:
    case CellState.cyanGlow:
      return CellVisual.active(
        color: const Color(0xFF20C7AD),
        fillColor: const Color(0xFF123B3D),
      );
    case CellState.greenUser:
    case CellState.greenGlow:
      return CellVisual.active(
        color: const Color(0xFF5ED6C1),
        fillColor: const Color(0xFF10372D),
      );
    case CellState.blueUser:
    case CellState.blueGlow:
      return CellVisual.active(
        color: const Color(0xFF426CF8),
        fillColor: const Color(0xFF102D45),
      );
    case CellState.purpleStar:
    case CellState.purpleGlow:
      return CellVisual.active(
        color: const Color(0xFF9B16C9),
        fillColor: const Color(0xFF30203D),
      );
    case CellState.goldUser:
    case CellState.goldGlow:
      return CellVisual.active(
        color: const Color(0xFFF7C948),
        fillColor: const Color(0xFF3B3217),
      );
    case CellState.inactive:
      return const CellVisual(
        active: false,
        color: Color(0xFF607883),
        fillColor: Color(0xFF18232A),
      );
  }
}

class NeonHoneycombPainter extends CustomPainter {
  NeonHoneycombPainter({
    required this.backgroundColor,
    required this.padding,
    required this.states,
    this.zoomFactor = 1,
  });

  final Color backgroundColor;
  final double padding;
  final Map<String, CellState> states;
  final double zoomFactor;

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackground(canvas, size);
    final cells = _buildCells();
    if (cells.isEmpty) return;
    final bounds = _calcGridBounds(cells);
    final availableWidth = size.width - padding * 2;
    final availableHeight = size.height - padding * 2;
    final rw = availableWidth / bounds.widthFactor;
    final rh = availableHeight / bounds.heightFactor;
    final radius = math.min(rw, rh) * zoomFactor;
    final gridPixelWidth = bounds.widthFactor * radius;
    final gridPixelHeight = bounds.heightFactor * radius;
    final offset = Offset(
      (size.width - gridPixelWidth) / 2 - bounds.minX * radius,
      (size.height - gridPixelHeight) / 2 - bounds.minY * radius,
    );
    for (final cell in cells) {
      final center = _axialPixel(
        q: cell.q,
        r: cell.r,
        radius: radius,
        offset: offset,
      );
      _drawCell(
        canvas: canvas,
        center: center,
        radius: radius * 0.97,
        cell: cell,
      );
    }
    _drawIridescentOverlay(canvas, size);
  }

  void _paintBackground(Canvas canvas, Size size) {
    final radialGradient = RadialGradient(
      colors: [
        const Color(0xFF20C7AD).withValues(alpha: 0.06),
        Colors.transparent,
      ],
      stops: const [0, 1],
    );
    canvas.drawCircle(
      size.center(Offset.zero),
      size.shortestSide * 0.48,
      Paint()
        ..shader = radialGradient.createShader(
          Rect.fromCircle(
            center: size.center(Offset.zero),
            radius: size.shortestSide * 0.48,
          ),
        ),
    );
  }

  List<_HexCell> _buildCells() {
    const gridRadius = 6;
    final cells = <_HexCell>[];
    for (int q = -gridRadius; q <= gridRadius; q++) {
      final minR = math.max(-gridRadius, -q - gridRadius);
      final maxR = math.min(gridRadius, -q + gridRadius);
      for (int r = minR; r <= maxR; r++) {
        cells.add(
          _HexCell(
            q: q,
            r: r,
            state: states['$q:$r'] ?? CellState.inactive,
          ),
        );
      }
    }
    return cells;
  }

  void _drawIridescentOverlay(Canvas canvas, Size size) {
    final gradient = RadialGradient(
      center: const Alignment(0.3, -0.2),
      radius: 1.6,
      colors: [
        const Color(0xFF20C7AD).withValues(alpha: 0.03),
        const Color(0xFF9B16C9).withValues(alpha: 0.02),
        const Color(0xFF426CF8).withValues(alpha: 0.02),
        Colors.transparent,
      ],
      stops: const [0, 0.3, 0.6, 1],
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = gradient.createShader(
          Offset.zero & size,
        ),
    );
  }

  void _drawCell({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required _HexCell cell,
  }) {
    final visual = _visualForState(cell.state);
    final path = _hexPath(center: center, radius: radius);

    if (visual.active) {
      _drawNeonGlow(canvas: canvas, path: path, color: visual.color, radius: radius);
    }

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.25),
        radius: 1.15,
        colors: [
          visual.fillColor.withValues(alpha: 0.97),
          const Color(0xFF101920).withValues(alpha: 0.98),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawPath(path, fillPaint);

    final innerHighlightPath = _hexPath(center: center, radius: radius * 0.94);
    canvas.drawPath(
      innerHighlightPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, radius * 0.018)
        ..color = visual.active
            ? visual.color.withValues(alpha: 0.38)
            : Colors.white.withValues(alpha: 0.035),
    );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = visual.active
            ? math.max(1.7, radius * 0.055)
            : math.max(0.9, radius * 0.026)
        ..strokeJoin = StrokeJoin.round
        ..color = visual.active
            ? visual.color
            : const Color(0xFF607883).withValues(alpha: 0.72),
    );

    switch (cell.state) {
      case CellState.cyanUser:
      case CellState.greenUser:
      case CellState.blueUser:
      case CellState.goldUser:
        _drawUserIcon(canvas: canvas, center: center, radius: radius, color: visual.color);
        break;
      case CellState.purpleStar:
        _drawStarIcon(canvas: canvas, center: center, radius: radius, color: visual.color);
        break;
      default:
        break;
    }
  }

  void _drawNeonGlow({
    required Canvas canvas,
    required Path path,
    required Color color,
    required double radius,
  }) {
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.11
        ..color = color.withValues(alpha: 0.28)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.18),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.045
        ..color = color.withValues(alpha: 0.55)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.07),
    );
  }

  void _drawUserIcon({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required Color color,
  }) {
    final iconPaint = Paint()..style = PaintingStyle.fill..color = color;
    final glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.48)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.11);

    final headCenter = Offset(center.dx, center.dy - radius * 0.19);
    final headRadius = radius * 0.14;
    canvas.drawCircle(headCenter, headRadius * 1.08, glowPaint);
    canvas.drawCircle(headCenter, headRadius, iconPaint);

    final bodyRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + radius * 0.16),
      width: radius * 0.58,
      height: radius * 0.40,
    );
    final bodyPath = Path()
      ..moveTo(bodyRect.left, bodyRect.bottom)
      ..cubicTo(
        bodyRect.left + radius * 0.04,
        bodyRect.top + radius * 0.03,
        bodyRect.right - radius * 0.04,
        bodyRect.top + radius * 0.03,
        bodyRect.right,
        bodyRect.bottom,
      )
      ..close();
    canvas.drawPath(bodyPath, glowPaint);
    canvas.drawPath(bodyPath, iconPaint);
  }

  void _drawStarIcon({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required Color color,
  }) {
    final path = Path();
    const points = 5;
    final outerRadius = radius * 0.38;
    final innerRadius = radius * 0.17;
    final startAngle = -math.pi / 2;
    for (int i = 0; i < points * 2; i++) {
      final currentRadius = i.isEven ? outerRadius : innerRadius;
      final angle = startAngle + i * math.pi / points;
      final point = Offset(
        center.dx + math.cos(angle) * currentRadius,
        center.dy + math.sin(angle) * currentRadius,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.fill
        ..color = color.withValues(alpha: 0.50)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.14),
    );
    canvas.drawPath(path, Paint()..style = PaintingStyle.fill..color = color);
  }

  @override
  bool shouldRepaint(covariant NeonHoneycombPainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.padding != padding ||
        oldDelegate.zoomFactor != zoomFactor ||
        oldDelegate.states != states;
  }
}

class NeonHoneycomb extends StatelessWidget {
  const NeonHoneycomb({
    Key? key,
    this.backgroundColor,
    this.padding = 2,
    this.zoomFactor = 1,
    required this.states,
    this.onCellTap,
  }) : super(key: key);

  final Color? backgroundColor;
  final double padding;
  final double zoomFactor;
  final Map<String, CellState> states;
  final void Function(int cellId)? onCellTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: (details) => _handleTap(details.localPosition, context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: CustomPaint(
          painter: NeonHoneycombPainter(
            backgroundColor: backgroundColor ?? const Color(0xFF141515),
            padding: padding,
            zoomFactor: zoomFactor,
            states: states,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  void _handleTap(Offset position, BuildContext context) {
    if (onCellTap == null) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;
    final cells = _buildAllCells();
    if (cells.isEmpty) return;
    final bounds = _calcGridBounds(cells);
    final availableWidth = size.width - padding * 2;
    final availableHeight = size.height - padding * 2;
    final rw = availableWidth / bounds.widthFactor;
    final rh = availableHeight / bounds.heightFactor;
    final radius = math.min(rw, rh) * zoomFactor;
    final gridPixelWidth = bounds.widthFactor * radius;
    final gridPixelHeight = bounds.heightFactor * radius;
    final offset = Offset(
      (size.width - gridPixelWidth) / 2 - bounds.minX * radius,
      (size.height - gridPixelHeight) / 2 - bounds.minY * radius,
    );
    for (final entry in kAxialMap.entries) {
      final q = entry.value[0];
      final r = entry.value[1];
      final center = _axialPixel(
        q: q,
        r: r,
        radius: radius,
        offset: offset,
      );
      final dx = position.dx - center.dx;
      final dy = position.dy - center.dy;
      if (dx * dx + dy * dy <= radius * radius) {
        onCellTap?.call(entry.key);
        return;
      }
    }
  }

  List<_HexCell> _buildAllCells() {
    const gridRadius = 6;
    final cells = <_HexCell>[];
    for (int q = -gridRadius; q <= gridRadius; q++) {
      final minR = math.max(-gridRadius, -q - gridRadius);
      final maxR = math.min(gridRadius, -q + gridRadius);
      for (int r = minR; r <= maxR; r++) {
        cells.add(
          _HexCell(q: q, r: r, state: states['$q:$r'] ?? CellState.inactive),
        );
      }
    }
    return cells;
  }
}

const Map<int, List<int>> kAxialMap = {
  1: [0, -2],
  2: [-1, -1],
  3: [1, -1],
  4: [-2, 0],
  5: [0, 0],
  6: [2, 0],
  7: [-2, 1],
  8: [-1, 1],
  9: [1, 1],
  10: [2, 1],
  11: [-2, 2],
  12: [-1, 2],
  13: [0, 2],
  14: [1, 2],
  15: [2, 2],
};
