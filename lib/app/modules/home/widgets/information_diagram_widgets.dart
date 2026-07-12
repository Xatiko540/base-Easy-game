part of '../views/utility_screens.dart';

class _BinaryTreeDiagram extends StatelessWidget {
  final bool compact;

  const _BinaryTreeDiagram({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 240 : 300,
      decoration: BoxDecoration(
        color: EasyGameTheme.cardDark.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EasyGameTheme.borderSoft),
      ),
      child: CustomPaint(
        painter: _InfoTreeLinesPainter(),
        child: Stack(
          children: [
            _InfoTreeNode(
              label: '1',
              alignment: const Alignment(0, -0.78),
              color: EasyGameTheme.teal,
              icon: CupertinoIcons.person,
            ),
            _InfoTreeNode(
              label: '2',
              alignment: const Alignment(-0.48, -0.12),
              color: Colors.greenAccent,
              icon: CupertinoIcons.person,
            ),
            _InfoTreeNode(
              label: '3',
              alignment: const Alignment(0.48, -0.12),
              color: Colors.greenAccent,
              icon: CupertinoIcons.person,
            ),
            _InfoTreeNode(
              label: '4',
              alignment: const Alignment(-0.72, 0.56),
              color: Colors.white24,
              icon: CupertinoIcons.circle,
            ),
            _InfoTreeNode(
              label: '5',
              alignment: const Alignment(-0.24, 0.56),
              color: EasyGameTheme.teal,
              icon: CupertinoIcons.snow,
            ),
            _InfoTreeNode(
              label: '6',
              alignment: const Alignment(0.24, 0.56),
              color: EasyGameTheme.orange,
              icon: CupertinoIcons.refresh,
            ),
            _InfoTreeNode(
              label: '7',
              alignment: const Alignment(0.72, 0.56),
              color: EasyGameTheme.gold,
              icon: CupertinoIcons.star,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTreeNode extends StatefulWidget {
  final String label;
  final Alignment alignment;
  final Color color;
  final IconData icon;

  const _InfoTreeNode({
    required this.label,
    required this.alignment,
    required this.color,
    required this.icon,
  });

  @override
  State<_InfoTreeNode> createState() => _InfoTreeNodeState();
}

class _InfoTreeNodeState extends State<_InfoTreeNode> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.alignment,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: _isHovered ? 1 : 0),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          builder: (context, hoverAmount, child) {
            final activeColor = Color.lerp(
              widget.color,
              const Color(0xFF20E8FF),
              hoverAmount,
            )!;

            return Transform.scale(
              scale: 1 + (hoverAmount * 0.12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 64,
                    height: 58,
                    child: CustomPaint(
                      painter: _InfoHexCellPainter(
                        color: activeColor,
                        glowIntensity: hoverAmount,
                      ),
                      child: Center(
                        child: Icon(
                          widget.icon,
                          color: activeColor,
                          size: 22 + (hoverAmount * 2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: Color.lerp(
                        Colors.white54,
                        const Color(0xFF8FF5FF),
                        hoverAmount,
                      ),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InfoHexCellPainter extends CustomPainter {
  final Color color;
  final double glowIntensity;

  const _InfoHexCellPainter({
    required this.color,
    this.glowIntensity = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = _hexPath(size).shift(const Offset(0, 1));
    final shadowPaint = Paint()
      ..color = color.withValues(alpha: 0.20 + (glowIntensity * 0.42))
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        12 + (glowIntensity * 10),
      );
    canvas.drawPath(path, shadowPaint);

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withValues(alpha: 0.24),
          EasyGameTheme.cardDark.withValues(alpha: 0.94),
          color.withValues(alpha: 0.10),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, fillPaint);

    final innerPath = _hexPath(Size(size.width - 10, size.height - 10))
        .shift(const Offset(5, 6));
    final innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.10);
    canvas.drawPath(innerPath, innerPaint);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 + glowIntensity
      ..strokeJoin = StrokeJoin.round
      ..color = color.withValues(alpha: 0.92);
    canvas.drawPath(path, borderPaint);

    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white.withValues(alpha: 0.22);
    canvas.drawPath(path.shift(const Offset(0, -1)), highlightPaint);
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
  bool shouldRepaint(covariant _InfoHexCellPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.glowIntensity != glowIntensity;
}

class _InfoTreeLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Offset p(double x, double y) =>
        Offset(size.width * (x + 1) / 2, size.height * (y + 1) / 2);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 2;
    final links = [
      [p(0, -0.58), p(-0.48, 0.08)],
      [p(0, -0.58), p(0.48, 0.08)],
      [p(-0.48, 0.08), p(-0.72, 0.72)],
      [p(-0.48, 0.08), p(-0.24, 0.72)],
      [p(0.48, 0.08), p(0.24, 0.72)],
      [p(0.48, 0.08), p(0.72, 0.72)],
    ];
    for (final link in links) {
      canvas.drawLine(link[0], link[1], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _InfoTreeLinesPainter oldDelegate) => false;
}
