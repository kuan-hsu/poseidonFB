module dialogs.prjPropertyDlg;

private import iup.iup, iup.iup_scintilla;
private import global, project, scintilla, actionManager, tools;
private import dialogs.baseDlg, dialogs.fileDlg, dialogs.singleTextDlg;
private import std.string, std.file, Path = std.path, std.conv;


class CProjectPropertiesDialog : CBaseDialog
{
	private:
	
	Ihandle*	textProjectName, listType, textProjectDir, textMainFile, toggleOneFile, textTargetName, textArgs, textCompilerOpts, textCompilerPath;
	Ihandle*	listFocus;
	Ihandle*	btnProjectDir;
	Ihandle*	listIncludePath, listLibPath;
	
	bool		bCreateNew = true;
	
	IupString[7] labelTitle;
	
	static PROJECT	tempProject;
	

	void createLayout()
	{
		Ihandle* bottom = createDlgButton( "40x12", "aoc" );

		// PAGE 1 General
		// Line 1
		if( labelTitle[0] is null ) labelTitle[0] = new IupString( GLOBAL.languageItems["prjname"].toDString ~ ":" );
		Ihandle* labelProjectName = IupLabel( labelTitle[0].toCString );
		IupSetAttributes( labelProjectName, "SIZE=60x20" );
		
		textProjectName = IupText( null );
		IupSetAttributes( textProjectName, "SIZE=130x12,NAME=PRJPROPERTY_ProjectName" );
		
		if( labelTitle[1] is null ) labelTitle[1] = new IupString( GLOBAL.languageItems["prjtype"].toDString ~ ":" );
		Ihandle* labelType = IupLabel(labelTitle[1].toCString );
		IupSetAttributes( labelType, "SIZE=40x20,ALIGNMENT=ACENTER" );
		
		listType = IupList( null );
		IupSetAttributes( listType, "SHOWIMAGE=NO,VALUE=1,DROPDOWN=YES,VISIBLE_ITEMS=3,SIZE=106x,NAME=PRJPROPERTY_TypeList" );
		IupSetAttribute( listType, "1", GLOBAL.languageItems["console"].toCString() );
		IupSetAttribute( listType, "2", GLOBAL.languageItems["static"].toCString() );
		IupSetAttribute( listType, "3", GLOBAL.languageItems["dynamic"].toCString() );

		Ihandle* hBox00 = IupHbox( labelProjectName, textProjectName, labelType, listType, null );
		IupSetAttribute( hBox00, "ALIGNMENT", "ACENTER" );
		

		// Line 2
		if( labelTitle[2] is null ) labelTitle[2] = new IupString( GLOBAL.languageItems["prjdir"].toDString ~ ":" );
		Ihandle* labelProjectDir = IupLabel( labelTitle[2].toCString );
		IupSetAttributes( labelProjectDir, "SIZE=60x20" );
		
		textProjectDir = IupText( null );
		IupSetAttributes( textProjectDir, "SIZE=276x12,NAME=PRJPROPERTY_ProjectDir" );

		btnProjectDir = IupButton( null, null );
		IupSetAttributes( btnProjectDir, "IMAGE=icon_openfile,FLAT=YES" );
		IupSetCallback( btnProjectDir, "ACTION", cast(Icallback) &CProjectPropertiesDialog_btnProjectDir_cb );

		Ihandle* hBox01 = IupHbox( labelProjectDir, textProjectDir, btnProjectDir, null );
		IupSetAttribute( hBox01, "ALIGNMENT", "ACENTER" );	

		// Line 3
		version(FBIDE)
		{
			if( labelTitle[3] is null ) labelTitle[3] = new IupString( GLOBAL.languageItems["prjmainfile"].toDString ~ ":" );
			Ihandle* labelMainFile = IupLabel( labelTitle[3].toCString );
			IupSetAttributes( labelMainFile, "SIZE=60x20" );
			
			textMainFile = IupText( null );
			IupSetAttributes( textMainFile, "SIZE=130x12,NAME=PRJPROPERTY_ProjectMainFile" );
			
			toggleOneFile = IupFlatToggle( GLOBAL.languageItems["prjonefile"].toCString );
			IupSetAttributes( toggleOneFile, "SIZE=140x12,ALIGNMENT=ALEFT:ACENTER,NAME=PRJPROPERTY_ToggleOneFile" );
			
			Ihandle* hBox02 = IupHbox( labelMainFile, textMainFile, IupFill, toggleOneFile, IupFill, null );
			IupSetAttribute( hBox02, "ALIGNMENT", "ACENTER" );
		}

		
		// Line 4
		if( labelTitle[4] is null ) labelTitle[4] = new IupString( GLOBAL.languageItems["prjtarget"].toDString ~ ":" );
		Ihandle* labelTargetName = IupLabel( labelTitle[4].toCString );
		IupSetAttributes( labelTargetName, "SIZE=60x20" );
		
		textTargetName = IupText( null );
		IupSetAttributes( textTargetName, "SIZE=130x12,NAME=PRJPROPERTY_TargetName" );
		
		if( labelTitle[5] is null ) labelTitle[5] = new IupString( GLOBAL.languageItems["prjfocus"].toDString ~ ":" );
		Ihandle* labelFocus = IupLabel( labelTitle[5].toCString );
		IupSetAttributes( labelFocus, "SIZE=40x12,ALIGNMENT=ACENTER" );
		
		listFocus = IupList( null );
		IupSetAttributes( listFocus, "SHOWIMAGE=NO,EDITBOX=YES,DROPDOWN=YES,VISIBLE_ITEMS=5,SIZE=106x12,NAME=PRJPROPERTY_FocusList" );
		IupSetCallback( listFocus, "ACTION",cast(Icallback) &CProjectPropertiesDialog_listFocus_ACTION );
		
		Ihandle* focusRemove = IupButton( null, null );
		IupSetAttributes( focusRemove, "FLAT=YES,IMAGE=icon_debug_clear" );
		IupSetCallback( focusRemove, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			Ihandle* _dlg = IupGetHandle( "PRJPROPERTY_DIALOG" );
			
			if( _dlg != null )
			{
				Ihandle* _focusList = IupGetDialogChild( _dlg, "PRJPROPERTY_FocusList" );
				if( _focusList != null )
				{
					string focusTitle = strip( fSTRz( IupGetAttribute( _focusList, "VALUE" ) ) );
			
					if( focusTitle.length )
					{
						for( int j = IupGetInt( _focusList, "COUNT" ); j >= 1; -- j )
						{
							if( fromStringz( IupGetAttributeId( _focusList, "", j ) ) == focusTitle )
							{
								if( focusTitle in tempProject.focusUnit ) tempProject.focusUnit.remove( focusTitle );
								IupSetInt( _focusList, "REMOVEITEM", j );
								tempProject.focusOn = "";
								IupSetAttribute( _focusList, "VALUE", "" );

								IupSetStrAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_TargetName" ), "VALUE", toStringz( CProjectPropertiesDialog.tempProject.targetName ) );
								IupSetStrAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_Options" ), "VALUE", toStringz( CProjectPropertiesDialog.tempProject.compilerOption ) );
								IupSetStrAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_CompilerPath" ), "VALUE", toStringz( CProjectPropertiesDialog.tempProject.compilerPath ) );

								IupSetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_IncludePaths" ), "REMOVEITEM", "ALL" );
								for( int i = 0; i < CProjectPropertiesDialog.tempProject.includeDirs.length; ++ i )
									IupSetStrAttributeId( IupGetDialogChild( _dlg, "PRJPROPERTY_IncludePaths" ), "", i + 1, toStringz( CProjectPropertiesDialog.tempProject.includeDirs[i] ) );
								
								IupSetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_LibPaths" ), "REMOVEITEM", "ALL" );
								for( int i = 0; i < CProjectPropertiesDialog.tempProject.libDirs.length; ++ i )
									IupSetStrAttributeId( IupGetDialogChild( _dlg, "PRJPROPERTY_LibPaths" ), "", i + 1, toStringz( CProjectPropertiesDialog.tempProject.libDirs[i] ) );
								
								break;
							}
						}
					}
				}
			}
			
			return IUP_DEFAULT;
		});			
		
