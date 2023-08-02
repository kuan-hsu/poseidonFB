module IDE;

debug import std.stdio;

struct IDECONFIG
{
private:
	import iup.iup, iup.iup_config;
	import global, actionManager, tools;
	import std.string, std.file, std.encoding, Conv = std.conv, Array = std.array;

	static bool loadLocalization()
	{
		// Load Language lng
		string lngFilePath = GLOBAL.poseidonPath ~ "/settings/language/" ~ GLOBAL.language ~ ".lng";
		if( GLOBAL.linuxHome.length )
		{
			lngFilePath = GLOBAL.linuxHome ~ "/settings/language/" ~GLOBAL.language ~ ".ini"; // In main.d, the .poseidonFB or .poseidonD path already added in linuxHome 
			if( !std.file.exists( lngFilePath ) ) lngFilePath = "settings/language/" ~ GLOBAL.language ~ ".lng";
		}

		if( std.file.exists( lngFilePath ) )
		{
			int _encoding, _withBom;
			auto lngDocument = FileAction.loadFile( lngFilePath, _encoding, _withBom );
			
			foreach( s; splitLines( lngDocument ) )
			{
				s = strip( s );
				if( s.length )
				{
					if( s[0] != '\'' )
					{
						string left, right;
						int _result = tools.getINILineData( s, left, right );
						if( _result == 2 )
						{
							if( left.length && right.length )
							{
								if( left in GLOBAL.languageItems ) GLOBAL.languageItems[left] = right;// else IupMessage( "Error",toStringz(left ) );
							}
						}
					}
				}
			}
			return true;
		}
		return false;
	}


public:
	static string convertShortKeyValue2String( int keyValue )
	{
		string result;

		if( keyValue & 0x20000000 ) result = "C+";else result = "+";
		if( keyValue & 0x10000000 ) result ~= "S+";else result ~= "+";
		if( keyValue & 0x40000000 ) result ~= "A+";else result ~= "+";

		keyValue = keyValue & 0xFFFF;

		if( keyValue == 0x9 ) // TAB
		{
			result ~= "TAB";
		}
		if( keyValue >= 0x41 && keyValue <= 90 ) // 'A' ~ 'Z'
		{
			char c = cast(char)keyValue;
			result ~= c;
		}
		else if( keyValue >= 0xFFBE && keyValue <= 0xFFC9 ) // 'F1' ~ 'F12'
		{
			result ~= ( "F" ~ Conv.to!(string)( keyValue - 0xFFBD ) );
		}
		
		return result;
	}	

	static uint convertShortKeyValue2Integer( string keyValue )
	{
		string[] splitWord = Array.split( keyValue, "+" );
		int result;

		if( splitWord.length == 4 )
		{
			if( splitWord[0] == "C" ) result = result | 0x20000000; // Ctrl
			if( splitWord[1] == "S" ) result = result | 0x10000000; // Shift
			if( splitWord[2] == "A" ) result = result | 0x40000000; // Alt
			if( splitWord[3].length )
			{
				switch( splitWord[3] )
				{
					case "A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z":
						result += cast(int) splitWord[3][0];
						break;

					case "TAB":
						result += 9;
						break;

					default:
						if( splitWord[3][0] == 'F' )
						{
							if( splitWord[3].length > 1 )
							{
								result = result + 0xFFBD + Conv.to!(int)( splitWord[3][1..$] );
							}
						}
				}
			}
		}

		return result;
	}	

