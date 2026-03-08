# Bar Widget Reference

Bar widgets appear in the status bar (top, bottom, left, or right). They display information
and provide quick interactions.

## Required Properties

```qml
property var pluginApi: null       // Injected by PluginService
property ShellScreen screen        // Multi-monitor support
property string widgetId: ""       // Unique widget instance ID
property string section: ""       // "left", "center", "right"
```

## Visual Capsule Pattern (recommended architecture)

Use an `Item` root with a centered `Rectangle` for proper click areas and styling:

```qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

Item {
    id: root
    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""

    // Per-screen configuration
    readonly property string screenName: screen?.name ?? ""
    readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
    readonly property bool isBarVertical: barPosition === "left" || barPosition === "right"
    readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
    readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)

    readonly property real contentWidth: content.implicitWidth + Style.marginM * 2
    readonly property real contentHeight: capsuleHeight

    implicitWidth: contentWidth
    implicitHeight: contentHeight

    Rectangle {
        id: visualCapsule
        x: Style.pixelAlignCenter(parent.width, width)
        y: Style.pixelAlignCenter(parent.height, height)
        width: root.contentWidth
        height: root.contentHeight
        color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
        radius: Style.radiusL
        border.color: Style.capsuleBorderColor
        border.width: Style.capsuleBorderWidth

        RowLayout {
            id: content
            anchors.centerIn: parent
            spacing: Style.marginS

            NIcon {
                icon: "heart"
                color: Color.mPrimary
            }
            NText {
                text: "My Widget"
                color: Color.mOnSurface
                pointSize: root.barFontSize
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: pluginApi?.openPanel(root.screen, root)
    }
}
```

## Per-Screen Configuration

Always use per-screen properties for multi-monitor support:

```qml
readonly property string screenName: screen?.name ?? ""
readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)
readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
```

## Vertical Bar Support

For left/right bar positions, swap width/height:

```qml
readonly property real contentWidth: isBarVertical
    ? capsuleHeight
    : layout.implicitWidth + Style.marginM * 2
readonly property real contentHeight: isBarVertical
    ? layout.implicitHeight + Style.marginM * 2
    : capsuleHeight
```

Use separate RowLayout and ColumnLayout for horizontal vs vertical orientation.

## Hover Effects

Always use property binding (not imperative handlers):

```qml
color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
```

## Context Menus

```qml
NPopupContextMenu {
    id: contextMenu
    actions: [
        Action {
            text: "Settings"
            icon.name: "settings"
            onTriggered: {
                contextMenu.close()
                PanelService.closeContextMenu(root.screen)
                BarService.openPluginSettings(root.screen, pluginApi.manifest)
            }
        }
    ]
}

// In MouseArea:
onClicked: function(mouse) {
    if (mouse.button === Qt.RightButton) {
        PanelService.showContextMenu(root.screen, contextMenu, root)
    }
}
```

Always call both `contextMenu.close()` and `PanelService.closeContextMenu(screen)` in handlers.

## Tooltips

```qml
import qs.Services.UI

MouseArea {
    hoverEnabled: true
    onEntered: {
        let direction = BarService.getTooltipDirection(root.screen)
        TooltipService.show(root, "Tooltip text", direction)
    }
    onExited: TooltipService.hide()
}
```

## Opening Panel from Bar Widget

```qml
onClicked: {
    if (pluginApi) {
        pluginApi.openPanel(root.screen, root)  // positions panel near widget
    }
}
```

## Settings Access

```qml
readonly property string message:
    pluginApi?.pluginSettings?.message ||
    pluginApi?.manifest?.metadata?.defaultSettings?.message || ""
```

## Best Practices

1. Always use the visual capsule pattern for extended click areas
2. Use per-screen Style/Settings methods instead of global values
3. Support vertical bar orientation (left/right)
4. Provide hover feedback via property bindings
5. Keep widgets compact — complex UI belongs in panels
6. Use `Style.pixelAlignCenter()` for pixel-perfect centering
7. Avoid expensive operations in bar widgets
