module dialogs.argOptionDlg;

private import iup.iup, iup.iup_scintilla;

private import global, scintilla, actionManager;
private import dialogs.baseDlg;

private import tango.stdc.stringz;

class CArgOptionDialog : CBaseDialog
{
	private:
	import				tools;

	Ihandle*			labelOptions, labelArgs, listOptions, listArgs;
	IupString[2]		cStrings;
	IupString[]			recentOptions, recentArgs;
	

	void createLayout()
	{
		Ihandle* bottom = createDlgButton();
		
		cStrings[0] = new IupString( GLOBAL.languageItems["prjopts"].toDString() ~ ":" );
		cStrings[1] = new IupString( GLOBAL.languageItems["prjargs"].toDString() ~ ":" );		

		listOptions = IupList( null );
		IupSetAttributes( listOptions, "SHOWIMAGE=NO,DROPDOWN=YES,EDITBOX=YES,SIZE=120x12,VISIBLE_ITEMS=5");
		for( int i = 0; i < GLOBAL.recentOptions.length; ++i )
			if( GLOBAL.recentOptions[i].length )
			{
				recentOptions.length = recentOptions.length + 1;
				recentOptions[$-1] = new IupString( GLOBAL.recentOptions[i] );
				IupSetAttribute( listOptions, toStringz( Integer.toString( i + 1 ) ), recentOptions[$-1].toCString );
			}
			
		IupSetHandle( "CArgOptionDialog_listOptions", listOptions );

		labelOptions = IupLabel( cStrings[0].toCString );
		Ihandle* hBox00 = IupHbox( labelOptions, listOptions, null );
		IupSetAttributes( hBox00, "ALIGNMENT=ACENTER" );

		listArgs = IupList( null );
		IupSetAttributes( listArgs, "SHOWIMAGE=NO,DROPDOWN=YES,EDITBOX=YES,SIZE=120x12,VISIBLE_ITEMS=5");
		for( int i = 0; i < GLOBAL.recentArgs.length; ++i )
			if( GLOBAL.recentArgs[i].length )
			{
				recentArgs.length = recentArgs.length + 1;
				recentArgs[$-1] = new IupString( GLOBAL.recentArgs[i] );
				IupSetAttribute( listArgs, toStringz( Integer.toString( i + 1 ) ), recentArgs[$-1].toCString );
			}
		
		IupSetHandle( "CArgOptionDialog_listArgs", listArgs );

		labelArgs = IupLabel( cStrings[1].toCString );
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

		IupSetCallback( btnCANCEL, "ACTION", cast(Icallback) &CArgOptionDialog_btnCancel_cb );
		IupSetCallback( btnOK, "ACTION", cast(Icallback) &CArgOptionDialog_btnOK_cb );

		IupSetAttribute( _dlg, "DEFAULTESC", "btnCANCEL_argOption" );
		IupSetAttribute( _dlg, "DEFAULTENTER", "btnOK_argOption" );

		IupSetCallback( _dlg, "CLOSE_CB", cast(Icallback) &CArgOptionDialog_CLOSE_cb );
	}

	~this()
	{
		//IupSetHandle( "CArgOptionDialog_listOptions", null );
		IupSetHandle( "CArgOptionDialog_listArgs", null );
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

		if( fromStringz( IupGetAttribute( listOptions, "ACTIVE" ) ) == "YES" )
			if( IupGetInt( listOptions, "COUNT" ) > 0 ) IupSetAttribute( listOptions, "VALUE", IupGetAttribute( listOptions, "1" ) );

		if( fromStringz( IupGetAttribute( listArgs, "ACTIVE" ) ) == "YES" )
			if( IupGetInt( listArgs, "COUNT" ) > 0 ) IupSetAttribute( listArgs, "VALUE", IupGetAttribute( listArgs, "1" ) );
			

		IupPopup( _dlg, IUP_MOUSEPOS, IUP_MOUSEPOS );

		char[][] results;

		if( listOptions != null )
		{
			if( fromStringz( IupGetAttribute( listOptions, "ACTIVE" ) ) == "YES" ) results ~= fromStringz( IupGetAttribute( listOptions, "VALUE" ) ).dup;
		}

		if( listArgs != null )
		{
			if( fromStringz( IupGetAttribute( listArgs, "ACTIVE" ) ) == "YES" ) results ~= fromStringz( IupGetAttribute( listArgs, "VALUE" ) ).dup;
		}
	
		return results;
	}	
}

extern(C) // Callback for CArgOptionDialog
{
	private int CArgOptionDialog_btnCancel_cb( Ihandle* ih )
	{
		if( GLOBAL.argsDlg !is null )
		{
			Ihandle* listOptions = IupGetHandle( "CArgOptionDialog_listOptions" );
			if( listOptions != null ) IupSetAttribute( listOptions, "ACTIVE", "NO" );

			Ihandle* listArgs = IupGetHandle( "CArgOptionDialog_listArgs" );
			if( listArgs != null ) IupSetAttribute( listArgs, "ACTIVE", "NO" );

			IupHide( GLOBAL.argsDlg._dlg );
		}

		return IUP_DEFAULT;
	}

	private int CArgOptionDialog_btnOK_cb( Ihandle* ih )
	{
		if( GLOBAL.argsDlg !is null )
		{
			Ihandle* _listOptions = IupGetHandle( "CArgOptionDialog_listOptions" );
			if( _listOptions != null )
			{
				if( fromStringz( IupGetAttribute( _listOptions, "ACTIVE" ) ) == "YES" )
				{
					actionManager.SearchAction.addListItem( _listOptions, fromStringz( IupGetAttribute( _listOptions, "VALUE" ) ).dup, 10 );
					GLOBAL.recentOptions.length = 0;
					for( int i = 1; i <= IupGetInt( _listOptions, "COUNT" ); ++ i )
					{
						GLOBAL.recentOptions ~= fromStringz( IupGetAttribute( _listOptions, toStringz( Integer.toString( i ) ) ) ).dup;
					}
				}
			}

			Ihandle* _listArgs = IupGetHandle( "CArgOptionDialog_listArgs" );
			if( _listArgs != null )
			{
				if( fromStringz( IupGetAttribute( _listArgs, "ACTIVE" ) ) == "YES" )
				{
					actionManager.SearchAction.addListItem( _listArgs, fromStringz( IupGetAttribute( _listArgs, "VALUE" ) ).dup , 10 );
					GLOBAL.recentArgs.length = 0;
					for( int i = 1; i <= IupGetInt( _listArgs, "COUNT" ); ++ i )
					{
						GLOBAL.recentArgs ~= fromStringz( IupGetAttribute( _listArgs, toStringz( Integer.toString( i ) ) ) ).dup;
					}
				}
			}			
			
			IupHide( GLOBAL.argsDlg._dlg );
		}

		return IUP_DEFAULT;
	}

	private int CArgOptionDialog_CLOSE_cb( Ihandle *ih )
	{
		return CArgOptionDialog_btnCancel_cb( ih );
	}	
}