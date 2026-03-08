---
name: noctalia-plugin-dev
description: >
  Guide for developing Noctalia Shell plugins with QML/JavaScript and the Quickshell framework.
  Use this skill whenever implementing, modifying, or debugging Noctalia plugins — including
  bar widgets, desktop widgets, control center widgets, launcher providers, panels, settings UIs,
  IPC handlers, or translations. Also use when creating new plugin components, working with
  manifest.json, accessing pluginApi or Noctalia services (ToastService, Logger, PanelService,
  AudioService, etc.), or when the user mentions "Noctalia", "plugin", "BarWidget", "Panel",
  "QML widget", or any Noctalia-specific component type.
---

# Noctalia Plugin Development

This skill guides the development of plugins for Noctalia Shell — a Wayland desktop shell built on
the Quickshell framework (Qt6/QML). Plugins run directly at runtime with no build step, no test
suite, and no linter.

## When to consult reference files

This SKILL.md covers the essential patterns. For detailed component APIs, read the relevant
reference file from `references/`:

| Topic | File | When to read |
|-------|------|-------------|
| manifest.json | `references/manifest.md` | Creating a new plugin or modifying entry points |
| Bar Widget | `references/bar-widget.md` | Building or modifying bar widgets |
| Desktop Widget | `references/desktop-widget.md` | Building desktop widgets with drag/scale support |
| Control Center Widget | `references/control-center-widget.md` | Adding control center buttons |
| Launcher Provider | `references/launcher-provider.md` | Extending the app launcher with search/commands |
| Panel | `references/panel.md` | Building overlay panel UIs |
| Settings UI | `references/settings-ui.md` | Creating plugin settings interfaces |
| Translations | `references/translations.md` | Implementing i18n with tr()/trp() |
| IPC | `references/ipc.md` | Adding IPC command handlers |
| Plugin API & Services | `references/api-services.md` | Using pluginApi, system services, theming |

## Plugin Structure

Every plugin is a top-level directory with a `manifest.json` (required). Standard layout:

```
my-plugin/
├── manifest.json          # Required — plugin metadata and entry points
├── preview.png            # Optional — preview image for plugin store
├── Main.qml               # IPC handlers and background logic
├── BarWidget.qml           # Status bar widget
├── DesktopWidget.qml       # Draggable desktop widget
├── ControlCenterWidget.qml # Control center button
├── LauncherProvider.qml    # Launcher search/command provider
├── Panel.qml               # Full-screen overlay panel
├── Settings.qml            # Settings UI (called from Settings > Plugins)
├── components/             # Reusable sub-components
├── i18n/
│   ├── en.json             # English (required fallback)
│   ├── de.json             # German
│   └── ...
└── settings.json           # Auto-generated persisted settings (never edit)
```

## Essential Patterns

### pluginApi — the central API object

Every component receives `property var pluginApi: null` from the framework. Always null-check:

```qml
// Settings access with fallback chain
readonly property string myValue:
    pluginApi?.pluginSettings?.myValue ??
    pluginApi?.manifest?.metadata?.defaultSettings?.myValue ??
    "default"

// Save settings
pluginApi.pluginSettings.myValue = newValue
pluginApi.saveSettings()

// Panel control
pluginApi.openPanel(screen, anchorItem)   // open near anchorItem
pluginApi.closePanel(screen)
pluginApi.togglePanel(screen, anchorItem)

// Translation
pluginApi.tr("panel.title")
pluginApi.tr("welcome", { name: userName })
pluginApi.trp("items.count", count, "1 item", "{count} items")

// Cross-component access
pluginApi.mainInstance.someMethod()
```

### Imports

```qml
import QtQuick                // Qt6 ONLY — never use Qt5Compat
import QtQuick.Layouts
import Quickshell             // ShellScreen etc.
import Quickshell.Io          // Process, IpcHandler, StdioCollector
import qs.Commons             // Style, Color, Settings, Logger, I18n, Keybinds
import qs.Widgets             // NText, NIcon, NButton, NTextInput, NToggle, etc.
import qs.Services.UI         // ToastService, TooltipService, PanelService, BarService
import qs.Services.System     // AudioService, BatteryService, NetworkService
import qs.Modules.DesktopWidgets  // DraggableDesktopWidget (only for desktop widgets)
```

### Styling (Material Design tokens)

```qml
// Colors
Color.mPrimary, Color.mOnPrimary
Color.mSurface, Color.mOnSurface
Color.mSurfaceVariant, Color.mOnSurfaceVariant
Color.mError, Color.mHover

// Spacing & sizing
Style.marginXS, Style.marginS, Style.marginM, Style.marginL
Style.radiusS, Style.radiusM, Style.radiusL
Style.fontSizeS, Style.fontSizeM, Style.fontSizeL
Style.barHeight, Style.capsuleColor, Style.capsuleBorderColor, Style.capsuleBorderWidth
Style.uiScaleRatio          // multiply by preferred dimensions
Style.sliderWidth, Style.baseWidgetSize

// Per-screen (bar widgets)
Style.getCapsuleHeightForScreen(screenName)
Style.getBarFontSizeForScreen(screenName)
Settings.getBarPositionForScreen(screenName)
```

### Icons

