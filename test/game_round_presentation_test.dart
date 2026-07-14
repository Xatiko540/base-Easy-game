import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_advance/app/modules/home/widgets/game_round_presentation.dart';

void main() {
  String format(Duration duration) => formatRoundCardCountdown(
        duration,
        dayUnit: 'days',
        hourUnit: 'hours',
        minuteUnit: 'min',
        secondUnit: 'sec',
      );

  group('formatRoundCardCountdown', () {
    test('uses days for long waits shown by scheduled level cards', () {
      expect(format(const Duration(days: 4, hours: 3)), '4 days');
    });

    test('keeps total hours for shorter waits', () {
      expect(format(const Duration(hours: 31, minutes: 5)), '31 hours');
    });

    test('shows seconds when less than one hour remains', () {
      expect(format(const Duration(minutes: 45, seconds: 7)), '45 min 07 sec');
      expect(format(const Duration(seconds: 9)), '9 sec');
    });

    test('clamps expired countdowns to zero', () {
      expect(format(const Duration(seconds: -1)), '0 sec');
    });
  });
}
