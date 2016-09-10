module dialogs.preferenceDlg;

private import iup.iup, iup.iup_scintilla;

private import global, project, tools, scintilla, actionManager;
private import dialogs.baseDlg, dialogs.helpDlg, dialogs.fileDlg, dialogs.shortcutDlg;

private import tango.stdc.stringz, Integer = tango.text.convert.Integer, Util = tango.text.Util;
private import tango.text.xml.Document, tango.text.xml.DocPrinter, tango.io.UnicodeFile;
private import tango.io.Stdout;

class CPreferenceDialog : CBaseDialog
{
	private:
	//import tango.io.device.File;
	
	Ihandle* textCompilerPath, textDebuggerPath;

	void createLayout()
	{
		Ihandle* bottom = createDlgButton();

		Ihandle* labelCompiler = IupLabel( "Compiler Path:" );
		IupSetAttributes( labelCompiler, "VISIBLELINES=1,VISIBLECOLUMNS=1" );
		//IupSetAttribute( labelCompiler, "FONT", "Consolas, 10" );
		
		textCompilerPath = IupText( null );
		IupSetAttribute( textCompilerPath, "SIZE", "185x12" );
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
		IupSetAttribute( textDebuggerPath, "SIZE", "185x12" );
		IupSetAttribute( textDebuggerPath, "VALUE", toStringz(GLOBAL.debuggerFullPath) );
		IupSetHandle( "debuggerPath_Handle", textDebuggerPath );
		
		Ihandle* btnOpenDebugger = IupButton( null, null );
		IupSetAttribute( btnOpenDebugger, "IMAGE", "icon_openfile" );
		IupSetCallback( btnOpenDebugger, "ACTION", cast(Icallback) &CPreferenceDialog_OpenDebuggerBinFile_cb );

		Ihandle* hBox02 = IupHbox( labelDebugger, textDebuggerPath, btnOpenDebugger, null );
		IupSetAttribute( hBox02, "ALIGNMENT", "ACENTER" );
		

		Ihandle* labelDefaultOption = IupLabel( "Compiler Opts:" );
		IupSetAttributes( labelDefaultOption, "VISIBLELINES=1,VISIBLECOLUMNS=1" );
		
		Ihandle* textDefaultOption = IupText( null );
		IupSetAttribute( textDefaultOption, "SIZE", "185x12" );
		IupSetAttribute( textDefaultOption, "VALUE", toStringz( GLOBAL.defaultOption.dup ) );
		IupSetHandle( "defaultOption_Handle", textDefaultOption );

		Ihandle* btnCompilerOpts = IupButton( null, null );
		IupSetAttributes( btnCompilerOpts, "IMAGE=icon_help" );
		IupSetCallback( btnCompilerOpts, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			GLOBAL.compilerHelpDlg.show( IUP_MOUSEPOS, IUP_MOUSEPOS );
		});	


		Ihandle* hBox03 = IupHbox( labelDefaultOption, textDefaultOption, btnCompilerOpts, null );
		IupSetAttribute( hBox03, "ALIGNMENT", "ACENTER" );



		// compiler Setting
		Ihandle* toggleAnnotation = IupToggle( "Show Compile Error/Warning Using Annotation", null );
		IupSetAttribute( toggleAnnotation, "VALUE", toStringz(GLOBAL.compilerAnootation.dup) );
		IupSetHandle( "toggleAnnotation", toggleAnnotation );
		
		Ihandle* toggleShowResultWindow = IupToggle( "Show Result Window", null );
		IupSetAttribute( toggleShowResultWindow, "VALUE", toStringz(GLOBAL.compilerWindow.dup) );
		IupSetHandle( "toggleShowResultWindow", toggleShowResultWindow );

		Ihandle* vBoxCompiler = IupVbox( toggleAnnotation, toggleShowResultWindow, null );

		Ihandle* frameCompiler = IupFrame( vBoxCompiler );
		IupSetAttribute( frameCompiler, "TITLE", "Compiler Setting");
		IupSetAttributes( frameCompiler, "EXPANDCHILDREN=YES,SIZE=261x");

		// Parser Setting
		Ihandle* toggleKeywordComplete = IupToggle( "Enable Keyword Autocomplete", null );
		IupSetAttribute( toggleKeywordComplete, "VALUE", toStringz(GLOBAL.enableKeywordComplete.dup) );
		IupSetHandle( "toggleKeywordComplete", toggleKeywordComplete );
		
		Ihandle* toggleUseParser = IupToggle( "Enable Parser", null );
		IupSetAttribute( toggleUseParser, "VALUE", toStringz(GLOBAL.enableParser.dup) );
		IupSetHandle( "toggleUseParser", toggleUseParser );
		
		Ihandle* labelTrigger = IupLabel( "Autocompletion Trigger:" );
		IupSetAttributes( labelTrigger, "SIZE=100x12" );
		
		Ihandle* textTrigger = IupText( null );
		IupSetAttribute( textTrigger, "SIZE", "30x12" );
		IupSetAttribute( textTrigger, "TIP", "Set 0 to disable auto complete" );
		IupSetAttribute( textTrigger, "VALUE", toStringz( Integer.toString( GLOBAL.autoCompletionTriggerWordCount ) ) );
		IupSetHandle( "textTrigger", textTrigger );

		Ihandle* labelIncludeLevel = IupLabel( "Include Levels:" );
		IupSetAttributes( labelIncludeLevel, "SIZE=100x12,GAP=0" );
		
		Ihandle* textIncludeLevel = IupText( null );
		IupSetAttribute( textIncludeLevel, "SIZE", "30x12" );
		IupSetAttribute( textIncludeLevel, "VALUE", toStringz( Integer.toString( GLOBAL.includeLevel ) ) );
		IupSetHandle( "textIncludeLevel", textIncludeLevel );

		

		Ihandle* toggleFunctionTitle = IupToggle( "Show Function Title", null );
		IupSetAttribute( toggleFunctionTitle, "VALUE", toStringz(GLOBAL.showFunctionTitle.dup) );
		IupSetHandle( "toggleFunctionTitle", toggleFunctionTitle );

		Ihandle* toggleWithParams = IupToggle( "Show Type With Function Parameters", null );
		IupSetAttribute( toggleWithParams, "VALUE", toStringz(GLOBAL.showTypeWithParams.dup) );
		IupSetHandle( "toggleWithParams", toggleWithParams );

