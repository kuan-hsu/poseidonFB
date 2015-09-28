module layouts.outline;

private import iup.iup;

private import global, scintilla, actionManager, menu;
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
			case B_VARIABLE:
				IupSetAttributeId( activeTreeOutline, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_variable" ~ prot ) );
				break;

			case B_FUNCTION:
			case B_SUB:
				IupSetAttributeId( activeTreeOutline, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_function" ) );
				if( _node.getChildrenCount > 0 )
				{
					IupSetAttributeId( activeTreeOutline, "IMAGEEXPANDED", lastAddNode, GLOBAL.cString.convert( "IUP_function" ) );
				}
				break;

			case B_PROPERTY:
				IupSetAttributeId( activeTreeOutline, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_property" ) );
				if( _node.getChildrenCount > 0 )
				{
					IupSetAttributeId( activeTreeOutline, "IMAGEEXPANDED", lastAddNode, GLOBAL.cString.convert( "IUP_property" ) );
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

			default:
				IupSetAttributeId( activeTreeOutline, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_variable" ) );
		}
	}
	
	void append( CASTnode _node, int bracchID )
	{
		int lastAddNode;

		if( _node is null ) return;
		
		if( _node.getChildrenCount > 0 )
		{
			switch( _node.kind )
			{
				case B_FUNCTION, B_PROPERTY:
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

				case B_SUB, B_CTOR, B_DTOR:
					IupSetAttributeId( activeTreeOutline, "ADDBRANCH", bracchID, GLOBAL.cString.convert( _node.name ~ _node.type ) );
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
			switch( _node.kind )
			{
				case B_FUNCTION, B_PROPERTY:
					char[] _type = _node.type;
					char[] _paramString;
					
					int pos = Util.index( _node.type, "(" );
					if( pos < _node.type.length )
					{
						_type = _node.type[0..pos];
						_paramString = _node.type[pos..length];
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
				IupSetAttributes( activeTreeOutline, GLOBAL.cString.convert( "ADDROOT=YES,EXPAND=YES,RASTERSIZE=0x,TITLE=" ~ fullPath ) );
				IupSetCallback( activeTreeOutline, "SELECTION_CB", cast(Icallback) &COutline_selection );
				IupSetCallback( activeTreeOutline, "RIGHTCLICK_CB", cast(Icallback) &COutline_RIGHTCLICK_CB );
				/+
				if( head.kind == "BAS" )
				{
					IupSetAttributeId( activeTreeOutline, "IMAGE", 0, toStringz("icon_bas") );
					IupSetAttributeId( activeTreeOutline, "IMAGEEXPANDED", 0, toStringz("icon_bas") );
				}
				else
				{
					IupSetAttributeId( activeTreeOutline, "IMAGE", 0, toStringz("icon_bi") );
					IupSetAttributeId( activeTreeOutline, "IMAGEEXPANDED", 0, toStringz("icon_bi") );
				}
				+/

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
	private int COutline_selection( Ihandle *ih, int id, int status )
	{
		// SELECTION_CB will trigger 2 times, preSelect -> Select, we only catch second signal
		if( status == 1 )
		{
			CASTnode _node = cast(CASTnode) IupGetAttributeId( ih, "USERDATA", id );
			//Stdout( _node.lineNumber ).newline;

			char[] _fullPath = fromStringz( IupGetAttributeId( ih, "TITLE", 0 ) ); // Get Tree-Head Title
			
			ScintillaAction.openFile( _fullPath, _node.lineNumber );
		}

		return IUP_DEFAULT;
	}

	private int COutline_RIGHTCLICK_CB( Ihandle *ih, int id )
	{
		if( id == 0 )
		{
			Ihandle* itemRefresh = IupItem( "Refresh", null );
			IupSetCallback( itemRefresh, "ACTION", cast(Icallback) &COutline_refresh );
			IupSetHandle( "outline_rightclick", ih );

			/*
			Ihandle* itemShowParams= IupItem( "Show Params", null );
			//IupSetAttribute(item_outline, "KEY", "O");
			//IupSetAttribute( itemShowParams, "VALUE", "ON" );
			IupSetCallback(itemShowParams, "ACTION", cast(Icallback)&COutline_showParams);

			Ihandle* itemShowLineNum = IupItem( "Show LineNumber", null );
			//IupSetAttribute(item_outline, "KEY", "O");
			IupSetAttribute( itemShowLineNum, "VALUE", "ON" );
			//IupSetCallback(itemShowParams, "ACTION", cast(Icallback)&outline_cb);
			*/

			Ihandle* popupMenu = IupMenu( 	itemRefresh,
											//IupSeparator(),
											//itemShowParams,
											//itemShowLineNum,
											null
										);

			IupPopup( popupMenu, IUP_MOUSEPOS, IUP_MOUSEPOS );
			IupDestroy( popupMenu );
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