module layouts.projectPanel;


private import iup.iup;

private import global, scintilla, actionManager, menu, tools;
private import dialogs.singleTextDlg, dialogs.fileDlg;

private import tango.stdc.stringz, tango.sys.Process;
private import tango.io.FilePath, Util = tango.text.Util, Integer = tango.text.convert.Integer, Path = tango.io.Path;

class CProjectTree
{
private:
	import				dialogs.prjPropertyDlg;

	import				project, tango.io.device.File, tango.io.stream.Lines;
	import				tango.core.Thread, parser.autocompletion;
	
	Ihandle*			layoutHandle, tree, projectButtonCollapse;

	void createLayout()
	{
		// Outline Toolbar
		projectButtonCollapse = IupButton( null, null );
		IupSetAttributes( projectButtonCollapse, "ALIGNMENT=ARIGHT:ACENTER,FLAT=YES,IMAGE=icon_collapse,VISIBLE=NO" );
		IupSetAttribute( projectButtonCollapse, "TIP", GLOBAL.languageItems["collapse"].toCString );
		IupSetCallback( projectButtonCollapse, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			Ihandle* _tree = GLOBAL.projectTree.getTreeHandle();
			if( _tree != null )
			{
				int id = IupGetInt( _tree, "VALUE" );
				
				if( id <= 0 )
				{
					if( fromStringz( IupGetAttributeId( _tree, "STATE", 0 ) ) == "EXPANDED" )
						IupSetAttribute( _tree, "EXPANDALL", "NO" );
					else
					{
						IupSetAttribute( _tree, "EXPANDALL", "YES" );
						IupSetAttribute( _tree, "TOPITEM", "YES" ); // Set position to top
					}
				}
				else
				{
					int 	nowDepth = IupGetIntId( _tree, "DEPTH", id );
					char*	nowState = IupGetAttributeId( _tree, "STATE", id );
					
					if( nowState != null )
					{
						for( int i = IupGetInt( _tree, "COUNT" ) - 1; i > 0; --i )
						{
							if( IupGetIntId( _tree, "DEPTH", i ) == nowDepth )
							{
								if( IupGetIntId( _tree, "CHILDCOUNT", i ) > 0 )
								{
									if( fromStringz( IupGetAttributeId( _tree, "KIND", i ) ) == "BRANCH" )
									{
										if( fromStringz( nowState ) == "EXPANDED" )
											IupSetAttributeId( _tree, "STATE", i, "COLLAPSED" );
										else
											IupSetAttributeId( _tree, "STATE", i, "EXPANDED" );
									}
								}
							}
						}
					}
				}
			}
			return IUP_DEFAULT;
		});

		Ihandle* projectButtonHide = IupButton( null, null );
		IupSetAttributes( projectButtonHide, "ALIGNMENT=ARIGHT:ACENTER,FLAT=YES,IMAGE=icon_shift_l" );
		IupSetAttribute( projectButtonHide, "TIP", GLOBAL.languageItems["hide"].toCString );
		IupSetCallback( projectButtonHide, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			menu.outlineMenuItem_cb( GLOBAL.menuOutlineWindow );
			return IUP_DEFAULT;
		});

		Ihandle* projectToolbarTitleImage = IupLabel( null );
		IupSetAttributes( projectToolbarTitleImage, "IMAGE=icon_packageexplorer,ALIGNMENT=ACENTER:ALEFT" );

		/*Ihandle* projectToolbarTitle = IupLabel( " Project" );
		IupSetAttribute( projectToolbarTitle, "ALIGNMENT", "ACENTER:ALEFT" );*/

		Ihandle* projectToolbarH = IupHbox( projectToolbarTitleImage, /*projectToolbarTitle,*/ IupFill, projectButtonCollapse, projectButtonHide, null );
		IupSetAttributes( projectToolbarH, "ALIGNMENT=ACENTER,SIZE=NULL" );

		tree = IupTree();
		IupSetAttributes( tree, "ADDROOT=YES,EXPAND=YES,TITLE=Projects,SIZE=NULL,BORDER=NO,MARKMODE=MULTIPLE,NAME=POSEIDON_PROJECT_Tree" );
		IupSetAttribute( tree, "FGCOLOR", GLOBAL.editColor.projectFore.toCString );
		IupSetAttribute( tree, "BGCOLOR", GLOBAL.editColor.projectBack.toCString );
		version(Windows) if( GLOBAL.editColor.project_HLT.toDString.length ) IupSetAttribute( tree, "HLCOLOR", GLOBAL.editColor.project_HLT.toCString );
		
		
		IupSetCallback( tree, "RIGHTCLICK_CB", cast(Icallback) &CProjectTree_RightClick_cb );
		IupSetCallback( tree, "SELECTION_CB", cast(Icallback) &CProjectTree_Selection_cb );
		IupSetCallback( tree, "NODEREMOVED_CB", cast(Icallback) &CProjectTree_NodeRemoved_cb );
		IupSetCallback( tree, "MULTISELECTION_CB", cast(Icallback) &CProjectTree_MULTISELECTION_CB );
		IupSetCallback( tree, "MULTIUNSELECTION_CB", cast(Icallback) &CProjectTree_MULTIUNSELECTION_CB );
		IupSetCallback( tree, "BUTTON_CB", cast(Icallback) &CProjectTree_BUTTON_CB );
		IupSetCallback( tree, "EXECUTELEAF_CB", cast(Icallback) &CProjectTree_EXECUTELEAF_CB );
		//IupSetCallback( tree, "BRANCHOPEN_CB", cast(Icallback) &CProjectTree_BRANCH_CB );
		//IupSetCallback( tree, "BRANCHCLOSE_CB", cast(Icallback) &CProjectTree_BRANCH_CB );
		
		layoutHandle = IupVbox( projectToolbarH, tree, null );
		IupSetAttributes( layoutHandle, GLOBAL.cString.convert( "ALIGNMENT=ARIGHT,GAP=2" ) );
	}

	void toBoldTitle( Ihandle* _tree, int id )
	{
		int commaPos = Util.index( GLOBAL.fonts[4].fontString, "," );
		if( commaPos < GLOBAL.fonts[4].fontString.length )
		{
			char[] fontString = Util.substitute( GLOBAL.fonts[4].fontString.dup, ",", ",Bold " );
			IupSetAttributeId( _tree, "TITLEFONT", id, toStringz( fontString.dup ) );
		}
	}


