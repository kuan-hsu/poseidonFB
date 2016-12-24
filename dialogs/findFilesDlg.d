module dialogs.findFilesDlg;

private import iup.iup, iup.iup_scintilla;

private import global, project, scintilla, actionManager, menu;
private import dialogs.baseDlg;

private import tango.stdc.stringz, Util = tango.text.Util;

import Integer = tango.text.convert.Integer;


class CFindInFilesDialog : CBaseDialog
{
	private:
	import				tools;
	Ihandle*			listFind, listReplace;
	Ihandle*			labelStatus;
	
	CstringConvert[14]	cStrings;

	void createLayout()
	{
		Ihandle* bottom = createDlgButton();
		IupSetAttribute( btnOK, "VISIBLE", "NO" );

		cStrings[0] = new CstringConvert( GLOBAL.languageItems["findwhat"] ~ ":" );
		cStrings[1] = new CstringConvert( GLOBAL.languageItems["replacewith"] ~ ":" );

		listFind = IupList( null );
		IupSetAttributes( listFind, "SHOWIMAGE=NO,DROPDOWN=YES,EDITBOX=YES,SIZE=160x12,VISIBLE_ITEMS=3");
		IupSetHandle( "CFindInFilesDialog_listFind", listFind );
		Ihandle* hBox00 = IupHbox( IupLabel( cStrings[0].toStringz ), listFind, null );
		IupSetAttributes( hBox00, "ALIGNMENT=ACENTER" );

		listReplace = IupList( null );
		IupSetAttributes( listReplace, "SHOWIMAGE=NO,DROPDOWN=YES,EDITBOX=YES,SIZE=160x12,VISIBLE_ITEMS=3");
		IupSetHandle( "CFindInFilesDialog_listReplace", listReplace );
		Ihandle* hBox01 = IupHbox( IupLabel( cStrings[1].toStringz ), listReplace, null );
		IupSetAttributes( hBox01, "ALIGNMENT=ACENTER" );


		// Options
		cStrings[2] = new CstringConvert( GLOBAL.languageItems["casesensitive"] );
		cStrings[3] = new CstringConvert( GLOBAL.languageItems["wholeword"] );
		cStrings[13] = new CstringConvert( GLOBAL.languageItems["options"] );
		
		Ihandle* toggleCaseSensitive = IupToggle( cStrings[2].toStringz, null );
		IupSetAttributes( toggleCaseSensitive, "VALUE=ON,EXPAND=YES" );
		IupSetHandle( "CFindInFilesDialog_toggleCaseSensitive", toggleCaseSensitive );
		IupSetCallback( toggleCaseSensitive, "ACTION", cast(Icallback) &CFindInFilesDialog_toggleAction_cb );

		Ihandle* toggleWholeWord = IupToggle( cStrings[3].toStringz, null );
		IupSetAttributes( toggleWholeWord, "VALUE=ON,EXPAND=YES" );
		IupSetHandle( "CFindInFilesDialog_toggleWholeWord", toggleWholeWord );
		IupSetCallback( toggleWholeWord, "ACTION", cast(Icallback) &CFindInFilesDialog_toggleAction_cb );

		Ihandle* hBoxOption = IupHbox( toggleCaseSensitive, toggleWholeWord, null );
		IupSetAttributes( hBoxOption, "ALIGNMENT=ACENTER,EXPAND=YES,MARGIN=0x0,GAP=0" );
		Ihandle* frameOption = IupFrame( hBoxOption );
		IupSetAttributes( frameOption, "MARGIN=0x0,GAP=0,SIZE=0x20");
		IupSetAttribute( frameOption, "TITLE", cStrings[13].toStringz );


		// Scope
		cStrings[4] = new CstringConvert( GLOBAL.languageItems["document"] );
		cStrings[5] = new CstringConvert( GLOBAL.languageItems["alldocument"] );		
		cStrings[6] = new CstringConvert( GLOBAL.languageItems["prj"] );
		cStrings[7] = new CstringConvert( GLOBAL.languageItems["allproject"] );		
		cStrings[8] = new CstringConvert( GLOBAL.languageItems["scope"] );		
		
		Ihandle* toggleDocument = IupToggle( cStrings[4].toStringz, null );
		IupSetHandle( "CFindInFilesDialog_toggleDocument", toggleDocument );
		IupSetCallback( toggleDocument, "ACTION", cast(Icallback) &CFindInFilesDialog_toggleRadioAction_cb );
		
		Ihandle* toggleAllDocument = IupToggle( cStrings[5].toStringz, null );
		IupSetHandle( "CFindInFilesDialog_toggleAllDocument", toggleAllDocument );
		IupSetCallback( toggleAllDocument, "ACTION", cast(Icallback) &CFindInFilesDialog_toggleRadioAction_cb );
		
		Ihandle* togglePrj = IupToggle( cStrings[6].toStringz, null );
		IupSetAttributes( togglePrj, "VALUE=ON");
		IupSetHandle( "CFindInFilesDialog_togglePrj", togglePrj );
		IupSetCallback( togglePrj, "ACTION", cast(Icallback) &CFindInFilesDialog_toggleRadioAction_cb );

		Ihandle* toggleAllPrj = IupToggle( cStrings[7].toStringz, null );
		IupSetHandle( "CFindInFilesDialog_toggletoggleAllPrj", toggleAllPrj );
		IupSetCallback( toggleAllPrj, "ACTION", cast(Icallback) &CFindInFilesDialog_toggleRadioAction_cb );


		Ihandle* vBoxScope = IupVbox( toggleDocument, toggleAllDocument, togglePrj, toggleAllPrj, null );
		//IupSetAttributes( vBoxScope, "" );
		Ihandle* radioScope = IupRadio( vBoxScope );
		Ihandle* frameScope = IupFrame( radioScope );
		IupSetAttribute( frameScope, "TITLE", cStrings[8].toStringz );		


		// Buttons
		cStrings[9] = new CstringConvert( GLOBAL.languageItems["findall"] );
		cStrings[10] = new CstringConvert( GLOBAL.languageItems["replaceall"] );		
		cStrings[11] = new CstringConvert( GLOBAL.languageItems["countall"] );
		cStrings[12] = new CstringConvert( GLOBAL.languageItems["bookmarkall"] );		
		
		Ihandle* btnFindAll = IupButton( cStrings[9].toStringz, null );
		IupSetHandle( "CFindInFilesDialog_btnFindAll", btnFindAll );
		IupSetAttributes( btnFindAll, "EXPAND=YES" );
		IupSetCallback( btnFindAll, "ACTION", cast(Icallback) &CFindInFilesDialog_btnFindAll_cb );
		
		Ihandle* btnReplaceAll = IupButton( cStrings[10].toStringz, null );
		IupSetHandle( "CFindInFilesDialog_btnReplaceAll", btnReplaceAll );
		IupSetAttributes( btnReplaceAll, "EXPAND=YES" );
		//IupSetAttribute( btnReplaceAll, "ACTIVE", "NO" );
		IupSetCallback( btnReplaceAll, "ACTION", cast(Icallback) &CFindInFilesDialog_btnFindAll_cb );
		
		Ihandle* btnCountAll = IupButton( cStrings[11].toStringz, null );
		IupSetHandle( "CFindInFilesDialog_btnCountAll", btnCountAll );
		IupSetAttributes( btnCountAll, "EXPAND=YES" );
		IupSetCallback( btnCountAll, "ACTION", cast(Icallback) &CFindInFilesDialog_btnFindAll_cb );
		
		Ihandle* btnMarkAll = IupButton( cStrings[12].toStringz, null );
		IupSetHandle( "CFindInFilesDialog_btnMarkAll", btnMarkAll );
		IupSetAttributes( btnMarkAll, "EXPAND=YES" );
		IupSetCallback( btnMarkAll, "ACTION", cast(Icallback) &CFindInFilesDialog_btnFindAll_cb );

		Ihandle* vBoxButton = IupVbox( btnFindAll, btnReplaceAll, btnCountAll, btnMarkAll, null );
		IupSetAttributes( vBoxScope, "EXPANDCHILDREN=YES,GAP=2" );

		Ihandle* hBoxButton = IupHbox( frameScope, vBoxButton, null );
		IupSetAttributes( hBoxButton, "EXPAND=YES,HOMOGENEOUS=YES" );


	
		Ihandle* vBox = IupVbox( hBox00, hBox01, frameOption, hBoxButton, bottom, null );
		IupSetAttributes( vBox, "ALIGNMENT=ACENTER,MARGIN=5x5,GAP=0,EXPANDCHILDREN=YES" );

		IupAppend( _dlg, vBox );
	}	

