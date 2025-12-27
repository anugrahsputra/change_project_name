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
        !entity.path.contains('.dart_tool/')) {
      files.add(entity);
    }
  }
  return files;
}

/// Validates a Dart package name according to Dart package naming conventions.
bool isValidPackageName(String name) {
  final regex = RegExp(r'^[a-z][a-z0-9_]*$');
  return regex.hasMatch(name);
}

/// Updates the '.dart_tool/package_config.json' file.
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
          pkg['name'] = newName;
          updated = true;
        }
      }

      if (updated) {
        await configFile.writeAsString(
          const JsonEncoder.withIndent('  ').convert(jsonContent),
        );
        print('✅ Updated: .dart_tool/package_config.json');
        await runPubGet();
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
