/// Human readable time left until the next review becomes available.
///
/// Mirrors the home-screen rule: beyond 24 hours the value is rounded up to
/// whole days; below that a live `H:MM:SS` clock is shown.
class ReviewCountdown {
  final Duration remaining;

  const ReviewCountdown(this.remaining);

  factory ReviewCountdown.until(DateTime target, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final diff = target.difference(reference);
    return ReviewCountdown(diff.isNegative ? Duration.zero : diff);
  }

  bool get isOver => remaining <= Duration.zero;

  bool get usesDays => remaining.inHours >= 24;

  int get days => usesDays ? (remaining.inHours / 24).ceil() : 0;

  String get clock {
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);
    return '$hours:${_pad(minutes)}:${_pad(seconds)}';
  }

  String get label => usesDays ? (days == 1 ? '1 day' : '$days days') : clock;

  static String _pad(int value) => value.toString().padLeft(2, '0');
}
