module layouts.messagePanel;

private import iup.iup;
private import iup.iup_scintilla;

private import global, scintilla, actionManager, tools;

private import Integer = tango.text.convert.Integer;
private import tango.stdc.stringz;
private import tango.io.FilePath, Path = tango.io.Path;
private import Util = tango.text.Util;


import tango.io.Stdout;

class CMessageAndSearch
{
	private:
	Ihandle*		outputPanel, searchOutputPanel;
	//Ihandle* 		formattag;


	void createMessagePanel()
	{
		outputPanel = IupScintilla( );
		IupSetAttributes( outputPanel, "MULTILINE=YES,SCROLLBAR=VERTICAL,EXPAND=YES,BORDER=NO" );
		IupSetCallback( outputPanel, "BUTTON_CB", cast(Icallback) &outputPanelButton_cb );
		
		searchOutputPanel = IupScintilla();
		IupSetAttributes( searchOutputPanel, "MULTILINE=YES,SCROLLBAR=VERTICAL,EXPAND=YES,BORDER=NO" );
		IupSetCallback( searchOutputPanel, "BUTTON_CB", cast(Icallback) &searchOutputButton_cb );

		IupSetAttribute( outputPanel, "TABTITLE", GLOBAL.languageItems["output"].toCString );
		IupSetAttribute( searchOutputPanel, "TABTITLE", GLOBAL.languageItems["search"].toCString );
		
		IupSetAttribute( outputPanel, "TABIMAGE", "icon_message" );
		IupSetAttribute( searchOutputPanel, "TABIMAGE", "icon_search" );
	}

	public:
	this()
	{
		createMessagePanel();
	}
	
	void setScintillaColor()
	{
		// outputPanel		
		IupSetAttribute( outputPanel, "LEXERLANGUAGE", "freebasic");
		/*
		IupSetAttribute( outputPanel, "KEYWORDS0", GLOBAL.KEYWORDS[0].toCString );
		IupSetAttribute( outputPanel, "KEYWORDS1", GLOBAL.KEYWORDS[1].toCString );
		IupSetAttribute( outputPanel, "KEYWORDS2", GLOBAL.KEYWORDS[2].toCString );
		IupSetAttribute( outputPanel, "KEYWORDS3", GLOBAL.KEYWORDS[3].toCString );		
		*/

		IupSetAttribute( outputPanel, "WORDWRAP", "CHAR" );	// SCE_B_KEYWORD4 12
		IupSetAttributeId( outputPanel, "INDICATORSTYLE", 8, "DOTBOX" );
		IupSetAttributeId( outputPanel, "INDICATORFGCOLOR", 8, "255 0 0" );
		
		// scintilla
		IupSetAttribute( searchOutputPanel, "LEXERLANGUAGE", "freebasic");
		IupSetAttribute( searchOutputPanel, "KEYWORDS0", GLOBAL.KEYWORDS[0].toCString );
		IupSetAttribute( searchOutputPanel, "KEYWORDS1", GLOBAL.KEYWORDS[1].toCString );
		IupSetAttribute( searchOutputPanel, "KEYWORDS2", GLOBAL.KEYWORDS[2].toCString );
		IupSetAttribute( searchOutputPanel, "KEYWORDS3", GLOBAL.KEYWORDS[3].toCString );		
		
		IupSetAttribute(searchOutputPanel, "WORDWRAP", "CHAR" );	// SCE_B_KEYWORD4 12
		IupSetAttributeId( searchOutputPanel, "INDICATORSTYLE", 8, "DOTBOX" );
		IupSetAttributeId( searchOutputPanel, "INDICATORFGCOLOR", 8, "0 0 255" );
		
		//IupScintillaSendMessage( searchOutputPanel, 2080, 8, GLOBAL.indicatorStyle ); //SCI_INDICSETSTYLE = 2080
		
		applyColor();
	}
	
