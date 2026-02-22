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
  property int hookRetryCount: 0

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
    checkProcess.command = ["task", "rc.hooks=0", "--version"];
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
        root.detectHookDir();
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

  // === UUID Validation ===
  function isValidUuid(uuid) {
    return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(String(uuid));
  }

  // === Filter Engine ===
  function buildFilterCommand(filter) {
    var parts = ["task", "rc.hooks=0", "rc.json.array=on"];

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
    counterProcess.command = ["task", "rc.hooks=0", "rc.json.array=on", "status:pending", "export"];
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

    var cmd = ["task", "add"];

    var prio = priority || (pluginApi?.pluginSettings?.defaultPriority || "");
    if (prio && String(prio).trim() !== "") {
      prio = String(prio).trim().toUpperCase();
      if (["H", "M", "L"].indexOf(prio) === -1) {
        Logger.w("Taskwarrior", "Invalid priority: " + prio);
        return;
      }
      cmd.push("priority:" + prio);
    }

    var proj = project || (pluginApi?.pluginSettings?.defaultProject || "");
    if (proj && String(proj).trim() !== "") {
      proj = String(proj).trim();
      if (!/^[a-zA-Z0-9._-]+$/.test(proj)) {
        Logger.w("Taskwarrior", "Invalid project name: " + proj);
        return;
      }
      cmd.push("project:" + proj);
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

    // -- separator prevents description from being parsed as attributes
    cmd.push("--");
    cmd.push(String(description).trim());

    runAction(cmd,
      pluginApi?.tr("main.task-added") || "Task added",
      pluginApi?.tr("main.error-add-failed") || "Failed to add task"
    );
  }

  function completeTask(uuid) {
    if (!root.taskwarriorAvailable || !uuid) return;
    if (!isValidUuid(uuid)) return;
    runAction(
      ["task", String(uuid), "done"],
      pluginApi?.tr("main.task-completed") || "Task completed",
      pluginApi?.tr("main.error-complete-failed") || "Failed to complete task"
    );
  }

  function deleteTask(uuid) {
    if (!root.taskwarriorAvailable || !uuid) return;
    if (!isValidUuid(uuid)) return;
    runAction(
      ["task", "rc.confirmation=off", String(uuid), "delete"],
      pluginApi?.tr("main.task-deleted") || "Task deleted",
      pluginApi?.tr("main.error-delete-failed") || "Failed to delete task"
    );
  }

  function modifyTask(uuid, field, value) {
    if (!root.taskwarriorAvailable || !uuid || !field) return;
    if (!isValidUuid(uuid)) return;

    var allowedFields = ["description", "project", "priority", "due", "wait", "scheduled", "recur", "until", "tags"];
    if (allowedFields.indexOf(String(field)) === -1) {
      Logger.w("Taskwarrior", "Blocked modify attempt with disallowed field: " + field);
      return;
    }

    var cmd;
    if (field === "tags") {
      // Tags require special handling: value is "+tag" or "-tag"
      var tagValue = String(value);
      if (!/^[+-][a-zA-Z0-9_-]+$/.test(tagValue)) {
        Logger.w("Taskwarrior", "Blocked invalid tag value: " + value);
        return;
      }
      cmd = ["task", String(uuid), "modify", tagValue];
    } else {
      cmd = ["task", String(uuid), "modify", String(field) + ":" + String(value)];
    }

    runAction(cmd,
      pluginApi?.tr("main.task-modified") || "Task modified",
      pluginApi?.tr("main.error-modify-failed") || "Failed to modify task"
    );
  }

  function batchModifyTask(uuid, modifications) {
    if (!root.taskwarriorAvailable || !uuid) return;
    if (!isValidUuid(uuid)) return;

    var allowedFields = ["description", "project", "priority", "due", "wait", "scheduled", "recur", "until"];
    var cmd = ["task", String(uuid), "modify"];

    for (var i = 0; i < modifications.length; i++) {
      var mod = modifications[i];
      if (mod.field === "tags") {
        var tagValue = String(mod.value);
        if (/^[+-][a-zA-Z0-9_-]+$/.test(tagValue)) {
          cmd.push(tagValue);
        }
      } else if (allowedFields.indexOf(String(mod.field)) !== -1) {
        cmd.push(String(mod.field) + ":" + String(mod.value));
      }
    }

    if (cmd.length <= 3) return;

    runAction(cmd,
      pluginApi?.tr("main.task-modified") || "Task modified",
      pluginApi?.tr("main.error-modify-failed") || "Failed to modify task"
    );
  }

  function startTask(uuid) {
    if (!root.taskwarriorAvailable || !uuid) return;
    if (!isValidUuid(uuid)) return;
    runAction(
      ["task", String(uuid), "start"],
      pluginApi?.tr("main.task-started") || "Task started",
      pluginApi?.tr("main.error-start-failed") || "Failed to start task"
    );
  }

  function stopTask(uuid) {
    if (!root.taskwarriorAvailable || !uuid) return;
    if (!isValidUuid(uuid)) return;
    runAction(
      ["task", String(uuid), "stop"],
      pluginApi?.tr("main.task-stopped") || "Task stopped",
      pluginApi?.tr("main.error-stop-failed") || "Failed to stop task"
    );
  }

  // === Metadata Loading ===
  function loadProjects() {
    if (!root.taskwarriorAvailable) return;
    projectsProcess.command = ["task", "rc.hooks=0", "_projects"];
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
    tagsProcess.command = ["task", "rc.hooks=0", "_tags"];
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

  // === Hook Management ===
  property string hookDir: ""

  function detectHookDir() {
    hookDirProcess.command = ["task", "rc.hooks=0", "_get", "rc.data.location"];
    hookDirProcess.running = true;
  }

  Process {
    id: hookDirProcess
    stdout: StdioCollector {
      onStreamFinished: {
        var dir = String(text || "").trim();
        if (dir !== "") {
          if (dir.startsWith("~")) {
            dir = dir.replace(/^~/, "");
            homeProcess.pendingDir = dir;
            homeProcess.command = ["sh", "-c", "echo $HOME"];
            homeProcess.running = true;
            return;
          }
          root.hookDir = dir + "/hooks";
          root.hookRetryCount = 0;
        } else {
          homeProcess.pendingDir = "/.task";
          homeProcess.command = ["sh", "-c", "echo $HOME"];
          homeProcess.running = true;
          return;
        }
        Logger.d("Taskwarrior", "Hook directory: " + root.hookDir);
      }
    }
    stderr: StdioCollector {}
  }

  Process {
    id: homeProcess
    property string pendingDir: ""
    stdout: StdioCollector {
      onStreamFinished: {
        var home = String(text || "").trim();
        if (home !== "") {
          root.hookDir = home + homeProcess.pendingDir + "/hooks";
        } else {
          root.hookDir = "/tmp/taskwarrior-hooks";
        }
        root.hookRetryCount = 0;
        Logger.d("Taskwarrior", "Hook directory (resolved): " + root.hookDir);
      }
    }
    stderr: StdioCollector {}
  }

  function installHook() {
    if (!pluginApi) return;
    if (root.hookDir === "") {
      if (root.hookRetryCount >= 3) {
        Logger.e("Taskwarrior", "Hook directory detection failed after 3 retries");
        return;
      }
      root.hookRetryCount++;
      detectHookDir();
      retryInstallTimer.running = true;
      return;
    }

    var hookSource = pluginApi.pluginDir + "/hooks/on-exit-noctalia";
    var targetDir = root.hookDir;
    var targetFile = targetDir + "/on-exit-noctalia";
    Logger.i("Taskwarrior", "Installing hook to " + targetDir);
    hookInstallProcess.command = ["bash", "-c",
      'mkdir -p "$1" && cp "$2" "$3" && chmod +x "$3"',
      "_", targetDir, hookSource, targetFile
    ];
    hookInstallProcess.running = true;
  }

  function removeHook() {
    if (root.hookDir === "") {
      if (root.hookRetryCount >= 3) {
        Logger.e("Taskwarrior", "Hook directory detection failed after 3 retries");
        return;
      }
      root.hookRetryCount++;
      detectHookDir();
      retryRemoveTimer.running = true;
      return;
    }

    var targetFile = root.hookDir + "/on-exit-noctalia";
    Logger.i("Taskwarrior", "Removing hook from " + root.hookDir);
    hookRemoveProcess.command = ["rm", "-f", targetFile];
    hookRemoveProcess.running = true;
  }

  Timer {
    id: refreshDebounceTimer
    interval: 300
    repeat: false
    onTriggered: root.refreshAll()
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
      refreshDebounceTimer.restart();
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
}
