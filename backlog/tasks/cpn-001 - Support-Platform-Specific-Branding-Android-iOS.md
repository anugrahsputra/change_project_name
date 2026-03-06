---
id: CPN-001
title: Support Platform-Specific Branding (Android & iOS)
status: In Progress
assignee: []
created_date: '2026-03-04 18:43'
updated_date: '2026-03-06 16:06'
labels: []
dependencies: []
priority: high
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Expand the tool to support platform-specific branding by updating Android package names and iOS bundle identifiers. This includes file content updates and directory renaming.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Identify and update Android package name in AndroidManifest.xml and build.gradle files.
- [ ] #2 Rename the Kotlin/Java directory structure to match the new package name.
- [ ] #3 Update the iOS bundle identifier in Info.plist and project.pbxproj.
- [ ] #4 Allow updating the app display name for both Android and iOS.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Implementation Plan

### 1. Research & Analysis
- [x] Analyze typical Flutter project structure for Android and iOS (using `example` directory).
- [x] Identify key files requiring updates: `build.gradle`, `AndroidManifest.xml`, `MainActivity.kt`, `Info.plist`, `project.pbxproj`.
- [x] Determine current Android package name and iOS bundle identifier from the project.

### 2. Android Rename Logic
- [ ] Create a mechanism to update `namespace` and `applicationId` in `build.gradle` and `build.gradle.kts` files.
- [ ] Update `android:label` in all `AndroidManifest.xml` files to change the app display name.
- [ ] Implement a recursive search and replace for the `package` declaration in Kotlin/Java files.
- [ ] Implement directory structure renaming for Kotlin/Java source sets (e.g., `src/main/kotlin/com/example/app` -> `src/main/kotlin/new/package/name`).

### 3. iOS Rename Logic
- [ ] Update `CFBundleDisplayName` in `Info.plist` to change the app display name.
- [ ] Update all occurrences of `PRODUCT_BUNDLE_IDENTIFIER` in `project.pbxproj`.

### 4. Integration
- [ ] Add `renamePlatformSpecific(String oldPackageName, String newPackageName, String appDisplayName)` to `ProjectRenamer`.
- [ ] Integrate these steps into the main `rename` workflow.
- [ ] Ensure dry-run and verbose modes are fully supported for platform-specific changes.

### 5. Verification & Testing
- [ ] Add unit tests for Android package name and directory renaming.
- [ ] Add unit tests for iOS bundle identifier and display name updates.
- [ ] Verify the changes using the `example` project in a controlled environment.
<!-- SECTION:PLAN:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Android package name updates correctly in AndroidManifest.xml and build.gradle
- [ ] #2 iOS bundle identifier updates correctly in project.pbxproj and Info.plist
- [ ] #3 Platform-specific directory renaming is verified across common folder structures
<!-- DOD:END -->
