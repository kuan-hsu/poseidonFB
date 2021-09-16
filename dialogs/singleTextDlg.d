module dialogs.singleTextDlg;

import iup.iup;

import dialogs.baseDlg;

class CSingleTextDialog : CBaseDialog
{
	private:
	import		global;
	
	Ihandle*	label, textResult;
	char[]		labelName;

	void createLayout( char[] textWH )
	{
		Ihandle* bottom = createDlgButton( "40x12" );

		label = IupLabel( GLOBAL.cString.convert( labelName ) );
		
		textResult = IupText( null );
		if( textWH.length ) IupSetAttribute( textResult, "SIZE", toStringz( textWH ) );
		//IupSetAttribute( textResult, "SIZE", "100x12" );
		IupSetAttribute( textResult, "EXPAND", "YES" );
		IupSetAttribute( textResult, "FONT", toStringz( GLOBAL.fonts[0].fontString.dup ) );
		IupSetHandle( "CSingleTextDialog_text", textResult );

		Ihandle* hBox = IupHbox( label, textResult, null );
		IupSetAttribute( hBox, "ALIGNMENT", "ACENTER" );

		Ihandle* vBox = IupVbox( hBox, bottom, null );
		IupSetAttributes( vBox, "ALIGNMENT=ALEFT,MARGIN=5x5,GAP=2,EXPAND=YES" );

		IupSetAttribute( btnOK, "SIZE", "40x12" );
		IupSetAttribute( btnCANCEL, "SIZE", "40x12" );
		//version( Windows ) IupSetAttribute( vBox, "FONTFACE", "Courier New" ); else IupSetAttribute( vBox, "FONTFACE", "Ubuntu Mono, 10" );

		IupAppend( _dlg, vBox );
	}	

	public:
	this( int w, int h, char[] title, char[] _labelText = null, char[] textWH = null, char[] text = null, bool bResize = false, char[] parent = "POSEIDON_MAIN_DIALOG", char[] iconName = null, bool bMap = true )
	{
		super( w, h, title, bResize, parent );
		IupSetAttribute( _dlg, "MINBOX", "NO" );
		IupSetAttribute( _dlg, "ICON", toStringz( iconName.dup ) );

		labelName = _labelText ;

		createLayout( textWH );

		if( bMap ) IupMap( _dlg );
		
		IupSetAttribute( textResult, "VALUE", GLOBAL.cString.convert( text ) );
		if( text.length) IupSetAttribute( textResult, "SELECTION", "ALL" );
		
		
		IupSetCallback( btnCANCEL, "ACTION", cast(Icallback) &CSingleTextDialog_btnCancel_cb );
		IupSetCallback( btnOK, "ACTION", cast(Icallback) &CSingleTextDialog_btnOK_cb );
	}

	~this()
	{
		IupSetHandle( "textResult", null );
	}

	char[] show( int x, int y ) // Overload form CBaseDialog
	{
		IupPopup( _dlg, x, y );

		Ihandle* textHandle = IupGetHandle( "CSingleTextDialog_text" );
		return fromStringz(IupGetAttribute( textHandle, "VALUE" ) ).dup;
	}
	
	Ihandle* getTextHandle()
	{
		return textResult;
	}
	
	Ihandle* getLabelHandle()
	{
		return label;
	}	
}

extern(C) // Callback for CSingleTextDialog
{
	private int CSingleTextDialog_btnCancel_cb( Ihandle* ih )
	{
		Ihandle* textHandle = IupGetHandle( "CSingleTextDialog_text" );
		if( textHandle != null )
		{
			IupSetAttribute( textHandle, "VALUE", null );
		}

		return IUP_CLOSE;
	}

	private int CSingleTextDialog_btnOK_cb( Ihandle* ih )
	{
		return IUP_CLOSE;
	}
}



class CSingleTextInput
{
	private:
	import		global;
	import		tango.stdc.stringz, Integer = tango.text.convert.Integer;
	
	Ihandle*	inputText, inputDlg;

	public:
	this( int w, int h, char[] text = null, char[] color = "255 255 255", int opacity = 198, bool border = true )
	{
		inputText = IupText( null );
		IupSetAttributes( inputText, toStringz( "SIZE=" ~ Integer.toString( w ) ~ "x" ~ Integer.toString( h ) ) );
		IupSetAttribute( inputText, "BGCOLOR", toStringz( color) );
		IupSetCallback( inputText, "K_ANY", cast(Icallback) &CSingleTextInput_K_ANY );
		
		inputDlg = IupDialog( inputText );
		IupSetAttributes( inputDlg, "RESIZE=NO,MAXBOX=NO,MINBOX=NO,MENUBOX=NO" );
		IupSetAttribute( inputDlg, "TITLE", null );
		IupSetInt( inputDlg, "BORDER", border );
		IupSetInt( inputDlg, "OPACITY", opacity );

		IupMap( inputDlg );
		
		IupSetAttribute( inputText, "VALUE", toStringz( text ) );
		IupSetAttribute( inputText, "SELECTION", "ALL" );
		
		IupSetHandle( "CSingleTextInput_dlg", inputDlg );
		//IupSetFocus( inputText );
	}

	~this()
	{
		IupSetHandle( "CSingleTextInput_dlg", null );
	}

