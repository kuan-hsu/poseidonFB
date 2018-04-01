module dialogs.searchDlg;

private import iup.iup, iup.iup_scintilla;

private import global, scintilla, actionManager;
private import dialogs.baseDlg;

private import tango.stdc.stringz;

/+
class CSearchDialog : CBaseDialog
{
	private:
	import				tools;
	
	Ihandle*			listFind, listReplace;
	Ihandle*			labelStatus, toggleSelection;
	IupString[2]		labelTitle;
	IupString			statusString;

	void createLayout()
	{
		Ihandle* bottom = createDlgButton( "40x16", "c");

		listFind = IupList( null );
		/*
		IupSetAttributes( listFind, "1=\"Console Application\",2=\"Static Library\",3=\"Dynamic Link Library\","
                                   "SHOWIMAGE=NO,VALUE=1,DROPDOWN=YES,EDITBOX=YES,SIZE=100x12,VISIBLE_ITEMS=3");
		*/
		IupSetAttributes( listFind, "SHOWIMAGE=NO,DROPDOWN=YES,EDITBOX=YES,SIZE=120x12,VISIBLE_ITEMS=3,NAME=list_Find");
		
		labelTitle[0] = new IupString( GLOBAL.languageItems["findwhat"].toDString ~ ":" );
		Ihandle* label0 = IupLabel( labelTitle[0].toCString );
		IupSetAttribute( label0, "SIZE", "60x16" );
		Ihandle* hBox00 = IupHbox( label0, listFind, null );
		IupSetAttributes( hBox00, "ALIGNMENT=ACENTER" );
		IupSetCallback( listFind, "K_ANY", cast(Icallback) &CSearchDialog_listFind_K_ANY_CB );


		listReplace = IupList( null );
		IupSetAttributes( listReplace, "SHOWIMAGE=NO,DROPDOWN=YES,EDITBOX=YES,SIZE=120x12,VISIBLE_ITEMS=3,NAME=list_Replace");
		
		labelTitle[1] = new IupString( GLOBAL.languageItems["replacewith"].toDString ~ ":" );
		Ihandle* label1 = IupLabel( labelTitle[1].toCString );
		IupSetAttribute( label1, "SIZE", "60x16" );
		Ihandle* hBox01 = IupHbox( label1, listReplace, null );
		IupSetAttributes( hBox01, "ALIGNMENT=ACENTER" );
		IupSetCallback( listReplace, "K_ANY", cast(Icallback) &CSearchDialog_listReplace_K_ANY_CB );

		Ihandle* toggleForward = IupToggle( GLOBAL.languageItems["forward"].toCString, null );
		IupSetAttributes( toggleForward, "RADIO=YES,NAME=toggle_Forward");
		
		Ihandle* toggleBackward = IupToggle( GLOBAL.languageItems["backward"].toCString, null );
		IupSetAttributes( toggleBackward, "RADIO=YES,NAME=toggle_Backward");
		
		Ihandle* vBoxDirection = IupVbox( toggleForward, toggleBackward, null );
		IupSetAttributes( vBoxDirection, "EXPAND=YES,EXPANDCHILDREN=YES" );
		Ihandle* radioDirection = IupRadio( vBoxDirection );
		Ihandle* frameDirection = IupFrame( radioDirection );
		IupSetAttributes( frameDirection, "EXPAND=YES");
		
		IupSetAttribute( frameDirection, "TITLE", GLOBAL.languageItems["direction"].toCString );


		Ihandle* toggleAll = IupToggle( GLOBAL.languageItems["all"].toCString, null );
		IupSetAttributes( toggleAll, "RADIO=YES");
		IupSetCallback( toggleAll, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			Ihandle* _ih = IupGetDialogChild( GLOBAL.searchDlg.getIhandle, "btn_Find" );
			if( _ih != null ) IupSetAttribute( _ih, "ACTIVE", "YES" );
			_ih = IupGetDialogChild( GLOBAL.searchDlg.getIhandle, "btn_ReplaceFind" );
			if( _ih != null ) IupSetAttribute( _ih, "ACTIVE", "YES" );
			_ih = IupGetDialogChild( GLOBAL.searchDlg.getIhandle, "btn_Replace" );
			if( _ih != null ) IupSetAttribute( _ih, "ACTIVE", "YES" );

			return IUP_DEFAULT;
		});			
		
