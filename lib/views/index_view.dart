import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'home_view.dart';
import 'json_to_dart_view.dart';
import '../generated/json_to_dart_binding.dart';

class IndexView extends StatelessWidget {
  const IndexView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JSON Tools', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Container(
        color: const Color(0xFFF5F5F5),
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  return Row(
                    children: [
                      Expanded(
                        child: _buildToolCard(
                          title: 'JSON Viewer',
                          description: 'View and explore your JSON data in a tree or table format.',
                          icon: Icons.account_tree_outlined,
                          color: Colors.blue,
                          onTap: () => Get.toNamed('/HomeView'),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildToolCard(
                          title: 'JSON to Dart',
                          description: 'Convert JSON objects into Dart class models automatically.',
                          icon: Icons.code,
                          color: Colors.orange,
                          onTap: () => Get.toNamed('/JsonToDartView'),
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildToolCard(
                        title: 'JSON Viewer',
                        description: 'View and explore your JSON data in a tree or table format.',
                        icon: Icons.account_tree_outlined,
                        color: Colors.blue,
                        onTap: () => Get.toNamed('/HomeView'),
                      ),
                      const SizedBox(height: 24),
                      _buildToolCard(
                        title: 'JSON to Dart',
                        description: 'Convert JSON objects into Dart class models automatically.',
                        icon: Icons.code,
                        color: Colors.orange,
                        onTap: () => Get.toNamed('/JsonToDartView'),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: color),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
