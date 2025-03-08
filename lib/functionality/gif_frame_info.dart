import 'package:animators_gif_enjoyer/main_screen/gif_mixins.dart';

bool isFpsWhole(double fps) {
  //return fps - fps.truncate() == 0;
  return fps.floorToDouble() == fps;
}

bool showWeirdFramerateWarning(GifInfo gifInfo) {
  if (gifInfo.isNonAnimated) {
    return false;
  }

  if (gifInfo.isImageSequence) {
    return false;
  }

  var frameDuration = gifInfo.frameDuration;
  if (frameDuration == null) {
    return false;
  }

  final frameMilliseconds = frameDuration.inMilliseconds;
  final fpsDouble = 1000.0 / frameMilliseconds;
  if (frameMilliseconds > 0 && isFpsWhole(fpsDouble)) {
    return false;
  }

  return true;
}

String getFramerateTooltipMessage(GifInfo gifInfo) {
  final duration = gifInfo.frameDuration;
  if (duration == null) return '';

  final frameMilliseconds = duration.inMilliseconds;

  String message =
      'GIF frames are each encoded with intervals in 10 millisecond increments.\n'
      'This makes their actual framerate potentially variable,\n'
      'and often not precisely fitting common video framerates.';
  if (frameMilliseconds <= 10) {
    message = 'Browsers usually reinterpret delays\n'
        'below 20 milliseconds as 100 milliseconds.';
  }

  return message;
}

String getFramerateLabel(GifInfo gifInfo) {
  if (gifInfo.isNonAnimated) {
    return 'Not animated ';
  }

  const millisecondsUnit = 'ms';
  const msPerFrameUnit = '$millisecondsUnit/frame';

  final frameDuration = gifInfo.frameDuration;
  switch (frameDuration) {
    case null:
      return 'Variable frame durations';
    case <= const Duration(milliseconds: 10):
      return '${frameDuration.inMilliseconds} $msPerFrameUnit';
    default:
      final frameMicroseconds = frameDuration.inMicroseconds;
      final fps = 1000000.0 / frameMicroseconds;
      final frameMilliseconds = frameMicroseconds / 1000.0; // prevent rounding.

      final fpsText = isFpsWhole(fps)
          ? fps.toStringAsFixed(0)
          : "~${fps.toStringAsFixed(2)}";
      final millisecondsText =
          (frameMilliseconds - frameMilliseconds.truncate() == 0)
              ? frameMilliseconds.toStringAsFixed(0)
              : frameMilliseconds.toStringAsFixed(2);

      return '$fpsText fps '
          '($millisecondsText $msPerFrameUnit) ';
  }
}
