module layouts.statusBar;

import		iup.iup, iup.iup_scintilla;
import		global, tools, menu, actionManager;
import		dialogs.singleTextDlg, dialogs.argOptionDlg;
import		tango.stdc.stringz;

class CStatusBar
{
	private:

	import		Integer = tango.text.convert.Integer;
	
	Ihandle*	layoutHandle, prjName, LINExCOL, Ins, EOLType, EncodingType, compileOptionSelection, codecomplete;
	IupString	_name, _lc, _ins, _eol, _en, tipString;
	
	int			originalTrigger;
	
	void createLayout()
	{
		prjName = IupLabel( null );
		IupSetAttribute( prjName, "SIZE", "250x" );
		IupSetCallback( prjName, "BUTTON_CB", cast(Icallback) &CStatusBar_Empty_BUTTON_CB );

		LINExCOL = IupLabel( "             " );
		IupSetCallback( LINExCOL, "BUTTON_CB", cast(Icallback) &CStatusBar_LINExCOL_BUTTON_CB );
		
		Ins = IupLabel( "   " );
		IupSetCallback( Ins, "BUTTON_CB", cast(Icallback) &CStatusBar_Empty_BUTTON_CB );
		
		EOLType = IupLabel( "        " );
		IupSetCallback( EOLType, "BUTTON_CB", cast(Icallback) &CStatusBar_EOL_BUTTON_CB );

		EncodingType = IupLabel( "           " );
		IupSetCallback( EncodingType, "BUTTON_CB", cast(Icallback) &CStatusBar_Encode_BUTTON_CB );
		
		Ihandle* image = IupLabel( "" );
		IupSetAttribute( image, "IMAGE", "icon_customoption" );
		IupSetAttribute( image, "TIP", GLOBAL.languageItems["setcustomoption"].toCString );
		IupSetCallback( image, "BUTTON_CB", cast(Icallback) &CStatusBar_CustomOption_BUTTON_CB );
		
		compileOptionSelection = IupLabel( "" );
		IupSetHandle( "compileOptionSelection", compileOptionSelection );
		IupSetAttribute( compileOptionSelection, "SIZE", "150x" );
		if( !GLOBAL.currentCustomCompilerOption.toDString.length )
		{
			IupSetAttribute( compileOptionSelection, "FGCOLOR", "0 0 0" );
			IupSetAttribute( compileOptionSelection, "TITLE", GLOBAL.noneCustomCompilerOption.toCString );
		}
		else
		{
			IupSetAttribute( compileOptionSelection, "FGCOLOR", "0 0 255" );
			IupSetAttribute( compileOptionSelection, "TITLE", GLOBAL.currentCustomCompilerOption.toCString );
			setTip( GLOBAL.currentCustomCompilerOption.toDString );
		}
		IupSetCallback( compileOptionSelection, "BUTTON_CB", cast(Icallback) &CStatusBar_Empty_BUTTON_CB );
		
		codecomplete = IupLabel( "" );
		if( GLOBAL.autoCompletionTriggerWordCount > 0 ) IupSetAttribute( codecomplete, "IMAGE", "IUP_codecomplete_on" ); else IupSetAttribute( codecomplete, "IMAGE", "IUP_codecomplete_off" );
		IupSetAttribute( codecomplete, "NAME", "label_Codecomplete" );
		IupSetCallback( codecomplete, "BUTTON_CB", cast(Icallback) &CStatusBar_Codecomplete_BUTTON_CB );
	
		
		Ihandle*[5] labelSEPARATOR;
		for( int i = 0; i < 5; i++ )
		{
			labelSEPARATOR[i] = IupLabel( null ); 
			IupSetAttribute( labelSEPARATOR[i], "SEPARATOR", "VERTICAL");
		}
		// Ihandle* StatusBar = IupHbox( GLOBAL.statusBar_PrjName, IupFill(), labelSEPARATOR[0], GLOBAL.statusBar_Line_Col, labelSEPARATOR[1], GLOBAL.statusBar_Ins, labelSEPARATOR[2], GLOBAL.statusBar_EOLType, labelSEPARATOR[3], GLOBAL.statusBar_encodingType, null );
		Ihandle* _hbox = IupHbox( image, compileOptionSelection, labelSEPARATOR[4], prjName, IupFill(), codecomplete, labelSEPARATOR[0], LINExCOL, labelSEPARATOR[1], Ins, labelSEPARATOR[2], EOLType, labelSEPARATOR[3], EncodingType, null );
		IupSetAttributes( _hbox, "GAP=5,MARGIN=5,ALIGNMENT=ACENTER" );
		
		layoutHandle = IupBackgroundBox( _hbox );
		IupSetCallback( layoutHandle, "BUTTON_CB", cast(Icallback) &CStatusBar_Empty_BUTTON_CB );
		
		version(Windows)
		{
			IupSetAttribute( layoutHandle, "FONT", "Courier New,9" );
		}
		else
		{
			IupSetAttribute( layoutHandle, "FONT", "Ubuntu Mono, 10" );
		}			
	}
	
	
	public:
	this()
	{
		_name = new IupString();
		_lc = new IupString();
		_ins = new IupString();
		_eol = new IupString();
		_en = new IupString();
		
		tipString = new IupString();
		
		createLayout();
		setOriginalTrigger( GLOBAL.autoCompletionTriggerWordCount );
	}
	
