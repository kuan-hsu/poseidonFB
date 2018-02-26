module dialogs.prjPropertyDlg;

private import iup.iup, iup.iup_scintilla;

private import global, project, scintilla, actionManager;
private import dialogs.baseDlg, dialogs.fileDlg;

private import tango.stdc.stringz, tango.io.FilePath, Util = tango.text.Util, Path = tango.io.Path;

class CProjectPropertiesDialog : CBaseDialog
{
	private:
	
	Ihandle*	textProjectName, listType, textProjectDir, textMainFile, textTargetName, textArgs, textCompilerOpts, textComment, textCompilerPath;
	Ihandle*	btnProjectDir;
	Ihandle*	listIncludePath, listLibPath;
	
	bool		bCreateNew = true;

	void createLayout()
	{
		Ihandle* bottom = createDlgButton( "40x12" );

		// PAGE 1 General
		// Line 1
		Ihandle* labelProjectName = IupLabel( toStringz( GLOBAL.languageItems["prjname"].toDString ~ ":" ) );
		IupSetAttributes( labelProjectName, "SIZE=60x20" );
		
		textProjectName = IupText( null );
		IupSetAttribute( textProjectName, "SIZE", "140x12" );
		IupSetHandle( "textProjectName", textProjectName );
		
		Ihandle* labelType = IupLabel( toStringz( GLOBAL.languageItems["prjtype"].toDString ~ ":" ) );
		IupSetAttributes( labelType, "SIZE=40x20" );
		
		listType = IupList( null );
		IupSetAttributes( listType, "SHOWIMAGE=NO,VALUE=1,DROPDOWN=YES,VISIBLE_ITEMS=3" );
		IupSetAttribute( listType, "1", GLOBAL.languageItems["console"].toCString() );
		IupSetAttribute( listType, "2", GLOBAL.languageItems["static"].toCString() );
		IupSetAttribute( listType, "3", GLOBAL.languageItems["dynamic"].toCString() );
		IupSetHandle( "listType", listType );

		Ihandle* hBox00 = IupHbox( labelProjectName, textProjectName, labelType, listType, null );
		IupSetAttribute( hBox00, "ALIGNMENT", "ACENTER" );
		

		// Line 2
		Ihandle* labelProjectDir = IupLabel( toStringz( GLOBAL.languageItems["prjdir"].toDString ~ ":" ) );
		IupSetAttributes( labelProjectDir, "SIZE=60x20" );
		
		textProjectDir = IupText( null );
		IupSetAttribute( textProjectDir, "SIZE", "276x12" );
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
		IupSetAttribute( textMainFile, "SIZE", "276x12" );
		IupSetHandle( "textMainFile", textMainFile );
		
		Ihandle* hBox02 = IupHbox( labelMainFile, textMainFile, null );
		IupSetAttribute( hBox02, "ALIGNMENT", "ACENTER" );

		// Line 4
		Ihandle* labelTargetName = IupLabel( toStringz( GLOBAL.languageItems["prjtarget"].toDString ~ ":" ) );
		IupSetAttributes( labelTargetName, "SIZE=60x20" );
		
		textTargetName = IupText( null );
		IupSetAttribute( textTargetName, "SIZE", "276x12" );
		IupSetHandle( "textTargetName", textTargetName );
		
		Ihandle* hBox03 = IupHbox( labelTargetName, textTargetName, null );
		IupSetAttribute( hBox03, "ALIGNMENT", "ACENTER" );

		// Line 5
		Ihandle* labelArgs = IupLabel( GLOBAL.languageItems["prjargs"].toCString );
		IupSetAttributes( labelArgs, "SIZE=60x20" );
		
		textArgs = IupText( null );
		IupSetAttribute( textArgs, "SIZE", "276x12" );
		IupSetHandle( "textArgs", textArgs );
		
		Ihandle* hBox04 = IupHbox( labelArgs, textArgs, null );
		IupSetAttribute( hBox04, "ALIGNMENT", "ACENTER" );

		// Line 6
		Ihandle* labelCompilerOpts = IupLabel( GLOBAL.languageItems["prjopts"].toCString );
		IupSetAttributes( labelCompilerOpts, "SIZE=60x20" );
		
		textCompilerOpts = IupText( null );
		IupSetAttribute( textCompilerOpts, "SIZE", "276x12" );
		IupSetHandle( "textCompilerOpts", textCompilerOpts );

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
		IupSetAttributes( textComment, "SIZE=276x20,MULTILINE=YES,SCROLLBAR=VERTICAL" );
		IupSetHandle( "textComment", textComment );
		
		Ihandle* hBox06 = IupHbox( labelComment, textComment, null );
		IupSetAttribute( hBox06, "ALIGNMENT", "ACENTER" );

		// Line 8
		Ihandle* labelCompilerPath = IupLabel( toStringz( GLOBAL.languageItems["prjcompiler"].toDString ~ ":" ) );
		IupSetAttributes( labelCompilerPath, "SIZE=60x20" );
		
		textCompilerPath = IupText( null );
		IupSetAttribute( textCompilerPath, "SIZE", "276x12" );
		IupSetHandle( "textCompilerPath", textCompilerPath );

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
		IupSetAttributes( listIncludePath, "MULTIPLE=NO, SIZE=326x64" );
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
		
		Ihandle* frameIncludePath = IupFrame( hBoxIncludePath );
		IupSetAttributes( frameIncludePath, "ALIGNMENT=ACENTER,MARGIN=2x2" );
		IupSetAttribute( frameIncludePath, "TITLE", GLOBAL.languageItems["includepath"].toCString() );



		// Library Paths
		listLibPath = IupList( null );
		IupSetAttributes( listLibPath, "MULTIPLE=NO, SIZE=328x64" );
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
	}

