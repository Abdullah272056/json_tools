import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/json.dart' as highlight_json;
import 'package:universal_html/html.dart' as html show Blob, AnchorElement, Url;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import '../models/json_node.dart';
import '../services/json_service.dart';

class JsonController extends GetxController {
  late CodeController codeController;

  var jsonOutput = ''.obs;
  var validationError = Rxn<Map<String, dynamic>>();
  var rootNode = Rxn<JsonNode>();
  var flattenedNodes = <JsonNode>[].obs;
  
  var isLoading = false.obs;
  var isDarkMode = false.obs;
  
  var totalKeys = 0.obs;
  var totalNodes = 0.obs;
  var jsonSize = '0 KB'.obs;
  var treeFontSize = 13.0.obs;

  var searchQuery = ''.obs;
  var searchResults = <JsonNode>[].obs;
  var currentSearchIndex = (-1).obs;
  var selectedNode = Rxn<JsonNode>();
  
  final ScrollController treeScrollController = ScrollController();
  final GlobalKey<AnimatedListState> treeListKey = GlobalKey<AnimatedListState>();

  @override
  void onInit() {
    super.onInit();
    codeController = CodeController(
      text: '',
      language: highlight_json.json,
    );
    codeController.addListener(() {
      _handleJsonChange(codeController.text);
    });
  }

  void selectNode(JsonNode node) {
    if (node.isExpandable) {
      selectedNode.value = node;
    } else if (node.parent != null) {
      selectedNode.value = node.parent;
    } else {
      selectedNode.value = node;
    }
  }

  void _handleJsonChange(String value) {
    jsonOutput.value = value;
    _validate(value);
    _calculateStats(value);
    _updateTreeView(value);
  }

  void _validate(String value) {
    validationError.value = JsonService.validateJson(value);
  }

  void _calculateStats(String value) {
    if (value.trim().isEmpty) {
      totalKeys.value = 0;
      jsonSize.value = '0 B';
      return;
    }
    try {
      final decoded = json.decode(value);
      totalKeys.value = JsonService.countKeys(decoded);
      final bytes = utf8.encode(value).length;
      if (bytes < 1024) {
        jsonSize.value = '$bytes B';
      } else if (bytes < 1024 * 1024) {
        jsonSize.value = '${(bytes / 1024).toStringAsFixed(2)} KB';
      } else {
        jsonSize.value = '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
      }
    } catch (_) {}
  }

  void _updateTreeView(String value) {
    if (validationError.value != null || value.trim().isEmpty) {
      rootNode.value = null;
      flattenedNodes.clear();
      totalNodes.value = 0;
      return;
    }
    try {
      final decoded = json.decode(value);
      rootNode.value = JsonService.parseToRootNode(decoded);
      totalNodes.value = JsonService.countNodes(rootNode.value!);
      _refreshFlattenedNodes();
    } catch (_) {}
  }

  void _refreshFlattenedNodes() {
    if (rootNode.value == null) {
      flattenedNodes.clear();
      return;
    }
    flattenedNodes.assignAll(JsonService.flatten(rootNode.value!, onlyVisible: true));
  }

  void toggleNode(JsonNode node) {
    final int index = flattenedNodes.indexOf(node);
    if (index == -1) return;

    if (node.isExpanded) {
      // Collapse
      final List<JsonNode> toRemove = _getVisibleSubtree(node);
      node.isExpanded = false;
      for (int i = 0; i < toRemove.length; i++) {
        flattenedNodes.removeAt(index + 1);
        treeListKey.currentState?.removeItem(
          index + 1,
          (context, animation) => const SizedBox.shrink(), // Immediate removal for collapse speed
          duration: const Duration(milliseconds: 150),
        );
      }
    } else {
      // Expand
      node.isExpanded = true;
      final List<JsonNode> toInsert = _getVisibleSubtree(node);
      for (int i = 0; i < toInsert.length; i++) {
        flattenedNodes.insert(index + 1 + i, toInsert[i]);
        treeListKey.currentState?.insertItem(
          index + 1 + i,
          duration: const Duration(milliseconds: 200),
        );
      }
    }
  }

  List<JsonNode> _getVisibleSubtree(JsonNode node) {
    List<JsonNode> result = [];
    for (var child in node.children) {
      result.add(child);
      if (child.isExpanded) {
        result.addAll(_getVisibleSubtree(child));
      }
    }
    return result;
  }

