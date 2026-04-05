#TEMPLATE(GenericKanban,'Generic Kanban Board'),FAMILY('ABC')
#Include('cape01.tpw')
#Include('cape02.tpw')
#GROUP(%ReadGlobal,%pa,%force)
  #INSERT(%SetFamily)
  #insert(%ReadClassesPR,'KanbanWrapper.inc',%pa,%force)
#Extension(GenericKanbanGlobal,'GenericKanban (Global)'),APPLICATION
#SHEET
  #TAB('General')
    #BOXED('Multi-DLL')
      #PROMPT('Part of a Multi-DLL program',CHECK),%MultiDLL,DEFAULT(%ProgramExtension='DLL'),AT(10)
      #ENABLE(%MultiDLL=1)
        #ENABLE(%ProgramExtension='DLL')
          #PROMPT('Export KanbanWrapper Class from this DLL',CHECK),%RootDLL,AT(10)
        #ENDENABLE
      #ENDENABLE
    #ENDBOXED
  #ENDTAB
  #TAB('Classes')
    #INSERT(%GlobalDeclareClassesPR)
  #ENDTAB
#ENDSHEET
#ATSTART
  #IF(VAREXISTS(%UseDefaultXPManifest))
    #SET(%UseDefaultXPManifest,0)
  #ENDIF
  #IF(VAREXISTS(%GenerateXPManifest))
    #SET(%GenerateXPManifest,1)
  #ENDIF
  #IF(VAREXISTS(%LinkGenerateXPManifest))
    #SET(%LinkGenerateXPManifest,0)
  #ENDIF
  #INSERT(%ReadGlobal,2,0)
#ENDAT
#ATEND
  #INSERT(%EndGlobal)
#ENDAT
#AT(%AfterGeneratedApplication),WHERE(%ProgramExtension='EXE')
#DECLARE(%gkManifestFile)
#SET(%gkManifestFile,%ProjectTarget & '.manifest')
#IF(FILEEXISTS(%gkManifestFile))
#OPEN(%gkManifestFile),READ
#DECLARE(%gkCount)
#DECLARE(%gkLine)
#DECLARE(%gkLines),MULTI
#LOOP
  #SET(%gkCount,%gkCount+1)
  #READ(%gkLine)
  #IF(%gkLine = %EOF)
    #BREAK
  #ENDIF
  #ADD(%gkLines,%gkLine,%gkCount)
#ENDLOOP
#CLOSE(%gkManifestFile),READ
#REMOVE(%gkManifestFile)
#OPEN(%gkManifestFile)
#FOR(%gkLines)
%gkLines
  #IF(INSTRING('</dependency>',%gkLines,1,1)>0)
<dependency>
  <dependentAssembly>
    <assemblyIdentity
      type="win32"
      name="GenericKanban"
      version="1.0.0.0"
      processorArchitecture="x86"
      language="*"
    />
  </dependentAssembly>
</dependency>
  #ENDIF
#ENDFOR
#CLOSE(%gkManifestFile)
#ENDIF
#ENDAT
#AT(%BeforeGlobalIncludes)
INCLUDE('KanbanWrapper.inc'),ONCE
#ENDAT
#AT(%AfterGlobalIncludes)
INCLUDE('KanbanWrapper.inc'),ONCE
#ENDAT
#AT(%BeforeGlobalData)
INCLUDE('KanbanWrapper.inc'),ONCE
#ENDAT
#AT(%BeforeGlobalDataInMember)
INCLUDE('KanbanWrapper.inc'),ONCE
#ENDAT
#AT(%BeforeFileDeclarationInMember)
INCLUDE('KanbanWrapper.inc'),ONCE
#ENDAT
#AT(%CustomGlobalDeclarations)
  #INSERT(%Defines,1,'KanBanWrapperLinkMode','KanBanWrapperDLLMode',%MultiDLL,%RootDLL)