	void applyColor()
	{
		uint alpha = Integer.atoi( GLOBAL.editColor.selAlpha.toDString );
		if( alpha > 255 )
			alpha = 255;
		else if( alpha < 0 )
			alpha = 0;
			
		// outputPanel
		IupSetAttribute( outputPanel, "STYLEFGCOLOR32", GLOBAL.editColor.outputFore.toCString );		// 32
		IupSetAttribute( outputPanel, "STYLEBGCOLOR32", GLOBAL.editColor.outputBack.toCString );		// 32
	
		IupSetAttribute( outputPanel, "STYLECLEARALL", "Yes");  /* sets all styles to have the same attributes as 32 */
		
		/*
		IupSetAttribute( outputPanel, "STYLEFGCOLOR3", GLOBAL.editColor.keyWord[0].toCString );	// SCE_B_KEYWORD 3
		IupSetAttribute( outputPanel, "STYLEFGCOLOR10", GLOBAL.editColor.keyWord[1].toCString );	// SCE_B_KEYWORD2 10
		IupSetAttribute( outputPanel, "STYLEFGCOLOR11",  GLOBAL.editColor.keyWord[2].toCString );	// SCE_B_KEYWORD3 11
		IupSetAttribute( outputPanel, "STYLEFGCOLOR12",  GLOBAL.editColor.keyWord[3].toCString );	// SCE_B_KEYWORD4 12
		*/
		
		IupSetAttribute( outputPanel, "STYLEFGCOLOR1", GLOBAL.editColor.SCE_B_COMMENT_Fore.toCString );		// SCE_B_COMMENT 1
		IupSetAttribute( outputPanel, "STYLEBGCOLOR1", GLOBAL.editColor.SCE_B_COMMENT_Back.toCString );		// SCE_B_COMMENT 1
		
		/*
		IupSetAttribute( outputPanel, "STYLEFGCOLOR6", GLOBAL.editColor.SCE_B_OPERATOR_Fore.toCString );		// SCE_B_OPERATOR 6
		IupSetAttribute( outputPanel, "STYLEBGCOLOR6", GLOBAL.editColor.SCE_B_OPERATOR_Back.toCString );		// SCE_B_OPERATOR 6
		*/
		IupSetAttribute( outputPanel, "STYLEFGCOLOR2", GLOBAL.editColor.SCE_B_NUMBER_Fore.toCString );		// SCE_B_NUMBER 2
		IupSetAttribute( outputPanel, "STYLEBGCOLOR2", GLOBAL.editColor.SCE_B_NUMBER_Back.toCString );		// SCE_B_NUMBER 2

		/*
		IupSetAttribute( outputPanel, "STYLEFGCOLOR4", GLOBAL.editColor.SCE_B_STRING_Fore.toCString );		// SCE_B_STRING 4
		IupSetAttribute( outputPanel, "STYLEBGCOLOR4", GLOBAL.editColor.SCE_B_STRING_Back.toCString );		// SCE_B_STRING 4
		*/
		if( alpha == 255 )
		{
			IupScintillaSendMessage( outputPanel, 2067, true, actionManager.ToolAction.convertIupColor( GLOBAL.editColor.selectionFore.toDString ) );// SCI_SETSELFORE = 2067,
			IupScintillaSendMessage( outputPanel, 2068, true, actionManager.ToolAction.convertIupColor( GLOBAL.editColor.selectionBack.toDString ) );// SCI_SETSELBACK = 2068,
			IupScintillaSendMessage( outputPanel, 2478, 256, 0 );// SCI_SETSELALPHA   2478
		}
		else if( alpha == 0 )
		{
			IupScintillaSendMessage( outputPanel, 2067, false, actionManager.ToolAction.convertIupColor( GLOBAL.editColor.selectionFore.toDString ) );// SCI_SETSELFORE = 2067,
			IupScintillaSendMessage( outputPanel, 2068, true, actionManager.ToolAction.convertIupColor( GLOBAL.editColor.selectionBack.toDString ) );// SCI_SETSELBACK = 2068,
			IupScintillaSendMessage( outputPanel, 2478, 256, 0 );// SCI_SETSELALPHA   2478
		}
		else
		{
			IupScintillaSendMessage( outputPanel, 2067, false, actionManager.ToolAction.convertIupColor( GLOBAL.editColor.selectionFore.toDString ) );// SCI_SETSELFORE = 2067,
			IupScintillaSendMessage( outputPanel, 2068, true, actionManager.ToolAction.convertIupColor( GLOBAL.editColor.selectionBack.toDString ) );// SCI_SETSELBACK = 2068,
			IupScintillaSendMessage( outputPanel, 2478, alpha, 0 );// SCI_SETSELALPHA   2478
		}
		
		// Caret Line ( Current Line )
		IupSetAttribute( outputPanel, "CARETLINEVISIBLE", toStringz( GLOBAL.editorSetting00.CaretLine.dup ) );
		IupSetAttribute( outputPanel, "CARETLINEBACKCOLOR", GLOBAL.editColor.caretLine.toCString );

		
		// searchOutputPanel
		IupSetAttribute( searchOutputPanel, "STYLEFGCOLOR32", GLOBAL.editColor.searchFore.toCString );		// 32
		IupSetAttribute( searchOutputPanel, "STYLEBGCOLOR32", GLOBAL.editColor.searchBack.toCString );		// 32
		
		IupSetAttribute( searchOutputPanel, "STYLECLEARALL", "Yes");  /* sets all styles to have the same attributes as 32 */
		
		IupSetAttribute( searchOutputPanel, "STYLEFGCOLOR3", GLOBAL.editColor.keyWord[0].toCString );	// SCE_B_KEYWORD 3
		IupSetAttribute( searchOutputPanel, "STYLEFGCOLOR10", GLOBAL.editColor.keyWord[1].toCString );	// SCE_B_KEYWORD2 10
		IupSetAttribute( searchOutputPanel, "STYLEFGCOLOR11",  GLOBAL.editColor.keyWord[2].toCString );	// SCE_B_KEYWORD3 11
		IupSetAttribute( searchOutputPanel, "STYLEFGCOLOR12",  GLOBAL.editColor.keyWord[3].toCString );	// SCE_B_KEYWORD4 12

		IupSetAttribute( searchOutputPanel, "STYLEFGCOLOR1", GLOBAL.editColor.SCE_B_COMMENT_Fore.toCString );		// SCE_B_COMMENT 1
		IupSetAttribute( searchOutputPanel, "STYLEBGCOLOR1", GLOBAL.editColor.SCE_B_COMMENT_Back.toCString );		// SCE_B_COMMENT 1
		IupSetAttribute( searchOutputPanel, "STYLEFGCOLOR2", GLOBAL.editColor.SCE_B_NUMBER_Fore.toCString );		// SCE_B_NUMBER 2
		IupSetAttribute( searchOutputPanel, "STYLEBGCOLOR2", GLOBAL.editColor.SCE_B_NUMBER_Back.toCString );		// SCE_B_NUMBER 2
		IupSetAttribute( searchOutputPanel, "STYLEFGCOLOR4", GLOBAL.editColor.SCE_B_STRING_Fore.toCString );		// SCE_B_STRING 4
		IupSetAttribute( searchOutputPanel, "STYLEBGCOLOR4", GLOBAL.editColor.SCE_B_STRING_Back.toCString );		// SCE_B_STRING 4
		//IupSetAttribute( searchOutputPanel, "STYLEFGCOLOR5", GLOBAL.editColor.SCE_B_PREPROCESSOR_Fore.toCString );	// SCE_B_PREPROCESSOR 5
		//IupSetAttribute( searchOutputPanel, "STYLEBGCOLOR5", GLOBAL.editColor.SCE_B_PREPROCESSOR_Back.toCString );	// SCE_B_PREPROCESSOR 5
		IupSetAttribute( searchOutputPanel, "STYLEFGCOLOR6", GLOBAL.editColor.SCE_B_OPERATOR_Fore.toCString );		// SCE_B_OPERATOR 6
		IupSetAttribute( searchOutputPanel, "STYLEBGCOLOR6", GLOBAL.editColor.SCE_B_OPERATOR_Back.toCString );		// SCE_B_OPERATOR 6
		
		/*
		IupSetAttribute(searchOutputPanel, "STYLEBOLD3", "YES");
		IupSetAttribute(searchOutputPanel, "STYLEBOLD10", "YES");
		IupSetAttribute(searchOutputPanel, "STYLEBOLD11", "YES");
		IupSetAttribute(searchOutputPanel, "STYLEBOLD12", "YES");
		*/
		if( alpha == 255 )
		{
			IupScintillaSendMessage( searchOutputPanel, 2067, true, actionManager.ToolAction.convertIupColor( GLOBAL.editColor.selectionFore.toDString ) );// SCI_SETSELFORE = 2067,
			IupScintillaSendMessage( searchOutputPanel, 2068, true, actionManager.ToolAction.convertIupColor( GLOBAL.editColor.selectionBack.toDString ) );// SCI_SETSELBACK = 2068,
			IupScintillaSendMessage( searchOutputPanel, 2478, 256, 0 );// SCI_SETSELALPHA   2478
		}
		else if( alpha == 0 )
		{
			IupScintillaSendMessage( searchOutputPanel, 2067, false, actionManager.ToolAction.convertIupColor( GLOBAL.editColor.selectionFore.toDString ) );// SCI_SETSELFORE = 2067,
			IupScintillaSendMessage( searchOutputPanel, 2068, true, actionManager.ToolAction.convertIupColor( GLOBAL.editColor.selectionBack.toDString ) );// SCI_SETSELBACK = 2068,
			IupScintillaSendMessage( searchOutputPanel, 2478, 256, 0 );// SCI_SETSELALPHA   2478
		}
		else
		{
			IupScintillaSendMessage( searchOutputPanel, 2067, false, actionManager.ToolAction.convertIupColor( GLOBAL.editColor.selectionFore.toDString ) );// SCI_SETSELFORE = 2067,
			IupScintillaSendMessage( searchOutputPanel, 2068, true, actionManager.ToolAction.convertIupColor( GLOBAL.editColor.selectionBack.toDString ) );// SCI_SETSELBACK = 2068,
			IupScintillaSendMessage( searchOutputPanel, 2478, alpha, 0 );// SCI_SETSELALPHA   2478
		}

		// Caret Line ( Current Line )
		IupSetAttribute( searchOutputPanel, "CARETLINEVISIBLE", toStringz( GLOBAL.editorSetting00.CaretLine.dup ) );
		IupSetAttribute( searchOutputPanel, "CARETLINEBACKCOLOR", GLOBAL.editColor.caretLine.toCString );
	}
	
