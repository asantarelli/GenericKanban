          MEMBER

! =============================================================================
! KanbanWrapper.clw
! Implementation of KanbanWrapperClass.
! Self-contained: no StringTheory or UltimateCOM dependency.
! Thread-safe event routing via module-level queues and critical section.
! =============================================================================

  INCLUDE('CWSYNCHM.INC'),ONCE
  INCLUDE('KanbanWrapper.inc'),ONCE

! ---------------------------------------------------------------------------
! Module-level event queues
! ---------------------------------------------------------------------------
KanbanEventQ        QUEUE,PRE(KanbanEventQ)
OleControl            SIGNED
EventName             CSTRING(100)
Parm1                 STRING(1000)
Parm2                 STRING(1000)
Parm3                 STRING(1000)
                    END

KanbanPostEventQ    QUEUE,PRE(KanbanPostEventQ)
OleControl            SIGNED
PostEvent             LONG
                    END

KanbanCS            &ICriticalSection

                    MAP
                      INCLUDE('OCX.CLW')
KanbanEventFunc       PROCEDURE(*SHORT, SIGNED, LONG), LONG
                    END



! ---------------------------------------------------------------------------
! Init / Kill
! ---------------------------------------------------------------------------
KanbanWrapperClass.Init   PROCEDURE(LONG pCtrl)
  CODE
  SELF.Ctrl = pCtrl
  IF SELF.StatusQueue &= NULL
    SELF.StatusQueue &= NEW KanbanStatusQueueType
  END

KanbanWrapperClass.Kill   PROCEDURE
i                           LONG
  CODE
  IF SELF.Ctrl
    OcxUnRegisterEventProc(SELF.Ctrl)
  END
  IF ~(KanbanCS &= NULL)
    KanbanCS.Wait()
    LOOP i = RECORDS(KanbanPostEventQ) TO 1 BY -1
      GET(KanbanPostEventQ, i)
      IF KanbanPostEventQ.OleControl = SELF.Ctrl
        DELETE(KanbanPostEventQ)
        BREAK
      END
    END
    LOOP i = RECORDS(KanbanEventQ) TO 1 BY -1
      GET(KanbanEventQ, i)
      IF KanbanEventQ.OleControl = SELF.Ctrl
        DELETE(KanbanEventQ)
      END
    END
    KanbanCS.Release()
  END
  IF ~(SELF.StatusQueue &= NULL)
    FREE(SELF.StatusQueue)
    DISPOSE(SELF.StatusQueue)
  END
  SELF.Ctrl = 0

! ---------------------------------------------------------------------------
! Event routing
! ---------------------------------------------------------------------------
KanbanWrapperClass.RegisterEvents   PROCEDURE(SIGNED pOleControl, LONG pPostEvent)
  CODE
  IF KanbanCS &= NULL
    KanbanCS &= NewCriticalSection()
  END
  KanbanCS.Wait()
  KanbanPostEventQ.OleControl = pOleControl
  KanbanPostEventQ.PostEvent  = pPostEvent
  ADD(KanbanPostEventQ)
  KanbanCS.Release()
  OcxRegisterEventProc(pOleControl, KanbanEventFunc)

KanbanWrapperClass.GetEvent         PROCEDURE()
i                                     LONG
  CODE
  IF KanbanCS &= NULL; RETURN 0. 
  KanbanCS.Wait()
  LOOP i = 1 TO RECORDS(KanbanEventQ)
    GET(KanbanEventQ, i)
    IF KanbanEventQ.OleControl = SELF.Ctrl
      SELF.EventName = KanbanEventQ.EventName
      SELF.Parm1     = KanbanEventQ.Parm1
      SELF.Parm2     = KanbanEventQ.Parm2
      SELF.Parm3     = KanbanEventQ.Parm3
      DELETE(KanbanEventQ)
      KanbanCS.Release()
      RETURN 1
    END
  END
  KanbanCS.Release()
  RETURN 0

