module layouts.outlinePanel;

private import iup.iup;

private import global, scintilla, actionManager, menu, tools;
private import dialogs.singleTextDlg, dialogs.fileDlg;
private import parser.ast;


private import tango.stdc.stringz, Integer = tango.text.convert.Integer, Util = tango.text.Util;
private import tango.io.FilePath, tango.io.UnicodeFile, tango.text.Ascii;

class COutline
{
	private:
	import 				iup.iup_scintilla;
	import				parser.scanner, parser.token, parser.parser;
	import				tango.core.Thread;

	Ihandle*			layoutHandle, zBoxHandle, outlineTreeNodeList;
	Ihandle*			outlineButtonCollapse, outlineButtonPR, outlineButtonShowLinenum, outlineToggleAnyWord, outlineButtonFresh;
	CASTnode[]			listItemASTs;
	int[]				listItemTreeID;
	int					listItemIndex;
	int					showIndex= 0; 
	
	/+
	// Inner Class
	class ReparseThread : Thread
	{
		private:
		import			parser.ast;
		
		char[]			pFullPath;
		char[]			pDocument;
		Ihandle*		pOutlineTree;

		public:
		this( char[] _pFullPath, char[] _pDocument, Ihandle* _pOutlineTree )
		{
			pFullPath		= _pFullPath;
			pDocument 		= _pDocument;
			pOutlineTree	= _pOutlineTree;
	
			super( &run );
		}

		void run()
		{
			GLOBAL.Parser.updateTokens( GLOBAL.scanner.scan( pDocument ) );
			CASTnode astHeadNode = GLOBAL.Parser.parse( pFullPath );
			CASTnode temp = GLOBAL.parserManager[fullPathByOS(pFullPath)];
			GLOBAL.parserManager[fullPathByOS(pFullPath)] = astHeadNode;
			delete temp;
			
			IupUnmap( pOutlineTree );

			IupSetAttributeId( pOutlineTree, "DELNODE", 0, "CHILDREN" );
			version(DIDE)
			{
				IupSetAttributeId( pOutlineTree, "USERDATA", 0, cast(char*) astHeadNode );
				IupSetAttribute( pOutlineTree, "TITLE", toStringz( astHeadNode.name ) );						
			}
			IupSetAttributeId( pOutlineTree, "COLOR", 0, GLOBAL.editColor.outlineFore.toCString );
			foreach_reverse( CASTnode t; astHeadNode.getChildren() )
			{
				append( pOutlineTree, t, 0 );
			}
			
			IupMap( pOutlineTree );
			
			// Reparse Lexer
			version(FBIDE) IupScintillaSendMessage( cSci.getIupScintilla, 4003, 0, -1 ); // SCI_COLOURISE 4003

		}
	}
	+/

