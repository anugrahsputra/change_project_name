import 'dart:convert';
import 'dart:io';

class ProjectConfig {
  final String? name;
  final String? appName;
  final String? packageName;
  final Map<String, String> customReplacements;
  final bool? backup;
  final bool? commit;
  final bool? refresh;

  ProjectConfig({
    this.name,
    this.appName,
    this.packageName,
    this.customReplacements = const {},
    this.backup,
    this.commit,
    this.refresh,
  });

  factory ProjectConfig.fromJson(Map<String, dynamic> json) {
    final options = json['options'] as Map<String, dynamic>? ?? {};
    final replacements = json['custom_replacements'] as Map<String, dynamic>? ?? {};

    return ProjectConfig(
      name: json['name'] as String?,
      appName: json['app_name'] as String?,
      packageName: json['package_name'] as String?,
      customReplacements: replacements.map((key, value) => MapEntry(key, value.toString())),
      backup: options['backup'] as bool?,
      commit: options['commit'] as bool?,
      refresh: options['refresh'] as bool?,
    );
  }

  static Future<ProjectConfig?> load(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;

    try {
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return ProjectConfig.fromJson(json);
    } catch (e) {
      print('⚠️  Warning: Could not parse config file at $path: $e');
      return null;
    }
  }

  static Future<void> generateTemplate(String path) async {
    final template = {
      "name": "new_project_name",
      "app_name": "New App Name",
      "package_name": "com.example.new_app",
      "custom_replacements": {
        "OldText": "NewText",
        "AnotherOld": "AnotherNew"
      },
      "options": {
        "backup": true,
        "commit": false,
        "refresh": true
      }
    };

    final file = File(path);
    if (await file.exists()) {
      print('⚠️  Config file already exists at $path');
      return;
    }

    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(template));
    print('✅ Generated template config file at $path');
  }
}
