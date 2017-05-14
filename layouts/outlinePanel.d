module layouts.outlinePanel;

private import iup.iup;

private import global, scintilla, actionManager, menu, tools;
private import dialogs.singleTextDlg, dialogs.fileDlg;
private import parser.ast;


private import tango.stdc.stringz, Integer = tango.text.convert.Integer;
private import tango.io.FilePath, tango.io.UnicodeFile, tango.text.Ascii;

class COutline
{
	private:
	import				parser.scanner, parser.token, parser.parser;

	/+
	import tango.core.Thread;
	// Inner Class
	class ReparseThread : Thread
	{
		private:
		import			parser.ast, parser.autocompletion;
		
		CScintilla 		cSci;

		public:
		this( CScintilla _cSci )
		{
			cSci = _cSci;
			super( &run );
		}

		void run()
		{
			if( GLOBAL.enableParser != "ON" ) return;
			
			if( cSci !is null )
			{
				scope f = new FilePath( cSci.getFullPath );

				char[] _ext = toLower( f.ext() );
				if( _ext != "bas" && _ext != "bi" ) return;
				
				if( upperCase( cSci.getFullPath ) in GLOBAL.parserManager )
				{
					Ihandle* actTree = getTree( cSci.getFullPath );
					if( actTree != null )
					{
						try
						{
							char[] document = cSci.getText();
							GLOBAL.parser.updateTokens( GLOBAL.scanner.scan( document ) );
							
							CASTnode astHeadNode = GLOBAL.parser.parse( cSci.getFullPath );
							CASTnode temp = GLOBAL.parserManager[upperCase(cSci.getFullPath)];

							GLOBAL.parserManager[upperCase(cSci.getFullPath)] = astHeadNode;
							delete temp;

							IupSetAttributeId( actTree, "DELNODE", 0, "CHILDREN" ); 
							foreach_reverse( CASTnode t; astHeadNode.getChildren() )
							{
								append( actTree, t, 0 );
							}
						}
						catch( Exception e ){}
					}
				}
			}
		}
	}
	+/

	Ihandle*			layoutHandle, zBoxHandle;
	CASTnode[]			listItemASTs;
	int[]				listItemTreeID;
	int					showIndex= 0;

