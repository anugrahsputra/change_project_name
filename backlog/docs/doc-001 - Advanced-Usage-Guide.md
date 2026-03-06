---
id: doc-001
title: Advanced Usage Guide
type: other
created_date: '2026-03-06 19:03'
---
# Usage Guide for Change Project Name

This guide provides detailed information on how to use the advanced features of the `change_project_name` CLI tool.

## Table of Contents
1. [Interactive Wizard](#interactive-wizard)
2. [Automatic Backups](#automatic-backups)
3. [Configuration-Driven Renaming (.rename.json)](#configuration-driven-renaming-renamejson)
4. [Custom Search and Replace](#custom-search-and-replace)
5. [Git Integration](#git-integration)

---

## Interactive Wizard

The interactive wizard is the recommended way for new users to rename their projects. It guides you through each step, ensuring you provide all necessary information.

To start the wizard, run:
```bash
change-project-name --interactive
```

The wizard will prompt you for:
- **New project name**: The name used in `pubspec.yaml` and for imports.
- **App Display Name**: The user-friendly name seen on mobile home screens.
- **Package Name / Bundle ID**: The unique identifier (e.g., `com.example.app`).

Finally, it shows a summary of all planned changes and asks for confirmation.

## Automatic Backups

By default, the tool creates a backup of your critical files before making any changes. This is a safety measure to prevent data loss.

- **Backup Location**: A timestamped directory named `.cpn_backup_<timestamp>` is created in your project root.
- **What's Backed Up**: `pubspec.yaml`, `android/`, `ios/`, and all modified `.dart` files.

You can disable backups using:
```bash
change-project-name --no-backup <new_name>
```

## Configuration-Driven Renaming (.rename.json)

For repeatable renames or complex rebranding processes, you can use a configuration file.

### Generating a Template
Run the following command to create a template `rename.json` file:
```bash
change-project-name --init
```

### Configuration Schema
```json
{
  "name": "new_project_name",
  "app_name": "New App Name",
  "package_name": "com.example.new_app",
  "custom_replacements": {
    "OldOrgName": "NewOrgName",
    "OldSecretKey": "NewSecretKey"
  },
  "options": {
    "backup": true,
    "commit": false,
    "refresh": true
  }
}
```

### Using the Config File
The tool automatically detects `rename.json` or `.rename.json` in the current directory. You can also specify a custom path:
```bash
change-project-name --config custom_config.json
```

**Note**: CLI arguments always override values in the configuration file.

## Custom Search and Replace

You can specify additional strings to be replaced across your project (in `.dart` files, `pubspec.yaml`, `README.md`, etc.).

Using the CLI flag:
```bash
change-project-name -r "OldText:NewText" -r "AnotherOld:AnotherNew" <new_name>
```

Or via the `custom_replacements` section in `rename.json`.

## Git Integration

The tool can automatically create a git commit after a successful rename:
```bash
change-project-name --commit <new_name>
```

This ensures you have a clean point to revert to if needed.
