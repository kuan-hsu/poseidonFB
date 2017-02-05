module layouts.filelistPanel;

private import iup.iup;

private import global, scintilla, actionManager, menu, tools;

private import tango.stdc.stringz;
private import tango.io.FilePath, Util = tango.text.Util, Integer = tango.text.convert.Integer;


class CFileList
{
	private:
	Ihandle*			layoutHandle, tree;
	int					fullPathState;
	CstringConvert[2]	cStrings;

	void createLayout()
	{
		cStrings[0] = new CstringConvert( GLOBAL.languageItems["fullpath"] );
		cStrings[1] = new CstringConvert( GLOBAL.languageItems["hide"] );
		
		// Outline Toolbar
		Ihandle* filelistButtonFilename = IupButton( null, null );
		IupSetAttributes( filelistButtonFilename, "ALIGNMENT=ARIGHT:ACENTER,FLAT=YES,IMAGE=icon_show_p" );
		IupSetAttribute( filelistButtonFilename, "TIP", cStrings[0].toStringz );
		IupSetCallback( filelistButtonFilename, "ACTION", cast(Icallback) &fileList_Filename_ACTION );

		Ihandle* filelistButtonHide = IupButton( null, null );
		IupSetAttributes( filelistButtonHide, "ALIGNMENT=ARIGHT:ACENTER,FLAT=YES,IMAGE=icon_shift_b" );
		IupSetAttribute( filelistButtonHide, "TIP", cStrings[1].toStringz );
		IupSetCallback( filelistButtonHide, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			IupSetInt( GLOBAL.fileListSplit, "VALUE", 1000 );
		});

		Ihandle* filelistToolbarTitleImage = IupLabel( null );
		IupSetAttributes( filelistToolbarTitleImage, "IMAGE=icon_filelist,ALIGNMENT=ALEFT:ACENTER" );

		Ihandle* filelistToolbarTitle = IupLabel( toStringz( GLOBAL.languageItems["filelist"] ) );
		IupSetAttribute( filelistToolbarTitle, "ALIGNMENT", "ACENTER:ALEFT" );

		Ihandle* filelistToolbarH = IupHbox( filelistToolbarTitleImage, filelistToolbarTitle, IupFill, filelistButtonFilename, filelistButtonHide, null );
		IupSetAttributes( filelistToolbarH, "ALIGNMENT=ACENTER,SIZE=NULL" );

		tree = IupTree();
		IupSetAttributes( tree, "ADDROOT=NO,EXPAND=YES,SIZE=NULL" );
		IupSetAttributes( tree, "SHOWDRAGDROP=YES" );
		version(Windows) IupSetAttribute( tree, "FGCOLOR", GLOBAL.editColor.filelistFore.toCString );
		version(Windows) IupSetAttribute( tree, "BGCOLOR", GLOBAL.editColor.filelistBack.toCString );		
		
		IupSetCallback( tree, "SELECTION_CB", cast(Icallback) &fileList_SELECTION_CB );
		IupSetCallback( tree, "DRAGDROP_CB", cast(Icallback) &fileList_DRAGDROP_CB );

		Ihandle* _v = IupVbox( filelistToolbarH, tree, null );
		IupSetAttributes( _v, GLOBAL.cString.convert( "ALIGNMENT=ARIGHT" ) );
		