	static void saveINI()
	{
		try
		{
			string fullpath = GLOBAL.poseidonPath ~ "/settings/editorSettings.ini";
			if( GLOBAL.linuxHome.length ) fullpath = GLOBAL.linuxHome ~ "/settings/editorSettings.ini"; // In main.d, the .poseidonFB or .poseidonD path already added in linuxHome 
			
			string doc;
			
			// Editor
			doc ~= setINILineData( "[editor]");
			doc ~= setINILineData( "language", GLOBAL.language );
			
			for( int i = 0; i < 6; ++ i )
				doc ~= setINILineData( "keyword" ~ Conv.to!(string)( i ), strip( GLOBAL.KEYWORDS[i] ) );

			for( int i = 1; i < 13; ++ i )
				doc ~= setINILineData( "customtools" ~ Conv.to!(string)( i ), strip( GLOBAL.customTools[i].name ) ~ "," ~ strip( GLOBAL.customTools[i].dir ) ~ "," ~ strip( GLOBAL.customTools[i].args ) ~ "," ~ strip( GLOBAL.customTools[i].toggleShowConsole ));
				
			doc ~= setINILineData( "indicatorStyle", Conv.to!(string)( GLOBAL.indicatorStyle ) );

			// toggle
			doc ~= setINILineData( "[toggle]");
			doc ~= setINILineData( "LineMargin", GLOBAL.editorSetting00.LineMargin );
			doc ~= setINILineData( "FixedLineMargin", GLOBAL.editorSetting00.FixedLineMargin );
			doc ~= setINILineData( "BookmarkMargin", GLOBAL.editorSetting00.BookmarkMargin );
			doc ~= setINILineData( "FoldMargin", GLOBAL.editorSetting00.FoldMargin );
			doc ~= setINILineData( "IndentGuide", GLOBAL.editorSetting00.IndentGuide );
			doc ~= setINILineData( "CaretLine", GLOBAL.editorSetting00.CaretLine );
			doc ~= setINILineData( "WordWrap", GLOBAL.editorSetting00.WordWrap );
			doc ~= setINILineData( "TabUseingSpace", GLOBAL.editorSetting00.TabUseingSpace );
			doc ~= setINILineData( "AutoIndent", GLOBAL.editorSetting00.AutoIndent );
			doc ~= setINILineData( "ShowEOL", GLOBAL.editorSetting00.ShowEOL );
			doc ~= setINILineData( "ShowSpace", GLOBAL.editorSetting00.ShowSpace );
			doc ~= setINILineData( "AutoEnd", GLOBAL.editorSetting00.AutoEnd );
			doc ~= setINILineData( "AutoClose", GLOBAL.editorSetting00.AutoClose );
			doc ~= setINILineData( "TabWidth", GLOBAL.editorSetting00.TabWidth );
			doc ~= setINILineData( "ColumnEdge", GLOBAL.editorSetting00.ColumnEdge );
			doc ~= setINILineData( "EolType", GLOBAL.editorSetting00.EolType );
			doc ~= setINILineData( "ColorOutline", GLOBAL.editorSetting00.ColorOutline );
			doc ~= setINILineData( "BoldKeyword", GLOBAL.editorSetting00.BoldKeyword );
			doc ~= setINILineData( "BraceMatchHighlight", GLOBAL.editorSetting00.BraceMatchHighlight );
			doc ~= setINILineData( "MultiSelection", GLOBAL.editorSetting00.MultiSelection );
			doc ~= setINILineData( "LoadPrevDoc", GLOBAL.editorSetting00.LoadPrevDoc );
			doc ~= setINILineData( "HighlightCurrentWord", GLOBAL.editorSetting00.HighlightCurrentWord );
			doc ~= setINILineData( "MiddleScroll", GLOBAL.editorSetting00.MiddleScroll );
			doc ~= setINILineData( "SaveDocStatus", GLOBAL.editorSetting00.DocStatus );
			doc ~= setINILineData( "ColorBarLine", GLOBAL.editorSetting00.ColorBarLine );
			doc ~= setINILineData( "AutoKBLayout", GLOBAL.editorSetting00.AutoKBLayout );
			doc ~= setINILineData( "ControlCharSymbol", GLOBAL.editorSetting00.ControlCharSymbol );
			doc ~= setINILineData( "GUI", GLOBAL.editorSetting00.GUI );
			doc ~= setINILineData( "Bit64", GLOBAL.compilerSettings.Bit64 );
			doc ~= setINILineData( "QBCase", GLOBAL.editorSetting00.QBCase );
			doc ~= setINILineData( "NewDocBOM", GLOBAL.editorSetting00.NewDocBOM );
			doc ~= setINILineData( "SaveAllModified", GLOBAL.editorSetting00.SaveAllModified );
			doc ~= setINILineData( "IconInvert", GLOBAL.editorSetting00.IconInvert );
			doc ~= setINILineData( "DarkMode", GLOBAL.editorSetting00.UseDarkMode );
			
			if( fromStringz( IupGetAttribute( GLOBAL.menuOutlineWindow, "VALUE" ) ) == "OFF" )
				GLOBAL.editorSetting01.ExplorerSplit = Conv.to!(string)( GLOBAL.explorerSplit_value );
			else
				GLOBAL.editorSetting01.ExplorerSplit = IupGetInt( GLOBAL.explorerSplit, "VALUE" ) <= 0 ? "180" : fSTRz( IupGetAttribute( GLOBAL.explorerSplit, "VALUE" ) );
			
			if( fromStringz( IupGetAttribute( GLOBAL.menuMessageWindow, "VALUE" ) ) == "OFF" )
				GLOBAL.editorSetting01.MessageSplit = Conv.to!(string)( GLOBAL.messageSplit_value ).dup;
			else
				GLOBAL.editorSetting01.MessageSplit = IupGetInt( GLOBAL.messageSplit, "VALUE" ) >= 1000 ? "850" : fSTRz( IupGetAttribute( GLOBAL.messageSplit, "VALUE" ) );

				
			GLOBAL.editorSetting01.OutlineWindow = fSTRz( IupGetAttribute( GLOBAL.menuOutlineWindow, "VALUE" ) );
			GLOBAL.editorSetting01.MessageWindow = fSTRz( IupGetAttribute( GLOBAL.menuMessageWindow, "VALUE" ) );

			// size
			doc ~= setINILineData( "[size]");
			if( GLOBAL.editorSetting01.PLACEMENT == "MINIMIZED" ) doc ~= setINILineData( "PLACEMENT", "NORMAL" ); else doc ~= setINILineData( "PLACEMENT", GLOBAL.editorSetting01.PLACEMENT );
			doc ~= setINILineData( "USEFULLSCREEN", GLOBAL.editorSetting01.USEFULLSCREEN );
			doc ~= setINILineData( "RASTERSIZE", GLOBAL.editorSetting01.RASTERSIZE );
			doc ~= setINILineData( "ExplorerSplit", GLOBAL.editorSetting01.ExplorerSplit );
			doc ~= setINILineData( "MessageSplit", GLOBAL.editorSetting01.MessageSplit );
			doc ~= setINILineData( "OutlineWindow", GLOBAL.editorSetting01.OutlineWindow );
			doc ~= setINILineData( "MessageWindow", GLOBAL.editorSetting01.MessageWindow );
			doc ~= setINILineData( "RotateTabs", GLOBAL.editorSetting01.RotateTabs );
			doc ~= setINILineData( "BarSize", GLOBAL.editorSetting01.BarSize );
			doc ~= setINILineData( "EXTRAASCENT", GLOBAL.editorSetting01.EXTRAASCENT );
			doc ~= setINILineData( "EXTRADESCENT", GLOBAL.editorSetting01.EXTRADESCENT );
			
			// font
			doc ~= setINILineData( "[font]");
			doc ~= setINILineData( "Default", GLOBAL.fonts[0].fontString );
			doc ~= setINILineData( "Document", GLOBAL.fonts[1].fontString );
			doc ~= setINILineData( "Leftside", GLOBAL.fonts[2].fontString );
			doc ~= setINILineData( "Filelist", GLOBAL.fonts[3].fontString );
			doc ~= setINILineData( "Project", GLOBAL.fonts[4].fontString );
			doc ~= setINILineData( "Outline", GLOBAL.fonts[5].fontString );
			doc ~= setINILineData( "Bottom", GLOBAL.fonts[6].fontString );
			doc ~= setINILineData( "Output", GLOBAL.fonts[7].fontString );
			doc ~= setINILineData( "Search", GLOBAL.fonts[8].fontString );
			doc ~= setINILineData( "Debugger", GLOBAL.fonts[9].fontString );
			doc ~= setINILineData( "Annotation", GLOBAL.fonts[10].fontString );
			doc ~= setINILineData( "StatusBar", GLOBAL.fonts[11].fontString );

			// color
			doc ~= setINILineData( "[color]");
			doc ~= setINILineData( "keyword0", GLOBAL.editColor.keyWord[0] );
			doc ~= setINILineData( "keyword1", GLOBAL.editColor.keyWord[1] );
			doc ~= setINILineData( "keyword2", GLOBAL.editColor.keyWord[2] );
			doc ~= setINILineData( "keyword3", GLOBAL.editColor.keyWord[3] );	
			doc ~= setINILineData( "keyword4", GLOBAL.editColor.keyWord[4] );
			doc ~= setINILineData( "keyword5", GLOBAL.editColor.keyWord[5] );	
			doc ~= setINILineData( "caretLine", GLOBAL.editColor.caretLine );
			doc ~= setINILineData( "cursor", GLOBAL.editColor.cursor );
			doc ~= setINILineData( "selectionFore", GLOBAL.editColor.selectionFore );
			doc ~= setINILineData( "selectionBack", GLOBAL.editColor.selectionBack );
			doc ~= setINILineData( "linenumFore", GLOBAL.editColor.linenumFore );
			doc ~= setINILineData( "linenumBack", GLOBAL.editColor.linenumBack );
			doc ~= setINILineData( "fold", GLOBAL.editColor.fold );
			doc ~= setINILineData( "selAlpha", GLOBAL.editColor.selAlpha );
			doc ~= setINILineData( "currentword", GLOBAL.editColor.currentWord );
			doc ~= setINILineData( "currentwordAlpha", GLOBAL.editColor.currentWordAlpha );
			doc ~= setINILineData( "braceFore", GLOBAL.editColor.braceFore );
			doc ~= setINILineData( "braceBack", GLOBAL.editColor.braceBack );		
			doc ~= setINILineData( "errorFore", GLOBAL.editColor.errorFore );
			doc ~= setINILineData( "errorBack", GLOBAL.editColor.errorBack );
			doc ~= setINILineData( "warningFore", GLOBAL.editColor.warningFore );
			doc ~= setINILineData( "warningBack", GLOBAL.editColor.warningBack );
			doc ~= setINILineData( "scintillaFore", GLOBAL.editColor.scintillaFore );
			doc ~= setINILineData( "scintillaBack", GLOBAL.editColor.scintillaBack );
			doc ~= setINILineData( "SCE_B_COMMENT_Fore", GLOBAL.editColor.SCE_B_COMMENT_Fore );
			doc ~= setINILineData( "SCE_B_COMMENT_Back", GLOBAL.editColor.SCE_B_COMMENT_Back );
			doc ~= setINILineData( "SCE_B_NUMBER_Fore", GLOBAL.editColor.SCE_B_NUMBER_Fore );
			doc ~= setINILineData( "SCE_B_NUMBER_Back", GLOBAL.editColor.SCE_B_NUMBER_Back );
			doc ~= setINILineData( "SCE_B_STRING_Fore", GLOBAL.editColor.SCE_B_STRING_Fore );
			doc ~= setINILineData( "SCE_B_STRING_Back", GLOBAL.editColor.SCE_B_STRING_Back );
			doc ~= setINILineData( "SCE_B_PREPROCESSOR_Fore", GLOBAL.editColor.SCE_B_PREPROCESSOR_Fore );
			doc ~= setINILineData( "SCE_B_PREPROCESSOR_Back", GLOBAL.editColor.SCE_B_PREPROCESSOR_Back );
			doc ~= setINILineData( "SCE_B_OPERATOR_Fore", GLOBAL.editColor.SCE_B_OPERATOR_Fore );
			doc ~= setINILineData( "SCE_B_OPERATOR_Back", GLOBAL.editColor.SCE_B_OPERATOR_Back );
			doc ~= setINILineData( "SCE_B_IDENTIFIER_Fore", GLOBAL.editColor.SCE_B_IDENTIFIER_Fore );
			doc ~= setINILineData( "SCE_B_IDENTIFIER_Back", GLOBAL.editColor.SCE_B_IDENTIFIER_Back );
			doc ~= setINILineData( "SCE_B_COMMENTBLOCK_Fore", GLOBAL.editColor.SCE_B_COMMENTBLOCK_Fore );
			doc ~= setINILineData( "SCE_B_COMMENTBLOCK_Back", GLOBAL.editColor.SCE_B_COMMENTBLOCK_Back );
			doc ~= setINILineData( "projectFore", GLOBAL.editColor.projectFore );
			doc ~= setINILineData( "projectBack", GLOBAL.editColor.projectBack );
			doc ~= setINILineData( "outlineFore", GLOBAL.editColor.outlineFore );
			doc ~= setINILineData( "outlineBack", GLOBAL.editColor.outlineBack );	
			doc ~= setINILineData( "dlgFore", GLOBAL.editColor.dlgFore );
			doc ~= setINILineData( "dlgBack", GLOBAL.editColor.dlgBack );
			doc ~= setINILineData( "txtFore", GLOBAL.editColor.txtFore );
			doc ~= setINILineData( "txtBack", GLOBAL.editColor.txtBack );
			
			doc ~= setINILineData( "outputFore", GLOBAL.editColor.outputFore );
			doc ~= setINILineData( "outputBack", GLOBAL.editColor.outputBack );
			doc ~= setINILineData( "searchFore", GLOBAL.editColor.searchFore );
			doc ~= setINILineData( "searchBack", GLOBAL.editColor.searchBack );
			doc ~= setINILineData( "prjTitle", GLOBAL.editColor.prjTitle );
			doc ~= setINILineData( "prjSourceType", GLOBAL.editColor.prjSourceType );
			doc ~= setINILineData( "calltipFore", GLOBAL.editColor.callTipFore );
			doc ~= setINILineData( "calltipBack", GLOBAL.editColor.callTipBack );
			doc ~= setINILineData( "calltipHLT", GLOBAL.editColor.callTipHLT );
			doc ~= setINILineData( "showtypeFore", GLOBAL.editColor.showTypeFore );
			doc ~= setINILineData( "showtypeBack", GLOBAL.editColor.showTypeBack );
			doc ~= setINILineData( "showtypeHLT", GLOBAL.editColor.showTypeHLT );
			doc ~= setINILineData( "autoCompleteFore", GLOBAL.editColor.autoCompleteFore );
			doc ~= setINILineData( "autoCompleteBack", GLOBAL.editColor.autoCompleteBack );
			doc ~= setINILineData( "autoCompleteHLTFore", GLOBAL.editColor.autoCompleteHLTFore );
			doc ~= setINILineData( "autoCompleteHLTBack", GLOBAL.editColor.autoCompleteHLTBack );

			doc ~= setINILineData( "searchIndicator", GLOBAL.editColor.searchIndicator );
			doc ~= setINILineData( "searchIndicatorAlpha", GLOBAL.editColor.searchIndicatorAlpha );
			doc ~= setINILineData( "prjViewHLT", GLOBAL.editColor.prjViewHLT );
			
			// shortkeys
			doc ~= setINILineData( "[shortkeys]");
			doc ~= setINILineData( "save", convertShortKeyValue2String( GLOBAL.shortKeys[0].keyValue ) );
			doc ~= setINILineData( "saveall", convertShortKeyValue2String( GLOBAL.shortKeys[1].keyValue ) );
			doc ~= setINILineData( "close", convertShortKeyValue2String( GLOBAL.shortKeys[2].keyValue ) );
			doc ~= setINILineData( "newtab", convertShortKeyValue2String( GLOBAL.shortKeys[3].keyValue ) );
			doc ~= setINILineData( "nexttab", convertShortKeyValue2String( GLOBAL.shortKeys[4].keyValue ) );
			doc ~= setINILineData( "prevtab", convertShortKeyValue2String( GLOBAL.shortKeys[5].keyValue ) );

			doc ~= setINILineData( "dupdown", convertShortKeyValue2String( GLOBAL.shortKeys[6].keyValue ) );
			doc ~= setINILineData( "dupup", convertShortKeyValue2String( GLOBAL.shortKeys[7].keyValue ) );
			doc ~= setINILineData( "delline", convertShortKeyValue2String( GLOBAL.shortKeys[8].keyValue ) );
			doc ~= setINILineData( "find", convertShortKeyValue2String( GLOBAL.shortKeys[9].keyValue ) );
			doc ~= setINILineData( "findinfile", convertShortKeyValue2String( GLOBAL.shortKeys[10].keyValue ) );
			doc ~= setINILineData( "findnext", convertShortKeyValue2String( GLOBAL.shortKeys[11].keyValue ) );
			doc ~= setINILineData( "findprev", convertShortKeyValue2String( GLOBAL.shortKeys[12].keyValue ) );
			doc ~= setINILineData( "gotoline", convertShortKeyValue2String( GLOBAL.shortKeys[13].keyValue ) );
			doc ~= setINILineData( "undo", convertShortKeyValue2String( GLOBAL.shortKeys[14].keyValue ) );
			doc ~= setINILineData( "redo", convertShortKeyValue2String( GLOBAL.shortKeys[15].keyValue ) );
			doc ~= setINILineData( "comment", convertShortKeyValue2String( GLOBAL.shortKeys[16].keyValue ) );
			doc ~= setINILineData( "uncomment", convertShortKeyValue2String( GLOBAL.shortKeys[17].keyValue ) );
			doc ~= setINILineData( "backnav", convertShortKeyValue2String( GLOBAL.shortKeys[18].keyValue ) );
			doc ~= setINILineData( "forwardnav", convertShortKeyValue2String( GLOBAL.shortKeys[19].keyValue ) );

			doc ~= setINILineData( "showtype", convertShortKeyValue2String( GLOBAL.shortKeys[20].keyValue ) );
			doc ~= setINILineData( "defintion", convertShortKeyValue2String( GLOBAL.shortKeys[21].keyValue ) );
			doc ~= setINILineData( "procedure", convertShortKeyValue2String( GLOBAL.shortKeys[22].keyValue ) );
			doc ~= setINILineData( "autocomplete", convertShortKeyValue2String( GLOBAL.shortKeys[23].keyValue ) );
			doc ~= setINILineData( "reparse", convertShortKeyValue2String( GLOBAL.shortKeys[24].keyValue ) );
			
			doc ~= setINILineData( "compilerun", convertShortKeyValue2String( GLOBAL.shortKeys[25].keyValue ) );
			doc ~= setINILineData( "quickrun", convertShortKeyValue2String( GLOBAL.shortKeys[26].keyValue ) );
			doc ~= setINILineData( "run", convertShortKeyValue2String( GLOBAL.shortKeys[27].keyValue ) );
			doc ~= setINILineData( "build", convertShortKeyValue2String( GLOBAL.shortKeys[28].keyValue ) );

			doc ~= setINILineData( "leftwindow", convertShortKeyValue2String( GLOBAL.shortKeys[29].keyValue ) );
			doc ~= setINILineData( "bottomwindow", convertShortKeyValue2String( GLOBAL.shortKeys[30].keyValue ) );			
			doc ~= setINILineData( "outlinewindow", convertShortKeyValue2String( GLOBAL.shortKeys[31].keyValue ) );
			doc ~= setINILineData( "messagewindow", convertShortKeyValue2String( GLOBAL.shortKeys[32].keyValue ) );
			
			doc ~= setINILineData( "customtool1", convertShortKeyValue2String( GLOBAL.shortKeys[33].keyValue ) );
			doc ~= setINILineData( "customtool2", convertShortKeyValue2String( GLOBAL.shortKeys[34].keyValue ) );
			doc ~= setINILineData( "customtool3", convertShortKeyValue2String( GLOBAL.shortKeys[35].keyValue ) );
			doc ~= setINILineData( "customtool4", convertShortKeyValue2String( GLOBAL.shortKeys[36].keyValue ) );
			doc ~= setINILineData( "customtool5", convertShortKeyValue2String( GLOBAL.shortKeys[37].keyValue ) );
			doc ~= setINILineData( "customtool6", convertShortKeyValue2String( GLOBAL.shortKeys[38].keyValue ) );
			doc ~= setINILineData( "customtool7", convertShortKeyValue2String( GLOBAL.shortKeys[39].keyValue ) );
			doc ~= setINILineData( "customtool8", convertShortKeyValue2String( GLOBAL.shortKeys[40].keyValue ) );
			doc ~= setINILineData( "customtool9", convertShortKeyValue2String( GLOBAL.shortKeys[41].keyValue ) );
			doc ~= setINILineData( "customtool10", convertShortKeyValue2String( GLOBAL.shortKeys[42].keyValue ) );
			doc ~= setINILineData( "customtool11", convertShortKeyValue2String( GLOBAL.shortKeys[43].keyValue ) );
			doc ~= setINILineData( "customtool12", convertShortKeyValue2String( GLOBAL.shortKeys[44].keyValue ) );
			
			// buildtools
			doc ~= setINILineData( "[buildtools]");
			doc ~= setINILineData( "compilerpath", GLOBAL.compilerSettings.compilerFullPath );
			doc ~= setINILineData( "x64compilerpath", GLOBAL.compilerSettings.x64compilerFullPath );
			doc ~= setINILineData( "debuggerpath", GLOBAL.compilerSettings.debuggerFullPath );
			doc ~= setINILineData( "x64debuggerpath", GLOBAL.compilerSettings.x64debuggerFullPath );
			doc ~= setINILineData( "terminalpath", GLOBAL.linuxTermName );
			doc ~= setINILineData( "htmlapppath", GLOBAL.linuxHtmlAppName );
			doc ~= setINILineData( "resultwindow", GLOBAL.compilerSettings.useResultDlg );
			doc ~= setINILineData( "usesfx", GLOBAL.compilerSettings.useSFX );
			doc ~= setINILineData( "annotation", GLOBAL.compilerSettings.useAnootation );
			doc ~= setINILineData( "delexistexe", GLOBAL.compilerSettings.useDelExistExe );
			doc ~= setINILineData( "consoleexe", GLOBAL.compilerSettings.useConsoleLaunch );
			doc ~= setINILineData( "compileatbackthread", GLOBAL.compilerSettings.useThread );
			doc ~= setINILineData( "consoleid", Conv.to!(string)( GLOBAL.consoleWindow.id ) );
			doc ~= setINILineData( "consolex", Conv.to!(string)( GLOBAL.consoleWindow.x ) );
			doc ~= setINILineData( "consoley", Conv.to!(string)( GLOBAL.consoleWindow.y ) );
			doc ~= setINILineData( "consolew", Conv.to!(string)( GLOBAL.consoleWindow.w ) );
			doc ~= setINILineData( "consoleh", Conv.to!(string)( GLOBAL.consoleWindow.h ) );

			// parser
			doc ~= setINILineData( "[parser]");
			doc ~= setINILineData( "enablekeywordcomplete", GLOBAL.compilerSettings.enableKeywordComplete );
			doc ~= setINILineData( "enableincludecomplete", GLOBAL.compilerSettings.enableIncludeComplete );
			doc ~= setINILineData( "enableparser", GLOBAL.enableParser );
			doc ~= setINILineData( "parsertrigger", Conv.to!(string)( GLOBAL.autoCompletionTriggerWordCount ) );
			doc ~= setINILineData( "togglepreloadprj", GLOBAL.togglePreLoadPrj );
			doc ~= setINILineData( "showfunctiontitle", GLOBAL.showFunctionTitle );
			doc ~= setINILineData( "showtypewithparams", GLOBAL.showTypeWithParams );
			doc ~= setINILineData( "includelevel", Conv.to!(string)( GLOBAL.compilerSettings.includeLevel ) );
			doc ~= setINILineData( "preparselevel", Conv.to!(string)( GLOBAL.preParseLevel ) );
			doc ~= setINILineData( "ignorecase", GLOBAL.toggleIgnoreCase );
			doc ~= setINILineData( "caseinsensitive", GLOBAL.toggleCaseInsensitive );
			//doc ~= setINILineData( "showlisttype", GLOBAL.toggleShowListType );
			doc ~= setINILineData( "showallmember", GLOBAL.compilerSettings.toggleShowAllMember );
			doc ~= setINILineData( "enabledwell", GLOBAL.toggleEnableDwell );
			doc ~= setINILineData( "enableoverwrite", GLOBAL.toggleOverWrite );
			doc ~= setINILineData( "completeatbackthread", GLOBAL.toggleCompleteAtBackThread );
			doc ~= setINILineData( "livelevel", Conv.to!(string)( GLOBAL.liveLevel ) );
			doc ~= setINILineData( "updateoutlinelive", GLOBAL.toggleUpdateOutlineLive );
			doc ~= setINILineData( "keywordcase", Conv.to!(string)( GLOBAL.keywordCase ) );
			doc ~= setINILineData( "dwelldelay", GLOBAL.dwellDelay );
			doc ~= setINILineData( "triggerdelay", GLOBAL.triggerDelay );
			doc ~= setINILineData( "autocmaxheight", Conv.to!(string)( GLOBAL.autoCMaxHeight ) );
			doc ~= setINILineData( "extraext", GLOBAL.extraParsableExt );
			
			// manual
			doc ~= setINILineData( "[manual]");
			doc ~= setINILineData( "manualusing", GLOBAL.toggleUseManual );
			for( int i = 0; i < GLOBAL.manuals.length; ++ i )
				doc ~= setINILineData( "name", GLOBAL.manuals[i] );			

			// recentFiles
			doc ~= setINILineData( "[recentFiles]" );
			for( int i = 0; i < GLOBAL.recentFiles.length; ++i )
				doc ~= setINILineData( "name", GLOBAL.recentFiles[i].toDString );

			// recentProjects
			doc ~= setINILineData( "[recentProjects]" );
			for( int i = 0; i < GLOBAL.recentProjects.length; ++i )
				doc ~= setINILineData( "name", GLOBAL.recentProjects[i].toDString );

			// recentOptions
			doc ~= setINILineData( "[recentOptions]" );
			for( int i = 0; i < GLOBAL.recentOptions.length; ++i )
				doc ~= setINILineData( "name", GLOBAL.recentOptions[i] );

			// recentArgss
			doc ~= setINILineData( "[recentArgs]" );
			for( int i = 0; i < GLOBAL.recentArgs.length; ++i )
				doc ~= setINILineData( "name", GLOBAL.recentArgs[i] );

			// recentCompilers
			doc ~= setINILineData( "[recentCompilers]" );
			for( int i = 0; i < GLOBAL.recentCompilers.length; ++i )
				doc ~= setINILineData( "name", GLOBAL.recentCompilers[i] );

			// customCompilerOptions
			doc ~= setINILineData( "[customCompilerOptions]" );
			doc ~= setINILineData( "current", GLOBAL.compilerSettings.currentCustomCompilerOption );
			doc ~= setINILineData( "none", GLOBAL.compilerSettings.noneCustomCompilerOption );
			for( int i = 0; i < GLOBAL.compilerSettings.customCompilerOptions.length; ++i )
				doc ~= setINILineData( "name", GLOBAL.compilerSettings.customCompilerOptions[i] );

			// prevLoadPrj
			doc ~= setINILineData( "[prevPrjs]" );
			for( int i = 0; i < GLOBAL.prevPrj.length; ++i )
				doc ~= setINILineData( "name", GLOBAL.prevPrj[i] );

			// prevLoadDoc
			doc ~= setINILineData( "[prevDocs]" );
			for( int i = 0; i < GLOBAL.prevDoc.length; ++i )
				doc ~= setINILineData( "name", GLOBAL.prevDoc[i] );
				
			// opacity
			doc ~= setINILineData( "[opacity]");
			doc ~= setINILineData( "findfilesdlg", GLOBAL.editorSetting02.findfilesDlg );
			doc ~= setINILineData( "preferencedlg", GLOBAL.editorSetting02.preferenceDlg );
			doc ~= setINILineData( "projectdlg", GLOBAL.editorSetting02.preferenceDlg );
			doc ~= setINILineData( "gotodlg", GLOBAL.editorSetting02.gotoDlg );
			doc ~= setINILineData( "newfiledlg", GLOBAL.editorSetting02.newfileDlg );
			doc ~= setINILineData( "autocompletedlg", GLOBAL.editorSetting02.autocompleteDlg );
			
			actionManager.FileAction.saveFile( fullpath, doc, BOM.utf8, true );
		}
		catch( Exception e )
		{
			IupMessage( "Save editorSettings.ini Error!", toStringz( e.toString ) );
		}
	}
	
