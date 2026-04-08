          PROGRAM


          MAP
Main        PROCEDURE()


          END
  INCLUDE('KanbanWrapper.inc'),ONCE




  CODE
  Main()
Main      PROCEDURE()
          MAP
KanbanProcess_Kanban    PROCEDURE
          END

Window      WINDOW('GenericKanban Feature Demo'),AT(,,860,540),FONT('Segoe UI',9),RESIZE,GRAY,MAX,SYSTEM,IMM
              OLE,AT(2,2,615,496),USE(?KanbanOLE)
              END
              
              STRING(''),AT(2,500,615,14),USE(?StatusLabel)
              ! ---- Card update buttons ----
              BUTTON('Update c1 Title / Body / Tag'),AT(620,2,237,14),USE(?BtnUpdateCard)
              BUTTON('Toggle c1 Visible'),AT(620,18,237,14),USE(?BtnToggleVisible)
              BUTTON('Color c1 (Bg / Text / Border)'),AT(620,34,237,14),USE(?BtnColorCard)
              BUTTON('Set c1 Assignee + DueDate'),AT(620,50,237,14),USE(?BtnAssignee)
              BUTTON('Toggle c1 Overdue'),AT(620,66,237,14),USE(?BtnOverdue)
              ! ---- Move buttons ----
              BUTTON('Move c1 -> Studio'),AT(620,86,237,14),USE(?BtnMoveToStudio)
              BUTTON('Move c2 -> Complete'),AT(620,102,237,14),USE(?BtnMoveToComplete)
              BUTTON('Move c1 to Top'),AT(620,118,237,14),USE(?BtnMoveToTop)
              ! ---- Query buttons ----
              BUTTON('Query: c1 Column + Count'),AT(620,138,237,14),USE(?BtnCardInfo)
              BUTTON('Query: c1 Radio Value'),AT(620,154,237,14),USE(?BtnRadioValue)
              ! ---- Board toggle buttons ----
              BUTTON('Toggle Dark Mode'),AT(620,174,237,14),USE(?BtnDarkMode)
              BUTTON('Toggle Read-Only'),AT(620,190,237,14),USE(?BtnReadOnly)
              BUTTON('Toggle Column Width'),AT(620,206,237,14),USE(?BtnColWidth)
              ! ---- Manage buttons ----
              BUTTON('Add New Card (c7)'),AT(620,226,237,14),USE(?BtnAddCard)
              BUTTON('Clear Print Column'),AT(620,242,237,14),USE(?BtnClearColumn)
              BUTTON('Remove c6'),AT(620,258,237,14),USE(?BtnRemoveCard)
              BUTTON('&Close'),AT(777,518,80,14),USE(?CloseButton),DEFAULT
            END
Kanban_Event    EQUATE(Event:User+2000+?KanbanOLE)

Kanban      Class(KanbanWrapperClass)
    ! Derived method overrides
Init                  PROCEDURE(LONG pCtrl),VIRTUAL
OnPageReady           PROCEDURE(),VIRTUAL
OnContextMenuSelected PROCEDURE(STRING pCardId, STRING pActionId),VIRTUAL
OnSingleClick         PROCEDURE(STRING pCardId),VIRTUAL
OnDoubleClick         PROCEDURE(STRING pCardId),VIRTUAL
OnCardRightClick      PROCEDURE(STRING pCardId),VIRTUAL
            End  ! Kanban

