import 'dart:io';

import 'utils.dart';

class ProjectRenamer {
  final Directory projectDir;
  final bool isDryRun;
  final bool isVerbose;
  final bool shouldRefresh;
  final bool shouldCommit;
  final bool shouldBackup;
  final Map<String, String> customReplacements;

  ProjectRenamer({
    required this.projectDir,
    this.isDryRun = false,
    this.isVerbose = false,
    this.shouldRefresh = true,
    this.shouldCommit = false,
    this.shouldBackup = true,
    this.customReplacements = const {},
  });

  Future<void> rename(
    String oldName,
    String newName, {
    String? newPackageName,
    String? newAppName,
  }) async {
    if (oldName == newName &&
        newPackageName == null &&
        newAppName == null &&
        customReplacements.isEmpty) {
      print('✅ Nothing to change.');
      return;
    }

    print(
      '\n🔄 ${isDryRun ? 'Planning' : 'Starting'} project rename from "$oldName" to "$newName"...\n',
    );

    try {
      // 0. Create backup
      if (!isDryRun && shouldBackup) {
        final backupName = await createBackup(projectDir);
        print('✅ Created project backup: $backupName\n');
      }

      // 1. Update pubspec.yaml
      if (oldName != newName) {
        await _updatePubspec(oldName, newName);
      }

      // 2. Update package imports in Dart files
      if (oldName != newName) {
        await _updateImports(oldName, newName);
      }

      // 3. Update Android specific branding
      await _updateAndroid(oldName, newName, newPackageName, newAppName);

      // 4. Update iOS specific branding
      await _updateIOS(oldName, newName, newPackageName, newAppName);

      // 5. Update .dart_tool/package_config.json if exists
      if (oldName != newName) {
        await _updatePackageConfig(oldName, newName);
      }

      // 5b. Custom replacements
      if (customReplacements.isNotEmpty) {
        await _applyCustomReplacements();
      }

      // 6. Git commit if requested
      if (!isDryRun && shouldCommit) {
        await _handleGitCommit(oldName, newName);
      }

      // Summary
      print(
        '\n🎉 ${isDryRun ? 'Analysis complete!' : 'Done!'} Project ${isDryRun ? 'would be' : 'successfully'} updated.',
      );

      if (isDryRun) {
        print('\n💡 Run without --dry-run to make these changes');
      }
    } catch (e) {
      throw Exception('An error occurred during project rename: $e');
    }
  }

  Future<void> _applyCustomReplacements() async {
    print('\n🔄 ${isDryRun ? 'Analyzing' : 'Applying'} custom replacements...');
    final files = await findDartFiles(projectDir);

    // Also include common config files
    final otherFiles = [
      File('${projectDir.path}/pubspec.yaml'),
      File('${projectDir.path}/README.md'),
      File('${projectDir.path}/CHANGELOG.md'),
    ];

    for (final file in otherFiles) {
      if (file.existsSync()) {
        files.add(file);
      }
    }

    int changedFiles = 0;
    for (final file in files) {
      final content = await file.readAsString();
      String updatedContent = content;
      bool changed = false;

      customReplacements.forEach((oldText, newText) {
        if (updatedContent.contains(oldText)) {
          updatedContent = updatedContent.replaceAll(oldText, newText);
          changed = true;
        }
      });

      if (changed) {
        if (!isDryRun) {
          await file.writeAsString(updatedContent);
        }
        changedFiles++;
        final relativePath = file.path.replaceFirst(projectDir.path, '.');
        print('✅ ${isDryRun ? 'Would update' : 'Updated'}: $relativePath (custom replace)');
      }
    }
    print(
      '📌 $changedFiles file(s) ${isDryRun ? 'would be' : ''} updated with custom replacements.',
    );
  }

  Future<void> _handleGitCommit(String oldName, String newName) async {
    print('\n🔄 Creating git commit...');
    final isRepo = await isGitRepository(projectDir);
    if (!isRepo) {
      print('⚠️  Not a git repository, skipping commit.');
      return;
    }

    final success = await createGitCommit(
      projectDir,
      'chore: rename project from $oldName to $newName',
    );
    if (success) {
      print(
        '✅ Created git commit: "chore: rename project from $oldName to $newName"',
      );
    } else {
      print('⚠️  Failed to create git commit.');
    }
  }

  Future<void> _updateAndroid(
    String oldName,
    String newName,
    String? newPackageName,
    String? newAppName,
  ) async {
    print('\n🔄 ${isDryRun ? 'Analyzing' : 'Updating'} Android configuration...');

    final androidDir = Directory('${projectDir.path}/android');
    if (!androidDir.existsSync()) {
      print('⚠️  Android directory not found, skipping Android updates.');
      return;
    }

    final oldPackageName = await getOldPackageName(projectDir);
    if (oldPackageName == null) {
      print('⚠️  Could not identify old Android package name, skipping.');
    } else {
      final targetPackageName = newPackageName ?? 'com.example.$newName';
      if (oldPackageName != targetPackageName) {
        print(
          '   Package name: $oldPackageName -> $targetPackageName${isDryRun ? ' (would change)' : ''}',
        );
        if (!isDryRun) {
          await updateAndroidPackageName(
            projectDir,
            oldPackageName,
            targetPackageName,
          );
        }
      }
    }

    if (newAppName != null) {
      print(
        '   App name: $newAppName${isDryRun ? ' (would change)' : ''}',
      );
      if (!isDryRun) {
        await updateAndroidAppName(projectDir, newAppName);
      }
    }
  }

  Future<void> _updateIOS(
    String oldName,
    String newName,
    String? newPackageName,
    String? newAppName,
  ) async {
    print('\n🔄 ${isDryRun ? 'Analyzing' : 'Updating'} iOS configuration...');

    final iosDir = Directory('${projectDir.path}/ios');
    if (!iosDir.existsSync()) {
      print('⚠️  iOS directory not found, skipping iOS updates.');
      return;
    }

    final targetBundleId = newPackageName ?? 'com.example.$newName';
    print(
      '   Bundle ID: $targetBundleId${isDryRun ? ' (would change)' : ''}',
    );
    if (!isDryRun) {
      await updateIOSBundleId(projectDir, targetBundleId);
    }

    if (newAppName != null) {
      print(
        '   App name: $newAppName${isDryRun ? ' (would change)' : ''}',
      );
      if (!isDryRun) {
        await updateIOSAppName(projectDir, newAppName);
      }
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
      await updatePackageConfig(oldName, newName, refresh: shouldRefresh);
    } else {
      final configFile = File(
        '${projectDir.path}/.dart_tool/package_config.json',
      );
      if (configFile.existsSync()) {
        print('✅ Would update: .dart_tool/package_config.json');
        if (shouldRefresh) {
          print('   → Would also run flutter clean and pub get');
        }
      }
    }
  }
}
