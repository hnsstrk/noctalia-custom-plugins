# Plugin API & Services Reference

## pluginApi Object

Injected into every component via `property var pluginApi: null`.

### Read-Only Properties

| Property | Type | Description |
|----------|------|-------------|
| `pluginId` | string | Unique plugin identifier |
| `pluginDir` | string | Absolute path to plugin directory |
| `currentLanguage` | string | Current UI language code (e.g., "en") |
| `translationVersion` | int | Increments on translation reload (reactive binding trigger) |
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

// Style — Font sizes (pt values)
Style.fontSizeXXS       // 8pt
Style.fontSizeXS        // 9pt
Style.fontSizeS         // 10pt
Style.fontSizeM         // 11pt
Style.fontSizeL         // 13pt
Style.fontSizeXL        // 16pt
Style.fontSizeXXL       // 18pt
Style.fontSizeXXXL      // 24pt

// Style — Font weights
Style.fontWeightRegular   // 400
Style.fontWeightMedium    // 500
Style.fontWeightSemiBold  // 600
Style.fontWeightBold      // 700

// Style — Spacing (scaled by Settings.data.general.scaleRatio)
Style.marginXXXS, Style.marginXXS, Style.marginXS
Style.marginS, Style.marginM, Style.marginL, Style.marginXL
// Doubled variants: Style.margin2XXXS .. Style.margin2XL

// Style — Container radii (scaled by Settings.data.general.radiusRatio)
Style.radiusXXXS, Style.radiusXXS, Style.radiusXS
Style.radiusS, Style.radiusM, Style.radiusL

// Style — Input radii (scaled by Settings.data.general.iRadiusRatio)
Style.iRadiusXXXS, Style.iRadiusXXS, Style.iRadiusXS
Style.iRadiusS, Style.iRadiusM, Style.iRadiusL

// Style — Borders
Style.borderS, Style.borderM, Style.borderL

// Style — Opacity
Style.opacityNone, Style.opacityLight, Style.opacityMedium
Style.opacityHeavy, Style.opacityAlmost, Style.opacityFull

// Style — Animation durations (affected by animationSpeed setting)
Style.animationFaster    // 75ms
Style.animationFast      // 150ms
Style.animationNormal    // 300ms
Style.animationSlow      // 450ms
Style.animationSlowest   // 750ms

// Style — Tooltip & pill delays
Style.tooltipDelay       // 300ms
Style.tooltipDelayLong   // 1200ms
Style.pillDelay          // 500ms

// Style — Shadows
Style.shadowOpacity, Style.shadowBlur, Style.shadowBlurMax
Style.shadowHorizontalOffset, Style.shadowVerticalOffset

// Style — Bar sizing
Style.barHeight          // Dynamic based on density + position
Style.capsuleHeight
Style.barFontSize
Style.capsuleColor       // Widget capsule background (with alpha)
Style.capsuleBorderColor // Capsule border color
Style.capsuleBorderWidth // Capsule border width
Style.boxBorderColor     // Box container border

// Style — UI constants
Style.uiScaleRatio       // UI scale factor
Style.sliderWidth        // Standard slider width (200)
Style.baseWidgetSize     // Standard widget size (33)

// Style — Functions
Style.pixelAlignCenter(containerSize, contentSize)  // Pixel-perfect centering
Style.toOdd(n)                                      // Round to nearest odd number
Style.toEven(n)                                     // Round to nearest even number
Style.getBarHeightForScreen(screenName)              // Per-screen bar height
Style.getCapsuleHeightForScreen(screenName)          // Per-screen capsule height
Style.getBarFontSizeForScreen(screenName)            // Per-screen font size
Style.getBarHeightForDensity(density, isVertical)    // Height for given density
Style.getCapsuleHeightForDensity(density, barHeight) // Capsule height for density
Style.getBarFontSizeForDensity(barHeight, capsuleHeight, isVertical)

