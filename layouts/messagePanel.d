module layouts.messagePanel;

private import iup.iup;
private import iup.iup_scintilla;

private import global, scintilla, actionManager, tools;

private import Integer = tango.text.convert.Integer;
private import tango.stdc.stringz;
private import tango.io.FilePath, Path = tango.io.Path;
private import Util = tango.text.Util;


class CMessageAndSearch
{
private:
	Ihandle*		outputPanel, searchOutputPanel;
	//Ihandle* 		formattag;


	void createMessagePanel()
	{
		if( GLOBAL.editorSetting01.OutputSci == "ON" )
		{
			outputPanel = IupScintilla();
			IupSetAttributes( outputPanel, "MULTILINE=YES,SCROLLBAR=VERTICAL,EXPAND=YES,BORDER=NO" );
		}
		else
		{
			outputPanel = IupText( null );
			IupSetAttributes( outputPanel, "MULTILINE=YES,SCROLLBAR=VERTICAL,EXPAND=YES,BORDER=NO,WORDWRAP=YES,READONLY=YES" );
		}
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
		if( GLOBAL.editorSetting01.OutputSci == "ON" )
		{
			// outputPanel		
			IupSetAttribute( outputPanel, "WORDWRAP", "CHAR" );	// SCE_B_KEYWORD4 12
			IupSetAttributeId( outputPanel, "INDICATORSTYLE", 4, "DOTBOX" );
			IupSetStrAttributeId( outputPanel, "INDICATORFGCOLOR", 4, GLOBAL.editColor.searchIndicator.toCString );
			IupSetIntId( outputPanel, "INDICATORALPHA", 4, Integer.atoi( GLOBAL.editColor.searchIndicatorAlpha.toDString ) );
		}
		
		// scintilla
		version(FBIDE)
		{
			IupSetAttribute( searchOutputPanel, "LEXERLANGUAGE", "freebasic");
			for( int i = 0; i < 6; ++i )
			{
				char[] _key = Util.trim( GLOBAL.KEYWORDS[i] );
				if( _key.length ) IupSetStrAttribute( searchOutputPanel, toStringz( "KEYWORDS" ~ Integer.toString( i ) ), toStringz( lowerCase( _key ) ) ); else IupSetAttribute( searchOutputPanel, toStringz( "KEYWORDS" ~ Integer.toString( i ) ), "" );
			}			
		}
		version(DIDE)
		{
			IupSetStrAttribute( searchOutputPanel, "LEXERLANGUAGE", "d");
			if( GLOBAL.KEYWORDS[0].length ) IupSetStrAttribute(searchOutputPanel, "KEYWORDS0", toStringz( GLOBAL.KEYWORDS[0] ) ); else IupSetAttribute( searchOutputPanel, "KEYWORDS0", "" );
			if( GLOBAL.KEYWORDS[1].length ) IupSetStrAttribute(searchOutputPanel, "KEYWORDS1", toStringz( GLOBAL.KEYWORDS[1] ) ); else IupSetAttribute( searchOutputPanel, "KEYWORDS1", "" );
			if( GLOBAL.KEYWORDS[2].length ) IupSetStrAttribute(searchOutputPanel, "KEYWORDS3", toStringz( GLOBAL.KEYWORDS[2] ) ); else IupSetAttribute( searchOutputPanel, "KEYWORDS3", "" );
			if( GLOBAL.KEYWORDS[3].length ) IupSetStrAttribute(searchOutputPanel, "KEYWORDS4", toStringz( GLOBAL.KEYWORDS[3] ) ); else IupSetAttribute( searchOutputPanel, "KEYWORDS4", "" );
			if( GLOBAL.KEYWORDS[4].length ) IupSetStrAttribute(searchOutputPanel, "KEYWORDS5", toStringz( GLOBAL.KEYWORDS[4] ) ); else IupSetAttribute( searchOutputPanel, "KEYWORDS5", "" );
			if( GLOBAL.KEYWORDS[5].length ) IupSetStrAttribute(searchOutputPanel, "KEYWORDS6", toStringz( GLOBAL.KEYWORDS[5] ) ); else IupSetAttribute( searchOutputPanel, "KEYWORDS6", "" );
		}
		
		IupSetAttribute( searchOutputPanel, "WORDWRAP", "CHAR" );	// SCE_B_KEYWORD4 12
		IupSetAttributeId( searchOutputPanel, "INDICATORSTYLE", 4, "DOTBOX" );
		IupSetStrAttributeId( searchOutputPanel, "INDICATORFGCOLOR", 4, GLOBAL.editColor.searchIndicator.toCString );
		IupSetIntId( searchOutputPanel, "INDICATORALPHA", 4, Integer.atoi( GLOBAL.editColor.searchIndicatorAlpha.toDString ) );
		
		applyColor();
	}
	