		Ihandle* hBox03 = IupHbox( labelTargetName, textTargetName, labelFocus, listFocus, focusRemove, null );
		IupSetAttribute( hBox03, "ALIGNMENT", "ACENTER" );

		// Line 5
		Ihandle* labelArgs = IupLabel( GLOBAL.languageItems["prjargs"].toCString );
		IupSetAttributes( labelArgs, "SIZE=60x20" );
		
		textArgs = IupText( null );
		IupSetAttributes( textArgs, "SIZE=276x12,NAME=PRJPROPERTY_Args" );
		
		Ihandle* hBox04 = IupHbox( labelArgs, textArgs, null );
		IupSetAttribute( hBox04, "ALIGNMENT", "ACENTER" );

		// Line 6
		Ihandle* labelCompilerOpts = IupLabel( GLOBAL.languageItems["prjopts"].toCString );
		IupSetAttributes( labelCompilerOpts, "SIZE=60x20" );
		
		textCompilerOpts = IupText( null );
		IupSetAttributes( textCompilerOpts, "SIZE=276x12,NAME=PRJPROPERTY_Options" );

		Ihandle* btnCompilerOpts = IupButton( null, null );
		IupSetAttributes( btnCompilerOpts, "IMAGE=icon_help,FLAT=YES" );
		IupSetCallback( btnCompilerOpts, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			GLOBAL.compilerHelpDlg.show( IUP_MOUSEPOS, IUP_MOUSEPOS );
			return IUP_DEFAULT;
		});	
		
		Ihandle* hBox05 = IupHbox( labelCompilerOpts, textCompilerOpts, btnCompilerOpts, null );
		IupSetAttribute( hBox05, "ALIGNMENT", "ACENTER" );
		
		// Line 8
		if( labelTitle[6] is null ) labelTitle[6] = new IupString( GLOBAL.languageItems["prjcompiler"].toDString ~ ":" );
		Ihandle* labelCompilerPath = IupLabel( labelTitle[6].toCString );
		IupSetAttributes( labelCompilerPath, "SIZE=60x12" );
		
		textCompilerPath = IupText( null );
		IupSetAttributes( textCompilerPath, "SIZE=276x12,NAME=PRJPROPERTY_CompilerPath" );

		Ihandle* btnCompilerPath = IupButton( null, null );
		IupSetAttributes( btnCompilerPath, "IMAGE=icon_openfile,FLAT=YES" );
		IupSetCallback( btnCompilerPath, "ACTION", cast(Icallback) &CProjectPropertiesDialog_btnCompilerPath_cb );		
		
		Ihandle* hBox07 = IupHbox( labelCompilerPath, textCompilerPath, btnCompilerPath, null );
		IupSetAttribute( hBox07, "ALIGNMENT", "ACENTER" );

		version(FBIDE)	Ihandle* vBoxPage01 = IupVbox( hBox00, hBox01, hBox02, hBox03, hBox04, hBox05, hBox07, null );
		version(DIDE)	Ihandle* vBoxPage01 = IupVbox( hBox00, hBox01, hBox03, hBox04, hBox05, hBox07, null );
		
		IupSetAttributes( vBoxPage01, "ALIGNMENT=ALEFT,MARGIN=2x0,GAP=0" );


		// PAGE 2 Include...
		// Include Paths
		listIncludePath = IupList( null );
		IupSetAttributes( listIncludePath, "MULTIPLE=NO,SIZE=326x64,NAME=PRJPROPERTY_IncludePaths" );

		IupSetHandle( "listIncludePath_Handle", listIncludePath );
		IupSetCallback( listIncludePath, "DBLCLICK_CB", cast(Icallback) &CProjectPropertiesDialog_DBLCLICK_CB );
		
		Ihandle* btnIncludePathAdd = IupButton( null, null );
		IupSetAttributes( btnIncludePathAdd, "IMAGE=icon_debug_add,FLAT=YES,CANFOCUS=NO" );
		IupSetHandle( "btnIncludePathAdd_Handle", btnIncludePathAdd );
		IupSetCallback( btnIncludePathAdd, "ACTION", cast(Icallback) &CProjectPropertiesDialog_Add_cb );

		Ihandle* btnIncludePathErase = IupButton( null, null );
		IupSetAttributes( btnIncludePathErase, "IMAGE=icon_delete,FLAT=YES,CANFOCUS=NO" );
		IupSetHandle( "btnIncludePathErase_Handle", btnIncludePathErase );
		IupSetCallback( btnIncludePathErase, "ACTION", cast(Icallback) &CProjectPropertiesDialog_Erase_cb );
		
		Ihandle* btnIncludePathEdit = IupButton( null, null );
		IupSetAttributes( btnIncludePathEdit, "IMAGE=icon_Write,FLAT=YES,CANFOCUS=NO" );
		IupSetHandle( "btnIncludePathEdit_Handle", btnIncludePathEdit );
		IupSetCallback( btnIncludePathEdit, "ACTION", cast(Icallback) &CProjectPropertiesDialog_Edit_cb );

		Ihandle* btnIncludePathUp = IupButton( null, null );
		IupSetAttributes( btnIncludePathUp, "IMAGE=icon_uparrow,FLAT=YES,CANFOCUS=NO" );
		IupSetHandle( "btnIncludePathUp_Handle", btnIncludePathUp );
		IupSetCallback( btnIncludePathUp, "ACTION", cast(Icallback) &CProjectPropertiesDialog_Up_cb );
		
		Ihandle* btnIncludePathDown = IupButton( null, null );
		IupSetAttributes( btnIncludePathDown, "IMAGE=icon_downarrow,FLAT=YES,CANFOCUS=NO" );
		IupSetHandle( "btnIncludePathDown_Handle", btnIncludePathDown );
		IupSetCallback( btnIncludePathDown, "ACTION", cast(Icallback) &CProjectPropertiesDialog_Down_cb );
		
		Ihandle* vBoxButtonIncludePath = IupVbox( btnIncludePathAdd, btnIncludePathErase, btnIncludePathEdit, btnIncludePathUp, btnIncludePathDown, null );
		Ihandle* hBoxIncludePath = IupHbox( listIncludePath, vBoxButtonIncludePath, null );
		IupSetAttribute( hBoxIncludePath, "NORMALIZESIZE", "VERTICAL" );

		Ihandle* frameIncludePath = IupFrame( hBoxIncludePath );
		IupSetAttributes( frameIncludePath, "ALIGNMENT=ACENTER,MARGIN=2x2" );
		IupSetAttribute( frameIncludePath, "TITLE", GLOBAL.languageItems["includepath"].toCString() );



		// Library Paths
		listLibPath = IupList( null );
		IupSetAttributes( listLibPath, "MULTIPLE=NO,SIZE=328x64,NAME=PRJPROPERTY_LibPaths" );
		IupSetHandle( "listLibPath_Handle", listLibPath );
		IupSetCallback( listLibPath, "DBLCLICK_CB", cast(Icallback) &CProjectPropertiesDialog_DBLCLICK_CB );

		Ihandle* btnLibPathAdd = IupButton( null, null );
		IupSetAttributes( btnLibPathAdd, "IMAGE=icon_debug_add,FLAT=YES" );
		IupSetHandle( "btnLibPathAdd_Handle", btnLibPathAdd );
		IupSetCallback( btnLibPathAdd, "ACTION", cast(Icallback) &CProjectPropertiesDialog_Add_cb );

		Ihandle* btnLibPathErase = IupButton( null, null );
		IupSetAttributes( btnLibPathErase, "IMAGE=icon_delete,FLAT=YES" );
		IupSetHandle( "btnLibPathErase_Handle", btnLibPathErase );
		IupSetCallback( btnLibPathErase, "ACTION", cast(Icallback) &CProjectPropertiesDialog_Erase_cb );
		
		Ihandle* btnLibPathEdit = IupButton( null, null );
		IupSetAttributes( btnLibPathEdit, "IMAGE=icon_Write,FLAT=YES" );
		IupSetHandle( "btnLibPathEdit_Handle", btnLibPathEdit );
		IupSetCallback( btnLibPathEdit, "ACTION", cast(Icallback) &CProjectPropertiesDialog_Edit_cb );

		Ihandle* btnLibPathUp = IupButton( null, null );
		IupSetAttributes( btnLibPathUp, "IMAGE=icon_uparrow,FLAT=YES" );
		IupSetHandle( "btnLibPathUp_Handle", btnLibPathUp );
		IupSetCallback( btnLibPathUp, "ACTION", cast(Icallback) &CProjectPropertiesDialog_Up_cb );
		
		Ihandle* btnLibPathDown = IupButton( null, null );
		IupSetAttributes( btnLibPathDown, "IMAGE=icon_downarrow,FLAT=YES" );
		IupSetHandle( "btnLibPathDown_Handle", btnLibPathDown );
		IupSetCallback( btnLibPathDown, "ACTION", cast(Icallback) &CProjectPropertiesDialog_Down_cb );

		Ihandle* vBoxButtonLibPath = IupVbox( btnLibPathAdd, btnLibPathErase, btnLibPathEdit, btnLibPathUp, btnLibPathDown, null );
		Ihandle* hBoxLibPath = IupHbox( listLibPath, vBoxButtonLibPath, null );
		IupSetAttribute( hBoxLibPath, "NORMALIZESIZE", "VERTICAL" );
		
		Ihandle* frameLibPath = IupFrame( hBoxLibPath );
		IupSetAttributes( frameLibPath, "ALIGNMENT=ACENTER,MARGIN=2x2" );
		IupSetAttribute( frameLibPath, "TITLE", GLOBAL.languageItems["librarypath"].toCString() );

		Ihandle* vBoxPage02 = IupVbox( frameIncludePath, frameLibPath, null );
		IupSetAttributes( vBoxPage02, "ALIGNMENT=ALEFT,MARGIN=2x0,GAP=0" );

		IupSetAttribute( vBoxPage01, "TABTITLE", GLOBAL.languageItems["general"].toCString() );
		IupSetAttribute( vBoxPage02, "TABTITLE", GLOBAL.languageItems["include"].toCString() );
		version(Windows)
		{
			Ihandle* projectTabs = IupFlatTabs( vBoxPage01, vBoxPage02, null );
			IupSetStrAttribute( projectTabs, "BGCOLOR", toStringz( GLOBAL.editColor.dlgBack ) );
		}
		else
		{
			Ihandle* projectTabs = IupTabs( vBoxPage01, vBoxPage02, null );
		}
		IupSetAttributes( projectTabs, "TABTYPE=TOP,EXPAND=YES" );

		Ihandle* vBox = IupVbox( projectTabs, bottom, null );
		IupSetAttributes( vBox, "ALIGNMENT=ACENTER,MARGIN=2x2,GAP=2,EXPAND=YES" );

		IupAppend( _dlg, vBox );

		// Set btnOK Action
		IupSetCallback( btnOK, "FLAT_ACTION", cast(Icallback) &CProjectPropertiesDialog_btnOK_cb );
		IupSetCallback( btnAPPLY, "FLAT_ACTION", cast(Icallback) &CProjectPropertiesDialog_btnApply_cb );
	}

	public:
	this( int w, int h, string title, bool bResize = true, bool bNew = true, string existedDir = "" )
	{
		super( w, h, title, bResize, "POSEIDON_MAIN_DIALOG" );
		bCreateNew = bNew;
		IupSetAttributes( _dlg, "MINBOX=NO,MAXBOX=NO,ICON=icon_properties" );
		IupSetHandle( "PRJPROPERTY_DIALOG", _dlg );
		
		// Init the tempProject
		PROJECT emptyProject;
		tempProject = emptyProject;

		createLayout();
		
		version(Windows)
		{
			IupSetStrAttribute( textProjectName, "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( textProjectName, "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );		
			IupSetStrAttribute( textProjectDir, "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( textProjectDir, "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
			IupSetStrAttribute( textMainFile, "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( textMainFile, "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
			IupSetStrAttribute( textTargetName, "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( textTargetName, "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
			IupSetStrAttribute( textArgs, "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( textArgs, "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
			IupSetStrAttribute( textCompilerOpts, "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( textCompilerOpts, "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
			IupSetStrAttribute( textCompilerPath, "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( textCompilerPath, "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
			IupSetStrAttribute( listIncludePath, "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( listIncludePath, "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
			IupSetStrAttribute( listLibPath, "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( listLibPath, "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
			IupSetStrAttribute( listType, "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( listType, "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
			IupSetStrAttribute( listFocus, "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( listFocus, "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
		}

		if( !bCreateNew )
		{
			IupSetAttribute( textProjectDir, "ACTIVE", "NO" );
			IupSetAttribute( btnProjectDir, "ACTIVE", "NO" );
			IupSetStrAttribute( textProjectDir, "BGCOLOR",  IupGetGlobal("DLGBGCOLOR") );
			
			// Set tempProject = Active Project
			tempProject = GLOBAL.projectManager[actionManager.ProjectAction.getActiveProjectName];
			
			IupSetStrAttribute( textProjectName, "VALUE", toStringz( tempProject.name ) );
			IupSetStrAttribute( listType, "VALUE", toStringz( tempProject.type ) );
			IupSetStrAttribute( textProjectDir, "VALUE", toStringz( tempProject.dir ) );
			version(FBIDE) if( tempProject.passOneFile == "ON" ) IupSetAttribute( toggleOneFile, "VALUE", "ON" );
			IupSetAttribute( textArgs, "VALUE", toStringz( tempProject.args ) );
			version(FBIDE) IupSetStrAttribute( textMainFile, "VALUE", toStringz( tempProject.mainFile ) );
			
			int _item;
			if( tempProject.focusUnit.length > 0 ) IupSetAttributeId( listFocus, "", ++_item, "" );
			foreach( size_t i, string key; tempProject.focusUnit.keys )
				IupSetStrAttributeId( listFocus, "", ++_item, toStringz( key ) );
				
			if( tempProject.focusOn.length ) IupSetStrAttribute( listFocus, "VALUE", toStringz( tempProject.focusOn ) );

			if( tempProject.focusOn in tempProject.focusUnit )
			{
				FocusUnit beFocusUnit = tempProject.focusUnit[tempProject.focusOn];

				IupSetStrAttribute( textTargetName, "VALUE", toStringz( beFocusUnit.Target ) );
				IupSetStrAttribute( textCompilerOpts, "VALUE", toStringz( beFocusUnit.Option ) );
				IupSetStrAttribute( textCompilerPath, "VALUE", toStringz( beFocusUnit.Compiler ) );
				
				for( int i = 0; i < beFocusUnit.IncDir.length; ++ i )
					IupSetStrAttributeId( listIncludePath, "", i + 1, toStringz( beFocusUnit.IncDir[i] ) );
				
				for( int i = 0; i < beFocusUnit.LibDir.length; ++ i )
					IupSetStrAttributeId( listLibPath, "", i + 1, toStringz( beFocusUnit.LibDir[i] ) );
			}
			else
			{
				IupSetStrAttribute( textTargetName, "VALUE", toStringz( tempProject.targetName ) );
				IupSetStrAttribute( textCompilerOpts, "VALUE", toStringz( tempProject.compilerOption ) );
				IupSetStrAttribute( textCompilerPath, "VALUE", toStringz( tempProject.compilerPath ) );
				
				for( int i = 0; i < tempProject.includeDirs.length; i++ )
					IupSetStrAttributeId( listIncludePath, "", i + 1, toStringz(tempProject.includeDirs[i]) );

				for( int i = 0; i < tempProject.libDirs.length; i++ )
					IupSetStrAttributeId( listLibPath, "", i + 1, toStringz(tempProject.libDirs[i]) );				
			}
		}
		else
		{
			if( existedDir.length )
			{
				IupSetStrAttribute( textProjectDir, "VALUE", toStringz( existedDir ) );
			}
			else
			{
				IupSetAttribute( textProjectDir, "ACTIVE", "YES" );
				IupSetAttribute( btnProjectDir, "ACTIVE", "YES" );
				IupSetStrAttribute( textProjectDir, "BGCOLOR",  IupGetGlobal("TXTBGCOLOR") );
			}
		}
		
		IupSetStrAttribute( _dlg, "OPACITY", toStringz( GLOBAL.editorSetting02.projectDlg ) );
		version(Windows) IupSetCallback( _dlg, "SHOW_CB", cast(Icallback) &CProjectPropertiesDialog_SHOW_CB );
		
		IupMap( _dlg );
	}

	~this()
	{
		// Free text and list's handle
		IupSetHandle( "listIncludePath_Handle", null );
		IupSetHandle( "btnIncludePathAdd_Handle", null );
		IupSetHandle( "btnIncludePathErase_Handle", null );
		IupSetHandle( "btnIncludePathEdit_Handle", null );
		IupSetHandle( "btnIncludePathUp_Handle", null );
		IupSetHandle( "btnIncludePathDown_Handle", null );

		IupSetHandle( "listLibPath_Handle", null );
		IupSetHandle( "btnLibPathAdd_Handle", null );
		IupSetHandle( "btnLibPathErase_Handle", null );
		IupSetHandle( "btnLibPathEdit_Handle", null );
		IupSetHandle( "btnLibPathUp_Handle", null );
		IupSetHandle( "btnLibPathDown_Handle", null );
		
		for( int i = 0; i < labelTitle.length; ++ i )
			if( labelTitle[i] !is null ) destroy( labelTitle[i] );
	}
	
	Ihandle* getHandle()
	{
		return _dlg;
	}
}

private:
extern(C) // Callback for CProjectPropertiesDialog
{
	int CProjectPropertiesDialog_listFocus_ACTION( Ihandle* ih, char* text, int item, int state )
	{
		if( state == 1 )
		{
			Ihandle* _dlg = IupGetHandle( "PRJPROPERTY_DIALOG" );
			if( _dlg != null )
			{
				string focusTitle = strip( fSTRz( text ) );
				if( !focusTitle.length )
				{
					IupSetStrAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_TargetName" ), "VALUE", toStringz( CProjectPropertiesDialog.tempProject.targetName ) );
					IupSetStrAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_Options" ), "VALUE", toStringz( CProjectPropertiesDialog.tempProject.compilerOption ) );
					IupSetStrAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_CompilerPath" ), "VALUE", toStringz( CProjectPropertiesDialog.tempProject.compilerPath ) );

					IupSetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_IncludePaths" ), "REMOVEITEM", "ALL" );
					for( int i = 0; i < CProjectPropertiesDialog.tempProject.includeDirs.length; ++ i )
						IupSetStrAttributeId( IupGetDialogChild( _dlg, "PRJPROPERTY_IncludePaths" ), "", i + 1, toStringz( CProjectPropertiesDialog.tempProject.includeDirs[i] ) );
					
					IupSetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_LibPaths" ), "REMOVEITEM", "ALL" );
					for( int i = 0; i < CProjectPropertiesDialog.tempProject.libDirs.length; ++ i )
						IupSetStrAttributeId( IupGetDialogChild( _dlg, "PRJPROPERTY_LibPaths" ), "", i + 1, toStringz( CProjectPropertiesDialog.tempProject.libDirs[i] ) );
				}
				else
				{
					if( focusTitle in CProjectPropertiesDialog.tempProject.focusUnit )
					{
						IupSetStrAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_TargetName" ), "VALUE", toStringz( CProjectPropertiesDialog.tempProject.focusUnit[focusTitle].Target ) );
						IupSetStrAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_Options" ), "VALUE", toStringz( CProjectPropertiesDialog.tempProject.focusUnit[focusTitle].Option ) );
						IupSetStrAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_CompilerPath" ), "VALUE", toStringz( CProjectPropertiesDialog.tempProject.focusUnit[focusTitle].Compiler ) );
						
						IupSetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_IncludePaths" ), "REMOVEITEM", "ALL" );
						for( int i = 0; i < CProjectPropertiesDialog.tempProject.focusUnit[focusTitle].IncDir.length; ++ i )
							IupSetStrAttributeId( IupGetDialogChild( _dlg, "PRJPROPERTY_IncludePaths" ), "", i + 1, toStringz( CProjectPropertiesDialog.tempProject.focusUnit[focusTitle].IncDir[i] ) );
						
						IupSetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_LibPaths" ), "REMOVEITEM", "ALL" );
						for( int i = 0; i < CProjectPropertiesDialog.tempProject.focusUnit[focusTitle].LibDir.length; ++ i )
							IupSetStrAttributeId( IupGetDialogChild( _dlg, "PRJPROPERTY_LibPaths" ), "", i + 1, toStringz( CProjectPropertiesDialog.tempProject.focusUnit[focusTitle].LibDir[i] ) );
					}
				}
			}
		}
		
		return IUP_DEFAULT;
	}

	int CProjectPropertiesDialog_btnOK_cb( Ihandle* ih )
	{
		// Apply First!!!
		if( CProjectPropertiesDialog_btnApply_cb( null ) == IUP_IGNORE )
		{
			tools.MessageDlg( GLOBAL.languageItems["alarm"].toDString(), GLOBAL.languageItems["nodirmessage"].toDString, "WARNING", "", IUP_CENTER, IUP_CENTER );
			return IUP_IGNORE;
		}
		
		
		Ihandle* dirHandle = IupGetDialogChild( IupGetHandle( "PRJPROPERTY_DIALOG" ), "PRJPROPERTY_ProjectDir" );
		if( dirHandle != null )
		{
			if( !CProjectPropertiesDialog.tempProject.name.length )
			{
				CProjectPropertiesDialog.tempProject.name = Path.stripExtension( Path.baseName( normalizeSlash( CProjectPropertiesDialog.tempProject.dir ) ) );
				IupSetStrAttribute( IupGetDialogChild( IupGetHandle( "PRJPROPERTY_DIALOG" ), "PRJPROPERTY_ProjectName" ), "VALUE", toStringz( CProjectPropertiesDialog.tempProject.name ) );
			}		
		
			if( fromStringz( IupGetAttribute( dirHandle, "ACTIVE" ) ) == "NO" ) // Created project
			{
				if( CProjectPropertiesDialog.tempProject.dir in GLOBAL.projectManager )
				{
					CProjectPropertiesDialog.tempProject.sources = GLOBAL.projectManager[CProjectPropertiesDialog.tempProject.dir].sources;
					CProjectPropertiesDialog.tempProject.includes = GLOBAL.projectManager[CProjectPropertiesDialog.tempProject.dir].includes;
					CProjectPropertiesDialog.tempProject.others = GLOBAL.projectManager[CProjectPropertiesDialog.tempProject.dir].others;
				}
			}

			GLOBAL.projectManager[CProjectPropertiesDialog.tempProject.dir] = CProjectPropertiesDialog.tempProject;
			if( !GLOBAL.projectManager[CProjectPropertiesDialog.tempProject.dir].saveFile() )
			{
				GLOBAL.projectManager.remove( CProjectPropertiesDialog.tempProject.dir );
				return IUP_CLOSE;
			}

			// Recent Projects
			GLOBAL.projectTree.updateRecentProjects( CProjectPropertiesDialog.tempProject.dir, CProjectPropertiesDialog.tempProject.name );
			if( fromStringz( IupGetAttribute( dirHandle, "ACTIVE" ) ) == "YES" ) GLOBAL.projectTree.CreateNewProject( CProjectPropertiesDialog.tempProject.name, CProjectPropertiesDialog.tempProject.dir );
			GLOBAL.statusBar.setPrjName( GLOBAL.languageItems["caption_prj"].toDString ~ ": " ~ GLOBAL.projectManager[CProjectPropertiesDialog.tempProject.dir].name 
										~ ( GLOBAL.projectManager[CProjectPropertiesDialog.tempProject.dir].focusOn.length ? " [" ~ GLOBAL.projectManager[CProjectPropertiesDialog.tempProject.dir].focusOn ~ "]" : "" ) );
		}

		return IUP_CLOSE;
	}

	int CProjectPropertiesDialog_btnApply_cb( Ihandle* ih )
	{
		//PRJPROPERTY_FocusList
		Ihandle* _dlg = IupGetHandle( "PRJPROPERTY_DIALOG" );
		if( _dlg != null )
		{
			Ihandle* dirHandle = IupGetDialogChild( _dlg, "PRJPROPERTY_ProjectDir" );
			if( dirHandle != null )
			{
				string	_prjDir	= strip( fSTRz( IupGetAttribute( dirHandle, "VALUE" ) ) );

				if( _prjDir.length )
				{
					CProjectPropertiesDialog.tempProject.name = strip( fSTRz( IupGetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_ProjectName" ), "VALUE" ) ) );
					CProjectPropertiesDialog.tempProject.dir = tools.normalizeSlash( _prjDir );
					CProjectPropertiesDialog.tempProject.type = strip( fSTRz( IupGetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_TypeList" ), "VALUE" ) ) );
					version(FBIDE) CProjectPropertiesDialog.tempProject.mainFile = strip( fSTRz( IupGetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_ProjectMainFile" ), "VALUE" ) ) );
					CProjectPropertiesDialog.tempProject.args = strip( fSTRz( IupGetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_Args" ), "VALUE" ) ) );
					CProjectPropertiesDialog.tempProject.focusOn = strip( fSTRz( IupGetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_FocusList" ), "VALUE" ) ) );
					version(FBIDE) CProjectPropertiesDialog.tempProject.passOneFile = strip( fSTRz( IupGetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_ToggleOneFile" ), "VALUE" ) ) );
					
					// Change Project Tree Title
					if( fromStringz( IupGetAttribute( dirHandle, "ACTIVE" ) ) == "NO" ) // Created project
					{
						if( actionManager.ProjectAction.getActiveProjectTreeNodeTitle != CProjectPropertiesDialog.tempProject.name ) actionManager.ProjectAction.changeActiveProjectTreeNodeTitle( CProjectPropertiesDialog.tempProject.name );
					}
				}
				else
				{
					return IUP_IGNORE;
				}
			}
			else
			{
				return IUP_IGNORE;
			}
		
		
			Ihandle* focusList = IupGetDialogChild( _dlg, "PRJPROPERTY_FocusList" );
			if( focusList != null )
			{
				string focusTitle = strip( fSTRz( IupGetAttribute( focusList, "VALUE" ) ) );
				if( focusTitle.length )
				{
					FocusUnit _focusUnit;
					_focusUnit.Target = strip( fSTRz( IupGetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_TargetName" ), "VALUE" ) ) );
					_focusUnit.Option = strip( fSTRz( IupGetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_Options" ), "VALUE" ) ) );
					_focusUnit.Compiler = strip( fSTRz( IupGetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_CompilerPath" ), "VALUE" ) ) );
					
					//PRJPROPERTY_IncludePaths, PRJPROPERTY_LibPaths
					int		includeCount = IupGetInt( IupGetDialogChild( _dlg, "PRJPROPERTY_IncludePaths" ), "COUNT" );
					for( int i = 1; i <= includeCount; i++ )
						_focusUnit.IncDir ~= fSTRz( IupGetAttributeId( IupGetDialogChild( _dlg, "PRJPROPERTY_IncludePaths" ), "", i ) );
					
					int		libCount = IupGetInt( IupGetDialogChild( _dlg, "PRJPROPERTY_LibPaths" ), "COUNT" );
					for( int i = 1; i <= libCount; i++ )
						_focusUnit.LibDir ~= fSTRz( IupGetAttributeId( IupGetDialogChild( _dlg, "PRJPROPERTY_LibPaths" ), "", i ) );
						
					CProjectPropertiesDialog.tempProject.focusUnit[focusTitle] = _focusUnit;
					actionManager.SearchAction.addListItem( focusList, focusTitle, 100 );
					IupSetAttributeId( focusList, "INSERTITEM", 1, "" );
					IupSetStrAttribute( focusList, "VALUE", toStringz( focusTitle ) );
				}
				else
				{
					CProjectPropertiesDialog.tempProject.targetName	= strip( fSTRz( IupGetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_TargetName" ), "VALUE" ) ) );
					CProjectPropertiesDialog.tempProject.compilerOption	= strip( fSTRz( IupGetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_Options" ), "VALUE" ) ) );
					CProjectPropertiesDialog.tempProject.compilerPath = strip( fSTRz( IupGetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_CompilerPath" ), "VALUE" ) ) );
					
					CProjectPropertiesDialog.tempProject.includeDirs.length = 0;
					int		includeCount = IupGetInt( IupGetDialogChild( _dlg, "PRJPROPERTY_IncludePaths" ), "COUNT" );
					for( int i = 1; i <= includeCount; i++ )
						CProjectPropertiesDialog.tempProject.includeDirs ~= fSTRz( IupGetAttributeId( IupGetDialogChild( _dlg, "PRJPROPERTY_IncludePaths" ), "", i ) );
					
					CProjectPropertiesDialog.tempProject.libDirs.length = 0;
					int		libCount = IupGetInt( IupGetDialogChild( _dlg, "PRJPROPERTY_LibPaths" ), "COUNT" );
					for( int i = 1; i <= libCount; i++ )
						CProjectPropertiesDialog.tempProject.libDirs ~= fSTRz( IupGetAttributeId( IupGetDialogChild( _dlg, "PRJPROPERTY_LibPaths" ), "", i ) );
				}
			}
			else
			{
				return IUP_IGNORE;
			}
		}
		else
		{
			return IUP_IGNORE;
		}
		
		
		return IUP_DEFAULT;
	}
	
	int CProjectPropertiesDialog_btnProjectDir_cb( Ihandle* ih )
	{
		scope fileSelectDlg = new CFileDlg( null, null, "DIR" );
		string fileName = fileSelectDlg.getFileName();

		if( fileName.length )
		{
			Ihandle* _dlg = IupGetHandle( "PRJPROPERTY_DIALOG" );
			if( _dlg != null )
			{
				Ihandle* textPrjPath = IupGetDialogChild( _dlg, "PRJPROPERTY_ProjectDir" );
				if( textPrjPath != null )
				{
					IupSetStrAttribute( textPrjPath, "VALUE", toStringz( fileName ) );
					
					Ihandle* textProjectName = IupGetDialogChild( _dlg, "PRJPROPERTY_ProjectName" );
					if( textProjectName != null )
					{
						string projectName = strip( fSTRz( IupGetAttribute( textProjectName, "VALUE" ) ) );
						if( !projectName.length ) IupSetStrAttribute( textProjectName, "VALUE", toStringz( Path.stripExtension( Path.baseName( fileName ) ) ) );
					}
				}
			}
		}
		else
		{
			//Writefln( "NoThing!!!" ).newline;
		}

		return IUP_DEFAULT;
	}

	int CProjectPropertiesDialog_btnCompilerPath_cb( Ihandle* ih ) 
	{
		auto mother = IupGetParent( ih );
		if( !mother ) return IUP_DEFAULT;
		
		auto _textElement = IupGetChild( mother, 1 );
		if( !_textElement ) return IUP_DEFAULT;
		
		string relatedPath = fSTRz( IupGetAttribute( _textElement, "VALUE" ) );
		scope fileSelectDlg = new CFileDlg( GLOBAL.languageItems["compilerpath"].toDString() ~ "...", GLOBAL.languageItems["exefile"].toDString() ~ "|*.exe", "OPEN", "NO", relatedPath );
		
		string fileName = fileSelectDlg.getFileName();
		if( fileName.length ) IupSetStrAttribute( _textElement, "VALUE", toStringz( tools.normalizeSlash( fileName ) ) );

		return IUP_DEFAULT;
	}
	
	int CProjectPropertiesDialog_DBLCLICK_CB( Ihandle *ih, int item, char *text )
	{
		string label = fSTRz( IupGetAttribute( IupGetParent( IupGetParent( ih ) ), "TITLE" ) );
		scope selectFileDlg = new CSingleTextOpen( 460, -1, GLOBAL.languageItems["add"].toDString() ~ "...", label, null, fSTRz( IupGetAttributeId( ih, "", item ) ), false, "PRJPROPERTY_DIALOG" );
		string fileName = selectFileDlg.show( IUP_CENTERPARENT, IUP_CENTERPARENT );
		if( fileName.length ) IupSetStrAttributeId( ih, "", item, toStringz( tools.normalizeSlash( fileName ) ) );
		IupSetInt( ih, "VALUE", item ); // Set Focus
		
		return IUP_DEFAULT;
	}

	int CProjectPropertiesDialog_Add_cb( Ihandle* ih ) 
	{
		Ihandle*	list;
		if( ih == IupGetHandle( "btnIncludePathAdd_Handle" ) ) list = IupGetHandle( "listIncludePath_Handle" ); else list = IupGetHandle( "listLibPath_Handle" );

		string label = fSTRz( IupGetAttribute( IupGetParent( IupGetParent( list ) ), "TITLE" ) );
		scope selectFileDlg = new CSingleTextOpen( 460, -1, GLOBAL.languageItems["add"].toDString() ~ "...",label, null, "", false, "PRJPROPERTY_DIALOG" );
		string fileName = selectFileDlg.show( IUP_CENTERPARENT, IUP_CENTERPARENT );
		if( fileName.length )
		{
			IupSetStrAttribute( list, "APPENDITEM", toStringz( tools.normalizeSlash( fileName ) ) );
			IupSetInt( list, "VALUE", IupGetInt( list, "COUNT" ) ); // Set Focus
		}
		
		IupSetFocus( list );
		
		return IUP_DEFAULT;
	}

	int CProjectPropertiesDialog_Erase_cb( Ihandle* ih ) 
	{
		Ihandle* list;
		if( ih == IupGetHandle( "btnIncludePathErase_Handle" ) ) list = IupGetHandle( "listIncludePath_Handle" ); else list = IupGetHandle( "listLibPath_Handle" );

		// IupGetAttribute( list, "VALUE" ) = 0 Items has no selected, = 1,2,3.....n   #n item had be selected
		int itemNumber = IupGetInt( list, "VALUE" );
		if( itemNumber > 0 )
		{
			IupSetInt( list, "REMOVEITEM", itemNumber );
			int count = IupGetInt( list, "COUNT" );
			if( count > 0 )
			{
				if( count >= itemNumber )
					IupSetInt( list, "VALUE", itemNumber ); // Set Focus
				else
					IupSetInt( list, "VALUE", itemNumber - 1 ); // Set Focus
			}
		}
		
		IupSetFocus( list );
		
		return IUP_DEFAULT;
	}

	int CProjectPropertiesDialog_Edit_cb( Ihandle* ih ) 
	{
		Ihandle* list;
		if( ih == IupGetHandle( "btnIncludePathEdit_Handle" ) ) list = IupGetHandle( "listIncludePath_Handle" ); else list = IupGetHandle( "listLibPath_Handle" );

		// IupGetAttribute( list, "VALUE" ) = 0 Items has no selected, = 1,2,3.....n   #n item had be selected
		int itemNumber = IupGetInt( list, "VALUE" );
		if( itemNumber > 0 )
		{
			string label = fSTRz( IupGetAttribute( IupGetParent( IupGetParent( list ) ), "TITLE" ) );
			scope selectFileDlg = new CSingleTextOpen( 460, -1, GLOBAL.languageItems["add"].toDString() ~ "...", label, null, fSTRz( IupGetAttributeId( list, "", itemNumber ) ), false, "PRJPROPERTY_DIALOG" );
			string fileName = selectFileDlg.show( IUP_CENTERPARENT, IUP_CENTERPARENT );
			if( fileName.length ) IupSetStrAttributeId( list, "", itemNumber, toStringz( tools.normalizeSlash( fileName ) ) );
			
			IupSetInt( list, "VALUE", itemNumber ); // Set Focus
		}
		
		IupSetFocus( list );
		
		return IUP_DEFAULT;
	}

	int CProjectPropertiesDialog_Up_cb( Ihandle* ih ) 
	{
		Ihandle* list;
		if( ih == IupGetHandle( "btnIncludePathUp_Handle" ) ) list = IupGetHandle( "listIncludePath_Handle" ); else list = IupGetHandle( "listLibPath_Handle" );

		int itemNumber = IupGetInt( list, "VALUE" );

		if( itemNumber > 1 )
		{
			string prevItemText = fSTRz( IupGetAttributeId( list, "", itemNumber-1 ) );
			string nowItemText = fSTRz( IupGetAttributeId( list, "", itemNumber ) );

			IupSetStrAttributeId( list, "", itemNumber-1, toStringz( nowItemText ) );
			IupSetStrAttributeId( list, "", itemNumber, toStringz( prevItemText ) );

			IupSetInt( list, "VALUE", itemNumber-1 ); // Set Focus
		}
		
		IupSetFocus( list );

		return IUP_DEFAULT;
	}

	int CProjectPropertiesDialog_Down_cb( Ihandle* ih ) 
	{
		Ihandle* list;
		if( ih == IupGetHandle( "btnIncludePathDown_Handle" ) ) list = IupGetHandle( "listIncludePath_Handle" ); else list = IupGetHandle( "listLibPath_Handle" );

		int itemNumber = IupGetInt( list, "VALUE" );
		int itemCount = IupGetInt( list, "COUNT" );

		if( itemNumber < itemCount )
		{
			string nextItemText = fSTRz( IupGetAttributeId( list, "", itemNumber+1 ) );
			string nowItemText = fSTRz( IupGetAttributeId( list, "", itemNumber ) );

			IupSetStrAttributeId( list, "", itemNumber+1, toStringz( nowItemText ) );
			IupSetStrAttributeId( list, "", itemNumber, toStringz( nextItemText ) );

			IupSetInt( list, "VALUE", itemNumber+1 ); // Set Focus
		}
		
		IupSetFocus( list );

		return IUP_DEFAULT;
	}
	
	version(Windows) int CProjectPropertiesDialog_SHOW_CB( Ihandle* ih, int state )
	{
		if( state == IUP_SHOW )
		{
			Ihandle* _typeHandle = IupGetDialogChild( ih, "PRJPROPERTY_TypeList" );
			Ihandle* _focusHandle = IupGetDialogChild( ih, "PRJPROPERTY_FocusList" );
			if( _typeHandle != null && _focusHandle != null )
			{
				bool _UseDarkMode = GLOBAL.editorSetting00.UseDarkMode == "ON" ? true : false;
				tools.setWinTheme( _typeHandle, "CFD", _UseDarkMode );
				tools.setWinTheme( _focusHandle, "CFD", _UseDarkMode );
			}
		}
		
		return IUP_DEFAULT;
	}	
	
}