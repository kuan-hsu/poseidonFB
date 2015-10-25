module layout;

import iup.iup;

import global, scintilla, project, dialogs.preferenceDlg;
import layouts.tabDocument, layouts.toolbar, layouts.tree, layouts.messagePanel, layouts.statusBar, layouts.outline, layouts.debugger, actionManager;
import dialogs.searchDlg, dialogs.findFilesDlg, dialogs.helpDlg, dialogs.argOptionDlg;

import tango.stdc.stringz;

void createExplorerWindow()
{
	Ihandle* toolBar = createToolBar();	
	//Ihandle* toolBar_VBox = IupVbox( toolBar, null );
	//IupSetAttributes( toolBar_VBox, "ALIGNMENT=ALEFT,RASTERSIZE=x10" );	
	
	// Explorer Window
	// To be continue...
	/+
	Ihandle* ml = IupMultiLine(null);
	IupSetAttribute(ml, "EXPAND", "YES");
	IupSetAttribute(ml, "VISIBLELINES", "5");
	IupSetAttribute(ml, "VISIBLECOLUMNS", "10");
	+/

	/+
	Ihandle* prjManager = createProjectManagerToolBar();
	Ihandle* prjOutline = createOutlineToolBar();
	+/
	createFileListTree();
	GLOBAL.projectTree = new CProjectTree; //createProjectManagerTree();
	GLOBAL.outlineTree = new COutline;

	IupSetAttribute( GLOBAL.projectTree.getTreeHandle, "TABTITLE", "Project" );
	IupSetAttribute( GLOBAL.fileListTree, "TABTITLE", "FileList" );
	IupSetAttribute( GLOBAL.outlineTree.getZBoxHandle, "TABTITLE", "Outline" );
	
	IupSetAttribute( GLOBAL.projectTree.getTreeHandle, "TABIMAGE", "icon_packageexplorer" );
	IupSetAttribute( GLOBAL.fileListTree, "TABIMAGE", "icon_filelist" );
	//IupSetAttribute( GLOBAL.fileListTree, "FONT", "Consolas, 10" );
	IupSetAttribute( GLOBAL.outlineTree.getZBoxHandle, "TABIMAGE", "icon_outline" );
	

	
	GLOBAL.projectViewTabs = IupTabs( GLOBAL.fileListTree, GLOBAL.projectTree.getTreeHandle, GLOBAL.outlineTree.getZBoxHandle, null );
	IupSetAttribute( GLOBAL.projectViewTabs, "TABTYPE", "BOTTOM" );
	//IupSetAttribute( GLOBAL.projectViewTabs, "FONT", "Consolas, 18" );

	createTabs();

	Ihandle* dndEmptylabel = IupLabel( null );
	IupSetAttribute( dndEmptylabel, "EXPAND", "YES" );
	IupSetCallback( dndEmptylabel, "DROPFILES_CB",cast(Icallback) &label_dropfiles_cb );
	GLOBAL.dndDocumentZBox = IupZbox( dndEmptylabel, GLOBAL.documentTabs, null  );


	GLOBAL.explorerSplit = IupSplit( GLOBAL.projectViewTabs, GLOBAL.dndDocumentZBox );
	IupSetAttributes(GLOBAL.explorerSplit, "ORIENTATION=VERTICAL,AUTOHIDE=YES,LAYOUTDRAG=NO,SHOWGRIP=LINES,VALUE=150");
	//IupSetAttribute(GLOBAL.explorerSplit, "COLOR", "127 127 255");

	
	createMessagePanel();

	GLOBAL.debugPanel = new CDebugger();

	GLOBAL.messageWindowTabs = IupTabs( GLOBAL.outputPanel, GLOBAL.searchOutputPanel, GLOBAL.debugPanel.getMainHandle, null );
	IupSetAttribute( GLOBAL.messageWindowTabs, "TABTYPE", "TOP" );
	IupSetAttributeId( GLOBAL.messageWindowTabs, "TABVISIBLE", 2, "NO" ); // Hide the Debug window

	Ihandle* messageScrollBox = IupScrollBox( GLOBAL.messageWindowTabs );
	 

	GLOBAL.messageSplit = IupSplit(GLOBAL.explorerSplit, messageScrollBox );
	IupSetAttributes(GLOBAL.messageSplit, "ORIENTATION=HORIZONTAL,AUTOHIDE=YES,LAYOUTDRAG=NO,SHOWGRIP=LINES,VALUE=750");
	//IupSetAttribute(GLOBAL.messageSplit, "COLOR", "127 127 255");

	Ihandle* StatusBar = createStatusBar();

	Ihandle* VBox = IupVbox( toolBar, GLOBAL.messageSplit, StatusBar, null );
	IupAppend( GLOBAL.mainDlg, VBox );
	//IupSetAttribute( GLOBAL.documentTabs, "VISIBLE", "NO" );
}