CardMeta    LIKE(KanbanCardMeta)
DarkMode    LONG
ReadOnly    LONG
WideColumns LONG
C1Visible   LONG
C1Overdue   LONG
C7Added     LONG

  CODE
  DarkMode  = 1
  C1Visible = 1
  C1Overdue = 1
  OPEN(Window)
  ACCEPT
    CASE EVENT()
    OF EVENT:OpenWindow
      ?KanbanOLE{PROP:Create} = 'GenericKanban.GenericKanbanControl'
      Kanban.Init(?KanbanOLE)
      Kanban.RegisterEvents(?KanbanOLE, Kanban_Event)
    OF EVENT:Accepted
      CASE ACCEPTED()
      OF ?CloseButton
        POST(Event:CloseWindow)

      ! ---- Card updates ----
      OF ?BtnUpdateCard
        Kanban.SetCardTitle('c1', 'Login Bug - FIXED')
        Kanban.SetCardBody('c1', 'Resolved in v2.1. Chrome and Firefox tested.')
        Kanban.SetCardTag('c1', 'Bug Fix', 027AE60h)
        Kanban.SetCardProgress('c1', 100)
        ?StatusLabel{PROP:Text} = 'c1: title, body, tag and progress updated'

      OF ?BtnToggleVisible
        C1Visible = 1 - C1Visible
        Kanban.SetCardVisible('c1', C1Visible)
        IF C1Visible
          ?StatusLabel{PROP:Text} = 'c1 is now visible'
        ELSE
          ?StatusLabel{PROP:Text} = 'c1 is now hidden'
        END

      OF ?BtnColorCard
        Kanban.SetCardBackgroundColor('c1', 0EBF5FBh)
        Kanban.SetCardTextColor('c1', 01A252Fh)
        Kanban.SetCardBorderColor('c1', 02980B9h)
        ?StatusLabel{PROP:Text} = 'c1: background, text and border colors applied'

      OF ?BtnAssignee
        Kanban.SetCardAssignee('c1', 'Mark')
        Kanban.SetCardDueDate('c1', '30/06/26')
        Kanban.SetCardFilterValue('c1', 'assignee', 'mark')  ! Keep assignee filter in sync
        ?StatusLabel{PROP:Text} = 'c1: reassigned to Mark, due date 30/06/26'

      OF ?BtnOverdue
        C1Overdue = 1 - C1Overdue
        Kanban.SetCardOverdue('c1', C1Overdue)
        IF C1Overdue
          ?StatusLabel{PROP:Text} = 'c1 flagged as overdue'
        ELSE
          ?StatusLabel{PROP:Text} = 'c1 overdue flag cleared'
        END

      ! ---- Move operations ----
      OF ?BtnMoveToStudio
        Kanban.MoveCard('c1', 'studio')
        ?StatusLabel{PROP:Text} = 'c1 moved to Studio via MoveCard'

      OF ?BtnMoveToComplete
        Kanban.MoveCard('c2', 'complete')
        ?StatusLabel{PROP:Text} = 'c2 moved to Complete via MoveCard'

      OF ?BtnMoveToTop
        Kanban.MoveCardToTop('c1')
        ?StatusLabel{PROP:Text} = 'c1 moved to top of its current column'

      ! ---- Queries ----
      OF ?BtnCardInfo
        ?StatusLabel{PROP:Text} = 'c1 column: [' & Kanban.GetCardColumn('c1') & ']' & |
          '  |  Not Started has ' & Kanban.GetColumnCardCount('notstarted') & ' card(s)'

      OF ?BtnRadioValue
        ?StatusLabel{PROP:Text} = 'c1 priority: ' & Kanban.GetCardRadioValue('c1', 'status')

      ! ---- Board toggles ----
      OF ?BtnDarkMode
        DarkMode = 1 - DarkMode
        Kanban.SetDarkMode(DarkMode)
        IF DarkMode
          ?StatusLabel{PROP:Text} = 'Dark mode ON'
        ELSE
          ?StatusLabel{PROP:Text} = 'Dark mode OFF'
        END

      OF ?BtnReadOnly
        ReadOnly = 1 - ReadOnly
        Kanban.SetReadOnly(ReadOnly)
        IF ReadOnly
          ?StatusLabel{PROP:Text} = 'Board is read-only (drag disabled)'
        ELSE
          ?StatusLabel{PROP:Text} = 'Board is editable (drag enabled)'
        END

      OF ?BtnColWidth
        WideColumns = 1 - WideColumns
        IF WideColumns
          Kanban.SetColumnWidth(300)
          ?StatusLabel{PROP:Text} = 'Column width: 300px'
        ELSE
          Kanban.SetColumnWidth(200)
          ?StatusLabel{PROP:Text} = 'Column width: 200px (default)'
        END

      ! ---- Manage ----
      OF ?BtnAddCard
        IF C7Added = 0
          Kanban.AddCard('c7', 'notstarted', 'New Card Added at Runtime', 'Added via the basic 4-param AddCard method')
          C7Added = 1
          ?StatusLabel{PROP:Text} = 'c7 added using 4-parameter AddCard'
        ELSE
          ?StatusLabel{PROP:Text} = 'c7 already exists on the board'
        END

      OF ?BtnClearColumn
        Kanban.ClearColumnCards('print')
        ?StatusLabel{PROP:Text} = 'All cards cleared from the Print column'

      OF ?BtnRemoveCard
        Kanban.RemoveCard('c6')
        ?StatusLabel{PROP:Text} = 'c6 removed from board'

      END  ! CASE ACCEPTED
    OF EVENT:CloseWindow
      Kanban.Kill()
      BREAK
    OF Kanban_Event
      KanbanProcess_Kanban()
    END  ! CASE EVENT
  END
  CLOSE(Window)

Kanban.Init   PROCEDURE(LONG pCtrl)
  CODE
  PARENT.Init(pCtrl)
