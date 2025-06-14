﻿module parser.live;

struct LiveParser
{
	private:
	import iup.iup, iup.iup_scintilla;
	import global, actionManager, menu;
	import tools;
	import parser.ast, parser.autocompletion;
	import std.string, Conv = std.conv, Uni = std.uni;
	version(Posix) import core.sys.posix.stdlib;

	static CASTnode delChildrenByLineNum( CASTnode head, int fixedLn )
	{
		try
		{
			if( head.lineNumber <= fixedLn && head.endLineNum > fixedLn )
			{
				bool		bMatched;
				CASTnode[]	beAliveNodes, beKillNodes;


				foreach_reverse( CASTnode child; head.getChildren() )
				{
					if( child.getChildrenCount > 0 )
					{
						if( child.lineNumber < fixedLn )
						{
							CASTnode matchedNode = delChildrenByLineNum( child, fixedLn );
							if( matchedNode !is null ) return matchedNode;
						}
					}

					if( fixedLn == child.lineNumber )
					{
						bMatched = true;
						beKillNodes ~= child;
					}
					else if( fixedLn > child.endLineNum )
					{
						if( !bMatched ) return head;
						beAliveNodes ~= child;
					}
					else
					{
						beAliveNodes ~= child;
					}
				}

				if( bMatched )
				{
					foreach( CASTnode _node; beKillNodes )
						destroy( _node );

					head.zeroChildCount();
					foreach_reverse( CASTnode _node; beAliveNodes )
						head.addChild( _node );

					return head;
				}
				else
				{
					return head;
				}
			}
		}
		catch( Exception e )
		{
			IupMessage( "", toStringz( "delChildrenByLineNum() Error:\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ Conv.to!(string)( e.line ) ) );
		}

		return null;
	}

	version(FBIDE)
	{
		static bool getBlockPosition( Ihandle* iupSci, int pos, string targetText, out int posHead, out int posEnd )
		{
			int		documentLength = IupGetInt( iupSci, "COUNT" );
			posHead = AutoComplete.getProcedurePos( iupSci, pos, targetText );
			if( posHead >= 0 )
			{
				//IupMessage( "targetText",toStringz( targetText ));
				int	LineNum = cast(int) IupScintillaSendMessage( iupSci, 2166, posHead, 0 ) + 1; //SCI_LINEFROMPOSITION = 2166,
				//IupMessage( "targetText LineNum",toStringz( Integer.toString( LineNum ) ));
				
				posEnd = AutoComplete.getProcedureTailPos( iupSci, pos, targetText, 0 );

				LineNum = cast(int) IupScintillaSendMessage( iupSci, 2166, posEnd, 0 ) + 1; //SCI_LINEFROMPOSITION = 2166,
				//IupMessage( "targetText Tail LineNum",toStringz( Integer.toString( LineNum ) ));
				
				if( posEnd > posHead ) return false;

				posEnd = AutoComplete.getProcedureTailPos( iupSci, pos, targetText, 1 );
				LineNum = cast(int) IupScintillaSendMessage( iupSci, 2166, posEnd, 0 ) + 1; //SCI_LINEFROMPOSITION = 2166,
				//IupMessage( "Re targetText Tail LineNum",toStringz( Integer.toString( LineNum ) ));
			
				if( posEnd > posHead ) return true;
			}

			return false;
		}
	}
	
	version(DIDE)
	{
		static bool getBlockPosition( Ihandle* iupSci, int pos, int oldLineHead, out int posHead, out int posEnd )
		{
			posEnd = AutoComplete.skipCommentAndString( iupSci, pos, "}", 1 );

			if( posEnd > -1 ) posHead = IupGetIntId( iupSci, "BRACEMATCH", posEnd );


			if( posHead >= 0 && posEnd >= 0 && posEnd > posHead )
			{
				int		functionPos = posHead - 1;
				string	functionWord = fSTRz( IupGetAttributeId( iupSci, "CHAR", functionPos ) );
				while( functionWord == " " || functionWord == "\t" || functionWord == "\n" )
				{
					functionPos --;
					functionWord = fSTRz( IupGetAttributeId( iupSci, "CHAR", functionPos ) );
				}
				
				int lineHead = cast(int) IupScintillaSendMessage( iupSci, 2166, functionPos, 0 ) + 1; //SCI_LINEFROMPOSITION = 2166,

				while( lineHead > oldLineHead  )
				{
					posHead = AutoComplete.skipCommentAndString( iupSci, posHead - 1, "{", 0 );
					if( posHead > -1 )
					{
						posEnd = IupGetIntId( iupSci, "BRACEMATCH", posHead );
						if( posEnd > -1 )
						{
							functionPos = posHead - 1;
							functionWord = fSTRz( IupGetAttributeId( iupSci, "CHAR", functionPos ) );
							while( functionWord == " " || functionWord == "\t" || functionWord == "\n" )
							{
								functionPos --;
								functionWord = fSTRz( IupGetAttributeId( iupSci, "CHAR", functionPos ) );
							}
							
							lineHead = cast(int) IupScintillaSendMessage( iupSci, 2166, functionPos, 0 ) + 1; //SCI_LINEFROMPOSITION = 2166,
						}
						else
						{
							break;
						}
					}
					else
					{
						break;
					}
				}

				if( lineHead == oldLineHead ) return true;
			}

			// No Match, Should be Reparse All Module
			posHead = 0;
			posEnd =  IupGetInt( iupSci, "COUNT" ) - 1;
			return false;
		}
	}

	public:
	
	static void lineNumberAdd( CASTnode head, int fixeLn, int n = 1 )
	{
		if( head !is null )
		{
			if( head.getChildrenCount )
			{
				foreach( CASTnode node; head.getChildren )
				{
					lineNumberAdd( node, fixeLn, n );
				}
			}

			if( head.getFather !is null )
			{
				if( head.lineNumber > fixeLn )
				{
					head.lineNumber += n;
					head.endLineNum += n;
				}
				else if( head.endLineNum > fixeLn )
				{
					if( head.endLineNum + n <= 2147483647 ) head.endLineNum += n;
				}
			}
		}
	}

	static void parseCurrentLine( int _ln = -1, string _text = "" )
	{
		try
		{
			auto cSci = ScintillaAction.getActiveCScintilla();
			if( cSci !is null )
			{
				string	currentLineText;
				int		currentLineNum;

				if( _text.length )
				{
					currentLineText = _text;
					currentLineNum = _ln;
				}
				else
				{
					int currentPos = ScintillaAction.getCurrentPos( cSci.getIupScintilla );
					currentLineNum = ( _ln != -1 ) ? _ln : cast(int) IupScintillaSendMessage( cSci.getIupScintilla, 2166, currentPos, 0 ) + 1;
					currentLineText = ( _ln != -1 ) ? fromStringz( IupGetAttributeId( cSci.getIupScintilla, "LINE", _ln - 1 ) ).dup : fromStringz( IupGetAttribute( cSci.getIupScintilla, "LINEVALUE" ) ).dup;
				}
				
				int	lineHeadPostion = cast(int) IupScintillaSendMessage( cSci.getIupScintilla, 2167, currentLineNum - 1, 0 );
				int currentLineTextLength = cast(int) strip( currentLineText).length;
			
				CASTnode 	oldHead = ParserAction.getActiveASTFromLine( ParserAction.getActiveParseAST(), currentLineNum );
				if( oldHead is null ) return;
					
				
				bool		bInTypeBody;
				CASTnode	newHead, _oldHead = oldHead;
				
				version(FBIDE)
				{
					if( _oldHead.lineNumber < currentLineNum )
					{
						while( _oldHead !is null )
						{
							if( _oldHead.kind & ( B_TYPE | B_CLASS | B_UNION ) )
							{
								bInTypeBody = true;
								newHead = GLOBAL.outlineTree.parserTextUnderTypeBody( currentLineText );
								break;
							}
							_oldHead = _oldHead.getFather();
						}
					}
				}

				if( !bInTypeBody ) newHead = GLOBAL.outlineTree.parserText( currentLineText );

				if( newHead !is null )
				{
					// Parse one line is not complete, EX: one line is function head: function DynamicArray.init( _size as integer ) as TokenUnit ptr
					if( newHead.endLineNum < 2147483647 )
					{
						destroy( newHead );
						return;
					}

					// Parse complete, but no any result
					if( newHead.getChildrenCount == 0 )
					{
						destroy( newHead );
						if( GLOBAL.parserSettings.toggleUpdateOutlineLive == "ON" )
						{
							Ihandle* actTree = GLOBAL.outlineTree.getActiveTree();
							GLOBAL.outlineTree.removeNodeAndGetInsertIndexByLineNumber( currentLineNum );
						}
						return;
					}
					
					/+
					// Check ParsedTree HEAD, like B_BAS / B_BI
					if( oldHead.getChildrenCount == 0 )
					{
						if( oldHead.getFather is null ) 
						{
							delete newHead;
							GLOBAL.outlineTree.refresh( cSci );
							return;
						}
					}
					+/

					CASTnode[] newChildren;
					foreach( CASTnode node; newHead.getChildren() )
					{
						node.lineNumber = currentLineNum;
						node.endLineNum = node.lineNumber;
						newChildren ~= node;
					}

					if( newChildren.length )
					{
						int insertID;
						if( GLOBAL.parserSettings.toggleUpdateOutlineLive == "ON" ) insertID = GLOBAL.outlineTree.removeNodeAndGetInsertIndexByLineNumber( currentLineNum );

						oldHead = delChildrenByLineNum( oldHead, currentLineNum );

						if( oldHead !is null )
						{
							foreach( CASTnode node; newChildren )
								oldHead.insertChildByLineNumber( node, node.lineNumber );

							if( GLOBAL.parserSettings.toggleUpdateOutlineLive == "ON" ) GLOBAL.outlineTree.insertNodeByLineNumber( newChildren, insertID );

							newHead.zeroChildCount();
						}
					}
					
					destroy( newHead );
				}
				else // If No any tokens, parser will return null ( GLOBAL.Parser.updateTokens() return false)
				{
					GLOBAL.outlineTree.removeNodeAndGetInsertIndexByLineNumber( currentLineNum );
					oldHead = delChildrenByLineNum( oldHead, currentLineNum );
				}
			}
		}
		catch( Exception e )
		{
			IupMessage( "", toStringz( "parseCurrentLine() Error:\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ Conv.to!(string)( e.line ) ) );
		}
	}

	version(FBIDE)
	{
		static void parseCurrentBlock()
		{
			try
			{
				auto cSci = ScintillaAction.getActiveCScintilla();
				if( cSci !is null )
				{
					int currentPos = ScintillaAction.getCurrentPos( cSci.getIupScintilla );

					if( ScintillaAction.isComment( cSci.getIupScintilla, currentPos ) ) return;

					int		posHead, posTail;
					if( !getBlockPosition( cSci.getIupScintilla, currentPos, "sub", posHead, posTail ) )
						if( !getBlockPosition( cSci.getIupScintilla, currentPos, "function", posHead, posTail ) )
							if( !getBlockPosition( cSci.getIupScintilla, currentPos, "property", posHead, posTail ) )
								if( !getBlockPosition( cSci.getIupScintilla, currentPos, "operator", posHead, posTail ) )
									if( !getBlockPosition( cSci.getIupScintilla, currentPos, "type", posHead, posTail ) )
										if( !getBlockPosition( cSci.getIupScintilla, currentPos, "union", posHead, posTail ) )
											if( !getBlockPosition( cSci.getIupScintilla, currentPos, "enum", posHead, posTail ) )
												if( !getBlockPosition( cSci.getIupScintilla, currentPos, "constructor", posHead, posTail ) )
													if( !getBlockPosition( cSci.getIupScintilla, currentPos, "destructor", posHead, posTail ) )
													{
														posHead = 0;
														posTail = IupGetInt( cSci.getIupScintilla, "COUNT" ) - 1;
													}
					string _char;
					while( posHead > 0 )
					{
						_char = fSTRz( IupGetAttributeId( cSci.getIupScintilla, "CHAR", --posHead ) );
						if( _char == "\n" || _char == ":" )
						{
							posHead ++;
							break;
						}
					}

					if( posHead == 0 )
					{
						GLOBAL.outlineTree.refresh( cSci, ( GLOBAL.parserSettings.toggleUpdateOutlineLive == "ON" ? true : false ) );
						
						int _ln = cast(int) IupScintillaSendMessage( cSci.getIupScintilla, 2166, currentPos, 0 ) + 1;
					
						int pos = IupGetInt( GLOBAL.outlineTree.getZBoxHandle, "VALUEPOS" ); // Get active zbox pos
						Ihandle* actTree = IupGetChild( GLOBAL.outlineTree.getZBoxHandle, pos );

						for( int i = IupGetInt( actTree, "COUNT" ) - 1; i > 0; --i )
						{
							CASTnode _node = cast(CASTnode) IupGetAttributeId( actTree, "USERDATA", i );
							if( _node.lineNumber <= _ln  )
							{
								version(Windows) IupSetAttributeId( actTree, "MARKED", i, "YES" ); else IupSetInt( actTree, "VALUE", i );
								break;
							}
						}			
						return;
					}
					
					IupScintillaSendMessage( cSci.getIupScintilla, 2190, posHead, 0 ); 	// SCI_SETTARGETSTART = 2190,
					IupScintillaSendMessage( cSci.getIupScintilla, 2192, posTail, 0 );	// SCI_SETTARGETEND = 2192,
					
					CASTnode newHead;
					version(Windows)
					{
						auto blockText = new char[posTail-posHead];
						IupScintillaSendMessage( cSci.getIupScintilla, 2687, 0, cast(ptrdiff_t) blockText.ptr );// SCI_GETTARGETTEXT 2687
						newHead = GLOBAL.outlineTree.parserText( blockText.dup );
						destroy( blockText );
					}
					else
					{
						char* blockText = cast(char*)calloc( 1, posTail-posHead );
						IupScintillaSendMessage( cSci.getIupScintilla, 2687, 0, cast(ptrdiff_t) blockText );// SCI_GETTARGETTEXT 2687
						newHead = GLOBAL.outlineTree.parserText( fSTRz( blockText ) );
						free( blockText );
					}
				
					if( newHead !is null )
					{
						CASTnode[]	beAliveNodes;

						if( newHead.getChildrenCount == 0 )
						{
							destroy( newHead );
							return;
						}
						else
						{
							// Parser not complete
							if( newHead.endLineNum < 2147483647 )
							{
								destroy( newHead );
								return;
							}
						}

						int headLine = cast(int) IupScintillaSendMessage( cSci.getIupScintilla, 2166, posHead, 0 ) + 1; //SCI_LINEFROMPOSITION = 2166,
						lineNumberAdd( newHead, newHead[0].lineNumber - 1, headLine - 1 );
						//IupMessage( "newHead", toStringz( newHead[0].name ~ " " ~ newHead[0].type ~ " (" ~ Integer.toString( newHead[0].lineNumber ) ~ ")" ) );

						// Get oringnal head
						if( fullPathByOS( cSci.getFullPath ) in GLOBAL.parserManager )
						{
							CASTnode oldHead = AutoComplete.getFunctionAST( cast(CASTnode) GLOBAL.parserManager[fullPathByOS( cSci.getFullPath )], newHead[0].kind, Uni.toLower( newHead[0].name ), newHead[0].lineNumber );
							//if( oldHead !is null ) IupMessage( "oldHead", toStringz( oldHead.name ~ " " ~oldHead.type ~ " (" ~ Integer.toString( oldHead.lineNumber ) ~ ")" ) ); else IupMessage("","NULL");
							if( oldHead !is null )
							{
								int insertID;
								if( GLOBAL.parserSettings.toggleUpdateOutlineLive == "ON" ) insertID = GLOBAL.outlineTree.removeNodeAndGetInsertIndexByLineNumber( headLine );

								CASTnode father = oldHead.getFather;

								foreach_reverse( CASTnode child; father.getChildren() )
								{
									if( headLine == child.lineNumber )
									{
										destroy( child ); // Equal delete oldHead
									}
									else
									{
										beAliveNodes ~= child;
									}
								}
								father.zeroChildCount();

								//IupMessage( "oldHead", toStringz( oldHead.name ~ " " ~oldHead.type ~ " (" ~ Integer.toString( oldHead.lineNumber ) ~ ")" ) );
								foreach_reverse( CASTnode _node; beAliveNodes )
								{
									father.addChild( _node );
								}
								
								//if( GLOBAL.toggleUpdateOutlineLive == "ON" ) GLOBAL.outlineTree.updateOneLineNodeByNumber( currentLineNum, newChildren );
								father.insertChildByLineNumber( newHead[0], headLine );

								if( GLOBAL.parserSettings.toggleUpdateOutlineLive == "ON" ) GLOBAL.outlineTree.insertBlockNodeByLineNumber( newHead[0], insertID );
								
								newHead.zeroChildCount();
								destroy( newHead );

								return;
							}
						}
						else
						{
							return;
						}

						destroy( newHead );
					}
					else
					{
						//debug IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( Integer.toString(currentLineNum) ~ " " ~ "Parse NUll" ) );
					}
				}
			}
			catch( Exception e )
			{
				IupMessage( "", toStringz( "parseCurrentBlock() Error:\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ Conv.to!(string)( e.line ) ) );
			}
		}
	}
	
	version(DIDE)
	{
		static void parseCurrentBlock()
		{
			try
			{
				auto cSci = ScintillaAction.getActiveCScintilla();
				if( cSci !is null )
				{
					int			currentPos = ScintillaAction.getCurrentPos( cSci.getIupScintilla );
					int			currentLineNum = cast(int) IupScintillaSendMessage( cSci.getIupScintilla, 2166, currentPos, 0 ) + 1; //SCI_LINEFROMPOSITION = 2166,

					if( ScintillaAction.isComment( cSci.getIupScintilla, currentPos ) ) return;

					CASTnode 	newHead, oldHead = ParserAction.getActiveASTFromLine( ParserAction.getActiveParseAST(), currentLineNum );
					int			posHead, posTail;

					if( oldHead !is null )
					{
						if( !getBlockPosition( cSci.getIupScintilla, currentPos, oldHead.lineNumber , posHead, posTail ) )
						{
							//IupMessage("FALSE","");
							// Reparse All
							GLOBAL.outlineTree.refresh( cSci, ( GLOBAL.parserSettings.toggleUpdateOutlineLive == "ON" ? true : false ) );
							
							int _ln = cast(int) IupScintillaSendMessage( cSci.getIupScintilla, 2166, currentPos, 0 ) + 1;
						
							int pos = IupGetInt( GLOBAL.outlineTree.getZBoxHandle, "VALUEPOS" ); // Get active zbox pos
							Ihandle* actTree = IupGetChild( GLOBAL.outlineTree.getZBoxHandle, pos );

							for( int i = IupGetInt( actTree, "COUNT" ) - 1; i > 0; --i )
							{
								CASTnode _node = cast(CASTnode) IupGetAttributeId( actTree, "USERDATA", i );
								if( _node.lineNumber <= _ln  )
								{
									version(Windows) IupSetAttributeId( actTree, "MARKED", i, "YES" ); else IupSetInt( actTree, "VALUE", i );
									break;
								}
							}			

							return;
						}

						posHead -= 1;

						string	functionWord = fSTRz( IupGetAttributeId( cSci.getIupScintilla, "CHAR", posHead ) );
						while( functionWord != ";" && functionWord != "{" && functionWord != "}" )
						{
							functionWord = fSTRz( IupGetAttributeId( cSci.getIupScintilla, "CHAR", --posHead ) );
						}					

						IupSetInt( cSci.getIupScintilla, "TARGETSTART", posHead + 1 );
						IupSetInt( cSci.getIupScintilla, "TARGETEND", posTail + 1 );					
						version(Windows)
						{
							auto blockText = new char[posTail-posHead];
							IupScintillaSendMessage( cSci.getIupScintilla, 2687, 0, cast(ptrdiff_t) blockText.ptr );// SCI_GETTARGETTEXT 2687
							newHead = GLOBAL.outlineTree.parserText( blockText.dup );
							destroy( blockText );
						}
						else
						{
							char* blockText = cast(char*)calloc( 1, posTail-posHead );
							IupScintillaSendMessage( cSci.getIupScintilla, 2687, 0, cast(ptrdiff_t) blockText );// SCI_GETTARGETTEXT 2687
							newHead = GLOBAL.outlineTree.parserText( fSTRz( blockText ) );
							free( blockText );
						}
					}

					if( newHead !is null )
					{
						CASTnode[]	beAliveNodes;

						if( newHead.getChildrenCount == 0 )
						{
							destroy( newHead );
							return;
						}
						else
						{
							// Parser not complete
							if( newHead.endLineNum < 2147483647 )
							{
								destroy( newHead );
								return;
							}
						}

						//IupMessage( "ori - newHead", toStringz( newHead[0].name ~ " " ~ newHead[0].type ~ " (" ~ Integer.toString( newHead[0].lineNumber ) ~ ")" ) );
						int headLine = oldHead.lineNumber;
						lineNumberAdd( newHead, 0, headLine - 1 );
						//IupMessage( "newHead", toStringz( newHead[0].name ~ " " ~ newHead[0].type ~ " (" ~ Integer.toString( newHead[0].lineNumber ) ~ ")" ) );

						if( oldHead !is null )
						{
							int insertID;
							if( GLOBAL.parserSettings.toggleUpdateOutlineLive == "ON" ) insertID = GLOBAL.outlineTree.removeNodeAndGetInsertIndexByLineNumber( headLine );

							CASTnode father = oldHead.getFather;

							foreach_reverse( CASTnode child; father.getChildren() )
							{
								if( headLine == child.lineNumber )
								{
									destroy( child ); // Equal delete oldHead
								}
								else
								{
									beAliveNodes ~= child;
								}
							}
							father.zeroChildCount();

							//IupMessage( "oldHead", toStringz( oldHead.name ~ " " ~oldHead.type ~ " (" ~ Integer.toString( oldHead.lineNumber ) ~ ")" ) );
							foreach_reverse( CASTnode _node; beAliveNodes )
							{
								father.addChild( _node );
							}
							
							//if( GLOBAL.toggleUpdateOutlineLive == "ON" ) GLOBAL.outlineTree.updateOneLineNodeByNumber( currentLineNum, newChildren );
							father.insertChildByLineNumber( newHead[0], headLine );
							
							if( GLOBAL.parserSettings.toggleUpdateOutlineLive == "ON" )
							{
								GLOBAL.outlineTree.insertBlockNodeByLineNumber( newHead[0], insertID );
							}						
							
							newHead.zeroChildCount();
						}

						destroy( newHead );
					}
					else
					{
						//IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( Integer.toString(currentLineNum) ~ " " ~ "Parse NUll" ) );
					}
				}
			}
			catch( Exception e ){}
		}	
	}
}