		toggleSelection = IupToggle( GLOBAL.languageItems["selection"].toCString, null );
		IupSetAttributes( toggleSelection, "RADIO=YES,NAME=toggle_Selection");
		IupSetCallback( toggleSelection, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			Ihandle* _ih = IupGetDialogChild( GLOBAL.searchDlg.getIhandle, "btn_Find" );
			if( _ih != null ) IupSetAttribute( _ih, "ACTIVE", "NO" );
			_ih = IupGetDialogChild( GLOBAL.searchDlg.getIhandle, "btn_ReplaceFind" );
			if( _ih != null ) IupSetAttribute( _ih, "ACTIVE", "NO" );
			_ih = IupGetDialogChild( GLOBAL.searchDlg.getIhandle, "btn_Replace" );
			if( _ih != null ) IupSetAttribute( _ih, "ACTIVE", "NO" );

			return IUP_DEFAULT;
		});					
		
		//IupSetAttribute( toggleSelection, "ACTIVE", "NO" );
		Ihandle* vBoxScope = IupVbox( toggleAll, toggleSelection, null );
		IupSetAttributes( vBoxScope, "EXPAND=YES,EXPANDCHILDREN=YES" );
		Ihandle* radioScope = IupRadio( vBoxScope );
		Ihandle* frameScope = IupFrame( radioScope );
		IupSetAttribute( frameScope, "EXPAND", "YES");
		IupSetAttribute( frameScope, "TITLE", GLOBAL.languageItems["scope"].toCString );

		Ihandle* hBox02 = IupHbox( frameDirection, frameScope, null );
		IupSetAttributes( hBox02, "EXPAND=YES,EXPANDCHILDREN=YES" );

		// Options
		Ihandle* toggleCaseSensitive = IupToggle( GLOBAL.languageItems["casesensitive"].toCString, null );
		IupSetAttributes( toggleCaseSensitive, "VALUE=ON,EXPAND=YES,NAME=toggle_CaseSensitive" );
		IupSetCallback( toggleCaseSensitive, "ACTION", cast(Icallback) &CSearchDialog_toggleAction_cb );

		Ihandle* toggleWholeWord = IupToggle( GLOBAL.languageItems["wholeword"].toCString, null );
		IupSetAttributes( toggleWholeWord, "VALUE=ON,EXPAND=YES" );
		IupSetCallback( toggleWholeWord, "ACTION", cast(Icallback) &CSearchDialog_toggleAction_cb );

		Ihandle* hBoxOption = IupHbox( toggleCaseSensitive, toggleWholeWord, null );
		IupSetAttributes( hBoxOption, "EXPAND=YES" );
		Ihandle* frameOption = IupFrame( hBoxOption );
		IupSetAttributes( frameOption, "EXPAND=YES,MARGIN=0x0");
		IupSetAttribute( frameOption, "TITLE", GLOBAL.languageItems["options"].toCString );



		Ihandle* btnFind = IupButton( GLOBAL.languageItems["find"].toCString, null );
		IupSetAttributes( btnFind, "SIZE=x12,NAME=btn_Find" );
		IupSetCallback( btnFind, "ACTION", cast(Icallback) &CSearchDialog_btnFind_cb );
		
		Ihandle* btnReplaceFind = IupButton( GLOBAL.languageItems["replacefind"].toCString, null );
		IupSetAttributes( btnReplaceFind, "SIZE=x12,NAME=btn_ReplaceFind" );
		IupSetCallback( btnReplaceFind, "ACTION", cast(Icallback) &CSearchDialog_btnReplaceFind_cb );
		
		Ihandle* btnReplace = IupButton( GLOBAL.languageItems["replace"].toCString, null );
		IupSetAttributes( btnReplace, "SIZE=x12,NAME=btn_Replace" );
		IupSetCallback( btnReplace, "ACTION", cast(Icallback) &CSearchDialog_btnReplace_cb );
		
		Ihandle* btnReplaceAll = IupButton( GLOBAL.languageItems["replaceall"].toCString, null );
		IupSetAttribute( btnReplaceAll, "SIZE", "x12" );
		IupSetCallback( btnReplaceAll, "ACTION", cast(Icallback) &CSearchDialog_btnReplaceAll_cb );
		
		Ihandle* btnCountAll = IupButton( GLOBAL.languageItems["countall"].toCString, null );
		IupSetAttribute( btnCountAll,"SIZE","x12" );
		IupSetCallback( btnCountAll, "ACTION", cast(Icallback) &CSearchDialog_btnCountAll_cb );
		
		Ihandle* btnMarkAll = IupButton( GLOBAL.languageItems["bookmarkall"].toCString, null );
		IupSetAttribute( btnMarkAll,"SIZE","x12" );
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

		labelStatus = IupLabel( GLOBAL.languageItems["status"].toCString );
		
		Ihandle* vBox = IupVbox( hBox00, hBox01, hBox02, frameOption, gbox, bottom, labelSEPARATOR, labelStatus, null );
		IupSetAttributes( vBox, "ALIGNMENT=ACENTER,MARGIN=5x5,GAP=2,EXPAND=YES,EXPANDCHILDREN=YES" );
		version( Windows ) IupSetAttribute( vBox, "FONTFACE", "Courier New" ); else IupSetAttribute( vBox, "FONT", "Ubuntu Mono, 10" );

		IupAppend( _dlg, vBox );
	}	

	public:

	int			searchRule = 6;
	
	this( int w, int h, char[] title, char[] findWhat = null, bool bResize = false, char[] parent = "MAIN_DIALOG" )
	{
		super( w, h, title, bResize, parent );
		IupSetAttribute( _dlg, "ICON", "icon_find" );
		IupSetAttribute( _dlg, "MINBOX", "NO" );
		
		statusString = new IupString;
		
		version( Windows )
		{
			IupSetAttribute( _dlg, "FONT", GLOBAL.cString.convert( "Courier New,9" ) );
		}
		else
		{
			IupSetAttribute( _dlg, "FONT", GLOBAL.cString.convert( "Ubuntu Mono, 10" ) );;
		}		

		createLayout();
		IupSetAttribute( listFind, "VALUE",toStringz( findWhat ) );

		IupSetAttribute( _dlg, "DEFAULTENTER", null );
		IupSetHandle( "btnCANCEL_search", btnCANCEL );
		IupSetCallback( btnCANCEL, "ACTION", cast(Icallback) &CSearchDialog_btnCancel_ACTION_CB );
		IupSetAttribute( _dlg, "DEFAULTESC", "btnCANCEL_search" );
		IupSetCallback( _dlg, "CLOSE_CB", cast(Icallback) &CSearchDialog_btnCancel_ACTION_CB );
		
		IupSetAttribute( _dlg, "OPACITY", toStringz( GLOBAL.editorSetting02.searchDlg ) );
		IupMap( _dlg );
	}

	~this()
	{
		IupSetHandle( "btnCANCEL_search", null );
	}

	char[] show( char[] selectedWord ) // Overload form CBaseDialog
	{
		if( selectedWord.length ) IupSetAttribute( listFind, "VALUE",toStringz( selectedWord.dup ) );else IupSetAttribute( listFind, "VALUE", "" );
		if( fromStringz( IupGetAttribute( toggleSelection, "VALUE" ) ) == "ON" ) IupSetAttribute( listFind, "VALUE", "" );
		
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
		statusString = text;
		IupSetAttribute( labelStatus, "TITLE", statusString.toCString );
	}
}