	static void loadINI()
	{
		string left, right;
		try
		{
			string fullpath = GLOBAL.poseidonPath ~ "/settings/editorSettings.ini";
			if( GLOBAL.linuxHome.length )
			{
				fullpath = GLOBAL.linuxHome ~ "/settings/editorSettings.ini"; // In main.d, the .poseidonFB or .poseidonD path already added in linuxHome 
				if( !std.file.exists( fullpath ) ) fullpath = "settings/editorSettings.ini";
			}
			if( !std.file.exists( fullpath ) ) throw new Exception( "editorSettings.ini isn't existed!" );
			
			// Load INI
			int _enconding, _withBom;
			string doc = FileAction.loadFile( fullpath, _enconding, _withBom );
			
			string	blockText;
			foreach( lineData; splitLines( doc ) )
			{
				lineData = strip( lineData );
				
				// Get Line Data
				int _result = tools.getINILineData( lineData, left, right );
				if( _result == 1 )
				{
					blockText = left;
					continue;
				}
				else if( _result == 0 )
				{
					continue;
				}
				else
				{
					switch( left )
					{
						case "keyword0", "keyword1", "keyword2", "keyword3", "keyword4", "keyword5": break;
						default:
							if( !right.length ) continue;
					}
				}
				
				switch( blockText )
				{
					case "[editor]":
						switch( left )
						{
							case "keyword0":		GLOBAL.KEYWORDS[0] = right;						break;
							case "keyword1":		GLOBAL.KEYWORDS[1] = right;						break;
							case "keyword2":		GLOBAL.KEYWORDS[2] = right;						break;
							case "keyword3":		GLOBAL.KEYWORDS[3] = right;						break;
							case "keyword4":		GLOBAL.KEYWORDS[4] = right;						break;
							case "keyword5":		GLOBAL.KEYWORDS[5] = right;						break;
							case "indicatorStyle":	GLOBAL.indicatorStyle = Conv.to!(int)( right );	break;
							case "language":
								GLOBAL.language = right;
								loadLocalization(); // Load Language lng
								break;
							case "customtools1", "customtools2", "customtools3", "customtools4", "customtools5", "customtools6", "customtools7", "customtools8", "customtools9", "customtools10", "customtools11", "customtools12":
								int index = Conv.to!(int)( left[11..$] );
								string[] values = Array.split( right, "," );
								if( values.length > 2 && values.length < 5 )
								{
									if( values[0].length )
									{
										GLOBAL.customTools[index].name = values[0];
										if( values[1].length ) GLOBAL.customTools[index].dir = values[1];
										if( values[2].length ) GLOBAL.customTools[index].args = values[2];
										if( values.length == 4 ) GLOBAL.customTools[index].toggleShowConsole = values[3];
									}
								}
								break;
							default:
						}
						break;
					
					case "[toggle]":
						switch( left )
						{
							case "LineMargin":	 			GLOBAL.editorSetting00.LineMargin = right;				break;
							case "FixedLineMargin":			GLOBAL.editorSetting00.FixedLineMargin = right;			break;
							case "BookmarkMargin":			GLOBAL.editorSetting00.BookmarkMargin = right;			break;
							case "FoldMargin":				GLOBAL.editorSetting00.FoldMargin = right;				break;
							case "IndentGuide":				GLOBAL.editorSetting00.IndentGuide = right;				break;
							case "CaretLine":				GLOBAL.editorSetting00.CaretLine = right;				break;
							case "WordWrap":				GLOBAL.editorSetting00.WordWrap = right;				break;
							case "TabUseingSpace":			GLOBAL.editorSetting00.TabUseingSpace = right;			break;
							case "AutoIndent":				GLOBAL.editorSetting00.AutoIndent = right;				break;
							case "ShowEOL":					GLOBAL.editorSetting00.ShowEOL = right;					break;
							case "ShowSpace":				GLOBAL.editorSetting00.ShowSpace = right;				break;
							case "AutoEnd":					GLOBAL.editorSetting00.AutoEnd = right;					break;
							case "AutoClose":				GLOBAL.editorSetting00.AutoClose = right;				break;
							case "TabWidth":				GLOBAL.editorSetting00.TabWidth = right;				break;
					
							case "ColumnEdge":				GLOBAL.editorSetting00.ColumnEdge = right;				break;
							case "EolType":					GLOBAL.editorSetting00.EolType = right;					break;
							case "ColorOutline":			GLOBAL.editorSetting00.ColorOutline = right;			break;
							case "BoldKeyword":				GLOBAL.editorSetting00.BoldKeyword = right;				break;
							case "BraceMatchHighlight":		GLOBAL.editorSetting00.BraceMatchHighlight = right;		break;
							case "MultiSelection":			GLOBAL.editorSetting00.MultiSelection = right;			break;
							case "LoadPrevDoc":				GLOBAL.editorSetting00.LoadPrevDoc = right;				break;
							case "HighlightCurrentWord":	GLOBAL.editorSetting00.HighlightCurrentWord = right;	break;
							case "MiddleScroll":			GLOBAL.editorSetting00.MiddleScroll = right;			break;
							case "SaveDocStatus":			GLOBAL.editorSetting00.DocStatus = right;				break;
							case "ColorBarLine":			GLOBAL.editorSetting00.ColorBarLine = right;			break;
							case "AutoKBLayout":			GLOBAL.editorSetting00.AutoKBLayout = right;			break;
							case "ControlCharSymbol":		GLOBAL.editorSetting00.ControlCharSymbol = right;		break;
							case "GUI":						GLOBAL.editorSetting00.GUI = right;						break;
							case "Bit64":					GLOBAL.compilerSettings.Bit64 = right;					break;
							case "QBCase":					GLOBAL.editorSetting00.QBCase = right;					break;
							case "NewDocBOM":				GLOBAL.editorSetting00.NewDocBOM = right;				break;
							case "SaveAllModified":			GLOBAL.editorSetting00.SaveAllModified = right;			break;
							case "IconInvert":				GLOBAL.editorSetting00.IconInvert = right;				break;
							case "DarkMode":				GLOBAL.editorSetting00.UseDarkMode = right;				break;
							default:
						}
						break;
						
					case "[size]":
						switch( left )
						{
							case "USEFULLSCREEN":	 		GLOBAL.editorSetting01.USEFULLSCREEN = right;			break;
							case "PLACEMENT":	 			GLOBAL.editorSetting01.PLACEMENT = right;				break;
							case "RASTERSIZE":				GLOBAL.editorSetting01.RASTERSIZE = right;				break;
							case "ExplorerSplit":			GLOBAL.editorSetting01.ExplorerSplit = right;			break;
							case "MessageSplit":			GLOBAL.editorSetting01.MessageSplit = right;			break;
							case "OutlineWindow":			GLOBAL.editorSetting01.OutlineWindow = right;			break;
							case "MessageWindow":			GLOBAL.editorSetting01.MessageWindow = right;			break;
							case "RotateTabs":				GLOBAL.editorSetting01.RotateTabs = right;				break;
							case "BarSize":
								GLOBAL.editorSetting01.BarSize = right;
								int _size = Conv.to!(int)( right );
								if( _size < 2 ) GLOBAL.editorSetting01.BarSize = "2";
								if( _size > 5 ) GLOBAL.editorSetting01.BarSize = "5";
								break;
							case "EXTRAASCENT":				GLOBAL.editorSetting01.EXTRAASCENT = right;				break;
							case "EXTRADESCENT":			GLOBAL.editorSetting01.EXTRADESCENT = right;			break;
							default:
						}
						break;
						
					case "[font]":
						switch( left )
						{
							case "Default":	 				GLOBAL.fonts[0].fontString = right;						break;
							case "Document":				GLOBAL.fonts[1].fontString = right;						break;
							case "Leftside":				GLOBAL.fonts[2].fontString = right;						break;
							case "Filelist":				GLOBAL.fonts[3].fontString = right;						break;
							case "Project":					GLOBAL.fonts[4].fontString = right;						break;
							case "Outline":					GLOBAL.fonts[5].fontString = right;						break;
							case "Bottom":					GLOBAL.fonts[6].fontString = right;						break;
							case "Output":					GLOBAL.fonts[7].fontString = right;						break;
							case "Search":					GLOBAL.fonts[8].fontString = right; 					break;
							case "Debugger":				GLOBAL.fonts[9].fontString  = right;					break;
							case "Annotation":				GLOBAL.fonts[10].fontString = right;					break;
							case "StatusBar":				GLOBAL.fonts[11].fontString = right;					break;
							default:
						}
						break;
					
					case "[color]":
						switch( left )
						{
							case "keyword0":				GLOBAL.editColor.keyWord[0] = right;					break;
							case "keyword1":				GLOBAL.editColor.keyWord[1] = right;					break;
							case "keyword2":				GLOBAL.editColor.keyWord[2] = right;					break;
							case "keyword3":				GLOBAL.editColor.keyWord[3] = right;					break;
							case "keyword4":				GLOBAL.editColor.keyWord[4] = right;					break;
							case "keyword5":				GLOBAL.editColor.keyWord[5] = right;					break;
							case "caretLine":				GLOBAL.editColor.caretLine = right;						break;
							case "cursor":					GLOBAL.editColor.cursor = right;						break;
							case "selectionFore":			GLOBAL.editColor.selectionFore = right;					break;
							case "selectionBack":			GLOBAL.editColor.selectionBack = right;					break;
							case "linenumFore":				GLOBAL.editColor.linenumFore = right;					break;
							case "linenumBack":				GLOBAL.editColor.linenumBack = right;					break;
							case "fold":					GLOBAL.editColor.fold = right;							break;
							case "selAlpha":				GLOBAL.editColor.selAlpha = right;						break;
							case "currentword":				GLOBAL.editColor.currentWord = right;					break;
							case "currentwordAlpha":		GLOBAL.editColor.currentWordAlpha = right;				break;
							case "braceFore":				GLOBAL.editColor.braceFore = right;						break;
							case "braceBack":				GLOBAL.editColor.braceBack = right;						break;
							case "errorFore":				GLOBAL.editColor.errorFore = right;						break;
							case "errorBack":				GLOBAL.editColor.errorBack = right;						break;
							case "warningFore":				GLOBAL.editColor.warningFore = right;					break;
							case "warningBack":				GLOBAL.editColor.warningBack = right;					break;
							case "scintillaFore":			GLOBAL.editColor.scintillaFore = right;					break;
							case "scintillaBack":			GLOBAL.editColor.scintillaBack = right;					break;
							case "SCE_B_COMMENT_Fore":		GLOBAL.editColor.SCE_B_COMMENT_Fore = right;			break;
							case "SCE_B_COMMENT_Back":		GLOBAL.editColor.SCE_B_COMMENT_Back = right;			break;
							case "SCE_B_NUMBER_Fore":		GLOBAL.editColor.SCE_B_NUMBER_Fore = right;				break;
							case "SCE_B_NUMBER_Back":		GLOBAL.editColor.SCE_B_NUMBER_Back = right;				break;
							case "SCE_B_STRING_Fore":		GLOBAL.editColor.SCE_B_STRING_Fore = right;				break;
							case "SCE_B_STRING_Back":		GLOBAL.editColor.SCE_B_STRING_Back = right;				break;
							case "SCE_B_PREPROCESSOR_Fore":	GLOBAL.editColor.SCE_B_PREPROCESSOR_Fore = right;		break;
							case "SCE_B_PREPROCESSOR_Back":	GLOBAL.editColor.SCE_B_PREPROCESSOR_Back = right;		break;
							case "SCE_B_OPERATOR_Fore":		GLOBAL.editColor.SCE_B_OPERATOR_Fore = right;			break;
							case "SCE_B_OPERATOR_Back":		GLOBAL.editColor.SCE_B_OPERATOR_Back = right;			break;
							case "SCE_B_IDENTIFIER_Fore":	GLOBAL.editColor.SCE_B_IDENTIFIER_Fore = right;			break;
							case "SCE_B_IDENTIFIER_Back":	GLOBAL.editColor.SCE_B_IDENTIFIER_Back = right;			break;
							case "SCE_B_COMMENTBLOCK_Fore":	GLOBAL.editColor.SCE_B_COMMENTBLOCK_Fore = right;		break;
							case "SCE_B_COMMENTBLOCK_Back":	GLOBAL.editColor.SCE_B_COMMENTBLOCK_Back = right;		break;
							case "projectFore":				GLOBAL.editColor.projectFore = right;					break;
							case "projectBack":				GLOBAL.editColor.projectBack = right;					break;
							case "outlineFore":				GLOBAL.editColor.outlineFore = right;					break;
							case "outlineBack":				GLOBAL.editColor.outlineBack = right;					break;
							case "dlgFore":					GLOBAL.editColor.dlgFore = right;						break;
							case "dlgBack":					GLOBAL.editColor.dlgBack = right;						break;
							case "txtFore":					GLOBAL.editColor.txtFore = right;						break;
							case "txtBack":					GLOBAL.editColor.txtBack = right;						break;
							case "outputFore":				GLOBAL.editColor.outputFore = right;					break;
							case "outputBack":				GLOBAL.editColor.outputBack = right;					break;
							case "searchFore":				GLOBAL.editColor.searchFore = right;					break;
							case "searchBack":				GLOBAL.editColor.searchBack = right;					break;
							case "prjTitle":				GLOBAL.editColor.prjTitle = right;						break;
							case "prjSourceType":			GLOBAL.editColor.prjSourceType = right;					break;

							case "calltipFore":				if( right.length ) GLOBAL.editColor.callTipFore = right;					break;
							case "calltipBack":				if( right.length ) GLOBAL.editColor.callTipBack = right;					break;
							case "calltipHLT":				if( right.length ) GLOBAL.editColor.callTipHLT = right;						break;
							case "showtypeFore":			if( right.length ) GLOBAL.editColor.showTypeFore = right;					break;
							case "showtypeBack":			if( right.length ) GLOBAL.editColor.showTypeBack = right;					break;
							case "showtypeHLT":				if( right.length ) GLOBAL.editColor.showTypeHLT = right;					break;
							case "autoCompleteFore":		if( right.length ) GLOBAL.editColor.autoCompleteFore = right;				break;
							case "autoCompleteBack":		if( right.length ) GLOBAL.editColor.autoCompleteBack = right;				break;
							case "autoCompleteHLTFore":		if( right.length ) GLOBAL.editColor.autoCompleteHLTFore = right;			break;
							case "autoCompleteHLTBack":		if( right.length ) GLOBAL.editColor.autoCompleteHLTBack = right;			break;
							
							case "searchIndicator":			if( right.length ) GLOBAL.editColor.searchIndicator = right;				break;
							case "searchIndicatorAlpha":	if( right.length ) GLOBAL.editColor.searchIndicatorAlpha = right;			break;
							case "prjViewHLT":				if( right.length ) GLOBAL.editColor.prjViewHLT = right;						break;
							
							default:
						}
						break;

					case "[shortkeys]":
						string	title;
						int		index;
					
						switch( left )
						{
							case "save":					index = 0; title = GLOBAL.languageItems["sc_save"].toDString();						break;
							case "saveall":					index = 1; title = GLOBAL.languageItems["sc_saveall"].toDString();					break;
							case "close":					index = 2; title = GLOBAL.languageItems["sc_close"].toDString();					break;
							case "newtab":					index = 3; title = GLOBAL.languageItems["sc_newtab"].toDString();					break;
							case "nexttab":					index = 4; title = GLOBAL.languageItems["sc_nexttab"].toDString();					break;
							case "prevtab":					index = 5; title = GLOBAL.languageItems["sc_prevtab"].toDString();					break;

							case "dupdown":					index = 6; title = GLOBAL.languageItems["sc_dupdown"].toDString();					break;
							case "dupup":					index = 7; title = GLOBAL.languageItems["sc_dupup"].toDString();					break;
							case "delline":					index = 8; title = GLOBAL.languageItems["sc_delline"].toDString();					break;
							case "find":					index = 9; title = GLOBAL.languageItems["sc_findreplace"].toDString();				break;
							case "findinfile":				index =10; title = GLOBAL.languageItems["sc_findreplacefiles"].toDString();			break;
							case "findnext":				index =11; title = GLOBAL.languageItems["sc_findnext"].toDString();					break;
							case "findprev":				index =12; title = GLOBAL.languageItems["sc_findprev"].toDString();					break;
							case "gotoline":				index =13; title = GLOBAL.languageItems["sc_goto"].toDString();						break;
							case "undo":					index =14; title = GLOBAL.languageItems["sc_undo"].toDString();						break;
							case "redo":					index =15; title = GLOBAL.languageItems["sc_redo"].toDString();						break;
							case "comment":					index =16; title = GLOBAL.languageItems["sc_comment"].toDString();					break;
							case "uncomment":				index =17; title = GLOBAL.languageItems["sc_uncomment"].toDString();				break;
							case "backnav":					index =18; title = GLOBAL.languageItems["sc_backnav"].toDString();					break;
							case "forwardnav":				index =19; title = GLOBAL.languageItems["sc_forwardnav"].toDString();				break;
							
							case "showtype":				index =20; title = GLOBAL.languageItems["sc_showtype"].toDString();					break;
							case "defintion":				index =21; title = GLOBAL.languageItems["sc_gotodef"].toDString();					break;
							case "procedure":				index =22; title = GLOBAL.languageItems["sc_procedure"].toDString();				break;
							case "autocomplete":			index =23; title = GLOBAL.languageItems["sc_autocomplete"].toDString();				break;
							case "reparse":					index =24; title = GLOBAL.languageItems["sc_reparse"].toDString();					break;

							case "compilerun":				index =25; title = GLOBAL.languageItems["sc_compilerun"].toDString();				break;
							case "quickrun":				index =26; title = GLOBAL.languageItems["sc_quickrun"].toDString();					break;
							case "run":						index =27; title = GLOBAL.languageItems["sc_run"].toDString();						break;
							case "build":					index =28; title = GLOBAL.languageItems["sc_build"].toDString();					break;

							case "leftwindow":				index =29; title = GLOBAL.languageItems["sc_leftwindowswitch"].toDString();			break;
							case "bottomwindow":			index =30; title = GLOBAL.languageItems["sc_bottomwindowswitch"].toDString();		break;
							case "outlinewindow":			index =31; title = GLOBAL.languageItems["sc_leftwindow"].toDString();				break;
							case "messagewindow":			index =32; title = GLOBAL.languageItems["sc_bottomwindow"].toDString();				break;
							
							case "customtool1", "customtool2", "customtool3", "customtool4", "customtool5", "customtool6", "customtool7", "customtool8", "customtool9", "customtool10", "customtool11", "customtool12":
								index = Conv.to!(int)( left[10..$] ) + 32;
								title = GLOBAL.languageItems[left].toDString();
								break;
							default:
								left = "";
						}
						
						if( left.length )
						{
							ShortKey sk = { left, title, convertShortKeyValue2Integer( right ) };
							GLOBAL.shortKeys[index]= sk;
						}
						break;
						
					case "[buildtools]":
						switch( left )
						{
							case "compilerpath":			
								GLOBAL.compilerSettings.compilerFullPath = right;
								version(linux) GLOBAL.compilerSettings.x64compilerFullPath = right;
								break;
							case "x64compilerpath":
								version(Windows) GLOBAL.compilerSettings.x64compilerFullPath = right;
								break;
							case "debuggerpath":			GLOBAL.compilerSettings.debuggerFullPath = right;		break;
							case "x64debuggerpath":			GLOBAL.compilerSettings.x64debuggerFullPath = right;	break;
							case "terminalpath":			GLOBAL.linuxTermName = right;							break;
							case "htmlapppath":				GLOBAL.linuxHtmlAppName = right;						break;
							case "resultwindow":			GLOBAL.compilerSettings.useResultDlg = right;			break;
							case "usesfx":					GLOBAL.compilerSettings.useSFX = right;					break;
							case "annotation":				GLOBAL.compilerSettings.useAnootation = right;			break;
							case "delexistexe":				GLOBAL.compilerSettings.useDelExistExe = right;			break;
							case "consoleexe":				GLOBAL.compilerSettings.useConsoleLaunch = right;		break;
							case "compileatbackthread":		GLOBAL.compilerSettings.useThread = right;				break;
							case "consoleid":				GLOBAL.consoleWindow.id = Conv.to!(int)( right );		break;
							case "consolex":				GLOBAL.consoleWindow.x = Conv.to!(int)( right );		break;
							case "consoley":				GLOBAL.consoleWindow.y = Conv.to!(int)( right );		break;
							case "consolew":				GLOBAL.consoleWindow.w = Conv.to!(int)( right );		break;
							case "consoleh":				GLOBAL.consoleWindow.h = Conv.to!(int)( right );		break;
							default:
						}
						break;
						
					case "[parser]":
						switch( left )
						{
							case "enablekeywordcomplete":	GLOBAL.compilerSettings.enableKeywordComplete = right;							break;
							case "enableincludecomplete":	GLOBAL.compilerSettings.enableIncludeComplete = right;							break;
							case "enableparser":			GLOBAL.enableParser = right;									break;
							case "parsertrigger":			GLOBAL.autoCompletionTriggerWordCount = Conv.to!(int)( right );	break;
							case "togglepreloadprj":		GLOBAL.togglePreLoadPrj = right;								break;
							case "showfunctiontitle":		GLOBAL.showFunctionTitle = right;								break;
							case "showtypewithparams":		GLOBAL.showTypeWithParams = right;								break;
							case "includelevel":			GLOBAL.compilerSettings.includeLevel = Conv.to!(int)( right );					break;
							case "preparselevel":			GLOBAL.preParseLevel = Conv.to!(int)( right );					break;
							case "ignorecase":				GLOBAL.toggleIgnoreCase = right;								break;
							case "caseinsensitive":			GLOBAL.toggleCaseInsensitive = right;							break;
							//case "showlisttype":			GLOBAL.toggleShowListType = right;								break;
							case "showallmember":			GLOBAL.compilerSettings.toggleShowAllMember = right;								break;
							case "enabledwell":				GLOBAL.toggleEnableDwell = right;								break;
							case "enableoverwrite":			GLOBAL.toggleOverWrite = right;									break;
							case "completeatbackthread":	GLOBAL.toggleCompleteAtBackThread = right;						break;
							case "livelevel":				GLOBAL.liveLevel = Conv.to!(int)( right );						break;
							case "updateoutlinelive":		GLOBAL.toggleUpdateOutlineLive = right;							break;
							case "keywordcase":				GLOBAL.keywordCase = Conv.to!(int)( right );						break;
							case "dwelldelay":				GLOBAL.dwellDelay = right;										break;
							case "triggerdelay":			GLOBAL.triggerDelay = right;									break;
							case "autocmaxheight":			GLOBAL.autoCMaxHeight = Conv.to!(int)( right );					break;
							case "extraext":				GLOBAL.extraParsableExt = right;								break;
							default:
						}
						break;
					
					case "[manual]":
						switch( left )
						{
							case "manualusing":				GLOBAL.toggleUseManual = right;									break;
							case "name":					GLOBAL.manuals ~= right;										break;
							default:
						}
						break;
						
					case "[recentFiles]":
						if( left == "name" ) GLOBAL.recentFiles ~= new IupString( right );
						break;
						
					case "[recentProjects]":
						if( left == "name" ) GLOBAL.recentProjects ~= new IupString( right );
						break;

					case "[recentOptions]":
						switch( left )
						{
							case "name":						GLOBAL.recentOptions ~= right;								break;
							default:
						}					
						break;

					case "[recentArgs]":
						switch( left )
						{
							case "name":						GLOBAL.recentArgs ~= right;									break;
							default:
						}					
						break;

					case "[recentCompilers]":
						switch( left )
						{
							case "name":						GLOBAL.recentCompilers ~= right;							break;
							default:
						}					
						break;

					case "[customCompilerOptions]":
						switch( left )
						{
							case "current":						GLOBAL.compilerSettings.currentCustomCompilerOption = right;					break;
							case "none":						GLOBAL.compilerSettings.noneCustomCompilerOption = right;					break; // Hiddle Option
							case "name":						GLOBAL.compilerSettings.customCompilerOptions ~= right;						break;
							default:
						}
						break;
						
					case "[prevPrjs]":							if( left == "name" ) GLOBAL.prevPrj ~= right;				break;
					case "[prevDocs]":							if( left == "name" ) GLOBAL.prevDoc ~= right;				break;
					
					case "[opacity]":
						switch( left )
						{
							case "findfilesdlg":				GLOBAL.editorSetting02.findfilesDlg = right;				break;
							case "preferencedlg":				GLOBAL.editorSetting02.preferenceDlg = right;				break;
							case "projectdlg":					GLOBAL.editorSetting02.projectDlg = right;					break;
							case "gotodlg":						GLOBAL.editorSetting02.gotoDlg = right;						break;
							case "newfiledlg":					GLOBAL.editorSetting02.newfileDlg = right;					break;
							case "autocompletedlg":				GLOBAL.editorSetting02.autocompleteDlg = right; 			break;
							default:
						}
						break;

					default:
				}
			}
		}
		catch( Exception e )
		{
			debug writefln( e.toString );
			IupMessageError( GLOBAL.mainDlg, toStringz( e.toString ) );
		}
		
		version(linux) GLOBAL.compilerSettings.x64compilerFullPath = GLOBAL.compilerSettings.compilerFullPath;
	}
	
