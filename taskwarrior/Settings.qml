import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import qs.Services.UI

ColumnLayout {
    id: root

    property var pluginApi: null

    property var cfg: pluginApi?.pluginSettings || ({})
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

    property string valueBarWidgetCounter: cfg.barWidgetCounter ?? defaults.barWidgetCounter
    property bool valueShowActiveIndicator: cfg.showActiveIndicator ?? defaults.showActiveIndicator
    property string valueDefaultProject: cfg.defaultProject ?? defaults.defaultProject
    property string valueDefaultPriority: cfg.defaultPriority ?? defaults.defaultPriority
    property bool valueSyncOnOpen: cfg.syncOnOpen ?? defaults.syncOnOpen

    readonly property var mainInstance: pluginApi?.mainInstance
    readonly property bool hookInstalled: cfg.hookInstalled ?? defaults.hookInstalled

    spacing: Style.marginL

    // === Bar Widget Section ===
    NText {
        text: pluginApi?.tr("settings.section-bar-widget") || "Bar Widget"
        font.pointSize: Style.fontSizeM
        font.weight: Font.Bold
        color: Color.mOnSurface
    }

    NComboBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.counter-type-label") || "Counter type"
        description: pluginApi?.tr("settings.counter-type-description") || "Which count to show in the bar widget"
        currentKey: root.valueBarWidgetCounter
        model: [
            {
                key: "pending",
                name: pluginApi?.tr("settings.counter-pending") || "Pending tasks"
            },
            {
                key: "overdue",
                name: pluginApi?.tr("settings.counter-overdue") || "Overdue tasks"
            }
        ]
        onSelected: function (key) {
            root.valueBarWidgetCounter = key;
        }
    }

    NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.active-indicator-label") || "Active task indicator"
        description: pluginApi?.tr("settings.active-indicator-description") || "Show a colored dot when a task is started"
        checked: root.valueShowActiveIndicator
        onToggled: function (checked) {
            root.valueShowActiveIndicator = checked;
        }
    }

    NDivider {}

    // === Defaults Section ===
    NText {
        text: pluginApi?.tr("settings.section-defaults") || "Defaults"
        font.pointSize: Style.fontSizeM
        font.weight: Font.Bold
        color: Color.mOnSurface
    }

    NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.default-project-label") || "Default project"
        description: pluginApi?.tr("settings.default-project-description") || "Pre-filled project when adding new tasks"
        placeholderText: pluginApi?.tr("settings.default-project-placeholder") || "e.g. work"
        text: root.valueDefaultProject
        onTextChanged: root.valueDefaultProject = text
    }

    NComboBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.default-priority-label") || "Default priority"
        description: pluginApi?.tr("settings.default-priority-description") || "Pre-selected priority when adding new tasks"
        currentKey: root.valueDefaultPriority
        model: [
            {
                key: "",
                name: pluginApi?.tr("settings.priority-none") || "None"
            },
            {
                key: "H",
                name: pluginApi?.tr("settings.priority-high") || "High"
            },
            {
                key: "M",
                name: pluginApi?.tr("settings.priority-medium") || "Medium"
            },
            {
                key: "L",
                name: pluginApi?.tr("settings.priority-low") || "Low"
            }
        ]
        onSelected: function (key) {
            root.valueDefaultPriority = key;
        }
    }

    NDivider {}

    // === Sync Section ===
    NText {
        text: pluginApi?.tr("settings.section-sync") || "Sync"
        font.pointSize: Style.fontSizeM
        font.weight: Font.Bold
        color: Color.mOnSurface
    }

    NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.sync-on-open-label") || "Sync on Panel Open"
        description: pluginApi?.tr("settings.sync-on-open-description") || "Automatically sync when the panel opens"
        checked: root.valueSyncOnOpen
        onToggled: function (checked) {
            root.valueSyncOnOpen = checked;
        }
    }

    NDivider {}

    // === Hook Section ===
    NText {
        text: pluginApi?.tr("settings.section-hook") || "Taskwarrior Hook"
        font.pointSize: Style.fontSizeM
        font.weight: Font.Bold
        color: Color.mOnSurface
    }

    NText {
        Layout.fillWidth: true
        text: pluginApi?.tr("settings.hook-description") || "Install an on-exit hook to automatically refresh the plugin when tasks change via the CLI."
        font.pointSize: Style.fontSizeS
        color: Color.mOnSurfaceVariant
        wrapMode: Text.Wrap
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        NText {
            text: root.hookInstalled ? (pluginApi?.tr("settings.hook-status-installed") || "Hook installed") : (pluginApi?.tr("settings.hook-status-not-installed") || "Hook not installed")
            font.pointSize: Style.fontSizeS
            color: root.hookInstalled ? Color.mPrimary : Color.mOnSurfaceVariant
        }

        Item {
            Layout.fillWidth: true
        }

        NButton {
            text: root.hookInstalled ? (pluginApi?.tr("settings.hook-remove") || "Remove Hook") : (pluginApi?.tr("settings.hook-install") || "Install Hook")
            backgroundColor: root.hookInstalled ? Color.mError : Color.mPrimary
            textColor: root.hookInstalled ? Color.mOnError : Color.mOnPrimary
            onClicked: {
                if (mainInstance) {
                    if (root.hookInstalled)
                        mainInstance.removeHook();
                    else
                        mainInstance.installHook();
                }
            }
        }
    }

    function saveSettings() {
        if (!pluginApi)
            return;
        pluginApi.pluginSettings.barWidgetCounter = root.valueBarWidgetCounter;
        pluginApi.pluginSettings.showActiveIndicator = root.valueShowActiveIndicator;
        pluginApi.pluginSettings.defaultProject = root.valueDefaultProject;
        pluginApi.pluginSettings.defaultPriority = root.valueDefaultPriority;
        pluginApi.pluginSettings.syncOnOpen = root.valueSyncOnOpen;
        pluginApi.saveSettings();
    }
}
