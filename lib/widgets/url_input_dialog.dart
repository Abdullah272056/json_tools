import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UrlInputDialog extends StatelessWidget {
  const UrlInputDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return AlertDialog(
      title: const Text('Load JSON from URL'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          hintText: 'https://api.example.com/data.json',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Get.back(result: controller.text),
          child: const Text('Load'),
        ),
      ],
    );
  }
}
