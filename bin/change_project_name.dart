import 'dart:io';

import 'package:args/args.dart';
import 'package:change_project_name/change_project_name.dart'
    as change_project_name;
import 'package:yaml/yaml.dart';

/// The main entry point for the project name changer CLI tool.
///
/// This function parses command-line arguments, validates the environment,
/// prompts for or reads the new project name, validates it, and then
/// performs (or simulates, in dry-run mode) the renaming of the project
/// and all relevant Dart import statements.
///
/// Each line is documented to help developers understand the flow and logic.
Future<void> main(List<String> arguments) async {
  /// Create an argument parser with all supported options and flags.
  final parser = _argParser();

  ArgResults argResults;
  try {
    /// Parse the command-line arguments into [argResults].
    argResults = parser.parse(arguments);
  } catch (e) {
    /// If parsing fails, print error and usage, then exit.
    print('❌ Error parsing arguments: $e\n');
    _showUsage(parser);
    exit(1);
  }

  /// Show help if requested or if no arguments provided (unless interactive).
  if (argResults['help'] as bool ||
      (arguments.isEmpty && !argResults['interactive'])) {
    _showUsage(parser);
    exit(0);
  }

  /// Get the current working directory.
  final currentDir = Directory.current;

  /// Reference to the pubspec.yaml file in the current directory.
  final pubspecFile = File('${currentDir.path}/pubspec.yaml');

  /// Check if pubspec.yaml exists to ensure we're in a Flutter project.
  if (!pubspecFile.existsSync()) {
    print(
      '❌ pubspec.yaml not found. Please run this in a Flutter project root.',
    );
    exit(1);
  }

  /// Read the contents of pubspec.yaml as a string.
  final yamlContent = await pubspecFile.readAsString();

  /// Parse the YAML content.
  final yaml = loadYaml(yamlContent);

  /// Extract the current project name from the YAML.
  final oldName = yaml['name']?.toString();

  /// If the project name is missing or empty, print error and exit.
  if (oldName == null || oldName.isEmpty) {
    print('❌ Could not find "name" in pubspec.yaml');
    exit(1);
  }

  /// If verbose flag is set, print the current working directory.
  if (argResults['verbose'] as bool) {
    print('📍 Working directory: ${currentDir.path}');
  }

  /// Print the current project name.
  print('📦 Current project name: $oldName');

  /// Variable to hold the new project name.
  String? newName;

  // Get new name from arguments or interactive input
  if (argResults['value'] != null) {
    /// If --value is provided, use it as the new name.
    newName = argResults['value'] as String;
  } else if (argResults['interactive'] as bool) {
    /// If --interactive is set, prompt the user for the new name.
    stdout.write('✏️  Enter NEW project name: ');
    newName = stdin.readLineSync()?.trim();
  } else {
    // If no --value and not --interactive, try positional argument
    if (argResults.rest.isNotEmpty) {
      /// If a positional argument is provided, use it as the new name.
      newName = argResults.rest.first.trim();
    }
  }

  /// If the new name is missing or empty, print error and exit.
  if (newName == null || newName.isEmpty) {
    print('❌ New project name cannot be empty!');
    print('Use --value <name>, --interactive, or provide name as argument');
    _showUsage(parser);
    exit(1);
  }

  /// Validate the new package name using Dart package naming conventions.
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

  /// If the new name is the same as the old name, print message and exit.
  if (oldName == newName) {
    print('✅ Project name is already "$newName". Nothing to change.');
    exit(0);
  }

  /// Determine if dry-run mode is enabled.
  final isDryRun = argResults['dry-run'] as bool;

  /// Determine if verbose mode is enabled.
  final isVerbose = argResults['verbose'] as bool;

  /// If dry-run, notify the user that no files will be modified.
  if (isDryRun) {
    print('🔍 DRY RUN MODE - No files will be modified');
  }

  /// Print the planned or starting rename operation.
  print(
    '\n🔄 ${isDryRun ? 'Planning' : 'Starting'} project rename from "$oldName" to "$newName"...\n',
  );

  try {
    // Update pubspec.yaml
    /// Print update status for pubspec.yaml.
    print('🔄 ${isDryRun ? 'Would update' : 'Updating'} pubspec.yaml...');
    if (!isDryRun) {
      /// Replace the old name with the new name in pubspec.yaml content.
      final newPubspecContent = yamlContent.replaceFirst(
        'name: $oldName',
        'name: $newName',
      );

      /// Write the updated content back to pubspec.yaml.
      await pubspecFile.writeAsString(newPubspecContent);
    }

    /// Print confirmation of pubspec.yaml update.
    print('✅ ${isDryRun ? 'Would update' : 'Updated'}: pubspec.yaml');

    // Update package imports
    /// Print update status for Dart import statements.
    print('\n🔄 ${isDryRun ? 'Analyzing' : 'Updating'} Dart imports...');

    /// Find all Dart files in the project.
    final files = await change_project_name.findDartFiles(currentDir);

    /// Counter for the number of changed files.
    int changedFiles = 0;

    /// Iterate over each Dart file.
    for (final file in files) {
      /// Read the file content.
      final content = await file.readAsString();

      /// If the file contains an import with the old package name.
      if (content.contains('package:$oldName')) {
        if (!isDryRun) {
          /// Replace all occurrences of the old package name with the new one.
          final updated = content.replaceAll(
            'package:$oldName',
            'package:$newName',
          );

          /// Write the updated content back to the file.
          await file.writeAsString(updated);
        }

        /// Increment the changed files counter.
        changedFiles++;

        /// Get the file path relative to the project root.
        final relativePath = file.path.replaceAll(currentDir.path, '.');

        /// Print confirmation of file update.
        print('✅ ${isDryRun ? 'Would update' : 'Updated'}: $relativePath');

        if (isVerbose) {
          /// Count and print the number of occurrences replaced.
          final occurrences = 'package:$oldName'.allMatches(content).length;
          print('   → $occurrences occurrence(s) of "package:$oldName"');
        }
      }
    }

    // Update .dart_tool/package_config.json if exists
    if (!isDryRun) {
      /// Actually update the package_config.json file if not in dry-run.
      await change_project_name.updatePackageConfig(oldName, newName);
    } else {
      /// In dry-run, just notify if the file exists and would be updated.
      final configFile = File('.dart_tool/package_config.json');
      if (configFile.existsSync()) {
        print('✅ Would update: .dart_tool/package_config.json');
      }
    }

    /// Print summary of the operation.
    print(
      '\n🎉 ${isDryRun ? 'Analysis complete!' : 'Done!'} Project ${isDryRun ? 'would be' : 'successfully'} renamed to "$newName".',
    );
    print(
      '📌 $changedFiles Dart file(s) ${isDryRun ? 'would be' : ''} updated.',
    );

    if (!isDryRun) {
      /// Print next steps for the user after a real rename.
      print('\n🚀 Next steps:');
      print('   1. flutter clean && flutter pub get');
      print('   2. Review and update any remaining references manually');
      print(
        '   3. Update app display names in platform-specific files if needed',
      );
    } else {
      /// Remind user to run without --dry-run to apply changes.
      print('\n💡 Run without --dry-run to make these changes');
    }
  } catch (e) {
    /// Catch and print any errors that occur during the rename process.
    print('\n❌ An error occurred during project rename: $e');
    exit(1);
  }
}

/// Prints usage information and example commands for the CLI tool.
///
/// [parser] is the ArgParser used to generate the options help.
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
}

/// Returns an [ArgParser] configured with all supported options and flags.
///
/// This parser is used to handle command-line arguments for the tool.
ArgParser _argParser() {
  return ArgParser()
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
      'verbose',
      negatable: false,
      help: 'Show detailed output',
      defaultsTo: false,
    );
}
