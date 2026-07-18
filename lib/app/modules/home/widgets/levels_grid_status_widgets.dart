part of '../views/levels.dart';

class _LevelStateBanner extends StatelessWidget {
  final String message;

  const _LevelStateBanner({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.info, color: Colors.orangeAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class BottomTableSection extends StatelessWidget {
  final List<GameTransaction> transactions;
  final bool isLoading;
  final String errorMessage;

  const BottomTableSection({
    super.key,
    required this.transactions,
    required this.isLoading,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        return Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: EasyGameTheme.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: EasyGameTheme.borderSoft),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TransactionsSectionHeader(
                count: transactions.length,
              ),
              if (errorMessage.isNotEmpty)
                _TransactionsError(
                  message: errorMessage,
                )
              else if (isLoading && transactions.isEmpty)
                const _TransactionsSkeleton()
              else if (!isLoading && transactions.isEmpty)
                const _TransactionsEmptyState()
              else if (compact)
                ...transactions.map(
                  (transaction) => _MobileTransactionTile(
                    transaction: transaction,
                  ),
                )
              else ...[
                const _DesktopTransactionsHeader(),
                ...transactions.map(
                  (transaction) => _DesktopTransactionRow(
                    transaction: transaction,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _TransactionsSkeleton extends StatelessWidget {
  const _TransactionsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(18, 4, 18, 18),
      child: Column(
        children: [
          StableSkeletonBlock(height: 52),
          SizedBox(height: 8),
          StableSkeletonBlock(height: 52),
          SizedBox(height: 8),
          StableSkeletonBlock(height: 52),
        ],
      ),
    );
  }
}

class _TransactionsSectionHeader extends StatelessWidget {
  final int count;

  const _TransactionsSectionHeader({
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: EasyGameTheme.teal.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              CupertinoIcons.arrow_2_circlepath,
              color: EasyGameTheme.teal,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'levels.transactions'.tr,
                  style: const TextStyle(
                    color: EasyGameTheme.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'levels.transactionsSubtitle'.trParams({'count': '$count'}),
                  style: const TextStyle(
                    color: EasyGameTheme.textMuted,
                    fontSize: 12,
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

class _DesktopTransactionsHeader extends StatelessWidget {
  const _DesktopTransactionsHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      decoration: const BoxDecoration(
        color: EasyGameTheme.cardDark,
        border: Border.symmetric(
          horizontal: BorderSide(color: EasyGameTheme.border),
        ),
      ),
      child: Row(
        children: [
          _DesktopCell(flex: 3, child: _TableLabel('levels.operation'.tr)),
          _DesktopCell(flex: 3, child: _TableLabel('levels.transaction'.tr)),
          _DesktopCell(flex: 2, child: _TableLabel('partner.date'.tr)),
          _DesktopCell(flex: 2, child: _TableLabel('levels.network'.tr)),
          _DesktopCell(flex: 2, child: _TableLabel('common.wallet'.tr)),
          _DesktopCell(
            flex: 2,
            child: _TableLabel('levels.status'.tr, align: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

class _DesktopTransactionRow extends StatelessWidget {
  final GameTransaction transaction;

  const _DesktopTransactionRow({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openTransaction(transaction),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: EasyGameTheme.border)),
        ),
        child: Row(
          children: [
            _DesktopCell(
              flex: 3,
              child: _OperationLabel(transaction: transaction),
            ),
            _DesktopCell(
              flex: 3,
              child: Text(
                transaction.shortHash,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: EasyGameTheme.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _DesktopCell(
              flex: 2,
              child: Text(
                _formatTransactionDate(transaction.createdAt),
                style: const TextStyle(color: EasyGameTheme.textMuted),
              ),
            ),
            _DesktopCell(
              flex: 2,
              child: Text(
                _transactionNetwork(transaction.chainId),
                style: const TextStyle(color: EasyGameTheme.textMuted),
              ),
            ),
            _DesktopCell(
              flex: 2,
              child: Text(
                transaction.shortWallet,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: EasyGameTheme.textMuted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            _DesktopCell(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: _TransactionStatus(transaction: transaction),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileTransactionTile extends StatelessWidget {
  final GameTransaction transaction;

  const _MobileTransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openTransaction(transaction),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: EasyGameTheme.border)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _OperationLabel(transaction: transaction)),
                const SizedBox(width: 8),
                _TransactionStatus(transaction: transaction),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MobileValue(
                    label: 'levels.transaction'.tr,
                    value: transaction.shortHash,
                  ),
                ),
                Expanded(
                  child: _MobileValue(
                    label: 'levels.network'.tr,
                    value: _transactionNetwork(transaction.chainId),
                  ),
                ),
                Expanded(
                  child: _MobileValue(
                    label: 'common.wallet'.tr,
                    value: transaction.shortWallet,
                    align: CrossAxisAlignment.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _formatTransactionDate(transaction.createdAt),
              style: const TextStyle(
                color: EasyGameTheme.textDim,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OperationLabel extends StatelessWidget {
  final GameTransaction transaction;

  const _OperationLabel({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: EasyGameTheme.purple.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            CupertinoIcons.arrow_up_right,
            color: EasyGameTheme.teal,
            size: 15,
          ),
        ),
        const SizedBox(width: 9),
        Flexible(
          child: Text(
            _transactionOperation(transaction.operation),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: EasyGameTheme.text,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _TransactionStatus extends StatelessWidget {
  final GameTransaction transaction;

  const _TransactionStatus({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final color = transaction.isFailed
        ? Colors.redAccent
        : transaction.isConfirmed
            ? EasyGameTheme.teal
            : EasyGameTheme.gold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Text(
        'levels.txStatus.${transaction.status}'.tr,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _MobileValue extends StatelessWidget {
  final String label;
  final String value;
  final CrossAxisAlignment align;

  const _MobileValue({
    required this.label,
    required this.value,
    this.align = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          style: const TextStyle(color: EasyGameTheme.textDim, fontSize: 10),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: EasyGameTheme.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _TransactionsEmptyState extends StatelessWidget {
  const _TransactionsEmptyState();

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
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: EasyGameTheme.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'levels.noTransactionsHint'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: EasyGameTheme.textDim,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionsError extends StatelessWidget {
  final String message;

  const _TransactionsError({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
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
        ],
      ),
    );
  }
}

class _DesktopCell extends StatelessWidget {
  final int flex;
  final Widget child;

  const _DesktopCell({required this.flex, required this.child});

  @override
  Widget build(BuildContext context) => Expanded(flex: flex, child: child);
}

class _TableLabel extends StatelessWidget {
  final String text;
  final TextAlign align;

  const _TableLabel(this.text, {this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      style: const TextStyle(
        color: EasyGameTheme.textDim,
        fontWeight: FontWeight.w900,
        fontSize: 11,
      ),
    );
  }
}

String _transactionOperation(String operation) {
  switch (operation) {
    case 'activateRound':
      return 'levels.operation.activateRound'.tr;
    case 'activateRoundWithUSDC':
      return 'levels.operation.activateRoundWithUSDC'.tr;
    default:
      return 'levels.operation.onChain'.tr;
  }
}

String _transactionNetwork(int chainId) {
  if (chainId == WalletConnectService.baseMainnetChainId) return 'Base';
  if (chainId == WalletConnectService.baseSepoliaChainId) {
    return 'Base Sepolia';
  }
  if (chainId == WalletConnectService.ganacheChainId) return 'Ganache';
  return chainId == 0 ? '-' : '$chainId';
}

String _formatTransactionDate(DateTime? value) {
  if (value == null) return '-';
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(local.day)}.${two(local.month)}.${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}

Future<void> _openTransaction(GameTransaction transaction) async {
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
