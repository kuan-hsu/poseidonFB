module layout;

import iup.iup;

import global, scintilla, project, dialogs.preferenceDlg;
import layouts.tabDocument, layouts.toolbar, layouts.filelistPanel, layouts.projectPanel, layouts.messagePanel, layouts.statusBar, layouts.outlinePanel, layouts.debugger, actionManager, menu;
import dialogs.searchDlg, dialogs.findFilesDlg, dialogs.helpDlg, dialogs.argOptionDlg;
import parser.live;

import tango.stdc.stringz, tango.io.FilePath;

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
	GLOBAL.fileListTree = new CFileList;
	GLOBAL.projectTree = new CProjectTree;
	GLOBAL.outlineTree = new COutline;


	IupSetAttribute( GLOBAL.projectTree.getLayoutHandle, "TABTITLE", "Project" );
	IupSetAttribute( GLOBAL.fileListTree.getLayoutHandle, "TABTITLE", "FileList" );
	IupSetAttribute( GLOBAL.outlineTree.getLayoutHandle, "TABTITLE", "Outline" );
	
	IupSetAttribute( GLOBAL.projectTree.getLayoutHandle, "TABIMAGE", "icon_packageexplorer" );
	IupSetAttribute( GLOBAL.fileListTree.getLayoutHandle, "TABIMAGE", "icon_filelist" );
	IupSetAttribute( GLOBAL.outlineTree.getLayoutHandle, "TABIMAGE", "icon_outline" );


	GLOBAL.projectViewTabs = IupTabs( GLOBAL.fileListTree.getLayoutHandle, GLOBAL.projectTree.getLayoutHandle, GLOBAL.outlineTree.getLayoutHandle, null );
	IupSetAttributes( GLOBAL.projectViewTabs, "TABTYPE=BOTTOM,SIZE=NULL" );
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
	IupSetCallback( GLOBAL.messageWindowTabs, "RIGHTCLICK_CB", cast(Icallback) &messageTabRightClick_cb );

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
	GLOBAL.compilerHelpDlg	= new CCompilerHelpDialog( 500, 400, "Compiler Options" );
	GLOBAL.argsDlg			= new CArgOptionDialog( -1, -1, "Compiler Options / EXE Arguments" );
	GLOBAL.searchDlg		= new CSearchDialog( -1, -1, "Search/Replace" );
	GLOBAL.serachInFilesDlg	= new CFindInFilesDialog( -1, -1, "Search/Replace In Files" );
}