// Color — Material Design 3 tokens
Color.mPrimary          // Primary accent
Color.mOnPrimary        // Text on primary
Color.mSecondary        // Secondary accent
Color.mOnSecondary      // Text on secondary
Color.mTertiary         // Tertiary accent
Color.mOnTertiary       // Text on tertiary
Color.mError            // Error state
Color.mOnError          // Text on error
Color.mSurface          // Surface background
Color.mOnSurface        // Primary text
Color.mSurfaceVariant   // Card/container background
Color.mOnSurfaceVariant // Secondary text
Color.mOutline          // Outline/border color
Color.mShadow           // Shadow color
Color.mHover            // Hover state background
Color.mOnHover          // Text on hover

// Settings — global Noctalia settings
Settings.data.ui.darkMode
Settings.data.bar.position
Settings.data.ui.fontMain
Settings.getBarPositionForScreen(screenName)

// Logger — structured logging
Logger.i("Tag", "message", value)   // Info (always visible)
Logger.d("Tag", "message", value)   // Debug (only if NOCTALIA_DEBUG=1)
Logger.w("Tag", "message")          // Warning (always visible)
Logger.e("Tag", "message", error)   // Error (always visible)

// Time — time utilities
Time.now                                         // Current Date object
Time.timestamp                                   // Unix timestamp (seconds)
Time.getFormattedTimestamp(date)                  // "YYYYMMDD-HHMMSS" format
Time.formatVagueHumanReadableDuration(seconds)   // "4h 32m" format
Time.formatRelativeTime(date)                    // "5 minutes ago" (i18n-aware)

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
ToastService.showNotice(title, description?, icon?, duration?, actionLabel?, actionCallback?)
ToastService.showWarning(title, description?, duration?, actionLabel?, actionCallback?)
ToastService.showError(title, description?, duration?, actionLabel?, actionCallback?)
// Default durations: notice=3000ms, warning=4000ms, error=6000ms

// TooltipService — hover tooltips
TooltipService.show(anchorItem, "text")
TooltipService.show(anchorItem, "text", direction)
TooltipService.hide()

// PanelService — panel management
PanelService.showContextMenu(contextMenu, anchorItem, screen, targetItem?)
PanelService.closeContextMenu(screen)
PanelService.getPanel(name, screen, fallback?)
PanelService.hasPanel(name)
PanelService.openLauncher(screen)
PanelService.toggleLauncher(screen)
PanelService.closeLauncher(screen)
PanelService.closePanel()

// BarService — bar utilities
BarService.getTooltipDirection(screenName)
BarService.openPluginSettings(screen, manifest)
BarService.lookupWidget(widgetId, screenName?, section?, index?)
BarService.hasWidget(widgetId, section?, screenName?)
BarService.show()
BarService.hide()
BarService.toggleVisibility()
```

### qs.Services.Hardware

```qml
import qs.Services.Hardware

BatteryService.percentage                    // battery level (real)
BatteryService.charging                      // is charging (bool)
BatteryService.icon                          // battery icon name
BrightnessService.brightness                 // current brightness (real)
BrightnessService.setBrightness(value)       // set brightness
```

### qs.Services.Media

```qml
import qs.Services.Media

AudioService.volume                          // current volume (real)
AudioService.setVolume(value)
AudioService.muted                           // is muted (bool)
AudioService.setMuted(bool)
MediaService                                 // media player integration
SpectrumService                              // audio visualization data
```

### qs.Services.Networking

```qml
import qs.Services.Networking

NetworkService.connected                     // is connected (bool)
NetworkService.ssid                          // WiFi name
NetworkService.signalStrength                // signal strength (int)
BluetoothService                             // Bluetooth management
VPNService                                   // VPN connections
```

### qs.Services.System

```qml
import qs.Services.System

NotificationService                          // desktop notifications
SoundService.playSound(path, options?)       // play audio ({repeat, volume})
SoundService.stopSound(path)                 // stop audio
SystemStatService                            // CPU, memory, disk stats
FontService                                  // font management
```

### qs.Services.Power

```qml
import qs.Services.Power

PowerProfileService                          // power profile management
IdleService                                  // idle detection
IdleInhibitorService                         // prevent idle
```

### qs.Services.Compositor

```qml
import qs.Services.Compositor

CompositorService.isHyprland                 // compositor detection
CompositorService.isNiri
CompositorService.isSway
CompositorService.isLabwc
CompositorService.workspaces                 // ListModel of workspaces
CompositorService.windows                    // ListModel of windows
CompositorService.overviewActive             // overview state
```

### qs.Services.Keyboard

```qml
import qs.Services.Keyboard

