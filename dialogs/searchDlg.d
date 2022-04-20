module dialogs.searchDlg;

private import iup.iup, iup.iup_scintilla;

private import global, tools, scintilla, actionManager;
private import dialogs.baseDlg;

private import tango.stdc.stringz;

class CSearchExpander
{
	private:
	import				tools;
	
	Ihandle*			btnFindPrev, btnFindNext, btnReplaceFind, btnReplace, btnReplaceAll, btnMarkAll;
	Ihandle*			btnCase, btnScope, btnClose, btnWhole, btnDirection;
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
		btnFindPrev = IupFlatButton( findButton[0].toCString ); // GLOBAL.languageItems["find"]
		IupSetAttributes( btnFindPrev, "SIZE=x12,NAME=btn_FindPrev,FLAT=YES,FONTSTYLE=Underline" );
		IupSetCallback( btnFindPrev, "FLAT_ACTION", cast(Icallback) &CSearchExpander_Find_ACTION );

		btnFindNext = IupFlatButton( findButton[1].toCString );
		IupSetAttributes( btnFindNext, "SIZE=x12,NAME=btn_FindNext,FLAT=YES,FONTSTYLE=Underline" );
		IupSetCallback( btnFindNext, "FLAT_ACTION", cast(Icallback) &CSearchExpander_Find_ACTION );

		btnReplaceFind = IupFlatButton( GLOBAL.languageItems["replacefind"].toCString );
		IupSetAttributes( btnReplaceFind, "SIZE=x12,NAME=btn_ReplaceFind,FLAT=YES,FONTSTYLE=Underline" );
		IupSetCallback( btnReplaceFind, "FLAT_ACTION", cast(Icallback) &CSearchExpander_btnReplaceFind_ACTION );
		
		btnReplace = IupFlatButton( GLOBAL.languageItems["replace"].toCString );
		IupSetAttributes( btnReplace, "SIZE=x12,NAME=btn_Replace,FLAT=YES,FONTSTYLE=Underline" );
		IupSetCallback( btnReplace, "FLAT_ACTION", cast(Icallback) function( Ihandle* ih )
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
		
		btnReplaceAll = IupFlatButton( GLOBAL.languageItems["replaceall"].toCString );
		IupSetAttributes( btnReplaceAll, "SIZE=x12,NAME=btn_ReplaceAll,FLAT=YES,FONTSTYLE=Underline" );
		IupSetCallback( btnReplaceAll, "FLAT_ACTION", cast(Icallback) function( Ihandle* ih )
		{
			CSearchExpanderAction( 2 );
		});
		
		btnMarkAll = IupFlatButton( GLOBAL.languageItems["bookmarkall"].toCString );
		IupSetAttributes( btnMarkAll,"SIZE=x12,NAME=btn_MarkAll,FLAT=YES,FONTSTYLE=Underline" );
		IupSetCallback( btnMarkAll, "FLAT_ACTION", cast(Icallback) function( Ihandle* ih )
		{
			CSearchExpanderAction( 1 );
		});
		
		Ihandle* _group2 = IupGridBox
		(
			btnFindPrev,	btnFindNext,		btnMarkAll,
			btnReplace,		btnReplaceFind,		btnReplaceAll,
			null
		);
		IupSetAttributes( _group2, "EXPAND=YES,NUMDIV=3,ALIGNMENTLIN=ACENTER,ALIGNMENTCOL=ARIGHT,NORMALIZESIZE=HORIZONTAL,HOMOGENEOUSCOL=YES,GAPLIN=2,GAPCOL=1,MARGIN=0x0,SIZELIN=-1" );		
		
		
		// Group 3
		btnCase = IupToggle( null, null );
		IupSetAttributes( btnCase, "IMAGE=icon_casesensitive,FLAT=YES,NAME=toggle_Case,SIZE=x12" );
		version(DIDE) IupSetAttribute( btnCase, "VALUE", "ON" );
		version(FBIDE) IupSetAttribute( btnCase, "VALUE", "OFF" );
		IupSetAttribute( btnCase, "TIP", GLOBAL.languageItems["casesensitive"].toCString );
		IupSetCallback( btnCase, "ACTION", cast(Icallback) &CSearchExpander_Toggle_ACTION );

		btnWhole = IupToggle( null, null );
		IupSetAttributes( btnWhole, "IMAGE=icon_wholeword,FLAT=YES,VALUE=ON,NAME=toggle_Whole,SIZE=x12" );
		IupSetAttribute( btnWhole, "TIP", GLOBAL.languageItems["wholeword"].toCString );
		IupSetCallback( btnWhole, "ACTION", cast(Icallback) &CSearchExpander_Toggle_ACTION );

		btnScope = IupToggle( null, null );
		IupSetAttributes( btnScope, "IMAGE=icon_selectall,FLAT=YES,VALUE=ON,NAME=toggle_Scope,SIZE=x12" );
		IupSetAttribute( btnScope, "TIP", GLOBAL.languageItems["scope"].toCString );
		//IupSetCallback( btnScope, "ACTION", cast(Icallback) &CSearchExpander_Toggle_ACTION );

		btnDirection = IupToggle( null, null );
		IupSetAttributes( btnDirection, "IMPRESS=icon_downarrow,IMAGE=icon_uparrow,FLAT=YES,VALUE=ON,NAME=toggle_Direction,SIZE=x12" );
		IupSetAttribute( btnDirection, "TIP", GLOBAL.languageItems["direction"].toCString );
		//IupSetCallback( btnDirection, "ACTION", cast(Icallback) &CSearchExpander_Toggle_ACTION );
		
		btnClose = IupButton( null, null );
		IupSetAttributes( btnClose, "IMAGE=icon_close,FLAT=YES,NAME=btn_Close,SIZE=x12" );
		IupSetCallback( btnClose, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			GLOBAL.searchExpander.contract();
			Ihandle* iupSci	= actionManager.ScintillaAction.getActiveIupScintilla();
			if( iupSci != null ) IupSetFocus( iupSci );
		});
		
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
	
