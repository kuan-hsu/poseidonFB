module layouts.filelistPanel;

private import iup.iup;

private import global, scintilla, actionManager, menu, tools;

private import tango.stdc.stringz;
private import tango.io.FilePath, Util = tango.text.Util, Integer = tango.text.convert.Integer;


class CFileList
{
	private:
	Ihandle*		layoutHandle, tree;

	void createLayout()
	{
		// Outline Toolbar
		Ihandle* filelistButtonCollapse = IupButton( null, "Collapse" );
		IupSetAttributes( filelistButtonCollapse, "ALIGNMENT=ARIGHT:ACENTER,FLAT=YES,IMAGE=icon_collapse,TIP=Collapse" );
		IupSetCallback( filelistButtonCollapse, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			Ihandle* _tree = GLOBAL.fileListTree.getTreeHandle();
			if( _tree != null )
				{
					
					if( fromStringz( IupGetAttributeId( _tree, "STATE", 0 ) ) == "EXPANDED" )
						IupSetAttribute( _tree, "EXPANDALL", "NO" );
					else
					{
						IupSetAttribute( _tree, "EXPANDALL", "YES" );
						IupSetAttribute( _tree, "TOPITEM", "YES" ); // Set position to top
					}
				}
			
		});

		scope string = new CstringConvert( "Show Fullpath" );

		Ihandle* filelistButtonFilename = IupButton( null, "Fullpath" );
		IupSetAttributes( filelistButtonFilename, "ALIGNMENT=ARIGHT:ACENTER,FLAT=YES,IMAGE=icon_show_p,TIP=FullPath" );
		IupSetCallback( filelistButtonFilename, "ACTION", cast(Icallback) &fileList_Filename_ACTION );


		Ihandle* filelistButtonHide = IupButton( null, "Hide" );
		IupSetAttributes( filelistButtonHide, "ALIGNMENT=ARIGHT:ACENTER,FLAT=YES,IMAGE=icon_debug_left,TIP=Hide" );
		IupSetCallback( filelistButtonHide, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			menu.outline_cb( GLOBAL.menuOutlineWindow );
		});


		Ihandle* labelSEPARATOR01 = IupLabel( null ); 
		IupSetAttribute( labelSEPARATOR01, "SEPARATOR", "VERTICAL");	
		

		Ihandle* filelistToolbarTitleImage = IupLabel( null );
		IupSetAttributes( filelistToolbarTitleImage, "IMAGE=icon_filelist,ALIGNMENT=ALEFT:ACENTER" );

		/*Ihandle* filelistToolbarTitle = IupLabel( " FileList" );
		IupSetAttribute( filelistToolbarTitle, "ALIGNMENT", "ACENTER:ALEFT" );*/

		Ihandle* filelistToolbarH = IupHbox( filelistToolbarTitleImage, /*filelistToolbarTitle,*/ IupFill, filelistButtonCollapse, filelistButtonFilename, labelSEPARATOR01, filelistButtonHide, null );
		IupSetAttributes( filelistToolbarH, "ALIGNMENT=ACENTER,SIZE=NULL" );

		tree = IupTree();
		IupSetAttributes( tree, "ADDROOT=YES,EXPAND=YES,TITLE=FileList,SIZE=NULL" );
		IupSetCallback( tree, "SELECTION_CB", cast(Icallback) &fileListNodeSelect_cb );
		//IupSetCallback( tree, "RIGHTCLICK_CB", cast(Icallback) &fileListNodeRightClick_cb );

		layoutHandle = IupVbox( filelistToolbarH, tree, null );
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

	void addItem( CScintilla _sci )
	{
		if( _sci !is null )
		{
			IupSetAttribute( tree, "ADDLEAF0", GLOBAL.cString.convert( _sci.getFullPath ) );
			IupSetAttribute( tree, "USERDATA1", cast(char*) _sci  );
			IupSetAttributeId( tree, "MARKED", 1, "YES" );
		}
	}

	void markItem( char[] fullPath )
	{
		for( int id = 1; id <= IupGetInt( tree, "COUNT" ); id++ ) // Not include Parent "FileList" node
		{
			CScintilla _sci_node = cast(CScintilla) IupGetAttributeId( tree, "USERDATA", id );
			if( _sci_node.getFullPath == fullPath )
			{
				IupSetAttributeId( tree, "MARKED", id, "YES" );
				break;
			}
		}
	}

	void markItem( CScintilla _sci )
	{
		if( _sci !is null ) markItem( _sci.getFullPath );
	}	

	void removeItem( char[] fullPath )
	{
		for( int id = 1; id <= IupGetInt( tree, "COUNT" ); id++ ) // Not include Parent "FileList" node
		{
			CScintilla _sci_node = cast(CScintilla) IupGetAttributeId( tree, "USERDATA", id );
			if( _sci_node.getFullPath == fullPath )
			{
				IupSetAttributeId( tree, "DELNODE", id, "SELECTED" );
				break;
			}			
		}
	}

	void removeItem( CScintilla _sci )
	{
		if( _sci !is null ) removeItem( _sci.getFullPath );
	}	
}


extern(C)
{
	// Open File...
	private int fileListNodeSelect_cb( Ihandle *ih, int id, int status )
	{
		if( id > 0 )
		{
			// SELECTION_CB will trigger 2 times, preSelect -> Select, we only catch second signal
			if( status == 1 )
			{
				CScintilla _sci = cast(CScintilla) IupGetAttributeId( ih, "USERDATA", id );
				ScintillaAction.openFile( _sci.getFullPath.dup );
			}
		}

		return IUP_DEFAULT;
	}

	private int fileList_Filename_ACTION( Ihandle *ih )
	{
		static state = 0;
		if( state == 1 ) showFullpath(); else showFilename();
		if( state == 1 ) state = 0; else state = 1;

		return IUP_DEFAULT;
	}

	//
	private void showFullpath()
	{
		int nodeCount = IupGetInt( GLOBAL.fileListTree.getTreeHandle, "COUNT" );
	
		for( int id = 1; id <= nodeCount; id++ ) // include Parent "FileList" node
		{
			CScintilla _sci = cast(CScintilla) IupGetAttributeId( GLOBAL.fileListTree.getTreeHandle, "USERDATA", id );
			if( _sci !is null)
			{
				IupSetAttributeId( GLOBAL.fileListTree.getTreeHandle, "TITLE" ,id, GLOBAL.cString.convert( _sci.getFullPath ) );
			}
		}
	}

	private void showFilename()
	{
		int nodeCount = IupGetInt( GLOBAL.fileListTree.getTreeHandle, "COUNT" );
	
		for( int id = 1; id <= nodeCount; id++ ) // include Parent "FileList" node
		{
			char* nodeTitle = IupGetAttributeId( GLOBAL.fileListTree.getTreeHandle, "TITLE", id );

			scope _fullPath = new FilePath( fromStringz( nodeTitle ).dup );
			char[] baseName = _fullPath.file();

			IupSetAttributeId( GLOBAL.fileListTree.getTreeHandle, "TITLE", id, GLOBAL.cString.convert( baseName ) );
		}		
	}

	/+
	// Show Fullpath or Filename
	private int fileListNodeRightClick_cb( Ihandle *ih, int id )
	{
		if( id == 0 )
		{
			IupSetAttributeId( ih, "MARKED", 0, "YES" );

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
	+/
}