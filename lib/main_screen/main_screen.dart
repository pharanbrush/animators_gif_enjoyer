import 'dart:ui' as ui;

import 'package:animators_gif_enjoyer/gif_view_pharan/gif_view.dart';
import 'package:animators_gif_enjoyer/interface/shortcuts.dart';
import 'package:animators_gif_enjoyer/main.dart';
import 'package:animators_gif_enjoyer/main_screen/frame_base.dart';
import 'package:animators_gif_enjoyer/main_screen/menu_items.dart'
    as menu_items;
import 'package:animators_gif_enjoyer/phlutter/app_theme_cycler.dart';
import 'package:animators_gif_enjoyer/main_screen/main_screen_widgets.dart';
import 'package:animators_gif_enjoyer/main_screen/theme.dart' as app_theme;
import 'package:animators_gif_enjoyer/phlutter/remember_window_size.dart';
import 'package:animators_gif_enjoyer/phlutter/windows/image_drop_target.dart';
import 'package:animators_gif_enjoyer/phlutter/material_state_property_utils.dart';
import 'package:animators_gif_enjoyer/phlutter/modal_panel.dart';
import 'package:animators_gif_enjoyer/phlutter/windows/windows_phwindow.dart';
import 'package:animators_gif_enjoyer/utils/build_info.dart';
import 'package:animators_gif_enjoyer/utils/download_file.dart';
import 'package:animators_gif_enjoyer/utils/gif_frame_advancer.dart';
import 'package:animators_gif_enjoyer/utils/open_file.dart' as open_file;
import 'package:animators_gif_enjoyer/utils/path_extensions.dart'
    as path_extensions;
