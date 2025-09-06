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
  // Dart package names must be lowercase, can contain underscores and numbers
  // Must start with a letter or underscore
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

/// Update Android package name in android/app/build.gradle
Future<void> updateAndroidPackageName(String oldName, String newName) async {
  final buildGradle = File('android/app/build.gradle');
  if (!buildGradle.existsSync()) return;

  try {
    final content = await buildGradle.readAsString();
    if (content.contains('applicationId')) {
      // This is a simple approach - in practice you might want more sophisticated parsing
      final updated = content.replaceAll(
        RegExp(r'applicationId\s+"[^"]*"'),
        'applicationId "com.example.$newName"',
      );

      if (updated != content) {
        await buildGradle.writeAsString(updated);
        print('✅ Updated: android/app/build.gradle');
      }
    }
  } catch (e) {
    print('⚠️  Warning: Could not update Android configuration: $e');
  }
}

/// Update iOS bundle identifier in ios/Runner.xcodeproj/project.pbxproj
Future<void> updateIOSBundleId(String oldName, String newName) async {
  final pbxproj = File('ios/Runner.xcodeproj/project.pbxproj');
  if (!pbxproj.existsSync()) return;

  try {
    final content = await pbxproj.readAsString();
    final updated = content.replaceAll(
      RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = [^;]*;'),
      'PRODUCT_BUNDLE_IDENTIFIER = com.example.$newName;',
    );

    if (updated != content) {
      await pbxproj.writeAsString(updated);
      print('✅ Updated: ios/Runner.xcodeproj/project.pbxproj');
    }
  } catch (e) {
    print('⚠️  Warning: Could not update iOS configuration: $e');
  }
}
