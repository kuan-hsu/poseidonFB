module parser.autocompletion;

struct AutoComplete
{
	private:
	import iup.iup;
	import iup.iup_scintilla;

	import global, actionManager, menu;
	import tools;
	import parser.ast;

	import Integer = tango.text.convert.Integer, Util = tango.text.Util, UTF = tango.text.convert.Utf;
	import tango.stdc.stringz;
	import tango.io.FilePath, tango.sys.Environment, Path = tango.io.Path;
	import tango.io.Stdout;

	version(Windows)
	{
		import tango.sys.win32.Types;
		
		struct HH_AKLINK
		{
			int       cbStruct;     // sizeof this structure
			BOOL      fReserved;    // must be FALSE (really!)
			LPCTSTR   pszKeywords;  // semi-colon separated keywords
			LPCTSTR   pszUrl;       // URL to jump to if no keywords found (may be NULL)
			LPCTSTR   pszMsgText;   // Message text to display in MessageBox if pszUrl is NULL and no keyword match
			LPCTSTR   pszMsgTitle;  // Message text to display in MessageBox if pszUrl is NULL and no keyword match
			LPCTSTR   pszWindow;    // Window to display URL in
			BOOL      fIndexOnFail; // Displays index if keyword lookup fails.
		}
	}

	static char[][]				listContainer;
	static CASTnode[char[]]		includesMarkContainer;
	
	
	static void cleanIncludesMarkContainer()
	{
		foreach( char[] key; includesMarkContainer.keys )
			includesMarkContainer.remove( key );
		//IupMessage("",toStringz(Integer.toString(includesMarkContainer.length)));
	}
	
	static void getTypeAndParameter( CASTnode node, inout char[] _type, inout char[] _param )
	{
		int openParenPos = Util.index( node.type, "(" );
		if( openParenPos < node.type.length )
		{
			_type = node.type[0..openParenPos];
			_param = node.type[openParenPos..$];
		}
		else
		{
			_type = node.type;
		}
	}
	
	static char[] getListImage( CASTnode node )
	{
		if( GLOBAL.toggleShowAllMember == "OFF" )
			if( node.protection == "private" ) return null;
		
		int protAdd;
		switch( node.protection )
		{
			case "public":		protAdd = 2; break;
			case "private":		protAdd = 0; break;
			case "protected":	protAdd = 1; break;
			default:			protAdd = 2;
		}

		char[] name = node.name;
		if( node.name.length )
		{
			if( node.name[length-1] == ')' )
			{
				int posOpenParen = Util.index( node.name, "(" );
				if( posOpenParen < node.name.length ) name = node.name[0..posOpenParen];
			}
		}
		else
			return null;

		bool bShowType = GLOBAL.toggleShowListType == "ON" ? true : false;
		char[] type = node.type;

		if( bShowType )
		{
			if( node.type.length )
			{
				int posOpenParen = Util.index( node.type, "(" );
				if( posOpenParen < node.type.length ) type = node.type[0..posOpenParen]; else type = node.type;
			}
		}
		
		switch( node.kind )
		{
			case B_DEFINE | B_VARIABLE:	return name ~ "?33";
			case B_DEFINE | B_FUNCTION:	return name ~ "?34";
			
			case B_SUB:					return bShowType ? name ~ "~void" ~ "?" ~ Integer.toString( 25 + protAdd ) : name ~ "?" ~ Integer.toString( 25 + protAdd );
			case B_FUNCTION:			return bShowType ? name  ~ "~" ~ type ~ "?" ~ Integer.toString( 28 + protAdd ) : name ~ "?" ~ Integer.toString( 28 + protAdd );
			case B_VARIABLE:
				if( node.name.length )
				{
					if( node.name[length-1] == ')' ) return bShowType ? name ~ "~" ~ type ~ "?" ~ Integer.toString( 0 + protAdd ) : name ~ "?" ~ Integer.toString( 0 + protAdd ); else return bShowType ? name ~ "~" ~ type ~ "?" ~ Integer.toString( 3 + protAdd ) : name ~ "?" ~ Integer.toString( 3 + protAdd );
				}
				break;

			case B_PROPERTY:
				if( node.type.length )
				{
					if( node.type[0] == '(' ) return name ~ "?31"; else	return name ~ "?32";
				}
				break;
				
			case B_CLASS:					return name ~ "?" ~ Integer.toString( 6 + protAdd );
			case B_TYPE: 					return name ~ "?" ~ Integer.toString( 9 + protAdd );
			case B_ENUM: 					return name ~ "?" ~ Integer.toString( 12 + protAdd );
			case B_PARAM:					return bShowType ? name ~ "~" ~ type ~ "?18" : name ~ "?18";
			case B_ENUMMEMBER:				return name ~ "?19";
			case B_ALIAS:					return name ~ "?20";
			case B_NAMESPACE:				return name ~ "?24";
			case B_INCLUDE, B_CTOR, B_DTOR:	return null;
			case B_OPERATOR:				return null;
			default:						return name ~ "?21";
		}

		return name;
	}

	static CASTnode[] anonymousEnumMembers( CASTnode originalNode )
	{
		CASTnode[] results;
		
		if( originalNode.kind & B_ENUM )
		{
			foreach( CASTnode _node; originalNode.getChildren() )
			{
				results ~= _node;
			}
		}

		return results;
	}

	static CASTnode[] getAnonymousEnumMemberFromWord( CASTnode originalNode, char[] word )
	{
		CASTnode[] results;
		
		if( originalNode.kind & B_ENUM )
		{
			if( !originalNode.name.length )
			{
				foreach( CASTnode _node; anonymousEnumMembers( originalNode ) )
				{
					if( Util.index( lowerCase( _node.name ), word ) == 0 ) results ~= _node;
				}
			}
		}

		return results;
	}

	/*
	static CASTnode getAnonymousEnumMemberFromWholeWord( CASTnode originalNode, char[] word )
	{
		if( originalNode.kind & B_ENUM )
		{
			if( !originalNode.name.length )
			{			
				foreach( CASTnode _node; anonymousEnumMembers( originalNode ) )
				{
					if( lowerCase( _node.name )== lowerCase( word ) ) return _node;
				}
			}
		}

		return null;
	}
	*/

	static CASTnode _searchMatchNode( CASTnode originalNode, char[] word, int B_KIND = B_ALL )
	{
		if( originalNode is null ) return null;
		
		CASTnode resultNode;
		
		foreach( CASTnode _node; originalNode.getChildren() )
		{
			if( _node.kind & B_KIND )
			{
				if( lowerCase( removeArrayAndPointerWord( _node.name ) ) == lowerCase( word ) )
				{
					resultNode = _node;
					break;
				}
			}
		}

		if( resultNode is null )
		{
			if( originalNode.getFather() !is null )
			{
				resultNode = _searchMatchNode( originalNode.getFather(), word, B_KIND );
			}
			else
			{
				auto cSci = actionManager.ScintillaAction.getActiveCScintilla();
				CASTnode[] resultIncludeNodes = getMatchIncludesFromWord( GLOBAL.parserManager[upperCase(cSci.getFullPath)], cSci.getFullPath, word );

				if( resultIncludeNodes.length ) resultNode = resultIncludeNodes[0];
			}
		}

		return resultNode;
	}	

	static CASTnode getBaseNode( CASTnode originalNode )
	{
		// Extends
		if( originalNode.base.length )
		{
			if( originalNode.kind & ( B_TYPE | B_CLASS | B_UNION ) )
			{
				return _searchMatchNode( originalNode, lowerCase( originalNode.base ), B_TYPE | B_CLASS | B_UNION  );
			}
		}

		return null;
	}

	static CASTnode[] getBaseNodeMembers( CASTnode originalNode )
	{
		CASTnode[] results;
		
		// Extends
		CASTnode mother = getBaseNode( originalNode );
		if( mother !is null )
		{
			foreach( CASTnode _node; mother.getChildren() )
			{
				if( _node.protection != "private" )
				{
					results ~= _node;
				}
			}

			results ~= getBaseNodeMembers( mother );
		}

		return results;
	}


	static CASTnode[] getMatchASTfromWholeWord( CASTnode node, char[] word, int line, int B_KIND )
	{
		CASTnode[] results;
		
		foreach( child; node.getChildren() )
		{
			if( child.kind & B_KIND )
			{
				if( lowerCase( child.name ) == lowerCase( word ) )
				{
					if( line < 0 )
					{
						results ~= child;
					}
					else
					{
						if( line >= child.lineNumber ) results ~= child;
					}
				}
				/*
				else
				{
					if( line >= child.lineNumber )
					{
						CASTnode enumResult = getAnonymousEnumMemberFromWholeWord( child, word );
						if( enumResult !is null ) results ~= enumResult;
					}
				}
				*/
			}
		}

		if( node.getFather() !is null )
		{
			results ~= getMatchASTfromWholeWord( node.getFather, word, line, B_KIND );
		}

		return results;
	}	

	static CASTnode[] getMatchASTfromWord( CASTnode node, char[] word, int line )
	{
		CASTnode[] results;
		
		foreach( child; node.getChildren() )
		{
			if( child.name.length )
			{
				if( Util.index( lowerCase( child.name ), lowerCase( word ) ) == 0 )
				{
					if( line >= child.lineNumber ) results ~= child;
				}
			}
			else
			{
				if( line >= child.lineNumber )
				{
					CASTnode[] enumResult = getAnonymousEnumMemberFromWord( child, word );
					if( enumResult.length ) results ~= enumResult;
				}
			}

			/*
			if( Util.index( lowerCase( child.name ), word ) == 0 )
			{
				if( line >= child.lineNumber ) results ~= child;
			}
			*/
		}

		if( node.getFather() !is null )
		{
			results ~= getMatchASTfromWord( node.getFather, word, line );
		}

		return results;
	}

	static char[] checkIncludeExist( char[] include, char[] originalFullPath )
	{
		if( include.length > 2 )
		{
			if( include[0] == '"' && include[length-1] == '"' ) include = include[1..length-1];
		}
		else
		{
			return null;
		}
		
		// Step 1: Relative from the directory of the source file
		scope  _path = new FilePath( originalFullPath ); // Tail include /
		char[] testPath = _path.path() ~ include;
		_path.set( testPath ); // Reset
		if( _path.exists() ) return testPath;


		// Step 2: Relative from the current working directory
		char[] dir = actionManager.ProjectAction.fileInProject( originalFullPath );
		if( dir.length )
		{
			if( dir[$-1] != '/' ) dir ~= "/";
			testPath = dir ~ include;

			_path.set( testPath ); // Reset
			if( _path.exists() ) return testPath;
		}

		testPath = Environment.cwd() ~ include; // Environment.cwd(), Tail include /
		_path.set( testPath ); // Reset
		if( _path.exists() ) return testPath;


		// Step 3: Relative from addition directories specified with the -i command line option
		// Work on Project
		char[] prjDir = actionManager.ProjectAction.fileInProject( originalFullPath );

		if( prjDir.length )
		{
			//Stdout( "Project Dir: " ~ prjDir ).newline;
			char[][] includeDirs = GLOBAL.projectManager[prjDir].includeDirs; // without \
			foreach( char[] s; includeDirs )
			{
				testPath = s ~ "/" ~ include;
				
				_path.set( testPath ); // Reset

				if( _path.exists() ) return testPath;
			}
		}

		// Step 4(Final): The include folder of the FreeBASIC installation (FreeBASIC\inc, where FreeBASIC is the folder where the fbc executable is located)
		_path.set( Path.normalize( GLOBAL.compilerFullPath.toDString ) );
		version( Windows )
		{
			testPath = _path.path() ~ "inc/" ~ include;
		}
		else
		{
			testPath = _path.path();
			int pos = Util.rindex( testPath, "/bin/" );
			if( pos > 0 && pos < testPath.length )
			{
				testPath = testPath[0..pos] ~ "/include/freebasic/" ~ include;
			}
			else
			{
				return null;
			}
		}
				
		_path.set( testPath ); // Reset
		if( _path.exists() )
		{
			//Stdout( "Bi fullpath :" ~ _path.toString ).newline; 
			return testPath;
		}
		
		return null;
	}