import 'package:animators_gif_enjoyer/utils/phclipboard.dart' as phclipboard;
import 'package:animators_gif_enjoyer/phlutter/value_notifier_extensions.dart';
import 'package:animators_gif_enjoyer/utils/plural.dart';
import 'package:animators_gif_enjoyer/utils/reveal_file_source.dart';
import 'package:animators_gif_enjoyer/utils/save_image_as_png.dart';
import 'package:contextual_menu/contextual_menu.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.initialTheme,
  });

  final String? initialTheme;

  @override
  Widget build(BuildContext context) {
    return FrameBaseContext(
      child: ThemeContext(
        initialThemeData: app_theme
            .getThemeFromString(initialTheme ?? app_theme.defaultThemeString),
        child: Builder(
          builder: (context) {
            Widget app(ThemeData themeData) {
              return MaterialApp(
                title: appName,
                debugShowCheckedModeBanner: false,
                theme: themeData,
                home: MyHomePage(initialThemeString: initialTheme),
              );
            }

            ThemeContext? themeContext = ThemeContext.of(context);

            if (themeContext == null) {
              return app(
                  app_theme.getThemeFromString(app_theme.defaultThemeString));
            }

            return ValueListenableBuilder(
              valueListenable: themeContext.themeData,
              builder: (_, themeDataValue, ___) => app(themeDataValue),
            );
          },
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    this.initialThemeString,
  });

  final String? initialThemeString;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

const bool isPlayOnLoad = true;

class _MyHomePageState extends State<MyHomePage>
    with
        SingleTickerProviderStateMixin,
        WindowListener,
        SnackbarShower,
        FrameBaseStorer,
        GifPlayer,
        ThemeCycler,
        WindowSizeRememberer,
        Exporter {
  final FocusNode mainWindowFocus = FocusNode(canRequestFocus: true);

  final Map<Type, Action<Intent>> shortcutActions = {};
  late List<(Type, Object? Function(Intent))> shortcutIntentActions = [
    (PreviousIntent, (_) => incrementFrame(-1)),
    (NextIntent, (_) => incrementFrame(1)),
    (CopyIntent, (_) => tryCopyFrameToClipboard()),
    (OpenTextMenu, (_) => bottomTextPanel.open()),
    (PasteAndGoIntent, (_) => openTextPanelAndPaste()),
    (PlayPauseIntent, (_) => togglePlayPause()),
    (EscapeIntent, (_) => handleEscapeIntent()),
    (FirstFrameIntent, (_) => setCurrentFrameToFirst()),
    (LastFrameIntent, (_) => setCurrentFrameToLast()),
  ];

  late final ModalTextPanel bottomTextPanel = ModalTextPanel(
    onClosed: () {
      mainWindowFocus.requestFocus();
    },
    onTextSubmitted: (value) {
      tryLoadGifFromUrl(value);
    },
    transitionBuilder: (child, animation) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      );
    },
    textPanelBuilder: (
      context,
      textController,
      onTextFieldSubmitted,
      onSubmitButtonPressed,
    ) {
      return EnjoyerBottomTextPanel(
        textController: textController,
        onTextFieldSubmitted: onTextFieldSubmitted,
        onSubmitButtonPressed: onSubmitButtonPressed,
      );
    },
  );

  final zoomLevelNotifier = ValueNotifier<double>(
    ScrollZoomContainer.defaultZoom,
  );

  //
  //  Lifecycle
  //

  @override
  void initState() {
    super.initState();

    void tryLoadFromWindowsOpenWith() {
      if (appFileToLoadFromMainArgs.isNotEmpty) {
        try {
          tryLoadGifFromFilePath(appFileToLoadFromMainArgs);
        } finally {
          appFileToLoadFromMainArgs = '';
        }
      }
    }

    tryLoadFromWindowsOpenWith();
    onSecondWindow = () => tryLoadFromWindowsOpenWith();

    initializePackageInfo();
  }

  @override
  void onGifLoadSuccess() {
    super.onGifLoadSuccess();
    zoomLevelNotifier.value = ScrollZoomContainer.defaultZoom;
  }

  @override
  void onGifDownloadSuccess() {
    showSnackbar(label: 'Download complete');
  }

  @override
  void onGifLoadError(String errorMessage) {
    showGifLoadFailedAlert(errorMessage);
  }

  void handleEscapeIntent() {
    if (bottomTextPanel.isOpen) return;
    if (inProgressExport != null) {
      return;
    }
    _exitApplication();
  }

  void _exitApplication() {
    //SystemChannels.platform.invokeMethod<void>('SystemNavigator.pop');

    // This is the dirty workaround for a nonfunctional application exit method on Flutter Windows.
    // For more info: https://github.com/flutter/flutter/issues/66631
    // debugger();
    // exit(0);

    //Separate workaround that uses window_manager since already it's a dependency.
    windowManager.close();
  }

  //
  // Build methods
  //

  @override
  Widget build(BuildContext context) {
    final windowContents = <Widget>[
      shortcutsWrapper(child: mainLayer(context)),
      topLeftControls(context),
      bottomTextPanel.widget(),
      fileDropTarget(context),
    ];

    return WindowsPhwindow(
      title: appName,
      titleColor: Theme.of(context).colorScheme.mutedSurfaceColor,
      iconWidget: Image.memory(app_theme.appIconDataBytes),
      addExtraResizingFrame: true,
      child: Stack(
        children: windowContents,
      ),
    );
  }

  Widget topLeftControls(BuildContext context) {
    const double iconSize = 16;
    const double buttonSize = 34;
    const Size size = Size(buttonSize, buttonSize);
    const buttonSizeProperty = MaterialStatePropertyAll(size);

    final buttonContentColor = Theme.of(context).colorScheme.faintGrayColor;
    final contentColorProperty = hoverColors(
      idle: buttonContentColor,
      hover: buttonContentColor.withAlpha(0xFF),
    );
    final buttonStyle = ButtonStyle(
      minimumSize: buttonSizeProperty,
      maximumSize: buttonSizeProperty,
      fixedSize: buttonSizeProperty,
      shape: const MaterialStatePropertyAll(app_theme.appButtonShape),
      iconSize: const MaterialStatePropertyAll(iconSize),
      iconColor: contentColorProperty,
      foregroundColor: contentColorProperty,
      textStyle: MaterialStatePropertyAll(
        Theme.of(context).textTheme.labelSmall!.copyWith(
              overflow: TextOverflow.visible,
            ),
      ),
      padding: const MaterialStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 0),
      ),
    );
    final activeColor = Theme.of(context).colorScheme.tertiary;
    final activeButtonStyle = ButtonStyle(
      foregroundColor: hoverColors(
        idle: activeColor.withOpacity(0.75),
        hover: activeColor,
      ),
    );
    final iconButtonTheme = IconButtonThemeData(style: buttonStyle);
    final textButtonTheme = TextButtonThemeData(style: buttonStyle);

    final cycleThemeButton = IconButton(
      icon: const Icon(Icons.lightbulb_outline),
      tooltip: 'Cycle interface brightness',
      onPressed: cycleTheme,
    );

    final cyclePlaybackSpeedButton = ValueListenableBuilder(
      valueListenable: playSpeedController.valueListenable,
      builder: (_, __, ___) {
        if (!isPlayModeAvailable) {
          return const SizedBox.shrink();
        }

        return Tooltip(
          message: 'Change playback speed',
          child: GestureDetector(
            onTertiaryTapDown: (_) => playSpeedController.resetSpeed(),
            child: TextButton(
              style:
                  playSpeedController.isDefaultSpeed ? null : activeButtonStyle,
              child: Text('${playSpeedController.currentSpeedString}x'),
              onPressed: () => playSpeedController.cycleNextSpeed(),
            ),
          ),
        );
      },
    );

    final zoomButton = ValueListenableBuilder(
      valueListenable: zoomLevelNotifier,
      builder: (_, __, ___) {
        if (zoomLevelNotifier.value != 1) {
          return IconButton(
            icon: const Icon(Icons.youtube_searched_for),
            tooltip: 'Reset zoom',
            onPressed: () => zoomLevelNotifier.value = 1.0,
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );

    final List<Widget> buttons = isGifLoaded
        ? [
            cycleThemeButton,
            cyclePlaybackSpeedButton,
            zoomButton,
          ]
        : [
            cycleThemeButton,
          ];

    return Positioned(
      left: 0,
      top: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 2,
          horizontal: 2,
        ),
        child: TooltipTheme(
          data: Theme.of(context).tooltipTheme.copyWith(
                verticalOffset: 35,
                waitDuration: delayedTooltipDelay,
              ),
          child: TextButtonTheme(
            data: textButtonTheme,
            child: IconButtonTheme(
              data: iconButtonTheme,
              child: Column(
                children: buttons,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget mainLayer(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: isGifDownloading,
            builder: (_, isCurrentlyDownloading, __) {
              if (isCurrentlyDownloading) {
                return gifDownloadingIndicator(context);
              }

              return isGifLoaded
                  ? loadedInterface(context)
                  : unloadedInterface(context);
            },
          ),
        ),
        bottomBarWidget()
      ],
    );
  }

  Widget gifDownloadingIndicator(BuildContext context) {
    return Center(
      child: SizedBox.square(
        dimension: 150,
        child: ValueListenableBuilder(
          valueListenable: gifDownloadPercent,
          builder: (_, percentDownloaded, __) {
            return CircularProgressIndicator(
              value: percentDownloaded < 0.1 ? null : percentDownloaded,
              strokeWidth: 8,
              strokeCap: StrokeCap.round,
            );
          },
        ),
      ),
    );
  }

  Widget unloadedInterface(BuildContext context) {
    Menu unloadedMenu() {
      return Menu(
        items: [
          MenuItem(
            label: 'Open GIF...',
            onClick: (_) => openNewFile(),
          ),
          MenuItem(
            label: 'Paste to address bar...',
            onClick: (_) => openTextPanelAndPaste(),
          ),
          MenuItem.separator(),
          MenuItem.submenu(
            label: 'Advanced',
            submenu: Menu(
              items: [
                menu_items.allowMultipleWindowsMenuItem(),
                menu_items.rememberWindowSizeMenuItem(),
              ],
            ),
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

    return GestureDetector(
      onSecondaryTap: () => popUpContextualMenu(unloadedMenu()),
      onDoubleTap: () => openNewFile(),
      child: Container(
        decoration:
            BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
        child: Align(
          alignment: Alignment.center,
          child: Material(
            type: MaterialType.transparency,
            child: SizedBox(
              height: 200,
              width: 300,
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Load a GIF!',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Use the button on the lower right.\n'
                      'Or drag and drop a GIF into the window.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget loadedInterface(BuildContext context) {
    final displayedFrameBaseOffset =
        FrameBaseContext.of(context)?.frameBase.value ?? 0;

    return ValueListenableBuilder(
      valueListenable: isScrubMode,
      builder: (_, __, ___) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: ZoomConstraintsContainerBuilder(
                minPixelDimension: 22, // Size of a Discord inline emote
                contentWidth: loadedGifInfo.width.toDouble(),
                contentHeight: loadedGifInfo.height.toDouble(),
                builder: (_, getFitZoom, getMinZoom, getMaxZoom) {
                  return GestureDetector(
                    onTap: () => togglePlayPause(),
                    child: GifViewContainer(
                      gifImageProvider: gifImageProvider,
                      gifController: gifController,
                      copyImageHandler: () => tryCopyFrameToClipboard(),
                      openImageHandler: () => openNewFile(),
                      pasteHandler: () => openTextPanelAndPaste(),
                      exportPngSequenceHandler: () => tryExportPngSequence(),
                      zoomLevelNotifier: zoomLevelNotifier,
                      isAppBusy: inProgressExport != null,
                      fitZoomGetter: getFitZoom,
                      hardMaxZoomGetter: getMaxZoom,
                      hardMinZoomGetter: getMinZoom,
                    ),
                  );
                },
              ),
            ),
            Column(
              children: [
                ValueListenableBuilder(
                  valueListenable: currentFrame,
                  builder: (_, __, ___) {
                    final bigStyle = Theme.of(context).textTheme.headlineMedium;
                    final bigStyleGray = bigStyle?.copyWith(
                            color: Theme.of(context).colorScheme.grayColor) ??
                        Theme.of(context).grayStyle;

                    final separator = Text(' - ', style: bigStyleGray);

                    return GestureDetector(
                      onSecondaryTap: () {
                        final frameBaseContext = FrameBaseContext.of(context);
                        final currentFrameBase = displayFrameBaseOffset;
                        if (frameBaseContext == null) return;

                        Menu menu(BuildContext context) {
                          return Menu(
                            items: currentFrameBase != 0
                                ? [
                                    MenuItem(
                                      label: 'Switch to zero-based frames',
                                      onClick: (_) => setDisplayFrameBase(0),
                                      checked: currentFrameBase == 0,
                                    )
                                  ]
                                : [
                                    MenuItem(
                                      label: 'Switch to one-based frames',
                                      onClick: (_) => setDisplayFrameBase(1),
                                      checked: currentFrameBase == 1,
                                    ),
                                  ],
                          );
                        }

                        popUpContextualMenu(menu(context));
                      },
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          separator,
                          Text(
                            displayedCurrentFrameString,
                            style: isScrubMode.value ? bigStyle : bigStyleGray,
                          ),
                          separator,
                        ],
                      ),
                    );
                  },
                ),
                Text('frame', style: Theme.of(context).smallGrayStyle)
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: isScrubMode.value ? null : () => setPlayMode(false),
                  child: MainSlider(
                    toggleUseFocus: toggleUseFocus,
                    primarySliderRange: primarySliderRange,
                    isUsingFocusRange: isUsingFocusRange,
                    currentFrame: currentFrame,
                    gifController: gifController,
                    enabled: isPlayModeAvailable && isScrubMode.value,
                    onChange: clampCurrentFrameAndShow,
                    displayedFrameOffset: displayedFrameBaseOffset,
                  ),
                ),
              ),
            ),
            ValueListenableBuilder(
              valueListenable: isUsingFocusRange,
              builder: (_, isUseCustomRange, __) {
                final double frameCount = focusFrameRange.value.rangeSize + 1;
                final rangeSeconds = loadedGifInfo.frameDuration != null
                    ? (frameCount *
                        loadedGifInfo.frameDuration!.inMilliseconds.toDouble() *
                        0.001)
                    : -1;

                final String rangeSecondsString = rangeSeconds >= 0
                    ? '${rangeSeconds.toStringAsFixed(2)} seconds'
                    : '';

                const double buttonSize = 25;
                const double buttonSpace = 4;

                return Visibility(
                  maintainInteractivity: false,
                  maintainSemantics: false,
                  visible: isUseCustomRange,
                  child: Column(
                    children: [
                      FrameRangeSlider(
                        displayedFrameOffset: displayedFrameBaseOffset,
                        startEnd: focusFrameRange,
                        maxFrameIndex: maxFrameIndex,
                        enabled: isGifLoaded && isScrubMode.value,
                        onChange: () => clampCurrentFrame(),
                        onChangeRangeStart: () =>
                            setDisplayedFrame(focusFrameRange.value.startInt),
                        onChangeRangeEnd: () =>
                            setDisplayedFrame(focusFrameRange.value.endInt),
                        onChangeTapUp: () =>
                            setDisplayedFrame(currentFrame.value),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (isScrubMode.value)
                            const SizedBox(width: buttonSize + buttonSpace + 3),
                          Text(
                            'Custom range: ${frameCount.toInt()} frames. ~$rangeSecondsString',
                            style: const TextStyle(
                                color: app_theme.focusRangeColor),
                          ),
                          isScrubMode.value
                              ? Padding(
                                  padding:
                                      const EdgeInsets.only(left: buttonSpace),
                                  child: IconButton(
                                    style: const ButtonStyle(
                                      minimumSize: MaterialStatePropertyAll(
                                        Size(buttonSize, buttonSize),
                                      ),
                                    ),
                                    tooltip: 'Disable frame range',
                                    iconSize: 12,
                                    onPressed: () => toggleUseFocus(),
                                    icon: const Icon(Icons.close),
                                  ),
                                )
                              : const SizedBox(height: buttonSize + 3),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget bottomBarWidget() {
    return SizedBox(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                getFramerateTooltip(),
                bottomBarGifInfo(context),
              ],
            ),
            const Spacer(),
            Wrap(
              direction: Axis.horizontal,
              spacing: 8,
              children: [
                if (isGifLoaded)
                  BottomPlayPauseButton(
                    isScrubMode: isScrubMode,
                    onPressed: () => togglePlayPause(),
                  ),
                Tooltip(
                  message: 'Open GIF file...\n'
                      'Or use ${Phshortcuts.shortcutString(Phshortcuts.pasteAndGo)} to paste a link to a GIF.',
                  child: IconButton(
                    onPressed: () => openNewFile(),
                    color: Theme.of(context).colorScheme.mutedSurfaceColor,
                    icon: const Icon(FluentIcons.folder_open_24_regular),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget bottomBarGifInfo(BuildContext context) {
    if (!isGifLoaded) return const SizedBox.shrink();
    final smallGrayStyle = Theme.of(context).smallGrayStyle;

    final isAnimatedWithVariableFps = //
        !loadedGifInfo.isNonAnimated && //
            loadedGifInfo.frameDuration == null;

    String getImageDimensionsLabel() {
      return '${loadedGifInfo.width}x${loadedGifInfo.height}px';
    }

    if (isAnimatedWithVariableFps) {
      return DefaultTextStyle(
        style: smallGrayStyle,
        child: Row(
          children: [
            const Text('Variable frame times. '),
            ValueListenableBuilder(
              valueListenable: currentFrame,
              builder: (_, __, ___) {
                return Text(
                  '(current: ${gifController.currentFrameData.duration.inMilliseconds} ms)',
                );
              },
            ),
            Text('- ${getImageDimensionsLabel()}'),
          ],
        ),
      );
    }

    String getFramerateLabel() {
      if (loadedGifInfo.isNonAnimated) {
        return 'Not animated ';
      }

      const millisecondsUnit = 'ms';
      const msPerFrameUnit = '$millisecondsUnit/frame';

      final frameDuration = loadedGifInfo.frameDuration;
      switch (frameDuration) {
        case null:
          return 'Variable frame durations';
        case <= const Duration(milliseconds: 10):
          return '${frameDuration.inMilliseconds} $msPerFrameUnit';
        default:
          final frameInterval = frameDuration.inMilliseconds;
          final fps = 1000.0 / frameInterval;
          return '~${fps.toStringAsFixed(2)} fps '
              '($frameInterval $msPerFrameUnit) ';
      }
    }

    return Text(
      '${getFramerateLabel()}- ${getImageDimensionsLabel()}',
      style: smallGrayStyle,
    );
  }

  Widget fileDropTarget(BuildContext context) {
    return ImageDropTarget(
      dragImagesHandler: (details) {
        if (details.files.isEmpty) return;
        final file = details.files[0];

        if (!open_file.isAcceptedFile(filename: file.name)) {
          showSnackbar(label: 'Not a GIF');

          if (!open_file.isInformallyAcceptedFile(filename: file.name)) {
            return;
          }
        }

        tryLoadGifFromFilePath(file.path);
      },
    );
  }

  Widget shortcutsWrapper({required Widget child}) {
    if (shortcutActions.isEmpty) {
      for (var (intentType, callback) in shortcutIntentActions) {
        shortcutActions[intentType] = CallbackAction(onInvoke: callback);
      }
    }

    return Shortcuts(
      shortcuts: Phshortcuts.intentMap,
      child: Actions(
        actions: shortcutActions,
        child: Focus(
          focusNode: mainWindowFocus,
          autofocus: true,
          child: child,
        ),
      ),
    );
  }

  //
  // UI Controls
  //

  void closeAllPanels() {
    bottomTextPanel.close();
  }

  void openTextPanelAndPaste() async {
    if (inProgressExport != null) return;

    final pastedText = await phclipboard.getStringFromClipboard();
    if (pastedText != null) {
      bottomTextPanel.openWithText(pastedText);
    }
  }

  void tryCopyFrameToClipboard() {
    if (!isGifLoaded) return;
    final image = gifController.currentFrameData.imageInfo.image;
    final suggestedName = "gifFrameg${gifController.currentFrame}.png";
    phclipboard.copyImageToClipboardAsPng(image, suggestedName);
  }

  //
  // UI info methods
  //

  Widget getFramerateTooltip() {
    if (!isGifLoaded || loadedGifInfo.isNonAnimated) {
      return const SizedBox.shrink();
    }

    if (loadedGifInfo.frameDuration == null) {
      return const SizedBox.shrink();
    }

    final frameMilliseconds = loadedGifInfo.frameDuration!.inMilliseconds;
    final fpsDouble = 1000.0 / frameMilliseconds;
    if (frameMilliseconds > 0 && GifPlayer.isFpsWhole(fpsDouble)) {
      return const SizedBox.shrink();
    }

    String message =
        'GIF frames are each encoded with intervals in 10 millisecond increments.\n'
        'This makes their actual framerate potentially variable,\n'
        'and often not precisely fitting common video framerates.';
    if (frameMilliseconds <= 10) {
      message = 'Browsers usually reinterpret delays\n'
          'below 20 milliseconds as 100 milliseconds.';
    }

    return Tooltip(
      message: message,
      child: Icon(
        Icons.info_outline,
        size: 13,
        color: Theme.of(context).colorScheme.grayColor,
      ),
    );
  }

  //
  // Load Operations
  //

  void openNewFile() async {
    if (inProgressExport != null) return;

    var (gifImage, name) = await open_file.openGifImageFile();
    if (gifImage == null || name == null) return;

    loadGifFromProvider(gifImage, name);
  }

  void tryLoadClipboardPath() async {
    final clipboardString = await phclipboard.getStringFromClipboard();
    if (clipboardString == null) return;

    tryLoadGifFromUrl(
      clipboardString,
      errorMessage: 'Pasted text was not a proper URL:\n "$clipboardString"',
    );
  }

  void tryExportPngSequence() async {
    if (!isGifLoaded) return;
    if (inProgressExport != null) return;

    final imageList = gifController.frames
        .map<ui.Image>((frame) => frame.imageInfo.image)
        .toList(growable: false);

    final gifPrefix =
        tryGetNameFromGifImageProvider(defaultName: 'gif_enjoyer');

    final totalFramesDouble = imageList.length.toDouble();
    inProgressExport = savePngSequenceFromImageList(
      imageList,
      prefix: gifPrefix,
      useSubfolder: true,
      useBaseZero: displayFrameBaseOffset == 0,
      exportCancel: isExportCancelled,
      onExportStart: () {
        exportPercentProgress.value = 0;
        showProgressSnackbar(
          icon: const Icon(Icons.save_alt),
          label: 'Exporting PNGs...',
          progressListenable: exportPercentProgress,
          action: SnackBarAction(
            label: 'Cancel',
            onPressed: () => cancelExport(),
          ),
        );
      },
      onFileSaveProgress: (totalFilesSaved) {
        updateExportPercentProgress(
          totalFilesSaved.toDouble() / totalFramesDouble,
        );
      },
      onExportCanceled: (totalFiles, directory) {
        showSnackbar(
          icon: const Icon(SnackbarShower.canceledIcon),
          label: 'Export canceled.',
          action: (directory == null)
              ? null
              : SnackBarAction(
                  label: 'Open folder',
                  onPressed: () => revealDirectoryInExplorer(directory),
                ),
        );
      },
      onExportSuccess: (totalFiles, directory) {
        showSnackbar(
          label:
              'PNG Sequence exported: $totalFiles image${pluralS(totalFiles)}',
          icon: const Icon(SnackbarShower.okIcon),
          action: (directory == null)
              ? null
              : SnackBarAction(
                  label: 'Open folder',
                  onPressed: () => revealDirectoryInExplorer(directory),
                ),
        );
      },
    )
      ..onError(
        (error, stackTrace) {
          setState(() {
            clearExportStatus();
          });
          showSnackbar(
            icon: const Icon(SnackbarShower.errorIcon),
            label: 'Error exporting PNG sequence.',
          );
        },
      )
      ..whenComplete(
        () => setState(() {
          clearExportStatus();
        }),
      );
    setState(() {});
  }

  void tryLoadGifFromFilePath(String path) {
    if (inProgressExport != null) return;

    if (path.trim().isEmpty) return;
    loadGifFromProvider(open_file.getFileImageFromPath(path), path);
  }

  void tryLoadGifFromUrl(String url, {String? errorMessage}) {
    if (inProgressExport != null) return;

    if (url.trim().isEmpty) {
      return;
    }

    if (isUrlString(url)) {
      var provider = NetworkImage(url);
      loadGifFromProvider(provider, url);
    } else {
      showSnackbar(label: errorMessage ?? "Can't load url:\n$url");
    }
  }

  //
  // Screen messages
  //

  void showGifLoadFailedAlert(String errorText) {
    showSnackbar(
      label: 'GIF loading failed\n'
          '$errorText',
    );
  }

  @override
  String get defaultThemeString => app_theme.defaultThemeString;
  @override
  String? get initialThemeString => widget.initialThemeString;
  @override
  ThemeData getThemeFromString(String themeName) =>
      app_theme.getThemeFromString(themeName);
  @override
  String getNextCycleTheme(String currentValue) =>
      app_theme.getNextCycleTheme(currentValue);
}

class GifInfo {
  const GifInfo({
    required this.fileSource,
    required this.width,
    required this.height,
    required this.frameDuration,
    this.isNonAnimated = false,
  });

  GifInfo._fromFramesAndImageInfo({
    required this.fileSource,
    required List<GifFrame> frames,
    required ImageInfo imageInfo,
  })  : frameDuration = readFrameDuration(frames),
        width = imageInfo.image.width,
        height = imageInfo.image.height,
        isNonAnimated = isNonMoving(frames);

  GifInfo.fromFrames({
    required fileSource,
    required List<GifFrame> frames,
  }) : this._fromFramesAndImageInfo(
          fileSource: fileSource,
          frames: frames,
          imageInfo: frames[0].imageInfo,
        );

  final String fileSource;
  final int width;
  final int height;
  final Duration? frameDuration;
  final bool isNonAnimated;

  Size get imageSize => Size(width.toDouble(), height.toDouble());

  static bool isNonMoving(List<GifFrame> frames) {
    return frames.length <= 1;
  }

  static Duration? readFrameDuration(List<GifFrame> frames) {
    final duration = frames[0].duration;
    for (final frame in frames) {
      if (duration != frame.duration) return null;
    }
    return duration;
  }
}

mixin GifPlayer<T extends StatefulWidget>
    on State<T>, TickerProvider, FrameBaseStorer<T> {
  final gifController = GifController();
  ImageProvider? gifImageProvider;
  late GifFrameAdvancer gifAdvancer;
  late PlaybackSpeedController playSpeedController = PlaybackSpeedController(
    setter: (timeScale) => gifAdvancer.timeScale = timeScale,
  );

  final ValueNotifier<int> displayedFrame = ValueNotifier(0);
  final ValueNotifier<int> currentFrame = ValueNotifier(0);

  String get displayedCurrentFrameString {
    return (currentFrame.value + displayFrameBaseOffset).toString();
  }

  final ValueNotifier<RangeValues> focusFrameRange =
      ValueNotifier(const RangeValues(0, 100));

  final ValueNotifier<bool> isScrubMode = ValueNotifier(!isPlayOnLoad);
  final ValueNotifier<int> maxFrameIndex = ValueNotifier(100);
  final ValueNotifier<bool> isUsingFocusRange = ValueNotifier(false);

  RangeValues get fullFrameRange =>
      RangeValues(0, maxFrameIndex.value.toDouble());
  RangeValues get primarySliderRange =>
      isUsingFocusRange.value ? focusFrameRange.value : fullFrameRange;

  final ValueNotifier<bool> isGifDownloading = ValueNotifier(false);
  final ValueNotifier<double> gifDownloadPercent = ValueNotifier(0.0);

  GifInfo loadedGifInfo = const GifInfo(
    fileSource: '',
    width: 0,
    height: 0,
    frameDuration: Duration.zero,
  );
  int get lastGifFrame => gifController.frameCount - 1;

  bool get isGifLoaded => gifImageProvider != null;
  bool get isPlayModeAvailable => isGifLoaded && !loadedGifInfo.isNonAnimated;

  /// Tries to get the filename of the loaded GIF.
  String tryGetNameFromGifImageProvider({required String defaultName}) {
    final nameWithoutExtension = switch (gifImageProvider) {
      FileImage _ => path_extensions.filenameFromFullPathWithoutExtensions(
          loadedGifInfo.fileSource,
        ),
      NetworkImage _ => path_extensions.filenameFromUrlWithoutExtension(
          loadedGifInfo.fileSource,
        ),
      _ => defaultName
    };

    if (nameWithoutExtension == null || nameWithoutExtension.trim().isEmpty) {
      return defaultName;
    }

    return nameWithoutExtension;
  }

  @override
  void initState() {
    gifAdvancer = GifFrameAdvancer(
      tickerProvider: this,
      onFrame: (frameIndex) => onGifFrameAdvance(frameIndex),
    );
    super.initState();
  }

  void onGifFrameAdvance(int frameIndex) {
    setCurrentFrameClamped(frameIndex);
  }

  @override
  void dispose() {
    gifController.dispose();
    gifAdvancer.dispose();
    super.dispose();
  }

  //
  // Playback controls
  //

  void togglePlayPause() {
    setPlayMode(isScrubMode.value);
  }

  void toggleUseFocus() {
    setState(() {
      clampFocusRange();

      bool willSwitchToFocused = !isUsingFocusRange.value;
      final nextRange =
          willSwitchToFocused ? focusFrameRange.value : fullFrameRange;
      clampCurrentFrameWithRange(nextRange);

      isUsingFocusRange.toggle();
    });
  }

  void setPlayMode(bool active) {
    if (!isPlayModeAvailable) {
      isScrubMode.value = true;
      return;
    }

    isScrubMode.value = !active;
    if (active) {
      final range = primarySliderRange;
      final int start = range.start.toInt();
      final int last = range.end.toInt();
      clampCurrentFrame();

      gifAdvancer.pause();
      gifAdvancer.play(
        start: start,
        last: last,
        current: currentFrame.value,
      );
    } else {
      gifAdvancer.pause();
    }
  }

  void onStartLoadNewGif() {
    setPlayMode(false);
  }

  void onGifLoadSuccess() {
    if (isPlayOnLoad) {
      setPlayMode(true);
    }
  }

  void onGifDownloadSuccess();
  void onGifLoadError(String errorMessage);

  void loadGifFromProvider(
    ImageProvider provider,
    String source,
  ) async {
    onStartLoadNewGif();

    try {
      final isDownload = provider is NetworkImage;
      isGifDownloading.value = isDownload;
      final frames = await loadGifFrames(
        provider: provider,
        onProgressPercent: isDownload
            ? (downloadPercent) {
                gifDownloadPercent.value = downloadPercent;
              }
            : null,
      );
      gifImageProvider = provider;
      loadedGifInfo = GifInfo.fromFrames(fileSource: source, frames: frames);
      gifController.load(frames);
      gifAdvancer.setFrames(frames);

      setState(() {
        // Reset sensible values for new file.
        int lastFrame = lastGifFrame;
        focusFrameRange.value = RangeValues(0, lastFrame.toDouble());
        maxFrameIndex.value = lastFrame;
        currentFrame.value = 0;
        playSpeedController.resetSpeed();
        isGifDownloading.value = false;
        onGifLoadSuccess();

        if (gifImageProvider is NetworkImage) {
          onGifDownloadSuccess();
        }
      });
    } catch (e) {
      if (gifImageProvider is NetworkImage) {
        try {
          var uri = Uri.parse(source);
          if (uri.host.contains('tenor') && !uri.path.endsWith('gif')) {
            final gifLinkError = 'Cannot access : $source \n'
                '(Tenor embed links currently do not work.)';
            onGifLoadError(gifLinkError);
          }
        } catch (m) {
          onGifLoadError(e.toString());
        }
      } else {
        onGifLoadError(e.toString());
      }

      isGifDownloading.value = false;
    }
  }

  void setDisplayedFrame(int frame) {
    gifController.seek(frame);
    gifAdvancer.setCurrent(frame);
    displayedFrame.value = gifController.currentFrame;
  }

  //
  // Frame controls
  //

  void incrementFrame(int incrementSign) {
    if (incrementSign == 0) return;
    setCurrentFrameClamped(currentFrame.value + incrementSign.sign);
  }

  void setCurrentFrameToFirst() {
    setCurrentFrameClamped(primarySliderRange.startInt);
  }

  void setCurrentFrameToLast() {
    setCurrentFrameClamped(primarySliderRange.endInt);
  }

  void setCurrentFrameClamped(int newFrame) {
    currentFrame.value = newFrame;
    clampCurrentFrameAndShow();
  }

  void clampCurrentFrameAndShow() {
    clampCurrentFrame();
    setDisplayedFrame(currentFrame.value);
  }

  void clampFocusRange() {
    final oldValue = focusFrameRange.value;
    final lastFrameIndex = maxFrameIndex.value.toDouble();

    double minValue = oldValue.start;
    if (minValue < 0) minValue = 0;
    if (minValue > lastFrameIndex) minValue = lastFrameIndex;

    double maxValue = oldValue.end;
    if (maxValue < minValue) maxValue = minValue;
    if (maxValue > lastFrameIndex) maxValue = lastFrameIndex;

    focusFrameRange.value = RangeValues(minValue, maxValue);
  }

  void clampCurrentFrameWithRange(RangeValues range) {
    currentFrame.value =
        clampDouble(currentFrame.value.toDouble(), range.start, range.end)
            .toInt();
  }

  void clampCurrentFrame() {
    setState(() {
      final currentRange = primarySliderRange;
      currentFrame.value = clampDouble(currentFrame.value.toDouble(),
              currentRange.start, currentRange.end)
          .toInt();
    });
  }

  static bool isFpsWhole(double fps) {
    return fps.floorToDouble() == fps;
  }
}

class PlaybackSpeedController {
  PlaybackSpeedController({
    required this.setter,
  });

  final void Function(double timeScale) setter;

  static const defaultSpeed = 1.0;
  static const _speeds = <double>[0.25, 0.5, defaultSpeed, 2, 4];

  final _currentSpeed = ValueNotifier<double>(defaultSpeed);

  String get currentSpeedString {
    return switch (_currentSpeed.value) {
      0.5 => '.5',
      < 1 => _currentSpeed.value.toStringAsPrecision(2).substring(1),
      _ => _currentSpeed.value.toInt().toString(),
    };
  }

  ValueListenable<double> get valueListenable => _currentSpeed;

  bool get isDefaultSpeed => _currentSpeed.value == defaultSpeed;

  void cycleNextSpeed() {
    final currentIndex = _speeds.indexOf(_currentSpeed.value);
    if (currentIndex < 0) {
      _setSpeed(defaultSpeed);
      return;
    }

    final nextIndex =
        (currentIndex == _speeds.length - 1) ? 0 : currentIndex + 1;

    _setSpeed(_speeds[nextIndex]);
  }

  void resetSpeed() {
    _setSpeed(defaultSpeed);
  }

  void _setSpeed(double speed) {
    _currentSpeed.value = speed;
    setter(_currentSpeed.value);
  }
}

mixin Exporter {
  Future? inProgressExport;
  ValueNotifier<double> exportPercentProgress = ValueNotifier(0);
  ValueNotifier<bool> isExportCancelled = ValueNotifier(false);

  void updateExportPercentProgress(double percent) {
    exportPercentProgress.value = percent;
  }

  void cancelExport() {
    isExportCancelled.value = true;
  }

  void clearExportStatus() {
    inProgressExport = null;
    exportPercentProgress.value = 0;
    isExportCancelled.value = false;
  }
}

mixin SnackbarShower<T extends StatefulWidget> on State<T> {
  static const IconData emptyIcon = Icons.check_box_outline_blank;
  static const IconData errorIcon = Icons.error_outline;
  static const IconData okIcon = Icons.check;
  static const IconData deleteIcon = Icons.delete;
  static const IconData undoIcon = Icons.undo;
  static const IconData saveIcon = Icons.save_alt;
  static const IconData copyIcon = Icons.copy;
  static const IconData canceledIcon = Icons.cancel;

  void showSnackbar({
    required String label,
    Icon? icon,
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        content: IconTheme(
          data: IconThemeData(
            color: Theme.of(context).colorScheme.onInverseSurface,
          ),
          child: Row(
            children: [
              if (icon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: icon,
                ),
              Flexible(child: Text(label)),
            ],
          ),
        ),
        action: action,
      ),
    );
  }

  void showProgressSnackbar({
    Icon? icon,
    required String label,
    required ValueListenable<double> progressListenable,
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(days: 1),
        action: action,
        content: IconTheme(
          data: IconThemeData(
            color: Theme.of(context).colorScheme.onInverseSurface,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  if (icon != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: icon,
                    ),
                  Flexible(child: Text(label)),
                ],
              ),
              ValueListenableBuilder(
                valueListenable: progressListenable,
                builder: (context, value, child) {
                  return LinearProgressIndicator(
                    borderRadius: const BorderRadius.all(Radius.circular(2)),
                    value: value,
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