void createEditorSetting()
{
	CPreferenceDialog.load();
}

void createLayout()
{
	createExplorerWindow();
}

void createDialog()
{
	GLOBAL.searchDlg		= new CSearchDialog( 330, 400, "Search/Replace" );
	GLOBAL.serachInFilesDlg	= new CFindInFilesDialog( 400, 310, "Search/Replace In Files" );
	GLOBAL.compilerHelpDlg	= new CCompilerHelpDialog( 500, 400, "Compiler Options" );
	GLOBAL.argsDlg			= new CArgOptionDialog( 370, 146, "Compiler Options / EXE Arguments" );
}

extern(C) int label_dropfiles_cb( Ihandle *ih, char* filename, int num, int x, int y )
{
	actionManager.ScintillaAction.openFile( fromStringz( filename ).dup  );
	if( IupGetInt( GLOBAL.dndDocumentZBox, "VALUEPOS" ) == 0 ) IupSetInt( GLOBAL.dndDocumentZBox, "VALUEPOS", 1 );
	return IUP_DEFAULT;
}

extern(C) int mainDialog_CLOSE_cb(Ihandle *ih)
{
	int ret = ScintillaAction.closeAllDocument();
	if( ret == IUP_IGNORE ) return IUP_IGNORE;
	
	// Save All Project	
	foreach( PROJECT p; GLOBAL.projectManager )
	{
		p.saveFile();
	}

	CPreferenceDialog.save();

	/+
	// Save Preference
	auto doc = new Document!(char);
	
	// attach an xml header
	doc.header;

	auto prjNode = doc.tree.element( null, "config" );

	prjNode.element( null, "editor", name );


	
	prjNode.element( null, "Type", type );



	
	prjNode.element( null, "Dir", dir );
	prjNode.element( null, "MainFile", mainFile );
	prjNode.element( null, "TargetName", targetName );
	prjNode.element( null, "CompilerArgs", args );
	prjNode.element( null, "CompilerOption", compilerOption );
	prjNode.element( null, "Comment", comment );
	prjNode.element( null, "CompilerPath", compilerPath );

	auto prjIncludeNode = prjNode.element( null, "IncludeDirs" );
	foreach( char[] s; includeDirs ) 
		prjIncludeNode.element( null, "Name", s );

	auto prjLibNode = prjNode.element( null, "LibDirs" );
	foreach( char[] s; libDirs ) 
		prjLibNode.element( null, "Name", s );

	auto prjSourceNode = prjNode.element( null, "Sources" );
	foreach( char[] s; sources ) 
		prjSourceNode.element( null, "Name", s );

	auto prjIncludeFileNode = prjNode.element( null, "Includes" );
	foreach( char[] s; includes ) 
		prjIncludeFileNode.element( null, "Name", s );

	auto prjOthersNode = prjNode.element( null, "Others" );
	foreach( char[] s; others ) 
		prjOthersNode.element( null, "Name", s );


	// Save File
	scope print = new DocPrinter!(char);
	FileAction.saveFile( dir ~ "\\.poseidon", print.print( doc ) );
	+/

	return IUP_CLOSE;
}