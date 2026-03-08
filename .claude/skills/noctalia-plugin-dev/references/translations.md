# Translations (i18n) Reference

Noctalia provides an i18n system. When users change Noctalia's language, plugins automatically
use the appropriate translations.

## Directory Structure

```
my-plugin/
└── i18n/
    ├── en.json      # English (required — system fallback)
    ├── de.json      # German
    ├── es.json      # Spanish
    ├── fr.json      # French
    └── ...
```

## Translation File Format

Nested JSON with hierarchical keys:

```json
{
  "bar_widget": {
    "title": "My Widget",
    "status-label": "Status"
  },
  "panel": {
    "header": "Settings",
    "save-label": "Save Changes",
    "cancel-label": "Cancel"
  },
  "messages": {
    "welcome": "Welcome, {name}!",
    "items": "{count} item",
    "items_plural": "{count} items"
  }
}
```

## API Functions

### tr(key, interpolations?) — basic translation

```qml
// Simple
text: pluginApi?.tr("bar_widget.title") || "My Widget"

// With interpolations
text: pluginApi?.tr("messages.welcome", { name: userName }) || ""

// Multiple interpolations
text: pluginApi?.tr("connection.status", {
    server: serverName,
    port: portNumber
}) || ""
```

### trp(key, count, singular, plural, interpolations?) — plural forms

```qml
text: pluginApi?.trp(
    "messages.items",     // Base key
    itemCount,            // Count for plural logic
    "1 item",             // Fallback singular
    "{count} items"       // Fallback plural
) || ""
```

Logic: count === 1 uses `"messages.items"`, count !== 1 uses `"messages.items_plural"`.

### hasTranslation(key) — check existence

```qml
if (pluginApi?.hasTranslation("optional.feature")) {
    text = pluginApi.tr("optional.feature")
}
```

### currentLanguage — current language code

```qml
readonly property string lang: pluginApi?.currentLanguage || "en"
```

## Fallback Chain

1. Current language translation (e.g., `i18n/de.json`)
2. English translation (`i18n/en.json`)
3. Key wrapped in `## ##` (e.g., `## widget.title ##`)

Always provide inline fallbacks:

```qml
text: pluginApi?.tr("widget.title") || "My Widget"
```

## Global Translations (I18n)

Access Noctalia's built-in translations:

```qml
import qs.Commons

text: I18n.tr("common.save")

// Combined fallback
text: pluginApi?.tr("panel.save") || I18n.tr("common.save")
```

## Key Naming Conventions

- Hierarchical by component: `bar_widget.*`, `panel.*`, `settings.*`, `main.*`
- Suffixes: `-label`, `-description`, `-placeholder`, `-tooltip`
- Placeholders: `{variable}` — must be preserved in all translations

## Supported Languages

en, es, de, fr, it, pt, nl, ru, ja, zh-CN, tr, uk-UA

## Hot Reload

With `NOCTALIA_DEBUG=1`, translation files are watched. Changes reload automatically
(~300ms debounce) without restarting. Plugin state is preserved.

## Best Practices

1. `en.json` is mandatory — system fallback
2. Always provide `|| "default"` fallbacks in QML
3. Organize keys hierarchically by component
4. Use identical key structures across all language files
5. Use interpolations (`{var}`) instead of string concatenation
6. Use `trp()` with `_plural` suffix for plural forms
7. Consider text expansion — German text is ~30% longer than English
