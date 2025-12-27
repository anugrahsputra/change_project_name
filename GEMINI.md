# Shared Package Agent Documentation

> **READ THIS FIRST**
> This document is the **single source of truth** for any AI agent working on the **Shared** package.
> It defines architectural intent, development constraints, and non-negotiable behavioral rules.

---

## 1. Philosophy & Guidelines

### Core Philosophy

- **Safety First**
  Never risk user data, stability, or backward compatibility.
  When uncertain, stop and ask for clarification.

- **Incremental Progress**
  Break complex tasks into small, verifiable steps.
  Large, speculative changes are forbidden.

- **Clear Intent Over Cleverness**
  Prefer readable, boring, maintainable solutions.
  Clever hacks are a liability.

- **Native Performance Mindset**
  Optimize only when necessary and with evidence.
  Avoid premature optimization.

---

### Eight Honors and Eight Shames

- **Shame** in guessing APIs, **Honor** in careful research
- **Shame** in vague execution, **Honor** in seeking confirmation
- **Shame** in assuming business logic, **Honor** in human verification
- **Shame** in creating new abstractions, **Honor** in reusing existing ones
- **Shame** in skipping validation, **Honor** in proactive testing
- **Shame** in breaking architecture, **Honor** in following specifications
- **Shame** in pretending to understand, **Honor** in honest ignorance
- **Shame** in blind modification, **Honor** in careful refactoring

---

## 2. Quality Standards

### Language & Style

- **English Only**
  All code, comments, documentation, identifiers, and error messages must be written in English.

- **No Unnecessary Comments**
  Do not comment _what_ the code does.
  Comments are allowed **only** to explain _why_ a decision exists.

---

### Dart & Flutter Standards

- **Idiomatic Dart & Flutter**
  Code must follow official Dart and Flutter best practices:
  - Sound null safety
  - No `dynamic` unless explicitly justified
  - Prefer `final` and `const`
  - Avoid force unwrap (`!`) unless logically guaranteed

- **Analyzer Cleanliness**
  Generated code must compile with zero analyzer warnings or errors.

---

### API & Architecture

- **Minimal Public Surface**
  Expose the smallest possible public API.
  Internal helpers, models, and utilities must remain private.

- **Single Responsibility**
  Each file, class, and function must have exactly one responsibility.
  If responsibilities grow, split — do not extend scope.

- **Predictable Structure**
  Project structure must be feature-based and easy to navigate.
  Global state, god objects, and hidden side effects are prohibited.

---

### Performance & Safety

- **Performance-Safe Defaults**
  - No heavy work in `build()`
  - No unnecessary widget rebuilds
  - Dispose all controllers, streams, and subscriptions
  - Avoid synchronous I/O on the UI thread

- **Explicit Error Handling**
  Errors must never be swallowed.
  Fail fast with meaningful, typed exceptions.
  Silent fallbacks and no-op behavior are not allowed.

---

### Platform & Dependencies

- **Platform Awareness**
  Platform-specific behavior must be explicit and isolated.
  Unsupported platforms must fail immediately with clear errors.

- **Dependency Discipline**
  Do not introduce new dependencies unless strictly necessary.
  Prefer standard libraries and existing project dependencies.

---

### Testability & Determinism

- **Test-Aware Design**
  - No hidden state
  - No hard-coded singletons
  - Dependencies must be injectable
  - Logic must be testable without UI

- **Deterministic Behavior**
  Avoid randomness, time-based behavior, or environment-dependent logic
  unless explicitly required.

---

### Hard Prohibitions (Non-Negotiable)

The agent **must not** generate:

- Dead code
- Commented-out code
- TODOs without explicit instruction
- Placeholder or fake implementations
- Over-engineered abstractions
- Speculative features or APIs

---

## 3. Project Identity

- **Name**: Change Project name
- **Purpose**: A CLI tools to rename flutter/darat project.
- **Core Value**: A powerful CLI tool to rename Flutter/Dart projects and automatically update all package references, and imports.

---

## 4. Key Workflows

### Development

1. **Understand**: Read `lib/src/` to know what is already implemented
2. **Implement**:
   - Add functionality to `lib/src/`

3. **Verify**: use dry-run first

## Release

- Versions managed in `pubspec.yaml` and via git tags

---

## 5. Agent Behavioral Constraints

- **No Large Changes by Default**
  The agent must not perform wide-ranging refactors, renames, or architectural changes
  unless explicitly instructed.

- **Ask Before Assumptions**
  If requirements, expected behavior, or side effects are unclear, the agent must stop
  and request clarification.

- **Small, Reviewable Diffs**
  Prefer small, incremental changes that are easy to review and revert.

- **Respect Stability**
  Public APIs and shared infrastructure are assumed to be consumed by multiple projects.
  Breaking changes are forbidden unless explicitly requested.

- **No Silent Behavior Changes**
  Any change that alters runtime behavior must be clearly explained.

---

## 6. Stability Rules

- **Stable Components**
  The following are considered stable and must not be modified lightly:
  - `NetworkClient` abstraction
  - `NetworkClientImpl` behavior and interceptors
  - `LocalStorageManager` contracts
  - Dependency registration in `di.dart`

- **Modification Policy**
  - Additive changes are preferred over modifications
  - Existing behavior must not change silently
  - Refactors must preserve public contracts

---

## 7. Pre-Change Checklist (Agent Self-Review)

Before producing output, the agent must verify:

- [ ] The change is necessary and scoped
- [ ] No public API is broken
- [ ] No new dependency is introduced unnecessarily
- [ ] The code is testable
- [ ] The behavior change (if any) is explicitly explained

### Final Reality Check

If a change:

- Can’t be explained clearly
- Can’t be tested easily
- Or risks breaking consumers

**It doesn’t belong here.**