	void printOutputPanel( char[] txt, bool bClear = false )
	{
		if( txt.length )
		{
			if( bClear ) IupSetAttribute( outputPanel, "VALUE", GLOBAL.cString.convert( txt ) ); else IupSetAttribute( outputPanel, "APPEND", GLOBAL.cString.convert( txt ) );
		}
		else
		{
			if( bClear ) IupSetAttribute( outputPanel, "VALUE", "" ); else IupSetAttribute( outputPanel, "APPEND", "" );
		}
	}
	
	void printSearchOutputPanel( char[] txt, bool bClear = false )
	{
		if( txt.length )
		{
			if( bClear ) IupSetAttribute( searchOutputPanel, "VALUE", GLOBAL.cString.convert( txt ) ); else IupSetAttribute( searchOutputPanel, "APPEND", GLOBAL.cString.convert( txt ) );
		}
		else
		{
			if( bClear ) IupSetAttribute( searchOutputPanel, "VALUE", "" ); else IupSetAttribute( searchOutputPanel, "APPEND", "" );
		}
	}
	
	void applyOutputPanelINDICATOR()
	{
		IupScintillaSendMessage( outputPanel, 2505, 0, IupGetInt( searchOutputPanel, "COUNT" ) ); // SCI_INDICATORCLEARRANGE = 2505
		IupScintillaSendMessage( outputPanel, 2500, 8, 0 ); // SCI_SETINDICATORCURRENT = 2500
		
		int LineNum;
		foreach( char[] lineText; Util.splitLines( fromStringz( IupGetAttribute( outputPanel, "VALUE" ) ) ) )
		{
			if( lineText.length )
			{
				int openPos = Util.index( lineText, "(" );
				if( openPos < lineText.length )
				{
					int closePos = Util.index( lineText, ")", openPos );
					if( closePos < lineText.length )
					{
						if( closePos < lineText.length )
						{
							if( closePos > openPos )
							{
								int colonPos = Util.index( lineText, ": ", closePos );
								
								if( colonPos < lineText.length )
								{
									if( colonPos > closePos )
									{
										int lineHeadPos = cast(int) IupScintillaSendMessage( outputPanel, 2167, LineNum, 0 ); //SCI_POSITIONFROMLINE 2167
										IupScintillaSendMessage( outputPanel, 2504, lineHeadPos, colonPos + 1 ); // SCI_INDICATORFILLRANGE =  2504
										IupScintillaSendMessage( outputPanel, 2504, lineHeadPos + colonPos + 2, lineText.length - colonPos - 2 ); // SCI_INDICATORFILLRANGE =  2504
									}
								}
							}
						}
					}
				}
			}
			LineNum ++;
		}
	}
	
