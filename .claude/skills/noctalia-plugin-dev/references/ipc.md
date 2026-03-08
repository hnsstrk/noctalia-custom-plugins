# IPC (Inter-Process Communication) Reference

IPC allows external scripts, keybindings, and tools to trigger plugin actions.

## Handler Registration (in Main.qml)

```qml
import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Services.UI

Item {
    property var pluginApi: null

    IpcHandler {
        target: "plugin:my-plugin-id"    // Must match manifest id

        function myCommand(param: string) {
            // All IPC arguments are STRINGS — parse explicitly
            let value = parseInt(param)
            if (isNaN(value)) {
                Logger.e("MyPlugin", "Invalid param:", param)
                return
            }
            // ... process command
        }

        function showPanel() {
            pluginApi.withCurrentScreen(screen => {
                pluginApi.openPanel(screen)
            })
        }

        function toggle() {
            pluginApi.withCurrentScreen(screen => {
                pluginApi.togglePanel(screen)
            })
        }
    }
}
```

## Calling IPC from Shell

```bash
qs -c noctalia-shell ipc call plugin:my-plugin-id myCommand "param"
qs -c noctalia-shell ipc call plugin:my-plugin-id showPanel
```

## Critical: Parameters are Always Strings

All IPC arguments arrive as strings. Always parse and validate:

```qml
function setCount(countStr: string) {
    let count = parseInt(countStr)
    if (isNaN(count) || count < 0) {
        Logger.e("Plugin", "Invalid count:", countStr)
        return
    }
    // use count...
}
```

## Screen Context

For panel/launcher operations in IPC handlers, use `withCurrentScreen`:

```qml
function showPanel() {
    pluginApi.withCurrentScreen(screen => {
        pluginApi.openPanel(screen)
    })
}
```

## User Feedback

Use ToastService for operation confirmation:

```qml
function doAction(param: string) {
    // ... perform action
    ToastService.showNotice("Action completed: " + param)
}
```

## Security Best Practices

1. Always validate and parse input parameters
2. Check argument counts before processing
3. Null-check `pluginApi` before use
4. Use parameterized arrays for CLI commands (`["task", arg]`), never `sh -c` strings
5. Implement debouncing for burst-prone IPC calls:

```qml
Timer {
    id: debounceTimer
    interval: 300
    onTriggered: actualHandler()
}

function ipcMethod(param: string) {
    pendingParam = param
    debounceTimer.restart()  // restart() not start()
}
```

## Manifest Registration

IPC handlers live in `Main.qml`:

```json
{
  "entryPoints": {
    "main": "Main.qml"
  }
}
```