	public:

	int			searchRule = 6;
	
	this( int w, int h, char[] title, char[] findWhat = null, bool bResize = false, char[] parent = "MAIN_DIALOG" )
	{
		super( w, h, title, bResize, parent );
		IupSetAttribute( _dlg, "ICON", "icon_findfiles" );
		IupSetAttribute( _dlg, "MINBOX", "NO" );
		IupSetAttribute( _dlg, "TOPMOST", "YES" );
		version( Windows )
		{
			IupSetAttribute( _dlg, "FONT", GLOBAL.cString.convert( "Courier New,9" ) );
		}
		else
		{
			IupSetAttribute( _dlg, "FONT", GLOBAL.cString.convert( "FreeMono,Bold 9" ) );
		}
		
		createLayout();

		IupSetAttribute( listFind, "VALUE", GLOBAL.cString.convert( findWhat ) );

		IupSetHandle( "btnCANCEL_findinfiles", btnCANCEL );
		IupSetCallback( btnCANCEL, "ACTION", cast(Icallback) &CFindInFilesDialog_btnCancel_cb );
		IupSetAttribute( _dlg, "DEFAULTESC", "btnCANCEL_findinfiles" );
		IupSetCallback( _dlg, "CLOSE_CB", cast(Icallback) &CFindInFilesDialog_btnCancel_cb );
	}

