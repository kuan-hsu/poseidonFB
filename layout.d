module layout;

import iup.iup, iup.iup_scintilla, iup.iupweb;

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
	IupSetAttributes( GLOBAL.projectViewTabs, "TABTYPE=BOTTOM,SIZE=NULL,BORDER=NO" );
	//IupSetAttribute( GLOBAL.projectViewTabs, "FONT", "Consolas, 18" );

	GLOBAL.fileListSplit = IupSplit( GLOBAL.projectViewTabs, GLOBAL.fileListTree.getLayoutHandle );
	IupSetAttributes( GLOBAL.fileListSplit, "ORIENTATION=HORIZONTAL,AUTOHIDE=NO,LAYOUTDRAG=NO,SHOWGRIP=LINES" );
	version(Windows) IupSetInt( GLOBAL.fileListSplit, "BARSIZE", 3 ); else IupSetInt( GLOBAL.fileListSplit, "BARSIZE", 2 );
	// Strange Bugs Fixed
	//IupSetCallback( IupGetChild( GLOBAL.fileListSplit, 0 ), "WHEEL_CB", cast(Icallback) function( Ihandle* ih ){ return IUP_DEFAULT; });

	createTabs();

	Ihandle* dndEmptylabel = IupLabel( null );
	IupSetAttribute( dndEmptylabel, "EXPAND", "YES" );
	IupSetCallback( dndEmptylabel, "DROPFILES_CB",cast(Icallback) &label_dropfiles_cb );
	IupSetCallback( dndEmptylabel, "BUTTON_CB",cast(Icallback) &emptyLabel_button_cb );
	GLOBAL.dndDocumentZBox = IupZbox( dndEmptylabel, GLOBAL.documentTabs, null  );

	//GLOBAL.explorerSplit = IupSplit( _split, GLOBAL.dndDocumentZBox );
	GLOBAL.explorerSplit = IupSplit( GLOBAL.fileListSplit, GLOBAL.dndDocumentZBox );
	IupSetAttributes(GLOBAL.explorerSplit, "ORIENTATION=VERTICAL,AUTOHIDE=YES,LAYOUTDRAG=NO,SHOWGRIP=LINES");
	version(Windows) IupSetInt( GLOBAL.explorerSplit, "BARSIZE", 3 ); else IupSetInt( GLOBAL.explorerSplit, "BARSIZE", 2 );
	// Strange Bugs Fixed
	//IupSetCallback( IupGetChild( GLOBAL.explorerSplit, 0 ), "WHEEL_CB", cast(Icallback) function( Ihandle* ih ){ return IUP_DEFAULT; });

	//createMessagePanel();
	GLOBAL.messagePanel = new CMessageAndSearch();

	GLOBAL.debugPanel = new CDebugger();

	version(FLATTAB)
	{
		GLOBAL.messageWindowTabs = IupFlatTabs( GLOBAL.messagePanel.getOutputPanelHandle, GLOBAL.messagePanel.getSearchOutputPanelHandle, GLOBAL.debugPanel.getMainHandle, null );
		IupSetAttribute( GLOBAL.messageWindowTabs, "HIGHCOLOR", "0 0 255" );
		IupSetAttribute( GLOBAL.messageWindowTabs, "TABSIMAGESPACING", "3" );
		IupSetAttribute( GLOBAL.messageWindowTabs, "TABSPADDING", "10x4" );
		//IupSetAttribute( GLOBAL.messageWindowTab, "SHOWCLOSE", "YES" );
		//IupSetAttribute( GLOBAL.messageWindowTabs, "CLOSEIMAGE", "icon_debug_clear" );
		//IupSetAttribute( GLOBAL.messageWindowTabs, "CLOSEIMAGEPRESS", "icon_debug_clear" );
		IupSetAttribute( GLOBAL.messageWindowTabs, "FORECOLOR", "0 0 255" );
		IupSetAttribute( GLOBAL.messageWindowTabs, "HIGHCOLOR", "255 0 0" );
		//IupSetCallback( GLOBAL.messageWindowTabs, "WHEEL_CB", cast(Icallback) function( Ihandle* ih ){ return IUP_DEFAULT; });
	}
	else
	{
		GLOBAL.messageWindowTabs = IupTabs( GLOBAL.messagePanel.getOutputPanelHandle, GLOBAL.messagePanel.getSearchOutputPanelHandle, GLOBAL.debugPanel.getMainHandle, null );
	}
	//GLOBAL.messageWindowTabs = IupTabs( GLOBAL.messagePanel.getOutputPanelHandle, GLOBAL.messagePanel.getSearchOutputPanelHandle, GLOBAL.debugPanel.getMainHandle, null );
	IupSetCallback( GLOBAL.messageWindowTabs, "RIGHTCLICK_CB", cast(Icallback) &messageTabRightClick_cb );
	version(IUPSVN)
	{
		version(Windows) IupSetCallback( GLOBAL.messageWindowTabs, "FLAT_BUTTON_CB", cast(Icallback) &CStatusBar_Empty_BUTTON_CB );
	}	

	IupSetAttribute( GLOBAL.messageWindowTabs, "TABTYPE", "TOP" );
	IupSetAttributeId( GLOBAL.messageWindowTabs, "TABVISIBLE", 2, "NO" ); // Hide the Debug window
	
	Ihandle* messageScrollBox = IupScrollBox( GLOBAL.messageWindowTabs );

	GLOBAL.messageSplit = IupSplit(GLOBAL.explorerSplit, messageScrollBox );
	IupSetAttributes(GLOBAL.messageSplit, "ORIENTATION=HORIZONTAL,AUTOHIDE=YES,LAYOUTDRAG=NO,SHOWGRIP=LINES");
	version(Windows) IupSetInt( GLOBAL.messageSplit, "BARSIZE", 2 ); else IupSetInt( GLOBAL.messageSplit, "BARSIZE", 2 );
	// Strange Bugs Fixed
	//IupSetCallback( IupGetChild( GLOBAL.messageSplit, 0 ), "WHEEL_CB", cast(Icallback) function( Ihandle* ih ){ return IUP_DEFAULT; });
	IupSetCallback( GLOBAL.messageSplit, "VALUECHANGED_CB", cast(Icallback) function( Ihandle* ih ){
		if( GLOBAL.fileListTree.getTreeH <= 6 ) IupSetInt( GLOBAL.fileListSplit, "VALUE", 1000 );		
		return IUP_IGNORE;
	});
	

	GLOBAL.statusBar = new CStatusBar();

	Ihandle* VBox = IupVbox( GLOBAL.toolbar.getHandle, GLOBAL.messageSplit, GLOBAL.statusBar.getLayoutHandle, null );
	IupAppend( GLOBAL.mainDlg, VBox );
	//IupSetAttribute( GLOBAL.documentTabs, "VISIBLE", "NO" );
	
	Ihandle* _scrolllabel = IupLabel( null );
	IupSetStrAttribute( _scrolllabel, "IMAGE", "icon_scroll" );
	
	GLOBAL.scrollICONHandle = IupDialog( _scrolllabel );
	IupSetStrAttribute( GLOBAL.scrollICONHandle, "OPACITYIMAGE", "icon_scroll" );
	IupSetAttributes( GLOBAL.scrollICONHandle, "RESIZE=NO,MAXBOX=NO,MINBOX=NO,MENUBOX=NO,BORDER=NO" );
	IupSetAttribute( GLOBAL.scrollICONHandle, "TOPMOST", "YES" );
}

