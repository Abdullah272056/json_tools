import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/json.dart' as highlight_json;
import 'package:highlight/languages/dart.dart' as highlight_dart;
import '../services/json_service.dart';
import '../services/dart_generator_service.dart';

class JsonToDartController extends GetxController {
  late CodeController jsonController;
  // late CodeController dartController;

  final dartController = CodeController().obs;

  var dartCode="".obs;
  late TextEditingController mainClassController;

  final mainClassName = 'MainModel'.obs;
  final usePrivateFields = false.obs;
  final generateCopyWith = false.obs;
  final generateEquatable = false.obs;
  final generateConstConstructor = false.obs;
  final generateFinalFields = false.obs;
  final generateNullableFields = true.obs;

  final validationError = Rxn<String>();
  final isGenerating = false.obs;
  final splitRatio = 0.5.obs; // Default to 50-50 split
  final _jsonText = ''.obs;

  final jsonHorizontalScrollController = ScrollController();
  final dartHorizontalScrollController = ScrollController();
  final dartVerticalScrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    jsonController = CodeController(
      text: '',
      language: highlight_json.json,
    );
    dartController.value = CodeController(
      text: '',
      language: highlight_dart.dart,
      readOnly: true,
    );
    mainClassController = TextEditingController(text: mainClassName.value);

    jsonController.addListener(() {
      if (_jsonText.value != jsonController.text) {
        _jsonText.value = jsonController.text;
      }
    });

    mainClassController.addListener(() {
      mainClassName.value = mainClassController.text.isEmpty ? 'MainModel' : mainClassController.text;
    });

    // Auto-generate Dart code whenever:
    // - JSON changes (debounced)
    debounce(_jsonText, (_) => generateDartCode(), time: const Duration(milliseconds: 500));
    
    // - Main Class Name changes (ever)
    ever(mainClassName, (_) => generateDartCode());
    
    // - Any generation option changes (ever)
    everAll([
      usePrivateFields,
      generateCopyWith,
      generateEquatable,
      generateConstConstructor,
      generateFinalFields,
      generateNullableFields
    ], (_) => generateDartCode());
  }

  @override
  void onClose() {
    jsonController.dispose();
    dartController.value.dispose();
    mainClassController.dispose();
    super.onClose();
  }

  void generateDartCode({bool showSnackbar = false}) {
    final jsonText = jsonController.text;
    if (jsonText.trim().isEmpty) {
      dartController.value.text = '';
      validationError.value = null;
      return;
    }

    final error = JsonService.validateJson(jsonText);
    if (error != null) {
      validationError.value = '${error['message']} at line ${error['line']}, col ${error['column']}';
      dartController.value.text = '';
      return;
    }

    validationError.value = null;
    isGenerating.value = true;

    try {
      final decoded = json.decode(jsonText);
      if (decoded is! Map && decoded is! List) {
        validationError.value = 'JSON must be an object {} or an array [].';
        dartController.value.text = '';
        return;
      }

      final generatedCode = DartGeneratorService.generate(
        decoded,
        mainClassName.value,
        options: GeneratorOptions(
          usePrivateFields: usePrivateFields.value,
          generateCopyWith: generateCopyWith.value,
          generateEquatable: generateEquatable.value,
          generateConstConstructor: generateConstConstructor.value,
          generateFinalFields: generateFinalFields.value,
          generateNullableFields: generateNullableFields.value,
        ),
      );
      
      if (generatedCode.trim().startsWith('//')) {
         validationError.value = generatedCode.replaceFirst('// ', '');
         dartController.value.text = '';
         if (showSnackbar) {
           Get.snackbar('Error', validationError.value!, snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.withOpacity(0.1));
         }
      } else {
        dartController.value.text = generatedCode;
        dartCode.value = generatedCode;
        dartController.refresh(); // Trigger Obx refresh
        log(generatedCode);
        validationError.value = null;
        if (showSnackbar) {
          Get.snackbar('Success', 'Dart code generated', snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 1));
        }
      }
    } catch (e) {
      validationError.value = 'Generation error: ${e.toString()}';
      dartController.value.text = '';
      if (showSnackbar) {
        Get.snackbar('Generation Error', e.toString(), snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.withOpacity(0.1));
      }
    } finally {
      isGenerating.value = false;
    }
  }

  void beautifyJson() {
    jsonController.text = JsonService.formatJson(jsonController.text);
  }

  void minifyJson() {
    jsonController.text = JsonService.minifyJson(jsonController.text);
  }

  Future<void> pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      jsonController.text = data!.text!;
    }
  }

  void clearAll() {
    jsonController.text = '';
    mainClassController.text = 'MainModel';
  }

  void loadSampleJson() {
    const sample = '''{
  "id": 1,
  "name": "Leanne Graham",
  "username": "Bret",
  "email": "Sincere@april.biz",
  "address": {
    "street": "Kulas Light",
    "suite": "Apt. 556",
    "city": "Gwenborough",
    "zipcode": "92998-3874",
    "geo": {
      "lat": "-37.3159",
      "lng": "81.1496"
    }
  },
  "phone": "1-770-736-8031 x56442",
  "website": "hildegard.org",
  "company": {
    "name": "Romaguera-Crona",
    "catchPhrase": "Multi-layered client-server neural-net",
    "bs": "harness real-time e-markets"
  },
  "tags": ["work", "personal"],
  "projects": [
    { "id": 1, "title": "Project A" },
    { "id": 2, "title": "Project B" }
  ]
}''';
    jsonController.text = sample;
  }

  void copyDartCode() {
    if (dartCode.value.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: dartCode.value));
      Get.snackbar('Copied', 'Dart code copied to clipboard', snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 1));
    } else {
      Get.snackbar('Error', 'No code to copy', snackPosition: SnackPosition.BOTTOM);
    }
  }

  void exportDartFile() {
    if (dartCode.value.isNotEmpty) {
      // Logic for exporting file can be added here
      Get.snackbar('Success', 'Dart file exported successfully', snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 1));
    } else {
      Get.snackbar('Error', 'No code to export', snackPosition: SnackPosition.BOTTOM);
    }
  }

  void shareCode() {
    if (dartCode.value.isNotEmpty) {
      // Logic for sharing code can be added here
      Get.snackbar('Share', 'Sharing Dart code...', snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 1));
    } else {
      Get.snackbar('Error', 'No code to share', snackPosition: SnackPosition.BOTTOM);
    }
  }
}

class GeneratorOptions {
  final bool usePrivateFields;
  final bool generateCopyWith;
  final bool generateEquatable;
  final bool generateConstConstructor;
  final bool generateFinalFields;
  final bool generateNullableFields;

  GeneratorOptions({
    required this.usePrivateFields,
    required this.generateCopyWith,
    required this.generateEquatable,
    required this.generateConstConstructor,
    required this.generateFinalFields,
    required this.generateNullableFields,
  });
}
