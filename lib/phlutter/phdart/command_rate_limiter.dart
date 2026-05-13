/// Provides a [queueCommand] method that
/// limits too many calls to the function being passed.
class CommandRateLimiter {
  CommandRateLimiter({
    this.delay = const Duration(milliseconds: 250),
  });

  int _queuedCommandId = 0;
  final Duration delay;

  Future<void> queueCommand(Function() commandFunction) async {
    int getLatestSaveCommandId() => _queuedCommandId;
    int currentCommandId = DateTime.now().millisecondsSinceEpoch;
    _queuedCommandId = currentCommandId;

    for (int i = 0; i < 5; i++) {
      await Future.delayed(delay);
      if (getLatestSaveCommandId() != currentCommandId) return;
    }

    if (getLatestSaveCommandId() == currentCommandId) {
      commandFunction();
    }
  }
}