!----------------------------------------------------
Kanban.OnPageReady    PROCEDURE()
  CODE
  PARENT.OnPageReady()

  ! ---- Columns ----
  SELF.AddColumn('notstarted', 'Not Started', 0607D8Bh)
  SELF.AddColumn('studio',     'Studio',      000796Bh)
  SELF.AddColumn('print',      'Print',       0795548h)
  SELF.AddColumn('finishing',  'Finishing',   06A1B9Ah)
  SELF.AddColumn('complete',   'Complete',    0C0392Bh)
  SELF.AddColumn('invoiced',   'Invoiced',    01A3A6Bh)
  SELF.SetAllColumnTextColors(COLOR:White)
  SELF.SetColumnWipLimit('notstarted', 1)        ! Header turns red when exceeded
  SELF.SetColumnBodyColor('complete', 0162C40h)  ! Custom body tint on Complete column

  ! ---- Board appearance ----
  SELF.SetDarkMode(1)
  SELF.SetBoardTitle('Job Tracking Board', 06C3483h, 0FFFFFFh)

  ! ---- Status / priority options (drives filter panel, context menu radio, status bar) ----
  SELF.SetStatusTitle('Priority')
  SELF.AddStatusOption('pri_high',   'High',   0E74C3Ch)
  SELF.AddStatusOption('pri_medium', 'Medium', 0F39C12h)
  SELF.AddStatusOption('pri_low',    'Low',    027AE60h)
  SELF.AddStatusOption('pri_none',   'None',   -1)

  ! ---- Cards: c1-c4 via KanbanCardMeta (full metadata helper) ----
  CLEAR(CardMeta)
  CardMeta.CardId       = 'c1'
  CardMeta.ColumnId     = 'notstarted'
  CardMeta.Title        = 'Fix Login Bug'
  CardMeta.Body         = 'Repro on Chrome only. Test a longer body to see what happens to text'
  CardMeta.Overdue      = 1
  CardMeta.Tag          = 'Artwork'
  CardMeta.TagColor     = 3498DBh
  CardMeta.Assignee     = 'Sarah'
  CardMeta.DueDate      = '04/04/26'
  CardMeta.Progress     = 65
  CardMeta.StatusOption = 'pri_low'
  SELF.AddCard(CardMeta)

  CLEAR(CardMeta)
  CardMeta.CardId       = 'c2'
  CardMeta.ColumnId     = 'studio'
  CardMeta.Title        = 'Write Unit Tests'
  CardMeta.StatusOption = 'pri_medium'
  CardMeta.Assignee     = 'Mark'
  CardMeta.Progress     = -1
  SELF.AddCard(CardMeta)

  CLEAR(CardMeta)
  CardMeta.CardId       = 'c3'
  CardMeta.ColumnId     = 'print'
  CardMeta.Title        = 'Refactor Data Layer'
  CardMeta.Body         = 'Started 01/04/2026'
  CardMeta.StatusOption = 'pri_high'
  CardMeta.Progress     = -1
  SELF.AddCard(CardMeta)

  CLEAR(CardMeta)
  CardMeta.CardId       = 'c4'
  CardMeta.ColumnId     = 'notstarted'
  CardMeta.Title        = 'Deploy to Staging'
  CardMeta.Body         = 'Waiting on c3'
  CardMeta.StatusOption = 'pri_none'
  CardMeta.Progress     = -1
  SELF.AddCard(CardMeta)

  ! c5: added via 4-param AddCard then individual setters (alternative to KanbanCardMeta)
  SELF.AddCard('c5', 'finishing', 'Print Run 1500 Leaflets', 'A4 double-sided gloss')
  SELF.SetCardTag('c5', 'Print', 08E44ADh)
  SELF.SetCardAssignee('c5', 'Sarah')
  SELF.SetCardProgress('c5', 40)
  SELF.SetCardStatusBar('c5', 'Blocked', 0E74C3Ch)  ! Direct status bar (bypasses radio group)

  CLEAR(CardMeta)
  CardMeta.CardId       = 'c6'
  CardMeta.ColumnId     = 'invoiced'
  CardMeta.Title        = 'Annual Report Design'
  CardMeta.Body         = 'Full rebrand. Logo, typography and layout.'
  CardMeta.Tag          = 'Design'
  CardMeta.TagColor     = 09B59B6h
  CardMeta.Assignee     = 'Mark'
  CardMeta.DueDate      = '30/06/26'
  CardMeta.Progress     = 100
  CardMeta.StatusOption = 'pri_none'
  SELF.AddCard(CardMeta)

  ! ---- Filters ----
  SELF.BuildFilterFromStatus()                      ! Adds Priority group from status options
  SELF.AddFilterGroup('assignee', 'Assignee')       ! Manual second filter group
  SELF.AddFilterItem('assignee', 'sarah', 'Sarah', 03498DBh)
  SELF.AddFilterItem('assignee', 'mark',  'Mark',  09B59B6h)
  SELF.SetCardFilterValue('c1', 'assignee', 'sarah')
  SELF.SetCardFilterValue('c2', 'assignee', 'mark')
  SELF.SetCardFilterValue('c5', 'assignee', 'sarah')
  SELF.SetCardFilterValue('c6', 'assignee', 'mark')
  SELF.SetTextSearchEnabled(1)

  ! ---- Context menu ----
  SELF.ClearContextMenu()
  SELF.AddContextMenuItem('', 'edit', 'Edit Card')
  SELF.AddContextMenuSep('')
  SELF.AddContextMenuSub('', 'move_col', 'Move to Column')   ! Sub-menu demo
  SELF.AddContextMenuItem('move_col', 'moveto_notstarted', 'Not Started')
  SELF.AddContextMenuItem('move_col', 'moveto_studio',     'Studio')
  SELF.AddContextMenuItem('move_col', 'moveto_print',      'Print')
  SELF.AddContextMenuItem('move_col', 'moveto_finishing',  'Finishing')
  SELF.AddContextMenuItem('move_col', 'moveto_complete',   'Complete')
  SELF.AddContextMenuItem('move_col', 'moveto_invoiced',   'Invoiced')
  SELF.AddContextMenuItem('', 'move_top', 'Move to Top')
  SELF.AddContextMenuSep('')
  SELF.BuildMenuFromStatus('')                       ! Adds Priority radio group
  SELF.AddContextMenuSep('')
  SELF.AddContextMenuItem('', 'delete', 'Delete Card')
