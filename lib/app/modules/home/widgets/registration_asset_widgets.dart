part of '../views/registrationlevel.dart';

class _PaymentAssetSelector extends StatelessWidget {
  final EasyGamePaymentAsset selected;
  final String nativeSymbol;
  final ValueChanged<EasyGamePaymentAsset> onChanged;

  const _PaymentAssetSelector({
    required this.selected,
    required this.nativeSymbol,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: EasyGameTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EasyGameTheme.borderSoft),
      ),
      child: Row(
        children: [
          Expanded(
            child: _AssetOption(
              label: nativeSymbol,
              selected: selected == EasyGamePaymentAsset.native,
              onTap: () => onChanged(EasyGamePaymentAsset.native),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _AssetOption(
              label: 'USDC',
              selected: selected == EasyGamePaymentAsset.usdc,
              onTap: () => onChanged(EasyGamePaymentAsset.usdc),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AssetOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected ? EasyGameTheme.actionGradient : null,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white54,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
