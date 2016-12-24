module layout;

import iup.iup;

import global, IDE, scintilla, project, tools, dialogs.preferenceDlg;
import layouts.tabDocument, layouts.toolbar, layouts.filelistPanel, layouts.projectPanel, layouts.messagePanel, layouts.statusBar, layouts.outlinePanel, layouts.debugger, actionManager, menu;
import dialogs.searchDlg, dialogs.findFilesDlg, dialogs.helpDlg, dialogs.argOptionDlg;
import parser.live, parser.autocompletion;

import tango.stdc.stringz, tango.io.FilePath, Integer = tango.text.convert.Integer, Util = tango.text.Util;

void createExplorerWindow()
{
	GLOBAL.toolbar = new CToolBar();

	GLOBAL.fileListTree = new CFileList;
	GLOBAL.projectTree = new CProjectTree;
	GLOBAL.outlineTree = new COutline;

	IupSetAttribute( GLOBAL.projectTree.getLayoutHandle, "TABTITLE", toStringz( GLOBAL.languageItems["prj"] ) );
	IupSetAttribute( GLOBAL.outlineTree.getLayoutHandle, "TABTITLE", toStringz( GLOBAL.languageItems["outline"] ) );
	
	IupSetAttribute( GLOBAL.projectTree.getLayoutHandle, "TABIMAGE", "icon_packageexplorer" );
	IupSetAttribute( GLOBAL.outlineTree.getLayoutHandle, "TABIMAGE", "icon_outline" );


	GLOBAL.projectViewTabs = IupTabs( GLOBAL.projectTree.getLayoutHandle, GLOBAL.outlineTree.getLayoutHandle, null );
	IupSetAttributes( GLOBAL.projectViewTabs, "TABTYPE=BOTTOM,SIZE=NULL" );
	//IupSetAttribute( GLOBAL.projectViewTabs, "FONT", "Consolas, 18" );

	GLOBAL.fileListSplit = IupSplit( GLOBAL.projectViewTabs, GLOBAL.fileListTree.getLayoutHandle );
	IupSetAttributes( GLOBAL.fileListSplit, "ORIENTATION=HORIZONTAL,AUTOHIDE=NO,LAYOUTDRAG=NO,SHOWGRIP=LINES" );
	version(Windows) IupSetInt( GLOBAL.fileListSplit, "BARSIZE", 3 ); else IupSetInt( GLOBAL.fileListSplit, "BARSIZE", 2 );


	createTabs();

	Ihandle* dndEmptylabel = IupLabel( null );
	IupSetAttribute( dndEmptylabel, "EXPAND", "YES" );
	IupSetCallback( dndEmptylabel, "DROPFILES_CB",cast(Icallback) &label_dropfiles_cb );
	GLOBAL.dndDocumentZBox = IupZbox( dndEmptylabel, GLOBAL.documentTabs, null  );

	//GLOBAL.explorerSplit = IupSplit( _split, GLOBAL.dndDocumentZBox );
	GLOBAL.explorerSplit = IupSplit( GLOBAL.fileListSplit, GLOBAL.dndDocumentZBox );
	IupSetAttributes(GLOBAL.explorerSplit, "ORIENTATION=VERTICAL,AUTOHIDE=YES,LAYOUTDRAG=NO,SHOWGRIP=LINES");
	version(Windows) IupSetInt( GLOBAL.explorerSplit, "BARSIZE", 3 ); else IupSetInt( GLOBAL.explorerSplit, "BARSIZE", 2 );

	
	createMessagePanel();

	GLOBAL.debugPanel = new CDebugger();

	GLOBAL.messageWindowTabs = IupTabs( GLOBAL.outputPanel, GLOBAL.searchOutputPanel, GLOBAL.debugPanel.getMainHandle, null );
	IupSetCallback( GLOBAL.messageWindowTabs, "RIGHTCLICK_CB", cast(Icallback) &messageTabRightClick_cb );

	IupSetAttribute( GLOBAL.messageWindowTabs, "TABTYPE", "TOP" );
	IupSetAttributeId( GLOBAL.messageWindowTabs, "TABVISIBLE", 2, "NO" ); // Hide the Debug window

	Ihandle* messageScrollBox = IupScrollBox( GLOBAL.messageWindowTabs );
	 

	GLOBAL.messageSplit = IupSplit(GLOBAL.explorerSplit, messageScrollBox );
	IupSetAttributes(GLOBAL.messageSplit, "ORIENTATION=HORIZONTAL,AUTOHIDE=YES,LAYOUTDRAG=NO,SHOWGRIP=LINES");
	version(Windows) IupSetInt( GLOBAL.messageSplit, "BARSIZE", 2 ); else IupSetInt( GLOBAL.messageSplit, "BARSIZE", 2 );

	Ihandle* StatusBar = createStatusBar();

	Ihandle* VBox = IupVbox( GLOBAL.toolbar.getHandle, GLOBAL.messageSplit, StatusBar, null );
	IupAppend( GLOBAL.mainDlg, VBox );
	//IupSetAttribute( GLOBAL.documentTabs, "VISIBLE", "NO" );
}

