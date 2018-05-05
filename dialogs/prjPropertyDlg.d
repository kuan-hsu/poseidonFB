module dialogs.prjPropertyDlg;

private import iup.iup, iup.iup_scintilla;

private import global, project, scintilla, actionManager;
private import dialogs.baseDlg, dialogs.fileDlg;

private import tango.stdc.stringz, tango.io.FilePath, Util = tango.text.Util, Path = tango.io.Path;

class CProjectPropertiesDialog : CBaseDialog
{
	private:
	
	Ihandle*	textProjectName, listType, textProjectDir, textMainFile, toggleOneFile, textTargetName, textArgs, textCompilerOpts, textComment, textCompilerPath;
	Ihandle*	listFocus;
	Ihandle*	btnProjectDir;
	Ihandle*	listIncludePath, listLibPath;
	
	bool		bCreateNew = true;
	
	static PROJECT	tempProject;
	

	void createLayout()
	{
		Ihandle* bottom = createDlgButton( "40x12", "aoc" );

		// PAGE 1 General
		// Line 1
		Ihandle* labelProjectName = IupLabel( toStringz( GLOBAL.languageItems["prjname"].toDString ~ ":" ) );
		IupSetAttributes( labelProjectName, "SIZE=60x20" );
		
		textProjectName = IupText( null );
		IupSetAttributes( textProjectName, "SIZE=130x12,NAME=PRJPROPERTY_ProjectName" );
		IupSetHandle( "textProjectName", textProjectName );
		
		Ihandle* labelType = IupLabel( toStringz( GLOBAL.languageItems["prjtype"].toDString ~ ":" ) );
		IupSetAttributes( labelType, "SIZE=40x20,ALIGNMENT=ACENTER" );
		
		listType = IupList( null );
		IupSetAttributes( listType, "SHOWIMAGE=NO,VALUE=1,DROPDOWN=YES,VISIBLE_ITEMS=3,SIZE=106x,NAME=PRJPROPERTY_TypeList" );
		IupSetAttribute( listType, "1", GLOBAL.languageItems["console"].toCString() );
		IupSetAttribute( listType, "2", GLOBAL.languageItems["static"].toCString() );
		IupSetAttribute( listType, "3", GLOBAL.languageItems["dynamic"].toCString() );

		Ihandle* hBox00 = IupHbox( labelProjectName, textProjectName, labelType, listType, null );
		IupSetAttribute( hBox00, "ALIGNMENT", "ACENTER" );
		

		// Line 2
		Ihandle* labelProjectDir = IupLabel( toStringz( GLOBAL.languageItems["prjdir"].toDString ~ ":" ) );
		IupSetAttributes( labelProjectDir, "SIZE=60x20" );
		
		textProjectDir = IupText( null );
		IupSetAttributes( textProjectDir, "SIZE=276x12,NAME=PRJPROPERTY_ProjectDir" );
		IupSetHandle( "textProjectDir", textProjectDir );

		btnProjectDir = IupButton( null, null );
		IupSetAttributes( btnProjectDir, "IMAGE=icon_openfile,FLAT=YES" );
		IupSetCallback( btnProjectDir, "ACTION", cast(Icallback) &CProjectPropertiesDialog_btnProjectDir_cb );

		Ihandle* hBox01 = IupHbox( labelProjectDir, textProjectDir, btnProjectDir, null );
		IupSetAttribute( hBox01, "ALIGNMENT", "ACENTER" );	

		// Line 3
		Ihandle* labelMainFile = IupLabel( toStringz( GLOBAL.languageItems["prjmainfile"].toDString ~ ":" ) );
		IupSetAttributes( labelMainFile, "SIZE=60x20" );
		
		textMainFile = IupText( null );
		IupSetAttributes( textMainFile, "SIZE=130x12,NAME=PRJPROPERTY_ProjectMainFile" );
		
		version(FBIDE)
		{
			toggleOneFile = IupToggle( GLOBAL.languageItems["prjonefile"].toCString, null );
			IupSetAttributes( toggleOneFile, "SIZE=140x12,NAME=PRJPROPERTY_ToggleOneFile" );
		
			Ihandle* hBox02 = IupHbox( labelMainFile, textMainFile, IupFill, toggleOneFile, IupFill, null );
		}
		version(DIDE)
		{
			Ihandle* hBox02 = IupHbox( labelMainFile, textMainFile, null );
		}
		IupSetAttribute( hBox02, "ALIGNMENT", "ACENTER" );
		
		

		
		// Line 4
		Ihandle* labelTargetName = IupLabel( toStringz( GLOBAL.languageItems["prjtarget"].toDString ~ ":" ) );
		IupSetAttributes( labelTargetName, "SIZE=60x20" );
		
		textTargetName = IupText( null );
		IupSetAttributes( textTargetName, "SIZE=130x12,NAME=PRJPROPERTY_TargetName" );
		
		//
		Ihandle* labelFocus = IupLabel( "Focus:" );//IupLabel( toStringz( GLOBAL.languageItems["prjtarget"].toDString ~ ":" ) );
		IupSetAttributes( labelFocus, "SIZE=40x12,ALIGNMENT=ACENTER" );
		
		listFocus = IupList( null );
		IupSetAttributes( listFocus, "SHOWIMAGE=NO,EDITBOX=YES,DROPDOWN=YES,VISIBLE_ITEMS=5,SIZE=106x12,NAME=PRJPROPERTY_FocusList" );
		IupSetCallback( listFocus, "VALUECHANGED_CB",cast(Icallback) cast(Icallback) function( Ihandle* ih )
		{
			Ihandle* _dlg = IupGetHandle( "PRJPROPERTY_DIALOG" );
			
			if( _dlg != null )
			{
				Ihandle* _focusList = IupGetDialogChild( _dlg, "PRJPROPERTY_FocusList" );
				if( _focusList != null )
				{
					char[] focusTitle = Util.trim( fromStringz( IupGetAttribute( _focusList, "VALUE" ) ) ).dup;
					if( !focusTitle.length )
					{
						IupSetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_TargetName" ), "VALUE", toStringz( CProjectPropertiesDialog.tempProject.targetName ) );
						IupSetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_Options" ), "VALUE", toStringz( CProjectPropertiesDialog.tempProject.compilerOption ) );
						IupSetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_CompilerPath" ), "VALUE", toStringz( CProjectPropertiesDialog.tempProject.compilerPath ) );

						IupSetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_IncludePaths" ), "REMOVEITEM", "ALL" );
						for( int i = 0; i < CProjectPropertiesDialog.tempProject.includeDirs.length; ++ i )
							IupSetAttributeId( IupGetDialogChild( _dlg, "PRJPROPERTY_IncludePaths" ), "", i + 1, toStringz( CProjectPropertiesDialog.tempProject.includeDirs[i] ) );
						
						IupSetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_LibPaths" ), "REMOVEITEM", "ALL" );
						for( int i = 0; i < CProjectPropertiesDialog.tempProject.libDirs.length; ++ i )
							IupSetAttributeId( IupGetDialogChild( _dlg, "PRJPROPERTY_LibPaths" ), "", i + 1, toStringz( CProjectPropertiesDialog.tempProject.libDirs[i] ) );
					}
					else
					{
						if( focusTitle in CProjectPropertiesDialog.tempProject.focusUnit )
						{
							IupSetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_TargetName" ), "VALUE", toStringz( CProjectPropertiesDialog.tempProject.focusUnit[focusTitle].Target ) );
							IupSetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_Options" ), "VALUE", toStringz( CProjectPropertiesDialog.tempProject.focusUnit[focusTitle].Option ) );
							IupSetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_CompilerPath" ), "VALUE", toStringz( CProjectPropertiesDialog.tempProject.focusUnit[focusTitle].Compiler ) );
							
							IupSetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_IncludePaths" ), "REMOVEITEM", "ALL" );
							for( int i = 0; i < CProjectPropertiesDialog.tempProject.focusUnit[focusTitle].IncDir.length; ++ i )
								IupSetAttributeId( IupGetDialogChild( _dlg, "PRJPROPERTY_IncludePaths" ), "", i + 1, toStringz( CProjectPropertiesDialog.tempProject.focusUnit[focusTitle].IncDir[i] ) );
							
							IupSetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_LibPaths" ), "REMOVEITEM", "ALL" );
							for( int i = 0; i < CProjectPropertiesDialog.tempProject.focusUnit[focusTitle].LibDir.length; ++ i )
								IupSetAttributeId( IupGetDialogChild( _dlg, "PRJPROPERTY_LibPaths" ), "", i + 1, toStringz( CProjectPropertiesDialog.tempProject.focusUnit[focusTitle].LibDir[i] ) );
						}
					}
				}
			}
			
			return IUP_DEFAULT;
		});
		
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
					char[] focusTitle = Util.trim( fromStringz( IupGetAttribute( _focusList, "VALUE" ) ) ).dup;
			
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

								IupSetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_TargetName" ), "VALUE", toStringz( CProjectPropertiesDialog.tempProject.targetName ) );
								IupSetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_Options" ), "VALUE", toStringz( CProjectPropertiesDialog.tempProject.compilerOption ) );
								IupSetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_CompilerPath" ), "VALUE", toStringz( CProjectPropertiesDialog.tempProject.compilerPath ) );

								IupSetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_IncludePaths" ), "REMOVEITEM", "ALL" );
								for( int i = 0; i < CProjectPropertiesDialog.tempProject.includeDirs.length; ++ i )
									IupSetAttributeId( IupGetDialogChild( _dlg, "PRJPROPERTY_IncludePaths" ), "", i + 1, toStringz( CProjectPropertiesDialog.tempProject.includeDirs[i] ) );
								
								IupSetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_LibPaths" ), "REMOVEITEM", "ALL" );
								for( int i = 0; i < CProjectPropertiesDialog.tempProject.libDirs.length; ++ i )
									IupSetAttributeId( IupGetDialogChild( _dlg, "PRJPROPERTY_LibPaths" ), "", i + 1, toStringz( CProjectPropertiesDialog.tempProject.libDirs[i] ) );
								
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

		// Line 7
		Ihandle* labelComment = IupLabel( toStringz( GLOBAL.languageItems["prjcomment"].toDString ~ ":" ) );
		IupSetAttributes( labelComment, "SIZE=60x20" );
		
		textComment = IupText( null );
		IupSetAttributes( textComment, "SIZE=276x20,MULTILINE=YES,SCROLLBAR=VERTICAL,NAME=PRJPROPERTY_Comment" );
		
		Ihandle* hBox06 = IupHbox( labelComment, textComment, null );
		IupSetAttribute( hBox06, "ALIGNMENT", "ACENTER" );

		// Line 8
		Ihandle* labelCompilerPath = IupLabel( toStringz( GLOBAL.languageItems["prjcompiler"].toDString ~ ":" ) );
		IupSetAttributes( labelCompilerPath, "SIZE=60x20" );
		
		textCompilerPath = IupText( null );
		IupSetAttributes( textCompilerPath, "SIZE=276x12,NAME=PRJPROPERTY_CompilerPath" );

		Ihandle* btnCompilerPath = IupButton( null, null );
		IupSetAttributes( btnCompilerPath, "IMAGE=icon_openfile,FLAT=YES" );
		IupSetCallback( btnCompilerPath, "ACTION", cast(Icallback) &CProjectPropertiesDialog_btnCompilerPath_cb );		
		
		Ihandle* hBox07 = IupHbox( labelCompilerPath, textCompilerPath, btnCompilerPath, null );
		IupSetAttribute( hBox07, "ALIGNMENT", "ACENTER" );

		/+
		// Line 7
		Ihandle* listFiles = IupList( null );
		IupSetAttributes( listFiles, "1=\"100m dash\", 2=\"Long jump\", 3=\"Javelin throw\", 4=\"110m hurdlers\", 5=\"Hammer throw\",6=\"High jump\",7=\"High jump\",8=\"High jump\",9=\"High jump\",10=\"High jump\","
                                   "MULTIPLE=YES, VALUE=\"+--+--\", SIZE=328x64" );
		
		Ihandle* framePage01 = IupFrame( listFiles );
		IupSetAttribute( framePage01, "ALIGNMENT", "ACENTER" );
		IupSetAttribute( framePage01, "MARGIN", "2x2" );
		IupSetAttribute(framePage01, "TITLE", "File List");
		+/

		Ihandle* vBoxPage01 = IupVbox( hBox00, hBox01, hBox02, hBox03, hBox04, hBox05, hBox06, hBox07, null );
		IupSetAttributes( vBoxPage01, "ALIGNMENT=ALEFT,MARGIN=2x0,GAP=0" );


		// PAGE 2 Include...
		// Include Paths
		listIncludePath = IupList( null );
		IupSetAttributes( listIncludePath, "MULTIPLE=NO,SIZE=326x64,NAME=PRJPROPERTY_IncludePaths" );
		IupSetHandle( "listIncludePath_Handle", listIncludePath );
		
		Ihandle* btnIncludePathAdd = IupButton( null, null );
		IupSetAttributes( btnIncludePathAdd, "IMAGE=icon_openfile,FLAT=YES" );
		IupSetHandle( "btnIncludePathAdd_Handle", btnIncludePathAdd );
		IupSetCallback( btnIncludePathAdd, "ACTION", cast(Icallback) &CProjectPropertiesDialog_Add_cb );

		Ihandle* btnIncludePathErase = IupButton( null, null );
		IupSetAttributes( btnIncludePathErase, "IMAGE=icon_delete,FLAT=YES" );
		IupSetHandle( "btnIncludePathErase_Handle", btnIncludePathErase );
		IupSetCallback( btnIncludePathErase, "ACTION", cast(Icallback) &CProjectPropertiesDialog_Erase_cb );
		
		Ihandle* btnIncludePathEdit = IupButton( null, null );
		IupSetAttributes( btnIncludePathEdit, "IMAGE=icon_Write,FLAT=YES" );
		IupSetHandle( "btnIncludePathEdit_Handle", btnIncludePathEdit );
		IupSetCallback( btnIncludePathEdit, "ACTION", cast(Icallback) &CProjectPropertiesDialog_Edit_cb );

		Ihandle* btnIncludePathUp = IupButton( null, null );
		IupSetAttributes( btnIncludePathUp, "IMAGE=icon_uparrow,FLAT=YES" );
		IupSetHandle( "btnIncludePathUp_Handle", btnIncludePathUp );
		IupSetCallback( btnIncludePathUp, "ACTION", cast(Icallback) &CProjectPropertiesDialog_Up_cb );
		
		Ihandle* btnIncludePathDown = IupButton( null, null );
		IupSetAttributes( btnIncludePathDown, "IMAGE=icon_downarrow,FLAT=YES" );
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

		Ihandle* btnLibPathAdd = IupButton( null, null );
		IupSetAttributes( btnLibPathAdd, "IMAGE=icon_openfile,FLAT=YES" );
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

		
		//IupSetAttribute( hBox, "EXPAND", "YES" );
		
		Ihandle* projectTabs = IupTabs( vBoxPage01, vBoxPage02, null );
		IupSetAttribute( projectTabs, "TABTYPE", "TOP" );
		IupSetAttribute( projectTabs, "EXPAND", "YES" );

		/*
		Ihandle* sep = IupLabel( null ); 
		IupSetAttribute( sep, "SEPARATOR", "HORIZONTAL");
		*/
		
		Ihandle* vBox = IupVbox( projectTabs, bottom, null );
		IupSetAttributes( vBox, "ALIGNMENT=ACENTER,MARGIN=5x10,GAP=2,EXPAND=YES" );

		IupAppend( _dlg, vBox );

		// Set btnOK Action
		IupSetCallback( btnOK, "ACTION", cast(Icallback) &CProjectPropertiesDialog_btnOK_cb );
		IupSetCallback( btnAPPLY, "ACTION", cast(Icallback) &CProjectPropertiesDialog_btnApply_cb );
	}

