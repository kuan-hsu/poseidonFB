module layouts.projectPanel;


private import iup.iup;
private import global, scintilla, actionManager, menu, tools;
private import dialogs.singleTextDlg, dialogs.fileDlg;
private import std.string, std.conv, std.file, std.encoding, Array = std.array, Path = std.path;

class CProjectTree
{
private:
	import				project, parser.autocompletion, parser.ast, dialogs.prjPropertyDlg, parser.parserFB;
	import				core.thread;
	
	Ihandle*			projectToolbarTitleImage, projectButtonCollapse, projectButtonHide;
	Ihandle*			layoutHandle, tree, projectToolBarBox;
	
	// Inner Class
	class ParseThread : Thread
	{
		private:
		import			parser.scanner, parser.parser;
		
		string			pFullPath, document;
		CASTnode		pParseTree;

		public:
		this( string _pFullPath, string _document = null )
		{
			pFullPath = _pFullPath;
			document = _document;
	
			super( &run );
		}

		void run()
		{
			// Don't Create Tree
			// Parser
			if( !document.length )
			{
				int bom, withbom;
				document = FileAction.loadFile( pFullPath, bom, withbom );
			}

			scope parser = new CParser( Scanner.scan( document ) );
			if( parser !is null )
			{
				auto p = parser.parse( pFullPath );
				if( p !is null ) pParseTree = p;
			}
		}
		
		CASTnode getResult()
		{
			return pParseTree;
		}
	}

