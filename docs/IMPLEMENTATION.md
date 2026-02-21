# Taskwarrior Plugin — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement the Taskwarrior client plugin for Noctalia Shell as specified in PLAN.md.

**Architecture:** Server-side filtering via `task export` CLI with race condition handling, action queue for CRUD operations, and a three-layer update mechanism (on-exit hook + panel-open refresh + manual refresh).

**Tech Stack:** QML/JavaScript (Quickshell Framework), Taskwarrior CLI, Bash (hook script)

**Design Document:** Siehe **PLAN.md** für das vollständige Design-Dokument.

---

## Allgemeine Hinweise

- **Reihenfolge einhalten:** Die Tasks bauen aufeinander auf. Main.qml wird in Tasks 2-5 schrittweise erweitert, Panel.qml in Tasks 7-12.
- **Kein Qt5Compat:** Alle APIs sind Qt6. Keine `import Qt5Compat.GraphicalEffects` oder ähnliches.
- **Kein Polling:** Keine Timer für periodische Updates. Nur Hook + Panel-Open-Refresh + manueller Refresh.
- **IPC-Parameter sind Strings:** Alle IPC-Parameter kommen als String an, explizite Konvertierung nötig.
- **Process-Pattern:** `process.command = [...]; process.running = true;` startet den Prozess. Ergebnisse über `StdioCollector.onStreamFinished` (stdout) und `Process.onExited` (Exit-Code).
- **Action Queue:** CRUD-Operationen werden sequentiell abgearbeitet, da Taskwarrior seine Datenbank bei gleichzeitigen Zugriffen sperrt.
- **Race Conditions:** Der `currentRequestId`-Counter stellt sicher, dass veraltete Export-Ergebnisse verworfen werden.
- **pluginApi.mainInstance:** Panel.qml und Settings.qml greifen über `pluginApi.mainInstance` auf Main.qml zu.
- **Hook-Pfad dynamisch:** Hook-Pfad via `task _get rc.data.location` ermitteln, nicht hartkodieren (TW 2.x: `~/.task/`, TW 3.x: `~/.local/share/task/`).

---

### Task 1: manifest.json erstellen

**Files:** Create: `taskwarrior/manifest.json`

**Step 1:** Plugin-Verzeichnis und manifest.json erstellen.

```json
{
  "id": "taskwarrior",
  "name": "Taskwarrior",
  "version": "1.0.0",
  "minNoctaliaVersion": "4.1.2",
  "author": "hnsstrk",
  "license": "MIT",
  "repository": "https://github.com/hnsstrk/noctalia-custom-plugins",
  "description": "A full-featured Taskwarrior client for Noctalia Shell",
  "tags": ["Bar", "Panel", "Productivity", "i18n"],
  "dependencies": {
    "plugins": []
  },
  "entryPoints": {
    "main": "Main.qml",
    "barWidget": "BarWidget.qml",
    "panel": "Panel.qml",
    "settings": "Settings.qml"
  },
  "metadata": {
    "defaultSettings": {
      "barWidgetCounter": "pending",
      "showActiveIndicator": true,
      "defaultProject": "",
      "defaultPriority": "",
      "hookInstalled": false
    }
  }
}
```

**Step 2:** Verifikation: `cat taskwarrior/manifest.json | python3 -m json.tool` — muss valides JSON sein.

**Step 3:** Commit: `git add taskwarrior/manifest.json && git commit -m "feat(taskwarrior): add manifest.json for MVP v1.0.0"`

---

### Task 2: Main.qml — Basis-Struktur

**Files:** Create: `taskwarrior/Main.qml`

**Step 1:** Basis-Struktur mit pluginApi, Taskwarrior-Verfügbarkeitsprüfung und IPC-Handler-Skeleton. Die checkProcess prüft via `task --version`, ob Taskwarrior installiert ist.