	void applyColor()
	{
		IupSetStrAttribute( GLOBAL.messageWindowTabs, "FGCOLOR", GLOBAL.editColor.outputFore.toCString );
		IupSetStrAttribute( GLOBAL.messageWindowTabs, "BGCOLOR", GLOBAL.editColor.outputBack.toCString );
		IupSetStrAttribute( GLOBAL.messageWindowTabs, "TABSFORECOLOR", GLOBAL.editColor.outlineFore.toCString );
		IupSetStrAttribute( GLOBAL.messageWindowTabs, "TABSBACKCOLOR", GLOBAL.editColor.outlineBack.toCString );		
		IupSetStrAttribute( GLOBAL.messageWindowTabs, "TABSLINECOLOR", GLOBAL.editColor.linenumBack.toCString );
		
		uint alpha = Integer.atoi( GLOBAL.editColor.selAlpha.toDString );
		if( alpha > 255 )
			alpha = 255;
		else if( alpha < 0 )
			alpha = 0;
			
		// outputPanel
		if( GLOBAL.editorSetting01.OutputSci == "ON" )
		{
			IupSetAttribute( outputPanel, "STYLEFGCOLOR32", GLOBAL.editColor.outputFore.toCString );		// 32
			IupSetAttribute( outputPanel, "STYLEBGCOLOR32", GLOBAL.editColor.outputBack.toCString );		// 32
		
			IupSetAttribute( outputPanel, "STYLECLEARALL", "Yes");  /* sets all styles to have the same attributes as 32 */
		}
		else
		{
			IupSetStrAttribute( outputPanel, "FGCOLOR", GLOBAL.editColor.outputFore.toCString );
			IupSetStrAttribute( outputPanel, "BGCOLOR", GLOBAL.editColor.outputBack.toCString );
		}
		/*
		IupSetAttribute( outputPanel, "STYLEFGCOLOR3", GLOBAL.editColor.keyWord[0].toCString );	// SCE_B_KEYWORD 3
		IupSetAttribute( outputPanel, "STYLEFGCOLOR10", GLOBAL.editColor.keyWord[1].toCString );	// SCE_B_KEYWORD2 10
		IupSetAttribute( outputPanel, "STYLEFGCOLOR11",  GLOBAL.editColor.keyWord[2].toCString );	// SCE_B_KEYWORD3 11
		IupSetAttribute( outputPanel, "STYLEFGCOLOR12",  GLOBAL.editColor.keyWord[3].toCString );	// SCE_B_KEYWORD4 12
		*/
		
		version(FBIDE)
		{
			if( GLOBAL.editorSetting01.OutputSci == "ON" )
			{
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
					IupScintillaSendMessage( outputPanel, 2067, true, tools.convertIupColor( GLOBAL.editColor.selectionFore.toDString ) );// SCI_SETSELFORE = 2067,
					IupScintillaSendMessage( outputPanel, 2068, true, tools.convertIupColor( GLOBAL.editColor.selectionBack.toDString ) );// SCI_SETSELBACK = 2068,
					IupScintillaSendMessage( outputPanel, 2478, 256, 0 );// SCI_SETSELALPHA   2478
				}
				else if( alpha == 0 )
				{
					IupScintillaSendMessage( outputPanel, 2067, false, tools.convertIupColor( GLOBAL.editColor.selectionFore.toDString ) );// SCI_SETSELFORE = 2067,
					IupScintillaSendMessage( outputPanel, 2068, true, tools.convertIupColor( GLOBAL.editColor.selectionBack.toDString ) );// SCI_SETSELBACK = 2068,
					IupScintillaSendMessage( outputPanel, 2478, 256, 0 );// SCI_SETSELALPHA   2478
				}
				else
				{
					IupScintillaSendMessage( outputPanel, 2067, false, tools.convertIupColor( GLOBAL.editColor.selectionFore.toDString ) );// SCI_SETSELFORE = 2067,
					IupScintillaSendMessage( outputPanel, 2068, true, tools.convertIupColor( GLOBAL.editColor.selectionBack.toDString ) );// SCI_SETSELBACK = 2068,
					IupScintillaSendMessage( outputPanel, 2478, alpha, 0 );// SCI_SETSELALPHA   2478
				}
			}
			// searchOutputPanel
			IupSetAttribute( searchOutputPanel, "STYLEFGCOLOR32", GLOBAL.editColor.searchFore.toCString );		// 32
			IupSetAttribute( searchOutputPanel, "STYLEBGCOLOR32", GLOBAL.editColor.searchBack.toCString );		// 32
			
			IupSetAttribute( searchOutputPanel, "STYLECLEARALL", "Yes");  /* sets all styles to have the same attributes as 32 */
			IupSetAttribute( searchOutputPanel, "STYLEFGCOLOR3", GLOBAL.editColor.keyWord[0].toCString );	// SCE_B_KEYWORD 3
			IupSetAttribute( searchOutputPanel, "STYLEFGCOLOR10", GLOBAL.editColor.keyWord[1].toCString );	// SCE_B_KEYWORD2 10
			IupSetAttribute( searchOutputPanel, "STYLEFGCOLOR11",  GLOBAL.editColor.keyWord[2].toCString );	// SCE_B_KEYWORD3 11
			IupSetAttribute( searchOutputPanel, "STYLEFGCOLOR12",  GLOBAL.editColor.keyWord[3].toCString );	// SCE_B_KEYWORD4 12
			IupSetAttribute( searchOutputPanel, "STYLEFGCOLOR23",  GLOBAL.editColor.keyWord[4].toCString );	// SCE_B_KEYWORD5 23
			IupSetAttribute( searchOutputPanel, "STYLEFGCOLOR24",  GLOBAL.editColor.keyWord[5].toCString );	// SCE_B_KEYWORD6 24
			
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
		}
		version(DIDE)
		{
			if( GLOBAL.editorSetting01.OutputSci == "ON" )
			{
				IupSetAttribute( outputPanel, "STYLEFGCOLOR12", GLOBAL.editColor.SCE_B_PREPROCESSOR_Fore.toCString );	// SCE_D_CHARACTER 12
				IupSetAttribute( outputPanel, "STYLEBGCOLOR12", GLOBAL.editColor.SCE_B_PREPROCESSOR_Back.toCString );	// SCE_D_CHARACTER 12
				
				/*
				IupSetAttribute( outputPanel, "STYLEFGCOLOR13", GLOBAL.editColor.SCE_B_OPERATOR_Fore.toCString );		// SCE_D_OPERATOR 13
				IupSetAttribute( outputPanel, "STYLEBGCOLOR13", GLOBAL.editColor.SCE_B_OPERATOR_Back.toCString );		// SCE_D_OPERATOR 13
				*/
				
				IupSetAttribute( outputPanel, "STYLEFGCOLOR5", GLOBAL.editColor.SCE_B_NUMBER_Fore.toCString );		// SCE_D_NUMBER 5
				IupSetAttribute( outputPanel, "STYLEBGCOLOR5", GLOBAL.editColor.SCE_B_NUMBER_Back.toCString );		// SCE_D_NUMBER 5

				/*
				IupSetAttribute( outputPanel, "STYLEFGCOLOR10", GLOBAL.editColor.SCE_B_STRING_Fore.toCString );		// SCE_D_STRING 10
				IupSetAttribute( outputPanel, "STYLEBGCOLOR10", GLOBAL.editColor.SCE_B_STRING_Back.toCString );		// SCE_D_STRING 10
				*/
				if( alpha == 255 )
				{
					IupScintillaSendMessage( outputPanel, 2067, true, tools.convertIupColor( GLOBAL.editColor.selectionFore.toDString ) );// SCI_SETSELFORE = 2067,
					IupScintillaSendMessage( outputPanel, 2068, true, tools.convertIupColor( GLOBAL.editColor.selectionBack.toDString ) );// SCI_SETSELBACK = 2068,
					IupScintillaSendMessage( outputPanel, 2478, 256, 0 );// SCI_SETSELALPHA   2478
				}
				else if( alpha == 0 )
				{
					IupScintillaSendMessage( outputPanel, 2067, false, tools.convertIupColor( GLOBAL.editColor.selectionFore.toDString ) );// SCI_SETSELFORE = 2067,
					IupScintillaSendMessage( outputPanel, 2068, true, tools.convertIupColor( GLOBAL.editColor.selectionBack.toDString ) );// SCI_SETSELBACK = 2068,
					IupScintillaSendMessage( outputPanel, 2478, 256, 0 );// SCI_SETSELALPHA   2478
				}
				else
				{
					IupScintillaSendMessage( outputPanel, 2067, false, tools.convertIupColor( GLOBAL.editColor.selectionFore.toDString ) );// SCI_SETSELFORE = 2067,
					IupScintillaSendMessage( outputPanel, 2068, true, tools.convertIupColor( GLOBAL.editColor.selectionBack.toDString ) );// SCI_SETSELBACK = 2068,
					IupScintillaSendMessage( outputPanel, 2478, alpha, 0 );// SCI_SETSELALPHA   2478
				}
			}
			// searchOutputPanel
			IupSetAttribute( searchOutputPanel, "STYLEFGCOLOR32", GLOBAL.editColor.searchFore.toCString );		// 32
			IupSetAttribute( searchOutputPanel, "STYLEBGCOLOR32", GLOBAL.editColor.searchBack.toCString );		// 32
			
			IupSetAttribute( searchOutputPanel, "STYLECLEARALL", "Yes");  /* sets all styles to have the same attributes as 32 */
			
			IupSetAttribute( searchOutputPanel, "STYLEFGCOLOR6", GLOBAL.editColor.keyWord[0].toCString );			// SCE_D_WORD 6	
			IupSetAttribute( searchOutputPanel, "STYLEFGCOLOR7", GLOBAL.editColor.keyWord[1].toCString );			// SCE_D_WORD2 7
			IupSetAttribute( searchOutputPanel, "STYLEFGCOLOR9",  GLOBAL.editColor.keyWord[2].toCString );			// SCE_D_WORD5 9
			IupSetAttribute( searchOutputPanel, "STYLEFGCOLOR20",  GLOBAL.editColor.keyWord[3].toCString );			// SCE_D_WORD6 20
			IupSetAttribute( searchOutputPanel, "STYLEFGCOLOR21",  GLOBAL.editColor.keyWord[4].toCString );			// SCE_D_WORD6 21
			IupSetAttribute( searchOutputPanel, "STYLEFGCOLOR22",  GLOBAL.editColor.keyWord[5].toCString );			// SCE_D_WORD7 22
			/*
			IupSetAttribute( searchOutputPanel, "STYLEFGCOLOR1", GLOBAL.editColor.SCE_B_COMMENT_Fore.toCString );		// SCE_D_COMMENT 1
			IupSetAttribute( searchOutputPanel, "STYLEBGCOLOR1", GLOBAL.editColor.SCE_B_COMMENT_Back.toCString );		// SCE_D_COMMENT 1
			*/
			IupSetAttribute( searchOutputPanel, "STYLEFGCOLOR2", GLOBAL.editColor.SCE_B_COMMENT_Fore.toCString );		// SCE_D_COMMENTLINE 2
			IupSetAttribute( searchOutputPanel, "STYLEBGCOLOR2", GLOBAL.editColor.SCE_B_COMMENT_Back.toCString );		// SCE_D_COMMENTLINE 2
			/*
			IupSetAttribute( searchOutputPanel, "STYLEFGCOLOR3", GLOBAL.editColor.SCE_B_COMMENT_Fore.toCString );		// SCE_D_COMMENTDOC 3
			IupSetAttribute( searchOutputPanel, "STYLEBGCOLOR3", GLOBAL.editColor.SCE_B_COMMENT_Back.toCString );		// SCE_D_COMMENTDOC 3
			*/

			IupSetAttribute( searchOutputPanel, "STYLEFGCOLOR5", GLOBAL.editColor.SCE_B_NUMBER_Fore.toCString );		// SCE_D_NUMBER 5
			IupSetAttribute( searchOutputPanel, "STYLEBGCOLOR5", GLOBAL.editColor.SCE_B_NUMBER_Back.toCString );		// SCE_D_NUMBER 5
			IupSetAttribute( searchOutputPanel, "STYLEFGCOLOR10", GLOBAL.editColor.SCE_B_STRING_Fore.toCString );		// SCE_D_STRING 10
			IupSetAttribute( searchOutputPanel, "STYLEBGCOLOR10", GLOBAL.editColor.SCE_B_STRING_Back.toCString );		// SCE_D_STRING 10
			IupSetAttribute( searchOutputPanel, "STYLEFGCOLOR12", GLOBAL.editColor.SCE_B_PREPROCESSOR_Fore.toCString );	// SCE_D_CHARACTER 12
			IupSetAttribute( searchOutputPanel, "STYLEBGCOLOR12", GLOBAL.editColor.SCE_B_PREPROCESSOR_Back.toCString );	// SCE_D_CHARACTER 12
			IupSetAttribute( searchOutputPanel, "STYLEFGCOLOR13", GLOBAL.editColor.SCE_B_OPERATOR_Fore.toCString );		// SCE_D_OPERATOR 13
			IupSetAttribute( searchOutputPanel, "STYLEBGCOLOR13", GLOBAL.editColor.SCE_B_OPERATOR_Back.toCString );		// SCE_D_OPERATOR 13	
		}
		
