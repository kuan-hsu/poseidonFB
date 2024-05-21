module dialogs.baseDlg;

import iup.iup;

class CBaseDialog
{
	private:
	import darkmode.darkmode;
	
	protected:
	import global, project, scintilla, actionManager, tools;
	import std.string, std.algorithm, std.conv;
	
	Ihandle*			_dlg;
	Ihandle*			btnAPPLY, btnOK, btnCANCEL, btnHiddenOK, btnHiddenCANCEL;
	
	Ihandle* createDlgButton( string buttonSize = "40x20", string buttons = "oc" )
	{
		btnAPPLY = IupFlatButton( GLOBAL.languageItems["apply"].toCString );
		IupSetStrAttribute( btnAPPLY, "HLCOLOR", IupGetAttribute( _dlg, "BGCOLOR" ) );
		IupSetHandle( "btnAPPLY", btnAPPLY );
		IupSetStrAttribute( btnAPPLY, "SIZE", toStringz( buttonSize ) );
		
		btnOK = IupFlatButton( GLOBAL.languageItems["ok"].toCString );
		IupSetStrAttribute( btnOK, "HLCOLOR", IupGetAttribute( _dlg, "BGCOLOR" ) );
		IupSetHandle( "btnOK", btnOK );
		IupSetStrAttribute( btnOK, "SIZE", toStringz( buttonSize ) );
		
		btnCANCEL = IupFlatButton( GLOBAL.languageItems["cancel"].toCString );
		IupSetStrAttribute( btnCANCEL, "HLCOLOR", IupGetAttribute( _dlg, "BGCOLOR" ) );
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
			if( GLOBAL.bCanUseDarkMode )
			{
				if( GLOBAL.editorSetting00.UseDarkMode == "ON" )
				{
					AllowDarkModeForWindow( IupGetAttribute( _dlg, "HWND" ), 1 );
					RefreshCaptionColor( IupGetAttribute( _dlg, "HWND" ) );
				}
			}
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
	int CBaseDialog_btnCancel_cb()
	{
		return IUP_CLOSE;
	}
}


/+
class CCustomMessageDialog
{
private:
	import global;
	import std.string, std.algorithm, std.conv;
	
	Ihandle*			_dlg, _icon, _message;
	Ihandle*			btnYES, btnNO, btnAPPLY, btnOK, btnCANCEL, btnHiddenOK, btnHiddenCANCEL;
	
