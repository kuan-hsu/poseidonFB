module parser.live;

struct LiveParser
{
	private:
	import iup.iup;
	import iup.iup_scintilla;

	import global, actionManager, menu;
	import tools;
	import parser.ast, parser.autocompletion;

	import Integer = tango.text.convert.Integer, Util = tango.text.Util;
	import tango.stdc.stringz, tango.io.Stdout;
	import tango.io.FilePath;
	
	import tango.stdc.stdlib, tango.stdc.string;

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
						/*
						if( !bMatched ) bMatched = true;*/
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
						delete _node;

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
			IupMessageError( null, toStringz( "delChildrenByLineNum() Error:\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ Integer.toString( e.line ) ) );
		}

		return null;
	}

	version(FBIDE)
	{
		static bool getBlockPosition( Ihandle* iupSci, int pos, char[] targetText, out int posHead, out int posEnd )
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
				char[]	functionWord = fromStringz( IupGetAttributeId( iupSci, "CHAR", functionPos ) );
				while( functionWord == " " || functionWord == "\t" || functionWord == "\n" )
				{
					functionPos --;
					functionWord = fromStringz( IupGetAttributeId( iupSci, "CHAR", functionPos ) );
				}
				
				int lineHead = IupScintillaSendMessage( iupSci, 2166, functionPos, 0 ) + 1; //SCI_LINEFROMPOSITION = 2166,

				while( lineHead > oldLineHead  )
				{
					posHead = AutoComplete.skipCommentAndString( iupSci, posHead - 1, "{", 0 );
					if( posHead > -1 )
					{
						posEnd = IupGetIntId( iupSci, "BRACEMATCH", posHead );
						if( posEnd > -1 )
						{
							functionPos = posHead - 1;
							functionWord = fromStringz( IupGetAttributeId( iupSci, "CHAR", functionPos ) );
							while( functionWord == " " || functionWord == "\t" || functionWord == "\n" )
							{
								functionPos --;
								functionWord = fromStringz( IupGetAttributeId( iupSci, "CHAR", functionPos ) );
							}
							
							lineHead = IupScintillaSendMessage( iupSci, 2166, functionPos, 0 ) + 1; //SCI_LINEFROMPOSITION = 2166,
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

	static void parseCurrentLine( int _ln = -1 )
	{
		try
		{
			auto cSci = ScintillaAction.getActiveCScintilla();
			if( cSci !is null )
			{
				int currentPos = ScintillaAction.getCurrentPos( cSci.getIupScintilla );

				if( ScintillaAction.isComment( cSci.getIupScintilla, currentPos ) ) return;
				
				int	currentLineNum; // = cast(int) IupScintillaSendMessage( cSci.getIupScintilla, 2166, currentPos, 0 ) + 1; //SCI_LINEFROMPOSITION = 2166,
				char[] currentLineText; // = fromStringz( IupGetAttribute( cSci.getIupScintilla, "LINEVALUE" ) ).dup;
				
				if( _ln != -1 )
				{
					currentLineNum = _ln;
					currentLineText = fromStringz( IupGetAttributeId( cSci.getIupScintilla, "LINE", _ln - 1 ) ).dup; // 0 BASE
				}
				else
				{
					currentLineNum = cast(int) IupScintillaSendMessage( cSci.getIupScintilla, 2166, currentPos, 0 ) + 1; //SCI_LINEFROMPOSITION = 2166,
					currentLineText = fromStringz( IupGetAttribute( cSci.getIupScintilla, "LINEVALUE" ) ).dup;
				}
				
				if( !Util.trim( currentLineText).length ) return;
			
				
				CASTnode 	oldHead = ParserAction.getActiveASTFromLine( ParserAction.getActiveParseAST(), currentLineNum );

				if( oldHead is null ) return;

				/*
				version(DIDE)
				{
					int			D_KIND;

					if( D_KIND & ( D_STRUCT | D_CLASS | D_UNION | D_ENUM ) )
					{
						if( oldHead.lineNumber == oldHead.endLineNum ) return; // Not Complete Block
						newHead = GLOBAL.outlineTree.parserText( currentLineText );
					}
					else
					{
						newHead = GLOBAL.outlineTree.parserText( currentLineText );
					}
				}
				*/
				
				CASTnode	newHead = GLOBAL.outlineTree.parserText( currentLineText );

				if( newHead !is null )
				{
					// Parse one line is not complete, EX: one line is function head: function DynamicArray.init( _size as integer ) as TokenUnit ptr
					if( newHead.endLineNum < 2147483647 )
					{
						delete newHead;
						return;
					}

					// Parse complete, but no any result
					if( newHead.getChildrenCount == 0 )
					{
						delete newHead;
						if( GLOBAL.toggleUpdateOutlineLive == "ON" )
						{
							Ihandle* actTree = GLOBAL.outlineTree.getActiveTree();
							GLOBAL.outlineTree.removeNodeAndGetInsertIndexByLineNumber( currentLineNum );
							if( GLOBAL.editorSetting01.OutlineFlat == "ON" ) IupSetInt( actTree, "VISIBLE", 1 );
						}
						return;
					}

					// 
					if( oldHead.getChildrenCount == 0 )
					{
						delete newHead;
						GLOBAL.outlineTree.refresh( cSci );
						return;
					}

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
						if( GLOBAL.toggleUpdateOutlineLive == "ON" ) insertID = GLOBAL.outlineTree.removeNodeAndGetInsertIndexByLineNumber( currentLineNum );

						oldHead = delChildrenByLineNum( oldHead, currentLineNum );

						if( oldHead !is null )
						{
							foreach( CASTnode node; newChildren )
								oldHead.insertChildByLineNumber( node, node.lineNumber );

							if( GLOBAL.toggleUpdateOutlineLive == "ON" ) GLOBAL.outlineTree.insertNodeByLineNumber( newChildren, insertID );

							newHead.zeroChildCount();
						}
					}
					
					delete newHead;
				}
				else
				{
				}
			}
		}
		catch( Exception e )
		{
			IupMessageError( null, toStringz( "parseCurrentLine() Error:\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ Integer.toString( e.line ) ) );
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
					char[] _char;
					while( posHead > 0 )
					{
						_char = fromStringz( IupGetAttributeId( cSci.getIupScintilla, "CHAR", --posHead ) );
						if( _char == "\n" || _char == ":" )
						{
							posHead ++;
							break;
						}
					}

					if( posHead == 0 )
					{
						GLOBAL.outlineTree.refresh( cSci );
						
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
						/*				
						int	id = IupGetInt( GLOBAL.outlineTree.getActiveTree, "VALUE" ); // Get Focus TreeNode
						
						if( !GLOBAL.outlineTree.softRefresh( cSci ) ) actionManager.OutlineAction.refresh( cSci.getFullPath() );

						IupSetAttributeId( GLOBAL.outlineTree.getActiveTree, "MARKED", id, "YES" );
						GLOBAL.outlineTree.markTreeNode( IupScintillaSendMessage( cSci.getIupScintilla, 2166, currentPos, 0 ) + 1 );
						*/
						return;
					}
					
					//IupSetInt( cSci.getIupScintilla, "TARGETSTART", posHead );
					IupScintillaSendMessage( cSci.getIupScintilla, 2190, posHead, 0 ); 	// SCI_SETTARGETSTART = 2190,
					//IupSetInt( cSci.getIupScintilla, "TARGETEND", posTail );
					IupScintillaSendMessage( cSci.getIupScintilla, 2192, posTail, 0 );	// SCI_SETTARGETEND = 2192,
					
					CASTnode newHead;
					version(Windows)
					{
						auto blockText = new char[posTail-posHead];
						IupScintillaSendMessage( cSci.getIupScintilla, 2687, 0, cast(int) blockText.ptr );// SCI_GETTARGETTEXT 2687
						newHead = GLOBAL.outlineTree.parserText( blockText );
						delete blockText;
					}
					else
					{
						char* blockText = cast(char*)calloc( 1, posTail-posHead );
						IupScintillaSendMessage( cSci.getIupScintilla, 2687, 0, cast(int) blockText );// SCI_GETTARGETTEXT 2687
						newHead = GLOBAL.outlineTree.parserText( fromStringz( blockText ) );
						free( blockText );
					}
					//IupMessage( "", toStringz( blockText ) );
				
					if( newHead !is null )
					{
						CASTnode[]	beAliveNodes;


						if( newHead.getChildrenCount == 0 )
						{
							delete newHead;
							return;
						}
						else
						{
							// Parser not complete
							if( newHead.endLineNum < 2147483647 )
							{
								delete newHead;
								return;
							}
							/+
							// DelNode
							if( !newHead[0].getChildrenCount )
							{
								if( GLOBAL.toggleUpdateOutlineLive == "ON" )
								{
									if( IupGetChildCount( GLOBAL.outlineTree.getZBoxHandle ) > 0 )
									{
										int pos = IupGetInt( GLOBAL.outlineTree.getZBoxHandle, "VALUEPOS" ); // Get active zbox pos
										Ihandle* actTree = IupGetChild( GLOBAL.outlineTree.getZBoxHandle, pos );
										int _ln = cast(int) IupScintillaSendMessage( cSci.getIupScintilla, 2166, posHead, 0 ) + 1;

										for( int i = IupGetInt( actTree, "COUNT" ) - 1; i > 0; --i )
										{
											CASTnode _node = cast(CASTnode) IupGetAttributeId( actTree, "USERDATA", i );
											if( _node.lineNumber == _ln && lowerCase( _node.name ) == lowerCase( newHead[0].name ) )
											{
												IupSetAttributeId( actTree, "DELNODE", i, "CHILDREN" );
												break;
											}
										}
									}
								}
								delete newHead;
								return;
							}
							+/
						}

						int headLine = cast(int) IupScintillaSendMessage( cSci.getIupScintilla, 2166, posHead, 0 ) + 1; //SCI_LINEFROMPOSITION = 2166,
						lineNumberAdd( newHead, newHead[0].lineNumber - 1, headLine - 1 );
						//IupMessage( "newHead", toStringz( newHead[0].name ~ " " ~ newHead[0].type ~ " (" ~ Integer.toString( newHead[0].lineNumber ) ~ ")" ) );

						// Get oringnal head
						if( fullPathByOS( cSci.getFullPath ) in GLOBAL.parserManager )
						{
							CASTnode oldHead = AutoComplete.getFunctionAST( GLOBAL.parserManager[fullPathByOS( cSci.getFullPath )], newHead[0].kind, lowerCase( newHead[0].name ), newHead[0].lineNumber );
							//if( oldHead !is null ) IupMessage( "oldHead", toStringz( oldHead.name ~ " " ~oldHead.type ~ " (" ~ Integer.toString( oldHead.lineNumber ) ~ ")" ) ); else IupMessage("","NULL");
							if( oldHead !is null )
							{
								int insertID;
								if( GLOBAL.toggleUpdateOutlineLive == "ON" ) insertID = GLOBAL.outlineTree.removeNodeAndGetInsertIndexByLineNumber( headLine );

								CASTnode	father = oldHead.getFather;

								foreach_reverse( CASTnode child; father.getChildren() )
								{
									if( headLine == child.lineNumber )
									{
										delete child; // Equal delete oldHead
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

								if( GLOBAL.toggleUpdateOutlineLive == "ON" ) GLOBAL.outlineTree.insertBlockNodeByLineNumber( newHead[0], insertID );
								
								newHead.zeroChildCount();
								delete newHead;

								return;
							}
						}
						else
						{
							return;
						}

						delete newHead;
					}
					else
					{
						//debug IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( Integer.toString(currentLineNum) ~ " " ~ "Parse NUll" ) );
					}
				}
			}
			catch( Exception e )
			{
				IupMessageError( null, toStringz( "parseCurrentBlock() Error:\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ Integer.toString( e.line ) ) );
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
					int			currentLineNum = IupScintillaSendMessage( cSci.getIupScintilla, 2166, currentPos, 0 ) + 1; //SCI_LINEFROMPOSITION = 2166,

					if( ScintillaAction.isComment( cSci.getIupScintilla, currentPos ) ) return;

					CASTnode 	newHead, oldHead = ParserAction.getActiveASTFromLine( ParserAction.getActiveParseAST(), currentLineNum );
					int			posHead, posTail;

					if( oldHead !is null )
					{
						if( !getBlockPosition( cSci.getIupScintilla, currentPos, oldHead.lineNumber , posHead, posTail ) )
						{
							//IupMessage("FALSE","");
							// Reparse All
							GLOBAL.outlineTree.refresh( cSci );
							
							int _ln = IupScintillaSendMessage( cSci.getIupScintilla, 2166, currentPos, 0 ) + 1;
						
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

						char[]	functionWord = fromStringz( IupGetAttributeId( cSci.getIupScintilla, "CHAR", posHead ) );
						while( functionWord != ";" && functionWord != "{" && functionWord != "}" )
						{
							functionWord = fromStringz( IupGetAttributeId( cSci.getIupScintilla, "CHAR", --posHead ) );
						}					

						IupSetInt( cSci.getIupScintilla, "TARGETSTART", posHead + 1 );
						IupSetInt( cSci.getIupScintilla, "TARGETEND", posTail + 1 );					

						version(Windows)
						{
							scope blockText = new char[posTail-posHead];
							IupScintillaSendMessage( cSci.getIupScintilla, 2687, 0, cast(int) blockText.ptr );// SCI_GETTARGETTEXT 2687
							//IupMessage( "", toStringz( blockText ) );
							newHead = GLOBAL.outlineTree.parserText( Util.trim( blockText ) );
						}
						else
						{
							char* blockText = cast(char*)calloc( 1, posTail-posHead );
							IupScintillaSendMessage( cSci.getIupScintilla, 2687, 0, cast(int) blockText );// SCI_GETTARGETTEXT 2687
							newHead = GLOBAL.outlineTree.parserText( Util.trim( fromStringz( blockText ) ) );
							free( blockText );
						}
					}

					//IupMessage("TRUE","");

					if( newHead !is null )
					{
						CASTnode[]	beAliveNodes;


						if( newHead.getChildrenCount == 0 )
						{
							delete newHead;
							return;
						}
						else
						{
							// Parser not complete
							if( newHead.endLineNum < 2147483647 )
							{
								delete newHead;
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
							if( GLOBAL.toggleUpdateOutlineLive == "ON" ) insertID = GLOBAL.outlineTree.removeNodeAndGetInsertIndexByLineNumber( headLine );

							CASTnode	father = oldHead.getFather;

							foreach_reverse( CASTnode child; father.getChildren() )
							{
								if( headLine == child.lineNumber )
								{
									delete child; // Equal delete oldHead
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
							
							if( GLOBAL.toggleUpdateOutlineLive == "ON" )
							{
								GLOBAL.outlineTree.insertBlockNodeByLineNumber( newHead[0], insertID );
								/+
								GLOBAL.outlineTree.refresh( cSci );
								
								int _ln = IupScintillaSendMessage( cSci.getIupScintilla, 2166, currentPos, 0 ) + 1;
							
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
								+/
							}						
							
							newHead.zeroChildCount();
							//delete newHead;
							//return;
						}

						delete newHead;
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