	void setImage( Ihandle* rootTree, CASTnode _node )
	{
		int lastAddNode = IupGetInt( rootTree, "LASTADDNODE" );

		char[] prot;
		if( _node.protection.length )
		{
			if( _node.protection != "public" && _node.protection != "shared" ) prot = "_" ~ _node.protection;
		}

		switch( _node.kind )
		{
			case B_DEFINE | B_VARIABLE:
				IupSetAttributeId( rootTree, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_define_var" ) );
				break;

			case B_DEFINE | B_FUNCTION:
				IupSetAttributeId( rootTree, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_define_fun" ) );
				break;
				
			case B_VARIABLE:
				if( _node.name.length )
				{
					if( _node.name[length-1] == ')' )
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
				IupSetAttributeId( rootTree, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_operator") );
				if( _node.getChildrenCount > 0 )
				{
					IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, GLOBAL.cString.convert( "IUP_operator" ) );
				}
				
				break;

			case B_PROPERTY:
				if(_node.type.length )
				{
					if( _node.type[0] == '(' )
					{
						IupSetAttributeId( rootTree, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_property" ) );
						if( _node.getChildrenCount > 0 ) IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, GLOBAL.cString.convert( "IUP_property" ) );
					}
					else
					{
						IupSetAttributeId( rootTree, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_property_var" ) );
						if( _node.getChildrenCount > 0 ) IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, GLOBAL.cString.convert( "IUP_property_var" ) );
					}
				}
				
				break;

			case B_CTOR:
				IupSetAttributeId( rootTree, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_ctor" ) );
				if( _node.getChildrenCount > 0 )
				{
					IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, GLOBAL.cString.convert( "IUP_ctor" ) );
				}
				break;

			case B_DTOR:
				IupSetAttributeId( rootTree, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_dtor" ) );
				if( _node.getChildrenCount > 0 )
				{
					IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, GLOBAL.cString.convert( "IUP_dtor" ) );
				}
				break;

			case B_TYPE:
				IupSetAttributeId( rootTree, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_struct" ) );
				if( _node.getChildrenCount > 0 )
				{
					IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, GLOBAL.cString.convert( "IUP_struct" ) );
				}
				break;

			case B_CLASS:
				IupSetAttributeId( rootTree, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_class" ) );
				if( _node.getChildrenCount > 0 )
				{
					IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, GLOBAL.cString.convert( "IUP_class" ) );
				}
				break;

			case B_ENUM:
				IupSetAttributeId( rootTree, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_enum" ) );
				if( _node.getChildrenCount > 0 )
				{
					IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, GLOBAL.cString.convert( "IUP_enum" ) );
				}
				break;				

			case B_ENUMMEMBER:
				IupSetAttributeId( rootTree, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_enummember" ) );
				if( _node.getChildrenCount > 0 )
				{
					IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, GLOBAL.cString.convert( "IUP_enummember" ) );
				}
				break;

			case B_UNION:
				IupSetAttributeId( rootTree, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_union" ) );
				if( _node.getChildrenCount > 0 )
				{
					IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, GLOBAL.cString.convert( "IUP_union" ) );
				}
				break;				

			case B_ALIAS:
				IupSetAttributeId( rootTree, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_alias" ) );
				break;

			case B_NAMESPACE:
				IupSetAttributeId( rootTree, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_namespace" ) );
				if( _node.getChildrenCount > 0 )
				{
					IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, GLOBAL.cString.convert( "IUP_namespace" ) );
				}				
				break;

			case B_MACRO:
				IupSetAttributeId( rootTree, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_macro" ) );
				if( _node.getChildrenCount > 0 )
				{
					IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, GLOBAL.cString.convert( "IUP_macro" ) );
				}				
				break;

			case B_SCOPE:
				IupSetAttributeId( rootTree, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_scope" ) );
				if( _node.getChildrenCount > 0 )
				{
					IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, GLOBAL.cString.convert( "IUP_scope" ) );
				}				
				break;
				
			case B_WITH:
				IupSetAttributeId( rootTree, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_with" ) );
				if( _node.getChildrenCount > 0 )
				{
					IupSetAttributeId( rootTree, "IMAGEEXPANDED", lastAddNode, GLOBAL.cString.convert( "IUP_with" ) );
				}				
				break;

			default:
				IupSetAttributeId( rootTree, "IMAGE", lastAddNode, GLOBAL.cString.convert( "IUP_variable" ) );
		}

		if( GLOBAL.editorSetting00.ColorOutline == "ON" )
		{
			switch( lowerCase( _node.protection ) )
			{
				case "private":		IupSetAttributeId( rootTree, "COLOR", lastAddNode, GLOBAL.cString.convert( "255 0 0" ) ); break;
				case "protected":	IupSetAttributeId( rootTree, "COLOR", lastAddNode, GLOBAL.cString.convert( "255 168 81" ) ); break;
				default:
			}
		}
	}

	void changePR()
	{
		if( IupGetChildCount( zBoxHandle ) > 0 )
		{
			int pos = IupGetInt( zBoxHandle, "VALUEPOS" ); // Get active zbox pos
			Ihandle* actTree = IupGetChild( zBoxHandle, pos );

			for( int i = 1; i < IupGetInt( actTree, "COUNT" ); ++ i )
			{
				CASTnode _node = cast(CASTnode) IupGetAttributeId( actTree, "USERDATA", i );
				
				if( _node !is null )
				{
					switch( _node.kind )
					{
						case B_FUNCTION, B_PROPERTY, B_OPERATOR:
							char[] _type = _node.type;
							char[] _paramString;

							int parenPos = Util.index( _node.type, "(" );
							if( parenPos < _node.type.length )
							{
								_type = _node.type[0..parenPos];
								_paramString = _node.type[parenPos..length];
							}


							if( _node.kind & B_DEFINE )
							{
								switch( showIndex )
								{
									case 0, 1:
										IupSetAttributeId( actTree, "TITLE", i, GLOBAL.cString.convert( _node.name ~ _paramString ) );
										break;
									default:
										IupSetAttributeId( actTree, "TITLE", i, GLOBAL.cString.convert( _node.name ) );
										break;
								}
								break;
							}
							
							switch( showIndex )
							{
								case 0:
									IupSetAttributeId( actTree, "TITLE", i, GLOBAL.cString.convert( _node.name ~ _paramString ~ ( _type.length ? " : " ~ _type : "" ) ) );
									break;
								case 1:
									IupSetAttributeId( actTree, "TITLE", i, GLOBAL.cString.convert( _node.name ~ _paramString ) );
									break;
								case 2:
									IupSetAttributeId( actTree, "TITLE", i, GLOBAL.cString.convert( _node.name ~ ( _type.length ? " : " ~ _type : "" ) ) );
									break;
								default:
									IupSetAttributeId( actTree, "TITLE", i, GLOBAL.cString.convert( _node.name ) );
									break;
							}
							break;

						case B_SUB, B_CTOR, B_DTOR, B_MACRO:
							switch( showIndex )
							{
								case 0, 1:
									IupSetAttributeId( actTree, "TITLE", i, GLOBAL.cString.convert( _node.name ~ _node.type ) );
									break;
								default:
									IupSetAttributeId( actTree, "TITLE", i, GLOBAL.cString.convert( _node.name ) );
									break;
							}
							break;

						case B_VARIABLE, B_ALIAS:
							if( _node.kind & B_DEFINE )
							{
								if( showIndex == 0 || showIndex == 2 )
									IupSetAttributeId( actTree, "TITLE", i, GLOBAL.cString.convert( _node.name ~ ( _node.type.length ? " : " ~ _node.type : "" ) ) );
								else
									IupSetAttributeId( actTree, "TITLE", i, GLOBAL.cString.convert( _node.name ) );
								
								break;
							}					

							if( showIndex == 0 || showIndex == 2 )
								IupSetAttributeId( actTree, "TITLE", i, GLOBAL.cString.convert( _node.name ~ ( _node.type.length ? " : " ~ _node.type : "" ) ) );
							else
								IupSetAttributeId( actTree, "TITLE", i, GLOBAL.cString.convert( _node.name ) );
							
							break;						

						default:
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

					switch( showIndex )
					{
						case 0:
							IupSetAttributeId( rootTree, sCovert.convert( BRANCH ), bracchID, GLOBAL.cString.convert( _node.name ~ _paramString ~ ( _type.length ? " : " ~ _type : "" ) ) );
							IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
							break;
						case 1:
							IupSetAttributeId( rootTree, sCovert.convert( BRANCH ), bracchID, GLOBAL.cString.convert( _node.name ~ _paramString ) );
							IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
							break;
						case 2:
							IupSetAttributeId( rootTree, sCovert.convert( BRANCH ), bracchID, GLOBAL.cString.convert( _node.name ~ ( _type.length ? " : " ~ _type : "" ) ) );
							IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
							break;
						default:
							IupSetAttributeId( rootTree, sCovert.convert( BRANCH ), bracchID, GLOBAL.cString.convert( _node.name ) );
							IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
							break;
					}					
					break;

				case B_SUB, B_CTOR, B_DTOR, B_MACRO:
					switch( showIndex )
					{
						case 0, 1:
							IupSetAttributeId( rootTree, sCovert.convert( BRANCH ), bracchID, GLOBAL.cString.convert( _node.name ~ _node.type ) );
							IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
							break;
						default:
							IupSetAttributeId( rootTree, sCovert.convert( BRANCH ), bracchID, GLOBAL.cString.convert( _node.name ) );
							IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
							break;
					}
					break;

				case B_SCOPE:
					IupSetAttributeId( rootTree, sCovert.convert( BRANCH ), bracchID, null );
					IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
					break;		

				default:
					IupSetAttributeId( rootTree, sCovert.convert( BRANCH ), bracchID, GLOBAL.cString.convert( _node.name ) );
					IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
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
			switch( _node.kind & 4194303 )
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
						switch( showIndex )
						{
							case 0, 1:
								IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( _node.name ~ _paramString ) );
								IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
								break;
							default:
								IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( _node.name ) );
								IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
								break;
						}
						break;
					}					

					switch( showIndex )
					{
						case 0:
							IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( _node.name ~ _paramString ~ ( _type.length ? " : " ~ _type : "" ) ) );
							IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
							break;
						case 1:
							IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( _node.name ~ _paramString ) );
							IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
							break;
						case 2:
							IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( _node.name ~ ( _type.length ? " : " ~ _type : "" ) ) );
							IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
							break;
						default:
							IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( _node.name ) );
							IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
							break;
					}
					break;

				case B_SUB, B_CTOR, B_DTOR:
					switch( showIndex )
					{
						case 0, 1:
							IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( _node.name ~ _node.type ) );
							IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
							break;
						default:
							IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( _node.name ) );
							IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
							break;
					}				
					break;

				case B_VARIABLE, B_ALIAS:
					if( _node.kind & B_DEFINE )
					{
						if( showIndex == 0 || showIndex == 2 )
						{
							IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( _node.name ~ ( _node.type.length ? " : " ~ _node.type : "" ) ) );
							IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
						}
						else
						{
							IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( _node.name ) );
							IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
						}
						