		layoutHandle = IupBackgroundBox( _v );
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
		version(Windows) IupSetAttribute( tree, "BGCOLOR",  GLOBAL.editColor.filelistBack.toCString );
		for( int i = 0; i < IupGetInt( tree, "COUNT" ); ++ i )
		{
			IupSetAttributeId( tree, "COLOR", i, GLOBAL.editColor.filelistFore.toCString );
		}		
	}

	void addItem( CScintilla _sci )
	{
		if( _sci !is null )
		{
			if( GLOBAL.fileListTree.fullPathState == 0 )
			{
				IupSetAttributeId( tree, "ADDLEAF", -1, GLOBAL.cString.convert( _sci.getFullPath ) );
				IupSetAttributeId( tree, "COLOR", 0, GLOBAL.editColor.filelistFore.toCString );
			}
			else
			{
				scope _fullPath = new FilePath( _sci.getFullPath );
				IupSetAttributeId( tree, "ADDLEAF", -1, GLOBAL.cString.convert( _fullPath.file() ) );
				IupSetAttributeId( tree, "COLOR", 0, GLOBAL.editColor.filelistFore.toCString );
			}
			
			IupSetAttributeId( tree, "USERDATA", 0, cast(char*) _sci  );
			version(Windows) IupSetAttributeId( tree, "MARKED", 0, "YES" ); else IupSetInt( tree, "VALUE", 0 );
		}
	}

	void markItem( char[] fullPath )
	{
		for( int id = 0; id < IupGetInt( tree, "COUNT" ); id++ ) // Not include Parent "FileList" node
		{
			CScintilla _sci_node = cast(CScintilla) IupGetAttributeId( tree, "USERDATA", id );
			if( _sci_node.getFullPath == fullPath )
			{
				version(Windows) IupSetAttributeId( tree, "MARKED", id, "YES" ); else IupSetInt( tree, "VALUE", id );
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
		for( int id = 0; id < IupGetInt( tree, "COUNT" ); id++ ) // Not include Parent "FileList" node
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
	private int fileList_SELECTION_CB( Ihandle *ih, int id, int status )
	{
		if( id >= 0 )
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


	private int fileList_DRAGDROP_CB( Ihandle *ih, int drag_id, int drop_id, int isshift, int iscontrol )
	{

		CScintilla _sci = cast(CScintilla) IupGetAttributeId( ih, "USERDATA", drag_id );

		if( _sci !is null )
		{
			char[]		_title = fromStringz( IupGetAttributeId( ih, "TITLE", drag_id ) );

			GLOBAL.fileListTree.removeItem( _sci );

			if( drop_id < drag_id )
			{
				IupSetAttributeId( ih, "INSERTLEAF", drop_id ++, GLOBAL.cString.convert( _title ) );
			}
			else if( drop_id > drag_id )
			{
				IupSetAttributeId( ih, "INSERTLEAF", drop_id - 1, GLOBAL.cString.convert( _title ) );
			}
			else
			{
				return IUP_DEFAULT;
			}

			IupSetAttributeId( ih, "USERDATA", drop_id, cast(char*) _sci  );
			version(Windows) IupSetAttributeId( ih, "MARKED", drop_id, "YES" ); else IupSetInt( ih, "VALUE", drop_id );
		}

		return IUP_DEFAULT;
	}

	private int fileList_Filename_ACTION( Ihandle *ih )
	{
		if( GLOBAL.fileListTree.fullPathState == 1 ) showFullpath(); else showFilename();
		if( GLOBAL.fileListTree.fullPathState == 1 ) GLOBAL.fileListTree.fullPathState = 0; else GLOBAL.fileListTree.fullPathState = 1;

		return IUP_DEFAULT;
	}

	//
	private void showFullpath()
	{
		int nodeCount = IupGetInt( GLOBAL.fileListTree.getTreeHandle, "COUNT" );
	
		for( int id = 0; id < nodeCount; id++ ) // include Parent "FileList" node
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
	
		for( int id = 0; id < nodeCount; id++ ) // include Parent "FileList" node
		{
			char* nodeTitle = IupGetAttributeId( GLOBAL.fileListTree.getTreeHandle, "TITLE", id );

			scope _fullPath = new FilePath( fromStringz( nodeTitle ).dup );
			char[] baseName = _fullPath.file();

			IupSetAttributeId( GLOBAL.fileListTree.getTreeHandle, "TITLE", id, GLOBAL.cString.convert( baseName ) );
		}		
	}
}