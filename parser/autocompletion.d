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
	//import tango.text.convert.Layout;
	import tango.stdc.stringz;
	import tango.io.FilePath, tango.sys.Environment;
	import tango.io.Stdout;

	static char[][]				listContainer;
	static CASTnode[char[]]		includesMarkContainer;


	static char[] searchHead( Ihandle* iupSci, int pos, char[] targetText )
	{
		int documentLength = IupScintillaSendMessage( iupSci, 2006, 0, 0 );		// SCI_GETLENGTH = 2006,
		
		int posHead = getProcedurePos( iupSci, pos, targetText );
		if( posHead < 0 ) return null;

		int posEnd = getProcedureTailPos( iupSci, pos, targetText, 0 );//skipCommentAndString( iupSci, pos, "end " ~ targetText, 0 );
		if( posEnd > posHead ) return null;


		char[]	result;
		bool	bSPACE, bReturnNextWord;
		for( int i = posHead + targetText.length; i < documentLength; ++i )
		{
			char[] s = fromStringz( IupGetAttributeId( iupSci, "CHAR", i ) );

			//stdout( s ).newline;
			
			if( s == " " || s == "\t" )
			{
				if( result.length ) break;
			}
			else if( s == "(" || s[0] == 13 || s == "\n" )
			{
				break;
			}
			else
			{
				result ~= s;
			}
		}

		return Util.trim( result.dup );
	}

	static bool checkWithBlock( Ihandle* iupSci, int pos )
	{
		int posWith		= skipCommentAndString( iupSci, pos, "with", 0 );
		int posSub		= skipCommentAndString( iupSci, pos, "sub", 0 );
		int posFunction	= skipCommentAndString( iupSci, pos, "function", 0 );
		int posProperty	= skipCommentAndString( iupSci, pos, "property", 0 );
		int posCtor		= skipCommentAndString( iupSci, pos, "constructor", 0 );
		int posDtor		= skipCommentAndString( iupSci, pos, "destructor", 0 );

		/*
		IupMessage( "With", toStringz( Integer.toString( posWith ) ) );
		IupMessage( "Sub", toStringz( Integer.toString( posSub ) ) );
		IupMessage( "Function", toStringz( Integer.toString( posFunction ) ) );
		*/

		if( posWith < 0 ) return false;

		if( posWith > posSub && posWith > posFunction && posWith > posProperty && posWith > posCtor && posWith > posDtor ) return true;

		return false;
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
		_path.set( GLOBAL.compilerFullPath.toDString );
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
				GLOBAL.outlineTree.loadFile( includeFullPath );

				if( GLOBAL.editorSetting00.Message == "ON" ) 
				{
					version(Windows) IupSetAttribute( GLOBAL.outputPanel, "APPEND", toStringz( "  Pre-Parse file: [" ~ includeFullPath ~ "]" ) );
				}
				
				results ~= GLOBAL.parserManager[upperCase(includeFullPath)];
				results ~= getIncludes( GLOBAL.parserManager[upperCase(includeFullPath)], includeFullPath );

				includesMarkContainer[upperCase(includeFullPath)] = GLOBAL.parserManager[upperCase(includeFullPath)];
			}
		}

		return results;
	}

	static CASTnode[] getMatchIncludesFromWholeWord( CASTnode originalNode, char[] originalFullPath, char[] word, int B_KIND )
	{
		CASTnode[] results;

		foreach( char[] key; includesMarkContainer.keys )
			includesMarkContainer.remove( key );		
		
		// Parse Include
		//CASTnode[] includeASTnodes = getIncludes( originalNode, originalFullPath );
		getIncludes( originalNode, originalFullPath, true );

		foreach( includeAST; includesMarkContainer )
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

		return results;
	}	

	static CASTnode[] getMatchIncludesFromWord( CASTnode originalNode, char[] originalFullPath, char[] word )
	{
		CASTnode[] results;

		foreach( char[] key; includesMarkContainer.keys )
			includesMarkContainer.remove( key );

		// Parse Include
		//CASTnode[] includeASTnodes = getIncludes( originalNode, originalFullPath );
		getIncludes( originalNode, originalFullPath, true );

		/*
		foreach( CASTnode n; includesMarkContainer )
			Stdout( n.name ).newline;
		*/
		foreach( includeAST; includesMarkContainer )
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
				CASTnode[] resultIncludeNodes = getMatchIncludesFromWholeWord( GLOBAL.parserManager[upperCase(cSci.getFullPath)], cSci.getFullPath, word, B_KIND );

				if( resultIncludeNodes.length )	resultNode = resultIncludeNodes[0];
			}
		}

		return resultNode;
	}

	static CASTnode[] getMembers( CASTnode AST_Head )
	{
		CASTnode[] result;

		foreach( CASTnode _child; AST_Head.getChildren() ~ getBaseNodeMembers( AST_Head ) )
		{
			if( _child.kind & ( B_UNION | B_TYPE ) )
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
					char[] _type = groupAST[i].type;
					char[] _paramString = "()";
					
					int openParenPos = Util.index( groupAST[i].type, "(" );
					if( openParenPos < groupAST[i].type.length )
					{
						_type = groupAST[i].type[0..openParenPos];
						_paramString = groupAST[i].type[openParenPos..length];
					}

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
		foreach( char[] _s; GLOBAL.KEYWORDS )
		{
			foreach( char[] s; Util.split( _s, " " ) )
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
			if( _node.kind == B_INCLUDE )
			{
				if( _node.type == "__FB_WIN32__" )
				{
					version(Windows)
					{
						//Stdout( "Include(Win32): " ~ _node.name ).newline;
						results ~= check( _node.name, originalFullPath );
					}
				}
				else if( _node.type == "__FB_LINUX__" || _node.type == "__FB_UNIX__" )
				{
					version(linux)
					{
						results ~= check( _node.name, originalFullPath );
					}
				}
				else if( _node.type == "!__FB_WIN32__" )
				{
					version(Windows){}
					else
					{
						//Stdout( "Include((Linux)): " ~ _node.name ).newline;
						results ~= check( _node.name, originalFullPath );
					}
				}
				else if( _node.type == "!__FB_LINUX__" || _node.type == "!__FB_UNIX__" )
				{
					version(linux){}
					else
					{
						results ~= check( _node.name, originalFullPath );
					}
				}
				/*
				else if( _node.type.length )
				{

			
				}
				*/
				else
				{
					//Stdout( "Include(NORMAL): " ~ _node.name ).newline;
					results ~= check( _node.name, originalFullPath );
				}
			}
		}

		//Stdout( "Level:" ~ Integer.toString( level )  ~ "  " ~ originalNode.name ).newline;

		if( level > 0 ) level--;

		return results;
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
		int documentLength = IupScintillaSendMessage( iupSci, 2006, 0, 0 );		// SCI_GETLENGTH = 2006,
		IupScintillaSendMessage( iupSci, 2198, 2, 0 );							// SCI_SETSEARCHFLAGS = 2198,
		IupScintillaSendMessage( iupSci, 2190, pos, 0 ); 						// SCI_SETTARGETSTART = 2190,
		IupScintillaSendMessage( iupSci, 2192, 0, 0 );							// SCI_SETTARGETEND = 2192,

		int posHead = IupScintillaSendMessage( iupSci, 2197, targetText.length, cast(int) GLOBAL.cString.convert( targetText ) );

		while( posHead >= 0 )
		{
			int style = IupScintillaSendMessage( iupSci, 2010, posHead, 0 ); // SCI_GETSTYLEAT 2010
			if( style == 1 || style == 19 || style == 4 )
			{
				IupScintillaSendMessage( iupSci, 2190, posHead - 1, 0 );				// SCI_SETTARGETSTART = 2190,
				IupScintillaSendMessage( iupSci, 2192, 0, 0 );							// SCI_SETTARGETEND = 2192,
				posHead = IupScintillaSendMessage( iupSci, 2197, targetText.length, cast(int) GLOBAL.cString.convert( targetText ) );
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
					posHead = IupScintillaSendMessage( iupSci, 2197, targetText.length, cast(int) GLOBAL.cString.convert( targetText ) );
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
		int documentLength = IupScintillaSendMessage( iupSci, 2006, 0, 0 );		// SCI_GETLENGTH = 2006,

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
		pos = IupScintillaSendMessage( iupSci, 2197, targetText.length, cast(int) GLOBAL.cString.convert( targetText ) );
		
		while( pos > -1 )
		{
			int style = IupScintillaSendMessage( iupSci, 2010, pos, 0 ); // SCI_GETSTYLEAT 2010
			if( style == 1 || style == 19 || style == 4 )
			{
				if( direct == 0 )
				{
					IupScintillaSendMessage( iupSci, 2190, pos - 1, 0 );
					IupScintillaSendMessage( iupSci, 2192, 0, 0 );							// SCI_SETTARGETEND = 2192,
					pos = IupScintillaSendMessage( iupSci, 2197, targetText.length, cast(int) GLOBAL.cString.convert( targetText ) );
				}
				else
				{
					IupScintillaSendMessage( iupSci, 2190, pos + targetText.length, 0 );
					IupScintillaSendMessage( iupSci, 2192, documentLength - 1, 0 );							// SCI_SETTARGETEND = 2192,
					pos = IupScintillaSendMessage( iupSci, 2197, targetText.length, cast(int) GLOBAL.cString.convert( targetText ) );
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
					case " ", "\t", ":", "\n", "\r", "+", ">", "*", "/", "<", ",":
						if( countParen == 0 && countBracket == 0 ) bBackEnd = true;
						break;

					default:
				}
			}

			if( bBackEnd ) break;
		}
		while( ++pos < documentLength )

		if( oriPos == pos ) return null;

		int dummyHeadPos;
		return getWholeWordReverse( iupSci, pos, dummyHeadPos );
	}

	static char[] checkIsInclude( Ihandle* iupSci, int pos = -1 )
	{
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
		 
		return result.reverse;
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
					//dchar s = IupScintillaSendMessage( iupSci, 2007, pos, 0 );//SCI_GETCHARAT = 2007,
					char[] _s = fromStringz( IupGetAttributeId( iupSci, "CHAR", pos ) );
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
						case ' ', '\t', ':', '\n', '\r', '+', '-', '*', '/', '<':
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
			}
			
		}
		catch( Exception e )
		{
			//IupMessage( "Error", toStringz( e.toString ) );
			return null;
		}

		return word;
	}
	
	static char[] charAdd( Ihandle* iupSci, int pos = -1, char[] text = "" )
	{
		int		dummyHeadPos;
		char[] 	word, result;
		bool	bDot, bCallTip;

		if( text == "(" )
		{
			bCallTip = true;
			IupSetAttribute( iupSci, "AUTOCCANCEL", GLOBAL.cString.convert( "YES" ) ); // Prevent autocomplete -> calltip issue
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

		// Check first dot '.' at With Block
		if( !word.length && bDot )
		{
			if( checkWithBlock( iupSci, pos ) )
			{
				char[] withTitle = searchHead( iupSci, pos, "with" );
				if( withTitle.length ) word = word ~ withTitle.reverse;
			}
		}

		/*
		if( !bDot && !bCallTip )
		{
			if( word.length < GLOBAL.autoCompletionTriggerWordCount ) return null;
		}
		*/

		word = lowerCase( word.reverse );

		auto cSci = actionManager.ScintillaAction.getActiveCScintilla();
		if( cSci !is null )
		{
			if( !bDot && ( fromStringz( IupGetAttribute( iupSci, "AUTOCACTIVE" ) ) == "YES" ) )
			{
				/+
				/*
				foreach( CASTnode node; listContainer )
				{
					//result ~= ( getListImage( node ) ~ " " );
				}
				*/
				if( listContainer.length )
				{
					listContainer.sort;

					char[]	_type;
					int		maxLeft, maxRight;
					
					for( int i = 0; i < listContainer.length; ++ i )
					{
						if( listContainer[i].length )
						{
							int dollarPos = Util.rindex( listContainer[i], "~" );
							if( dollarPos < listContainer[i].length )
							{
								_type = listContainer[i][dollarPos+1..length];
								if( _type.length > maxRight ) maxRight = _type.length;
								listContainer[i] = listContainer[i][0..dollarPos];
								if( listContainer[i].length > maxLeft ) maxLeft = listContainer[i].length;
							}
							else
							{
								if( listContainer[i].length > maxLeft ) maxLeft = listContainer[i].length;
							}
						}
					}

					
					result ~= ( listContainer[0] ~ "^" );
					for( int i = 1; i < listContainer.length; ++ i )
					{
						if( listContainer[i].length )
						{
							if( listContainer[i] != listContainer[i-1] ) result ~= ( listContainer[i] ~ "^" );
						}
					}
				}
				+/
			}
			else
			{
				// Clean listContainer
				listContainer.length = 0;
				IupSetAttribute( iupSci, "AUTOCCANCEL", GLOBAL.cString.convert( "YES" ) );

				// Divide word
				/*char[][] splitWord = Util.split( word, "." );
				if( splitWord.length == 1 ) splitWord = Util.split( word, "->" );*/
				char[][]	splitWord = getDivideWord( word );
				int			lineNum = IupScintillaSendMessage( iupSci, 2166, pos, 0 ) + 1; //SCI_LINEFROMPOSITION = 2166,
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
							if( s != "" ) splitWord ~= s;
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
				
				if( !_fatherNode.name.length )
				{
					if( _fatherNode.kind & ( B_CTOR | B_DTOR ) )
					{
						memberFunctionMotherName = _fatherNode.name;
					}					
				}
				else
				{
					int dotPos = Util.index( _fatherNode.name, "." );
					if( dotPos < _fatherNode.name.length )
					{
						memberFunctionMotherName = _fatherNode.name[0..dotPos];
					}
				}

				
				/+
				if( !splitWord[0].length )
				{
					if( checkWithBlock( iupSci, pos ) )
					{
						char[] withTitle = searchHead( iupSci, pos, "with" );
						
						if( withTitle.length )
						{
							char[][] splitWithTile = Util.split(withTitle, "." );
							char[][] tempSplitWord = splitWord;
							splitWord.length = 0;

							foreach( char[] s; splitWithTile ~ tempSplitWord )
							{
								if( s != "" ) splitWord ~= s;
							}
						}
					}
				}

				auto			AST_Head = GLOBAL.parserManager[upperCase(cSci.getFullPath)];
				int 			titleKind;
				char[]			functionTitle = lowerCase( getFunctionTitle( iupSci, pos, titleKind ) );
				int				lineNum = IupScintillaSendMessage( iupSci, 2166, pos, 0 ) + 1; //SCI_LINEFROMPOSITION = 2166,
				char[]			memberFunctionMotherName;
				+/
				
				/+

				if( functionTitle.length )
				{
					//AST_Head = getFunctionAST( AST_Head, functionTitle, lineNum );
					CASTnode functionHeadNode = getFunctionAST( AST_Head, titleKind, functionTitle, lineNum );
					if( functionHeadNode !is null ) AST_Head = functionHeadNode;
					AST_Head = checkScopeNode( iupSci, AST_Head, lineNum );
					
					int dotPos = Util.index( functionTitle, "." );
					if( dotPos < functionTitle.length )
					{
						memberFunctionMotherName = functionTitle[0..dotPos];
					}
					else
					{
						// check Constructor or Destructor
						if( titleKind & ( B_CTOR | B_DTOR ) ) memberFunctionMotherName = functionTitle;
					}
				}
				else
				{
					AST_Head = checkScopeNode( iupSci, AST_Head, lineNum );
				}
				+/

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

				for( int i = 0; i < splitWord.length; i++ )
				{
					listContainer.length = 0;
					
					if( i == 0 )
					{
						CASTnode firstMatchNode;

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
								resultNodes			= getMatchASTfromWord( AST_Head, splitWord[i], lineNum );
								resultIncludeNodes	= getMatchIncludesFromWord( GLOBAL.parserManager[upperCase(cSci.getFullPath)], cSci.getFullPath, splitWord[i] );

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
							if( listContainer[i] == listContainer[i+1] ) continue;

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

	static void toDefintionAndType( bool bDefintion )
	{
		if( GLOBAL.enableParser != "ON" ) return;
		
		try
		{
			char[] word;
			
			auto cSci = actionManager.ScintillaAction.getActiveCScintilla();
			if( cSci !is null )
			{
				int currentPos = actionManager.ScintillaAction.getCurrentPos( cSci.getIupScintilla );
				if( currentPos < 1 ) return;
				
				word = getWholeWordDoubleSide( cSci.getIupScintilla, currentPos );
				word = lowerCase( word.reverse );

				char[][] splitWord = getDivideWord( word );
				
				// Manual
				if( splitWord.length == 1 )
				{
					if( GLOBAL.toggleUseManual == "ON" )
					{
						if( bDefintion )
						{
							if( GLOBAL.toggleManualDefinition == "ON" )
							{
								if( GLOBAL.manualPanel.jumpDefinition( splitWord[0] ) ) GLOBAL.manualPanel.showTab( true );
							}
						}
						else
						{
							if( GLOBAL.toggleManualShowType == "ON" ) GLOBAL.manualPanel.showType( splitWord[0] );
						}
					}
				}

				// Divide word
				int			lineNum = IupScintillaSendMessage( cSci.getIupScintilla, 2166, currentPos, 0 ) + 1; //SCI_LINEFROMPOSITION = 2166,
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
							if( s != "" ) splitWord ~= s;
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
				
				if( !_fatherNode.name.length )
				{
					if( _fatherNode.kind & ( B_CTOR | B_DTOR ) )
					{
						memberFunctionMotherName = _fatherNode.name;
					}					
				}
				else
				{
					int dotPos = Util.index( _fatherNode.name, "." );
					if( dotPos < _fatherNode.name.length )
					{
						memberFunctionMotherName = _fatherNode.name[0..dotPos];
					}
				}
				/*
				if( AST_Head.name.length )
				{
					int dotPos = Util.index( AST_Head.name, "." );
					if( dotPos < AST_Head.name.length )
					{
						memberFunctionMotherName = AST_Head.name[0..dotPos];
					}
					else
					{
						// check Constructor or Destructor
						if( AST_Head.kind & ( B_CTOR | B_DTOR ) ) memberFunctionMotherName = AST_Head.name;
					}
				}
				*/
				

				// Goto Includes
				if( bDefintion )
				{
					char[] string = checkIsInclude( cSci.getIupScintilla, currentPos );
					char[] fullPath = checkIncludeExist( string, cSci.getFullPath );

					if( fullPath.length )
					{
						actionManager.ScintillaAction.openFile( fullPath );
						return;
					}			
				}

				if( AST_Head is null ) return;

				for( int i = 0; i < splitWord.length; i++ )
				{
					if( i == 0 )
					{
						AST_Head = searchMatchNode( AST_Head, splitWord[i], B_FIND | B_SUB ); // NOTE!!!! Using "searchMatchNode()"

						if( AST_Head is null )
						{
							if( memberFunctionMotherName.length )
							{
								//IupMessage("",toStringz(memberFunctionMotherName ~ "." ~ word));
								AST_Head = searchMatchNode( GLOBAL.parserManager[upperCase(cSci.getFullPath)], memberFunctionMotherName ~ "." ~ word, B_FIND | B_SUB ); // NOTE!!!! Using "searchMatchNode()"
							}
						}

						if( AST_Head is null )
						{
							// For Type Objects
							if( memberFunctionMotherName.length )
							{
								//AST_Head = GLOBAL.parserManager[upperCase(cSci.getFullPath)];
								CASTnode memberFunctionMotherNode = _searchMatchNode( GLOBAL.parserManager[upperCase(cSci.getFullPath)], memberFunctionMotherName, B_TYPE | B_CLASS );
								if( memberFunctionMotherNode !is null ) AST_Head = searchMatchNode( memberFunctionMotherNode, splitWord[i], B_FIND | B_SUB );
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

					if( bDefintion )
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

				if( !bDefintion )
				{
					char[]	_param;
					char[] 	_type = AST_Head.type;
					int openParenPos = Util.index( AST_Head.type, "(" );
					if( openParenPos < AST_Head.type.length )
					{
						_type = AST_Head.type[0..openParenPos];
						if( GLOBAL.showTypeWithParams == "ON" ) _param = AST_Head.type[openParenPos..length];
					}

					switch( AST_Head.kind )
					{
						case B_FUNCTION, B_SUB: if( !_type.length ) _type = "void"; break;
						case B_TYPE: _type = "TYPE"; break;
						case B_CLASS: _type = "CLASS"; break;
						case B_UNION: _type = "UNION"; break;
						case B_ENUM: _type = "ENUM"; break;
						case B_NAMESPACE: _type = "NAMESPACE"; break;
						default:
					}

					IupScintillaSendMessage( cSci.getIupScintilla, 2206, 0xFF0000, 0 ); //SCI_CALLTIPSETFORE 2206
					IupScintillaSendMessage( cSci.getIupScintilla, 2205, 0x00FFFF, 0 ); //SCI_CALLTIPSETBACK 2205

					char[] _list = ( ( _type.length ? _type ~ " " : null ) ~ AST_Head.name ~ _param ).dup;
					IupScintillaSendMessage( cSci.getIupScintilla, 2200, currentPos, cast(int) GLOBAL.cString.convert( _list ) ); // SCI_CALLTIPSHOW 2200
				}
				else
				{
					lineNum = AST_Head.lineNumber;
					
					while( AST_Head.getFather() !is null )
					{
						AST_Head = AST_Head.getFather();
					}

					if( actionManager.ScintillaAction.openFile( AST_Head.name, lineNum ) ) GLOBAL.stackGotoDefinition ~= ( cSci.getFullPath ~ "*" ~ Integer.toString( ScintillaAction.getLinefromPos( cSci.getIupScintilla, currentPos ) + 1 ) );
				}
			}
		}
		catch( Exception e )
		{
			//IupMessage( "Error", toStringz( e.toString ) );
		}
	}
	
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

	static char[] getFunctionTitle( Ihandle* iupSci, int pos, out int code )
	{
		char[] result = searchHead( iupSci, pos, "sub" );

		if( result.length )
		{
			code = B_SUB;
		}
		else
		{
			result = searchHead( iupSci, pos, "function" );
			if( result.length )
			{
				code = B_FUNCTION;
			}
			else
			{
				result = searchHead( iupSci, pos, "property" );
				if( result.length )
				{
					code = B_PROPERTY;
				}
				else
				{
					result = searchHead( iupSci, pos, "operator" );
					if( result.length )
					{
						code = B_OPERATOR;
					}
					else
					{
						result = searchHead( iupSci, pos, "type" );
						if( result.length )
						{
							code = B_TYPE;
						}
						else
						{
							result = searchHead( iupSci, pos, "union" );
							if( result.length )
							{
								code = B_UNION;
							}
							else
							{
								result = searchHead( iupSci, pos, "enum" );
								if( result.length )
								{
									code = B_ENUM;
								}
								else
								{
									result = searchHead( iupSci, pos, "constructor" );
									if( result.length )
									{
										code = B_CTOR | 1;
									}
									else
									{
										result = searchHead( iupSci, pos, "destructor" );
										if( result.length )
										{
											code = B_DTOR | 1;
										}
									}
								}				
							}				
						}				
					}				
				}				
			}
		}
		
		if( result.length )
		{
			if( Util.index( result, "." ) < result.length ) code = code | 1;
		}

		//IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( "Title: " ~ result ) );

		return result;
	}
	/+
	static char[] InsertEnd( Ihandle *iupSci, int lin, int pos )
	{
		// #define SCI_LINEFROMPOSITION 2166
		lin--; // ScintillaAction.getLinefromPos( iupSci, POS ) ) begin from 0
		
		int POS		= getProcedurePos( iupSci, pos, "sub" ), rePOS;
		int	ENDPOS;
		if( POS > -1 && lin == ScintillaAction.getLinefromPos( iupSci, POS ) )
		{
			ENDPOS	= getProcedureTailPos( iupSci, pos, "sub", 1 );
			if( ENDPOS > -1 ) rePOS = getProcedurePos( iupSci, ENDPOS - 3, "sub" ); else return "end sub";
			if( POS == rePOS ) return null; else return "end sub";
		}

		POS		= getProcedurePos( iupSci, pos, "function" );
		if( POS > -1 && lin == ScintillaAction.getLinefromPos( iupSci, POS ) )
		{
			ENDPOS	= getProcedureTailPos( iupSci, pos, "function", 1 );
			if( ENDPOS > -1 ) rePOS = getProcedurePos( iupSci, ENDPOS - 8, "function" ); else return "end function";
			if( POS == rePOS ) return null; else return "end function";
		}
		
		POS		= getProcedurePos( iupSci, pos, "property" );
		if( POS > -1 && lin == ScintillaAction.getLinefromPos( iupSci, POS ) )
		{
			ENDPOS	= getProcedureTailPos( iupSci, pos, "property", 1 );
			if( ENDPOS > -1 ) rePOS = getProcedurePos( iupSci, ENDPOS - 8, "property" ); else return "end property";
			if( POS == rePOS ) return null; else return "end property";
		}
		
		POS		= getProcedurePos( iupSci, pos, "constructor" );
		if( POS > -1 && lin == ScintillaAction.getLinefromPos( iupSci, POS ) )
		{
			ENDPOS	= getProcedureTailPos( iupSci, pos, "constructor", 1 );
			if( ENDPOS > -1 ) rePOS = getProcedurePos( iupSci, ENDPOS - 11, "constructor" ); else return "end constructor";
			if( POS == rePOS ) return null; else return "end constructor";
		}

		POS		= getProcedurePos( iupSci, pos, "destructor" );
		if( POS > -1 && lin == ScintillaAction.getLinefromPos( iupSci, POS ) )
		{
			ENDPOS	= getProcedureTailPos( iupSci, pos, "destructor", 1 );
			if( ENDPOS > -1 ) rePOS = getProcedurePos( iupSci, ENDPOS - 10, "destructor" ); else return "end destructor";
			if( POS == rePOS ) return null; else return "end destructor";
		}

		POS		= getProcedurePos( iupSci, pos, "if" );
		if( POS > -1 && lin == ScintillaAction.getLinefromPos( iupSci, POS ) )
		{
			ENDPOS	= getProcedureTailPos( iupSci, pos, "if", 1 );
			if( ENDPOS > -1 ) rePOS = getProcedurePos( iupSci, ENDPOS - 2, "if" ); else return "end if";
			if( POS == rePOS ) return null; else return "end if";
		}
		
		POS		= getProcedurePos( iupSci, pos, "with" );
		if( POS > -1 && lin == ScintillaAction.getLinefromPos( iupSci, POS ) )
		{
			ENDPOS	= getProcedureTailPos( iupSci, pos, "with", 1 );
			if( ENDPOS > -1 ) rePOS = getProcedurePos( iupSci, ENDPOS - 4, "with" ); else return "end with";
			if( POS == rePOS ) return null; else return "end with";
		}

		POS		= getProcedurePos( iupSci, pos, "select case" );
		if( POS > -1 && lin == ScintillaAction.getLinefromPos( iupSci, POS ) ) return "end select";
		{
			ENDPOS	= getProcedureTailPos( iupSci, pos, "select", 1 );
			if( ENDPOS > -1 ) rePOS = getProcedurePos( iupSci, ENDPOS - 6, "select case" ); else return "end select";
			if( POS == rePOS ) return null; else return "end select";
		}
		
		POS		= getProcedurePos( iupSci, pos, "namespace" );
		if( POS > -1 && lin == ScintillaAction.getLinefromPos( iupSci, POS ) )
		{
			ENDPOS	= getProcedureTailPos( iupSci, pos, "namespace", 1 );
			if( ENDPOS > -1 ) rePOS = getProcedurePos( iupSci, ENDPOS - 9, "namespace" ); else return "end namespace";
			if( POS == rePOS ) return null; else return "end namespace";
		}		

		POS		= getProcedurePos( iupSci, pos, "type" );
		if( POS > -1 && lin == ScintillaAction.getLinefromPos( iupSci, POS ) )
		{
			ENDPOS	= getProcedureTailPos( iupSci, pos, "type", 1 );
			if( ENDPOS > -1 ) rePOS = getProcedurePos( iupSci, ENDPOS - 4, "type" ); else return "end type";
			if( POS == rePOS ) return null; else return "end type";
		}		

		POS		= getProcedurePos( iupSci, pos, "union" );
		if( POS > -1 && lin == ScintillaAction.getLinefromPos( iupSci, POS ) )
		{
			ENDPOS	= getProcedureTailPos( iupSci, pos, "union", 1 );
			if( ENDPOS > -1 ) rePOS = getProcedurePos( iupSci, ENDPOS - 5, "union" ); else return "end union";
			if( POS == rePOS ) return null; else return "end union";
		}		
		
		POS		= getProcedurePos( iupSci, pos, "extern" );
		if( POS > -1 && lin == ScintillaAction.getLinefromPos( iupSci, POS ) )
		{
			ENDPOS	= getProcedureTailPos( iupSci, pos, "extern", 1 );
			if( ENDPOS > -1 ) rePOS = getProcedurePos( iupSci, ENDPOS - 6, "extern" ); else return "end extern";
			if( POS == rePOS ) return null; else return "end extern";
		}		

		POS		= getProcedurePos( iupSci, pos, "operator" );
		if( POS > -1 && lin == ScintillaAction.getLinefromPos( iupSci, POS ) )
		{
			ENDPOS	= getProcedureTailPos( iupSci, pos, "operator", 1 );
			if( ENDPOS > -1 ) rePOS = getProcedurePos( iupSci, ENDPOS - 8, "operator" ); else return "end operator";
			if( POS == rePOS ) return null; else return "end operator";
		}		

		POS			= skipCommentAndString( iupSci, pos, "enum", 0 );
		ENDPOS		= skipCommentAndString( iupSci, pos, "end enum", 0 );
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
	+/

	static char[] InsertEnd( Ihandle *iupSci, int lin, int pos )
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

			if( fromStringz( IupGetAttribute( ih, "AUTOCACTIVE" ) ) == "YES" )
			{
				IupSetAttribute( ih, "AUTOCSELECT", GLOBAL.cString.convert( alreadyInput ) );
				if( IupGetInt( ih, "AUTOCSELECTEDINDEX" ) == -1 ) IupSetAttribute( ih, "AUTOCCANCEL", "YES" );
			}
			else
			{
				if( text == "(" )
				{
					if( fromStringz( IupGetAttribute( ih, "AUTOCACTIVE" ) ) == "YES" ) IupSetAttribute( ih, "AUTOCCANCEL", "YES" );

					IupScintillaSendMessage( ih, 2206, 0x707070, 0 ); //SCI_CALLTIPSETFORE 2206
					IupScintillaSendMessage( ih, 2205, 0xFFFFFF, 0 ); //SCI_CALLTIPSETBACK 2205

					IupScintillaSendMessage( ih, 2200, pos, cast(int) GLOBAL.cString.convert( list ) );
				}
				else
				{
					if( !alreadyInput.length ) IupScintillaSendMessage( ih, 2100, alreadyInput.length - 1, cast(int) GLOBAL.cString.convert( list ) ); else IupSetAttributeId( ih, "AUTOCSHOW", alreadyInput.length - 1, GLOBAL.cString.convert( list ) );
				}
			}

			return false;
		}

		return true;
	}
}