						break;
					}					

					if( showIndex == 0 || showIndex == 2 )
					{
						IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( _node.name ~ ( _node.type.length ? " : " ~ _node.type : "" ) ) );
						IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
					}
					else
					{
						IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( _node.name ) );
						IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
					}
					
					break;

				case B_ENUMMEMBER, B_WITH:
					IupSetAttributeId( rootTree, sCovert.convert( LEAF ), bracchID, GLOBAL.cString.convert( _node.name ) );
					IupSetAttributeId( rootTree, "COLOR", bracchID + 1, GLOBAL.editColor.outlineFore.toCString );
					break;

				default:
					bNoImage = true;
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
		Ihandle* outlineButtonCollapse = IupButton( null, null );
		IupSetAttributes( outlineButtonCollapse, "ALIGNMENT=ARIGHT:ACENTER,FLAT=YES,IMAGE=icon_collapse" );
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
		});
		
		Ihandle* outlineButtonPR = IupButton( null, "PR" );
		IupSetAttributes( outlineButtonPR, "ALIGNMENT=ARIGHT:ACENTER,FLAT=YES,IMAGE=icon_show_pr" );
		IupSetAttribute( outlineButtonPR, "TIP", GLOBAL.languageItems["showpr"].toCString );
		IupSetHandle( "outlineButtonPR", outlineButtonPR );
		IupSetCallback( outlineButtonPR, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			if( GLOBAL.outlineTree.showIndex == 3 ) GLOBAL.outlineTree.showIndex = 0; else GLOBAL.outlineTree.showIndex ++;

			Ihandle* _ih = IupGetHandle( "outlineButtonPR" );
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

			GLOBAL.outlineTree.changePR();
		});

		Ihandle* outlineToggleAnyWord = IupToggle( null, null );
		IupSetAttributes( outlineToggleAnyWord, "ALIGNMENT=ARIGHT:ACENTER,FLAT=YES,IMAGE=icon_searchany,VALUE=TOGGLE" );
		IupSetAttribute( outlineToggleAnyWord, "TIP", GLOBAL.languageItems["searchanyword"].toCString );
		IupSetHandle( "outlineToggleAnyWord", outlineToggleAnyWord );


		Ihandle* outlineButtonFresh = IupButton( null, null );
		IupSetAttributes( outlineButtonFresh, "ALIGNMENT=ARIGHT:ACENTER,FLAT=YES,IMAGE=icon_refresh" );
		IupSetAttribute( outlineButtonFresh, "TIP", GLOBAL.languageItems["sc_reparse"].toCString );
		IupSetCallback( outlineButtonFresh, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			CScintilla cSci = actionManager.ScintillaAction.getActiveCScintilla();
			GLOBAL.outlineTree.refresh( cSci );
		});

		Ihandle* outlineButtonHide = IupButton( null, null );
		IupSetAttributes( outlineButtonHide, "ALIGNMENT=ALEFT,FLAT=YES,IMAGE=icon_shift_l" );
		IupSetAttribute( outlineButtonHide, "TIP", GLOBAL.languageItems["hide"].toCString );
		IupSetCallback( outlineButtonHide, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			menu.outlineMenuItem_cb( GLOBAL.menuOutlineWindow );
		});

		Ihandle* outlineToolbarTitleImage = IupLabel( null );
		IupSetAttributes( outlineToolbarTitleImage, "IMAGE=icon_outline,ALIGNMENT=ALEFT:ACENTER" );

		/*Ihandle* outlineToolbarTitle = IupLabel( "Outline" );
		IupSetAttribute( outlineToolbarTitle, "ALIGNMENT", "ALEFT" );*/

		Ihandle* outlineToolbarH = IupHbox( outlineToolbarTitleImage, /*outlineToolbarTitle,*/ IupFill, outlineButtonCollapse, outlineButtonPR, outlineButtonFresh, outlineToggleAnyWord, outlineButtonHide, null );
		IupSetAttributes( outlineToolbarH, "ALIGNMENT=ACENTER,SIZE=NULL" );


		Ihandle* outlineTreeNodeList = IupList( null );
		IupSetAttributes( outlineTreeNodeList, "ACTIVE=YES,DROPDOWN=YES,SHOWIMAGE=YES,EDITBOX=YES,EXPAND=YES,DROPEXPAND=NO,VISIBLEITEMS=8" );

		IupSetCallback( outlineTreeNodeList, "DROPDOWN_CB",cast(Icallback) &COutline_List_DROPDOWN_CB );
		IupSetCallback( outlineTreeNodeList, "ACTION",cast(Icallback) &COutline_List_ACTION );
		

		version(linux)
		{
			IupSetCallback( outlineTreeNodeList, "EDIT_CB",cast(Icallback) &COutline_List_EDIT_CB );
			IupSetCallback( outlineTreeNodeList, "K_ANY",cast(Icallback) &COutline_List_K_ANY );
		}

		layoutHandle = IupVbox( outlineToolbarH, outlineTreeNodeList, zBoxHandle, null );
		IupSetAttributes( layoutHandle, GLOBAL.cString.convert( "ALIGNMENT=ARIGHT,EXPANDCHILDREN=YES,GAP=2" ) );
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
		createLayout();
	}

	~this()
	{
		IupSetHandle( "outlineButtonPR", null );
		IupSetHandle( "outlineToggleAnyWord", null );
	}

	void changeColor()
	{
		for( int i = 0; i < IupGetChildCount( zBoxHandle ); ++i )
		{
			Ihandle* ih = IupGetChild( zBoxHandle, i ); // tree
			if( ih != null )
			{
				version(Windows) IupSetAttribute( ih, "BGCOLOR", GLOBAL.editColor.outlineBack.toCString );
			}
		}
		
		foreach( CScintilla cSci; GLOBAL.scintillaManager )
			refresh( cSci );
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
			if( head.kind == B_BAS || head.kind == B_BI )
			{
				char[] fullPath = head.name;

				Ihandle* tree = IupTree();
				IupSetAttributes( tree, GLOBAL.cString.convert( "ADDROOT=YES,EXPAND=YES,RASTERSIZE=0x" ) );
				version(Windows) IupSetAttribute( tree, "BGCOLOR", GLOBAL.editColor.outlineBack.toCString );
				
				IupSetAttribute( tree, "TITLE", toStringz( fullPath ) );
				IupSetAttributeId( tree, "COLOR", 0, GLOBAL.editColor.outlineFore.toCString );
				
				toBoldTitle( tree, 0 );
				IupSetCallback( tree, "BUTTON_CB", cast(Icallback) &COutline_BUTTON_CB );

				IupAppend( zBoxHandle, tree );
				IupMap( tree );
				IupRefresh( GLOBAL.outlineTree.getZBoxHandle );	
				foreach_reverse( CASTnode t; head.getChildren() )
				{
					append( tree, t, 0 );
				}
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

				if( fullPath == _fullPath )
				{
					IupSetAttribute( ih, "DELNODE", "ALL" );
					if( bDestroy ) IupDestroy( ih );
					break;
				}
			}
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

				if( fullPath == _fullPath ) return ih;
			}
		}

		return null;
	}
	

	Ihandle* getZBoxHandle(){ return zBoxHandle; }


	CASTnode loadFile( char[] fullPath )
	{
		if( GLOBAL.enableParser != "ON" ) return null;
		
		scope f = new FilePath( fullPath );

		char[] _ext = toLower( f.ext() );

		if( _ext != "bas" && _ext != "bi" ) return null;

		
		CScintilla actCSci;
		
		foreach( CScintilla cSci; GLOBAL.scintillaManager )
		{
			if( upperCase(fullPath) == upperCase(cSci.getFullPath()) )
			{
				actCSci = cSci;
				break;
			}
		}


		if( actCSci !is null )
		{
			if( upperCase(fullPath) in GLOBAL.parserManager )
			{
				cleanTree( fullPath );
			}
			else
			{
				char[] document = actCSci.getText();
				GLOBAL.parser.updateTokens( GLOBAL.scanner.scan( document ) );
				GLOBAL.parserManager[upperCase(fullPath)] = GLOBAL.parser.parse( fullPath );
				//IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( "\t"~fullPath ) );
			}

			createTree( GLOBAL.parserManager[upperCase(fullPath)] );
			CScintilla nowCsci = ScintillaAction.getActiveCScintilla();
			if( nowCsci == actCSci ) changeTree( fullPath );
		}
		else
		{
			if( upperCase(fullPath) in GLOBAL.parserManager )
			{
			}
			else
			{
				// Don't Create Tree
				// Parser
				GLOBAL.parser.updateTokens( GLOBAL.scanner.scanFile( fullPath ) );
				GLOBAL.parserManager[upperCase(fullPath)] = GLOBAL.parser.parse( fullPath );
				//IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( fullPath ) );
			}
		}

		return GLOBAL.parserManager[upperCase(fullPath)];

		//hardRefresh( fullPath );
	}

	char[] getImageName( CASTnode _node )
	{
		char[] prot;
		if( _node.protection.length )
		{
			if( _node.protection != "public" && _node.protection != "shared" ) prot = "_" ~ _node.protection;
		}

		switch( _node.kind )
		{
			case B_DEFINE | B_VARIABLE: return "IUP_define_var";
			case B_DEFINE | B_FUNCTION: return "IUP_define_fun";
			case B_VARIABLE:
				if( _node.name.length )
				{
					if( _node.name[length-1] == ')' ) return ( "IUP_variable_array" ~ prot ); else return( "IUP_variable" ~ prot );
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
						
						/+
						if( _node.lineNumber == _ln  )
						{
							if( fromStringz( IupGetAttributeId( actTree, "KIND", i - 1 ) ) == "LEAF" )
							{
								int sonID = i - 1;
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
								
								if( parentID <= 0 ) insertID = i - 1; // parentID = 0 = root node
							}
							else
							{
								insertID = -( i - 1 );
							}

							IupSetAttributeId( actTree, "DELNODE", i, "SELECTED" );
							bEqual = true;
						}
						else if( _node.lineNumber < _ln )
						{
							if( bEqual ) break;
							if( fromStringz( IupGetAttributeId( actTree, "KIND", i ) ) == "LEAF" )
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
								
								if( parentID <= 0 ) insertID = i; // parentID = 0 = root node
							}
							else
							{
								insertID = -i; // AddNODE, depth +1 
							}
							
							break;
						}
						+/
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

	/+
	int removeNodeByLineNumber( int _ln )
	{
		int insertID = 0;
		
		try
		{
			Ihandle* actTree = getActiveTree();
			
			if( actTree != null )
			{
				bool bEqual;
				for( int i = IupGetInt( actTree, "COUNT" ) - 1; i > 0; --i )
				{
					CASTnode _node = cast(CASTnode) IupGetAttributeId( actTree, "USERDATA", i );
					if( _node !is null )
					{
						if( _node.lineNumber == _ln  )
						{
							/+
							insertID = i - 1;
							// Check if the be deleted node is the first child node of branch or not
							if( fromStringz( IupGetAttributeId( actTree, "KIND", insertID ) ) == "BRANCH" ) insertID = -insertID;

							IupSetAttributeId( actTree, "DELNODE", i, "SELECTED" );
							+/
							if( fromStringz( IupGetAttributeId( actTree, "KIND", i - 1 ) ) == "LEAF" )
							{
								int parentID = IupGetIntId( actTree, "PARENT", i - 1 );
								CASTnode _parentNode = cast(CASTnode) IupGetAttributeId( actTree, "USERDATA", parentID );
								if( parentID > 0 )
								{
									if( _parentNode.endLineNum < _ln ) 
										insertID = parentID; // New node out BRANCH block
									else
										insertID = i - 1; // New node in BRANCH block
								}
								else
								{
									insertID = i - 1; // parentID = 0 = root node
								}								
							}
							else
							{
								insertID = -( i - 1 );
							}

							IupSetAttributeId( actTree, "DELNODE", i, "SELECTED" );
							bEqual = true;
						}
						else if( _node.lineNumber < _ln )
						{
							if( bEqual ) break;
							if( fromStringz( IupGetAttributeId( actTree, "KIND", i ) ) == "LEAF" )
							{
								int parentID = IupGetIntId( actTree, "PARENT", i );
								CASTnode _parentNode = cast(CASTnode) IupGetAttributeId( actTree, "USERDATA", parentID );
								if( parentID > 0 )
								{
									if( _parentNode.endLineNum < _ln ) 
										insertID = parentID; // New node out BRANCH block
									else
										insertID = i; // New node in BRANCH block
								}
								else
								{
									insertID = i; // parentID = 0 = root node
								}

								//if( parentID == i - 1 ) insertID = -i; // If insertID <=0, using "ADDLEAF"; insertID > 0, using "INSERTLEAF"
							}
							else
							{
								insertID = -i;
							}
							
							break;
						}						
					}
				}
			}
		}
		catch( Exception e ){}

		return insertID;
	}
	+/

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

	/+
	int removeBlockNodeByLineNumber( int _ln )
	{
		/+
		int insertID = -1;
		
		try
		{
			Ihandle* actTree = getActiveTree();
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
							break;
						}
					}
					else if( _node.lineNumber < _ln )
					{
						insertID = i + 1;
						break;
					}					
				}

				if( insertID > 0 ) insertID --;
			}
		}
		catch( Exception e ){}
		+/

		int insertID = 0;

		try
		{
			Ihandle* actTree = getActiveTree();
			
			if( actTree != null )
			{
				for( int i = IupGetInt( actTree, "COUNT" ) - 1; i > 0; --i )
				{
					CASTnode _node = cast(CASTnode) IupGetAttributeId( actTree, "USERDATA", i );
					if( _node !is null )
					{
						if( _node.lineNumber == _ln  )
						{
							//IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( " InsertID= " ~ Integer.toString(i) ) );

							if( fromStringz( IupGetAttributeId( actTree, "KIND", i - 1 ) ) == "LEAF" )
							{
								int parentID = IupGetIntId( actTree, "PARENT", i - 1 );
								CASTnode _parentNode = cast(CASTnode) IupGetAttributeId( actTree, "USERDATA", parentID );
								if( parentID > 0 )
								{
									if( _parentNode.endLineNum < _ln ) 
										insertID = parentID; // New node out BRANCH block
									else
										insertID = i - 1; // New node in BRANCH block
								}
								else
								{
									insertID = i - 1; // parentID = 0 = root node
								}								
							}
							else
							{
								insertID = -( i - 1 );
							}

							
							/*
							insertID = i - 1;
							// Check if the be deleted node is the first child node of branch or not
							if( fromStringz( IupGetAttributeId( actTree, "KIND", insertID ) ) == "BRANCH" ) insertID = -insertID;
							*/

							IupSetAttributeId( actTree, "DELNODE", i, "SELECTED" );
							break;
						}
						else if( _node.lineNumber < _ln )
						{
							if( fromStringz( IupGetAttributeId( actTree, "KIND", i ) ) == "LEAF" )
							{
								int parentID = IupGetIntId( actTree, "PARENT", i );
								CASTnode _parentNode = cast(CASTnode) IupGetAttributeId( actTree, "USERDATA", parentID );
								if( parentID > 0 )
								{
									if( _parentNode.endLineNum < _ln ) 
										insertID = parentID; // New node out BRANCH block
									else
										insertID = i; // New node in BRANCH block
								}
								else
								{
									insertID = i; // parentID = 0 = root node
								}

								//if( parentID == i - 1 ) insertID = -i; // If insertID <=0, using "ADDLEAF"; insertID > 0, using "INSERTLEAF"
							}
							else
							{
								insertID = -i;
							}
							
							break;
						}						
					}
				}
			}
		}
		catch( Exception e ){}		

		return insertID;
	}
	+/

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

		char[] _ext = toLower( f.ext() );
		if( _ext != "bas" && _ext != "bi" ) return false;
		
		if( cSci !is null )
		{
			if( upperCase( cSci.getFullPath ) in GLOBAL.parserManager )
			{
				Ihandle* actTree = getTree( cSci.getFullPath );
				if( actTree != null )
				{
					try
					{
						char[] document = cSci.getText();
						GLOBAL.parser.updateTokens( GLOBAL.scanner.scan( document ) );
						
						CASTnode astHeadNode = GLOBAL.parser.parse( cSci.getFullPath );
						CASTnode temp = GLOBAL.parserManager[upperCase(cSci.getFullPath)];

						GLOBAL.parserManager[upperCase(cSci.getFullPath)] = astHeadNode;
						delete temp;

						IupSetAttributeId( actTree, "DELNODE", 0, "CHILDREN" ); 
						foreach_reverse( CASTnode t; astHeadNode.getChildren() )
						{
							append( actTree, t, 0 );
						}

						return true;
					}
					catch( Exception e ){}
				}
			}
		}
		/+
		try
		{
			ReparseThread p = new ReparseThread( cSci );
			p.start();
		}
		catch
		{
			return false;
		}
		+/

		return true;
	}

	CASTnode parserText( char[] text, int B_KIND = 0 )
	{
		// Don't Create Tree
		try
		{
			// Parser
			GLOBAL.parser.updateTokens( GLOBAL.scanner.scan( text ) );
			return GLOBAL.parser.parse( "x.bas", B_KIND );
		}
		catch( Exception e )
		{
		}

		return null;
	}	
}