!----------------------------------------------------
Kanban.OnContextMenuSelected  PROCEDURE(STRING pCardId, STRING pActionId)
  CODE
  PARENT.OnContextMenuSelected(pCardId, pActionId)

  CASE pActionId
  OF 'edit'
    ! Placeholder: open your edit dialog here
  OF 'move_top'
    SELF.MoveCardToTop(pCardId)
  OF 'moveto_notstarted'
    SELF.MoveCard(pCardId, 'notstarted')
  OF 'moveto_studio'
    SELF.MoveCard(pCardId, 'studio')
  OF 'moveto_print'
    SELF.MoveCard(pCardId, 'print')
  OF 'moveto_finishing'
    SELF.MoveCard(pCardId, 'finishing')
  OF 'moveto_complete'
    SELF.MoveCard(pCardId, 'complete')
  OF 'moveto_invoiced'
    SELF.MoveCard(pCardId, 'invoiced')
  OF 'pri_high'
  OROF 'pri_medium'
  OROF 'pri_low'
  OROF 'pri_none'
    SELF.SetCardStatus(pCardId, pActionId)
  OF 'delete'
    SELF.RemoveCard(pCardId)
  END
!----------------------------------------------------
Kanban.OnSingleClick  PROCEDURE(STRING pCardId)
  CODE
  PARENT.OnSingleClick(pCardId)
!----------------------------------------------------
Kanban.OnDoubleClick  PROCEDURE(STRING pCardId)
  CODE
  PARENT.OnDoubleClick(pCardId)
!----------------------------------------------------
Kanban.OnCardRightClick   PROCEDURE(STRING pCardId)
  CODE
  PARENT.OnCardRightClick(pCardId)
  ! PARENT base calls ShowContextMenu(pCardId) automatically.
  ! Add pre-menu logic here if needed (e.g. enable/disable items per card).

KanbanProcess_Kanban  PROCEDURE
  CODE

  LOOP WHILE Kanban.GetEvent()
    CASE Kanban.EventName
    OF 'PageReady'
      Kanban.OnPageReady()
    OF 'CardMoved'
      Kanban.OnCardMoved(Kanban.Parm1, Kanban.Parm2, Kanban.Parm3)
      ?StatusLabel{PROP:Text} = Kanban.Parm1 & ' dragged from ' & Kanban.Parm2 & ' to ' & Kanban.Parm3
    OF 'ContextMenuSelected'
      Kanban.OnContextMenuSelected(Kanban.Parm1, Kanban.Parm2)
    OF 'CardDoubleClick'
      Kanban.OnDoubleClick(Kanban.Parm1)
      ?StatusLabel{PROP:Text} = 'Dbl-click: ' & Kanban.Parm1 & |
        '  |  Priority: ' & Kanban.GetCardRadioValue(Kanban.Parm1, 'status')
    OF 'CardClick'
      Kanban.OnSingleClick(Kanban.Parm1)
      ?StatusLabel{PROP:Text} = 'Clicked: ' & Kanban.Parm1 & |
        '  |  Column: ' & Kanban.GetCardColumn(Kanban.Parm1)
    OF 'CardRightClick'
      Kanban.OnCardRightClick(Kanban.Parm1)
    ELSE
      Kanban.OnOtherEvent(Kanban.EventName)
    END
  END

