import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_highlight/themes/github.dart';
import '../controllers/json_to_dart_controller.dart';
import '../controllers/json_controller.dart';

class JsonToDartView extends GetView<JsonToDartController> {
  const JsonToDartView({super.key});

  @override
  Widget build(BuildContext context) {
    // We can't use Get.find if we are not using named routes with bindings or Get.put before.
    // Assuming this view will be pushed with Get.to(JsonToDartView(), binding: JsonToDartBinding())
    // or defined in a route.

    return Scaffold(
      appBar: AppBar(
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
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: _buildJsonInputPanel(),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 1,
          child: _buildDartOutputPanel(),
        ),
      ],
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
    final themeController = Get.find<JsonController>();
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
                  Obx(() => ElevatedButton(
                    onPressed: controller.isGenerating.value ? null : () => controller.generateDartCode(showSnackbar: true),
                    child: controller.isGenerating.value 
                      ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Generate'),
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
              child: CodeField(
                controller: controller.jsonController,
                textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                expands: true,
                wrap: false,
                lineNumberStyle: const LineNumberStyle(
                  width: 45,
                  textAlign: TextAlign.right,
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
          return const SizedBox(height: 8);
        }),
      ],
    );
  }

  Widget _buildDartOutputPanel() {
    final themeController = Get.find<JsonController>();
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.blueGrey.shade50,
          width: double.infinity,
          child: const Text(
            'Generated Dart Code',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),

        Expanded(
          flex: 7,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
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

              return SingleChildScrollView(
                child: HighlightView(
                  code,
                  language: 'dart',
                  theme: isDark ? monokaiSublimeTheme : githubTheme,
                  padding: const EdgeInsets.all(16),
                  textStyle: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(Icons.copy, 'Copy', controller.copyDartCode),
            _buildActionButton(Icons.download, 'Export', controller.exportDartFile),
            _buildActionButton(Icons.share, 'Share', controller.shareCode),
          ],
        ),
        const Divider(),
        Expanded(
          flex: 3,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildOptionSwitch('Use Private Fields', controller.usePrivateFields),
              _buildOptionSwitch('Generate copyWith()', controller.generateCopyWith),
              _buildOptionSwitch('Generate Equatable', controller.generateEquatable),
              _buildOptionSwitch('Generate const Constructor', controller.generateConstConstructor),
              _buildOptionSwitch('Generate Final Fields', controller.generateFinalFields),
              _buildOptionSwitch('Generate Nullable Fields', controller.generateNullableFields),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildOptionSwitch(String title, RxBool value) {
    return Obx(() => SwitchListTile(
      title: Text(title, style: const TextStyle(fontSize: 13)),
      value: value.value,
      onChanged: (v) => value.value = v,
      dense: true,
    ));
  }
}
