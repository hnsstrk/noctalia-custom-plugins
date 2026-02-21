# Taskwarrior Plugin — Design Document

**Date:** 2026-02-21
**Author:** hnsstrk
**Status:** Approved
**Version:** MVP → Iterative

## Overview

A full-featured Taskwarrior client plugin for Noctalia Shell. Uses server-side filtering (Taskwarrior CLI) for all queries and provides a filter-based UI instead of tab-based navigation.

## Starting Point

To create a compliant plugin, start with the Hello World plugin from the repository and adapt: https://github.com/noctalia-dev/noctalia-plugins/tree/main/hello-world

## Sources

- https://github.com/noctalia-dev/noctalia-shell
- https://docs.noctalia.dev/
  - https://docs.noctalia.dev/getting-started/compositor-settings/niri/
  - https://docs.noctalia.dev/getting-started/running-the-shell/
  - https://docs.noctalia.dev/development/guideline/
  - https://docs.noctalia.dev/development/plugins/getting-started/
  - https://docs.noctalia.dev/development/plugins/panel/
  - https://docs.noctalia.dev/development/plugins/settings-ui/
  - https://docs.noctalia.dev/development/plugins/api/
  - https://docs.noctalia.dev/development/plugins/ipc/
  - https://docs.noctalia.dev/development/plugins/manifest/
  - https://docs.noctalia.dev/development/plugins/translations/
- https://github.com/noctalia-dev/noctalia-plugins
- https://github.com/GothenburgBitFactory/taskwarrior
  - https://taskwarrior.org/docs/hooks_guide/
  - https://taskwarrior.org/docs/hooks/
  - https://taskwarrior.org/docs/hooks2/
  - https://taskwarrior.org/docs/3rd-party/
  - https://taskwarrior.org/docs/sync/
  - https://taskwarrior.org/docs/upgrade-3/
  - https://github.com/GothenburgBitFactory/taskwarrior/tree/develop/doc/devel/rfcs

## Architecture

### Approach: Server-side Filtering

Every filter change triggers a new `task <filter> export` CLI call. This leverages Taskwarrior's native filter engine and scales to large task databases.

**Trade-offs:**
- (+) Full Taskwarrior filter power
- (+) Scales with large databases
- (-) CLI latency on filter changes
- (-) Race condition handling required

### Data Flow

```
User changes filter
    → buildFilterCommand(filter)
    → Process executes: task <filter> export
    → JSON output parsed
    → requestId validated (discard stale results)
    → ListModel updated
    → UI re-renders
```

### Update-Mechanismus

Das Plugin verwendet **kein Polling**. Stattdessen ein Drei-Schichten-Modell:

**Schicht 1: on-exit Hook (Primär)**
- Feuert bei jedem lokalen `task`-Befehl (auch read-only wie `task list`)
- Sendet IPC-Signal an Plugin → Plugin führt `task export` aus
- Deckt ab: JEDE Operation — add, done, delete, modify, start, stop, annotate, import, sync, undo, und auch read-only Befehle wie `task list`

**Schicht 2: Refresh bei Panel-Öffnung**
- `onVisibleChanged` in Panel.qml triggert Daten-Reload
- Stellt sicher dass das Panel immer aktuelle Daten zeigt
- Fängt Fälle ab die der Hook nicht abdeckt (z.B. nach `task sync`)
- Kosten: minimal (ein `task export` < 100ms)
- Dieses Pattern verwenden auch andere Noctalia-Plugins (rss-feed, weekly-calendar, clipper)

**Schicht 3: Manueller Refresh**
- Refresh-Button im Panel-Header
- IPC-Kommando: `qs -c noctalia-shell ipc call plugin:taskwarrior refresh`

**Kein Polling-Timer** — Die Kombination aus Hook + Panel-Open-Refresh + manueller Refresh deckt alle relevanten Szenarien ab.

