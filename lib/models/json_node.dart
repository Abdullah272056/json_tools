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
  bool isCollapsing;
  int dynamicDurationMs; // Dynamic duration based on sibling count

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
    this.dynamicDurationMs = 300,
  });

  bool get isExpandable => type == JsonNodeType.object || type == JsonNodeType.array;
}
