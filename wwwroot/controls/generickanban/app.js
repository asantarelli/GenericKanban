(function () {
  'use strict';

  const kanban = {
    _columns: {},
    _cards:   {},
    _colWidth: 260,
    _currentView: 'board',
    _titleBg:     '#1a1a1a',
    _titleText:   '#ffffff',
    _currentView: 'board',
    _titleBg:   '#1a1a1a',
    _titleText: '#ffffff',

    // â”€â”€ Context menu state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    _menuDef:   [],   // root-level node array
    _menuMap:   {},   // id â†’ node (for parent lookups when building)
    _ctxCardId: null, // card that was right-clicked
    _ctxEl:     null, // current visible menu DOM element

    _initSortable(col) {
      col.sortable = new Sortable(col.cardList, {
        group:                'kanban-cards',
        animation:            180,
        easing:               'cubic-bezier(.25,1,.5,1)',
        ghostClass:           'card-ghost',
        chosenClass:          'card-chosen',
        dragClass:            'card-drag',
        emptyInsertThreshold: 20,
        onEnd(evt) {
          const cardId     = evt.item.dataset.cardId;
          const fromColumn = evt.from.dataset.colId;
          const toColumn   = evt.to.dataset.colId;
          if (kanban._cards[cardId]) kanban._cards[cardId].columnId = toColumn;
          kanban._refreshCount(fromColumn);
          if (toColumn !== fromColumn) kanban._refreshCount(toColumn);
          window.chrome.webview.postMessage(JSON.stringify({
            type: 'CardMoved', cardId, fromColumn, toColumn
          }));
        }
      });
    },

    _refreshCount(columnId) {
      const col = this._columns[columnId];
      if (!col) return;
      const n = Object.values(this._cards).filter(c => c.columnId === columnId).length;
      col.count.textContent = n;
    },

    _makeCardEl(card) {
      const el = document.createElement('div');
      el.className      = 'card';
      el.dataset.cardId = card.id;
      if (card.bgColor) el.style.backgroundColor = card.bgColor;

      // Right-click: show context menu if one has been defined
      el.addEventListener('contextmenu', e => {
        if (!kanban._menuDef.length) return;
        e.preventDefault();
        e.stopPropagation();
        kanban._showContextMenu(e.clientX, e.clientY, card.id);
      });

      // Optional left status bar
      const bar = document.createElement('div');
      bar.className = 'card-statusbar';
      if (card.statusColor) {
        bar.style.backgroundColor = card.statusColor;
        if (card.statusLabel) {
          bar.classList.add('card-statusbar--wide');
          const lbl = document.createElement('span');
          lbl.className   = 'card-statusbar-label';
          lbl.textContent = card.statusLabel;
          bar.appendChild(lbl);
        }
      }
      el.appendChild(bar);

      // Card content wrapper
      const content = document.createElement('div');
      content.className = 'card-content';

      if (card.tag) {
        const tag = document.createElement('div');
        tag.className   = 'card-tag';
        tag.textContent = card.tag;
        if (card.tagColor) tag.style.color = card.tagColor;
        content.appendChild(tag);
      }

      const t = document.createElement('div');
      t.className   = 'card-title';
      t.textContent = card.title;
      if (card.textColor) t.style.color = card.textColor;
      content.appendChild(t);

      if (card.body) {
        const b = document.createElement('div');
        b.className   = 'card-body';
        b.textContent = card.body;
        if (card.textColor) b.style.color = card.textColor;
        content.appendChild(b);
      }

      if (card.overdue) {
        const ov = document.createElement('div');
        ov.className   = 'card-overdue';
        ov.textContent = 'OVERDUE';
        content.appendChild(ov);
      }

      if (card.assignee || card.dueDate) {
        const meta = document.createElement('div');
        meta.className = 'card-meta';
        if (card.assignee) {
          const a = document.createElement('span');
          a.className   = 'card-assignee';
          a.textContent = card.assignee;
          meta.appendChild(a);
        }
        if (card.dueDate) {
          const d = document.createElement('span');
          d.className   = 'card-due';
          d.textContent = 'Due: ' + card.dueDate;
          meta.appendChild(d);
        }
        content.appendChild(meta);
      }

      if (card.progress >= 0) {
        const wrap = document.createElement('div');
        wrap.className = 'card-progress-bar';
        const fill = document.createElement('div');
        fill.className = 'card-progress-fill';
        fill.style.width = Math.min(100, Math.max(0, card.progress)) + '%';
        if (card.tagColor) fill.style.backgroundColor = card.tagColor;
        wrap.appendChild(fill);
        content.appendChild(wrap);
      }

      el.appendChild(content);
      return el;
    },

    _rebuildCard(cardId) {
      const card = this._cards[cardId];
      if (!card || !card.el) return;
      const newEl = this._makeCardEl(card);
      card.el.parentNode.replaceChild(newEl, card.el);
      card.el = newEl;
    },

    // â”€â”€ Context Menu â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    clearContextMenu() {
      this._menuDef = [];
      this._menuMap = {};
      this._radioGrps = {};
      this._hideContextMenu();
    },

    addContextMenuItem(parentId, itemId, label) {
      const node = { type: 'item', id: itemId, label };
      this._menuMap[itemId] = node;
      if (!parentId) {
        this._menuDef.push(node);
      } else {
        const parent = this._menuMap[parentId];
        if (parent) parent.children.push(node);
      }
    },

    addContextMenuSub(parentId, subId, label) {
      const node = { type: 'sub', id: subId, label, children: [] };
      this._menuMap[subId] = node;
      if (!parentId) {
        this._menuDef.push(node);
      } else {
        const parent = this._menuMap[parentId];
        if (parent) parent.children.push(node);
      }
    },

    addContextMenuSep(parentId) {
      const node = { type: 'sep' };
      if (!parentId) {
        this._menuDef.push(node);
      } else {
        const parent = this._menuMap[parentId];
        if (parent) parent.children.push(node);
      }
    },

    addContextMenuRadioGroup(parentId, groupId, label) {
      const node = { type: 'radio', id: groupId, label, children: [] };
      this._menuMap[groupId] = node;
      this._radioGrps[groupId] = groupId;
      if (!parentId) {
        this._menuDef.push(node);
      } else {
        const parent = this._menuMap[parentId];
        if (parent) parent.children.push(node);
      }
    },

    addContextMenuRadioItem(groupId, itemId, label) {
      const group = this._menuMap[groupId];
      if (!group) return;
      const node = { type: 'radioitem', id: itemId, groupId, label };
      this._menuMap[itemId] = node;
      group.children.push(node);
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

    moveCardToTop(cardId) {
      const card = this._cards[cardId];
      if (!card || !card.el) return;
      const col = this._columns[card.columnId];
      if (!col || !col.cardList) return;
      if (col.cardList.firstChild === card.el) return;
      col.cardList.insertBefore(card.el, col.cardList.firstChild);
    },

    _buildMenuEl(nodes, card) {
      const ul = document.createElement('ul');
      ul.className = 'ctx-menu';

      nodes.forEach(node => {
        const li = document.createElement('li');

        if (node.type === 'sep') {
          li.className = 'ctx-sep';

        } else if (node.type === 'item') {
          li.className = 'ctx-item';
          li.textContent = node.label;
          li.addEventListener('mousedown', e => e.preventDefault());
          li.addEventListener('click', e => {
            e.stopPropagation();
            const cardId = kanban._ctxCardId;
            const itemId = node.id;
            kanban._hideContextMenu();
            window.chrome.webview.postMessage(JSON.stringify({
              type: 'ContextMenuSelected', cardId, itemId
            }));
          });

        } else if (node.type === 'radio') {
          // Radio group — renders as a submenu
          li.className = 'ctx-item ctx-has-sub';
          const span = document.createElement('span');
          span.textContent = node.label;
          li.appendChild(span);
          const subEl = kanban._buildMenuEl(node.children, card);
          li.appendChild(subEl);
          li.addEventListener('mouseenter', () => {
            const r = li.getBoundingClientRect();
            if (r.right + 170 > window.innerWidth) {
              subEl.style.left  = 'auto';
              subEl.style.right = '100%';
            } else {
              subEl.style.left  = '100%';
              subEl.style.right = 'auto';
            }
          });

        } else if (node.type === 'radioitem') {
          const isSelected = card && card.radioValues[node.groupId] === node.id;
          li.className = 'ctx-item ctx-radio-item' + (isSelected ? ' ctx-radio-checked' : '');
          li.textContent = node.label;
          li.addEventListener('mousedown', e => e.preventDefault());
          li.addEventListener('click', e => {
            e.stopPropagation();
            const cardId = kanban._ctxCardId;
            const itemId = node.id;
            kanban._hideContextMenu();
            window.chrome.webview.postMessage(JSON.stringify({
              type: 'ContextMenuSelected', cardId, itemId
            }));
          });

        } else if (node.type === 'sub') {
          li.className = 'ctx-item ctx-has-sub';
          const span = document.createElement('span');
          span.textContent = node.label;
          li.appendChild(span);
          const subEl = kanban._buildMenuEl(node.children, card);
          li.appendChild(subEl);
          li.addEventListener('mouseenter', () => {
            const r = li.getBoundingClientRect();
            if (r.right + 170 > window.innerWidth) {
              subEl.style.left  = 'auto';
              subEl.style.right = '100%';
            } else {
              subEl.style.left  = '100%';
              subEl.style.right = 'auto';
            }
          });
        }

        ul.appendChild(li);
      });

      return ul;
    },

    _showContextMenu(x, y, cardId) {
      this._hideContextMenu();
      if (!this._menuDef.length) return;
      this._ctxCardId = cardId;
      const card = this._cards[cardId] || null;

      const menu = this._buildMenuEl(this._menuDef, card);
      // Place off-screen first so we can measure it
      menu.style.position = 'fixed';
      menu.style.top      = '-9999px';
      menu.style.left     = '-9999px';
      document.body.appendChild(menu);
      this._ctxEl = menu;

      // Clamp to viewport so menu never appears off-screen
      const w  = menu.offsetWidth  || 170;
      const h  = menu.offsetHeight || 20;
      const cx = (x + w > window.innerWidth)  ? window.innerWidth  - w - 4 : x;
      const cy = (y + h > window.innerHeight) ? window.innerHeight - h - 4 : y;
      menu.style.left = cx + 'px';
      menu.style.top  = cy + 'px';
    },

    _hideContextMenu() {
      if (this._ctxEl) { this._ctxEl.remove(); this._ctxEl = null; }
      this._ctxCardId = null;
    },

    // â”€â”€ Column Methods â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    addColumn(id, title) {
      if (this._columns[id]) return;
      const col = document.createElement('div');
      col.className = 'column';
      col.style.width = this._colWidth + 'px';

      const header = document.createElement('div');
      header.className = 'column-header';

      const titleEl = document.createElement('span');
      titleEl.className   = 'column-title';
      titleEl.textContent = title;

      const count = document.createElement('span');
      count.className   = 'column-count';
      count.textContent = '0';

      header.appendChild(titleEl);
      header.appendChild(count);

      const cardList = document.createElement('div');
      cardList.className     = 'card-list';
      cardList.dataset.colId = id;

      col.appendChild(header);
      col.appendChild(cardList);
      document.getElementById('board').appendChild(col);

      const entry = { id, el: col, header, titleEl, count, cardList, sortable: null };
      this._columns[id] = entry;
      this._initSortable(entry);
    },

    removeColumn(id) {
      const col = this._columns[id];
      if (!col) return;
      Object.keys(this._cards).forEach(cid => {
        if (this._cards[cid].columnId === id) delete this._cards[cid];
      });
      if (col.sortable) col.sortable.destroy();
      col.el.remove();
      delete this._columns[id];
    },

    clearColumns() {
      Object.keys(this._columns).forEach(id => this.removeColumn(id));
    },

    setColumnHeaderColor(id, hex) {
      const col = this._columns[id];
      if (col) col.header.style.backgroundColor = hex;
    },

    setColumnHeaderTextColor(id, hex) {
      const col = this._columns[id];
      if (col) col.titleEl.style.color = hex;
    },

    setColumnBodyColor(id, hex) {
      const col = this._columns[id];
      if (col) col.el.style.backgroundColor = hex;
    },

    // â”€â”€ Card Methods â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    addCard(cardId, columnId, title, body) {
      if (this._cards[cardId] || !this._columns[columnId]) return;
      const card = {
        id: cardId, columnId, title, body: body || '',
        bgColor: null, textColor: null, borderColor: null,
        tag: null, tagColor: null,
        assignee: null, dueDate: null,
        progress: -1, overdue: false,
        statusColor: null, statusLabel: null,
        radioValues: {}   // groupId → selected itemId
      };
      const el = this._makeCardEl(card);
      card.el = el;
      this._cards[cardId] = card;
      this._columns[columnId].cardList.appendChild(el);
      this._refreshCount(columnId);
    },

    removeCard(cardId) {
      const card = this._cards[cardId];
      if (!card) return;
      const colId = card.columnId;
      card.el.remove();
      delete this._cards[cardId];
      this._refreshCount(colId);
    },

    clearColumnCards(columnId) {
      Object.keys(this._cards).forEach(id => {
        if (this._cards[id].columnId === columnId) {
          this._cards[id].el.remove();
          delete this._cards[id];
        }
      });
      this._refreshCount(columnId);
    },

    setCardBackgroundColor(cardId, hex) {
      const card = this._cards[cardId]; if (!card) return;
      card.bgColor = hex; this._rebuildCard(cardId);
    },

    setCardTextColor(cardId, hex) {
      const card = this._cards[cardId]; if (!card) return;
      card.textColor = hex; this._rebuildCard(cardId);
    },

    setCardBorderColor(cardId, hex) {
      const card = this._cards[cardId]; if (!card) return;
      card.borderColor = hex; this._rebuildCard(cardId);
    },

    setCardTitle(cardId, title) {
      const card = this._cards[cardId]; if (!card) return;
      card.title = title; this._rebuildCard(cardId);
    },

    setCardBody(cardId, body) {
      const card = this._cards[cardId]; if (!card) return;
      card.body = body; this._rebuildCard(cardId);
    },

    setCardTag(cardId, label, hexColor) {
      const card = this._cards[cardId]; if (!card) return;
      card.tag = label || null; card.tagColor = hexColor || null;
      this._rebuildCard(cardId);
    },

    setCardAssignee(cardId, assignee) {
      const card = this._cards[cardId]; if (!card) return;
      card.assignee = assignee || null; this._rebuildCard(cardId);
    },

    setCardDueDate(cardId, dueDate) {
      const card = this._cards[cardId]; if (!card) return;
      card.dueDate = dueDate || null; this._rebuildCard(cardId);
    },

    setCardProgress(cardId, progress) {
      const card = this._cards[cardId]; if (!card) return;
      card.progress = (progress >= 0) ? progress : -1; this._rebuildCard(cardId);
    },

    setCardOverdue(cardId, overdue) {
      const card = this._cards[cardId]; if (!card) return;
      card.overdue = !!overdue; this._rebuildCard(cardId);
    },

    setCardStatusBar(cardId, label, hexColor) {
      const card = this._cards[cardId]; if (!card) return;
      card.statusLabel = label    || null;
      card.statusColor = hexColor || null;
      this._rebuildCard(cardId);
    },

    // â”€â”€ Board Methods â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    setReadOnly(readOnly) {
      Object.values(this._columns).forEach(col => {
        if (col.sortable) col.sortable.option('disabled', !!readOnly);
      });
      document.getElementById('board').classList.toggle('board-readonly', !!readOnly);
    },

    setBoardTitle(title, hexBg, hexText) {
      const bar = document.getElementById('board-title-bar');
      if (!title) { bar.style.display = 'none'; bar.innerHTML = ''; return; }
      this._titleBg   = hexBg   || '#1a1a1a';
      this._titleText = hexText || '#ffffff';
      bar.style.display         = 'flex';
      bar.style.backgroundColor = this._titleBg;
      bar.style.color           = this._titleText;
      bar.innerHTML = '';

      const titleSpan = document.createElement('span');
      titleSpan.className   = 'board-title-text';
      titleSpan.textContent = title;
      bar.appendChild(titleSpan);

      const sel = document.createElement('div');
      sel.className = 'view-selector';

      const btn = document.createElement('button');
      btn.className = 'view-btn';
      btn.id = 'view-btn';
      btn.textContent = this._currentView === 'board' ? '\u229e Board \u25be' : '\u2630 Table \u25be';

      const dropdown = document.createElement('ul');
      dropdown.className = 'view-dropdown';
      dropdown.id = 'view-dropdown';

      [['board', '\u229e Board'], ['table', '\u2630 Table']].forEach(([v, label]) => {
        const li = document.createElement('li');
        li.className = 'view-opt' + (this._currentView === v ? ' view-opt--active' : '');
        li.textContent = label;
        li.dataset.view = v;
        li.addEventListener('mousedown', e => { e.preventDefault(); this._switchView(v); });
        dropdown.appendChild(li);
      });

      btn.addEventListener('click', e => {
        e.stopPropagation();
        dropdown.classList.toggle('view-dropdown--open');
      });

      sel.appendChild(btn);
      sel.appendChild(dropdown);
      bar.appendChild(sel);
    },

    _switchView(view) {
      this._currentView = view;
      const btn      = document.getElementById('view-btn');
      const dropdown = document.getElementById('view-dropdown');
      if (btn) btn.textContent = view === 'board' ? '\u229e Board \u25be' : '\u2630 Table \u25be';
      if (dropdown) {
        dropdown.classList.remove('view-dropdown--open');
        dropdown.querySelectorAll('.view-opt').forEach(li => {
          li.classList.toggle('view-opt--active', li.dataset.view === view);
        });
      }
      const board = document.getElementById('board');
      const table = document.getElementById('table-view');
      if (view === 'board') {
        board.style.display = '';
        table.style.display = 'none';
      } else {
        board.style.display = 'none';
        table.style.display = '';
        this._refreshTable();
      }
    },

    _refreshTable() {
      const tbody = document.getElementById('kv-tbody');
      if (!tbody) return;
      tbody.innerHTML = '';
      Object.values(this._cards).forEach(card => {
        const col      = this._columns[card.columnId];
        const colTitle = col ? col.titleEl.textContent : card.columnId;
        const tr = document.createElement('tr');
        tr.className      = 'kv-row';
        tr.dataset.cardId = card.id;

        const cells = [
          `<span class="kv-card-title">${this._esc(card.title)}</span>`,
          this._esc(colTitle),
          card.tag
            ? `<span class="kv-tag" style="color:${this._esc(card.tagColor || '#5c9fe8')}">${this._esc(card.tag)}</span>`
            : '',
          this._esc(card.assignee || ''),
          this._esc(card.dueDate  || ''),
          card.progress >= 0
            ? `<div class="kv-progress"><div class="kv-progress-fill" style="width:${card.progress}%"></div></div><span class="kv-progress-pct">${card.progress}%</span>`
            : '',
          card.statusColor
            ? `<span class="kv-priority"><span class="kv-priority-dot" style="background:${this._esc(card.statusColor)}"></span>${this._esc(card.statusLabel || '')}</span>`
            : '',
          `<span class="kv-body">${this._esc(card.body)}</span>`,
        ];

        cells.forEach(html => {
          const td = document.createElement('td');
          td.innerHTML = html;
          tr.appendChild(td);
        });
        tbody.appendChild(tr);
      });
    },

    _esc(str) {
      if (!str) return '';
      return String(str)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    },

    setBoardBackgroundColor(hex) {
      document.body.style.backgroundColor = hex;
      document.getElementById('board').style.backgroundColor = hex;
    },

    setColumnWidth(px) {
      this._colWidth = px;
      Object.values(this._columns).forEach(col => col.el.style.width = px + 'px');
    }
  };

  // Dismiss context menu on any click or right-click outside a card
  document.addEventListener('click',        () => kanban._hideContextMenu());
  document.addEventListener('contextmenu',  e  => {
    // Only dismiss if the right-click was NOT on a card (cards call stopPropagation)
    kanban._hideContextMenu();
  });

  window.kanban = kanban;

  function sendReady() {
    try {
      window.chrome.webview.postMessage(JSON.stringify({ type: 'ready' }));
    } catch (e) {
      setTimeout(sendReady, 50);
    }
  }
  sendReady();
})();