extern(C)
{
	int mainDialog_CLOSE_cb(Ihandle *ih)
	{
		int ret = ScintillaAction.closeAllDocument();
		if( ret == IUP_IGNORE ) return IUP_IGNORE;
		
		// Save All Project	
		foreach( PROJECT p; GLOBAL.projectManager )
		{
			p.saveFile();
		}

		CPreferenceDialog.save();

		return IUP_CLOSE;
	}

	int GlobalKeyPress_CB( int c, int press )
	{
		if( press == 0 ) 
		{
			try
			{
				if( GLOBAL.liveLevel > 0 && !GLOBAL.bKeyUp )
				{
					switch( c )
					{
						case 8, 9, 10, 13, 65535:
							LiveParser.parseCurrentLine();
							break;
							
						default:
							if( c > 31 && c < 127 ) LiveParser.parseCurrentLine();
					}
				}
			}
			catch( Exception e ){}
		
			GLOBAL.bKeyUp = true; // Release
		}
			
		//if( press == 0 ) IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( "KeyUP\n" ) );else IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( "KeyDOWN\n" ) );

		return IUP_DEFAULT;
	}

	int mainKany_cb( Ihandle* ih, int c )
	{
		foreach( ShortKey sk; GLOBAL.shortKeys )
		{
			switch( sk.name )
			{
				case "Quick Run":
					if( sk.keyValue == c )
					{
						menu.quickRun_cb( null );
						return IUP_IGNORE;
					}
					break;
				case "Run":
					if( sk.keyValue == c )
					{
						menu.run_cb( null );
						return IUP_IGNORE;
					}
					break;
				case "Build":
					if( sk.keyValue == c )
					{
						menu.buildAll_cb( null );
						return IUP_IGNORE;
					}
					break;				
				case "On/Off Left-side Window":
					if( sk.keyValue == c ) 
					{
						menu.outline_cb( GLOBAL.menuOutlineWindow );
						IupSetFocus( ih );
						return IUP_IGNORE;
					}
					break;
				case "On/Off Bottom-side Window":
					if( sk.keyValue == c )
					{
						menu.message_cb( GLOBAL.menuMessageWindow );
						IupSetFocus( ih );
						return IUP_IGNORE;
					}
					break;
				case "Next Tab":
					if( sk.keyValue == c )
					{
						int count = IupGetChildCount( GLOBAL.documentTabs );
						if( count > 1 )
						{
							int id = IupGetInt( GLOBAL.documentTabs, "VALUEPOS" );
							if( id < count - 1 ) ++id; else id = 0;
							IupSetInt( GLOBAL.documentTabs, "VALUEPOS", id );
							actionManager.DocumentTabAction.tabChangePOS( GLOBAL.documentTabs, id, -1 );
						}
						return IUP_IGNORE;
					}
					break;

				case "Previous Tab":
					if( sk.keyValue == c )
					{
						int count = IupGetChildCount( GLOBAL.documentTabs );
						if( count > 1 )
						{
							int id = IupGetInt( GLOBAL.documentTabs, "VALUEPOS" );
							if( id > 0 ) --id; else id = --count;
							IupSetInt( GLOBAL.documentTabs, "VALUEPOS", id );
							actionManager.DocumentTabAction.tabChangePOS( GLOBAL.documentTabs, id, -1 );
						}
						return IUP_IGNORE;
					}
					break;					
				case "New Tab":
					if( sk.keyValue == c )
					{
						menu.newFile_cb( ih );
						return IUP_IGNORE;
					}
					break;

				default:
			}
		}

		return IUP_DEFAULT;
	}	
	
	private int label_dropfiles_cb( Ihandle *ih, char* filename, int num, int x, int y )
	{
		scope f = new FilePath( fromStringz( filename ) );

		if( f.name == ".poseidon" )
		{
			char[] dir = f.path;
			if( dir.length ) dir = dir[0..length-1]; else return IUP_DEFAULT; // Remove tail '/'
			GLOBAL.projectTree.openProject( dir );
		}
		else
		{
			actionManager.ScintillaAction.openFile( fromStringz( filename ).dup  );
			if( IupGetInt( GLOBAL.dndDocumentZBox, "VALUEPOS" ) == 0 ) IupSetInt( GLOBAL.dndDocumentZBox, "VALUEPOS", 1 );
		}
		return IUP_DEFAULT;
	}

	private int messageTabRightClick_cb( Ihandle* ih, int pos )
	{
		// ih = GLOBAL.messageWindowTabs
		// So we need get the child's Ihandle
		Ihandle* _child = IupGetChild( ih, pos );
		// Get Focus
		IupSetAttribute( GLOBAL.messageWindowTabs, "VALUE_HANDLE", cast(char*)_child );

		if( pos == 2 ) return IUP_DEFAULT;


		Ihandle* _clear = IupItem( "Clear Output", null );
		IupSetAttribute( _clear, "IMAGE", "icon_debug_clear" );
		IupSetCallback( _clear, "ACTION", cast(Icallback) cast(Icallback) function( Ihandle* _ih )
		{
			int valuePos = IupGetInt( GLOBAL.messageWindowTabs, "VALUEPOS" );
			if( valuePos == 0 )
			{
				IupSetAttribute( GLOBAL.outputPanel, "VALUE", null );
			}
			else if( valuePos == 1 )
			{
				IupSetAttribute( GLOBAL.searchOutputPanel , "VALUE", null );
			}
		});
		Ihandle* popupMenu = IupMenu( _clear, null );

		IupPopup( popupMenu, IUP_MOUSEPOS, IUP_MOUSEPOS );
		IupDestroy( popupMenu );		

		return IUP_DEFAULT;
	}
}