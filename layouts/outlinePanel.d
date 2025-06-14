﻿module layouts.outlinePanel;

private import iup.iup;

private import global, scintilla, actionManager, menu, tools;
private import dialogs.singleTextDlg, dialogs.fileDlg;
private import darkmode.darkmode;
private import parser.ast;
private import std.string, std.conv, std.file, Array = std.array, Path = std.path, Uni = std.uni;

class COutline
{
private:
	import 				iup.iup_scintilla;
	import				parser.scanner, parser.token, parser.parser, parser.autocompletion, std.conv;
	import				core.thread;

	Ihandle*			layoutHandle, zBoxHandle, outlineTreeNodeList, outlineToolBarBox;
	Ihandle*			outlineToolbarTitleImage, outlineButtonCollapse, outlineButtonPR, outlineButtonShowLinenum, outlineToggleAnyWord, outlineButtonFresh, outlineButtonHide;
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

		string prot;
		if( _node.protection.length )
		{
			if( _node.protection != "public" && _node.protection != "shared" ) prot = "_" ~ _node.protection;
		}

		version(FBIDE)
		{
			switch( _node.kind )
			{
				case B_INCLUDE:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_import" );
					break;
					
				case B_VERSION: //, B_VERSION | B_PARAM:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_version" );
					IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_version" );
					break;
					
				case B_DEFINE | B_VARIABLE:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_define_var" );
					break;

				case B_DEFINE | B_FUNCTION:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_define_fun" );
					break;
					
				case B_DEFINE | B_VERSION:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_versionspec" );
					break;
					
				case B_VARIABLE:
					if( _node.type.length )
					{
						if( _node.name[$-1] == ')' )
							IupSetStrAttributeId( rootTree, "IMAGE", lastAddNode, toStringz( "IUP_variable_array" ~ prot ) );
						else
							IupSetStrAttributeId( rootTree, "IMAGE", lastAddNode, toStringz( "IUP_variable" ~ prot ) );
					}
					break;

				case B_FUNCTION:
					if( _node.base == "pointer" )
						IupSetStrAttributeId( rootTree, "IMAGE", lastAddNode, toStringz( "IUP_funptr" ~ prot ) );
					else
					{
						IupSetStrAttributeId( rootTree, "IMAGE", lastAddNode, toStringz( "IUP_function" ~ prot ) );
						IupSetStrAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode,toStringz( "IUP_function" ~ prot ) );
					}
					break;

				case B_SUB:
					if( _node.base == "ctor" )
					{
						IupSetStrAttributeId( rootTree, "IMAGE", lastAddNode, toStringz( "IUP_ctor" ) );
						IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_ctor" );
					}
					else if( _node.base == "dtor" )
					{
						IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_dtor" );
						IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_dtor" );
					}
					else
					{
						IupSetStrAttributeId( rootTree, "IMAGE", lastAddNode, toStringz( "IUP_sub" ~ prot ) );
						IupSetStrAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, toStringz( "IUP_sub" ~ prot ) );
					}
					break;

				case B_OPERATOR:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_operator" );
					IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_operator" );
					
					break;

				case B_PROPERTY:
					if(_node.type.length )
					{
						if( _node.type[0] == '(' )
						{
							IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_property" );
							IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_property" );
						}
						else
						{
							IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_property_var" );
							IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_property_var" );
						}
					}
					
					break;

				case B_CTOR:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_ctor" );
					IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_ctor" );
					break;

				case B_DTOR:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_dtor" );
					IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_dtor" );
					break;

				case B_TYPE:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_struct" );
					IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_struct" );
					break;

				case B_CLASS:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_class" );
					IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_class" );
					break;

				case B_ENUM:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_enum" );
					IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_enum" );
					break;				

				case B_ENUMMEMBER:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_enummember" );
					IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_enummember" );
					break;

				case B_UNION:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_union" );
					IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_union" );
					break;				

				case B_ALIAS:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_alias" );
					break;

				case B_NAMESPACE:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_namespace" );
					IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_namespace" );
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
					IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_scope" );
					break;
					
				case B_WITH:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_with" );
					IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_with" );
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
					IupSetStrAttributeId( rootTree, "IMAGE", lastAddNode, toStringz( "IUP_import" ~ prot ) );
					break;
					
				case D_VARIABLE:
					if( _node.type.length )
					{
						if( _node.type[$-1] == ']' )
							IupSetStrAttributeId( rootTree, "IMAGE", lastAddNode, toStringz( "IUP_variable_array" ~ prot ) );
						else
							IupSetStrAttributeId( rootTree, "IMAGE", lastAddNode, toStringz( "IUP_variable" ~ prot ) );
					}
					break;

				case D_FUNCTIONPTR:
					IupSetStrAttributeId( rootTree, "IMAGE", lastAddNode, toStringz( "IUP_funptr" ~ prot ) );
					break;

				case D_FUNCTIONLITERALS:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_anonymous" );
					IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_anonymous" );
					break;

