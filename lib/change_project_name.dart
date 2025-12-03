import 'dart:convert';
import 'dart:io';

/// Recursively finds all Dart files in the given [dir], excluding those in
/// 'build/' and '.dart_tool/' directories.
///
/// - [dir]: The root directory to start the search from.
/// - Returns: A Future that completes with a list of Dart [File]s found.
Future<List<File>> findDartFiles(Directory dir) async {
  // List to store found Dart files.
  final files = <File>[];

  // Iterate over all entities in the directory tree recursively.
  await for (final entity in dir.list(recursive: true, followLinks: false)) {
    // Check if the entity is a file,
    // and its path ends with '.dart',
    // and it is not inside 'build/' or '.dart_tool/' directories.
    if (entity is File &&
        entity.path.endsWith('.dart') &&
        !entity.path.contains('build/') &&
        !entity.path.contains('.dart_tool/')) {
      // Add the Dart file to the result list.
      files.add(entity);
    }
  }

  // Return the list of found Dart files.
  return files;
}

/// Validates a Dart package name according to Dart package naming conventions.
///
/// - [name]: The package name to validate.
/// - Returns: true if the name is valid, false otherwise.
///
/// Rules:
///   - Must start with a lowercase letter.
///   - Can contain lowercase letters, numbers, and underscores.
bool isValidPackageName(String name) {
  final regex = RegExp(r'^[a-z][a-z0-9_]*$');
  return regex.hasMatch(name);
}

/// Updates the '.dart_tool/package_config.json' file to replace the old package
/// name with the new one, avoiding package mismatch issues.
///
/// - [oldName]: The old package name to replace.
/// - [newName]: The new package name to set.
///
/// If the file does not exist, the function returns immediately.
/// If the update is successful, the file is overwritten with the new content.
Future<void> updatePackageConfig(String oldName, String newName) async {
  final configFile = File('.dart_tool/package_config.json');
  if (!configFile.existsSync()) return;

  try {
    // Read and decode the JSON content of the file.
    final jsonContent = jsonDecode(await configFile.readAsString());

    // Check if the JSON is a map and contains the 'packages' key.
    if (jsonContent is Map && jsonContent.containsKey('packages')) {
      final packages = jsonContent['packages'] as List<dynamic>;
      bool updated = false;

      // Iterate over each package entry.
      for (final pkg in packages) {
        if (pkg is Map && pkg['rootUri'] == '../' && pkg['name'] == oldName) {
          pkg['name'] = newName;
          updated = true;
        }
      }

      // If any package was updated, write the updated JSON back to the file.
      if (updated) {
        await configFile.writeAsString(
          const JsonEncoder.withIndent('  ').convert(jsonContent),
        );

        print('✅ Updated: .dart_tool/package_config.json');

        await runPubGet();
      }
    }
  } catch (e) {
    // Print a warning if an error occurs during the update.
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
}