		Ihandle* toggleIGNORECASE = IupToggle( "Autocomplete List Sort Is Ignore Case", null );
		IupSetAttribute( toggleIGNORECASE, "VALUE", toStringz(GLOBAL.toggleIgnoreCase.dup) );
		IupSetHandle( "toggleIGNORECASE", toggleIGNORECASE );

		Ihandle* toggleCASEINSENSITIVE = IupToggle( "Selection Of Autocomplete List Is Case Insensitive", null );
		IupSetAttribute( toggleCASEINSENSITIVE, "VALUE", toStringz(GLOBAL.toggleCaseInsensitive.dup) );
		IupSetHandle( "toggleCASEINSENSITIVE", toggleCASEINSENSITIVE );

		Ihandle* toggleSHOWLISTTYPE = IupToggle( "Show Autocomplete List Type", null );
		IupSetAttribute( toggleSHOWLISTTYPE, "VALUE", toStringz(GLOBAL.toggleShowListType.dup) );
		IupSetHandle( "toggleSHOWLISTTYPE", toggleSHOWLISTTYPE );

		Ihandle* toggleSHOWALLMEMBER = IupToggle( "Show All Members( public, protected, private )", null );
		IupSetAttribute( toggleSHOWALLMEMBER, "VALUE", toStringz(GLOBAL.toggleShowAllMember.dup) );
		IupSetHandle( "toggleSHOWALLMEMBER", toggleSHOWALLMEMBER );


		Ihandle* toggleLiveNone = IupToggle( "None", null );
		IupSetHandle( "toggleLiveNone", toggleLiveNone );

		Ihandle* toggleLiveLight = IupToggle( "Light", null );
		IupSetHandle( "toggleLiveLight", toggleLiveLight );
		
		Ihandle* toggleLiveFull = IupToggle( "Full", null );
		IupSetHandle( "toggleLiveFull", toggleLiveFull );
		//IupSetAttribute( toggleLiveFull, "ACTIVE", "NO" );

		Ihandle* toggleUpdateOutline = IupToggle( "Update Outline", null );
		IupSetAttribute( toggleUpdateOutline, "VALUE", toStringz(GLOBAL.toggleUpdateOutlineLive.dup) );
		//IupSetAttribute( toggleUpdateOutline, "ACTIVE", "NO" );
		IupSetHandle( "toggleUpdateOutline", toggleUpdateOutline );

		switch( GLOBAL.liveLevel )
		{
			case 1:		IupSetAttribute( toggleLiveLight, "VALUE", "ON" ); break;
			case 2:		IupSetAttribute( toggleLiveFull, "VALUE", "ON" ); break;
			default:	IupSetAttribute( toggleLiveNone, "VALUE", "ON" ); break;
		}

		Ihandle* hBoxLive = IupHbox( toggleLiveNone, toggleLiveLight, toggleLiveFull, null );
		IupSetAttributes( hBoxLive, "ALIGNMENT=ACENTER,NORMALIZESIZE=HORIZONTAL,HOMOGENEOUS=YES,EXPANDCHILDREN=YES" );
		Ihandle* radioLive = IupRadio( hBoxLive );

		Ihandle* hBoxLive2 = IupHbox( radioLive, toggleUpdateOutline, null );
		IupSetAttributes( hBoxLive2, "GAP=30,MARGIN=10x,ALIGNMENT=ACENTER" );
		//IupSetAttributes( hBoxLive2, "ALIGNMENT=ACENTER,NORMALIZESIZE=HORIZONTAL,HOMOGENEOUS=YES,EXPANDCHILDREN=YES" );
		
		Ihandle* frameLive = IupFrame( hBoxLive2 );
		IupSetAttributes( frameLive, "SIZE=261x" );
		IupSetAttribute( frameLive, "TITLE", "ParseLive! Level");



		Ihandle* hBox00 = IupHbox( labelTrigger, textTrigger, null );
		Ihandle* hBox00_1 = IupHbox( labelIncludeLevel, textIncludeLevel, null );
		Ihandle* vBox00 = IupVbox( toggleKeywordComplete, toggleUseParser, toggleFunctionTitle, toggleWithParams, toggleIGNORECASE, toggleCASEINSENSITIVE, toggleSHOWLISTTYPE, toggleSHOWALLMEMBER, frameLive, hBox00, hBox00_1, null );
		IupSetAttributes( vBox00, "GAP=5,MARGIN=0x1,EXPANDCHILDREN=YES" );
	
		Ihandle* frameParser = IupFrame( vBox00 );
		IupSetAttribute( frameParser, "TITLE", "Parser Setting");
		IupSetAttribute( frameParser, "EXPANDCHILDREN", "YES");
		IupSetAttribute( frameParser, "SIZE", "275x");
		
		Ihandle* vBoxPage01 = IupVbox( hBox01, hBox02, hBox03, frameCompiler, frameParser, null );
		IupSetAttributes( vBoxPage01, "ALIGNMENT=ALEFT,MARGIN=2x5");
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
		IupSetAttribute( toggleLineMargin, "VALUE", toStringz(GLOBAL.editorSetting00.LineMargin.dup) );
		IupSetHandle( "toggleLineMargin", toggleLineMargin );
		
		Ihandle* toggleBookmarkMargin = IupToggle( "Show book mark margin", null );
		IupSetAttribute( toggleBookmarkMargin, "VALUE", toStringz(GLOBAL.editorSetting00.BookmarkMargin.dup) );
		IupSetHandle( "toggleBookmarkMargin", toggleBookmarkMargin );
		
		Ihandle* toggleFoldMargin = IupToggle( "Show folding margin", null );
		IupSetAttribute( toggleFoldMargin, "VALUE", toStringz(GLOBAL.editorSetting00.FoldMargin.dup) );
		IupSetHandle( "toggleFoldMargin", toggleFoldMargin );
		
		Ihandle* toggleIndentGuide = IupToggle( "Show indentation guide", null );
		IupSetAttribute( toggleIndentGuide, "VALUE", toStringz(GLOBAL.editorSetting00.IndentGuide.dup) );
		IupSetHandle( "toggleIndentGuide", toggleIndentGuide );
		
