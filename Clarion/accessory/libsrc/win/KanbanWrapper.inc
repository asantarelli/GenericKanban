! =============================================================================
! KanbanWrapper.inc
! Clarion wrapper for the GenericKanban WebView2 COM control.
! Requires: KanbanWrapper.clw (module implementation)
! =============================================================================

! =============================================================================
! KanbanStatusOption - one entry in the status queue (internal use)
! =============================================================================
KanbanStatusOption      GROUP, TYPE
OptionId                  STRING(50)
Label                     STRING(100)
Color                     LONG
                        END

! =============================================================================
! KanbanCardMeta - optional card metadata, pass to AddCard override
! Leave fields blank/0 to skip the corresponding method call.
! Progress: use -1 to hide the progress bar (0 is a valid value)
! StatusOption: id from AddStatusOption (blank = no status)
! =============================================================================
KanbanCardMeta          GROUP, TYPE
CardId                    STRING(50)
ColumnId                  STRING(50)
Title                     STRING(255)
Body                      STRING(255)
Tag                       STRING(50)
TagColor                  LONG
Assignee                  STRING(100)
DueDate                   STRING(20)
Progress                  LONG
Overdue                   LONG
StatusOption              STRING(50)
                        END

! =============================================================================
! KanbanStatusQueueType - queue of status options (declared outside class)
! =============================================================================
KanbanStatusQueueType   QUEUE, TYPE
OptionId                  STRING(50)
Label                     STRING(100)
Color                     LONG
                        END

KanbanWrapperClass      CLASS(),TYPE,MODULE('KanbanWrapper.clw'),LINK('KanbanWrapper.clw',KanBanWrapperLinkMode),DLL(KanBanWrapperDLLMode)

! -- Core --
Ctrl                      LONG

! -- Last event received (populated by GetEvent) --
EventName                 CSTRING(100)
Parm1                     STRING(1000)
Parm2                     STRING(1000)
Parm3                     STRING(1000)

! -- Internal status queue --
StatusQueue               &KanbanStatusQueueType, PRIVATE
StatusTitle               STRING(100), PRIVATE

! -- Lifecycle --
Init                      PROCEDURE(LONG pCtrl),VIRTUAL
Kill                      PROCEDURE,VIRTUAL

! -- Event routing --
RegisterEvents            PROCEDURE(SIGNED pOleControl, LONG pPostEvent),VIRTUAL
GetEvent                  PROCEDURE(), LONG,VIRTUAL
Count                     PROCEDURE(), LONG,VIRTUAL
ClearEvents               PROCEDURE,VIRTUAL

! -- Columns --
AddColumn                 PROCEDURE(STRING pColumnId, STRING pTitle, LONG pColor=0),VIRTUAL
RemoveColumn              PROCEDURE(STRING pColumnId),VIRTUAL
ClearColumns              PROCEDURE,VIRTUAL
SetColumnHeaderColor      PROCEDURE(STRING pColumnId, LONG pColor),VIRTUAL
SetColumnHeaderTextColor  PROCEDURE(STRING pColumnId, LONG pColor),VIRTUAL
SetAllColumnTextColors    PROCEDURE(LONG pColor),VIRTUAL
SetColumnBodyColor        PROCEDURE(STRING pColumnId, LONG pColor),VIRTUAL

