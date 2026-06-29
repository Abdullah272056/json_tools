import '../controllers/json_to_dart_controller.dart';

class _PendingClass {
  final String className;
  final Map<String, dynamic> data;
  _PendingClass(this.className, this.data);
}

class DartGeneratorService {
  final Set<String> _generatedClassNames = {};
  final List<String> _generatedClasses = [];
  final GeneratorOptions options;

  DartGeneratorService(this.options);

  static String generate(dynamic jsonData, String rootClassName, {required GeneratorOptions options}) {
    final service = DartGeneratorService(options);
    return service._doGenerate(jsonData, rootClassName);
  }

  String _doGenerate(dynamic jsonData, String rootClassName) {
    _generatedClassNames.clear();
    _generatedClasses.clear();

    final List<_PendingClass> queue = [];

    if (jsonData is List) {
      if (jsonData.isEmpty) {
        return '// The provided JSON array is empty.';
      }
      queue.add(_PendingClass(rootClassName, Map<String, dynamic>.from(jsonData.first)));
    } else if (jsonData is Map) {
      queue.add(_PendingClass(rootClassName, Map<String, dynamic>.from(jsonData)));
    } else {
      return '// Invalid JSON data. Must be an object or an array of objects.';
    }

    while (queue.isNotEmpty) {
      final item = queue.removeAt(0);
      final pascalClassName = _toPascalCase(item.className);
      
      if (_generatedClassNames.contains(pascalClassName)) continue;
      _generatedClassNames.add(pascalClassName);
      
      _generatedClasses.add(_generateClass(pascalClassName, item.data, queue));
    }

    String output = '';
    if (options.generateEquatable) {
      output += "import 'package:equatable/equatable.dart';\n\n";
    }

    output += _generatedClasses.join('\n\n');
    return output;
  }

