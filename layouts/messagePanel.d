module layouts.messagePanel;

private import iup.iup;
private import iup.iup_scintilla;

private import global, scintilla, actionManager, tools;

private import Integer = tango.text.convert.Integer;
private import tango.stdc.stringz;
private import tango.io.FilePath;
private import Util = tango.text.Util;


import tango.io.Stdout;

void createMessagePanel()
{
	GLOBAL.outputPanel = IupText( null );
	IupSetAttributes( GLOBAL.outputPanel, "MULTILINE=YES,SCROLLBAR=VERTICAL,EXPAND=YES,WORDWRAP=YES" );
	IupSetAttribute( GLOBAL.outputPanel, "VISIBLECOLUMNS", null );
	IupSetCallback( GLOBAL.outputPanel, "BUTTON_CB", cast(Icallback) &outputPanelButton_cb );
	//IupSetAttribute( GLOBAL.outputPanel, "FORMATTING", "YES");
	

	GLOBAL.searchOutputPanel = IupText( null );
	IupSetAttributes( GLOBAL.searchOutputPanel, "MULTILINE=YES,SCROLLBAR=VERTICAL,EXPAND=YES,WORDWRAP=YES" );
	IupSetAttribute( GLOBAL.searchOutputPanel, "VISIBLECOLUMNS", null );
	IupSetCallback( GLOBAL.searchOutputPanel, "BUTTON_CB", cast(Icallback) &searchOutputButton_cb );


	IupSetAttribute( GLOBAL.outputPanel, "TABTITLE", "Output" );
	IupSetAttribute( GLOBAL.searchOutputPanel, "TABTITLE", "Search" );
	
	
	IupSetAttribute( GLOBAL.outputPanel, "TABIMAGE", "icon_message" );
	IupSetAttribute( GLOBAL.searchOutputPanel, "TABIMAGE", "icon_find" );
}


extern(C)
{
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
										fileName = Util.replace( lineText[0..openPos], '\\', '/' );

										if( ScintillaAction.openFile( fileName.dup, lineNumber ) )
										{
											if( GLOBAL.compilerAnootation == "ON" )
											{
												char[] allMessage = fromStringz( IupGetAttribute( ih, "VALUE" ) ).dup;

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
																char[]	filePath = Util.replace( s[0..lineNumberHead++], '\\', '/' );
																if( fileName == filePath )
																{
																	if( upperCase(filePath) in GLOBAL.scintillaManager )
																	{
																		CScintilla cSci = GLOBAL.scintillaManager[upperCase(filePath)];

																		int		ln = Integer.atoi( s[lineNumberHead..lineNumberTail] ) - 1;
																		char[]	annotationText = s[lineNumberTail+2..length];
																		char[]	getText = fromStringz( IupGetAttributeId( cSci.getIupScintilla, "ANNOTATIONTEXT", ln ) ).dup;
																		if( getText.length ) annotationText = getText ~ "\n" ~ annotationText;

																		if( IupGetIntId( cSci.getIupScintilla, "ANNOTATIONSTYLE", ln ) < 40 )
																		{
																			IupSetAttributeId( cSci.getIupScintilla, "ANNOTATIONTEXT", ln, toStringz( s[lineNumberTail+2..length] ) );
																			if( bWarning ) IupSetIntId( cSci.getIupScintilla, "ANNOTATIONSTYLE", ln, 41 ); else IupSetIntId( cSci.getIupScintilla, "ANNOTATIONSTYLE", ln, 40 );
																		}
																	}
																}
															}
														}
													}
												}
												IupSetAttribute( GLOBAL.scintillaManager[upperCase(fileName.dup)].getIupScintilla, "ANNOTATIONVISIBLE", "BOXED" );
											}
										}

										// Make all line be selected
										int _line, _col;
										IupTextConvertPosToLinCol( ih, IupConvertXYToPos( ih, x, y ), &_line, &_col );
										IupSetAttribute( ih, "SELECTION", toStringz( Integer.toString( _line ) ~ ",1:" ~ Integer.toString( _line ) ~ "," ~ Integer.toString( lineText.length + 1 ) ) );
										
										return IUP_IGNORE;
									}
								}
							}
						}
						else
						{
							return IUP_DEFAULT;
						}
					}
					else
					{
						return IUP_DEFAULT;
					}
				}
			}
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
										int _line, _col;
										IupTextConvertPosToLinCol( ih, IupConvertXYToPos( ih, x, y ), &_line, &_col );
										IupSetAttribute( ih, "SELECTION", toStringz( Integer.toString( _line ) ~ ",1:" ~ Integer.toString( _line ) ~ "," ~ Integer.toString( lineText.length + 1 ) ) );										

										return IUP_IGNORE;
									}
								}
							}
						}
						else
						{
							return IUP_DEFAULT;
						}
					}
					else
					{
						return IUP_DEFAULT;
					}
				}
			}
		}

		return IUP_DEFAULT;
	}	
}