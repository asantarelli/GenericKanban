# Changelog

All notable changes to GenericKanban will be documented here.

## [1.3.0] - 2026-07-06

### Added
- **`SetColumnVisible(pColumnId, pVisible)`** — shows/hides a column without removing it or its cards
- **`SetColumnSortMode(pColumnId, pMode)`** — auto-sorts a column by `'priority'` or `'date'` (or `'none'`); re-applies on card add or on priority/due-date change; manual drag-reordering afterward is preserved until the next trigger
- **`SetCardPriority(pCardId, pPriority)`** — numeric priority (lower = higher priority); `-1` clears it
- **`SetLanguage(pLang)`** — UI chrome language, `'en'` or `'es'` (default `'en'`); translates table headers, filter panel, OVERDUE badge and due-date prefix — does not translate card content
- **`SetFontSize(pPx)`** — global base font size in pixels (default 14); all other text scales proportionally via a CSS custom property
- **Automatic text-contrast fallback** — when a background colour is set without an explicit paired text colour (`SetCardBackgroundColor`, `SetColumnHeaderColor`), the control picks black or white text based on luminance; an explicit `SetCardTextColor` / `SetColumnHeaderTextColor` call always overrides the automatic choice
- **`GetBoardState()`** — returns a JSON string with all board-level settings (dark mode, read-only, column width, font size, language, board title/colours, per-column visibility, per-column sort mode, assignee filter)
- **`SetBoardState(pJson)`** — restores board-level settings from a `GetBoardState()` JSON string; safe to call before or after `PageReady`
- **`SetAssigneeFilter(pAssignee)`** — shows only cards whose assignee (`SetCardAssignee`) matches exactly; pass an empty string to show every assignee again. Composes with the generic filter panel and text search. While a specific assignee is active, that assignee's name is hidden on the card (redundant — every visible card already belongs to them) and reappears automatically when the filter is cleared
- **`SetCompactView(pEnabled)`** — compact card rendering: only the title and the status/priority colour bar remain visible; tag, body, overdue badge, assignee/due-date line, and progress bar are hidden without losing any card data. Included in `GetBoardState()`/`SetBoardState()`

### Changed
- `SetDarkMode`, `SetReadOnly`, `SetColumnWidth`, `SetBoardTitle` now also store their value in C# shadow state so `GetBoardState()` can read them back
- `KanbanWrapper.clw`'s `Q_()` string-escaping buffer enlarged from `CSTRING(4002)` to `CSTRING(16002)` to accommodate larger JSON payloads (e.g. `SetBoardState` on boards with many columns)

## [1.2.0] - 2026-04-08

### Added
- **`OnCardRightClick(pCardId)`** event — fires on right-click *before* the context menu is shown; override to rebuild the menu per-card for dynamic, context-aware menus
- **`ShowContextMenu(pCardId)`** method — triggers the context menu at the right-click position; called automatically by the base `OnCardRightClick`; call explicitly only if suppressing the PARENT call
- **Stale-call guard** — a monotonic request token (seq) flows JS → C# → JS; a delayed C# response cannot show a ghost menu if the user right-clicked elsewhere or on the same card again before Clarion responded; document-level right-click also cancels any in-flight pending right-click

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
