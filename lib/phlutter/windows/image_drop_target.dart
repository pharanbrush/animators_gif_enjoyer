import 'package:desktop_drop/desktop_drop.dart' as desktop_drop;
import 'package:flutter/material.dart';

class ImageDropTarget extends StatefulWidget {
  const ImageDropTarget({
    super.key,
    this.dragImagesHandler,
  });

  final desktop_drop.OnDragDoneCallback? dragImagesHandler;

  @override
  State<ImageDropTarget> createState() => _ImageDropTargetState();
}

class _ImageDropTargetState extends State<ImageDropTarget> {
  bool _isDragging = false;

  void _setDraggingActive(bool active) {
    setState(() {
      _isDragging = active;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final foregroundColor = colorScheme.onInverseSurface;
    final boxColor = colorScheme.inverseSurface.withAlpha(0xDD);
    final BoxDecoration visibleBoxDecoration = BoxDecoration(
      color: boxColor,
      borderRadius: const BorderRadius.all(Radius.circular(5)),
    );
    const BoxDecoration hiddenBoxDecoration = BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.all(Radius.circular(15)),
    );
    final textStyle =
        theme.textTheme.displaySmall?.copyWith(color: foregroundColor);

    final Widget hiddenDropWidget = Center(
      child: Material(
        textStyle: textStyle,
        type: MaterialType.transparency,
        child: const SizedBox.shrink(),
      ),
    );

    final icon = Icon(
      Icons.image_outlined,
      size: 80,
      color: foregroundColor,
    );

    final label = Text(
      'Drop GIF here.',
      style: textStyle,
    );

    final Widget visibleDropWidget = Center(
      child: Material(
        textStyle: textStyle,
        type: MaterialType.transparency,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(height: 15),
            label,
          ],
        ),
      ),
    );

    return desktop_drop.DropTarget(
      onDragDone: (details) {
        _setDraggingActive(false);
        widget.dragImagesHandler?.call(details);
      },
      onDragEntered: (details) => _setDraggingActive(true),
      onDragExited: (details) => _setDraggingActive(false),
      child: IgnorePointer(
        ignoring: true,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutQuart,
          key: const Key('dropContainer'),
          margin:
              _isDragging ? const EdgeInsets.all(30) : const EdgeInsets.all(50),
          decoration: _isDragging ? visibleBoxDecoration : hiddenBoxDecoration,
          child: _isDragging ? visibleDropWidget : hiddenDropWidget,
        ),
      ),
    );
  }
}
