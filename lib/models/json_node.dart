enum JsonNodeType { object, array, string, number, boolean, nullValue }

class JsonNode {
  final dynamic key;
  final dynamic value;
  final JsonNodeType type;
  final int depth;
  bool isExpanded;
  List<JsonNode> children;
  final JsonNode? parent;
  
  bool wasJustAdded; 
  bool isCollapsing; // New flag for smooth collapse

  JsonNode({
    required this.key,
    required this.value,
    required this.type,
    required this.depth,
    this.isExpanded = false,
    this.children = const [],
    this.parent,
    this.wasJustAdded = false,
    this.isCollapsing = false,
  });

  bool get isExpandable => type == JsonNodeType.object || type == JsonNodeType.array;
}
