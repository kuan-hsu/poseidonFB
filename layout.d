module layout;

import iup.iup, iup.iup_scintilla;

import global, IDE, scintilla, project, tools, dialogs.preferenceDlg;
import layouts.tabDocument, layouts.toolbar, layouts.projectPanel, layouts.messagePanel, layouts.statusBar, layouts.outlinePanel, layouts.debugger, actionManager, menu;
import layouts.statusBar;
import dialogs.searchDlg, dialogs.findFilesDlg, dialogs.helpDlg, dialogs.argOptionDlg;
import parser.live, parser.autocompletion;
import std.string, std.conv, std.file, Array = std.array, Path = std.path;
import core.sys.windows.winuser;

void changeIconLeftTABIMAGE()
{
	if( GLOBAL.editorSetting00.IconInvert == "ON" )
	{
		IupSetAttribute( GLOBAL.projectTree.getLayoutHandle, "TABIMAGE", "icon_packageexplorer_invert" );
		IupSetAttribute( GLOBAL.outlineTree.getLayoutHandle, "TABIMAGE", "icon_outline_invert" );
	}
	else
	{
		IupSetAttribute( GLOBAL.projectTree.getLayoutHandle, "TABIMAGE", "icon_packageexplorer" );
		IupSetAttribute( GLOBAL.outlineTree.getLayoutHandle, "TABIMAGE", "icon_outline" );
	}
}

