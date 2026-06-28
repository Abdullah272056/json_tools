import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/json_controller.dart';

class StatusBar extends StatelessWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<JsonController>();

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Obx(() => Row(
        children: [
          _StatusItem(label: 'Keys', value: '${controller.totalKeys.value}'),
          const VerticalDivider(width: 20),
          _StatusItem(label: 'Nodes', value: '${controller.totalNodes.value}'),
          const VerticalDivider(width: 20),
          _StatusItem(label: 'Size', value: controller.jsonSize.value),
          const Spacer(),
          if (controller.validationError.value != null)
            _ValidationStatus(
              isValid: false,
              message: 'Line ${controller.validationError.value!['line']}, Col ${controller.validationError.value!['column']}',
            )
          else if (controller.jsonOutput.value.trim().isNotEmpty)
            const _ValidationStatus(isValid: true, message: 'Valid JSON'),
        ],
      )),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatusItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$label: ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _ValidationStatus extends StatelessWidget {
  final bool isValid;
  final String message;

  const _ValidationStatus({required this.isValid, required this.message});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.error,
          color: isValid ? Colors.green : Colors.red,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          message,
          style: TextStyle(
            color: isValid ? Colors.green : Colors.red,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
