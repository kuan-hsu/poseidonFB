module layouts.projectPanel;


private import iup.iup;

private import global, scintilla, actionManager, menu, tools;
private import dialogs.singleTextDlg, dialogs.fileDlg;

private import tango.stdc.stringz, tango.sys.Process;
private import tango.io.FilePath, Util = tango.text.Util, Integer = tango.text.convert.Integer;

class CProjectTree
{
	private:
	import				project, tango.io.device.File, tango.io.stream.Lines;
	import				tango.core.Thread, parser.autocompletion;
	
	CstringConvert[2]	cStrings;
	/+
	// Inner Class
	class ParseThread : Thread
	{
		private:

		PROJECT 	p;

		public:
		this( PROJECT _p )
		{
			p = _p;
			super( &run );
		}

		void run()
		{
			foreach( char[] s; p.sources ~ p.includes )
			{
				auto _parserTree = GLOBAL.outlineTree.loadFile( s );
				auto _parsers = AutoComplete.getIncludes( _parserTree, s, true );
				/*
				IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( s ) );
				foreach( _p; _parsers )
					IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( "\t" ~ _p.name ) );
				*/
			}
		}
	}
	+/
	
	Ihandle*	layoutHandle, tree;

	void createLayout()
	{
		cStrings[0] = new CstringConvert( GLOBAL.languageItems["collapse"] );
		cStrings[1] = new CstringConvert( GLOBAL.languageItems["hide"] );
		
		// Outline Toolbar
		Ihandle* projectButtonCollapse = IupButton( null, null );
		IupSetAttributes( projectButtonCollapse, "ALIGNMENT=ARIGHT:ACENTER,FLAT=YES,IMAGE=icon_collapse" );
		IupSetAttribute( projectButtonCollapse, "TIP", cStrings[0].toStringz );
		IupSetCallback( projectButtonCollapse, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			Ihandle* tree = GLOBAL.projectTree.getTreeHandle();
			if( tree != null )
				{
					
					if( fromStringz( IupGetAttributeId( tree, "STATE", 0 ) ) == "EXPANDED" )
						IupSetAttribute( tree, "EXPANDALL", "NO" );
					else
					{
						IupSetAttribute( tree, "EXPANDALL", "YES" );
						IupSetAttribute( tree, "TOPITEM", "YES" ); // Set position to top
					}
				}
			
		});

