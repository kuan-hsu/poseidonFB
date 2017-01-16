module dialogs.preferenceDlg;

private import iup.iup, iup.iup_scintilla;

private import global, IDE, project, tools, scintilla, actionManager;
private import dialogs.baseDlg, dialogs.helpDlg, dialogs.fileDlg, dialogs.shortcutDlg;

private import tango.stdc.stringz, tango.io.Stdout;

class CPreferenceDialog : CBaseDialog
{
	private:
	Ihandle* textCompilerPath, textDebuggerPath;

	void createLayout()
	{
		Ihandle* bottom = createDlgButton();

		Ihandle* labelCompiler = IupLabel( toStringz( GLOBAL.languageItems["compilerpath"] ~ ":" ) );
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
		IupSetAttributes( hBox01, "ALIGNMENT=ACENTER,MARGIN=5x0" );

		
		Ihandle* labelDebugger = IupLabel( toStringz( GLOBAL.languageItems["debugpath"] ~ ":" ) );
		IupSetAttributes( labelDebugger, "VISIBLELINES=1,VISIBLECOLUMNS=1" );
		
		textDebuggerPath = IupText( null );
		IupSetAttribute( textDebuggerPath, "SIZE", "185x12" );
		IupSetAttribute( textDebuggerPath, "VALUE", toStringz(GLOBAL.debuggerFullPath) );
		IupSetHandle( "debuggerPath_Handle", textDebuggerPath );
		
		Ihandle* btnOpenDebugger = IupButton( null, null );
		IupSetAttribute( btnOpenDebugger, "IMAGE", "icon_openfile" );
		IupSetCallback( btnOpenDebugger, "ACTION", cast(Icallback) &CPreferenceDialog_OpenDebuggerBinFile_cb );

		Ihandle* hBox02 = IupHbox( labelDebugger, textDebuggerPath, btnOpenDebugger, null );
		IupSetAttributes( hBox02, "ALIGNMENT=ACENTER,MARGIN=5x0" );
		

		Ihandle* labelDefaultOption = IupLabel( toStringz( GLOBAL.languageItems["compileropts"] ~ ":" ) );
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
		IupSetAttributes( hBox03, "ALIGNMENT=ACENTER,MARGIN=5x0" );



		// compiler Setting
		Ihandle* toggleAnnotation = IupToggle( toStringz( GLOBAL.languageItems["errorannotation"] ), null );
		IupSetAttribute( toggleAnnotation, "VALUE", toStringz(GLOBAL.compilerAnootation.dup) );
		IupSetHandle( "toggleAnnotation", toggleAnnotation );
		
		Ihandle* toggleShowResultWindow = IupToggle( toStringz( GLOBAL.languageItems["showresultwindow"] ), null );
		IupSetAttribute( toggleShowResultWindow, "VALUE", toStringz(GLOBAL.compilerWindow.dup) );
		IupSetHandle( "toggleShowResultWindow", toggleShowResultWindow );

		Ihandle* vBoxCompiler = IupVbox( toggleAnnotation, toggleShowResultWindow, null );

		Ihandle* frameCompiler = IupFrame( vBoxCompiler );
		IupSetAttribute( frameCompiler, "TITLE", toStringz( GLOBAL.languageItems["compilersetting"] ) );
		IupSetAttributes( frameCompiler, "EXPANDCHILDREN=YES,SIZE=261x");

		// Parser Setting
		Ihandle* toggleKeywordComplete = IupToggle( toStringz( GLOBAL.languageItems["enablekeyword"] ), null );
		IupSetAttribute( toggleKeywordComplete, "VALUE", toStringz(GLOBAL.enableKeywordComplete.dup) );
		IupSetHandle( "toggleKeywordComplete", toggleKeywordComplete );
		
		Ihandle* toggleUseParser = IupToggle( toStringz( GLOBAL.languageItems["enableparser"] ), null );
		IupSetAttribute( toggleUseParser, "VALUE", toStringz(GLOBAL.enableParser.dup) );
		IupSetHandle( "toggleUseParser", toggleUseParser );
		
		Ihandle* labelTrigger = IupLabel( toStringz( GLOBAL.languageItems["trigger"] ~ ":" ) );
		IupSetAttributes( labelTrigger, "SIZE=96x12" );
		
		Ihandle* textTrigger = IupText( null );
		IupSetAttribute( textTrigger, "SIZE", "30x12" );
		IupSetAttribute( textTrigger, "TIP", toStringz( GLOBAL.languageItems["triggertip"] ) );
		IupSetAttribute( textTrigger, "VALUE", toStringz( Integer.toString( GLOBAL.autoCompletionTriggerWordCount ) ) );
		IupSetHandle( "textTrigger", textTrigger );

		Ihandle* labelIncludeLevel = IupLabel( toStringz( GLOBAL.languageItems["includelevel"] ~ ":" ) );
		IupSetAttributes( labelIncludeLevel, "SIZE=80x12,GAP=0" );
		
		Ihandle* textIncludeLevel = IupText( null );
		IupSetAttribute( textIncludeLevel, "SIZE", "30x12" );
		IupSetAttribute( textIncludeLevel, "VALUE", toStringz( Integer.toString( GLOBAL.includeLevel ) ) );
		IupSetHandle( "textIncludeLevel", textIncludeLevel );

		

		Ihandle* toggleFunctionTitle = IupToggle( toStringz( GLOBAL.languageItems["showtitle"] ), null );
		IupSetAttribute( toggleFunctionTitle, "VALUE", toStringz(GLOBAL.showFunctionTitle.dup) );
		IupSetHandle( "toggleFunctionTitle", toggleFunctionTitle );

		Ihandle* toggleWithParams = IupToggle( toStringz( GLOBAL.languageItems["showtypeparam"] ), null );
		IupSetAttribute( toggleWithParams, "VALUE", toStringz(GLOBAL.showTypeWithParams.dup) );
		IupSetHandle( "toggleWithParams", toggleWithParams );

		Ihandle* toggleIGNORECASE = IupToggle( toStringz( GLOBAL.languageItems["sortignorecase"] ), null );
		IupSetAttribute( toggleIGNORECASE, "VALUE", toStringz(GLOBAL.toggleIgnoreCase.dup) );
		IupSetHandle( "toggleIGNORECASE", toggleIGNORECASE );

		Ihandle* toggleCASEINSENSITIVE = IupToggle( toStringz( GLOBAL.languageItems["selectcase"] ), null );
		IupSetAttribute( toggleCASEINSENSITIVE, "VALUE", toStringz(GLOBAL.toggleCaseInsensitive.dup) );
		IupSetHandle( "toggleCASEINSENSITIVE", toggleCASEINSENSITIVE );

		Ihandle* toggleSHOWLISTTYPE = IupToggle( toStringz( GLOBAL.languageItems["showlisttype"] ), null );
		IupSetAttribute( toggleSHOWLISTTYPE, "VALUE", toStringz(GLOBAL.toggleShowListType.dup) );
		IupSetHandle( "toggleSHOWLISTTYPE", toggleSHOWLISTTYPE );

		Ihandle* toggleSHOWALLMEMBER = IupToggle( toStringz( GLOBAL.languageItems["showallmembers"] ), null );
		IupSetAttribute( toggleSHOWALLMEMBER, "VALUE", toStringz(GLOBAL.toggleShowAllMember.dup) );
		IupSetHandle( "toggleSHOWALLMEMBER", toggleSHOWALLMEMBER );


		Ihandle* toggleLiveNone = IupToggle( toStringz( GLOBAL.languageItems["none"] ), null );
		IupSetHandle( "toggleLiveNone", toggleLiveNone );

		Ihandle* toggleLiveLight = IupToggle( toStringz( GLOBAL.languageItems["light"] ), null );
		IupSetHandle( "toggleLiveLight", toggleLiveLight );
		
		Ihandle* toggleLiveFull = IupToggle( toStringz( GLOBAL.languageItems["full"] ), null );
		IupSetHandle( "toggleLiveFull", toggleLiveFull );
		//IupSetAttribute( toggleLiveFull, "ACTIVE", "NO" );

		Ihandle* toggleUpdateOutline = IupToggle( toStringz( GLOBAL.languageItems["update"] ), null );
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
		IupSetAttribute( frameLive, "TITLE", toStringz( GLOBAL.languageItems["parserlive"] ) );


		Ihandle* hBox00 = IupHbox( labelTrigger, textTrigger, labelIncludeLevel, textIncludeLevel,null );
		//Ihandle* hBox00_1 = IupHbox( labelIncludeLevel, textIncludeLevel, null );
		Ihandle* vBox00 = IupVbox( toggleKeywordComplete, toggleUseParser, toggleFunctionTitle, toggleWithParams, toggleIGNORECASE, toggleCASEINSENSITIVE, toggleSHOWLISTTYPE, toggleSHOWALLMEMBER, frameLive, hBox00, null );
		IupSetAttributes( vBox00, "GAP=5,MARGIN=0x1,EXPANDCHILDREN=YES" );
	
		Ihandle* frameParser = IupFrame( vBox00 );
		IupSetAttribute( frameParser, "TITLE", toStringz( GLOBAL.languageItems["parsersetting"] ) );
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
		Ihandle* toggleLineMargin = IupToggle( toStringz( GLOBAL.languageItems["lnmargin"] ), null );
		IupSetAttribute( toggleLineMargin, "VALUE", toStringz(GLOBAL.editorSetting00.LineMargin.dup) );
		IupSetHandle( "toggleLineMargin", toggleLineMargin );
		
		Ihandle* toggleBookmarkMargin = IupToggle( toStringz( GLOBAL.languageItems["bkmargin"] ), null );
		IupSetAttribute( toggleBookmarkMargin, "VALUE", toStringz(GLOBAL.editorSetting00.BookmarkMargin.dup) );
		IupSetHandle( "toggleBookmarkMargin", toggleBookmarkMargin );
		
		Ihandle* toggleFoldMargin = IupToggle( toStringz( GLOBAL.languageItems["fdmargin"] ), null );
		IupSetAttribute( toggleFoldMargin, "VALUE", toStringz(GLOBAL.editorSetting00.FoldMargin.dup) );
		IupSetHandle( "toggleFoldMargin", toggleFoldMargin );
		
		Ihandle* toggleIndentGuide = IupToggle( toStringz( GLOBAL.languageItems["indentguide"] ), null );
		IupSetAttribute( toggleIndentGuide, "VALUE", toStringz(GLOBAL.editorSetting00.IndentGuide.dup) );
		IupSetHandle( "toggleIndentGuide", toggleIndentGuide );
		
		Ihandle* toggleCaretLine = IupToggle( toStringz( GLOBAL.languageItems["showcaretline"] ), null );
		IupSetAttribute( toggleCaretLine, "VALUE", toStringz(GLOBAL.editorSetting00.CaretLine.dup) );
		IupSetHandle( "toggleCaretLine", toggleCaretLine );
		
		Ihandle* toggleWordWrap = IupToggle( toStringz( GLOBAL.languageItems["wordwarp"] ), null );
		IupSetAttribute( toggleWordWrap, "VALUE", toStringz(GLOBAL.editorSetting00.WordWrap.dup) );
		IupSetHandle( "toggleWordWrap", toggleWordWrap );
		
		Ihandle* toggleTabUseingSpace = IupToggle( toStringz( GLOBAL.languageItems["tabtospace"] ), null );
		IupSetAttribute( toggleTabUseingSpace, "VALUE", toStringz(GLOBAL.editorSetting00.TabUseingSpace.dup) );
		IupSetHandle( "toggleTabUseingSpace", toggleTabUseingSpace );
		
		Ihandle* toggleAutoIndent = IupToggle( toStringz( GLOBAL.languageItems["autoindent"] ), null );
		IupSetAttribute( toggleAutoIndent, "VALUE", toStringz(GLOBAL.editorSetting00.AutoIndent.dup) );
		IupSetHandle( "toggleAutoIndent", toggleAutoIndent );

		Ihandle* toggleShowEOL = IupToggle( toStringz( GLOBAL.languageItems["showeol"] ), null );
		IupSetAttribute( toggleShowEOL, "VALUE", toStringz(GLOBAL.editorSetting00.ShowEOL.dup) );
		IupSetHandle( "toggleShowEOL", toggleShowEOL );

		Ihandle* toggleShowSpace = IupToggle( toStringz( GLOBAL.languageItems["showspacetab"] ), null );
		IupSetAttribute( toggleShowSpace, "VALUE", toStringz(GLOBAL.editorSetting00.ShowSpace.dup) );
		IupSetHandle( "toggleShowSpace", toggleShowSpace );

		Ihandle* toggleAutoEnd = IupToggle( toStringz( GLOBAL.languageItems["autoinsertend"] ), null );
		IupSetAttribute( toggleAutoEnd, "VALUE", toStringz(GLOBAL.editorSetting00.AutoEnd.dup) );
		IupSetHandle( "toggleAutoEnd", toggleAutoEnd );

		Ihandle* toggleColorOutline = IupToggle( toStringz( GLOBAL.languageItems["coloroutline"] ), null );
		IupSetAttribute( toggleColorOutline, "VALUE", toStringz(GLOBAL.editorSetting00.ColorOutline.dup) );
		IupSetHandle( "toggleColorOutline", toggleColorOutline );		

		Ihandle* toggleMessage = IupToggle( toStringz( GLOBAL.languageItems["showidemessage"] ), null );
		IupSetAttribute( toggleMessage, "VALUE", toStringz(GLOBAL.editorSetting00.Message.dup) );
		IupSetHandle( "toggleMessage", toggleMessage );		

		Ihandle* toggleBoldKeyword = IupToggle( toStringz( GLOBAL.languageItems["boldkeyword"] ), null );
		IupSetAttribute( toggleBoldKeyword, "VALUE", toStringz(GLOBAL.editorSetting00.BoldKeyword.dup) );
		IupSetHandle( "toggleBoldKeyword", toggleBoldKeyword );		


		Ihandle* labelTabWidth = IupLabel( toStringz( GLOBAL.languageItems["tabwidth"] ~ ":" ) );
		Ihandle* textTabWidth = IupText( null );
		IupSetAttribute( textTabWidth, "VALUE", toStringz(GLOBAL.editorSetting00.TabWidth) );
		IupSetHandle( "textTabWidth", textTabWidth );
		Ihandle* hBoxTab = IupHbox( labelTabWidth, textTabWidth, null );
		IupSetAttribute( hBoxTab, "ALIGNMENT", "ACENTER" );
		
		Ihandle* labelColumnEdge = IupLabel( toStringz( GLOBAL.languageItems["columnedge"] ~ ":" ) );
		Ihandle* textColumnEdge = IupText( null );
		IupSetAttribute( textColumnEdge, "VALUE", toStringz(GLOBAL.editorSetting00.ColumnEdge) );
		IupSetAttribute( textColumnEdge, "TIP", toStringz( GLOBAL.languageItems["triggertip"] ) );
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

			IupSetAttributes( toggleMessage, "" ),
			IupSetAttributes( toggleBoldKeyword, "" ),
			

			IupSetAttributes( hBoxTab, "" ),
			IupSetAttributes( hBoxColumn, "" ),
			
			null
		);

