import 'package:flutter/material.dart';
import 'package:nativeapi/nativeapi.dart';

import '../app/theme.dart';
import '../main_screen/menu_items.dart';
import '../phlutter/phmaterial/frame_slider.dart';
import '../phlutter/phmaterial/material_desktop.dart';
import '../phlutter/widget/preferences_stored_bool.dart';
import '../phlutter/widget/scroll_listener.dart';

class FrameRangeSlider extends StatelessWidget {
  const FrameRangeSlider({
    super.key,
    required this.startEnd,
    required this.maxFrameIndex,
    this.enabled = true,
    this.onChange,
    this.onChangeRangeStart,
    this.onChangeRangeEnd,
    this.onChangeTapUp,
    this.displayedFrameOffset = 0,
  });

  final VoidCallback? onChange;
  final VoidCallback? onChangeRangeStart;
  final VoidCallback? onChangeRangeEnd;
  final VoidCallback? onChangeTapUp;
  final ValueNotifier<RangeValues> startEnd;
  final ValueNotifier<int> maxFrameIndex;
  final bool enabled;
  final int displayedFrameOffset;

  static const mainSliderTheme = SliderThemeData(
    trackHeight: 2,
    thumbShape: RoundSliderThumbShape(
      disabledThumbRadius: 3,
      enabledThumbRadius: 4,
    ),
    rangeThumbShape: VerticalPillRangeSliderThumbShape(),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        children: [
          Text(
            '$displayedFrameOffset',
            style: Theme.of(context).smallGrayStyle,
          ),
          Expanded(
            child: Theme(
              data: focusTheme,
              child: SliderTheme(
                data: mainSliderTheme.copyWith(
                  thumbColor: focusTheme.colorScheme.inversePrimary,
                ),
                child: ValueListenableBuilder(
                  valueListenable: startEnd,
                  builder: (_, currentStartEnd, _) {
                    return RangeSlider(
                      values: currentStartEnd,
                      min: 0,
                      max: maxFrameIndex.value.toDouble(),
                      labels: RangeLabels(
                        '${(currentStartEnd.startInt + displayedFrameOffset)}',
                        '${(currentStartEnd.endInt + displayedFrameOffset)}',
                      ),
                      onChanged: enabled
                          ? (newValue) {
                              final oldValue = startEnd.value;

                              final pushedValue = RangeValues(
                                newValue.start.floorToDouble(),
                                newValue.end.floorToDouble(),
                              );
                              startEnd.value = pushedValue;

                              onChange?.call();

                              if (oldValue.startInt != newValue.startInt) {
                                onChangeRangeStart?.call();
                              } else if (oldValue.endInt != newValue.endInt) {
                                onChangeRangeEnd?.call();
                              }
                            }
                          : null,
                      onChangeEnd: enabled
                          ? (_) => onChangeTapUp?.call()
                          : null,
                    );
                  },
                ),
              ),
            ),
          ),
          Text(
            '${(maxFrameIndex.value + displayedFrameOffset)}',
            style: Theme.of(context).smallGrayStyle,
          ),
        ],
      ),
    );
  }
}

class MainSlider extends StatelessWidget {
  const MainSlider({
    super.key,
    required this.toggleUseFocus,
    required this.primarySliderRange,
    required this.isUsingFocusRange,
    required this.currentFrame,
    required this.enabled,
    required this.allowWidePreference,
    required this.allowWrapAroundPreference,
    required this.incrementFunction,
    required this.markerNotifier,
    required this.snapModeNotifier,
    this.onSecondaryTapOnFrame,
    this.frameMarkers,
    this.displayedFrameOffset = 0,
  });

