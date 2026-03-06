import 'dart:convert';
import 'dart:io';

/// Recursively finds all Dart files in the given [dir], excluding those in
/// 'build/' and '.dart_tool/' directories.
Future<List<File>> findDartFiles(Directory dir) async {
  final files = <File>[];
  if (!await dir.exists()) return files;

  await for (final entity in dir.list(recursive: true, followLinks: false)) {
    if (entity is File &&
        entity.path.endsWith('.dart') &&
        !entity.path.contains('build/') &&
        !entity.path.contains('.dart_tool/') &&
        !entity.path.contains('.cpn_backup')) {
      files.add(entity);
    }
  }
  return files;
}

/// Copies a directory recursively to a target location.
Future<void> copyDirectory(Directory source, Directory destination) async {
  await destination.create(recursive: true);
  await for (final entity in source.list(recursive: false)) {
    if (entity is Directory) {
      final newDirectory =
          Directory('${destination.path}/${entity.path.split(Platform.pathSeparator).last}');
      await copyDirectory(entity, newDirectory);
    } else if (entity is File) {
      await entity.copy(
        '${destination.path}/${entity.path.split(Platform.pathSeparator).last}',
      );
    }
  }
}

/// Creates a backup of the project's critical files.
Future<String> createBackup(Directory projectDir) async {
  final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
  final backupName = '.cpn_backup_$timestamp';
  final backupDir = Directory('${projectDir.path}/$backupName');

  if (await backupDir.exists()) {
    await backupDir.delete(recursive: true);
  }
  await backupDir.create(recursive: true);

  // Backup pubspec.yaml
  final pubspec = File('${projectDir.path}/pubspec.yaml');
  if (await pubspec.exists()) {
    await pubspec.copy('${backupDir.path}/pubspec.yaml');
  }

  // Backup android/
  final android = Directory('${projectDir.path}/android');
  if (await android.exists()) {
    await copyDirectory(android, Directory('${backupDir.path}/android'));
  }

  // Backup ios/
  final ios = Directory('${projectDir.path}/ios');
  if (await ios.exists()) {
    await copyDirectory(ios, Directory('${backupDir.path}/ios'));
  }

  // Backup lib/ (only .dart files)
  final lib = Directory('${projectDir.path}/lib');
  if (await lib.exists()) {
    final backupLib = Directory('${backupDir.path}/lib');
    await backupLib.create(recursive: true);
    final dartFiles = await findDartFiles(lib);
    for (final file in dartFiles) {
      final relativePath = file.path.replaceFirst(lib.path, '');
      final backupFile = File('${backupLib.path}$relativePath');
      await backupFile.parent.create(recursive: true);
      await file.copy(backupFile.path);
    }
  }

  return backupName;
}

/// Validates a Dart package name according to Dart package naming conventions.
bool isValidPackageName(String name) {
  final regex = RegExp(r'^[a-z][a-z0-9_]*$');
  return regex.hasMatch(name);
}

/// Normalizes a string into a valid Dart package name (lowercase, underscores).
String normalizeName(String name) {
  // Insert underscore before uppercase letters (except the first one)
  final camelCaseRegex = RegExp(r'(?<!^)([A-Z])');
  final withUnderscores = name.trim().replaceAllMapped(
        camelCaseRegex,
        (match) => '_${match.group(1)}',
      );

  return withUnderscores
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}

/// Checks if the directory is a git repository.
Future<bool> isGitRepository(Directory dir) async {
  final gitDir = Directory('${dir.path}/.git');
  if (gitDir.existsSync()) return true;

  try {
    final result = await Process.run(
      'git',
      ['rev-parse', '--is-inside-work-tree'],
      workingDirectory: dir.path,
    );
    return result.exitCode == 0;
  } catch (_) {
    return false;
  }
}

/// Creates a git commit with the given message.
Future<bool> createGitCommit(Directory dir, String message) async {
  try {
    // 1. Stage all changes
    final addResult = await Process.run(
      'git',
      ['add', '.'],
      workingDirectory: dir.path,
    );
    if (addResult.exitCode != 0) return false;

    // 2. Commit
    final commitResult = await Process.run(
      'git',
      ['commit', '-m', message],
      workingDirectory: dir.path,
    );
    return commitResult.exitCode == 0;
  } catch (_) {
    return false;
  }
}

