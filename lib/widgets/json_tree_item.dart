import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/json_node.dart';
import '../controllers/json_controller.dart';
import '../utils/app_theme.dart';

class JsonTreeItem extends StatelessWidget {
  final JsonNode node;

  const JsonTreeItem({super.key, required this.node});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<JsonController>();
    
    return Obx(() {
      final isCurrentMatch = controller.searchResults.isNotEmpty &&
          controller.currentSearchIndex.value >= 0 &&
          controller.currentSearchIndex.value < controller.searchResults.length &&
          controller.searchResults[controller.currentSearchIndex.value] == node;

      return InkWell(
        onTap: node.isExpandable ? () => controller.toggleNode(node) : null,
        child: Container(
          decoration: BoxDecoration(
            color: isCurrentMatch ? Colors.blue.withOpacity(0.1) : null,
          ),
          padding: EdgeInsets.only(left: (node.depth * 18.0) + 8.0),
          height: 22,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Vertical lines for depth
              for (int i = 1; i <= node.depth; i++)
                Positioned(
                  left: (i * 18.0) - (node.depth * 18.0) - 15.0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 1,
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              Row(
                children: [
                  _buildExpandIcon(),
                  const SizedBox(width: 4),
                  _buildTypeIcon(),
                  const SizedBox(width: 6),
                  _buildKey(),
                  if (node.type != JsonNodeType.object && node.type != JsonNodeType.array) ...[
                    const Text(' : ', style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold)),
                    _buildValue(),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildExpandIcon() {
    if (!node.isExpandable) {
      return const SizedBox(width: 12);
    }
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black54, width: 1.0),
        color: Colors.white,
        borderRadius: BorderRadius.circular(1),
      ),
      child: Center(
        child: Icon(
          node.isExpanded ? Icons.remove : Icons.add,
          size: 9,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildTypeIcon() {
    if (node.type == JsonNodeType.object) {
      return const Text(
        '{}',
        style: TextStyle(
          color: AppTheme.objectColor,
          fontWeight: FontWeight.bold,
          fontSize: 15,
          fontFamily: 'monospace',
        ),
      );
    } else if (node.type == JsonNodeType.array) {
      return const Text(
        '[]',
        style: TextStyle(
          color: AppTheme.arrayColor,
          fontWeight: FontWeight.bold,
          fontSize: 15,
          fontFamily: 'monospace',
        ),
      );
    } else {
      Color squareColor;
      switch (node.type) {
        case JsonNodeType.number:
          squareColor = AppTheme.numberSquare;
          break;
        case JsonNodeType.nullValue:
          squareColor = AppTheme.nullSquare;
          break;
        default:
          squareColor = AppTheme.stringSquare;
      }
      return Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          color: squareColor,
          borderRadius: BorderRadius.circular(1),
        ),
      );
    }
  }

  Widget _buildKey() {
    return Text(
      node.key.toString(),
      style: const TextStyle(
        color: Colors.black,
        fontSize: 13,
        fontWeight: FontWeight.bold,
        fontFamily: 'monospace',
      ),
    );
  }

  Widget _buildValue() {
    String displayValue = node.value.toString();
    if (node.type == JsonNodeType.string) {
      displayValue = '"$displayValue"';
    } else if (node.type == JsonNodeType.nullValue) {
      displayValue = 'null';
    }

    return Flexible(
      child: Text(
        displayValue,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