		if( GLOBAL.editorSetting01.OutputSci == "ON" )
		{
			// Caret Line ( Current Line )
			IupSetAttribute( outputPanel, "CARETLINEVISIBLE", toStringz( GLOBAL.editorSetting00.CaretLine ) );
			IupSetAttribute( outputPanel, "CARETLINEBACKCOLOR", GLOBAL.editColor.caretLine.toCString );
		}
		
		/*
		IupSetAttribute(searchOutputPanel, "STYLEBOLD3", "YES");
		IupSetAttribute(searchOutputPanel, "STYLEBOLD10", "YES");
		IupSetAttribute(searchOutputPanel, "STYLEBOLD11", "YES");
		IupSetAttribute(searchOutputPanel, "STYLEBOLD12", "YES");
		*/
		if( alpha == 255 )
		{
			IupScintillaSendMessage( searchOutputPanel, 2067, true, tools.convertIupColor( GLOBAL.editColor.selectionFore.toDString ) );// SCI_SETSELFORE = 2067,
			IupScintillaSendMessage( searchOutputPanel, 2068, true, tools.convertIupColor( GLOBAL.editColor.selectionBack.toDString ) );// SCI_SETSELBACK = 2068,
			IupScintillaSendMessage( searchOutputPanel, 2478, 256, 0 );// SCI_SETSELALPHA   2478
		}
		else if( alpha == 0 )
		{
			IupScintillaSendMessage( searchOutputPanel, 2067, false, tools.convertIupColor( GLOBAL.editColor.selectionFore.toDString ) );// SCI_SETSELFORE = 2067,
			IupScintillaSendMessage( searchOutputPanel, 2068, true, tools.convertIupColor( GLOBAL.editColor.selectionBack.toDString ) );// SCI_SETSELBACK = 2068,
			IupScintillaSendMessage( searchOutputPanel, 2478, 256, 0 );// SCI_SETSELALPHA   2478
		}
		else
		{
			IupScintillaSendMessage( searchOutputPanel, 2067, false, tools.convertIupColor( GLOBAL.editColor.selectionFore.toDString ) );// SCI_SETSELFORE = 2067,
			IupScintillaSendMessage( searchOutputPanel, 2068, true, tools.convertIupColor( GLOBAL.editColor.selectionBack.toDString ) );// SCI_SETSELBACK = 2068,
			IupScintillaSendMessage( searchOutputPanel, 2478, alpha, 0 );// SCI_SETSELALPHA   2478
		}

