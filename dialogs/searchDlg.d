module dialogs.searchDlg;

private import iup.iup, iup.iup_scintilla;

private import global, scintilla, actionManager;
private import dialogs.baseDlg;

private import tango.stdc.stringz;

class CSearchDialog : CBaseDialog
{
	private:
	import				tools;
	
	Ihandle*			listFind, listReplace;
	Ihandle*			labelStatus;
	IupString[18]	cStrings;

	void createLayout()
	{
		Ihandle* bottom = createDlgButton();
		IupSetAttribute( btnOK, "VISIBLE", "NO" );

		listFind = IupList( null );
		/*
		IupSetAttributes( listFind, "1=\"Console Application\",2=\"Static Library\",3=\"Dynamic Link Library\","
                                   "SHOWIMAGE=NO,VALUE=1,DROPDOWN=YES,EDITBOX=YES,SIZE=100x12,VISIBLE_ITEMS=3");
		*/
		IupSetAttributes( listFind, "SHOWIMAGE=NO,DROPDOWN=YES,EDITBOX=YES,SIZE=120x12,VISIBLE_ITEMS=3");
		IupSetHandle( "CSearchDialog_listFind", listFind );
		
		cStrings[0] = new IupString( GLOBAL.languageItems["findwhat"] ~ ":" );
		Ihandle* hBox00 = IupHbox( IupLabel( cStrings[0].toCString ), listFind, null );
		
		IupSetAttributes( hBox00, "ALIGNMENT=ACENTER" );
		IupSetCallback( listFind, "K_ANY", cast(Icallback) &CSearchDialog_listFind_K_ANY_CB );


		listReplace = IupList( null );
		IupSetAttributes( listReplace, "SHOWIMAGE=NO,DROPDOWN=YES,EDITBOX=YES,SIZE=120x12,VISIBLE_ITEMS=3");
		IupSetHandle( "CSearchDialog_listReplace", listReplace );
		
		cStrings[1] = new IupString( GLOBAL.languageItems["replacewith"] ~ ":" );
		Ihandle* hBox01 = IupHbox( IupLabel( cStrings[1].toCString ), listReplace, null );
		IupSetAttributes( hBox01, "ALIGNMENT=ACENTER" );
		IupSetCallback( listReplace, "K_ANY", cast(Icallback) &CSearchDialog_listReplace_K_ANY_CB );

		cStrings[2] = new IupString( GLOBAL.languageItems["forward"] );
		Ihandle* toggleForward = IupToggle( cStrings[2].toCString, null );
		IupSetAttributes( toggleForward, "RADIO=YES");
		IupSetHandle( "CSearchDialog_toggleForward", toggleForward );
		
		cStrings[3] = new IupString( GLOBAL.languageItems["backward"] );
		Ihandle* toggleBackward = IupToggle( cStrings[3].toCString, null );
		IupSetAttributes( toggleBackward, "RADIO=YES");
		IupSetHandle( "CSearchDialog_toggleBackward", toggleBackward );
		
		Ihandle* vBoxDirection = IupVbox( toggleForward, toggleBackward, null );
		IupSetAttributes( vBoxDirection, "EXPAND=YES,EXPANDCHILDREN=YES" );
		Ihandle* radioDirection = IupRadio( vBoxDirection );
		Ihandle* frameDirection = IupFrame( radioDirection );
		IupSetAttributes( frameDirection, "EXPAND=YES");
		
		cStrings[4] = new IupString( GLOBAL.languageItems["direction"] );
		IupSetAttribute( frameDirection, "TITLE", cStrings[4].toCString );

		cStrings[5] = new IupString( GLOBAL.languageItems["all"] );
		cStrings[6] = new IupString( GLOBAL.languageItems["selection"] );
		cStrings[7] = new IupString( GLOBAL.languageItems["scope"] );
		
		Ihandle* toggleAll = IupToggle( cStrings[5].toCString, null );
		IupSetAttributes( toggleAll, "RADIO=YES");		
		Ihandle* toggleSelection = IupToggle( cStrings[6].toCString, null );
		IupSetAttributes( toggleSelection, "RADIO=YES");
		IupSetAttribute( toggleSelection, "ACTIVE", "NO" );
		Ihandle* vBoxScope = IupVbox( toggleAll, toggleSelection, null );
		IupSetAttributes( vBoxScope, "EXPAND=YES,EXPANDCHILDREN=YES" );
		Ihandle* radioScope = IupRadio( vBoxScope );
		Ihandle* frameScope = IupFrame( radioScope );
		IupSetAttribute( frameScope, "EXPAND", "YES");
		IupSetAttribute( frameScope, "TITLE", cStrings[7].toCString );

		Ihandle* hBox02 = IupHbox( frameDirection, frameScope, null );
		IupSetAttributes( hBox02, "EXPAND=YES,EXPANDCHILDREN=YES" );

		// Options
		cStrings[8] = new IupString( GLOBAL.languageItems["casesensitive"] );
		cStrings[9] = new IupString( GLOBAL.languageItems["wholeword"] );
		cStrings[10] = new IupString( GLOBAL.languageItems["options"] );
		
		Ihandle* toggleCaseSensitive = IupToggle( cStrings[8].toCString, null );
		IupSetAttributes( toggleCaseSensitive, "VALUE=ON,EXPAND=YES" );
		IupSetHandle( "toggleCaseSensitive", toggleCaseSensitive );
		IupSetCallback( toggleCaseSensitive, "ACTION", cast(Icallback) &CSearchDialog_toggleAction_cb );

		Ihandle* toggleWholeWord = IupToggle( cStrings[9].toCString, null );
		IupSetAttributes( toggleWholeWord, "VALUE=ON,EXPAND=YES" );
		IupSetCallback( toggleWholeWord, "ACTION", cast(Icallback) &CSearchDialog_toggleAction_cb );

		Ihandle* hBoxOption = IupHbox( toggleCaseSensitive, toggleWholeWord, null );
		IupSetAttributes( hBoxOption, "EXPAND=YES" );
		Ihandle* frameOption = IupFrame( hBoxOption );
		IupSetAttributes( frameOption, "EXPAND=YES,MARGIN=0x0");
		IupSetAttribute( frameOption, "TITLE", cStrings[10].toCString );


		cStrings[11] = new IupString( GLOBAL.languageItems["find"] );
		cStrings[12] = new IupString( GLOBAL.languageItems["replacefind"] );
		cStrings[13] = new IupString( GLOBAL.languageItems["replace"] );
		cStrings[14] = new IupString( GLOBAL.languageItems["replaceall"] );
		cStrings[15] = new IupString( GLOBAL.languageItems["countall"] );
		cStrings[16] = new IupString( GLOBAL.languageItems["bookmarkall"] );


		Ihandle* btnFind = IupButton( cStrings[11].toCString, null );
		IupSetHandle( "CSearchDialog_btnFind", btnFind );
		IupSetCallback( btnFind, "ACTION", cast(Icallback) &CSearchDialog_btnFind_cb );
		
		Ihandle* btnReplaceFind = IupButton( cStrings[12].toCString, null );
		IupSetHandle( "btnReplaceFind", btnReplaceFind );
		IupSetCallback( btnReplaceFind, "ACTION", cast(Icallback) &CSearchDialog_btnReplaceFind_cb );
		
		Ihandle* btnReplace = IupButton( cStrings[13].toCString, null );
		IupSetHandle( "btnReplace", btnReplace );
		IupSetCallback( btnReplace, "ACTION", cast(Icallback) &CSearchDialog_btnReplace_cb );
		
		Ihandle* btnReplaceAll = IupButton( cStrings[14].toCString, null );
		IupSetHandle( "btnReplaceAll", btnReplaceAll );
		IupSetCallback( btnReplaceAll, "ACTION", cast(Icallback) &CSearchDialog_btnReplaceAll_cb );
		
		Ihandle* btnCountAll = IupButton( cStrings[15].toCString, null );
		IupSetHandle( "btnCountAll", btnCountAll );
		IupSetCallback( btnCountAll, "ACTION", cast(Icallback) &CSearchDialog_btnCountAll_cb );
		
		Ihandle* btnMarkAll = IupButton( cStrings[16].toCString, null );
		IupSetHandle( "btnMarkAll", btnMarkAll );
		IupSetCallback( btnMarkAll, "ACTION", cast(Icallback) &CSearchDialog_btnMarkAll_cb );

		Ihandle* gbox = IupGridBox
		(
			IupSetAttributes( btnFind, "" ),
			IupSetAttributes( btnReplaceFind,"" ),

			IupSetAttributes( btnReplace, "" ),
			IupSetAttributes( btnReplaceAll, "" ),

			IupSetAttributes( btnCountAll, "" ),
			IupSetAttributes( btnMarkAll, "" ),

			null
		);
		IupSetAttributes( gbox, "EXPAND=YES,NUMDIV=2,ALIGNMENTLIN=ACENTER,EXPANDCHILDREN=YES,ALIGNMENTCOL=ARIGHT,GAPLIN=2,GAPCOL=1,MARGIN=0x0,SIZELIN=2" );


		Ihandle* labelSEPARATOR = IupLabel( null ); 
		IupSetAttribute( labelSEPARATOR, "SEPARATOR", "HORIZONTAL" );

		cStrings[17] = new IupString( GLOBAL.languageItems["status"] );
		labelStatus = IupLabel( cStrings[17].toCString );
		
		Ihandle* vBox = IupVbox( hBox00, hBox01, hBox02, frameOption, gbox, bottom, labelSEPARATOR, labelStatus, null );
		IupSetAttributes( vBox, "ALIGNMENT=ACENTER,MARGIN=5x5,GAP=2,EXPAND=YES,EXPANDCHILDREN=YES" );

		IupAppend( _dlg, vBox );
	}	