				case D_FUNCTION:
					IupSetStrAttributeId( rootTree, "IMAGE", lastAddNode, toStringz( "IUP_function" ~ prot ) );
					IupSetStrAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, toStringz( "IUP_function" ~ prot ) );
					break;

				case D_TEMPLATE:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_template" );
					IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_template" );
					break;

				case D_CTOR:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_ctor" );
					IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_ctor" );
					break;

				case D_DTOR:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_dtor" );
					IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_dtor" );
					break;

				case D_STRUCT:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_struct" );
					IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_struct" );
					break;

				case D_CLASS:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_class" );
					IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_class" );
					break;

				case D_INTERFACE:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_interface" );
					IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_interface" );
					break;

				case D_ENUM:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_enum" );
					IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_enum" );
					break;				

				case D_ENUMMEMBER:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_enummember" );
					//IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_enummember" );
					break;

				case D_UNION:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_union" );
					IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_union" );
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
					IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_version" );
					break;

				case D_DEBUG:
					if( _node.type.length )
					{
						IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_debugspec" );
						break;
					}
				
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_debug" );
					IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, "IUP_debug" );
					break;

				default:
					IupSetAttributeId( rootTree, "IMAGE", lastAddNode, "IUP_variable" );
			}
		}
		

		if( GLOBAL.editorSetting00.ColorOutline == "ON" ) restoreSingleNodeColor( rootTree, lastAddNode, _node );
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
			
			string	lineNumString;
			bool	bShowLinenum;
			Ihandle* showLineHandle = IupGetDialogChild( GLOBAL.mainDlg, "button_OutlineShowLinenum" );
			if( showLineHandle != null )
			{
				if( fromStringz( IupGetAttribute( showLineHandle, "VALUE" ) ) == "ON" ) bShowLinenum = true;
			}

			try
			{
				for( int i = 1; i < IupGetInt( actTree, "COUNT" ); ++ i )
				{
					CASTnode _node = cast(CASTnode) IupGetAttributeId( actTree, "USERDATA", i );
					
					if( bShowLinenum ) lineNumString = " .... [" ~ to!(string)( _node.lineNumber ) ~ "]"; else lineNumString = "";
					
					if( _node !is null )
					{
						version(FBIDE)
						{
							switch( _node.kind )
							{
								case B_FUNCTION, B_PROPERTY, B_OPERATOR:
									string _type;
									string _paramString;
									ParserAction.returnTypeAndParameter( _node.type, _type, _paramString );
									switch( showIndex )
									{
										case 0:
											IupSetStrAttributeId( actTree, "TITLE", i, toStringz( _node.name ~ _paramString ~ ( _type.length ? " : " ~ _type : "" ) ~ lineNumString ) );
											break;
										case 1:
											IupSetStrAttributeId( actTree, "TITLE", i, toStringz( _node.name ~ _paramString ~ lineNumString ) );
											break;
										case 2:
											IupSetStrAttributeId( actTree, "TITLE", i, toStringz( _node.name ~ ( _type.length ? " : " ~ _type : "" ) ~ lineNumString ) );
											break;
										default:
											IupSetStrAttributeId( actTree, "TITLE", i, toStringz( _node.name ~ lineNumString ) );
											break;
									}
									break;

								case B_SUB, B_CTOR, B_DTOR, B_MACRO:
									switch( showIndex )
									{
										case 0, 1:
											IupSetStrAttributeId( actTree, "TITLE", i, toStringz( _node.name ~ _node.type ~ lineNumString ) );
											break;
										default:
											IupSetStrAttributeId( actTree, "TITLE", i, toStringz( _node.name ~ lineNumString ) );
											break;
									}
									break;
								
								case B_DEFINE | B_FUNCTION:
									string _paramString = ParserAction.getSeparateParam( _node.type ~ lineNumString );
									switch( showIndex )
									{
										case 0, 1:
											IupSetStrAttributeId( actTree, "TITLE", i, toStringz( _node.name ~ _paramString ~ lineNumString ) );
											break;
										default:
											IupSetStrAttributeId( actTree, "TITLE", i, toStringz( _node.name ~ lineNumString ) );
											break;
									}
									break;
									
								case B_DEFINE | B_VARIABLE, B_DEFINE | B_ALIAS:
									if( showIndex == 0 || showIndex == 2 )
										IupSetStrAttributeId( actTree, "TITLE", i, toStringz( _node.name ~ ( _node.type.length ? " : " ~ _node.type : "" ) ~ lineNumString ) );
									else
										IupSetStrAttributeId( actTree, "TITLE", i, toStringz( _node.name ~ lineNumString ) );
									
									break;

								case B_VARIABLE, B_ALIAS:
									if( showIndex == 0 || showIndex == 2 )
										IupSetStrAttributeId( actTree, "TITLE", i, toStringz( _node.name ~ ( _node.type.length ? " : " ~ _node.type : "" ) ~ lineNumString ) );
									else
										IupSetStrAttributeId( actTree, "TITLE", i, toStringz( _node.name ~ lineNumString ) );
									
									break;
									
								case B_TYPE, B_CLASS, B_UNION, B_ENUM:
									if( showIndex == 0 || showIndex == 2 )
										IupSetStrAttributeId( actTree, "TITLE", i, toStringz( _node.name ~ ( _node.base.length ? " : " ~ _node.base : "" ) ~ lineNumString ) );
									else
										IupSetStrAttributeId( actTree, "TITLE", i, toStringz( _node.name ~ lineNumString ) );
									
									break;

								default:
									IupSetStrAttributeId( actTree, "TITLE", i, toStringz( _node.name ~ lineNumString ) );
									break;
							}
						}
						
						version(DIDE)
						{
							switch( _node.kind )
							{
								case D_IMPORT:
									IupSetStrAttributeId( actTree, "TITLE", i, toStringz( _node.name ~ ( _node.type.length ? " : " ~ _node.type : "" ) ~ lineNumString ) );
									break;						
							
								case D_FUNCTION, D_FUNCTIONLITERALS:
									string _type = _node.type;
									string _paramString;
									ParserAction.returnTypeAndParameter( _node.type, _type, _paramString );
									switch( showIndex )
									{
										case 0:
											IupSetStrAttributeId( actTree, "TITLE", i, toStringz( _node.name ~ _paramString ~ ( _type.length ? " : " ~ _type : "" ) ~ lineNumString ) );
											break;
										case 1:
											IupSetStrAttributeId( actTree, "TITLE", i, toStringz( _node.name ~ _paramString ~ lineNumString ) );
											break;
										case 2:
											IupSetStrAttributeId( actTree, "TITLE", i, toStringz( _node.name ~ ( _type.length ? " : " ~ _type : "" ) ~ lineNumString ) );
											break;
										default:
											IupSetStrAttributeId( actTree, "TITLE", i, toStringz( _node.name ~ lineNumString ) );
											break;
									}
									break;

								case D_CTOR:
									switch( showIndex )
									{
										case 0, 1:
											IupSetStrAttributeId( actTree, "TITLE", i, toStringz( "this" ~ _node.type ~ lineNumString ) );
											break;
										default:
											IupSetStrAttributeId( actTree, "TITLE", i, toStringz( "this" ~ lineNumString ) );
											break;
									}
									break;

								case D_DTOR:
									switch( showIndex )
									{
										case 0, 1:
											IupSetStrAttributeId( actTree, "TITLE", i, toStringz( "~this()" ~ lineNumString ) );
											break;
										default:
											IupSetStrAttributeId( actTree, "TITLE", i, toStringz( "~this" ~ lineNumString ) );
											break;
									}
									break;

								case D_CLASS, D_INTERFACE:
									if( showIndex == 0 || showIndex == 2 )
										IupSetStrAttributeId( actTree, "TITLE", i, toStringz( _node.name ~ ( _node.base.length ? " : " ~ _node.base : "" ) ~ lineNumString ) );
									else
										IupSetStrAttributeId( actTree, "TITLE", i, toStringz( _node.name ~ lineNumString ) );
									
									break;
									
								case D_TEMPLATE:
									if( showIndex == 0 )
										IupSetStrAttributeId( actTree, "TITLE", i, toStringz( _node.name ~ _node.type ~ ( _node.base.length ? " : " ~ _node.base : "" ) ~ lineNumString ) );
									else if( showIndex == 1 )
										IupSetStrAttributeId( actTree, "TITLE", i, toStringz( _node.name ~ _node.type ~ lineNumString ) );
									else if( showIndex == 2 )
										IupSetStrAttributeId( actTree, "TITLE", i, toStringz( _node.name ~ ( _node.base.length ? " : " ~ _node.base : "" ) ~ lineNumString ) );
									else
										IupSetStrAttributeId( actTree, "TITLE", i, toStringz( _node.name ~ lineNumString ) );
									
									break;										
									
								case D_FUNCTIONPTR:
									string _type;
									string _paramString;
									ParserAction.returnTypeAndParameter( _node.type, _type, _paramString );
									switch( showIndex )
									{
										case 0:
											IupSetStrAttributeId( actTree, "TITLE", i, toStringz( _node.name ~ _paramString ~ ( _type.length ? " : " ~ _type : "" ) ~ lineNumString ) );
											break;
										case 1:
											IupSetStrAttributeId( actTree, "TITLE", i, toStringz( _node.name ~ _paramString ~ lineNumString ) );
											break;
										case 2:
											IupSetStrAttributeId( actTree, "TITLE", i, toStringz( _node.name ~ ( _type.length ? " : " ~ _type : "" ) ~ lineNumString ) );
											break;
										default:
											IupSetStrAttributeId( actTree, "TITLE", i, toStringz( _node.name ~ lineNumString ) );
											break;
									}				
									break;	
							
								case D_VARIABLE:
									if( showIndex == 0 || showIndex == 2 )
										IupSetStrAttributeId( actTree, "TITLE", i, toStringz( _node.name ~ ( _node.type.length ? " : " ~ _node.type : "" ) ~ lineNumString ) );
									else
										IupSetStrAttributeId( actTree, "TITLE", i, toStringz( _node.name ~ lineNumString ) );
									
									break;						

								default:
									IupSetStrAttributeId( actTree, "TITLE", i, toStringz( _node.name ~ lineNumString ) );
									break;						
							}
						}
					}
				}
			}
			catch( Exception e )
			{
				IupMessage( "changePR() Error", toStringz( e.toString ) );
			}
		}		
	}
	
	void append( Ihandle* rootTree, CASTnode _node, int bracchID, bool bInsertMode = false )
	{
		int lastAddNode;

		if( _node is null ) return;

		//if( _node.kind & B_SCOPE ) return;

		string	BRANCH, LEAF;
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
		
		string lineNumString;
		Ihandle* showLineHandle = IupGetDialogChild( GLOBAL.mainDlg, "button_OutlineShowLinenum" );
		if( showLineHandle != null )
		{
			if( fromStringz( IupGetAttribute( showLineHandle, "VALUE" ) ) == "ON" ) lineNumString = " .... [" ~ to!(string)( _node.lineNumber ) ~ "]";
		}
		
		bool bNoImage;
		version(FBIDE)
		{
			switch( _node.kind & 16777215 )
			{
				case B_FUNCTION, B_PROPERTY, B_OPERATOR:
					string _type = _node.type;
					string _paramString;
					ParserAction.returnTypeAndParameter( _node.type, _type, _paramString );
					if( _node.kind & B_FUNCTION && _node.base == "pointer" )
					{
						switch( showIndex )
						{
							case 0:
								IupSetStrAttributeId( rootTree, toStringz( LEAF ), bracchID, toStringz( _node.name ~ _paramString ~ ( _type.length ? " : " ~ _type : "" ) ~ lineNumString ) );
								break;
							case 1:
								IupSetStrAttributeId( rootTree, toStringz( LEAF ), bracchID, toStringz( _node.name ~ _paramString ~ lineNumString ) );
								break;
							case 2:
								IupSetStrAttributeId( rootTree, toStringz( LEAF ), bracchID, toStringz( _node.name ~ ( _type.length ? " : " ~ _type : "" ) ~ lineNumString ) );
								break;
							default:
								IupSetStrAttributeId( rootTree, toStringz( LEAF ), bracchID, toStringz( _node.name ~ lineNumString ) );

						}
						break;
					}
					switch( showIndex )
					{
						case 0:
							IupSetStrAttributeId( rootTree, toStringz( BRANCH ), bracchID, toStringz( _node.name ~ _paramString ~ ( _type.length ? " : " ~ _type : "" ) ~ lineNumString ) );
							break;
						case 1:
							IupSetStrAttributeId( rootTree, toStringz( BRANCH ), bracchID, toStringz( _node.name ~ _paramString ~ lineNumString ) );
							break;
						case 2:
							IupSetStrAttributeId( rootTree, toStringz( BRANCH ), bracchID, toStringz( _node.name ~ ( _type.length ? " : " ~ _type : "" ) ~ lineNumString ) );
							break;
						default:
							IupSetStrAttributeId( rootTree, toStringz( BRANCH ), bracchID, toStringz( _node.name ~ lineNumString ) );

					}
					break;

				case B_SUB, B_CTOR, B_DTOR, B_MACRO:
					switch( showIndex )
					{
						case 0, 1:
							IupSetStrAttributeId( rootTree, toStringz( BRANCH ), bracchID, toStringz( _node.name ~ _node.type ~ lineNumString ) );
							break;
						default:
							IupSetStrAttributeId( rootTree, toStringz( BRANCH ), bracchID, toStringz( _node.name ~ lineNumString ) );
					}				
					break;
					
				case B_DEFINE | B_FUNCTION:
					string _paramString = ParserAction.getSeparateParam( _node.type );
					switch( showIndex )
					{
						case 0, 1:
							IupSetStrAttributeId( rootTree, toStringz( BRANCH ), bracchID, toStringz( _node.name ~ _paramString ~ lineNumString ) );
							break;
						default:
							IupSetStrAttributeId( rootTree, toStringz( BRANCH ), bracchID, toStringz( _node.name ~ lineNumString ) );
					}
					break;
					
				case B_DEFINE | B_VARIABLE, B_DEFINE | B_ALIAS:
					if( showIndex == 0 || showIndex == 2 )
					{
						IupSetStrAttributeId( rootTree, toStringz( BRANCH ), bracchID, toStringz( _node.name ~ ( _node.type.length ? " : " ~ _node.type : "" ) ~ lineNumString ) );
					}
					else
					{
						IupSetStrAttributeId( rootTree, toStringz( BRANCH ), bracchID, toStringz( _node.name ~ lineNumString ) );
					}
					break;
					
				case B_DEFINE | B_VERSION:
					IupSetStrAttributeId( rootTree, toStringz( LEAF ), bracchID, toStringz( _node.name ~ lineNumString ) );
					break;					

				case B_VARIABLE:
					if( !_node.type.length )
					{
						if( _node.base.length )
						{
							string[] types = ParserAction.getDivideWordWithoutSymbol( _node.base );
							string autoType = Array.join( types, "." );
							if( showIndex == 0 || showIndex == 2 )
							{
								IupSetStrAttributeId( rootTree, toStringz( LEAF ), bracchID, toStringz( _node.name ~ ( autoType.length ? " : " ~ autoType : "" ) ~ lineNumString ) );
							}
							else
							{
								IupSetStrAttributeId( rootTree, toStringz( LEAF ), bracchID, toStringz( _node.name ~ lineNumString ) );
							}
							break;
						}
					}
					goto case;
				
				case B_ALIAS:
					if( showIndex == 0 || showIndex == 2 )
					{
						IupSetStrAttributeId( rootTree, toStringz( LEAF ), bracchID, toStringz( _node.name ~ ( _node.type.length ? " : " ~ _node.type : "" ) ~ lineNumString ) );
					}
					else
					{
						IupSetStrAttributeId( rootTree, toStringz( LEAF ), bracchID, toStringz( _node.name ~ lineNumString ) );
					}
					break;
				
				/*
				case B_VERSION | B_PARAM:
					IupSetStrAttributeId( rootTree, toStringz( BRANCH ), bracchID, toStringz( _node.name ~ _node.protection ~ _node.type ~ lineNumString ) );
					IupSetStrAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
					break;
				*/
				case B_WITH, B_NAMESPACE, B_VERSION:
					IupSetStrAttributeId( rootTree, toStringz( BRANCH ), bracchID, toStringz( _node.name ~ lineNumString ) );
					break;
					
				case B_SCOPE:
					IupSetStrAttributeId( rootTree, toStringz( BRANCH ), bracchID, toStringz( "-SCOPE-" ~ lineNumString ) );
					break;

				case B_INCLUDE:
					IupSetStrAttributeId( rootTree, toStringz( LEAF ), bracchID, toStringz( _node.name ~ lineNumString ) );
					IupSetStrAttributeId( rootTree, "TITLEFONTSTYLE", bracchID + 1, "Underline" );
					break;
				
				case B_ENUMMEMBER:
					IupSetStrAttributeId( rootTree, toStringz( LEAF ), bracchID, toStringz( _node.name ~ lineNumString ) );
					break;
					
				case B_TYPE, B_CLASS, B_UNION, B_ENUM:
					IupSetStrAttributeId( rootTree, toStringz( BRANCH ), bracchID, toStringz( _node.name ~ ( _node.base.length ? " : " ~ _node.base : "" ) ~ lineNumString ) );
					break;

				default:
					bNoImage = true;
			}
		}
		version(DIDE)
		{
			switch( _node.kind & 8388607 )
			{
				case D_IMPORT:
					IupSetStrAttributeId( rootTree, toStringz( LEAF ), bracchID, toStringz( _node.name ~ ( _node.type.length ? " : " ~ _node.type : "" ) ~ lineNumString ) );
					IupSetStrAttributeId( rootTree, "TITLEFONTSTYLE", bracchID + 1, "Underline" );
					break;
					
				case D_FUNCTION, D_FUNCTIONLITERALS:
					string _type = _node.type;
					string _paramString;
					ParserAction.returnTypeAndParameter( _node.type, _type, _paramString );
					switch( showIndex )
					{
						case 0:
							IupSetStrAttributeId( rootTree, toStringz( BRANCH ), bracchID, toStringz( _node.name ~ _paramString ~ ( _type.length ? " : " ~ _type : "" ) ~ lineNumString ) );
							break;
						case 1:
							IupSetStrAttributeId( rootTree, toStringz( BRANCH ), bracchID, toStringz( _node.name ~ _paramString ~ lineNumString ) );
							break;
						case 2:
							IupSetStrAttributeId( rootTree, toStringz( BRANCH ), bracchID, toStringz( _node.name ~ ( _type.length ? " : " ~ _type : "" ) ~ lineNumString ) );
							break;
						default:
							IupSetStrAttributeId( rootTree, toStringz( BRANCH ), bracchID, toStringz( _node.name ~ lineNumString ) );
					}
					break;

				case D_CTOR:
					switch( showIndex )
					{
						case 0, 1:
							IupSetStrAttributeId( rootTree, toStringz( BRANCH ), bracchID, toStringz( "this" ~ _node.type ~ lineNumString ) );
							break;
						default:
							IupSetStrAttributeId( rootTree, toStringz( BRANCH ), bracchID, toStringz( "this" ~ lineNumString ) );
					}
					break;

				case D_DTOR:
					switch( showIndex )
					{
						case 0, 1:
							IupSetStrAttributeId( rootTree, toStringz( BRANCH ), bracchID, toStringz( "~this()" ~ lineNumString ) );
							break;
						default:
							IupSetStrAttributeId( rootTree, toStringz( BRANCH ), bracchID, toStringz( "~this" ~ lineNumString ) );
					}				
					break;
					
				case D_FUNCTIONPTR:
					string _type;
					string _paramString;
					ParserAction.returnTypeAndParameter( _node.type, _type, _paramString );
					switch( showIndex )
					{
						case 0:
							IupSetStrAttributeId( rootTree, toStringz( LEAF ), bracchID, toStringz( _node.name ~ _paramString ~ ( _type.length ? " : " ~ _type : "" ) ~ lineNumString ) );
							break;
						case 1:
							IupSetStrAttributeId( rootTree, toStringz( LEAF ), bracchID, toStringz( _node.name ~ _paramString ~ lineNumString ) );
							break;
						case 2:
							IupSetStrAttributeId( rootTree, toStringz( LEAF ), bracchID, toStringz( _node.name ~ ( _type.length ? " : " ~ _type : "" ) ~ lineNumString ) );
							break;
						default:
							IupSetStrAttributeId( rootTree, toStringz( LEAF ), bracchID, toStringz( _node.name ~ lineNumString ) );
					}					
					break;
					
				case D_VARIABLE:
					if( !_node.type.length )
					{
						if( _node.base.length )
						{
							string[] types = ParserAction.getDivideWordWithoutSymbol( _node.base );
							string autoType = Array.join( types, "." );
							if( showIndex == 0 || showIndex == 2 )
							{
								IupSetStrAttributeId( rootTree, toStringz( LEAF ), bracchID, toStringz( _node.name ~ ( autoType.length ? " : " ~ autoType : "" ) ~ lineNumString ) );
							}
							else
							{
								IupSetStrAttributeId( rootTree, toStringz( LEAF ), bracchID, toStringz( _node.name ~ lineNumString ) );
							}
							break;
						}
					}
					goto case;
					
				case D_ALIAS:
					if( showIndex == 0 || showIndex == 2 )
					{
						IupSetStrAttributeId( rootTree, toStringz( LEAF ), bracchID, toStringz( _node.name ~ ( _node.type.length ? " : " ~ _node.type : "" ) ~ lineNumString ) );
					}
					else
					{
						IupSetStrAttributeId( rootTree, toStringz( LEAF ), bracchID, toStringz( _node.name ~ lineNumString ) );
					}
					break;

				case D_ENUMMEMBER:
					IupSetStrAttributeId( rootTree, toStringz( LEAF ), bracchID, toStringz( _node.name ~ lineNumString ) );
					break;
					
				case D_CLASS, D_INTERFACE:
					switch( showIndex )
					{
						case 0, 2:
							IupSetStrAttributeId( rootTree, toStringz( BRANCH ), bracchID, toStringz( _node.name ~ ( _node.base.length ? " : " ~ _node.base : _node.base ) ~ lineNumString ) );
							break;
						default:
							IupSetStrAttributeId( rootTree, toStringz( BRANCH ), bracchID, toStringz( _node.name ~ lineNumString ) );
					}
					break;

				case D_TEMPLATE:
					switch( showIndex )
					{
						case 0:
							IupSetStrAttributeId( rootTree, toStringz( BRANCH ), bracchID, toStringz( _node.name ~ _node.type ~ ( _node.base.length ? " : " ~ _node.base : _node.base ) ~ lineNumString ) );
							break;
						case 1:
							IupSetStrAttributeId( rootTree, toStringz( BRANCH ), bracchID, toStringz( _node.name ~ _node.type ~ lineNumString ) );
							break;
						case 2:
							IupSetStrAttributeId( rootTree, toStringz( BRANCH ), bracchID, toStringz( _node.name ~ ( _node.base.length ? " : " ~ _node.base : _node.base ) ~ lineNumString ) );
							break;
						default:
							IupSetStrAttributeId( rootTree, toStringz( BRANCH ), bracchID, toStringz( _node.name ~ lineNumString ) );
					}
					break;
				/*
				case D_VERSION:
					if( _node.getChildrenCount > 0 )
						IupSetStrAttributeId( rootTree, toStringz( BRANCH ), bracchID, toStringz( _node.name ~ lineNumString ) );
					else
						bNoImage = true;
					break;
				*/
				case D_VERSION:
				case D_STRUCT, D_UNION, D_DEBUG, D_SCOPE:
					IupSetStrAttributeId( rootTree, toStringz( BRANCH ), bracchID, toStringz( _node.name ~ lineNumString ) );
					break;

				case D_ENUM:	
					if( !_node.name.length )
					{
						IupSetStrAttributeId( rootTree, toStringz( BRANCH ), bracchID, toStringz( "-Anonymous-" ~ lineNumString ) );
					}
					else
					{
						IupSetStrAttributeId( rootTree, toStringz( BRANCH ), bracchID, toStringz( _node.name ~ lineNumString ) );
					}
					break;	

				default:
					bNoImage = true;
			}
		}
		

		if( !bNoImage )
		{
			IupSetStrAttributeId( rootTree, "COLOR", bracchID + 1, toStringz( GLOBAL.editColor.outlineFore ) );
			lastAddNode = IupGetInt( rootTree, "LASTADDNODE" );
			setImage( rootTree, _node );
			IupSetAttributeId( rootTree, "USERDATA", lastAddNode, cast(char*) _node );
			
			foreach_reverse( CASTnode t; _node.getChildren() )
			{
				append( rootTree, t, lastAddNode );
			}				
		}
	}
	
	
	int updateNodeByLineNumber( CASTnode[] newASTNodes, int _ln )
	{
		if( GLOBAL.parserSettings.toggleUpdateOutlineLive != "ON" ) return -1;

		int insertID = -1;
		if( IupGetChildCount( GLOBAL.outlineTree.getZBoxHandle ) > 0 )
		{
			int pos = IupGetInt( GLOBAL.outlineTree.getZBoxHandle, "VALUEPOS" ); // Get active zbox pos
			Ihandle* actTree = IupGetChild( GLOBAL.outlineTree.getZBoxHandle, pos );
			if( actTree != null )
			{
				try
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
				}
				catch( Exception e )
				{
					throw e;
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
		IupSetAttributes( outlineButtonCollapse, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,CANFOCUS=NO,IMAGE=icon_collapse2,VISIBLE=NO" );
		IupSetStrAttribute( outlineButtonCollapse, "TIP", GLOBAL.languageItems["collapse"].toCString );
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
		IupSetAttributes( outlineButtonPR, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,CANFOCUS=NO,IMAGE=icon_show_pr,VISIBLE=NO,NAME=button_OutlinePR" );
		IupSetStrAttribute( outlineButtonPR, "TIP", GLOBAL.languageItems["showpr"].toCString );
		IupSetCallback( outlineButtonPR, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			if( GLOBAL.outlineTree.showIndex == 3 ) GLOBAL.outlineTree.showIndex = 0; else GLOBAL.outlineTree.showIndex ++;

			Ihandle* _ih = IupGetDialogChild( GLOBAL.mainDlg, "button_OutlinePR" );
			if( _ih != null )
			{
				if( GLOBAL.editorSetting00.IconInvert == "ON" )
				{
					switch( GLOBAL.outlineTree.showIndex )
					{
						case 0:		IupSetAttribute( _ih, "IMAGE", "icon_show_pr_invert" ); break;
						case 1:		IupSetAttribute( _ih, "IMAGE", "icon_show_p_invert" ); break;
						case 2:		IupSetAttribute( _ih, "IMAGE", "icon_show_r_invert" ); break;
						default:	IupSetAttribute( _ih, "IMAGE", "icon_show_nopr_invert" ); break;
					}
				}
				else
				{
					switch( GLOBAL.outlineTree.showIndex )
					{
						case 0:		IupSetAttribute( _ih, "IMAGE", "icon_show_pr" ); break;
						case 1:		IupSetAttribute( _ih, "IMAGE", "icon_show_p" ); break;
						case 2:		IupSetAttribute( _ih, "IMAGE", "icon_show_r" ); break;
						default:	IupSetAttribute( _ih, "IMAGE", "icon_show_nopr" ); break;
					}
				}
			}
			
			for( int i = 0; i < IupGetChildCount( GLOBAL.outlineTree.getZBoxHandle ); ++ i )
				GLOBAL.outlineTree.changePR( IupGetChild( GLOBAL.outlineTree.getZBoxHandle, i ) );
			return IUP_DEFAULT;
		});
		

		outlineToggleAnyWord = IupToggle( null, null );
		IupSetAttributes( outlineToggleAnyWord, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,CANFOCUS=NO,IMAGE=icon_notwholeword,IMPRESS=icon_wholeword,VALUE=OFF,VISIBLE=NO,NAME=button_OutlineWholeWord" );
		IupSetStrAttribute( outlineToggleAnyWord, "TIP", GLOBAL.languageItems["searchanyword"].toCString );
		

		outlineButtonShowLinenum = IupToggle( null, null );
		IupSetAttributes( outlineButtonShowLinenum, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,CANFOCUS=NO,IMAGE=icon_show_linenum,VALUE=OFF,VISIBLE=NO,NAME=button_OutlineShowLinenum" );
		IupSetStrAttribute( outlineButtonShowLinenum, "TIP", GLOBAL.languageItems["showln"].toCString );
		IupSetCallback( outlineButtonShowLinenum, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			// Change All Documents
			for( int i = 0; i < IupGetChildCount( GLOBAL.outlineTree.getZBoxHandle ); ++ i )
				GLOBAL.outlineTree.changePR( IupGetChild( GLOBAL.outlineTree.getZBoxHandle, i ) );
			return IUP_DEFAULT;
		});		


		outlineButtonFresh = IupButton( null, null );
		IupSetAttributes( outlineButtonFresh, "ALIGNMENT=ACENTER:ACENTER,FLAT=YES,CANFOCUS=NO,IMAGE=icon_refresh,VISIBLE=NO,NAME=button_OutlineRefresh" );
		IupSetStrAttribute( outlineButtonFresh, "TIP", GLOBAL.languageItems["sc_reparse"].toCString );
		IupSetCallback( outlineButtonFresh, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			CScintilla cSci = actionManager.ScintillaAction.getActiveCScintilla();
			GLOBAL.outlineTree.refresh( cSci );
			return IUP_DEFAULT;
		});

		outlineButtonHide = IupButton( null, null );
		IupSetAttributes( outlineButtonHide, "ALIGNMENT=ALEFT,FLAT=YES,CANFOCUS=NO,IMAGE=icon_shift_l" );
		IupSetStrAttribute( outlineButtonHide, "TIP", GLOBAL.languageItems["hide"].toCString );
		IupSetCallback( outlineButtonHide, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			menu.outlineMenuItem_cb( GLOBAL.menuOutlineWindow );
			return IUP_DEFAULT;
		});

		outlineToolbarTitleImage = IupButton( null, null );
		IupSetAttributes( outlineToolbarTitleImage, "ALIGNMENT=ALEFT,FLAT=YES,CANFOCUS=NO,IMAGE=icon_outline" );
		IupSetStrAttribute( outlineToolbarTitleImage, "TIP", GLOBAL.languageItems["hidesearch"].toCString );
		IupSetCallback( outlineToolbarTitleImage, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			Ihandle* _expandHandle = IupGetDialogChild( GLOBAL.outlineTree.getLayoutHandle, "Outline_Expander" );
			if( _expandHandle != null )
			{
				if( fromStringz( IupGetAttribute( _expandHandle, "STATE" ) ) == "OPEN" )
				{
					IupSetAttribute( _expandHandle, "STATE", "CLOSE" );
					Ihandle* _listHandle = IupGetChild( _expandHandle, 1 ); // Get outlineTreeNodeList Ihandle
					if( _listHandle != null ) IupSetAttributes( _listHandle, "VISIBLE=NO,ACTIVE=NO" ); // Make outlineTreeNodeList to hide
				}
				else
				{
					IupSetAttribute( _expandHandle, "STATE", "OPEN" );
					Ihandle* _listHandle = IupGetChild( _expandHandle, 1 );
					if( _listHandle != null )
					{
						IupSetAttributes( _listHandle, "VISIBLE=YES,ACTIVE=YES" ); // Make outlineTreeNodeList to show
						IupSetFocus( _listHandle );
					}
				}
			}
			return IUP_DEFAULT;
		});
		
		

		Ihandle* outlineToolbarH = IupHbox( outlineToolbarTitleImage, IupFill, outlineButtonCollapse, outlineButtonPR, outlineButtonShowLinenum, outlineToggleAnyWord, outlineButtonFresh, outlineButtonHide, null );
		IupSetAttributes( outlineToolbarH, "ALIGNMENT=ACENTER,SIZE=NULL" );

		outlineTreeNodeList = IupList( null );
		IupSetAttributes( outlineTreeNodeList, "ACTIVE=NO,VISIBLE=NO,DROPDOWN=YES,SHOWIMAGE=YES,EDITBOX=YES,EXPAND=YES,VISIBLEITEMS=8,NAME=list_Outline" );
		IupSetCallback( outlineTreeNodeList, "DROPDOWN_CB",cast(Icallback) &COutline_List_DROPDOWN_CB );
		IupSetCallback( outlineTreeNodeList, "ACTION",cast(Icallback) &COutline_List_ACTION );
		IupSetCallback( outlineTreeNodeList, "K_ANY",cast(Icallback) &COutline_List_K_ANY );
		version(Windows)
			IupSetCallback( outlineTreeNodeList, "EDIT_CB",cast(Icallback) &COutline_List_EDIT_CB );
		else
		{
			IupSetCallback( outlineTreeNodeList, "GETFOCUS_CB",cast(Icallback) function( Ihandle* ih )
			{
				IupSetAttribute( ih, "REMOVEITEM", "ALL" );
				for( int i = 0; i < 10; ++i )
					IupSetStrAttributeId( ih, "", i + 1, "" ); // Add Dummy for linux, fixed the popup dialog size = 10 items
				
				return IUP_DEFAULT;
			});	
		}
		
		Ihandle* expander = IupExpander( outlineTreeNodeList );
		IupSetAttributes( expander, "BARSIZE=0,STATE=CLOSE,EXPAND=HORIZONTAL,NAME=Outline_Expander" );
		IupSetStrAttribute( expander, "BACKCOLOR", toStringz( GLOBAL.editColor.dlgBack ) );		

		Ihandle* _backgroundbox = IupGetChild( expander, 0 );
		if( _backgroundbox != null ) IupSetAttribute( _backgroundbox, "VISIBLE", "NO" ); // Hide Title Image
		
		outlineToolBarBox = IupBackgroundBox( outlineToolbarH );
		IupSetStrAttribute( outlineToolBarBox, "BGCOLOR", toStringz( GLOBAL.editColor.outlineBack ) );		
		
		layoutHandle = IupVbox( outlineToolBarBox, expander, zBoxHandle, null );
		IupSetAttributes( layoutHandle, "ALIGNMENT=ARIGHT,EXPANDCHILDREN=YES,GAP=2" );
		layoutHandle = IupBackgroundBox( layoutHandle );

		changeIcons();
	}
	
public:
	this()
	{
		zBoxHandle = IupZbox( null );
		IupSetAttributes( zBoxHandle, "NAME=zbox_Outline" );
		createLayout();
	}

	~this(){}

	void changeIcons()
	{
		string tail;
		if( GLOBAL.editorSetting00.IconInvert != "OFF" ) tail = "_invert";

		IupSetStrAttribute( outlineToolbarTitleImage, "IMAGE", toStringz( tail.length ? "icon_outline" : "icon_outline" ~ tail ) );
		IupSetStrAttribute( outlineButtonCollapse, "IMAGE", toStringz( tail.length ? "icon_collapse2" : "icon_collapse2" ~ tail ) );
		switch( showIndex )
		{
			case 0:		IupSetStrAttribute( outlineButtonPR, "IMAGE", toStringz( tail.length ? "icon_show_pr" : "icon_show_pr" ~ tail ) ); break;
			case 1:		IupSetStrAttribute( outlineButtonPR, "IMAGE", toStringz( tail.length ? "icon_show_p" : "icon_show_p" ~ tail ) ); break;
			case 2:		IupSetStrAttribute( outlineButtonPR, "IMAGE", toStringz( tail.length ? "icon_show_r" : "icon_show_r" ~ tail ) ); break;
			default:	IupSetStrAttribute( outlineButtonPR, "IMAGE", toStringz( tail.length ? "icon_show_nopr" : "icon_show_nopr" ~ tail ) ); break;
		}
		IupSetStrAttribute( outlineToggleAnyWord, "IMPRESS", toStringz( "icon_wholeword" ~ tail )); 
		IupSetStrAttribute( outlineToggleAnyWord, "IMAGE", toStringz( tail.length ? "icon_notwholeword" : "icon_notwholeword" ~ tail ));
		IupSetStrAttribute( outlineButtonShowLinenum, "IMPRESS", toStringz( "icon_show_linenum" ~ tail ) );
		IupSetStrAttribute( outlineButtonShowLinenum, "IMAGE", toStringz( tail.length ? "icon_show_linenum" : "icon_show_linenum" ~ tail ) );
		IupSetStrAttribute( outlineButtonFresh, "IMAGE", toStringz( tail.length ? "icon_refresh" : "icon_refresh" ~ tail ) );
		IupSetStrAttribute( outlineButtonHide, "IMAGE", toStringz( tail.length ? "icon_shift_l" : "icon_shift_l" ~ tail ) );
	}

	void changeColor()
	{
		IupSetStrAttribute( outlineToolBarBox, "BGCOLOR", toStringz( GLOBAL.editColor.outlineBack ) );
		IupSetStrAttribute( GLOBAL.projectViewTabs, "FGCOLOR", toStringz( GLOBAL.editColor.outlineFore ) );
		IupSetStrAttribute( GLOBAL.projectViewTabs, "BGCOLOR", toStringz( GLOBAL.editColor.outlineBack ) );	
		IupSetStrAttribute( GLOBAL.projectViewTabs, "TABSLINECOLOR", toStringz( GLOBAL.editColor.linenumBack ) );	
		
		for( int i = 0; i < IupGetChildCount( zBoxHandle ); ++i )
		{
			Ihandle* ih = IupGetChild( zBoxHandle, i ); // tree
			if( ih != null )
			{
				IupSetAttribute( ih, "FGCOLOR", toStringz( GLOBAL.editColor.outlineFore ) );
				IupSetAttribute( ih, "BGCOLOR", toStringz( GLOBAL.editColor.outlineBack ) );					
				if( GLOBAL.editColor.prjViewHLT.length ) IupSetStrAttribute( ih, "HLCOLOR", toStringz( GLOBAL.editColor.prjViewHLT ) );
				try
				{
					for( int j = 0; j < IupGetInt( ih, "COUNT" ); ++ j )
					{
						if( j == 0 )
						{
							IupSetStrAttributeId( ih, "COLOR", 0, toStringz( GLOBAL.editColor.prjTitle ) );
							IupSetStrAttributeId( ih, "TITLEFONT", 0, toStringz( GLOBAL.fonts[5].fontString ) );// Outline	
							IupSetAttributeId( ih, "TITLEFONTSTYLE", 0, "Bold" );// Outline	
						}
						else
						{
							auto _node = cast(CASTnode) IupGetAttributeId( ih, "USERDATA", j );
							if( _node !is null )
							{
								switch( Uni.toLower( _node.protection ) )
								{
									case "private":		IupSetStrAttributeId( ih, "COLOR", j, toStringz( GLOBAL.editColor.privateColor ) ); break;
									case "protected":	IupSetStrAttributeId( ih, "COLOR", j, toStringz( GLOBAL.editColor.protectedColor ) ); break;
									default:			IupSetStrAttributeId( ih, "COLOR", j, toStringz( GLOBAL.editColor.outlineFore ) );
								}
								
								version(FBIDE)
								{
									if( _node.kind & B_INCLUDE )
									{
										IupSetStrAttributeId( ih, "TITLEFONT", j, toStringz( GLOBAL.fonts[5].fontString ) );// Outline	
										IupSetAttributeId( ih, "TITLEFONTSTYLE", j, "Underline" );// Outline	
									}
									else if( _node.kind & B_VERSION )
									{
										if( _node.type == "!" ) IupSetAttributeId( ih, "COLOR", j, "255 0 0" ); else IupSetAttributeId( ih, "COLOR", j, "0 160 0" );
									}									
								}
								version(DIDE)
								{
									if( _node.kind & D_IMPORT )
									{
										IupSetStrAttributeId( ih, "TITLEFONT", j, toStringz( GLOBAL.fonts[5].fontString ) );// Outline	
										IupSetAttributeId( ih, "TITLEFONTSTYLE", j, "Underline" );// Outline	
									}
								}
							}
						}
					}
				}
				catch( Exception e )
				{
					IupMessage( "changeColor() Error", toStringz( e.toString ) );
				}
			}
		}
		version(Windows) tools.setDarkMode4Dialog( GLOBAL.outlineTree.getLayoutHandle, GLOBAL.editorSetting00.UseDarkMode == "ON" ? true : false );
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
	
	Ihandle* createTree( CASTnode head )
	{
		if( head !is null )
		{
			Ihandle* tree;
			
			version(FBIDE) if( head.kind != B_BAS && head.kind != B_BI ) return null;
			version(DIDE) if( head.kind != D_MODULE ) return null;
			
			string fullPath = head.name;
			tree = IupTree();
			IupSetAttributes( tree, "ADDROOT=YES,EXPAND=YES,BORDER=NO" );
			IupSetStrAttribute( tree, "TITLE", toStringz( fullPath ) );
			IupSetCallback( tree, "BUTTON_CB", cast(Icallback) &COutline_BUTTON_CB );
			if( GLOBAL.editColor.prjViewHLT.length ) IupSetStrAttribute( tree, "HLCOLOR", toStringz( GLOBAL.editColor.prjViewHLT ) );
			IupSetStrAttributeId( tree, "COLOR", 0, toStringz( GLOBAL.editColor.prjTitle ) );
			IupSetAttributeId( tree, "TITLEFONTSTYLE", 0, "Bold" ); // Bold
			//toBoldTitle( tree, 0 );
			version(Windows)
			{
				IupSetCallback( tree, "SELECTION_CB", cast(Icallback) function( Ihandle *ih, int id, int status )
				{
					if( status == 1 )
					{
						/*if( GLOBAL.bCanUseDarkMode )*/ IupSetStrAttributeId( ih, "COLOR", id, toStringz( tools.invertColor( GLOBAL.editColor.prjViewHLT ) ) );
					}
					else
					{
						restoreSingleNodeColor( ih, id );
					}
				
					return IUP_DEFAULT;
				});
			}
			
			version(FBIDE)
			{
				string tail = GLOBAL.editorSetting00.IconInvert == "ON" ? "_invert" : "";
				IupSetStrAttribute( tree, "IMAGE0", toStringz( "icon_folder" ~ tail ) );
				IupSetStrAttribute( tree, "IMAGEEXPANDED0", toStringz( "icon_folder_open" ~ tail ) );
			}
			else //version(DIDE)
			{
				IupSetAttributeId( tree, "IMAGE", 0, "IUP_module" );
				IupSetAttributeId( tree, "IMAGEEXPANDED", 0, "IUP_module" );
				IupSetAttributeId( tree, "USERDATA", 0, cast(char*) head );
			}

			IupAppend( zBoxHandle, tree );
			IupMap( tree );
			IupRefresh( GLOBAL.outlineTree.getZBoxHandle );	
			foreach_reverse( CASTnode t; head.getChildren() )
				append( tree, t, 0 );
			
			IupSetStrAttribute( zBoxHandle, "FONT", toStringz( GLOBAL.fonts[5].fontString ) );// Outline
			IupSetAttribute( tree, "FGCOLOR", toStringz( GLOBAL.editColor.outlineFore ) );
			IupSetAttribute( tree, "BGCOLOR", toStringz( GLOBAL.editColor.outlineBack ) );			
			
			if( IupGetChildCount( zBoxHandle ) > 0 ) showTreeAndButtons( true );
			version(Windows) tools.setWinTheme( tree, "Explorer", GLOBAL.editorSetting00.UseDarkMode == "ON" ? true : false );
			version(Windows) IupSetStrAttributeId( tree, "COLOR", 0, toStringz( tools.invertColor( GLOBAL.editColor.prjViewHLT ) ) ); // Selected on first Node, color it
			
			return tree;
		}
		
		return null;
	}
	
	
	void showTreeAndButtons( bool bShow )
	{
		if( !bShow )
		{
			IupSetAttribute( zBoxHandle, "VISIBLE", "NO" );
			IupSetAttribute( outlineTreeNodeList, "VISIBLE", "NO" );
			IupSetAttribute( outlineButtonCollapse, "VISIBLE", "NO" );
			IupSetAttribute( outlineButtonPR, "VISIBLE", "NO" );
			IupSetAttribute( outlineToggleAnyWord, "VISIBLE", "NO" );
			IupSetAttribute( outlineButtonShowLinenum, "VISIBLE", "NO" );
			IupSetAttribute( outlineButtonFresh, "VISIBLE", "NO" );
		}
		else
		{
			IupSetAttribute( zBoxHandle, "VISIBLE", "YES" );
			if( IupGetInt( outlineTreeNodeList, "ACTIVE" ) ) IupSetAttribute( outlineTreeNodeList, "VISIBLE", "YES" );
			IupSetAttribute( outlineButtonCollapse, "VISIBLE", "YES" );
			IupSetAttribute( outlineButtonPR, "VISIBLE", "YES" );
			IupSetAttribute( outlineToggleAnyWord, "VISIBLE", "YES" );
			IupSetAttribute( outlineButtonShowLinenum, "VISIBLE", "YES" );
			IupSetAttribute( outlineButtonFresh, "VISIBLE", "YES" );
		}
		
		// Prevent x64 stranger color error...
		IupSetStrAttribute( getLayoutHandle, "BGCOLOR", toStringz( GLOBAL.editColor.outlineBack ) );
		IupSetStrAttribute( GLOBAL.projectTree.getLayoutHandle, "BGCOLOR", toStringz( GLOBAL.editColor.projectBack ) );
		if( GLOBAL.debugPanel !is null ) GLOBAL.debugPanel.adjustColor();
	}
	
	
	void changeTree( string fullPath )
	{
		try
		{
			for( int i = 0; i < IupGetChildCount( zBoxHandle ); ++i )
			{
				Ihandle* ih = IupGetChild( zBoxHandle, i );
				if( ih != null )
				{
					string _fullPath = fSTRz( IupGetAttributeId( ih, "TITLE", 0 ) );
					version(DIDE)
					{
						auto _node = cast(CASTnode) IupGetAttributeId( ih, "USERDATA", 0 );
						if( _node !is null ) _fullPath = _node.type; else _fullPath = "";
					}

					if( fullPathByOS( fullPath ) == fullPathByOS( _fullPath ) )
					{
						IupSetInt( zBoxHandle, "VALUEPOS", i );
						showTreeAndButtons( true );
						return;
					}
				}
			}
		}
		catch( Exception e )
		{
			IupMessage( "ChangeTree() Error", toStringz( e.toString ) );
		}
		
		// Not in zBox( no tree created ), hide the zBox
		showTreeAndButtons( false );
	}

	void cleanTree( string fullPath, bool bDestroy = true )
	{
		try
		{
			for( int i = 0; i < IupGetChildCount( GLOBAL.outlineTree.getZBoxHandle ); ++i )
			{
				Ihandle* ih = IupGetChild( GLOBAL.outlineTree.getZBoxHandle, i ); 
				if( ih != null )
				{
					string _fullPath = fSTRz( IupGetAttributeId( ih, "TITLE", 0 ) );
					version(DIDE)
					{
						auto _node = cast(CASTnode) IupGetAttributeId( ih, "USERDATA", 0 );
						if( _node !is null ) _fullPath = _node.type; else _fullPath = "";
					}

					if( fullPathByOS( fullPath ) == fullPathByOS( _fullPath ) )
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
									if( pParser !is null ) destroy( pParser );
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
				IupSetAttribute( outlineTreeNodeList, "VALUE", "" );
				showTreeAndButtons( false );
			}
		}
		catch( Exception e )
		{
			IupMessage( "cleanTree() Error", toStringz( e.toString ) );
		}
	}

	Ihandle* getTree( string fullPath )
	{
		for( int i = 0; i < IupGetChildCount( GLOBAL.outlineTree.getZBoxHandle ); ++i )
		{
			Ihandle* ih = IupGetChild( GLOBAL.outlineTree.getZBoxHandle, i ); 
			if( ih != null )
			{
				string _fullPath = fSTRz( IupGetAttributeId( ih, "TITLE", 0 ) );
				version(DIDE)
				{
					try
					{
						auto _node = cast(CASTnode) IupGetAttributeId( ih, "USERDATA", 0 );
						if( _node !is null ) _fullPath = _node.type; else _fullPath = "";
					}
					catch( Exception e )
					{
						IupMessage( "getTree() Error", toStringz( e.toString ) );
					}
				}				

				if( fullPathByOS( fullPath ) == fullPathByOS( _fullPath ) ) return ih;
			}
		}

		return null;
	}
	

	Ihandle* getZBoxHandle(){ return zBoxHandle; }


	CASTnode createParserByText( string fullPath, string document )
	{
		if( GLOBAL.parserSettings.enableParser != "ON" ) return null;
		
		string _ext = Path.extension( Uni.toLower( fullPath ) );
		version(FBIDE)	if( !tools.isParsableExt( _ext, 7 ) )	return null;
		version(DIDE)	if( _ext != ".d" && _ext != ".di" )	return null;
		
		GLOBAL.Parser.updateTokens( GLOBAL.scanner.scan( document ) );
		auto _ast = GLOBAL.Parser.parse( fullPath );
		GLOBAL.parserManager[fullPathByOS(fullPath)] = cast(shared CASTnode) _ast;

		Ihandle* _tree = getTree( fullPath );
		if( _tree != null )	cleanTree( fullPath );
		createTree( _ast );
		
		return _ast;
	}


	CASTnode loadFile( string fullPath )
	{
		if( GLOBAL.parserSettings.enableParser != "ON" ) return null;

		string _ext = Path.extension( Uni.toLower( fullPath ) );
		version(FBIDE)	if( !tools.isParsableExt( _ext, 7 ) )	return null;
		version(DIDE)	if( _ext != ".d" && _ext != ".di" )	return null;
		
		if( fullPathByOS(fullPath) in GLOBAL.scintillaManager )
		{
			if( fullPathByOS(fullPath) in GLOBAL.parserManager )
			{
				Ihandle* _tree = getTree( fullPath );
				if( _tree == null ) createTree( cast(CASTnode) GLOBAL.parserManager[fullPathByOS(fullPath)] );
			}
			else
			{
				string document = GLOBAL.scintillaManager[fullPathByOS(fullPath)].getText();
				GLOBAL.Parser.updateTokens( GLOBAL.scanner.scan( document ) );
				GLOBAL.parserManager[fullPathByOS(fullPath)] = cast(shared CASTnode)GLOBAL.Parser.parse( fullPath );
				Ihandle* _tree = getTree( fullPath );
				if( _tree != null )	cleanTree( fullPath );
				createTree( cast(CASTnode) GLOBAL.parserManager[fullPathByOS(fullPath)] );
			}
			changeTree( fullPath );
		}
		else
		{
			return null;
		}

		return cast(CASTnode) GLOBAL.parserManager[fullPathByOS(fullPath)];
	}
	
	CASTnode loadParser( string fullPath )
	{
		if( GLOBAL.parserSettings.enableParser != "ON" ) return null;
		
		string _ext = Path.extension( Uni.toLower( fullPath ) );
		version(FBIDE)	if( !tools.isParsableExt( _ext, 7 ) )	return null;
		version(DIDE)	if( _ext != ".d" && _ext != ".di" )	return null;		

		if( fullPathByOS(fullPath) in GLOBAL.parserManager )
		{
			return cast(CASTnode) GLOBAL.parserManager[fullPathByOS(fullPath)];
		}
		else
		{
			// Don't Create Tree
			// Parser
			if( std.file.exists( fullPath ) )
			{
				if( GLOBAL.Parser.updateTokens( GLOBAL.scanner.scanFile( fullPath ) ) )
				{
					auto _ast = GLOBAL.Parser.parse( fullPath );
					GLOBAL.parserManager[fullPathByOS(fullPath)] = cast(shared CASTnode) _ast;
					return _ast;
				}
			}
		}

		return null;
	}

	string getImageName( CASTnode _node )
	{
		string prot;
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

				case B_FUNCTION:
					if( _node.base == "pointer" ) return ( "IUP_funptr" ~ prot );
					return ( "IUP_function" ~ prot );
					
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
		try
		{
			Ihandle* actTree = getActiveTree();
			if( actTree != null )
			{
				version(Windows)
				{
					int activeID = IupGetInt( actTree, "VALUE" );
					if( activeID > -1 ) restoreSingleNodeColor( actTree, activeID );
				}
				
				foreach_reverse( CASTnode _node; newASTNodes )
					if( insertID <= 0 ) append( actTree, _node, -insertID ); else append( actTree, _node, insertID, true );

				int markID = IupGetInt( actTree, "LASTADDNODE" ) + cast(int) newASTNodes.length - 1;
				IupSetAttributeId( actTree, "MARKED", markID, "YES" );
				version(Windows)
				{
					IupSetInt( actTree, "VALUE", markID );
					IupSetStrAttributeId( actTree, "COLOR", markID, toStringz( tools.invertColor( GLOBAL.editColor.prjViewHLT ) ) );
				}
			}
		}
		catch( Exception e ){}		
	}

	void insertBlockNodeByLineNumber( CASTnode newASTNode, int insertID )
	{
		try
		{
			Ihandle* actTree = getActiveTree();
			if( actTree != null )
			{
				if( insertID <= 0 ) append( actTree, newASTNode, insertID ); else append( actTree, newASTNode, insertID, true );
				int markID = IupGetInt( actTree, "LASTADDNODE" );
				IupSetAttributeId( actTree, "MARKED", markID, "YES" );
				version(Windows) IupSetInt( actTree, "VALUE", markID );
			}
		}
		catch( Exception e ){}
	}
	
	bool refresh( CScintilla cSci, bool bUpdateTree = true )
	{
		if( GLOBAL.parserSettings.enableParser != "ON" ) return false;
		if( cSci is null ) return false;

		string _ext = Uni.toLower( Path.extension( cSci.getFullPath ) );

		version(FBIDE)	if( !tools.isParsableExt( _ext, 7 ) ) return false;
		version(DIDE)	if( _ext != ".d" && _ext != ".di" )	return false;
		
		if( cSci !is null )
		{
			if( fullPathByOS( cSci.getFullPath ) in GLOBAL.parserManager )
			{
				Ihandle* actTree = getTree( cSci.getFullPath );
				if( actTree != null )
				{
					try
					{
						string document = cSci.getText();
						CASTnode astHeadNode;
						GLOBAL.Parser.updateTokens( GLOBAL.scanner.scan( document ) );
						astHeadNode = GLOBAL.Parser.parse( cSci.getFullPath );
						
						CASTnode temp = cast(CASTnode) GLOBAL.parserManager[fullPathByOS(cSci.getFullPath)];
						GLOBAL.parserManager[fullPathByOS(cSci.getFullPath)] = cast(shared CASTnode) astHeadNode;
						destroy( temp );
						
						if( bUpdateTree )
						{
							Ihandle* newTree = createTree( astHeadNode );
							IupSetAttribute( zBoxHandle, "VALUE_HANDLE", cast(char*) newTree );
							IupDestroy( actTree );						
						}

						// Reparse Lexer
						AutoComplete.resetPrevContainer();
						version(FBIDE) IupScintillaSendMessage( cSci.getIupScintilla, 4003, 0, -1 ); // SCI_COLOURISE 4003
						return true;
					}
					catch( Exception e ){}
				}
			}
		}
		return true;
	}

	CASTnode parserText( string text )
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
			IupMessage( "ERROR", toStringz( "parserText() Error:\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ to!(string)( e.line ) ) );
		}

		return null;
	}
	
	version(FBIDE)
	{
		CASTnode parserTextUnderTypeBody( string text )
		{
			try
			{
				if( GLOBAL.Parser.updateTokens( GLOBAL.scanner.scan( text ) ) ) return GLOBAL.Parser.parseTypeBodySingleLine( "_.bas" );
			}
			catch( Exception e )
			{
				IupMessage( "ERROR", toStringz( "parserTextUnderTypeBody() Error:\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ to!(string)( e.line ) ) );
			}

			return null;
		}
	}

	void cleanListItems()
	{
		IupSetAttribute( outlineTreeNodeList, "REMOVEITEM", "ALL" );
		listItemASTs.length = 0;
		listItemTreeID.length = 0;
		listItemIndex = 0;
	}
	
	int getShowIndex(){ return showIndex; }
}

private void restoreSingleNodeColor( Ihandle* ih, int id, CASTnode _node = null )
{
	if( GLOBAL.editorSetting00.ColorOutline != "ON" ) return;
	
	if( id < 0 ) return;
	if( id == 0 )
	{
		IupSetStrAttributeId( ih, "COLOR", 0, toStringz( GLOBAL.editColor.prjTitle ) );
		return;
	}
	
	if( _node is null )
	{
		_node = cast(CASTnode) IupGetAttributeId( ih, "USERDATA", id );
		IupSetStrAttributeId( ih, "COLOR", id, toStringz( GLOBAL.editColor.outlineFore ) );
	}
	
	version(FBIDE)
	{
		switch( Uni.toLower( _node.protection ) )
		{
			case "private":		IupSetStrAttributeId( ih, "COLOR", id, toStringz( GLOBAL.editColor.privateColor ) ); break;
			case "protected":	IupSetStrAttributeId( ih, "COLOR", id, toStringz( GLOBAL.editColor.protectedColor ) ); break;
			default:
		}
		
		if( _node.kind & B_VERSION )
		{
			if( _node.name == "-else-" ) IupSetAttributeId( ih, "COLOR", id, "255 0 0" ); else IupSetAttributeId( ih, "COLOR", id, "0 180 0" );
		}
	}
	version(DIDE)
	{
		if( _node.kind & D_IMPORT )
		{
			if( _node.protection == "protected" )
				IupSetStrAttributeId( ih, "COLOR", id, toStringz( GLOBAL.editColor.protectedColor ) );
			else if( _node.protection == "" || _node.protection == "private" )
				IupSetStrAttributeId( ih, "COLOR", id, toStringz( GLOBAL.editColor.privateColor ) );
		}
		else
		{
			switch( _node.protection )
			{
				case "private":		IupSetStrAttributeId( ih, "COLOR", id, toStringz( GLOBAL.editColor.privateColor ) ); break;
				case "protected":	IupSetStrAttributeId( ih, "COLOR", id, toStringz( GLOBAL.editColor.protectedColor ) ); break;
				default:			IupSetStrAttributeId( ih, "COLOR", id, toStringz( GLOBAL.editColor.outlineFore ) );
			}
		}
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
							string _fullPath = fSTRz( IupGetAttributeId( ih, "TITLE", 0 ) ); // Get Tree-Head Title
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
			IupMessage( "ERROR", toStringz( "COutline_BUTTON_CB() Error:\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ to!(string)( e.line ) ) );
			//GLOBAL.IDEMessageDlg.print( "COutline_BUTTON_CB() Error:\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ to!(string)( e.line ) );
		}

		return IUP_DEFAULT;
	}

	private int COutline_List_DROPDOWN_CB( Ihandle *ih, int state )
	{
		// ListBox open
		if( state == 1 )
		{
			setTreeNodeToList( strip( fSTRz( IupGetAttribute( ih, "VALUE" ) ) ) );
			version(Windows) IupSetFocus( ih );
		}
		else	// ListBox close
		{
			/*
			Check module layout -- GlobalKeyPress_CB
			KeyDown = 13
			Trigger Order: keydown -> DROPDOWN_CB -> keyup
			*/
			version(Windows)
			{
				if( GLOBAL.KeyNumber == 13 ) 
				{
					if( IupGetInt( ih, "COUNT" ) > 0 )
					{
						if( GLOBAL.outlineTree.listItemIndex > 0 )
						{
							if( GLOBAL.outlineTree.listItemIndex <= GLOBAL.outlineTree.listItemASTs.length )
							{
								string text = strip( fSTRz( IupGetAttribute( ih, "VALUE" ) ) );
								if( text.length )
								{
									ScintillaAction.openFile( ScintillaAction.getActiveCScintilla.getFullPath, GLOBAL.outlineTree.listItemASTs[GLOBAL.outlineTree.listItemIndex-1].lineNumber );
									Ihandle* tree = GLOBAL.outlineTree.getActiveTree();
									if( tree != null )
									{
										IupSetAttributeId( tree, "MARKED", GLOBAL.outlineTree.listItemTreeID[GLOBAL.outlineTree.listItemIndex-1], "YES" );
										IupSetInt( tree, "VALUE", GLOBAL.outlineTree.listItemTreeID[GLOBAL.outlineTree.listItemIndex-1] );
									}
									IupSetFocus( ih );
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
				/*
				else
				{
					IupMessage( "",toStringz( to!(string)( GLOBAL.KeyNumber ) ) );
				}
				*/
			}
			else
			{
				/*
				When click button
				(1)Just trigger COutline_List_DROPDOWN_CB OPEN
				Re-click button
				(2)Trigger COutline_List_DROPDOWN_CB CLOSE
				Use IupSetFocus to set focus
				(3)Trigger GETFOCUS_CB
				
				COutline_List_DROPDOWN_CB OPEN
				COutline_List_DROPDOWN_CB CLOSE
				GETFOCUS_CB
				
				Select an item
				(4)The COutline_List_ACTION before GETFOCUS_CB
				
				COutline_List_DROPDOWN_CB OPEN
				COutline_List_DROPDOWN_CB CLOSE
				COutline_List_ACTION
				GETFOCUS_CB
				*/
				IupSetFocus( ih );
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
							Ihandle* tree = GLOBAL.outlineTree.getActiveTree();
							if( tree != null )
							{
								if( GLOBAL.outlineTree.listItemTreeID.length > item )
								{
									version(Windows) IupSetAttributeId( tree, "MARKED", GLOBAL.outlineTree.listItemTreeID[item], "YES" );
									IupSetInt( tree, "VALUE", GLOBAL.outlineTree.listItemTreeID[item] );
								}
							}
							IupSetFocus( ih ); // Set Focus To List
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
						if( tree != null )
						{
							if( GLOBAL.outlineTree.listItemTreeID.length > item - 1 )
							{
								IupSetAttributeId( tree, "MARKED", GLOBAL.outlineTree.listItemTreeID[--item], "YES" );
								IupSetInt( tree, "VALUE", GLOBAL.outlineTree.listItemTreeID[item] );
							}
						}
					}
				}
			}
		}
		
		return IUP_DEFAULT;
	}	

	version(Posix)
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
				if( GLOBAL.KeyNumber == 65307 ) // ESC
				{
					GLOBAL.outlineTree.cleanListItems();
					//IupSetAttribute( ih, "VALUE", "" );
				}
			}
			return IUP_DEFAULT;
		}
		
		private int COutline_List_EDIT_CB( Ihandle *ih, int c, char *new_value )
		{
			// Avoid mouuse cursor disappear
			int screenX, screenY, sizeW, sizeH;
			string screenXY = fSTRz( IupGetAttribute( ih, "SCREENPOSITION" ) );
			if( tools.splitBySign( screenXY, ",", screenX, screenY ) )
			{
				string WH = fSTRz( IupGetAttribute( ih, "RASTERSIZE" ) );
				if( tools.splitBySign( WH, "x", sizeW, sizeH ) )
				{
					screenY = screenY + sizeH;
					screenXY = to!(string)( screenX + 8 ) ~ "x" ~ to!(string)( screenY + 8 );
					IupSetStrGlobal( "CURSORPOS", toStringz( screenXY ) );
				}
			}
		
			return IUP_DEFAULT;
		}
	}
	
	private bool setTreeNodeToList( string editText )
	{
		if( IupGetChildCount( GLOBAL.outlineTree.getZBoxHandle ) > 0 )
		{
			int pos = IupGetInt( GLOBAL.outlineTree.getZBoxHandle, "VALUEPOS" ); // Get active zbox pos
			Ihandle* actTree = IupGetChild( GLOBAL.outlineTree.getZBoxHandle, pos );

			string imageName;
			GLOBAL.outlineTree.cleanListItems();
			
			bool bAnyWord, bGo;
			Ihandle* _wholeWordHandle = IupGetDialogChild( GLOBAL.mainDlg, "button_OutlineWholeWord" );
			if( _wholeWordHandle != null ) 
			{
				if( fromStringz( IupGetAttribute( _wholeWordHandle, "VALUE" ) ) == "OFF" ) bAnyWord = true; else bAnyWord = false;
			}
			
			try
			{
				Ihandle* _listHandle = IupGetDialogChild( GLOBAL.mainDlg, "list_Outline" );
				if( _listHandle )
				{
					for( int i = 1; i < IupGetInt( actTree, "COUNT" ); ++ i )
					{
						CASTnode _node = cast(CASTnode) IupGetAttributeId( actTree, "USERDATA", i );
						if( _node !is null )
						{
							if( bAnyWord )
							{
								if( indexOf( Uni.toLower( _node.name ), Uni.toLower( editText ) ) > -1 ) bGo = true; else bGo = false;
							}
							else
							{
								if( indexOf( Uni.toLower( _node.name ), Uni.toLower( editText ) ) == 0 ) bGo = true; else bGo = false;
							}
							
							if( bGo )
							{
								IupSetStrAttribute( _listHandle, "APPENDITEM", toStringz( _node.name ) );
								GLOBAL.outlineTree.listItemASTs ~= _node;
								GLOBAL.outlineTree.listItemTreeID ~= i;
								imageName = GLOBAL.outlineTree.getImageName( _node );
								if( imageName.length ) IupSetStrAttributeId( _listHandle, "IMAGE", IupGetInt( _listHandle, "COUNT" ), toStringz( imageName ) );
							}
						}
					}

					if( GLOBAL.outlineTree.listItemASTs.length > 0 )
					{
						GLOBAL.outlineTree.listItemIndex = 1;
						version(Windows) IupSetStrAttribute( _listHandle, "VALUE", toStringz( GLOBAL.outlineTree.listItemASTs[0].name ) );
					}
					return true;
				}
			}
			catch( Exception e ){}
		}
		
		return false;
	}	
}