	void setImage( Ihandle* rootTree, CASTnode _node )
	{
		int lastAddNode = IupGetInt( rootTree, "LASTADDNODE" );

		char[] prot;
		if( _node.protection.length )
		{
			if( _node.protection != "public" && _node.protection != "shared" ) prot = "_" ~ _node.protection;
		}

		version(FBIDE)
		{
			switch( _node.kind )
			{
				case B_DEFINE | B_VARIABLE:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_define_var" );
					break;

				case B_DEFINE | B_FUNCTION:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_define_fun" );
					break;
					
				case B_VARIABLE:
					if( _node.type.length )
					{
						if( _node.name[$-1] == ')' )
							IupSetAttributeId( rootTree, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_variable_array" ~ prot ) );
						else
							IupSetAttributeId( rootTree, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_variable" ~ prot ) );
					}
					break;

				case B_FUNCTION:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_function" ~ prot ) );
					if( _node.getChildrenCount > 0 )
					{
						IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, GLOBAL.cString.convert( "IUP_function" ~ prot ) );
					}
					break;

				case B_SUB:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_sub" ~ prot ) );
					if( _node.getChildrenCount > 0 )
					{
						IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, GLOBAL.cString.convert( "IUP_sub" ~ prot ) );
					}
					break;

				case B_OPERATOR:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_operator" );
					if( _node.getChildrenCount > 0 )
					{
						IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_operator" );
					}
					
					break;

				case B_PROPERTY:
					if(_node.type.length )
					{
						if( _node.type[0] == '(' )
						{
							IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_property" );
							if( _node.getChildrenCount > 0 ) IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_property" );
						}
						else
						{
							IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_property_var" );
							if( _node.getChildrenCount > 0 ) IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_property_var" );
						}
					}
					
					break;

				case B_CTOR:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_ctor" );
					if( _node.getChildrenCount > 0 )
					{
						IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_ctor" );
					}
					break;

				case B_DTOR:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_dtor" );
					if( _node.getChildrenCount > 0 )
					{
						IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_dtor" );
					}
					break;

				case B_TYPE:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_struct" );
					if( _node.getChildrenCount > 0 )
					{
						IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_struct" );
					}
					break;

				case B_CLASS:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_class" );
					if( _node.getChildrenCount > 0 )
					{
						IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_class" );
					}
					break;

				case B_ENUM:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_enum" );
					if( _node.getChildrenCount > 0 )
					{
						IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_enum" );
					}
					break;				

				case B_ENUMMEMBER:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_enummember" );
					if( _node.getChildrenCount > 0 )
					{
						IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_enummember" );
					}
					break;

				case B_UNION:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_union" );
					if( _node.getChildrenCount > 0 )
					{
						IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_union" );
					}
					break;				

				case B_ALIAS:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_alias" );
					break;

				case B_NAMESPACE:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_namespace" );
					if( _node.getChildrenCount > 0 )
					{
						IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_namespace" );
					}				
					break;

				case B_MACRO:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_macro" );
					if( _node.getChildrenCount > 0 )
					{
						IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_macro" );
					}				
					break;

				case B_SCOPE:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_scope" );
					if( _node.getChildrenCount > 0 )
					{
						IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_scope" );
					}				
					break;
					
				case B_WITH:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_with" );
					if( _node.getChildrenCount > 0 )
					{
						IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_with" );
					}				
					break;

				default:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_variable" );
			}
		}
		
		version(DIDE)
		{
			switch( _node.kind )
			{
				case D_IMPORT:
					if( _node.protection != "public" ) prot = "_private";
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_import" ~ prot ) );
					break;
					
				case D_VARIABLE:
					if( _node.type.length )
					{
						if( _node.type[$-1] == ']' )
							IupSetAttributeId( rootTree, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_variable_array" ~ prot ) );
						else
							IupSetAttributeId( rootTree, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_variable" ~ prot ) );
					}
					break;

				case D_FUNCTIONPTR:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_funptr" ~ prot ) );
					break;

				case D_FUNCTIONLITERALS:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_anonymous" );
					if( _node.getChildrenCount > 0 )
					{
						IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_anonymous" );
					}
					break;

				case D_FUNCTION:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_function" ~ prot ) );
					if( _node.getChildrenCount > 0 )
					{
						IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, GLOBAL.cString.convert( "IUP_function" ~ prot ) );
					}
					break;

				case D_TEMPLATE:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_template" );
					if( _node.getChildrenCount > 0 )
					{
						IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_template" );
					}
					break;

				case D_CTOR:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_ctor" );
					if( _node.getChildrenCount > 0 )
					{
						IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_ctor" );
					}
					break;

				case D_DTOR:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_dtor" );
					if( _node.getChildrenCount > 0 )
					{
						IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_dtor" );
					}
					break;

				case D_STRUCT:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_struct" );
					if( _node.getChildrenCount > 0 )
					{
						IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_struct" );
					}
					break;

				case D_CLASS:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_class" );
					if( _node.getChildrenCount > 0 )
					{
						IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_class" );
					}
					break;

				case D_INTERFACE:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_interface" );
					if( _node.getChildrenCount > 0 )
					{
						IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_interface" );
					}
					break;

				case D_ENUM:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_enum" );
					if( _node.getChildrenCount > 0 )
					{
						IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_enum" );
					}
					break;				

				case D_ENUMMEMBER:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_enummember" );
					if( _node.getChildrenCount > 0 )
					{
						IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_enummember" );
					}
					break;

				case D_UNION:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_union" );
					if( _node.getChildrenCount > 0 )
					{
						IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_union" );
					}
					break;				

				case D_ALIAS:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_alias" );
					break;

				case D_VERSION:
					if( _node.type.length )
					{
						IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_versionspec" );
						break;
					}
					
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_version" );
					if( _node.getChildrenCount > 0 )
					{
						IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_version" );
					}				
					break;

				case D_DEBUG:
					if( _node.type.length )
					{
						IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_debugspec" );
						break;
					}
				
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_debug" );
					if( _node.getChildrenCount > 0 )
					{
						IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_debug" );
					}				
					break;

				default:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_variable" );
			}
		}
		

		if( GLOBAL.editorSetting00.ColorOutline == "ON" )
		{
			version(FBIDE)
			{
				switch( lowerCase( _node.protection ) )
				{
					case "private":		IupSetAttributeId( rootTree, "COLOR", lastAddNode, GLOBAL.cString.convert( "255 0 0" ) ); break;
					case "protected":	IupSetAttributeId( rootTree, "COLOR", lastAddNode, GLOBAL.cString.convert( "255 127 39" ) ); break;
					default:
				}
			}
			version(DIDE)
			{
				if( _node.kind & D_IMPORT )
				{
					if( _node.protection == "protected" )
						IupSetAttributeId( rootTree, "COLOR", lastAddNode, GLOBAL.cString.convert( "255 95 17" ) );
					else if( _node.protection == "" || _node.protection == "private" )
						IupSetAttributeId( rootTree, "COLOR", lastAddNode, GLOBAL.cString.convert( "255 0 0" ) );
				}
				else
				{
					switch( _node.protection )
					{
						case "private":		IupSetAttributeId( rootTree, "COLOR", lastAddNode, GLOBAL.cString.convert( "255 0 0" ) ); break;
						case "protected":	IupSetAttributeId( rootTree, "COLOR", lastAddNode, GLOBAL.cString.convert( "255 95 17" ) ); break;
						default:
					}
				}
			}
		}
	}

	void changePR( Ihandle* actTree = null )
	{
		if( IupGetChildCount( zBoxHandle ) > 0 )
		{
			if( actTree == null )
			{
				int pos = IupGetInt( zBoxHandle, "VALUEPOS" ); // Get active zbox pos
				actTree = IupGetChild( zBoxHandle, pos );
			}
			
			if( actTree == null ) return;
			
			char[]	lineNumString;
			bool	bShowLinenum;
			Ihandle* showLineHandle = IupGetDialogChild( GLOBAL.mainDlg, "button_OutlineShowLinenum" );
			if( showLineHandle != null )
			{
				if( fromStringz( IupGetAttribute( showLineHandle, "VALUE" ) ) == "ON" ) bShowLinenum = true;
			}

			for( int i = 1; i < IupGetInt( actTree, "COUNT" ); ++ i )
			{
				CASTnode _node = cast(CASTnode) IupGetAttributeId( actTree, "USERDATA", i );
				
				if( bShowLinenum ) lineNumString = " .... [" ~ Integer.toString( _node.lineNumber ) ~ "]"; else lineNumString = "";
				
				if( _node !is null )
				{
					version(FBIDE)
					{
						switch( _node.kind )
						{
							case B_FUNCTION, B_PROPERTY, B_OPERATOR:
								char[] _type;
								char[] _paramString;
								
								ParserAction.getSplitDataFromNodeTypeString( _node.type, _type, _paramString );
								switch( showIndex )
								{
									case 0:
										IupSetAttributeId( actTree, "TITLE", i, GLOBAL.cString.convert( _node.name ~ _paramString ~ ( _type.length ? " : " ~ _type : "" ) ~ lineNumString ) );
										break;
									case 1:
										IupSetAttributeId( actTree, "TITLE", i, GLOBAL.cString.convert( _node.name ~ _paramString ~ lineNumString ) );
										break;
									case 2:
										IupSetAttributeId( actTree, "TITLE", i, GLOBAL.cString.convert( _node.name ~ ( _type.length ? " : " ~ _type : "" ) ~ lineNumString ) );
										break;
									default:
										IupSetAttributeId( actTree, "TITLE", i, GLOBAL.cString.convert( _node.name ~ lineNumString ) );
										break;
								}
								break;

							case B_SUB, B_CTOR, B_DTOR, B_MACRO:
								switch( showIndex )
								{
									case 0, 1:
										IupSetAttributeId( actTree, "TITLE", i, GLOBAL.cString.convert( _node.name ~ _node.type ~ lineNumString ) );
										break;
									default:
										IupSetAttributeId( actTree, "TITLE", i, GLOBAL.cString.convert( _node.name ~ lineNumString ) );
										break;
								}
								break;
							
							case B_DEFINE | B_FUNCTION:
								char[] _paramString = ParserAction.getSeparateParam( _node.type ~ lineNumString );
								switch( showIndex )
								{
									case 0, 1:
										IupSetAttributeId( actTree, "TITLE", i, GLOBAL.cString.convert( _node.name ~ _paramString ~ lineNumString ) );
										break;
									default:
										IupSetAttributeId( actTree, "TITLE", i, GLOBAL.cString.convert( _node.name ~ lineNumString ) );
										break;
								}
								break;
								
							case B_DEFINE | B_VARIABLE, B_DEFINE | B_ALIAS:
								if( showIndex == 0 || showIndex == 2 )
									IupSetAttributeId( actTree, "TITLE", i, GLOBAL.cString.convert( _node.name ~ ( _node.type.length ? " : " ~ _node.type : "" ) ~ lineNumString ) );
								else
									IupSetAttributeId( actTree, "TITLE", i, GLOBAL.cString.convert( _node.name ~ lineNumString ) );
								
								break;

							case B_VARIABLE, B_ALIAS:
								if( showIndex == 0 || showIndex == 2 )
									IupSetAttributeId( actTree, "TITLE", i, GLOBAL.cString.convert( _node.name ~ ( _node.type.length ? " : " ~ _node.type : "" ) ~ lineNumString ) );
								else
									IupSetAttributeId( actTree, "TITLE", i, GLOBAL.cString.convert( _node.name ~ lineNumString ) );
								
								break;						

							default:
								IupSetAttributeId( actTree, "TITLE", i, GLOBAL.cString.convert( _node.name ~ lineNumString ) );
								break;
						}
					}
					
					version(DIDE)
					{
						switch( _node.kind )
						{
							case D_IMPORT:
								IupSetAttributeId( actTree, "TITLE", i, GLOBAL.cString.convert( _node.name ~ ( _node.type.length ? " : " ~ _node.type : "" ) ~ lineNumString ) );
								break;						
						
							case D_FUNCTION, D_FUNCTIONLITERALS:
								char[] _type = _node.type;
								char[] _paramString;
								
								ParserAction.getSplitDataFromNodeTypeString( _node.type, _type, _paramString );
								switch( showIndex )
								{
									case 0:
										IupSetAttributeId( actTree, "TITLE", i, GLOBAL.cString.convert( _node.name ~ _paramString ~ ( _type.length ? " : " ~ _type : "" ) ~ lineNumString ) );
										break;
									case 1:
										IupSetAttributeId( actTree, "TITLE", i, GLOBAL.cString.convert( _node.name ~ _paramString ~ lineNumString ) );
										break;
									case 2:
										IupSetAttributeId( actTree, "TITLE", i, GLOBAL.cString.convert( _node.name ~ ( _type.length ? " : " ~ _type : "" ) ~ lineNumString ) );
										break;
									default:
										IupSetAttributeId( actTree, "TITLE", i, GLOBAL.cString.convert( _node.name ~ lineNumString ) );
										break;
								}
								break;

							case D_CTOR:
								switch( showIndex )
								{
									case 0, 1:
										IupSetAttributeId( actTree, "TITLE", i, GLOBAL.cString.convert( "this" ~ _node.type ~ lineNumString ) );
										break;
									default:
										IupSetAttributeId( actTree, "TITLE", i, GLOBAL.cString.convert( "this" ~ lineNumString ) );
										break;
								}
								break;

							case D_DTOR:
								switch( showIndex )
								{
									case 0, 1:
										IupSetAttributeId( actTree, "TITLE", i, GLOBAL.cString.convert( "~this()" ~ lineNumString ) );
										break;
									default:
										IupSetAttributeId( actTree, "TITLE", i, GLOBAL.cString.convert( "~this" ~ lineNumString ) );
										break;
								}
								break;

							case D_CLASS, D_INTERFACE:
								if( showIndex == 0 || showIndex == 2 )
									IupSetAttributeId( actTree, "TITLE", i, GLOBAL.cString.convert( _node.name ~ ( _node.base.length ? " : " ~ _node.base : "" ) ~ lineNumString ) );
								else
									IupSetAttributeId( actTree, "TITLE", i, GLOBAL.cString.convert( _node.name ~ lineNumString ) );
								
								break;	
								
							case D_FUNCTIONPTR:
								char[] _type;
								char[] _paramString;
								ParserAction.getSplitDataFromNodeTypeString( _node.type, _type, _paramString );
								switch( showIndex )
								{
									case 0:
										IupSetAttributeId( actTree, "TITLE", i, GLOBAL.cString.convert( _node.name ~ _paramString ~ ( _type.length ? " : " ~ _type : "" ) ~ lineNumString ) );
										break;
									case 1:
										IupSetAttributeId( actTree, "TITLE", i, GLOBAL.cString.convert( _node.name ~ _paramString ~ lineNumString ) );
										break;
									case 2:
										IupSetAttributeId( actTree, "TITLE", i, GLOBAL.cString.convert( _node.name ~ ( _type.length ? " : " ~ _type : "" ) ~ lineNumString ) );
										break;
									default:
										IupSetAttributeId( actTree, "TITLE", i, GLOBAL.cString.convert( _node.name ~ lineNumString ) );
										break;
								}				
								break;	
						
							case D_VARIABLE:
								if( showIndex == 0 || showIndex == 2 )
									IupSetAttributeId( actTree, "TITLE", i, GLOBAL.cString.convert( _node.name ~ ( _node.type.length ? " : " ~ _node.type : "" ) ~ lineNumString ) );
								else
									IupSetAttributeId( actTree, "TITLE", i, GLOBAL.cString.convert( _node.name ~ lineNumString ) );
								
								break;						

							default:
								IupSetAttributeId( actTree, "TITLE", i, GLOBAL.cString.convert( _node.name ~ lineNumString ) );
								break;						
						}
					}
				}
			}
		}		
	}
	
	void append( Ihandle* rootTree, CASTnode _node, int bracchID, bool bInsertMode = false )
	{
		int lastAddNode;

		if( _node is null ) return;

		//if( _node.kind & B_SCOPE ) return;

		char[]	BRANCH, LEAF;
		if( bInsertMode )
		{
			BRANCH	= "INSERTBRANCH";
			LEAF	= "INSERTLEAF";
		}
		else
		{
			BRANCH	= "ADDBRANCH";
			LEAF	= "ADDLEAF";
		}
		
		scope sCovert = new IupString;
		
		char[]	lineNumString;
		Ihandle* showLineHandle = IupGetDialogChild( GLOBAL.mainDlg, "button_OutlineShowLinenum" );
		if( showLineHandle != null )
		{
			if( fromStringz( IupGetAttribute( showLineHandle, "VALUE" ) ) == "ON" ) lineNumString = " .... [" ~ Integer.toString( _node.lineNumber ) ~ "]";
		}

		if( _node.getChildrenCount > 0 )
		{
			version(FBIDE)
			{
				switch( _node.kind )
				{
					case B_FUNCTION, B_PROPERTY, B_OPERATOR:
						char[] _type = _node.type;
						char[] _paramString;
						
						ParserAction.getSplitDataFromNodeTypeString( _node.type, _type, _paramString );
						switch( showIndex )
						{
							case 0:
								IupSetAttributeId( rootTree, sCovert.convert( BRANCH ), bracchID, GLOBAL.cString.convert( _node.name ~ _paramString ~ ( _type.length ? " : " ~ _type : "" )  ~ lineNumString ) );
								IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
								break;
							case 1:
								IupSetAttributeId( rootTree, sCovert.convert( BRANCH ), bracchID, GLOBAL.cString.convert( _node.name ~ _paramString ~ lineNumString ) );
								IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
								break;
							case 2:
								IupSetAttributeId( rootTree, sCovert.convert( BRANCH ), bracchID, GLOBAL.cString.convert( _node.name ~ ( _type.length ? " : " ~ _type : "" ) ~ lineNumString ) );
								IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
								break;
							default:
								IupSetAttributeId( rootTree, sCovert.convert( BRANCH ), bracchID, GLOBAL.cString.convert( _node.name ~ lineNumString ) );
								IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
								break;
						}					
						break;

					case B_SUB, B_CTOR, B_DTOR, B_MACRO:
						switch( showIndex )
						{
							case 0, 1:
								IupSetAttributeId( rootTree, sCovert.convert( BRANCH ), bracchID, GLOBAL.cString.convert( _node.name ~ _node.type ~ lineNumString ) );
								IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
								break;
							default:
								IupSetAttributeId( rootTree, sCovert.convert( BRANCH ), bracchID, GLOBAL.cString.convert( _node.name ~ lineNumString ) );
								IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
								break;
						}
						break;

					case B_SCOPE:
						IupSetAttributeId( rootTree, sCovert.convert( BRANCH ), bracchID, GLOBAL.cString.convert( lineNumString ) );
						IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
						break;
						
					case B_TYPE, B_CLASS:
						if( _node.base.length )
						{
							IupSetAttributeId( rootTree, sCovert.convert( BRANCH ), bracchID, GLOBAL.cString.convert( _node.name ~ " : " ~ _node.base ~ lineNumString ) );
							IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
							break;
						}

					default:
						IupSetAttributeId( rootTree, sCovert.convert( BRANCH ), bracchID, GLOBAL.cString.convert( _node.name ~ lineNumString ) );
						IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
				}
			}
			version(DIDE)
			{
				switch( _node.kind )
				{
					case D_FUNCTION, D_FUNCTIONLITERALS:
						char[] _type = _node.type;
						char[] _paramString;
						
						ParserAction.getSplitDataFromNodeTypeString( _node.type, _type, _paramString );
						switch( showIndex )
						{
							case 0:
								IupSetAttributeId( rootTree, sCovert.convert( BRANCH ), bracchID, GLOBAL.cString.convert( _node.name ~ _paramString ~ ( _type.length ? " : " ~ _type : "" ) ~ lineNumString ) );
								IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
								break;
							case 1:
								IupSetAttributeId( rootTree, sCovert.convert( BRANCH ), bracchID, GLOBAL.cString.convert( _node.name ~ _paramString ~ lineNumString ) );
								IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
								break;
							case 2:
								IupSetAttributeId( rootTree, sCovert.convert( BRANCH ), bracchID, GLOBAL.cString.convert( _node.name ~ ( _type.length ? " : " ~ _type : "" ) ~ lineNumString ) );
								IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
								break;
							default:
								IupSetAttributeId( rootTree, sCovert.convert( BRANCH ), bracchID, GLOBAL.cString.convert( _node.name ~ lineNumString ) );
								IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
								break;
						}					
						break;

					case D_CTOR:
						switch( showIndex )
						{
							case 0, 1:
								IupSetAttributeId( rootTree, sCovert.convert( BRANCH ), bracchID, GLOBAL.cString.convert( "this" ~ _node.type ~ lineNumString ) );
								IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
								break;
							default:
								IupSetAttributeId( rootTree, sCovert.convert( BRANCH ), bracchID, GLOBAL.cString.convert( "this" ~ lineNumString ) );
								IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
								break;
						}
						break;

					case D_DTOR:
						switch( showIndex )
						{
							case 0, 1:
								IupSetAttributeId( rootTree, sCovert.convert( BRANCH ), bracchID, GLOBAL.cString.convert( "~this()" ~ lineNumString ) );
								IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
								break;
							default:
								IupSetAttributeId( rootTree, sCovert.convert( BRANCH ), bracchID, GLOBAL.cString.convert( "~this" ~ lineNumString ) );
								IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
								break;
						}
						break;

					case D_CLASS, D_INTERFACE:
						switch( showIndex )
						{
							case 0, 2:
								IupSetAttributeId( rootTree, sCovert.convert( BRANCH ), bracchID, GLOBAL.cString.convert( _node.name ~ ( _node.base.length ? " : " ~ _node.base : _node.base ) ~ lineNumString ) );
								IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
								break;
								
							default:
								IupSetAttributeId( rootTree, sCovert.convert( BRANCH ), bracchID, GLOBAL.cString.convert( _node.name ~ lineNumString ) );
								IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
								break;
						}
						break;					

					case D_ENUM:	
						if( !_node.name.length )
						{
							IupSetAttributeId( rootTree, sCovert.convert( BRANCH ), bracchID, GLOBAL.cString.convert( "-Anonymous-" ~ lineNumString ) );
							IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
						}
						else
						{
							IupSetAttributeId( rootTree, sCovert.convert( BRANCH ), bracchID, GLOBAL.cString.convert( _node.name ~ lineNumString ) );
							IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
						}
						break;	
						
					default:
						IupSetAttributeId( rootTree, sCovert.convert( BRANCH ), bracchID, GLOBAL.cString.convert( _node.name ~ lineNumString ) );
						IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
				}
			}
			
			lastAddNode = IupGetInt( rootTree, "LASTADDNODE" );
			setImage( rootTree, _node );
			IupSetAttributeId( rootTree, "USERDATA", lastAddNode, cast(char*) _node );

			foreach_reverse( CASTnode t; _node.getChildren() )
			{
				append( rootTree, t, lastAddNode );
			}
		}
		else
		{
			bool bNoImage;
			version(FBIDE)
			{
				switch( _node.kind & 4194303 )
				{
					case B_FUNCTION, B_PROPERTY, B_OPERATOR:
						char[] _type = _node.type;
						char[] _paramString;
						
						ParserAction.getSplitDataFromNodeTypeString( _node.type, _type, _paramString );
						switch( showIndex )
						{
							case 0:
								IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( _node.name ~ _paramString ~ ( _type.length ? " : " ~ _type : "" ) ~ lineNumString ) );
								IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
								break;
							case 1:
								IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( _node.name ~ _paramString ~ lineNumString ) );
								IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
								break;
							case 2:
								IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( _node.name ~ ( _type.length ? " : " ~ _type : "" ) ~ lineNumString ) );
								IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
								break;
							default:
								IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( _node.name ~ lineNumString ) );
								IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
								break;
						}
						break;

					case B_SUB, B_CTOR, B_DTOR:
						switch( showIndex )
						{
							case 0, 1:
								IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( _node.name ~ _node.type ~ lineNumString ) );
								IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
								break;
							default:
								IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( _node.name ~ lineNumString ) );
								IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
								break;
						}				
						break;
						
					case B_DEFINE | B_FUNCTION:
						char[] _paramString = ParserAction.getSeparateParam( _node.type );
						switch( showIndex )
						{
							case 0, 1:
								IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( _node.name ~ _paramString ~ lineNumString ) );
								IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
								break;
							default:
								IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( _node.name ~ lineNumString ) );
								IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
								break;
						}
						break;
						
					case B_DEFINE | B_VARIABLE, B_DEFINE | B_ALIAS:
						if( showIndex == 0 || showIndex == 2 )
						{
							IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( _node.name ~ ( _node.type.length ? " : " ~ _node.type : "" ) ~ lineNumString ) );
							IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
						}
						else
						{
							IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( _node.name ~ lineNumString ) );
							IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
						}
						break;

					case B_VARIABLE:
						if( !_node.type.length )
							if( _node.base.length )
							{
								char[][] types = ParserAction.getDivideWordWithoutSymbol( _node.base );
								
								char[] autoType = Util.join( types, "." );
								if( showIndex == 0 || showIndex == 2 )
								{
									IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( _node.name ~ ( autoType.length ? " : " ~ autoType : "" ) ~ lineNumString ) );
									IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
								}
								else
								{
									IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( _node.name ~ lineNumString ) );
									IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
								}
								break;
							}					
					
					case  B_ALIAS:
						if( showIndex == 0 || showIndex == 2 )
						{
							IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( _node.name ~ ( _node.type.length ? " : " ~ _node.type : "" ) ~ lineNumString ) );
							IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
						}
						else
						{
							IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( _node.name ~ lineNumString ) );
							IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
						}
						
						break;

					case B_ENUMMEMBER, B_WITH:
						IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( _node.name ~ lineNumString ) );
						IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
						break;
						
					case B_TYPE, B_CLASS:
						if( _node.base.length )
						{
							IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( _node.name ~ " : " ~ _node.base ~ lineNumString ) );
							IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
							break;
						}

					default:
						bNoImage = true;
				}
			}
			version(DIDE)
			{
				switch( _node.kind & 8388607 )
				{
					case D_IMPORT:
						IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( _node.name ~ ( _node.type.length ? " : " ~ _node.type : "" ) ~ lineNumString ) );
						break;
						
					case D_FUNCTION, D_FUNCTIONLITERALS:
						char[] _type = _node.type;
						char[] _paramString;
						
						ParserAction.getSplitDataFromNodeTypeString( _node.type, _type, _paramString );
						switch( showIndex )
						{
							case 0:
								IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( _node.name ~ _paramString ~ ( _type.length ? " : " ~ _type : "" ) ~ lineNumString ) );
								IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
								break;
							case 1:
								IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( _node.name ~ _paramString ~ lineNumString ) );
								IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
								break;
							case 2:
								IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( _node.name ~ ( _type.length ? " : " ~ _type : "" ) ~ lineNumString ) );
								IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
								break;
							default:
								IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( _node.name ~ lineNumString ) );
								IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
								break;
						}
						break;

					case D_CTOR:
						switch( showIndex )
						{
							case 0, 1:
								IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( "this" ~ _node.type ~ lineNumString ) );
								IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
								break;
							default:
								IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( "this" ~ lineNumString ) );
								IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
								break;
						}				
						break;

					case D_DTOR:
						switch( showIndex )
						{
							case 0, 1:
								IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( "~this()" ~ lineNumString ) );
								IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
								break;
							default:
								IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( "~this" ~ lineNumString ) );
								IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
								break;
						}				
						break;
						
					case D_FUNCTIONPTR:
						char[] _type;
						char[] _paramString;
						
						ParserAction.getSplitDataFromNodeTypeString( _node.type, _type, _paramString );
						switch( showIndex )
						{
							case 0:
								IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( _node.name ~ _paramString ~ ( _type.length ? " : " ~ _type : "" ) ~ lineNumString ) );
								IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
								break;
							case 1:
								IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( _node.name ~ _paramString ~ lineNumString ) );
								IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
								break;
							case 2:
								IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( _node.name ~ ( _type.length ? " : " ~ _type : "" ) ~ lineNumString ) );
								IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
								break;
							default:
								IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( _node.name ~ lineNumString ) );
								IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
								break;
						}					
						break;
						
					case D_VARIABLE:
						if( !_node.type.length )
							if( _node.base.length )
							{
								char[][] types = ParserAction.getDivideWordWithoutSymbol( _node.base );
								
								char[] autoType = Util.join( types, "." );
								if( showIndex == 0 || showIndex == 2 )
								{
									IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( _node.name ~ ( autoType.length ? " : " ~ autoType : "" ) ~ lineNumString ) );
									IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
								}
								else
								{
									IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( _node.name ~ lineNumString ) );
									IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
								}
								break;
							}
						
					case D_ALIAS:
						if( showIndex == 0 || showIndex == 2 )
						{
							IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( _node.name ~ ( _node.type.length ? " : " ~ _node.type : "" ) ~ lineNumString ) );
							IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
						}
						else
						{
							IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( _node.name ~ lineNumString ) );
							IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
						}
						break;

					case D_ENUMMEMBER, D_VERSION, D_DEBUG:
						IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( _node.name ~ lineNumString ) );
						IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
						break;

					default:
						bNoImage = true;
				}
			}

			if( !bNoImage )
			{
				lastAddNode = IupGetInt( rootTree, "LASTADDNODE" );
				setImage( rootTree, _node );
				IupSetAttributeId( rootTree, "USERDATA", lastAddNode, cast(char*) _node );
			}
		}
	}

	int updateNodeByLineNumber( CASTnode[] newASTNodes, int _ln )
	{
		if( GLOBAL.toggleUpdateOutlineLive != "ON" ) return -1;

		int insertID = -1;
		if( IupGetChildCount( GLOBAL.outlineTree.getZBoxHandle ) > 0 )
		{
			int pos = IupGetInt( GLOBAL.outlineTree.getZBoxHandle, "VALUEPOS" ); // Get active zbox pos
			Ihandle* actTree = IupGetChild( GLOBAL.outlineTree.getZBoxHandle, pos );

			if( actTree != null )
			{
				for( int i = IupGetInt( actTree, "COUNT" ) - 1; i > 0; --i )
				{
					CASTnode _node = cast(CASTnode) IupGetAttributeId( actTree, "USERDATA", i );
					if( _node !is null )
					{
						if( _node.lineNumber == _ln  )
						{
							insertID = i;
							IupSetAttributeId( actTree, "DELNODE", i, "SELECTED" );
						}
					}
				}

				if( insertID == -1 )
				{
					for( int i = IupGetInt( actTree, "COUNT" ) - 1; i > 0 ; --i )
					{
						CASTnode _node = cast(CASTnode) IupGetAttributeId( actTree, "USERDATA", i );
						if( _node !is null )
						{
							if( _node.lineNumber < _ln )
							{
								insertID = i + 1;
								break;
							}
						}
					}
				}

				if( insertID > 0 ) insertID --;
			}
		}
		return insertID;
	}

	void createLayout()
	{
		// Outline Toolbar
		outlineButtonCollapse = IupButton( null, null );
		IupSetAttributes( outlineButtonCollapse, "ALIGNMENT=ARIGHT:ACENTER,FLAT=YES,IMAGE=icon_collapse,VISIBLE=NO" );
		IupSetAttribute( outlineButtonCollapse, "TIP", GLOBAL.languageItems["collapse"].toCString );
		IupSetCallback( outlineButtonCollapse, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			Ihandle* tree = GLOBAL.outlineTree.getActiveTree();
			if( tree != null )
			{
				int id = IupGetInt( tree, "VALUE" );
				
				if( id <= 0 )
				{
					if( fromStringz( IupGetAttributeId( tree, "STATE", 0 ) ) == "EXPANDED" )
						IupSetAttribute( tree, "EXPANDALL", "NO" );
					else
					{
						IupSetAttribute( tree, "EXPANDALL", "YES" );
						IupSetAttribute( tree, "TOPITEM", "YES" ); // Set position to top
					}
				}
				else
				{
					int 	nowDepth = IupGetIntId( tree, "DEPTH", id );
					char*	nowState = IupGetAttributeId( tree, "STATE", id );
					
					if( nowState != null )
					{
						for( int i = IupGetInt( tree, "COUNT" ) - 1; i > 0; --i )
						{
							if( IupGetIntId( tree, "DEPTH", i ) == nowDepth )
							{
								if( IupGetIntId( tree, "CHILDCOUNT", i ) > 0 )
								{
									if( fromStringz( IupGetAttributeId( tree, "KIND", i ) ) == "BRANCH" )
									{
										if( fromStringz( nowState ) == "EXPANDED" )
											IupSetAttributeId( tree, "STATE", i, "COLLAPSED" );
										else
											IupSetAttributeId( tree, "STATE", i, "EXPANDED" );
									}
								}
							}
						}
					}
				}
			}
			return IUP_DEFAULT;
		});
		
		outlineButtonPR = IupButton( null, "PR" );
		IupSetAttributes( outlineButtonPR, "ALIGNMENT=ARIGHT:ACENTER,FLAT=YES,IMAGE=icon_show_pr,VISIBLE=NO,NAME=button_OutlinePR" );
		IupSetAttribute( outlineButtonPR, "TIP", GLOBAL.languageItems["showpr"].toCString );
		IupSetCallback( outlineButtonPR, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			if( GLOBAL.outlineTree.showIndex == 3 ) GLOBAL.outlineTree.showIndex = 0; else GLOBAL.outlineTree.showIndex ++;

			Ihandle* _ih = IupGetDialogChild( GLOBAL.mainDlg, "button_OutlinePR" );
			if( _ih != null )
			{
				switch( GLOBAL.outlineTree.showIndex )
				{
					case 0:		IupSetAttribute( _ih, "IMAGE", "icon_show_pr" ); break;
					case 1:		IupSetAttribute( _ih, "IMAGE", "icon_show_p" ); break;
					case 2:		IupSetAttribute( _ih, "IMAGE", "icon_show_r" ); break;
					default:	IupSetAttribute( _ih, "IMAGE", "icon_show_nopr" ); break;
				}
			}
			
			// Change All Documents
			for( int i = 0; i < IupGetChildCount( GLOBAL.outlineTree.getZBoxHandle ); ++ i )
				GLOBAL.outlineTree.changePR( IupGetChild( GLOBAL.outlineTree.getZBoxHandle, i ) );
			//GLOBAL.outlineTree.changePR();
			
			return IUP_DEFAULT;
		});
		

		outlineToggleAnyWord = IupToggle( null, null );
		IupSetAttributes( outlineToggleAnyWord, "ALIGNMENT=ARIGHT:ACENTER,FLAT=YES,IMAGE=icon_wholeword,VALUE=OFF,VISIBLE=NO,NAME=button_OutlineWholeWord" );
		IupSetAttribute( outlineToggleAnyWord, "TIP", GLOBAL.languageItems["searchanyword"].toCString );
		

		outlineButtonShowLinenum = IupToggle( null, null );
		IupSetAttributes( outlineButtonShowLinenum, "ALIGNMENT=ARIGHT:ACENTER,FLAT=YES,IMAGE=icon_show_linenum,VALUE=OFF,VISIBLE=NO,NAME=button_OutlineShowLinenum" );
		IupSetAttribute( outlineButtonShowLinenum, "TIP", GLOBAL.languageItems["showln"].toCString );
		IupSetCallback( outlineButtonShowLinenum, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			// Change All Documents
			for( int i = 0; i < IupGetChildCount( GLOBAL.outlineTree.getZBoxHandle ); ++ i )
				GLOBAL.outlineTree.changePR( IupGetChild( GLOBAL.outlineTree.getZBoxHandle, i ) );
				
			//GLOBAL.outlineTree.changePR();
			return IUP_DEFAULT;
		});		


		outlineButtonFresh = IupButton( null, null );
		IupSetAttributes( outlineButtonFresh, "ALIGNMENT=ARIGHT:ACENTER,FLAT=YES,IMAGE=icon_refresh,VISIBLE=NO,NAME=button_OutlineRefresh" );
		IupSetAttribute( outlineButtonFresh, "TIP", GLOBAL.languageItems["sc_reparse"].toCString );
		IupSetCallback( outlineButtonFresh, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			CScintilla cSci = actionManager.ScintillaAction.getActiveCScintilla();
			GLOBAL.outlineTree.refresh( cSci );
			return IUP_DEFAULT;
		});

		Ihandle* outlineButtonHide = IupButton( null, null );
		IupSetAttributes( outlineButtonHide, "ALIGNMENT=ALEFT,FLAT=YES,IMAGE=icon_shift_l" );
		IupSetAttribute( outlineButtonHide, "TIP", GLOBAL.languageItems["hide"].toCString );
		IupSetCallback( outlineButtonHide, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			menu.outlineMenuItem_cb( GLOBAL.menuOutlineWindow );
			return IUP_DEFAULT;
		});

		Ihandle* outlineToolbarTitleImage = IupLabel( null );
		IupSetAttributes( outlineToolbarTitleImage, "IMAGE=icon_outline,ALIGNMENT=ALEFT:ACENTER" );

		Ihandle* outlineToolbarH = IupHbox( outlineToolbarTitleImage, IupFill, outlineButtonCollapse, outlineButtonPR, outlineButtonShowLinenum, outlineToggleAnyWord, outlineButtonFresh, outlineButtonHide, null );
		IupSetAttributes( outlineToolbarH, "ALIGNMENT=ACENTER,SIZE=NULL" );


		outlineTreeNodeList = IupList( null );
		IupSetAttributes( outlineTreeNodeList, "ACTIVE=YES,DROPDOWN=YES,SHOWIMAGE=YES,EDITBOX=YES,EXPAND=YES,DROPEXPAND=NO,VISIBLEITEMS=8,VISIBLE=NO,NAME=list_Outline" );
		IupSetAttribute( outlineTreeNodeList, "FGCOLOR", GLOBAL.editColor.outlineFore.toCString );
		IupSetAttribute( outlineTreeNodeList, "BGCOLOR", GLOBAL.editColor.outlineBack.toCString );
		IupSetCallback( outlineTreeNodeList, "DROPDOWN_CB",cast(Icallback) &COutline_List_DROPDOWN_CB );
		IupSetCallback( outlineTreeNodeList, "ACTION",cast(Icallback) &COutline_List_ACTION );
		IupSetCallback( outlineTreeNodeList, "K_ANY",cast(Icallback) &COutline_List_K_ANY );
		version(Windows) IupSetCallback( outlineTreeNodeList, "EDIT_CB",cast(Icallback) &COutline_List_EDIT_CB );
		
		

		layoutHandle = IupVbox( outlineToolbarH, outlineTreeNodeList, zBoxHandle, null );
		IupSetAttributes( layoutHandle, GLOBAL.cString.convert( "ALIGNMENT=ARIGHT,EXPANDCHILDREN=YES,GAP=2" ) );
		
		GLOBAL.objectDefaultParser = loadObjectParser();
	}

	void toBoldTitle( Ihandle* _tree, int id )
	{
		int commaPos = Util.index( GLOBAL.fonts[4].fontString, "," );
		if( commaPos < GLOBAL.fonts[4].fontString.length )
		{
			char[] fontString = Util.substitute( GLOBAL.fonts[5].fontString.dup, ",", ",Bold " );
			IupSetAttributeId( _tree, "TITLEFONT", id, toStringz( fontString ) );
		}
	}	

	public:
	this()
	{
		zBoxHandle = IupZbox( null );
		IupSetAttributes( zBoxHandle, "NAME=zbox_Outline" );
		createLayout();
	}

	~this()
	{
	}

	void changeColor()
	{
		IupSetAttribute( outlineTreeNodeList, "FGCOLOR", GLOBAL.editColor.outlineFore.toCString );
		IupSetAttribute( outlineTreeNodeList, "BGCOLOR", GLOBAL.editColor.outlineBack.toCString );
		
		for( int i = 0; i < IupGetChildCount( zBoxHandle ); ++i )
		{
			Ihandle* ih = IupGetChild( zBoxHandle, i ); // tree
			if( ih != null )
			{
				IupSetAttribute( ih, "BGCOLOR", GLOBAL.editColor.outlineBack.toCString );
				for( int j = 0; j < IupGetInt( ih, "COUNT" ); ++ j )
				{
					if( j == 0 )
					{
						IupSetAttributeId( ih, "COLOR", 0, GLOBAL.editColor.prjTitle.toCString );
					}
					else
					{
						auto _node = cast(CASTnode) IupGetAttributeId( ih, "USERDATA", j );
						if( _node !is null )
						{
							switch( lowerCase( _node.protection ) )
							{
								case "private", "protected":	break;
								default:						IupSetAttributeId( ih, "COLOR", j, GLOBAL.editColor.outlineFore.toCString );
							}
						}
					}
				}
			}
		}
	}


	Ihandle* getLayoutHandle()
	{
		return layoutHandle;
	}

	Ihandle* getActiveTree()
	{
		//if( IupGetChildCount( GzBoxHandle ) ) < 1 return null;
		int pos = IupGetInt( zBoxHandle, "VALUEPOS" ); // Get active zbox pos
		if( pos >= 0 ) return IupGetChild( zBoxHandle, pos );

		return null;
	}

	void createTree( CASTnode head )
	{
		if( head !is null )
		{
			version(FBIDE)
			{
				if( head.kind == B_BAS || head.kind == B_BI )
				{
					char[] fullPath = head.name;
					
					cleanTree( fullPath );

					Ihandle* tree = IupTree();
					IupSetAttributes( tree, GLOBAL.cString.convert( "ADDROOT=YES,EXPAND=YES,RASTERSIZE=0x" ) );
					IupSetAttribute( tree, "BGCOLOR", GLOBAL.editColor.outlineBack.toCString );
					
					IupSetAttribute( tree, "TITLE", toStringz( fullPath ) );
					IupSetAttributeId( tree, "COLOR", 0, GLOBAL.editColor.prjTitle.toCString );
					
					toBoldTitle( tree, 0 );
					//IupSetCallback( tree, "SELECTION_CB", cast(Icallback) &COutline_SELECTION_CB );
					IupSetCallback( tree, "BUTTON_CB", cast(Icallback) &COutline_BUTTON_CB );

					IupAppend( zBoxHandle, tree );
					IupMap( tree );
					IupRefresh( GLOBAL.outlineTree.getZBoxHandle );	
					foreach_reverse( CASTnode t; head.getChildren() )
					{
						append( tree, t, 0 );
					}
					
					IupSetAttribute( zBoxHandle, "FONT",  toStringz( GLOBAL.fonts[5].fontString ) );// Outline
					IupSetAttribute( tree, "FGCOLOR", GLOBAL.editColor.outlineFore.toCString );
					IupSetAttribute( tree, "BGCOLOR", GLOBAL.editColor.outlineBack.toCString );
				}
			}
			version(DIDE)
			{
				if( head.kind == D_MODULE )
				{
					char[] fullPath = head.name;

					Ihandle* tree = IupTree();
					IupSetAttributes( tree, GLOBAL.cString.convert( "ADDROOT=YES,EXPAND=YES,RASTERSIZE=0x" ) );
					IupSetAttribute( tree, "BGCOLOR", GLOBAL.editColor.outlineBack.toCString );
					IupSetAttributeId( tree, "USERDATA", 0, cast(char*) head );
					IupSetAttributeId( tree, "IMAGE", 0, GLOBAL.cString.convert( "IUP_module" ) );
					IupSetAttributeId( tree, "IMAGEEXPANDED", 0, GLOBAL.cString.convert( "IUP_module" ) );				
					IupSetAttribute( tree, "TITLE", toStringz( fullPath ) );
					IupSetAttributeId( tree, "COLOR", 0, GLOBAL.editColor.prjTitle.toCString );
					
					IupSetAttributeId( tree, "FONTSTYLE", 0, "BOLD" ); // Bold
					IupSetCallback( tree, "BUTTON_CB", cast(Icallback) &COutline_BUTTON_CB );

					IupAppend( zBoxHandle, tree );
					IupMap( tree );
					IupRefresh( GLOBAL.outlineTree.getZBoxHandle );	
					foreach_reverse( CASTnode t; head.getChildren() )
					{
						append( tree, t, 0 );
					}
					
					IupSetAttribute( zBoxHandle, "FONT",  toStringz( GLOBAL.fonts[5].fontString ) );// Outline
					IupSetAttribute( tree, "FGCOLOR", GLOBAL.editColor.outlineFore.toCString );
					IupSetAttribute( tree, "BGCOLOR", GLOBAL.editColor.outlineBack.toCString );
					if( fromStringz( IupGetGlobal( "DRIVER" ) ) != "GTK" )
						if( GLOBAL.editColor.project_HLT.toDString.length ) IupSetAttribute( tree, "HLCOLOR", GLOBAL.editColor.project_HLT.toCString );
				}
			}
			
			if( IupGetChildCount( zBoxHandle ) > 0 )
			{
				IupSetAttribute( outlineTreeNodeList, "VISIBLE", "YES" );
				IupSetAttribute( outlineButtonCollapse, "VISIBLE", "YES" );
				IupSetAttribute( outlineButtonPR, "VISIBLE", "YES" );
				IupSetAttribute( outlineToggleAnyWord, "VISIBLE", "YES" );
				IupSetAttribute( outlineButtonShowLinenum, "VISIBLE", "YES" );
				IupSetAttribute( outlineButtonFresh, "VISIBLE", "YES" );
			}
		}
	}

	void changeTree( char[] fullPath )
	{
		for( int i = 0; i < IupGetChildCount( zBoxHandle ); ++i )
		{
			Ihandle* ih = IupGetChild( zBoxHandle, i );
			if( ih != null )
			{
				char[] _fullPath = fromStringz( IupGetAttributeId( ih, "TITLE", 0 ) );
				version(DIDE)
				{
					auto _node = cast(CASTnode) IupGetAttributeId( ih, "USERDATA", 0 );
					if( _node !is null ) _fullPath = _node.type; else _fullPath = "";
				}

				if( fullPath == _fullPath )
				{
					IupSetInt( zBoxHandle, "VALUEPOS", i );
					break;
				}
			}
		}
	}

	void cleanTree( char[] fullPath, bool bDestroy = true )
	{
		for( int i = 0; i < IupGetChildCount( GLOBAL.outlineTree.getZBoxHandle ); ++i )
		{
			Ihandle* ih = IupGetChild( GLOBAL.outlineTree.getZBoxHandle, i ); 
			if( ih != null )
			{
				char[] _fullPath = fromStringz( IupGetAttributeId( ih, "TITLE", 0 ) );
				version(DIDE)
				{
					auto _node = cast(CASTnode) IupGetAttributeId( ih, "USERDATA", 0 );
					if( _node !is null ) _fullPath = _node.type; else _fullPath = "";
				}

				if( fullPath == _fullPath )
				{
					IupSetAttribute( ih, "DELNODE", "ALL" );
					if( bDestroy ) IupDestroy( ih );

					if( fullPath.length >= 7 )
					{
						if( fullPath[0..7] == "NONAME#" )
						{
							if( fullPathByOS( fullPath ) in GLOBAL.parserManager )
							{
								auto pParser = GLOBAL.parserManager[fullPathByOS(fullPath)];
								if( pParser !is null ) delete pParser;
								GLOBAL.parserManager.remove( fullPathByOS(fullPath) );
							}
						}
					}
					
					break;
				}
			}
		}
		
		if( IupGetChildCount( zBoxHandle ) == 0 )
		{
			IupSetAttribute( outlineTreeNodeList, "VISIBLE", "NO" );
			IupSetAttribute( outlineTreeNodeList, "VALUE", "" );
			IupSetAttribute( outlineButtonCollapse, "VISIBLE", "NO" );
			IupSetAttribute( outlineButtonPR, "VISIBLE", "NO" );
			IupSetAttribute( outlineToggleAnyWord, "VISIBLE", "NO" );
			IupSetAttribute( outlineButtonShowLinenum, "VISIBLE", "NO" );
			IupSetAttribute( outlineButtonFresh, "VISIBLE", "NO" );
		}
	}

	Ihandle* getTree( char[] fullPath )
	{
		for( int i = 0; i < IupGetChildCount( GLOBAL.outlineTree.getZBoxHandle ); ++i )
		{
			Ihandle* ih = IupGetChild( GLOBAL.outlineTree.getZBoxHandle, i ); 
			if( ih != null )
			{
				char[] _fullPath = fromStringz( IupGetAttributeId( ih, "TITLE", 0 ) );
				version(DIDE)
				{
					auto _node = cast(CASTnode) IupGetAttributeId( ih, "USERDATA", 0 );
					if( _node !is null ) _fullPath = _node.type; else _fullPath = "";
				}				

				if( fullPath == _fullPath ) return ih;
			}
		}

		return null;
	}
	

	Ihandle* getZBoxHandle(){ return zBoxHandle; }


	CASTnode createParserByText( char[] fullPath, char[] document )
	{
		if( GLOBAL.enableParser != "ON" ) return null;
		
		scope f = new FilePath( fullPath );
		char[] _ext = lowerCase( f.ext() );

		version(FBIDE)	if( !tools.isParsableExt( f.ext, 7 ) )	return null;
		version(DIDE)	if( _ext != "d" && _ext != "di" )	return null;
		
		GLOBAL.Parser.updateTokens( GLOBAL.scanner.scan( document ) );
		GLOBAL.parserManager[fullPathByOS(fullPath)] = GLOBAL.Parser.parse( fullPath );

		Ihandle* _tree = getTree( fullPath );
		if( _tree != null )	cleanTree( fullPath );
		createTree( GLOBAL.parserManager[fullPathByOS(fullPath)] );
		
		return GLOBAL.parserManager[fullPathByOS(fullPath)];
	}


	CASTnode loadFile( char[] fullPath )
	{
		if( GLOBAL.enableParser != "ON" ) return null;
		
		scope f = new FilePath( fullPath );

		char[] _ext = lowerCase( f.ext() );

		version(FBIDE)	if( !tools.isParsableExt( f.ext, 7 ) )	return null;
		version(DIDE)	if( _ext != "d" && _ext != "di" )	return null;
		
		if( fullPathByOS(fullPath) in GLOBAL.scintillaManager )
		{
			if( fullPathByOS(fullPath) in GLOBAL.parserManager )
			{
				Ihandle* _tree = getTree( fullPath );
				if( _tree == null ) createTree( GLOBAL.parserManager[fullPathByOS(fullPath)] );
			}
			else
			{
				char[] document = GLOBAL.scintillaManager[fullPathByOS(fullPath)].getText();
				GLOBAL.Parser.updateTokens( GLOBAL.scanner.scan( document ) );
				GLOBAL.parserManager[fullPathByOS(fullPath)] = GLOBAL.Parser.parse( fullPath );
				Ihandle* _tree = getTree( fullPath );
				if( _tree != null )	cleanTree( fullPath );
				createTree( GLOBAL.parserManager[fullPathByOS(fullPath)] );
			}
			changeTree( fullPath );
		}
		else
		{
			return null;
		}

		/+
		CScintilla actCSci;
		
		foreach( CScintilla cSci; GLOBAL.scintillaManager )
		{
			if( fullPathByOS(fullPath) == fullPathByOS(cSci.getFullPath()) )
			{
				actCSci = cSci;
				break;
			}
		}


		if( actCSci !is null )
		{
			if( fullPathByOS(fullPath) in GLOBAL.parserManager )
			{
				cleanTree( fullPath );
			}
			else
			{
				char[] document = actCSci.getText();
				GLOBAL.Parser.updateTokens( GLOBAL.scanner.scan( document ) );
				GLOBAL.parserManager[fullPathByOS(fullPath)] = GLOBAL.Parser.parse( fullPath );
				//IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( "\t"~fullPath ) );
			}

			if( GLOBAL.parserManager[fullPathByOS(fullPath)] !is null ) createTree( GLOBAL.parserManager[fullPathByOS(fullPath)] );
			CScintilla nowCsci = ScintillaAction.getActiveCScintilla();
			if( nowCsci == actCSci ) changeTree( fullPath );
		}
		else
		{
			if( fullPathByOS(fullPath) in GLOBAL.parserManager )
			{
			}
			else
			{
				// Don't Create Tree
				// Parser
				if( f.exists() )
				{
					GLOBAL.Parser.updateTokens( GLOBAL.scanner.scanFile( fullPath ) );
					GLOBAL.parserManager[fullPathByOS(fullPath)] = GLOBAL.Parser.parse( fullPath );
					//IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( fullPath ) );
				}
			}
		}
		+/

		return GLOBAL.parserManager[fullPathByOS(fullPath)];

		//hardRefresh( fullPath );
	}
	
	CASTnode loadParser( char[] fullPath )
	{
		if( GLOBAL.enableParser != "ON" ) return null;
		
		scope f = new FilePath( fullPath );

		char[] _ext = lowerCase( f.ext() );

		version(FBIDE)	if( !tools.isParsableExt( f.ext, 7 ) )	return null;
		version(DIDE)	if( _ext != "d" && _ext != "di" )	return null;		

		if( fullPathByOS(fullPath) in GLOBAL.parserManager )
		{
			return GLOBAL.parserManager[fullPathByOS(fullPath)];
		}
		else
		{
			// Don't Create Tree
			// Parser
			if( f.exists() )
			{
				if( GLOBAL.Parser.updateTokens( GLOBAL.scanner.scanFile( fullPath ) ) )
				{
					GLOBAL.parserManager[fullPathByOS(fullPath)] = GLOBAL.Parser.parse( fullPath );
					return GLOBAL.parserManager[fullPathByOS(fullPath)];
				}
			}
		}

		return null;
	}

	char[] getImageName( CASTnode _node )
	{
		char[] prot;
		if( _node.protection.length )
		{
			if( _node.protection != "public" && _node.protection != "shared" ) prot = "_" ~ _node.protection;
		}

		version(FBIDE)
		{
			switch( _node.kind )
			{
				case B_DEFINE | B_VARIABLE: return "IUP_define_var";
				case B_DEFINE | B_FUNCTION: return "IUP_define_fun";
				case B_VARIABLE:
					if( _node.name.length )
					{
						if( _node.name[$-1] == ')' ) return ( "IUP_variable_array" ~ prot ); else return( "IUP_variable" ~ prot );
					}
					break;

				case B_FUNCTION:			return ( "IUP_function" ~ prot );
				case B_SUB:					return ( "IUP_sub" ~ prot );
				case B_OPERATOR:			return "IUP_operator";
				case B_PROPERTY:	
					if(_node.type.length )
					{
						if( _node.type[0] == '(' ) return "IUP_property"; else return "IUP_property_var";
					}
					break;

				case B_CTOR:				return "IUP_ctor";
				case B_DTOR:				return "IUP_dtor";
				case B_TYPE:				return "IUP_struct";
				case B_CLASS:				return "IUP_class";
				case B_ENUM:				return "IUP_enum";
				case B_ENUMMEMBER:			return "IUP_enummember";
				case B_UNION:				return "IUP_union";
				case B_ALIAS:				return "IUP_alias";
				case B_NAMESPACE:			return "IUP_namespace";
				case B_MACRO:				return "IUP_macro";
				case B_SCOPE:				return "IUP_scope";
				default:					return "IUP_variable";
			}
		}
		
		version(DIDE)
		{
			switch( _node.kind )
			{
				case D_IMPORT:
					if( _node.protection != "public" ) prot = "_private";
					return ( "IUP_import" ~ prot );

				case D_VARIABLE:
					if( _node.type.length )
					{
						if( _node.type[$-1] == ']' ) return ( "IUP_variable_array" ~ prot ); else return( "IUP_variable" ~ prot );
					}
					break;

		
				case D_FUNCTION:			return ( "IUP_function" ~ prot );
				case D_INTERFACE:			return "IUP_interface";
				case D_TEMPLATE:			return "IUP_template";
				case D_CTOR:				return "IUP_ctor";
				case D_DTOR:				return "IUP_dtor";
				case D_STRUCT:				return "IUP_struct";
				case D_CLASS:				return "IUP_class";
				case D_ENUM:				return "IUP_enum";
				case D_ENUMMEMBER:			return "IUP_enummember";
				case D_UNION:				return "IUP_union";
				case D_ALIAS:				return "IUP_alias";
				case D_VERSION:				if( _node.type.length) return "IUP_versionspec"; else return "IUP_version";
				case D_DEBUG:				if( _node.type.length) return "IUP_debugspec"; else return "IUP_debug";
				default:					return "IUP_variable";
			}
		}

		return "IUP_variable";
	}


	int removeNodeAndGetInsertIndexByLineNumber( int _ln )
	{
		int insertID = 0;
		
		try
		{
			Ihandle* actTree = getActiveTree();
			
			if( actTree != null )
			{
				//bool bEqual;
				for( int i = IupGetInt( actTree, "COUNT" ) - 1; i > 0; --i )
				{
					CASTnode _node = cast(CASTnode) IupGetAttributeId( actTree, "USERDATA", i );
					if( _node !is null )
					{
						if( _node.lineNumber < _ln )
						{
							if( _node.endLineNum > _ln )
							{
								insertID = -i;
								break;
							}
							else
							{
								int	sonID = i;
								int parentID = IupGetIntId( actTree, "PARENT", sonID );
								
								while( parentID > 0 )
								{
									CASTnode _parentNode = cast(CASTnode) IupGetAttributeId( actTree, "USERDATA", parentID );
									if( _parentNode is null ) throw new Exception( "Insert & Remove Outline Tree Node Error!" );

									if( _parentNode.endLineNum < _ln )
									{
										sonID = insertID = parentID; // New node out BRANCH block
										parentID = IupGetIntId( actTree, "PARENT", sonID );
									}
									else
									{
										insertID = sonID; // New node in BRANCH block
										break;
									}									
								}
								
								if( parentID <= 0 ) insertID = sonID; // parentID = 0 = root node
								
								break;
							}
						}
						else if( _node.lineNumber == _ln  )
						{
							IupSetAttributeId( actTree, "DELNODE", i, "SELECTED" );
						}
					}
				}
			}
		}
		catch( Exception e )
		{
			IupMessage( "Error", toStringz( e.toString ~ "\0" ) );
			throw e;
		}

		return insertID;
	}

	void insertNodeByLineNumber( CASTnode[] newASTNodes, int insertID )
	{
		//if( insertID < 0 ) return;

		try
		{
			Ihandle* actTree = getActiveTree();
			if( actTree != null )
			{			
				foreach_reverse( CASTnode _node; newASTNodes )
				{
					//IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( " InsertID= " ~ Integer.toString(insertID) ) );
					if( insertID <= 0 ) append( actTree, _node, -insertID ); else append( actTree, _node, insertID, true );
				}

				int markID = IupGetInt( actTree, "LASTADDNODE" ) + newASTNodes.length - 1;
				version(Windows) IupSetAttributeId( actTree, "MARKED", markID, "YES" ); else IupSetInt( actTree, "VALUE", markID );
			}
		}
		catch( Exception e ){}		
	}

	void insertBlockNodeByLineNumber( CASTnode newASTNode, int insertID )
	{
		//if( insertID < 0 ) return;
		
		try
		{
			Ihandle* actTree = getActiveTree();
			if( actTree != null )
			{
				/+
				int insertID;
				for( int i = IupGetInt( actTree, "COUNT" ) - 1; i > 0; --i )
				{
					CASTnode _node = cast(CASTnode) IupGetAttributeId( actTree, "USERDATA", i );
					if( _node !is null )
					{
						if( _node.lineNumber == _ln  )
						{
							insertID = i;
							IupSetAttributeId( actTree, "DELNODE", i, "SELECTED" );
							break;
						}
						else if( _node.lineNumber < _ln )
						{
							insertID = i + 1;
							break;
						}
					}
				}

				if( insertID > 0 ) insertID --;
				+/
				if( insertID <= 0 ) append( actTree, newASTNode, insertID ); else append( actTree, newASTNode, insertID, true );
				int markID = IupGetInt( actTree, "LASTADDNODE" );
				version(Windows) IupSetAttributeId( actTree, "MARKED", markID, "YES" ); else IupSetInt( actTree, "VALUE", markID );
			}
		}
		catch( Exception e ){}
	}	

	void markTreeNode( int _ln = -1, char[] _name = "-NULL", int _kind = -1, char[] _type = "-NULL" )
	{
		Ihandle* actTree = getActiveTree();
		if( actTree != null )
		{
			for( int i = IupGetInt( actTree, "COUNT" ) - 1; i > 0; --i )
			{
				CASTnode _node = cast(CASTnode) IupGetAttributeId( actTree, "USERDATA", i );
				bool bMatch;
				
				if( _node !is null )
				{
					if( _ln != -1 )
					{
						if( _node.lineNumber == _ln  )
						{
							bMatch = true; 
						}
						else if( _node.lineNumber < _ln  )
						{
							return;
						}
						else
						{
							continue;
						}
					}
					if( _name != "-NULL" )
					{
						if( _node.name == _name  ) bMatch = true; else continue;
					}
					if( _kind != -1 )
					{
						if( _node.kind == _kind  ) bMatch = true; else continue;
					}
					if( _type != "-NULL" )
					{
						if( _node.type == _type  ) bMatch = true; else continue;
					}
				}

				if( bMatch )
				{
					//IupSetAttributeId( actTree, "MARKED", i, "YES" );
					version(Windows) IupSetAttributeId( actTree, "MARKED", i, "YES" ); else IupSetInt( actTree, "VALUE", i );
					return;
				}
			}
		}			
	}

	bool refresh( CScintilla cSci )
	{
		if( GLOBAL.enableParser != "ON" ) return false;

		scope f = new FilePath( cSci.getFullPath );

		char[] _ext = lowerCase( f.ext() );
		version(FBIDE)	if( !tools.isParsableExt( f.ext, 7 ) ) return false;
		version(DIDE)	if( _ext != "d" && _ext != "di" ) 	return false;
		
		if( cSci !is null )
		{
			if( fullPathByOS( cSci.getFullPath ) in GLOBAL.parserManager )
			{
				Ihandle* actTree = getTree( cSci.getFullPath );
				if( actTree != null )
				{
					try
					{
						char[] document = cSci.getText();
						CASTnode astHeadNode;
						GLOBAL.Parser.updateTokens( GLOBAL.scanner.scan( document ) );
						astHeadNode = GLOBAL.Parser.parse( cSci.getFullPath );
						
						CASTnode temp = GLOBAL.parserManager[fullPathByOS(cSci.getFullPath)];
						GLOBAL.parserManager[fullPathByOS(cSci.getFullPath)] = astHeadNode;
						delete temp;

						IupSetAttributeId( actTree, "DELNODE", 0, "CHILDREN" );
						version(DIDE)
						{
							IupSetAttributeId( actTree, "USERDATA", 0, cast(char*) astHeadNode );
							IupSetAttribute( actTree, "TITLE", toStringz( astHeadNode.name ) );						
						}
						IupSetAttributeId( actTree, "COLOR", 0, GLOBAL.editColor.outlineFore.toCString );
						foreach_reverse( CASTnode t; astHeadNode.getChildren() )
						{
							append( actTree, t, 0 );
						}
						
						// Reparse Lexer
						int dummy;
						version(FBIDE) dummy = IupScintillaSendMessage( cSci.getIupScintilla, 4003, 0, -1 ); // SCI_COLOURISE 4003

						return true;
					}
					catch( Exception e ){}
				}
			}
		}

		/+
		try
		{
			ReparseThread p = new ReparseThread( cSci.getFullPath, cSci.getText(), getTree( cSci.getFullPath ) );
			p.start();
		}
		catch( Exception e )
		{
			return false;
		}
		+/

		return true;
	}

	CASTnode parserText( char[] text )
	{
		// Don't Create Tree
		try
		{
			// Parser
			if( GLOBAL.Parser.updateTokens( GLOBAL.scanner.scan( text ) ) )
			{
				version(FBIDE) return GLOBAL.Parser.parse( "_.bas" );
				version(DIDE) return GLOBAL.Parser.parse( "_.d" );
			}
		}
		catch( Exception e )
		{
		}

		return null;
	}
	
	CASTnode loadObjectParser()
	{
		version(FBIDE)
		{
			scope objectFilePath = new FilePath( "settings/FB_BuiltinFunctions.bi" );
			if( objectFilePath.exists )
			{
				return loadParser( fullPathByOS( objectFilePath.toString() ) );
			}
		}
		
		version(DIDE)
		{
			scope objectFilePath = new FilePath( GLOBAL.compilerFullPath );
			objectFilePath.set( objectFilePath.path );
			char[] _path = objectFilePath.parent;
			
			if( _path.length )
				if( _path[$-1] != '/' ) _path ~= '/';
			
			
			objectFilePath.set( _path ~ "import/object.di" );
			
			if( objectFilePath.exists )
			{
				return loadParser( _path ~ "import/object.di" );
			}
			else
			{	
				objectFilePath.set( GLOBAL.compilerFullPath );
				objectFilePath.set( objectFilePath.path );
				objectFilePath.set( objectFilePath.parent );
				_path = objectFilePath.parent;
				if( _path.length )
					if( _path[$-1] != '/' ) _path ~= '/';
				
				objectFilePath.set( _path ~ "src/druntime/import/object.d" );
				if( objectFilePath.exists )
				{
					return loadParser( fullPathByOS( objectFilePath.toString() ) );
				}
			}
		}
		
		return null;
	}
	
	
	void cleanListItems()
	{
		IupSetAttribute( outlineTreeNodeList, "REMOVEITEM", "ALL" );
		listItemASTs.length = 0;
		listItemTreeID.length = 0;
		listItemIndex = 0;
	}
}

