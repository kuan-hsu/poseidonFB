module parser.autocompletionD;

version(DIDE)
{
	import iup.iup;
	import iup.iup_scintilla;

	import global, actionManager, menu, tools;
	import std.string, Conv = std.conv, Algorithm = std.algorithm, std.algorithm.mutation : SwapStrategy;
	
	struct AutoComplete
	{
	private:
		import parser.ast;
		import actionManager;

		import std.stdio, std.file, std.format, UTF = std.utf;
		import Path = std.path, Array = std.array, Uni = std.uni;
		import core.thread;

		struct PrevAnalysisUnit
		{
			string[]		word;
			CASTnode		node;
			int				linenum;
			string[string]	completeList, completeCallTip;
		}
		
		static Stack!(string)				calltipContainer;
		public static string				noneListProcedureName;
		
		static string[]						listContainer;
		static shared CASTnode[string]		includesMarkContainer;
		public static shared int[string]	VersionCondition;
		
		static shared CASTnode				nowLineAst;
		static shared int					nowLineNum;
		
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
				AutoComplete.getIncludes( AST_Head, AST_Head.name, true, true );
			}
		}		
		
		class CShowListThread : Thread
		{
		private:
			import scintilla;
			
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
				
				
				// For Quick show the dialog...
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
				}
				
				
				if( !bCompleteJump )
				{
					result = analysisSplitWorld_ReturnCompleteList( AST_Head, splitWord, lineNum, bDot, bCallTip, true );

					if( listContainer.length )
					{
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

						//string formatString = "{,-" ~ Conv.to!(string)( maxLeft ) ~ "} :: {,-" ~ Conv.to!(string)( maxRight ) ~ "}";					
						for( int i = 0; i < listContainer.length; ++ i )
						{
							if( i > 0 )
								if( listContainer[i] == listContainer[i-1] ) continue;

							if( listContainer[i].length )
							{
								string _string;
								
								auto dollarPos = lastIndexOf( listContainer[i], "#" );
								if( dollarPos > -1 )
								{
									_type = listContainer[i][dollarPos+1..$];
									_list = listContainer[i][0..dollarPos];
									_string = stripRight( format( "%-" ~ Conv.to!(string)(maxLeft) ~ "s :: %-" ~ Conv.to!(string)(maxRight) ~ "s", _list, _type ) );
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
		static Ihandle*					timer = null;

		static string getDefaultList( string s, bool bBracket )
		{
			if( s.length )
			{
				if( s[$-1] == ']' || s == "string" || s == "wstring" || s == "dstring" )
				{
					if( !bBracket )
					{
						listContainer.length = 0;
						return "dup?21^idup?21^init?21^length?21^ptr?21^reverse?21^sizeof?21^sort?21";

					}
				}
			}
			return null;
		}
		
		static bool checkIsFriendAndMother( CASTnode node )
		{
			if( node is null ) return false;
			/*
			int				lineNum = ScintillaAction.getCurrentLine( ScintillaAction.getActiveIupScintilla );
			CASTnode		AST_Head = ParserAction.getActiveASTFromLine( ParserAction.getActiveParseAST(), lineNum );
			*/
			int lineNum = nowLineNum;
			CASTnode AST_Head = cast(CASTnode) nowLineAst;
			
			if( AST_Head is null ) return false;
			
			
			// check Different module
			if( ParserAction.getRoot( node ) != ParserAction.getRoot( AST_Head ) ) return false;

			auto father = node.getFather;
			if( father !is null )
			{
				while( father.kind & D_TEMPLATE )
				{
					if( node.name != father.name ) break;
					
					if( father.getFather() !is null ) father = node.getFather; else break;
				}
				
				if( father.lineNumber < AST_Head.lineNumber && father.endLineNum > AST_Head.endLineNum ) return true;
			}
			else
			{
				// D_MODULE
				return true;
			}
			
			return false;
		}
		
		static string getShowTypeCTORList( CASTnode node, bool bAnalysisClass = true, int layerLimit = 3 )
		{
			if( node is null ) return null;
			
			string	result, _space;
			int		layer;
			
			void _getList( CASTnode _node )
			{
				if( _node.kind & D_TEMPLATE )
				{
					auto _sonNode = getAggregateTemplate( _node );
					if( _sonNode !is null )
					{
						_node = _sonNode;
						
						/+
						int quotePos = Util.rindex( _list, "\"" );
						if( quotePos < _list.length )
						{
							if( _sonNode.kind & D_CLASS )
								_list = _list[0..quotePos] ~ " \"CLASS\" " ~ _list[quotePos..$];
							else if( _sonNode.kind & D_INTERFACE )
								_list = _list[0..quotePos] ~ " \"INTERFACE\" " ~ _list[quotePos..$];
							else if( _sonNode.kind & D_FUNCTION )
								_list = _list[0..quotePos] ~ " \"FUNCTION\" " ~ _list[quotePos..$];
						}
						/*
						if( _sonNode.kind & D_CLASS )
							result ~= ( "\n" ~ _space ~ "             \"CLASS\" " ~ _sonNode.name );
						else if( _sonNode.kind & D_CLASS )
							result ~= ( "\n" ~ _space ~ "             \"INTERFACE\" " ~ _sonNode.name );
						else if( _sonNode.kind & D_FUNCTION )
							result ~= ( "\n" ~ _space ~ "             \"FUNCTION\" " ~ _sonNode.name );
						*/
						+/
					}		
				}
				
				if( _node.kind & D_FUNCTION )
				{
					if( _node.getFather !is null )
					{
						foreach( CASTnode funNode; searchMatchNodes( _node.getFather, _node.name, D_FUNCTION, _node.lineNumber ) )
						{
							result ~= "\n";
							if( GLOBAL.showTypeWithParams != "ON" )
								result ~= ( ParserAction.getSeparateType( funNode.type ) ~ " " ~ funNode.name );
							else
								result ~= ( ParserAction.getSeparateType( funNode.type ) ~ " " ~ funNode.name ~ ParserAction.getSeparateParam( funNode.type ) ).dup;
						}
						return;
					}
				}
				
				if( bAnalysisClass )
				{
					foreach( CASTnode _child; _node.getChildren() )
					{
						if( _child.kind & D_CTOR )
						{
							result ~= "\n";
							//_space[] = ' ';
							if( GLOBAL.showTypeWithParams != "ON" )
								result ~= ( _space ~ "this" );
							else
								result ~= ( _space ~ "this" ~ ParserAction.getSeparateParam( _child.type ) );
						}
					}

					if( ++layer < layerLimit )
					{
						if( _node.kind & ( D_CLASS | D_INTERFACE ) )
						{
							if( _node.base.length )
							{
								if( _node.getFather !is null )
								{
									// Search BaseNode, using originalNode.getFather to prevent infinite loop
									CASTnode mother = searchMatchNode( _node.getFather, ParserAction.removeArrayAndPointer( _node.base ), D_CLASS | D_INTERFACE | D_TEMPLATE );

									if( mother !is null )
									{
										string _type;
										switch( mother.kind )
										{
											case D_INTERFACE: _type = "\"INTERFACE\""; break;
											case D_TEMPLATE: _type = "\"TEMPLATE\""; break;
											case D_CLASS: _type = "\"CLASS\""; break;
											default:
										}
										
										_space.length = 0;
										for( int i = 0; i < layer; ++ i )
											_space ~= "--";
										
										result ~= "\n";
										result ~= ( _space ~ "Base Layer = " ~ ( _type.length ? _type ~ " " : null ) ~ mother.name ~ ( mother.base.length ? " : " ~ mother.base : "" ) );
										_getList( mother );
									}
								}
							}
						}
					}
				}
			}
			
			_getList( node );
			
			return result;
		}
		
		
		static string getMotherPath_D_MODULE( ref CASTnode oriNode, bool bToRoot = false )
		{
			string		cwdPath;
			CASTnode	astNode = oriNode;
			
			if( bToRoot )
			{
				while( astNode.getFather !is null )
					astNode = astNode.getFather;			
			}
			
			if( astNode.kind & D_MODULE )
			{
				auto dotCount = Algorithm.count( astNode.name, "." );
				cwdPath = Path.dirName( astNode.type );
				
				bool bPackageModule;
				if( Path.baseName( astNode.type ) == "package.d" )
					if( astNode.name.length > 6 )
						if( astNode.name[$-7..$] != "package" ) bPackageModule = true;
				
				
				for( int i = 0; i < dotCount; ++ i )
				{
					cwdPath = Path.dirName( cwdPath );
				}
				
				if( bPackageModule )
				{
					cwdPath = Path.dirName( cwdPath );
				}
			}		
			
			return cwdPath;
		}
		
		
		static CASTnode importComplete( CASTnode AST_Head, int lineNum, int completeCase, string[] splitWord, int wordIndex )
		{
			string RootFullPath;
			auto _root = ParserAction.getRoot( AST_Head );
			if( _root !is null ) RootFullPath = _root.type; else return null;
			
			switch( completeCase )
			{
				case 0:
					CASTnode[]	resultNodes			= getMatchASTfromWholeWord( AST_Head, splitWord[0], lineNum, D_IMPORT );
					CASTnode[]	resultIncludeNodes;
					if( fullPathByOS(RootFullPath) in GLOBAL.parserManager ) resultIncludeNodes = getMatchIncludesFromWholeWord( cast(CASTnode) GLOBAL.parserManager[fullPathByOS(RootFullPath)], null, splitWord[0], D_IMPORT );
					
					foreach( CASTnode _node; resultNodes ~ resultIncludeNodes )
					{
						if( !_node.type.length )
						{
							if( _node.name == splitWord[0] )
							{
								// Get Module AST From Import AST
								return searchMatchNode( AST_Head, _node.name, D_MODULE );
							}
						}
						else
						{
							if( _node.name == splitWord[0] )
							{
								if( _node.base.length )
								{
									if( _node.name != _node.base )
									{
										string base = _node.base;
										auto motherModule = searchMatchNode( AST_Head, _node.type, D_IMPORT ); // Check Renamed Imports
										if( motherModule !is null )
											if( motherModule.type.length ) _node = motherModule;
										
										motherModule = searchMatchNode( AST_Head, _node.type, D_MODULE );
										if( motherModule !is null )	return searchMatchMemberNode( motherModule, base, D_FIND );
									}
								}
								else
								{
									// Get Module AST From Import AST
									return searchMatchNode( AST_Head, _node.type, D_MODULE );
								}
							}
						}
					}
					
					return null;
					break;
					
				case 1: // wordIndex = 0; Using word full match
					CASTnode[]	resultNodes			= getMatchASTfromWord( AST_Head, splitWord[0], lineNum, D_IMPORT );
					CASTnode[]	resultIncludeNodes;
					
					if( fullPathByOS(RootFullPath) in GLOBAL.parserManager ) resultIncludeNodes = getMatchIncludesFromWord( cast(CASTnode) GLOBAL.parserManager[fullPathByOS(RootFullPath)], null, splitWord[0], false, D_IMPORT );
				
					string[]	results;
					CASTnode	markNode;
					
					foreach( CASTnode _node; resultNodes ~ resultIncludeNodes )
					{
						if( !_node.type.length )
						{
							if( _node.name == splitWord[0] )
							{
								// Get Module AST From Import AST
								return searchMatchNode( AST_Head, _node.name, D_MODULE );
							}
							
							if( indexOf( _node.name, splitWord[0] ~ "." ) == 0 )
							{
								string[] _nodeNames = Array.split( _node.name, "." );
								if( _nodeNames.length > 1 )
								{
									markNode = _node;
									results ~= ( _nodeNames[1] ~ "?22" );
								}
							}
						}
						else
						{
							if( _node.name == splitWord[0] )
							{
								if( _node.base.length )
								{
									if( _node.name != _node.base )
									{
										string base = _node.base;
										auto motherModule = searchMatchNode( AST_Head, _node.type, D_IMPORT ); // Check Renamed Imports
										if( motherModule !is null )
											if( motherModule.type.length ) _node = motherModule;
									
										motherModule = searchMatchNode( AST_Head, _node.type, D_MODULE );
										if( motherModule !is null )	return searchMatchMemberNode( motherModule, base, D_FIND );
									}
								}
								else
								{
									// Get Module AST From Import AST
									return searchMatchNode( AST_Head, _node.type, D_MODULE );
								}
							}
						}
					}

					Algorithm.sort( results );

					foreach( string s; results )
						listContainer ~= s;

					return markNode;

				case 2: // StepByStep
					string combineWord;
					for( int i = 0; i <= wordIndex; ++ i )
						combineWord ~= ( splitWord[i] ~ "." );

					if( combineWord.length > 1 ) combineWord = combineWord[0..$-1];

					CASTnode	returnNode;
					CASTnode[]	resultNodes			= getMatchASTfromWord( AST_Head, combineWord, lineNum, D_IMPORT );
					CASTnode[]	resultIncludeNodes;
					
					if( fullPathByOS(RootFullPath) in GLOBAL.parserManager ) resultIncludeNodes = getMatchIncludesFromWord( cast(CASTnode) GLOBAL.parserManager[fullPathByOS(RootFullPath)], null, combineWord, false, D_IMPORT );
						
					foreach( CASTnode _node; resultNodes ~ resultIncludeNodes )
					{
						if( !_node.type.length )
						{
							string[] _nodeNames = Array.split( _node.name, "." );
							
							if( _nodeNames.length == wordIndex + 1 )
							{
								if( _node.name == combineWord ) return searchMatchNode( AST_Head, _node.name, D_MODULE );
							}
							else if( _nodeNames.length > wordIndex + 1 )
							{
								if( indexOf( _node.name, combineWord ~ "." ) == 0 )
								{
									//results ~= ( _nodeNames[wordIndex+1] ~ "?22" );
									returnNode = _node;
								}			
							}
						}
					}

					return returnNode;				

				case 3: // Tail
					string combineWord;
					string[] results;

					for( int i = 0; i <= wordIndex; ++ i )
						combineWord ~= ( splitWord[i] ~ "." );

					if( combineWord.length > 1 ) combineWord = combineWord[0..$-1];

					CASTnode[]	resultNodes			= getMatchASTfromWord( AST_Head, combineWord, lineNum, D_IMPORT );
					CASTnode[]	resultIncludeNodes;
					
					if( fullPathByOS(RootFullPath) in GLOBAL.parserManager ) resultIncludeNodes = getMatchIncludesFromWord( cast(CASTnode) GLOBAL.parserManager[fullPathByOS(RootFullPath)], null, combineWord, false, D_IMPORT );
					
					foreach( CASTnode _node; resultNodes ~ resultIncludeNodes )
					{
						if( !_node.type.length )
						{
							string[] _nodeNames = Array.split( _node.name, "." );

							if( _nodeNames.length == wordIndex + 1 )
							{
								if( _node.name == combineWord ) return searchMatchNode( AST_Head, _node.name, D_MODULE );
							}
							else if( _nodeNames.length > wordIndex + 1 )
							{
								if( indexOf( _node.name, combineWord ~ "." ) == 0 )
								{
									listContainer ~= ( _nodeNames[wordIndex+1] ~ "?22" );
								}
							}
						}
					}
						
					break;

				case 4:

					string combineWord;
					for( int j = 0; j <= wordIndex; ++ j )
						combineWord ~= ( splitWord[j] ~ "." );

					if( combineWord.length > 1 ) combineWord = combineWord[0..$-1];	
					
					CASTnode[]	resultNodes			= getMatchASTfromWord( AST_Head, combineWord, lineNum, D_IMPORT );
					CASTnode[]	resultIncludeNodes;
					
					if( fullPathByOS(RootFullPath) in GLOBAL.parserManager ) resultIncludeNodes = getMatchIncludesFromWord( cast(CASTnode) GLOBAL.parserManager[fullPathByOS(RootFullPath)], null, combineWord, false, D_IMPORT );

					foreach( CASTnode _node; resultNodes ~ resultIncludeNodes )
					{
						if( !_node.type.length )
						{
							string[] nodeNames = Array.split( _node.name, "." );
							if( wordIndex < nodeNames.length )
							{
								listContainer ~= ( nodeNames[wordIndex] ~ "?22" );
							}
						}
					}
					break;

				default:
			}

			return null;
		}		

		static CASTnode[] combineNodes( CASTnode node, CASTnode[] nodeGroup )
		{
			CASTnode[] result;

			if( node !is null ) result ~= node;

			foreach( CASTnode _node; nodeGroup )
				if( _node != node ) result ~= _node;

			return result;
		}
		
		/+
		static string searchHead( Ihandle* iupSci, int pos, string targetText )
		{
			int documentLength = IupScintillaSendMessage( iupSci, 2006, 0, 0 );		// SCI_GETLENGTH = 2006,
			
			int posHead = getProcedurePos( iupSci, pos, targetText );
			if( posHead < 0 ) return null;

			int posEnd = getProcedureTailPos( iupSci, pos, targetText, 0 );//skipCommentAndString( iupSci, pos, "end " ~ targetText, 0 );
			if( posEnd > posHead ) return null;


			string	result;
			bool	bSPACE, bReturnNextWord;
			for( int i = posHead + targetText.length; i < documentLength; ++i )
			{
				string s = fromStringz( IupGetAttributeId( iupSci, "CHAR", i ) );

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
			IupMessage( "With", toStringz( Conv.to!(string)( posWith ) ) );
			IupMessage( "Sub", toStringz( Conv.to!(string)( posSub ) ) );
			IupMessage( "Function", toStringz( Conv.to!(string)( posFunction ) ) );
			*/

			if( posWith < 0 ) return false;

			if( posWith > posSub && posWith > posFunction && posWith > posProperty && posWith > posCtor && posWith > posDtor ) return true;

			return false;
		}
		+/

		static string getListImage( CASTnode node )
		{
			if( node is null ) return null;
			
			if( GLOBAL.compilerSettings.toggleShowAllMember == "OFF" )
			{
				if( node.protection == "private" )
					if( !checkIsFriendAndMother( node ) ) return null;
			}
			
			
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

			string type = node.type;
			type = ParserAction.getSeparateType( node.type );
			switch( node.kind )
			{
				case D_FUNCTION:				return name  ~ "#" ~ type ~ "?" ~ Conv.to!(string)( 28 + protAdd );
				case D_VARIABLE:
					if( node.name.length )
					{
						if( node.name[$-1] == ')' ) return name ~ "#" ~ type ~ "?" ~  Conv.to!(string)( 0 + protAdd ); else return name ~ "#" ~ type ~ "?" ~ Conv.to!(string)( 3 + protAdd );
					}
					break;
					
				case D_TEMPLATE:				return name ~ "?23";
				case D_CLASS:					return name ~ "?" ~ Conv.to!(string)( 6 + protAdd );
				case D_STRUCT: 					return name ~ "?" ~ Conv.to!(string)( 9 + protAdd );
				case D_ENUM: 					return name ~ "?" ~ Conv.to!(string)( 12 + protAdd );
				case D_PARAM:
						if( indexOf( type, "in " ) == 0 )
							type = type[3..$].dup;
						else if( indexOf( type, "out " ) == 0 )
							type = type[4..$].dup;
						else if( indexOf( type, "ref " ) == 0 )
							type = type[4..$].dup;
						else if( indexOf( type, "inout " ) == 0 )
							type = type[6..$].dup;
				
						return name ~ "#" ~ type ~ "?18";
				case D_ENUMMEMBER:				return name ~ "?19";
				case D_ALIAS:					return name ~ "?31";
				case D_INTERFACE:				return name ~ "?32";

				case D_IMPORT, D_MODULE:		return name ~ "?22";

				case D_STATICIF, D_CTOR, D_DTOR:
				case D_DEBUG, D_VERSION:		return null;

				/*
				case B_NAMESPACE:				return name ~ "?24";
				case B_INCLUDE, B_CTOR, B_DTOR:	return null;
				case B_OPERATOR:				return null;
				*/
				default:						return name ~ "?21";
			}

			return name;
		}

		static CASTnode[] anonymousEnumMembers( CASTnode originalNode )
		{
			if( originalNode is null ) return null;
			
			CASTnode[] results;
			
			if( originalNode.kind & D_ENUM )
			{
				foreach( CASTnode _node; originalNode.getChildren() )
				{
					results ~= _node;
				}
			}

			return results;
		}

		static CASTnode[] getAnonymousEnumMemberFromWord( CASTnode originalNode, string word, bool bCaseSensitive )
		{
			if( originalNode is null ) return null;
			
			CASTnode[] results;
			
			if( originalNode.kind & D_ENUM )
			{
				if( !originalNode.name.length )
				{
					foreach( CASTnode _node; anonymousEnumMembers( originalNode ) )
					{
						if( bCaseSensitive )
						{
							if( indexOf( _node.name, word ) == 0 ) results ~= _node;
						}
						else
						{
							if( indexOf( Uni.toLower( _node.name ), Uni.toLower( word ) ) == 0 ) results ~= _node;
						}
					}
				}
			}

			return results;
		}

		/*
		static CASTnode getAnonymousEnumMemberFromWholeWord( CASTnode originalNode, string word )
		{
			if( originalNode.kind & B_ENUM )
			{
				if( !originalNode.name.length )
				{			
					foreach( CASTnode _node; anonymousEnumMembers( originalNode ) )
					{
						if( _node.name == word ) return _node;
					}
				}
			}

			return null;
		}
		*/

		static CASTnode[] getBaseNodeMembers( CASTnode originalNode )
		{
			if( originalNode is null ) return null;
			
			CASTnode[] results;

			if( originalNode.kind & ( D_CLASS | D_INTERFACE ) )
			{
				if( originalNode.base.length )
				{
					if( originalNode.getFather !is null )
					{
						// Search BaseNode, using originalNode.getFather to prevent infinite loop
						CASTnode mother = searchMatchNode( originalNode.getFather, ParserAction.removeArrayAndPointer( originalNode.base ), D_CLASS | D_INTERFACE | D_TEMPLATE );

						if( mother !is null )
						{
							if( mother.kind & D_TEMPLATE )
							{
								auto temp = getAggregateTemplate( mother );
								if( temp !is null ) mother = temp;
							}
							
							foreach( CASTnode _node; mother.getChildren() )
								if( _node.protection != "private" ) results ~= _node;

							results ~= getBaseNodeMembers( mother );
						}
					}
				}
			}

			return results;
		}
		
		static CASTnode checkScopeNode( Ihandle* iupSci, CASTnode head, int line )
		{
			CASTnode nextNode;
			
			// Whole Word
			IupScintillaSendMessage( iupSci, 2198, 2, 0 );	// SCI_SETSEARCHFLAGS = 2198,
			
			int documentLength = cast(int) IupScintillaSendMessage( iupSci, 2006, 0, 0 );		// SCI_GETLENGTH = 2006,
			int currentPos = ScintillaAction.getCurrentPos( iupSci );

			return head;
		}		

		static CASTnode[] getMatchASTfromWholeWord( CASTnode node, string word, int line, int B_KIND )
		{
			if( node is null ) return null;
			
			CASTnode[] results;
			
			//foreach( child; node.getChildren() )
			foreach( child; getMembers( node ) )
			{
				if( child.kind & B_KIND )
				{
					if( child.name == word )
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

		static CASTnode[] getMatchASTfromWord( CASTnode node, string word, int line, int D_KIND )
		{
			if( node is null ) return null;
			
			CASTnode[] results;
			
			//foreach( child; node.getChildren() )
			foreach( child; getMembers( node ) )
			{
				if( child.kind & D_KIND )
				{
					if( child.name.length )
					{
						if( indexOf( child.name, word ) == 0 )
						{
							if( child.kind & ( D_VARIABLE | D_PARAM ) )
							{
								if( node.kind & D_FUNCTION )
								{
									if( line >= child.lineNumber ) results ~= child;
								}
								else
									results ~= child;
							}
							else
							{
								results ~= child;
							}
						}
					}
					else
					{
						if( line >= child.lineNumber )
						{
							CASTnode[] enumResult = getAnonymousEnumMemberFromWord( child, word, true );
							if( enumResult.length ) results ~= enumResult;
						}
					}
				}

				/*
				if( Util.index( child.name, word ) == 0 )
				{
					if( line >= child.lineNumber ) results ~= child;
				}
				*/
			}

			if( node.getFather() !is null )
			{
				results ~= getMatchASTfromWord( node.getFather, word, line, D_KIND );
			}

			return results;
		}

		static public string checkIncludeExist( string importName, string _cwd )
		{
			try
			{
				if( !importName.length ) return null;
				
				importName = Array.replace( importName, '.', '/' );
				if( Path.extension( _cwd ).length ) _cwd = Path.dirName( _cwd );
				
				auto _focusUnit = GLOBAL.compilerSettings.activeCompiler;
				string testPath;
				// The originalFullPath is often change by file, we need get the original file dir
				foreach( _importPath; _focusUnit.IncDir.dup ~ _cwd )
				{
					testPath = _importPath ~ "/" ~ importName ~ ".d";
					if( std.file.exists( testPath ) ) return testPath;
					
					testPath = _importPath ~ "/" ~ importName ~ ".di";
					if( std.file.exists( testPath ) ) return testPath;

					testPath = _importPath ~ "/" ~ importName ~ "/package.d";
					if( std.file.exists( testPath ) ) return testPath;
				}
			}
			catch( Exception e )
			{
				debug IupMessage( "Bug", toStringz( "checkIncludeExist() Error:\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ Conv.to!(string)( e.line ) ) );
			}
			return null;		
		}

		static CASTnode[] check( string name, string originalFullPath, bool bCheckOnlyOnce = false )
		{
			CASTnode[] results;
			
			string includeFullPath = checkIncludeExist( name, originalFullPath );

			if( includeFullPath.length )
			{
				if( fullPathByOS(includeFullPath) in includesMarkContainer ) return null;

				CASTnode includeAST;
				if( fullPathByOS(includeFullPath) in GLOBAL.parserManager )
				{
					includesMarkContainer[fullPathByOS(includeFullPath)] = GLOBAL.parserManager[fullPathByOS(includeFullPath)];
					auto _ast = cast(CASTnode) GLOBAL.parserManager[fullPathByOS(includeFullPath)];
					results ~= _ast;
					if( !bCheckOnlyOnce ) results ~= getIncludes( _ast, "" );
				}
				else
				{
					CASTnode _createFileNode = ParserAction.createParser( includeFullPath, true );
					
					if( _createFileNode !is null )
					{
						includesMarkContainer[fullPathByOS(includeFullPath)] = cast(shared CASTnode) _createFileNode;
						results ~= _createFileNode;
						if( !bCheckOnlyOnce ) results ~= getIncludes( _createFileNode, "" );
					}
					else
					{
						includesMarkContainer[fullPathByOS(includeFullPath)] = null;
					}
				}
			}

			return results;
		}

		static CASTnode[] getMatchIncludesFromWholeWord( CASTnode originalNode, string originalFullPath, string word, int D_KIND )
		{
			if( originalNode is null ) return null;
			
			CASTnode[] results;

			cleanIncludeContainer();
			getIncludes( originalNode, "", true );

			foreach( includeAST; cast(CASTnode[string]) includesMarkContainer )
			{
				if( D_KIND & D_MODULE )
				{
					if( includeAST.kind & D_KIND )
					{
						if( includeAST.name == word ) results ~= includeAST;
					}
				}
				
				// Skip "private"
				if( GLOBAL.compilerSettings.toggleShowAllMember == "OFF" )
					if( includeAST.protection == "private" ) continue;
				
				
				foreach( child; getMembers( includeAST ) )//includeAST.getChildren )
				{
					if( child.kind & D_KIND )
					{
						if( child.name.length )
						{
							if( child.name == word ) results ~= child;
						}
						else
						{
							CASTnode[] enumResult = getAnonymousEnumMemberFromWord( child, word, true );
							if( enumResult.length ) results ~= enumResult;
						}
					}
				}						
			}

			return results;
		}	

		static CASTnode[] getMatchIncludesFromWord( CASTnode originalNode, string originalFullPath, string word, bool bCaseSensitive, int D_KIND )
		{
			if( originalNode is null ) return null;
			
			CASTnode[] results;
			
			cleanIncludeContainer();
			getIncludes( originalNode, "", true );

			foreach( includeAST; includesMarkContainer )
			{
				if( D_KIND & D_MODULE )
				{
					if( includeAST.kind & D_KIND )
					{
						ptrdiff_t _pos;
						if( bCaseSensitive ) _pos = indexOf( includeAST.name, word ); else _pos = indexOf( Uni.toLower( includeAST.name ), Uni.toLower( word ) );
						if( _pos == 0 ) results ~= cast(CASTnode) includeAST;
					}
				}
				
				// Skip "private"
				if( GLOBAL.compilerSettings.toggleShowAllMember == "OFF" )
					if( includeAST.protection == "private" ) continue;		
			
				foreach( child; getMembers( cast(CASTnode) includeAST ) )//includeAST.getChildren )
				{
					//if( !checkBackThreadGoing ) return null;
					if( child.kind & D_KIND )
					{
						if( child.name.length )
						{
							ptrdiff_t _pos;
							if( bCaseSensitive ) _pos = indexOf( child.name, word ); else _pos = indexOf( Uni.toLower( child.name ), Uni.toLower( word ) );
							if( _pos == 0 ) results ~= child;
						}
						else
						{
							CASTnode[] enumResult = getAnonymousEnumMemberFromWord( child, word, bCaseSensitive );
							if( enumResult.length ) results ~= enumResult;
						}
					}
				}						
			}

			return results;
		}

		static bool isDefaultType( string _type )
		{
			if( _type == "bool" || _type == "byte" || _type == "ubyte" || _type == "short" || _type == "ushort" || _type == "int" || _type == "uint" || _type == "long" || _type == "ulong" ||
				_type == "char" || _type == "wchar" || _type == "dchar" || _type == "float" || _type == "double" || _type == "real" || _type == "ifloat" || _type == "idouble" || _type == "ireal" ||
				_type == "cfloat" || _type == "cdouble" || _type == "creal" || _type == "void" 	) return true;
				
			if( _type == "string" || _type == "wstring" || _type == "dstring" ) return true;

			return false;
		}

		static CASTnode searchMatchMemberNode( CASTnode originalNode, string word, int D_KIND = D_ALL )
		{
			if( originalNode is null ) return null;
			
			foreach( CASTnode _node; getMembers( originalNode ) )
			{
				if( _node.kind & D_KIND )
				{
					if( ParserAction.removeArrayAndPointer( _node.name ) == word ) return _node;
				}
			}

			return null;
		}

		static CASTnode[] searchMatchMemberNodes( CASTnode originalNode, string word, int D_KIND = D_ALL, int lineNum = 2147483647, bool bWholeWord = true, bool bCaseSensitive = true )
		{
			if( originalNode is null ) return null;
			
			CASTnode[] results;
			
			foreach( CASTnode _node; getMembers( originalNode ) )
			{
				if( _node.kind & D_KIND )
				{
					string name = ParserAction.removeArrayAndPointer( _node.name );

					if( !bCaseSensitive )
					{
						name = Uni.toLower( name );
						word = Uni.toLower( word );
					}

					if( bWholeWord )
					{
						if( name == word )
							if( lineNum >= _node.lineNumber ) results ~= _node;
					}
					else
					{
						if( indexOf( name, word ) == 0 )
							if( lineNum >= _node.lineNumber ) results ~= _node;
					}
				}
			}

			return results;
		}

		static CASTnode searchMatchNode( CASTnode originalNode, string word, int D_KIND = D_ALL )
		{
			if( originalNode is null ) return null;
			
			CASTnode resultNode = searchMatchMemberNode( originalNode, word, D_KIND );

			if( resultNode is null )
			{
				CASTnode[] resultIncludeNodes = getMatchIncludesFromWholeWord( originalNode, null, word, D_KIND );
				if( resultIncludeNodes.length )	return resultIncludeNodes[0];
				
				if( originalNode.getFather() !is null )
				{
					resultNode = searchMatchNode( originalNode.getFather(), word, D_KIND );
				}
				else
				{
					if( D_KIND & D_MODULE )
					{
						if( originalNode.name == word ) return originalNode;
					}
				}
			}
			
			return resultNode;
		}

		static CASTnode[] searchMatchNodes( CASTnode originalNode, string word, int D_KIND = D_ALL, int lineNum = 2147483647, bool bWholeWord = true, bool bCaseSensitive = true )
		{
			if( originalNode is null ) return null;
			
			CASTnode[] resultNodes = searchMatchMemberNodes( originalNode, word, D_KIND, lineNum, bWholeWord, bCaseSensitive );

			if( bWholeWord )
				resultNodes ~=  getMatchIncludesFromWholeWord( originalNode, null, word, D_KIND );
			else
				resultNodes ~=  getMatchIncludesFromWord( originalNode, null, word, false, D_KIND );
			

			if( originalNode.getFather() !is null )
			{
				resultNodes ~= searchMatchNodes( originalNode.getFather(), word, D_KIND, 2147483647, bWholeWord, bCaseSensitive );
			}
			else
			{
				if( D_KIND & D_MODULE )
				{
					if( bWholeWord )
					{
						if( originalNode.name == word ) resultNodes ~= originalNode;
					}
					else
					{
						if( indexOf( originalNode.name, word ) == 0 ) resultNodes ~= originalNode;
					}
				}
			}

			return resultNodes;
		}	

		static CASTnode[] getMembers( CASTnode AST_Head )
		{
			if( AST_Head is null ) return null;
			
			CASTnode[] result;

			CASTnode[] childrenNodes = AST_Head.getChildren();
			childrenNodes ~= getBaseNodeMembers( AST_Head );

			//foreach( CASTnode _child; AST_Head.getChildren() ~ getBaseNodeMembers( AST_Head ) )

			foreach( CASTnode _child; childrenNodes )
			{
				if( _child.kind & D_VERSION )
				{
					version(Windows)
					{
						if( _child.name == "Windows" || _child.name == "Win32" || ( _child.name == "-else-" && _child.base == "linux" ) )
						{
							result ~= getMembers( _child );
							continue;
						}
					}

					version(linux)
					{
						if( _child.name == "linux" || ( _child.name == "-else-" && _child.base != "linux" ) )
						{
							result ~= getMembers( _child );
							continue;
						}
					}				
				
					if( _child.name != "-else-" )
					{
						if( _child.name in VersionCondition ) result ~= getMembers( _child );
					}
					else
					{
						if( !( _child.name in VersionCondition ) ) result ~= getMembers( _child );
					}
				}
				else if( _child.kind & D_ENUM )
				{
					if( !_child.name.length )
					{
						result ~= anonymousEnumMembers( _child );
					}
					else
					{
						result ~= _child;
					}
				}
				else
				{
					result ~= _child;
				}
			}

			return result;
		}

		static int skipDelimitedString( char tokOpen, char tokClose, string word, int pos )
		{
			int		_countDemlimit, index;
			string	_params;		// include open Delimit and close Delimit


			for( index = pos; index < word.length; ++ index )
			{
				if( word[index] == tokOpen )
					_countDemlimit ++;
				else if( word[index] == tokClose )
					_countDemlimit --;

				if( _countDemlimit == 0 ) break;
			}

			return index;
		}	

		static string convertRightExpressWord( string word )
		{
			string	result;

			for( int i = 0; i < word.length; ++ i )
			{
				if( word[i] == '(' )
					i = skipDelimitedString( '(', ')', word, i );
				else if( word[i] == '[' )
					i = skipDelimitedString( '[', ']', word, i );
				else if( word[i] == '!' )
					continue;
				else
					result ~= word[i];
			}
				
			return result;
		}
		
		static CASTnode getType( CASTnode originalNode, int lineNum  )
		{
			if( originalNode is null ) return null;
			
			CASTnode resultNode;

			if( originalNode.kind & ( D_ALIAS | D_VARIABLE | D_PARAM | D_FUNCTION | D_FUNCTIONPTR ) )
			{
				string[]	splitWord;

				if( originalNode.type.length )
				{
					string _type = originalNode.type;
					
					if( originalNode.kind & D_PARAM )
					{
						if( indexOf( _type, "in " ) == 0 )
							_type = _type[3..$].dup;
						else if( indexOf( _type, "out " ) == 0 )
							_type = _type[4..$].dup;
						else if( indexOf( _type, "ref " ) == 0 )
							_type = _type[4..$].dup;
						else if( indexOf( _type, "inout " ) == 0 )
							_type = _type[6..$].dup;
					}
					
					// Check and get D_FUNCTIONPTR type
					if( originalNode.kind & D_FUNCTIONPTR )
					{
						auto _pos = indexOf( _type, " function(" );
						if( _pos == -1 ) _pos = indexOf( _type, " delegate(" );
						if( _pos > -1 ) _type = _type[0.._pos].dup;
					}
					
					splitWord = ParserAction.getDivideWordWithoutSymbol( _type );
				}
				else
				{
					// AutoDeclaration
					if( originalNode.base.length ) splitWord = getDivideWord( convertRightExpressWord( originalNode.base ) ); else return null;
				}
				
				foreach( string s; splitWord )
					if( s == originalNode.name ) return null;

				analysisSplitWorld_ReturnCompleteList( originalNode, splitWord, lineNum, true, false, false );
				if( originalNode !is null )
				{
					if( originalNode.kind & D_TEMPLATE )
					{
						auto _tempNode = getAggregateTemplate( originalNode );
						if( _tempNode !is null ) return _tempNode;
					}

					resultNode = originalNode;
				}
			}
			
			return resultNode;
		}

		static bool stepByStep( ref CASTnode AST_Head, string word, int D_KIND, int lineNum )
		{
			AST_Head = searchMatchMemberNode( AST_Head, word, D_KIND );
			if( AST_Head is null ) return false;

			if( AST_Head.kind & ( D_VARIABLE | D_PARAM | D_FUNCTION | D_ALIAS | D_FUNCTIONPTR ) )
			{
				AST_Head = getType( AST_Head, lineNum );
				if( AST_Head is null ) return false;
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
				
				if( groupAST[i].kind & ( D_FUNCTION | D_FUNCTIONPTR ) )
				{
					if( ( !word.length ) || groupAST[i].name == word )
					{
						string _type = ParserAction.getSeparateType( groupAST[i].type );
						string _paramString = ParserAction.getSeparateParam( groupAST[i].type );
						
						results ~= ( _type ~ " " ~ groupAST[i].name ~ _paramString ~ "\n" );
					}
				}
				else if( groupAST[i].kind & ( D_STRUCT | D_CLASS | D_UNION ) )
				{
					if( ( !word.length ) || groupAST[i].name == word )
					{
						foreach( CASTnode _child; groupAST[i].getChildren() )
						{
							if( _child.kind & D_CTOR )
							{
								results ~= ( groupAST[i].name ~ "::" ~ "this" ~ _child.type ~ "\n" );
							}
						}
					}
				}
				else if( groupAST[i].kind & ( D_TEMPLATE ) )
				{
					if( ( !word.length ) || groupAST[i].name == word )
					{
						foreach( CASTnode _child; groupAST[i].getChildren() )
						{
							if( _child.kind & D_FUNCTION )
							{
								if( _child.name == groupAST[i].name )
								{
									string _type = ParserAction.getSeparateType( groupAST[i].type );
									string _paramString = ParserAction.getSeparateParam( groupAST[i].type );
									
									results ~= ( _type ~ " " ~ groupAST[i].name ~ _paramString ~ "\n" );
								}
							}
							else if( _child.kind & ( D_STRUCT | D_CLASS | D_UNION ) )
							{
								foreach( CASTnode __child; _child.getChildren() )
								{
									if( __child.kind & D_CTOR )
									{
										results ~= ( "this" ~ __child.type ~ "\n" );
									}
								}
							}
						}
					}

				}
			}

			Algorithm.sort( results );
			
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
			foreach( string lineText; splitLines( list ) )
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
			
			if( lineHeadPos == -1 )	lineHeadPos = cast(int) IupScintillaSendMessage( ih, 2167, ScintillaAction.getCurrentLine( ih ) - 1, 0 ); //SCI_POSITIONFROMLINE 2167
			
			for( int i = cast(int) lineHeadText.length - 1; i >= 0; --i ) 
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
					if( lineHeadText[i] == ' ' || lineHeadText[i] == '\t' || lineHeadText[i] == '\n' || lineHeadText[i] == '\r' || lineHeadText[i] == '.' || lineHeadText[i] == ';')
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
					if( s == " " || s == "\t" || s == "\n" || s == "\r"  || s == "." || s == ";" )
						break;
					else
						procedureName = s ~ procedureName;
				}
			}
			
			return procedureName;
		}

		static void keyWordlist( string word )
		{
			foreach( string _s; GLOBAL.KEYWORDS )
			{
				foreach( string s; Array.split( _s, " " ) )
				{
					if( s.length )
					{
						if( indexOf( s, word ) == 0 ) listContainer ~= ( s ~ "?21" );
					}
				}
			}
		}

		static string[] getDivideWord( string word )
		{
			string[]	splitWord;
			string		tempWord;
			for( int i = 0; i < word.length ; ++ i )
			{
				if( word[i] == '.' )
				{
					if( tempWord.length > 1 )
						if( tempWord[0] == '!' ) tempWord = tempWord[1..$];

					splitWord ~= tempWord;
					tempWord = "";
				}
				else
				{
					tempWord ~= word[i];
				}			
			}

			if( tempWord.length > 1 )
				if( tempWord[0] == '!' ) tempWord = tempWord[1..$];

			splitWord ~= tempWord;

			return splitWord;
		}

		static CASTnode getAggregateTemplate( CASTnode templateNode )
		{
			if( templateNode is null ) return null;
			
			if( templateNode.kind & D_TEMPLATE )
			{
				foreach( CASTnode child; templateNode.getChildren() )
				{
					if( child.kind & ( D_CLASS | D_INTERFACE | D_STRUCT | D_UNION | D_FUNCTION ) )
					{
						if( child.name == templateNode.name ) return child;
					}
				}
			}

			return null;
		}

		static CASTnode[] searchObjectModuleMembers( string word, int D_KIND = D_ALL, bool bWholeWord = true, bool bCaseSensitive = true )
		{
			CASTnode[] resultNodes;
			
			// object.di
			if( GLOBAL.objectDefaultParser !is null )
			{
				foreach( CASTnode child; ( cast(CASTnode) GLOBAL.objectDefaultParser ).getChildren )
				{
					if( child.kind & D_KIND )
					{
						if( bWholeWord )
						{
							if( child.name == word ) resultNodes ~= child;
						}
						else
						{
							if( bCaseSensitive )
							{
								if( indexOf( child.name, word ) == 0 ) resultNodes ~= child;
							}
							else
							{
								if( indexOf( Uni.toLower( child.name ), Uni.toLower( word ) ) == 0 ) resultNodes ~= child;
							}
						}
					}	
				}
			}
			/*
			else  
				IupMessage("searchObjectModuleMembers","NULL");
			*/
			return resultNodes;
		}
		
		static CASTnode searchObjectModule( string word, int D_KIND = D_ALL, bool bWholeWord = true, bool bCaseSensitive = true )
		{
			CASTnode[] resultNodes = searchObjectModuleMembers( word, D_KIND, bWholeWord, bCaseSensitive );
			if( resultNodes.length ) return resultNodes[0];
			
			return null;
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
			else
			{
				word = text;
			}

			//word = word ~ getWholeWordReverse( iupSci, pos, dummyHeadPos );
			word = word ~ getWholeWordReverseWithBracket( iupSci, pos, dummyHeadPos ); // Keep With []
			word = Algorithm.reverse( word.dup );

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
					
					nowLineAst = cast(shared CASTnode) AST_Head;
					nowLineNum = lineNum;
					
					return getDivideWord( word );
				}
			}
			
			return null;
		}
		

		static string analysisSplitWorld_ReturnCompleteList( ref CASTnode AST_Head, string[] splitWord, int lineNum, bool bDot, bool bCallTip, bool bPushContainer  )
		{
			if( AST_Head is null ) return null;
			
			auto		function_originalAST_Head = AST_Head;
			auto		_rootNode = ParserAction.getRoot( function_originalAST_Head );
			string		fullPath = _rootNode !is null ? _rootNode.name : "";
			

			string		result;
			string		wordWithoutSymbol;
			CASTnode	tempReturnNode;
			bool		bBracket;

			int startNum;
			if( lineNum == prevAnalysis.linenum )
			{
				if( prevAnalysis.word.length < splitWord.length )
				{
					if( indexOf( Array.join( splitWord, "." ), Array.join( prevAnalysis.word, "." ) ) == 0 )
					{
						AST_Head = prevAnalysis.node;
						startNum = cast(int) prevAnalysis.word.length;
						//IupMessage( "GO", toStringz( Array.join( prevAnalysis.word, "." ) ) );
					}
				}
			}			
			for( int i = startNum; i < splitWord.length; i++ )
			{
				listContainer.length = 0;
				
				// 
				wordWithoutSymbol = ParserAction.removeArrayAndPointer( splitWord[i] );
				if( splitWord[i].length ) bBracket = ( splitWord[i][$-1] == ']' ? true : false ); else bBracket = false;
				
				
				if( i == 0 )
				{
					if( splitWord.length == 1 )
					{
						if( !bDot )
						{
							CASTnode[] resultNodes;
							if( bCallTip )
							{
								foreach( node; searchMatchNodes( AST_Head, splitWord[i], D_FIND | D_IMPORT, lineNum, true ) ~ searchObjectModuleMembers( splitWord[i], D_FIND )  ) // NOTE!!!! Using "searchMatchNode()"
								{
									if( node !is null )
									{
										if( node.kind & ( D_FUNCTION | D_CLASS | D_STRUCT | D_INTERFACE | D_UNION | D_FUNCTIONPTR ) )
										{
											resultNodes ~= node;
										}
										else if( node.kind & ( D_VARIABLE | D_PARAM | D_ALIAS ) )
										{
											node = getType( node, lineNum );
											if( node !is null ) resultNodes ~= node;
										}
										else if( node.kind & D_TEMPLATE )
										{
											auto temp = getAggregateTemplate( node );
											if( temp !is null ) resultNodes ~= temp;
										}
										else if( node.kind & D_IMPORT ) // Selective Imports
										{
											if( node.base.length )
											{
												string base = node.base;
												auto motherModule = searchMatchNode( AST_Head, node.type, D_IMPORT ); // Check Renamed Imports
												if( motherModule !is null )
													if( motherModule.type.length ) node = motherModule;
												
												motherModule = searchMatchNode( AST_Head, node.type, D_MODULE );
												if( motherModule !is null ) resultNodes ~= searchMatchMemberNode( motherModule, base, D_FIND );
											}											
										}
									}
								}

								if( !bPushContainer ) return null;

								result = callTipList( resultNodes, null );
								return strip( result );
							}


							if( GLOBAL.compilerSettings.enableKeywordComplete == "ON" ) keyWordlist( splitWord[i] );

							if( bPushContainer )
							{
								foreach( CASTnode _node; searchMatchNodes( AST_Head, splitWord[i], D_ALL, lineNum, false, false ) ~ searchObjectModuleMembers( splitWord[i], D_FIND, false, false ) )
								{
									if( _node.kind & D_IMPORT )
									{
										string[] nodeNames = Array.split( _node.name, "." );
										listContainer ~= ( nodeNames[0] ~ "?22");
									}
									else
										listContainer ~= getListImage( _node );
								}
							}						
						}
						else
						{
							CASTnode	_sub_ori_AST_Head = AST_Head;
							
							// Get Members
							AST_Head = searchMatchNode( AST_Head, wordWithoutSymbol, D_FIND ); // NOTE!!!! Using "searchMatchNode()"
							if( AST_Head is null ) AST_Head = searchObjectModule( wordWithoutSymbol, D_FIND );
							if( AST_Head is null )
							{
								AST_Head = importComplete( _sub_ori_AST_Head, lineNum, 1, splitWord, 0 );
								if( AST_Head is null ) break;
							}
							
							// Check AggregateTemplate
							tempReturnNode = getAggregateTemplate( AST_Head );
							if( tempReturnNode !is null ) AST_Head = tempReturnNode;
							
							/*
							if( AST_Head.kind & ( D_VARIABLE | D_PARAM ) )
							{
								string defaultList = getDefaultList( ParserAction.getSeparateType( AST_Head.type ) );
								if( defaultList.length ) return defaultList;
							}
							*/

							if( AST_Head.kind & ( D_VARIABLE | D_PARAM | D_FUNCTION | D_ALIAS | D_FUNCTIONPTR ) )
							{
								string defaultList = getDefaultList( ParserAction.getSeparateType( AST_Head.type ), bBracket );
								if( defaultList.length ) return defaultList;
								
								tempReturnNode = getType( AST_Head, lineNum );
								if( tempReturnNode !is null )
								{
									AST_Head = tempReturnNode;
									// Re-check New AST_Head
									defaultList = getDefaultList( ParserAction.getSeparateType( AST_Head.type ), bBracket );
									if( defaultList.length ) return defaultList;
								}
							}
							
							//********************************************************************
							prevAnalysis = PrevAnalysisUnit( [splitWord[0]], AST_Head, lineNum );
							//IupMessage( toStringz( Conv.to!(string)( i ) ), toStringz( splitWord[0] ) );							
							
							
							if( bPushContainer )
							{
								if( AST_Head.kind & ( D_STRUCT | D_ENUM | D_UNION | D_CLASS ) )
								{
									foreach( CASTnode _child; getMembers( AST_Head ) ) // Get members( include nested unnamed union & type )
									{
										if( _child.kind & ( D_FIND | D_ENUMMEMBER ) ) listContainer ~= getListImage( _child );
									}
								}

								if( AST_Head.kind & D_MODULE )
								{
									foreach( CASTnode _child; getMembers( AST_Head ) ) // Get members( include nested unnamed union & type )
									{
										if( !( _child.kind & D_IMPORT ) ) listContainer ~= getListImage( _child );
									}
								}
							}
						}
						break;
					}

					CASTnode	_sub_ori_AST_Head = AST_Head;
					AST_Head = searchMatchNode( AST_Head, wordWithoutSymbol, D_FIND ); // NOTE!!!! Using "searchMatchNode()"
					if( ParserAction.getRoot( _sub_ori_AST_Head ) != ParserAction.getRoot( AST_Head ) ) lineNum = 2147483647; // Different Module
					
					if( AST_Head is null ) AST_Head = searchObjectModule( wordWithoutSymbol, D_FIND );

					if( AST_Head is null )
					{
						AST_Head = importComplete( _sub_ori_AST_Head, lineNum, 1, splitWord, 0 );
						
						if( AST_Head is null ) return null;
						
						if( AST_Head.kind & D_IMPORT ) continue;
					}

					tempReturnNode = getAggregateTemplate( AST_Head );
					if( tempReturnNode !is null ) AST_Head = tempReturnNode;

					if( AST_Head.kind & ( D_VARIABLE | D_PARAM | D_FUNCTION | D_ALIAS | D_FUNCTIONPTR ) )
					{
						AST_Head = getType( AST_Head, lineNum );
						if( AST_Head is null ) return null;
					}
				}
				else if( i == splitWord.length -1 )
				{
					if( !bDot )
					{
						if( bCallTip )
						{
							if( !bPushContainer ) return null;

							//if( AST_Head is null ) IupMessage("",""); else IupMessage("",toStringz(Conv.to!(string)(AST_Head.kind) ~ " " ~ AST_Head.name));

							CASTnode[] childrenNodes;// =  AST_Head.getChildren();
							//getBaseNodeMembers( AST_Head, childrenNodes );

							//foreach( node; searchMatchNodes( AST_Head, splitWord[i], D_FIND, lineNum, true ) ~ searchObjectModuleMembers( splitWord[i], D_FIND ) ) // NOTE!!!! Using "searchMatchNode()"
							foreach( node; searchMatchNodes( AST_Head, splitWord[i], D_FIND ) ~ searchObjectModuleMembers( splitWord[i], D_FIND ) ) // NOTE!!!! Using "searchMatchNode()"
							{
								if( node !is null )
								{
									if( node.kind & ( D_FUNCTION | D_CLASS | D_STRUCT | D_INTERFACE | D_UNION | D_FUNCTIONPTR ) )
									{
										childrenNodes ~= node;
									}
									else if( node.kind & ( D_VARIABLE | D_PARAM | D_ALIAS ) )
									{
										node = getType( node, lineNum );
										if( node !is null ) childrenNodes ~= node;
									}
									else if( node.kind & D_TEMPLATE )
									{
										auto temp = getAggregateTemplate( node );
										if( temp !is null ) childrenNodes ~= temp;
									}
								}
							}

							if( !bPushContainer ) return null;

							// result = callTipList( childrenNodes, splitWord[i] );
							result = callTipList( childrenNodes, null );
							return strip( result );
						}

						if( bPushContainer )
						{
							if( AST_Head.kind & D_IMPORT )
							{
								importComplete( function_originalAST_Head, lineNum, 4, splitWord, i );
							}
							else
							{
								//IupMessage("originalNode", toStringz( Conv.to!(string)( AST_Head.kind ) ~ " " ~ ( AST_Head.name ) ~ " : " ~ AST_Head.type ) );
								foreach( CASTnode _child; getMembers( AST_Head ) ) // Get members( include nested unnamed union & type )
								{
									if( indexOf( Uni.toLower( _child.name ), Uni.toLower( splitWord[i] ) ) == 0 ) listContainer ~= getListImage( _child );
								}
							}
						}
					}
					else
					{
						if( AST_Head is null ) return null;

						if( !( AST_Head.kind & D_IMPORT ) )
							AST_Head = searchMatchMemberNode( AST_Head, wordWithoutSymbol, D_FIND );
						else
							AST_Head = importComplete( function_originalAST_Head, lineNum, 3, splitWord, i );
						
						if( AST_Head is null ) return null;

						if( AST_Head.kind & D_MODULE )
						{
							if( bPushContainer )
							{
								foreach( CASTnode _child; getMembers( AST_Head ) ) // Get members( include nested unnamed union & type )
								{
									if( !( _child.kind & D_IMPORT ) ) listContainer ~= getListImage( _child );
								}
							}
						}
						else
						{
							if( AST_Head.kind & ( D_VARIABLE | D_PARAM | D_FUNCTION | D_FUNCTIONPTR ) )
							{	
								string defaultList = getDefaultList( ParserAction.getSeparateType( AST_Head.type ), bBracket );
								if( defaultList.length ) return defaultList;
								
								tempReturnNode = getType( AST_Head, lineNum );
								if( tempReturnNode !is null )
								{
									AST_Head = tempReturnNode;
									// Re-check New AST_Head
									defaultList = getDefaultList( ParserAction.getSeparateType( AST_Head.type ), bBracket );
									if( defaultList.length ) return defaultList;
								}
							}
							
							if( bPushContainer )
							{
								if( AST_Head.kind & ( D_STRUCT | D_ENUM | D_UNION | D_CLASS | D_INTERFACE ) )
								{
									foreach( CASTnode _child; getMembers( AST_Head ) ) // Get members( include nested unnamed union & type )
									{
										if( _child.kind & ( D_FIND | D_ENUMMEMBER ) ) listContainer ~= getListImage( _child );
									}
								}
								else if( AST_Head.kind & D_TEMPLATE )
								{
									foreach( CASTnode kid; AST_Head.getChildren )
									{
										if( kid.kind & ( D_CLASS | D_INTERFACE | D_STRUCT | D_UNION | D_FUNCTION ) )
										{
											if( kid.name == AST_Head.name )
											{
												foreach( CASTnode _child; getMembers( AST_Head ) ) // Get members( include nested unnamed union & type )
												{
													if( _child.kind & ( D_FIND | D_ENUMMEMBER ) ) listContainer ~= getListImage( _child );
												}											
											}
										}
									}
								}
								
							}
						}
						
						//********************************************************************
						prevAnalysis = PrevAnalysisUnit( splitWord[0..$].dup, AST_Head, lineNum );
						//IupMessage( toStringz( Conv.to!(string)( i ) ), toStringz( Array.join( prevAnalysis.word, "." ) ) );
					}
				}
				else
				{
					if( !( AST_Head.kind & D_IMPORT ) )
					{
						//if( !stepByStep( AST_Head, splitWord[i], D_FIND ) ) return null;
						if( !stepByStep( AST_Head, wordWithoutSymbol, D_FIND, lineNum ) ) return null;
					}
					else
					{
						AST_Head = importComplete( function_originalAST_Head, lineNum, 2, splitWord, i );
						if( AST_Head is null ) return null;
					}
				}
			}

			return result;
		}



		public:
		static bool bEnter, bInsertBrace;
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
				setTimer( Conv.to!(int)( GLOBAL.triggerDelay ) );
			}
			
			calltipContainer.clear();
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
		
		static string getShowTypeContent()
		{
			return showTypeContent;
		}

		static void clearShowTypeContent()
		{
			showTypeContent = "";
		}		
		
		static bool showCallTipThreadIsRunning()
		{
			if( showCallTipThread is null ) return false;
			if( !showCallTipThread.isRunning ) return false;
		
			return true;
		}		
		
		static void cleanIncludeContainer()
		{
			( cast(CASTnode[string]) includesMarkContainer ).clear;
		}
		
		static void cleanCalltipContainer()
		{
			calltipContainer.clear();
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

		static bool checkIsclmportDeclare( Ihandle* iupSci, int pos = -1 )
		{
			string	result;
			dstring	resultd;
			
			int		documentLength = IupGetInt( iupSci, "COUNT" );
			try
			{
				while( --pos >= 0 )
				{
					if( !ScintillaAction.isComment( iupSci, pos ) )
					{
						string s = fSTRz( IupGetAttributeId( iupSci, "CHAR", pos ) );
						if( s.length )
						{
							int key = cast(int) s[0];
							if( key >= 0 && key <= 127 )
							{
								if( s == ";" ) break;
								result ~= s;
							}
						}
					}	
				}
				
				result = Uni.toLower( strip( Algorithm.reverse( result.dup ) ) );
				if( Algorithm.count( result, "import " ) > 0 ) return true;
				if( Algorithm.count( result, "import\t" ) > 0 ) return true;
			}
			catch( Exception e )
			{
				debug IupMessage( "AutoComplete.checkIscludeDeclare() Error", toStringz( e.toString ) );
			}

			return false;
		}
		
		static string includeComplete( Ihandle* iupSci, int pos, ref string text )
		{
			if( !text.length )  return null;
			
			dstring word32;
			string	word = text;
			bool	bExitLoopFlag;		
			
			if( text != "." && ( fromStringz( IupGetAttribute( iupSci, "AUTOCACTIVE\0" ) ) == "YES" ) ) return null;

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
							dstring sd = UTF.toUTF32( _s );
							dchar s = sd[0];
							switch( s )
							{
								case ' ', '\t', ';', '\n', '\r':		bExitLoopFlag = true; break;
								default: 
									if( UTF.isValidDchar( s ) )
									{
										word32 = "";
										word32 ~= s;
										word ~= strip( UTF.toUTF8( word32 ) );
									}
							}
						}
					}
					
					if( bExitLoopFlag ) break;
				}
				if( !word.length ) return null; else word = Algorithm.reverse( word.dup );
				
				string[]	words = Array.split( word, "." );
				string[]	tempList;

				if( !words.length ) return null;
				
				if( words.length == 1 && (text == "." ) ) words ~= "";
				
				// Step 1: Relative from the directory of the source file
				string		_path1;
				string[] 	_path2, _path3;
				/+
				this is includeComplete, so base on document fullpath
				+/
				auto cSci = ScintillaAction.getCScintilla( iupSci ); 
				if( cSci !is null ) _path1 = Path.dirName( cSci.getFullPath );

				// Step 2:  Default *.ini DFLAGS
				// Step 3: Relative from addition directories specified with the -i command line option
				// Work on Project
				_path2 = GLOBAL.compilerSettings.activeCompiler.IncDir.dup;
				
				int index;
				for( int i = 0; i < words.length; ++ i )
				{
					if( i == words.length - 1 )
					{
						// Step 1: Relative from the directory of the source file
						if( std.file.exists( _path1 ) )
						{
							foreach( string _fp; dirEntries( _path1, SpanMode.shallow ) )
							{
								if( std.file.isDir( _fp ) )
									tempList ~= Path.baseName( _fp );
								else
								{
									if( tools.isParsableExt( Path.extension( _fp ), 3 ) ) tempList ~= Path.baseName( _fp );
								}
							}
						}
						
						// Step 2:  Default *.ini DFLAGS
						// Step 3: Relative from addition directories specified with the -i command line option
						foreach( _fp2; _path2 )
						{
							if( std.file.exists( _fp2 ) )
							{
								foreach( string _fp; dirEntries( _fp2, SpanMode.shallow ) )
								{
									if( std.file.isDir( _fp ) )
										tempList ~= Path.baseName( _fp );
									else
									{
										if( tools.isParsableExt( Path.extension( _fp ), 3 ) ) tempList ~= Path.baseName( _fp );
									}
								}
							}
						}
					}
					else
					{
						_path1 = _path1 ~ "/" ~ words[i];
						for( int j = 0; j < _path2.length; ++ j )
							_path2[j] = _path2[j] ~ "/" ~ words[i];
					}
				}

				foreach( string s; tempList )
				{
					if( s.length )
					{
						string iconNum = "37";
						
						if( s.length > 2 )
						{
							if( Uni.toLower( s[$-2..$] ) == ".d" )
							{
								iconNum = "35";
								s = s[0..$-2];
							}
						}
						
						if( s.length > 3 )
						{
							if( Uni.toLower( s[$-3..$] ) == ".di" )
							{
								iconNum = "36";
								s = s[0..$-3];
							}
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
			}
			
			return null;
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
		

		static CASTnode[] getIncludes( CASTnode originalNode, string cwdPath = null, bool bRootCall = false, bool bCheckOnlyOnce = false )
		{
			CASTnode[] results;
			
			if( originalNode is null ) return null;

			if( !cwdPath.length )
			{
				cwdPath = getMotherPath_D_MODULE( originalNode, true );
				/+
				auto headNode = originalNode;
				while( headNode.getFather !is null )
					headNode = headNode.getFather;
				
				if( headNode.kind & D_MODULE )
				{
					int dotCount = Util.count( headNode.name, "." );
					scope cwdFilePath = new FilePath( headNode.type );

					//IupSetAttribute( GLOBAL.outputPanel, "APPEND", toStringz( "D_MODULE Name: [" ~ originalNode.name ~ "]"  ) );

					cwdPath = cwdFilePath.path();
					for( int i = 0; i < dotCount; ++ i )
					{
						cwdFilePath.set( cwdPath );
						cwdPath = cwdFilePath.parent();
					}

					if( cwdPath.length )
						if( cwdPath[$-1] != '/' ) cwdPath ~= '/';

					//IupSetAttribute( GLOBAL.outputPanel, "APPEND", toStringz( "cwdPath Name: [" ~ cwdPath ~ "]"  ) );
				}
				+/
			}
			else
			{
				cwdPath = Path.dirName( cwdPath );
			}

			foreach( CASTnode _node; getMembers( originalNode ) )
			{
				if( _node.kind & D_IMPORT )
				{
					//IupMessage( "D_IMPORT", toStringz( _node.name ));
					//IupMessage( "cwdPath", toStringz( cwdPath ));
					if( bRootCall )
					{
						if( _node.type.length ) results ~= check( _node.type, cwdPath, bCheckOnlyOnce ); else results ~= check( _node.name, cwdPath, bCheckOnlyOnce );
					}
					else
					{
						if( _node.protection == "public" )
						{
							if( _node.type.length ) results ~= check( _node.type, cwdPath, bCheckOnlyOnce ); else results ~= check( _node.name, cwdPath, bCheckOnlyOnce );
						}
					}
				}
			}

			return results;
		}
		

		/*	direct = 0 findprev, direct = 1 findnext
			SCFIND_WHOLEWORD = 2,
			SCFIND_MATCHCASE = 4,
		*/
		static int skipCommentAndString(  Ihandle* iupSci, int pos, string targetText, int direct,int flag = 2 )
		{
			IupScintillaSendMessage( iupSci, 2198, flag, 0 );						// SCI_SETSEARCHFLAGS = 2198,
			int documentLength = cast(int) IupScintillaSendMessage( iupSci, 2006, 0, 0 );		// SCI_GETLENGTH = 2006,

			if( direct == 0 ) // UP
			{
				IupScintillaSendMessage( iupSci, 2190, pos, 0 );
				IupScintillaSendMessage( iupSci, 2192, 0, 0 );							// SCI_SETTARGETEND = 2192,
			}
			else // DOWN
			{
				IupScintillaSendMessage( iupSci, 2190, pos, 0 );
				IupScintillaSendMessage( iupSci, 2192, documentLength - 1, 0 );			// SCI_SETTARGETEND = 2192,
			}
			
			scope _t = new IupString( targetText );
			
			pos = cast(int) IupScintillaSendMessage( iupSci, 2197, cast(size_t) targetText.length, cast(ptrdiff_t) _t.toCString );
			
			while( pos > -1 )
			{
				int style = cast(int) IupScintillaSendMessage( iupSci, 2010, pos, 0 ); // SCI_GETSTYLEAT 2010
				if( style == 1 || style == 2 || style == 3 || style == 4 || style == 10 || style == 12 )
				{
					if( direct == 0 )
					{
						IupScintillaSendMessage( iupSci, 2190, pos - 1, 0 );
						IupScintillaSendMessage( iupSci, 2192, 0, 0 );							// SCI_SETTARGETEND = 2192,
						pos = cast(int) IupScintillaSendMessage( iupSci, 2197, cast(size_t) targetText.length, cast(ptrdiff_t) _t.toCString );
					}
					else
					{
						IupScintillaSendMessage( iupSci, 2190, pos + cast(ptrdiff_t) targetText.length, 0 );
						IupScintillaSendMessage( iupSci, 2192, documentLength - 1, 0 );							// SCI_SETTARGETEND = 2192,
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
			bool	bForntEnd, bBackEnd;
			int		documentLength = IupGetInt( iupSci, "COUNT" );

			do
			{
				if( !actionManager.ScintillaAction.isComment( iupSci, pos ) )
				{
					string s = fSTRz( IupGetAttributeId( iupSci, "CHAR", pos ) );

					switch( s )
					{
						case "(", ")", "[", "]", "{", "}":
						case ".":
						case " ", "\t", ":", ";", "\n", "\r", "+", "-", "*", "/", "\\", ">", "<", "=", ",", "!":
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
			

			countParen = 0;
			countBracket = 0;
			

			dstring word32;
			string	word;
			try
			{
				while( pos > -1 )
				{
					--pos;
					if( pos < 0 ) break;
					
					if( !actionManager.ScintillaAction.isComment( iupSci, pos ) )
					{
						string _s = fromStringz( IupGetAttributeId( iupSci, "CHAR", pos ) ).dup;
						if( _s.length )
						{
							dstring sd = UTF.toUTF32( _s );
							dchar s = sd[0];
							switch( s )
							{
								case ')':
									if( countBracket == 0 )
									{
										if( countParen == 0 )
										{
											if( pos < IupGetInt( iupSci, "COUNT" ) - 1 )
											{
												string prevs = fromStringz( IupGetAttributeId( iupSci, "CHAR", pos + 1 ) ).dup;
												if( prevs.length )
												{
													if( prevs[0] == '_' || prevs[0] == '*' || ( prevs[0] >= 'A' && prevs[0] <= 'Z' ) || ( prevs[0] >= 'a' && prevs[0] <= 'z' ) ) return word;
												}
											}
											else
											{
												return word;
											}
										}
										countParen++;
									}
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

								case '\n', '\r':
									if( !actionManager.ScintillaAction.isComment( iupSci, pos ) ) return word;
									goto case;
									
								case ' ', '\t', ':', ';', '+', '-', '*', '/', '<', '>', ',', '=', '&':
									if( countParen == 0 && countBracket == 0 ) return word;
									goto default;
									
								case '.':
									if( pos > 0 )
									{
										if( countBracket == 0 )
											if( fSTRz( IupGetAttributeId( iupSci, "CHAR", pos - 1 ) ) == "." ) return word;
									}
									goto default;
									
								default: 
									if( countParen == 0 && countBracket == 0 )
									{
										if( UTF.isValidDchar( s ) )
										{
											word32 = "";
											word32 ~= s;
											word ~= strip( UTF.toUTF8( word32 ) );
										}
									}
							}
						}
					}
				}
				
			}
			catch( Exception e )
			{
				return null;
			}			
			
			return word;
			/*
			int dummyHeadPos;
			return getWholeWordReverse( iupSci, pos, dummyHeadPos );
			*/
		}

		// For Goto Defintion Using
		static string checkIsInclude( Ihandle* iupSci, int pos = -1 )
		{
			string	result;
			int		documentLength = IupGetInt( iupSci, "COUNT" ), fullStringPos, fullStringEndPos, moduleStartPos, oriPos = pos;
			
			do
			{
				string s = fSTRz( IupGetAttributeId( iupSci, "CHAR", pos ) );
				if( s == ";" || s == "," ) break;
			}
			while( ++pos < documentLength );
			
			--pos;
			fullStringEndPos = fullStringPos = pos;

			do
			{
				string s = fSTRz( IupGetAttributeId( iupSci, "CHAR", pos ) );
				if( s == ";" || s == "{" || s == "{" || s == "," || s =="=" ) break;
			}
			while( --pos >= 0 );
			
			moduleStartPos = pos;

			do
			{
				string s = fSTRz( IupGetAttributeId( iupSci, "CHAR", fullStringPos ) );
				if( s == ";" || s == "{" || s == "{" ) break;
			}
			while( --fullStringPos >= 0 );
			
			int importPos = skipCommentAndString( iupSci, fullStringEndPos, "import", 0 );
			if( importPos < fullStringPos )
			{
				//IupMessage("fullStringEndPos",toStringz("NON IMPORT") );
				return null;
			}
			else
			{
				if ( moduleStartPos < importPos ) moduleStartPos = importPos + 6;
				do
				{
					string s = fSTRz( IupGetAttributeId( iupSci, "CHAR", importPos ) );
					if( s != " " && s != "\t" ) break;
				}
				while( ++moduleStartPos < documentLength );		
				
				if( oriPos > moduleStartPos && oriPos < fullStringEndPos )
				{
					for( int i = moduleStartPos +1 ; i <= fullStringEndPos; ++ i )
					{
						result ~= fromStringz( IupGetAttributeId( iupSci, "CHAR", i ) );
					}
					return strip( result );
				}
			}
			
			return result;
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
								case "(", ")", "[", "]", "{", "}":																	return startPos;
								case " ", "\t", ":", ";", ",", ".", "\n", "\r", "+", "-", "*", "/", "\\", "<", ">", "=", "&":		return startPos;
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
		
		static string getWholeWordReverse( Ihandle* iupSci, int pos, out int headPos )
		{
			dstring word32;
			string	word;
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
						string _s = fromStringz( IupGetAttributeId( iupSci, "CHAR", pos ) ).dup;
						if( _s.length )
						{
							dstring sd = UTF.toUTF32( _s );
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

								case '\n', '\r':
									if( !actionManager.ScintillaAction.isComment( iupSci, pos ) ) return word;
									goto case;
									
								case ' ', '\t', ':', ';', '+', '-', '*', '/', '<', '>', ',', '=', '&':
									if( countParen == 0 && countBracket == 0 ) return word;
									goto default;
									
								case '.':
									if( pos > 0 )
									{
										if( countBracket == 0 )
											if( fSTRz( IupGetAttributeId( iupSci, "CHAR", pos - 1 ) ) == "." ) return word;
									}
									goto default;
									
								default: 
									if( countParen == 0 && countBracket == 0 )
									{
										if( UTF.isValidDchar( s ) )
										{
											word32 = "";
											word32 ~= s;
											word ~= strip( UTF.toUTF8( word32 ) );
											//word ~= s;
										}
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

		static string getWholeWordReverseWithBracket( Ihandle* iupSci, int pos, out int headPos )
		{
			dstring word32;
			string	word;
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
						string _s = fromStringz( IupGetAttributeId( iupSci, "CHAR", pos ) ).dup;
						if( _s.length )
						{
							dstring sd = UTF.toUTF32( _s );
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
									if( countParen == 0 )
									{
										if( countBracket == 0 ) word ~= "]";
										countBracket++;
									}
									break;

								case '[':
									if( countParen == 0 )
									{
										countBracket--;
										if( countBracket == 0 ) word ~= "[";
									}
									if( countBracket < 0 ) return word;
									break;

								case '\n', '\r':
									if( !actionManager.ScintillaAction.isComment( iupSci, pos ) ) return word;
									goto case;
									
								case ' ', '\t', ':', ';', '+', '-', '*', '/', '<', '>', ',', '=', '&':
									if( countParen == 0 && countBracket == 0 ) return word;
									goto default;
									
								case '.':
									if( pos > 0 )
									{
										if( countBracket == 0 )
											if( fSTRz( IupGetAttributeId( iupSci, "CHAR", pos - 1 ) ) == "." ) return word;
									}
									goto default;
									
								default: 
									if( countParen == 0 && countBracket == 0 )
									{
										if( UTF.isValidDchar( s ) )
										{
											word32 = "";
											word32 ~= s;
											word ~= strip( UTF.toUTF8( word32 ) );
											//word ~= s;
										}
									}
							}
						}
					}
				}
				
			}
			catch( Exception e )
			{
				return null;
			}

			return word;
		}
		

		static string charAdd( Ihandle* iupSci, int pos = -1, string text = "", bool bForce = false )
		{
			int		dummyHeadPos;
			string 	word, result;
			bool	bDot, bCallTip;

			if( text == "(" )
			{
				bCallTip = true;
				IupSetAttribute( iupSci, "AUTOCCANCEL", "YES" ); // Prevent autocomplete -> calltip issue
			}
			else if( text == "." )
			{
				bDot = true;
			}
			else
			{
				word = text;
			}

			//word = word ~ getWholeWordReverse( iupSci, pos, dummyHeadPos );
			word = word ~ getWholeWordReverseWithBracket( iupSci, pos, dummyHeadPos ); // Keep With []
			word = Algorithm.reverse( word.dup );

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

					string[]		splitWord = getDivideWord( word );
					int				lineNum = cast(int) IupScintillaSendMessage( iupSci, 2166, pos, 0 ) + 1; //SCI_LINEFROMPOSITION = 2166,
					CASTnode		AST_Head = ParserAction.getActiveASTFromLine( ParserAction.getActiveParseAST(), lineNum );
					string			memberFunctionMotherName;
					
					nowLineAst = cast(shared CASTnode) AST_Head;
					nowLineNum = lineNum;					

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
					
					result = analysisSplitWorld_ReturnCompleteList( AST_Head, splitWord, ScintillaAction.getLinefromPos( iupSci, pos ) , bDot, bCallTip, true );

					if( listContainer.length )
					{
						Algorithm.sort!("toUpper(a) < toUpper(b)", SwapStrategy.stable)( listContainer );

						string	_type, _list;
						int		maxLeft, maxRight;

						for( int i = 0; i < listContainer.length; ++ i )
						{
							if( listContainer[i].length )
							{
								auto dollarPos = lastIndexOf( listContainer[i], "#" );
								if( dollarPos < -1 )
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

						string formatString = "{,-" ~ Conv.to!(string)( maxLeft ) ~ "} :: {,-" ~ Conv.to!(string)( maxRight ) ~ "}";
						
						for( int i = 0; i < listContainer.length; ++ i )
						{
							if( i > 0 )
								if( listContainer[i] == listContainer[i-1] ) continue;

							if( listContainer[i].length )
							{
								string _string;
								
								auto dollarPos = lastIndexOf( listContainer[i], "#" );
								if( dollarPos > -1 )
								{
									_type = listContainer[i][dollarPos+1..$];
									_list = listContainer[i][0..dollarPos];
									_string = stripRight( format( "%-" ~ Conv.to!(string)(maxLeft) ~ "s :: %-" ~ Conv.to!(string)(maxRight) ~ "s", _list, _type ) );
								}
								else
								{
									_string = listContainer[i];
								}

								result ~= ( _string ~ "^" );
							}
						}
					}
				}

				if( result.length )
					if( result[$-1] == '^' ) result = result[0..$-1];

				return result;
			}

			return null;
		}

		static void toDefintionAndType( int runType )
		{
			if( GLOBAL.enableParser != "ON" ) return;
			
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
				string word;
				
				auto cSci = actionManager.ScintillaAction.getActiveCScintilla();
				if( cSci !is null )
				{
					int currentPos = actionManager.ScintillaAction.getCurrentPos( cSci.getIupScintilla );
					if( currentPos < 1 ) return;
					
					word = getWholeWordDoubleSide( cSci.getIupScintilla, currentPos );
					if( !word.length ) return;
					word = Algorithm.reverse( word.dup );
					
					string[] splitWord = getDivideWord( word );

					int				lineNum = cast(int) IupScintillaSendMessage( cSci.getIupScintilla, 2166, currentPos, 0 ) + 1; //SCI_LINEFROMPOSITION = 2166,
					CASTnode		AST_Head = ParserAction.getActiveASTFromLine( ParserAction.getActiveParseAST(), lineNum );

					if( AST_Head is null ) return;
					/+
					// Reset VersionCondition Container
					foreach( string key; ( cast(int[string]) VersionCondition ).keys )
						VersionCondition.remove( key );
					
					string options = GLOBAL.compilerSettings.activeCompiler.Option.dup;
					if( options.length )
					{
						auto _versionPos =indexOf( options, "-version=" );
						while( _versionPos > -1 )
						{
							string versionName;
							for( int i = cast(int) _versionPos + 9; i < options.length; ++ i )
							{
								if( options[i] == '\t' || options[i] == ' ' ) break;
								versionName ~= options[i];
							}							
							if( versionName.length ) AutoComplete.VersionCondition[versionName] = 1;
							
							_versionPos = indexOf( options, "-version=", _versionPos + 9 );
						}
					}
					+/

					// Goto Import Modules
					if( runType > 0 )
					{
						string _string = checkIsInclude( cSci.getIupScintilla, currentPos );
						if( _string.length )
						{
							// Get cwd
							string cwdPath = getMotherPath_D_MODULE( AST_Head, true );
							
							/+
							auto headNode = AST_Head;
							while( headNode.getFather !is null )
								headNode = headNode.getFather;
								
							if( headNode.kind & D_MODULE )
							{
								int dotCount = Util.count( headNode.name, "." );
								scope cwdFilePath = new FilePath( headNode.type );

								cwdPath = cwdFilePath.path();
								for( int i = 0; i < dotCount; ++ i )
								{
									cwdFilePath.set( cwdPath );
									cwdPath = cwdFilePath.parent();
								}

								if( cwdPath.length )
									if( cwdPath[$-1] != '/' ) cwdPath ~= '/';
							}
							+/
							
							string fullPath = checkIncludeExist( _string, cwdPath );
							if( fullPath.length )
							{
								if( GLOBAL.navigation.addCache( fullPath, 1 ) ) actionManager.ScintillaAction.openFile( fullPath );
								return;
							}
						}
					}

					CASTnode	firstASTNode, finalASTNode, _sub_ori_AST_Head = AST_Head;
					string		_list;
					bool		bIsModuleCheck;
				
					for( int i = 0; i < splitWord.length; i++ )
					{
						if( i == 0 )
						{
							AST_Head = searchMatchNode( AST_Head, stripLeft( ParserAction.removeArrayAndPointer( splitWord[i] ), "&" ), D_FIND | D_ENUMMEMBER ); // NOTE!!!! Using "searchMatchNode()"
							
							if( AST_Head is null ) AST_Head = searchObjectModule( splitWord[i], D_FIND );
							
							if( AST_Head is null )
							{
								// Check Module
								AST_Head = importComplete( _sub_ori_AST_Head, lineNum, 0, splitWord, 0 );
								if( AST_Head is null )
								{
									CASTnode[]	resultNodes;
									resultNodes = getMatchASTfromWord( _sub_ori_AST_Head, splitWord[0], lineNum, D_IMPORT );
									if( !resultNodes.length )
									{
										resultNodes	= getMatchIncludesFromWord( _sub_ori_AST_Head, null, splitWord[0], false, D_MODULE );
										if( resultNodes.length )
										{
											AST_Head = _sub_ori_AST_Head;
											bIsModuleCheck = true;
										}
										else
										{
											return;
										}
									}
									else
									{
										AST_Head = _sub_ori_AST_Head;
										bIsModuleCheck = true;
									}
									continue;
								}
							}
							
							if( AST_Head is null ) break;

							firstASTNode = AST_Head;

							if( AST_Head.kind & ( D_VARIABLE | D_PARAM | D_FUNCTION | D_ALIAS | D_FUNCTIONPTR ) )
							{
								if( !isDefaultType( ParserAction.getSeparateType( AST_Head.type, true ) ) )
								{
									AST_Head = getType( AST_Head, lineNum );
									if( AST_Head is null )
									{
										finalASTNode = null;
									}
									else
									{
										finalASTNode = AST_Head;
									}
								}
								else
								{
									finalASTNode = null;
								}
							}
							else if( AST_Head.kind & ( D_ENUMMEMBER ) )
							{
								finalASTNode = AST_Head.getFather;
							}

							if( splitWord.length == 1 ) break;
						}
						else
						{
							if( AST_Head !is null )
							{
								if( bIsModuleCheck )
								{
									string _moduleName = splitWord[0];

									// Combine splitWord[0..i]	
									for( int j = 1; j <= i; j++ )
										_moduleName ~= ( "." ~ splitWord[j] );
									
									AST_Head = searchMatchNode( AST_Head, _moduleName, D_MODULE );
									if( AST_Head is null )
									{
										CASTnode[]	resultNodes;
										resultNodes = getMatchASTfromWord( _sub_ori_AST_Head, _moduleName, lineNum, D_IMPORT );
										if( !resultNodes.length )
										{
											resultNodes	= getMatchIncludesFromWord( _sub_ori_AST_Head, null, _moduleName, false, D_MODULE );
											if( resultNodes.length )
											{
												AST_Head = _sub_ori_AST_Head;
											}
											else
											{
												return;
											}
										}
										else
										{
											AST_Head = _sub_ori_AST_Head;
										}
									}
									else
									{
										firstASTNode = AST_Head;
										bIsModuleCheck = false;
									}

									continue;
								}
							
								AST_Head = searchMatchMemberNode( AST_Head, ParserAction.removeArrayAndPointer( splitWord[i] ), D_FIND | D_ENUMMEMBER );
								
								if( AST_Head is null ) return;

								firstASTNode = AST_Head;

								if( AST_Head.kind & ( D_VARIABLE | D_PARAM | D_FUNCTION | D_ALIAS | D_FUNCTIONPTR ) )
								{
									if( !isDefaultType( ParserAction.getSeparateType( AST_Head.type, true ) ) )
									{
										AST_Head = getType( AST_Head, lineNum );
										if( AST_Head is null )
										{
											finalASTNode = null;
										}
										else
										{
											finalASTNode = AST_Head;
										}
									}
									else
									{
										finalASTNode = null;
									}
								}
								else if( AST_Head.kind & ( D_ENUMMEMBER ) )
								{
									finalASTNode = AST_Head.getFather;
								}
							}
						}
					}

					if( runType == 0 )
					{
						
						string	_type, _param;
						int		topLayerStartPos = -1;

						if( firstASTNode !is null )
						{
							ParserAction.getSplitDataFromNodeTypeString( firstASTNode.type, _type, _param );
							if( GLOBAL.showTypeWithParams != "ON" ) _param = "";
							switch( firstASTNode.kind )
							{
								case D_MODULE: _type = "\"MODULE\""; break;
								case D_INTERFACE: _type = "\"INTERFACE\""; break;
								case D_TEMPLATE: _type = "\"TEMPLATE\""; break;
								case D_STRUCT: _type = "\"STRUCT\""; break;
								case D_CLASS: _type = "\"CLASS\""; break;
								case D_UNION: _type = "\"UNION\""; break;
								case D_ENUM: _type = "\"ENUM\""; break;
								case D_ENUMMEMBER: _type = "\"ENUMMEMBER\""; break;
								case D_FUNCTION: _type = "\"FUNCTION\""; break;
								case D_VARIABLE: if( !firstASTNode.type.length && firstASTNode.base.length ) _type = "\"AUTO\""; break;
								default:
							}

							if( firstASTNode.kind & ( D_CLASS | D_TEMPLATE | D_INTERFACE ) )
							{
								_list = ( "1st Layer = " ~ ( _type.length ? _type ~ " " : null ) ~ firstASTNode.name ~ ( firstASTNode.base.length ? " : " ~ firstASTNode.base : "" ) );
								_list ~= getShowTypeCTORList( firstASTNode );
							}
							else if( firstASTNode.kind & D_FUNCTION )
							{
								_list = ( "1st Layer = " ~ ( _type.length ? _type ~ " " : null ) );
								_list ~= getShowTypeCTORList( firstASTNode );
							}
							else if( firstASTNode.kind & D_MODULE )
							{
								_list  = ( "1st Layer = " ~ ( _type.length ? _type ~ " " : null ) ~ firstASTNode.name ~ _param );
								_list ~= "\n";
								topLayerStartPos = cast(int) _list.length;
								_list ~= ( "File Path = " ~ firstASTNode.type );
							}
							else
							{
								_list = ( "1st Layer = " ~ ( _type.length ? _type ~ " " : null ) ~ firstASTNode.name ~ _param );
							}
						}

						
						if( finalASTNode !is null )
						{
							ParserAction.getSplitDataFromNodeTypeString( finalASTNode.type, _type, _param );
							if( GLOBAL.showTypeWithParams != "ON" ) _param = "";
							switch( finalASTNode.kind )
							{
								case D_MODULE: _type = "\"MODULE\""; break;
								case D_INTERFACE: _type = "\"INTERFACE\""; break;
								case D_TEMPLATE: _type = "\"TEMPLATE\""; break;
								case D_STRUCT: _type = "\"STRUCT\""; break;
								case D_CLASS: _type = "\"CLASS\""; break;
								case D_UNION: _type = "\"UNION\""; break;
								case D_ENUM: _type = "\"ENUM\""; break;
								case D_FUNCTION: _type = "\"FUNCTION\""; break;
								case D_VARIABLE: if( !finalASTNode.type.length && finalASTNode.base.length ) _type = "\"AUTO\""; break;
								default:
							}

							if( _list.length )
							{
								_list ~= "\n";
								topLayerStartPos = cast(int) _list.length;
							}
							
							if( finalASTNode.kind & ( D_CLASS | D_TEMPLATE | D_INTERFACE ) )
							{
								_list ~= ( "Top Layer = " ~ ( _type.length ? _type ~ " " : null ) ~ finalASTNode.name ~ ( finalASTNode.base.length ? " : " ~ finalASTNode.base : "" ) );
								_list ~= getShowTypeCTORList( finalASTNode, firstASTNode.kind & ( D_CLASS | D_TEMPLATE | D_INTERFACE ) ? true : false );
							}
							else if( finalASTNode.kind & D_FUNCTION )
							{
								_list ~= ( "Top Layer = " ~ ( _type.length ? _type ~ " " : null ) );
								_list ~= getShowTypeCTORList( finalASTNode, firstASTNode.kind & ( D_CLASS | D_TEMPLATE | D_INTERFACE ) ? true : false );
							}
							else
							{
								_list ~= ( "Top Layer = " ~ ( _type.length ? _type ~ " " : null ) ~ finalASTNode.name ~ _param );
							}
						}
						
						if( _list.length )
						{
							showTypeContent = _list;
							scope _result = new IupString( showTypeContent );
							cleanCalltipContainer(); // Clear Call Tip Container						
							IupScintillaSendMessage( cSci.getIupScintilla, 2206, cast(size_t) tools.convertIupColor( GLOBAL.editColor.showTypeFore ), 0 ); //SCI_CALLTIPSETFORE 2206
							IupScintillaSendMessage( cSci.getIupScintilla, 2205, cast(size_t) tools.convertIupColor( GLOBAL.editColor.showTypeBack ), 0 ); //SCI_CALLTIPSETBACK 2205
							IupScintillaSendMessage( cSci.getIupScintilla, 2200, currentPos, cast(ptrdiff_t) _result.toCString ); // SCI_CALLTIPSHOW 2200

							
							if( topLayerStartPos > -1 )
							{
								IupScintillaSendMessage( cSci.getIupScintilla, 2204, topLayerStartPos, cast(ptrdiff_t) _list.length ); // SCI_CALLTIPSETHLT 2204
								IupScintillaSendMessage( cSci.getIupScintilla, 2207, cast(size_t) tools.convertIupColor( GLOBAL.editColor.showTypeHLT ), 0 ); // SCI_CALLTIPSETFOREHLT 2207
							}
							else
							{
								IupScintillaSendMessage( cSci.getIupScintilla, 2204, 0, -1 ); // SCI_CALLTIPSETHLT 2204
							}
						}
					}
					else
					{
						CASTnode runTypeNode;

						if( runType == 1 ) runTypeNode = firstASTNode; else runTypeNode = finalASTNode;
				
						if( runTypeNode !is null )
						{
							lineNum = runTypeNode.lineNumber;
							
							while( runTypeNode.getFather() !is null )
							{
								runTypeNode = runTypeNode.getFather();
							}

							if( GLOBAL.navigation.addCache( runTypeNode.type, lineNum ) ) actionManager.ScintillaAction.openFile( runTypeNode.type, lineNum );
						}
					}
				}
			}
			catch( Exception e )
			{
				//IupMessage( "Error", toStringz( e.toString ) );
			}
		}
		
		
		static bool callAutocomplete( Ihandle *ih, int pos, string text, string alreadyInput, bool bForce = false )
		{
			if( preLoadContainerThread !is null )
			{
				if( preLoadContainerThread.isRunning )
					preLoadContainerThread.join();
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

							try
							{
								if( showCallTipThread !is null )
									if( showCallTipThread.isRunning ) showCallTipThread.join();
							}
							catch( Exception e ){}
							
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
						scope _result = new IupString( list );
						IupScintillaSendMessage( ih, 2200, pos, cast(ptrdiff_t) _result.toCString );
						IupScintillaSendMessage( ih, 2207, cast(size_t) tools.convertIupColor( GLOBAL.editColor.callTipHLT ), 0 ); // SCI_CALLTIPSETFOREHLT 2207
						
						//if( calltipContainer !is null )	calltipContainer.push( Conv.to!(string)( ScintillaAction.getLinefromPos( ih, pos ) ) ~ ";" ~ list );
						calltipContainer.push( Conv.to!(string)( ScintillaAction.getLinefromPos( ih, pos ) ) ~ ";" ~ list );
						
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
			
			if( fromStringz( IupGetAttribute( ih, "AUTOCACTIVE" ) ) == "YES" ) // Complete List already showed
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
			else
			{
				if( cast(int) IupScintillaSendMessage( ih, 2202, 0, 0 ) == 1 ) // Calltip already showed
				{
					if( singleWord != null )
					{
						string s = fSTRz( singleWord );
						if( s == ")" ) IupScintillaSendMessage( ih, 2201, 0, 0 ); //  SCI_CALLTIPCANCEL 2201 , SCI_CALLTIPACTIVE 2202
					}
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
				/*
				string	listInContainer = calltipContainer.top();
				if( listInContainer.length )
				{
					int semicolonPos = Util.index( listInContainer, ";" );
					if( semicolonPos < listInContainer.length )
					{
						lineNumber = Integer.toInt( listInContainer[0..semicolonPos] );
						if( ScintillaAction.getCurrentLine( ih ) != lineNumber + 1 ) cleanCalltipContainer();
					}
				}
				*/
				LineHeadText = _getLineHeadText( pos - 1, s );
			}

			string	procedureNameFromDocument = parseProcedureForCalltip( ih, lineHeadPos, LineHeadText, commaCount, parenCount, firstOpenParenPosFromDocument ); // from document
			//string	procedureNameFromDocument = AutoComplete.parseProcedureForCalltip( ih, pos, commaCount, parenCount, firstOpenParenPosFromDocument ); // from document

			if( commaCount == 0 )
			{
				calltipContainer.pop();
				if( cast(int) IupScintillaSendMessage( ih, 2202, 0, 0 ) == 1 ) IupScintillaSendMessage( ih, 2201, 0, 0 ); //  SCI_CALLTIPCANCEL 2201 , SCI_CALLTIPACTIVE 2202
				return false;
			}



			// Last time we get null "List" at same line and same procedureNameFromDocument, leave!!!!!
			if( noneListProcedureName == Conv.to!(string)( firstOpenParenPosFromDocument ) ~ ";" ~ procedureNameFromDocument ) return false;
	
	
	
			string	list;
			string	listInContainer = calltipContainer.top();
			
			if( listInContainer.length )
			{
				auto semicolonPos = indexOf( listInContainer, ";" );
				if( semicolonPos > -1 )
				{
					lineNumber = Conv.to!(int)( listInContainer[0..semicolonPos] );
					if( currentLn == lineNumber )
					{
						auto openParenPos = indexOf( listInContainer, "(" );
						if( openParenPos > semicolonPos )
						{
							//string procedureNameFromList;
							for( int i = cast(int) openParenPos - 1; i > semicolonPos; -- i )
							{
								if( listInContainer[i] == ' ' ) break;
								procedureNameFromList = listInContainer[i] ~ procedureNameFromList;
							}
							
							version(FBIDE)
							{
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
							version(DIDE)
							{
								auto doubleColonPos = lastIndexOf( procedureNameFromList, "::this" );
								if( doubleColonPos > -1 )
								{
									if( procedureNameFromDocument != "this" )
									{
										if( doubleColonPos > 0 )
										{
											if( procedureNameFromList[0..doubleColonPos] == procedureNameFromDocument )
											{
												bContinue = true;
												list = listInContainer[semicolonPos+1..$].dup;
											}
										}
									}
									else
									{
										bContinue = true;
										list = listInContainer[semicolonPos+1..$].dup;
									}									
								}
								else
								{
									if( procedureNameFromList == procedureNameFromDocument )
									{
										bContinue = true;
										list = listInContainer[semicolonPos+1..$].dup;
									}
								}
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
								catch( Exception e ){}

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
					list = charAdd( ih, firstOpenParenPosFromDocument, "(", true );
					if( list.length )
					{
						bContinue = true;
						calltipContainer.push( Conv.to!(string)( ScintillaAction.getLinefromPos( ih, pos ) ) ~ ";" ~ list );
					}
				}
			}
			
			if( !bContinue )
			{
				if( calltipContainer.size > 1 )
				{
					calltipContainer.pop();
					list = calltipContainer.top;
					if( list.length )
					{
						auto semicolonPos = indexOf( list, ";" );
						if( semicolonPos > -1 )
						{
							list = list[semicolonPos+1..$].dup;
							bContinue = true;
						}
					}
				}
			}
			
			
			if( !bContinue )
			{
				if( calltipContainer.size > 0 )
				{
					calltipContainer.clear();
					//if( cast(int) IupScintillaSendMessage( ih, 2202, 0, 0 ) == 1 ) IupScintillaSendMessage( ih, 2201, 1, 0 ); //  SCI_CALLTIPCANCEL 2201 , SCI_CALLTIPACTIVE 2202
				}
					
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
						scope _result = new IupString( list );
						IupScintillaSendMessage( ih, 2200, pos, cast(ptrdiff_t) _result.toCString );
						IupScintillaSendMessage( ih, 2207, cast(size_t) tools.convertIupColor( GLOBAL.editColor.callTipHLT ), 0 ); // SCI_CALLTIPSETFOREHLT 2207
						
						calltipContainer.push( Conv.to!(string)( ScintillaAction.getLinefromPos( ih, pos ) ) ~ ";" ~ list );
					}
				
					if( cast(int) IupScintillaSendMessage( ih, 2202, 0, 0 ) == 1 ) // CallTip be Showed
					{
						int highlightStart, highlightEnd;
						callTipSetHLT( list, commaCount, highlightStart, highlightEnd );

						if( highlightEnd > -1 )
						{
							IupScintillaSendMessage( ih, 2204, highlightStart, highlightEnd ); // SCI_CALLTIPSETHLT 2204
							return true;
						}
						else
						{
							// Clean the Hight-light
							IupScintillaSendMessage( ih, 2204, 0, -1 ); // SCI_CALLTIPSETHLT 2204
							if( cast(int) IupScintillaSendMessage( ih, 2202, 0, 0 ) == 1 ) IupScintillaSendMessage( ih, 2201, 0, 0 ); //  SCI_CALLTIPCANCEL 2201 , SCI_CALLTIPACTIVE 2202
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
		bool bShowListTrigger;
		
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
							
							string	lastChar = fSTRz( IupGetAttributeId( sci, "CHAR", _pos - 1 ) );

							string	_alreadyInput = Algorithm.reverse( AutoComplete.getWholeWordReverse( sci, _pos, dummyHeadPos ).dup );
							if( _alreadyInput.length )
							{
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

								bShowListTrigger = true;
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
							
							//if( cast(int) IupScintillaSendMessage( sci, 2202, 0, 0 ) == 1 ) IupScintillaSendMessage( sci, 2201, 0, 0 ); //  SCI_CALLTIPCANCEL 2201 , SCI_CALLTIPACTIVE 2202

							IupScintillaSendMessage( sci, 2205, cast(size_t) tools.convertIupColor( GLOBAL.editColor.callTipBack ), 0 ); // SCI_CALLTIPSETBACK 2205
							IupScintillaSendMessage( sci, 2206, cast(size_t) tools.convertIupColor( GLOBAL.editColor.callTipFore ), 0 ); // SCI_CALLTIPSETFORE 2206
							IupScintillaSendMessage( sci, 2207, cast(size_t) tools.convertIupColor( GLOBAL.editColor.callTipHLT ), 0 ); // SCI_CALLTIPSETFOREHLT 2207
							scope _result = new IupString( ScintillaAction.textWrap( AutoComplete.showCallTipThread.getResult ) );
							if( !bShowListTrigger ) IupScintillaSendMessage( sci, 2200, _pos, cast(ptrdiff_t) _result.toCString );
							
							AutoComplete.calltipContainer.push( Conv.to!(string)( ScintillaAction.getLinefromPos( sci, _pos ) ) ~ ";" ~ AutoComplete.showCallTipThread.getResult );
							
							if( !bShowListTrigger )
							{
								int highlightStart, highlightEnd;
								AutoComplete.callTipSetHLT( AutoComplete.showCallTipThread.getResult, AutoComplete.showCallTipThread.ext, highlightStart, highlightEnd );
								if( highlightEnd > -1 ) IupScintillaSendMessage( sci, 2204, highlightStart, highlightEnd ); // SCI_CALLTIPSETHLT 2204
							}
							
							AutoComplete.noneListProcedureName = "";
						}
					}
				}
				else
				{
					AutoComplete.noneListProcedureName = Conv.to!(string)( AutoComplete.showCallTipThread.pos ) ~ ";" ~ AutoComplete.showCallTipThread.extString;
					//AutoComplete.cleanCalltipContainer();
				}

				destroy( AutoComplete.showCallTipThread );
				AutoComplete.showCallTipThread = null;
			}
		}		
		
		if( AutoComplete.showListThread is null && AutoComplete.showCallTipThread is null )	IupSetAttribute( _ih, "RUN", "NO" );
		
		return IUP_IGNORE;
	}	
}