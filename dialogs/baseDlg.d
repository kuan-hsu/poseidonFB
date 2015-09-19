module dialogs.baseDlg;

import iup.iup;

class CBaseDialog
{
	protected:
	import global, project, scintilla, actionManager;

	import tango.stdc.stringz, Integer = tango.text.convert.Integer;
	
	Ihandle*	_dlg;
	Ihandle*	btnOK, btnCANCEL;//, btnAPPLY;


	Ihandle* createDlgButton()
	{
		btnOK = IupButton( "OK", null );
		IupSetHandle( "btnOK", btnOK );
		IupSetAttributes( btnOK, "SIZE=40x20");//,IMAGE=IUP_ActionOk" );
		
		btnCANCEL = IupButton( "Cancel", null );
		IupSetHandle( "btnCANCEL", btnCANCEL );
		IupSetAttributes( btnCANCEL, "SIZE=40x20" );// ,IMAGE=IUP_ActionCancel
		IupSetCallback( btnCANCEL, "ACTION", cast(Icallback) &CBaseDialog_btnCancel_cb );
		
		/+
		Ihandle* btnAPPLY = IupButton( "Apply", null );
		IupSetAttribute( btnAPPLY, "SIZE", "40x20" );
		IupSetAttribute( btnAPPLY, "IMAGE", "IUP_NavigateRefresh" );
		+/
		
		Ihandle* hBox_DlgButton = IupHbox( IupFill(), btnOK, btnCANCEL, null );
		IupSetAttributes( hBox_DlgButton, "ALIGNMENT=ABOTTOM,GAP=5,MARGIN=1x0" );

		IupSetAttribute( _dlg, "DEFAULTENTER", "btnOK" );
		IupSetAttribute( _dlg, "DEFAULTESC", "btnCANCEL" );


		return hBox_DlgButton;
	}
	

	public:
	this( int w, int h, char[] title, bool bResize = true, char[] parent = null )
	{
		_dlg = IupDialog( null );
		IupSetAttribute( _dlg, "TITLE", title.ptr );
		IupSetAttribute( _dlg, "RASTERSIZE", (Integer.toString( w ) ~ "x" ~ Integer.toString( h )).ptr );
		if( parent.length)
		{
			IupSetAttribute( _dlg, "PARENTDIALOG", toStringz( parent, GLOBAL.stringzTemp ) );
			delete GLOBAL.stringzTemp;
		}
		if( !bResize ) IupSetAttribute( _dlg, "RESIZE", "NO" );
	}

	~this()
	{
		IupSetHandle( "btnCANCEL", null );
		IupSetHandle( "btnOK", null );
		IupDestroy( _dlg );
	}

	char[] show( int x, int y )
	{
		IupPopup( _dlg, x, y );
		return null;
	}
	
	Ihandle* getIhandle()
	{
		return _dlg;
	}
}

extern(C) // Callback for CBaseDialog
{
	int CBaseDialog_btnCancel_cb()
	{
		return IUP_CLOSE;
	}
}