KanbanWrapperClass.Count            PROCEDURE()
i                                     LONG
cnt                                   LONG
  CODE
  IF KanbanCS &= NULL; RETURN 0.
  KanbanCS.Wait()
  LOOP i = 1 TO RECORDS(KanbanEventQ)
    GET(KanbanEventQ, i)
    IF KanbanEventQ.OleControl = SELF.Ctrl
      cnt += 1
    END
  END
  KanbanCS.Release()
  RETURN cnt

KanbanWrapperClass.ClearEvents      PROCEDURE
i                                     LONG
  CODE
  IF KanbanCS &= NULL; RETURN. 
  KanbanCS.Wait()
  LOOP i = RECORDS(KanbanEventQ) TO 1 BY -1
    GET(KanbanEventQ, i)
    IF KanbanEventQ.OleControl = SELF.Ctrl
      DELETE(KanbanEventQ)
    END
  END
  KanbanCS.Release()

! ---------------------------------------------------------------------------
! Column methods
! ---------------------------------------------------------------------------
KanbanWrapperClass.AddColumn        PROCEDURE(STRING pColumnId, STRING pTitle, LONG pColor=0)
  CODE
  SELF.Ctrl{'AddColumn(' & SELF.Q_(pColumnId) & ',' & SELF.Q_(pTitle) & ')'}
  IF pColor <> 0
    SELF.SetColumnHeaderColor(pColumnId, pColor)
  END

KanbanWrapperClass.RemoveColumn     PROCEDURE(STRING pColumnId)
  CODE
  SELF.Ctrl{'RemoveColumn(' & SELF.Q_(pColumnId) & ')'}

KanbanWrapperClass.ClearColumns     PROCEDURE
  CODE
  SELF.Ctrl{'ClearColumns()'}

KanbanWrapperClass.SetColumnHeaderColor     PROCEDURE(STRING pColumnId, LONG pColor)
  CODE
  SELF.Ctrl{'SetColumnHeaderColor(' & SELF.Q_(pColumnId) & ',' & pColor & ')'}

KanbanWrapperClass.SetColumnHeaderTextColor PROCEDURE(STRING pColumnId, LONG pColor)
  CODE
  SELF.Ctrl{'SetColumnHeaderTextColor(' & SELF.Q_(pColumnId) & ',' & pColor & ')'}

KanbanWrapperClass.SetAllColumnTextColors   PROCEDURE(LONG pColor)
  CODE
  SELF.Ctrl{'SetAllColumnHeaderTextColor(' & pColor & ')'}

KanbanWrapperClass.SetColumnBodyColor       PROCEDURE(STRING pColumnId, LONG pColor)
  CODE
  SELF.Ctrl{'SetColumnBodyColor(' & SELF.Q_(pColumnId) & ',' & pColor & ')'}

! ---------------------------------------------------------------------------
! Card methods
! ---------------------------------------------------------------------------
KanbanWrapperClass.AddCard          PROCEDURE(STRING pCardId, STRING pColumnId, STRING pTitle, STRING pBody)
  CODE
  SELF.Ctrl{'AddCard(' & SELF.Q_(pCardId) & ',' & SELF.Q_(pColumnId) & ',' & SELF.Q_(pTitle) & ',' & SELF.Q_(pBody) & ')'}

KanbanWrapperClass.AddCard          PROCEDURE(KanbanCardMeta pMeta)
  CODE
  SELF.AddCard(pMeta.CardId, pMeta.ColumnId, pMeta.Title, pMeta.Body)
  IF CLIP(pMeta.Tag) <> ''
    SELF.SetCardTag(pMeta.CardId, pMeta.Tag, pMeta.TagColor)
  END
  IF CLIP(pMeta.Assignee) <> ''
    SELF.SetCardAssignee(pMeta.CardId, pMeta.Assignee)
  END
  IF CLIP(pMeta.DueDate) <> ''
    SELF.SetCardDueDate(pMeta.CardId, pMeta.DueDate)
  END
  IF pMeta.Progress >= 0
    SELF.SetCardProgress(pMeta.CardId, pMeta.Progress)
  END
  IF pMeta.Overdue = 1
    SELF.SetCardOverdue(pMeta.CardId, 1)
  END
  IF CLIP(pMeta.StatusOption) <> ''
    SELF.SetCardStatus(pMeta.CardId, pMeta.StatusOption)
  END

