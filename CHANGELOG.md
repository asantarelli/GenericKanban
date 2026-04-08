# Changelog

All notable changes to GenericKanban will be documented here.

## [1.1.0] - 2026-04-08

### Added
- **Table view** — toggle between board and table view from the title bar
- **Toolbar** — always-visible title bar (`SetBoardTitle`)
- **Dark mode** — `SetDarkMode(1/0)`
- **Filter panel** — `AddFilterGroup`, `AddFilterItem`, `SetCardFilterValue`, `SetTextSearchEnabled`
- **Status system** — `SetStatusTitle`, `AddStatusOption`, `BuildFilterFromStatus`, `BuildMenuFromStatus`, `SetCardStatus`; ties colour, context menu radio, and filter option to a single status value
- **Context menu** — `ClearContextMenu`, `AddContextMenuItem`, `AddContextMenuSub`, `AddContextMenuSep`, `AddContextMenuRadioGroup`, `AddContextMenuRadioItem`, `SetCardRadioValue`, `GetCardRadioValue`
- **Card metadata** — `SetCardTag`, `SetCardAssignee`, `SetCardDueDate`, `SetCardProgress`, `SetCardOverdue`, `SetCardStatusBar`
- **`AddCard(KanbanCardMeta)`** overload — create a fully decorated card in one call
- **`KanbanCardMeta`** GROUP,TYPE data structure
- **`MoveCard(pCardId, pColumnId)`** — programmatic card move; fires `OnCardMoved` identically to drag-drop
- **`SetColumnWipLimit(pColumnId, pMaxCards)`** — WIP limit per column; badge turns amber at limit, red when exceeded
- **`GetColumnCardCount(pColumnId)`** — card count from C# shadow state (no round-trip)
- **`SetCardVisible(pCardId, pVisible)`** — show/hide a card without removing it; independent of filter panel
- **`SetReadOnly(pReadOnly)`** — disables drag-and-drop
- **`SetAllColumnTextColors(pColor)`** — sets header text colour for every column at once
- **`OnSingleClick(pCardId)`** event — confirmed single click (300 ms debounce, mutually exclusive with double-click)
- **`OnDoubleClick(pCardId)`** event — double-click (cancels pending single-click)
- **Row selection highlight** in table view — clicked row stays highlighted (`.kv-row--selected`)

### Changed
- Frontend JavaScript (`app.js`) migrated to TypeScript (`frontend/src/app.ts`) with esbuild bundling
  - `app.js` remains committed so C#-only builds work without Node.js
  - Node.js 18+ is only required when modifying `app.ts`
- MSBuild `BuildFrontend` target added — incremental, skips if `app.js` is newer than `app.ts`, guarded against design-time builds

## [1.0.0] - 2026-04-02

### Added
- Initial release
- AddColumn / RemoveColumn / ClearColumns
- AddCard / RemoveCard / ClearColumnCards
- GetCardColumn
- SetColumnHeaderColor / SetColumnHeaderTextColor / SetColumnBodyColor
- SetCardBackgroundColor / SetCardTextColor / SetCardBorderColor
- SetCardTitle / SetCardBody
- SetBoardBackgroundColor / SetColumnWidth
- CardMoved COM event (fires to Clarion on drag-drop)
- Drag-and-drop cards between columns
- Automatic post-build deployment to Clarion\accessory\
- MSBuild-generated .details / .events / .methods metadata files
