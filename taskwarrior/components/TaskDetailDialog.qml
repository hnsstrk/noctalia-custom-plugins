import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "TaskUtils.js" as TaskUtils

Popup {
    id: root

    property var pluginApi: null
    property var mainInstance: null

    property var taskData: null
    property string editDescription: ""
    property string editProject: ""
    property string editPriority: ""
    property string editDue: ""
    property string editTags: ""
    property string editWait: ""
    property string editScheduled: ""

    function openForTask(task) {
        root.taskData = task;
        root.editDescription = task.description || "";
        root.editProject = task.project || "";
        root.editPriority = task.priority || "";
        root.editDue = task.due ? TaskUtils.formatDateForInput(task.due) : "";
        root.editTags = task.tags ? task.tags.join(", ") : "";
        root.editWait = task.wait ? TaskUtils.formatDateForInput(task.wait) : "";
        root.editScheduled = task.scheduled ? TaskUtils.formatDateForInput(task.scheduled) : "";
        root.open();
    }

    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    width: 550 * Style.uiScaleRatio
    height: 450 * Style.uiScaleRatio
    modal: true
    focus: true
    padding: 0

    background: Rectangle {
        color: Color.mSurface
        radius: Style.radiusL
        border.color: Color.mOutline
        border.width: 1
    }

    contentItem: Item {
        anchors.fill: parent

        Rectangle {
            id: detailHeader
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
            height: 44 * Style.uiScaleRatio
            color: Color.mPrimary
            radius: Style.radiusS

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Style.marginL
                anchors.rightMargin: Style.marginM

                NText {
                    text: pluginApi?.tr("panel.detail-title") || "Task Details"
                    font.pointSize: Style.fontSizeM
                    font.weight: Font.Bold
                    color: Color.mOnPrimary
                    Layout.fillWidth: true
                }

                NIconButton {
                    icon: "x"
                    colorBg: Qt.rgba(1, 1, 1, 0.2)
                    colorBgHover: Qt.rgba(1, 1, 1, 0.3)
                    colorFg: Color.mOnPrimary
                    onClicked: root.close()
                }
            }
        }

        Flickable {
            anchors {
                left: parent.left
                right: parent.right
                top: detailHeader.bottom
                bottom: detailButtonBar.top
            }
            contentWidth: width
            contentHeight: detailColumn.implicitHeight + Style.marginL
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: detailColumn
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: Style.marginL
                }
                spacing: Style.marginM

                NTextInput {
                    Layout.fillWidth: true
                    label: pluginApi?.tr("panel.detail-description-label") || "Description"
                    text: root.editDescription
                    onTextChanged: root.editDescription = text
                }

                NTextInput {
                    Layout.fillWidth: true
                    label: pluginApi?.tr("panel.detail-project-label") || "Project"
                    placeholderText: pluginApi?.tr("panel.detail-project-placeholder") || "e.g. work"
                    text: root.editProject
                    onTextChanged: root.editProject = text
                }

                NComboBox {
                    Layout.fillWidth: true
                    label: pluginApi?.tr("panel.detail-priority-label") || "Priority"
                    currentKey: root.editPriority
                    model: [
                        {
                            key: "",
                            name: pluginApi?.tr("panel.priority-none") || "None"
                        },
                        {
                            key: "H",
                            name: pluginApi?.tr("panel.priority-high") || "High"
                        },
                        {
                            key: "M",
                            name: pluginApi?.tr("panel.priority-medium") || "Medium"
                        },
                        {
                            key: "L",
                            name: pluginApi?.tr("panel.priority-low") || "Low"
                        }
                    ]
                    onSelected: function (key) {
                        root.editPriority = key;
                    }
                }

                NTextInput {
                    Layout.fillWidth: true
                    label: pluginApi?.tr("panel.detail-due-label") || "Due"
                    placeholderText: pluginApi?.tr("panel.detail-due-placeholder") || "e.g. 2026-03-01, tomorrow, eow"
                    text: root.editDue
                    onTextChanged: root.editDue = text
                }

                NTextInput {
                    Layout.fillWidth: true
                    label: pluginApi?.tr("panel.detail-tags-label") || "Tags"
                    placeholderText: pluginApi?.tr("panel.detail-tags-placeholder") || "e.g. urgent, review"
                    text: root.editTags
                    onTextChanged: root.editTags = text
                }

                NTextInput {
                    Layout.fillWidth: true
                    label: pluginApi?.tr("panel.detail-wait-label") || "Wait"
                    placeholderText: pluginApi?.tr("panel.detail-wait-placeholder") || "e.g. 2026-03-01, tomorrow"
                    text: root.editWait
                    onTextChanged: root.editWait = text
                }

                NTextInput {
                    Layout.fillWidth: true
                    label: pluginApi?.tr("panel.detail-scheduled-label") || "Scheduled"
                    placeholderText: pluginApi?.tr("panel.detail-scheduled-placeholder") || "e.g. monday, 2026-03-01"
                    text: root.editScheduled
                    onTextChanged: root.editScheduled = text
                }

                // Annotations (read-only)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Style.marginXS
                    visible: root.taskData && root.taskData.annotations && root.taskData.annotations.length > 0

                    NText {
                        text: pluginApi?.tr("panel.detail-annotations-label") || "Annotations"
                        font.pointSize: Style.fontSizeS
                        font.weight: Font.Medium
                        color: Color.mOnSurfaceVariant
                    }

                    Repeater {
                        model: (root.taskData && root.taskData.annotations) ? root.taskData.annotations : []
                        delegate: NText {
                            required property var modelData
                            Layout.fillWidth: true
                            text: "- " + (modelData.description || "")
                            font.pointSize: Style.fontSizeXS
                            color: Color.mOnSurface
                            wrapMode: Text.Wrap
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Color.mOutline
                    opacity: 0.3
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.marginM

                    NText {
                        text: (pluginApi?.tr("panel.detail-uuid-label") || "UUID") + ": " + (root.taskData ? root.taskData.uuid : "")
                        font.pointSize: Style.fontSizeXS
                        font.family: Settings.data.ui.fontFixed
                        color: Color.mOnSurfaceVariant
                        Layout.fillWidth: true
                        elide: Text.ElideMiddle
                    }

                    NText {
                        text: (pluginApi?.tr("panel.detail-urgency-label") || "Urgency") + ": " + (root.taskData ? Number(root.taskData.urgency || 0).toFixed(1) : "0.0")
                        font.pointSize: Style.fontSizeXS
                        color: Color.mOnSurfaceVariant
                    }
                }
            }
        }

        Rectangle {
            id: detailButtonBar
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: 52 * Style.uiScaleRatio
            color: Color.mSurfaceVariant
            radius: Style.radiusS

            RowLayout {
                anchors.fill: parent
                anchors.margins: Style.marginM
                spacing: Style.marginS

                Item {
                    Layout.fillWidth: true
                }

                NButton {
                    text: pluginApi?.tr("panel.detail-cancel") || "Cancel"
                    onClicked: root.close()
                }

                NButton {
                    text: pluginApi?.tr("panel.detail-save") || "Save"
                    backgroundColor: Color.mPrimary
                    textColor: Color.mOnPrimary
                    onClicked: {
                        root.saveChanges();
                        root.close();
                    }
                }
            }
        }
    }

    function saveChanges() {
        if (!root.mainInstance || !root.taskData)
            return;
        var uuid = root.taskData.uuid;
        var modifications = [];

        if (root.editDescription !== (root.taskData.description || ""))
            modifications.push({
                field: "description",
                value: root.editDescription
            });
        if (root.editProject !== (root.taskData.project || ""))
            modifications.push({
                field: "project",
                value: root.editProject || ""
            });
        if (root.editPriority !== (root.taskData.priority || ""))
            modifications.push({
                field: "priority",
                value: root.editPriority || ""
            });

        var origDue = root.taskData.due ? TaskUtils.formatDateForInput(root.taskData.due) : "";
        if (root.editDue !== origDue)
            modifications.push({
                field: "due",
                value: root.editDue || ""
            });

        var origWait = root.taskData.wait ? TaskUtils.formatDateForInput(root.taskData.wait) : "";
        if (root.editWait !== origWait)
            modifications.push({
                field: "wait",
                value: root.editWait || ""
            });

        var origScheduled = root.taskData.scheduled ? TaskUtils.formatDateForInput(root.taskData.scheduled) : "";
        if (root.editScheduled !== origScheduled)
            modifications.push({
                field: "scheduled",
                value: root.editScheduled || ""
            });

        // Tags (diff-based)
        var origTags = root.taskData.tags || [];
        var newTagStr = root.editTags.trim();
        var newTags = newTagStr === "" ? [] : newTagStr.split(",").map(function (t) {
            return t.trim();
        }).filter(function (t) {
            return t !== "";
        });

        for (var i = 0; i < newTags.length; i++) {
            if (origTags.indexOf(newTags[i]) === -1)
                modifications.push({
                    field: "tags",
                    value: "+" + newTags[i]
                });
        }
        for (var j = 0; j < origTags.length; j++) {
            if (newTags.indexOf(origTags[j]) === -1)
                modifications.push({
                    field: "tags",
                    value: "-" + origTags[j]
                });
        }

        if (modifications.length > 0)
            root.mainInstance.batchModifyTask(uuid, modifications);
    }

    // Helper functions provided by TaskUtils.js:
    // TaskUtils.formatDateForInput(dateStr)
}