	Ihandle* createDlgButton( string buttonSize = "45x20", string buttons = "yn" )
	{
		btnYES = IupFlatButton( GLOBAL.languageItems["yes"].toCString );
		IupSetStrAttribute( btnYES, "HLCOLOR", IupGetAttribute( _dlg, "BGCOLOR" ) );
		IupSetStrAttribute( btnYES, "SIZE", toStringz( buttonSize ) );
		IupSetAttributes( btnYES, "NAME=btnYES" );

		btnNO = IupFlatButton( GLOBAL.languageItems["no"].toCString );
		IupSetStrAttribute( btnNO, "HLCOLOR", IupGetAttribute( _dlg, "BGCOLOR" ) );
		IupSetStrAttribute( btnNO, "SIZE", toStringz( buttonSize ) );
		IupSetAttributes( btnNO, "NAME=btnNO" );

		btnCANCEL = IupFlatButton( GLOBAL.languageItems["cancel"].toCString );
		IupSetStrAttribute( btnCANCEL, "HLCOLOR", IupGetAttribute( _dlg, "BGCOLOR" ) );
		IupSetStrAttribute( btnCANCEL, "SIZE", toStringz( buttonSize ) );
		IupSetAttributes( btnCANCEL, "NAME=btnCANCEL" );
		//IupSetCallback( btnCANCEL, "FLAT_ACTION", cast(Icallback) &CCustomMessageDialog_btnCancel_cb );
		
		// IupFlatButton won't support DEFAULTENTER / DEFAULTESC, so we create non-visible IupButton
		btnHiddenOK = IupButton( null, null );
		IupSetAttribute( btnHiddenOK, "VISIBLE", "NO" );
		IupSetAttributes( btnHiddenOK, "NAME=btnHiddenOK" );
		
		btnHiddenCANCEL = IupButton( null, null );
		IupSetAttribute( btnHiddenCANCEL, "VISIBLE", "NO" );
		IupSetAttributes( btnHiddenCANCEL, "NAME=btnHiddenCANCEL" );
		//IupSetCallback( btnHiddenCANCEL, "ACTION", cast(Icallback) &CCustomMessageDialog_btnCancel_cb );
		
		
		
		Ihandle* hBox_DlgButton = IupHbox( btnYES, btnNO, btnCANCEL, null );
		IupSetAttributes( hBox_DlgButton, "ALIGNMENT=ACENTER,NORMALIZESIZE=HORIZONTAL,HOMOGENEOUS=YES,GAP=5,MARGIN=1x0" );
		/+
		IupSetAttribute( _dlg, "DEFAULTENTER", "btnHiddenOK" );
		IupSetAttribute( _dlg, "DEFAULTESC", "btnHiddenCANCEL" );
		IupSetCallback( _dlg, "CLOSE_CB", cast(Icallback) &CBaseDialog_btnCancel_cb );

		if( std.algorithm.count( buttons, "a" ) == 0 ) IupDestroy( btnAPPLY );
		if( std.algorithm.count( buttons, "o" ) == 0 ) IupDestroy( btnOK );
		if( std.algorithm.count( buttons, "c" ) == 0 ) IupDestroy( btnCANCEL );
		+/
		return hBox_DlgButton;
	}
	
	
	Ihandle* createMessage( string message, string iconType )
	{
		_icon = IupLabel( null );
		IupSetAttribute( _icon, "IMAGE", "icon_gotomember" );
		_message = IupText( null );
		IupSetAttribute( _message, "VALUE", toStringz( message ) );
		IupSetAttributes( _message, "CANFOCUS=NO,MULTILINE=YES,SCROLLBAR=NO,ALIGNMENT=ACENTER,WORDWRAP=YES,READONLY=YES,BORDER=NO,SIZE=120x30" );
	
		Ihandle* hBox_Message = IupHbox( _icon, _message, null );
		IupSetAttributes( hBox_Message, "ALIGNMENT=ACENTER,MARGIN=5x5" );
		
		return hBox_Message;
	}
	

public:
	this( string title, string message, string buttonType )
	{
		int w = 270, h = 175;
		
		Ihandle* vBox = IupVbox( IupFill, createMessage( message, "alarm" ), IupFill, createDlgButton(), null );
		IupSetAttributes( vBox, "ALIGNMENT=ACENTER,GAP=10" );
		_dlg = IupDialog( vBox );
		IupSetStrAttribute( _dlg, "TITLE", toStringz( title ) );
		IupSetStrAttribute( _dlg, "FGCOLOR", toStringz( GLOBAL.editColor.dlgFore ) );
		IupSetStrAttribute( _dlg, "BGCOLOR", toStringz( GLOBAL.editColor.dlgBack ) );
		
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

		IupSetAttributes( _dlg, "RESIZE=NO,MINBOX=NO" );
		IupSetStrAttribute( _dlg, "PARENTDIALOG", "POSEIDON_MAIN_DIALOG" );
		IupSetAttribute( _dlg, "FONT", IupGetGlobal( "DEFAULTFONT" ) );
		
		IupPopup( _dlg, IUP_CENTERPARENT, IUP_CENTERPARENT );
	}


	~this()
	{
	}

	string show( int x, int y )
	{
		IupPopup( _dlg, x, y );
		return null;
	}
	
	Ihandle* getIhandle()
	{
		return _dlg;
	}
}
+/