# GenericKanban — Feature Recommendations

---

## High Value (common Kanban patterns, straightforward to implement)

### `MoveCard(cardId, columnId)` — programmatic card move
You can drag cards but there's no API to move them in code. This would fire the
existing `CardMoved` event so Clarion code behaves the same regardless of whether
the move was triggered by a drag or by the application.

### WIP limits per column
`SetColumnWipLimit(columnId, maxCards)` — the column header count badge already
exists, it just needs a threshold to turn amber/red when exceeded. Core Kanban
methodology feature and very visible to end users.

### `GetColumnCardCount(columnId)` — synchronous read
`GetCardColumn` exists but there is no way to query how many cards are in a column
without tracking it separately in Clarion code. Useful for enforcing WIP limits in
business logic before allowing a card move.

### `SetCardVisible(cardId, visible)`
The filter system shows/hides cards but is driven by filter values set via
`SetCardFilterValue`. Clarion sometimes needs direct show/hide control — for example,
hiding completed cards without removing them from the board. This would be independent
of the filter panel so both can coexist.

---

## Medium Value

### `ScrollToCard(cardId)`
When a column has many cards and you programmatically add or highlight one, there is
no way to bring it into the visible area. A simple `el.scrollIntoView()` call in JS
exposed as a COM method would handle this.

### `SetColumnCollapsed(columnId, collapsed)`
Collapse a column down to a slim header-only strip. Useful when a "Done" or "Archive"
column is present but users want to maximise horizontal space for active columns.

### `CardRightClick` event (DispId 6)
Currently `ContextMenuSelected` fires *after* the user picks an item. A `CardRightClick`
event fired *before* the menu is displayed would let Clarion dynamically update menu
items per card — for example, enabling or disabling options based on the card's current
state — rather than defining a single static menu up front for all cards.

### `RefreshCard(cardId)`
A signal to JS to re-render a single card from its current stored state. Useful when
you want to batch several property changes (title, tag, color, assignee) and then
apply them all in one repaint, rather than triggering a full `_rebuildCard` on every
individual setter call. This is a performance and flicker improvement for cards that
receive multiple updates at once.

---

## Larger Effort (worth planning for)

### Swimlanes
Horizontal grouping rows across all columns — for example, grouping by assignee,
priority, or project. A significant layout change but a natural Kanban extension that
makes multi-team or multi-project boards practical.

### Column drag reordering
Sortable.js already handles card drag-and-drop between columns. Wiring the same
library up to the columns themselves, with a `ColumnMoved(columnId, fromIndex, toIndex)`
event, would be a contained addition.

### Card multi-select + `CardSelectionChanged` event
Shift/ctrl-click to select multiple cards, then fire a `CardSelectionChanged` event
with the list of selected card IDs. Enables bulk move, bulk status change, or any
other batch operation driven from Clarion.

---

## Recommended Priority Order

1. **`MoveCard`** — fills the most obvious gap; drag is the only move mechanism right now
2. **WIP limits** — visible, high-impact, core to the methodology
3. **`CardRightClick`** — enables dynamic context menus which makes the control much
   more flexible for complex applications
4. **`GetColumnCardCount`** — small addition, unlocks WIP enforcement in Clarion code
5. **`SetCardVisible`** — clean complement to the existing filter system
