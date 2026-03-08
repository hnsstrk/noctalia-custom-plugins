# Desktop Widget Reference

Desktop widgets are floating, draggable components on the desktop background with user-adjustable
positioning and scaling.

## Core Structure

Desktop widgets must extend `DraggableDesktopWidget`:

```qml
import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import qs.Modules.DesktopWidgets

DraggableDesktopWidget {
    id: root
    property var pluginApi: null

    implicitWidth: Math.round(200 * widgetScale)
    implicitHeight: Math.round(120 * widgetScale)

    // Widget content...
}
```

## Inherited Properties

From `DraggableDesktopWidget`:

| Property | Type | Description |
|----------|------|-------------|
| `screen` | ShellScreen | Display screen |
| `widgetData` | var | Instance configuration data |
| `widgetIndex` | int | Position in widget list |
| `isDragging` | bool | Currently being dragged (read-only) |
| `isScaling` | bool | Currently being scaled (read-only) |
| `showBackground` | bool | Show default background container |
| `widgetScale` | real | Scale factor (0.5 to 3.0) |

## Dimension-Based Scaling (critical)

**Always use dimension-based scaling, never transform-based.** Multiply all dimension values
by `widgetScale` and use `Math.round()` for pixel-perfect rendering:

```qml
// Dimensions
implicitWidth: Math.round(200 * widgetScale)
implicitHeight: Math.round(120 * widgetScale)

// Spacing
anchors.margins: Math.round(Style.marginL * widgetScale)
spacing: Math.round(Style.marginM * widgetScale)

// Text
pointSize: Math.round(Style.fontSizeM * widgetScale)

// Borders
radius: Math.round(Style.radiusL * widgetScale)

// Icons
Layout.preferredWidth: Math.round(24 * widgetScale)
Layout.preferredHeight: Math.round(24 * widgetScale)
```

**Scale everything**: widget dimensions, font sizes, margins, spacing, border radii,
icon sizes, fixed element sizes.

## Performance — Disable During Interaction

Disable expensive operations during dragging and scaling:

```qml
// Disable layer effects
layer.enabled: !root.isScaling

// Disable animations
Behavior on opacity {
    enabled: !root.isDragging && !root.isScaling
    NumberAnimation { duration: 200 }
}
```

Disable during interaction:
- `layer.enabled` effects
- MultiEffect shadows
- ShaderEffectSource
- Canvas operations
- Complex Loaders
- Animations

## Widget Data Access

```qml
readonly property string myProp:
    (widgetData && widgetData.myProp) ? widgetData.myProp : "default"
```

## Settings Access

```qml
readonly property string setting:
    pluginApi?.pluginSettings?.propertyName || "defaultValue"
```

## Manifest Registration

```json
{
  "entryPoints": {
    "desktopWidget": "DesktopWidget.qml"
  }
}
```

## Best Practices

1. Always extend `DraggableDesktopWidget`
2. Define explicit implicitWidth/implicitHeight
3. Use dimension-based scaling exclusively (multiply by `widgetScale`)
4. Disable expensive effects during `isScaling`/`isDragging`
5. Use `Math.round()` for all scaled dimensions
6. Handle `widgetData` with defensive null checks
7. Use theme-aware `Color.m*` colors
8. Provide fallbacks for all settings
