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

Window      WINDOW('GenericKanban Feature Demo'),AT(,,741,397),GRAY,IMM,SYSTEM, |
              FONT('Segoe UI',9)
              OLE,AT(2,2,615,374),USE(?KanbanOLE)
              END
              STRING(''),AT(2,379,615,14),USE(?StatusLabel)
    ! ---- Card update buttons ----
              BUTTON('Update BUG-001 Title / Body'),AT(620,2,115,14),USE(?BtnUpdateCard)
              BUTTON('Toggle BUG-001 Visible'),AT(620,18,115,14),USE(?BtnToggleVisible)
              BUTTON('Color BUG-001 (Bg/Text/Border)'),AT(620,34,115,14),USE(?BtnColorCard)
              BUTTON('Reassign BUG-001'),AT(620,50,115,14),USE(?BtnAssignee)
              BUTTON('Toggle BUG-001 Overdue'),AT(620,66,115,14),USE(?BtnOverdue)
    ! ---- Move buttons ----
              BUTTON('Move BUG-001 -> Triage'),AT(620,86,115,14),USE(?BtnMoveToTriage)
              BUTTON('Move BUG-002 -> Testing'),AT(620,102,115,14),USE(?BtnMoveToTesting)
              BUTTON('Move BUG-001 to Top'),AT(620,118,115,14),USE(?BtnMoveToTop)
    ! ---- Query buttons ----
              BUTTON('Query: BUG-001 Column'),AT(620,138,115,14),USE(?BtnCardInfo)
              BUTTON('Query: BUG-001 Severity'),AT(620,154,115,14),USE(?BtnRadioValue)
    ! ---- Board toggle buttons ----
              BUTTON('Toggle Dark Mode'),AT(620,174,115,14),USE(?BtnDarkMode)
              BUTTON('Toggle Read-Only'),AT(620,190,115,14),USE(?BtnReadOnly)
              BUTTON('Toggle Column Width'),AT(620,206,115,14),USE(?BtnColWidth)
    ! ---- Manage buttons ----
              BUTTON('Add New Card (c7)'),AT(620,226,115,14),USE(?BtnAddCard)
              BUTTON('Clear Testing Column'),AT(620,242,115,14),USE(?BtnClearColumn)
              BUTTON('Remove BUG-005'),AT(620,258,115,14),USE(?BtnRemoveCard)
              BUTTON('&Close'),AT(620,282,115,14),USE(?CloseButton),DEFAULT
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
        Kanban.SetCardTitle('c1', 'BUG-001 - FIXED')
        Kanban.SetCardBody('c1', 'Root cause: missing activity heartbeat. Fix verified on Chrome, Edge and Firefox.')
        Kanban.SetCardTag('c1', 'Resolved', 027AE60h)
        Kanban.SetCardProgress('c1', 100)
        ?StatusLabel{PROP:Text} = 'BUG-001: title, body, tag and progress updated'

      OF ?BtnToggleVisible
        C1Visible = 1 - C1Visible
        Kanban.SetCardVisible('c1', C1Visible)
        IF C1Visible
          ?StatusLabel{PROP:Text} = 'BUG-001 is now visible'
        ELSE
          ?StatusLabel{PROP:Text} = 'BUG-001 is now hidden'
        END

      OF ?BtnColorCard
        Kanban.SetCardBackgroundColor('c1', 0FDEDECH)
        Kanban.SetCardTextColor('c1', 078281Bh)
        Kanban.SetCardBorderColor('c1', 0E74C3Ch)
        ?StatusLabel{PROP:Text} = 'BUG-001: background, text and border colors applied'

      OF ?BtnAssignee
        Kanban.SetCardAssignee('c1', 'Mark')
        Kanban.SetCardDueDate('c1', '30/06/26')
        Kanban.SetCardFilterValue('c1', 'assignee', 'mark')  ! Keep assignee filter in sync
        ?StatusLabel{PROP:Text} = 'BUG-001: reassigned to Mark, due date 30/06/26'

      OF ?BtnOverdue
        C1Overdue = 1 - C1Overdue
        Kanban.SetCardOverdue('c1', C1Overdue)
        IF C1Overdue
          ?StatusLabel{PROP:Text} = 'BUG-001 flagged as overdue'
        ELSE
          ?StatusLabel{PROP:Text} = 'BUG-001 overdue flag cleared'
        END

      ! ---- Move operations ----
      OF ?BtnMoveToTriage
        Kanban.MoveCard('c1', 'triage')
        ?StatusLabel{PROP:Text} = 'BUG-001 moved to Triage via MoveCard'

      OF ?BtnMoveToTesting
        Kanban.MoveCard('c2', 'testing')
        ?StatusLabel{PROP:Text} = 'BUG-002 moved to Testing via MoveCard'

      OF ?BtnMoveToTop
        Kanban.MoveCardToTop('c1')
        ?StatusLabel{PROP:Text} = 'BUG-001 moved to top of its current column'

      ! ---- Queries ----
      OF ?BtnCardInfo
        ?StatusLabel{PROP:Text} = 'BUG-001 column: [' & Kanban.GetCardColumn('c1') & ']' & |
          '  |  New has ' & Kanban.GetColumnCardCount('new') & ' card(s)'

      OF ?BtnRadioValue
        ?StatusLabel{PROP:Text} = 'BUG-001 severity: ' & Kanban.GetCardRadioValue('c1', 'status')

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
          Kanban.AddCard('c7', 'new', 'BUG-007: Null reference on empty search', 'Occurs when the search box is cleared and submitted.')
          C7Added = 1
          ?StatusLabel{PROP:Text} = 'BUG-007 added using 4-parameter AddCard'
        ELSE
          ?StatusLabel{PROP:Text} = 'BUG-007 already exists on the board'
        END

      OF ?BtnClearColumn
        Kanban.ClearColumnCards('testing')
        ?StatusLabel{PROP:Text} = 'All cards cleared from the Testing column'

      OF ?BtnRemoveCard
        Kanban.RemoveCard('c6')
        ?StatusLabel{PROP:Text} = 'BUG-005 removed from board'

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
  SELF.AddColumn('new',        'New',         02980B9h)
  SELF.AddColumn('triage',     'Triage',      0D35400h)
  SELF.AddColumn('inprogress', 'In Progress', 06C3483h)
  SELF.AddColumn('review',     'In Review',   000796Bh)
  SELF.AddColumn('testing',    'Testing',     0E67E22h)
  SELF.AddColumn('closed',     'Closed',      027AE60h)
  SELF.SetAllColumnTextColors(COLOR:White)
  SELF.SetColumnWipLimit('new', 5)             ! Header turns red when exceeded
  SELF.SetColumnBodyColor('closed', 0EAF7EAh)  ! Subtle green tint on Closed column

  ! ---- Board appearance ----
  SELF.SetDarkMode(1)
  SELF.SetBoardTitle('Bug Tracker', 02C3E50h, 0FFFFFFh)

  ! ---- Severity options (drives filter panel, context menu radio, status bar) ----
  SELF.SetStatusTitle('Severity')
  SELF.AddStatusOption('sev_critical', 'Critical', 0C0392Bh)
  SELF.AddStatusOption('sev_high',     'High',     0E74C3Ch)
  SELF.AddStatusOption('sev_medium',   'Medium',   0F39C12h)
  SELF.AddStatusOption('sev_low',      'Low',      027AE60h)

  ! ---- Cards c1-c4 via KanbanCardMeta ----
  CLEAR(CardMeta)
  CardMeta.CardId       = 'c1'
  CardMeta.ColumnId     = 'new'
  CardMeta.Title        = 'BUG-001: Login timeout not reset on activity'
  CardMeta.Body         = 'Session expires despite user interaction. Reproduced on Chrome, Edge and Firefox.'
  CardMeta.Overdue      = 1
  CardMeta.Tag          = 'Auth'
  CardMeta.TagColor     = 0E74C3Ch
  CardMeta.Assignee     = 'Sarah'
  CardMeta.DueDate      = '01/04/26'
  CardMeta.Progress     = 20
  CardMeta.StatusOption = 'sev_critical'
  SELF.AddCard(CardMeta)

  CLEAR(CardMeta)
  CardMeta.CardId       = 'c2'
  CardMeta.ColumnId     = 'triage'
  CardMeta.Title        = 'BUG-002: PDF export crashes with large datasets'
  CardMeta.Body         = 'Unhandled exception when record count exceeds 1,000. Stack trace attached.'
  CardMeta.Assignee     = 'Mark'
  CardMeta.StatusOption = 'sev_high'
  CardMeta.Progress     = -1
  SELF.AddCard(CardMeta)

  CLEAR(CardMeta)
  CardMeta.CardId       = 'c3'
  CardMeta.ColumnId     = 'inprogress'
  CardMeta.Title        = 'BUG-003: Dashboard chart flickers on window resize'
  CardMeta.Body         = 'Repaint issue in bar chart component. Affects all chart types.'
  CardMeta.Assignee     = 'Sarah'
  CardMeta.Progress     = 45
  CardMeta.StatusOption = 'sev_medium'
  SELF.AddCard(CardMeta)

  CLEAR(CardMeta)
  CardMeta.CardId       = 'c4'
  CardMeta.ColumnId     = 'inprogress'
  CardMeta.Title        = 'FEAT-001: Bulk email export for filtered records'
  CardMeta.Body         = 'Allow users to export the current filtered view as a CSV via email.'
  CardMeta.Tag          = 'Feature'
  CardMeta.TagColor     = 03498DBh
  CardMeta.Assignee     = 'Mark'
  CardMeta.Progress     = 30
  CardMeta.StatusOption = 'sev_low'
  SELF.AddCard(CardMeta)

  ! c5: added via 4-param AddCard then individual setters (alternative to KanbanCardMeta)
  SELF.AddCard('c5', 'review', 'BUG-004: Session cookie not cleared on logout', 'Cookie persists after logout allowing session hijack. Security review required.')
  SELF.SetCardTag('c5', 'Security', 0C0392Bh)
  SELF.SetCardAssignee('c5', 'Sarah')
  SELF.SetCardProgress('c5', 70)
  SELF.SetCardStatusBar('c5', 'Blocked', 0E74C3Ch)  ! Direct status bar (bypasses radio group)

  CLEAR(CardMeta)
  CardMeta.CardId       = 'c6'
  CardMeta.ColumnId     = 'testing'
  CardMeta.Title        = 'BUG-005: Grid column widths reset after sort'
  CardMeta.Body         = 'User column preferences lost on every sort. Full regression test needed.'
  CardMeta.Tag          = 'UI'
  CardMeta.TagColor     = 09B59B6h
  CardMeta.Assignee     = 'Mark'
  CardMeta.DueDate      = '15/06/26'
  CardMeta.Progress     = 80
  CardMeta.StatusOption = 'sev_low'
  SELF.AddCard(CardMeta)

  ! ---- Filters ----
  SELF.BuildFilterFromStatus()                       ! Adds Severity group from status options
  SELF.AddFilterGroup('assignee', 'Assignee')        ! Manual second filter group
  SELF.AddFilterItem('assignee', 'sarah', 'Sarah', 03498DBh)
  SELF.AddFilterItem('assignee', 'mark',  'Mark',  09B59B6h)
  SELF.SetCardFilterValue('c1', 'assignee', 'sarah')
  SELF.SetCardFilterValue('c2', 'assignee', 'mark')
  SELF.SetCardFilterValue('c3', 'assignee', 'sarah')
  SELF.SetCardFilterValue('c4', 'assignee', 'mark')
  SELF.SetCardFilterValue('c5', 'assignee', 'sarah')
  SELF.SetCardFilterValue('c6', 'assignee', 'mark')
  SELF.SetTextSearchEnabled(1)

  ! ---- Context menu ----
  SELF.ClearContextMenu()
  SELF.AddContextMenuItem('', 'edit', 'Edit Issue')
  SELF.AddContextMenuSep('')
  SELF.AddContextMenuSub('', 'move_col', 'Move to Column')   ! Sub-menu demo
  SELF.AddContextMenuItem('move_col', 'moveto_new',        'New')
  SELF.AddContextMenuItem('move_col', 'moveto_triage',     'Triage')
  SELF.AddContextMenuItem('move_col', 'moveto_inprogress', 'In Progress')
  SELF.AddContextMenuItem('move_col', 'moveto_review',     'In Review')
  SELF.AddContextMenuItem('move_col', 'moveto_testing',    'Testing')
  SELF.AddContextMenuItem('move_col', 'moveto_closed',     'Closed')
  SELF.AddContextMenuItem('', 'move_top', 'Move to Top')
  SELF.AddContextMenuSep('')
  SELF.BuildMenuFromStatus('')                       ! Adds Severity radio group
  SELF.AddContextMenuSep('')
  SELF.AddContextMenuItem('', 'delete', 'Delete Issue')
!----------------------------------------------------
Kanban.OnContextMenuSelected  PROCEDURE(STRING pCardId, STRING pActionId)
  CODE
  PARENT.OnContextMenuSelected(pCardId, pActionId)

  CASE pActionId
  OF 'edit'
    ! Placeholder: open your issue edit dialog here
  OF 'move_top'
    SELF.MoveCardToTop(pCardId)
  OF 'moveto_new'
    SELF.MoveCard(pCardId, 'new')
  OF 'moveto_triage'
    SELF.MoveCard(pCardId, 'triage')
  OF 'moveto_inprogress'
    SELF.MoveCard(pCardId, 'inprogress')
  OF 'moveto_review'
    SELF.MoveCard(pCardId, 'review')
  OF 'moveto_testing'
    SELF.MoveCard(pCardId, 'testing')
  OF 'moveto_closed'
    SELF.MoveCard(pCardId, 'closed')
  OF 'sev_critical'
  OROF 'sev_high'
  OROF 'sev_medium'
  OROF 'sev_low'
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
        '  |  Severity: ' & Kanban.GetCardRadioValue(Kanban.Parm1, 'status')
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