void createEditorSetting()
{
	//IDECONFIG.load();
	GLOBAL.IDEMessageDlg	= new CIDEMessageDialog( 400, 600, GLOBAL.languageItems["message"].toDString );
	GLOBAL.IDEMessageDlg.show( IUP_RIGHT, 0 );
	IupHide( GLOBAL.IDEMessageDlg.getHandle );

	IDECONFIG.loadINI();
	
	GLOBAL.IDEMessageDlg.setFont( GLOBAL.fonts[7].fontString );
}

void createLayout()
{
	createExplorerWindow();
}

void createDialog()
{
	GLOBAL.compilerHelpDlg	= new CCompilerHelpDialog( 500, 400, GLOBAL.languageItems["caption_optionhelp"].toDString );
	//GLOBAL.argsDlg			= new CArgOptionDialog( -1, -1, GLOBAL.languageItems["caption_argtitle"].toDString );
	GLOBAL.searchDlg		= new CSearchDialog( -1, -1, GLOBAL.languageItems["sc_findreplace"].toDString );
	GLOBAL.serachInFilesDlg	= new CFindInFilesDialog( -1, -1, GLOBAL.languageItems["sc_findreplacefiles"].toDString );
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
					if( argPath.file == ".poseidon" )
					{
						char[] dir = argPath.path;
						if( dir.length ) dir = dir[0..length-1]; // Remove tail '/'
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
			GLOBAL.prevDoc.length = 0;
			if( GLOBAL.editorSetting00.LoadPrevDoc == "ON" )
			{
				for( int i = 0; i < IupGetInt( GLOBAL.documentTabs, "COUNT" ); ++ i )
				{
					Ihandle* documentHandle = IupGetChild( GLOBAL.documentTabs, i );
					if( documentHandle != null )
					{
						auto cSci = ScintillaAction.getCScintilla( documentHandle );
						if( cSci !is null )  GLOBAL.prevDoc ~= cSci.getFullPath;
					}
				}
			}
			
			int ret = ScintillaAction.closeAllDocument();
			if( ret == IUP_IGNORE ) return IUP_IGNORE;
			
			// Save All Project	
			foreach( PROJECT p; GLOBAL.projectManager )
			{
				p.saveFile();
			}

			//IDECONFIG.save();
			IDECONFIG.saveINI();

			foreach( parser; GLOBAL.parserManager )
			{
				if( parser !is null ) delete parser;
			}
		}
		catch(Exception e )
		{
			debug IupMessage("",toStringz(e.toString()));
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
		
		if( GLOBAL.editorSetting00.MiddleScroll == "ON" )
			if( fromStringz( IupGetAttribute( GLOBAL.scrollICONHandle, "VISIBLE" ) ) == "YES" ) IupHide( GLOBAL.scrollICONHandle );

		return IUP_DEFAULT;
	}
	
	int mainDialog_FOCUS_cb( Ihandle *ih, int focus )
	{
		if( GLOBAL.editorSetting00.MiddleScroll == "ON" )
		{
			if( focus == 0 )
				if( fromStringz( IupGetAttribute( GLOBAL.scrollICONHandle, "VISIBLE" ) ) == "YES" ) IupHide( GLOBAL.scrollICONHandle );
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
		
		// Update Filelist Size
		if( GLOBAL.fileListTree.getTreeH() <= 1 ) IupSetInt( GLOBAL.fileListSplit, "VALUE", 1000 );
		
		return IUP_DEFAULT;
	}
	
	int GlobalWHEEL_CB( Ihandle *ih, float delta, int x, int y, char *status )
	{
		if( GLOBAL.editorSetting00.MiddleScroll == "ON" )
			if( fromStringz( IupGetAttribute( GLOBAL.scrollICONHandle, "VISIBLE" ) ) == "YES" ) IupHide( GLOBAL.scrollICONHandle );
			
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
					// Auto convert keyword case......
					if( GLOBAL.keywordCase > 0 )
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
									foreach( IupString _keyword; GLOBAL.KEYWORDS )
									{
										foreach( char[] _k; Util.split( _keyword.toDString, " " ) )
										{								
											if( lowerCase( _k ) == word )
											{
												if( c == 9 || c == 32 )
												{
													currentPos++;
													//word ~= c;
												}
												//IupMessage("",toStringz( Integer.toString( ++headPos ) ~ ":" ~ Integer.toString( currentPos ) ) );
												++headPos;
												IupSetAttribute( cSci.getIupScintilla, "SELECTIONPOS", toStringz( Integer.toString( headPos ) ~ ":" ~ Integer.toString( headPos + word.length ) ) );
												word = tools.convertKeyWordCase( GLOBAL.keywordCase, word );
												IupSetAttribute( cSci.getIupScintilla, "SELECTEDTEXT", toStringz( word ) );
												IupScintillaSendMessage( cSci.getIupScintilla, 2025, currentPos , 0 ); // sci_gotopos = 2025,

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
					
					/+
					// BRACEMATCH
					if( GLOBAL.editorSetting00.BraceMatchHighlight == "ON" )
					{
						IupSetInt( cSci.getIupScintilla, "BRACEBADLIGHT", -1 );
						
						int pos = actionManager.ScintillaAction.getCurrentPos( cSci.getIupScintilla );
						int close = IupGetIntId( cSci.getIupScintilla, "BRACEMATCH", pos );
						if( close > -1 )
						{
							IupScintillaSendMessage( cSci.getIupScintilla, 2351, pos, close ); // SCI_BRACEHIGHLIGHT 2351
						}
						else
						{
							if( GLOBAL.editorSetting00.BraceMatchDoubleSidePos == "ON" )
							{
								--pos;
								close = IupGetIntId( cSci.getIupScintilla, "BRACEMATCH", pos );
								if( close > -1 )
								{
									IupScintillaSendMessage( cSci.getIupScintilla, 2351, pos, close ); // SCI_BRACEHIGHLIGHT 2351
								}
							}
						}
					}
					+/
					
					if( GLOBAL.enableParser == "ON" && GLOBAL.liveLevel > 0 && !GLOBAL.bKeyUp )
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
				/*
				if( GLOBAL.editorSetting01.USEFULLSCREEN == "ON" )
				{
					//IupMessage( "", toStringz( Integer.toString(c)));
					if( c == 65307 )
					{
						GLOBAL.editorSetting01.USEFULLSCREEN = "OFF";
						if( IupGetHandle( "Menu_fullScreenItem" ) != null ) IupSetAttribute( IupGetHandle( "Menu_fullScreenItem" ), "VALUE", "OFF" );
						IupSetAttribute( GLOBAL.mainDlg, "FULLSCREEN", "NO" );
						IupSetAttribute( GLOBAL.mainDlg, "TITLE", "poseidonFB - FreeBasic IDE" );
					}
				}
				*/
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
	
	private int emptyLabel_button_cb( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		// On/OFF Outline Window
		if( button == IUP_BUTTON1 ) // Left Click
		{
			char[] _s = fromStringz( status ).dup;
			if( _s.length > 5 )
			{
				if( _s[5] == 'D' ) // Double Click
				{
					menu.outlineMenuItem_cb( GLOBAL.menuOutlineWindow );
				}
			}
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

	/+
	private int messageWindowTabs_BUTTON_CB( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		// On/OFF Outline Window
		if( button == IUP_BUTTON1 ) // Left Click
		{
			char[] _s = fromStringz( status ).dup;
			if( _s.length > 5 )
			{
				if( _s[5] == 'D' ) // Double Click
				{
					menu.messageMenuItem_cb( GLOBAL.menuMessageWindow );
				}
			}
		}
		return IUP_DEFAULT;
	}

	version(FLATTAB)
	{
		// Close the document Iuptab......
		private int messageWindowTabs_tabClose_cb( Ihandle* ih, int pos )
		{
			if( pos < 2 )
			{
				int valuePos = IupGetInt( GLOBAL.messageWindowTabs, "VALUEPOS" );
				if( valuePos == 0 )
				{
					IupSetAttribute( GLOBAL.outputPanel, "VALUE", "" );
				}
				else if( valuePos == 1 )
				{
					IupSetAttribute( GLOBAL.searchOutputPanel , "VALUE", "" );
				}
			}
			version(FLATTAB) return IUP_IGNORE;
			
			return IUP_DEFAULT;
		}
	}
	+/
}