void createExplorerWindow()
{
	GLOBAL.toolbar = new CToolBar();

	GLOBAL.projectTree = new CProjectTree;
	GLOBAL.outlineTree = new COutline;

	IupSetAttribute( GLOBAL.projectTree.getLayoutHandle, "TABTITLE", GLOBAL.languageItems["prj"].toCString );
	IupSetAttribute( GLOBAL.outlineTree.getLayoutHandle, "TABTITLE", GLOBAL.languageItems["outline"].toCString );
	changeIconLeftTABIMAGE();


	GLOBAL.projectViewTabs = IupFlatTabs( GLOBAL.projectTree.getLayoutHandle, GLOBAL.outlineTree.getLayoutHandle, null );
	IupSetAttributes( GLOBAL.projectViewTabs, "TABTYPE=BOTTOM,TABSPADDING=3x2,NAME=POSEIDON_LEFT_TABS" );
	//IupSetAttribute( GLOBAL.projectViewTabs, "FORECOLOR", "0 0 255" );
	IupSetAttribute( GLOBAL.projectViewTabs, "HIGHCOLOR", "255 0 0" );
	IupSetStrAttribute( GLOBAL.projectViewTabs, "FGCOLOR", toStringz( GLOBAL.editColor.outlineFore ) );
	IupSetStrAttribute( GLOBAL.projectViewTabs, "BGCOLOR", toStringz( GLOBAL.editColor.outlineBack ) );
	IupSetStrAttribute( GLOBAL.projectViewTabs, "TABSFORECOLOR", toStringz( GLOBAL.editColor.outlineFore ) );
	IupSetStrAttribute( GLOBAL.projectViewTabs, "TABSBACKCOLOR", toStringz( GLOBAL.editColor.outlineBack ) );
	IupSetStrAttribute( GLOBAL.projectViewTabs, "TABSLINECOLOR", toStringz( GLOBAL.editColor.linenumBack ) );
	
	createTabs();
	createTabs2();

	Ihandle* dndEmptylabel = IupLabel( null );
	IupSetAttribute( dndEmptylabel, "EXPAND", "YES" );
	IupSetCallback( dndEmptylabel, "DROPFILES_CB",cast(Icallback) &label_dropfiles_cb );
	IupSetCallback( dndEmptylabel, "BUTTON_CB",cast(Icallback) &emptyLabel_button_cb );
	Ihandle *dndEmptyBackGroundBox = IupBackgroundBox( dndEmptylabel ); // For colorize
	IupSetStrAttribute( dndEmptyBackGroundBox, "BGCOLOR" , toStringz( GLOBAL.editColor.dlgBack ) );
	GLOBAL.dndDocumentZBox = IupZbox( dndEmptyBackGroundBox, GLOBAL.documentTabs, null  );
	
	// RIGHT
	if( GLOBAL.editorSetting01.RotateTabs == "ON" )
		GLOBAL.documentSplit = IupSplit( GLOBAL.dndDocumentZBox, null );
	else
		GLOBAL.documentSplit = IupSplit( GLOBAL.dndDocumentZBox, GLOBAL.documentTabs_Sub );
		
	IupSetAttributes( GLOBAL.documentSplit, "ORIENTATION=VERTICAL,AUTOHIDE=YES,LAYOUTDRAG=NO,VALUE=1000,SHOWGRIP=LINES,BARSIZE=0,ACTIVE=YES" );
	if( GLOBAL.editorSetting00.ColorBarLine == "ON" )
	{
		IupSetAttributes( GLOBAL.documentSplit, "SHOWGRIP=NO" );
		IupSetStrAttribute( GLOBAL.documentSplit, "COLOR", toStringz( GLOBAL.editColor.fold ) );
	}		
	version(Posix) IupSetAttributes( GLOBAL.documentSplit, "SHOWGRIP=NO" );

	// BOTTOM
	if( GLOBAL.editorSetting01.RotateTabs == "ON" )
		GLOBAL.documentSplit2 = IupSplit( GLOBAL.documentSplit, GLOBAL.documentTabs_Sub );
	else
		GLOBAL.documentSplit2 = IupSplit( GLOBAL.documentSplit, null );
		
	IupSetAttributes( GLOBAL.documentSplit2, "ORIENTATION=HORIZONTAL,AUTOHIDE=YES,LAYOUTDRAG=NO,VALUE=1000,SHOWGRIP=LINES,BARSIZE=0,ACTIVE=YES" );
	if( GLOBAL.editorSetting00.ColorBarLine == "ON" )
	{
		IupSetAttributes( GLOBAL.documentSplit2, "SHOWGRIP=NO" );
		IupSetStrAttribute( GLOBAL.documentSplit2, "COLOR", toStringz( GLOBAL.editColor.fold ) );
	}	
	version(Posix) IupSetAttributes( GLOBAL.documentSplit2, "SHOWGRIP=NO" );
	
	GLOBAL.searchExpander = new CSearchExpander;
	GLOBAL.activeDocumentTabs = GLOBAL.documentTabs;

	
	GLOBAL.explorerSplit = IupSplit( GLOBAL.projectViewTabs, IupVbox( GLOBAL.documentSplit2, GLOBAL.searchExpander.getHandle, null ) );
	IupSetAttributes(GLOBAL.explorerSplit, "ORIENTATION=VERTICAL,AUTOHIDE=YES,LAYOUTDRAG=NO,SHOWGRIP=LINES,NAME=POSEIDON_LEFT_SPLIT");
	IupSetStrAttribute(GLOBAL.explorerSplit, "BARSIZE", toStringz( GLOBAL.editorSetting01.BarSize ) );
	if( GLOBAL.editorSetting00.ColorBarLine == "ON" )
	{
		IupSetAttributes( GLOBAL.explorerSplit, "SHOWGRIP=NO" );
		IupSetStrAttribute( GLOBAL.explorerSplit, "COLOR", toStringz( GLOBAL.editColor.fold ) );
	}
	version(Posix) IupSetAttributes( GLOBAL.explorerSplit, "SHOWGRIP=NO" );
	
	//createMessagePanel();
	GLOBAL.messagePanel = new CMessageAndSearch();
	
	//IupDestroy( test );	
	
	bool bWithoutDebug;
	
	version(DIDE)
	{
		version(Windows) bWithoutDebug = true;
	}

	if( !bWithoutDebug )
	{
		GLOBAL.debugPanel = new CDebugger();
		GLOBAL.messageWindowTabs = IupFlatTabs( GLOBAL.messagePanel.getOutputPanelHandle, GLOBAL.messagePanel.getSearchOutputPanelHandle, GLOBAL.debugPanel.getMainHandle, null );
	}
	else
	{
		GLOBAL.messageWindowTabs = IupFlatTabs( GLOBAL.messagePanel.getOutputPanelHandle, GLOBAL.messagePanel.getSearchOutputPanelHandle, null );
	}

	IupSetAttribute( GLOBAL.messageWindowTabs, "HIGHCOLOR", "0 0 255" );
	IupSetAttribute( GLOBAL.messageWindowTabs, "TABSIMAGESPACING", "3" );
	IupSetAttribute( GLOBAL.messageWindowTabs, "TABSPADDING", "6x2" );
	IupSetAttribute( GLOBAL.messageWindowTabs, "HIGHCOLOR", "255 0 0" );
	IupSetStrAttribute( GLOBAL.messageWindowTabs, "FGCOLOR", toStringz( GLOBAL.editColor.outputFore ) );
	IupSetStrAttribute( GLOBAL.messageWindowTabs, "BGCOLOR", toStringz( GLOBAL.editColor.outputBack ) );
	IupSetStrAttribute( GLOBAL.messageWindowTabs, "TABSFORECOLOR", toStringz( GLOBAL.editColor.outlineFore ) );
	IupSetStrAttribute( GLOBAL.messageWindowTabs, "TABSBACKCOLOR", toStringz( GLOBAL.editColor.outlineBack ) );
	IupSetStrAttribute( GLOBAL.messageWindowTabs, "TABSLINECOLOR", toStringz( GLOBAL.editColor.linenumBack ) );
	IupSetAttribute( GLOBAL.messageWindowTabs, "NAME", "POSEIDON_BOTTOM_TABS" );
	IupSetCallback( GLOBAL.messageWindowTabs, "FLAT_BUTTON_CB", cast(Icallback) &CStatusBar_Empty_BUTTON_CB );
	IupSetCallback( GLOBAL.messageWindowTabs, "RIGHTCLICK_CB", cast(Icallback) &messageTabRightClick_cb );
	IupSetAttribute( GLOBAL.messageWindowTabs, "TABTYPE", "TOP" );
	IupSetAttributeId( GLOBAL.messageWindowTabs, "TABVISIBLE", 2, "NO" ); // Hide the Debug window
	Ihandle* messageScrollBox = IupScrollBox( GLOBAL.messageWindowTabs );
	

	GLOBAL.messageSplit = IupSplit(GLOBAL.explorerSplit, messageScrollBox );
	IupSetAttributes(GLOBAL.messageSplit, "ORIENTATION=HORIZONTAL,AUTOHIDE=YES,SHOWGRIP=LINES,LAYOUTDRAG=NO,NAME=POSEIDON_BOTTOM_SPLIT");
	if( GLOBAL.editorSetting00.ColorBarLine == "ON" )
	{
		IupSetAttributes( GLOBAL.messageSplit, "SHOWGRIP=NO" );
		IupSetStrAttribute( GLOBAL.messageSplit, "COLOR", toStringz( GLOBAL.editColor.fold ) );
		IupSetInt( GLOBAL.messageSplit, "BARSIZE", to!(int)( GLOBAL.editorSetting01.BarSize ) );
	}	
	version(Posix) IupSetAttributes( GLOBAL.messageSplit, "SHOWGRIP=NO" );
	IupSetAttribute( GLOBAL.messageSplit, "COLOR", toStringz( GLOBAL.editColor.linenumBack ) );
	IupSetInt( GLOBAL.messageSplit, "BARSIZE", to!(int)( GLOBAL.editorSetting01.BarSize ) );
	/+
	IupSetCallback( GLOBAL.messageSplit, "VALUECHANGED_CB", cast(Icallback) function( Ihandle* _ih ){
		return IUP_DEFAULT;
	});
	+/

	GLOBAL.statusBar = new CStatusBar();
	Ihandle* expander = IupExpander( GLOBAL.toolbar.getHandle );
	IupSetAttributes( expander, "BARSIZE=0,STATE=OPEN,EXPAND=HORIZONTAL,NAME=POSEIDON_TOOLBAR_EXPANDER" );
	Ihandle* _backgroundbox = IupGetChild( expander, 0 );
	if( _backgroundbox != null ) IupSetAttribute( _backgroundbox, "VISIBLE", "NO" ); // Hide Title Image 	
	
	version(Windows)
	{
		Ihandle* VBox = IupVbox( createMenu, expander, GLOBAL.messageSplit, GLOBAL.statusBar.getLayoutHandle, null );
		IupAppend( GLOBAL.mainDlg, VBox );
	}
	else
	{
		Ihandle* VBox = IupVbox( expander, GLOBAL.messageSplit, GLOBAL.statusBar.getLayoutHandle, null );
		IupAppend( GLOBAL.mainDlg, VBox );
	}
	
	Ihandle* _scrolllabel = IupLabel( null );
	IupSetStrAttribute( _scrolllabel, "IMAGE", "icon_scroll" );
	
	GLOBAL.scrollICONHandle = IupDialog( _scrolllabel );
	IupSetAttribute( GLOBAL.scrollICONHandle, "OPACITYIMAGE", "icon_scroll" );
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
					string cursorString = fSTRz( IupGetGlobal( "CURSORPOS" ) );
					
					int		cursorX, cursorY, iconX, iconY;
					if( tools.splitBySign( cursorString, "x", cursorX, cursorY ) )
					{
						string iconString = fSTRz( IupGetAttribute( GLOBAL.scrollICONHandle, "SCREENPOSITION" ) );
						if( tools.splitBySign( iconString, ",", iconX, iconY ) )
						{
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
			}
		}
		
		return IUP_DEFAULT;
	});
}

