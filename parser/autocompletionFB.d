module parser.autocompletionFB;

version(FBIDE)
{
	import iup.iup;
	import iup.iup_scintilla;

	import global, actionManager, menu, tools;
	import tango.stdc.stringz, Util = tango.text.Util;


	struct AutoComplete
	{
		private:
		import tools;
		import parser.ast;
		import scintilla;

		import Integer = tango.text.convert.Integer, UTF = tango.text.convert.Utf, Float = tango.text.convert.Float;
		import tango.io.FilePath, tango.sys.Environment, Path = tango.io.Path;
		import tango.io.Stdout, tango.util.container.more.Stack;
		import tango.core.Thread;
		import tango.util.container.SortedMap;

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
		
		
		static CASTnode[]					extendedClasses;
		static SortedMap!(char[], char[])	map;
		static Stack!(char[])				calltipContainer;
		static char[]						noneListProcedureName;

		static char[][]						listContainer;
		static CASTnode[char[]]				includesMarkContainer;
		static bool[char[]]					noIncludeNodeContainer;
		static float[char[]]				VersionCondition;

		static char[]						showTypeContent;
		static char[]						includesFromPath;


		class CGetIncludes : Thread
		{
		private:
			CASTnode	AST_Head;
		
		public:
			this( CASTnode _AST_Head )
			{
				AST_Head = _AST_Head;
				super( &run );
			}

			void run()
			{
				AutoComplete.getIncludes( AST_Head, AST_Head.name, 0 );
			}
		}

		class CShowListThread : Thread
		{
		private:
			int			ext;
			char[]		text, extString;
			char[]		result;
			
			CASTnode	AST_Head;
			int			pos, lineNum;
			bool		bDot, bCallTip;
			char[][]	splitWord;
			
		public:
			this( CASTnode _AST_Head, int _pos, int _lineNum, bool _bDot, bool _bCallTip, char[][] _splitWord, char[] _text, int _ext = -1, char[] _extString = ""  )
			{
				AST_Head		= _AST_Head;
				pos				= _pos;
				lineNum			= _lineNum;
				bDot			= _bDot;
				bCallTip		= _bCallTip;
				splitWord		= _splitWord;
				text			= _text;
				ext				= _ext;
				_extString		= _extString;
				
				super( &run );
			}

			// If using IUP command in Thread, join() occur infinite loop, so......
			void run()
			{
				if( AST_Head is null )
				{
					if( GLOBAL.enableKeywordComplete == "ON" ) result = getKeywordContainerList( splitWord[0] );
					return;
				}
			
				if( GLOBAL.autoCompletionTriggerWordCount < 1 ) 
				{
					if( GLOBAL.enableKeywordComplete == "ON" ) result = getKeywordContainerList( splitWord[0] );
					return;
				}
				
				auto oriAST = AST_Head;
				
				version(VERSION_NONE) initIncludesMarkContainer( AST_Head, lineNum ); else checkVersionSpec( AST_Head, lineNum );
				
				result = analysisSplitWorld_ReturnCompleteList( AST_Head, splitWord, lineNum, bDot, bCallTip, true );
				char[][] usingNames = checkUsingNamespace( oriAST, lineNum );
				if( usingNames.length )
				{
					char[][] noUsingListContainer;
					if( splitWord.length == 1 )
					{
						if( !bDot && !bCallTip )
						{
							noUsingListContainer = listContainer.dup;
							listContainer.length = 0;
						}
						else if( bCallTip )
						{
							if( !result.length ) listContainer.length = 0;
						}
					}
					
					if( !listContainer.length )
					{
						foreach( char[] s; usingNames )
						{
							char[][] splitWithDot = Util.split( s, "." );
							char[][] namespaceSplitWord = splitWithDot ~ splitWord;
							char[] _result = analysisSplitWorld_ReturnCompleteList( oriAST, namespaceSplitWord, lineNum, bDot, bCallTip, true );
							
							if( bCallTip )
							{
								if( _result.length )
								{
									result = _result;
									break;
								}
							}
							
							if( listContainer.length )
							{
								listContainer = noUsingListContainer ~ listContainer;
								result = _result;
								break;
							}
						}
					}
					
					if( !listContainer.length ) listContainer = noUsingListContainer;			
				}				

				if( listContainer.length )
				{
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
									_type = listContainer[i][dollarPos+1..$];
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
						if( i < listContainer.length - 1 )
						{
							int questPos = Util.rindex( listContainer[i], "?0" );
							if( questPos < listContainer[i].length )
							{
								char[]	_keyWord = listContainer[i][0..questPos];
								char[]	compareWord;
								
								int tildePos = Util.rindex( listContainer[i+1], "~" );
								if( tildePos < listContainer[i+1].length )
									compareWord = listContainer[i+1][0..tildePos];
								else
								{
									questPos = Util.rindex( listContainer[i+1], "?" );
									if( questPos < listContainer[i+1].length ) compareWord = listContainer[i+1][0..questPos]; else compareWord = listContainer[i+1];
								}
								
								if( lowerCase( _keyWord ) == lowerCase( compareWord ) ) continue;
							}
						}

						if( listContainer[i].length )
						{
							if( GLOBAL.toggleShowListType == "ON" )
							{
								char[] _string;
								
								int dollarPos = Util.rindex( listContainer[i], "~" );
								if( dollarPos < listContainer[i].length )
								{
									_type = listContainer[i][dollarPos+1..$];
									_list = listContainer[i][0..dollarPos];
									_string = Util.trim( Stdout.layout.convert( formatString, _list, _type ) );
								}
								else
								{
									_string = listContainer[i];
								}

								result ~= ( _string ~ "^" );
							}
							else
							{
								result ~= ( listContainer[i] ~ "^" );
							}
						}
					}
				}

				if( result.length )
					if( result[$-1] == '^' ) result = result[0..$-1];
			}
			
			char[] getResult()
			{
				return result;
			}			
		}
		
		static CGetIncludes		preLoadContainerThread;
		static CShowListThread	showListThread;
		static CShowListThread	showCallTipThread;
		static Ihandle* timer = null;
		
		static void cleanIncludesMarkContainer( int level = -1)
		{
			foreach( char[] key; includesMarkContainer.keys )
				includesMarkContainer.remove( key );
			
			foreach( char[] key; noIncludeNodeContainer.keys )
				noIncludeNodeContainer.remove( key );
		}
		
		static bool checkExtendedClassesExist( CASTnode _node )
		{
			foreach( CASTnode a; extendedClasses )
			{
				if( a == _node ) return true;
			}
			
			return false;
		}
		
		
		static void getTypeAndParameter( CASTnode node, ref char[] _type, ref char[] _param )
		{
			if( node !is null )
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
		}
		
		static char[] getListImage( CASTnode node )
		{
			if( GLOBAL.toggleShowAllMember == "OFF" )
				if( node.protection == "private" ) return null;
				
			if( Util.count( node.name, "." ) > 0 ) return null;
			
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
				if( node.name[$-1] == ')' )
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
				case B_FUNCTION:			return bShowType ? name ~ "~" ~ type ~ "?" ~ Integer.toString( 28 + protAdd ) : name ~ "?" ~ Integer.toString( 28 + protAdd );
				case B_VARIABLE:
					if( node.name.length )
					{
						if( !type.length ) type = node.base; // VAR
						if( node.name[$-1] == ')' ) return bShowType ? name ~ "~" ~ type ~ "?" ~ Integer.toString( 1 + protAdd ) : name ~ "?" ~ Integer.toString( 1 + protAdd ); else return bShowType ? name ~ "~" ~ type ~ "?" ~ Integer.toString( 4 + protAdd ) : name ~ "?" ~ Integer.toString( 4 + protAdd );
					}
					break;

				case B_PROPERTY:
					if( node.type.length )
					{
						if( node.type[0] == '(' ) return name ~ "?31"; else	return name ~ "?32";
					}
					break;
					
				case B_CLASS:					return name ~ "?" ~ Integer.toString( 7 + protAdd );
				case B_TYPE: 					return name ~ "?" ~ Integer.toString( 10 + protAdd );
				case B_ENUM: 					return name ~ "?" ~ Integer.toString( 12 + protAdd );
				case B_PARAM:					return bShowType ? name ~ "~" ~ type ~ "?18" : name ~ "?18";
				case B_ENUMMEMBER:				return name ~ "?19";
				case B_ALIAS:					return bShowType ? name ~ "~" ~ type ~ "?20" : name ~ "?20";//name ~ "?20";
				case B_NAMESPACE:				return name ~ "?24";
				case B_INCLUDE, B_CTOR, B_DTOR:	return null;
				case B_OPERATOR:				return null;
				default:						return name ~ "?21";
			}

			return name;
		}

		static CASTnode[] anonymousEnumMembers( CASTnode originalNode )
		{
			if( originalNode is null ) return null;
			
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
			if( originalNode is null ) return null;
			
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

		static CASTnode getBaseNode( CASTnode originalNode )
		{
			if( originalNode is null ) return null;
			
			// Extends
			if( originalNode.base.length )
			{
				if( lowerCase( originalNode.base ) == "object" ) return null;
				
				if( originalNode.kind & ( B_TYPE | B_CLASS | B_UNION ) )
				{
					CASTnode	ret;
					
					// If the name of extends class with dot, it should be with namespace....
					if( Util.containsPattern( originalNode.base, "." ) )
					{
						ret = getExtendClass( originalNode, lowerCase( originalNode.base ) );
						if( ret is null )
						{
							ret = getExtendClass( originalNode, lowerCase( getNameSpaceWithDotTail( originalNode ) ~ originalNode.base ) );
							if( ret is null )
							{	
								char[][] usingNames = checkUsingNamespace( originalNode, originalNode.lineNumber );
								if( usingNames.length )
								{
									foreach( char[] s; usingNames )
									{
										ret = getExtendClass( originalNode, lowerCase( s ~ "." ~ originalNode.base ) );
										if( ret !is null ) return ret;
									}
								}	
							}
						}
					}
					else
					{
						char[][]	usingNames = checkUsingNamespace( originalNode, originalNode.lineNumber );
						char[]		NameSpaceString = getNameSpaceWithDotTail( originalNode );
						
						if( usingNames.length )
						{
							foreach( char[] s; usingNames )
							{
								ret = getExtendClass( originalNode, lowerCase( s ~ "." ~ originalNode.base ) );
								if( ret !is null ) return ret;
							}
						}
						
						
						if( NameSpaceString.length )
						{
							ret = getExtendClass( originalNode, lowerCase( NameSpaceString ~ originalNode.base ) );
						}
						
						if( ret is null ) ret = getExtendClass( originalNode, lowerCase( originalNode.base ) );
					}

					return ret;
				}
			}

			return null;
		}


		static CASTnode[] getBaseNodeMembers( CASTnode originalNode, int level = 0 )
		{
			if( originalNode is null ) return null;
		
			if( GLOBAL.includeLevel > 0 )
				if( level > GLOBAL.includeLevel - 1 ) return null;

			if( level > 2 ) return null; // MAX 3 STEP (0,1,2)
			
			CASTnode[] results;
			
			// Extends
			CASTnode mother = getBaseNode( originalNode );
			if( mother !is null )
			{
				if( !checkExtendedClassesExist( mother ) ) // Check to prevent infinite loop, EX: A extends B, B extends A......... or object extends object..........
				{
					extendedClasses ~= mother;
					
					foreach( CASTnode _node; mother.getChildren() )
					{
						if( _node.protection != "private" )
						{
							results ~= _node;
						}
					}
					
					results ~= getBaseNodeMembers( mother, ++level );
				}
			}

			return results;
		}


		static CASTnode[] getMatchASTfromWholeWord( CASTnode node, char[] word, int line, int B_KIND )
		{
			if( node is null ) return null;
			
			CASTnode[] results;
			
			foreach( child; getMembers( node ) )
			{
				if( child.kind & B_KIND )
				{
					if( lowerCase( ParserAction.removeArrayAndPointer( child.name ) ) == lowerCase( word ) )
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
			if( node is null ) return null;
			
			CASTnode[] results;
			
			foreach( child; getMembers( node ) )
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


		static CASTnode[] check( char[] name, char[] originalFullPath, int _LEVEL )
		{
			CASTnode[] results;
			
			char[] includeFullPath = checkIncludeExist( name, originalFullPath );

			if( includeFullPath.length )
			{
				bool bAlreadyExisted = ( fullPathByOS(includeFullPath) in includesMarkContainer ) ? true : false;
				
				if( GLOBAL.includeLevel < 0 )
					if( bAlreadyExisted ) return null;


				CASTnode includeAST;
				if( fullPathByOS(includeFullPath) in GLOBAL.parserManager )
				{
					if( !bAlreadyExisted )
					{
						includesMarkContainer[fullPathByOS(includeFullPath)] = GLOBAL.parserManager[fullPathByOS(includeFullPath)];
						results ~= GLOBAL.parserManager[fullPathByOS(includeFullPath)];
					}
					
					results ~= getIncludes( GLOBAL.parserManager[fullPathByOS(includeFullPath)], includeFullPath, _LEVEL );
				}
				else
				{
					CASTnode _createFileNode = GLOBAL.outlineTree.loadParser( includeFullPath );
					
					if( _createFileNode !is null )
					{
						includesMarkContainer[fullPathByOS(includeFullPath)] = _createFileNode;
						results ~= _createFileNode;
						results ~= getIncludes( _createFileNode, includeFullPath, _LEVEL );
					}
					else
					{
						includesMarkContainer[fullPathByOS(includeFullPath)] = null;
					}
				}
			}

			return results;
		}
		
		static CASTnode[] getInsertCodeBI( CASTnode originalNode, char[] originalFullPath, char[] word, bool bWholeWord, int ln = 2147483647 )
		{
			if( originalNode is null ) return null;
			
			bool bHasInclude;
			
			// Check Insert-Code-BI or not
			foreach( CASTnode _node; originalNode.getChildren )
			{
				if( _node.kind & B_INCLUDE )
				{
					bHasInclude = true;
					break;
				}
			}
			
			if( bHasInclude )
			{
				foreach( CASTnode _node; originalNode.getChildren )
				{
					if( _node.kind & B_VARIABLE )
					{
						if( !( _node.kind & B_DEFINE ) )
						{
							bHasInclude = false;
							break;
						}
					}
				}
			}

			// Insert-Code-BI, go
			if( !bHasInclude )
			{
				if( originalFullPath in noIncludeNodeContainer )
				{
				}
				else
				{
					if( GLOBAL.activeProjectPath in GLOBAL.projectManager )
					{
						foreach( char[] s; GLOBAL.projectManager[GLOBAL.activeProjectPath].sources ~ GLOBAL.projectManager[GLOBAL.activeProjectPath].includes )
						{
							if( s != originalFullPath )
							{
								CASTnode _createFileNode = GLOBAL.outlineTree.loadParser( s );
								if( _createFileNode !is null )
								{
									includesMarkContainer[fullPathByOS(s)] = _createFileNode;
									
									foreach( CASTnode _node; _createFileNode.getChildren )
									{
										if( _node.kind & B_INCLUDE ) 
										{
											char[] name = checkIncludeExist( _node.name, s );
											if( name == originalFullPath )
											{
												noIncludeNodeContainer[originalFullPath] = true;
												if( bWholeWord )
													return searchMatchMemberNodes( _createFileNode, word, B_ALL, true ) ~ getMatchIncludesFromWholeWord( _createFileNode, s, word, _node.lineNumber );
												else
													return searchMatchMemberNodes( _createFileNode, word, B_ALL, false ) ~ getMatchIncludesFromWord( _createFileNode, s, word, _node.lineNumber );
											}
										}
									}
								}
							}
						}
					}
				}
			}
			
			return null;
		}
		
		static CASTnode getMatchNodeInFile( CASTnode oriNode, char[][] nameSpaces, char[] word, char[] fileName, int B_KIND, bool bOnlyDeclare = false, bool bOnlyProcedureBody = true )
		{
			CASTnode _createFileNode = GLOBAL.outlineTree.loadParser( fileName );
		
			if( _createFileNode !is null )
			{
				for( int i = 0; i < nameSpaces.length; i ++ )
				{
					if( nameSpaces[i].length )
					{
						bool bMatch;
						foreach( CASTnode _node; _createFileNode.getChildren )
						{
							if( _node.kind & B_NAMESPACE )
							{
								if( _node.name == nameSpaces[i] )
								{
									_createFileNode = _node;
									bMatch = true;
									break;
								}
							}
						}
						
						if( !bMatch ) break;
					}
				}
				
				CASTnode[] matchASTs;
				foreach( CASTnode _node; getMembers( _createFileNode ) )
				{
					if( _node.kind & B_KIND ) 
					{
						if( lowerCase( word ) == lowerCase( _node.name ) )
						{
							if( bOnlyProcedureBody )
							{
								if( _node.lineNumber < _node.endLineNum ) matchASTs ~= _node;
							}
							else if( bOnlyDeclare )
							{
								if( _node.lineNumber == _node.endLineNum ) matchASTs ~= _node;
							}
							else
							{
								matchASTs ~= _node;
							}
						}
					}
				}
				
				foreach( CASTnode a; matchASTs )
					if( lowerCase( oriNode.type ) == lowerCase( a.type ) ) return a;
				
				if( matchASTs.length ) return matchASTs[0];
			}
			
			return null;
		}
		
		static CASTnode getMatchNodeInProject( CASTnode oriNode, char[][] nameSpaces, char[] word, char[] prjName, int B_KIND, char[][] exceptFileNames, bool bOnlyDeclare = false, bool bOnlyProcedureBody = true )
		{
			if( prjName in GLOBAL.projectManager )
			{
				foreach( char[] s; GLOBAL.projectManager[prjName].sources ~ GLOBAL.projectManager[prjName].includes )
				{
					foreach( char[] e; exceptFileNames )
						if( s == e ) continue;
					
					
					CASTnode _createFileNode = getMatchNodeInFile( oriNode, nameSpaces, word, s, B_KIND, bOnlyDeclare, bOnlyProcedureBody );
					if( _createFileNode !is null ) return _createFileNode;
				}
			}
			
			return null;
		}

		static CASTnode[] getMatchIncludesFromWholeWord( CASTnode originalNode, char[] originalFullPath, char[] word, int ln = 2147483647 )
		{
			if( originalNode is null ) return null;

			char[][] prevKeys = includesMarkContainer.keys;
			CASTnode[] results = getInsertCodeBI( originalNode, originalFullPath, word, true, ln );
			if( results.length )
				return results;
			else
			{
				foreach( char[] key; includesMarkContainer.keys )
				{
					bool bRemove = true;
					foreach( char[] pKey; prevKeys )
					{
						if( pKey == key )
						{
							bRemove = false;
							break;
						}
					}
					if( bRemove ) includesMarkContainer.remove( key );
				}
			}

			/+
			foreach( char[] key; includesMarkContainer.keys )
				includesMarkContainer.remove( key );		
			+/
			
			// Parse Include
			//CASTnode[] includeASTnodes = getIncludes( originalNode, originalFullPath );
			auto dummyASTs = getIncludes( originalNode, originalFullPath, 0 );

			foreach( includeAST; includesMarkContainer )
			{
				if( includeAST !is null )
				{
					foreach( child; getMembers( includeAST ) )
					{
						if( child.name.length )
						{
							if( lowerCase( ParserAction.removeArrayAndPointer( child.name ) ) == lowerCase( word ) ) results ~= child;
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

		static CASTnode[] getMatchIncludesFromWord( CASTnode originalNode, char[] originalFullPath, char[] word, int ln = 2147483647 )
		{
			if( originalNode is null ) return null;
			
			char[][] prevKeys = includesMarkContainer.keys;
			CASTnode[] results = getInsertCodeBI( originalNode, originalFullPath, word, false, ln );
			if( results.length )
				return results;
			else
			{
				foreach( char[] key; includesMarkContainer.keys )
				{
					bool bRemove = true;
					foreach( char[] pKey; prevKeys )
					{
						if( pKey == key )
						{
							bRemove = false;
							break;
						}
					}
					if( bRemove ) includesMarkContainer.remove( key );
				}
			}			
			
			auto dummyASTs = getIncludes( originalNode, originalFullPath, 0 );

			/*
			foreach( CASTnode n; includesMarkContainer )
				Stdout( n.name ).newline;
			*/
			
			foreach( includeAST; includesMarkContainer )
			{
				if( includeAST !is null )
				{
					foreach( child; getMembers( includeAST ) )
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
									/*
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
									*/
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

		static bool isDefaultType( char[] _type )
		{
			_type = lowerCase( _type );
			
			if( _type == "byte" || _type == "ubyte" || _type == "short" || _type == "ushort" || _type == "integer" || _type == "uinteger" || _type == "longint" || _type == "ulongint" ||
				_type == "single" || _type == "double" || _type == "string" || _type == "zstring" || _type == "wstring" || _type == "boolean" ) return true;

			return false;
		}
		

		static CASTnode searchMatchMemberNode( CASTnode originalNode, char[] word, int B_KIND = B_ALL, bool bSkipExtend = false )
		{
			if( originalNode is null ) return null;
			
			foreach( CASTnode _node; getMembers( originalNode, bSkipExtend ) )
			{
				if( _node.kind & B_KIND )
				{
					char[] name = lowerCase( ParserAction.removeArrayAndPointer( _node.name ) );
					
					if( name.length )
					{
						if( name == lowerCase( word ) ) return _node;
					}
					else
					{
						foreach( CASTnode _enumMember; anonymousEnumMembers( _node ) )
						{
							if( lowerCase( _enumMember.name ) == lowerCase( word ) ) return _enumMember;
						}
					}
				}
			}

			return null;
		}

		static CASTnode[] searchMatchMemberNodes( CASTnode originalNode, char[] word, int B_KIND = B_ALL, bool bWholeWord = true, bool bSkipExtend = false )
		{
			if( originalNode is null ) return null;
			
			CASTnode[] results;
			
			word = lowerCase( word );
			
			foreach( CASTnode _node; getMembers( originalNode, bSkipExtend ) )
			{
				if( _node.kind & B_KIND )
				{
					char[] name = lowerCase( ParserAction.removeArrayAndPointer( _node.name ) );

					if( bWholeWord )
					{
						if( name == word ) results ~= _node;
					}
					else
					{
						//if( Util.index( name, lowerCase( word ) ) == 0 ) results ~= _node;
						if( name.length )
						{
							if( Util.index( name, word ) == 0 ) results ~= _node;
						}
						else
						{
							if( _node.kind & B_ENUM )
							{
								CASTnode[] enumResult = getAnonymousEnumMemberFromWord( _node, word );
								if( enumResult.length ) results ~= enumResult;
							}
						}					
					}
				}
			}

			return results;
		}
		

		static CASTnode searchMatchNode( CASTnode originalNode, char[] word, int B_KIND = B_ALL, bool bSkipExtend = true )
		{
			if( originalNode is null ) return null;
			
			CASTnode resultNode = searchMatchMemberNode( originalNode, word, B_KIND, bSkipExtend );

			if( resultNode is null )
			{
				if( originalNode.getFather() !is null )
				{
					resultNode = searchMatchNode( originalNode.getFather(), word, B_KIND, bSkipExtend );
				}
				else
				{
					auto cSci = actionManager.ScintillaAction.getActiveCScintilla();

					//CASTnode[] resultIncludeNodes = getMatchIncludesFromWord( GLOBAL.parserManager[fullPathByOS(cSci.getFullPath)], cSci.getFullPath, word );
					if( fullPathByOS(cSci.getFullPath) in GLOBAL.parserManager ) 
					{
						CASTnode[] resultIncludeNodes = getMatchIncludesFromWholeWord( GLOBAL.parserManager[fullPathByOS(cSci.getFullPath)], cSci.getFullPath, word, B_KIND );
						if( resultIncludeNodes.length )	resultNode = resultIncludeNodes[0];
					}
				}
			}

			return resultNode;
		}
		
		
		static CASTnode[] searchMatchNodes( CASTnode originalNode, char[] word, int B_KIND = B_ALL, bool bSkipExtend = false )
		{
			if( originalNode is null ) return null;
			
			CASTnode[] resultNodes = searchMatchMemberNodes( originalNode, word, B_KIND, true, bSkipExtend );

			if( originalNode.getFather() !is null )
			{
				resultNodes ~= searchMatchNodes( originalNode.getFather(), word, B_KIND, bSkipExtend );
			}
			else
			{
				auto cSci = actionManager.ScintillaAction.getActiveCScintilla();

				//CASTnode[] resultIncludeNodes = getMatchIncludesFromWord( GLOBAL.parserManager[fullPathByOS(cSci.getFullPath)], cSci.getFullPath, word );
				if( fullPathByOS(cSci.getFullPath) in GLOBAL.parserManager ) 
				{
					CASTnode[] resultIncludeNodes = getMatchIncludesFromWholeWord( GLOBAL.parserManager[fullPathByOS(cSci.getFullPath)], cSci.getFullPath, word, B_KIND );
					if( resultIncludeNodes.length )	resultNodes ~= resultIncludeNodes;
				}
			}
			
			return resultNodes;
		}


		static CASTnode[] getMembers( CASTnode AST_Head, bool bSkipExtend = false )
		{
			if( AST_Head is null ) return null;
			
			CASTnode[] result;
			
			CASTnode[] childrenNodes = AST_Head.getChildren();
			if( AST_Head.kind & ( B_TYPE | B_CLASS ) )
				if( !bSkipExtend ) childrenNodes ~= getBaseNodeMembers( AST_Head ); 
			

			for( int i = 0; i < childrenNodes.length; ++ i )
			{
				if( childrenNodes[i].kind == B_VERSION )
				{
					version(VERSION_NONE)
					{
					}
					else
					{
						char[] symbol = upperCase( childrenNodes[i].name );
						char[] noSignSymbolName = childrenNodes[i].type.length ? symbol[1..$] : symbol;
						if( noSignSymbolName == "__FB_WIN32__" || noSignSymbolName == "__FB_LINUX__" || noSignSymbolName == "__FB_FREEBSD__" || noSignSymbolName == "__FB_OPENBSD__" || noSignSymbolName == "__FB_UNIX__" )
						{
							version(Windows)
							{
								if( symbol == "__FB_WIN32__" || ( symbol != "!__FB_WIN32__" ) )
								{
									result ~= getMembers( childrenNodes[i], bSkipExtend );
									continue;
								}
							}
							
							version(linux)
							{
								if( symbol == "__FB_LINUX__" || ( symbol != "!__FB_LINUX__" ) )
								{
									result ~= getMembers( childrenNodes[i], bSkipExtend );
									continue;
								}
							}
							
							version(FreeBSD)
							{
								if( symbol == "__FB_FREEBSD__" || ( symbol != "!__FB_FREEBSD__" ) )
								{
									result ~= getMembers( childrenNodes[i], bSkipExtend );
									continue;
								}
							}
							
							version(OpenBSD)
							{
								if( symbol == "__FB_OPENBSD__" || ( symbol != "!__FB_OPENBSD__" ) )
								{
									result ~= getMembers( childrenNodes[i], bSkipExtend );
									continue;
								}
							}
							
							version(Posix)
							{
								if( symbol == "__FB_UNIX__" || ( symbol != "!__FB_UNIX__" ) )
								{
									result ~= getMembers( childrenNodes[i], bSkipExtend );
									continue;
								}
							}
						}
						else
						{
							if( !childrenNodes[i].type.length )
							{
								if( symbol in AutoComplete.VersionCondition ) result ~= getMembers( childrenNodes[i], bSkipExtend );
							}
							else
							{
								if( VersionCondition.length )
								{
									if( !( symbol[1..$] in AutoComplete.VersionCondition ) ) result ~= getMembers( childrenNodes[i], bSkipExtend );
								}
								else
								{
									result ~= getMembers( childrenNodes[i], bSkipExtend );
								}
							}
						}
					}
				}
				/+
				else if( childrenNodes[i].kind == ( B_VERSION | B_PARAM ) )
				{
					// activeASTnode.addChild( _identifier, B_VERSION | B_PARAM, _sign, _body, "#if", token().lineNumber );
					char[] _ident, _sign, _body;
					char[] symbol = upperCase( childrenNodes[i].name );
					if( symbol in VersionCondition )
					{
						_body = childrenNodes[i].type;
						_sign = childrenNodes[i].protection;
						
						try
						{
							if( childrenNodes[i].base == "#if" || childrenNodes[i].base == "#elseif" )
							{
								switch( _sign )
								{
									case ">":
										if( VersionCondition[symbol] > Float.toFloat( _body ) ) 
										{
											result ~= getMembers( childrenNodes[i], bSkipExtend );
											i = skipPreprocessorCondition( childrenNodes, i );
										}
										break;
										
									case ">=":
										if( VersionCondition[symbol] >= Float.toFloat( _body ) )
										{
											result ~= getMembers( childrenNodes[i], bSkipExtend );
											i = skipPreprocessorCondition( childrenNodes, i );
										}
										break;
										
									case "<":
										if( VersionCondition[symbol] < Float.toFloat( _body ) )
										{
											result ~= getMembers( childrenNodes[i], bSkipExtend );
											i = skipPreprocessorCondition( childrenNodes, i );
										}
										break;
										
									case "<=":
										if( VersionCondition[symbol] <= Float.toFloat( _body ) )
										{
											result ~= getMembers( childrenNodes[i], bSkipExtend );
											i = skipPreprocessorCondition( childrenNodes, i );
										}
										break;

									case "<>":
										if( VersionCondition[symbol] != Float.toFloat( _body ) )
										{
											result ~= getMembers( childrenNodes[i], bSkipExtend );
											i = skipPreprocessorCondition( childrenNodes, i );
										}
										break;

									case "=":
										if( VersionCondition[symbol] == Float.toFloat( _body ) )
										{
											result ~= getMembers( childrenNodes[i], bSkipExtend );
											i = skipPreprocessorCondition( childrenNodes, i );
										}
										break;

									default:
								}
							}
							else if( childrenNodes[i].base == "#else" )
							{
								result ~= getMembers( childrenNodes[i], bSkipExtend );
							}
						}
						catch( Exception e )
						{}
					}
				}
				+/
				else if( childrenNodes[i].kind & ( B_UNION | B_TYPE | B_CLASS ) )
				{
					if( !childrenNodes[i].name.length ) result ~= getMembers( childrenNodes[i], bSkipExtend ); else result ~= childrenNodes[i];
				}
				else
				{
					result ~= childrenNodes[i];
				}
			}

			return result;
		}
		
		
		static int skipPreprocessorCondition( CASTnode[] nodeGroup, int oriIndex )
		{
			int ret = oriIndex;
			
			if( oriIndex + 1 < nodeGroup.length )
			{
				while( nodeGroup[++oriIndex].kind == ( B_VERSION | B_PARAM ) )
				{
					if( nodeGroup[oriIndex].base != "#if" ) ret = oriIndex; else break;
					if( oriIndex + 1 >= nodeGroup.length ) break;
				}
			}
			
			return ret;
		}
		

		static CASTnode getType( CASTnode originalNode, int lineNum )
		{
			if( originalNode is null ) return null;
			
			CASTnode resultNode;

			if( originalNode.kind & ( B_ALIAS | B_VARIABLE | B_PARAM | B_FUNCTION ) )
			{
				char[][]	splitWord;
				char[]		_type;
				
				auto oriAST = originalNode;
				
				if( originalNode.type.length ) _type = originalNode.type; else _type = Util.stripl( originalNode.base, '*' ); // remove leftside *
				
				splitWord = ParserAction.getDivideWordWithoutSymbol( _type );
				/*
				foreach( char[] s; splitWord )
					if( s == originalNode.name ) return null;
				*/
				
				char[][] usingNames = checkUsingNamespace( oriAST, lineNum );
				if( usingNames.length )
				{
					foreach( char[] s; usingNames )
					{
						originalNode = oriAST;
						char[][] splitWithDot = Util.split( s, "." );
						char[][] namespaceSplitWord = splitWithDot ~ splitWord;
						analysisSplitWorld_ReturnCompleteList( originalNode, namespaceSplitWord, lineNum, true, false, false );
						if( originalNode !is null ) return originalNode;
					}
				}
				
				// No Using or No results found...
				originalNode = oriAST;
				analysisSplitWorld_ReturnCompleteList( originalNode, splitWord, lineNum, true, false, false );
				
				if( originalNode is oriAST ) return oriAST; // Prevent infinite loop
				
				/*
				analysisSplitWorld_ReturnCompleteList( originalNode, splitWord, lineNum, true, false, false );
				
				if( oriAST == originalNode ) return oriAST; // Prevent infinite loop
				
				if( originalNode is null )
				{
					char[][] usingNames = checkUsingNamespace( oriAST, lineNum );
					if( usingNames.length )
					{
						foreach( char[] s; usingNames )
						{
							originalNode = oriAST;
							char[][] splitWithDot = Util.split( s, "." );
							char[][] namespaceSplitWord = splitWithDot ~ splitWord;
							analysisSplitWorld_ReturnCompleteList( originalNode, namespaceSplitWord, lineNum, true, false, false );
							if( originalNode !is null ) break;
						}
					}
				}
				*/
				
				if( originalNode !is null ) resultNode = originalNode;// else resultNode = oriAST;
			}			
			
			return resultNode;
		}

		static bool stepByStep( ref CASTnode AST_Head, char[] word, int B_KIND, int lineNum )
		{
			AST_Head = searchMatchMemberNode( AST_Head, word, B_KIND );
			if( AST_Head is null ) return false;

			if( AST_Head.kind & ( B_VARIABLE | B_PARAM | B_FUNCTION ) )
			{
				if( !isDefaultType( ParserAction.getSeparateType( AST_Head.type, true ) ) )
				{
					AST_Head = getType( AST_Head, lineNum );
					if( AST_Head is null ) return false;
				}
				else
				{
					return false;
				}
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
		
		static void callTipSetHLT( char[] list, int itemNO, ref int highlightStart, ref int highlightEnd )
		{
			int listHead;
			foreach( char[] lineText; Util.splitLines( list ) )
			{
				int openParenPos = Util.index( lineText, "(" );
				int closeParenPos = Util.rindex( lineText, ")" );
				if( closeParenPos > openParenPos + 1 && openParenPos > 0 )
				{
					openParenPos += listHead;
					closeParenPos += listHead;
					
					int parenCount;
					int	paramCount;
					
					for( int i = openParenPos + 1; i < closeParenPos; ++i )
					{
						if( i == openParenPos + 1 )	highlightStart = i;
						 
						switch( list[i] )
						{
							case ',':
								if( parenCount == 0 )
								{
									if( ++paramCount == itemNO )
									{
										highlightEnd = i;
										return;
									}
									else
									{
										highlightStart = i + 1;
									}
								}
								break;
							case '(':
								parenCount ++;
								break;
							case ')':
								parenCount --;
								break;
							default:
						
						}
					}

					if( parenCount == 0 )
					{
						if( ++paramCount == itemNO )
						{
							highlightEnd = closeParenPos;
							return;
						}
					}					
					
				}
				
				listHead += lineText.length;
				for( int i = listHead; i < list.length; ++ i )
				{
					if( list[i] == '\n' || list[i] == '\r' ) listHead ++; else break;
				}
			}
			
			highlightEnd = -1;
		}
		
		static char[] parseProcedureForCalltip( Ihandle* ih, int lineHeadPos, char[] lineHeadText, ref int commaCount, ref int parenCount, ref int firstOpenParenPos )
		{
			if( ih == null ) return null;
			
			bool	bGetName;
			char[]	procedureName;
			
			if( lineHeadPos == -1 )	lineHeadPos = cast(int) IupScintillaSendMessage( ih, 2167, ScintillaAction.getCurrentLine( ih ) - 1, 0 );
			
			for( int i = lineHeadText.length - 1; i >= 0; --i ) //SCI_POSITIONFROMLINE 2167
			{
				if( !bGetName )
				{
					switch( lineHeadText[i] )
					{
						case ')':
							parenCount --;
							break;

						case '(':
							parenCount ++;
							if( parenCount == 1 )
							{
								commaCount ++;
								firstOpenParenPos = lineHeadPos + i;
								bGetName = true;
							}
							break;
							
						case ',':
							if( parenCount == 0 ) commaCount ++;
							break;

						default:
					}
				}
				else
				{
					if( lineHeadText[i] == ' ' || lineHeadText[i] == '\t' || lineHeadText[i] == '\n' || lineHeadText[i] == '\r' || lineHeadText[i] == '.'  || lineHeadText[i] == ':' )
						break;
					else
						procedureName = lineHeadText[i] ~ procedureName;
				}
			}
			
			return procedureName;
		}		
		
		static char[] parseProcedureForCalltip( Ihandle* ih, int pos, ref int commaCount, ref int parenCount, ref int firstOpenParenPos )
		{
			if( ih == null ) return null;
			
			//int pos = ScintillaAction.getCurrentPos( ih );
			
			bool	bGetName;
			char[]	procedureName;
			
			for( int i = pos; i >= cast(int) IupScintillaSendMessage( ih, 2167, ScintillaAction.getCurrentLine( ih ) - 1, 0 ); --i ) //SCI_POSITIONFROMLINE 2167
			{
				char[] s = fromStringz( IupGetAttributeId( ih, "CHAR", i ) );
				if( !bGetName )
				{
					switch( s )
					{
						case ")":
							parenCount --;
							break;

						case "(":
							parenCount ++;
							if( parenCount == 1 )
							{
								commaCount ++;
								firstOpenParenPos = i;
								bGetName = true;
							}
							break;
							
						case ",":
							if( parenCount == 0 ) commaCount ++;
							break;

						default:
					}
				}
				else
				{
					if( s == " " || s == "\t" || s == "\n" || s == "\r"  || s == "." || s == ":" )
						break;
					else
						procedureName = s ~ procedureName;
				}
			}
			
			return procedureName;
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
							listContainer ~= ( s ~ "?0" );
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


		static char[][] getNeedDataForThread( Ihandle* iupSci, char[] text, int pos, ref int lineNum, ref bool bDot, ref bool bCallTip, ref CASTnode AST_Head )
		{
			int		dummyHeadPos;
			char[] 	word, result;

			if( text == "(" )
			{
				bCallTip = true;
				IupSetAttribute( iupSci, "AUTOCCANCEL", "YES" ); // Prevent autocomplete -> calltip issue
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
			
			word = lowerCase( word.dup.reverse );

			auto cSci = actionManager.ScintillaAction.getActiveCScintilla();
			if( cSci !is null )
			{
				if( !bDot && ( fromStringz( IupGetAttribute( iupSci, "AUTOCACTIVE" ) ) == "YES" ) )
				{}
				else
				{
					// Clean listContainer
					listContainer.length = 0;
					IupSetAttribute( iupSci, "AUTOCCANCEL", "YES" );

					lineNum = IupScintillaSendMessage( iupSci, 2166, pos, 0 ) + 1; //SCI_LINEFROMPOSITION = 2166,
					AST_Head = ParserAction.getActiveASTFromLine( ParserAction.getActiveParseAST(), lineNum );
					
					return getDivideWord( word );
				}
			}
			
			return null;
		}
		

		static void checkVersionSpec( CASTnode AST_Head, int lineNum )
		{
			if( AST_Head is null ) return;
			
			foreach( CASTnode _friends; getMembers( AST_Head ) )
			{
				if( _friends.kind == ( B_DEFINE | B_VERSION ) )
					if( _friends.lineNumber < lineNum ) VersionCondition[upperCase(_friends.name)] = 1;
			}
			
			if( AST_Head.getFather !is null )
				checkVersionSpec( AST_Head.getFather, lineNum );
			else
			{
				//initIncludesMarkContainer( AST_Head, lineNum );
				
				if( includesFromPath != AST_Head.name ) includesFromPath = AST_Head.name;
				cleanIncludesMarkContainer();
				
				if( GLOBAL.includeLevel != 0 )
				{
					int oriIncludeLevel = GLOBAL.includeLevel;
					
					// Heavy slow down the spped, only check only 2-steps
					// if( GLOBAL.includeLevel > 2 ) GLOBAL.includeLevel = 2; // Comment this line to get full-check
					auto dummy = getIncludes( AST_Head, AST_Head.name, 0 );
					
					foreach( _includeNode; includesMarkContainer )
					{
						foreach( CASTnode _friends; getMembers( _includeNode, true ) )
						{
							if( _friends.kind == ( B_DEFINE | B_VERSION ) ) 
							{
								if( _friends.getFather.kind == B_VERSION )
									if( _friends.getFather.type.length )
										if( upperCase( _friends.name ) == upperCase( _friends.getFather.name[1..$] ) ) continue; // Skip the C-style include once
								
								VersionCondition[upperCase(_friends.name)] = 1; // Much VersionCondition, performance loss
							}
						}
					}
					
					GLOBAL.includeLevel = oriIncludeLevel;
				}
			}
		}
		
		
		static void initIncludesMarkContainer( CASTnode AST_Head, int lineNum )
		{
			if( includesFromPath != AST_Head.name ) includesFromPath = AST_Head.name;
			cleanIncludesMarkContainer();
			
			if( GLOBAL.includeLevel != 0 )
			{
				//int oriIncludeLevel = GLOBAL.includeLevel;
				
				// Heavy slow down the spped, only check only 2-steps
				// if( GLOBAL.includeLevel > 2 ) GLOBAL.includeLevel = 2; // Comment this line to get full-check
				auto dummy = getIncludes( AST_Head, AST_Head.name, 0 );
				//GLOBAL.includeLevel = oriIncludeLevel;
			}			
		}
		
		
		static char[][] checkUsingNamespace( CASTnode AST_Head, int lineNum )
		{
			char[][] results;
			
			foreach( CASTnode _friends; AST_Head.getChildren )
			{
				if( _friends.kind & B_USING )
					if( _friends.lineNumber < lineNum ) results ~= _friends.name;
			}
			
			if( AST_Head.getFather !is null ) results ~= checkUsingNamespace( AST_Head.getFather, lineNum );
		
			return results;
		}
		

		static char[] getNameSpaceWithDotTail( CASTnode AST_Head )
		{
			char[] result;
			
			if( AST_Head !is null )
			{
				if( AST_Head.getFather !is null )
				{
					while( AST_Head.getFather.kind & B_NAMESPACE )
					{
						AST_Head = AST_Head.getFather;
						result = AST_Head.name ~ "." ~ result;
						if( AST_Head.getFather is null ) break;
					}
				}
			}
		
			return result;
		}
		
		
		static CASTnode getExtendClass( CASTnode _AST_Head, char[] baseName )
		{
			char[][]	_splitWord = Util.split( baseName, "." );
			CASTnode[]	matchNodes;
			
			for( int i = 0; i < _splitWord.length; i++ )
			{
				if( i == 0 )
				{
					//matchNodes = _searchMatchNodes( _AST_Head, _splitWord[i], B_NAMESPACE | B_CLASS | B_TYPE | B_UNION );
					matchNodes = searchMatchNodes( _AST_Head, _splitWord[i], B_NAMESPACE | B_CLASS | B_TYPE | B_UNION, true );
					if( !matchNodes.length ) return null; 
					if( _splitWord.length == 1 ) break;
				}
				else
				{
					CASTnode[] tempMatchNodes = matchNodes.dup;
					matchNodes.length = 0;
					foreach( CASTnode a; tempMatchNodes )
					{
						auto matchNode = searchMatchMemberNode( a, _splitWord[i], B_NAMESPACE | B_CLASS | B_TYPE | B_UNION, true );
						if( matchNode !is null )
						{
							if( i == _splitWord.length - 1 ) return matchNode;
							matchNodes ~= matchNode;
						}
					}
					
					if( !matchNodes.length ) return null;
				}
			}
			
			if( matchNodes.length ) return matchNodes[0];
			
			return null;
		}		

		
		static char[] analysisSplitWorld_ReturnCompleteList( ref CASTnode AST_Head, char[][] splitWord, int lineNum, bool bDot, bool bCallTip, bool bPushContainer  )
		{
			if( AST_Head is null ) return null;
			
			auto		function_originalAST_Head = AST_Head;
			auto		_rootNode = ParserAction.getRoot( function_originalAST_Head );
			char[]		fullPath = _rootNode !is null ? _rootNode.name : "";
			
			
			if( bPushContainer )
			{
				if( map is null ) map = new SortedMap!(char[], char[]); else map.reset();
			}
			
			extendedClasses.length = 0;
			
			char[]		memberFunctionMotherName, result;

			if( !splitWord[0].length )
			{
				if( AST_Head.kind & B_WITH )
				{
					char[][] splitWithTile = getDivideWord( AST_Head.name );
					char[][] tempSplitWord = splitWord;
					splitWord.length = 0;						
					foreach( char[] s; splitWithTile ~ tempSplitWord )
					{
						if( s != "" ) splitWord ~= ParserAction.removeArrayAndPointer( s );
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
				while( _fatherNode.kind & ( B_WITH | B_SCOPE ) );
			}
			
			if( _fatherNode.getFather !is null )
			{
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
			}
			
			if( includesFromPath != fullPath )
			{
				includesFromPath = fullPath;
				cleanIncludesMarkContainer();
			}
			
			CASTnode[] nameSpaceNodes;
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
								if( !bPushContainer ) return null;
								
								if( GLOBAL.objectDefaultParser !is null )
									resultNodes	= getMatchASTfromWholeWord( GLOBAL.objectDefaultParser, splitWord[i], -1, B_FUNCTION | B_SUB | B_DEFINE );

								resultNodes			~= getMatchASTfromWholeWord( AST_Head, splitWord[i], lineNum, B_FUNCTION | B_SUB | B_PROPERTY | B_TYPE | B_CLASS | B_UNION | B_NAMESPACE | B_DEFINE );
								if( fullPathByOS(fullPath) in GLOBAL.parserManager ) resultIncludeNodes	= getMatchIncludesFromWholeWord( GLOBAL.parserManager[fullPathByOS(fullPath)], fullPath, splitWord[i], B_FUNCTION | B_SUB | B_PROPERTY | B_TYPE | B_CLASS | B_UNION | B_NAMESPACE | B_DEFINE );

								// For Type Objects
								if( memberFunctionMotherName.length )
								{
									// "_searchMatchNode" also search includes
									//CASTnode classNode = _searchMatchNode( AST_Head, memberFunctionMotherName, B_TYPE | B_CLASS );
									CASTnode classNode = searchMatchNode( AST_Head, memberFunctionMotherName, B_TYPE | B_CLASS, true );
									if( classNode !is null ) resultNodes ~= searchMatchMemberNodes( classNode, splitWord[i], B_ALL );
								}

								result = callTipList( resultNodes ~ resultIncludeNodes, splitWord[i] );
								return Util.trim( result );
							}


							if( GLOBAL.enableKeywordComplete == "ON" )
							{
								if( bPushContainer )
								{
									foreach( char[] _s; GLOBAL.KEYWORDS )
									{
										foreach( char[] s; Util.split( _s, " " ) )
										{
											if( s.length )
											{
												if( Util.index( lowerCase( s ), lowerCase( splitWord[i] ) ) == 0 )
												{
													s = tools.convertKeyWordCase( GLOBAL.keywordCase, s );
													map.add( upperCase( s ~ "?0" ), s ~ "?0" );
													//listContainer ~= ( s ~ "?0" );
												}
											}
										}
									}							
									//keyWordlist( splitWord[i] );
								}
							}

							if( AST_Head !is null )
							{
								resultNodes			= getMatchASTfromWord( AST_Head, splitWord[i], lineNum );
								
								if( fullPathByOS(fullPath) in GLOBAL.parserManager ) resultIncludeNodes	= getMatchIncludesFromWord( GLOBAL.parserManager[fullPathByOS(fullPath)], fullPath, splitWord[i] );
								
								// For Type Objects
								if( memberFunctionMotherName.length )
								{
									//CASTnode classNode = _searchMatchNode( AST_Head, memberFunctionMotherName, B_TYPE | B_CLASS );
									CASTnode classNode = searchMatchNode( AST_Head, memberFunctionMotherName, B_TYPE | B_CLASS, true );
									if( classNode !is null ) resultNodes ~= searchMatchMemberNodes( classNode,  splitWord[i] , B_ALL, false );
								}
								
								if( bPushContainer )
								{
									foreach( CASTnode _node; resultNodes ~ resultIncludeNodes )
									{
										char[] _list = getListImage( _node );
										map.add( upperCase( _list ), _list );
									}
								}
							}
						}
						else
						{
							// Get Members
							//AST_Head = searchMatchNode( AST_Head, splitWord[i], B_FIND ); // NOTE!!!! Using "searchMatchNode()"

							CASTnode[] matchNodes = searchMatchNodes( AST_Head, splitWord[i], B_FIND );
							if( !matchNodes.length )
								AST_Head = null;
							else if( matchNodes.length == 1 )
							{
								AST_Head = matchNodes[0];
							}
							else
							{
								foreach( CASTnode a; matchNodes )
									if( a.kind & B_NAMESPACE ) nameSpaceNodes ~= a;
							}
							
							if( !nameSpaceNodes.length )
							{
								if( matchNodes.length ) AST_Head = matchNodes[0]; else AST_Head = null;
							}
							else
							{
								//IupMessage("","MULTI Namespace declares!" );
								if( bPushContainer )
								{
									foreach( CASTnode namespaceNode; nameSpaceNodes )
									{
										foreach( CASTnode _child; getMembers( namespaceNode ) ) // Get members( include nested unnamed union & type )
										{
											char[] _list = getListImage( _child );
											map.add( upperCase( _list ), _list );
										}
									}
								}
								
								break;
							}
							
							
							if( AST_Head is null )
							{
								// For Type Objects
								if( memberFunctionMotherName.length )
								{
									if( fullPathByOS(fullPath) in GLOBAL.parserManager )
									{
										//CASTnode memberFunctionMotherNode = _searchMatchNode( GLOBAL.parserManager[fullPathByOS(fullPath)], memberFunctionMotherName, B_TYPE | B_CLASS );
										CASTnode memberFunctionMotherNode = searchMatchNode( GLOBAL.parserManager[fullPathByOS(fullPath)], memberFunctionMotherName, B_TYPE | B_CLASS, true );
										if( memberFunctionMotherNode !is null )
										{
											if( lowerCase( splitWord[i] ) == "this" ) AST_Head = memberFunctionMotherNode; else AST_Head = searchMatchNode( memberFunctionMotherNode, splitWord[i], B_FIND );
										}
									}
								}					
							}

							if( AST_Head is null ) return null;

							if( AST_Head.kind & ( B_VARIABLE | B_PARAM | B_FUNCTION ) )
							{
								if( !isDefaultType( ParserAction.getSeparateType( AST_Head.type, true ) ) )
								{
									AST_Head = getType( AST_Head, lineNum );
									if( AST_Head is null ) return null;
								}
								else
								{
									return null;
								}
							}
							
							if( bPushContainer )
							{
								if( AST_Head.kind & ( B_TYPE | B_ENUM | B_UNION | B_CLASS | B_NAMESPACE ) )
								{
									foreach( CASTnode _child; getMembers( AST_Head ) ) // Get members( include nested unnamed union & type )
									{
										char[] _list = getListImage( _child );
										map.add( upperCase( _list ), _list );
									}
								}
							}
						}

						break;
					}
					
					//AST_Head = searchMatchNode( AST_Head, splitWord[i], B_FIND ); // NOTE!!!! Using "searchMatchNode()"
					CASTnode[] matchNodes = searchMatchNodes( AST_Head, splitWord[i], B_FIND );
					if( !matchNodes.length )
						AST_Head = null;
					else if( matchNodes.length == 1 )
					{
						AST_Head = matchNodes[0];
					}
					else
					{
						foreach( CASTnode a; matchNodes )
							if( a.kind & B_NAMESPACE ) nameSpaceNodes ~= a;
					}
					
					if( !nameSpaceNodes.length )
					{
						if( matchNodes.length ) AST_Head = matchNodes[0]; else AST_Head = null;
					}
					else
					{
						//IupMessage("","MULTI Namespace declares!" );
						continue;
					}
					
					
					

					if( AST_Head is null )
					{
						// For Type Objects
						if( memberFunctionMotherName.length )
						{
							if( fullPathByOS(fullPath) in GLOBAL.parserManager )
							{
								//CASTnode memberFunctionMotherNode = _searchMatchNode( GLOBAL.parserManager[fullPathByOS(fullPath)], memberFunctionMotherName, B_TYPE | B_CLASS );
								CASTnode memberFunctionMotherNode = searchMatchNode( GLOBAL.parserManager[fullPathByOS(fullPath)], memberFunctionMotherName, B_TYPE | B_CLASS, true );
								if( memberFunctionMotherNode !is null )
								{
									if( lowerCase( splitWord[i] ) == "this" ) AST_Head = memberFunctionMotherNode; else AST_Head = searchMatchNode( memberFunctionMotherNode, splitWord[i], B_FIND );
									//AST_Head = searchMatchNode( memberFunctionMotherNode, splitWord[i], B_FIND );
								}
							}
						}					
					}

					if( AST_Head is null ) return null;

					if( AST_Head.kind & ( B_VARIABLE | B_PARAM | B_FUNCTION ) )
					{
						if( !isDefaultType( ParserAction.getSeparateType( AST_Head.type, true ) ) )
						{
							AST_Head = getType( AST_Head, lineNum );
							if( AST_Head is null ) return null;
						}
						else
						{
							return null;
						}
					}
				}
				else if( i == splitWord.length -1 )
				{

					if( nameSpaceNodes.length )
					{
						if( !bDot )
						{
							if( bCallTip )
							{
								if( !bPushContainer ) return null;
								
								foreach( CASTnode a; nameSpaceNodes )
									result ~= callTipList( a.getChildren() ~ getBaseNodeMembers( a ), splitWord[i] );

								return Util.trim( result );
							}
							
							if( bPushContainer )
							{
								foreach( CASTnode a; nameSpaceNodes )
								{
									foreach( CASTnode _child; getMembers( a ) ) // Get members( include nested unnamed union & type )
									{
										if( Util.index( lowerCase( _child.name ), splitWord[i] ) == 0 )
										{
											char[] _list = getListImage( _child );
											map.add( upperCase( _list ), _list );
										}
									}
								}
							}
						}
						else
						{
							CASTnode[] tempNameSpaceNodes = nameSpaceNodes.dup;
							nameSpaceNodes.length = 0;
							foreach( CASTnode _child; tempNameSpaceNodes )
								if( stepByStep( _child, splitWord[i], B_VARIABLE | B_FUNCTION | B_PROPERTY | B_TYPE | B_ENUM | B_UNION | B_NAMESPACE, lineNum ) ) nameSpaceNodes ~= _child;
							
							if( !nameSpaceNodes.length ) return null; else AST_Head = nameSpaceNodes[0];
							
							if( bPushContainer )
							{
								foreach( CASTnode a; nameSpaceNodes )
								{
									foreach( CASTnode _child; getMembers( a ) ) // Get members( include nested unnamed union & type )
									{
										char[] _list = getListImage( _child );
										map.add( upperCase( _list ), _list );
									}
								}
							}
						}
						
						break;
					}				
				
				
					if( !bDot )
					{
						if( bCallTip )
						{
							if( !bPushContainer ) return null;
							
							result = callTipList( AST_Head.getChildren() ~ getBaseNodeMembers( AST_Head ), splitWord[i] );
							return Util.trim( result );
						}
						
						if( bPushContainer )
						{
							foreach( CASTnode _child; getMembers( AST_Head ) ) // Get members( include nested unnamed union & type )
							{
								if( Util.index( lowerCase( _child.name ), splitWord[i] ) == 0 )
								{
									char[] _list = getListImage( _child );
									map.add( upperCase( _list ), _list );
								}
							}
						}
					}
					else
					{
						if( AST_Head.kind & B_NAMESPACE )
						{
							if( !stepByStep( AST_Head, splitWord[i], B_VARIABLE | B_FUNCTION | B_PROPERTY | B_TYPE | B_ENUM | B_UNION | B_NAMESPACE, lineNum ) ) return null;
						}
						else
						{
							if( !stepByStep( AST_Head, splitWord[i], B_VARIABLE | B_FUNCTION | B_PROPERTY, lineNum ) ) return null;
						}
						
						
						
						if( bPushContainer )
						{
							foreach( CASTnode _child; getMembers( AST_Head ) ) // Get members( include nested unnamed union & type )
							{
								char[] _list = getListImage( _child );
								map.add( upperCase( _list ), _list );
							}
						}
					}
				}
				else
				{
					if( nameSpaceNodes.length )
					{
						CASTnode[] tempNameSpaceNodes = nameSpaceNodes.dup;
						nameSpaceNodes.length = 0;
						foreach( CASTnode _child; tempNameSpaceNodes )
							if( stepByStep( _child, splitWord[i], B_VARIABLE | B_FUNCTION | B_PROPERTY | B_TYPE | B_ENUM | B_UNION | B_NAMESPACE, lineNum ) ) nameSpaceNodes ~= _child;

						if( !nameSpaceNodes.length ) return null;
						if( nameSpaceNodes.length == 1 )
						{
							AST_Head = nameSpaceNodes[0];
							nameSpaceNodes.length = 0;
						}
						continue;
					}
					
					if( AST_Head.kind & B_NAMESPACE )
					{
						if( !stepByStep( AST_Head, splitWord[i], B_VARIABLE | B_FUNCTION | B_PROPERTY | B_TYPE | B_ENUM | B_UNION | B_NAMESPACE, lineNum ) ) return null;
					}
					else
					{
						if( !stepByStep( AST_Head, splitWord[i], B_VARIABLE | B_FUNCTION | B_PROPERTY, lineNum ) ) return null;
					}
				}
			}		
		
			if( bPushContainer )
			{
				foreach( key, value; map )
					listContainer ~= value;
			}
		
			return result;
		}
		

		public:
		static bool bEnter;
		static bool bAutocompletionPressEnter;
		static bool	bSkipAutoComplete;
		
		static void init()
		{
			// For Static Struct -- AutoComplete Init!
			if( timer == null )
			{
				timer = IupTimer();
				IupSetAttributes( timer, "TIME=50,RUN=NO" );
				IupSetCallback( timer, "ACTION_CB", cast(Icallback) &CompleteTimer_ACTION );
				setTimer( Integer.atoi( GLOBAL.triggerDelay ) );
			}
		}
		
		static void setTimer( uint milisecond )
		{
			if( milisecond > 1000 ) milisecond = 1000;
			IupSetInt( timer, "TIME", milisecond );
		}
		
		static bool showListThreadIsRunning()
		{
			if( showListThread is null ) return false;
			if( !showListThread.isRunning ) return false;
			
			return true;
		}
		
		static bool showCallTipThreadIsRunning()
		{
			if( showCallTipThread is null ) return false;
			if( !showCallTipThread.isRunning ) return false;
		
			return true;
		}
		
		static char[] getShowTypeContent()
		{
			return showTypeContent;
		}

		static void clearShowTypeContent()
		{
			showTypeContent = "";
		}
		
		static void cleanIncludeContainer()
		{
			foreach( char[] key; includesMarkContainer.keys )
				includesMarkContainer.remove( key );
		}		
		
		static void cleanCalltipContainer()
		{
			calltipContainer.clear();
		}
		
		static char[] getKeywordContainerList( char[] word, bool bCleanContainer = true )
		{
			char[] result;
			
			if( bCleanContainer ) listContainer.length = 0;
			
			keyWordlist( word );

			if( listContainer.length )
			{
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
					if( result[$-1] == '^' ) result = result[0..$-1];

				return Util.trim( result );
			}
			
			return null;
		}
		
		static void setPreLoadContainer( CASTnode astHead )
		{
			if( preLoadContainerThread is null )
			{
				preLoadContainerThread = new CGetIncludes( astHead );
				preLoadContainerThread.start();
			}
			else
			{
				if( !preLoadContainerThread.isRunning )
				{
					delete preLoadContainerThread;
					preLoadContainerThread = new CGetIncludes( astHead );
					preLoadContainerThread.start();
				}
				else
				{
					preLoadContainerThread.join();
				}
			}
		}


		static char[] checkIncludeExist( char[] include, char[] originalFullPath )
		{
			try
			{
				//char[] include;
				
				if( !include.length ) return null;
				/*
				if( _include.length > 2 )
				{
					if( _include[0] == '"' && _include[$-1] == '"' ) _include = _include[1..$-1];
					include = _include.dup;
				}
				else
				{
					return null;
				}
				*/
				include = Util.substitute( include, "\\", "/" );
				originalFullPath = Path.normalize( originalFullPath );
				
				// Step 1: Relative from the directory of the source file
				scope  _path = new FilePath( originalFullPath ); // Tail include /
				char[] testPath = _path.path() ~ include;
				_path.set( testPath ); // Reset
				if( _path.exists() )
					if( _path.isFile ) return testPath;


				// Step 2: Relative from the current working directory
				char[] dir = actionManager.ProjectAction.fileInProject( originalFullPath );
				if( dir.length )
				{
					if( dir[$-1] != '/' ) dir ~= "/";
					testPath = dir ~ include;

					_path.set( testPath ); // Reset
					if( _path.exists() ) 
						if( _path.isFile ) return testPath;
				}

				testPath = Environment.cwd() ~ include; // Environment.cwd(), Tail include /
				_path.set( testPath ); // Reset
				if( _path.exists() )
					if( _path.isFile ) return testPath;


				// Step 3: Relative from addition directories specified with the -i command line option
				// Work on Project
				//char[] prjDir = actionManager.ProjectAction.fileInProject( originalFullPath );
				char[] prjDir = GLOBAL.activeProjectPath;
				if( prjDir.length )
				{
					//Stdout( "Project Dir: " ~ prjDir ).newline;
					if( prjDir in GLOBAL.projectManager )
					{
						char[][] _includeDirs = GLOBAL.projectManager[prjDir].includeDirs; // without \
						if( GLOBAL.projectManager[prjDir].focusOn.length )
							if( GLOBAL.projectManager[prjDir].focusOn in GLOBAL.projectManager[prjDir].focusUnit ) _includeDirs = GLOBAL.projectManager[prjDir].focusUnit[GLOBAL.projectManager[prjDir].focusOn].IncDir;						
							
						foreach( char[] s; _includeDirs )
						{
							testPath = s ~ "/" ~ include;
							
							_path.set( testPath ); // Reset

							if( _path.exists() )
								if( _path.isFile ) return testPath;
						}
					}
				}

				// Step 4(Final): The include folder of the FreeBASIC installation (FreeBASIC\inc, where FreeBASIC is the folder where the fbc executable is located)
				// Get Custom Compiler
				char[] customOpt, customCompiler, fbcFullPath;
				CustomToolAction.getCustomCompilers( customOpt, customCompiler );

				if( customCompiler.length )
					_path.set( Path.normalize( customCompiler ) );
				else
				{
					char[] _compilerPath;
					if( prjDir in GLOBAL.projectManager )
					{
						_compilerPath = GLOBAL.projectManager[prjDir].compilerPath;
						if( GLOBAL.projectManager[prjDir].focusOn.length )
							if( GLOBAL.projectManager[prjDir].focusOn in GLOBAL.projectManager[prjDir].focusUnit ) _compilerPath = GLOBAL.projectManager[prjDir].focusUnit[GLOBAL.projectManager[prjDir].focusOn].Compiler;						
					}
					
					if( _compilerPath.length )
						_path.set( Path.normalize( _compilerPath ) );
					else
					{
						version(Windows)
						{
							if( GLOBAL.editorSetting00.Bit64 == "OFF" ) _compilerPath = GLOBAL.compilerFullPath; else _compilerPath = GLOBAL.x64compilerFullPath;
						}
						else
						{
							_compilerPath = GLOBAL.compilerFullPath;
						}
					}
					
					_path.set( Path.normalize( _compilerPath ) );
				}

				version( Windows )
				{
					testPath = _path.path() ~ "inc/" ~ include;
				}
				else
				{
					testPath = _path.path() ~ "../include/freebasic/" ~ include;
				}
	
				_path.set( testPath ); // Reset
				if( _path.exists() )
					if( _path.isFile ) return testPath;
			}
			catch( Exception e )
			{
				IupMessage( "Bug", toStringz( "checkIncludeExist() Error:\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ Integer.toString( e.line ) ) );
			}
			
			return null;
		}
		

		static CASTnode[] getIncludes( CASTnode originalNode, char[] originalFullPath, int _LEVEL )
		{
			if( originalNode is null ) return null;
			if( GLOBAL.includeLevel == 0 ) return null;
			if( _LEVEL >= GLOBAL.includeLevel && GLOBAL.includeLevel > 0 ) return null;
			if( GLOBAL.includeLevel > -1 ) _LEVEL++;
			

			CASTnode[]	results;
			//bool		bPrjFile;

			CASTnode rootNode = ParserAction.getRoot( originalNode );
			//if( ProjectAction.fileInProject( rootNode.name, GLOBAL.activeProjectPath ) ) bPrjFile = true;
			
			foreach( CASTnode _node; getMembers( originalNode, true ) )
			{
				if( _node.kind & B_INCLUDE )
				{
					if( _node.lineNumber < 2147483647 )
					{
						//Stdout( _node.name ~ " " ~ Integer.toString( _LEVEL ) ).newline;
						CASTnode[] _results = check( _node.name, originalFullPath, _LEVEL );
						if( _results.length ) results ~= _results;
					}
				}
			}

			return results;
		}
		
		static char[] includeComplete( Ihandle* iupSci, int pos, ref char[] text )
		{
			// Nested Delegate Filter Function
			bool dirFilter( FilePath _fp, bool _isFfolder )
			{
				if( _isFfolder ) return true;
				if( tools.isParsableExt( _fp.ext, 7 ) ) return true;
			
				return false;
			}
			
			bool delegate( FilePath, bool ) _dirFilter;
			_dirFilter = &dirFilter;
			// End of Nested Function
			
			if( !text.length )  return null;
			
			dchar[] word32;
			char[]	word = text;
			bool	bExitLoopFlag;		
			
			if( text != "\\" && text != "/" && ( fromStringz( IupGetAttribute( iupSci, "AUTOCACTIVE" ) ) == "YES" ) ) return null;

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
						int key = cast(int) _s[0];
						if( key >= 0 && key <= 127 )
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
					}
					
					if( bExitLoopFlag ) break;
				}
				
				if( !word.length ) return null; else word = word.dup.reverse;
				
				//version(Windows) word = word.dup.reverse; else word = lowerCase( word.dup.reverse );
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
					if( prjDir in GLOBAL.projectManager )
					{
						char[][] _includeDirs = GLOBAL.projectManager[prjDir].includeDirs;
						if( GLOBAL.projectManager[prjDir].focusOn.length )
							if( GLOBAL.projectManager[prjDir].focusOn in GLOBAL.projectManager[prjDir].focusUnit ) _includeDirs = GLOBAL.projectManager[prjDir].focusUnit[GLOBAL.projectManager[prjDir].focusOn].IncDir;						
						
						foreach( char[] s; _includeDirs ) // without \
							_path3 ~= new FilePath( s ); // Reset
					}
				}			
				
				// Step 4(Final): The include folder of the FreeBASIC installation (FreeBASIC\inc, where FreeBASIC is the folder where the fbc executable is located)
				FilePath _path4 = new FilePath( Path.normalize( GLOBAL.compilerFullPath ) );
				
				// Get Custom Compiler
				char[] customOpt, customCompiler, fbcFullPath, testPath;
				CustomToolAction.getCustomCompilers( customOpt, customCompiler );

				if( customCompiler.length )
					_path4.set( Path.normalize( customCompiler ) );
				else
				{
					char[] _compilerPath;
					if( prjDir in GLOBAL.projectManager )
					{
						_compilerPath = GLOBAL.projectManager[prjDir].compilerPath;
						if( GLOBAL.projectManager[prjDir].focusOn.length )
							if( GLOBAL.projectManager[prjDir].focusOn in GLOBAL.projectManager[prjDir].focusUnit ) _compilerPath = GLOBAL.projectManager[prjDir].focusUnit[GLOBAL.projectManager[prjDir].focusOn].Compiler;						
					}
					
					if( _compilerPath.length )
						_path4.set( Path.normalize( _compilerPath ) );
					else
					{
						version(Windows)
						{
							if( GLOBAL.editorSetting00.Bit64 == "OFF" ) _compilerPath = GLOBAL.compilerFullPath; else _compilerPath = GLOBAL.x64compilerFullPath;
						}
						else
						{
							_compilerPath = GLOBAL.compilerFullPath;
						}
					}
					
					_path4.set( Path.normalize( _compilerPath ) );
				}				
				
				version( Windows )
				{
					testPath = _path4.path() ~ "inc/";
				}
				else
				{
					testPath = _path4.path() ~ "../include/freebasic/";
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
					if( list[$-1] == '^' ) list = list[0..$-1];
					
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

			scope _t = new IupString( targetText );

			int posHead = cast(int) IupScintillaSendMessage( iupSci, 2197, targetText.length, cast(int) _t.toCString );

			while( posHead >= 0 )
			{
				int style = cast(int) IupScintillaSendMessage( iupSci, 2010, posHead, 0 ); // SCI_GETSTYLEAT 2010
				if( style == 1 || style == 19 || style == 4 )
				{
					IupScintillaSendMessage( iupSci, 2190, posHead - 1, 0 );				// SCI_SETTARGETSTART = 2190,
					IupScintillaSendMessage( iupSci, 2192, 0, 0 );							// SCI_SETTARGETEND = 2192,
					posHead = cast(int) IupScintillaSendMessage( iupSci, 2197, targetText.length, cast(int) _t.toCString );
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

							if( cast(int) _s[0] == 13 || _s == ":" || _s == "\n" )
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
							
							if( beforeWord == "eralced" || beforeWord == "dne" || beforeWord == "=" || beforeWord == "sa" ) bReSearch = true; else bReSearch = false;
							break;
						}
					}
				}

				if( bReSearch )
				{
					IupScintillaSendMessage( iupSci, 2190, --posHead, 0 );
					IupScintillaSendMessage( iupSci, 2192, 0, 0 );							// SCI_SETTARGETEND = 2192,
					posHead = cast(int) IupScintillaSendMessage( iupSci, 2197, targetText.length, cast(int) _t.toCString );
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
				IupSetInt( iupSci, "TARGETSTART", pos );
				IupSetInt( iupSci, "TARGETEND", 0 );
			}
			else
			{
				IupSetInt( iupSci, "TARGETSTART", pos );
				IupSetInt( iupSci, "TARGETEND", -1 );
			}

			scope _t = new IupString( targetText );
			
			pos = cast(int) IupScintillaSendMessage( iupSci, 2197, targetText.length, cast(int) _t.toCString );
			
			while( pos > -1 )
			{
				int style = cast(int) IupScintillaSendMessage( iupSci, 2010, pos, 0 ); // SCI_GETSTYLEAT 2010
				if( style == 1 || style == 19 || style == 4 )
				{
					if( direct == 0 )
					{
						IupSetInt( iupSci, "TARGETSTART", pos - 1 );
						IupSetInt( iupSci, "TARGETEND", 0 );
						pos = cast(int) IupScintillaSendMessage( iupSci, 2197, targetText.length, cast(int) _t.toCString );
					}
					else
					{
						IupSetInt( iupSci, "TARGETSTART", pos + targetText.length );
						IupSetInt( iupSci, "TARGETEND", -1 );
						pos = cast(int) IupScintillaSendMessage( iupSci, 2197, targetText.length, cast(int) _t.toCString );
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
			bool	bBackEnd;
			int		documentLength = IupGetInt( iupSci, "COUNT" );

			do
			{
				if( !actionManager.ScintillaAction.isComment( iupSci, pos ) )
				{
					char[] s = fromStringz( IupGetAttributeId( iupSci, "CHAR", pos ) );

					switch( s )
					{
						case "(", ")", "[", "]", "{", "}":
						case ".":
						case " ", "\t", ":", "\n", "\r", "+", "-", "*", "/", "\\", ">", "<", "=", ",", "@":
							bBackEnd = true;
							break;

						default:
					}
				}
				
				if( pos >= documentLength ) break;
				if( bBackEnd ) break;
			}
			while( ++pos < documentLength );
			
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
				while( --pos >= 0 )
				{
					char[] s = fromStringz( IupGetAttributeId( iupSci, "CHAR", pos ) );
					if( s.length )
					{
						int key = cast(int) s[0];
						if( key >= 0 && key <= 127 )
						{
							if( s == ":" || s == "\n" ) break;
							result ~= s;
						}
					}
				}
				
				result = lowerCase( Util.trim( result.reverse ) ).dup;
				if( result.length > 7 )
				{
					if( result[0..8] == "#include" ) return true;
				}			
			}
			catch( Exception e )
			{
				debug IupMessage( "AutoComplete.checkIscludeDeclare() Error", toStringz( e.toString ) );
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
			while( ++pos < documentLength );
			
			--pos;

			do
			{
				char[] s = fromStringz( IupGetAttributeId( iupSci, "CHAR", pos ) );
				if( s == "\"" || s == "\n" ) break;
				result ~= s;
			}
			while( --pos >= 0 );
			 
			return result.dup.reverse;
		}
		
		static int getWholeWordTailPos( Ihandle* iupSci, int startPos )
		{
			try
			{
				while( startPos < IupGetInt( iupSci, "COUNT" ) )
				{
					char[] s = fromStringz( IupGetAttributeId( iupSci, "CHAR", startPos ) );
					int key = cast(int) s[0];
					if( key >= 0 && key <= 127 )
					{
						if( s.length )
						{
							if( actionManager.ScintillaAction.isComment( iupSci, startPos ) ) return startPos;
							
							switch( s )
							{
								case "(", ")", "[", "]":								return startPos;
								case ":", ";", ",", ".":								return startPos;			
								case " ", "\t", "\n", "\r":								return startPos;
								case "+", "-", "*", "/", "\\", "<", ">", "=", "@":		return startPos;
								default: 
							}
						}
					}
					startPos ++;
				}
			}
			catch( Exception e )
			{
				//return -1;
			}

			return startPos;
		}

		static char[] getKeyWordReverse( Ihandle* iupSci, int pos, out int headPos )
		{
			dchar[] word32;
			char[]	word;
			int		countParen, countBracket;

			try
			{
				while( pos > -1 )
				{
					headPos = pos;
					--pos;
					if( pos < 0 ) break;
					
					char[] s = fromStringz( IupGetAttributeId( iupSci, "CHAR", pos ) );
					int key = cast(int) s[0];
					if( key >= 0 && key <= 127 )
					{
						version(Windows)
						{
							dchar[] _dcharString = fromString32z( cast(dchar*) IupGetAttributeId( iupSci, "CHAR", pos ) );
							if( _dcharString.length )
							{
								if( actionManager.ScintillaAction.isComment( iupSci, pos ) )
								{
									return UTF.toString( word32 );
								}
								else
								{
									switch( _dcharString )
									{
										case ")", "(", "[", "]", "<", ">", "{", "}":
										case " ", "\t", ":", "\n", "\r", "+", "-", "*", "/", "\\", "=", ",", "@":
											return UTF.toString( word32 );
											
										default: 
											word32 ~= _dcharString;
									}
								}
							}
						}
						else
						{
							if( s.length )
							{
								if( actionManager.ScintillaAction.isComment( iupSci, pos ) )
								{
									return word;
								}
								else
								{
									switch( s )
									{
										case ")", "(", "[", "]", "<", ">", "{", "}":
										case " ", "\t", ":", "\n", "\r", "+", "-", "*", "/", "\\", "=", ",", "@":
											return word;
											
										default: 
											word ~= s;
									}
								}
							}
						}
					}
				}
			}
			catch( Exception e )
			{
				debug IupMessage( "AutoComplete.getKeyWordReverse() Error", toStringz( e.toString ) );
				return null;
			}
			
			version(Windows) word = UTF.toString( word32 );

			return word;
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
					headPos = pos;
					--pos;
					if( pos < 0 ) break;
					
					char[] s = fromStringz( IupGetAttributeId( iupSci, "CHAR", pos ) );
					int key = cast(int) s[0];
					if( key >= 0 && key <= 127 )
					{
						version(Windows)
						{
							dchar[] _dcharString = fromString32z( cast(dchar*) IupGetAttributeId( iupSci, "CHAR", pos ) );
							if( _dcharString.length )
							{
								if( actionManager.ScintillaAction.isComment( iupSci, pos ) )
								{
									if( _dcharString == "\r" || _dcharString == "\n" )
									{
										if( countParen == 0 && countBracket == 0 ) return UTF.toString( word32 ); else continue;
									}
									else
									{
										continue;
									}
								}
								
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
										if( countParen == 0 && countBracket == 0 ) word32 ~= _dcharString;
								}
							}
						}
						else
						{
							if( s.length )
							{
								if( actionManager.ScintillaAction.isComment( iupSci, pos ) )
								{
									if( s == "\r" || s == "\n" )
									{
										if( countParen == 0 && countBracket == 0 ) return word; else continue;
									}
									else
										continue;
								}
								
								switch( s )
								{
									case ")":
										if( countBracket == 0 ) countParen++;
										break;

									case "(":
										if( countBracket == 0 ) countParen--;
										if( countParen < 0 ) return word;
										break;
										
									case "]":
										if( countParen == 0 ) countBracket++;
										break;

									case "[":
										if( countParen == 0 ) countBracket--;
										if( countBracket < 0 ) return word;
										break;
										
									case ">":
										if( pos > 0 && countParen == 0 && countBracket == 0 )
										{
											if( fromStringz( IupGetAttributeId( iupSci, "CHAR", pos - 1 ) ) == "-" )
											{
												word ~= ">-";
												pos--;
												break;
											}
										}
									case " ", "\t", ":", "\n", "\r", "+", "-", "*", "/", "\\", "<", "=", ",", "@":
										if( countParen == 0 && countBracket == 0 ) return word;
										
									default: 
										if( countParen == 0 && countBracket == 0 )
										{
											if( !actionManager.ScintillaAction.isComment( iupSci, pos ) ) word ~= s;
										}
								}
							}
						}
					}
				}
			}
			catch( Exception e )
			{
				debug IupMessage( "AutoComplete.getWholeWordReverse() Error", toStringz( e.toString ) );
				return null;
			}
			
			version(Windows) word = UTF.toString( word32 );

			return word;
		}
		
		static char[] charAdd( Ihandle* iupSci, int pos, char[] text, bool bForce = false )
		{
			int		dummyHeadPos;
			char[] 	word, result;
			bool	bDot, bCallTip;
			
			if( text == "(" )
			{
				//if( GLOBAL.toggleCompleteAtBackThread == "ON" )
					if( calltipContainer.size > 0 ) return null;
				
				bCallTip = true;
				IupSetAttribute( iupSci, "AUTOCCANCEL", "YES" ); // Prevent autocomplete -> calltip issue
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
			
			word = lowerCase( word.dup.reverse );

			auto cSci = actionManager.ScintillaAction.getActiveCScintilla();
			if( cSci !is null )
			{
				if( fullPathByOS(cSci.getFullPath) in GLOBAL.parserManager )
				{
					if( GLOBAL.parserManager[fullPathByOS(cSci.getFullPath)] is null ) return null;
				}
				else
				{
					return null;
				}
				
				if( !bDot && ( fromStringz( IupGetAttribute( iupSci, "AUTOCACTIVE" ) ) == "YES" ) )
				{}
				else
				{
					// Clean listContainer
					listContainer.length = 0;
					
					if( fromStringz( IupGetAttribute( iupSci, "AUTOCACTIVE" ) ) == "YES" ) IupSetAttribute( iupSci, "AUTOCCANCEL", "YES" );

					// Divide word
					char[][]	splitWord = getDivideWord( word );
					int			lineNum = cast(int) IupScintillaSendMessage( iupSci, 2166, pos, 0 ) + 1; //SCI_LINEFROMPOSITION = 2166,
					CASTnode	AST_Head = actionManager.ParserAction.getActiveASTFromLine( GLOBAL.parserManager[fullPathByOS(cSci.getFullPath)], lineNum );

					if( AST_Head is null )
					{
						if( GLOBAL.enableKeywordComplete == "ON" ) return getKeywordContainerList( splitWord[0] );
						return null;
					}

					if( GLOBAL.autoCompletionTriggerWordCount < 1 && !bForce ) 
					{
						if( GLOBAL.enableKeywordComplete == "ON" ) return getKeywordContainerList( splitWord[0] );
						return null;
					}
					
					auto oriAST = AST_Head;
					
					version(VERSION_NONE) initIncludesMarkContainer( AST_Head, lineNum ); else checkVersionSpec( AST_Head, lineNum );
					
					result = analysisSplitWorld_ReturnCompleteList( AST_Head, splitWord, lineNum, bDot, bCallTip, true );
					char[][] usingNames = checkUsingNamespace( oriAST, lineNum );
					if( usingNames.length )
					{
						char[][] noUsingListContainer;
						if( splitWord.length == 1 )
						{
							if( !bDot && !bCallTip )
							{
								noUsingListContainer = listContainer.dup;
								listContainer.length = 0;
							}
							else if( bCallTip )
							{
								if( !result.length ) listContainer.length = 0; 
							}
						}
						
						if( !listContainer.length )
						{
							foreach( char[] s; usingNames )
							{
								char[][] splitWithDot = Util.split( s, "." );
								char[][] namespaceSplitWord = splitWithDot ~ splitWord;
								char[] _result = analysisSplitWorld_ReturnCompleteList( oriAST, namespaceSplitWord, lineNum, bDot, bCallTip, true );
								
								if( bCallTip )
								{
									if( _result.length )
									{
										result = _result;
										break;
									}
								}
								
								if( listContainer.length )
								{
									listContainer = noUsingListContainer ~ listContainer;
									result = _result;
									break;
								}
							}
						}
						
						if( !listContainer.length ) listContainer = noUsingListContainer;
						/+
						char[][] keyWordListContainer;
						
						if( listContainer.length )
						{
							if( listContainer[$-1][$-1] == '0' )
							{
								keyWordListContainer = listContainer.dup;
								listContainer.length = 0;
							}
						}

						if( !listContainer.length )
						{
							foreach( char[] s; usingNames )
							{
								char[][] splitWithDot = Util.split( s, "." );
								char[][] namespaceSplitWord = splitWithDot ~ splitWord;
								char[] _result = analysisSplitWorld_ReturnCompleteList( oriAST, namespaceSplitWord, lineNum, bDot, bCallTip, true );
								if( listContainer.length )
								{
									listContainer = keyWordListContainer ~ listContainer;
									result = _result;
									break;
								}
							}
						}
						
						if( !listContainer.length ) listContainer = keyWordListContainer;
						+/
					}

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
										_type = listContainer[i][dollarPos+1..$];
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
							/*
							if( i > 0 )
							{
								if( listContainer[i] == listContainer[i-1] ) continue;
							}
							*/
							
							if( i < listContainer.length - 1 )
							{
								int questPos = Util.rindex( listContainer[i], "?0" );
								if( questPos < listContainer[i].length )
								{
									char[]	_keyWord = listContainer[i][0..questPos];
									char[]	compareWord;
									
									int tildePos = Util.rindex( listContainer[i+1], "~" );
									if( tildePos < listContainer[i+1].length )
										compareWord = listContainer[i+1][0..tildePos];
									else
									{
										questPos = Util.rindex( listContainer[i+1], "?" );
										if( questPos < listContainer[i+1].length ) compareWord = listContainer[i+1][0..questPos]; else compareWord = listContainer[i+1];
									}
									
									if( lowerCase( _keyWord ) == lowerCase( compareWord ) ) continue;
								}
							}


							if( listContainer[i].length )
							{
								if( GLOBAL.toggleShowListType == "ON" )
								{
									char[] _string;
									
									int dollarPos = Util.rindex( listContainer[i], "~" );
									if( dollarPos < listContainer[i].length )
									{
										_type = listContainer[i][dollarPos+1..$];
										_list = listContainer[i][0..dollarPos];
										_string = Util.trim( Stdout.layout.convert( formatString, _list, _type ) );
									}
									else
									{
										_string = listContainer[i];
									}

									result ~= ( _string ~ "^" );
								}
								else
								{
									result ~= ( listContainer[i] ~ "^" );
								}
							}
						}
					}
				}

				if( result.length )
					if( result[$-1] == '^' ) result = result[0..$-1];

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
			clearShowTypeContent();
			
			try
			{
				if( showListThread !is null )
				{
					if( showListThread.isRunning ) showListThread.join();
				}
				
				if( showCallTipThread !is null )
				{
					if( showCallTipThread.isRunning ) showCallTipThread.join();
				}
				
			}
			catch( Exception e){}
			
			try
			{
				char[]	word;
				bool	bDwell;
				auto cSci = actionManager.ScintillaAction.getActiveCScintilla();
				if( cSci !is null )
				{
					if( fullPathByOS(cSci.getFullPath) in GLOBAL.parserManager ){} else{ return; }
					
					if( currentPos == -1 ) currentPos = actionManager.ScintillaAction.getCurrentPos( cSci.getIupScintilla ); else bDwell = true;
					if( currentPos < 1 ) return;
				
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
								scope _result = new IupString( includeFullPath );
								IupScintillaSendMessage( cSci.getIupScintilla, 2206, 0xFF0000, 0 ); //SCI_CALLTIPSETFORE 2206
								IupScintillaSendMessage( cSci.getIupScintilla, 2205, 0x00FFFF, 0 ); //SCI_CALLTIPSETBACK 2205
								IupScintillaSendMessage( cSci.getIupScintilla, 2200, currentPos, cast(int) _result.toCString ); // SCI_CALLTIPSHOW 2200
							}
							return;
						}
					}					
					
					if( ScintillaAction.isComment( cSci.getIupScintilla, currentPos ) ) return;
					
					word = getWholeWordDoubleSide( cSci.getIupScintilla, currentPos );
					word = lowerCase( word.dup.reverse );
					
					if( GLOBAL.debugPanel.isRunning && GLOBAL.debugPanel.isExecuting )
					{
						if( TYPE == -1 )
						{
							if( word.length )
							{
								word = fullPathByOS( Util.substitute( word, "->", "." ).dup );
								char[] typeName, value, title, title1;
								char[] title0 = GLOBAL.debugPanel.getTypeValueByName( word, word, typeName, value ).dup;
								/+
								if( typeName.length )
								{
									if( typeName[$-1] == '*' )
									{
										int spacePos = Util.index( typeName, " " );
										if( spacePos < typeName.length )
										{
											if( typeName[0..spacePos] != "VOID" ) title1 = GLOBAL.debugPanel.getTypeValueByName( "*" ~ word, word, typeName, value );
										}
									}
								}
								
								if( title0.length && title1.length )
									title = title0 ~ "\n" ~ title1;
								else if( title0.length )
									title = title0;
								else if( title1.length )
									title = title1;
								else
									return;
								+/
								if( title0.length )
								{
									IupScintillaSendMessage( cSci.getIupScintilla, 2206, 0x000000, 0 ); //SCI_CALLTIPSETFORE 2206
									IupScintillaSendMessage( cSci.getIupScintilla, 2205, 0xFFEEFF, 0 ); //SCI_CALLTIPSETBACK 2205
									scope _result = new IupString( title0 );
									IupScintillaSendMessage( cSci.getIupScintilla, 2200, currentPos, cast(int) _result.toCString ); // SCI_CALLTIPSHOW 2200
									
									int assignPos = Util.index( title0, " = " );
									if( assignPos < title0.length )
									{
										IupScintillaSendMessage( cSci.getIupScintilla, 2204, 0, assignPos ); // SCI_CALLTIPSETHLT 2204
										IupScintillaSendMessage( cSci.getIupScintilla, 2207, 0xFF0000, 0 ); // SCI_CALLTIPSETFOREHLT 2207
									}
									else
									{
										IupScintillaSendMessage( cSci.getIupScintilla, 2204, 0, -1 ); // SCI_CALLTIPSETHLT 2204
									}
								}
							}
							return;
						}
					}
					
					
					
					char[][] splitWord = getDivideWord( word );
					
					// Manual
					if( splitWord.length == 1 )
					{
						if( GLOBAL.toggleUseManual == "ON" )
						{
							if( TYPE == 0 && !bDwell )
							{
								char[]	keyWord;
								bool	bExitFlag;

								if( splitWord[0].length )
								{
									foreach( char[] _s; GLOBAL.KEYWORDS )
									{
										foreach( char[] targetText; Util.split( _s, " " ) )
										{
											if( targetText == splitWord[0] )
											{
												keyWord = targetText;
												bExitFlag = true;
												break;
											}
										}
										if( bExitFlag ) break;
									}

									if( bExitFlag )
									{
										bExitFlag = false;
										
										version(Windows)
										{
											if( GLOBAL.htmlHelp != null )
											{
												wchar[] keyWord16 = UTF.toString16( keyWord );
												
												foreach( char[] s; GLOBAL.manuals )
												{
													char[][] _splitWords = Util.split( s, "," );
													if( _splitWords.length == 2 )
													{
														if( _splitWords[1].length )
														{
															wchar[]	_path =  UTF.toString16( _splitWords[1] );

															HH_AKLINK	akLink;
															akLink.cbStruct = HH_AKLINK.sizeof;
															akLink.fReserved = 0;
															akLink.pszKeywords = toString16z( keyWord16 );
															akLink.fIndexOnFail = 0;
															//GLOBAL.htmlHelp( null, toString16z( _path ), 1, 0 ); // HH_DISPLAY_TOPIC = 1
															if( GLOBAL.htmlHelp( null, toString16z( _path ), 0x000D, cast(uint) &akLink ) != null ) //#define HH_KEYWORD_LOOKUP       &h000D
															{
																bExitFlag = true;
																break;
															}
														}
													}
												}
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
												if( GLOBAL.manuals.length > 0 )
												{
													char[][] _splitWords = Util.split( GLOBAL.manuals[0], "," );
													if( _splitWords.length == 2 )
													{
														if( _splitWords[1].length )	IupExecute( "hh", toStringz( "\"" ~ _splitWords[1] ~ keyPg ~ "\"" ) );
													}
												}
											}
										}
										else
										{
											if( GLOBAL.manuals.length > 0 )
											{
												char[][] _splitWords = Util.split( GLOBAL.manuals[0], "," );
												if( _splitWords.length == 2 )
												{
													if( _splitWords[1].length )
														IupExecute( "./CHMVIEW", toStringz( _splitWords[1] ~ " -p KeyPg" ~ keyWord ~ ".html" ) );	// "kchmviewer --sindex %s /chm-path
														//IupExecute( "kchmviewer", toStringz( "--stoc " ~ keyWord ~ " /" ~ _splitWords[1] ) );	// "kchmviewer --sindex %s /chm-path
												}
											}
										}
										
										if( bExitFlag ) return;
									}
								}
							}
							
							//if( splitWord[0] == "constructor" || splitWord[0] == "destructor" ) return;
						}
					}

					// Divide word
					int			lineNum = cast(int) IupScintillaSendMessage( cSci.getIupScintilla, 2166, currentPos, 0 ) + 1; //SCI_LINEFROMPOSITION = 2166,
					auto 		AST_Head = actionManager.ParserAction.getActiveASTFromLine( GLOBAL.parserManager[fullPathByOS(cSci.getFullPath)], lineNum );
					auto		oriAST = AST_Head;
					char[]		memberFunctionMotherName;
					
					// Get VersionCondition names
					if( AST_Head is null ) return;
					
					version(VERSION_NONE)
					{
						initIncludesMarkContainer( AST_Head, lineNum );
					}
					else
					{
						// Reset VersionCondition Container
						foreach( char[] key; VersionCondition.keys )
							VersionCondition.remove( key );						
						
						char[] options, compilers;
						CustomToolAction.getCustomCompilers( options, compilers );
						
						char[] activePrjName = ProjectAction.getActiveProjectName;
						if( activePrjName.length ) options = Util.trim( options ~ " " ~ GLOBAL.projectManager[activePrjName].compilerOption );
						if( options.length )
						{	
							int _versionPos = Util.index( options, "-d" );
							while( _versionPos < options.length )
							{
								char[]	versionName;
								bool	bBeforeSymbol = true;
								for( int i = _versionPos + 2; i < options.length; ++ i )
								{
									if( options[i] == '\t' || options[i] == ' ' )
									{
										if( !bBeforeSymbol ) break; else continue;
									}
									else if( options[i] == '=' )
									{
										break;
									}

									versionName ~= options[i];
								}								

								if( versionName.length ) AutoComplete.VersionCondition[upperCase(versionName)] = 1;
								_versionPos = Util.index( options, "-d", _versionPos + 2 );
							}								
						}
						
						checkVersionSpec( AST_Head, lineNum );
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
								if( s != "" ) splitWord ~= ParserAction.removeArrayAndPointer( s );
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
						while( _fatherNode.kind & ( B_WITH | B_SCOPE ) );
					}
					
					if( _fatherNode.getFather !is null )
					{
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
						/*
						case "operator":
							if( keyword_Btype == 0 ) keyword_Btype = B_OPERATOR;
						case "property":
							if( keyword_Btype == 0 ) keyword_Btype = B_PROPERTY;
						*/
						default:
							if( keyword_Btype > 0 )
							{
								if( AST_Head.kind & ( B_CTOR | B_DTOR ) )
								{
									if( TYPE < 2 )
										if( AST_Head.lineNumber == AST_Head.endLineNum ) return; // Declare
								}
							}
						
							/+
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
							+/
					}
					
					// Comment at 2022/05/28
					//cleanIncludesMarkContainer();
					
					// Nested 2021.09.01, for Namespace
					CASTnode _analysisSplitWord( CASTnode _AST_Head, char[][] _splitWord )
					{
						CASTnode[] nameSpaceNodes;
						CASTnode returnNode;
						for( int i = 0; i < _splitWord.length; i++ )
						{
							if( i == 0 )
							{
								CASTnode[] matchNodes = searchMatchNodes( _AST_Head, _splitWord[i], B_FIND | B_SUB | B_ENUMMEMBER );
								if( !matchNodes.length )
								{
									// For Type Objects
									if( memberFunctionMotherName.length )
									{
										//CASTnode memberFunctionMotherNode = _searchMatchNode( GLOBAL.parserManager[fullPathByOS(cSci.getFullPath)], memberFunctionMotherName, B_TYPE | B_CLASS );
										CASTnode memberFunctionMotherNode = searchMatchNode( GLOBAL.parserManager[fullPathByOS(cSci.getFullPath)], memberFunctionMotherName, B_TYPE | B_CLASS, true );
										if( memberFunctionMotherNode !is null )
										{
											auto matchNode = searchMatchNode( memberFunctionMotherNode, _splitWord[i], B_FIND | B_CTOR | B_SUB );
											if( matchNode !is null ) matchNodes ~= matchNode;
										}
									}
									/*
									if( !matchNodes.length )
									{
										if( _AST_Head.kind & ( B_CLASS | B_TYPE ) )
										{
											if( _AST_Head.base.length )
											{
												matchNodes = searchMatchNodes( GLOBAL.parserManager[fullPathByOS(cSci.getFullPath)], _splitWord[i], B_CLASS | B_TYPE | B_NAMESPACE );
											}
										}
									}
									*/
									if( !matchNodes.length ) return null;
								}
								
								foreach( CASTnode a; matchNodes )
								{
									if( a.kind & ( B_SUB | B_FUNCTION ) )
									{
										if( TYPE == 1 )
										{
											if( a.lineNumber < a.endLineNum ) // Not Declare
											{
												bool bGetDeclare;
												foreach( CASTnode _node; searchMatchNodes( a, _splitWord[i], B_FIND | B_SUB ) )
												{
													if( _node.lineNumber == _node.endLineNum ) // Is Declare
													{
														nameSpaceNodes ~= _node;
														bGetDeclare = true;
														break;
													}
												}
												
												if( !bGetDeclare ) nameSpaceNodes ~= a;
											}
											else
											{
												nameSpaceNodes ~= a;
											}
										}
										else
										{
											nameSpaceNodes ~= a;
										}
									}
									else
									{
										nameSpaceNodes ~= a;
									}
								}
							
								if( _splitWord.length == 1 )
								{
									if( !nameSpaceNodes.length ) return null;
									
									foreach( CASTnode a; nameSpaceNodes )
										if( lowerCase( a.type ) == lowerCase( _AST_Head.type ) ) return a;
									
									return nameSpaceNodes[0];
								}
							}
							else
							{
								CASTnode[] tempNameSpaceNodes = nameSpaceNodes.dup;
								nameSpaceNodes.length = 0;
								foreach( CASTnode a; tempNameSpaceNodes )
								{
									if( a.kind & B_NAMESPACE )
									{
										auto matchNode = searchMatchMemberNode( a, _splitWord[i], B_FIND | B_SUB );
										if( matchNode !is null ) nameSpaceNodes ~= matchNode;
									}
									else
									{
										auto matchNodes = searchMatchMemberNodes( a, _splitWord[i], B_VARIABLE | B_FUNCTION | B_PROPERTY | B_OPERATOR | B_NAMESPACE | B_SUB | B_ENUMMEMBER );
										//if( matchNode !is null ) nameSpaceNodes ~= matchNode;
										if( matchNodes.length > 0 ) nameSpaceNodes ~= matchNodes;
									}
								}
								
								if( !nameSpaceNodes.length ) return null;
							}
							

							if( i < _splitWord.length - 1 )
							{
								CASTnode[] tempNameSpaceNodes = nameSpaceNodes.dup;
								nameSpaceNodes.length = 0;
								foreach( CASTnode a; tempNameSpaceNodes )
								{
									if( a.kind & ( B_VARIABLE | B_PARAM | B_FUNCTION ) )
									{
										if( !isDefaultType( ParserAction.getSeparateType( a.type, true ) ) )
										{
											auto matchNode = getType( a, lineNum );
											if( matchNode !is null ) nameSpaceNodes ~= matchNode;
										}
									}
									else
									{
										nameSpaceNodes ~= a;
									}
								}
								
								if( !nameSpaceNodes.length ) return null;
							}
							else
							{
								if( nameSpaceNodes.length ) 
								{
									foreach( CASTnode a; nameSpaceNodes )
										if( lowerCase( a.type ) == lowerCase( _AST_Head.type ) ) return a;
									
									returnNode = nameSpaceNodes[0];
								}
							}
						}
						
						return returnNode;
					}
					
					
					CASTnode _performAnalysisSplitWord( CASTnode _AST_Head, char[][] _splitWord )
					{
						auto _oriAST = _AST_Head;
						_AST_Head = null;
						
						char[][] usingNames = checkUsingNamespace( _oriAST, lineNum );
						if( usingNames.length )
						{
							foreach( char[] s; usingNames )
							{
								char[][] splitWithDot = Util.split( s, "." );
								char[][] namespaceSplitWord = splitWithDot ~ _splitWord;
								_AST_Head = _analysisSplitWord( _oriAST, namespaceSplitWord );
								if( _AST_Head !is null ) break;
							}
						}
						else
						{
							char[] _namespace = getNameSpaceWithDotTail( _oriAST );
							if( _namespace.length )
							{
								_namespace ~= Util.join( _splitWord, "." );
								_AST_Head = _analysisSplitWord( _oriAST, Util.split( _namespace, "." ) );
							}
						}
						
						if( _AST_Head is null )	_AST_Head = _analysisSplitWord( _oriAST, _splitWord );
						
						return _AST_Head;
					}
					
					
					
					if( TYPE == 2 && keyword_Btype > 0 )
					{
					}
					else
					{
						if( keyword_Btype > 0 )
						{
							// Already skip if is Declare, must be member function( B_CTOR / B_DTOR )
							splitWord.length = 0;
							splitWord ~= AST_Head.name; // Get the TYPE | CLASS | UNION name
							AST_Head = AST_Head.getFather;
						}
						// #define SCI_SETCURSOR 2386
						IupScintillaSendMessage( cSci.getIupScintilla, 2386, 4, 0 );
						AST_Head = _performAnalysisSplitWord( AST_Head, splitWord );
						IupScintillaSendMessage( cSci.getIupScintilla, 2386, -1, 0 );
						
						/*
						AST_Head = analysisSplitWord( AST_Head, splitWord );
						if( AST_Head is null )
						{
							char[][] usingNames = checkUsingNamespace( oriAST, lineNum );
							if( usingNames.length )
							{
								foreach( char[] s; usingNames )
								{
									char[][] splitWithDot = Util.split( s, "." );
									char[][] namespaceSplitWord = splitWithDot ~ splitWord;
									auto oriAST2 = analysisSplitWord( oriAST, namespaceSplitWord );
									if( oriAST2 !is null )
									{
										AST_Head = oriAST2;
										break;
									}
								}
							}	
							else
							{
								char[] _namespace = getNameSpaceWithDotTail( oriAST );
								if( _namespace.length )
								{
									_namespace ~= Util.join( splitWord, "." );
									auto oriAST2 = analysisSplitWord( oriAST, Util.split( _namespace, "." ) );
									if( oriAST2 !is null ) AST_Head = oriAST2;
								}
							}
						}
						*/
					}
					

					if( AST_Head is null ) return;
					
					if( TYPE == 0 )
					{
						if( AST_Head is null ) return;
						
						char[]	_param, _type;
						getTypeAndParameter( AST_Head, _type, _param );
						if( GLOBAL.showTypeWithParams != "ON" ) _param = "";
						
						switch( AST_Head.kind )
						{
							case B_FUNCTION, B_SUB: 	if( !_type.length ) _type = "void"; 	break;
							case B_TYPE:				_type = "TYPE"; 						break;
							case B_CLASS:				_type = "CLASS"; 						break;
							case B_UNION:				_type = "UNION"; 						break;
							case B_ENUM:				_type = "ENUM"; 						break;
							case B_ENUMMEMBER:			_type = "ENUMMEMBER"; 					break;
							case B_NAMESPACE: 			_type = "NAMESPACE"; 					break;
							case B_BI, B_BAS:
								return;
							default:
						}
						
						IupScintillaSendMessage( cSci.getIupScintilla, 2206, tools.convertIupColor( GLOBAL.editColor.showTypeFore.toDString ), 0 ); //SCI_CALLTIPSETFORE 2206
						IupScintillaSendMessage( cSci.getIupScintilla, 2205, tools.convertIupColor( GLOBAL.editColor.showTypeBack.toDString ), 0 ); //SCI_CALLTIPSETBACK 2205

						auto _rNode = ParserAction.getRoot( AST_Head );

						char[] _list;
						if( _rNode.name == cSci.getFullPath )
							_list = ( "@ ThisFile ...[" ~ Integer.toString( AST_Head.lineNumber ) ~ "]\n" );
						else
							_list = ( "@ \"" ~ _rNode.name ~ "\"" ~ " ...[" ~ Integer.toString( AST_Head.lineNumber ) ~ "]\n" );

						int filePathPos = _list.length;
						
						
						char[] nameSpaceTitle;
						switch( AST_Head.kind )
						{
							case B_SUB:
								if( AST_Head.getFather.kind & ( B_TYPE | B_CLASS ) )
								{
									nameSpaceTitle = getNameSpaceWithDotTail( AST_Head.getFather );
									_list ~= ( "MEMBER_SUBROUTINE: < " ~ nameSpaceTitle ~ AST_Head.getFather.name ~ " >\n" );
								}
								else
									 _list ~= "SUBROUTINE:\n";
								break;
							case B_FUNCTION:
								if( AST_Head.getFather.kind & ( B_TYPE | B_CLASS ) )
								{
									nameSpaceTitle = getNameSpaceWithDotTail( AST_Head.getFather );
									_list ~= ( "MEMBER_FUNCTION: < " ~ nameSpaceTitle ~ AST_Head.getFather.name ~ " >\n" );
								}
								else
									_list ~= "FUNCTION:\n";
								break;
							case B_VARIABLE:
								if( AST_Head.getFather.kind & ( B_TYPE | B_CLASS ) )
								{
									nameSpaceTitle = getNameSpaceWithDotTail( AST_Head.getFather );
									_list ~= ( "MEMBER_VARIABLE: < " ~ nameSpaceTitle ~ AST_Head.getFather.name ~ " >\n" );
								}
								else 
									_list ~= "VARIABLE:\n";
								break;
								
							case B_PROPERTY:
								if( AST_Head.getFather.kind & ( B_TYPE | B_CLASS ) )
								{
									nameSpaceTitle = getNameSpaceWithDotTail( AST_Head.getFather );
									_list ~= ( "MEMBER_PROPERTY: < " ~ nameSpaceTitle ~ AST_Head.getFather.name ~ " >\n" );
								}
								else 
									_list ~= "PROPERTY:\n";
								break;

							case B_OPERATOR:
								if( AST_Head.getFather.kind & ( B_TYPE | B_CLASS ) )
								{
									nameSpaceTitle = getNameSpaceWithDotTail( AST_Head.getFather );
									_list ~= ( "MEMBER_OPERATOR: < " ~ nameSpaceTitle ~ AST_Head.getFather.name ~ " >\n" );
								}
								else 
									_list ~= "OPERATOR:\n";
								break;

							case B_PARAM:	 	_list ~= "PARAMETER:\n";	break;
							case B_CTOR:	 	_list ~= "CTOR:\n";			break;
							case B_DTOR:	 	_list ~= "DTOR:\n";			break;
							default:
						}
						
						
						//IupMessage( "AST_HEAD", toStringz( "TYPE :" ~ AST_Head.type ~ "\n" ~ "NAME :" ~ AST_Head.name ~ "\n" ) );
						if( AST_Head.kind & B_NAMESPACE )
						{
							char[] _name = AST_Head.name;
							
							_name= getNameSpaceWithDotTail( AST_Head ) ~ _name;
							_list ~= ScintillaAction.textWrap( ( _type ~ " " ~ _name ) ).dup;
						}
						else if( AST_Head.kind & ( B_FUNCTION | B_SUB | B_PROPERTY | B_OPERATOR ) )
						{
							_list ~= ScintillaAction.textWrap( ( ( _type.length ? _type ~ " " : null ) ~ AST_Head.name ~ ( _param.length ? _param : "()" ) ) ).dup;
						}
						else if( AST_Head.kind & ( B_VARIABLE ) )
						{
							if( !_type.length )	// VAR declare...
							{
								if( AST_Head.base.length )
								{
									int starIndex;
									for( starIndex = 0; starIndex < AST_Head.base.length; ++ starIndex )
										if( AST_Head.base[starIndex] != '*' ) break;
								
								
									auto typeNode = _performAnalysisSplitWord( AST_Head, Util.split( AST_Head.base[starIndex..$], "." ) ); //_analysisSplitWord( AST_Head, Util.split( AST_Head.base, "." ) );
									/*
									while( typeNode !is null ) // Get Top
									{
										auto a = analysisSplitWord( typeNode, Util.split( typeNode.type, "." ) );
										if( a is null ) break; else typeNode = a;
									}
									*/
									if( typeNode !is null )
									{
										//IupMessage( "typeNode", toStringz( "TYPE :" ~ typeNode.type ~ "\n" ~ "NAME :" ~ typeNode.name ~ "\n" ) );
										getTypeAndParameter( typeNode, _type, _param );
										if( !_type.length ) _type = typeNode.name;			// The node without type, like TYPE XXX
									}
									else
										_type = AST_Head.base;
									
									// var text = *IupGetAttribute(textbox, IUP_VALUE)
									for( int i = 0; i < starIndex; ++ i )
									{
										if( _type.length > 0 )
										{
											if( _type[$-1] == '*' ) _type = _type[0..$-1].dup; else break;
										}
										else
											break;
									}
								}
							}
						
							_list ~= ScintillaAction.textWrap( ( _type ~ " " ~ AST_Head.name ) ).dup; // Without parameters
						}
						else
							_list ~= ScintillaAction.textWrap( ( ( _type.length ? _type ~ " " : null ) ~ AST_Head.name ~ _param ) ).dup;
						
						
						if( AST_Head.kind & ( B_TYPE | B_CLASS | B_UNION ) )
						{
							foreach( CASTnode _child; AST_Head.getChildren() )
								if( _child.kind & B_CTOR ) _list ~= ScintillaAction.textWrap( ( "\n" ~ _child.name ~ _child.type ) );
						}

						showTypeContent = _list;
						cleanCalltipContainer(); // Clear Call Tip Container
						IupScintillaSendMessage( cSci.getIupScintilla, 2213, 1, 0 ); // SCI_CALLTIPSETPOSITION 2213
						scope _result = new IupString( showTypeContent );
						IupScintillaSendMessage( cSci.getIupScintilla, 2200, currentPos, cast(int) _result.toCString ); // SCI_CALLTIPSHOW 2200
						IupScintillaSendMessage( cSci.getIupScintilla, 2213, 0, 0 ); // SCI_CALLTIPSETPOSITION 2213
						IupScintillaSendMessage( cSci.getIupScintilla, 2204, 0, filePathPos ); // SCI_CALLTIPSETHLT 2204
						IupScintillaSendMessage( cSci.getIupScintilla, 2207, tools.convertIupColor( GLOBAL.editColor.showTypeHLT.toDString ), 0 ); // SCI_CALLTIPSETFOREHLT 2207
					}
					else
					{
						bool		bGotoMemberProcedure;
						char[]		className, procedureName;
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
										className = AST_Head.getFather.name; // Get Class Name
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
								// The AST_HEAD is already TYPE | CLASS | UNION struct
								foreach( CASTnode _node; AST_Head.getChildren )
								{
									if( _node.kind & keyword_Btype )
									{
										
										AST_Head = _node;
										break;
									}
								}				
							}
						}
						
						// Get lineNum
						lineNum = AST_Head.lineNumber;
						
						CASTnode	_rootNode = ParserAction.getRoot( AST_Head );
						char[]		fullPath = _rootNode.name;
						scope _fp = new FilePath( fullPath );
						
						if( bGotoMemberProcedure ) // Mean Goto Function with code( Type = 2 )
						{
							//IupMessage( "AST_Head", toStringz( Integer.toString( AST_Head.kind ) ~ "\n" ~ AST_Head.name ~ "\n" ~ Integer.toString( AST_Head.lineNumber ) ) );
							char[][] exceptFiles;
							exceptFiles ~= fullPath;
							
							if( className.length )
							{
								switch( AST_Head.kind )
								{
									case B_SUB, B_FUNCTION, B_OPERATOR, B_PROPERTY:				procedureName = className ~ "." ~ procedureName; break;
									case B_CTOR, B_DTOR:										procedureName = className;						 break;
									default:
								}
							}
							
							char[][] nameSpaces = Util.split( getNameSpaceWithDotTail( AST_Head.getFather ), "." );

							// Declare & procedure body at same file
							CASTnode _resultNode = getMatchNodeInFile( oriAST, nameSpaces, procedureName, fullPath, AST_Head.kind );
							if( _resultNode !is null )
							{
								if( GLOBAL.navigation.addCache( fullPath, _resultNode.lineNumber ) ) actionManager.ScintillaAction.openFile( fullPath, _resultNode.lineNumber );
								return;
							}
							
							// Not Same File, Continue search
							// Check BAS file first								
							if( lowerCase( _fp.ext ) == "bi" )
							{
								exceptFiles ~= ( _fp.path() ~ _fp.name ~ ".bas" );
								_resultNode = getMatchNodeInFile( oriAST, nameSpaces, procedureName, exceptFiles[$-1], AST_Head.kind );
								if( _resultNode !is null )
								{
									if( GLOBAL.navigation.addCache( exceptFiles[$-1], _resultNode.lineNumber ) ) actionManager.ScintillaAction.openFile( exceptFiles[$-1], _resultNode.lineNumber );
									return;
								}
								else
								{
									exceptFiles ~= ( _fp.path() ~ _fp.name ~ "." ~ GLOBAL.extraParsableExt );
									_resultNode = getMatchNodeInFile( oriAST, nameSpaces, procedureName, exceptFiles[$-1], AST_Head.kind );
									if( _resultNode !is null )
									{
										if( GLOBAL.navigation.addCache( exceptFiles[$-1], _resultNode.lineNumber ) ) actionManager.ScintillaAction.openFile( exceptFiles[$-1], _resultNode.lineNumber );
										return;
									}
								}
							}
							
							// Check All Project
							_resultNode = getMatchNodeInProject( oriAST, nameSpaces, procedureName, ProjectAction.getActiveProjectName(), B_SUB | B_FUNCTION, exceptFiles );
							_rootNode = ParserAction.getRoot( _resultNode );
							if( _rootNode !is null )
							{
								//IupMessage( "KIND", toStringz( Integer.toString( _resultNode.kind ) ~ "\n" ~ _resultNode.name ~ "\n" ~ Integer.toString( _resultNode.lineNumber ) ) );
								if( GLOBAL.navigation.addCache( _rootNode.name, _resultNode.lineNumber ) ) actionManager.ScintillaAction.openFile( _rootNode.name, _resultNode.lineNumber );
								return;
							}
						}
						
						if( GLOBAL.navigation.addCache( fullPath, lineNum ) ) actionManager.ScintillaAction.openFile( fullPath, lineNum );
					}
				}
			}
			catch( Exception e )
			{
				IupMessage( "Bug", toStringz( "toDefintionAndType() Error:\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ Integer.toString( e.line ) ) );
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

		static char[] InsertEnd( Ihandle* iupSci, int lin, int pos )
		{
			// #define SCI_LINEFROMPOSITION 2166
			lin--; // ScintillaAction.getLinefromPos( iupSci, POS ) ) begin from 0
			
			bool _isHead( int _pos )
			{
				char[] _word;
				
				while( --_pos >= 0 )
				{
					char[] s = fromStringz( IupGetAttributeId( iupSci, "CHAR", _pos ) );
					
					int key = cast(int) s[0];
					if( key >= 0 && key <= 127 )
					{
						if( s == ":" || s == "\n" ) break;
						_word ~= s;
					}
				}
				
				if( Util.trim( _word ).length ) return false;
				
				return true;
			}
			
			bool _isTail( int _pos )
			{
				char[] _word;
				
				while( _pos < cast(int) IupScintillaSendMessage( iupSci, 2136, lin, 0 ) ) // SCI_GETLINEENDPOSITION 2136 )
				{
					char[] s = fromStringz( IupGetAttributeId( iupSci, "CHAR", ++_pos ) );
					int key = cast(int) s[0];
					if( key >= 0 && key <= 127 )
					{
						if( s == ":" || s == "\n" ) break;
						_word ~= s;
					}
				}
				
				if( Util.trim( _word ).length ) return false;
				
				return true;
			}
			
			/*
				target....	or	target	= -1 ( _checkType )
				target		= 0 ( _checkType )
				target....	= 1 ( _checkType )
			....target		= 2 ( _checkType )
			....target....	= 3 ( _checkType )
			*/
			int _check( char[] target, int _checkType )
			{
				int POS = skipCommentAndString( iupSci, pos, target, 0 );
				if( POS > -1 )
				{
					if( lin == ScintillaAction.getLinefromPos( iupSci, POS ) )
					{
						if( _checkType == -1 )
						{
							if( _isHead( POS ) ) return POS; else return -1;
						}
						else if( _checkType == 0 )
						{
							if( !_isTail( POS + target.length ) ) return -1;
							if( !_isHead( POS ) ) return -1;
						}
						
						if( _checkType & 1 )
						{
							if( _isTail( POS + target.length ) ) return -1;
						}
						
						if( _checkType & 2 )
						{
							if( _isHead( POS ) ) return -1;
						}
						else
						{
							if( !_isHead( POS ) ) return -1;
						}

						return POS;
					}
				}
				
				return -1;
			}
			
			char[] _checkProcedures( char[] keyword )
			{
				int _pos = _check( keyword, 1 );
				if( _pos > -1 )
				{
					int c0 = DocumentTabAction.getKeyWordCount( iupSci, keyword, "" );
					c0 += DocumentTabAction.getKeyWordCount( iupSci, keyword, "private" );
					c0 += DocumentTabAction.getKeyWordCount( iupSci, keyword, "protected" );
					c0 += DocumentTabAction.getKeyWordCount( iupSci, keyword, "public" );
					int c1 = DocumentTabAction.getKeyWordCount( iupSci, keyword, "end" );
					if( c0 > c1 ) return "end " ~ keyword;
				}
				else
				{
					_pos = _check( keyword, 3 );
					if( _pos > -1 )
					{
						char[] beforeWord = DocumentTabAction.getBeforeWord( iupSci, _pos - 1 );
						switch( beforeWord )
						{
							case "private", "protected", "public":
								int c0 = DocumentTabAction.getKeyWordCount( iupSci, keyword, "" );
								c0 += DocumentTabAction.getKeyWordCount( iupSci, keyword, "private" );
								c0 += DocumentTabAction.getKeyWordCount( iupSci, keyword, "protected" );
								c0 += DocumentTabAction.getKeyWordCount( iupSci, keyword, "public" );							
								int c1 = DocumentTabAction.getKeyWordCount( iupSci, keyword, "end" );
								if( c0 > c1 ) return "end " ~ keyword;
							default:
						}
					}
				}
				
				return null;
			}
			
			
			
			int		POS;
			char[]	resultProcedures = _checkProcedures( "sub" );
			if( resultProcedures.length ) return resultProcedures;

			resultProcedures = _checkProcedures( "property" );
			if( resultProcedures.length ) return resultProcedures;
			
			resultProcedures = _checkProcedures( "operator" );
			if( resultProcedures.length ) return resultProcedures;
			
			resultProcedures = _checkProcedures( "constructor" );
			if( resultProcedures.length ) return resultProcedures;

			resultProcedures = _checkProcedures( "destructor" );
			if( resultProcedures.length ) return resultProcedures;

			
			POS = _check( "function", 1 );
			if( POS > -1 )
			{
				char[] afterWord = DocumentTabAction.getAfterWord( iupSci, POS + 8 );
				if( afterWord.length )
				{
					if( afterWord[0] != '=' )
					{
						int c0 = DocumentTabAction.getKeyWordCount( iupSci, "function", "" );
						c0 += DocumentTabAction.getKeyWordCount( iupSci, "function", "private" );
						c0 += DocumentTabAction.getKeyWordCount( iupSci, "function", "protected" );
						c0 += DocumentTabAction.getKeyWordCount( iupSci, "function", "public" );
						int c1 = DocumentTabAction.getKeyWordCount( iupSci, "function", "end" );
						if( c0 > c1 ) return "end function";
					}
				}
			}
			else
			{
				POS = _check( "function", 3 );
				if( POS > -1 )
				{
					char[] beforeWord = DocumentTabAction.getBeforeWord( iupSci, POS - 1 );
					switch( beforeWord )
					{
						case "private", "protected", "public":
							int c0 = DocumentTabAction.getKeyWordCount( iupSci, "function", "" );
							c0 += DocumentTabAction.getKeyWordCount( iupSci, "function", "private" );
							c0 += DocumentTabAction.getKeyWordCount( iupSci, "function", "protected" );
							c0 += DocumentTabAction.getKeyWordCount( iupSci, "function", "public" );							
							int c1 = DocumentTabAction.getKeyWordCount( iupSci, "function", "end" );
							if( c0 > c1 ) return "end function";
						default:
					}
				}
			}




			POS= _check( "extern", 1 );
			if( POS > -1 )
			{
				char[] afterWord = DocumentTabAction.getAfterWord( iupSci, POS + 6 );
				if( afterWord.length )
				{
					if( afterWord[0] == '"' )
					{
						int c0 = DocumentTabAction.getKeyWordCount( iupSci, "extern", "" );
						int c1 = DocumentTabAction.getKeyWordCount( iupSci, "extern", "end" );
						if( c0 > c1 ) return "end extern";
					}
				}
			}		
		
			POS= _check( "type", 1 );
			if( POS > -1 )
			{
				int c0 = DocumentTabAction.getKeyWordCount( iupSci, "type", "" );
				int c1 = DocumentTabAction.getKeyWordCount( iupSci, "type", "end" );
				if( c0 > c1 ) return "end type";
			}

			POS= _check( "select", 1 );
			if( POS > -1 )
			{
				int c0 = DocumentTabAction.getKeyWordCount( iupSci, "select", "" );
				int c1 = DocumentTabAction.getKeyWordCount( iupSci, "select", "end" );
				if( c0 > c1 ) return "end select";
			}

			POS = _check( "namespace", 1 );
			if( POS > -1 )
			{
				int c0 = DocumentTabAction.getKeyWordCount( iupSci, "namespace", "" );
				int c1 = DocumentTabAction.getKeyWordCount( iupSci, "namespace", "end" );
				if( c0 > c1 ) return "end namespace";
			}

			POS = _check( "with", 1 );
			if( POS > -1 )
			{
				int c0 = DocumentTabAction.getKeyWordCount( iupSci, "with", "" );
				int c1 = DocumentTabAction.getKeyWordCount( iupSci, "with", "end" );
				if( c0 > c1 ) return "end with";
			}

			POS = _check( "enum", -1 );
			if( POS > -1 )
			{
				int c0 = DocumentTabAction.getKeyWordCount( iupSci, "enum", "" );
				int c1 = DocumentTabAction.getKeyWordCount( iupSci, "enum", "end" );
				if( c0 > c1 ) return "end enum";
			}

			POS = _check( "scope", 0 );
			if( POS > -1 )
			{
				int c0 = DocumentTabAction.getKeyWordCount( iupSci, "scope", "" );
				int c1 = DocumentTabAction.getKeyWordCount( iupSci, "scope", "end" );
				if( c0 > c1 ) return "end scope";
			}	

			/*
			POS		= getProcedurePos( iupSci, pos, "#if" );
			if( POS > -1 && lin == ScintillaAction.getLinefromPos( iupSci, POS ) ) return "#endif";

			POS		= getProcedurePos( iupSci, pos, "#ifdef" );
			if( POS > -1 && lin == ScintillaAction.getLinefromPos( iupSci, POS ) ) return "#endif";

			POS		= getProcedurePos( iupSci, pos, "#ifndef" );
			if( POS > -1 && lin == ScintillaAction.getLinefromPos( iupSci, POS ) ) return "#endif";

			POS		= getProcedurePos( iupSci, pos, "#macro" );
			if( POS > -1 && lin == ScintillaAction.getLinefromPos( iupSci, POS ) ) return "#endmacro";
			*/
			
			// #IF
			POS = _check( "#if", 1 );
			if( POS > -1 )
			{
				int _p0 = skipCommentAndString( iupSci, POS + 3, "#endif", 1 );
				int _p1 = skipCommentAndString( iupSci, POS + 3, "#if", 1 );
				if( _p0 == -1 || ( _p1 > -1 && _p0 > _p1 ) ) return "#endif";
			}
			
			// #IFDEF
			POS = _check( "#ifdef", 1 );
			if( POS > -1 )
			{
				int _p0 = skipCommentAndString( iupSci, POS + 6, "#endif", 1 );
				int _p1 = skipCommentAndString( iupSci, POS + 6, "#ifdef", 1 );
				if( _p0 == -1 || ( _p1 > -1 && _p0 > _p1 ) ) return "#endif";
			}
			
			// #IFNDEF
			POS = _check( "#ifndef", 1 );
			if( POS > -1 )
			{
				int _p0 = skipCommentAndString( iupSci, POS + 7, "#endif", 1 );
				int _p1 = skipCommentAndString( iupSci, POS + 7, "#ifndef", 1 );
				if( _p0 == -1 || ( _p1 > -1 && _p0 > _p1 ) ) return "#endif";
			}
			
			// #MACRO
			POS = _check( "#macro", 1 );
			if( POS > -1 )
			{
				int _p0 = skipCommentAndString( iupSci, POS + 6, "#endmacro", 1 );
				int _p1 = skipCommentAndString( iupSci, POS + 6, "#macro", 1 );
				if( _p0 == -1 || ( _p1 > -1 && _p0 > _p1 ) ) return "#endmacro";
			}
			
			
			
			
			POS = _check( "if", 1 );
			if( POS > -1 )		
			{
				int c0 = DocumentTabAction.getKeyWordCount( iupSci, "if", "", "then" );
				int c1 = DocumentTabAction.getKeyWordCount( iupSci, "endif", "" );
				c1 += DocumentTabAction.getKeyWordCount( iupSci, "if", "end" );
				if( c0 > c1 ) return "end if";
				//if( _secondCheck( "if", "dne", POS + 2 ) ) return "end if";
			}

			POS = _check( "for", 1 );
			if( POS > -1 )
			{
				int c0 = DocumentTabAction.getKeyWordCount( iupSci, "for", "" );
				int c1 = DocumentTabAction.getKeyWordCount( iupSci, "next", "" );
				if( c0 > c1 ) return "next";
			}		
			
			POS = _check( "do", 0 );
			if( POS > -1 )
			{
				int c0 = DocumentTabAction.getKeyWordCount( iupSci, "do", "" );
				int c1 = DocumentTabAction.getKeyWordCount( iupSci, "loop", "" );
				if( c0 > c1 ) return "loop";
			}
			
			POS = _check( "do", 1 );
			if( POS > -1 )
			{
				int c0 = DocumentTabAction.getKeyWordCount( iupSci, "do", "" );
				int c1 = DocumentTabAction.getKeyWordCount( iupSci, "loop", "" );
				if( c0 > c1 ) return "loop";
			}
			
			POS = _check( "while", 1 );
			if( POS > -1 )
			{
				int c0 = DocumentTabAction.getKeyWordCount( iupSci, "while", "" );
				int c1 = DocumentTabAction.getKeyWordCount( iupSci, "wend", "" );
				if( c0 > c1 ) return "wend";
			}		
			
			/+
			POS		= getProcedurePos( iupSci, pos, "if" );
			if( POS > -1 && lin == ScintillaAction.getLinefromPos( iupSci, POS ) )

			// FOR
			if( _check( "for", 1 ) > -1 ) return "next";
			POS = _check( "for", 1 );
			if( POS > -1 )
			{
				int _p0 = skipCommentAndString( iupSci, POS + 3, "next", 1 );
				int _p1 = skipCommentAndString( iupSci, POS + 3, "for", 1 );
				if( _p0 == -1 || ( _p1 > -1 && _p0 > _p1 ) ) return "next";
			}

			// DO
			POS = _check( "do", 0 );
			if( POS > -1 )
			{
				int _p0 = skipCommentAndString( iupSci, POS + 2, "loop", 1 );
				int _p1 = skipCommentAndString( iupSci, POS + 2, "do", 1 );
				if( _p0 == -1 || ( _p1 > -1 && _p0 > _p1 ) ) return "loop";
			}

			// DO
			POS = _check( "do", 1 );
			if( POS > -1 )
			{
				int _p0 = skipCommentAndString( iupSci, POS + 2, "loop", 1 );
				int _p1 = skipCommentAndString( iupSci, POS + 2, "do", 1 );
				if( _p0 == -1 || ( _p1 > -1 && _p0 > _p1 ) ) return "loop";
			}

			// while
			POS = _check( "while", 1 );
			if( POS > -1 )
			{
				int _p0 = skipCommentAndString( iupSci, POS + 5, "wend", 1 );
				int _p1 = skipCommentAndString( iupSci, POS + 5, "while", 1 );
				if( _p0 == -1 || _p1 == -1 ) return "wend";
			}
			+/

			return null;
		}
		
		
		static bool callAutocomplete( Ihandle *ih, int pos, char[] text, char[] alreadyInput, bool bForce = false )
		{
			if( preLoadContainerThread !is null )
			{
				if( preLoadContainerThread.isRunning )
					preLoadContainerThread.join();
				else
				{
					delete preLoadContainerThread;
					preLoadContainerThread = null;
				}
			}

			
			auto cSci = ScintillaAction.getCScintilla( ih );
			if( cSci is null ) return false;

			if( !bForce )
			{
				try
				{
					/+
					if( text == "(" )
					{
						// CScintilla_action_cb() in scintilla.d will call updateCallTip(), so skip it......
					}
					else
					+/
					if( text != ")" && text != "," && text != "(" && text != "\n" )
					{
						if( showListThread is null )
						{
							if( fromStringz( IupGetAttribute( ih, "AUTOCACTIVE" ) ) == "YES" ) IupSetAttribute( ih, "AUTOCCANCEL", "YES" );
							
							// wait showCallTipThread thread done
							try
							{
								if( showCallTipThread !is null )
									if( showCallTipThread.isRunning ) showCallTipThread.join();
							}
							catch( Exception e){}
							
							// If using IUP command in Thread, join() occur infinite loop, so......
							bool		bDot, bCallTip;
							CASTnode	AST_Head;
							int			lineNum;
							char[][] 	splitWord = getNeedDataForThread( ih, text, pos, lineNum, bDot, bCallTip, AST_Head );
							
							showListThread = new CShowListThread( AST_Head, pos, lineNum, bDot, bCallTip, splitWord, text );
							showListThread.start();
							
							if( fromStringz( IupGetAttribute( timer, "RUN" ) ) != "YES" ) IupSetAttribute( timer, "RUN", "YES" );
						}
					}
					else
					{
						if( showListThread !is null )
						{
							delete showListThread;
							showListThread = null;
						}
					}
				}
				catch( Exception e )
				{
					IupMessage( "ERROR", "callAutocomplete Exceprtion!" );
				}
			}
			else
			{
				//if( timer != null )	IupSetAttribute( timer, "RUN", "NO" );
				char[] list = charAdd( ih, pos, text, bForce );

				if( list.length )
				{
					char[][] splitWord = getDivideWord( alreadyInput );

					alreadyInput = splitWord[$-1];
					if( text == "(" )
					{
						if( fromStringz( IupGetAttribute( ih, "AUTOCACTIVE" ) ) == "YES" ) IupSetAttribute( ih, "AUTOCCANCEL", "YES" );

						IupScintillaSendMessage( ih, 2205, tools.convertIupColor( GLOBAL.editColor.callTipBack.toDString ), 0 ); // SCI_CALLTIPSETBACK 2205
						IupScintillaSendMessage( ih, 2206, tools.convertIupColor( GLOBAL.editColor.callTipFore.toDString ), 0 ); // SCI_CALLTIPSETFORE 2206
						
						//SCI_CALLTIPSETHLT 2204
						scope _result = new IupString( ScintillaAction.textWrap( list ) );
						IupScintillaSendMessage( ih, 2200, pos, cast(int) _result.toCString );
						
						calltipContainer.push( Integer.toString( ScintillaAction.getLinefromPos( ih, pos ) ) ~ ";" ~ list );
						
						int highlightStart, highlightEnd;
						callTipSetHLT( list, 1, highlightStart, highlightEnd );
						if( highlightEnd > -1 ) IupScintillaSendMessage( ih, 2204, highlightStart, highlightEnd ); // SCI_CALLTIPSETHLT 2204
					}
					else
					{
						scope _result = new IupString( list );
						if( !alreadyInput.length ) IupScintillaSendMessage( ih, 2100, alreadyInput.length - 1, cast(int) _result.toCString ); else IupSetAttributeId( ih, "AUTOCSHOW", alreadyInput.length - 1, _result.toCString );
					}
					return true;
				}
			}

			return false;
		}
		
		static bool updateCallTip( Ihandle* ih, int pos, char* singleWord )
		{
			if( !bSkipAutoComplete ) bSkipAutoComplete = true; else return false;
			
			if( fromStringz( IupGetAttribute( ih, "AUTOCACTIVE" ) ) == "YES" )
			{
				if( singleWord != null )
				{
					char[] s = fromStringz( singleWord );
					if( s == "(" || s == ")" || s == "," ) IupSetAttribute( ih, "AUTOCCANCEL", "YES" ); else return false;
				}
				else
				{
					return false;
				}
			}
		

			bool	bContinue;
			int		commaCount, parenCount, firstOpenParenPosFromDocument;
			char[]	procedureNameFromList, LineHeadText;
			int		lineNumber, currentLn = ScintillaAction.getCurrentLine( ih ) - 1;
			int		lineHeadPos = cast(int) IupScintillaSendMessage( ih, 2167, ScintillaAction.getCurrentLine( ih ) - 1, 0 );
			
			
			char[] _getLineHeadText( int _pos, char[] _result = "" )
			{
				while( _pos >= lineHeadPos )
					_result = fromStringz( IupGetAttributeId( ih, "CHAR", _pos-- ) ) ~ _result;
					
				return _result;
			}
			
			
			if( singleWord == null )
			{
				int currentPos = ScintillaAction.getCurrentPos( ih );
				LineHeadText = _getLineHeadText( pos - 1 );
				/+
				if( currentPos > pos ) // BS
				{
					/*
					01234567
					KUAN,
					Before pos at 5, after press BS, the current pos = 4
					*/
					LineHeadText = _getLineHeadText( pos - 2 );
				}
				else // DEL
				{
					LineHeadText = _getLineHeadText( pos - 1 );
				}
				+/
			}
			else
			{
				char[] s = fromStringz( singleWord );
				
				// Press Enter, leave...
				if( s == "\n" )
				{
					if( cast(int) IupScintillaSendMessage( ih, 2202, 0, 0 ) == 1 ) IupScintillaSendMessage( ih, 2201, 0, 0 ); //  SCI_CALLTIPCANCEL 2201 , SCI_CALLTIPACTIVE 2202
					noneListProcedureName = "";
					cleanCalltipContainer();
					return false;
				}
				
				LineHeadText = _getLineHeadText( pos - 1, s );
			}

			char[]	procedureNameFromDocument = AutoComplete.parseProcedureForCalltip( ih, lineHeadPos, LineHeadText, commaCount, parenCount, firstOpenParenPosFromDocument ); // from document
			//char[]	procedureNameFromDocument = AutoComplete.parseProcedureForCalltip( ih, pos, commaCount, parenCount, firstOpenParenPosFromDocument ); // from document

			if( commaCount == 0 )
			{
				if( calltipContainer.size > 0 ) calltipContainer.pop();
				if( cast(int) IupScintillaSendMessage( ih, 2202, 0, 0 ) == 1 ) IupScintillaSendMessage( ih, 2201, 0, 0 ); //  SCI_CALLTIPCANCEL 2201 , SCI_CALLTIPACTIVE 2202
				return false;
			}



			// Last time we get null "List" at same line and same procedureNameFromDocument, leave!!!!!
			if( noneListProcedureName == Integer.toString( firstOpenParenPosFromDocument ) ~ ";" ~ procedureNameFromDocument ) return false;
	
	
	
	
			char[]	list;
			char[]	listInContainer = calltipContainer.size > 0 ? calltipContainer.top() : "";
			
			if( listInContainer.length )
			{
				int semicolonPos = Util.index( listInContainer, ";" );
				if( semicolonPos < listInContainer.length )
				{
					lineNumber = Integer.toInt( listInContainer[0..semicolonPos] );
					if( currentLn == lineNumber )
					{
						int openParenPos = Util.index( listInContainer, "(" );
						if( openParenPos > semicolonPos )
						{
							//char[] procedureNameFromList;
							for( int i = openParenPos - 1; i > semicolonPos; -- i )
							{
								if( listInContainer[i] == ' ' ) break;
								procedureNameFromList = listInContainer[i] ~ procedureNameFromList;
							}
							
							if( procedureNameFromList != "Constructor" )
							{
								if( lowerCase(procedureNameFromList) == lowerCase(procedureNameFromDocument) )
								{
									bContinue = true;
									list = listInContainer[semicolonPos+1..$].dup;
								}
							}
							else
							{
								bContinue = true;
								list = listInContainer[semicolonPos+1..$].dup;
							}
						}	
					}
				}
			}

			if( !list.length )
			{
				if( GLOBAL.toggleCompleteAtBackThread == "ON" )
				{
					if( fromStringz( IupGetAttribute( ih, "AUTOCACTIVE" ) ) == "NO" )
					{
						if( procedureNameFromDocument.length )
						{
							if( showCallTipThread is null )
							{
								if( cast(int) IupScintillaSendMessage( ih, 2202, 0, 0 ) == 1 ) IupScintillaSendMessage( ih, 2201, 0, 0 ); //  SCI_CALLTIPCANCEL 2201 , SCI_CALLTIPACTIVE 2202
								
								try
								{
									if( showListThread !is null ) return false;
										//if( showListThread.isRunning ) showListThread.join();
								}
								catch( Exception e){}
								
								// If using IUP command in Thread, join() occur infinite loop, so......
								bool		bDot, bCallTip;
								CASTnode	AST_Head;
								int			lineNum;
								char[][] 	splitWord = getNeedDataForThread( ih, "(", firstOpenParenPosFromDocument, lineNum, bDot, bCallTip, AST_Head );
								
								showCallTipThread = new CShowListThread( AST_Head, firstOpenParenPosFromDocument, lineNum, bDot, bCallTip, splitWord, "(", commaCount, procedureNameFromDocument );									
								showCallTipThread.start();									
								
								if( fromStringz( IupGetAttribute( timer, "RUN" ) ) != "YES" ) IupSetAttribute( timer, "RUN", "YES" );
							}
						}
					}
					
					return false;
				}
				else
				{
					// commaCount != 0 and calltipContainer is empty, Re-get the list
					//IupMessage("updateCallTip", "NULL" );
					list = charAdd( ih, firstOpenParenPosFromDocument, "(", true );
					if( list.length )
					{
						bContinue = true;
						calltipContainer.push( Integer.toString( ScintillaAction.getLinefromPos( ih, pos ) ) ~ ";" ~ list );
					}
				}
			}
			
			if( !bContinue )
			{
				if( calltipContainer.size > 1 )
				{
					calltipContainer.pop();
					list = calltipContainer.top;
					int semicolonPos = Util.index( list, ";" );
					if( semicolonPos < list.length )
					{
						list = list[semicolonPos+1..$].dup;
						bContinue = true;
					}
				}
			}
			
			
			if( !bContinue )
			{
				if( calltipContainer.size > 0 ) calltipContainer.clear();
				//if( cast(int) IupScintillaSendMessage( ih, 2202, 0, 0 ) == 1 ) IupScintillaSendMessage( ih, 2201, 1, 0 ); //  SCI_CALLTIPCANCEL 2201 , SCI_CALLTIPACTIVE 2202
					
				return false;
			}
			else
			{
				if( list.length )
				{
					if( fromStringz( IupGetAttribute( ih, "AUTOCACTIVE" ) ) == "NO" && cast(int) IupScintillaSendMessage( ih, 2202, 0, 0 ) == 0 )
					{
						IupScintillaSendMessage( ih, 2205, tools.convertIupColor( GLOBAL.editColor.callTipBack.toDString ), 0 ); // SCI_CALLTIPSETBACK 2205
						IupScintillaSendMessage( ih, 2206, tools.convertIupColor( GLOBAL.editColor.callTipFore.toDString ), 0 ); // SCI_CALLTIPSETFORE 2206
						scope _result = new IupString( ScintillaAction.textWrap( list ) );
						IupScintillaSendMessage( ih, 2200, pos, cast(int) _result.toCString );
						
						//if( calltipContainer !is null )	calltipContainer.push( Integer.toString( ScintillaAction.getLinefromPos( ih, pos ) ) ~ ";" ~ list );
						calltipContainer.push( Integer.toString( ScintillaAction.getLinefromPos( ih, pos ) ) ~ ";" ~ list );
					}
				
					if( cast(int) IupScintillaSendMessage( ih, 2202, 0, 0 ) == 1 )
					{
						int highlightStart, highlightEnd;
						callTipSetHLT( list, commaCount, highlightStart, highlightEnd );

						if( highlightEnd > -1 )
						{
							IupScintillaSendMessage( ih, 2204, highlightStart, highlightEnd ); // SCI_CALLTIPSETHLT 2204
							IupScintillaSendMessage( ih, 2207, tools.convertIupColor( GLOBAL.editColor.callTipHLT.toDString ), 0 ); // SCI_CALLTIPSETFOREHLT 2207
							return true;
						}
						else
						{
							// Clean the Hight-light
							IupScintillaSendMessage( ih, 2204, 0, -1 ); // SCI_CALLTIPSETHLT 2204
							if( cast(int) IupScintillaSendMessage( ih, 2202, 0, 0 ) == 1 ) IupScintillaSendMessage( ih, 2201, 1, 0 ); //  SCI_CALLTIPCANCEL 2201 , SCI_CALLTIPACTIVE 2202
						}
					}
				}
			}
			
			return false;
		}
		
		static bool updateCallTipByDirectKey( Ihandle* ih, int pos )
		{
			int		commaCount, parenCount, firstOpenParenPosFromDocument;
			char[]	procedureNameFromDocument = AutoComplete.parseProcedureForCalltip( ih, pos, commaCount, parenCount, firstOpenParenPosFromDocument ); // from document
			if( cast(int) IupScintillaSendMessage( ih, 2202, 0, 0 ) == 1 )
			{
				char[] list = calltipContainer.top();
				if( list.length )
				{
					int semicolonPos = Util.index( list, ";" );
					if( semicolonPos < list.length )
					{
						list = list[semicolonPos+1..$].dup;
				
						int highlightStart, highlightEnd;
						callTipSetHLT( list, commaCount, highlightStart, highlightEnd );

						if( highlightEnd > -1 )
						{
							IupScintillaSendMessage( ih, 2204, highlightStart, highlightEnd ); // SCI_CALLTIPSETHLT 2204
							IupScintillaSendMessage( ih, 2207, tools.convertIupColor( GLOBAL.editColor.callTipHLT.toDString ), 0 ); // SCI_CALLTIPSETFOREHLT 2207
							return true;
						}
						else
						{
							IupScintillaSendMessage( ih, 2204, 0, -1 ); // SCI_CALLTIPSETHLT 2204
						}
					}
				}
			}
			
			return false;
		}
	}

	extern(C) private int CompleteTimer_ACTION( Ihandle* _ih )
	{
		if( AutoComplete.showListThread !is null )
		{
			if( !AutoComplete.showListThread.isRunning )
			{
				if( AutoComplete.showListThread.getResult.length )
				{
					auto sci = ScintillaAction.getActiveIupScintilla();
					if( sci != null )
					{
						if( fromStringz( IupGetAttribute( sci, "AUTOCACTIVE" ) ) == "NO" )
						{
							int		_pos = ScintillaAction.getCurrentPos( sci );
							int		dummyHeadPos;
							char[]	_alreadyInput;
							char[]	lastChar = fromStringz( IupGetAttributeId( sci, "CHAR", _pos - 1 ) );
							
							if( _pos > 1 )
							{
								if( lastChar == ">" )
								{
									if( fromStringz( IupGetAttributeId( sci, "CHAR", _pos - 2 ) ) == "-" ) _alreadyInput = AutoComplete.getWholeWordReverse( sci, _pos - 2, dummyHeadPos ).reverse ~ "->";
								}
							}

							if( !_alreadyInput.length ) _alreadyInput = AutoComplete.getWholeWordReverse( sci, _pos, dummyHeadPos ).reverse;
							char[][] splitWord = AutoComplete.getDivideWord( _alreadyInput );
							_alreadyInput = splitWord[$-1];
							
							if( cast(int) IupScintillaSendMessage( sci, 2202, 0, 0 ) == 1 ) IupScintillaSendMessage( sci, 2201, 0, 0 ); //  SCI_CALLTIPCANCEL 2201 , SCI_CALLTIPACTIVE 2202
							
							scope _result = new IupString( AutoComplete.showListThread.getResult );
							if( _alreadyInput.length )
								IupScintillaSendMessage( sci, 2100, _alreadyInput.length, cast(int) _result.toCString );
							else
								IupScintillaSendMessage( sci, 2100, 0, cast(int) _result.toCString );
								

							auto cSci = ScintillaAction.getActiveCScintilla();
						}
					}
				}
				
				delete AutoComplete.showListThread;
				AutoComplete.showListThread = null;
			}
		}
		
		
		if( AutoComplete.showCallTipThread !is null )
		{
			if( !AutoComplete.showCallTipThread.isRunning )
			{
				if( AutoComplete.showCallTipThread.getResult.length )
				{
					auto sci = ScintillaAction.getActiveIupScintilla();
					if( sci != null )
					{
						if( fromStringz( IupGetAttribute( sci, "AUTOCACTIVE" ) ) == "NO" )
						{
							int		_pos = ScintillaAction.getCurrentPos( sci );

							if( cast(int) IupScintillaSendMessage( sci, 2202, 0, 0 ) == 1 ) IupScintillaSendMessage( sci, 2201, 0, 0 ); //  SCI_CALLTIPCANCEL 2201 , SCI_CALLTIPACTIVE 2202

							IupScintillaSendMessage( sci, 2205, tools.convertIupColor( GLOBAL.editColor.callTipBack.toDString ), 0 ); // SCI_CALLTIPSETBACK 2205
							IupScintillaSendMessage( sci, 2206, tools.convertIupColor( GLOBAL.editColor.callTipFore.toDString ), 0 ); // SCI_CALLTIPSETFORE 2206
							scope _result = new IupString( ScintillaAction.textWrap( AutoComplete.showCallTipThread.getResult ) );
							IupScintillaSendMessage( sci, 2200, _pos, cast(int) _result.toCString );
							
							AutoComplete.calltipContainer.push( Integer.toString( ScintillaAction.getLinefromPos( sci, _pos ) ) ~ ";" ~ AutoComplete.showCallTipThread.getResult );
							
							int highlightStart, highlightEnd;
							AutoComplete.callTipSetHLT( AutoComplete.showCallTipThread.getResult, AutoComplete.showCallTipThread.ext, highlightStart, highlightEnd );
							if( highlightEnd > -1 ) 
							{
								IupScintillaSendMessage( sci, 2204, highlightStart, highlightEnd ); // SCI_CALLTIPSETHLT 2204
								IupScintillaSendMessage( sci, 2207, tools.convertIupColor( GLOBAL.editColor.callTipHLT.toDString ), 0 ); // SCI_CALLTIPSETFOREHLT 2207
							}
							
							AutoComplete.noneListProcedureName = "";
							
							auto cSci = ScintillaAction.getActiveCScintilla();
						}
					}
				}
				else
				{
					AutoComplete.noneListProcedureName = Integer.toString( AutoComplete.showCallTipThread.pos ) ~ ";" ~ AutoComplete.showCallTipThread.extString;
				}

				delete AutoComplete.showCallTipThread;
				AutoComplete.showCallTipThread = null;
			}
		}		
		
		if( AutoComplete.showListThread is null && AutoComplete.showCallTipThread is null )	IupSetAttribute( _ih, "RUN", "NO" );		
		
		return IUP_IGNORE;
	}	
}