	public:

	int			searchRule = 6;
	
	this( int w, int h, char[] title, char[] findWhat = null, bool bResize = false, char[] parent = "MAIN_DIALOG" )
	{
		super( w, h, title, bResize, parent );
		IupSetAttribute( _dlg, "ICON", "icon_find" );
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

		IupSetAttribute( listFind, "VALUE",toStringz( findWhat ) );

		//IupSetAttribute( _dlg, "DEFAULTENTER", "CSearchDialog_btnFind" );
		IupSetHandle( "btnCANCEL_search", btnCANCEL );
		IupSetCallback( btnCANCEL, "ACTION", cast(Icallback) &CSearchDialog_btnCancel_cb );
		IupSetAttribute( _dlg, "DEFAULTESC", "btnCANCEL_search" );
		IupSetCallback( _dlg, "CLOSE_CB", cast(Icallback) &CSearchDialog_btnCancel_cb );
	}

	~this()
	{
		IupSetHandle( "CSearchDialog_listFind", null );
		IupSetHandle( "CSearchDialog_listReplace", null );

		IupSetHandle( "CSearchDialog_toggleForward", null );
		IupSetHandle( "CSearchDialog_toggleBackward", null );

		IupSetHandle( "btnCANCEL_search", null );
	}

	char[] show( char[] selectedWord ) // Overload form CBaseDialog
	{
		if( selectedWord.length ) IupSetAttribute( listFind, "VALUE",toStringz( selectedWord.dup ) );
		IupShow( _dlg );
		return null;
	}	