public:
	this()
	{
		createLayout();
	}

	~this()
	{
	}
	
	Ihandle* getLayoutHandle()
	{
		return layoutHandle;
	}	

	Ihandle* getTreeHandle()
	{
		return tree;
	}
	
	void changeColor()
	{
		IupSetAttributeId( tree, "COLOR", 0, GLOBAL.editColor.projectFore.toCString );
		IupSetAttribute( tree, "FGCOLOR", GLOBAL.editColor.projectFore.toCString );
		IupSetAttribute( tree, "BGCOLOR", GLOBAL.editColor.projectBack.toCString );
		
		/*
		scope icon_prj = CstringConvert( "icon_prj" );
		scope icon_prj_open = CstringConvert( "icon_prj_open" );
		scope icon_door = CstringConvert( "icon_door" );
		scope icon_prj_open = CstringConvert( "icon_prj_open" );
		*/
		for( int i = 1; i < IupGetInt( tree, "COUNT" ); ++ i )
		{
			if( IupGetIntId( tree, "DEPTH", i ) == 1 )
			{
				IupSetAttributeId( tree, "COLOR", i, GLOBAL.editColor.prjTitle.toCString );
				IupSetAttributeId( tree, "IMAGE", i, GLOBAL.cString.convert( "icon_prj" ) );
				IupSetAttributeId( tree, "IMAGEEXPANDED", i, GLOBAL.cString.convert( "icon_prj_open" ) );				
			}
			else if( IupGetIntId( tree, "DEPTH", i ) == 2 )
			{
				IupSetAttributeId( tree, "COLOR", i, GLOBAL.editColor.prjSourceType.toCString );
				IupSetAttributeId( tree, "IMAGE", i, GLOBAL.cString.convert( "icon_door" ) );
				IupSetAttributeId( tree, "IMAGEEXPANDED", i, GLOBAL.cString.convert( "icon_dooropen" ) );					
			}
			else
			{
				IupSetAttributeId( tree, "COLOR", i, GLOBAL.editColor.projectFore.toCString );
				scope _fp = new FilePath( fromStringz( IupGetAttributeId( tree, "TITLE", i ) ) );

				version(FBIDE)
				{
					switch( tools.lowerCase( _fp.ext() ) )
					{
						case "bas":
							IupSetAttributeId( tree, "IMAGE", i, GLOBAL.cString.convert( "icon_bas" ) );	break;
						case "bi":
							IupSetAttributeId( tree, "IMAGE", i, GLOBAL.cString.convert( "icon_bi" ) );		break;
						default:
							IupSetAttributeId( tree, "IMAGE", i, GLOBAL.cString.convert( "icon_txt" ) );
					}
				}
				
				version(DIDE)
				{
					switch( tools.lowerCase( _fp.ext() ) )
					{
						case "d":
							IupSetAttributeId( tree, "IMAGE", i, GLOBAL.cString.convert( "icon_bas" ) );	break;
						case "di":
							IupSetAttributeId( tree, "IMAGE", i, GLOBAL.cString.convert( "icon_bi" ) );		break;
						default:
							IupSetAttributeId( tree, "IMAGE", i, GLOBAL.cString.convert( "icon_txt" ) );
					}
				}
			}
		}
	}

	/*
	Ihandle* getShadowTreeHandle()
	{
		return shadowTree;
	}
	*/

	void createProjectTree( char[] setupDir )
	{
		char[] prjDirName = GLOBAL.projectManager[setupDir].dir ~ "/";

		// Add Project's Name to Tree
		IupSetAttribute( tree, "ADDBRANCH0", GLOBAL.cString.convert( GLOBAL.projectManager[setupDir].name ) );
		IupSetAttribute( tree, "IMAGE1", GLOBAL.cString.convert( "icon_prj" ) );
		IupSetAttribute( tree, "IMAGEEXPANDED1", GLOBAL.cString.convert( "icon_prj_open" ) );
		version(Windows) IupSetAttributeId( tree, "MARKED", 1, "YES" ); else IupSetInt( tree, "VALUE", 1 );
		IupSetAttributeId( tree, "USERDATA", 1, tools.getCString( setupDir ) );
		IupSetAttributeId( tree, "COLOR", 1, GLOBAL.editColor.prjTitle.toCString );
		toBoldTitle( tree, 1 );
		
		// Miscellaneous
		IupSetAttribute( tree, "ADDBRANCH1", "Miscellaneous" );
		IupSetAttributeId( tree, "COLOR", 2, GLOBAL.editColor.prjSourceType.toCString );
		IupSetAttribute( tree, "IMAGE2", GLOBAL.cString.convert( "icon_door" ) );
		IupSetAttribute( tree, "IMAGEEXPANDED2", GLOBAL.cString.convert( "icon_dooropen" ) );
		toBoldTitle( tree, 2 );
		
		// Create Sub Dir
		foreach_reverse( char[] s; GLOBAL.projectManager[setupDir].misc )
			_createTree( prjDirName, s );
			
		foreach_reverse( char[] s; GLOBAL.projectManager[setupDir].misc )
		{
			char[]		userData = s;
			int			folderLocateId = _createTree( prjDirName, s );
			
			if( IupGetIntId( tree, "CHILDCOUNT", folderLocateId ) > 0 )
			{
				folderLocateId = IupGetIntId( tree, "LAST", folderLocateId + 1 );
				IupSetAttributeId( tree, "INSERTLEAF", folderLocateId, GLOBAL.cString.convert( s ) );
				int insertID = IupGetInt( tree, "LASTADDNODE" );
				IupSetAttributeId( tree, "COLOR", insertID, GLOBAL.editColor.projectFore.toCString );
				IupSetAttributeId( tree, "IMAGE", insertID, GLOBAL.cString.convert( "icon_txt" ) );
				IupSetAttributeId( tree, "USERDATA", insertID, tools.getCString( userData ) );
			}
			else
			{
				IupSetAttributeId( tree, "ADDLEAF", folderLocateId, GLOBAL.cString.convert( s ) );
				IupSetAttributeId( tree, "COLOR", folderLocateId + 1, GLOBAL.editColor.projectFore.toCString );
				IupSetAttributeId( tree, "IMAGE", folderLocateId + 1, GLOBAL.cString.convert( "icon_txt" ) );
				IupSetAttributeId( tree, "USERDATA", folderLocateId + 1, tools.getCString( userData ) );
			}
		}		
		

	
		IupSetAttribute( tree, "ADDBRANCH1", "Others" );
		IupSetAttributeId( tree, "COLOR", 2, GLOBAL.editColor.prjSourceType.toCString );
		IupSetAttribute( tree, "IMAGE2", GLOBAL.cString.convert( "icon_door" ) );
		IupSetAttribute( tree, "IMAGEEXPANDED2", GLOBAL.cString.convert( "icon_dooropen" ) );
		toBoldTitle( tree, 2 );

		// Create Sub Dir
		foreach_reverse( char[] s; GLOBAL.projectManager[setupDir].others )
			_createTree( prjDirName, s );
			
		foreach_reverse( char[] s; GLOBAL.projectManager[setupDir].others )
		{
			char[]		userData = s;
			int			folderLocateId = _createTree( prjDirName, s );
			
			if( IupGetIntId( tree, "CHILDCOUNT", folderLocateId ) > 0 )
			{
				folderLocateId = IupGetIntId( tree, "LAST", folderLocateId + 1 );
				IupSetAttributeId( tree, "INSERTLEAF", folderLocateId, GLOBAL.cString.convert( s ) );
				int insertID = IupGetInt( tree, "LASTADDNODE" );
				IupSetAttributeId( tree, "COLOR", insertID, GLOBAL.editColor.projectFore.toCString );
				IupSetAttributeId( tree, "IMAGE", insertID, GLOBAL.cString.convert( "icon_txt" ) );
				IupSetAttributeId( tree, "USERDATA", insertID, tools.getCString( userData ) );
			}
			else
			{
				IupSetAttributeId( tree, "ADDLEAF", folderLocateId, GLOBAL.cString.convert( s ) );
				IupSetAttributeId( tree, "COLOR", folderLocateId + 1, GLOBAL.editColor.projectFore.toCString );
				IupSetAttributeId( tree, "IMAGE", folderLocateId + 1, GLOBAL.cString.convert( "icon_txt" ) );
				IupSetAttributeId( tree, "USERDATA", folderLocateId + 1, tools.getCString( userData ) );
			}
		}


		
		IupSetAttribute( tree, "ADDBRANCH1", "Includes" );
		IupSetAttributeId( tree, "COLOR", 2, GLOBAL.editColor.prjSourceType.toCString );
		IupSetAttribute( tree, "IMAGE2", GLOBAL.cString.convert( "icon_door" ) );
		IupSetAttribute( tree, "IMAGEEXPANDED2", GLOBAL.cString.convert( "icon_dooropen" ) );
		toBoldTitle( tree, 2 );
		
		// Create Sub Dir
		foreach_reverse( char[] s; GLOBAL.projectManager[setupDir].includes )
			_createTree( prjDirName, s );
			
		foreach( char[] s; GLOBAL.projectManager[setupDir].includes )
		{
			char[]		userData = s;
			int			folderLocateId = _createTree( prjDirName, s );
			
			if( IupGetIntId( tree, "CHILDCOUNT", folderLocateId ) > 0 )
			{
				folderLocateId = IupGetIntId( tree, "LAST", folderLocateId + 1 );
				IupSetAttributeId( tree, "INSERTLEAF", folderLocateId, GLOBAL.cString.convert( s ) );
				int insertID = IupGetInt( tree, "LASTADDNODE" );
				IupSetAttributeId( tree, "COLOR", insertID, GLOBAL.editColor.projectFore.toCString );
				IupSetAttributeId( tree, "IMAGE", insertID, GLOBAL.cString.convert( "icon_bi" ) );
				IupSetAttributeId( tree, "USERDATA", insertID, tools.getCString( userData ) );
			}
			else
			{
				IupSetAttributeId( tree, "ADDLEAF", folderLocateId, GLOBAL.cString.convert( s ) );
				IupSetAttributeId( tree, "COLOR", folderLocateId + 1, GLOBAL.editColor.projectFore.toCString );
				IupSetAttributeId( tree, "IMAGE", folderLocateId + 1, GLOBAL.cString.convert( "icon_bi" ) );
				IupSetAttributeId( tree, "USERDATA", folderLocateId + 1, tools.getCString( userData ) );
			}
		}



		IupSetAttribute( tree, "ADDBRANCH1", "Sources" );
		IupSetAttributeId( tree, "COLOR", 2, GLOBAL.editColor.prjSourceType.toCString );
		toBoldTitle( tree, 2 );
		IupSetAttribute( tree, "IMAGE2", GLOBAL.cString.convert( "icon_door" ) );
		IupSetAttribute( tree, "IMAGEEXPANDED2", GLOBAL.cString.convert( "icon_dooropen" ) );
		
		// Create Sub Dir
		foreach_reverse( char[] s; GLOBAL.projectManager[setupDir].sources )
			_createTree( prjDirName, s );
		
		
		foreach( char[] s; GLOBAL.projectManager[setupDir].sources )
		{
			char[]		userData = s;
			int			folderLocateId = _createTree( prjDirName, s );
			
			if( IupGetIntId( tree, "CHILDCOUNT", folderLocateId ) > 0 )
			{
				folderLocateId = IupGetIntId( tree, "LAST", folderLocateId + 1 );
				IupSetAttributeId( tree, "INSERTLEAF", folderLocateId, GLOBAL.cString.convert( s ) );
				int insertID = IupGetInt( tree, "LASTADDNODE" );
				IupSetAttributeId( tree, "COLOR", insertID, GLOBAL.editColor.projectFore.toCString );
				IupSetAttributeId( tree, "IMAGE", insertID, GLOBAL.cString.convert( "icon_bas" ) );
				IupSetAttributeId( tree, "USERDATA", insertID, tools.getCString( userData ) );
			}
			else
			{
				IupSetAttributeId( tree, "ADDLEAF", folderLocateId, GLOBAL.cString.convert( s ) );
				IupSetAttributeId( tree, "COLOR", folderLocateId + 1, GLOBAL.editColor.projectFore.toCString );
				IupSetAttributeId( tree, "IMAGE", folderLocateId + 1, GLOBAL.cString.convert( "icon_bas" ) );
				IupSetAttributeId( tree, "USERDATA", folderLocateId + 1, tools.getCString( userData ) );
			}
		}
		
		

		// Switch to project tree tab
		IupSetAttribute( GLOBAL.projectViewTabs, "VALUEPOS", "0" );
		//IupSetAttribute( GLOBAL.projectViewTabs, "VALUE_HANDLE", cast(char*) GLOBAL.projectTree.getTreeHandle );

		IupSetAttribute( tree, "MARK", "CLEARALL" );
		
		// Set Focus to Project Tree
		IupSetAttributeId( tree, "MARKED", 1, "YES" );
		IupSetInt( tree, "VALUE", 1 );

		// Recent Projects
		GLOBAL.projectTree.updateRecentProjects( setupDir, GLOBAL.projectManager[setupDir].name );
		GLOBAL.statusBar.setPrjName( null, true );
		//GLOBAL.statusBar.setPrjName( GLOBAL.languageItems["caption_prj"].toDString ~ ": " ~ GLOBAL.projectManager[setupDir].name );
		
		if( IupGetInt( tree, "COUNT" ) > 1 ) IupSetAttribute( projectButtonCollapse, "VISIBLE", "YES" );
	}

	void CreateNewProject( char[] prjName, char[] prjDir )
	{
		//GLOBAL.activeProjectDirName = prjDir;
		IupSetAttribute( GLOBAL.projectTree.getTreeHandle, "MARK", "CLEARALL" ); // For projectTree MULTIPLE Selection

		IupSetAttribute( tree, "ADDBRANCH0", GLOBAL.cString.convert( prjName ) );
		version(Windows) IupSetAttributeId( tree, "MARKED", 1, "YES" ); else IupSetInt( tree, "VALUE", 1 );
		IupSetAttribute( tree, "USERDATA1", tools.getCString( prjDir ) );
		IupSetAttributeId( tree, "COLOR", 1, toStringz( "128 0 0" ) );
		toBoldTitle( tree, 1 );

		IupSetAttribute( tree, "ADDBRANCH1", "Miscellaneous" );
		IupSetAttributeId( tree, "COLOR", 2, toStringz( "0 0 255" ) );
		IupSetAttribute( tree, "IMAGE2", GLOBAL.cString.convert( "icon_door" ) );
		IupSetAttribute( tree, "IMAGEEXPANDED2", GLOBAL.cString.convert( "icon_dooropen" ) );
		toBoldTitle( tree, 2 );
		
		IupSetAttribute( tree, "ADDBRANCH1", "Others" );
		IupSetAttributeId( tree, "COLOR", 2, toStringz( "0 0 255" ) );
		IupSetAttribute( tree, "IMAGE2", GLOBAL.cString.convert( "icon_door" ) );
		IupSetAttribute( tree, "IMAGEEXPANDED2", GLOBAL.cString.convert( "icon_dooropen" ) );
		toBoldTitle( tree, 2 );
		
		IupSetAttribute( tree, "ADDBRANCH1", "Includes" );
		IupSetAttributeId( tree, "COLOR", 2, toStringz( "0 0 255" ) );
		IupSetAttribute( tree, "IMAGE2", GLOBAL.cString.convert( "icon_door" ) );
		IupSetAttribute( tree, "IMAGEEXPANDED2", GLOBAL.cString.convert( "icon_dooropen" ) );
		toBoldTitle( tree, 2 );
		
		IupSetAttribute( tree, "ADDBRANCH1", "Sources" );
		IupSetAttributeId( tree, "COLOR", 2, toStringz( "0 0 255" ) );
		IupSetAttribute( tree, "IMAGE2", GLOBAL.cString.convert( "icon_door" ) );
		IupSetAttribute( tree, "IMAGEEXPANDED2", GLOBAL.cString.convert( "icon_dooropen" ) );
		toBoldTitle( tree, 2 );
		// Set Focus to Project Tree
		IupSetAttribute( GLOBAL.projectViewTabs, "VALUE_HANDLE", cast(char*) tree );
		
		if( IupGetInt( tree, "COUNT" ) > 1 ) IupSetAttribute( projectButtonCollapse, "VISIBLE", "YES" );
	}

	bool openProject( char[] setupDir = null, bool bAskCreateNew = false )
	{
		if( !setupDir.length )
		{
			scope fileSelectDlg = new CFileDlg( GLOBAL.languageItems["caption_openprj"].toDString ~ "...", null, "DIR" );
			setupDir = fileSelectDlg.getFileName();
		}

		if( !setupDir.length ) return false;

		setupDir = Path.normalize( setupDir );
		
		if( setupDir in GLOBAL.projectManager )
		{
			Ihandle* messageDlg = IupMessageDlg();
			IupSetAttributes( messageDlg, "DIALOGTYPE=WARNING" );
			IupSetAttribute( messageDlg, "VALUE", toStringz( "\"" ~ setupDir ~ "\"\n" ~ GLOBAL.languageItems["opened"].toDString ) );
			IupSetAttribute( messageDlg, "TITLE", GLOBAL.languageItems["alarm"].toCString );
			IupPopup( messageDlg, IUP_MOUSEPOS, IUP_MOUSEPOS );			
			return true;
		}

		//if( GLOBAL.editorSetting00.Message == "ON" ) GLOBAL.IDEMessageDlg.print( "Load Project: [" ~ setupDir ~ "]", true ); //IupSetAttribute( GLOBAL.outputPanel, "VALUE", toStringz( "Load Project: [" ~ setupDir ~ "]" ) );
		
		version(FBIDE)	char[] setupFileName = setupDir ~ "/.poseidon";
		version(DIDE)	char[] setupFileName = setupDir ~ "/D.poseidon";

		scope sFN = new FilePath( setupFileName );

		if( sFN.exists() )
		{
			PROJECT		p;
			GLOBAL.projectManager[setupDir] = p.loadFile( setupFileName );

			if( !GLOBAL.projectManager[setupDir].dir.length )
			{
				GLOBAL.projectManager.remove( setupDir );
				Ihandle* messageDlg = IupMessageDlg();
				IupSetAttributes( messageDlg, "DIALOGTYPE=ERROR" );
				IupSetAttribute( messageDlg, "VALUE", GLOBAL.languageItems[".poseidonbroken"].toCString );
				IupSetAttribute( messageDlg, "TITLE", GLOBAL.languageItems["error"].toCString );
				IupPopup( messageDlg, IUP_MOUSEPOS, IUP_MOUSEPOS );					
				return false;
			}

			createProjectTree( setupDir );
		}
		else
		{
			IupMessageError( null, toStringz( "\"" ~ setupDir ~ "\"\n" ~ GLOBAL.languageItems[".poseidonlost"].toDString ) );
			
			if( bAskCreateNew )
			{
				sFN.set( setupDir );
				if( sFN.exists() )
				{
					int result = IupMessageAlarm( null, GLOBAL.languageItems["alarm"].toCString, GLOBAL.languageItems["createnewone"].toCString, "YESNO" );
					if( result == 1 )
					{
						scope dlg = new CProjectPropertiesDialog( -1, -1, GLOBAL.languageItems["caption_prjproperties"].toDString(), true, true, setupDir );
						dlg.show( IUP_CENTERPARENT, IUP_CENTERPARENT );
						return true;
					}
				}
			}

			return false;
		}

		/+
		// Pre-Load Parser
		ParseThread subThread = new ParseThread( GLOBAL.projectManager[setupDir] );
		subThread.start();
		+/

		//if( GLOBAL.editorSetting00.Message == "ON" ) GLOBAL.IDEMessageDlg.print( "Done." );//IupSetAttribute( GLOBAL.outputPanel, "APPEND", toStringz( "Done."  ) );

		return true;
	}

	version(FBIDE)
	{
		bool importFbEditProject()
		{
			scope fileSelectDlg = new CFileDlg( GLOBAL.languageItems["caption_importprj"].toDString() ~ "...",  GLOBAL.languageItems["fbeditfile"].toDString() ~ "|*.fbp|" ~ GLOBAL.languageItems["allfile"].toDString() ~ "|*.*" );
			char[] fbpFullPath = fileSelectDlg.getFileName();

			if( !fbpFullPath.length ) return false;

			scope sFN = new FilePath( fbpFullPath );
			char[] _dir = sFN.path(); // include tail /

			if( _dir.length )
				if( _dir[$-1] == '/' ) _dir = _dir[0..$-1].dup;

			if( _dir in GLOBAL.projectManager )
			{
				Ihandle* messageDlg = IupMessageDlg();
				IupSetAttributes( messageDlg, "DIALOGTYPE=WARNING" );
				IupSetAttribute( messageDlg, "VALUE", toStringz( "\"" ~ _dir ~ "\"\n" ~ GLOBAL.languageItems["opened"].toDString() ) );
				IupSetAttribute( messageDlg, "TITLE", GLOBAL.languageItems["alarm"].toCString );
				IupPopup( messageDlg, IUP_MOUSEPOS, IUP_MOUSEPOS );				
				return false;
			}

			scope poseidonFN = new FilePath( sFN.path ~ ".poseidon" );

			if( poseidonFN.exists() )
			{
				Ihandle* messageDlg = IupMessageDlg();
				IupSetAttributes( messageDlg, "DIALOGTYPE=WARNING,BUTTONDEFAULT=2,BUTTONS=YESNO" );
				IupSetAttribute( messageDlg, "VALUE", GLOBAL.languageItems["continueimport"].toCString );
				IupSetAttribute( messageDlg, "TITLE", GLOBAL.languageItems["alarm"].toCString );
				IupPopup( messageDlg, IUP_CENTER, IUP_CENTER );

				if( IupGetInt( messageDlg, "BUTTONRESPONSE") == 2 ) return false;
			}

			scope file = new File( fbpFullPath, File.ReadExisting );

			PROJECT			prj;
			int				blockType; // blockType = 1 [Project], 2 [Make], 3 [TabOrder], 4 [File], 5 [BreakPoint], 6 [FileInfo], 7 [NoDebug]
			char[][char[]]	fileArrays, optionArrays;
			char[]			currentOption;

			prj.dir = _dir;
			prj.name = sFN.name;

			foreach( line; new Lines!(char)(file) )
			{
				if( line.length )
				{
					char[] _lineData = Util.trim( line );
					bool bContinue;

					switch( _lineData )
					{
						case "[Project]":		blockType = 1; bContinue = true; break;
						case "[Make]":			blockType = 2; bContinue = true; break;
						case "[TabOrder]":		blockType = 3; bContinue = true; break;
						case "[File]":			blockType = 4; bContinue = true; break;
						case "[BreakPoint]":	blockType = 5; bContinue = true; break;
						case "[FileInfo]":		blockType = 6; bContinue = true; break;
						case "[NoDebug]":		blockType = 7; bContinue = true; break;
						default:
					}

					if( !bContinue )
					{
						switch( blockType )
						{
							case 1:
								int assignPos = Util.index( _lineData, "=" );
								if( assignPos < _lineData.length - 1 )
								{
									char[] 	_keyWord = _lineData[0..assignPos];
									char[]	_value = _lineData[assignPos+1..$];
									if( _keyWord == "Description" )
									{
										prj.comment = _value;
									}
								}

							case 2:
								int assignPos = Util.index( _lineData, "=" );
								if( assignPos < _lineData.length - 1 )
								{
									char[] 	_keyWord = _lineData[0..assignPos];
									char[]	_value = _lineData[assignPos+1..$];

									if( _keyWord == "Output" )
									{
										scope _fp = new FilePath( _value );
										prj.targetName = _fp.name;
									}
									else if( _keyWord == "Run" )
									{
										prj.args = _value;
									}
									else  if( _keyWord == "Current" )
									{
										currentOption = _value;
									}
									else
									{
										if( _keyWord[0] > 48 && _keyWord[0] < 58 )
											if( Integer.atoi( _keyWord ) < 1000 ) optionArrays[_keyWord] = _value;
									}
								}
								break;

							case 4:
								int assignPos = Util.index( _lineData, "=" );
								if( assignPos < _lineData.length - 1 )
								{
									char[] 	_keyWord = _lineData[0..assignPos];
									char[]	_value = _lineData[assignPos+1..$];

									if( _keyWord == "Main" )
									{
										if( fileArrays.length )	prj.mainFile = fileArrays[_value];
										break;
									}
					
									fileArrays[_keyWord] = _value;

									scope _fp = new FilePath( Path.normalize( _value ) );
									version(FBIDE)
									{
										switch( lowerCase( _fp.ext ) )
										{
											case "bas":		if( !_fp.isAbsolute ) prj.sources ~= ( prj.dir ~ "/" ~ _value ); else prj.sources ~= _value;	break;
											case "bi":		if( !_fp.isAbsolute ) prj.includes ~= ( prj.dir ~ "/" ~ _value ); else prj.includes ~= _value;	break;
											default:		if( !_fp.isAbsolute ) prj.others ~= ( prj.dir ~ "/" ~ _value ); else prj.others ~= _value;		break;
											
										}
									}
									version(DIDE)
									{
										switch( lowerCase( _fp.ext ) )
										{
											case "d":		if( !_fp.isAbsolute ) prj.sources ~= ( prj.dir ~ "/" ~ _value ); else prj.sources ~= _value;	break;
											case "di":		if( !_fp.isAbsolute ) prj.includes ~= ( prj.dir ~ "/" ~ _value ); else prj.includes ~= _value;	break;
											default:		if( !_fp.isAbsolute ) prj.others ~= ( prj.dir ~ "/" ~ _value ); else prj.others ~= _value;		break;
											
										}
									}
								}
								break;

							default:
						}
					}
				}
			}

			if( currentOption.length )
			{
				if( currentOption in optionArrays )
				{
					char[] option = optionArrays[currentOption];
					int posComma = Util.index( option, "," );
					if( posComma < option.length )
					{
						option = option[posComma+1..$];
						option = Util.substitute( option, "fbc ", "" );
						prj.compilerOption = Util.trim( option );
					}
				}
			}

			prj.type = "1";

			GLOBAL.projectManager[prj.dir] = prj;
			createProjectTree( prj.dir );
			return true;
		}
	}
	
	void closeProject()
	{
		char[] activePrjName = actionManager.ProjectAction.getActiveProjectName();

		if( activePrjName.length )
		{
			foreach( char[] s; GLOBAL.projectManager[activePrjName].sources ~ GLOBAL.projectManager[activePrjName].includes ~ GLOBAL.projectManager[activePrjName].others ~ GLOBAL.projectManager[activePrjName].misc )
			{
				if( actionManager.ScintillaAction.closeDocument( s ) == IUP_IGNORE ) return;
			}
			
			DocumentTabAction.updateTabsLayout();			

			GLOBAL.projectManager[activePrjName].saveFile();
			//if( GLOBAL.editorSetting00.Message == "ON" ) GLOBAL.IDEMessageDlg.print( "Close Project: [" ~ GLOBAL.projectManager[activePrjName].name ~ "]" );//IupSetAttribute( GLOBAL.outputPanel, "APPEND", toStringz( "Close Project: [" ~ GLOBAL.projectManager[activePrjName].name ~ "]"  ) );
			GLOBAL.projectManager.remove( activePrjName );

			int countChild = IupGetInt( tree, "COUNT" );
			for( int i = 1; i <= countChild; ++ i )
			{
				int depth = IupGetIntId( tree, "DEPTH", i );
				if( depth == 1 )
				{
					if( fromStringz( IupGetAttributeId( tree, "USERDATA", i )) == activePrjName )
					{
						char* user = IupGetAttributeId( tree, "USERDATA", i );
						if( user != null ) delete user;
						IupSetAttributeId( tree, "DELNODE", i, "SELECTED" );
						break;
					}
				}
			}

			if( IupGetInt( tree, "COUNT" ) == 1 )
			{
				GLOBAL.statusBar.setPrjName( "" );
				IupSetAttribute( projectButtonCollapse, "VISIBLE", "NO" );
			}
			else
			{
				GLOBAL.statusBar.setPrjName( null, true );
			}
		}
	}
	
	void closeAllProjects()
	{
		char[][] prjsDir;
		
		foreach( PROJECT p; GLOBAL.projectManager )
		{
			//IupMessage("",toStringz(p.dir) );
			foreach( char[] s; p.sources ~ p.includes ~ p.others ~ p.misc )
			{
				if( actionManager.ScintillaAction.closeDocument( s ) == IUP_IGNORE )
				{
					foreach( char[] _s; prjsDir )
					{
						GLOBAL.projectManager.remove( _s );
					}

					//IupSetAttribute( GLOBAL.mainDlg, "TITLE", "poseidonFB - FreeBasic IDE" );
					GLOBAL.statusBar.setPrjName( "" );
					return; 
				}
			}
			
			DocumentTabAction.updateTabsLayout();

			prjsDir ~= p.dir.dup;
			p.saveFile();
			
			int countChild = IupGetInt( tree, "COUNT" );
			for( int i = countChild - 1; i > 0; -- i )
			{
				int depth = IupGetIntId( tree, "DEPTH", i );
				if( depth == 1 )
				{
					try
					{
						char[] _cstring = fromStringz( IupGetAttributeId( tree, "USERDATA", i ) );
						if( _cstring == p.dir )
						{
							char* user = IupGetAttributeId( tree, "USERDATA", i );
							if( user != null ) delete user;
							IupSetAttributeId( tree, "DELNODE", i, "SELECTED" );

							break;
						}
					}
					catch( Exception e )
					{
						//IupMessage( "", toStringz( e.toString ) );
					}
				}
			}

			//if( GLOBAL.editorSetting00.Message == "ON" ) GLOBAL.IDEMessageDlg.print( "Close Project: [" ~ p.name ~ "]" );//IupSetAttribute( GLOBAL.outputPanel, "APPEND", toStringz( "Close Project: [" ~ p.name ~ "]"  ) );
		}

		foreach( char[] s; prjsDir )
		{
			GLOBAL.projectManager.remove( s );
			//IupMessage("Remove",toStringz(s) );
		}

		if( IupGetInt( tree, "COUNT" ) == 1 )
		{
			GLOBAL.statusBar.setPrjName( "" );
			IupSetAttribute( projectButtonCollapse, "VISIBLE", "NO" );
		}
	}

	void updateRecentProjects( char[] prjDir, char[] prjName )
	{
		char[] title;
		
		if( prjDir.length )
		{
			IupString[]	temps;
			
			title = prjDir ~ " : " ~ prjName;
			
			for( int i = 0; i < GLOBAL.recentProjects.length; ++ i )
			{
				if( GLOBAL.recentProjects[i].toDString != title ) temps ~= new IupString( GLOBAL.recentProjects[i].toDString );
			}

			temps ~= new IupString( title );
			
			for( int i = 0; i < GLOBAL.recentProjects.length; ++ i )
				delete GLOBAL.recentProjects[i];
				
			int count, index;
			if( temps.length > 8 )
			{
				GLOBAL.recentProjects.length = 8;
				for( count = temps.length - 8; count < temps.length; ++count )
					GLOBAL.recentProjects[index++] = temps[count];
			}
			else
			{
				GLOBAL.recentProjects.length = temps.length;
				for( count = 0; count < temps.length; ++count )
					GLOBAL.recentProjects[index++] = temps[count];
			}				
		}
		else
		{
			for( int i = 0; i < GLOBAL.recentProjects.length; ++ i )
				delete GLOBAL.recentProjects[i];
				
			GLOBAL.recentProjects.length = 0;
		}
		

		Ihandle* recentPrj_ih = IupGetHandle( "recentPrjsSubMenu" );
		if( recentPrj_ih != null )
		{
			// Clear All iupItem......
			for( int i = IupGetChildCount( recentPrj_ih ) - 1; i >= 0; -- i )
			{
				IupDestroy( IupGetChild( recentPrj_ih, i ) );
			}

			Ihandle* _clearRecentPrjs = IupItem( GLOBAL.languageItems["clearall"].toCString, null );
			IupSetAttribute(_clearRecentPrjs, "IMAGE", "icon_clearall");
			IupSetCallback( _clearRecentPrjs, "ACTION", cast(Icallback) &menu.submenuRecentPrjsClear_click_cb );
			IupInsert( recentPrj_ih, null, _clearRecentPrjs );
			IupMap( IupGetChild( recentPrj_ih, 0 ) );
			IupInsert( recentPrj_ih, null, IupSeparator() );
			IupMap( IupGetChild( recentPrj_ih, 0 ) );
	
			// Create New iupItem
			for( int i = 0; i < GLOBAL.recentProjects.length; ++ i )
			{
				Ihandle* _new = IupItem( GLOBAL.recentProjects[i].toCString, null );
				IupSetCallback( _new, "ACTION", cast(Icallback) &menu.submenuRecentProject_click_cb );
				IupInsert( recentPrj_ih, null, _new );
				IupMap( _new );
			}
			IupRefresh( recentPrj_ih );
		}		
	}	
}