	~this()
	{
		//delete _name, _lc, _ins, _eol, _en;
	}
	
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
		IupSetAttribute( prjName, "SIZE", toStringz( Integer.toString( width / 5 ) ~ "x" ) );
	}
	
	void setPrjName( char[] name )
	{
		_name = name;
		IupSetAttribute( prjName, "TITLE", _name.toCString );
	}
	
	void setLINExCOL( char[] lc )
	{
		_lc = lc;
		IupSetAttribute( LINExCOL, "TITLE", _lc.toCString );
	}

	void setIns( char[] ins )
	{
		_ins = ins;
		IupSetAttribute( Ins, "TITLE", _ins.toCString );
	}

	void setEOLType( char[] eol )
	{
		_eol = eol;
		IupSetAttribute( EOLType, "TITLE", _eol.toCString );
	}

	void setEncodingType( char[] en )
	{
		_en = en;
		IupSetAttribute( EncodingType, "TITLE", _en.toCString );
	}
	
	void setTip( char[] name )
	{
		tipString = cast(char[])"";
		IupSetAttribute( compileOptionSelection, "TIP", tipString.toCString );
		
		if( name.length )
		{
			foreach( char[] s; GLOBAL.customCompilerOptions )
			{
				int pos = Util.rindex( s, "%::% " );
				if( pos < s.length )
				{
					if( s[pos+5..$] == name )
					{
						tipString = s[0..pos].dup;
						IupSetAttribute( compileOptionSelection, "TIP", tipString.toCString );
						IupRefresh( compileOptionSelection );
						break;
					}
				}			
			}			
		}
	}
	
	void setCompleteIcon( bool bStatus )
	{
		if( bStatus ) IupSetAttribute( codecomplete, "IMAGE", "IUP_codecomplete_on" ); else IupSetAttribute( codecomplete, "IMAGE", "IUP_codecomplete_off" );
	}
	
	/+
	void setCompileOptionSelection( char[] os )
	{
		if( compileOptionSelection != null )
		{
			GLOBAL.currentCustomCompilerOption = os;
			IupSetAttribute( compileOptionSelection, "FGCOLOR", "0 0 255" );
			IupSetAttribute( compileOptionSelection, "TITLE", GLOBAL.currentCustomCompilerOption.toCString );
		}
	}
	+/
}

