# Change Project Name

[![pub package](https://img.shields.io/pub/v/change_project_name.svg)](https://pub.dev/packages/change_project_name)

A powerful CLI tool to rename Flutter/Dart projects and automatically update all package references, and imports.

## New in Version 2.0.0

- 🪄 **Interactive Wizard**: Step-by-step guidance for a complete project rename.
- 🛡️ **Automatic Backups**: Keeps your data safe by backing up critical files before modification.
- 📜 **Configuration-Driven**: Define your renaming rules in a `rename.json` file.
- 🔄 **Custom Search and Replace**: Specify additional strings to be replaced across your project.

## Features

- 🔄 **Automatic Renaming**: Updates project name in `pubspec.yaml`
- 📦 **Import Updates**: Finds and updates all package imports in Dart files
- 📱 **Branding Updates**: Updates App Display Name and Package Name/Bundle ID for Android and iOS
- ✅ **Validation**: Ensures new names follow Dart package naming conventions
- 🔍 **Dry Run**: Preview changes before applying them
- 🎯 **Flexible Input**: Multiple ways to specify the new project name
- 📱 **Smart Detection**: Automatically excludes build directories and tool files

## Installation

Install globally using pub:

```bash
dart pub global activate change_project_name
```

## Usage

### Basic Usage

```bash
# Start the interactive wizard (Recommended)
change-project-name --interactive

# Simple rename
change-project-name my_new_project

# Using --value flag
change-project-name --value my_new_project
```

### Advanced Options

```bash
# Use a configuration file
change-project-name --config my_rename_config.json

# Custom search and replace
change-project-name -r "OldText:NewText" my_new_project

# Disable automatic backups
change-project-name --no-backup my_new_project

# Preview changes without applying them
change-project-name --dry-run my_new_project

# Verbose output
change-project-name --verbose my_new_project

# Show help
change-project-name --help
```

### Configuration File (rename.json)

Generate a template configuration:
```bash
change-project-name --init
```

Example `rename.json`:
```json
{
  "name": "new_project_name",
  "app_name": "New App Name",
  "package_name": "com.example.new_app",
  "custom_replacements": {
    "OldText": "NewText"
  },
  "options": {
    "backup": true,
    "commit": false,
    "refresh": true
  }
}
```
The tool automatically detects `rename.json` or `.rename.json` in the current directory.

### Programmatic Usage

You can also use the core logic in your own Dart scripts:

```dart
import 'dart:io';
import 'package:change_project_name/change_project_name.dart';

void main() async {
  final renamer = ProjectRenamer(
    projectDir: Directory.current,
    isDryRun: false, // Set to true to preview changes
    isVerbose: true,
  );

  try {
    await renamer.rename('old_name', 'new_name');
  } catch (e) {
    print('Error: $e');
  }
}
```

### Command Line Options

| Option          | Short | Description                      |
| --------------- | ----- | -------------------------------- |
| `--value`       | `-v`  | Specify the new project name     |
| `--interactive` | `-i`  | Run in interactive mode          |
| `--dry-run`     | `-d`  | Preview changes without applying |
| `--verbose`     |       | Show detailed output             |
| `--help`        | `-h`  | Show help message                |

## What Gets Updated

- ✅ `pubspec.yaml` - Project name
- ✅ All `.dart` files - Package import statements
- ✅ `.dart_tool/package_config.json` - Package configuration

## Example

```bash
$ cd my_flutter_project
$ change-project-name awesome_app

📦 Current project name: old_project_name
🔄 Starting project rename from "old_project_name" to "awesome_app"...

🔄 Updating pubspec.yaml...
✅ Updated: pubspec.yaml

🔄 Updating Dart imports...
✅ Updated: ./lib/main.dart
✅ Updated: ./lib/src/app.dart
✅ Updated: ./.dart_tool/package_config.json

🎉 Done! Project successfully renamed to "awesome_app".
📌 2 Dart file(s) updated.

```

## Package Name Validation

The tool validates that new project names follow Dart package naming conventions:

- Must be lowercase
- Can contain underscores and numbers
- Must start with a letter or underscore
- Cannot start with numbers

✅ Valid: `my_app`, `myapp`, `my_app_v2`  
❌ Invalid: `MyApp`, `my-app`, `2myapp`

## Requirements

- Dart SDK 2.17.0 or higher
- Must be run from a Flutter/Dart project root (directory containing `pubspec.yaml`)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.