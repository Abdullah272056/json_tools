import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_highlight/themes/github.dart';
import '../controllers/json_controller.dart';
import '../models/json_node.dart';
import '../widgets/toolbar.dart';
import '../widgets/status_bar.dart';
import '../widgets/json_tree_item.dart';
import 'json_to_dart_view.dart';
import '../generated/json_to_dart_binding.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with SingleTickerProviderStateMixin {
  final controller = Get.put(JsonController());
  final ScrollController _treeHorizontalScrollController = ScrollController();
  final ScrollController _tableHorizontalScrollController = ScrollController();

  @override
  void dispose() {
    _treeHorizontalScrollController.dispose();
    _tableHorizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: AppBar(
        title: const Text('Piku JSON Viewer',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.code),
            tooltip: 'JSON to Dart',
            onPressed: () => Get.to(() => const JsonToDartView(), binding: JsonToDartBinding()),
          ),
          Obx(() => IconButton(
            icon: Icon(controller.isDarkMode.value ? Icons.light_mode : Icons.dark_mode),
            onPressed: controller.toggleTheme,
          )),
        ],
      ),
      body: Column(
        children: [
          const Toolbar(),
          _buildTabHeader(),
          Expanded(
            child: Obx(() => AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.02, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: controller.currentTabIndex.value == 0 
                  ? _buildTreeView() 
                  : _buildEditor(),
            )),
          ),
          const StatusBar(),
        ],
      ),
    );
  }

  Widget _buildTabHeader() {
    return Container(
      color: const Color(0xFFE0E0E0),
      child: Row(
        children: [
          _TabButton(
            title: 'Viewer',
            index: 0,
            onTap: () => controller.currentTabIndex.value = 0,
          ),
          _TabButton(
            title: 'Text',
            index: 1,
            onTap: () => controller.currentTabIndex.value = 1,
          ),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    return Container(
      key: const ValueKey('EditorView'),
      color: Colors.white,
      child: CodeTheme(
        data: CodeThemeData(styles: controller.isDarkMode.value ? monokaiSublimeTheme : githubTheme),
        child: SingleChildScrollView(
          child: CodeField(
            controller: controller.codeController,
            textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.bold),
            minLines: 40,
          ),
        ),
      ),
    );
  }

  double _viewerSplitRatio = 4 / 7;

  Widget _buildTreeView() {
    return Container(
      key: const ValueKey('TreeView'),
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (controller.flattenedNodes.isEmpty) {
          return const Center(
            child: Text('Enter valid JSON to see the tree view'),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final double treeWidth = constraints.maxWidth * _viewerSplitRatio;
            return Row(
              children: [
                SizedBox(
                  width: treeWidth,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.only(top: 8),
                    child: Scrollbar(
                      controller: _treeHorizontalScrollController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _treeHorizontalScrollController,
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: 2000,
                          child: ListView.builder(
                            controller: controller.treeScrollController,
                            itemCount: controller.flattenedNodes.length,
                            itemBuilder: (context, index) {
                              final node = controller.flattenedNodes[index];
                              return JsonTreeItem(
                                key: ObjectKey(node), 
                                node: node,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.resizeLeftRight,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      setState(() {
                        _viewerSplitRatio += details.delta.dx / constraints.maxWidth;
                        _viewerSplitRatio = _viewerSplitRatio.clamp(0.2, 0.8);
                      });
                    },
                    child: Container(
                      width: 6,
                      color: Colors.grey.shade300,
                      child: const Center(
                        child: Icon(Icons.drag_indicator, size: 12, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _buildDetailTable(),
                ),
              ],
            );
          },
        );
      }),
    );
  }

  Widget _buildDetailTable() {
    return Obx(() {
      final node = controller.selectedNode.value;
      if (node == null) {
        return const Center(child: Text('Select an object or array to view details'));
      }

      final children = List<JsonNode>.from(node.children);
      children.sort((a, b) => a.key.toString().compareTo(b.key.toString()));

      return Container(
        color: Colors.white,
        child: Scrollbar(
          controller: _tableHorizontalScrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _tableHorizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 650,
              child: Column(
                children: [
                  Container(
                    height: 28,
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey.shade400, width: 1)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 250,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F0FE),
                            border: Border(right: BorderSide(color: Colors.grey.shade400, width: 1)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              const Text('Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black)),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_drop_up, size: 14, color: Colors.blue.shade700),
                            ],
                          ),
                        ),
                        Container(
                          width: 400,
                          height: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          alignment: Alignment.centerLeft,
                          child: const Text('Value', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: children.length,
                      itemBuilder: (context, index) {
                        final child = children[index];
                        return Container(
                          height: 24,
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 250,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  border: Border(right: BorderSide(color: Colors.grey.shade200, width: 1)),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                alignment: Alignment.centerLeft,
                                child: SelectableText(
                                  child.key.toString(),
                                  style: const TextStyle(fontSize: 13, fontFamily: 'monospace', color: Colors.black, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                ),
                              ),
                              Container(
                                width: 400,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                alignment: Alignment.centerLeft,
                                child: SelectableText(
                                  child.isExpandable ? '...' : child.value.toString(),
                                  style: const TextStyle(fontSize: 13, fontFamily: 'monospace', color: Colors.black, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _TabButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final int index;

  const _TabButton({
    required this.title,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<JsonController>();
    return Obx(() {
      final bool active = controller.currentTabIndex.value == index;
      return InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            border: Border(
              top: BorderSide(color: active ? Colors.grey : Colors.transparent),
              left: BorderSide(color: active ? Colors.grey : Colors.transparent),
              right: BorderSide(color: active ? Colors.grey : Colors.transparent),
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              color: Colors.black,
            ),
          ),
        ),
      );
    });
  }
}
