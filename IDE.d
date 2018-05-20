module IDE;

struct IDECONFIG
{
	private:
	import iup.iup;
	
	import global, actionManager, tools;

	import tango.stdc.stringz, Integer = tango.text.convert.Integer, Util = tango.text.Util;
	import tango.text.xml.Document, tango.text.xml.DocPrinter, tango.io.UnicodeFile, tango.io.stream.Lines;
	import tango.io.FilePath;
	
	static bool loadLocalization()
	{
		// Load Language lng
		scope lngFilePath = new FilePath( "settings/language/" ~ GLOBAL.language ~ ".lng" );
		if( lngFilePath.exists() )
		{
			scope lngFile = new UnicodeFile!(char)( lngFilePath.toString, Encoding.Unknown );
			char[] lngDocument = lngFile.read();
			
			foreach( char[] s; Util.splitLines( lngDocument ) )
			{
				s = Util.trim( s );
				if( s.length )
				{
					if( s[0] != '\'' )
					{
						int assignIndex = Util.index( s, "=" );
						if( assignIndex < s.length )
						{
							try
							{
								GLOBAL.languageItems[Util.trim( s[0..assignIndex] )] = Util.trim( s[assignIndex+1..$] );
							}
							catch( Exception e )
							{
								//GLOBAL.IDEMessageDlg.print( Util.trim( s[0..assignIndex] ) ~ "=Error" );
								debug IupMessage( toStringz( "Language Error!" ), toStringz( Util.trim( s[0..assignIndex] ) ~ "=Error" ) );
							}
						}
					}
				}
			}
			return true;
		}
		return false;
	}
	
	version(linux) static void setLinuxTerminal()
	{
		// Get linux terminal program name
		
		//char[] termNameFile = cast(char[]) File.get( "/etc/alternatives/x-terminal-emulator" );
		GLOBAL.linuxTermName = "/etc/alternatives/x-terminal-emulator";
		scope term = new UnicodeFile!(char)( "/etc/alternatives/x-terminal-emulator", Encoding.Unknown );
		char[] termNameFile = term.read;
		if( termNameFile.length )
		{
			int pos = Util.rindex( termNameFile, "exec('" ); 
			if( pos < termNameFile.length )
			{
				GLOBAL.linuxTermName = "";
				for( int i = pos + 6; i < termNameFile.length; ++ i )
				{
					if( termNameFile[i] == '\'' ) break;
					GLOBAL.linuxTermName ~= termNameFile[i];
				}
			}
		}
	}


	public:

	static char[] convertShortKeyValue2String( int keyValue )
	{
		char[] result;

		if( keyValue & 0x20000000 ) result = "C+";else result = "+";
		if( keyValue & 0x10000000 ) result ~= "S+";else result ~= "+";
		if( keyValue & 0x40000000 ) result ~= "A+";else result ~= "+";

		keyValue = keyValue & 0xFFFF;

		if( keyValue == 0x9 ) // TAB
		{
			result = result ~ "TAB";
		}
		if( keyValue >= 0x41 && keyValue <= 90 ) // 'A' ~ 'Z'
		{
			char c = keyValue;
			result = result ~ c;
		}
		else if( keyValue >= 0xFFBE && keyValue <= 0xFFC9 ) // 'F1' ~ 'F12'
		{
			result = result ~ "F" ~ Integer.toString( keyValue - 0xFFBD );
		}
		
		return result;
	}	

