# Settings UI Reference

Settings UIs provide user-facing configuration integrated into Noctalia's settings panel
(Settings > Plugins > Your Plugin > Configure).

## Core Structure

```qml
import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root
    property var pluginApi: null
    spacing: Style.marginM

    // Local state copies (edited values before save)
    property string editMessage:
        pluginApi?.pluginSettings?.message ||
        pluginApi?.manifest?.metadata?.defaultSettings?.message || ""
    property bool editEnabled:
        pluginApi?.pluginSettings?.enabled ??
        pluginApi?.manifest?.metadata?.defaultSettings?.enabled ?? true

    // Called automatically when user clicks "Save"
    function saveSettings() {
        pluginApi.pluginSettings.message = root.editMessage
        pluginApi.pluginSettings.enabled = root.editEnabled
        pluginApi.saveSettings()
    }

    // Settings UI widgets...
}
```

## Key Rules

1. **`saveSettings()` is required** — called automatically when user clicks Save
2. **Use local state copies** — allows cancel without applying changes
3. **Fallback chain**: pluginSettings → defaultSettings → hardcoded default

## Available Widgets

### NTextInput

```qml
NTextInput {
    Layout.fillWidth: true
    label: "Display Message"
    description: "Shown in the bar widget"
    placeholderText: "Enter message..."
    text: root.editMessage
    onTextChanged: root.editMessage = text
}
```

### NToggle

```qml
NToggle {
    Layout.fillWidth: true
    label: "Enable Feature"
    description: "Toggle this feature on or off"
    checked: root.editEnabled
    onCheckedChanged: root.editEnabled = checked
}
```

### NCheckbox

```qml
NCheckbox {
    text: "Show notifications"
    checked: root.editNotifications
    onCheckedChanged: root.editNotifications = checked
}
```

### NSlider

```qml
NSlider {
    Layout.fillWidth: true
    from: 0
    to: 100
    value: root.editOpacity
    onValueChanged: root.editOpacity = value
}
```

### NSpinBox

```qml
NSpinBox {
    from: 1
    to: 60
    value: root.editInterval
    onValueChanged: root.editInterval = value
}
```

### NComboBox

```qml
NComboBox {
    Layout.fillWidth: true
    model: ["Compact", "Normal", "Expanded"]
    currentIndex: root.editModeIndex
    onCurrentIndexChanged: root.editModeIndex = currentIndex
}
```

### NColorPicker

```qml
NColorPicker {
    Layout.preferredWidth: Style.sliderWidth
    Layout.preferredHeight: Style.baseWidgetSize
    selectedColor: root.editColor
    onColorSelected: function(color) {
        root.editColor = color
    }
}
```

### NLabel (section headers)

```qml
NLabel {
    label: "Section Title"
    description: "Optional description text"
}
```

### NDivider (visual separator)

```qml
NDivider {}
```

### NButton

```qml
NButton {
    text: "Reset to Defaults"
    onClicked: {
        root.editMessage = pluginApi?.manifest?.metadata?.defaultSettings?.message || ""
    }
}
```

## Layout

- Use `Style.marginM` between sections
- Use `Style.marginS` for grouped controls
- Set `Layout.fillWidth: true` on most controls
- Group related settings with NLabel headers and NDivider separators

## Translation Support

```qml
NTextInput {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.message_label") || "Message"
    description: pluginApi?.tr("settings.message_description") || "Display message"
}
```

## Best Practices

1. Always use local state — never modify pluginSettings directly until save
2. Provide fallbacks from defaultSettings in manifest
3. Add descriptive labels and descriptions
4. Group related settings logically
5. Validate input where necessary
6. Show previews of changes when useful
7. Always null-check pluginApi
