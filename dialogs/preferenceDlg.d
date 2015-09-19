module dialogs.preferenceDlg;

private import iup.iup, iup.iup_scintilla;

private import global, project, scintilla, actionManager;
private import dialogs.baseDlg, dialogs.helpDlg, dialogs.fileDlg, dialogs.shortcutDlg;

private import tango.stdc.stringz, Integer = tango.text.convert.Integer, Util = tango.text.Util;
private import tango.text.xml.Document, tango.text.xml.DocPrinter, tango.io.UnicodeFile;
private import tango.io.Stdout;

class CPreferenceDialog : CBaseDialog
{
	private:
	
	Ihandle* textCompilerPath, textDebuggerPath;

	void createLayout()
	{
		Ihandle* bottom = createDlgButton();

		Ihandle* labelCompiler = IupLabel( "Compiler Path:" );
		IupSetAttributes( labelCompiler, "VISIBLELINES=1,VISIBLECOLUMNS=1" );
		//IupSetAttribute( labelCompiler, "FONT", "Consolas, 10" );
		
		textCompilerPath = IupText( null );
		IupSetAttribute( textCompilerPath, "SIZE", "180x12" );
		IupSetAttribute( textCompilerPath, "VALUE", toStringz(GLOBAL.compilerFullPath) );
		IupSetHandle( "compilerPath_Handle", textCompilerPath );
		
		Ihandle* btnOpen = IupButton( null, null );
		IupSetAttribute( btnOpen, "IMAGE", "icon_openfile" );
		IupSetCallback( btnOpen, "ACTION", cast(Icallback) &CPreferenceDialog_OpenCompileBinFile_cb );

		Ihandle* hBox01 = IupHbox( labelCompiler, textCompilerPath, btnOpen, null );
		IupSetAttribute( hBox01, "ALIGNMENT", "ACENTER" );

		

		Ihandle* labelDebugger = IupLabel( "Debugger Path:" );
		IupSetAttributes( labelDebugger, "VISIBLELINES=1,VISIBLECOLUMNS=1" );
		
		textDebuggerPath = IupText( null );
		IupSetAttribute( textDebuggerPath, "SIZE", "180x12" );
		IupSetAttribute( textDebuggerPath, "VALUE", toStringz(GLOBAL.debuggerFullPath) );
		IupSetHandle( "debuggerPath_Handle", textDebuggerPath );
		IupSetAttribute( textDebuggerPath, "ACTIVE", "NO" );
		
		Ihandle* btnOpenDebugger = IupButton( null, null );
		IupSetAttribute( btnOpenDebugger, "IMAGE", "icon_openfile" );
		IupSetCallback( btnOpenDebugger, "ACTION", cast(Icallback) &CPreferenceDialog_OpenCompileBinFile_cb );
		IupSetAttribute( btnOpenDebugger, "ACTIVE", "NO" );

		Ihandle* hBox02 = IupHbox( labelDebugger, textDebuggerPath, btnOpenDebugger, null );
		IupSetAttribute( hBox02, "ALIGNMENT", "ACENTER" );


		// Parser Setting
		Ihandle* labelTrigger = IupLabel( "Autocompletion Trigger:" );
		IupSetAttributes( labelTrigger, "SIZE=100x12" );
		
		Ihandle* textTrigger = IupText( null );
		IupSetAttribute( textTrigger, "SIZE", "30x12" );
		IupSetAttribute( textTrigger, "VALUE", toStringz( Integer.toString( GLOBAL.autoCompletionTriggerWordCount ) ) );
		IupSetHandle( "textTrigger", textTrigger );
		
		
		Ihandle* hBox00 = IupHbox( labelTrigger, textTrigger, null );

		Ihandle* frameParser = IupFrame( hBox00 );
		IupSetAttribute( frameParser, "TITLE", "Parser Setting");
		IupSetAttribute( frameParser, "EXPANDCHILDREN", "YES");
		

		Ihandle* vBoxPage01 = IupVbox( hBox01, hBox02, frameParser, null );
		IupSetAttribute( vBoxPage01, "ALIGNMENT", "ALEFT");
		IupSetAttribute( vBoxPage01, "EXPANDCHILDREN", "YES");

/+


		Ihandle* labelMaxError = IupLabel( "Max errors occurred to stop:" );
		IupSetAttributes( labelCompiler, "VISIBLELINES=1,VISIBLECOLUMNS=1" );
		
		textCompilerPath = IupText( null );
		IupSetAttribute( textCompilerPath, "SIZE", "200x12" );
		IupSetAttribute( textCompilerPath, "VALUE", toStringz(GLOBAL.compilerFullPath) );
		IupSetHandle( "compilerPath_Handle", textCompilerPath );


+/
		Ihandle* toggleLineMargin = IupToggle( "Show line number margin", null );
		IupSetAttribute( toggleLineMargin, "VALUE", toStringz(GLOBAL.editorSetting00.LineMargin) );
		IupSetHandle( "toggleLineMargin", toggleLineMargin );
		
		Ihandle* toggleBookmarkMargin = IupToggle( "Show book mark margin", null );
		IupSetAttribute( toggleBookmarkMargin, "VALUE", toStringz(GLOBAL.editorSetting00.BookmarkMargin) );
		IupSetHandle( "toggleBookmarkMargin", toggleBookmarkMargin );
		
		Ihandle* toggleFoldMargin = IupToggle( "Show folding margin", null );
		IupSetAttribute( toggleFoldMargin, "VALUE", toStringz(GLOBAL.editorSetting00.FoldMargin) );
		IupSetHandle( "toggleFoldMargin", toggleFoldMargin );
		
		Ihandle* toggleIndentGuide = IupToggle( "Show indentation guide", null );
		IupSetAttribute( toggleIndentGuide, "VALUE", toStringz(GLOBAL.editorSetting00.IndentGuide) );
		IupSetHandle( "toggleIndentGuide", toggleIndentGuide );
		
		Ihandle* toggleCaretLine = IupToggle( "High light caret line", null );
		IupSetAttribute( toggleCaretLine, "VALUE", toStringz(GLOBAL.editorSetting00.CaretLine) );
		IupSetHandle( "toggleCaretLine", toggleCaretLine );
		
		Ihandle* toggleWordWrap = IupToggle( "Word warp", null );
		IupSetAttribute( toggleWordWrap, "VALUE", toStringz(GLOBAL.editorSetting00.WordWrap) );
		IupSetHandle( "toggleWordWrap", toggleWordWrap );
		
		Ihandle* toggleTabUseingSpace = IupToggle( "Replace tab by space", null );
		IupSetAttribute( toggleTabUseingSpace, "VALUE", toStringz(GLOBAL.editorSetting00.TabUseingSpace) );
		IupSetHandle( "toggleTabUseingSpace", toggleTabUseingSpace );
		
		Ihandle* toggleAutoIndent = IupToggle( "Auto indent", null );
		IupSetAttribute( toggleAutoIndent, "VALUE", toStringz(GLOBAL.editorSetting00.AutoIndent) );
		IupSetHandle( "toggleAutoIndent", toggleAutoIndent );
		
		Ihandle* gbox = IupGridBox
		(
			IupSetAttributes( toggleLineMargin, "" ),
			IupSetAttributes( toggleBookmarkMargin,"" ),

			IupSetAttributes( toggleFoldMargin, "" ),
			IupSetAttributes( toggleIndentGuide, "" ),

			IupSetAttributes( toggleCaretLine, "" ),
			IupSetAttributes( toggleWordWrap, "" ),

			IupSetAttributes( toggleTabUseingSpace, "" ),
			IupSetAttributes( toggleAutoIndent, "" ),
			null
		);

		//IupSetAttribute(gbox, "SIZECOL", "1");
		//IupSetAttribute(gbox, "SIZELIN", "4");
		IupSetAttributes( gbox, "NUMDIV=2,ALIGNMENTLIN=ACENTER,GAPLIN=5,GAPCOL=20,MARGIN=0x0" );

		Ihandle* labelTabWidth = IupLabel( "Tab Width:" );
		Ihandle* textTabWidth = IupText( null );
		IupSetAttributes( textTabWidth, "SIZE=30x12,MARGIN=0x0" );
		IupSetAttribute( textTabWidth, "VALUE", toStringz(GLOBAL.editorSetting00.TabWidth) );
		IupSetHandle( "textTabWidth", textTabWidth );

		Ihandle* hBox03 = IupHbox( labelTabWidth, textTabWidth, null );
		IupSetAttribute( hBox03, "MARGIN", "0x0" );
		IupSetAttribute( hBox03, "ALIGNMENT", "ACENTER" );

		// Short Cut
		Ihandle* fontList = IupList( null );
		IupSetAttributes( fontList, "MULTIPLE=NO,MARGIN=10x10,VISIBLELINES=YES,EXPAND=YES" );
		version( Windows )
		{
			IupSetAttribute( fontList, "FONT", "Courier New,9" );
		}
		else
		{
			IupSetAttribute( fontList, "FONT", "FreeMono,Bold 9" );
		}

		for( int i = 0; i < GLOBAL.fonts.length; ++ i )
		{
			char[][] strings = Util.split( GLOBAL.fonts[i].fontString, "," );
			if( strings.length == 2 )
			{
				char[] Bold, Italic, Underline, Strikeout, size;
				
				strings[0] = Util.trim( strings[0] );
				strings[1] = Util.trim( strings[1] );

				foreach( char[] s; Util.split( strings[1], " " ) )
				{
					switch( s )
					{
						case "Bold":		Bold = s;		break;
						case "Italic":		Italic = s;		break;
						case "Underline":	Underline = s;	break;
						case "Strikeout":	Strikeout = s;	break;
						default:
							size = s;
					}
				}

				char[] _string = Stdout.layout.convert( "{,-10} {,-18},{,-4} {,-6} {,-9} {,-9} {,-3}", GLOBAL.fonts[i].name, strings[0], Bold, Italic, Underline, Strikeout, size );
				IupSetAttribute( fontList, toStringz( Integer.toString( i + 1 ) ), toStringz( _string ) );
			}
		}
		IupSetHandle( "fontList", fontList );
		IupSetCallback( fontList, "DBLCLICK_CB", cast(Icallback) &CPreferenceDialog_fontList_DBLCLICK_CB );


		Ihandle* frameFont = IupFrame( fontList );
		IupSetAttribute( frameFont, "TITLE", "Default_Font");
		IupSetAttribute( frameFont, "EXPAND", "YES");

		// Color
		Ihandle* labelCaretLine = IupLabel( "Caret line:" );
		Ihandle* btnCaretLine = IupButton( null, null );
		IupSetAttribute( btnCaretLine, "BGCOLOR", toStringz(GLOBAL.editColor.caretLine) );
		IupSetAttribute( btnCaretLine, "SIZE", "16x8" );
		IupSetHandle( "btnCaretLine", btnCaretLine );
		IupSetCallback( btnCaretLine, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelCursor = IupLabel( "Cursor:" );
		Ihandle* btnCursor = IupButton( null, null );
		IupSetAttribute( btnCursor, "BGCOLOR", toStringz(GLOBAL.editColor.cursor) );
		IupSetAttribute( btnCursor, "SIZE", "16x8" );
		IupSetHandle( "btnCursor", btnCursor );
		IupSetCallback( btnCursor, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelSelectFore = IupLabel( "Selection foreground:" );
		Ihandle* btnSelectFore = IupButton( null, null );
		IupSetAttribute( btnSelectFore, "BGCOLOR", toStringz(GLOBAL.editColor.selectionFore) );
		IupSetAttribute( btnSelectFore, "SIZE", "16x8" );
		IupSetHandle( "btnSelectFore", btnSelectFore );
		IupSetCallback( btnSelectFore, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttribute( btnSelectFore, "ACTIVE", "NO" );

		Ihandle* labelSelectBack = IupLabel( "Selection background:" );
		Ihandle* btnSelectBack = IupButton( null, null );
		IupSetAttribute( btnSelectBack, "BGCOLOR", toStringz(GLOBAL.editColor.selectionBack) );
		IupSetAttribute( btnSelectBack, "SIZE", "16x8" );
		IupSetHandle( "btnSelectBack", btnSelectBack );
		IupSetCallback( btnSelectBack, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttribute( btnSelectBack, "ACTIVE", "NO" );

		Ihandle* labelLinenumFore = IupLabel( "Linenumber foreground:" );
		Ihandle* btnLinenumFore = IupButton( null, null );
		IupSetAttribute( btnLinenumFore, "BGCOLOR", toStringz(GLOBAL.editColor.linenumFore) );
		IupSetAttribute( btnLinenumFore, "SIZE", "16x8" );
		IupSetHandle( "btnLinenumFore", btnLinenumFore );
		IupSetCallback( btnLinenumFore, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelLinenumBack = IupLabel( "Linenumber background:" );
		Ihandle* btnLinenumBack = IupButton( null, null );
		IupSetAttribute( btnLinenumBack, "BGCOLOR", toStringz(GLOBAL.editColor.linenumBack) );
		IupSetAttribute( btnLinenumBack, "SIZE", "16x8" );
		IupSetHandle( "btnLinenumBack", btnLinenumBack );
		IupSetCallback( btnLinenumBack, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelFoldingColor = IupLabel( "FoldingMargin color:" );
		Ihandle* btnFoldingColor = IupButton( null, null );
		IupSetAttribute( btnFoldingColor, "BGCOLOR", toStringz(GLOBAL.editColor.fold) );
		IupSetAttribute( btnFoldingColor, "SIZE", "16x8" );
		IupSetHandle( "btnFoldingColor", btnFoldingColor );
		IupSetCallback( btnFoldingColor, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttribute( btnFoldingColor, "ACTIVE", "NO" );


		Ihandle* gboxColor = IupGridBox
		(
			IupSetAttributes( labelCaretLine, "" ),
			IupSetAttributes( btnCaretLine,"" ),
			IupSetAttributes( labelCursor, "" ),
			IupSetAttributes( btnCursor, "" ),

			IupSetAttributes( labelSelectFore, "" ),
			IupSetAttributes( btnSelectFore, "" ),
			IupSetAttributes( labelSelectBack, "" ),
			IupSetAttributes( btnSelectBack, "" ),

			IupSetAttributes( labelLinenumFore, "" ),
			IupSetAttributes( btnLinenumFore, "" ),
			IupSetAttributes( labelLinenumBack, "" ),
			IupSetAttributes( btnLinenumBack, "" ),

			IupSetAttributes( labelFoldingColor, "" ),
			IupSetAttributes( btnFoldingColor, "" ),
			IupSetAttributes( null, "" ),
			IupSetAttributes( null, "" ),

			null
		);
		IupSetAttributes( gboxColor, "EXPAND=YES,NUMDIV=4,ALIGNMENTLIN=ACENTER,ALIGNMENTCOL=ARIGHT,GAPLIN=5,GAPCOL=20,MARGIN=2x10,SIZELIN=2" );

		Ihandle* frameColor = IupFrame( gboxColor );
		IupSetAttributes( frameColor, "MARGIN=0x0,EXPAND=YES,EXPAND=HORIZONTAL" );
		IupSetAttribute( frameColor, "SIZE", "275x" );//IupGetAttribute( frameFont, "SIZE" ) );

		IupSetAttribute( frameColor, "TITLE", "Color");

		Ihandle* vBoxPage02 = IupVbox( gbox, hBox03, frameFont, frameColor, null );
		IupSetAttribute( vBoxPage02, "EXPANDCHILDREN", "YES");


		// Short Cut
		Ihandle* shortCutList = IupList( null );
		IupSetAttributes( shortCutList, "MULTIPLE=NO,MARGIN=10x10,VISIBLELINES=YES,EXPAND=YES" );
		version( Windows )
		{
			IupSetAttribute( shortCutList, "FONT", "Courier New,10" );
		}
		else
		{
			IupSetAttribute( shortCutList, "FONT", "FreeMono,Bold 10" );
		}
		IupSetHandle( "shortCutList", shortCutList );
		IupSetCallback( shortCutList, "DBLCLICK_CB", cast(Icallback) &CPreferenceDialog_shortCutList_DBLCLICK_CB );


		for( int i = 0; i < GLOBAL.shortKeys.length; ++ i )
		{
			char[] keyValue = convertShortKeyValue2String( GLOBAL.shortKeys[i].keyValue );
			char[][] splitWord = Util.split( keyValue, "+" );

			if(  splitWord.length == 4 ) 
			{
				if( splitWord[0] == "C" )  splitWord[0] = "Ctrl";
				if( splitWord[1] == "S" )  splitWord[1] = "Shift";
				if( splitWord[2] == "A" )  splitWord[2] = "Alt";
			}
			
			char[] string = Stdout.layout.convert( "{,-30} {,-5} + {,-5} + {,-5} + {,-5}", GLOBAL.shortKeys[i].name, splitWord[0], splitWord[1], splitWord[2], splitWord[3] );

			IupSetAttribute( shortCutList, toStringz( Integer.toString( i + 1 ) ), toStringz( string ) );
		}


		IupSetAttribute( vBoxPage01, "TABTITLE", "Compiler" );
		IupSetAttribute( vBoxPage02, "TABTITLE", "Editor" );
		IupSetAttribute( shortCutList, "TABTITLE", "Short Cut" );
		IupSetAttribute( vBoxPage01, "EXPAND", "YES" );
		
		Ihandle* preferenceTabs = IupTabs( vBoxPage01, vBoxPage02, shortCutList, null );
		IupSetAttribute( preferenceTabs, "TABTYPE", "TOP" );
		IupSetAttribute( preferenceTabs, "EXPAND", "YES" );

		
		Ihandle* vBox = IupVbox( preferenceTabs, bottom, null );
		IupSetAttributes( vBox, "ALIGNMENT=ACENTER,MARGIN=10x10,GAP=5" );

		IupAppend( _dlg, vBox );

		// Set btnOK Action
		IupSetCallback( btnOK, "ACTION", cast(Icallback) &CPreferenceDialog_btnOK_cb );
	}

	public:
	this( int w, int h, char[] title, bool bResize = true, char[] parent = null )
	{
		super( w, h, title, bResize, parent );
		IupSetAttribute( _dlg, "MINBOX", "NO" );
		version( Windows )
		{
			IupSetAttribute( _dlg, "FONT", "Courier New,9" );
		}
		else
		{
			IupSetAttribute( _dlg, "FONT", "FreeMono,Bold 9" );
		}
		 
		createLayout();
	}

	~this()
	{
		IupSetHandle( "compilerPath_Handle", null );
		IupSetHandle( "debuggerPath_Handle", null );
		IupSetHandle( "textTrigger", null );

		IupSetHandle( "toggleLineMargin", null );
		IupSetHandle( "toggleBookmarkMargin", null );
		IupSetHandle( "toggleFoldMargin", null );
		IupSetHandle( "toggleIndentGuide", null );
		IupSetHandle( "toggleCaretLine", null );
		IupSetHandle( "toggleWordWarp", null );
		IupSetHandle( "toggleTabUseingSpace", null );
		IupSetHandle( "toggleAutoIndent", null );
		
		IupSetHandle( "textTabWidth", null );

		IupSetHandle( "textFontName", null );
		IupSetHandle( "textFontSize", null );
		IupSetHandle( "toggleFontBold", null );
		IupSetHandle( "toggleFontItalic", null );
		IupSetHandle( "toggleFontUnderline", null );
		IupSetHandle( "btnFontForeground", null );
		IupSetHandle( "btnFontBackground", null );


		IupSetHandle( "btnCaretLine", null );
		IupSetHandle( "btnCursor", null );
		IupSetHandle( "btnSelectFore", null );
		IupSetHandle( "btnSelectBack", null );
		IupSetHandle( "btnLinenumFore", null );
		IupSetHandle( "btnLinenumBack", null );
		IupSetHandle( "btnFoldingColor", null );
		IupSetHandle( "btnBookmarkColor", null );

		IupSetHandle( "shortCutList", null );
		IupSetHandle( "fontList", null );
	}

	static char[] convertShortKeyValue2String( int keyValue )
	{
		char[] result;

		if( keyValue & 0x20000000 ) result = "C+";else result = "+";
		if( keyValue & 0x10000000 ) result ~= "S+";else result ~= "+";
		if( keyValue & 0x40000000 ) result ~= "A+";else result ~= "+";

		keyValue = keyValue & 0xFFFF;

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

		for( int i = 0; i < GLOBAL.KEYWORDS.length; ++i )
		{
			editorNode.element( null, "keywords" )
			.attribute( null, "id", Integer.toString( i ) ).attribute( null, "value", GLOBAL.KEYWORDS[i] );
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
		.attribute( null, "TabWidth", GLOBAL.editorSetting00.TabWidth );

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
		.attribute( null, "Search", GLOBAL.fonts[8].fontString );

		//<color caretLine="255 255 0" cursor="0 0 0" selectionFore="255 255 255" selectionBack="0 0 255" linenumFore="0 0 0" linenumBack="200 200 200" fold="200 208 208"></color>
		editorNode.element( null, "color" )
		.attribute( null, "caretLine", GLOBAL.editColor.caretLine )
		.attribute( null, "cursor", GLOBAL.editColor.cursor )
		.attribute( null, "selectionFore", GLOBAL.editColor.selectionFore )
		.attribute( null, "selectionBack", GLOBAL.editColor.selectionBack )
		.attribute( null, "linenumFore", GLOBAL.editColor.linenumFore )
		.attribute( null, "linenumBack", GLOBAL.editColor.linenumBack )
		.attribute( null, "fold", GLOBAL.editColor.fold );

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
		.attribute( null, "reparse", convertShortKeyValue2String( GLOBAL.shortKeys[14].keyValue ) );
		

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
		buildtoolsNode.element( null, "maxerror", GLOBAL.maxError );

		/*
		<parser>
			<parsertrigger>3</parsertrigger>
		</parser>  
		*/
		auto parserNode = configNode.element( null, "parser" );
		parserNode.element( null, "parsertrigger", Integer.toString( GLOBAL.autoCompletionTriggerWordCount ) );

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
		
		
		auto print = new DocPrinter!(char);
		actionManager.FileAction.saveFile( "settings\\editorSettings.xml", print.print( doc ) );
	}

	static void load()
	{
		try
		{
			// Loading Key Word...
			scope file = new UnicodeFile!(char)( "settings\\editorSettings.xml", Encoding.Unknown );
			//scope file  = cast(char[]) File.get( "settings\\editorSettings.xml" );

			scope doc = new Document!( char );
			doc.parse( file.read );

			auto root = doc.elements;
			auto result = root.query.descendant("keywords").attribute("value");
			GLOBAL.KEYWORDS.length = 0;
			foreach( e; result )
			{
				GLOBAL.KEYWORDS~= e.value;
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

			result = root.query.descendant("maxerror");
			foreach( e; result )
			{
				GLOBAL.maxError = e.value;
			}

			// Parser
			result = root.query.descendant("parsertrigger");
			foreach( e; result )
			{
				GLOBAL.autoCompletionTriggerWordCount = Integer.atoi( e.value );
			}

			result = root.query.descendant("recentProjects").descendant("name");
			foreach( e; result )
			{
				GLOBAL.recentProjects ~= e.value;
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

			result = root.query.descendant("toggle00").attribute("TabWidth");
			foreach( e; result ) GLOBAL.editorSetting00.TabWidth = e.value;


			// Font
			GLOBAL.fonts.length = 0;

			fontUint fu = { "Default", "" };
			GLOBAL.fonts ~= fu;
			result = root.query.descendant("font").attribute( fu.name );
			foreach( e; result ) GLOBAL.fonts[length-1].fontString = e.value;

			fu.name = "Document";
			GLOBAL.fonts ~= fu;
			result = root.query.descendant("font").attribute( fu.name );
			foreach( e; result ) GLOBAL.fonts[length-1].fontString = e.value;
			
			fu.name = "Leftside";
			GLOBAL.fonts ~= fu;
			result = root.query.descendant("font").attribute( fu.name );
			foreach( e; result ) GLOBAL.fonts[length-1].fontString = e.value;

			fu.name = "Filelist";
			GLOBAL.fonts ~= fu;
			result = root.query.descendant("font").attribute( fu.name );
			foreach( e; result ) GLOBAL.fonts[length-1].fontString = e.value;

			fu.name = "Project";
			GLOBAL.fonts ~= fu;
			result = root.query.descendant("font").attribute( fu.name );
			foreach( e; result ) GLOBAL.fonts[length-1].fontString = e.value;

			fu.name = "Outline";
			GLOBAL.fonts ~= fu;
			result = root.query.descendant("font").attribute( fu.name );
			foreach( e; result ) GLOBAL.fonts[length-1].fontString = e.value;
			
			fu.name = "Bottom";
			GLOBAL.fonts ~= fu;
			result = root.query.descendant("font").attribute( fu.name );
			foreach( e; result ) GLOBAL.fonts[length-1].fontString = e.value;

			fu.name = "Output";
			GLOBAL.fonts ~= fu;
			result = root.query.descendant("font").attribute( fu.name );
			foreach( e; result ) GLOBAL.fonts[length-1].fontString = e.value;

			fu.name = "Search";
			GLOBAL.fonts ~= fu;
			result = root.query.descendant("font").attribute( fu.name );
			foreach( e; result ) GLOBAL.fonts[length-1].fontString = e.value;
			
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


			// short keys (Editor)
			GLOBAL.shortKeys.length = 0;
			result = root.query.descendant("shortkeys").attribute("find");
			foreach( e; result )
			{
				ShortKey sk = { "Find/Replace", convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys ~= sk;
			}

			result = root.query.descendant("shortkeys").attribute("findinfile");
			foreach( e; result )
			{
				ShortKey sk = { "Find/Replace In Files", convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys ~= sk;
			}

			result = root.query.descendant("shortkeys").attribute("findnext");
			foreach( e; result )
			{
				ShortKey sk = { "Find Next", convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys ~= sk;
			}

			result = root.query.descendant("shortkeys").attribute("findprev");
			foreach( e; result )
			{
				ShortKey sk = { "Find Previous", convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys ~= sk;
			}		

			result = root.query.descendant("shortkeys").attribute("gotoline");
			foreach( e; result )
			{
				ShortKey sk = { "Goto Line", convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys ~= sk;
			}

			result = root.query.descendant("shortkeys").attribute("undo");
			foreach( e; result )
			{
				ShortKey sk = { "Undo", convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys ~= sk;
			}		

			result = root.query.descendant("shortkeys").attribute("redo");
			foreach( e; result )
			{
				ShortKey sk = { "Redo", convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys ~= sk;
			}		

			result = root.query.descendant("shortkeys").attribute("defintion");
			foreach( e; result )
			{
				ShortKey sk = { "Goto Defintion", convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys ~= sk;
			}	

			result = root.query.descendant("shortkeys").attribute("quickrun");
			foreach( e; result )
			{
				ShortKey sk = { "Quick Run", convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys ~= sk;
			}	

			result = root.query.descendant("shortkeys").attribute("run");
			foreach( e; result )
			{
				ShortKey sk = { "Run", convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys ~= sk;
			}	

			result = root.query.descendant("shortkeys").attribute("build");
			foreach( e; result )
			{
				ShortKey sk = { "Build", convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys ~= sk;
			}	

			result = root.query.descendant("shortkeys").attribute("outlinewindow");
			foreach( e; result )
			{
				ShortKey sk = { "On/Off Left-side Window", convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys ~= sk;
			}	

			result = root.query.descendant("shortkeys").attribute("messagewindow");
			foreach( e; result )
			{
				ShortKey sk = { "On/Off Bottom-side Window", convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys ~= sk;
			}

			result = root.query.descendant("shortkeys").attribute("showtype");
			foreach( e; result )
			{
				ShortKey sk = { "Show Type", convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys ~= sk;
			}

			result = root.query.descendant("shortkeys").attribute("reparse");
			foreach( e; result )
			{
				ShortKey sk = { "Reparse", convertShortKeyValue2Integer( e.value ) };
				GLOBAL.shortKeys ~= sk;
			}			

			scope fileCompilerOptions = new UnicodeFile!(char)( "settings\\compilerOptions.txt", Encoding.Unknown );
			GLOBAL.txtCompilerOptions = fileCompilerOptions.read;
		}
		catch
		{


		}
	}
}

extern(C) // Callback for CPreferenceDialog
{
	int CPreferenceDialog_OpenCompileBinFile_cb()
	{
		scope fileSecectDlg = new CFileDlg( "Open File..." );
		char[] fileName = fileSecectDlg.getFileName();

		if( fileName.length )
		{
			GLOBAL.compilerFullPath = fileName;
			Ihandle* _compilePath_Handle = IupGetHandle( "compilerPath_Handle" );
			if( _compilePath_Handle != null ) IupSetAttribute( _compilePath_Handle, "VALUE", toStringz( fileName ) );
		}
		else
		{
			//Stdout( "NoThing!!!" ).newline;
		}

		return IUP_DEFAULT;
	}

	int CPreferenceDialog_shortCutList_DBLCLICK_CB( Ihandle *ih, int item, char *text )
	{
		scope skDialog = new CShortCutDialog( 300, 140, item, fromStringz( text ).dup );
		skDialog.show( IUP_CENTERPARENT, IUP_CENTERPARENT );

		return IUP_DEFAULT;
	}

	int CPreferenceDialog_fontList_DBLCLICK_CB( Ihandle *ih, int item, char *text )
	{
		char[] listString = fromStringz( text ).dup;
		char[] _ls;
		
		if( listString.length > 10 ) _ls = listString[10..length].dup; else return IUP_DEFAULT;

		// Set IupFontDlg
		Ihandle* dlg = IupFontDlg();
		IupSetAttribute( dlg, "VALUE", toStringz( _ls.dup, GLOBAL.stringzTemp ) ); delete GLOBAL.stringzTemp;
		IupSetAttribute( dlg, "TITLE", toStringz( "Font", GLOBAL.stringzTemp ) ); delete GLOBAL.stringzTemp;

		// Open IupFontDlg
		IupPopup( dlg, IUP_CURRENT, IUP_CURRENT );

		if( IupGetInt( dlg, "STATUS" ) )
		{
			char[] fontInformation = fromStringz( IupGetAttribute( dlg, "VALUE" ) ).dup;

			char[][] strings = Util.split( fontInformation, "," );
			if( strings.length == 2 )
			{
				char[] Bold, Italic, Underline, Strikeout, size;

				if( !strings[0].length )
				{
					version( Windows )
					{
						strings[0] = "Courier New";
					}
					else
					{
						strings[0] = "Monospace";
					}
				}
				else
				{
					strings[0] = Util.trim( strings[0] );
				}
				strings[1] = Util.trim( strings[1] );

				foreach( char[] s; Util.split( strings[1], " " ) )
				{
					switch( s )
					{
						case "Bold":		Bold = s;		break;
						case "Italic":		Italic = s;		break;
						case "Underline":	Underline = s;	break;
						case "Strikeout":	Strikeout = s;	break;
						default:
							size = s;
					}
				}

				char[] _string = Stdout.layout.convert( "{,-10} {,-18},{,-4} {,-6} {,-9} {,-9} {,-3}", GLOBAL.fonts[item-1].name, strings[0], Bold, Italic, Underline, Strikeout, size );
				IupSetAttribute( ih, toStringz( Integer.toString( item ) ), toStringz( _string ) );
			}
		}

		IupDestroy( dlg ); 

		return IUP_DEFAULT;
	}

	

	int CPreferenceDialog_btnOK_cb( Ihandle* ih )
	{
		GLOBAL.editorSetting00.LineMargin			= fromStringz(IupGetAttribute( IupGetHandle( "toggleLineMargin" ), "VALUE" )).dup;
		GLOBAL.editorSetting00.BookmarkMargin		= fromStringz(IupGetAttribute( IupGetHandle( "toggleBookmarkMargin" ), "VALUE" )).dup;
		GLOBAL.editorSetting00.FoldMargin			= fromStringz(IupGetAttribute( IupGetHandle( "toggleFoldMargin" ), "VALUE" )).dup;
		GLOBAL.editorSetting00.IndentGuide			= fromStringz(IupGetAttribute( IupGetHandle( "toggleFoldMargin" ), "VALUE" )).dup;
		GLOBAL.editorSetting00.CaretLine			= fromStringz(IupGetAttribute( IupGetHandle( "toggleCaretLine" ), "VALUE" )).dup;
		GLOBAL.editorSetting00.WordWrap				= fromStringz(IupGetAttribute( IupGetHandle( "toggleWordWrap" ), "VALUE" )).dup;
		GLOBAL.editorSetting00.TabUseingSpace		= fromStringz(IupGetAttribute( IupGetHandle( "toggleTabUseingSpace" ), "VALUE" )).dup;
		GLOBAL.editorSetting00.AutoIndent			= fromStringz(IupGetAttribute( IupGetHandle( "toggleAutoIndent" ), "VALUE" )).dup;
		GLOBAL.editorSetting00.TabWidth				= fromStringz(IupGetAttribute( IupGetHandle( "textTabWidth" ), "VALUE" )).dup;

		Ihandle* _ft = IupGetHandle( "fontList" );
		if( _ft != null )
		{
			for( int i = 0; i < GLOBAL.fonts.length; ++ i )
			{
				char[]	result;
				
				char[]	fontInformation = fromStringz( IupGetAttribute( _ft, toStringz( Integer.toString( i + 1 ) ) ) ).dup;
				char[][] strings = Util.split( fontInformation[10..length] , "," );
				
				if( strings.length == 2 )
				{
					result ~= ( Util.trim( strings[0] ) ~ "," );

					foreach( char[] s; Util.split( Util.trim( strings[1] ), " " ) )
					{
						s = Util.trim( s );
						if( s.length )	result ~= ( " " ~ s );
					}

					GLOBAL.fonts[i].name = Util.trim( fontInformation[0..10] );
					GLOBAL.fonts[i].fontString = result;
				}			
			}
		}


		GLOBAL.editColor.caretLine					= fromStringz(IupGetAttribute( IupGetHandle( "btnCaretLine" ), "BGCOLOR" )).dup;
		GLOBAL.editColor.cursor						= fromStringz(IupGetAttribute( IupGetHandle( "btnCursor" ), "BGCOLOR" )).dup;

		GLOBAL.editColor.selectionFore				= fromStringz(IupGetAttribute( IupGetHandle( "btnSelectFore" ), "BGCOLOR" )).dup;
		GLOBAL.editColor.selectionBack				= fromStringz(IupGetAttribute( IupGetHandle( "btnSelectBack" ), "BGCOLOR" )).dup;
		GLOBAL.editColor.linenumFore				= fromStringz(IupGetAttribute( IupGetHandle( "btnLinenumFore" ), "BGCOLOR" )).dup;
		GLOBAL.editColor.linenumBack				= fromStringz(IupGetAttribute( IupGetHandle( "btnLinenumBack" ), "BGCOLOR" )).dup;
		GLOBAL.editColor.fold						= fromStringz(IupGetAttribute( IupGetHandle( "btnFoldingColor" ), "BGCOLOR" )).dup;


		GLOBAL.autoCompletionTriggerWordCount		= Integer.atoi( fromStringz(IupGetAttribute( IupGetHandle( "textTrigger" ), "VALUE" ) ).dup );

		GLOBAL.compilerFullPath						= fromStringz( IupGetAttribute( IupGetHandle( "compilerPath_Handle" ), "VALUE" ) ).dup;

		if( GLOBAL.fonts.length == 9 )
		{
			foreach( CScintilla cSci; GLOBAL.scintillaManager )
			{
				if( cSci !is null ) cSci.setGlobalSetting();
			}			
			IupSetAttribute( GLOBAL.projectViewTabs, "FONT", toStringz( GLOBAL.fonts[2].fontString ) ); // Leftside
			IupSetAttribute( GLOBAL.fileListTree, "FONT", toStringz( GLOBAL.fonts[3].fontString ) ); // Filelist
			IupSetAttribute( GLOBAL.projectTree.getTreeHandle, "FONT", toStringz( GLOBAL.fonts[4].fontString ) ); // Project
			IupSetAttribute( GLOBAL.outlineTree.getZBoxHandle, "FONT", toStringz( GLOBAL.fonts[5].fontString ) ); // Outline
			IupSetAttribute( GLOBAL.messageWindowTabs, "FONT", toStringz( GLOBAL.fonts[6].fontString ) ); // Bottom
			IupSetAttribute( GLOBAL.outputPanel, "FONT", toStringz( GLOBAL.fonts[7].fontString ) ); // Output
			IupSetAttribute( GLOBAL.searchOutputPanel, "FONT", toStringz( GLOBAL.fonts[8].fontString ) ); // Search
		}

		// Save Setup to Xml
		CPreferenceDialog.save();

		return IUP_CLOSE;
	}

	int CPreferenceDialog_colorChoose_cb( Ihandle* ih )
	{
		Ihandle* dlg = IupColorDlg();

		IupSetAttribute( dlg, "VALUE", IupGetAttribute( ih, "BGCOLOR" ) );
		//IupSetAttribute(dlg, "ALPHA", "142");
		IupSetAttribute(dlg, "SHOWHEX", "YES");
		IupSetAttribute(dlg, "SHOWCOLORTABLE", "YES");
		IupSetAttribute(dlg, "TITLE", "IupColorDlg");
		//IupSetCallback(dlg, "HELP_CB", (Icallback)help_cb);

		IupPopup( dlg, IUP_CURRENT, IUP_CURRENT );
		IupSetAttribute( ih, "BGCOLOR", IupGetAttribute( dlg, "VALUE" ) );
	

		return IUP_DEFAULT;
	}
}	
