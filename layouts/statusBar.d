module layouts.statusBar;

import		iup.iup, iup.iup_scintilla;
import		global, tools, menu, actionManager;
import		dialogs.singleTextDlg, dialogs.argOptionDlg;
import		std.string, std.conv;

class CStatusBar
{
private:
	Ihandle*	layoutHandle, prjName, LINExCOL, Ins, EOLType, EncodingType, image, compileOptionSelection, codecomplete, findMessage;
	int			originalTrigger;
	
	void createLayout()
	{
		prjName = IupLabel( null );
		IupSetAttribute( prjName, "SIZE", "150x" );
		IupSetCallback( prjName, "BUTTON_CB", cast(Icallback) &CStatusBar_PROJECTFOCUS_CB );

		LINExCOL = IupLabel( "             " );
		IupSetCallback( LINExCOL, "BUTTON_CB", cast(Icallback) &CStatusBar_LINExCOL_BUTTON_CB );
		
		Ins = IupLabel( "   " );
		IupSetCallback( Ins, "BUTTON_CB", cast(Icallback) &CStatusBar_Empty_BUTTON_CB );
		
		EOLType = IupLabel( "        " );
		IupSetCallback( EOLType, "BUTTON_CB", cast(Icallback) &CStatusBar_EOL_BUTTON_CB );

		EncodingType = IupLabel( "           " );
		IupSetCallback( EncodingType, "BUTTON_CB", cast(Icallback) &CStatusBar_Encode_BUTTON_CB );
		
		image = IupFlatButton( "" );
		IupSetAttributes( image, "IMAGE=icon_customoption,HASFOCUS=NO,SHOWBORDER=NO,BORDERWIDTH=0,SIZE=10x8" );
		IupSetStrAttribute( image, "HLCOLOR", null  );
		IupSetStrAttribute( image, "TIP", GLOBAL.languageItems["setcustomoption"].toCString );
		IupSetCallback( image, "FLAT_BUTTON_CB", cast(Icallback) &CStatusBar_CustomOption_BUTTON_CB );
		
		compileOptionSelection = IupLabel( "" );
		IupSetHandle( "compileOptionSelection", compileOptionSelection );
		IupSetAttribute( compileOptionSelection, "SIZE", "200x" );
		if( !GLOBAL.compilerSettings.currentCustomCompilerOption.length )
		{
			IupSetStrAttribute( compileOptionSelection, "TITLE", toStringz( GLOBAL.compilerSettings.noneCustomCompilerOption ) );
		}
		else
		{
			IupSetAttribute( compileOptionSelection, "TITLE", toStringz( GLOBAL.compilerSettings.currentCustomCompilerOption ) );
			setTip( GLOBAL.compilerSettings.currentCustomCompilerOption );
		}
		IupSetCallback( compileOptionSelection, "BUTTON_CB", cast(Icallback) &CStatusBar_Empty_BUTTON_CB );
		
		codecomplete = IupFlatButton( "" );
		if( GLOBAL.autoCompletionTriggerWordCount > 0 ) IupSetAttribute( codecomplete, "IMAGE", "icon_run" ); else IupSetAttribute( codecomplete, "IMAGE", "icon_debug_stop" );
		IupSetAttributes( codecomplete, "NAME=label_Codecomplete,SHOWBORDER=NO,BORDERWIDTH=0,SIZE=10x8" );
		IupSetStrAttribute( codecomplete, "TIP", GLOBAL.languageItems["codecompletiononoff"].toCString );
		IupSetCallback( codecomplete, "FLAT_BUTTON_CB", cast(Icallback) &CStatusBar_Codecomplete_BUTTON_CB );
		
		findMessage = IupLabel( "" );
		IupSetAttribute( findMessage, "ELLIPSIS", "YES" );
		IupSetAttributes( findMessage, "EXPAND=HORIZONTAL,ALIGNMENT=ARIGHT" );
		IupSetCallback( findMessage, "BUTTON_CB", cast(Icallback) &CStatusBar_Empty_BUTTON_CB );
	
		
		Ihandle*[5] labelSEPARATOR;
		for( int i = 0; i < 5; i++ )
		{
			labelSEPARATOR[i] = IupFlatSeparator(); 
			IupSetAttributes( labelSEPARATOR[i], "STYLE=EMPTY" );
		}
		Ihandle* _hbox = IupHbox( image, compileOptionSelection, labelSEPARATOR[4], prjName, findMessage, IupFill(), codecomplete, labelSEPARATOR[0], LINExCOL, labelSEPARATOR[1], Ins, labelSEPARATOR[2], EOLType, labelSEPARATOR[3], EncodingType, null );
		IupSetAttributes( _hbox, "GAP=5,MARGIN=5,ALIGNMENT=ACENTER" );
		
		layoutHandle = IupBackgroundBox( _hbox );
		IupSetCallback( layoutHandle, "BUTTON_CB", cast(Icallback) &CStatusBar_Empty_BUTTON_CB );
		version(Windows) // linux get IupFlatSeparator wrong color
		{
			IupSetStrAttribute( layoutHandle, "BGCOLOR", toStringz( GLOBAL.editColor.dlgBack ) );
			IupSetStrAttribute( layoutHandle, "FGCOLOR", toStringz( GLOBAL.editColor.dlgFore ) );
		}
		
		version(Windows)
		{
			IupSetAttribute( layoutHandle, "FONT", "Courier New,9" );
		}
		else
		{
			IupSetAttribute( layoutHandle, "FONT", "Monospace, 10" );
		}			
	}
	
	
	public:
	this()
	{
		createLayout();
		setOriginalTrigger( GLOBAL.autoCompletionTriggerWordCount );
	}
	
