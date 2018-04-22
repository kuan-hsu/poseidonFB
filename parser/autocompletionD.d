module parser.autocompletionD;

version(DIDE)
{
	import iup.iup;
	import iup.iup_scintilla;

	import global, actionManager, menu;
	import tango.stdc.stringz;
	
	struct AutoComplete
	{
		private:
		import tools;
		import parser.ast;

		import Integer = tango.text.convert.Integer, Util = tango.text.Util, UTF = tango.text.convert.Utf;
		import tango.io.FilePath, tango.sys.Environment;
		import tango.io.Stdout;
		import tango.core.Thread;

		static CStack!(char[])		calltipContainer;
		static char[]				noneListProcedureName;
		
		static char[][]				listContainer;
		static CASTnode[char[]]		includesMarkContainer;
		static char[][]				VersionCondition;
		
		class CShowListThread : Thread
		{
			private:
			import scintilla;
			
			Ihandle*	sci;
			int			pos, ext;
			char[]		text, extString;
			char[]		result;
			bool		bStop;
			
			public:
			this( Ihandle* _sci, int _pos, char[] _text, int _ext = -1, char[] _extString = "" )
			{
				sci				= _sci;
				pos				= _pos;
				text			= _text.dup;
				ext				= _ext;
				extString		= _extString;
				
				super( &run );
			}

			void run()
			{
				int _delay = Integer.toInt( GLOBAL.completeDelay.toDString );
				if( _delay > 0 ) Thread.sleep( cast(float) _delay / 1000.0 );
				
				result = charAdd( sci, pos, text );
			}
			
			char[] getResult()
			{
				return result;
			}
			
			void stop()
			{
				bStop = true;
			}			
		}
		
		
		
		static CShowListThread showListThread;
		static CShowListThread showCallTipThread;
		static Ihandle* timer = null;
		
		static CASTnode importComplete( CASTnode AST_Head, int lineNum, int completeCase, char[][] splitWord, int wordIndex )
		{
			auto		cSci = actionManager.ScintillaAction.getActiveCScintilla();
			
			switch( completeCase )
			{
				case 1: // wordIndex = 0; Using word full match
					CASTnode[]	resultNodes			= getMatchASTfromWord( AST_Head, lowerCase( splitWord[0] ), lineNum, D_IMPORT );
					CASTnode[]	resultIncludeNodes	= getMatchIncludesFromWord( GLOBAL.parserManager[upperCase(cSci.getFullPath)], null, splitWord[0], false, D_IMPORT );
				
					char[][]	results;
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
							
							if( Util.index( _node.name, splitWord[0] ~ "." ) == 0 )
							{
								char[][] _nodeNames = Util.split( _node.name, "." );
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
								// Get Module AST From Import AST
								return searchMatchNode( AST_Head, _node.type, D_MODULE );
							}
						}
					}

					results.sort;

					foreach( char[] s; results )
						listContainer ~= s;

					return markNode;

				case 2: // StepByStep
					char[] combineWord;
					for( int i = 0; i <= wordIndex; ++ i )
						combineWord ~= ( splitWord[i] ~ "." );

					if( combineWord.length > 1 ) combineWord = combineWord[0..$-1];

					CASTnode	returnNode;
					CASTnode[]	resultNodes			= getMatchASTfromWord( AST_Head, lowerCase( combineWord ), lineNum, D_IMPORT );
					CASTnode[]	resultIncludeNodes	= getMatchIncludesFromWord( GLOBAL.parserManager[upperCase(cSci.getFullPath)], null, combineWord, false, D_IMPORT );
						
					foreach( CASTnode _node; resultNodes ~ resultIncludeNodes )
					{
						if( !_node.type.length )
						{
							char[][] _nodeNames = Util.split( _node.name, "." );
							
							if( _nodeNames.length == wordIndex + 1 )
							{
								if( _node.name == combineWord ) return searchMatchNode( AST_Head, _node.name, D_MODULE );
							}
							else if( _nodeNames.length > wordIndex + 1 )
							{
								if( Util.index( _node.name, combineWord ~ "." ) == 0 )
								{
									//results ~= ( _nodeNames[wordIndex+1] ~ "?22" );
									returnNode = _node;
								}			
							}
						}
					}

					return returnNode;				

				case 3: // Tail
					char[] combineWord;
					char[][] results;

					for( int i = 0; i <= wordIndex; ++ i )
						combineWord ~= ( splitWord[i] ~ "." );

					if( combineWord.length > 1 ) combineWord = combineWord[0..$-1];

					CASTnode[]	resultNodes			= getMatchASTfromWord( AST_Head, lowerCase( combineWord ), lineNum, D_IMPORT );
					CASTnode[]	resultIncludeNodes	= getMatchIncludesFromWord( GLOBAL.parserManager[upperCase(cSci.getFullPath)], null, combineWord, false, D_IMPORT );
					
					foreach( CASTnode _node; resultNodes ~ resultIncludeNodes )
					{
						if( !_node.type.length )
						{
							char[][] _nodeNames = Util.split( _node.name, "." );

							if( _nodeNames.length == wordIndex + 1 )
							{
								if( _node.name == combineWord ) return searchMatchNode( AST_Head, _node.name, D_MODULE );
							}
							else if( _nodeNames.length > wordIndex + 1 )
							{
								if( Util.index( _node.name, combineWord ~ "." ) == 0 )
								{
									listContainer ~= ( _nodeNames[wordIndex+1] ~ "?22" );
								}
							}
						}
					}
						
					break;

				case 4:

					char[] combineWord;
					for( int j = 0; j <= wordIndex; ++ j )
						combineWord ~= ( splitWord[j] ~ "." );

					if( combineWord.length > 1 ) combineWord = combineWord[0..$-1];	
					
					CASTnode[]	resultNodes			= getMatchASTfromWord( AST_Head, lowerCase( combineWord ), lineNum, D_IMPORT );
					CASTnode[]	resultIncludeNodes	= getMatchIncludesFromWord( GLOBAL.parserManager[upperCase(cSci.getFullPath)], null, combineWord, false, D_IMPORT );

					foreach( CASTnode _node; resultNodes ~ resultIncludeNodes )
					{
						if( !_node.type.length )
						{
							char[][] nodeNames = Util.split( _node.name, "." );
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
		+/
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
				type = tools.getSeparateType( node.type );
			}
			
			switch( node.kind )
			{
				case D_FUNCTION:			return bShowType ? name  ~ "#" ~ type ~ "?" ~ Integer.toString( 28 + protAdd ) : name ~ "?" ~ Integer.toString( 28 + protAdd );
				case D_VARIABLE:
					if( node.name.length )
					{
						if( node.name[length-1] == ')' ) return bShowType ? name ~ "#" ~ type ~ "?" ~ Integer.toString( 0 + protAdd ) : name ~ "?" ~ Integer.toString( 0 + protAdd ); else return bShowType ? name ~ "#" ~ type ~ "?" ~ Integer.toString( 3 + protAdd ) : name ~ "?" ~ Integer.toString( 3 + protAdd );
					}
					break;
				case D_TEMPLATE:			return name ~ "?23";
				/*
				case B_PROPERTY:
					if( node.type.length )
					{
						if( node.type[0] == '(' ) return name ~ "?31"; else	return name ~ "?32";
					}
					break;
				*/
					
				case D_CLASS:					return name ~ "?" ~ Integer.toString( 6 + protAdd );
				case D_STRUCT: 					return name ~ "?" ~ Integer.toString( 9 + protAdd );
				case D_ENUM: 					return name ~ "?" ~ Integer.toString( 12 + protAdd );
				case D_PARAM:					return bShowType ? name ~ "#" ~ type ~ "?18" : name ~ "?18";
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

		static CASTnode[] getAnonymousEnumMemberFromWord( CASTnode originalNode, char[] word, bool bCaseSensitive )
		{
			CASTnode[] results;
			
			if( originalNode.kind & D_ENUM )
			{
				if( !originalNode.name.length )
				{
					foreach( CASTnode _node; anonymousEnumMembers( originalNode ) )
					{
						if( bCaseSensitive )
						{
							if( Util.index( _node.name, word ) == 0 ) results ~= _node;
						}
						else
						{
							if( Util.index( lowerCase( _node.name ), lowerCase( word ) ) == 0 ) results ~= _node;
						}
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
						if( _node.name == word ) return _node;
					}
				}
			}

			return null;
		}
		*/

		static CASTnode[] getBaseNodeMembers( CASTnode originalNode )
		{
			CASTnode[] results;

			if( originalNode !is null )
			{
				if( originalNode.kind & ( D_CLASS | D_INTERFACE ) )
				{
					if( originalNode.base.length )
					{
						// Search BaseNode, using originalNode.getFather to prevent infinite loop
						CASTnode mother = searchMatchNode( originalNode.getFather, tools.removeArrayAndPointer( originalNode.base ), D_CLASS | D_INTERFACE | D_TEMPLATE );

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
			
			int documentLength = IupScintillaSendMessage( iupSci, 2006, 0, 0 );		// SCI_GETLENGTH = 2006,
			int currentPos = ScintillaAction.getCurrentPos( iupSci );

			/*
			foreach_reverse( CASTnode child; head.getChildren() )
			{
				if( child.kind == B_SCOPE )
				{
					if( child.lineNumber < line )
					{
						int startPos;
						if( nextNode is null ) startPos = documentLength - 1;else startPos = IupScintillaSendMessage( iupSci, 2167, nextNode.lineNumber, 0 ); // SCI_POSITIONFROMLINE = 2167,
						
						int endPos = IupScintillaSendMessage( iupSci, 2167, child.lineNumber, 0 ); // SCI_POSITIONFROMLINE = 2167,

						IupScintillaSendMessage( iupSci, 2190, startPos, 0 ); 						// SCI_SETTARGETSTART = 2190,
						IupScintillaSendMessage( iupSci, 2192, endPos, 0 );							// SCI_SETTARGETEND = 2192,

						int posEndScope = cast(int) IupScintillaSendMessage( iupSci, 2197, 9, cast(int) GLOBAL.cString.convert( "end scope" ) ); // SCI_SEARCHINTARGET = 2197,

						if( posEndScope > endPos )
						{
							if( currentPos < posEndScope && currentPos > endPos )
							{
								if( child.getChildrenCount > 0 ) return checkScopeNode( iupSci, child, line ); else return child;
							}
						}
					}
				}

				nextNode = child;
			}
			*/
			return head;
		}		

		static CASTnode[] getMatchASTfromWholeWord( CASTnode node, char[] word, int line, int B_KIND )
		{
			CASTnode[] results;
			
			foreach( child; node.getChildren() )
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

		static CASTnode[] getMatchASTfromWord( CASTnode node, char[] word, int line, int D_KIND )
		{
			CASTnode[] results;
			
			foreach( child; node.getChildren() )
			{
				if( child.kind & D_KIND )
				{
					if( child.name.length )
					{
						if( Util.index( lowerCase( child.name ), word ) == 0 )
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

		static char[] checkIncludeExist( char[] importName, char[] _cwd )
		{
			if( importName.length )
			{
				importName = Util.replace( importName.dup, '.', '/' );
				char[] importFullPath = _cwd ~ importName;
		
			
				// Step 1: Relative from the directory of the source file
				scope  _path = new FilePath( importFullPath ~ ".d" ); // Tail include /
				if( _path.exists() ) return  _path.toString();
				_path.suffix(".di" );
				if( _path.exists() ) return  _path.toString();
				
				// Step 3: Relative from addition directories specified with the -i command line option
				// Work on Project
				char[] prjDir = actionManager.ProjectAction.getActiveProjectDir();

				if( prjDir.length )
				{
					char[][] includeDirs = GLOBAL.projectManager[prjDir].includeDirs; // without \
					foreach( char[] s; includeDirs )
					{
						if(s[$-1] != '/' || s[$-1] != '\\' ) s ~= '/';
						_path.set( s ~ importName ~ ".d" ); // Reset
						if( _path.exists() ) return _path.toString();

						_path.suffix(".di" );
						if( _path.exists() ) return _path.toString();
					}

					if( GLOBAL.projectManager[prjDir].compilerPath.length )
					{
						foreach( char[] _p; tools.getImportPath( GLOBAL.projectManager[prjDir].compilerPath ) )
						{
							_path.set( _p ~ importName ~ ".d" );
							if( _path.exists() ) return _path.toString();

							_path.suffix(".di" );
							if( _path.exists() ) return _path.toString();
						}
					}
					else
					{
						// Step 2: Default *.ini DFLAGS
						foreach( char[] _p; GLOBAL.defaultImportPaths )
						{
							_path.set( _p ~ importName ~ ".d" );
							if( _path.exists() ) return _path.toString();

							_path.suffix(".di" );
							if( _path.exists() ) return _path.toString();
						}
					}
				}
				else
				{
					// Step 2: Default *.ini DFLAGS
					foreach( char[] _p; GLOBAL.defaultImportPaths )
					{
						_path.set( _p ~ importName ~ ".d" );
						if( _path.exists() ) return _path.toString();

						_path.suffix(".di" );
						if( _path.exists() ) return _path.toString();
					}
				}		
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
					results ~= getIncludes( GLOBAL.parserManager[upperCase(includeFullPath)], "" );
				}
				else
				{
					//IupSetAttribute( GLOBAL.searchOutputPanel, "APPEND", toStringz( includeFullPath ));
					CASTnode _createFileNode = GLOBAL.outlineTree.loadParser( includeFullPath );
					
					if( _createFileNode !is null )
					{
						if( GLOBAL.editorSetting00.Message == "ON" ) 
						{
							if( GLOBAL.editorSetting00.LoadAtBackThread == "ON" )
							{
								version(Windows) GLOBAL.IDEMessageDlg.print( "  Pre-Parse file: [" ~ includeFullPath ~ "]" );//IupSetAttribute( GLOBAL.outputPanel, "APPEND\0", toStringz( "  Pre-Parse file: [" ~ includeFullPath ~ "]" ) );
							}
							else
							{
								GLOBAL.IDEMessageDlg.print( "  Pre-Parse file: [" ~ includeFullPath ~ "]" );
							}
						}
						
						includesMarkContainer[upperCase(includeFullPath)] = _createFileNode;
						
						results ~= _createFileNode;
						//results ~= getIncludes( _createFileNode, includeFullPath );
						results ~= getIncludes( _createFileNode, "" );
					}
				}
			}

			return results;
		}

		static CASTnode[] getMatchIncludesFromWholeWord( CASTnode originalNode, char[] originalFullPath, char[] word, int D_KIND )
		{
			CASTnode[] results;

			foreach( char[] key; includesMarkContainer.keys )
				includesMarkContainer.remove( key );		
			
			// Parse Include
			//CASTnode[] includeASTnodes = getIncludes( originalNode, originalFullPath );
			getIncludes( originalNode, "", true );

			foreach( includeAST; includesMarkContainer )
			{
				if( !checkBackThreadGoing ) return null;
				
				if( D_KIND & D_MODULE )
				{
					if( includeAST.kind & D_KIND )
					{
						if( includeAST.name == word ) results ~= includeAST;
					}
				}
				
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

		static CASTnode[] getMatchIncludesFromWord( CASTnode originalNode, char[] originalFullPath, char[] word, bool bCaseSensitive, int D_KIND )
		{
			CASTnode[] results;

			foreach( char[] key; includesMarkContainer.keys )
				includesMarkContainer.remove( key );

			// Parse Include
			//CASTnode[] includeASTnodes = getIncludes( originalNode, originalFullPath );
			getIncludes( originalNode, "", true );

			/*
			foreach( CASTnode n; includesMarkContainer )
				Stdout( n.name ).newline;
			*/
			foreach( includeAST; includesMarkContainer )
			{
				foreach( child; getMembers( includeAST ) )//includeAST.getChildren )
				{
					if( !checkBackThreadGoing ) return null;
					
					if( child.kind & D_KIND )
					{
						if( child.name.length )
						{
							int _pos;
							if( bCaseSensitive ) _pos = Util.index( child.name, word ); else _pos = Util.index( lowerCase( child.name ), lowerCase( word ) );
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

		static bool isDefaultType( char[] _type )
		{
			if( _type == "bool" || _type == "byte" || _type == "ubyte" || _type == "short" || _type == "ushort" || _type == "int" || _type == "uint" || _type == "long" || _type == "ulong" ||
				_type == "char" || _type == "wchar" || _type == "dchar" || _type == "float" || _type == "double" || _type == "real" || _type == "ifloat" || _type == "idouble" || _type == "ireal" ||
				_type == "cfloat" || _type == "cdouble" || _type == "creal" || _type == "void" 	) return true;

			return false;
		}

		static CASTnode searchMatchMemberNode( CASTnode originalNode, char[] word, int D_KIND = D_ALL )
		{
			foreach( CASTnode _node; getMembers( originalNode ) )
			{
				if( _node.kind & D_KIND )
				{
					if( tools.removeArrayAndPointer( _node.name ) == word ) return _node;
				}
			}

			return null;
		}

		static CASTnode[] searchMatchMemberNodes( CASTnode originalNode, char[] word, int D_KIND = D_ALL, bool bWholeWord = true, bool bCaseSensitive = true )
		{
			CASTnode[] results;
			
			foreach( CASTnode _node; getMembers( originalNode ) )
			{
				if( _node.kind & D_KIND )
				{
					char[] name = tools.removeArrayAndPointer( _node.name );

					if( !bCaseSensitive )
					{
						name = lowerCase( name );
						word = lowerCase( word );
					}

					if( bWholeWord )
					{
						if( name == word ) results ~= _node;
					}
					else
					{
						if( Util.index( name, word ) == 0 ) results ~= _node;
					}
				}
			}

			return results;
		}

		static CASTnode searchMatchNode( CASTnode originalNode, char[] word, int D_KIND = D_ALL )
		{
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

		static CASTnode[] searchMatchNodes( CASTnode originalNode, char[] word, int D_KIND = D_ALL, bool bWholeWord = true, bool bCaseSensitive = true )
		{
			CASTnode[] resultNodes = searchMatchMemberNodes( originalNode, word, D_KIND, bWholeWord, bCaseSensitive );

			if( bWholeWord )
				resultNodes ~=  getMatchIncludesFromWholeWord( originalNode, null, word, D_KIND );
			else
				resultNodes ~=  getMatchIncludesFromWord( originalNode, null, word, false, D_KIND );
			

			if( originalNode.getFather() !is null )
			{
				resultNodes ~= searchMatchNodes( originalNode.getFather(), word, D_KIND, bWholeWord, bCaseSensitive );
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
						if( Util.index( originalNode.name, word ) == 0 ) resultNodes ~= originalNode;
					}
				}
			}

			return resultNodes;
		}	

		static CASTnode[] getMembers( CASTnode AST_Head )
		{
			CASTnode[] result;

			CASTnode[] childrenNodes = AST_Head.getChildren();
			
			//IupMessage("MemberMother", toStringz( Integer.toString( AST_Head.kind ) ~ " " ~ ( AST_Head.name ) ~ " : " ~ AST_Head.type ) );
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
						foreach( char[] v; VersionCondition )
						{
							if( _child.name == v ) result ~= getMembers( _child );
						}
					}
					else
					{
						foreach( char[] v; VersionCondition )
						{
							if( _child.base != v ) result ~= getMembers( _child );
						}
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

		static int skipDelimitedString( char tokOpen, char tokClose, char[] word, int pos )
		{
			int		_countDemlimit, index;
			char[]	_params;		// include open Delimit and close Delimit


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

		static char[] convertRightExpressWord( char[] word )
		{
			char[]	result;

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
		
		static CASTnode getType( CASTnode originalNode )
		{
			CASTnode resultNode;

			if( originalNode.kind & ( D_ALIAS | D_VARIABLE | D_PARAM | D_FUNCTION ) )
			{
				char[][]	splitWord;

				if( originalNode.type.length )
				{
					splitWord = getDivideWord2( originalNode.type );
				}
				else
				{
					// AutoDeclaration
					if( originalNode.base.length ) splitWord = getDivideWord( convertRightExpressWord( originalNode.base ) ); else return null;
				}

				analysisSplitWorld_ReturnCompleteList( originalNode, splitWord, ScintillaAction.getCurrentPos( ScintillaAction.getActiveIupScintilla ), true, false, false );
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

		static bool stepByStep( ref CASTnode AST_Head, char[] word, int D_KIND )
		{
			AST_Head = searchMatchMemberNode( AST_Head, word, D_KIND );
			if( AST_Head is null ) return false;

			if( AST_Head.kind & ( D_VARIABLE | D_PARAM | D_FUNCTION | D_ALIAS ) )
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
				
				if( groupAST[i].kind & ( D_FUNCTION ) )
				{
					if( ( !word.length ) || groupAST[i].name == word )
					{
						char[] _type = tools.getSeparateType( groupAST[i].type );
						char[] _paramString = tools.getSeparateParam( groupAST[i].type );
						
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
								results ~= ( "this" ~ _child.type ~ "\n" );
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
									char[] _type = tools.getSeparateType( groupAST[i].type );
									char[] _paramString = tools.getSeparateParam( groupAST[i].type );
									
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
		
		static void callTipSetHLT( char[] list, int itemNO, inout int highlightStart, inout int highlightEnd )
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
		
		static char[] parseProcedureForCalltip( Ihandle* ih, int lineHeadPos, char[] lineHeadText, inout int commaCount, inout int parenCount, inout int firstOpenParenPos )
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
					if( lineHeadText[i] == ' ' || lineHeadText[i] == '\t' || lineHeadText[i] == '\n' || lineHeadText[i] == '\r' || lineHeadText[i] == '.' || lineHeadText[i] == ';')
						break;
					else
						procedureName = lineHeadText[i] ~ procedureName;
				}
			}
			
			return procedureName;
		}		
		
		static char[] parseProcedureForCalltip( Ihandle* ih, int pos, inout int commaCount, inout int parenCount, inout int firstOpenParenPos )
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
					if( s == " " || s == "\t" || s == "\n" || s == "\r"  || s == "." || s == ";" )
						break;
					else
						procedureName = s ~ procedureName;
				}
			}
			
			return procedureName;
		}

		static void keyWordlist( char[] word )
		{
			foreach( IupString _s; GLOBAL.KEYWORDS )
			{
				foreach( char[] s; Util.split( _s.toDString, " " ) )
				{
					if( s.length )
					{
						if( Util.index( s, word ) == 0 ) listContainer ~= ( s ~ "?21" );
					}
				}
			}
		}

		static char[][] getDivideWord( char[] word )
		{
			char[][]	splitWord;
			char[]		tempWord;
			for( int i = 0; i < word.length ; ++ i )
			{
				if( word[i] == '.' )
				{
					if( tempWord.length > 1 )
						if( tempWord[0] == '!' ) tempWord = tempWord[1..length];

					splitWord ~= tempWord;
					tempWord = "";
				}
				else
				{
					tempWord ~= word[i];
				}			
			}

			if( tempWord.length > 1 )
				if( tempWord[0] == '!' ) tempWord = tempWord[1..length];

			splitWord ~= tempWord;

			return splitWord;
		}

		static char[][] getDivideWord2( char[] word )
		{
			int _getDelimitedString( int _index, char _delimitedOpen, char _delimitedClose )
			{
				int		_countDemlimit;
				
				do
				{
					if( word[_index] == _delimitedOpen ) _countDemlimit ++;
					if( word[_index] == _delimitedClose ) _countDemlimit --;

					if( _countDemlimit == 0 ) break;
					_index ++;
				}
				while( _countDemlimit > 0 )

				return _index;
			}

			char[][]	splitWord;
			char[]		tempWord;

			int			returnIndex;

			for( int i = 0; i < word.length ; ++ i )
			{
				if( word[i] == '.' )
				{
					splitWord ~= tools.removeArrayAndPointer( tempWord );
					tempWord = "";
				}
				else
				{
					if( word[i] == '(' )
					{
						returnIndex = _getDelimitedString( i, '(', ')' );
						if( returnIndex < word.length )
						{
							i = returnIndex;
							//tempWord ~= ")";
						}
					}
					else if( word[i] == '[' )
					{
						returnIndex = _getDelimitedString( i, '[', ']' );
						if( returnIndex < word.length )
						{
							i = returnIndex;
							//tempWord ~= "]";
						}				
					}
					else
					{
						tempWord ~= word[i];
					}
				}			
			}

			splitWord ~= tools.removeArrayAndPointer( tempWord );

			/+
			IupSetAttribute( GLOBAL.outputPanel, "APPEND", toStringz( "OriWord= " ~ word ) );
			foreach( char[] s; splitWord )
			{
				IupSetAttribute( GLOBAL.outputPanel, "APPEND", toStringz( s ) );
			}
			IupSetAttribute( GLOBAL.outputPanel, "APPEND", toStringz( "\n" ) );
			+/

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

		static CASTnode[] searchObjectModuleMembers( char[] word, int D_KIND = D_ALL, bool bWholeWord = true, bool bCaseSensitive = true )
		{
			CASTnode[] resultNodes;
			
			// object.di
			if( GLOBAL.objectParserFullPath.length )
			{
				if( GLOBAL.objectParserFullPath in GLOBAL.parserManager )
				{
					foreach( CASTnode child; GLOBAL.parserManager[GLOBAL.objectParserFullPath].getChildren )
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
									if( Util.index( child.name, word ) == 0 ) resultNodes ~= child;
								}
								else
								{
									if( Util.index( lowerCase( child.name ), lowerCase( word ) ) == 0 ) resultNodes ~= child;
								}
							}
						}	
					}
				}
			}

			return resultNodes;
		}
		
		static CASTnode searchObjectModule( char[] word, int D_KIND = D_ALL, bool bWholeWord = true, bool bCaseSensitive = true )
		{
			CASTnode[] resultNodes = searchObjectModuleMembers( word, D_KIND, bWholeWord, bCaseSensitive );
			if( resultNodes.length ) return resultNodes[0];
			
			return null;
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
			}
			
			if( calltipContainer is null ) calltipContainer = new CStack!(char[]);
		}
		
		static void cleanCalltipContainer()
		{
			if( calltipContainer is null ) calltipContainer.clear();
		}		

		static bool checkIsclmportDeclare( Ihandle* iupSci, int pos = -1 )
		{
			char[]	result;
			dchar[]	resultd;
			
			int		documentLength = IupGetInt( iupSci, "COUNT" );
			try
			{
				while( --pos >= 0 )
				{
					if( !ScintillaAction.isComment( iupSci, pos ) )
					{
						char[] s = fromStringz( IupGetAttributeId( iupSci, "CHAR", pos ) );
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
				
				result = lowerCase( Util.trim( result.reverse ) ).dup;
				if( Util.count( result, "import " ) > 0 ) return true;
				if( Util.count( result, "import\t" ) > 0 ) return true;
			}
			catch( Exception e )
			{
				GLOBAL.IDEMessageDlg.print( "checkIscludeDeclare() Error:\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ Integer.toString( e.line ) );
				//debug IupMessage( "AutoComplete.checkIscludeDeclare() Error", toStringz( e.toString ) );
			}

			return false;
		}
		
		static char[] includeComplete( Ihandle* iupSci, int pos, inout char[] text )
		{
			// Nested Delegate Filter Function
			bool dirFilter( FilePath _fp, bool _isFfolder )
			{
				if( _isFfolder ) return true;
				if( lowerCase( _fp.ext ) == "d" || lowerCase( _fp.ext ) == "di" ) return true;
			
				return false;
			}
			
			bool delegate( FilePath, bool ) _dirFilter;
			_dirFilter = &dirFilter;
			// End of Nested Function
			
			if( !text.length )  return null;
			
			dchar[] word32;
			char[]	word = text;
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
								case ' ', '\t', ';', '\n', '\r':		bExitLoopFlag = true; break;
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
				
				char[][]	words = Util.split( word, "." );
				char[][]	tempList;

				if( !words.length ) return null;
				
				// Step 1: Relative from the directory of the source file
				FilePath  _path1;
				
				// Get cwd
				auto cSci = ScintillaAction.getCScintilla( iupSci );
				if( cSci !is null )
				{
					if( upperCase(cSci.getFullPath) in GLOBAL.parserManager )
					{
						auto headNode = GLOBAL.parserManager[upperCase( cSci.getFullPath )];
						if( headNode.kind & D_MODULE )
						{
							int dotCount = Util.count( headNode.name, "." );
							scope cwdFilePath = new FilePath( headNode.type );

							//IupSetAttribute( GLOBAL.outputPanel, "APPEND", toStringz( "D_MODULE Name: [" ~ originalNode.name ~ "]"  ) );

							char[] _cwd = cwdFilePath.path();
							for( int i = 0; i < dotCount; ++ i )
							{
								cwdFilePath.set( _cwd );
								_cwd = cwdFilePath.parent();
							}

							if( _cwd.length )
								if( _cwd[$-1] != '/' ) _cwd ~= '/';

							_path1 = new FilePath( _cwd );
						}
					}
				}

				// Step 3: Relative from addition directories specified with the -i command line option
				// Work on Project
				FilePath[]  _path2, _path3;
				
				char[] prjDir = actionManager.ProjectAction.getActiveProjectDir();
				if( prjDir.length )
				{
					foreach( char[] s; GLOBAL.projectManager[prjDir].includeDirs )
						_path3 ~= new FilePath( s );


					if( GLOBAL.projectManager[prjDir].compilerPath.length )
					{
						foreach( char[] _p; tools.getImportPath( GLOBAL.projectManager[prjDir].compilerPath ) )
							_path3 ~= new FilePath( _p );
					}
					else
					{
						// Step 2: Default *.ini DFLAGS
						foreach( char[] _p; GLOBAL.defaultImportPaths )
							_path2 ~= new FilePath( _p );
					}
				}
				else
				{
					// Step 2: Default *.ini DFLAGS
					foreach( char[] _p; GLOBAL.defaultImportPaths )
						_path2 ~= new FilePath( _p );
				}
				

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
						
						// Step 2:  Default *.ini DFLAGS
						foreach( FilePath _fp2; _path2 )
						{
							if( _fp2.exists )
							{
								foreach( FilePath _fp; _fp2.toList( _dirFilter ) )
									tempList ~= _fp.file;
							}
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
					}
					else
					{
						_path1 = _path1.set( _path1.toString ~ words[i] ~ "/" );
						for( int j = 0; j < _path2.length; ++ j )
							_path2[j] = _path2[j].set( _path2[j].toString ~ words[i] ~ "/" );
						for( int j = 0; j < _path3.length; ++ j )
							_path3[j] = _path3[j].set( _path3[j].toString ~ words[i] ~ "/" );
					}
				}

				foreach( char[] s; tempList )
				{
					if( s.length )
					{
						char[] iconNum = "37";
						
						if( s.length > 2 )
						{
							if( lowerCase( s[$-2..$] ) == ".d" )
							{
								iconNum = "35";
								s = s[0..$-2];
							}
						}
						
						if( s.length > 3 )
						{
							if( lowerCase( s[$-3..$] ) == ".di" )
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
				foreach( FilePath _p; _path2 )
					delete _p;
				foreach( FilePath _p; _path3 )
					delete _p;
				
				return list;				
			}
			catch( Exception e )
			{
			}
			
			return null;
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
					if( result[length-1] == '^' ) result = result[0..length-1];

				return Util.trim( result );
			}
			
			return null;
		}
		
		static bool checkBackThreadGoing()
		{
			if( GLOBAL.toggleCompleteAtBackThread )
			{
				auto _thread = cast( CShowListThread ) Thread.getThis();
				
				if( showListThread !is null )
				{
					if( _thread.text != "(" )
					{
						if( showListThread.bStop ) return false;
					}
				}
				
				if( showCallTipThread !is null )
				{
					if( _thread.text == "(" )
					{
						if( showCallTipThread.bStop ) return false;
					}
				}
			}
			
			return true;
		}		

		static CASTnode[] getIncludes( CASTnode originalNode, char[] cwdPath = null, bool bRootCall = false )
		{
			CASTnode[] results;

			if( !cwdPath.length )
			{
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
			}

			foreach( CASTnode _node; getMembers( originalNode ) )
			{
				if( !checkBackThreadGoing ) return null;
				
				if( _node.kind & D_IMPORT )
				{
					//IupMessage( "D_IMPORT", toStringz( _node.name ));
					//IupMessage( "cwdPath", toStringz( cwdPath ));
					if( bRootCall )
					{
						if( _node.type.length ) results ~= check( _node.type, cwdPath ); else results ~= check( _node.name, cwdPath );
					}
					else
					{
						if( _node.protection == "public" )
						{
							if( _node.type.length ) results ~= check( _node.type, cwdPath ); else results ~= check( _node.name, cwdPath );
						}
					}
				}
				/+
				else if( _node.kind & D_VERSION )
				{
					version(Windows)
					{
						if( _node.name == "Windows" || _node.name == "Win32" || ( _node.name == "-else-" && _node.base == "linux" ) )
						{
							results ~= getIncludes( _node, cwdPath, bRootCall );
						}
					}

					version(linux)
					{
						if( _node.name == "linux" || ( _node.name == "-else-" && _node.base != "linux" ) )
						{
							results ~= getIncludes( _node, cwdPath, bRootCall );
						}
					}
				}
				+/
			}

			return results;
		}
		
		/+
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
					if( targetText == "type" )
					{
						char[]	afterWord;
						bool	bFirstChar = true;
						int		count;
						
						for( int i = posHead + targetText.length; i < documentLength; ++ i )
						{
							char[] _s = fromStringz( IupGetAttributeId( iupSci, "CHAR", i ) );

							if( _s[0] == 13 || _s == ":" || _s == "\n" )
							{
								break;
							}
							else if( _s == " " || _s == "\t" )
							{
								if( !bFirstChar )
								{
									count ++;
									
									if( count == 2 && afterWord == "as" )
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
							char[] s = fromStringz( IupGetAttributeId( iupSci, "CHAR", i ) );

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
									char[] _s = fromStringz( IupGetAttributeId( iupSci, "CHAR", j ) );
									
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
		+/
		/+
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

				if( endText == targetText )
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
		+/

		/*	direct = 0 findprev, direct = 1 findnext
			SCFIND_WHOLEWORD = 2,
			SCFIND_MATCHCASE = 4,
		*/
		static int skipCommentAndString(  Ihandle* iupSci, int pos, char[] targetText, int direct,int flag = 2 )
		{
			IupScintillaSendMessage( iupSci, 2198, flag, 0 );						// SCI_SETSEARCHFLAGS = 2198,
			int documentLength = IupScintillaSendMessage( iupSci, 2006, 0, 0 );		// SCI_GETLENGTH = 2006,

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
			pos = IupScintillaSendMessage( iupSci, 2197, targetText.length, cast(int) GLOBAL.cString.convert( targetText ) );
			
			while( pos > -1 )
			{
				int style = IupScintillaSendMessage( iupSci, 2010, pos, 0 ); // SCI_GETSTYLEAT 2010
				if( style == 1 || style == 2 || style == 3 || style == 4 || style == 10 || style == 12 )
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
		/+
		static CASTnode getTitleAST( Ihandle* iupSci, int pos, CASTnode head )
		{
			int _kind;
			
			char[] titleName = getFunctionTitle( iupSci, pos, _kind );
			if( titleName.length )
			{
				int	lineNum = IupScintillaSendMessage( iupSci, 2166, pos, 0 ) + 1; //SCI_LINEFROMPOSITION = 2166,
				return getFunctionAST( head, _kind, titleName, lineNum );
			}

			return null;
		}
		+/

		static char[] getWholeWordDoubleSide( Ihandle* iupSci, int pos = -1 )
		{
			int		countParen, countBracket;
			int		oriPos = pos;
			bool	bForntEnd, bBackEnd;
			int		documentLength = IupGetInt( iupSci, "COUNT" );
			/+
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
						
						case " ", "\t", ":", ";", "\r", "\n", "+", "-", ">", "*", "/", "<", ",", "{", "}", "!":
							if( countParen == 0 && countBracket == 0 ) bBackEnd = true;
							break;

						default:
					}
				}
				
				if( pos >= documentLength ) break;
				if( bBackEnd ) break;
			}
			while( ++pos < documentLength )
			+/
			do
			{
				if( !actionManager.ScintillaAction.isComment( iupSci, pos ) )
				{
					char[] s = fromStringz( IupGetAttributeId( iupSci, "CHAR", pos ) );

					switch( s )
					{
						case "(", ")", "[", "]", "{", "}":
						case " ", "\t", ":", ";", "\n", "\r", "+", "-", "*", "/", "\\", ">", "<", "=", ",", "!":
							bBackEnd = true;
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

		// For Goto Defintion Using
		static char[] checkIsInclude( Ihandle* iupSci, int pos = -1 )
		{
			char[]	result;
			int		documentLength = IupGetInt( iupSci, "COUNT" ), fullStringPos, fullStringEndPos, moduleStartPos, oriPos = pos;
			
			do
			{
				char[] s = fromStringz( IupGetAttributeId( iupSci, "CHAR", pos ) );
				if( s == ";" || s == "," ) break;
			}
			while( ++pos < documentLength )
			--pos;
			fullStringEndPos = fullStringPos = pos;

			do
			{
				char[] s = fromStringz( IupGetAttributeId( iupSci, "CHAR", pos ) );
				if( s == ";" || s == "{" || s == "{" || s == "," || s =="=" ) break;
			}
			while( --pos >= 0 )
			moduleStartPos = pos;

			do
			{
				char[] s = fromStringz( IupGetAttributeId( iupSci, "CHAR", fullStringPos ) );
				if( s == ";" || s == "{" || s == "{" ) break;
			}
			while( --fullStringPos >= 0 )
			
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
					char[] s = fromStringz( IupGetAttributeId( iupSci, "CHAR", importPos ) );
					if( s != " " && s != "\t" ) break;
				}
				while( ++moduleStartPos < documentLength )			
				
				if( oriPos > moduleStartPos && oriPos < fullStringEndPos )
				{
					for( int i = moduleStartPos +1 ; i <= fullStringEndPos; ++ i )
					{
						result ~= fromStringz( IupGetAttributeId( iupSci, "CHAR", i ) );
					}
					return Util.trim( result );
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
					char[] s = fromStringz( IupGetAttributeId( iupSci, "CHAR", startPos ) );
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
						char[] _s = fromStringz( IupGetAttributeId( iupSci, "CHAR", pos ) ).dup;
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

								case '\n', '\r':
									if( !actionManager.ScintillaAction.isComment( iupSci, pos ) ) return word;

								case ' ', '\t', ':', ';', '+', '-', '*', '/', '<', '>', ',', '=', '&':
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
				
			}
			catch( Exception e )
			{
				//IupMessage( "Error", toStringz( e.toString ) );
				return null;
			}

			return word;
		}


		private static char[] analysisSplitWorld_ReturnCompleteList( inout CASTnode AST_Head, char[][] splitWord, int pos, bool bDot, bool bCallTip, bool bPushContainer  )
		{
			if( AST_Head is null ) return null;
			
			auto		cSci = actionManager.ScintillaAction.getActiveCScintilla();
			auto		function_originalAST_Head = AST_Head;

			if( cSci is null ) return null;
			
			int			lineNum = IupScintillaSendMessage( cSci.getIupScintilla(), 2166, ScintillaAction.getCurrentPos( cSci.getIupScintilla() ), 0 ) + 1; //SCI_LINEFROMPOSITION = 2166,
			char[]		result;
			
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
							if( bCallTip )
							{
								foreach( node; searchMatchNodes( AST_Head, splitWord[i], D_FIND, true ) ~ searchObjectModuleMembers( splitWord[i], D_FIND )  ) // NOTE!!!! Using "searchMatchNode()"
								{
									if( node !is null )
									{
										if( node.kind & ( D_FUNCTION | D_CLASS | D_STRUCT | D_INTERFACE | D_UNION ) )
										{
											resultNodes ~= node;
										}
										else if( node.kind & ( D_VARIABLE | D_PARAM | D_ALIAS ) )
										{
											node = getType( node );
											if( node !is null ) resultNodes ~= node;
										}
										else if( node.kind & D_TEMPLATE )
										{
											auto temp = getAggregateTemplate( node );
											if( temp !is null ) resultNodes ~= temp;
										}
									}
								}

								if( !bPushContainer ) return null;

								result = callTipList( resultNodes, null );
								return Util.trim( result );
							}


							if( GLOBAL.enableKeywordComplete == "ON" ) keyWordlist( splitWord[i] );

							if( bPushContainer )
							{
								foreach( CASTnode _node; searchMatchNodes( AST_Head, splitWord[i], D_ALL, false, false )  ~ searchObjectModuleMembers( splitWord[i], D_FIND, false, false ) )
								{
									if( _node.kind & D_IMPORT )
									{
										char[][] nodeNames = Util.split( _node.name, "." );
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
							AST_Head = searchMatchNode( AST_Head, splitWord[i], D_FIND ); // NOTE!!!! Using "searchMatchNode()"
							if( AST_Head is null ) AST_Head = searchObjectModule( splitWord[i], D_FIND );
							if( AST_Head is null )
							{
								AST_Head = importComplete( _sub_ori_AST_Head, lineNum, 1, splitWord, 0 );
								if( AST_Head is null ) break;
							}
							auto _tempNode = getAggregateTemplate( AST_Head );
							if( _tempNode !is null ) AST_Head = _tempNode;
							if( AST_Head.kind & ( D_VARIABLE | D_PARAM ) )
							{
								//if( Util.count( AST_Head.type, "[" ) )
								if( AST_Head.type.length )
								{
									if( AST_Head.type[$-1] == ']' )
									{
										char[] beforeDot = fromStringz( IupGetAttributeId( cSci.getIupScintilla, "CHAR", pos - 1 ) );
										if( beforeDot != "]" )
										{
											listContainer.length = 0;
											return "init?21^sizeof?21^length?21^ptr?21^dup?21^idup?21^reverse?21^sort?21";
										}
									}
								}
							}

							if( AST_Head.kind & ( D_VARIABLE | D_PARAM | D_FUNCTION | D_ALIAS ) )
							{
								//IupMessage("originalNode", toStringz( Integer.toString( AST_Head.kind ) ~ " " ~ ( AST_Head.name ) ~ " : " ~ AST_Head.type ) );
								AST_Head = getType( AST_Head );
								if( AST_Head is null ) return null;
							}
							if( bPushContainer )
							{
								//IupMessage("originalNode", toStringz( Integer.toString( AST_Head.kind ) ~ " " ~ ( AST_Head.name ) ~ " : " ~ AST_Head.type ) );
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
					AST_Head = searchMatchNode( AST_Head, splitWord[i], D_FIND ); // NOTE!!!! Using "searchMatchNode()"
					
					if( AST_Head is null ) AST_Head = searchObjectModule( splitWord[i], D_FIND );

					if( AST_Head is null )
					{
						AST_Head = importComplete( _sub_ori_AST_Head, lineNum, 1, splitWord, 0 );
						
						if( AST_Head is null ) return null;
						
						if( AST_Head.kind & D_IMPORT ) continue;
					}

					auto _tempNode = getAggregateTemplate( AST_Head );
					if( _tempNode !is null ) AST_Head = _tempNode;

					if( AST_Head.kind & ( D_VARIABLE | D_PARAM | D_FUNCTION | D_ALIAS ) )
					{
						AST_Head = getType( AST_Head );
						if( AST_Head is null ) return null;
					}

					//IupMessage("originalNode", toStringz( Integer.toString( AST_Head.kind ) ~ " " ~ ( AST_Head.name ) ~ " : " ~ AST_Head.type ) );
				}
				else if( i == splitWord.length -1 )
				{
					if( !bDot )
					{
						if( bCallTip )
						{
							if( !bPushContainer ) return null;

							//if( AST_Head is null ) IupMessage("",""); else IupMessage("",toStringz(Integer.toString(AST_Head.kind) ~ " " ~ AST_Head.name));

							CASTnode[] childrenNodes;// =  AST_Head.getChildren();
							//getBaseNodeMembers( AST_Head, childrenNodes );

							foreach( node; searchMatchNodes( AST_Head, splitWord[i], D_FIND, true ) ~ searchObjectModuleMembers( splitWord[i], D_FIND ) ) // NOTE!!!! Using "searchMatchNode()"
							{
								if( node !is null )
								{
									if( node.kind & ( D_FUNCTION | D_CLASS | D_STRUCT | D_INTERFACE | D_UNION ) )
									{
										childrenNodes ~= node;
									}
									else if( node.kind & ( D_VARIABLE | D_PARAM | D_ALIAS ) )
									{
										node = getType( node );
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
							return Util.trim( result );
						}

						if( bPushContainer )
						{
							if( AST_Head.kind & D_IMPORT )
							{
								importComplete( function_originalAST_Head, lineNum, 4, splitWord, i );
							}
							else
							{
								//IupMessage("originalNode", toStringz( Integer.toString( AST_Head.kind ) ~ " " ~ ( AST_Head.name ) ~ " : " ~ AST_Head.type ) );
								foreach( CASTnode _child; getMembers( AST_Head ) ) // Get members( include nested unnamed union & type )
								{
									if( Util.index( lowerCase( _child.name ), lowerCase( splitWord[i] ) ) == 0 ) listContainer ~= getListImage( _child );
								}
							}
						}
					}
					else
					{
						if( AST_Head is null ) return null;

						if( !( AST_Head.kind & D_IMPORT ) )
							AST_Head = searchMatchMemberNode( AST_Head, tools.removeArrayAndPointer( splitWord[i] ), D_FIND );
						else
							AST_Head = importComplete( function_originalAST_Head, lineNum, 3, splitWord, i );
						
						if( AST_Head is null ) return null;

						//if( AST_Head !is null ) IupMessage("NOT NULL", toStringz( Integer.toString( AST_Head.kind ) ~ " " ~ ( AST_Head.name ) ~ " : " ~ AST_Head.type ) );

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
							if( AST_Head.kind & ( D_VARIABLE | D_PARAM | D_FUNCTION ) )
							{	
								CASTnode _sub_ori_AST_Head = AST_Head;
								AST_Head = getType( AST_Head );

								//if( AST_Head !is null ) IupMessage("NOT NULL", toStringz( Integer.toString( AST_Head.kind ) ~ " " ~ ( AST_Head.name ) ~ " : " ~ AST_Head.type ) );
								if( AST_Head is null )
								{
									//if( Util.count( getSeparateType( _sub_ori_AST_Head.type ), "[" ) )
									char[] _type = getSeparateType( _sub_ori_AST_Head.type );
									if( _type.length )
									{
										if( _type[$-1] == ']' )
										{
											char[] beforeDot = fromStringz( IupGetAttributeId( cSci.getIupScintilla, "CHAR", pos - 1 ) );
											if( beforeDot != "]" )
											{
												listContainer.length = 0;
												return "init?21^sizeof?21^length?21^ptr?21^dup?21^idup?21^reverse?21^sort?21";
											}
										}
									}
									return null;
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
					}
				}
				else
				{
					if( !( AST_Head.kind & D_IMPORT ) )
					{
						if( !stepByStep( AST_Head, splitWord[i], D_FIND ) ) return null;
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
		
		static char[] charAdd( Ihandle* iupSci, int pos = -1, char[] text = "", bool bForce = false )
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
			else
			{
				word = text;
			}

			word = word ~ getWholeWordReverse( iupSci, pos, dummyHeadPos );
			
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
			+/

			word = word.reverse;

			auto cSci = actionManager.ScintillaAction.getActiveCScintilla();
			if( cSci !is null )
			{
				if( !bDot && ( fromStringz( IupGetAttribute( iupSci, "AUTOCACTIVE" ) ) == "YES" ) )
				{}
				else
				{
					// Clean listContainer
					listContainer.length = 0;
					IupSetAttribute( iupSci, "AUTOCCANCEL", GLOBAL.cString.convert( "YES" ) );

					// Divide word
					/*char[][] splitWord = Util.split( word, "." );
					if( splitWord.length == 1 ) splitWord = Util.split( word, "->" );*/
					char[][]	splitWord = getDivideWord( word );
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
					+/

					int				lineNum = IupScintillaSendMessage( iupSci, 2166, pos, 0 ) + 1; //SCI_LINEFROMPOSITION = 2166,
					CASTnode		AST_Head = ParserAction.getActiveASTFromLine( ParserAction.getActiveParseAST(), lineNum );
					char[]			memberFunctionMotherName;

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
					
					
					result = analysisSplitWorld_ReturnCompleteList( AST_Head, splitWord, pos, bDot, bCallTip, true );

					if( listContainer.length )
					{
						listContainer.sort;

						char[]	_type, _list;
						int		maxLeft, maxRight;

						if( GLOBAL.toggleShowListType == "ON" )
						{
							for( int i = 0; i < listContainer.length; ++ i )
							{
								if( listContainer[i].length )
								{
									int dollarPos = Util.rindex( listContainer[i], "#" );
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
									
									int dollarPos = Util.rindex( listContainer[i], "#" );
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
					if( result[length-1] == '^' ) result = result[0..length-1];

				return result.dup;
			}

			return null;
		}

		static void toDefintionAndType( int runType )
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
					word = word.reverse;

					char[][] splitWord = getDivideWord( word );

					int				lineNum = IupScintillaSendMessage( cSci.getIupScintilla, 2166, currentPos, 0 ) + 1; //SCI_LINEFROMPOSITION = 2166,
					CASTnode		AST_Head = ParserAction.getActiveASTFromLine( ParserAction.getActiveParseAST(), lineNum );

					if( AST_Head is null ) return;
					
					//if( AST_Head !is null ) IupMessage("NOT NULL", toStringz( Integer.toString( AST_Head.kind ) ~ " " ~ ( AST_Head.name ) ~ " : " ~ AST_Head.type ) ); else IupMessage("",toStringz("NULL"));


					//
					AutoComplete.VersionCondition.length = 0;
					
					char[] options = ExecuterAction.getCustomCompilerOption();
					char[] activePrjName = ProjectAction.getActiveProjectName;
					if( activePrjName.length ) options = Util.trim( options ~ " " ~ GLOBAL.projectManager[activePrjName].compilerOption );
					if( options.length )
					{
						int _versionPos = Util.index( options, "-version=" );
						while( _versionPos < options.length )
						{
							char[] versionName;
							for( int i = _versionPos + 9; i < options.length; ++ i )
							{
								if( options[i] == '\t' || options[i] == ' ' ) break;
								versionName ~= options[i];
							}							
							if( versionName.length ) AutoComplete.VersionCondition ~= versionName;
							
							_versionPos = Util.index( options, "-version=", _versionPos + 9 );
						}
					}
					

					// Goto Import Modules
					if( runType > 0 )
					{
						char[] string = checkIsInclude( cSci.getIupScintilla, currentPos );
						if( string.length )
						{
							// Get cwd
							char[] cwdPath;
							
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
							
							char[] fullPath = checkIncludeExist( string, cwdPath );
							if( fullPath.length )
							{
								if( GLOBAL.navigation.addCache( fullPath, 1 ) ) actionManager.ScintillaAction.openFile( fullPath );
								return;
							}
						}
					}

					CASTnode	firstASTNode, finalASTNode, _sub_ori_AST_Head = AST_Head;
					char[]		_list;
				
					for( int i = 0; i < splitWord.length; i++ )
					{
						//IupMessage(toStringz(Integer.toString(i)),toStringz( tools.removeArrayAndPointer( splitWord[i] ) ));
						if( i == 0 )
						{
							//IupMessage("",toStringz(removeArrayAndPointerWord( splitWord[i] )));
							//IupMessage("",toStringz(AST_Head.name ~ " : " ~ AST_Head.type));
							AST_Head = searchMatchNode( AST_Head, Util.stripl( tools.removeArrayAndPointer( splitWord[i] ), '&' ), D_FIND ); // NOTE!!!! Using "searchMatchNode()"
							
							if( AST_Head is null ) AST_Head = searchObjectModule( splitWord[i], D_FIND );
							
							if( AST_Head is null )
							{
								AST_Head = importComplete( _sub_ori_AST_Head, lineNum, 1, splitWord, 0 );
								if( AST_Head is null ) return;
							}
							//if( AST_Head is null ) return;

							firstASTNode = AST_Head;

							if( AST_Head.kind & ( D_VARIABLE | D_PARAM | D_FUNCTION | D_ALIAS ) )
							{
								if( isDefaultType( tools.getSeparateType( AST_Head.type, true ) ) )
								{
									_list = ( "1st Layer:  " ~ AST_Head.type ~ " " ~ firstASTNode.name ~ getSeparateParam( firstASTNode.type ) ).dup;
								}
								else
								{
									AST_Head = getType( AST_Head );
									if( AST_Head is null )
									{
										if( firstASTNode.kind & D_MODULE )
											_list = ( "1st Layer:  " ~ ( firstASTNode.name.length ? getSeparateType( firstASTNode.name ) ~ " " : " " ) );
										else
											_list = ( "1st Layer:  " ~ ( firstASTNode.type.length ? getSeparateType( firstASTNode.type ) ~ " " : " " ) ~ firstASTNode.name ~ ( firstASTNode.type.length ? getSeparateParam( firstASTNode.type ) : "()" ) );
											
										finalASTNode = null;
									}
									else
									{
										finalASTNode = AST_Head;
									}
								}
							}						

							if( splitWord.length == 1 ) break;
						}
						else
						{
							if( AST_Head !is null )
							{
								AST_Head = searchMatchMemberNode( AST_Head, tools.removeArrayAndPointer( splitWord[i] ), D_FIND );
								
								if( AST_Head is null ) return;

								firstASTNode = AST_Head;

								if( AST_Head.kind & ( D_VARIABLE | D_PARAM | D_FUNCTION | D_ALIAS ) )
								{
									if( isDefaultType( tools.getSeparateType( AST_Head.type, true ) ) )
									{
										_list = ( "1st Layer:  " ~ AST_Head.type ~ " " ~ firstASTNode.name ~ getSeparateParam( firstASTNode.type ) ).dup;
									}
									else
									{
										AST_Head = getType( AST_Head );
										if( AST_Head is null )
										{
											_list = ( "1st Layer:  " ~ ( firstASTNode.type.length ? getSeparateType( firstASTNode.type ) ~ " " : " " ) ~ firstASTNode.name ~ getSeparateParam( firstASTNode.type ) ).dup;
											finalASTNode = null;
										}
										else
										{
											finalASTNode = AST_Head;
										}
									}
								}
							}
						}
					}

					if( runType == 0 )
					{
						
						char[]	_type, _param;

						if( firstASTNode !is null )
						{
							_type = getSeparateType( firstASTNode.type );
							_param = getSeparateParam( firstASTNode.type );

							switch( firstASTNode.kind )
							{
								case D_MODULE: _type = "\"MODULE\""; break;
								case D_INTERFACE: _type = "\"INTERFACE\""; break;
								case D_TEMPLATE: _type = "\"TEMPLATE\""; break;
								case D_STRUCT: _type = "\"STRUCT\""; break;
								case D_CLASS: _type = "\"CLASS\""; break;
								case D_UNION: _type = "\"UNION\""; break;
								case D_ENUM: _type = "\"ENUM\""; break;
								//case B_NAMESPACE: _type = "NAMESPACE"; break;
								default:
							}

							_list = ( "1st Layer:  " ~ ( _type.length ? _type ~ " " : null ) ~ firstASTNode.name ~ _param ).dup;
						}


						if( finalASTNode !is null )
						{
							_type = getSeparateType( finalASTNode.type );
							_param = getSeparateParam( finalASTNode.type );

							switch( finalASTNode.kind )
							{
								case D_MODULE: _type = "\"MODULE\""; break;
								case D_INTERFACE: _type = "\"INTERFACE\""; break;
								case D_TEMPLATE: _type = "\"TEMPLATE\""; break;
								case D_STRUCT: _type = "\"STRUCT\""; break;
								case D_CLASS: _type = "\"CLASS\""; break;
								case D_UNION: _type = "\"UNION\""; break;
								case D_ENUM: _type = "\"ENUM\""; break;
								//case B_NAMESPACE: _type = "NAMESPACE"; break;
								default:
							}

							if( _list.length ) _list ~= "\n";
							_list ~= ( "Top Layer:  " ~ ( _type.length ? _type ~ " " : null ) ~ finalASTNode.name ~ _param ).dup;
						}

						IupScintillaSendMessage( cSci.getIupScintilla, 2206, 0xFF0000, 0 ); //SCI_CALLTIPSETFORE 2206
						IupScintillaSendMessage( cSci.getIupScintilla, 2205, 0x00FFFF, 0 ); //SCI_CALLTIPSETBACK 2205
						IupScintillaSendMessage( cSci.getIupScintilla, 2200, currentPos, cast(int) GLOBAL.cString.convert( _list ) ); // SCI_CALLTIPSHOW 2200
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

		/+
		static CASTnode getFunctionAST( CASTnode head, int _kind, char[] functionTitle, int line )
		{
			foreach_reverse( CASTnode node; head.getChildren() )
			{
				if( node.kind & _kind )
				{
					if( node.name == functionTitle )
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
			/+
			if( result.length )
			{
				code = D_FUNCTION;//B_SUB;
			}
			else
			{
				result = searchHead( iupSci, pos, "function" );
				if( result.length )
				{
					code = D_FUNCTION;
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
			+/
			return result;
		}
		+/
		
		static bool callAutocomplete( Ihandle *ih, int pos, char[] text, char[] alreadyInput, bool bForce = false )
		{
			auto cSci = ScintillaAction.getCScintilla( ih );
			if( cSci is null ) return false;
			switch( text )
			{
				case "(", ")", ",", ":", ".":	
					cSci.lastPos = -99;
					break;
					
				default:
					if( cSci.lastPos == pos - 1 )
					{
						cSci.lastPos = pos;
						return false;
					}
			}		

			if( !bForce )
			{
				try
				{
					if( text == "(" )
					{
						if( alreadyInput.length )
						{
							if( alreadyInput[$-1] == ' ' ) // Check if Short-Cut Trigger
							{
								if( showCallTipThread is null )
								{
									showCallTipThread = new CShowListThread( ih, pos, text, 1 );
									showCallTipThread.start();
									
									if( fromStringz( IupGetAttribute( timer, "RUN" ) ) != "YES" ) IupSetAttribute( timer, "RUN", "YES" );
								}
							}
						}
					}
					else
					{
						if( showListThread is null )
						{
							showListThread = new CShowListThread( ih, pos, text );
							showListThread.start();
							
							if( fromStringz( IupGetAttribute( timer, "RUN" ) ) != "YES" ) IupSetAttribute( timer, "RUN", "YES" );
							
							// CodeComplete is high priority than CallTip, Stop showCallTipThread
							if( showCallTipThread !is null ) showCallTipThread.stop;
						}
						else
						{
							if( text == "," || text == ";" ) showListThread.stop();
						}						
					}
				}
				catch( Exception e )
				{
					IupMessage("ERROR","");
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
						if( fromStringz( IupGetAttribute( ih, "AUTOCACTIVE\0" ) ) == "YES" ) IupSetAttribute( ih, "AUTOCCANCEL\0", "YES\0" );

						IupScintillaSendMessage( ih, 2205, actionManager.ToolAction.convertIupColor( GLOBAL.editColor.callTip_Back.toDString ), 0 ); // SCI_CALLTIPSETBACK 2205
						IupScintillaSendMessage( ih, 2206, actionManager.ToolAction.convertIupColor( GLOBAL.editColor.callTip_Fore.toDString ), 0 ); // SCI_CALLTIPSETFORE 2206
						
						//SCI_CALLTIPSETHLT 2204
						IupScintillaSendMessage( ih, 2200, pos, cast(int) GLOBAL.cString.convert( list ) );
						
						if( calltipContainer !is null )	calltipContainer.push( Integer.toString( ScintillaAction.getLinefromPos( ih, pos ) ) ~ ";" ~ list );
						
						int highlightStart, highlightEnd;
						callTipSetHLT( list, 1, highlightStart, highlightEnd );
						if( highlightEnd > -1 ) IupScintillaSendMessage( ih, 2204, highlightStart, highlightEnd ); // SCI_CALLTIPSETHLT 2204
					}
					else
					{
						if( !alreadyInput.length ) IupScintillaSendMessage( ih, 2100, alreadyInput.length - 1, cast(int) GLOBAL.cString.convert( list ) ); else IupSetAttributeId( ih, "AUTOCSHOW", alreadyInput.length - 1, GLOBAL.cString.convert( list ) );
					}
					cSci.lastPos = -99;
					return true;
				}
				else
				{
					cSci.lastPos = pos;
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
			
		
			if( calltipContainer !is null )
			{
				// debug GLOBAL.IDEMessageDlg.print( "calltipContainer Size: " ~ Integer.toString( calltipContainer.size ) );
				
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
					calltipContainer.pop();
					if( cast(int) IupScintillaSendMessage( ih, 2202, 0, 0 ) == 1 ) IupScintillaSendMessage( ih, 2201, 0, 0 ); //  SCI_CALLTIPCANCEL 2201 , SCI_CALLTIPACTIVE 2202
					return false;
				}



				// Last time we get null "List" at same line and same procedureNameFromDocument, leave!!!!!
				if( noneListProcedureName == Integer.toString( firstOpenParenPosFromDocument ) ~ ";" ~ procedureNameFromDocument ) return false;
		
		
		
		
				char[]	list;
				char[]	listInContainer = calltipContainer.top();
				
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
									
									showCallTipThread = new CShowListThread( ih, firstOpenParenPosFromDocument, "(", commaCount, procedureNameFromDocument );
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
							if( calltipContainer !is null )	calltipContainer.push( Integer.toString( ScintillaAction.getLinefromPos( ih, pos ) ) ~ ";" ~ list );
						}
					}
				}
				
				if( !bContinue )
				{
					if( calltipContainer !is null )	
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
				}
				
				
				if( !bContinue )
				{
					if( calltipContainer !is null )
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
							IupScintillaSendMessage( ih, 2205, actionManager.ToolAction.convertIupColor( GLOBAL.editColor.callTip_Back.toDString ), 0 ); // SCI_CALLTIPSETBACK 2205
							IupScintillaSendMessage( ih, 2206, actionManager.ToolAction.convertIupColor( GLOBAL.editColor.callTip_Fore.toDString ), 0 ); // SCI_CALLTIPSETFORE 2206
							
							IupScintillaSendMessage( ih, 2200, pos, cast(int) GLOBAL.cString.convert( list ) );
							
							if( calltipContainer !is null )	calltipContainer.push( Integer.toString( ScintillaAction.getLinefromPos( ih, pos ) ) ~ ";" ~ list );
						}
					
						if( cast(int) IupScintillaSendMessage( ih, 2202, 0, 0 ) == 1 )
						{
							int highlightStart, highlightEnd;
							
							//GLOBAL.IDEMessageDlg.print( "commaCount: " ~ Integer.toString( commaCount ) );
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
								if( cast(int) IupScintillaSendMessage( ih, 2202, 0, 0 ) == 1 ) IupScintillaSendMessage( ih, 2201, 1, 0 ); //  SCI_CALLTIPCANCEL 2201 , SCI_CALLTIPACTIVE 2202
							}
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
			/*
			GLOBAL.IDEMessageDlg.print( "procedureName = " ~ procedureNameFromDocument );
			GLOBAL.IDEMessageDlg.print( "Char = " ~ fromStringz( IupGetAttributeId( ih, "CHAR", pos ) ) );
			GLOBAL.IDEMessageDlg.print( "commaCount = " ~ Integer.toString( commaCount ) );
			*/
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
							
							/+
							if( lastChar == "(" ) _alreadyInput = AutoComplete.getWholeWordReverse( sci, _pos - 1, dummyHeadPos ).reverse; else _alreadyInput = AutoComplete.getWholeWordReverse( sci, _pos, dummyHeadPos ).reverse;
						
							char[][] splitWord = AutoComplete.getDivideWord( _alreadyInput );
							_alreadyInput = splitWord[$-1];									
						
							if( lastChar == "(" )
							{
								IupScintillaSendMessage( sci, 2205, actionManager.ToolAction.convertIupColor( GLOBAL.editColor.callTip_Back.toDString ), 0 ); // SCI_CALLTIPSETBACK 2205
								IupScintillaSendMessage( sci, 2206, actionManager.ToolAction.convertIupColor( GLOBAL.editColor.callTip_Fore.toDString ), 0 ); // SCI_CALLTIPSETFORE 2206
								IupScintillaSendMessage( sci, 2200, _pos, cast(int) GLOBAL.cString.convert( AutoComplete.showListThread.getResult ) );
								
								if( AutoComplete.calltipContainer !is null ) AutoComplete.calltipContainer.push( Integer.toString( ScintillaAction.getLinefromPos( sci, _pos ) ) ~ ";" ~ AutoComplete.showListThread.getResult );
								
								int highlightStart, highlightEnd;
								AutoComplete.callTipSetHLT( AutoComplete.showListThread.getResult, 1, highlightStart, highlightEnd );
								if( highlightEnd > -1 ) IupScintillaSendMessage( sci, 2204, highlightStart, highlightEnd ); // SCI_CALLTIPSETHLT 2204
							}
							else
							{
							+/
								if( cast(int) IupScintillaSendMessage( sci, 2202, 0, 0 ) == 1 ) IupScintillaSendMessage( sci, 2201, 0, 0 ); //  SCI_CALLTIPCANCEL 2201 , SCI_CALLTIPACTIVE 2202
								
								if( _alreadyInput.length )
									IupScintillaSendMessage( sci, 2100, _alreadyInput.length, cast(int) GLOBAL.cString.convert( AutoComplete.showListThread.getResult ) );
								else
									IupScintillaSendMessage( sci, 2100, 0, cast(int) GLOBAL.cString.convert( AutoComplete.showListThread.getResult ) );
							//}
							auto cSci = ScintillaAction.getActiveCScintilla();
							if( cSci !is null ) cSci.lastPos = -99;
						}
					}
				}
				else
				{
					auto cSci = ScintillaAction.getActiveCScintilla();
					if( cSci !is null ) cSci.lastPos = ScintillaAction.getCurrentPos( cSci.getIupScintilla );
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
							//if( cast(int) IupScintillaSendMessage( sci, 2202, 0, 0 ) == 0 )
							//{
								int		_pos = ScintillaAction.getCurrentPos( sci );
								
								if( cast(int) IupScintillaSendMessage( sci, 2202, 0, 0 ) == 1 ) IupScintillaSendMessage( sci, 2201, 0, 0 ); //  SCI_CALLTIPCANCEL 2201 , SCI_CALLTIPACTIVE 2202

								IupScintillaSendMessage( sci, 2205, actionManager.ToolAction.convertIupColor( GLOBAL.editColor.callTip_Back.toDString ), 0 ); // SCI_CALLTIPSETBACK 2205
								IupScintillaSendMessage( sci, 2206, actionManager.ToolAction.convertIupColor( GLOBAL.editColor.callTip_Fore.toDString ), 0 ); // SCI_CALLTIPSETFORE 2206
								IupScintillaSendMessage( sci, 2200, _pos, cast(int) GLOBAL.cString.convert( AutoComplete.showCallTipThread.getResult ) );
								
								if( AutoComplete.calltipContainer !is null ) AutoComplete.calltipContainer.push( Integer.toString( ScintillaAction.getLinefromPos( sci, _pos ) ) ~ ";" ~ AutoComplete.showCallTipThread.getResult );
								
								int highlightStart, highlightEnd;
								AutoComplete.callTipSetHLT( AutoComplete.showCallTipThread.getResult, AutoComplete.showCallTipThread.ext, highlightStart, highlightEnd );
								if( highlightEnd > -1 ) IupScintillaSendMessage( sci, 2204, highlightStart, highlightEnd ); // SCI_CALLTIPSETHLT 2204
								
								AutoComplete.noneListProcedureName = "";
								auto cSci = ScintillaAction.getActiveCScintilla();
								if( cSci !is null ) cSci.lastPos = -99;
							//}
						}
					}
				}
				else
				{
					AutoComplete.noneListProcedureName = Integer.toString( AutoComplete.showCallTipThread.pos ) ~ ";" ~ AutoComplete.showCallTipThread.extString;
					//AutoComplete.cleanCalltipContainer();
					auto cSci = ScintillaAction.getActiveCScintilla();
					if( cSci !is null ) cSci.lastPos = ScintillaAction.getCurrentPos( cSci.getIupScintilla );
				}

				delete AutoComplete.showCallTipThread;
				AutoComplete.showListThread = null;
			}
		}		
		
		if( AutoComplete.showListThread is null && AutoComplete.showCallTipThread is null )	IupSetAttribute( _ih, "RUN", "NO" );
		
		return IUP_IGNORE;
	}	
}