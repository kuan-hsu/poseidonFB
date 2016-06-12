module layouts.outline;

private import iup.iup;

private import global, scintilla, actionManager, menu, tools;
private import dialogs.singleTextDlg, dialogs.fileDlg;
private import parser.ast;


private import tango.stdc.stringz, Integer = tango.text.convert.Integer;;
private import tango.io.FilePath, tango.io.UnicodeFile, tango.text.Ascii, tango.io.Stdout;

class COutline
{
	private:

	
	Ihandle*			zBoxHandle, activeTreeOutline;

	void setImage( CASTnode _node )
	{
		int lastAddNode = IupGetInt( activeTreeOutline, "LASTADDNODE" );

		char[] prot;
		if( _node.protection.length )
		{
			if( _node.protection != "public" && _node.protection != "shared" ) prot = "_" ~ _node.protection;
		}

		switch( _node.kind )
		{
			case B_DEFINE | B_VARIABLE:
				IupSetAttributeId( activeTreeOutline, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_define_var" ) );
				break;

			case B_DEFINE | B_FUNCTION:
				IupSetAttributeId( activeTreeOutline, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_define_fun" ) );
				break;
				
			case B_VARIABLE:
				if( _node.name.length )
				{
					if( _node.name[length-1] == ')' )
						IupSetAttributeId( activeTreeOutline, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_variable_array" ~ prot ) );
					else
						IupSetAttributeId( activeTreeOutline, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_variable" ~ prot ) );
				}
				break;

			case B_FUNCTION:
				IupSetAttributeId( activeTreeOutline, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_function" ~ prot ) );
				if( _node.getChildrenCount > 0 )
				{
					IupSetAttributeId( activeTreeOutline, "IMAGEEXPANDED", lastAddNode, GLOBAL.cString.convert( "IUP_function" ~ prot ) );
				}
				break;

			case B_SUB:
				IupSetAttributeId( activeTreeOutline, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_sub" ~ prot ) );
				if( _node.getChildrenCount > 0 )
				{
					IupSetAttributeId( activeTreeOutline, "IMAGEEXPANDED", lastAddNode, GLOBAL.cString.convert( "IUP_sub" ~ prot ) );
				}
				break;

			case B_OPERATOR:
				IupSetAttributeId( activeTreeOutline, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_operator") );
				if( _node.getChildrenCount > 0 )
				{
					IupSetAttributeId( activeTreeOutline, "IMAGEEXPANDED", lastAddNode, GLOBAL.cString.convert( "IUP_operator" ) );
				}
				
				break;

			case B_PROPERTY:
				if(_node.type.length )
				{
					if( _node.type[0] == '(' )
					{
						IupSetAttributeId( activeTreeOutline, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_property" ) );
						if( _node.getChildrenCount > 0 ) IupSetAttributeId( activeTreeOutline, "IMAGEEXPANDED", lastAddNode, GLOBAL.cString.convert( "IUP_property" ) );
					}
					else
					{
						IupSetAttributeId( activeTreeOutline, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_property_var" ) );
						if( _node.getChildrenCount > 0 ) IupSetAttributeId( activeTreeOutline, "IMAGEEXPANDED", lastAddNode, GLOBAL.cString.convert( "IUP_property_var" ) );
					}
				}
				
				break;

			case B_CTOR:
				IupSetAttributeId( activeTreeOutline, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_ctor" ) );
				if( _node.getChildrenCount > 0 )
				{
					IupSetAttributeId( activeTreeOutline, "IMAGEEXPANDED", lastAddNode, GLOBAL.cString.convert( "IUP_ctor" ) );
				}
				break;

			case B_DTOR:
				IupSetAttributeId( activeTreeOutline, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_dtor" ) );
				if( _node.getChildrenCount > 0 )
				{
					IupSetAttributeId( activeTreeOutline, "IMAGEEXPANDED", lastAddNode, GLOBAL.cString.convert( "IUP_dtor" ) );
				}
				break;

			case B_TYPE:
				IupSetAttributeId( activeTreeOutline, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_struct" ) );
				if( _node.getChildrenCount > 0 )
				{
					IupSetAttributeId( activeTreeOutline, "IMAGEEXPANDED", lastAddNode, GLOBAL.cString.convert( "IUP_struct" ) );
				}
				break;

			case B_CLASS:
				IupSetAttributeId( activeTreeOutline, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_class" ) );
				if( _node.getChildrenCount > 0 )
				{
					IupSetAttributeId( activeTreeOutline, "IMAGEEXPANDED", lastAddNode, GLOBAL.cString.convert( "IUP_class" ) );
				}
				break;

			case B_ENUM:
				IupSetAttributeId( activeTreeOutline, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_enum" ) );
				if( _node.getChildrenCount > 0 )
				{
					IupSetAttributeId( activeTreeOutline, "IMAGEEXPANDED", lastAddNode, GLOBAL.cString.convert( "IUP_enum" ) );
				}
				break;				

			case B_ENUMMEMBER:
				IupSetAttributeId( activeTreeOutline, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_enummember" ) );
				if( _node.getChildrenCount > 0 )
				{
					IupSetAttributeId( activeTreeOutline, "IMAGEEXPANDED", lastAddNode, GLOBAL.cString.convert( "IUP_enummember" ) );
				}
				break;

			case B_UNION:
				IupSetAttributeId( activeTreeOutline, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_union" ) );
				if( _node.getChildrenCount > 0 )
				{
					IupSetAttributeId( activeTreeOutline, "IMAGEEXPANDED", lastAddNode, GLOBAL.cString.convert( "IUP_union" ) );
				}
				break;				

			case B_ALIAS:
				IupSetAttributeId( activeTreeOutline, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_alias" ) );
				break;

			case B_NAMESPACE:
				IupSetAttributeId( activeTreeOutline, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_namespace" ) );
				if( _node.getChildrenCount > 0 )
				{
					IupSetAttributeId( activeTreeOutline, "IMAGEEXPANDED", lastAddNode, GLOBAL.cString.convert( "IUP_namespace" ) );
				}				
				break;

			case B_MACRO:
				IupSetAttributeId( activeTreeOutline, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_macro" ) );
				if( _node.getChildrenCount > 0 )
				{
					IupSetAttributeId( activeTreeOutline, "IMAGEEXPANDED", lastAddNode, GLOBAL.cString.convert( "IUP_macro" ) );
				}				
				break;

			case B_SCOPE:
				IupSetAttributeId( activeTreeOutline, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_scope" ) );
				if( _node.getChildrenCount > 0 )
				{
					IupSetAttributeId( activeTreeOutline, "IMAGEEXPANDED", lastAddNode, GLOBAL.cString.convert( "IUP_scope" ) );
				}				
				break;	

			default:
				IupSetAttributeId( activeTreeOutline, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_variable" ) );
		}
	}
	
	void append( CASTnode _node, int bracchID )
	{
		int lastAddNode;

		if( _node is null ) return;

		//if( _node.kind & B_SCOPE ) return;

		if( _node.getChildrenCount > 0 )
		{
			switch( _node.kind )
			{
				case B_FUNCTION, B_PROPERTY, B_OPERATOR:
					char[] _type = _node.type;
					char[] _paramString;

					int pos = Util.index( _node.type, "(" );
					if( pos < _node.type.length )
					{
						_type = _node.type[0..pos];
						_paramString = _node.type[pos..length];
					}

					if( _type.length )
						IupSetAttributeId( activeTreeOutline, "ADDBRANCH", bracchID, GLOBAL.cString.convert( _node.name ~ _paramString ~ " : " ~ _type ) );
					else
						IupSetAttributeId( activeTreeOutline, "ADDBRANCH", bracchID, GLOBAL.cString.convert( _node.name ~ _paramString ) );
						
					break;

				case B_SUB, B_CTOR, B_DTOR, B_MACRO:
					IupSetAttributeId( activeTreeOutline, "ADDBRANCH", bracchID, GLOBAL.cString.convert( _node.name ~ _node.type ) );
					break;

				case B_SCOPE:
					IupSetAttributeId( activeTreeOutline, "ADDBRANCH", bracchID, null );
					break;				

				default:
					IupSetAttributeId( activeTreeOutline, "ADDBRANCH", bracchID, GLOBAL.cString.convert( _node.name ) );
			}
			lastAddNode = IupGetInt( activeTreeOutline, "LASTADDNODE" );
			setImage( _node );
			IupSetAttributeId( activeTreeOutline, "USERDATA", lastAddNode, cast(char*) _node );

			foreach_reverse( CASTnode t; _node.getChildren() )
			{
				append( t, lastAddNode );
			}
		}
		else
		{
			bool bNoImage;
			switch( _node.kind & 2097151 )
			{
				case B_FUNCTION, B_PROPERTY, B_OPERATOR:
					char[] _type = _node.type;
					char[] _paramString;
					
					int pos = Util.index( _node.type, "(" );
					if( pos < _node.type.length )
					{
						_type = _node.type[0..pos];
						_paramString = _node.type[pos..length];
					}

					if( _node.kind & B_DEFINE )
					{
						IupSetAttributeId( activeTreeOutline, "ADDLEAF", bracchID, GLOBAL.cString.convert( _node.name ~ _paramString ) );
						break;
					}					

					if( _type.length )
					{
						IupSetAttributeId( activeTreeOutline, "ADDLEAF", bracchID, GLOBAL.cString.convert( _node.name ~ _paramString ~ " : " ~ _type ) );
					}
					else
					{
						IupSetAttributeId( activeTreeOutline, "ADDLEAF", bracchID, GLOBAL.cString.convert( _node.name ~ _paramString ) );
					}
					break;

				case B_SUB, B_CTOR, B_DTOR:
					IupSetAttributeId( activeTreeOutline, "ADDLEAF", bracchID, GLOBAL.cString.convert( _node.name ~ _node.type ) );
					break;

				case B_VARIABLE, B_ALIAS:
					if( _node.kind & B_DEFINE )
					{
						IupSetAttributeId( activeTreeOutline, "ADDLEAF", bracchID, GLOBAL.cString.convert( _node.name ~ ( _node.type.length ? " : " ~ _node.type : "" ) ) );
						break;
					}					
				
					IupSetAttributeId( activeTreeOutline, "ADDLEAF", bracchID, GLOBAL.cString.convert( _node.name ~ ( _node.type.length ? " : " ~ _node.type : "" ) ) );
					break;

				case B_ENUMMEMBER:
					IupSetAttributeId( activeTreeOutline, "ADDLEAF", bracchID, GLOBAL.cString.convert( _node.name ) );
					break;

				default:
					bNoImage = true;
			}

			if( !bNoImage )
			{
				lastAddNode = IupGetInt( activeTreeOutline, "LASTADDNODE" );
				setImage( _node );
				IupSetAttributeId( activeTreeOutline, "USERDATA", lastAddNode, cast(char*) _node );
			}
		}
	}

	public:
	this()
	{
		zBoxHandle = IupZbox( null );
	}

	void setActiveTree( Ihandle* ih )
	{
		activeTreeOutline = ih;
	}

	Ihandle* getActiveTree()
	{
		return activeTreeOutline;
	}


	void cleanTree( char[] fullPath )
	{
		actionManager.OutlineAction.cleanTree( fullPath );
	}
	

	void createTree( CASTnode head )
	{
		if( head !is null )
		{
			if( head.kind == B_BAS || head.kind == B_BI )
			{
				char[] fullPath = head.name;

				Ihandle* tree = IupTree();
				activeTreeOutline = tree;
				IupSetAttributes( activeTreeOutline, GLOBAL.cString.convert( "ADDROOT=YES,EXPAND=YES,RASTERSIZE=0x" ) );
				IupSetAttribute( activeTreeOutline, "TITLE", toStringz( fullPath ) );
				IupSetCallback( activeTreeOutline, "BUTTON_CB", cast(Icallback) &COutline_BUTTON_CB );

				IupAppend( zBoxHandle, activeTreeOutline );
				IupMap( activeTreeOutline );
				IupRefresh( GLOBAL.outlineTree.getZBoxHandle );	
				foreach_reverse( CASTnode t; head.getChildren() )
				{
					//Stdout( t.kind ~ " " ~ t.type ~ " " );
					//Stdout( t.name ).newline;
					append( t, 0 );
				}
			}
		}

		activeTreeOutline = null;
		//int cpunt = IupGetChildCount( zBoxHandle );
		//IupMessage( "",toStringz( Integer.toString( cpunt ) ) );
		
	}

	void changeTree( char[] fullPath )
	{
		for( int i = 0; i < IupGetChildCount( zBoxHandle ); ++i )
		{
			Ihandle* ih = IupGetChild( zBoxHandle, i );
			if( ih != null )
			{
				char[] _fullPath = fromStringz( IupGetAttributeId( ih, "TITLE", 0 ) );

				if( fullPath == _fullPath )
				{
					IupSetInt( zBoxHandle, "VALUEPOS", i );
					break;
				}
			}
		}
	}
	
	Ihandle* getZBoxHandle(){ return zBoxHandle; }
}

extern(C) 
{
	private int COutline_BUTTON_CB( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		int id = IupConvertXYToPos( ih, x, y );

		if( fromStringz( IupGetAttribute( ih, "MARKMODE" ) ) == "MULTIPLE" )
		{
			IupSetAttributes( ih, GLOBAL.cString.convert( "MARK=CLEARALL" ) );
			IupSetAttributes( ih, GLOBAL.cString.convert( "MARKMODE=SINGLE" ) );
		}

		if( button == 49 ) // IUP_BUTTON1 = '1' = 49
		{
			char[] _s = fromStringz( status ).dup;
			
			if( _s.length > 5 )
			{
				if( _s[5] == 'D' ) // Double Click
				{
					if( id > 0 )
					{
						CASTnode _node = cast(CASTnode) IupGetAttributeId( ih, "USERDATA", id );

						char[] _fullPath = fromStringz( IupGetAttributeId( ih, "TITLE", 0 ) ); // Get Tree-Head Title
						
						ScintillaAction.openFile( _fullPath, _node.lineNumber );
						IupSetAttributeId( ih, "MARKED", id, "YES" );

						return IUP_IGNORE;
					}
				}
			}
		}
		else if( button == 51 ) // IUP_BUTTON3 = '3' = 51
		{
			if( id == 0 )
			{
				if( pressed == 0 )
				{
					IupSetAttributeId( ih, "MARKED", id, "YES" );

					GLOBAL.outlineTree.setActiveTree( ih );
					
					Ihandle* itemRefresh = IupItem( "Refresh", null );
					IupSetCallback( itemRefresh, "ACTION", cast(Icallback) &COutline_refresh );
					IupSetHandle( "outline_rightclick", ih );

					Ihandle* itemExpand = IupItem( "Expand/Contract All", null );
					IupSetCallback( itemExpand, "ACTION", cast(Icallback) &COutline_expand );
					IupSetHandle( "outline_rightclickexpand", ih );

					Ihandle* itemSearch = IupItem( "Mark Search", null );
					IupSetCallback( itemSearch, "ACTION", cast(Icallback) &COutline_search );
					IupSetHandle( "outline_search", ih );
					

					Ihandle* popupMenu = IupMenu( 	itemRefresh,
													itemExpand,
													IupSeparator(),
													itemSearch,
													null
												);

					IupPopup( popupMenu, IUP_MOUSEPOS, IUP_MOUSEPOS );
					IupDestroy( popupMenu );
				}
			}
		}

		return IUP_DEFAULT;
	}

	private int COutline_refresh( Ihandle *ih )
	{
		Ihandle* _iih = IupGetHandle( "outline_rightclick" );
		if( _iih != null )
		{
			char[] fullPath = fromStringz( IupGetAttributeId( _iih, "TITLE", 0 ) );
			actionManager.OutlineAction.refresh( fullPath );
		}
		IupSetHandle( "outline_rightclick", null );
		return IUP_DEFAULT;
	}

	private int COutline_expand( Ihandle *ih )
	{
		
		Ihandle* _iih = IupGetHandle( "outline_rightclickexpand" );
		if( _iih != null )
		{
			
			if( fromStringz( IupGetAttributeId( _iih, "STATE", 0 ) ) == "EXPANDED" )
				IupSetAttribute( _iih, "EXPANDALL", "NO" );
			else
			{
				IupSetAttribute( _iih, "EXPANDALL", "YES" );
				IupSetAttribute( _iih, "TOPITEM", "YES" ); // Set position to top
			}
		}
		IupSetHandle( "outline_rightclickexpand", null );
		return IUP_DEFAULT;
	}

	private int COutline_search( Ihandle *ih )
	{
		Ihandle* _iih = IupGetHandle( "outline_search" );
		if( _iih != null )
		{
			// Open Dialog Window
			scope test = new CSingleTextDialog( 275, 96, "Mark Search Outline...", "Target:", null, false );
			char[] target = test.show( IUP_MOUSEPOS, IUP_MOUSEPOS );
			if( target.length )
			{
				Ihandle* treeHandle = GLOBAL.outlineTree.getActiveTree;
				if( treeHandle != null )
				{
					IupSetAttributes( treeHandle, GLOBAL.cString.convert( "MARKMODE=MULTIPLE" ) );
					/*
					for( int i = 1; i < IupGetInt( treeHandle, "COUNT" ); ++ i )
					{
						IupSetAttributeId( treeHandle, "COLOR", i, "0 0 0" );
					}
					*/
					IupSetAttributeId( treeHandle, "MARKED", 0, "NO" );
					
					for( int i = 1; i < IupGetInt( treeHandle, "COUNT" ); ++ i )
					{
						//IupMessage( "", IupGetAttributeId( treeHandle, "TITLE", i ) );
						char[] title = fromStringz( IupGetAttributeId( treeHandle, "TITLE", i ) );
						int colonPos = Util.index( title, ":" );
						if( colonPos < title.length ) title = title[0..colonPos].dup;

						if( Util.index( lowerCase( title ), lowerCase( target ) ) < title.length ) IupSetAttributeId( treeHandle, "MARKED", i, "YES" );//IupSetAttributeId( treeHandle, "COLOR", i, "0 0 255" );
					}
				}
			}
		}
		IupSetHandle( "outline_search", null );
		return IUP_DEFAULT;
	}
	

	int COutline_showParams( Ihandle *ih )
	{
		if( fromStringz( IupGetAttribute( ih, "VALUE" ) ) == "ON" )
		{
			IupSetAttribute( ih, "VALUE", "OFF" );
		}
		else
		{
			IupSetAttribute( ih, "VALUE", "ON" );
		}
		
		return IUP_DEFAULT;
	}	
}