	~this()
	{
		IupSetHandle( "CFindInFilesDialog_listFind", null );
		IupSetHandle( "CFindInFilesDialog_listReplace", null );
		IupSetHandle( "CFindInFilesDialog_toggleCaseSensitive", null );
		IupSetHandle( "CFindInFilesDialog_toggleWholeWord", null );

		IupSetHandle( "CFindInFilesDialog_toggleDocument", null );
		IupSetHandle( "CFindInFilesDialog_toggleAllDocument", null );
		IupSetHandle( "CFindInFilesDialog_togglePrj", null );
		IupSetHandle( "CFindInFilesDialog_toggletoggleAllPrj", null );

		IupSetHandle( "CFindInFilesDialog_btnFindAll", null );
		IupSetHandle( "CFindInFilesDialog_btnReplaceAll", null );
		IupSetHandle( "CFindInFilesDialog_btnCountAll", null );
		IupSetHandle( "CFindInFilesDialog_btnMarkAll", null );

		IupSetHandle( "btnCANCEL_findinfiles", null );	
	}

	char[] show( char[] selectedWord ) // Overload form CBaseDialog
	{
		if( selectedWord.length ) IupSetAttribute( listFind, "VALUE", GLOBAL.cString.convert( selectedWord ) );
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
		IupSetAttribute( labelStatus, "TITLE", GLOBAL.cString.convert( text ) );
	}
}