	static CASTnode[] check( char[] name, char[] originalFullPath )
	{
		CASTnode[] results;
		
		char[] includeFullPath = checkIncludeExist( name, originalFullPath );

		if( includeFullPath.length )
		{
			if( upperCase(includeFullPath) in includesMarkContainer ) return null;

			CASTnode includeAST;
			if( upperCase(includeFullPath) in GLOBAL.parserManager )
			{
				includesMarkContainer[upperCase(includeFullPath)] = GLOBAL.parserManager[upperCase(includeFullPath)];
					
				results ~= GLOBAL.parserManager[upperCase(includeFullPath)];
				results ~= getIncludes( GLOBAL.parserManager[upperCase(includeFullPath)], includeFullPath );
			}
			else
			{
				//IupSetAttribute( GLOBAL.searchOutputPanel, "APPEND", toStringz( includeFullPath ));
				CASTnode _createFileNode = GLOBAL.outlineTree.loadFile( includeFullPath );
				
				if( _createFileNode !is null )
				{
					if( GLOBAL.editorSetting00.Message == "ON" ) 
					{
						version(Windows) GLOBAL.IDEMessageDlg.print( "  Pre-Parse file: [" ~ includeFullPath ~ "]" );//IupSetAttribute( GLOBAL.outputPanel, "APPEND\0", toStringz( "  Pre-Parse file: [" ~ includeFullPath ~ "]" ) );
					}
					
					includesMarkContainer[upperCase(includeFullPath)] = _createFileNode;
					
					results ~= _createFileNode;
					results ~= getIncludes( _createFileNode, includeFullPath );
				}
			}
		}

		return results;
	}

	static CASTnode[] getMatchIncludesFromWholeWord( CASTnode originalNode, char[] originalFullPath, char[] word, int B_KIND )
	{
		if( originalNode is null ) return null;
		
		CASTnode[] results;

		/+
		foreach( char[] key; includesMarkContainer.keys )
			includesMarkContainer.remove( key );		
		+/
		
		// Parse Include
		//CASTnode[] includeASTnodes = getIncludes( originalNode, originalFullPath );
		getIncludes( originalNode, originalFullPath, true );

		foreach( includeAST; includesMarkContainer )
		{
			if( includeAST !is null )
			{
				foreach( child; includeAST.getChildren )
				{
					if( child.kind & B_NAMESPACE )
					{
						if( child.name.length )
						{
							if( lowerCase( child.name ) == lowerCase( word ) )
							{
								results ~= child;
							}
							else
							{
								foreach( _child; child.getChildren )
								{
									if( _child.name.length )
									{
										if( lowerCase( _child.name ) == lowerCase( word ) )
										{
											results ~= _child;
										}
									}
									else
									{
										CASTnode[] enumResult = getAnonymousEnumMemberFromWord( _child, lowerCase( word ) );
										if( enumResult.length ) results ~= enumResult;
									}
								}
							}
						}
					}
					else
					{
						if( child.name.length )
						{
							if( lowerCase( child.name ) == lowerCase( word ) )
							{
								results ~= child;
							}
						}
						else
						{
							CASTnode[] enumResult = getAnonymousEnumMemberFromWord( child, lowerCase( word ) );
							if( enumResult.length ) results ~= enumResult;
						}
					}

					/+
					if( child.kind & B_KIND )
					{
						if( lowerCase( child.name ) == lowerCase( word ) )
						{
							results ~= child;
						}
						/*
						else
						{
							CASTnode enumResult = getAnonymousEnumMemberFromWholeWord( child, word );
							if( enumResult !is null ) results ~= enumResult;
						}
						*/
					}
					+/
				}
			}
		}

		return results;
	}	

	static CASTnode[] getMatchIncludesFromWord( CASTnode originalNode, char[] originalFullPath, char[] word )
	{
		if( originalNode is null ) return null;
		
		CASTnode[] results;

		/+
		foreach( char[] key; includesMarkContainer.keys )
			includesMarkContainer.remove( key );
		+/

		// Parse Include
		//CASTnode[] includeASTnodes = getIncludes( originalNode, originalFullPath );
		getIncludes( originalNode, originalFullPath, true );

		/*
		foreach( CASTnode n; includesMarkContainer )
			Stdout( n.name ).newline;
		*/
		foreach( includeAST; includesMarkContainer )
		{
			if( includeAST !is null )
			{
				foreach( child; includeAST.getChildren )
				{
					if( child.kind & B_NAMESPACE )
					{
						if( child.name.length )
						{
							if( Util.index( lowerCase( child.name ), lowerCase( word ) ) == 0 )
							{
								results ~= child;
							}
							else
							{
								foreach( _child; child.getChildren )
								{
									if( _child.name.length )
									{
										// Bug
										if( Util.index( lowerCase( _child.name ), lowerCase( word ) ) == 0 )
										{
											results ~= _child;
										}
									}
									else
									{
										CASTnode[] enumResult = getAnonymousEnumMemberFromWord( _child, lowerCase( word ) );
										if( enumResult.length ) results ~= enumResult;
									}
								}
							}
						}
					}
					else
					{
						if( child.name.length )
						{
							if( Util.index( lowerCase( child.name ), lowerCase( word ) ) == 0 )
							{
								results ~= child;
							}
						}
						else
						{
							CASTnode[] enumResult = getAnonymousEnumMemberFromWord( child, lowerCase( word ) );
							if( enumResult.length ) results ~= enumResult;
						}
					}
				}
			}
		}

		return results;
	}

	static char[] removeArrayAndPointerWord( char[] word )
	{
		char[] result;

		foreach( char c; word )
		{
			if( c == '(' || c == '*' ) break; else result ~= c;
		}

		return result;
	}

	static bool isDefaultType( char[] _type )
	{
		_type = lowerCase( _type );
		
		if( _type == "byte" || _type == "ubyte" || _type == "short" || _type == "ushort" || _type == "integer" || _type == "uinteger" || _type == "longint" || _type == "ulongint" ||
			_type == "single" || _type == "double" || _type == "string" || _type == "zstring" || _type == "wstring" ) return true;

		return false;
	}

	static CASTnode searchMatchMemberNode( CASTnode originalNode, char[] word, int B_KIND = B_ALL )
	{
		foreach( CASTnode _node; getMembers( originalNode ) )
		{
			if( _node.kind & B_KIND )
			{
				if( lowerCase( removeArrayAndPointerWord( _node.name ) ) == lowerCase( word ) ) return _node;
			}
		}

		return null;
	}

	static CASTnode[] searchMatchMemberNodes( CASTnode originalNode, char[] word, int B_KIND = B_ALL, bool bWholeWord = true )
	{
		CASTnode[] results;
		
		foreach( CASTnode _node; getMembers( originalNode ) )
		{
			if( _node.kind & B_KIND )
			{
				char[] name = lowerCase( removeArrayAndPointerWord( _node.name ) );

				if( bWholeWord )
				{
					if( name == lowerCase( word ) ) results ~= _node;
				}
				else
				{
					if( Util.index( name, lowerCase( word ) ) == 0 ) results ~= _node;
				}
			}
		}

		return results;
	}
	

	static CASTnode searchMatchNode( CASTnode originalNode, char[] word, int B_KIND = B_ALL )
	{
		CASTnode resultNode = searchMatchMemberNode( originalNode, word, B_KIND );

		if( resultNode is null )
		{
			if( originalNode.getFather() !is null )
			{
				resultNode = searchMatchNode( originalNode.getFather(), word, B_KIND );
			}
			else
			{
				auto cSci = actionManager.ScintillaAction.getActiveCScintilla();

				//CASTnode[] resultIncludeNodes = getMatchIncludesFromWord( GLOBAL.parserManager[upperCase(cSci.getFullPath)], cSci.getFullPath, word );
				if( upperCase(cSci.getFullPath) in GLOBAL.parserManager ) 
				{
					CASTnode[] resultIncludeNodes = getMatchIncludesFromWholeWord( GLOBAL.parserManager[upperCase(cSci.getFullPath)], cSci.getFullPath, word, B_KIND );
					if( resultIncludeNodes.length )	resultNode = resultIncludeNodes[0];
				}
			}
		}

		return resultNode;
	}
	
	static CASTnode[] searchMatchNodes( CASTnode originalNode, char[] word, int B_KIND = B_ALL )
	{
		CASTnode[] resultNodes = searchMatchMemberNodes( originalNode, word, B_KIND, true );

		//if( !resultNodes.length )
		//{
			if( originalNode.getFather() !is null )
			{
				resultNodes = searchMatchNodes( originalNode.getFather(), word, B_KIND );
			}
			else
			{
				auto cSci = actionManager.ScintillaAction.getActiveCScintilla();

				//CASTnode[] resultIncludeNodes = getMatchIncludesFromWord( GLOBAL.parserManager[upperCase(cSci.getFullPath)], cSci.getFullPath, word );
				if( upperCase(cSci.getFullPath) in GLOBAL.parserManager ) 
				{
					CASTnode[] resultIncludeNodes = getMatchIncludesFromWholeWord( GLOBAL.parserManager[upperCase(cSci.getFullPath)], cSci.getFullPath, word, B_KIND );
					if( resultIncludeNodes.length )	resultNodes ~= resultIncludeNodes;
				}
			}
		//}
		
		return resultNodes;
	}

	static CASTnode[] getMembers( CASTnode AST_Head )
	{
		CASTnode[] result;

		foreach( CASTnode _child; AST_Head.getChildren() ~ getBaseNodeMembers( AST_Head ) )
		{
			if( _child.kind & ( B_UNION | B_TYPE | B_CLASS ) )
			{
				if( !_child.name.length ) result ~= getMembers( _child );else result ~= _child;
			}
			else
			{
				result ~= _child;
			}
		}

		return result;
	}

	static CASTnode getType( CASTnode originalNode )
	{
		CASTnode resultNode;

		if( originalNode.type.length >= 4 )
		{
			if( originalNode.type[0..4] == "Var(" )
			{
				char[] varTypeName = removeArrayAndPointerWord( originalNode.type[4..length-1] );

				CASTnode varNode = searchMatchNode( originalNode, varTypeName, B_FUNCTION | B_PROPERTY  );
				if( varNode !is null )
				{
					varTypeName = removeArrayAndPointerWord( varNode.type );
					return searchMatchNode( originalNode, varTypeName, B_TYPE | B_CLASS | B_ENUM | B_UNION );					
				}
				/+
				CASTnode[] varNodes = AutoComplete.getMatchASTfromWholeWord( originalNode, varTypeName, originalNode.lineNumber, B_FUNCTION | B_SUB | B_PROPERTY | B_TYPE | B_CLASS | B_UNION | B_NAMESPACE );
				if( !varNodes.length )
				{
					auto cSci = actionManager.ScintillaAction.getActiveCScintilla();
					if( cSci !is null )	varNodes = getMatchIncludesFromWholeWord( GLOBAL.parserManager[upperCase(cSci.getFullPath)], cSci.getFullPath, varTypeName, B_FUNCTION | B_SUB | B_PROPERTY | B_TYPE | B_CLASS | B_UNION | B_NAMESPACE );
				}
;
				if( varNodes.length )
				{
					varTypeName = removeArrayAndPointerWord( varNodes[0].type );
					resultNode = searchMatchNode( originalNode, varTypeName, B_TYPE | B_CLASS | B_ENUM | B_UNION );
					return resultNode;
				}
				+/
			}
		}

		switch( originalNode.kind )
		{
			case B_VARIABLE, B_PARAM:
				int countLoop = -1;
				foreach( char[] s; Util.split( originalNode.type, "." ) )
				{
					if( s.length )
					{
						char[] _type = removeArrayAndPointerWord( s );
						
						if( ++countLoop == 0 )
						{
							if( isDefaultType( _type ) ) return null;

							resultNode = searchMatchNode( originalNode, _type, B_TYPE | B_CLASS | B_ENUM | B_UNION );
							
							if( resultNode is null )
							{
								resultNode = searchMatchNode( originalNode, _type, B_ALIAS );
								if( resultNode !is null ) resultNode = searchMatchNode( originalNode, resultNode.type, B_TYPE | B_CLASS | B_ENUM | B_UNION );
							}
						}
						else
						{
							if( !stepByStep( resultNode, _type, B_VARIABLE | B_FUNCTION | B_PROPERTY | B_TYPE | B_ENUM | B_UNION | B_CLASS | B_ALIAS ) ) return null;
						}
					}
				}
				break;

			case B_FUNCTION:
				char[] _ReturnType = removeArrayAndPointerWord( originalNode.type );
				resultNode = searchMatchNode( originalNode, _ReturnType, B_TYPE | B_CLASS | B_ENUM | B_UNION );
				break;

			default:
		}
		
		return resultNode;
	}

