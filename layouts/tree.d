module layouts.tree;

private import iup.iup;

private import global, scintilla, actionManager, menu;
private import dialogs.singleTextDlg, dialogs.fileDlg;


private import tango.stdc.stringz;
private import tango.io.FilePath, tango.io.UnicodeFile, tango.text.Ascii, tango.io.Stdout;


import Integer = tango.text.convert.Integer;

// FileLise Tree
void createFileListTree()
{
	GLOBAL.fileListTree = IupTree();

	IupSetAttributes( GLOBAL.fileListTree, "EXPAND=YES,RASTERSIZE=0x,TITLE=FileList" );
	IupSetCallback( GLOBAL.fileListTree, "SELECTION_CB", cast(Icallback) &fileListNodeSelect_cb );
	IupSetCallback( GLOBAL.fileListTree, "RIGHTCLICK_CB", cast(Icallback) &fileListNodeRightClick_cb );
}


class CProjectTree
{
	private:
		import		project;
		
		Ihandle*	tree;

	int _createTree( char[] _prjDirName, inout char[] _titleName )
	{
		int		folderLocateId = 2;
		char[]	fullPath = _titleName;
		
		int pos = Util.index( fullPath, _prjDirName );
		if( pos == 0 ) 	_titleName = Util.substitute( fullPath, _prjDirName, "" );

		// Check the child Folder
		char[][]	splitText = Util.split( _titleName, "\\" );
	
		int counterSplitText;
		for( counterSplitText = 0; counterSplitText < splitText.length - 1; ++counterSplitText )
		{
			//int 	countChild = IupGetIntId( tree, "TOTALCHILDCOUNT", folderLocateId );
			int 	countChild = IupGetIntId( tree, "COUNT", folderLocateId );

			bool bFolerExist = false;
			for( int i = 1; i <= countChild; ++ i )
			{
				char[]	kind = fromStringz( IupGetAttributeId( tree, "KIND", folderLocateId + i ) );
				if( kind == "BRANCH" )
				{
					if( splitText[counterSplitText] == fromStringz( IupGetAttributeId( tree, "TITLE", folderLocateId + i ) ) )
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
				IupSetAttributeId( tree, "ADDBRANCH", folderLocateId, toStringz(splitText[counterSplitText]) );
				//if( pos != 0 ) IupSetAttributeId( tree, "USERDATA", folderLocateId+1, toStringz("FIXED") );
				if( pos != 0 ) IupSetAttributeId( tree, "USERDATA", folderLocateId+1, cast(char*) new CString("FIXED") );
				folderLocateId ++;
			}
		}

		if( splitText.length > 1 ) _titleName = splitText[length-1];
		
		return folderLocateId;
	}		


	public:
	this()
	{
		tree = IupTree();
		IupSetAttributes( tree, "ADDROOT=YES,EXPAND=YES,RASTERSIZE=0x,TITLE=Projects" );
		IupSetCallback( tree, "RIGHTCLICK_CB", cast(Icallback) &CProjectTree_RightClick_cb );
		IupSetCallback( tree, "SELECTION_CB", cast(Icallback) &CProjectTree_Selection_cb );
		IupSetCallback( tree, "EXECUTELEAF_CB", cast(Icallback) &CProjectTree_ExecuteLeaf_cb );

		IupSetAttribute( tree, "IMAGELEAF", "IMGPAPER" );
	}

	Ihandle* getTreeHandle()
	{
		return tree;
	}

	void CreateNewProject( char[] prjName, char[] prjDir )
	{
		//GLOBAL.activeProjectDirName = prjDir;

		IupSetAttribute( tree, "ADDBRANCH0", toStringz(prjName)  );
		IupSetAttributeId( tree, "MARKED", 1, "YES" );

		int lastAddNodeID = IupGetInt( tree, "LASTADDNODE" );
		IupSetAttributeId( tree, "USERDATA", lastAddNodeID, cast(char*) new CString(prjDir) );

		IupSetAttribute( tree, "ADDBRANCH1", "Others" );
		IupSetAttribute( tree, "ADDBRANCH1", "Includes" );
		IupSetAttribute( tree, "ADDBRANCH1", "Sources" );

		// Set Focus to Project Tree
		IupSetAttribute( GLOBAL.projectViewTabs, "VALUE_HANDLE", cast(char*) GLOBAL.projectTree.getTreeHandle );
	}

	void openProject( char[] setupDir = null )
	{
		if( !setupDir.length )
		{
			scope fileSelectDlg = new CFileDlg( null, null, "DIR" );
			setupDir = fileSelectDlg.getFileName();
		}

		if( !setupDir.length ) return;

		if( setupDir in GLOBAL.projectManager )
		{
			IupMessage( "Alarm!", toStringz("\"" ~ setupDir ~ "\"\nhas already opened!") );
			return;
		}
		
		char[] setupFileName = setupDir ~ "\\.poseidon";

		scope sFN = new FilePath( setupFileName );

		if( sFN.exists() )
		{
			PROJECT		p;
			GLOBAL.projectManager[setupDir] = p.loadFile( setupFileName );

			if( !GLOBAL.projectManager[setupDir].dir.length )
			{
				GLOBAL.projectManager.remove( setupDir );
				IupMessage( "ERROR", toStringz("Project setup file loading error!!\nXml format may be broken!!") );
				return;
			}

			/*
			GLOBAL.activeProjectDirName = GLOBAL.projectManager[setupDir].dir;

			char[] 		prjDirName = GLOBAL.activeProjectDirName ~ "\\";
			*/
			char[] prjDirName = GLOBAL.projectManager[setupDir].dir ~ "\\";

			// Add Project's Name to Tree
			IupSetAttribute( tree, "ADDBRANCH0", toStringz(GLOBAL.projectManager[setupDir].name)  );
			IupSetAttributeId( tree, "MARKED", 1, "YES" );
			

			// Add Project's Dir to First USERDATA
			int lastAddNodeID = IupGetInt( tree, "LASTADDNODE" );
			IupSetAttributeId( tree, "USERDATA", lastAddNodeID, cast(char*) new CString( setupDir ) );

			IupSetAttribute( tree, "ADDBRANCH1", "Others" );
			foreach( char[] s; GLOBAL.projectManager[setupDir].others )
			{
				char[]		userData = s;
				int			folderLocateId = _createTree( prjDirName, s );
				
				IupSetAttributeId( tree, "ADDLEAF", folderLocateId, toStringz(s) );
				IupSetAttributeId( tree, "USERDATA", folderLocateId + 1, cast(char*) new CString( userData ) );
				IupSetAttributeId( tree, "IMAGE", folderLocateId + 1, toStringz("icon_txt") );
			}
			
			IupSetAttribute( tree, "ADDBRANCH1", "Includes" );
			foreach( char[] s; GLOBAL.projectManager[setupDir].includes )
			{
				char[]		userData = s;
				int			folderLocateId = _createTree( prjDirName, s );
				
				IupSetAttributeId( tree, "ADDLEAF", folderLocateId, toStringz(s) );
				IupSetAttributeId( tree, "USERDATA", folderLocateId + 1, cast(char*) new CString( userData ) );
				IupSetAttributeId( tree, "IMAGE", folderLocateId + 1, toStringz("icon_bi") );
			}

			IupSetAttribute( tree, "ADDBRANCH1", "Sources" );
			foreach( char[] s; GLOBAL.projectManager[setupDir].sources )
			{
				char[]		userData = s;
				int			folderLocateId = _createTree( prjDirName, s );
				
				IupSetAttributeId( tree, "ADDLEAF", folderLocateId, toStringz(s) );
				IupSetAttributeId( tree, "USERDATA", folderLocateId + 1, cast(char*) new CString( userData ) );
				IupSetAttributeId( tree, "IMAGE", folderLocateId + 1, toStringz("icon_bas") );
			}

			// Set Focus to Project Tree
			IupSetAttribute( GLOBAL.projectViewTabs, "VALUE_HANDLE", cast(char*) GLOBAL.projectTree.getTreeHandle );

			// Recent Projects
			GLOBAL.projectTree.updateRecentProjects( setupDir, GLOBAL.projectManager[setupDir].name );
		}
		else
		{
			IupMessage( "Error!", toStringz("\"" ~ setupDir ~ "\"\nhas lost setting xml file!") );
			return;
		}
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
				Ihandle* _new = IupItem( toStringz(GLOBAL.recentProjects[i]), null );
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
	int CProjectTree_Selection_cb( Ihandle *ih, int id, int status )
	{
		// SELECTION_CB will trigger 2 times, preSelect -> Select, we only catch second signal
		if( status == 1 )
		{
			// Swith the doument tabs by select Tree Node, if the doument isn't exist, do nothing
			if( fromStringz( IupGetAttribute( ih, "KIND" ) ) == "LEAF" )
			{
				char[] fullPath = ( cast(CString) IupGetAttribute( ih, "USERDATA" ) ).text;
				if( fullPath in GLOBAL.scintillaManager ) 
				{
					Ihandle* _sci = GLOBAL.scintillaManager[fullPath].getIupScintilla;
					
					IupSetAttribute( GLOBAL.documentTabs, "VALUE_HANDLE", cast(char*)_sci );
					IupSetFocus( _sci );
					StatusBarAction.update();
				}				
			}
		}

		return IUP_DEFAULT;
	}

	// Leaf Node has been Double-Click
	int CProjectTree_ExecuteLeaf_cb( Ihandle *ih, int id )
	{
		char[] fullPath = ( cast(CString) IupGetAttribute( ih, "USERDATA" ) ).text; // Get the fullpath of file, from USERDATA
		actionManager.ScintillaAction.openFile( fullPath );

		return IUP_DEFAULT;
	}

	// Show Fullpath or Filename
	int CProjectTree_RightClick_cb( Ihandle *ih, int id )
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

				Ihandle* popupMenu = IupMenu( 	itemNewProject, 
												itemOpenProject,
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

				Ihandle* popupMenu = IupMenu( 	itemProperty, 
												itemClose,
												null
											);

				IupPopup( popupMenu, IUP_MOUSEPOS, IUP_MOUSEPOS );
				IupDestroy( popupMenu );
				break;

			case 2:		// On Source or Include Node
			default:
				auto _cstring = cast(CString) IupGetAttribute( ih, "USERDATA" );
				if( _cstring !is null )
				{
					if( _cstring.text == "FIXED" ) return IUP_DEFAULT;
				}
				
				//if( ( cast(CString) IupGetAttribute( ih, "USERDATA" ) ).text == "FIXED" ) return IUP_DEFAULT;
			
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

	int CProjectTree_NewFile_cb( Ihandle* ih )
	{
		// Open Dialog Window
		scope test = new CSingleTextDialog( 275, 120, "Create New File", "File Name:", null, false );
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
					stepFolder ~= fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "TITLE", id ) );
					
					id = IupGetIntId( GLOBAL.projectTree.getTreeHandle, "PARENT", id );
					depth = IupGetIntId( GLOBAL.projectTree.getTreeHandle, "DEPTH", id );
				}

				prjFilesFolderName = fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "TITLE", id ) ); // = Sources or Includes or Others
			}

			char[] activeProjectDirName = actionManager.ProjectAction.getActiveProjectName();
			char[] fullPath = activeProjectDirName ~ "\\";
			//char[] fullPath = GLOBAL.activeProjectDirName ~ "\\";
			
			foreach_reverse( char[] s; stepFolder )
			{
				fullPath = fullPath ~ s ~ "\\";
			}
			fullPath = fullPath ~ fileName;

			scope fn = new FilePath( fullPath );

			if( fn.exists() )
			{
				IupMessage( "Alarm!", toStringz("\"" ~ fileName ~ "\"\nhas already exist!") );
				return IUP_DEFAULT;
			}
			
			// Wrong Ext, exit!
			switch( toLower( fn.ext ) )
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

			id = IupGetInt( GLOBAL.projectTree.getTreeHandle, "VALUE" ); // Re-Get Active Focus Node ID
			IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "ADDLEAF", id, toStringz(fileName) );
			IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id + 1, cast(char*) new CString( fullPath ) );
			

			switch( prjFilesFolderName )
			{
				case "Sources":
					GLOBAL.projectManager[activeProjectDirName].sources ~= fullPath;
					IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "IMAGE", id + 1, toStringz("icon_bas") );
					break;
				case "Includes":
					GLOBAL.projectManager[activeProjectDirName].includes ~= fullPath;
					IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "IMAGE", id + 1, toStringz("icon_bi") );
					break;
				default:
					GLOBAL.projectManager[activeProjectDirName].others ~= fullPath;
					IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "IMAGE", id + 1, toStringz("icon_txt") );
					break;
			}
		}
		
		return IUP_DEFAULT;
	}

	int CProjectTree_NewFolder_cb( Ihandle* ih )
	{
		scope test = new CSingleTextDialog( 290, 120, "Create New Folder", "Folder Name:", null, false );
		char[] folderName = test.show( IUP_MOUSEPOS, IUP_MOUSEPOS );

		if( folderName.length )
		{
			// Get Focus Tree Node ID
			int id = IupGetInt( GLOBAL.projectTree.getTreeHandle, "VALUE" );

			// Get Focus Tree Node 
			char[] kind = fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "KIND", id ) );

			if( kind == "BRANCH" )
			{
				IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "ADDBRANCH", id, toStringz(folderName) );
			}
		}
		
		return IUP_DEFAULT;
	}

	int CProjectTree_AddFile_cb( Ihandle* ih )
	{
		int		id					= actionManager.ProjectAction.getTargetDepthID( 2 );
		char[]	prjFilesFolderName	= fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "TITLE", id ) ); // = Sources or Includes or Others
		char[]	prjDirName 			= actionManager.ProjectAction.getActiveProjectName();
		char[]	filter;

		switch( prjFilesFolderName )
		{
			case "Sources":		filter = "Source File|*.bas|All Files|*.*"; break;
			case "Includes":	filter = "Include File|*.bi|All Files|*.*"; break;
			default:			filter = "All Files|*.*"; break;
		}

		scope fileSecectDlg = new CFileDlg( "Add File...", filter );
		char[] fullPath = fileSecectDlg.getFileName();

		if( fullPath.length )
		{
			scope fn = new FilePath( fullPath );

			if( !fn.exists() )
			{
				IupMessage( "Alarm!", toStringz("\"" ~ fullPath ~ "\"\nhas no exist!") );
				return IUP_DEFAULT;
			}
			else
			{
				foreach( char[] s; GLOBAL.projectManager[prjDirName].sources ~ GLOBAL.projectManager[prjDirName].includes ~ GLOBAL.projectManager[prjDirName].others )
				{
					if( s == fullPath )
					{
						actionManager.ScintillaAction.openFile( s );
						return IUP_DEFAULT;
					}
				}
			}
			
			// Wrong Ext, exit!
			switch( toLower( fn.ext ) )
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

			int	folderLocateId = actionManager.ProjectAction.addTreeNode( prjDirName ~ "\\", fullPath, id );
			IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "ADDLEAF", folderLocateId, toStringz(fn.file) );
			IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", folderLocateId + 1, cast(char*) new CString( fullPath ) );

			switch( prjFilesFolderName )
			{
				case "Sources":		IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "IMAGE", folderLocateId + 1, toStringz("icon_bas") ); break;
				case "Includes":	IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "IMAGE", folderLocateId + 1, toStringz("icon_bi") ); break;
				default:			IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "IMAGE", folderLocateId + 1, toStringz("icon_txt") ); break;
			}			

			actionManager.ScintillaAction.openFile( fullPath );
		}

		return IUP_DEFAULT;
	}

	int CProjectTree_Open_cb( Ihandle *ih )
	{
		// Get Focus Tree Node ID
		int id = IupGetInt( GLOBAL.projectTree.getTreeHandle, "VALUE" );

		char[] fullPath = ( cast(CString) IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id ) ).text;
		actionManager.ScintillaAction.openFile( fullPath );

		return IUP_DEFAULT;
	}

	int CProjectTree_remove_cb( Ihandle* ih )
	{
		// Get Focus Tree Node ID
		int		id					= IupGetInt( GLOBAL.projectTree.getTreeHandle, "VALUE" );
		char[]	fullPath			= ( cast(CString) IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id ) ).text;
		int		typeID				= actionManager.ProjectAction.getTargetDepthID( 2 );
		char[]	prjFilesFolderName	= fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "TITLE", typeID ) ); // = Sources or Includes or Others

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

		IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "DELNODE", id, "SELECTED" );
		
		return IUP_DEFAULT;
	}

	int CProjectTree_delete_cb( Ihandle* ih )
	{
		int		id					= IupGetInt( GLOBAL.projectTree.getTreeHandle, "VALUE" );
		char[]	fullPath			= ( cast(CString) IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id ) ).text;

		if( fullPath.length )
		{
			if( CProjectTree_remove_cb( ih ) == IUP_IGNORE ) return IUP_IGNORE;

			scope f = new FilePath( fullPath );
			f.remove();
		}

		return IUP_DEFAULT;
	}

	int CProjectTree_rename_cb( Ihandle* ih )
	{
		// 
		int id = IupGetInt( GLOBAL.projectTree.getTreeHandle, "VALUE" );
		char[] fullPath = ( cast(CString) IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id ) ).text;

		scope fp = new FilePath( fullPath );

		char[] oldExt = fp.ext();

		scope test = new CSingleTextDialog( 275, 120, "File Rename", "File Name:", fp.name(), false );
		char[] newFileName = test.show( IUP_MOUSEPOS, IUP_MOUSEPOS );

		if( newFileName.length )
		{
			// ReName On Disk & Change fn
			fp.rename( fp.path ~ "\\" ~ newFileName ~ fp.suffix );

			if( fullPath in GLOBAL.scintillaManager ) 
			{
				GLOBAL.scintillaManager[fullPath].rename( fp.toString );
			}				

			IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id, cast(char*) new CString(fp.toString) );
			IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "TITLE", id, toStringz(fp.file) );

			char[] activeProjectDirName = actionManager.ProjectAction.getActiveProjectName;

			switch( toLower( oldExt ) )
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
}


