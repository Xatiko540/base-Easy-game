part of '../views/registrationlevel.dart';

class _DarkInput extends StatelessWidget {
  final Widget child;

  const _DarkInput({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: EasyGameTheme.card,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _CheckPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onPressed;

  const _CheckPill({
    required this.icon,
    required this.label,
    required this.active,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        active ? CupertinoIcons.check_mark_circled : icon,
        color: active ? const Color(0xFF7CFF85) : const Color(0xFF67DCCB),
        size: 18,
      ),
      label: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: active ? const Color(0xFF7CFF85) : const Color(0xFF67DCCB),
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: active ? const Color(0xFF7CFF85) : const Color(0xFF67DCCB),
          width: 1.4,
        ),
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String title;
  final String value;
  final bool strong;

  const _SummaryRow({
    required this.title,
    required this.value,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: strong ? Colors.white : Colors.white60,
              fontSize: strong ? 17 : 14,
              fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: strong ? 18 : 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