	static bool stepByStep( ref CASTnode AST_Head, char[] word, int B_KIND )
	{
		AST_Head = searchMatchMemberNode( AST_Head, word, B_KIND );
		if( AST_Head is null ) return false;

		if( AST_Head.kind & ( B_VARIABLE | B_PARAM | B_FUNCTION ) )
		{
			AST_Head = getType( AST_Head );
			if( AST_Head is null ) return false;
		}	

		return true;
	}
	
	static char[] callTipList( CASTnode[] groupAST, char[] word = null )
	{
		char[][] results;
		
		for( int i = 0; i < groupAST.length; ++ i )
		{
			if( i > 0 )
			{
				if( groupAST[i].name == groupAST[i-1].name && groupAST[i].type == groupAST[i-1].type ) continue;
			}
			
			if( groupAST[i].kind & ( B_FUNCTION | B_SUB | B_PROPERTY ) )
			{
				if( ( !word.length ) || lowerCase( groupAST[i].name ) == lowerCase( word ) )
				{
					char[] _type, _paramString	= "()";
					getTypeAndParameter( groupAST[i], _type, _paramString );

					if( _type.length )
						results ~= ( _type ~ " " ~ groupAST[i].name ~ _paramString ~ "\n" );
					else
						results ~= ( "void " ~ groupAST[i].name ~ _paramString ~ "\n" );
				}
			}
			else if( groupAST[i].kind & ( B_TYPE | B_CLASS| B_UNION ) )
			{
				if( ( !word.length ) || lowerCase( groupAST[i].name ) == lowerCase( word ) )
				{
					foreach( CASTnode _child; groupAST[i].getChildren() )
					{
						if( _child.kind & B_CTOR )
						{
							results ~= ( "Constructor" ~ _child.type ~ "\n" );
						}
					}
				}
			}
		}

		results.sort;
		
		char[] result;
		for( int i = 0; i < results.length; i ++ )
		{
			if( i > 0 )
			{
				if( results[i] != results[i-1] ) result ~= results[i];
			}
			else
				result ~= results[i];

		}

		return result;
	}

	static void keyWordlist( char[] word )
	{
		foreach( IupString _s; GLOBAL.KEYWORDS )
		{
			foreach( char[] s; Util.split( _s.toDString, " " ) )
			{
				if( s.length )
				{
					if( Util.index( lowerCase( s ), lowerCase( word ) ) == 0 )
					{
						s = tools.convertKeyWordCase( GLOBAL.keywordCase, s );
						listContainer ~= ( s ~ "?21" );
					}
				}
			}
		}
	}

	static char[][] getDivideWord( char[] word )
	{
		char[][]	splitWord;
		char[]		tempWord;

		//IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( word ) );
		for( int i = 0; i < word.length ; ++ i )
		{
			if( word[i] == '.' )
			{
				splitWord ~= tempWord;
				tempWord = "";
			}
			else if( word[i] == '-' )
			{
				if( i < word.length - 1 )
				{
					if( word[i+1] == '>' )
					{
						splitWord ~= tempWord;
						tempWord = "";
						i ++;
					}
					else
					{
						tempWord ~= word[i];
					}
				}
				else
				{
					tempWord ~= word[i];
				}
			}
			else
			{
				tempWord ~= word[i];
			}
		}

		splitWord ~= tempWord;

		/*
		foreach( char[] s; splitWord )
		{
			IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( s ) );
		}
		IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( "\n" ) );
		*/

		return splitWord;
	}


	public:
	static bool bEnter;
	static bool bAutocompletionPressEnter;


	static CASTnode[] getIncludes( CASTnode originalNode, char[] originalFullPath, bool bRootCall = false )
	{
		if( originalNode is null ) return null;
		
		static int	level;

		CASTnode[] results;

		if( !bRootCall )
		{
			level ++;
			if( level >= GLOBAL.includeLevel )
			{
				//Stdout( "Level:" ~ Integer.toString( level )  ~ "  " ~ originalNode.name ).newline;
				level--;
				return null;
			}
		}
		else
		{
			level = 0;
		}

		foreach( CASTnode _node; originalNode.getChildren )
		{
			if( _node.kind & B_INCLUDE )
			{
				if( _node.type == "__FB_WIN32__" )
				{
					version(Windows)
					{
						//Stdout( "Include(Win32): " ~ _node.name ).newline;
						CASTnode[] _results = check( _node.name, originalFullPath );
						if( _results.length ) results ~= _results;
					}
				}
				else if( _node.type == "__FB_LINUX__" || _node.type == "__FB_UNIX__" )
				{
					version(linux)
					{
						CASTnode[] _results = check( _node.name, originalFullPath );
						if( _results.length ) results ~= _results;
					}
				}
				else if( _node.type == "!__FB_WIN32__" )
				{
					version(Windows){}
					else
					{
						CASTnode[] _results = check( _node.name, originalFullPath );
						if( _results.length ) results ~= _results;
					}
				}
				else if( _node.type == "!__FB_LINUX__" || _node.type == "!__FB_UNIX__" )
				{
					version(linux){}
					else
					{
						CASTnode[] _results = check( _node.name, originalFullPath );
						if( _results.length ) results ~= _results;
					}
				}
				else
				{
					CASTnode[] _result = check( _node.name, originalFullPath );
					if( _result.length ) results ~= _result;
				}
			}
		}

		//Stdout( "Level:" ~ Integer.toString( level )  ~ "  " ~ originalNode.name ).newline;

		if( level > 0 ) level--;

		return results;
	}
	
	static char[] includeComplete( Ihandle* iupSci, int pos, inout char[] text )
	{
		// Nested Delegate Filter Function
		bool dirFilter( FilePath _fp, bool _isFfolder )
		{
			if( _isFfolder ) return true;
			if( lowerCase( _fp.ext ) == "bas" || lowerCase( _fp.ext ) == "bi" ) return true;
		
			return false;
		}
		
		bool delegate( FilePath, bool ) _dirFilter;
		_dirFilter = &dirFilter;
		// End of Nested Function
		
		if( !text.length )  return null;
		
		dchar[] word32;
		char[]	word = text;
		bool	bExitLoopFlag;		
		
		if( text != "\\" && text != "/" && ( fromStringz( IupGetAttribute( iupSci, "AUTOCACTIVE\0" ) ) == "YES" ) ) return null;

		listContainer.length = 0;
		if( fromStringz( IupGetAttribute( iupSci, "AUTOCACTIVE" ) ) == "YES" ) IupSetAttribute( iupSci, "AUTOCCANCEL", "YES" );		

		try
		{
			while( pos > -1 )
			{
				--pos;
				if( pos < 0 ) break;
				
				char[] _s = fromStringz( IupGetAttributeId( iupSci, "CHAR", pos ) );
				if( _s.length )
				{
					dchar[] sd = UTF.toString32( _s );
					dchar s = sd[0];
					switch( s )
					{
						case '"':								bExitLoopFlag = true; break;
						case ' ', '\t', ':', '\n', '\r':		bExitLoopFlag = true; break;
						default: 
							if( UTF.isValid( s ) )
							{
								word32 = "";
								word32 ~= s;
								word ~= Util.trim( UTF.toString( word32 ) );
							}
					}
				}
				
				if( bExitLoopFlag ) break;
			}
			
			if( !word.length ) return null;
			
			version(Windows) word = word.dup.reverse; else word = lowerCase( word.dup.reverse );
			//if( word.length < GLOBAL.autoCompletionTriggerWordCount ) return null;
			
			char[][]	words = Util.split( Path.normalize( word ), "/" );
			char[][]	tempList;

			if( !words.length ) return null;

			// Step 1: Relative from the directory of the source file
			FilePath  _path1 = new FilePath( ScintillaAction.getActiveCScintilla.getFullPath ); // Tail include /
			_path1.set( _path1.path );
			
			// Step 2: Relative from the current working directory
			FilePath  _path2;
			char[] prjDir = actionManager.ProjectAction.fileInProject( ScintillaAction.getActiveCScintilla.getFullPath );
			if( prjDir.length )
				_path2 = new FilePath( prjDir ~ "/" );
			else
				_path2 = new FilePath( Environment.cwd() ); // Tail include /

			// Step 3: Relative from addition directories specified with the -i command line option
			// Work on Project
			FilePath[]  _path3;
			prjDir = actionManager.ProjectAction.fileInProject( ScintillaAction.getActiveCScintilla.getFullPath );
			if( prjDir.length )
			{
				foreach( char[] s; GLOBAL.projectManager[prjDir].includeDirs ) // without \
					_path3 ~= new FilePath( s ); // Reset
			}			
			
			// Step 4(Final): The include folder of the FreeBASIC installation (FreeBASIC\inc, where FreeBASIC is the folder where the fbc executable is located)
			char[] testPath;
			FilePath _path4 = new FilePath( Path.normalize( GLOBAL.compilerFullPath.toDString ) );
			version( Windows )
			{
				testPath = _path4.path() ~ "inc/";
			}
			else
			{
				testPath = _path4.path();
				int _pos = Util.rindex( testPath, "/bin/" );
				if( _pos > 0 && _pos < testPath.length )
				{
					testPath = testPath[0.._pos] ~ "/include/freebasic/";
				}
			}
			_path4.set( testPath ); // Reset			
			
			int index;
			for( int i = 0; i < words.length; ++ i )
			{
				if( i == words.length - 1 )
				{
					// Step 1: Relative from the directory of the source file
					if( _path1.exists )
					{
						foreach( FilePath _fp; _path1.toList( _dirFilter ) )
							tempList ~= _fp.file;
					}
					
					// Step 2: Relative from the current working directory
					if( _path2.exists )
					{
						foreach( FilePath _fp; _path2.toList( _dirFilter ) )
							tempList ~= _fp.file;
					}
					
					// Step 3: Relative from addition directories specified with the -i command line option
					// Work on Project
					foreach( FilePath _fp3; _path3 )
					{
						if( _fp3.exists )
						{
							foreach( FilePath _fp; _fp3.toList( _dirFilter ) )
								tempList ~= _fp.file;
						}
					}
					
					// Step 4(Final): The include folder of the FreeBASIC installation (FreeBASIC\inc, where FreeBASIC is the folder where the fbc executable is located)
					if( _path4.exists )
					{
						foreach( FilePath _fp; _path4.toList( _dirFilter ) )
							tempList ~= _fp.file;
					}
				}
				else
				{
					_path1 = _path1.set( _path1.toString ~ words[i] ~ "/" );
					_path2 = _path2.set( _path2.toString ~ words[i] ~ "/" );
					for( int j = 0; j < _path3.length; ++ j )
						_path3[j] = _path3[j].set( _path3[j].toString ~ words[i] ~ "/" );
					_path4 = _path4.set( _path4.toString ~ words[i] ~ "/" );
				}
			}
			
			
			if( word == "\"" ) words[$-1] = "";
			foreach( char[] s; tempList )
			{
				if( s.length )
				{
					char[] iconNum = "37";
					
					if( s.length > 4 )
					{
						if( lowerCase( s[$-4..$] ) == ".bas" ) iconNum = "35";
					}
					
					if( s.length > 3 )
					{
						if( lowerCase( s[$-3..$] ) == ".bi" ) iconNum = "36";
					}
					
					if( !words[$-1].length )
					{
						listContainer ~= ( s ~ "?" ~ iconNum );
					}
					else
					{
						if( Util.index( lowerCase( s ), lowerCase( words[$-1] ) ) == 0 ) listContainer ~= ( s ~ "?" ~ iconNum );
					}
				}
			}
			
			text = words[$-1];
			listContainer.sort;
			
			char[] list;
			for( int i = 0; i < listContainer.length; ++ i )
			{
				if( listContainer[i].length )
				{
					if( i > 0 )
					{
						if( listContainer[i] != listContainer[i-1] ) list ~= ( listContainer[i] ~ "^" );
					}
					else
					{
						list ~= ( listContainer[i] ~ "^" );
					}
				}
			}			
			
			if( list.length )
				if( list[length-1] == '^' ) list = list[0..length-1];
				
			// Release FilePath Class Objects
			delete _path1;
			delete _path2;
			delete _path4;
			foreach( FilePath _p; _path3 )
				delete _p;
			
			return list;
			
		}
		catch( Exception e )
		{
			IupMessage( "includeComplete Error", toStringz( e.toString ) );
		}
		
		return null;
	}
	
