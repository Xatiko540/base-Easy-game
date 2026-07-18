import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/models/game_round_models.dart';
import 'package:lottery_advance/app/modules/home/widgets/game_round_presentation.dart';
import 'package:lottery_advance/utils/theme.dart';

class RoundCardTimer extends StatelessWidget {
  const RoundCardTimer({
    super.key,
    required this.round,
    this.prominent = true,
  });

  final GameRoundViewState round;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final schedule = round.schedule;
    final label = _labelFor(round.phase);
    final color = _colorFor(round.phase);
    final countdown = _countdown(round);
    final timer = prominent
        ? _ProminentRoundTimer(
            label: label,
            countdown: countdown,
            color: color,
          )
        : _CompactRoundTimer(
            label: label,
            countdown: countdown,
            color: color,
          );

    return Tooltip(
      message: localizedRoundScheduleRange(schedule),
      child: timer,
    );
  }

  String _labelFor(GameRoundPhase phase) {
    switch (phase) {
      case GameRoundPhase.scheduled:
        return 'round.startsInLabel'.tr;
      case GameRoundPhase.open:
        return 'round.entriesCloseInLabel'.tr;
      case GameRoundPhase.locked:
        return 'round.endsInLabel'.tr;
      default:
        return roundPhaseTranslationKey(phase).tr;
    }
  }

  Color _colorFor(GameRoundPhase phase) {
    switch (phase) {
      case GameRoundPhase.open:
        return EasyGameTheme.teal;
      case GameRoundPhase.scheduled:
      case GameRoundPhase.locked:
        return EasyGameTheme.orange;
      default:
        return EasyGameTheme.textMuted;
    }
  }
}

class InlineRoundCountdown extends StatelessWidget {
  const InlineRoundCountdown({super.key, required this.round});

  final GameRoundViewState round;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: localizedRoundScheduleRange(round.schedule),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            CupertinoIcons.stopwatch,
            size: 14,
            color: EasyGameTheme.orange,
          ),
          const SizedBox(width: 4),
          Text(
            _countdown(round),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: EasyGameTheme.orange,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

String _countdown(GameRoundViewState round) => localizedRoundCountdown(round);

class _CompactRoundTimer extends StatelessWidget {
  const _CompactRoundTimer({
    required this.label,
    required this.countdown,
    required this.color,
  });

  final String label;
  final String countdown;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(CupertinoIcons.stopwatch, size: 25, color: color),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: EasyGameTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                countdown,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProminentRoundTimer extends StatelessWidget {
  const _ProminentRoundTimer({
    required this.label,
    required this.countdown,
    required this.color,
  });

  final String label;
  final String countdown;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(CupertinoIcons.stopwatch, size: 42, color: color),
        const SizedBox(height: 10),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: EasyGameTheme.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            countdown,
            maxLines: 1,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}
