part of '../views/partner_bonus_screen.dart';

class _BonusTable extends StatelessWidget {
  const _BonusTable();

  @override
  Widget build(BuildContext context) {
    final walletService = Get.find<WalletConnectService>();
    return _PartnerAccordionPanel(
      icon: CupertinoIcons.list_bullet,
      title: 'partner.rewards'.tr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BonusHeader(),
          const Divider(color: Color(0xFF343738)),
          Obx(
            () => _BonusRow(
              date: 'common.waitingEvents'.tr,
              level: '-',
              wallet: walletService.isConnected.value
                  ? walletService.shortAddress
                  : 'common.notConnected'.tr,
              amount: '0 ${walletService.nativeSymbol}',
            ),
          ),
        ],
      ),
    );
  }
}

class _BonusHeader extends StatelessWidget {
  const _BonusHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: 2, child: _HeaderText('partner.date'.tr)),
        Expanded(child: _HeaderText('common.level'.tr)),
        Expanded(flex: 2, child: _HeaderText('common.wallet'.tr)),
        Expanded(child: _HeaderText('partner.reward'.tr)),
      ],
    );
  }
}

class _BonusRow extends StatelessWidget {
  final String date;
  final String level;
  final String wallet;
  final String amount;

  const _BonusRow({
    required this.date,
    required this.level,
    required this.wallet,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: 2, child: _BodyText(date)),
        Expanded(child: _BodyText(level)),
        Expanded(flex: 2, child: _BodyText(wallet)),
        Expanded(child: _BodyText(amount, green: true)),
      ],
    );
  }
}

class _HeaderText extends StatelessWidget {
  final String value;

  const _HeaderText(this.value);

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _BodyText extends StatelessWidget {
  final String value;
  final bool green;

  const _BodyText(this.value, {this.green = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Text(
        value,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: green ? const Color(0xFF36E16C) : Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
