module dialogs.singleTextDlg;

import iup.iup;

import dialogs.baseDlg;

import tango.stdc.stringz;

class CSingleTextDialog : CBaseDialog
{
	private:
	Ihandle*	textResult;
	char[]		labelName;

	void createLayout()
	{
		Ihandle* bottom = createDlgButton();

		Ihandle* label = IupLabel( toStringz(labelName) );
		
		textResult = IupText( null );
		IupSetAttribute( textResult, "SIZE", "100x12" );
		IupSetHandle( "CSingleTextDialog_text", textResult );

		Ihandle* hBox = IupHbox( label, textResult, null );
		IupSetAttribute( hBox, "ALIGNMENT", "ACENTER" );

		Ihandle* vBox = IupVbox( hBox, bottom, null );
		IupSetAttributes( vBox, "ALIGNMENT=ALEFT,MARGIN=5x5,GAP=2,EXPAND=YES" );

		IupAppend( _dlg, vBox );
	}	

	public:
	this( int w, int h, char[] title, char[] _labelText = null, char[] text = null, bool bResize = false, char[] parent = "MAIN_DIALOG" )
	{
		super( w, h, title, bResize, parent );
		IupSetAttribute( _dlg, "MINBOX", "NO" );
		version( Windows )
		{
			IupSetAttribute( _dlg, "FONT", "Courier New,9" );
		}
		else
		{
			IupSetAttribute( _dlg, "FONT", "Monospace,9" );
		}

		labelName = _labelText ;
		 
		createLayout();

		IupSetAttribute( textResult, "VALUE", toStringz(text) );
		/+
		IupSetAttribute( textResult, "CARET ", "1"  );
		IupSetAttribute( textResult, "SELECTIONPOS ",  "0:2"  );
		+/

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
		return fromStringz(IupGetAttribute( textHandle, "VALUE" ) );
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