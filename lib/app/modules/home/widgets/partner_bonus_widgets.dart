part of '../views/partner_bonus_screen.dart';

class _PartnerAccordionPanel extends StatefulWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _PartnerAccordionPanel({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  State<_PartnerAccordionPanel> createState() => _PartnerAccordionPanelState();
}

class _PartnerAccordionPanelState extends State<_PartnerAccordionPanel> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            EasyGameTheme.surface.withValues(alpha: 0.85),
            EasyGameTheme.cardDark.withValues(alpha: 0.92),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EasyGameTheme.borderSoft.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  _PartnerHexIcon(icon: widget.icon),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedRotation(
                    turns: _isExpanded ? 0 : -0.25,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: EasyGameTheme.teal,
                      size: 27,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: _isExpanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: widget.child,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _PartnerHexIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _PartnerHexIcon({
    required this.icon,
    this.color = EasyGameTheme.teal,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: CustomPaint(
        painter: _PartnerHexIconPainter(color),
        child: Center(child: Icon(icon, color: color, size: 18)),
      ),
    );
  }
}

class _PartnerHexIconPainter extends CustomPainter {
  final Color color;

  const _PartnerHexIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    for (var index = 0; index < 6; index++) {
      final angle = (index * 60 - 30) * math.pi / 180;
      final point = Offset(
        size.width / 2 + size.width * 0.43 * math.cos(angle),
        size.height / 2 + size.height * 0.43 * math.sin(angle),
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }

  @override
  bool shouldRepaint(covariant _PartnerHexIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
