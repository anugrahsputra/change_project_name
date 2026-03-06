---
id: CPN-004
title: Support Configuration-Driven Renaming (.rename.json)
status: In Progress
assignee: []
created_date: '2026-03-04 18:43'
updated_date: '2026-03-06 18:34'
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
- [ ] #1 Define a schema for the .rename.json configuration file.
- [ ] #2 Implement logic to read and apply renaming rules from .rename.json.
- [ ] #3 Provide a command to generate a template .rename.json file.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 .rename.json schema is valid and documented
- [ ] #2 Configuration file is correctly read and overrides CLI arguments where specified
- [ ] #3 Template generation produces a valid .rename.json file with all options documented
<!-- DOD:END -->