Noctalia uses **Tabler Icons** (6000+ icons). Use via `NIcon` or the `icon` property of
`NIconButton`/`NIconButtonHot`. Icon names in kebab-case: `"clipboard-check"`, `"refresh"`,
`"cloud-upload"`. Browse: https://tabler.io/icons

### Logging

```qml
Logger.i("PluginName", "info message")      // info
Logger.d("PluginName", "debug:", value)      // debug
Logger.w("PluginName", "warning!")           // warning
Logger.e("PluginName", "error:", error)      // error
```

Never use `console.log` — always use Logger.

### Notifications

```qml
import qs.Services.UI
ToastService.showNotice("Operation completed")
ToastService.showError("Something went wrong")
```

### Async CLI execution (Process + StdioCollector)

```qml
import Quickshell.Io

Process {
    id: myProcess
    command: ["task", "export"]      // Always arrays, never sh -c strings
    stdout: StdioCollector {
        onStreamFinished: {
            let data = JSON.parse(text)
            // process data...
        }
    }
    stderr: StdioCollector {}
    onExited: function(exitCode, exitStatus) {
        if (exitCode !== 0) Logger.e("Plugin", "Command failed:", exitCode)
    }
}
// Start: myProcess.command = [...]; myProcess.running = true;
```

### IPC Handler (in Main.qml)

```qml
import Quickshell.Io

IpcHandler {
    target: "plugin:my-plugin-id"    // must match manifest id
    function myCommand(param: string) {
        // IPC params are ALWAYS strings — parse explicitly
        let value = parseInt(param)
    }
}
// Call from shell: qs -c noctalia-shell ipc call plugin:my-plugin-id myCommand "param"
```

## Component Quick Reference

### Bar Widget — required properties

```qml
property var pluginApi: null
property ShellScreen screen
property string widgetId: ""
property string section: ""      // "left", "center", "right"
```

Uses `Item` root with centered `Rectangle` (visual capsule pattern). Must handle hover states
and vertical bar orientation. See `references/bar-widget.md` for full pattern.

### Desktop Widget — extends DraggableDesktopWidget

```qml
import qs.Modules.DesktopWidgets
DraggableDesktopWidget {
    property var pluginApi: null
    implicitWidth: Math.round(200 * widgetScale)
    implicitHeight: Math.round(120 * widgetScale)
}
```

Uses **dimension-based scaling** (multiply all sizes by `widgetScale`), never transform scaling.
Disable expensive effects during `isScaling`/`isDragging`. See `references/desktop-widget.md`.

### Control Center Widget — simple button

```qml
NIconButtonHot {
    property ShellScreen screen
    property var pluginApi: null
    icon: "my-icon"
    tooltipText: "My Plugin"
    onClicked: pluginApi?.togglePanel(screen, this)
}
```

See `references/control-center-widget.md`.

### Panel — overlay interface

```qml
Item {
    property var pluginApi: null
    readonly property var geometryPlaceholder: panelContainer
    readonly property bool allowAttach: true
    property real contentPreferredWidth: 680 * Style.uiScaleRatio
    property real contentPreferredHeight: 540 * Style.uiScaleRatio
    anchors.fill: parent
    Rectangle { id: panelContainer; anchors.fill: parent; color: "transparent" }
}
```

See `references/panel.md`.

### Settings UI — must implement saveSettings()

```qml
ColumnLayout {
    property var pluginApi: null
    property string editValue: pluginApi?.pluginSettings?.myValue || ""
    function saveSettings() {
        pluginApi.pluginSettings.myValue = editValue
        pluginApi.saveSettings()
    }
}
```

Uses local state copies, saved only on explicit save. See `references/settings-ui.md`.

### Launcher Provider — extends launcher search

Requires `pluginApi`, `launcher`, `name` properties. Must implement `handleCommand()`,
`getResults()`, `commands()`, `init()`. See `references/launcher-provider.md`.

## Development Workflow

1. **Create plugin directory** in `~/.config/noctalia/plugins/` (or symlink from dev dir)
2. **Write manifest.json** with at least one entry point
3. **Register** in `~/.config/noctalia/plugins.json` with `"enabled": true`
4. **Develop with hot reload**: `NOCTALIA_DEBUG=1 noctalia-shell`
   - Or click Noctalia logo 8 times in About tab
   - QML + i18n files are watched and reloaded automatically
5. **Format QML**: `/usr/lib/qt6/bin/qmlformat -i <file>.qml`
6. **Debug via Logger** — view output in terminal

## Project-Specific Conventions

This repository (noctalia-custom-plugins) follows these additional rules:

- **Git commits**: `type(scope): message` — types: feat, fix, chore, i18n, docs
- **Version bumps mandatory** for any plugin code change (manifest.json is source of truth)
- **SemVer**: PATCH for bugfixes, MINOR for features, MAJOR for breaking changes
- **Version bump checklist**: manifest.json → README.md plugin table → registry.json
- **Registry**: generate with `node .github/workflows/update-registry.js`
- **Security**: CLI commands as arrays (never `sh -c`), `rc.hooks=0` for read-only task commands,
  UUID validation, field whitelists, debounced IPC
- **i18n keys**: hierarchical (`bar_widget.*`, `panel.*`), suffixes: `-label`, `-description`,
  `-placeholder`, `-tooltip`
- **Qt6 only** — no Qt5Compat imports