	public:
	this( int w, int h, char[] title, bool bResize = true, bool bNew = true, char[] parent = null )
	{
		super( w, h, title, bResize, parent );
		bCreateNew = bNew;
		IupSetAttribute( _dlg, "MINBOX", "NO" );
		IupSetAttribute( _dlg, "ICON", "icon_properties" );
		version( Windows )
		{
			IupSetAttribute( _dlg, "FONT", GLOBAL.cString.convert( "Courier New,9" ) );
		}
		else
		{
			IupSetAttribute( _dlg, "FONT", GLOBAL.cString.convert( "Ubuntu Mono, 10" ) );
		}
		 
		createLayout();
		
		if( !bCreateNew )
		{
			IupSetAttribute( textProjectDir, "ACTIVE", "NO" );
			IupSetAttribute( btnProjectDir, "ACTIVE", "NO" );
			IupSetAttribute( textProjectDir, "BGCOLOR",  IupGetGlobal("DLGBGCOLOR") );

			//PROJECT activeP = GLOBAL.projectManager[GLOBAL.activeProjectDirName];
			PROJECT activeP = GLOBAL.projectManager[actionManager.ProjectAction.getActiveProjectName];

			IupSetAttribute( textProjectName, "VALUE", toStringz( activeP.name ) );
			IupSetAttribute( listType, "VALUE", toStringz( activeP.type ) );
			IupSetAttribute( textProjectDir, "VALUE", toStringz( activeP.dir ) );
			IupSetAttribute( textMainFile, "VALUE", toStringz( activeP.mainFile ) );
			IupSetAttribute( textTargetName, "VALUE", toStringz( activeP.targetName ) );
			IupSetAttribute( textArgs, "VALUE", toStringz( activeP.args ) );
			IupSetAttribute( textCompilerOpts, "VALUE", toStringz( activeP.compilerOption ) );
			IupSetAttribute( textComment, "VALUE", toStringz( activeP.comment ) );
			IupSetAttribute( textCompilerPath, "VALUE", toStringz( activeP.compilerPath ) );


			//IupSetAttribute( list, "APPENDITEM", toStringz(fileName) );
			//Ihandle*	listIncludePath, listLibPath;
			for( int i = 0; i < activeP.includeDirs.length; i++ )
				IupSetAttribute( listIncludePath, toStringz( Integer.toString( i+1 ) ), toStringz(activeP.includeDirs[i]) );

			for( int i = 0; i < activeP.libDirs.length; i++ )
				IupSetAttribute( listLibPath, toStringz( Integer.toString( i+1 ) ), toStringz(activeP.libDirs[i]) );
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
		IupSetHandle( "listType", null );
		IupSetHandle( "textProjectDir", null );
		IupSetHandle( "btnProjectDir", null );
		IupSetHandle( "textMainFile", null );
		IupSetHandle( "textTargetName", null );
		IupSetHandle( "textArgs", null );
		IupSetHandle( "textCompilerOpts", null );
		IupSetHandle( "textComment", null );
		IupSetHandle( "textCompilerPath", null );
		
		
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
}

private:
extern(C) // Callback for CProjectPropertiesDialog
{
	int CProjectPropertiesDialog_btnOK_cb( Ihandle* ih )
	{
		Ihandle* dirHandle = IupGetHandle( "textProjectDir" );
		if( dirHandle != null )
		{

			char[]	_prjDir				= Util.trim( fromStringz( IupGetAttribute( dirHandle, "VALUE" ) ).dup );

			if( _prjDir.length )
			{
				char[]	_prjName			= Util.trim( fromStringz( IupGetAttribute( IupGetHandle( "textProjectName" ), "VALUE" ) ) ).dup;
				char[]	_prjType			= Util.trim( fromStringz( IupGetAttribute( IupGetHandle( "listType" ), "VALUE" ) ) ).dup;
				char[]	_prjMainFile		= Util.trim( fromStringz( IupGetAttribute( IupGetHandle( "textMainFile" ), "VALUE" ) ) ).dup;
				char[]	_prjTargetName		= Util.trim( fromStringz( IupGetAttribute( IupGetHandle( "textTargetName" ), "VALUE" ) ) ).dup;
				char[]	_prjArgs			= Util.trim( fromStringz( IupGetAttribute( IupGetHandle( "textArgs" ), "VALUE" ) ) ).dup;
				char[]	_prjCompilerOptions	= Util.trim( fromStringz( IupGetAttribute( IupGetHandle( "textCompilerOpts" ), "VALUE" ) ) ).dup;
				char[]	_prjComment			= Util.trim( fromStringz( IupGetAttribute( IupGetHandle( "textComment" ), "VALUE" ) ) ).dup;
				char[]	_prjCompilerPath	= Util.trim( fromStringz( IupGetAttribute( IupGetHandle( "textCompilerPath" ), "VALUE" ) ) ).dup;
				
				if( !_prjName.length )
				{
					scope _fp = new FilePath( Path.normalize( _prjDir ) );
					_prjName = _fp.name;
				}

				PROJECT s;
				s.name				= _prjName;
				s.type				= _prjType;
				s.dir				= Path.normalize( _prjDir );
				s.mainFile			= _prjMainFile;
				s.targetName		= _prjTargetName;
				s.args				= _prjArgs;
				s.compilerOption	= _prjCompilerOptions;
				s.comment			= _prjComment;
				s.compilerPath		= _prjCompilerPath;

				if( fromStringz( IupGetAttribute( dirHandle, "ACTIVE" ) ) == "NO" ) // Created project
				{
					if( _prjDir in GLOBAL.projectManager )
					{
						s.sources = GLOBAL.projectManager[_prjDir].sources.dup;
						s.includes = GLOBAL.projectManager[_prjDir].includes.dup;
						s.others = GLOBAL.projectManager[_prjDir].others.dup;
					}
				}

				int		includeCount = IupGetInt( IupGetHandle( "listIncludePath_Handle" ), "COUNT" );
				for( int i = 1; i <= includeCount; i++ )
					s.includeDirs ~= fromStringz( IupGetAttribute( IupGetHandle( "listIncludePath_Handle" ), toStringz( Integer.toString( i ) ) ) ).dup;
				
				int		libCount = IupGetInt( IupGetHandle( "listLibPath_Handle" ), "COUNT" );
				for( int i = 1; i <= libCount; i++ )
					s.libDirs ~= fromStringz( IupGetAttribute( IupGetHandle( "listLibPath_Handle" ), toStringz( Integer.toString( i ) ) ) ).dup;

				GLOBAL.projectManager[_prjDir] = s;
				GLOBAL.projectManager[_prjDir].saveFile();

				// Recent Projects
				GLOBAL.projectTree.updateRecentProjects( _prjDir, _prjName );

				if( fromStringz( IupGetAttribute( dirHandle, "ACTIVE" ) ) == "YES" ) GLOBAL.projectTree.CreateNewProject( _prjName, _prjDir );

				GLOBAL.statusBar.setPrjName( GLOBAL.languageItems["caption_prj"].toDString ~ ": " ~ _prjName );
			}
		}

		return IUP_CLOSE;
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
		scope fileSecectDlg = new CFileDlg( GLOBAL.languageItems["compilerpath"].toDString() ~ "...", GLOBAL.languageItems["exefile"].toDString() ~ "|*.exe|" );
		char[] fileName = fileSecectDlg.getFileName();

		if( fileName.length )
		{
			Ihandle* _compilerPath = IupGetHandle( "textCompilerPath" );
			if( _compilerPath != null ) IupSetAttribute( _compilerPath, "VALUE", toStringz( fileName ) );
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