```qml
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI

Item {
  id: root

  property var pluginApi: null

  // === State Properties ===
  property bool taskwarriorAvailable: false
  property var cachedTasks: []
  property var cachedProjects: []
  property var cachedTags: []
  property int pendingCount: 0
  property int overdueCount: 0
  property var activeTask: null
  property var currentFilter: ({})
  property int currentRequestId: 0
  property string searchText: ""

  // === Initialization ===
  Component.onCompleted: {
    if (pluginApi) {
      checkTaskwarrior();
    }
  }

  onPluginApiChanged: {
    if (pluginApi) {
      checkTaskwarrior();
    }
  }

  // === Taskwarrior Availability Check ===
  function checkTaskwarrior() {
    checkProcess.command = ["task", "--version"];
    checkProcess.running = true;
  }

  Process {
    id: checkProcess
    stdout: StdioCollector {}
    stderr: StdioCollector {}

    onExited: function(exitCode, exitStatus) {
      root.taskwarriorAvailable = (exitCode === 0);
      if (root.taskwarriorAvailable) {
        var version = String(checkProcess.stdout.text || "").trim();
        Logger.i("Taskwarrior", "Taskwarrior detected, version: " + version);
        root.refreshAll();
      } else {
        Logger.e("Taskwarrior", "Taskwarrior not found");
      }
    }
  }

  // === Convenience: Refresh all data ===
  function refreshAll() {
    if (!root.taskwarriorAvailable) return;
    loadTasks();
    loadCounters();
    loadProjects();
    loadTags();
  }

  // === Placeholder functions (implemented in Tasks 3-5) ===
  function loadTasks() {}
  function loadCounters() {}
  function loadProjects() {}
  function loadTags() {}

  // === IPC Handler ===
  IpcHandler {
    target: "plugin:taskwarrior"

    function togglePanel() {
      if (!pluginApi) return;
      pluginApi.withCurrentScreen(function(screen) {
        pluginApi.togglePanel(screen);
      });
    }

    function refresh() {
      root.refreshAll();
    }

    function addTask(description: string, project: string, priority: string, due: string, tags: string) {
      root.addTask(description, project, priority, due, tags);
    }

    function completeTask(uuid: string) {
      root.completeTask(uuid);
    }

    function deleteTask(uuid: string) {
      root.deleteTask(uuid);
    }

    function startTask(uuid: string) {
      root.startTask(uuid);
    }

    function stopTask(uuid: string) {
      root.stopTask(uuid);
    }

    function modifyTask(uuid: string, field: string, value: string) {
      root.modifyTask(uuid, field, value);
    }

    function installHook() {
      root.installHook();
    }

    function removeHook() {
      root.removeHook();
    }
  }

  // === Placeholder action functions (implemented in Task 4) ===
  function addTask(description, project, priority, due, tags) {}
  function completeTask(uuid) {}
  function deleteTask(uuid) {}
  function startTask(uuid) {}
  function stopTask(uuid) {}
  function modifyTask(uuid, field, value) {}

  // === Placeholder hook functions (implemented in Task 14) ===
  function installHook() {}
  function removeHook() {}
}
```

**Step 2:** Verifikation: Noctalia Shell im Debug-Modus starten (`NOCTALIA_DEBUG=1 qs -c noctalia-shell --no-duplicate`), Plugin aktivieren, in der Konsole nach "Taskwarrior detected" oder "Taskwarrior not found" suchen.

**Step 3:** Commit: `git add taskwarrior/Main.qml && git commit -m "feat(taskwarrior): add Main.qml base structure with availability check and IPC skeleton"`

---

### Task 3: Main.qml — Filter-Engine

**Files:** Edit: `taskwarrior/Main.qml`

**Step 1:** Die Placeholder-Funktionen `loadTasks` und `loadCounters` durch die vollständige Filter-Engine ersetzen. `buildFilterCommand` baut den CLI-Befehl dynamisch, `currentRequestId` verhindert Race Conditions.

Ersetze die Placeholder-Funktionen `loadTasks` und `loadCounters`:

```qml
  // === Filter Engine ===
  function buildFilterCommand(filter) {
    var parts = ["task", "rc.json.array=on"];

    if (filter.status && filter.status !== "all") {
      parts.push("status:" + filter.status);
    } else if (!filter.status) {
      parts.push("status:pending");
    }

    if (filter.project) {
      parts.push("project:" + filter.project);
    }

    if (filter.priority) {
      parts.push("priority:" + filter.priority);
    }

    if (filter.tags && filter.tags.length > 0) {
      for (var i = 0; i < filter.tags.length; i++) {
        parts.push("+" + filter.tags[i]);
      }
    }

    if (filter.due) {
      if (filter.due === "today") {
        parts.push("due:today");
      } else if (filter.due === "week") {
        parts.push("due.before:eow+1d");
      } else if (filter.due === "overdue") {
        parts.push("(+OVERDUE)");
      }
    }

    parts.push("export");
    return parts;
  }

  function loadTasks() {
    if (!root.taskwarriorAvailable) return;

    root.currentRequestId++;
    var requestId = root.currentRequestId;

    var cmd = buildFilterCommand(root.currentFilter);
    Logger.d("Taskwarrior", "Loading tasks with command: " + cmd.join(" "));

    exportProcess.requestId = requestId;
    exportProcess.command = cmd;
    exportProcess.running = true;
  }

  function applyFilter(filter) {
    root.currentFilter = filter;
    loadTasks();
  }

  Process {
    id: exportProcess
    property int requestId: 0

    stdout: StdioCollector {
      onStreamFinished: {
        if (exportProcess.requestId !== root.currentRequestId) {
          Logger.d("Taskwarrior", "Discarding stale export result (request " + exportProcess.requestId + ", current " + root.currentRequestId + ")");
          return;
        }

        var rawText = String(text || "").trim();
        if (!rawText || rawText === "") {
          root.cachedTasks = [];
          return;
        }

        try {
          var tasks = JSON.parse(rawText);
          root.cachedTasks = tasks;
          Logger.d("Taskwarrior", "Loaded " + tasks.length + " tasks");
        } catch (e) {
          Logger.e("Taskwarrior", "Failed to parse task export: " + e);
          root.cachedTasks = [];
        }
      }
    }

    stderr: StdioCollector {}

    onExited: function(exitCode, exitStatus) {
      if (exitCode !== 0) {
        var errText = String(exportProcess.stderr.text || "").trim();
        if (errText) {
          Logger.w("Taskwarrior", "Export stderr: " + errText);
        }
      }
    }
  }

  // === Counter-Prozesse für BarWidget (laufen unabhängig vom Filter) ===
  function loadCounters() {
    if (!root.taskwarriorAvailable) return;
    counterProcess.command = ["task", "rc.json.array=on", "status:pending", "export"];
    counterProcess.running = true;
  }

  Process {
    id: counterProcess
    stdout: StdioCollector {
      onStreamFinished: {
        var rawText = String(text || "").trim();
        if (!rawText || rawText === "") {
          root.pendingCount = 0;
          root.overdueCount = 0;
          root.activeTask = null;
          return;
        }

        try {
          var tasks = JSON.parse(rawText);
          var pending = 0;
          var overdue = 0;
          var active = null;
          var now = new Date();

          for (var i = 0; i < tasks.length; i++) {
            var task = tasks[i];
            if (task.status === "pending") pending++;
            if (task.due) {
              var dueDate = new Date(task.due);
              if (dueDate < now && task.status === "pending") overdue++;
            }
            if (task.start && task.status === "pending") active = task;
          }

          root.pendingCount = pending;
          root.overdueCount = overdue;
          root.activeTask = active;
        } catch (e) {
          Logger.e("Taskwarrior", "Failed to parse counter data: " + e);
        }
      }
    }
    stderr: StdioCollector {}
  }
```