KanbanWrapperClass.RemoveCard       PROCEDURE(STRING pCardId)
  CODE
  SELF.Ctrl{'RemoveCard(' & SELF.Q_(pCardId) & ')'}

KanbanWrapperClass.ClearColumnCards PROCEDURE(STRING pColumnId)
  CODE
  SELF.Ctrl{'ClearColumnCards(' & SELF.Q_(pColumnId) & ')'}

KanbanWrapperClass.GetCardColumn    PROCEDURE(STRING pCardId)
ReturnVal                             STRING(250)
  CODE
  ReturnVal = SELF.Ctrl{'GetCardColumn(' & SELF.Q_(pCardId) & ')'}
  RETURN CLIP(ReturnVal)

KanbanWrapperClass.SetCardBackgroundColor   PROCEDURE(STRING pCardId, LONG pColor)
  CODE
  SELF.Ctrl{'SetCardBackgroundColor(' & SELF.Q_(pCardId) & ',' & pColor & ')'}

KanbanWrapperClass.SetCardTextColor         PROCEDURE(STRING pCardId, LONG pColor)
  CODE
  SELF.Ctrl{'SetCardTextColor(' & SELF.Q_(pCardId) & ',' & pColor & ')'}

KanbanWrapperClass.SetCardBorderColor       PROCEDURE(STRING pCardId, LONG pColor)
  CODE
  SELF.Ctrl{'SetCardBorderColor(' & SELF.Q_(pCardId) & ',' & pColor & ')'}

KanbanWrapperClass.SetCardTitle             PROCEDURE(STRING pCardId, STRING pTitle)
  CODE
  SELF.Ctrl{'SetCardTitle(' & SELF.Q_(pCardId) & ',' & SELF.Q_(pTitle) & ')'}

KanbanWrapperClass.SetCardBody              PROCEDURE(STRING pCardId, STRING pBody)
  CODE
  SELF.Ctrl{'SetCardBody(' & SELF.Q_(pCardId) & ',' & SELF.Q_(pBody) & ')'}

KanbanWrapperClass.SetCardTag               PROCEDURE(STRING pCardId, STRING pLabel, LONG pColor)
  CODE
  SELF.Ctrl{'SetCardTag(' & SELF.Q_(pCardId) & ',' & SELF.Q_(pLabel) & ',' & pColor & ')'}

KanbanWrapperClass.SetCardAssignee          PROCEDURE(STRING pCardId, STRING pAssignee)
  CODE
  SELF.Ctrl{'SetCardAssignee(' & SELF.Q_(pCardId) & ',' & SELF.Q_(pAssignee) & ')'}

KanbanWrapperClass.SetCardDueDate           PROCEDURE(STRING pCardId, STRING pDueDate)
  CODE
  SELF.Ctrl{'SetCardDueDate(' & SELF.Q_(pCardId) & ',' & SELF.Q_(pDueDate) & ')'}

KanbanWrapperClass.SetCardProgress          PROCEDURE(STRING pCardId, LONG pProgress)
  CODE
  SELF.Ctrl{'SetCardProgress(' & SELF.Q_(pCardId) & ',' & pProgress & ')'}

KanbanWrapperClass.SetCardOverdue           PROCEDURE(STRING pCardId, LONG pOverdue)
  CODE
  SELF.Ctrl{'SetCardOverdue(' & SELF.Q_(pCardId) & ',' & pOverdue & ')'}

