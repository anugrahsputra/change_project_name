---
id: CPN-003
title: 'Improve Safety & User Experience (Wizard, Backups, Custom Replace)'
status: In Progress
assignee: []
created_date: '2026-03-04 18:43'
updated_date: '2026-03-06 18:36'
labels: []
dependencies: []
priority: medium
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Improve user experience and safety by adding an interactive wizard, automatic backups, and flexible custom search/replace options.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Implement an interactive wizard mode for step-by-step renaming.
- [ ] #2 Add automatic backup functionality for modified files.
- [ ] #3 Support custom search and replace pairs via a CLI flag.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Implementation Plan

### 1. Enhanced Interactive Wizard
- **Location:** `bin/change_project_name.dart`
- **Goal:** Provide a step-by-step guided experience.
- **Steps:**
    - Detect current project name from `pubspec.yaml`.
    - Prompt for:
        - New project name (slug): suggest normalized version of input.
        - App display name: suggest a capitalized version of the project name.
        - Package name/Bundle ID: suggest `com.example.<project_name>`.
        - Options: Run clean/get? Create git commit? Create backup?
    - Show a summary of all planned changes.
    - Ask for final confirmation (Y/n).

### 2. Automatic Backup Mechanism
- **Location:** `lib/src/renamer.dart` and `lib/src/utils.dart`
- **Goal:** Prevent data loss if something goes wrong.
- **Details:**
    - Add `--backup` flag (defaults to `true`).
    - Before any modification, create a `.cpn_backup` directory in the project root.
    - Copy critical files before they are modified:
        - `pubspec.yaml`
        - `android/` directory
        - `ios/` directory
        - All `.dart` files that will be modified (based on `findDartFiles` results).
    - Provide a message on where the backup is stored.

### 3. Custom Search and Replace
- **Location:** `bin/change_project_name.dart` and `lib/src/renamer.dart`
- **Goal:** Allow users to specify additional string replacements.
- **Details:**
    - Add `--replace` option to `ArgParser`, allowing multiple occurrences (e.g., `--replace "OldOrg:NewOrg" --replace "OldKey:NewKey"`).
    - In `ProjectRenamer.rename()`, after standard renaming, iterate through the project files and apply these custom replacements.
    - Limit custom replacement to text files to avoid corrupting binary assets.

### 4. Testing & Validation
- **Manual Test:** Run the wizard and verify it correctly collects and applies data.
- **Manual Test:** Verify `.cpn_backup` is created and contains the original files.
- **Manual Test:** Verify custom replacements are applied across the project.
- **Automated Test:** Add unit tests for the backup logic and custom replacement logic in `test/change_project_name_test.dart`.
<!-- SECTION:PLAN:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Interactive wizard correctly prompts and applies choices
- [ ] #2 Automatic backups of files are verified to be recoverable
- [ ] #3 Custom search and replace pairs are applied correctly across project files
<!-- DOD:END -->
