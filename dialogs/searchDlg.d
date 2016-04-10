module dialogs.searchDlg;

private import iup.iup, iup.iup_scintilla;

private import global, scintilla, actionManager;
private import dialogs.baseDlg;

private import tango.stdc.stringz;

class CSearchDialog : CBaseDialog
{
	private:
	Ihandle*	listFind, listReplace;
	Ihandle*	labelStatus;

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
		Ihandle* hBox00 = IupHbox( IupLabel( "Find What:   " ), listFind, null );
		IupSetAttributes( hBox00, "ALIGNMENT=ACENTER" );
		IupSetCallback( listFind, "K_ANY", cast(Icallback) &CSearchDialog_listFind_K_ANY_CB );


		listReplace = IupList( null );
		IupSetAttributes( listReplace, "SHOWIMAGE=NO,DROPDOWN=YES,EDITBOX=YES,SIZE=120x12,VISIBLE_ITEMS=3");
		IupSetHandle( "CSearchDialog_listReplace", listReplace );
		Ihandle* hBox01 = IupHbox( IupLabel( "Replace With:" ), listReplace, null );
		IupSetAttributes( hBox01, "ALIGNMENT=ACENTER" );
		IupSetCallback( listReplace, "K_ANY", cast(Icallback) &CSearchDialog_listReplace_K_ANY_CB );

		Ihandle* toggleForward = IupToggle( "Forward", null );
		IupSetAttributes( toggleForward, "RADIO=YES");
		IupSetHandle( "CSearchDialog_toggleForward", toggleForward );
		
		Ihandle* toggleBackward = IupToggle( "Backward", null );
		IupSetAttributes( toggleBackward, "RADIO=YES");
		IupSetHandle( "CSearchDialog_toggleBackward", toggleBackward );
		
		Ihandle* vBoxDirection = IupVbox( toggleForward, toggleBackward, null );
		IupSetAttributes( vBoxDirection, "EXPAND=YES,EXPANDCHILDREN=YES" );
		Ihandle* radioDirection = IupRadio( vBoxDirection );
		Ihandle* frameDirection = IupFrame( radioDirection );
		IupSetAttributes( frameDirection, "TITLE=Direction,EXPAND=YES");		

		Ihandle* toggleAll = IupToggle( "All", null );
		IupSetAttributes( toggleAll, "RADIO=YES");		
		Ihandle* toggleSelection = IupToggle( "Selection", null );
		IupSetAttributes( toggleSelection, "RADIO=YES");
		Ihandle* vBoxScope = IupVbox( toggleAll, toggleSelection, null );
		IupSetAttributes( vBoxScope, "EXPAND=YES,EXPANDCHILDREN=YES" );
		Ihandle* radioScope = IupRadio( vBoxScope );
		Ihandle* frameScope = IupFrame( radioScope );
		IupSetAttributes( frameScope, "TITLE=Scope,EXPAND=YES");

		Ihandle* hBox02 = IupHbox( frameDirection, frameScope, null );
		IupSetAttributes( hBox02, "EXPAND=YES,EXPANDCHILDREN=YES" );

		// Options
		Ihandle* toggleCaseSensitive = IupToggle( "Case Sensitive", null );
		IupSetAttributes( toggleCaseSensitive, "VALUE=ON,EXPAND=YES" );
		IupSetCallback( toggleCaseSensitive, "ACTION", cast(Icallback) &CSearchDialog_toggleAction_cb );

		Ihandle* toggleWholeWord = IupToggle( "Whole Word", null );
		IupSetAttributes( toggleWholeWord, "VALUE=ON,EXPAND=YES" );
		IupSetCallback( toggleWholeWord, "ACTION", cast(Icallback) &CSearchDialog_toggleAction_cb );

		Ihandle* hBoxOption = IupHbox( toggleCaseSensitive, toggleWholeWord, null );
		IupSetAttributes( hBoxOption, "EXPAND=YES" );
		Ihandle* frameOption = IupFrame( hBoxOption );
		IupSetAttributes( frameOption, "TITLE=Options,EXPAND=YES,MARGIN=0x0");


		Ihandle* btnFind = IupButton( "Find", null );
		IupSetHandle( "CSearchDialog_btnFind", btnFind );
		IupSetCallback( btnFind, "ACTION", cast(Icallback) &CSearchDialog_btnFind_cb );
		
		Ihandle* btnReplaceFind = IupButton( "Replace/Find", null );
		IupSetHandle( "btnReplaceFind", btnReplaceFind );
		IupSetCallback( btnReplaceFind, "ACTION", cast(Icallback) &CSearchDialog_btnReplaceFind_cb );
		
		Ihandle* btnReplace = IupButton( "Replace", null );
		IupSetHandle( "btnReplace", btnReplace );
		IupSetCallback( btnReplace, "ACTION", cast(Icallback) &CSearchDialog_btnReplace_cb );
		