#ENDAT
#AT(%mpDefineAll)
#INSERT(%Defines,2,'KanBanWrapperLinkMode','KanBanWrapperDLLMode',%MultiDLL,%RootDLL)
#ENDAT
#AT(%mpDefineAll7)
#INSERT(%Defines,3,'KanBanWrapperLinkMode','KanBanWrapperDLLMode',%MultiDLL,%RootDLL)
#ENDAT
#CONTROL(GenericKanbanControl,'GenericKanban Control'),WINDOW,MULTI,REQ(GenericKanbanGlobal)
  CONTROLS
    OLE,AT(,,450,250),USE(?KanbanOLE)
    END
  END
#PROMPT('Object Name:',@S50),%KanbanObjName,DEFAULT('Kanban' & %ActiveTemplateInstance)
#PREPARE
  #INSERT(%ReadGlobal,3,0)
#ENDPREPARE
#ATSTART
  #IF(VarExists(%KanbanFEQ) = 0)
    #DECLARE(%KanbanFEQ)
    #SET(%KanbanFEQ,0)
  #EndIf
  #FOR(%Control),WHERE(%ControlInstance = %ActiveTemplateInstance)
    #SET(%KanbanFEQ,%Control)
  #ENDFOR
  #INSERT(%AtStartInitialisation)
  #INSERT(%ReadGlobal,3,0)
  #INSERT(%AddObjectPR,'KanbanWrapperClass',%KanbanObjName,'Local Objects')
#ENDAT
#AT(%DataSection)
               MAP
KanbanProcess_%KanbanObjName   PROCEDURE
               END
%KanbanObjName_Event          EQUATE(Event:User+2000+%KanbanFEQ)
#ENDAT
#AT(%LocalDataClasses)
#INSERT(%GenerateClassDeclaration,'KanbanWrapperClass',%KanbanObjName,'Local Objects','Kanban Objects')
#ENDAT
#AT(%DataSection),WHERE(%ProcedureTemplate='Source' AND %Family='CW20')
#INSERT(%GenerateClassDeclaration,'KanbanWrapperClass',%KanbanObjName,'Local Objects','Kanban Objects')
#ENDAT
#AT(%WindowEventHandling,'OpenWindow'),PRIORITY(8005)
%KanbanFEQ{PROP:Create} = 'GenericKanban.GenericKanbanControl'
%KanbanObjName.Init(%KanbanFEQ)
%KanbanObjName.RegisterEvents(%KanbanFEQ,%KanbanObjName_Event)
#Embed(%KanbanAfterInit,'After Kanban Init'),TREE('Local Objects','Kanban Objects','%KanbanObjName (KanbanWrapperClass)','After Init')
#ENDAT
#AT(%WindowEventHandling,'CloseWindow')
%KanbanObjName.Kill()
#ENDAT
#AT(%WindowManagerMethodCodeSection,'TakeEvent','(),BYTE'),PRIORITY(6300)
IF Event()=%KanbanObjName_Event
  KanbanProcess_%KanbanObjName()
END
#ENDAT
#AT(%LocalProcedures)
KanbanProcess_%KanbanObjName  PROCEDURE
  CODE
  LOOP WHILE %KanbanObjName.GetEvent()
    CASE %KanbanObjName.EventName
    OF 'PageReady'
      %KanbanObjName.OnPageReady()
    OF 'CardMoved'
      %KanbanObjName.OnCardMoved(%KanbanObjName.Parm1,%KanbanObjName.Parm2,%KanbanObjName.Parm3)
    OF 'ContextMenuSelected'
      %KanbanObjName.OnContextMenuSelected(%KanbanObjName.Parm1,%KanbanObjName.Parm2)
    ELSE
      %KanbanObjName.OnOtherEvent(%KanbanObjName.EventName)
    END
  END
#ENDAT
#AT(%LocalProcedures)
#INSERT(%GenerateMethods,'KanbanWrapperClass',%KanbanObjName,'Local Objects','Kanban Objects')
#ENDAT
#AT(%dMethodCodeSection,%ActiveTemplate & %ActiveTemplateInstance,%eMethodID),PRIORITY(5000),DESCRIPTION('Parent Call')
#INSERT(%ParentCall)
#ENDAT
