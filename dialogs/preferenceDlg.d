module dialogs.preferenceDlg;

private import iup.iup, iup.iup_scintilla;

private import global, project, scintilla, actionManager;
private import dialogs.baseDlg, dialogs.helpDlg, dialogs.fileDlg;

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

		

		Ihandle* labelDebugger = IupLabel( "debugger Path:" );
		IupSetAttributes( labelDebugger, "VISIBLELINES=1,VISIBLECOLUMNS=1" );
		
		textDebuggerPath = IupText( null );
		IupSetAttribute( textDebuggerPath, "SIZE", "180x12" );
		IupSetAttribute( textDebuggerPath, "VALUE", toStringz(GLOBAL.debuggerFullPath) );
		IupSetHandle( "debuggerPath_Handle", textDebuggerPath );
		
		Ihandle* btnOpenDebugger = IupButton( null, null );
		IupSetAttribute( btnOpenDebugger, "IMAGE", "icon_openfile" );
		IupSetCallback( btnOpenDebugger, "ACTION", cast(Icallback) &CPreferenceDialog_OpenCompileBinFile_cb );

		Ihandle* hBox02 = IupHbox( labelDebugger, textDebuggerPath, btnOpenDebugger, null );
		IupSetAttribute( hBox02, "ALIGNMENT", "ACENTER" );

		Ihandle* vBoxPage01 = IupVbox( hBox01, hBox02, null );



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


		Ihandle* labelFontName = IupLabel( "Font name:" );
		Ihandle* textFontName = IupText( null );
		IupSetAttribute( textFontName, "SIZE", "120x12" );
		IupSetAttribute( textFontName, "VALUE", toStringz(GLOBAL.editFont.name) );
		IupSetHandle( "textFontName", textFontName );
		
		Ihandle* labelFontSize = IupLabel( "Font size:" );
		Ihandle* textFontSize = IupText( null );
		IupSetAttribute( textFontSize, "SIZE", "30x12" );
		IupSetAttribute( textFontSize, "VALUE", toStringz(GLOBAL.editFont.size) );
		IupSetHandle( "textFontSize", textFontSize );

		Ihandle* btnFont = IupButton( "...", null );
		//IupSetAttribute( btnFont, "IMAGE", "icon_openfile" );
		IupSetCallback( btnFont, "ACTION", cast(Icallback) &CPreferenceDialog_btnFont_cb );
		
		Ihandle* hBoxFont00 = IupHbox( labelFontName, textFontName, labelFontSize, textFontSize, btnFont, null );
		IupSetAttributes( hBoxFont00, "EXPAND=YES,ALIGNMENT=ACENTER,MARGIN=0x0");


		Ihandle* toggleFontBold = IupToggle( "Bold", null );
		IupSetAttribute( toggleFontBold, "VALUE", toStringz(GLOBAL.editFont.bold) );
		IupSetHandle( "toggleFontBold", toggleFontBold );
		
		Ihandle* toggleFontItalic = IupToggle( "Italic", null );
		IupSetAttribute( toggleFontItalic, "VALUE", toStringz(GLOBAL.editFont.italic) );
		IupSetHandle( "toggleFontItalic", toggleFontItalic );
		
		Ihandle* toggleFontUnderline = IupToggle( "Underline", null );
		IupSetAttribute( toggleFontUnderline, "VALUE", toStringz(GLOBAL.editFont.underline) );
		IupSetHandle( "toggleFontUnderline", toggleFontUnderline );

		Ihandle* labelFontForeground = IupLabel( "Foreground:" );
		Ihandle* btnFontForeground = IupButton( null, null );
		IupSetAttribute( btnFontForeground, "BGCOLOR", toStringz(GLOBAL.editFont.foreColor) );
		IupSetAttribute( btnFontForeground, "SIZE", "16x8" );
		IupSetHandle( "btnFontForeground", btnFontForeground );
		IupSetCallback( btnFontForeground, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		
		Ihandle* labelFontBackground = IupLabel( "Background:" );
		Ihandle* btnFontBackground = IupButton( null, null );
		IupSetAttribute( btnFontBackground, "BGCOLOR", toStringz(GLOBAL.editFont.backColor) );
		IupSetAttribute( btnFontBackground, "SIZE", "16x8" );
		IupSetHandle( "btnFontBackground", btnFontBackground );
		IupSetCallback( btnFontBackground, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		

		Ihandle* hBoxFont01 = IupHbox( toggleFontBold, toggleFontItalic, toggleFontUnderline, labelFontForeground, btnFontForeground, labelFontBackground, btnFontBackground, null );
		IupSetAttributes( hBoxFont01, "EXPAND=YES,ALIGNMENT=ACENTER,MARGIN=0x0");


		Ihandle* vBoxFont00 = IupVbox( hBoxFont00, hBoxFont01, null );
		

		Ihandle* frameFont = IupFrame( vBoxFont00 );
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

		IupSetAttribute( vBoxPage01, "TABTITLE", "Compiler" );
		IupSetAttribute( vBoxPage02, "TABTITLE", "Editor(1)" );
		IupSetAttribute( vBoxPage01, "EXPAND", "YES" );
		
		Ihandle* preferenceTabs = IupTabs( vBoxPage01, vBoxPage02, null );
		IupSetAttribute( preferenceTabs, "TABTYPE", "TOP" );
		IupSetAttribute( preferenceTabs, "EXPAND", "YES" );

		
		Ihandle* vBox = IupVbox( preferenceTabs, bottom, null );
		IupSetAttributes( vBox, "ALIGNMENT=ACENTER,MARGIN=10x10,GAP=5" );

		IupAppend( _dlg, vBox );

		// Set btnOK Action
		IupSetCallback( btnOK, "ACTION", cast(Icallback) &CPreferenceDialog_btnOK_cb );
	}

	public:
	this( int w, int h, char[] title, bool bResize = true, char[] parent = "MAIN_DIALOG" )
	{
		super( w, h, title, bResize, parent );
		IupSetAttribute( _dlg, "MINBOX", "NO" );
		 
		createLayout();
	}

	~this()
	{
		IupSetHandle( "compilerPath_Handle", null );

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

		//<font name="Consolas" size="11" bold="OFF" italic="OFF" underline="OFF" forecolor="0 0 0" backcolor="255 255 255"></font>
		editorNode.element( null, "font" )
		.attribute( null, "name", GLOBAL.editFont.name )
		.attribute( null, "size", GLOBAL.editFont.size )
		.attribute( null, "bold", GLOBAL.editFont.bold )
		.attribute( null, "italic", GLOBAL.editFont.italic )
		.attribute( null, "underline", GLOBAL.editFont.underline )
		.attribute( null, "forecolor", GLOBAL.editFont.foreColor )
		.attribute( null, "backcolor", GLOBAL.editFont.backColor );

		//<color caretLine="255 255 0" cursor="0 0 0" selectionFore="255 255 255" selectionBack="0 0 255" linenumFore="0 0 0" linenumBack="200 200 200" fold="200 208 208"></color>
		editorNode.element( null, "color" )
		.attribute( null, "caretLine", GLOBAL.editColor.caretLine )
		.attribute( null, "cursor", GLOBAL.editColor.cursor )
		.attribute( null, "selectionFore", GLOBAL.editColor.selectionFore )
		.attribute( null, "selectionBack", GLOBAL.editColor.selectionBack )
		.attribute( null, "linenumFore", GLOBAL.editColor.linenumFore )
		.attribute( null, "linenumBack", GLOBAL.editColor.linenumBack )
		.attribute( null, "fold", GLOBAL.editColor.fold );

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
		// Loading Key Word...
		scope file = new UnicodeFile!(char)( "settings\\editorSettings.xml", Encoding.Unknown );
		//scope file  = cast(char[]) File.get( "settings\\editorSettings.xml" );

		scope doc = new Document!( char );
		doc.parse( file.read );

		auto root = doc.elements;
		auto result = root.query.descendant("keywords").attribute("value");

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



		scope fileCompilerOptions = new UnicodeFile!(char)( "settings\\compilerOptions.txt", Encoding.Unknown );
		GLOBAL.txtCompilerOtions = fileCompilerOptions.read;
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
			if( _compilePath_Handle != null ) IupSetAttribute( _compilePath_Handle, "VALUE", fileName.ptr );
		}
		else
		{
			//Stdout( "NoThing!!!" ).newline;
		}

		return IUP_DEFAULT;
	}

	int CPreferenceDialog_btnOK_cb( Ihandle* ih )
	{
		GLOBAL.editorSetting00.LineMargin			= fromStringz(IupGetAttribute( IupGetHandle( "toggleLineMargin" ), "VALUE" ));
		GLOBAL.editorSetting00.BookmarkMargin		= fromStringz(IupGetAttribute( IupGetHandle( "toggleBookmarkMargin" ), "VALUE" ));
		GLOBAL.editorSetting00.FoldMargin			= fromStringz(IupGetAttribute( IupGetHandle( "toggleFoldMargin" ), "VALUE" ));
		GLOBAL.editorSetting00.IndentGuide			= fromStringz(IupGetAttribute( IupGetHandle( "toggleFoldMargin" ), "VALUE" ));
		GLOBAL.editorSetting00.CaretLine			= fromStringz(IupGetAttribute( IupGetHandle( "toggleCaretLine" ), "VALUE" ));
		GLOBAL.editorSetting00.WordWrap				= fromStringz(IupGetAttribute( IupGetHandle( "toggleWordWrap" ), "VALUE" ));
		GLOBAL.editorSetting00.TabUseingSpace		= fromStringz(IupGetAttribute( IupGetHandle( "toggleTabUseingSpace" ), "VALUE" ));
		GLOBAL.editorSetting00.AutoIndent			= fromStringz(IupGetAttribute( IupGetHandle( "toggleAutoIndent" ), "VALUE" ));
		GLOBAL.editorSetting00.TabWidth				= fromStringz(IupGetAttribute( IupGetHandle( "textTabWidth" ), "VALUE" ));

		GLOBAL.editFont.name						= fromStringz(IupGetAttribute( IupGetHandle( "textFontName" ), "VALUE" ));
		GLOBAL.editFont.size						= fromStringz(IupGetAttribute( IupGetHandle( "textFontSize" ), "VALUE" ));
		GLOBAL.editFont.bold						= fromStringz(IupGetAttribute( IupGetHandle( "toggleFontBold" ), "VALUE" ));
		GLOBAL.editFont.italic						= fromStringz(IupGetAttribute( IupGetHandle( "toggleFontItalic" ), "VALUE" ));
		GLOBAL.editFont.underline					= fromStringz(IupGetAttribute( IupGetHandle( "toggleFontUnderline" ), "VALUE" ));
		GLOBAL.editFont.foreColor					= fromStringz(IupGetAttribute( IupGetHandle( "btnFontForeground" ), "BGCOLOR" ));
		GLOBAL.editFont.backColor					= fromStringz(IupGetAttribute( IupGetHandle( "btnFontBackground" ), "BGCOLOR" ));


		GLOBAL.editColor.caretLine					= fromStringz(IupGetAttribute( IupGetHandle( "btnCaretLine" ), "BGCOLOR" ));
		GLOBAL.editColor.cursor						= fromStringz(IupGetAttribute( IupGetHandle( "btnCursor" ), "BGCOLOR" ));

		GLOBAL.editColor.selectionFore				= fromStringz(IupGetAttribute( IupGetHandle( "btnSelectFore" ), "BGCOLOR" ));
		GLOBAL.editColor.selectionBack				= fromStringz(IupGetAttribute( IupGetHandle( "btnSelectBack" ), "BGCOLOR" ));
		GLOBAL.editColor.linenumFore				= fromStringz(IupGetAttribute( IupGetHandle( "btnLinenumFore" ), "BGCOLOR" ));
		GLOBAL.editColor.linenumBack				= fromStringz(IupGetAttribute( IupGetHandle( "btnLinenumBack" ), "BGCOLOR" ));
		GLOBAL.editColor.fold						= fromStringz(IupGetAttribute( IupGetHandle( "btnFoldingColor" ), "BGCOLOR" ));
		

		foreach( CScintilla cSci; GLOBAL.scintillaManager )
		{
			if( cSci !is null ) cSci.setGlobalSetting();
		}

		// Save Setup to Xml
		CPreferenceDialog.save();

		return IUP_CLOSE;
	}

	int CPreferenceDialog_btnFont_cb( Ihandle* ih )
	{
		Ihandle* dlg = IupFontDlg();
		IupSetAttribute(dlg, "COLOR", "128 0 255");
		IupSetAttribute(dlg, "VALUE", "Times New Roman, Bold 20");
		IupSetAttribute(dlg, "TITLE", "IupFontDlg Test");
				
		IupPopup( dlg, IUP_CURRENT, IUP_CURRENT );

		if( IupGetInt( dlg, "STATUS" ) )
		{
			char[] fontInformation = fromStringz( IupGetAttribute( dlg, "VALUE" ) );
			int commaPos = Util.index( fontInformation, "," );

			if( commaPos <= fontInformation.length )
			{
				GLOBAL.editFont.name = fontInformation[0..commaPos];
				Ihandle* _ih = IupGetHandle( "textFontName" );
				if( _ih != null ) IupSetAttribute( _ih, "VALUE", toStringz(GLOBAL.editFont.name) );
				
				char[][] fontSizeInformation = Util.split( Util.trim( fontInformation[commaPos+1..length] ), " " );
				if( fontSizeInformation.length )
				{
					GLOBAL.editFont.size = fontSizeInformation[length-1];
					_ih = IupGetHandle( "textFontSize" );
					if( _ih != null ) IupSetAttribute( _ih, "VALUE", toStringz(GLOBAL.editFont.size) );
				}
			}
		}

		return IUP_DEFAULT;
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