	static void saveFileStatus()
	{
		try
		{
			string doc;
			
			// Editor
			doc ~= "[poseidonDocStatus]\n";
			
			foreach( f; GLOBAL.fileStatusManager.keys )
			{
				string lineData;
				
				doc ~= ( f ~ "=" );
				
				foreach( size_t i, int value; GLOBAL.fileStatusManager[f] )
				{
					if( i == 0 )
						doc ~= ( "(" ~ Conv.to!string( value ) ~ ")" );
					else
					{
						doc ~= ( Conv.to!string( value ) ~ "," );
					}
				}
				
				doc ~= "\n";
			}

			string iniPath = GLOBAL.poseidonPath ~ "/settings/docStatus.ini";
			if( GLOBAL.linuxHome.length ) iniPath = GLOBAL.linuxHome ~ "/settings/docStatus.ini"; // Under AppImage
			actionManager.FileAction.saveFile( iniPath, doc, BOM.utf8, false );
		}
		catch( Exception e )
		{
		}
	}	

	static void loadFileStatus()
	{
		try
		{
			string iniPath = GLOBAL.poseidonPath ~ "/settings/docStatus.ini";
			if( GLOBAL.linuxHome.length ) iniPath = GLOBAL.linuxHome ~ "/settings/docStatus.ini"; // In main.d, the .poseidonFB or .poseidonD path already added in linuxHome 
			if( !std.file.exists( iniPath ) ) return;
			
			// Load INI
			/*
			int _bom, _withbom;
			string doc = FileAction.loadFile( iniPath, _bom, _withbom );
			*/
			string doc = cast(string) std.file.read( iniPath );
			
			string	blockText;
			bool	bCheckPass;
			foreach( lineData; splitLines( doc ) )
			{
				lineData = strip( lineData );
				
				if( !bCheckPass )
				{
					if( lineData == "[poseidonDocStatus]" )
					{
						bCheckPass = true;
						continue;
					}
					else
					{
						return;
					}
				}
				
				// Get Line Data
				auto assignPos = indexOf( lineData, "=" );
				if( assignPos > -1 )
				{
					int		pos;
					string	fullPath = tools.normalizeSlash( lineData[0..assignPos] );
					string	rightData = lineData[assignPos+1..$].dup;
					
					auto closeParenPos = indexOf( rightData, ")" );
					if( closeParenPos > -1 )
					{
						pos = Conv.to!(int)( rightData[1..closeParenPos] );
						GLOBAL.fileStatusManager[fullPath] ~= pos;
					
						foreach( s; Array.split( rightData[closeParenPos+1..$], "," ) )
						{
							if( s.length ) GLOBAL.fileStatusManager[fullPath] ~= Conv.to!(int)(s);
						}
					}
				}
			}
		}
		catch( Exception e )
		{
		
		}
	}
	
	
	static bool loadColorTemplateINI( string templateName )
	{
		try
		{
			string iniPath = GLOBAL.poseidonPath ~ "/settings/colorTemplates/" ~ templateName ~ ".ini";
			if( GLOBAL.linuxHome.length ) iniPath = GLOBAL.linuxHome ~ "/settings/colorTemplates/" ~ templateName ~ ".ini"; // In main.d, the .poseidonFB or .poseidonD path already added in linuxHome 
			if( !std.file.exists( iniPath ) )
			{
				debug writefln( "loadColorTemplateINI() file isn't exist error!" );
				IupMessageError( GLOBAL.mainDlg, "loadColorTemplateINI() file isn't existed!" );
				return false;
			}
			
			// Load INI
			string	blockText;
			int _enconding, _withBom;
			auto doc = FileAction.loadFile( iniPath, _enconding, _withBom );
			foreach( lineData; splitLines( doc ) )
			{
				string left, right;
				lineData = strip( lineData );
				
				// Get Line Data
				int _result = tools.getINILineData( lineData, left, right );
				if( _result == 1 )
				{
					blockText = left;
					continue;
				}
				else if( _result == 0 )
				{
					continue;
				}
				else
				{
					if( !right.length ) continue;
				}
				
				if( blockText == "[color]" )
				{
					switch( left )
					{
						case	"caretLine":				IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnCaretLine" ), "FGCOLOR", toStringz( right ) ); break;
						case	"cursor":					IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnCursor" ), "FGCOLOR", toStringz( right ) ); break;
						case	"fold":						IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnFoldingColor" ), "FGCOLOR", toStringz( right ) ); break;
						case	"selAlpha":
								version(Windows) IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-textSelAlpha" ), "SPINVALUE", toStringz( right ) );
								version(linux) IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-textSelAlpha" ), "VALUE", toStringz( right ) );
								break;
						case	"prjTitle":					IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnPrjTitle" ), "FGCOLOR", toStringz( right ) ); break;
						case	"prjSourceType":			IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSourceTypeFolder" ), "FGCOLOR", toStringz( right ) ); break;
						
						case	"dlgFore":					IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnDlg_FG" ), "FGCOLOR", toStringz( right ) ); break;
						case	"dlgBack":					IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnDlg_BG" ), "FGCOLOR", toStringz( right ) ); break;
						case	"txtFore":					IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnTxt_FG" ), "FGCOLOR", toStringz( right ) ); break;
						case	"txtBack":					IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnTxt_BG" ), "FGCOLOR", toStringz( right ) ); break;
						
						case	"projectFore":				IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnPrj_FG" ), "FGCOLOR", toStringz( right ) ); break;
						case	"projectBack":				IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnPrj_BG" ), "FGCOLOR", toStringz( right ) ); break;
						case	"outlineFore":				IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnOutline_FG" ), "FGCOLOR", toStringz( right ) ); break;
						case	"outlineBack":				IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnOutline_BG" ), "FGCOLOR", toStringz( right ) ); break;
						case	"outputFore":				IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnOutput_FG" ), "FGCOLOR", toStringz( right ) ); break;
						case	"outputBack":				IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnOutput_BG" ), "FGCOLOR", toStringz( right ) ); break;
						case	"searchFore":				IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSearch_FG" ), "FGCOLOR", toStringz( right ) ); break;
						case	"searchBack":				IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSearch_BG" ), "FGCOLOR", toStringz( right ) ); break;
						case	"selectionFore":			IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSelectFore" ), "FGCOLOR", toStringz( right ) ); break;
						case	"selectionBack":			IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSelectBack" ), "FGCOLOR", toStringz( right ) ); break;
						case	"linenumFore":				IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnLinenumFore" ), "FGCOLOR", toStringz( right ) ); break;
						case	"linenumBack":				IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnLinenumBack" ), "FGCOLOR", toStringz( right ) ); break;
						case	"currentword":				IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnIndicator" ), "FGCOLOR", toStringz( right ) ); break;
						case	"currentwordAlpha":
								version(Windows) IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-textIndicatorAlpha" ), "SPINVALUE", toStringz( right ) );
								version(linux) IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-textIndicatorAlpha" ), "VALUE", toStringz( right ) );
								break;
						case	"messageIndicator":			IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnMessageIndicator" ), "FGCOLOR", toStringz( right ) ); break;
						case	"messageIndicatorAlpha":
								version(Windows) IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-textMessageIndicatorAlpha" ), "SPINVALUE", toStringz( right ) );
								version(linux) IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-textMessageIndicatorAlpha" ), "VALUE", toStringz( right ) );
								break;
						case	"braceFore":				IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnBrace_FG" ), "FGCOLOR", toStringz( right ) ); break;
						case	"braceBack":				IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnBrace_BG" ), "FGCOLOR", toStringz( right ) ); break;
						case	"errorFore":				IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnError_FG" ), "FGCOLOR", toStringz( right ) ); break;
						case	"errorBack":				IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnError_BG" ), "FGCOLOR", toStringz( right ) ); break;
						case	"warningFore":				IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnWarning_FG" ), "FGCOLOR", toStringz( right ) ); break;
						case	"warningBack":				IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnWarning_BG" ), "FGCOLOR", toStringz( right ) ); break;
						case	"prjViewHLT":				IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnLeftViewHLT" ), "FGCOLOR", toStringz( right ) ); break;
						case 	"showtypeFore":				IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnShowType_FG" ), "FGCOLOR", toStringz( right ) ); break;
						case 	"showtypeBack":				IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnShowType_BG" ), "FGCOLOR", toStringz( right ) ); break;
						case 	"showtypeHLT":				IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnShowTypeHLT" ), "FGCOLOR", toStringz( right ) ); break;
						case 	"calltipFore":				IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnCallTip_FG" ), "FGCOLOR", toStringz( right ) ); break;
						case	"calltipBack":				IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnCallTip_BG" ), "FGCOLOR", toStringz( right ) ); break;
						case 	"calltipHLT":				IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnCallTipHLT" ), "FGCOLOR", toStringz( right ) ); break;
						case 	"autoCompleteFore":			IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnAutoComplete_FG" ), "FGCOLOR", toStringz( right ) ); break;
						case	"autoCompleteBack":			IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnAutoComplete_BG" ), "FGCOLOR", toStringz( right ) ); break;
						case	"autoCompleteHLTFore":		IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnAutoCompleteHLT_FG" ), "FGCOLOR", toStringz( right ) ); break;
						case	"autoCompleteHLTBack":		IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnAutoCompleteHLT_BG" ), "FGCOLOR", toStringz( right ) ); break;

						case	"scintillaFore":			IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btn_Scintilla_FG" ), "FGCOLOR", toStringz( right ) ); break;
						case	"scintillaBack":			IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btn_Scintilla_BG" ), "FGCOLOR", toStringz( right ) ); break;
						case	"SCE_B_COMMENT_Fore":		IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_COMMENT_FG" ), "FGCOLOR", toStringz( right ) ); break;
						case	"SCE_B_COMMENT_Back":		IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_COMMENT_BG" ), "FGCOLOR", toStringz( right ) ); break;
						case	"SCE_B_NUMBER_Fore":		IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_NUMBER_FG" ), "FGCOLOR", toStringz( right ) ); break;
						case	"SCE_B_NUMBER_Back":		IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_NUMBER_BG" ), "FGCOLOR", toStringz( right ) ); break;
						case	"SCE_B_STRING_Fore":		IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_STRING_FG" ), "FGCOLOR", toStringz( right ) ); break;
						case	"SCE_B_STRING_Back":		IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_STRING_BG" ), "FGCOLOR", toStringz( right ) ); break;
						case	"SCE_B_PREPROCESSOR_Fore":	IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_PREPROCESSOR_FG" ), "FGCOLOR", toStringz( right ) ); break;
						case	"SCE_B_PREPROCESSOR_Back":	IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_PREPROCESSOR_BG" ), "FGCOLOR", toStringz( right ) ); break;
						case	"SCE_B_OPERATOR_Fore":		IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_OPERATOR_FG" ), "FGCOLOR", toStringz( right ) ); break;
						case	"SCE_B_OPERATOR_Back":		IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_OPERATOR_BG" ), "FGCOLOR", toStringz( right ) ); break;
						case	"SCE_B_IDENTIFIER_Fore":	IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_IDENTIFIER_FG" ), "FGCOLOR", toStringz( right ) ); break;
						case	"SCE_B_IDENTIFIER_Back":	IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_IDENTIFIER_BG" ), "FGCOLOR", toStringz( right ) ); break;
						case	"SCE_B_COMMENTBLOCK_Fore":	IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_COMMENTBLOCK_FG" ), "FGCOLOR", toStringz( right ) ); break;
						case	"SCE_B_COMMENTBLOCK_Back":	IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_COMMENTBLOCK_BG" ), "FGCOLOR", toStringz( right ) ); break;

						case	"keyword0":					IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord0Color" ), "FGCOLOR", toStringz( right ) ); break;
						case	"keyword1":					IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord1Color" ), "FGCOLOR", toStringz( right ) ); break;
						case	"keyword2":					IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord2Color" ), "FGCOLOR", toStringz( right ) ); break;
						case	"keyword3":					IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord3Color" ), "FGCOLOR", toStringz( right ) ); break;
						case	"keyword4":					IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord4Color" ), "FGCOLOR", toStringz( right ) ); break;
						case	"keyword5":					IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord5Color" ), "FGCOLOR", toStringz( right ) ); break;
						
						default:
					}
				}
				else if( blockText == "[toggle]" )
				{
					if( left == "IconInvert" )
					{
						switch( right )
						{
							case "ON":
								IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-toggleIconInvert" ), "VALUE", "ON" ); break;
							case "ALL":
								IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-toggleIconInvertAll" ), "VALUE", "ON" ); break;
							default:
								IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-toggleIcon" ), "VALUE", "ON" );
						}
					}
					else if( left == "DarkMode" )
					{
						IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-toggleDarkMode" ), "VALUE", toStringz( right ) );
					}
				}
			}
			if( GLOBAL.preferenceDlg.getIhandle != null ) IupUpdateChildren( GLOBAL.preferenceDlg.getIhandle );
		}
		catch( Exception e )
		{
			debug writefln( "loadColorTemplateINI() error!\n" ~ Conv.to!(string)(e.line) );
			return false;
		}
		
		return true;
	}
	

