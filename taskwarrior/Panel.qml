import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  // === Plugin API (injected by PluginPanelSlot) ===
  property var pluginApi: null

  // === SmartPanel required properties ===
  readonly property var geometryPlaceholder: panelContainer
  property real contentPreferredWidth: 750 * Style.uiScaleRatio
  property real contentPreferredHeight: 550 * Style.uiScaleRatio
  readonly property bool allowAttach: true
  anchors.fill: parent

  // === Main instance reference ===
  readonly property var mainInstance: pluginApi?.mainInstance

  // === Local UI state ===
  property var filteredTasksModel: ListModel {}
  property bool showEmptyState: false
  property string localSearchText: ""

  // === Filter state ===
  property string filterStatus: "pending"
  property string filterProject: ""
  property string filterPriority: ""
  property string filterDue: ""
  property var filterTags: []

  // === Refresh on panel open ===
  onVisibleChanged: {
    if (visible && mainInstance) {
      mainInstance.refreshAll();
    }
  }

  // === React to data changes ===
  property var watchTasks: mainInstance ? mainInstance.cachedTasks : []
  onWatchTasksChanged: {
    reloadTaskList();
  }

  // === Build and apply filter ===
  function buildAndApplyFilter() {
    var filter = {};
    if (root.filterStatus && root.filterStatus !== "all") filter.status = root.filterStatus;
    if (root.filterProject && root.filterProject !== "") filter.project = root.filterProject;
    if (root.filterPriority && root.filterPriority !== "") filter.priority = root.filterPriority;
    if (root.filterDue && root.filterDue !== "") filter.due = root.filterDue;
    if (root.filterTags.length > 0) filter.tags = root.filterTags;
    if (mainInstance) mainInstance.applyFilter(filter);
  }

  // === Reload task list from cached data ===
  function reloadTaskList() {
    filteredTasksModel.clear();
    var tasks = mainInstance ? mainInstance.cachedTasks : [];
    var search = root.localSearchText.toLowerCase().trim();

    for (var i = 0; i < tasks.length; i++) {
      var task = tasks[i];
      if (search !== "" && task.description.toLowerCase().indexOf(search) === -1) continue;

      filteredTasksModel.append({
        taskUuid: task.uuid || "",
        taskDescription: task.description || "",
        taskProject: task.project || "",
        taskPriority: task.priority || "",
        taskDue: task.due || "",
        taskStatus: task.status || "pending",
        taskTags: task.tags ? task.tags.join(", ") : "",
        taskStart: task.start || "",
        taskUrgency: task.urgency || 0,
        taskEntry: task.entry || ""
      });
    }
    root.showEmptyState = (filteredTasksModel.count === 0);
  }

  function resetFilters() {
    root.filterStatus = "pending";
    root.filterProject = "";
    root.filterPriority = "";
    root.filterDue = "";
    root.filterTags = [];
    root.localSearchText = "";
    buildAndApplyFilter();
  }

  // === Helper functions ===
  function getPriorityColor(priority) {
    if (priority === "H") return Color.mError;
    if (priority === "M") return Color.mPrimary;
    if (priority === "L") return Color.mOnSurfaceVariant;
    return Color.mOnSurfaceVariant;
  }

  function formatDueDate(dueStr) {
    if (!dueStr || dueStr === "") return "";
    try {
      var d = new Date(dueStr);
      var now = new Date();
      var diffMs = d.getTime() - now.getTime();
      var diffDays = Math.ceil(diffMs / (1000 * 60 * 60 * 24));
      if (diffDays < 0) return pluginApi?.tr("panel.due-overdue") || "Overdue";
      if (diffDays === 0) return pluginApi?.tr("panel.due-today") || "Today";
      if (diffDays === 1) return pluginApi?.tr("panel.due-tomorrow") || "Tomorrow";
      return d.toLocaleDateString();
    } catch (e) {
      return dueStr;
    }
  }

  function isDueOverdue(dueStr) {
    if (!dueStr || dueStr === "") return false;
    try { return new Date(dueStr) < new Date(); } catch (e) { return false; }
  }

  function formatDateForInput(dateStr) {
    if (!dateStr || dateStr === "") return "";
    try {
      var d = new Date(dateStr);
      return d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, '0') + "-" + String(d.getDate()).padStart(2, '0');
    } catch (e) { return dateStr; }
  }

  // === Add new task ===
  function addNewTask() {
    var desc = newTaskInput.text.trim();
    if (!desc || !mainInstance) return;
    mainInstance.addTask(desc, newTaskProject.text.trim(), newTaskPriorityGroup.currentPriority, "", "");
    newTaskInput.text = "";
    newTaskPriorityGroup.currentPriority = pluginApi?.pluginSettings?.defaultPriority || "";
  }

  // === Panel Layout ===
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

      // === Header ===
      RowLayout {
        Layout.fillWidth: true
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

        Item { Layout.fillWidth: true }

        NIconButton {
          icon: "refresh"
          tooltipText: pluginApi?.tr("panel.refresh-tooltip") || "Refresh"
          onClicked: { if (mainInstance) mainInstance.refreshAll(); }
        }

        NIconButton {
          icon: "settings"
          tooltipText: pluginApi?.tr("panel.settings-tooltip") || "Settings"
          onClicked: {
            var screen = pluginApi?.panelOpenScreen;
            if (screen && pluginApi?.manifest) BarService.openPluginSettings(screen, pluginApi.manifest);
          }
        }
      }

      // === Filter-Bar ===
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: filterBarContent.implicitHeight + Style.marginM * 2
        color: Color.mSurfaceVariant
        radius: Style.radiusM

        ColumnLayout {
          id: filterBarContent
          anchors {
            fill: parent
            margins: Style.marginM
          }
          spacing: Style.marginS

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            NComboBox {
              Layout.fillWidth: true
              label: pluginApi?.tr("panel.filter-status-label") || "Status"
              currentKey: root.filterStatus
              model: [
                { key: "pending", name: pluginApi?.tr("panel.filter-status-pending") || "Pending" },
                { key: "completed", name: pluginApi?.tr("panel.filter-status-completed") || "Completed" },
                { key: "waiting", name: pluginApi?.tr("panel.filter-status-waiting") || "Waiting" },
                { key: "all", name: pluginApi?.tr("panel.filter-status-all") || "All" }
              ]
              onSelected: function(key) { root.filterStatus = key; buildAndApplyFilter(); }
            }

            NComboBox {
              Layout.fillWidth: true
              label: pluginApi?.tr("panel.filter-project-label") || "Project"
              currentKey: root.filterProject
              model: {
                var items = [{ key: "", name: pluginApi?.tr("panel.filter-project-all") || "All projects" }];
                var projects = mainInstance ? mainInstance.cachedProjects : [];
                for (var i = 0; i < projects.length; i++) items.push({ key: projects[i], name: projects[i] });
                return items;
              }
              onSelected: function(key) { root.filterProject = key; buildAndApplyFilter(); }
            }

            NComboBox {
              Layout.fillWidth: true
              label: pluginApi?.tr("panel.filter-priority-label") || "Priority"
              currentKey: root.filterPriority
              model: [
                { key: "", name: pluginApi?.tr("panel.filter-priority-all") || "All" },
                { key: "H", name: pluginApi?.tr("panel.priority-high") || "High" },
                { key: "M", name: pluginApi?.tr("panel.priority-medium") || "Medium" },
                { key: "L", name: pluginApi?.tr("panel.priority-low") || "Low" }
              ]
              onSelected: function(key) { root.filterPriority = key; buildAndApplyFilter(); }
            }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            NComboBox {
              Layout.preferredWidth: 160
              label: pluginApi?.tr("panel.filter-due-label") || "Due"
              currentKey: root.filterDue
              model: [
                { key: "", name: pluginApi?.tr("panel.filter-due-any") || "Any" },
                { key: "today", name: pluginApi?.tr("panel.filter-due-today") || "Today" },
                { key: "week", name: pluginApi?.tr("panel.filter-due-week") || "This week" },
                { key: "overdue", name: pluginApi?.tr("panel.filter-due-overdue") || "Overdue" }
              ]
              onSelected: function(key) { root.filterDue = key; buildAndApplyFilter(); }
            }

            NTextInput {
              id: searchInput
              Layout.fillWidth: true
              placeholderText: pluginApi?.tr("panel.search-placeholder") || "Search tasks..."
              text: root.localSearchText
              onTextChanged: { root.localSearchText = text; reloadTaskList(); }
            }

            NIconButton {
              icon: "x"
              tooltipText: pluginApi?.tr("panel.filter-reset-tooltip") || "Reset filters"
              onClicked: { searchInput.text = ""; resetFilters(); }
            }
          }

          // Active filter chips
          Flow {
            Layout.fillWidth: true
            spacing: Style.marginXS
            visible: root.filterProject !== "" || root.filterPriority !== "" || root.filterDue !== "" || root.filterTags.length > 0

            Repeater {
              model: {
                var chips = [];
                if (root.filterProject !== "") chips.push({ type: "project", label: "project:" + root.filterProject });
                if (root.filterPriority !== "") chips.push({ type: "priority", label: "priority:" + root.filterPriority });
                if (root.filterDue !== "") chips.push({ type: "due", label: "due:" + root.filterDue });
                for (var i = 0; i < root.filterTags.length; i++) chips.push({ type: "tag", label: "+" + root.filterTags[i], index: i });
                return chips;
              }

              delegate: Rectangle {
                required property var modelData
                width: chipRow.implicitWidth + Style.marginM * 2
                height: Style.fontSizeM * 2.5
                radius: Style.radiusS
                color: Color.mPrimary
                opacity: 0.8

                Row {
                  id: chipRow
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
                        if (modelData.type === "project") root.filterProject = "";
                        else if (modelData.type === "priority") root.filterPriority = "";
                        else if (modelData.type === "due") root.filterDue = "";
                        else if (modelData.type === "tag") {
                          var tags = root.filterTags.slice();
                          tags.splice(modelData.index, 1);
                          root.filterTags = tags;
                        }
                        buildAndApplyFilter();
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }

      // === Task Input ===
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NTextInput {
          id: newTaskInput
          Layout.fillWidth: true
          placeholderText: pluginApi?.tr("panel.input-description-placeholder") || "Add a new task..."
          Keys.onReturnPressed: addNewTask()
        }

        NTextInput {
          id: newTaskProject
          Layout.preferredWidth: 120 * Style.uiScaleRatio
          placeholderText: pluginApi?.tr("panel.input-project-placeholder") || "Project"
          text: pluginApi?.pluginSettings?.defaultProject || ""
        }

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
                  color: newTaskPriorityGroup.currentPriority === modelData ? getPriorityColor(modelData) : "transparent"
                  radius: Style.iRadiusS

                  NText {
                    anchors.centerIn: parent
                    text: modelData
                    color: newTaskPriorityGroup.currentPriority === modelData ? Color.mOnPrimary : getPriorityColor(modelData)
                    font.pointSize: Style.fontSizeS
                    font.weight: Font.Bold
                  }

                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: newTaskPriorityGroup.currentPriority = (newTaskPriorityGroup.currentPriority === modelData ? "" : modelData)
                  }
                }
              }
            }
          }
        }

        QtObject {
          id: newTaskPriorityGroup
          property string currentPriority: pluginApi?.pluginSettings?.defaultPriority || ""
        }

        NIconButton {
          icon: "plus"
          baseSize: Style.baseWidgetSize * 1.2
          customRadius: Style.iRadiusS
          onClicked: addNewTask()
        }
      }

      // === Task List ===
      Rectangle {
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
            model: root.filteredTasksModel
            spacing: Style.marginS
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
              id: taskDelegate
              width: ListView.view.width
              height: taskDelegateContent.implicitHeight + Style.marginM * 2
              color: Color.mSurface
              radius: Style.radiusS

              required property int index
              required property var model

              readonly property string uuid: model.taskUuid || ""
              readonly property string desc: model.taskDescription || ""
              readonly property string proj: model.taskProject || ""
              readonly property string prio: model.taskPriority || ""
              readonly property string due: model.taskDue || ""
              readonly property string status: model.taskStatus || ""
              readonly property string tags: model.taskTags || ""
              readonly property string start: model.taskStart || ""
              readonly property bool isActive: start !== ""
              readonly property bool isOverdue: root.isDueOverdue(due)

              ColumnLayout {
                id: taskDelegateContent
                anchors {
                  left: parent.left
                  right: parent.right
                  top: parent.top
                  margins: Style.marginM
                }
                spacing: Style.marginXS

                RowLayout {
                  Layout.fillWidth: true
                  spacing: Style.marginS

                  Rectangle {
                    Layout.preferredWidth: 4
                    Layout.preferredHeight: Style.baseWidgetSize * 0.7
                    Layout.alignment: Qt.AlignVCenter
                    radius: 2
                    color: root.getPriorityColor(taskDelegate.prio)
                    visible: taskDelegate.prio !== ""
                  }

                  Rectangle {
                    Layout.preferredWidth: 8
                    Layout.preferredHeight: 8
                    Layout.alignment: Qt.AlignVCenter
                    radius: 4
                    color: Color.mPrimary
                    visible: taskDelegate.isActive
                  }

                  Item {
                    Layout.preferredWidth: Style.baseWidgetSize * 0.7
                    Layout.preferredHeight: Style.baseWidgetSize * 0.7
                    visible: taskDelegate.status === "pending"

                    Rectangle {
                      anchors.fill: parent
                      radius: Style.iRadiusXS
                      color: Color.mSurface
                      border.color: Color.mOutline
                      border.width: Style.borderS

                      MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { if (mainInstance) mainInstance.completeTask(taskDelegate.uuid); }
                      }
                    }
                  }

                  NText {
                    Layout.fillWidth: true
                    text: taskDelegate.desc
                    color: taskDelegate.isOverdue ? Color.mError : Color.mOnSurface
                    font.pointSize: Style.fontSizeS
                    font.weight: taskDelegate.isActive ? Font.Bold : Font.Normal
                    elide: Text.ElideRight
                    maximumLineCount: 1
                  }

                  Rectangle {
                    visible: taskDelegate.prio !== ""
                    Layout.preferredWidth: prioBadge.implicitWidth + Style.marginS * 2
                    Layout.preferredHeight: Style.fontSizeS * 2
                    radius: Style.radiusS
                    color: root.getPriorityColor(taskDelegate.prio)
                    opacity: 0.8

                    NText {
                      id: prioBadge
                      anchors.centerIn: parent
                      text: taskDelegate.prio
                      font.pointSize: Style.fontSizeXS
                      font.weight: Font.Bold
                      color: Color.mOnPrimary
                    }
                  }

                  Rectangle {
                    visible: taskDelegate.due !== ""
                    Layout.preferredWidth: dueBadge.implicitWidth + Style.marginS * 2
                    Layout.preferredHeight: Style.fontSizeS * 2
                    radius: Style.radiusS
                    color: taskDelegate.isOverdue ? Color.mError : Color.mSurfaceVariant

                    NText {
                      id: dueBadge
                      anchors.centerIn: parent
                      text: root.formatDueDate(taskDelegate.due)
                      font.pointSize: Style.fontSizeXS
                      color: taskDelegate.isOverdue ? Color.mOnError : Color.mOnSurfaceVariant
                    }
                  }
                }

                RowLayout {
                  Layout.fillWidth: true
                  Layout.leftMargin: Style.marginM
                  spacing: Style.marginXS
                  visible: taskDelegate.proj !== "" || taskDelegate.tags !== ""

                  NText {
                    visible: taskDelegate.proj !== ""
                    text: taskDelegate.proj
                    font.pointSize: Style.fontSizeXS
                    color: Color.mOnSurfaceVariant
                    font.italic: true
                  }

                  NText {
                    visible: taskDelegate.proj !== "" && taskDelegate.tags !== ""
                    text: "\u00b7"
                    font.pointSize: Style.fontSizeXS
                    color: Color.mOnSurfaceVariant
                  }

                  NText {
                    visible: taskDelegate.tags !== ""
                    text: taskDelegate.tags
                    font.pointSize: Style.fontSizeXS
                    color: Color.mOnSurfaceVariant
                  }

                  Item { Layout.fillWidth: true }
                }

                RowLayout {
                  Layout.fillWidth: true
                  Layout.leftMargin: Style.marginM
                  spacing: Style.marginS

                  Item { Layout.fillWidth: true }

                  NButton {
                    visible: taskDelegate.status === "pending"
                    text: taskDelegate.isActive ? (pluginApi?.tr("panel.action-stop") || "Stop") : (pluginApi?.tr("panel.action-start") || "Start")
                    icon: taskDelegate.isActive ? "player-stop" : "player-play"
                    fontSize: Style.fontSizeXS
                    onClicked: {
                      if (mainInstance) {
                        if (taskDelegate.isActive) mainInstance.stopTask(taskDelegate.uuid);
                        else mainInstance.startTask(taskDelegate.uuid);
                      }
                    }
                  }

                  NButton {
                    text: pluginApi?.tr("panel.action-edit") || "Edit"
                    icon: "pencil"
                    fontSize: Style.fontSizeXS
                    onClicked: root.openDetailDialog(taskDelegate.uuid)
                  }

                  NButton {
                    text: pluginApi?.tr("panel.action-delete") || "Delete"
                    icon: "trash"
                    fontSize: Style.fontSizeXS
                    textColor: Color.mError
                    onClicked: root.openDeleteDialog(taskDelegate.uuid, taskDelegate.desc)
                  }
                }
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

      // === Status Bar ===
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NText {
          text: {
            var count = root.filteredTasksModel.count;
            var overdue = mainInstance ? mainInstance.overdueCount : 0;
            var statusText = count + " " + (pluginApi?.tr("panel.status-tasks") || "tasks");
            if (overdue > 0) statusText += " · " + overdue + " " + (pluginApi?.tr("panel.status-overdue") || "overdue");
            return statusText;
          }
          font.pointSize: Style.fontSizeS
          color: Color.mOnSurfaceVariant
        }

        Item { Layout.fillWidth: true }

        NText {
          visible: !mainInstance || !mainInstance.taskwarriorAvailable
          text: pluginApi?.tr("panel.status-unavailable") || "Taskwarrior not found"
          font.pointSize: Style.fontSizeS
          color: Color.mError
        }
      }
    }
  }

  // === Detail Dialog ===
  function openDetailDialog(uuid) {
    var tasks = mainInstance ? mainInstance.cachedTasks : [];
    var task = null;
    for (var i = 0; i < tasks.length; i++) {
      if (tasks[i].uuid === uuid) { task = tasks[i]; break; }
    }
    if (!task) return;

    detailDialog.taskData = task;
    detailDialog.editDescription = task.description || "";
    detailDialog.editProject = task.project || "";
    detailDialog.editPriority = task.priority || "";
    detailDialog.editDue = task.due ? formatDateForInput(task.due) : "";
    detailDialog.editTags = task.tags ? task.tags.join(", ") : "";
    detailDialog.editWait = task.wait ? formatDateForInput(task.wait) : "";
    detailDialog.editScheduled = task.scheduled ? formatDateForInput(task.scheduled) : "";
    detailDialog.open();
  }

  Popup {
    id: detailDialog

    property var taskData: null
    property string editDescription: ""
    property string editProject: ""
    property string editPriority: ""
    property string editDue: ""
    property string editTags: ""
    property string editWait: ""
    property string editScheduled: ""

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
        anchors { left: parent.left; right: parent.right; top: parent.top }
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
            onClicked: detailDialog.close()
          }
        }
      }

      Flickable {
        anchors { left: parent.left; right: parent.right; top: detailHeader.bottom; bottom: detailButtonBar.top }
        contentWidth: width
        contentHeight: detailColumn.implicitHeight + Style.marginL
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
          id: detailColumn
          anchors { left: parent.left; right: parent.right; top: parent.top; margins: Style.marginL }
          spacing: Style.marginM

          NTextInput {
            Layout.fillWidth: true
            label: pluginApi?.tr("panel.detail-description-label") || "Description"
            text: detailDialog.editDescription
            onTextChanged: detailDialog.editDescription = text
          }

          NTextInput {
            Layout.fillWidth: true
            label: pluginApi?.tr("panel.detail-project-label") || "Project"
            placeholderText: pluginApi?.tr("panel.detail-project-placeholder") || "e.g. work"
            text: detailDialog.editProject
            onTextChanged: detailDialog.editProject = text
          }

          NComboBox {
            Layout.fillWidth: true
            label: pluginApi?.tr("panel.detail-priority-label") || "Priority"
            currentKey: detailDialog.editPriority
            model: [
              { key: "", name: pluginApi?.tr("panel.priority-none") || "None" },
              { key: "H", name: pluginApi?.tr("panel.priority-high") || "High" },
              { key: "M", name: pluginApi?.tr("panel.priority-medium") || "Medium" },
              { key: "L", name: pluginApi?.tr("panel.priority-low") || "Low" }
            ]
            onSelected: function(key) { detailDialog.editPriority = key; }
          }

          NTextInput {
            Layout.fillWidth: true
            label: pluginApi?.tr("panel.detail-due-label") || "Due"
            placeholderText: pluginApi?.tr("panel.detail-due-placeholder") || "e.g. 2026-03-01, tomorrow, eow"
            text: detailDialog.editDue
            onTextChanged: detailDialog.editDue = text
          }

          NTextInput {
            Layout.fillWidth: true
            label: pluginApi?.tr("panel.detail-tags-label") || "Tags"
            placeholderText: pluginApi?.tr("panel.detail-tags-placeholder") || "e.g. urgent, review"
            text: detailDialog.editTags
            onTextChanged: detailDialog.editTags = text
          }

          NTextInput {
            Layout.fillWidth: true
            label: pluginApi?.tr("panel.detail-wait-label") || "Wait"
            placeholderText: pluginApi?.tr("panel.detail-wait-placeholder") || "e.g. 2026-03-01, tomorrow"
            text: detailDialog.editWait
            onTextChanged: detailDialog.editWait = text
          }

          NTextInput {
            Layout.fillWidth: true
            label: pluginApi?.tr("panel.detail-scheduled-label") || "Scheduled"
            placeholderText: pluginApi?.tr("panel.detail-scheduled-placeholder") || "e.g. monday, 2026-03-01"
            text: detailDialog.editScheduled
            onTextChanged: detailDialog.editScheduled = text
          }

          // Annotations (read-only)
          ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.marginXS
            visible: detailDialog.taskData && detailDialog.taskData.annotations && detailDialog.taskData.annotations.length > 0

            NText {
              text: pluginApi?.tr("panel.detail-annotations-label") || "Annotations"
              font.pointSize: Style.fontSizeS
              font.weight: Font.Medium
              color: Color.mOnSurfaceVariant
            }

            Repeater {
              model: (detailDialog.taskData && detailDialog.taskData.annotations) ? detailDialog.taskData.annotations : []
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

          Rectangle { Layout.fillWidth: true; height: 1; color: Color.mOutline; opacity: 0.3 }

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginM

            NText {
              text: "UUID: " + (detailDialog.taskData ? detailDialog.taskData.uuid : "")
              font.pointSize: Style.fontSizeXS
              font.family: Settings.data.ui.fontFixed
              color: Color.mOnSurfaceVariant
              Layout.fillWidth: true
              elide: Text.ElideMiddle
            }

            NText {
              text: "Urgency: " + (detailDialog.taskData ? Number(detailDialog.taskData.urgency || 0).toFixed(1) : "0.0")
              font.pointSize: Style.fontSizeXS
              color: Color.mOnSurfaceVariant
            }
          }
        }
      }

      Rectangle {
        id: detailButtonBar
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 52 * Style.uiScaleRatio
        color: Color.mSurfaceVariant
        radius: Style.radiusS

        RowLayout {
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginS

          Item { Layout.fillWidth: true }

          NButton {
            text: pluginApi?.tr("panel.detail-cancel") || "Cancel"
            onClicked: detailDialog.close()
          }

          NButton {
            text: pluginApi?.tr("panel.detail-save") || "Save"
            backgroundColor: Color.mPrimary
            textColor: Color.mOnPrimary
            onClicked: { saveDetailChanges(); detailDialog.close(); }
          }
        }
      }
    }
  }

  function saveDetailChanges() {
    if (!mainInstance || !detailDialog.taskData) return;
    var uuid = detailDialog.taskData.uuid;

    if (detailDialog.editDescription !== (detailDialog.taskData.description || ""))
      mainInstance.modifyTask(uuid, "description", detailDialog.editDescription);
    if (detailDialog.editProject !== (detailDialog.taskData.project || ""))
      mainInstance.modifyTask(uuid, "project", detailDialog.editProject || "");
    if (detailDialog.editPriority !== (detailDialog.taskData.priority || ""))
      mainInstance.modifyTask(uuid, "priority", detailDialog.editPriority || "");

    var origDue = detailDialog.taskData.due ? formatDateForInput(detailDialog.taskData.due) : "";
    if (detailDialog.editDue !== origDue)
      mainInstance.modifyTask(uuid, "due", detailDialog.editDue || "");

    var origWait = detailDialog.taskData.wait ? formatDateForInput(detailDialog.taskData.wait) : "";
    if (detailDialog.editWait !== origWait)
      mainInstance.modifyTask(uuid, "wait", detailDialog.editWait || "");

    var origScheduled = detailDialog.taskData.scheduled ? formatDateForInput(detailDialog.taskData.scheduled) : "";
    if (detailDialog.editScheduled !== origScheduled)
      mainInstance.modifyTask(uuid, "scheduled", detailDialog.editScheduled || "");

    // Tags (diff-based)
    var origTags = detailDialog.taskData.tags || [];
    var newTagStr = detailDialog.editTags.trim();
    var newTags = newTagStr === "" ? [] : newTagStr.split(",").map(function(t) { return t.trim(); }).filter(function(t) { return t !== ""; });

    for (var i = 0; i < newTags.length; i++) {
      if (origTags.indexOf(newTags[i]) === -1) mainInstance.modifyTask(uuid, "tags", "+" + newTags[i]);
    }
    for (var j = 0; j < origTags.length; j++) {
      if (newTags.indexOf(origTags[j]) === -1) mainInstance.modifyTask(uuid, "tags", "-" + origTags[j]);
    }
  }

  // === Delete Confirmation Dialog ===
  function openDeleteDialog(uuid, description) {
    deleteConfirmDialog.deleteUuid = uuid;
    deleteConfirmDialog.deleteDescription = description;
    deleteConfirmDialog.open();
  }

  Popup {
    id: deleteConfirmDialog

    property string deleteUuid: ""
    property string deleteDescription: ""

    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    width: 400 * Style.uiScaleRatio
    height: 180 * Style.uiScaleRatio
    modal: true
    focus: true
    padding: 0

    background: Rectangle {
      color: Color.mSurface
      radius: Style.radiusL
      border.color: Color.mOutline
      border.width: 1
    }

    contentItem: ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginM

      NText {
        Layout.fillWidth: true
        text: pluginApi?.tr("panel.delete-confirm-title") || "Delete Task?"
        font.pointSize: Style.fontSizeM
        font.weight: Font.Bold
        color: Color.mOnSurface
      }

      NText {
        Layout.fillWidth: true
        text: deleteConfirmDialog.deleteDescription
        font.pointSize: Style.fontSizeS
        color: Color.mOnSurfaceVariant
        wrapMode: Text.Wrap
        elide: Text.ElideRight
        maximumLineCount: 2
      }

      Item { Layout.fillHeight: true }

      RowLayout {
        Layout.alignment: Qt.AlignRight
        spacing: Style.marginS

        NButton {
          text: pluginApi?.tr("panel.delete-cancel") || "Cancel"
          onClicked: deleteConfirmDialog.close()
        }

        NButton {
          text: pluginApi?.tr("panel.delete-confirm") || "Delete"
          textColor: Color.mOnError
          backgroundColor: Color.mError
          onClicked: {
            if (mainInstance) mainInstance.deleteTask(deleteConfirmDialog.deleteUuid);
            deleteConfirmDialog.close();
          }
        }
      }
    }
  }
}
