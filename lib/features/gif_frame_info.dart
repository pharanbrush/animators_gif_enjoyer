import 'package:animators_gif_enjoyer/main_screen/gif_mixins.dart';

bool isFpsWhole(double fps) {
  //return fps - fps.truncate() == 0;
  return fps.floorToDouble() == fps;
}

bool showWeirdFramerateWarning(AnimationInfo animationInfo) {
  if (animationInfo.isNonAnimated) {
    return false;
  }

  if (!animationInfo.isGif) {
    return false;
  }

  if (animationInfo.isImageSequence) {
    return false;
  }

  var frameDuration = animationInfo.frameDuration;
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

String getFramerateTooltipMessage(AnimationInfo animationInfo) {
  final duration = animationInfo.frameDuration;
  if (duration == null) return '';

  if (!animationInfo.isGif) return '';

  final frameMilliseconds = duration.inMilliseconds;

  String message =
      'GIF frames are each encoded with intervals in 10 millisecond increments.\n'
      'This makes their actual framerate potentially variable,\n'
      'and often not precisely fitting common video framerates.';
  if (frameMilliseconds <= 10) {
    message =
        'Browsers usually reinterpret delays\n'
        'below 20 milliseconds as 100 milliseconds.';
  }

  return message;
}

String getFramerateLabel(AnimationInfo animationInfo) {
  if (animationInfo.isNonAnimated) {
    return 'Not animated ';
  }

  const millisecondsUnit = 'ms';
  const msPerFrameUnit = '$millisecondsUnit/frame';

  final frameDuration = animationInfo.frameDuration;
  {
    if (frameDuration == null) {
      return 'Variable frame durations';
    }

    if (animationInfo.isGif &&
        frameDuration <= const Duration(milliseconds: 10)) {
      return '${frameDuration.inMilliseconds} $msPerFrameUnit';
    }

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
