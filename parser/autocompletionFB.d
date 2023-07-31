module parser.autocompletionFB;

version(FBIDE)
{
	import iup.iup;
	import iup.iup_scintilla;
	import global, actionManager, menu, tools;
	import std.stdio, std.string, std.conv, Algorithm = std.algorithm;

	struct AutoComplete
	{
	private:
		import tools;
		import parser.ast;
		import scintilla, project;
		import std.string, std.file, std.process, std.utf, std.format, Conv = std.conv, Array = std.array, Uni = std.uni, Path = std.path, Algorithm = std.algorithm, std.algorithm.mutation : SwapStrategy;
		import core.thread, core.sys.windows.winnt, core.sys.windows.windef;


		version(Windows)
		{
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
		
		struct PrevAnalysisUnit
		{
			string[]		word;
			CASTnode		node;
			int				linenum;
			string[string]	completeList, completeCallTip;
		}
		
		
		static shared CASTnode[string]		includesMarkContainer;
		static shared bool[string]			noIncludeNodeContainer;
		
		static CASTnode[]					extendedClasses;
		static Stack!(string)				calltipContainer;
		public static string				noneListProcedureName;
		static string[]						listContainer;

		static string						showTypeContent;
		static __gshared PrevAnalysisUnit	prevAnalysis, prevComplete;


		class CGetIncludes : Thread
		{
		private:
			CASTnode			AST_Head;
			CompilerSettingUint	compilerSettings; // For TLS
		
		public:
			this( CASTnode _AST_Head )
			{
				AST_Head = _AST_Head;
				compilerSettings = GLOBAL.compilerSettings; // copy MainThread GLOBAL.compilerSettings Data
				
				super( &run );
			}

			void run()
			{
				GLOBAL.compilerSettings = compilerSettings; // To TLS GLOBAL.compilerSettings
				AutoComplete.getIncludes( AST_Head, AST_Head.name, 0 );
			}
		}

		class CShowListThread : Thread
		{
		private:
			int					ext;
			string				text, extString;
			string				result;
			
			CASTnode			AST_Head;
			int					pos, lineNum;
			bool				bDot, bCallTip;
			string[]			splitWord;
			CompilerSettingUint compilerSettings;
			
		public:
			this( CASTnode _AST_Head, int _pos, int _lineNum, bool _bDot, bool _bCallTip, string[] _splitWord, string _text, int _ext = -1, string _extString = ""  )
			{
				AST_Head			= _AST_Head;
				pos					= _pos;
				lineNum				= _lineNum;
				bDot				= _bDot;
				bCallTip			= _bCallTip;
				splitWord			= _splitWord;
				text				= _text;
				ext					= _ext;
				_extString			= _extString;
				compilerSettings	= GLOBAL.compilerSettings; // copy MainThread GLOBAL.compilerSettings Data
			
				super( &run );
			}

			// If using IUP command in Thread, join() occur infinite loop, so......
			void run()
			{
				GLOBAL.compilerSettings = compilerSettings; // To TLS GLOBAL.compilerSettings

				if( AST_Head is null )
				{
					if( GLOBAL.compilerSettings.enableKeywordComplete == "ON" ) result = getKeywordContainerList( splitWord[0] );
					return;
				}
			
				if( GLOBAL.autoCompletionTriggerWordCount < 1 ) 
				{
					if( GLOBAL.compilerSettings.enableKeywordComplete == "ON" ) result = getKeywordContainerList( splitWord[0] );
					return;
				}
				
				auto oriAST = AST_Head;
				
				version(VERSION_NONE){} else checkVersionSpec( AST_Head, lineNum );
				
				
				// For Quick show the dialog...
				/*
				writefln( Array.join( prevComplete.word, "." ) );
				writefln( Array.join( splitWord, "." ) );
				*/
				bool bCompleteJump;
				if( lineNum == prevComplete.linenum )
				{
					//if( prevComplete.word.length >= splitWord.length )
					if( prevComplete.word.length && splitWord.length )
					{
						//string prevWords = fullPathByOS( Array.join( prevComplete.word, "." ) );
						string nowWords = fullPathByOS( Array.join( splitWord, "." ) );
					
						//if( indexOf( prevWords, nowWords ) == 0 )
						if( fullPathByOS( prevComplete.word[0] ) == fullPathByOS( splitWord[0] ) )
						{
							if( bDot )
							{
								if( nowWords in prevComplete.completeList )
								{
									result = prevComplete.completeList[nowWords];
									bCompleteJump = true;
								}
							}
							else if( bCallTip )
							{
								if( nowWords in prevComplete.completeCallTip )
								{
									result = prevComplete.completeCallTip[nowWords];
									bCompleteJump = true;
								}
							}
							else
							{
								if( splitWord.length > 1 )
								{
									nowWords = fullPathByOS( Array.join( splitWord[0..$-1], "." ) );
									if( nowWords in prevComplete.completeList )
									{
										result = prevComplete.completeList[nowWords];
										bCompleteJump = true;
									}
								}
							}
						}
					}
				}
				else
				{
					if( prevComplete.completeList.length ) prevComplete.completeList.clear;
					if( prevComplete.completeCallTip.length ) prevComplete.completeCallTip.clear;
					cleanInsertBIContainer();
				}
				

				if( !bCompleteJump )
				{
					result = analysisSplitWorld_ReturnCompleteList( AST_Head, splitWord, lineNum, bDot, bCallTip, true );
					
					string[] usingNames = checkUsingNamespace( oriAST, lineNum );
					if( usingNames.length )
					{
						string[] noUsingListContainer;
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
							foreach( s; usingNames )
							{
								string[] splitWithDot = Array.split( s, "." );
								string[] namespaceSplitWord = splitWithDot ~ splitWord;
								string _result = analysisSplitWorld_ReturnCompleteList( oriAST, namespaceSplitWord, lineNum, bDot, bCallTip, true );
								
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
						//Algorithm.sort( listContainer );
						Algorithm.sort!("toUpper(a) < toUpper(b)", SwapStrategy.stable)( listContainer );
						
						string	_type, _list;
						int		maxLeft, maxRight;

						for( int i = 0; i < listContainer.length; ++ i )
						{
							if( listContainer[i].length )
							{
								auto dollarPos = lastIndexOf( listContainer[i], "#" );
								if( dollarPos > -1 )
								{
									_type = listContainer[i][dollarPos+1..$];
									if( _type.length > maxRight ) maxRight = cast(int) _type.length;
									_list = listContainer[i][0..dollarPos];
									if( _list.length > maxLeft ) maxLeft = cast(int) _list.length;
								}
								else
								{
									if( listContainer[i].length > maxLeft ) maxLeft = cast(int) listContainer[i].length;
								}
							}
						}

						for( int i = 0; i < listContainer.length; ++ i )
						{
							if( i > 0 )
							{
								if( Uni.toLower( listContainer[i] ) == Uni.toLower( listContainer[i-1] ) ) continue;
							}					

							if( listContainer[i].length )
							{
								string _string;
								
								auto dollarPos = lastIndexOf( listContainer[i], "#" );
								if( dollarPos > 0 )
								{
									_type = listContainer[i][dollarPos+1..$];
									_list = listContainer[i][0..dollarPos];
									_string = stripRight( format( "%-" ~ std.conv.to!(string)(maxLeft) ~ "s :: %-" ~ std.conv.to!(string)(maxRight) ~ "s", _list, _type ) );
								}
								else
								{
									_string = listContainer[i];
								}

								result ~= ( _string ~ "^" );
							}
						}
					}
				
					if( result.length )
						if( result[$-1] == '^' ) result = result[0..$-1];
				}

				
				// For Quick show the dialog...
				if( bDot )
				{
					prevComplete.word = splitWord;
					prevComplete.linenum = lineNum;
					prevComplete.completeList[fullPathByOS( Array.join( splitWord, "." ) )] = result;
				}
				else if( bCallTip )
				{
					prevComplete.word = splitWord;
					prevComplete.linenum = lineNum;
					prevComplete.completeCallTip[fullPathByOS( Array.join( splitWord, "." ) )] = result;
				}
			}
			
			string getResult()
			{
				return result;
			}			
		}
		
		static CGetIncludes				preLoadContainerThread;
		public static CShowListThread	showListThread;
		public static CShowListThread	showCallTipThread;
		static Ihandle* timer = null;
		
		static bool checkExtendedClassesExist( CASTnode _node )
		{
			foreach( CASTnode a; extendedClasses )
			{
				if( a == _node ) return true;
			}
			
			return false;
		}
		
		
		static void getTypeAndParameter( CASTnode node, ref string _type, ref string _param )
		{
			if( node !is null )
			{
				auto openParenPos = indexOf( node.type, "(" );
				if( openParenPos > -1 )
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
		
		static string getListImage( CASTnode node, bool bFullShow = false )
		{
			if( !bFullShow )
				if( GLOBAL.compilerSettings.toggleShowAllMember == "OFF" )
					if( node.protection == "private" ) return null;
				
			if( Algorithm.count( node.name, "." ) > 0 ) return null;
			
			int protAdd;
			switch( node.protection )
			{
				case "public":		protAdd = 2; break;
				case "private":		protAdd = 0; break;
				case "protected":	protAdd = 1; break;
				default:			protAdd = 2;
			}

			string name = node.name;
			if( node.name.length )
			{
				if( node.name[$-1] == ')' )
				{
					auto posOpenParen = indexOf( node.name, "(" );
					if( posOpenParen > -1 ) name = node.name[0..posOpenParen];
				}
			}
			else
				return null;

			bool bShowType = true;//GLOBAL.toggleShowListType == "ON" ? true : false;
			string type = node.type;

			if( bShowType )
			{
				if( node.type.length )
				{
					auto posOpenParen = indexOf( node.type, "(" );
					if( posOpenParen > -1 ) type = node.type[0..posOpenParen]; else type = node.type;
				}
			}
			
			switch( node.kind )
			{
				case B_DEFINE | B_VARIABLE:	return name ~ "?33";
				case B_DEFINE | B_FUNCTION:	return name ~ "?34";
				
				case B_SUB:					return bShowType ? name ~ "#void" ~ "?" ~ std.conv.to!(string)( 25 + protAdd ) : name ~ "?" ~ std.conv.to!(string)( 25 + protAdd );
				case B_FUNCTION:			return bShowType ? name ~ "#" ~ type ~ "?" ~ std.conv.to!(string)( 28 + protAdd ) : name ~ "?" ~ std.conv.to!(string)( 28 + protAdd );
				case B_VARIABLE:
					if( node.name.length )
					{
						if( !type.length ) type = node.base; // VAR
						if( node.name[$-1] == ')' ) return bShowType ? name ~ "#" ~ type ~ "?" ~ std.conv.to!(string)( 1 + protAdd ) : name ~ "?" ~ std.conv.to!(string)( 1 + protAdd ); else return bShowType ? name ~ "#" ~ type ~ "?" ~ std.conv.to!(string)( 4 + protAdd ) : name ~ "?" ~ std.conv.to!(string)( 4 + protAdd );
					}
					break;

				case B_PROPERTY:
					if( node.type.length )
					{
						if( node.type[0] == '(' ) return name ~ "?31"; else	return name ~ "?32";
					}
					break;
					
				case B_CLASS:					return name ~ "?" ~ std.conv.to!(string)( 7 + protAdd );
				case B_TYPE: 					return name ~ "?" ~ std.conv.to!(string)( 10 + protAdd );
				case B_ENUM: 					return name ~ "?" ~ std.conv.to!(string)( 12 + protAdd );
				case B_PARAM:					return bShowType ? name ~ "#" ~ type ~ "?18" : name ~ "?18";
				case B_ENUMMEMBER:				return name ~ "?19";
				case B_ALIAS:					return bShowType ? name ~ "#" ~ type ~ "?20" : name ~ "?20";//name ~ "?20";
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

		static CASTnode[] getAnonymousEnumMemberFromWord( CASTnode originalNode, string word )
		{
			if( originalNode is null ) return null;
			
			CASTnode[] results;
			
			if( originalNode.kind & B_ENUM )
			{
				if( !originalNode.name.length )
				{
					foreach( CASTnode _node; anonymousEnumMembers( originalNode ) )
					{
						if( indexOf( Uni.toLower( _node.name ), word ) == 0 ) results ~= _node;
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
				if( Uni.toLower( originalNode.base ) == "object" ) return null;
				
				if( originalNode.kind & ( B_TYPE | B_CLASS | B_UNION ) )
				{
					CASTnode	ret;
					
					// If the name of extends class with dot, it should be with namespace....
					if( Algorithm.count( originalNode.base, "." ) )
					{
						ret = getExtendClass( originalNode, Uni.toLower( originalNode.base ) );
						if( ret is null )
						{
							ret = getExtendClass( originalNode, Uni.toLower( getNameSpaceWithDotTail( originalNode ) ~ originalNode.base ) );
							if( ret is null )
							{	
								string[] usingNames = checkUsingNamespace( originalNode, originalNode.lineNumber );
								if( usingNames.length )
								{
									foreach( s; usingNames )
									{
										ret = getExtendClass( originalNode, Uni.toLower( s ~ "." ~ originalNode.base ) );
										if( ret !is null ) return ret;
									}
								}	
							}
						}
					}
					else
					{
						string[]	usingNames = checkUsingNamespace( originalNode, originalNode.lineNumber );
						string		NameSpaceString = getNameSpaceWithDotTail( originalNode );
						
						if( usingNames.length )
						{
							foreach( s; usingNames )
							{
								ret = getExtendClass( originalNode, Uni.toLower( s ~ "." ~ originalNode.base ) );
								if( ret !is null ) return ret;
							}
						}
						
						
						if( NameSpaceString.length )
						{
							ret = getExtendClass( originalNode, Uni.toLower( NameSpaceString ~ originalNode.base ) );
						}
						
						if( ret is null ) ret = getExtendClass( originalNode, Uni.toLower( originalNode.base ) );
					}

					return ret;
				}
			}

			return null;
		}


		static CASTnode[] getBaseNodeMembers( CASTnode originalNode, int level = 0 )
		{
			if( originalNode is null ) return null;
		
			if( GLOBAL.compilerSettings.includeLevel > -1 )
			{
				if( level > GLOBAL.compilerSettings.includeLevel - 1 ) return null;

				if( level > 2 ) return null; // MAX 3 STEP (0,1,2)
			}
			
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


		static CASTnode[] getMatchASTfromWholeWord( CASTnode node, string word, int line, int B_KIND )
		{
			if( node is null ) return null;
			
			CASTnode[] results;
			
			foreach( child; getMembers( node ) )
			{
				if( child.kind & B_KIND )
				{
					if( Uni.toLower( ParserAction.removeArrayAndPointer( child.name ) ) == Uni.toLower( word ) )
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

		static CASTnode[] getMatchASTfromWord( CASTnode node, string word, int line )
		{
			if( node is null ) return null;
			
			CASTnode[] results;
			
			foreach( child; getMembers( node ) )
			{
				if( child.name.length )
				{
					if( indexOf( Uni.toLower( child.name ), Uni.toLower( word ) ) == 0 )
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


		static CASTnode[] check( string name, string originalFullPath, int _LEVEL )
		{
			CASTnode[] results;
			
			string includeFullPath = checkIncludeExist( name, originalFullPath );

			if( includeFullPath.length )
			{
				if( fullPathByOS(includeFullPath) in includesMarkContainer ) return null;

				CASTnode includeAST;
				if( fullPathByOS(includeFullPath) in GLOBAL.parserManager )
				{
					auto _ast = cast(CASTnode) GLOBAL.parserManager[fullPathByOS(includeFullPath)];
					includesMarkContainer[fullPathByOS(includeFullPath)] = cast(shared CASTnode) _ast;
					results ~= _ast;
					results ~= getIncludes( _ast, includeFullPath, _LEVEL );
				}
				else
				{
					CASTnode _createFileNode = ParserAction.createParser( includeFullPath, true );
					if( _createFileNode !is null )
					{
						includesMarkContainer[fullPathByOS(includeFullPath)] = cast(shared CASTnode) _createFileNode;
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
		
		static CASTnode[] getInsertCodeBI( CASTnode originalNode, string originalFullPath, string word, bool bWholeWord, int ln = 2147483647 )
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
						foreach( s; GLOBAL.projectManager[GLOBAL.activeProjectPath].sources ~ GLOBAL.projectManager[GLOBAL.activeProjectPath].includes )
						{
							if( s != originalFullPath )
							{
								CASTnode _createFileNode = ParserAction.loadParser( s, true );
								if( _createFileNode !is null )
								{
									foreach( CASTnode _node; _createFileNode.getChildren )
									{
										if( _node.kind & B_INCLUDE ) 
										{
											string name = checkIncludeExist( _node.name, s );
											if( name == originalFullPath )
											{
												noIncludeNodeContainer[originalFullPath] = true;
												/*
												if( bWholeWord )
													return searchMatchMemberNodes( _createFileNode, word, B_ALL, true ) ~ getMatchIncludesFromWholeWord( _createFileNode, s, word, _node.lineNumber );
												else
													return searchMatchMemberNodes( _createFileNode, word, B_ALL, false ) ~ getMatchIncludesFromWord( _createFileNode, s, word, _node.lineNumber );
												*/
												if( bWholeWord )
													return searchMatchMemberNodes( _createFileNode, word, B_ALL, true ) ~ getMatchIncludesFromWholeWord( _createFileNode, s, word );
												else
													return searchMatchMemberNodes( _createFileNode, word, B_ALL, false ) ~ getMatchIncludesFromWord( _createFileNode, s, word );
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
		
		static CASTnode getMatchNodeInFile( CASTnode oriNode, string[] nameSpaces, string word, string fileName, int B_KIND, bool bOnlyDeclare = false, bool bOnlyProcedureBody = true )
		{
			CASTnode _createFileNode = ParserAction.loadParser( fileName, true );
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
						if( Uni.toLower( word ) == Uni.toLower( _node.name ) )
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
					if( Uni.toLower( oriNode.type ) == Uni.toLower( a.type ) ) return a;
				
				if( matchASTs.length ) return matchASTs[0];
			}
			
			return null;
		}
		
		static CASTnode getMatchNodeInProject( CASTnode oriNode, string[] nameSpaces, string word, string prjName, int B_KIND, string[] exceptFileNames, bool bOnlyDeclare = false, bool bOnlyProcedureBody = true )
		{
			if( prjName in GLOBAL.projectManager )
			{
				foreach( s; GLOBAL.projectManager[prjName].sources ~ GLOBAL.projectManager[prjName].includes )
				{
					foreach( e; exceptFileNames )
						if( s == e ) continue;
					
					
					CASTnode _createFileNode = getMatchNodeInFile( oriNode, nameSpaces, word, s, B_KIND, bOnlyDeclare, bOnlyProcedureBody );
					if( _createFileNode !is null ) return _createFileNode;
				}
			}
			
			return null;
		}

		static CASTnode[] getMatchIncludesFromWholeWord( CASTnode originalNode, string originalFullPath, string word, int ln = 2147483647 )
		{
			if( originalNode is null ) return null;

			CASTnode[] results = getInsertCodeBI( originalNode, originalFullPath, word, true, ln );
			if( results.length ) return results;

			cleanIncludeContainer();
			getIncludes( originalNode, originalFullPath, 0, ln );

			foreach( includeAST; cast(CASTnode[string]) includesMarkContainer )
			{
				if( includeAST !is null )
				{
					foreach( child; getMembers( includeAST ) )
					{
						if( child.name.length )
						{
							if( Uni.toLower( ParserAction.removeArrayAndPointer( child.name ) ) == Uni.toLower( word ) ) results ~= child;
						}
						else
						{
							CASTnode[] enumResult = getAnonymousEnumMemberFromWord( child, Uni.toLower( word ) );
							if( enumResult.length ) results ~= enumResult;
						}
					}
				}
			}

			return results;
		}	

		static CASTnode[] getMatchIncludesFromWord( CASTnode originalNode, string originalFullPath, string word, int ln = 2147483647 )
		{
			if( originalNode is null ) return null;
			
			CASTnode[] results = getInsertCodeBI( originalNode, originalFullPath, word, false, ln );
			if( results.length ) return results;
			
			cleanIncludeContainer();
			getIncludes( originalNode, originalFullPath, 0, ln );
			
			foreach( includeAST; cast(CASTnode[string]) includesMarkContainer )
			{
				if( includeAST !is null )
				{
					foreach( child; getMembers( includeAST ) )
					{
						if( child.kind & B_NAMESPACE )
						{
							if( child.name.length )
							{
								if( indexOf( Uni.toLower( child.name ), Uni.toLower( word ) ) == 0 )
								{
									results ~= child;
								}
							}
						}
						else
						{
							if( child.name.length )
							{
								if( indexOf( Uni.toLower( child.name ), Uni.toLower( word ) ) == 0 )
								{
									results ~= child;
								}
							}
							else
							{
								CASTnode[] enumResult = getAnonymousEnumMemberFromWord( child, Uni.toLower( word ) );
								if( enumResult.length ) results ~= enumResult;
							}
						}
					}
				}
			}
			

			return results;
		}

		static bool isDefaultType( string _type )
		{
			_type = Uni.toLower( _type );
			
			if( _type == "byte" || _type == "ubyte" || _type == "short" || _type == "ushort" || _type == "integer" || _type == "uinteger" || _type == "longint" || _type == "ulongint" ||
				_type == "single" || _type == "double" || _type == "string" || _type == "zstring" || _type == "wstring" || _type == "boolean" ) return true;

			return false;
		}
		

		static CASTnode searchMatchMemberNode( CASTnode originalNode, string word, int B_KIND = B_ALL, bool bSkipExtend = false )
		{
			if( originalNode is null ) return null;
			
			foreach( CASTnode _node; getMembers( originalNode, bSkipExtend ) )
			{
				if( _node.kind & B_KIND )
				{
					string name = Uni.toLower( ParserAction.removeArrayAndPointer( _node.name ) );
					
					if( name.length )
					{
						if( name == Uni.toLower( word ) ) return _node;
					}
					else
					{
						foreach( CASTnode _enumMember; anonymousEnumMembers( _node ) )
						{
							if( Uni.toLower( _enumMember.name ) == Uni.toLower( word ) ) return _enumMember;
						}
					}
				}
			}

			return null;
		}

		static CASTnode[] searchMatchMemberNodes( CASTnode originalNode, string word, int B_KIND = B_ALL, bool bWholeWord = true, bool bSkipExtend = false )
		{
			if( originalNode is null ) return null;
			
			CASTnode[] results;
			
			word = Uni.toLower( word );
			
			foreach( CASTnode _node; getMembers( originalNode, bSkipExtend ) )
			{
				if( _node.kind & B_KIND )
				{
					string name = Uni.toLower( ParserAction.removeArrayAndPointer( _node.name ) );

					if( bWholeWord )
					{
						if( name == word ) results ~= _node;
					}
					else
					{
						//if( Util.index( name, lowerCase( word ) ) == 0 ) results ~= _node;
						if( name.length )
						{
							if( indexOf( name, word ) == 0 ) results ~= _node;
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
		

		static CASTnode searchMatchNode( CASTnode originalNode, string word, int B_KIND = B_ALL, bool bSkipExtend = true )
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
					//auto cSci = actionManager.ScintillaAction.getActiveCScintilla();
					string rootFilePath = originalNode.name;
					//CASTnode[] resultIncludeNodes = getMatchIncludesFromWord( GLOBAL.parserManager[fullPathByOS(cSci.getFullPath)], cSci.getFullPath, word );					
					if( fullPathByOS(rootFilePath) in GLOBAL.parserManager ) 
					{
						auto _ast = cast(CASTnode) GLOBAL.parserManager[fullPathByOS(rootFilePath)];
						CASTnode[] resultIncludeNodes = getMatchIncludesFromWholeWord( _ast, rootFilePath, word, B_KIND );
						if( resultIncludeNodes.length )	resultNode = resultIncludeNodes[0];
					}
				}
			}

			return resultNode;
		}
		
		
		static CASTnode[] searchMatchNodes( CASTnode originalNode, string word, int B_KIND = B_ALL, bool bSkipExtend = false )
		{
			if( originalNode is null ) return null;
			
			CASTnode[] resultNodes = searchMatchMemberNodes( originalNode, word, B_KIND, true, bSkipExtend );

			if( originalNode.getFather() !is null )
			{
				resultNodes ~= searchMatchNodes( originalNode.getFather(), word, B_KIND, bSkipExtend );
			}
			else
			{
				//auto cSci = actionManager.ScintillaAction.getActiveCScintilla();
				string rootFilePath = originalNode.name;

				//CASTnode[] resultIncludeNodes = getMatchIncludesFromWord( GLOBAL.parserManager[fullPathByOS(cSci.getFullPath)], cSci.getFullPath, word );
				if( fullPathByOS(rootFilePath) in GLOBAL.parserManager ) 
				{
					auto _ast = cast(CASTnode) GLOBAL.parserManager[fullPathByOS(rootFilePath)];
					CASTnode[] resultIncludeNodes = getMatchIncludesFromWholeWord( _ast, rootFilePath, word );
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
						string symbol = Uni.toUpper( childrenNodes[i].name );
						string noSignSymbolName = childrenNodes[i].type.length ? symbol[1..$] : symbol;
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
								if( AutoComplete.VersionCondition.length )
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
				string[]	splitWord;
				string		_type;
				
				auto oriAST = originalNode;
				
				if( originalNode.type.length ) _type = originalNode.type; else _type = stripLeft( originalNode.base, "*" ); // remove leftside *
				
				splitWord = ParserAction.getDivideWordWithoutSymbol( _type );
				/*
				foreach( char[] s; splitWord )
					if( s == originalNode.name ) return null;
				*/
				version(VERSION_NONE){} else checkVersionSpec( originalNode, originalNode.lineNumber );
				string[] usingNames = checkUsingNamespace( oriAST, lineNum );
				if( usingNames.length )
				{
					foreach( s; usingNames )
					{
						originalNode = oriAST;
						string[] splitWithDot = Array.split( s, "." );
						string[] namespaceSplitWord = splitWithDot ~ splitWord;
						analysisSplitWorld_ReturnCompleteList( originalNode, namespaceSplitWord, lineNum, true, false, false );
						if( originalNode !is oriAST )
							if( originalNode !is null ) return originalNode;
					}
				}
				
				// No Using or No results found...
				originalNode = oriAST;
				analysisSplitWorld_ReturnCompleteList( originalNode, splitWord, lineNum, true, false, false );
				
				if( originalNode is oriAST ) return oriAST; // Prevent infinite loop
				
				if( originalNode !is null ) resultNode = originalNode;// else resultNode = oriAST;
			}			
			
			return resultNode;
		}

		static bool stepByStep( ref CASTnode AST_Head, string word, int B_KIND, int lineNum )
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
		
		static string callTipList( CASTnode[] groupAST, string word = null )
		{
			string[] results;
			
			for( int i = 0; i < groupAST.length; ++ i )
			{
				if( i > 0 )
				{
					if( groupAST[i].name == groupAST[i-1].name && groupAST[i].type == groupAST[i-1].type ) continue;
				}
				
				if( groupAST[i].kind & ( B_FUNCTION | B_SUB | B_PROPERTY ) )
				{
					if( ( !word.length ) || Uni.toLower( groupAST[i].name ) == Uni.toLower( word ) )
					{
						string _type, _paramString	= "()";
						getTypeAndParameter( groupAST[i], _type, _paramString );

						if( _type.length )
							results ~= ( _type ~ " " ~ groupAST[i].name ~ _paramString ~ "\n" );
						else
							results ~= ( "void " ~ groupAST[i].name ~ _paramString ~ "\n" );
					}
				}
				else if( groupAST[i].kind & ( B_TYPE | B_CLASS| B_UNION ) )
				{
					if( ( !word.length ) || Uni.toLower( groupAST[i].name ) == Uni.toLower( word ) )
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

			//Algorithm.sort( results );
			Algorithm.sort!("toUpper(a) < toUpper(b)", SwapStrategy.stable)( results );
			
			string result;
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
		
		static void callTipSetHLT( string list, int itemNO, ref int highlightStart, ref int highlightEnd )
		{
			int listHead;
			foreach( lineText; splitLines( list ) )
			{
				auto openParenPos = indexOf( lineText, "(" );
				auto closeParenPos = lastIndexOf( lineText, ")" );
				if( closeParenPos > openParenPos + 1 && openParenPos > 0 )
				{
					openParenPos += listHead;
					closeParenPos += listHead;
					
					int parenCount;
					int	paramCount;
					
					for( int i = cast(int) openParenPos + 1; i < closeParenPos; ++i )
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
							highlightEnd = cast(int) closeParenPos;
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
		
		static string parseProcedureForCalltip( Ihandle* ih, int lineHeadPos, string lineHeadText, ref int commaCount, ref int parenCount, ref int firstOpenParenPos )
		{
			if( ih == null ) return null;
			
			bool	bGetName;
			string	procedureName;
			
			if( lineHeadPos == -1 )	lineHeadPos = cast(int) IupScintillaSendMessage( ih, 2167, ScintillaAction.getCurrentLine( ih ) - 1, 0 );
			
			for( int i = cast(int) lineHeadText.length - 1; i >= 0; --i ) //SCI_POSITIONFROMLINE 2167
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
		
		static string parseProcedureForCalltip( Ihandle* ih, int pos, ref int commaCount, ref int parenCount, ref int firstOpenParenPos )
		{
			if( ih == null ) return null;
			
			//int pos = ScintillaAction.getCurrentPos( ih );
			
			bool	bGetName;
			string	procedureName;
			
			for( int i = pos; i >= cast(int) IupScintillaSendMessage( ih, 2167, ScintillaAction.getCurrentLine( ih ) - 1, 0 ); --i ) //SCI_POSITIONFROMLINE 2167
			{
				string s = fSTRz( IupGetAttributeId( ih, "CHAR", i ) );
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

		static void keyWordlist( string word )
		{
			foreach( _s; GLOBAL.KEYWORDS )
			{
				foreach( s; Array.split( _s, " " ) )
				{
					if( s.length )
					{
						if( indexOf( Uni.toLower( s ), Uni.toLower( word ) ) == 0 )
						{
							s = tools.convertKeyWordCase( GLOBAL.keywordCase, s );
							listContainer ~= ( s ~ "?0" );
						}
					}
				}
			}
		}
		
		
		static string[] getDivideWord( string word )
		{
			string[]	splitWord;
			string		tempWord;

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


		static string[] getNeedDataForThread( Ihandle* iupSci, string text, int pos, ref int lineNum, ref bool bDot, ref bool bCallTip, ref CASTnode AST_Head )
		{
			int		dummyHeadPos;
			string 	word, result;

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
			
			word = Uni.toLower( Algorithm.reverse( word.dup ) );

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

					lineNum = cast(int) IupScintillaSendMessage( iupSci, 2166, pos, 0 ) + 1; //SCI_LINEFROMPOSITION = 2166,
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
					if( _friends.lineNumber < lineNum ) VersionCondition[Uni.toUpper(_friends.name)] = 1;
			}
			
			if( AST_Head.getFather !is null )
				checkVersionSpec( AST_Head.getFather, lineNum );
			else
			{
				if( GLOBAL.compilerSettings.includeLevel != 0 )
				{
					int oriIncludeLevel = GLOBAL.compilerSettings.includeLevel;
					
					// Heavy slow down the spped, only check only 2-steps
					// if( GLOBAL.includeLevel > 2 ) GLOBAL.includeLevel = 2; // Comment this line to get full-check
					getIncludes( AST_Head, AST_Head.name, 0 );
					foreach( _includeNode; cast(CASTnode[string]) includesMarkContainer )
					{
						foreach( CASTnode _friends; getMembers( _includeNode, true ) )
						{
							if( _friends.kind == ( B_DEFINE | B_VERSION ) ) 
							{
								if( _friends.getFather.kind == B_VERSION )
									if( _friends.getFather.type.length )
										if( Uni.toUpper( _friends.name ) == Uni.toUpper( _friends.getFather.name[1..$] ) ) continue; // Skip the C-style include once
								
								VersionCondition[Uni.toUpper(_friends.name)] = 1; // Much VersionCondition, performance loss
							}
						}
					}
					
					GLOBAL.compilerSettings.includeLevel = oriIncludeLevel;
				}
			}
		}
		
		
		static string[] checkUsingNamespace( CASTnode AST_Head, int lineNum )
		{
			string[] results;
			
			foreach( CASTnode _friends; AST_Head.getChildren )
			{
				if( _friends.kind & B_USING )
					if( _friends.lineNumber < lineNum ) results ~= _friends.name;
			}
			
			if( AST_Head.getFather !is null ) results ~= checkUsingNamespace( AST_Head.getFather, lineNum );
		
			return results;
		}
		

		static string getNameSpaceWithDotTail( CASTnode AST_Head )
		{
			string result;
			
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
		
		
		static CASTnode getExtendClass( CASTnode _AST_Head, string baseName )
		{
			string[]	_splitWord = Array.split( baseName, "." );
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

		
		static string analysisSplitWorld_ReturnCompleteList( ref CASTnode AST_Head, string[] splitWord, int lineNum, bool bDot, bool bCallTip, bool bPushContainer  )
		{
			if( AST_Head is null ) return null;
			
			auto		function_originalAST_Head = AST_Head;
			auto		_rootNode = ParserAction.getRoot( function_originalAST_Head );
			string		fullPath = _rootNode !is null ? _rootNode.name : "";
			string		memberFunctionMotherName, result;
			
			extendedClasses.length = 0;

			if( !splitWord[0].length )
			{
				if( AST_Head.kind & B_WITH )
				{
					string[] splitWithTile = getDivideWord( AST_Head.name );
					string[] tempSplitWord = splitWord;
					splitWord.length = 0;						
					foreach( s; splitWithTile ~ tempSplitWord )
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
						auto dotPos = indexOf( _fatherNode.name, "." );
						if( dotPos > -1 )
						{
							memberFunctionMotherName = _fatherNode.name[0..dotPos];
						}
					}
				}
			}
			
			CASTnode[] nameSpaceNodes;
			
			int startNum;
			if( lineNum == prevAnalysis.linenum )
			{	/*
				writefln( Array.join( prevAnalysis.word, "." ) );
				writefln( Array.join( splitWord, "." ) );
				writefln("");
				*/
				if( prevAnalysis.word.length < splitWord.length )
				{
					if( indexOf( Array.join( splitWord, "." ), Array.join( prevAnalysis.word, "." ) ) == 0 )
					{
						AST_Head = prevAnalysis.node;
						startNum = cast(int) prevAnalysis.word.length;
						//writefln( "BINGO" );
					}
				}
				/+
				else if( prevAnalysis.word.length == splitWord.length )
				{
					if( indexOf( Array.join( splitWord, "." ), Array.join( prevAnalysis.word, "." ) ) == 0 )
					{
						AST_Head = prevAnalysis.node;
						//writefln( "EQUAL BINGO" );
						
						if( bDot )
						{
							if( bPushContainer )
							{
								if( AST_Head.kind & ( B_TYPE | B_ENUM | B_UNION | B_NAMESPACE | B_CLASS ) )
								{
									foreach( CASTnode _child; getMembers( AST_Head ) ) // Get members( include nested unnamed union & type )
									{
										string _list = getListImage( _child, false );
										listContainer ~= _list;
									}
								}
							}
							return result;
						}
					}
				}
				+/
			}
			
			
			
			for( int i = startNum; i < splitWord.length; i++ )
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
									resultNodes	= getMatchASTfromWholeWord( cast(CASTnode) GLOBAL.objectDefaultParser, splitWord[i], -1, B_FUNCTION | B_SUB | B_DEFINE );

								resultNodes			~= getMatchASTfromWholeWord( AST_Head, splitWord[i], lineNum, B_FUNCTION | B_SUB | B_PROPERTY | B_TYPE | B_CLASS | B_UNION | B_NAMESPACE | B_DEFINE );
								auto _parserManaper = cast(CASTnode[string]) GLOBAL.parserManager;
								if( fullPathByOS(fullPath) in _parserManaper ) resultIncludeNodes = getMatchIncludesFromWholeWord( _parserManaper[fullPathByOS(fullPath)], fullPath, splitWord[i], lineNum );

								// For Type Objects
								if( memberFunctionMotherName.length )
								{
									// "_searchMatchNode" also search includes
									//CASTnode classNode = _searchMatchNode( AST_Head, memberFunctionMotherName, B_TYPE | B_CLASS );
									CASTnode classNode = searchMatchNode( AST_Head, memberFunctionMotherName, B_TYPE | B_CLASS, true );
									if( classNode !is null ) resultNodes ~= searchMatchMemberNodes( classNode, splitWord[i], B_ALL );
								}

								result = callTipList( resultNodes ~ resultIncludeNodes, splitWord[i] );
								return strip( result );
							}


							if( GLOBAL.compilerSettings.enableKeywordComplete == "ON" )
							{
								if( bPushContainer )
								{
									foreach( _s; GLOBAL.KEYWORDS )
									{
										foreach( s; Array.split( _s, " " ) )
										{
											if( s.length )
											{
												if( indexOf( Uni.toLower( s ), Uni.toLower( splitWord[i] ) ) == 0 )
												{
													s = tools.convertKeyWordCase( GLOBAL.keywordCase, s );
													listContainer ~= ( s ~ "?0" );
												}
											}
										}
									}
								}
							}

							if( AST_Head !is null )
							{
								resultNodes			= getMatchASTfromWord( AST_Head, splitWord[i], lineNum );
								
								if( fullPathByOS(fullPath) in GLOBAL.parserManager ) resultIncludeNodes = getMatchIncludesFromWord( cast(CASTnode) GLOBAL.parserManager[fullPathByOS(fullPath)], fullPath, splitWord[i], lineNum );
								// For Type Objects
								if( memberFunctionMotherName.length )
								{
									//CASTnode classNode = _searchMatchNode( AST_Head, memberFunctionMotherName, B_TYPE | B_CLASS );
									CASTnode classNode = searchMatchNode( AST_Head, memberFunctionMotherName, B_TYPE | B_CLASS, true );
									if( classNode !is null ) resultNodes ~= searchMatchMemberNodes( classNode,  splitWord[i] , B_ALL, false );
								}
								
								if( bPushContainer )
								{
									foreach( CASTnode _node; resultNodes )
									{
										string _list = getListImage( _node, true );
										listContainer ~= _list;
									}
									foreach( CASTnode _node; resultIncludeNodes )
									{
										string _list = getListImage( _node, false );
										listContainer ~= _list;
									}								
								}
							}
						}
						else
						{
							// Get Members
							//AST_Head = searchMatchNode( AST_Head, splitWord[i], B_FIND ); // NOTE!!!! Using "searchMatchNode()"
							import core.time;
							
							
							
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
											string _list = getListImage( _child, true );
											listContainer ~= _list;
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
										CASTnode memberFunctionMotherNode = searchMatchNode( cast(CASTnode) GLOBAL.parserManager[fullPathByOS(fullPath)], memberFunctionMotherName, B_TYPE | B_CLASS, true );
										if( memberFunctionMotherNode !is null )
										{
											if( Uni.toLower( splitWord[i] ) == "this" ) AST_Head = memberFunctionMotherNode; else AST_Head = searchMatchNode( memberFunctionMotherNode, splitWord[i], B_FIND );
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
							
								
							//********************************************************************
							prevAnalysis = PrevAnalysisUnit( [splitWord[0]], AST_Head, lineNum );
							//IupMessage( toStringz( Conv.to!(string)( i ) ), toStringz( splitWord[0] ) );
							
							
							if( bPushContainer )
							{
								if( AST_Head.kind & ( B_TYPE | B_ENUM | B_UNION | B_CLASS | B_NAMESPACE ) )
								{
									foreach( CASTnode _child; getMembers( AST_Head ) ) // Get members( include nested unnamed union & type )
									{
										string _list = getListImage( _child, false );
										listContainer ~= _list;
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
								CASTnode memberFunctionMotherNode = searchMatchNode( cast(CASTnode) GLOBAL.parserManager[fullPathByOS(fullPath)], memberFunctionMotherName, B_TYPE | B_CLASS, true );
								if( memberFunctionMotherNode !is null )
								{
									if( Uni.toLower( splitWord[i] ) == "this" ) AST_Head = memberFunctionMotherNode; else AST_Head = searchMatchNode( memberFunctionMotherNode, splitWord[i], B_FIND );
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

								return strip( result );
							}
							
							if( bPushContainer )
							{
								foreach( CASTnode a; nameSpaceNodes )
								{
									foreach( CASTnode _child; getMembers( a ) ) // Get members( include nested unnamed union & type )
									{
										if( indexOf( Uni.toLower( _child.name ), splitWord[i] ) == 0 )
										{
											string _list = getListImage( _child, false );
											listContainer ~= _list;
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
							
							//********************************************************************
							prevAnalysis = PrevAnalysisUnit( splitWord[0..$].dup, AST_Head, lineNum );							
							
							if( bPushContainer )
							{
								foreach( CASTnode a; nameSpaceNodes )
								{
									foreach( CASTnode _child; getMembers( a ) ) // Get members( include nested unnamed union & type )
									{
										string _list = getListImage( _child, false );
										listContainer ~= _list;
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
							return strip( result );
						}
						
						if( bPushContainer )
						{
							foreach( CASTnode _child; getMembers( AST_Head ) ) // Get members( include nested unnamed union & type )
							{
								if( indexOf( Uni.toLower( _child.name ), splitWord[i] ) == 0 )
								{
									string _list = getListImage( _child, false );
									listContainer ~= _list;
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
							//if( !stepByStep( AST_Head, splitWord[i], B_VARIABLE | B_FUNCTION | B_PROPERTY, lineNum ) ) return null;
							if( !stepByStep( AST_Head, splitWord[i], B_VARIABLE | B_FUNCTION | B_PROPERTY | B_TYPE | B_UNION, lineNum ) ) return null; // for nested TYPE / UNION
						}
						
						//********************************************************************
						prevAnalysis = PrevAnalysisUnit( splitWord[0..$].dup, AST_Head, lineNum );
						
						if( bPushContainer )
						{
							foreach( CASTnode _child; getMembers( AST_Head ) ) // Get members( include nested unnamed union & type )
							{
								string _list = getListImage( _child, false );
								listContainer ~= _list;
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
						if( !stepByStep( AST_Head, splitWord[i], B_VARIABLE | B_FUNCTION | B_PROPERTY | B_TYPE | B_UNION, lineNum ) ) return null; // for nested TYPE / UNION
					}
				}
			}		

			return result;
		}
		

	public:
		static shared float[string]		VersionCondition;	
		static bool 					bEnter;
		static bool 					bAutocompletionPressEnter;
		static bool						bSkipAutoComplete;
		
		static void init()
		{
			// For Static Struct -- AutoComplete Init!
			if( timer == null )
			{
				timer = IupTimer();
				IupSetAttributes( timer, "TIME=50,RUN=NO" );
				IupSetCallback( timer, "ACTION_CB", cast(Icallback) &CompleteTimer_ACTION );
				setTimer( std.conv.to!(int)( GLOBAL.triggerDelay ) );
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
		
		static string getShowTypeContent()
		{
			return showTypeContent;
		}

		static void clearShowTypeContent()
		{
			showTypeContent = "";
		}
		
		static void cleanIncludeContainer()
		{
			( cast(CASTnode[string]) includesMarkContainer ).clear;
		}
		
		static void cleanCalltipContainer()
		{
			calltipContainer.clear();
		}
		
		static void cleanInsertBIContainer()
		{
			( cast(bool[string]) noIncludeNodeContainer ).clear;
		}		
		
		static string getKeywordContainerList( string word, bool bCleanContainer = true )
		{
			string result;
			
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

				return strip( result );
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
					destroy( preLoadContainerThread );
					preLoadContainerThread = new CGetIncludes( astHead );
					preLoadContainerThread.start();
				}
				else
				{
					preLoadContainerThread.join();
				}
			}
		}


		static string checkIncludeExist( string include, string originalFullPath )
		{
			try
			{
				if( !include.length ) return null;
				
				FocusUnit _focusUnit = GLOBAL.compilerSettings.activeCompiler;
				string testPath;
				// The originalFullPath is often change by file, we need get the original file dir
				foreach( _importPath; _focusUnit.IncDir ~ Path.dirName( originalFullPath ) )
				{
					testPath = _importPath ~ "/" ~ include;
					if( std.file.exists( testPath ) )
						if( isFile( testPath ) ) return testPath;
				}
			}
			catch( Exception e )
			{
				IupMessage( "Bug", toStringz( "checkIncludeExist() Error:\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ std.conv.to!(string)( e.line ) ) );
			}
			return null;
		}
		

		static CASTnode[] getIncludes( CASTnode originalNode, string originalFullPath, int _LEVEL, int ln = 2147483647 )
		{
			if( originalNode is null ) return null;
			if( GLOBAL.compilerSettings.includeLevel == 0 ) return null;
			if( _LEVEL >= GLOBAL.compilerSettings.includeLevel && GLOBAL.compilerSettings.includeLevel > 0 ) return null;
			if( GLOBAL.compilerSettings.includeLevel > -1 ) _LEVEL++;
			

			CASTnode[]	results;
			//bool		bPrjFile;

			CASTnode rootNode = ParserAction.getRoot( originalNode );
			//if( ProjectAction.fileInProject( rootNode.name, GLOBAL.activeProjectPath ) ) bPrjFile = true;
			
			foreach( CASTnode _node; getMembers( originalNode, true ) )
			{
				if( _node.kind & B_INCLUDE )
				{
					if( _node.lineNumber < ln )
					{
						CASTnode[] _results = check( _node.name, originalFullPath, _LEVEL );
						if( _results.length ) results ~= _results;
					}
				}
			}

			return results;
		}
		
		static string includeComplete( Ihandle* iupSci, int pos, ref string text )
		{
			if( !text.length )  return null;
			
			dstring word32;
			string	word = text;
			bool	bExitLoopFlag;		
			
			if( text != "\\" && text != "/" && ( fSTRz( IupGetAttribute( iupSci, "AUTOCACTIVE" ) ) == "YES" ) ) return null;

			listContainer.length = 0;
			if( fromStringz( IupGetAttribute( iupSci, "AUTOCACTIVE" ) ) == "YES" ) IupSetAttribute( iupSci, "AUTOCCANCEL", "YES" );

			try
			{
				while( pos > -1 )
				{
					--pos;
					if( pos < 0 ) break;
					
					string _s = fSTRz( IupGetAttributeId( iupSci, "CHAR", pos ) );
					if( _s.length )
					{
						int key = cast(int) _s[0];
						if( key >= 0 && key <= 127 )
						{
							dstring sd = toUTF32( _s );
							dchar s = sd[0];
							switch( s )
							{
								case '"':								bExitLoopFlag = true; break;
								case ' ', '\t', ':', '\n', '\r':		bExitLoopFlag = true; break;
								default: 
									if( std.utf.isValidDchar( s ) )
									{
										word32 = "";
										word32 ~= s;
										word ~= strip( toUTF8( word32 ) );
									}
							}
						}
					}
					
					if( bExitLoopFlag ) break;
				}
				
				if( !word.length ) return null; else word = Algorithm.reverse( word.dup );

				string[] words = Array.split( tools.normalizeSlash( word ), "/" );
				string[] tempList;

				if( !words.length ) return null;
				
				if( words.length == 1 && (text == "\\" || text == "/" ) ) words ~= "";

				// Step 1: Relative from the directory of the source file
				string _path1 = Path.dirName( ScintillaAction.getActiveCScintilla.getFullPath );
				
				// Step 2: Relative from the current working directory
				/*
				string  _path2;
				string prjDir = actionManager.ProjectAction.fileInProject( ScintillaAction.getActiveCScintilla.getFullPath );
				if( prjDir.length )
					_path2 = prjDir;
				else
				
					_path2 = std.file.getcwd(); //new FilePath( Environment.cwd() ); // Tail include /
				*/
				/*
				But I think no one will want to cwd on poseidon( because cwd = poseidon's Path ). so Igorne it!
				*/
				
				// Step 3: Relative from addition directories specified with the -i command line option
				// Work on Project
				// Step 4(Final): The include folder of the FreeBASIC installation (FreeBASIC\inc, where FreeBASIC is the folder where the fbc executable is located)
				FocusUnit _focus = GLOBAL.compilerSettings.activeCompiler;
				string[] _path3 = _focus.IncDir.dup;
				
				for( int i = 0; i < words.length; ++ i )
				{
					if( i == words.length - 1 )
					{
						// Step 1: Relative from the directory of the source file
						if( std.file.exists( _path1 ) )
						{
							foreach( string s; dirEntries( _path1, SpanMode.shallow ) )
							{
								if( std.file.isDir( s ) )
									tempList ~= Path.baseName( s );
								else
								{
									if( tools.isParsableExt( Path.extension( s ), 7 ) ) tempList ~= Path.baseName( s );
								}
							}
						}
						
						/*
						// Step 2: Relative from the current working directory
						if( exists( _path2 ) )
						{
							foreach( string s; dirEntries( _path2, SpanMode.shallow ) )
							{
								if( isDir( s ) )
									tempList ~= Path.baseName( s );
								else
								{
									if( tools.isParsableExt( Path.extension( s ), 7 ) ) tempList ~= Path.baseName( s );
								}
							}
						}
						*/
						
						// Step 3: Relative from addition directories specified with the -i command line option
						// Work on Project
						// Step 4(Final): The include folder of the FreeBASIC installation (FreeBASIC\inc, where FreeBASIC is the folder where the fbc executable is located)
						foreach( _fp3; _path3 )
						{
							if( std.file.exists( _fp3 ) )
							{
								foreach( string s; dirEntries( _fp3, SpanMode.shallow ) )
								{
									if( isDir( s ) )
									{
										tempList ~= Path.baseName( s );
									}
									else
									{
										if( tools.isParsableExt( Path.extension( s ), 7 ) )
										{
											tempList ~= Path.baseName( s );
										}
									}
								}
							}
						}
					}
					else
					{
						_path1 = _path1 ~ "/" ~ word[i];
						/*_path2 = _path2 ~ "/" ~ word[i];*/
						for( int j = 0; j < _path3.length; ++ j )
							_path3[j] = _path3[j] ~ "/" ~ words[i];
					}
				}
				
				if( word == "\"" ) words[$-1] = "";
				foreach( s; tempList )
				{
					if( s.length )
					{
						string iconNum = "37";
						
						if( s.length > 4 )
						{
							if( Uni.toLower( s[$-4..$] ) == ".bas" ) iconNum = "35";
						}
						
						if( s.length > 3 )
						{
							if( Uni.toLower( s[$-3..$] ) == ".bi" ) iconNum = "36";
						}
						
						if( !words[$-1].length )
						{
							listContainer ~= ( s ~ "?" ~ iconNum );
						}
						else
						{
							if( indexOf( Uni.toLower( s ), Uni.toLower( words[$-1] ) ) == 0 ) listContainer ~= ( s ~ "?" ~ iconNum );
						}
					}
				}
				
				text = words[$-1];
				//Algorithm.sort( listContainer );
				Algorithm.sort!("toUpper(a) < toUpper(b)", SwapStrategy.stable)( listContainer );
				
				string list;
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
					
				return list;
			}
			catch( Exception e )
			{
				IupMessage( "includeComplete Error", toStringz( e.toString ) );
			}
			
			return null;
		}
		
		static int getProcedurePos( Ihandle* iupSci, int pos, string targetText )
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

			int posHead = cast(int) IupScintillaSendMessage( iupSci, 2197, cast(size_t) targetText.length, cast(ptrdiff_t) _t.toCString );

			while( posHead >= 0 )
			{
				int style = cast(int) IupScintillaSendMessage( iupSci, 2010, posHead, 0 ); // SCI_GETSTYLEAT 2010
				if( style == 1 || style == 19 || style == 4 )
				{
					IupScintillaSendMessage( iupSci, 2190, posHead - 1, 0 );				// SCI_SETTARGETSTART = 2190,
					IupScintillaSendMessage( iupSci, 2192, 0, 0 );							// SCI_SETTARGETEND = 2192,
					posHead = cast(int) IupScintillaSendMessage( iupSci, 2197, cast(size_t) targetText.length, cast(ptrdiff_t) _t.toCString );
				}
				else
				{
					bool bReSearch;
					
					// check if Type (Alias) or Temporary Types
					if( Uni.toLower( targetText ) == "type" )
					{
						string	afterWord;
						bool	bFirstChar = true;
						int		count;
						
						for( int i = posHead + cast(int) targetText.length; i < documentLength; ++ i )
						{
							string _s = Uni.toLower( fSTRz( IupGetAttributeId( iupSci, "CHAR", i ) ) );

							if( cast(int) _s[0] == 13 || _s == ":" || _s == "\n" )
							{
								break;
							}
							else if( _s == " " || _s == "\t" )
							{
								if( !bFirstChar )
								{
									count ++;
									
									if( count == 2 && Uni.toLower( afterWord ) == "as" )
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
					for( int i = posHead + cast(int) targetText.length; i < documentLength; ++ i )
					{
						string s = Uni.toLower( fSTRz( IupGetAttributeId( iupSci, "CHAR", i ) ) );

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
								string _s = Uni.toLower( fSTRz( IupGetAttributeId( iupSci, "CHAR", j ) ) );
								
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
					posHead = cast(int) IupScintillaSendMessage( iupSci, 2197, cast(size_t) targetText.length, cast(ptrdiff_t) _t.toCString );
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
		static int getProcedureTailPos( Ihandle* iupSci, int pos, string targetText, int direct )
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
				endText = strip( endText );

				if( Uni.toLower( endText ) == Uni.toLower( targetText ) )
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
		static int skipCommentAndString(  Ihandle* iupSci, int pos, string targetText, int direct )
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
			
			pos = cast(int) IupScintillaSendMessage( iupSci, 2197, cast(size_t) targetText.length, cast(ptrdiff_t) _t.toCString );
			
			while( pos > -1 )
			{
				int style = cast(int) IupScintillaSendMessage( iupSci, 2010, pos, 0 ); // SCI_GETSTYLEAT 2010
				if( style == 1 || style == 19 || style == 4 )
				{
					if( direct == 0 )
					{
						IupSetInt( iupSci, "TARGETSTART", pos - 1 );
						IupSetInt( iupSci, "TARGETEND", 0 );
						pos = cast(int) IupScintillaSendMessage( iupSci, 2197, cast(size_t) targetText.length, cast(ptrdiff_t) _t.toCString );
					}
					else
					{
						IupSetInt( iupSci, "TARGETSTART", pos + cast(int) targetText.length );
						IupSetInt( iupSci, "TARGETEND", -1 );
						pos = cast(int) IupScintillaSendMessage( iupSci, 2197, cast(size_t) targetText.length, cast(ptrdiff_t) _t.toCString );
					}
				}
				else
				{
					return pos;
				}
			}

			return pos;
		}

		static string getWholeWordDoubleSide( Ihandle* iupSci, int pos = -1 )
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
			string	result;
			dstring	resultd;
			
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
				
				result = Uni.toLower( strip( Algorithm.reverse( result.dup ) ) ).dup;
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

		static string getIncludeString( Ihandle* iupSci, int pos = -1 )
		{
			if( !checkIscludeDeclare( iupSci, pos ) ) return null;
			
			string	result;
			int		documentLength = IupGetInt( iupSci, "COUNT" );
			
			do
			{
				string s = fSTRz( IupGetAttributeId( iupSci, "CHAR", pos ) );
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
			 
			return Algorithm.reverse( result.dup );
		}
		
		static int getWholeWordTailPos( Ihandle* iupSci, int startPos )
		{
			try
			{
				while( startPos < IupGetInt( iupSci, "COUNT" ) )
				{
					string s = fSTRz( IupGetAttributeId( iupSci, "CHAR", startPos ) );
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

		static string getKeyWordReverse( Ihandle* iupSci, int pos, out int headPos )
		{
			dstring word32;
			string	word;
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
							dstring _dcharString = toUTF32( fSTRz( IupGetAttributeId( iupSci, "CHAR", pos ) ) );
							if( _dcharString.length )
							{
								if( actionManager.ScintillaAction.isComment( iupSci, pos ) )
								{
									return toUTF8( word32 );
								}
								else
								{
									switch( _dcharString )
									{
										case ")", "(", "[", "]", "<", ">", "{", "}":
										case " ", "\t", ":", "\n", "\r", "+", "-", "*", "/", "\\", "=", ",", "@":
											return toUTF8( word32 );
											
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
			
			version(Windows) word = toUTF8( word32 );

			return word;
		}

		static string getWholeWordReverse( Ihandle* iupSci, int pos, out int headPos )
		{
			dstring word32;
			string	word;
			int		countParen, countBracket;

			try
			{
				while( pos > -1 )
				{
					headPos = pos;
					--pos;
					if( pos < 0 ) break;
					
					string s = fSTRz( IupGetAttributeId( iupSci, "CHAR", pos ) );
					int key = cast(int) s[0];
					if( key >= 0 && key <= 127 )
					{
						version(Windows)
						{
							dstring _dcharString = toUTF32( fSTRz( IupGetAttributeId( iupSci, "CHAR", pos ) ) );
							if( _dcharString.length )
							{
								if( actionManager.ScintillaAction.isComment( iupSci, pos ) )
								{
									if( _dcharString == "\r" || _dcharString == "\n" )
									{
										if( countParen == 0 && countBracket == 0 ) return toUTF8( word32 ); else continue;
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
										if( countParen < 0 ) return toUTF8( word32 );
										break;
										
									case "]":
										if( countParen == 0 ) countBracket++;
										break;

									case "[":
										if( countParen == 0 ) countBracket--;
										if( countBracket < 0 ) return toUTF8( word32 );
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
										goto case;
									case " ", "\t", ":", "\n", "\r", "+", "-", "*", "/", "\\", "<", "=", ",", "@":
										if( countParen == 0 && countBracket == 0 ) return toUTF8( word32 );
										goto default;
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
										goto case;
										
									case " ", "\t", ":", "\n", "\r", "+", "-", "*", "/", "\\", "<", "=", ",", "@":
										if( countParen == 0 && countBracket == 0 ) return word;
										goto default;
										
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
			
			version(Windows) word = toUTF8( word32 );

			return word;
		}
		
		static string charAdd( Ihandle* iupSci, int pos, string text, bool bForce = false )
		{
			int		dummyHeadPos;
			string 	word, result;
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
			
			word = Uni.toLower( Algorithm.reverse( word.dup ) );

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
					string[]	splitWord = getDivideWord( word );
					int			lineNum = cast(int) IupScintillaSendMessage( iupSci, 2166, pos, 0 ) + 1; //SCI_LINEFROMPOSITION = 2166,
					CASTnode	AST_Head = actionManager.ParserAction.getActiveASTFromLine( cast(CASTnode) GLOBAL.parserManager[fullPathByOS(cSci.getFullPath)], lineNum );

					if( AST_Head is null )
					{
						if( GLOBAL.compilerSettings.enableKeywordComplete == "ON" ) return getKeywordContainerList( splitWord[0] );
						return null;
					}

					if( GLOBAL.autoCompletionTriggerWordCount < 1 && !bForce ) 
					{
						if( GLOBAL.compilerSettings.enableKeywordComplete == "ON" ) return getKeywordContainerList( splitWord[0] );
						return null;
					}
					
					auto oriAST = AST_Head;
					
					version(VERSION_NONE){} else checkVersionSpec( AST_Head, lineNum );


					// For Quick show the dialog...
					bool bCompleteJump;
					if( lineNum == prevComplete.linenum )
					{	/*
						writefln( Array.join( prevComplete.word, "." ) );
						writefln( Array.join( splitWord, "." ) );
						writefln("");				
						*/
						if( prevComplete.word.length == splitWord.length )
						{
							string prevWords = fullPathByOS( Array.join( prevComplete.word, "." ) );
							string nowWords = fullPathByOS( Array.join( splitWord, "." ) );
						
							if( indexOf( nowWords, prevWords ) == 0 )
							{
								if( bDot )
								{
									if( prevWords in prevComplete.completeList )
									{
										result = prevComplete.completeList[prevWords];
										bCompleteJump = true;
									}
								}
								else if( bCallTip )
								{
									if( prevWords in prevComplete.completeCallTip )
									{
										result = prevComplete.completeCallTip[prevWords];
										bCompleteJump = true;
									}
								}
							}
						}
					}
					else
					{
						if( prevComplete.completeList.length ) prevComplete.completeList.clear;
						if( prevComplete.completeCallTip.length ) prevComplete.completeCallTip.clear;
					}
					
					
					if( !bCompleteJump )
					{
						result = analysisSplitWorld_ReturnCompleteList( AST_Head, splitWord, lineNum, bDot, bCallTip, true );
						string[] usingNames = checkUsingNamespace( oriAST, lineNum );
						if( usingNames.length )
						{
							string[] noUsingListContainer;
							if( splitWord.length == 1 )
							{
								if( !bDot && !bCallTip )
								{
									noUsingListContainer = listContainer;
									listContainer.length = 0;
								}
								else if( bCallTip )
								{
									if( !result.length ) listContainer.length = 0; 
								}
							}
							
							if( !listContainer.length )
							{
								foreach( s; usingNames )
								{
									string[] splitWithDot = Array.split( s, "." );
									string[] namespaceSplitWord = splitWithDot ~ splitWord;
									string _result = analysisSplitWorld_ReturnCompleteList( oriAST, namespaceSplitWord, lineNum, bDot, bCallTip, true );
									
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
							//Algorithm.sort( listContainer );
							Algorithm.sort!("toUpper(a) < toUpper(b)", SwapStrategy.stable)( listContainer );

							string	_type, _list;
							int		maxLeft, maxRight;

							for( int i = 0; i < listContainer.length; ++ i )
							{
								if( listContainer[i].length )
								{
									auto dollarPos = lastIndexOf( listContainer[i], "#" );
									if( dollarPos > -1 )
									{
										_type = listContainer[i][dollarPos+1..$];
										if( _type.length > maxRight ) maxRight = cast(int) _type.length;
										_list = listContainer[i][0..dollarPos];
										if( _list.length > maxLeft ) maxLeft = cast(int) _list.length;
									}
									else
									{
										if( listContainer[i].length > maxLeft ) maxLeft = cast(int) listContainer[i].length;
									}
								}
							}

							for( int i = 0; i < listContainer.length; ++ i )
							{
								if( i > 0 )
								{
									if( listContainer[i] == listContainer[i-1] ) continue;
								}

								if( listContainer[i].length )
								{
									string _string;
									
									auto dollarPos = lastIndexOf( listContainer[i], "#" );
									if( dollarPos > -1 )
									{
										_type = listContainer[i][dollarPos+1..$];
										_list = listContainer[i][0..dollarPos];
										_string = stripRight( format( "%-" ~ std.conv.to!(string)(maxLeft) ~ "s :: %-" ~ std.conv.to!(string)(maxRight) ~ "s", _list, _type ) );
									}
									else
									{
										_string = listContainer[i];
									}

									result ~= ( _string ~ "^" );
								}
							}
						}

						if( result.length )
							if( result[$-1] == '^' ) result = result[0..$-1];
					}
						
					// For Quick show the dialog...
					if( bDot )
					{
						prevComplete.word = splitWord;
						prevComplete.linenum = lineNum;
						prevComplete.completeList[fullPathByOS( Array.join( splitWord, "." ) )] = result;
					}
					else if( bCallTip )
					{
						prevComplete.word = splitWord;
						prevComplete.linenum = lineNum;
						prevComplete.completeCallTip[fullPathByOS( Array.join( splitWord, "." ) )] = result;
					}							
				}

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
				string	word;
				bool	bDwell;
				auto cSci = actionManager.ScintillaAction.getActiveCScintilla();
				if( cSci !is null )
				{
					if( fullPathByOS(cSci.getFullPath) in GLOBAL.parserManager ){} else{ return; }
					
					if( currentPos == -1 ) currentPos = actionManager.ScintillaAction.getCurrentPos( cSci.getIupScintilla ); else bDwell = true;
					if( currentPos < 1 ) return;
				
					// Goto Includes
					string includeString = getIncludeString( cSci.getIupScintilla, currentPos );
					if( includeString.length )
					{
						string includeFullPath = checkIncludeExist( includeString, cSci.getFullPath );
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
								IupScintillaSendMessage( cSci.getIupScintilla, 2200, currentPos, cast(ptrdiff_t) _result.toCString ); // SCI_CALLTIPSHOW 2200
							}
							return;
						}
					}					
					
					if( ScintillaAction.isComment( cSci.getIupScintilla, currentPos ) ) return;
					
					word = getWholeWordDoubleSide( cSci.getIupScintilla, currentPos );
					if( !word.length ) return;
					word = Uni.toLower( Algorithm.reverse( word.dup ) );
					
					if( GLOBAL.debugPanel.isRunning && GLOBAL.debugPanel.isExecuting )
					{
						if( TYPE == -1 )
						{
							if( word.length )
							{
								word = fullPathByOS( Array.replace( word, "->", "." ).dup );
								string typeName, value, title, title1;
								string title0 = GLOBAL.debugPanel.getTypeValueByName( word, word, typeName, value ).dup;
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
									IupScintillaSendMessage( cSci.getIupScintilla, 2200, currentPos, cast(ptrdiff_t) _result.toCString ); // SCI_CALLTIPSHOW 2200
									
									auto assignPos = indexOf( title0, " = " );
									if( assignPos > -1 )
									{
										IupScintillaSendMessage( cSci.getIupScintilla, 2204, 0, cast(ptrdiff_t) assignPos ); // SCI_CALLTIPSETHLT 2204
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
					
					
					
					string[] splitWord = getDivideWord( word );
					
					// Manual
					version(FBIDE)
					{
						if( splitWord.length == 1 )
						{
							if( GLOBAL.toggleUseManual == "ON" )
							{
								if( TYPE == 0 && !bDwell )
								{
									string	keyWord;
									bool	bExitFlag;

									if( splitWord[0].length )
									{
										foreach( _s; GLOBAL.KEYWORDS )
										{
											foreach( targetText; Array.split( _s, " " ) )
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
													foreach( s; GLOBAL.manuals )
													{
														string[] _splitWords = Array.split( s, "," );
														if( _splitWords.length == 2 )
														{
															if( _splitWords[1].length )
															{
																HH_AKLINK	akLink;
																akLink.cbStruct = HH_AKLINK.sizeof;
																akLink.fReserved = 0;
																akLink.pszKeywords = toUTF16z( keyWord );
																akLink.fIndexOnFail = 0;
																//GLOBAL.htmlHelp( null, toString16z( _path ), 1, 0 ); // HH_DISPLAY_TOPIC = 1
																if( GLOBAL.htmlHelp( null, toUTF16z( _splitWords[1] ), 0x000D, cast(DWORD_PTR) &akLink ) != null ) //#define HH_KEYWORD_LOOKUP       &h000D
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
													string	keyPg;
													
													switch( Uni.toLower( keyWord ) )
													{
														case "select":			keyPg = "::KeyPgSelectcase.html";			break;
														case "if", "then":		keyPg = "::KeyPgIfthen.html";				break;
														default:				keyPg = "::KeyPg" ~ keyWord ~ ".html";
													}											

													if( GLOBAL.manuals.length > 0 )
													{
														string[] _splitWords = Array.split( GLOBAL.manuals[0], "," );
														if( _splitWords.length == 2 )
														{
															if( _splitWords[1].length )
															{
																IupExecute( "hh", toStringz( "\"" ~ _splitWords[1] ~ keyPg ~ "\"" ) );
																bExitFlag = true;
															}
														}
													}
												}
											}
											else
											{
												if( GLOBAL.manuals.length > 0 )
												{
													string[] _splitWords = Array.split( GLOBAL.manuals[0], "," );
													if( _splitWords.length == 2 )
													{
														if( _splitWords[1].length )
														{
															switch( Path.stripExtension( Path.baseName( GLOBAL.linuxHtmlAppName ) ) )
															{
																case "xchm":
																	IupExecute( toStringz( GLOBAL.linuxHtmlAppName ), toStringz( "\"file:" ~ _splitWords[1] ~ "#xchm:/KeyPg" ~ keyWord ~ ".html\"" ) );	// xchm "file:/home/username/freebasic/FB-manual-1.05.0.chm#xchm:/KeyPg%s.html"
																	break;
																case "kchmviewer":
																	IupExecute( toStringz( GLOBAL.linuxHtmlAppName ), toStringz( "--stoc " ~ keyWord ~ " /" ~ _splitWords[1] ) );	// "kchmviewer --sindex %s /chm-path
																	break;
																case "CHMVIEW":
																	IupExecute( toStringz( GLOBAL.linuxHtmlAppName ), toStringz( _splitWords[1] ~ " -p KeyPg" ~ keyWord ~ ".html" ) );
																	break;
																default:
																	IupExecute( "CHMVIEW", toStringz( _splitWords[1] ~ " -p KeyPg" ~ keyWord ~ ".html" ) );
															}
															bExitFlag = true;
														}
													}
												}
											}
											
											if( bExitFlag ) return;
										}
									}
								}
							}
						}
					}

					// Divide word
					int			lineNum = cast(int) IupScintillaSendMessage( cSci.getIupScintilla, 2166, currentPos, 0 ) + 1; //SCI_LINEFROMPOSITION = 2166,
					auto 		AST_Head = actionManager.ParserAction.getActiveASTFromLine( cast(CASTnode) GLOBAL.parserManager[fullPathByOS(cSci.getFullPath)], lineNum );
					auto		oriAST = AST_Head;
					string		memberFunctionMotherName;
					
					// Get VersionCondition names
					if( AST_Head is null ) return;

					checkVersionSpec( AST_Head, lineNum );
					
					if( !splitWord[0].length )
					{
						if( AST_Head.kind & B_WITH )
						{
							string[] splitWithTile = getDivideWord( AST_Head.name );
							string[] tempSplitWord = splitWord;
							splitWord.length = 0;						
							foreach( s; splitWithTile ~ tempSplitWord )
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
									auto dotPos = indexOf( _fatherNode.name, "." );
									if( dotPos > -1 )
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
					switch( Uni.toLower( word ) )
					{
						case "constructor":
							keyword_Btype = B_CTOR;
							goto case;
						case "destructor":
							if( keyword_Btype == 0 ) keyword_Btype = B_DTOR;
							goto default;
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
					CASTnode _analysisSplitWord( CASTnode _AST_Head, string[] _splitWord )
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
										CASTnode memberFunctionMotherNode = searchMatchNode( cast(CASTnode) GLOBAL.parserManager[fullPathByOS(cSci.getFullPath)], memberFunctionMotherName, B_TYPE | B_CLASS, true );
										if( memberFunctionMotherNode !is null )
										{
											if( Uni.toLower( _splitWord[i] ) == "this" )
											{
												matchNodes ~= memberFunctionMotherNode;
											}
											else
											{
												auto matchNode = searchMatchNode( memberFunctionMotherNode, _splitWord[i], B_FIND | B_CTOR | B_SUB );
												if( matchNode !is null ) matchNodes ~= matchNode;
											}
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
										if( Uni.sicmp( a.type, _AST_Head.type ) == 0 ) return a;
									
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
										auto matchNodes = searchMatchMemberNodes( a, _splitWord[i], B_VARIABLE | B_FUNCTION | B_PROPERTY | B_OPERATOR | B_NAMESPACE | B_SUB | B_ENUMMEMBER | B_TYPE | B_UNION );
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
										if( Uni.sicmp( a.type, _AST_Head.type ) == 0 ) return a;
									
									returnNode = nameSpaceNodes[0];
								}
							}
						}
						
						return returnNode;
					}
					
					
					CASTnode _performAnalysisSplitWord( CASTnode _AST_Head, string[] _splitWord )
					{
						auto _oriAST = _AST_Head;
						_AST_Head = null;
						
						string[] usingNames = checkUsingNamespace( _oriAST, lineNum );
						if( usingNames.length )
						{
							foreach( s; usingNames )
							{
								string[] splitWithDot = Array.split( s, "." );
								string[] namespaceSplitWord = splitWithDot ~ _splitWord;
								_AST_Head = _analysisSplitWord( _oriAST, namespaceSplitWord );
								if( _AST_Head !is null ) break;
							}
						}
						else
						{
							string _namespace = getNameSpaceWithDotTail( _oriAST );
							if( _namespace.length )
							{
								_namespace ~= Array.join( _splitWord, "." );
								_AST_Head = _analysisSplitWord( _oriAST, Array.split( _namespace, "." ) );
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
						
						string	_param, _type;
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
						
						IupScintillaSendMessage( cSci.getIupScintilla, 2206, cast(size_t) tools.convertIupColor( GLOBAL.editColor.showTypeFore ), 0 ); //SCI_CALLTIPSETFORE 2206
						IupScintillaSendMessage( cSci.getIupScintilla, 2205, cast(size_t) tools.convertIupColor( GLOBAL.editColor.showTypeBack ), 0 ); //SCI_CALLTIPSETBACK 2205

						auto _rNode = ParserAction.getRoot( AST_Head );

						string _list;
						if( _rNode.name == cSci.getFullPath )
							_list = ( "@ ThisFile ...[" ~ std.conv.to!(string)( AST_Head.lineNumber ) ~ "]\n" );
						else
							_list = ( "@ \"" ~ _rNode.name ~ "\"" ~ " ...[" ~ std.conv.to!(string)( AST_Head.lineNumber ) ~ "]\n" );

						int filePathPos = cast(int) _list.length;
						
						
						string nameSpaceTitle;
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
							string _name = AST_Head.name;
							
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
								
								
									auto typeNode = _performAnalysisSplitWord( AST_Head, Array.split( AST_Head.base[starIndex..$], "." ) ); //_analysisSplitWord( AST_Head, Util.split( AST_Head.base, "." ) );
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
						IupScintillaSendMessage( cSci.getIupScintilla, 2200, currentPos, cast(ptrdiff_t) _result.toCString ); // SCI_CALLTIPSHOW 2200
						IupScintillaSendMessage( cSci.getIupScintilla, 2213, 0, 0 ); // SCI_CALLTIPSETPOSITION 2213
						IupScintillaSendMessage( cSci.getIupScintilla, 2204, 0, filePathPos ); // SCI_CALLTIPSETHLT 2204
						IupScintillaSendMessage( cSci.getIupScintilla, 2207, cast(size_t) tools.convertIupColor( GLOBAL.editColor.showTypeHLT ), 0 ); // SCI_CALLTIPSETFOREHLT 2207
					}
					else
					{
						bool		bGotoMemberProcedure;
						string		className, procedureName;
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
						string		fullPath = _rootNode.name;
						
						if( bGotoMemberProcedure ) // Mean Goto Function with code( Type = 2 )
						{
							//IupMessage( "AST_Head", toStringz( to!(string)( AST_Head.kind ) ~ "\n" ~ AST_Head.name ~ "\n" ~ to!(string)( AST_Head.lineNumber ) ) );
							string[] exceptFiles;
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
							
							string[] nameSpaces = Array.split( getNameSpaceWithDotTail( AST_Head.getFather ), "." );

							// Declare & procedure body at same file
							CASTnode _resultNode = getMatchNodeInFile( oriAST, nameSpaces, procedureName, fullPath, AST_Head.kind );
							if( _resultNode !is null )
							{
								if( GLOBAL.navigation.addCache( fullPath, _resultNode.lineNumber ) ) actionManager.ScintillaAction.openFile( fullPath, _resultNode.lineNumber );
								return;
							}
							
							// Not Same File, Continue search
							// Check BAS file first
							string _ext = Path.extension( fullPath );
							if( Uni.toLower( _ext ) == ".bi" )
							{
								exceptFiles ~= ( Path.stripExtension( fullPath ) ~ ".bas" );
								_resultNode = getMatchNodeInFile( oriAST, nameSpaces, procedureName, exceptFiles[$-1], AST_Head.kind );
								if( _resultNode !is null )
								{
									if( GLOBAL.navigation.addCache( exceptFiles[$-1], _resultNode.lineNumber ) ) actionManager.ScintillaAction.openFile( exceptFiles[$-1], _resultNode.lineNumber );
									return;
								}
								else
								{
									exceptFiles ~= ( Path.stripExtension( fullPath ) ~ "." ~ GLOBAL.extraParsableExt );
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
								//IupMessage( "KIND", toStringz( to!(string)( _resultNode.kind ) ~ "\n" ~ _resultNode.name ~ "\n" ~ to!(string)( _resultNode.lineNumber ) ) );
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
				IupMessage( "Bug", toStringz( "toDefintionAndType() Error:\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ std.conv.to!(string)( e.line ) ) );
			}
		}
		
		
		static CASTnode getFunctionAST( CASTnode head, int _kind, string functionTitle, int line )
		{
			foreach_reverse( CASTnode node; head.getChildren() )
			{
				if( node.kind & _kind )
				{
					if( Uni.toLower( node.name ) == functionTitle )
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

		static string InsertEnd( Ihandle* iupSci, int lin, int pos )
		{
			// #define SCI_LINEFROMPOSITION 2166
			lin--; // ScintillaAction.getLinefromPos( iupSci, POS ) ) begin from 0
			
			bool _isHead( int _pos )
			{
				string _word;
				
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
				
				if( strip( _word ).length ) return false;
				
				return true;
			}
			
			bool _isTail( int _pos )
			{
				string _word;
				
				while( _pos < cast(int) IupScintillaSendMessage( iupSci, 2136, lin, 0 ) ) // SCI_GETLINEENDPOSITION 2136 )
				{
					string s = fSTRz( IupGetAttributeId( iupSci, "CHAR", ++_pos ) );
					int key = cast(int) s[0];
					if( key >= 0 && key <= 127 )
					{
						if( s == ":" || s == "\n" ) break;
						_word ~= s;
					}
				}
				
				if( strip( _word ).length ) return false;
				
				return true;
			}
			
			/*
				target....	or	target	= -1 ( _checkType )
				target		= 0 ( _checkType )
				target....	= 1 ( _checkType )
			....target		= 2 ( _checkType )
			....target....	= 3 ( _checkType )
			*/
			int _check( string target, int _checkType )
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
							if( !_isTail( POS + cast(int) target.length ) ) return -1;
							if( !_isHead( POS ) ) return -1;
						}
						
						if( _checkType & 1 )
						{
							if( _isTail( POS + cast(int) target.length ) ) return -1;
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
			
			string _checkProcedures( string keyword )
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
						string beforeWord = DocumentTabAction.getBeforeWord( iupSci, _pos - 1 );
						switch( beforeWord )
						{
							case "private", "protected", "public":
								int c0 = DocumentTabAction.getKeyWordCount( iupSci, keyword, "" );
								c0 += DocumentTabAction.getKeyWordCount( iupSci, keyword, "private" );
								c0 += DocumentTabAction.getKeyWordCount( iupSci, keyword, "protected" );
								c0 += DocumentTabAction.getKeyWordCount( iupSci, keyword, "public" );							
								int c1 = DocumentTabAction.getKeyWordCount( iupSci, keyword, "end" );
								if( c0 > c1 ) return "end " ~ keyword;
								break;
							default:
						}
					}
				}
				
				return null;
			}
			
			
			
			int		POS;
			string	resultProcedures = _checkProcedures( "sub" );
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
				string afterWord = DocumentTabAction.getAfterWord( iupSci, POS + 8 );
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
					string beforeWord = DocumentTabAction.getBeforeWord( iupSci, POS - 1 );
					switch( beforeWord )
					{
						case "private", "protected", "public":
							int c0 = DocumentTabAction.getKeyWordCount( iupSci, "function", "" );
							c0 += DocumentTabAction.getKeyWordCount( iupSci, "function", "private" );
							c0 += DocumentTabAction.getKeyWordCount( iupSci, "function", "protected" );
							c0 += DocumentTabAction.getKeyWordCount( iupSci, "function", "public" );							
							int c1 = DocumentTabAction.getKeyWordCount( iupSci, "function", "end" );
							if( c0 > c1 ) return "end function";
							break;
						default:
					}
				}
			}




			POS= _check( "extern", 1 );
			if( POS > -1 )
			{
				string afterWord = DocumentTabAction.getAfterWord( iupSci, POS + 6 );
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
		
		
		static bool callAutocomplete( Ihandle *ih, int pos, string text, string alreadyInput, bool bForce = false )
		{
			if( preLoadContainerThread !is null )
			{
				if( preLoadContainerThread.isRunning )
				{
					preLoadContainerThread.join();
				}
				else
				{
					destroy( preLoadContainerThread );
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
							string[] 	splitWord = getNeedDataForThread( ih, text, pos, lineNum, bDot, bCallTip, AST_Head );
							
							showListThread = new CShowListThread( AST_Head, pos, lineNum, bDot, bCallTip, splitWord, text );
							showListThread.start();
							
							if( fromStringz( IupGetAttribute( timer, "RUN" ) ) != "YES" ) IupSetAttribute( timer, "RUN", "YES" );
						}
					}
					else
					{
						if( showListThread !is null )
						{
							destroy( showListThread );
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
				string list = charAdd( ih, pos, text, bForce );

				if( list.length )
				{
					string[] splitWord = getDivideWord( alreadyInput );

					alreadyInput = splitWord[$-1];
					if( text == "(" )
					{
						if( fromStringz( IupGetAttribute( ih, "AUTOCACTIVE" ) ) == "YES" ) IupSetAttribute( ih, "AUTOCCANCEL", "YES" );

						IupScintillaSendMessage( ih, 2205, cast(size_t) tools.convertIupColor( GLOBAL.editColor.callTipBack ), 0 ); // SCI_CALLTIPSETBACK 2205
						IupScintillaSendMessage( ih, 2206, cast(size_t) tools.convertIupColor( GLOBAL.editColor.callTipFore ), 0 ); // SCI_CALLTIPSETFORE 2206
						
						//SCI_CALLTIPSETHLT 2204
						scope _result = new IupString( ScintillaAction.textWrap( list ) );
						IupScintillaSendMessage( ih, 2200, pos, cast(ptrdiff_t) _result.toCString );
						
						calltipContainer.push( std.conv.to!(string)( ScintillaAction.getLinefromPos( ih, pos ) ) ~ ";" ~ list );
						
						int highlightStart, highlightEnd;
						callTipSetHLT( list, 1, highlightStart, highlightEnd );
						if( highlightEnd > -1 ) IupScintillaSendMessage( ih, 2204, highlightStart, highlightEnd ); // SCI_CALLTIPSETHLT 2204
					}
					else
					{
						scope _result = new IupString( list );
						if( !alreadyInput.length ) IupScintillaSendMessage( ih, 2100, cast(size_t) alreadyInput.length - 1, cast(ptrdiff_t) _result.toCString ); else IupSetAttributeId( ih, "AUTOCSHOW", cast(int) alreadyInput.length - 1, _result.toCString );
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
					string s = fSTRz( singleWord );
					if( s == "(" || s == ")" || s == "," ) IupSetAttribute( ih, "AUTOCCANCEL", "YES" ); else return false;
				}
				else
				{
					return false;
				}
			}
		
			bool	bContinue;
			int		commaCount, parenCount, firstOpenParenPosFromDocument;
			string	procedureNameFromList, LineHeadText;
			int		lineNumber, currentLn = ScintillaAction.getCurrentLine( ih ) - 1;
			int		lineHeadPos = cast(int) IupScintillaSendMessage( ih, 2167, ScintillaAction.getCurrentLine( ih ) - 1, 0 );
			
			
			string _getLineHeadText( int _pos, string _result = "" )
			{
				while( _pos >= lineHeadPos )
					_result = fSTRz( IupGetAttributeId( ih, "CHAR", _pos-- ) ) ~ _result;
					
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
				string s = fSTRz( singleWord );
				
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

			string	procedureNameFromDocument = AutoComplete.parseProcedureForCalltip( ih, lineHeadPos, LineHeadText, commaCount, parenCount, firstOpenParenPosFromDocument ); // from document
			//char[]	procedureNameFromDocument = AutoComplete.parseProcedureForCalltip( ih, pos, commaCount, parenCount, firstOpenParenPosFromDocument ); // from document

			if( commaCount == 0 )
			{
				if( calltipContainer.size > 0 ) calltipContainer.pop();
				if( cast(int) IupScintillaSendMessage( ih, 2202, 0, 0 ) == 1 ) IupScintillaSendMessage( ih, 2201, 0, 0 ); //  SCI_CALLTIPCANCEL 2201 , SCI_CALLTIPACTIVE 2202
				return false;
			}

			// Last time we get null "List" at same line and same procedureNameFromDocument, leave!!!!!
			if( noneListProcedureName == std.conv.to!(string)( firstOpenParenPosFromDocument ) ~ ";" ~ procedureNameFromDocument ) return false;

			string	list;
			string	listInContainer = calltipContainer.size > 0 ? calltipContainer.top() : "";
			
			if( listInContainer.length )
			{
				auto semicolonPos = indexOf( listInContainer, ";" );
				if( semicolonPos > -1 )
				{
					lineNumber = std.conv.to!(int)( listInContainer[0..semicolonPos] );
					if( currentLn == lineNumber )
					{
						auto openParenPos = indexOf( listInContainer, "(" );
						if( openParenPos > semicolonPos )
						{
							//char[] procedureNameFromList;
							for( int i = cast(int) openParenPos - 1; i > semicolonPos; -- i )
							{
								if( listInContainer[i] == ' ' ) break;
								procedureNameFromList = listInContainer[i] ~ procedureNameFromList;
							}
							
							if( procedureNameFromList != "Constructor" )
							{
								if( Uni.toLower(procedureNameFromList) == Uni.toLower(procedureNameFromDocument) )
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
								string[] 	splitWord = getNeedDataForThread( ih, "(", firstOpenParenPosFromDocument, lineNum, bDot, bCallTip, AST_Head );
								
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
						calltipContainer.push( std.conv.to!(string)( ScintillaAction.getLinefromPos( ih, pos ) ) ~ ";" ~ list );
					}
				}
			}
			
			if( !bContinue )
			{
				if( calltipContainer.size > 1 )
				{
					calltipContainer.pop();
					list = calltipContainer.top;
					auto semicolonPos = indexOf( list, ";" );
					if( semicolonPos > -1 )
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
						IupScintillaSendMessage( ih, 2205, cast(size_t) tools.convertIupColor( GLOBAL.editColor.callTipBack ), 0 ); // SCI_CALLTIPSETBACK 2205
						IupScintillaSendMessage( ih, 2206, cast(size_t) tools.convertIupColor( GLOBAL.editColor.callTipFore ), 0 ); // SCI_CALLTIPSETFORE 2206
						scope _result = new IupString( ScintillaAction.textWrap( list ) );
						IupScintillaSendMessage( ih, 2200, pos, cast(ptrdiff_t) _result.toCString );
						
						//if( calltipContainer !is null )	calltipContainer.push( to!(string)( ScintillaAction.getLinefromPos( ih, pos ) ) ~ ";" ~ list );
						calltipContainer.push( std.conv.to!(string)( ScintillaAction.getLinefromPos( ih, pos ) ) ~ ";" ~ list );
					}
				
					if( cast(int) IupScintillaSendMessage( ih, 2202, 0, 0 ) == 1 )
					{
						int highlightStart, highlightEnd;
						callTipSetHLT( list, commaCount, highlightStart, highlightEnd );

						if( highlightEnd > -1 )
						{
							IupScintillaSendMessage( ih, 2204, highlightStart, highlightEnd ); // SCI_CALLTIPSETHLT 2204
							IupScintillaSendMessage( ih, 2207, cast(size_t) tools.convertIupColor( GLOBAL.editColor.callTipHLT ), 0 ); // SCI_CALLTIPSETFOREHLT 2207
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
			string	procedureNameFromDocument = AutoComplete.parseProcedureForCalltip( ih, pos, commaCount, parenCount, firstOpenParenPosFromDocument ); // from document
			if( cast(int) IupScintillaSendMessage( ih, 2202, 0, 0 ) == 1 )
			{
				string list = calltipContainer.top();
				if( list.length )
				{
					auto semicolonPos = indexOf( list, ";" );
					if( semicolonPos > -1 )
					{
						list = list[semicolonPos+1..$].dup;
				
						int highlightStart, highlightEnd;
						callTipSetHLT( list, commaCount, highlightStart, highlightEnd );

						if( highlightEnd > -1 )
						{
							IupScintillaSendMessage( ih, 2204, highlightStart, highlightEnd ); // SCI_CALLTIPSETHLT 2204
							IupScintillaSendMessage( ih, 2207, cast(size_t) tools.convertIupColor( GLOBAL.editColor.callTipHLT ), 0 ); // SCI_CALLTIPSETFOREHLT 2207
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
		
		static resetPrevContainer()
		{
			if( prevAnalysis.completeList.length ) prevAnalysis.completeList.clear;
			if( prevComplete.completeCallTip.length ) prevComplete.completeCallTip.clear;
			prevAnalysis.word.length = prevComplete.word.length = 0;
			prevAnalysis.linenum = prevComplete.linenum = 0;
			prevAnalysis.node = prevComplete.node = null;
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
						if( fSTRz( IupGetAttribute( sci, "AUTOCACTIVE" ) ) == "NO" )
						{
							int		_pos = ScintillaAction.getCurrentPos( sci );
							int		dummyHeadPos;
							string	_alreadyInput;
							string	lastChar = fSTRz( IupGetAttributeId( sci, "CHAR", _pos - 1 ) );
							
							if( _pos > 1 )
							{
								if( lastChar == ">" )
								{
									if( fromStringz( IupGetAttributeId( sci, "CHAR", _pos - 2 ) ) == "-" )
									{
										_alreadyInput = Algorithm.reverse( AutoComplete.getWholeWordReverse( sci, _pos - 2, dummyHeadPos ).dup );
										_alreadyInput ~= "->";
									}
								}
							}

							if( !_alreadyInput.length ) _alreadyInput = Algorithm.reverse( AutoComplete.getWholeWordReverse( sci, _pos, dummyHeadPos ).dup );
							string[] splitWord = AutoComplete.getDivideWord( _alreadyInput );
							_alreadyInput = splitWord[$-1];
							
							if( cast(int) IupScintillaSendMessage( sci, 2202, 0, 0 ) == 1 ) IupScintillaSendMessage( sci, 2201, 0, 0 ); //  SCI_CALLTIPCANCEL 2201 , SCI_CALLTIPACTIVE 2202
							
							scope _result = new IupString( AutoComplete.showListThread.getResult );
							version(Windows)
							{
								if( _alreadyInput.length )
									ScintillaAction.directSendMessage( sci, 2100, cast(size_t) _alreadyInput.length, cast(ptrdiff_t) _result.toCString );
								else
									ScintillaAction.directSendMessage( sci, 2100, 0, cast(ptrdiff_t) _result.toCString );
							}
							else
							{
								if( _alreadyInput.length )
									IupScintillaSendMessage( sci, 2100, cast(size_t) _alreadyInput.length, cast(ptrdiff_t) _result.toCString );
								else
									IupScintillaSendMessage( sci, 2100, 0, cast(ptrdiff_t) _result.toCString );
							}
						}
					}
				}
				
				destroy( AutoComplete.showListThread );
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

							IupScintillaSendMessage( sci, 2205, cast(size_t) tools.convertIupColor( GLOBAL.editColor.callTipBack ), 0 ); // SCI_CALLTIPSETBACK 2205
							IupScintillaSendMessage( sci, 2206, cast(size_t) tools.convertIupColor( GLOBAL.editColor.callTipFore ), 0 ); // SCI_CALLTIPSETFORE 2206
							scope _result = new IupString( ScintillaAction.textWrap( AutoComplete.showCallTipThread.getResult ) );
							IupScintillaSendMessage( sci, 2200, _pos, cast(ptrdiff_t) _result.toCString );
							
							AutoComplete.calltipContainer.push( to!(string)( ScintillaAction.getLinefromPos( sci, _pos ) ) ~ ";" ~ AutoComplete.showCallTipThread.getResult );
							
							int highlightStart, highlightEnd;
							AutoComplete.callTipSetHLT( AutoComplete.showCallTipThread.getResult, AutoComplete.showCallTipThread.ext, highlightStart, highlightEnd );
							if( highlightEnd > -1 ) 
							{
								IupScintillaSendMessage( sci, 2204, highlightStart, highlightEnd ); // SCI_CALLTIPSETHLT 2204
								IupScintillaSendMessage( sci, 2207, cast(size_t) tools.convertIupColor( GLOBAL.editColor.callTipHLT ), 0 ); // SCI_CALLTIPSETFOREHLT 2207
							}
							
							AutoComplete.noneListProcedureName = "";
						}
					}
				}
				else
				{
					AutoComplete.noneListProcedureName = to!(string)( AutoComplete.showCallTipThread.pos ) ~ ";" ~ AutoComplete.showCallTipThread.extString;
				}

				destroy( AutoComplete.showCallTipThread );
				AutoComplete.showCallTipThread = null;
			}
		}		
		
		if( AutoComplete.showListThread is null && AutoComplete.showCallTipThread is null )	IupSetAttribute( _ih, "RUN", "NO" );		
		
		return IUP_IGNORE;
	}	
}