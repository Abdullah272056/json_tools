import 'dart:convert';
import '../models/json_node.dart';

class JsonService {
  static String formatJson(String jsonString) {
    try {
      final object = json.decode(jsonString);
      return const JsonEncoder.withIndent('  ').convert(object);
    } catch (e) {
      return jsonString;
    }
  }

  static String minifyJson(String jsonString) {
    try {
      final object = json.decode(jsonString);
      return json.encode(object);
    } catch (e) {
      return jsonString;
    }
  }

  static Map<String, dynamic>? validateJson(String jsonString) {
    if (jsonString.trim().isEmpty) return null;
    try {
      json.decode(jsonString);
      return null;
    } catch (e) {
      if (e is FormatException) {
        return {
          'message': e.message,
          'line': _getLineNumber(jsonString, e.offset ?? 0),
          'column': _getColumnNumber(jsonString, e.offset ?? 0),
          'offset': e.offset,
        };
      }
      return {'message': e.toString()};
    }
  }

  static int _getLineNumber(String source, int offset) {
    if (offset <= 0) return 1;
    if (offset > source.length) offset = source.length;
    return source.substring(0, offset).split('\n').length;
  }

  static int _getColumnNumber(String source, int offset) {
    if (offset <= 0) return 1;
    if (offset > source.length) offset = source.length;
    final lines = source.substring(0, offset).split('\n');
    return lines.last.length + 1;
  }

  static JsonNode parseToRootNode(dynamic data, {dynamic key = 'JSON'}) {
    return _parse(data, key: key, depth: 0);
  }

  static JsonNode _parse(dynamic data, {dynamic key, int depth = 0, JsonNode? parent}) {
    if (data is Map) {
      final node = JsonNode(
        key: key,
        value: data,
        type: JsonNodeType.object,
        depth: depth,
        parent: parent,
      );
      node.children = data.entries
          .map((e) => _parse(e.value, key: e.key, depth: depth + 1, parent: node))
          .toList();
      return node;
    } else if (data is List) {
      final node = JsonNode(
        key: key,
        value: data,
        type: JsonNodeType.array,
        depth: depth,
        parent: parent,
      );
      node.children = data
          .asMap()
          .entries
          .map((e) => _parse(e.value, key: '[${e.key}]', depth: depth + 1, parent: node))
          .toList();
      return node;
    } else {
      JsonNodeType type;
      if (data == null) {
        type = JsonNodeType.nullValue;
      } else if (data is String) {
        type = JsonNodeType.string;
      } else if (data is num) {
        type = JsonNodeType.number;
      } else if (data is bool) {
        type = JsonNodeType.boolean;
      } else {
        type = JsonNodeType.string;
      }
      return JsonNode(
        key: key,
        value: data,
        type: type,
        depth: depth,
        parent: parent,
      );
    }
  }

  static List<JsonNode> flatten(JsonNode node, {bool onlyVisible = true}) {
    List<JsonNode> result = [node];
    if (onlyVisible && !node.isExpanded) return result;
    for (var child in node.children) {
      result.addAll(flatten(child, onlyVisible: onlyVisible));
    }
    return result;
  }

  static int countKeys(dynamic data) {
    if (data is Map) {
      int count = data.length;
      for (var value in data.values) {
        count += countKeys(value);
      }
      return count;
    } else if (data is List) {
      int count = 0;
      for (var value in data) {
        count += countKeys(value);
      }
      return count;
    }
    return 0;
  }

  static int countNodes(JsonNode node) {
    int count = 1;
    for (var child in node.children) {
      count += countNodes(child);
    }
    return count;
  }
}
