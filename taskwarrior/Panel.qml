import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "components"

Item {
    id: root

    property var pluginApi: null

    readonly property var geometryPlaceholder: panelContainer
    property real contentPreferredWidth: 750 * Style.uiScaleRatio
    property real contentPreferredHeight: 550 * Style.uiScaleRatio
    readonly property bool allowAttach: true
    anchors.fill: parent

    readonly property var mainInstance: pluginApi?.mainInstance

    // === Local UI state ===
    property var filteredTasksModel: ListModel {}
    property bool showEmptyState: false
    property string localSearchText: ""

    // === Lifecycle ===
    onVisibleChanged: {
        if (visible && mainInstance) {
            mainInstance.refreshAll();
            if (pluginApi?.pluginSettings?.syncOnOpen)
                mainInstance.syncTasks();
        }
    }

    property var watchTasks: mainInstance ? mainInstance.cachedTasks : []
    onWatchTasksChanged: reloadTaskList()

    // === Filter logic ===
    function buildAndApplyFilter() {
        var filter = {};
        if (filterBar.filterStatus && filterBar.filterStatus !== "all")
            filter.status = filterBar.filterStatus;
        if (filterBar.filterProject && filterBar.filterProject !== "")
            filter.project = filterBar.filterProject;
        if (filterBar.filterPriority && filterBar.filterPriority !== "")
            filter.priority = filterBar.filterPriority;
        if (filterBar.filterDue && filterBar.filterDue !== "")
            filter.due = filterBar.filterDue;
        if (filterBar.filterTags.length > 0)
            filter.tags = filterBar.filterTags;
        if (mainInstance)
            mainInstance.applyFilter(filter);
    }

    function reloadTaskList() {
        filteredTasksModel.clear();
        var tasks = mainInstance ? mainInstance.cachedTasks : [];
        var search = root.localSearchText.toLowerCase().trim();

        for (var i = 0; i < tasks.length; i++) {
            var task = tasks[i];
            if (search !== "" && task.description.toLowerCase().indexOf(search) === -1)
                continue;
            filteredTasksModel.append({
                taskUuid: task.uuid || "",
                taskDescription: task.description || "",
                taskProject: task.project || "",
                taskPriority: task.priority || "",
                taskDue: task.due || "",
                taskStatus: task.status || "pending",
                taskTags: task.tags ? task.tags.join(", ") : "",
                taskStart: task.start || "",
                taskUrgency: task.urgency || 0
            });
        }
        root.showEmptyState = (filteredTasksModel.count === 0);
    }

    function resetFilters() {
        filterBar.filterStatus = "pending";
        filterBar.filterProject = "";
        filterBar.filterPriority = "";
        filterBar.filterDue = "";
        filterBar.filterTags = [];
        root.localSearchText = "";
        buildAndApplyFilter();
    }

    // === Layout ===
    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: "transparent"

        ColumnLayout {
            anchors {
                fill: parent
                margins: Style.marginM
            }
            spacing: Style.marginM

            PanelHeader {
                Layout.fillWidth: true
                pluginApi: root.pluginApi
                mainInstance: root.mainInstance
            }

            FilterBar {
                id: filterBar
                pluginApi: root.pluginApi
                mainInstance: root.mainInstance
                onFilterChanged: root.buildAndApplyFilter()
                onSearchChanged: function (text) {
                    root.localSearchText = text;
                    root.reloadTaskList();
                }
                onResetRequested: root.resetFilters()
            }

            QuickAdd {
                Layout.fillWidth: true
                pluginApi: root.pluginApi
                mainInstance: root.mainInstance
            }

            TaskList {
                pluginApi: root.pluginApi
                mainInstance: root.mainInstance
                taskModel: root.filteredTasksModel
                showEmptyState: root.showEmptyState
                onEditRequested: function (uuid) {
                    root.openDetailDialog(uuid);
                }
                onDeleteRequested: function (uuid, description) {
                    deleteDialog.openForTask(uuid, description);
                }
            }

            // Status bar
            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginS

                NText {
                    text: {
                        var count = root.filteredTasksModel.count;
                        var overdue = mainInstance ? mainInstance.overdueCount : 0;
                        var statusText = count + " " + (pluginApi?.tr("panel.status-tasks") || "tasks");
                        if (overdue > 0)
                            statusText += " \u00b7 " + overdue + " " + (pluginApi?.tr("panel.status-overdue") || "overdue");
                        return statusText;
                    }
                    font.pointSize: Style.fontSizeS
                    color: Color.mOnSurfaceVariant
                }

                Item {
                    Layout.fillWidth: true
                }

                NText {
                    visible: !mainInstance || !mainInstance.taskwarriorAvailable
                    text: pluginApi?.tr("panel.status-unavailable") || "Taskwarrior not found"
                    font.pointSize: Style.fontSizeS
                    color: Color.mError
                }
            }
        }
    }

    // === Dialogs ===
    function openDetailDialog(uuid) {
        var tasks = mainInstance ? mainInstance.cachedTasks : [];
        for (var i = 0; i < tasks.length; i++) {
            if (tasks[i].uuid === uuid) {
                detailDialog.openForTask(tasks[i]);
                return;
            }
        }
    }

    TaskDetailDialog {
        id: detailDialog
        pluginApi: root.pluginApi
        mainInstance: root.mainInstance
    }

    DeleteConfirmDialog {
        id: deleteDialog
        pluginApi: root.pluginApi
        mainInstance: root.mainInstance
    }
}