		//IupSetAttribute(gbox, "SIZECOL", "1");
		//IupSetAttribute(gbox, "SIZELIN", "4");
		IupSetAttributes( gbox, "NUMDIV=2,ALIGNMENTLIN=ACENTER,GAPLIN=5,GAPCOL=100,MARGIN=0x0" );

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


		Ihandle* radioKeywordCase0 = IupToggle( toStringz( GLOBAL.languageItems["none"] ), null );
		IupSetHandle( "radioKeywordCase0", radioKeywordCase0 );

		Ihandle* radioKeywordCase1 = IupToggle( toStringz( GLOBAL.languageItems["lowercase"] ), null );
		IupSetHandle( "radioKeywordCase1", radioKeywordCase1 );
		
		Ihandle* radioKeywordCase2 = IupToggle( toStringz( GLOBAL.languageItems["uppercase"] ), null );
		IupSetHandle( "radioKeywordCase2", radioKeywordCase2 );

		Ihandle* radioKeywordCase3 = IupToggle( toStringz( GLOBAL.languageItems["mixercase"] ), null );
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
		IupSetAttribute( frameKeywordCase, "TITLE", toStringz( GLOBAL.languageItems["autoconvertkeyword"] ) );
		
		

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
		IupSetAttribute( frameFont, "TITLE", toStringz( GLOBAL.languageItems["font"] ));
		IupSetAttribute( frameFont, "EXPAND", "YES");
		
		Ihandle* vBoxPage02 = IupVbox( gbox, frameKeywordCase, frameFont, null );
		IupSetAttributes( vBoxPage02, "GAP=5,MARGIN=0x1,EXPANDCHILDREN=YES" );		