		Ihandle* toggleCaretLine = IupToggle( "High light caret line", null );
		IupSetAttribute( toggleCaretLine, "VALUE", toStringz(GLOBAL.editorSetting00.CaretLine.dup) );
		IupSetHandle( "toggleCaretLine", toggleCaretLine );
		
		Ihandle* toggleWordWrap = IupToggle( "Word warp", null );
		IupSetAttribute( toggleWordWrap, "VALUE", toStringz(GLOBAL.editorSetting00.WordWrap.dup) );
		IupSetHandle( "toggleWordWrap", toggleWordWrap );
		
		Ihandle* toggleTabUseingSpace = IupToggle( "Replace tab by space", null );
		IupSetAttribute( toggleTabUseingSpace, "VALUE", toStringz(GLOBAL.editorSetting00.TabUseingSpace.dup) );
		IupSetHandle( "toggleTabUseingSpace", toggleTabUseingSpace );
		
		Ihandle* toggleAutoIndent = IupToggle( "Auto indent", null );
		IupSetAttribute( toggleAutoIndent, "VALUE", toStringz(GLOBAL.editorSetting00.AutoIndent.dup) );
		IupSetHandle( "toggleAutoIndent", toggleAutoIndent );

		Ihandle* toggleShowEOL = IupToggle( "Show EOL", null );
		IupSetAttribute( toggleShowEOL, "VALUE", toStringz(GLOBAL.editorSetting00.ShowEOL.dup) );
		IupSetHandle( "toggleShowEOL", toggleShowEOL );

		Ihandle* toggleShowSpace = IupToggle( "Show Space/Tab", null );
		IupSetAttribute( toggleShowSpace, "VALUE", toStringz(GLOBAL.editorSetting00.ShowSpace.dup) );
		IupSetHandle( "toggleShowSpace", toggleShowSpace );

		Ihandle* toggleAutoEnd = IupToggle( "Auto Insert Block End", null );
		IupSetAttribute( toggleAutoEnd, "VALUE", toStringz(GLOBAL.editorSetting00.AutoEnd.dup) );
		IupSetHandle( "toggleAutoEnd", toggleAutoEnd );

		Ihandle* toggleColorOutline = IupToggle( "Colorize Outline Item", null );
		IupSetAttribute( toggleColorOutline, "VALUE", toStringz(GLOBAL.editorSetting00.ColorOutline.dup) );
		IupSetHandle( "toggleColorOutline", toggleColorOutline );		



		Ihandle* labelTabWidth = IupLabel( "Tab Width:" );
		Ihandle* textTabWidth = IupText( null );
		IupSetAttribute( textTabWidth, "VALUE", toStringz(GLOBAL.editorSetting00.TabWidth) );
		IupSetHandle( "textTabWidth", textTabWidth );
		Ihandle* hBoxTab = IupHbox( labelTabWidth, textTabWidth, null );
		IupSetAttribute( hBoxTab, "ALIGNMENT", "ACENTER" );
		
		Ihandle* labelColumnEdge = IupLabel( "Column Edge:" );
		Ihandle* textColumnEdge = IupText( null );
		IupSetAttribute( textColumnEdge, "VALUE", toStringz(GLOBAL.editorSetting00.ColumnEdge) );
		IupSetAttribute( textColumnEdge, "TIP", toStringz( "Set 0 to disable" ) );
		IupSetHandle( "textColumnEdge", textColumnEdge );
		Ihandle* hBoxColumn = IupHbox( labelColumnEdge, textColumnEdge, null );
		IupSetAttribute( hBoxColumn, "ALIGNMENT", "ACENTER" );

			
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

			IupSetAttributes( toggleShowEOL, "" ),
			IupSetAttributes( toggleShowSpace, "" ),

			IupSetAttributes( toggleAutoEnd, "" ),
			IupSetAttributes( toggleColorOutline, "" ),

			IupSetAttributes( hBoxTab, "" ),
			IupSetAttributes( hBoxColumn, "" ),
			
