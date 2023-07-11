module dialogs.findFilesDlg;

private import iup.iup, iup.iup_scintilla;
private import tools;
private import global, project, scintilla, actionManager, menu;
private import dialogs.baseDlg;
private import std.conv;


class CFindInFilesDialog : CBaseDialog
{
private:
	import				std.string;
	Ihandle*			listFind, listReplace;
	Ihandle*			labelStatus;
	Ihandle* 			btnFindAll, btnReplaceAll, btnCountAll, btnMarkAll;
	
	IupString[2]		labelTitle;

	void createLayout()
	{
		Ihandle* bottom = createDlgButton( "40x16", "c" );

		labelTitle[0] = new IupString( GLOBAL.languageItems["findwhat"].toDString ~ ":" );
		labelTitle[1] = new IupString( GLOBAL.languageItems["replacewith"].toDString ~ ":" );

		listFind = IupList( null );
		IupSetAttributes( listFind, "SHOWIMAGE=NO,DROPDOWN=YES,EDITBOX=YES,SIZE=160x12,VISIBLE_ITEMS=3,NAME=CFindInFilesDialog-list_Find");
		Ihandle* label00 = IupLabel( labelTitle[0].toCString );
		IupSetAttribute( label00, "SIZE", "60x12" );
		Ihandle* hBox00 = IupHbox( label00, listFind, null );
		IupSetAttributes( hBox00, "ALIGNMENT=ACENTER" );
		IupSetCallback( listFind, "K_ANY", cast(Icallback) &findList_K_ANY );
		
		listReplace = IupList( null );
		IupSetAttributes( listReplace, "SHOWIMAGE=NO,DROPDOWN=YES,EDITBOX=YES,SIZE=160x12,VISIBLE_ITEMS=3,NAME=CFindInFilesDialog-list_Replace");
		Ihandle* label01 = IupLabel( labelTitle[1].toCString );
		IupSetAttribute( label01, "SIZE", "60x12" );
		Ihandle* hBox01 = IupHbox( label01, listReplace, null );
		IupSetAttributes( hBox01, "ALIGNMENT=ACENTER" );


		// Options
		Ihandle* toggleCaseSensitive = IupFlatToggle( GLOBAL.languageItems["casesensitive"].toCString );
		IupSetAttributes( toggleCaseSensitive, "EXPAND=YES,NAME=toggle_CaseSensitive,ALIGNMENT=ALEFT:ACENTER" );
		version(DIDE) IupSetAttribute( toggleCaseSensitive, "VALUE", "ON" );
		IupSetCallback( toggleCaseSensitive, "FLAT_ACTION", cast(Icallback) &dialogs.findFilesDlg.toggle_ACTION_CB );

		Ihandle* toggleWholeWord = IupFlatToggle( GLOBAL.languageItems["wholeword"].toCString );
		IupSetAttributes( toggleWholeWord, "VALUE=ON,EXPAND=YES,NAME=toggle_WholeWord,ALIGNMENT=ALEFT:ACENTER" );
		IupSetCallback( toggleWholeWord, "FLAT_ACTION", cast(Icallback) &dialogs.findFilesDlg.toggle_ACTION_CB );

		Ihandle* hBoxOption = IupHbox( toggleCaseSensitive, toggleWholeWord, null );
		IupSetAttributes( hBoxOption, "ALIGNMENT=ACENTER,EXPAND=YES,MARGIN=0x0,GAP=0,HOMOGENEOUS=YES" );
		Ihandle* frameOption = IupFrame( hBoxOption );
		IupSetStrAttribute( frameOption, "TITLE", GLOBAL.languageItems["options"].toCString );


		// Scope
		Ihandle* toggleDocument = IupFlatToggle( GLOBAL.languageItems["document"].toCString );
		IupSetAttributes( toggleDocument, "NAME=toggle_Document,ALIGNMENT=ALEFT:ACENTER" );
		IupSetCallback( toggleDocument, "FLAT_ACTION", cast(Icallback) &dialogs.findFilesDlg.radioTarget_ACTION_CB );
		
		Ihandle* toggleAllDocument = IupFlatToggle( GLOBAL.languageItems["alldocument"].toCString );
		IupSetAttributes( toggleAllDocument, "NAME=toggle_AllDocuments,ALIGNMENT=ALEFT:ACENTER" );
		IupSetCallback( toggleAllDocument, "FLAT_ACTION", cast(Icallback) &dialogs.findFilesDlg.radioTarget_ACTION_CB );
		
		Ihandle* togglePrj = IupFlatToggle( GLOBAL.languageItems["prj"].toCString );
		IupSetAttributes( togglePrj, "NAME=toggle_Project,ALIGNMENT=ALEFT:ACENTER");
		IupSetCallback( togglePrj, "FLAT_ACTION", cast(Icallback) &dialogs.findFilesDlg.radioTarget_ACTION_CB );

		Ihandle* toggleAllPrj = IupFlatToggle( GLOBAL.languageItems["allproject"].toCString );
		IupSetAttributes( toggleAllPrj, "NAME=toggle_AllProjects,ALIGNMENT=ALEFT:ACENTER" );
		IupSetCallback( toggleAllPrj, "FLAT_ACTION", cast(Icallback) &dialogs.findFilesDlg.radioTarget_ACTION_CB );

		Ihandle* vBoxScope = IupVbox( toggleDocument, toggleAllDocument, togglePrj, toggleAllPrj, null );
		IupSetAttributes( vBoxScope, "EXPANDCHILDREN=YES,GAP=0" );
		Ihandle* radioScope = IupRadio( vBoxScope );
		Ihandle* frameScope = IupFrame( radioScope );
		IupSetStrAttribute( frameScope, "TITLE", GLOBAL.languageItems["scope"].toCString );
		
		IupSetAttribute( togglePrj, "VALUE", "ON");


		// Buttons
		btnFindAll = IupFlatButton( GLOBAL.languageItems["findall"].toCString );
		IupSetAttributes( btnFindAll, "EXPAND=YES,NAME=btn_Find" );
		IupSetStrAttribute( btnFindAll, "HLCOLOR", "" );
		IupSetCallback( btnFindAll, "FLAT_ACTION", cast(Icallback) &dialogs.findFilesDlg.btnExecute_ACTION_CB );
		
		btnReplaceAll = IupFlatButton( GLOBAL.languageItems["replaceall"].toCString );
		IupSetAttributes( btnReplaceAll, "EXPAND=YES,NAME=btn_Replace" );
		IupSetStrAttribute( btnReplaceAll, "HLCOLOR", "" );
		IupSetCallback( btnReplaceAll, "FLAT_ACTION", cast(Icallback) &dialogs.findFilesDlg.btnExecute_ACTION_CB );
		
		btnCountAll = IupFlatButton( GLOBAL.languageItems["countall"].toCString );
		IupSetAttributes( btnCountAll, "EXPAND=YES,NAME=btn_Count" );
		IupSetStrAttribute( btnCountAll, "HLCOLOR", "" );
		IupSetCallback( btnCountAll, "FLAT_ACTION", cast(Icallback) &dialogs.findFilesDlg.btnExecute_ACTION_CB );
		
		btnMarkAll = IupFlatButton( GLOBAL.languageItems["bookmarkall"].toCString );
		IupSetAttributes( btnMarkAll, "EXPAND=YES,NAME=btn_Mark" );
		IupSetStrAttribute( btnMarkAll, "HLCOLOR", "" );
		IupSetCallback( btnMarkAll, "FLAT_ACTION", cast(Icallback) &dialogs.findFilesDlg.btnExecute_ACTION_CB );

		Ihandle* vBoxButton = IupVbox( btnFindAll, btnReplaceAll, btnCountAll, btnMarkAll, null );
		Ihandle* hBoxButton = IupHbox( frameScope, vBoxButton, null );
		IupSetAttributes( hBoxButton, "EXPAND=YES,HOMOGENEOUS=YES,EXPANDCHILDREN=YES" );
		
		
		Ihandle* FindFiles_btnHiddenCANCEL = IupButton( null, null );
		IupSetAttribute( FindFiles_btnHiddenCANCEL, "VISIBLE", "NO" );
		IupSetHandle( "FindFiles_btnHiddenCANCEL", FindFiles_btnHiddenCANCEL );
		IupSetCallback( FindFiles_btnHiddenCANCEL, "ACTION", cast(Icallback) &dialogs.findFilesDlg.btnCancel_ACTION_CB );

	
		Ihandle* vBox = IupVbox( hBox00, hBox01, frameOption, hBoxButton, IupHbox( FindFiles_btnHiddenCANCEL, bottom, null ), null );
		IupSetAttributes( vBox, "ALIGNMENT=ACENTER,MARGIN=5x5,GAP=0,EXPANDCHILDREN=YES" );
		//version( Windows ) IupSetAttribute( vBox, "FONTFACE", "Courier New" ); else IupSetAttribute( vBox, "FONT", "Ubuntu Mono, 10" );

		IupAppend( _dlg, vBox );
		
		changeColor();
	}	

public:
	int			searchRule = 6;
	
