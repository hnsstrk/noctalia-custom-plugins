# Plugin API & Services Reference

## pluginApi Object

Injected into every component via `property var pluginApi: null`.

### Read-Only Properties

| Property | Type | Description |
|----------|------|-------------|
| `pluginId` | string | Unique plugin identifier |
| `pluginDir` | string | Absolute path to plugin directory |
| `currentLanguage` | string | Current UI language code (e.g., "en") |
| `manifest` | object | Plugin manifest data |
| `mainInstance` | Item | Reference to Main.qml (null if not provided) |
| `barWidget` | Item | Reference to BarWidget component |
| `desktopWidget` | Item | Reference to DesktopWidget component |
| `controlCenterWidget` | Item | Reference to ControlCenterWidget component |
| `launcherProvider` | Item | Reference to LauncherProvider component |
| `panelOpenScreen` | ShellScreen | Screen the panel is displayed on (Panel.qml only) |

### Read-Write Properties

| Property | Type | Description |
|----------|------|-------------|
| `pluginSettings` | object | User settings (call saveSettings() after modification) |

### Functions

```qml
// Settings
pluginApi.saveSettings()                              // Persist to disk

// Panel control
pluginApi.openPanel(screen, buttonItem?)              // Open panel, returns bool
pluginApi.closePanel(screen)                          // Close panel, returns bool
pluginApi.togglePanel(screen, buttonItem?)             // Toggle panel, returns bool

// Launcher control
pluginApi.openLauncher(screen)                        // Open with plugin prefix
pluginApi.closeLauncher(screen)                       // Close launcher
pluginApi.toggleLauncher(screen)                      // Toggle with prefix

// Translation
pluginApi.tr(key, interpolations?)                    // Translate key
pluginApi.trp(key, count, singular, plural, interp?)  // Plural translation
pluginApi.hasTranslation(key)                         // Check key exists

// Utility
pluginApi.withCurrentScreen(callback)                 // Execute with active screen
```

## Services

### qs.Commons

```qml
import qs.Commons

// Style — UI spacing, sizing, theming
Style.marginXS          // Extra-small spacing
Style.marginS           // Small spacing
Style.marginM           // Medium spacing
Style.marginL           // Large spacing
Style.radiusS           // Small border radius
Style.radiusM           // Medium border radius
Style.radiusL           // Large border radius
Style.fontSizeS         // Small font
Style.fontSizeM         // Medium font
Style.fontSizeL         // Large font
Style.barHeight         // Bar height
Style.capsuleColor      // Widget capsule background
Style.capsuleBorderColor // Capsule border color
Style.capsuleBorderWidth // Capsule border width
Style.uiScaleRatio      // UI scale factor
Style.sliderWidth       // Standard slider width
Style.baseWidgetSize    // Standard widget size
Style.pixelAlignCenter(parentSize, childSize)  // Pixel-perfect centering
Style.getCapsuleHeightForScreen(screenName)    // Per-screen capsule height
Style.getBarFontSizeForScreen(screenName)      // Per-screen font size

// Color — Material Design tokens
Color.mPrimary          // Primary accent
Color.mOnPrimary        // Text on primary
Color.mSurface          // Surface background
Color.mOnSurface        // Primary text
Color.mSurfaceVariant   // Card/container background
Color.mOnSurfaceVariant // Secondary text
Color.mError            // Error state
Color.mHover            // Hover state background

// Settings — global Noctalia settings
Settings.data.ui.darkMode
Settings.data.bar.position
Settings.data.ui.fontMain
Settings.getBarPositionForScreen(screenName)

// Logger — structured logging
Logger.i("Tag", "message", value)   // Info
Logger.d("Tag", "message", value)   // Debug
Logger.w("Tag", "message")          // Warning
Logger.e("Tag", "message", error)   // Error

// I18n — global translations
I18n.tr("common.save")
I18n.langCode

// Keybinds — keyboard utilities
Keybinds.checkKey(event, "escape", Settings)
Keybinds.getKeybindString(event)
Keybinds.getKeybindConflict(keyStr, "action", Settings.data)
```

### qs.Services.UI

```qml
import qs.Services.UI

// ToastService — notifications
ToastService.showNotice("message")
ToastService.showError("message")

// TooltipService — hover tooltips
TooltipService.show(anchorItem, "text")
TooltipService.show(anchorItem, "text", direction)
TooltipService.hide()

// PanelService — panel management
PanelService.openPanel("settings", screen)
PanelService.closePanel("launcher", screen)
PanelService.isPanelOpen("launcher", screen)
PanelService.showContextMenu(screen, contextMenu, anchorItem)
PanelService.closeContextMenu(screen)

// BarService — bar utilities
BarService.getTooltipDirection(screen)
BarService.openPluginSettings(screen, manifest)
```

### qs.Services.System

```qml
import qs.Services.System

// AudioService
AudioService.volume                          // current volume (real)
AudioService.setVolume(value)
AudioService.muted                           // is muted (bool)
AudioService.setMuted(bool)

// BatteryService
BatteryService.percentage                    // battery level (real)
BatteryService.charging                      // is charging (bool)
BatteryService.icon                          // battery icon name

// NetworkService
NetworkService.connected                     // is connected (bool)
NetworkService.ssid                          // WiFi name
NetworkService.signalStrength                // signal strength (int)
```

### qs.Widgets

Available UI components:

| Widget | Purpose |
|--------|---------|
| `NText` | Text display |
| `NIcon` | Icon display (Tabler icons) |
| `NButton` | Clickable button |
| `NIconButton` | Icon-only button |
| `NIconButtonHot` | Icon button with hot state |
| `NTextInput` | Text input field with label/description |
| `NToggle` | Toggle switch with label |
| `NCheckbox` | Checkbox |
| `NSlider` | Range slider |
| `NSpinBox` | Numeric spinner |
| `NComboBox` | Dropdown selector |
| `NColorPicker` | Color picker |
| `NLabel` | Label with description |
| `NDivider` | Visual separator |
| `NScrollView` | Scrollable container |
| `NPopupContextMenu` | Context menu popup |

## Theming

Noctalia supports automatic theming via wallpaper-extracted Material You colors or predefined
schemes (Noctalia, Tokyo Night, etc.). Plugins should always use `Color.m*` tokens instead of
hardcoded colors to respect the user's theme.

Supported theme targets: GTK 3/4, Qt6ct, KColorScheme, Kitty, Foot, Ghostty, Fuzzel, Discord,
Firefox (Pywalfox).
