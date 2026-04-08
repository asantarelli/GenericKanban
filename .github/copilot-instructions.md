# GenericKanban – Copilot Instructions

## What this project is

A registration-free COM ActiveX control for **Clarion for Windows** that renders a Kanban board inside a WebView2 browser surface. The control is written in C# (.NET Framework 4.8, x86), exposes a COM dual interface (`IGenericKanban`), and fires COM outbound events (`IGenericKanbanEvents`) back to Clarion. The board UI is pure HTML/CSS/JS (`wwwroot/controls/generickanban/`), using SortableJS for drag-and-drop.

## Build

```
dotnet build                          # Debug
dotnet build -c Release               # Release (x86 enforced in csproj)
```

**Frontend changes** require Node.js 18+ on PATH. MSBuild runs `esbuild` automatically
when `frontend/src/app.ts` is newer than the output `app.js`. C#-only builds use the
committed `app.js` and do not require Node.

Post-build MSBuild targets automatically deploy all artefacts to `Clarion\accessory\`:
- `GenericKanban.dll` → `bin\`
- Managed dependencies (Newtonsoft.Json, WebView2 managed) → `bin\GenericKanban\` (private subfolder)
- `WebView2Loader.dll` (native) → `bin\`
- `wwwroot\` tree → `resources\wwwroot\`
- `GenericKanban.manifest` → `bin\`

## Architecture

```
Clarion app
   │  COM (RegFree, manifest-based)
   ▼
GenericKanbanControl.cs   ← UserControl + IGenericKanban implementation
   │  ExecuteScriptAsync (C# → JS)
   ▼
wwwroot/controls/generickanban/app.js   ← kanban.* JS API
   │  postMessage (JS → C#)
   ▼
GenericKanbanControl.OnWebMessage   → fires COM events to Clarion
```

### Key files

| File | Purpose |
|------|---------|
| `IGenericKanban.cs` | COM dual interface – all public methods with `[DispId]` |
| `IGenericKanbanEvents.cs` | COM outbound events interface (`InterfaceIsIDispatch`) |
| `GenericKanbanControl.cs` | Single implementation class: UserControl + IGenericKanban |
| `frontend/src/app.ts` | **TypeScript source** – all board/card/filter logic |
| `frontend/src/globals.d.ts` | Ambient declarations for Sortable and `window.chrome.webview` |
| `frontend/package.json` | esbuild + TypeScript devDeps; `build`, `watch`, `typecheck` scripts |
| `wwwroot/controls/generickanban/app.js` | **Generated** by esbuild from `app.ts` – committed so C#-only builds work without Node |
| `GenericKanban.manifest` | RegFree COM manifest – references the CLSID and typelib |
| `Clarion/accessory/libsrc/win/KanbanWrapper.clw/.inc` | Clarion wrapper class for cleaner consumer code |

## Key conventions

### Adding a new COM method

1. Add to `IGenericKanban.cs` with the next sequential `[DispId(N)]`.
2. Implement in `GenericKanbanControl.cs` – use `Exec(...)` for fire-and-forget JS calls, `RunOnUIThread(...)` when you also mutate C# shadow state.
3. Add the matching `kanban.*()` function in **`frontend/src/app.ts`** (TypeScript source). Run `npm run build` in `frontend/` to regenerate `app.js`.
4. Update the Clarion metadata files in `Clarion/accessory/resources/` (`.methods`, `.details`).

### Adding a new COM event

1. Add to `IGenericKanbanEvents.cs` with the next `[DispId(N)]`.
2. Declare the corresponding delegate and `event` field in `GenericKanbanControl.cs`.
3. Post from JS: `window.chrome.webview.postMessage(JSON.stringify({ type: 'EventName', ... }))`.
4. Handle in `OnWebMessage` switch and invoke the event, wrapped in try/catch (errors must not bubble into WebView2).
5. Update the Clarion metadata `.events` file.

### Color encoding

All color parameters are `int` values in **0xRRGGBB** format (not ARGB). Pass `-1` to mean "no color / default". The helper `ColorToHex(int color)` converts to CSS `#RRGGBB` or empty string.

### C# ↔ JS bridge

- **C# → JS**: `Exec("kanban.someMethod(...)")` – queues the script until `_pageReady`, then calls `ExecuteScriptAsync`. Strings must be JSON-encoded with the `J(string)` helper.
- **JS → C#**: `window.chrome.webview.postMessage(JSON.stringify({type, ...}))` from `app.js`, received in `OnWebMessage`.

### Shadow state

`_cardColumn` (`ConcurrentDictionary<string,string>`) and `_radioValues` mirror JS state so that `GetCardColumn` / `GetCardRadioValue` can return synchronously without a JS round-trip. Always keep shadow state in sync when writing card/column mutations.

### Threading

Clarion calls COM methods from its STA thread. `Exec()` self-marshals to the UI thread via `BeginInvoke`. Methods that mutate both shadow state and call `Exec()` atomically must wrap the whole operation in `RunOnUIThread(...)`.

### Dependency isolation

Managed dependencies ship in `bin\GenericKanban\` (a private subfolder) to avoid version conflicts with other COM controls loaded in the same process. The static `AssemblyResolve` handler in `GenericKanbanControl` redirects .NET's probing to that subfolder.

### RegFree COM

The control uses registration-free COM (no `regasm`, no registry entries). The `.manifest` file is the sole COM registration artefact. `processorArchitecture` must remain `x86`.

### Clarion metadata files

The files `Clarion/accessory/resources/GenericKanban.methods`, `.events`, `.details`, and `.header` are consumed by the Clarion IDE to populate the template/wizard UI. Keep them in sync with interface changes.
