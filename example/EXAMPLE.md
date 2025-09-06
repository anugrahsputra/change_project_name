# Examples

This directory contains usage examples for the `change-project-name` CLI tool.

## Basic Usage

```bash
# Rename project to "my_shitty_app"
change-project-name my_shitty_app
```

## Using Flags

```bash
# Using the --value flag
change-project-name --value my_shitty_app

# Interactive mode
change-project-name --interactive

# Dry run to preview changes
change-project-name --dry-run my_shitty_app

# Skip platform-specific updates
change-project-name --skip-platform my_shitty_app

# Verbose output
change-project-name --verbose my_shitty_app
```

## Shell Script Integration

You can integrate this tool into setup scripts:

```bash
#!/bin/bash
PROJECT_NAME="my_new_app"
change-project-name --value "$PROJECT_NAME"
flutter clean && flutter pub get
```