	void applySearchOutputPanelINDICATOR()
	{
		IupScintillaSendMessage( searchOutputPanel, 2505, 0, IupGetInt( searchOutputPanel, "COUNT" ) ); // SCI_INDICATORCLEARRANGE = 2505
		IupScintillaSendMessage( searchOutputPanel, 2500, 8, 0 ); // SCI_SETINDICATORCURRENT = 2500
		
		int LineNum;
		foreach( char[] lineText; Util.splitLines( fromStringz( IupGetAttribute( searchOutputPanel, "VALUE" ) ) ) )
		{
			if( lineText.length )
			{
				int openPos = Util.index( lineText, "(" );
				if( openPos < lineText.length )
				{
					int closePos = Util.index( lineText, "): ", openPos );
					if( closePos < lineText.length - 2 )
					{
						if( closePos > openPos + 1 )
						{
							int lineHeadPos = cast(int) IupScintillaSendMessage( searchOutputPanel, 2167, LineNum, 0 ); //SCI_POSITIONFROMLINE 2167
							IupScintillaSendMessage( searchOutputPanel, 2504, lineHeadPos, closePos + 2 ); // SCI_INDICATORFILLRANGE =  2504
							IupScintillaSendMessage( searchOutputPanel, 2504, lineHeadPos + closePos + 3, lineText.length - closePos - 3 ); // SCI_INDICATORFILLRANGE =  2504
						}
					}
				}
			}
			LineNum ++;
		}
	}
	