	void createLayout()
	{
		// Outline Toolbar
		projectButtonCollapse = IupButton( null, null );
		IupSetAttributes( projectButtonCollapse, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_collapse2,VISIBLE=NO" );
		IupSetStrAttribute( projectButtonCollapse, "TIP", GLOBAL.languageItems["collapse"].toCString );
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

		projectButtonHide = IupButton( null, null );
		IupSetAttributes( projectButtonHide, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,IMAGE=icon_shift_l" );
		IupSetStrAttribute( projectButtonHide, "TIP", GLOBAL.languageItems["hide"].toCString );
		IupSetCallback( projectButtonHide, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			menu.outlineMenuItem_cb( GLOBAL.menuOutlineWindow );
			return IUP_DEFAULT;
		});

		projectToolbarTitleImage = IupLabel( null );
		IupSetAttributes( projectToolbarTitleImage, "ALIGNMENT=ACENTER:ALEFT" );

		Ihandle* projectToolbarH = IupHbox( projectToolbarTitleImage, IupFill, projectButtonCollapse, projectButtonHide, null );
		IupSetAttributes( projectToolbarH, "ALIGNMENT=ACENTER,SIZE=NULL" );
		
		tree = IupTree();
		IupSetAttributes( tree, "ADDROOT=YES,EXPAND=YES,TITLE=Projects,SIZE=NULL,BORDER=NO,MARKMODE=MULTIPLE,NAME=POSEIDON_PROJECT_Tree" );
		IupSetCallback( tree, "BUTTON_CB", cast(Icallback) &CProjectTree_BUTTON_CB );
		if( GLOBAL.editColor.prjViewHLT.length )
		{
			IupSetStrAttribute( tree, "HLCOLOR", toStringz( GLOBAL.editColor.prjViewHLT ) );
		}
		IupSetStrAttribute( tree, "FGCOLOR", toStringz( GLOBAL.editColor.projectFore ) );
		IupSetStrAttribute( tree, "BGCOLOR", toStringz( GLOBAL.editColor.projectBack ) );
		
		IupSetCallback( tree, "RIGHTCLICK_CB", cast(Icallback) &CProjectTree_RightClick_cb );
		IupSetCallback( tree, "SELECTION_CB", cast(Icallback) &CProjectTree_Selection_cb );
		IupSetCallback( tree, "NODEREMOVED_CB", cast(Icallback) &CProjectTree_NodeRemoved_cb );
		IupSetCallback( tree, "MULTISELECTION_CB", cast(Icallback) &CProjectTree_MULTISELECTION_CB );

		IupSetAttribute( tree, "IMAGE0", "icon_prj" );
		IupSetAttribute( tree, "IMAGEEXPANDED0", "icon_prj" );
		
		projectToolBarBox = IupBackgroundBox( projectToolbarH );
		IupSetStrAttribute( projectToolBarBox, "BGCOLOR", toStringz( GLOBAL.editColor.projectBack ) );	
		
		layoutHandle = IupVbox( projectToolBarBox, tree, null );
		IupSetAttributes( layoutHandle, "ALIGNMENT=ARIGHT,GAP=2" );
		layoutHandle = IupBackgroundBox( layoutHandle );
		
		changeIcons();
	}

	void toBoldTitle( Ihandle* _tree, int id )
	{
		auto commaPos = indexOf( GLOBAL.fonts[4].fontString, "," );
		if( commaPos > 0 )
		{
			string fontString = Array.replace( GLOBAL.fonts[4].fontString.dup, ",", ",Bold " );
			IupSetStrAttributeId( _tree, "TITLEFONT", id, toStringz( fontString ) );
		}
	}
	
	void changeIcons()
	{
		string tail;
		if( GLOBAL.editorSetting00.IconInvert == "ON" ) tail = "_invert";
		IupSetStrAttribute( projectToolbarTitleImage, "IMAGE", toStringz( "icon_packageexplorer" ~ tail ) );
		IupSetStrAttribute( projectButtonCollapse, "IMAGE", toStringz( "icon_collapse2" ~ tail ) );
		IupSetStrAttribute( projectButtonHide, "IMAGE", toStringz( "icon_shift_l" ~ tail ) );
	}
	

	CASTnode[] getVersionIncludes( CASTnode _node )
	{
		CASTnode[] result;
		
		foreach( CASTnode _child; _node.getChildren )
		{
			version(FBIDE)
			{
				if( _child.kind & B_VERSION )
				{
					version(VERSION_NONE)
					{
					}
					else
					{
						string symbol = toUpper( _child.name );
						string noSignSymbolName = _child.type.length ? symbol[1..$] : symbol;
						if( noSignSymbolName == "__FB_WIN32__" || noSignSymbolName == "__FB_LINUX__" || noSignSymbolName == "__FB_FREEBSD__" || noSignSymbolName == "__FB_OPENBSD__" || noSignSymbolName == "__FB_UNIX__" )
						{
							version(Windows)
							{
								if( symbol == "__FB_WIN32__" || ( symbol != "!__FB_WIN32__" ) )
								{
									result ~= getVersionIncludes( _child );
									continue;
								}
							}
							
							version(linux)
							{
								if( symbol == "__FB_LINUX__" || ( symbol != "!__FB_LINUX__" ) )
								{
									result ~= getVersionIncludes( _child );
									continue;
								}
							}
							
							version(FreeBSD)
							{
								if( symbol == "__FB_FREEBSD__" || ( symbol != "!__FB_FREEBSD__" ) )
								{
									result ~= getVersionIncludes( _child );
									continue;
								}
							}
							
							version(OpenBSD)
							{
								if( symbol == "__FB_OPENBSD__" || ( symbol != "!__FB_OPENBSD__" ) )
								{
									result ~= getVersionIncludes( _child );
									continue;
								}
							}
							
							version(Posix)
							{
								if( symbol == "__FB_UNIX__" || ( symbol != "!__FB_UNIX__" ) )
								{
									result ~= getVersionIncludes( _child );
									continue;
								}
							}
						}
						else
						{
							if( !_child.type.length )
							{
								if( symbol in AutoComplete.VersionCondition ) result ~= getVersionIncludes( _child );
							}
							else
							{
								if( AutoComplete.VersionCondition.length )
								{
									if( !( symbol[1..$] in AutoComplete.VersionCondition ) ) result ~= getVersionIncludes( _child );
								}
								else
								{
									result ~= getVersionIncludes( _child );
								}
							}
						}
					}
				}
				else if( _child.kind & B_INCLUDE )
				{
					result ~= _child;
				}
			}
			version(DIDE)
			{
				if( _child.kind & D_VERSION )
				{
					version(Windows)
					{
						if( _child.name == "Windows" || _child.name == "Win32" || ( _child.name == "-else-" && _child.base == "linux" ) )
						{
							result ~= getVersionIncludes( _child );
							continue;
						}
					}

					version(linux)
					{
						if( _child.name == "linux" || ( _child.name == "-else-" && _child.base != "linux" ) )
						{
							result ~= getVersionIncludes( _child );
							continue;
						}
					}				
				
					if( _child.name != "-else-" )
					{
						if( _child.name in AutoComplete.VersionCondition ) result ~= getVersionIncludes( _child );
					}
					else
					{
						if( !( _child.base in AutoComplete.VersionCondition ) ) result ~= getVersionIncludes( _child );
					}
				}
				else if( _child.kind & D_IMPORT )
				{
					result ~= _child;
				}					
			}
		}
		
		return result;
	}
	
	
	string[] preParseFiles( string[] inFiles, int level )
	{
		string[] beParsedFiles;
		
		string plusSign;
		for( int i = 0; i < level; ++ i)
			plusSign ~= "+";
		
		foreach( s; inFiles )
		{
			bool bInParserManager = ( fullPathByOS(s) in GLOBAL.parserManager ) ? true : false;

			CASTnode Root = ParserAction.loadParser( s, true );
			if( Root !is null )
			{
				if( !bInParserManager )
				{
					GLOBAL.messagePanel.printOutputPanel( "  " ~ plusSign ~ "[ " ~ s ~ " ]...Parsed" );

					string includeFullPath;
					version(FBIDE)
					{
						CASTnode[] includeNodes = getVersionIncludes( Root );
						foreach( CASTnode _node; includeNodes )
						{
							includeFullPath = AutoComplete.checkIncludeExist( _node.name, Root.name );
							if( includeFullPath.length ) beParsedFiles ~= includeFullPath;									
						}
					}
					version(DIDE)
					{
						CASTnode[] includeNodes = getVersionIncludes( Root );
						foreach( CASTnode _node; includeNodes )
						{
							if( _node.type.length )
							{
								//results ~= check( _node.type, cwdPath, bCheckOnlyOnce );
								includeFullPath = AutoComplete.checkIncludeExist( _node.type, Root.type );
								if( includeFullPath.length ) beParsedFiles ~= includeFullPath;									
							}
							else
							{
								//results ~= check( _node.name, cwdPath, bCheckOnlyOnce );
								includeFullPath = AutoComplete.checkIncludeExist( _node.name, Root.type );
								if( includeFullPath.length ) beParsedFiles ~= includeFullPath;									
							}
						}					
					}
				}
			}

		}
		
		return beParsedFiles;
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
		IupSetStrAttribute( projectToolBarBox, "BGCOLOR", toStringz( GLOBAL.editColor.projectBack ) );	
		IupSetStrAttributeId( tree, "COLOR", 0, toStringz( GLOBAL.editColor.projectFore ) );
		IupSetStrAttribute( tree, "FGCOLOR", toStringz( GLOBAL.editColor.projectFore ) );
		IupSetStrAttribute( tree, "BGCOLOR", toStringz( GLOBAL.editColor.projectBack ) );
		IupSetStrAttribute( tree, "HLCOLOR", toStringz( GLOBAL.editColor.prjViewHLT ) );
		version(Windows)
		{
			tools.setWinTheme( tree, "Explorer", GLOBAL.editorSetting00.UseDarkMode == "ON" ? true : false );
			tools.setDarkMode4Dialog( projectToolBarBox, GLOBAL.editorSetting00.UseDarkMode == "ON" ? true : false );
		}
		for( int i = 1; i < IupGetInt( tree, "COUNT" ); ++ i )
		{
			if( IupGetIntId( tree, "DEPTH", i ) == 1 )
			{
				IupSetStrAttributeId( tree, "COLOR", i, toStringz( GLOBAL.editColor.prjTitle ) );
				IupSetAttributeId( tree, "IMAGE", i, "icon_prj" );
				IupSetAttributeId( tree, "IMAGEEXPANDED", i, "icon_prj_open" );
			}
			else if( IupGetIntId( tree, "DEPTH", i ) == 2 )
			{
				IupSetStrAttributeId( tree, "COLOR", i, toStringz( GLOBAL.editColor.prjSourceType ) );
				IupSetAttributeId( tree, "IMAGE", i, "icon_door" );
				IupSetAttributeId( tree, "IMAGEEXPANDED", i, "icon_dooropen" );
			}
			else
			{
				IupSetStrAttributeId( tree, "COLOR", i, toStringz( GLOBAL.editColor.projectFore ) );
				string _fp = fSTRz( IupGetAttributeId( tree, "TITLE", i ) );
				version(FBIDE)
				{
					switch( toLower( Path.extension( _fp ) ) )
					{
						case ".bas":
							IupSetAttributeId( tree, "IMAGE", i, "icon_bas" );	break;
						case ".bi":
							IupSetAttributeId( tree, "IMAGE", i, "icon_bi" );	break;
						default:
							IupSetAttributeId( tree, "IMAGE", i, "icon_txt" );
					}
				}
				
				version(DIDE)
				{
					switch( toLower( Path.extension( _fp ) ) )
					{
						case ".d":
							IupSetAttributeId( tree, "IMAGE", i, "icon_bas" );	break;
						case ".di":
							IupSetAttributeId( tree, "IMAGE", i, "icon_bi" );	break;
						default:
							IupSetAttributeId( tree, "IMAGE", i, "icon_txt" );
					}
				}
			}
		}
	}


	void createProjectTree( string setupDir )
	{
		string prjDirName = GLOBAL.projectManager[setupDir].dir ~ "/";
		
		// Add Project's Name to Tree
		IupSetStrAttribute( tree, "ADDBRANCH0", toStringz( GLOBAL.projectManager[setupDir].name ) );
		IupSetAttribute( tree, "IMAGE1", "icon_packageexplorer" );
		IupSetAttribute( tree, "IMAGEEXPANDED1", "icon_prj_open" );
		version(Windows) IupSetAttributeId( tree, "MARKED", 1, "YES" ); else IupSetInt( tree, "VALUE", 1 );
		IupSetAttributeId( tree, "USERDATA", 1, tools.getCString( setupDir ) );
		IupSetStrAttributeId( tree, "COLOR", 1, toStringz( GLOBAL.editColor.prjTitle ) );
		toBoldTitle( tree, 1 );
		
		// Miscellaneous
		IupSetAttribute( tree, "ADDBRANCH1", "Miscellaneous" );
		IupSetStrAttributeId( tree, "COLOR", 2, toStringz( GLOBAL.editColor.prjSourceType ) );
		IupSetAttribute( tree, "IMAGE2", "icon_door" );
		IupSetAttribute( tree, "IMAGEEXPANDED2", "icon_dooropen" );
		toBoldTitle( tree, 2 );
		
		// Create Sub Dir
		foreach_reverse( s; GLOBAL.projectManager[setupDir].misc )
			_createTree( prjDirName, s );
			
		foreach_reverse( s; GLOBAL.projectManager[setupDir].misc )
		{
			string		userData = s;
			int			folderLocateId = _createTree( prjDirName, s );
			
			if( IupGetIntId( tree, "CHILDCOUNT", folderLocateId ) > 0 )
			{
				folderLocateId = IupGetIntId( tree, "LAST", folderLocateId + 1 );
				IupSetStrAttributeId( tree, "INSERTLEAF", folderLocateId, toStringz( s ) );
				int insertID = IupGetInt( tree, "LASTADDNODE" );
				IupSetStrAttributeId( tree, "COLOR", insertID, toStringz( GLOBAL.editColor.projectFore ) );
				IupSetAttributeId( tree, "IMAGE", insertID, "icon_txt" );
				IupSetAttributeId( tree, "USERDATA", insertID, tools.getCString( userData ) ); // Allocate memory to save files's fullpath 
			}
			else
			{
				IupSetStrAttributeId( tree, "ADDLEAF", folderLocateId, toStringz( s ) );
				IupSetStrAttributeId( tree, "COLOR", folderLocateId + 1, toStringz( GLOBAL.editColor.projectFore ) );
				IupSetAttributeId( tree, "IMAGE", folderLocateId + 1, "icon_txt" );
				IupSetAttributeId( tree, "USERDATA", folderLocateId + 1, tools.getCString( userData ) ); // Allocate memory to save files's fullpath 
			}
		}		
		
		IupSetAttribute( tree, "ADDBRANCH1", "Others" );
		IupSetStrAttributeId( tree, "COLOR", 2, toStringz( GLOBAL.editColor.prjSourceType ) );
		IupSetAttribute( tree, "IMAGE2", "icon_door" );
		IupSetAttribute( tree, "IMAGEEXPANDED2", "icon_dooropen" );
		toBoldTitle( tree, 2 );

		// Create Sub Dir
		foreach_reverse( s; GLOBAL.projectManager[setupDir].others )
			_createTree( prjDirName, s );
			
		foreach_reverse( s; GLOBAL.projectManager[setupDir].others )
		{
			string		userData = s;
			int			folderLocateId = _createTree( prjDirName, s );
			
			if( IupGetIntId( tree, "CHILDCOUNT", folderLocateId ) > 0 )
			{
				folderLocateId = IupGetIntId( tree, "LAST", folderLocateId + 1 );
				IupSetStrAttributeId( tree, "INSERTLEAF", folderLocateId, toStringz( s ) );
				int insertID = IupGetInt( tree, "LASTADDNODE" );
				IupSetStrAttributeId( tree, "COLOR", insertID, toStringz( GLOBAL.editColor.projectFore ) );
				IupSetAttributeId( tree, "IMAGE", insertID, "icon_txt" );
				IupSetAttributeId( tree, "USERDATA", insertID, tools.getCString( userData ) ); // Allocate memory to save files's fullpath 
			}
			else
			{
				IupSetStrAttributeId( tree, "ADDLEAF", folderLocateId, toStringz( s ) );
				IupSetStrAttributeId( tree, "COLOR", folderLocateId + 1, toStringz( GLOBAL.editColor.projectFore ) );
				IupSetAttributeId( tree, "IMAGE", folderLocateId + 1, "icon_txt" );
				IupSetAttributeId( tree, "USERDATA", folderLocateId + 1, tools.getCString( userData ) ); // Allocate memory to save files's fullpath 
			}
		}


		
		IupSetAttribute( tree, "ADDBRANCH1", "Includes" );
		IupSetStrAttributeId( tree, "COLOR", 2, toStringz( GLOBAL.editColor.prjSourceType ) );
		IupSetAttribute( tree, "IMAGE2", "icon_door" );
		IupSetAttribute( tree, "IMAGEEXPANDED2", "icon_dooropen" );
		toBoldTitle( tree, 2 );
		
		// Create Sub Dir
		foreach_reverse( s; GLOBAL.projectManager[setupDir].includes )
			_createTree( prjDirName, s );
			
		foreach( s; GLOBAL.projectManager[setupDir].includes )
		{
			string		userData = s;
			int			folderLocateId = _createTree( prjDirName, s );
			
			if( IupGetIntId( tree, "CHILDCOUNT", folderLocateId ) > 0 )
			{
				folderLocateId = IupGetIntId( tree, "LAST", folderLocateId + 1 );
				IupSetStrAttributeId( tree, "INSERTLEAF", folderLocateId, toStringz( s ) );
				int insertID = IupGetInt( tree, "LASTADDNODE" );
				IupSetStrAttributeId( tree, "COLOR", insertID, toStringz( GLOBAL.editColor.projectFore ) );
				IupSetAttributeId( tree, "IMAGE", insertID, "icon_bi" );
				IupSetAttributeId( tree, "USERDATA", insertID, tools.getCString( userData ) );
			}
			else
			{
				IupSetStrAttributeId( tree, "ADDLEAF", folderLocateId, toStringz( s ) );
				IupSetStrAttributeId( tree, "COLOR", folderLocateId + 1, toStringz( GLOBAL.editColor.projectFore ) );
				IupSetAttributeId( tree, "IMAGE", folderLocateId + 1, "icon_bi" );
				IupSetAttributeId( tree, "USERDATA", folderLocateId + 1, tools.getCString( userData ) );
			}
		}



		IupSetAttribute( tree, "ADDBRANCH1", "Sources" );
		IupSetStrAttributeId( tree, "COLOR", 2, toStringz( GLOBAL.editColor.prjSourceType ) );
		toBoldTitle( tree, 2 );
		IupSetAttribute( tree, "IMAGE2", "icon_door" );
		IupSetAttribute( tree, "IMAGEEXPANDED2", "icon_dooropen" );
		
		// Create Sub Dir
		foreach_reverse( s; GLOBAL.projectManager[setupDir].sources )
			_createTree( prjDirName, s );
		
		foreach( s; GLOBAL.projectManager[setupDir].sources )
		{
			string		userData = s;
			int			folderLocateId = _createTree( prjDirName, s );
			
			if( IupGetIntId( tree, "CHILDCOUNT", folderLocateId ) > 0 )
			{
				folderLocateId = IupGetIntId( tree, "LAST", folderLocateId + 1 );
				IupSetStrAttributeId( tree, "INSERTLEAF", folderLocateId, toStringz( s ) );
				int insertID = IupGetInt( tree, "LASTADDNODE" );
				IupSetStrAttributeId( tree, "COLOR", insertID, toStringz( GLOBAL.editColor.projectFore ) );
				IupSetAttributeId( tree, "IMAGE", insertID, "icon_bas" );
				IupSetAttributeId( tree, "USERDATA", insertID, tools.getCString( userData ) );
			}
			else
			{
				IupSetStrAttributeId( tree, "ADDLEAF", folderLocateId, toStringz( s ) );
				IupSetStrAttributeId( tree, "COLOR", folderLocateId + 1, toStringz( GLOBAL.editColor.projectFore ) );
				IupSetAttributeId( tree, "IMAGE", folderLocateId + 1, "icon_bas" );
				IupSetAttributeId( tree, "USERDATA", folderLocateId + 1, tools.getCString( userData ) );
			}
		}

		// Switch to project tree tab
		IupSetAttribute( GLOBAL.projectViewTabs, "VALUEPOS", "0" );

		IupSetAttribute( tree, "MARK", "CLEARALL" );
		
		// Set Focus to Project Tree
		IupSetAttributeId( tree, "MARKED", 1, "YES" );
		IupSetInt( tree, "VALUE", 1 );

		// Recent Projects
		GLOBAL.projectTree.updateRecentProjects( setupDir, GLOBAL.projectManager[setupDir].name );
		GLOBAL.statusBar.setPrjName( null, true );
		
		if( IupGetInt( tree, "COUNT" ) > 1 ) IupSetAttribute( projectButtonCollapse, "VISIBLE", "YES" );
	}

	void CreateNewProject( string prjName, string prjDir )
	{
		//GLOBAL.activeProjectDirName = prjDir;
		IupSetAttribute( GLOBAL.projectTree.getTreeHandle, "MARK", "CLEARALL" ); // For projectTree MULTIPLE Selection

		IupSetStrAttribute( tree, "ADDBRANCH0", toStringz( prjName ) );
		version(Windows) IupSetAttributeId( tree, "MARKED", 1, "YES" ); else IupSetInt( tree, "VALUE", 1 );
		IupSetAttribute( tree, "USERDATA1", tools.getCString( prjDir ) );
		IupSetAttribute( tree, "IMAGE1", "icon_packageexplorer" );
		IupSetAttribute( tree, "IMAGEEXPANDED1", "icon_prj_open" );		
		IupSetStrAttributeId( tree, "COLOR", 1, toStringz( GLOBAL.editColor.prjTitle ) );
		toBoldTitle( tree, 1 );

		IupSetAttribute( tree, "ADDBRANCH1", "Miscellaneous" );
		IupSetStrAttributeId( tree, "COLOR", 2, toStringz( GLOBAL.editColor.prjSourceType ) );
		IupSetAttribute( tree, "IMAGE2", "icon_door" );
		IupSetAttribute( tree, "IMAGEEXPANDED2", "icon_dooropen" );
		toBoldTitle( tree, 2 );
		
		IupSetAttribute( tree, "ADDBRANCH1", "Others" );
		IupSetStrAttributeId( tree, "COLOR", 2, toStringz( GLOBAL.editColor.prjSourceType ) );
		IupSetAttribute( tree, "IMAGE2", "icon_door" );
		IupSetAttribute( tree, "IMAGEEXPANDED2", "icon_dooropen" );
		toBoldTitle( tree, 2 );
		
		IupSetAttribute( tree, "ADDBRANCH1", "Includes" );
		IupSetStrAttributeId( tree, "COLOR", 2, toStringz( GLOBAL.editColor.prjSourceType ) );
		IupSetAttribute( tree, "IMAGE2", "icon_door" );
		IupSetAttribute( tree, "IMAGEEXPANDED2", "icon_dooropen" );
		toBoldTitle( tree, 2 );
		
		IupSetAttribute( tree, "ADDBRANCH1", "Sources" );
		IupSetStrAttributeId( tree, "COLOR", 2, toStringz( GLOBAL.editColor.prjSourceType ) );
		IupSetAttribute( tree, "IMAGE2", "icon_door" );
		IupSetAttribute( tree, "IMAGEEXPANDED2", "icon_dooropen" );
		toBoldTitle( tree, 2 );
		// Set Focus to Project Tree
		IupSetAttribute( GLOBAL.projectViewTabs, "VALUE_HANDLE", cast(char*) tree );
		
		if( IupGetInt( tree, "COUNT" ) > 1 ) IupSetAttribute( projectButtonCollapse, "VISIBLE", "YES" );
	}

	bool openProject( string setupDir = null, bool bAskCreateNew = false )
	{
		if( !setupDir.length )
		{
			scope fileSelectDlg = new CFileDlg( GLOBAL.languageItems["caption_openprj"].toDString ~ "...", null, "DIR" );
			setupDir = fileSelectDlg.getFileName();
		}

		if( !setupDir.length ) return false;

		setupDir = tools.normalizeSlash( setupDir );
		
		if( setupDir in GLOBAL.projectManager )
		{
			tools.MessageDlg( GLOBAL.languageItems["alarm"].toDString, "\"" ~ setupDir ~ "\"\n" ~ GLOBAL.languageItems["opened"].toDString, "WARNING", "", IUP_MOUSEPOS, IUP_MOUSEPOS );
			return true;
		}

		
		version(FBIDE)	string sFN = setupDir ~ "/FB.poseidon";
		version(DIDE)	string sFN = setupDir ~ "/D.poseidon";

		if( std.file.exists( sFN ) )
		{
			PROJECT		p;
			GLOBAL.projectManager[setupDir] = p.loadFile( sFN );

			if( !GLOBAL.projectManager[setupDir].dir.length )
			{
				GLOBAL.projectManager.remove( setupDir );
				tools.MessageDlg( GLOBAL.languageItems["error"].toDString, GLOBAL.languageItems[".poseidonbroken"].toDString, "ERROR", "", IUP_MOUSEPOS, IUP_MOUSEPOS );
				return false;
			}

			createProjectTree( setupDir );
			
			// PreLoad, Load all files in project parser
			if( GLOBAL.enableParser == "ON" && GLOBAL.preParseLevel > 0 )
			{
				GLOBAL.activeProjectPath = setupDir;
				GLOBAL.compilerSettings.activeCompiler = getActiveCompilerInformation( GLOBAL.projectManager[setupDir].dir );

				if( GLOBAL.togglePreLoadPrj == "ON" )
				{
					if( fromStringz( IupGetAttribute( GLOBAL.menuMessageWindow, "VALUE" ) ) == "OFF" )
					{
						IupSetAttribute( GLOBAL.menuMessageWindow, "VALUE", "ON" );
						IupSetInt( GLOBAL.messageSplit, "BARSIZE", std.conv.to!(int)( GLOBAL.editorSetting01.BarSize ) );
						IupSetInt( GLOBAL.messageSplit, "VALUE", GLOBAL.messageSplit_value );
						IupSetInt( GLOBAL.messageSplit, "ACTIVE", 1 );
					}
					IupSetInt( GLOBAL.messageWindowTabs, "VALUEPOS", 0 );				
				
					GLOBAL.statusBar.setPrjName( "Pre-Parse Project..." );
					GLOBAL.statusBar.setPrjName( "Pre-Parse Project..." );
					
					string[]		parsedFiles;
					GLOBAL.messagePanel.printOutputPanel( "Project { " ~ GLOBAL.projectManager[setupDir].name ~ " } Files Pre-Loading...", true );
					foreach( source; GLOBAL.projectManager[setupDir].sources ~ GLOBAL.projectManager[setupDir].includes ~ GLOBAL.projectManager[setupDir].misc ~ GLOBAL.projectManager[setupDir].others )
					{
						if( std.file.exists( source ) ) parsedFiles ~= source;
					}

					for( int i = 0; i <= GLOBAL.preParseLevel; ++i )
						parsedFiles = preParseFiles( parsedFiles, i );
				
					GLOBAL.messagePanel.printOutputPanel( "Project { " ~ GLOBAL.projectManager[setupDir].name ~ " } Pre-Loading Finished." );
				}

				GLOBAL.messagePanel.applyOutputPanelINDICATOR2();
				IupSetInt( GLOBAL.messagePanel.getOutputPanelHandle, "CARETPOS", 99999999 );
			}
		}
		else
		{
			tools.MessageDlg( GLOBAL.languageItems["error"].toDString, "\"" ~ setupDir ~ "\"\n" ~ GLOBAL.languageItems[".poseidonlost"].toDString, "ERROR", "", IUP_MOUSEPOS, IUP_MOUSEPOS );
			if( bAskCreateNew )
			{
				if( std.file.exists( setupDir ) )
				{
					int result = tools.MessageDlg( GLOBAL.languageItems["alarm"].toDString, GLOBAL.languageItems["createnewone"].toDString );
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

		return true;
	}
	
	void closeProject()
	{
		string activePrjName = actionManager.ProjectAction.getActiveProjectName();

		if( activePrjName.length )
		{
			foreach( s; GLOBAL.projectManager[activePrjName].sources ~ GLOBAL.projectManager[activePrjName].includes ~ GLOBAL.projectManager[activePrjName].others ~ GLOBAL.projectManager[activePrjName].misc )
			{
				if( actionManager.ScintillaAction.closeDocument( s ) == IUP_IGNORE ) return;
			}
			
			DocumentTabAction.updateTabsLayout();			

			GLOBAL.projectManager[activePrjName].saveFile();
			GLOBAL.projectManager.remove( activePrjName );

			int countChild = IupGetInt( tree, "COUNT" );
			for( int i = 1; i <= countChild; ++ i )
			{
				int depth = IupGetIntId( tree, "DEPTH", i );
				if( depth == 1 )
				{
					try
					{
						if( fromStringz( IupGetAttributeId( tree, "USERDATA", i )) == activePrjName )
						{
							/*
							char* user = IupGetAttributeId( tree, "USERDATA", i );
							if( user != null )
							{
								delete user;
								user = null;
							}
							*/
							IupSetAttributeId( tree, "DELNODE", i, "SELECTED" );
							break;
						}
					}
					catch( Exception e ){}
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
		string[] prjsDir;
		
		foreach( p; GLOBAL.projectManager )
		{
			foreach( s; p.sources ~ p.includes ~ p.others ~ p.misc )
			{
				if( actionManager.ScintillaAction.closeDocument( s ) == IUP_IGNORE )
				{
					foreach( _s; prjsDir )
						GLOBAL.projectManager.remove( _s );

					
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
						string _cstring = fSTRz( IupGetAttributeId( tree, "USERDATA", i ) );
						if( _cstring == p.dir )
						{
							char* user = IupGetAttributeId( tree, "USERDATA", i );
							/*
							if( user != null )
							{
								delete user;
								user = null;
							}
							*/
							IupSetAttributeId( tree, "DELNODE", i, "SELECTED" );
							break;
						}
					}
					catch( Exception e ){}
				}
			}
		}

		foreach( s; prjsDir )
		{
			GLOBAL.projectManager.remove( s );
		}

		if( IupGetInt( tree, "COUNT" ) == 1 )
		{
			GLOBAL.statusBar.setPrjName( "" );
			IupSetAttribute( projectButtonCollapse, "VISIBLE", "NO" );
		}
	}

	void updateRecentProjects( string prjDir, string prjName )
	{
		string title;
		
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
				destroy( GLOBAL.recentProjects[i] );
				
			int count, index;
			if( temps.length > 8 )
			{
				GLOBAL.recentProjects.length = 8;
				for( count = cast(int) temps.length - 8; count < temps.length; ++count )
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
				destroy( GLOBAL.recentProjects[i] );
				
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
			IupSetAttribute(_clearRecentPrjs, "IMAGE", "icon_deleteall");
			IupSetCallback( _clearRecentPrjs, "ACTION", cast(Icallback) &menu.submenuRecentPrjsClear_click_cb );
			IupInsert( recentPrj_ih, null, _clearRecentPrjs );
			IupMap( IupGetChild( recentPrj_ih, 0 ) );
			if( GLOBAL.recentProjects.length )
			{
				IupInsert( recentPrj_ih, null, IupSeparator() );
				IupMap( IupGetChild( recentPrj_ih, 0 ) );
			}
	
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
					version(Windows) if( GLOBAL.bCanUseDarkMode ) IupSetStrAttributeId( ih, "COLOR", id, toStringz( tools.invertColor( GLOBAL.editColor.prjViewHLT ) ) );
					
					char*	_fullpath = IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id );
					
					if( _fullpath != null )
					{
						string fullPath = fSTRz( _fullpath );

						if( fullPathByOS(fullPath) in GLOBAL.scintillaManager ) 
						{
							actionManager.ScintillaAction.openFile( fullPath );
							return IUP_IGNORE;
						}
					}
					else
					{
						return IUP_IGNORE;
					}
					
					string _selectedStatus = fSTRz( IupGetAttribute( GLOBAL.projectTree.getTreeHandle,"MARKEDNODES" ) );
					for( int i = 0; i < _selectedStatus.length; ++ i )
					{
						if( _selectedStatus[i] == '+' )
						{
							if( fromStringz( IupGetAttributeId( ih, "KIND", i ) ) == "BRANCH" ) IupSetAttributeId( ih, "MARKED", i, "NO" );
						}
					}
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

					GLOBAL.statusBar.setPrjName( to!(string)( id ), true );
				}
				else
				{
					GLOBAL.statusBar.setPrjName( "                                            " );
				}
			}
			catch( Exception e )
			{
				IupMessage( "CProjectTree_Selection_cb", toStringz( "CProjectTree_Selection_cb Error\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ to!(string)( e.line ) ) );
			}
		}
		else
		{
			version(Windows)
			{
				if( GLOBAL.bCanUseDarkMode )
					if( fromStringz( IupGetAttributeId( ih, "KIND", id ) ) == "LEAF" ) IupSetStrAttributeId( ih, "COLOR", id, toStringz( GLOBAL.editColor.projectFore ) );
			}
		}

		return IUP_DEFAULT;
	}

	private int CProjectTree_BUTTON_CB( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		if( pressed == 1 )
		{
			if( button == IUP_BUTTON1 ) // Left Click
			{
				if( DocumentTabAction.isDoubleClick( status ) )
				{
					CProjectTree_Open_cb( ih );
					return IUP_IGNORE;
				}
			}
		}
		return IUP_DEFAULT;
	}
	
	private int CProjectTree_NodeRemoved_cb( Ihandle *ih, void* userdata )
	{
		char* dataPointer = cast(char*) userdata;
		if( dataPointer != null ) tools.freeCString( dataPointer );

		return IUP_DEFAULT;
	}
	
	private int CProjectTree_MULTISELECTION_CB( Ihandle *ih, int* ids, int n )
	{
		string status = fSTRz( IupGetAttribute(ih,"MARKEDNODES") );
		for( int i = 0; i < status.length; ++ i )
		{
			if( status[i] == '+' )
			{
				if( fromStringz( IupGetAttributeId( ih, "KIND", i ) ) == "BRANCH" )
					IupSetAttributeId( ih, "MARKED", i, "NO" );
				else
				{
					version(Windows) if( GLOBAL.bCanUseDarkMode ) IupSetStrAttributeId( ih, "COLOR", i, toStringz( tools.invertColor( GLOBAL.editColor.prjViewHLT ) ) );
				}
			}
		}
		
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
				version(Windows)
				{
					if( fromStringz( IupGetAttributeId( ih, "KIND", i ) ) == "LEAF" )
						if( GLOBAL.bCanUseDarkMode ) IupSetStrAttributeId( ih, "COLOR", i, toStringz( GLOBAL.editColor.projectFore ) );				
				}
			}
			
			for( int i = 0; i < status.length; ++ i )
			{
				if( status[i] == '+' )
				{
					if( fromStringz( IupGetAttributeId( ih, "KIND", i ) ) == "LEAF" )
					{
						string fullPath = fSTRz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", i ) );
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


	private int CProjectTree_RightClick_cb( Ihandle *ih, int id )
	{
		version(Windows) ProjectAction.clearDarkModeNodesForeColor();
	
		if( fromStringz( IupGetAttributeId( ih, "MARKED", id ) ) == "NO" )
		{
			IupSetAttribute( ih, "MARK", "CLEARALL" );
			IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "MARKED", id, "YES" );
		}
		IupSetInt( GLOBAL.projectTree.getTreeHandle, "VALUE", id );

		string nodeKind = fSTRz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "KIND", id ) );

		if( nodeKind == "LEAF" ) // On File(*.bas, *.bi) Node
		{
			Ihandle* popupMenu;
			
			string 	titleFP				= fSTRz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "TITLE", id ) );
			int		typeID				= actionManager.ProjectAction.getTargetDepthID( 2 );
			string	prjFilesFolderName	= fSTRz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "TITLE", typeID ) ); // = Sources or Includes or Others or Miscellaneous
			
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
											null
										);
					IupSetFunction( "CProjectTree_openin", cast(Icallback) &CProjectTree_Openin_cb );
					break;
					
				default:
					if( isParsableExt( Path.extension( titleFP ), 7 ) )
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
				IupSetAttribute(itemNewProject, "IMAGE", "icon_packageexplorer");
				IupSetCallback( itemNewProject, "ACTION", cast(Icallback) &menu.newProject_cb ); // From menu.d
				
				Ihandle* itemOpenProject = IupItem( GLOBAL.languageItems["openprj"].toCString, null );
				IupSetAttribute(itemOpenProject, "IMAGE", "icon_openprj");
				IupSetCallback( itemOpenProject, "ACTION", cast(Icallback) &menu.openProject_cb ); // From menu.d

				Ihandle* itemCloseAllProject = IupItem( GLOBAL.languageItems["closeallprj"].toCString, null );
				IupSetAttribute(itemCloseAllProject, "IMAGE", "icon_deleteall");
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
					string fullPath = actionManager.ProjectAction.getActiveProjectName();
					version( Windows )
					{
						fullPath = Array.replace( fullPath, "/", "\\" );
						IupExecute( "explorer", toStringz( "\"" ~ fullPath ~ "\"" ) );
					}
					else
					{
						IupExecute( "xdg-open", toStringz( "\"" ~ fullPath ~ "\"" ) );
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

			//case 2:		// On Source or Include Node
			default:
				string s = fSTRz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id ) );
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
				IupSetCallback( itemAdd, "ACTION", cast(Icallback) &CProjectTree_AddFile_cb );

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
		}

