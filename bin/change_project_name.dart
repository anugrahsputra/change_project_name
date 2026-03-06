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

  // Load config if exists
  final configPath = argResults['config'] as String?;
  ProjectConfig? config;
  if (configPath != null) {
    config = await ProjectConfig.load(configPath);
  } else {
    // Check for default config files
    if (File('rename.json').existsSync()) {
      config = await ProjectConfig.load('rename.json');
    } else if (File('.rename.json').existsSync()) {
      config = await ProjectConfig.load('.rename.json');
    }
  }

  if (argResults['help'] as bool ||
      (arguments.isEmpty && !argResults['interactive'] && config == null)) {
    _showUsage(parser);
    exit(0);
  }

  if (argResults['init'] as bool) {
    await ProjectConfig.generateTemplate('rename.json');
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
  String? packageName = argResults['package-name'] as String? ?? config?.packageName;
  String? appName = argResults['app-name'] as String? ?? config?.appName;
  final isInteractive = argResults['interactive'] as bool;

  if (argResults['value'] != null) {
    newName = argResults['value'] as String;
  } else if (argResults.rest.isNotEmpty) {
    newName = argResults.rest.first.trim();
  } else if (config?.name != null) {
    newName = config!.name;
  } else if (isInteractive) {
    stdout.write('✏️  Enter NEW project name [leave blank to keep current]: ');
    final input = stdin.readLineSync()?.trim();
    newName = (input == null || input.isEmpty) ? oldName : input;
  }

  if (newName == null || newName.isEmpty) {
    print('❌ New project name cannot be empty!');
    print('Use --value <name>, --interactive, --config <file>, or provide name as argument');
    _showUsage(parser);
    exit(1);
  }

  // Normalize name
  newName = normalizeName(newName);

  if (!isValidPackageName(newName)) {
    print('❌ Invalid project name: "$newName"');
    print(
      '   Project names must be lowercase, can contain underscores and numbers,',
    );
    print(
      '   and must start with a letter or underscore (not numbers or reserved prefixes).',
    );
    print('   Examples: my_app, myapp, my_app_v2');
    exit(1);
  }

  if (isInteractive) {
    // Interactive Wizard for other fields
    final defaultAppName = appName ?? newName.split('_').map((s) => s[0].toUpperCase() + s.substring(1)).join(' ');
    stdout.write('✏️  Enter App Display Name [default: $defaultAppName]: ');
    final appInput = stdin.readLineSync()?.trim();
    appName = (appInput == null || appInput.isEmpty) ? defaultAppName : appInput;

    final defaultPackage = packageName ?? 'com.example.$newName';
    stdout.write('✏️  Enter Package Name / Bundle ID [default: $defaultPackage]: ');
    final pkgInput = stdin.readLineSync()?.trim();
    packageName = (pkgInput == null || pkgInput.isEmpty) ? defaultPackage : pkgInput;

    print('\n📋 Summary of changes:');
    print('   - Project Name: $oldName -> $newName');
    print('   - App Display Name: $appName');
    print('   - Package Name: $packageName');
    print('   - Backup: ${argResults.wasParsed('backup') ? argResults['backup'] : (config?.backup ?? true) ? 'YES' : 'NO'}');
    print('   - Dry Run: ${argResults['dry-run'] ? 'YES' : 'NO'}');
    print('   - Git Commit: ${argResults.wasParsed('commit') ? argResults['commit'] : (config?.commit ?? false) ? 'YES' : 'NO'}');
    print('   - Refresh (clean/get): ${argResults.wasParsed('refresh') ? argResults['refresh'] : (config?.refresh ?? true) ? 'YES' : 'NO'}');

    stdout.write('\n🚀 Proceed with these changes? [Y/n]: ');
    final confirm = stdin.readLineSync()?.trim().toLowerCase();
    if (confirm != null && confirm.isNotEmpty && confirm != 'y' && confirm != 'yes') {
      print('❌ Aborted by user.');
      exit(0);
    }
  }

  // Parse custom replacements
  final customReplacements = <String, String>{};
  // Start with config replacements
  if (config?.customReplacements != null) {
    customReplacements.addAll(config!.customReplacements);
  }
  // CLI replacements override config
  final replaceOptions = argResults['replace'] as List<String>;
  for (final option in replaceOptions) {
    final parts = option.split(':');
    if (parts.length == 2) {
      customReplacements[parts[0]] = parts[1];
    } else {
      print('⚠️  Warning: Invalid replacement format "$option". Use "old:new".');
    }
  }

  final renamer = ProjectRenamer(
    projectDir: currentDir,
    isDryRun: argResults['dry-run'] as bool,
    isVerbose: argResults['verbose'] as bool,
    shouldRefresh: argResults.wasParsed('refresh') ? argResults['refresh'] as bool : (config?.refresh ?? true),
    shouldCommit: argResults.wasParsed('commit') ? argResults['commit'] as bool : (config?.commit ?? false),
    shouldBackup: argResults.wasParsed('backup') ? argResults['backup'] as bool : (config?.backup ?? true),
    customReplacements: customReplacements,
  );


  try {
    await renamer.rename(
      oldName,
      newName,
      newPackageName: packageName,
      newAppName: appName,
    );
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
  print(
    '  change-project-name --package-name com.example.new_app --app-name "My New App"',
  );
}

ArgParser _argParser() {
  return ArgParser()
    ..addOption(
      'config',
      abbr: 'c',
      help: 'Path to configuration file (e.g., rename.json)',
      valueHelp: 'file',
    )
    ..addFlag(
      'init',
      negatable: false,
      help: 'Generate a template configuration file (rename.json)',
    )
    ..addOption(
      'value',
      abbr: 'v',
      help: 'The new project name to set',
      valueHelp: 'project_name',
    )
    ..addOption(
      'package-name',
      abbr: 'p',
      help: 'The new package name (e.g., com.example.app)',
      valueHelp: 'package_name',
    )
    ..addOption(
      'app-name',
      abbr: 'a',
      help: 'The new app display name',
      valueHelp: 'app_name',
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
    )
    ..addFlag(
      'refresh',
      negatable: true,
      help: 'Run "flutter clean" and "flutter pub get" after renaming',
      defaultsTo: true,
    )
    ..addFlag(
      'commit',
      negatable: true,
      help: 'Automatically create a git commit after successful rename',
      defaultsTo: false,
    )
    ..addFlag(
      'backup',
      negatable: true,
      help: 'Create a backup before making any changes',
      defaultsTo: true,
    )
    ..addMultiOption(
      'replace',
      abbr: 'r',
      help: 'Custom search and replace pairs (e.g., "Old:New")',
      valueHelp: 'old:new',
    );
    }