**Step 2:** Verifikation: Shell neustarten, im Log muss "Loaded N tasks" erscheinen. IPC-Test: `qs -c noctalia-shell ipc call plugin:taskwarrior refresh` — muss erneut "Loaded N tasks" ausgeben.

**Step 3:** Commit: `git add taskwarrior/Main.qml && git commit -m "feat(taskwarrior): add filter engine with race condition handling and counter processes"`

---

### Task 4: Main.qml — CRUD Aktionen

**Files:** Edit: `taskwarrior/Main.qml`

**Step 1:** Die Placeholder-Funktionen für CRUD-Operationen durch vollständige Implementierungen ersetzen. Alle Schreiboperationen verwenden eine Action Queue für sequentielle Abarbeitung. Nach jeder erfolgreichen Aktion wird `refreshAll()` aufgerufen.

Ersetze die Placeholder-Funktionen:

```qml
  // === CRUD Actions ===
  property var actionQueue: []
  property bool actionRunning: false

  function runAction(cmd, successMessage, errorMessage) {
    root.actionQueue.push({
      command: cmd,
      successMessage: successMessage,
      errorMessage: errorMessage
    });
    processNextAction();
  }

  function processNextAction() {
    if (root.actionRunning || root.actionQueue.length === 0) return;

    var action = root.actionQueue.shift();
    root.actionRunning = true;
    actionProcess.successMessage = action.successMessage;
    actionProcess.errorMessage = action.errorMessage;
    actionProcess.command = action.command;
    actionProcess.running = true;
  }

  Process {
    id: actionProcess
    property string successMessage: ""
    property string errorMessage: ""

    stdout: StdioCollector {}
    stderr: StdioCollector {}

    onExited: function(exitCode, exitStatus) {
      root.actionRunning = false;

      if (exitCode === 0) {
        if (actionProcess.successMessage) {
          ToastService.showNotice(actionProcess.successMessage);
        }
        Logger.i("Taskwarrior", "Action completed successfully");
        root.refreshAll();
      } else {
        var errText = String(actionProcess.stderr.text || "").trim();
        var msg = actionProcess.errorMessage || pluginApi?.tr("main.error-action-failed") || "Action failed";
        if (errText) {
          msg += ": " + errText;
        }
        ToastService.showError(msg);
        Logger.e("Taskwarrior", "Action failed: " + errText);
      }

      root.processNextAction();
    }
  }

  function addTask(description, project, priority, due, tags) {
    if (!root.taskwarriorAvailable) return;
    if (!description || String(description).trim() === "") {
      ToastService.showError(pluginApi?.tr("main.error-empty-description") || "Description cannot be empty");
      return;
    }

    var cmd = ["task", "add", String(description).trim()];

    var proj = project || (pluginApi?.pluginSettings?.defaultProject || "");
    if (proj && String(proj).trim() !== "") {
      cmd.push("project:" + String(proj).trim());
    }

    var prio = priority || (pluginApi?.pluginSettings?.defaultPriority || "");
    if (prio && String(prio).trim() !== "") {
      cmd.push("priority:" + String(prio).trim());
    }

    if (due && String(due).trim() !== "") {
      cmd.push("due:" + String(due).trim());
    }

    if (tags && String(tags).trim() !== "") {
      var tagList = String(tags).split(",");
      for (var i = 0; i < tagList.length; i++) {
        var tag = tagList[i].trim();
        if (tag !== "") {
          cmd.push("+" + tag);
        }
      }
    }

    runAction(cmd,
      pluginApi?.tr("main.task-added") || "Task added",
      pluginApi?.tr("main.error-add-failed") || "Failed to add task"
    );
  }

  function completeTask(uuid) {
    if (!root.taskwarriorAvailable || !uuid) return;
    runAction(
      ["task", String(uuid), "done"],
      pluginApi?.tr("main.task-completed") || "Task completed",
      pluginApi?.tr("main.error-complete-failed") || "Failed to complete task"
    );
  }

  function deleteTask(uuid) {
    if (!root.taskwarriorAvailable || !uuid) return;
    runAction(
      ["sh", "-c", "echo 'yes' | task " + String(uuid) + " delete"],
      pluginApi?.tr("main.task-deleted") || "Task deleted",
      pluginApi?.tr("main.error-delete-failed") || "Failed to delete task"
    );
  }

  function modifyTask(uuid, field, value) {
    if (!root.taskwarriorAvailable || !uuid || !field) return;

    var cmd;
    if (field === "tags") {
      // Tags require special handling: value is "+tag" or "-tag"
      cmd = ["task", String(uuid), "modify", String(value)];
    } else {
      cmd = ["task", String(uuid), "modify", String(field) + ":" + String(value)];
    }

    runAction(cmd,
      pluginApi?.tr("main.task-modified") || "Task modified",
      pluginApi?.tr("main.error-modify-failed") || "Failed to modify task"
    );
  }

  function startTask(uuid) {
    if (!root.taskwarriorAvailable || !uuid) return;
    runAction(
      ["task", String(uuid), "start"],
      pluginApi?.tr("main.task-started") || "Task started",
      pluginApi?.tr("main.error-start-failed") || "Failed to start task"
    );
  }

  function stopTask(uuid) {
    if (!root.taskwarriorAvailable || !uuid) return;
    runAction(
      ["task", String(uuid), "stop"],
      pluginApi?.tr("main.task-stopped") || "Task stopped",
      pluginApi?.tr("main.error-stop-failed") || "Failed to stop task"
    );
  }
```

