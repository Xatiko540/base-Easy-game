part of '../views/levels.dart';

class _LevelHeroPanel extends StatelessWidget {
  final int level;
  final BigInt priceWei;
  final String stateLabel;
  final String walletLabel;
  final double progress;
  final VoidCallback? onActivate;

  const _LevelHeroPanel({
    required this.level,
    required this.priceWei,
    required this.stateLabel,
    required this.walletLabel,
    required this.progress,
    required this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    final clampedProgress = (progress / 100).clamp(0, 1).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1A1F2E),
            Color(0xFF0F131A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFF6A4BFF), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A4BFF).withValues(alpha: 0.45),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lvl $level',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.orangeAccent,
                    radius: 12,
                    child: Icon(
                      Icons.monetization_on,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${formatWeiToEth(priceWei)} ${Get.find<WalletConnectService>().nativeSymbol}',
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
              border: Border.all(color: const Color(0xFF2AF598), width: 2),
            ),
            child: const Icon(
              Icons.account_tree,
              color: Color(0xFF2AF598),
              size: 38,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'common.you'.tr,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          Text(
            walletLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 22),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              stateLabel,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.grey[800],
                ),
              ),
              FractionallySizedBox(
                widthFactor: clampedProgress,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF2AF598),
                        Color(0xFF009EFD),
                        Color(0xFF6A4BFF),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${progress.toStringAsFixed(2)}%',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          if (onActivate != null) ...[
            const SizedBox(height: 22),
            Container(
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF6A4BFF),
                    Color(0xFF2AF598),
                  ],
                ),
              ),
              child: ElevatedButton(
                onPressed: onActivate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'levelDetail.activateLevel'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
