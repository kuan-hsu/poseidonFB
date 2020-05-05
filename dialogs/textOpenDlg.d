module dialogs.textOpenDlg;

import iup.iup;

import dialogs.baseDlg;

class CTextOpenDialog : CBaseDialog
{
	private:
	import		global;
	import		dialogs.fileDlg;
	
	Ihandle*	label, textResult, openButton;
	char[]		labelName;

	void createLayout( char[] textWH )
	{
		Ihandle* bottom = createDlgButton( "40x12" );

		label = IupLabel( GLOBAL.cString.convert( labelName ) );
		
		textResult = IupText( null );
		if( textWH.length ) IupSetAttribute( textResult, "SIZE", toStringz( textWH ) );
		IupSetAttribute( textResult, "EXPAND", "YES" );
		IupSetAttribute( textResult, "FONT", toStringz( GLOBAL.fonts[0].fontString.dup ) );
		IupSetHandle( "CTextOpenDialog_text", textResult );
		
		openButton = IupButton( null, null );
		IupSetAttributes( openButton, "IMAGE=icon_openfile,FLAT=YES" );

		Ihandle* hBox = IupHbox( label, textResult, openButton, null );
		IupSetAttribute( hBox, "ALIGNMENT", "ACENTER" );

		Ihandle* vBox = IupVbox( hBox, bottom, null );
		IupSetAttributes( vBox, "ALIGNMENT=ALEFT,MARGIN=5x5,GAP=2,EXPAND=YES" );

		IupSetAttribute( btnOK, "SIZE", "40x12" );
		IupSetAttribute( btnCANCEL, "SIZE", "40x12" );
		//version( Windows ) IupSetAttribute( vBox, "FONTFACE", "Courier New" ); else IupSetAttribute( vBox, "FONTFACE", "Ubuntu Mono, 10" );

		IupAppend( _dlg, vBox );
	}	

	public:
	this( int w, int h, char[] title, char[] _labelText = null, char[] textWH = null, char[] text = null, bool bResize = false, char[] parent = "POSEIDON_MAIN_DIALOG", char[] iconName = null )
	{
		super( w, h, title, bResize, parent );
		IupSetAttribute( _dlg, "MINBOX", "NO" );
		IupSetAttribute( _dlg, "ICON", toStringz( iconName.dup ) );

		labelName = _labelText ;

		createLayout( textWH );

		IupSetAttribute( textResult, "VALUE", GLOBAL.cString.convert( text ) );
		
		IupSetCallback( btnCANCEL, "ACTION", cast(Icallback) &CTextOpenDialog_btnCancel_cb );
		IupSetCallback( btnOK, "ACTION", cast(Icallback) &CTextOpenDialog_btnOK_cb );
		IupSetCallback( openButton, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			scope fileSecectDlg = new CFileDlg( null, null, "DIR" );
			char[] fileName = fileSecectDlg.getFileName();

			if( fileName.length )
			{
				Ihandle* textHandle = IupGetHandle( "CTextOpenDialog_text" );
				if( textHandle != null )
				{
					IupSetAttribute( textHandle, "VALUE", toStringz(fileName) );
					IupSetAttribute( textHandle, "SELECTIONPOS", "ALL" );
				}
			}
		});
		
		IupSetCallback( _dlg, "SHOW_CB", cast(Icallback) &CTextOpenDialog_SHOW_CB );
	}

	~this()
	{
		IupSetHandle( "textResult", null );
	}

	char[] show( int x, int y ) // Overload form CBaseDialog
	{
		IupPopup( _dlg, x, y );

		Ihandle* textHandle = IupGetHandle( "CTextOpenDialog_text" );
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
	int CTextOpenDialog_btnCancel_cb( Ihandle* ih )
	{
		Ihandle* textHandle = IupGetHandle( "CTextOpenDialog_text" );
		if( textHandle != null )
		{
			IupSetAttribute( textHandle, "VALUE", null );
		}

		return IUP_CLOSE;
	}

	int CTextOpenDialog_btnOK_cb( Ihandle* ih )
	{
		return IUP_CLOSE;
	}
	
	int CTextOpenDialog_SHOW_CB( Ihandle* ih, int state )
	{
		if( state == IUP_SHOW )
		{
			Ihandle* textHandle = IupGetHandle( "CTextOpenDialog_text" );
			if( textHandle != null ) IupSetAttribute( textHandle, "SELECTIONPOS", "ALL" );
		}
	
		return IUP_DEFAULT;
	}
}