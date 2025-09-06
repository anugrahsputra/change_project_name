import 'dart:convert';
import 'dart:io';

/// Recursively find all dart files except in build & .dart_tool
Future<List<File>> findDartFiles(Directory dir) async {
  final files = <File>[];

  await for (final entity in dir.list(recursive: true, followLinks: false)) {
    if (entity is File &&
        entity.path.endsWith('.dart') &&
        !entity.path.contains('build/') &&
        !entity.path.contains('.dart_tool/')) {
      // Fixed: was 'dart_tool.'
      files.add(entity);
    }
  }

  return files;
}

/// Validate project name according to Dart package naming conventions
bool isValidPackageName(String name) {
  final regex = RegExp(r'^[a-z_][a-z0-9_]*$');
  return regex.hasMatch(name) && !name.startsWith('_');
}

/// Update .dart_tool/package_config.json to avoid package mismatch
Future<void> updatePackageConfig(String oldName, String newName) async {
  final configFile = File('.dart_tool/package_config.json');
  if (!configFile.existsSync()) return;

  try {
    final jsonContent = jsonDecode(await configFile.readAsString());

    if (jsonContent is Map && jsonContent.containsKey('packages')) {
      final packages = jsonContent['packages'] as List<dynamic>;
      bool updated = false;

      for (final pkg in packages) {
        if (pkg is Map && pkg['rootUri'] == '../' && pkg['name'] == oldName) {
          pkg['name'] =
              newName; // Fixed: was == (comparison) instead of = (assignment)
          updated = true;
        }
      }

      if (updated) {
        await configFile.writeAsString(
          const JsonEncoder.withIndent('  ').convert(jsonContent),
        );
        print('✅ Updated: .dart_tool/package_config.json');
      }
    }
  } catch (e) {
    print('⚠️  Warning: Could not update .dart_tool/package_config.json: $e');
  }
}