		Ihandle* projectButtonHide = IupButton( null, null );
		IupSetAttributes( projectButtonHide, "ALIGNMENT=ARIGHT:ACENTER,FLAT=YES,IMAGE=icon_shift_l" );
		IupSetAttribute( projectButtonHide, "TIP", cStrings[1].toStringz );
		IupSetCallback( projectButtonHide, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			menu.outlineMenuItem_cb( GLOBAL.menuOutlineWindow );
		});

		Ihandle* projectToolbarTitleImage = IupLabel( null );
		IupSetAttributes( projectToolbarTitleImage, "IMAGE=icon_packageexplorer,ALIGNMENT=ACENTER:ALEFT" );

		/*Ihandle* projectToolbarTitle = IupLabel( " Project" );
		IupSetAttribute( projectToolbarTitle, "ALIGNMENT", "ACENTER:ALEFT" );*/

		Ihandle* projectToolbarH = IupHbox( projectToolbarTitleImage, /*projectToolbarTitle,*/ IupFill, projectButtonCollapse, projectButtonHide, null );
		IupSetAttributes( projectToolbarH, "ALIGNMENT=ACENTER,SIZE=NULL" );

		tree = IupTree();
		IupSetAttributes( tree, "ADDROOT=YES,EXPAND=YES,TITLE=Projects,SIZE=NULL" );
		toBoldTitle( tree, 0 );
		IupSetCallback( tree, "RIGHTCLICK_CB", cast(Icallback) &CProjectTree_RightClick_cb );
		IupSetCallback( tree, "SELECTION_CB", cast(Icallback) &CProjectTree_Selection_cb );
		IupSetCallback( tree, "EXECUTELEAF_CB", cast(Icallback) &CProjectTree_ExecuteLeaf_cb );
		IupSetCallback( tree, "NODEREMOVED_CB", cast(Icallback) &CProjectTree_NodeRemoved_cb );
		
		layoutHandle = IupVbox( projectToolbarH, tree, null );
		IupSetAttributes( layoutHandle, GLOBAL.cString.convert( "ALIGNMENT=ARIGHT,GAP=2" ) );
	}

	void toBoldTitle( Ihandle* _tree, int id )
	{
		int commaPos = Util.index( GLOBAL.fonts[4].fontString, "," );
		if( commaPos < GLOBAL.fonts[4].fontString.length )
		{
			char[] fontString = Util.substitute( GLOBAL.fonts[4].fontString.dup, ",", ",Bold " );
			IupSetAttributeId( _tree, "TITLEFONT", id, toStringz( fontString ) );
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
		IupSetAttributeId( tree, "COLOR", 1, toStringz( "128 0 0" ) );
		toBoldTitle( tree, 1 );

	
		IupSetAttribute( tree, "ADDBRANCH1", "Others" );
		IupSetAttributeId( tree, "COLOR", 2, toStringz( "0 0 255" ) );
		IupSetAttribute( tree, "IMAGE2", GLOBAL.cString.convert( "icon_door" ) );
		IupSetAttribute( tree, "IMAGEEXPANDED2", GLOBAL.cString.convert( "icon_dooropen" ) );
		toBoldTitle( tree, 2 );

		foreach( char[] s; GLOBAL.projectManager[setupDir].others )
		{
			char[]		userData = s;
			int			folderLocateId = _createTree( prjDirName, s );
			
			IupSetAttributeId( tree, "ADDLEAF", folderLocateId, GLOBAL.cString.convert( s ) );
			IupSetAttributeId( tree, "IMAGE", folderLocateId + 1, GLOBAL.cString.convert( "icon_txt" ) );
			IupSetAttributeId( tree, "USERDATA", folderLocateId + 1, tools.getCString( userData ) );
		}
		
		IupSetAttribute( tree, "ADDBRANCH1", "Includes" );
		IupSetAttributeId( tree, "COLOR", 2, toStringz( "0 0 255" ) );
		IupSetAttribute( tree, "IMAGE2", GLOBAL.cString.convert( "icon_door" ) );
		IupSetAttribute( tree, "IMAGEEXPANDED2", GLOBAL.cString.convert( "icon_dooropen" ) );
		toBoldTitle( tree, 2 );
		
		foreach( char[] s; GLOBAL.projectManager[setupDir].includes )
		{
			char[]		userData = s;
			int			folderLocateId = _createTree( prjDirName, s );
			
			IupSetAttributeId( tree, "ADDLEAF", folderLocateId, GLOBAL.cString.convert( s ) );
			IupSetAttributeId( tree, "IMAGE", folderLocateId + 1, GLOBAL.cString.convert( "icon_bi" ) );
			IupSetAttributeId( tree, "USERDATA", folderLocateId + 1, tools.getCString( userData ) );
		}

		IupSetAttribute( tree, "ADDBRANCH1", "Sources" );
		IupSetAttributeId( tree, "COLOR", 2, toStringz( "0 0 255" ) );
		toBoldTitle( tree, 2 );
		IupSetAttribute( tree, "IMAGE2", GLOBAL.cString.convert( "icon_door" ) );
		IupSetAttribute( tree, "IMAGEEXPANDED2", GLOBAL.cString.convert( "icon_dooropen" ) );
		
		
		foreach( char[] s; GLOBAL.projectManager[setupDir].sources )
		{
			char[]		userData = s;
			int			folderLocateId = _createTree( prjDirName, s );
			
			IupSetAttributeId( tree, "ADDLEAF", folderLocateId, GLOBAL.cString.convert( s ) );
			IupSetAttributeId( tree, "IMAGE", folderLocateId + 1, GLOBAL.cString.convert( "icon_bas" ) );
			IupSetAttributeId( tree, "USERDATA", folderLocateId + 1, tools.getCString( userData ) );
		}

		// Switch to project tree tab
		IupSetAttribute( GLOBAL.projectViewTabs, "VALUEPOS", "0" );
		//IupSetAttribute( GLOBAL.projectViewTabs, "VALUE_HANDLE", cast(char*) GLOBAL.projectTree.getTreeHandle );
		// Set Focus to Project Tree
		version(Windows) IupSetAttributeId( tree, "MARKED", 1, "YES" ); else IupSetInt( tree, "VALUE", 1 );

		// Recent Projects
		GLOBAL.projectTree.updateRecentProjects( setupDir, GLOBAL.projectManager[setupDir].name );

		IupSetAttribute( GLOBAL.mainDlg, "TITLE", toStringz( GLOBAL.projectManager[setupDir].name ~ " - poseidonFB - FreeBasic IDE" ) );
		
		//IupSetInt( GLOBAL.fileListSplit, "VALUE", IupGetInt( GLOBAL.fileListSplit, "VALUE" ) + 12 );
	}

	void CreateNewProject( char[] prjName, char[] prjDir )
	{
		//GLOBAL.activeProjectDirName = prjDir;

		IupSetAttribute( tree, "ADDBRANCH0", GLOBAL.cString.convert( prjName ) );
		version(Windows) IupSetAttributeId( tree, "MARKED", 1, "YES" ); else IupSetInt( tree, "VALUE", 1 );
		IupSetAttribute( tree, "USERDATA1", tools.getCString( prjDir ) );
		IupSetAttributeId( tree, "COLOR", 1, toStringz( "128 0 0" ) );
		toBoldTitle( tree, 1 );

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
		IupSetAttribute( GLOBAL.projectViewTabs, "VALUE_HANDLE", cast(char*) GLOBAL.projectTree.getTreeHandle );
	}

	bool openProject( char[] setupDir = null )
	{
		if( !setupDir.length )
		{
			scope fileSelectDlg = new CFileDlg( GLOBAL.languageItems["openprj"], null, "DIR" );
			setupDir = fileSelectDlg.getFileName();
		}

		if( !setupDir.length ) return false;

		setupDir = Util.replace( setupDir, '\\', '/' );

		if( setupDir in GLOBAL.projectManager )
		{
			IupMessage( "Alarm!", GLOBAL.cString.convert( "\"" ~ setupDir ~ "\"\nhas already opened!" ) );
			return true;
		}

		if( GLOBAL.editorSetting00.Message == "ON" ) IupSetAttribute( GLOBAL.outputPanel, "VALUE", toStringz( "Load Project: [" ~ setupDir ~ "]" ) );
		
		char[] setupFileName = setupDir ~ "/.poseidon";

		scope sFN = new FilePath( setupFileName );

		if( sFN.exists() )
		{
			PROJECT		p;
			GLOBAL.projectManager[setupDir] = p.loadFile( setupFileName );

			if( !GLOBAL.projectManager[setupDir].dir.length )
			{
				GLOBAL.projectManager.remove( setupDir );
				IupMessage( "ERROR", GLOBAL.cString.convert( "Project setup file loading error!!\nXml format may be broken!!" ) );
				return false;
			}

			createProjectTree( setupDir );
		}
		else
		{
			IupMessage( "Error!", GLOBAL.cString.convert( "\"" ~ setupDir ~ "\"\nhas lost setting xml file!" ) );
			return false;
		}

		/+
		// Pre-Load Parser
		ParseThread subThread = new ParseThread( GLOBAL.projectManager[setupDir] );
		subThread.start();
		+/

		if( GLOBAL.editorSetting00.Message == "ON" ) IupSetAttribute( GLOBAL.outputPanel, "APPEND", toStringz( "Done."  ) );

		return true;
	}

	bool importFbEditProject()
	{
		scope fileSelectDlg = new CFileDlg( GLOBAL.languageItems["importprj"],  GLOBAL.languageItems["fbeditfile"] ~ "|*.fbp|" ~ GLOBAL.languageItems["allfile"] ~ "|All Files|*.*" );
		char[] fbpFullPath = fileSelectDlg.getFileName();

		if( !fbpFullPath.length ) return false;

		scope sFN = new FilePath( fbpFullPath );
		char[] _dir = sFN.path(); // include tail /

		if( _dir.length )
			if( _dir[length-1] == '/' ) _dir = _dir[0..length-1].dup;

		if( _dir in GLOBAL.projectManager )
		{
			IupMessage( "Alarm!", GLOBAL.cString.convert( "\"" ~ _dir ~ "\"\nhas already opened!" ) );
			return false;
		}

		scope poseidonFN = new FilePath( sFN.path ~ ".poseidon" );

		if( poseidonFN.exists() )
		{
			Ihandle* messageDlg = IupMessageDlg();
			IupSetAttributes( messageDlg, "DIALOGTYPE=WARNING,TITLE=WARNING,BUTTONDEFAULT=2,BUTTONS=YESNO" );
			IupSetAttribute( messageDlg, "VALUE", toStringz( "The Dir has poseidonFB Project File,\nContinue Import Anyway?" ) );
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
								char[]	_value = _lineData[assignPos+1..length];
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
								char[]	_value = _lineData[assignPos+1..length];

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
								char[]	_value = _lineData[assignPos+1..length];

								if( _keyWord == "Main" )
								{
									if( fileArrays.length )	prj.mainFile = fileArrays[_value];
									break;
								}
				
								fileArrays[_keyWord] = _value;

								scope _fp = new FilePath( Util.replace( _value, '\\', '/' ) );
								if( lowerCase( _fp.ext ) == "bas" )
								{
									if( !_fp.isAbsolute ) prj.sources ~= ( prj.dir ~ "/" ~ _value ); else prj.sources ~= _value;
								}
								else if( lowerCase( _fp.ext ) == "bi" )
								{
									if( !_fp.isAbsolute ) prj.includes ~= ( prj.dir ~ "/" ~ _value ); else prj.includes ~= _value;
								}
								else
								{
									if( !_fp.isAbsolute ) prj.others ~= ( prj.dir ~ "/" ~ _value ); else prj.others ~= _value;
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
					option = option[posComma+1..length];
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

	void updateRecentProjects( char[] prjDir, char[] prjName )
	{
		char[] title;
		
		if( prjDir.length )
		{
			char[][]	temps;
			title = prjDir ~ " : " ~ prjName;
			
			for( int i = 0; i < GLOBAL.recentProjects.length; ++ i )
			{
				if( GLOBAL.recentProjects[i] != title )	temps ~= GLOBAL.recentProjects[i];
			}

			temps ~= title;
			GLOBAL.recentProjects.length = 0;
			GLOBAL.recentProjects = temps;
		}
		
		// Recent Projects
		if( GLOBAL.recentProjects.length > 8 )
		{
			GLOBAL.recentProjects[0..8] = GLOBAL.recentProjects[length-8..length].dup;
			GLOBAL.recentProjects.length = 8;
		}

		Ihandle* recentPrj_ih = IupGetHandle( "recentPrjsSubMenu" );
		if( recentPrj_ih != null )
		{
			// Clear All iupItem......
			for( int i = IupGetChildCount( recentPrj_ih ) - 1; i >= 0; -- i )
			{
				IupDestroy( IupGetChild( recentPrj_ih, i ) );
			}

			Ihandle* _clearRecentPrjs = IupItem( toStringz( GLOBAL.languageItems["clearall"] ), null );
			IupSetAttribute(_clearRecentPrjs, "IMAGE", "icon_clearall");
			IupSetCallback( _clearRecentPrjs, "ACTION", cast(Icallback) &menu.submenuRecentPrjsClear_click_cb );
			IupInsert( recentPrj_ih, null, _clearRecentPrjs );
			IupMap( IupGetChild( recentPrj_ih, 0 ) );
			IupInsert( recentPrj_ih, null, IupSeparator() );
			IupMap( IupGetChild( recentPrj_ih, 0 ) );
	
			// Create New iupItem
			for( int i = 0; i < GLOBAL.recentProjects.length; ++ i )
			{
				Ihandle* _new = IupItem( GLOBAL.cString.convert( GLOBAL.recentProjects[i] ), null );
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
			// Swith the doument tabs by select Tree Node, if the doument isn't exist, do nothing
			if( fromStringz( IupGetAttribute( ih, "KIND" ) ) == "LEAF" )
			{
				char[] fullPath = fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id ) );
				
				if( upperCase(fullPath) in GLOBAL.scintillaManager ) 
				{
					actionManager.ScintillaAction.openFile( fullPath.dup );
				}				
			}

			if( id > 0 )
			{
				int prjID = actionManager.ProjectAction.getActiveProjectID();
				char[] _prjName = fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "TITLE", prjID ) ).dup;
				IupSetAttribute( GLOBAL.mainDlg, "TITLE", toStringz( _prjName ~ " - poseidonFB - FreeBasic IDE" ) );
			}
			else
			{
				IupSetAttribute( GLOBAL.mainDlg, "TITLE", "poseidonFB - FreeBasic IDE" );
			}
		}

		return IUP_DEFAULT;
	}

	// Leaf Node has been Double-Click
	private int CProjectTree_ExecuteLeaf_cb( Ihandle *ih, int id )
	{
		char[] fullPath = fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id ) );

		scope fp = new FilePath( fullPath );
		char[] ext = lowerCase( fp.ext );

		if( ext == "bas" || ext == "bi" )
		{
			actionManager.ScintillaAction.openFile( fullPath.dup );
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
			catch{}
		}

		return IUP_DEFAULT;
	}

	private int CProjectTree_NodeRemoved_cb( Ihandle *ih, void* userdata )
	{
		char* dataPointer = cast(char*) userdata;
		tools.freeCString( dataPointer );

		return IUP_DEFAULT;
	}

	// 
	private int CProjectTree_RightClick_cb( Ihandle *ih, int id )
	{
		version(Windows) IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "MARKED", id, "YES" ); else IupSetInt( GLOBAL.projectTree.getTreeHandle, "VALUE", id );

		char[] nodeKind = fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "KIND", id ) );

		if( nodeKind == "LEAF" ) // On File(*.bas, *.bi) Node
		{
			Ihandle* popupMenu = IupMenu( 
										IupItem( toStringz( GLOBAL.languageItems["open"] ), "CProjectTree_open" ),
										IupItem( toStringz( GLOBAL.languageItems["removefromprj"] ), "CProjectTree_remove" ),
										IupSeparator(),
										IupItem( toStringz( GLOBAL.languageItems["delete"] ), "CProjectTree_delete" ),
										IupItem( toStringz( GLOBAL.languageItems["rename"] ), "CProjectTree_rename" ),
										null
									);

			IupSetFunction( "CProjectTree_open", cast(Icallback) &CProjectTree_Open_cb );
			IupSetFunction( "CProjectTree_remove", cast(Icallback) &CProjectTree_remove_cb );
			IupSetFunction( "CProjectTree_delete", cast(Icallback) &CProjectTree_delete_cb );
			IupSetFunction( "CProjectTree_rename", cast(Icallback) &CProjectTree_rename_cb );

			IupPopup( popupMenu, IUP_MOUSEPOS, IUP_MOUSEPOS );
			IupDestroy( popupMenu );

			return IUP_DEFAULT;
		}

		
		//IupMessage( "USERDATA", IupGetAttribute( GLOBAL.projectTree.getTreeHandle,  ("USERDATA" ~ Integer.toString( id )).ptr ) );
		int depth = IupGetIntId( GLOBAL.projectTree.getTreeHandle, "DEPTH", id );

		switch( depth )
		{
			case 0:
				Ihandle* itemNewProject = IupItem( toStringz( GLOBAL.languageItems["newprj"] ), null );
				IupSetAttribute(itemNewProject, "IMAGE", "icon_newprj");
				IupSetCallback( itemNewProject, "ACTION", cast(Icallback) &menu.newProject_cb ); // From menu.d
				
				Ihandle* itemOpenProject = IupItem( toStringz( GLOBAL.languageItems["openprj"] ), null );
				IupSetAttribute(itemOpenProject, "IMAGE", "icon_openprj");
				IupSetCallback( itemOpenProject, "ACTION", cast(Icallback) &menu.openProject_cb ); // From menu.d

				Ihandle* itemCloseAllProject = IupItem( toStringz( GLOBAL.languageItems["closeallprj"] ), null );
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
				Ihandle* itemProperty = IupItem( toStringz( GLOBAL.languageItems["properties"] ), null );
				IupSetAttribute(itemProperty, "IMAGE", "icon_properties");
				IupSetCallback( itemProperty, "ACTION", cast(Icallback) &menu.projectProperties_cb ); // From menu.d
				
				Ihandle* itemClose = IupItem( toStringz( GLOBAL.languageItems["closeprj"] ), null );
				IupSetAttribute(itemClose, "IMAGE", "icon_clear");
				IupSetCallback( itemClose, "ACTION", cast(Icallback) &menu.closeProject_cb );  // From menu.d

				Ihandle* itemExplorer = IupItem( toStringz( GLOBAL.languageItems["openinexplorer"] ), null );
				IupSetCallback( itemExplorer, "ACTION", cast(Icallback) function( Ihandle* ih )
				{
					char[]	fullPath = actionManager.ProjectAction.getActiveProjectName();

					version( Windows )
					{
						Util.replace( fullPath, '/', '\\' );
						scope proc = new Process( true, "explorer " ~ "\"" ~ fullPath ~ "\"" );
						proc.execute;
						proc.wait;
					}
					else
					{
						scope proc = new Process( true, "xdg-open " ~ "\"" ~ fullPath ~ "\"" );
						proc.execute;
						proc.wait;
					}
				});

				Ihandle* popupMenu = IupMenu( 	itemProperty,
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
				
				Ihandle* itemNewFile = IupItem( toStringz( GLOBAL.languageItems["newfile"] ), null );
				IupSetCallback( itemNewFile, "ACTION", cast(Icallback) &CProjectTree_NewFile_cb );
				Ihandle* itemNewFolder = IupItem( toStringz( GLOBAL.languageItems["newfolder"] ), null );
				IupSetCallback( itemNewFolder, "ACTION", cast(Icallback) &CProjectTree_NewFolder_cb );
				
				Ihandle* itemCreateNew = IupMenu( itemNewFile, itemNewFolder, null );
		
				Ihandle* itemNew = IupSubmenu( toStringz( GLOBAL.languageItems["new"] ), itemCreateNew );
				
				Ihandle* itemAdd = IupItem( toStringz( GLOBAL.languageItems["addfile"] ), null );
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
		scope test = new CSingleTextDialog( -1, -1, "Create New File", "File Name:", "100x", null, false, "MAIN_DIALOG", "icon_newfile" );
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
				IupMessage( "Alarm!", GLOBAL.cString.convert( "\"" ~ fileName ~ "\"\nhas already exist!" ) );
				return IUP_DEFAULT;
			}
			
			// Wrong Ext, exit!
			switch( lowerCase( fn.ext ) )
			{
				case "bas":
					if( prjFilesFolderName != "Sources" )
					{
						IupMessage( "Wrong!", "Wrong Ext Name!!" );
						return IUP_DEFAULT;
					}
					break;
				case "bi":
					if( prjFilesFolderName != "Includes" )
					{
						IupMessage( "Wrong!", "Wrong Ext Name!!" );
						return IUP_DEFAULT;
					}
					break;
				default:
					if( prjFilesFolderName != "Others" )
					{
						IupMessage( "Wrong!", "Wrong Ext Name!!" );
						return IUP_DEFAULT;
					}
			}

			// Reset FilePath Object
			fn.set( fn.path );
			if( !fn.exists() ) fn.create(); // Create Folder On Disk

			actionManager.ScintillaAction.newFile( fullPath );
			GLOBAL.outlineTree.loadFile( fullPath );

			id = IupGetInt( GLOBAL.projectTree.getTreeHandle, "VALUE" ); // Re-Get Active Focus Node ID
			IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "ADDLEAF", id, GLOBAL.cString.convert( fileName ) );
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
				default:
					GLOBAL.projectManager[activeProjectDirName].others ~= fullPath;
					IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "IMAGE", id + 1, GLOBAL.cString.convert( "icon_txt" ) );
					break;
			}
		}
		
		return IUP_DEFAULT;
	}

	private int CProjectTree_NewFolder_cb( Ihandle* ih )
	{
		scope test = new CSingleTextDialog( -1, -1, "Create New Folder", "Folder Name:", "100x", null, false );
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

			switch( prjFilesFolderName )
			{
				case "Sources":		filter = "Source File|*.bas|All Files|*.*"; break;
				case "Includes":	filter = "Include File|*.bi|All Files|*.*"; break;
				default:			filter = "All Files|*.*"; break;
			}

			scope fileSecectDlg = new CFileDlg( "Add File...", filter, "OPEN", "YES" );
			//char[] fullPath = fileSecectDlg.getFileName();
			foreach( char[] fullPath; fileSecectDlg.getFilesName() )
			{
				if( fullPath.length )
				{
					scope fn = new FilePath( fullPath.dup );
					if( !fn.exists() )
					{
						IupMessage( "Alarm!", GLOBAL.cString.convert( "\"" ~ fullPath ~ "\"\nhas no exist!" ) );
						return IUP_DEFAULT;
					}
					else
					{
						//Util.substitute( fullPath, "/", "\\" );
						foreach( char[] s; GLOBAL.projectManager[prjDirName].sources ~ GLOBAL.projectManager[prjDirName].includes ~ GLOBAL.projectManager[prjDirName].others )
						{
							if( s == fullPath )
							{
								char[] ext = lowerCase( fn.ext() );
								if( ext == "bi" || ext == "bas" ) actionManager.ScintillaAction.openFile( s.dup );
								return IUP_DEFAULT;
							}
						}
					}

					// Wrong Ext, exit!
					switch( lowerCase( fn.ext ) )
					{
						case "bas":
							if( prjFilesFolderName != "Sources" )
							{
								IupMessage( "Wrong!", "Wrong Ext Name!!" );
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
								IupMessage( "Wrong!", "Wrong Ext Name!!" );
								return IUP_DEFAULT;
							}
							else
							{
								GLOBAL.projectManager[prjDirName].includes ~= fullPath;
							}
							break;
						default:
							if( prjFilesFolderName != "Others" )
							{
								IupMessage( "Wrong!", "Wrong Ext Name!!" );
								return IUP_DEFAULT;
							}
							else
							{
								GLOBAL.projectManager[prjDirName].others ~= fullPath;
							}
					}

					/*
					int	folderLocateId = actionManager.ProjectAction.addTreeNode( prjDirName ~ "/", fullPath, id );
					IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "ADDLEAF", folderLocateId, GLOBAL.cString.convert( fn.file ) );
					IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", folderLocateId+1, tools.getCString( fullPath ) );
					// shadow
					//IupSetAttributeId( GLOBAL.projectTree.getShadowTreeHandle, "ADDLEAF", id, GLOBAL.cString.convert( fullPath ) );
					*/
					char[]		titleName = Util.substitute( fullPath, "\\", "/" );
					int			folderLocateId = _createTree( prjDirName ~ "/", titleName, id );
					char[]		userData = fullPath;
					IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "ADDLEAF", folderLocateId, GLOBAL.cString.convert( titleName ) );
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
		// Get Focus Tree Node ID
		int id = IupGetInt( GLOBAL.projectTree.getTreeHandle, "VALUE" );
		char[] fullPath = fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id ) );

		scope fp = new FilePath( fullPath );
		char[] ext = lowerCase( fp.ext );

		if( ext == "bi" || ext == "bas" )
		{
			actionManager.ScintillaAction.openFile( fullPath.dup );
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
			catch{}
		}

		return IUP_DEFAULT;
	}

	private int CProjectTree_remove_cb( Ihandle* ih )
	{
		// Get Focus Tree Node ID
		int		id					= IupGetInt( GLOBAL.projectTree.getTreeHandle, "VALUE" );
		char[]	fullPath			= fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id ) ).dup;
		int		typeID				= actionManager.ProjectAction.getTargetDepthID( 2 );
		char[]	prjFilesFolderName	= fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "TITLE", typeID ) ).dup; // = Sources or Includes or Others

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
				
			default:
				char[][] temp;
				foreach( char[] s; GLOBAL.projectManager[actionManager.ProjectAction.getActiveProjectName].others )
					if( s != fullPath ) temp ~= s;
				GLOBAL.projectManager[actionManager.ProjectAction.getActiveProjectName].others = temp;
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
		
		return IUP_DEFAULT;
	}

	private int CProjectTree_delete_cb( Ihandle* ih )
	{
		int		id					= IupGetInt( GLOBAL.projectTree.getTreeHandle, "VALUE" );
		char[]	fullPath			= fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id ) ).dup;

		Ihandle* messageDlg = IupMessageDlg();
		IupSetAttributes( messageDlg, "DIALOGTYPE=WARNING,TITLE=Warning!,BUTTONS=OKCANCEL" );
		IupSetAttribute( messageDlg, "VALUE", toStringz( "Are you sure to delete file?" ) );
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

		scope fp = new FilePath( fullPath );

		char[] oldExt = fp.ext().dup;

		scope test = new CSingleTextDialog( -1, -1, "File Rename", "File Name:", "100x", fp.name(), false );
		char[] newFileName = test.show( IUP_MOUSEPOS, IUP_MOUSEPOS );

		if( newFileName.length )
		{
			// ReName On Disk & Change fn
			fp.rename( fp.path ~ newFileName ~ fp.suffix );

			if( upperCase(fullPath) in GLOBAL.scintillaManager ) 
			{
				GLOBAL.scintillaManager[upperCase(fullPath)].rename( fp.toString );
			}

			
			char* pointer = IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id );
			if( pointer != null ) freeCString( pointer );
			
			IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id, tools.getCString( fp.toString ) );
			IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "TITLE", id, GLOBAL.cString.convert( fp.file ) );

			char[] activeProjectDirName = actionManager.ProjectAction.getActiveProjectName;

			switch( lowerCase( oldExt ) )
			{
				case "bas":
					/*
					char[][] tempSources = GLOBAL.projectManager[GLOBAL.activeProjectDirName].sources;
					GLOBAL.projectManager[GLOBAL.activeProjectDirName].sources.length = 0;
					*/
					char[][] tempSources = GLOBAL.projectManager[activeProjectDirName].sources;
					GLOBAL.projectManager[activeProjectDirName].sources.length = 0;
					foreach( char[] s; tempSources )
					{
						//if( s != fullPath ) GLOBAL.projectManager[GLOBAL.activeProjectDirName].sources ~= s;else GLOBAL.projectManager[GLOBAL.activeProjectDirName].sources ~= fp.toString;
						if( s != fullPath ) GLOBAL.projectManager[activeProjectDirName].sources ~= s;else GLOBAL.projectManager[activeProjectDirName].sources ~= fp.toString;
					}
					
					break;

				case "bi":
					/*
					char[][] tempIncludes = GLOBAL.projectManager[GLOBAL.activeProjectDirName].includes;
					GLOBAL.projectManager[GLOBAL.activeProjectDirName].includes.length = 0;
					*/
					char[][] tempIncludes = GLOBAL.projectManager[activeProjectDirName].includes;
					GLOBAL.projectManager[activeProjectDirName].includes.length = 0;
					foreach( char[] s; tempIncludes )
					{
						//if( s != fullPath ) GLOBAL.projectManager[GLOBAL.activeProjectDirName].includes ~= s;else GLOBAL.projectManager[GLOBAL.activeProjectDirName].includes ~= fp.toString;
						if( s != fullPath ) GLOBAL.projectManager[activeProjectDirName].includes ~= s;else GLOBAL.projectManager[activeProjectDirName].includes ~= fp.toString;
					}
					break;
				default:
					/*
					char[][] tempOthers = GLOBAL.projectManager[GLOBAL.activeProjectDirName].others;
					GLOBAL.projectManager[GLOBAL.activeProjectDirName].others.length = 0;
					*/
					char[][] tempOthers = GLOBAL.projectManager[activeProjectDirName].others;
					GLOBAL.projectManager[activeProjectDirName].others.length = 0;
					foreach( char[] s; tempOthers )
					{
						//if( s != fullPath ) GLOBAL.projectManager[GLOBAL.activeProjectDirName].others ~= s;else GLOBAL.projectManager[GLOBAL.activeProjectDirName].others ~= fp.toString;
						if( s != fullPath ) GLOBAL.projectManager[activeProjectDirName].others ~= s;else GLOBAL.projectManager[activeProjectDirName].others ~= fp.toString;
					}
			}
		}
		
		return IUP_DEFAULT;
	}

	private int _createTree( char[] _prjDirName, inout char[] _titleName, int startID = 2 )
	{
		int		pos;
		int		folderLocateId = startID;
		char[]	fullPath = Util.replace( _titleName, '\\', '/' );

		version(Windows)
		{
			pos = Util.index( lowerCase( fullPath ), lowerCase( _prjDirName ) );
			if( pos == 0 ) _titleName = fullPath[_prjDirName.length..length].dup;
		}
		else
		{
			pos = Util.index( fullPath, _prjDirName );
			if( pos == 0 )  _titleName = fullPath[_prjDirName.length..length].dup; //_titleName = Util.substitute( fullPath, _prjDirName, "" );
		}

		// Check the child Folder
		char[][]	splitText = Util.split( _titleName, "/" );
	
		int counterSplitText;
		for( counterSplitText = 0; counterSplitText < splitText.length - 1; ++counterSplitText )
		{
			if( splitText[counterSplitText].length )
			{
				int 	countChild = IupGetIntId( GLOBAL.projectTree.getTreeHandle, "TOTALCHILDCOUNT", folderLocateId );
				//int 	countChild = IupGetIntId( tree, "COUNT", folderLocateId );
				bool bFolerExist = false;
				for( int i = 1; i <= countChild; ++ i )
				{
					char[]	kind = fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "KIND", folderLocateId + i ) );
					if( kind == "BRANCH" )
					{
						if( splitText[counterSplitText] == fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "TITLE", folderLocateId + i ) ) )
						{
							// folder already exist
							folderLocateId = folderLocateId+i;
							bFolerExist = true;
							break;
						}
					}
				}
				if( !bFolerExist )
				{
					IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "ADDBRANCH", folderLocateId, GLOBAL.cString.convert( splitText[counterSplitText] ) );
					if( pos != 0 )
						IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", folderLocateId+1, tools.getCString( "FIXED" ) );
					else
						IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", folderLocateId+1, tools.getCString( splitText[counterSplitText] ) );
					
					folderLocateId ++;
				}
			}
		}

		if( splitText.length > 1 ) _titleName = splitText[length-1];
		
		return folderLocateId;
	}		
}