		// Caret Line ( Current Line )
		IupSetAttribute( searchOutputPanel, "CARETLINEVISIBLE", toStringz( GLOBAL.editorSetting00.CaretLine ) );
		IupSetAttribute( searchOutputPanel, "CARETLINEBACKCOLOR", GLOBAL.editColor.caretLine.toCString );
	}
	
	void printOutputPanel( char[] txt, bool bClear = false, bool bScrolltoBottom = true )
	{
		if( txt.length )
		{
			if( bClear ) IupSetStrAttribute( outputPanel, "VALUE", toStringz( txt ) ); else IupSetStrAttribute( outputPanel, "APPEND", toStringz( txt ) );
			version(linux) if( bScrolltoBottom ) scrollOutputPanel( -1 );
		}
		else
		{
			if( bClear ) IupSetAttribute( outputPanel, "VALUE", "" ); else IupSetAttribute( outputPanel, "APPEND", "" );
		}
	}
	
	void printSearchOutputPanel( char[] txt, bool bClear = false, bool bScrolltoBottom = true )
	{
		if( txt.length )
		{
			if( bClear ) IupSetStrAttribute( searchOutputPanel, "VALUE", toStringz( txt ) ); else IupSetStrAttribute( searchOutputPanel, "APPEND", toStringz( txt ) );
			if( bScrolltoBottom ) scrollSearchOutputPanel( -1 );
		}
		else
		{
			if( bClear ) IupSetAttribute( searchOutputPanel, "VALUE", "" ); else IupSetAttribute( searchOutputPanel, "APPEND", "" );
		}
	}
	
	void applyOutputPanelINDICATOR()
	{
		IupScintillaSendMessage( outputPanel, 2505, 0, IupGetInt( outputPanel, "COUNT" ) ); // SCI_INDICATORCLEARRANGE = 2505
		IupScintillaSendMessage( outputPanel, 2500, 4, 0 ); // SCI_SETINDICATORCURRENT = 2500
		
		foreach( int LineNum, char[] lineText; Util.splitLines( fromStringz( IupGetAttribute( outputPanel, "VALUE" ) ) ) )
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
		}
	}
	
	void applyOutputPanelINDICATOR2()
	{
		IupScintillaSendMessage( outputPanel, 2505, 0, IupGetInt( outputPanel, "COUNT" ) ); // SCI_INDICATORCLEARRANGE = 2505
		IupScintillaSendMessage( outputPanel, 2500, 4, 0 ); // SCI_SETINDICATORCURRENT = 2500
		
		foreach( int LineNum, char[] lineText; Util.splitLines( fromStringz( IupGetAttribute( outputPanel, "VALUE" ) ) ) )
		{
			if( lineText.length )
			{
				int lineHeadPos = cast(int) IupScintillaSendMessage( outputPanel, 2167, LineNum, 0 ); //SCI_POSITIONFROMLINE 2167
				char[] triml_lineText = Util.triml( lineText );
				lineHeadPos += ( lineText.length - triml_lineText.length );
				IupScintillaSendMessage( outputPanel, 2504, lineHeadPos, triml_lineText.length ); // SCI_INDICATORFILLRANGE =  2504
			}
		}
	}
	
	void applySearchOutputPanelINDICATOR()
	{
		IupScintillaSendMessage( searchOutputPanel, 2505, 0, IupGetInt( searchOutputPanel, "COUNT" ) ); // SCI_INDICATORCLEARRANGE = 2505
		IupScintillaSendMessage( searchOutputPanel, 2500, 4, 0 ); // SCI_SETINDICATORCURRENT = 2500
		
		foreach( int LineNum, char[] lineText; Util.splitLines( fromStringz( IupGetAttribute( searchOutputPanel, "VALUE" ) ) ) )
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
		}
	}
	
	void scrollOutputPanel( int pos )
	{
		//IupSetInt( outputPanel, "SCROLLTOPOS", pos );
		if( pos < 0 ) IupSetInt( outputPanel, "CARETPOS", IupGetInt( outputPanel, "COUNT" ) ); else IupSetInt( outputPanel, "CARETPOS", pos );
	}
	
	void scrollSearchOutputPanel( int pos )
	{
		//IupSetInt( searchOutputPanel, "SCROLLTOPOS", pos );
		if( pos < 0 ) IupSetInt( searchOutputPanel, "CARETPOS", IupGetInt( searchOutputPanel, "COUNT" ) ); else IupSetInt( searchOutputPanel, "CARETPOS", pos );
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
	private void right_click( bool bIsOutputPanel )
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
		
		if( !bIsOutputPanel )
		{
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
		}
		else
		{
		popupMenu = IupMenu(
							_copy,
							_selectall,
							_clear,
							null
							);
		
		}

		IupPopup( popupMenu, IUP_MOUSEPOS, IUP_MOUSEPOS );
		IupDestroy( popupMenu );
	}
	
	private int outputPanelButton_cb(Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		if( button == IUP_BUTTON1 )
		{
			char[] statusUTF8 = fromStringz( status ).dup;
			if( statusUTF8.length > 5 )
			{
				if( statusUTF8[5] == 'D' )
				{
					int		lineNumber;
					bool	bGetFileName = true;
					char[]	fileName;
					char[]	lineText = fromStringz( IupGetAttribute( ih, "LINEVALUE" ) ).dup;

					version(FBIDE)
					{
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
											
											if( ExecuterAction.quickRunFile.length )
											{
												if( !Path.parent( fileName ).length ) fileName = ExecuterAction.quickRunFile;
											}
											
											if( fullPathByOS(fileName) in GLOBAL.scintillaManager )
											{
												if( GLOBAL.navigation.addCache( fileName, lineNumber ) ) ScintillaAction.openFile( fileName, lineNumber );
											}
											else
											{
												GLOBAL.navigation.addCache( fileName, lineNumber );
												if( ScintillaAction.openFile( fileName, lineNumber ) )
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
																			if( fullPathByOS(filePath) in GLOBAL.scintillaManager )
																			{
																				CScintilla cSci = GLOBAL.scintillaManager[fullPathByOS(filePath)];

																				int		ln = Integer.atoi( s[lineNumberHead..lineNumberTail] ) - 1;
																				char[]	annotationText = s[lineNumberTail+2..$];
																				
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
																				IupSetAttribute( GLOBAL.scintillaManager[fullPathByOS(fileName)].getIupScintilla, "ANNOTATIONVISIBLE", "BOXED" );
																			}
																		}
																	}
																}
															}
														}
														//IupSetAttribute( GLOBAL.scintillaManager[fullPathByOS(fileName.dup)].getIupScintilla, "ANNOTATIONVISIBLE", "BOXED" );
													}
												}
											}

											// Make all line be selected
											if( GLOBAL.editorSetting01.OutputSci == "ON" )
											{
												int	_line = ScintillaAction.getLinefromPos( ih, ScintillaAction.getCurrentPos( ih ) );
												IupSetAttribute( ih, "SELECTION", toStringz( Integer.toString( _line ) ~ ",0:" ~ Integer.toString( _line ) ~ "," ~ Integer.toString( lineText.length - 1 ) ) );										
											}
											else
											{
												int pos = IupConvertXYToPos( ih, x, y );
												int _line, col;
												IupTextConvertPosToLinCol( ih, pos, &_line, &col );
												IupSetAttribute( ih, "SELECTION", toStringz( Integer.toString( _line ) ~ ",1:" ~ Integer.toString( _line ) ~ "," ~ Integer.toString( lineText.length + 1 ) ) );										
											}
											
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
					version(DIDE)
					{
						int closePos = Util.index( lineText, "): " );
						if( closePos < lineText.length )
						{
							int openPos = Util.rindex( lineText, "(", closePos );
							if( openPos < lineText.length )
							{
								char[] lineNumber_char = lineText[openPos+1..closePos];
								lineNumber = Integer.atoi( lineNumber_char );
								
								if( Util.index( lineText, "warning - " ) == 0 )	fileName = Path.normalize( lineText[10..openPos] ); else fileName =  Path.normalize( lineText[0..openPos] );
								if( fullPathByOS(fileName) in GLOBAL.scintillaManager )
								{
									if( GLOBAL.navigation.addCache( fileName, lineNumber ) ) ScintillaAction.openFile( fileName, lineNumber );
								}
								else
								{
									GLOBAL.navigation.addCache( fileName, lineNumber );
									if( ScintillaAction.openFile( fileName, lineNumber ) )
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

													if( Util.index( s, "warning - " ) == 0 ) bWarning = true;
													int lineNumberTail = Util.index( s, "): " );
													if( lineNumberTail < s.length )
													{
														int lineNumberHead = Util.rindex( s, "(", lineNumberTail );
														if( lineNumberHead < lineNumberTail - 1 )
														{
															char[]	filePath = bWarning ? Util.replace( s[10..lineNumberHead++], '\\', '/' ) : Util.replace( s[0..lineNumberHead++], '\\', '/' );
															if( fileName == filePath )
															{
																if( fullPathByOS(filePath) in GLOBAL.scintillaManager )
																{
																	CScintilla cSci = GLOBAL.scintillaManager[fullPathByOS(filePath)];

																	int		ln = Integer.atoi( s[lineNumberHead..lineNumberTail] ) - 1;
																	char[]	annotationText = s[lineNumberTail+2..$];
																	
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
																	IupSetAttribute( GLOBAL.scintillaManager[fullPathByOS(fileName)].getIupScintilla, "ANNOTATIONVISIBLE", "BOXED" );
																}
															}
														}
													}
												}
											}
											//IupSetAttribute( GLOBAL.scintillaManager[fullPathByOS(fileName.dup)].getIupScintilla, "ANNOTATIONVISIBLE", "BOXED" );
										}
									}
								}

								// Make all line be selected
								if( GLOBAL.editorSetting01.OutputSci == "ON" )
								{
									int	_line = ScintillaAction.getLinefromPos( ih, ScintillaAction.getCurrentPos( ih ) );
									IupSetAttribute( ih, "SELECTION", toStringz( Integer.toString( _line ) ~ ",0:" ~ Integer.toString( _line ) ~ "," ~ Integer.toString( lineText.length - 1 ) ) );
								}
								else
								{
									int pos = IupConvertXYToPos( ih, x, y );
									int _line, col;
									IupTextConvertPosToLinCol( ih, pos, &_line, &col );
									IupSetAttribute( ih, "SELECTION", toStringz( Integer.toString( _line ) ~ ",1:" ~ Integer.toString( _line ) ~ "," ~ Integer.toString( lineText.length + 1 ) ) );										
								}
								
								return IUP_IGNORE;
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
		}
		else if( button == IUP_BUTTON3 )
		{
			right_click( true );
			return IUP_IGNORE;
		}
		
		return IUP_DEFAULT;
	}

	private int searchOutputButton_cb( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		if( button == IUP_BUTTON1 )
		{
			char[] statusUTF8 = fromStringz( status ).dup;
			if( statusUTF8.length > 5 )
			{
				if( pressed == 1 )
				{
					if( statusUTF8[5] == 'D' ) // Double Click!
					{
						int		lineNumber;
						bool	bGetFileName = true;
						char[]	fileName;
						char[]	lineText = fromStringz( IupGetAttribute( ih, "LINEVALUE" ) ).dup;
						
						int closePos = Util.index( lineText, "):" );
						if( closePos < lineText.length )
						{
							lineText = lineText[0..closePos];
							int openPos = Util.rindex( lineText[], "(" );
							if( openPos < lineText.length )
							{
								char[] lineNumber_char = lineText[openPos+1..$];
								lineNumber = Integer.toInt( lineNumber_char );
								fileName = lineText[0..openPos];
								GLOBAL.navigation.addCache( fileName, lineNumber );
								if( ScintillaAction.openFile( fileName, lineNumber ) )
								{
									int	_line = ScintillaAction.getLinefromPos( ih, ScintillaAction.getCurrentPos( ih ) );
									int	lineHead = cast(int) IupScintillaSendMessage( ih, 2167, _line, 0 ); // SCI_POSITIONFROMLINE 2167
									int	lineTail = cast(int) IupScintillaSendMessage( ih, 2136, _line, 0 ); // SCI_GETLINEENDPOSITION 2136
									IupScintillaSendMessage( ih, 2160, lineHead, lineTail ); // SCI_SETSEL 2160
									
									version(Windows) return IUP_DEFAULT; else return IUP_IGNORE;
								}
							}
						}
						
						version(Windows) return IUP_DEFAULT; else return IUP_IGNORE;
					}
				}
			}
		}
		else if( button == IUP_BUTTON3 )
		{
			right_click( false );
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
			if( _ih == GLOBAL.messagePanel.getOutputPanelHandle )
				IupSetAttribute( _ih, "VALUE", "" );
			else
				IupSetAttribute( _ih, "CLEARALL", "YES" );
			
		}
		return IUP_DEFAULT;
	}
}