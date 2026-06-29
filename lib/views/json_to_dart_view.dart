import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:highlight/highlight.dart' show highlight;
import 'package:highlight/src/node.dart' as hi;
import '../controllers/json_to_dart_controller.dart';
import '../controllers/theme_controller.dart';

class JsonToDartView extends GetView<JsonToDartController> {
  const JsonToDartView({super.key});

  @override 
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.home_rounded),
          onPressed: () => Get.offAllNamed('/'),
          tooltip: 'Back to Home',
        ),
        title: const Text('JSON to Dart Converter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            onPressed: controller.clearAll,
            tooltip: 'Clear All',
          ),
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: controller.loadSampleJson,
            tooltip: 'Load Sample',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return _buildDesktopLayout();
          } else {
            return _buildMobileLayout();
          }
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Obx(() {
          final double leftWidth = constraints.maxWidth * controller.splitRatio.value;
          
          return Row(
            children: [
              SizedBox(
                width: leftWidth,
                child: _buildJsonInputPanel(),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.resizeLeftRight,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    double delta = details.delta.dx / constraints.maxWidth;
                    double newRatio = controller.splitRatio.value + delta;
                    controller.splitRatio.value = newRatio.clamp(0.2, 0.8);
                  },
                  child: Container(
                    width: 8,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.drag_indicator, size: 14, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _buildDartOutputPanel(),
              ),
            ],
          );
        });
      },
    );
  }

  Widget _buildMobileLayout() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'JSON'),
              Tab(text: 'Dart'),
            ],
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildJsonInputPanel(),
                _buildDartOutputPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJsonInputPanel() {
    final themeController = Get.find<ThemeController>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Main Class Name',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      controller: controller.mainClassController,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Obx(() => ElevatedButton.icon(
                    onPressed: controller.isGenerating.value ? null : () => controller.generateDartCode(showSnackbar: true),
                    icon: controller.isGenerating.value 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.auto_fix_high, size: 18),
                    label: const Text('Generate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                  )),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'beautify': controller.beautifyJson(); break;
                        case 'minify': controller.minifyJson(); break;
                        case 'paste': controller.pasteFromClipboard(); break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'beautify', child: Text('Beautify JSON')),
                      const PopupMenuItem(value: 'minify', child: Text('Minify JSON')),
                      const PopupMenuItem(value: 'paste', child: Text('Paste From Clipboard')),
                    ],
                    child: const Icon(Icons.more_vert),
                  ),
                ],
              ),
            ],
          ),
        ), 
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              color: Colors.white,
            ),
            child: Obx(() => CodeTheme(
              data: CodeThemeData(styles: themeController.isDarkMode.value ? monokaiSublimeTheme : githubTheme),
              child: Scrollbar(
                controller: controller.jsonHorizontalScrollController,
                thumbVisibility: true, 
                notificationPredicate: (notif) => notif.depth == 0,
                child: SingleChildScrollView(
                  controller: controller.jsonHorizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 2000, // Large width for horizontal scrolling
                    child: Stack(
                      children: [
                        CodeField(
                          controller: controller.jsonController,
                          focusNode: controller.focusNode,
                          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.bold),
                          expands: true, 
                          wrap: false,
                        ),
                        Obx(() => controller.jsonInputText.value.isEmpty
                            ? Positioned(
                                left: 48,
                                top: 12,
                                child: Text(
                                  'Paste your JSON here to convert to Dart...',
                                  style: TextStyle(
                                    color: Colors.grey.withOpacity(0.5),
                                    fontFamily: 'monospace',
                                    fontSize: 14,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink()),
                      ],
                    ),
                  ),
                ),
              ),
            )),
          ),
        ),
        Obx(() {
          if (controller.validationError.value != null) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(top: 4),
              color: Colors.red.shade50,
              width: double.infinity,
              child: Text(
                controller.validationError.value!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            );
          }
          return const SizedBox(height: 4);
        }),
        const Divider(),
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [ 
              _buildOptionSwitch('Generate Nullable Fields', controller.generateNullableFields),
              _buildOptionSwitch('Use Private Fields', controller.usePrivateFields),
              _buildOptionSwitch('Generate copyWith()', controller.generateCopyWith),
              _buildOptionSwitch('Generate Equatable', controller.generateEquatable),
              _buildOptionSwitch('Generate const Constructor', controller.generateConstConstructor),
              _buildOptionSwitch('Generate Final Fields', controller.generateFinalFields),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDartOutputPanel() {
    final themeController = Get.find<ThemeController>();
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.blueGrey.shade50,
          width: double.infinity,
          child: Row(
            // mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Generated Dart Code:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(width: 25,),
              Expanded(child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildHeaderButton(Icons.copy, 'Copy', controller.copyDartCode),
                  const SizedBox(width: 15,),
                  _buildHeaderButton(Icons.download, 'Export', controller.exportDartFile),
                  const SizedBox(width: 15,),
                  _buildHeaderButton(Icons.share, 'Share', controller.shareCode),
                ],
              )),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              color: themeController.isDarkMode.value ? const Color(0xFF1E1E1E) : Colors.white,
            ),
            child: Obx(() {
              final isDark = themeController.isDarkMode.value;
              final code = controller.dartCode.value;
              
              if (code.isEmpty) {
                return const Center(
                  child: Text('Generate code to see it here', 
                    style: TextStyle(color: Colors.grey)
                  ),
                );
              }
 
              final theme = isDark ? monokaiSublimeTheme : githubTheme;

              return SelectionArea(
                child: Scrollbar(
                  controller: controller.dartHorizontalScrollController,
                  thumbVisibility: true,
                  notificationPredicate: (notif) => notif.depth == 1,
                  child: Scrollbar(
                    controller: controller.dartVerticalScrollController,
                    notificationPredicate: (notif) => notif.depth == 0,
                    child: SingleChildScrollView(
                      controller: controller.dartVerticalScrollController,
                      child: SingleChildScrollView(
                        controller: controller.dartHorizontalScrollController,
                        scrollDirection: Axis.horizontal,
                        child: IntrinsicWidth(
                          child: Padding( 
                            padding: const EdgeInsets.all(16),
                            child: Text.rich(
                              _formatCode(code, theme),
                              softWrap: false,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  TextSpan _formatCode(String code, Map<String, TextStyle> theme) {
    final result = highlight.parse(code, language: 'dart');
    return TextSpan(
      children: _convertNodes(result.nodes!, theme),
    );
  }

  List<TextSpan> _convertNodes(List<hi.Node> nodes, Map<String, TextStyle> theme) {
    List<TextSpan> spans = [];
    for (var node in nodes) {
      if (node.value != null) {
        spans.add(TextSpan(text: node.value, style: theme[node.className]));
      } else if (node.children != null) {
        spans.add(TextSpan(
          children: _convertNodes(node.children!, theme),
          style: theme[node.className],
        ));
      }
    }
    return spans;
  }

  Widget _buildHeaderButton(IconData icon, String label, VoidCallback onPressed) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      style: TextButton.styleFrom(
        foregroundColor: Colors.blue.shade800,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  Widget _buildOptionSwitch(String title, RxBool value) {
    return Obx(() => Container(
      height: 30, // Reduced height
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 14)), // Increased to 14
          Transform.scale(
            scale: 0.7, // Scaled down switch to fit compact height
            child: Switch(
              value: value.value,
              onChanged: (v) => value.value = v,
              activeColor: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    ));
  }
}