		Ihandle* btnReplaceAll = IupButton( "Replace All", null );
		IupSetHandle( "btnReplaceAll", btnReplaceAll );
		IupSetCallback( btnReplaceAll, "ACTION", cast(Icallback) &CSearchDialog_btnReplaceAll_cb );
		
		Ihandle* btnCountAll = IupButton( "Count All", null );
		IupSetHandle( "btnCountAll", btnCountAll );
		IupSetCallback( btnCountAll, "ACTION", cast(Icallback) &CSearchDialog_btnCountAll_cb );
		
		Ihandle* btnMarkAll = IupButton( "Mark All", null );
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

		labelStatus = IupLabel( "Status Bar" );
		
		Ihandle* vBox = IupVbox( hBox00, hBox01, hBox02, frameOption, gbox, bottom, labelSEPARATOR, labelStatus, null );
		IupSetAttributes( vBox, "ALIGNMENT=ACENTER,MARGIN=5x5,GAP=2,EXPAND=YES,EXPANDCHILDREN=YES" );

		IupAppend( _dlg, vBox );
	}	

	public:

	int			searchRule = 3;
	
	this( int w, int h, char[] title, char[] findWhat = null, bool bResize = false, char[] parent = "MAIN_DIALOG" )
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
		if( selectedWord.length ) IupSetAttribute( listFind, "VALUE",toStringz( selectedWord ) );
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
		IupSetAttribute( labelStatus, "TITLE", toStringz( text ) );
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
		if( fromStringz(IupGetAttribute( ih, "TITLE" )) == "Case Sensitive" )
		{
			if( state == 1 ) GLOBAL.searchDlg.searchRule = GLOBAL.searchDlg.searchRule | 1;
			if( state == 0 ) GLOBAL.searchDlg.searchRule = GLOBAL.searchDlg.searchRule & 2;
		}
		else //"Whole Word"
		{
			if( state == 1 ) GLOBAL.searchDlg.searchRule = GLOBAL.searchDlg.searchRule | 2;
			if( state == 0 ) GLOBAL.searchDlg.searchRule = GLOBAL.searchDlg.searchRule & 1;
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
						
						return actionManager.SearchAction.search( iupSci, findText, GLOBAL.searchDlg.searchRule, bForward, bJumpSelect );
					}
				}
			}
		}

		return -1;
	}

	private int CSearchDialog_btnFind_cb()
	{
		GLOBAL.searchDlg.setStatusBar( "" );

		//int pos = actionManager.SearchAction.search();
		int pos = CSearchDialog_search();

		if( pos > -1 ) GLOBAL.searchDlg.setStatusBar( "Found Word." ); else GLOBAL.searchDlg.setStatusBar( "Find Nothing!" );

		/+
		int pos = -1;
		
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
						if( fromStringz(IupGetAttribute( direction_handle, "VALUE" )) == "ON" )
						{
							pos = actionManager.SearchAction.findNext( iupSci, findText, GLOBAL.searchDlg.searchRule );
						}
						else
						{
							pos = actionManager.SearchAction.findPrev( iupSci, findText, GLOBAL.searchDlg.searchRule );
						}
					}		
				}
			}
		}

		if( pos > -1 ) GLOBAL.searchDlg.setStatusBar( "Found Word." ); else GLOBAL.searchDlg.setStatusBar( "Find Nothing!" );
		+/
		
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
							//IupScintillaSendMessage( iupSci, 2170, 0, cast(long) toStringz(ReplaceText.dup) ); // SCI_REPLACESEL = 2170
						}
						
						
						if( fromStringz(IupGetAttribute( direction_handle, "VALUE" )) == "ON" )
						{
							pos = actionManager.SearchAction.findNext( iupSci, findText, GLOBAL.searchDlg.searchRule );
						}
						else
						{
							pos = actionManager.SearchAction.findPrev( iupSci, findText, GLOBAL.searchDlg.searchRule );
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
		int counts;
		int pos;

		Ihandle* iupSci	= actionManager.ScintillaAction.getActiveIupScintilla();
		if( iupSci !is null )
		{
			int 	OriginPos;
			bool	bU_trun;
			char[]	OriginValue;

			Ihandle* direction_handle = IupGetHandle( "CSearchDialog_toggleForward" );
			if( direction_handle != null )
			{
				// Change direction_handle
				OriginValue = fromStringz(IupGetAttribute( direction_handle, "VALUE" ));
				IupSetAttribute( direction_handle, "VALUE", "ON" );
			
				while( pos > -1 )
				{
					pos = CSearchDialog_btnReplaceFind_cb();

					if( !bU_trun )
					{
						if( pos < OriginPos ) bU_trun = true;
						if( pos == OriginPos ) break;
						
					}
					else
					{
						if( pos >= OriginPos ) break;
					}

					if( counts == 0 ) OriginPos = pos;
					if( pos > -1 ) counts ++;
				}

				// Re-change direction_handle
				IupSetAttribute( direction_handle, "VALUE", toStringz(OriginValue) );
			}
		}

		if( counts == 0 ) GLOBAL.searchDlg.setStatusBar( "Find nothing!" ); else GLOBAL.searchDlg.setStatusBar( "Replace " ~ Integer.toString( counts ) ~ " words." );

		return IUP_DEFAULT;
	}

	private int CSearchDialog_btnCountAll_cb()
	{
		int counts;
		int pos;

		Ihandle* iupSci	= actionManager.ScintillaAction.getActiveIupScintilla();
		if( iupSci !is null )
		{
			int 	OriginPos;
			bool	bU_trun;
			char[]	OriginValue, OriginSelectPos;

			Ihandle* direction_handle = IupGetHandle( "CSearchDialog_toggleForward" );
			if( direction_handle != null )
			{
				// Change direction_handle
				OriginValue = fromStringz(IupGetAttribute( direction_handle, "VALUE" ));
				IupSetAttribute( direction_handle, "VALUE", "ON" );

				OriginSelectPos = fromStringz( IupGetAttribute( iupSci, "SELECTIONPOS" ) );
				
				while( pos > -1 )
				{
					//pos = actionManager.SearchAction.search( false );//CSearchDialog_btnFind_cb();
					pos = CSearchDialog_search( false );

					if( !bU_trun )
					{
						if( pos < OriginPos ) bU_trun = true;
						if( pos == OriginPos ) break;
						
					}
					else
					{
						if( pos >= OriginPos ) break;
					}

					if( counts == 0 ) OriginPos = pos;
					if( pos > -1 ) counts ++;
				}

				// Re-change direction_handle
				IupSetAttribute( direction_handle, "VALUE", toStringz(OriginValue) );
			}

			IupSetAttribute( iupSci, "SELECTIONPOS", toStringz( OriginSelectPos ) );
			IupScintillaSendMessage( iupSci, 2163, 0, 0 ); // SCI_HIDESELECTION = 2163,
		}

		if( counts == 0 ) GLOBAL.searchDlg.setStatusBar( "Find nothing!" ); else GLOBAL.searchDlg.setStatusBar( "Count total = " ~ Integer.toString( counts ) ~ " words." );

		return IUP_DEFAULT;
	}

	private int CSearchDialog_btnMarkAll_cb()
	{
		int counts;
		int pos;

		Ihandle* iupSci	= actionManager.ScintillaAction.getActiveIupScintilla();
		if( iupSci != null )
		{
			int 	OriginPos;
			bool	bU_trun;
			char[]	OriginValue, OriginSelectPos;

			Ihandle* direction_handle = IupGetHandle( "CSearchDialog_toggleForward" );
			if( direction_handle != null )
			{
				// Change direction_handle
				OriginValue = fromStringz(IupGetAttribute( direction_handle, "VALUE" ));
				IupSetAttribute( direction_handle, "VALUE", "ON" );

				OriginSelectPos = fromStringz( IupGetAttribute( iupSci, "SELECTIONPOS" ) );
			
				while( pos > -1 )
				{
					//pos = actionManager.SearchAction.search( false );//CSearchDialog_btnFind_cb();
					pos = CSearchDialog_search( false );

					if( !bU_trun )
					{
						if( pos < OriginPos ) bU_trun = true;
						if( pos == OriginPos ) break;
						
					}
					else
					{
						if( pos >= OriginPos ) break;
					}

					if( counts == 0 ) OriginPos = pos;
					if( pos > -1 ) counts ++;else break;

					int linNum = IupScintillaSendMessage( iupSci, 2166, pos, 0 );// SCI_LINEFROMPOSITION = 2166
					if( !( IupGetIntId( iupSci, "MARKERGET", linNum ) & 2 ) ) IupSetIntId( iupSci, "MARKERADD", linNum, 1 );
				}

				// Re-change direction_handle
				IupSetAttribute( direction_handle, "VALUE", toStringz(OriginValue) );
			}

			IupSetAttribute( iupSci, "SELECTIONPOS", toStringz( OriginSelectPos ) );
			IupScintillaSendMessage( iupSci, 2163, 0, 0 ); // SCI_HIDESELECTION = 2163,
		}

		if( counts == 0 ) GLOBAL.searchDlg.setStatusBar( "Find nothing!" ); else GLOBAL.searchDlg.setStatusBar( "Mark total = " ~ Integer.toString( counts ) ~ " words." );

		return IUP_DEFAULT;
	}	
}