extern(C)
{
	// Node has been Selected, but Notice! Right-Click isn't Trigger!
	private int CProjectTree_Selection_cb( Ihandle *ih, int id, int status )
	{
		// SELECTION_CB will trigger 2 times, preSelect -> Select, we only catch second signal
		if( status == 1 )
		{
			//IupMessage("Select", toStringz( Integer.toString( id ) ) );
			
			try
			{
				//IupSetInt( ih, "VALUE", id ); // Make Crash
				
				// Swith the doument tabs by select Tree Node, if the doument isn't exist, do nothing
				if( fromStringz( IupGetAttributeId( ih, "KIND", id ) ) == "LEAF" )
				{
					char*	_fullpath = IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id );
					
					if( _fullpath != null )
					{
						char[] fullPath = fromStringz( _fullpath ).dup;

						if( fullPathByOS(fullPath) in GLOBAL.scintillaManager ) 
						{
							actionManager.ScintillaAction.openFile( fullPath );
						}
					}
					
					char[] 	_selectedStatus = fromStringz( IupGetAttribute( GLOBAL.projectTree.getTreeHandle,"MARKEDNODES" ) );
					for( int i = 0; i < _selectedStatus.length; ++ i )
					{
						if( _selectedStatus[i] == '+' )
						{
							if( fromStringz( IupGetAttributeId( ih, "KIND", i ) ) == "BRANCH" ) IupSetAttributeId( ih, "MARKED", i, "NO" );
						}
					}
					DocumentTabAction.setFocus( ScintillaAction.getActiveIupScintilla() ); 
				}
				else
				{
					int[] ids = actionManager.ProjectAction.getSelectIDs();
					if( ids.length )
					{
						IupSetAttribute( ih, "MARK", "CLEARALL" );
						IupSetAttributeId( ih, "MARKED", id, "YES" );
					}
				}

				if( id > 0 )
				{
					int 	depth	= IupGetIntId( ih, "DEPTH", id );
				
					while( depth > 1 )
					{
						id = IupGetIntId( ih, "PARENT", id );
						depth = IupGetIntId( ih, "DEPTH", id );
					}				

					GLOBAL.statusBar.setPrjName( Integer.toString( id ), true );
				}
				else
				{
					GLOBAL.statusBar.setPrjName( "                                            " );
					//IupSetAttribute( GLOBAL.mainDlg, "TITLE", "poseidonFB - FreeBasic IDE" );
				}
			}
			catch( Exception e )
			{
				//GLOBAL.IDEMessageDlg.print( "CProjectTree_Selection_cb() Error:\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ Integer.toString( e.line ) );
				IupMessage( "CProjectTree_Selection_cb", toStringz( "CProjectTree_Selection_cb Error\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ Integer.toString( e.line ) ) );
			}
		}
		else
		{
			//IupMessage("UnSelect", toStringz( Integer.toString( id ) ) );
		}

		return IUP_DEFAULT;
	}

	private int CProjectTree_BUTTON_CB( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		return IUP_DEFAULT;
	}
	/*
	private int CProjectTree_BUTTON_CB( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		if( pressed == 1 )
		{
			if( button == IUP_BUTTON1 ) // Left Click
			{
				char[] _s = fromStringz( status ).dup;
				if( _s.length > 5 )
				{
					if( _s[5] == 'D' ) // Double Click
					{
						CProjectTree_Open_cb( ih );
						return IUP_IGNORE;
					}
				}
			}
		}
		return IUP_DEFAULT;
	}
	*/
	
	/*
	private int CProjectTree_BRANCH_CB( Ihandle* ih, int id )
	{
		/+
		if( IupGetInt( ih, "VALUE" ) != id )
		{
			IupSetAttribute( ih, "MARK", "CLEARALL" );
			IupSetAttributeId( ih, "MARKED", id, "YES" );
			IupSetInt( ih, "VALUE", id );
		}
		//IupMessage("TOGGLLE","");
		+/
		return IUP_DEFAULT;
	}
	*/
	
	private int CProjectTree_EXECUTELEAF_CB( Ihandle* ih, int id )
	{
		return CProjectTree_Open_cb( ih );
	}	
	
	private int CProjectTree_NodeRemoved_cb( Ihandle *ih, void* userdata )
	{
		char* dataPointer = cast(char*) userdata;
		tools.freeCString( dataPointer );

		return IUP_DEFAULT;
	}
	
	private int CProjectTree_MULTISELECTION_CB( Ihandle *ih, int* ids, int n )
	{
		char[] status = fromStringz( IupGetAttribute(ih,"MARKEDNODES") );
		for( int i = 0; i < status.length; ++ i )
		{
			if( status[i] == '+' )
			{
				if( fromStringz( IupGetAttributeId( ih, "KIND", i ) ) == "BRANCH" )
				{
					IupSetAttributeId( ih, "MARKED", i, "NO" );
				}
			}
		}
		
		//IupMessage("MultiSelect",IupGetAttribute(ih,"MARKEDNODES"));
		return IUP_DEFAULT;
	}
	
	private int CProjectTree_MULTIUNSELECTION_CB( Ihandle *ih, int* ids, int n )
	{
		char[] status = fromStringz( IupGetAttribute(ih,"MARKEDNODES") );
		
		if( status.length >= n )
		{
			for( int i = 0; i < n; ++ i )
			{
				status[ids[i]] = '-';
			}
			
			for( int i = 0; i < status.length; ++ i )
			{
				if( status[i] == '+' )
				{
					if( fromStringz( IupGetAttributeId( ih, "KIND", i ) ) == "LEAF" )
					{
						char[]	fullPath = fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", i ) );
						if( fullPathByOS(fullPath) in GLOBAL.scintillaManager )
						{
							ScintillaAction.openFile( fullPath );
							break;
						}
					}
				}
			}
		}

		return IUP_DEFAULT;
	}


	// 
	private int CProjectTree_RightClick_cb( Ihandle *ih, int id )
	{
		if( fromStringz( IupGetAttributeId( ih, "MARKED", id ) ) == "NO" )
		{
			IupSetAttribute( ih, "MARK", "CLEARALL" );
			IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "MARKED", id, "YES" );
		}
		IupSetInt( GLOBAL.projectTree.getTreeHandle, "VALUE", id );

		char[] nodeKind = fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "KIND", id ) );

		if( nodeKind == "LEAF" ) // On File(*.bas, *.bi) Node
		{
			Ihandle* popupMenu;
			
			scope titleFP = new FilePath( fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "TITLE", id ) ) );
			
			int		typeID				= actionManager.ProjectAction.getTargetDepthID( 2 );
			char[]	prjFilesFolderName	= fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "TITLE", typeID ) ).dup; // = Sources or Includes or Others or Miscellaneous
			
			switch( prjFilesFolderName )
			{
				case "Others":
				case "Miscellaneous":
					popupMenu = IupMenu( 
											IupItem( GLOBAL.languageItems["open"].toCString, "CProjectTree_open" ),
											IupItem( GLOBAL.languageItems["openinposeidon"].toCString, "CProjectTree_openin" ),
											IupItem( GLOBAL.languageItems["removefromprj"].toCString, "CProjectTree_remove" ),
											IupSeparator(),
											IupItem( GLOBAL.languageItems["delete"].toCString, "CProjectTree_delete" ),
											IupItem( GLOBAL.languageItems["rename"].toCString, "CProjectTree_rename" ),
											/*
											IupSeparator(),
											IupItem( GLOBAL.languageItems["setmainmodule"].toCString, "CProjectTree_setmainmodule" ),
											*/
											null
										);
					IupSetFunction( "CProjectTree_openin", cast(Icallback) &CProjectTree_Openin_cb );
					break;
					
				default:
					if( lowerCase( titleFP.ext ) == "bas" )
					{
						popupMenu = IupMenu( 
												IupItem( GLOBAL.languageItems["open"].toCString, "CProjectTree_open" ),
												IupItem( GLOBAL.languageItems["removefromprj"].toCString, "CProjectTree_remove" ),
												IupSeparator(),
												IupItem( GLOBAL.languageItems["delete"].toCString, "CProjectTree_delete" ),
												IupItem( GLOBAL.languageItems["rename"].toCString, "CProjectTree_rename" ),
												IupSeparator(),
												IupItem( GLOBAL.languageItems["setmainmodule"].toCString, "CProjectTree_setmainmodule" ),
												null
											);
											
						IupSetFunction( "CProjectTree_setmainmodule", cast(Icallback) &CProjectTree_setmainmodule_cb );
					}
					else
					{
						popupMenu = IupMenu( 
												IupItem( GLOBAL.languageItems["open"].toCString, "CProjectTree_open" ),
												IupItem( GLOBAL.languageItems["removefromprj"].toCString, "CProjectTree_remove" ),
												IupSeparator(),
												IupItem( GLOBAL.languageItems["delete"].toCString, "CProjectTree_delete" ),
												IupItem( GLOBAL.languageItems["rename"].toCString, "CProjectTree_rename" ),
												null
											);
					}				
			}
			
			IupSetFunction( "CProjectTree_open", cast(Icallback) &CProjectTree_Open_cb );
			IupSetFunction( "CProjectTree_remove", cast(Icallback) &CProjectTree_remove_cb );
			IupSetFunction( "CProjectTree_delete", cast(Icallback) &CProjectTree_delete_cb );
			IupSetFunction( "CProjectTree_rename", cast(Icallback) &CProjectTree_rename_cb );

			IupPopup( popupMenu, IUP_MOUSEPOS, IUP_MOUSEPOS );
			IupDestroy( popupMenu );

			return IUP_DEFAULT;
		}



		int depth = IupGetIntId( GLOBAL.projectTree.getTreeHandle, "DEPTH", id );

		switch( depth )
		{
			case 0:
				Ihandle* itemNewProject = IupItem( GLOBAL.languageItems["newprj"].toCString, null );
				IupSetAttribute(itemNewProject, "IMAGE", "icon_newprj");
				IupSetCallback( itemNewProject, "ACTION", cast(Icallback) &menu.newProject_cb ); // From menu.d
				
				Ihandle* itemOpenProject = IupItem( GLOBAL.languageItems["openprj"].toCString, null );
				IupSetAttribute(itemOpenProject, "IMAGE", "icon_openprj");
				IupSetCallback( itemOpenProject, "ACTION", cast(Icallback) &menu.openProject_cb ); // From menu.d

				Ihandle* itemCloseAllProject = IupItem( GLOBAL.languageItems["closeallprj"].toCString, null );
				IupSetAttribute(itemCloseAllProject, "IMAGE", "icon_clearall");
				IupSetCallback( itemCloseAllProject, "ACTION", cast(Icallback) &menu.closeAllProject_cb ); // From menu.d
				

				Ihandle* popupMenu = IupMenu( 	itemNewProject, 
												itemOpenProject,
												IupSeparator(),
												itemCloseAllProject,
												null
											);

				IupPopup( popupMenu, IUP_MOUSEPOS, IUP_MOUSEPOS );
				IupDestroy( popupMenu );
				break;

			case 1:		// On Project Name Node
				Ihandle* itemImportAll = IupItem( GLOBAL.languageItems["importall"].toCString, null );
				IupSetAttribute(itemImportAll, "IMAGE", "icon_importall");
				IupSetCallback( itemImportAll, "ACTION", cast(Icallback) &CProjectTree_importall_cb );
			
				Ihandle* itemProperty = IupItem( GLOBAL.languageItems["properties"].toCString, null );
				IupSetAttribute(itemProperty, "IMAGE", "icon_properties");
				IupSetCallback( itemProperty, "ACTION", cast(Icallback) &menu.projectProperties_cb ); // From menu.d
				
				Ihandle* itemClose = IupItem( GLOBAL.languageItems["closeprj"].toCString, null );
				IupSetAttribute(itemClose, "IMAGE", "icon_clear");
				IupSetCallback( itemClose, "ACTION", cast(Icallback) &menu.closeProject_cb );  // From menu.d

				Ihandle* itemExplorer = IupItem( GLOBAL.languageItems["openinexplorer"].toCString, null );
				IupSetCallback( itemExplorer, "ACTION", cast(Icallback) function( Ihandle* ih )
				{
					char[]	fullPath = actionManager.ProjectAction.getActiveProjectName();

					version( Windows )
					{
						fullPath = Util.substitute( fullPath, "/", "\\" );
						IupExecute( "explorer", toStringz( "\"" ~ fullPath ~ "\"" ) );
						/*
						scope proc = new Process( true, "explorer " ~ "\"" ~ fullPath ~ "\"" );
						proc.execute;
						proc.wait;
						*/
					}
					else
					{
						IupExecute( "xdg-open", toStringz( "\"" ~ fullPath ~ "\"" ) );
						/*
						scope proc = new Process( true, "xdg-open " ~ "\"" ~ fullPath ~ "\"" );
						proc.execute;
						proc.wait;
						*/
					}
					return IUP_DEFAULT;
				});

				Ihandle* popupMenu = IupMenu(	itemImportAll,
												itemProperty,
												IupSeparator(),
												itemExplorer,
												IupSeparator(),
												itemClose,
												null
											);

				IupPopup( popupMenu, IUP_MOUSEPOS, IUP_MOUSEPOS );
				IupDestroy( popupMenu );
				break;

			case 2:		// On Source or Include Node
			default:
				//char[] s = fromStringz( IupGetAttributeId( GLOBAL.projectTree.getShadowTreeHandle, "TITLE", id ) );
				char[] s = fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id ) );
				if( s.length )
				{
					if( s == "FIXED" ) return IUP_DEFAULT;
				}
				
				Ihandle* itemNewFile = IupItem( GLOBAL.languageItems["newfile"].toCString, null );
				IupSetCallback( itemNewFile, "ACTION", cast(Icallback) &CProjectTree_NewFile_cb );
				Ihandle* itemNewFolder = IupItem( GLOBAL.languageItems["newfolder"].toCString, null );
				IupSetCallback( itemNewFolder, "ACTION", cast(Icallback) &CProjectTree_NewFolder_cb );
				
				Ihandle* itemCreateNew = IupMenu( itemNewFile, itemNewFolder, null );
		
				Ihandle* itemNew = IupSubmenu( GLOBAL.languageItems["new"].toCString, itemCreateNew );
				
				Ihandle* itemAdd = IupItem( GLOBAL.languageItems["addfile"].toCString, null );
				IupSetCallback( itemAdd, "ACTION", &CProjectTree_AddFile_cb );

				Ihandle* popupMenu;
				if( depth == 2 )
				{
					popupMenu = IupMenu(	itemNew,
											itemAdd,
											null
										);
				}
				else
				{
					popupMenu = IupMenu( itemNew, null );
				}

				IupPopup( popupMenu, IUP_MOUSEPOS, IUP_MOUSEPOS );
				IupDestroy( popupMenu );

				break;
			//default:
		}

		return IUP_DEFAULT;
	}

	private int CProjectTree_NewFile_cb( Ihandle* ih )
	{
		// Open Dialog Window
		scope test = new CSingleTextDialog( -1, -1, GLOBAL.languageItems["newfile"].toDString(), GLOBAL.languageItems["filename"].toDString() ~ ":", "120x", null, false, "POSEIDON_MAIN_DIALOG", "icon_newfile" );
		IupSetAttribute( test.getIhandle, "OPACITY", toStringz( GLOBAL.editorSetting02.newfileDlg ) );
		char[] fileName = test.show( IUP_MOUSEPOS, IUP_MOUSEPOS );

		if( fileName.length )
		{
			// Get Depth
			char[]		prjFilesFolderName;
			char[][] 	stepFolder;
			
			int 		id		= IupGetInt( GLOBAL.projectTree.getTreeHandle, "VALUE" ); // Get Focus TreeNode
			int 		depth	= IupGetIntId( GLOBAL.projectTree.getTreeHandle, "DEPTH", id );
			
			if( depth >= 2 ) // Under Branch of Branch
			{
				while( depth > 2 )
				{
					stepFolder ~= fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "TITLE", id ) ).dup;
					
					id = IupGetIntId( GLOBAL.projectTree.getTreeHandle, "PARENT", id );
					depth = IupGetIntId( GLOBAL.projectTree.getTreeHandle, "DEPTH", id );
				}

				prjFilesFolderName = fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "TITLE", id ) ).dup; // = Sources or Includes or Others
			}

			char[] activeProjectDirName = actionManager.ProjectAction.getActiveProjectName();
			char[] fullPath = activeProjectDirName ~ "/";
			//char[] fullPath = GLOBAL.activeProjectDirName ~ "\\";
			
			foreach_reverse( char[] s; stepFolder )
			{
				fullPath = fullPath ~ s ~ "/";
			}
			fullPath = fullPath ~ fileName;

			scope fn = new FilePath( fullPath );

			if( fn.exists() )
			{
				Ihandle* messageDlg = IupMessageDlg();
				IupSetAttributes( messageDlg, "DIALOGTYPE=WARNING" );
				IupSetAttribute( messageDlg, "VALUE", toStringz( "\"" ~ fileName ~ "\"\n" ~ GLOBAL.languageItems["existed"].toDString() ) );
				IupSetAttribute( messageDlg, "TITLE", GLOBAL.languageItems["alarm"].toCString );
				IupPopup( messageDlg, IUP_MOUSEPOS, IUP_MOUSEPOS );					
				return IUP_DEFAULT;
			}
			
			// Wrong Ext, exit!
			version(FBIDE)
			{
				switch( lowerCase( fn.ext ) )
				{
					case "bas":
						if( prjFilesFolderName != "Sources" )
						{
							Ihandle* messageDlg = IupMessageDlg();
							IupSetAttributes( messageDlg, "DIALOGTYPE=ERROR" );
							IupSetAttribute( messageDlg, "VALUE", GLOBAL.languageItems["wrongext"].toCString );
							IupSetAttribute( messageDlg, "TITLE", GLOBAL.languageItems["error"].toCString );
							IupPopup( messageDlg, IUP_MOUSEPOS, IUP_MOUSEPOS );							
							return IUP_DEFAULT;
						}
						break;
					case "bi":
						if( prjFilesFolderName != "Includes" )
						{
							Ihandle* messageDlg = IupMessageDlg();
							IupSetAttributes( messageDlg, "DIALOGTYPE=ERROR" );
							IupSetAttribute( messageDlg, "VALUE", GLOBAL.languageItems["wrongext"].toCString );
							IupSetAttribute( messageDlg, "TITLE", GLOBAL.languageItems["error"].toCString );
							IupPopup( messageDlg, IUP_MOUSEPOS, IUP_MOUSEPOS );							
							return IUP_DEFAULT;
						}
						break;
					default:
						if( prjFilesFolderName != "Others" && prjFilesFolderName != "Miscellaneous" )
						{
							Ihandle* messageDlg = IupMessageDlg();
							IupSetAttributes( messageDlg, "DIALOGTYPE=ERROR" );
							IupSetAttribute( messageDlg, "VALUE", GLOBAL.languageItems["wrongext"].toCString );
							IupSetAttribute( messageDlg, "TITLE", GLOBAL.languageItems["error"].toCString );
							IupPopup( messageDlg, IUP_MOUSEPOS, IUP_MOUSEPOS );							
							return IUP_DEFAULT;
						}
				}
			}
			version(DIDE)
			{
				switch( lowerCase( fn.ext ) )
				{
					case "d":
						if( prjFilesFolderName != "Sources" )
						{
							Ihandle* messageDlg = IupMessageDlg();
							IupSetAttributes( messageDlg, "DIALOGTYPE=ERROR" );
							IupSetAttribute( messageDlg, "VALUE", GLOBAL.languageItems["wrongext"].toCString );
							IupSetAttribute( messageDlg, "TITLE", GLOBAL.languageItems["error"].toCString );
							IupPopup( messageDlg, IUP_MOUSEPOS, IUP_MOUSEPOS );							
							return IUP_DEFAULT;
						}
						break;
					case "di":
						if( prjFilesFolderName != "Includes" )
						{
							Ihandle* messageDlg = IupMessageDlg();
							IupSetAttributes( messageDlg, "DIALOGTYPE=ERROR" );
							IupSetAttribute( messageDlg, "VALUE", GLOBAL.languageItems["wrongext"].toCString );
							IupSetAttribute( messageDlg, "TITLE", GLOBAL.languageItems["error"].toCString );
							IupPopup( messageDlg, IUP_MOUSEPOS, IUP_MOUSEPOS );							
							return IUP_DEFAULT;
						}
						break;
					default:
						if( prjFilesFolderName != "Others" && prjFilesFolderName != "Miscellaneous" )
						{
							Ihandle* messageDlg = IupMessageDlg();
							IupSetAttributes( messageDlg, "DIALOGTYPE=ERROR" );
							IupSetAttribute( messageDlg, "VALUE", GLOBAL.languageItems["wrongext"].toCString );
							IupSetAttribute( messageDlg, "TITLE", GLOBAL.languageItems["error"].toCString );
							IupPopup( messageDlg, IUP_MOUSEPOS, IUP_MOUSEPOS );							
							return IUP_DEFAULT;
						}
				}
			}

			// Reset FilePath Object
			fn.set( fn.path );
			if( !fn.exists() ) fn.create(); // Create Folder On Disk

			actionManager.ScintillaAction.newFile( fullPath );
			//GLOBAL.outlineTree.loadFile( fullPath );

			id = IupGetInt( GLOBAL.projectTree.getTreeHandle, "VALUE" ); // Re-Get Active Focus Node ID
			IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "ADDLEAF", id, GLOBAL.cString.convert( fileName ) );
			IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "COLOR", id + 1, GLOBAL.editColor.projectFore.toCString );
			IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id+1, tools.getCString( fullPath ) );
			// shadow
			//IupSetAttributeId( GLOBAL.projectTree.getShadowTreeHandle, "ADDLEAF", id, GLOBAL.cString.convert( fullPath ) );

			switch( prjFilesFolderName )
			{
				case "Sources":
					GLOBAL.projectManager[activeProjectDirName].sources ~= fullPath;
					IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "IMAGE", id + 1, GLOBAL.cString.convert( "icon_bas" ) );
					break;
				case "Includes":
					GLOBAL.projectManager[activeProjectDirName].includes ~= fullPath;
					IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "IMAGE", id + 1, GLOBAL.cString.convert( "icon_bi" ) );
					break;
				case "Others":
					GLOBAL.projectManager[activeProjectDirName].others ~= fullPath;
					IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "IMAGE", id + 1, GLOBAL.cString.convert( "icon_txt" ) );
					break;
				default:
					GLOBAL.projectManager[activeProjectDirName].misc ~= fullPath;
					IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "IMAGE", id + 1, GLOBAL.cString.convert( "icon_txt" ) );
					break;
			}
		}
		
		return IUP_DEFAULT;
	}

	private int CProjectTree_NewFolder_cb( Ihandle* ih )
	{
		scope test = new CSingleTextDialog( -1, -1, GLOBAL.languageItems["newfolder"].toDString(), GLOBAL.languageItems["foldername"].toDString() ~ ":", "120x", null, false );
		char[] folderName = test.show( IUP_MOUSEPOS, IUP_MOUSEPOS );

		if( folderName.length )
		{
			// Get Focus Tree Node ID
			int id = IupGetInt( GLOBAL.projectTree.getTreeHandle, "VALUE" );

			// Get Focus Tree Node 
			char[] kind = fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "KIND", id ) );

			if( kind == "BRANCH" )
			{
				IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "ADDBRANCH", id, GLOBAL.cString.convert( folderName ) );
				IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "COLOR", id + 1, GLOBAL.editColor.projectFore.toCString );
				// shadow
				//IupSetAttributeId( GLOBAL.projectTree.getShadowTreeHandle, "ADDBRANCH", id, GLOBAL.cString.convert( folderName ) );
			}
		}
		
		return IUP_DEFAULT;
	}

	private int CProjectTree_AddFile_cb( Ihandle* ih )
	{
		try
		{
			int		id					= actionManager.ProjectAction.getTargetDepthID( 2 );
			char[]	prjFilesFolderName	= fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "TITLE", id ) ).dup; // = Sources or Includes or Others
			char[]	prjDirName 			= actionManager.ProjectAction.getActiveProjectName();
			char[]	filter;

			version(FBIDE)
			{
				switch( prjFilesFolderName )
				{
					case "Sources":		filter = GLOBAL.languageItems["basfile"].toDString() ~ "|*.bas|" ~ GLOBAL.languageItems["allfile"].toDString() ~ "|*.*"; break;
					case "Includes":	filter = GLOBAL.languageItems["bifile"].toDString() ~ "|*.bi|" ~ GLOBAL.languageItems["allfile"].toDString() ~ "|*.*"; break;
					default:			filter = GLOBAL.languageItems["allfile"].toDString() ~ "|*.*"; break;
				}
			}
			version(DIDE)
			{
				switch( prjFilesFolderName )
				{
					case "Sources":		filter = GLOBAL.languageItems["basfile"].toDString() ~ "|*.d|" ~ GLOBAL.languageItems["allfile"].toDString() ~ "|*.*"; break;
					case "Includes":	filter = GLOBAL.languageItems["bifile"].toDString() ~ "|*.di|" ~ GLOBAL.languageItems["allfile"].toDString() ~ "|*.*"; break;
					default:			filter = GLOBAL.languageItems["allfile"].toDString() ~ "|*.*"; break;
				}
			}
			
			
			scope fileSecectDlg = new CFileDlg( GLOBAL.languageItems["addfile"].toDString() ~ "...", filter, "OPEN", "YES" );
			//char[] fullPath = fileSecectDlg.getFileName();
			
			foreach_reverse( char[] fullPath; fileSecectDlg.getFilesName() )
			{
				if( fullPath.length )
				{
					scope fn = new FilePath( fullPath.dup );
					if( !fn.exists() )
					{
						Ihandle* messageDlg = IupMessageDlg();
						IupSetAttributes( messageDlg, "DIALOGTYPE=WARNING" );
						IupSetAttribute( messageDlg, "VALUE", toStringz( "\"" ~ fullPath ~ "\"\n" ~ GLOBAL.languageItems["existed"].toDString() ) );
						IupSetAttribute( messageDlg, "TITLE", toStringz( GLOBAL.languageItems["alarm"].toDString() ) );
						IupPopup( messageDlg, IUP_MOUSEPOS, IUP_MOUSEPOS );							
						return IUP_DEFAULT;
					}
					else
					{
						//Util.substitute( fullPath, "/", "\\" );
						bool bExitChildLoop;
						foreach( char[] s; GLOBAL.projectManager[prjDirName].sources ~ GLOBAL.projectManager[prjDirName].includes ~ GLOBAL.projectManager[prjDirName].others ~ GLOBAL.projectManager[prjDirName].misc )
						{
							if( s == fullPath )
							{
								bExitChildLoop = true;
								break;
							}
						}
						if( bExitChildLoop ) continue;
					}

					// Wrong Ext, exit!
					
					// Version Condition
					version(FBIDE)
					{
						switch( lowerCase( fn.ext ) )
						{
							case "bas":
								if( prjFilesFolderName != "Sources" )
								{
									Ihandle* messageDlg = IupMessageDlg();
									IupSetAttributes( messageDlg, "DIALOGTYPE=ERROR" );
									IupSetAttribute( messageDlg, "VALUE", GLOBAL.languageItems["wrongext"].toCString );
									IupSetAttribute( messageDlg, "TITLE", GLOBAL.languageItems["error"].toCString );
									IupPopup( messageDlg, IUP_MOUSEPOS, IUP_MOUSEPOS );								
									return IUP_DEFAULT;
								}
								else
								{
									GLOBAL.projectManager[prjDirName].sources ~= fullPath;
								}
								break;
							case "bi":
								if( prjFilesFolderName != "Includes" )
								{
									Ihandle* messageDlg = IupMessageDlg();
									IupSetAttributes( messageDlg, "DIALOGTYPE=ERROR" );
									IupSetAttribute( messageDlg, "VALUE", GLOBAL.languageItems["wrongext"].toCString );
									IupSetAttribute( messageDlg, "TITLE", GLOBAL.languageItems["error"].toCString );
									IupPopup( messageDlg, IUP_MOUSEPOS, IUP_MOUSEPOS );								
									return IUP_DEFAULT;
								}
								else
								{
									GLOBAL.projectManager[prjDirName].includes ~= fullPath;
								}
								break;
							default:
								if( prjFilesFolderName == "Others" )
									GLOBAL.projectManager[prjDirName].others ~= fullPath;
								else if( prjFilesFolderName == "Miscellaneous" )
									GLOBAL.projectManager[prjDirName].misc ~= fullPath;
								else
								{
									Ihandle* messageDlg = IupMessageDlg();
									IupSetAttributes( messageDlg, "DIALOGTYPE=ERROR" );
									IupSetAttribute( messageDlg, "VALUE", GLOBAL.languageItems["wrongext"].toCString );
									IupSetAttribute( messageDlg, "TITLE", GLOBAL.languageItems["error"].toCString );
									IupPopup( messageDlg, IUP_MOUSEPOS, IUP_MOUSEPOS );								
									return IUP_DEFAULT;
								}
						}
					}
					version(DIDE)
					{
						switch( lowerCase( fn.ext ) )
						{
							case "d":
								if( prjFilesFolderName != "Sources" )
								{
									Ihandle* messageDlg = IupMessageDlg();
									IupSetAttributes( messageDlg, "DIALOGTYPE=ERROR" );
									IupSetAttribute( messageDlg, "VALUE", GLOBAL.languageItems["wrongext"].toCString );
									IupSetAttribute( messageDlg, "TITLE", GLOBAL.languageItems["error"].toCString );
									IupPopup( messageDlg, IUP_MOUSEPOS, IUP_MOUSEPOS );								
									return IUP_DEFAULT;
								}
								else
								{
									GLOBAL.projectManager[prjDirName].sources ~= fullPath;
								}
								break;
							case "di":
								if( prjFilesFolderName != "Includes" )
								{
									Ihandle* messageDlg = IupMessageDlg();
									IupSetAttributes( messageDlg, "DIALOGTYPE=ERROR" );
									IupSetAttribute( messageDlg, "VALUE", GLOBAL.languageItems["wrongext"].toCString );
									IupSetAttribute( messageDlg, "TITLE", GLOBAL.languageItems["error"].toCString );
									IupPopup( messageDlg, IUP_MOUSEPOS, IUP_MOUSEPOS );								
									return IUP_DEFAULT;
								}
								else
								{
									GLOBAL.projectManager[prjDirName].includes ~= fullPath;
								}
								break;
							default:
								if( prjFilesFolderName == "Others" )
									GLOBAL.projectManager[prjDirName].others ~= fullPath; 
								else if( prjFilesFolderName == "Miscellaneous" )
									GLOBAL.projectManager[prjDirName].misc ~= fullPath;
								else
								{
									Ihandle* messageDlg = IupMessageDlg();
									IupSetAttributes( messageDlg, "DIALOGTYPE=ERROR" );
									IupSetAttribute( messageDlg, "VALUE", GLOBAL.languageItems["wrongext"].toCString );
									IupSetAttribute( messageDlg, "TITLE", GLOBAL.languageItems["error"].toCString );
									IupPopup( messageDlg, IUP_MOUSEPOS, IUP_MOUSEPOS );								
									return IUP_DEFAULT;
								}
						}
					}

					/*
					int	folderLocateId = actionManager.ProjectAction.addTreeNode( prjDirName ~ "/", fullPath, id );
					IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "ADDLEAF", folderLocateId, GLOBAL.cString.convert( fn.file ) );
					IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", folderLocateId+1, tools.getCString( fullPath ) );
					// shadow
					//IupSetAttributeId( GLOBAL.projectTree.getShadowTreeHandle, "ADDLEAF", id, GLOBAL.cString.convert( fullPath ) );
					*/
					char[]		titleName = Path.normalize( fullPath );
					int			folderLocateId = _createTree( prjDirName ~ "/", titleName, id );
					char[]		userData = fullPath;
					IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "ADDLEAF", folderLocateId, GLOBAL.cString.convert( titleName ) );
					IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "COLOR", folderLocateId + 1, GLOBAL.editColor.projectFore.toCString );
					IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", folderLocateId + 1, tools.getCString( userData ) );

					switch( prjFilesFolderName )
					{
						case "Sources":		IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "IMAGE", folderLocateId + 1, GLOBAL.cString.convert( "icon_bas" ) ); break;
						case "Includes":	IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "IMAGE", folderLocateId + 1, GLOBAL.cString.convert( "icon_bi" ) ); break;
						default:			IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "IMAGE", folderLocateId + 1, GLOBAL.cString.convert( "icon_txt" ) ); break;
					}

					//actionManager.ScintillaAction.openFile( fullPath.dup );
				}
			}
		}
		catch( Exception e )
		{
			IupMessage( "Exception", toStringz( e.toString ) );
		}
		
		return IUP_DEFAULT;
	}

	private int CProjectTree_Open_cb( Ihandle *ih )
	{
		int[] selectedIDs = actionManager.ProjectAction.getSelectIDs();
		
		if( selectedIDs.length > 0 )
		{
			foreach( int _i; selectedIDs )
			{
				if( fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "KIND", _i ) ) == "LEAF" )
				{
					char[] fullPath = fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", _i ) ).dup;
					scope fp = new FilePath( fullPath );
					
					if( fp.exists )
					{
						char[] ext = lowerCase( fp.ext );
						
						// Version Condition
						char[] _source_ = "bas", _include_ = "bi";
						version(DIDE)
						{
							_source_	= "d";
							_include_	= "di";
						}					

						if( ext == _include_ || ext == _source_ )
						{
							if( selectedIDs.length == 1 )
							{
								actionManager.ScintillaAction.openFile( fullPath );
								break;
							}
							else
								actionManager.ScintillaAction.openFile( fullPath );
						}
						else
						{
							try
							{
								version(Windows)
								{
									Process p = new Process( true, "cmd", "/c", fullPath );
									p.gui( true );
									p.execute;
								}
								else
								{
									Process p = new Process( true, "xdg-open", fullPath );
									p.gui( true );
									p.execute;
								}
							}
							catch( Exception e )
							{
								break;
							}
						}
					}
					else
					{
						IupMessageError( null, toStringz( fullPath ~ "\n" ~ GLOBAL.languageItems["filelost"].toDString() ) );
						break;
					}
				}
			}
			
			int id = IupGetInt( GLOBAL.projectTree.getTreeHandle, "VALUE" );
			// Erase Project Treeitems And Left Only One Item
			IupSetAttribute( GLOBAL.projectTree.getTreeHandle, "MARK", "CLEARALL" );
			IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "MARKED", id, "YES" );
		}
		
		return IUP_DEFAULT;
	}

	private int CProjectTree_Openin_cb( Ihandle *ih )
	{
		int[] selectedIDs = actionManager.ProjectAction.getSelectIDs();
		
		if( selectedIDs.length > 0 )
		{
			foreach( int _i; selectedIDs )
			{
				if( fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "KIND", _i ) ) == "LEAF" )
				{
					char[] fullPath = fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", _i ) ).dup;
					scope fp = new FilePath( fullPath );
					
					if( fp.exists )
					{
						if( selectedIDs.length == 1 )
							actionManager.ScintillaAction.openFile( fullPath.dup, -1 );
						else
							actionManager.ScintillaAction.openFile( fullPath.dup );
					}
					else
					{
						IupMessageError( null, toStringz( fullPath ~ "\n" ~ GLOBAL.languageItems["filelost"].toDString() ) );
					}
				}
			}
			
			int id = IupGetInt( GLOBAL.projectTree.getTreeHandle, "VALUE" );
			// Erase Project Treeitems And Left Only One Item
			IupSetAttribute( GLOBAL.projectTree.getTreeHandle, "MARK", "CLEARALL" );
			IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "MARKED", id, "YES" );
		}
		
		return IUP_DEFAULT;
	}

	private int CProjectTree_remove_cb( Ihandle* ih )
	{
		int[] selectedIDs = actionManager.ProjectAction.getSelectIDs();
		
		if( selectedIDs.length > 0 )
		{
			foreach_reverse( int id; selectedIDs )
			{			
		
				// Get Focus Tree Node ID
				//int		id					= IupGetInt( GLOBAL.projectTree.getTreeHandle, "VALUE" );
				IupSetInt( GLOBAL.projectTree.getTreeHandle, "VALUE", id );
				
				char[]	fullPath			= fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id ) ).dup;
				int		typeID				= actionManager.ProjectAction.getTargetDepthID( 2 );
				char[]	prjFilesFolderName	= fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "TITLE", typeID ) ).dup; // = Sources or Includes or Others or Miscellaneous

				if( actionManager.ScintillaAction.closeDocument( fullPath ) == IUP_IGNORE ) return IUP_IGNORE;

				switch( prjFilesFolderName )
				{
					case "Sources":
						char[][] temp;
						foreach( char[] s; GLOBAL.projectManager[actionManager.ProjectAction.getActiveProjectName].sources )
							if( s != fullPath ) temp ~= s;
						GLOBAL.projectManager[actionManager.ProjectAction.getActiveProjectName].sources = temp;
						break;
						
					case "Includes":
						char[][] temp;
						foreach( char[] s; GLOBAL.projectManager[actionManager.ProjectAction.getActiveProjectName].includes )
							if( s != fullPath ) temp ~= s;
						GLOBAL.projectManager[actionManager.ProjectAction.getActiveProjectName].includes = temp;
						break;
						
					case "Others":
						char[][] temp;
						foreach( char[] s; GLOBAL.projectManager[actionManager.ProjectAction.getActiveProjectName].others )
							if( s != fullPath ) temp ~= s;
						GLOBAL.projectManager[actionManager.ProjectAction.getActiveProjectName].others = temp;
						break;

					case "Miscellaneous":
						char[][] temp;
						foreach( char[] s; GLOBAL.projectManager[actionManager.ProjectAction.getActiveProjectName].misc )
							if( s != fullPath ) temp ~= s;
						GLOBAL.projectManager[actionManager.ProjectAction.getActiveProjectName].misc = temp;
						break;
				}		

				char* user = IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id );
				if( user != null ) delete user;
				int parentID = IupGetIntId( GLOBAL.projectTree.getTreeHandle, "PARENT", id );
				IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "DELNODE", id, "SELECTED" );

				// Del empty folder( branch )
				while( IupGetIntId( GLOBAL.projectTree.getTreeHandle, "DEPTH", parentID ) > 2 )
				{
					if( IupGetIntId( GLOBAL.projectTree.getTreeHandle, "CHILDCOUNT", parentID ) < 1 )
					{
						int beDelParentID = parentID;
						parentID = IupGetIntId( GLOBAL.projectTree.getTreeHandle, "PARENT", beDelParentID );
						IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "DELNODE", beDelParentID, "SELECTED" );
					}
					else
					{
						break;
					}
				}
			}
		}
		
		return IUP_DEFAULT;
	}

	private int CProjectTree_delete_cb( Ihandle* ih )
	{
		int		id					= IupGetInt( GLOBAL.projectTree.getTreeHandle, "VALUE" );
		char[]	fullPath			= fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id ) ).dup;

		// Erase Project Treeitems And Left Only One Item
		IupSetAttribute( GLOBAL.projectTree.getTreeHandle, "MARK", "CLEARALL" );
		IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "MARKED", id, "YES" );


		Ihandle* messageDlg = IupMessageDlg();
		IupSetAttributes( messageDlg, "DIALOGTYPE=WARNING,BUTTONS=OKCANCEL" );
		IupSetAttribute( messageDlg, "VALUE", GLOBAL.languageItems["suredelete"].toCString );
		IupSetAttribute( messageDlg, "TITLE", GLOBAL.languageItems["alarm"].toCString );
		IupPopup( messageDlg, IUP_MOUSEPOS, IUP_MOUSEPOS );

		if( IupGetInt( messageDlg, "BUTTONRESPONSE" ) == 1 )
		{
			if( fullPath.length )
			{
				if( CProjectTree_remove_cb( ih ) == IUP_IGNORE ) return IUP_IGNORE;

				scope f = new FilePath( fullPath );
				f.remove();
			}
		}

		return IUP_DEFAULT;
	}

	private int CProjectTree_rename_cb( Ihandle* ih )
	{
		int		id			= IupGetInt( GLOBAL.projectTree.getTreeHandle, "VALUE" );
		char[]	fullPath	= fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id ) ).dup;
		
		// Erase Project Treeitems And Left Only One Item
		IupSetAttribute( GLOBAL.projectTree.getTreeHandle, "MARK", "CLEARALL" );
		IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "MARKED", id, "YES" );		

		scope fp = new FilePath( fullPath );

		char[] oldExt = fp.ext().dup;

		scope test = new CSingleTextDialog( -1, -1, GLOBAL.languageItems["rename"].toDString(), GLOBAL.languageItems["filename"].toDString() ~":", "120x", fp.name(), false );
		char[] newFileName = test.show( IUP_MOUSEPOS, IUP_MOUSEPOS );

		if( newFileName.length )
		{
			// Save Old File Changed
			if( fullPathByOS(fullPath) in GLOBAL.scintillaManager ) GLOBAL.scintillaManager[fullPathByOS(fullPath)].saveFile();
			
			// ReName On Disk & Change fn
			fp.rename( fp.path ~ newFileName ~ fp.suffix );

			if( fullPathByOS(fullPath) in GLOBAL.scintillaManager ) 
			{
				GLOBAL.scintillaManager[fullPathByOS(fullPath)].rename( fp.toString );
			}

			
			char* pointer = IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id );
			if( pointer != null ) freeCString( pointer );
			
			IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id, tools.getCString( fp.toString ) );
			IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "TITLE", id, GLOBAL.cString.convert( fp.file ) );

			char[]	activeProjectDirName = actionManager.ProjectAction.getActiveProjectName;
			int		typeID				= actionManager.ProjectAction.getTargetDepthID( 2 );
			char[]	prjFilesFolderName	= fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "TITLE", typeID ) ).dup; // = Sources or Includes or Others or Miscellaneous
			
			switch( prjFilesFolderName )
			{
				case "Sources":
					char[][] tempSources = GLOBAL.projectManager[activeProjectDirName].sources;
					GLOBAL.projectManager[activeProjectDirName].sources.length = 0;
					foreach( char[] s; tempSources )
					{
						if( s != fullPath ) GLOBAL.projectManager[activeProjectDirName].sources ~= s;else GLOBAL.projectManager[activeProjectDirName].sources ~= fp.toString;
					}
					break;
					
				case "Includes":
					char[][] tempIncludes = GLOBAL.projectManager[activeProjectDirName].includes;
					GLOBAL.projectManager[activeProjectDirName].includes.length = 0;
					foreach( char[] s; tempIncludes )
					{
						if( s != fullPath ) GLOBAL.projectManager[activeProjectDirName].includes ~= s;else GLOBAL.projectManager[activeProjectDirName].includes ~= fp.toString;
					}
					break;
					
				case "Others":
					char[][] tempOthers = GLOBAL.projectManager[activeProjectDirName].others;
					GLOBAL.projectManager[activeProjectDirName].others.length = 0;
					foreach( char[] s; tempOthers )
					{
						if( s != fullPath ) GLOBAL.projectManager[activeProjectDirName].others ~= s;else GLOBAL.projectManager[activeProjectDirName].others ~= fp.toString;
					}
					break;

				case "Miscellaneous":
					char[][] tempMisc = GLOBAL.projectManager[activeProjectDirName].misc;
					GLOBAL.projectManager[activeProjectDirName].misc.length = 0;
					foreach( char[] s; tempMisc )
					{
						if( s != fullPath ) GLOBAL.projectManager[activeProjectDirName].misc ~= s;else GLOBAL.projectManager[activeProjectDirName].misc ~= fp.toString;
					}
					break;
				default:
			}				
			
			/+
			version(FBIDE)
			{
				switch( lowerCase( oldExt ) )
				{
					case "bas":
						char[][] tempSources = GLOBAL.projectManager[activeProjectDirName].sources;
						GLOBAL.projectManager[activeProjectDirName].sources.length = 0;
						foreach( char[] s; tempSources )
						{
							if( s != fullPath ) GLOBAL.projectManager[activeProjectDirName].sources ~= s;else GLOBAL.projectManager[activeProjectDirName].sources ~= fp.toString;
						}
						
						break;

					case "bi":
						char[][] tempIncludes = GLOBAL.projectManager[activeProjectDirName].includes;
						GLOBAL.projectManager[activeProjectDirName].includes.length = 0;
						foreach( char[] s; tempIncludes )
						{
							if( s != fullPath ) GLOBAL.projectManager[activeProjectDirName].includes ~= s;else GLOBAL.projectManager[activeProjectDirName].includes ~= fp.toString;
						}
						break;
					default:
						char[][] tempOthers = GLOBAL.projectManager[activeProjectDirName].others;
						GLOBAL.projectManager[activeProjectDirName].others.length = 0;
						foreach( char[] s; tempOthers )
						{
							if( s != fullPath ) GLOBAL.projectManager[activeProjectDirName].others ~= s;else GLOBAL.projectManager[activeProjectDirName].others ~= fp.toString;
						}
				}
			}
			version(DIDE)
			{
				switch( lowerCase( oldExt ) )
				{
					case "d":
						char[][] tempSources = GLOBAL.projectManager[activeProjectDirName].sources;
						GLOBAL.projectManager[activeProjectDirName].sources.length = 0;
						foreach( char[] s; tempSources )
						{
							if( s != fullPath ) GLOBAL.projectManager[activeProjectDirName].sources ~= s;else GLOBAL.projectManager[activeProjectDirName].sources ~= fp.toString;
						}
						
						break;

					case "di":
						char[][] tempIncludes = GLOBAL.projectManager[activeProjectDirName].includes;
						GLOBAL.projectManager[activeProjectDirName].includes.length = 0;
						foreach( char[] s; tempIncludes )
						{
							if( s != fullPath ) GLOBAL.projectManager[activeProjectDirName].includes ~= s;else GLOBAL.projectManager[activeProjectDirName].includes ~= fp.toString;
						}
						break;
					default:
						char[][] tempOthers = GLOBAL.projectManager[activeProjectDirName].others;
						GLOBAL.projectManager[activeProjectDirName].others.length = 0;
						foreach( char[] s; tempOthers )
						{
							if( s != fullPath ) GLOBAL.projectManager[activeProjectDirName].others ~= s;else GLOBAL.projectManager[activeProjectDirName].others ~= fp.toString;
						}
				}
			}
			+/
		}
		
		return IUP_DEFAULT;
	}
	
	private int CProjectTree_setmainmodule_cb( Ihandle* ih )
	{
		int		id			= IupGetInt( GLOBAL.projectTree.getTreeHandle, "VALUE" );
		char[]	fullPath	= fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id ) ).dup;
		
		// Erase Project Treeitems And Left Only One Item
		IupSetAttribute( GLOBAL.projectTree.getTreeHandle, "MARK", "CLEARALL" );
		IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "MARKED", id, "YES" );
		
		scope fp = new FilePath( fullPath );
		char[] _prjName = ProjectAction.getActiveProjectName;
		if( _prjName in GLOBAL.projectManager )
		{
			char[] _mainModule = fp.path ~ fp.name;
			GLOBAL.projectManager[_prjName].mainFile = Util.substitute( _mainModule, GLOBAL.projectManager[_prjName].dir ~ "/", "" );
		}

		return IUP_DEFAULT;
	}
	
	private int CProjectTree_importall_cb( Ihandle* ih )
	{
		// Nested Delegate Filter Function
		bool dirFilter( FilePath _fp, bool _isFfolder )
		{
			if( _isFfolder ) return true;
			version(FBIDE)	if( lowerCase( _fp.ext ) == "bas" || lowerCase( _fp.ext ) == "bi" ) return true;
			version(DIDE)	if( lowerCase( _fp.ext ) == "d" || lowerCase( _fp.ext ) == "di" ) return true;
			return false;
		}
		
		bool delegate( FilePath, bool ) _dirFilter;
		_dirFilter = &dirFilter;
		// End of Nested Function
		
		char[][] _getFiles( FilePath _fatherPath, char[] ext )
		{
			char[][]	results;
			FilePath[]	files;
			
			foreach( FilePath _fp; _fatherPath.toList( _dirFilter ) )
			{
				if( _fp.isFolder )
				{
					results ~= _getFiles( _fp, ext );
				}
				else
				{
					if( lowerCase( _fp.ext ) == ext ) files ~= _fp;
				}
			}
			
			foreach( _fp; files )
				results ~= _fp.toString;
				
			return results;
		}
		
		
	
	
		int		id			= IupGetInt( GLOBAL.projectTree.getTreeHandle, "VALUE" );
		char[]	prjDirName	= fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id ) );
		int		sourceID	= id + 1;
		int		includesID	= IupGetIntId( GLOBAL.projectTree.getTreeHandle, "NEXT", sourceID );
		
		scope prjPath = new FilePath( prjDirName );
		if( prjPath.isFolder )
		{
			GLOBAL.projectManager[prjDirName].includes.length = 0;
			IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "DELNODE", includesID, "CHILDREN" );
			
			char[] _ext;
			version(FBIDE) _ext = "bi";	version(DIDE) _ext = "di";
			
			foreach_reverse( char[] s; _getFiles( prjPath, _ext ) )
			{
				GLOBAL.projectManager[prjDirName].includes ~= s;
			
				char[]		titleName = Path.normalize( s );
				int			folderLocateId = _createTree( prjDirName ~ "/", titleName, includesID );
				char[]		userData = s;
				IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "ADDLEAF", folderLocateId, GLOBAL.cString.convert( titleName ) );
				IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "COLOR", folderLocateId + 1, GLOBAL.editColor.projectFore.toCString );
				IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", folderLocateId + 1, tools.getCString( userData ) );
				
				IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "IMAGE", folderLocateId + 1, GLOBAL.cString.convert( "icon_bi" ) );
			}
			
			GLOBAL.projectManager[prjDirName].sources.length = 0;
			IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "DELNODE", sourceID, "CHILDREN" );
			version(FBIDE) _ext = "bas"; version(DIDE) _ext = "d";
			
			foreach_reverse( char[] s; _getFiles( prjPath, _ext ) )
			{
				GLOBAL.projectManager[prjDirName].sources ~= s;
			
				char[]		titleName = Path.normalize( s );
				int			folderLocateId = _createTree( prjDirName ~ "/", titleName, sourceID );
				char[]		userData = s;
				IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "ADDLEAF", folderLocateId, GLOBAL.cString.convert( titleName ) );
				IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "COLOR", folderLocateId + 1, GLOBAL.editColor.projectFore.toCString );
				IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", folderLocateId + 1, tools.getCString( userData ) );
				
				IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "IMAGE", folderLocateId + 1, GLOBAL.cString.convert( "icon_bas" ) );
			}			
		}

		return IUP_DEFAULT;
	}	

	private int _createTree( char[] _prjDirName, ref char[] _titleName, int startID = 2 )
	{
		int		pos;
		int		folderLocateId = startID;
		char[]	fullPath = Path.normalize( _titleName );

		version(Windows)
		{
			pos = Util.index( lowerCase( fullPath ), lowerCase( _prjDirName ) );
			if( pos == 0 ) _titleName = fullPath[_prjDirName.length..$].dup;
		}
		else
		{
			pos = Util.index( fullPath, _prjDirName );
			if( pos == 0 )  _titleName = fullPath[_prjDirName.length..$].dup; //_titleName = Util.substitute( fullPath, _prjDirName, "" );
		}

		// Check the child Folder
		char[][]	splitText = Util.split( _titleName, "/" );
	
		int counterSplitText;
		for( counterSplitText = 0; counterSplitText < splitText.length - 1; ++counterSplitText )
		{
			if( splitText[counterSplitText].length )
			{
				int 	countChild = IupGetIntId( GLOBAL.projectTree.getTreeHandle, "TOTALCHILDCOUNT", folderLocateId );
				bool	bFolerExist = false;
				for( int i = 1; i <= countChild; ++ i )
				{
					char[]	kind = fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "KIND", folderLocateId + i ) );
					if( kind == "BRANCH" )
					{
						if( splitText[counterSplitText] == fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "TITLE", folderLocateId + i ) ) )
						{
							folderLocateId = folderLocateId+i;
							bFolerExist = true;
							break;
						}
					}
				}
				if( !bFolerExist )
				{
					IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "ADDBRANCH", folderLocateId, GLOBAL.cString.convert( splitText[counterSplitText] ) );
					IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "COLOR", folderLocateId + 1, GLOBAL.editColor.projectFore.toCString );
					if( pos != 0 )
						IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", folderLocateId+1, tools.getCString( "FIXED" ) );
					else
						IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", folderLocateId+1, tools.getCString( splitText[counterSplitText] ) );
					
					folderLocateId ++;
				}
			}
		}

		if( splitText.length > 1 ) _titleName = splitText[$-1];

		return folderLocateId;
	}		
}