**Step 2:** Verifikation via IPC:
- `qs -c noctalia-shell ipc call plugin:taskwarrior addTask "Test from Noctalia" "" "H" "" ""`
- `task list` — der Task muss erscheinen
- `qs -c noctalia-shell ipc call plugin:taskwarrior completeTask "<uuid>"` mit UUID aus `task export`

**Step 3:** Commit: `git add taskwarrior/Main.qml && git commit -m "feat(taskwarrior): add CRUD actions with action queue and toast notifications"`

---

### Task 5: Main.qml — Metadaten laden

**Files:** Edit: `taskwarrior/Main.qml`

**Step 1:** Die Placeholder-Funktionen `loadProjects()` und `loadTags()` durch vollständige Implementierungen ersetzen. Diese laden via `task _projects` und `task _tags`.

Ersetze die Placeholder-Funktionen:

```qml
  // === Metadata Loading ===
  function loadProjects() {
    if (!root.taskwarriorAvailable) return;
    projectsProcess.command = ["task", "_projects"];
    projectsProcess.running = true;
  }

  Process {
    id: projectsProcess
    stdout: StdioCollector {
      onStreamFinished: {
        var rawText = String(text || "").trim();
        if (!rawText || rawText === "") {
          root.cachedProjects = [];
          return;
        }
        var lines = rawText.split("\n");
        var projects = [];
        for (var i = 0; i < lines.length; i++) {
          var line = lines[i].trim();
          if (line !== "") {
            projects.push(line);
          }
        }
        root.cachedProjects = projects;
        Logger.d("Taskwarrior", "Loaded " + projects.length + " projects");
      }
    }
    stderr: StdioCollector {}
  }

  function loadTags() {
    if (!root.taskwarriorAvailable) return;
    tagsProcess.command = ["task", "_tags"];
    tagsProcess.running = true;
  }

  Process {
    id: tagsProcess
    stdout: StdioCollector {
      onStreamFinished: {
        var rawText = String(text || "").trim();
        if (!rawText || rawText === "") {
          root.cachedTags = [];
          return;
        }
        var lines = rawText.split("\n");
        var tags = [];
        for (var i = 0; i < lines.length; i++) {
          var line = lines[i].trim();
          if (line !== "") {
            tags.push(line);
          }
        }
        root.cachedTags = tags;
        Logger.d("Taskwarrior", "Loaded " + tags.length + " tags");
      }
    }
    stderr: StdioCollector {}
  }
```

**Step 2:** Verifikation: Shell neustarten, im Log müssen "Loaded N projects" und "Loaded N tags" erscheinen.

**Step 3:** Commit: `git add taskwarrior/Main.qml && git commit -m "feat(taskwarrior): add project and tag metadata loading via task _projects and _tags"`

---

### Task 6: BarWidget.qml

**Files:** Create: `taskwarrior/BarWidget.qml`

**Step 1:** BarWidget mit konfigurierbarem Counter, Active-Task-Indikator, Overdue-Highlight und Kontextmenü. Pattern: todo/BarWidget.qml für Layout.

```qml
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
    if (counterType === "overdue") return String(overdueCount);
    return String(pendingCount);
  }

  readonly property color contentColor: {
    if (hasOverdue) return Color.mError;
    if (mouseArea.containsMouse) return Color.mOnHover;
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

    onTriggered: function(action) {
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

    onClicked: function(mouse) {
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
```

**Step 2:** Verifikation: Noctalia neustarten, BarWidget zur Bar hinzufügen. Counter muss die Anzahl pending Tasks anzeigen. Rechtsklick muss Kontextmenü öffnen.

**Step 3:** Commit: `git add taskwarrior/BarWidget.qml && git commit -m "feat(taskwarrior): add BarWidget with configurable counter, active indicator, and context menu"`