	static int getProcedurePos( Ihandle* iupSci, int pos, char[] targetText )
	{
		/*
		SCI_SETTARGETSTART = 2190,
		SCI_GETTARGETSTART = 2191,
		SCI_SETTARGETEND = 2192,
		SCI_GETTARGETEND = 2193,
		SCI_SEARCHINTARGET = 2197,
		SCI_SETSEARCHFLAGS = 2198,
		SCFIND_WHOLEWORD = 2,
		SCFIND_MATCHCASE = 4,

		SCFIND_WHOLEWORD = 2,
		SCFIND_MATCHCASE = 4,
		SCFIND_WORDSTART = 0x00100000,
		SCFIND_REGEXP = 0x00200000,
		SCFIND_POSIX = 0x00400000,
		*/		
		int documentLength = cast(int) IupScintillaSendMessage( iupSci, 2006, 0, 0 );		// SCI_GETLENGTH = 2006,
		IupScintillaSendMessage( iupSci, 2198, 2, 0 );							// SCI_SETSEARCHFLAGS = 2198,
		IupScintillaSendMessage( iupSci, 2190, pos, 0 ); 						// SCI_SETTARGETSTART = 2190,
		IupScintillaSendMessage( iupSci, 2192, 0, 0 );							// SCI_SETTARGETEND = 2192,

		int posHead = cast(int) IupScintillaSendMessage( iupSci, 2197, targetText.length, cast(int) GLOBAL.cString.convert( targetText ) );

		while( posHead >= 0 )
		{
			int style = cast(int) IupScintillaSendMessage( iupSci, 2010, posHead, 0 ); // SCI_GETSTYLEAT 2010
			if( style == 1 || style == 19 || style == 4 )
			{
				IupScintillaSendMessage( iupSci, 2190, posHead - 1, 0 );				// SCI_SETTARGETSTART = 2190,
				IupScintillaSendMessage( iupSci, 2192, 0, 0 );							// SCI_SETTARGETEND = 2192,
				posHead = cast(int) IupScintillaSendMessage( iupSci, 2197, targetText.length, cast(int) GLOBAL.cString.convert( targetText ) );
			}
			else
			{
				bool bReSearch;
				
				// check if Type (Alias) or Temporary Types
				if( lowerCase( targetText ) == "type" )
				{
					char[]	afterWord;
					bool	bFirstChar = true;
					int		count;
					
					for( int i = posHead + targetText.length; i < documentLength; ++ i )
					{
						char[] _s = lowerCase( fromStringz( IupGetAttributeId( iupSci, "CHAR", i ) ) );

						if( _s[0] == 13 || _s == ":" || _s == "\n" )
						{
							break;
						}
						else if( _s == " " || _s == "\t" )
						{
							if( !bFirstChar )
							{
								count ++;
								
								if( count == 2 && lowerCase( afterWord ) == "as" )
								{
									bReSearch = true;
									break;	
								}
								else
								{
									afterWord = "";
								}
							}
						}
						else
						{
							if( bFirstChar )
							{
								if( _s == "(" || _s == "<" )
								{
									bReSearch = true;
									break;
								}
								else
								{
									bFirstChar = false;
									afterWord ~= _s;
								}
							}
							else
							{
								afterWord ~= _s;
							}
						}
					}
				}


				if( !bReSearch )
				{
					// Check after "sub""function"...etc have word, like "end sub" or "exit function", Research 
					for( int i = posHead + targetText.length; i < documentLength; ++ i )
					{
						char[] s = lowerCase( fromStringz( IupGetAttributeId( iupSci, "CHAR", i ) ) );

						if( s[0] == 13 || s == ":" || s == "\n" || s == "=" )
						{
							bReSearch = true;
							break;
						}
						else if( s != " " && s != "\t" )
						{
							// Check before targetText word.......
							char[]	beforeWord;
							for( int j = posHead - 1; j >= 0; --j )
							{
								char[] _s = lowerCase( fromStringz( IupGetAttributeId( iupSci, "CHAR", j ) ) );
								
								if( _s[0] == 13 || _s == ":" || _s == "\n" )
								{
									break;
								}
								else if( _s == " " || _s == "\t" )
								{
									if( beforeWord.length ) break;
								}
								else
								{
									beforeWord ~= _s;
								}
							}
							
							if( beforeWord == "eralced" || beforeWord == "dne" || beforeWord == "=" ) bReSearch = true; else bReSearch = false;
							break;
						}
					}
				}

				if( bReSearch )
				{
					IupScintillaSendMessage( iupSci, 2190, --posHead, 0 );
					IupScintillaSendMessage( iupSci, 2192, 0, 0 );							// SCI_SETTARGETEND = 2192,
					posHead = cast(int) IupScintillaSendMessage( iupSci, 2197, targetText.length, cast(int) GLOBAL.cString.convert( targetText ) );
				}
				else
				{
					break;
				}
			}
		}
		
		return posHead;
	}

	// direct = 0 findprev, direct = 1 findnext
	static int getProcedureTailPos( Ihandle* iupSci, int pos, char[] targetText, int direct )
	{
		int		documentLength = IupGetInt( iupSci, "COUNT" );
		int		posEnd = skipCommentAndString( iupSci, pos, "end", direct );

		while( posEnd > 0 )
		{
			pos = posEnd; // Put vrigin posEnd to pos
			posEnd += 3;
			
			char[] 	_char = fromStringz( IupGetAttributeId( iupSci, "CHAR", posEnd ) );
			char[]	endText;
			while( _char != "\n" && _char != ":" )
			{
				endText ~= _char;
				posEnd ++;
				if( posEnd >= documentLength ) break; else _char = fromStringz( IupGetAttributeId( iupSci, "CHAR", posEnd ) );
			}
			endText = Util.trim( endText );

			if( lowerCase( endText ) == lowerCase( targetText ) )
			{
				return posEnd;
			}
			else
			{
				if( direct == 0 )
					posEnd = skipCommentAndString( iupSci, --pos, "end", 0 );
				else 
					posEnd = skipCommentAndString( iupSci, posEnd, "end", 1 );
			}	
		}

		return -1;
	}	

	// direct = 0 findprev, direct = 1 findnext
	static int skipCommentAndString(  Ihandle* iupSci, int pos, char[] targetText, int direct )
	{
		IupScintillaSendMessage( iupSci, 2198, 2, 0 );							// SCI_SETSEARCHFLAGS = 2198,
		int documentLength = cast(int) IupScintillaSendMessage( iupSci, 2006, 0, 0 );		// SCI_GETLENGTH = 2006,

		if( direct == 0 )
		{
			IupScintillaSendMessage( iupSci, 2190, pos, 0 );
			IupScintillaSendMessage( iupSci, 2192, 0, 0 );							// SCI_SETTARGETEND = 2192,
		}
		else
		{
			IupScintillaSendMessage( iupSci, 2190, pos, 0 );
			IupScintillaSendMessage( iupSci, 2192, documentLength - 1, 0 );			// SCI_SETTARGETEND = 2192,
		}
		pos = cast(int) IupScintillaSendMessage( iupSci, 2197, targetText.length, cast(int) GLOBAL.cString.convert( targetText ) );
		
		while( pos > -1 )
		{
			int style = cast(int) IupScintillaSendMessage( iupSci, 2010, pos, 0 ); // SCI_GETSTYLEAT 2010
			if( style == 1 || style == 19 || style == 4 )
			{
				if( direct == 0 )
				{
					IupScintillaSendMessage( iupSci, 2190, pos - 1, 0 );
					IupScintillaSendMessage( iupSci, 2192, 0, 0 );							// SCI_SETTARGETEND = 2192,
					pos = cast(int) IupScintillaSendMessage( iupSci, 2197, targetText.length, cast(int) GLOBAL.cString.convert( targetText ) );
				}
				else
				{
					IupScintillaSendMessage( iupSci, 2190, pos + targetText.length, 0 );
					IupScintillaSendMessage( iupSci, 2192, documentLength - 1, 0 );							// SCI_SETTARGETEND = 2192,
					pos = cast(int) IupScintillaSendMessage( iupSci, 2197, targetText.length, cast(int) GLOBAL.cString.convert( targetText ) );
				}
			}
			else
			{
				return pos;
			}
		}

		return pos;
	}	

	static char[] getWholeWordDoubleSide( Ihandle* iupSci, int pos = -1 )
	{
		int		countParen, countBracket;
		int		oriPos = pos;
		bool	bForntEnd, bBackEnd;
		int		documentLength = IupGetInt( iupSci, "COUNT" );

		do
		{
			if( !actionManager.ScintillaAction.isComment( iupSci, pos ) )
			{
				char[] s = fromStringz( IupGetAttributeId( iupSci, "CHAR", pos ) );

				switch( s )
				{
					case "(":
						if( countBracket == 0 ) countParen ++;
						break;

					case ")":
						if( countBracket == 0 ) countParen --;
						if( countParen < 0 ) bBackEnd = true;
						break;

					case "[":
						if( countParen == 0 ) countBracket ++;
						break;

					case "]":
						if( countParen == 0 ) countBracket --;
						if( countBracket < 0 ) bBackEnd = true;
						break;

					case ".":
						if( countParen == 0 && countBracket == 0 ) bBackEnd = true;
						break;
					
					case "-":
						if( pos < documentLength )
						{
							if( fromStringz( IupGetAttributeId( iupSci, "CHAR", pos + 1 ) ) == ">" )
							{
								if( countParen == 0 && countBracket == 0 )
								{
									bBackEnd = true;
								}
								else
								{
									pos++;
								}
								break;
							}
						}
						
					case " ", "\t", ":", "\n", "\r", "+", "*", "/", "\\", ">", "<", "=", ",", "@":
						if( countParen == 0 && countBracket == 0 ) bBackEnd = true;
						break;

					default:
				}
			}
			
			if( pos >= documentLength ) break;
			if( bBackEnd ) break;
		}
		while( ++pos < documentLength )

		if( oriPos == pos ) return null;

		int dummyHeadPos;
		return getWholeWordReverse( iupSci, pos, dummyHeadPos );
	}

