import 'package:animators_gif_enjoyer/gif_view_pharan/gif_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

class FrameAdvancer {
  FrameAdvancer({
    required TickerProvider tickerProvider,
    required this.currentFrameNotifier,
  }) {
    ticker = tickerProvider.createTicker(_handleTick);
  }

  late final Ticker ticker;

  bool enabled = false;
  double timeScale = 1;
  Duration _accumulatedDuration = Duration.zero;
  Duration _lastTime = Duration.zero;
  int _start = 0;
  int _last = 0;
  final ValueNotifier<int> currentFrameNotifier;
  List<AnimationFrame> _frames = [];

  int getLastFrameIndex() => _frames.length - 1;

  void dispose() {
    ticker.dispose();
  }

  void reset() {
    _accumulatedDuration = Duration.zero;
    _lastTime = Duration.zero;
  }

  void setFrames(List<AnimationFrame> frames) {
    _frames = frames;
    _start = 0;
    _last = getLastFrameIndex();
    currentFrameNotifier.value = 0;
  }

  void play({
    int? start,
    int? last,
    int? current,
  }) {
    int candidateStart = start ?? 0;
    int lastIndexInFrames = getLastFrameIndex();
    int candidateLast = last ?? lastIndexInFrames;

    if (candidateStart < 0) candidateStart = 0;
    if (candidateLast > lastIndexInFrames) candidateLast = lastIndexInFrames;
    if (candidateStart > candidateLast) return;

    int candidateCurrent = current ?? candidateStart;
    if (candidateCurrent < candidateStart) candidateCurrent = candidateStart;
    if (candidateCurrent > candidateLast) candidateCurrent = candidateLast;

    _start = candidateStart;
    _last = candidateLast;
    currentFrameNotifier.value = candidateCurrent;
    _lastTime = Duration.zero;
    enabled = true;
    ticker.start();

    _accumulatedDuration = Duration.zero;
  }

  void pause() {
    enabled = false;
    _accumulatedDuration = Duration.zero;
    _lastTime = Duration.zero;
    ticker.stop();
  }

  void _handleTick(Duration currentTickerTime) {
    if (!enabled) return;

    final unscaledDeltaTime = currentTickerTime - _lastTime;
    final deltaTime = unscaledDeltaTime * timeScale;
    _accumulatedDuration += deltaTime;

    const maxFrameSkip = 4;
    const lastFrameSkip = maxFrameSkip - 1;
    const zeroDefaultDuration = Duration(milliseconds: 100);

    bool wasUpdatedFrame = false;

    int newCurrentFrame = currentFrameNotifier.value;
    for (var i = 0; i < maxFrameSkip; i++) {
      final currentDurationData = _frames[newCurrentFrame].duration;
      final currentFrameDuration = currentDurationData > Duration.zero
          ? currentDurationData
          : zeroDefaultDuration;

      if (_accumulatedDuration >= currentFrameDuration) {
        _accumulatedDuration -= currentFrameDuration;
        if (i == lastFrameSkip) _accumulatedDuration = Duration.zero;

        newCurrentFrame++;
        if (newCurrentFrame > _last) {
          newCurrentFrame = _start;
        }
        wasUpdatedFrame = true;
      } else {
        break;
      }
    }

    if (wasUpdatedFrame) {
      currentFrameNotifier.value = newCurrentFrame;
    }
    _lastTime = currentTickerTime;
  }
}
