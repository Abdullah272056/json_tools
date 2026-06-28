import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/json_controller.dart';
import 'url_input_dialog.dart';

class Toolbar extends StatelessWidget {
  const Toolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<JsonController>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ActionButton(
              icon: Icons.format_align_left,
              label: 'Format',
              onPressed: controller.formatJson,
              tooltip: 'Format/Prettify JSON',
            ),
            _ActionButton(
              icon: Icons.compress,
              label: 'Minify',
              onPressed: controller.minifyJson,
              tooltip: 'Minify/Compact JSON',
            ),
            _ActionButton(
              icon: Icons.file_open,
              label: 'Open File',
              onPressed: controller.loadFromFile,
              tooltip: 'Load JSON from local file',
            ),
            _ActionButton(
              icon: Icons.link,
              label: 'From URL',
              onPressed: () async {
                final url = await Get.dialog<String>(const UrlInputDialog());
                if (url != null) controller.loadFromUrl(url);
              },
              tooltip: 'Load JSON from URL',
            ),
            const VerticalDivider(width: 20),
            _ActionButton(
              icon: Icons.copy,
              label: 'Copy',
              onPressed: controller.copyJson,
              tooltip: 'Copy to Clipboard',
            ),
            _ActionButton(
              icon: Icons.download,
              label: 'Download',
              onPressed: controller.downloadJson,
              tooltip: 'Download as .json',
            ),
            _ActionButton(
              icon: Icons.clear_all,
              label: 'Clear',
              onPressed: controller.clearJson,
              tooltip: 'Clear Editor',
            ),
            const VerticalDivider(width: 20),
            _ActionButton(
              icon: Icons.unfold_more,
              label: 'Expand All',
              onPressed: controller.expandAll,
              tooltip: 'Expand all nodes',
            ),
            _ActionButton(
              icon: Icons.unfold_less,
              label: 'Collapse All',
              onPressed: controller.collapseAll,
              tooltip: 'Collapse all nodes',
            ),
            const VerticalDivider(width: 20),
            _buildSearchBox(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBox(JsonController controller) {
    return Container(
      width: 250,
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: controller.performSearch,
              decoration: const InputDecoration(
                hintText: 'Search keys/values...',
                border: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Obx(() => Text(
            controller.searchResults.isEmpty 
                ? '0/0' 
                : '${controller.currentSearchIndex.value + 1}/${controller.searchResults.length}',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          )),
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 18),
            onPressed: controller.prevSearchResult,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 18),
            onPressed: controller.nextSearchResult,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final String tooltip;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }
}
