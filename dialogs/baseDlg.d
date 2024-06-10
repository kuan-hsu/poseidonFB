module dialogs.baseDlg;

import iup.iup;

class CBaseDialog
{
protected:
	import global, project, scintilla, actionManager, tools;
	import std.string, std.algorithm, std.conv;
	
	Ihandle*			_dlg;
	Ihandle*			btnAPPLY, btnOK, btnCANCEL, btnHiddenOK, btnHiddenCANCEL;
	
	Ihandle* createDlgButton( string buttonSize = "40x20", string buttons = "oc", string HandleHeadName = "" )
	{
		btnAPPLY = IupFlatButton( GLOBAL.languageItems["apply"].toCString );
		IupSetStrAttribute( btnAPPLY, "HLCOLOR", IupGetAttribute( _dlg, "BGCOLOR" ) );
		IupSetHandle( toStringz( HandleHeadName ~ "btnAPPLY" ), btnAPPLY );
		IupSetStrAttribute( btnAPPLY, "SIZE", toStringz( buttonSize ) );
		
		btnOK = IupFlatButton( GLOBAL.languageItems["ok"].toCString );
		IupSetStrAttribute( btnOK, "HLCOLOR", IupGetAttribute( _dlg, "BGCOLOR" ) );
		IupSetHandle( toStringz( HandleHeadName ~ "btnOK" ), btnOK );
		IupSetStrAttribute( btnOK, "SIZE", toStringz( buttonSize ) );
		
		btnCANCEL = IupFlatButton( GLOBAL.languageItems["cancel"].toCString );
		IupSetStrAttribute( btnCANCEL, "HLCOLOR", IupGetAttribute( _dlg, "BGCOLOR" ) );
		IupSetHandle( toStringz( HandleHeadName ~ "btnCANCEL" ), btnCANCEL );
		IupSetStrAttribute( btnCANCEL, "SIZE", toStringz( buttonSize ) );
		IupSetCallback( btnCANCEL, "FLAT_ACTION", cast(Icallback) &CBaseDialog_btnCancel_cb );
		
		// IupFlatButton won't support DEFAULTENTER / DEFAULTESC, so we create non-visible IupButton
		btnHiddenOK = IupButton( null, null );
		IupSetAttribute( btnHiddenOK, "VISIBLE", "NO" );
		IupSetHandle( toStringz( HandleHeadName ~ "btnHiddenOK" ), btnHiddenOK );
		
		btnHiddenCANCEL = IupButton( null, null );
		IupSetAttribute( btnHiddenCANCEL, "VISIBLE", "NO" );
		IupSetHandle( toStringz( HandleHeadName ~ "btnHiddenCANCEL" ), btnHiddenCANCEL );
		IupSetCallback( btnHiddenCANCEL, "ACTION", cast(Icallback) &CBaseDialog_btnCancel_cb );
		
		
		
		Ihandle* hBox_DlgButton = IupHbox( btnHiddenOK, btnHiddenCANCEL, IupFill(), btnAPPLY, btnOK, btnCANCEL, null );
		IupSetAttributes( hBox_DlgButton, "ALIGNMENT=ABOTTOM,GAP=5,MARGIN=1x0" );

		IupSetAttribute( _dlg, "DEFAULTENTER", toStringz( HandleHeadName ~ "btnHiddenOK" ) );
		IupSetAttribute( _dlg, "DEFAULTESC", toStringz( HandleHeadName ~ "btnHiddenCANCEL" ) );
		IupSetCallback( _dlg, "CLOSE_CB", cast(Icallback) &CBaseDialog_btnCancel_cb );

		if( std.algorithm.count( buttons, "a" ) == 0 ) IupDestroy( btnAPPLY );
		if( std.algorithm.count( buttons, "o" ) == 0 ) IupDestroy( btnOK );
		if( std.algorithm.count( buttons, "c" ) == 0 ) IupDestroy( btnCANCEL );

		return hBox_DlgButton;
	}
	

public:
	this( int w, int h, string title, bool bResize = true, string parent = "" )
	{
		_dlg = IupDialog( null );
		if( title.length ) IupSetStrAttribute( _dlg, "TITLE", toStringz( title ) );
		version(Windows)
		{
			IupSetStrAttribute( _dlg, "FGCOLOR", toStringz( GLOBAL.editColor.dlgFore ) );
			IupSetStrAttribute( _dlg, "BGCOLOR", toStringz( GLOBAL.editColor.dlgBack ) );
		}
		IupSetStrAttribute( _dlg, "OPACITY", toStringz( GLOBAL.editorSetting02.generalDlg ) );
		
		string size	= to!(string)( w ) ~ "x" ~ to!(string)( h );
		string onlyW = to!(string)( w ) ~ "x";
		string onlyH = "x" ~ to!(string)( h );
		if( w < 0 || h < 0 ) 
		{
			IupSetAttribute( _dlg, "RASTERSIZE", "NULL" );
			if( w < 0 && h > 0)
				IupSetStrAttribute( _dlg, "RASTERSIZE", toStringz( onlyH ) );
			else if( w > 0 && h < 0)
				IupSetStrAttribute( _dlg, "RASTERSIZE", toStringz( onlyW ) );
		}
		else
		{
			IupSetStrAttribute( _dlg, "RASTERSIZE", toStringz( size ) );
		}
		
		if( parent.length)
		{
			IupSetStrAttribute( _dlg, "PARENTDIALOG", toStringz( parent ) );
		}
		if( !bResize ) IupSetAttribute( _dlg, "RESIZE", "NO" );
		
		IupSetAttribute( _dlg, "FONT", IupGetGlobal( "DEFAULTFONT" ) );
	}


	this( int w, int h, string title, bool bResize = true, Ihandle* parent = null )
	{
		this( w, h, title, bResize, "" );
		if( parent != null)	IupSetAttributeHandle( _dlg, "PARENTDIALOG", parent );
	}

	~this()
	{
		IupSetHandle( "btnCANCEL", null );
		IupSetHandle( "btnOK", null );
	}

	string show( int x, int y )
	{	
		version(Windows)
		{
			IupMap( _dlg );
			tools.setCaptionTheme( _dlg, GLOBAL.editorSetting00.UseDarkMode == "ON" ? true : false );
			tools.setDarkMode4Dialog( _dlg, GLOBAL.editorSetting00.UseDarkMode == "ON" ? true : false );
		}
		IupPopup( _dlg, x, y );
		return null;
	}
	
	string[] show( int x, int y, int dummy )
	{
		return null;
	}	
	
	Ihandle* getIhandle()
	{
		return _dlg;
	}
}

extern(C) // Callback for CBaseDialog
{
	int CBaseDialog_btnCancel_cb( Ihandle* ih )
	{
		return IUP_CLOSE;
	}
}