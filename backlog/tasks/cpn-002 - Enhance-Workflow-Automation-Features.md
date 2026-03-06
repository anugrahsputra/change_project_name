---
id: CPN-002
title: Enhance Workflow & Automation Features
status: In Progress
assignee: []
created_date: '2026-03-04 18:43'
updated_date: '2026-03-06 17:57'
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
- [ ] #1 Add a --refresh flag to run 'flutter clean' and 'flutter pub get' after renaming.
- [ ] #2 Add a --commit flag to automatically create a git commit after a successful rename.
- [ ] #3 Implement smart normalization to convert user input into valid Dart package names.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Implementation Plan

### 1. Input Normalization
- [ ] Implement `normalizeName(String name)` in `lib/src/utils.dart` to convert inputs like "My New App" to "my_new_app".
- [ ] Update `bin/change_project_name.dart` to use `normalizeName` before validation.
- [ ] Ensure `packageName` also undergoes basic normalization if it's meant to be a single identifier.

### 2. Build Refresh Automation (--refresh)
- [ ] Modify `updatePackageConfig` to accept a `bool refresh` parameter.
- [ ] Update `ProjectRenamer` to take a `shouldRefresh` option.
- [ ] Update CLI to add `--refresh` flag (default to `false` or `true` based on preference, currently it's "unconditionally true" in some parts, need to make it consistent).

### 3. Git Integration (--commit)
- [ ] Implement `isGitRepository(Directory dir)` in `lib/src/utils.dart`.
- [ ] Implement `createGitCommit(Directory dir, String message)` using `Process.run`.
- [ ] Update `ProjectRenamer` to handle automatic commits after successful renaming.
- [ ] Update CLI to add `--commit` flag.

### 4. Verification & Testing
- [ ] Add unit tests for `normalizeName`.
- [ ] Add tests for Git integration (mocking or using temp git repos).
- [ ] Verify flags using the `example` project.
<!-- SECTION:PLAN:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 --refresh flag triggers flutter clean and pub get successfully
- [ ] #2 --commit flag creates a git commit with a standardized message format
- [ ] #3 Input normalization is verified with multiple project name formats
<!-- DOD:END -->
