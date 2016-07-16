module layouts.projectPanel;


private import iup.iup;

private import global, scintilla, actionManager, menu, tools;
private import dialogs.singleTextDlg, dialogs.fileDlg;

private import tango.stdc.stringz, tango.sys.Process;
private import tango.io.FilePath, Util = tango.text.Util, Integer = tango.text.convert.Integer;

class CProjectTree
{
	private:
	import		project;
		
	Ihandle*	layoutHandle, tree;//, shadowTree;

	void createLayout()
	{
		// Outline Toolbar
		Ihandle* projectButtonCollapse = IupButton( null, "Collapse" );
		IupSetAttributes( projectButtonCollapse, "ALIGNMENT=ARIGHT:ACENTER,FLAT=YES,IMAGE=icon_collapse,TIP=Collapse" );
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

		Ihandle* projectButtonHide = IupButton( null, "Hide" );
		IupSetAttributes( projectButtonHide, "ALIGNMENT=ARIGHT:ACENTER,FLAT=YES,IMAGE=icon_debug_left,TIP=Hide" );
		IupSetCallback( projectButtonHide, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			menu.outline_cb( GLOBAL.menuOutlineWindow );
		});


		Ihandle* labelSEPARATOR01 = IupLabel( null ); 
		IupSetAttribute( labelSEPARATOR01, "SEPARATOR", "VERTICAL");	
		

		Ihandle* projectToolbarTitleImage = IupLabel( null );
		IupSetAttributes( projectToolbarTitleImage, "IMAGE=icon_packageexplorer,ALIGNMENT=ACENTER:ALEFT" );

		/*Ihandle* projectToolbarTitle = IupLabel( " Project" );
		IupSetAttribute( projectToolbarTitle, "ALIGNMENT", "ACENTER:ALEFT" );*/

		Ihandle* projectToolbarH = IupHbox( projectToolbarTitleImage, /*projectToolbarTitle,*/ IupFill, projectButtonCollapse, labelSEPARATOR01, projectButtonHide, null );
		IupSetAttributes( projectToolbarH, "ALIGNMENT=ACENTER,SIZE=NULL" );

		tree = IupTree();
		IupSetAttributes( tree, "ADDROOT=YES,EXPAND=YES,TITLE=Projects,SIZE=NULL" );
		IupSetCallback( tree, "RIGHTCLICK_CB", cast(Icallback) &CProjectTree_RightClick_cb );
		IupSetCallback( tree, "SELECTION_CB", cast(Icallback) &CProjectTree_Selection_cb );
		IupSetCallback( tree, "EXECUTELEAF_CB", cast(Icallback) &CProjectTree_ExecuteLeaf_cb );		

