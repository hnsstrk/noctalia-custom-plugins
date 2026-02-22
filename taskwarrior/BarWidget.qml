import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
    id: root

    property var pluginApi: null

    property ShellScreen screen
    property string widgetId: ""
    property string section: ""

    readonly property var mainInstance: pluginApi?.mainInstance
    readonly property var cfg: pluginApi?.pluginSettings || ({})
    readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

    readonly property string screenName: screen ? screen.name : ""
    readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
    readonly property bool isVertical: barPosition === "left" || barPosition === "right"
    readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
    readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)

    readonly property string counterType: cfg.barWidgetCounter ?? defaults.barWidgetCounter
    readonly property bool showActiveIndicator: cfg.showActiveIndicator ?? defaults.showActiveIndicator

    readonly property int pendingCount: mainInstance ? mainInstance.pendingCount : 0
    readonly property int overdueCount: mainInstance ? mainInstance.overdueCount : 0
    readonly property var activeTask: mainInstance ? mainInstance.activeTask : null
    readonly property bool hasOverdue: overdueCount > 0
    readonly property bool hasActive: activeTask !== null

    readonly property string displayCount: {
        if (counterType === "overdue")
            return String(overdueCount);
        return String(pendingCount);
    }

    readonly property color contentColor: {
        if (hasOverdue)
            return Color.mError;
        if (mouseArea.containsMouse)
            return Color.mOnHover;
        return Color.mOnSurface;
    }

    readonly property real contentWidth: root.isVertical ? root.capsuleHeight : horizontalRow.implicitWidth + Style.marginM * 2
    readonly property real contentHeight: root.isVertical ? verticalColumn.implicitHeight + Style.marginM * 2 : root.capsuleHeight

    implicitWidth: contentWidth
    implicitHeight: contentHeight

    Rectangle {
        id: visualCapsule
        x: Style.pixelAlignCenter(parent.width, width)
        y: Style.pixelAlignCenter(parent.height, height)
        width: root.contentWidth
        height: root.contentHeight
        radius: Style.radiusL
        color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
        border.color: Style.capsuleBorderColor
        border.width: Style.capsuleBorderWidth

        Row {
            id: horizontalRow
            anchors.centerIn: parent
            spacing: Style.marginS
            visible: !root.isVertical

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 6
                height: 6
                radius: 3
                color: Color.mPrimary
                visible: root.showActiveIndicator && root.hasActive
            }

            NIcon {
                anchors.verticalCenter: parent.verticalCenter
                icon: "clipboard-check"
                applyUiScale: false
                color: root.contentColor
            }

            NText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.displayCount
                color: root.contentColor
                pointSize: root.barFontSize
                applyUiScale: false
            }

            NText {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.hasOverdue
                text: "(" + root.overdueCount + "!)"
                color: Color.mError
                pointSize: root.barFontSize
                applyUiScale: false
                font.weight: Font.Bold
            }
        }

        Column {
            id: verticalColumn
            anchors.centerIn: parent
            spacing: Style.marginS
            visible: root.isVertical

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 6
                height: 6
                radius: 3
                color: Color.mPrimary
                visible: root.showActiveIndicator && root.hasActive
            }

            NIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                icon: "clipboard-check"
                applyUiScale: false
                color: root.contentColor
            }
        }
    }

    NPopupContextMenu {
        id: contextMenu

        model: {
            var items = [];
            items.push({
                "label": pluginApi?.tr("bar_widget.refresh") || "Refresh",
                "action": "refresh",
                "icon": "refresh"
            });
            if (root.hasActive) {
                items.push({
                    "label": pluginApi?.tr("bar_widget.stop-active") || "Stop active task",
                    "action": "stop-active",
                    "icon": "player-stop"
                });
            }
            items.push({
                "label": pluginApi?.tr("bar_widget.settings") || "Widget Settings",
                "action": "settings",
                "icon": "settings"
            });
            return items;
        }

        onTriggered: function (action) {
            contextMenu.close();
            PanelService.closeContextMenu(screen);

            if (action === "settings") {
                BarService.openPluginSettings(root.screen, pluginApi.manifest);
            } else if (action === "refresh" && mainInstance) {
                mainInstance.refreshAll();
            } else if (action === "stop-active" && mainInstance && root.activeTask) {
                mainInstance.stopTask(root.activeTask.uuid);
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: function (mouse) {
            if (mouse.button === Qt.LeftButton) {
                if (pluginApi) {
                    pluginApi.openPanel(root.screen, root);
                }
            } else if (mouse.button === Qt.RightButton) {
                PanelService.showContextMenu(contextMenu, root, screen);
            }
        }
    }
}
