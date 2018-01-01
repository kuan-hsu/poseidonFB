module layouts.filelistPanel;

private import iup.iup;

private import global, scintilla, actionManager, menu, tools;

private import tango.stdc.stringz;
private import tango.io.FilePath, Util = tango.text.Util, Integer = tango.text.convert.Integer;


class CFileList
{
	private:
	Ihandle*			layoutHandle, tree;
	Ihandle*			filelistToolbarTitle;
	int					fullPathState;

	void createLayout()
	{
		// Outline Toolbar
		Ihandle* filelistButtonFilename = IupButton( null, null );
		IupSetAttributes( filelistButtonFilename, "ALIGNMENT=ARIGHT:ACENTER,FLAT=YES,IMAGE=icon_show_p" );
		IupSetAttribute( filelistButtonFilename, "TIP", GLOBAL.languageItems["fullpath"].toCString );
		IupSetCallback( filelistButtonFilename, "ACTION", cast(Icallback) &fileList_Filename_ACTION );

		Ihandle* filelistButtonHide = IupButton( null, null );
		IupSetAttributes( filelistButtonHide, "ALIGNMENT=ARIGHT:ACENTER,FLAT=YES,IMAGE=icon_collapse2" );
		IupSetAttribute( filelistButtonHide, "TIP", GLOBAL.languageItems["collapse"].toCString );
		IupSetCallback( filelistButtonHide, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			if( GLOBAL.fileListTree.getTreeH() <= 1 )
			{
				IupSetAttribute( GLOBAL.fileListSplit, "VALUE", toStringz( GLOBAL.editorSetting01.FileListSplit ) );
			}
			else
			{
				GLOBAL.editorSetting01.FileListSplit = fromStringz( IupGetAttribute( GLOBAL.fileListSplit, "VALUE" ) );
				IupSetInt( GLOBAL.fileListSplit, "VALUE", 1000 );
			}
			return IUP_DEFAULT;
		});

		Ihandle* filelistToolbarTitleImage = IupLabel( null );
		IupSetAttributes( filelistToolbarTitleImage, "IMAGE=icon_filelist,ALIGNMENT=ALEFT:ACENTER" );

		filelistToolbarTitle = IupLabel( GLOBAL.languageItems["filelist"].toCString() );
		IupSetAttribute( filelistToolbarTitle, "SIZE", "100x8" );// Leftside
		setTitleFont();
		IupSetCallback( filelistToolbarTitle, "BUTTON_CB", cast(Icallback) &fileList_Empty_BUTTON_CB );

		Ihandle* filelistToolbarH = IupHbox( filelistToolbarTitleImage, filelistToolbarTitle, IupFill, filelistButtonFilename, filelistButtonHide, null );
		IupSetAttributes( filelistToolbarH, "ALIGNMENT=ACENTER,SIZE=NULL" );

		tree = IupTree();
		IupSetAttributes( tree, "ADDROOT=NO,EXPAND=YES,SIZE=NULL,BORDER=NO" );
		IupSetAttributes( tree, "SHOWDRAGDROP=YES" );
		version(Windows) IupSetAttribute( tree, "FGCOLOR", GLOBAL.editColor.filelistFore.toCString );
		version(Windows) IupSetAttribute( tree, "BGCOLOR", GLOBAL.editColor.filelistBack.toCString );
		
		IupSetCallback( tree, "SELECTION_CB", cast(Icallback) &fileList_SELECTION_CB );
		IupSetCallback( tree, "DRAGDROP_CB", cast(Icallback) &fileList_DRAGDROP_CB );

		Ihandle* _v = IupVbox( filelistToolbarH, tree, null );
		IupSetAttributes( _v, GLOBAL.cString.convert( "ALIGNMENT=ARIGHT" ) );
		layoutHandle = IupBackgroundBox( _v );
		IupSetCallback( layoutHandle, "BUTTON_CB", cast(Icallback) &fileList_Empty_BUTTON_CB );
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
	
	int getFullPathState()
	{
		return fullPathState;
	}
	