KanbanWrapperClass.SetCardStatusBar         PROCEDURE(STRING pCardId, STRING pLabel, LONG pColor)
  CODE
  SELF.Ctrl{'SetCardStatusBar(' & SELF.Q_(pCardId) & ',' & SELF.Q_(pLabel) & ',' & pColor & ')'}

KanbanWrapperClass.MoveCardToTop            PROCEDURE(STRING pCardId)
  CODE
  SELF.Ctrl{'MoveCardToTop(' & SELF.Q_(pCardId) & ')'}

KanbanWrapperClass.MoveCard                 PROCEDURE(STRING pCardId, STRING pColumnId)
  CODE
  SELF.Ctrl{'MoveCard(' & SELF.Q_(pCardId) & ',' & SELF.Q_(pColumnId) & ')'}

KanbanWrapperClass.SetColumnWipLimit        PROCEDURE(STRING pColumnId, LONG pMaxCards)
  CODE
  SELF.Ctrl{'SetColumnWipLimit(' & SELF.Q_(pColumnId) & ',' & pMaxCards & ')'}

KanbanWrapperClass.GetColumnCardCount       PROCEDURE(STRING pColumnId)
ReturnVal                                     LONG
  CODE
  ReturnVal = SELF.Ctrl{'GetColumnCardCount(' & SELF.Q_(pColumnId) & ')'}
  RETURN ReturnVal

KanbanWrapperClass.SetCardVisible           PROCEDURE(STRING pCardId, LONG pVisible)
  CODE
  SELF.Ctrl{'SetCardVisible(' & SELF.Q_(pCardId) & ',' & pVisible & ')'}

! ---------------------------------------------------------------------------
! Board appearance
! ---------------------------------------------------------------------------
KanbanWrapperClass.SetBoardBackgroundColor  PROCEDURE(LONG pColor)
  CODE
  SELF.Ctrl{'SetBoardBackgroundColor(' & pColor & ')'}

KanbanWrapperClass.SetColumnWidth           PROCEDURE(LONG pWidth)
  CODE
  SELF.Ctrl{'SetColumnWidth(' & pWidth & ')'}

KanbanWrapperClass.SetBoardTitle            PROCEDURE(STRING pTitle, LONG pColorBg, LONG pColorText)
  CODE
  SELF.Ctrl{'SetBoardTitle(' & SELF.Q_(pTitle) & ',' & pColorBg & ',' & pColorText & ')'}

KanbanWrapperClass.SetDarkMode              PROCEDURE(LONG pEnabled)
  CODE
  SELF.Ctrl{'SetDarkMode(' & pEnabled & ')'}

KanbanWrapperClass.SetReadOnly              PROCEDURE(LONG pReadOnly)
  CODE
  SELF.Ctrl{'SetReadOnly(' & pReadOnly & ')'}

! ---------------------------------------------------------------------------
! Context menu
! ---------------------------------------------------------------------------
KanbanWrapperClass.ClearContextMenu         PROCEDURE
  CODE
  SELF.Ctrl{'ClearContextMenu()'}

KanbanWrapperClass.AddContextMenuItem       PROCEDURE(STRING pParentId, STRING pItemId, STRING pLabel)
  CODE
  SELF.Ctrl{'AddContextMenuItem(' & SELF.Q_(pParentId) & ',' & SELF.Q_(pItemId) & ',' & SELF.Q_(pLabel) & ')'}

KanbanWrapperClass.AddContextMenuSub        PROCEDURE(STRING pParentId, STRING pSubId, STRING pLabel)
  CODE
  SELF.Ctrl{'AddContextMenuSub(' & SELF.Q_(pParentId) & ',' & SELF.Q_(pSubId) & ',' & SELF.Q_(pLabel) & ')'}

KanbanWrapperClass.AddContextMenuSep        PROCEDURE(STRING pParentId)
  CODE
  SELF.Ctrl{'AddContextMenuSep(' & SELF.Q_(pParentId) & ')'}