extern(C) // Callback for CFindInFilesDialog
{
	private int CFindInFilesDialog_btnCancel_cb( Ihandle* ih )
	{
		if( GLOBAL.serachInFilesDlg !is null ) IupHide( GLOBAL.serachInFilesDlg._dlg );

		return IUP_DEFAULT;
	}

	private int CFindInFilesDialog_toggleAction_cb( Ihandle* ih, int state )
	{
		if( ih == IupGetHandle( "CFindInFilesDialog_toggleCaseSensitive" ) )
		{
			if( state == 1 ) GLOBAL.serachInFilesDlg.searchRule = GLOBAL.serachInFilesDlg.searchRule | 4;
			if( state == 0 ) GLOBAL.serachInFilesDlg.searchRule = GLOBAL.serachInFilesDlg.searchRule & 2;
		}
		else //"Whole Word"
		{
			if( state == 1 ) GLOBAL.serachInFilesDlg.searchRule = GLOBAL.serachInFilesDlg.searchRule | 2;
			if( state == 0 ) GLOBAL.serachInFilesDlg.searchRule = GLOBAL.serachInFilesDlg.searchRule & 4;
		}

		return IUP_DEFAULT;
	}

	private int CFindInFilesDialog_toggleRadioAction_cb( Ihandle* ih, int state )
	{
		if( ih == IupGetHandle( "CFindInFilesDialog_togglePrj" ) || ih == IupGetHandle( "CFindInFilesDialog_toggletoggleAllPrj" ) )
		{
			IupSetAttribute( IupGetHandle( "CFindInFilesDialog_btnMarkAll" ), "ACTIVE", "NO" );
		}
		else
		{
			IupSetAttribute( IupGetHandle( "CFindInFilesDialog_btnMarkAll" ), "ACTIVE", "YES" );
		}

		return IUP_DEFAULT;
	}

	private int CFindInFilesDialog_btnFindAll_cb( Ihandle* ih )
	{
		int		buttonIndex;
		char[]	findText, replaceText;

		if( IupGetHandle( toStringz("CFindInFilesDialog_btnFindAll") ) == ih )
			buttonIndex = 0;
		else if( IupGetHandle( toStringz("CFindInFilesDialog_btnReplaceAll") ) == ih )
			buttonIndex = 1;
		else if( IupGetHandle( toStringz("CFindInFilesDialog_btnCountAll") ) == ih )
			buttonIndex = 2;
		else
			buttonIndex = 3;
			

		Ihandle* listFind_ih = IupGetHandle( toStringz( "CFindInFilesDialog_listFind" ) );
		Ihandle* listReplace_ih = IupGetHandle( toStringz( "CFindInFilesDialog_listReplace" ) );
		if( listReplace_ih != null ) replaceText = fromStringz( IupGetAttribute( listReplace_ih, "VALUE" )).dup;
		
		
		if( listFind_ih != null )
		{
			findText = fromStringz( IupGetAttribute( listFind_ih, "VALUE" ) ).dup;
			if( findText.length )
			{
				switch( buttonIndex )
				{
					case 0:		IupSetAttribute( GLOBAL.searchOutputPanel, "VALUE", toStringz("Seraching......") ); break;
					case 1:		IupSetAttribute( GLOBAL.searchOutputPanel, "VALUE", toStringz("Replace......") ); break;
					case 2:		IupSetAttribute( GLOBAL.searchOutputPanel, "VALUE", toStringz("Counting......") ); break;
					default:	IupSetAttribute( GLOBAL.searchOutputPanel, "VALUE", toStringz("Marking......") );
				}

				int _findCase, _findMethod, count;
				if( fromStringz( IupGetAttribute( IupGetHandle( "CFindInFilesDialog_toggleDocument" ), "VALUE" ) ) == "ON" ) _findCase = 1;
				if( fromStringz( IupGetAttribute( IupGetHandle( "CFindInFilesDialog_toggleAllDocument" ), "VALUE" ) ) == "ON" ) _findCase = 2;
				if( fromStringz( IupGetAttribute( IupGetHandle( "CFindInFilesDialog_togglePrj" ), "VALUE" ) ) == "ON" ) _findCase = 3;
				if( fromStringz( IupGetAttribute( IupGetHandle( "CFindInFilesDialog_toggletoggleAllPrj" ), "VALUE" ) ) == "ON" ) _findCase = 4;

				if( fromStringz( IupGetAttribute( IupGetHandle( "CFindInFilesDialog_toggleWholeWord" ), "VALUE" ) ) == "ON" ) _findMethod = _findMethod | 2;
				if( fromStringz( IupGetAttribute( IupGetHandle( "CFindInFilesDialog_toggleCaseSensitive" ), "VALUE" ) ) == "ON" ) _findMethod = _findMethod | 4;


				if( buttonIndex == 1 )
				{
					IupSetAttribute( GLOBAL.serachInFilesDlg.getIhandle, "VISIBLE", "NO" );
					
					Ihandle* messageDlg = IupMessageDlg();
					IupSetAttributes( messageDlg, "DIALOGTYPE=WARNING,BUTTONS=OKCANCEL");
					IupSetAttribute( messageDlg, "TITLE", toStringz( GLOBAL.languageItems["findreplacefiles"] ) );
					IupSetAttribute( messageDlg, "VALUE", toStringz( GLOBAL.languageItems["cantundo"] ) );

					IupPopup( messageDlg, IUP_CURRENT, IUP_CURRENT );
					if( IupGetInt( messageDlg, "BUTTONRESPONSE" ) == 2 )
					{
						IupSetAttribute( GLOBAL.serachInFilesDlg.getIhandle, "VISIBLE", "YES" );
						return IUP_DEFAULT;
					}
					IupSetAttribute( GLOBAL.serachInFilesDlg.getIhandle, "VISIBLE", "YES" );
				}

				switch( _findCase )
				{
					case 1:
						CScintilla cSci = actionManager.ScintillaAction.getActiveCScintilla();
						if( cSci !is null )
						{
							count = actionManager.SearchAction.findInOneFile( cSci.getFullPath, findText, replaceText, _findMethod, buttonIndex );
						}
						break;
						
					case 2:
						foreach( CScintilla cSci; GLOBAL.scintillaManager )
						{
							count = count + actionManager.SearchAction.findInOneFile( cSci.getFullPath, findText, replaceText, _findMethod, buttonIndex );
						}
						break;
						
					case 3:
						char[] activePrjName = actionManager.ProjectAction.getActiveProjectName();
						if( activePrjName.length )
						{
							foreach( char[] s; GLOBAL.projectManager[activePrjName].sources ~ GLOBAL.projectManager[activePrjName].includes )
							{
								count = count + actionManager.SearchAction.findInOneFile( s, findText, replaceText, _findMethod, buttonIndex );
							}
						}
						else
						{
							if( fromStringz( IupGetAttribute( GLOBAL.menuMessageWindow, "VALUE" ) ) == "OFF" ) menu.message_cb( GLOBAL.menuMessageWindow );
							actionManager.SearchAction.addListItem( listFind_ih, findText, 15 );
							IupSetAttribute( GLOBAL.searchOutputPanel, "APPEND", toStringz("\nTotal found " ~ Integer.toString(count) ~ " Results.\nNo Active Project Be Selected.\n" ) );
							IupSetAttribute( GLOBAL.messageWindowTabs, "VALUEPOS", "1" );
							return IUP_DEFAULT;
						}
						break;

					default:
						if( GLOBAL.projectManager.length )
						{
							foreach( prj; GLOBAL.projectManager )
							{
								foreach( char[] s; prj.sources ~ prj.includes )
								{
									count = count + actionManager.SearchAction.findInOneFile( s, findText, replaceText, _findMethod, buttonIndex );
								}
							}
						}
						else
						{
							if( fromStringz( IupGetAttribute( GLOBAL.menuMessageWindow, "VALUE" ) ) == "OFF" ) menu.message_cb( GLOBAL.menuMessageWindow );
							actionManager.SearchAction.addListItem( listFind_ih, findText, 15 );
							IupSetAttribute( GLOBAL.searchOutputPanel, "APPEND", toStringz("\nTotal found " ~ Integer.toString(count) ~ " Results.\nNo Any Project Be Selected.\n" ) );
							IupSetAttribute( GLOBAL.messageWindowTabs, "VALUEPOS", "1" );
							return IUP_DEFAULT;
						}
				}

				actionManager.SearchAction.addListItem( listFind_ih, findText, 15 );
				IupSetAttribute( GLOBAL.searchOutputPanel, "APPEND", toStringz("\nTotal found " ~ Integer.toString(count) ~ " Results." ) );
				IupSetAttribute( GLOBAL.messageWindowTabs, "VALUEPOS", "1" );
			}
		}
		
		return IUP_DEFAULT;
	}
}