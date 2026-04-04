using System.Runtime.InteropServices;

namespace GenericKanban
{
    /// <summary>
    /// COM interface for the GenericKanban control.
    /// Provides methods to manage columns, cards, formatting, drag-drop behaviour,
    /// and a configurable right-click context menu.
    /// </summary>
    [ComVisible(true)]
    [Guid("5C2A34DE-EF8B-4372-B028-047882FC7480")]
    [InterfaceType(ComInterfaceType.InterfaceIsDual)]
    public interface IGenericKanban
    {
        // â”€â”€ Column Management â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

        /// <summary>Adds a new column to the board.</summary>
        [DispId(1)]
        void AddColumn(string columnId, string title);

        /// <summary>Removes a column and all its cards from the board.</summary>
        [DispId(2)]
        void RemoveColumn(string columnId);

        /// <summary>Removes all columns and cards from the board.</summary>
        [DispId(3)]
        void ClearColumns();

        /// <summary>Sets the background colour of a column header. hexColor e.g. #3498DB</summary>
        [DispId(4)]
        void SetColumnHeaderColor(string columnId, string hexColor);

        /// <summary>Sets the text colour of a column header.</summary>
        [DispId(5)]
        void SetColumnHeaderTextColor(string columnId, string hexColor);

        /// <summary>Sets the background colour of the column body area.</summary>
        [DispId(6)]
        void SetColumnBodyColor(string columnId, string hexColor);

        // â”€â”€ Card Management â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

        /// <summary>Adds a card to the specified column.</summary>
        [DispId(7)]
        void AddCard(string cardId, string columnId, string title, string body);

        /// <summary>Removes a card by its ID.</summary>
        [DispId(8)]
        void RemoveCard(string cardId);

        /// <summary>Removes all cards from a specific column.</summary>
        [DispId(9)]
        void ClearColumnCards(string columnId);

        /// <summary>Returns the ID of the column that currently contains the specified card. Returns empty string if not found.</summary>
        [DispId(10)]
        string GetCardColumn(string cardId);

        // â”€â”€ Card Formatting â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

        /// <summary>Sets the background colour of a card.</summary>
        [DispId(11)]
        void SetCardBackgroundColor(string cardId, string hexColor);

        /// <summary>Sets the text colour of a card.</summary>
        [DispId(12)]
        void SetCardTextColor(string cardId, string hexColor);

        /// <summary>Sets the border colour of a card.</summary>
        [DispId(13)]
        void SetCardBorderColor(string cardId, string hexColor);

        /// <summary>Updates the title text displayed on an existing card.</summary>
        [DispId(14)]
        void SetCardTitle(string cardId, string title);

        /// <summary>Updates the body text displayed on an existing card.</summary>
        [DispId(15)]
        void SetCardBody(string cardId, string body);

        // â”€â”€ Board-level Formatting â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

        /// <summary>Sets the background colour of the entire board.</summary>
        [DispId(16)]
        void SetBoardBackgroundColor(string hexColor);

        /// <summary>Sets the pixel width used for every column (default 260).</summary>
        [DispId(17)]
        void SetColumnWidth(int width);

        // â”€â”€ Optional Card Metadata â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

        /// <summary>Sets a coloured tag/badge on a card. Pass empty strings to remove.</summary>
        [DispId(18)]
        void SetCardTag(string cardId, string label, string hexColor);

        /// <summary>Sets the assignee name shown at the bottom of a card. Pass empty to remove.</summary>
        [DispId(19)]
        void SetCardAssignee(string cardId, string assignee);

        /// <summary>Sets the due-date string shown at the bottom of a card. Pass empty to remove.</summary>
        [DispId(20)]
        void SetCardDueDate(string cardId, string dueDate);

        /// <summary>Sets the progress bar value (0-100). Pass -1 to hide the bar.</summary>
        [DispId(21)]
        void SetCardProgress(string cardId, int progress);

        /// <summary>Marks a card as overdue (1) or clears it (0). Shows a red OVERDUE badge.</summary>
        [DispId(22)]
        void SetCardOverdue(string cardId, int overdue);

        /// <summary>Sets the board to read-only mode (1) or editable (0). Disables drag-drop when read-only.</summary>
        [DispId(23)]
        void SetReadOnly(int readOnly);

        /// <summary>Sets a coloured left status bar on a card. Pass a label (e.g. "Active") and hex colour. Pass empty strings to remove.</summary>
        [DispId(24)]
        void SetCardStatusBar(string cardId, string label, string hexColor);

        /// <summary>Sets a title bar across the top of the board. Pass empty title to hide. hexBg defaults to #1a1a1a, hexText to #ffffff.</summary>
        [DispId(25)]
        void SetBoardTitle(string title, string hexBg, string hexText);

        // â”€â”€ Context Menu â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

        /// <summary>Clears all context menu items. Call this before rebuilding the menu definition.</summary>
        [DispId(26)]
        void ClearContextMenu();

        /// <summary>
        /// Adds a clickable item to the context menu.
        /// Pass parentId='' to add at the root level, or a submenu ID to nest inside it.
        /// </summary>
        [DispId(27)]
        void AddContextMenuItem(string parentId, string itemId, string label);

        /// <summary>
        /// Adds a submenu container (equivalent to Clarion MENU).
        /// Pass parentId='' for root level, or another submenu ID to nest.
        /// </summary>
        [DispId(28)]
        void AddContextMenuSub(string parentId, string subId, string label);

        /// <summary>
        /// Adds a horizontal separator line.
        /// Pass parentId='' for root level, or a submenu ID to place inside a submenu.
        /// </summary>
        [DispId(29)]
        void AddContextMenuSep(string parentId);

        // ── Context Menu Radio Groups ─────────────────────────────────────────

        /// <summary>
        /// Adds a radio group submenu. Items inside show a bullet next to the currently selected value.
        /// Pass parentId='' for root level. The groupId is used with SetCardRadioValue.
        /// </summary>
        [DispId(30)]
        void AddContextMenuRadioGroup(string parentId, string groupId, string label);

        /// <summary>
        /// Adds a selectable item inside a radio group. Only one item per group can be active per card.
        /// </summary>
        [DispId(31)]
        void AddContextMenuRadioItem(string groupId, string itemId, string label);

        /// <summary>
        /// Sets the currently selected radio item for a specific card and group.
        /// The bullet marker is shown automatically when the card is right-clicked.
        /// Pass empty itemId to clear the selection.
        /// </summary>
        [DispId(32)]
        void SetCardRadioValue(string cardId, string groupId, string itemId);

        /// <summary>
        /// Returns the currently selected radio item ID for a specific card and group.
        /// Returns empty string if no value has been set.
        /// </summary>
        [DispId(33)]
        string GetCardRadioValue(string cardId, string groupId);

        // ── Card Operations ───────────────────────────────────────────────────

        /// <summary>
        /// Moves a card to the top of its current column.
        /// </summary>
        [DispId(34)]
        void MoveCardToTop(string cardId);
    }
}