	~this(){}
	
	Ihandle* getLayoutHandle()
	{
		return layoutHandle;
	}
	
	void setOriginalTrigger( int trigger )
	{
		originalTrigger = trigger;
	}
	
	int getOriginalTrigger()
	{
		return originalTrigger;
	}
	
	void setPrjNameSize( int width )
	{
		IupSetStrAttribute( prjName, "SIZE", toStringz( to!(string)( width / 5 ) ~ "x" ) );
	}
	
	void setPrjName( string name, bool bFull = false )
	{
		if( !bFull )
		{
			if( strip( name ).length == 0 ) GLOBAL.activeProjectPath = "";
			IupSetStrAttribute( prjName, "TITLE", toStringz( name ) );
		}
		else
		{
			int prjID;
			
			if( name.length )
				prjID = to!(int)( name );
			else
				prjID = actionManager.ProjectAction.getActiveProjectID();
			
			
			string _prjName = fSTRz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "TITLE", prjID ) );
			string _prjDir = fSTRz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", prjID ) );
			
			GLOBAL.activeProjectPath = _prjDir;
			
			string focusName;
			if( _prjDir in GLOBAL.projectManager ) focusName = GLOBAL.projectManager[_prjDir].focusOn;
			
			string _name = GLOBAL.languageItems["caption_prj"].toDString() ~ ": " ~ _prjName ~ ( focusName.length ? " [" ~ focusName ~ "]" : ""  );
			IupSetStrAttribute( prjName, "TITLE", toStringz( _name ) );
			if( strip( _name ).length == 0 ) GLOBAL.activeProjectPath = "";
		}
	}
	
	void setLINExCOL( string lc )
	{
		IupSetStrAttribute( LINExCOL, "TITLE", toStringz( lc ) );
	}

	void setIns( string ins )
	{
		IupSetStrAttribute( Ins, "TITLE", toStringz( ins ) );
	}

	void setEOLType( string eol )
	{
		IupSetStrAttribute( EOLType, "TITLE", toStringz( eol ) );
	}

	void setEncodingType( string en )
	{
		IupSetStrAttribute( EncodingType, "TITLE", toStringz( en ) );
	}
	
	void setTip( string name )
	{
		string tipString;
		IupSetStrAttribute( compileOptionSelection, "TIP", "" );
		
		if( name.length )
		{
			foreach( s; GLOBAL.compilerSettings.customCompilerOptions )
			{
				int bpos = lastIndexOf( s, "%::% " );
				if( bpos > 0 )
				{
					if( s[bpos+5..$] == name )
					{
						int fpos = indexOf( s, "%::% " );
						if( fpos < bpos && fpos > -1 )
						{
							tipString = ( s[0..fpos] ~ "\n" ~ s[fpos+5..bpos] ).dup; // With Compiler Path
						}
						else
						{
							tipString = s[0..bpos].dup;
						}
						IupSetStrAttribute( compileOptionSelection, "TIP", toStringz( tipString ) );
						IupRefresh( compileOptionSelection );
						break;
					}
				}			
			}			
		}
	}
	
	void setCompleteIcon( bool bStatus )
	{
		if( bStatus ) IupSetAttribute( codecomplete, "IMAGE", "icon_run" ); else IupSetAttribute( codecomplete, "IMAGE", "icon_debug_stop" );
	}
	
	void setFindMessage( string message )
	{
		IupSetAttribute( findMessage, "TITLE", "" );
		if( message.length ) IupSetStrAttribute( findMessage, "TITLE", toStringz( message ) );
	}
	
	void changeColor()
	{
		version(Windows)
		{
			IupSetStrAttribute( layoutHandle, "FGCOLOR", toStringz( GLOBAL.editColor.dlgFore ) );
			IupSetStrAttribute( layoutHandle, "BGCOLOR", toStringz( GLOBAL.editColor.dlgBack ) );
		}
		IupSetStrAttribute( image, "HLCOLOR", "" );
		
		IupSetStrAttribute( prjName, "FGCOLOR", toStringz( GLOBAL.editColor.dlgFore ) );
		IupSetStrAttribute( prjName, "BGCOLOR", toStringz( GLOBAL.editColor.dlgBack ) );
		IupSetStrAttribute( LINExCOL, "FGCOLOR", toStringz( GLOBAL.editColor.dlgFore ) );
		IupSetStrAttribute( LINExCOL, "BGCOLOR", toStringz( GLOBAL.editColor.dlgBack ) );
		IupSetStrAttribute( Ins, "FGCOLOR", toStringz( GLOBAL.editColor.dlgFore ) );
		IupSetStrAttribute( Ins, "BGCOLOR", toStringz( GLOBAL.editColor.dlgBack ) );
		IupSetStrAttribute( EOLType, "FGCOLOR", toStringz( GLOBAL.editColor.dlgFore ) );
		IupSetStrAttribute( EOLType, "BGCOLOR", toStringz( GLOBAL.editColor.dlgBack ) );	
		IupSetStrAttribute( compileOptionSelection, "FGCOLOR", toStringz( GLOBAL.editColor.dlgFore ) );
		IupSetStrAttribute( compileOptionSelection, "BGCOLOR", toStringz( GLOBAL.editColor.dlgBack ) );
		IupSetStrAttribute( findMessage, "FGCOLOR", toStringz( GLOBAL.editColor.dlgFore ) );
		IupSetStrAttribute( findMessage, "BGCOLOR", toStringz( GLOBAL.editColor.dlgBack ) );
		IupSetStrAttribute( image, "FGCOLOR", toStringz( GLOBAL.editColor.dlgFore ) );
		IupSetStrAttribute( image, "BGCOLOR", toStringz( GLOBAL.editColor.dlgBack ) );
		IupSetStrAttribute( codecomplete, "FGCOLOR", toStringz( GLOBAL.editColor.dlgFore ) );
		IupSetStrAttribute( codecomplete, "BGCOLOR", toStringz( GLOBAL.editColor.dlgBack ) );	
		IupSetStrAttribute( EncodingType, "FGCOLOR", toStringz( GLOBAL.editColor.dlgFore ) );
		IupSetStrAttribute( EncodingType, "BGCOLOR", toStringz( GLOBAL.editColor.dlgBack ) );
	}
}

