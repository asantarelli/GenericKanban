# GenericKanban

A generic, database-agnostic Kanban board control for Clarion for Windows applications. Supports user-defined columns and cards with custom formatting. Cards can be dragged between columns and a `CardMoved` event fires back to Clarion. Built with WebView2 and SortableJS.

## Requirements

- .NET Framework 4.8
- Clarion 11.0 or later
- WebView2 Runtime ([download](https://developer.microsoft.com/microsoft-edge/webview2/))

## Features

- Drag-and-drop cards between columns (SortableJS)
- Board and Table view (toggle in title bar)
- WIP limits per column with amber/red visual indicator
- Single-click and double-click card events
- Card metadata: tag, assignee, due date, progress bar, status bar
- Status system — ties colour, context menu radio, and filter to one status value
- Hierarchical right-click context menus with radio groups
- Filter panel with colour-coded groups and text search
- Show/hide cards independently of the filter system
- Programmatic card move (fires the same event as drag)
- Read-only mode — disables drag-and-drop
- Dark mode toggle
- Custom column header and body colours, board title bar
- Show/hide columns independently
- Auto-contrast text colour fallback and configurable global font size
- English/Spanish UI language toggle (control chrome only, not card content)
- Auto-sort a column by card priority or due date, with free drag-reordering afterward
- Filter the board down to a single assignee's cards (or show every assignee) with one call
- Compact card view — title and status colour bar only, for scanning many tasks at once
- Save/restore board-level settings (dark mode, read-only, column width, font size, language, column visibility, column sort modes, assignee filter, compact view) as a JSON string

## Installation

Copy the contents of the `Clarion/accessory/` folder to your Clarion accessory folder:
- `bin/GenericKanban.dll` → `accessory\bin\`
- `resources/GenericKanban.manifest` → `accessory\resources\`
- `resources/wwwroot/` → `accessory\resources\wwwroot\`

## API Reference

### Methods

**Columns**

| Method | Description |
|--------|-------------|
| `AddColumn(columnId, title, color=0)` | Adds a column; `color` sets the header background |
| `RemoveColumn(columnId)` | Removes a column and all its cards |
| `ClearColumns()` | Removes all columns and cards |
| `SetColumnHeaderColor(columnId, color)` | Sets column header background colour |
| `SetColumnHeaderTextColor(columnId, color)` | Sets column header text colour |
| `SetAllColumnTextColors(color)` | Sets header text colour for every column at once |
| `SetColumnBodyColor(columnId, color)` | Sets column body background colour |
| `SetColumnWidth(width)` | Sets pixel width for all columns (default 260) |
| `SetColumnWipLimit(columnId, maxCards)` | Sets WIP limit; 0 = no limit |
| `GetColumnCardCount(columnId)` | Returns current card count for a column |
| `SetColumnVisible(columnId, visible)` | Shows (1) or hides (0) a column without removing it or its cards |
| `SetColumnSortMode(columnId, mode)` | Auto-sorts a column by `"priority"` or `"date"` (or `"none"`); re-applies on card add/priority/due-date change, drag-reordering afterward is preserved |

**Cards**

| Method | Description |
|--------|-------------|
| `AddCard(cardId, columnId, title, body)` | Adds a card |
| `AddCard(KanbanCardMeta)` | Adds a fully decorated card in one call |
| `RemoveCard(cardId)` | Removes a card |
| `ClearColumnCards(columnId)` | Removes all cards from a column |
| `GetCardColumn(cardId)` | Returns the column ID containing the card |
| `MoveCardToTop(cardId)` | Moves a card to the top of its column |
| `MoveCard(cardId, columnId)` | Moves a card to a different column (fires `CardMoved`); re-applies the destination column's auto-sort mode if one is active |
| `SetCardVisible(cardId, visible)` | Shows (1) or hides (0) a card without removing it |
| `SetCardTitle(cardId, title)` | Updates card title |
| `SetCardBody(cardId, body)` | Updates card body text |
| `SetCardBackgroundColor(cardId, color)` | Sets card background colour |
| `SetCardTextColor(cardId, color)` | Sets card text colour |
| `SetCardBorderColor(cardId, color)` | Sets card border colour |
| `SetCardTag(cardId, label, color)` | Sets tag badge on card |
| `SetCardAssignee(cardId, assignee)` | Sets assignee text on card |
| `SetCardDueDate(cardId, dueDate)` | Sets due date text on card |
| `SetCardProgress(cardId, percent)` | Sets progress bar (0–100, -1 to hide) |
| `SetCardOverdue(cardId, overdue)` | Marks card as overdue (1) or clears (0); shows the OVERDUE badge and renders the card body in red |
| `SetCardStatusBar(cardId, label, color)` | Sets coloured status bar on card left edge |
| `SetCardStatus(cardId, optionId)` | Sets status (bar colour + filter + radio) in one call |
| `SetCardPriority(cardId, priority)` | Sets a numeric priority (lower = higher priority); -1 clears it |
| `SetCardRadioValue(cardId, groupId, itemId)` | Sets selected radio item for a group on a card |
| `GetCardRadioValue(cardId, groupId)` | Returns selected radio item ID for a group |
| `SetCardFilterValue(cardId, groupId, itemId)` | Associates a card with a filter value |

**Board Appearance**

| Method | Description |
|--------|-------------|
| `SetBoardTitle(title, colorBg, colorText)` | Sets the toolbar title bar |
| `SetBoardBackgroundColor(color)` | Sets board canvas background colour |
| `SetDarkMode(enabled)` | Enables (1) or disables (0) dark mode |
| `SetReadOnly(readOnly)` | Disables drag-and-drop when 1 |
| `SetLanguage(lang)` | Sets UI chrome language: `"en"` or `"es"` (fallback `"en"`); does not translate card content |
| `SetFontSize(px)` | Sets the global base font size in pixels (default 14); other text scales proportionally |
| `GetBoardState()` | Returns a JSON string with all board-level settings (dark mode, read-only, column width, font size, language, board title/colours, column visibility, column sort modes, assignee filter, compact view) |
| `SetBoardState(json)` | Restores board-level settings from a `GetBoardState()` JSON string; safe to call before or after `PageReady` |
| `SetCompactView(enabled)` | Enables (1) or disables (0) compact cards: only the title and the status/priority colour bar remain visible; tag, body, overdue badge, assignee/due-date line, and progress bar are hidden without losing the underlying data |

**Context Menu**

| Method | Description |
|--------|-------------|
| `ClearContextMenu()` | Clears all context menu items |
| `AddContextMenuItem(parentId, itemId, label)` | Adds a clickable menu item |
| `AddContextMenuSub(parentId, subId, label)` | Adds a sub-menu |
| `AddContextMenuSep(parentId)` | Adds a separator |
| `AddContextMenuRadioGroup(parentId, groupId, label)` | Adds a radio group |
| `AddContextMenuRadioItem(groupId, itemId, label)` | Adds a radio item to a group |

**Filters**

| Method | Description |
|--------|-------------|
| `ClearFilters()` | Clears all filter groups and items |
| `AddFilterGroup(groupId, title)` | Adds a filter group section |
| `AddFilterItem(groupId, itemId, label, color)` | Adds a filter option with colour swatch |
| `SetTextSearchEnabled(enabled)` | Shows (1) or hides (0) the text search box |
| `SetAssigneeFilter(assignee)` | Shows only cards whose assignee (`SetCardAssignee`) matches exactly; empty string shows every assignee. While a specific assignee is active, that card's assignee label is hidden (redundant) and reappears when cleared |

**Status System**

| Method | Description |
|--------|-------------|
| `SetStatusTitle(title)` | Sets the display name for the status group |
| `AddStatusOption(optionId, label, color)` | Registers a status value |
| `BuildFilterFromStatus()` | Creates a filter group from all status options |
| `BuildMenuFromStatus(parentId)` | Creates a context menu radio group from all status options |

### Events

| Event | Parameters | Description |
|-------|-----------|-------------|
| `CardMoved` | `cardId`, `fromColumnId`, `toColumnId` | Fired when a card moves to a different column (drag or `MoveCard`) |
| `PageReady` | — | Fired when the board is fully initialised and ready to receive calls |
| `ContextMenuSelected` | `cardId`, `itemId` | Fired when a context menu item is clicked |
| `CardClick` | `cardId` | Fired on a confirmed single click (300 ms debounce, mutually exclusive with double-click) |
| `CardDoubleClick` | `cardId` | Fired on a double-click (cancels pending single-click) |

## Clarion Wrapper Class

A `KanbanWrapperClass` is provided in `Clarion/accessory/libsrc/win/` (`KanbanWrapper.inc` / `KanbanWrapper.clw`) that wraps raw COM calls for cleaner Clarion code.

## Building from Source

1. Clone or download this repository
2. Open `GenericKanban.csproj` in Visual Studio 2022, or run:
   ```
   dotnet build -c Release
   ```
3. Build in Release / x86 configuration

> **Frontend changes:** The Kanban UI is written in TypeScript (`frontend/src/app.ts`).
> If you modify `app.ts`, **Node.js 18+** must be on your PATH — MSBuild will automatically run
> `npm ci` (first build only) and `esbuild` to regenerate `wwwroot/controls/generickanban/app.js`.
> If you are only making C# changes, the committed `app.js` is used as-is without Node.

## License

MIT — see [LICENSE](LICENSE)