KanbanWrapperClass.AddContextMenuRadioGroup PROCEDURE(STRING pParentId, STRING pGroupId, STRING pLabel)
  CODE
  SELF.Ctrl{'AddContextMenuRadioGroup(' & SELF.Q_(pParentId) & ',' & SELF.Q_(pGroupId) & ',' & SELF.Q_(pLabel) & ')'}

KanbanWrapperClass.AddContextMenuRadioItem  PROCEDURE(STRING pGroupId, STRING pItemId, STRING pLabel)
  CODE
  SELF.Ctrl{'AddContextMenuRadioItem(' & SELF.Q_(pGroupId) & ',' & SELF.Q_(pItemId) & ',' & SELF.Q_(pLabel) & ')'}

KanbanWrapperClass.SetCardRadioValue        PROCEDURE(STRING pCardId, STRING pGroupId, STRING pItemId)
  CODE
  SELF.Ctrl{'SetCardRadioValue(' & SELF.Q_(pCardId) & ',' & SELF.Q_(pGroupId) & ',' & SELF.Q_(pItemId) & ')'}

KanbanWrapperClass.GetCardRadioValue        PROCEDURE(STRING pCardId, STRING pGroupId)
ReturnVal                                     STRING(250)
  CODE
  ReturnVal = SELF.Ctrl{'GetCardRadioValue(' & SELF.Q_(pCardId) & ',' & SELF.Q_(pGroupId) & ')'}
  RETURN CLIP(ReturnVal)

! ---------------------------------------------------------------------------
! Filters
! ---------------------------------------------------------------------------
KanbanWrapperClass.ClearFilters             PROCEDURE
  CODE
  SELF.Ctrl{'ClearFilters()'}

KanbanWrapperClass.AddFilterGroup           PROCEDURE(STRING pGroupId, STRING pTitle)
  CODE
  SELF.Ctrl{'AddFilterGroup(' & SELF.Q_(pGroupId) & ',' & SELF.Q_(pTitle) & ')'}

KanbanWrapperClass.AddFilterItem            PROCEDURE(STRING pGroupId, STRING pItemId, STRING pLabel, LONG pColor)
  CODE
  SELF.Ctrl{'AddFilterItem(' & SELF.Q_(pGroupId) & ',' & SELF.Q_(pItemId) & ',' & SELF.Q_(pLabel) & ',' & pColor & ')'}

KanbanWrapperClass.SetCardFilterValue       PROCEDURE(STRING pCardId, STRING pGroupId, STRING pItemId)
  CODE
  SELF.Ctrl{'SetCardFilterValue(' & SELF.Q_(pCardId) & ',' & SELF.Q_(pGroupId) & ',' & SELF.Q_(pItemId) & ')'}

KanbanWrapperClass.SetTextSearchEnabled     PROCEDURE(LONG pEnabled)
  CODE
  SELF.Ctrl{'SetTextSearchEnabled(' & pEnabled & ')'}

! ---------------------------------------------------------------------------
! Status system
! ---------------------------------------------------------------------------
KanbanWrapperClass.SetStatusTitle           PROCEDURE(STRING pTitle)
  CODE
  SELF.StatusTitle = pTitle

KanbanWrapperClass.AddStatusOption          PROCEDURE(STRING pOptionId, STRING pLabel, LONG pColor)
  CODE
  SELF.StatusQueue.OptionId = pOptionId
  SELF.StatusQueue.Label    = pLabel
  SELF.StatusQueue.Color    = pColor
  ADD(SELF.StatusQueue)

KanbanWrapperClass.BuildFilterFromStatus    PROCEDURE
i                                             LONG
  CODE
  SELF.AddFilterGroup('status', SELF.StatusTitle)
  LOOP i = 1 TO RECORDS(SELF.StatusQueue)
    GET(SELF.StatusQueue, i)
    SELF.AddFilterItem('status', CLIP(SELF.StatusQueue.OptionId), CLIP(SELF.StatusQueue.Label), SELF.StatusQueue.Color)
  END