	static void saveColorTemplateINI( string templateName )
	{
		if( GLOBAL.preferenceDlg is null ) return;
		if( !GLOBAL.preferenceDlg.getIhandle ) return;
		
		try
		{
			string templatePath = GLOBAL.poseidonPath ~ "/settings/colorTemplates";
			if( GLOBAL.linuxHome.length ) templatePath = GLOBAL.linuxHome ~ "/settings/colorTemplates";
			if( !std.file.exists( templatePath ) ) std.file.mkdir( templatePath );
			
			string doc = "[color]\n";
			doc ~= setINILineData( "caretLine", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnCaretLine" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "cursor", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnCursor" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "fold", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnFoldingColor" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "selAlpha", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-textSelAlpha" ), "VALUE" ) ) );
			doc ~= setINILineData( "prjTitle", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnPrjTitle" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "prjSourceType", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSourceTypeFolder" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "dlgFore", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnDlg_FG" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "dlgBack", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnDlg_BG" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "txtFore", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnTxt_FG" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "txtBack", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnTxt_BG" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "projectFore", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnPrj_FG" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "projectBack", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnPrj_BG" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "outlineFore", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnOutline_FG" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "outlineBack", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnOutline_BG" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "outputFore", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnOutput_FG" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "outputBack", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnOutput_BG" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "searchFore", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSearch_FG" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "searchBack", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSearch_BG" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "selectionFore", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSelectFore" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "selectionBack", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSelectBack" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "linenumFore", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnLinenumFore" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "linenumBack", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnLinenumBack" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "currentword", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnIndicator" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "currentwordAlpha", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textIndicatorAlpha" ), "VALUE" ) ) );
			doc ~= setINILineData( "messageIndicator", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnMessageIndicator" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "messageIndicatorAlpha", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textMessageIndicatorAlpha" ), "VALUE" ) ) );
			doc ~= setINILineData( "braceFore", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnBrace_FG" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "braceBack", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnBrace_BG" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "errorFore", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnError_FG" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "errorBack", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnError_BG" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "warningFore", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnWarning_FG" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "warningBack", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnWarning_BG" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "prjViewHLT", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnLeftViewHLT" ), "FGCOLOR" ) ) );

			doc ~= setINILineData( "showTypeFore", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnShowType_FG" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "showTypeBack", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnShowType_BG" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "showTypeHLT", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnShowTypeHLT" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "callTipFore", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnCallTip_FG" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "callTipBack", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnCallTip_BG" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "callTipHLT", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnCallTipHLT" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "autoCompleteFore", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnAutoComplete_FG" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "autoCompleteBack", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnAutoComplete_BG" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "autoCompleteHLTFore", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnAutoCompleteHLT_FG" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "autoCompleteHLTBack", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnAutoCompleteHLT_BG" ), "FGCOLOR" ) ) );

			doc ~= setINILineData( "scintillaFore", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btn_Scintilla_FG" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "scintillaBack", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btn_Scintilla_BG" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "SCE_B_COMMENT_Fore", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_COMMENT_FG" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "SCE_B_COMMENT_Back", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_COMMENT_BG" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "SCE_B_NUMBER_Fore", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_NUMBER_FG" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "SCE_B_NUMBER_Back", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_NUMBER_BG" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "SCE_B_STRING_Fore", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_STRING_FG" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "SCE_B_STRING_Back", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_STRING_BG" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "SCE_B_PREPROCESSOR_Fore", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_PREPROCESSOR_FG" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "SCE_B_PREPROCESSOR_Back", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_PREPROCESSOR_BG" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "SCE_B_OPERATOR_Fore", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_OPERATOR_FG" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "SCE_B_OPERATOR_Back", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_OPERATOR_BG" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "SCE_B_IDENTIFIER_Fore", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_IDENTIFIER_FG" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "SCE_B_IDENTIFIER_Back", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_IDENTIFIER_BG" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "SCE_B_COMMENTBLOCK_Fore", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_COMMENTBLOCK_FG" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "SCE_B_COMMENTBLOCK_Back", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_COMMENTBLOCK_BG" ), "FGCOLOR" ) ) );
			
			doc ~= setINILineData( "keyword0", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord0Color" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "keyword1", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord1Color" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "keyword2", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord2Color" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "keyword3", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord3Color" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "keyword4", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord4Color" ), "FGCOLOR" ) ) );
			doc ~= setINILineData( "keyword5", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord5Color" ), "FGCOLOR" ) ) );

			doc ~= "[toggle]\n";
			
			if( fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-toggleIcon" ), "VALUE" ) ) == "ON" )
				doc ~= setINILineData( "IconInvert", "OFF" );
			else if( fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-toggleIconInvert" ), "VALUE" ) ) == "ON" )
				doc ~= setINILineData( "IconInvert", "ON" );
			else if( fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-toggleIconInvertAll" ), "VALUE" ) ) == "ON" )
				doc ~= setINILineData( "IconInvert", "ALL" );

			doc ~= setINILineData( "DarkMode", fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-toggleDarkMode" ), "VALUE" ) ) );
			
			if( !FileAction.saveFile( templatePath ~ "/" ~ templateName ~ ".ini", doc, BOM.utf8, true ) ) throw new Exception( "Save File Error" );
		}
		catch( Exception e )
		{
			debug writefln( e.toString );
			IupMessageError( GLOBAL.mainDlg, toStringz( e.toString ) );		
		}
	}	
}