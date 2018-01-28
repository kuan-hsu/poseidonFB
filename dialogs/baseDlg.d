module dialogs.baseDlg;

import iup.iup;

class CBaseDialog
{
	protected:
	import global, project, scintilla, actionManager, tools;

	import tango.stdc.stringz, Integer = tango.text.convert.Integer;
	
	Ihandle*			_dlg;
	Ihandle*			btnAPPLY, btnOK, btnCANCEL;
	IupString			titleString, parentName;
	
	Ihandle* createDlgButton( char[] buttonSize = "40x20", char[] buttons = "oc" )
	{
		btnAPPLY = IupButton( GLOBAL.languageItems["apply"].toCString, null );
		IupSetHandle( "btnAPPLY", btnAPPLY );
		IupSetAttributes( btnAPPLY, toStringz( "SIZE=" ~ buttonSize ) );
		
		btnOK = IupButton( GLOBAL.languageItems["ok"].toCString, null );
		IupSetHandle( "btnOK", btnOK );
		IupSetAttributes( btnOK, toStringz( "SIZE=" ~ buttonSize ) );
		
		btnCANCEL = IupButton( GLOBAL.languageItems["cancel"].toCString, null );
		IupSetHandle( "btnCANCEL", btnCANCEL );
		IupSetAttributes( btnCANCEL, toStringz( "SIZE=" ~ buttonSize ) );
		IupSetCallback( btnCANCEL, "ACTION", cast(Icallback) &CBaseDialog_btnCancel_cb );
		
		/+
		Ihandle* btnAPPLY = IupButton( "Apply", null );
		IupSetAttribute( btnAPPLY, "SIZE", "40x20" );
		IupSetAttribute( btnAPPLY, "IMAGE", "IUP_NavigateRefresh" );
		+/
		
		Ihandle* hBox_DlgButton = IupHbox( IupFill(), btnAPPLY, btnOK, btnCANCEL, null );
		IupSetAttributes( hBox_DlgButton, "ALIGNMENT=ABOTTOM,GAP=5,MARGIN=1x0" );

		IupSetAttribute( _dlg, "DEFAULTENTER", "btnOK" );
		IupSetAttribute( _dlg, "DEFAULTESC", "btnCANCEL" );
		IupSetCallback( _dlg, "CLOSE_CB", cast(Icallback) &CBaseDialog_btnCancel_cb );

		if( Util.count( buttons, "a" ) == 0 ) IupDestroy( btnAPPLY );
		if( Util.count( buttons, "o" ) == 0 ) IupDestroy( btnOK );
		if( Util.count( buttons, "c" ) == 0 ) IupDestroy( btnCANCEL );

		return hBox_DlgButton;
	}
	

	public:
	this( int w, int h, char[] title, bool bResize = true, char[] parent = null )
	{
		_dlg = IupDialog( null );
		titleString = new IupString( title );
		IupSetAttribute( _dlg, "TITLE", titleString.toCString );

		char[] size = Integer.toString( w ) ~ "x" ~ Integer.toString( h );
		if( w < 0 || h < 0 ) 
		{
			IupSetAttribute( _dlg, "RASTERSIZE", "NULL" );
			if( w < 0 && h > 0)
				IupSetAttribute( _dlg, "RASTERSIZE", GLOBAL.cString.convert( "x" ~ Integer.toString( h ) ) );
			else if( w > 0 && h < 0)
				IupSetAttribute( _dlg, "RASTERSIZE", GLOBAL.cString.convert( Integer.toString( w) ~ "x" ) );
		}
		else
		{
			IupSetAttribute( _dlg, "RASTERSIZE", GLOBAL.cString.convert( size ) );
		}
		
		if( parent.length)
		{
			parentName = new IupString( parent );
			IupSetAttribute( _dlg, "PARENTDIALOG", parentName.toCString );
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