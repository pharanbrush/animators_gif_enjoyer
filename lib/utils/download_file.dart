import 'package:flutter/material.dart';

Future<String?> openGifDownloadDialog({
  required BuildContext context,
  required TextEditingController controller,
  required Function(String?) handleSubmit,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog.adaptive(
        title: const Text('Download GIF'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter the GIF link'),
          controller: controller,
        ),
        actions: [
          TextButton(
            onPressed: () => handleSubmit(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => handleSubmit(controller.text),
            child: const Text('Ok'),
          )
        ],
      );
    },
  );
}