extern(C) 
{
	private int COutline_BUTTON_CB( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		int id = IupConvertXYToPos( ih, x, y );

		try
		{
			if( button == IUP_BUTTON1 ) // Left Click
			{
				if( DocumentTabAction.isDoubleClick( status ) )
				{
					if( id > 0 )
					{
						CASTnode _node = cast(CASTnode) IupGetAttributeId( ih, "USERDATA", id );
						
						if( _node !is null )
						{
							char[] _fullPath = fromStringz( IupGetAttributeId( ih, "TITLE", 0 ) ); // Get Tree-Head Title
							version(DIDE)
							{
								CASTnode _headnode = cast(CASTnode) IupGetAttributeId( ih, "USERDATA", 0 );
								if( _headnode !is null ) _fullPath = _headnode.type; else _fullPath = "";
							}
						
							
							ScintillaAction.openFile( _fullPath, _node.lineNumber );
							version(Windows) IupSetAttributeId( ih, "MARKED", id, "YES" ); else IupSetInt( ih, "VALUE", id );

							return IUP_IGNORE;
						}
					}
				}
			}
		}
		catch( Exception e )
		{
			IupMessage( "ERROR", toStringz( "COutline_BUTTON_CB() Error:\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ Integer.toString( e.line ) ) );
			//GLOBAL.IDEMessageDlg.print( "COutline_BUTTON_CB() Error:\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ Integer.toString( e.line ) );
		}

		return IUP_DEFAULT;
	}


	private int COutline_List_DROPDOWN_CB( Ihandle *ih, int state )
	{
		// ListBox open
		if( state == 1 )
		{
			if( IupGetChildCount( GLOBAL.outlineTree.getZBoxHandle ) > 0 )
			{
				int pos = IupGetInt( GLOBAL.outlineTree.getZBoxHandle, "VALUEPOS" ); // Get active zbox pos
				Ihandle* actTree = IupGetChild( GLOBAL.outlineTree.getZBoxHandle, pos );

				char[] imageName, editText = Util.trim( fromStringz( IupGetAttribute( ih, "VALUE" ) ) );
				GLOBAL.outlineTree.cleanListItems();

				bool bAnyWord, bGo;
				Ihandle* _wholeWordHandle = IupGetDialogChild( GLOBAL.mainDlg, "button_OutlineWholeWord" );
				if( _wholeWordHandle != null ) 
				{
					if( fromStringz( IupGetAttribute( _wholeWordHandle, "VALUE" ) ) == "OFF" ) bAnyWord = true; else bAnyWord = false;
				}
				
				for( int i = 1; i < IupGetInt( actTree, "COUNT" ); ++ i )
				{
					CASTnode _node = cast(CASTnode) IupGetAttributeId( actTree, "USERDATA", i );
					
					if( _node !is null )
					{
						if( bAnyWord )
						{
							if( Util.index( lowerCase( _node.name ), lowerCase( editText ) ) < _node.name.length ) bGo = true; else bGo = false;
						}
						else
						{
							if( Util.index( lowerCase( _node.name ), lowerCase( editText ) ) == 0 ) bGo = true; else bGo = false;
						}
						
						if( bGo )
						{
							IupSetAttribute( ih, "APPENDITEM", toStringz( _node.name ) );
							
							GLOBAL.outlineTree.listItemASTs ~= _node;
							GLOBAL.outlineTree.listItemTreeID ~= i;
							
							imageName = GLOBAL.outlineTree.getImageName( _node );
							if( imageName.length ) IupSetAttributeId( ih, "IMAGE", IupGetInt( ih, "COUNT" ), toStringz( imageName ) );
						}
					}
				}
				
				if( IupGetInt( actTree, "COUNT" ) > 0 )
				{
					GLOBAL.outlineTree.listItemIndex = 1;
					version(Windows) IupSetAttribute( ih, "VALUE", IupGetAttribute( ih, "1" ) );
				}
			}
		}
		else	// ListBox close
		{
			/*
			Check module layout -- GlobalKeyPress_CB
			KeyDown = 13
			Trigger Order: keydown -> DROPDOWN_CB -> keyup
			*/
			if( GLOBAL.KeyNumber == 13 ) 
			{
				version(Windows)
				{
					if( IupGetInt( ih, "COUNT" ) > 0 )
					{
						if( GLOBAL.outlineTree.listItemIndex > 0 )
						{
							if( GLOBAL.outlineTree.listItemIndex <= GLOBAL.outlineTree.listItemASTs.length )
							{
								char[] text = Util.trim( fromStringz( IupGetAttribute( ih, "VALUE" ) ).dup );
								if( text.length )
								{
									ScintillaAction.openFile( ScintillaAction.getActiveCScintilla.getFullPath, GLOBAL.outlineTree.listItemASTs[GLOBAL.outlineTree.listItemIndex-1].lineNumber );
									IupSetFocus( ih );
									IupSetAttribute( ih, "SELECTIONPOS", "ALL" );
									Ihandle* tree = GLOBAL.outlineTree.getActiveTree();
									if( tree != null ) version(Windows) IupSetAttributeId( tree, "MARKED", GLOBAL.outlineTree.listItemTreeID[GLOBAL.outlineTree.listItemIndex-1], "YES" ); else IupSetInt( tree, "VALUE", GLOBAL.outlineTree.listItemTreeID[GLOBAL.outlineTree.listItemIndex] );
									IupSetFocus( ScintillaAction.getActiveIupScintilla ); // Set Focus To Ducument
								}
							}
						}
					}
				}
			}
			else if( GLOBAL.KeyNumber == 65307 ) // ESC
			{
				GLOBAL.outlineTree.cleanListItems();
				IupSetAttribute( ih, "VALUE", "" );
			}
			else
			{
				//IupMessage( "",toStringz( Integer.toString( GLOBAL.KeyNumber ) ) );
			}

		}
		
		return IUP_DEFAULT;
	}


	private int COutline_List_ACTION( Ihandle *ih, char *text, int item, int state )
	{
		if( state == 1 )
		{
			GLOBAL.outlineTree.listItemIndex = item;
			
			bool bGo;
			
			version(Windows)
			{
				if( GLOBAL.KeyNumber == -1 ) bGo = true;								// Mouse Click item
			}
			else
			{
				if( GLOBAL.KeyNumber == -1 || GLOBAL.KeyNumber == 13 ) bGo = true;		// Mouse Click item or Enter
			}
			
			
			if( bGo )
			{
				if( IupGetInt( ih, "COUNT" ) > 0 )
				{
					if( item > 0 )
					{
						if( item <= GLOBAL.outlineTree.listItemASTs.length )
						{
							ScintillaAction.openFile( ScintillaAction.getActiveCScintilla.getFullPath, GLOBAL.outlineTree.listItemASTs[--item].lineNumber );
							IupSetFocus( ih );
							IupSetAttribute( ih, "SELECTIONPOS", "ALL" );
							Ihandle* tree = GLOBAL.outlineTree.getActiveTree();
							if( tree != null ) version(Windows) IupSetAttributeId( tree, "MARKED", GLOBAL.outlineTree.listItemTreeID[item], "YES" ); else IupSetInt( tree, "VALUE", GLOBAL.outlineTree.listItemTreeID[item] );
							IupSetFocus( ScintillaAction.getActiveIupScintilla ); // Set Focus To Ducument
						}
					}
				}
			}
			else
			{
				version(Windows)
				{
					if( IupGetInt( ih, "COUNT" ) > 0 && item > 0 )
					{
						Ihandle* tree = GLOBAL.outlineTree.getActiveTree();
						if( tree != null ) IupSetAttributeId( tree, "MARKED", GLOBAL.outlineTree.listItemTreeID[--item], "YES" );
					}
				}
			}
		}
		
		return IUP_DEFAULT;
	}	


	version(linux)
	{
		private int COutline_List_K_ANY( Ihandle *ih, int c )
		{
			if( IupGetChildCount( GLOBAL.outlineTree.getZBoxHandle ) > 0 )
			{
				if( c == 13 )
				{
					IupSetAttribute( ih, "SHOWDROPDOWN", "YES" );
				}
				else if( GLOBAL.KeyNumber == 65307 ) // ESC
				{
					GLOBAL.outlineTree.cleanListItems();
					IupSetAttribute( ih, "VALUE", "" );
				}					
			}
			return IUP_DEFAULT;
		}
	}
	else
	{
		private int COutline_List_K_ANY( Ihandle *ih, int c )
		{
			if( IupGetChildCount( GLOBAL.outlineTree.getZBoxHandle ) > 0 )
			{
				if( c == 13 )
				{
					if( IupGetInt( ih, "COUNT" ) > 0 )
					{
						if( GLOBAL.outlineTree.listItemIndex > 0 )
						{
							if( GLOBAL.outlineTree.listItemIndex <= GLOBAL.outlineTree.listItemASTs.length )
							{
								char[] text = Util.trim( fromStringz( IupGetAttribute( ih, "VALUE" ) ).dup );
								if( text.length )
								{
									ScintillaAction.openFile( ScintillaAction.getActiveCScintilla.getFullPath, GLOBAL.outlineTree.listItemASTs[GLOBAL.outlineTree.listItemIndex-1].lineNumber );
									IupSetFocus( ih );
									IupSetAttribute( ih, "SELECTIONPOS", "ALL" );
									Ihandle* tree = GLOBAL.outlineTree.getActiveTree();
									if( tree != null ) version(Windows) IupSetAttributeId( tree, "MARKED", GLOBAL.outlineTree.listItemTreeID[GLOBAL.outlineTree.listItemIndex-1], "YES" ); else IupSetInt( tree, "VALUE", GLOBAL.outlineTree.listItemTreeID[GLOBAL.outlineTree.listItemIndex] );
									IupSetFocus( ScintillaAction.getActiveIupScintilla ); // Set Focus To Ducument
								}
							}
						}
					}
				}
				else if( GLOBAL.KeyNumber == 65307 ) // ESC
				{
					GLOBAL.outlineTree.cleanListItems();
					IupSetAttribute( ih, "VALUE", "" );
				}
			}
			return IUP_DEFAULT;
		}
		
		
		private int COutline_List_EDIT_CB( Ihandle *ih, int c, char *new_value )
		{
			// Avoid mouuse cursor disappear
			char[] screenXY = fromStringz( IupGetAttribute( ih, "SCREENPOSITION" ) ).dup;
			int commaPos = Util.index( screenXY, "," );
			if( commaPos < screenXY.length )
			{
				int screenX = Integer.toInt( screenXY[0..commaPos] );
				int screenY = Integer.toInt( screenXY[commaPos+1..$] );
				
				char[] WH = fromStringz( IupGetAttribute( ih, "RASTERSIZE" ) ).dup;
				int crossPos = Util.index( WH, "x" );
				if( crossPos < WH.length )
				{
					screenY = screenY + Integer.toInt( WH[crossPos+1..$] );
					
					screenXY = Integer.toString( screenX + 8 ) ~ "x" ~ Integer.toString( screenY + 8 );
					IupSetGlobal( "CURSORPOS", toStringz( screenXY ) );
				}
			}
		
			return IUP_DEFAULT;
		}
	}
}