  String _generateClass(String className, Map<String, dynamic> json, List<_PendingClass> queue) {
    final sb = StringBuffer();
    final Map<String, String> fields = {};
    final Map<String, String> originalKeys = {};

    json.forEach((key, value) {
      final fieldName = _toCamelCase(key);
      final fieldType = _detectType(key, value);
      fields[fieldName] = fieldType;
      originalKeys[fieldName] = key;

      if (value is Map) {
        queue.add(_PendingClass(fieldType, Map<String, dynamic>.from(value)));
      } else if (value is List && value.isNotEmpty) {
        final first = value.first;
        if (first is Map) {
          final innerType = _toPascalCase(key);
          queue.add(_PendingClass(innerType, Map<String, dynamic>.from(first)));
        }
      }
    });

    // Class definition
    if (options.generateEquatable) {
      sb.writeln('class $className extends Equatable {');
    } else {
      sb.writeln('class $className {');
    }

    // Field declarations
    fields.forEach((name, type) {
      final fieldType = options.generateNullableFields ? '$type?' : type;
      final prefix = options.generateFinalFields ? 'final ' : '';
      if (options.usePrivateFields) {
        sb.writeln('  $prefix$fieldType _$name;');
      } else {
        sb.writeln('  $prefix$fieldType $name;');
      }
    });

    // Getters for Private Fields
    if (options.usePrivateFields) {
      sb.writeln();
      fields.forEach((name, type) {
        final fieldType = options.generateNullableFields ? '$type?' : type;
        sb.writeln('  $fieldType get $name => _$name;');
      });
    }

    sb.writeln();

    // Constructor
    final constPrefix = options.generateConstConstructor ? 'const ' : '';
    sb.write('  $constPrefix$className({');
    int count = 0;
    fields.forEach((name, type) {
      final paramPrefix = options.usePrivateFields ? 'this._' : 'this.';
      sb.write('$paramPrefix$name');
      if (++count < fields.length) sb.write(', ');
    });
    sb.writeln('});');

    sb.writeln();

    // fromJson
    if (options.generateFinalFields) {
      sb.writeln('  $className.fromJson(Map<String, dynamic> json)');
      int initCount = 0;
      fields.forEach((name, type) {
        final key = originalKeys[name];
        final fieldName = options.usePrivateFields ? '_$name' : name;
        final separator = initCount == 0 ? '      : ' : '        ';
        
        if (type.startsWith('List<')) {
          final innerType = type.substring(5, type.length - 1);
          if (['String', 'int', 'double', 'bool', 'dynamic', 'Null'].contains(innerType)) {
             sb.write("$separator$fieldName = json['$key']?.cast<$innerType>()");
          } else {
             sb.write("$separator$fieldName = json['$key'] != null ? (json['$key'] as List).map((i) => $innerType.fromJson(i)).toList() : null");
          }
        } else if (!['String', 'int', 'double', 'bool', 'dynamic', 'Null'].contains(type)) {
          sb.write("$separator$fieldName = json['$key'] != null ? new $type.fromJson(json['$key']) : null");
        } else {
          sb.write("$separator$fieldName = json['$key']");
        }
        
        if (++initCount < fields.length) sb.writeln(',');
      });
      sb.writeln(';');
    } else {
      sb.writeln('  $className.fromJson(Map<String, dynamic> json) {');
      fields.forEach((name, type) {
        final key = originalKeys[name];
        final fieldName = options.usePrivateFields ? '_$name' : name;
        
        if (type.startsWith('List<')) {
          final innerType = type.substring(5, type.length - 1);
          sb.writeln("    if (json['$key'] != null) {");
          sb.writeln("      $fieldName = <$innerType>[];");
          sb.writeln("      json['$key'].forEach((v) {");
          if (['String', 'int', 'double', 'bool', 'dynamic', 'Null'].contains(innerType)) {
            sb.writeln("        $fieldName!.add(v);");
          } else {
            sb.writeln("        $fieldName!.add(new $innerType.fromJson(v));");
          }
          sb.writeln("      });");
          sb.writeln("    }");
        } else if (!['String', 'int', 'double', 'bool', 'dynamic', 'Null'].contains(type)) {
          sb.writeln("    $fieldName = json['$key'] != null ? new $type.fromJson(json['$key']) : null;");
        } else {
          sb.writeln("    $fieldName = json['$key'];");
        }
      });
      sb.writeln('  }');
    }

    sb.writeln();

    // toJson
    sb.writeln('  Map<String, dynamic> toJson() {');
    sb.writeln('    final Map<String, dynamic> data = new Map<String, dynamic>();');
    fields.forEach((name, type) {
      final key = originalKeys[name];
      final fieldName = options.usePrivateFields ? '_$name' : name;
      
      if (type.startsWith('List<')) {
        final innerType = type.substring(5, type.length - 1);
        if (['String', 'int', 'double', 'bool', 'dynamic', 'Null'].contains(innerType)) {
          sb.writeln("    data['$key'] = this.$fieldName;");
        } else {
          sb.writeln("    if (this.$fieldName != null) {");
          sb.writeln("      data['$key'] = this.$fieldName!.map((v) => v.toJson()).toList();");
          sb.writeln("    }");
        }
      } else if (!['String', 'int', 'double', 'bool', 'dynamic', 'Null'].contains(type)) {
        sb.writeln("    if (this.$fieldName != null) {");
        sb.writeln("      data['$key'] = this.$fieldName!.toJson();");
        sb.writeln("    }");
      } else {
        sb.writeln("    data['$key'] = this.$fieldName;");
      }
    });
    sb.writeln('    return data;');
    sb.writeln('  }');

    // copyWith
    if (options.generateCopyWith) {
      sb.writeln();
      sb.writeln('  $className copyWith({');
      fields.forEach((name, type) {
        sb.writeln('    $type? $name,');
      });
      sb.writeln('  }) {');
      sb.writeln('    return $className(');
      int cpCount = 0;
      fields.forEach((name, type) {
        final paramName = options.usePrivateFields ? '_$name' : name;
        sb.write('      $name: $name ?? this.$paramName');
        if (++cpCount < fields.length) sb.writeln(',');
      });
      sb.writeln('\n    );');
      sb.writeln('  }');
    }

    // Equatable props
    if (options.generateEquatable) {
      sb.writeln();
      sb.writeln('  @override');
      sb.writeln('  List<Object?> get props => [');
      fields.forEach((name, type) {
        final fieldName = options.usePrivateFields ? '_$name' : name;
        sb.writeln('    $fieldName,');
      });
      sb.writeln('  ];');
    }

    sb.writeln('}');
    return sb.toString();
  }

  String _detectType(String key, dynamic value) {
    if (value == null) return 'dynamic';
    if (value is String) return 'String';
    if (value is int) return 'int';
    if (value is double) return 'double';
    if (value is bool) return 'bool';
    if (value is Map) return _toPascalCase(key);
    if (value is List) {
      if (value.isEmpty) return 'List<dynamic>';
      final first = value.first;
      if (first is Map) {
        return 'List<${_toPascalCase(key)}>';
      }
      return 'List<${_detectType(key, first)}>';
    }
    return 'dynamic';
  }

  String _toPascalCase(String text) {
    if (text.isEmpty) return text;
    final words = _splitIntoWords(text);
    return words.map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase()).join('');
  }

  String _toCamelCase(String text) {
    if (text.isEmpty) return text;
    final words = _splitIntoWords(text);
    String result = words[0].toLowerCase();
    for (int i = 1; i < words.length; i++) {
      result += words[i][0].toUpperCase() + words[i].substring(1).toLowerCase();
    }
    return result;
  }

  List<String> _splitIntoWords(String text) {
    String sanitized = text.replaceAll(RegExp(r'[^a-zA-Z0-9]'), ' ');
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'), 
      (match) => '${match.group(1)} ${match.group(2)}'
    );
    return sanitized.split(' ').where((w) => w.isNotEmpty).toList();
  }
}
