import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/json_node.dart';
import '../controllers/json_controller.dart';
import '../utils/app_theme.dart';

class JsonTreeItem extends StatefulWidget {
  final JsonNode node;

  const JsonTreeItem({super.key, required this.node});

  @override
  State<JsonTreeItem> createState() => _JsonTreeItemState();
}

class _JsonTreeItemState extends State<JsonTreeItem> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _sizeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // Increased duration for smoothness
    );
    _sizeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic, // More elegant, fluid curve
    );

    if (widget.node.wasJustAdded) {
      _animationController.forward();
      widget.node.wasJustAdded = false;
    } else {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(JsonTreeItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.node.isCollapsing) {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<JsonController>();
    
    return SizeTransition(
      sizeFactor: _sizeAnimation,
      axisAlignment: -1.0,
      child: Obx(() {
        final node = widget.node;
        final isCurrentMatch = controller.searchQuery.isNotEmpty &&
            (node.key.toString().toLowerCase().contains(controller.searchQuery.value.toLowerCase()) ||
                (node.type != JsonNodeType.object &&
                    node.type != JsonNodeType.array &&
                    node.value.toString().toLowerCase().contains(controller.searchQuery.value.toLowerCase())));
        
        final isSelected = controller.selectedNode.value == node;

        final fontSize = controller.treeFontSize.value;
        final iconSize = fontSize * 0.75;
        final rowHeight = fontSize * 1.7;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => controller.selectNode(node),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isSelected 
                  ? Colors.blue.withOpacity(0.15) 
                  : (isCurrentMatch ? Colors.orange.withOpacity(0.2) : null),
              border: isSelected ? Border(left: BorderSide(color: Colors.blue.shade700, width: 3)) : null,
            ),
            padding: EdgeInsets.only(left: (node.depth * (fontSize * 1.4)) + (isSelected ? 5.0 : 8.0)),
            height: rowHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildExpandIcon(iconSize, controller),
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
      }),
    );
  }

  Widget _buildExpandIcon(double size, JsonController controller) {
    if (!widget.node.isExpandable || widget.node.children.isEmpty) {
      return SizedBox(width: size + 1);
    }
    return GestureDetector(
      onTap: () {
        controller.toggleNode(widget.node);
      },
      child: Container(
        width: size + 1,
        height: size + 1,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 1.2),
          color: Colors.white,
          borderRadius: BorderRadius.circular(1),
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
            child: Icon(
              widget.node.isExpanded ? Icons.remove : Icons.add,
              key: ValueKey(widget.node.isExpanded),
              size: size - 2.5,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIcon(double fontSize, double iconSize) {
    final node = widget.node;
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
      widget.node.key.toString(),
      style: TextStyle(
        color: Colors.black,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        fontFamily: 'monospace',
      ),
    );
  }

  Widget _buildValue(double fontSize) {
    String displayValue = widget.node.value.toString();
    if (widget.node.type == JsonNodeType.string) {
      displayValue = '"$displayValue"';
    } else if (widget.node.type == JsonNodeType.nullValue) {
      displayValue = 'null';
    }

    return Text(
      displayValue,
      style: TextStyle(
        color: Colors.black,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        fontFamily: 'monospace',
      ),
    );
  }
}
