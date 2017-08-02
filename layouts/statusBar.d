module layouts.statusBar;

import		iup.iup;
import		global, tools, dialogs.argOptionDlg;
import		tango.stdc.stringz;

class CStatusBar
{
	private:

	import		Integer = tango.text.convert.Integer;
	
	Ihandle*	layoutHandle, prjName, LINExCOL, Ins, EOLType, EncodingType, compileOptionSelection;
	IupString	_name, _lc, _ins, _eol, _en, tipString;
	
	
	void createLayout()
	{
		prjName = IupLabel( null );
		IupSetAttribute( prjName, "SIZE", "250x" );
		LINExCOL = IupLabel( "             " );
		Ins = IupLabel( "   " );
		EOLType = IupLabel( "        " );
		EncodingType = IupLabel( "           " );
		
		Ihandle* image = IupLabel( "" );
		IupSetAttribute( image, "IMAGE", "icon_customoption" );
		IupSetAttribute( image, "TIP", GLOBAL.languageItems["setcustomoption"].toCString );
		IupSetCallback( image, "BUTTON_CB", cast(Icallback) &CStatusBar_BUTTON_CB );
		
		compileOptionSelection = IupLabel( "" );
		IupSetHandle( "compileOptionSelection", compileOptionSelection );
		IupSetAttribute( compileOptionSelection, "SIZE", "150x" );
		if( !GLOBAL.currentCustomCompilerOption.toDString.length )
		{
			IupSetAttribute( compileOptionSelection, "FGCOLOR", "255 0 0" );
			IupSetAttribute( compileOptionSelection, "TITLE", GLOBAL.noneCustomCompilerOption.toCString );
		}
		else
		{
			IupSetAttribute( compileOptionSelection, "FGCOLOR", "0 0 255" );
			IupSetAttribute( compileOptionSelection, "TITLE", GLOBAL.currentCustomCompilerOption.toCString );
			setTip( GLOBAL.currentCustomCompilerOption.toDString );
		}
	
		
		Ihandle*[5] labelSEPARATOR;
		for( int i = 0; i < 5; i++ )
		{
			labelSEPARATOR[i] = IupLabel( null ); 
			IupSetAttribute( labelSEPARATOR[i], "SEPARATOR", "VERTICAL");
		}
		
		// Ihandle* StatusBar = IupHbox( GLOBAL.statusBar_PrjName, IupFill(), labelSEPARATOR[0], GLOBAL.statusBar_Line_Col, labelSEPARATOR[1], GLOBAL.statusBar_Ins, labelSEPARATOR[2], GLOBAL.statusBar_EOLType, labelSEPARATOR[3], GLOBAL.statusBar_encodingType, null );
		layoutHandle = IupHbox( image, compileOptionSelection, labelSEPARATOR[4], prjName, IupFill(), labelSEPARATOR[0], LINExCOL, labelSEPARATOR[1], Ins, labelSEPARATOR[2], EOLType, labelSEPARATOR[3], EncodingType, null );
		IupSetAttributes( layoutHandle, "GAP=5,MARGIN=5,ALIGNMENT=ACENTER" );
		
		version(Windows)
		{
			IupSetAttribute( layoutHandle, "FONT", "Courier New,9" );
		}
		else
		{
			IupSetAttribute( layoutHandle, "FONT", "FreeMono,Bold 9" );
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
	}
	
	~this()
	{
		//delete _name, _lc, _ins, _eol, _en;
	}
	
	Ihandle* getLayoutHandle()
	{
		return layoutHandle;
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
	int CStatusBar_BUTTON_CB( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		if( pressed == 0 ) //release
		{
			if( button == '1' ) 
			{
				Ihandle* itemNULL = IupItem( GLOBAL.languageItems["none"].toCString, null );
				IupSetAttribute( itemNULL, "IMAGE", "icon_clear" );
				IupSetCallback( itemNULL, "ACTION", cast(Icallback) function( Ihandle* ih )
				{
					Ihandle* selectionHandle = IupGetHandle( "compileOptionSelection" );
					if( selectionHandle != null )
					{
						IupSetAttribute( selectionHandle, "FGCOLOR", "255 0 0" );
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
						scope dlg = new CArgOptionDialog( 492, -1, GLOBAL.languageItems["setcustomoption"].toDString(), false );
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
}