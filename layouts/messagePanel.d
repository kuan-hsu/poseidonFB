module layouts.messagePanel;

private import iup.iup;
private import iup.iup_scintilla;
private import global, scintilla, actionManager, tools;
private import std.string, std.conv, std.file, Array = std.array, Path = std.path, Uni = std.uni;

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
		
		changeIcon();
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
			IupSetStrAttributeId( outputPanel, "INDICATORFGCOLOR", 4, toStringz( GLOBAL.editColor.searchIndicator ) );
			IupSetIntId( outputPanel, "INDICATORALPHA", 4, to!(int)( GLOBAL.editColor.searchIndicatorAlpha ) );
		}
		
		// scintilla
		version(FBIDE) IupSetAttribute( searchOutputPanel, "LEXERLANGUAGE", "freebasic"); else IupSetAttribute( searchOutputPanel, "LEXERLANGUAGE", "d" );
		for( int i = 0; i < 6; ++i )
		{
			string _key = strip( GLOBAL.KEYWORDS[i] );
			if( _key.length ) IupSetStrAttribute( searchOutputPanel, toStringz( "KEYWORDS" ~ to!(string)( i ) ), toStringz( Uni.toLower( _key ) ) ); else IupSetStrAttribute( searchOutputPanel, toStringz( "KEYWORDS" ~ to!(string)( i ) ), "" );
		}			
		
		IupSetAttribute( searchOutputPanel, "WORDWRAP", "CHAR" );	// SCE_B_KEYWORD4 12
		IupSetAttributeId( searchOutputPanel, "INDICATORSTYLE", 4, "DOTBOX" );
		IupSetStrAttributeId( searchOutputPanel, "INDICATORFGCOLOR", 4, toStringz( GLOBAL.editColor.searchIndicator ) );
		IupSetIntId( searchOutputPanel, "INDICATORALPHA", 4, to!(int)( GLOBAL.editColor.searchIndicatorAlpha ) );
		
		applyColor();
		changeIcon();
	}
	
	void changeIcon()
	{
		if( GLOBAL.editorSetting00.IconInvert == "ON" )
		{
			IupSetAttribute( outputPanel, "TABIMAGE", "icon_message_invert" );
			IupSetAttribute( searchOutputPanel, "TABIMAGE", "icon_search_invert" );
		}
		else
		{
			IupSetAttribute( outputPanel, "TABIMAGE", "icon_message" );
			IupSetAttribute( searchOutputPanel, "TABIMAGE", "icon_search" );
		}
	}
	
	void applyColor()
	{
		IupSetStrAttribute( GLOBAL.messageWindowTabs, "FGCOLOR", toStringz( GLOBAL.editColor.outputFore ) );
		IupSetStrAttribute( GLOBAL.messageWindowTabs, "BGCOLOR", toStringz( GLOBAL.editColor.outputBack ) );
		IupSetStrAttribute( GLOBAL.messageWindowTabs, "TABSFORECOLOR", toStringz( GLOBAL.editColor.outlineFore ) );
		IupSetStrAttribute( GLOBAL.messageWindowTabs, "TABSBACKCOLOR", toStringz( GLOBAL.editColor.outlineBack ) );		
		IupSetStrAttribute( GLOBAL.messageWindowTabs, "TABSLINECOLOR", toStringz( GLOBAL.editColor.linenumBack ) );
		
		uint alpha = to!(int)( GLOBAL.editColor.selAlpha );
		if( alpha > 255 )
			alpha = 255;
		else if( alpha < 0 )
			alpha = 0;
			
		// outputPanel
		if( GLOBAL.editorSetting01.OutputSci == "ON" )
		{
			IupSetStrAttribute( outputPanel, "STYLEFGCOLOR32", toStringz( GLOBAL.editColor.outputFore ) );		// 32
			IupSetStrAttribute( outputPanel, "STYLEBGCOLOR32", toStringz( GLOBAL.editColor.outputBack ) );		// 32
			IupSetAttribute( outputPanel, "STYLECLEARALL", "Yes");  /* sets all styles to have the same attributes as 32 */
		}
		else
		{
			IupSetStrAttribute( outputPanel, "FGCOLOR", toStringz( GLOBAL.editColor.outputFore ) );
			IupSetStrAttribute( outputPanel, "BGCOLOR", toStringz( GLOBAL.editColor.outputBack ) );
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
				IupSetStrAttribute( outputPanel, "STYLEFGCOLOR1", toStringz( GLOBAL.editColor.SCE_B_COMMENT_Fore ) );		// SCE_B_COMMENT 1
				IupSetStrAttribute( outputPanel, "STYLEBGCOLOR1", toStringz( GLOBAL.editColor.SCE_B_COMMENT_Back ) );		// SCE_B_COMMENT 1
				
				/*
				IupSetAttribute( outputPanel, "STYLEFGCOLOR6", GLOBAL.editColor.SCE_B_OPERATOR_Fore.toCString );		// SCE_B_OPERATOR 6
				IupSetAttribute( outputPanel, "STYLEBGCOLOR6", GLOBAL.editColor.SCE_B_OPERATOR_Back.toCString );		// SCE_B_OPERATOR 6
				*/
				IupSetStrAttribute( outputPanel, "STYLEFGCOLOR2", toStringz( GLOBAL.editColor.SCE_B_NUMBER_Fore ) );		// SCE_B_NUMBER 2
				IupSetStrAttribute( outputPanel, "STYLEBGCOLOR2", toStringz( GLOBAL.editColor.SCE_B_NUMBER_Back ) );		// SCE_B_NUMBER 2

				/*
				IupSetAttribute( outputPanel, "STYLEFGCOLOR4", GLOBAL.editColor.SCE_B_STRING_Fore.toCString );		// SCE_B_STRING 4
				IupSetAttribute( outputPanel, "STYLEBGCOLOR4", GLOBAL.editColor.SCE_B_STRING_Back.toCString );		// SCE_B_STRING 4
				*/
				if( alpha == 255 )
				{
					IupScintillaSendMessage( outputPanel, 2067, true, tools.convertIupColor( GLOBAL.editColor.selectionFore ) );// SCI_SETSELFORE = 2067,
					IupScintillaSendMessage( outputPanel, 2068, true, tools.convertIupColor( GLOBAL.editColor.selectionBack ) );// SCI_SETSELBACK = 2068,
					IupScintillaSendMessage( outputPanel, 2478, 256, 0 );// SCI_SETSELALPHA   2478
				}
				else if( alpha == 0 )
				{
					IupScintillaSendMessage( outputPanel, 2067, false, tools.convertIupColor( GLOBAL.editColor.selectionFore ) );// SCI_SETSELFORE = 2067,
					IupScintillaSendMessage( outputPanel, 2068, true, tools.convertIupColor( GLOBAL.editColor.selectionBack ) );// SCI_SETSELBACK = 2068,
					IupScintillaSendMessage( outputPanel, 2478, 256, 0 );// SCI_SETSELALPHA   2478
				}
				else
				{
					IupScintillaSendMessage( outputPanel, 2067, false, tools.convertIupColor( GLOBAL.editColor.selectionFore ) );// SCI_SETSELFORE = 2067,
					IupScintillaSendMessage( outputPanel, 2068, true, tools.convertIupColor( GLOBAL.editColor.selectionBack ) );// SCI_SETSELBACK = 2068,
					IupScintillaSendMessage( outputPanel, 2478, alpha, 0 );// SCI_SETSELALPHA   
				}
			}
			// searchOutputPanel
			IupSetStrAttribute( searchOutputPanel, "STYLEFGCOLOR32", toStringz( GLOBAL.editColor.searchFore ) );		// 32
			IupSetStrAttribute( searchOutputPanel, "STYLEBGCOLOR32", toStringz( GLOBAL.editColor.searchBack ) );		// 32
			
			IupSetAttribute( searchOutputPanel, "STYLECLEARALL", "Yes");  /* sets all styles to have the same attributes as 32 */
			IupSetStrAttribute( searchOutputPanel, "STYLEFGCOLOR3", toStringz( GLOBAL.editColor.keyWord[0] ) );	// SCE_B_KEYWORD 3
			IupSetStrAttribute( searchOutputPanel, "STYLEFGCOLOR10", toStringz( GLOBAL.editColor.keyWord[1] ) );	// SCE_B_KEYWORD2 10
			IupSetStrAttribute( searchOutputPanel, "STYLEFGCOLOR11",  toStringz( GLOBAL.editColor.keyWord[2] ) );	// SCE_B_KEYWORD3 11
			IupSetStrAttribute( searchOutputPanel, "STYLEFGCOLOR12",  toStringz( GLOBAL.editColor.keyWord[3] ) );	// SCE_B_KEYWORD4 12
			IupSetStrAttribute( searchOutputPanel, "STYLEFGCOLOR23",  toStringz( GLOBAL.editColor.keyWord[4] ) );	// SCE_B_KEYWORD5 23
			IupSetStrAttribute( searchOutputPanel, "STYLEFGCOLOR24",  toStringz( GLOBAL.editColor.keyWord[5] ) );	// SCE_B_KEYWORD6 24
			
			IupSetStrAttribute( searchOutputPanel, "STYLEFGCOLOR1", toStringz( GLOBAL.editColor.SCE_B_COMMENT_Fore ) );		// SCE_B_COMMENT 1
			IupSetStrAttribute( searchOutputPanel, "STYLEBGCOLOR1", toStringz( GLOBAL.editColor.SCE_B_COMMENT_Back ) );		// SCE_B_COMMENT 1
			IupSetStrAttribute( searchOutputPanel, "STYLEFGCOLOR2", toStringz( GLOBAL.editColor.SCE_B_NUMBER_Fore ) );		// SCE_B_NUMBER 2
			IupSetStrAttribute( searchOutputPanel, "STYLEBGCOLOR2", toStringz( GLOBAL.editColor.SCE_B_NUMBER_Back ) );		// SCE_B_NUMBER 2
			IupSetStrAttribute( searchOutputPanel, "STYLEFGCOLOR4", toStringz( GLOBAL.editColor.SCE_B_STRING_Fore ) );		// SCE_B_STRING 4
			IupSetStrAttribute( searchOutputPanel, "STYLEBGCOLOR4", toStringz( GLOBAL.editColor.SCE_B_STRING_Back ) );		// SCE_B_STRING 4
			//IupSetAttribute( searchOutputPanel, "STYLEFGCOLOR5", toStringz( GLOBAL.editColor.SCE_B_PREPROCESSOR_Fore.toCString );	// SCE_B_PREPROCESSOR 5
			//IupSetAttribute( searchOutputPanel, "STYLEBGCOLOR5", toStringz( GLOBAL.editColor.SCE_B_PREPROCESSOR_Back.toCString );	// SCE_B_PREPROCESSOR 5
			IupSetStrAttribute( searchOutputPanel, "STYLEFGCOLOR6", toStringz( GLOBAL.editColor.SCE_B_OPERATOR_Fore ) );		// SCE_B_OPERATOR 6
			IupSetStrAttribute( searchOutputPanel, "STYLEBGCOLOR6", toStringz( GLOBAL.editColor.SCE_B_OPERATOR_Back ) );		// SCE_B_OPERATOR 6
		}
		version(DIDE)
		{
			if( GLOBAL.editorSetting01.OutputSci == "ON" )
			{
				IupSetStrAttribute( outputPanel, "STYLEFGCOLOR12", toStringz( GLOBAL.editColor.SCE_B_PREPROCESSOR_Fore ) );	// SCE_D_CHARACTER 12
				IupSetStrAttribute( outputPanel, "STYLEBGCOLOR12", toStringz( GLOBAL.editColor.SCE_B_PREPROCESSOR_Back ) );	// SCE_D_CHARACTER 12
				
				/*
				IupSetStrAttribute( outputPanel, "STYLEFGCOLOR13", toStringz( GLOBAL.editColor.SCE_B_OPERATOR_Fore.toCString );		// SCE_D_OPERATOR 13
				IupSetStrAttribute( outputPanel, "STYLEBGCOLOR13", toStringz( GLOBAL.editColor.SCE_B_OPERATOR_Back.toCString );		// SCE_D_OPERATOR 13
				*/
				
				IupSetStrAttribute( outputPanel, "STYLEFGCOLOR5", toStringz( GLOBAL.editColor.SCE_B_NUMBER_Fore ) );		// SCE_D_NUMBER 5
				IupSetStrAttribute( outputPanel, "STYLEBGCOLOR5", toStringz( GLOBAL.editColor.SCE_B_NUMBER_Back ) );		// SCE_D_NUMBER 5

				/*
				IupSetStrAttribute( outputPanel, "STYLEFGCOLOR10", toStringz( GLOBAL.editColor.SCE_B_STRING_Fore.toCString );		// SCE_D_STRING 10
				IupSetStrAttribute( outputPanel, "STYLEBGCOLOR10", toStringz( GLOBAL.editColor.SCE_B_STRING_Back.toCString );		// SCE_D_STRING 10
				*/
				if( alpha == 255 )
				{
					IupScintillaSendMessage( outputPanel, 2067, true, tools.convertIupColor( GLOBAL.editColor.selectionFore ) );// SCI_SETSELFORE = 2067,
					IupScintillaSendMessage( outputPanel, 2068, true, tools.convertIupColor( GLOBAL.editColor.selectionBack ) );// SCI_SETSELBACK = 2068,
					IupScintillaSendMessage( outputPanel, 2478, 256, 0 );// SCI_SETSELALPHA   2478
				}
				else if( alpha == 0 )
				{
					IupScintillaSendMessage( outputPanel, 2067, false, tools.convertIupColor( GLOBAL.editColor.selectionFore ) );// SCI_SETSELFORE = 2067,
					IupScintillaSendMessage( outputPanel, 2068, true, tools.convertIupColor( GLOBAL.editColor.selectionBack ) );// SCI_SETSELBACK = 2068,
					IupScintillaSendMessage( outputPanel, 2478, 256, 0 );// SCI_SETSELALPHA   2478
				}
				else
				{
					IupScintillaSendMessage( outputPanel, 2067, false, tools.convertIupColor( GLOBAL.editColor.selectionFore ) );// SCI_SETSELFORE = 2067,
					IupScintillaSendMessage( outputPanel, 2068, true, tools.convertIupColor( GLOBAL.editColor.selectionBack ) );// SCI_SETSELBACK = 2068,
					IupScintillaSendMessage( outputPanel, 2478, alpha, 0 );// SCI_SETSELALPHA   2478
				}
			}
			// searchOutputPanel
			IupSetStrAttribute( searchOutputPanel, "STYLEFGCOLOR32", toStringz( GLOBAL.editColor.searchFore ) );		// 32
			IupSetStrAttribute( searchOutputPanel, "STYLEBGCOLOR32", toStringz( GLOBAL.editColor.searchBack ) );		// 32
			
			IupSetStrAttribute( searchOutputPanel, "STYLECLEARALL", "Yes");  /* sets all styles to have the same attributes as 32 */
			
			IupSetStrAttribute( searchOutputPanel, "STYLEFGCOLOR6", toStringz( GLOBAL.editColor.keyWord[0] ) );			// SCE_D_WORD 6	
			IupSetStrAttribute( searchOutputPanel, "STYLEFGCOLOR7", toStringz( GLOBAL.editColor.keyWord[1] ) );			// SCE_D_WORD2 7
			IupSetStrAttribute( searchOutputPanel, "STYLEFGCOLOR9",  toStringz( GLOBAL.editColor.keyWord[2] ) );			// SCE_D_WORD5 9
			IupSetStrAttribute( searchOutputPanel, "STYLEFGCOLOR20",  toStringz( GLOBAL.editColor.keyWord[3] ) );			// SCE_D_WORD6 20
			IupSetStrAttribute( searchOutputPanel, "STYLEFGCOLOR21",  toStringz( GLOBAL.editColor.keyWord[4] ) );			// SCE_D_WORD6 21
			IupSetStrAttribute( searchOutputPanel, "STYLEFGCOLOR22",  toStringz( GLOBAL.editColor.keyWord[5] ) );			// SCE_D_WORD7 22
			/*
			IupSetStrAttribute( searchOutputPanel, "STYLEFGCOLOR1", toStringz( GLOBAL.editColor.SCE_B_COMMENT_Fore.toCString );		// SCE_D_COMMENT 1
			IupSetStrAttribute( searchOutputPanel, "STYLEBGCOLOR1", toStringz( GLOBAL.editColor.SCE_B_COMMENT_Back.toCString );		// SCE_D_COMMENT 1
			*/
			IupSetStrAttribute( searchOutputPanel, "STYLEFGCOLOR2", toStringz( GLOBAL.editColor.SCE_B_COMMENT_Fore ) );		// SCE_D_COMMENTLINE 2
			IupSetStrAttribute( searchOutputPanel, "STYLEBGCOLOR2", toStringz( GLOBAL.editColor.SCE_B_COMMENT_Back ) );		// SCE_D_COMMENTLINE 2
			/*
			IupSetAttribute( searchOutputPanel, "STYLEFGCOLOR3", toStringz( GLOBAL.editColor.SCE_B_COMMENT_Fore.toCString );		// SCE_D_COMMENTDOC 3
			IupSetAttribute( searchOutputPanel, "STYLEBGCOLOR3", toStringz( GLOBAL.editColor.SCE_B_COMMENT_Back.toCString );		// SCE_D_COMMENTDOC 3
			*/

			IupSetStrAttribute( searchOutputPanel, "STYLEFGCOLOR5", toStringz( GLOBAL.editColor.SCE_B_NUMBER_Fore ) );		// SCE_D_NUMBER 5
			IupSetStrAttribute( searchOutputPanel, "STYLEBGCOLOR5", toStringz( GLOBAL.editColor.SCE_B_NUMBER_Back ) );		// SCE_D_NUMBER 5
			IupSetStrAttribute( searchOutputPanel, "STYLEFGCOLOR10", toStringz( GLOBAL.editColor.SCE_B_STRING_Fore ) );		// SCE_D_STRING 10
			IupSetStrAttribute( searchOutputPanel, "STYLEBGCOLOR10", toStringz( GLOBAL.editColor.SCE_B_STRING_Back ) );		// SCE_D_STRING 10
			IupSetStrAttribute( searchOutputPanel, "STYLEFGCOLOR12", toStringz( GLOBAL.editColor.SCE_B_PREPROCESSOR_Fore ) );	// SCE_D_CHARACTER 12
			IupSetStrAttribute( searchOutputPanel, "STYLEBGCOLOR12", toStringz( GLOBAL.editColor.SCE_B_PREPROCESSOR_Back ) );	// SCE_D_CHARACTER 12
			IupSetStrAttribute( searchOutputPanel, "STYLEFGCOLOR13", toStringz( GLOBAL.editColor.SCE_B_OPERATOR_Fore ) );		// SCE_D_OPERATOR 13
			IupSetStrAttribute( searchOutputPanel, "STYLEBGCOLOR13", toStringz( GLOBAL.editColor.SCE_B_OPERATOR_Back ) );		// SCE_D_OPERATOR 13	
		}
		
		if( GLOBAL.editorSetting01.OutputSci == "ON" )
		{
			// Caret Line ( Current Line )
			IupSetStrAttribute( outputPanel, "CARETLINEVISIBLE", toStringz( GLOBAL.editorSetting00.CaretLine ) );
			IupSetStrAttribute( outputPanel, "CARETLINEBACKCOLOR", toStringz( GLOBAL.editColor.caretLine ) );
		}
		
		/*
		IupSetAttribute(searchOutputPanel, "STYLEBOLD3", "YES");
		IupSetAttribute(searchOutputPanel, "STYLEBOLD10", "YES");
		IupSetAttribute(searchOutputPanel, "STYLEBOLD11", "YES");
		IupSetAttribute(searchOutputPanel, "STYLEBOLD12", "YES");
		*/
		if( alpha == 255 )
		{
			IupScintillaSendMessage( searchOutputPanel, 2067, true, tools.convertIupColor( GLOBAL.editColor.selectionFore ) );// SCI_SETSELFORE = 2067,
			IupScintillaSendMessage( searchOutputPanel, 2068, true, tools.convertIupColor( GLOBAL.editColor.selectionBack ) );// SCI_SETSELBACK = 2068,
			IupScintillaSendMessage( searchOutputPanel, 2478, 256, 0 );// SCI_SETSELALPHA   2478
		}
		else if( alpha == 0 )
		{
			IupScintillaSendMessage( searchOutputPanel, 2067, false, tools.convertIupColor( GLOBAL.editColor.selectionFore ) );// SCI_SETSELFORE = 2067,
			IupScintillaSendMessage( searchOutputPanel, 2068, true, tools.convertIupColor( GLOBAL.editColor.selectionBack ) );// SCI_SETSELBACK = 2068,
			IupScintillaSendMessage( searchOutputPanel, 2478, 256, 0 );// SCI_SETSELALPHA   2478
		}
		else
		{
			IupScintillaSendMessage( searchOutputPanel, 2067, false, tools.convertIupColor( GLOBAL.editColor.selectionFore ) );// SCI_SETSELFORE = 2067,
			IupScintillaSendMessage( searchOutputPanel, 2068, true, tools.convertIupColor( GLOBAL.editColor.selectionBack ) );// SCI_SETSELBACK = 2068,
			IupScintillaSendMessage( searchOutputPanel, 2478, alpha, 0 );// SCI_SETSELALPHA   2478
		}

		// Caret Line ( Current Line )
		IupSetStrAttribute( searchOutputPanel, "CARETLINEVISIBLE", toStringz( GLOBAL.editorSetting00.CaretLine ) );
		IupSetStrAttribute( searchOutputPanel, "CARETLINEBACKCOLOR", toStringz( GLOBAL.editColor.caretLine ) );
	}
	
	void printOutputPanel( string txt, bool bClear = false, bool bScrolltoBottom = true )
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
	
	void printSearchOutputPanel( string txt, bool bClear = false, bool bScrolltoBottom = true )
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
		
		foreach( int LineNum, string lineText; splitLines( fSTRz( IupGetAttribute( outputPanel, "VALUE" ) ) ) )
		{
			if( lineText.length )
			{
				int openPos = indexOf( lineText, "(" );
				if( openPos > 0 )
				{
					int closePos = indexOf( lineText, ")", openPos );
					if( closePos > openPos + 1 )
					{
						int colonPos = indexOf( lineText, ": ", closePos );
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
	
	void applyOutputPanelINDICATOR2()
	{
		IupScintillaSendMessage( outputPanel, 2505, 0, IupGetInt( outputPanel, "COUNT" ) ); // SCI_INDICATORCLEARRANGE = 2505
		IupScintillaSendMessage( outputPanel, 2500, 4, 0 ); // SCI_SETINDICATORCURRENT = 2500
		
		foreach( int LineNum, string lineText; splitLines( fSTRz( IupGetAttribute( outputPanel, "VALUE" ) ) ) )
		{
			if( lineText.length )
			{
				int lineHeadPos = cast(int) IupScintillaSendMessage( outputPanel, 2167, LineNum, 0 ); //SCI_POSITIONFROMLINE 2167
				string triml_lineText = strip( lineText );
				lineHeadPos += ( lineText.length - triml_lineText.length );
				IupScintillaSendMessage( outputPanel, 2504, lineHeadPos, triml_lineText.length ); // SCI_INDICATORFILLRANGE =  2504
			}
		}
	}
	
	void applySearchOutputPanelINDICATOR()
	{
		IupScintillaSendMessage( searchOutputPanel, 2505, 0, IupGetInt( searchOutputPanel, "COUNT" ) ); // SCI_INDICATORCLEARRANGE = 2505
		IupScintillaSendMessage( searchOutputPanel, 2500, 4, 0 ); // SCI_SETINDICATORCURRENT = 2500
		
		foreach( int LineNum, string lineText; splitLines( fSTRz( IupGetAttribute( searchOutputPanel, "VALUE" ) ) ) )
		{
			if( lineText.length )
			{
				int openPos = indexOf( lineText, "(" );
				if( openPos > 0 )
				{
					int closePos = indexOf( lineText, "): ", openPos );
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
			string statusUTF8 = fSTRz( status );
			if( statusUTF8.length > 5 )
			{
				if( statusUTF8[5] == 'D' )
				{
					int		lineNumber;
					bool	bGetFileName = true;
					string	fileName;
					string	lineText = fromStringz( IupGetAttribute( ih, "LINEVALUE" ) ).dup;

					version(FBIDE)
					{
						int openPos = indexOf( lineText, "(" );
						if( openPos > 0 )
						{
							int closePos = indexOf( lineText, ")", openPos );
							if( closePos > openPos + 1 )
							{
								if( closePos < lineText.length - 1 )
								{
									if( lineText[closePos+1] == ' ' )
									{
										string lineNumber_char = lineText[openPos+1..closePos].dup;
										lineNumber = to!(int)( lineNumber_char );
										fileName = tools.normalizeSlash( lineText[0..openPos] );
										
										if( ExecuterAction.quickRunFile.length )
										{
											string _baseName = Path.stripExtension( fileName );
											if( _baseName.length == 16 )
												if( _baseName[0..12] == "poseidonTemp" && isNumeric( _baseName[12..14] ) )
													fileName = ExecuterAction.quickRunFile;
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
												if( GLOBAL.compilerSettings.useAnootation == "ON" )
												{
													string allMessage = fromStringz( IupGetAttribute( ih, "VALUE" ) ).dup;
													int prevLineNumber, prevLineNumberCount;
													foreach( s; splitLines( allMessage ) )
													{
														if( s.length )
														{
															bool bWarning;
															int lineNumberTail = indexOf( s, ") error" );
															if( lineNumberTail == -1 )
															{
																lineNumberTail = indexOf( s, ") warning" );
																bWarning = true;
															}

															if( lineNumberTail > 0 )
															{
																int lineNumberHead = indexOf( s, "(" );
																if( lineNumberHead < lineNumberTail - 1 && lineNumberHead > -1 )
																{
																	string filePath = tools.normalizeSlash( s[0..lineNumberHead++] );
																	if( fileName == filePath )
																	{
																		if( fullPathByOS(filePath) in GLOBAL.scintillaManager )
																		{
																			CScintilla cSci = GLOBAL.scintillaManager[fullPathByOS(filePath)];

																			int		ln = to!(int)( s[lineNumberHead..lineNumberTail] ) - 1;
																			string	annotationText = s[lineNumberTail+2..$];
																			if( ln != prevLineNumber )
																			{
																				prevLineNumber = ln;
																				prevLineNumberCount = 1;
																				annotationText = "[" ~ to!(string)( prevLineNumberCount ) ~ "]" ~ annotationText;
																				prevLineNumberCount ++;
																			}
																			else
																			{
																				annotationText = "[" ~ to!(string)( prevLineNumberCount ) ~ "]" ~ annotationText;
																				prevLineNumberCount ++;
																			}
																	
																			string getText = fSTRz( IupGetAttributeId( cSci.getIupScintilla, "ANNOTATIONTEXT", ln ) );
																			if( getText.length ) annotationText = getText ~ "\n" ~ annotationText;

																			IupSetStrAttributeId( cSci.getIupScintilla, "ANNOTATIONTEXT", ln, toStringz( annotationText ) );
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
											IupSetAttribute( ih, "SELECTION", toStringz( to!(string)( _line ) ~ ",0:" ~ to!(string)( _line ) ~ "," ~ to!(string)( lineText.length - 1 ) ) );										
										}
										else
										{
											int pos = IupConvertXYToPos( ih, x, y );
											int _line, col;
											IupTextConvertPosToLinCol( ih, pos, &_line, &col );
											IupSetAttribute( ih, "SELECTION", toStringz( to!(string)( _line ) ~ ",1:" ~ to!(string)( _line ) ~ "," ~ to!(string)( lineText.length + 1 ) ) );										
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
					version(DIDE)
					{
						int closePos = indexOf( lineText, "): " );
						if( closePos > 0 )
						{
							int openPos = lastIndexOf( lineText, "(", closePos );
							if( openPos < closePos && closePos > 0 )
							{
								string lineNumber_char = lineText[openPos+1..closePos];
								lineNumber = to!(int)( lineNumber_char );
								
								if( indexOf( lineText, "warning - " ) == 0 ) fileName = tools.normalizeSlash( lineText[10..openPos] ); else fileName =  tools.normalizeSlash( lineText[0..openPos] );
								if( fullPathByOS(fileName) in GLOBAL.scintillaManager )
								{
									if( GLOBAL.navigation.addCache( fileName, lineNumber ) ) ScintillaAction.openFile( fileName, lineNumber );
								}
								else
								{
									GLOBAL.navigation.addCache( fileName, lineNumber );
									if( ScintillaAction.openFile( fileName, lineNumber ) )
									{
										if( GLOBAL.compilerSettings.useAnootation == "ON" )
										{
											string allMessage = fSTRz( IupGetAttribute( ih, "VALUE" ) );
											
											int prevLineNumber, prevLineNumberCount;
											foreach( s; splitLines( allMessage ) )
											{
												if( s.length )
												{
													bool bWarning;

													if( indexOf( s, "warning - " ) == 0 ) bWarning = true;
													int lineNumberTail = indexOf( s, "): " );
													if( lineNumberTail > 0 )
													{
														int lineNumberHead = lastIndexOf( s, "(", lineNumberTail );
														if( lineNumberHead < lineNumberTail - 1 && lineNumberHead > 0 )
														{
															string filePath = bWarning ? Array.replace( s[10..lineNumberHead++], "\\", "/" ) : Array.replace( s[0..lineNumberHead++], '\\', '/' );
															if( fileName == filePath )
															{
																if( fullPathByOS(filePath) in GLOBAL.scintillaManager )
																{
																	CScintilla cSci = GLOBAL.scintillaManager[fullPathByOS(filePath)];
																	int		ln = to!(int)( s[lineNumberHead..lineNumberTail] ) - 1;
																	string	annotationText = s[lineNumberTail+2..$];
																	
																	if( ln != prevLineNumber )
																	{
																		prevLineNumber = ln;
																		prevLineNumberCount = 1;
																		annotationText = "[" ~ to!(string)( prevLineNumberCount ) ~ "]" ~ annotationText;
																		prevLineNumberCount ++;
																	}
																	else
																	{
																		annotationText = "[" ~ to!(string)( prevLineNumberCount ) ~ "]" ~ annotationText;
																		prevLineNumberCount ++;
																	}																
																	
																	string getText = fSTRz( IupGetAttributeId( cSci.getIupScintilla, "ANNOTATIONTEXT", ln ) );
																	if( getText.length ) annotationText = getText ~ "\n" ~ annotationText;
																	
																	IupSetStrAttributeId( cSci.getIupScintilla, "ANNOTATIONTEXT", ln, toStringz( annotationText ) );
																	if( bWarning ) IupSetIntId( cSci.getIupScintilla, "ANNOTATIONSTYLE", ln, 41 ); else IupSetIntId( cSci.getIupScintilla, "ANNOTATIONSTYLE", ln, 40 );
																	IupSetAttribute( GLOBAL.scintillaManager[fullPathByOS(fileName)].getIupScintilla, "ANNOTATIONVISIBLE", "BOXED" );
																}
															}
														}
													}
												}
											}
										}
									}
								}

								// Make all line be selected
								if( GLOBAL.editorSetting01.OutputSci == "ON" )
								{
									int	_line = ScintillaAction.getLinefromPos( ih, ScintillaAction.getCurrentPos( ih ) );
									IupSetStrAttribute( ih, "SELECTION", toStringz( to!(string)( _line ) ~ ",0:" ~ to!(string)( _line ) ~ "," ~ to!(string)( lineText.length - 1 ) ) );
								}
								else
								{
									int pos = IupConvertXYToPos( ih, x, y );
									int _line, col;
									IupTextConvertPosToLinCol( ih, pos, &_line, &col );
									IupSetStrAttribute( ih, "SELECTION", toStringz( to!(string)( _line ) ~ ",1:" ~ to!(string)( _line ) ~ "," ~ to!(string)( lineText.length + 1 ) ) );										
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
			string statusUTF8 = fSTRz( status );
			if( statusUTF8.length > 5 )
			{
				if( pressed == 1 )
				{
					if( statusUTF8[5] == 'D' ) // Double Click!
					{
						int		lineNumber;
						bool	bGetFileName = true;
						string	fileName;
						string	lineText = fSTRz( IupGetAttribute( ih, "LINEVALUE" ) );
						
						int closePos = indexOf( lineText, "):" );
						if( closePos > 0 )
						{
							lineText = lineText[0..closePos].dup;
							int openPos = lastIndexOf( lineText, "(" );
							if( openPos > 0 )
							{
								string lineNumber_char = lineText[openPos+1..$];
								lineNumber = to!(int)( lineNumber_char );
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