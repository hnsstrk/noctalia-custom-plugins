# Manifest Reference (manifest.json)

Every plugin requires a `manifest.json` in its root directory.

## Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Unique identifier, must match directory name. Kebab-case, globally unique, immutable after publication. |
| `name` | string | Human-readable display name |
| `version` | string | Semantic version (x.y.z) |
| `author` | string | Author name or organization |
| `description` | string | Brief description (<100 chars) |
| `entryPoints` | object | At least one entry point required |

## Optional Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `minNoctaliaVersion` | string | none | Minimum required Noctalia Shell version |
| `license` | string | none | SPDX license identifier (MIT, GPL-3.0, etc.) |
| `repository` | string | none | Git repository URL |
| `tags` | string[] | [] | Categorization tags (e.g. "Bar", "Panel", "Productivity", "i18n") |

## Entry Points

All entry points are optional, but at least one must be specified:

```json
{
  "entryPoints": {
    "main": "Main.qml",                           // Background logic, IPC
    "barWidget": "BarWidget.qml",                  // Status bar widget
    "desktopWidget": "DesktopWidget.qml",          // Draggable desktop widget
    "desktopWidgetSettings": "DesktopWidgetSettings.qml", // Per-instance desktop widget config
    "controlCenterWidget": "ControlCenterWidget.qml", // Control center button
    "launcherProvider": "LauncherProvider.qml",    // Launcher search/commands
    "panel": "Panel.qml",                          // Overlay panel
    "settings": "Settings.qml"                     // Settings UI
  }
}
```

## Dependencies

```json
{
  "dependencies": {
    "plugins": ["other-plugin-id"]
  }
}
```

Reserved for future use — dependency resolution not yet implemented.

## Metadata

```json
{
  "metadata": {
    "commandPrefix": "myprefix",
    "defaultSettings": {
      "enabled": true,
      "interval": 30,
      "customValue": "hello"
    }
  }
}
```

- `commandPrefix`: Prefix for launcher provider activation (`>myprefix`). Defaults to plugin ID.
- `defaultSettings`: Default values for plugin settings. Supported types: string, number, boolean, object, array.

## Validation Rules

The PluginRegistry enforces:
1. Required fields: `id`, `name`, `version`, `author`, `description`, `entryPoints`
2. Version format: `x.y.z` pattern
3. At least one entry point
4. ID format: lowercase with hyphens

## Complete Example

```json
{
  "id": "my-plugin",
  "name": "My Plugin",
  "version": "1.0.0",
  "minNoctaliaVersion": "3.6.0",
  "author": "Your Name",
  "license": "MIT",
  "repository": "https://github.com/user/noctalia-plugins",
  "description": "Brief description of what the plugin does",
  "tags": ["Bar", "Panel"],
  "entryPoints": {
    "main": "Main.qml",
    "barWidget": "BarWidget.qml",
    "desktopWidget": "DesktopWidget.qml",
    "desktopWidgetSettings": "DesktopWidgetSettings.qml",
    "panel": "Panel.qml",
    "settings": "Settings.qml"
  },
  "dependencies": {
    "plugins": []
  },
  "metadata": {
    "defaultSettings": {
      "enabled": true,
      "customValue": "hello"
    }
  }
}
```