	char[] show( int x, int y ) // Overload form CBaseDialog
	{
		IupShowXY( _dlg, x, y );
		return null;
	}

	void setStatusBar( char[] text )
	{
		IupSetAttribute( labelStatus, "TITLE", toStringz( text.dup ) );
	}
}

extern(C) // Callback for CSingleTextDialog
{
	private int CSearchDialog_btnCancel_cb( Ihandle* ih )
	{
		if( GLOBAL.searchDlg !is null ) IupHide( GLOBAL.searchDlg._dlg );

		return IUP_DEFAULT;
	}

	private int CSearchDialog_listFind_K_ANY_CB( Ihandle *ih, int c ) 
	{
		if( c == 13 )
		{
			int pos = CSearchDialog_search();
			if( pos > -1 ) GLOBAL.searchDlg.setStatusBar( "Found Word." ); else GLOBAL.searchDlg.setStatusBar( "Find Nothing!" );
		}
		return IUP_DEFAULT;
	}

	private int CSearchDialog_listReplace_K_ANY_CB( Ihandle *ih, int c ) 
	{
		if( c  == 13 ) CSearchDialog_btnReplaceFind_cb();
		return IUP_DEFAULT;
	}

	private int CSearchDialog_toggleAction_cb( Ihandle* ih, int state )
	{
		if( IupGetHandle( "toggleCaseSensitive" ) == ih )
		//if( fromStringz(IupGetAttribute( ih, "TITLE" )) == "Case Sensitive" )
		{
			if( state == 1 ) GLOBAL.searchDlg.searchRule = GLOBAL.searchDlg.searchRule | 4;
			if( state == 0 ) GLOBAL.searchDlg.searchRule = GLOBAL.searchDlg.searchRule & 2;
		}
		else //"Whole Word"
		{
			if( state == 1 ) GLOBAL.searchDlg.searchRule = GLOBAL.searchDlg.searchRule | 2;
			if( state == 0 ) GLOBAL.searchDlg.searchRule = GLOBAL.searchDlg.searchRule & 4;
		}

		return IUP_DEFAULT;
	}

	private int CSearchDialog_search( bool bJumpSelect = true )
	{
		Ihandle* iupSci	= actionManager.ScintillaAction.getActiveIupScintilla();
		if( iupSci != null )
		{
			Ihandle* listFind_handle = IupGetHandle( "CSearchDialog_listFind" );
			if( listFind_handle != null )
			{
				char[] findText = fromStringz( IupGetAttribute( listFind_handle, "VALUE" ) );

				if( findText.length )
				{
					Ihandle* direction_handle = IupGetHandle( "CSearchDialog_toggleForward" );
					if( direction_handle != null )
					{
						bool bForward;
						if( fromStringz(IupGetAttribute( direction_handle, "VALUE" )) == "ON" ) bForward = true;

						actionManager.SearchAction.addListItem( listFind_handle, findText, 15 );
						
						return actionManager.SearchAction.search( iupSci, findText, GLOBAL.searchDlg.searchRule, bForward );
					}
				}
			}
		}

		return -1;
	}

	private int CSearchDialog_btnFind_cb()
	{
		GLOBAL.searchDlg.setStatusBar( "" );

		int pos = CSearchDialog_search();
		if( pos > -1 ) GLOBAL.searchDlg.setStatusBar( "Found Word." ); else GLOBAL.searchDlg.setStatusBar( "Find Nothing!" );
	
		return IUP_DEFAULT;;
	}

	private int CSearchDialog_btnReplaceFind_cb()
	{
		GLOBAL.searchDlg.setStatusBar( "" );
		int pos = -1;
		
		Ihandle* iupSci	= actionManager.ScintillaAction.getActiveIupScintilla();
		if( iupSci != null )
		{
			Ihandle* listFind_handle	= IupGetHandle( "CSearchDialog_listFind" );
			Ihandle* listReplace_handle	=  IupGetHandle( "CSearchDialog_listReplace" );
			if( listFind_handle != null && listReplace_handle != null )
			{
				char[] findText		= fromStringz( IupGetAttribute( listFind_handle, "VALUE" ) );
				char[] ReplaceText	= fromStringz( IupGetAttribute( listReplace_handle, "VALUE" ) );

				if( findText.length )
				{
					Ihandle* direction_handle = IupGetHandle( "CSearchDialog_toggleForward" );
					if( direction_handle != null )
					{
						char[] targetText = fromStringz(IupGetAttribute( iupSci, "SELECTEDTEXT" ));
						if( targetText == findText )
						{
							IupSetAttribute( iupSci, "SELECTEDTEXT", toStringz( ReplaceText ) );
						}
						
						
						if( fromStringz(IupGetAttribute( direction_handle, "VALUE" )) == "ON" )
						{
							pos = actionManager.SearchAction.search( iupSci, findText, GLOBAL.searchDlg.searchRule, true );
						}
						else
						{
							pos = actionManager.SearchAction.search( iupSci, findText, GLOBAL.searchDlg.searchRule, false );
						}
					}
				}
			}
		}

		return pos;
	}

	private int CSearchDialog_btnReplace_cb()
	{
		GLOBAL.searchDlg.setStatusBar( "" );
		
		Ihandle* iupSci	= actionManager.ScintillaAction.getActiveIupScintilla();
		if( iupSci != null )
		{
			Ihandle* listFind_handle	= IupGetHandle( "CSearchDialog_listFind" );
			Ihandle* listReplace_handle	=  IupGetHandle( "CSearchDialog_listReplace" );
			if( listFind_handle != null && listReplace_handle != null )
			{
				char[] findText		= fromStringz( IupGetAttribute( listFind_handle, "VALUE" ) );
				char[] ReplaceText	= fromStringz( IupGetAttribute( listReplace_handle, "VALUE" ) );

				if( findText.length )
				{
					Ihandle* direction_handle = IupGetHandle( "CSearchDialog_toggleForward" );
					if( direction_handle != null )
					{
						char[] targetText = fromStringz(IupGetAttribute( iupSci, "SELECTEDTEXT" ));
						if( targetText == findText )
						{
							IupSetAttribute( iupSci, "SELECTEDTEXT", toStringz( ReplaceText ) );
						}
					}
				}
			}
		}

		return IUP_DEFAULT;
	}

	private int CSearchDialog_btnReplaceAll_cb()
	{
		return CSearchDialogAction( 2 );
	}

	private int CSearchDialog_btnCountAll_cb()
	{
		return CSearchDialogAction( 0 );
	}

	private int CSearchDialog_btnMarkAll_cb()
	{
		return CSearchDialogAction( 1 );
	}

	/*
	flag = 0 CountALL
	flag = 1 MarkALL
	flag = 2 ReplaceALL
	*/
	private int CSearchDialogAction( int flag = 0 )
	{
		int counts;

		Ihandle* iupSci	= actionManager.ScintillaAction.getActiveIupScintilla();
		if( iupSci !is null )
		{
			Ihandle* listFind_handle	= IupGetHandle( "CSearchDialog_listFind" );
			Ihandle* listReplace_handle	= IupGetHandle( "CSearchDialog_listReplace" );
			
			if( listFind_handle != null && listReplace_handle != null )
			{
				char[] findText		= fromStringz( IupGetAttribute( listFind_handle, "VALUE" ) );
				char[] ReplaceText	= fromStringz( IupGetAttribute( listReplace_handle, "VALUE" ) );
				
				if( findText.length )
				{
					IupScintillaSendMessage( iupSci, 2198, GLOBAL.searchDlg.searchRule, 0 ); // SCI_SETSEARCHFLAGS = 2198,
					
					IupSetInt( iupSci, "TARGETSTART", 0 );
					IupSetInt( iupSci, "TARGETEND", 0 );

					int findPos = cast(int) IupScintillaSendMessage( iupSci, 2197, findText.length, cast(int) GLOBAL.cString.convert( findText ) ); //SCI_SEARCHINTARGET = 2197,
					while( findPos > -1 )
					{
						switch( flag )
						{
							case 1:
								int linNum = IupScintillaSendMessage( iupSci, 2166, findPos, 0 );// SCI_LINEFROMPOSITION = 2166
								if( !( IupGetIntId( iupSci, "MARKERGET", linNum ) & 2 ) ) IupSetIntId( iupSci, "MARKERADD", linNum, 1 );
								break;
							case 2:
								IupSetAttribute( iupSci, "REPLACETARGET", toStringz( ReplaceText ) );
								break;
							default:
						}
						
						counts ++;
						if( flag < 2 ) IupSetInt( iupSci, "TARGETSTART", findPos + findText.length ); else IupSetInt( iupSci, "TARGETSTART", findPos );
						IupSetInt( iupSci, "TARGETEND", 0 );
						findPos = cast(int) IupScintillaSendMessage( iupSci, 2197, findText.length, cast(int) GLOBAL.cString.convert( findText ) ); //SCI_SEARCHINTARGET = 2197,
					}
				}
			}
		}

		if( counts == 0 )
		{
			GLOBAL.searchDlg.setStatusBar( "Find nothing!" );
		}
		else
		{
			switch( flag )
			{
				case 0:	GLOBAL.searchDlg.setStatusBar( "Count total = " ~ Integer.toString( counts ) ~ " words." ); break;
				case 1:	GLOBAL.searchDlg.setStatusBar( "Mark total = " ~ Integer.toString( counts ) ~ " words." ); break;
				case 2: GLOBAL.searchDlg.setStatusBar( "Replace total = " ~ Integer.toString( counts ) ~ " words." ); break;
				default:
			}			
		}

		return IUP_DEFAULT;
	}
}