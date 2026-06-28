import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_highlight/themes/github.dart';
import '../controllers/json_controller.dart';
import '../widgets/toolbar.dart';
import '../widgets/status_bar.dart';
import '../widgets/json_tree_item.dart';
import '../utils/responsive.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with SingleTickerProviderStateMixin {
  final controller = Get.put(JsonController());
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: AppBar(
        title: const Text('JSON Viewer'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
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
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTreeView(),
                _buildEditor(),
              ],
            ),
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
            isSelected: true,
            onTap: () => _tabController.animateTo(0),
            controller: _tabController,
            index: 0,
          ),
          _TabButton(
            title: 'Text',
            isSelected: false,
            onTap: () => _tabController.animateTo(1),
            controller: _tabController,
            index: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    return Obx(() => Container(
      color: Colors.white,
      child: CodeTheme(
        data: CodeThemeData(styles: controller.isDarkMode.value ? monokaiSublimeTheme : githubTheme),
        child: SingleChildScrollView(
          child: CodeField(
            controller: controller.codeController,
            textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            minLines: 40,
          ),
        ),
      ),
    ));
  }

  double _viewerSplitRatio = 0.5;

  Widget _buildTreeView() {
    return Obx(() {
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
          return Row(
            children: [
              SizedBox(
                width: constraints.maxWidth * _viewerSplitRatio,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.only(top: 8),
                  child: ListView.builder(
                    controller: controller.treeScrollController,
                    itemCount: controller.flattenedNodes.length,
                    itemBuilder: (context, index) {
                      return JsonTreeItem(node: controller.flattenedNodes[index]);
                    },
                  ),
                ),
              ),
              GestureDetector(
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _viewerSplitRatio += details.delta.dx / constraints.maxWidth;
                    _viewerSplitRatio = _viewerSplitRatio.clamp(0.2, 0.8);
                  });
                },
                child: Container(
                  width: 4,
                  color: Colors.grey.shade300,
                  child: const Center(
                    child: Icon(Icons.drag_indicator, size: 12, color: Colors.grey),
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
    });
  }

  Widget _buildDetailTable() {
    return Obx(() {
      final node = controller.selectedNode.value;
      if (node == null) {
        return const Center(child: Text('Select an object or array to view details'));
      }

      final children = node.children;

      return Container(
        color: Colors.white,
        child: Column(
          children: [
            Container(
              height: 28,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade400, width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F0FE), // Light blue for header
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
                  ),
                  Expanded(
                    child: Container(
                      height: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      alignment: Alignment.centerLeft,
                      child: const Text('Value', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black)),
                    ),
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
                        Expanded(
                          child: Container(
                            height: double.infinity,
                            decoration: BoxDecoration(
                              border: Border(right: BorderSide(color: Colors.grey.shade200, width: 1)),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            alignment: Alignment.centerLeft,
                            child: SelectableText(
                              child.key.toString(),
                              style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.black, fontWeight: FontWeight.bold),
                              maxLines: 1,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            alignment: Alignment.centerLeft,
                            child: SelectableText(
                              child.isExpandable ? '...' : child.value.toString(),
                              style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.black, fontWeight: FontWeight.bold),
                              maxLines: 1,
                            ),
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
      );
    });
  }
}

class _TabButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final TabController controller;
  final int index;

  const _TabButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
    required this.controller,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final bool active = controller.index == index;
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
      },
    );
  }
}