		return IUP_DEFAULT;
	}

	private int CProjectTree_NewFile_cb( Ihandle* ih )
	{
		// Open Dialog Window
		scope test = new CSingleTextDialog( -1, -1, GLOBAL.languageItems["newfile"].toDString(), GLOBAL.languageItems["filename"].toDString() ~ ":", "120x", null, false, "POSEIDON_MAIN_DIALOG", "icon_newfile", false );
		string fileName = test.show( IUP_MOUSEPOS, IUP_MOUSEPOS );

		if( fileName.length )
		{
			// Get Depth
			string		prjFilesFolderName;
			string[] 	stepFolder;
			
			int 		id		= IupGetInt( GLOBAL.projectTree.getTreeHandle, "VALUE" ); // Get Focus TreeNode
			int 		depth	= IupGetIntId( GLOBAL.projectTree.getTreeHandle, "DEPTH", id );
			
			if( depth >= 2 ) // Under Branch of Branch
			{
				while( depth > 2 )
				{
					stepFolder ~= fSTRz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "TITLE", id ) );
					
					id = IupGetIntId( GLOBAL.projectTree.getTreeHandle, "PARENT", id );
					depth = IupGetIntId( GLOBAL.projectTree.getTreeHandle, "DEPTH", id );
				}
				prjFilesFolderName = fSTRz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "TITLE", id ) ); // = Sources or Includes or Others
			}

			string activeProjectDirName = actionManager.ProjectAction.getActiveProjectName();
			string fullPath = activeProjectDirName ~ "/";
			
			foreach_reverse( s; stepFolder )
			{
				fullPath = fullPath ~ s ~ "/";
			}

			fullPath ~= fileName;
			if( std.file.exists( fullPath ) )
			{
				tools.MessageDlg( GLOBAL.languageItems["alarm"].toDString, "\"" ~ fileName ~ "\"\n" ~ GLOBAL.languageItems["existed"].toDString, "WARNING", "", IUP_MOUSEPOS, IUP_MOUSEPOS );									
				return IUP_DEFAULT;
			}
			
			// Wrong Ext, exit!
			version(FBIDE)
			{
				switch( toLower( Path.extension( fullPath ) ) )
				{
					case ".bas":
						if( prjFilesFolderName != "Sources" )
						{
							tools.MessageDlg( GLOBAL.languageItems["error"].toDString, GLOBAL.languageItems["wrongext"].toDString, "ERROR", "", IUP_MOUSEPOS, IUP_MOUSEPOS );						
							return IUP_DEFAULT;
						}
						break;
					case ".bi":
						if( prjFilesFolderName != "Includes" )
						{
							tools.MessageDlg( GLOBAL.languageItems["error"].toDString, GLOBAL.languageItems["wrongext"].toDString, "ERROR", "", IUP_MOUSEPOS, IUP_MOUSEPOS );						
							return IUP_DEFAULT;
						}
						break;
					default:
						if( prjFilesFolderName != "Others" && prjFilesFolderName != "Miscellaneous" )
						{
							tools.MessageDlg( GLOBAL.languageItems["error"].toDString, GLOBAL.languageItems["wrongext"].toDString, "ERROR", "", IUP_MOUSEPOS, IUP_MOUSEPOS );												
							return IUP_DEFAULT;
						}
				}
			}
			version(DIDE)
			{
				switch( toLower( Path.extension( fullPath ) ) )
				{
					case ".d":
						if( prjFilesFolderName != "Sources" )
						{
							tools.MessageDlg( GLOBAL.languageItems["error"].toDString, GLOBAL.languageItems["wrongext"].toDString, "ERROR", "", IUP_MOUSEPOS, IUP_MOUSEPOS );												
							return IUP_DEFAULT;
						}
						break;
					case ".di":
						if( prjFilesFolderName != "Includes" )
						{
							tools.MessageDlg( GLOBAL.languageItems["error"].toDString, GLOBAL.languageItems["wrongext"].toDString, "ERROR", "", IUP_MOUSEPOS, IUP_MOUSEPOS );						
							return IUP_DEFAULT;
						}
						break;
					default:
						if( prjFilesFolderName != "Others" && prjFilesFolderName != "Miscellaneous" )
						{
							tools.MessageDlg( GLOBAL.languageItems["error"].toDString, GLOBAL.languageItems["wrongext"].toDString, "ERROR", "", IUP_MOUSEPOS, IUP_MOUSEPOS );						
							return IUP_DEFAULT;
						}
				}
			}

			// Get the parent folder name
			string dir = Path.dirName( fullPath );
			if( !std.file.exists( dir ) ) mkdir( dir ); // Create Folder On Disk

			version(Windows)
			{
				if( GLOBAL.editorSetting00.NewDocBOM == "ON" ) actionManager.ScintillaAction.newFile( fullPath, BOM.utf8, true ); else actionManager.ScintillaAction.newFile( fullPath, BOM.utf8, false );
			}
			else
			{
				actionManager.ScintillaAction.newFile( fullPath, BOM.utf8, false );
			}

			id = IupGetInt( GLOBAL.projectTree.getTreeHandle, "VALUE" ); // Re-Get Active Focus Node ID
			IupSetStrAttributeId( GLOBAL.projectTree.getTreeHandle, "ADDLEAF", id, toStringz( fileName ) );
			IupSetStrAttributeId( GLOBAL.projectTree.getTreeHandle, "COLOR", id + 1, toStringz( GLOBAL.editColor.projectFore ) );
			IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id + 1, tools.getCString( fullPath ) );

			switch( prjFilesFolderName )
			{
				case "Sources":
					GLOBAL.projectManager[activeProjectDirName].sources ~= fullPath;
					IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "IMAGE", id + 1, "icon_bas" );
					break;
				case "Includes":
					GLOBAL.projectManager[activeProjectDirName].includes ~= fullPath;
					IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "IMAGE", id + 1, "icon_bi" );
					break;
				case "Others":
					GLOBAL.projectManager[activeProjectDirName].others ~= fullPath;
					IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "IMAGE", id + 1, "icon_txt" );
					break;
				default:
					GLOBAL.projectManager[activeProjectDirName].misc ~= fullPath;
					IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "IMAGE", id + 1, "icon_txt" );
					break;
			}
		}
		
		return IUP_DEFAULT;
	}

	private int CProjectTree_NewFolder_cb( Ihandle* ih )
	{
		scope test = new CSingleTextDialog( -1, -1, GLOBAL.languageItems["newfolder"].toDString(), GLOBAL.languageItems["foldername"].toDString() ~ ":", "120x", null, false );
		string folderName = test.show( IUP_MOUSEPOS, IUP_MOUSEPOS );

		if( folderName.length )
		{
			// Get Focus Tree Node ID
			int id = IupGetInt( GLOBAL.projectTree.getTreeHandle, "VALUE" );

			// Get Focus Tree Node 
			string kind = fSTRz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "KIND", id ) );

			if( kind == "BRANCH" )
			{
				IupSetStrAttributeId( GLOBAL.projectTree.getTreeHandle, "ADDBRANCH", id, toStringz( folderName ) );
				IupSetStrAttributeId( GLOBAL.projectTree.getTreeHandle, "COLOR", id + 1, toStringz( GLOBAL.editColor.projectFore ) );
			}
		}
		
		return IUP_DEFAULT;
	}

	private int CProjectTree_AddFile_cb( Ihandle* ih )
	{
		try
		{
			int		id					= actionManager.ProjectAction.getTargetDepthID( 2 );
			string	prjFilesFolderName	= fSTRz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "TITLE", id ) ); // = Sources or Includes or Others
			string	prjDirName 			= actionManager.ProjectAction.getActiveProjectName();
			string	filter;

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
			foreach_reverse( fullPath; fileSecectDlg.getFilesName() )
			{
				if( fullPath.length )
				{
					if( !std.file.exists( fullPath ) )
					{
						tools.MessageDlg( GLOBAL.languageItems["alarm"].toDString, "\"" ~ fullPath ~ "\"\n" ~ GLOBAL.languageItems["existed"].toDString, "WARNING", "", IUP_MOUSEPOS, IUP_MOUSEPOS );
						return IUP_DEFAULT;
					}
					else
					{
						//Util.substitute( fullPath, "/", "\\" );
						bool bExitChildLoop;
						foreach( s; GLOBAL.projectManager[prjDirName].sources ~ GLOBAL.projectManager[prjDirName].includes ~ GLOBAL.projectManager[prjDirName].others ~ GLOBAL.projectManager[prjDirName].misc )
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
						switch( toLower( Path.extension( fullPath ) ) )
						{
							case ".bas":
								if( prjFilesFolderName != "Sources" )
								{
									tools.MessageDlg( GLOBAL.languageItems["error"].toDString, GLOBAL.languageItems["wrongext"].toDString, "ERROR", "", IUP_MOUSEPOS, IUP_MOUSEPOS );
									return IUP_DEFAULT;
								}
								else
								{
									GLOBAL.projectManager[prjDirName].sources ~= tools.normalizeSlash( fullPath );
								}
								break;
							case ".bi":
								if( prjFilesFolderName != "Includes" )
								{
									tools.MessageDlg( GLOBAL.languageItems["error"].toDString, GLOBAL.languageItems["wrongext"].toDString, "ERROR", "", IUP_MOUSEPOS, IUP_MOUSEPOS );
									return IUP_DEFAULT;
								}
								else
								{
									GLOBAL.projectManager[prjDirName].includes ~= tools.normalizeSlash( fullPath );
								}
								break;
							default:
								if( prjFilesFolderName == "Others" )
									GLOBAL.projectManager[prjDirName].others ~= tools.normalizeSlash( fullPath );
								else if( prjFilesFolderName == "Miscellaneous" )
									GLOBAL.projectManager[prjDirName].misc ~= tools.normalizeSlash( fullPath );
								else
								{
									tools.MessageDlg( GLOBAL.languageItems["error"].toDString, GLOBAL.languageItems["wrongext"].toDString, "ERROR", "", IUP_MOUSEPOS, IUP_MOUSEPOS );
									return IUP_DEFAULT;
								}
						}
					}
					version(DIDE)
					{
						switch( toLower( Path.extension( fullPath ) ) )
						{
							case ".d":
								if( prjFilesFolderName != "Sources" )
								{
									tools.MessageDlg( GLOBAL.languageItems["error"].toDString, GLOBAL.languageItems["wrongext"].toDString, "ERROR", "", IUP_MOUSEPOS, IUP_MOUSEPOS );
									return IUP_DEFAULT;
								}
								else
								{
									GLOBAL.projectManager[prjDirName].sources ~= tools.normalizeSlash( fullPath );
								}
								break;
							case ".di":
								if( prjFilesFolderName != "Includes" )
								{
									tools.MessageDlg( GLOBAL.languageItems["error"].toDString, GLOBAL.languageItems["wrongext"].toDString, "ERROR", "", IUP_MOUSEPOS, IUP_MOUSEPOS );
									return IUP_DEFAULT;
								}
								else
								{
									GLOBAL.projectManager[prjDirName].includes ~= tools.normalizeSlash( fullPath );
								}
								break;
							default:
								if( prjFilesFolderName == "Others" )
									GLOBAL.projectManager[prjDirName].others ~= tools.normalizeSlash( fullPath );
								else if( prjFilesFolderName == "Miscellaneous" )
									GLOBAL.projectManager[prjDirName].misc ~= tools.normalizeSlash( fullPath );
								else
								{
									tools.MessageDlg( GLOBAL.languageItems["error"].toDString, GLOBAL.languageItems["wrongext"].toDString, "ERROR", "", IUP_MOUSEPOS, IUP_MOUSEPOS );
									return IUP_DEFAULT;
								}
						}
					}

					string		titleName = tools.normalizeSlash( fullPath );
					int			folderLocateId = _createTree( prjDirName ~ "/", titleName, id );
					string		userData = fullPath;
					IupSetStrAttributeId( GLOBAL.projectTree.getTreeHandle, "ADDLEAF", folderLocateId, toStringz( titleName ) );
					IupSetStrAttributeId( GLOBAL.projectTree.getTreeHandle, "COLOR", folderLocateId + 1, toStringz( GLOBAL.editColor.projectFore ) );
					IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", folderLocateId + 1, tools.getCString( userData ) );

					switch( prjFilesFolderName )
					{
						case "Sources":		IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "IMAGE", folderLocateId + 1, "icon_bas" ); break;
						case "Includes":	IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "IMAGE", folderLocateId + 1, "icon_bi" ); break;
						default:			IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "IMAGE", folderLocateId + 1, "icon_txt" ); break;
					}
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
					string fullPath = fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", _i ) ).dup;
					if( std.file.exists( fullPath ) )
					{
						string ext = toLower( Path.extension( fullPath ) );
						
						// Version Condition
						version(FBIDE) int _options = 7; else int _options = 3;
						if( tools.isParsableExt( Path.extension( fullPath ), _options ) )
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
							version( Windows )
							{
								fullPath = Array.replace( fullPath, "/", "\\" );
								IupExecute( "cmd", toStringz( "/c \"" ~ fullPath ~ "\"" ) );
							}
							else
							{
								IupExecute( "xdg-open", toStringz( "\"" ~ fullPath ~ "\"" ) );
							}
						}
					}
					else
					{
						tools.MessageDlg( GLOBAL.languageItems["error"].toDString, fullPath ~ "\n" ~ GLOBAL.languageItems["filelost"].toDString, "ERROR", "", IUP_CENTERPARENT, IUP_CENTERPARENT );
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
					string fullPath = fSTRz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", _i ) );
					if( std.file.exists( fullPath ) )
					{
						if( selectedIDs.length == 1 )
							actionManager.ScintillaAction.openFile( fullPath, -1 );
						else
							actionManager.ScintillaAction.openFile( fullPath );
					}
					else
					{
						tools.MessageDlg( GLOBAL.languageItems["error"].toDString, fullPath ~ "\n" ~ GLOBAL.languageItems["filelost"].toDString, "ERROR", "", IUP_CENTERPARENT, IUP_CENTERPARENT );
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
				
				string	fullPath			= fSTRz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id ) );
				int		typeID				= actionManager.ProjectAction.getTargetDepthID( 2 );
				string	prjFilesFolderName	= fSTRz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "TITLE", typeID ) ); // = Sources or Includes or Others or Miscellaneous

				if( actionManager.ScintillaAction.closeDocument( fullPath ) == IUP_IGNORE ) return IUP_IGNORE;

				switch( prjFilesFolderName )
				{
					case "Sources":
						string[] temp;
						foreach( s; GLOBAL.projectManager[actionManager.ProjectAction.getActiveProjectName].sources )
							if( s != fullPath ) temp ~= s;
						GLOBAL.projectManager[actionManager.ProjectAction.getActiveProjectName].sources = temp;
						break;
						
					case "Includes":
						string[] temp;
						foreach( s; GLOBAL.projectManager[actionManager.ProjectAction.getActiveProjectName].includes )
							if( s != fullPath ) temp ~= s;
						GLOBAL.projectManager[actionManager.ProjectAction.getActiveProjectName].includes = temp;
						break;
						
					case "Others":
						string[] temp;
						foreach( s; GLOBAL.projectManager[actionManager.ProjectAction.getActiveProjectName].others )
							if( s != fullPath ) temp ~= s;
						GLOBAL.projectManager[actionManager.ProjectAction.getActiveProjectName].others = temp;
						break;

					case "Miscellaneous":
						string[] temp;
						foreach( s; GLOBAL.projectManager[actionManager.ProjectAction.getActiveProjectName].misc )
							if( s != fullPath ) temp ~= s;
						GLOBAL.projectManager[actionManager.ProjectAction.getActiveProjectName].misc = temp;
						break;
					default:
				}		

				char* user = IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id );
				/*
				if( user != null ) 
				{
					delete user;
					user = null;
				}
				*/
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
		string	fullPath			= fromStringz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id ) ).dup;

		// Erase Project Treeitems And Left Only One Item
		IupSetAttribute( GLOBAL.projectTree.getTreeHandle, "MARK", "CLEARALL" );
		IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "MARKED", id, "YES" );

		int _result = tools.MessageDlg( GLOBAL.languageItems["alarm"].toDString, GLOBAL.languageItems["suredelete"].toDString, "WARNING", "OKCANCEL", IUP_MOUSEPOS, IUP_MOUSEPOS );
		if( _result == 1 )
		{
			if( fullPath.length )
			{
				if( CProjectTree_remove_cb( ih ) == IUP_IGNORE ) return IUP_IGNORE;
				try
				{
					std.file.remove( fullPath );
				}
				catch( Exception e )
				{
					IupMessage( "ProjectTree Delete", toStringz( e.toString ) );
				}
			}
		}

		return IUP_DEFAULT;
	}

	private int CProjectTree_rename_cb( Ihandle* ih )
	{
		int		id			= IupGetInt( GLOBAL.projectTree.getTreeHandle, "VALUE" );
		string	fullPath	= fSTRz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id ) );
		
		// Erase Project Treeitems And Left Only One Item
		IupSetAttribute( GLOBAL.projectTree.getTreeHandle, "MARK", "CLEARALL" );
		IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "MARKED", id, "YES" );		

		string oldExt = Path.extension( fullPath );
		string _dirName = Path.dirName( fullPath );

		scope test = new CSingleTextDialog( -1, -1, GLOBAL.languageItems["rename"].toDString(), GLOBAL.languageItems["filename"].toDString() ~":", "120x", null, false );
		string newFileName = test.show( IUP_MOUSEPOS, IUP_MOUSEPOS );

		if( newFileName.length )
		{
			// Save Old File Changed
			if( fullPathByOS(fullPath) in GLOBAL.scintillaManager ) GLOBAL.scintillaManager[fullPathByOS(fullPath)].saveFile();

			// ReName On Disk & Change fn
			string newFullPath = _dirName ~ "/" ~ newFileName ~ oldExt;
			std.file.rename( fullPath, newFullPath );

			if( fullPathByOS(fullPath) in GLOBAL.scintillaManager ) 
			{
				GLOBAL.scintillaManager[fullPathByOS(fullPath)].rename( newFullPath );
			}

			
			char* pointer = IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id );
			if( pointer != null )
			{
				freeCString( pointer );
				pointer = null;
			}
			
			IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id, tools.getCString( newFullPath ) );
			IupSetStrAttributeId( GLOBAL.projectTree.getTreeHandle, "TITLE", id, toStringz( Path.baseName( newFullPath ) ) );

			string	activeProjectDirName = actionManager.ProjectAction.getActiveProjectName;
			int		typeID				= actionManager.ProjectAction.getTargetDepthID( 2 );
			string	prjFilesFolderName	= fSTRz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "TITLE", typeID ) ); // = Sources or Includes or Others or Miscellaneous
			
			switch( prjFilesFolderName )
			{
				case "Sources":
					string[] tempSources = GLOBAL.projectManager[activeProjectDirName].sources;
					GLOBAL.projectManager[activeProjectDirName].sources.length = 0;
					foreach( s; tempSources )
						if( s != fullPath ) GLOBAL.projectManager[activeProjectDirName].sources ~= s;else GLOBAL.projectManager[activeProjectDirName].sources ~= newFullPath;
					break;
					
				case "Includes":
					string[] tempIncludes = GLOBAL.projectManager[activeProjectDirName].includes;
					GLOBAL.projectManager[activeProjectDirName].includes.length = 0;
					foreach( s; tempIncludes )
						if( s != fullPath ) GLOBAL.projectManager[activeProjectDirName].includes ~= s;else GLOBAL.projectManager[activeProjectDirName].includes ~= newFullPath;
					break;
					
				case "Others":
					string[] tempOthers = GLOBAL.projectManager[activeProjectDirName].others;
					GLOBAL.projectManager[activeProjectDirName].others.length = 0;
					foreach( s; tempOthers )
						if( s != fullPath ) GLOBAL.projectManager[activeProjectDirName].others ~= s;else GLOBAL.projectManager[activeProjectDirName].others ~= newFullPath;
					break;

				case "Miscellaneous":
					string[] tempMisc = GLOBAL.projectManager[activeProjectDirName].misc;
					GLOBAL.projectManager[activeProjectDirName].misc.length = 0;
					foreach( s; tempMisc )
						if( s != fullPath ) GLOBAL.projectManager[activeProjectDirName].misc ~= s;else GLOBAL.projectManager[activeProjectDirName].misc ~= newFullPath;
					break;
				default:
			}				
		}
		
		return IUP_DEFAULT;
	}
	
	private int CProjectTree_setmainmodule_cb( Ihandle* ih )
	{
		int		id			= IupGetInt( GLOBAL.projectTree.getTreeHandle, "VALUE" );
		string	fullPath	= fSTRz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id ) );
		
		// Erase Project Treeitems And Left Only One Item
		IupSetAttribute( GLOBAL.projectTree.getTreeHandle, "MARK", "CLEARALL" );
		IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "MARKED", id, "YES" );
		
		string _prjName = ProjectAction.getActiveProjectName;
		if( _prjName in GLOBAL.projectManager )
		{
			string _mainModule = Path.stripExtension( fullPath );
			GLOBAL.projectManager[_prjName].mainFile = Array.replace( _mainModule, GLOBAL.projectManager[_prjName].dir ~ "/", "" );
		}

		return IUP_DEFAULT;
	}
	
	private int CProjectTree_importall_cb( Ihandle* ih )
	{
		int		id			= IupGetInt( GLOBAL.projectTree.getTreeHandle, "VALUE" );
		string	prjDirName	= fSTRz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", id ) );
		int		sourceID	= id + 1;
		int		includesID	= IupGetIntId( GLOBAL.projectTree.getTreeHandle, "NEXT", sourceID );
		
		if( prjDirName !in GLOBAL.projectManager ) return IUP_IGNORE;
		
		if( std.file.isDir( prjDirName ) )
		{
			string _ext;
			
			GLOBAL.projectManager[prjDirName].includes.length = 0;
			IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "DELNODE", includesID, "CHILDREN" ); // Delete All tree children
			
			version(FBIDE) _ext = "bi";	version(DIDE) _ext = "di";
			foreach( string s; dirEntries( prjDirName, "*.{" ~ _ext ~ "}", SpanMode.depth ) ) // or SpanMode.breadth
			{
				string 		titleName = tools.normalizeSlash( s );
				string		userData = titleName;
				int			folderLocateId = _createTree( prjDirName ~ "/", titleName, includesID ); // titleName will be changed

				GLOBAL.projectManager[prjDirName].includes ~= userData;
				
				IupSetStrAttributeId( GLOBAL.projectTree.getTreeHandle, "ADDLEAF", folderLocateId, toStringz( titleName ) );
				IupSetStrAttributeId( GLOBAL.projectTree.getTreeHandle, "COLOR", folderLocateId + 1, toStringz( GLOBAL.editColor.projectFore ) );
				IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", folderLocateId + 1, tools.getCString( userData ) );
				
				IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "IMAGE", folderLocateId + 1, "icon_bi" );
			}
			
			
			GLOBAL.projectManager[prjDirName].sources.length = 0;
			IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "DELNODE", sourceID, "CHILDREN" );

			version(FBIDE) _ext = "bas"; version(DIDE) _ext = "d";
			foreach( string s; dirEntries( prjDirName, "*.{" ~ _ext ~ "}", SpanMode.depth ) ) // or SpanMode.breadth
			{
				string 		titleName = tools.normalizeSlash( s );
				string		userData = titleName;
				int			folderLocateId = _createTree( prjDirName ~ "/", titleName, sourceID );
				
				GLOBAL.projectManager[prjDirName].sources ~= userData;

				IupSetStrAttributeId( GLOBAL.projectTree.getTreeHandle, "ADDLEAF", folderLocateId, toStringz( titleName ) );
				IupSetStrAttributeId( GLOBAL.projectTree.getTreeHandle, "COLOR", folderLocateId + 1, toStringz( GLOBAL.editColor.projectFore ) );
				IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "USERDATA", folderLocateId + 1, tools.getCString( userData ) );
				
				IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "IMAGE", folderLocateId + 1, "icon_bas" );
			}			
		}

		return IUP_DEFAULT;
	}	

	private int _createTree( string _prjDirName, ref string _titleName, int startID = 2 )
	{
		int		folderLocateId = startID;
		string	fullPath = tools.normalizeSlash( _titleName );

		auto pos = indexOf( fullPathByOS( fullPath ), fullPathByOS( _prjDirName ) );
		if( pos == 0 ) _titleName = fullPath[_prjDirName.length..$].dup;

		// Check the child Folder
		string[] splitText = Array.split( _titleName, "/" );
	
		int counterSplitText;
		for( counterSplitText = 0; counterSplitText < splitText.length - 1; ++counterSplitText )
		{
			if( splitText[counterSplitText].length )
			{
				int 	countChild = IupGetIntId( GLOBAL.projectTree.getTreeHandle, "TOTALCHILDCOUNT", folderLocateId );
				bool	bFolerExist = false;
				for( int i = 1; i <= countChild; ++ i )
				{
					string	kind = fSTRz( IupGetAttributeId( GLOBAL.projectTree.getTreeHandle, "KIND", folderLocateId + i ) );
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
					IupSetStrAttributeId( GLOBAL.projectTree.getTreeHandle, "ADDBRANCH", folderLocateId, toStringz( splitText[counterSplitText] ) );
					IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "IMAGE", folderLocateId + 1, "icon_folder" );
					IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "IMAGEEXPANDED", folderLocateId + 1, "icon_folder_open" );
					IupSetAttributeId( GLOBAL.projectTree.getTreeHandle, "COLOR", folderLocateId + 1, toStringz( GLOBAL.editColor.projectFore ) );
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