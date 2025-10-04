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
///   - Must start with a lowercase letter or underscore.
///   - Can contain lowercase letters, numbers, and underscores.
///   - Cannot start with an underscore.
bool isValidPackageName(String name) {
  // Regular expression for valid package names.
  final regex = RegExp(r'^[a-z_][a-z0-9_]*$');
  // Check if the name matches the regex and does not start with an underscore.
  return regex.hasMatch(name) && !name.startsWith('_');
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
  // Reference to the package_config.json file.
  final configFile = File('.dart_tool/package_config.json');
  // If the file does not exist, exit early.
  if (!configFile.existsSync()) return;

  try {
    // Read and decode the JSON content of the file.
    final jsonContent = jsonDecode(await configFile.readAsString());

    // Check if the JSON is a map and contains the 'packages' key.
    if (jsonContent is Map && jsonContent.containsKey('packages')) {
      // Get the list of packages from the JSON.
      final packages = jsonContent['packages'] as List<dynamic>;
      // Flag to track if any package was updated.
      bool updated = false;

      // Iterate over each package entry.
      for (final pkg in packages) {
        // Check if the entry is a map, has 'rootUri' == '../', and the old name.
        if (pkg is Map && pkg['rootUri'] == '../' && pkg['name'] == oldName) {
          // Update the package name to the new name.
          pkg['name'] = newName;
          updated = true;
        }
      }

      // If any package was updated, write the updated JSON back to the file.
      if (updated) {
        await configFile.writeAsString(
          const JsonEncoder.withIndent('  ').convert(jsonContent),
        );

        // Print a success message.
        print('✅ Updated: .dart_tool/package_config.json');

        // run flutter clean and flutter pub get
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
    print('/n🚀 Running flutter pub get...');
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
