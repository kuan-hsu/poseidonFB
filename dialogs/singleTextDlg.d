module dialogs.singleTextDlg;

import iup.iup;

import dialogs.baseDlg;

class CSingleTextDialog : CBaseDialog
{
	private:
	import		global;
	
	Ihandle*	textResult;
	char[]		labelName;

	void createLayout( char[] textWH )
	{
		Ihandle* bottom = createDlgButton();

		Ihandle* label = IupLabel( GLOBAL.cString.convert( labelName ) );
		
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

		IupAppend( _dlg, vBox );
	}	

	public:
	this( int w, int h, char[] title, char[] _labelText = null, char[] textWH = null, char[] text = null, bool bResize = false, char[] parent = "MAIN_DIALOG", char[] iconName = null )
	{
		super( w, h, title, bResize, parent );
		IupSetAttribute( _dlg, "MINBOX", "NO" );
		IupSetAttribute( _dlg, "ICON", toStringz( iconName.dup ) );
		version( Windows )
		{
			IupSetAttribute( _dlg, "FONT", GLOBAL.cString.convert( "Courier New,9" ) );
		}
		else
		{
			IupSetAttribute( _dlg, "FONT", GLOBAL.cString.convert( "FreeMono,Bold 9" ) );
		}

		labelName = _labelText ;
		 
		createLayout( textWH );

		//if( text.length) IupSetAttribute( textResult, "SELECTIONPOS", "ALL" );
		IupSetAttribute( textResult, "VALUE", GLOBAL.cString.convert( text ) );

		
		IupSetCallback( btnCANCEL, "ACTION", cast(Icallback) &CSingleTextDialog_btnCancel_cb );
		IupSetCallback( btnOK, "ACTION", cast(Icallback) &CSingleTextDialog_btnOK_cb );
	}

	~this()
	{
		IupSetHandle( "textResult", null );
		IupDestroy( _dlg );
	}

	char[] show( int x, int y ) // Overload form CBaseDialog
	{
		IupPopup( _dlg, x, y );

		Ihandle* textHandle = IupGetHandle( "CSingleTextDialog_text" );
		return fromStringz(IupGetAttribute( textHandle, "VALUE" ) ).dup;
	}	
}

extern(C) // Callback for CSingleTextDialog
{
	int CSingleTextDialog_btnCancel_cb( Ihandle* ih )
	{
		Ihandle* textHandle = IupGetHandle( "CSingleTextDialog_text" );
		if( textHandle != null )
		{
			IupSetAttribute( textHandle, "VALUE", null );
		}

		return IUP_CLOSE;
	}

	int CSingleTextDialog_btnOK_cb( Ihandle* ih )
	{
		return IUP_CLOSE;
	}
}