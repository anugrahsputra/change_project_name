---
id: CPN-002
title: Enhance Workflow & Automation Features
status: Done
assignee: []
created_date: '2026-03-04 18:43'
updated_date: '2026-03-06 18:00'
labels: []
dependencies: []
priority: medium
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Improve the renaming workflow by adding automation features like automatic build refreshes, git integration, and input normalization.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Add a --refresh flag to run 'flutter clean' and 'flutter pub get' after renaming.
- [x] #2 Add a --commit flag to automatically create a git commit after a successful rename.
- [x] #3 Implement smart normalization to convert user input into valid Dart package names.
<!-- AC:END -->

## Implementation Plan
Implementation Plan:
--------------------------------------------------
## Implementation Plan

### 1. Input Normalization
- [x] Implement `normalizeName(String name)` in `lib/src/utils.dart` to convert inputs like "My New App" to "my_new_app".
- [x] Update `bin/change_project_name.dart` to use `normalizeName` before validation.
- [x] Ensure `packageName` also undergoes basic normalization if it's meant to be a single identifier.

### 2. Build Refresh Automation (--refresh)
- [x] Modify `updatePackageConfig` to accept a `bool refresh` parameter.
- [x] Update `ProjectRenamer` to take a `shouldRefresh` option.
- [x] Update CLI to add `--refresh` flag (default to `false` or `true` based on preference, currently it's "unconditionally true" in some parts, need to make it consistent).

### 3. Git Integration (--commit)
- [x] Implement `isGitRepository(Directory dir)` in `lib/src/utils.dart`.
- [x] Implement `createGitCommit(Directory dir, String message)` using `Process.run`.
- [x] Update `ProjectRenamer` to handle automatic commits after successful renaming.
- [x] Update CLI to add `--commit` flag.

### 4. Verification & Testing
- [x] Add unit tests for `normalizeName`.
- [x] Add tests for Git integration (mocking or using temp git repos).
- [x] Verify flags using the `example` project.

<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Added --refresh (default on) and --no-refresh flags.

Added --commit flag for automatic git commits.

Implemented smart name normalization for project names.

Added unit tests and verified with example project.
<!-- SECTION:NOTES:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 --refresh flag triggers flutter clean and pub get successfully
- [x] #2 --commit flag creates a git commit with a standardized message format
- [x] #3 Input normalization is verified with multiple project name formats
<!-- DOD:END -->
