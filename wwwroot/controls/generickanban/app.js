"use strict";
(() => {
  // src/app.ts
  function isMenuParent(node) {
    return node.type === "sub" || node.type === "radio";
  }
  var kanban = {
    _columns: {},
    _cards: {},
    _colWidth: 260,
    _filterDef: [],
    _cardFilters: {},
    _activeFilters: {},
    _currentView: "board",
    _titleBg: "#1a1a1a",
    _titleText: "#ffffff",
    // Context menu state
    _menuDef: [],
    _menuMap: {},
    _ctxCardId: null,
    _ctxEl: null,
    // Deferred right-click state (CardRightClick event → C# → showContextMenu)
    _pendingCtxCardId: null,
    _pendingCtxX: 0,
    _pendingCtxY: 0,
    _pendingCtxSeq: 0,
    // monotonic counter; guards against same-card stale calls
    _sortKeys: [],
    _tableSortInit: false,
    _searchText: "",
    _searchEnabled: true,
    _lastClickCard: null,
    _lastClickTime: 0,
    _singleClickTimer: void 0,
    _wipLimits: {},
    _selectedTableRow: null,
    _dragScrollRaf: 0,
    _dragPointerX: 0,
    // ── Sortable ───────────────────────────────────────────────────────────────
    _startDragScroll() {
      const board = document.getElementById("board");
      const ZONE = 100;
      const MAX = 18;
      const loop = () => {
        const rect = board.getBoundingClientRect();
        const x = this._dragPointerX;
        const distR = rect.right - x;
        const distL = x - rect.left;
        if (distR < ZONE && distR > 0) {
          board.scrollLeft += MAX * (1 - distR / ZONE);
        } else if (distL < ZONE && distL > 0) {
          board.scrollLeft -= MAX * (1 - distL / ZONE);
        }
        this._dragScrollRaf = requestAnimationFrame(loop);
      };
      const track = (e) => {
        this._dragPointerX = e.clientX;
      };
      board.addEventListener("pointermove", track);
      document.addEventListener("pointermove", track);
      board._dragScrollCleanup = () => {
        board.removeEventListener("pointermove", track);
        document.removeEventListener("pointermove", track);
        cancelAnimationFrame(this._dragScrollRaf);
      };
      this._dragScrollRaf = requestAnimationFrame(loop);
    },
    _stopDragScroll() {
      const board = document.getElementById("board");
      if (board && board._dragScrollCleanup) {
        board._dragScrollCleanup();
        board._dragScrollCleanup = null;
      }
    },
    _initSortable(col) {
      col.sortable = new Sortable(col.cardList, {
        group: "kanban-cards",
        animation: 180,
        easing: "cubic-bezier(.25,1,.5,1)",
        ghostClass: "card-ghost",
        chosenClass: "card-chosen",
        dragClass: "card-drag",
        emptyInsertThreshold: 20,
        onStart: () => {
          kanban._startDragScroll();
        },
        onEnd(evt) {
          kanban._stopDragScroll();
          const cardId = evt.item.dataset.cardId;
          const fromColumn = evt.from.dataset.colId;
          const toColumn = evt.to.dataset.colId;
          if (kanban._cards[cardId]) kanban._cards[cardId].columnId = toColumn;
          if (fromColumn !== toColumn) {
            const fromCol = kanban._columns[fromColumn];
            const toCol = kanban._columns[toColumn];
            if (fromCol) fromCol.cardCount = Math.max(0, (fromCol.cardCount || 0) - 1);
            if (toCol) toCol.cardCount = (toCol.cardCount || 0) + 1;
          }
          kanban._refreshCount(fromColumn);
          if (toColumn !== fromColumn) kanban._refreshCount(toColumn);
          window.chrome.webview.postMessage(JSON.stringify({
            type: "CardMoved",
            cardId,
            fromColumn,
            toColumn
          }));
        }
      });
    },
    _refreshCount(columnId) {
      const col = this._columns[columnId];
      if (!col) return;
      const count = col.cardCount || 0;
      const limit = this._wipLimits[columnId] || 0;
      col.count.textContent = limit > 0 ? `${count}/${limit}` : String(count);
      col.header.classList.toggle("wip-over", limit > 0 && count > limit);
      col.header.classList.toggle("wip-warn", limit > 0 && count === limit);
    },
    // ── Card DOM construction ──────────────────────────────────────────────────
    _makeCardEl(card) {
      const el = document.createElement("div");
      el.className = "card";
      el.dataset.cardId = card.id;
      if (card.bgColor) el.style.backgroundColor = card.bgColor;
      if (card.borderColor) {
        el.style.borderColor = card.borderColor;
        el.style.borderStyle = "solid";
        el.style.borderWidth = "2px";
      }
      this._attachCardClicks(el, card.id);
      const bar = document.createElement("div");
      bar.className = "card-statusbar";
      if (card.statusColor) {
        bar.style.backgroundColor = card.statusColor;
        if (card.statusLabel) {
          bar.classList.add("card-statusbar--wide");
          const lbl = document.createElement("span");
          lbl.className = "card-statusbar-label";
          lbl.textContent = card.statusLabel;
          bar.appendChild(lbl);
        }
      }
      el.appendChild(bar);
      const content = document.createElement("div");
      content.className = "card-content";
      if (card.tag) {
        const tag = document.createElement("div");
        tag.className = "card-tag";
        tag.textContent = card.tag;
        if (card.tagColor) tag.style.color = card.tagColor;
        content.appendChild(tag);
      }
      const t = document.createElement("div");
      t.className = "card-title";
      t.textContent = card.title;
      if (card.textColor) t.style.color = card.textColor;
      content.appendChild(t);
      if (card.body) {
        const b = document.createElement("div");
        b.className = "card-body";
        b.textContent = card.body;
        if (card.textColor) b.style.color = card.textColor;
        content.appendChild(b);
      }
      if (card.overdue) {
        const ov = document.createElement("div");
        ov.className = "card-overdue";
        ov.textContent = "OVERDUE";
        content.appendChild(ov);
      }
      if (card.assignee || card.dueDate) {
        const meta = document.createElement("div");
        meta.className = "card-meta";
        if (card.assignee) {
          const a = document.createElement("span");
          a.className = "card-assignee";
          a.textContent = card.assignee;
          meta.appendChild(a);
        }
        if (card.dueDate) {
          const d = document.createElement("span");
          d.className = "card-due";
          d.textContent = "Due: " + card.dueDate;
          meta.appendChild(d);
        }
        content.appendChild(meta);
      }
      if (card.progress >= 0) {
        const wrap = document.createElement("div");
        wrap.className = "card-progress-bar";
        const fill = document.createElement("div");
        fill.className = "card-progress-fill";
        fill.style.width = Math.min(100, Math.max(0, card.progress)) + "%";
        if (card.tagColor) fill.style.backgroundColor = card.tagColor;
        wrap.appendChild(fill);
        content.appendChild(wrap);
      }
      el.appendChild(content);
      return el;
    },
    _attachCardClicks(el, cardId) {
      const isRow = el.classList.contains("kv-row");
      el.addEventListener("click", () => {
        if (isRow) {
          if (kanban._selectedTableRow && kanban._selectedTableRow !== el)
            kanban._selectedTableRow.classList.remove("kv-row--selected");
          el.classList.add("kv-row--selected");
          kanban._selectedTableRow = el;
        }
        const now = Date.now();
        if (kanban._lastClickCard === cardId && now - kanban._lastClickTime < 300) {
          clearTimeout(kanban._singleClickTimer);
          kanban._singleClickTimer = void 0;
          kanban._lastClickCard = null;
          kanban._lastClickTime = 0;
          window.chrome.webview.postMessage(JSON.stringify({ type: "CardDoubleClick", cardId }));
        } else {
          kanban._lastClickCard = cardId;
          kanban._lastClickTime = now;
          clearTimeout(kanban._singleClickTimer);
          kanban._singleClickTimer = setTimeout(() => {
            kanban._singleClickTimer = void 0;
            kanban._lastClickCard = null;
            window.chrome.webview.postMessage(JSON.stringify({ type: "CardClick", cardId }));
          }, 300);
        }
      });
      el.addEventListener("contextmenu", (e) => {
        e.preventDefault();
        e.stopPropagation();
        const seq = ++kanban._pendingCtxSeq;
        kanban._pendingCtxCardId = cardId;
        kanban._pendingCtxX = e.clientX;
        kanban._pendingCtxY = e.clientY;
        window.chrome.webview.postMessage(JSON.stringify({ type: "CardRightClick", cardId, seq }));
      });
    },
    _rebuildCard(cardId) {
      const card = this._cards[cardId];
      if (!card || !card.el) return;
      const newEl = this._makeCardEl(card);
      card.el.parentNode.replaceChild(newEl, card.el);
      card.el = newEl;
    },
    // ── Context Menu ───────────────────────────────────────────────────────────
    clearContextMenu() {
      this._menuDef = [];
      this._menuMap = {};
      this._hideContextMenu();
    },
    // Called from C# after the CardRightClick event has been handled.
    // Stale-call guard: seq must match the latest right-click token, and the
    // card must still exist. Prevents showing a menu for an outdated right-click
    // even when the same card is right-clicked multiple times before C# responds.
    showContextMenu(cardId, seq) {
      if (seq !== this._pendingCtxSeq) return;
      if (!this._cards[cardId]) return;
      this._pendingCtxCardId = null;
      this._showContextMenu(this._pendingCtxX, this._pendingCtxY, cardId);
    },
    addContextMenuItem(parentId, itemId, label) {
      const node = { type: "item", id: itemId, label };
      this._menuMap[itemId] = node;
      if (!parentId) {
        this._menuDef.push(node);
      } else {
        const parent = this._menuMap[parentId];
        if (parent && isMenuParent(parent)) parent.children.push(node);
      }
    },
    addContextMenuSub(parentId, subId, label) {
      const node = { type: "sub", id: subId, label, children: [] };
      this._menuMap[subId] = node;
      if (!parentId) {
        this._menuDef.push(node);
      } else {
        const parent = this._menuMap[parentId];
        if (parent && isMenuParent(parent)) parent.children.push(node);
      }
    },
    addContextMenuSep(parentId) {
      const node = { type: "sep" };
      if (!parentId) {
        this._menuDef.push(node);
      } else {
        const parent = this._menuMap[parentId];
        if (parent && isMenuParent(parent)) parent.children.push(node);
      }
    },
    addContextMenuRadioGroup(parentId, groupId, label) {
      const node = { type: "radio", id: groupId, label, children: [] };
      this._menuMap[groupId] = node;
      if (!parentId) {
        this._menuDef.push(node);
      } else {
        const parent = this._menuMap[parentId];
        if (parent && isMenuParent(parent)) parent.children.push(node);
      }
    },
    addContextMenuRadioItem(groupId, itemId, label) {
      const group = this._menuMap[groupId];
      if (!group) return;
      const node = { type: "radioitem", id: itemId, groupId, label };
      this._menuMap[itemId] = node;
      if (isMenuParent(group)) group.children.push(node);
    },
    setCardRadioValue(cardId, groupId, itemId) {
      const card = this._cards[cardId];
      if (!card) return;
      if (!itemId) {
        delete card.radioValues[groupId];
      } else {
        card.radioValues[groupId] = itemId;
      }
    },
    _positionSubMenu(li, subEl) {
      const r = li.getBoundingClientRect();
      if (r.right + 170 > window.innerWidth) {
        subEl.style.left = "auto";
        subEl.style.right = "100%";
      } else {
        subEl.style.left = "100%";
        subEl.style.right = "auto";
      }
    },
    _buildMenuEl(nodes, card) {
      const ul = document.createElement("ul");
      ul.className = "ctx-menu";
      nodes.forEach((node) => {
        const li = document.createElement("li");
        if (node.type === "sep") {
          li.className = "ctx-sep";
        } else if (node.type === "item") {
          li.className = "ctx-item";
          li.textContent = node.label;
          li.addEventListener("mousedown", (e) => e.preventDefault());
          li.addEventListener("click", (e) => {
            e.stopPropagation();
            const cardId = kanban._ctxCardId;
            const itemId = node.id;
            kanban._hideContextMenu();
            window.chrome.webview.postMessage(JSON.stringify({
              type: "ContextMenuSelected",
              cardId,
              itemId
            }));
          });
        } else if (node.type === "radio") {
          li.className = "ctx-item ctx-has-sub";
          const span = document.createElement("span");
          span.textContent = node.label;
          li.appendChild(span);
          const subEl = kanban._buildMenuEl(node.children, card);
          li.appendChild(subEl);
          li.addEventListener("mouseenter", () => kanban._positionSubMenu(li, subEl));
        } else if (node.type === "radioitem") {
          const isSelected = card !== null && card.radioValues[node.groupId] === node.id;
          li.className = "ctx-item ctx-radio-item" + (isSelected ? " ctx-radio-checked" : "");
          li.textContent = node.label;
          li.addEventListener("mousedown", (e) => e.preventDefault());
          li.addEventListener("click", (e) => {
            e.stopPropagation();
            const cardId = kanban._ctxCardId;
            const itemId = node.id;
            kanban._hideContextMenu();
            window.chrome.webview.postMessage(JSON.stringify({
              type: "ContextMenuSelected",
              cardId,
              itemId
            }));
          });
        } else if (node.type === "sub") {
          li.className = "ctx-item ctx-has-sub";
          const span = document.createElement("span");
          span.textContent = node.label;
          li.appendChild(span);
          const subEl = kanban._buildMenuEl(node.children, card);
          li.appendChild(subEl);
          li.addEventListener("mouseenter", () => kanban._positionSubMenu(li, subEl));
        }
        ul.appendChild(li);
      });
      return ul;
    },
    _showContextMenu(x, y, cardId) {
      var _a;
      this._hideContextMenu();
      if (!this._menuDef.length) return;
      this._ctxCardId = cardId;
      const card = (_a = this._cards[cardId]) != null ? _a : null;
      const menu = this._buildMenuEl(this._menuDef, card);
      menu.style.position = "fixed";
      menu.style.top = "-9999px";
      menu.style.left = "-9999px";
      document.body.appendChild(menu);
      this._ctxEl = menu;
      const w = menu.offsetWidth || 170;
      const h = menu.offsetHeight || 20;
      const cx = x + w > window.innerWidth ? window.innerWidth - w - 4 : x;
      const cy = y + h > window.innerHeight ? window.innerHeight - h - 4 : y;
      menu.style.left = cx + "px";
      menu.style.top = cy + "px";
    },
    _hideContextMenu() {
      if (this._ctxEl) {
        this._ctxEl.remove();
        this._ctxEl = null;
      }
      this._ctxCardId = null;
    },
    // ── Column Methods ─────────────────────────────────────────────────────────
    addColumn(id, title) {
      if (this._columns[id]) return;
      const col = document.createElement("div");
      col.className = "column";
      col.style.width = this._colWidth + "px";
      const header = document.createElement("div");
      header.className = "column-header";
      const titleEl = document.createElement("span");
      titleEl.className = "column-title";
      titleEl.textContent = title;
      const count = document.createElement("span");
      count.className = "column-count";
      count.textContent = "0";
      header.appendChild(titleEl);
      header.appendChild(count);
      const cardList = document.createElement("div");
      cardList.className = "card-list";
      cardList.dataset.colId = id;
      col.appendChild(header);
      col.appendChild(cardList);
      document.getElementById("board").appendChild(col);
      const entry = { id, el: col, header, titleEl, count, cardList, sortable: null, cardCount: 0 };
      this._columns[id] = entry;
      this._initSortable(entry);
    },
    removeColumn(id) {
      const col = this._columns[id];
      if (!col) return;
      Object.keys(this._cards).forEach((cid) => {
        if (this._cards[cid].columnId === id) {
          delete this._cardFilters[cid];
          delete this._cards[cid];
        }
      });
      if (col.sortable) col.sortable.destroy();
      col.el.remove();
      delete this._columns[id];
    },
    clearColumns() {
      Object.keys(this._columns).forEach((id) => this.removeColumn(id));
    },
    setColumnHeaderColor(id, hex) {
      const col = this._columns[id];
      if (col) col.header.style.backgroundColor = hex;
    },
    setColumnHeaderTextColor(id, hex) {
      const col = this._columns[id];
      if (col) {
        col.titleEl.style.color = hex;
        col.count.style.color = hex;
      }
    },
    setDarkMode(enabled) {
      document.body.classList.toggle("dark", !!enabled);
      const btn = document.getElementById("dm-toggle-btn");
      if (btn) btn.textContent = enabled ? "\u2600\uFE0F" : "\u{1F319}";
    },
    _toggleDarkMode() {
      const isDark = !document.body.classList.contains("dark");
      this.setDarkMode(isDark);
    },
    setAllColumnHeaderTextColor(hex) {
      Object.values(this._columns).forEach((col) => {
        col.titleEl.style.color = hex;
        col.count.style.color = hex;
      });
    },
    setColumnBodyColor(id, hex) {
      const col = this._columns[id];
      if (col) col.el.style.backgroundColor = hex;
    },
    // ── Card Methods ───────────────────────────────────────────────────────────
    addCard(cardId, columnId, title, body) {
      if (this._cards[cardId] || !this._columns[columnId]) return;
      const card = {
        id: cardId,
        columnId,
        title,
        body: body || "",
        bgColor: null,
        textColor: null,
        borderColor: null,
        tag: null,
        tagColor: null,
        assignee: null,
        dueDate: null,
        progress: -1,
        overdue: false,
        statusColor: null,
        statusLabel: null,
        radioValues: {},
        visible: true,
        el: null
        // assigned on the next line
      };
      card.el = this._makeCardEl(card);
      this._cards[cardId] = card;
      this._columns[columnId].cardCount = (this._columns[columnId].cardCount || 0) + 1;
      this._columns[columnId].cardList.appendChild(card.el);
      this._refreshCount(columnId);
    },
    removeCard(cardId) {
      const card = this._cards[cardId];
      if (!card) return;
      const colId = card.columnId;
      card.el.remove();
      if (kanban._lastClickCard === cardId) {
        clearTimeout(kanban._singleClickTimer);
        kanban._singleClickTimer = void 0;
        kanban._lastClickCard = null;
        kanban._lastClickTime = 0;
      }
      delete this._cardFilters[cardId];
      delete this._cards[cardId];
      const colEntry = this._columns[colId];
      if (colEntry) colEntry.cardCount = Math.max(0, (colEntry.cardCount || 0) - 1);
      this._refreshCount(colId);
    },
    clearColumnCards(columnId) {
      Object.keys(this._cards).forEach((id) => {
        if (this._cards[id].columnId === columnId) {
          this._cards[id].el.remove();
          delete this._cardFilters[id];
          delete this._cards[id];
        }
      });
      const col = this._columns[columnId];
      if (col) col.cardCount = 0;
      this._refreshCount(columnId);
    },
    setCardBackgroundColor(cardId, hex) {
      const card = this._cards[cardId];
      if (!card) return;
      card.bgColor = hex;
      this._rebuildCard(cardId);
    },
    setCardTextColor(cardId, hex) {
      const card = this._cards[cardId];
      if (!card) return;
      card.textColor = hex;
      this._rebuildCard(cardId);
    },
    setCardBorderColor(cardId, hex) {
      const card = this._cards[cardId];
      if (!card) return;
      card.borderColor = hex;
      this._rebuildCard(cardId);
    },
    setCardTitle(cardId, title) {
      const card = this._cards[cardId];
      if (!card) return;
      card.title = title;
      this._rebuildCard(cardId);
    },
    setCardBody(cardId, body) {
      const card = this._cards[cardId];
      if (!card) return;
      card.body = body;
      this._rebuildCard(cardId);
    },
    setCardTag(cardId, label, hexColor) {
      const card = this._cards[cardId];
      if (!card) return;
      card.tag = label || null;
      card.tagColor = hexColor || null;
      this._rebuildCard(cardId);
    },
    setCardAssignee(cardId, assignee) {
      const card = this._cards[cardId];
      if (!card) return;
      card.assignee = assignee || null;
      this._rebuildCard(cardId);
    },
    setCardDueDate(cardId, dueDate) {
      const card = this._cards[cardId];
      if (!card) return;
      card.dueDate = dueDate || null;
      this._rebuildCard(cardId);
    },
    setCardProgress(cardId, progress) {
      const card = this._cards[cardId];
      if (!card) return;
      const p = Number(progress);
      card.progress = !isNaN(p) && p >= 0 ? Math.min(100, p) : -1;
      this._rebuildCard(cardId);
    },
    setCardOverdue(cardId, overdue) {
      const card = this._cards[cardId];
      if (!card) return;
      card.overdue = !!overdue;
      this._rebuildCard(cardId);
    },
    setCardStatusBar(cardId, label, hexColor) {
      const card = this._cards[cardId];
      if (!card) return;
      card.statusLabel = label || null;
      card.statusColor = hexColor || null;
      this._rebuildCard(cardId);
    },
    moveCardToTop(cardId) {
      const card = this._cards[cardId];
      if (!card || !card.el) return;
      const col = this._columns[card.columnId];
      if (!col || !col.cardList) return;
      if (col.cardList.firstChild === card.el) return;
      col.cardList.insertBefore(card.el, col.cardList.firstChild);
    },
    moveCard(cardId, columnId) {
      const card = this._cards[cardId];
      if (!card || !this._columns[columnId]) return;
      const fromColumn = card.columnId;
      if (fromColumn === columnId) return;
      card.el.remove();
      this._columns[columnId].cardList.appendChild(card.el);
      const fromCol = this._columns[fromColumn];
      if (fromCol) fromCol.cardCount = Math.max(0, (fromCol.cardCount || 0) - 1);
      this._columns[columnId].cardCount = (this._columns[columnId].cardCount || 0) + 1;
      card.columnId = columnId;
      this._refreshCount(fromColumn);
      this._refreshCount(columnId);
      window.chrome.webview.postMessage(JSON.stringify({
        type: "CardMoved",
        cardId,
        fromColumn,
        toColumn: columnId
      }));
    },
    setColumnWipLimit(columnId, maxCards) {
      this._wipLimits[columnId] = maxCards > 0 ? maxCards : 0;
      this._refreshCount(columnId);
    },
    setCardVisible(cardId, visible) {
      const card = this._cards[cardId];
      if (!card) return;
      card.visible = visible;
      this._applyFilters();
    },
    // ── Board Methods ──────────────────────────────────────────────────────────
    setReadOnly(readOnly) {
      Object.values(this._columns).forEach((col) => {
        if (col.sortable) col.sortable.option("disabled", !!readOnly);
      });
      document.getElementById("board").classList.toggle("board-readonly", !!readOnly);
    },
    // Build toolbar once at startup so buttons are always visible even
    // when setBoardTitle is never called.
    _buildToolbar() {
      const bar = document.getElementById("board-title-bar");
      if (!bar || bar.dataset.toolbarBuilt) return;
      bar.dataset.toolbarBuilt = "1";
      const titleSpan = document.createElement("span");
      titleSpan.className = "board-title-text";
      titleSpan.id = "board-title-text";
      bar.appendChild(titleSpan);
      const filterWrap = document.createElement("div");
      filterWrap.className = "filter-selector";
      filterWrap.id = "filter-wrap";
      const filterBtn = document.createElement("button");
      filterBtn.className = "view-btn filter-btn";
      filterBtn.id = "filter-btn";
      filterBtn.textContent = "\u22C2 Filter";
      const filterPanel = document.createElement("div");
      filterPanel.className = "filter-panel";
      filterPanel.id = "filter-panel";
      this._buildFilterPanel(filterPanel);
      filterBtn.addEventListener("click", (e) => {
        e.stopPropagation();
        filterPanel.classList.toggle("filter-panel--open");
      });
      filterWrap.appendChild(filterBtn);
      filterWrap.appendChild(filterPanel);
      bar.appendChild(filterWrap);
      const dmBtn = document.createElement("button");
      dmBtn.className = "view-btn dm-toggle-btn";
      dmBtn.id = "dm-toggle-btn";
      dmBtn.textContent = document.body.classList.contains("dark") ? "\u2600\uFE0F" : "\u{1F319}";
      dmBtn.title = "Toggle dark mode";
      dmBtn.addEventListener("click", () => this._toggleDarkMode());
      bar.appendChild(dmBtn);
      const sel = document.createElement("div");
      sel.className = "view-selector";
      const btn = document.createElement("button");
      btn.className = "view-btn";
      btn.id = "view-btn";
      btn.textContent = this._currentView === "board" ? "\u229E Board \u25BE" : "\u2630 Table \u25BE";
      const dropdown = document.createElement("ul");
      dropdown.className = "view-dropdown";
      dropdown.id = "view-dropdown";
      ["board", "table"].forEach((v) => {
        const label = v === "board" ? "\u229E Board" : "\u2630 Table";
        const li = document.createElement("li");
        li.className = "view-opt" + (this._currentView === v ? " view-opt--active" : "");
        li.textContent = label;
        li.dataset.view = v;
        li.addEventListener("mousedown", (e) => {
          e.preventDefault();
          this._switchView(v);
        });
        dropdown.appendChild(li);
      });
      btn.addEventListener("click", (e) => {
        e.stopPropagation();
        dropdown.classList.toggle("view-dropdown--open");
      });
      sel.appendChild(btn);
      sel.appendChild(dropdown);
      bar.appendChild(sel);
      bar.style.display = "flex";
      bar.style.backgroundColor = this._titleBg;
      bar.style.color = this._titleText;
    },
    setBoardTitle(title, hexBg, hexText) {
      const bar = document.getElementById("board-title-bar");
      if (!bar) return;
      if (hexBg) {
        this._titleBg = hexBg;
        bar.style.backgroundColor = hexBg;
      }
      if (hexText) {
        this._titleText = hexText;
        bar.style.color = hexText;
      }
      const span = document.getElementById("board-title-text");
      if (span) span.textContent = title || "";
    },
    _switchView(view) {
      this._currentView = view;
      const btn = document.getElementById("view-btn");
      const dropdown = document.getElementById("view-dropdown");
      if (btn) btn.textContent = view === "board" ? "\u229E Board \u25BE" : "\u2630 Table \u25BE";
      if (dropdown) {
        dropdown.classList.remove("view-dropdown--open");
        dropdown.querySelectorAll(".view-opt").forEach((li) => {
          li.classList.toggle("view-opt--active", li.dataset.view === view);
        });
      }
      const board = document.getElementById("board");
      const table = document.getElementById("table-view");
      if (view === "board") {
        board.style.display = "";
        table.style.display = "none";
      } else {
        board.style.display = "none";
        table.style.display = "";
        this._initTableSort();
        this._refreshTable();
      }
    },
    // ── Table View ─────────────────────────────────────────────────────────────
    _initTableSort() {
      if (this._tableSortInit) return;
      this._tableSortInit = true;
      document.querySelectorAll(".kv-table thead th[data-col]").forEach((th) => {
        th.addEventListener("click", (e) => {
          const col = th.dataset.col;
          const idx = this._sortKeys.findIndex((s) => s.col === col);
          if (e.shiftKey) {
            if (idx === -1) {
              this._sortKeys.push({ col, dir: "asc" });
            } else if (this._sortKeys[idx].dir === "asc") {
              this._sortKeys[idx].dir = "desc";
            } else {
              this._sortKeys.splice(idx, 1);
            }
          } else {
            if (idx === -1 || this._sortKeys.length > 1) {
              this._sortKeys = [{ col, dir: "asc" }];
            } else if (this._sortKeys[idx].dir === "asc") {
              this._sortKeys = [{ col, dir: "desc" }];
            } else {
              this._sortKeys = [];
            }
          }
          this._updateSortHeaders();
          this._refreshTable();
        });
      });
    },
    _updateSortHeaders() {
      document.querySelectorAll(".kv-table thead th[data-col]").forEach((th) => {
        const col = th.dataset.col;
        const existing = th.querySelector(".kv-sort-ind");
        if (existing) existing.remove();
        const idx = this._sortKeys.findIndex((s) => s.col === col);
        if (idx === -1) return;
        const { dir } = this._sortKeys[idx];
        const span = document.createElement("span");
        span.className = "kv-sort-ind";
        span.textContent = (dir === "asc" ? " \u25B2" : " \u25BC") + (this._sortKeys.length > 1 ? idx + 1 : "");
        th.appendChild(span);
      });
    },
    _getSortValue(card, col) {
      switch (col) {
        case "title":
          return (card.title || "").toLowerCase();
        case "column": {
          const c = this._columns[card.columnId];
          return c ? c.titleEl.textContent.toLowerCase() : "";
        }
        case "tag":
          return (card.tag || "").toLowerCase();
        case "assignee":
          return (card.assignee || "").toLowerCase();
        case "dueDate": {
          const d = card.dueDate || "";
          const m4 = d.match(/^(\d{2})\/(\d{2})\/(\d{4})$/);
          if (m4) return `${m4[3]}${m4[2]}${m4[1]}`;
          const m2 = d.match(/^(\d{2})\/(\d{2})\/(\d{2})$/);
          if (m2) return `20${m2[3]}${m2[2]}${m2[1]}`;
          return d;
        }
        case "progress":
          return typeof card.progress === "number" ? card.progress : -1;
        case "priority":
          return (card.statusLabel || "").toLowerCase();
        case "body":
          return (card.body || "").toLowerCase();
        default:
          return "";
      }
    },
    _refreshTable() {
      const tbody = document.getElementById("kv-tbody");
      if (!tbody) return;
      this._selectedTableRow = null;
      tbody.innerHTML = "";
      let cards = Object.values(this._cards);
      if (this._sortKeys.length) {
        cards = cards.slice().sort((a, b) => {
          for (const { col, dir } of this._sortKeys) {
            const av = this._getSortValue(a, col);
            const bv = this._getSortValue(b, col);
            let cmp = 0;
            if (typeof av === "number" && typeof bv === "number") {
              cmp = av - bv;
            } else {
              cmp = String(av).localeCompare(String(bv));
            }
            if (cmp !== 0) return dir === "asc" ? cmp : -cmp;
          }
          return 0;
        });
      }
      cards.forEach((card) => {
        const col = this._columns[card.columnId];
        const colTitle = col ? col.titleEl.textContent : card.columnId;
        const tr = document.createElement("tr");
        tr.className = "kv-row";
        tr.dataset.cardId = card.id;
        const cells = [
          `<span class="kv-card-title">${this._esc(card.title)}</span>`,
          this._esc(colTitle),
          card.tag ? `<span class="kv-tag" style="color:${this._esc(card.tagColor || "#5c9fe8")}">${this._esc(card.tag)}</span>` : "",
          this._esc(card.assignee || ""),
          this._esc(card.dueDate || ""),
          card.progress >= 0 ? `<div class="kv-progress"><div class="kv-progress-fill" style="width:${Math.min(100, Math.max(0, card.progress))}%"></div></div><span class="kv-progress-pct">${card.progress}%</span>` : "",
          card.statusColor ? `<span class="kv-priority"><span class="kv-priority-dot" style="background:${this._esc(card.statusColor)}"></span>${this._esc(card.statusLabel || "")}</span>` : "",
          `<span class="kv-body">${this._esc(card.body)}</span>`
        ];
        if (card.visible === false || !this._cardPassesFilter(card)) {
          tr.style.display = "none";
        }
        cells.forEach((html) => {
          const td = document.createElement("td");
          td.innerHTML = html;
          tr.appendChild(td);
        });
        this._attachCardClicks(tr, card.id);
        tbody.appendChild(tr);
      });
    },
    // ── Filter Panel ───────────────────────────────────────────────────────────
    clearFilters() {
      this._filterDef = [];
      this._cardFilters = {};
      this._activeFilters = {};
      this._searchText = "";
      this._rebuildFilterPanel();
      this._applyFilters();
    },
    addFilterGroup(groupId, title) {
      if (this._filterDef.find((g) => g.id === groupId)) return;
      this._filterDef.push({ id: groupId, title, items: [] });
      this._rebuildFilterPanel();
    },
    addFilterItem(groupId, itemId, label, hexColor) {
      const group = this._filterDef.find((g) => g.id === groupId);
      if (!group) return;
      if (group.items.find((i) => i.id === itemId)) return;
      group.items.push({ id: itemId, label, hex: hexColor || "" });
      this._rebuildFilterPanel();
    },
    setCardFilterValue(cardId, groupId, itemId) {
      if (!this._cardFilters[cardId]) this._cardFilters[cardId] = {};
      if (!itemId) {
        delete this._cardFilters[cardId][groupId];
      } else {
        this._cardFilters[cardId][groupId] = itemId;
      }
      this._applyFilters();
    },
    _buildFilterPanel(panel) {
      panel.innerHTML = "";
      const header = document.createElement("div");
      header.className = "fp-header";
      const heading = document.createElement("span");
      heading.className = "fp-heading";
      heading.textContent = "Filter";
      header.appendChild(heading);
      const clearBtn = document.createElement("button");
      clearBtn.className = "fp-clear";
      clearBtn.textContent = "Clear all";
      clearBtn.addEventListener("mousedown", (e) => {
        e.preventDefault();
        this._activeFilters = {};
        this._searchText = "";
        this._applyFilters();
        this._rebuildFilterPanel();
        this._updateFilterBadge();
      });
      header.appendChild(clearBtn);
      panel.appendChild(header);
      if (this._searchEnabled) {
        const searchSec = document.createElement("div");
        searchSec.className = "fp-section fp-search-section";
        const si = document.createElement("input");
        si.type = "text";
        si.className = "fp-search";
        si.placeholder = "Search cards\u2026";
        si.value = this._searchText;
        si.addEventListener("input", (e) => {
          e.stopPropagation();
          this._searchText = si.value;
          this._applyFilters();
          this._updateFilterBadge();
        });
        si.addEventListener("mousedown", (e) => e.stopPropagation());
        si.addEventListener("click", (e) => e.stopPropagation());
        searchSec.appendChild(si);
        panel.appendChild(searchSec);
      }
      this._filterDef.forEach((group) => {
        const section = document.createElement("div");
        section.className = "fp-section";
        const label = document.createElement("div");
        label.className = "fp-group-label";
        label.textContent = group.title;
        section.appendChild(label);
        const list = document.createElement("ul");
        list.className = "fp-list";
        group.items.forEach((item) => {
          var _a, _b;
          const li = document.createElement("li");
          li.className = "fp-item";
          const lbl = document.createElement("label");
          lbl.className = "fp-item-label";
          const cb = document.createElement("input");
          cb.type = "checkbox";
          cb.className = "fp-checkbox";
          cb.checked = (_b = (_a = this._activeFilters[group.id]) == null ? void 0 : _a.has(item.id)) != null ? _b : false;
          cb.addEventListener("mousedown", (e) => {
            e.preventDefault();
          });
          cb.addEventListener("change", () => {
            if (!this._activeFilters[group.id])
              this._activeFilters[group.id] = /* @__PURE__ */ new Set();
            const s = this._activeFilters[group.id];
            if (cb.checked) {
              s.add(item.id);
            } else {
              s.delete(item.id);
              if (!s.size) delete this._activeFilters[group.id];
            }
            this._applyFilters();
            this._updateFilterBadge();
          });
          lbl.appendChild(cb);
          if (item.hex) {
            const dot = document.createElement("span");
            dot.className = "fp-dot";
            dot.style.background = item.hex;
            lbl.appendChild(dot);
          }
          const txt = document.createElement("span");
          txt.textContent = item.label;
          lbl.appendChild(txt);
          li.appendChild(lbl);
          list.appendChild(li);
        });
        section.appendChild(list);
        panel.appendChild(section);
      });
    },
    _rebuildFilterPanel() {
      const panel = document.getElementById("filter-panel");
      if (panel) this._buildFilterPanel(panel);
    },
    _updateFilterBadge() {
      const btn = document.getElementById("filter-btn");
      if (!btn) return;
      const count = Object.keys(this._activeFilters).length + (this._searchEnabled && this._searchText.trim() ? 1 : 0);
      btn.textContent = count > 0 ? `\u22C2 Filter (${count})` : "\u22C2 Filter";
      btn.classList.toggle("filter-btn--active", count > 0);
    },
    _cardPassesFilter(card) {
      var _a;
      for (const [groupId, activeSet] of Object.entries(this._activeFilters)) {
        if (!activeSet.size) continue;
        const val = (_a = this._cardFilters[card.id]) == null ? void 0 : _a[groupId];
        if (!val || !activeSet.has(val)) return false;
      }
      if (this._searchEnabled && this._searchText.trim()) {
        const q = this._searchText.trim().toLowerCase();
        const hay = ((card.title || "") + " " + (card.body || "") + " " + (card.tag || "")).toLowerCase();
        if (!hay.includes(q)) return false;
      }
      return true;
    },
    _applyFilters() {
      Object.values(this._cards).forEach((card) => {
        const show = card.visible !== false && this._cardPassesFilter(card);
        if (card.el) card.el.style.display = show ? "" : "none";
      });
      if (this._currentView === "table") this._refreshTable();
    },
    _esc(str) {
      if (!str) return "";
      return String(str).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/'/g, "&#x27;");
    },
    setTextSearchEnabled(enabled) {
      this._searchEnabled = !!enabled;
      this._searchText = "";
      this._rebuildFilterPanel();
      this._applyFilters();
      this._updateFilterBadge();
    },
    setBoardBackgroundColor(hex) {
      document.body.style.backgroundColor = hex;
      document.getElementById("board").style.backgroundColor = hex;
    },
    setColumnWidth(px) {
      this._colWidth = px;
      Object.values(this._columns).forEach((col) => col.el.style.width = px + "px");
    }
  };
  document.addEventListener("click", () => {
    kanban._hideContextMenu();
    const p = document.getElementById("filter-panel");
    if (p) p.classList.remove("filter-panel--open");
    const d = document.getElementById("view-dropdown");
    if (d) d.classList.remove("view-dropdown--open");
  });
  document.addEventListener("contextmenu", () => {
    kanban._pendingCtxCardId = null;
    kanban._pendingCtxSeq = 0;
    kanban._hideContextMenu();
  });
  window.kanban = kanban;
  kanban._buildToolbar();
  function sendReady(attempts) {
    if (attempts > 100) return;
    try {
      window.chrome.webview.postMessage(JSON.stringify({ type: "ready" }));
    } catch (e) {
      setTimeout(() => sendReady(attempts + 1), 50);
    }
  }
  sendReady(0);
})();
