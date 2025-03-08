import 'package:animators_gif_enjoyer/functionality/zooming.dart';
import 'package:animators_gif_enjoyer/gif_view_pharan/gif_view.dart';
import 'package:animators_gif_enjoyer/main_screen/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const delayedTooltipDelay = Duration(milliseconds: 200);
const slowTooltipDelay = Duration(milliseconds: 600);

class GifViewContainer extends StatelessWidget {
  const GifViewContainer({
    super.key,
    required this.gifImageProvider,
    required this.gifController,
    this.allowWideSliderNotifier,
    this.isAppBusy = false,
    this.zoomLevelNotifier,
    this.fitZoomGetter,
    this.hardMinZoomGetter,
    this.hardMaxZoomGetter,
  });

  final ImageProvider<Object>? gifImageProvider;
  final GifController gifController;
  final double Function()? fitZoomGetter;
  final double Function()? hardMinZoomGetter;
  final double Function()? hardMaxZoomGetter;
  final ValueNotifier<double>? zoomLevelNotifier;
  final ValueNotifier<bool>? allowWideSliderNotifier;
  final bool isAppBusy;

  @override
  Widget build(BuildContext context) {
    return ScrollZoomContainer(
      notifier: zoomLevelNotifier,
      fitZoomGetter: fitZoomGetter,
      hardMaxZoomGetter: hardMaxZoomGetter,
      hardMinZoomGetter: hardMinZoomGetter,
      child: GifView(
        image: gifImageProvider,
        controller: gifController,
      ),
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
        return Tooltip(
          message: 'Toggle play/pause.\nYou can also click on the gif.',
          waitDuration: slowTooltipDelay,
          child: IconButton(
            style: const ButtonStyle(
              maximumSize: WidgetStatePropertyAll(Size(100, 100)),
            ),
            onPressed: onPressed,
            icon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Icon(
                color: Theme.of(context).colorScheme.mutedSurfaceColor,
                isPausedAndScrubbing ? Icons.play_arrow : Icons.pause,
              ),
            ),
          ),
        );
      },
    );
  }
}

class EnjoyerBottomTextPanel extends StatelessWidget {
  const EnjoyerBottomTextPanel({
    super.key,
    required this.textController,
    required this.onTextFieldSubmitted,
    required this.onSubmitButtonPressed,
  });

  final TextEditingController textController;
  final Function(String) onTextFieldSubmitted;
  final VoidCallback onSubmitButtonPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Material(
            type: MaterialType.canvas,
            borderRadius: const BorderRadius.only(
              topLeft: borderRadiusRadius,
              topRight: borderRadiusRadius,
            ),
            elevation: 20,
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Material(
                    type: MaterialType.canvas,
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: textController,
                            style: const TextStyle(fontSize: 13),
                            decoration: const InputDecoration(
                              hintText: 'Enter GIF link',
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                    width: 0, style: BorderStyle.none),
                              ),
                            ),
                            autocorrect: false,
                            onSubmitted: onTextFieldSubmitted,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: IconButton(
                            onPressed: onSubmitButtonPressed,
                            icon: const Icon(Icons.send),
                            tooltip: 'Download GIF from Link',
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