	public:
	this( int w, int h, char[] title, bool bResize = true, bool bNew = true, char[] parent = null )
	{
		super( w, h, title, bResize, parent );
		bCreateNew = bNew;
		IupSetAttributes( _dlg, "MINBOX=NO,MAXBOX=NO,ICON=icon_properties" );
		IupSetHandle( "PRJPROPERTY_DIALOG", _dlg );
		
		// Init the tempProject
		PROJECT emptyProject;
		tempProject = emptyProject;
		/*
		version( Windows )
		{
			IupSetAttribute( _dlg, "FONT", GLOBAL.cString.convert( "Courier New,9" ) );
		}
		else
		{
			IupSetAttribute( _dlg, "FONT", GLOBAL.cString.convert( "Ubuntu Mono, 10" ) );
		}
		*/
		createLayout();
		
		if( !bCreateNew )
		{
			IupSetAttribute( textProjectDir, "ACTIVE", "NO" );
			IupSetAttribute( btnProjectDir, "ACTIVE", "NO" );
			IupSetAttribute( textProjectDir, "BGCOLOR",  IupGetGlobal("DLGBGCOLOR") );
			
			// Set tempProject = Active Project
			tempProject = GLOBAL.projectManager[actionManager.ProjectAction.getActiveProjectName];
			
			IupSetAttribute( textProjectName, "VALUE", toStringz( tempProject.name ) );
			IupSetAttribute( listType, "VALUE", toStringz( tempProject.type ) );
			IupSetAttribute( textProjectDir, "VALUE", toStringz( tempProject.dir ) );
			version(FBIDE) if( tempProject.passOneFile == "ON" ) IupSetAttribute( toggleOneFile, "VALUE", "ON" );
			IupSetAttribute( textArgs, "VALUE", toStringz( tempProject.args ) );
			IupSetAttribute( textComment, "VALUE", toStringz( tempProject.comment ) );
			IupSetAttribute( textMainFile, "VALUE", toStringz( tempProject.mainFile ) );
			
			int _item;
			if( tempProject.focusUnit.length > 0 ) IupSetAttributeId( listFocus, "", ++_item, "" );
			foreach( int i, char[] key; tempProject.focusUnit.keys )
				IupSetAttributeId( listFocus, "", ++_item, toStringz( key ) );
				
			if( tempProject.focusOn.length ) IupSetAttribute( listFocus, "VALUE", toStringz( tempProject.focusOn ) );
			
			
			if( tempProject.focusOn in tempProject.focusUnit )
			{
				FocusUnit beFocusUnit = tempProject.focusUnit[tempProject.focusOn];

				IupSetAttribute( textTargetName, "VALUE", toStringz( beFocusUnit.Target ) );
				IupSetAttribute( textCompilerOpts, "VALUE", toStringz( beFocusUnit.Option ) );
				IupSetAttribute( textCompilerPath, "VALUE", toStringz( beFocusUnit.Compiler ) );
				
				for( int i = 0; i < beFocusUnit.IncDir.length; ++ i )
					IupSetAttributeId( listIncludePath, "", i + 1, toStringz( beFocusUnit.IncDir[i] ) );
				
				for( int i = 0; i < beFocusUnit.LibDir.length; ++ i )
					IupSetAttributeId( listLibPath, "", i + 1, toStringz( beFocusUnit.LibDir[i] ) );				
			}
			else
			{
				IupSetAttribute( textTargetName, "VALUE", toStringz( tempProject.targetName ) );
				IupSetAttribute( textCompilerOpts, "VALUE", toStringz( tempProject.compilerOption ) );
				IupSetAttribute( textCompilerPath, "VALUE", toStringz( tempProject.compilerPath ) );
				
				for( int i = 0; i < tempProject.includeDirs.length; i++ )
					IupSetAttributeId( listIncludePath, "", i + 1, toStringz(tempProject.includeDirs[i]) );

				for( int i = 0; i < tempProject.libDirs.length; i++ )
					IupSetAttributeId( listLibPath, "", i + 1, toStringz(tempProject.libDirs[i]) );				
			}
		}
		else
		{
			IupSetAttribute( textProjectDir, "ACTIVE", "YES" );
			IupSetAttribute( btnProjectDir, "ACTIVE", "YES" );
			IupSetAttribute( textProjectDir, "BGCOLOR",  IupGetGlobal("TXTBGCOLOR") );
		}
		
		IupSetAttribute( _dlg, "OPACITY", toStringz( GLOBAL.editorSetting02.projectDlg ) );
		IupMap( _dlg );
	}

