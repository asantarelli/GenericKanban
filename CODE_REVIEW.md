# Code Review — GenericKanban COM Control

**Overall Score: 78 / 100** | Verdict: **REVISE**

---

## Category Scores

| Category | Score | Notes |
|---|---|---|
| Naming | 9/10 | Consistent, clear XML comments throughout |
| Patterns | 8/10 | COM dual-interface + events pattern is correct |
| Architecture | 8/10 | Clean C# bridge → JS separation; pending queue pattern is good |
| Error Handling | 6/10 | Thread-safety gaps, stale timer bug |
| Performance | 7/10 | Full card DOM rebuild on every property change |
| Maintainability | 8/10 | Good comments; duplicated cleanup logic |

---

## MAJOR Issues

### 1. Thread-safety race on `_pending` list
**File:** `GenericKanbanControl.cs` lines 193–196 and 264–268

`_pending` is a plain `List<string>` written from the COM caller thread and drained on the WebView2 UI thread. The `if (_pageReady)` check and `_pending.Add()` are not atomic — a script can be silently lost if `PageReady` fires concurrently with `Exec()` appending.

**Fix:** Wrap all `_pending` mutations and the `_pageReady` check inside `lock (_pending)` in both `Exec()` and the `"ready"` case of `OnWebMessage`.

---

### 2. `_cardColumn` reader/writer race
**File:** `GenericKanbanControl.cs` lines 208–212 and 380

`GetCardColumn()` is called directly on Clarion's STA thread while writes happen on the UI thread. No synchronisation between them.

**Fix:** Use `ConcurrentDictionary<string, string>` for `_cardColumn`, or marshal `GetCardColumn` reads to the UI thread via `Invoke`.

---

### 3. Single-click timer fires after card removal
**File:** `wwwroot\controls\generickanban\app.js` lines 81–85 and 480–489

`removeCard()` removes the DOM element but doesn't cancel a pending `_singleClickTimer`. 300ms later, the `CardClick` COM event fires with a stale card ID that no longer exists in `_cards`, which can confuse Clarion subscribers.

**Fix:** In `removeCard()`, after `card.el.remove()`, add:

```js
if (kanban._lastClickCard === cardId) {
    clearTimeout(kanban._singleClickTimer);
    kanban._singleClickTimer = null;
    kanban._lastClickCard = null;
}
```

---

## MINOR Issues

### 4. `SetCardBorderColor` is a no-op in JS
`_makeCardEl` never reads `card.borderColor` when building the card element, so the C# `SetCardBorderColor` API method has zero visible effect. The property is stored but never applied.

**Fix:** In `_makeCardEl`, after applying `backgroundColor`, add:
```js
if (card.borderColor) el.style.borderColor = card.borderColor;
```
You may also need a `border` base style in CSS for the color to be visible.

---

### 5. Misleading XML summary on `CardDoubleClick`
**File:** `IGenericKanbanEvents.cs` lines 38–41

The summary reads "Fired when the user clicks a card without dragging (Trello-style open)" — which describes a *single* click. The event actually fires on double-click. This was apparently copied before the events were renamed and will confuse Clarion developers reading the TLB-generated help.

**Fix:** Update the summary to: `"Fired when the user double-clicks a card (two clicks within 300 ms)."`

---

### 6. Duplicate column-card cleanup logic
**File:** `GenericKanbanControl.cs` lines 285–297 (`RemoveColumn`) and 363–376 (`ClearColumnCards`)

Both methods iterate `_cardColumn` to find cards belonging to a column, then remove them from `_cardColumn` and `_radioValues`. Identical logic in two places — any future shadow dictionary addition (e.g. `_filterValues`) must be maintained twice.

**Fix:** Extract a private `RemoveCardsInColumn(string columnId)` helper and call it from both methods.

---

### 7. `_rebuildCard` causes N full DOM rebuilds for N property sets
**File:** `wwwroot\controls\generickanban\app.js` — `_rebuildCard` and `_makeCardEl`

