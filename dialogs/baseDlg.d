module dialogs.baseDlg;

import iup.iup;

class CBaseDialog
{
	protected:
	import global, project, scintilla, actionManager, tools;

	import tango.stdc.stringz, Integer = tango.text.convert.Integer;
	
	Ihandle*			_dlg;
	Ihandle*			btnAPPLY, btnOK, btnCANCEL, btnHiddenOK, btnHiddenCANCEL;
	IupString			size, onlyW, onlyH, titleString, parentName;
	
	Ihandle* createDlgButton( char[] buttonSize = "40x20", char[] buttons = "oc" )
	{
		btnAPPLY = IupFlatButton( GLOBAL.languageItems["apply"].toCString );
		IupSetStrAttribute( btnAPPLY, "HLCOLOR", null );
		IupSetHandle( "btnAPPLY", btnAPPLY );
		IupSetStrAttribute( btnAPPLY, "SIZE", toStringz( buttonSize ) );
		
		btnOK = IupFlatButton( GLOBAL.languageItems["ok"].toCString );
		IupSetStrAttribute( btnOK, "HLCOLOR", null );
		IupSetHandle( "btnOK", btnOK );
		IupSetStrAttribute( btnOK, "SIZE", toStringz( buttonSize ) );
		
		btnCANCEL = IupFlatButton( GLOBAL.languageItems["cancel"].toCString );
		IupSetStrAttribute( btnCANCEL, "HLCOLOR", null );
		IupSetHandle( "btnCANCEL", btnCANCEL );
		IupSetStrAttribute( btnCANCEL, "SIZE", toStringz( buttonSize ) );
		IupSetCallback( btnCANCEL, "FLAT_ACTION", cast(Icallback) &CBaseDialog_btnCancel_cb );
		
		// IupFlatButton won't support DEFAULTENTER / DEFAULTESC, so we create non-visible IupButton
		btnHiddenOK = IupButton( null, null );
		IupSetAttribute( btnHiddenOK, "VISIBLE", "NO" );
		IupSetHandle( "btnHiddenOK", btnHiddenOK );
		
		btnHiddenCANCEL = IupButton( null, null );
		IupSetAttribute( btnHiddenCANCEL, "VISIBLE", "NO" );
		IupSetHandle( "btnHiddenCANCEL", btnHiddenCANCEL );
		IupSetCallback( btnHiddenCANCEL, "ACTION", cast(Icallback) &CBaseDialog_btnCancel_cb );
		
		
		
		Ihandle* hBox_DlgButton = IupHbox( btnHiddenOK, btnHiddenCANCEL, IupFill(), btnAPPLY, btnOK, btnCANCEL, null );
		IupSetAttributes( hBox_DlgButton, "ALIGNMENT=ABOTTOM,GAP=5,MARGIN=1x0" );

		IupSetAttribute( _dlg, "DEFAULTENTER", "btnHiddenOK" );
		IupSetAttribute( _dlg, "DEFAULTESC", "btnHiddenCANCEL" );
		IupSetCallback( _dlg, "CLOSE_CB", cast(Icallback) &CBaseDialog_btnCancel_cb );

		if( Util.count( buttons, "a" ) == 0 ) IupDestroy( btnAPPLY );
		if( Util.count( buttons, "o" ) == 0 ) IupDestroy( btnOK );
		if( Util.count( buttons, "c" ) == 0 ) IupDestroy( btnCANCEL );

		return hBox_DlgButton;
	}
	

	public:
	this( int w, int h, char[] title, bool bResize = true, char[] parent = "" )
	{
		_dlg = IupDialog( null );
		titleString = new IupString( title );
		IupSetAttribute( _dlg, "TITLE", titleString.toCString );
		version(DARKTHEME) 
		{
			IupSetStrAttribute( _dlg, "FGCOLOR", GLOBAL.editColor.dlgFore.toCString );
			IupSetStrAttribute( _dlg, "BGCOLOR", GLOBAL.editColor.dlgBack.toCString );
		}
		
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


	this( int w, int h, char[] title, bool bResize = true, Ihandle* parent = null )
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
		
		if( parent != null)	IupSetAttributeHandle( _dlg, "PARENTDIALOG", parent );
		if( !bResize ) IupSetAttribute( _dlg, "RESIZE", "NO" );
		
		IupSetAttribute( _dlg, "FONT", IupGetGlobal( "DEFAULTFONT" ) );
	}

	~this()
	{
		IupSetHandle( "btnCANCEL", null );
		IupSetHandle( "btnOK", null );
		//IupDestroy( _dlg );

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