	void setTitleFont()
	{
		scope leftsideString = new IupString( GLOBAL.fonts[2].fontString );
		IupSetAttribute( filelistToolbarTitle, "FONT", leftsideString.toCString );// Leftside
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
			int addIndex = IupGetInt( tree, "COUNT" );
			if( GLOBAL.fileListTree.fullPathState == 0 )
			{
				IupSetAttributeId( tree, "ADDLEAF", addIndex - 1, GLOBAL.cString.convert( _sci.getFullPath ) );
				IupSetAttributeId( tree, "COLOR", addIndex, GLOBAL.editColor.filelistFore.toCString );
			}
			else
			{
				scope _fullPath = new FilePath( _sci.getFullPath );
				IupSetAttributeId( tree, "ADDLEAF", addIndex - 1, GLOBAL.cString.convert( _fullPath.file() ) );
				IupSetAttributeId( tree, "COLOR", addIndex, GLOBAL.editColor.filelistFore.toCString );
			}
			
			IupSetAttributeId( tree, "USERDATA", addIndex, cast(char*) _sci );
			version(Windows) IupSetAttributeId( tree, "MARKED", addIndex, "YES" ); else IupSetInt( tree, "VALUE", addIndex );
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
	
	int getTreeH()
	{
		try
		{
			char[] treeSize = fromStringz( IupGetAttribute( tree, "SIZE" ) );
			if( treeSize.length )
			{
				int crossPos = Util.rindex( treeSize, "x" );
				if( crossPos < treeSize.length ) return Integer.atoi( treeSize[crossPos+1..$] );
			}
		}
		catch( Exception e )
		{
			GLOBAL.IDEMessageDlg.print( "CFileList.getTreeH() Error:\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ Integer.toString( e.line ) );
			//debug IupMessage( "CFileList getTreeH()", toStringz( e.toString ) );
		}
		
		return 4096;
	}
}


extern(C)
{
	// File Select...
	private int fileList_SELECTION_CB( Ihandle *ih, int id, int status )
	{
		try
		{
			if( id >= 0 )
			{
				// SELECTION_CB will trigger 2 times, preSelect -> Select, we only catch second signal
				if( status == 1 )
				{
					CScintilla _sci = cast(CScintilla) IupGetAttributeId( ih, "USERDATA", id );
					if( _sci !is null )
					{
						//IupSetAttribute( GLOBAL.projectTree.getTreeHandle, "MARK", "CLEARALL" ); // For projectTree MULTIPLE Selection
						ScintillaAction.openFile( _sci.getFullPath.dup );
					}
				}
			}
		}
		catch( Exception e )
		{
			GLOBAL.IDEMessageDlg.print( "fileList_SELECTION_CB() Error:\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ Integer.toString( e.line ) );
		}

		return IUP_DEFAULT;
	}

	private int fileList_Empty_BUTTON_CB( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		// On/OFF fILELIST Window
		if( button == IUP_BUTTON1 ) // Left Click
		{
			char[] _s = fromStringz( status ).dup;
			if( _s.length > 5 )
			{
				if( _s[5] == 'D' ) // Double Click
				{
					char[] treeSize = fromStringz( IupGetAttribute( GLOBAL.fileListTree.getTreeHandle, "SIZE" ) );
					if( treeSize.length )
					{
						if( GLOBAL.fileListTree.getTreeH() <= 1 )
						{
							IupSetAttribute( GLOBAL.fileListSplit, "VALUE", toStringz( GLOBAL.editorSetting01.FileListSplit ) );
						}
						else
						{
							GLOBAL.editorSetting01.FileListSplit = fromStringz( IupGetAttribute( GLOBAL.fileListSplit, "VALUE" ) );
							IupSetInt( GLOBAL.fileListSplit, "VALUE", 1000 );
						}
					}
				}
			}
		}
		return IUP_DEFAULT;
	}

	private int fileList_DRAGDROP_CB( Ihandle *ih, int drag_id, int drop_id, int isshift, int iscontrol )
	{

		CScintilla _sci = cast(CScintilla) IupGetAttributeId( ih, "USERDATA", drag_id );
		CScintilla _dropSci;

		if( _sci !is null )
		{
			if( drop_id >= IupGetInt( ih, "COUNT" ) - 1 ) 
				_dropSci = null;
			else
				_dropSci = cast(CScintilla) IupGetAttributeId( ih, "USERDATA", drop_id + 1 );
			
			
			char[]		_title = fromStringz( IupGetAttributeId( ih, "TITLE", drag_id ) );
			GLOBAL.fileListTree.removeItem( _sci );

			if( drop_id < drag_id )
			{
				IupSetAttributeId( ih, "INSERTLEAF", drop_id ++, GLOBAL.fileListTree.getFullPathState ? _sci.getTitleHandle.toCString : _sci.getFullPath_IupString.toCString );
			}
			else if( drop_id > drag_id )
			{
				IupSetAttributeId( ih, "INSERTLEAF", drop_id - 1,  GLOBAL.fileListTree.getFullPathState ? _sci.getTitleHandle.toCString : _sci.getFullPath_IupString.toCString );
			}
			else
			{
				return IUP_DEFAULT;
			}
			
			IupSetAttributeId( ih, "USERDATA", drop_id, cast(char*) _sci  );
			version(Windows) IupSetAttributeId( ih, "MARKED", drop_id, "YES" ); else IupSetInt( ih, "VALUE", drop_id );
			/*
			// Change Document Tab Order
			if( _dropSci !is null )
				IupReparent( _sci.getIupScintilla, GLOBAL.documentTabs, _dropSci.getIupScintilla );
			else
				IupReparent( _sci.getIupScintilla, GLOBAL.documentTabs, null );

			int newDocumentPos = IupGetChildPos( GLOBAL.documentTabs, _sci.getIupScintilla );
			IupSetAttributeId( GLOBAL.documentTabs , "TABTITLE", newDocumentPos, _sci.getTitleHandle.toCString );
			DocumentTabAction.resetTip();
			IupRefresh( GLOBAL.documentTabs );
			IupSetInt( GLOBAL.documentTabs, "VALUEPOS", newDocumentPos );
			*/
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