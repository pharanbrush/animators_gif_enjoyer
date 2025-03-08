import 'package:animators_gif_enjoyer/gif_view_pharan/gif_view.dart';
import 'package:animators_gif_enjoyer/main_screen/theme.dart';
import 'package:animators_gif_enjoyer/phlutter/windows/scroll_listener.dart';
import 'package:flutter/material.dart';
import 'package:animators_gif_enjoyer/main_screen/gif_enjoyer_preferences.dart'
    as gif_enjoyer_preferences;

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
                  builder: (_, currentStartEnd, __) {
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
                      onChangeEnd:
                          enabled ? (_) => onChangeTapUp?.call() : null,
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
    required this.gifController,
    required this.enabled,
    required this.onChange,
    required this.allowWideNotifier,
    this.displayedFrameOffset = 0,
  });

  final int displayedFrameOffset;
  final VoidCallback toggleUseFocus;
  final RangeValues primarySliderRange;
  final ValueNotifier<bool> isUsingFocusRange;
  final ValueNotifier<int> currentFrame;
  final ValueNotifier<bool> allowWideNotifier;
  final GifController gifController;
  final VoidCallback onChange;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final sliderPart = ValueListenableBuilder(
      valueListenable: allowWideNotifier,
      builder: (_, allowWideValue, __) {
        var insideExpanded = ValueListenableBuilder(
          valueListenable: currentFrame,
          builder: (_, currentFrameValue, __) {
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
              _ => minFramesBeforeShrink * maximumSpacePerFrame
            };

            var slider = Slider(
              min: sliderMin,
              max: sliderMax,
              value: currentFrameValue.toDouble(),
              label: '${(currentFrameValue + displayedFrameOffset)}',
              onChanged: enabled
                  ? (newValue) {
                      currentFrame.value = newValue.toInt();
                      onChange();
                    }
                  : null,
            );

            var originalSliderThemeData = Theme.of(context).sliderTheme;
            return SliderTheme(
              data: originalSliderThemeData.copyWith(
                thumbColor: Theme.of(context).colorScheme.secondary,
                trackHeight: enabled ? 10 : 2,
                thumbShape: const RoundSliderThumbShape(
                  disabledThumbRadius: 0,
                  elevation: 2,
                ),
              ),
              child: GestureDetector(
                onTertiaryTapDown: (_) async {
                  gif_enjoyer_preferences
                      .storeAllowWideSliderPreference(!allowWideNotifier.value);
                  allowWideNotifier.value = await gif_enjoyer_preferences
                      .getAllowWideSliderPreference();
                },
                child: SizedBox(
                  width: allowWideValue ? null : width,
                  child: Focus(
                    canRequestFocus: false,
                    autofocus: false,
                    skipTraversal: true,
                    descendantsAreFocusable: false,
                    descendantsAreTraversable: false,
                    child: ScrollListener(
                      onScrollUp: () => increment(currentFrame, 1),
                      onScrollDown: () => increment(currentFrame, -1),
                      child: slider,
                    ),
                  ),
                ),
              ),
            );
          },
        );

        return allowWideValue
            ? Expanded(child: insideExpanded)
            : insideExpanded;
      },
    );

    final row = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ToggleFocusButton(
          label: '${(primarySliderRange.startInt + displayedFrameOffset)}',
          handleToggle: () => toggleUseFocus(),
          isFocusing: isUsingFocusRange.value,
          enabled: enabled,
        ),
        sliderPart,
        ToggleFocusButton(
          label: '${(primarySliderRange.endInt + displayedFrameOffset)}',
          handleToggle: () => toggleUseFocus(),
          isFocusing: isUsingFocusRange.value,
          enabled: enabled,
        ),
      ],
    );

    return row;
  }

  void increment(ValueNotifier<int> notifier, int incrementSign) {
    notifier.value = notifier.value + incrementSign.sign;
    onChange();
  }
}

class ToggleFocusButton extends StatelessWidget {
  const ToggleFocusButton({
    super.key,
    required this.label,
    required this.handleToggle,
    required this.isFocusing,
    required this.enabled,
  });

  final String label;
  final VoidCallback handleToggle;
  final bool isFocusing;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    const customFocusStyle = TextStyle(color: focusRangeColor);

    return Tooltip(
      preferBelow: false,
      message: !enabled
          ? ''
          : isFocusing
              ? 'Click to disable frame range'
              : 'Click to use custom frame range',
      child: TextButton(
        style: const ButtonStyle(
          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 0)),
        ),
        onPressed: enabled ? handleToggle : null,
        child: Text(
          label,
          style: isFocusing ? customFocusStyle : Theme.of(context).grayStyle,
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
