module layout;

import iup.iup, iup.iup_scintilla;

import global, IDE, scintilla, project, tools, dialogs.preferenceDlg;
import layouts.tabDocument, layouts.toolbar, layouts.filelistPanel, layouts.projectPanel, layouts.messagePanel, layouts.statusBar, layouts.outlinePanel, layouts.debugger, actionManager, menu;
import layouts.statusBar;
import dialogs.searchDlg, dialogs.findFilesDlg, dialogs.helpDlg, dialogs.argOptionDlg, dialogs.idemessageDlg;
import parser.live, parser.autocompletion;

import tango.stdc.stringz, tango.io.FilePath, Integer = tango.text.convert.Integer, Util = tango.text.Util;
import tango.sys.win32.UserGdi;

void createExplorerWindow()
{
	GLOBAL.toolbar = new CToolBar();

	GLOBAL.fileListTree = new CFileList;
	GLOBAL.projectTree = new CProjectTree;
	GLOBAL.outlineTree = new COutline;

	IupSetAttribute( GLOBAL.projectTree.getLayoutHandle, "TABTITLE", GLOBAL.languageItems["prj"].toCString );
	IupSetAttribute( GLOBAL.outlineTree.getLayoutHandle, "TABTITLE", GLOBAL.languageItems["outline"].toCString );
	
	IupSetAttribute( GLOBAL.projectTree.getLayoutHandle, "TABIMAGE", "icon_packageexplorer" );
	IupSetAttribute( GLOBAL.outlineTree.getLayoutHandle, "TABIMAGE", "icon_outline" );


	GLOBAL.projectViewTabs = IupTabs( GLOBAL.projectTree.getLayoutHandle, GLOBAL.outlineTree.getLayoutHandle, null );
	IupSetAttributes( GLOBAL.projectViewTabs, "TABTYPE=BOTTOM,SIZE=NULL,BORDER=NO,NAME=POSEIDON_LEFT_TABS" );
	//IupSetAttribute( GLOBAL.projectViewTabs, "FONT", "Consolas, 18" );

	GLOBAL.fileListSplit = IupSplit( GLOBAL.projectViewTabs, GLOBAL.fileListTree.getLayoutHandle );
	IupSetAttributes( GLOBAL.fileListSplit, "ORIENTATION=HORIZONTAL,AUTOHIDE=YES,LAYOUTDRAG=NO,SHOWGRIP=LINES" );
	IupSetInt( GLOBAL.fileListSplit, "BARSIZE", Integer.atoi( GLOBAL.editorSetting01.BarSize ) );
	//version(Windows) IupSetInt( GLOBAL.fileListSplit, "BARSIZE", 3 ); else IupSetInt( GLOBAL.fileListSplit, "BARSIZE", 2 );

	createTabs();
	createTabs2();

	Ihandle* dndEmptylabel = IupLabel( null );
	IupSetAttribute( dndEmptylabel, "EXPAND", "YES" );
	IupSetCallback( dndEmptylabel, "DROPFILES_CB",cast(Icallback) &label_dropfiles_cb );
	IupSetCallback( dndEmptylabel, "BUTTON_CB",cast(Icallback) &emptyLabel_button_cb );
	GLOBAL.dndDocumentZBox = IupZbox( dndEmptylabel, GLOBAL.documentTabs, null  );
	
	// RIGHT
	if( GLOBAL.editorSetting01.RotateTabs == "ON" )
		GLOBAL.documentSplit = IupSplit( GLOBAL.dndDocumentZBox, null );
	else
		GLOBAL.documentSplit = IupSplit( GLOBAL.dndDocumentZBox, GLOBAL.documentTabs_Sub );
		
	IupSetAttributes( GLOBAL.documentSplit, "ORIENTATION=VERTICAL,AUTOHIDE=YES,LAYOUTDRAG=NO,VALUE=1000,BARSIZE=0,ACTIVE=YES,SHOWGRIP=NO" );
	IupSetAttribute( GLOBAL.documentTabs, "ACTIVE","YES" );
	//IupSetAttribute( GLOBAL.documentTabs_Sub, "ACTIVE","YES" );

	// BOTTOM
	if( GLOBAL.editorSetting01.RotateTabs == "ON" )
		GLOBAL.documentSplit2 = IupSplit( GLOBAL.documentSplit, GLOBAL.documentTabs_Sub );
	else
		GLOBAL.documentSplit2 = IupSplit( GLOBAL.documentSplit, null );
		
	IupSetAttributes( GLOBAL.documentSplit2, "ORIENTATION=HORIZONTAL,AUTOHIDE=YES,LAYOUTDRAG=NO,VALUE=1000,BARSIZE=0,ACTIVE=YES,SHOWGRIP=LINES" );
	IupSetAttribute( GLOBAL.documentSplit2, "ACTIVE","YES" );
	
	GLOBAL.searchExpander = new CSearchExpander;
	GLOBAL.activeDocumentTabs = GLOBAL.documentTabs;

	Ihandle* projectViewBackground = IupBackgroundBox( GLOBAL.fileListSplit );
	
	GLOBAL.explorerSplit = IupSplit( projectViewBackground, IupVbox( GLOBAL.documentSplit2, GLOBAL.searchExpander.getHandle, null ) );
	IupSetAttributes(GLOBAL.explorerSplit, "ORIENTATION=VERTICAL,AUTOHIDE=YES,LAYOUTDRAG=NO,SHOWGRIP=LINES,NAME=POSEIDON_LEFT_SPLIT");
	//version(Windows) IupSetInt( GLOBAL.explorerSplit, "BARSIZE", 3 ); else IupSetInt( GLOBAL.explorerSplit, "BARSIZE", 2 );
	IupSetInt( GLOBAL.explorerSplit, "BARSIZE", Integer.atoi( GLOBAL.editorSetting01.BarSize ) );

	//createMessagePanel();
	GLOBAL.messagePanel = new CMessageAndSearch();
	
	//IupDestroy( test );	
	
	bool bUseIupTabs;

	version(FBIDE)
	{
		GLOBAL.debugPanel = new CDebugger();
		
		version(Windows)
		{
			GLOBAL.messageWindowTabs = IupFlatTabs( GLOBAL.messagePanel.getOutputPanelHandle, GLOBAL.messagePanel.getSearchOutputPanelHandle, GLOBAL.debugPanel.getMainHandle, null );
		}
		else
		{
			if( GLOBAL.IUP_VERSION > 3.24 )
			{
				GLOBAL.messageWindowTabs = IupFlatTabs( GLOBAL.messagePanel.getOutputPanelHandle, GLOBAL.messagePanel.getSearchOutputPanelHandle, GLOBAL.debugPanel.getMainHandle, null );
			}
			else
			{
				GLOBAL.messageWindowTabs = IupTabs( GLOBAL.messagePanel.getOutputPanelHandle, GLOBAL.messagePanel.getSearchOutputPanelHandle, GLOBAL.debugPanel.getMainHandle, null );
				bUseIupTabs = true;
			}
		}
	}
	version(DIDE)	GLOBAL.messageWindowTabs = IupFlatTabs( GLOBAL.messagePanel.getOutputPanelHandle, GLOBAL.messagePanel.getSearchOutputPanelHandle, null );

	if( !bUseIupTabs )
	{
		IupSetAttribute( GLOBAL.messageWindowTabs, "HIGHCOLOR", "0 0 255" );
		IupSetAttribute( GLOBAL.messageWindowTabs, "TABSIMAGESPACING", "3" );
		if( GLOBAL.IUP_VERSION > 3.24 ) IupSetAttribute( GLOBAL.messageWindowTabs, "TABSPADDING", "6x2" ); else IupSetAttribute( GLOBAL.messageWindowTabs, "TABSPADDING", "10x4" );
		IupSetAttribute( GLOBAL.messageWindowTabs, "FORECOLOR", "0 0 255" );
		IupSetAttribute( GLOBAL.messageWindowTabs, "HIGHCOLOR", "255 0 0" );
		IupSetAttribute( GLOBAL.messageWindowTabs, "NAME", "POSEIDON_BOTTOM_TABS" );
		IupSetCallback( GLOBAL.messageWindowTabs, "FLAT_BUTTON_CB", cast(Icallback) &CStatusBar_Empty_BUTTON_CB );
		/*
		IupSetAttribute( GLOBAL.messageWindowTabs, "EXTRABUTTONS", "1" );
		IupSetAttributeId( GLOBAL.messageWindowTabs, "EXTRAIMAGE", 1, "icon_downarrow" );
		*/
	}
	
	IupSetCallback( GLOBAL.messageWindowTabs, "RIGHTCLICK_CB", cast(Icallback) &messageTabRightClick_cb );
	IupSetAttribute( GLOBAL.messageWindowTabs, "TABTYPE", "TOP" );
	IupSetAttributeId( GLOBAL.messageWindowTabs, "TABVISIBLE", 2, "NO" ); // Hide the Debug window

	
	Ihandle* messageScrollBox = IupScrollBox( GLOBAL.messageWindowTabs );

	GLOBAL.messageSplit = IupSplit(GLOBAL.explorerSplit, messageScrollBox );
	IupSetAttributes(GLOBAL.messageSplit, "ORIENTATION=HORIZONTAL,AUTOHIDE=YES,LAYOUTDRAG=NO,SHOWGRIP=LINES,NAME=POSEIDON_BOTTOM_SPLIT");
	//IupSetInt( GLOBAL.messageSplit, "BARSIZE", 2 );
	IupSetInt( GLOBAL.messageSplit, "BARSIZE", Integer.atoi( GLOBAL.editorSetting01.BarSize ) );
	/*
	IupSetCallback( GLOBAL.messageSplit, "VALUECHANGED_CB", cast(Icallback) function( Ihandle* ih ){
		if( GLOBAL.fileListTree.getTreeH <= 6 ) IupSetInt( GLOBAL.fileListSplit, "VALUE", 1000 );		
		return IUP_IGNORE;
	});
	*/

	GLOBAL.statusBar = new CStatusBar();

	Ihandle* VBox = IupVbox( GLOBAL.toolbar.getHandle, GLOBAL.messageSplit, GLOBAL.statusBar.getLayoutHandle, null );
	IupAppend( GLOBAL.mainDlg, VBox );
	//IupSetAttribute( GLOBAL.documentTabs, "VISIBLE", "NO" );
	
	Ihandle* _scrolllabel = IupLabel( null );
	IupSetStrAttribute( _scrolllabel, "IMAGE", "icon_scroll" );
	
	GLOBAL.scrollICONHandle = IupDialog( _scrolllabel );
	IupSetStrAttribute( GLOBAL.scrollICONHandle, "OPACITYIMAGE", "icon_scroll" );
	IupSetAttributes( GLOBAL.scrollICONHandle, "RESIZE=NO,MAXBOX=NO,MINBOX=NO,MENUBOX=NO,BORDER=NO" );
	IupSetAttribute( GLOBAL.scrollICONHandle, "PARENTDIALOG", "POSEIDON_MAIN_DIALOG" );
	GLOBAL.scrollTimer = IupTimer();
	IupSetAttributes( GLOBAL.scrollTimer, "TIME=200,RUN=NO" );
	IupSetCallback( GLOBAL.scrollTimer, "ACTION_CB", cast(Icallback) function( Ihandle* ih )
	{
		if( GLOBAL.editorSetting00.MiddleScroll == "ON" )
		{
			if( fromStringz( IupGetAttribute( GLOBAL.scrollICONHandle, "VISIBLE" ) ) == "YES" )
			{
				Ihandle* _ih = ScintillaAction.getActiveIupScintilla();
				
				if( _ih != null )
				{
					char[] cursorString = fromStringz( IupGetGlobal( "CURSORPOS" ) );
					
					int		cursorX, cursorY, iconX, iconY;
					int 	crossSign = Util.index( cursorString, "x" );
					if( crossSign < cursorString.length )
					{
						cursorX = Integer.atoi( cursorString[0..crossSign] );
						cursorY = Integer.atoi( cursorString[crossSign+1..$] );
					}
					
					char[] iconString = fromStringz( IupGetAttribute( GLOBAL.scrollICONHandle, "SCREENPOSITION" ) );
					crossSign = Util.index( iconString, "," );
					
					if( crossSign < iconString.length )
					{
						iconX = Integer.atoi( iconString[0..crossSign] );
						iconY = Integer.atoi( iconString[crossSign+1..$] );
					}
					
					if( cursorY > iconY + 16 )
					{
						int add = ( cursorY - iconY - 16 ) / 5 + 1;
						IupScintillaSendMessage( _ih, 2168, 0, add ); // SCI_LINESCROLL 2168
						
					}
					else if( cursorY < iconY + 16 )
					{
						int minus = ( cursorY - iconY - 16 ) / 5 - 1;
						IupScintillaSendMessage( _ih, 2168, 0, minus ); // SCI_LINESCROLL 2168
					}
					
					if( cursorX > iconX + 16 )
					{
						int add = ( cursorX - iconX - 16 ) / 100;
						IupScintillaSendMessage( _ih, 2168, add, 0 ); // SCI_LINESCROLL 2168
						
					}
					else if( cursorX < iconX + 16 )
					{
						int minus = ( cursorX - iconX - 16 ) / 100;
						IupScintillaSendMessage( _ih, 2168, minus, 0 ); // SCI_LINESCROLL 2168
					}
				}
			}
		}
		
		return IUP_DEFAULT;
	});
}