	this( int w, int h, string title, string findWhat = null, bool bResize = false, string parent = "POSEIDON_MAIN_DIALOG" )
	{
		super( w, h, title, bResize, parent );
		IupSetAttribute( _dlg, "ICON", "icon_findfiles" );
		IupSetAttribute( _dlg, "MINBOX", "NO" );
		
		createLayout();

		IupSetStrAttribute( listFind, "VALUE", toStringz( findWhat ) );
		IupSetCallback( btnCANCEL, "FLAT_ACTION", cast(Icallback) &dialogs.findFilesDlg.btnCancel_ACTION_CB );
		IupSetAttribute( _dlg, "DEFAULTESC", "FindFiles_btnHiddenCANCEL" );
		IupSetCallback( _dlg, "CLOSE_CB", cast(Icallback) &dialogs.findFilesDlg.btnCancel_ACTION_CB );	
		IupSetStrAttribute( _dlg, "OPACITY", toStringz( GLOBAL.editorSetting02.findfilesDlg ) );
		version(Windows) IupSetCallback( _dlg, "SHOW_CB", cast(Icallback) function( Ihandle* ih )
		{
			Ihandle* _findHandle = IupGetDialogChild( GLOBAL.serachInFilesDlg.getIhandle, "CFindInFilesDialog-list_Find" );
			Ihandle* _replaceHandle = IupGetDialogChild( GLOBAL.serachInFilesDlg.getIhandle, "CFindInFilesDialog-list_Replace" );
			if( _findHandle != null && _replaceHandle != null )
			{
				if( GLOBAL.bCanUseDarkMode )
				{
					if( GLOBAL.editorSetting00.UseDarkMode == "ON" )
					{
						GLOBAL.SetWindowTheme( cast(void*) IupGetAttribute( _findHandle, "WID" ), "DarkMode_CFD", null );
						GLOBAL.SetWindowTheme( cast(void*) IupGetAttribute( _replaceHandle, "WID" ), "DarkMode_CFD", null );
					}
					else
					{
						GLOBAL.SetWindowTheme( cast(void*) IupGetAttribute( _findHandle, "WID" ), "CFD", null );
						GLOBAL.SetWindowTheme( cast(void*) IupGetAttribute( _replaceHandle, "WID" ), "CFD", null );
					}	
				}
			}
			
			return IUP_DEFAULT;
		});
		
		IupMap( _dlg );
	}

