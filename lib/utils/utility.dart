final class Utility {
  Utility._();

  static Utility instance = Utility._();

  Future<bool> completedWithinDeadline({
    required Duration deadline,
    required Future<bool> Function() future,
    Duration tick = const Duration(milliseconds: 100),
  }) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    bool completed = false;
    await Future.doWhile(() async {
      completed = await future();
      if (completed ||
          stopwatch.elapsedMilliseconds > deadline.inMilliseconds) {
        return false;
      } else {
        await Future.delayed(tick);
        return true;
      }
    });

    return completed;
  }
}