void createEditorSetting()
{
	//IDECONFIG.load();
	GLOBAL.IDEMessageDlg	= new CIDEMessageDialog( -1, -1, GLOBAL.languageItems["message"].toDString, true, "POSEIDON_MAIN_DIALOG" );
	//GLOBAL.IDEMessageDlg.show( IUP_RIGHT, 24 );
	//IupHide( GLOBAL.IDEMessageDlg.getIhandle );

	IDECONFIG.loadINI();
	
	GLOBAL.IDEMessageDlg.setFont( GLOBAL.fonts[7].fontString );
	GLOBAL.IDEMessageDlg.setLocalization();
	
	if( GLOBAL.editorSetting00.DocStatus == "ON" ) IDECONFIG.loadFileStatus();
}

void createLayout()
{
	createExplorerWindow();
}

void createDialog()
{
	GLOBAL.compilerHelpDlg	= new CCompilerHelpDialog( 500, 400, GLOBAL.languageItems["caption_optionhelp"].toDString );
	//GLOBAL.argsDlg			= new CArgOptionDialog( -1, -1, GLOBAL.languageItems["caption_argtitle"].toDString );
	//GLOBAL.searchDlg		= new CSearchDialog( -1, -1, GLOBAL.languageItems["sc_findreplace"].toDString, null, false, "POSEIDON_MAIN_DIALOG" );
	GLOBAL.serachInFilesDlg	= new CFindInFilesDialog( -1, -1, GLOBAL.languageItems["sc_findreplacefiles"].toDString, null, false, "POSEIDON_MAIN_DIALOG" );
}


