module dialogs.argOptionDlg;

private import iup.iup, iup.iup_scintilla;

private import global, scintilla, actionManager, tools;
private import dialogs.baseDlg;

private import tango.stdc.stringz;

class CArgOptionDialog : CBaseDialog
{
	private:
	Ihandle*			labelOptions, labelArgs, listOptions, listArgs, btnAPPLY, btnERASE;
	IupString[2]		cStrings;
	IupString[20]		_recentOptions, _recentArgs;
	
	Ihandle* createDlgButton( char[] buttonSize = "40x20" )
	{
		btnOK = IupButton( GLOBAL.languageItems["ok"].toCString, null );
		IupSetAttributes( btnOK, toStringz( "SIZE=" ~ buttonSize ) );//,IMAGE=IUP_ActionOk" );
		
		btnCANCEL = IupButton( GLOBAL.languageItems["cancel"].toCString, null );
		IupSetAttributes( btnCANCEL, toStringz( "SIZE=" ~ buttonSize ) );// ,IMAGE=IUP_ActionCancel
		IupSetCallback( btnCANCEL, "ACTION", cast(Icallback) &CBaseDialog_btnCancel_cb );

		btnAPPLY = IupButton( GLOBAL.languageItems["add"].toCString, null );
		IupSetAttributes( btnAPPLY, toStringz( "SIZE=" ~ buttonSize ) );// ,IMAGE=IUP_ActionCancel

		btnERASE = IupButton( GLOBAL.languageItems["delete"].toCString, null );
		IupSetAttributes( btnERASE, toStringz( "SIZE=" ~ buttonSize ) );// ,IMAGE=IUP_ActionCancel

		Ihandle* hBox_DlgButton = IupHbox( btnERASE, btnAPPLY, IupFill(), btnOK, btnCANCEL, null );
		IupSetAttributes( hBox_DlgButton, "ALIGNMENT=ABOTTOM,GAP=5,MARGIN=1x0" );

		return hBox_DlgButton;
	}	

	void createLayout()
	{
		Ihandle* bottom = createDlgButton( "40x12" );
		
		cStrings[0] = new IupString( GLOBAL.languageItems["prjopts"].toDString() ~ ":" );
		cStrings[1] = new IupString( GLOBAL.languageItems["prjargs"].toDString() ~ ":" );		

		listOptions = IupList( null );
		IupSetAttributes( listOptions, "SHOWIMAGE=NO,DROPDOWN=YES,EDITBOX=YES,SIZE=140x12,VISIBLE_ITEMS=5");
		for( int i = 0; i < GLOBAL.recentOptions.length; ++i )
		{
			_recentOptions[i] = new IupString( GLOBAL.recentOptions[i] );
			IupSetAttribute( listOptions, toStringz( Integer.toString( i + 1 ) ), _recentOptions[i].toCString );
		}
			
		IupSetHandle( "CArgOptionDialog_listOptions", listOptions );

		labelOptions = IupLabel( cStrings[0].toCString );
		IupSetAttribute( labelOptions, "SIZE", "60x16" );
		Ihandle* hBox00 = IupHbox( labelOptions, listOptions, null );
		IupSetAttributes( hBox00, "ALIGNMENT=ACENTER" );

		listArgs = IupList( null );
		IupSetAttributes( listArgs, "SHOWIMAGE=NO,DROPDOWN=YES,EDITBOX=YES,SIZE=140x12,VISIBLE_ITEMS=5");
		for( int i = 0; i < GLOBAL.recentArgs.length; ++i )
		{
			_recentArgs[i] = new IupString( GLOBAL.recentArgs[i] );
			IupSetAttribute( listArgs, toStringz( Integer.toString( i + 1 ) ), _recentArgs[i].toCString );
		}
		
		IupSetHandle( "CArgOptionDialog_listArgs", listArgs );

		labelArgs = IupLabel( cStrings[1].toCString );
		IupSetAttribute( labelArgs, "SIZE", "60x16" );
		Ihandle* hBox01 = IupHbox( labelArgs, listArgs, null );
		IupSetAttributes( hBox01, "ALIGNMENT=ACENTER" );

		Ihandle* vBox = IupVbox( hBox00, hBox01, bottom, null );
		IupSetAttributes( vBox, "ALIGNMENT=ACENTER,MARGIN=5x5,GAP=2,EXPAND=YES,EXPANDCHILDREN=YES" );
		version( Windows ) IupSetAttribute( vBox, "FONTFACE", "Courier New" ); else IupSetAttribute( vBox, "FONTFACE", "FreeMono,Bold 9" );

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

		IupSetHandle( "btnAPPLY_argOption", btnAPPLY );
		IupSetHandle( "btnCANCEL_argOption", btnCANCEL );
		IupSetHandle( "btnOK_argOption", btnOK );

		IupSetCallback( btnCANCEL, "ACTION", cast(Icallback) &CArgOptionDialog_btnCancel_cb );
		IupSetCallback( btnOK, "ACTION", cast(Icallback) &CArgOptionDialog_btnOK_cb );
		IupSetCallback( btnAPPLY, "ACTION", cast(Icallback) &CArgOptionDialog_btnOK_cb );
		IupSetCallback( btnERASE, "ACTION", cast(Icallback) &CArgOptionDialog_btnERASE_cb );
		
		
		IupSetAttribute( btnOK, "TITLE", GLOBAL.languageItems["run"].toCString );

		IupSetAttribute( _dlg, "DEFAULTESC", "btnCANCEL_argOption" );
		IupSetAttribute( _dlg, "DEFAULTENTER", "btnOK_argOption" );

		IupSetCallback( _dlg, "CLOSE_CB", cast(Icallback) &CArgOptionDialog_CLOSE_cb );
	}

