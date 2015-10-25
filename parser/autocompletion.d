module parser.autocompletion;

struct AutoComplete
{
	private:
	import iup.iup;
	import iup.iup_scintilla;

	import global, actionManager, menu;
	import tools;
	import parser.ast;

	import Integer = tango.text.convert.Integer, Util = tango.text.Util;
	//import tango.text.convert.Layout;
	import tango.stdc.stringz;
	import tango.io.FilePath, tango.sys.Environment;
	import tango.io.Stdout;

	static char[][]				listContainer;
	static CASTnode[char[]]		includesMarkContainer;

	

	static char[] getLine( Ihandle* iupSci, int line, bool bCRLF = true )
	{
		// SCI_GETLINE = 2153, (include CR/LF)
		// SCI_LINELENGTH = 2350, (include CR/LF)
		// SCI_LINEFROMPOSITION = 2166,
		// SCI_GETLINEENDPOSITION = 2136,
		// SCI_POSITIONFROMLINE = 2167,
		
		int posLineTail = IupScintillaSendMessage( iupSci, 2136, line, 0 );
		int posLineHead = IupScintillaSendMessage( iupSci, 2167, line, 0 );

		if( posLineTail <= posLineHead ) return null;

		char[]	text;
		int		len = posLineTail - posLineHead;

		int lineLength_CRLF =  IupScintillaSendMessage( iupSci, 2350, line, 0 ); // SCI_LINELENGTH = 2350, (include CR/LF)
		text.length = lineLength_CRLF;

		IupScintillaSendMessage( iupSci, 2153, line, cast(int) GLOBAL.cString.convert( text ) ); // SCI_GETLINE = 2153, (include CR/LF)

		if( bCRLF ) return text;
		
		return text[0..len];
	}
	
	static char[] searchHead( Ihandle* iupSci, int pos, char[] targetText )
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

		if( posHead < 0 ) return null;

		// Check after "sub" have word, if "end sub", we got no word....
		for( int i = posHead + targetText.length; i < documentLength; ++ i )
		{
			char[] s = lowerCase( fromStringz( IupGetAttributeId( iupSci, "CHAR", i ) ) );

			
			if( s[0] == 13 || s == ":" || s == "\n" )
			{
				return null;
			}
			else if( s == " " || s == "\t" )
			{
			}
			else
			{
				break;
			}
		}

		IupScintillaSendMessage( iupSci, 2190, pos, 0 ); 						// SCI_SETTARGETSTART = 2190,
		IupScintillaSendMessage( iupSci, 2192, documentLength - 1, 0 );			// SCI_SETTARGETEND = 2192,

		int posTail = IupScintillaSendMessage( iupSci, 2197, targetText.length, cast(int) GLOBAL.cString.convert( targetText ) );

		if( posTail < 0 ) return null;

		// Check after "sub" have word, if "end sub", we got no word....
		for( int i = posTail+targetText.length; i < documentLength; ++ i )
		{
			char[] s = lowerCase( fromStringz( IupGetAttributeId( iupSci, "CHAR", i ) ) );

			if( s[0] == 13 || s == ":" || s == "\n" )
			{
				break;
			}
			else if( s == " " || s == "\t" )
			{
			}
			else
			{
				return null;
			}
		}

		if( pos < posHead || pos > posTail ) return null;