	~this()
	{
		destroy( labelTitle[0] );
		destroy( labelTitle[1] );
	}

	string show( string selectedWord ) // Overload form CBaseDialog
	{
		if( selectedWord.length ) IupSetStrAttribute( listFind, "VALUE", toStringz( selectedWord ) );
		IupShow( _dlg );
		return null;
	}	

	override string show( int x, int y ) // Overload form CBaseDialog
	{
		IupShowXY( _dlg, x, y );
		return null;
	}

	void setStatusBar( string text )
	{
		IupSetStrAttribute( labelStatus, "TITLE", toStringz( text ) );
	}
	
	void changeColor()
	{
		version(Windows)
		{
			IupSetStrAttribute( _dlg, "FGCOLOR", toStringz( GLOBAL.editColor.dlgFore ) );
			IupSetStrAttribute( _dlg, "BGCOLOR", toStringz( GLOBAL.editColor.dlgBack ) );

			IupSetStrAttribute( listFind, "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( listFind, "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
			IupSetStrAttribute( listReplace, "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( listReplace, "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
		
			IupSetStrAttribute( btnCANCEL, "HLCOLOR", IupGetAttribute( _dlg, "BGCOLOR" ) );
			IupSetStrAttribute( btnFindAll, "HLCOLOR", IupGetAttribute( _dlg, "BGCOLOR" ) );
			IupSetStrAttribute( btnReplaceAll, "HLCOLOR", IupGetAttribute( _dlg, "BGCOLOR" ) );
			IupSetStrAttribute( btnCountAll, "HLCOLOR",IupGetAttribute( _dlg, "BGCOLOR" ) );
			IupSetStrAttribute( btnMarkAll, "HLCOLOR", IupGetAttribute( _dlg, "BGCOLOR" ) );
		}
	}
}


extern(C) // Callback for CFindInFilesDialog
{
	private int findList_K_ANY( Ihandle *ih, int c )
	{
		if( c == 13 ) return btnExecute_ACTION_CB( IupGetDialogChild( GLOBAL.serachInFilesDlg.getIhandle, "btn_Find" ) );
		return IUP_DEFAULT;
	}
	
	private int btnCancel_ACTION_CB( Ihandle* ih )
	{
		if( GLOBAL.serachInFilesDlg !is null ) IupHide( GLOBAL.serachInFilesDlg.getIhandle );

		return IUP_DEFAULT;
	}

	private int toggle_ACTION_CB( Ihandle* ih, int state )
	{
		if( ih == IupGetDialogChild( GLOBAL.serachInFilesDlg.getIhandle, "toggle_CaseSensitive" ) )
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

	private int radioTarget_ACTION_CB( Ihandle* ih, int state )
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

	private int btnExecute_ACTION_CB( Ihandle* ih )
	{
		int		buttonIndex;
		string	findText, replaceText;

		if( IupGetDialogChild( GLOBAL.serachInFilesDlg.getIhandle, "btn_Find" ) == ih )
			buttonIndex = 0;
		else if( IupGetDialogChild( GLOBAL.serachInFilesDlg.getIhandle, "btn_Replace" ) == ih )
			buttonIndex = 1;
		else if( IupGetDialogChild( GLOBAL.serachInFilesDlg.getIhandle, "btn_Count" ) == ih )
			buttonIndex = 2;
		else
			buttonIndex = 3;
			

		Ihandle* listFind_ih = IupGetDialogChild( GLOBAL.serachInFilesDlg.getIhandle, "CFindInFilesDialog-list_Find" );
		Ihandle* listReplace_ih = IupGetDialogChild( GLOBAL.serachInFilesDlg.getIhandle, "CFindInFilesDialog-list_Replace" ); // IupGetHandle( toStringz( "CFindInFilesDialog_listReplace" ) );
		if( listReplace_ih != null ) replaceText = fSTRz( IupGetAttribute( listReplace_ih, "VALUE" ) );
		
		
		if( listFind_ih != null )
		{
			findText = fSTRz( IupGetAttribute( listFind_ih, "VALUE" ) );
			if( findText.length )
			{
				actionManager.SearchAction.addListItem( listFind_ih, findText, 15 );
				
				switch( buttonIndex )
				{
					case 0:		GLOBAL.messagePanel.printSearchOutputPanel( "Seraching......", true ); break;
					case 1:		GLOBAL.messagePanel.printSearchOutputPanel( "Replace......", true ); break;
					case 2:		GLOBAL.messagePanel.printSearchOutputPanel( "Counting......", true ); break;
					default:	GLOBAL.messagePanel.printSearchOutputPanel( "Marking......", true );
				}

				int _findCase, _findMethod, count;
				if( fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.serachInFilesDlg.getIhandle, "toggle_Document" ), "VALUE" ) ) == "ON" ) _findCase = 1;
				if( fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.serachInFilesDlg.getIhandle, "toggle_AllDocuments" ), "VALUE" ) ) == "ON" ) _findCase = 2;
				if( fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.serachInFilesDlg.getIhandle, "toggle_Project" ), "VALUE" ) ) == "ON" ) _findCase = 3;
				if( fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.serachInFilesDlg.getIhandle, "toggle_AllProjects" ), "VALUE" ) ) == "ON" ) _findCase = 4;

				if( fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.serachInFilesDlg.getIhandle, "toggle_WholeWord" ), "VALUE" ) ) == "ON" ) _findMethod = _findMethod | 2;
				if( fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.serachInFilesDlg.getIhandle, "toggle_CaseSensitive" ), "VALUE" ) ) == "ON" ) _findMethod = _findMethod | 4;

				if( buttonIndex == 1 )
				{
					IupSetAttribute( GLOBAL.serachInFilesDlg.getIhandle, "VISIBLE", "NO" );
					
					Ihandle* messageDlg = IupMessageDlg();
					IupSetAttributes( messageDlg, "DIALOGTYPE=WARNING,BUTTONS=OKCANCEL");
					IupSetAttribute( messageDlg, "TITLE", GLOBAL.languageItems["findreplacefiles"].toCString );
					IupSetAttribute( messageDlg, "VALUE", GLOBAL.languageItems["cantundo"].toCString );

					IupPopup( messageDlg, IUP_CURRENT, IUP_CURRENT );
					if( IupGetInt( messageDlg, "BUTTONRESPONSE" ) == 2 )
					{
						IupSetAttribute( GLOBAL.serachInFilesDlg.getIhandle, "VISIBLE", "YES" );
						return IUP_DEFAULT;
					}
					IupSetAttribute( GLOBAL.serachInFilesDlg.getIhandle, "VISIBLE", "YES" );
					if( replaceText.length ) actionManager.SearchAction.addListItem( listReplace_ih, replaceText, 15 );
				}

				switch( _findCase )
				{
					case 1:
						CScintilla cSci = actionManager.ScintillaAction.getActiveCScintilla();
						if( cSci !is null )
						{
							count = actionManager.SearchAction.findInOneFile( cSci.getFullPath, findText, replaceText, _findMethod, buttonIndex );
						}
						
						GLOBAL.messagePanel.applySearchOutputPanelINDICATOR();
						
						break;
						
					case 2:
						foreach( CScintilla cSci; GLOBAL.scintillaManager )
						{
							count = count + actionManager.SearchAction.findInOneFile( cSci.getFullPath, findText, replaceText, _findMethod, buttonIndex );
						}
						
						GLOBAL.messagePanel.applySearchOutputPanelINDICATOR();
						
						break;
						
					case 3:
						string activePrjName = actionManager.ProjectAction.getActiveProjectName();
						if( activePrjName.length )
						{
							if( activePrjName in GLOBAL.projectManager )
							{
								foreach( string s; GLOBAL.projectManager[activePrjName].sources ~ GLOBAL.projectManager[activePrjName].includes )
								{
									count = count + actionManager.SearchAction.findInOneFile( s, findText, replaceText, _findMethod, buttonIndex );
								}
								
								GLOBAL.messagePanel.applySearchOutputPanelINDICATOR();
							}
						}
						else
						{
							if( fSTRz( IupGetAttribute( GLOBAL.menuMessageWindow, "VALUE" ) ) == "OFF" ) menu.messageMenuItem_cb( GLOBAL.menuMessageWindow );
							actionManager.SearchAction.addListItem( listFind_ih, findText, 15 );
							GLOBAL.messagePanel.printSearchOutputPanel( "\nTotal found " ~ to!(string)(count) ~ " Results.\nNo Active Project Be Selected.\n" );
							IupSetAttribute( GLOBAL.messageWindowTabs, "VALUEPOS", "1" );
							return IUP_DEFAULT;
						}
						break;

					default:
						if( GLOBAL.projectManager.length )
						{
							foreach( prj; GLOBAL.projectManager )
							{
								foreach( string s; prj.sources ~ prj.includes )
								{
									count = count + actionManager.SearchAction.findInOneFile( s, findText, replaceText, _findMethod, buttonIndex );
								}
							}
							
							GLOBAL.messagePanel.applySearchOutputPanelINDICATOR();
						}
						else
						{
							if( fSTRz( IupGetAttribute( GLOBAL.menuMessageWindow, "VALUE" ) ) == "OFF" ) menu.messageMenuItem_cb( GLOBAL.menuMessageWindow );
							actionManager.SearchAction.addListItem( listFind_ih, findText, 15 );
							GLOBAL.messagePanel.printSearchOutputPanel( "\nTotal found " ~ to!(string)(count) ~ " Results.\nNo Any Project Be Selected.\n" );
							IupSetAttribute( GLOBAL.messageWindowTabs, "VALUEPOS", "1" );
							return IUP_DEFAULT;
						}
				}

				actionManager.SearchAction.addListItem( listFind_ih, findText, 15 );
				GLOBAL.messagePanel.printSearchOutputPanel( "\nTotal found " ~ to!(string)(count) ~ " Results." );
				IupSetAttribute( GLOBAL.messageWindowTabs, "VALUEPOS", "1" );
			}
		}
		
		return IUP_DEFAULT;
	}
}