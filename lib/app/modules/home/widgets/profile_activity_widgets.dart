part of '../views/profilescreen.dart';

class _RecentActivityTable extends StatelessWidget {
  final ProfileDashboardSnapshot data;
  final String errorMessage;
  final VoidCallback onRefresh;

  const _RecentActivityTable({
    required this.data,
    required this.errorMessage,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: EasyGameTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EasyGameTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Text(
              'profile.recentTransactions'.tr,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Divider(height: 1, color: EasyGameTheme.border),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _ProfileTransactionsBody(
              data: data,
              errorMessage: errorMessage,
              onRefresh: onRefresh,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTransactionsBody extends StatelessWidget {
  final ProfileDashboardSnapshot data;
  final String errorMessage;
  final VoidCallback onRefresh;

  const _ProfileTransactionsBody({
    required this.data,
    required this.errorMessage,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (errorMessage.isNotEmpty) {
      return _ProfileTransactionsError(
        key: const ValueKey('transactions-error'),
        message: errorMessage,
        onRefresh: onRefresh,
      );
    }
    if (data.transactions.isEmpty) {
      return const KeyedSubtree(
        key: ValueKey('transactions-empty'),
        child: _ProfileTransactionsEmpty(),
      );
    }
    return LayoutBuilder(
      key: const ValueKey('transactions-list'),
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Column(
            children: data.transactions
                .take(8)
                .map((transaction) =>
                    _ProfileMobileTransaction(transaction: transaction))
                .toList(),
          );
        }
        return Column(
          children: [
            const _ActivityHeader(),
            const Divider(height: 1, color: EasyGameTheme.border),
            ...data.transactions
                .take(8)
                .map((transaction) => _ActivityRow(transaction: transaction)),
          ],
        );
      },
    );
  }
}

class _ProfileTransactionsError extends StatelessWidget {
  final String message;
  final VoidCallback onRefresh;

  const _ProfileTransactionsError({
    super.key,
    required this.message,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Tooltip(
            message: message,
            child: const Icon(
              CupertinoIcons.exclamationmark_triangle,
              color: EasyGameTheme.gold,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'levels.transactionsUnavailable'.tr,
              style: const TextStyle(color: EasyGameTheme.textMuted),
            ),
          ),
          TextButton(
            onPressed: onRefresh,
            child: Text('common.refresh'.tr),
          ),
        ],
      ),
    );
  }
}

class _ProfileTransactionsEmpty extends StatelessWidget {
  const _ProfileTransactionsEmpty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 30),
      child: Center(
        child: Column(
          children: [
            const Icon(
              CupertinoIcons.doc_text_search,
              color: EasyGameTheme.textDim,
              size: 28,
            ),
            const SizedBox(height: 10),
            Text(
              'levels.noTransactions'.tr,
              style: const TextStyle(color: EasyGameTheme.textMuted),
            ),
            const SizedBox(height: 4),
            Text(
              'levels.noTransactionsHint'.tr,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: EasyGameTheme.textDim, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityHeader extends StatelessWidget {
  const _ActivityHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Expanded(flex: 3, child: _HeaderText('profile.type'.tr)),
          Expanded(flex: 2, child: _HeaderText('partner.date'.tr)),
          const Expanded(flex: 3, child: _HeaderText('TX')),
          Expanded(flex: 1, child: _HeaderText('common.level'.tr)),
          Expanded(flex: 3, child: _HeaderText('common.wallet'.tr)),
          Expanded(
            flex: 2,
            child: _HeaderText('profile.amount'.tr, align: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  final String text;
  final TextAlign align;

  const _HeaderText(this.text, {this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      style: const TextStyle(
        color: Colors.white38,
        fontWeight: FontWeight.w900,
        fontSize: 12,
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final GameTransaction transaction;

  const _ActivityRow({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final statusColor = _profileTransactionColor(transaction);
    return InkWell(
      onTap: () => _openProfileTransaction(transaction),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: EasyGameTheme.border)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: _ProfileOperation(transaction: transaction),
            ),
            Expanded(
              flex: 2,
              child: Text(
                _formatProfileTransactionDate(transaction.createdAt),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                transaction.shortHash,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              child: Text(
                transaction.level?.toString() ?? '-',
                style: const TextStyle(color: Colors.white54),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                transaction.shortWallet,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                _profileTransactionAmount(transaction),
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMobileTransaction extends StatelessWidget {
  final GameTransaction transaction;

  const _ProfileMobileTransaction({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final statusColor = _profileTransactionColor(transaction);
    return InkWell(
      onTap: () => _openProfileTransaction(transaction),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: EasyGameTheme.border)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _ProfileOperation(transaction: transaction)),
                const SizedBox(width: 8),
                Text(
                  _profileTransactionAmount(transaction),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _ProfileActivityValue(
                  label: 'partner.date'.tr,
                  value: _formatProfileTransactionDate(transaction.createdAt),
                ),
                _ProfileActivityValue(
                    label: 'TX', value: transaction.shortHash),
                _ProfileActivityValue(
                  label: 'common.level'.tr,
                  value: transaction.level?.toString() ?? '-',
                ),
                _ProfileActivityValue(
                  label: 'common.wallet'.tr,
                  value: transaction.shortWallet,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileOperation extends StatelessWidget {
  final GameTransaction transaction;

  const _ProfileOperation({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final color = _profileTransactionColor(transaction);
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            transaction.isFailed
                ? CupertinoIcons.exclamationmark_triangle
                : CupertinoIcons.arrow_up_right,
            color: color,
            size: 15,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            _profileTransactionOperation(transaction.operation),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileActivityValue extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileActivityValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 110, maxWidth: 190),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white30, fontSize: 10)),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

Color _profileTransactionColor(GameTransaction transaction) {
  if (transaction.isFailed) return Colors.redAccent;
  if (transaction.isConfirmed) return EasyGameTheme.teal;
  return EasyGameTheme.gold;
}

String _profileTransactionOperation(String operation) {
  switch (operation) {
    case 'activateRound':
      return 'levels.operation.activateRound'.tr;
    case 'activateRoundWithUSDC':
      return 'levels.operation.activateRoundWithUSDC'.tr;
    default:
      return 'levels.operation.onChain'.tr;
  }
}

String _profileTransactionAmount(GameTransaction transaction) {
  if (transaction.amount.isEmpty) {
    return 'levels.txStatus.${transaction.status}'.tr;
  }
  final currency =
      transaction.currency.isEmpty ? '' : ' ${transaction.currency}';
  return '${transaction.amount}$currency';
}

String _formatProfileTransactionDate(DateTime? value) {
  if (value == null) return '-';
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(local.day)}.${two(local.month)}.${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}

Future<void> _openProfileTransaction(GameTransaction transaction) async {
  if (transaction.transactionHash.isEmpty) return;
  var explorer = '';
  if (transaction.chainId == WalletConnectService.baseMainnetChainId) {
    explorer = 'https://basescan.org';
  } else if (transaction.chainId == WalletConnectService.baseSepoliaChainId) {
    explorer = 'https://sepolia.basescan.org';
  }
  if (explorer.isEmpty) return;
  await launchUrl(
    Uri.parse('$explorer/tx/${transaction.transactionHash}'),
    mode: LaunchMode.externalApplication,
  );
}
