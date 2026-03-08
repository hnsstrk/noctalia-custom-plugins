import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import qs.Services.UI
import "TaskUtils.js" as TaskUtils

ColumnLayout {
    id: root

    property var pluginApi: null
    property var mainInstance: null

    signal taskAdded

    spacing: Style.marginXS

    function addNewTask() {
        var desc = descriptionInput.text.trim();
        if (!desc) {
            ToastService.showError(pluginApi?.tr("main.error-empty-description") || "Description cannot be empty");
            return;
        }
        if (!root.mainInstance)
            return;
        root.mainInstance.addTask(desc, projectInput.text.trim(), priorityGroup.currentPriority, dueInput.text.trim(), tagsInput.text.trim());
        descriptionInput.text = "";
        dueInput.text = "";
        tagsInput.text = "";
        priorityGroup.currentPriority = pluginApi?.pluginSettings?.defaultPriority || "";
        root.taskAdded();
    }

    // === Row 1: Description, Project, Due, Priority ===
    RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NTextInput {
            id: descriptionInput
            Layout.fillWidth: true
            placeholderText: pluginApi?.tr("panel.input-description-placeholder") || "Add a new task..."
            Keys.onReturnPressed: root.addNewTask()
        }

        NTextInput {
            id: projectInput
            Layout.preferredWidth: 120 * Style.uiScaleRatio
            placeholderText: pluginApi?.tr("panel.input-project-placeholder") || "Project"
            text: pluginApi?.pluginSettings?.defaultProject || ""
            Keys.onReturnPressed: root.addNewTask()
        }

        NTextInput {
            id: dueInput
            Layout.preferredWidth: 140 * Style.uiScaleRatio
            placeholderText: pluginApi?.tr("panel.quick-add-due-placeholder") || "e.g. tomorrow, eow"
            Keys.onReturnPressed: root.addNewTask()
        }

        // Priority selector (H/M/L toggle)
        Item {
            Layout.preferredWidth: 90 * Style.uiScaleRatio
            Layout.preferredHeight: Style.baseWidgetSize * 0.95

            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.color: Color.mOutline
                border.width: 1
                radius: Style.iRadiusS

                Row {
                    anchors.fill: parent
                    spacing: 1

                    Repeater {
                        model: ["H", "M", "L"]
                        delegate: Rectangle {
                            required property string modelData
                            required property int index
                            width: (parent.width - 2) / 3
                            height: parent.height
                            color: priorityGroup.currentPriority === modelData ? TaskUtils.getPriorityColor(modelData, Color) : "transparent"
                            radius: Style.iRadiusS

                            NText {
                                anchors.centerIn: parent
                                text: modelData
                                color: priorityGroup.currentPriority === modelData ? Color.mOnPrimary : TaskUtils.getPriorityColor(modelData, Color)
                                font.pointSize: Style.fontSizeS
                                font.weight: Font.Bold
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: priorityGroup.currentPriority = (priorityGroup.currentPriority === modelData ? "" : modelData)
                            }
                        }
                    }
                }
            }
        }

        QtObject {
            id: priorityGroup
            property string currentPriority: pluginApi?.pluginSettings?.defaultPriority || ""
        }
    }

    // === Row 2: Tags + Add Button ===
    RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NTextInput {
            id: tagsInput
            Layout.fillWidth: true
            placeholderText: pluginApi?.tr("panel.quick-add-tags-placeholder") || "e.g. urgent, review"
            Keys.onReturnPressed: root.addNewTask()
        }

        NIconButton {
            icon: "plus"
            baseSize: Style.baseWidgetSize * 1.2
            customRadius: Style.iRadiusS
            onClicked: root.addNewTask()
        }
    }

    // Helper functions provided by TaskUtils.js:
    // TaskUtils.getPriorityColor(priority, Color)
}
