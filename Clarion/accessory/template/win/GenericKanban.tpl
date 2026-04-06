#TEMPLATE(GenericKanban,'Generic Kanban Board'),FAMILY('ABC')
#Include('cape01.tpw')
#Include('cape02.tpw')
#GROUP(%ReadGlobal,%pa,%force)
  #INSERT(%SetFamily)
  #insert(%ReadClassesPR,'KanbanWrapper.inc',%pa,%force)

#! ---------------------------------------------------------------------------
#! %CopyFile - Copy a single file from Accessory\BIN to the output folder.
#!   %pFilename  : filename (e.g. 'GenericKanban.dll')
#!   %pSubFolder : destination subfolder within output dir, or '' for root
#! ---------------------------------------------------------------------------
#GROUP(%gkCopyFile,%pFilename,%pSubFolder),AUTO
#DECLARE(%gkSrcPath)
#DECLARE(%gkDestPath)
#DECLARE(%gkDestRoot)
#! Resolve output root: app folder optionally + output subdir
#IF(%gkOutputDir='')
  #SET(%gkDestRoot,FULLNAME('.\'))
#ELSE
  #SET(%gkDestRoot,FULLNAME('.\')&%gkOutputDir&'\')
  #RUN('cmd.exe /c if not exist "'&%gkDestRoot&'" mkdir "'&%gkDestRoot&'"'),WAIT
#ENDIF
#! Remove stale copy from old location
#REMOVE(FULLNAME('.\')&%pFilename)
#! Locate source in Accessory\BIN
#SET(%gkSrcPath,%CWRoot&'Accessory\BIN\'&%pFilename)
#IF(NOT FILEEXISTS(%gkSrcPath))
  #ERROR('GenericKanban: File "'& %gkSrcPath &'" not found. Ensure GenericKanban is installed.')
  #RETURN
#ENDIF
#! Build destination path
#IF(%pSubFolder='')
  #SET(%gkDestPath,%gkDestRoot&%pFilename)
#ELSE
  #SET(%gkDestPath,%gkDestRoot&%pSubFolder&'\'&%pFilename)
  #RUN('cmd.exe /c if not exist "'&%gkDestRoot&%pSubFolder&'" mkdir "'&%gkDestRoot&%pSubFolder&'"'),WAIT
#ENDIF
#RUN('cmd.exe /c echo f | xcopy "'& %gkSrcPath &'" "'& %gkDestPath &'" /D /Y'),WAIT

#! ---------------------------------------------------------------------------
#! %CopyFolder - Copy an entire folder tree from Accessory\<pSrcRel> to the
#!              output folder at <pDestRel>.
#!   %pSrcRel  : path relative to %CWRoot&'Accessory\' (e.g. 'resources\wwwroot')
#!   %pDestRel : destination path within output dir (e.g. 'wwwroot')
#! ---------------------------------------------------------------------------
#GROUP(%gkCopyFolder,%pSrcRel,%pDestRel),AUTO
#DECLARE(%gkFolderSrc)
#DECLARE(%gkFolderDest)
#DECLARE(%gkFolderRoot)
#IF(%gkOutputDir='')
  #SET(%gkFolderRoot,FULLNAME('.\'))
#ELSE
  #SET(%gkFolderRoot,FULLNAME('.\')&%gkOutputDir&'\')
#ENDIF
#SET(%gkFolderSrc,%CWRoot&'Accessory\'&%pSrcRel)
#SET(%gkFolderDest,%gkFolderRoot&%pDestRel)
#IF(NOT FILEEXISTS(%gkFolderSrc))
  #ERROR('GenericKanban: Folder "'& %gkFolderSrc &'" not found. Ensure GenericKanban is installed.')
  #RETURN
#ENDIF
#RUN('cmd.exe /c xcopy "'& %gkFolderSrc &'" "'& %gkFolderDest &'" /D /E /I /Y /Q'),WAIT

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
    #BOXED('Deployment')
      #PROMPT('Do not copy DLLs and resources to project folder',CHECK),%gkDoNotCopy,DEFAULT(0),AT(10)
      #ENABLE(%gkDoNotCopy=0)
        #DISPLAY('Output subdirectory (blank = EXE/DLL in app folder):'),AT(10,,250)
        #PROMPT('',@S100),%gkOutputDir,DEFAULT(''),AT(10)
        #DISPLAY('e.g. enter  build  if your EXE/DLL goes to a ''build'' subfolder'),AT(10,,250)
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
  #!  #IF(VAREXISTS(%LinkGenerateXPManifest))
  #!    #SET(%LinkGenerateXPManifest,0)
  #!  #ENDIF
  #INSERT(%ReadGlobal,2,0)
#ENDAT
#ATEND
  #INSERT(%EndGlobal)
#ENDAT
#AT(%AfterGenerateXPManifest),WHERE(%ProgramExtension='EXE')
#DECLARE(%gkManifestBuffer)
#DECLARE(%gkManifestDependencyLineNo)
#DECLARE(%gkManifestLines),MULTI
#DECLARE(%gkManifestLinesContent,%gkManifestLines)
#DECLARE(%gkManifestLineCount)
#FREE(%gkManifestLines)
#SET(%gkManifestLineCount,0)
#OPEN(%ExportFile),READ
#LOOP
  #READ(%gkManifestBuffer)
  #IF(%gkManifestBuffer=%EOF)
    #BREAK
  #ENDIF
  #ADD(%gkManifestLines,ITEMS(%gkManifestLines)+1)
  #SET(%gkManifestLinesContent,%gkManifestBuffer)
  #SET(%gkManifestLineCount,%gkManifestLineCount+1)
  #IF(INSTRING('</dependency>',%gkManifestBuffer,1,1)>0)
    #SET(%gkManifestDependencyLineNo,%gkManifestLineCount)
  #ENDIF
#ENDLOOP
#CLOSE(%ExportFile),READ
#SET(%gkManifestLineCount,0)
#CREATE(%BuildFile)
#FOR(%gkManifestLines)
%gkManifestLinesContent
  #SET(%gkManifestLineCount,%gkManifestLineCount+1)
  #IF(%gkManifestLineCount=%gkManifestDependencyLineNo)
<dependency>
  <dependentAssembly>
    <assemblyIdentity name="GenericKanban" version="1.0.0.0" processorArchitecture="x86" type="win32"/>
  </dependentAssembly>
</dependency>
  #ENDIF
#ENDFOR
#CLOSE(%BuildFile)
#REPLACE(%ExportFile,%BuildFile)
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
  #! Copy DLLs and resources to project folder (unless opted out)
  #IF(%gkDoNotCopy=0)
    #! COM entry point and native loader - go in app root
    #CALL(%gkCopyFile,'GenericKanban.dll','')
    #CALL(%gkCopyFile,'GenericKanban.manifest','')
    #CALL(%gkCopyFile,'WebView2Loader.dll','')
    #! Managed dependencies - private subfolder (BIN\GenericKanban\ -> app\GenericKanban\)
    #CALL(%gkCopyFolder,'BIN\GenericKanban','GenericKanban')
    #! wwwroot resources (app.js, index.html, styles.css, sortable.min.js)
    #CALL(%gkCopyFolder,'resources\wwwroot\controls\generickanban','wwwroot\controls\generickanban')
  #ENDIF
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
