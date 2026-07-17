part of '../views/levels.dart';

class _LevelDetailSkeleton extends StatelessWidget {
  const _LevelDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        StableSkeletonBlock(height: 220),
        SizedBox(height: 16),
        StableSkeletonBlock(height: 112),
        SizedBox(height: 16),
        StableSkeletonBlock(height: 280),
        SizedBox(height: 16),
        StableSkeletonBlock(height: 180),
      ],
    );
  }
}

class _LevelDetailPanel extends StatelessWidget {
  final String title;
  final List<DetailRow> rows;

  const _LevelDetailPanel({
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(row.label,
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      row.value,
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LevelEventsTable extends StatelessWidget {
  final List<GameTransaction> transactions;
  final bool isLoading;
  final String errorMessage;

  const _LevelEventsTable({
    required this.transactions,
    required this.isLoading,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return BottomTableSection(
      transactions: transactions,
      isLoading: isLoading,
      errorMessage: errorMessage,
    );
  }
}

class _LevelNavButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool trailing;
  final bool enabled;
  final VoidCallback onTap;

  const _LevelNavButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
    this.trailing = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = [
      Icon(icon, color: enabled ? Colors.white : Colors.grey, size: 16),
      const SizedBox(width: 4),
      Text(
        label,
        style: TextStyle(
          color: enabled ? Colors.white : Colors.grey,
          fontSize: 14,
        ),
      ),
    ];
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F2E),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: trailing ? content.reversed.toList() : content,
          ),
        ),
      ),
    );
  }
}