extern(C) // Callback for CBaseDialog
{
	int CStatusBar_Empty_BUTTON_CB( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		static int oriH;
		
		// On/OFF Message Window
		if( button == IUP_BUTTON1 ) // Left Click
		{
			//if( pressed == 0 ) oriH = GLOBAL.fileListTree.getTreeH();
			
			if( DocumentTabAction.isDoubleClick( status ) )
			{
				menu.messageMenuItem_cb( GLOBAL.menuMessageWindow );
				return IUP_IGNORE;
			}
		}
		
		return IUP_DEFAULT;
	}
	
	int CStatusBar_CustomOption_BUTTON_CB( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		if( CStatusBar_Empty_BUTTON_CB( ih, button, pressed, x, y, status ) == IUP_IGNORE ) return IUP_IGNORE;
		
		if( pressed == 0 ) //release
		{
			if( button == IUP_BUTTON3 || button == IUP_BUTTON1 ) // Right Click
			{
				Ihandle* itemNULL = IupItem( GLOBAL.languageItems["none"].toCString, null );
				IupSetAttribute( itemNULL, "IMAGE", "icon_clear" );
				IupSetCallback( itemNULL, "ACTION", cast(Icallback) function( Ihandle* ih )
				{
					Ihandle* selectionHandle = IupGetHandle( "compileOptionSelection" );
					if( selectionHandle != null )
					{
						IupSetStrAttribute( selectionHandle, "TITLE", toStringz( GLOBAL.compilerSettings.noneCustomCompilerOption ) );
						GLOBAL.compilerSettings.currentCustomCompilerOption = "";
						GLOBAL.statusBar.setTip( "" );
					}
					return IUP_DEFAULT;
				});				
				
				Ihandle* itemConfig = IupItem( GLOBAL.languageItems["configuration"].toCString, null );
				IupSetAttribute( itemConfig, "IMAGE", "icon_tools" );
				IupSetCallback( itemConfig, "ACTION", cast(Icallback) function( Ihandle* ih )
				{
					int		x, y;
					string	mousePos = fSTRz( IupGetGlobal( "CURSORPOS" ) );
					
					int crossSign = indexOf( mousePos, "x" );
					if( crossSign > 0 )
					{
						x = to!(int)( mousePos[0..crossSign] );
						y = to!(int)( mousePos[crossSign+1..$] );
					}
					else
					{
						x = IUP_MOUSEPOS;
						y = IUP_CURRENT;
					}
					
					version(Windows)
					{
						scope dlg = new CArgOptionDialog( 480, -1, GLOBAL.languageItems["setcustomoption"].toDString() );
						dlg.show( x, y - 220, -1 );
					}
					else
					{
						scope dlg = new CArgOptionDialog( 492, -1, GLOBAL.languageItems["setcustomoption"].toDString() );
						dlg.show( x, y - 220,-1 );
					}
					
					return IUP_DEFAULT;
				});
				
				

				Ihandle* popupMenu = IupMenu( 	
												IupSeparator(),
												itemNULL,
												itemConfig,
												null
											);
											
				for( int i = GLOBAL.compilerSettings.customCompilerOptions.length - 1; i >= 0; -- i )
				{
					int pos = lastIndexOf( GLOBAL.compilerSettings.customCompilerOptions[i], "%::% " );
					if( pos > 0 )
					{
						string Name = GLOBAL.compilerSettings.customCompilerOptions[i][pos+5..$].dup;
						Ihandle* _new = IupItem( toStringz( Name ), null );
						IupSetCallback( _new, "ACTION", cast(Icallback) &customCompilerOptions_click_cb );
						IupInsert( popupMenu, null, _new );
						IupMap( _new );
					}
				}
				IupRefresh( popupMenu );
				
				
				IupPopup( popupMenu, IUP_MOUSEPOS, IUP_MOUSEPOS );
				IupDestroy( popupMenu );
			}
		}
		return IUP_DEFAULT;
	}
	
	private int CStatusBar_PROJECTFOCUS_CB( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		if( CStatusBar_Empty_BUTTON_CB( ih, button, pressed, x, y, status ) == IUP_IGNORE ) return IUP_IGNORE;
		
		if( pressed == 0 ) //release
		{
			if( button == IUP_BUTTON3 ) // Right Click
			{
				string activePrjDir = ProjectAction.getActiveProjectName();
				if( activePrjDir.length )
				{
					if( activePrjDir in GLOBAL.projectManager )
					{
						if( GLOBAL.projectManager[activePrjDir].focusUnit.length )
						{
							Ihandle* popupMenu = IupMenu( null );
							
							Ihandle* _emptyItem = IupItem( toStringz( "<null>" ), null );
							IupSetCallback( _emptyItem, "ACTION", cast(Icallback ) &CStatusBar_PROJECTFOCUS_popupMenu_Action );
							IupAppend( popupMenu, _emptyItem );
							if( !GLOBAL.projectManager[activePrjDir].focusOn.length ) IupSetAttribute( _emptyItem, "VALUE", "ON" );
							
							
							Ihandle*[100] _item;
							foreach( int i, key; GLOBAL.projectManager[activePrjDir].focusUnit.keys )
							{
								_item[i] = IupItem( toStringz( key ), null );
								IupSetCallback( _item[i], "ACTION", cast(Icallback ) &CStatusBar_PROJECTFOCUS_popupMenu_Action );
								IupAppend( popupMenu, _item[i] );
								if( key == GLOBAL.projectManager[activePrjDir].focusOn ) IupSetAttribute( _item[i], "VALUE", "ON" );
							}
							
							IupPopup( popupMenu, IUP_MOUSEPOS, IUP_MOUSEPOS );
							IupDestroy( popupMenu );								
						}
					}
				}
			}
		}
		return IUP_DEFAULT;
	}
	
	private int CStatusBar_PROJECTFOCUS_popupMenu_Action( Ihandle* ih )
	{
		string focusTitle = fSTRz( IupGetAttribute( ih, "TITLE" ) );
		string activePrjDir = ProjectAction.getActiveProjectName();
		
		if( focusTitle != "<null>" )
		{
			if( focusTitle in GLOBAL.projectManager[activePrjDir].focusUnit ) GLOBAL.projectManager[activePrjDir].focusOn = focusTitle;	else GLOBAL.projectManager[activePrjDir].focusOn = "";
		}
		else
		{
			if( activePrjDir in GLOBAL.projectManager ) GLOBAL.projectManager[activePrjDir].focusOn = "";
		}
		
		IupSetAttribute( ih, "VALUE", "ON" );
		GLOBAL.statusBar.setPrjName( "", true );
		
		return IUP_DEFAULT;
	}
	
	private int CStatusBar_LINExCOL_BUTTON_CB( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		if( CStatusBar_Empty_BUTTON_CB( ih, button, pressed, x, y, status ) == IUP_IGNORE ) return IUP_IGNORE;
		
		if( pressed == 0 ) //release
		{
			if( button == IUP_BUTTON3 ) // Right Click
			{
				auto cSci = actionManager.ScintillaAction.getActiveCScintilla();
				if( cSci !is null )
				{
					string mousePos = fSTRz( IupGetGlobal( "CURSORPOS" ) );
					
					int crossSign = indexOf( mousePos, "x" );
					if( crossSign > 0 )
					{
						x = to!(int)( mousePos[0..crossSign] );
						y = to!(int)( mousePos[crossSign+1..$] );
					}
					else
					{
						x = IUP_MOUSEPOS;
						y = IUP_CURRENT;
					}						
					
					// Open Dialog Window
					scope gotoLineDlg = new CSingleTextDialog( -1, -1, GLOBAL.languageItems["sc_goto"].toDString() ~ "...", GLOBAL.languageItems["line"].toDString() ~ ":", null, null, false, "POSEIDON_MAIN_DIALOG", null, false );
					IupSetAttributes( gotoLineDlg.getIhandle, "BORDER=NO,RESIZE=NO,MAXBOX=NO,MINBOX=NO,MENUBOX=NO,OPACITY=198" );
					IupSetAttribute( gotoLineDlg.getIhandle, "TITLE", "" );
					
					string lineNum = gotoLineDlg.show( x, y - 60 );
					
					lineNum = strip( lineNum );
					if( lineNum.length)
					{
						int pos = lastIndexOf( lineNum, "x" );
						if( pos == -1 )	pos = lastIndexOf( lineNum, ":" );
						if( pos > 0 )
						{
							try
							{
								int left = to!(int)( strip( lineNum[0..pos].dup ) );
								int right = to!(int)( strip( lineNum[pos+1..$].dup ) );
								
								
								string LineCol = to!(string)( left - 1 )  ~ "," ~ to!(string)( right - 1 );
								IupSetStrAttribute( cSci.getIupScintilla, "CARET", toStringz( LineCol ) );
								actionManager.StatusBarAction.update();
								IupSetFocus( cSci.getIupScintilla );
							}
							catch( Exception e )
							{
							}
							return IUP_DEFAULT;
						}
						else
						{
							try
							{
								if( lineNum[0] == '-' )
								{
									int value = to!(int)( lineNum[1..$].dup );
									value --;
									
									IupSetInt( cSci.getIupScintilla, "CARETPOS", value );
									actionManager.StatusBarAction.update();
									IupSetFocus( cSci.getIupScintilla );
									return IUP_DEFAULT;
								}
							}
							catch( Exception e )
							{
								return IUP_DEFAULT;
							}
						}
						
						actionManager.ScintillaAction.gotoLine( cSci.getFullPath, to!(int)( lineNum ) );
						actionManager.StatusBarAction.update();
					}
				}					
			}
		}
		return IUP_DEFAULT;
	}
	
	private int CStatusBar_EOL_BUTTON_CB( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		if( CStatusBar_Empty_BUTTON_CB( ih, button, pressed, x, y, status ) == IUP_IGNORE ) return IUP_IGNORE;
		
		if( pressed == 0 ) //release
		{
			if( button == IUP_BUTTON3 ) // Right Click
			{
				//if( IupGetInt( GLOBAL.documentTabs, "COUNT" ) == 0 ) return IUP_DEFAULT;
				Ihandle* _windowsEOL = IupItem( toStringz( "Windows" ), null );
				IupSetCallback( _windowsEOL, "ACTION", cast(Icallback) function( Ihandle* ih )
				{
					GLOBAL.editorSetting00.EolType = "0";
					foreach( cSci; GLOBAL.scintillaManager )
						if( cSci !is null )	IupScintillaSendMessage( cSci.getIupScintilla, 2031, 0, 0 ); // SCI_SETEOLMODE	= 2031

					StatusBarAction.update();
					return IUP_DEFAULT;
				});	
				
				Ihandle* _macEOL = IupItem( toStringz( "Mac" ), null );
				IupSetCallback( _macEOL, "ACTION", cast(Icallback) function( Ihandle* ih )
				{
					GLOBAL.editorSetting00.EolType = "1";
					foreach( cSci; GLOBAL.scintillaManager )
						if( cSci !is null )	IupScintillaSendMessage( cSci.getIupScintilla, 2031, 1, 0 ); // SCI_SETEOLMODE	= 2031
					
					StatusBarAction.update();
					return IUP_DEFAULT;
				});	
				
				Ihandle* _unixEOL = IupItem( toStringz( "Unix" ), null );
				IupSetCallback( _unixEOL, "ACTION", cast(Icallback) function( Ihandle* ih )
				{
					GLOBAL.editorSetting00.EolType = "2";
					foreach( cSci; GLOBAL.scintillaManager )
					
						if( cSci !is null )	IupScintillaSendMessage( cSci.getIupScintilla, 2031, 2, 0 ); // SCI_SETEOLMODE	= 2031

					StatusBarAction.update();
					return IUP_DEFAULT;
				});
				
				Ihandle* popupMenu = IupMenu( 	
												_windowsEOL,
												_macEOL,
												_unixEOL,
												null
											);
											
				IupSetAttribute( popupMenu, "RADIO", "YES" );
				switch( GLOBAL.editorSetting00.EolType )
				{
					case "0":	IupSetAttribute( _windowsEOL, "VALUE", "ON"); break;
					case "1":	IupSetAttribute( _macEOL, "VALUE", "ON"); break;
					case "2":	IupSetAttribute( _unixEOL, "VALUE", "ON"); break;
					default:
				}				
				
				IupPopup( popupMenu, IUP_MOUSEPOS, IUP_MOUSEPOS );
				IupDestroy( popupMenu );				
			}
		}
		return IUP_DEFAULT;
	}
	
	private int CStatusBar_Encode_BUTTON_CB( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		if( CStatusBar_Empty_BUTTON_CB( ih, button, pressed, x, y, status ) == IUP_IGNORE ) return IUP_IGNORE;
		
		if( pressed == 0 ) //release
		{
			if( button == IUP_BUTTON3 ) // Right Click
			{
				if( !strip( fromStringz( IupGetAttribute( ih, "TITLE" ) ) ).length ) return IUP_DEFAULT;
				
				Ihandle* encodeDefault = IupItem( toStringz( "Default" ), null );
				IupSetCallback( encodeDefault, "ACTION", cast(Icallback) &menu.encode_cb );
				Ihandle* encodeUTF8 = IupItem( toStringz( "UTF8" ), null );
				IupSetCallback( encodeUTF8, "ACTION", cast(Icallback) &menu.encode_cb );
				Ihandle* encodeUTF8BOM = IupItem( toStringz( "UTF8.BOM" ), null );
				IupSetCallback( encodeUTF8BOM, "ACTION", cast(Icallback) &menu.encode_cb );
				Ihandle* encodeUTF16BEBOM = IupItem( toStringz( "UTF16BE.BOM" ), null );
				IupSetCallback( encodeUTF16BEBOM, "ACTION", cast(Icallback) &menu.encode_cb );
				Ihandle* encodeUTF16LEBOM = IupItem( toStringz( "UTF16LE.BOM" ), null );
				IupSetCallback( encodeUTF16LEBOM, "ACTION", cast(Icallback) &menu.encode_cb );
				Ihandle* encodeUTF32BE = IupItem( toStringz( "UTF32BE" ), null );
				IupSetInt( encodeUTF32BE, "ACTIVE", 0 );
				IupSetCallback( encodeUTF32BE, "ACTION", cast(Icallback) &menu.encode_cb );
				Ihandle* encodeUTF32BEBOM = IupItem( toStringz( "UTF32BE.BOM" ), null );
				IupSetCallback( encodeUTF32BEBOM, "ACTION", cast(Icallback) &menu.encode_cb );
				Ihandle* encodeUTF32LE = IupItem( toStringz( "UTF32LE" ), null );
				IupSetInt( encodeUTF32LE, "ACTIVE", 0 );
				IupSetCallback( encodeUTF32LE, "ACTION", cast(Icallback) &menu.encode_cb );
				Ihandle* encodeUTF32LEBOM = IupItem( toStringz( "UTF32LE.BOM" ), null );
				IupSetCallback( encodeUTF32LEBOM, "ACTION", cast(Icallback) &menu.encode_cb );
				
				Ihandle* popupMenu = IupMenu( 	
												encodeDefault,
												encodeUTF8,
												encodeUTF8BOM,
												encodeUTF16BEBOM,
												encodeUTF16LEBOM,
												//encodeUTF32BE,
												encodeUTF32BEBOM,
												//encodeUTF32LE,
												encodeUTF32LEBOM,
												null
											);

				
				
				IupPopup( popupMenu, IUP_MOUSEPOS, IUP_MOUSEPOS );
				IupDestroy( popupMenu );
			}
		}
		return IUP_DEFAULT;
	}
	
	private int customCompilerOptions_click_cb( Ihandle* ih )
	{
		Ihandle* selectionHandle = IupGetHandle( "compileOptionSelection" );
		if( selectionHandle != null )
		{
			GLOBAL.compilerSettings.currentCustomCompilerOption = fSTRz( IupGetAttribute( ih, "TITLE" ) );
			IupSetStrAttribute( selectionHandle, "TITLE", toStringz( GLOBAL.compilerSettings.currentCustomCompilerOption ) );
			GLOBAL.statusBar.setTip( GLOBAL.compilerSettings.currentCustomCompilerOption );
		}

		return IUP_DEFAULT;
	}
	
	private int CStatusBar_Codecomplete_BUTTON_CB( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		if( pressed == 0 ) //release
		{
			Ihandle* codecompleteHandle = IupGetDialogChild( GLOBAL.statusBar.layoutHandle, "label_Codecomplete" );
			if( codecompleteHandle != null )
			{
				Ihandle* preferenceTriggerHandle = IupGetHandle( "textTrigger" );
				if( fromStringz( IupGetAttribute( codecompleteHandle, "IMAGE" ) ) == "icon_run" )
				{
					GLOBAL.statusBar.setCompleteIcon( false );
					GLOBAL.autoCompletionTriggerWordCount = 0;
				}
				else
				{
					GLOBAL.statusBar.setCompleteIcon( true );
					GLOBAL.autoCompletionTriggerWordCount = GLOBAL.statusBar.getOriginalTrigger;
				}
				if( preferenceTriggerHandle != null ) IupSetStrAttribute( preferenceTriggerHandle, "VALUE", toStringz( to!(string)( GLOBAL.autoCompletionTriggerWordCount ) ) );
			}
		}

		return IUP_DEFAULT;
	}
}