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

      final fontSize = controller.treeFontSize.value;
      final iconSize = fontSize * 0.75; // Middle ground between 0.7 and 0.8
      final rowHeight = fontSize * 1.7;

      return InkWell(
        onTap: node.isExpandable ? () => controller.toggleNode(node) : null,
        child: Container(
          decoration: BoxDecoration(
            color: isCurrentMatch ? Colors.blue.withOpacity(0.1) : null,
          ),
          padding: EdgeInsets.only(left: (node.depth * (fontSize * 1.4)) + 8.0),
          height: rowHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Vertical lines for depth
              for (int i = 1; i <= node.depth; i++)
                Positioned(
                  left: (i * (fontSize * 1.4)) - (node.depth * (fontSize * 1.4)) - (fontSize * 1.2),
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
                  _buildExpandIcon(iconSize),
                  SizedBox(width: fontSize * 0.6),
                  _buildTypeIcon(fontSize, iconSize),
                  SizedBox(width: fontSize * 0.8),
                  _buildKey(fontSize),
                  if (node.type != JsonNodeType.object && node.type != JsonNodeType.array) ...[
                    Text(' : ', style: TextStyle(color: Colors.black, fontSize: fontSize, fontWeight: FontWeight.bold)),
                    _buildValue(fontSize),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildExpandIcon(double size) {
    if (!node.isExpandable) {
      return SizedBox(width: size + 1);
    }
    return Container(
      width: size + 1,
      height: size + 1,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1.2),
        color: Colors.white,
        borderRadius: BorderRadius.circular(1),
      ),
      child: Center(
        child: Icon(
          node.isExpanded ? Icons.remove : Icons.add,
          size: size - 2.5,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildTypeIcon(double fontSize, double iconSize) {
    if (node.type == JsonNodeType.object) {
      return Text(
        '{ }',
        style: TextStyle(
          color: AppTheme.objectColor,
          fontWeight: FontWeight.w900,
          fontSize: fontSize + 2,
          fontFamily: 'monospace',
        ),
      );
    } else if (node.type == JsonNodeType.array) {
      return Text(
        '[ ]',
        style: TextStyle(
          color: AppTheme.arrayColor,
          fontWeight: FontWeight.w900,
          fontSize: fontSize + 2,
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
        width: iconSize - 2,
        height: iconSize - 2,
        decoration: BoxDecoration(
          color: squareColor,
          borderRadius: BorderRadius.circular(1),
        ),
      );
    }
  }

  Widget _buildKey(double fontSize) {
    return Text(
      node.key.toString(),
      style: TextStyle(
        color: Colors.black,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        fontFamily: 'monospace',
      ),
    );
  }

  Widget _buildValue(double fontSize) {
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
        style: TextStyle(
          color: Colors.black,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
