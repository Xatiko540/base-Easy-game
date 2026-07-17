import 'package:flutter/material.dart';

/// Keeps the rendered layout mounted while its controller refreshes data.
///
/// Background refreshes stay fully opaque. Only the first unresolved load is
/// softened, so no progress bar is inserted into (or removed from) the layout.
class StableLoadingSurface extends StatelessWidget {
  final bool isLoading;
  final bool hasData;
  final Widget child;

  const StableLoadingSurface({
    Key? key,
    required this.isLoading,
    required this.hasData,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      opacity: isLoading && !hasData ? 0.58 : 1,
      child: IgnorePointer(
        ignoring: isLoading && !hasData,
        child: child,
      ),
    );
  }
}

/// A fixed-size neutral placeholder used only when a screen has no cached
/// content yet. It deliberately has no spinner or moving progress track.
class StableSkeletonBlock extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius borderRadius;

  const StableSkeletonBlock({
    Key? key,
    required this.height,
    this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF24272A),
        borderRadius: borderRadius,
        border: Border.all(color: const Color(0xFF303438)),
      ),
    );
  }
}