	static int convertShortKeyValue2Integer( char[] keyValue )
	{
		char[][] splitWord = Util.split( keyValue, "+" );
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
								result = result + 0xFFBD + Integer.atoi( splitWord[3][1..length] );
							}
						}
				}
			}
		}

		return result;
	}	

	static void saveINI( char[] fullpath = "settings/editorSettings.ini" )
	{
		try
		{
			char[] doc;
			
			// Editor
			doc ~= setINILineData( "[editor]");
			doc ~= setINILineData( "lexer", GLOBAL.lexer );
			doc ~= setINILineData( "language", GLOBAL.language );
			
			for( int i = 0; i < 4; ++ i )
				doc ~= setINILineData( "keyword" ~ Integer.toString( i ), Util.trim( GLOBAL.KEYWORDS[i].toDString ) );

			for( int i = 1; i < 10; ++ i )
				doc ~= setINILineData( "customtools" ~ Integer.toString( i ), Util.trim( GLOBAL.customTools[i].name.toDString ) ~ "," ~ Util.trim( GLOBAL.customTools[i].dir.toDString ) ~ "," ~ Util.trim( GLOBAL.customTools[i].args.toDString ) );
				
			doc ~= setINILineData( "indicatorStyle", Integer.toString( GLOBAL.indicatorStyle ) );

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
			doc ~= setINILineData( "Message", GLOBAL.editorSetting00.Message );
			doc ~= setINILineData( "BoldKeyword", GLOBAL.editorSetting00.BoldKeyword );
			doc ~= setINILineData( "BraceMatchHighlight", GLOBAL.editorSetting00.BraceMatchHighlight );
			doc ~= setINILineData( "MultiSelection", GLOBAL.editorSetting00.MultiSelection );
			doc ~= setINILineData( "LoadPrevDoc", GLOBAL.editorSetting00.LoadPrevDoc );
			doc ~= setINILineData( "HighlightCurrentWord", GLOBAL.editorSetting00.HighlightCurrentWord );
			doc ~= setINILineData( "MiddleScroll", GLOBAL.editorSetting00.MiddleScroll );
			doc ~= setINILineData( "SaveDocStatus", GLOBAL.editorSetting00.DocStatus );
			doc ~= setINILineData( "LoadAtBackThread", GLOBAL.editorSetting00.LoadAtBackThread );
			doc ~= setINILineData( "ControlCharSymbol", GLOBAL.editorSetting00.ControlCharSymbol );
			doc ~= setINILineData( "GUI", GLOBAL.editorSetting00.GUI );
			doc ~= setINILineData( "Bit64", GLOBAL.editorSetting00.Bit64 );
			
			
			
			if( fromStringz( IupGetAttribute( GLOBAL.menuOutlineWindow, "VALUE" ) ) == "OFF" )
				GLOBAL.editorSetting01.ExplorerSplit = Integer.toString( GLOBAL.explorerSplit_value );
			else
				GLOBAL.editorSetting01.ExplorerSplit = IupGetInt( GLOBAL.explorerSplit, "VALUE" ) <= 0 ? "180" : fromStringz( IupGetAttribute( GLOBAL.explorerSplit, "VALUE" ) ).dup;
			
			if( fromStringz( IupGetAttribute( GLOBAL.menuMessageWindow, "VALUE" ) ) == "OFF" )
				GLOBAL.editorSetting01.MessageSplit = Integer.toString( GLOBAL.messageSplit_value ).dup;
			else
				GLOBAL.editorSetting01.MessageSplit = IupGetInt( GLOBAL.messageSplit, "VALUE" ) >= 1000 ? "850" : fromStringz( IupGetAttribute( GLOBAL.messageSplit, "VALUE" ) ).dup;

			if( fromStringz( IupGetAttribute( GLOBAL.menuFistlistWindow, "VALUE" ) ) == "OFF" )
				GLOBAL.editorSetting01.FileListSplit = Integer.toString( GLOBAL.fileListSplit_value ).dup;
			else
				GLOBAL.editorSetting01.FileListSplit = IupGetInt( GLOBAL.fileListSplit, "VALUE" ) >= 1000 ? "900" : fromStringz( IupGetAttribute( GLOBAL.fileListSplit, "VALUE" ) ).dup;
				
			//GLOBAL.editorSetting01.FileListSplit = fromStringz( IupGetAttribute( GLOBAL.fileListSplit, "VALUE" ) ).dup;
			
			GLOBAL.editorSetting01.OutlineWindow = fromStringz( IupGetAttribute( GLOBAL.menuOutlineWindow, "VALUE" ) ).dup;
			GLOBAL.editorSetting01.MessageWindow = fromStringz( IupGetAttribute( GLOBAL.menuMessageWindow, "VALUE" ) ).dup;
			GLOBAL.editorSetting01.FilelistWindow = fromStringz( IupGetAttribute( GLOBAL.menuFistlistWindow, "VALUE" ) ).dup;
			//FilelistWindow

			// size
			doc ~= setINILineData( "[size]");
			if( GLOBAL.editorSetting01.PLACEMENT == "MINIMIZED" ) doc ~= setINILineData( "PLACEMENT", "NORMAL" ); else doc ~= setINILineData( "PLACEMENT", GLOBAL.editorSetting01.PLACEMENT );
			doc ~= setINILineData( "USEFULLSCREEN", GLOBAL.editorSetting01.USEFULLSCREEN );
			doc ~= setINILineData( "RASTERSIZE", GLOBAL.editorSetting01.RASTERSIZE );
			doc ~= setINILineData( "ExplorerSplit", GLOBAL.editorSetting01.ExplorerSplit );
			doc ~= setINILineData( "MessageSplit", GLOBAL.editorSetting01.MessageSplit );
			doc ~= setINILineData( "FileListSplit", GLOBAL.editorSetting01.FileListSplit );
			doc ~= setINILineData( "OutlineWindow", GLOBAL.editorSetting01.OutlineWindow );
			doc ~= setINILineData( "MessageWindow", GLOBAL.editorSetting01.MessageWindow );
			doc ~= setINILineData( "FilelistWindow", GLOBAL.editorSetting01.FilelistWindow );
			doc ~= setINILineData( "RotateTabs", GLOBAL.editorSetting01.RotateTabs );
			doc ~= setINILineData( "BarSize", GLOBAL.editorSetting01.BarSize );
			
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
			doc ~= setINILineData( "keyword0", GLOBAL.editColor.keyWord[0].toDString );
			doc ~= setINILineData( "keyword1", GLOBAL.editColor.keyWord[1].toDString );
			doc ~= setINILineData( "keyword2", GLOBAL.editColor.keyWord[2].toDString );
			doc ~= setINILineData( "keyword3", GLOBAL.editColor.keyWord[3].toDString );	
			doc ~= setINILineData( "template", GLOBAL.colorTemplate.toDString );
			doc ~= setINILineData( "caretLine", GLOBAL.editColor.caretLine.toDString );
			doc ~= setINILineData( "cursor", GLOBAL.editColor.cursor.toDString );
			doc ~= setINILineData( "selectionFore", GLOBAL.editColor.selectionFore.toDString );
			doc ~= setINILineData( "selectionBack", GLOBAL.editColor.selectionBack.toDString );
			doc ~= setINILineData( "linenumFore", GLOBAL.editColor.linenumFore.toDString );
			doc ~= setINILineData( "linenumBack", GLOBAL.editColor.linenumBack.toDString );
			doc ~= setINILineData( "fold", GLOBAL.editColor.fold.toDString );
			doc ~= setINILineData( "selAlpha", GLOBAL.editColor.selAlpha.toDString );
			doc ~= setINILineData( "currentword", GLOBAL.editColor.currentWord.toDString );
			doc ~= setINILineData( "currentwordAlpha", GLOBAL.editColor.currentWordAlpha.toDString );
			doc ~= setINILineData( "braceFore", GLOBAL.editColor.braceFore.toDString );
			doc ~= setINILineData( "braceBack", GLOBAL.editColor.braceBack.toDString );		
			doc ~= setINILineData( "errorFore", GLOBAL.editColor.errorFore.toDString );
			doc ~= setINILineData( "errorBack", GLOBAL.editColor.errorBack.toDString );
			doc ~= setINILineData( "warningFore", GLOBAL.editColor.warningFore.toDString );
			doc ~= setINILineData( "warningBack", GLOBAL.editColor.warringBack.toDString );
			doc ~= setINILineData( "scintillaFore", GLOBAL.editColor.scintillaFore.toDString );
			doc ~= setINILineData( "scintillaBack", GLOBAL.editColor.scintillaBack.toDString );
			doc ~= setINILineData( "SCE_B_COMMENT_Fore", GLOBAL.editColor.SCE_B_COMMENT_Fore.toDString );
			doc ~= setINILineData( "SCE_B_COMMENT_Back", GLOBAL.editColor.SCE_B_COMMENT_Back.toDString );
			doc ~= setINILineData( "SCE_B_NUMBER_Fore", GLOBAL.editColor.SCE_B_NUMBER_Fore.toDString );
			doc ~= setINILineData( "SCE_B_NUMBER_Back", GLOBAL.editColor.SCE_B_NUMBER_Back.toDString );
			doc ~= setINILineData( "SCE_B_STRING_Fore", GLOBAL.editColor.SCE_B_STRING_Fore.toDString );
			doc ~= setINILineData( "SCE_B_STRING_Back", GLOBAL.editColor.SCE_B_STRING_Back.toDString );
			doc ~= setINILineData( "SCE_B_PREPROCESSOR_Fore", GLOBAL.editColor.SCE_B_PREPROCESSOR_Fore.toDString );
			doc ~= setINILineData( "SCE_B_PREPROCESSOR_Back", GLOBAL.editColor.SCE_B_PREPROCESSOR_Back.toDString );
			doc ~= setINILineData( "SCE_B_OPERATOR_Fore", GLOBAL.editColor.SCE_B_OPERATOR_Fore.toDString );
			doc ~= setINILineData( "SCE_B_OPERATOR_Back", GLOBAL.editColor.SCE_B_OPERATOR_Back.toDString );
			doc ~= setINILineData( "SCE_B_IDENTIFIER_Fore", GLOBAL.editColor.SCE_B_IDENTIFIER_Fore.toDString );
			doc ~= setINILineData( "SCE_B_IDENTIFIER_Back", GLOBAL.editColor.SCE_B_IDENTIFIER_Back.toDString );
			doc ~= setINILineData( "SCE_B_COMMENTBLOCK_Fore", GLOBAL.editColor.SCE_B_COMMENTBLOCK_Fore.toDString );
			doc ~= setINILineData( "SCE_B_COMMENTBLOCK_Back", GLOBAL.editColor.SCE_B_COMMENTBLOCK_Back.toDString );
			doc ~= setINILineData( "projectFore", GLOBAL.editColor.projectFore.toDString );
			doc ~= setINILineData( "projectBack", GLOBAL.editColor.projectBack.toDString );
			doc ~= setINILineData( "outlineFore", GLOBAL.editColor.outlineFore.toDString );
			doc ~= setINILineData( "outlineBack", GLOBAL.editColor.outlineBack.toDString );	
			doc ~= setINILineData( "filelistFore", GLOBAL.editColor.filelistFore.toDString );
			doc ~= setINILineData( "filelistBack", GLOBAL.editColor.filelistBack.toDString );
			doc ~= setINILineData( "outputFore", GLOBAL.editColor.outputFore.toDString );
			doc ~= setINILineData( "outputBack", GLOBAL.editColor.outputBack.toDString );
			doc ~= setINILineData( "searchFore", GLOBAL.editColor.searchFore.toDString );
			doc ~= setINILineData( "searchBack", GLOBAL.editColor.searchBack.toDString );
			doc ~= setINILineData( "prjTitle", GLOBAL.editColor.prjTitle.toDString );
			doc ~= setINILineData( "prjSourceType", GLOBAL.editColor.prjSourceType.toDString );
			doc ~= setINILineData( "maker0", GLOBAL.editColor.maker[0].toDString );
			doc ~= setINILineData( "maker1", GLOBAL.editColor.maker[1].toDString );
			doc ~= setINILineData( "maker2", GLOBAL.editColor.maker[2].toDString );
			doc ~= setINILineData( "maker3", GLOBAL.editColor.maker[3].toDString );
			doc ~= setINILineData( "calltipFore", GLOBAL.editColor.callTip_Fore.toDString );
			doc ~= setINILineData( "calltipBack", GLOBAL.editColor.callTip_Back.toDString );
			doc ~= setINILineData( "calltipHLT", GLOBAL.editColor.callTip_HLT.toDString );
			
			// shortkeys
			doc ~= setINILineData( "[shortkeys]");
			doc ~= setINILineData( "save", convertShortKeyValue2String( GLOBAL.shortKeys[0].keyValue ) );
			doc ~= setINILineData( "saveall", convertShortKeyValue2String( GLOBAL.shortKeys[1].keyValue ) );
			doc ~= setINILineData( "close", convertShortKeyValue2String( GLOBAL.shortKeys[2].keyValue ) );
			doc ~= setINILineData( "newtab", convertShortKeyValue2String( GLOBAL.shortKeys[3].keyValue ) );
			doc ~= setINILineData( "nexttab", convertShortKeyValue2String( GLOBAL.shortKeys[4].keyValue ) );
			doc ~= setINILineData( "prevtab", convertShortKeyValue2String( GLOBAL.shortKeys[5].keyValue ) );

			doc ~= setINILineData( "cut", convertShortKeyValue2String( GLOBAL.shortKeys[6].keyValue ) );
			doc ~= setINILineData( "copy", convertShortKeyValue2String( GLOBAL.shortKeys[7].keyValue ) );
			doc ~= setINILineData( "paste", convertShortKeyValue2String( GLOBAL.shortKeys[8].keyValue ) );
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
			
			doc ~= setINILineData( "outlinewindow", convertShortKeyValue2String( GLOBAL.shortKeys[29].keyValue ) );
			doc ~= setINILineData( "messagewindow", convertShortKeyValue2String( GLOBAL.shortKeys[30].keyValue ) );
			
			doc ~= setINILineData( "customtool1", convertShortKeyValue2String( GLOBAL.shortKeys[31].keyValue ) );
			doc ~= setINILineData( "customtool2", convertShortKeyValue2String( GLOBAL.shortKeys[32].keyValue ) );
			doc ~= setINILineData( "customtool3", convertShortKeyValue2String( GLOBAL.shortKeys[33].keyValue ) );
			doc ~= setINILineData( "customtool4", convertShortKeyValue2String( GLOBAL.shortKeys[34].keyValue ) );
			doc ~= setINILineData( "customtool5", convertShortKeyValue2String( GLOBAL.shortKeys[35].keyValue ) );
			doc ~= setINILineData( "customtool6", convertShortKeyValue2String( GLOBAL.shortKeys[36].keyValue ) );
			doc ~= setINILineData( "customtool7", convertShortKeyValue2String( GLOBAL.shortKeys[37].keyValue ) );
			doc ~= setINILineData( "customtool8", convertShortKeyValue2String( GLOBAL.shortKeys[38].keyValue ) );
			doc ~= setINILineData( "customtool9", convertShortKeyValue2String( GLOBAL.shortKeys[39].keyValue ) );
			
			// buildtools
			doc ~= setINILineData( "[buildtools]");
			doc ~= setINILineData( "compilerpath", GLOBAL.compilerFullPath.toDString );
			doc ~= setINILineData( "x64compilerpath", GLOBAL.x64compilerFullPath.toDString );
			doc ~= setINILineData( "debuggerpath", GLOBAL.debuggerFullPath.toDString );
			//doc ~= setINILineData( "defaultoption", GLOBAL.defaultOption.toDString );
			doc ~= setINILineData( "resultwindow", GLOBAL.compilerWindow );
			doc ~= setINILineData( "usesfx", GLOBAL.compilerSFX );
			doc ~= setINILineData( "annotation", GLOBAL.compilerAnootation );
			doc ~= setINILineData( "delexistexe", GLOBAL.delExistExe );
			doc ~= setINILineData( "consoleexe", GLOBAL.consoleExe );
			doc ~= setINILineData( "compileatbackthread", GLOBAL.toggleCompileAtBackThread );
			doc ~= setINILineData( "consoleid", Integer.toString( GLOBAL.consoleWindow.id ) );
			doc ~= setINILineData( "consolex", Integer.toString( GLOBAL.consoleWindow.x ) );
			doc ~= setINILineData( "consoley", Integer.toString( GLOBAL.consoleWindow.y ) );
			doc ~= setINILineData( "consolew", Integer.toString( GLOBAL.consoleWindow.w ) );
			doc ~= setINILineData( "consoleh", Integer.toString( GLOBAL.consoleWindow.h ) );

			// parser
			doc ~= setINILineData( "[parser]");
			doc ~= setINILineData( "enablekeywordcomplete", GLOBAL.enableKeywordComplete );
			doc ~= setINILineData( "enableincludecomplete", GLOBAL.enableIncludeComplete );
			doc ~= setINILineData( "enableparser", GLOBAL.enableParser );
			doc ~= setINILineData( "parsertrigger", Integer.toString( GLOBAL.autoCompletionTriggerWordCount ) );
			doc ~= setINILineData( "showfunctiontitle", GLOBAL.showFunctionTitle );
			doc ~= setINILineData( "widthfunctiontitle", GLOBAL.widthFunctionTitle.toDString );
			doc ~= setINILineData( "showtypewithparams", GLOBAL.showTypeWithParams );
			doc ~= setINILineData( "includelevel", Integer.toString( GLOBAL.includeLevel ) );
			doc ~= setINILineData( "ignorecase", GLOBAL.toggleIgnoreCase );
			doc ~= setINILineData( "caseinsensitive", GLOBAL.toggleCaseInsensitive );
			doc ~= setINILineData( "showlisttype", GLOBAL.toggleShowListType );
			doc ~= setINILineData( "showallmember", GLOBAL.toggleShowAllMember );
			doc ~= setINILineData( "enabledwell", GLOBAL.toggleEnableDwell );
			doc ~= setINILineData( "enableoverwrite", GLOBAL.toggleOverWrite );
			doc ~= setINILineData( "completeatbackthread", GLOBAL.toggleCompleteAtBackThread );
			doc ~= setINILineData( "completedelay", GLOBAL.completeDelay.toDString );
			doc ~= setINILineData( "livelevel", Integer.toString( GLOBAL.liveLevel ) );
			doc ~= setINILineData( "updateoutlinelive", GLOBAL.toggleUpdateOutlineLive );
			doc ~= setINILineData( "keywordcase", Integer.toString( GLOBAL.keywordCase ) );
			
			// manual
			doc ~= setINILineData( "[manual]");
			doc ~= setINILineData( "manualpath", GLOBAL.manualPath.toDString );
			doc ~= setINILineData( "manualusing", GLOBAL.toggleUseManual );

			// recentFiles
			doc ~= setINILineData( "[recentFiles]" );
			for( int i = 0; i < GLOBAL.recentFiles.length; ++i )
				doc ~= setINILineData( "name", GLOBAL.recentFiles[i].toDString );

			// recentProjects
			doc ~= setINILineData( "[recentProjects]" );
			for( int i = 0; i < GLOBAL.recentProjects.length; ++i )
				doc ~= setINILineData( "name", GLOBAL.recentProjects[i].toDString );

			// recentProjects
			doc ~= setINILineData( "[recentOptions]" );
			doc ~= setINILineData( "max", Integer.toString( GLOBAL.maxRecentOptions ) );
			for( int i = 0; i < GLOBAL.recentOptions.length; ++i )
				doc ~= setINILineData( "name", GLOBAL.recentOptions[i] );

			// recentProjects
			doc ~= setINILineData( "[recentArgs]" );
			doc ~= setINILineData( "max", Integer.toString( GLOBAL.maxRecentArgs ) );
			for( int i = 0; i < GLOBAL.recentArgs.length; ++i )
				doc ~= setINILineData( "name", GLOBAL.recentArgs[i] );

			// customCompilerOptions
			doc ~= setINILineData( "[customCompilerOptions]" );
			doc ~= setINILineData( "current", GLOBAL.currentCustomCompilerOption.toDString );
			doc ~= setINILineData( "none", GLOBAL.noneCustomCompilerOption.toDString );
			for( int i = 0; i < GLOBAL.customCompilerOptions.length; ++i )
				doc ~= setINILineData( "name", GLOBAL.customCompilerOptions[i] );

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
			doc ~= setINILineData( "searchdlg", GLOBAL.editorSetting02.searchDlg );
			doc ~= setINILineData( "findfilesdlg", GLOBAL.editorSetting02.findfilesDlg );
			doc ~= setINILineData( "preferencedlg", GLOBAL.editorSetting02.preferenceDlg );
			doc ~= setINILineData( "projectdlg", GLOBAL.editorSetting02.preferenceDlg );
			doc ~= setINILineData( "gotodlg", GLOBAL.editorSetting02.gotoDlg );
			doc ~= setINILineData( "newfiledlg", GLOBAL.editorSetting02.newfileDlg );
			
			actionManager.FileAction.saveFile( fullpath, doc );
		}
		catch( Exception e )
		{
			IupMessage( "Save editorSettings.ini Error", toStringz( e.toString ) );
		}
	}
	
	static void loadINI()
	{
		char[]	left, right;
		try
		{
			version( linux ) setLinuxTerminal(); // Get linux terminal program name
			
			scope settingFilePath = new FilePath( "settings/editorSettings.ini" );
			if( !settingFilePath.exists() )
			{
				/+
				load(); // load xml
				Ihandle* messageDlg = IupMessageDlg();
				IupSetAttributes( messageDlg, "DIALOGTYPE=ERROR" );
				IupSetAttribute( messageDlg, "VALUE", GLOBAL.languageItems["wrongext"].toCString );
				IupSetAttribute( messageDlg, "TITLE", GLOBAL.languageItems["error"].toCString );
				IupPopup( messageDlg, IUP_MOUSEPOS, IUP_MOUSEPOS );
				+/
				return;
			}
			
			// Load INI
			scope file = new UnicodeFile!(char)( "settings/editorSettings.ini", Encoding.Unknown );
			char[] doc = file.read();
			
			char[]	blockText;
			foreach( char[] lineData; Util.splitLines( doc ) )
			{
				lineData = Util.trim( lineData );
				
				// Get Line Data
				int _result = getINILineData( lineData, left, right );
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
				
				switch( blockText )
				{
					case "[editor]":
						switch( left )
						{
							case "lexer":			
								version(DIDE)
									GLOBAL.lexer = "d";
								else
									GLOBAL.lexer = right;
								break;

							case "keyword0":		GLOBAL.KEYWORDS[0] = right;						break;
							case "keyword1":		GLOBAL.KEYWORDS[1] = right;						break;
							case "keyword2":		GLOBAL.KEYWORDS[2] = right;						break;
							case "keyword3":		GLOBAL.KEYWORDS[3] = right;						break;
							case "indicatorStyle":	GLOBAL.indicatorStyle = Integer.atoi( right );	break;
							case "language":
								GLOBAL.language = right;
								loadLocalization(); // Load Language lng
								break;
							case "customtools1", "customtools2", "customtools3", "customtools4", "customtools5", "customtools6", "customtools7", "customtools8", "customtools9":
								int index = Integer.atoi( left[$-1..$] );
								char[][] values = Util.split( right, "," );
								if( values.length == 3 )
								{
									if( values[0].length )
									{
										GLOBAL.customTools[index].name = values[0];
										if( values[1].length ) GLOBAL.customTools[index].dir = values[1];
										if( values[2].length ) GLOBAL.customTools[index].args = values[2];
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
							case "Message":					GLOBAL.editorSetting00.Message = right;					break;
							case "BoldKeyword":				GLOBAL.editorSetting00.BoldKeyword = right;				break;
							case "BraceMatchHighlight":		GLOBAL.editorSetting00.BraceMatchHighlight = right;		break;
							case "MultiSelection":			GLOBAL.editorSetting00.MultiSelection = right;			break;
							case "LoadPrevDoc":				GLOBAL.editorSetting00.LoadPrevDoc = right;				break;
							case "HighlightCurrentWord":	GLOBAL.editorSetting00.HighlightCurrentWord = right;	break;
							case "MiddleScroll":			GLOBAL.editorSetting00.MiddleScroll = right;			break;
							case "SaveDocStatus":			GLOBAL.editorSetting00.DocStatus = right;				break;
							case "LoadAtBackThread":		GLOBAL.editorSetting00.LoadAtBackThread = right;		break;
							case "ControlCharSymbol":		GLOBAL.editorSetting00.ControlCharSymbol = right;		break;
							case "GUI":						GLOBAL.editorSetting00.GUI = right;						break;
							case "Bit64":					GLOBAL.editorSetting00.Bit64 = right;					break;
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
							case "FileListSplit":			GLOBAL.editorSetting01.FileListSplit = right;			break;
							case "OutlineWindow":			GLOBAL.editorSetting01.OutlineWindow = right;			break;
							case "MessageWindow":			GLOBAL.editorSetting01.MessageWindow = right;			break;
							case "FilelistWindow":			GLOBAL.editorSetting01.FilelistWindow = right;			break;
							case "RotateTabs":				GLOBAL.editorSetting01.RotateTabs = right;				break;
							case "BarSize":
								GLOBAL.editorSetting01.BarSize = right;
								int _size = Integer.atoi( right );
								if( _size < 2 ) GLOBAL.editorSetting01.BarSize = "2";
								if( _size > 5 ) GLOBAL.editorSetting01.BarSize = "5";
								break;
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
							case "Search":					GLOBAL.fonts[8].fontString = right; 					break;		break;
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
							case "template":				GLOBAL.colorTemplate = right;							break;
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
							case "warningBack":				GLOBAL.editColor.warringBack = right;					break;
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
							case "filelistFore":			GLOBAL.editColor.filelistFore = right;					break;
							case "filelistBack":			GLOBAL.editColor.filelistBack = right;					break;
							case "outputFore":				GLOBAL.editColor.outputFore = right;					break;
							case "outputBack":				GLOBAL.editColor.outputBack = right;					break;
							case "searchFore":				GLOBAL.editColor.searchFore = right;					break;
							case "searchBack":				GLOBAL.editColor.searchBack = right;					break;
							case "prjTitle":				GLOBAL.editColor.prjTitle = right;						break;
							case "prjSourceType":			GLOBAL.editColor.prjSourceType = right;					break;
							case "maker0":					GLOBAL.editColor.maker[0] = right;						break;
							case "maker1":					GLOBAL.editColor.maker[1] = right;						break;
							case "maker2":					GLOBAL.editColor.maker[2] = right;						break;
							case "maker3":					GLOBAL.editColor.maker[3] = right;						break;
							
							case "calltipFore":				GLOBAL.editColor.callTip_Fore = right;					break;
							case "calltipBack":				GLOBAL.editColor.callTip_Back = right;					break;
							case "calltipHLT":				GLOBAL.editColor.callTip_HLT = right;					break;
							
							default:
						}
						break;

					case "[shortkeys]":
						char[]	title;
						int		index;
					
						switch( left )
						{
							case "save":					index = 0; title = GLOBAL.languageItems["sc_save"].toDString();						break;
							case "saveall":					index = 1; title = GLOBAL.languageItems["sc_saveall"].toDString();					break;
							case "close":					index = 2; title = GLOBAL.languageItems["sc_close"].toDString();					break;
							case "newtab":					index = 3; title = GLOBAL.languageItems["sc_newtab"].toDString();					break;
							case "nexttab":					index = 4; title = GLOBAL.languageItems["sc_nexttab"].toDString();					break;
							case "prevtab":					index = 5; title = GLOBAL.languageItems["sc_prevtab"].toDString();					break;

							case "cut":						index = 6; title = GLOBAL.languageItems["caption_cut"].toDString();					break;
							case "copy":					index = 7; title = GLOBAL.languageItems["caption_copy"].toDString();				break;
							case "paste":					index = 8; title = GLOBAL.languageItems["caption_paste"].toDString();				break;
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

							case "outlinewindow":			index =29; title = GLOBAL.languageItems["sc_leftwindow"].toDString();				break;
							case "messagewindow":			index =30; title = GLOBAL.languageItems["sc_bottomwindow"].toDString();				break;
							
							case "customtool1", "customtool2", "customtool3", "customtool4", "customtool5", "customtool6", "customtool7", "customtool8", "customtool9":
								index = Integer.atoi( left[$-1..$] ) + 30;
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
								GLOBAL.compilerFullPath = right;
								version(DIDE) GLOBAL.x64compilerFullPath = right;
								break;
							case "x64compilerpath":			version(FBIDE) GLOBAL.x64compilerFullPath = right;		break;
							case "debuggerpath":			GLOBAL.debuggerFullPath = right;						break;
							//case "defaultoption":			GLOBAL.defaultOption = right;							break;
							case "resultwindow":			GLOBAL.compilerWindow = right;							break;
							case "usesfx":					GLOBAL.compilerSFX = right;								break;
							case "annotation":				GLOBAL.compilerAnootation = right;						break;
							case "delexistexe":				GLOBAL.delExistExe = right;								break;
							case "consoleexe":				GLOBAL.consoleExe = right;								break;
							case "compileatbackthread":		GLOBAL.toggleCompileAtBackThread = right;				break;
							case "consoleid":				GLOBAL.consoleWindow.id = Integer.atoi( right );		break;
							case "consolex":				GLOBAL.consoleWindow.x = Integer.atoi( right );			break;
							case "consoley":				GLOBAL.consoleWindow.y = Integer.atoi( right );			break;
							case "consolew":				GLOBAL.consoleWindow.w = Integer.atoi( right );			break;
							case "consoleh":				GLOBAL.consoleWindow.h = Integer.atoi( right );			break;
							default:
						}
						break;
						
					case "[parser]":
						switch( left )
						{
							case "enablekeywordcomplete":	GLOBAL.enableKeywordComplete = right;							break;
							case "enableincludecomplete":	GLOBAL.enableIncludeComplete = right;							break;
							case "enableparser":			GLOBAL.enableParser = right;									break;
							case "parsertrigger":			GLOBAL.autoCompletionTriggerWordCount = Integer.atoi( right );	break;
							case "showfunctiontitle":		GLOBAL.showFunctionTitle = right;								break;
							case "widthfunctiontitle":		GLOBAL.widthFunctionTitle = right;								break;
							case "showtypewithparams":		GLOBAL.showTypeWithParams = right;								break;
							case "includelevel":			GLOBAL.includeLevel = Integer.atoi( right );					break;
							case "ignorecase":				GLOBAL.toggleIgnoreCase = right;								break;
							case "caseinsensitive":			GLOBAL.toggleCaseInsensitive = right;							break;
							case "showlisttype":			GLOBAL.toggleShowListType = right;								break;
							case "showallmember":			GLOBAL.toggleShowAllMember = right;								break;
							case "enabledwell":				GLOBAL.toggleEnableDwell = right;								break;
							case "enableoverwrite":			GLOBAL.toggleOverWrite = right;									break;
							case "completeatbackthread":	GLOBAL.toggleCompleteAtBackThread = right;						break;
							case "completedelay":			GLOBAL.completeDelay = right;									break;
							case "livelevel":				GLOBAL.liveLevel = Integer.atoi( right );						break;
							case "updateoutlinelive":		GLOBAL.toggleUpdateOutlineLive = right;							break;
							case "keywordcase":				GLOBAL.keywordCase = Integer.atoi( right );						break;
							default:
						}
						break;
					
					case "[manual]":
						switch( left )
						{
							case "manualpath":				GLOBAL.manualPath = right;										break;
							case "manualusing":				GLOBAL.toggleUseManual = right;									break;
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
							case "max":							GLOBAL.maxRecentOptions = Integer.toInt( right );			break; // Hiddle Option
							case "name":						GLOBAL.recentOptions ~= right;								break;
							default:
						}					
						break;

					case "[recentArgs]":
						switch( left )
						{
							case "max":							GLOBAL.maxRecentArgs = Integer.toInt( right );				break; // Hiddle Option
							case "name":						GLOBAL.recentArgs ~= right;									break;
							default:
						}					
						break;

					case "[customCompilerOptions]":
						switch( left )
						{
							case "current":						GLOBAL.currentCustomCompilerOption = right;					break;
							case "none":						GLOBAL.noneCustomCompilerOption = right;					break; // Hiddle Option
							case "name":						GLOBAL.customCompilerOptions ~= right;						break;
							default:
						}
						break;
						
					case "[prevPrjs]":							if( left == "name" ) GLOBAL.prevPrj ~= right;				break;
					case "[prevDocs]":							if( left == "name" ) GLOBAL.prevDoc ~= right;				break;
					
					case "[opacity]":
						switch( left )
						{
							case "searchdlg":					GLOBAL.editorSetting02.searchDlg = right;					break;
							case "findfilesdlg":				GLOBAL.editorSetting02.findfilesDlg = right;				break;
							case "preferencedlg":				GLOBAL.editorSetting02.preferenceDlg = right;				break;
							case "projectdlg":					GLOBAL.editorSetting02.projectDlg = right;					break;
							case "gotodlg":						GLOBAL.editorSetting02.gotoDlg = right;						break;
							case "newfiledlg":					GLOBAL.editorSetting02.newfileDlg = right;					break;
							default:
						}
						break;
						
					default:
				}
			}
		}
		catch( Exception e )
		{
			IupMessage( "Load editorSettings.ini Error Left", toStringz( left ) );
			IupMessage( "Load editorSettings.ini Error Right", toStringz( right ) );
		}
		
		// Get and Set Default Import Path
		version(DIDE) GLOBAL.defaultImportPaths = tools.getImportPath( GLOBAL.compilerFullPath.toDString );		
	}
	
	static void saveFileStatus()
	{
		try
		{
			char[] doc;
			
			// Editor
			doc ~= "[poseidonDocStatus]\n";
			
			foreach( char[] f; GLOBAL.fileStatusManager.keys )
			{
				char[] lineData;
				
				doc ~= ( f ~ "=" );
				
				foreach( int i, int value; GLOBAL.fileStatusManager[f] )
				{
					if( i == 0 )
						doc ~= ( "(" ~ Integer.toString( value ) ~ ")" );
					else
					{
						doc ~= ( Integer.toString( value ) ~ "," );
					}
				}
				
				doc ~= "\n";
			}
			
			actionManager.FileAction.saveFile( "settings/docStatus.ini", doc );
		}
		catch( Exception e )
		{
		
		}
	}	

	static void loadFileStatus()
	{
		try
		{
			scope settingFilePath = new FilePath( "settings/docStatus.ini" );
			if( !settingFilePath.exists() ) return;
			
			// Load INI
			scope file = new UnicodeFile!(char)( "settings/docStatus.ini", Encoding.Unknown );
			char[] doc = file.read();
			
			char[]	blockText;
			bool	bCheckPass;
			foreach( char[] lineData; Util.splitLines( doc ) )
			{
				lineData = Util.trim( lineData );
				
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
				int assignPos = Util.index( lineData, "=" );
				if( assignPos < lineData.length )
				{
					int		pos;
					char[]	fullPath = Path.normalize( lineData[0..assignPos] );
					char[]	rightData = lineData[assignPos+1..$];
					
					int closeParenPos = Util.index( rightData, ")" );
					if( closeParenPos < rightData.length )
					{
						pos = Integer.toInt( rightData[1..closeParenPos] );
						GLOBAL.fileStatusManager[fullPath] ~= pos;
					
						foreach( char[] s; Util.split( rightData[closeParenPos+1..$], "," ) )
						{
							if( s.length ) GLOBAL.fileStatusManager[fullPath] ~= Integer.toInt(s);
						}
					}
				}
			}
		}
		catch( Exception e )
		{
		
		}
	}
	
	
	static void saveColorTemplate( char[] templateName )
	{
		// Write Setting File...
		auto doc = new Document!(char);

		// attach an xml header
		doc.header;

		auto configNode = doc.tree.element( null, "config" );

		configNode.element( null, "color" )
		.attribute( null, "keyword0", GLOBAL.editColor.keyWord[0].toDString )
		.attribute( null, "keyword1", GLOBAL.editColor.keyWord[1].toDString )
		.attribute( null, "keyword2", GLOBAL.editColor.keyWord[2].toDString )
		.attribute( null, "keyword3", GLOBAL.editColor.keyWord[3].toDString )
		.attribute( null, "caretLine", GLOBAL.editColor.caretLine.toDString )
		.attribute( null, "cursor", GLOBAL.editColor.cursor.toDString )
		.attribute( null, "selectionFore", GLOBAL.editColor.selectionFore.toDString )
		.attribute( null, "selectionBack", GLOBAL.editColor.selectionBack.toDString )
		.attribute( null, "linenumFore", GLOBAL.editColor.linenumFore.toDString )
		.attribute( null, "linenumBack", GLOBAL.editColor.linenumBack.toDString )
		.attribute( null, "fold", GLOBAL.editColor.fold.toDString )
		.attribute( null, "selAlpha", GLOBAL.editColor.selAlpha.toDString )
		.attribute( null, "braceFore", GLOBAL.editColor.braceFore.toDString )
		.attribute( null, "braceBack", GLOBAL.editColor.braceBack.toDString )
		.attribute( null, "errorFore", GLOBAL.editColor.errorFore.toDString )
		.attribute( null, "errorBack", GLOBAL.editColor.errorBack.toDString )
		.attribute( null, "warningFore", GLOBAL.editColor.warningFore.toDString )
		.attribute( null, "warningBack", GLOBAL.editColor.warringBack.toDString )
		.attribute( null, "scintillaFore", GLOBAL.editColor.scintillaFore.toDString )
		.attribute( null, "scintillaBack", GLOBAL.editColor.scintillaBack.toDString )
		.attribute( null, "SCE_B_COMMENT_Fore", GLOBAL.editColor.SCE_B_COMMENT_Fore.toDString )
		.attribute( null, "SCE_B_COMMENT_Back", GLOBAL.editColor.SCE_B_COMMENT_Back.toDString )
		.attribute( null, "SCE_B_NUMBER_Fore", GLOBAL.editColor.SCE_B_NUMBER_Fore.toDString )
		.attribute( null, "SCE_B_NUMBER_Back", GLOBAL.editColor.SCE_B_NUMBER_Back.toDString )
		.attribute( null, "SCE_B_STRING_Fore", GLOBAL.editColor.SCE_B_STRING_Fore.toDString )
		.attribute( null, "SCE_B_STRING_Back", GLOBAL.editColor.SCE_B_STRING_Back.toDString )
		.attribute( null, "SCE_B_PREPROCESSOR_Fore", GLOBAL.editColor.SCE_B_PREPROCESSOR_Fore.toDString )
		.attribute( null, "SCE_B_PREPROCESSOR_Back", GLOBAL.editColor.SCE_B_PREPROCESSOR_Back.toDString )
		.attribute( null, "SCE_B_OPERATOR_Fore", GLOBAL.editColor.SCE_B_OPERATOR_Fore.toDString )
		.attribute( null, "SCE_B_OPERATOR_Back", GLOBAL.editColor.SCE_B_OPERATOR_Back.toDString )
		.attribute( null, "SCE_B_IDENTIFIER_Fore", GLOBAL.editColor.SCE_B_IDENTIFIER_Fore.toDString )
		.attribute( null, "SCE_B_IDENTIFIER_Back", GLOBAL.editColor.SCE_B_IDENTIFIER_Back.toDString )
		.attribute( null, "SCE_B_COMMENTBLOCK_Fore", GLOBAL.editColor.SCE_B_COMMENTBLOCK_Fore.toDString )
		.attribute( null, "SCE_B_COMMENTBLOCK_Back", GLOBAL.editColor.SCE_B_COMMENTBLOCK_Back.toDString )
		.attribute( null, "projectFore", GLOBAL.editColor.projectFore.toDString )
		.attribute( null, "projectBack", GLOBAL.editColor.projectBack.toDString )
		.attribute( null, "outlineFore", GLOBAL.editColor.outlineFore.toDString )
		.attribute( null, "outlineBack", GLOBAL.editColor.outlineBack.toDString )		
		.attribute( null, "filelistFore", GLOBAL.editColor.filelistFore.toDString )
		.attribute( null, "filelistBack", GLOBAL.editColor.filelistBack.toDString )
		.attribute( null, "outputFore", GLOBAL.editColor.outputFore.toDString )
		.attribute( null, "outputBack", GLOBAL.editColor.outputBack.toDString )
		.attribute( null, "searchFore", GLOBAL.editColor.searchFore.toDString )
		.attribute( null, "searchBack", GLOBAL.editColor.searchBack.toDString )
		.attribute( null, "prjTitle", GLOBAL.editColor.prjTitle.toDString )
		.attribute( null, "prjSourceType", GLOBAL.editColor.prjSourceType.toDString )
		.attribute( null, "currentword", GLOBAL.editColor.currentWord.toDString )
		.attribute( null, "currentwordAlpha", GLOBAL.editColor.currentWordAlpha.toDString );		
		
		auto print = new DocPrinter!(char);
		scope _fp = new FilePath( "settings/colorTemplates" );
		if( !_fp.exists() )	_fp.createFolder();
		
		actionManager.FileAction.saveFile( "settings/colorTemplates/" ~ templateName ~ ".xml", print.print( doc ) );
	}
	
	static char[][] loadColorTemplate( char[] templateName )
	{
		char[][] results;
		
		try
		{
			// Loading Key Word...
			scope _fp = new FilePath( "settings/colorTemplates/" ~ templateName ~ ".xml" );
			if( !_fp.exists() ) return null;
			
			scope file = new UnicodeFile!(char)( _fp.toString, Encoding.Unknown );

			scope doc = new Document!( char );
			doc.parse( file.read );

			auto root = doc.elements;
			
			auto result = root.query.descendant("color").attribute("caretLine");
			foreach( e; result ) results ~= e.value;

			result = root.query.descendant("color").attribute("cursor");
			foreach( e; result ) results ~= e.value;

			result = root.query.descendant("color").attribute("selectionFore");
			foreach( e; result ) results ~= e.value;

			result = root.query.descendant("color").attribute("selectionBack");
			foreach( e; result ) results ~= e.value;
			
			result = root.query.descendant("color").attribute("linenumFore");
			foreach( e; result ) results ~= e.value;

			result = root.query.descendant("color").attribute("linenumBack");
			foreach( e; result ) results ~= e.value;

			result = root.query.descendant("color").attribute("fold");
			foreach( e; result ) results ~= e.value;

			result = root.query.descendant("color").attribute("selAlpha");
			foreach( e; result ) results ~= e.value;
			
			result = root.query.descendant("color").attribute("braceFore");
			foreach( e; result ) results ~= e.value;
			result = root.query.descendant("color").attribute("braceBack");
			foreach( e; result ) results ~= e.value;

			result = root.query.descendant("color").attribute("errorFore");
			foreach( e; result ) results ~= e.value;
			result = root.query.descendant("color").attribute("errorBack");
			foreach( e; result ) results ~= e.value;

			result = root.query.descendant("color").attribute("warningFore");
			foreach( e; result ) results ~= e.value;
			result = root.query.descendant("color").attribute("warningBack");
			foreach( e; result ) results ~= e.value;

			result = root.query.descendant("color").attribute("scintillaFore");
			foreach( e; result ) results ~= e.value;
			result = root.query.descendant("color").attribute("scintillaBack");
			foreach( e; result ) results ~= e.value;
			
			result = root.query.descendant("color").attribute("SCE_B_COMMENT_Fore");
			foreach( e; result ) results ~= e.value;
			result = root.query.descendant("color").attribute("SCE_B_COMMENT_Back");
			foreach( e; result ) results ~= e.value;
			
			result = root.query.descendant("color").attribute("SCE_B_NUMBER_Fore");
			foreach( e; result ) results ~= e.value;
			result = root.query.descendant("color").attribute("SCE_B_NUMBER_Back");
			foreach( e; result ) results ~= e.value;
			
			result = root.query.descendant("color").attribute("SCE_B_STRING_Fore");
			foreach( e; result ) results ~= e.value;
			result = root.query.descendant("color").attribute("SCE_B_STRING_Back");
			foreach( e; result ) results ~= e.value;

			result = root.query.descendant("color").attribute("SCE_B_PREPROCESSOR_Fore");
			foreach( e; result ) results ~= e.value;
			result = root.query.descendant("color").attribute("SCE_B_PREPROCESSOR_Back");
			foreach( e; result ) results ~= e.value;

			result = root.query.descendant("color").attribute("SCE_B_OPERATOR_Fore");
			foreach( e; result )results ~= e.value;
			result = root.query.descendant("color").attribute("SCE_B_OPERATOR_Back");
			foreach( e; result ) results ~= e.value;

			result = root.query.descendant("color").attribute("SCE_B_IDENTIFIER_Fore");
			foreach( e; result ) results ~= e.value;
			result = root.query.descendant("color").attribute("SCE_B_IDENTIFIER_Back");
			foreach( e; result ) results ~= e.value;

			result = root.query.descendant("color").attribute("SCE_B_COMMENTBLOCK_Fore");
			foreach( e; result ) results ~= e.value;
			result = root.query.descendant("color").attribute("SCE_B_COMMENTBLOCK_Back");
			foreach( e; result ) results ~= e.value;

			result = root.query.descendant("color").attribute("projectFore");
			foreach( e; result ) results ~= e.value;
			result = root.query.descendant("color").attribute("projectBack");
			foreach( e; result ) results ~= e.value;

			result = root.query.descendant("color").attribute("outlineFore");
			foreach( e; result ) results ~= e.value;
			result = root.query.descendant("color").attribute("outlineBack");
			foreach( e; result ) results ~= e.value;

			result = root.query.descendant("color").attribute("filelistFore");
			foreach( e; result ) results ~= e.value;
			result = root.query.descendant("color").attribute("filelistBack");
			foreach( e; result ) results ~= e.value;

			result = root.query.descendant("color").attribute("outputFore");
			foreach( e; result ) results ~= e.value;
			result = root.query.descendant("color").attribute("outputBack");
			foreach( e; result ) results ~= e.value;

			result = root.query.descendant("color").attribute("searchFore");
			foreach( e; result ) results ~= e.value;
			result = root.query.descendant("color").attribute("searchBack");
			foreach( e; result ) results ~= e.value;

			result = root.query.descendant("color").attribute("prjTitle");
			foreach( e; result ) results ~= e.value;
			result = root.query.descendant("color").attribute("prjSourceType");
			foreach( e; result ) results ~= e.value;
			
			result = root.query.descendant("color").attribute("keyword0");
			foreach( e; result ) results ~= e.value;

			result = root.query.descendant("color").attribute("keyword1");
			foreach( e; result ) results ~= e.value;

			result = root.query.descendant("color").attribute("keyword2");
			foreach( e; result ) results ~= e.value;

			result = root.query.descendant("color").attribute("keyword3");
			foreach( e; result ) results ~= e.value;
			
			result = root.query.descendant("color").attribute("currentword");
			foreach( e; result ) results ~= e.value;

			result = root.query.descendant("color").attribute("currentwordAlpha");
			foreach( e; result ) results ~= e.value;			
			
		}
		catch( Exception e ){}
		
		return results;
	}
}