ClipboardService                             // clipboard access
EmojiService                                 // emoji picker
KeyboardLayoutService                        // keyboard layout switching
LockKeysService                              // caps/num lock state
```

### qs.Services.Location

```qml
import qs.Services.Location

CalendarService                              // calendar events
DarkModeService                              // dark mode scheduling
NightLightService                            // blue light filter
```

### qs.Services.Theming

```qml
import qs.Services.Theming

ColorSchemeService                           // color scheme management
AppThemeService                              // application theming
```

### qs.Services.Control

```qml
import qs.Services.Control

IPCService                                   // IPC management
HooksService                                 // hook system
```

### qs.Widgets

Available UI components (import `qs.Widgets`):

**Text & Display:**

| Widget | Purpose |
|--------|---------|
| `NText` | Text display |
| `NIcon` | Icon display (Tabler icons) |
| `NLabel` | Label with description text |
| `NScrollText` | Auto-scrolling text |
| `NHeader` | Section header |

**Buttons:**

| Widget | Purpose |
|--------|---------|
| `NButton` | Clickable button |
| `NIconButton` | Icon-only button |
| `NIconButtonHot` | Icon button with hot/active state |

**Input Controls:**

| Widget | Purpose |
|--------|---------|
| `NTextInput` | Text input field with label/description |
| `NTextInputButton` | Text input with action button |
| `NSearchableComboBox` | Searchable dropdown selector |
| `NComboBox` | Dropdown selector |
| `NSpinBox` | Numeric spinner |
| `NSlider` | Range slider |
| `NValueSlider` | Slider with value display |
| `NToggle` | Toggle switch with label |
| `NCheckbox` | Checkbox |
| `NRadioButton` | Radio button |
| `NColorPicker` | Color picker |
| `NColorPickerDialog` | Color picker dialog |
| `NColorChoice` | Color selection preset |
| `NColorSlider` | Color channel slider |
| `NFilePicker` | File selection |
| `NKeybindRecorder` | Keyboard shortcut recorder |
| `NInputAction` | Input with action trigger |

**Layout & Containers:**

| Widget | Purpose |
|--------|---------|
| `NDivider` | Visual separator |
| `NScrollView` | Scrollable container |
| `NListView` | List display container |
| `NGridView` | Grid layout container |
| `NTabView` | Tabbed content container |
| `NTabBar` | Tab navigation bar |
| `NTabButton` | Individual tab button |
| `NCollapsible` | Expandable/collapsible section |
| `NBox` | Styled container with optional translucency |

**Data Visualization:**

| Widget | Purpose |
|--------|---------|
| `NCircleStat` | Circular progress indicator |
| `NLinearGauge` | Linear gauge/meter |
| `NGraph` | Data graph (shader-based) |
| `NClock` | Clock display |
| `NBattery` | Battery indicator |
| `NDateTimeTokens` | Date/time token display |

**Effects:**

| Widget | Purpose |
|--------|---------|
| `NDropShadow` | Drop shadow effect |
| `NImageRounded` | Image with rounded corners |
| `NBusyIndicator` | Loading spinner |

**Menus:**

| Widget | Purpose |
|--------|---------|
| `NPopupContextMenu` | Context menu popup |
| `NContextMenu` | Inline context menu |

**Settings:**

| Widget | Purpose |
|--------|---------|
| `NPluginSettingsPopup` | Plugin settings dialog |
| `NSettingsIndicator` | Settings status indicator |
| `NSectionEditor` | Section editing UI |

**Other:**

| Widget | Purpose |
|--------|---------|
| `NIconPicker` | Icon selection |
| `NReorderCheckboxes` | Reorderable checkbox list |
| `NTagFilter` | Tag filter UI |

## Theming

Noctalia supports automatic theming via wallpaper-extracted Material You colors or predefined
schemes (Noctalia, Tokyo Night, etc.). Plugins should always use `Color.m*` tokens instead of
hardcoded colors to respect the user's theme.

Supported theme targets: GTK 3/4, Qt6ct, KColorScheme, Kitty, Foot, Ghostty, Fuzzel, Discord,
Firefox (Pywalfox).
