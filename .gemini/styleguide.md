# Noctalia Custom Plugins — Code Review Style Guide

## Framework & Environment

This repository contains QML plugins for the Quickshell framework (Qt6) running
on Wayland. Do not flag Quickshell-specific APIs as errors or suggest Qt5Compat
alternatives — Qt6-only is intentional.

## QML Conventions

- Use `Logger.i/d/w/e("PluginName", "message")` for debug output, never `console.log()`
- IPC parameters are always strings — explicit type conversion (parseInt, toString) is correct
- `property var pluginApi: null` is the standard Quickshell pattern, not a bug
- `Process` + `StdioCollector` is the correct async CLI pattern for this framework
- Use `Quickshell.env("VAR")` for environment variable access instead of shell subprocesses

## JavaScript/QML Style

- 4-space indentation (enforced by qmlformat)
- camelCase for properties and functions
- PascalCase for QML component IDs and types
- Commit messages follow Conventional Commits: feat/fix/chore/i18n/docs(scope): message

## What NOT to flag

- Quickshell imports (qs.Commons, qs.Services.UI) — these are internal framework modules
- `pluginApi?.xyz` optional chaining — pluginApi can legitimately be null at startup
- Auto-generated `registry.json` — never review this file
- Missing build files / package.json / tsconfig — this project has no build step by design
- `Component.onCompleted` and `onXyzChanged` signal handlers — standard Qt/QML patterns

## Security

- Subprocess calls via `Process` must use parameterized command arrays, never `sh -c` with string concatenation
- All user input passed to CLI commands must be validated (UUID format, field whitelists, tag format)
- Read-only task commands must include `rc.hooks=0` to prevent feedback loops with on-exit hooks
- CRUD actions intentionally keep hooks enabled for external notification

## i18n

- All user-visible strings must use `pluginApi.tr("key")` — hardcoded strings in QML are a valid finding
- Translation keys follow the pattern: `component_name.key-with-suffix` (e.g. `panel.filter-placeholder`)
- Placeholders `{var}` must be preserved across all translations
