enum JsonNodeType { object, array, string, number, boolean, nullValue }

class JsonNode {
  final dynamic key;
  final dynamic value;
  final JsonNodeType type;
  final int depth;
  bool isExpanded;
  List<JsonNode> children;
  final JsonNode? parent;

  JsonNode({
    required this.key,
    required this.value,
    required this.type,
    required this.depth,
    this.isExpanded = false,
    this.children = const [],
    this.parent,
  });

  bool get isExpandable => type == JsonNodeType.object || type == JsonNodeType.array;

  String get valueString {
    if (type == JsonNodeType.object) return 'Object {${children.length}}';
    if (type == JsonNodeType.array) return 'Array [${children.length}]';
    return value.toString();
  }
}