extern(C) // Callback for CSingleTextDialog
{
	private int CSearchDialog_btnCancel_ACTION_CB( Ihandle* ih )
	{
		if( GLOBAL.searchDlg !is null ) IupHide( GLOBAL.searchDlg._dlg );

		return IUP_DEFAULT;
	}

	private int CSearchDialog_listFind_K_ANY_CB( Ihandle *ih, int c ) 
	{
		if( c == 13 )
		{
			auto cSci = ScintillaAction.getActiveCScintilla();
			if( cSci !is null )
			{
				GLOBAL.navigation.addCache( cSci.getFullPath, ScintillaAction.getCurrentLine( cSci.getIupScintilla ) );
				GLOBAL.navigation.eraseTail();
			}
			
			int pos = CSearchDialog_search();
			if( pos > -1 )
			{
				if( cSci !is null ) GLOBAL.navigation.addCache( cSci.getFullPath, ScintillaAction.getCurrentLine( cSci.getIupScintilla ) );
				GLOBAL.searchDlg.setStatusBar( GLOBAL.languageItems["foundword"].toDString );
			}
			else
			{
				if( cSci !is null ) GLOBAL.navigation.eraseTail();
				GLOBAL.searchDlg.setStatusBar( GLOBAL.languageItems["foundnothing"].toDString );
			}
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
		if( IupGetDialogChild( GLOBAL.searchDlg.getIhandle, "toggle_CaseSensitive" ) == ih )
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
			Ihandle* listFind_handle = IupGetDialogChild( GLOBAL.searchDlg.getIhandle, "list_Find" );
			if( listFind_handle != null )
			{
				char[] findText = fromStringz( IupGetAttribute( listFind_handle, "VALUE" ) ).dup;

				if( findText.length )
				{
					Ihandle* direction_handle = IupGetDialogChild( GLOBAL.searchDlg.getIhandle, "toggle_Forward" );
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

		auto cSci = ScintillaAction.getActiveCScintilla();
		if( cSci !is null )
		{
			GLOBAL.navigation.addCache( cSci.getFullPath, ScintillaAction.getCurrentLine( cSci.getIupScintilla ) );
			GLOBAL.navigation.eraseTail();
		}
		
		int pos = CSearchDialog_search();
		if( pos > -1 )
		{
			if( cSci !is null ) GLOBAL.navigation.addCache( cSci.getFullPath, ScintillaAction.getCurrentLine( cSci.getIupScintilla ) );
			GLOBAL.searchDlg.setStatusBar( GLOBAL.languageItems["foundword"].toDString );
		}
		else
		{
			if( cSci !is null ) GLOBAL.navigation.eraseTail();
			GLOBAL.searchDlg.setStatusBar( GLOBAL.languageItems["foundnothing"].toDString );
		}
	
		return IUP_DEFAULT;;
	}

	private int CSearchDialog_btnReplaceFind_cb()
	{
		GLOBAL.searchDlg.setStatusBar( "" );
		int pos = -1;
		
		Ihandle* iupSci	= actionManager.ScintillaAction.getActiveIupScintilla();
		if( iupSci != null )
		{
			Ihandle* listFind_handle	= IupGetDialogChild( GLOBAL.searchDlg.getIhandle, "list_Find" );
			Ihandle* listReplace_handle	= IupGetDialogChild( GLOBAL.searchDlg.getIhandle, "list_Replace" );
			if( listFind_handle != null && listReplace_handle != null )
			{
				char[] findText		= fromStringz( IupGetAttribute( listFind_handle, "VALUE" ) ).dup;
				char[] ReplaceText	= fromStringz( IupGetAttribute( listReplace_handle, "VALUE" ) ).dup;

				if( findText.length )
				{
					actionManager.SearchAction.addListItem( listFind_handle, findText, 15 );
					if( ReplaceText.length ) actionManager.SearchAction.addListItem( listReplace_handle, ReplaceText, 15 );
					
					Ihandle* direction_handle = IupGetDialogChild( GLOBAL.searchDlg.getIhandle, "toggle_Forward" );
					if( direction_handle != null )
					{
						char[] targetText = fromStringz(IupGetAttribute( iupSci, "SELECTEDTEXT" )).dup;
						
						if( targetText.length )
						{
							if( targetText == findText )
							{
								if( !ReplaceText.length )
									IupScintillaSendMessage( iupSci, 2194, -1, 0  ); // SCI_REPLACETARGET 2194
								else
									IupSetAttribute( iupSci, "SELECTEDTEXT", toStringz( ReplaceText ) );
								
								DocumentTabAction.setFocus( iupSci );
							}
						}
						
						if( fromStringz( IupGetAttribute( direction_handle, "VALUE" )) == "ON" )
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
			Ihandle* listFind_handle	= IupGetDialogChild( GLOBAL.searchDlg.getIhandle, "list_Find" );
			Ihandle* listReplace_handle	= IupGetDialogChild( GLOBAL.searchDlg.getIhandle, "list_Replace" );
			if( listFind_handle != null && listReplace_handle != null )
			{
				char[] findText		= fromStringz( IupGetAttribute( listFind_handle, "VALUE" ) ).dup;
				char[] ReplaceText	= fromStringz( IupGetAttribute( listReplace_handle, "VALUE" ) ).dup;

				if( findText.length )
				{
					if( ReplaceText.length ) actionManager.SearchAction.addListItem( listReplace_handle, ReplaceText, 15 );
					
					Ihandle* direction_handle = IupGetDialogChild( GLOBAL.searchDlg.getIhandle, "toggle_Forward" );
					if( direction_handle != null )
					{
						char[] targetText = fromStringz(IupGetAttribute( iupSci, "SELECTEDTEXT" )).dup;
						if( targetText == findText )
						{
							if( !ReplaceText.length )
								IupScintillaSendMessage( iupSci, 2194, -1, 0  ); // SCI_REPLACETARGET 2194
							else
								IupSetAttribute( iupSci, "SELECTEDTEXT", toStringz( ReplaceText ) );
							
							DocumentTabAction.setFocus( iupSci );
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
			Ihandle* listFind_handle	= IupGetDialogChild( GLOBAL.searchDlg.getIhandle, "list_Find" );
			Ihandle* listReplace_handle	= IupGetDialogChild( GLOBAL.searchDlg.getIhandle, "list_Replace" );
			
			if( listFind_handle != null && listReplace_handle != null )
			{
				char[] findText		= fromStringz( IupGetAttribute( listFind_handle, "VALUE" ) ).dup;
				char[] ReplaceText	= fromStringz( IupGetAttribute( listReplace_handle, "VALUE" ) ).dup;
				
				if( findText.length )
				{
					bool	bScopeSelection;
					Ihandle* _ih = IupGetDialogChild( GLOBAL.searchDlg.getIhandle, "toggle_Selection" );
					if( _ih != null )
					{
						if( fromStringz( IupGetAttribute( _ih, "VALUE" ) ) == "ON" )
						{
							IupSetAttribute( iupSci, "TARGETFROMSELECTION", "YES" );
							bScopeSelection = true;
						}
						else
						{
							IupSetAttribute( iupSci, "TARGETWHOLEDOCUMENT", "YES" );
						}
					}
					else
					{
						return IUP_DEFAULT;
					}

					IupScintillaSendMessage( iupSci, 2198, GLOBAL.searchDlg.searchRule, 0 );	// SCI_SETSEARCHFLAGS = 2198,
					
					actionManager.SearchAction.addListItem( listFind_handle, findText, 15 );
					if( flag == 2 && ReplaceText.length ) actionManager.SearchAction.addListItem( listReplace_handle, ReplaceText, 15 );
					

					int findPos = cast(int) IupScintillaSendMessage( iupSci, 2197, findText.length, cast(int) GLOBAL.cString.convert( findText ) ); //SCI_SEARCHINTARGET = 2197,
					while( findPos > -1 )
					{
						switch( flag )
						{
							case 1:
								int linNum = cast(int) IupScintillaSendMessage( iupSci, 2166, findPos, 0 );// SCI_LINEFROMPOSITION = 2166
								if( !( IupGetIntId( iupSci, "MARKERGET", linNum ) & 2 ) ) IupSetIntId( iupSci, "MARKERADD", linNum, 1 );
								break;
							case 2:
								if( !ReplaceText.length )
									IupScintillaSendMessage( iupSci, 2194, -1, 0  ); // SCI_REPLACETARGET 2194
								else
									IupSetAttribute( iupSci, "REPLACETARGET", toStringz( ReplaceText ) );
								break;
							default:
						}
						
						counts ++;
						
						if( !bScopeSelection ) IupSetInt( iupSci, "TARGETEND", -1 ); else IupSetAttribute( iupSci, "TARGETFROMSELECTION", "YES" );
						//if( flag < 2 ) IupSetInt( iupSci, "TARGETSTART", findPos + findText.length ); else IupSetInt( iupSci, "TARGETSTART", findPos );
						if( flag < 2 ) IupSetInt( iupSci, "TARGETSTART", findPos + findText.length ); else IupSetInt( iupSci, "TARGETSTART", findPos + ReplaceText.length );
						
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
+/




class CSearchExpander
{
	private:
	import				tools;
	
	Ihandle*			expander;
	IupString[2] 		labelTitle, findButton;

	void createLayout()
	{
		// Group 0
		labelTitle[0] = new IupString( " " ~ GLOBAL.languageItems["findwhat"].toDString ~ ":" );
		labelTitle[1] = new IupString( " " ~ GLOBAL.languageItems["replacewith"].toDString ~ ":" );
		findButton[0] = new IupString( GLOBAL.languageItems["find"].toDString ~ " ^" );
		findButton[1] = new IupString( GLOBAL.languageItems["find"].toDString ~ " v" );
		
		Ihandle* label0 = IupLabel( labelTitle[0].toCString );
		IupSetAttribute( label0, "SIZE", "x12" );	
		
		Ihandle* label1 = IupLabel( labelTitle[1].toCString );
		IupSetAttribute( label1, "SIZE", "x12" );	
		
		Ihandle* _group0 = IupVbox( label0, label1, null );
		
		// Group 1
		Ihandle* listFind = IupList( "" );
		IupSetAttribute( listFind, "EXPAND","HORIZONTAL" );
		IupSetAttributes( listFind, "DROPDOWN=YES,EDITBOX=YES,NAME=list_Find" );
		IupSetCallback( listFind, "K_ANY", cast(Icallback) &CSearchExpander_listFind_K_ANY );
		
		Ihandle* listReplace = IupList( "" );
		IupSetAttribute( listReplace, "EXPAND","HORIZONTAL" );
		IupSetAttributes( listReplace, "DROPDOWN=YES,EDITBOX=YES,NAME=list_Replace" );
		IupSetCallback( listReplace, "K_ANY", cast(Icallback) &CSearchDialog_listReplace_K_ANY );
		
		Ihandle* _group1 = IupVbox( listFind, listReplace, null );
		
		// Group 2
		Ihandle* btnFindPrev = IupButton( findButton[0].toCString, null ); // GLOBAL.languageItems["find"]
		IupSetAttributes( btnFindPrev, "SIZE=x12,NAME=btn_FindPrev,FLAT=YES,FONTSTYLE=Underline" );
		IupSetCallback( btnFindPrev, "ACTION", cast(Icallback) &CSearchExpander_Find_ACTION );

		Ihandle* btnFindNext = IupButton( findButton[1].toCString, null );
		IupSetAttributes( btnFindNext, "SIZE=x12,NAME=btn_FindNext,FLAT=YES,FONTSTYLE=Underline" );
		IupSetCallback( btnFindNext, "ACTION", cast(Icallback) &CSearchExpander_Find_ACTION );

		Ihandle* btnReplaceFind = IupButton( GLOBAL.languageItems["replacefind"].toCString, null );
		IupSetAttributes( btnReplaceFind, "SIZE=x12,NAME=btn_ReplaceFind,FLAT=YES,FONTSTYLE=Underline" );
		IupSetCallback( btnReplaceFind, "ACTION", cast(Icallback) &CSearchExpander_btnReplaceFind_ACTION );
		
		Ihandle* btnReplace = IupButton( GLOBAL.languageItems["replace"].toCString, null );
		IupSetAttributes( btnReplace, "SIZE=x12,NAME=btn_Replace,FLAT=YES,FONTSTYLE=Underline" );
		IupSetCallback( btnReplace, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			//GLOBAL.searchDlg.setStatusBar( "" );
			GLOBAL.statusBar.setFindMessage( "" );
		
			Ihandle* iupSci	= actionManager.ScintillaAction.getActiveIupScintilla();
			if( iupSci != null )
			{
				Ihandle* listFind_handle	= IupGetDialogChild( GLOBAL.searchExpander.getHandle, "list_Find" );
				Ihandle* listReplace_handle	= IupGetDialogChild( GLOBAL.searchExpander.getHandle, "list_Replace" );
				if( listFind_handle != null && listReplace_handle != null )
				{
					char[] findText		= fromStringz( IupGetAttribute( listFind_handle, "VALUE" ) ).dup;
					char[] ReplaceText	= fromStringz( IupGetAttribute( listReplace_handle, "VALUE" ) ).dup;

					if( findText.length )
					{
						if( ReplaceText.length ) actionManager.SearchAction.addListItem( listReplace_handle, ReplaceText, 15 );
						
						Ihandle* direction_handle = IupGetDialogChild( GLOBAL.searchExpander.getHandle, "toggle_Direction" );
						if( direction_handle != null )
						{
							char[] targetText = fromStringz(IupGetAttribute( iupSci, "SELECTEDTEXT" )).dup;
							if( targetText == findText )
							{
								if( !ReplaceText.length )
									IupScintillaSendMessage( iupSci, 2194, -1, 0  ); // SCI_REPLACETARGET 2194
								else
									IupSetAttribute( iupSci, "SELECTEDTEXT", toStringz( ReplaceText ) );
								
								DocumentTabAction.setFocus( iupSci );
							}
						}
					}
				}
			}

			return IUP_DEFAULT;
		});		
		
		Ihandle* btnReplaceAll = IupButton( GLOBAL.languageItems["replaceall"].toCString, null );
		IupSetAttributes( btnReplaceAll, "SIZE=x12,NAME=btn_ReplaceAll,FLAT=YES,FONTSTYLE=Underline" );
		IupSetCallback( btnReplaceAll, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			CSearchExpanderAction( 2 );
		});
		
		Ihandle* btnMarkAll = IupButton( GLOBAL.languageItems["bookmarkall"].toCString, null );
		IupSetAttributes( btnMarkAll,"SIZE=x12,NAME=btn_MarkAll,FLAT=YES,FONTSTYLE=Underline" );
		IupSetCallback( btnMarkAll, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			CSearchExpanderAction( 1 );
		});
		
		Ihandle* _group2 = IupGridBox
		(
			IupSetAttributes( btnFindPrev, "" ),	IupSetAttributes( btnFindNext,"" ),		IupSetAttributes( btnMarkAll, "" ),
			IupSetAttributes( btnReplace, "" ),		IupSetAttributes( btnReplaceFind, "" ),	IupSetAttributes( btnReplaceAll, "" ),
			null
		);
		IupSetAttributes( _group2, "EXPAND=YES,NUMDIV=3,ALIGNMENTLIN=ACENTER,ALIGNMENTCOL=ARIGHT,NORMALIZESIZE=HORIZONTAL,HOMOGENEOUSCOL=YES,GAPLIN=2,GAPCOL=1,MARGIN=0x0,SIZELIN=-1" );		
		
		
		// Group 3
		Ihandle* btnCase = IupToggle( null, null );
		IupSetAttributes( btnCase, "IMAGE=icon_casesensitive,FLAT=YES,VALUE=ON,NAME=toggle_Case,SIZE=x12" );
		IupSetAttribute( btnCase, "TIP", GLOBAL.languageItems["casesensitive"].toCString );
		IupSetCallback( btnCase, "ACTION", cast(Icallback) &CSearchExpander_Toggle_ACTION );

		Ihandle* btnWhole = IupToggle( null, null );
		IupSetAttributes( btnWhole, "IMAGE=icon_wholeword,FLAT=YES,VALUE=ON,NAME=toggle_Whole,SIZE=x12" );
		IupSetAttribute( btnWhole, "TIP", GLOBAL.languageItems["wholeword"].toCString );
		IupSetCallback( btnWhole, "ACTION", cast(Icallback) &CSearchExpander_Toggle_ACTION );

		Ihandle* btnScope = IupToggle( null, null );
		IupSetAttributes( btnScope, "IMAGE=icon_selectall,FLAT=YES,VALUE=ON,NAME=toggle_Scope,SIZE=x12" );
		IupSetAttribute( btnScope, "TIP", GLOBAL.languageItems["scope"].toCString );
		//IupSetCallback( btnScope, "ACTION", cast(Icallback) &CSearchExpander_Toggle_ACTION );

		Ihandle* btnDirection = IupToggle( null, null );
		IupSetAttributes( btnDirection, "IMPRESS=icon_downarrow,IMAGE=icon_uparrow,FLAT=YES,VALUE=ON,NAME=toggle_Direction,SIZE=x12" );
		IupSetAttribute( btnDirection, "TIP", GLOBAL.languageItems["direction"].toCString );
		//IupSetCallback( btnDirection, "ACTION", cast(Icallback) &CSearchExpander_Toggle_ACTION );
		
		Ihandle* btnClose = IupButton( null, null );
		IupSetAttributes( btnClose, "IMAGE=icon_close,FLAT=YES,NAME=btn_Close,SIZE=x12" );
		IupSetCallback( btnClose, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			GLOBAL.searchExpander.contract();
			Ihandle* iupSci	= actionManager.ScintillaAction.getActiveIupScintilla();
			if( iupSci != null ) IupSetFocus( iupSci );
		});
		/*
		Ihandle* btnCase = IupFlatButton( null );
		IupSetAttributes( btnCase, "IMAGE=icon_casesensitive,VALUE=ON,NAME=toggle_Case,TOGGLE=YES,SIZE=16x12" );
		IupSetAttribute( btnCase, "TIP", GLOBAL.languageItems["casesensitive"].toCString );
		IupSetCallback( btnCase, "FLAT_ACTION", cast(Icallback) &CSearchExpander_Toggle_ACTION );		

		Ihandle* btnWhole = IupFlatButton( null );
		IupSetAttributes( btnWhole, "IMAGE=icon_wholeword,VALUE=ON,NAME=toggle_Whole,TOGGLE=YES,SIZE=16x12" );
		IupSetAttribute( btnWhole, "TIP", GLOBAL.languageItems["wholeword"].toCString );
		IupSetCallback( btnWhole, "FLAT_ACTION", cast(Icallback) &CSearchExpander_Toggle_ACTION );

		Ihandle* btnScope = IupFlatButton( null );
		IupSetAttributes( btnScope, "IMAGE=icon_selectall,VALUE=ON,NAME=toggle_Scope,TOGGLE=YES,SIZE=16x12" );
		IupSetAttribute( btnScope, "TIP", GLOBAL.languageItems["scope"].toCString );

		Ihandle* btnDirection = IupFlatButton( null );
		IupSetAttributes( btnDirection, "IMPRESS=icon_downarrow,IMAGE=icon_uparrow,VALUE=ON,NAME=toggle_Direction,TOGGLE=YES,SIZE=16x12" );
		IupSetAttribute( btnDirection, "TIP", GLOBAL.languageItems["direction"].toCString );
		
		Ihandle* btnClose = IupFlatButton( null );
		IupSetAttributes( btnClose, "IMAGE=icon_close,NAME=btn_Close,SIZE=16x12" );
		IupSetCallback( btnClose, "FLAT_ACTION", cast(Icallback) function( Ihandle* ih )
		{
			GLOBAL.statusBar.setFindMessage( "" );
			GLOBAL.searchExpander.contract();
			Ihandle* iupSci	= actionManager.ScintillaAction.getActiveIupScintilla();
			if( iupSci != null ) DocumentTabAction.setFocus( iupSci );
		});
		*/
		
		Ihandle* _group3 = IupGridBox
		(
			btnCase,	btnScope,		btnClose,
			btnWhole,	btnDirection,	IupFill(),
			null
		);
		IupSetAttributes( _group3, "EXPAND=YES,NUMDIV=3,ALIGNMENTLIN=ACENTER,ALIGNMENTCOL=ARIGHT,NORMALIZESIZE=HORIZONTAL,HOMOGENEOUSCOL=YES,GAPLIN=2,GAPCOL=1,MARGIN=0x0,SIZELIN=-1" );		
		
		expander = IupExpander( IupHbox( _group0, _group1, _group2, _group3, null ) );
		IupSetAttributes( expander, "BARSIZE=0,STATE=CLOSE,BARPOSITION=BOTTOM" );
		Ihandle* _backgroundbox = IupGetChild( expander, 0 );
		if( _backgroundbox != null ) IupSetAttribute( _backgroundbox, "VISIBLE", "NO" ); // Hide Title Image 
	}	

	public:
	
	int			searchRule = 6;
	
	this()
	{
		createLayout();
	}
	
	~this(){}
	
	Ihandle* getHandle()
	{
		return expander;
	}
	
	void expand()
	{
		IupSetAttribute( expander, "STATE", "OPEN" );
	}

	void contract()
	{
		IupSetAttribute( expander, "STATE", "CLOSE" );
		GLOBAL.statusBar.setFindMessage( "" );
	}

	bool isVisible()
	{
		if( fromStringz( IupGetAttribute( expander, "STATE" ) ) == "OPEN" ) return true;
		
		return false;
	}
	
	void show( char[] selectedWord )
	{
		Ihandle* _find = IupGetDialogChild( expander, "list_Find" );
		if( _find != null )
		{
			if( selectedWord.length ) IupSetAttribute( _find, "VALUE",toStringz( selectedWord.dup ) );// else IupSetAttribute( _find, "VALUE", "" );
			
			Ihandle* _scope = IupGetDialogChild( expander, "toggle_Scope" );
			if( _scope != null )
			{
				if( fromStringz( IupGetAttribute( _scope, "VALUE" ) ) == "OFF" ) IupSetAttribute( _find, "VALUE", "" );
			}
		}
		
		expand();
		
		if( _find != null ) IupSetFocus( _find );
	}
}

extern(C)
{
	/*
	diection		= 0  follow toggle_Direction button
	diection		= 1  Backward
	diection		>= 2 Forward
	*/
	private int CSearchExpander_search( int direction = 0 )
	{
		Ihandle* iupSci	= actionManager.ScintillaAction.getActiveIupScintilla();
		if( iupSci != null )
		{
			Ihandle* listFind_handle = IupGetDialogChild( GLOBAL.searchExpander.getHandle, "list_Find" );
			if( listFind_handle != null )
			{
				char[] findText = fromStringz( IupGetAttribute( listFind_handle, "VALUE" ) ).dup;

				if( findText.length )
				{
					if( direction == 0 )
					{
						Ihandle* direction_handle = IupGetDialogChild( GLOBAL.searchExpander.getHandle, "toggle_Direction" );
						if( direction_handle != null )
						{
							bool bForward;
							if( fromStringz( IupGetAttribute( direction_handle, "VALUE" )) == "ON" )
							{
								bForward = true;
								IupSetAttribute( iupSci, "SELECTIONPOS", IupGetAttribute( iupSci, "SELECTIONPOS" ) );
							}
							else
							{
								char[] beginEndPos = fromStringz( IupGetAttribute( iupSci, "SELECTIONPOS" ) );
								if( beginEndPos.length )
								{
									int colonPos = Util.index( beginEndPos, ":" );
									if( colonPos < beginEndPos.length )
									{
										char[] newBeginEndPos = beginEndPos[colonPos+1..length] ~ ":" ~ beginEndPos[0..colonPos];
										IupSetAttribute( iupSci, "SELECTIONPOS", toStringz( newBeginEndPos.dup ) );
									}
								}
							}

							actionManager.SearchAction.addListItem( listFind_handle, findText, 15 );
							
							return actionManager.SearchAction.search( iupSci, findText, GLOBAL.searchExpander.searchRule, bForward );
						}
					}
					else if( direction == 1 )
					{
						actionManager.SearchAction.addListItem( listFind_handle, findText, 15 );
						return actionManager.SearchAction.search( iupSci, findText, GLOBAL.searchExpander.searchRule, false );
					}
					else
					{
						actionManager.SearchAction.addListItem( listFind_handle, findText, 15 );
						return actionManager.SearchAction.search( iupSci, findText, GLOBAL.searchExpander.searchRule, true );
					}
				}
			}
		}

		return -1;
	}
	

	/*
	flag = 0 CountALL
	flag = 1 MarkALL
	flag = 2 ReplaceALL
	*/
	private int CSearchExpanderAction( int flag = 0 )
	{
		int counts;

		Ihandle* iupSci	= actionManager.ScintillaAction.getActiveIupScintilla();
		if( iupSci != null )
		{
			Ihandle* listFind_handle	= IupGetDialogChild( GLOBAL.searchExpander.getHandle, "list_Find" );
			Ihandle* listReplace_handle	= IupGetDialogChild( GLOBAL.searchExpander.getHandle, "list_Replace" );
			
			if( listFind_handle != null && listReplace_handle != null )
			{
				char[] findText		= fromStringz( IupGetAttribute( listFind_handle, "VALUE" ) ).dup;
				char[] ReplaceText	= fromStringz( IupGetAttribute( listReplace_handle, "VALUE" ) ).dup;
				
				if( findText.length )
				{
					bool	bScopeSelection;
					Ihandle* _ih = IupGetDialogChild( GLOBAL.searchExpander.getHandle, "toggle_Scope" );
					if( _ih != null )
					{
						if( fromStringz( IupGetAttribute( _ih, "VALUE" ) ) == "ON" )
						{
							IupSetAttribute( iupSci, "TARGETWHOLEDOCUMENT", "YES" );
						}
						else
						{
							IupSetAttribute( iupSci, "TARGETFROMSELECTION", "YES" );
							bScopeSelection = true;
						}
					}
					else
					{
						return IUP_DEFAULT;
					}

					IupScintillaSendMessage( iupSci, 2198, GLOBAL.searchExpander.searchRule, 0 );	// SCI_SETSEARCHFLAGS = 2198,
					
					actionManager.SearchAction.addListItem( listFind_handle, findText, 15 );
					if( flag == 2 && ReplaceText.length ) actionManager.SearchAction.addListItem( listReplace_handle, ReplaceText, 15 );

					int findPos = cast(int) IupScintillaSendMessage( iupSci, 2197, findText.length, cast(int) GLOBAL.cString.convert( findText ) ); //SCI_SEARCHINTARGET = 2197,
					while( findPos > -1 )
					{
						switch( flag )
						{
							case 1:
								int linNum = cast(int) IupScintillaSendMessage( iupSci, 2166, findPos, 0 );// SCI_LINEFROMPOSITION = 2166
								if( !( IupGetIntId( iupSci, "MARKERGET", linNum ) & 2 ) ) IupSetIntId( iupSci, "MARKERADD", linNum, 1 );
								break;
							case 2:
								if( !ReplaceText.length )
									IupScintillaSendMessage( iupSci, 2194, -1, 0  ); // SCI_REPLACETARGET 2194
								else
									IupSetAttribute( iupSci, "REPLACETARGET", toStringz( ReplaceText ) );
								break;
							default:
						}
						
						counts ++;
						
						if( !bScopeSelection ) IupSetInt( iupSci, "TARGETEND", -1 ); else IupSetAttribute( iupSci, "TARGETFROMSELECTION", "YES" );
						if( flag < 2 ) IupSetInt( iupSci, "TARGETSTART", findPos + findText.length ); else IupSetInt( iupSci, "TARGETSTART", findPos + ReplaceText.length );
						
						findPos = cast(int) IupScintillaSendMessage( iupSci, 2197, findText.length, cast(int) GLOBAL.cString.convert( findText ) ); //SCI_SEARCHINTARGET = 2197,
					}
				}
			}
		}

		if( counts == 0 )
		{
			GLOBAL.statusBar.setFindMessage( GLOBAL.languageItems["foundnothing"].toDString );
		}
		else
		{
			switch( flag )
			{
				//case 0:	GLOBAL.searchDlg.setStatusBar( "Count total = " ~ Integer.toString( counts ) ~ " words." ); break;
				case 1:	GLOBAL.statusBar.setFindMessage( "Mark total = " ~ Integer.toString( counts ) ~ " words." ); break;
				case 2: GLOBAL.statusBar.setFindMessage( "Replace total = " ~ Integer.toString( counts ) ~ " words." ); break;
				default:
			}			
		}

		return IUP_DEFAULT;
	}	
	
	private int CSearchExpander_Find_ACTION( Ihandle* ih )
	{
		auto cSci = ScintillaAction.getActiveCScintilla();
		if( cSci !is null )
		{
			GLOBAL.navigation.addCache( cSci.getFullPath, ScintillaAction.getCurrentLine( cSci.getIupScintilla ) );
			GLOBAL.navigation.eraseTail();
		}
		else
		{
			return IUP_DEFAULT;;
		}
		
		int pos;
		if( fromStringz( IupGetAttribute( ih, "NAME" ) ) == "btn_FindPrev" )
		{
			char[] beginEndPos = fromStringz( IupGetAttribute( cSci.getIupScintilla, "SELECTIONPOS" ) );
			if( beginEndPos.length )
			{
				int colonPos = Util.index( beginEndPos, ":" );
				if( colonPos < beginEndPos.length )
				{
					char[] newBeginEndPos = beginEndPos[colonPos+1..length] ~ ":" ~ beginEndPos[0..colonPos];
					IupSetAttribute( cSci.getIupScintilla, "SELECTIONPOS", toStringz( newBeginEndPos.dup ) );
				}
			}
		
			pos = CSearchExpander_search( 1 );
		}
		else
		{
			IupSetAttribute( cSci.getIupScintilla, "SELECTIONPOS", IupGetAttribute( cSci.getIupScintilla, "SELECTIONPOS" ) );
			pos = CSearchExpander_search( 2 );
		}

		if( pos > -1 )
		{
			GLOBAL.navigation.addCache( cSci.getFullPath, ScintillaAction.getCurrentLine( cSci.getIupScintilla ) );
			GLOBAL.statusBar.setFindMessage( GLOBAL.languageItems["foundword"].toDString );
		}
		else
		{
			GLOBAL.navigation.eraseTail();
			GLOBAL.statusBar.setFindMessage( GLOBAL.languageItems["foundnothing"].toDString );
		}
		
		return IUP_DEFAULT;;
	}
	
	private int CSearchExpander_Toggle_ACTION( Ihandle* ih )
	{
		char[]	name = fromStringz( IupGetAttribute( ih, "NAME" ) );
		char[]	value = fromStringz( IupGetAttribute( ih, "VALUE" ) );
		
		//IupMessage("",IupGetAttribute( ih, "VALUE" ) );
		switch( name )
		{
			case "toggle_Case":
				if( value == "ON" ) GLOBAL.searchExpander.searchRule = GLOBAL.searchExpander.searchRule | 4; else GLOBAL.searchExpander.searchRule = GLOBAL.searchExpander.searchRule & 2;
				break;
			case "toggle_Whole":
				if( value == "ON" ) GLOBAL.searchExpander.searchRule = GLOBAL.searchExpander.searchRule | 2; else GLOBAL.searchExpander.searchRule = GLOBAL.searchExpander.searchRule & 4;
				break;
			default:
		}
		
		return IUP_DEFAULT;;
	}
	
	private int CSearchExpander_btnReplaceFind_ACTION()
	{
		Ihandle* iupSci	= actionManager.ScintillaAction.getActiveIupScintilla();
		if( iupSci != null )
		{
			Ihandle* listFind_handle	= IupGetDialogChild( GLOBAL.searchExpander.getHandle, "list_Find" );
			Ihandle* listReplace_handle	= IupGetDialogChild( GLOBAL.searchExpander.getHandle, "list_Replace" );
			if( listFind_handle != null && listReplace_handle != null )
			{
				char[] findText		= fromStringz( IupGetAttribute( listFind_handle, "VALUE" ) ).dup;
				char[] ReplaceText	= fromStringz( IupGetAttribute( listReplace_handle, "VALUE" ) ).dup;

				if( findText.length )
				{
					actionManager.SearchAction.addListItem( listFind_handle, findText, 15 );
					if( ReplaceText.length ) actionManager.SearchAction.addListItem( listReplace_handle, ReplaceText, 15 );
					
					Ihandle* direction_handle = IupGetDialogChild( GLOBAL.searchExpander.getHandle, "toggle_Direction" );
					if( direction_handle != null )
					{
						char[] targetText = fromStringz(IupGetAttribute( iupSci, "SELECTEDTEXT" )).dup;
						
						if( targetText.length )
						{
							if( targetText == findText )
							{
								if( !ReplaceText.length )
									IupScintillaSendMessage( iupSci, 2194, -1, 0  ); // SCI_REPLACETARGET 2194
								else
									IupSetAttribute( iupSci, "SELECTEDTEXT", toStringz( ReplaceText ) );
								
								DocumentTabAction.setFocus( iupSci );
							}
						}
						
						if( fromStringz( IupGetAttribute( direction_handle, "VALUE" )) == "ON" )
						{
							actionManager.SearchAction.search( iupSci, findText, GLOBAL.searchExpander.searchRule, true );
						}
						else
						{
							actionManager.SearchAction.search( iupSci, findText, GLOBAL.searchExpander.searchRule, false );
						}
					}
				}
			}
		}

		return IUP_DEFAULT;
	}	
	
	private int CSearchExpander_listFind_K_ANY( Ihandle *ih, int c ) 
	{
		auto cSci = ScintillaAction.getActiveCScintilla();
		if( cSci !is null )
		{
			if( c == 13 )
			{
				GLOBAL.navigation.addCache( cSci.getFullPath, ScintillaAction.getCurrentLine( cSci.getIupScintilla ) );
				GLOBAL.navigation.eraseTail();
				
				int pos = CSearchExpander_search( 0 );
				if( pos > -1 )
				{
					GLOBAL.navigation.addCache( cSci.getFullPath, ScintillaAction.getCurrentLine( cSci.getIupScintilla ) );
					GLOBAL.statusBar.setFindMessage( GLOBAL.languageItems["foundword"].toDString );
				}
				else
				{
					GLOBAL.navigation.eraseTail();
					GLOBAL.statusBar.setFindMessage( GLOBAL.languageItems["foundnothing"].toDString );
				}
			}
			else if( c == 65307 ) // ESC = 65307
			{
				GLOBAL.searchExpander.contract();
				IupSetFocus( cSci.getIupScintilla );
			}
		}
		else
		{
			if( c == 65307 ) GLOBAL.searchExpander.contract(); // ESC = 65307
		}
	
		return IUP_DEFAULT;
	}

	private int CSearchDialog_listReplace_K_ANY( Ihandle *ih, int c ) 
	{
		Ihandle* iupSci	= actionManager.ScintillaAction.getActiveIupScintilla();
		if( iupSci != null )
		{
			if( c == 13 )
			{
				CSearchExpander_btnReplaceFind_ACTION();
			}
			else if( c == 65307 ) // ESC = 65307
			{
				GLOBAL.searchExpander.contract();
				IupSetFocus( iupSci );
			}
		}
		else
		{
			if( c == 65307 ) GLOBAL.searchExpander.contract(); // ESC = 65307
		}
		
		return IUP_DEFAULT;
	}	
}