	// SCFIND_WHOLEWORD = 2, SCFIND_MATCHCASE = 4
	version(FBIDE)
		int			searchRule = 2;
	else
		int			searchRule = 6;
		
	this()
	{
		createLayout();
		changeColor();
	}
	
	void changeColor()
	{
		IupSetStrAttribute( btnFindPrev, "HLCOLOR", null );
		IupSetStrAttribute( btnFindNext, "HLCOLOR", null );
		IupSetStrAttribute( btnReplaceFind, "HLCOLOR", null );
		IupSetStrAttribute( btnReplace, "HLCOLOR", null );
		IupSetStrAttribute( btnReplaceAll, "HLCOLOR", null );
		IupSetStrAttribute( btnMarkAll, "HLCOLOR", null );
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
										char[] newBeginEndPos = beginEndPos[colonPos+1..$] ~ ":" ~ beginEndPos[0..colonPos];
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
					
					scope _t = new IupString( findText );

					int findPos = cast(int) IupScintillaSendMessage( iupSci, 2197, findText.length, cast(int) _t.toCString ); //SCI_SEARCHINTARGET = 2197,
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
									IupSetStrAttribute( iupSci, "REPLACETARGET", toStringz( ReplaceText ) );
								break;
							default:
						}
						
						counts ++;
						
						if( !bScopeSelection ) IupSetInt( iupSci, "TARGETEND", -1 ); else IupSetAttribute( iupSci, "TARGETFROMSELECTION", "YES" );
						if( flag < 2 ) IupSetInt( iupSci, "TARGETSTART", findPos + findText.length ); else IupSetInt( iupSci, "TARGETSTART", findPos + ReplaceText.length );
						