extern(C)
{
	version(Windows)
	{
		int mainDialog_COPYDATA_CB(Ihandle *ih, char* cmdLine, int size)
		{
			char[][]	args;
			char[][]	_args = Util.split( fromStringz( cmdLine ), "\"" );
			
			foreach( char[] s; _args )
			{
				s = Util.trim( s );
				if( s.length ) args ~= s;
			}
			
			if( args.length > 1 )
			{
				scope argPath = new FilePath( args[1] );
				if( argPath.exists() )
				{
					version(FBIDE)	char[] PRJFILE = ".poseidon";
					version(DIDE)	char[] PRJFILE = "D.poseidon";
					if( argPath.file == PRJFILE )
					{
						char[] dir = argPath.path;
						if( dir.length ) dir = dir[0..$-1]; // Remove tail '/'
						GLOBAL.projectTree.openProject( dir );				
					}
					else
					{
						ScintillaAction.openFile( args[1] );
					}
				}				
				
			}

			//IupShow( ih );
			if( IsIconic( IupGetAttribute( GLOBAL.mainDlg, "HWND" ) ) )
			{
				ShowWindow( IupGetAttribute( GLOBAL.mainDlg, "HWND" ), SW_RESTORE);  
			}
			else
			{
				SetForegroundWindow( IupGetAttribute( GLOBAL.mainDlg, "HWND" ) );
			}			
			
			return IUP_DEFAULT;
		}
	}

	int mainDialog_CLOSE_cb(Ihandle *ih)
	{
		try
		{
			char[][] tempPrevDocs;
			if( GLOBAL.editorSetting00.LoadPrevDoc == "ON" )
			{
				Ihandle* activeHandle = cast(Ihandle*) IupGetAttribute( GLOBAL.activeDocumentTabs, "VALUE_HANDLE" );
				
				for( int i = 0; i < IupGetInt( GLOBAL.documentTabs, "COUNT" ); ++ i )
				{
					Ihandle* documentHandle = IupGetChild( GLOBAL.documentTabs, i );
					if( documentHandle != null )
					{
						auto cSci = ScintillaAction.getCScintilla( documentHandle );
						if( cSci !is null )
						{
							if( activeHandle == documentHandle ) tempPrevDocs ~= ( "*" ~ cSci.getFullPath ); else	tempPrevDocs ~= cSci.getFullPath;
						}
					}
				}

				for( int i = 0; i < IupGetInt( GLOBAL.documentTabs_Sub, "COUNT" ); ++ i )
				{
					Ihandle* documentHandle = IupGetChild( GLOBAL.documentTabs_Sub, i );
					if( documentHandle != null )
					{
						auto cSci = ScintillaAction.getCScintilla( documentHandle );
						if( cSci !is null )
						{
							if( activeHandle == documentHandle ) tempPrevDocs ~= ( "*" ~ cSci.getFullPath ); else tempPrevDocs ~= cSci.getFullPath;
						}
					}
				}
			}
			
			int ret = ScintillaAction.closeAllDocument();
			if( ret == IUP_IGNORE ) return IUP_IGNORE;
			
			GLOBAL.prevDoc = tempPrevDocs;
			
			// Save All Project
			GLOBAL.prevPrj.length = 0;
			foreach( PROJECT p; GLOBAL.projectManager )
			{
				try
				{
					p.saveFile();
					if( GLOBAL.editorSetting00.LoadPrevDoc == "ON" ) GLOBAL.prevPrj ~= p.dir;
				}
				catch( Exception e )
				{
					IupMessage( "Project Save Fail!",toStringz( e.toString() ) );
				}
			}

			GLOBAL.autoCompletionTriggerWordCount = GLOBAL.statusBar.getOriginalTrigger();
			//IDECONFIG.save();
			IDECONFIG.saveINI();

			foreach( parser; GLOBAL.parserManager )
			{
				if( parser !is null ) delete parser;
			}

			if( GLOBAL.objectDefaultParser !is null ) delete GLOBAL.objectDefaultParser;
			
			if( GLOBAL.editorSetting00.DocStatus == "ON" ) IDECONFIG.saveFileStatus();
			
			if( GLOBAL.scrollTimer != null ) IupDestroy( GLOBAL.scrollTimer );
			
			foreach( _plugin; GLOBAL.pluginMnager )
			{
				if( _plugin !is null ) delete _plugin;
			}
		}
		catch( Exception e )
		{
			debug IupMessage("",toStringz(e.toString()));
		}

		return IUP_CLOSE;
	}

	int mainDialog_SHOW_cb( Ihandle *ih,int state )
	{
		switch( state )
		{
			case IUP_MAXIMIZE:			GLOBAL.editorSetting01.PLACEMENT = "MAXIMIZED";		break;
			case IUP_RESTORE:			GLOBAL.editorSetting01.PLACEMENT = "NORMAL";		break;
			case IUP_MINIMIZE:			GLOBAL.editorSetting01.PLACEMENT = "MINIMIZED";		break;
			default:
		}

		return IUP_DEFAULT;
	}
	
	int mainDialog_RESIZE_cb( Ihandle *ih, int width, int height )
	{
		if( GLOBAL.editorSetting01.USEFULLSCREEN == "ON" ) return IUP_DEFAULT;
		
		if( GLOBAL.editorSetting01.PLACEMENT != "MAXIMIZED" )
		{
			scope rasterSize = new IupString;
			rasterSize = IupGetAttribute( GLOBAL.mainDlg, "RASTERSIZE");
			GLOBAL.editorSetting01.RASTERSIZE = rasterSize.toDString.dup;
		}
		//IupMessage("",toStringz(GLOBAL.editorSetting01.PLACEMENT));
		if( GLOBAL.editorSetting01.PLACEMENT != "MINIMIZED" ) GLOBAL.statusBar.setPrjNameSize( width );
		
		return IUP_DEFAULT;
	}
	
	int GlobalWHEEL_CB( Ihandle *ih, float delta, int x, int y, char *status )
	{
		if( GLOBAL.editorSetting00.MiddleScroll == "ON" )
			if( fromStringz( IupGetAttribute( GLOBAL.scrollICONHandle, "VISIBLE" ) ) == "YES" )
			{
				IupHide( GLOBAL.scrollICONHandle );
				IupSetAttribute( GLOBAL.scrollTimer, "RUN", "NO" );
			}
			
		return IUP_DEFAULT;
	}
	
	int GlobalKeyPress_CB( int c, int press )
	{
		if( press == 0 ) 
		{
			try
			{
				auto cSci = actionManager.ScintillaAction.getActiveCScintilla();
				if( cSci !is null )
				{
					if( GLOBAL.editorSetting00.BraceMatchHighlight == "ON" )
					{
						switch( c )
						{
							case 40, 41, 91, 93, 123, 125: // (, ), [, ], {, }
								int pos = ScintillaAction.getCurrentPos( cSci.getIupScintilla );
								if( !actionManager.ScintillaAction.isComment( cSci.getIupScintilla, pos ) )
								{
									int close = IupGetIntId( cSci.getIupScintilla, "BRACEMATCH", --pos );
									if( close > -1 )
									{
										IupScintillaSendMessage( cSci.getIupScintilla, 2351, pos, close );
										version(DIDE)
										{
											if( GLOBAL.editorSetting00.AutoIndent == "ON" )
											{
												if( c == 125 )
												{
													int currentLine = ScintillaAction.getLinefromPos( cSci.getIupScintilla, pos );
													int matchLine = ScintillaAction.getLinefromPos( cSci.getIupScintilla, close );
													if( matchLine < currentLine )
													{
														int matchInd = cast(int) IupScintillaSendMessage( cSci.getIupScintilla, 2127, matchLine, 0 ); // SCI_GETLINEINDENTATION = 2127
														IupScintillaSendMessage( cSci.getIupScintilla, 2126, currentLine, matchInd ); // SCI_SETLINEINDENTATION = 2126
														int changeLinePos = cast(int) IupScintillaSendMessage( cSci.getIupScintilla, 2128, currentLine, 0 ); // SCI_GETLINEINDENTPOSITION 2128
														IupScintillaSendMessage( cSci.getIupScintilla, 2025, ++changeLinePos , 0 );// SCI_GOTOPOS = 2025,
													}
												}
											}
										}
									}
									else
										IupScintillaSendMessage( cSci.getIupScintilla, 2351, -1, -1 ); // SCI_BRACEHIGHLIGHT 2351
								}
								break;
							case 8, 65535: // Back, Del
								int pos = ScintillaAction.getCurrentPos( cSci.getIupScintilla );
								if( !actionManager.ScintillaAction.isComment( cSci.getIupScintilla, pos ) )
								{
									int close = IupGetIntId( cSci.getIupScintilla, "BRACEMATCH", pos );
									if( close > -1 )
										IupScintillaSendMessage( cSci.getIupScintilla, 2351, pos, close ); 
									else
									{
										close = IupGetIntId( cSci.getIupScintilla, "BRACEMATCH", --pos );
										if( close > -1 ) IupScintillaSendMessage( cSci.getIupScintilla, 2351, pos, close ); else IupScintillaSendMessage( cSci.getIupScintilla, 2351, -1, -1 ); // SCI_BRACEHIGHLIGHT 2351
									}
								}
								break;
							
							default:
						}
					}
					else
					{
						version(DIDE)
						{
							if( GLOBAL.editorSetting00.AutoIndent == "ON" )
							{
								if( c == 125 )
								{
									int pos = ScintillaAction.getCurrentPos( cSci.getIupScintilla );
									if( !actionManager.ScintillaAction.isComment( cSci.getIupScintilla, pos ) )
									{
										int close = IupGetIntId( cSci.getIupScintilla, "BRACEMATCH", --pos );
										if( close > -1 )
										{								
											int currentLine = ScintillaAction.getLinefromPos( cSci.getIupScintilla, pos );
											int matchLine = ScintillaAction.getLinefromPos( cSci.getIupScintilla, close );
											if( matchLine < currentLine )
											{
												int matchInd = cast(int) IupScintillaSendMessage( cSci.getIupScintilla, 2127, matchLine, 0 ); // SCI_GETLINEINDENTATION = 2127
												IupScintillaSendMessage( cSci.getIupScintilla, 2126, currentLine, matchInd ); // SCI_SETLINEINDENTATION = 2126
												int changeLinePos = cast(int) IupScintillaSendMessage( cSci.getIupScintilla, 2128, currentLine, 0 ); // SCI_GETLINEINDENTPOSITION 2128
												IupScintillaSendMessage( cSci.getIupScintilla, 2025, ++changeLinePos , 0 );// SCI_GOTOPOS = 2025,
											}
										}
									}
								}
							}
						}
					}

					
					if( GLOBAL.enableParser == "ON" && GLOBAL.liveLevel > 0 && !GLOBAL.bKeyUp )
					{
						if( !AutoComplete.showCallTipThreadIsRunning && !AutoComplete.showListThreadIsRunning )
						{
							char[] s = ScintillaAction.getCurrentChar( -1, cSci.getIupScintilla );
							if( s.length ) c = cast(int) s[$-1];
							//GLOBAL.messagePanel.printOutputPanel( "Keycode:" ~ Integer.toString( c ) );
							
							switch( c )
							{
								case 10, 13: // Eneter
									switch( GLOBAL.liveLevel )
									{
										case 1:
											int prevLine = ScintillaAction.getCurrentLine( cSci.getIupScintilla ) - 1;
											char[] prevLineText = fromStringz( IupGetAttributeId( cSci.getIupScintilla, "LINE", prevLine - 1 ) ); // 0 BASE
											//GLOBAL.messagePanel.printOutputPanel( "prevLine(" ~ Integer.toString(prevLine) ~ "): " ~ prevLineText );
											
											if( Util.trim( prevLineText ).length )
											{
												if( Util.trim( fromStringz( IupGetAttribute( cSci.getIupScintilla, "LINEVALUE" ) ) ).length )
												{
													LiveParser.parseCurrentLine( prevLine );
													LiveParser.parseCurrentLine();
												}
											}
											break;
											
										case 2: LiveParser.parseCurrentBlock(); break;
										default:
									}
									break;

								case 8, 9, 65535:
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
			}
			catch( Exception e )
			{
				debug IupMessage( "GlobalKeyPress_CB Error", toStringz( "GlobalKeyPress_CB()\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ Integer.toString( e.line ) ) );
			}
		
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
				case "findinfile":
					if( sk.keyValue == c )
					{ 
						menu.findReplaceInFiles( ih );
						return IUP_IGNORE;
					}
					break;			
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
						int count = IupGetChildCount( GLOBAL.activeDocumentTabs );
						if( count > 1 )
						{
							int id = IupGetInt( GLOBAL.activeDocumentTabs, "VALUEPOS" );
							if( id < count - 1 ) ++id; else id = 0;
							//IupSetInt( GLOBAL.activeDocumentTabs, "VALUEPOS", id );
							DocumentTabAction.setFocus( IupGetChild( GLOBAL.activeDocumentTabs, id ) );
							actionManager.DocumentTabAction.tabChangePOS( GLOBAL.activeDocumentTabs, id );
						}
						return IUP_IGNORE;
					}
					break;

				case "prevtab":
					if( sk.keyValue == c )
					{
						int count = IupGetChildCount( GLOBAL.activeDocumentTabs );
						if( count > 1 )
						{
							int id = IupGetInt( GLOBAL.activeDocumentTabs, "VALUEPOS" );
							if( id > 0 ) --id; else id = --count;
							//IupSetInt( GLOBAL.activeDocumentTabs, "VALUEPOS", id );
							DocumentTabAction.setFocus( IupGetChild( GLOBAL.activeDocumentTabs, id ) );
							actionManager.DocumentTabAction.tabChangePOS( GLOBAL.activeDocumentTabs, id );
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
	
	private int emptyLabel_button_cb( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		// On/OFF Outline Window
		if( button == IUP_BUTTON1 ) // Left Click
		{
			if( DocumentTabAction.isDoubleClick( status ) )	menu.outlineMenuItem_cb( GLOBAL.menuOutlineWindow );
		}
		
		return IUP_DEFAULT;
	}
	
	private int label_dropfiles_cb( Ihandle *ih, char* filename, int num, int x, int y )
	{
		char[] _fn = fromStringz( filename );
		
		version(linux)
		{
			char[] result;
			
			for( int i = 0; i < _fn.length; ++ i )
			{
				if( _fn[i] != '%' )
				{
					result ~= _fn[i];
				}
				else
				{
					if( i + 2 < _fn.length )
					{
						char _a = _fn[i+1];
						char _b = _fn[i+2];
						
						char computeValue;
						
						
						if( _a >= '0' && _a <= '9' )
						{
							computeValue = ( _a - 48 ) * 16;
						}
						else if( _a >= 'A' && _a <= 'F' )
						{
							computeValue = ( _a - 55 ) * 16;
						}
						else
						{
							break;
						}
						
						if( _b >= '0' && _b <= '9' )
						{
							computeValue += ( _b - 48 );
						}
						else if( _b >= 'A' && _b <= 'F' )
						{
							computeValue += ( _b - 55 );
						}
						else
						{
							break;
						}
				
						result ~= cast(char)computeValue;
						
						i += 2;
					}
				}
			}
			
			_fn = result;
		}
		
		scope f = new FilePath( _fn );
		
		if( f.exists() )
		{
			version(FBIDE)	char[] PRJFILE = ".poseidon";
			version(DIDE)	char[] PRJFILE = "D.poseidon";
			if( f.name == PRJFILE )
			{
				char[] dir = f.path;
				if( dir.length ) dir = dir[0..$-1]; else return IUP_DEFAULT; // Remove tail '/'
				GLOBAL.projectTree.openProject( dir );
			}
			else
			{
				actionManager.ScintillaAction.openFile( f.toString, true );
				actionManager.ScintillaAction.updateRecentFiles( f.toString );
				
				if( IupGetInt( GLOBAL.dndDocumentZBox, "VALUEPOS" ) == 0 ) IupSetInt( GLOBAL.dndDocumentZBox, "VALUEPOS", 1 );
			}
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
		
		Ihandle* popupMenu;

		if( pos == 2 )
		{
			return IUP_DEFAULT;
		}
		else
		{
			Ihandle* _clear = IupItem( GLOBAL.languageItems["clear"].toCString, null );
			IupSetAttribute( _clear, "IMAGE", "icon_debug_clear" );
			IupSetCallback( _clear, "ACTION", cast(Icallback) function( Ihandle* _ih )
			{
				int valuePos = IupGetInt( GLOBAL.messageWindowTabs, "VALUEPOS" );
				if( valuePos == 0 )
				{
					//IupSetAttribute( GLOBAL.outputPanel, "VALUE", null );
					GLOBAL.messagePanel.printOutputPanel( "", true );
				}
				else if( valuePos == 1 )
				{
					//IupSetAttribute( GLOBAL.searchOutputPanel , "VALUE", null );
					GLOBAL.messagePanel.printSearchOutputPanel( "", true );
				}
				return IUP_DEFAULT;
			});
			popupMenu = IupMenu( _clear, null );
		}

		IupPopup( popupMenu, IUP_MOUSEPOS, IUP_MOUSEPOS );
		IupDestroy( popupMenu );

		return IUP_DEFAULT;
	}
}