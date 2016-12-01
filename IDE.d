module IDE;

struct IDECONFIG
{
	private:
	import iup.iup;
	
	import global, actionManager;

	import tango.stdc.stringz, Integer = tango.text.convert.Integer, Util = tango.text.Util;
	import tango.text.xml.Document, tango.text.xml.DocPrinter, tango.io.UnicodeFile;
	
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
		// Write Setting File...
		auto doc = new Document!(char);

		// attach an xml header
		doc.header;

		auto configNode = doc.tree.element( null, "config" );

		auto editorNode = configNode.element( null, "editor" );
		editorNode.element( null, "lexer", GLOBAL.lexer );
		for( int i = 0; i < GLOBAL.KEYWORDS.length; ++i )
		{
			editorNode.element( null, "keywords" )
			.attribute( null, "id", Integer.toString( i ) ).attribute( null, "value", Util.trim( GLOBAL.KEYWORDS[i] ) ).attribute( null, "color", GLOBAL.editColor.keyWord[i]);
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
		.attribute( null, "BoldKeyword", GLOBAL.editorSetting00.BoldKeyword );


		if( fromStringz( IupGetAttribute( GLOBAL.menuOutlineWindow, "VALUE" ) ) == "OFF" )
			GLOBAL.editorSetting01.ExplorerSplit = Integer.toString( GLOBAL.explorerSplit_value );
		else
			GLOBAL.editorSetting01.ExplorerSplit = fromStringz( IupGetAttribute( GLOBAL.explorerSplit, "VALUE" ) );
		
		if( fromStringz( IupGetAttribute( GLOBAL.menuMessageWindow, "VALUE" ) ) == "OFF" )
			GLOBAL.editorSetting01.MessageSplit = Integer.toString( GLOBAL.messageSplit_value );
		else
			GLOBAL.editorSetting01.MessageSplit = fromStringz( IupGetAttribute( GLOBAL.messageSplit, "VALUE" ) );
		
		
		GLOBAL.editorSetting01.FileListSplit = fromStringz( IupGetAttribute( GLOBAL.fileListSplit, "VALUE" ) );
		GLOBAL.editorSetting01.OutlineWindow = fromStringz( IupGetAttribute( GLOBAL.menuOutlineWindow, "VALUE" ) );
		GLOBAL.editorSetting01.MessageWindow = fromStringz( IupGetAttribute( GLOBAL.menuMessageWindow, "VALUE" ) );

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
		.attribute( null, "Annotation", GLOBAL.fonts[10].fontString );

		//<color caretLine="255 255 0" cursor="0 0 0" selectionFore="255 255 255" selectionBack="0 0 255" linenumFore="0 0 0" linenumBack="200 200 200" fold="200 208 208"></color>
		editorNode.element( null, "color" )
		.attribute( null, "caretLine", GLOBAL.editColor.caretLine )
		.attribute( null, "cursor", GLOBAL.editColor.cursor )
		.attribute( null, "selectionFore", GLOBAL.editColor.selectionFore )
		.attribute( null, "selectionBack", GLOBAL.editColor.selectionBack )
		.attribute( null, "linenumFore", GLOBAL.editColor.linenumFore )
		.attribute( null, "linenumBack", GLOBAL.editColor.linenumBack )
		.attribute( null, "fold", GLOBAL.editColor.fold )
		.attribute( null, "selAlpha", GLOBAL.editColor.selAlpha );

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
		.attribute( null, "compilerun", convertShortKeyValue2String( GLOBAL.shortKeys[22].keyValue ) );

		/*
		<buildtools>
			<compilerpath>D:\CodingPark\FreeBASIC-1.02.1-win32\fbc.exe</compilerpath>
			<debuggerpath>D:\CodingPark\FreeBASIC-1.02.1-win32\bin\win32\gdb.exe</debuggerpath>
			<maxerror>30</maxerror>
		</buildtools>  
		*/
		auto buildtoolsNode = configNode.element( null, "buildtools" );
		buildtoolsNode.element( null, "compilerpath", GLOBAL.compilerFullPath );
		buildtoolsNode.element( null, "debuggerpath", GLOBAL.debuggerFullPath );
		buildtoolsNode.element( null, "defaultoption", GLOBAL.defaultOption );
		buildtoolsNode.element( null, "resultwindow", GLOBAL.compilerWindow );
		buildtoolsNode.element( null, "annotation", GLOBAL.compilerAnootation );

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
		<recentFiles>
			<name>~~~</name>
			<name>~~~</name>
		</recentFiles>  
		*/
		auto recentFilesNode = configNode.element( null, "recentFiles" );
		for( int i = 0; i < GLOBAL.recentFiles.length; ++i )
		{
			recentFilesNode.element( null, "name", GLOBAL.recentFiles[i] );
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
			recentNode.element( null, "name", GLOBAL.recentProjects[i] );
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
		/*
		Ihandle* listOptions = IupGetHandle( "CArgOptionDialog_listOptions" );
		if( listOptions != null )
		{
			for( int i = 0; i < IupGetInt( listOptions, "COUNT" ); ++i )
			{
				optionsNode.element( null, "name", fromStringz( IupGetAttribute( listOptions, toStringz( Integer.toString( i + 1 ) ) ) ).dup );
			}
		}
		*/

		auto argsNode = configNode.element( null, "recentArgs" );
		foreach( char[] s; GLOBAL.recentArgs )
			argsNode.element( null, "name", s );		
		/*
		Ihandle* listArgs = IupGetHandle( "CArgOptionDialog_listArgs" );
		if( listArgs != null )
		{
			for( int i = 0; i < IupGetInt( listArgs, "COUNT" ); ++i )
			{
				argsNode.element( null, "name", fromStringz( IupGetAttribute( listArgs, toStringz( Integer.toString( i + 1 ) ) ) ).dup );
			}
		}
		*/
		
		auto print = new DocPrinter!(char);
		actionManager.FileAction.saveFile( "settings/editorSettings.xml", print.print( doc ) );
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
			
			result = root.query.descendant("keywords").attribute("value");
			GLOBAL.KEYWORDS.length = 0;
			foreach( e; result )
			{
				GLOBAL.KEYWORDS ~= e.value;
			}

			result = root.query.descendant("keywords").attribute("color");
			int index;
			foreach( e; result )
			{
				GLOBAL.editColor.keyWord[index++] = e.value;
			}			

			result = root.query.descendant("compilerpath");
			foreach( e; result )
			{
				GLOBAL.compilerFullPath = e.value;
			}	

			result = root.query.descendant("debuggerpath");
			foreach( e; result )
			{
				GLOBAL.debuggerFullPath = e.value;
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
		
			result = root.query.descendant("recentFiles").descendant("name");
			foreach( e; result )
			{
				GLOBAL.recentFiles ~= e.value;
			}

			result = root.query.descendant("recentProjects").descendant("name");
			foreach( e; result )
			{
				GLOBAL.recentProjects ~= e.value;
			}

			result = root.query.descendant("recentOptions").descendant("name");
			foreach( e; result )
			{
				GLOBAL.recentOptions ~= e.value;
			}

			result = root.query.descendant("recentArgs").descendant("name");
			foreach( e; result )
			{
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

			fu.name = "Default";
			GLOBAL.fonts[0] = fu;
			result = root.query.descendant("font").attribute( fu.name );
			foreach( e; result ) if( e.value.length ) GLOBAL.fonts[0].fontString = e.value;

			fu.name = "Document";
			GLOBAL.fonts[1] = fu;
			result = root.query.descendant("font").attribute( fu.name );
			foreach( e; result ) if( e.value.length ) GLOBAL.fonts[1].fontString = e.value;
			
			fu.name = "Leftside";
			GLOBAL.fonts[2] = fu;
			result = root.query.descendant("font").attribute( fu.name );
			foreach( e; result ) if( e.value.length ) GLOBAL.fonts[2].fontString = e.value;

			fu.name = "Filelist";
			GLOBAL.fonts[3] = fu;
			result = root.query.descendant("font").attribute( fu.name );
			foreach( e; result ) if( e.value.length ) GLOBAL.fonts[3].fontString = e.value;

			fu.name = "Project";
			GLOBAL.fonts[4] = fu;
			result = root.query.descendant("font").attribute( fu.name );
			foreach( e; result ) if( e.value.length ) GLOBAL.fonts[4].fontString = e.value;

			fu.name = "Outline";
			GLOBAL.fonts[5] = fu;
			result = root.query.descendant("font").attribute( fu.name );
			foreach( e; result ) if( e.value.length ) GLOBAL.fonts[5].fontString = e.value;
			
			fu.name = "Bottom";
			GLOBAL.fonts[6] = fu;
			result = root.query.descendant("font").attribute( fu.name );
			foreach( e; result ) if( e.value.length ) GLOBAL.fonts[6].fontString = e.value;

			fu.name = "Output";
			GLOBAL.fonts[7] = fu;
			result = root.query.descendant("font").attribute( fu.name );
			foreach( e; result ) if( e.value.length ) GLOBAL.fonts[7].fontString = e.value;

			fu.name = "Search";
			GLOBAL.fonts[8] = fu;
			result = root.query.descendant("font").attribute( fu.name );
			foreach( e; result ) if( e.value.length ) GLOBAL.fonts[8].fontString = e.value;

			fu.name = "Debugger";
			GLOBAL.fonts[9] = fu;
			result = root.query.descendant("font").attribute( fu.name );
			foreach( e; result ) if( e.value.length ) GLOBAL.fonts[9].fontString = e.value;

			fu.name = "Annotation";
			GLOBAL.fonts[10] = fu;
			result = root.query.descendant("font").attribute( fu.name );
			foreach( e; result ) if( e.value.length ) GLOBAL.fonts[10].fontString = e.value;			
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


			// short keys (Editor)
			if( !GLOBAL.shortKeys.length ) GLOBAL.shortKeys.length = 23;
			result = root.query.descendant("shortkeys").attribute("find");
			foreach( e; result )
			{
				ShortKey sk = { "Find/Replace", convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[0] = sk;
			}

			result = root.query.descendant("shortkeys").attribute("findinfile");
			foreach( e; result )
			{
				ShortKey sk = { "Find/Replace In Files", convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[1] = sk;
			}

			result = root.query.descendant("shortkeys").attribute("findnext");
			foreach( e; result )
			{
				ShortKey sk = { "Find Next", convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[2] = sk;
			}

			result = root.query.descendant("shortkeys").attribute("findprev");
			foreach( e; result )
			{
				ShortKey sk = { "Find Previous", convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[3] = sk;
			}		

			result = root.query.descendant("shortkeys").attribute("gotoline");
			foreach( e; result )
			{
				ShortKey sk = { "Goto Line", convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[4] = sk;
			}

			result = root.query.descendant("shortkeys").attribute("undo");
			foreach( e; result )
			{
				ShortKey sk = { "Undo", convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[5] = sk;
			}		

			result = root.query.descendant("shortkeys").attribute("redo");
			foreach( e; result )
			{
				ShortKey sk = { "Redo", convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[6] = sk;
			}		

			result = root.query.descendant("shortkeys").attribute("defintion");
			foreach( e; result )
			{
				ShortKey sk = { "Goto Defintion", convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[7] = sk;
			}	

			result = root.query.descendant("shortkeys").attribute("quickrun");
			foreach( e; result )
			{
				ShortKey sk = { "Quick Run", convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[8] = sk;
			}	

			result = root.query.descendant("shortkeys").attribute("run");
			foreach( e; result )
			{
				ShortKey sk = { "Run", convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[9] = sk;
			}	

			result = root.query.descendant("shortkeys").attribute("build");
			foreach( e; result )
			{
				ShortKey sk = { "Build", convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[10] = sk;
			}	

			result = root.query.descendant("shortkeys").attribute("outlinewindow");
			foreach( e; result )
			{
				ShortKey sk = { "On/Off Left-side Window", convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[11] = sk;
			}	

			result = root.query.descendant("shortkeys").attribute("messagewindow");
			foreach( e; result )
			{
				ShortKey sk = { "On/Off Bottom-side Window", convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[12] = sk;
			}

			result = root.query.descendant("shortkeys").attribute("showtype");
			foreach( e; result )
			{
				ShortKey sk = { "Show Type", convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[13] = sk;
			}

			result = root.query.descendant("shortkeys").attribute("reparse");
			foreach( e; result )
			{
				ShortKey sk = { "Reparse", convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[14] = sk;
			}			

			result = root.query.descendant("shortkeys").attribute("save");
			foreach( e; result )
			{
				ShortKey sk = { "Save File", convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[15] = sk;
			}			

			result = root.query.descendant("shortkeys").attribute("saveall");
			foreach( e; result )
			{
				ShortKey sk = { "Save All", convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[16] = sk;
			}			

			result = root.query.descendant("shortkeys").attribute("close");
			foreach( e; result )
			{
				ShortKey sk = { "Close File", convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[17] = sk;
			}			

			result = root.query.descendant("shortkeys").attribute("nexttab");
			foreach( e; result )
			{
				ShortKey sk = { "Next Tab", convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[18] = sk;
			}			

			result = root.query.descendant("shortkeys").attribute("prevtab");
			foreach( e; result )
			{
				ShortKey sk = { "Previous Tab", convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[19] = sk;
			}

			result = root.query.descendant("shortkeys").attribute("newtab");
			foreach( e; result )
			{
				ShortKey sk = { "New Tab", convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[20] = sk;
			}

			result = root.query.descendant("shortkeys").attribute("autocomplete");
			foreach( e; result )
			{
				ShortKey sk = { "Autocomplete", convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[21]= sk;
			}

			result = root.query.descendant("shortkeys").attribute("compilerun");
			foreach( e; result )
			{
				ShortKey sk = { "Compile & Run", convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys[22]= sk;
			}

			// Get linux terminal program name
			version( linux )
			{
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
		}
		catch( Exception e ){}
	}
}