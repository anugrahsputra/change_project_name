---
id: CPN-004
title: Support Configuration-Driven Renaming (.rename.json)
status: Done
assignee: []
created_date: '2026-03-04 18:43'
updated_date: '2026-03-06 18:51'
labels: []
dependencies: []
priority: low
ordinal: 500
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Allow users to define renaming rules in a .rename.json file for repeatable and documented rebranding processes.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Define a schema for the .rename.json configuration file.
- [x] #2 Implement logic to read and apply renaming rules from .rename.json.
- [x] #3 Provide a command to generate a template .rename.json file.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Implementation Plan

### 1. Define Configuration Model
- Create `lib/src/config.dart` to handle JSON parsing and represent the renaming configuration.
- **Schema:**
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

### 2. Add CLI Options
- Update `_argParser()` in `bin/change_project_name.dart`:
    - Add `--config <path>`: Path to the configuration file (defaults to `rename.json` or `.rename.json`).
    - Add `--init`: Flag to generate a template configuration file.

### 3. Implement Config Loading & Merging
- In `bin/change_project_name.dart`:
    - If `--init` is set:
        - Generate a documented template `.rename.json`.
        - Print success message and exit.
    - If a config file exists (or is specified):
        - Load and parse the JSON.
        - Merge values with CLI arguments. 
        - **Precedence:** CLI arguments > Config file values > Defaults.

### 4. Integration & Refactoring
- Ensure `main()` correctly passes the merged values to `ProjectRenamer`.
- Validate the configuration file (e.g., check for required fields or invalid formats).

### 5. Testing & Validation
- **Manual Test:** Run `change-project-name --init` and verify the generated file.
- **Manual Test:** Create a `.rename.json` and run the tool without arguments.
- **Manual Test:** Verify that CLI arguments correctly override `.rename.json` values.
- **Automated Test:** Add unit tests in `test/change_project_name_test.dart` for:
    - JSON parsing logic.
    - Argument merging precedence.
<!-- SECTION:PLAN:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented configuration-driven renaming (CPN-004):
- **Configuration Model**: Created `lib/src/config.dart` to handle JSON configuration files (`rename.json` or `.rename.json`).
- **CLI Options**: Added `--config` (or `-c`) to specify a config file and `--init` to generate a template configuration.
- **Config Merging**: Implemented logic to merge configuration values with CLI arguments, where CLI arguments take precedence.
- **Template Generation**: Added a feature to generate a fully documented `rename.json` template.
- **Workflow Improvement**: The tool now automatically picks up `rename.json` or `.rename.json` if they exist in the current directory, allowing for zero-argument execution.
- **Verification**: Verified via unit tests in `test/change_project_name_test.dart` and manual testing on the `example/` project. Verified that CLI arguments correctly override config file values.
<!-- SECTION:FINAL_SUMMARY:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 .rename.json schema is valid and documented
- [x] #2 Configuration file is correctly read and overrides CLI arguments where specified
- [x] #3 Template generation produces a valid .rename.json file with all options documented
<!-- DOD:END -->
