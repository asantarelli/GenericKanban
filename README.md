# GenericKanban

A generic, database-agnostic Kanban board control for Clarion for Windows applications. Supports user-defined columns and cards with custom formatting. Cards can be dragged between columns and a `CardMoved` event fires back to Clarion. Built with WebView2 and SortableJS.

## Requirements

- .NET Framework 4.8
- Clarion 11.0 or later
- WebView2 Runtime ([download](https://developer.microsoft.com/microsoft-edge/webview2/))

## Features

- Drag-and-drop cards between columns (SortableJS)
- Board and Table view (toggle in title bar)
- Right-click context menu with sub-menus, separators, and radio groups
- Card metadata: tag, assignee, due date, progress bar, status bar (priority colour)
- Move card to top of column
- Read-only mode
- Custom column header and body colours
- Custom board background colour and title bar
- Board/Table view selector built into the title bar

## Installation

Copy the contents of the `Clarion/accessory/` folder to your Clarion accessory folder:
- `bin/GenericKanban.dll` → `accessory\bin\`
- `resources/GenericKanban.manifest` → `accessory\resources\`
- `resources/wwwroot/` → `accessory\resources\wwwroot\`
- Metadata files (`.details`, `.methods`, `.events`, `.header`) → `accessory\resources\`

## API Reference

### Methods

| Method | Parameters | Description |
|--------|-----------|-------------|
| `AddColumn` | `columnId`, `title` | Adds a new column to the board |
| `RemoveColumn` | `columnId` | Removes a column and all its cards |
| `ClearColumns` | — | Removes all columns and cards |
| `SetColumnHeaderColor` | `columnId`, `hexColor` | Sets column header background colour |
| `SetColumnHeaderTextColor` | `columnId`, `hexColor` | Sets column header text colour |
| `SetColumnBodyColor` | `columnId`, `hexColor` | Sets column body background colour |
| `SetColumnWidth` | `width` | Sets pixel width for all columns (default 260) |
| `AddCard` | `cardId`, `columnId`, `title`, `body` | Adds a card to a column |
| `RemoveCard` | `cardId` | Removes a card |
| `ClearColumnCards` | `columnId` | Removes all cards from a column |
| `GetCardColumn` | `cardId` | Returns the column ID containing the card |
| `MoveCardToTop` | `cardId` | Moves a card to the top of its column |
| `SetCardTitle` | `cardId`, `title` | Updates card title |
| `SetCardBody` | `cardId`, `body` | Updates card body text |
| `SetCardBackgroundColor` | `cardId`, `hexColor` | Sets card background colour |
| `SetCardTextColor` | `cardId`, `hexColor` | Sets card text colour |
| `SetCardBorderColor` | `cardId`, `hexColor` | Sets card border colour |
| `SetCardTag` | `cardId`, `label`, `hexColor` | Sets tag badge on card |
| `SetCardAssignee` | `cardId`, `assignee` | Sets assignee text on card |
| `SetCardDueDate` | `cardId`, `dueDate` | Sets due date text on card |
| `SetCardProgress` | `cardId`, `percent` | Sets progress bar (0–100, -1 to hide) |
| `SetCardOverdue` | `cardId`, `overdue` | Marks card as overdue (red indicator) |
| `SetCardStatusBar` | `cardId`, `label`, `hexColor` | Sets coloured status bar on left edge |
| `SetCardRadioValue` | `cardId`, `groupId`, `itemId` | Sets the selected radio item for a group on a card |
| `GetCardRadioValue` | `cardId`, `groupId` | Returns selected radio item ID for a group |
| `SetBoardTitle` | `title`, `hexBg`, `hexText` | Sets the board title bar |
| `SetBoardBackgroundColor` | `hexColor` | Sets board canvas background colour |
| `SetReadOnly` | `readOnly` | Enables/disables drag-and-drop (1=readonly) |
| `ClearContextMenu` | — | Clears all context menu items |
| `AddContextMenuItem` | `parentId`, `itemId`, `label` | Adds a menu item |
| `AddContextMenuSub` | `parentId`, `subId`, `label` | Adds a sub-menu |
| `AddContextMenuSep` | `parentId` | Adds a separator |
| `AddContextMenuRadioGroup` | `parentId`, `groupId`, `label` | Adds a radio group sub-menu |
| `AddContextMenuRadioItem` | `groupId`, `itemId`, `label` | Adds a radio item to a group |

### Events

| Event | Parameters | Description |
|-------|-----------|-------------|
| `CardMoved` | `cardId`, `fromColumnId`, `toColumnId` | Fired when a card is dragged to a different column |
| `PageReady` | — | Fired when the board is fully initialised and ready |
| `ContextMenuSelected` | `cardId`, `itemId` | Fired when a context menu item is clicked |

## Clarion Wrapper Class

A `KanbanWrapperClass` is provided in `TestKanban/` (see `KanbanWrapper.inc` / `KanbanWrapper.clw`) that wraps raw COM calls for cleaner Clarion code.

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