---

### Task 7: Panel.qml — Basis-Layout

**Files:** Create: `taskwarrior/Panel.qml`

**Step 1:** Panel-Grundgerüst mit Header (Refresh/Settings), Status-Bar, Pflicht-Properties und onVisibleChanged-Refresh.

```qml
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

      // === Filter-Bar (Task 8) ===
      // Placeholder

      // === Task Input (Task 9) ===
      // Placeholder

      // === Task List (Task 10) ===
      // Placeholder

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

  // === Placeholder functions for dialogs (Tasks 11-12) ===
  function openDetailDialog(uuid) {}
  function openDeleteDialog(uuid, description) {}
  function addNewTask() {}
}
```

**Step 2:** Verifikation: Panel über BarWidget öffnen. Header mit Refresh/Settings und Status-Bar müssen sichtbar sein.

**Step 3:** Commit: `git add taskwarrior/Panel.qml && git commit -m "feat(taskwarrior): add Panel.qml base layout with header, status bar, and panel-open refresh"`

---

### Task 8: Panel.qml — Filter-Bar

**Files:** Edit: `taskwarrior/Panel.qml`

**Step 1:** Den Placeholder `// Placeholder` für die Filter-Bar ersetzen. NComboBox für Status/Project/Priority/Due, Suchfeld und Reset-Button.

Ersetze `// === Filter-Bar (Task 8) ===` und `// Placeholder`:

```qml
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
```

**Step 2:** Verifikation: Panel öffnen, Filter-Dropdowns testen. Status ändern → Task-Liste aktualisiert sich. Reset-Button setzt alles zurück.

**Step 3:** Commit: `git add taskwarrior/Panel.qml && git commit -m "feat(taskwarrior): add filter bar with status, project, priority, due dropdowns and filter chips"`

---

### Task 9: Panel.qml — Task-Eingabe

**Files:** Edit: `taskwarrior/Panel.qml`

**Step 1:** Den Placeholder für Task Input ersetzen. Felder für Description, Project, Priority und Add-Button.

Ersetze `// === Task Input (Task 9) ===` und `// Placeholder`:

```qml
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
```

Ersetze die Placeholder-Funktion `addNewTask`:

```qml
  function addNewTask() {
    var desc = newTaskInput.text.trim();
    if (!desc || !mainInstance) return;
    mainInstance.addTask(desc, newTaskProject.text.trim(), newTaskPriorityGroup.currentPriority, "", "");
    newTaskInput.text = "";
    newTaskPriorityGroup.currentPriority = pluginApi?.pluginSettings?.defaultPriority || "";
  }
```

**Step 2:** Verifikation: Panel öffnen, Task-Beschreibung eingeben, Add-Button klicken. `task list` zeigt neuen Task.

**Step 3:** Commit: `git add taskwarrior/Panel.qml && git commit -m "feat(taskwarrior): add task input row with description, project, priority selector"`

---

### Task 10: Panel.qml — Task-Liste

**Files:** Edit: `taskwarrior/Panel.qml`

**Step 1:** Den Placeholder für die Task List ersetzen. ListView mit Task-Item Delegates, Priority/Due Badges, Action Buttons.

Ersetze `// === Task List (Task 10) ===` und `// Placeholder`:

```qml
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
```

**Step 2:** Verifikation: Panel öffnen, Tasks als Liste mit Priority/Due Badges und Action Buttons sichtbar. Complete-Checkbox, Start/Stop klickbar.

**Step 3:** Commit: `git add taskwarrior/Panel.qml && git commit -m "feat(taskwarrior): add task list with priority/due badges, action buttons, and empty state"`

---

### Task 11: Panel.qml — Detail-Dialog

**Files:** Edit: `taskwarrior/Panel.qml`

**Step 1:** Die Placeholder-Funktion `openDetailDialog` durch einen modalen Popup ersetzen. Alle editierbaren Felder, Annotations (read-only), Save/Cancel.

Ersetze `function openDetailDialog(uuid) {}`:

```qml
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
```

**Step 2:** Verifikation: Edit-Button bei einem Task klicken. Detail-Dialog zeigt alle Felder. Werte ändern und speichern → `task info <uuid>` zeigt Änderungen.

**Step 3:** Commit: `git add taskwarrior/Panel.qml && git commit -m "feat(taskwarrior): add detail dialog with editable fields for description, project, priority, due, tags, wait, scheduled"`

---

### Task 12: Panel.qml — Delete-Bestätigungs-Dialog

**Files:** Edit: `taskwarrior/Panel.qml`

**Step 1:** Die Placeholder-Funktion `openDeleteDialog` durch einen Bestätigungsdialog ersetzen.

Ersetze `function openDeleteDialog(uuid, description) {}`:

```qml
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
```

**Step 2:** Verifikation: Delete-Button klicken → Bestätigungsdialog. Cancel = nichts passiert. Delete = Task wird entfernt.

**Step 3:** Commit: `git add taskwarrior/Panel.qml && git commit -m "feat(taskwarrior): add delete confirmation dialog"`

---

### Task 13: Settings.qml

**Files:** Create: `taskwarrior/Settings.qml`