void createEditorSetting()
{
	IDECONFIG.loadINI();
	if( GLOBAL.editorSetting00.DocStatus == "ON" ) IDECONFIG.loadFileStatus();
}

void createLayout()
{
	createExplorerWindow();
}

void createDialog()
{
	GLOBAL.compilerHelpDlg	= new CCompilerHelpDialog( 500, 400, GLOBAL.languageItems["caption_optionhelp"].toDString );
	GLOBAL.serachInFilesDlg	= new CFindInFilesDialog( -1, -1, GLOBAL.languageItems["sc_findreplacefiles"].toDString, null, false, "POSEIDON_MAIN_DIALOG" );
}


extern(C)
{
	version(Windows)
	{
		int mainDialog_COPYDATA_CB(Ihandle *ih, char* cmdLine, int size)
		{
			string[]	args;
			string[]	_args = Array.split( fSTRz( cmdLine ), "\"" );
			
			foreach( s; _args )
			{
				s = strip( s );
				if( s.length ) args ~= s;
			}
			
			if( args.length > 1 )
			{
				string argPath = args[1];
				if( std.file.exists( argPath ) )
				{
					string PRJFILE;
					version(FBIDE) PRJFILE = "FB.poseidon"; else PRJFILE = "D.poseidon";
					if( Path.baseName( argPath ) == PRJFILE )
						GLOBAL.projectTree.openProject( Path.dirName( argPath ) );				
					else
						ScintillaAction.openFile( argPath );
				}				
				
			}
			
			//IupShow( ih );
			// BOOL IsIconic( [in] HWND hWnd );  Check the window is min
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


	// While Leave poseidon.......
	int mainDialog_CLOSE_cb(Ihandle *ih)
	{
		version(Windows)
		{
			if( fSTRz( IupGetAttribute( ih, "MINIMIZED" ) ) == "YES" ) ShowWindow( IupGetAttribute( ih, "HWND" ), SW_RESTORE );
		}
		else
		{
			IupShow( ih );
		}

		if( GLOBAL.scintillaManager.length > 0 )
		{
			foreach( sc; GLOBAL.scintillaManager )
			{
				if( ScintillaAction.getModifyByTitle( sc ) )
				{
					int result = tools.MessageDlg( GLOBAL.languageItems["alarm"].toDString, GLOBAL.languageItems["sureexit"].toDString );
					if( result != 1 ) return IUP_IGNORE; else break;
				}
			}
		}
	
		try
		{
			string[] tempPrevDocs;
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
							if( activeHandle == documentHandle ) tempPrevDocs ~= ( "*" ~ cSci.getFullPath ); else tempPrevDocs ~= cSci.getFullPath;
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

			GLOBAL.parserSettings.autoCompletionTriggerWordCount = GLOBAL.statusBar.getOriginalTrigger();
			IDECONFIG.saveINI();

			foreach( parser; GLOBAL.parserManager )
			{
				if( parser !is null ) destroy( parser );
			}

			if( GLOBAL.editorSetting00.DocStatus == "ON" ) IDECONFIG.saveFileStatus();
			
			if( GLOBAL.scrollTimer != null ) IupDestroy( GLOBAL.scrollTimer );
			
			foreach( _plugin; GLOBAL.pluginMnager )
			{
				if( _plugin !is null ) destroy( _plugin );
			}
		}
		catch( Exception e )
		{
			debug IupMessage( "",toStringz( e.toString ) );
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
			GLOBAL.editorSetting01.RASTERSIZE = fSTRz( IupGetAttribute( GLOBAL.mainDlg, "RASTERSIZE" ) );
		}

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

					
					if( GLOBAL.parserSettings.enableParser == "ON" && GLOBAL.parserSettings.liveLevel > 0 && !GLOBAL.bKeyUp )
					{
						if( !AutoComplete.showCallTipThreadIsRunning && !AutoComplete.showListThreadIsRunning )
						{
							switch( c )
							{
								case 10, 13: // Eneter
									switch( GLOBAL.parserSettings.liveLevel )
									{
										case 1:
											int prevLine = ScintillaAction.getCurrentLine( cSci.getIupScintilla ) - 1;
											string prevLineText = fSTRz( IupGetAttributeId( cSci.getIupScintilla, "LINE", prevLine - 1 ) ); // 0 BASE
											//GLOBAL.messagePanel.printOutputPanel( "prevLine(" ~ Integer.toString(prevLine) ~ "): " ~ prevLineText );
											
											if( strip( prevLineText ).length )
											{
												if( strip( fromStringz( IupGetAttribute( cSci.getIupScintilla, "LINEVALUE" ) ) ).length )
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

								case 8, 9, 65535: // BACKSPACE, TAB, DEL
									switch( GLOBAL.parserSettings.liveLevel )
									{
										case 1: LiveParser.parseCurrentLine(); break;
										case 2: LiveParser.parseCurrentBlock(); break;
										default:
									}
									break;
										
								default:
									if( c > 31 && c < 127 )
									{
										switch( GLOBAL.parserSettings.liveLevel )
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
				debug IupMessage( "GlobalKeyPress_CB Error", toStringz( "GlobalKeyPress_CB()\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ to!(string)( e.line ) ) );
			}
		
			GLOBAL.bKeyUp = true; // Release
			GLOBAL.KeyNumber = -1;
		}
		else
		{
			GLOBAL.KeyNumber = c;
		}

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
				case "leftwindow":
					if( sk.keyValue == c ) 
					{
						if( IupGetInt( GLOBAL.menuOutlineWindow, "VALUE" ) == 0 )
						{
							IupSetAttribute( GLOBAL.menuOutlineWindow, "VALUE", "ON" );
							IupSetInt( GLOBAL.explorerSplit, "BARSIZE", to!(int)( GLOBAL.editorSetting01.BarSize ) );
							IupSetInt( GLOBAL.explorerSplit, "VALUE", GLOBAL.explorerSplit_value );
							IupSetInt( GLOBAL.explorerSplit, "ACTIVE", 1 );
						}
						if( IupGetInt( GLOBAL.projectViewTabs, "VALUEPOS" ) == 0 ) IupSetInt( GLOBAL.projectViewTabs, "VALUEPOS", 1 ); else IupSetInt( GLOBAL.projectViewTabs, "VALUEPOS", 0 );
						IupSetFocus( ih );
						return IUP_IGNORE;
					}
					break;
				case "bottomwindow":
					if( sk.keyValue == c ) 
					{
						if( IupGetInt( GLOBAL.menuMessageWindow, "VALUE" ) == 0 )
						{
							IupSetAttribute( GLOBAL.menuMessageWindow, "VALUE", "ON" );
							IupSetInt( GLOBAL.messageSplit, "BARSIZE", to!(int)( GLOBAL.editorSetting01.BarSize ) );
							IupSetInt( GLOBAL.messageSplit, "VALUE", GLOBAL.messageSplit_value );
							IupSetInt( GLOBAL.messageSplit, "ACTIVE", 1 );
						}
						if( IupGetInt( GLOBAL.messageWindowTabs, "VALUEPOS" ) == 0 ) IupSetInt( GLOBAL.messageWindowTabs, "VALUEPOS", 1 ); else IupSetInt( GLOBAL.messageWindowTabs, "VALUEPOS", 0 );
						IupSetFocus( ih );
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
		string _fn = fSTRz( filename );
		version(Posix) _fn = tools.modifyLinuxDropFileName( _fn );

		string prjSettingFile = _fn;
		if( isDir( _fn ) )
		{
			version(FBIDE)
				prjSettingFile = _fn ~ "/" ~ "FB.poseidon";
			else
				prjSettingFile = _fn ~ "/" ~ "D.poseidon";
		}
		
		if( std.file.exists( prjSettingFile ) )
		{
			bool bIsPrj;
			
			version(FBIDE)
			{
				if( Path.baseName( prjSettingFile ) == "FB.poseidon" ) bIsPrj = true;
			}
			else
			{
				if( Path.baseName( prjSettingFile ) == "D.poseidon" ) bIsPrj = true;
			}
				
			if( bIsPrj )
			{
				GLOBAL.projectTree.openProject( Path.dirName( prjSettingFile ) );
			}
			else
			{
				actionManager.ScintillaAction.openFile( prjSettingFile, true );
				actionManager.ScintillaAction.updateRecentFiles( prjSettingFile );
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