---
id: CPN-002
title: Enhance Workflow & Automation Features
status: To Do
assignee: []
created_date: '2026-03-04 18:43'
labels: []
dependencies: []
priority: medium
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
