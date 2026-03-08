# Launcher Provider Reference

Launcher providers extend the app launcher with custom search sources, command handlers,
and browsable content categories. Requires Noctalia Shell 3.9.0+.

## Required Properties

```qml
property var pluginApi: null   // Plugin API
property var launcher: null    // Reference to Launcher panel (injected)
property string name: ""       // Display name for the provider
```

## Essential Functions

### init()

Setup when provider registers:

```qml
function init() {
    // Load data, initialize state
}
```

### handleCommand(searchText)

Returns boolean — whether this provider handles the current input:

```qml
function handleCommand(searchText) {
    return searchText.startsWith(">myprefix ")
}
```

### commands()

Returns available commands shown when user types `>`:

```qml
function commands() {
    return [{
        name: ">myprefix",
        description: "Search my data",
        icon: "search",
        isTablerIcon: true,
        onActivate: function() {
            launcher.searchText = ">myprefix "
        }
    }]
}
```

### getResults(searchText)

Returns matching results:

```qml
function getResults(searchText) {
    let query = searchText.replace(">myprefix ", "").trim()
    return filteredItems.map(item => ({
        name: item.title,
        description: item.subtitle,
        icon: "file",
        isTablerIcon: true,
        singleLine: false,
        onActivate: function() {
            // action on selection
        }
    }))
}
```

## Result Object Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | string | Display title |
| `description` | string | Subtitle text |
| `icon` | string | Icon name |
| `isTablerIcon` | bool | Whether icon is a Tabler icon |
| `displayString` | string | Alternative display text |
| `hideIcon` | bool | Hide the icon |
| `singleLine` | bool | Single-line display mode |
| `onActivate` | function | Callback when result is selected |
| `onAutoPaste` | function | Callback for auto-paste action |
| `autoPasteText` | string | Text for clipboard operations |

## Optional Properties

```qml
property bool handleSearch: false           // Participate in standard search
property string supportedLayouts: "both"    // "both", "list", "grid"
property var categories: []                 // Browsable category groups
property bool supportsAutoPaste: false      // Enable clipboard paste
property int preferredGridColumns: 0        // Grid layout columns
```

### Categories

```qml
property var categories: [
    { name: "Category 1", icon: "folder" },
    { name: "Category 2", icon: "star" }
]

function selectCategory(category) {
    // Load items for selected category
}

function getCategoryName(category) {
    return category.name
}
```

## IPC Integration

Toggle launcher with plugin prefix from keybindings:

```qml
// In Main.qml
IpcHandler {
    target: "plugin:my-provider"
    function toggle() {
        pluginApi.withCurrentScreen(screen => {
            pluginApi.toggleLauncher(screen)
        })
    }
}
```

## Manifest Registration

```json
{
  "entryPoints": {
    "launcherProvider": "LauncherProvider.qml"
  },
  "metadata": {
    "commandPrefix": "myprefix"
  }
}
```

The `commandPrefix` defines the `>prefix` command. Defaults to plugin ID if not set.
