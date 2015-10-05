module layouts.messagePanel;

private import iup.iup;
private import iup.iup_scintilla;

private import global, scintilla, actionManager;

private import Integer = tango.text.convert.Integer;
private import tango.stdc.stringz;
private import tango.io.FilePath;
private import Util = tango.text.Util;


import tango.io.Stdout;

void createMessagePanel()
{
	GLOBAL.outputPanel = IupText(null);
	IupSetAttribute( GLOBAL.outputPanel, "MULTILINE", "YES" );
	IupSetAttribute( GLOBAL.outputPanel, "SCROLLBAR", "VERTICAL" );
	IupSetAttribute( GLOBAL.outputPanel, "EXPAND", "YES" );
	IupSetAttribute( GLOBAL.outputPanel, "VISIBLELINES", "0" );
	IupSetAttribute( GLOBAL.outputPanel, "VISIBLECOLUMNS", null );
	IupSetAttribute( GLOBAL.outputPanel, "FONTSIZE", "8" );
	IupSetCallback( GLOBAL.outputPanel, "BUTTON_CB", cast(Icallback) &outputPanelButton_cb );
	//IupSetAttribute( GLOBAL.outputPanel, "FORMATTING", "YES");
	

	GLOBAL.searchOutputPanel = IupText( null );
	IupSetAttribute( GLOBAL.searchOutputPanel, "MULTILINE", "YES" );
	IupSetAttribute( GLOBAL.searchOutputPanel, "SCROLLBAR", "VERTICAL" );
	IupSetAttribute( GLOBAL.searchOutputPanel, "EXPAND", "YES" );
	IupSetAttribute( GLOBAL.searchOutputPanel, "VISIBLELINES", "0" );
	IupSetAttribute( GLOBAL.searchOutputPanel, "VISIBLECOLUMNS", null );
	IupSetAttribute( GLOBAL.searchOutputPanel, "FONTSIZE", "8" );
	IupSetCallback( GLOBAL.searchOutputPanel, "BUTTON_CB", cast(Icallback) &searchOutputButton_cb );

/*
	GLOBAL.debugPanel = IupText( null );
	IupSetAttribute( GLOBAL.debugPanel, "MULTILINE", "YES" );
	IupSetAttribute( GLOBAL.debugPanel, "SCROLLBAR", "VERTICAL" );
	IupSetAttribute( GLOBAL.debugPanel, "EXPAND", "YES" );
	IupSetAttribute( GLOBAL.debugPanel, "VISIBLELINES", "0" );
	IupSetAttribute( GLOBAL.debugPanel, "VISIBLECOLUMNS", null );
	IupSetAttribute( GLOBAL.debugPanel, "FONTSIZE", "8" );
	//IupSetCallback( debugPanel, "BUTTON_CB", cast(Icallback) &searchOutputButton_cb );
*/


	IupSetAttribute( GLOBAL.outputPanel, "TABTITLE", "Output" );
	IupSetAttribute( GLOBAL.searchOutputPanel, "TABTITLE", "Search" );
	IupSetAttribute( GLOBAL.debugPanel, "TABTITLE", "Debug" );
	
	
	IupSetAttribute( GLOBAL.outputPanel, "TABIMAGE", "icon_message" );
	IupSetAttribute( GLOBAL.searchOutputPanel, "TABIMAGE", "icon_find" );
	IupSetAttribute( GLOBAL.debugPanel, "TABIMAGE", "icon_debug" );
}


extern(C)
{
	int outputPanelButton_cb(Ihandle* ih, int button, int pressed, int x, int y, char* status )
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
					char[]	lineText = fromStringz( IupGetAttribute( ih, "LINEVALUE" ) );

					/+
					formattag = IupUser();

					IupSetAttribute(GLOBAL.outputPanel, "REMOVEFORMATTING", "YES" );
					
					//IupSetAttribute( formattag, "CLEARATTRIBUTES", "" );
					//IupDestroy( formattag );
					
					
					IupSetAttribute(formattag, "BGCOLOR", "255 128 64");
					IupSetAttribute(formattag, "WEIGHT", "BOLD");

					int pos = IupConvertXYToPos( GLOBAL.outputPanel, x, y );
					int line, col;
					IupTextConvertPosToLinCol( GLOBAL.outputPanel, pos, &line, &col );
					char[] lincol = Integer.toString(line) ~ ",1:" ~ Integer.toString(line) ~"," ~ Integer.toString(lineText.length);

					
					
					IupSetAttribute(formattag, "SELECTION", toStringz( lincol ) );
					IupSetAttribute(GLOBAL.outputPanel, "ADDFORMATTAG_HANDLE", cast(char*)formattag);
					+/
			
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
										fileName = lineText[0..openPos];
										ScintillaAction.openFile( fileName.dup, lineNumber );
										
										return IUP_DEFAULT;
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

	int searchOutputButton_cb( Ihandle* ih, int button, int pressed, int x, int y, char* status )
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

										return IUP_DEFAULT;
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

	/*
	int messageCaret_cb(Ihandle *ih, int lin, int col, int pos)
	{
		LINECOLPOS.line = lin;
		LINECOLPOS.col = col;
		LINECOLPOS.pos = pos;

		return IUP_DEFAULT;
	}	
	*/
}