		// Color
		Ihandle* labelCaretLine = IupLabel( toStringz( GLOBAL.languageItems["caretline"] ~ ":" ) );
		Ihandle* btnCaretLine = IupButton( null, null );
		IupSetAttribute( btnCaretLine, "BGCOLOR", GLOBAL.editColor.caretLine.toCString );
		version(Windows) IupSetAttribute( btnCaretLine, "SIZE", "16x8" ); else IupSetAttribute( btnCaretLine, "SIZE", "16x12" );
		IupSetHandle( "btnCaretLine", btnCaretLine );
		IupSetCallback( btnCaretLine, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelCursor = IupLabel( toStringz( GLOBAL.languageItems["cursor"] ~ ":" ) );
		Ihandle* btnCursor = IupButton( null, null );
		IupSetAttribute( btnCursor, "BGCOLOR", GLOBAL.editColor.cursor.toCString );
		version(Windows) IupSetAttribute( btnCursor, "SIZE", "16x8" ); else IupSetAttribute( btnCursor, "SIZE", "16x12" );
		IupSetHandle( "btnCursor", btnCursor );
		IupSetCallback( btnCursor, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelSelectFore = IupLabel( toStringz( GLOBAL.languageItems["sel"] ~ ":" ) );
		Ihandle* btnSelectFore = IupButton( null, null );
		IupSetAttribute( btnSelectFore, "BGCOLOR", GLOBAL.editColor.selectionFore.toCString );
		version(Windows) IupSetAttribute( btnSelectFore, "SIZE", "64x8" ); else IupSetAttribute( btnSelectFore, "SIZE", "64x12" );
		IupSetHandle( "btnSelectFore", btnSelectFore );
		IupSetCallback( btnSelectFore, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* btnSelectBack = IupButton( null, null );
		IupSetAttribute( btnSelectBack, "BGCOLOR", GLOBAL.editColor.selectionBack.toCString );
		version(Windows) IupSetAttribute( btnSelectBack, "SIZE", "64x8" ); else IupSetAttribute( btnSelectBack, "SIZE", "64x12" );
		IupSetHandle( "btnSelectBack", btnSelectBack );
		IupSetCallback( btnSelectBack, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelLinenumFore = IupLabel( toStringz( GLOBAL.languageItems["ln"] ~ ":" ) );
		Ihandle* btnLinenumFore = IupButton( null, null );
		IupSetAttribute( btnLinenumFore, "BGCOLOR", GLOBAL.editColor.linenumFore.toCString );
		version(Windows) IupSetAttribute( btnLinenumFore, "SIZE", "64x8" ); else IupSetAttribute( btnLinenumFore, "SIZE", "64x12" );
		IupSetHandle( "btnLinenumFore", btnLinenumFore );
		IupSetCallback( btnLinenumFore, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* btnLinenumBack = IupButton( null, null );
		IupSetAttribute( btnLinenumBack, "BGCOLOR", GLOBAL.editColor.linenumBack.toCString );
		version(Windows) IupSetAttribute( btnLinenumBack, "SIZE", "64x8" ); else IupSetAttribute( btnLinenumBack, "SIZE", "64x12" );
		IupSetHandle( "btnLinenumBack", btnLinenumBack );
		IupSetCallback( btnLinenumBack, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelFoldingColor = IupLabel( toStringz( GLOBAL.languageItems["foldcolor"] ~ ":" ) );
		Ihandle* btnFoldingColor = IupButton( null, null );
		IupSetAttribute( btnFoldingColor, "BGCOLOR", GLOBAL.editColor.fold.toCString );
		version(Windows) IupSetAttribute( btnFoldingColor, "SIZE", "16x8" ); else IupSetAttribute( btnFoldingColor, "SIZE", "16x12" );
		IupSetHandle( "btnFoldingColor", btnFoldingColor );
		IupSetCallback( btnFoldingColor, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelSelAlpha = IupLabel( toStringz( GLOBAL.languageItems["selalpha"] ~ ":" ) );
		Ihandle* textAlpha = IupText( null );
		version(Windows)
		{
			IupSetAttributes( textAlpha, "SIZE=24x10,MARGIN=0x0,SPIN=YES,SPINMAX=255,SPINMIN=0" );
			IupSetAttribute( textAlpha, "SPINVALUE", GLOBAL.editColor.selAlpha.toCString );
		}
		else
		{
			IupSetAttributes( textAlpha, "SIZE=24x10,MARGIN=0x0" );
			IupSetAttribute( textAlpha, "VALUE", GLOBAL.editColor.selAlpha.toCString );
		}
		IupSetAttribute( textAlpha, "TIP", toStringz( GLOBAL.languageItems["alphatip"] ) );
		IupSetHandle( "textAlpha", textAlpha );
		
		
		// 2017.1.14
		Ihandle* labelPrjTitle = IupLabel( toStringz( GLOBAL.languageItems["prjtitle"] ~ ":" ) );
		Ihandle* btnPrjTitle = IupButton( null, null );
		IupSetAttribute( btnPrjTitle, "BGCOLOR", GLOBAL.editColor.prjTitle.toCString );
		version(Windows) IupSetAttribute( btnPrjTitle, "SIZE", "16x8" ); else IupSetAttribute( btnPrjTitle, "SIZE", "16x12" );
		IupSetHandle( "btnPrjTitle", btnPrjTitle );
		IupSetCallback( btnPrjTitle, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );		

		Ihandle* labelSourceTypeFolder = IupLabel( toStringz( GLOBAL.languageItems["sourcefolder"] ~ ":" ) );
		Ihandle* btnSourceTypeFolder = IupButton( null, null );
		IupSetAttribute( btnSourceTypeFolder, "BGCOLOR", GLOBAL.editColor.prjSourceType.toCString );
		version(Windows) IupSetAttribute( btnSourceTypeFolder, "SIZE", "16x8" ); else IupSetAttribute( btnSourceTypeFolder, "SIZE", "16x12" );
		IupSetHandle( "btnSourceTypeFolder", btnSourceTypeFolder );
		IupSetCallback( btnSourceTypeFolder, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );		



		Ihandle* gboxColor = IupGridBox
		(
			IupSetAttributes( labelCaretLine, "" ),
			IupSetAttributes( btnCaretLine,"" ),
			IupSetAttributes( labelCursor, "" ),
			IupSetAttributes( btnCursor, "" ),

			IupSetAttributes( labelFoldingColor, "" ),
			IupSetAttributes( btnFoldingColor, "" ),
			IupSetAttributes( labelSelAlpha, "" ),
			IupSetAttributes( textAlpha, "" ),
			
			IupSetAttributes( labelPrjTitle, "" ),
			IupSetAttributes( btnPrjTitle, "" ),
			IupSetAttributes( labelSourceTypeFolder, "" ),
			IupSetAttributes( btnSourceTypeFolder, "" ),
			/*
			IupSetAttributes( labelLinenumFore, "" ),
			IupSetAttributes( btnLinenumFore, "" ),
			IupSetAttributes( labelLinenumBack, "" ),
			IupSetAttributes( btnLinenumBack, "" ),
			*/



			null
		);
		IupSetAttributes( gboxColor, "EXPAND=YES,NUMDIV=4,ALIGNMENTLIN=ACENTER,ALIGNMENTCOL=ALEFT,GAPLIN=5,GAPCOL=30,MARGIN=2x10,SIZELIN=1" );

		Ihandle* frameColor = IupFrame( gboxColor );
		IupSetAttributes( frameColor, "MARGIN=0x0,EXPAND=YES,EXPAND=HORIZONTAL" );
		IupSetAttribute( frameColor, "SIZE", "275x" );//IupGetAttribute( frameFont, "SIZE" ) );

		IupSetAttribute( frameColor, "TITLE", toStringz( GLOBAL.languageItems["color"] ));

		
		// Color -1
		Ihandle* label_Scintilla = IupLabel( toStringz( GLOBAL.languageItems["scintilla"] ~ ":" ) );
		Ihandle* btn_Scintilla_FG = IupButton( null, null );
		Ihandle* btn_Scintilla_BG = IupButton( null, null );
		IupSetAttribute( btn_Scintilla_FG, "BGCOLOR", GLOBAL.editColor.scintillaFore.toCString );
		IupSetAttribute( btn_Scintilla_BG, "BGCOLOR", GLOBAL.editColor.scintillaBack.toCString );
		IupSetHandle( "btn_Scintilla_FG", btn_Scintilla_FG );
		IupSetHandle( "btn_Scintilla_BG", btn_Scintilla_BG );
		IupSetCallback( btn_Scintilla_FG, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btn_Scintilla_BG, "ACTION", cast(Icallback) &CPreferenceDialog_colorChooseScintilla_cb );
		version(Windows)
		{
			IupSetAttribute( btn_Scintilla_FG, "SIZE", "64x8" );
			IupSetAttribute( btn_Scintilla_BG, "SIZE", "64x8" );
		}
		else
		{
			IupSetAttribute( btn_Scintilla_FG, "SIZE", "64x12" );
			IupSetAttribute( btn_Scintilla_BG, "SIZE", "64x12" );
		}

		Ihandle* labelSCE_B_COMMENT = IupLabel( toStringz( GLOBAL.languageItems["SCE_B_COMMENT"] ~ ":" ) );
		Ihandle* btnSCE_B_COMMENT_FG = IupButton( null, null );
		Ihandle* btnSCE_B_COMMENT_BG = IupButton( null, null );
		IupSetAttribute( btnSCE_B_COMMENT_FG, "BGCOLOR", GLOBAL.editColor.SCE_B_COMMENT_Fore.toCString );
		IupSetAttribute( btnSCE_B_COMMENT_BG, "BGCOLOR", GLOBAL.editColor.SCE_B_COMMENT_Back.toCString );
		IupSetHandle( "btnSCE_B_COMMENT_FG", btnSCE_B_COMMENT_FG );
		IupSetHandle( "btnSCE_B_COMMENT_BG", btnSCE_B_COMMENT_BG );
		IupSetCallback( btnSCE_B_COMMENT_FG, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnSCE_B_COMMENT_BG, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		version(Windows)
		{
			IupSetAttribute( btnSCE_B_COMMENT_FG, "SIZE", "64x8" );
			IupSetAttribute( btnSCE_B_COMMENT_BG, "SIZE", "64x8" );
		}
		else
		{
			IupSetAttribute( btnSCE_B_COMMENT_FG, "SIZE", "64x12" );
			IupSetAttribute( btnSCE_B_COMMENT_BG, "SIZE", "64x12" );
		}
		
		Ihandle* labelSCE_B_NUMBER = IupLabel( toStringz( GLOBAL.languageItems["SCE_B_NUMBER"] ~ ":" ) );
		Ihandle* btnSCE_B_NUMBER_FG = IupButton( null, null );
		Ihandle* btnSCE_B_NUMBER_BG = IupButton( null, null );
		IupSetAttribute( btnSCE_B_NUMBER_FG, "BGCOLOR", GLOBAL.editColor.SCE_B_NUMBER_Fore.toCString );
		IupSetAttribute( btnSCE_B_NUMBER_BG, "BGCOLOR", GLOBAL.editColor.SCE_B_NUMBER_Back.toCString );
		IupSetHandle( "btnSCE_B_NUMBER_FG", btnSCE_B_NUMBER_FG );
		IupSetHandle( "btnSCE_B_NUMBER_BG", btnSCE_B_NUMBER_BG );
		IupSetCallback( btnSCE_B_NUMBER_FG, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnSCE_B_NUMBER_BG, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		version(Windows)
		{
			IupSetAttribute( btnSCE_B_NUMBER_FG, "SIZE", "64x8" );
			IupSetAttribute( btnSCE_B_NUMBER_BG, "SIZE", "64x8" );
		}
		else
		{
			IupSetAttribute( btnSCE_B_NUMBER_FG, "SIZE", "64x12" );
			IupSetAttribute( btnSCE_B_NUMBER_BG, "SIZE", "64x12" );
		}
		
		Ihandle* labelSCE_B_STRING = IupLabel( toStringz( GLOBAL.languageItems["SCE_B_STRING"] ~ ":" ) );
		Ihandle* btnSCE_B_STRING_FG = IupButton( null, null );
		Ihandle* btnSCE_B_STRING_BG = IupButton( null, null );
		IupSetAttribute( btnSCE_B_STRING_FG, "BGCOLOR", GLOBAL.editColor.SCE_B_STRING_Fore.toCString );
		IupSetAttribute( btnSCE_B_STRING_BG, "BGCOLOR", GLOBAL.editColor.SCE_B_STRING_Back.toCString );
		IupSetHandle( "btnSCE_B_STRING_FG", btnSCE_B_STRING_FG );
		IupSetHandle( "btnSCE_B_STRING_BG", btnSCE_B_STRING_BG );
		IupSetCallback( btnSCE_B_STRING_FG, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnSCE_B_STRING_BG, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		version(Windows)
		{
			IupSetAttribute( btnSCE_B_STRING_FG, "SIZE", "64x8" );
			IupSetAttribute( btnSCE_B_STRING_BG, "SIZE", "64x8" );
		}
		else
		{
			IupSetAttribute( btnSCE_B_STRING_FG, "SIZE", "64x12" );
			IupSetAttribute( btnSCE_B_STRING_BG, "SIZE", "64x12" );
		}		
		
		Ihandle* labelSCE_B_PREPROCESSOR = IupLabel( toStringz( GLOBAL.languageItems["SCE_B_PREPROCESSOR"] ~ ":" ) );
		Ihandle* btnSCE_B_PREPROCESSOR_FG = IupButton( null, null );
		Ihandle* btnSCE_B_PREPROCESSOR_BG = IupButton( null, null );
		IupSetAttribute( btnSCE_B_PREPROCESSOR_FG, "BGCOLOR", GLOBAL.editColor.SCE_B_PREPROCESSOR_Fore.toCString );
		IupSetAttribute( btnSCE_B_PREPROCESSOR_BG, "BGCOLOR", GLOBAL.editColor.SCE_B_PREPROCESSOR_Back.toCString );
		IupSetHandle( "btnSCE_B_PREPROCESSOR_FG", btnSCE_B_PREPROCESSOR_FG );
		IupSetHandle( "btnSCE_B_PREPROCESSOR_BG", btnSCE_B_PREPROCESSOR_BG );
		IupSetCallback( btnSCE_B_PREPROCESSOR_FG, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnSCE_B_PREPROCESSOR_BG, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		version(Windows)
		{
			IupSetAttribute( btnSCE_B_PREPROCESSOR_FG, "SIZE", "64x8" );
			IupSetAttribute( btnSCE_B_PREPROCESSOR_BG, "SIZE", "64x8" );
		}
		else
		{
			IupSetAttribute( btnSCE_B_PREPROCESSOR_FG, "SIZE", "64x12" );
			IupSetAttribute( btnSCE_B_PREPROCESSOR_BG, "SIZE", "64x12" );
		}
		
		Ihandle* labelSCE_B_OPERATOR = IupLabel( toStringz( GLOBAL.languageItems["SCE_B_OPERATOR"] ~ ":" ) );
		Ihandle* btnSCE_B_OPERATOR_FG = IupButton( null, null );
		Ihandle* btnSCE_B_OPERATOR_BG = IupButton( null, null );
		IupSetAttribute( btnSCE_B_OPERATOR_FG, "BGCOLOR", GLOBAL.editColor.SCE_B_OPERATOR_Fore.toCString );
		IupSetAttribute( btnSCE_B_OPERATOR_BG, "BGCOLOR", GLOBAL.editColor.SCE_B_OPERATOR_Back.toCString );
		IupSetHandle( "btnSCE_B_OPERATOR_FG", btnSCE_B_OPERATOR_FG );
		IupSetHandle( "btnSCE_B_OPERATOR_BG", btnSCE_B_OPERATOR_BG );
		IupSetCallback( btnSCE_B_OPERATOR_FG, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnSCE_B_OPERATOR_BG, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		version(Windows)
		{
			IupSetAttribute( btnSCE_B_OPERATOR_FG, "SIZE", "64x8" );
			IupSetAttribute( btnSCE_B_OPERATOR_BG, "SIZE", "64x8" );
		}
		else
		{
			IupSetAttribute( btnSCE_B_OPERATOR_FG, "SIZE", "64x12" );
			IupSetAttribute( btnSCE_B_OPERATOR_BG, "SIZE", "64x12" );
		}
		
		Ihandle* labelSCE_B_IDENTIFIER = IupLabel( toStringz( GLOBAL.languageItems["SCE_B_IDENTIFIER"] ~ ":" ) );
		Ihandle* btnSCE_B_IDENTIFIER_FG = IupButton( null, null );
		Ihandle* btnSCE_B_IDENTIFIER_BG = IupButton( null, null );
		IupSetAttribute( btnSCE_B_IDENTIFIER_FG, "BGCOLOR", GLOBAL.editColor.SCE_B_IDENTIFIER_Fore.toCString );
		IupSetAttribute( btnSCE_B_IDENTIFIER_BG, "BGCOLOR", GLOBAL.editColor.SCE_B_IDENTIFIER_Back.toCString );
		IupSetHandle( "btnSCE_B_IDENTIFIER_FG", btnSCE_B_IDENTIFIER_FG );
		IupSetHandle( "btnSCE_B_IDENTIFIER_BG", btnSCE_B_IDENTIFIER_BG );
		IupSetCallback( btnSCE_B_IDENTIFIER_FG, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnSCE_B_IDENTIFIER_BG, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		version(Windows)
		{
			IupSetAttribute( btnSCE_B_IDENTIFIER_FG, "SIZE", "64x8" );
			IupSetAttribute( btnSCE_B_IDENTIFIER_BG, "SIZE", "64x8" );
		}
		else
		{
			IupSetAttribute( btnSCE_B_IDENTIFIER_FG, "SIZE", "64x12" );
			IupSetAttribute( btnSCE_B_IDENTIFIER_BG, "SIZE", "64x12" );
		}
		
		Ihandle* labelSCE_B_COMMENTBLOCK = IupLabel( toStringz( GLOBAL.languageItems["SCE_B_COMMENTBLOCK"] ~ ":" ) );
		Ihandle* btnSCE_B_COMMENTBLOCK_FG = IupButton( null, null );
		Ihandle* btnSCE_B_COMMENTBLOCK_BG = IupButton( null, null );
		IupSetAttribute( btnSCE_B_COMMENTBLOCK_FG, "BGCOLOR", GLOBAL.editColor.SCE_B_COMMENTBLOCK_Fore.toCString );
		IupSetAttribute( btnSCE_B_COMMENTBLOCK_BG, "BGCOLOR", GLOBAL.editColor.SCE_B_COMMENTBLOCK_Back.toCString );	
		IupSetHandle( "btnSCE_B_COMMENTBLOCK_FG", btnSCE_B_COMMENTBLOCK_FG );
		IupSetHandle( "btnSCE_B_COMMENTBLOCK_BG", btnSCE_B_COMMENTBLOCK_BG );
		IupSetCallback( btnSCE_B_COMMENTBLOCK_FG, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnSCE_B_COMMENTBLOCK_BG, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		version(Windows)
		{
			IupSetAttribute( btnSCE_B_COMMENTBLOCK_FG, "SIZE", "64x8" );
			IupSetAttribute( btnSCE_B_COMMENTBLOCK_BG, "SIZE", "64x8" );
		}
		else
		{
			IupSetAttribute( btnSCE_B_COMMENTBLOCK_FG, "SIZE", "64x12" );
			IupSetAttribute( btnSCE_B_COMMENTBLOCK_BG, "SIZE", "64x12" );
		}
		
		
		Ihandle* labelPrj = IupLabel( toStringz( GLOBAL.languageItems["caption_prj"] ~ ":" ) );
		IupSetAttribute( labelPrj, "SIZE", toStringz("100x") );
		Ihandle* btnPrj_FG = IupButton( null, null );
		Ihandle* btnPrj_BG = IupButton( null, null );
		IupSetAttribute( btnPrj_FG, "BGCOLOR", GLOBAL.editColor.projectFore.toCString );
		IupSetAttribute( btnPrj_BG, "BGCOLOR", GLOBAL.editColor.projectBack.toCString );	
		IupSetHandle( "btnPrj_FG", btnPrj_FG );
		IupSetHandle( "btnPrj_BG", btnPrj_BG );
		IupSetCallback( btnPrj_FG, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnPrj_BG, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		version(Windows)
		{
			IupSetAttribute( btnPrj_FG, "SIZE", "64x8" );
			IupSetAttribute( btnPrj_BG, "SIZE", "64x8" );
		}
		else
		{
			IupSetAttribute( btnPrj_FG, "SIZE", "64x12" );
			IupSetAttribute( btnPrj_BG, "SIZE", "64x12" );
		}		
		
		Ihandle* labelOutline = IupLabel( toStringz( GLOBAL.languageItems["outline"] ~ ":" ) );
		Ihandle* btnOutline_FG = IupButton( null, null );
		Ihandle* btnOutline_BG = IupButton( null, null );
		IupSetAttribute( btnOutline_FG, "BGCOLOR", GLOBAL.editColor.outlineFore.toCString );
		IupSetAttribute( btnOutline_BG, "BGCOLOR", GLOBAL.editColor.outlineBack.toCString );	
		IupSetHandle( "btnOutline_FG", btnOutline_FG );
		IupSetHandle( "btnOutline_BG", btnOutline_BG );
		IupSetCallback( btnOutline_FG, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnOutline_BG, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		version(Windows)
		{
			IupSetAttribute( btnOutline_FG, "SIZE", "64x8" );
			IupSetAttribute( btnOutline_BG, "SIZE", "64x8" );
		}
		else
		{
			IupSetAttribute( btnOutline_FG, "SIZE", "64x12" );
			IupSetAttribute( btnOutline_BG, "SIZE", "64x12" );
		}
		
		Ihandle* labelFilelist= IupLabel( toStringz( GLOBAL.languageItems["filelist"] ~ ":" ) );
		Ihandle* btnFilelist_FG = IupButton( null, null );
		Ihandle* btnFilelist_BG = IupButton( null, null );
		IupSetAttribute( btnFilelist_FG, "BGCOLOR", GLOBAL.editColor.filelistFore.toCString );
		IupSetAttribute( btnFilelist_BG, "BGCOLOR", GLOBAL.editColor.filelistBack.toCString );	
		IupSetHandle( "btnFilelist_FG", btnFilelist_FG );
		IupSetHandle( "btnFilelist_BG", btnFilelist_BG );
		IupSetCallback( btnFilelist_FG, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnFilelist_BG, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		version(Windows)
		{
			IupSetAttribute( btnFilelist_FG, "SIZE", "64x8" );
			IupSetAttribute( btnFilelist_BG, "SIZE", "64x8" );
		}
		else
		{
			IupSetAttribute( btnFilelist_FG, "SIZE", "64x12" );
			IupSetAttribute( btnFilelist_BG, "SIZE", "64x12" );
		}
		
		Ihandle* labelOutput= IupLabel( toStringz( GLOBAL.languageItems["output"] ~ ":" ) );
		Ihandle* btnOutput_FG = IupButton( null, null );
		Ihandle* btnOutput_BG = IupButton( null, null );
		IupSetAttribute( btnOutput_FG, "BGCOLOR", GLOBAL.editColor.outputFore.toCString );
		IupSetAttribute( btnOutput_BG, "BGCOLOR", GLOBAL.editColor.outputBack.toCString );	
		IupSetHandle( "btnOutput_FG", btnOutput_FG );
		IupSetHandle( "btnOutput_BG", btnOutput_BG );
		IupSetCallback( btnOutput_FG, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnOutput_BG, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		version(Windows)
		{
			IupSetAttribute( btnOutput_FG, "SIZE", "64x8" );
			IupSetAttribute( btnOutput_BG, "SIZE", "64x8" );
		}
		else
		{
			IupSetAttribute( btnOutput_FG, "SIZE", "64x12" );
			IupSetAttribute( btnOutput_BG, "SIZE", "64x12" );
		}
		
		Ihandle* labelSearch= IupLabel( toStringz( GLOBAL.languageItems["caption_search"] ~ ":" ) );
		Ihandle* btnSearch_FG = IupButton( null, null );
		Ihandle* btnSearch_BG = IupButton( null, null );
		IupSetAttribute( btnSearch_FG, "BGCOLOR", GLOBAL.editColor.searchFore.toCString );
		IupSetAttribute( btnSearch_BG, "BGCOLOR", GLOBAL.editColor.searchBack.toCString );	
		IupSetHandle( "btnSearch_FG", btnSearch_FG );
		IupSetHandle( "btnSearch_BG", btnSearch_BG );
		IupSetCallback( btnSearch_FG, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnSearch_BG, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		version(Windows)
		{
			IupSetAttribute( btnSearch_FG, "SIZE", "64x8" );
			IupSetAttribute( btnSearch_BG, "SIZE", "64x8" );
		}
		else
		{
			IupSetAttribute( btnSearch_FG, "SIZE", "64x12" );
			IupSetAttribute( btnSearch_BG, "SIZE", "64x12" );
		}		
		
		Ihandle* gboxColor_1 = IupGridBox
		(
			IupSetAttributes( labelPrj, "" ),
			//IupFill(),
			IupSetAttributes( btnPrj_FG, "" ),
			IupSetAttributes( btnPrj_BG, "" ),

			IupSetAttributes( labelOutline, "" ),
			//IupFill(),
			IupSetAttributes( btnOutline_FG, "" ),
			IupSetAttributes( btnOutline_BG, "" ),

			IupSetAttributes( labelFilelist, "" ),
			//IupFill(),
			IupSetAttributes( btnFilelist_FG, "" ),
			IupSetAttributes( btnFilelist_BG, "" ),

			IupSetAttributes( labelOutput, "" ),
			//IupFill(),
			IupSetAttributes( btnOutput_FG, "" ),
			IupSetAttributes( btnOutput_BG, "" ),

			IupSetAttributes( labelSearch, "" ),
			//IupFill(),
			IupSetAttributes( btnSearch_FG, "" ),
			IupSetAttributes( btnSearch_BG, "" ),
			
			
			IupSetAttributes( labelSelectFore, "" ),
			IupSetAttributes( btnSelectFore, "" ),
			//IupSetAttributes( labelSelectBack, "" ),
			IupSetAttributes( btnSelectBack, "" ),

			IupSetAttributes( labelLinenumFore, "" ),
			IupSetAttributes( btnLinenumFore, "" ),
			//IupSetAttributes( labelLinenumBack, "" ),
			IupSetAttributes( btnLinenumBack, "" ),			
			
			
			
			IupSetAttributes( label_Scintilla, "" ),
			//IupFill(),
			IupSetAttributes( btn_Scintilla_FG,"" ),
			IupSetAttributes( btn_Scintilla_BG, "" ),

			IupSetAttributes( labelSCE_B_COMMENT, "" ),
			//IupFill(),
			IupSetAttributes( btnSCE_B_COMMENT_FG,"" ),
			IupSetAttributes( btnSCE_B_COMMENT_BG, "" ),

			IupSetAttributes( labelSCE_B_NUMBER, "" ),
			//IupFill(),
			IupSetAttributes( btnSCE_B_NUMBER_FG, "" ),
			IupSetAttributes( btnSCE_B_NUMBER_BG, "" ),

			IupSetAttributes( labelSCE_B_STRING, "" ),
			//IupFill(),
			IupSetAttributes( btnSCE_B_STRING_FG, "" ),
			IupSetAttributes( btnSCE_B_STRING_BG, "" ),

			IupSetAttributes( labelSCE_B_PREPROCESSOR, "" ),
			//IupFill(),
			IupSetAttributes( btnSCE_B_PREPROCESSOR_FG, "" ),
			IupSetAttributes( btnSCE_B_PREPROCESSOR_BG, "" ),

			IupSetAttributes( labelSCE_B_OPERATOR, "" ),
			//IupFill(),
			IupSetAttributes( btnSCE_B_OPERATOR_FG, "" ),
			IupSetAttributes( btnSCE_B_OPERATOR_BG, "" ),

			IupSetAttributes( labelSCE_B_IDENTIFIER, "" ),
			//IupFill(),
			IupSetAttributes( btnSCE_B_IDENTIFIER_FG, "" ),
			IupSetAttributes( btnSCE_B_IDENTIFIER_BG, "" ),

			IupSetAttributes( labelSCE_B_COMMENTBLOCK, "" ),
			//IupFill(),
			IupSetAttributes( btnSCE_B_COMMENTBLOCK_FG, "" ),
			IupSetAttributes( btnSCE_B_COMMENTBLOCK_BG, "" ),

			null
		);
		IupSetAttributes( gboxColor_1, "FITTOCHILDREN=YES,NUMDIV=3,ALIGNMENTLIN=ACENTER,ALIGNMENTCOL=ALEFT,GAPLIN=4,GAPCOL=20,MARGIN=2x10" );

		Ihandle* frameColor_1 = IupFrame( gboxColor_1 );
		IupSetAttributes( frameColor_1, "MARGIN=0x0,EXPAND=YES,EXPAND=HORIZONTAL" );
		IupSetAttribute( frameColor_1, "SIZE", "275x" );//IupGetAttribute( frameFont, "SIZE" ) );

		IupSetAttribute( frameColor_1, "TITLE", toStringz( GLOBAL.languageItems["colorfgbg"] ));
		
		
		
		/*
		Ihandle* vBoxPage02 = IupVbox( gbox, frameKeywordCase, frameFont, frameColor, null );
		IupSetAttributes( vBoxPage02, "GAP=5,MARGIN=0x1,EXPANDCHILDREN=YES" );
		*/
		Ihandle* vColor = IupVbox( frameColor, frameColor_1, null );
		IupSetAttributes( vColor, "GAP=5,MARGIN=0x1,EXPANDCHILDREN=YES" );		


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
			char[] keyValue = IDECONFIG.convertShortKeyValue2String( GLOBAL.shortKeys[i].keyValue );
			char[][] splitWord = Util.split( keyValue, "+" );

			if(  splitWord.length == 4 ) 
			{
				if( splitWord[0] == "C" )  splitWord[0] = "Ctrl";
				if( splitWord[1] == "S" )  splitWord[1] = "Shift";
				if( splitWord[2] == "A" )  splitWord[2] = "Alt";
			}
			
			char[] string = Stdout.layout.convert( "{,-30} {,-5} + {,-5} + {,-5} + {,-5}", GLOBAL.shortKeys[i].title, splitWord[0], splitWord[1], splitWord[2], splitWord[3] );

			IupSetAttribute( shortCutList, toStringz( Integer.toString( i + 1 ) ), toStringz( string ) );
		}


		Ihandle* keyWordText0 = IupText( null );
		IupSetAttributes( keyWordText0, "MULTILINE=YES,SCROLLBAR=VERTICAL,EXPAND=YES,WORDWRAP=YES" );
		IupSetAttribute( keyWordText0, "VALUE", toStringz( GLOBAL.KEYWORDS[0].dup ) );
		IupSetHandle( "keyWordText0", keyWordText0 );
		Ihandle* keyWordText1 = IupText( null );
		IupSetAttributes( keyWordText1, "MULTILINE=YES,SCROLLBAR=VERTICAL,EXPAND=YES,WORDWRAP=YES" );
		IupSetAttribute( keyWordText1, "VALUE", toStringz( GLOBAL.KEYWORDS[1].dup ) );
		IupSetHandle( "keyWordText1", keyWordText1 );
		Ihandle* keyWordText2 = IupText( null );
		IupSetAttributes( keyWordText2, "MULTILINE=YES,SCROLLBAR=VERTICAL,EXPAND=YES,WORDWRAP=YES" );
		IupSetAttribute( keyWordText2, "VALUE", toStringz( GLOBAL.KEYWORDS[2].dup ) );
		IupSetHandle( "keyWordText2", keyWordText2 );
		Ihandle* keyWordText3 = IupText( null );
		IupSetAttributes( keyWordText3, "MULTILINE=YES,SCROLLBAR=VERTICAL,EXPAND=YES,WORDWRAP=YES" );
		IupSetAttribute( keyWordText3, "VALUE", toStringz( GLOBAL.KEYWORDS[3].dup ) );
		IupSetHandle( "keyWordText3", keyWordText3 );


		Ihandle* labelKeyWord0 = IupLabel( toStringz( GLOBAL.languageItems["keyword0"] ) );
		Ihandle* btnKeyWord0Color = IupButton( null, null );
		IupSetAttribute( btnKeyWord0Color, "BGCOLOR", GLOBAL.editColor.keyWord[0].toCString );
		version(Windows) IupSetAttribute( btnKeyWord0Color, "SIZE", "24x8" ); else IupSetAttribute( btnKeyWord0Color, "SIZE", "24x12" );
		IupSetHandle( toStringz( "btnKeyWord0Color" ), btnKeyWord0Color );
		IupSetCallback( btnKeyWord0Color, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelKeyWord1 = IupLabel( toStringz( GLOBAL.languageItems["keyword1"] ) );
		Ihandle* btnKeyWord1Color = IupButton( null, null );
		IupSetAttribute( btnKeyWord1Color, "BGCOLOR", GLOBAL.editColor.keyWord[1].toCString );
		version(Windows) IupSetAttribute( btnKeyWord1Color, "SIZE", "24x8" ); else IupSetAttribute( btnKeyWord1Color, "SIZE", "24x12" );
		IupSetHandle( "btnKeyWord1Color", btnKeyWord1Color );
		IupSetCallback( btnKeyWord1Color, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelKeyWord2 = IupLabel( toStringz( GLOBAL.languageItems["keyword2"] ) );
		Ihandle* btnKeyWord2Color = IupButton( null, null );
		IupSetAttribute( btnKeyWord2Color, "BGCOLOR", GLOBAL.editColor.keyWord[2].toCString );
		version(Windows) IupSetAttribute( btnKeyWord2Color, "SIZE", "24x8" ); else IupSetAttribute( btnKeyWord2Color, "SIZE", "24x12" );
		IupSetHandle( "btnKeyWord2Color", btnKeyWord2Color );
		IupSetCallback( btnKeyWord2Color, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelKeyWord3 = IupLabel( toStringz( GLOBAL.languageItems["keyword3"] ) );
		Ihandle* btnKeyWord3Color = IupButton( null, null );
		IupSetAttribute( btnKeyWord3Color, "BGCOLOR",GLOBAL.editColor.keyWord[3].toCString );
		version(Windows) IupSetAttribute( btnKeyWord3Color, "SIZE", "24x8" ); else IupSetAttribute( btnKeyWord3Color, "SIZE", "24x12" );
		IupSetHandle( "btnKeyWord3Color", btnKeyWord3Color );
		IupSetCallback( btnKeyWord3Color, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* gboxKeyWordColor = IupGridBox
		(
			labelKeyWord0,
			btnKeyWord0Color,
			labelKeyWord1,
			btnKeyWord1Color,

			labelKeyWord2,
			btnKeyWord2Color,
			labelKeyWord3,
			btnKeyWord3Color,

			null
		);
		IupSetAttributes( gboxKeyWordColor, "EXPAND=YES,NUMDIV=8,ALIGNMENTLIN=ACENTER,ALIGNMENTCOL=ALEFT,GAPLIN=0,GAPCOL=0,MARGIN=0x0,SIZELIN=0,HOMOGENEOUSCOL=YES" );


		Ihandle* keyWordVbox = IupVbox( keyWordText0, keyWordText1, keyWordText2, keyWordText3, gboxKeyWordColor, null );
		IupSetAttribute( keyWordVbox, "ALIGNMENT", toStringz( "ACENTER" ) );


		IupSetAttribute( vBoxPage01, "TABTITLE", toStringz( GLOBAL.languageItems["compiler"] ) );
		IupSetAttribute( vBoxPage02, "TABTITLE", toStringz( GLOBAL.languageItems["editor"] ) );
		IupSetAttribute( vColor, "TABTITLE", toStringz( GLOBAL.languageItems["color"] ) );
		IupSetAttribute( shortCutList, "TABTITLE", toStringz( GLOBAL.languageItems["shortcut"] ) );
		IupSetAttribute( keyWordVbox, "TABTITLE", toStringz( GLOBAL.languageItems["keywords"] ) );
		IupSetAttribute( vBoxPage01, "EXPAND", "YES" );
	
		
		
		Ihandle* preferenceTabs = IupTabs( vBoxPage01, vBoxPage02, vColor, shortCutList, keyWordVbox, null );
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
		IupSetHandle( "toggleMessage", null );
		IupSetHandle( "toggleBoldKeyword", null );	

		
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
		
		IupSetHandle( "btn_Scintilla_FG", null );
		IupSetHandle( "btn_Scintilla_BG", null );
		IupSetHandle( "btnSCE_B_COMMENT_FG", null );
		IupSetHandle( "btnSCE_B_COMMENT_BG", null );
		IupSetHandle( "btnSCE_B_NUMBER_FG", null );
		IupSetHandle( "btnSCE_B_NUMBER_BG", null );
		IupSetHandle( "btnSCE_B_STRING_FG", null );
		IupSetHandle( "btnSCE_B_STRING_BG", null );
		IupSetHandle( "btnSCE_B_PREPROCESSOR_FG", null );
		IupSetHandle( "btnSCE_B_PREPROCESSOR_BG", null );
		IupSetHandle( "btnSCE_B_OPERATOR_FG", null );
		IupSetHandle( "btnSCE_B_OPERATOR_BG", null );
		IupSetHandle( "btnSCE_B_IDENTIFIER_FG", null );
		IupSetHandle( "btnSCE_B_IDENTIFIER_BG", null );
		IupSetHandle( "btnSCE_B_COMMENTBLOCK_FG", null );
		IupSetHandle( "btnSCE_B_COMMENTBLOCK_BG", null );		

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
}

extern(C) // Callback for CPreferenceDialog
{
	private int CPreferenceDialog_OpenCompileBinFile_cb( Ihandle* ih )
	{
		scope fileSecectDlg = new CFileDlg( GLOBAL.languageItems["caption_open"] ~ "..." );
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
		scope fileSecectDlg = new CFileDlg( GLOBAL.languageItems["caption_open"] ~ "..." );
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
		GLOBAL.editorSetting00.Message				= fromStringz(IupGetAttribute( IupGetHandle( "toggleMessage" ), "VALUE" )).dup;
		GLOBAL.editorSetting00.BoldKeyword			= fromStringz(IupGetAttribute( IupGetHandle( "toggleBoldKeyword" ), "VALUE" )).dup;


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


		GLOBAL.editColor.caretLine					= IupGetAttribute( IupGetHandle( "btnCaretLine" ), "BGCOLOR" );
		GLOBAL.editColor.cursor						= IupGetAttribute( IupGetHandle( "btnCursor" ), "BGCOLOR" );

		GLOBAL.editColor.selectionFore				= IupGetAttribute( IupGetHandle( "btnSelectFore" ), "BGCOLOR" );
		GLOBAL.editColor.selectionBack				= IupGetAttribute( IupGetHandle( "btnSelectBack" ), "BGCOLOR" );
		GLOBAL.editColor.linenumFore				= IupGetAttribute( IupGetHandle( "btnLinenumFore" ), "BGCOLOR" );
		GLOBAL.editColor.linenumBack				= IupGetAttribute( IupGetHandle( "btnLinenumBack" ), "BGCOLOR" );
		GLOBAL.editColor.fold						= IupGetAttribute( IupGetHandle( "btnFoldingColor" ), "BGCOLOR" );
		version(Windows)
			GLOBAL.editColor.selAlpha				= IupGetAttribute( IupGetHandle( "textAlpha" ), "SPINVALUE" );
		else
			GLOBAL.editColor.selAlpha				= IupGetAttribute( IupGetHandle( "textAlpha" ), "VALUE" );
			
		GLOBAL.editColor.scintillaFore				= IupGetAttribute( IupGetHandle( "btn_Scintilla_FG" ), "BGCOLOR" );
		GLOBAL.editColor.scintillaBack				= IupGetAttribute( IupGetHandle( "btn_Scintilla_BG" ), "BGCOLOR" );
		GLOBAL.editColor.SCE_B_COMMENT_Fore			= IupGetAttribute( IupGetHandle( "btnSCE_B_COMMENT_FG" ), "BGCOLOR" );
		GLOBAL.editColor.SCE_B_COMMENT_Back			= IupGetAttribute( IupGetHandle( "btnSCE_B_COMMENT_BG" ), "BGCOLOR" );
		GLOBAL.editColor.SCE_B_NUMBER_Fore			= IupGetAttribute( IupGetHandle( "btnSCE_B_NUMBER_FG" ), "BGCOLOR" );
		GLOBAL.editColor.SCE_B_NUMBER_Back			= IupGetAttribute( IupGetHandle( "btnSCE_B_NUMBER_BG" ), "BGCOLOR" );
		GLOBAL.editColor.SCE_B_STRING_Fore			= IupGetAttribute( IupGetHandle( "btnSCE_B_STRING_FG" ), "BGCOLOR" );
		GLOBAL.editColor.SCE_B_STRING_Back			= IupGetAttribute( IupGetHandle( "btnSCE_B_STRING_BG" ), "BGCOLOR" );
		GLOBAL.editColor.SCE_B_PREPROCESSOR_Fore	= IupGetAttribute( IupGetHandle( "btnSCE_B_PREPROCESSOR_FG" ), "BGCOLOR" );
		GLOBAL.editColor.SCE_B_PREPROCESSOR_Back	= IupGetAttribute( IupGetHandle( "btnSCE_B_PREPROCESSOR_BG" ), "BGCOLOR" );
		GLOBAL.editColor.SCE_B_OPERATOR_Fore		= IupGetAttribute( IupGetHandle( "btnSCE_B_OPERATOR_FG" ), "BGCOLOR" );
		GLOBAL.editColor.SCE_B_OPERATOR_Back		= IupGetAttribute( IupGetHandle( "btnSCE_B_OPERATOR_BG" ), "BGCOLOR" );
		GLOBAL.editColor.SCE_B_IDENTIFIER_Fore		= IupGetAttribute( IupGetHandle( "btnSCE_B_IDENTIFIER_FG" ), "BGCOLOR" );
		GLOBAL.editColor.SCE_B_IDENTIFIER_Back		= IupGetAttribute( IupGetHandle( "btnSCE_B_IDENTIFIER_BG" ), "BGCOLOR" );
		GLOBAL.editColor.SCE_B_COMMENTBLOCK_Fore	= IupGetAttribute( IupGetHandle( "btnSCE_B_COMMENTBLOCK_FG" ), "BGCOLOR" );
		GLOBAL.editColor.SCE_B_COMMENTBLOCK_Back	= IupGetAttribute( IupGetHandle( "btnSCE_B_COMMENTBLOCK_BG" ), "BGCOLOR" );
		GLOBAL.editColor.prjTitle					= IupGetAttribute( IupGetHandle( "btnPrjTitle" ), "BGCOLOR" );
		GLOBAL.editColor.prjSourceType				= IupGetAttribute( IupGetHandle( "btnSourceTypeFolder" ), "BGCOLOR" );
		
		
		GLOBAL.editColor.projectFore				= IupGetAttribute( IupGetHandle( "btnPrj_FG" ), "BGCOLOR" );
		GLOBAL.editColor.projectBack				= IupGetAttribute( IupGetHandle( "btnPrj_BG" ), "BGCOLOR" );
		GLOBAL.editColor.outlineFore				= IupGetAttribute( IupGetHandle( "btnOutline_FG" ), "BGCOLOR" );
		GLOBAL.editColor.outlineBack				= IupGetAttribute( IupGetHandle( "btnOutline_BG" ), "BGCOLOR" );
		GLOBAL.editColor.filelistFore				= IupGetAttribute( IupGetHandle( "btnFilelist_FG" ), "BGCOLOR" );
		GLOBAL.editColor.filelistBack				= IupGetAttribute( IupGetHandle( "btnFilelist_BG" ), "BGCOLOR" );
		GLOBAL.editColor.outputFore					= IupGetAttribute( IupGetHandle( "btnOutput_FG" ), "BGCOLOR" );
		GLOBAL.editColor.outputBack					= IupGetAttribute( IupGetHandle( "btnOutput_BG" ), "BGCOLOR" );
		GLOBAL.editColor.searchFore					= IupGetAttribute( IupGetHandle( "btnSearch_FG" ), "BGCOLOR" );
		GLOBAL.editColor.searchBack					= IupGetAttribute( IupGetHandle( "btnSearch_BG" ), "BGCOLOR" );
		
		GLOBAL.projectTree.changeColor();
		GLOBAL.outlineTree.changeColor();
		GLOBAL.fileListTree.changeColor();
		
		IupSetAttribute( GLOBAL.outputPanel, "BGCOLOR", IupGetAttribute( IupGetHandle( "btnOutput_BG" ), "BGCOLOR" ) );
		Ihandle* formattagOutput = IupUser();
		IupSetAttribute(formattagOutput, "SELECTIONPOS", toStringz( "ALL" ));
		IupSetAttribute(formattagOutput, "FGCOLOR", GLOBAL.editColor.outputFore.toCString );
		IupSetAttribute( GLOBAL.outputPanel, "ADDFORMATTAG_HANDLE", cast(char*) formattagOutput);
		
		IupSetAttribute( GLOBAL.searchOutputPanel, "BGCOLOR", IupGetAttribute( IupGetHandle( "btnSearch_BG" ), "BGCOLOR" ) );
		Ihandle* formattagSearch = IupUser();
		IupSetAttribute(formattagSearch, "SELECTIONPOS", toStringz( "ALL" ));
		IupSetAttribute(formattagSearch, "FGCOLOR", GLOBAL.editColor.outputFore.toCString );
		IupSetAttribute( GLOBAL.searchOutputPanel, "ADDFORMATTAG_HANDLE", cast(char*) formattagSearch);
		
		

		// GLOBAL.editColor.keyWord is IupString class
		GLOBAL.editColor.keyWord[0]					= IupGetAttribute( IupGetHandle( "btnKeyWord0Color" ), "BGCOLOR" );
		GLOBAL.editColor.keyWord[1]					= IupGetAttribute( IupGetHandle( "btnKeyWord1Color" ), "BGCOLOR" );
		GLOBAL.editColor.keyWord[2]					= IupGetAttribute( IupGetHandle( "btnKeyWord2Color" ), "BGCOLOR" );
		GLOBAL.editColor.keyWord[3]					= IupGetAttribute( IupGetHandle( "btnKeyWord3Color" ), "BGCOLOR" );


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
		IDECONFIG.save();

		return IUP_CLOSE;
	}

	private int CPreferenceDialog_colorChoose_cb( Ihandle* ih )
	{
		Ihandle* dlg = IupColorDlg();

		IupSetAttribute( dlg, "VALUE", IupGetAttribute( ih, "BGCOLOR" ) );
		//IupSetAttribute(dlg, "ALPHA", "142");
		IupSetAttribute(dlg, "SHOWHEX", "YES");
		IupSetAttribute(dlg, "SHOWCOLORTABLE", "YES");
		IupSetAttribute(dlg, "TITLE", toStringz( GLOBAL.languageItems["color"] ) );

		IupPopup( dlg, IUP_CURRENT, IUP_CURRENT );

		if( IupGetInt( dlg, "STATUS" ) ) IupSetAttribute( ih, "BGCOLOR", IupGetAttribute( dlg, "VALUE" ) );

		return IUP_DEFAULT;
	}
	
	private int CPreferenceDialog_colorChooseScintilla_cb( Ihandle* ih )
	{
		Ihandle* dlg = IupColorDlg();

		IupSetAttribute( dlg, "VALUE", IupGetAttribute( ih, "BGCOLOR" ) );
		IupSetAttribute(dlg, "SHOWHEX", "YES");
		IupSetAttribute(dlg, "SHOWCOLORTABLE", "YES");
		IupSetAttribute(dlg, "TITLE", toStringz( GLOBAL.languageItems["color"] ) );

		IupPopup( dlg, IUP_CURRENT, IUP_CURRENT );

		if( IupGetInt( dlg, "STATUS" ) )
		{
			IupSetAttribute( ih, "BGCOLOR", IupGetAttribute( dlg, "VALUE" ) );
			
			scope cStringDocument = new CstringConvert( GLOBAL.languageItems["applycolor"] );
			
			Ihandle* messageDlg = IupMessageDlg();
			IupSetAttributes( messageDlg, "DIALOGTYPE=QUESTION,BUTTONDEFAULT=2,BUTTONS=YESNO" );
			IupSetAttribute( messageDlg, "VALUE", cStringDocument.toStringz );
			IupSetAttribute( messageDlg, "TITLE", toStringz( GLOBAL.languageItems["quest"] ) );
			IupPopup( messageDlg, IUP_CENTER, IUP_CENTER );		
			int button = IupGetInt( messageDlg, "BUTTONRESPONSE" );
			
			if( button == 1 )
			{
				Ihandle* _ih = IupGetHandle( "btnSCE_B_COMMENT_BG" );
				if( ih != null ) IupSetAttribute( _ih, "BGCOLOR", IupGetAttribute( dlg, "VALUE" ) );
				
				_ih = IupGetHandle( "btnSCE_B_NUMBER_BG" );
				if( ih != null ) IupSetAttribute( _ih, "BGCOLOR", IupGetAttribute( dlg, "VALUE" ) );
				
				_ih = IupGetHandle( "btnSCE_B_STRING_BG" );
				if( ih != null ) IupSetAttribute( _ih, "BGCOLOR", IupGetAttribute( dlg, "VALUE" ) );
				
				_ih = IupGetHandle( "btnSCE_B_PREPROCESSOR_BG" );
				if( ih != null ) IupSetAttribute( _ih, "BGCOLOR", IupGetAttribute( dlg, "VALUE" ) );
				
				_ih = IupGetHandle( "btnSCE_B_OPERATOR_BG" );
				if( ih != null ) IupSetAttribute( _ih, "BGCOLOR", IupGetAttribute( dlg, "VALUE" ) );
				
				_ih = IupGetHandle( "btnSCE_B_IDENTIFIER_BG" );
				if( ih != null ) IupSetAttribute( _ih, "BGCOLOR", IupGetAttribute( dlg, "VALUE" ) );
				
				_ih = IupGetHandle( "btnSCE_B_COMMENTBLOCK_BG" );
				if( ih != null ) IupSetAttribute( _ih, "BGCOLOR", IupGetAttribute( dlg, "VALUE" ) );
			}			
			
		}

		return IUP_DEFAULT;
	}	
}