		char[]	result;
		bool	bSPACE, bReturnNextWord;
		for( int i = posHead + targetText.length; i < documentLength; ++i )
		{
			char[] s = lowerCase( fromStringz( IupGetAttributeId( iupSci, "CHAR", i ) ) );

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

	static char[] getListImage( CASTnode node )
	{
		int protAdd;
		switch( node.protection )
		{
			case "public":		protAdd = 2; break;
			case "private":		protAdd = 0; break;
			case "protected":	protAdd = 1; break;
			default:			protAdd = 2;
		}
		
		switch( node.kind )
		{
			case B_SUB, B_FUNCTION:			return node.name ~ "?" ~ Integer.toString( 0 + protAdd );
			case B_VARIABLE:				return node.name ~ "?" ~ Integer.toString( 3 + protAdd );
			/*
				CASTnode _typeNode = getType( node );
				if( _typeNode is null )
				{
					return node.name ~ "?" ~ Integer.toString( 3 + protAdd );
				}
				else
				{	
					char[] result = getListImage( _typeNode );
					int questPos = Util.index( result, "?" );
					if( questPos < result.length )
					{
						return node.name ~ result[questPos..length];
					}
				}
				break;
			*/
			case B_CLASS:					return node.name ~ "?" ~ Integer.toString( 6 + protAdd );
			case B_TYPE: 					return node.name ~ "?" ~ Integer.toString( 9 + protAdd );
			case B_ENUM: 					return node.name ~ "?" ~ Integer.toString( 12 + protAdd );
			case B_PARAM:					return node.name ~ "?18";
			case B_ENUMMEMBER:				return node.name ~ "?19";
			case B_ALIAS:					return node.name ~ "?20";
			case B_NAMESPACE:				return node.name ~ "?24";
			case B_INCLUDE, B_CTOR, B_DTOR:	return null;
			default:						return node.name ~ "?21";
		}

		return node.name;
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


	static char[] getFunctionTitle( Ihandle* iupSci, int pos )
	{
		char[] result = searchHead( iupSci, pos, "sub" );

		if( !result.length ) result = searchHead( iupSci, pos, "function" );
		if( !result.length ) result = searchHead( iupSci, pos, "property" );

		return result;
	}

	static CASTnode getFunctionAST( CASTnode head, char[] functionTitle, int line )
	{
		foreach_reverse( CASTnode node; head.getChildren() )
		{
			if( lowerCase( node.name ) == functionTitle )
			{
				if( line >= node.lineNumber ) return node;
			}

			if( node.getChildrenCount )
			{
				CASTnode _node = getFunctionAST( node, functionTitle, line );
				if( _node !is null ) return _node;
			}
		}

		return null;
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
					if( line >= child.lineNumber ) results ~= child;
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
				if( Util.index( lowerCase( child.name ), word ) == 0 )
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
		_path.set( GLOBAL.compilerFullPath );
		testPath = _path.path() ~ "inc/" ~ include;
				
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
				actionManager.OutlineAction.loadFile( includeFullPath );
				results ~= GLOBAL.parserManager[upperCase(includeFullPath)];
				results ~= getIncludes( GLOBAL.parserManager[upperCase(includeFullPath)], includeFullPath );

				includesMarkContainer[upperCase(includeFullPath)] = GLOBAL.parserManager[upperCase(includeFullPath)];
			}
		}

		return results;
	}

	static CASTnode[] getIncludes( CASTnode originalNode, char[] originalFullPath )
	{
		CASTnode[] results;

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
				else if( _node.type == "!__FB_WIN32__" )
				{
					version(Windows){}
					else
					{
						//Stdout( "Include((Linux)): " ~ _node.name ).newline;
						results ~= check( _node.name, originalFullPath );
					}
				}
				else
				{
					//Stdout( "Include(NORMAL): " ~ _node.name ).newline;
					results ~= check( _node.name, originalFullPath );
				}
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
		getIncludes( originalNode, originalFullPath );

		foreach( includeAST; includesMarkContainer )
		{
			foreach( child; includeAST.getChildren )
			{
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
		getIncludes( originalNode, originalFullPath );

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
		foreach( CASTnode _node; originalNode.getChildren() )
		{
			if( _node.kind & B_KIND )
			{
				if( lowerCase( removeArrayAndPointerWord( _node.name ) ) == lowerCase( word ) ) return _node;
			}
		}

		// Extends
		foreach( CASTnode _node; getBaseNodeMembers( originalNode ) )
		{
			if( _node.kind & B_KIND )
			{
				if( lowerCase( removeArrayAndPointerWord( _node.name ) ) == lowerCase( word ) ) return _node;
			}
		}

		return null;
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

				CASTnode[] resultIncludeNodes = getMatchIncludesFromWord( GLOBAL.parserManager[upperCase(cSci.getFullPath)], cSci.getFullPath, word );

				if( resultIncludeNodes.length )	resultNode = resultIncludeNodes[0];
			}
		}

		return resultNode;
	}

	static CASTnode getType( CASTnode originalNode )
	{
		CASTnode resultNode;

		switch( originalNode.kind )
		{
			case B_VARIABLE, B_PARAM:
				int countLoop = -1;
				foreach( char[] s; Util.split( originalNode.type, "." ) )
				{
					if( s.length )
					{
						if( ++countLoop == 0 )
						{
							char[] _type = removeArrayAndPointerWord( s );

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
							if( !stepByStep( resultNode, s, B_VARIABLE | B_FUNCTION | B_PROPERTY | B_TYPE | B_ENUM | B_UNION | B_CLASS | B_ALIAS ) ) return null;
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
		char[] result;
		
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
						result ~= ( _type ~ " " ~ groupAST[i].name ~ _paramString ~ "\n" );
					else
						result ~= ( "void " ~ groupAST[i].name ~ _paramString ~ "\n" );
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
							result ~= ( "Constructor" ~ _child.type ~ "\n" );
						}
					}
				}
			}
		}