	static bool checkIscludeDeclare( Ihandle* iupSci, int pos = -1 )
	{
		char[]	result;
		dchar[]	resultd;
		
		int		documentLength = IupGetInt( iupSci, "COUNT" );

		try
		{
			version(Winodws)
			{
				while( --pos >= 0 )
				{
					dchar[] _dcharString = fromString32z( cast(dchar*) IupGetAttributeId( iupSci, "CHAR", pos ) );
					if( _dcharString == ":" || _dcharString == "\n" ) break;
					resultd ~= _dcharString;
				}

				resultd = Util.trim!(dchar)( resultd.reverse ).dup;
				if( resultd.length > 7 )
				{
					result = lowerCase( UTF.toString( resultd ) );
					if( result[0..8] == "#include" ) return true;
				}
			}
			else
			{
				while( --pos >= 0 )
				{
					char[] s = fromStringz( IupGetAttributeId( iupSci, "CHAR", pos ) );
					if( s == ":" || s == "\n" ) break;
					result ~= s;
				}
				
				result = lowerCase( Util.trim( result.reverse ) ).dup;
				if( result.length > 7 )
				{
					if( result[0..8] == "#include" ) return true;
				}
			}
		}
		catch( Exception e )
		{
			GLOBAL.IDEMessageDlg.print( "checkIscludeDeclare() Error:\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ Integer.toString( e.line ) );
			//debug IupMessage( "AutoComplete.checkIscludeDeclare() Error", toStringz( e.toString ) );
		}

		return false;
	}

	static char[] getIncludeString( Ihandle* iupSci, int pos = -1 )
	{
		if( !checkIscludeDeclare( iupSci, pos ) ) return null;
		
		char[]	result;
		int		documentLength = IupGetInt( iupSci, "COUNT" );
		
		do
		{
			char[] s = fromStringz( IupGetAttributeId( iupSci, "CHAR", pos ) );
			if( s == "\"" || s == "\n" ) break;
		}
		while( ++pos < documentLength )
		--pos;

		do
		{
			char[] s = fromStringz( IupGetAttributeId( iupSci, "CHAR", pos ) );
			if( s == "\"" || s == "\n" ) break;
			result ~= s;
		}
		while( --pos >= 0 )
		 
		return result.dup.reverse;
	}	

	static char[] getWholeWordReverse( Ihandle* iupSci, int pos, out int headPos )
	{
		dchar[] word32;
		char[]	word;
		int		countParen, countBracket;

		try
		{
			while( pos > -1 )
			{
				--pos;
				headPos = pos;
				if( pos < 0 ) break;
				
				if( !actionManager.ScintillaAction.isComment( iupSci, pos ) )
				{
					dchar[] _dcharString = fromString32z( cast(dchar*) IupGetAttributeId( iupSci, "CHAR", pos ) );
					if( _dcharString.length )
					{
						switch( _dcharString )
						{
							case ")":
								if( countBracket == 0 ) countParen++;
								break;

							case "(":
								if( countBracket == 0 ) countParen--;
								if( countParen < 0 ) return UTF.toString( word32 );
								break;
								
							case "]":
								if( countParen == 0 ) countBracket++;
								break;

							case "[":
								if( countParen == 0 ) countBracket--;
								if( countBracket < 0 ) return UTF.toString( word32 );
								break;
								
							case ">":
								if( pos > 0 && countParen == 0 && countBracket == 0 )
								{
									if( fromStringz( IupGetAttributeId( iupSci, "CHAR", pos - 1 ) ) == "-" )
									{
										word32 ~= ">-";
										pos--;
										break;
									}
								}
							case " ", "\t", ":", "\n", "\r", "+", "-", "*", "/", "\\", "<", "=", ",", "@":
								if( countParen == 0 && countBracket == 0 ) return UTF.toString( word32 );
								
							default: 
								if( countParen == 0 && countBracket == 0 )
								{
									word32 ~= _dcharString;
								}
						}
					}
					/+
					//dchar s = IupScintillaSendMessage( iupSci, 2007, pos, 0 );//SCI_GETCHARAT = 2007,
					char[] _s = fromStringz( IupGetAttributeId( iupSci, "CHAR", pos ) );
					if( _s.length )
					{
						dchar[] sd = UTF.toString32( _s );
						dchar s = sd[0];
						switch( s )
						{
							case ')':
								if( countBracket == 0 ) countParen++;
								break;

							case '(':
								if( countBracket == 0 ) countParen--;
								if( countParen < 0 ) return word;
								break;
								
							case ']':
								if( countParen == 0 ) countBracket++;
								break;

							case '[':
								if( countParen == 0 ) countBracket--;
								if( countBracket < 0 ) return word;
								break;
								
							case '>':
								if( pos > 0 && countParen == 0 && countBracket == 0 )
								{
									if( fromStringz( IupGetAttributeId( iupSci, "CHAR", pos - 1 ) ) == "-" )
									{
										word ~= ">-";
										pos--;
										break;
									}
								}
							case ' ', '\t', ':', '\n', '\r', '+', '-', '*', '/', '\\', '<', '=', ',', '@':
								if( countParen == 0 && countBracket == 0 ) return word;
								
							default: 
								if( countParen == 0 && countBracket == 0 )
								{
									if( UTF.isValid( s ) )
									{
										word32 = "";
										word32 ~= s;
										word ~= Util.trim( UTF.toString( word32 ) );
										//word ~= s;
									}
								}
						}
					}
					+/
				}
			}
			
		}
		catch( Exception e )
		{
			GLOBAL.IDEMessageDlg.print( "getWholeWordReverse() Error:\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ Integer.toString( e.line ) );
			//debug IupMessage( "AutoComplete.getWholeWordReverse() Error", toStringz( e.toString ) );
			return null;
		}

		return UTF.toString( word32 );
		//return word;
	}
	
	static char[] charAdd( Ihandle* iupSci, int pos, char[] text )
	{
		int		dummyHeadPos;
		char[] 	word, result;
		bool	bDot, bCallTip;

		if( text == "(" )
		{
			bCallTip = true;
			IupSetAttribute( iupSci, "AUTOCCANCEL\0", "YES\0" ); // Prevent autocomplete -> calltip issue
		}
		else if( text == "." )
		{
			bDot = true;
		}
		else if( text == ">" )
		{
			if( pos > 0 )
			{
				if( fromStringz( IupGetAttributeId( iupSci, "CHAR", pos - 1 ) ) == "-" )
				{
					bDot = true;
				}
				else
				{
					word = text;
				}
			}
			else
			{
				word = text;
			}
		}
		else
		{
			word = text;
		}

		if( text == ">" && bDot )
		{
			word = word ~ getWholeWordReverse( iupSci, pos - 1, dummyHeadPos );
		}
		else
		{
			word = word ~ getWholeWordReverse( iupSci, pos, dummyHeadPos );
		}

		/+
		// Check first dot '.' at With Block
		if( !word.length && bDot )
		{
			if( checkWithBlock( iupSci, pos ) )
			{
				char[] withTitle = searchHead( iupSci, pos, "with" );
				if( withTitle.length ) word = word ~ withTitle.reverse;
			}
		}
		if( !bDot && !bCallTip )
		{
			if( word.length < GLOBAL.autoCompletionTriggerWordCount ) return null;
		}
		+/

		word = lowerCase( word.dup.reverse );

		auto cSci = actionManager.ScintillaAction.getActiveCScintilla();
		if( cSci !is null )
		{
			if( upperCase(cSci.getFullPath) in GLOBAL.parserManager )
			{
				if( GLOBAL.parserManager[upperCase(cSci.getFullPath)] is null ) return null;
			}
			else
			{
				return null;
			}
			
			if( !bDot && ( fromStringz( IupGetAttribute( iupSci, "AUTOCACTIVE\0" ) ) == "YES" ) )
			{}
			else
			{
				// Clean listContainer
				listContainer.length = 0;
				
				if( fromStringz( IupGetAttribute( iupSci, "AUTOCACTIVE\0" ) ) == "YES" ) IupSetAttribute( iupSci, "AUTOCCANCEL\0", "YES\0" );

				// Divide word
				/*char[][] splitWord = Util.split( word, "." );
				if( splitWord.length == 1 ) splitWord = Util.split( word, "->" );*/
				char[][]	splitWord = getDivideWord( word );
				int			lineNum = cast(int) IupScintillaSendMessage( iupSci, 2166, pos, 0 ) + 1; //SCI_LINEFROMPOSITION = 2166,
				CASTnode	AST_Head = actionManager.ParserAction.getActiveASTFromLine( GLOBAL.parserManager[upperCase(cSci.getFullPath)], lineNum );
				char[]		memberFunctionMotherName;


				if( AST_Head is null )
				{
					if( GLOBAL.enableKeywordComplete == "ON" )
					{
						keyWordlist( splitWord[0] );

						if( listContainer.length )
						{
							//listContainer.sort;

							for( int i = 0; i < listContainer.length; ++ i )
							{
								if( listContainer[i].length )
								{
									if( i > 0 )
									{
										if( listContainer[i] != listContainer[i-1] ) result ~= ( listContainer[i] ~ "^" );
									}
									else
									{
										result ~= ( listContainer[i] ~ "^" );
									}
								}
							}


							if( result.length )
								if( result[length-1] == '^' ) result = result[0..length-1];

							return Util.trim( result );
						}
					}

					return null;
				}


				if( !splitWord[0].length )
				{
					if( AST_Head.kind & B_WITH )
					{
						char[][] splitWithTile = getDivideWord( AST_Head.name );
						char[][] tempSplitWord = splitWord;
						splitWord.length = 0;						
						foreach( char[] s; splitWithTile ~ tempSplitWord )
						{
							if( s != "" ) splitWord ~= removeArrayAndPointerWord( s );
						}						
					}
					else
					{
						return null;
					}
				}
				
				// Get memberFunctionMotherName
				auto _fatherNode = AST_Head;
				if( AST_Head.kind & ( B_WITH | B_SCOPE ) )
				{
					do
					{
						if( _fatherNode.getFather !is null ) _fatherNode = _fatherNode.getFather; else break;
					}
					while( _fatherNode.kind & ( B_WITH | B_SCOPE ) )
				}
				
				if( _fatherNode.name.length )
				{
					if( _fatherNode.kind & ( B_CTOR | B_DTOR ) )
					{
						memberFunctionMotherName = _fatherNode.name;
					}
					else
					{
						int dotPos = Util.index( _fatherNode.name, "." );
						if( dotPos < _fatherNode.name.length )
						{
							memberFunctionMotherName = _fatherNode.name[0..dotPos];
						}
					}
				}
				
				cleanIncludesMarkContainer();
				
				for( int i = 0; i < splitWord.length; i++ )
				{
					listContainer.length = 0;
					
					if( i == 0 )
					{
						if( splitWord.length == 1 )
						{
							if( !bDot )
							{
								CASTnode[] resultNodes;
								CASTnode[] resultIncludeNodes;

								if( bCallTip )
								{
									resultNodes			= getMatchASTfromWholeWord( AST_Head, splitWord[i], lineNum, B_FUNCTION | B_SUB | B_PROPERTY | B_TYPE | B_CLASS | B_UNION | B_NAMESPACE );
									resultIncludeNodes	= getMatchIncludesFromWholeWord( GLOBAL.parserManager[upperCase(cSci.getFullPath)], cSci.getFullPath, splitWord[i], B_FUNCTION | B_SUB | B_PROPERTY | B_TYPE | B_CLASS | B_UNION | B_NAMESPACE );

									// For Type Objects
									if( memberFunctionMotherName.length )
									{
										// "_searchMatchNode" also search includes
										CASTnode classNode = _searchMatchNode( AST_Head, memberFunctionMotherName, B_TYPE | B_CLASS );
										if( classNode !is null ) resultNodes ~= searchMatchMemberNodes( classNode, splitWord[i], B_ALL );
									}

									result = callTipList( resultNodes ~ resultIncludeNodes, splitWord[i] );
									return Util.trim( result );
								}


								if( GLOBAL.enableKeywordComplete == "ON" ) keyWordlist( splitWord[i] );
								//IupMessage("",toStringz(AST_Head.name));
								if( AST_Head !is null )
								{
									resultNodes			= getMatchASTfromWord( AST_Head, splitWord[i], lineNum );
									resultIncludeNodes	= getMatchIncludesFromWord( GLOBAL.parserManager[upperCase(cSci.getFullPath)], cSci.getFullPath, splitWord[i] );
									
									//cleanIncludesMarkContainer();
									// For Type Objects
									if( memberFunctionMotherName.length )
									{
										CASTnode classNode = _searchMatchNode( AST_Head, memberFunctionMotherName, B_TYPE | B_CLASS );
										if( classNode !is null ) resultNodes ~= searchMatchMemberNodes( classNode,  splitWord[i] , B_ALL, false );
									}
									foreach( CASTnode _node; resultNodes ~ resultIncludeNodes )
									{
										listContainer ~= getListImage( _node );
										//listContainer ~= _node;
									}
								}
							}
							else
							{
								// Get Members
								AST_Head = searchMatchNode( AST_Head, splitWord[i], B_FIND ); // NOTE!!!! Using "searchMatchNode()"
								if( AST_Head is null )
								{
									// For Type Objects
									if( memberFunctionMotherName.length )
									{
										//AST_Head = GLOBAL.parserManager[upperCase(cSci.getFullPath)];
										CASTnode memberFunctionMotherNode = _searchMatchNode( GLOBAL.parserManager[upperCase(cSci.getFullPath)], memberFunctionMotherName, B_TYPE | B_CLASS );
										if( memberFunctionMotherNode !is null )
										{
											if( lowerCase( splitWord[i] ) == "this" ) AST_Head = memberFunctionMotherNode; else AST_Head = searchMatchNode( memberFunctionMotherNode, splitWord[i], B_FIND );
										}
									}					
								}

								if( AST_Head is null ) return null;

								if( AST_Head.kind & ( B_VARIABLE | B_PARAM | B_FUNCTION ) )
								{
									AST_Head = getType( AST_Head );
									if( AST_Head is null ) return null;
								}

								if( AST_Head.kind & ( B_TYPE | B_ENUM | B_UNION | B_CLASS | B_NAMESPACE ) )
								{
									foreach( CASTnode _child; getMembers( AST_Head ) ) // Get members( include nested unnamed union & type )
									{
										listContainer ~= getListImage( _child );
									}
								}
							}

							break;
						}

						AST_Head = searchMatchNode( AST_Head, splitWord[i], B_FIND ); // NOTE!!!! Using "searchMatchNode()"
						if( AST_Head is null )
						{
							// For Type Objects
							if( memberFunctionMotherName.length )
							{
								CASTnode memberFunctionMotherNode = _searchMatchNode( GLOBAL.parserManager[upperCase(cSci.getFullPath)], memberFunctionMotherName, B_TYPE | B_CLASS );
								if( memberFunctionMotherNode !is null )
								{
									if( lowerCase( splitWord[i] ) == "this" ) AST_Head = memberFunctionMotherNode; else AST_Head = searchMatchNode( memberFunctionMotherNode, splitWord[i], B_FIND );
									//AST_Head = searchMatchNode( memberFunctionMotherNode, splitWord[i], B_FIND );
								}
							}					
						}

						if( AST_Head is null ) return null;

						if( AST_Head.kind & ( B_VARIABLE | B_PARAM | B_FUNCTION ) )
						{
							AST_Head = getType( AST_Head );
							if( AST_Head is null ) return null;
						}
					}
					else if( i == splitWord.length -1 )
					{
						if( !bDot )
						{
							if( bCallTip )
							{
								result = callTipList( AST_Head.getChildren() ~ getBaseNodeMembers( AST_Head ), splitWord[i] );
								return Util.trim( result );
							}

							foreach( CASTnode _child; getMembers( AST_Head ) ) // Get members( include nested unnamed union & type )
							{
								if( Util.index( lowerCase( _child.name ), splitWord[i] ) == 0 ) listContainer ~= getListImage( _child );
							}							
						}
						else
						{
							if( AST_Head.kind & B_NAMESPACE )
							{
								if( !stepByStep( AST_Head, splitWord[i], B_VARIABLE | B_FUNCTION | B_PROPERTY | B_TYPE | B_ENUM | B_UNION ) ) return null;
							}
							else
							{
								if( !stepByStep( AST_Head, splitWord[i], B_VARIABLE | B_FUNCTION | B_PROPERTY ) ) return null;
							}

							foreach( CASTnode _child; getMembers( AST_Head ) ) // Get members( include nested unnamed union & type )
							{
								listContainer ~= getListImage( _child );
							}								
						}
						
					}
					else
					{
						if( AST_Head.kind & B_NAMESPACE )
						{
							if( !stepByStep( AST_Head, splitWord[i], B_VARIABLE | B_FUNCTION | B_PROPERTY | B_TYPE | B_ENUM | B_UNION ) ) return null;
						}
						else
						{
							if( !stepByStep( AST_Head, splitWord[i], B_VARIABLE | B_FUNCTION | B_PROPERTY ) ) return null;
						}
					}
				}

				/+
				scope sortTool = new CNameSort!(CASTnode)( listContainer );
				listContainer = sortTool.dump();
				foreach( CASTnode _node; listContainer )
				{
					if( !( _node.kind & ( B_CTOR | B_DTOR ) ) )	result ~= ( getListImage( _node ) ~ " " );
				}
				+/

				if( listContainer.length )
				{
					//listContainer.sort;

					char[]	_type, _list;
					int		maxLeft, maxRight;

					if( GLOBAL.toggleShowListType == "ON" )
					{
						for( int i = 0; i < listContainer.length; ++ i )
						{
							if( listContainer[i].length )
							{
								int dollarPos = Util.rindex( listContainer[i], "~" );
								if( dollarPos < listContainer[i].length )
								{
									_type = listContainer[i][dollarPos+1..length];
									if( _type.length > maxRight ) maxRight = _type.length;
									_list = listContainer[i][0..dollarPos];
									if( _list.length > maxLeft ) maxLeft = _list.length;
								}
								else
								{
									if( listContainer[i].length > maxLeft ) maxLeft = listContainer[i].length;
								}
							}
						}
					}

					char[] formatString = "{,-" ~ Integer.toString( maxLeft ) ~ "} :: {,-" ~ Integer.toString( maxRight ) ~ "}";
					
					for( int i = 0; i < listContainer.length; ++ i )
					{
						if( i > 0 )
							if( listContainer[i] == listContainer[i-1] ) continue;

						if( listContainer[i].length )
						{
							if( GLOBAL.toggleShowListType == "ON" )
							{
								char[] _string;
								
								int dollarPos = Util.rindex( listContainer[i], "~" );
								if( dollarPos < listContainer[i].length )
								{
									_type = listContainer[i][dollarPos+1..length];
									_list = listContainer[i][0..dollarPos];
									_string = Util.trim( Stdout.layout.convert( formatString, _list, _type ) );
								}
								else
								{
									_string = listContainer[i];
								}

								result ~= ( _string ~ "^" );
								/*
								if( i > 0 )
								{
									if( _string != listContainer[i-1] ) result ~= ( _string ~ "^" );
								}
								else
								{
									result ~= ( _string ~ "^" );
								}
								*/
							}
							else
							{
								result ~= ( listContainer[i] ~ "^" );
								/*
								if( i > 0 )
								{
									if( listContainer[i] != listContainer[i-1] ) result ~= ( listContainer[i] ~ "^" );
								}
								else
								{
									result ~= ( listContainer[i] ~ "^" );
								}
								*/
							}
						}
					}
				}
			}

			if( result.length )
				if( result[length-1] == '^' ) result = result[0..length-1];

			return result.dup;
		}

		return null;
	}

	/*
		TYPE = 0		show type
		TYPE = 1		goto definition
		TYPE = 2		goto member procedure
	*/
	static void toDefintionAndType( int TYPE, int currentPos = -1 )
	{
		if( GLOBAL.enableParser != "ON" ) return;
		
		try
		{
			char[]	word;
			bool	bDwell;
			
			auto cSci = actionManager.ScintillaAction.getActiveCScintilla();
			if( cSci !is null )
			{
				if( upperCase(cSci.getFullPath) in GLOBAL.parserManager ){} else{ return; }
				
				if( currentPos == -1 ) currentPos = actionManager.ScintillaAction.getCurrentPos( cSci.getIupScintilla ); else bDwell = true;
				if( currentPos < 1 ) return;
				
				word = getWholeWordDoubleSide( cSci.getIupScintilla, currentPos );
				word = lowerCase( word.dup.reverse );
				
				char[][] splitWord = getDivideWord( word );
				
				// Manual
				if( splitWord.length == 1 )
				{
					if( GLOBAL.toggleUseManual == "ON" )
					{
						if( TYPE == 0 && !bDwell )
						{
							scope chmPath = new FilePath( GLOBAL.manualPath.toDString );
							if( chmPath.exists() )
							{
								char[]	keyWord = splitWord[0];

								foreach( IupString _s; GLOBAL.KEYWORDS )
								{
									foreach( char[] targetText; Util.split( _s.toDString, " " ) )
									{
										if( keyWord == targetText )
										{
											keyWord = lowerCase( keyWord );
											if ( keyWord[0] >= 'a' && keyWord[0] <= 'z' ) keyWord[0] = cast(char) ( keyWord[0] - 32 );
											
											version(Windows)
											{
												if( GLOBAL.htmlHelp != null )
												{
													wchar[] keyWord16 = UTF.toString16( keyWord );
													wchar[]	_path =  UTF.toString16( GLOBAL.manualPath.toDString );
													
													HH_AKLINK	akLink;
													akLink.cbStruct = HH_AKLINK.sizeof;
													akLink.fReserved = 0;
													akLink.pszKeywords = toString16z( keyWord16 );
													akLink.fIndexOnFail = 0;
													GLOBAL.htmlHelp( null, toString16z( _path ), 0x000D, cast(uint) &akLink ); //#define HH_KEYWORD_LOOKUP       &h000D
												}
												else
												{
													char[]	keyPg;
													
													switch( lowerCase( keyWord ) )
													{
														case "select":			keyPg = "::KeyPgSelectcase.html";			break;
														case "if", "then":		keyPg = "::KeyPgIfthen.html";				break;
														default:				keyPg = "::KeyPg" ~ keyWord ~ ".html";
													}											

													//IupExecute( "hh", toStringz( "\"mk:@MSITStore:" ~ GLOBAL.manualPath.toDString ~ keyPg ~ "\"" ) );
													IupExecute( "hh", toStringz( "\"its:" ~ GLOBAL.manualPath.toDString ~ keyPg ~ "\"" ) );
												}
											}
											else
											{
												IupExecute( "kchmviewer", toStringz( "--stoc " ~ keyWord ~ " /" ~ GLOBAL.manualPath.toDString ) );
												// "kchmviewer --sindex %s /chm-path
											}

											return;
										}
									}
								}
							}
						}
						
						//if( splitWord[0] == "constructor" || splitWord[0] == "destructor" ) return;
					}
				}

				// Divide word
				int			lineNum = cast(int) IupScintillaSendMessage( cSci.getIupScintilla, 2166, currentPos, 0 ) + 1; //SCI_LINEFROMPOSITION = 2166,
				auto 		AST_Head = actionManager.ParserAction.getActiveASTFromLine( GLOBAL.parserManager[upperCase(cSci.getFullPath)], lineNum );
				char[]		memberFunctionMotherName;

				if( !splitWord[0].length )
				{
					if( AST_Head.kind & B_WITH )
					{
						char[][] splitWithTile = getDivideWord( AST_Head.name );
						char[][] tempSplitWord = splitWord;
						splitWord.length = 0;						
						foreach( char[] s; splitWithTile ~ tempSplitWord )
						{
							if( s != "" ) splitWord ~= removeArrayAndPointerWord( s );
						}						
					}
				}
				
				// Get memberFunctionMotherName
				auto _fatherNode = AST_Head;
				if( AST_Head.kind & ( B_WITH | B_SCOPE ) )
				{
					do
					{
						if( _fatherNode.getFather !is null ) _fatherNode = _fatherNode.getFather; else break;
					}
					while( _fatherNode.kind & ( B_WITH | B_SCOPE ) )
				}
				
				if( _fatherNode.name.length )
				{
					if( _fatherNode.kind & ( B_CTOR | B_DTOR ) )
					{
						memberFunctionMotherName = _fatherNode.name;
					}
					else
					{
						if( _fatherNode.kind & ( B_BI | B_BAS ) )
						{
						}
						else
						{
							int dotPos = Util.index( _fatherNode.name, "." );
							if( dotPos < _fatherNode.name.length )
							{
								memberFunctionMotherName = _fatherNode.name[0..dotPos];
							}
						}
					}
				}				

				// Goto Includes
				char[] includeString = getIncludeString( cSci.getIupScintilla, currentPos );
				if( includeString.length )
				{
					char[] includeFullPath = checkIncludeExist( includeString, cSci.getFullPath );
					if( includeFullPath.length )
					{
						if( TYPE & 1 )
						{
							if( GLOBAL.navigation.addCache( includeFullPath, 1 ) ) actionManager.ScintillaAction.openFile( includeFullPath );
						}
						else
						{
							IupScintillaSendMessage( cSci.getIupScintilla, 2206, 0xFF0000, 0 ); //SCI_CALLTIPSETFORE 2206
							IupScintillaSendMessage( cSci.getIupScintilla, 2205, 0x00FFFF, 0 ); //SCI_CALLTIPSETBACK 2205
							IupScintillaSendMessage( cSci.getIupScintilla, 2200, currentPos, cast(int) GLOBAL.cString.convert( includeFullPath.dup ) ); // SCI_CALLTIPSHOW 2200
						}
						return;
					}
				}
				
				if( !splitWord[0].length ) return;

				if( AST_Head is null ) return;
				
				uint keyword_Btype;
				switch( lowerCase( word ) )
				{
					case "constructor":
						keyword_Btype = B_CTOR;
					case "destructor":
						if( keyword_Btype == 0 ) keyword_Btype = B_DTOR;
					case "operator":
						if( keyword_Btype == 0 ) keyword_Btype = B_OPERATOR;
					case "property":
						if( keyword_Btype == 0 ) keyword_Btype = B_PROPERTY;
					
					default:
						if( keyword_Btype > 0 )
						{
							CASTnode _motherNode = AST_Head;

							foreach( CASTnode _node; getMembers( AST_Head ) )
							{
								if( _node.kind & keyword_Btype )
								{
									if( _node.lineNumber == lineNum )
									{
										AST_Head = _node;
										break;
									}
								}
							}

							if( AST_Head is null ) return;
						}
				}
				
				cleanIncludesMarkContainer();
				
				for( int i = 0; i < splitWord.length; i++ )
				{
					if( keyword_Btype > 0 ) break;
					
					if( i == 0 )
					{
						/+
						CASTnode[] _nodes = searchMatchNodes( AST_Head, splitWord[i], B_FIND | B_SUB );
						if( _nodes.length )
						{
							foreach( CASTnode _n; _nodes )
							{
								CASTnode _nFather = _n;
								if( _nFather.getFather !is null )
								{
									_nFather = _nFather.getFather;
								}
								
								IupMessage( "", toStringz( _n.name ~ " : " ~ Integer.toString( _n.lineNumber ) ~ "\n" ~ _nFather.name ) );
								
							}
							
						}
						+/
						
						AST_Head = searchMatchNode( AST_Head, splitWord[i], B_FIND | B_SUB ); // NOTE!!!! Using "searchMatchNode()"
						if( AST_Head is null )
						{
							// For Type Objects
							if( memberFunctionMotherName.length )
							{
								//AST_Head = GLOBAL.parserManager[upperCase(cSci.getFullPath)];
								CASTnode memberFunctionMotherNode = _searchMatchNode( GLOBAL.parserManager[upperCase(cSci.getFullPath)], memberFunctionMotherName, B_TYPE | B_CLASS );
								if( memberFunctionMotherNode !is null ) AST_Head = searchMatchNode( memberFunctionMotherNode, splitWord[i], B_FIND | B_CTOR | B_SUB );
							}					
						}

						if( AST_Head is null ) return;

						if( splitWord.length == 1 ) break;
					}
					else
					{
						if( AST_Head.kind & B_NAMESPACE )
						{
							AST_Head = searchMatchMemberNode( AST_Head, splitWord[i], B_FIND | B_SUB );
						}
						else
						{
							AST_Head = searchMatchMemberNode( AST_Head, splitWord[i], B_VARIABLE | B_FUNCTION | B_PROPERTY | B_NAMESPACE | B_SUB );
						}
						
						if( AST_Head is null ) return;
					}

					if( TYPE & 3 )
					{
						if( AST_Head.kind & ( B_VARIABLE | B_PARAM ) )// | B_FUNCTION ) )
						{
							AST_Head = getType( AST_Head );
							if( AST_Head is null ) return;
						}
					}
					else
					{
						if( i < splitWord.length - 1 )
						{
							if( AST_Head.kind & ( B_VARIABLE | B_PARAM | B_FUNCTION ) )
							{
								AST_Head = getType( AST_Head );
								if( AST_Head is null ) return;
							}
						}
					}
				}

				if( TYPE == 0 )
				{
					char[]	_param, _type;
					getTypeAndParameter( AST_Head, _type, _param );
					if( GLOBAL.showTypeWithParams != "ON" ) _param = "";
					
					switch( AST_Head.kind )
					{
						case B_FUNCTION, B_SUB: if( !_type.length ) _type = "void"; break;
						case B_TYPE: _type = "TYPE"; break;
						case B_CLASS: _type = "CLASS"; break;
						case B_UNION: _type = "UNION"; break;
						case B_ENUM: _type = "ENUM"; break;
						case B_NAMESPACE: _type = "NAMESPACE"; break;
						case B_BI, B_BAS:
							return;
						default:
					}
					
					IupScintillaSendMessage( cSci.getIupScintilla, 2206, 0xFF0000, 0 ); //SCI_CALLTIPSETFORE 2206
					IupScintillaSendMessage( cSci.getIupScintilla, 2205, 0x00FFFF, 0 ); //SCI_CALLTIPSETBACK 2205

					char[] _list = ( ( _type.length ? _type ~ " " : null ) ~ AST_Head.name ~ _param ).dup;
					
					if( AST_Head.kind & ( B_TYPE | B_CLASS | B_UNION ) )
					{
						foreach( CASTnode _child; AST_Head.getChildren() )
							if( _child.kind & B_CTOR ) _list ~= ( "\n" ~ _child.name ~ _child.type );
					}
					
					IupScintillaSendMessage( cSci.getIupScintilla, 2200, currentPos, cast(int) GLOBAL.cString.convert( _list ) ); // SCI_CALLTIPSHOW 2200
				}
				else
				{
					bool		bGotoMemberProcedure;
					char[]		className, procedureName, fullPath;
					CASTnode	sonProcedureNode, oriNode = AST_Head;
					
					if( TYPE & 2 )
					{
						if( AST_Head.kind & ( B_SUB | B_FUNCTION | B_DTOR | B_CTOR | B_OPERATOR | B_PROPERTY ) )
						{
							if( AST_Head.getFather !is null )
							{
								// Declare
								if( AST_Head.getFather.kind & ( B_TYPE | B_CLASS | B_UNION ) )
								{
									bGotoMemberProcedure = true;
									className = AST_Head.getFather.name;
									procedureName = AST_Head.name;
								}
								else if( AST_Head.kind & ( B_SUB | B_FUNCTION ) )
								{
									if( AST_Head.lineNumber == AST_Head.endLineNum ) // Declare
									{
										bGotoMemberProcedure = true;
										procedureName = AST_Head.name;
										className = "";
									}
								}								
							}
						}
					}
					else if( TYPE & 1 )
					{
						if( keyword_Btype > 0 )
						{
							// Declare
							if( AST_Head.getFather.kind & ( B_TYPE | B_CLASS | B_UNION ) )
							{}
							else
							{
								char[]	typeString = AST_Head.type;
								CASTnode memberFunctionMotherNode = searchMatchNode( AST_Head.getFather, AST_Head.name, B_TYPE | B_CLASS | B_UNION );
								if( memberFunctionMotherNode !is null )
								{
									foreach_reverse( CASTnode _node; getMembers( memberFunctionMotherNode ) )
									{
										if( _node.kind & keyword_Btype )
										{
											if( _node.type == typeString )
											{
												AST_Head = _node;
												break;
											}
											AST_Head = _node;
										}
									}
								}
							}
						}
					}
					
					

					// Get lineNum
					lineNum = AST_Head.lineNumber;
					while( AST_Head.getFather() !is null )
					{
						AST_Head = AST_Head.getFather();
					}
					fullPath = AST_Head.name;
					
					scope _fp = new FilePath( fullPath );
					
					if( bGotoMemberProcedure )
					{
						if( className.length )
						{
							if( lowerCase( _fp.ext ) == "bi" )
							{
								fullPath = _fp.path() ~ _fp.name ~ ".bas";
								AST_Head = GLOBAL.outlineTree.loadParser( fullPath );
							}
	
							if( AST_Head !is null )
							{
								switch( oriNode.kind )
								{
									case B_SUB, B_FUNCTION, B_OPERATOR, B_PROPERTY:
										sonProcedureNode = searchMatchMemberNode( AST_Head, className ~ "." ~ procedureName, oriNode.kind );
										break;

									case B_CTOR, B_DTOR:
										sonProcedureNode = searchMatchMemberNode( AST_Head, className, oriNode.kind );
										break;
									
									default:
										return;
								}
								
								if( sonProcedureNode !is null )
								{
									if( GLOBAL.navigation.addCache( fullPath, sonProcedureNode.lineNumber ) ) actionManager.ScintillaAction.openFile( fullPath, sonProcedureNode.lineNumber );
									//if( actionManager.ScintillaAction.openFile( fullPath, sonProcedureNode.lineNumber ) ) GLOBAL.stackGotoDefinition ~= ( cSci.getFullPath ~ "*" ~ Integer.toString( ScintillaAction.getLinefromPos( cSci.getIupScintilla, currentPos ) + 1 ) );
									return;
								}
							}
							return;
						}
						else
						{
							// Declare & procedure body at same file
							foreach_reverse( CASTnode son; getMembers( AST_Head ) )
							{
								if( son.kind & oriNode.kind )
									if( son.name == procedureName )
										if( son.lineNumber < son.endLineNum )
										{
											if( GLOBAL.navigation.addCache( fullPath, son.lineNumber ) ) actionManager.ScintillaAction.openFile( fullPath, son.lineNumber );
											//if( actionManager.ScintillaAction.openFile( fullPath, son.lineNumber ) ) GLOBAL.stackGotoDefinition ~= ( cSci.getFullPath ~ "*" ~ Integer.toString( ScintillaAction.getLinefromPos( cSci.getIupScintilla, currentPos ) + 1 ) );
											return;
										}
							}
							
							// Check BAS file
							if( lowerCase( _fp.ext ) == "bi" )
							{
								fullPath = _fp.path() ~ _fp.name ~ ".bas";
								AST_Head = GLOBAL.outlineTree.loadParser( fullPath );
								
								if( AST_Head !is null )
								{
									foreach_reverse( CASTnode son; getMembers( AST_Head ) )
									{
										if( son.kind & oriNode.kind )
											if( son.name == procedureName )
												if( son.lineNumber < son.endLineNum )
												{
													if( GLOBAL.navigation.addCache( fullPath, son.lineNumber ) ) actionManager.ScintillaAction.openFile( fullPath, son.lineNumber );
													//if( actionManager.ScintillaAction.openFile( fullPath, son.lineNumber ) ) GLOBAL.stackGotoDefinition ~= ( cSci.getFullPath ~ "*" ~ Integer.toString( ScintillaAction.getLinefromPos( cSci.getIupScintilla, currentPos ) + 1 ) );
													return;
												}
									}
								}
							}							
							
						}
					}
					else
					{
						if( oriNode.kind & ( B_SUB | B_FUNCTION ) )
						{
							/*
							if( !memberFunctionMotherName.length )
							{
								IupMessage( "AST_Head",toStringz(AST_Head.name));
								IupMessage( "oriNode",toStringz(oriNode.name));
							}
							*/
							
							if( memberFunctionMotherName.length )
							{
								if( oriNode.lineNumber < oriNode.endLineNum ) // Not Declare
								{
									if( lowerCase( _fp.ext ) == "bas" )
									{
										fullPath = _fp.path() ~ _fp.name ~ ".bi";
										AST_Head = GLOBAL.outlineTree.loadParser( fullPath );
										
										if( AST_Head !is null )
										{
											foreach( CASTnode son; getMembers( AST_Head ) )
											{
												if( son.kind & oriNode.kind )
													if( son.name == oriNode.name )
														if( son.lineNumber == son.endLineNum ) // Declare
														{
															if( GLOBAL.navigation.addCache( fullPath, son.lineNumber ) ) actionManager.ScintillaAction.openFile( fullPath, son.lineNumber );
															//if( actionManager.ScintillaAction.openFile( fullPath, son.lineNumber ) ) GLOBAL.stackGotoDefinition ~= ( cSci.getFullPath ~ "*" ~ Integer.toString( ScintillaAction.getLinefromPos( cSci.getIupScintilla, currentPos ) + 1 ) );
															return;
														}
											}
										}										
									}
								}
							}
							
							//IupMessage( "!",toStringz("!!!!!"));
						}
					}
					
					if( GLOBAL.navigation.addCache( fullPath, lineNum ) ) actionManager.ScintillaAction.openFile( fullPath, lineNum );
					//if( actionManager.ScintillaAction.openFile( fullPath, lineNum ) ) GLOBAL.stackGotoDefinition ~= ( cSci.getFullPath ~ "*" ~ Integer.toString( ScintillaAction.getLinefromPos( cSci.getIupScintilla, currentPos ) + 1 ) );
				}
			}
		}
		catch( Exception e )
		{
			//IupMessage( "Error", toStringz( e.toString ) );
		}
	}
	
	/+
	static void backDefinition()
	{
		if( GLOBAL.stackGotoDefinition.length > 0 )
		{
			int starPos = Util.index( GLOBAL.stackGotoDefinition[$-1], "*" );
			if( starPos < GLOBAL.stackGotoDefinition[$-1].length )
			{
				char[]	fileName = GLOBAL.stackGotoDefinition[$-1][0..starPos];
				int		lineNumber = Integer.atoi( GLOBAL.stackGotoDefinition[$-1][starPos+1..$] );
				
				if( actionManager.ScintillaAction.openFile( fileName, lineNumber ) )
				{
					GLOBAL.stackGotoDefinition.length = GLOBAL.stackGotoDefinition.length - 1;
				}
			}
		}
	}
	+/
	
	static CASTnode getFunctionAST( CASTnode head, int _kind, char[] functionTitle, int line )
	{
		foreach_reverse( CASTnode node; head.getChildren() )
		{
			if( node.kind & _kind )
			{
				if( lowerCase( node.name ) == functionTitle )
				{
					if( line >= node.lineNumber ) return node;
				}
			}

			if( node.getChildrenCount )
			{
				CASTnode _node = getFunctionAST( node, _kind, functionTitle, line );
				if( _node !is null ) return _node;
			}
		}

		return null;
	}

	static char[] InsertEnd( Ihandle* iupSci, int lin, int pos )
	{
		// #define SCI_LINEFROMPOSITION 2166
		lin--; // ScintillaAction.getLinefromPos( iupSci, POS ) ) begin from 0
		
		int POS		= getProcedurePos( iupSci, pos, "sub" );
		if( POS > -1 && lin == ScintillaAction.getLinefromPos( iupSci, POS ) ) return "end sub";

		POS		= getProcedurePos( iupSci, pos, "function" );
		if( POS > -1 && lin == ScintillaAction.getLinefromPos( iupSci, POS ) ) return "end function";
		
		POS		= getProcedurePos( iupSci, pos, "property" );
		if( POS > -1 && lin == ScintillaAction.getLinefromPos( iupSci, POS ) ) return "end property";
		
		POS		= getProcedurePos( iupSci, pos, "constructor" );
		if( POS > -1 && lin == ScintillaAction.getLinefromPos( iupSci, POS ) ) return "end constructor";

		POS		= getProcedurePos( iupSci, pos, "destructor" );
		if( POS > -1 && lin == ScintillaAction.getLinefromPos( iupSci, POS ) ) return "end destructor";

		POS		= getProcedurePos( iupSci, pos, "#if" );
		if( POS > -1 && lin == ScintillaAction.getLinefromPos( iupSci, POS ) ) return "#endif";

		POS		= getProcedurePos( iupSci, pos, "#ifdef" );
		if( POS > -1 && lin == ScintillaAction.getLinefromPos( iupSci, POS ) ) return "#endif";

		POS		= getProcedurePos( iupSci, pos, "#ifndef" );
		if( POS > -1 && lin == ScintillaAction.getLinefromPos( iupSci, POS ) ) return "#endif";

		POS		= getProcedurePos( iupSci, pos, "#macro" );
		if( POS > -1 && lin == ScintillaAction.getLinefromPos( iupSci, POS ) ) return "#endmacro";

		POS		= getProcedurePos( iupSci, pos, "if" );
		if( POS > -1 && lin == ScintillaAction.getLinefromPos( iupSci, POS ) ) return "end if";
		
		POS		= getProcedurePos( iupSci, pos, "with" );
		if( POS > -1 && lin == ScintillaAction.getLinefromPos( iupSci, POS ) ) return "end with";

		POS		= getProcedurePos( iupSci, pos, "select case" );
		if( POS > -1 && lin == ScintillaAction.getLinefromPos( iupSci, POS ) ) return "end select";

		POS		= getProcedurePos( iupSci, pos, "namespace" );
		if( POS > -1 && lin == ScintillaAction.getLinefromPos( iupSci, POS ) ) return "end namespace";

		POS		= getProcedurePos( iupSci, pos, "type" );
		if( POS > -1 && lin == ScintillaAction.getLinefromPos( iupSci, POS ) ) return "end type";

		POS		= getProcedurePos( iupSci, pos, "union" );
		if( POS > -1 && lin == ScintillaAction.getLinefromPos( iupSci, POS ) ) return "end union";
		
		POS		= getProcedurePos( iupSci, pos, "extern" );
		if( POS > -1 && lin == ScintillaAction.getLinefromPos( iupSci, POS ) ) return "end extern";

		POS		= getProcedurePos( iupSci, pos, "operator" );
		if( POS > -1 && lin == ScintillaAction.getLinefromPos( iupSci, POS ) ) return "end operator";
		 

		POS			= skipCommentAndString( iupSci, pos, "enum", 0 );
		int ENDPOS	= skipCommentAndString( iupSci, pos, "end enum", 0 );
		if( POS > -1 && POS != ENDPOS + 4)
			if( lin == ScintillaAction.getLinefromPos( iupSci, POS ) ) return "end enum";

		POS		= skipCommentAndString( iupSci, pos, "scope", 0 );
		ENDPOS	= skipCommentAndString( iupSci, pos, "end scope", 0 );
		if( POS > -1 && POS != ENDPOS + 4)
			if( lin == ScintillaAction.getLinefromPos( iupSci, POS ) ) return "end scope";

		POS		= skipCommentAndString( iupSci, pos, "for", 0 );
		ENDPOS	= skipCommentAndString( iupSci, pos, "exit for", 0 );
		if( POS > -1 && POS != ENDPOS + 5 )
		{
			POS		= getProcedurePos( iupSci, pos, "for" );
			if( POS > -1 && lin == ScintillaAction.getLinefromPos( iupSci, POS ) ) return "next";
		}


		POS		= skipCommentAndString( iupSci, pos, "while", 0 );
		ENDPOS	= skipCommentAndString( iupSci, pos, "do while", 0 );
		if( POS > -1 && POS != ENDPOS + 3 )
		{
			POS		= getProcedurePos( iupSci, pos, "while" );
			if( POS > -1 && lin == ScintillaAction.getLinefromPos( iupSci, POS ) ) return "wend";
		}

		POS		= skipCommentAndString( iupSci, pos, "do", 0 );
		ENDPOS	= skipCommentAndString( iupSci, pos, "exit do", 0 );
		if( POS > -1 && POS != ENDPOS + 5 )
		{
			if( lin == ScintillaAction.getLinefromPos( iupSci, POS ) ) return "loop";
		}
		

		return null;
	}

	static bool callAutocomplete( Ihandle *ih, int pos, char[] text, char[] alreadyInput )
	{
		char[] list = charAdd( ih, pos, text );

		if( list.length )
		{
			/*char[][] splitWord = Util.split( alreadyInput, "." );
			if( splitWord.length == 1 ) splitWord = Util.split( alreadyInput, "->" );*/
			char[][] splitWord = getDivideWord( alreadyInput );

			alreadyInput = splitWord[length-1];

			/+
			if( fromStringz( IupGetAttribute( ih, "AUTOCACTIVE\0" ) ) == "YES" )
			{
				IupSetAttribute( ih, "AUTOCSELECT\0", GLOBAL.cString.convert( alreadyInput ) );
				if( IupGetInt( ih, "AUTOCSELECTEDINDEX\0" ) == -1 ) IupSetAttribute( ih, "AUTOCCANCEL\0", "YES\0" );
			}
			else
			{
			+/
				if( text == "(" )
				{
					if( fromStringz( IupGetAttribute( ih, "AUTOCACTIVE\0" ) ) == "YES" ) IupSetAttribute( ih, "AUTOCCANCEL\0", "YES\0" );

					IupScintillaSendMessage( ih, 2206, 0x707070, 0 ); //SCI_CALLTIPSETFORE 2206
					IupScintillaSendMessage( ih, 2205, 0xFFFFFF, 0 ); //SCI_CALLTIPSETBACK 2205

					IupScintillaSendMessage( ih, 2200, pos, cast(int) GLOBAL.cString.convert( list ) );
				}
				else
				{
					if( !alreadyInput.length ) IupScintillaSendMessage( ih, 2100, alreadyInput.length - 1, cast(int) GLOBAL.cString.convert( list ) ); else IupSetAttributeId( ih, "AUTOCSHOW", alreadyInput.length - 1, GLOBAL.cString.convert( list ) );
				}
			//}

			return false;
		}

		return true;
	}
}