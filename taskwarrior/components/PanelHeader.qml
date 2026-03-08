import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import qs.Services.UI

RowLayout {
    id: root

    property var pluginApi: null
    property var mainInstance: null

    spacing: Style.marginM

    NIcon {
        icon: "clipboard-check"
        pointSize: Style.fontSizeXL
    }

    NText {
        text: pluginApi?.tr("panel.header-title") || "Taskwarrior"
        font.pointSize: Style.fontSizeL
        font.weight: Font.Medium
        color: Color.mOnSurface
    }

    Item {
        Layout.fillWidth: true
    }

    NIconButton {
        icon: "refresh"
        tooltipText: pluginApi?.tr("panel.refresh-tooltip") || "Refresh"
        onClicked: {
            if (root.mainInstance)
                root.mainInstance.refreshAll();
        }
    }

    NIconButton {
        icon: root.mainInstance?.syncInProgress ? "loader" : "cloud-upload"
        tooltipText: (root.mainInstance?.syncInProgress ?? false) ? (pluginApi?.tr("panel.sync-in-progress") || "Syncing...") : (pluginApi?.tr("panel.sync-tooltip") || "Synchronize with server")
        enabled: !(root.mainInstance?.syncInProgress ?? false)
        onClicked: {
            if (root.mainInstance)
                root.mainInstance.syncTasks();
        }
    }

    // Note: If NIconButton does not animate rotation natively,
    // wrap in Item { rotation: syncRotation; RotationAnimation { ... } }

    NIconButton {
        icon: "settings"
        tooltipText: pluginApi?.tr("panel.settings-tooltip") || "Settings"
        onClicked: {
            var screen = pluginApi?.panelOpenScreen;
            if (screen && pluginApi?.manifest)
                BarService.openPluginSettings(screen, pluginApi.manifest);
        }
    }
}
