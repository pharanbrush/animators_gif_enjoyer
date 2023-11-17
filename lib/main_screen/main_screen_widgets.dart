import 'package:animators_gif_enjoyer/gif_view_pharan/gif_view.dart';
import 'package:animators_gif_enjoyer/main_screen/theme.dart';
import 'package:animators_gif_enjoyer/utils/build_info.dart';
import 'package:contextual_menu/contextual_menu.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class GifViewContainer extends StatelessWidget {
  const GifViewContainer({
    super.key,
    required this.gifImageProvider,
    required this.gifController,
    required this.copyImageHandler,
    required this.openImageHandler,
    required this.pasteHandler,
  });

  final ImageProvider<Object>? gifImageProvider;
  final GifController gifController;
  final VoidCallback copyImageHandler;
  final VoidCallback openImageHandler;
  final VoidCallback pasteHandler;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTap: () => popUpContextualMenu(menu(context)),
      child: GifView(
        image: gifImageProvider!,
        controller: gifController,
      ),
    );
  }

  Menu menu(BuildContext context) {
    return Menu(
      items: [
        MenuItem(
          label: 'Open GIF...',
          onClick: (_) => openImageHandler(),
        ),
        MenuItem(
          label: 'Paste to address bar...',
          onClick: (_) => pasteHandler(),
        ),
        MenuItem.separator(),
        MenuItem(
          label: 'Copy frame image',
          onClick: (_) => copyImageHandler(),
        ),
        MenuItem.separator(),
        if (packageInfo != null)
          MenuItem(
            label: 'Build $buildName',
            disabled: true,
          )
      ],
    );
  }
}

class BottomPlayPauseButton extends StatelessWidget {
  const BottomPlayPauseButton({
    super.key,
    required this.isScrubMode,
    this.onPressed,
  });

  final ValueListenable<bool> isScrubMode;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isScrubMode,
      builder: (_, isPausedAndScrubbing, __) {
        return IconButton(
          style: const ButtonStyle(
            maximumSize: MaterialStatePropertyAll(Size(100, 100)),
          ),
          onPressed: onPressed,
          tooltip: 'Toggle play/pause.\nYou can also click on the gif.',
          icon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: Icon(
              color: Theme.of(context).colorScheme.mutedSurfaceColor,
              isPausedAndScrubbing ? Icons.play_arrow : Icons.pause,
            ),
          ),
        );
      },
    );
  }
}

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
  });

  final VoidCallback? onChange;
  final VoidCallback? onChangeRangeStart;
  final VoidCallback? onChangeRangeEnd;
  final VoidCallback? onChangeTapUp;
  final ValueNotifier<RangeValues> startEnd;
  final ValueNotifier<int> maxFrameIndex;
  final bool enabled;

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
          Text('0', style: Theme.of(context).smallGrayStyle),
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
                      labels: RangeLabels('${currentStartEnd.startInt}',
                          '${currentStartEnd.endInt}'),
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
          Text('${maxFrameIndex.value}',
              style: Theme.of(context).smallGrayStyle),
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
  });

  final VoidCallback toggleUseFocus;
  final RangeValues primarySliderRange;
  final ValueNotifier<bool> isUsingFocusRange;
  final ValueNotifier<int> currentFrame;
  final GifController gifController;
  final VoidCallback onChange;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ToggleFocusButton(
          label: '${primarySliderRange.startInt}',
          handleToggle: () => toggleUseFocus(),
          isFocusing: isUsingFocusRange.value,
          enabled: enabled,
        ),
        ValueListenableBuilder(
          valueListenable: currentFrame,
          builder: (_, currentFrameValue, __) {
            final sliderMin = primarySliderRange.start;
            final sliderMax = primarySliderRange.end;

            const int minFramesBeforeShrink = 7;
            const int reallyShortFrames = 4;
            const double maximumSpacePerFrame = 40;
            final limitedFrameCount = sliderMax - sliderMin;

            final double width = switch (limitedFrameCount) {
              (< reallyShortFrames) => reallyShortFrames * maximumSpacePerFrame,
              (< minFramesBeforeShrink) =>
                limitedFrameCount * maximumSpacePerFrame,
              _ => minFramesBeforeShrink * maximumSpacePerFrame
            };

            var slider = Slider(
              min: sliderMin,
              max: sliderMax,
              value: currentFrameValue.toDouble(),
              label: '$currentFrameValue',
              onChanged: enabled
                  ? (newValue) {
                      currentFrame.value = newValue.toInt();
                      onChange();
                    }
                  : null,
            );

            return SliderTheme(
              data: SliderThemeData(
                thumbColor: Theme.of(context).colorScheme.secondary,
                trackHeight: enabled ? 10 : 2,
                thumbShape: const RoundSliderThumbShape(
                  disabledThumbRadius: 0,
                  elevation: 2,
                ),
              ),
              child: SizedBox(
                width: width,
                child: Focus(
                  canRequestFocus: false,
                  autofocus: false,
                  skipTraversal: true,
                  descendantsAreFocusable: false,
                  descendantsAreTraversable: false,
                  child: slider,
                ),
              ),
            );
          },
        ),
        ToggleFocusButton(
          label: '${primarySliderRange.endInt}',
          handleToggle: () => toggleUseFocus(),
          isFocusing: isUsingFocusRange.value,
          enabled: enabled,
        ),
      ],
    );
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
      message: !enabled
          ? ''
          : isFocusing
              ? 'Click to disable frame range'
              : 'Click to use custom frame range',
      child: TextButton(
        style: const ButtonStyle(
          padding:
              MaterialStatePropertyAll(EdgeInsets.symmetric(horizontal: 0)),
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

// final List<(String label, ThemeMode themeMode)> itemsData = [
//   ('Light', ThemeMode.light),
//   ('Dark', ThemeMode.dark),
//   ('-', ThemeMode.system),
//   ('System', ThemeMode.system),
// ];

// MenuItem themeSubmenu(BuildContext context) {
//   ThemeContext? themeContext = ThemeContext.of(context);
//   if (themeContext == null) {
//     return MenuItem(
//       label: 'Themes',
//       disabled: true,
//     );
//   }

//   final themeModeNotifier = themeContext.themeMode;

//   final themeMode = themeModeNotifier.value;

//   MenuItem mapper(e) {
//     var (label, itemMode) = e;
//     switch (label) {
//       case '-':
//         return MenuItem.separator();
//       default:
//         return MenuItem.checkbox(
//           checked: themeMode == itemMode,
//           label: label,
//           onClick: (_) {
//             themeModeNotifier.value = itemMode;
//             storeThemePreference(itemMode);
//           },
//         );
//     }
//   }

//   final menuItems = itemsData.map(mapper).toList(growable: false);

//   return MenuItem.submenu(label: 'Theme', submenu: Menu(items: menuItems));
// }
