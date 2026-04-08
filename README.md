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

## Installation

Copy the contents of the `Clarion/accessory/` folder to your Clarion accessory folder:
- `bin/GenericKanban.dll` → `accessory\bin\`
- `resources/GenericKanban.manifest` → `accessory\resources\`
- `resources/wwwroot/` → `accessory\resources\wwwroot\`
- Metadata files (`.details`, `.methods`, `.events`, `.header`) → `accessory\resources\`

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

**Cards**

| Method | Description |
|--------|-------------|
| `AddCard(cardId, columnId, title, body)` | Adds a card |
| `AddCard(KanbanCardMeta)` | Adds a fully decorated card in one call |
| `RemoveCard(cardId)` | Removes a card |
| `ClearColumnCards(columnId)` | Removes all cards from a column |
| `GetCardColumn(cardId)` | Returns the column ID containing the card |
| `MoveCardToTop(cardId)` | Moves a card to the top of its column |
| `MoveCard(cardId, columnId)` | Moves a card to a different column (fires `CardMoved`) |
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
| `SetCardOverdue(cardId, overdue)` | Marks card as overdue (1) or clears (0) |
| `SetCardStatusBar(cardId, label, color)` | Sets coloured status bar on card left edge |
| `SetCardStatus(cardId, optionId)` | Sets status (bar colour + filter + radio) in one call |
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

A `KanbanWrapperClass` is provided in `Clarion/accessory/libsrc/win/` (`KanbanWrapper.inc` / `KanbanWrapper.clw`) that wraps raw COM calls for cleaner Clarion code. The Clarion template generates and links this automatically.

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