! -- Cards --
AddCard                   PROCEDURE(STRING pCardId, STRING pColumnId, STRING pTitle, STRING pBody),VIRTUAL
AddCard                   PROCEDURE(KanbanCardMeta pMeta),VIRTUAL
RemoveCard                PROCEDURE(STRING pCardId),VIRTUAL
ClearColumnCards          PROCEDURE(STRING pColumnId),VIRTUAL
GetCardColumn             PROCEDURE(STRING pCardId), STRING,VIRTUAL
SetCardBackgroundColor    PROCEDURE(STRING pCardId, LONG pColor),VIRTUAL
SetCardTextColor          PROCEDURE(STRING pCardId, LONG pColor),VIRTUAL
SetCardBorderColor        PROCEDURE(STRING pCardId, LONG pColor),VIRTUAL
SetCardTitle              PROCEDURE(STRING pCardId, STRING pTitle),VIRTUAL
SetCardBody               PROCEDURE(STRING pCardId, STRING pBody),VIRTUAL
SetCardTag                PROCEDURE(STRING pCardId, STRING pLabel, LONG pColor),VIRTUAL
SetCardAssignee           PROCEDURE(STRING pCardId, STRING pAssignee),VIRTUAL
SetCardDueDate            PROCEDURE(STRING pCardId, STRING pDueDate),VIRTUAL
SetCardProgress           PROCEDURE(STRING pCardId, LONG pProgress),VIRTUAL
SetCardOverdue            PROCEDURE(STRING pCardId, LONG pOverdue),VIRTUAL
SetCardStatusBar          PROCEDURE(STRING pCardId, STRING pLabel, LONG pColor),VIRTUAL
MoveCardToTop             PROCEDURE(STRING pCardId),VIRTUAL
MoveCard                  PROCEDURE(STRING pCardId, STRING pColumnId),VIRTUAL
SetColumnWipLimit         PROCEDURE(STRING pColumnId, LONG pMaxCards),VIRTUAL
GetColumnCardCount        PROCEDURE(STRING pColumnId), LONG,VIRTUAL
SetCardVisible            PROCEDURE(STRING pCardId, LONG pVisible),VIRTUAL
ShowContextMenu           PROCEDURE(STRING pCardId),VIRTUAL

! -- Board appearance --
SetBoardBackgroundColor   PROCEDURE(LONG pColor),VIRTUAL
SetColumnWidth            PROCEDURE(LONG pWidth),VIRTUAL
SetBoardTitle             PROCEDURE(STRING pTitle, LONG pColorBg, LONG pColorText),VIRTUAL
SetDarkMode               PROCEDURE(LONG pEnabled),VIRTUAL
SetReadOnly               PROCEDURE(LONG pReadOnly),VIRTUAL

! -- Context menu --
ClearContextMenu          PROCEDURE,VIRTUAL
AddContextMenuItem        PROCEDURE(STRING pParentId, STRING pItemId, STRING pLabel),VIRTUAL
AddContextMenuSub         PROCEDURE(STRING pParentId, STRING pSubId, STRING pLabel),VIRTUAL
AddContextMenuSep         PROCEDURE(STRING pParentId),VIRTUAL
AddContextMenuRadioGroup  PROCEDURE(STRING pParentId, STRING pGroupId, STRING pLabel),VIRTUAL
AddContextMenuRadioItem   PROCEDURE(STRING pGroupId, STRING pItemId, STRING pLabel),VIRTUAL
SetCardRadioValue         PROCEDURE(STRING pCardId, STRING pGroupId, STRING pItemId),VIRTUAL
GetCardRadioValue         PROCEDURE(STRING pCardId, STRING pGroupId), STRING,VIRTUAL

! -- Filters --
ClearFilters              PROCEDURE,VIRTUAL
AddFilterGroup            PROCEDURE(STRING pGroupId, STRING pTitle),VIRTUAL
AddFilterItem             PROCEDURE(STRING pGroupId, STRING pItemId, STRING pLabel, LONG pColor),VIRTUAL
SetCardFilterValue        PROCEDURE(STRING pCardId, STRING pGroupId, STRING pItemId),VIRTUAL
SetTextSearchEnabled      PROCEDURE(LONG pEnabled),VIRTUAL

! -- Status system --
SetStatusTitle            PROCEDURE(STRING pTitle),VIRTUAL
AddStatusOption           PROCEDURE(STRING pOptionId, STRING pLabel, LONG pColor),VIRTUAL
BuildFilterFromStatus     PROCEDURE,VIRTUAL
BuildMenuFromStatus       PROCEDURE(STRING pParentId),VIRTUAL
SetCardStatus             PROCEDURE(STRING pCardId, STRING pOptionId),VIRTUAL

! -- Event handlers (override in derived class) --
OnPageReady               PROCEDURE(),VIRTUAL
OnCardMoved               PROCEDURE(STRING pCardId, STRING pFromColumn, STRING pToColumn),VIRTUAL
OnContextMenuSelected     PROCEDURE(STRING pCardId, STRING pActionId),VIRTUAL
OnSingleClick             PROCEDURE(STRING pCardId),VIRTUAL
OnDoubleClick             PROCEDURE(STRING pCardId),VIRTUAL
OnCardRightClick          PROCEDURE(STRING pCardId),VIRTUAL
OnOtherEvent              PROCEDURE(STRING pEventName),VIRTUAL

! -- Private helpers --
Q_                        PROCEDURE(STRING pValue), STRING, PRIVATE

                        END
