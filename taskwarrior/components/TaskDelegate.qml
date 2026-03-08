import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "TaskUtils.js" as TaskUtils

Rectangle {
    id: root

    property var pluginApi: null
    property var mainInstance: null

    // Task data properties
    property string taskUuid: ""
    property string taskDescription: ""
    property string taskProject: ""
    property string taskPriority: ""
    property string taskDue: ""
    property string taskStatus: ""
    property string taskTags: ""
    property string taskStart: ""
    property real taskUrgency: 0

    readonly property bool isActive: taskStart !== ""
    readonly property bool isOverdue: TaskUtils.isDueOverdue(taskDue)
    readonly property bool isPending: taskStatus === "pending"
    readonly property bool isHovered: delegateMouseArea.containsMouse

    signal editRequested(string uuid)
    signal deleteRequested(string uuid, string description)

    width: ListView.view ? ListView.view.width : parent.width
    implicitHeight: delegateContent.implicitHeight + Style.marginM * 2
    color: root.isHovered ? Color.mHover : Color.mSurface
    radius: Style.radiusS

    Behavior on implicitHeight {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutCubic
        }
    }

    MouseArea {
        id: delegateMouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    ColumnLayout {
        id: delegateContent
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: Style.marginM
        }
        spacing: Style.marginXS

        // === Row 1: Main content (always visible) ===
        RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            // Priority bar
            Rectangle {
                Layout.preferredWidth: 4
                Layout.preferredHeight: Style.baseWidgetSize * 0.7
                Layout.alignment: Qt.AlignVCenter
                radius: 2
                color: TaskUtils.getPriorityColor(root.taskPriority, Color)
                visible: root.taskPriority !== ""
            }

            // Active indicator dot
            Rectangle {
                Layout.preferredWidth: 8
                Layout.preferredHeight: 8
                Layout.alignment: Qt.AlignVCenter
                radius: 4
                color: Color.mPrimary
                visible: root.isActive
            }

            // Checkbox (complete task)
            Item {
                Layout.preferredWidth: Style.baseWidgetSize * 0.7
                Layout.preferredHeight: Style.baseWidgetSize * 0.7
                visible: root.isPending

                Rectangle {
                    anchors.fill: parent
                    radius: Style.iRadiusXS
                    color: Color.mSurface
                    border.color: Color.mOutline
                    border.width: Style.borderS

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.mainInstance)
                                root.mainInstance.completeTask(root.taskUuid);
                        }
                    }
                }
            }

            // Description
            NText {
                Layout.fillWidth: true
                text: root.taskDescription
                color: root.isOverdue ? Color.mError : Color.mOnSurface
                font.pointSize: Style.fontSizeS
                font.weight: root.isActive ? Font.Bold : Font.Normal
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            // Compact: project + tags inline (hidden on hover)
            NText {
                visible: !root.isHovered && (root.taskProject !== "" || root.taskTags !== "")
                text: {
                    var parts = [];
                    if (root.taskProject !== "")
                        parts.push(root.taskProject);
                    if (root.taskTags !== "")
                        parts.push(root.taskTags);
                    return parts.join(" \u00b7 ");
                }
                font.pointSize: Style.fontSizeXS
                color: Color.mOnSurfaceVariant
                elide: Text.ElideRight
                Layout.maximumWidth: 200 * Style.uiScaleRatio
            }

            // Priority badge
            Rectangle {
                visible: root.taskPriority !== ""
                Layout.preferredWidth: prioBadgeText.implicitWidth + Style.marginS * 2
                Layout.preferredHeight: Style.fontSizeS * 2
                radius: Style.radiusS
                color: TaskUtils.getPriorityColor(root.taskPriority, Color)
                opacity: 0.8

                NText {
                    id: prioBadgeText
                    anchors.centerIn: parent
                    text: root.taskPriority
                    font.pointSize: Style.fontSizeXS
                    font.weight: Font.Bold
                    color: Color.mOnPrimary
                }
            }

            // Due date badge
            Rectangle {
                visible: root.taskDue !== ""
                Layout.preferredWidth: dueBadgeRow.implicitWidth + Style.marginS * 2
                Layout.preferredHeight: Style.fontSizeS * 2
                radius: Style.radiusS
                color: root.isOverdue ? Color.mError : Color.mSurfaceVariant

                Row {
                    id: dueBadgeRow
                    anchors.centerIn: parent
                    spacing: Style.marginXS

                    NIcon {
                        icon: "calendar"
                        color: root.isOverdue ? Color.mOnError : Color.mOnSurfaceVariant
                        anchors.verticalCenter: parent.verticalCenter
                        pointSize: Style.fontSizeXS
                    }

                    NText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: TaskUtils.formatDueDate(root.taskDue, root.pluginApi)
                        font.pointSize: Style.fontSizeXS
                        color: root.isOverdue ? Color.mOnError : Color.mOnSurfaceVariant
                    }
                }
            }
        }

        // === Row 2: Project + Tags (visible on hover) ===
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Style.marginM
            spacing: Style.marginXS
            visible: root.isHovered && (root.taskProject !== "" || root.taskTags !== "")

            NText {
                visible: root.taskProject !== ""
                text: root.taskProject
                font.pointSize: Style.fontSizeXS
                color: Color.mOnSurfaceVariant
                font.italic: true
            }

            NText {
                visible: root.taskProject !== "" && root.taskTags !== ""
                text: "\u00b7"
                font.pointSize: Style.fontSizeXS
                color: Color.mOnSurfaceVariant
            }

            NText {
                visible: root.taskTags !== ""
                text: root.taskTags
                font.pointSize: Style.fontSizeXS
                color: Color.mOnSurfaceVariant
            }

            Item {
                Layout.fillWidth: true
            }
        }

        // === Row 3: Action buttons (visible on hover) ===
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Style.marginM
            spacing: Style.marginS
            visible: root.isHovered

            Item {
                Layout.fillWidth: true
            }

            NButton {
                visible: root.isPending
                text: root.isActive ? (pluginApi?.tr("panel.action-stop") || "Stop") : (pluginApi?.tr("panel.action-start") || "Start")
                icon: root.isActive ? "player-stop" : "player-play"
                fontSize: Style.fontSizeXS
                onClicked: {
                    if (root.mainInstance) {
                        if (root.isActive)
                            root.mainInstance.stopTask(root.taskUuid);
                        else
                            root.mainInstance.startTask(root.taskUuid);
                    }
                }
            }

            NButton {
                text: pluginApi?.tr("panel.action-edit") || "Edit"
                icon: "pencil"
                fontSize: Style.fontSizeXS
                onClicked: root.editRequested(root.taskUuid)
            }

            NButton {
                text: pluginApi?.tr("panel.action-delete") || "Delete"
                icon: "trash"
                fontSize: Style.fontSizeXS
                textColor: Color.mError
                onClicked: root.deleteRequested(root.taskUuid, root.taskDescription)
            }
        }
    }

    // Helper functions provided by TaskUtils.js:
    // TaskUtils.getPriorityColor(priority, Color)
    // TaskUtils.formatDueDate(dueStr, pluginApi)
    // TaskUtils.isDueOverdue(dueStr)
}