**Bekannte Lücke:** `task sync` (eingehende Tasks von anderen Geräten) triggert weder on-add noch on-modify für die synchronisierten Tasks (offenes Issue #2142 seit 2017). Dies wird durch Schicht 2 (Panel-Open-Refresh) abgefangen. Wenn der Benutzer `task sync` ausführt, feuert zumindest on-exit — aber die synchronisierten Tasks selbst lösen keine Daten-Hooks aus.

## Components

### manifest.json

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

**Hinweis `tags`:** Das Feld ist nicht in der offiziellen Manifest-Dokumentation aufgeführt, wird aber von allen Plugins im Repository und dem Registry-Script (`update-registry.js`) verwendet.

### Main.qml — Data Layer

**Properties:**
- `currentFilter: {}` — Active filter object (`{project, priority, tags[], status, due}`)
- `cachedTasks: []` — Result of last export
- `cachedProjects: []` — For filter dropdowns (loaded via `task _projects`)
- `cachedTags: []` — For filter dropdowns (loaded via `task _tags`)
- `taskwarriorAvailable: bool`

**Processes:**
- `exportProcess` — Main export with dynamic filter command
- `metadataProcess` — Load projects/tags once (`task _projects`, `task _tags`)
- `actionProcess` — Universal write operations (add, done, delete, modify, start, stop, annotate)
- `hookCheckProcess` / `hookInstallProcess` — Hook management

**Process Pattern (StdioCollector):**

```qml
Process {
    id: exportProcess
    command: [...]
    stdout: StdioCollector {
        onStreamFinished: {
            let data = JSON.parse(text);
            // process data...
        }
    }
}
```

**Filter Builder:**
```js
function buildFilterCommand(filter) {
    let parts = ["task", "rc.json.array=on"];
    if (filter.project) parts.push(`project:${filter.project}`);
    if (filter.priority) parts.push(`priority:${filter.priority}`);
    if (filter.tags) filter.tags.forEach(t => parts.push(`+${t}`));
    if (filter.status) parts.push(`status:${filter.status}`);
    if (filter.due) parts.push(`due:${filter.due}`);
    parts.push("export");
    return parts.join(" ");
}
```

**Race Condition Handling:** A `requestId` counter increments on each export call. When an older export returns after the current request, its result is discarded.

**IPC Handler (target: `plugin:taskwarrior`):**
- `togglePanel()`, `refresh()`
- `addTask(description, project, priority, due, tags)`
- `completeTask(uuid)`, `deleteTask(uuid)`
- `startTask(uuid)`, `stopTask(uuid)`
- `modifyTask(uuid, field, value)`
- `installHook()`, `removeHook()`

**Hinweis:** IPC-Parameter sind immer Strings — explizite Typkonvertierung ist nötig (z.B. `parseInt()`).

### Panel.qml — UI Layer

**Pflicht-Properties:**

```qml
property var pluginApi: null
readonly property var geometryPlaceholder: panelContainer
property real contentPreferredWidth: 750 * Style.uiScaleRatio
property real contentPreferredHeight: 550 * Style.uiScaleRatio
readonly property bool allowAttach: true
anchors.fill: parent
```

**Zugriff auf Main.qml:** `pluginApi.mainInstance` für direkten Zugriff auf Properties und Funktionen der Data Layer.

**Aktueller Screen:** `pluginApi.panelOpenScreen` liefert den Screen, auf dem das Panel geöffnet wurde.

**Panel-Steuerung:**
- `pluginApi.openPanel(screen, buttonItem?)` — Panel öffnen (`buttonItem` optional, für Positionierung)
- `pluginApi.closePanel(screen)` — Panel programmatisch schließen
- `pluginApi.togglePanel(screen)` — Panel umschalten

**Layout:**

```
┌─ Header ─────────────────────────────────────┐
│  TaskWarrior              [Refresh] [Settings]│
├─ Filter-Bar ─────────────────────────────────┤
│  [Status ▼] [Project ▼] [Priority ▼] [+Tag] │
│  [Due ▼] [Search...]             [× Reset]   │
├─ Active Filters (Chips) ─────────────────────┤
│  ● project:work  ● +urgent  ● priority:H  ×  │
├─ Task Input ─────────────────────────────────┤
│  [Description...] [Project] [Priority] [Add]  │
├─ Task List ──────────────────────────────────┤
│  ┌─ Task Item ──────────────────────────────┐│
│  │ [✓] Description           [P:H] [due:Mo]││
│  │     project:work  +urgent               ││
│  │     [▶Start] [✎Edit] [🗑Del]            ││
│  └──────────────────────────────────────────┘│
│  ┌─ Task Item ──────────────────────────────┐│
│  │ ...                                      ││
│  └──────────────────────────────────────────┘│
├─ Status Bar ─────────────────────────────────┤
│  42 tasks filtered · 3 overdue               │
└──────────────────────────────────────────────┘
```

**Filter-Bar:**
- Dropdowns: Status (pending/completed/waiting/all), Project, Priority, Due (today/week/overdue/any)
- Tag input with autocomplete from known tags
- Free-text search (filters description client-side on server result)
- Filter chips show active filters, clickable to remove
- Reset button clears all filters

**Task Item:**
- Compact layout: Checkbox + Description + Priority badge + Due badge
- Second row: Project + Tags as small labels
- Action buttons: Start/Stop, Edit (opens detail dialog), Delete (with confirmation)
- Color coding: Overdue tasks red, active tasks with indicator

**Detail Dialog:**
- Modal popup (like todo plugin pattern)
- Editable fields: Description, Project, Priority, Due, Tags, Wait, Scheduled, Depends
- Annotations: List + Add
- Start/Stop quick action
- Save/Cancel buttons

**Delete Confirmation:**
- Simple modal: "Delete task X?" with Cancel/Delete buttons

### BarWidget.qml — Status Bar

```
Idle:       [📋 12 tasks · 2 overdue]
Active:     [📋● 12 tasks · Working]
Vertical:   [📋]
                ●
```

- Configurable counter: pending / today / overdue / active
- Active indicator: colored dot when a task is started
- Overdue highlight: text/icon turns red when overdue tasks exist
- Hover: background color change
- Click: Left = open panel, Right = open settings

**Framework-injizierte Properties:**
- `property ShellScreen screen` — Der aktuelle Screen
- `property string widgetId` — Eindeutige Widget-ID
- `property string section: ""` — Section-Zuordnung (erforderlich, siehe hello-world)

**Referenz:** Das todo-Plugin (`todo/BarWidget.qml`) verwendet ein ähnliches BarWidget-Pattern mit Counter-Text — direkte Referenz für unser Plugin.

**Rechtsklick-Menü (NPopupContextMenu-Pattern):**

```qml
NPopupContextMenu {
    id: contextMenu
    model: [
        { text: pluginApi.tr("settings-label"), value: "settings" }
    ]
    onTriggered: function(item) {
        if (item.value === "settings") {
            BarService.openPluginSettings(root.screen, pluginApi.manifest);
        }
        contextMenu.close();
        PanelService.closeContextMenu(screen);
    }
}

// Im MouseArea/TapHandler:
// PanelService.showContextMenu(root.screen, contextMenu, root)
```

- `BarService.openPluginSettings(root.screen, pluginApi.manifest)` zum Öffnen der Settings

**Styling:**
- `Style.getCapsuleHeightForScreen(screen?.name)` für korrekte Höhe
- `Style.capsuleColor` für Hintergrundfarbe

### Settings.qml — Configuration

**Root-Element:** `ColumnLayout`

**Lokale State-Kopien Pattern:**

```qml
property var cfg: pluginApi?.pluginSettings || ({})
property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
property string barWidgetCounter: cfg.barWidgetCounter ?? defaults.barWidgetCounter
property bool showActiveIndicator: cfg.showActiveIndicator ?? defaults.showActiveIndicator
// ...
```

**saveSettings():** Wird vom Framework aufgerufen, kopiert lokale Werte zurück in `pluginApi.pluginSettings`:

```qml
function saveSettings() {
    if (!pluginApi) return;
    pluginApi.pluginSettings.barWidgetCounter = barWidgetCounter;
    // ...
    pluginApi.saveSettings();
}
```

**Verfügbare Framework-Widgets:** NTextInput, NToggle, NSpinBox, NComboBox, NButton, NDivider, NLabel, NCheckbox, NSlider, NColorPicker

| Setting | Type | Default | Range |
|---------|------|---------|-------|
| Bar Counter | NComboBox | pending | pending/today/overdue/active |
| Active Indicator | NToggle | true | — |
| Default Project | NTextInput | "" | — |
| Default Priority | NComboBox | none | none/H/M/L |
| Hook | NButton | not installed | install/remove |

### Hook System

**Hook-Verzeichnis:**
- Taskwarrior 2.x: `~/.task/hooks/`
- Taskwarrior 3.x: `~/.local/share/task/hooks/`
- **Dynamisch ermitteln** via `task _get rc.data.location` oder `task diagnostics`
- Das Plugin muss den Pfad zur Laufzeit ermitteln, nicht hart kodieren

#### Alle Hook-Typen

Taskwarrior kennt vier Hook-Typen, die an verschiedenen Stellen des Verarbeitungszyklus greifen:

| Hook | Auslöser | Input (stdin) | Output (stdout) | Kann abbrechen? | Kann Tasks ändern? |
|------|----------|---------------|-----------------|-----------------|-------------------|
| on-launch | Bei jedem TW-Start, vor Verarbeitung | Nichts | Kein JSON, nur Feedback | JA | NEIN |
| on-add | Bei neuem Task, vor Speicherung | 1 JSON-Zeile (neuer Task) | 1 JSON-Zeile + Feedback | JA | JA |
| on-modify | Bei Task-Änderung, vor Speicherung | 2 JSON-Zeilen (vorher/nachher) | 1 JSON-Zeile + Feedback | JA | JA |
| on-exit | Am Ende, nach aller Verarbeitung | 0+ JSON-Zeilen (betroffene Tasks) | Kein JSON, nur Feedback | NEIN | NEIN |

#### Hook-Matrix (welche Hooks feuern bei welcher Operation)

| Operation | on-launch | on-add | on-modify | on-exit |
|-----------|:---------:|:------:|:---------:|:-------:|
| task add | Ja | Ja | Nein | Ja |
| task done | Ja | Nein | Ja | Ja |
| task delete | Ja | Nein | Ja | Ja |
| task modify | Ja | Nein | Ja | Ja |
| task start | Ja | Nein | Ja | Ja |
| task stop | Ja | Nein | Ja | Ja |
| task annotate | Ja | Nein | Ja | Ja |
| task sync | Ja | Nein | NEIN! | Ja |
| task undo | Ja | Nein | Unzuverlässig | Ja |
| task list (read-only) | Ja | Nein | Nein | Ja |

Wichtig: `task done` und `task delete` sind STATUS-Änderungen und triggern daher on-modify, nicht on-add.

#### Hooks v2 API (ab Taskwarrior 2.4.3)

Hook-Skripte erhalten zusätzliche Kommandozeilen-Argumente:
- `api:2`, `args:task ...`, `command:add|done|modify|...`, `rc:<file>`, `data:<dir>`, `version:<x.y.z>`

#### Warum on-exit?

Wir nutzen einen on-exit Hook (statt on-add + on-modify), weil:
- on-exit läuft bei JEDER Operation (auch read-only, sync, undo)
- on-exit kann die Operation nicht abbrechen oder Tasks modifizieren — kein Risiko
- on-exit ist minimal-invasiv: nur IPC-Signal senden, kein JSON-Output nötig
- Das Plugin holt sich dann via `task export` die aktuellen Daten

#### Hook-Script

**Datei:** `hooks/on-exit-noctalia`

**Namensformat:** `on-exit-noctalia` — Die Collating-Sequence des Dateinamens bestimmt die Ausführungsreihenfolge bei mehreren Hooks.

```bash
#!/bin/bash
# Taskwarrior on-exit hook: notify Noctalia Shell on task changes
qs -c noctalia-shell ipc call plugin:taskwarrior refresh &
exit 0
```

Das `&` sorgt dafür, dass der IPC-Aufruf im Hintergrund läuft und Taskwarrior nicht blockiert wird.

**Anforderungen:**
- Muss executable sein (`chmod +x`)
- Exit-Code 0 = Erfolg (bei Fehler wird Taskwarrior den Benutzer warnen)
- on-exit erhält 0+ JSON-Zeilen als Input (die geänderten Tasks)
- on-exit kann keine Tasks modifizieren, nur Feedback ausgeben

**Installation:** Wird nach `<hook-verzeichnis>/on-exit-noctalia` kopiert (Pfad dynamisch via `task _get rc.data.location`) und mit `chmod +x` ausführbar gemacht. Verwaltung über den Hook-Button in den Settings.

**Debugging:**
- `task diagnostics` — Zeigt Hook-Status und erkannte Hook-Dateien
- `rc.debug.hooks=1` — Aktiviert Hook-Debug-Ausgabe
- `rc.debug.hooks=2` — Verbose Hook-Debug-Ausgabe

### Taskwarrior-Kompatibilität

Das Plugin kommuniziert ausschließlich über die CLI (`task export`, `task add`, etc.) und Hooks — beides funktioniert identisch in Taskwarrior 2.x und 3.x.

**Versionen:**
| | Taskwarrior 2.x | Taskwarrior 3.x |
|---|---|---|
| Storage | `.data` Textdateien | TaskChampion (SQLite) |
| Sync | taskd (eigener Server) | TaskChampion Sync Server |
| Hooks | v1 + v2 API | v1 + v2 API (kompatibel) |
| CLI-Interface | `task export/add/done/...` | identisch |

- Sync ist in beiden Versionen **immer manuell** via `task sync` (ggf. per cron automatisiert). Es gibt keinen auto-sync-Daemon.
- Arch Linux / CachyOS: Taskwarrior 3.x — Ubuntu / Debian stable: Taskwarrior 2.x
- Das Plugin muss mit beiden Versionen kompatibel sein

### i18n

- `en.json` as source of truth from day one
- Hierarchical keys: `bar_widget.*`, `main.*`, `panel.*`, `settings.*`
- Placeholders: `{count}`, `{date}`, `{project}`, etc.
- Context suffixes: `-label`, `-description`, `-placeholder`, `-tooltip`
- `pluginApi.tr(key, interpolations?)` — Standard-Übersetzung mit optionaler Platzhalter-Interpolation
  - Beispiel: `pluginApi.tr("task_count", { count: 42 })` → ersetzt `{count}` im String
  - Manuelles `.replace()` ist damit unnötig
  - Fallback bei fehlendem Key: gibt `## key ##` zurück
- `pluginApi.trp(key, count, defaultSingular?, defaultPlural?, interpolations?)` — Pluralformen für Task-Zähler
  - `defaultSingular` und `defaultPlural` sind optional (mit `?`)
  - `interpolations` ist ein optionales Objekt für Platzhalter
  - Beispiel: `pluginApi.trp("tasks", taskCount, "task", "tasks", { count: taskCount })`
- `pluginApi.hasTranslation(key)` — Prüft ob ein Schlüssel existiert

**Unterstützte Sprachen (15 Kern-Sprachen, >60% Verbreitung):**
en, de, zh-CN, fr, es, pt, tr, uk-UA, ru, pl, nl, ja, it, hu, ku

## Quality Requirements

- **Formatting:** `qmlfmt` auf alle QML-Dateien vor PRs anwenden
- **Qt-Version:** Kein Qt5Compat, ausschließlich Qt6-APIs verwenden
- **Logging:** `Logger.i/d/w/e("Taskwarrior", "message")` für Debug-Ausgaben
- **IPC-Typen:** IPC-Parameter sind immer Strings — explizite Typkonvertierung nötig
- **Hot Reload:** `NOCTALIA_DEBUG=1` als Umgebungsvariable für QML-Hot-Reload während der Entwicklung

## Roadmap

### MVP (v1.0.0)

- Main.qml: Filter engine, CRUD operations, Start/Stop, Hook system
- BarWidget.qml: Counter + active indicator
- Panel.qml: Filter bar, task list, task input, detail dialog, delete confirmation
- Settings.qml: Counter type, defaults, hook management
- i18n: en.json baseline
- hooks/on-exit-noctalia
- manifest.json with entry points and default settings

### v1.1.0

- Project grouping as optional view mode
- Annotation management in detail dialog
- Dependency display (blocked/blocking)
- Recurring task display

### v1.2.0

- Summary/Dashboard view
- Completed tasks history
- Additional languages (de, es, fr, ...)
- preview.png (960x540)

## File Structure

```
taskwarrior/
├── manifest.json
├── Main.qml
├── BarWidget.qml
├── Panel.qml
├── Settings.qml
├── hooks/
│   └── on-exit-noctalia
└── i18n/
    └── en.json
```

## Entry Points

```json
{
  "main": "Main.qml",
  "barWidget": "BarWidget.qml",
  "panel": "Panel.qml",
  "settings": "Settings.qml"
}
```

## Default Settings

```json
{
  "barWidgetCounter": "pending",
  "showActiveIndicator": true,
  "defaultProject": "",
  "defaultPriority": "",
  "hookInstalled": false
}
```

---

## Implementation Plan

Siehe **IMPLEMENTATION.md** für den vollständigen 17-Task Implementierungsplan mit Code.
