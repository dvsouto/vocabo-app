import 'package:test/test.dart';
import 'package:vocabo_core/vocabo_core.dart';

void main() {
  test('rounds up to whole days beyond 24 hours', () {
    final countdown = ReviewCountdown(const Duration(hours: 35));

    expect(countdown.usesDays, isTrue);
    expect(countdown.days, 2);
    expect(countdown.label, '2 days');
  });

  test('uses a singular label for exactly one day', () {
    final countdown = ReviewCountdown(const Duration(hours: 24));

    expect(countdown.label, '1 day');
  });

  test('shows a clock below 24 hours', () {
    final countdown = ReviewCountdown(
      const Duration(hours: 23, minutes: 59, seconds: 25),
    );

    expect(countdown.usesDays, isFalse);
    expect(countdown.label, '23:59:25');
  });

  test('clamps past targets to zero', () {
    final now = DateTime(2026, 10, 10, 12);
    final countdown = ReviewCountdown.until(
      now.subtract(const Duration(minutes: 5)),
      now: now,
    );

    expect(countdown.isOver, isTrue);
    expect(countdown.label, '0:00:00');
  });
}