  void expandAll() {
    if (rootNode.value == null) return;
    _setExpanded(rootNode.value!, true);
    _refreshFlattenedNodes();
    // Reset the animated list
    _reloadList();
  }

  void collapseAll() {
    if (rootNode.value == null) return;
    _setExpanded(rootNode.value!, false);
    _refreshFlattenedNodes();
    _reloadList();
  }

  void _reloadList() {
    // A trick to refresh the AnimatedList when bulk changes happen
    // In a real app, you'd replace the AnimatedList or use a different approach for bulk
  }

  void _setExpanded(JsonNode node, bool expanded) {
    node.isExpanded = expanded;
    for (var child in node.children) {
      _setExpanded(child, expanded);
    }
  }

  void formatJson() {
    final formatted = JsonService.formatJson(codeController.text);
    codeController.text = formatted;
  }

  void minifyJson() {
    final minified = JsonService.minifyJson(codeController.text);
    codeController.text = minified;
  }

  void clearJson() {
    codeController.text = '';
  }

  void copyJson() {
    Clipboard.setData(ClipboardData(text: codeController.text));
    Get.snackbar('Copied', 'JSON copied to clipboard', snackPosition: SnackPosition.BOTTOM);
  }

  Future<void> loadFromFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result != null) {
        if (kIsWeb) {
          final bytes = result.files.first.bytes;
          if (bytes != null) {
            codeController.text = utf8.decode(bytes);
          }
        } else {
          final path = result.files.first.path;
          if (path != null) {
            final file = File(path);
            codeController.text = await file.readAsString();
          }
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load file');
    }
  }

  Future<void> loadFromUrl(String url) async {
    if (url.isEmpty) return;
    isLoading.value = true;
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        codeController.text = response.body;
      } else {
        Get.snackbar('Error', 'Failed to load JSON from URL: ${response.statusCode}');
      }
    } catch (e) {
      Get.snackbar('Error', 'Invalid URL or network error');
    } finally {
      isLoading.value = false;
    }
  }

  void downloadJson() async {
    final text = codeController.text;
    if (text.isEmpty) return;
    
    try {
      if (kIsWeb) {
        final bytes = utf8.encode(text);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", "data.json")
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/data.json');
        await file.writeAsString(text);
        Get.snackbar('Success', 'File saved to ${file.path}');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to save file');
    }
  }

  void performSearch(String query) {
    searchQuery.value = query;
    searchResults.clear();
    currentSearchIndex.value = -1;
    if (query.trim().isEmpty || rootNode.value == null) return;

    _searchInNode(rootNode.value!, query.toLowerCase());
    if (searchResults.isNotEmpty) {
      currentSearchIndex.value = 0;
      _jumpToSearchResult(0);
    }
  }

  void _searchInNode(JsonNode node, String query) {
    bool match = false;
    if (node.key.toString().toLowerCase().contains(query)) match = true;
    if (node.type != JsonNodeType.object && node.type != JsonNodeType.array) {
      if (node.value.toString().toLowerCase().contains(query)) match = true;
    }
    
    if (match) searchResults.add(node);
    
    for (var child in node.children) {
      _searchInNode(child, query);
    }
  }

  void _jumpToSearchResult(int index) {
    if (index < 0 || index >= searchResults.length) return;
    final node = searchResults[index];
    _expandParents(node);
    _refreshFlattenedNodes();
    
    // Logic to scroll to the node could be added here
    final flatIndex = flattenedNodes.indexOf(node);
    if (flatIndex != -1) {
      // Small delay to allow UI to update
      Future.delayed(const Duration(milliseconds: 100), () {
        if (treeScrollController.hasClients) {
          treeScrollController.animateTo(
            flatIndex * 30.0, // Assuming each row is ~30px
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _expandParents(JsonNode node) {
    var p = node.parent;
    while (p != null) {
      p.isExpanded = true;
      p = p.parent;
    }
  }

  void nextSearchResult() {
    if (searchResults.isEmpty) return;
    currentSearchIndex.value = (currentSearchIndex.value + 1) % searchResults.length;
    _jumpToSearchResult(currentSearchIndex.value);
  }

  void prevSearchResult() {
    if (searchResults.isEmpty) return;
    currentSearchIndex.value = (currentSearchIndex.value - 1 + searchResults.length) % searchResults.length;
    _jumpToSearchResult(currentSearchIndex.value);
  }

  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  void updateFontSize(double delta) {
    double newSize = treeFontSize.value + delta;
    if (newSize >= 8 && newSize <= 30) {
      treeFontSize.value = newSize;
    }
  }
}