		layoutHandle = IupVbox( projectToolbarH, tree, null );
		IupSetAttributes( layoutHandle, GLOBAL.cString.convert( "ALIGNMENT=ARIGHT,GAP=2" ) );
	}


	public:
	this()
	{
		createLayout();
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

	void CreateNewProject( char[] prjName, char[] prjDir )
	{
		//GLOBAL.activeProjectDirName = prjDir;

		IupSetAttribute( tree, "ADDBRANCH0", GLOBAL.cString.convert( prjName ) );
		IupSetAttributeId( tree, "MARKED", 1, "YES" );
		IupSetAttribute( tree, "USERDATA1", tools.getCString( prjDir ) );

		IupSetAttribute( tree, "ADDBRANCH1", "Others" );
		IupSetAttribute( tree, "ADDBRANCH1", "Includes" );
		IupSetAttribute( tree, "ADDBRANCH1", "Sources" );
		// Set Focus to Project Tree
		IupSetAttribute( GLOBAL.projectViewTabs, "VALUE_HANDLE", cast(char*) GLOBAL.projectTree.getTreeHandle );

		/*
		// Shadow
		IupSetAttribute( shadowTree, "ADDBRANCH0", GLOBAL.cString.convert( prjDir ) );
		IupSetAttributeId( shadowTree, "MARKED", 1, "YES" );
		IupSetAttribute( shadowTree, "ADDBRANCH1", "Others" );
		IupSetAttribute( shadowTree, "ADDBRANCH1", "Includes" );
		IupSetAttribute( shadowTree, "ADDBRANCH1", "Sources" );
		*/

		//Stdout( "tree count: " ~ fromStringz( IupGetAttribute( tree, "COUNT" ) ) ).newline;
		//Stdout( "shadowtree count: " ~ fromStringz( IupGetAttribute( shadowTree, "COUNT" ) ) ).newline;
	}

	bool openProject( char[] setupDir = null )
	{
		if( !setupDir.length )
		{
			scope fileSelectDlg = new CFileDlg( null, null, "DIR" );
			setupDir = fileSelectDlg.getFileName();
		}

		if( !setupDir.length ) return false;

		if( setupDir in GLOBAL.projectManager )
		{
			IupMessage( "Alarm!", GLOBAL.cString.convert( "\"" ~ setupDir ~ "\"\nhas already opened!" ) );
			return false;
		}
		
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

			/*
			GLOBAL.activeProjectDirName = GLOBAL.projectManager[setupDir].dir;

			char[] 		prjDirName = GLOBAL.activeProjectDirName ~ "\\";
			*/
			char[] prjDirName = GLOBAL.projectManager[setupDir].dir ~ "/";

			// Add Project's Name to Tree
			IupSetAttribute( tree, "ADDBRANCH0", GLOBAL.cString.convert( GLOBAL.projectManager[setupDir].name ) );
			IupSetAttribute( tree, "IMAGE1", GLOBAL.cString.convert( "icon_prj" ) );
			IupSetAttribute( tree, "IMAGEEXPANDED1", GLOBAL.cString.convert( "icon_prj_open" ) );
			IupSetAttributeId( tree, "MARKED", 1, "YES" );
			IupSetAttributeId( tree, "USERDATA", 1, tools.getCString( setupDir ) );

			// Shadow
			//IupSetAttribute( shadowTree, "ADDBRANCH0", GLOBAL.cString.convert( setupDir ) );

			
			IupSetAttribute( tree, "ADDBRANCH1", "Others" );
			// Shadow
			//IupSetAttribute( shadowTree, "ADDBRANCH1", "Others" );
	
			foreach( char[] s; GLOBAL.projectManager[setupDir].others )
			{
				char[]		userData = s;
				int			folderLocateId = _createTree( prjDirName, s );
				
				IupSetAttributeId( tree, "ADDLEAF", folderLocateId, GLOBAL.cString.convert( s ) );
				IupSetAttributeId( tree, "IMAGE", folderLocateId + 1, GLOBAL.cString.convert( "icon_txt" ) );
				IupSetAttributeId( tree, "USERDATA", folderLocateId + 1, tools.getCString( userData ) );

				// Shadow
				//IupSetAttributeId( shadowTree, "ADDLEAF", folderLocateId, GLOBAL.cString.convert( userData ) );
			}
			
			IupSetAttribute( tree, "ADDBRANCH1", "Includes" );
			// Shadow
			//IupSetAttribute( shadowTree, "ADDBRANCH1", "Includes" );
			foreach( char[] s; GLOBAL.projectManager[setupDir].includes )
			{
				char[]		userData = s;
				int			folderLocateId = _createTree( prjDirName, s );
				
				IupSetAttributeId( tree, "ADDLEAF", folderLocateId, GLOBAL.cString.convert( s ) );
				IupSetAttributeId( tree, "IMAGE", folderLocateId + 1, GLOBAL.cString.convert( "icon_bi" ) );
				IupSetAttributeId( tree, "USERDATA", folderLocateId + 1, tools.getCString( userData ) );

				// Shadow
				//IupSetAttributeId( shadowTree, "ADDLEAF", folderLocateId, GLOBAL.cString.convert( userData ) );
			}

			IupSetAttribute( tree, "ADDBRANCH1", "Sources" );
			// Shadow
			//IupSetAttribute( shadowTree, "ADDBRANCH1", "Sources" );			
			foreach( char[] s; GLOBAL.projectManager[setupDir].sources )
			{
				char[]		userData = s;
				int			folderLocateId = _createTree( prjDirName, s );
				
				IupSetAttributeId( tree, "ADDLEAF", folderLocateId, GLOBAL.cString.convert( s ) );
				IupSetAttributeId( tree, "IMAGE", folderLocateId + 1, GLOBAL.cString.convert( "icon_bas" ) );
				IupSetAttributeId( tree, "USERDATA", folderLocateId + 1, tools.getCString( userData ) );

				// Shadow
				//IupSetAttributeId( shadowTree, "ADDLEAF", folderLocateId, GLOBAL.cString.convert( userData ) );
			}

			// Set Focus to Project Tree
			IupSetAttribute( GLOBAL.projectViewTabs, "VALUE_HANDLE", cast(char*) GLOBAL.projectTree.getTreeHandle );

			// Recent Projects
			GLOBAL.projectTree.updateRecentProjects( setupDir, GLOBAL.projectManager[setupDir].name );

			IupSetAttribute( GLOBAL.mainDlg, "TITLE", toStringz( GLOBAL.projectManager[setupDir].name ~ " - poseidonFB - FreeBasic IDE" ) );

			IupSetAttribute( GLOBAL.projectViewTabs, "VALUEPOS", "0" );
		}
		else
		{
			IupMessage( "Error!", GLOBAL.cString.convert( "\"" ~ setupDir ~ "\"\nhas lost setting xml file!" ) );
			return false;
		}

		return true;
	}

	void updateRecentProjects( char[] prjDir, char[] prjName )
	{
		char[] title = prjDir ~ " : " ~ prjName;

		char[][]	temps;
		bool		bMove;

		for( int i = 0; i < GLOBAL.recentProjects.length; ++ i )
		{
			if( GLOBAL.recentProjects[i] != title )	temps ~= GLOBAL.recentProjects[i];
		}

		temps ~= title;
		GLOBAL.recentProjects.length = 0;
		GLOBAL.recentProjects = temps;
		
		// Recent Projects
		if( GLOBAL.recentProjects.length > 8 )
		{
			GLOBAL.recentProjects[0..8] = GLOBAL.recentProjects[length-8..length].dup;
			GLOBAL.recentProjects.length = 8;
		}

		Ihandle* recentPrj_ih = IupGetHandle( "recentFilesMenu" );
		if( recentPrj_ih != null )
		{
			// Clear All iupItem......
			for( int i = IupGetChildCount( recentPrj_ih ) - 1; i >= 0; -- i )
			{
				IupDestroy( IupGetChild( recentPrj_ih, i ) );
			}

			// Create New iupItem
			for( int i = 0; i < GLOBAL.recentProjects.length; ++ i )
			{
				Ihandle* _new = IupItem( GLOBAL.cString.convert( GLOBAL.recentProjects[i] ), null );
				IupSetCallback( _new, "ACTION", cast(Icallback)&menu.submenu_click_cb );
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
			/*
			char[] s = fromStringz( IupGetAttributeId( GLOBAL.projectTree.getShadowTreeHandle, "TITLE", id ) );
			Stdout( s ).newline;
			*/
			
			// Swith the doument tabs by select Tree Node, if the doument isn't exist, do nothing
			if( fromStringz( IupGetAttribute( ih, "KIND" ) ) == "LEAF" )
			{
				//char[] fullPath = fromStringz( IupGetAttributeId( GLOBAL.projectTree.getShadowTreeHandle, "TITLE", id ) ); // shadow
				char[] fullPath = fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id ) );
				//IupMessage("", IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id ) );
				
				if( upperCase(fullPath) in GLOBAL.scintillaManager ) 
				{
					//char[] fullPath = fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id ) );
					actionManager.ScintillaAction.openFile( fullPath.dup );
					/*
					Ihandle* _sci = GLOBAL.scintillaManager[upperCase(fullPath)].getIupScintilla;
					
					IupSetAttribute( GLOBAL.documentTabs, "VALUE_HANDLE", cast(char*)_sci );
					IupSetFocus( _sci );
					StatusBarAction.update();
					*/
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
		//char[] fullPath = fromStringz( IupGetAttributeId( GLOBAL.projectTree.getShadowTreeHandle, "TITLE", id ) ); // Shadow
		char[] fullPath = fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id ) );
		actionManager.ScintillaAction.openFile( fullPath.dup );

		return IUP_DEFAULT;
	}

	// Show Fullpath or Filename
	private int CProjectTree_RightClick_cb( Ihandle *ih, int id )
	{
		IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "MARKED", id, "YES" );

		char[] nodeKind = fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "KIND", id ) );

		if( nodeKind == "LEAF" ) // On File(*.bas, *.bi) Node
		{
			Ihandle* popupMenu = IupMenu( 
										IupItem( "Open", "CProjectTree_open" ),
										IupItem( "Remove from Project", "CProjectTree_remove" ),
										IupSeparator(),
										IupItem( "Delete", "CProjectTree_delete" ),
										IupItem( "Rename", "CProjectTree_rename" ),
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
				Ihandle* itemNewProject = IupItem( "New Project", null );
				IupSetCallback( itemNewProject, "ACTION", cast(Icallback) &menu.newProject_cb ); // From menu.d
				
				Ihandle* itemOpenProject = IupItem( "Open Project", null );
				IupSetCallback( itemOpenProject, "ACTION", cast(Icallback) &menu.openProject_cb ); // From menu.d

				Ihandle* itemCloseAllProject = IupItem( "Close All Project", null );
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
				Ihandle* itemProperty = IupItem( "Property", null );
				IupSetCallback( itemProperty, "ACTION", cast(Icallback) &menu.projectProperties_cb ); // From menu.d
				
				Ihandle* itemClose = IupItem( "Close", null );
				IupSetCallback( itemClose, "ACTION", cast(Icallback) &menu.closeProject_cb );  // From menu.d

				Ihandle* itemExplorer = IupItem( "Open In Explorer", null );
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
				
				Ihandle* itemNewFile = IupItem( "New File", null );
				IupSetCallback( itemNewFile, "ACTION", cast(Icallback) &CProjectTree_NewFile_cb );
				Ihandle* itemNewFolder = IupItem( "New Folder", null );
				IupSetCallback( itemNewFolder, "ACTION", cast(Icallback) &CProjectTree_NewFolder_cb );
				
				Ihandle* itemCreateNew = IupMenu( itemNewFile, itemNewFolder, null );
		
				Ihandle* itemNew = IupSubmenu( "New", itemCreateNew );
				
				Ihandle* itemAdd = IupItem( "Add File", null );
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
		scope test = new CSingleTextDialog( -1, -1, "Create New File", "File Name:", "100x", null, false );
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
								actionManager.ScintillaAction.openFile( s.dup );
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

					actionManager.ScintillaAction.openFile( fullPath.dup );
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

		// Shadow
		//char[] fullPath = fromStringz( IupGetAttributeId( GLOBAL.projectTree.getShadowTreeHandle, "TITLE", id ) );
		char[] fullPath = fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id ) );
		actionManager.ScintillaAction.openFile( fullPath.dup );

		return IUP_DEFAULT;
	}

	private int CProjectTree_remove_cb( Ihandle* ih )
	{
		// Get Focus Tree Node ID
		int		id					= IupGetInt( GLOBAL.projectTree.getTreeHandle, "VALUE" );
		// Shadow
		//char[]	fullPath			= fromStringz( IupGetAttributeId( GLOBAL.projectTree.getShadowTreeHandle, "TITLE", id ) ).dup;
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

		// Shadow
		//IupSetAttributeId( GLOBAL.projectTree.getShadowTreeHandle, "DELNODE", id, "SELECTED" );

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
		// Shadow
		//char[]	fullPath			= fromStringz( IupGetAttributeId( GLOBAL.projectTree.getShadowTreeHandle, "TITLE", id ) ).dup;

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
		// Shadow
		//char[]	fullPath			= fromStringz( IupGetAttributeId( GLOBAL.projectTree.getShadowTreeHandle, "TITLE", id ) ).dup;

		scope fp = new FilePath( fullPath );

		char[] oldExt = fp.ext();

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

			IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id, GLOBAL.cString.convert( fp.toString ) );
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
		int		folderLocateId = startID;
		char[]	fullPath = _titleName;
		
		int pos = Util.index( fullPath, _prjDirName );
		if( pos == 0 ) 	_titleName = Util.substitute( fullPath, _prjDirName, "" );

		// Check the child Folder
		char[][]	splitText = Util.split( _titleName, "/" );
	
		int counterSplitText;
		for( counterSplitText = 0; counterSplitText < splitText.length - 1; ++counterSplitText )
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
				
				/*
				// Shadow
				if( pos != 0 )
				{
					IupSetAttributeId( shadowTree, "ADDBRANCH", folderLocateId, GLOBAL.cString.convert( "FIXED" ) );
				}
				else
				{
					IupSetAttributeId( shadowTree, "ADDBRANCH", folderLocateId, GLOBAL.cString.convert( splitText[counterSplitText] ) );
				}
				*/
				
				folderLocateId ++;
			}
		}

		if( splitText.length > 1 ) _titleName = splitText[length-1];
		
		return folderLocateId;
	}		
}