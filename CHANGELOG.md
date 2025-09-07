# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-09-06

### Added
- Initial release of change_project_name CLI tool
- Automatic renaming of Flutter/Dart project names
- Update all package imports and references
- Support for command-line arguments with `--value` flag
- Interactive mode with `--interactive` flag
- Dry-run mode to preview changes with `--dry-run`
- Platform-specific configuration updates (Android/iOS)
- Comprehensive validation of package names
- Support for skipping platform updates with `--skip-platform`
- Verbose output mode with `--verbose`
- Help documentation with `--help`

### Features
- Recursively finds and updates all Dart files
- Updates pubspec.yaml with new project name
- Updates .dart_tool/package_config.json
- Updates Android bundle identifier
- Updates iOS bundle identifier
- Validates package names according to Dart conventions
- Comprehensive error handling and user feedback

## [1.0.1] - 2025-09-06

### Removed
- Dropped support for `--skip-platform` flag
- Removed automatic iOS bundle identifier updates

## [1.0.2] - 2025-09-07

### Added
- Added example project
- Added support for `.dart_tool/package_config.json` file

### Removed
- Removed support for `--skip-platform` flag