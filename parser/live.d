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
					if( child.getChildrenCount )
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
		catch( Exception e ){}

		return null;
	}

	static bool getBlockPosition( Ihandle* iupSci, int pos, char[] targetText, out int posHead, out int posEnd )
	{
		int		documentLength = IupGetInt( iupSci, "COUNT" );
		posHead = AutoComplete.getProcedurePos( iupSci, pos, targetText );
		if( posHead >= 0 )
		{
			//IupMessage( "targetText",toStringz( targetText ));
			int	LineNum = IupScintillaSendMessage( iupSci, 2166, posHead, 0 ) + 1; //SCI_LINEFROMPOSITION = 2166,
			//IupMessage( "targetText LineNum",toStringz( Integer.toString( LineNum ) ));
			
			posEnd = AutoComplete.getProcedureTailPos( iupSci, pos, targetText, 0 );

			LineNum = IupScintillaSendMessage( iupSci, 2166, posEnd, 0 ) + 1; //SCI_LINEFROMPOSITION = 2166,
			//IupMessage( "targetText Tail LineNum",toStringz( Integer.toString( LineNum ) ));
			
			if( posEnd > posHead ) return false;

			posEnd = AutoComplete.getProcedureTailPos( iupSci, pos, targetText, 1 );
			LineNum = IupScintillaSendMessage( iupSci, 2166, posEnd, 0 ) + 1; //SCI_LINEFROMPOSITION = 2166,
			//IupMessage( "Re targetText Tail LineNum",toStringz( Integer.toString( LineNum ) ));
		
			if( posEnd > posHead ) return true;
		}

		return false;
	}

	public:
	
	static void lineNumberAdd( CASTnode head, int fixeLn, int n = 1 )
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
			// Stdout( head.name ~ " " );
			// Stdout( head.lineNumber ).newline;
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

	static void parseCurrentLine()
	{
		try
		{
			auto cSci = ScintillaAction.getActiveCScintilla();
			if( cSci !is null )
			{
				int currentPos = ScintillaAction.getCurrentPos( cSci.getIupScintilla );

				if( ScintillaAction.isComment( cSci.getIupScintilla, currentPos ) ) return;
				
				int	currentLineNum = IupScintillaSendMessage( cSci.getIupScintilla, 2166, currentPos, 0 ) + 1; //SCI_LINEFROMPOSITION = 2166,
				char[] currentLineText = fromStringz( IupGetAttribute( cSci.getIupScintilla, "LINEVALUE" ) ).dup;
				debug IupSetAttribute( GLOBAL.outputPanel, "VALUE", GLOBAL.cString.convert( "CurrentLineText: " ~ currentLineText ~ "(" ~ Integer.toString(currentLineNum) ~ ")" ) );

				CASTnode 	oldHead;
				int			B_KIND;


				if( upperCase( cSci.getFullPath ) in GLOBAL.parserManager )
				{
					char[] titleName = AutoComplete.getFunctionTitle( cSci.getIupScintilla, currentPos, B_KIND );
					if( titleName.length )
					{
						int	lineNum = IupScintillaSendMessage( cSci.getIupScintilla, 2166, currentPos, 0 ) + 1; //SCI_LINEFROMPOSITION = 2166,
						oldHead = AutoComplete.getFunctionAST( GLOBAL.parserManager[upperCase( cSci.getFullPath )], B_KIND, lowerCase( titleName ), lineNum );
					}

					//oldHead = AutoComplete.getTitleAST( cSci.getIupScintilla, currentPos, GLOBAL.parserManager[upperCase( cSci.getFullPath )] );
					if( oldHead is null ) oldHead = GLOBAL.parserManager[upperCase( cSci.getFullPath )];// else IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( Integer.toString(currentLineNum) ~ " " ~ oldHead.name  ~ " : " ~ oldHead.type ) );
				}
				else
				{
					return;
				}

				if( oldHead is null )
				{
					debug IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( Integer.toString(currentLineNum) ~ " " ~ "No oldHead" ) );
					return;
				}
				/*
				else
				{
					IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( Integer.toString(currentLineNum) ~ " " ~ oldHead.name  ~ " : " ~ oldHead.type ) );
				}
				*/
				
				CASTnode newHead;
				if( B_KIND & ( B_TYPE | B_UNION | B_ENUM ) )
				{
					if( oldHead.lineNumber == oldHead.endLineNum ) return; // Not Complete Block
					newHead = GLOBAL.outlineTree.parserText( currentLineText, B_KIND );
				}
				else
				{
					newHead = GLOBAL.outlineTree.parserText( currentLineText );
				}
				
				if( newHead !is null )
				{
					// Parse one line is not complete, EX: one line is function head: function DynamicArray.init( _size as integer ) as TokenUnit ptr
					if( newHead.endLineNum < 2147483647 )
					{
						delete newHead;
						return;
					}

					// Parse complete, but no any result
					if( !newHead.getChildrenCount )
					{
						delete newHead;
						if( GLOBAL.toggleUpdateOutlineLive == "ON" ) GLOBAL.outlineTree.removeNodeAndGetInsertIndexByLineNumber( currentLineNum );
						debug IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( Integer.toString(currentLineNum ) ~ " " ~ "No child, Parse Error" ) );
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
						debug IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( "New Node :" ~ Integer.toString(currentLineNum) ~ " " ~ node.name  ~ " : " ~ node.type ) );
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
					

					debug IupMessage( "", toStringz( oldHead.name ~ " " ~ Integer.toString( oldHead.getChildrenCount ) ) );
				}
				else
				{
					debug IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( Integer.toString(currentLineNum) ~ " " ~ "Parse NUll" ) );
				}
			}
		}
		catch( Exception e ){}
	}

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
					/*				
					int	id = IupGetInt( GLOBAL.outlineTree.getActiveTree, "VALUE" ); // Get Focus TreeNode
					
					if( !GLOBAL.outlineTree.softRefresh( cSci ) ) actionManager.OutlineAction.refresh( cSci.getFullPath() );

					IupSetAttributeId( GLOBAL.outlineTree.getActiveTree, "MARKED", id, "YES" );
					GLOBAL.outlineTree.markTreeNode( IupScintillaSendMessage( cSci.getIupScintilla, 2166, currentPos, 0 ) + 1 );
					*/
					return;
				}

				IupSetInt( cSci.getIupScintilla, "TARGETSTART", posHead );
				IupSetInt( cSci.getIupScintilla, "TARGETEND", posTail );
				
				CASTnode newHead;
				version(Windows)
				{
					scope blockText = new char[posTail-posHead];
					IupScintillaSendMessage( cSci.getIupScintilla, 2687, 0, cast(int) blockText.ptr );// SCI_GETTARGETTEXT 2687
					newHead = GLOBAL.outlineTree.parserText( blockText );
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


					if( !newHead.getChildrenCount )
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
									int _ln = IupScintillaSendMessage( cSci.getIupScintilla, 2166, posHead, 0 ) + 1;

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

					int headLine = IupScintillaSendMessage( cSci.getIupScintilla, 2166, posHead, 0 ) + 1; //SCI_LINEFROMPOSITION = 2166,
					lineNumberAdd( newHead, newHead[0].lineNumber - 1, headLine - 1 );
					//IupMessage( "newHead", toStringz( newHead[0].name ~ " " ~ newHead[0].type ~ " (" ~ Integer.toString( newHead[0].lineNumber ) ~ ")" ) );

					// Get oringnal head
					if( upperCase( cSci.getFullPath ) in GLOBAL.parserManager )
					{
						CASTnode oldHead = AutoComplete.getFunctionAST( GLOBAL.parserManager[upperCase( cSci.getFullPath )], newHead[0].kind, lowerCase( newHead[0].name ), newHead[0].lineNumber );
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
					debug IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( Integer.toString(currentLineNum) ~ " " ~ "Parse NUll" ) );
				}
			}
		}
		catch( Exception e ){}
	}	
}