**Step 1:** Settings-UI mit Counter-Typ, Active Indicator Toggle, Default-Projekt, Default-Priority und Hook Install/Remove Button.

```qml
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
      { key: "pending", name: pluginApi?.tr("settings.counter-pending") || "Pending tasks" },
      { key: "overdue", name: pluginApi?.tr("settings.counter-overdue") || "Overdue tasks" }
    ]
    onSelected: function(key) { root.valueBarWidgetCounter = key; }
  }

  NToggle {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.active-indicator-label") || "Active task indicator"
    description: pluginApi?.tr("settings.active-indicator-description") || "Show a colored dot when a task is started"
    checked: root.valueShowActiveIndicator
    onToggled: function(checked) { root.valueShowActiveIndicator = checked; }
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
      { key: "", name: pluginApi?.tr("settings.priority-none") || "None" },
      { key: "H", name: pluginApi?.tr("settings.priority-high") || "High" },
      { key: "M", name: pluginApi?.tr("settings.priority-medium") || "Medium" },
      { key: "L", name: pluginApi?.tr("settings.priority-low") || "Low" }
    ]
    onSelected: function(key) { root.valueDefaultPriority = key; }
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
      text: root.hookInstalled
        ? (pluginApi?.tr("settings.hook-status-installed") || "Hook installed")
        : (pluginApi?.tr("settings.hook-status-not-installed") || "Hook not installed")
      font.pointSize: Style.fontSizeS
      color: root.hookInstalled ? Color.mPrimary : Color.mOnSurfaceVariant
    }

    Item { Layout.fillWidth: true }

    NButton {
      text: root.hookInstalled
        ? (pluginApi?.tr("settings.hook-remove") || "Remove Hook")
        : (pluginApi?.tr("settings.hook-install") || "Install Hook")
      backgroundColor: root.hookInstalled ? Color.mError : Color.mPrimary
      textColor: root.hookInstalled ? Color.mOnError : Color.mOnPrimary
      onClicked: {
        if (mainInstance) {
          if (root.hookInstalled) mainInstance.removeHook();
          else mainInstance.installHook();
        }
      }
    }
  }

  function saveSettings() {
    if (!pluginApi) return;
    pluginApi.pluginSettings.barWidgetCounter = root.valueBarWidgetCounter;
    pluginApi.pluginSettings.showActiveIndicator = root.valueShowActiveIndicator;
    pluginApi.pluginSettings.defaultProject = root.valueDefaultProject;
    pluginApi.pluginSettings.defaultPriority = root.valueDefaultPriority;
    pluginApi.saveSettings();
  }
}
```

**Step 2:** Verifikation: Settings öffnen (Rechtsklick → Widget Settings). Alle Felder sichtbar und änderbar. Speichern und prüfen ob Werte übernommen werden.

**Step 3:** Commit: `git add taskwarrior/Settings.qml && git commit -m "feat(taskwarrior): add Settings.qml with counter type, defaults, and hook management UI"`

---

### Task 14: Hook-Script und Install/Remove Logik

**Files:** Create: `taskwarrior/hooks/on-exit-noctalia`, Edit: `taskwarrior/Main.qml`

**Step 1:** Hook-Script erstellen.

```bash
#!/bin/bash
# Taskwarrior on-exit hook: notify Noctalia Shell on task changes
qs -c noctalia-shell ipc call plugin:taskwarrior refresh &
exit 0
```

**Step 2:** Die Placeholder-Funktionen `installHook` und `removeHook` in Main.qml ersetzen. **Wichtig:** Hook-Pfad dynamisch via `task _get rc.data.location` ermitteln (TW 2.x: `~/.task/`, TW 3.x: `~/.local/share/task/`).

Ersetze die Placeholder-Funktionen:

```qml
  // === Hook Management ===
  property string hookDir: ""

  function detectHookDir() {
    hookDirProcess.command = ["task", "_get", "rc.data.location"];
    hookDirProcess.running = true;
  }

  Process {
    id: hookDirProcess
    stdout: StdioCollector {
      onStreamFinished: {
        var dir = String(text || "").trim();
        if (dir !== "") {
          // Expand ~ to $HOME
          if (dir.startsWith("~")) {
            dir = dir.replace("~", "");
            root.hookDir = "$HOME" + dir + "/hooks";
          } else {
            root.hookDir = dir + "/hooks";
          }
        } else {
          root.hookDir = "$HOME/.task/hooks";
        }
        Logger.d("Taskwarrior", "Hook directory: " + root.hookDir);
      }
    }
    stderr: StdioCollector {}
  }

  function installHook() {
    if (!pluginApi) return;
    if (root.hookDir === "") {
      detectHookDir();
      // Retry after detection — use a simple delay
      retryInstallTimer.running = true;
      return;
    }

    var hookSource = pluginApi.pluginDir + "/hooks/on-exit-noctalia";
    Logger.i("Taskwarrior", "Installing hook to " + root.hookDir);
    hookInstallProcess.command = ["sh", "-c",
      "mkdir -p " + root.hookDir + " && cp '" + hookSource + "' " + root.hookDir + "/on-exit-noctalia && chmod +x " + root.hookDir + "/on-exit-noctalia"
    ];
    hookInstallProcess.running = true;
  }

  function removeHook() {
    if (root.hookDir === "") {
      detectHookDir();
      retryRemoveTimer.running = true;
      return;
    }

    Logger.i("Taskwarrior", "Removing hook from " + root.hookDir);
    hookRemoveProcess.command = ["sh", "-c", "rm -f " + root.hookDir + "/on-exit-noctalia"];
    hookRemoveProcess.running = true;
  }

  Timer {
    id: retryInstallTimer
    interval: 500
    repeat: false
    onTriggered: root.installHook()
  }

  Timer {
    id: retryRemoveTimer
    interval: 500
    repeat: false
    onTriggered: root.removeHook()
  }

  Process {
    id: hookInstallProcess
    stdout: StdioCollector {}
    stderr: StdioCollector {}

    onExited: function(exitCode, exitStatus) {
      if (exitCode === 0) {
        if (pluginApi) {
          pluginApi.pluginSettings.hookInstalled = true;
          pluginApi.saveSettings();
        }
        ToastService.showNotice(pluginApi?.tr("main.hook-installed") || "Hook installed successfully");
        Logger.i("Taskwarrior", "Hook installed successfully");
      } else {
        var errText = String(hookInstallProcess.stderr.text || "").trim();
        ToastService.showError((pluginApi?.tr("main.hook-install-failed") || "Failed to install hook") + (errText ? ": " + errText : ""));
        Logger.e("Taskwarrior", "Hook install failed: " + errText);
      }
    }
  }

  Process {
    id: hookRemoveProcess
    stdout: StdioCollector {}
    stderr: StdioCollector {}

    onExited: function(exitCode, exitStatus) {
      if (exitCode === 0) {
        if (pluginApi) {
          pluginApi.pluginSettings.hookInstalled = false;
          pluginApi.saveSettings();
        }
        ToastService.showNotice(pluginApi?.tr("main.hook-removed") || "Hook removed successfully");
        Logger.i("Taskwarrior", "Hook removed successfully");
      } else {
        var errText = String(hookRemoveProcess.stderr.text || "").trim();
        ToastService.showError((pluginApi?.tr("main.hook-remove-failed") || "Failed to remove hook") + (errText ? ": " + errText : ""));
        Logger.e("Taskwarrior", "Hook remove failed: " + errText);
      }
    }
  }
```

Ergänze den Aufruf von `detectHookDir()` in `checkTaskwarrior`'s onExited Callback (nach `root.refreshAll()`):

```qml
    // In checkProcess.onExited, nach refreshAll():
    root.detectHookDir();
```

**Step 3:** Verifikation:
- `chmod +x taskwarrior/hooks/on-exit-noctalia`
- Settings → "Install Hook" klicken
- `task diagnostics` — Hook muss gelistet sein
- `task add "Hook Test"` — im Plugin-Log muss "Loaded N tasks" erscheinen
- Settings → "Remove Hook" klicken → Hook entfernt

**Step 4:** Commit: `git add taskwarrior/hooks/on-exit-noctalia taskwarrior/Main.qml && git commit -m "feat(taskwarrior): add on-exit hook script with dynamic path detection and install/remove logic"`

---

### Task 15: i18n en.json

**Files:** Create: `taskwarrior/i18n/en.json`

**Step 1:** Englische Basisübersetzung mit allen Translation Keys.

