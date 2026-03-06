# Changelog

All notable changes to this project will be documented in this file.

## [2.0.0] - 2026-03-07

### Features

- **Interactive Wizard**: Added a guided, step-by-step mode for renaming projects.
- **Automatic Backups**: Project files are now automatically backed up before any modifications.
- **Configuration-Driven Renaming**: Support for `rename.json` and `.rename.json` configuration files for repeatable rebranding.
- **Custom Search and Replace**: Support for user-defined string replacements across the project.
- **Template Generation**: Added `--init` flag to generate a template configuration file.

### Bug Fixes

- Fixed an issue where the `--commit` flag was not negatable.
- Improved file discovery to exclude backup directories.

### Refactoring

- Professionalized `CHANGELOG.md` format (removed emojis, standardized headers).
- Updated `cliff.toml` to maintain professional changelog generation.

## [1.1.0] - 2025-12-27

### Features

- Introduce `ProjectRenamer` class for programmatic usage.

### Refactoring

- Modularize codebase: Move logic to `lib/src/` and split utilities.
- Improve CLI argument parsing and error handling.

### Testing

- Add unit tests for package name validation.

## [1.0.7] - 2025-12-03

### Bug Fixes

- Correct newline character and package name validation logic

### Documentation

- Update changelog
- Update changelog for v1.0.7

## [1.0.6] - 2025-10-20

### Documentation

- Update README

### Miscellaneous

- Add publisher

## [1.0.5] - 2025-10-05

### Documentation

- Update CHANGELOG
- Update README

### Miscellaneous

- Bump version

## [1.0.4] - 2025-10-04

### Documentation

- Update cliff.toml

### Miscellaneous

- Bump version to 1.0.4

## [1.0.3] - 2025-09-28

### Documentation

- Add initial CHANGELOG.md for tracking changes

### Miscellaneous

- Update CHANGELOG for version 1.0.2 and enhance documentation
- Update version to 1.0.3 and enhance CHANGELOG with documentation improvements

## [1.0.2] - 2025-09-21

### Features

- Add flutter project example

### Refactoring

- Enhance documentation and improve argument parsing in CLI tool

### Documentation

- Enhance changelog format and add cliff.toml configuration

### Miscellaneous

- Update version to 1.0.2 and enhance CHANGELOG with new features and removals

## [1.0.1] - 2025-09-06

### Refactoring

- Remove unnecessary code

### Documentation

- Update documentation
- Update

### Miscellaneous

- Bump version