  final int displayedFrameOffset;
  final VoidCallback toggleUseFocus;
  final RangeValues primarySliderRange;
  final ValueNotifier<bool> isUsingFocusRange;
  final ValueNotifier<int> currentFrame;
  final PreferencesStoredBool allowWidePreference;
  final PreferencesStoredBool allowWrapAroundPreference;
  final ValueNotifier<SnapMode> snapModeNotifier;
  final ChangeNotifier? markerNotifier;
  final void Function(int increment) incrementFunction;
  final void Function(int frame)? onSecondaryTapOnFrame;
  final Iterable<int>? frameMarkers;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    Widget sliderPart() => ListenableBuilder(
      listenable: Listenable.merge([
        allowWidePreference.valueNotifier,
        allowWrapAroundPreference.valueNotifier,
        markerNotifier,
        snapModeNotifier,
      ]),
      builder: (_, _) {
        Widget insideExpanded() => Padding(
          padding: const .symmetric(horizontal: 6),
          child: ValueListenableBuilder(
            valueListenable: currentFrame,
            builder: (_, currentFrameValue, _) {
              final sliderMin = primarySliderRange.start;
              final sliderMax = primarySliderRange.end;

              const int minFramesBeforeShrink = 7;
              const int reallyFewFrames = 4;
              const double maximumSpacePerFrame = 40;
              final limitedFrameCount = sliderMax - sliderMin;

              final double width = switch (limitedFrameCount) {
                (< reallyFewFrames) => reallyFewFrames * maximumSpacePerFrame,
                (< minFramesBeforeShrink) =>
                  limitedFrameCount * maximumSpacePerFrame,
                _ => minFramesBeforeShrink * maximumSpacePerFrame,
              };

              Widget slider() => FrameSlider(
                min: sliderMin.toInt(),
                max: sliderMax.toInt(),
                value: currentFrameValue,
                wrapWhenDragging: allowWrapAroundPreference.value,
                frameMarkers: frameMarkers,
                snapMode: snapModeNotifier.value,
                onSecondaryTapOnFrame: onSecondaryTapOnFrame,
                onChanged: enabled
                    ? (newValue) => currentFrame.value = newValue
                    : null,
              );

              return GestureDetector(
                onTertiaryTapDown: (_) => allowWidePreference.toggle(),
                child: SizedBox(
                  width: allowWidePreference.value ? null : width,
                  child: Focus(
                    canRequestFocus: false,
                    autofocus: false,
                    skipTraversal: true,
                    descendantsAreFocusable: false,
                    descendantsAreTraversable: false,
                    child: ScrollListener(
                      onScrollUp: () => incrementFunction(1),
                      onScrollDown: () => incrementFunction(-1),
                      child: slider(),
                    ),
                  ),
                ),
              );
            },
          ),
        );

        return allowWidePreference.value
            ? Expanded(child: insideExpanded())
            : insideExpanded();
      },
    );

    final firstFrame = primarySliderRange.startInt;
    final firstFrameDisplay = firstFrame + displayedFrameOffset;

    final lastFrame = primarySliderRange.endInt;
    final lastFrameDisplay = lastFrame + displayedFrameOffset;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ListenableBuilder(
          listenable: currentFrame,
          builder: (context, child) {
            return StartEndFrameButton(
              label: firstFrameDisplay.toString(),
              isCurrentFrame: currentFrame.value == firstFrame,
              onClick: () => currentFrame.value = firstFrame,
              onTriggerCustomFrameRange: () => toggleUseFocus(),
              isCustomFrameRangeEnabled: isUsingFocusRange.value,
              enabled: enabled,
            );
          },
        ),
        sliderPart(),
        ListenableBuilder(
          listenable: currentFrame,
          builder: (context, child) {
            return StartEndFrameButton(
              label: lastFrameDisplay.toString(),
              isCurrentFrame: currentFrame.value == lastFrame,
              onClick: () => currentFrame.value = lastFrame,
              onTriggerCustomFrameRange: () => toggleUseFocus(),
              isCustomFrameRangeEnabled: isUsingFocusRange.value,
              enabled: enabled,
            );
          },
        ),
      ],
    );
  }
}

class StartEndFrameButton extends StatelessWidget {
  const StartEndFrameButton({
    super.key,
    required this.label,
    required this.onClick,
    required this.onTriggerCustomFrameRange,
    required this.isCustomFrameRangeEnabled,
    required this.isCurrentFrame,
    required this.enabled,
  });

  final String label;
  final bool isCurrentFrame;
  final VoidCallback onClick;
  final VoidCallback onTriggerCustomFrameRange;
  final bool isCustomFrameRangeEnabled;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    const customFocusStyle = TextStyle(color: focusRangeColor);

    return GestureDetector(
      onDoubleTap: isCurrentFrame ? () => onTriggerCustomFrameRange() : null,
      onSecondaryTap: () {
        Menu()
          ..addMenuItem(
            isCustomFrameRangeEnabled
                ? "Disable custom frame range"
                : "Enable custom frame range",
            onClick: onTriggerCustomFrameRange,
          )
          ..open(.cursorPosition());
      },
      onTertiaryTapDown: (_) => onTriggerCustomFrameRange(),
      child: TextButton(
        style: const ButtonStyle(
          padding: WidgetStatePropertyAll(.symmetric(horizontal: 0)),
          minimumSize: WidgetStatePropertyAll(Size(50, 40)),
        ),
        onPressed: enabled ? onClick : null,
        child: Text(
          label,
          style: isCustomFrameRangeEnabled
              ? customFocusStyle
              : Theme.of(context).grayStyle,
        ),
      ),
    );
  }
}

extension RangeValuesExtensions on RangeValues {
  int get endInt => end.toInt();
  int get startInt => start.toInt();

  double get rangeSize => end - start;
}
