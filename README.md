# Change Project Name

[![pub package](https://img.shields.io/pub/v/change_project_name.svg)](https://pub.dev/packages/change_project_name)

A powerful CLI tool to rename Flutter/Dart projects and automatically update all package references, imports, and platform-specific configurations.

## Features

- 🔄 **Automatic Renaming**: Updates project name in `pubspec.yaml`
- 📦 **Import Updates**: Finds and updates all package imports in Dart files
- 🛠️ **Platform Support**: Updates Android and iOS bundle identifiers
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
# Simple rename
change-project-name my_new_project

# Using --value flag
change-project-name --value my_new_project

# Interactive mode
change-project-name --interactive
```

### Advanced Options

```bash
# Preview changes without applying them
change-project-name --dry-run my_new_project

# Skip platform-specific updates
change-project-name --skip-platform my_new_project

# Verbose output
change-project-name --verbose my_new_project

# Show help
change-project-name --help
```

### Command Line Options

| Option | Short | Description |
|--------|-------|-------------|
| `--value` | `-v` | Specify the new project name |
| `--interactive` | `-i` | Run in interactive mode |
| `--dry-run` | `-d` | Preview changes without applying |
| `--skip-platform` | | Skip Android/iOS configuration updates |
| `--verbose` | | Show detailed output |
| `--help` | `-h` | Show help message |

## What Gets Updated

- ✅ `pubspec.yaml` - Project name
- ✅ All `.dart` files - Package import statements
- ✅ `.dart_tool/package_config.json` - Package configuration
- ✅ `android/app/build.gradle` - Android application ID
- ✅ `ios/Runner.xcodeproj/project.pbxproj` - iOS bundle identifier

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

🔄 Updating platform configurations...
✅ Updated: android/app/build.gradle
✅ Updated: ios/Runner.xcodeproj/project.pbxproj

🎉 Done! Project successfully renamed to "awesome_app".
📌 2 Dart file(s) updated.

🚀 Next steps:
   1. flutter clean && flutter pub get
   2. Review and update any remaining references manually
   3. Update app display names in platform-specific files if needed
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