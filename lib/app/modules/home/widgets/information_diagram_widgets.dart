part of '../views/utility_screens.dart';

class _MatrixDemoController extends GetxController {
  final currentFrame = 0.obs;
  final isRunning = false.obs;

  static const frames = <Map<int, CellState>>[
    {5: CellState.cyanUser},
    {5: CellState.cyanUser, 2: CellState.greenUser},
    {5: CellState.cyanUser, 2: CellState.greenUser, 3: CellState.greenUser},
    {5: CellState.cyanGlow, 2: CellState.greenGlow, 3: CellState.greenGlow},
    {
      5: CellState.cyanUser,
      2: CellState.greenUser,
      3: CellState.greenUser,
      4: CellState.greenUser
    },
    {
      5: CellState.cyanUser,
      2: CellState.greenUser,
      3: CellState.greenUser,
      4: CellState.greenUser,
      7: CellState.blueUser
    },
    {
      5: CellState.cyanUser,
      2: CellState.greenUser,
      3: CellState.greenUser,
      4: CellState.greenUser,
      7: CellState.greenUser,
      9: CellState.greenUser
    },
    {
      5: CellState.cyanUser,
      7: CellState.greenUser,
      9: CellState.greenUser,
      15: CellState.goldUser
    },
    {5: CellState.cyanUser, 15: CellState.goldGlow},
    {5: CellState.cyanUser},
  ];

  void startLoop() {
    if (isRunning.value) return;
    isRunning.value = true;
    _animate();
  }

  void stopLoop() {
    isRunning.value = false;
    currentFrame.value = 0;
  }

  void _animate() async {
    for (var i = 0; i < frames.length && isRunning.value; i++) {
      currentFrame.value = i;
      await Future.delayed(const Duration(milliseconds: 800));
    }
    if (isRunning.value) {
      currentFrame.value = 0;
      Future.delayed(const Duration(milliseconds: 800), _animate);
    }
  }

  @override
  void onClose() {
    isRunning.value = false;
    super.onClose();
  }
}

class _AnimatedMatrixDemo extends StatefulWidget {
  final bool compact;
  const _AnimatedMatrixDemo({required this.compact});

  @override
  State<_AnimatedMatrixDemo> createState() => _AnimatedMatrixDemoState();
}

class _AnimatedMatrixDemoState extends State<_AnimatedMatrixDemo> {
  late final _MatrixDemoController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(_MatrixDemoController(), tag: 'matrix_demo');
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.startLoop());
  }

  @override
  void dispose() {
    Get.delete<_MatrixDemoController>(tag: 'matrix_demo');
    super.dispose();
  }

  static const _kAllCells = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];

  Map<String, CellState> _buildStates(int frameIndex) {
    final frameStates = _MatrixDemoController.frames[frameIndex];
    final states = <String, CellState>{};
    for (final c in _kAllCells) {
      final entry = kAxialMap[c]!;
      final id = '${entry[0]}:${entry[1]}';
      states[id] = frameStates[c] ?? CellState.inactive;
    }
    return states;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final frameIndex = controller.currentFrame.value;
      return Container(
        height: widget.compact ? 240 : 300,
        decoration: BoxDecoration(
          color: EasyGameTheme.cardDark.withValues(alpha: 0.76),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: EasyGameTheme.borderSoft),
        ),
        clipBehavior: Clip.antiAlias,
        child: NeonHoneycomb(
          zoomFactor: 2.0,
          states: _buildStates(frameIndex),
        ),
      );
    });
  }
}

class _WinningCellsHoneycomb extends StatelessWidget {
  const _WinningCellsHoneycomb();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 520.0;
        final cellWidth = ((availableWidth - 56) / 3.45).clamp(68.0, 122.0);
        final cellHeight = cellWidth * 1.08;
        final gap = (cellWidth * 0.10).clamp(8.0, 14.0);
        final rowWidth = (cellWidth * 3) + (gap * 2);
        final shift = cellWidth * 0.48;
        final clusterWidth = rowWidth + shift;

        Widget row(List<String> labels) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < labels.length; index++) ...[
                if (index > 0) SizedBox(width: gap),
                _WinningCellHex(
                  label: labels[index],
                  width: cellWidth,
                  height: cellHeight,
                ),
              ],
            ],
          );
        }

        return Center(
          child: SizedBox(
            width: clusterWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                    alignment: Alignment.centerLeft,
                    child: row(const ['7', '15', '31'])),
                SizedBox(height: gap),
                Align(
                    alignment: Alignment.centerRight,
                    child: row(const ['63', '127', '255'])),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WinningCellHex extends StatelessWidget {
  final String label;
  final double width;
  final double height;

  const _WinningCellHex({
    required this.label,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: const _InfoHexCellPainter(
          color: EasyGameTheme.gold,
          glowIntensity: 0.42,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: const Color(0xFFFFC93C),
              fontSize: (width * 0.31).clamp(22.0, 38.0),
              fontWeight: FontWeight.w900,
            ),
          ),
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
