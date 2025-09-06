import 'dart:io';

import 'package:args/args.dart';
import 'package:change_project_name/change_project_name.dart'
    as change_project_name;
import 'package:yaml/yaml.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'value',
      abbr: 'v',
      help: 'The new project name to set',
      valueHelp: 'project_name',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show this help message',
    )
    ..addFlag(
      'interactive',
      abbr: 'i',
      negatable: false,
      help: 'Run in interactive mode (prompt for project name)',
      defaultsTo: false,
    )
    ..addFlag(
      'dry-run',
      abbr: 'd',
      negatable: false,
      help: 'Show what would be changed without making actual changes',
      defaultsTo: false,
    )
    ..addFlag(
      'skip-platform',
      negatable: false,
      help: 'Skip updating platform-specific files (Android/iOS)',
      defaultsTo: false,
    )
    ..addFlag(
      'verbose',
      negatable: false,
      help: 'Show detailed output',
      defaultsTo: false,
    );

  ArgResults argResults;
  try {
    argResults = parser.parse(arguments);
  } catch (e) {
    print('❌ Error parsing arguments: $e\n');
    _showUsage(parser);
    exit(1);
  }

  // Show help if requested or no arguments provided
  if (argResults['help'] as bool ||
      (arguments.isEmpty && !argResults['interactive'])) {
    _showUsage(parser);
    exit(0);
  }

  final currentDir = Directory.current;
  final pubspecFile = File('${currentDir.path}/pubspec.yaml');

  // Check if we are in a Flutter project
  if (!pubspecFile.existsSync()) {
    print(
      '❌ pubspec.yaml not found. Please run this in a Flutter project root.',
    );
    exit(1);
  }

  // Read pubspec.yaml
  final yamlContent = await pubspecFile.readAsString();
  final yaml = loadYaml(yamlContent);
  final oldName = yaml['name']?.toString();

  if (oldName == null || oldName.isEmpty) {
    print('❌ Could not find "name" in pubspec.yaml');
    exit(1);
  }

  if (argResults['verbose'] as bool) {
    print('📍 Working directory: ${currentDir.path}');
  }

  print('📦 Current project name: $oldName');

  String? newName;

  // Get new name from arguments or interactive input
  if (argResults['value'] != null) {
    newName = argResults['value'] as String;
  } else if (argResults['interactive'] as bool) {
    stdout.write('✏️  Enter NEW project name: ');
    newName = stdin.readLineSync()?.trim();
  } else {
    // If no --value and not --interactive, try positional argument
    if (argResults.rest.isNotEmpty) {
      newName = argResults.rest.first.trim();
    }
  }

  if (newName == null || newName.isEmpty) {
    print('❌ New project name cannot be empty!');
    print('Use --value <name>, --interactive, or provide name as argument');
    _showUsage(parser);
    exit(1);
  }

  // Validate package name
  if (!change_project_name.isValidPackageName(newName)) {
    print('❌ Invalid package name: "$newName"');
    print(
      '   Package names must be lowercase, can contain underscores and numbers,',
    );
    print(
      '   and must start with a letter or underscore (not numbers or reserved prefixes).',
    );
    print('   Examples: my_app, myapp, my_app_v2');
    exit(1);
  }

  if (oldName == newName) {
    print('✅ Project name is already "$newName". Nothing to change.');
    exit(0);
  }

  final isDryRun = argResults['dry-run'] as bool;
  // final skipPlatform = argResults['skip-platform'] as bool;
  final isVerbose = argResults['verbose'] as bool;

  if (isDryRun) {
    print('🔍 DRY RUN MODE - No files will be modified');
  }

  print(
    '\n🔄 ${isDryRun ? 'Planning' : 'Starting'} project rename from "$oldName" to "$newName"...\n',
  );

  try {
    // Update pubspec.yaml
    print('🔄 ${isDryRun ? 'Would update' : 'Updating'} pubspec.yaml...');
    if (!isDryRun) {
      final newPubspecContent = yamlContent.replaceFirst(
        'name: $oldName',
        'name: $newName',
      );
      await pubspecFile.writeAsString(newPubspecContent);
    }
    print('✅ ${isDryRun ? 'Would update' : 'Updated'}: pubspec.yaml');

    // Update package imports
    print('\n🔄 ${isDryRun ? 'Analyzing' : 'Updating'} Dart imports...');
    final files = await change_project_name.findDartFiles(currentDir);
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
        final relativePath = file.path.replaceAll(currentDir.path, '.');
        print('✅ ${isDryRun ? 'Would update' : 'Updated'}: $relativePath');

        if (isVerbose) {
          final occurrences = 'package:$oldName'.allMatches(content).length;
          print('   → $occurrences occurrence(s) of "package:$oldName"');
        }
      }
    }

    // Update .dart_tool/package_config.json if exists
    if (!isDryRun) {
      await change_project_name.updatePackageConfig(oldName, newName);
    } else {
      final configFile = File('.dart_tool/package_config.json');
      if (configFile.existsSync()) {
        print('✅ Would update: .dart_tool/package_config.json');
      }
    }

    print(
      '\n🎉 ${isDryRun ? 'Analysis complete!' : 'Done!'} Project ${isDryRun ? 'would be' : 'successfully'} renamed to "$newName".',
    );
    print(
      '📌 $changedFiles Dart file(s) ${isDryRun ? 'would be' : ''} updated.',
    );

    if (!isDryRun) {
      print('\n🚀 Next steps:');
      print('   1. flutter clean && flutter pub get');
      print('   2. Review and update any remaining references manually');
      print(
        '   3. Update app display names in platform-specific files if needed',
      );
    } else {
      print('\n💡 Run without --dry-run to make these changes');
    }
  } catch (e) {
    print('\n❌ An error occurred during project rename: $e');
    exit(1);
  }
}

void _showUsage(ArgParser parser) {
  print('🔧 Flutter Project Name Changer\n');
  print('Usage: change-project-name [options] [new_name]\n');
  print('Options:');
  print(parser.usage);
  print('\nExamples:');
  print('  change-project-name --value my_new_app');
  print('  change-project-name -v my_new_app');
  print('  change-project-name my_new_app');
  print('  change-project-name --interactive');
  print('  change-project-name --dry-run --value my_new_app');
  print('  change-project-name --skip-platform my_new_app');
}