	~this()
	{
		// Free text and list's handle
		IupSetHandle( "textProjectName", null );
		IupSetHandle( "textProjectDir", null );
		IupSetHandle( "btnProjectDir", null );
		
		
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
	}
	
	Ihandle* getHandle()
	{
		return _dlg;
	}
}

private:
extern(C) // Callback for CProjectPropertiesDialog
{
	int CProjectPropertiesDialog_btnOK_cb( Ihandle* ih )
	{
		// Apply First!!!
		if( CProjectPropertiesDialog_btnApply_cb( null ) == IUP_IGNORE )
		{
			Ihandle* messageDlg = IupMessageDlg();
			IupSetAttributes( messageDlg, "DIALOGTYPE=WARNING" );
			IupSetAttribute( messageDlg, "VALUE", GLOBAL.languageItems["nodirmessage"].toCString() );
			IupSetAttribute( messageDlg, "TITLE", GLOBAL.languageItems["alarm"].toCString() );
			IupPopup( messageDlg, IUP_CENTER, IUP_CENTER );
		
			return IUP_IGNORE;
		}
		
		
		Ihandle* dirHandle = IupGetDialogChild( IupGetHandle( "PRJPROPERTY_DIALOG" ), "PRJPROPERTY_ProjectDir" );
		if( dirHandle != null )
		{
			if( !CProjectPropertiesDialog.tempProject.name.length )
			{
				scope _fp = new FilePath( Path.normalize( CProjectPropertiesDialog.tempProject.dir ) );
				CProjectPropertiesDialog.tempProject.name = _fp.name;
				IupSetAttribute( IupGetDialogChild( IupGetHandle( "PRJPROPERTY_DIALOG" ), "PRJPROPERTY_ProjectName" ), "VALUE", toStringz( CProjectPropertiesDialog.tempProject.name.dup ) );
			}		
		
			if( fromStringz( IupGetAttribute( dirHandle, "ACTIVE" ) ) == "NO" ) // Created project
			{
				if( CProjectPropertiesDialog.tempProject.dir in GLOBAL.projectManager )
				{
					CProjectPropertiesDialog.tempProject.sources = GLOBAL.projectManager[CProjectPropertiesDialog.tempProject.dir].sources.dup;
					CProjectPropertiesDialog.tempProject.includes = GLOBAL.projectManager[CProjectPropertiesDialog.tempProject.dir].includes.dup;
					CProjectPropertiesDialog.tempProject.others = GLOBAL.projectManager[CProjectPropertiesDialog.tempProject.dir].others.dup;
				}
			}

			GLOBAL.projectManager[CProjectPropertiesDialog.tempProject.dir] = CProjectPropertiesDialog.tempProject;
			GLOBAL.projectManager[CProjectPropertiesDialog.tempProject.dir].saveFile();

			// Recent Projects
			GLOBAL.projectTree.updateRecentProjects( CProjectPropertiesDialog.tempProject.dir, CProjectPropertiesDialog.tempProject.name );
			if( fromStringz( IupGetAttribute( dirHandle, "ACTIVE" ) ) == "YES" ) GLOBAL.projectTree.CreateNewProject( CProjectPropertiesDialog.tempProject.name, CProjectPropertiesDialog.tempProject.dir );
			GLOBAL.statusBar.setPrjName( null, true );
			//GLOBAL.statusBar.setPrjName( GLOBAL.languageItems["caption_prj"].toDString ~ ": " ~ GLOBAL.projectManager[CProjectPropertiesDialog.tempProject.dir].name );
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
				char[]	_prjDir				= Util.trim( fromStringz( IupGetAttribute( dirHandle, "VALUE" ) ).dup );

				if( _prjDir.length )
				{
					CProjectPropertiesDialog.tempProject.name = Util.trim( fromStringz( IupGetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_ProjectName" ), "VALUE" ) ) ).dup;
					CProjectPropertiesDialog.tempProject.dir = Path.normalize( _prjDir ).dup;
					CProjectPropertiesDialog.tempProject.type = Util.trim( fromStringz( IupGetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_TypeList" ), "VALUE" ) ) ).dup;
					CProjectPropertiesDialog.tempProject.mainFile = Util.trim( fromStringz( IupGetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_ProjectMainFile" ), "VALUE" ) ) ).dup;
					CProjectPropertiesDialog.tempProject.args = Util.trim( fromStringz( IupGetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_Args" ), "VALUE" ) ) ).dup;
					CProjectPropertiesDialog.tempProject.comment = Util.trim( fromStringz( IupGetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_Comment" ), "VALUE" ) ) ).dup;
					CProjectPropertiesDialog.tempProject.focusOn = Util.trim( fromStringz( IupGetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_FocusList" ), "VALUE" ) ) ).dup;
					version(FBIDE)
						CProjectPropertiesDialog.tempProject.passOneFile = Util.trim( fromStringz( IupGetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_ToggleOneFile" ), "VALUE" ) ) ).dup;
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
				char[] focusTitle = Util.trim( fromStringz( IupGetAttribute( focusList, "VALUE" ) ) ).dup;
				if( focusTitle.length )
				{
					FocusUnit _focusUnit;
					_focusUnit.Target = Util.trim( fromStringz( IupGetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_TargetName" ), "VALUE" ) ) ).dup;
					_focusUnit.Option = Util.trim( fromStringz( IupGetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_Options" ), "VALUE" ) ) ).dup;
					_focusUnit.Compiler = Util.trim( fromStringz( IupGetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_CompilerPath" ), "VALUE" ) ) ).dup;
					
					//PRJPROPERTY_IncludePaths, PRJPROPERTY_LibPaths
					int		includeCount = IupGetInt( IupGetDialogChild( _dlg, "PRJPROPERTY_IncludePaths" ), "COUNT" );
					for( int i = 1; i <= includeCount; i++ )
						_focusUnit.IncDir ~= fromStringz( IupGetAttributeId( IupGetDialogChild( _dlg, "PRJPROPERTY_IncludePaths" ), "", i ) ).dup;
					
					int		libCount = IupGetInt( IupGetDialogChild( _dlg, "PRJPROPERTY_LibPaths" ), "COUNT" );
					for( int i = 1; i <= libCount; i++ )
						_focusUnit.LibDir ~= fromStringz( IupGetAttributeId( IupGetDialogChild( _dlg, "PRJPROPERTY_LibPaths" ), "", i ) ).dup;
						
					CProjectPropertiesDialog.tempProject.focusUnit[focusTitle] = _focusUnit;
					actionManager.SearchAction.addListItem( focusList, focusTitle, 100 );
					IupSetAttributeId( focusList, "INSERTITEM", 1, "" );
					IupSetAttribute( focusList, "VALUE", toStringz( focusTitle ) );
				}
				else
				{
					CProjectPropertiesDialog.tempProject.targetName	= Util.trim( fromStringz( IupGetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_TargetName" ), "VALUE" ) ) ).dup;
					CProjectPropertiesDialog.tempProject.compilerOption	= Util.trim( fromStringz( IupGetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_Options" ), "VALUE" ) ) ).dup;
					CProjectPropertiesDialog.tempProject.compilerPath = Util.trim( fromStringz( IupGetAttribute( IupGetDialogChild( _dlg, "PRJPROPERTY_CompilerPath" ), "VALUE" ) ) ).dup;
					
					CProjectPropertiesDialog.tempProject.includeDirs.length = 0;
					int		includeCount = IupGetInt( IupGetDialogChild( _dlg, "PRJPROPERTY_IncludePaths" ), "COUNT" );
					for( int i = 1; i <= includeCount; i++ )
						CProjectPropertiesDialog.tempProject.includeDirs ~= fromStringz( IupGetAttributeId( IupGetDialogChild( _dlg, "PRJPROPERTY_IncludePaths" ), "", i ) ).dup;
					
					CProjectPropertiesDialog.tempProject.libDirs.length = 0;
					int		libCount = IupGetInt( IupGetDialogChild( _dlg, "PRJPROPERTY_LibPaths" ), "COUNT" );
					for( int i = 1; i <= libCount; i++ )
						CProjectPropertiesDialog.tempProject.libDirs ~= fromStringz( IupGetAttributeId( IupGetDialogChild( _dlg, "PRJPROPERTY_LibPaths" ), "", i ) ).dup;
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
		char[] fileName = fileSelectDlg.getFileName();

		if( fileName.length )
		{
			Ihandle* textPrjPath = IupGetHandle( "textProjectDir" );
			if( textPrjPath != null )
			{
				IupSetAttribute( textPrjPath, "VALUE", toStringz( fileName ) );
				
				Ihandle* textProjectName = IupGetHandle( "textProjectName" );
				if( textProjectName != null )
				{
					char[] projectName = Util.trim( fromStringz( IupGetAttribute( textProjectName, "VALUE" ) ) ).dup;
					if( !projectName.length )
					{
						scope _fp = new FilePath( Path.normalize( fileName ) );
						IupSetAttribute( textProjectName, "VALUE", toStringz( _fp.name.dup ) );
					}
				}
			}
		}
		else
		{
			//Stdout( "NoThing!!!" ).newline;
		}

		return IUP_DEFAULT;
	}

	int CProjectPropertiesDialog_btnCompilerPath_cb( Ihandle* ih ) 
	{
		scope fileSecectDlg = new CFileDlg( GLOBAL.languageItems["compilerpath"].toDString() ~ "...", GLOBAL.languageItems["exefile"].toDString() ~ "|*.exe" );
		char[] fileName = fileSecectDlg.getFileName();

		if( fileName.length )
		{
			Ihandle* _dlg = IupGetHandle( "PRJPROPERTY_DIALOG" );
			if( _dlg != null )
			{
				Ihandle* _compilerPath = IupGetDialogChild( _dlg, "PRJPROPERTY_CompilerPath" );
				if( _compilerPath != null ) IupSetAttribute( _compilerPath, "VALUE", toStringz( fileName ) );
			}
		}
		else
		{
			//Stdout( "NoThing!!!" ).newline;
		}

		return IUP_DEFAULT;
	}

	int CProjectPropertiesDialog_Add_cb( Ihandle* ih ) 
	{
		scope fileSecectDlg = new CFileDlg( null, null, "DIR" );
		char[] fileName = fileSecectDlg.getFileName();

		if( fileName.length )
		{
			Ihandle* list;
			if( ih == IupGetHandle( "btnIncludePathAdd_Handle" ) ) list = IupGetHandle( "listIncludePath_Handle" ); else list = IupGetHandle( "listLibPath_Handle" );

			IupSetAttribute( list, "APPENDITEM", toStringz(fileName) );
		}
		else
		{
			//Stdout( "NoThing!!!" ).newline;
		}

		return IUP_DEFAULT;
	}

	int CProjectPropertiesDialog_Erase_cb( Ihandle* ih ) 
	{
		Ihandle* list;
		if( ih == IupGetHandle( "btnIncludePathErase_Handle" ) ) list = IupGetHandle( "listIncludePath_Handle" ); else list = IupGetHandle( "listLibPath_Handle" );

		// IupGetAttribute( list, "VALUE" ) = 0 Items has no selected, = 1,2,3.....n   #n item had be selected
		char* itemNumber = IupGetAttribute( list, "VALUE" );
		if( Integer.atoi( fromStringz( itemNumber ) ) > 0 )
		{
			IupSetAttribute( list, "REMOVEITEM", itemNumber );
		}
		
		return IUP_DEFAULT;
	}

	int CProjectPropertiesDialog_Edit_cb( Ihandle* ih ) 
	{
		Ihandle* list;
		if( ih == IupGetHandle( "btnIncludePathEdit_Handle" ) ) list = IupGetHandle( "listIncludePath_Handle" ); else list = IupGetHandle( "listLibPath_Handle" );

		// IupGetAttribute( list, "VALUE" ) = 0 Items has no selected, = 1,2,3.....n   #n item had be selected
		char* itemNumber = IupGetAttribute( list, "VALUE" );
		if( Integer.atoi( fromStringz( itemNumber ) ) > 0 )
		{
			scope fileSecectDlg = new CFileDlg( null, null, "DIR" );
			char[] fileName = fileSecectDlg.getFileName();

			if( fileName.length )
			{
				IupSetAttribute( list, itemNumber, toStringz( fileName ) );
			}
		}
		
		return IUP_DEFAULT;
	}

	int CProjectPropertiesDialog_Up_cb( Ihandle* ih ) 
	{
		Ihandle* list;
		if( ih == IupGetHandle( "btnIncludePathUp_Handle" ) ) list = IupGetHandle( "listIncludePath_Handle" ); else list = IupGetHandle( "listLibPath_Handle" );

		int itemNumber = Integer.atoi( fromStringz( IupGetAttribute( list, "VALUE" ) ) );

		if( itemNumber > 1 )
		{
			char* prevItemText = IupGetAttribute( list, toStringz( Integer.toString(itemNumber-1) ) );
			char* nowItemText = IupGetAttribute( list, toStringz( Integer.toString(itemNumber) ) );

			IupSetAttribute( list, toStringz( Integer.toString(itemNumber-1) ), nowItemText );
			IupSetAttribute( list, toStringz( Integer.toString(itemNumber) ), prevItemText );

			IupSetAttribute( list, "VALUE", toStringz( Integer.toString(itemNumber-1) ) );
		}

		return IUP_DEFAULT;
	}

	int CProjectPropertiesDialog_Down_cb( Ihandle* ih ) 
	{
		Ihandle* list;
		if( ih == IupGetHandle( "btnIncludePathDown_Handle" ) ) list = IupGetHandle( "listIncludePath_Handle" ); else list = IupGetHandle( "listLibPath_Handle" );

		int itemNumber = Integer.atoi( fromStringz( IupGetAttribute( list, "VALUE" ) ) );
		int itemCount = Integer.atoi( fromStringz( IupGetAttribute( list, "COUNT" ) ) );

		if( itemNumber < itemCount )
		{
			char* nextItemText = IupGetAttribute( list, toStringz( Integer.toString(itemNumber+1) ) );
			char* nowItemText = IupGetAttribute( list, toStringz( Integer.toString(itemNumber) ) );

			IupSetAttribute( list, toStringz( Integer.toString(itemNumber+1) ), nowItemText );
			IupSetAttribute( list, toStringz( Integer.toString(itemNumber) ), nextItemText );

			IupSetAttribute( list, "VALUE", toStringz( Integer.toString(itemNumber+1) ) );
		}

		return IUP_DEFAULT;
	}
}