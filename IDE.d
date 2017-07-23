module IDE;

struct IDECONFIG
{
	private:
	import iup.iup;
	
	import global, actionManager, tools;

	import tango.stdc.stringz, Integer = tango.text.convert.Integer, Util = tango.text.Util;
	import tango.text.xml.Document, tango.text.xml.DocPrinter, tango.io.UnicodeFile, tango.io.stream.Lines;
	import tango.io.FilePath;
	
	static char[] setINILineData( char[] left, char[] right = "" )
	{
		return left ~ "=" ~ right ~ "\n";
	}

	static void getINILineData( char[] lineData, out char[] left, out char[] right )
	{
		int assignPos = Util.index( lineData, "=" );
		if( assignPos < lineData.length )
		{
			left	= Util.trim( lineData[0..assignPos] );
			right	= Util.trim( lineData[assignPos+1..$] );
		}			
	}
	
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
								IupMessage( toStringz( "Language Error!" ), toStringz( Util.trim( s[0..assignIndex] ) ~ "=Error" ) );
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

	static void save()
	{
		try
		{
			// Write Setting File...
			scope doc = new Document!(char);

			// attach an xml header
			doc.header;

			auto configNode = doc.tree.element( null, "config" );

			auto editorNode = configNode.element( null, "editor" );
			editorNode.element( null, "lexer", GLOBAL.lexer );
			
			editorNode.element( null, "language", GLOBAL.language );
			
			for( int i = 0; i < GLOBAL.KEYWORDS.length; ++i )
			{
				editorNode.element( null, "keywords" )
				.attribute( null, "id", Integer.toString( i ) ).attribute( null, "value", Util.trim( GLOBAL.KEYWORDS[i].toDString ) );
			}
			
			for( int i = 1; i < 10; ++i )
			{
				editorNode.element( null, "customtools" )
				.attribute( null, "id", Integer.toString( i ) ).attribute( null, "name", Util.trim( GLOBAL.customTools[i].name.toDString ) ).attribute( null, "dir", Util.trim( GLOBAL.customTools[i].dir.toDString ) ).attribute( null, "args", Util.trim( GLOBAL.customTools[i].args.toDString ) );
			}

			editorNode.element( null, "toggle00" )
			.attribute( null, "LineMargin", GLOBAL.editorSetting00.LineMargin )
			.attribute( null, "BookmarkMargin", GLOBAL.editorSetting00.BookmarkMargin )
			.attribute( null, "FoldMargin", GLOBAL.editorSetting00.FoldMargin )
			.attribute( null, "IndentGuide", GLOBAL.editorSetting00.IndentGuide )
			.attribute( null, "CaretLine", GLOBAL.editorSetting00.CaretLine )
			.attribute( null, "WordWrap", GLOBAL.editorSetting00.WordWrap )
			.attribute( null, "TabUseingSpace", GLOBAL.editorSetting00.TabUseingSpace )
			.attribute( null, "AutoIndent", GLOBAL.editorSetting00.AutoIndent )
			.attribute( null, "ShowEOL", GLOBAL.editorSetting00.ShowEOL )
			.attribute( null, "ShowSpace", GLOBAL.editorSetting00.ShowSpace )	
			.attribute( null, "AutoEnd", GLOBAL.editorSetting00.AutoEnd )	
			.attribute( null, "TabWidth", GLOBAL.editorSetting00.TabWidth )
			.attribute( null, "ColumnEdge", GLOBAL.editorSetting00.ColumnEdge )
			.attribute( null, "EolType", GLOBAL.editorSetting00.EolType )
			.attribute( null, "ColorOutline", GLOBAL.editorSetting00.ColorOutline )
			.attribute( null, "Message", GLOBAL.editorSetting00.Message )
			.attribute( null, "BoldKeyword", GLOBAL.editorSetting00.BoldKeyword )
			.attribute( null, "BraceMatchHighlight", GLOBAL.editorSetting00.BraceMatchHighlight )
			.attribute( null, "BraceMatchDoubleSidePos", GLOBAL.editorSetting00.BraceMatchDoubleSidePos )
			.attribute( null, "MultiSelection", GLOBAL.editorSetting00.MultiSelection )
			.attribute( null, "LoadPrevDoc", GLOBAL.editorSetting00.LoadPrevDoc )
			.attribute( null, "HighlightCurrentWord", GLOBAL.editorSetting00.HighlightCurrentWord );


			if( fromStringz( IupGetAttribute( GLOBAL.menuOutlineWindow, "VALUE" ) ) == "OFF" )
				GLOBAL.editorSetting01.ExplorerSplit = Integer.toString( GLOBAL.explorerSplit_value );
			else
				GLOBAL.editorSetting01.ExplorerSplit = fromStringz( IupGetAttribute( GLOBAL.explorerSplit, "VALUE" ) ).dup;
			
			if( fromStringz( IupGetAttribute( GLOBAL.menuMessageWindow, "VALUE" ) ) == "OFF" )
				GLOBAL.editorSetting01.MessageSplit = Integer.toString( GLOBAL.messageSplit_value ).dup;
			else
				GLOBAL.editorSetting01.MessageSplit = fromStringz( IupGetAttribute( GLOBAL.messageSplit, "VALUE" ) ).dup;
			
			
			GLOBAL.editorSetting01.FileListSplit = fromStringz( IupGetAttribute( GLOBAL.fileListSplit, "VALUE" ) ).dup;
			GLOBAL.editorSetting01.OutlineWindow = fromStringz( IupGetAttribute( GLOBAL.menuOutlineWindow, "VALUE" ) ).dup;
			GLOBAL.editorSetting01.MessageWindow = fromStringz( IupGetAttribute( GLOBAL.menuMessageWindow, "VALUE" ) ).dup;

			editorNode.element( null, "size01" )
			.attribute( null, "PLACEMENT", GLOBAL.editorSetting01.PLACEMENT )
			.attribute( null, "RASTERSIZE", GLOBAL.editorSetting01.RASTERSIZE )
			.attribute( null, "ExplorerSplit", GLOBAL.editorSetting01.ExplorerSplit )
			.attribute( null, "MessageSplit", GLOBAL.editorSetting01.MessageSplit )
			.attribute( null, "FileListSplit", GLOBAL.editorSetting01.FileListSplit )
			.attribute( null, "OutlineWindow", GLOBAL.editorSetting01.OutlineWindow )
			.attribute( null, "MessageWindow", GLOBAL.editorSetting01.MessageWindow );
			
			/+
			//<font name="Consolas" size="11" bold="OFF" italic="OFF" underline="OFF" forecolor="0 0 0" backcolor="255 255 255"></font>
			editorNode.element( null, "font" )
			.attribute( null, "name", GLOBAL.editFont.name )
			.attribute( null, "size", GLOBAL.editFont.size )
			.attribute( null, "bold", GLOBAL.editFont.bold )
			.attribute( null, "italic", GLOBAL.editFont.italic )
			.attribute( null, "underline", GLOBAL.editFont.underline )
			.attribute( null, "forecolor", GLOBAL.editFont.foreColor )
			.attribute( null, "backcolor", GLOBAL.editFont.backColor );
			+/
			editorNode.element( null, "font" )
			.attribute( null, "Default", GLOBAL.fonts[0].fontString )
			.attribute( null, "Document", GLOBAL.fonts[1].fontString )
			.attribute( null, "Leftside", GLOBAL.fonts[2].fontString )
			.attribute( null, "Filelist", GLOBAL.fonts[3].fontString )
			.attribute( null, "Project", GLOBAL.fonts[4].fontString )
			.attribute( null, "Outline", GLOBAL.fonts[5].fontString )
			.attribute( null, "Bottom", GLOBAL.fonts[6].fontString )
			.attribute( null, "Output", GLOBAL.fonts[7].fontString )
			.attribute( null, "Search", GLOBAL.fonts[8].fontString )
			.attribute( null, "Debugger", GLOBAL.fonts[9].fontString )
			.attribute( null, "Annotation", GLOBAL.fonts[10].fontString )
			.attribute( null, "Manual", GLOBAL.fonts[11].fontString )
			.attribute( null, "StatusBar", GLOBAL.fonts[12].fontString );

			//<color caretLine="255 255 0" cursor="0 0 0" selectionFore="255 255 255" selectionBack="0 0 255" linenumFore="0 0 0" linenumBack="200 200 200" fold="200 208 208"></color>
			editorNode.element( null, "color" )
			.attribute( null, "keyword0", GLOBAL.editColor.keyWord[0].toDString )
			.attribute( null, "keyword1", GLOBAL.editColor.keyWord[1].toDString )
			.attribute( null, "keyword2", GLOBAL.editColor.keyWord[2].toDString )
			.attribute( null, "keyword3", GLOBAL.editColor.keyWord[3].toDString )		
			.attribute( null, "template", GLOBAL.colorTemplate.toDString )
			.attribute( null, "caretLine", GLOBAL.editColor.caretLine.toDString )
			.attribute( null, "cursor", GLOBAL.editColor.cursor.toDString )
			.attribute( null, "selectionFore", GLOBAL.editColor.selectionFore.toDString )
			.attribute( null, "selectionBack", GLOBAL.editColor.selectionBack.toDString )
			.attribute( null, "linenumFore", GLOBAL.editColor.linenumFore.toDString )
			.attribute( null, "linenumBack", GLOBAL.editColor.linenumBack.toDString )
			.attribute( null, "fold", GLOBAL.editColor.fold.toDString )
			.attribute( null, "selAlpha", GLOBAL.editColor.selAlpha.toDString )
			.attribute( null, "currentword", GLOBAL.editColor.currentWord.toDString )
			.attribute( null, "currentwordAlpha", GLOBAL.editColor.currentWordAlpha.toDString )
			.attribute( null, "braceFore", GLOBAL.editColor.braceFore.toDString )
			.attribute( null, "braceBack", GLOBAL.editColor.braceBack.toDString )		
			.attribute( null, "errorFore", GLOBAL.editColor.errorFore.toDString )
			.attribute( null, "errorBack", GLOBAL.editColor.errorBack.toDString )
			.attribute( null, "warningFore", GLOBAL.editColor.warningFore.toDString )
			.attribute( null, "warningBack", GLOBAL.editColor.warringBack.toDString )
			.attribute( null, "manualFore", GLOBAL.editColor.manualFore.toDString )
			.attribute( null, "manualBack", GLOBAL.editColor.manualBack.toDString )
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
			.attribute( null, "maker0", GLOBAL.editColor.maker[0].toDString )
			.attribute( null, "maker1", GLOBAL.editColor.maker[1].toDString )
			.attribute( null, "maker2", GLOBAL.editColor.maker[2].toDString )
			.attribute( null, "maker3", GLOBAL.editColor.maker[3].toDString );
			
			

			//<shortkeys find="C+++F" findinfile="C+S++F" findnext="+++F3" findprev="C+++F3" gotoline="C+++G" undo="C+++Z" redo="C+++X" defintion="++A+G" quickrun="+S++F5" run="+++F5" build="+++F6" outlinewindow="+++F12" messagewindow="+++F11"/>
			editorNode.element( null, "shortkeys" )
			.attribute( null, "find", convertShortKeyValue2String( GLOBAL.shortKeys[0].keyValue ) )
			.attribute( null, "findinfile", convertShortKeyValue2String( GLOBAL.shortKeys[1].keyValue ) )
			.attribute( null, "findnext", convertShortKeyValue2String( GLOBAL.shortKeys[2].keyValue ) )
			.attribute( null, "findprev", convertShortKeyValue2String( GLOBAL.shortKeys[3].keyValue ) )
			.attribute( null, "gotoline", convertShortKeyValue2String( GLOBAL.shortKeys[4].keyValue ) )
			.attribute( null, "undo", convertShortKeyValue2String( GLOBAL.shortKeys[5].keyValue ) )
			.attribute( null, "redo", convertShortKeyValue2String( GLOBAL.shortKeys[6].keyValue ) )
			.attribute( null, "defintion", convertShortKeyValue2String( GLOBAL.shortKeys[7].keyValue ) )
			.attribute( null, "quickrun", convertShortKeyValue2String( GLOBAL.shortKeys[8].keyValue ) )
			.attribute( null, "run", convertShortKeyValue2String( GLOBAL.shortKeys[9].keyValue ) )
			.attribute( null, "build", convertShortKeyValue2String( GLOBAL.shortKeys[10].keyValue ) )
			.attribute( null, "outlinewindow", convertShortKeyValue2String( GLOBAL.shortKeys[11].keyValue ) )
			.attribute( null, "messagewindow", convertShortKeyValue2String( GLOBAL.shortKeys[12].keyValue ) )
			.attribute( null, "showtype", convertShortKeyValue2String( GLOBAL.shortKeys[13].keyValue ) )
			.attribute( null, "reparse", convertShortKeyValue2String( GLOBAL.shortKeys[14].keyValue ) )
			.attribute( null, "save", convertShortKeyValue2String( GLOBAL.shortKeys[15].keyValue ) )
			.attribute( null, "saveall", convertShortKeyValue2String( GLOBAL.shortKeys[16].keyValue ) )
			.attribute( null, "close", convertShortKeyValue2String( GLOBAL.shortKeys[17].keyValue ) )
			.attribute( null, "nexttab", convertShortKeyValue2String( GLOBAL.shortKeys[18].keyValue ) )
			.attribute( null, "prevtab", convertShortKeyValue2String( GLOBAL.shortKeys[19].keyValue ) )
			.attribute( null, "newtab", convertShortKeyValue2String( GLOBAL.shortKeys[20].keyValue ) )
			.attribute( null, "autocomplete", convertShortKeyValue2String( GLOBAL.shortKeys[21].keyValue ) )
			.attribute( null, "compilerun", convertShortKeyValue2String( GLOBAL.shortKeys[22].keyValue ) )
			.attribute( null, "comment", convertShortKeyValue2String( GLOBAL.shortKeys[23].keyValue ) )
			.attribute( null, "backdefinition", convertShortKeyValue2String( GLOBAL.shortKeys[24].keyValue ) )
			
			.attribute( null, "customtool1", convertShortKeyValue2String( GLOBAL.shortKeys[25].keyValue ) )
			.attribute( null, "customtool2", convertShortKeyValue2String( GLOBAL.shortKeys[26].keyValue ) )
			.attribute( null, "customtool3", convertShortKeyValue2String( GLOBAL.shortKeys[27].keyValue ) )
			.attribute( null, "customtool4", convertShortKeyValue2String( GLOBAL.shortKeys[28].keyValue ) )
			.attribute( null, "customtool5", convertShortKeyValue2String( GLOBAL.shortKeys[29].keyValue ) )
			.attribute( null, "customtool6", convertShortKeyValue2String( GLOBAL.shortKeys[30].keyValue ) )
			.attribute( null, "customtool7", convertShortKeyValue2String( GLOBAL.shortKeys[31].keyValue ) )
			.attribute( null, "customtool8", convertShortKeyValue2String( GLOBAL.shortKeys[32].keyValue ) )
			.attribute( null, "customtool9", convertShortKeyValue2String( GLOBAL.shortKeys[33].keyValue ) )
			.attribute( null, "procedure", convertShortKeyValue2String( GLOBAL.shortKeys[34].keyValue ) );
			
			/*
			<buildtools>
				<compilerpath>D:\CodingPark\FreeBASIC-1.02.1-win32\fbc.exe</compilerpath>
				<debuggerpath>D:\CodingPark\FreeBASIC-1.02.1-win32\bin\win32\gdb.exe</debuggerpath>
			</buildtools>  
			*/
			auto buildtoolsNode = configNode.element( null, "buildtools" );
			buildtoolsNode.element( null, "compilerpath", GLOBAL.compilerFullPath.toDString );
			buildtoolsNode.element( null, "x64compilerpath", GLOBAL.x64compilerFullPath.toDString );
			buildtoolsNode.element( null, "debuggerpath", GLOBAL.debuggerFullPath.toDString );
			buildtoolsNode.element( null, "x64debuggerpath", GLOBAL.x64debuggerFullPath.toDString );
			buildtoolsNode.element( null, "defaultoption", GLOBAL.defaultOption.toDString );
			buildtoolsNode.element( null, "resultwindow", GLOBAL.compilerWindow );
			buildtoolsNode.element( null, "annotation", GLOBAL.compilerAnootation );
			buildtoolsNode.element( null, "delexistexe", GLOBAL.delExistExe );

			/*
			<parser>
				<parsertrigger>3</parsertrigger>
			</parser>  
			*/
			auto parserNode = configNode.element( null, "parser" );

			parserNode.element( null, "enablekeywordcomplete", GLOBAL.enableKeywordComplete );
			parserNode.element( null, "enableparser", GLOBAL.enableParser );
			parserNode.element( null, "parsertrigger", Integer.toString( GLOBAL.autoCompletionTriggerWordCount ) );
			parserNode.element( null, "showfunctiontitle", GLOBAL.showFunctionTitle );
			parserNode.element( null, "widthfunctiontitle", GLOBAL.widthFunctionTitle.toDString );
			parserNode.element( null, "showtypewithparams", GLOBAL.showTypeWithParams );
			parserNode.element( null, "includelevel", Integer.toString( GLOBAL.includeLevel ) );
			parserNode.element( null, "ignorecase", GLOBAL.toggleIgnoreCase );
			parserNode.element( null, "caseinsensitive", GLOBAL.toggleCaseInsensitive );
			parserNode.element( null, "showlisttype", GLOBAL.toggleShowListType );
			parserNode.element( null, "showallmember", GLOBAL.toggleShowAllMember );
			parserNode.element( null, "livelevel", Integer.toString( GLOBAL.liveLevel ) );
			parserNode.element( null, "updateoutlinelive", GLOBAL.toggleUpdateOutlineLive );
			parserNode.element( null, "keywordcase", Integer.toString( GLOBAL.keywordCase ) );
			
			/*
			<manual>
				<manualpath>manual/index00.html</manualpath>
			</manual>  
			*/
			auto manualNode = configNode.element( null, "manual" );
			manualNode.element( null, "manualpath", GLOBAL.manualPath.toDString );
			manualNode.element( null, "manualusing", GLOBAL.toggleUseManual );
			manualNode.element( null, "manualdefinition", GLOBAL.toggleManualDefinition );
			manualNode.element( null, "manualshowtype", GLOBAL.toggleManualShowType );

			/*
			<recentFiles>
				<name>~~~</name>
				<name>~~~</name>
			</recentFiles>  
			*/
			auto recentFilesNode = configNode.element( null, "recentFiles" );
			for( int i = 0; i < GLOBAL.recentFiles.length; ++i )
			{
				recentFilesNode.element( null, "name", GLOBAL.recentFiles[i].toDString );
			}

			/*
			<recentProjects>
				<name>~~~</name>
				<name>~~~</name>
			</recentProjects>  
			*/
			auto recentNode = configNode.element( null, "recentProjects" );
			for( int i = 0; i < GLOBAL.recentProjects.length; ++i )
			{
				recentNode.element( null, "name", GLOBAL.recentProjects[i].toDString );
			}

			/*
			<compileOptionLists>
				<name>-E</name>
				<name>-C</name>
				<name>-c</name>
			</compileOptionLists>
			*/
			auto optionsNode = configNode.element( null, "recentOptions" );
			foreach( char[] s; GLOBAL.recentOptions )
				optionsNode.element( null, "name", s );

			auto argsNode = configNode.element( null, "recentArgs" );
			foreach( IupString s; GLOBAL.recentArgs )
				argsNode.element( null, "name", s.toDString );		
			
			auto print = new DocPrinter!(char);
			actionManager.FileAction.saveFile( "settings/editorSettings.xml", print.print( doc ) );
			saveINI();
		}
		catch( Exception e )
		{
			IupMessage( "Save editorSettings.xml Error", toStringz( e.toString ) );
			saveINI( "settings/exception_editorSettings.ini" );
		}
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

			// toggle
			doc ~= setINILineData( "[toggle]");
			doc ~= setINILineData( "LineMargin", GLOBAL.editorSetting00.LineMargin );
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
			doc ~= setINILineData( "TabWidth", GLOBAL.editorSetting00.TabWidth );
			doc ~= setINILineData( "ColumnEdge", GLOBAL.editorSetting00.ColumnEdge );
			doc ~= setINILineData( "EolType", GLOBAL.editorSetting00.EolType );
			doc ~= setINILineData( "ColorOutline", GLOBAL.editorSetting00.ColorOutline );
			doc ~= setINILineData( "Message", GLOBAL.editorSetting00.Message );
			doc ~= setINILineData( "BoldKeyword", GLOBAL.editorSetting00.BoldKeyword );
			doc ~= setINILineData( "BraceMatchHighlight", GLOBAL.editorSetting00.BraceMatchHighlight );
			doc ~= setINILineData( "BraceMatchDoubleSidePos", GLOBAL.editorSetting00.BraceMatchDoubleSidePos );
			doc ~= setINILineData( "MultiSelection", GLOBAL.editorSetting00.MultiSelection );
			doc ~= setINILineData( "LoadPrevDoc", GLOBAL.editorSetting00.LoadPrevDoc );
			doc ~= setINILineData( "HighlightCurrentWord", GLOBAL.editorSetting00.HighlightCurrentWord );
			
			
			
			if( fromStringz( IupGetAttribute( GLOBAL.menuOutlineWindow, "VALUE" ) ) == "OFF" )
				GLOBAL.editorSetting01.ExplorerSplit = Integer.toString( GLOBAL.explorerSplit_value );
			else
				GLOBAL.editorSetting01.ExplorerSplit = fromStringz( IupGetAttribute( GLOBAL.explorerSplit, "VALUE" ) ).dup;
			
			if( fromStringz( IupGetAttribute( GLOBAL.menuMessageWindow, "VALUE" ) ) == "OFF" )
				GLOBAL.editorSetting01.MessageSplit = Integer.toString( GLOBAL.messageSplit_value ).dup;
			else
				GLOBAL.editorSetting01.MessageSplit = fromStringz( IupGetAttribute( GLOBAL.messageSplit, "VALUE" ) ).dup;
			
			
			GLOBAL.editorSetting01.FileListSplit = fromStringz( IupGetAttribute( GLOBAL.fileListSplit, "VALUE" ) ).dup;
			GLOBAL.editorSetting01.OutlineWindow = fromStringz( IupGetAttribute( GLOBAL.menuOutlineWindow, "VALUE" ) ).dup;
			GLOBAL.editorSetting01.MessageWindow = fromStringz( IupGetAttribute( GLOBAL.menuMessageWindow, "VALUE" ) ).dup;

			// size
			doc ~= setINILineData( "[size]");
			if( GLOBAL.editorSetting01.PLACEMENT == "MINIMIZED" ) doc ~= setINILineData( "PLACEMENT", "NORMAL" ); else doc ~= setINILineData( "PLACEMENT", GLOBAL.editorSetting01.PLACEMENT );
			doc ~= setINILineData( "RASTERSIZE", GLOBAL.editorSetting01.RASTERSIZE );
			doc ~= setINILineData( "ExplorerSplit", GLOBAL.editorSetting01.ExplorerSplit );
			doc ~= setINILineData( "MessageSplit", GLOBAL.editorSetting01.MessageSplit );
			doc ~= setINILineData( "FileListSplit", GLOBAL.editorSetting01.FileListSplit );
			doc ~= setINILineData( "OutlineWindow", GLOBAL.editorSetting01.OutlineWindow );
			doc ~= setINILineData( "MessageWindow", GLOBAL.editorSetting01.MessageWindow );
			
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
			doc ~= setINILineData( "Manual", GLOBAL.fonts[11].fontString );
			doc ~= setINILineData( "StatusBar", GLOBAL.fonts[12].fontString );

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
			doc ~= setINILineData( "manualFore", GLOBAL.editColor.manualFore.toDString );
			doc ~= setINILineData( "manualBack", GLOBAL.editColor.manualBack.toDString );
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
			
			// shortkeys
			doc ~= setINILineData( "[shortkeys]");
			doc ~= setINILineData( "find", convertShortKeyValue2String( GLOBAL.shortKeys[0].keyValue ) );
			doc ~= setINILineData( "findinfile", convertShortKeyValue2String( GLOBAL.shortKeys[1].keyValue ) );
			doc ~= setINILineData( "findnext", convertShortKeyValue2String( GLOBAL.shortKeys[2].keyValue ) );
			doc ~= setINILineData( "findprev", convertShortKeyValue2String( GLOBAL.shortKeys[3].keyValue ) );
			doc ~= setINILineData( "gotoline", convertShortKeyValue2String( GLOBAL.shortKeys[4].keyValue ) );
			doc ~= setINILineData( "undo", convertShortKeyValue2String( GLOBAL.shortKeys[5].keyValue ) );
			doc ~= setINILineData( "redo", convertShortKeyValue2String( GLOBAL.shortKeys[6].keyValue ) );
			doc ~= setINILineData( "defintion", convertShortKeyValue2String( GLOBAL.shortKeys[7].keyValue ) );
			doc ~= setINILineData( "quickrun", convertShortKeyValue2String( GLOBAL.shortKeys[8].keyValue ) );
			doc ~= setINILineData( "run", convertShortKeyValue2String( GLOBAL.shortKeys[9].keyValue ) );
			doc ~= setINILineData( "build", convertShortKeyValue2String( GLOBAL.shortKeys[10].keyValue ) );
			doc ~= setINILineData( "outlinewindow", convertShortKeyValue2String( GLOBAL.shortKeys[11].keyValue ) );
			doc ~= setINILineData( "messagewindow", convertShortKeyValue2String( GLOBAL.shortKeys[12].keyValue ) );
			doc ~= setINILineData( "showtype", convertShortKeyValue2String( GLOBAL.shortKeys[13].keyValue ) );
			doc ~= setINILineData( "reparse", convertShortKeyValue2String( GLOBAL.shortKeys[14].keyValue ) );
			doc ~= setINILineData( "save", convertShortKeyValue2String( GLOBAL.shortKeys[15].keyValue ) );
			doc ~= setINILineData( "saveall", convertShortKeyValue2String( GLOBAL.shortKeys[16].keyValue ) );
			doc ~= setINILineData( "close", convertShortKeyValue2String( GLOBAL.shortKeys[17].keyValue ) );
			doc ~= setINILineData( "nexttab", convertShortKeyValue2String( GLOBAL.shortKeys[18].keyValue ) );
			doc ~= setINILineData( "prevtab", convertShortKeyValue2String( GLOBAL.shortKeys[19].keyValue ) );
			doc ~= setINILineData( "newtab", convertShortKeyValue2String( GLOBAL.shortKeys[20].keyValue ) );
			doc ~= setINILineData( "autocomplete", convertShortKeyValue2String( GLOBAL.shortKeys[21].keyValue ) );
			doc ~= setINILineData( "compilerun", convertShortKeyValue2String( GLOBAL.shortKeys[22].keyValue ) );
			doc ~= setINILineData( "comment", convertShortKeyValue2String( GLOBAL.shortKeys[23].keyValue ) );
			doc ~= setINILineData( "backdefinition", convertShortKeyValue2String( GLOBAL.shortKeys[24].keyValue ) );
			
			doc ~= setINILineData( "customtool1", convertShortKeyValue2String( GLOBAL.shortKeys[25].keyValue ) );
			doc ~= setINILineData( "customtool2", convertShortKeyValue2String( GLOBAL.shortKeys[26].keyValue ) );
			doc ~= setINILineData( "customtool3", convertShortKeyValue2String( GLOBAL.shortKeys[27].keyValue ) );
			doc ~= setINILineData( "customtool4", convertShortKeyValue2String( GLOBAL.shortKeys[28].keyValue ) );
			doc ~= setINILineData( "customtool5", convertShortKeyValue2String( GLOBAL.shortKeys[29].keyValue ) );
			doc ~= setINILineData( "customtool6", convertShortKeyValue2String( GLOBAL.shortKeys[30].keyValue ) );
			doc ~= setINILineData( "customtool7", convertShortKeyValue2String( GLOBAL.shortKeys[31].keyValue ) );
			doc ~= setINILineData( "customtool8", convertShortKeyValue2String( GLOBAL.shortKeys[32].keyValue ) );
			doc ~= setINILineData( "customtool9", convertShortKeyValue2String( GLOBAL.shortKeys[33].keyValue ) );
			doc ~= setINILineData( "procedure", convertShortKeyValue2String( GLOBAL.shortKeys[34].keyValue ) );
			
			// buildtools
			doc ~= setINILineData( "[buildtools]");
			doc ~= setINILineData( "compilerpath", GLOBAL.compilerFullPath.toDString );
			doc ~= setINILineData( "x64compilerpath", GLOBAL.x64compilerFullPath.toDString );
			doc ~= setINILineData( "debuggerpath", GLOBAL.debuggerFullPath.toDString );
			doc ~= setINILineData( "x64debuggerpath", GLOBAL.x64debuggerFullPath.toDString );
			doc ~= setINILineData( "defaultoption", GLOBAL.defaultOption.toDString );
			doc ~= setINILineData( "resultwindow", GLOBAL.compilerWindow );
			doc ~= setINILineData( "annotation", GLOBAL.compilerAnootation );
			doc ~= setINILineData( "delexistexe", GLOBAL.delExistExe );
			doc ~= setINILineData( "consoleexe", GLOBAL.consoleExe );

			// parser
			doc ~= setINILineData( "[parser]");
			doc ~= setINILineData( "enablekeywordcomplete", GLOBAL.enableKeywordComplete );
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
			doc ~= setINILineData( "livelevel", Integer.toString( GLOBAL.liveLevel ) );
			doc ~= setINILineData( "updateoutlinelive", GLOBAL.toggleUpdateOutlineLive );
			doc ~= setINILineData( "keywordcase", Integer.toString( GLOBAL.keywordCase ) );
			
			// manual
			doc ~= setINILineData( "[manual]");
			doc ~= setINILineData( "manualpath", GLOBAL.manualPath.toDString );
			doc ~= setINILineData( "manualusing", GLOBAL.toggleUseManual );
			doc ~= setINILineData( "manualdefinition", GLOBAL.toggleManualDefinition );
			doc ~= setINILineData( "manualshowtype", GLOBAL.toggleManualShowType );

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
			for( int i = 0; i < GLOBAL.recentOptions.length; ++i )
				doc ~= setINILineData( "name", GLOBAL.recentOptions[i] );

			// recentProjects
			doc ~= setINILineData( "[recentArgs]" );
			for( int i = 0; i < GLOBAL.recentArgs.length; ++i )
				doc ~= setINILineData( "name", GLOBAL.recentArgs[i] );
				
			// prevLoadDoc
			doc ~= setINILineData( "[prevDocs]" );
			for( int i = 0; i < GLOBAL.prevDoc.length; ++i )
				doc ~= setINILineData( "name", GLOBAL.prevDoc[i] );
			
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
				load(); // load xml
				/+
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
				if( lineData.length )
				{
					if( lineData[0] == '[' )
					{
						int assignPos = Util.rindex( lineData, "=" );
						if( assignPos < lineData.length )
						{
							blockText = lineData[0..assignPos];
							continue;
						}
					}
				}
				else
				{
					continue;
				}
				
				// Get Line Data
				getINILineData( lineData, left, right );
				
				switch( blockText )
				{
					case "[editor]":
						switch( left )
						{
							case "lexer":			GLOBAL.lexer = right;			break;
							case "keyword0":		GLOBAL.KEYWORDS[0] = right;		break;
							case "keyword1":		GLOBAL.KEYWORDS[1] = right;		break;
							case "keyword2":		GLOBAL.KEYWORDS[2] = right;		break;
							case "keyword3":		GLOBAL.KEYWORDS[3] = right;		break;
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
							case "TabWidth":				GLOBAL.editorSetting00.TabWidth = right;				break;
					
							case "ColumnEdge":				GLOBAL.editorSetting00.ColumnEdge = right;				break;
							case "EolType":					GLOBAL.editorSetting00.EolType = right;					break;
							case "ColorOutline":			GLOBAL.editorSetting00.ColorOutline = right;			break;
							case "Message":					GLOBAL.editorSetting00.Message = right;					break;
							case "BoldKeyword":				GLOBAL.editorSetting00.BoldKeyword = right;				break;
							case "BraceMatchHighlight":		GLOBAL.editorSetting00.BraceMatchHighlight = right;		break;
							case "BraceMatchDoubleSidePos":	GLOBAL.editorSetting00.BraceMatchDoubleSidePos = right;	break;
							case "MultiSelection":			GLOBAL.editorSetting00.MultiSelection = right;			break;
							case "LoadPrevDoc":				GLOBAL.editorSetting00.LoadPrevDoc = right;				break;
							case "HighlightCurrentWord":	GLOBAL.editorSetting00.HighlightCurrentWord = right;	break;
							default:
						}
						break;
						
					case "[size]":
						switch( left )
						{
							case "PLACEMENT":	 			GLOBAL.editorSetting01.PLACEMENT = right;				break;
							case "RASTERSIZE":				GLOBAL.editorSetting01.RASTERSIZE = right;				break;
							case "ExplorerSplit":			GLOBAL.editorSetting01.ExplorerSplit = right;			break;
							case "MessageSplit":			GLOBAL.editorSetting01.MessageSplit = right;			break;
							case "FileListSplit":			GLOBAL.editorSetting01.FileListSplit = right;			break;
							case "OutlineWindow":			GLOBAL.editorSetting01.OutlineWindow = right;			break;
							case "MessageWindow":			GLOBAL.editorSetting01.MessageWindow = right;			break;
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
							case "Manual":					GLOBAL.fonts[11].fontString = right;					break;
							case "StatusBar":				GLOBAL.fonts[12].fontString = right;					break;
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
							case "manualFore":				GLOBAL.editColor.manualFore = right;					break;
							case "manualBack":				GLOBAL.editColor.manualBack = right;					break;
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
							default:
						}
						break;

					case "[shortkeys]":
						char[]	title;
						int		index;
					
						switch( left )
						{
							case "find":					index = 0; title = GLOBAL.languageItems["sc_findreplace"].toDString();				break;
							case "findinfile":				index = 1; title = GLOBAL.languageItems["sc_findreplacefiles"].toDString();			break;
							case "findnext":				index = 2; title = GLOBAL.languageItems["sc_findnext"].toDString();					break;
							case "findprev":				index = 3; title = GLOBAL.languageItems["sc_findprev"].toDString();					break;
							case "gotoline":				index = 4; title = GLOBAL.languageItems["sc_goto"].toDString();						break;
							case "undo":					index = 5; title = GLOBAL.languageItems["sc_undo"].toDString();						break;
							case "redo":					index = 6; title = GLOBAL.languageItems["sc_redo"].toDString();						break;
							case "defintion":				index = 7; title = GLOBAL.languageItems["sc_gotodef"].toDString();					break;
							case "quickrun":				index = 8; title = GLOBAL.languageItems["sc_quickrun"].toDString();					break;
							case "run":						index = 9; title = GLOBAL.languageItems["sc_run"].toDString();						break;
							case "build":					index =10; title = GLOBAL.languageItems["sc_findreplace"].toDString();				break;
							case "outlinewindow":			index =11; title = GLOBAL.languageItems["sc_leftwindow"].toDString();				break;
							case "messagewindow":			index =12; title = GLOBAL.languageItems["sc_bottomwindow"].toDString();				break;
							case "showtype":				index =13; title = GLOBAL.languageItems["sc_showtype"].toDString();					break;
							case "reparse":					index =14; title = GLOBAL.languageItems["sc_reparse"].toDString();					break;
							case "save":					index =15; title = GLOBAL.languageItems["sc_save"].toDString();						break;
							case "saveall":					index =16; title = GLOBAL.languageItems["sc_saveall"].toDString();					break;
							case "close":					index =17; title = GLOBAL.languageItems["sc_close"].toDString();					break;
							case "nexttab":					index =18; title = GLOBAL.languageItems["sc_nexttab"].toDString();					break;
							case "prevtab":					index =19; title = GLOBAL.languageItems["sc_prevtab"].toDString();					break;
							case "newtab":					index =20; title = GLOBAL.languageItems["sc_newtab"].toDString();					break;
							case "autocomplete":			index =21; title = GLOBAL.languageItems["sc_autocomplete"].toDString();				break;
							case "compilerun":				index =22; title = GLOBAL.languageItems["sc_compilerun"].toDString();				break;
							case "comment":					index =23; title = GLOBAL.languageItems["sc_comment"].toDString();					break;
							case "backdefinition":			index =24; title = GLOBAL.languageItems["sc_backdefinition"].toDString();			break;
							case "procedure":				index =34; title = GLOBAL.languageItems["sc_procedure"].toDString();				break;
							case "customtool1", "customtool2", "customtool3", "customtool4", "customtool5", "customtool6", "customtool7", "customtool8", "customtool9":
								index = Integer.atoi( left[$-1..$] ) + 24;
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
							case "compilerpath":			GLOBAL.compilerFullPath = right;						break;
							case "x64compilerpath":			GLOBAL.x64compilerFullPath = right;						break;
							case "debuggerpath":			GLOBAL.debuggerFullPath = right;						break;
							case "x64debuggerpath":			GLOBAL.x64debuggerFullPath = right;						break;
							case "defaultoption":			GLOBAL.defaultOption = right;							break;
							case "resultwindow":			GLOBAL.compilerWindow = right;							break;
							case "annotation":				GLOBAL.compilerAnootation = right;						break;
							case "delexistexe":				GLOBAL.delExistExe = right;								break;
							case "consoleexe":				GLOBAL.consoleExe = right;								break;
							default:
						}
						break;
						
					case "[parser]":
						switch( left )
						{
							case "enablekeywordcomplete":	GLOBAL.enableKeywordComplete = right;							break;
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
							case "manualdefinition":		GLOBAL.toggleManualDefinition = right;							break;
							case "manualshowtype":			GLOBAL.toggleManualShowType = right;							break;
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
						if( left == "name" ) GLOBAL.recentOptions ~= right;
						break;

					case "[recentArgs]":
						if( left == "name" ) GLOBAL.recentArgs ~= right;
						break;

					case "[prevDocs]":
						if( left == "name" ) GLOBAL.prevDoc ~= right;
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
	}

	static void load()
	{
		try
		{
			// Loading Key Word...
			scope file = new UnicodeFile!(char)( "settings/editorSettings.xml", Encoding.Unknown );
			//scope file  = cast(char[]) File.get( "settings\\editorSettings.xml" );

			scope doc = new Document!( char );
			doc.parse( file.read );

			auto root = doc.elements;
			
			auto result = root.query.descendant("lexer");
			foreach( e; result )
			{
				GLOBAL.lexer = e.value;
			}
			if( !GLOBAL.lexer.length ) GLOBAL.lexer = "freebasic";
			
			result = root.query.descendant("language");
			foreach( e; result )
			{
				GLOBAL.language = e.value;
			}
			
			result = root.query.descendant("keywords").attribute("value");
			int count;
			foreach( e; result )
			{
				GLOBAL.KEYWORDS[count++] = e.value;
			}

			result = root.query.descendant("customtools").attribute("name");
			int id = 1;
			foreach( e; result )
			{
				GLOBAL.customTools[id++].name = e.value;
			}
			result = root.query.descendant("customtools").attribute("dir");
			id = 1;
			foreach( e; result )
			{
				GLOBAL.customTools[id++].dir = e.value;
			}
			result = root.query.descendant("customtools").attribute("args");
			id = 1;
			foreach( e; result )
			{
				GLOBAL.customTools[id++].args = e.value;
			}
			
			result = root.query.descendant("compilerpath");
			foreach( e; result )
			{
				GLOBAL.compilerFullPath = e.value;
			}
			
			result = root.query.descendant("x64compilerpath");
			foreach( e; result )
			{
				GLOBAL.x64compilerFullPath = e.value;
			}				

			result = root.query.descendant("debuggerpath");
			foreach( e; result )
			{
				GLOBAL.debuggerFullPath = e.value;
			}
			
			result = root.query.descendant("x64debuggerpath");
			foreach( e; result )
			{
				GLOBAL.x64debuggerFullPath = e.value;
			}			

			result = root.query.descendant("defaultoption");
			foreach( e; result )
			{
				GLOBAL.defaultOption = e.value;
			}

			result = root.query.descendant("resultwindow");
			foreach( e; result )
			{
				GLOBAL.compilerWindow = e.value;
			}

			result = root.query.descendant("annotation");
			foreach( e; result )
			{
				GLOBAL.compilerAnootation = e.value;
			}
			
			result = root.query.descendant("delexistexe");
			foreach( e; result )
			{
				GLOBAL.delExistExe = e.value;
			}

			// Parser
			result = root.query.descendant("enablekeywordcomplete");
			foreach( e; result )
			{
				GLOBAL.enableKeywordComplete = e.value;
			}
			result = root.query.descendant("enableparser");
			foreach( e; result )
			{
				GLOBAL.enableParser = e.value;
			}
			result = root.query.descendant("parsertrigger");
			foreach( e; result )
			{
				GLOBAL.autoCompletionTriggerWordCount = Integer.atoi( e.value );
			}
			result = root.query.descendant("showfunctiontitle");
			foreach( e; result )
			{
				GLOBAL.showFunctionTitle = e.value;
			}
			result = root.query.descendant("widthfunctiontitle");
			foreach( e; result )
			{
				GLOBAL.widthFunctionTitle = e.value;
			}			
			result = root.query.descendant("showtypewithparams");
			foreach( e; result )
			{
				GLOBAL.showTypeWithParams = e.value;
			}
			result = root.query.descendant("includelevel");
			foreach( e; result )
			{
				GLOBAL.includeLevel = Integer.atoi( e.value );
			}
			if( GLOBAL.includeLevel < 0 ) GLOBAL.includeLevel = 0;
			result = root.query.descendant("ignorecase");
			foreach( e; result )
			{
				GLOBAL.toggleIgnoreCase = e.value;
			}
			result = root.query.descendant("caseinsensitive");
			foreach( e; result )
			{
				GLOBAL.toggleCaseInsensitive = e.value;
			}			
			result = root.query.descendant("showlisttype");
			foreach( e; result )
			{
				GLOBAL.toggleShowListType = e.value;
			}	
			result = root.query.descendant("showallmember");
			foreach( e; result )
			{
				GLOBAL.toggleShowAllMember = e.value;
			}
			result = root.query.descendant("livelevel");
			foreach( e; result )
			{
				GLOBAL.liveLevel = Integer.atoi( e.value );
			}
			result = root.query.descendant("updateoutlinelive");
			foreach( e; result )
			{
				GLOBAL.toggleUpdateOutlineLive = e.value;
			}
			result = root.query.descendant("keywordcase");
			foreach( e; result )
			{
				GLOBAL.keywordCase = Integer.atoi( e.value );
			}
			
			// Manual
			result = root.query.descendant("manualpath");
			foreach( e; result )
			{
				GLOBAL.manualPath = e.value;
			}
			result = root.query.descendant("manualusing");
			foreach( e; result )
			{
				GLOBAL.toggleUseManual = e.value;
			}			
			result = root.query.descendant("manualdefinition");
			foreach( e; result )
			{
				GLOBAL.toggleManualDefinition = e.value;
			}			
			result = root.query.descendant("manualshowtype");
			foreach( e; result )
			{
				GLOBAL.toggleManualShowType = e.value;
			}			
			
			
		
			result = root.query.descendant("recentFiles").descendant("name");
			foreach( e; result )
			{
				auto rf = new IupString( cast(char[]) e.value );
				GLOBAL.recentFiles ~= rf;
			}

			result = root.query.descendant("recentProjects").descendant("name");
			foreach( e; result )
			{
				auto rp = new IupString( cast(char[]) e.value );
				GLOBAL.recentProjects ~= rp;
			}

			result = root.query.descendant("recentOptions").descendant("name");
			foreach( e; result )
			{
				//auto ro = new IupString( cast(char[]) e.value );
				GLOBAL.recentOptions ~= e.value;
			}

			result = root.query.descendant("recentArgs").descendant("name");
			foreach( e; result )
			{
				//auto ra = new IupString( cast(char[]) e.value );
				GLOBAL.recentArgs ~= e.value;
			}


			result = root.query.descendant("toggle00").attribute("LineMargin");
			foreach( e; result ) GLOBAL.editorSetting00.LineMargin = e.value;

			result = root.query.descendant("toggle00").attribute("BookmarkMargin");
			foreach( e; result ) GLOBAL.editorSetting00.BookmarkMargin = e.value;

			result = root.query.descendant("toggle00").attribute("FoldMargin");
			foreach( e; result ) GLOBAL.editorSetting00.FoldMargin = e.value;
			
			result = root.query.descendant("toggle00").attribute("IndentGuide");
			foreach( e; result ) GLOBAL.editorSetting00.IndentGuide = e.value;
			
			result = root.query.descendant("toggle00").attribute("CaretLine");
			foreach( e; result ) GLOBAL.editorSetting00.CaretLine = e.value;

			result = root.query.descendant("toggle00").attribute("WordWrap");
			foreach( e; result ) GLOBAL.editorSetting00.WordWrap = e.value;

			result = root.query.descendant("toggle00").attribute("TabUseingSpace");
			foreach( e; result ) GLOBAL.editorSetting00.TabUseingSpace = e.value;

			result = root.query.descendant("toggle00").attribute("AutoIndent");
			foreach( e; result ) GLOBAL.editorSetting00.AutoIndent = e.value;

			result = root.query.descendant("toggle00").attribute("ShowEOL");
			foreach( e; result ) GLOBAL.editorSetting00.ShowEOL = e.value;

			result = root.query.descendant("toggle00").attribute("ShowSpace");
			foreach( e; result ) GLOBAL.editorSetting00.ShowSpace = e.value;

			result = root.query.descendant("toggle00").attribute("AutoEnd");
			foreach( e; result ) GLOBAL.editorSetting00.AutoEnd = e.value;

			result = root.query.descendant("toggle00").attribute("TabWidth");
			foreach( e; result ) GLOBAL.editorSetting00.TabWidth = e.value;

			result = root.query.descendant("toggle00").attribute("ColumnEdge");
			foreach( e; result ) GLOBAL.editorSetting00.ColumnEdge = e.value;

			result = root.query.descendant("toggle00").attribute("EolType");
			foreach( e; result ) GLOBAL.editorSetting00.EolType = e.value;

			result = root.query.descendant("toggle00").attribute("ColorOutline");
			foreach( e; result ) GLOBAL.editorSetting00.ColorOutline = e.value;

			result = root.query.descendant("toggle00").attribute("Message");
			foreach( e; result ) GLOBAL.editorSetting00.Message = e.value;

			result = root.query.descendant("toggle00").attribute("BoldKeyword");
			foreach( e; result ) GLOBAL.editorSetting00.BoldKeyword = e.value;

			result = root.query.descendant("toggle00").attribute("BraceMatchHighlight");
			foreach( e; result ) GLOBAL.editorSetting00.BraceMatchHighlight = e.value;

			result = root.query.descendant("toggle00").attribute("BraceMatchDoubleSidePos");
			foreach( e; result ) GLOBAL.editorSetting00.BraceMatchDoubleSidePos = e.value;

			result = root.query.descendant("toggle00").attribute("MultiSelection");
			foreach( e; result ) GLOBAL.editorSetting00.MultiSelection = e.value;

			result = root.query.descendant("toggle00").attribute("LoadPrevDoc");
			foreach( e; result ) GLOBAL.editorSetting00.LoadPrevDoc = e.value;
			
			result = root.query.descendant("toggle00").attribute("HighlightCurrentWord");
			foreach( e; result ) GLOBAL.editorSetting00.HighlightCurrentWord = e.value;


			result = root.query.descendant("size01").attribute("PLACEMENT");
			foreach( e; result ) GLOBAL.editorSetting01.PLACEMENT = e.value;

			result = root.query.descendant("size01").attribute("RASTERSIZE");
			foreach( e; result ) GLOBAL.editorSetting01.RASTERSIZE = e.value;

			result = root.query.descendant("size01").attribute("ExplorerSplit");
			foreach( e; result ) GLOBAL.editorSetting01.ExplorerSplit = e.value;

			result = root.query.descendant("size01").attribute("MessageSplit");
			foreach( e; result ) GLOBAL.editorSetting01.MessageSplit = e.value;

			result = root.query.descendant("size01").attribute("FileListSplit");
			foreach( e; result ) GLOBAL.editorSetting01.FileListSplit = e.value;
			
			result = root.query.descendant("size01").attribute("OutlineWindow");
			foreach( e; result ) GLOBAL.editorSetting01.OutlineWindow = e.value;

			result = root.query.descendant("size01").attribute("MessageWindow");
			foreach( e; result ) GLOBAL.editorSetting01.MessageWindow = e.value;
			

			// Font
			//GLOBAL.fonts.length = 0;
			fontUint fu;
			version( Windows )
			{
				fu.fontString = "Courier New,9";
			}
			else
			{
				fu.fontString = "FreeMono,Bold 9";
			}

			fu.name = "default";
			GLOBAL.fonts[0] = fu;
			result = root.query.descendant("font").attribute( "Default" );
			foreach( e; result ) if( e.value.length ) GLOBAL.fonts[0].fontString = e.value;

			fu.name = "document";
			GLOBAL.fonts[1] = fu;
			result = root.query.descendant("font").attribute( "Document" );
			foreach( e; result ) if( e.value.length ) GLOBAL.fonts[1].fontString = e.value;
			
			fu.name = "leftside";
			GLOBAL.fonts[2] = fu;
			result = root.query.descendant("font").attribute( "Leftside" );
			foreach( e; result ) if( e.value.length ) GLOBAL.fonts[2].fontString = e.value;

			fu.name = "filelist";
			GLOBAL.fonts[3] = fu;
			result = root.query.descendant("font").attribute( "Filelist" );
			foreach( e; result ) if( e.value.length ) GLOBAL.fonts[3].fontString = e.value;

			fu.name = "caption_prj";
			GLOBAL.fonts[4] = fu;
			result = root.query.descendant("font").attribute( "Project" );
			foreach( e; result ) if( e.value.length ) GLOBAL.fonts[4].fontString = e.value;

			fu.name = "outline";
			GLOBAL.fonts[5] = fu;
			result = root.query.descendant("font").attribute( "Outline" );
			foreach( e; result ) if( e.value.length ) GLOBAL.fonts[5].fontString = e.value;
			
			fu.name = "bottom";
			GLOBAL.fonts[6] = fu;
			result = root.query.descendant("font").attribute( "Bottom" );
			foreach( e; result ) if( e.value.length ) GLOBAL.fonts[6].fontString = e.value;

			fu.name = "output";
			GLOBAL.fonts[7] = fu;
			result = root.query.descendant("font").attribute( "Output" );
			foreach( e; result ) if( e.value.length ) GLOBAL.fonts[7].fontString = e.value;

			fu.name = "search";
			GLOBAL.fonts[8] = fu;
			result = root.query.descendant("font").attribute( "Search" );
			foreach( e; result ) if( e.value.length ) GLOBAL.fonts[8].fontString = e.value;

			fu.name = "debug";
			GLOBAL.fonts[9] = fu;
			result = root.query.descendant("font").attribute( "Debugger" );
			foreach( e; result ) if( e.value.length ) GLOBAL.fonts[9].fontString = e.value;

			fu.name = "annotation";
			GLOBAL.fonts[10] = fu;
			result = root.query.descendant("font").attribute( "Annotation" );
			foreach( e; result ) if( e.value.length ) GLOBAL.fonts[10].fontString = e.value;
			
			fu.name = "manual";
			GLOBAL.fonts[11] = fu;
			result = root.query.descendant("font").attribute( "Manual" );
			foreach( e; result ) if( e.value.length ) GLOBAL.fonts[11].fontString = e.value;

			fu.name = "statusbar";
			GLOBAL.fonts[12] = fu;
			result = root.query.descendant("font").attribute( "StatusBar" );
			foreach( e; result ) if( e.value.length ) GLOBAL.fonts[12].fontString = e.value;
			
			
			
			/+
			// Font
			result = root.query.descendant("font").attribute("name");
			foreach( e; result ) GLOBAL.editFont.name = e.value;

			result = root.query.descendant("font").attribute("size");
			foreach( e; result ) GLOBAL.editFont.size = e.value;

			result = root.query.descendant("font").attribute("bold");
			foreach( e; result ) GLOBAL.editFont.bold = e.value;

			result = root.query.descendant("font").attribute("italic");
			foreach( e; result ) GLOBAL.editFont.italic = e.value;

			result = root.query.descendant("font").attribute("underline");
			foreach( e; result ) GLOBAL.editFont.underline = e.value;

			result = root.query.descendant("font").attribute("forecolor");
			foreach( e; result ) GLOBAL.editFont.foreColor = e.value;

			result = root.query.descendant("font").attribute("backcolor");
			foreach( e; result ) GLOBAL.editFont.backColor = e.value;
			+/


			// Color (Editor)
			result = root.query.descendant("color").attribute("keyword0");
			foreach( e; result ) GLOBAL.editColor.keyWord[0] = e.value;

			result = root.query.descendant("color").attribute("keyword1");
			foreach( e; result ) GLOBAL.editColor.keyWord[1] = e.value;

			result = root.query.descendant("color").attribute("keyword2");
			foreach( e; result ) GLOBAL.editColor.keyWord[2] = e.value;

			result = root.query.descendant("color").attribute("keyword3");
			foreach( e; result ) GLOBAL.editColor.keyWord[3] = e.value;
			
			result = root.query.descendant("color").attribute("template");
			foreach( e; result ) GLOBAL.colorTemplate = e.value;
			
			result = root.query.descendant("color").attribute("caretLine");
			foreach( e; result ) GLOBAL.editColor.caretLine = e.value;

			result = root.query.descendant("color").attribute("cursor");
			foreach( e; result ) GLOBAL.editColor.cursor = e.value;

			result = root.query.descendant("color").attribute("selectionFore");
			foreach( e; result ) GLOBAL.editColor.selectionFore = e.value;

			result = root.query.descendant("color").attribute("selectionBack");
			foreach( e; result ) GLOBAL.editColor.selectionBack = e.value;
			
			result = root.query.descendant("color").attribute("linenumFore");
			foreach( e; result ) GLOBAL.editColor.linenumFore = e.value;

			result = root.query.descendant("color").attribute("linenumBack");
			foreach( e; result ) GLOBAL.editColor.linenumBack = e.value;

			result = root.query.descendant("color").attribute("fold");
			foreach( e; result ) GLOBAL.editColor.fold = e.value;

			result = root.query.descendant("color").attribute("selAlpha");
			foreach( e; result ) GLOBAL.editColor.selAlpha = e.value;
			
			result = root.query.descendant("color").attribute("currentword");
			foreach( e; result ) GLOBAL.editColor.currentWord = e.value;

			result = root.query.descendant("color").attribute("currentwordAlpha");
			foreach( e; result ) GLOBAL.editColor.currentWordAlpha = e.value;

			
			result = root.query.descendant("color").attribute("braceFore");
			foreach( e; result ) GLOBAL.editColor.braceFore = e.value;
			result = root.query.descendant("color").attribute("braceBack");
			foreach( e; result ) GLOBAL.editColor.braceBack = e.value;			

			result = root.query.descendant("color").attribute("errorFore");
			foreach( e; result ) GLOBAL.editColor.errorFore = e.value;
			result = root.query.descendant("color").attribute("errorBack");
			foreach( e; result ) GLOBAL.editColor.errorBack = e.value;

			result = root.query.descendant("color").attribute("warningFore");
			foreach( e; result ) GLOBAL.editColor.warningFore = e.value;
			result = root.query.descendant("color").attribute("warningBack");
			foreach( e; result ) GLOBAL.editColor.warringBack = e.value;

			result = root.query.descendant("color").attribute("manualFore");
			foreach( e; result ) GLOBAL.editColor.manualFore = e.value;
			result = root.query.descendant("color").attribute("manualBack");
			foreach( e; result ) GLOBAL.editColor.manualBack = e.value;

			result = root.query.descendant("color").attribute("scintillaFore");
			foreach( e; result ) GLOBAL.editColor.scintillaFore = e.value;
			result = root.query.descendant("color").attribute("scintillaBack");
			foreach( e; result ) GLOBAL.editColor.scintillaBack = e.value;
			
			result = root.query.descendant("color").attribute("SCE_B_COMMENT_Fore");
			foreach( e; result ) GLOBAL.editColor.SCE_B_COMMENT_Fore = e.value;
			result = root.query.descendant("color").attribute("SCE_B_COMMENT_Back");
			foreach( e; result ) GLOBAL.editColor.SCE_B_COMMENT_Back = e.value;
			
			result = root.query.descendant("color").attribute("SCE_B_NUMBER_Fore");
			foreach( e; result ) GLOBAL.editColor.SCE_B_NUMBER_Fore = e.value;
			result = root.query.descendant("color").attribute("SCE_B_NUMBER_Back");
			foreach( e; result ) GLOBAL.editColor.SCE_B_NUMBER_Back = e.value;
			
			result = root.query.descendant("color").attribute("SCE_B_STRING_Fore");
			foreach( e; result ) GLOBAL.editColor.SCE_B_STRING_Fore = e.value;
			result = root.query.descendant("color").attribute("SCE_B_STRING_Back");
			foreach( e; result ) GLOBAL.editColor.SCE_B_STRING_Back = e.value;
			
			result = root.query.descendant("color").attribute("SCE_B_PREPROCESSOR_Fore");
			foreach( e; result ) GLOBAL.editColor.SCE_B_PREPROCESSOR_Fore = e.value;
			result = root.query.descendant("color").attribute("SCE_B_PREPROCESSOR_Back");
			foreach( e; result ) GLOBAL.editColor.SCE_B_PREPROCESSOR_Back = e.value;

			result = root.query.descendant("color").attribute("SCE_B_PREPROCESSOR_Fore");
			foreach( e; result ) GLOBAL.editColor.SCE_B_PREPROCESSOR_Fore = e.value;
			result = root.query.descendant("color").attribute("SCE_B_PREPROCESSOR_Back");
			foreach( e; result ) GLOBAL.editColor.SCE_B_PREPROCESSOR_Back = e.value;

			result = root.query.descendant("color").attribute("SCE_B_OPERATOR_Fore");
			foreach( e; result ) GLOBAL.editColor.SCE_B_OPERATOR_Fore = e.value;
			result = root.query.descendant("color").attribute("SCE_B_OPERATOR_Back");
			foreach( e; result ) GLOBAL.editColor.SCE_B_OPERATOR_Back = e.value;

			result = root.query.descendant("color").attribute("SCE_B_IDENTIFIER_Fore");
			foreach( e; result ) GLOBAL.editColor.SCE_B_IDENTIFIER_Fore = e.value;
			result = root.query.descendant("color").attribute("SCE_B_IDENTIFIER_Back");
			foreach( e; result ) GLOBAL.editColor.SCE_B_IDENTIFIER_Back = e.value;

			result = root.query.descendant("color").attribute("SCE_B_COMMENTBLOCK_Fore");
			foreach( e; result ) GLOBAL.editColor.SCE_B_COMMENTBLOCK_Fore = e.value;
			result = root.query.descendant("color").attribute("SCE_B_COMMENTBLOCK_Back");
			foreach( e; result ) GLOBAL.editColor.SCE_B_COMMENTBLOCK_Back = e.value;

			result = root.query.descendant("color").attribute("projectFore");
			foreach( e; result ) GLOBAL.editColor.projectFore = e.value;
			result = root.query.descendant("color").attribute("projectBack");
			foreach( e; result ) GLOBAL.editColor.projectBack = e.value;

			result = root.query.descendant("color").attribute("outlineFore");
			foreach( e; result ) GLOBAL.editColor.outlineFore = e.value;
			result = root.query.descendant("color").attribute("outlineBack");
			foreach( e; result ) GLOBAL.editColor.outlineBack = e.value;

			result = root.query.descendant("color").attribute("filelistFore");
			foreach( e; result ) GLOBAL.editColor.filelistFore = e.value;
			result = root.query.descendant("color").attribute("filelistBack");
			foreach( e; result ) GLOBAL.editColor.filelistBack = e.value;

			result = root.query.descendant("color").attribute("outputFore");
			foreach( e; result ) GLOBAL.editColor.outputFore = e.value;
			result = root.query.descendant("color").attribute("outputBack");
			foreach( e; result ) GLOBAL.editColor.outputBack = e.value;

			result = root.query.descendant("color").attribute("searchFore");
			foreach( e; result ) GLOBAL.editColor.searchFore = e.value;
			result = root.query.descendant("color").attribute("searchBack");
			foreach( e; result ) GLOBAL.editColor.searchBack = e.value;

			result = root.query.descendant("color").attribute("prjTitle");
			foreach( e; result ) GLOBAL.editColor.prjTitle = e.value;
			result = root.query.descendant("color").attribute("prjSourceType");
			foreach( e; result ) GLOBAL.editColor.prjSourceType = e.value;
			
			result = root.query.descendant("color").attribute("maker0");
			foreach( e; result ) GLOBAL.editColor.maker[0] = e.value;
			result = root.query.descendant("color").attribute("maker1");
			foreach( e; result ) GLOBAL.editColor.maker[1] = e.value;
			result = root.query.descendant("color").attribute("maker2");
			foreach( e; result ) GLOBAL.editColor.maker[2] = e.value;
			result = root.query.descendant("color").attribute("maker3");
			foreach( e; result ) GLOBAL.editColor.maker[3] = e.value;

			/+
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
									IupMessage( toStringz( "Language Error!" ), toStringz( Util.trim( s[0..assignIndex] ) ~ "=Error" ) );
								}
							}
						}
					}
				}
			}
			+/

			// short keys (Editor)
			if( !GLOBAL.shortKeys.length ) GLOBAL.shortKeys.length = 35;
			result = root.query.descendant("shortkeys").attribute("find");
			foreach( e; result )
			{
				ShortKey sk = { "find", GLOBAL.languageItems["sc_findreplace"].toDString(), convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[0] = sk;
			}

			result = root.query.descendant("shortkeys").attribute("findinfile");
			foreach( e; result )
			{
				ShortKey sk = { "findinfile", GLOBAL.languageItems["sc_findreplacefiles"].toDString(), convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[1] = sk;
			}

			result = root.query.descendant("shortkeys").attribute("findnext");
			foreach( e; result )
			{
				ShortKey sk = { "findnext", GLOBAL.languageItems["sc_findnext"].toDString(), convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[2] = sk;
			}

			result = root.query.descendant("shortkeys").attribute("findprev");
			foreach( e; result )
			{
				ShortKey sk = { "findprev", GLOBAL.languageItems["sc_findprev"].toDString(), convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[3] = sk;
			}		

			result = root.query.descendant("shortkeys").attribute("gotoline");
			foreach( e; result )
			{
				ShortKey sk = { "gotoline", GLOBAL.languageItems["sc_goto"].toDString(), convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[4] = sk;
			}

			result = root.query.descendant("shortkeys").attribute("undo");
			foreach( e; result )
			{
				ShortKey sk = { "undo", GLOBAL.languageItems["sc_undo"].toDString(), convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[5] = sk;
			}		

			result = root.query.descendant("shortkeys").attribute("redo");
			foreach( e; result )
			{
				ShortKey sk = { "redo", GLOBAL.languageItems["sc_redo"].toDString(), convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[6] = sk;
			}		

			result = root.query.descendant("shortkeys").attribute("defintion");
			foreach( e; result )
			{
				ShortKey sk = { "defintion", GLOBAL.languageItems["sc_gotodef"].toDString(), convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[7] = sk;
			}	

			result = root.query.descendant("shortkeys").attribute("quickrun");
			foreach( e; result )
			{
				ShortKey sk = { "quickrun", GLOBAL.languageItems["sc_quickrun"].toDString(), convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[8] = sk;
			}	

			result = root.query.descendant("shortkeys").attribute("run");
			foreach( e; result )
			{
				ShortKey sk = { "run", GLOBAL.languageItems["sc_run"].toDString(), convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[9] = sk;
			}	

			result = root.query.descendant("shortkeys").attribute("build");
			foreach( e; result )
			{
				ShortKey sk = { "build", GLOBAL.languageItems["sc_build"].toDString(), convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[10] = sk;
			}	

			result = root.query.descendant("shortkeys").attribute("outlinewindow");
			foreach( e; result )
			{
				ShortKey sk = { "outlinewindow", GLOBAL.languageItems["sc_leftwindow"].toDString(), convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[11] = sk;
			}	

			result = root.query.descendant("shortkeys").attribute("messagewindow");
			foreach( e; result )
			{
				ShortKey sk = { "messagewindow", GLOBAL.languageItems["sc_bottomwindow"].toDString(), convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[12] = sk;
			}

			result = root.query.descendant("shortkeys").attribute("showtype");
			foreach( e; result )
			{
				ShortKey sk = { "showtype", GLOBAL.languageItems["sc_showtype"].toDString(), convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[13] = sk;
			}

			result = root.query.descendant("shortkeys").attribute("reparse");
			foreach( e; result )
			{
				ShortKey sk = { "reparse", GLOBAL.languageItems["sc_reparse"].toDString(), convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[14] = sk;
			}			

			result = root.query.descendant("shortkeys").attribute("save");
			foreach( e; result )
			{
				ShortKey sk = { "save", GLOBAL.languageItems["sc_save"].toDString(), convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[15] = sk;
			}			

			result = root.query.descendant("shortkeys").attribute("saveall");
			foreach( e; result )
			{
				ShortKey sk = { "saveall", GLOBAL.languageItems["sc_saveall"].toDString(), convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[16] = sk;
			}			

			result = root.query.descendant("shortkeys").attribute("close");
			foreach( e; result )
			{
				ShortKey sk = { "close", GLOBAL.languageItems["sc_close"].toDString(), convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[17] = sk;
			}			

			result = root.query.descendant("shortkeys").attribute("nexttab");
			foreach( e; result )
			{
				ShortKey sk = { "nexttab", GLOBAL.languageItems["sc_nexttab"].toDString(), convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[18] = sk;
			}			

			result = root.query.descendant("shortkeys").attribute("prevtab");
			foreach( e; result )
			{
				ShortKey sk = { "prevtab", GLOBAL.languageItems["sc_prevtab"].toDString(), convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[19] = sk;
			}

			result = root.query.descendant("shortkeys").attribute("newtab");
			foreach( e; result )
			{
				ShortKey sk = { "newtab", GLOBAL.languageItems["sc_newtab"].toDString(), convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[20] = sk;
			}

			result = root.query.descendant("shortkeys").attribute("autocomplete");
			foreach( e; result )
			{
				ShortKey sk = { "autocomplete", GLOBAL.languageItems["sc_autocomplete"].toDString(), convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[21]= sk;
			}

			result = root.query.descendant("shortkeys").attribute("compilerun");
			foreach( e; result )
			{
				ShortKey sk = { "compilerun", GLOBAL.languageItems["sc_compilerun"].toDString(), convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[22]= sk;
			}

			result = root.query.descendant("shortkeys").attribute("comment");
			foreach( e; result )
			{
				ShortKey sk = { "comment", GLOBAL.languageItems["sc_comment"].toDString(), convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[23]= sk;
			}
			
			result = root.query.descendant("shortkeys").attribute("backdefinition");
			foreach( e; result )
			{
				ShortKey sk = { "backdefinition", GLOBAL.languageItems["sc_backdefinition"].toDString(), convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[24]= sk;
			}

			for( int i = 1; i < 10; ++ i )
			{
				char[] targetString = "customtool" ~ Integer.toString(i);
				result = root.query.descendant("shortkeys").attribute( targetString );
				foreach( e; result )
				{
					ShortKey sk = { targetString, GLOBAL.languageItems[targetString].toDString(), convertShortKeyValue2Integer( e.value ) };
					GLOBAL.shortKeys[24+i]= sk;
				}
			}
			
			auto result34 = root.query.descendant("shortkeys").attribute("procedure");
			foreach( e; result34 )
			{
				//ShortKey sk = { "procedure", GLOBAL.languageItems["sc_procedure"].toDString(), convertShortKeyValue2Integer( e.value ) };
				//IupMessage( "",toStringz( e.value ) );
				//int _value = cast(int) convertShortKeyValue2Integer( e.value );
				GLOBAL.shortKeys[34].name = "procedure";
				GLOBAL.shortKeys[34].title = GLOBAL.languageItems["sc_procedure"].toDString();
				GLOBAL.shortKeys[34].keyValue = cast(int) convertShortKeyValue2Integer( e.value );
				break;
			}
			
			// Get linux terminal program name
			// version( linux ) setLinuxTerminal();
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
		.attribute( null, "manualFore", GLOBAL.editColor.manualFore.toDString )
		.attribute( null, "manualBack", GLOBAL.editColor.manualBack.toDString )
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

			result = root.query.descendant("color").attribute("manualFore");
			foreach( e; result ) results ~= e.value;
			result = root.query.descendant("color").attribute("manualBack");
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