	char[] show( int x, int y )
	{
		IupPopup( inputDlg, x, y );
		
		if( IupGetInt( inputDlg, "ACTIVE" ) == 0 ) return null;
		
		return fromStringz( IupGetAttribute( inputText, "VALUE" ) ).dup;
	}
}

extern(C) // Callback for CSingleTextDialogWithoutButton
{
	private int CSingleTextInput_K_ANY( Ihandle* ih, int c )
	{
		Ihandle* dlgHandle = IupGetHandle( "CSingleTextInput_dlg" );
		if( dlgHandle != null )
		{
			if( c == 13 ) return IUP_CLOSE;
			if( c == 65307 )
			{
				IupSetInt( dlgHandle, "ACTIVE", 0 );
				return IUP_CLOSE;
			}
		}

		return IUP_DEFAULT;
	}
}


class CSingleTextOpen : CBaseDialog
{
	private:
	import		global;
	import		dialogs.fileDlg;
	
	Ihandle*	labelORframe, hBox, vBox, textResult, openButton;
	IupString	labelName;

	void createLayout( char[] textWH, bool bFrame )
	{
		Ihandle* bottom = createDlgButton( "40x12" );

		textResult = IupText( null );
		if( textWH.length ) IupSetAttribute( textResult, "SIZE", toStringz( textWH ) );
		IupSetAttribute( textResult, "EXPAND", "YES" );
		IupSetAttribute( textResult, "FONT", toStringz( GLOBAL.fonts[0].fontString.dup ) );
		IupSetHandle( "CSingleTextOpen_text", textResult );
		
		openButton = IupButton( null, null );
		IupSetAttributes( openButton, "IMAGE=icon_openfile,FLAT=YES,CANFOCUS=NO" );

		if( !bFrame )
		{
			labelORframe = IupLabel( labelName.toCString );
			hBox = IupHbox( labelORframe, textResult, openButton, null );
			vBox = IupVbox( hBox, bottom, null );
		}
		else
		{
			hBox = IupHbox( textResult, openButton, null );
			labelORframe = IupFrame( hBox );
			IupSetAttribute( labelORframe, "TITLE", labelName.toCString );
			vBox = IupVbox( labelORframe, bottom, null );
		}

		IupSetAttribute( hBox, "ALIGNMENT", "ACENTER" );
		IupSetAttributes( vBox, "ALIGNMENT=ALEFT,MARGIN=5x5,GAP=2,EXPAND=YES" );
		IupSetAttribute( btnOK, "SIZE", "40x12" );
		IupSetAttribute( btnCANCEL, "SIZE", "40x12" );

		IupAppend( _dlg, vBox );
	}	

	public:
	this( int w, int h, char[] title, char[] _labelText = null, char[] textWH = null, char[] text = null, bool bResize = false, char[] parent = "POSEIDON_MAIN_DIALOG", char[] iconName = null, bool bFrame = true )
	{
		super( w, h, title, bResize, parent );
		IupSetAttribute( _dlg, "MINBOX", "NO" );
		IupSetAttribute( _dlg, "ICON", toStringz( iconName.dup ) );

		labelName = new IupString( _labelText );

		createLayout( textWH, bFrame );
		
		IupMap( _dlg );

		IupSetStrAttribute( textResult, "VALUE", toStringz( text ) );
		IupSetAttribute( textResult, "SELECTION", "ALL" );
		
		IupSetCallback( btnCANCEL, "ACTION", cast(Icallback) &CSingleTextOpen_btnCancel_cb );
		IupSetCallback( btnOK, "ACTION", cast(Icallback) &CSingleTextOpen_btnOK_cb );
		IupSetCallback( openButton, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			Ihandle* textHandle = IupGetHandle( "CSingleTextOpen_text" );
			if( textHandle != null )
			{
				scope fileSelectDlg = new CFileDlg( null, null, "DIR", null, fromStringz( IupGetAttribute( textHandle, "VALUE" ) ) );
				char[] fileName = fileSelectDlg.getFileName();

				if( fileName.length )
				{
					IupSetAttribute( textHandle, "VALUE", toStringz(fileName) );
					IupSetAttribute( textHandle, "SELECTIONPOS", "ALL" );
				}
			}
		});
	}

	~this()
	{
		IupSetHandle( "textResult", null );
	}

	char[] show( int x, int y ) // Overload form CBaseDialog
	{
		IupPopup( _dlg, x, y );

		Ihandle* textHandle = IupGetHandle( "CSingleTextOpen_text" );
		return fromStringz(IupGetAttribute( textHandle, "VALUE" ) ).dup;
	}
	
	Ihandle* getTextHandle()
	{
		return textResult;
	}
	
	Ihandle* getLabelHandle()
	{
		return labelORframe;
	}	
}

extern(C) // Callback for CSingleTextOpen
{
	private int CSingleTextOpen_btnCancel_cb( Ihandle* ih )
	{
		Ihandle* textHandle = IupGetHandle( "CSingleTextOpen_text" );
		if( textHandle != null )
		{
			IupSetAttribute( textHandle, "VALUE", null );
		}

		return IUP_CLOSE;
	}

	private int CSingleTextOpen_btnOK_cb( Ihandle* ih )
	{
		return IUP_CLOSE;
	}
}