void createOutlineTree()
{
	GLOBAL.outlineTree = IupTree();
	IupSetAttributes( GLOBAL.outlineTree , "EXPAND=YES,RASTERSIZE=0x" );

	/*
	IupSetAttribute( GLOBAL.outlineTree , "EXPAND", "YES" );
	IupSetAttribute( GLOBAL.outlineTree , "RASTERSIZE", "0x" );
	*/
}



extern(C)
{
	// Open File...
	int fileListNodeSelect_cb( Ihandle *ih, int id, int status )
	{
		// SELECTION_CB will trigger 2 times, preSelect -> Select, we only catch second signal
		if( status == 1 )
		{
			CScintilla _sci = cast(CScintilla) IupGetAttributeId( ih, "USERDATA", id );
			ScintillaAction.openFile( _sci.getFullPath );
		}

		return IUP_DEFAULT;
	}

	//
	private void showFullpath()
	{
		int nodeCount = IupGetInt( GLOBAL.fileListTree, "COUNT" );
	
		for( int id = 1; id <= nodeCount; id++ ) // include Parent "FileList" node
		{
			CScintilla _sci = cast(CScintilla) IupGetAttributeId( GLOBAL.fileListTree, "USERDATA", id );
			if( _sci !is null) IupSetAttributeId( GLOBAL.fileListTree, "TITLE" ,id, toStringz(_sci.getFullPath) );
		}
	}

	private void showFilename()
	{
		int nodeCount = IupGetInt( GLOBAL.fileListTree, "COUNT" );
	
		for( int id = 1; id <= nodeCount; id++ ) // include Parent "FileList" node
		{
			char* nodeTitle = IupGetAttributeId( GLOBAL.fileListTree, "TITLE", id );

			scope _fullPath = new FilePath( fromStringz( nodeTitle ).dup );
			char[] baseName = _fullPath.file();

			IupSetAttributeId( GLOBAL.fileListTree, "TITLE", id, toStringz(baseName) );
		}		
	}

	// Show Fullpath or Filename
	int fileListNodeRightClick_cb( Ihandle *ih, int id )
	{
		if( id == 0 )
		{
			//IupMessage( "Message", "Root");
			static char id_string[10];

			Ihandle* popupMenu = IupMenu( 
											IupItem( "Show Fullpath", "showFullpath" ),
											IupItem( "Show Filename", "showFilename" ),
											null
										);

			IupSetFunction( "showFullpath", cast(Icallback) &showFullpath );
			IupSetFunction( "showFilename", cast(Icallback) &showFilename );


			IupPopup( popupMenu, IUP_MOUSEPOS, IUP_MOUSEPOS );
			IupDestroy(popupMenu);
		}

		return IUP_DEFAULT;
	}

	
}