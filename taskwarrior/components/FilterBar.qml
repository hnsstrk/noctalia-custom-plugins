import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Rectangle {
    id: root

    property var pluginApi: null
    property var mainInstance: null

    // Filter state (bound bidirectionally from Panel)
    property string filterStatus: "pending"
    property string filterProject: ""
    property string filterPriority: ""
    property string filterDue: ""
    property var filterTags: []
    property string searchText: ""

    // Collapsible state
    property bool expanded: false

    signal filterChanged
    signal searchChanged(string text)
    signal resetRequested

    Layout.fillWidth: true
    implicitHeight: filterContent.implicitHeight + Style.marginM * 2
    color: Color.mSurfaceVariant
    radius: Style.radiusM

    ColumnLayout {
        id: filterContent
        anchors {
            fill: parent
            margins: Style.marginM
        }
        spacing: Style.marginS

        // === Row 1: Toggle + Chips + Search (always visible) ===
        RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            // Filter toggle button
            Rectangle {
                Layout.preferredWidth: filterToggleRow.implicitWidth + Style.marginM * 2
                Layout.preferredHeight: Style.baseWidgetSize * 0.95
                radius: Style.iRadiusS
                color: filterToggleMouseArea.containsMouse ? Color.mHover : "transparent"
                border.color: Color.mOutline
                border.width: 1

                Row {
                    id: filterToggleRow
                    anchors.centerIn: parent
                    spacing: Style.marginXS

                    NIcon {
                        icon: root.expanded ? "chevron-up" : "chevron-down"
                        color: Color.mOnSurfaceVariant
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    NText {
                        text: pluginApi?.tr("panel.filter-toggle-label") || "Filter"
                        font.pointSize: Style.fontSizeS
                        color: Color.mOnSurfaceVariant
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: filterToggleMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.expanded = !root.expanded
                }
            }

            // Active filter chips (always visible)
            Flow {
                Layout.fillWidth: true
                spacing: Style.marginXS

                Repeater {
                    model: {
                        var chips = [];
                        if (root.filterStatus !== "pending" && root.filterStatus !== "")
                            chips.push({
                                type: "status",
                                label: "status:" + root.filterStatus
                            });
                        if (root.filterProject !== "")
                            chips.push({
                                type: "project",
                                label: "project:" + root.filterProject
                            });
                        if (root.filterPriority !== "")
                            chips.push({
                                type: "priority",
                                label: "priority:" + root.filterPriority
                            });
                        if (root.filterDue !== "")
                            chips.push({
                                type: "due",
                                label: "due:" + root.filterDue
                            });
                        for (var i = 0; i < root.filterTags.length; i++)
                            chips.push({
                                type: "tag",
                                label: "+" + root.filterTags[i],
                                index: i
                            });
                        return chips;
                    }

                    delegate: Rectangle {
                        required property var modelData
                        width: chipContentRow.implicitWidth + Style.marginM * 2
                        height: Style.fontSizeM * 2.5
                        radius: Style.radiusS
                        color: Color.mPrimary
                        opacity: 0.8

                        Row {
                            id: chipContentRow
                            anchors.centerIn: parent
                            spacing: Style.marginXS

                            NText {
                                text: modelData.label
                                font.pointSize: Style.fontSizeXS
                                color: Color.mOnPrimary
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            NText {
                                text: "x"
                                font.pointSize: Style.fontSizeXS
                                font.weight: Font.Bold
                                color: Color.mOnPrimary
                                anchors.verticalCenter: parent.verticalCenter

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (modelData.type === "status")
                                            root.filterStatus = "pending";
                                        else if (modelData.type === "project")
                                            root.filterProject = "";
                                        else if (modelData.type === "priority")
                                            root.filterPriority = "";
                                        else if (modelData.type === "due")
                                            root.filterDue = "";
                                        else if (modelData.type === "tag") {
                                            var tags = root.filterTags.slice();
                                            tags.splice(modelData.index, 1);
                                            root.filterTags = tags;
                                        }
                                        root.filterChanged();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Search field (always visible)
            NTextInput {
                id: searchInput
                Layout.preferredWidth: 180 * Style.uiScaleRatio
                placeholderText: pluginApi?.tr("panel.search-placeholder") || "Search tasks..."
                text: root.searchText
                onTextChanged: {
                    root.searchText = text;
                    root.searchChanged(text);
                }
            }
        }

        // === Expanded filter dropdowns ===
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.marginS
            visible: root.expanded

            // Row: Status, Project, Priority
            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginS

                NComboBox {
                    Layout.fillWidth: true
                    label: pluginApi?.tr("panel.filter-status-label") || "Status"
                    currentKey: root.filterStatus
                    model: [
                        {
                            key: "pending",
                            name: pluginApi?.tr("panel.filter-status-pending") || "Pending"
                        },
                        {
                            key: "completed",
                            name: pluginApi?.tr("panel.filter-status-completed") || "Completed"
                        },
                        {
                            key: "waiting",
                            name: pluginApi?.tr("panel.filter-status-waiting") || "Waiting"
                        },
                        {
                            key: "all",
                            name: pluginApi?.tr("panel.filter-status-all") || "All"
                        }
                    ]
                    onSelected: function (key) {
                        root.filterStatus = key;
                        root.filterChanged();
                    }
                }

                NComboBox {
                    Layout.fillWidth: true
                    label: pluginApi?.tr("panel.filter-project-label") || "Project"
                    currentKey: root.filterProject
                    model: {
                        var items = [
                            {
                                key: "",
                                name: pluginApi?.tr("panel.filter-project-all") || "All projects"
                            }
                        ];
                        var projects = root.mainInstance ? root.mainInstance.cachedProjects : [];
                        for (var i = 0; i < projects.length; i++)
                            items.push({
                                key: projects[i],
                                name: projects[i]
                            });
                        return items;
                    }
                    onSelected: function (key) {
                        root.filterProject = key;
                        root.filterChanged();
                    }
                }

                NComboBox {
                    Layout.fillWidth: true
                    label: pluginApi?.tr("panel.filter-priority-label") || "Priority"
                    currentKey: root.filterPriority
                    model: [
                        {
                            key: "",
                            name: pluginApi?.tr("panel.filter-priority-all") || "All"
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
                        root.filterPriority = key;
                        root.filterChanged();
                    }
                }
            }

            // Row: Due, Tags
            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginS

                NComboBox {
                    Layout.preferredWidth: 160
                    label: pluginApi?.tr("panel.filter-due-label") || "Due"
                    currentKey: root.filterDue
                    model: [
                        {
                            key: "",
                            name: pluginApi?.tr("panel.filter-due-any") || "Any"
                        },
                        {
                            key: "today",
                            name: pluginApi?.tr("panel.filter-due-today") || "Today"
                        },
                        {
                            key: "week",
                            name: pluginApi?.tr("panel.filter-due-week") || "This week"
                        },
                        {
                            key: "overdue",
                            name: pluginApi?.tr("panel.filter-due-overdue") || "Overdue"
                        }
                    ]
                    onSelected: function (key) {
                        root.filterDue = key;
                        root.filterChanged();
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                NIconButton {
                    icon: "x"
                    tooltipText: pluginApi?.tr("panel.filter-reset-tooltip") || "Reset filters"
                    onClicked: {
                        searchInput.text = "";
                        root.resetRequested();
                    }
                }
            }
        }
    }
}
