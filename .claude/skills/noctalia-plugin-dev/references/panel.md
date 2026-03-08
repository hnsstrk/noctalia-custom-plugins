# Panel Reference

Panels are full-screen overlay components for detailed interfaces, complex interactions,
and configuration screens.

## Required Properties and Structure

```qml
import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Item {
    id: root
    property var pluginApi: null

    // SmartPanel integration (required)
    readonly property var geometryPlaceholder: panelContainer
    readonly property bool allowAttach: true

    // Preferred dimensions (multiply by uiScaleRatio)
    property real contentPreferredWidth: 680 * Style.uiScaleRatio
    property real contentPreferredHeight: 540 * Style.uiScaleRatio

    anchors.fill: parent

    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: "transparent"

        ColumnLayout {
            anchors {
                fill: parent
                margins: Style.marginL
            }
            spacing: Style.marginL

            // Header
            RowLayout {
                Layout.fillWidth: true
                NText {
                    text: pluginApi?.tr("panel.title") || "My Panel"
                    color: Color.mOnSurface
                    pointSize: Style.fontSizeL
                    font.weight: Font.Bold
                }
                Item { Layout.fillWidth: true }
                NIconButton {
                    icon: "x"
                    onClicked: pluginApi?.closePanel(pluginApi.panelOpenScreen)
                }
            }

            // Content
            NScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                // Scrollable content...
            }
        }
    }
}
```

## Required Properties Explained

| Property | Description |
|----------|-------------|
| `pluginApi` | Plugin API, injected by PluginPanelSlot |
| `geometryPlaceholder` | Container reference for sizing calculations |
| `allowAttach` | Enable panel edge-attachment behavior |
| `contentPreferredWidth` | Preferred width (always multiply by `Style.uiScaleRatio`) |
| `contentPreferredHeight` | Preferred height (always multiply by `Style.uiScaleRatio`) |

## Opening and Closing

### From Bar Widget

```qml
// In BarWidget.qml
onClicked: pluginApi?.openPanel(root.screen, root)   // positions near widget
```

### From Control Center

```qml
onClicked: pluginApi?.togglePanel(screen, this)
```

### From Main.qml via IPC

```qml
IpcHandler {
    target: "plugin:my-plugin"
    function showPanel() {
        pluginApi.withCurrentScreen(screen => {
            pluginApi.openPanel(screen)
        })
    }
}
```

### Closing Programmatically

```qml
// In Panel.qml — use panelOpenScreen (not root.screen!)
pluginApi.closePanel(pluginApi.panelOpenScreen)
```

## Panel Screen Access

In Panel.qml, use `pluginApi.panelOpenScreen` to get the screen the panel is displayed on.
Do NOT use `root.screen` — panels don't have a `screen` property.

## Styling

```qml
// Background colors
Color.mSurface           // Main surface
Color.mSurfaceVariant    // Cards and containers
"transparent"            // Inherit panel background

// Text colors
Color.mOnSurface         // Primary text
Color.mOnSurfaceVariant  // Secondary text
Color.mPrimary           // Accent text

// Spacing
Style.marginL            // Outer margins
Style.marginM            // Between sections
Style.marginS            // Related items
Style.marginXS           // Tight spacing
```

## Settings in Panel

```qml
NTextInput {
    id: messageInput
    Layout.fillWidth: true
    label: pluginApi?.tr("panel.message_label") || "Message"
    text: pluginApi?.pluginSettings?.message || ""
}

NButton {
    text: pluginApi?.tr("panel.save") || "Save"
    onClicked: {
        pluginApi.pluginSettings.message = messageInput.text
        pluginApi.saveSettings()
        ToastService.showNotice("Saved!")
    }
}
```

## Best Practices

1. Always set `contentPreferredWidth/Height` with `Style.uiScaleRatio`
2. Use `panelOpenScreen` (not `root.screen`) for panel operations
3. Use `NScrollView` for scrollable content
4. Provide visual feedback via ToastService
5. Show empty states when no data is available
6. Support keyboard navigation (Escape to close)
7. Clean up resources when panel closes