		return result;
	}


	public:
	static bool bEnter;
	static bool bAutocompletionPressEnter;


	static char[] getWholeWordDoubleSide( Ihandle* iupSci, int pos = -1 )
	{
		int		countParen;
		int		oriPos = pos;
		bool	bForntEnd, bBackEnd;
		int		documentLength = IupScintillaSendMessage( iupSci, 2183, 0, 0 ); //SCI_GETTEXTLENGTH = 2183

		do
		{
			char[] s = fromStringz( IupGetAttributeId( iupSci, "CHAR", pos ) );

			switch( s )
			{
				case "(":
					countParen ++;
					break;

				case ")":
					countParen --;
					if( countParen < 0 ) bBackEnd = true;
					break;

				case ".":
					if( countParen == 0 ) bBackEnd = true;
					break;
				
				case "-":
					if( pos < documentLength )
					{
						if( fromStringz( IupGetAttributeId( iupSci, "CHAR", pos + 1 ) ) == ">" )
						{
							if( countParen == 0 )
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
				case " ", "\t", ":", "\n", "\r", "+", ">", "*", "/", "<":
					if( countParen == 0 ) bBackEnd = true;
					break;

				default:
			}

			if( bBackEnd ) break;
		}
		while( ++pos < documentLength )

		if( oriPos == pos ) return null;

		return getWholeWordReverse( iupSci, pos );
	}

	static char[] checkIsInclude( Ihandle* iupSci, int pos = -1 )
	{
		char[]	result;
		int		documentLength = IupScintillaSendMessage( iupSci, 2183, 0, 0 ); //SCI_GETTEXTLENGTH = 2183
		
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

	
	static char[] getWholeWordReverse( Ihandle* iupSci, int pos = -1 )
	{
		char[]	word;
		int		countParen;
		
		do
		{
			pos--;
			char[] s = fromStringz( IupGetAttributeId( iupSci, "CHAR", pos ) );
			switch( s )
			{
				case ")":
					countParen++;
					break;

				case "(":
					countParen--;
					if( countParen < 0 ) return word;
					break;
					
				case ">":
					if( pos > 0 && countParen == 0 )
					{
						if( fromStringz( IupGetAttributeId( iupSci, "CHAR", pos - 1 ) ) == "-" )
						{
							word ~= ">-";
							pos--;
							break;
						}
					}
				case " ", "\t", ":", "\n", "\r", "+", "-", "*", "/", "<":
					if( countParen == 0 ) return word;

				default: 
					if( countParen == 0 ) word ~= s;
			}
		}
		while( pos > -1 )

		return word;
	}
	
	static char[] charAdd( Ihandle* iupSci, int pos = -1, char[] text = "" )
	{
		char[] 	word, result;
		bool	bDot, bCallTip;

		if( text == "(" )
		{
			bCallTip = true;
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
			word = word ~ getWholeWordReverse( iupSci, pos - 1 );
		}
		else
		{
			word = word ~ getWholeWordReverse( iupSci, pos );
		}

		if( !bDot && !bCallTip )
		{
			if( word.length < GLOBAL.autoCompletionTriggerWordCount ) return null;
		}

		word = lowerCase( word.reverse );

		auto cSci = actionManager.ScintillaAction.getActiveCScintilla();
		if( cSci !is null )
		{
			if( !bDot && ( fromStringz( IupGetAttribute( iupSci, "AUTOCACTIVE" ) ) == "YES" ) )
			{
				/*
				foreach( CASTnode node; listContainer )
				{
					//result ~= ( getListImage( node ) ~ " " );
				}
				*/
				if( listContainer.length )
				{
					listContainer.sort;
					result ~= ( listContainer[0] ~ " " );
					for( int i = 1; i < listContainer.length; ++ i )
					{
						if( listContainer[i].length )
						{
							if( listContainer[i] != listContainer[i-1] ) result ~= ( listContainer[i] ~ " " );
						}
					}
				}
			}
			else
			{
				// Clean listContainer
				listContainer.length = 0;
				IupSetAttribute( iupSci, "AUTOCCANCEL", GLOBAL.cString.convert( "YES" ) );

				// Divide word
				char[][] splitWord = Util.split( word, "." );
				if( splitWord.length == 1 ) splitWord = Util.split( word, "->" );

				auto			AST_Head = GLOBAL.parserManager[upperCase(cSci.getFullPath)];
				char[]			functionTitle = getFunctionTitle( iupSci, pos );
				int				lineNum = IupScintillaSendMessage( iupSci, 2166, pos, 0 ) + 1; //SCI_LINEFROMPOSITION = 2166,

				if( functionTitle.length ) AST_Head = getFunctionAST( AST_Head, functionTitle, lineNum );

				if( AST_Head is null ) return null;

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

									result = callTipList( resultNodes ~ resultIncludeNodes );
									return Util.trim( result );
								}

								resultNodes			= getMatchASTfromWord( AST_Head, splitWord[i], lineNum );
								resultIncludeNodes	= getMatchIncludesFromWord( GLOBAL.parserManager[upperCase(cSci.getFullPath)], cSci.getFullPath, splitWord[i] );

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
								if( AST_Head is null ) return null;

								if( AST_Head.kind & ( B_VARIABLE | B_PARAM | B_FUNCTION ) )
								{
									AST_Head = getType( AST_Head );
									if( AST_Head is null ) return null;
								}

								if( AST_Head.kind & ( B_TYPE | B_ENUM | B_UNION | B_CLASS | B_NAMESPACE ) )
								{
									foreach( CASTnode _child; AST_Head.getChildren() ~ getBaseNodeMembers( AST_Head ) )
									{
										listContainer ~= getListImage( _child );
									}
								}
							}

							break;
						}

						AST_Head = searchMatchNode( AST_Head, splitWord[i], B_FIND ); // NOTE!!!! Using "searchMatchNode()"
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
							
							foreach( CASTnode _child; AST_Head.getChildren() ~ getBaseNodeMembers( AST_Head ) )
							{
								if( Util.index( lowerCase( _child.name ), splitWord[i] ) == 0 )
								{
									listContainer ~= getListImage( _child );
									//listContainer ~= _child;
								}
							}
						}
						else
						{
							if( !stepByStep( AST_Head, splitWord[i], B_VARIABLE | B_FUNCTION | B_PROPERTY ) ) return null;
							foreach( CASTnode _child; AST_Head.getChildren() )
							{
								listContainer ~= getListImage( _child );
								//listContainer ~= _child;
							}							
						}
						
					}
					else
					{
						if( !stepByStep( AST_Head, splitWord[i], B_VARIABLE | B_FUNCTION | B_PROPERTY ) ) return null;
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
					listContainer.sort;
					result ~= ( listContainer[0] ~ " " );
					for( int i = 1; i < listContainer.length; ++ i )
					{
						if( listContainer[i].length )
						{
							if( listContainer[i] != listContainer[i-1] ) result ~= ( listContainer[i] ~ " " );
						}
					}
				}
			}
			
			return Util.trim( result );
		}

		return null;
	}

	static void toDefintionAndType( bool bDefintion )
	{
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

				char[][] splitWord = Util.split( word, "." );
				if( splitWord.length == 1 ) splitWord = Util.split( word, "->" );

				auto			AST_Head = GLOBAL.parserManager[upperCase(cSci.getFullPath)];

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

				
				char[]			functionTitle = getFunctionTitle( cSci.getIupScintilla, currentPos );
				int				lineNum = IupScintillaSendMessage( cSci.getIupScintilla, 2166, currentPos, 0 ) + 1; //SCI_LINEFROMPOSITION = 2166,

				if( functionTitle.length ) AST_Head = getFunctionAST( AST_Head, functionTitle, lineNum );

				if( AST_Head is null ) return;


				for( int i = 0; i < splitWord.length; i++ )
				{
					if( i == 0 )
					{
						AST_Head = searchMatchNode( AST_Head, splitWord[i], B_FIND | B_SUB ); // NOTE!!!! Using "searchMatchNode()"
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
							AST_Head = searchMatchMemberNode( AST_Head, splitWord[i], B_VARIABLE | B_FUNCTION | B_PROPERTY | B_NAMESPACE );
						}
						
						if( AST_Head is null ) return;
					}

					if( bDefintion )
					{
						if( AST_Head.kind & ( B_VARIABLE | B_PARAM | B_FUNCTION ) )
						{
							AST_Head = getType( AST_Head );
							if( AST_Head is null ) return;
						}
					}
					else
					{
						if( i < splitWord.length )
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
					char[] _type = AST_Head.type;
					int openParenPos = Util.index( AST_Head.type, "(" );
					if( openParenPos < AST_Head.type.length ) _type = AST_Head.type[0..openParenPos];

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

					char[] _list = ( ( _type.length ? _type ~ " " : null ) ~ AST_Head.name ).dup;
					IupScintillaSendMessage( cSci.getIupScintilla, 2200, currentPos, cast(int) GLOBAL.cString.convert( _list ) ); // SCI_CALLTIPSHOW 2200
				}
				else
				{
					lineNum = AST_Head.lineNumber;
					
					while( AST_Head.getFather() !is null )
					{
						AST_Head = AST_Head.getFather();
					}

					actionManager.ScintillaAction.openFile( AST_Head.name, lineNum );
				}
			}
		}
		catch( Exception e )
		{
			IupMessage( "Error", toStringz( e.toString ) );
		}
	}
}