	~this()
	{
		//IupSetHandle( "CArgOptionDialog_listOptions", null );
		IupSetHandle( "CArgOptionDialog_listArgs", null );
		IupSetHandle( "btnCANCEL_argOption", null );
		for( int i =0; i < 20; ++ i )
		{
			if( _recentArgs[i] !is null ) delete _recentArgs[i];
			if( _recentOptions[i] !is null ) delete _recentOptions[i];
		}
		
		if( cStrings[0] !is null ) delete cStrings[0];
		if( cStrings[1] !is null ) delete cStrings[1];
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
					char[] text = Util.trim( fromStringz( IupGetAttribute( _listOptions, "VALUE" ) ).dup );
					if( text.length )
					{
						actionManager.SearchAction.addListItem( _listOptions, text, GLOBAL.maxRecentOptions );
						
						GLOBAL.recentOptions.length = 0;
						for( int i = 1; i <= IupGetInt( _listOptions, "COUNT" ); ++ i )
						{
							GLOBAL.recentOptions ~= fromStringz( IupGetAttribute( _listOptions, toStringz( Integer.toString( i ) ) ) ).dup;
						}
						if( GLOBAL.recentOptions.length ) IupSetAttribute( _listOptions, "VALUE", toStringz( GLOBAL.recentOptions[0] ) );
					}
					else
					{
						IupSetAttribute( _listOptions, "VALUE", "" );
					}
				}
			}

			Ihandle* _listArgs = IupGetHandle( "CArgOptionDialog_listArgs" );
			if( _listArgs != null )
			{
				if( fromStringz( IupGetAttribute( _listArgs, "ACTIVE" ) ) == "YES" )
				{
					char[] text = Util.trim( fromStringz( IupGetAttribute( _listArgs, "VALUE" ) ).dup );
					if( text.length )
					{
						actionManager.SearchAction.addListItem( _listArgs, text, GLOBAL.maxRecentArgs );

						GLOBAL.recentArgs.length = 0;
						for( int i = 1; i <= IupGetInt( _listArgs, "COUNT" ); ++ i )
						{
							GLOBAL.recentArgs ~= fromStringz( IupGetAttribute( _listArgs, toStringz( Integer.toString( i ) ) ) ).dup;
						}
						if( GLOBAL.recentArgs.length ) IupSetAttribute( _listArgs, "VALUE", toStringz( GLOBAL.recentArgs[0] ) );
					}
					else
					{
						IupSetAttribute( _listArgs, "VALUE", "" );
					}
				}
			}
			
			if( ih == IupGetHandle( "btnAPPLY_argOption" ) ) return IUP_DEFAULT;
			IupHide( GLOBAL.argsDlg._dlg );
		}

		return IUP_DEFAULT;
	}

	private int CArgOptionDialog_btnERASE_cb( Ihandle* ih )
	{
		if( GLOBAL.argsDlg !is null )
		{
			Ihandle* _listOptions = IupGetHandle( "CArgOptionDialog_listOptions" );
			if( _listOptions != null )
			{
				if( fromStringz( IupGetAttribute( _listOptions, "ACTIVE" ) ) == "YES" )
				{
					char[] text = fromStringz( IupGetAttribute( _listOptions, "VALUE" ) ).dup;
					for( int i = IupGetInt( _listOptions, "COUNT" ); i > 0; -- i )
					{
						char[] itemText = Util.trim( fromStringz( IupGetAttributeId( _listOptions, "", i ) ) ).dup;
						if( itemText.length )
						{
							if( fromStringz( IupGetAttributeId( _listOptions, "", i ) ) == text )
							{
								IupSetAttribute( _listOptions, "VALUE", "" );
								IupSetInt( _listOptions, "REMOVEITEM", i );
							}
						}
						else
						{
							IupSetInt( _listOptions, "REMOVEITEM", i );							
						}
					}
					GLOBAL.recentOptions.length = 0;
					for( int i = 1; i <= IupGetInt( _listOptions, "COUNT" ); ++ i )
					{
						GLOBAL.recentOptions ~= fromStringz( IupGetAttributeId( _listOptions, "", i ) ).dup;
					}					
				}
			}

			Ihandle* _listArgs = IupGetHandle( "CArgOptionDialog_listArgs" );
			if( _listArgs != null )
			{
				char[] text = fromStringz( IupGetAttribute( _listArgs, "VALUE" ) ).dup;
				for( int i = IupGetInt( _listArgs, "COUNT" ); i > 0; -- i )
				{
					char[] itemText = Util.trim( fromStringz( IupGetAttributeId( _listArgs, "", i ) ) ).dup;
					if( itemText.length )
					{
						if( fromStringz( IupGetAttributeId( _listArgs, "", i ) ) == text )
						{
							IupSetAttribute( _listArgs, "VALUE", "" );
							IupSetInt( _listArgs, "REMOVEITEM", i );
						}
					}
					else
					{
						IupSetInt( _listArgs, "REMOVEITEM", i );							
					}
				}
				GLOBAL.recentArgs.length = 0;
				for( int i = 1; i <= IupGetInt( _listArgs, "COUNT" ); ++ i )
				{
					GLOBAL.recentArgs ~= fromStringz( IupGetAttributeId( _listArgs, "", i ) ).dup;
				}
			}
		}

		return IUP_DEFAULT;
	}
	
	private int CArgOptionDialog_CLOSE_cb( Ihandle *ih )
	{
		return CArgOptionDialog_btnCancel_cb( ih );
	}	
}