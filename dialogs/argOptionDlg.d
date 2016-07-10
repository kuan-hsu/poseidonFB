module dialogs.argOptionDlg;

private import iup.iup, iup.iup_scintilla;

private import global, scintilla, actionManager;
private import dialogs.baseDlg;

private import tango.stdc.stringz;

class CArgOptionDialog : CBaseDialog
{
	private:
	Ihandle*	labelOptions, labelArgs, listOptions, listArgs;

	void createLayout()
	{
		Ihandle* bottom = createDlgButton();

		listOptions = IupList( null );
		IupSetAttributes( listOptions, "SHOWIMAGE=NO,DROPDOWN=YES,EDITBOX=YES,SIZE=120x12,VISIBLE_ITEMS=5");
		IupSetHandle( "CArgOprionDialog_listOptions", listOptions );

		labelOptions = IupLabel( "Compiler Options: " );
		Ihandle* hBox00 = IupHbox( labelOptions, listOptions, null );
		IupSetAttributes( hBox00, "ALIGNMENT=ACENTER" );

		listArgs = IupList( null );
		IupSetAttributes( listArgs, "SHOWIMAGE=NO,DROPDOWN=YES,EDITBOX=YES,SIZE=120x12,VISIBLE_ITEMS=5");
		IupSetHandle( "CArgOprionDialog_listArgs", listArgs );
		labelArgs = IupLabel( "Execute Arguments:" );
		Ihandle* hBox01 = IupHbox( labelArgs, listArgs, null );
		IupSetAttributes( hBox01, "ALIGNMENT=ACENTER" );

		Ihandle* vBox = IupVbox( hBox00, hBox01, bottom, null );
		IupSetAttributes( vBox, "ALIGNMENT=ACENTER,MARGIN=5x5,GAP=2,EXPAND=YES,EXPANDCHILDREN=YES" );

		IupAppend( _dlg, vBox );
	}	

	public:
	this( int w, int h, char[] title, bool bResize = false, char[] parent = "MAIN_DIALOG" )
	{
		super( w, h, title, bResize, parent );
		IupSetAttribute( _dlg, "MINBOX", "NO" );
		IupSetAttribute( _dlg, "TOPMOST", "YES" );
		version( Windows )
		{
			IupSetAttribute( _dlg, "FONT", GLOBAL.cString.convert( "Courier New,9" ) );
		}
		else
		{
			IupSetAttribute( _dlg, "FONT", GLOBAL.cString.convert( "FreeMono,Bold 9" ) );;
		}		

		createLayout();

		IupSetHandle( "btnCANCEL_argOption", btnCANCEL );
		IupSetHandle( "btnOK_argOption", btnOK );

		IupSetCallback( btnCANCEL, "ACTION", cast(Icallback) &CArgOprionDialog_btnCancel_cb );
		IupSetCallback( btnOK, "ACTION", cast(Icallback) &CArgOprionDialog_btnOK_cb );

		IupSetAttribute( _dlg, "DEFAULTESC", "btnCANCEL_argOption" );
		IupSetAttribute( _dlg, "DEFAULTENTER", "btnOK_argOption" );

		IupSetCallback( _dlg, "CLOSE_CB", cast(Icallback) &CArgOprionDialog_CLOSE_cb );
	}

	~this()
	{
		IupSetHandle( "CArgOprionDialog_listOptions", null );
		IupSetHandle( "CArgOprionDialog_listArgs", null );
		IupSetHandle( "btnCANCEL_argOption", null );	
	}

	char[][] show( int showWhat ) // Overload form CBaseDialog
	{
		//IupShow( _dlg );
		if( showWhat & 1 )
		{
			IupSetAttribute( listOptions, "ACTIVE", "YES" );
			IupSetAttribute( labelOptions, "ACTIVE", "YES" );
		}
		else
		{
			IupSetAttribute( listOptions, "ACTIVE", "NO" );
			IupSetAttribute( labelOptions, "ACTIVE", "NO" );
		}

		if( showWhat & 2 )
		{
			IupSetAttribute( listArgs, "ACTIVE", "YES" );
			IupSetAttribute( labelArgs, "ACTIVE", "YES" );
		}
		else
		{
			IupSetAttribute( listArgs, "ACTIVE", "NO" );
			IupSetAttribute( labelArgs, "ACTIVE", "NO" );
		}

		IupPopup( _dlg, IUP_MOUSEPOS, IUP_MOUSEPOS );

		char[][] results;

		Ihandle* listOptions = IupGetHandle( "CArgOprionDialog_listOptions" );
		if( listOptions != null )
		{
			if( fromStringz( IupGetAttribute( listOptions, "ACTIVE" ) ) == "YES" ) results ~= fromStringz( IupGetAttribute( listOptions, "VALUE" ) ).dup;
		}

		Ihandle* listArgs = IupGetHandle( "CArgOprionDialog_listArgs" );
		if( listArgs != null )
		{
			if( fromStringz( IupGetAttribute( listArgs, "ACTIVE" ) ) == "YES" ) results ~= fromStringz( IupGetAttribute( listArgs, "VALUE" ) ).dup;
		}
	
		return results;
	}	
}

extern(C) // Callback for CArgOprionDialog
{
	private int CArgOprionDialog_btnCancel_cb( Ihandle* ih )
	{
		if( GLOBAL.argsDlg !is null )
		{
			Ihandle* listOptions = IupGetHandle( "CArgOprionDialog_listOptions" );
			if( listOptions != null ) IupSetAttribute( listOptions, "ACTIVE", "NO" );

			Ihandle* listArgs = IupGetHandle( "CArgOprionDialog_listArgs" );
			if( listArgs != null ) IupSetAttribute( listArgs, "ACTIVE", "NO" );

			IupHide( GLOBAL.argsDlg._dlg );
		}

		return IUP_DEFAULT;
	}

	private int CArgOprionDialog_btnOK_cb( Ihandle* ih )
	{
		if( GLOBAL.argsDlg !is null )
		{
			Ihandle* listOptions = IupGetHandle( "CArgOprionDialog_listOptions" );
			if( listOptions != null )
			{
				if( fromStringz( IupGetAttribute( listOptions, "ACTIVE" ) ) == "YES" ) actionManager.SearchAction.addListItem( listOptions, fromStringz( IupGetAttribute( listOptions, "VALUE" ) ).dup , 10 );
			}

			Ihandle* listArgs = IupGetHandle( "CArgOprionDialog_listArgs" );
			if( listArgs != null )
			{
				if( fromStringz( IupGetAttribute( listArgs, "ACTIVE" ) ) == "YES" ) actionManager.SearchAction.addListItem( listArgs, fromStringz( IupGetAttribute( listArgs, "VALUE" ) ).dup , 10 );
			}			
			
			IupHide( GLOBAL.argsDlg._dlg );
		}

		return IUP_DEFAULT;
	}

	private int CArgOprionDialog_CLOSE_cb( Ihandle *ih )
	{
		return CArgOprionDialog_btnCancel_cb( ih );
	}	
}