KanbanWrapperClass.BuildMenuFromStatus      PROCEDURE(STRING pParentId)
i                                             LONG
  CODE
  SELF.AddContextMenuRadioGroup(pParentId, 'status', SELF.StatusTitle)
  LOOP i = 1 TO RECORDS(SELF.StatusQueue)
    GET(SELF.StatusQueue, i)
    SELF.AddContextMenuRadioItem('status', CLIP(SELF.StatusQueue.OptionId), CLIP(SELF.StatusQueue.Label))
  END

KanbanWrapperClass.SetCardStatus            PROCEDURE(STRING pCardId, STRING pOptionId)
i                                             LONG
foundColor                                    LONG
  CODE
  LOOP i = 1 TO RECORDS(SELF.StatusQueue)
    GET(SELF.StatusQueue, i)
    IF CLIP(SELF.StatusQueue.OptionId) = CLIP(pOptionId)
      foundColor = SELF.StatusQueue.Color
      BREAK
    END
  END
  SELF.SetCardRadioValue(pCardId, 'status', pOptionId)
  SELF.SetCardStatusBar(pCardId, '', foundColor)
  SELF.SetCardFilterValue(pCardId, 'status', pOptionId)

! ---------------------------------------------------------------------------
! Event handlers
! ---------------------------------------------------------------------------
KanbanWrapperClass.OnPageReady              PROCEDURE()
  CODE

KanbanWrapperClass.OnCardMoved              PROCEDURE(STRING pCardId, STRING pFromColumn, STRING pToColumn)
  CODE

KanbanWrapperClass.OnContextMenuSelected    PROCEDURE(STRING pCardId, STRING pActionId)
  CODE

KanbanWrapperClass.OnSingleClick            PROCEDURE(STRING pCardId)
  CODE

KanbanWrapperClass.OnDoubleClick            PROCEDURE(STRING pCardId)
  CODE

KanbanWrapperClass.OnOtherEvent             PROCEDURE(STRING pEventName)
  CODE

! ---------------------------------------------------------------------------
! Private helpers
! ---------------------------------------------------------------------------
KanbanWrapperClass.Q_               PROCEDURE(STRING pValue)
Cleaned                               CSTRING(4002)
i                                     LONG, AUTO
ch                                    STRING(1)
  CODE
  LOOP i = 1 TO LEN(CLIP(pValue))
    ch = SUB(pValue, i, 1)
    IF ch = '"'
      Cleaned = Cleaned & '\"'
    ELSE
      Cleaned = Cleaned & ch
    END
  END
  RETURN '"' & Cleaned & '"'

! ---------------------------------------------------------------------------
! Module-level callback - registered via OcxRegisterEventProc
! Fires on the thread that owns the OLE control.
! ---------------------------------------------------------------------------
KanbanEventFunc     PROCEDURE(*SHORT Reference, SIGNED OleControl, LONG CurEvent)
i                     LONG
PostEv                LONG
  CODE
  IF KanbanCS &= NULL; RETURN 0. 
  KanbanCS.Wait()
  KanbanEventQ.OleControl = OleControl
  KanbanEventQ.EventName  = OleControl{PROP:LastEventName}
  KanbanEventQ.Parm1      = OcxGetParam(Reference, 1)
  KanbanEventQ.Parm2      = OcxGetParam(Reference, 2)
  KanbanEventQ.Parm3      = OcxGetParam(Reference, 3)
  ADD(KanbanEventQ)
  LOOP i = 1 TO RECORDS(KanbanPostEventQ)
    GET(KanbanPostEventQ, i)
    IF KanbanPostEventQ.OleControl = OleControl
      PostEv = KanbanPostEventQ.PostEvent
      BREAK
    END
  END
  KanbanCS.Release()
  IF PostEv
    POST(PostEv)
  END
  RETURN 1  