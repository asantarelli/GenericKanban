using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Windows.Forms;
using Microsoft.Web.WebView2.Core;
using Microsoft.Web.WebView2.WinForms;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace GenericKanban
{
    [ComVisible(false)]
    public delegate void CardMovedEventHandler(string cardId, string fromColumnId, string toColumnId);

    [ComVisible(false)]
    public delegate void PageReadyEventHandler();

    [ComVisible(false)]
    public delegate void ContextMenuSelectedEventHandler(string cardId, string itemId);

    [ComVisible(true)]
    [Guid("124E0548-A46F-449D-A10E-E1741D4EB644")]
    [ProgId("GenericKanban.GenericKanbanControl")]
    [ClassInterface(ClassInterfaceType.None)]
    [ComSourceInterfaces(typeof(IGenericKanbanEvents))]
    public class GenericKanbanControl : UserControl, IGenericKanban
    {
        // ----------------------------------------------------------------
        // COM events
        // ----------------------------------------------------------------

        public event CardMovedEventHandler CardMoved;
        public event PageReadyEventHandler PageReady;
        public event ContextMenuSelectedEventHandler ContextMenuSelected;

        // ----------------------------------------------------------------
        // WebView2 state
        // ----------------------------------------------------------------

        private WebView2 _webView;
        private bool _pageReady;
        private readonly List<string> _pending = new List<string>();

        // Shadow state so GetCardColumn() can return synchronously
        private readonly Dictionary<string, string> _cardColumn =
            new Dictionary<string, string>(StringComparer.Ordinal);

        // Shadow state for radio group values: cardId → (groupId → itemId)
        private readonly Dictionary<string, Dictionary<string, string>> _radioValues =
            new Dictionary<string, Dictionary<string, string>>(StringComparer.Ordinal);

        // ----------------------------------------------------------------
        // Loading panel - visible during WebView2 cold-start
        // ----------------------------------------------------------------

        private Panel _loadingPanel;
        private Label _loadingLabel;

        // ----------------------------------------------------------------
        // Construction
        // ----------------------------------------------------------------

        public GenericKanbanControl()
        {
            Size      = new System.Drawing.Size(800, 600);
            BackColor = System.Drawing.Color.FromArgb(240, 242, 245); // matches board bg

            _loadingPanel = new Panel
            {
                Dock      = DockStyle.Fill,
                BackColor = System.Drawing.Color.FromArgb(240, 242, 245)
            };

            _loadingLabel = new Label
            {
                Text      = "Loading\u2026",
                Font      = new System.Drawing.Font("Segoe UI", 11f),
                ForeColor = System.Drawing.Color.FromArgb(94, 108, 132),
                AutoSize  = true
            };

            _loadingPanel.Controls.Add(_loadingLabel);
            _loadingPanel.Resize += (s, e) => CenterLoadingLabel();
            Controls.Add(_loadingPanel);
            _loadingPanel.BringToFront();

            Load += OnLoad;
        }

        private void CenterLoadingLabel()
        {
            if (_loadingLabel == null || _loadingPanel == null) return;
            _loadingLabel.Left = (_loadingPanel.Width  - _loadingLabel.Width)  / 2;
            _loadingLabel.Top  = (_loadingPanel.Height - _loadingLabel.Height) / 2;
        }

        private void OnLoad(object sender, EventArgs e)
        {
            CenterLoadingLabel();
            InitWebViewAsync();
        }

        private async void InitWebViewAsync()
        {
            try
            {
                _webView      = new WebView2 { Dock = DockStyle.Fill };
                Controls.Add(_webView);
                _webView.SendToBack(); // keep loading panel on top during init

                var dllDir = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);

                // Use %TEMP% for the user-data folder.
                // %TEMP% is always local, always writable, and is per-user in Citrix
                // multi-session environments â€” avoiding both network-share slowness
                // and multi-user folder conflicts.
                var userDataPath = Path.Combine(
                    Path.GetTempPath(), "GenericKanban_WebView2Data");

                var env = await CoreWebView2Environment.CreateAsync(null, userDataPath);
                await _webView.EnsureCoreWebView2Async(env);

                _webView.CoreWebView2.SetVirtualHostNameToFolderMapping(
                    "localapp.generickanban",
                    Path.Combine(dllDir, "wwwroot", "controls", "generickanban"),
                    CoreWebView2HostResourceAccessKind.Allow);

                _webView.CoreWebView2.Settings.AreDevToolsEnabled             = false;
                _webView.CoreWebView2.Settings.AreDefaultContextMenusEnabled  = false;
                _webView.CoreWebView2.WebMessageReceived += OnWebMessage;
                _webView.CoreWebView2.Navigate("https://localapp.generickanban/index.html");
            }
            catch (Exception ex)
            {
                // Show the error in the loading panel rather than silently failing
                if (_loadingLabel != null)
                {
                    _loadingLabel.Text      = "Failed to load: " + ex.Message;
                    _loadingLabel.ForeColor = System.Drawing.Color.FromArgb(231, 76, 60);
                    CenterLoadingLabel();
                }
            }
        }

        // ----------------------------------------------------------------
        // Message bridge: JS -> C#
        // ----------------------------------------------------------------

        private void OnWebMessage(object sender, CoreWebView2WebMessageReceivedEventArgs e)
        {
            try
            {
                var msg  = JObject.Parse(e.TryGetWebMessageAsString());
                var type = (string)msg["type"];

                switch (type)
                {
                    case "ready":
                        _pageReady = true;
                        foreach (var s in _pending)
                            _webView.CoreWebView2.ExecuteScriptAsync(s);
                        _pending.Clear();

                        // Board is ready and all queued setup scripts have been sent â€”
                        // hide the loading panel so the board appears cleanly.
                        if (_loadingPanel != null)
                            _loadingPanel.Visible = false;

                        try { PageReady?.Invoke(); } catch { }
                        break;

                    case "CardMoved":
                        var cardId     = (string)msg["cardId"];
                        var fromColumn = (string)msg["fromColumn"];
                        var toColumn   = (string)msg["toColumn"];
                        if (cardId != null)
                            _cardColumn[cardId] = toColumn ?? "";
                        try { CardMoved?.Invoke(cardId, fromColumn, toColumn); } catch { }
                        break;

                    case "ContextMenuSelected":
                        var ctxCardId = (string)msg["cardId"];
                        var itemId    = (string)msg["itemId"];
                        try { ContextMenuSelected?.Invoke(ctxCardId, itemId); } catch { }
                        break;
                }
            }
            catch { }
        }

        // ----------------------------------------------------------------
        // Helpers: script execution
        // ----------------------------------------------------------------

        private void Exec(string script)
        {
            if (InvokeRequired) { BeginInvoke(new Action<string>(Exec), script); return; }
            if (_pageReady && _webView?.CoreWebView2 != null)
                _webView.CoreWebView2.ExecuteScriptAsync(script);
            else
                _pending.Add(script);
        }

        // JSON-encode a string safely for embedding inside a JS call
        private static string J(string v) => JsonConvert.SerializeObject(v ?? "");

        // ----------------------------------------------------------------
        // IGenericKanban â€” Columns
        // ----------------------------------------------------------------

        public void AddColumn(string columnId, string title)
        {
            Exec($"kanban.addColumn({J(columnId)},{J(title)})");
        }

        public void RemoveColumn(string columnId)
        {
            Exec($"kanban.removeColumn({J(columnId)})");
            var toRemove = new List<string>();
            foreach (var kv in _cardColumn)
                if (kv.Value == columnId) toRemove.Add(kv.Key);
            foreach (var id in toRemove) _cardColumn.Remove(id);
        }

        public void ClearColumns()
        {
            Exec("kanban.clearColumns()");
            _cardColumn.Clear();
        }

        public void SetColumnHeaderColor(string columnId, string hexColor)
        {
            Exec($"kanban.setColumnHeaderColor({J(columnId)},{J(hexColor)})");
        }

        public void SetColumnHeaderTextColor(string columnId, string hexColor)
        {
            Exec($"kanban.setColumnHeaderTextColor({J(columnId)},{J(hexColor)})");
        }

        public void SetColumnBodyColor(string columnId, string hexColor)
        {
            Exec($"kanban.setColumnBodyColor({J(columnId)},{J(hexColor)})");
        }

        // ----------------------------------------------------------------
        // IGenericKanban â€” Cards
        // ----------------------------------------------------------------

        public void AddCard(string cardId, string columnId, string title, string body)
        {
            Exec($"kanban.addCard({J(cardId)},{J(columnId)},{J(title)},{J(body)})");
            _cardColumn[cardId] = columnId;
        }

        public void RemoveCard(string cardId)
        {
            Exec($"kanban.removeCard({J(cardId)})");
            _cardColumn.Remove(cardId);
        }

        public void ClearColumnCards(string columnId)
        {
            Exec($"kanban.clearColumnCards({J(columnId)})");
            var toRemove = new List<string>();
            foreach (var kv in _cardColumn)
                if (kv.Value == columnId) toRemove.Add(kv.Key);
            foreach (var id in toRemove) _cardColumn.Remove(id);
        }

        public string GetCardColumn(string cardId)
        {
            _cardColumn.TryGetValue(cardId, out var col);
            return col ?? "";
        }

        // ----------------------------------------------------------------
        // IGenericKanban â€” Card formatting
        // ----------------------------------------------------------------

        public void SetCardBackgroundColor(string cardId, string hexColor)
        {
            Exec($"kanban.setCardBackgroundColor({J(cardId)},{J(hexColor)})");
        }

        public void SetCardTextColor(string cardId, string hexColor)
        {
            Exec($"kanban.setCardTextColor({J(cardId)},{J(hexColor)})");
        }

        public void SetCardBorderColor(string cardId, string hexColor)
        {
            Exec($"kanban.setCardBorderColor({J(cardId)},{J(hexColor)})");
        }

        public void SetCardTitle(string cardId, string title)
        {
            Exec($"kanban.setCardTitle({J(cardId)},{J(title)})");
        }

        public void SetCardBody(string cardId, string body)
        {
            Exec($"kanban.setCardBody({J(cardId)},{J(body)})");
        }

        // ----------------------------------------------------------------
        // IGenericKanban â€” Board
        // ----------------------------------------------------------------

        public void SetBoardBackgroundColor(string hexColor)
        {
            Exec($"kanban.setBoardBackgroundColor({J(hexColor)})");
        }

        public void SetColumnWidth(int width)
        {
            Exec($"kanban.setColumnWidth({width})");
        }

        // ----------------------------------------------------------------
        // IGenericKanban â€” Optional card metadata
        // ----------------------------------------------------------------

        public void SetCardTag(string cardId, string label, string hexColor)
        {
            Exec($"kanban.setCardTag({J(cardId)},{J(label)},{J(hexColor)})");
        }

        public void SetCardAssignee(string cardId, string assignee)
        {
            Exec($"kanban.setCardAssignee({J(cardId)},{J(assignee)})");
        }

        public void SetCardDueDate(string cardId, string dueDate)
        {
            Exec($"kanban.setCardDueDate({J(cardId)},{J(dueDate)})");
        }

        public void SetCardProgress(string cardId, int progress)
        {
            Exec($"kanban.setCardProgress({J(cardId)},{progress})");
        }

        public void SetCardOverdue(string cardId, int overdue)
        {
            Exec($"kanban.setCardOverdue({J(cardId)},{(overdue != 0 ? "true" : "false")})");
        }

        public void SetReadOnly(int readOnly)
        {
            Exec($"kanban.setReadOnly({(readOnly != 0 ? "true" : "false")})");
        }

        public void SetCardStatusBar(string cardId, string label, string hexColor)
        {
            Exec($"kanban.setCardStatusBar({J(cardId)},{J(label)},{J(hexColor)})");
        }

        public void SetBoardTitle(string title, string hexBg, string hexText)
        {
            Exec($"kanban.setBoardTitle({J(title)},{J(hexBg)},{J(hexText)})");
        }

        // ----------------------------------------------------------------
        // IGenericKanban â€” Context Menu
        // ----------------------------------------------------------------

        public void ClearContextMenu()
        {
            Exec("kanban.clearContextMenu()");
        }

        public void AddContextMenuItem(string parentId, string itemId, string label)
        {
            Exec($"kanban.addContextMenuItem({J(parentId)},{J(itemId)},{J(label)})");
        }

        public void AddContextMenuSub(string parentId, string subId, string label)
        {
            Exec($"kanban.addContextMenuSub({J(parentId)},{J(subId)},{J(label)})");
        }

        public void AddContextMenuSep(string parentId)
        {
            Exec($"kanban.addContextMenuSep({J(parentId)})");
        }

        public void AddContextMenuRadioGroup(string parentId, string groupId, string label)
        {
            Exec($"kanban.addContextMenuRadioGroup({J(parentId)},{J(groupId)},{J(label)})");
        }

        public void AddContextMenuRadioItem(string groupId, string itemId, string label)
        {
            Exec($"kanban.addContextMenuRadioItem({J(groupId)},{J(itemId)},{J(label)})");
        }

        public void SetCardRadioValue(string cardId, string groupId, string itemId)
        {
            if (!_radioValues.ContainsKey(cardId))
                _radioValues[cardId] = new Dictionary<string, string>(StringComparer.Ordinal);
            _radioValues[cardId][groupId] = itemId ?? "";
            Exec($"kanban.setCardRadioValue({J(cardId)},{J(groupId)},{J(itemId)})");
        }

        public string GetCardRadioValue(string cardId, string groupId)
        {
            if (_radioValues.TryGetValue(cardId, out var groups) &&
                groups.TryGetValue(groupId, out var itemId))
                return itemId;
            return "";
        }

        public void MoveCardToTop(string cardId)
        {
            Exec($"kanban.moveCardToTop({J(cardId)})");
        }

        // ----------------------------------------------------------------
        // Filter Panel
        // ----------------------------------------------------------------

        public void ClearFilters()
        {
            Exec("kanban.clearFilters()");
        }

        public void AddFilterGroup(string groupId, string title)
        {
            Exec($"kanban.addFilterGroup({J(groupId)},{J(title)})");
        }

        public void AddFilterItem(string groupId, string itemId, string label, string hexColor)
        {
            Exec($"kanban.addFilterItem({J(groupId)},{J(itemId)},{J(label)},{J(hexColor)})");
        }

        public void SetCardFilterValue(string cardId, string groupId, string itemId)
        {
            Exec($"kanban.setCardFilterValue({J(cardId)},{J(groupId)},{J(itemId)})");
        }

        // ----------------------------------------------------------------
        // Cleanup
        // ----------------------------------------------------------------

        protected override void Dispose(bool disposing)
        {
            if (disposing)
                _webView?.Dispose();
            base.Dispose(disposing);
        }
    }
}