						findPos = cast(int) IupScintillaSendMessage( iupSci, 2197, findText.length, cast(int) _t.toCString ); //SCI_SEARCHINTARGET = 2197,
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
			IupSetFocus( ScintillaAction.getActiveIupScintilla );
		}

		return IUP_DEFAULT;
	}	
	
	private int CSearchExpander_Find_ACTION( Ihandle* ih )
	{
		auto cSci = ScintillaAction.getActiveCScintilla();
		if( cSci !is null )
			GLOBAL.navigation.addCache();
		else
			return IUP_DEFAULT;
		
		int		pos;
		char[]	beginEndPos = fromStringz( IupGetAttribute( cSci.getIupScintilla, "SELECTIONPOS" ) );
		
		if( fromStringz( IupGetAttribute( ih, "NAME" ) ) == "btn_FindPrev" )
		{
			if( beginEndPos.length )
			{
				int colonPos = Util.index( beginEndPos, ":" );
				if( colonPos < beginEndPos.length )
				{
					char[] newBeginEndPos = beginEndPos[colonPos+1..$] ~ ":" ~ beginEndPos[0..colonPos];
					IupSetAttribute( cSci.getIupScintilla, "SELECTIONPOS", toStringz( newBeginEndPos.dup ) );
				}
			}
		
			pos = CSearchExpander_search( 1 );
		}
		else
		{
			if( beginEndPos.length ) IupSetAttribute( cSci.getIupScintilla, "SELECTIONPOS", toStringz( beginEndPos.dup ) );
			
			pos = CSearchExpander_search( 2 );
		}

		if( pos > -1 )
		{
			GLOBAL.navigation.addCache();
			GLOBAL.statusBar.setFindMessage( GLOBAL.languageItems["foundword"].toDString );
			actionManager.StatusBarAction.update();
			IupSetFocus( ScintillaAction.getActiveIupScintilla );
		}
		else
		{
			GLOBAL.statusBar.setFindMessage( GLOBAL.languageItems["foundnothing"].toDString );
		}
		
		return IUP_DEFAULT;
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
		
		IupSetFocus( ScintillaAction.getActiveIupScintilla );
		
		return IUP_DEFAULT;
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
							actionManager.StatusBarAction.update();
						}
						else
						{
							actionManager.SearchAction.search( iupSci, findText, GLOBAL.searchExpander.searchRule, false );
							actionManager.StatusBarAction.update();
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
				GLOBAL.navigation.addCache();
				
				int pos = CSearchExpander_search( 0 );
				if( pos > -1 )
				{
					GLOBAL.navigation.addCache();
					GLOBAL.statusBar.setFindMessage( GLOBAL.languageItems["foundword"].toDString );
					actionManager.StatusBarAction.update();
				}
				else
				{
					GLOBAL.statusBar.setFindMessage( GLOBAL.languageItems["foundnothing"].toDString );
				}
			}
			else if( c == 65307 ) // ESC = 65307
			{
				GLOBAL.searchExpander.contract();
				IupSetFocus( cSci.getIupScintilla );
			}
			else
			{
				foreach( ShortKey sk; GLOBAL.shortKeys )
				{
					if( sk.name == "findnext" )
					{
						if( c == sk.keyValue )
						{
							char[]	beginEndPos = fromStringz( IupGetAttribute( cSci.getIupScintilla, "SELECTIONPOS" ) );
							if( beginEndPos.length ) IupSetAttribute( cSci.getIupScintilla, "SELECTIONPOS", toStringz( beginEndPos.dup ) );
							
							CSearchExpander_search( 2 );
							actionManager.StatusBarAction.update();
							break;
						}
					}
					else if( sk.name == "findprev" )
					{
						if( c == sk.keyValue )
						{
							char[]	beginEndPos = fromStringz( IupGetAttribute( cSci.getIupScintilla, "SELECTIONPOS" ) );
							if( beginEndPos.length )
							{
								int colonPos = Util.index( beginEndPos, ":" );
								if( colonPos < beginEndPos.length )
								{
									char[] newBeginEndPos = beginEndPos[colonPos+1..$] ~ ":" ~ beginEndPos[0..colonPos];
									IupSetAttribute( cSci.getIupScintilla, "SELECTIONPOS", toStringz( newBeginEndPos.dup ) );
								}
							}						
							
							CSearchExpander_search( 1 );
							actionManager.StatusBarAction.update();
							break;
						}
					}
				}
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