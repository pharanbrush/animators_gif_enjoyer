import 'package:animators_gif_enjoyer/gif_view_pharan/gif_view.dart';
import 'package:flutter/scheduler.dart';

class GifFrameAdvancer {
  GifFrameAdvancer({required TickerProvider tickerProvider, this.onFrame}) {
    ticker = tickerProvider.createTicker(_handleTick);
  }

  final Function(int frameIndex)? onFrame;
  late final Ticker ticker;

  bool enabled = false;
  double timeScale = 1;
  Duration _accumulatedDuration = Duration.zero;
  Duration _lastTime = Duration.zero;
  int _start = 0;
  int _last = 0;
  int _current = 0;
  List<GifFrame> _frames = [];

  int getLastFrameIndex() => _frames.length - 1;

  void dispose() {
    ticker.dispose();
  }

  void reset() {
    _accumulatedDuration = Duration.zero;
    _lastTime = Duration.zero;
  }

  void setFrames(List<GifFrame> frames) {
    _frames = frames;
    _start = 0;
    _last = getLastFrameIndex();
    _current = 0;
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
    _current = candidateCurrent;
    _lastTime = Duration.zero;
    enabled = true;
    ticker.start();

    _accumulatedDuration = Duration.zero;

    onFrame?.call(_current);
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

    const maxTimeSkip = Duration(milliseconds: 300);
    if (_accumulatedDuration > maxTimeSkip) {
      _accumulatedDuration = maxTimeSkip;
    }

    const maxFrameSkip = 4;
    bool wasUpdatedFrame = false;
    for (var i = 0; i < maxFrameSkip; i++) {
      final currentFrameDuration = _frames[_current].duration;
      if (_accumulatedDuration >= currentFrameDuration) {
        _accumulatedDuration -= currentFrameDuration;

        _current++;
        if (_current > _last) {
          _current = _start;
        }
        wasUpdatedFrame = true;
      } else {
        break;
      }
    }

    if (wasUpdatedFrame) onFrame?.call(_current);
    _lastTime = currentTickerTime;
  }
}