extern(C) 
{
	private int COutline_BUTTON_CB( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		int id = IupConvertXYToPos( ih, x, y );

		/*
		if( fromStringz( IupGetAttribute( ih, "MARKMODE" ) ) == "MULTIPLE" )
		{
			IupSetAttributes( ih, GLOBAL.cString.convert( "MARK=CLEARALL" ) );
			IupSetAttributes( ih, GLOBAL.cString.convert( "MARKMODE=SINGLE" ) );
		}
		*/

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
						
						if( _node !is null )
						{
							char[] _fullPath = fromStringz( IupGetAttributeId( ih, "TITLE", 0 ) ); // Get Tree-Head Title
						
							ScintillaAction.openFile( _fullPath, _node.lineNumber );
							version(Windows) IupSetAttributeId( ih, "MARKED", id, "YES" ); else IupSetInt( ih, "VALUE", id );

							return IUP_IGNORE;
						}
					}
				}
			}
		}
		/+
		else if( button == 51 ) // IUP_BUTTON3 = '3' = 51
		{
			if( id > 0 )
			{
				if( pressed == 0 )
				{
					version(Windows) IupSetAttributeId( ih, "MARKED", id, "YES" ); else IupSetInt( ih, "VALUE", id );
					
					
					if( IupGetIntId( ih, "CHILDCOUNT", id ) == 0 ) return IUP_DEFAULT;
					
					GLOBAL.outlineTree.nowDepth = IupGetIntId( ih, "DEPTH", id );
					GLOBAL.outlineTree.nowState = IupGetAttributeId( ih, "STATE", id );
					
					if( GLOBAL.outlineTree.nowState == null ) return IUP_DEFAULT;
					
					Ihandle* itemExpand = IupItem( "Expand/Contract This Depth", null );
					IupSetCallback( itemExpand, "ACTION", cast(Icallback) function( Ihandle* ih )
					{
						Ihandle* actTree = GLOBAL.outlineTree.getActiveTree();
						
						if( actTree != null )
						{
							//bool bEqual;
							for( int i = IupGetInt( actTree, "COUNT" ) - 1; i > 0; --i )
							{
								if( IupGetIntId( actTree, "DEPTH", i ) == GLOBAL.outlineTree.nowDepth )
								{
									if( IupGetIntId( actTree, "CHILDCOUNT", i ) > 0 )
									{
										if( fromStringz( IupGetAttributeId( actTree, "KIND", i ) ) == "BRANCH" )
										{
											if( fromStringz( GLOBAL.outlineTree.nowState ) == "EXPANDED" )
												IupSetAttributeId( actTree, "STATE", i, "COLLAPSED" );
											else
												IupSetAttributeId( actTree, "STATE", i, "EXPANDED" );
										}
									}
								}
							}
						}
					});					
					
					Ihandle* popupMenu = IupMenu( 	itemExpand,
													/*IupSeparator(),
													itemSearch,*/
													null
												);

					IupPopup( popupMenu, IUP_MOUSEPOS, IUP_MOUSEPOS );
					IupDestroy( popupMenu );
				}
			}
		}
		+/

		return IUP_DEFAULT;
	}

	private int COutline_List_DROPDOWN_CB( Ihandle *ih, int state )
	{
		if( state == 1 )
		{
			if( IupGetChildCount( GLOBAL.outlineTree.getZBoxHandle ) > 0 )
			{
				int pos = IupGetInt( GLOBAL.outlineTree.getZBoxHandle, "VALUEPOS" ); // Get active zbox pos
				Ihandle* actTree = IupGetChild( GLOBAL.outlineTree.getZBoxHandle, pos );

				char[] imageName, editText = Util.trim( fromStringz( IupGetAttribute( ih, "VALUE" ) ) );

				IupSetAttribute( ih, "REMOVEITEM", "ALL" );
				GLOBAL.outlineTree.listItemASTs.length = 0;
				GLOBAL.outlineTree.listItemTreeID.length = 0;

				bool bAnyWord, bGo;
				if( fromStringz( IupGetAttribute( IupGetHandle( "outlineToggleAnyWord" ), "VALUE" ) ) == "ON" ) bAnyWord = true; else bAnyWord = false;
				
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

				if( IupGetInt( ih, "COUNT" ) > 0 ) IupSetAttribute( ih, "VALUE", IupGetAttribute( ih, "1" ) );
			}
		}
		
		return IUP_DEFAULT;
	}

	private int COutline_List_ACTION( Ihandle *ih, char *text, int item, int state )
	{
		//IupMessage("BEFORE",toStringz(Integer.toString(item)));

		if( state == 1 )
		{
			if( IupGetInt( ih, "COUNT" ) > 0 )
			{
				if( item <= GLOBAL.outlineTree.listItemASTs.length )
				{
					ScintillaAction.openFile( ScintillaAction.getActiveCScintilla.getFullPath, GLOBAL.outlineTree.listItemASTs[--item].lineNumber );
					Ihandle* tree = GLOBAL.outlineTree.getActiveTree();
					if( tree != null ) version(Windows) IupSetAttributeId( tree, "MARKED", GLOBAL.outlineTree.listItemTreeID[item], "YES" ); else IupSetInt( tree, "VALUE", GLOBAL.outlineTree.listItemTreeID[item] );
				}
			}
		}
		
		return IUP_DEFAULT;
	}	

	version(linux)
	{
		private int COutline_List_EDIT_CB( Ihandle *ih, int c, char *new_value )
		{
			//IupMessage("new_value",new_value);
			//IupMessage("c",toStringz(Integer.toString(c)));
			IupSetAttribute( ih, "APPENDITEM", toStringz( "DUMMY" ) );

			return IUP_DEFAULT;
		}

		private int COutline_List_K_ANY( Ihandle *ih, int c )
		{
			if( IupGetChildCount( GLOBAL.outlineTree.getZBoxHandle ) > 0 )
			{
				if(  c == 13 ) IupSetAttribute( ih, "SHOWDROPDOWN", "YES" );
			}
			return IUP_DEFAULT;
		}
	}
}