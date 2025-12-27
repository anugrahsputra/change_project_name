import 'dart:io';

import 'utils.dart';

class ProjectRenamer {
  final Directory projectDir;
  final bool isDryRun;
  final bool isVerbose;

  ProjectRenamer({
    required this.projectDir,
    this.isDryRun = false,
    this.isVerbose = false,
  });

  Future<void> rename(String oldName, String newName) async {
    print(
      '\n🔄 ${isDryRun ? 'Planning' : 'Starting'} project rename from "$oldName" to "$newName"...\n',
    );

    try {
      // 1. Update pubspec.yaml
      await _updatePubspec(oldName, newName);

      // 2. Update package imports in Dart files
      await _updateImports(oldName, newName);

      // 3. Update .dart_tool/package_config.json if exists
      await _updatePackageConfig(oldName, newName);

      // Summary
      print(
        '\n🎉 ${isDryRun ? 'Analysis complete!' : 'Done!'} Project ${isDryRun ? 'would be' : 'successfully'} renamed to "$newName".',
      );

      if (isDryRun) {
        print('\n💡 Run without --dry-run to make these changes');
      }
    } catch (e) {
      throw Exception('An error occurred during project rename: $e');
    }
  }

  Future<void> _updatePubspec(String oldName, String newName) async {
    print('🔄 ${isDryRun ? 'Would update' : 'Updating'} pubspec.yaml...');
    final pubspecFile = File('${projectDir.path}/pubspec.yaml');
    if (!pubspecFile.existsSync()) {
      throw Exception('pubspec.yaml not found at ${pubspecFile.path}');
    }

    if (!isDryRun) {
      final content = await pubspecFile.readAsString();
      // Only replace the first occurrence of "name: oldName"
      // to avoid replacing dependencies that might have the same name (unlikely but possible)
      // Ideally we should use a YAML parser/editor but string replacement is robust enough if careful.
      // We look for "name: oldName" specifically.
      final newContent = content.replaceFirst(
        'name: $oldName',
        'name: $newName',
      );
      await pubspecFile.writeAsString(newContent);
    }
    print('✅ ${isDryRun ? 'Would update' : 'Updated'}: pubspec.yaml');
  }

  Future<void> _updateImports(String oldName, String newName) async {
    print('\n🔄 ${isDryRun ? 'Analyzing' : 'Updating'} Dart imports...');

    final files = await findDartFiles(projectDir);
    int changedFiles = 0;

    for (final file in files) {
      final content = await file.readAsString();

      if (content.contains('package:$oldName')) {
        if (!isDryRun) {
          final updated = content.replaceAll(
            'package:$oldName',
            'package:$newName',
          );
          await file.writeAsString(updated);
        }

        changedFiles++;
        final relativePath = file.path.replaceAll(projectDir.path, '.');
        print('✅ ${isDryRun ? 'Would update' : 'Updated'}: $relativePath');

        if (isVerbose) {
          final occurrences = 'package:$oldName'.allMatches(content).length;
          print('   → $occurrences occurrence(s) of "package:$oldName"');
        }
      }
    }
    print(
      '📌 $changedFiles Dart file(s) ${isDryRun ? 'would be' : ''} updated.',
    );
  }

  Future<void> _updatePackageConfig(String oldName, String newName) async {
    if (!isDryRun) {
      await updatePackageConfig(oldName, newName);
    } else {
      final configFile = File(
        '${projectDir.path}/.dart_tool/package_config.json',
      );
      if (configFile.existsSync()) {
        print('✅ Would update: .dart_tool/package_config.json');
      }
    }
  }
}