extern(C) // Callback for CBaseDialog
{
	int CStatusBar_Empty_BUTTON_CB( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		static int oriH;
		
		// On/OFF Message Window
		if( button == IUP_BUTTON1 ) // Left Click
		{
			if( pressed == 0 ) oriH = GLOBAL.fileListTree.getTreeH();
			
			char[] _s = fromStringz( status ).dup;
			if( _s.length > 5 )
			{
				if( _s[5] == 'D' ) // Double Click
				{
					menu.messageMenuItem_cb( GLOBAL.menuMessageWindow );
					return IUP_IGNORE;
				}
			}
		}
		return IUP_DEFAULT;
	}
	
	int CStatusBar_CustomOption_BUTTON_CB( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		if( CStatusBar_Empty_BUTTON_CB( ih, button, pressed, x, y, status ) == IUP_IGNORE ) return IUP_DEFAULT;
		
		if( pressed == 0 ) //release
		{
			if( button == IUP_BUTTON3 ) // Right Click
			{
				Ihandle* itemNULL = IupItem( GLOBAL.languageItems["none"].toCString, null );
				IupSetAttribute( itemNULL, "IMAGE", "icon_clear" );
				IupSetCallback( itemNULL, "ACTION", cast(Icallback) function( Ihandle* ih )
				{
					Ihandle* selectionHandle = IupGetHandle( "compileOptionSelection" );
					if( selectionHandle != null )
					{
						IupSetAttribute( selectionHandle, "FGCOLOR", "0 0 0" );
						IupSetAttribute( selectionHandle, "TITLE", GLOBAL.noneCustomCompilerOption.toCString );
						GLOBAL.currentCustomCompilerOption = cast(char[])"";
						GLOBAL.statusBar.setTip( "" );
					}
					return IUP_DEFAULT;
				});				
				
				Ihandle* itemConfig = IupItem( GLOBAL.languageItems["configuration"].toCString, null );
				IupSetAttribute( itemConfig, "IMAGE", "icon_tools" );
				IupSetCallback( itemConfig, "ACTION", cast(Icallback) function( Ihandle* ih )
				{
					int		x, y;
					char[]	mousePos = fromStringz( IupGetGlobal( "CURSORPOS" ) );
					
					int crossSign = Util.index( mousePos, "x" );
					if( crossSign < mousePos.length )
					{
						x = Integer.atoi( mousePos[0..crossSign] );
						y = Integer.atoi( mousePos[crossSign+1..$] );
					}
					else
					{
						x = IUP_MOUSEPOS;
						y = IUP_CURRENT;
					}
					
					version(Windows)
					{
						scope dlg = new CArgOptionDialog( 480, -1, GLOBAL.languageItems["setcustomoption"].toDString() );
						dlg.show( x, y - 210, -1 );
					}
					else
					{
						scope dlg = new CArgOptionDialog( 492, -1, GLOBAL.languageItems["setcustomoption"].toDString() );
						dlg.show( x, y - 210,-1 );
					}
					
					return IUP_DEFAULT;
				});
				
				

				Ihandle* popupMenu = IupMenu( 	
												IupSeparator(),
												itemNULL,
												itemConfig,
												null
											);
											
				for( int i = GLOBAL.customCompilerOptions.length - 1; i >= 0; -- i )
				{
					int pos = Util.index( GLOBAL.customCompilerOptions[i], "%::% " );
					if( pos < GLOBAL.customCompilerOptions[i].length )
					{
						char[] Name = GLOBAL.customCompilerOptions[i][pos+5..$];
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
	
	private int CStatusBar_LINExCOL_BUTTON_CB( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		if( CStatusBar_Empty_BUTTON_CB( ih, button, pressed, x, y, status ) == IUP_IGNORE ) return IUP_DEFAULT;
		
		if( pressed == 0 ) //release
		{
			if( button == IUP_BUTTON3 ) // Right Click
			{
				auto cSci = actionManager.ScintillaAction.getActiveCScintilla();
				if( cSci !is null )
				{
					char[]	mousePos = fromStringz( IupGetGlobal( "CURSORPOS" ) );
					
					int crossSign = Util.index( mousePos, "x" );
					if( crossSign < mousePos.length )
					{
						x = Integer.atoi( mousePos[0..crossSign] );
						y = Integer.atoi( mousePos[crossSign+1..$] );
					}
					else
					{
						x = IUP_MOUSEPOS;
						y = IUP_CURRENT;
					}						
					
					// Open Dialog Window
					scope gotoLineDlg = new CSingleTextDialog( -1, -1, GLOBAL.languageItems["sc_goto"].toDString() ~ "...", GLOBAL.languageItems["line"].toDString() ~ ":", null, null, false );
					IupSetAttributes( gotoLineDlg.getIhandle, "BORDER=NO,RESIZE=NO,MAXBOX=NO,MINBOX=NO,MENUBOX=NO,OPACITY=198" );
					//IupSetAttribute( gotoLineDlg.getIhandle, "BGCOLOR", "255 255 255" );
					//IupSetAttribute( gotoLineDlg.getIhandle, "BACKGROUND", "0 255 0" );
					IupSetAttribute( gotoLineDlg.getIhandle, "TITLE", null );
					
					char[] lineNum = gotoLineDlg.show( x, y - 60 );
					
					lineNum = Util.trim( lineNum );
					if( lineNum.length)
					{
						int pos = Util.rindex( lineNum, "x" );
						if( pos >= lineNum.length )	pos = Util.rindex( lineNum, ":" );
						if( pos < lineNum.length )
						{
							try
							{
								int left = Integer.atoi( Util.trim( lineNum[0..pos] ) );
								int right = Integer.atoi( Util.trim( lineNum[pos+1..$] ) );
								
								
								char[] LineCol = Integer.toString( left - 1 )  ~ "," ~ Integer.toString( right - 1 );
								IupSetAttribute( cSci.getIupScintilla, "CARET", toStringz( LineCol.dup ) );
								actionManager.StatusBarAction.update();
								IupSetFocus( cSci.getIupScintilla );
							}
							catch
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
									int value = Integer.atoi( lineNum[1..$] );
									value --;
									
									IupSetAttribute( cSci.getIupScintilla, "CARETPOS", toStringz( Integer.toString( value).dup ) );
									actionManager.StatusBarAction.update();
									IupSetFocus( cSci.getIupScintilla );
									return IUP_DEFAULT;
								}
							}
							catch
							{
								return IUP_DEFAULT;
							}
						}
						
						actionManager.ScintillaAction.gotoLine( cSci.getFullPath, Integer.atoi( lineNum ) );
						actionManager.StatusBarAction.update();
					}
				}					
			}
		}
		return IUP_DEFAULT;
	}
	
	private int CStatusBar_EOL_BUTTON_CB( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		if( CStatusBar_Empty_BUTTON_CB( ih, button, pressed, x, y, status ) == IUP_IGNORE ) return IUP_DEFAULT;
		
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
		if( CStatusBar_Empty_BUTTON_CB( ih, button, pressed, x, y, status ) == IUP_IGNORE ) return IUP_DEFAULT;
		
		if( pressed == 0 ) //release
		{
			if( button == IUP_BUTTON3 ) // Right Click
			{
				if( !Util.trim( fromStringz( IupGetAttribute( ih, "TITLE" ) ) ).length ) return IUP_DEFAULT;
				
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
				IupSetCallback( encodeUTF32BE, "ACTION", cast(Icallback) &menu.encode_cb );
				Ihandle* encodeUTF32BEBOM = IupItem( toStringz( "UTF32BE.BOM" ), null );
				IupSetCallback( encodeUTF32BEBOM, "ACTION", cast(Icallback) &menu.encode_cb );
				Ihandle* encodeUTF32LE = IupItem( toStringz( "UTF32LE" ), null );
				IupSetCallback( encodeUTF32LE, "ACTION", cast(Icallback) &menu.encode_cb );
				Ihandle* encodeUTF32LEBOM = IupItem( toStringz( "UTF32LE.BOM" ), null );
				IupSetCallback( encodeUTF32LEBOM, "ACTION", cast(Icallback) &menu.encode_cb );
				
				Ihandle* popupMenu = IupMenu( 	
												encodeDefault,
												encodeUTF8,
												encodeUTF8BOM,
												encodeUTF16BEBOM,
												encodeUTF16LEBOM,
												encodeUTF32BE,
												encodeUTF32BEBOM,
												encodeUTF32LE,
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
			GLOBAL.currentCustomCompilerOption = IupGetAttribute( ih, "TITLE" );
			IupSetAttribute( selectionHandle, "FGCOLOR", "0 0 255" );
			IupSetAttribute( selectionHandle, "TITLE", GLOBAL.currentCustomCompilerOption.toCString );
			GLOBAL.statusBar.setTip( GLOBAL.currentCustomCompilerOption.toDString );
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
				if( fromStringz( IupGetAttribute( codecompleteHandle, "IMAGE" ) ) == "IUP_codecomplete_on" )
				{
					GLOBAL.statusBar.setCompleteIcon( false );
					GLOBAL.autoCompletionTriggerWordCount = 0;
				}
				else
				{
					GLOBAL.statusBar.setCompleteIcon( true );
					GLOBAL.autoCompletionTriggerWordCount = GLOBAL.statusBar.getOriginalTrigger;
				}
				if( preferenceTriggerHandle != null ) IupSetAttribute( preferenceTriggerHandle, "VALUE", toStringz( Integer.toString( GLOBAL.autoCompletionTriggerWordCount ) ) );
			}
		}

		return IUP_DEFAULT;
	}	
}