void createEditorSetting()
{
	IDECONFIG.load();
}

void createLayout()
{
	createExplorerWindow();
}

void createDialog()
{
	GLOBAL.compilerHelpDlg	= new CCompilerHelpDialog( 500, 400, GLOBAL.languageItems["caption_optionhelp"]);
	GLOBAL.argsDlg			= new CArgOptionDialog( -1, -1, GLOBAL.languageItems["caption_argtitle"] );
	GLOBAL.searchDlg		= new CSearchDialog( -1, -1, GLOBAL.languageItems["sc_findreplace"] );
	GLOBAL.serachInFilesDlg	= new CFindInFilesDialog( -1, -1, GLOBAL.languageItems["sc_findreplacefiles"] );
}

extern(C)
{
	int mainDialog_CLOSE_cb(Ihandle *ih)
	{
		try
		{
		int ret = ScintillaAction.closeAllDocument();
		if( ret == IUP_IGNORE ) return IUP_IGNORE;
		
		// Save All Project	
		foreach( PROJECT p; GLOBAL.projectManager )
		{
			p.saveFile();
		}

		IDECONFIG.save();

		foreach( parser; GLOBAL.parserManager )
		{
			delete parser;
		}
		}
		catch(Exception e )
		{
			IupMessage("",toStringz(e.toString()));
			
		}


		return IUP_CLOSE;
	}

	int mainDialog_SHOW_cb( Ihandle *ih,int state )
	{
		switch( state )
		{
			case IUP_MAXIMIZE:	GLOBAL.editorSetting01.PLACEMENT = "MAXIMIZED";		break;
			case IUP_RESTORE:	GLOBAL.editorSetting01.PLACEMENT = "NORMAL";		break;
			case IUP_MINIMIZE:	GLOBAL.editorSetting01.PLACEMENT = "MINIMIZED";		break;
			default:
		}

		return IUP_DEFAULT;
	}
	
	int mainDialog_RESIZE_cb( Ihandle *ih, int width, int height )
	{
		if( GLOBAL.editorSetting01.PLACEMENT != "MAXIMIZED" ) GLOBAL.editorSetting01.RASTERSIZE = Integer.toString( width ) ~ "x" ~ Integer.toString( height );
		return IUP_DEFAULT;
	}
	
	int GlobalKeyPress_CB( int c, int press )
	{
		if( press == 0 ) 
		{
			try
			{
				auto cSci = actionManager.ScintillaAction.getActiveCScintilla();

				// Auto convert keyword case......
				if( GLOBAL.keywordCase > 0 )
				{
					if( cSci !is null )
					{
						if( ( c > 31 && c < 127 ) || c == 9 || c == 32 )
						{
							int currentPos = actionManager.ScintillaAction.getCurrentPos( cSci.getIupScintilla );
							if( c == 9 || c == 32 ) currentPos--;
							
							char[]	nextChar = lowerCase( fromStringz( IupGetAttributeId( cSci.getIupScintilla, "CHAR", currentPos ) ) );
							bool	bContinue = true;
							
							
							if( nextChar.length )
							{
								if( nextChar[0] >= 'a' && nextChar[0] <= 'z' ) bContinue = false;
							}

							if( bContinue )
							{
								int		headPos;
								char[]	word = AutoComplete.getWholeWordReverse( cSci.getIupScintilla, currentPos, headPos );
								word = lowerCase( word.reverse );

								if( word.length )
								{
									bool bExitFlag;
									foreach( char[] _keyword; GLOBAL.KEYWORDS )
									{
										foreach( char[] _k; Util.split( _keyword, " " ) )
										{								
											if( lowerCase( _k ) == word )
											{
												if( c == 9 || c == 32 )
												{
													currentPos++;
													word ~= c;
												}
												//IupMessage("",toStringz( Integer.toString( ++headPos ) ~ ":" ~ Integer.toString( currentPos ) ) );
												IupSetAttribute( cSci.getIupScintilla, "SELECTIONPOS", toStringz( Integer.toString( ++headPos ) ~ ":" ~ Integer.toString( currentPos ) ) );
												word = tools.convertKeyWordCase( GLOBAL.keywordCase, word );
												IupSetAttribute( cSci.getIupScintilla, "SELECTEDTEXT", toStringz( word ) );
												bExitFlag = true;
												break;
											}
										}
										if( bExitFlag ) break;
									}
								}
							}
						}
					}
				}

				
				if( GLOBAL.enableParser == "ON" && GLOBAL.liveLevel > 0 && !GLOBAL.bKeyUp )
				{
					if( cSci !is null )
					{
						switch( c )
						{
							case 8, 9, 10, 13, 65535:
								switch( GLOBAL.liveLevel )
								{
									case 1: LiveParser.parseCurrentLine(); break;
									case 2: LiveParser.parseCurrentBlock(); break;
									default:
								}
								break;
								
							default:
								if( c > 31 && c < 127 )
								{
									switch( GLOBAL.liveLevel )
									{
										case 1: LiveParser.parseCurrentLine(); break;
										case 2: LiveParser.parseCurrentBlock(); break;
										default:
									}
								}
						}
					}
				}
			}
			catch( Exception e ){}
		
			GLOBAL.bKeyUp = true; // Release
			GLOBAL.KeyNumber = -1;
		}
		else
		{
			GLOBAL.KeyNumber = c;
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
				case "quickrun":
					if( sk.keyValue == c )
					{
						menu.quickRun_cb( null );
						return IUP_IGNORE;
					}
					break;
				case "run":
					if( sk.keyValue == c )
					{
						menu.run_cb( null );
						return IUP_IGNORE;
					}
					break;
				case "build":
					if( sk.keyValue == c )
					{
						menu.buildAll_cb( null );
						return IUP_IGNORE;
					}
					break;				
				case "outlinewindow":
					if( sk.keyValue == c ) 
					{
						menu.outlineMenuItem_cb( GLOBAL.menuOutlineWindow );
						IupSetFocus( ih );
						return IUP_IGNORE;
					}
					break;
				case "messagewindow":
					if( sk.keyValue == c )
					{
						menu.messageMenuItem_cb( GLOBAL.menuMessageWindow );
						IupSetFocus( ih );
						return IUP_IGNORE;
					}
					break;
				case "nexttab":
					if( sk.keyValue == c )
					{
						int count = IupGetChildCount( GLOBAL.documentTabs );
						if( count > 1 )
						{
							int id = IupGetInt( GLOBAL.documentTabs, "VALUEPOS" );
							if( id < count - 1 ) ++id; else id = 0;
							IupSetInt( GLOBAL.documentTabs, "VALUEPOS", id );
							actionManager.DocumentTabAction.tabChangePOS( GLOBAL.documentTabs, id );
						}
						return IUP_IGNORE;
					}
					break;

				case "prevtab":
					if( sk.keyValue == c )
					{
						int count = IupGetChildCount( GLOBAL.documentTabs );
						if( count > 1 )
						{
							int id = IupGetInt( GLOBAL.documentTabs, "VALUEPOS" );
							if( id > 0 ) --id; else id = --count;
							IupSetInt( GLOBAL.documentTabs, "VALUEPOS", id );
							actionManager.DocumentTabAction.tabChangePOS( GLOBAL.documentTabs, id );
						}
						return IUP_IGNORE;
					}
					break;					

				case "newtab":
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
			actionManager.ScintillaAction.openFile( f.toString  );
			actionManager.ScintillaAction.updateRecentFiles( f.toString );
			
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


		Ihandle* _clear = IupItem( toStringz( GLOBAL.languageItems["clear"] ), null );
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
