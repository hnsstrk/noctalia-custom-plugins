import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Rectangle {
    id: root

    property var pluginApi: null
    property var mainInstance: null
    property var taskModel: null
    property bool showEmptyState: false

    signal editRequested(string uuid)
    signal deleteRequested(string uuid, string description)

    Layout.fillWidth: true
    Layout.fillHeight: true
    color: Color.mSurfaceVariant
    radius: Style.radiusL

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.marginS

        ListView {
            id: taskListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root.taskModel
            spacing: Style.marginS
            boundsBehavior: Flickable.StopAtBounds

            delegate: TaskDelegate {
                pluginApi: root.pluginApi
                mainInstance: root.mainInstance
                taskUuid: model.taskUuid || ""
                taskDescription: model.taskDescription || ""
                taskProject: model.taskProject || ""
                taskPriority: model.taskPriority || ""
                taskDue: model.taskDue || ""
                taskStatus: model.taskStatus || ""
                taskTags: model.taskTags || ""
                taskStart: model.taskStart || ""
                taskUrgency: model.taskUrgency || 0
                onEditRequested: function (uuid) {
                    root.editRequested(uuid);
                }
                onDeleteRequested: function (uuid, description) {
                    root.deleteRequested(uuid, description);
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.showEmptyState

            NText {
                anchors.centerIn: parent
                text: pluginApi?.tr("panel.empty-state") || "No tasks found"
                color: Color.mOnSurfaceVariant
                font.pointSize: Style.fontSizeM
            }
        }
    }
}