Every card setter (`SetCardTitle`, `SetCardTag`, `SetCardBackgroundColor`, etc.) calls `_rebuildCard`, which does a full `replaceChild`. Calling five setters in sequence triggers five full rebuilds and repaints. At scale with many cards this will be noticeable.

**Fix:** For individual property changes, consider targeted in-place DOM mutations (e.g. `el.querySelector('.card-title').textContent = title`) rather than rebuilding the whole element. At minimum, add a comment that callers should batch setter calls before the card is displayed.

---

### 8. Inconsistent UI-thread marshalling
**File:** `GenericKanbanControl.cs`

`AddCard` explicitly wraps everything in `RunOnUIThread`, but `SetCardTitle`, `SetCardTag`, and other setters rely on `Exec`'s internal `InvokeRequired` guard. The pattern is inconsistent and confusing to maintain.

**Fix:** Either apply `RunOnUIThread` consistently across all public methods, or add a comment at the top of `Exec` stating it is self-marshalling, and that explicit wrapping is only needed when shadow state (`_cardColumn`, `_radioValues`) must be mutated atomically with the script dispatch.

---

### 9. WebView2 user-data folder never cleaned up
**File:** `GenericKanbanControl.cs` lines 150–153

The user-data folder is named `GenericKanban_WebView2Data_{pid}_{handle}` in `%TEMP%`. This prevents multi-instance conflicts (good), but the folder is never deleted on `Dispose` or process exit, leaking one folder per control instance over time.

**Fix:** Store `userDataPath` as a field. In `Dispose(bool disposing)`, after `_webView?.Dispose()`, add:
```csharp
try { Directory.Delete(_userDataPath, recursive: true); } catch { /* ignore lock races */ }
```

---

## Nits

### N1. `_esc` doesn't escape single-quote characters
**File:** `wwwroot\controls\generickanban\app.js` lines 986–993

`_esc` escapes `&`, `<`, `>`, and `"` but not `'`. Safe for current `innerHTML` usages with double-quoted attributes, but if output were ever used in a single-quoted attribute context it would be unsafe.

**Fix:** Either add `'` → `&#x27;` to `_esc`, or add a comment: `// for innerHTML use only — does not escape single quotes`.

---

### N2. `[assembly: ComVisible(true)]` is too broad
**File:** `Properties\AssemblyInfo.cs` line 13

Making every public type COM-visible by default is against standard .NET COM interop guidance. Any future helper class added without thought will be accidentally exposed.

**Fix:** Change to `[assembly: ComVisible(false)]` and rely on the explicit `[ComVisible(true)]` already present on the interface and class.

---

### N3. Duplicated `mouseenter` positioning block in `_buildMenuEl`
**File:** `wwwroot\controls\generickanban\app.js` lines ~297–306 and ~330–339

The `mouseenter` handler for `node.type === 'radio'` and `node.type === 'sub'` are character-for-character identical.

**Fix:** Extract to a named function `_positionSubMenu(li, subEl)` and call it from both branches.

---

### N4. DispId ordering is reversed from typical expectation (informational)
**File:** `IGenericKanbanEvents.cs`

`CardDoubleClick` has DispId 4 (added first) and `CardClick` has DispId 5 (added later). Single-click being the higher-numbered event is mildly surprising when reading the IDL. This cannot be fixed without breaking binary compatibility — informational only.

---

## Bottom Line

The architecture is solid: clean COM interface, safe JS IIFE scoping, correct use of `.textContent` in card rendering (no XSS risk), and a sensible pre-ready queue concept. The three major issues are all targeted fixes, not architectural problems.

- The **`_pending` race** is the most dangerous in production — setup commands can be silently dropped.
- **`SetCardBorderColor` being a no-op** is the most likely to cause immediate user-visible confusion.
- The **stale single-click timer** is a subtle correctness issue that will occasionally fire ghost events.

None of these require structural changes. All three are small, localised fixes.
