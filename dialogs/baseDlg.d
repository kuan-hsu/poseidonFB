module dialogs.baseDlg;

import iup.iup;

class CBaseDialog
{
	protected:
	import global, project, scintilla, actionManager, tools;

	import tango.stdc.stringz, Integer = tango.text.convert.Integer;
	
	Ihandle*			_dlg;
	Ihandle*			btnAPPLY, btnOK, btnCANCEL;
	IupString			_buttonSize, size, onlyW, onlyH, titleString, parentName;
	
	Ihandle* createDlgButton( char[] buttonSize = "40x20", char[] buttons = "oc" )
	{
		_buttonSize = new IupString( buttonSize );
		
		btnAPPLY = IupButton( GLOBAL.languageItems["apply"].toCString, null );
		IupSetHandle( "btnAPPLY", btnAPPLY );
		IupSetAttribute( btnAPPLY, "SIZE", _buttonSize.toCString );
		
		btnOK = IupButton( GLOBAL.languageItems["ok"].toCString, null );
		IupSetHandle( "btnOK", btnOK );
		IupSetAttribute( btnOK, "SIZE", _buttonSize.toCString );
		
		btnCANCEL = IupButton( GLOBAL.languageItems["cancel"].toCString, null );
		IupSetHandle( "btnCANCEL", btnCANCEL );
		IupSetAttribute( btnCANCEL, "SIZE", _buttonSize.toCString );
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

		size	= new IupString( Integer.toString( w ) ~ "x" ~ Integer.toString( h ) );
		onlyW	= new IupString( Integer.toString( w ) ~ "x" );
		onlyH	= new IupString( "x" ~ Integer.toString( h ) );
		if( w < 0 || h < 0 ) 
		{
			IupSetAttribute( _dlg, "RASTERSIZE", "NULL" );
			if( w < 0 && h > 0)
				IupSetAttribute( _dlg, "RASTERSIZE", onlyH.toCString );
			else if( w > 0 && h < 0)
				IupSetAttribute( _dlg, "RASTERSIZE", onlyW.toCString );
		}
		else
		{
			IupSetAttribute( _dlg, "RASTERSIZE", size.toCString );
		}
		
		if( parent.length)
		{
			parentName = new IupString( parent );
			IupSetAttribute( _dlg, "PARENTDIALOG", parentName.toCString );
		}
		if( !bResize ) IupSetAttribute( _dlg, "RESIZE", "NO" );
		
		IupSetAttribute( _dlg, "FONT", IupGetGlobal( "DEFAULTFONT" ) );
	}

	~this()
	{
		IupSetHandle( "btnCANCEL", null );
		IupSetHandle( "btnOK", null );
		//IupDestroy( _dlg );
		
		delete _buttonSize;
		delete size;
		delete onlyW;
		delete onlyH;
		delete titleString;
		delete parentName;
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