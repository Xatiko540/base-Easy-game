part of '../views/utility_screens.dart';

class _ArenaSkillsPanel extends StatelessWidget {
  final _MatrixArenaSnapshot data;
  final String selectedOpponent;
  final bool actionsBusy;
  final ValueChanged<String> onSelectOpponent;
  final VoidCallback onBuyFreeze;
  final VoidCallback onFreeze;
  final VoidCallback onUnfreeze;

  const _ArenaSkillsPanel({
    required this.data,
    required this.selectedOpponent,
    required this.actionsBusy,
    required this.onSelectOpponent,
    required this.onBuyFreeze,
    required this.onFreeze,
    required this.onUnfreeze,
  });

  @override
  Widget build(BuildContext context) {
    final status = data.playerSkillStatus;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: EasyGameTheme.cardDark.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: data.playerFrozen
              ? Colors.lightBlueAccent.withValues(alpha: 0.55)
              : EasyGameTheme.borderSoft,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                data.playerFrozen ? CupertinoIcons.snow : CupertinoIcons.shield,
                color: data.playerFrozen
                    ? Colors.lightBlueAccent
                    : Colors.greenAccent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  !data.playerActive
                      ? 'matrix.statusNotParticipant'.tr
                      : data.playerFrozen
                          ? 'matrix.statusFrozen'.tr
                          : status?.immune == true
                              ? 'matrix.statusImmune'.tr
                              : 'matrix.statusActive'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                '${status?.freezeHits ?? 0}/${data.skillRules.freezeLimit}',
                style: const TextStyle(color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _ArenaStatusValue(
                label: 'matrix.freezeTokens'.tr,
                value: '${status?.freezeTokens ?? 0}',
              ),
              _ArenaStatusValue(
                label: 'matrix.freezesRemaining'.tr,
                value: '${data.skillRules.freezesRemaining}',
              ),
              if (status?.frozenUntil != null)
                _ArenaStatusValue(
                  label: 'matrix.frozenUntil'.tr,
                  value: _formatArenaDate(status!.frozenUntil!),
                ),
              _ArenaStatusValue(
                label: 'matrix.freezeWindow'.tr,
                value: data.freezeWindowOpen
                    ? 'matrix.freezeWindowOpen'.tr
                    : 'matrix.freezeWindowClosed'.tr,
              ),
              if (data.freezeClosesAt != null)
                _ArenaStatusValue(
                  label: 'matrix.freezeWindowEnds'.tr,
                  value: _formatArenaDate(data.freezeClosesAt!),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SkillActionButton(
                icon: CupertinoIcons.snow,
                label:
                    '${'matrix.buyFreeze'.tr} · ${_usdc(data.freezeTokenPriceUsdc)} USDC',
                onPressed: actionsBusy || !data.canUseFreezeSkills
                    ? null
                    : onBuyFreeze,
              ),
              _SkillActionButton(
                icon: CupertinoIcons.location,
                label: 'matrix.freezeSelected'.tr,
                onPressed: actionsBusy ||
                        !data.canUseFreezeSkills ||
                        selectedOpponent.isEmpty ||
                        (status?.freezeTokens ?? 0) == 0
                    ? null
                    : onFreeze,
              ),
              _SkillActionButton(
                icon: CupertinoIcons.drop,
                label:
                    '${'matrix.unfreezeNow'.tr} · ${_usdc(status?.unfreezePriceUsdc ?? BigInt.from(1000000))} USDC',
                onPressed:
                    actionsBusy || !data.playerFrozen ? null : onUnfreeze,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'matrix.participants'.tr,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topLeft,
            child: data.participants.isEmpty
                ? Text(
                    'matrix.noParticipants'.tr,
                    key: const ValueKey('participants-empty'),
                    style: const TextStyle(color: Colors.white38),
                  )
                : Wrap(
                    key: const ValueKey('participants-list'),
                    spacing: 8,
                    runSpacing: 8,
                    children: data.participants.map((participant) {
                      final selected = participant.wallet.toLowerCase() ==
                          selectedOpponent.toLowerCase();
                      return ChoiceChip(
                        selected: selected,
                        onSelected: participant.isCurrentPlayer ||
                                participant.skillStatus?.immune == true
                            ? null
                            : (_) => onSelectOpponent(participant.wallet),
                        avatar: Icon(
                          participant.skillStatus?.frozen == true
                              ? CupertinoIcons.snow
                              : participant.skillStatus?.immune == true
                                  ? CupertinoIcons.shield_fill
                              : participant.isInvited
                                  ? CupertinoIcons.person_badge_plus
                                  : CupertinoIcons.person,
                          size: 16,
                          color: participant.skillStatus?.frozen == true
                              ? Colors.lightBlueAccent
                              : participant.skillStatus?.immune == true
                                  ? Colors.greenAccent
                              : participant.isInvited
                                  ? EasyGameTheme.purple
                                  : EasyGameTheme.teal,
                        ),
                        label: Text(
                          '#${participant.cellId} ${_shortAddress(participant.wallet)}'
                          '${participant.isCurrentPlayer ? ' · ${'matrix.you'.tr}' : ''}'
                          '${participant.isInvited ? ' · ${'matrix.invited'.tr}' : ''}'
                          '${participant.skillStatus?.immune == true ? ' · ${'matrix.immune'.tr}' : ''}',
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  String _usdc(BigInt value) {
    final whole = value ~/ BigInt.from(1000000);
    final fraction = (value % BigInt.from(1000000))
        .toString()
        .padLeft(6, '0')
        .replaceFirst(RegExp(r'0+$'), '');
    return fraction.isEmpty ? '$whole' : '$whole.$fraction';
  }

  String _formatArenaDate(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(local.day)}.${two(local.month)} ${two(local.hour)}:${two(local.minute)}';
  }
}

class _ArenaStatusValue extends StatelessWidget {
  final String label;
  final String value;

  const _ArenaStatusValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label: $value',
      style: const TextStyle(color: Colors.white54, fontSize: 12),
    );
  }
}

class _SkillActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _SkillActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: EasyGameTheme.purple,
        disabledBackgroundColor: Colors.white10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}
