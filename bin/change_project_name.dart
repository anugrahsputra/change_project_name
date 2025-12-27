import 'dart:io';

import 'package:args/args.dart';
import 'package:change_project_name/change_project_name.dart';
import 'package:yaml/yaml.dart';

Future<void> main(List<String> arguments) async {
  final parser = _argParser();

  ArgResults argResults;
  try {
    argResults = parser.parse(arguments);
  } catch (e) {
    print('❌ Error parsing arguments: $e\n');
    _showUsage(parser);
    exit(1);
  }

  if (argResults['help'] as bool ||
      (arguments.isEmpty && !argResults['interactive'])) {
    _showUsage(parser);
    exit(0);
  }

  final currentDir = Directory.current;
  final pubspecFile = File('${currentDir.path}/pubspec.yaml');

  if (!pubspecFile.existsSync()) {
    print(
      '❌ pubspec.yaml not found. Please run this in a Flutter project root.',
    );
    exit(1);
  }

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

  if (argResults['value'] != null) {
    newName = argResults['value'] as String;
  } else if (argResults['interactive'] as bool) {
    stdout.write('✏️  Enter NEW project name: ');
    newName = stdin.readLineSync()?.trim();
  } else {
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

  if (!isValidPackageName(newName)) {
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

  final renamer = ProjectRenamer(
    projectDir: currentDir,
    isDryRun: argResults['dry-run'] as bool,
    isVerbose: argResults['verbose'] as bool,
  );

  try {
    await renamer.rename(oldName, newName);
  } catch (e) {
    print(e);
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
}

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