	void scrollOutputPanel( int pos )
	{
		IupSetInt( outputPanel, "SCROLLTOPOS", pos );
	}
	
	void scrollSearchOutputPanel( int pos )
	{
		IupSetInt( searchOutputPanel, "SCROLLTOPOS", pos );
	}
	
	Ihandle* getOutputPanelHandle()
	{
		return outputPanel;
	}
	
	Ihandle* getSearchOutputPanelHandle()
	{
		return searchOutputPanel;
	}
}


extern(C)
{
	private void right_click()
	{
		Ihandle* _undo = IupItem( GLOBAL.languageItems["sc_undo"].toCString, null );
		IupSetAttribute( _undo, "IMAGE", "icon_undo" );
		IupSetCallback( _undo, "ACTION", cast(Icallback) &undo_ACTION );

		Ihandle* _redo = IupItem( GLOBAL.languageItems["sc_redo"].toCString, null );
		IupSetAttribute( _redo, "IMAGE", "icon_redo" );
		IupSetCallback( _redo, "ACTION", cast(Icallback) &redo_ACTION );

		Ihandle* _cut = IupItem( GLOBAL.languageItems["caption_cut"].toCString, null );
		IupSetAttribute( _cut, "IMAGE", "icon_cut" );
		IupSetCallback( _cut, "ACTION",  cast(Icallback) &cut_ACTION );
		
		Ihandle* _copy = IupItem( GLOBAL.languageItems["caption_copy"].toCString, null );
		IupSetAttribute( _copy, "IMAGE", "icon_copy" );
		IupSetCallback( _copy, "ACTION", cast(Icallback) &copy_ACTION );

		Ihandle* _paste = IupItem( GLOBAL.languageItems["caption_paste"].toCString, null );
		IupSetAttribute( _paste, "IMAGE", "icon_paste" );
		IupSetCallback( _paste, "ACTION", cast(Icallback) &paste_ACTION );

		Ihandle* _delete = IupItem( GLOBAL.languageItems["delete"].toCString, null );
		IupSetAttribute( _delete, "IMAGE", "icon_clear" );
		IupSetCallback( _delete, "ACTION", cast(Icallback) &delete_ACTION );
		
		Ihandle* _selectall = IupItem( GLOBAL.languageItems["caption_selectall"].toCString, null );
		IupSetAttribute( _selectall, "IMAGE", "icon_selectall" );
		IupSetCallback( _selectall, "ACTION", cast(Icallback) &selectall_ACTION );

		Ihandle* _clear = IupItem( GLOBAL.languageItems["clearall"].toCString, null );
		IupSetAttribute( _clear, "IMAGE", "icon_debug_clear" );
		IupSetCallback( _clear, "ACTION", cast(Icallback) &clearall_ACTION );
		
		Ihandle* popupMenu;
		popupMenu = IupMenu(
							_undo,
							_redo,
							IupSeparator(),

							_cut,
							_copy,
							_paste,
							_delete,
							IupSeparator(),

							_selectall,
							_clear,
							null
							);

		IupPopup( popupMenu, IUP_MOUSEPOS, IUP_MOUSEPOS );
		IupDestroy( popupMenu );
	}
	
	private int outputPanelButton_cb(Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		if( button == IUP_BUTTON1 )
		{
			char[] statusUTF8 = fromStringz( status );
			if( statusUTF8.length > 5 )
			{
				if( statusUTF8[5] == 'D' )
				{
					int		lineNumber;
					bool	bGetFileName = true;
					char[]	fileName;
					char[]	lineText = fromStringz( IupGetAttribute( ih, "LINEVALUE" ) ).dup;

					int openPos = Util.index( lineText, "(" );
					if( openPos < lineText.length )
					{
						int closePos = Util.index( lineText, ")" );
						if( closePos < lineText.length )
						{
							if( closePos > openPos+1 )
							{
								if( closePos < lineText.length - 1 )
								{
									if( lineText[closePos+1] == ' ' )
									{
										char[] lineNumber_char = lineText[openPos+1..closePos];
										lineNumber = Integer.atoi( lineNumber_char );
										fileName = Path.normalize( lineText[0..openPos] );
										
										if( ExecuterAction.quickRunFile.length ) fileName = ExecuterAction.quickRunFile;
										
										if( upperCase(fileName.dup) in GLOBAL.scintillaManager )
										{
											ScintillaAction.openFile( fileName.dup, lineNumber );
										}
										else
										{
											if( ScintillaAction.openFile( fileName.dup, lineNumber ) )
											{
												if( GLOBAL.compilerAnootation == "ON" )
												{
													char[] allMessage = fromStringz( IupGetAttribute( ih, "VALUE" ) ).dup;
													
													int prevLineNumber, prevLineNumberCount;

													foreach( char[] s; Util.splitLines( allMessage ) )
													{
														if( s.length )
														{
															bool bWarning;
															int lineNumberTail = Util.index( s, ") error" );
															if( lineNumberTail >= s.length )
															{
																lineNumberTail = Util.index( s, ") warning" );
																bWarning = true;
															}

															if( lineNumberTail < s.length )
															{
																int lineNumberHead = Util.index( s, "(" );
																if( lineNumberHead < lineNumberTail - 1 )
																{
																	char[]	filePath = Path.normalize( s[0..lineNumberHead++] );
																	if( fileName == filePath )
																	{
																		if( upperCase(filePath) in GLOBAL.scintillaManager )
																		{
																			CScintilla cSci = GLOBAL.scintillaManager[upperCase(filePath)];

																			int		ln = Integer.atoi( s[lineNumberHead..lineNumberTail] ) - 1;
																			char[]	annotationText = s[lineNumberTail+2..length];
																			
																			if( ln != prevLineNumber )
																			{
																				prevLineNumber = ln;
																				prevLineNumberCount = 1;
																				annotationText = "[" ~ Integer.toString( prevLineNumberCount ) ~ "]" ~ annotationText;
																				prevLineNumberCount ++;
																			}
																			else
																			{
																				annotationText = "[" ~ Integer.toString( prevLineNumberCount ) ~ "]" ~ annotationText;
																				prevLineNumberCount ++;
																			}
																	
																			char[]	getText = fromStringz( IupGetAttributeId( cSci.getIupScintilla, "ANNOTATIONTEXT", ln ) ).dup;
																			if( getText.length ) annotationText = getText ~ "\n" ~ annotationText;

																			IupSetAttributeId( cSci.getIupScintilla, "ANNOTATIONTEXT", ln, toStringz( annotationText ) );
																			if( bWarning ) IupSetIntId( cSci.getIupScintilla, "ANNOTATIONSTYLE", ln, 41 ); else IupSetIntId( cSci.getIupScintilla, "ANNOTATIONSTYLE", ln, 40 );
																			IupSetAttribute( GLOBAL.scintillaManager[upperCase(fileName.dup)].getIupScintilla, "ANNOTATIONVISIBLE", "BOXED" );
																		}
																	}
																}
															}
														}
													}
													//IupSetAttribute( GLOBAL.scintillaManager[upperCase(fileName.dup)].getIupScintilla, "ANNOTATIONVISIBLE", "BOXED" );
												}
											}
										}

										// Make all line be selected
										int	_line = ScintillaAction.getLinefromPos( ih, ScintillaAction.getCurrentPos( ih ) );
										IupSetAttribute( ih, "SELECTION", toStringz( Integer.toString( _line ) ~ ",0:" ~ Integer.toString( _line ) ~ "," ~ Integer.toString( lineText.length - 1 ) ) );										
										
										return IUP_IGNORE;
									}
								}
							}
						}
						else
						{
							version(Windows) return IUP_DEFAULT; else return IUP_IGNORE;
						}
					}
					else
					{
						version(Windows) return IUP_DEFAULT; else return IUP_IGNORE;
					}
				}
			}
		}
		else if( button == IUP_BUTTON3 )
		{
			right_click();
			return IUP_IGNORE;
		}
		
		return IUP_DEFAULT;
	}

	private int searchOutputButton_cb( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		if( button == IUP_BUTTON1 )
		{
			char[] statusUTF8 = fromStringz( status );
			if( statusUTF8.length > 5 )
			{
				if( statusUTF8[5] == 'D' ) // Double Click!
				{
					int		lineNumber;
					bool	bGetFileName = true;
					char[]	fileName;
					char[]	lineText = fromStringz( IupGetAttribute( ih, "LINEVALUE" ) );

					int openPos = Util.index( lineText, "(" );
					if( openPos < lineText.length )
					{
						int closePos = Util.index( lineText, "):", openPos );
						if( closePos < lineText.length )
						{
							if( closePos > openPos+1 )
							{
								if( closePos < lineText.length - 1 )
								{
									if( lineText[closePos+1] == ':' )
									{
										char[] lineNumber_char = lineText[openPos+1..closePos];
										lineNumber = Integer.atoi( lineNumber_char );
										fileName = lineText[0..openPos];
										ScintillaAction.openFile( fileName.dup, lineNumber );

										// Make all line be selected
										int	_line = ScintillaAction.getLinefromPos( ih, ScintillaAction.getCurrentPos( ih ) );
										IupSetAttribute( ih, "SELECTION", toStringz( Integer.toString( _line ) ~ ",0:" ~ Integer.toString( _line ) ~ "," ~ Integer.toString( lineText.length - 1 ) ) );										

										return IUP_IGNORE;
									}
								}
							}
						}
						else
						{
							version(Windows) return IUP_DEFAULT; else return IUP_IGNORE;
						}
					}
					else
					{
						version(Windows) return IUP_DEFAULT; else return IUP_IGNORE;
					}
				}
			}
		}
		else if( button == IUP_BUTTON3 )
		{
			right_click();
			return IUP_IGNORE;
		}

		return IUP_DEFAULT;
	}

	private int undo_ACTION( Ihandle* ih )
	{
		Ihandle* _ih = cast(Ihandle*) IupGetAttribute( GLOBAL.messageWindowTabs, "VALUE_HANDLE" );
		if( _ih != null )
		{
			if( fromStringz( IupGetAttribute( _ih, "UNDO" ) ) == "YES" ) IupSetAttribute( _ih, "UNDO", "YES" );
		}
		return IUP_DEFAULT;
	}
	
	private int redo_ACTION( Ihandle* ih )
	{
		Ihandle* _ih = cast(Ihandle*) IupGetAttribute( GLOBAL.messageWindowTabs, "VALUE_HANDLE" );
		if( _ih != null )
		{
			if( fromStringz( IupGetAttribute( _ih, "REDO" ) ) == "YES" ) IupSetAttribute( _ih, "REDO", "YES" );
		}
		return IUP_DEFAULT;
	}

	private int cut_ACTION( Ihandle* ih )
	{
		Ihandle* _ih = cast(Ihandle*) IupGetAttribute( GLOBAL.messageWindowTabs, "VALUE_HANDLE" );
		if( _ih != null ) IupSetAttribute( _ih, "CLIPBOARD", "CUT" );
		return IUP_DEFAULT;
	}

	private int copy_ACTION( Ihandle* ih )
	{
		Ihandle* _ih = cast(Ihandle*) IupGetAttribute( GLOBAL.messageWindowTabs, "VALUE_HANDLE" );
		if( _ih != null ) IupSetAttribute( _ih, "CLIPBOARD", "COPY" );
		return IUP_DEFAULT;
	}

	private int paste_ACTION( Ihandle* ih )
	{
		Ihandle* _ih = cast(Ihandle*) IupGetAttribute( GLOBAL.messageWindowTabs, "VALUE_HANDLE" );
		if( _ih != null ) IupSetAttribute( _ih, "CLIPBOARD", "PASTE" );
		return IUP_DEFAULT;
	}

	private int delete_ACTION( Ihandle* ih )
	{
		Ihandle* _ih = cast(Ihandle*) IupGetAttribute( GLOBAL.messageWindowTabs, "VALUE_HANDLE" );
		if( _ih != null ) IupSetAttribute( _ih, "CLIPBOARD", "CLEAR" );
		return IUP_DEFAULT;
	}
	
	private int selectall_ACTION( Ihandle* ih )
	{
		Ihandle* _ih = cast(Ihandle*) IupGetAttribute( GLOBAL.messageWindowTabs, "VALUE_HANDLE" );
		if( _ih != null ) IupSetAttribute( _ih, "SELECTION", "ALL" );
		return IUP_DEFAULT;
	}

	private int clearall_ACTION( Ihandle* ih )
	{
		Ihandle* _ih = cast(Ihandle*) IupGetAttribute( GLOBAL.messageWindowTabs, "VALUE_HANDLE" );
		if( _ih != null )
		{
			IupSetAttribute( _ih, "CLEARALL", "YES" );
		}
		return IUP_DEFAULT;
	}
}