			null
		);

		//IupSetAttribute(gbox, "SIZECOL", "1");
		//IupSetAttribute(gbox, "SIZELIN", "4");
		IupSetAttributes( gbox, "NUMDIV=2,ALIGNMENTLIN=ACENTER,GAPLIN=5,GAPCOL=20,MARGIN=0x0" );

		// fontList
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


		Ihandle* radioKeywordCase0 = IupToggle( "None", null );
		IupSetHandle( "radioKeywordCase0", radioKeywordCase0 );

		Ihandle* radioKeywordCase1 = IupToggle( "lowercase", null );
		IupSetHandle( "radioKeywordCase1", radioKeywordCase1 );
		
		Ihandle* radioKeywordCase2 = IupToggle( "UPPERCASE", null );
		IupSetHandle( "radioKeywordCase2", radioKeywordCase2 );

		Ihandle* radioKeywordCase3 = IupToggle( "Mixedcase", null );
		IupSetHandle( "radioKeywordCase3", radioKeywordCase3 );

		switch( GLOBAL.keywordCase )
		{
			case 0:		IupSetAttribute( radioKeywordCase0, "VALUE", "ON" ); break;
			case 1:		IupSetAttribute( radioKeywordCase1, "VALUE", "ON" ); break;
			case 2:		IupSetAttribute( radioKeywordCase2, "VALUE", "ON" ); break;
			default:	IupSetAttribute( radioKeywordCase3, "VALUE", "ON" ); break;
		}

		Ihandle* hBoxKeywordCase = IupHbox( radioKeywordCase0, radioKeywordCase1, radioKeywordCase2, radioKeywordCase3, null );
		IupSetAttributes( hBoxKeywordCase, "GAP=30,MARGIN=30x,ALIGNMENT=ACENTER" );
		Ihandle* radioKeywordCase = IupRadio( hBoxKeywordCase );

		Ihandle* frameKeywordCase = IupFrame( radioKeywordCase );
		IupSetAttributes( frameKeywordCase, "SIZE=270,GAP=1" );
		IupSetAttribute( frameKeywordCase, "TITLE", "Auto Convert Keyword Case");
		
		

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
		version(Windows) IupSetAttribute( btnCaretLine, "SIZE", "16x8" ); else IupSetAttribute( btnCaretLine, "SIZE", "16x12" );
		IupSetHandle( "btnCaretLine", btnCaretLine );
		IupSetCallback( btnCaretLine, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelCursor = IupLabel( "Cursor:" );
		Ihandle* btnCursor = IupButton( null, null );
		IupSetAttribute( btnCursor, "BGCOLOR", toStringz(GLOBAL.editColor.cursor) );
		version(Windows) IupSetAttribute( btnCursor, "SIZE", "16x8" ); else IupSetAttribute( btnCursor, "SIZE", "16x12" );
		IupSetHandle( "btnCursor", btnCursor );
		IupSetCallback( btnCursor, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelSelectFore = IupLabel( "Selection foreground:" );
		Ihandle* btnSelectFore = IupButton( null, null );
		IupSetAttribute( btnSelectFore, "BGCOLOR", toStringz(GLOBAL.editColor.selectionFore) );
		version(Windows) IupSetAttribute( btnSelectFore, "SIZE", "16x8" ); else IupSetAttribute( btnSelectFore, "SIZE", "16x12" );
		IupSetHandle( "btnSelectFore", btnSelectFore );
		IupSetCallback( btnSelectFore, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelSelectBack = IupLabel( "Selection background:" );
		Ihandle* btnSelectBack = IupButton( null, null );
		IupSetAttribute( btnSelectBack, "BGCOLOR", toStringz(GLOBAL.editColor.selectionBack) );
		version(Windows) IupSetAttribute( btnSelectBack, "SIZE", "16x8" ); else IupSetAttribute( btnSelectBack, "SIZE", "16x12" );
		IupSetHandle( "btnSelectBack", btnSelectBack );
		IupSetCallback( btnSelectBack, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelLinenumFore = IupLabel( "Linenumber foreground:" );
		Ihandle* btnLinenumFore = IupButton( null, null );
		IupSetAttribute( btnLinenumFore, "BGCOLOR", toStringz(GLOBAL.editColor.linenumFore) );
		version(Windows) IupSetAttribute( btnLinenumFore, "SIZE", "16x8" ); else IupSetAttribute( btnLinenumFore, "SIZE", "16x12" );
		IupSetHandle( "btnLinenumFore", btnLinenumFore );
		IupSetCallback( btnLinenumFore, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelLinenumBack = IupLabel( "Linenumber background:" );
		Ihandle* btnLinenumBack = IupButton( null, null );
		IupSetAttribute( btnLinenumBack, "BGCOLOR", toStringz(GLOBAL.editColor.linenumBack) );
		version(Windows) IupSetAttribute( btnLinenumBack, "SIZE", "16x8" ); else IupSetAttribute( btnLinenumBack, "SIZE", "16x12" );
		IupSetHandle( "btnLinenumBack", btnLinenumBack );
		IupSetCallback( btnLinenumBack, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelFoldingColor = IupLabel( "FoldingMargin color:" );
		Ihandle* btnFoldingColor = IupButton( null, null );
		IupSetAttribute( btnFoldingColor, "BGCOLOR", toStringz(GLOBAL.editColor.fold) );
		version(Windows) IupSetAttribute( btnFoldingColor, "SIZE", "16x8" ); else IupSetAttribute( btnFoldingColor, "SIZE", "16x12" );
		IupSetHandle( "btnFoldingColor", btnFoldingColor );
		IupSetCallback( btnFoldingColor, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelSelAlpha = IupLabel( "Selection Alpha:" );
		Ihandle* textAlpha = IupText( null );
		version(Windows)
		{
			IupSetAttributes( textAlpha, "SIZE=24x10,MARGIN=0x0,SPIN=YES,SPINMAX=255,SPINMIN=0" );
			IupSetAttribute( textAlpha, "SPINVALUE", toStringz( GLOBAL.editColor.selAlpha ) );
		}
		else
		{
			IupSetAttributes( textAlpha, "SIZE=24x10,MARGIN=0x0" );
			IupSetAttribute( textAlpha, "VALUE", toStringz( GLOBAL.editColor.selAlpha ) );
		}
		IupSetAttribute( textAlpha, "TIP", toStringz( "'255' will disable the alpha" ) );
		IupSetHandle( "textAlpha", textAlpha );



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
			IupSetAttributes( labelSelAlpha, "" ),
			IupSetAttributes( textAlpha, "" ),

			null
		);
		IupSetAttributes( gboxColor, "EXPAND=YES,NUMDIV=4,ALIGNMENTLIN=ACENTER,ALIGNMENTCOL=ALEFT,GAPLIN=5,GAPCOL=20,MARGIN=2x10,SIZELIN=2" );

		Ihandle* frameColor = IupFrame( gboxColor );
		IupSetAttributes( frameColor, "MARGIN=0x0,EXPAND=YES,EXPAND=HORIZONTAL" );
		IupSetAttribute( frameColor, "SIZE", "275x" );//IupGetAttribute( frameFont, "SIZE" ) );

		IupSetAttribute( frameColor, "TITLE", "Color");

		Ihandle* vBoxPage02 = IupVbox( gbox, frameKeywordCase, frameFont, frameColor, null );
		IupSetAttributes( vBoxPage02, "GAP=5,MARGIN=0x1,EXPANDCHILDREN=YES" );


		// Short Cut
		Ihandle* shortCutList = IupList( null );
		IupSetAttributes( shortCutList, "MULTIPLE=NO,MARGIN=10x10,VISIBLELINES=YES,EXPAND=YES,AUTOHIDE=YES" );
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


		Ihandle* keyWordText0 = IupText( null );
		IupSetAttributes( keyWordText0, "MULTILINE=YES,SCROLLBAR=VERTICAL,EXPAND=YES,WORDWRAP=YES" );
		IupSetAttribute( keyWordText0, "VALUE", toStringz( GLOBAL.KEYWORDS[0] ) );
		IupSetHandle( "keyWordText0", keyWordText0 );
		Ihandle* keyWordText1 = IupText( null );
		IupSetAttributes( keyWordText1, "MULTILINE=YES,SCROLLBAR=VERTICAL,EXPAND=YES,WORDWRAP=YES" );
		IupSetAttribute( keyWordText1, "VALUE", toStringz( GLOBAL.KEYWORDS[1] ) );
		IupSetHandle( "keyWordText1", keyWordText1 );
		Ihandle* keyWordText2 = IupText( null );
		IupSetAttributes( keyWordText2, "MULTILINE=YES,SCROLLBAR=VERTICAL,EXPAND=YES,WORDWRAP=YES" );
		IupSetAttribute( keyWordText2, "VALUE", toStringz( GLOBAL.KEYWORDS[2] ) );
		IupSetHandle( "keyWordText2", keyWordText2 );
		Ihandle* keyWordText3 = IupText( null );
		IupSetAttributes( keyWordText3, "MULTILINE=YES,SCROLLBAR=VERTICAL,EXPAND=YES,WORDWRAP=YES" );
		IupSetAttribute( keyWordText3, "VALUE", toStringz( GLOBAL.KEYWORDS[3] ) );
		IupSetHandle( "keyWordText3", keyWordText3 );


		Ihandle* labelKeyWord0 = IupLabel( "KeyWord0" );
		Ihandle* btnKeyWord0Color = IupButton( null, null );
		IupSetAttribute( btnKeyWord0Color, "BGCOLOR", toStringz(GLOBAL.editColor.keyWord[0]) );
		version(Windows) IupSetAttribute( btnKeyWord0Color, "SIZE", "24x8" ); else IupSetAttribute( btnKeyWord0Color, "SIZE", "24x12" );
		IupSetHandle( "btnKeyWord0Color", btnKeyWord0Color );
		IupSetCallback( btnKeyWord0Color, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelKeyWord1 = IupLabel( "KeyWord1" );
		Ihandle* btnKeyWord1Color = IupButton( null, null );
		IupSetAttribute( btnKeyWord1Color, "BGCOLOR", toStringz(GLOBAL.editColor.keyWord[1]) );
		version(Windows) IupSetAttribute( btnKeyWord1Color, "SIZE", "24x8" ); else IupSetAttribute( btnKeyWord1Color, "SIZE", "24x12" );
		IupSetHandle( "btnKeyWord1Color", btnKeyWord1Color );
		IupSetCallback( btnKeyWord1Color, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelKeyWord2 = IupLabel( "KeyWord2" );
		Ihandle* btnKeyWord2Color = IupButton( null, null );
		IupSetAttribute( btnKeyWord2Color, "BGCOLOR", toStringz(GLOBAL.editColor.keyWord[2]) );
		version(Windows) IupSetAttribute( btnKeyWord2Color, "SIZE", "24x8" ); else IupSetAttribute( btnKeyWord2Color, "SIZE", "24x12" );
		IupSetHandle( "btnKeyWord2Color", btnKeyWord2Color );
		IupSetCallback( btnKeyWord2Color, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelKeyWord3 = IupLabel( "KeyWord3" );
		Ihandle* btnKeyWord3Color = IupButton( null, null );
		IupSetAttribute( btnKeyWord3Color, "BGCOLOR", toStringz(GLOBAL.editColor.keyWord[3]) );
		version(Windows) IupSetAttribute( btnKeyWord3Color, "SIZE", "24x8" ); else IupSetAttribute( btnKeyWord3Color, "SIZE", "24x12" );
		IupSetHandle( "btnKeyWord3Color", btnKeyWord3Color );
		IupSetCallback( btnKeyWord3Color, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* gboxKeyWordColor = IupGridBox
		(
			IupSetAttributes( labelKeyWord0, "" ),
			IupSetAttributes( btnKeyWord0Color,"" ),
			IupSetAttributes( labelKeyWord1, "" ),
			IupSetAttributes( btnKeyWord1Color, "" ),

			IupSetAttributes( labelKeyWord2, "" ),
			IupSetAttributes( btnKeyWord2Color, "" ),
			IupSetAttributes( labelKeyWord3, "" ),
			IupSetAttributes( btnKeyWord3Color, "" ),

			null
		);
		IupSetAttributes( gboxKeyWordColor, "EXPAND=YES,NUMDIV=8,ALIGNMENTLIN=ACENTER,ALIGNMENTCOL=ALEFT,GAPLIN=0,GAPCOL=0,MARGIN=0x0,SIZELIN=0,HOMOGENEOUSCOL=YES" );


		Ihandle* keyWordVbox = IupVbox( keyWordText0, keyWordText1, keyWordText2, keyWordText3, gboxKeyWordColor, null );
		IupSetAttribute( keyWordVbox, "ALIGNMENT", toStringz( "ACENTER" ) );


		IupSetAttribute( vBoxPage01, "TABTITLE", "Compiler" );
		IupSetAttribute( vBoxPage02, "TABTITLE", "Editor" );
		IupSetAttribute( shortCutList, "TABTITLE", "Short Cut" );
		IupSetAttribute( keyWordVbox, "TABTITLE", "KeyWords" );
		IupSetAttribute( vBoxPage01, "EXPAND", "YES" );
		
		Ihandle* preferenceTabs = IupTabs( vBoxPage01, vBoxPage02, shortCutList, keyWordVbox, null );
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
		IupSetAttribute( _dlg, "ICON", "icon_preference" );
		version( Windows )
		{
			IupSetAttribute( _dlg, "FONT", GLOBAL.cString.convert( "Courier New,9" ) );
		}
		else
		{
			IupSetAttribute( _dlg, "FONT", GLOBAL.cString.convert( "FreeMono,Bold 9" ) );
		}
		 
		createLayout();
	}

	~this()
	{
		IupSetHandle( "compilerPath_Handle", null );
		IupSetHandle( "debuggerPath_Handle", null );
		IupSetHandle( "defaultOption_Handle", null );
		IupSetHandle( "textTrigger", null );
		IupSetHandle( "textIncludeLevel", null );
		IupSetHandle( "toggleFunctionTitle", null );
		IupSetHandle( "toggleKeywordComplete", null );
		IupSetHandle( "toggleUseParser", null );
		IupSetHandle( "toggleWithParams", null );
		IupSetHandle( "toggleIGNORECASE", null );
		IupSetHandle( "toggleCASEINSENSITIVE", null );
		IupSetHandle( "toggleSHOWLISTTYPE", null );
		IupSetHandle( "toggleSHOWALLMEMBER", null );
		IupSetHandle( "toggleLiveNone", null );
		IupSetHandle( "toggleLiveLight", null );
		IupSetHandle( "toggleLiveFull", null );		
		IupSetHandle( "toggleUpdateOutline", null );
	
		IupSetHandle( "toggleAnnotation", null );
		IupSetHandle( "toggleShowResultWindow", null );

		IupSetHandle( "toggleLineMargin", null );
		IupSetHandle( "toggleBookmarkMargin", null );
		IupSetHandle( "toggleFoldMargin", null );
		IupSetHandle( "toggleIndentGuide", null );
		IupSetHandle( "toggleCaretLine", null );
		IupSetHandle( "toggleWordWarp", null );
		IupSetHandle( "toggleTabUseingSpace", null );
		IupSetHandle( "toggleAutoIndent", null );
		IupSetHandle( "toggleShowEOL", null );
		IupSetHandle( "toggleShowSpace", null );
		IupSetHandle( "toggleAutoEnd", null );
		IupSetHandle( "toggleColorOutline", null );

		
		IupSetHandle( "textTabWidth", null );
		IupSetHandle( "textColumnEdge", null );

		IupSetHandle( "radioKeywordCase0", null );
		IupSetHandle( "radioKeywordCase1", null );
		IupSetHandle( "radioKeywordCase2", null );
		IupSetHandle( "radioKeywordCase3", null );

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
		IupSetHandle( "textAlpha", null );

		IupSetHandle( "btnKeyWord0Color", null );
		IupSetHandle( "btnKeyWord1Color", null );
		IupSetHandle( "btnKeyWord2Color", null );
		IupSetHandle( "btnKeyWord3Color", null );

		IupSetHandle( "keyWordText0", null );
		IupSetHandle( "keyWordText1", null );
		IupSetHandle( "keyWordText2", null );
		IupSetHandle( "keyWordText3", null );
		
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
		.attribute( null, "ColorOutline", GLOBAL.editorSetting00.ColorOutline );
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
		.attribute( null, "autocomplete", convertShortKeyValue2String( GLOBAL.shortKeys[21].keyValue ) );

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
		Ihandle* listOptions = IupGetHandle( "CArgOptionDialog_listOptions" );
		if( listOptions != null )
		{
			for( int i = 0; i < IupGetInt( listOptions, "COUNT" ); ++i )
			{
				optionsNode.element( null, "name", fromStringz( IupGetAttribute( listOptions, toStringz( Integer.toString( i + 1 ) ) ) ).dup );
			}
		}

		auto argsNode = configNode.element( null, "recentArgs" );
		Ihandle* listArgs = IupGetHandle( "CArgOptionDialog_listArgs" );
		if( listArgs != null )
		{
			for( int i = 0; i < IupGetInt( listArgs, "COUNT" ); ++i )
			{
				argsNode.element( null, "name", fromStringz( IupGetAttribute( listArgs, toStringz( Integer.toString( i + 1 ) ) ) ).dup );
			}
		}		
		
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
			auto result = root.query.descendant("keywords").attribute("value");
			GLOBAL.KEYWORDS.length = 0;
			foreach( e; result )
			{
				GLOBAL.KEYWORDS~= e.value;
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
			if( !GLOBAL.shortKeys.length ) GLOBAL.shortKeys.length = 21;
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
		catch
		{


		}
	}
}

extern(C) // Callback for CPreferenceDialog
{
	private int CPreferenceDialog_OpenCompileBinFile_cb( Ihandle* ih )
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

	private int CPreferenceDialog_OpenDebuggerBinFile_cb( Ihandle* ih )
	{
		scope fileSecectDlg = new CFileDlg( "Open File..." );
		char[] fileName = fileSecectDlg.getFileName();

		if( fileName.length )
		{
			GLOBAL.debuggerFullPath = fileName;
			Ihandle* _debuggerPath_Handle = IupGetHandle( "debuggerPath_Handle" );
			if( _debuggerPath_Handle != null ) IupSetAttribute( _debuggerPath_Handle, "VALUE", toStringz( fileName ) );
		}
		else
		{
			//Stdout( "NoThing!!!" ).newline;
		}

		return IUP_DEFAULT;
	}

	private int CPreferenceDialog_shortCutList_DBLCLICK_CB( Ihandle *ih, int item, char *text )
	{
		scope skDialog = new CShortCutDialog( 300, 140, item, fromStringz( text ).dup );
		skDialog.show( IUP_CENTERPARENT, IUP_CENTERPARENT );

		return IUP_DEFAULT;
	}

	private int CPreferenceDialog_fontList_DBLCLICK_CB( Ihandle *ih, int item, char *text )
	{
		char[] listString = fromStringz( text ).dup;
		char[] _ls;
		
		if( listString.length > 10 ) _ls = listString[10..length].dup; else return IUP_DEFAULT;

		version(linux)
		{
			_ls = "";
			foreach( char c; listString[10..length].dup )
			{
				if( c != ' ' && c != ',' )
				{
					_ls ~= c;
				}
				else if( c == ' ' )
				{
					if( _ls.length )
					{
						if( _ls[length-1] != ' ' ) _ls ~= ' ' ;
					}
				}
			}
		}		

		// Set IupFontDlg
		try
		{
			Ihandle* dlg = IupFontDlg();

			if( dlg == null )
			{
				IupMessage( "Error", toStringz( "IupFontDlg created fail!" ) );
				return IUP_IGNORE;
			}

			IupSetAttribute( dlg, "VALUE", toStringz( _ls.dup ) );
			
			// Open IupFontDlg
			IupPopup( dlg, IUP_CURRENT, IUP_CURRENT );

			if( IupGetInt( dlg, "STATUS" ) )
			{
				char[] fontInformation = fromStringz( IupGetAttribute( dlg, "VALUE" ) ).dup;
				char[] Bold, Italic, Underline, Strikeout, size, fontName;
				char[][] strings = Util.split( fontInformation, "," );
				if( strings.length == 2 )
				{
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
				else
				{
					version(linux)
					{
						foreach( char[] s; Util.split( fontInformation, " " ) )
						{
							switch( s )
							{
								case "Bold":		Bold = s;		break;
								case "Italic":		Italic = s;		break;
								case "Underline":	Underline = s;	break;
								case "Strikeout":	Strikeout = s;	break;
								default:
									if( s.length )
									{
										if( s[0] >= 48 && s[0] <= 57 )
										{
											size = s;
											break;
										}

										fontName ~= ( s ~ " " );
									}
							}
						}

						fontName = Util.trim( fontName );
						char[] _string = Stdout.layout.convert( "{,-10} {,-18},{,-4} {,-6} {,-9} {,-9} {,-3}", GLOBAL.fonts[item-1].name, fontName, Bold, Italic, Underline, Strikeout, size );
						IupSetAttribute( ih, toStringz( Integer.toString( item ) ), toStringz( _string ) );
					}
				}			
			}

			IupDestroy( dlg ); 
		}
		catch( Exception e )
		{
			IupMessage( "Error", toStringz( e.toString ) );
		}

		return IUP_DEFAULT;
	}

	private int CPreferenceDialog_btnOK_cb( Ihandle* ih )
	{
		GLOBAL.KEYWORDS[0] = Util.trim( fromStringz(IupGetAttribute( IupGetHandle( "keyWordText0" ), "VALUE" ))).dup;
		GLOBAL.KEYWORDS[1] = Util.trim( fromStringz(IupGetAttribute( IupGetHandle( "keyWordText1" ), "VALUE" ))).dup;
		GLOBAL.KEYWORDS[2] = Util.trim( fromStringz(IupGetAttribute( IupGetHandle( "keyWordText2" ), "VALUE" ))).dup;
		GLOBAL.KEYWORDS[3] = Util.trim( fromStringz(IupGetAttribute( IupGetHandle( "keyWordText3" ), "VALUE" ))).dup;
		
		GLOBAL.editorSetting00.LineMargin			= fromStringz(IupGetAttribute( IupGetHandle( "toggleLineMargin" ), "VALUE" )).dup;
		GLOBAL.editorSetting00.BookmarkMargin		= fromStringz(IupGetAttribute( IupGetHandle( "toggleBookmarkMargin" ), "VALUE" )).dup;
		GLOBAL.editorSetting00.FoldMargin			= fromStringz(IupGetAttribute( IupGetHandle( "toggleFoldMargin" ), "VALUE" )).dup;
		GLOBAL.editorSetting00.IndentGuide			= fromStringz(IupGetAttribute( IupGetHandle( "toggleIndentGuide" ), "VALUE" )).dup;
		GLOBAL.editorSetting00.CaretLine			= fromStringz(IupGetAttribute( IupGetHandle( "toggleCaretLine" ), "VALUE" )).dup;
		GLOBAL.editorSetting00.WordWrap				= fromStringz(IupGetAttribute( IupGetHandle( "toggleWordWrap" ), "VALUE" )).dup;
		GLOBAL.editorSetting00.TabUseingSpace		= fromStringz(IupGetAttribute( IupGetHandle( "toggleTabUseingSpace" ), "VALUE" )).dup;
		GLOBAL.editorSetting00.AutoIndent			= fromStringz(IupGetAttribute( IupGetHandle( "toggleAutoIndent" ), "VALUE" )).dup;
		GLOBAL.editorSetting00.ShowEOL				= fromStringz(IupGetAttribute( IupGetHandle( "toggleShowEOL" ), "VALUE" )).dup;
		GLOBAL.editorSetting00.ShowSpace			= fromStringz(IupGetAttribute( IupGetHandle( "toggleShowSpace" ), "VALUE" )).dup;
		GLOBAL.editorSetting00.AutoEnd				= fromStringz(IupGetAttribute( IupGetHandle( "toggleAutoEnd" ), "VALUE" )).dup;
		GLOBAL.editorSetting00.ColorOutline			= fromStringz(IupGetAttribute( IupGetHandle( "toggleColorOutline" ), "VALUE" )).dup;
		GLOBAL.editorSetting00.TabWidth				= fromStringz(IupGetAttribute( IupGetHandle( "textTabWidth" ), "VALUE" )).dup;
		GLOBAL.editorSetting00.ColumnEdge			= fromStringz(IupGetAttribute( IupGetHandle( "textColumnEdge" ), "VALUE" )).dup;

		Ihandle* _ft = IupGetHandle( "fontList" );
		if( _ft != null )
		{
			for( int i = 0; i < GLOBAL.fonts.length; ++ i )
			{
				char[]	result;
				
				char[]	fontInformation = fromStringz( IupGetAttribute( _ft, toStringz( Integer.toString( i + 1 ) ) ) ).dup;

				if( fontInformation.length > 10 )
				{
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
		}


		GLOBAL.editColor.caretLine					= fromStringz(IupGetAttribute( IupGetHandle( "btnCaretLine" ), "BGCOLOR" )).dup;
		GLOBAL.editColor.cursor						= fromStringz(IupGetAttribute( IupGetHandle( "btnCursor" ), "BGCOLOR" )).dup;

		GLOBAL.editColor.selectionFore				= fromStringz(IupGetAttribute( IupGetHandle( "btnSelectFore" ), "BGCOLOR" )).dup;
		GLOBAL.editColor.selectionBack				= fromStringz(IupGetAttribute( IupGetHandle( "btnSelectBack" ), "BGCOLOR" )).dup;
		GLOBAL.editColor.linenumFore				= fromStringz(IupGetAttribute( IupGetHandle( "btnLinenumFore" ), "BGCOLOR" )).dup;
		GLOBAL.editColor.linenumBack				= fromStringz(IupGetAttribute( IupGetHandle( "btnLinenumBack" ), "BGCOLOR" )).dup;
		GLOBAL.editColor.fold						= fromStringz(IupGetAttribute( IupGetHandle( "btnFoldingColor" ), "BGCOLOR" )).dup;
		version(Windows)
			GLOBAL.editColor.selAlpha				= fromStringz(IupGetAttribute( IupGetHandle( "textAlpha" ), "SPINVALUE" )).dup;
		else
			GLOBAL.editColor.selAlpha				= fromStringz(IupGetAttribute( IupGetHandle( "textAlpha" ), "VALUE" )).dup;

		GLOBAL.editColor.keyWord[0]					= fromStringz(IupGetAttribute( IupGetHandle( "btnKeyWord0Color" ), "BGCOLOR" )).dup;
		GLOBAL.editColor.keyWord[1]					= fromStringz(IupGetAttribute( IupGetHandle( "btnKeyWord1Color" ), "BGCOLOR" )).dup;
		GLOBAL.editColor.keyWord[2]					= fromStringz(IupGetAttribute( IupGetHandle( "btnKeyWord2Color" ), "BGCOLOR" )).dup;
		GLOBAL.editColor.keyWord[3]					= fromStringz(IupGetAttribute( IupGetHandle( "btnKeyWord3Color" ), "BGCOLOR" )).dup;


		GLOBAL.autoCompletionTriggerWordCount		= Integer.atoi( fromStringz(IupGetAttribute( IupGetHandle( "textTrigger" ), "VALUE" ) ).dup );
		GLOBAL.includeLevel							= Integer.atoi( fromStringz(IupGetAttribute( IupGetHandle( "textIncludeLevel" ), "VALUE" ) ).dup );

		if( GLOBAL.includeLevel < 0 ) GLOBAL.includeLevel = 0;

		GLOBAL.compilerFullPath						= fromStringz( IupGetAttribute( IupGetHandle( "compilerPath_Handle" ), "VALUE" ) ).dup;
		GLOBAL.debuggerFullPath						= fromStringz( IupGetAttribute( IupGetHandle( "debuggerPath_Handle" ), "VALUE" ) ).dup;
		GLOBAL.defaultOption						= fromStringz( IupGetAttribute( IupGetHandle( "defaultOption_Handle" ), "VALUE" ) ).dup;
		GLOBAL.compilerAnootation					= fromStringz( IupGetAttribute( IupGetHandle( "toggleAnnotation" ), "VALUE" ) ).dup;
		GLOBAL.compilerWindow						= fromStringz( IupGetAttribute( IupGetHandle( "toggleShowResultWindow" ), "VALUE" ) ).dup;


		GLOBAL.enableKeywordComplete				= fromStringz( IupGetAttribute( IupGetHandle( "toggleKeywordComplete" ), "VALUE" ) ).dup;
		GLOBAL.enableParser							= fromStringz( IupGetAttribute( IupGetHandle( "toggleUseParser" ), "VALUE" ) ).dup;
		GLOBAL.showFunctionTitle					= fromStringz( IupGetAttribute( IupGetHandle( "toggleFunctionTitle" ), "VALUE" ) ).dup;
		GLOBAL.showTypeWithParams					= fromStringz( IupGetAttribute( IupGetHandle( "toggleWithParams" ), "VALUE" ) ).dup;
		GLOBAL.toggleIgnoreCase						= fromStringz( IupGetAttribute( IupGetHandle( "toggleIGNORECASE" ), "VALUE" ) ).dup;
		GLOBAL.toggleCaseInsensitive				= fromStringz( IupGetAttribute( IupGetHandle( "toggleCASEINSENSITIVE" ), "VALUE" ) ).dup;
		GLOBAL.toggleShowListType					= fromStringz( IupGetAttribute( IupGetHandle( "toggleSHOWLISTTYPE" ), "VALUE" ) ).dup;
		GLOBAL.toggleShowAllMember					= fromStringz( IupGetAttribute( IupGetHandle( "toggleSHOWALLMEMBER" ), "VALUE" ) ).dup;


		if( fromStringz( IupGetAttribute( IupGetHandle( "toggleLiveNone" ), "VALUE" ) ) == "ON" )
			GLOBAL.liveLevel = 0;
		else if( fromStringz( IupGetAttribute( IupGetHandle( "toggleLiveLight" ), "VALUE" ) ) == "ON" )
			GLOBAL.liveLevel = 1;
		else if( fromStringz( IupGetAttribute( IupGetHandle( "toggleLiveFull" ), "VALUE" ) ) == "ON" )
			GLOBAL.liveLevel = 2;
		else
			GLOBAL.liveLevel = 0;

		GLOBAL.toggleUpdateOutlineLive				= fromStringz( IupGetAttribute( IupGetHandle( "toggleUpdateOutline" ), "VALUE" ) ).dup;


		if( fromStringz( IupGetAttribute( IupGetHandle( "radioKeywordCase0" ), "VALUE" ) ) == "ON" )
			GLOBAL.keywordCase = 0;
		else if( fromStringz( IupGetAttribute( IupGetHandle( "radioKeywordCase1" ), "VALUE" ) ) == "ON" )
			GLOBAL.keywordCase = 1;
		else if( fromStringz( IupGetAttribute( IupGetHandle( "radioKeywordCase2" ), "VALUE" ) ) == "ON" )
			GLOBAL.keywordCase = 2;
		else
			GLOBAL.keywordCase = 3;

		if( GLOBAL.showFunctionTitle == "ON" ) IupSetAttribute( GLOBAL.toolbar.getListHandle(), "VISIBLE", "YES" ); else IupSetAttribute( GLOBAL.toolbar.getListHandle(), "VISIBLE", "NO" );

		//if( GLOBAL.fonts.length == 11 )
		//{
			foreach( CScintilla cSci; GLOBAL.scintillaManager )
			{
				if( cSci !is null ) cSci.setGlobalSetting();
			}			
			IupSetAttribute( GLOBAL.projectViewTabs, "FONT", toStringz( GLOBAL.fonts[2].fontString ) ); // Leftside
			IupSetAttribute( GLOBAL.fileListTree.getTreeHandle, "FONT", toStringz( GLOBAL.fonts[3].fontString ) ); // Filelist
			IupSetAttribute( GLOBAL.projectTree.getTreeHandle, "FONT", toStringz( GLOBAL.fonts[4].fontString ) ); // Project
			IupSetAttribute( GLOBAL.outlineTree.getZBoxHandle, "FONT", toStringz( GLOBAL.fonts[5].fontString ) ); // Outline
			IupSetAttribute( GLOBAL.messageWindowTabs, "FONT", toStringz( GLOBAL.fonts[6].fontString ) ); // Bottom
			IupSetAttribute( GLOBAL.outputPanel, "FONT", toStringz( GLOBAL.fonts[7].fontString ) ); // Output
			IupSetAttribute( GLOBAL.searchOutputPanel, "FONT", toStringz( GLOBAL.fonts[8].fontString ) ); // Search
			IupSetAttribute( GLOBAL.debugPanel.getConsoleHandle, "FONT", toStringz( GLOBAL.fonts[8].fontString ) );// Debugger
			GLOBAL.debugPanel.setFont();
		//}

		// Save Setup to Xml
		CPreferenceDialog.save();

		return IUP_CLOSE;
	}

	private int CPreferenceDialog_colorChoose_cb( Ihandle* ih )
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