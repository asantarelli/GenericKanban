using System.Runtime.InteropServices;

namespace GenericKanban
{
    /// <summary>
    /// COM outbound events fired by the GenericKanban control back to Clarion.
    /// </summary>
    [ComVisible(true)]
    [Guid("CBEB822E-19C0-45E7-A6CB-BFCF6916199C")]
    [InterfaceType(ComInterfaceType.InterfaceIsIDispatch)]
    public interface IGenericKanbanEvents
    {
        /// <summary>
        /// Fired after a card is successfully dragged from one column to another.
        /// </summary>
        /// <param name="cardId">ID of the card that was moved.</param>
        /// <param name="fromColumnId">ID of the column the card was dragged FROM.</param>
        /// <param name="toColumnId">ID of the column the card was dragged TO.</param>
        [DispId(1)]
        void CardMoved(string cardId, string fromColumnId, string toColumnId);

        /// <summary>
        /// Fired when the WebView2 page has fully loaded and is ready to receive commands.
        /// Use this event to safely call AddColumn, AddCard, SetReadOnly etc.
        /// </summary>
        [DispId(2)]
        void PageReady();

        /// <summary>
        /// Fired when the user selects an item from the card right-click context menu.
        /// </summary>
        /// <param name="cardId">ID of the card that was right-clicked.</param>
        /// <param name="itemId">ID of the menu item that was selected.</param>
        [DispId(3)]
        void ContextMenuSelected(string cardId, string itemId);
        /// <summary>
        /// Fired when the user double-clicks a card (two clicks within 300 ms).
        /// </summary>
        /// <param name="cardId">ID of the card that was double-clicked.</param>
        [DispId(4)]
        void CardDoubleClick(string cardId);

        /// <summary>
        /// Fired when the user single-clicks a card (confirmed after 300ms with no second click).
        /// </summary>
        /// <param name="cardId">ID of the card that was clicked.</param>
        [DispId(5)]
        void CardClick(string cardId);

        /// <summary>
        /// Fired when the user right-clicks a card, before the context menu is shown.
        /// Call ShowContextMenu(cardId) from your event handler (or let the base OnCardRightClick do it)
        /// to display the menu at the position of the right-click.
        /// </summary>
        /// <param name="cardId">ID of the card that was right-clicked.</param>
        [DispId(6)]
        void CardRightClick(string cardId);
    }
}