```json
{
  "bar_widget": {
    "refresh": "Refresh",
    "settings": "Widget Settings",
    "stop-active": "Stop active task"
  },
  "main": {
    "task-added": "Task added",
    "task-completed": "Task completed",
    "task-deleted": "Task deleted",
    "task-modified": "Task modified",
    "task-started": "Task started",
    "task-stopped": "Task stopped",
    "error-empty-description": "Description cannot be empty",
    "error-action-failed": "Action failed",
    "error-add-failed": "Failed to add task",
    "error-complete-failed": "Failed to complete task",
    "error-delete-failed": "Failed to delete task",
    "error-modify-failed": "Failed to modify task",
    "error-start-failed": "Failed to start task",
    "error-stop-failed": "Failed to stop task",
    "hook-installed": "Hook installed successfully",
    "hook-removed": "Hook removed successfully",
    "hook-install-failed": "Failed to install hook",
    "hook-remove-failed": "Failed to remove hook"
  },
  "panel": {
    "header-title": "Taskwarrior",
    "refresh-tooltip": "Refresh tasks",
    "settings-tooltip": "Open settings",
    "status-tasks": "tasks",
    "status-overdue": "overdue",
    "status-unavailable": "Taskwarrior not found",
    "empty-state": "No tasks found",
    "filter-status-label": "Status",
    "filter-status-pending": "Pending",
    "filter-status-completed": "Completed",
    "filter-status-waiting": "Waiting",
    "filter-status-all": "All",
    "filter-project-label": "Project",
    "filter-project-all": "All projects",
    "filter-priority-label": "Priority",
    "filter-priority-all": "All",
    "filter-due-label": "Due",
    "filter-due-any": "Any",
    "filter-due-today": "Today",
    "filter-due-week": "This week",
    "filter-due-overdue": "Overdue",
    "filter-reset-tooltip": "Reset all filters",
    "search-placeholder": "Search tasks...",
    "input-description-placeholder": "Add a new task...",
    "input-project-placeholder": "Project",
    "priority-none": "None",
    "priority-high": "High",
    "priority-medium": "Medium",
    "priority-low": "Low",
    "due-overdue": "Overdue",
    "due-today": "Today",
    "due-tomorrow": "Tomorrow",
    "action-start": "Start",
    "action-stop": "Stop",
    "action-edit": "Edit",
    "action-delete": "Delete",
    "detail-title": "Task Details",
    "detail-description-label": "Description",
    "detail-project-label": "Project",
    "detail-project-placeholder": "e.g. work",
    "detail-priority-label": "Priority",
    "detail-due-label": "Due",
    "detail-due-placeholder": "e.g. 2026-03-01, tomorrow, eow",
    "detail-tags-label": "Tags",
    "detail-tags-placeholder": "e.g. urgent, review",
    "detail-wait-label": "Wait",
    "detail-wait-placeholder": "e.g. 2026-03-01, tomorrow",
    "detail-scheduled-label": "Scheduled",
    "detail-scheduled-placeholder": "e.g. monday, 2026-03-01",
    "detail-annotations-label": "Annotations",
    "detail-cancel": "Cancel",
    "detail-save": "Save",
    "delete-confirm-title": "Delete Task?",
    "delete-cancel": "Cancel",
    "delete-confirm": "Delete"
  },
  "settings": {
    "section-bar-widget": "Bar Widget",
    "counter-type-label": "Counter type",
    "counter-type-description": "Which count to show in the bar widget",
    "counter-pending": "Pending tasks",
    "counter-overdue": "Overdue tasks",
    "active-indicator-label": "Active task indicator",
    "active-indicator-description": "Show a colored dot when a task is started",
    "section-defaults": "Defaults",
    "default-project-label": "Default project",
    "default-project-description": "Pre-filled project when adding new tasks",
    "default-project-placeholder": "e.g. work",
    "default-priority-label": "Default priority",
    "default-priority-description": "Pre-selected priority when adding new tasks",
    "priority-none": "None",
    "priority-high": "High",
    "priority-medium": "Medium",
    "priority-low": "Low",
    "section-hook": "Taskwarrior Hook",
    "hook-description": "Install an on-exit hook to automatically refresh the plugin when tasks change via the CLI.",
    "hook-status-installed": "Hook installed",
    "hook-status-not-installed": "Hook not installed",
    "hook-install": "Install Hook",
    "hook-remove": "Remove Hook"
  }
}
```

**Step 2:** Verifikation: `python3 -m json.tool taskwarrior/i18n/en.json` — muss valides JSON sein.

**Step 3:** Commit: `git add taskwarrior/i18n/en.json && git commit -m "i18n(taskwarrior): add en.json baseline with all translation keys"`

---

### Task 16: Registry Update

**Files:** Auto-generated: `registry.json`

**Step 1:** Registry-Update-Script ausführen.

```bash
node .github/workflows/update-registry.js
```

**Step 2:** Verifikation: `grep -A 5 '"taskwarrior"' registry.json` — Eintrag muss vorhanden sein.

**Step 3:** Commit: `git add registry.json && git commit -m "chore(taskwarrior): update registry for v1.0.0"`

---

### Task 17: Finale Verifikation und Cleanup

**Files:** Alle Dateien im `taskwarrior/`-Verzeichnis

**Step 1:** Vollständige Verifikation:

1. **Strukturprüfung:**
   ```bash
   ls -la taskwarrior/
   ls -la taskwarrior/hooks/
   ls -la taskwarrior/i18n/
   ```
   Erwartete Dateien: `manifest.json`, `Main.qml`, `BarWidget.qml`, `Panel.qml`, `Settings.qml`, `hooks/on-exit-noctalia`, `i18n/en.json`

2. **JSON-Validierung:**
   ```bash
   python3 -m json.tool taskwarrior/manifest.json
   python3 -m json.tool taskwarrior/i18n/en.json
   ```

3. **Hook-Permissions:**
   ```bash
   test -x taskwarrior/hooks/on-exit-noctalia && echo "OK" || echo "FAIL"
   ```

4. **Funktionsprüfung (manuell):**
   - Noctalia Shell neustarten mit `NOCTALIA_DEBUG=1`
   - Plugin aktivieren
   - BarWidget zur Bar hinzufügen
   - Panel öffnen: Tasks angezeigt
   - Filter ändern: Tasks aktualisieren sich
   - Task hinzufügen: Erscheint in der Liste
   - Task starten/stoppen: Active-Indikator im BarWidget
   - Task editieren: Detail-Dialog, Änderungen gespeichert
   - Task löschen: Bestätigungsdialog, dann Löschung
   - Hook installieren: `task add "Hook Test"` triggert Refresh
   - Hook entfernen: Keine automatischen Refreshes mehr
   - Settings: Alle Optionen funktionieren

5. **IPC-Tests:**
   ```bash
   qs -c noctalia-shell ipc call plugin:taskwarrior refresh
   qs -c noctalia-shell ipc call plugin:taskwarrior addTask "IPC Test" "" "M" "" ""
   qs -c noctalia-shell ipc call plugin:taskwarrior togglePanel
   ```

**Step 2:** Hook executable machen: `chmod +x taskwarrior/hooks/on-exit-noctalia`