/// Updates the '.dart_tool/package_config.json' file.
Future<void> updatePackageConfig(
  String oldName,
  String newName, {
  bool refresh = true,
}) async {
  final configFile = File('.dart_tool/package_config.json');
  if (!configFile.existsSync()) return;

  try {
    final jsonContent = jsonDecode(await configFile.readAsString());

    if (jsonContent is Map && jsonContent.containsKey('packages')) {
      final packages = jsonContent['packages'] as List<dynamic>;
      bool updated = false;

      for (final pkg in packages) {
        if (pkg is Map && pkg['rootUri'] == '../' && pkg['name'] == oldName) {
          pkg['name'] = newName;
          updated = true;
        }
      }

      if (updated) {
        await configFile.writeAsString(
          const JsonEncoder.withIndent('  ').convert(jsonContent),
        );
        print('✅ Updated: .dart_tool/package_config.json');
        if (refresh) {
          await runPubGet();
        }
      }
    }
  } catch (e) {
    print('⚠️  Warning: Could not update .dart_tool/package_config.json: $e');
  }
}

Future<void> runPubGet() async {
  print('\n🚀 Running flutter clean...');
  final cleanExitCode = await runCommand(['clean']);

  if (cleanExitCode == 0) {
    print('\n🚀 Running flutter pub get...');
    await runCommand(['pub', 'get']);
  }
}

Future<int> runCommand(List<String> args) async {
  print('Running command: flutter ${args.join(' ')}');

  try {
    final process = await Process.start('flutter', args);
    process.stdout.transform(utf8.decoder).listen(stdout.write);
    process.stderr.transform(utf8.decoder).listen(stderr.write);
    final exitCode = await process.exitCode;

    if (exitCode != 0) {
      stderr.writeln('Command failed with exit code: $exitCode');
    } else {
      print('');
    }
    return exitCode;
  } catch (e) {
    stderr.writeln('Failed to run command: flutter ${args.join(' ')}');
    stderr.writeln('Error: $e');
    return -1;
  }
}

/// Extracts the current Android package name from build.gradle or build.gradle.kts
Future<String?> getOldPackageName(Directory projectDir) async {
  final gradleFile = File('${projectDir.path}/android/app/build.gradle');
  final gradleKtsFile = File('${projectDir.path}/android/app/build.gradle.kts');

  File? targetFile;
  if (gradleFile.existsSync()) targetFile = gradleFile;
  if (gradleKtsFile.existsSync()) targetFile = gradleKtsFile;

  if (targetFile == null) return null;

  final content = await targetFile.readAsString();

  // Try to find applicationId or namespace
  // Groovy uses `applicationId "com.example"`
  // Kotlin uses `applicationId = "com.example"`
  final appIdRegex = RegExp(r'applicationId\s*=?\s*["'']([^"'']+)["'']');
  final namespaceRegex = RegExp(r'namespace\s*=?\s*["'']([^"'']+)["'']');

  final appIdMatch = appIdRegex.firstMatch(content);
  if (appIdMatch != null) return appIdMatch.group(1);

  final namespaceMatch = namespaceRegex.firstMatch(content);
  if (namespaceMatch != null) return namespaceMatch.group(1);

  return null;
}

/// Updates the Android package name in all relevant files and renames the directory structure.
Future<void> updateAndroidPackageName(
  Directory projectDir,
  String oldPackageName,
  String newPackageName,
) async {
  // 1. Update build.gradle / build.gradle.kts
  final gradleFiles = [
    File('${projectDir.path}/android/app/build.gradle'),
    File('${projectDir.path}/android/app/build.gradle.kts'),
  ];

  for (final file in gradleFiles) {
    if (file.existsSync()) {
      final content = await file.readAsString();
      final updated = content.replaceAll(oldPackageName, newPackageName);
      await file.writeAsString(updated);
      print('✅ Updated: android/app/${file.path.split('/').last}');
    }
  }

  // 2. Update AndroidManifest.xml
  final manifestFiles = [
    File('${projectDir.path}/android/app/src/main/AndroidManifest.xml'),
    File('${projectDir.path}/android/app/src/debug/AndroidManifest.xml'),
    File('${projectDir.path}/android/app/src/profile/AndroidManifest.xml'),
  ];

  for (final file in manifestFiles) {
    if (file.existsSync()) {
      final content = await file.readAsString();
      // Only replace if it contains the package name (sometimes it's in the manifest tag)
      if (content.contains(oldPackageName)) {
        final updated = content.replaceAll(oldPackageName, newPackageName);
        await file.writeAsString(updated);
        print('✅ Updated: android/app/src/.../${file.path.split('/').last}');
      }
    }
  }

  // 3. Update Kotlin/Java files and rename directories
  final sourceSets = ['main', 'debug', 'profile'];
  final languages = ['kotlin', 'java'];

  for (final sourceSet in sourceSets) {
    for (final lang in languages) {
      final sourceDir =
          Directory('${projectDir.path}/android/app/src/$sourceSet/$lang');
      if (sourceDir.existsSync()) {
        await _processSourceDirectory(
          sourceDir,
          oldPackageName,
          newPackageName,
        );
      }
    }
  }
}

