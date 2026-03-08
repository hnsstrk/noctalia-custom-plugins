# Control Center Widget Reference

Control center widgets are button components in the Control Center panel providing quick access
to plugin functionality.

## Required Properties

```qml
property ShellScreen screen    // Screen where widget is displayed
property var pluginApi: null   // Plugin API (injected by PluginService)
```

## Recommended: NIconButtonHot

The most common widget type — icon button with hot state styling:

```qml
import QtQuick
import Quickshell
import qs.Widgets

NIconButtonHot {
    property ShellScreen screen
    property var pluginApi: null

    icon: "settings"
    tooltipText: pluginApi?.tr("controlCenter.tooltip") || "Open Settings"
    onClicked: pluginApi?.togglePanel(screen, this)
}
```

Passing `this` as second parameter to `togglePanel()` makes the panel open near the button.

## Alternative: NIconButton

Simpler icon button without hot state:

```qml
NIconButton {
    property ShellScreen screen
    property var pluginApi: null

    icon: "refresh"
    tooltip: "Refresh Data"
    onClicked: pluginApi?.mainInstance?.refresh()
}
```

## Custom Widget

For full control over appearance:

```qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

Rectangle {
    id: root
    property ShellScreen screen
    property var pluginApi: null

    implicitWidth: 32
    implicitHeight: 32
    radius: Style.radiusS
    color: mouseArea.containsMouse ? Color.mSurfaceVariant : "transparent"

    NIcon {
        anchors.centerIn: parent
        icon: "star"
        color: Color.mOnSurface
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: pluginApi?.togglePanel(root.screen, root)
    }
}
```

## Manifest Registration

```json
{
  "entryPoints": {
    "controlCenterWidget": "ControlCenterWidget.qml",
    "panel": "Panel.qml"
  }
}
```

## Best Practices

1. Keep it simple — buttons only, no complex UIs
2. Always provide descriptive tooltips
3. Typical pattern: toggle a panel on click
4. Use Tabler icons consistent with Noctalia design
5. Always null-check `pluginApi` before use
6. Support translations for tooltip text