Future<void> _processSourceDirectory(
  Directory sourceDir,
  String oldPackageName,
  String newPackageName,
) async {
  final oldPath = oldPackageName.replaceAll('.', '/');
  final newPath = newPackageName.replaceAll('.', '/');

  final files = sourceDir.listSync(recursive: true).whereType<File>().toList();

  for (final file in files) {
    if (file.path.endsWith('.kt') || file.path.endsWith('.java')) {
      final content = await file.readAsString();
      if (content.contains(oldPackageName)) {
        final updated = content.replaceAll(oldPackageName, newPackageName);
        await file.writeAsString(updated);
      }
    }
  }

  // Now rename the directory structure
  final oldPackageDir = Directory('${sourceDir.path}/$oldPath');
  if (oldPackageDir.existsSync()) {
    final newPackageDir = Directory('${sourceDir.path}/$newPath');
    if (!newPackageDir.existsSync()) {
      newPackageDir.createSync(recursive: true);
    }

    // Move all files and subdirectories
    for (final entity in oldPackageDir.listSync()) {
      final newEntityPath =
          entity.path.replaceFirst(oldPackageDir.path, newPackageDir.path);
      entity.renameSync(newEntityPath);
    }

    // Clean up old empty directories
    _deleteEmptyDirectories(oldPackageDir);
  }
}

void _deleteEmptyDirectories(Directory dir) {
  if (!dir.existsSync()) return;

  final parent = dir.parent;
  if (dir.listSync().isEmpty) {
    dir.deleteSync();
    // Recursively check parent
    if (parent.path.contains('src') && parent.listSync().isEmpty) {
      _deleteEmptyDirectories(parent);
    }
  }
}

/// Updates the Android app display name in AndroidManifest.xml
Future<void> updateAndroidAppName(Directory projectDir, String appName) async {
  final manifestFile =
      File('${projectDir.path}/android/app/src/main/AndroidManifest.xml');
  if (manifestFile.existsSync()) {
    final content = await manifestFile.readAsString();
    final labelRegex = RegExp(r'android:label="([^"]+)"');
    final updated = content.replaceFirst(labelRegex, 'android:label="$appName"');
    await manifestFile.writeAsString(updated);
    print('✅ Updated app name in AndroidManifest.xml');
  }
}

/// Updates the iOS bundle identifier in project.pbxproj
Future<void> updateIOSBundleId(Directory projectDir, String bundleId) async {
  final pbxprojFile =
      File('${projectDir.path}/ios/Runner.xcodeproj/project.pbxproj');
  if (pbxprojFile.existsSync()) {
    final content = await pbxprojFile.readAsString();
    final updated = content.replaceAll(
      RegExp(r'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*[^;]+;'),
      'PRODUCT_BUNDLE_IDENTIFIER = $bundleId;',
    );
    await pbxprojFile.writeAsString(updated);
    print('✅ Updated: ios/Runner.xcodeproj/project.pbxproj');
  }
}

/// Updates the iOS app display name in Info.plist
Future<void> updateIOSAppName(Directory projectDir, String appName) async {
  final infoPlistFile = File('${projectDir.path}/ios/Runner/Info.plist');
  if (infoPlistFile.existsSync()) {
    final content = await infoPlistFile.readAsString();

    // Update CFBundleDisplayName
    final displayNameRegex =
        RegExp(r'<key>CFBundleDisplayName</key>\s*<string>[^<]+</string>');
    var updated = content.replaceFirst(
      displayNameRegex,
      '<key>CFBundleDisplayName</key>\n\t<string>$appName</string>',
    );

    // Also update CFBundleName
    final bundleNameRegex =
        RegExp(r'<key>CFBundleName</key>\s*<string>[^<]+</string>');
    updated = updated.replaceFirst(
      bundleNameRegex,
      '<key>CFBundleName</key>\n\t<string>$appName</string>',
    );

    await infoPlistFile.writeAsString(updated);
    print('✅ Updated: ios/Runner/Info.plist');
  }
}
