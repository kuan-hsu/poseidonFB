module dialogs.preferenceDlg;

private import iup.iup, iup.iup_scintilla;

private import global, IDE, project, tools, scintilla, actionManager;
private import dialogs.baseDlg, dialogs.helpDlg, dialogs.fileDlg, dialogs.shortcutDlg;

private import tango.stdc.stringz, tango.io.Stdout, tango.io.FilePath;

class CPreferenceDialog : CBaseDialog
{
	private:
	Ihandle*			textCompilerPath, textDebuggerPath;
	IupString[15]		_stringOfLabel;
	
	static		IupString[48]		kbg;

	void createLayout()
	{
		Ihandle* bottom = createDlgButton( "40x12", "aoc" );

		textCompilerPath = IupText( null );
		IupSetAttribute( textCompilerPath, "SIZE", "320x16" );
		IupSetAttribute( textCompilerPath, "VALUE", GLOBAL.compilerFullPath.toCString );
		IupSetHandle( "compilerPath_Handle", textCompilerPath );
		
		Ihandle* btnOpen = IupButton( null, null );
		IupSetAttribute( btnOpen, "IMAGE", "icon_openfile" );
		IupSetCallback( btnOpen, "ACTION", cast(Icallback) &CPreferenceDialog_OpenCompileBinFile_cb );
		
		Ihandle* _hBox01 = IupHbox( textCompilerPath, btnOpen, null );
		IupSetAttributes( _hBox01, "ALIGNMENT=ACENTER,MARGIN=5x0" );
		
		Ihandle* hBox01 = IupFrame( _hBox01 );
		IupSetAttribute( hBox01, "TITLE", GLOBAL.languageItems["compilerpath"].toCString );
		IupSetAttributes( hBox01, "EXPANDCHILDREN=YES,SIZE=346x");

		version(FBIDE)
		{
			Ihandle* textx64CompilerPath = IupText( null );
			IupSetAttribute( textx64CompilerPath, "SIZE", "320x16" );
			IupSetAttribute( textx64CompilerPath, "VALUE", GLOBAL.x64compilerFullPath.toCString );
			IupSetHandle( "x64compilerPath_Handle", textx64CompilerPath );
			
			Ihandle* btnx64Open = IupButton( null, null );
			IupSetAttribute( btnx64Open, "IMAGE", "icon_openfile" );
			IupSetCallback( btnx64Open, "ACTION", cast(Icallback) &CPreferenceDialog_Openx64CompileBinFile_cb );
			
			Ihandle* _hBox01x64 = IupHbox( textx64CompilerPath, btnx64Open, null );
			IupSetAttributes( _hBox01x64, "ALIGNMENT=ACENTER,MARGIN=5x0" );
			
			Ihandle* hBox01x64 = IupFrame( _hBox01x64 );
			IupSetAttribute( hBox01x64, "TITLE", GLOBAL.languageItems["x64path"].toCString );
			IupSetAttributes( hBox01x64, "EXPANDCHILDREN=YES,SIZE=346x");



			textDebuggerPath = IupText( null );
			IupSetAttribute( textDebuggerPath, "SIZE", "320x16" );
			IupSetAttribute( textDebuggerPath, "VALUE", GLOBAL.debuggerFullPath.toCString );
			IupSetHandle( "debuggerPath_Handle", textDebuggerPath );
			
			Ihandle* btnOpenDebugger = IupButton( null, null );
			IupSetAttribute( btnOpenDebugger, "IMAGE", "icon_openfile" );
			IupSetCallback( btnOpenDebugger, "ACTION", cast(Icallback) &CPreferenceDialog_OpenDebuggerBinFile_cb );

			Ihandle* _hBox02 = IupHbox( textDebuggerPath, btnOpenDebugger, null );
			IupSetAttributes( _hBox02, "ALIGNMENT=ACENTER,MARGIN=5x0" );
			
			Ihandle* hBox02 = IupFrame( _hBox02 );
			IupSetAttribute( hBox02, "TITLE", GLOBAL.languageItems["debugpath"].toCString );
			IupSetAttributes( hBox02, "EXPANDCHILDREN=YES,SIZE=346x");
		}
		
		
		
		/+
		Ihandle* labelDefaultOption = IupLabel( toStringz( GLOBAL.languageItems["compileropts"].toDString ~ ":" ) );
		IupSetAttributes( labelDefaultOption, "SIZE=60x12,ALIGNMENT=ARIGHT:ACENTER,VISIBLELINES=1,VISIBLECOLUMNS=1" );
		
		Ihandle* textDefaultOption = IupText( null );
		IupSetAttribute( textDefaultOption, "SIZE", "210x12" );
		IupSetAttribute( textDefaultOption, "VALUE", GLOBAL.defaultOption.toCString );
		IupSetHandle( "defaultOption_Handle", textDefaultOption );

		Ihandle* btnCompilerOpts = IupButton( null, null );
		IupSetAttributes( btnCompilerOpts, "IMAGE=icon_help" );
		IupSetCallback( btnCompilerOpts, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			GLOBAL.compilerHelpDlg.show( IUP_MOUSEPOS, IUP_MOUSEPOS );
			return IUP_DEFAULT;
		});	


		Ihandle* hBox03 = IupHbox( labelDefaultOption, textDefaultOption, btnCompilerOpts, null );
		IupSetAttributes( hBox03, "ALIGNMENT=ACENTER,MARGIN=5x0" );
		+/


		// compiler Setting
		Ihandle* toggleAnnotation = IupToggle( GLOBAL.languageItems["errorannotation"].toCString, null );
		IupSetAttribute( toggleAnnotation, "VALUE", toStringz(GLOBAL.compilerAnootation.dup) );
		IupSetHandle( "toggleAnnotation", toggleAnnotation );
		
		Ihandle* toggleShowResultWindow = IupToggle( GLOBAL.languageItems["showresultwindow"].toCString, null );
		IupSetAttribute( toggleShowResultWindow, "VALUE", toStringz(GLOBAL.compilerWindow.dup) );
		IupSetHandle( "toggleShowResultWindow", toggleShowResultWindow );
		
		Ihandle* toggleSFX = IupToggle( GLOBAL.languageItems["usesfx"].toCString, null );
		IupSetAttribute( toggleSFX, "VALUE", toStringz(GLOBAL.compilerSFX.dup) );
		IupSetHandle( "toggleSFX", toggleSFX );

		Ihandle* toggleDelPrevEXE = IupToggle( GLOBAL.languageItems["delexistexe"].toCString, null );
		IupSetAttribute( toggleDelPrevEXE, "VALUE", toStringz(GLOBAL.delExistExe.dup) );
		IupSetHandle( "toggleDelPrevEXE", toggleDelPrevEXE );
		
		Ihandle* toggleConsoleExe = IupToggle( GLOBAL.languageItems["consoleexe"].toCString, null );
		IupSetAttribute( toggleConsoleExe, "VALUE", toStringz(GLOBAL.consoleExe.dup) );
		IupSetHandle( "toggleConsoleExe", toggleConsoleExe );
		
		Ihandle* labelMonitorID = IupLabel( "ID:" );
		Ihandle* labelConsoleX = IupLabel( "ConsoleX:" );
		Ihandle* labelConsoleY = IupLabel( "ConsoleY:" );
		Ihandle* labelConsoleW = IupLabel( "ConsoleW:" );
		Ihandle* labelConsoleH = IupLabel( "ConsoleH:" );
		Ihandle* textMonitorID = IupText( null );
		Ihandle* textConsoleX = IupText( null );
		Ihandle* textConsoleY = IupText( null );
		Ihandle* textConsoleW = IupText( null );
		Ihandle* textConsoleH = IupText( null );
		
		IupSetAttribute( textMonitorID, "VALUE", toStringz( Integer.toString( GLOBAL.consoleWindow.id + 1 ) ) );
		IupSetAttribute( textConsoleX, "VALUE", toStringz( Integer.toString( GLOBAL.consoleWindow.x ) ) );
		IupSetAttribute( textConsoleY, "VALUE", toStringz( Integer.toString( GLOBAL.consoleWindow.y ) ) );
		IupSetAttribute( textConsoleW, "VALUE", toStringz( Integer.toString( GLOBAL.consoleWindow.w ) ) );
		IupSetAttribute( textConsoleH, "VALUE", toStringz( Integer.toString( GLOBAL.consoleWindow.h ) ) );

		IupSetAttribute( textMonitorID, "SIZE", "20x" );
		IupSetAttribute( textConsoleX, "SIZE", "20x" );
		IupSetAttribute( textConsoleY, "SIZE", "20x" );
		IupSetAttribute( textConsoleW, "SIZE", "20x" );
		IupSetAttribute( textConsoleH, "SIZE", "20x" );
		
		if( GLOBAL.monitors.length == 1 )
		{
			IupSetAttribute( textMonitorID, "VALUE", "1" );
			IupSetAttribute( textMonitorID, "ACTIVE", "NO" );
			IupSetAttribute( labelMonitorID, "ACTIVE", "NO" );
		}
		else
		{
			IupSetAttribute( textMonitorID, "ACTIVE", "YES" );
			IupSetAttribute( labelMonitorID, "ACTIVE", "YES" );
		}
		
		IupSetAttribute( textMonitorID, "NAME", "textMonitorID" );
		IupSetAttribute( textConsoleX, "NAME", "textConsoleX" );
		IupSetAttribute( textConsoleY, "NAME", "textConsoleY" );
		IupSetAttribute( textConsoleW, "NAME", "textConsoleW" );
		IupSetAttribute( textConsoleH, "NAME", "textConsoleH" );

		
		Ihandle* hBoxConsole = IupHbox( labelMonitorID, textMonitorID, labelConsoleX, textConsoleX, labelConsoleY, textConsoleY, labelConsoleW, textConsoleW, labelConsoleH, textConsoleH, null );
		IupSetAttributes( hBoxConsole, "ALIGNMENT=ACENTER" );
		

		Ihandle* vBoxCompiler = IupVbox( toggleAnnotation, toggleShowResultWindow, toggleSFX, toggleDelPrevEXE, toggleConsoleExe, hBoxConsole, null );
		version(FBIDE)	IupSetAttributes( vBoxCompiler, "GAP=10,MARGIN=0x1,EXPANDCHILDREN=NO" );
		version(DIDE)	IupSetAttributes( vBoxCompiler, "GAP=16,MARGIN=0x1,EXPANDCHILDREN=NO" );

		Ihandle* frameCompiler = IupFrame( vBoxCompiler );
		IupSetAttribute( frameCompiler, "TITLE", GLOBAL.languageItems["compilersetting"].toCString );
		IupSetAttributes( frameCompiler, "EXPANDCHILDREN=YES,SIZE=346x");
		
		
		// Manual
		Ihandle* toggleUseManual = IupToggle( GLOBAL.languageItems["manualusing"].toCString(), null );
		IupSetAttribute( toggleUseManual, "VALUE", toStringz(GLOBAL.toggleUseManual.dup) );
		IupSetHandle( "toggleUseManual", toggleUseManual );
		
		Ihandle* labelchm = IupLabel( toStringz( GLOBAL.languageItems["manualpath"].toDString ~ ":" ) );
		IupSetAttributes( labelchm, "SIZE=94x12,ALIGNMENT=ALEFT:ACENTER,VISIBLELINES=1,VISIBLECOLUMNS=1" );
		
		Ihandle* textchm = IupText( null );
		IupSetAttribute( textchm, "SIZE", "224x12" );
		IupSetAttribute( textchm, "VALUE", GLOBAL.manualPath.toCString );
		IupSetHandle( "textchm", textchm );
		
		Ihandle* btnchm = IupButton( null, null );
		IupSetAttribute( btnchm, "IMAGE", "icon_openfile" );
		IupSetCallback( btnchm, "ACTION", cast(Icallback) &CPreferenceDialog_OpenCHM_cb );

		Ihandle* hBoxChm = IupHbox( labelchm, textchm, btnchm, null );
		IupSetAttributes( hBoxChm, "ALIGNMENT=ACENTER,MARGIN=5x0" );
		
		version(FBIDE)
		{
			Ihandle* vBoxChm = IupVbox( hBoxChm, toggleUseManual, null );
			Ihandle* manuFrame = IupFrame( vBoxChm );
		}
		version(DIDE)
		{
			Ihandle* manuFrame = IupFrame( hBoxChm );
		}
		IupSetAttribute( manuFrame, "TITLE", GLOBAL.languageItems["manual"].toCString() );
		IupSetAttribute( manuFrame, "SIZE", "346x");		
		
		
		version(FBIDE)
		{
			Ihandle* vBoxCompilerSettings = IupVbox( hBox01, hBox01x64, hBox02, frameCompiler, manuFrame, null );
			IupSetAttributes( vBoxCompilerSettings, "ALIGNMENT=ALEFT,MARGIN=2x5");
			IupSetAttribute( vBoxCompilerSettings, "EXPANDCHILDREN", "YES");
		}
		version(DIDE)
		{
			Ihandle* vBoxCompilerSettings = IupVbox( hBox01, frameCompiler, manuFrame, null );
			IupSetAttributes( vBoxCompilerSettings, "ALIGNMENT=ALEFT,MARGIN=2x5");
			IupSetAttribute( vBoxCompilerSettings, "EXPANDCHILDREN", "YES");
		}
		
		
		
		
		

		// Parser Setting
		Ihandle* toggleKeywordComplete = IupToggle( GLOBAL.languageItems["enablekeyword"].toCString, null );
		IupSetAttribute( toggleKeywordComplete, "VALUE", toStringz(GLOBAL.enableKeywordComplete.dup) );
		IupSetHandle( "toggleKeywordComplete", toggleKeywordComplete );
		
		Ihandle* toggleIncludeComplete = IupToggle( GLOBAL.languageItems["enableinclude"].toCString, null );
		IupSetAttribute( toggleIncludeComplete, "VALUE", toStringz(GLOBAL.enableIncludeComplete.dup) );
		IupSetHandle( "toggleIncludeComplete", toggleIncludeComplete );
		
		Ihandle* toggleUseParser = IupToggle( GLOBAL.languageItems["enableparser"].toCString, null );
		IupSetAttribute( toggleUseParser, "VALUE", toStringz(GLOBAL.enableParser.dup) );
		IupSetHandle( "toggleUseParser", toggleUseParser );
		
		Ihandle* labelTrigger = IupLabel( toStringz( GLOBAL.languageItems["trigger"].toDString ~ ":" ) );
		IupSetAttributes( labelTrigger, "SIZE=120x12" );
		
		Ihandle* textTrigger = IupText( null );
		IupSetAttribute( textTrigger, "SIZE", "30x12" );
		IupSetAttribute( textTrigger, "TIP", GLOBAL.languageItems["triggertip"].toCString );
		IupSetAttribute( textTrigger, "VALUE", toStringz( Integer.toString( GLOBAL.autoCompletionTriggerWordCount ) ) );
		IupSetHandle( "textTrigger", textTrigger );

		Ihandle* labelIncludeLevel = IupLabel( toStringz( GLOBAL.languageItems["includelevel"].toDString ~ ":" ) );
		IupSetAttributes( labelIncludeLevel, "SIZE=120x12,GAP=0" );
		
		Ihandle* textIncludeLevel = IupText( null );
		IupSetAttribute( textIncludeLevel, "SIZE", "30x12" );
		IupSetAttribute( textIncludeLevel, "VALUE", toStringz( Integer.toString( GLOBAL.includeLevel ) ) );
		IupSetHandle( "textIncludeLevel", textIncludeLevel );

		
		Ihandle* toggleWithParams = IupToggle( GLOBAL.languageItems["showtypeparam"].toCString, null );
		IupSetAttribute( toggleWithParams, "VALUE", toStringz(GLOBAL.showTypeWithParams.dup) );
		IupSetHandle( "toggleWithParams", toggleWithParams );

		Ihandle* toggleIGNORECASE = IupToggle( GLOBAL.languageItems["sortignorecase"].toCString, null );
		IupSetAttribute( toggleIGNORECASE, "VALUE", toStringz(GLOBAL.toggleIgnoreCase.dup) );
		IupSetHandle( "toggleIGNORECASE", toggleIGNORECASE );

		Ihandle* toggleCASEINSENSITIVE = IupToggle( GLOBAL.languageItems["selectcase"].toCString, null );
		IupSetAttribute( toggleCASEINSENSITIVE, "VALUE", toStringz(GLOBAL.toggleCaseInsensitive.dup) );
		IupSetHandle( "toggleCASEINSENSITIVE", toggleCASEINSENSITIVE );

		Ihandle* toggleSHOWLISTTYPE = IupToggle( GLOBAL.languageItems["showlisttype"].toCString, null );
		IupSetAttribute( toggleSHOWLISTTYPE, "VALUE", toStringz(GLOBAL.toggleShowListType.dup) );
		IupSetHandle( "toggleSHOWLISTTYPE", toggleSHOWLISTTYPE );

		Ihandle* toggleSHOWALLMEMBER = IupToggle( GLOBAL.languageItems["showallmembers"].toCString, null );
		IupSetAttribute( toggleSHOWALLMEMBER, "VALUE", toStringz(GLOBAL.toggleShowAllMember.dup) );
		IupSetHandle( "toggleSHOWALLMEMBER", toggleSHOWALLMEMBER );
		
		Ihandle* toggleDWELL = IupToggle( GLOBAL.languageItems["enabledwell"].toCString, null );
		IupSetAttribute( toggleDWELL, "VALUE", toStringz(GLOBAL.toggleEnableDwell.dup) );
		IupSetHandle( "toggleDWELL", toggleDWELL );
		
		
		Ihandle* toggleFunctionTitle = IupToggle( GLOBAL.languageItems["showtitle"].toCString, null );
		IupSetAttribute( toggleFunctionTitle, "VALUE", toStringz(GLOBAL.showFunctionTitle.dup) );
		IupSetHandle( "toggleFunctionTitle", toggleFunctionTitle );
		
		Ihandle* labelFunctionTitle = IupLabel( GLOBAL.languageItems["width"].toCString );
		IupSetAttributes( labelFunctionTitle, "SIZE=80x12,ALIGNMENT=ARIGHT:ACENTER" ); 
		Ihandle* textFunctionTitle = IupText( null );
		IupSetAttribute( textFunctionTitle, "SIZE", "30x12" );
		IupSetAttribute( textFunctionTitle, "VALUE", GLOBAL.widthFunctionTitle.toCString );
		IupSetHandle( "textFunctionTitle", textFunctionTitle );
		
		Ihandle* hBoxFunctionTitle = IupHbox( toggleFunctionTitle, labelFunctionTitle, textFunctionTitle, null );
		IupSetAttribute( hBoxFunctionTitle, "ALIGNMENT", "ACENTER" ); 		


		Ihandle* toggleLiveNone = IupToggle( GLOBAL.languageItems["none"].toCString, null );
		IupSetHandle( "toggleLiveNone", toggleLiveNone );

		Ihandle* toggleLiveLight = IupToggle( GLOBAL.languageItems["light"].toCString, null );
		IupSetHandle( "toggleLiveLight", toggleLiveLight );
		
		Ihandle* toggleLiveFull = IupToggle( GLOBAL.languageItems["full"].toCString, null );
		IupSetHandle( "toggleLiveFull", toggleLiveFull );
		//IupSetAttribute( toggleLiveFull, "ACTIVE", "NO" );

		Ihandle* toggleUpdateOutline = IupToggle( GLOBAL.languageItems["update"].toCString, null );
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
		IupSetAttributes( hBoxLive, "ALIGNMENT=ACENTER,NORMALIZESIZE=HORIZONTAL,HOMOGENEOUS=YES" );
		Ihandle* radioLive = IupRadio( hBoxLive );

		Ihandle* hBoxLive2 = IupHbox( radioLive, toggleUpdateOutline, null );
		IupSetAttributes( hBoxLive2, "GAP=30,MARGIN=10x,ALIGNMENT=ACENTER" );
		//IupSetAttributes( hBoxLive2, "ALIGNMENT=ACENTER,NORMALIZESIZE=HORIZONTAL,HOMOGENEOUS=YES,EXPANDCHILDREN=YES" );
		
		Ihandle* frameLive = IupFrame( hBoxLive2 );
		IupSetAttributes( frameLive, "SIZE=346x" );
		IupSetAttribute( frameLive, "TITLE", GLOBAL.languageItems["parserlive"].toCString );


		Ihandle* hBox00 = IupHbox( labelTrigger, textTrigger, labelIncludeLevel, textIncludeLevel,null );
		//Ihandle* hBox00_1 = IupHbox( labelIncludeLevel, textIncludeLevel, null );
		Ihandle* vBox00 = IupVbox( toggleUseParser, toggleKeywordComplete, toggleIncludeComplete, toggleWithParams, toggleIGNORECASE, toggleCASEINSENSITIVE, toggleSHOWLISTTYPE, toggleSHOWALLMEMBER, toggleDWELL, hBoxFunctionTitle, hBox00, null );
		version(FBIDE)	IupSetAttributes( vBox00, "GAP=10,MARGIN=0x1,EXPANDCHILDREN=NO" );
		version(DIDE)	IupSetAttributes( vBox00, "GAP=16,MARGIN=0x1,EXPANDCHILDREN=NO" );
	
		Ihandle* frameParser = IupFrame( vBox00 );
		IupSetAttribute( frameParser, "TITLE",  GLOBAL.languageItems["parsersetting"].toCString );
		IupSetAttribute( frameParser, "EXPANDCHILDREN", "YES");
		IupSetAttribute( frameParser, "SIZE", "346x");


		
		Ihandle* vBoxParserSettings = IupVbox( frameParser, frameLive, null );
		IupSetAttributes( vBoxParserSettings, "ALIGNMENT=ALEFT,MARGIN=2x5");
		IupSetAttribute( vBoxParserSettings, "EXPANDCHILDREN", "YES");
		
		
		
		
		Ihandle* toggleLineMargin = IupToggle( GLOBAL.languageItems["lnmargin"].toCString, null );
		IupSetAttribute( toggleLineMargin, "VALUE", toStringz(GLOBAL.editorSetting00.LineMargin.dup) );
		IupSetHandle( "toggleLineMargin", toggleLineMargin );
		
		Ihandle* toggleFixedLineMargin = IupToggle( GLOBAL.languageItems["fixedlnmargin"].toCString, null );
		IupSetAttribute( toggleFixedLineMargin, "VALUE", toStringz(GLOBAL.editorSetting00.FixedLineMargin.dup) );
		IupSetHandle( "toggleFixedLineMargin", toggleFixedLineMargin );
		
		Ihandle* toggleBookmarkMargin = IupToggle( GLOBAL.languageItems["bkmargin"].toCString, null );
		IupSetAttribute( toggleBookmarkMargin, "VALUE", toStringz(GLOBAL.editorSetting00.BookmarkMargin.dup) );
		IupSetHandle( "toggleBookmarkMargin", toggleBookmarkMargin );
		
		Ihandle* toggleFoldMargin = IupToggle( GLOBAL.languageItems["fdmargin"].toCString, null );
		IupSetAttribute( toggleFoldMargin, "VALUE", toStringz(GLOBAL.editorSetting00.FoldMargin.dup) );
		IupSetHandle( "toggleFoldMargin", toggleFoldMargin );
		
		Ihandle* toggleIndentGuide = IupToggle(  GLOBAL.languageItems["indentguide"].toCString, null );
		IupSetAttribute( toggleIndentGuide, "VALUE", toStringz(GLOBAL.editorSetting00.IndentGuide.dup) );
		IupSetHandle( "toggleIndentGuide", toggleIndentGuide );
		
		Ihandle* toggleCaretLine = IupToggle( GLOBAL.languageItems["showcaretline"].toCString, null );
		IupSetAttribute( toggleCaretLine, "VALUE", toStringz(GLOBAL.editorSetting00.CaretLine.dup) );
		IupSetHandle( "toggleCaretLine", toggleCaretLine );
		
		Ihandle* toggleWordWrap = IupToggle( GLOBAL.languageItems["wordwarp"].toCString, null );
		IupSetAttribute( toggleWordWrap, "VALUE", toStringz(GLOBAL.editorSetting00.WordWrap.dup) );
		IupSetHandle( "toggleWordWrap", toggleWordWrap );
		
		Ihandle* toggleTabUseingSpace = IupToggle( GLOBAL.languageItems["tabtospace"].toCString, null );
		IupSetAttribute( toggleTabUseingSpace, "VALUE", toStringz(GLOBAL.editorSetting00.TabUseingSpace.dup) );
		IupSetHandle( "toggleTabUseingSpace", toggleTabUseingSpace );
		
		Ihandle* toggleAutoIndent = IupToggle( GLOBAL.languageItems["autoindent"].toCString, null );
		IupSetAttribute( toggleAutoIndent, "VALUE", toStringz(GLOBAL.editorSetting00.AutoIndent.dup) );
		IupSetHandle( "toggleAutoIndent", toggleAutoIndent );

		Ihandle* toggleShowEOL = IupToggle( GLOBAL.languageItems["showeol"].toCString, null );
		IupSetAttribute( toggleShowEOL, "VALUE", toStringz(GLOBAL.editorSetting00.ShowEOL.dup) );
		IupSetHandle( "toggleShowEOL", toggleShowEOL );

		Ihandle* toggleShowSpace = IupToggle( GLOBAL.languageItems["showspacetab"].toCString, null );
		IupSetAttribute( toggleShowSpace, "VALUE", toStringz(GLOBAL.editorSetting00.ShowSpace.dup) );
		IupSetHandle( "toggleShowSpace", toggleShowSpace );

		version(FBIDE)
		{
			Ihandle* toggleAutoEnd = IupToggle( GLOBAL.languageItems["autoinsertend"].toCString, null );
			IupSetAttribute( toggleAutoEnd, "VALUE", toStringz(GLOBAL.editorSetting00.AutoEnd.dup) );
			IupSetHandle( "toggleAutoEnd", toggleAutoEnd );
		}
		
		Ihandle* toggleAutoClose = IupToggle( GLOBAL.languageItems["autoclose"].toCString, null );
		IupSetAttribute( toggleAutoClose, "VALUE", toStringz(GLOBAL.editorSetting00.AutoClose.dup) );
		IupSetHandle( "toggleAutoClose", toggleAutoClose );

		Ihandle* toggleColorOutline = IupToggle( GLOBAL.languageItems["coloroutline"].toCString, null );
		IupSetAttribute( toggleColorOutline, "VALUE", toStringz(GLOBAL.editorSetting00.ColorOutline.dup) );
		IupSetHandle( "toggleColorOutline", toggleColorOutline );		

		Ihandle* toggleMessage = IupToggle( GLOBAL.languageItems["showidemessage"].toCString, null );
		IupSetAttribute( toggleMessage, "VALUE", toStringz(GLOBAL.editorSetting00.Message.dup) );
		IupSetHandle( "toggleMessage", toggleMessage );		

		Ihandle* toggleBoldKeyword = IupToggle( GLOBAL.languageItems["boldkeyword"].toCString, null );
		IupSetAttribute( toggleBoldKeyword, "VALUE", toStringz(GLOBAL.editorSetting00.BoldKeyword.dup) );
		IupSetHandle( "toggleBoldKeyword", toggleBoldKeyword );
		
		Ihandle* toggleBraceMatch = IupToggle( GLOBAL.languageItems["bracematchhighlight"].toCString, null );
		IupSetAttribute( toggleBraceMatch, "VALUE", toStringz(GLOBAL.editorSetting00.BraceMatchHighlight.dup) );
		IupSetHandle( "toggleBraceMatch", toggleBraceMatch );		

		Ihandle* toggleMultiSelection = IupToggle( GLOBAL.languageItems["multiselection"].toCString, null );
		IupSetAttribute( toggleMultiSelection, "VALUE", toStringz(GLOBAL.editorSetting00.MultiSelection.dup) );
		IupSetHandle( "toggleMultiSelection", toggleMultiSelection );			

		Ihandle* toggleLoadprev = IupToggle( GLOBAL.languageItems["loadprevdoc"].toCString, null );
		IupSetAttribute( toggleLoadprev, "VALUE", toStringz(GLOBAL.editorSetting00.LoadPrevDoc.dup) );
		IupSetHandle( "toggleLoadprev", toggleLoadprev );			

		Ihandle* toggleCurrentWord = IupToggle( GLOBAL.languageItems["hlcurrentword"].toCString, null );
		IupSetAttribute( toggleCurrentWord, "VALUE", toStringz(GLOBAL.editorSetting00.HighlightCurrentWord.dup) );
		IupSetHandle( "toggleCurrentWord", toggleCurrentWord );			

		Ihandle* toggleMiddleScroll = IupToggle( GLOBAL.languageItems["middlescroll"].toCString, null );
		IupSetAttribute( toggleMiddleScroll, "VALUE", toStringz(GLOBAL.editorSetting00.MiddleScroll.dup) );
		IupSetHandle( "toggleMiddleScroll", toggleMiddleScroll );
		
		Ihandle* labelSetControlCharSymbol = IupLabel( toStringz( GLOBAL.languageItems["controlcharsymbol"].toDString ~ ":" ) );
		Ihandle* textSetControlCharSymbol = IupText( null );
		IupSetAttribute( textSetControlCharSymbol, "VALUE", toStringz(GLOBAL.editorSetting00.ControlCharSymbol) );
		IupSetHandle( "textSetControlCharSymbol", textSetControlCharSymbol );
		Ihandle* hBoxControlChar = IupHbox( labelSetControlCharSymbol, textSetControlCharSymbol, null );
		IupSetAttribute( hBoxControlChar, "ALIGNMENT", "ACENTER" );
		
		
		
		Ihandle* labelTabWidth = IupLabel( toStringz( GLOBAL.languageItems["tabwidth"].toDString ~ ":" ) );
		Ihandle* textTabWidth = IupText( null );
		IupSetAttribute( textTabWidth, "VALUE", toStringz(GLOBAL.editorSetting00.TabWidth) );
		IupSetHandle( "textTabWidth", textTabWidth );
		Ihandle* hBoxTab = IupHbox( labelTabWidth, textTabWidth, null );
		IupSetAttribute( hBoxTab, "ALIGNMENT", "ACENTER" );
		
		Ihandle* labelColumnEdge = IupLabel( toStringz( GLOBAL.languageItems["columnedge"].toDString ~ ":" ) );
		Ihandle* textColumnEdge = IupText( null );
		IupSetAttribute( textColumnEdge, "VALUE", toStringz(GLOBAL.editorSetting00.ColumnEdge.dup) );
		IupSetAttribute( textColumnEdge, "TIP", GLOBAL.languageItems["triggertip"].toCString );
		IupSetHandle( "textColumnEdge", textColumnEdge );
		Ihandle* hBoxColumn = IupHbox( labelColumnEdge, textColumnEdge, null );
		IupSetAttribute( hBoxColumn, "ALIGNMENT", "ACENTER" );

		Ihandle* labelBarsize = IupLabel( toStringz( GLOBAL.languageItems["barsize"].toDString ~ ":" ) );
		Ihandle* textBarSize = IupText( null );
		IupSetAttribute( textBarSize, "VALUE", toStringz(GLOBAL.editorSetting01.BarSize.dup) );
		IupSetAttribute( textBarSize, "TIP", GLOBAL.languageItems["barsizetip"].toCString );
		IupSetHandle( "textBarSize", textBarSize );
		Ihandle* hBoxBarSize = IupHbox( labelBarsize, textBarSize, null );
		IupSetAttribute( hBoxBarSize, "ALIGNMENT", "ACENTER" );


		version(FBIDE)
		{
			Ihandle* gbox = IupGridBox
			(
				IupSetAttributes( toggleLineMargin, "" ),
				IupSetAttributes( toggleFixedLineMargin, "" ),
				
				IupSetAttributes( toggleBookmarkMargin,"" ),
				IupSetAttributes( toggleFoldMargin, "" ),
				
				IupSetAttributes( toggleIndentGuide, "" ),
				IupSetAttributes( toggleCaretLine, "" ),
				
				IupSetAttributes( toggleWordWrap, "" ),
				IupSetAttributes( toggleTabUseingSpace, "" ),
				
				IupSetAttributes( toggleShowEOL, "" ),
				IupSetAttributes( toggleShowSpace, "" ),

				IupSetAttributes( toggleAutoIndent, "" ),
				IupSetAttributes( toggleAutoEnd, "" ),
				
				IupSetAttributes( toggleAutoClose, "" ),
				IupSetAttributes( toggleColorOutline, "" ),
				
				IupSetAttributes( toggleMessage, "" ),
				IupSetAttributes( toggleBoldKeyword, "" ),
				
				IupSetAttributes( toggleBraceMatch, "" ),
				IupSetAttributes( toggleLoadprev, "" ),

				IupSetAttributes( toggleMultiSelection, "" ),
				IupSetAttributes( toggleCurrentWord, "" ),

				IupSetAttributes( toggleMiddleScroll, "" ),
				hBoxControlChar,
				
				IupSetAttributes( hBoxTab, "" ),
				IupSetAttributes( hBoxColumn, "" ),
				
				IupSetAttributes( hBoxBarSize, "" ),
				IupFill(),
				
				null
			);
		}
		version(DIDE)
		{
			Ihandle* gbox = IupGridBox
			(
				IupSetAttributes( toggleLineMargin, "" ),
				IupSetAttributes( toggleFixedLineMargin, "" ),
				
				IupSetAttributes( toggleBookmarkMargin,"" ),
				IupSetAttributes( toggleFoldMargin, "" ),
				
				IupSetAttributes( toggleIndentGuide, "" ),
				IupSetAttributes( toggleCaretLine, "" ),
				
				IupSetAttributes( toggleWordWrap, "" ),
				IupSetAttributes( toggleTabUseingSpace, "" ),
				
				IupSetAttributes( toggleShowEOL, "" ),
				IupSetAttributes( toggleShowSpace, "" ),

				IupSetAttributes( toggleAutoIndent, "" ),
				IupSetAttributes( toggleAutoClose, "" ),
				
				IupSetAttributes( toggleColorOutline, "" ),
				IupSetAttributes( toggleMessage, "" ),

				IupSetAttributes( toggleBoldKeyword, "" ),
				IupSetAttributes( toggleLoadprev, "" ),
				
				IupSetAttributes( toggleBraceMatch, "" ),
				IupSetAttributes( toggleMultiSelection, "" ),

				IupSetAttributes( toggleCurrentWord, "" ),
				IupSetAttributes( toggleMiddleScroll, "" ),

				IupSetAttributes( hBoxTab, "" ),
				IupSetAttributes( hBoxColumn, "" ),
				
				hBoxControlChar,
				IupSetAttributes( hBoxBarSize, "" ),
				
				null
			);
		}

		//IupSetAttribute(gbox, "SIZECOL", "1");
		//IupSetAttribute(gbox, "SIZELIN", "4");
		IupSetAttributes( gbox, "NUMDIV=2,ALIGNMENTLIN=ACENTER,GAPLIN=9,EXPANDCHILDREN=YES,MARGIN=0x0" );
		
		
		// Mark High Light Line
		Ihandle* labelMarker0 = IupLabel( toStringz( GLOBAL.languageItems["maker0"].toDString ~ ": " ) );
		Ihandle* btnMarker0Color = IupButton( null, null );
		IupSetAttribute( btnMarker0Color, "BGCOLOR",GLOBAL.editColor.maker[0].toCString );
		version(Windows) IupSetAttribute( btnMarker0Color, "SIZE", "24x8" ); else IupSetAttribute( btnMarker0Color, "SIZE", "24x10" );
		IupSetHandle( "btnMarker0Color", btnMarker0Color );
		IupSetCallback( btnMarker0Color, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		
		Ihandle* labelMarker1 = IupLabel( toStringz( GLOBAL.languageItems["maker1"].toDString ~ ": " ) );
		Ihandle* btnMarker1Color = IupButton( null, null );
		IupSetAttribute( btnMarker1Color, "BGCOLOR",GLOBAL.editColor.maker[1].toCString );
		version(Windows) IupSetAttribute( btnMarker1Color, "SIZE", "24x8" ); else IupSetAttribute( btnMarker1Color, "SIZE", "24x10" );
		IupSetHandle( "btnMarker1Color", btnMarker1Color );
		IupSetCallback( btnMarker1Color, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelMarker2 = IupLabel( toStringz( GLOBAL.languageItems["maker2"].toDString ~ ": " ) );
		Ihandle* btnMarker2Color = IupButton( null, null );
		IupSetAttribute( btnMarker2Color, "BGCOLOR",GLOBAL.editColor.maker[2].toCString );
		version(Windows) IupSetAttribute( btnMarker2Color, "SIZE", "24x8" ); else IupSetAttribute( btnMarker2Color, "SIZE", "24x10" );
		IupSetHandle( "btnMarker2Color", btnMarker2Color );
		IupSetCallback( btnMarker2Color, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelMarker3 = IupLabel( toStringz( GLOBAL.languageItems["maker3"].toDString ~ ": " ) );
		Ihandle* btnMarker3Color = IupButton( null, null );
		IupSetAttribute( btnMarker3Color, "BGCOLOR",GLOBAL.editColor.maker[3].toCString );
		version(Windows) IupSetAttribute( btnMarker3Color, "SIZE", "24x8" ); else IupSetAttribute( btnMarker3Color, "SIZE", "24x10" );
		IupSetHandle( "btnMarker3Color", btnMarker3Color );
		IupSetCallback( btnMarker3Color, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		
		Ihandle* gboxMarkerColor = IupGridBox
		(
			labelMarker0,
			btnMarker0Color,
			labelMarker1,
			btnMarker1Color,

			labelMarker2,
			btnMarker2Color,
			labelMarker3,
			btnMarker3Color,

			null
		);
		IupSetAttributes( gboxMarkerColor, "EXPAND=YES,NUMDIV=8,ALIGNMENTLIN=ACENTER,ALIGNMENTCOL=ACENTER,GAPLIN=0,GAPCOL=10,MARGIN=0x5,SIZELIN=0,HOMOGENEOUSCOL=YES,NAME=gridbox_Maker" );
		
		version(FBIDE)
		{
			Ihandle* radioKeywordCase0 = IupToggle( GLOBAL.languageItems["none"].toCString, null );
			IupSetHandle( "radioKeywordCase0", radioKeywordCase0 );

			Ihandle* radioKeywordCase1 = IupToggle( GLOBAL.languageItems["lowercase"].toCString, null );
			IupSetHandle( "radioKeywordCase1", radioKeywordCase1 );
			
			Ihandle* radioKeywordCase2 = IupToggle( GLOBAL.languageItems["uppercase"].toCString, null );
			IupSetHandle( "radioKeywordCase2", radioKeywordCase2 );

			Ihandle* radioKeywordCase3 = IupToggle( GLOBAL.languageItems["mixercase"].toCString, null );
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
			IupSetAttributes( frameKeywordCase, "SIZE=346x,GAP=1" );
			IupSetAttribute( frameKeywordCase, "TITLE", GLOBAL.languageItems["autoconvertkeyword"].toCString );
		}
		
		
		
		Ihandle*[15]	lableString, flatFrame;
		
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
					if( s.length )
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
				}
				
				version(Windows)
				{
					if( _stringOfLabel[i] is null ) 
						_stringOfLabel[i] = new IupString( Stdout.layout.convert( "{,-48}\t{,-4} {,-6} {,-9} {,-9} {,-3}", strings[0], Bold, Italic, Underline, Strikeout, size ) );
					else
						_stringOfLabel[i] = Stdout.layout.convert( "{,-48}\t{,-4} {,-6} {,-9} {,-9} {,-3}", strings[0], Bold, Italic, Underline, Strikeout, size );
				}
				else
				{
					if( _stringOfLabel[i] is null ) 
						_stringOfLabel[i] = new IupString( Stdout.layout.convert( "{,-46}\t{,-4} {,-6} {,-9} {,-9} {,-3}", strings[0], Bold, Italic, Underline, Strikeout, size ) );
					else
						_stringOfLabel[i] = Stdout.layout.convert( "{,-46}\t{,-4} {,-6} {,-9} {,-9} {,-3}", strings[0], Bold, Italic, Underline, Strikeout, size );
				}
				
				lableString[i]	= IupLabel( _stringOfLabel[i].toCString );
				IupSetAttributes( lableString[i], "SIZE=275x,EXPAND=YES");
				
				scope IupFlatFrameString = new IupString( "customFont_" ~ Integer.toString( i ) );
				IupSetHandle( IupFlatFrameString.toCString, lableString[i] );
				IupSetCallback( lableString[i], "BUTTON_CB", cast(Icallback) &CPreferenceDialog_font_BUTTON_CB );
				
				flatFrame[i] = IupFlatFrame( lableString[i] );
				IupSetAttribute( flatFrame[i], "TITLE", GLOBAL.languageItems[GLOBAL.fonts[i].name].toCString );
				
				version( Windows )
				{
					IupSetAttribute( lableString[i], "FONT", "Courier New,9" );
					IupSetAttribute( flatFrame[i], "FONT", "Courier New,9" );
				}
				else
				{
					IupSetAttribute( lableString[i], "FONT", "Ubuntu Mono, 10" );
					IupSetAttribute( flatFrame[i], "FONT", "Ubuntu Mono, 10" );
				}
				
				scope _fontSyle = new IupString( strings[0] );
				IupSetAttribute( flatFrame[i], "FONTFACE", _fontSyle.toCString );
				version(Windows) IupSetAttributes( flatFrame[i], "TITLETEXTALIGNMENT=ACENTER,EXPAND=YES,FONTSIZE=9" ); else IupSetAttributes( flatFrame[i], "SIZE=285x,EXPAND=YES,FONTSIZE=10" );
				IupSetAttribute( flatFrame[i], "TITLEBGCOLOR", "64 128 255");
				IupSetAttribute( flatFrame[i], "TITLECOLOR", "255 255 255");
				
				version( Windows ) IupSetAttribute( lableString[i], "FONTFACE", "Courier New" ); else IupSetAttribute( lableString[i], "FONTFACE", "Ubuntu Mono" );
				
				scope _IupFlatFrameString = new IupString( "customFlatFrame_" ~ Integer.toString( i ) );
				IupSetHandle( _IupFlatFrameString.toCString, flatFrame[i] );
			}
		}
		
		version(DIDE) IupSetAttribute( flatFrame[9], "ACTIVE", "NO" );
		
		Ihandle* visibleBox = IupVbox( flatFrame[0], flatFrame[1], flatFrame[2], flatFrame[3], flatFrame[4], flatFrame[5], flatFrame[6], flatFrame[7], flatFrame[8], flatFrame[9], flatFrame[10], flatFrame[11], flatFrame[12], null );
		IupSetAttributes( visibleBox, "GAP=1,MARGIN=5x1,EXPANDCHILDREN=YES");
		Ihandle* sb = IupFlatScrollBox ( visibleBox );
		IupSetAttributes( sb, "EXPAND=EXPAND,ALIGNMENT=ACENTER" );
		
		
		version(FBIDE)	Ihandle* vBoxPage02 = IupVbox( gbox, gboxMarkerColor, frameKeywordCase, null );
		version(DIDE)	Ihandle* vBoxPage02 = IupVbox( gbox, gboxMarkerColor, null );
		IupSetAttributes( vBoxPage02, "MARGIN=0x1,EXPANDCHILDREN=YES" );

		// Color
		Ihandle* colorTemplateList = IupList( null );
		IupSetHandle( "colorTemplateList", colorTemplateList );
		version(Windows) IupSetAttributes( colorTemplateList, "ACTIVE=YES,EDITBOX=YES,EXPAND=YES,DROPDOWN=YES,VISIBLEITEMS=5" ); else IupSetAttributes( colorTemplateList, "ACTIVE=YES,EDITBOX=YES,SIZE=120x12,DROPDOWN=YES,VISIBLEITEMS=5" );;
		IupSetAttribute( colorTemplateList, "SIZE", "310x12" );
		
		scope templateFP = new FilePath( "settings/colorTemplates" );
		if( templateFP.exists() )
		{
			foreach( _fp; templateFP.toList )
			{
				if( _fp.ext == "xml" ) IupSetAttribute( colorTemplateList, toStringz( Integer.toString( IupGetInt( colorTemplateList, "COUNT" ) + 1 ) ), toStringz( _fp.name.dup ) );
			}
		}
		IupSetAttribute( colorTemplateList, "VALUE", GLOBAL.colorTemplate.toCString );
		IupSetCallback( colorTemplateList, "VALUECHANGED_CB",cast(Icallback) &colorTemplateList_VALUECHANGED_CB );

		Ihandle* colorDefaultRefresh = IupButton( null, null );
		IupSetAttributes( colorDefaultRefresh, "FLAT=NO,IMAGE=icon_refresh" );
		IupSetAttribute( colorDefaultRefresh, "TIP", GLOBAL.languageItems["default"].toCString() );
		IupSetCallback( colorDefaultRefresh, "ACTION", cast(Icallback) &colorTemplateList_reset_ACTION );

		Ihandle* colorTemplateRemove = IupButton( null, null );
		IupSetAttributes( colorTemplateRemove, "FLAT=NO,IMAGE=icon_debug_clear" );
		IupSetAttribute( colorTemplateRemove, "TIP", GLOBAL.languageItems["remove"].toCString() );
		IupSetCallback( colorTemplateRemove, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			Ihandle* _listHandle = IupGetHandle( "colorTemplateList" );
			if( _listHandle != null )
			{
				char[] templateName = Util.trim( fromStringz( IupGetAttribute( _listHandle, "VALUE" ) ) ).dup;
				for( int i = IupGetInt( _listHandle, "COUNT" ); i >= 1; -- i )
				{
					if( fromStringz( IupGetAttributeId( _listHandle, "", i ) ).dup == templateName )
					{
						scope templateFP = new FilePath( "settings/colorTemplates/" ~ templateName ~ ".xml" );
						if( templateFP.exists() )
						{
							int result = IupMessageAlarm( null, GLOBAL.languageItems["alarm"].toCString, GLOBAL.languageItems["suredelete"].toCString, "YESNO" );
							if( result == 1 )
							{
								templateFP.remove;
								IupSetInt( _listHandle, "REMOVEITEM", i );
							}
							else
							{
								return IUP_DEFAULT;
							}
						}
						return colorTemplateList_reset_ACTION( _listHandle );
					}
				}
			}
			
			return IUP_DEFAULT;
		});
		
		
		
		Ihandle* _hboxColorPath = IupHbox( colorTemplateList, colorDefaultRefresh, colorTemplateRemove, null );
		IupSetAttributes( _hboxColorPath, "ALIGNMENT=ACENTER,MARGIN=0x0,EXPAND=NO,SIZE=200x12" );
		

		Ihandle* colorTemplateFrame = IupFrame( _hboxColorPath );
		IupSetAttribute( colorTemplateFrame, "TITLE", GLOBAL.languageItems["colorfile"].toCString() );
		IupSetAttributes( colorTemplateFrame, "EXPANDCHILDREN=YES,SIZE=346x");
		
		
		
		Ihandle* labelCaretLine = IupLabel( toStringz( GLOBAL.languageItems["caretline"].toDString ~ ":" ) );
		Ihandle* btnCaretLine = IupButton( null, null );
		IupSetAttribute( btnCaretLine, "BGCOLOR", GLOBAL.editColor.caretLine.toCString );
		version(Windows) IupSetAttribute( btnCaretLine, "SIZE", "16x8" ); else IupSetAttribute( btnCaretLine, "SIZE", "16x10" );
		IupSetHandle( "btnCaretLine", btnCaretLine );
		IupSetCallback( btnCaretLine, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelCursor = IupLabel( toStringz( GLOBAL.languageItems["cursor"].toDString ~ ":" ) );
		Ihandle* btnCursor = IupButton( null, null );
		IupSetAttribute( btnCursor, "BGCOLOR", GLOBAL.editColor.cursor.toCString );
		version(Windows) IupSetAttribute( btnCursor, "SIZE", "16x8" ); else IupSetAttribute( btnCursor, "SIZE", "16x10" );
		IupSetHandle( "btnCursor", btnCursor );
		IupSetCallback( btnCursor, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelSelectFore = IupLabel( toStringz( GLOBAL.languageItems["sel"].toDString ~ ":" ) );
		Ihandle* btnSelectFore = IupButton( null, null );
		IupSetAttribute( btnSelectFore, "BGCOLOR", GLOBAL.editColor.selectionFore.toCString );
		version(Windows) IupSetAttribute( btnSelectFore, "SIZE", "16x8" ); else IupSetAttribute( btnSelectFore, "SIZE", "16x10" );
		IupSetHandle( "btnSelectFore", btnSelectFore );
		IupSetCallback( btnSelectFore, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* btnSelectBack = IupButton( null, null );
		IupSetAttribute( btnSelectBack, "BGCOLOR", GLOBAL.editColor.selectionBack.toCString );
		version(Windows) IupSetAttribute( btnSelectBack, "SIZE", "16x8" ); else IupSetAttribute( btnSelectBack, "SIZE", "16x10" );
		IupSetHandle( "btnSelectBack", btnSelectBack );
		IupSetCallback( btnSelectBack, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelLinenumFore = IupLabel( toStringz( GLOBAL.languageItems["ln"].toDString ~ ":" ) );
		Ihandle* btnLinenumFore = IupButton( null, null );
		IupSetAttribute( btnLinenumFore, "BGCOLOR", GLOBAL.editColor.linenumFore.toCString );
		version(Windows) IupSetAttribute( btnLinenumFore, "SIZE", "16x8" ); else IupSetAttribute( btnLinenumFore, "SIZE", "16x10" );
		IupSetHandle( "btnLinenumFore", btnLinenumFore );
		IupSetCallback( btnLinenumFore, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* btnLinenumBack = IupButton( null, null );
		IupSetAttribute( btnLinenumBack, "BGCOLOR", GLOBAL.editColor.linenumBack.toCString );
		version(Windows) IupSetAttribute( btnLinenumBack, "SIZE", "16x8" ); else IupSetAttribute( btnLinenumBack, "SIZE", "16x10" );
		IupSetHandle( "btnLinenumBack", btnLinenumBack );
		IupSetCallback( btnLinenumBack, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelFoldingColor = IupLabel( toStringz( GLOBAL.languageItems["foldcolor"].toDString ~ ":" ) );
		Ihandle* btnFoldingColor = IupButton( null, null );
		IupSetAttribute( btnFoldingColor, "BGCOLOR", GLOBAL.editColor.fold.toCString );
		version(Windows) IupSetAttribute( btnFoldingColor, "SIZE", "16x8" ); else IupSetAttribute( btnFoldingColor, "SIZE", "16x10" );
		IupSetHandle( "btnFoldingColor", btnFoldingColor );
		IupSetCallback( btnFoldingColor, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelSelAlpha = IupLabel( toStringz( GLOBAL.languageItems["selalpha"].toDString ~ ":" ) );
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
		IupSetAttribute( textAlpha, "TIP", GLOBAL.languageItems["alphatip"].toCString() );
		IupSetHandle( "textAlpha", textAlpha );
		
		
		// 2017.1.14
		Ihandle* labelPrjTitle = IupLabel( toStringz( GLOBAL.languageItems["prjtitle"].toDString ~ ":" ) );
		Ihandle* btnPrjTitle = IupButton( null, null );
		IupSetAttribute( btnPrjTitle, "BGCOLOR", GLOBAL.editColor.prjTitle.toCString );
		version(Windows) IupSetAttribute( btnPrjTitle, "SIZE", "16x8" ); else IupSetAttribute( btnPrjTitle, "SIZE", "16x10" );
		IupSetHandle( "btnPrjTitle", btnPrjTitle );
		IupSetCallback( btnPrjTitle, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );		

		Ihandle* labelSourceTypeFolder = IupLabel( toStringz( GLOBAL.languageItems["sourcefolder"].toDString ~ ":" ) );
		Ihandle* btnSourceTypeFolder = IupButton( null, null );
		IupSetAttribute( btnSourceTypeFolder, "BGCOLOR", GLOBAL.editColor.prjSourceType.toCString );
		version(Windows) IupSetAttribute( btnSourceTypeFolder, "SIZE", "16x8" ); else IupSetAttribute( btnSourceTypeFolder, "SIZE", "16x10" );
		IupSetHandle( "btnSourceTypeFolder", btnSourceTypeFolder );
		IupSetCallback( btnSourceTypeFolder, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );		


		// 2017.7.9
		Ihandle* labelIndicator = IupLabel( toStringz( GLOBAL.languageItems["hlcurrentword"].toDString ~ ":" ) );
		Ihandle* btnIndicator = IupButton( null, null );
		IupSetAttribute( btnIndicator, "BGCOLOR", GLOBAL.editColor.currentWord.toCString );
		version(Windows) IupSetAttribute( btnIndicator, "SIZE", "16x8" ); else IupSetAttribute( btnIndicator, "SIZE", "16x10" );
		IupSetHandle( "btnIndicator", btnIndicator );
		IupSetCallback( btnIndicator, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelIndicatorAlpha = IupLabel( toStringz( GLOBAL.languageItems["hlcurrentwordalpha"].toDString ~ ":" ) );
		Ihandle* textIndicatorAlpha = IupText( null );
		version(Windows)
		{
			IupSetAttributes( textIndicatorAlpha, "SIZE=24x10,MARGIN=0x0,SPIN=YES,SPINMAX=255,SPINMIN=0" );
			IupSetAttribute( textIndicatorAlpha, "SPINVALUE", GLOBAL.editColor.currentWordAlpha.toCString );
		}
		else
		{
			IupSetAttributes( textIndicatorAlpha, "SIZE=24x10,MARGIN=0x0" );
			IupSetAttribute( textIndicatorAlpha, "VALUE", GLOBAL.editColor.currentWordAlpha.toCString );
		}
		//IupSetAttribute( textIndicatorAlpha, "TIP", GLOBAL.languageItems["alphatip"].toCString() );
		IupSetHandle( "textIndicatorAlpha", textIndicatorAlpha );




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
			
			IupSetAttributes( labelIndicator, "" ),
			IupSetAttributes( btnIndicator, "" ),
			IupSetAttributes( labelIndicatorAlpha, "" ),
			IupSetAttributes( textIndicatorAlpha, "" ),

			null
		);
		version(Windows) IupSetAttributes( gboxColor, "EXPAND=YES,NUMDIV=4,ALIGNMENTLIN=ACENTER,ALIGNMENTCOL=ALEFT,GAPLIN=6,GAPCOL=30,MARGIN=2x8,SIZELIN=-1" ); else IupSetAttributes( gboxColor, "EXPAND=YES,NUMDIV=4,ALIGNMENTLIN=ACENTER,ALIGNMENTCOL=ALEFT,GAPLIN=6,GAPCOL=30,MARGIN=2x10,SIZELIN=1" );

		Ihandle* frameColor = IupFrame( gboxColor );
		IupSetAttributes( frameColor, "MARGIN=0x0,EXPAND=YES,EXPAND=HORIZONTAL" );
		IupSetAttribute( frameColor, "SIZE", "346x" );//IupGetAttribute( frameFont, "SIZE" ) );
		IupSetAttribute( frameColor, "TITLE", GLOBAL.languageItems["color"].toCString );

		
		// Color -1
		Ihandle* label_Scintilla = IupLabel( toStringz( GLOBAL.languageItems["scintilla"].toDString ~ ":" ) );
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
			IupSetAttribute( btn_Scintilla_FG, "SIZE", "16x8" );
			IupSetAttribute( btn_Scintilla_BG, "SIZE", "16x8" );
		}
		else
		{
			IupSetAttribute( btn_Scintilla_FG, "SIZE", "16x10" );
			IupSetAttribute( btn_Scintilla_BG, "SIZE", "16x10" );
		}

		Ihandle* labelSCE_B_COMMENT = IupLabel( toStringz( GLOBAL.languageItems["SCE_B_COMMENT"].toDString ~ ":" ) );
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
			IupSetAttribute( btnSCE_B_COMMENT_FG, "SIZE", "16x8" );
			IupSetAttribute( btnSCE_B_COMMENT_BG, "SIZE", "16x8" );
		}
		else
		{
			IupSetAttribute( btnSCE_B_COMMENT_FG, "SIZE", "16x10" );
			IupSetAttribute( btnSCE_B_COMMENT_BG, "SIZE", "16x10" );
		}
		
		Ihandle* labelSCE_B_NUMBER = IupLabel( toStringz( GLOBAL.languageItems["SCE_B_NUMBER"].toDString ~ ":" ) );
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
			IupSetAttribute( btnSCE_B_NUMBER_FG, "SIZE", "16x8" );
			IupSetAttribute( btnSCE_B_NUMBER_BG, "SIZE", "16x8" );
		}
		else
		{
			IupSetAttribute( btnSCE_B_NUMBER_FG, "SIZE", "16x10" );
			IupSetAttribute( btnSCE_B_NUMBER_BG, "SIZE", "16x10" );
		}
		
		Ihandle* labelSCE_B_STRING = IupLabel( toStringz( GLOBAL.languageItems["SCE_B_STRING"].toDString ~ ":" ) );
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
			IupSetAttribute( btnSCE_B_STRING_FG, "SIZE", "16x8" );
			IupSetAttribute( btnSCE_B_STRING_BG, "SIZE", "16x8" );
		}
		else
		{
			IupSetAttribute( btnSCE_B_STRING_FG, "SIZE", "16x10" );
			IupSetAttribute( btnSCE_B_STRING_BG, "SIZE", "16x10" );
		}		
		
		Ihandle* labelSCE_B_PREPROCESSOR = IupLabel( toStringz( GLOBAL.languageItems["SCE_B_PREPROCESSOR"].toDString ~ ":" ) );
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
			IupSetAttribute( btnSCE_B_PREPROCESSOR_FG, "SIZE", "16x8" );
			IupSetAttribute( btnSCE_B_PREPROCESSOR_BG, "SIZE", "16x8" );
		}
		else
		{
			IupSetAttribute( btnSCE_B_PREPROCESSOR_FG, "SIZE", "16x10" );
			IupSetAttribute( btnSCE_B_PREPROCESSOR_BG, "SIZE", "16x10" );
		}
		
		Ihandle* labelSCE_B_OPERATOR = IupLabel( toStringz( GLOBAL.languageItems["SCE_B_OPERATOR"].toDString ~ ":" ) );
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
			IupSetAttribute( btnSCE_B_OPERATOR_FG, "SIZE", "16x8" );
			IupSetAttribute( btnSCE_B_OPERATOR_BG, "SIZE", "16x8" );
		}
		else
		{
			IupSetAttribute( btnSCE_B_OPERATOR_FG, "SIZE", "16x10" );
			IupSetAttribute( btnSCE_B_OPERATOR_BG, "SIZE", "16x10" );
		}
		
		Ihandle* labelSCE_B_IDENTIFIER = IupLabel( toStringz( GLOBAL.languageItems["SCE_B_IDENTIFIER"].toDString ~ ":" ) );
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
			IupSetAttribute( btnSCE_B_IDENTIFIER_FG, "SIZE", "16x8" );
			IupSetAttribute( btnSCE_B_IDENTIFIER_BG, "SIZE", "16x8" );
		}
		else
		{
			IupSetAttribute( btnSCE_B_IDENTIFIER_FG, "SIZE", "16x10" );
			IupSetAttribute( btnSCE_B_IDENTIFIER_BG, "SIZE", "16x10" );
		}
		
		Ihandle* labelSCE_B_COMMENTBLOCK = IupLabel( toStringz( GLOBAL.languageItems["SCE_B_COMMENTBLOCK"].toDString ~ ":" ) );
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
			IupSetAttribute( btnSCE_B_COMMENTBLOCK_FG, "SIZE", "16x8" );
			IupSetAttribute( btnSCE_B_COMMENTBLOCK_BG, "SIZE", "16x8" );
		}
		else
		{
			IupSetAttribute( btnSCE_B_COMMENTBLOCK_FG, "SIZE", "16x10" );
			IupSetAttribute( btnSCE_B_COMMENTBLOCK_BG, "SIZE", "16x10" );
		}
		
		
		Ihandle* labelPrj = IupLabel( toStringz( GLOBAL.languageItems["caption_prj"].toDString ~ ":" ) );
		//IupSetAttribute( labelPrj, "SIZE", toStringz("100x") );
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
			IupSetAttribute( btnPrj_FG, "SIZE", "16x8" );
			IupSetAttribute( btnPrj_BG, "SIZE", "16x8" );
		}
		else
		{
			IupSetAttribute( btnPrj_FG, "SIZE", "16x10" );
			IupSetAttribute( btnPrj_BG, "SIZE", "16x10" );
		}		
		
		Ihandle* labelOutline = IupLabel( toStringz( GLOBAL.languageItems["outline"].toDString ~ ":" ) );
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
			IupSetAttribute( btnOutline_FG, "SIZE", "16x8" );
			IupSetAttribute( btnOutline_BG, "SIZE", "16x8" );
		}
		else
		{
			IupSetAttribute( btnOutline_FG, "SIZE", "16x10" );
			IupSetAttribute( btnOutline_BG, "SIZE", "16x10" );
		}
		
		Ihandle* labelFilelist= IupLabel( toStringz( GLOBAL.languageItems["filelist"].toDString ~ ":" ) );
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
			IupSetAttribute( btnFilelist_FG, "SIZE", "16x8" );
			IupSetAttribute( btnFilelist_BG, "SIZE", "16x8" );
		}
		else
		{
			IupSetAttribute( btnFilelist_FG, "SIZE", "16x10" );
			IupSetAttribute( btnFilelist_BG, "SIZE", "16x10" );
		}
		
		Ihandle* labelOutput= IupLabel( toStringz( GLOBAL.languageItems["output"].toDString ~ ":" ) );
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
			IupSetAttribute( btnOutput_FG, "SIZE", "16x8" );
			IupSetAttribute( btnOutput_BG, "SIZE", "16x8" );
		}
		else
		{
			IupSetAttribute( btnOutput_FG, "SIZE", "16x10" );
			IupSetAttribute( btnOutput_BG, "SIZE", "16x10" );
		}
		
		Ihandle* labelSearch= IupLabel( toStringz( GLOBAL.languageItems["caption_search"].toDString ~ ":" ) );
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
			IupSetAttribute( btnSearch_FG, "SIZE", "16x8" );
			IupSetAttribute( btnSearch_BG, "SIZE", "16x8" );
		}
		else
		{
			IupSetAttribute( btnSearch_FG, "SIZE", "16x10" );
			IupSetAttribute( btnSearch_BG, "SIZE", "16x10" );
		}
		
		Ihandle* labelError= IupLabel( toStringz( GLOBAL.languageItems["manualerrorannotation"].toDString ~ ":" ) );
		Ihandle* btnError_FG = IupButton( null, null );
		Ihandle* btnError_BG = IupButton( null, null );
		IupSetAttribute( btnError_FG, "BGCOLOR", GLOBAL.editColor.errorFore.toCString );
		IupSetAttribute( btnError_BG, "BGCOLOR", GLOBAL.editColor.errorBack.toCString );	
		IupSetHandle( "btnError_FG", btnError_FG );
		IupSetHandle( "btnError_BG", btnError_BG );
		IupSetCallback( btnError_FG, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnError_BG, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		version(Windows)
		{
			IupSetAttribute( btnError_FG, "SIZE", "16x8" );
			IupSetAttribute( btnError_BG, "SIZE", "16x8" );
		}
		else
		{
			IupSetAttribute( btnError_FG, "SIZE", "16x10" );
			IupSetAttribute( btnError_BG, "SIZE", "16x10" );
		}
		
		Ihandle* labelWarning= IupLabel( toStringz( GLOBAL.languageItems["manualwarningannotation"].toDString ~ ":" ) );
		Ihandle* btnWarning_FG = IupButton( null, null );
		Ihandle* btnWarning_BG = IupButton( null, null );
		IupSetAttribute( btnWarning_FG, "BGCOLOR", GLOBAL.editColor.warningFore.toCString );
		IupSetAttribute( btnWarning_BG, "BGCOLOR", GLOBAL.editColor.warringBack.toCString );	
		IupSetHandle( "btnWarning_FG", btnWarning_FG );
		IupSetHandle( "btnWarning_BG", btnWarning_BG );
		IupSetCallback( btnWarning_FG, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnWarning_BG, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		version(Windows)
		{
			IupSetAttribute( btnWarning_FG, "SIZE", "16x8" );
			IupSetAttribute( btnWarning_BG, "SIZE", "16x8" );
		}
		else
		{
			IupSetAttribute( btnWarning_FG, "SIZE", "16x10" );
			IupSetAttribute( btnWarning_BG, "SIZE", "16x10" );
		}		
		
		Ihandle* labelBrace= IupLabel( toStringz( GLOBAL.languageItems["bracehighlight"].toDString ~ ":" ) );
		Ihandle* btnBrace_FG = IupButton( null, null );
		Ihandle* btnBrace_BG = IupButton( null, null );
		IupSetAttribute( btnBrace_FG, "BGCOLOR", GLOBAL.editColor.braceFore.toCString );
		IupSetAttribute( btnBrace_BG, "BGCOLOR", GLOBAL.editColor.braceBack.toCString );	
		IupSetHandle( "btnBrace_FG", btnBrace_FG );
		IupSetHandle( "btnBrace_BG", btnBrace_BG );
		IupSetCallback( btnBrace_FG, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnBrace_BG, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		version(Windows)
		{
			IupSetAttribute( btnBrace_FG, "SIZE", "16x8" );
			IupSetAttribute( btnBrace_BG, "SIZE", "16x8" );
		}
		else
		{
			IupSetAttribute( btnBrace_FG, "SIZE", "16x10" );
			IupSetAttribute( btnBrace_BG, "SIZE", "16x10" );
		}			
		
		Ihandle* gboxColor_1 = IupGridBox
		(
			IupSetAttributes( labelPrj, "" ),
			IupSetAttributes( btnPrj_FG, "" ),
			IupSetAttributes( btnPrj_BG, "" ),
			IupFill(),
			IupSetAttributes( labelOutline, "" ),
			IupSetAttributes( btnOutline_FG, "" ),
			IupSetAttributes( btnOutline_BG, "" ),

			IupSetAttributes( labelFilelist, "" ),
			IupSetAttributes( btnFilelist_FG, "" ),
			IupSetAttributes( btnFilelist_BG, "" ),
			IupFill(),
			IupSetAttributes( labelOutput, "" ),
			IupSetAttributes( btnOutput_FG, "" ),
			IupSetAttributes( btnOutput_BG, "" ),

			IupSetAttributes( labelSearch, "" ),
			IupSetAttributes( btnSearch_FG, "" ),
			IupSetAttributes( btnSearch_BG, "" ),
			IupFill(),
			IupSetAttributes( labelSelectFore, "" ),
			IupSetAttributes( btnSelectFore, "" ),
			IupSetAttributes( btnSelectBack, "" ),

			IupSetAttributes( labelLinenumFore, "" ),
			IupSetAttributes( btnLinenumFore, "" ),
			IupSetAttributes( btnLinenumBack, "" ),
			IupFill(),
			IupSetAttributes( labelBrace, "" ),
			IupSetAttributes( btnBrace_FG, "" ),
			IupSetAttributes( btnBrace_BG, "" ),

			IupSetAttributes( labelError, "" ),
			IupSetAttributes( btnError_FG, "" ),
			IupSetAttributes( btnError_BG, "" ),			
			IupFill(),
			IupSetAttributes( labelWarning, "" ),
			IupSetAttributes( btnWarning_FG, "" ),
			IupSetAttributes( btnWarning_BG, "" ),			
			
			
			IupSetAttributes( label_Scintilla, "" ),
			//IupFill(),
			IupSetAttributes( btn_Scintilla_FG,"" ),
			IupSetAttributes( btn_Scintilla_BG, "" ),
			IupFill(),
			IupSetAttributes( labelSCE_B_COMMENT, "" ),
			//IupFill(),
			IupSetAttributes( btnSCE_B_COMMENT_FG,"" ),
			IupSetAttributes( btnSCE_B_COMMENT_BG, "" ),

			IupSetAttributes( labelSCE_B_NUMBER, "" ),
			//IupFill(),
			IupSetAttributes( btnSCE_B_NUMBER_FG, "" ),
			IupSetAttributes( btnSCE_B_NUMBER_BG, "" ),
			IupFill(),
			IupSetAttributes( labelSCE_B_STRING, "" ),
			//IupFill(),
			IupSetAttributes( btnSCE_B_STRING_FG, "" ),
			IupSetAttributes( btnSCE_B_STRING_BG, "" ),

			IupSetAttributes( labelSCE_B_PREPROCESSOR, "" ),
			//IupFill(),
			IupSetAttributes( btnSCE_B_PREPROCESSOR_FG, "" ),
			IupSetAttributes( btnSCE_B_PREPROCESSOR_BG, "" ),
			IupFill(),
			IupSetAttributes( labelSCE_B_OPERATOR, "" ),
			//IupFill(),
			IupSetAttributes( btnSCE_B_OPERATOR_FG, "" ),
			IupSetAttributes( btnSCE_B_OPERATOR_BG, "" ),

			IupSetAttributes( labelSCE_B_IDENTIFIER, "" ),
			//IupFill(),
			IupSetAttributes( btnSCE_B_IDENTIFIER_FG, "" ),
			IupSetAttributes( btnSCE_B_IDENTIFIER_BG, "" ),
			IupFill(),
			IupSetAttributes( labelSCE_B_COMMENTBLOCK, "" ),
			//IupFill(),
			IupSetAttributes( btnSCE_B_COMMENTBLOCK_FG, "" ),
			IupSetAttributes( btnSCE_B_COMMENTBLOCK_BG, "" ),

			null
		);
		IupSetAttributes( gboxColor_1, "SIZELIN =-1,NUMDIV=7,ALIGNMENTLIN=ACENTER,ALIGNMENTCOL=ALEFT,GAPLIN=6,GAPCOL=5,MARGIN=2x8" );

		Ihandle* frameColor_1 = IupFrame( gboxColor_1 );
		IupSetAttributes( frameColor_1, "MARGIN=0x0,EXPAND=YES,EXPAND=HORIZONTAL" );
		IupSetAttribute( frameColor_1, "SIZE", "288x" );//IupGetAttribute( frameFont, "SIZE" ) );
		IupSetAttribute( frameColor_1, "TITLE", GLOBAL.languageItems["colorfgbg"].toCString );
		
		Ihandle* labelKeyWord0 = IupLabel( GLOBAL.languageItems["keyword0"].toCString() );
		Ihandle* btnKeyWord0Color = IupButton( null, null );
		IupSetAttribute( btnKeyWord0Color, "BGCOLOR", GLOBAL.editColor.keyWord[0].toCString );
		version(Windows) IupSetAttribute( btnKeyWord0Color, "SIZE", "24x8" ); else IupSetAttribute( btnKeyWord0Color, "SIZE", "24x10" );
		IupSetHandle( "btnKeyWord0Color", btnKeyWord0Color );
		IupSetCallback( btnKeyWord0Color, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelKeyWord1 = IupLabel( GLOBAL.languageItems["keyword1"].toCString() );
		Ihandle* btnKeyWord1Color = IupButton( null, null );
		IupSetAttribute( btnKeyWord1Color, "BGCOLOR", GLOBAL.editColor.keyWord[1].toCString );
		version(Windows) IupSetAttribute( btnKeyWord1Color, "SIZE", "24x8" ); else IupSetAttribute( btnKeyWord1Color, "SIZE", "24x10" );
		IupSetHandle( "btnKeyWord1Color", btnKeyWord1Color );
		IupSetCallback( btnKeyWord1Color, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelKeyWord2 = IupLabel( GLOBAL.languageItems["keyword2"].toCString() );
		Ihandle* btnKeyWord2Color = IupButton( null, null );
		IupSetAttribute( btnKeyWord2Color, "BGCOLOR", GLOBAL.editColor.keyWord[2].toCString );
		version(Windows) IupSetAttribute( btnKeyWord2Color, "SIZE", "24x8" ); else IupSetAttribute( btnKeyWord2Color, "SIZE", "24x10" );
		IupSetHandle( "btnKeyWord2Color", btnKeyWord2Color );
		IupSetCallback( btnKeyWord2Color, "ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelKeyWord3 = IupLabel( GLOBAL.languageItems["keyword3"].toCString() );
		Ihandle* btnKeyWord3Color = IupButton( null, null );
		IupSetAttribute( btnKeyWord3Color, "BGCOLOR",GLOBAL.editColor.keyWord[3].toCString );
		version(Windows) IupSetAttribute( btnKeyWord3Color, "SIZE", "24x8" ); else IupSetAttribute( btnKeyWord3Color, "SIZE", "24x10" );
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
		IupSetAttributes( gboxKeyWordColor, "EXPAND=YES,NUMDIV=8,ALIGNMENTLIN=ACENTER,ALIGNMENTCOL=ACENTER,GAPLIN=5,GAPCOL=5,MARGIN=0x5,SIZELIN=0,EXPANDCHILDREN=YES" );
		Ihandle* frameKeywordColor = IupFrame( gboxKeyWordColor );
		IupSetAttributes( frameKeywordColor, "MARGIN=0x0,EXPAND=YES,EXPAND=HORIZONTAL" );
		IupSetAttribute( frameKeywordColor, "SIZE", "288x" );//IupGetAttribute( frameFont, "SIZE" ) );
		IupSetAttribute( frameKeywordColor, "TITLE", GLOBAL.languageItems["keywords"].toCString );		
		
		
		/*
		Ihandle* vBoxPage02 = IupVbox( gbox, frameKeywordCase, frameFont, frameColor, null );
		IupSetAttributes( vBoxPage02, "GAP=5,MARGIN=0x1,EXPANDCHILDREN=YES" );
		*/
		Ihandle* vColor = IupVbox( colorTemplateFrame, frameColor, frameColor_1, frameKeywordColor, null );
		IupSetAttributes( vColor, "ALIGNMENT=ACENTER,EXPANDCHILDREN=YES,HOMOGENEOUS=NO,GAP=0" );		


		// Short Cut
		Ihandle* shortCutList = IupList( null );
		IupSetAttributes( shortCutList, "SIZE=150x200,MULTIPLE=NO,MARGIN=2x10,VISIBLECOLUMNS=YES,EXPAND=YES,AUTOHIDE=YES,SHOWIMAGE=YES" );
		version( Windows )
		{
			IupSetAttribute( shortCutList, "FONT", "Courier New,9" );
		}
		else
		{
			IupSetAttribute( shortCutList, "FONT", "Ubuntu Mono, 10" );
		}
		IupSetHandle( "shortCutList", shortCutList );
		IupSetCallback( shortCutList, "DBLCLICK_CB", cast(Icallback) &CPreferenceDialog_shortCutList_DBLCLICK_CB );

		int ID = 0;
		for( int i = 0; i < GLOBAL.shortKeys.length; ++ i )
		{
			ID ++;
			switch( i )
			{
				case 0:
					IupSetAttributeId( shortCutList, "", ID, toStringz( "[" ~ GLOBAL.languageItems["file"].toDString ~ "]" ) ); 
					IupSetAttributeId( shortCutList, "IMAGE", ID, "icon_prj_open" ); 
					ID++;
					break;
				case 6:
					IupSetAttributeId( shortCutList, "", ID, toStringz( "[" ~ GLOBAL.languageItems["edit"].toDString ~ "]" ) );
					IupSetAttributeId( shortCutList, "IMAGE", ID, "icon_search" ); 
					ID++;
					break;
				case 19:
					IupSetAttributeId( shortCutList, "", ID, toStringz( "[" ~ GLOBAL.languageItems["parser"].toDString ~ "]" ) );
					IupSetAttributeId( shortCutList, "IMAGE", ID, "icon_refresh" ); 
					ID++;
					break;
				case 24:
					IupSetAttributeId( shortCutList, "", ID, toStringz( "[" ~ GLOBAL.languageItems["build"].toDString ~ "]" ) );
					IupSetAttributeId( shortCutList, "IMAGE", ID, "icon_compile" );
					ID++;
					break;
				case 28:
					IupSetAttributeId( shortCutList, "", ID, toStringz( "[" ~ GLOBAL.languageItems["windows"].toDString ~ "]" ) );
					IupSetAttributeId( shortCutList, "IMAGE", ID, "icon_gui" );
					ID++;
					break;
				case 30:
					IupSetAttributeId( shortCutList, "", ID, toStringz( "[" ~ GLOBAL.languageItems["setcustomtool"].toDString ~ "]" ) );
					IupSetAttributeId( shortCutList, "IMAGE", ID, "icon_toolitem" );
					ID++;
					break;
				default:
			}
			
			char[] keyValue = IDECONFIG.convertShortKeyValue2String( GLOBAL.shortKeys[i].keyValue );
			char[][] splitWord = Util.split( keyValue, "+" );

			if(  splitWord.length == 4 ) 
			{
				if( splitWord[0] == "C" )  splitWord[0] = "Ctrl";
				if( splitWord[1] == "S" )  splitWord[1] = "Shift";
				if( splitWord[2] == "A" )  splitWord[2] = "Alt";
			}
			
			char[] string = Stdout.layout.convert( " {,-5} + {,-5} + {,-5} + {,-5} {,-40}", splitWord[0], splitWord[1], splitWord[2], splitWord[3], GLOBAL.shortKeys[i].title );

			IupSetAttributeId( shortCutList, "",  ID, toStringz( string ) );
		}






		Ihandle* keyWordText0 = IupText( null );
		IupSetAttributes( keyWordText0, "MULTILINE=YES,EXPAND=YES,WORDWRAP=YES,AUTOHIDE=YES,SCROLLBAR=YES,PADDING=2x2" );
		IupSetAttribute( keyWordText0, "VALUE", GLOBAL.KEYWORDS[0].toCString );
		IupSetHandle( "keyWordText0", keyWordText0 );
		Ihandle* keyWordText1 = IupText( null );
		IupSetAttributes( keyWordText1, "MULTILINE=YES,EXPAND=YES,WORDWRAP=YES,AUTOHIDE=YES,SCROLLBAR=YES,PADDING=2x2" );
		IupSetAttribute( keyWordText1, "VALUE", GLOBAL.KEYWORDS[1].toCString );
		IupSetHandle( "keyWordText1", keyWordText1 );
		Ihandle* keyWordText2 = IupText( null );
		IupSetAttributes( keyWordText2, "MULTILINE=YES,EXPAND=YES,WORDWRAP=YES,AUTOHIDE=YES,SCROLLBAR=YES,PADDING=2x2" );
		IupSetAttribute( keyWordText2, "VALUE", GLOBAL.KEYWORDS[2].toCString );
		IupSetHandle( "keyWordText2", keyWordText2 );
		Ihandle* keyWordText3 = IupText( null );
		IupSetAttributes( keyWordText3, "MULTILINE=YES,EXPAND=YES,WORDWRAP=YES,AUTOHIDE=YES,SCROLLBAR=YES,PADDING=2x2" );
		IupSetAttribute( keyWordText3, "VALUE", GLOBAL.KEYWORDS[3].toCString );
		IupSetHandle( "keyWordText3", keyWordText3 );
		
		IupSetAttribute( keyWordText0, "TABTITLE", GLOBAL.languageItems["keyword0"].toCString() );
		IupSetAttribute( keyWordText1, "TABTITLE", GLOBAL.languageItems["keyword1"].toCString() );
		IupSetAttribute( keyWordText2, "TABTITLE", GLOBAL.languageItems["keyword2"].toCString() );
		IupSetAttribute( keyWordText3, "TABTITLE", GLOBAL.languageItems["keyword3"].toCString() );
		Ihandle* keywordTabs = IupTabs( keyWordText0, keyWordText1, keyWordText2, keyWordText3, null );
		IupSetAttribute( keywordTabs, "TABTYPE", "TOP" );
		IupSetAttribute( keywordTabs, "EXPAND", "YES" );
		IupSetAttribute( keywordTabs, "CHILDOFFSET", "2x5" );
		
		
		
		




/*
		Ihandle* keyWordVbox = IupVbox( keyWordText0, keyWordText1, keyWordText2, keyWordText3, gboxKeyWordColor, null );
		IupSetAttribute( keyWordVbox, "ALIGNMENT", toStringz( "ACENTER" ) );
	*/	
		/*
		IupSetAttribute( vBoxPage01, "TABTITLE", GLOBAL.languageItems["compiler"].toCString() );
		*/
		IupSetAttribute( vBoxCompilerSettings, "TABTITLE", GLOBAL.languageItems["compiler"].toCString() );
		IupSetAttribute( vBoxParserSettings, "TABTITLE", GLOBAL.languageItems["parser"].toCString() );
		
		IupSetAttribute( vBoxPage02, "TABTITLE", GLOBAL.languageItems["editor"].toCString() );
		IupSetAttribute( sb, "TABTITLE", GLOBAL.languageItems["font"].toCString() );
		IupSetAttribute( vColor, "TABTITLE", GLOBAL.languageItems["color"].toCString() );
		IupSetAttribute( shortCutList, "TABTITLE", GLOBAL.languageItems["shortcut"].toCString() );
		IupSetAttribute( keywordTabs, "TABTITLE", GLOBAL.languageItems["keywords"].toCString() );
		//IupSetAttribute( manuFrame, "TABTITLE", GLOBAL.languageItems["manual"].toCString() );
		//IupSetAttribute( vBoxPage01, "EXPAND", "YES" );
	
		
		
		Ihandle* preferenceTabs = IupTabs( /*vBoxPage01,*/vBoxCompilerSettings, vBoxParserSettings, vBoxPage02, sb, vColor, shortCutList, keywordTabs, /*manuFrame,*/ null );
		IupSetAttribute( preferenceTabs, "TABTYPE", "TOP" );
		IupSetAttribute( preferenceTabs, "EXPAND", "YES" );
		IupSetAttribute( preferenceTabs, "CHILDOFFSET", "0x0" );
		

		
		Ihandle* vBox = IupVbox( preferenceTabs, bottom, null );
		IupSetAttributes( vBox, "ALIGNMENT=ACENTER,MARGIN=10x10,GAP=5" );

		IupAppend( _dlg, vBox );
	}

	public:
	this( int w, int h, char[] title, bool bResize = true, char[] parent = "MAIN_DIALOG" )
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
			IupSetAttribute( _dlg, "FONT", GLOBAL.cString.convert( "Ubuntu Mono, 10" ) );
		}
		
		IupSetHandle( "PreferenceHandle", getIhandle );
		
		createLayout();
		
		//scope size = new IupString( Integer.toString( w ) ~ "x" ~ Integer.toString( h ) );
		version(Windows) IupSetAttribute( _dlg, "SIZE", "-1x295" ); else IupSetAttribute( _dlg, "SIZE", "-1x360" );
		
		IupSetAttribute( _dlg, "OPACITY", toStringz( GLOBAL.editorSetting02.preferenceDlg ) );
		
		// Bottom Button
		IupSetAttribute( _dlg, "DEFAULTENTER", null );
		IupSetAttribute( btnCANCEL, "TITLE", GLOBAL.languageItems["close"].toCString );
		IupSetCallback( btnAPPLY, "ACTION", cast(Icallback) &CPreferenceDialog_btnApply_cb );
		IupSetCallback( btnOK, "ACTION", cast(Icallback) &CPreferenceDialog_btnOK_cb );
		IupSetCallback( btnCANCEL, "ACTION", cast(Icallback) &CPreferenceDialog_btnCancel_cb );
		IupSetCallback( _dlg, "CLOSE_CB", cast(Icallback) &CPreferenceDialog_btnCancel_cb );		
		
		IupMap( _dlg );
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
		IupSetHandle( "toggleIncludeComplete", null );
		IupSetHandle( "toggleUseParser", null );
		IupSetHandle( "toggleWithParams", null );
		IupSetHandle( "toggleIGNORECASE", null );
		IupSetHandle( "toggleCASEINSENSITIVE", null );
		IupSetHandle( "toggleSHOWLISTTYPE", null );
		IupSetHandle( "toggleSHOWALLMEMBER", null );
		IupSetHandle( "toggleDWELL", null );
		IupSetHandle( "toggleLiveNone", null );
		IupSetHandle( "toggleLiveLight", null );
		IupSetHandle( "toggleLiveFull", null );		
		IupSetHandle( "toggleUpdateOutline", null );
	
		IupSetHandle( "toggleAnnotation", null );
		IupSetHandle( "toggleShowResultWindow", null );
		IupSetHandle( "toggleSFX", null );
		IupSetHandle( "toggleDelPrevEXE", null );
		IupSetHandle( "toggleConsoleExe", null );

		IupSetHandle( "toggleLineMargin", null );
		IupSetHandle( "toggleFixedLineMargin", null );
		IupSetHandle( "toggleBookmarkMargin", null );
		IupSetHandle( "toggleFoldMargin", null );
		IupSetHandle( "toggleIndentGuide", null );
		IupSetHandle( "toggleCaretLine", null );
		IupSetHandle( "toggleWordWarp", null );
		IupSetHandle( "toggleTabUseingSpace", null );
		IupSetHandle( "toggleAutoIndent", null );
		IupSetHandle( "toggleShowEOL", null );
		IupSetHandle( "toggleShowSpace", null );
		version(FBIDE)	IupSetHandle( "toggleAutoEnd", null );
		IupSetHandle( "toggleAutoClose", null );
		IupSetHandle( "toggleColorOutline", null );
		IupSetHandle( "toggleMessage", null );
		IupSetHandle( "toggleBoldKeyword", null );
		IupSetHandle( "toggleBraceMatch", null );
		IupSetHandle( "toggleMultiSelection", null );
		IupSetHandle( "toggleLoadprev", null );
		IupSetHandle( "toggleCurrentWord", null );
		IupSetHandle( "toggleMiddleScroll", null );
		IupSetHandle( "textSetControlCharSymbol", null );
		
		
		IupSetHandle( "textTabWidth", null );
		IupSetHandle( "textColumnEdge", null );
		IupSetHandle( "textBarSize", null );

		IupSetHandle( "radioKeywordCase0", null );
		IupSetHandle( "radioKeywordCase1", null );
		IupSetHandle( "radioKeywordCase2", null );
		IupSetHandle( "radioKeywordCase3", null );

		IupSetHandle( "customFont_0", null );
		IupSetHandle( "customFont_1", null );
		IupSetHandle( "customFont_2", null );
		IupSetHandle( "customFont_3", null );
		IupSetHandle( "customFont_4", null );
		IupSetHandle( "customFont_5", null );
		IupSetHandle( "customFont_6", null );
		IupSetHandle( "customFont_7", null );
		IupSetHandle( "customFont_8", null );
		IupSetHandle( "customFont_9", null );
		IupSetHandle( "customFont_10", null );
		IupSetHandle( "customFont_11", null );
		IupSetHandle( "customFont_12", null );

		IupSetHandle( "btnCaretLine", null );
		IupSetHandle( "btnCursor", null );
		IupSetHandle( "btnSelectFore", null );
		IupSetHandle( "btnSelectBack", null );
		IupSetHandle( "btnLinenumFore", null );
		IupSetHandle( "btnLinenumBack", null );
		IupSetHandle( "btnFoldingColor", null );
		IupSetHandle( "btnBookmarkColor", null );
		IupSetHandle( "textAlpha", null );
		IupSetHandle( "btnIndicator", null );
		IupSetHandle( "textIndicatorAlpha", null );		
		
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

		//IupSetHandle( "btnKeyWord0Color", null );
		//IupSetHandle( "btnKeyWord1Color", null );
		//IupSetHandle( "btnKeyWord2Color", null );
		//IupSetHandle( "btnKeyWord3Color", null );

		IupSetHandle( "keyWordText0", null );
		IupSetHandle( "keyWordText1", null );
		IupSetHandle( "keyWordText2", null );
		IupSetHandle( "keyWordText3", null );
		
		IupSetHandle( "shortCutList", null );
		
		for( int i = 0; i < 15; ++ i )
			if( _stringOfLabel[i] !is null ) delete _stringOfLabel[i];
			
		IupDestroy( _dlg );
	}
	
	char[] show( int x, int y )
	{
		IupShowXY( _dlg, x, y );
		return null;
	}	
}

extern(C) // Callback for CPreferenceDialog
{
	private int CPreferenceDialog_OpenCompileBinFile_cb( Ihandle* ih )
	{
		scope fileSecectDlg = new CFileDlg( GLOBAL.languageItems["caption_open"].toDString ~ "..." );
		char[] fileName = fileSecectDlg.getFileName();

		if( fileName.length )
		{
			GLOBAL.compilerFullPath = fileName;
			Ihandle* _compilePath_Handle = IupGetHandle( "compilerPath_Handle" );
			if( _compilePath_Handle != null ) IupSetAttribute( _compilePath_Handle, "VALUE", GLOBAL.compilerFullPath.toCString );
		}
		else
		{
			//Stdout( "NoThing!!!" ).newline;
		}

		return IUP_DEFAULT;
	}
	
	private int CPreferenceDialog_Openx64CompileBinFile_cb( Ihandle* ih )
	{
		scope fileSecectDlg = new CFileDlg( GLOBAL.languageItems["caption_open"].toDString ~ "..." );
		char[] fileName = fileSecectDlg.getFileName();

		if( fileName.length )
		{
			GLOBAL.x64compilerFullPath = fileName;
			Ihandle* _compilePath_Handle = IupGetHandle( "x64compilerPath_Handle" );
			if( _compilePath_Handle != null ) IupSetAttribute( _compilePath_Handle, "VALUE", GLOBAL.x64compilerFullPath.toCString );
		}
		else
		{
			//Stdout( "NoThing!!!" ).newline;
		}

		return IUP_DEFAULT;
	}	

	private int CPreferenceDialog_OpenDebuggerBinFile_cb( Ihandle* ih )
	{
		scope fileSecectDlg = new CFileDlg( GLOBAL.languageItems["caption_open"].toDString ~ "..." );
		char[] fileName = fileSecectDlg.getFileName();

		if( fileName.length )
		{
			GLOBAL.debuggerFullPath = fileName;
			Ihandle* _debuggerPath_Handle = IupGetHandle( "debuggerPath_Handle" );
			if( _debuggerPath_Handle != null ) IupSetAttribute( _debuggerPath_Handle, "VALUE", GLOBAL.debuggerFullPath.toCString );
		}
		else
		{
			//Stdout( "NoThing!!!" ).newline;
		}

		return IUP_DEFAULT;
	}
	
	private int CPreferenceDialog_OpenCHM_cb( Ihandle* ih )
	{
		scope fileSecectDlg = new CFileDlg( GLOBAL.languageItems["caption_open"].toDString() ~ "...", GLOBAL.languageItems["chmfile"].toDString() ~ "|*.chm|" ~ GLOBAL.languageItems["allfile"].toDString() ~ "|*.*", "OPEN", "YES" );
		//scope fileSecectDlg = new CFileDlg( GLOBAL.languageItems["caption_open"].toDString ~ "..." );
		char[] fileName = fileSecectDlg.getFileName();

		if( fileName.length )
		{
			GLOBAL.manualPath = fileName;
			Ihandle* _chm_Handle = IupGetHandle( "textchm" );
			if( _chm_Handle != null ) IupSetAttribute( _chm_Handle, "VALUE", GLOBAL.manualPath.toCString );
		}
		else
		{
			//Stdout( "NoThing!!!" ).newline;
		}

		return IUP_DEFAULT;
	}	

	private int CPreferenceDialog_shortCutList_DBLCLICK_CB( Ihandle *ih, int item, char *text )
	{
		char[] itemText = fromStringz( text ).dup;
		if( itemText.length )
		{
			if( itemText[0] == '[' ) return IUP_DEFAULT;
		}

		scope skDialog = new CShortCutDialog( -1, -1, item, fromStringz( text ).dup );
		skDialog.show( IUP_CENTERPARENT, IUP_CENTERPARENT );

		return IUP_DEFAULT;
	}
	
	
	private int CPreferenceDialog_font_BUTTON_CB( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		try
		{
			if( button == IUP_BUTTON1 ) // Left Click
			{
				char[] _s = fromStringz( status ).dup;
				
				if( _s.length > 5 )
				{
					if( _s[5] == 'D' ) // Double Click
					{
						char[] listString = fromStringz( IupGetAttribute( ih, "TITLE" ) ).dup;
						char[] _ls;
						
						if( listString.length <= 32 ) return IUP_DEFAULT;
						
						foreach( char c; listString )
						{
							if( c == ' ' )
							{
								if( _ls.length )
								{
									if( _ls[length-1] != ' ' ) _ls ~= ' ';
								}
							}
							else
							{
								_ls ~= c;
							}							
						}

						// Open IupFontDlg
						Ihandle* dlg = IupFontDlg();
						if( dlg == null )
						{
							IupMessage( "Error", toStringz( "IupFontDlg created fail!" ) );
							return IUP_IGNORE;
						}

						IupSetAttribute( dlg, "VALUE", toStringz( Util.substitute( _ls.dup, "\t", ",") ) );
						IupPopup( dlg, IUP_CURRENT, IUP_CURRENT );						
						
						if( IupGetInt( dlg, "STATUS" ) )
						{
							int id;
							if( ih == IupGetHandle( "customFont_0" ) )
								id = 0;
							else if( ih == IupGetHandle( "customFont_1" ) )
								id = 1;
							else if( ih == IupGetHandle( "customFont_2" ) )
								id = 2;
							else if( ih == IupGetHandle( "customFont_3" ) )
								id = 3;
							else if( ih == IupGetHandle( "customFont_4" ) )
								id = 4;
							else if( ih == IupGetHandle( "customFont_5" ) )
								id = 5;
							else if( ih == IupGetHandle( "customFont_6" ) )
								id = 6;
							else if( ih == IupGetHandle( "customFont_7" ) )
								id = 7;
							else if( ih == IupGetHandle( "customFont_8" ) )
								id = 8;
							else if( ih == IupGetHandle( "customFont_9" ) )
								id = 9;
							else if( ih == IupGetHandle( "customFont_10" ) )
								id = 10;
							else if( ih == IupGetHandle( "customFont_11" ) )
								id = 11;
							else if( ih == IupGetHandle( "customFont_12" ) )
								id = 12;
							else
								return IUP_DEFAULT;

							auto fontInformation = new IupString( IupGetAttribute( dlg, "VALUE" ) );
							char[] Bold, Italic, Underline, Strikeout, size, fontName;
							char[][] strings = Util.split( fontInformation.toDString, "," );
							
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
										strings[0] = "Ubuntu Mono";
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
								version(Window)
									fontInformation = Stdout.layout.convert( "{,-48}\t{,-4} {,-6} {,-9} {,-9} {,-3}", strings[0], Bold, Italic, Underline, Strikeout, size );
								else
									fontInformation = Stdout.layout.convert( "{,-46}\t{,-4} {,-6} {,-9} {,-9} {,-3}", strings[0], Bold, Italic, Underline, Strikeout, size );
									
								IupSetAttribute( ih, "TITLE", fontInformation.toCString );

								scope _IupFlatFrameString = new IupString( "customFlatFrame_" ~ Integer.toString( id ) );
								Ihandle* _flatFrameHandle = IupGetHandle( _IupFlatFrameString.toCString );
								if( _flatFrameHandle != null )
								{
									scope _fontSyle = new IupString( strings[0] );
									IupSetAttribute( _flatFrameHandle, "FONTFACE", _fontSyle.toCString );
									version( Windows ) IupSetAttribute( ih, "FONTFACE", "Courier New" ); else IupSetAttribute( ih, "FONTFACE", "Ubuntu Mono" );
									IupRefresh( _flatFrameHandle );
								}
							}
							else
							{
								version(linux)
								{
									foreach( char[] s; Util.split( fontInformation.toDString, " " ) )
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
									version(Windows)
										fontInformation = Stdout.layout.convert( "{,-48}\t{,-4} {,-6} {,-9} {,-9} {,-3}", fontName, Bold, Italic, Underline, Strikeout, size );
									else
										fontInformation = Stdout.layout.convert( "{,-46}\t{,-4} {,-6} {,-9} {,-9} {,-3}", fontName, Bold, Italic, Underline, Strikeout, size );
									IupSetAttribute( ih, "TITLE", fontInformation.toCString );
									
									scope _IupFlatFrameString = new IupString( "customFlatFrame_" ~ Integer.toString( id ) );
									Ihandle* _flatFrameHandle = IupGetHandle( _IupFlatFrameString.toCString );
									if( _flatFrameHandle != null )
									{
										scope _fontSyle = new IupString( fontName );
										IupSetAttribute( _flatFrameHandle, "FONTFACE", _fontSyle.toCString );
										version( Windows ) IupSetAttribute( ih, "FONTFACE", "Courier New" ); else IupSetAttribute( ih, "FONTFACE", "Ubuntu Mono" );
										IupRefresh( _flatFrameHandle );
									}									
								}
							}			
						}
						
						IupDestroy( dlg );
					}
				}
			}
		}
		catch( Exception e )
		{
			debug IupMessage( "CPreferenceDialog_font_BUTTON_CB", toStringz( e.toString() ) );
		}
		
		return IUP_DEFAULT;
	}
	
	private int CPreferenceDialog_btnCancel_cb( Ihandle* ih )
	{
		IupHide( GLOBAL.preferenceDlg.getIhandle );
		return IUP_DEFAULT;
	}

	private int CPreferenceDialog_btnOK_cb( Ihandle* ih )
	{
		CPreferenceDialog_btnApply_cb( ih );
		IupHide( GLOBAL.preferenceDlg.getIhandle );
		return IUP_DEFAULT;
	}

	private int CPreferenceDialog_btnApply_cb( Ihandle* ih )
	{
		try
		{
			GLOBAL.KEYWORDS[0] = Util.trim( fromStringz(IupGetAttribute( IupGetHandle( "keyWordText0" ), "VALUE" ))).dup;
			GLOBAL.KEYWORDS[1] = Util.trim( fromStringz(IupGetAttribute( IupGetHandle( "keyWordText1" ), "VALUE" ))).dup;
			GLOBAL.KEYWORDS[2] = Util.trim( fromStringz(IupGetAttribute( IupGetHandle( "keyWordText2" ), "VALUE" ))).dup;
			GLOBAL.KEYWORDS[3] = Util.trim( fromStringz(IupGetAttribute( IupGetHandle( "keyWordText3" ), "VALUE" ))).dup;
			
			GLOBAL.editorSetting00.LineMargin				= fromStringz(IupGetAttribute( IupGetHandle( "toggleLineMargin" ), "VALUE" )).dup;
				if( IupGetHandle( "menuLineMargin" ) != null ) IupSetAttribute( IupGetHandle( "menuLineMargin" ), "VALUE", IupGetAttribute( IupGetHandle( "toggleLineMargin" ), "VALUE" ) );
			GLOBAL.editorSetting00.FixedLineMargin			= fromStringz(IupGetAttribute( IupGetHandle( "toggleFixedLineMargin" ), "VALUE" )).dup;
			GLOBAL.editorSetting00.BookmarkMargin			= fromStringz(IupGetAttribute( IupGetHandle( "toggleBookmarkMargin" ), "VALUE" )).dup;
				if( IupGetHandle( "menuBookmarkMargin" ) != null ) IupSetAttribute( IupGetHandle( "menuBookmarkMargin" ), "VALUE", IupGetAttribute( IupGetHandle( "toggleBookmarkMargin" ), "VALUE" ) );
			GLOBAL.editorSetting00.FoldMargin				= fromStringz(IupGetAttribute( IupGetHandle( "toggleFoldMargin" ), "VALUE" )).dup;
				if( IupGetHandle( "menuFoldMargin" ) != null ) IupSetAttribute( IupGetHandle( "menuFoldMargin" ), "VALUE", IupGetAttribute( IupGetHandle( "toggleFoldMargin" ), "VALUE" ) );
			GLOBAL.editorSetting00.IndentGuide				= fromStringz(IupGetAttribute( IupGetHandle( "toggleIndentGuide" ), "VALUE" )).dup;
				if( IupGetHandle( "menuIndentGuide" ) != null ) IupSetAttribute( IupGetHandle( "menuIndentGuide" ), "VALUE", IupGetAttribute( IupGetHandle( "toggleIndentGuide" ), "VALUE" ) );
			GLOBAL.editorSetting00.CaretLine				= fromStringz(IupGetAttribute( IupGetHandle( "toggleCaretLine" ), "VALUE" )).dup;
				if( IupGetHandle( "menuCaretLine" ) != null ) IupSetAttribute( IupGetHandle( "menuCaretLine" ), "VALUE", IupGetAttribute( IupGetHandle( "toggleCaretLine" ), "VALUE" ) );
			GLOBAL.editorSetting00.WordWrap					= fromStringz(IupGetAttribute( IupGetHandle( "toggleWordWrap" ), "VALUE" )).dup;
			GLOBAL.editorSetting00.TabUseingSpace			= fromStringz(IupGetAttribute( IupGetHandle( "toggleTabUseingSpace" ), "VALUE" )).dup;
			GLOBAL.editorSetting00.AutoIndent				= fromStringz(IupGetAttribute( IupGetHandle( "toggleAutoIndent" ), "VALUE" )).dup;
			GLOBAL.editorSetting00.ShowEOL					= fromStringz(IupGetAttribute( IupGetHandle( "toggleShowEOL" ), "VALUE" )).dup;
				if( IupGetHandle( "menuShowEOL" ) != null ) IupSetAttribute( IupGetHandle( "menuShowEOL" ), "VALUE", IupGetAttribute( IupGetHandle( "toggleShowEOL" ), "VALUE" ) );
			GLOBAL.editorSetting00.ShowSpace				= fromStringz(IupGetAttribute( IupGetHandle( "toggleShowSpace" ), "VALUE" )).dup;
				if( IupGetHandle( "menuShowSpace" ) != null ) IupSetAttribute( IupGetHandle( "menuShowSpace" ), "VALUE", IupGetAttribute( IupGetHandle( "toggleShowSpace" ), "VALUE" ) );
			version(FBIDE)	GLOBAL.editorSetting00.AutoEnd					= fromStringz(IupGetAttribute( IupGetHandle( "toggleAutoEnd" ), "VALUE" )).dup;
			GLOBAL.editorSetting00.AutoClose				= fromStringz(IupGetAttribute( IupGetHandle( "toggleAutoClose" ), "VALUE" )).dup;
			GLOBAL.editorSetting00.ColorOutline				= fromStringz(IupGetAttribute( IupGetHandle( "toggleColorOutline" ), "VALUE" )).dup;
			GLOBAL.editorSetting00.Message					= fromStringz(IupGetAttribute( IupGetHandle( "toggleMessage" ), "VALUE" )).dup;
			GLOBAL.editorSetting00.BoldKeyword				= fromStringz(IupGetAttribute( IupGetHandle( "toggleBoldKeyword" ), "VALUE" )).dup;
				if( IupGetHandle( "menuBoldKeyword" ) != null ) IupSetAttribute( IupGetHandle( "menuBoldKeyword" ), "VALUE", IupGetAttribute( IupGetHandle( "toggleBoldKeyword" ), "VALUE" ) );
			GLOBAL.editorSetting00.BraceMatchHighlight		= fromStringz(IupGetAttribute( IupGetHandle( "toggleBraceMatch" ), "VALUE" )).dup;
				if( IupGetHandle( "menuBraceMatch" ) != null ) IupSetAttribute( IupGetHandle( "menuBraceMatch" ), "VALUE", IupGetAttribute( IupGetHandle( "toggleBraceMatch" ), "VALUE" ) );
			GLOBAL.editorSetting00.MultiSelection			= fromStringz(IupGetAttribute( IupGetHandle( "toggleMultiSelection" ), "VALUE" )).dup;
			GLOBAL.editorSetting00.LoadPrevDoc				= fromStringz(IupGetAttribute( IupGetHandle( "toggleLoadprev" ), "VALUE" )).dup;
			GLOBAL.editorSetting00.HighlightCurrentWord		= fromStringz(IupGetAttribute( IupGetHandle( "toggleCurrentWord" ), "VALUE" )).dup;
				if( IupGetHandle( "menuHighlightCurrentWord" ) != null ) IupSetAttribute( IupGetHandle( "menuHighlightCurrentWord" ), "VALUE", IupGetAttribute( IupGetHandle( "toggleCurrentWord" ), "VALUE" ) );
				
			GLOBAL.editorSetting00.MiddleScroll				= fromStringz(IupGetAttribute( IupGetHandle( "toggleMiddleScroll" ), "VALUE" )).dup;
			GLOBAL.editorSetting00.ControlCharSymbol		= fromStringz(IupGetAttribute( IupGetHandle( "textSetControlCharSymbol" ), "VALUE" )).dup;
			
			
			
			GLOBAL.editorSetting00.TabWidth				= fromStringz(IupGetAttribute( IupGetHandle( "textTabWidth" ), "VALUE" )).dup;
			GLOBAL.editorSetting00.ColumnEdge			= fromStringz(IupGetAttribute( IupGetHandle( "textColumnEdge" ), "VALUE" )).dup;
			GLOBAL.editorSetting01.BarSize				= fromStringz(IupGetAttribute( IupGetHandle( "textBarSize" ), "VALUE" )).dup;
			int _barSize = Integer.atoi( GLOBAL.editorSetting01.BarSize );
			if( _barSize < 2 )
			{
				GLOBAL.editorSetting01.BarSize = "2";
				IupSetAttribute( IupGetHandle( "textBarSize" ), "VALUE", "2" );
			}
			if( _barSize > 5 )
			{
				GLOBAL.editorSetting01.BarSize = "5";
				IupSetAttribute( IupGetHandle( "textBarSize" ), "VALUE", "5" );
			}
			
			// Save Font Style
			for( int i = 0; i < GLOBAL.fonts.length; ++ i )
			{
				scope _tempString = new IupString(  "customFont_" ~ Integer.toString( i ) );
				Ihandle* _ih = IupGetHandle( _tempString.toCString );
				if( ih != null )
				{
					char[]	fontInformation = fromStringz( IupGetAttribute( _ih, "TITLE" ) ).dup;
					char[]	result;
					
					if( fontInformation.length > 32 )
					{
						char[][] strings = Util.split( fontInformation, "\t" );
						
						if( strings.length == 2 )
						{
							result ~= ( Util.trim( strings[0] ) ~ "," );

							foreach( char[] s; Util.split( Util.trim( strings[1] ), " " ) )
							{
								s = Util.trim( s );
								if( s.length )	result ~= ( " " ~ s );
							}
							GLOBAL.fonts[i].fontString = result;
						}
					}					
				}
			}
			

			//GLOBAL.editColor.caretLine					= IupGetAttribute( IupGetHandle( "btnCaretLine" ), "BGCOLOR" );					IupSetAttribute( IupGetHandle( "btnCaretLine" ), "BGCOLOR", GLOBAL.editColor.caretLine.toCString );
			IupSetAttribute( IupGetHandle( "btnCaretLine" ), "BGCOLOR", GLOBAL.editColor.caretLine << IupGetAttribute( IupGetHandle( "btnCaretLine" ), "BGCOLOR" ) );
			
			//GLOBAL.editColor.cursor						= IupGetAttribute( IupGetHandle( "btnCursor" ), "BGCOLOR" );					IupSetAttribute( IupGetHandle( "btnCursor" ), "BGCOLOR", GLOBAL.editColor.cursor.toCString );
			IupSetAttribute( IupGetHandle( "btnCursor" ), "BGCOLOR", GLOBAL.editColor.cursor << IupGetAttribute( IupGetHandle( "btnCursor" ), "BGCOLOR" ) );

			/*
			GLOBAL.editColor.selectionFore				= IupGetAttribute( IupGetHandle( "btnSelectFore" ), "BGCOLOR" );				IupSetAttribute( IupGetHandle( "btnSelectFore" ), "BGCOLOR", GLOBAL.editColor.selectionFore.toCString );
			GLOBAL.editColor.selectionBack				= IupGetAttribute( IupGetHandle( "btnSelectBack" ), "BGCOLOR" );				IupSetAttribute( IupGetHandle( "btnSelectBack" ), "BGCOLOR", GLOBAL.editColor.selectionBack.toCString );
			GLOBAL.editColor.linenumFore				= IupGetAttribute( IupGetHandle( "btnLinenumFore" ), "BGCOLOR" );				IupSetAttribute( IupGetHandle( "btnLinenumFore" ), "BGCOLOR", GLOBAL.editColor.linenumFore.toCString );
			GLOBAL.editColor.linenumBack				= IupGetAttribute( IupGetHandle( "btnLinenumBack" ), "BGCOLOR" );				IupSetAttribute( IupGetHandle( "btnLinenumBack" ), "BGCOLOR", GLOBAL.editColor.linenumBack.toCString );
			GLOBAL.editColor.fold						= IupGetAttribute( IupGetHandle( "btnFoldingColor" ), "BGCOLOR" );				IupSetAttribute( IupGetHandle( "btnFoldingColor" ), "BGCOLOR", GLOBAL.editColor.fold.toCString );
			*/
			IupSetAttribute( IupGetHandle( "btnSelectFore" ), "BGCOLOR", GLOBAL.editColor.selectionFore << IupGetAttribute( IupGetHandle( "btnSelectFore" ), "BGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnSelectBack" ), "BGCOLOR", GLOBAL.editColor.selectionBack << IupGetAttribute( IupGetHandle( "btnSelectBack" ), "BGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnLinenumFore" ), "BGCOLOR", GLOBAL.editColor.linenumFore << IupGetAttribute( IupGetHandle( "btnLinenumFore" ), "BGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnLinenumBack" ), "BGCOLOR", GLOBAL.editColor.linenumBack << IupGetAttribute( IupGetHandle( "btnLinenumBack" ), "BGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnFoldingColor" ), "BGCOLOR", GLOBAL.editColor.fold << IupGetAttribute( IupGetHandle( "btnFoldingColor" ), "BGCOLOR" ) );
			
			
			version(Windows)
				GLOBAL.editColor.selAlpha				= IupGetAttribute( IupGetHandle( "textAlpha" ), "SPINVALUE" );
			else
				GLOBAL.editColor.selAlpha				= IupGetAttribute( IupGetHandle( "textAlpha" ), "VALUE" );
			
			//GLOBAL.editColor.currentWord				= IupGetAttribute( IupGetHandle( "btnIndicator" ), "BGCOLOR" );				IupSetAttribute( IupGetHandle( "btnIndicator" ), "BGCOLOR", GLOBAL.editColor.currentWord.toCString );
			IupSetAttribute( IupGetHandle( "btnIndicator" ), "BGCOLOR", GLOBAL.editColor.currentWord << IupGetAttribute( IupGetHandle( "btnIndicator" ), "BGCOLOR" ) );
			version(Windows)
				GLOBAL.editColor.currentWordAlpha		= IupGetAttribute( IupGetHandle( "textIndicatorAlpha" ), "SPINVALUE" );
			else
				GLOBAL.editColor.currentWordAlpha		= IupGetAttribute( IupGetHandle( "textIndicatorAlpha" ), "VALUE" );
				
			/+
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
			
			GLOBAL.editColor.errorFore					= IupGetAttribute( IupGetHandle( "btnError_FG" ), "BGCOLOR" );
			GLOBAL.editColor.errorBack					= IupGetAttribute( IupGetHandle( "btnError_BG" ), "BGCOLOR" );
			GLOBAL.editColor.warningFore				= IupGetAttribute( IupGetHandle( "btnWarning_FG" ), "BGCOLOR" );
			GLOBAL.editColor.warringBack				= IupGetAttribute( IupGetHandle( "btnWarning_BG" ), "BGCOLOR" );
			GLOBAL.editColor.braceFore					= IupGetAttribute( IupGetHandle( "btnBrace_FG" ), "BGCOLOR" );
			GLOBAL.editColor.braceBack					= IupGetAttribute( IupGetHandle( "btnBrace_BG" ), "BGCOLOR" );
			
			GLOBAL.editColor.maker[0]					= IupGetAttribute( IupGetHandle( "btnMarker0Color" ), "BGCOLOR" );
			GLOBAL.editColor.maker[1]					= IupGetAttribute( IupGetHandle( "btnMarker1Color" ), "BGCOLOR" );
			GLOBAL.editColor.maker[2]					= IupGetAttribute( IupGetHandle( "btnMarker2Color" ), "BGCOLOR" );
			GLOBAL.editColor.maker[3]					= IupGetAttribute( IupGetHandle( "btnMarker3Color" ), "BGCOLOR" );
			+/

			IupSetAttribute( IupGetHandle( "btn_Scintilla_FG" ), "BGCOLOR", GLOBAL.editColor.scintillaFore << IupGetAttribute( IupGetHandle( "btn_Scintilla_FG" ), "BGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btn_Scintilla_BG" ), "BGCOLOR", GLOBAL.editColor.scintillaBack << IupGetAttribute( IupGetHandle( "btn_Scintilla_BG" ), "BGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnSCE_B_COMMENT_FG" ), "BGCOLOR", GLOBAL.editColor.SCE_B_COMMENT_Fore << IupGetAttribute( IupGetHandle( "btnSCE_B_COMMENT_FG" ), "BGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnSCE_B_COMMENT_BG" ), "BGCOLOR", GLOBAL.editColor.SCE_B_COMMENT_Back << IupGetAttribute( IupGetHandle( "btnSCE_B_COMMENT_BG" ), "BGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnSCE_B_NUMBER_FG" ), "BGCOLOR", GLOBAL.editColor.SCE_B_NUMBER_Fore << IupGetAttribute( IupGetHandle( "btnSCE_B_NUMBER_FG" ), "BGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnSCE_B_NUMBER_BG" ), "BGCOLOR", GLOBAL.editColor.SCE_B_NUMBER_Back << IupGetAttribute( IupGetHandle( "btnSCE_B_NUMBER_BG" ), "BGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnSCE_B_STRING_FG" ), "BGCOLOR", GLOBAL.editColor.SCE_B_STRING_Fore << IupGetAttribute( IupGetHandle( "btnSCE_B_STRING_FG" ), "BGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnSCE_B_STRING_BG" ), "BGCOLOR", GLOBAL.editColor.SCE_B_STRING_Back << IupGetAttribute( IupGetHandle( "btnSCE_B_STRING_BG" ), "BGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnSCE_B_PREPROCESSOR_FG" ), "BGCOLOR", GLOBAL.editColor.SCE_B_PREPROCESSOR_Fore << IupGetAttribute( IupGetHandle( "btnSCE_B_PREPROCESSOR_FG" ), "BGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnSCE_B_PREPROCESSOR_BG" ), "BGCOLOR", GLOBAL.editColor.SCE_B_PREPROCESSOR_Back << IupGetAttribute( IupGetHandle( "btnSCE_B_PREPROCESSOR_BG" ), "BGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnSCE_B_OPERATOR_FG" ), "BGCOLOR", GLOBAL.editColor.SCE_B_OPERATOR_Fore << IupGetAttribute( IupGetHandle( "btnSCE_B_OPERATOR_FG" ), "BGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnSCE_B_OPERATOR_BG" ), "BGCOLOR", GLOBAL.editColor.SCE_B_OPERATOR_Back << IupGetAttribute( IupGetHandle( "btnSCE_B_OPERATOR_BG" ), "BGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnSCE_B_IDENTIFIER_FG" ), "BGCOLOR", GLOBAL.editColor.SCE_B_IDENTIFIER_Fore << IupGetAttribute( IupGetHandle( "btnSCE_B_IDENTIFIER_FG" ), "BGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnSCE_B_IDENTIFIER_BG" ), "BGCOLOR", GLOBAL.editColor.SCE_B_IDENTIFIER_Back << IupGetAttribute( IupGetHandle( "btnSCE_B_IDENTIFIER_BG" ), "BGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnSCE_B_COMMENTBLOCK_FG" ), "BGCOLOR", GLOBAL.editColor.SCE_B_COMMENTBLOCK_Fore << IupGetAttribute( IupGetHandle( "btnSCE_B_COMMENTBLOCK_FG" ), "BGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnSCE_B_COMMENTBLOCK_BG" ), "BGCOLOR", GLOBAL.editColor.SCE_B_COMMENTBLOCK_Back << IupGetAttribute( IupGetHandle( "btnSCE_B_COMMENTBLOCK_BG" ), "BGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnPrjTitle" ), "BGCOLOR", GLOBAL.editColor.prjTitle << IupGetAttribute( IupGetHandle( "btnPrjTitle" ), "BGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnSourceTypeFolder" ), "BGCOLOR", GLOBAL.editColor.prjSourceType << IupGetAttribute( IupGetHandle( "btnSourceTypeFolder" ), "BGCOLOR" ) );
			
			IupSetAttribute( IupGetHandle( "btnPrj_FG" ), "BGCOLOR", GLOBAL.editColor.projectFore << IupGetAttribute( IupGetHandle( "btnPrj_FG" ), "BGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnPrj_BG" ), "BGCOLOR", GLOBAL.editColor.projectBack << IupGetAttribute( IupGetHandle( "btnPrj_BG" ), "BGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnOutline_FG" ), "BGCOLOR", GLOBAL.editColor.outlineFore << IupGetAttribute( IupGetHandle( "btnOutline_FG" ), "BGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnOutline_BG" ), "BGCOLOR", GLOBAL.editColor.outlineBack << IupGetAttribute( IupGetHandle( "btnOutline_BG" ), "BGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnFilelist_FG" ), "BGCOLOR", GLOBAL.editColor.filelistFore << IupGetAttribute( IupGetHandle( "btnFilelist_FG" ), "BGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnFilelist_BG" ), "BGCOLOR", GLOBAL.editColor.filelistBack << IupGetAttribute( IupGetHandle( "btnFilelist_BG" ), "BGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnOutput_FG" ), "BGCOLOR", GLOBAL.editColor.outputFore << IupGetAttribute( IupGetHandle( "btnOutput_FG" ), "BGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnOutput_BG" ), "BGCOLOR", GLOBAL.editColor.outputBack << IupGetAttribute( IupGetHandle( "btnOutput_BG" ), "BGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnSearch_FG" ), "BGCOLOR", GLOBAL.editColor.searchFore << IupGetAttribute( IupGetHandle( "btnSearch_FG" ), "BGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnSearch_BG" ), "BGCOLOR", GLOBAL.editColor.searchBack << IupGetAttribute( IupGetHandle( "btnSearch_BG" ), "BGCOLOR" ) );

			IupSetAttribute( IupGetHandle( "btnError_FG" ), "BGCOLOR", GLOBAL.editColor.errorFore << IupGetAttribute( IupGetHandle( "btnError_FG" ), "BGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnError_BG" ), "BGCOLOR", GLOBAL.editColor.errorBack << IupGetAttribute( IupGetHandle( "btnError_BG" ), "BGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnWarning_FG" ), "BGCOLOR", GLOBAL.editColor.warningFore << IupGetAttribute( IupGetHandle( "btnWarning_FG" ), "BGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnWarning_BG" ), "BGCOLOR", GLOBAL.editColor.warringBack << IupGetAttribute( IupGetHandle( "btnWarning_BG" ), "BGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnBrace_FG" ), "BGCOLOR", GLOBAL.editColor.braceFore << IupGetAttribute( IupGetHandle( "btnBrace_FG" ), "BGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnBrace_BG" ), "BGCOLOR", GLOBAL.editColor.braceBack << IupGetAttribute( IupGetHandle( "btnBrace_BG" ), "BGCOLOR" ) );

			IupSetAttribute( IupGetHandle( "btnMarker0Color" ), "BGCOLOR", GLOBAL.editColor.maker[0] << IupGetAttribute( IupGetHandle( "btnMarker0Color" ), "BGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnMarker1Color" ), "BGCOLOR", GLOBAL.editColor.maker[1] << IupGetAttribute( IupGetHandle( "btnMarker1Color" ), "BGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnMarker2Color" ), "BGCOLOR", GLOBAL.editColor.maker[2] << IupGetAttribute( IupGetHandle( "btnMarker2Color" ), "BGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnMarker3Color" ), "BGCOLOR", GLOBAL.editColor.maker[3] << IupGetAttribute( IupGetHandle( "btnMarker3Color" ), "BGCOLOR" ) );

			/+
			// Reassign the color
			IupSetAttribute( IupGetHandle( "btn_Scintilla_FG" ), "BGCOLOR", GLOBAL.editColor.scintillaFore.toCString );
			IupSetAttribute( IupGetHandle( "btn_Scintilla_BG" ), "BGCOLOR", GLOBAL.editColor.scintillaBack.toCString );
			IupSetAttribute( IupGetHandle( "btnSCE_B_COMMENT_FG" ), "BGCOLOR", GLOBAL.editColor.SCE_B_COMMENT_Fore.toCString );
			IupSetAttribute( IupGetHandle( "btnSCE_B_COMMENT_BG" ), "BGCOLOR", GLOBAL.editColor.SCE_B_COMMENT_Back.toCString );
			IupSetAttribute( IupGetHandle( "btnSCE_B_NUMBER_FG" ), "BGCOLOR", GLOBAL.editColor.SCE_B_NUMBER_Fore.toCString );
			IupSetAttribute( IupGetHandle( "btnSCE_B_NUMBER_BG" ), "BGCOLOR", GLOBAL.editColor.SCE_B_NUMBER_Back.toCString );
			IupSetAttribute( IupGetHandle( "btnSCE_B_STRING_FG" ), "BGCOLOR", GLOBAL.editColor.SCE_B_STRING_Fore.toCString );
			IupSetAttribute( IupGetHandle( "btnSCE_B_STRING_BG" ), "BGCOLOR", GLOBAL.editColor.SCE_B_STRING_Back.toCString );
			IupSetAttribute( IupGetHandle( "btnSCE_B_PREPROCESSOR_FG" ), "BGCOLOR", GLOBAL.editColor.SCE_B_PREPROCESSOR_Fore.toCString );
			IupSetAttribute( IupGetHandle( "btnSCE_B_PREPROCESSOR_BG" ), "BGCOLOR", GLOBAL.editColor.SCE_B_PREPROCESSOR_Back.toCString );
			IupSetAttribute( IupGetHandle( "btnSCE_B_OPERATOR_FG" ), "BGCOLOR", GLOBAL.editColor.SCE_B_OPERATOR_Fore.toCString );
			IupSetAttribute( IupGetHandle( "btnSCE_B_OPERATOR_BG" ), "BGCOLOR", GLOBAL.editColor.SCE_B_OPERATOR_Back.toCString );
			IupSetAttribute( IupGetHandle( "btnSCE_B_IDENTIFIER_FG" ), "BGCOLOR", GLOBAL.editColor.SCE_B_IDENTIFIER_Fore.toCString );
			IupSetAttribute( IupGetHandle( "btnSCE_B_IDENTIFIER_BG" ), "BGCOLOR", GLOBAL.editColor.SCE_B_IDENTIFIER_Back.toCString );
			IupSetAttribute( IupGetHandle( "btnSCE_B_COMMENTBLOCK_FG" ), "BGCOLOR", GLOBAL.editColor.SCE_B_COMMENTBLOCK_Fore.toCString );
			IupSetAttribute( IupGetHandle( "btnSCE_B_COMMENTBLOCK_BG" ), "BGCOLOR", GLOBAL.editColor.SCE_B_COMMENTBLOCK_Back.toCString );
			IupSetAttribute( IupGetHandle( "btnPrjTitle" ), "BGCOLOR", GLOBAL.editColor.prjTitle.toCString );
			IupSetAttribute( IupGetHandle( "btnSourceTypeFolder" ), "BGCOLOR", GLOBAL.editColor.prjSourceType.toCString );		
			
			IupSetAttribute( IupGetHandle( "btnPrj_FG" ), "BGCOLOR", GLOBAL.editColor.projectFore.toCString );
			IupSetAttribute( IupGetHandle( "btnPrj_BG" ), "BGCOLOR", GLOBAL.editColor.projectBack.toCString );	
			IupSetAttribute( IupGetHandle( "btnOutline_FG" ), "BGCOLOR", GLOBAL.editColor.outlineFore.toCString );
			IupSetAttribute( IupGetHandle( "btnOutline_BG" ), "BGCOLOR", GLOBAL.editColor.outlineBack.toCString );	
			IupSetAttribute( IupGetHandle( "btnFilelist_FG" ), "BGCOLOR", GLOBAL.editColor.filelistFore.toCString );
			IupSetAttribute( IupGetHandle( "btnFilelist_BG" ), "BGCOLOR", GLOBAL.editColor.filelistBack.toCString );	
			IupSetAttribute( IupGetHandle( "btnOutput_FG" ), "BGCOLOR", GLOBAL.editColor.outputFore.toCString );
			IupSetAttribute( IupGetHandle( "btnOutput_BG" ), "BGCOLOR", GLOBAL.editColor.outputBack.toCString );	
			IupSetAttribute( IupGetHandle( "btnSearch_FG" ), "BGCOLOR", GLOBAL.editColor.searchFore.toCString );
			IupSetAttribute( IupGetHandle( "btnSearch_BG" ), "BGCOLOR", GLOBAL.editColor.searchBack.toCString );
			
			IupSetAttribute( IupGetHandle( "btnError_FG" ), "BGCOLOR", GLOBAL.editColor.errorFore.toCString );
			IupSetAttribute( IupGetHandle( "btnError_BG" ), "BGCOLOR", GLOBAL.editColor.errorBack.toCString );	
			IupSetAttribute( IupGetHandle( "btnWarning_FG" ), "BGCOLOR", GLOBAL.editColor.warningFore.toCString );
			IupSetAttribute( IupGetHandle( "btnWarning_BG" ), "BGCOLOR", GLOBAL.editColor.warringBack.toCString );	
			IupSetAttribute( IupGetHandle( "btnBrace_FG" ), "BGCOLOR", GLOBAL.editColor.braceFore.toCString );
			IupSetAttribute( IupGetHandle( "btnBrace_BG" ), "BGCOLOR", GLOBAL.editColor.braceBack.toCString );
			
			IupSetAttribute( IupGetHandle( "btnMarker0Color" ), "BGCOLOR", GLOBAL.editColor.maker[0].toCString );
			IupSetAttribute( IupGetHandle( "btnMarker1Color" ), "BGCOLOR", GLOBAL.editColor.maker[1].toCString );
			IupSetAttribute( IupGetHandle( "btnMarker2Color" ), "BGCOLOR", GLOBAL.editColor.maker[2].toCString );
			IupSetAttribute( IupGetHandle( "btnMarker3Color" ), "BGCOLOR", GLOBAL.editColor.maker[3].toCString );
			+/
			

			GLOBAL.projectTree.changeColor();
			GLOBAL.outlineTree.changeColor();
			GLOBAL.fileListTree.changeColor();
			
			// GLOBAL.editColor.keyWord is IupString class
			/*
			GLOBAL.editColor.keyWord[0]					= IupGetAttribute( IupGetHandle( "btnKeyWord0Color" ), "BGCOLOR" );		IupSetAttribute( IupGetHandle( "btnKeyWord0Color" ), "BGCOLOR", GLOBAL.editColor.keyWord[0].toCString );
			GLOBAL.editColor.keyWord[1]					= IupGetAttribute( IupGetHandle( "btnKeyWord1Color" ), "BGCOLOR" );		IupSetAttribute( IupGetHandle( "btnKeyWord1Color" ), "BGCOLOR", GLOBAL.editColor.keyWord[1].toCString );
			GLOBAL.editColor.keyWord[2]					= IupGetAttribute( IupGetHandle( "btnKeyWord2Color" ), "BGCOLOR" );		IupSetAttribute( IupGetHandle( "btnKeyWord2Color" ), "BGCOLOR", GLOBAL.editColor.keyWord[2].toCString );
			GLOBAL.editColor.keyWord[3]					= IupGetAttribute( IupGetHandle( "btnKeyWord3Color" ), "BGCOLOR" );		IupSetAttribute( IupGetHandle( "btnKeyWord3Color" ), "BGCOLOR", GLOBAL.editColor.keyWord[3].toCString );
			*/
			IupSetAttribute( IupGetHandle( "btnKeyWord0Color" ), "BGCOLOR", GLOBAL.editColor.keyWord[0] << IupGetAttribute( IupGetHandle( "btnKeyWord0Color" ), "BGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnKeyWord1Color" ), "BGCOLOR", GLOBAL.editColor.keyWord[1] << IupGetAttribute( IupGetHandle( "btnKeyWord1Color" ), "BGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnKeyWord2Color" ), "BGCOLOR", GLOBAL.editColor.keyWord[2] << IupGetAttribute( IupGetHandle( "btnKeyWord2Color" ), "BGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnKeyWord3Color" ), "BGCOLOR", GLOBAL.editColor.keyWord[3] << IupGetAttribute( IupGetHandle( "btnKeyWord3Color" ), "BGCOLOR" ) );


			
			// Set GLOBAL.messagePanel Color
			GLOBAL.messagePanel.applyColor();
			
			char[] templateName = Util.trim( fromStringz( IupGetAttribute( IupGetHandle( "colorTemplateList" ), "VALUE" ) ) ).dup;
			if( templateName.length )
			{
				IDECONFIG.saveColorTemplate( templateName );
				GLOBAL.colorTemplate = templateName.dup;
			}			

			scope numberString_0 = new IupString( IupGetAttribute( IupGetHandle( "textTrigger" ), "VALUE" ) );
			scope numberString_1 = new IupString( IupGetAttribute( IupGetHandle( "textIncludeLevel" ), "VALUE" ) );
			
			GLOBAL.autoCompletionTriggerWordCount		= Integer.atoi( numberString_0.toDString );
			GLOBAL.statusBar.setOriginalTrigger( GLOBAL.autoCompletionTriggerWordCount );
			GLOBAL.includeLevel							= Integer.atoi( numberString_1.toDString );

			if( GLOBAL.includeLevel < 0 ) GLOBAL.includeLevel = 0;

			GLOBAL.compilerFullPath						= IupGetAttribute( IupGetHandle( "compilerPath_Handle" ), "VALUE" );
			GLOBAL.x64compilerFullPath					= IupGetAttribute( IupGetHandle( "x64compilerPath_Handle" ), "VALUE" );
			GLOBAL.debuggerFullPath						= IupGetAttribute( IupGetHandle( "debuggerPath_Handle" ), "VALUE" );
			//GLOBAL.defaultOption						= fromStringz( IupGetAttribute( IupGetHandle( "defaultOption_Handle" ), "VALUE" ) ).dup;
			GLOBAL.compilerAnootation					= fromStringz( IupGetAttribute( IupGetHandle( "toggleAnnotation" ), "VALUE" ) ).dup;
			GLOBAL.compilerWindow						= fromStringz( IupGetAttribute( IupGetHandle( "toggleShowResultWindow" ), "VALUE" ) ).dup;
			GLOBAL.compilerSFX							= fromStringz( IupGetAttribute( IupGetHandle( "toggleSFX" ), "VALUE" ) ).dup;
			
			GLOBAL.delExistExe							= fromStringz( IupGetAttribute( IupGetHandle( "toggleDelPrevEXE" ), "VALUE" ) ).dup;
			GLOBAL.consoleExe							= fromStringz( IupGetAttribute( IupGetHandle( "toggleConsoleExe" ), "VALUE" ) ).dup;
			
			try
			{
				Ihandle* _mHandle = IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textMonitorID" );
				if( _mHandle != null )
				{
					GLOBAL.consoleWindow.id = Integer.toInt( fromStringz( IupGetAttribute( _mHandle, "VALUE" ) ) ) - 1;
					if( GLOBAL.consoleWindow.id < 0 || GLOBAL.consoleWindow.id >= GLOBAL.monitors.length )
					{
						GLOBAL.consoleWindow.id = 0;
						IupSetAttribute( _mHandle, "VALUE", "1" );
					}
				}
				_mHandle = IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textConsoleX" );
				if( _mHandle != null ) GLOBAL.consoleWindow.x = Integer.atoi( fromStringz( IupGetAttribute( _mHandle, "VALUE" ) ) );
				_mHandle = IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textConsoleY" );
				if( _mHandle != null ) GLOBAL.consoleWindow.y = Integer.atoi( fromStringz( IupGetAttribute( _mHandle, "VALUE" ) ) );
				_mHandle = IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textConsoleW" );
				if( _mHandle != null ) GLOBAL.consoleWindow.w = Integer.atoi( fromStringz( IupGetAttribute( _mHandle, "VALUE" ) ) );
				_mHandle = IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textConsoleH" );
				if( _mHandle != null ) GLOBAL.consoleWindow.h = Integer.atoi( fromStringz( IupGetAttribute( _mHandle, "VALUE" ) ) );
			}
			catch
			{
				GLOBAL.consoleWindow.id = 0;
				GLOBAL.consoleWindow.x = GLOBAL.consoleWindow.y = GLOBAL.consoleWindow.w = GLOBAL.consoleWindow.h = 0;
				Ihandle* _mHandle = IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textMonitorID" );
				if( _mHandle != null ) IupSetAttribute( _mHandle, "VALUE", "1" );
			}
			

			GLOBAL.enableKeywordComplete				= fromStringz( IupGetAttribute( IupGetHandle( "toggleKeywordComplete" ), "VALUE" ) ).dup;
			GLOBAL.enableIncludeComplete				= fromStringz( IupGetAttribute( IupGetHandle( "toggleIncludeComplete" ), "VALUE" ) ).dup;
			GLOBAL.enableParser							= fromStringz( IupGetAttribute( IupGetHandle( "toggleUseParser" ), "VALUE" ) ).dup;
			
			GLOBAL.showFunctionTitle					= fromStringz( IupGetAttribute( IupGetHandle( "toggleFunctionTitle" ), "VALUE" ) ).dup;
			GLOBAL.widthFunctionTitle					= IupGetAttribute( IupGetHandle( "textFunctionTitle" ), "VALUE" );
			GLOBAL.showTypeWithParams					= fromStringz( IupGetAttribute( IupGetHandle( "toggleWithParams" ), "VALUE" ) ).dup;
			GLOBAL.toggleIgnoreCase						= fromStringz( IupGetAttribute( IupGetHandle( "toggleIGNORECASE" ), "VALUE" ) ).dup;
			GLOBAL.toggleCaseInsensitive				= fromStringz( IupGetAttribute( IupGetHandle( "toggleCASEINSENSITIVE" ), "VALUE" ) ).dup;
			GLOBAL.toggleShowListType					= fromStringz( IupGetAttribute( IupGetHandle( "toggleSHOWLISTTYPE" ), "VALUE" ) ).dup;
			GLOBAL.toggleShowAllMember					= fromStringz( IupGetAttribute( IupGetHandle( "toggleSHOWALLMEMBER" ), "VALUE" ) ).dup;
			GLOBAL.toggleEnableDwell					= fromStringz( IupGetAttribute( IupGetHandle( "toggleDWELL" ), "VALUE" ) ).dup;

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

			if( GLOBAL.showFunctionTitle == "ON" )
			{
				IupSetAttribute( GLOBAL.toolbar.getListHandle(), "VISIBLE", "YES" );
				IupSetAttribute( GLOBAL.toolbar.getListHandle(), "SIZE", GLOBAL.widthFunctionTitle.toCString );
				IupRefresh( GLOBAL.toolbar.getListHandle() );
			}
			else
				IupSetAttribute( GLOBAL.toolbar.getListHandle(), "VISIBLE", "NO" );

			foreach( CScintilla cSci; GLOBAL.scintillaManager )
			{
				if( cSci !is null ) cSci.setGlobalSetting();
			}
			
			
			//=====================FONT=====================
			// Set Default Font
			if(  GLOBAL.fonts[0].fontString.length )
			{
				IupSetGlobal( "DEFAULTFONT", toStringz( GLOBAL.fonts[0].fontString.dup ) );

				if( GLOBAL.fonts[0].fontString.length )
				{
					int comma = Util.index( GLOBAL.fonts[0].fontString, "," );
					if( comma < GLOBAL.fonts[0].fontString.length )
					{
						IupSetGlobal( "DEFAULTFONTFACE", toStringz( ( GLOBAL.fonts[0].fontString[0..comma] ).dup ) );

						for( int i = GLOBAL.fonts[0].fontString.length - 1; i > comma; -- i )
						{
							if( GLOBAL.fonts[0].fontString[i] < 48 || GLOBAL.fonts[0].fontString[i] > 57 )
							{
								IupSetGlobal( "DEFAULTFONTSIZE", toStringz( ( GLOBAL.fonts[0].fontString[i+1..length] ).dup ) );

								if( ++comma  < i ) IupSetGlobal( "DEFAULTFONTSTYLE", toStringz( ( GLOBAL.fonts[0].fontString[comma..i] ).dup ) );
								
								break;
							}
						}
						
					}
				}
			}			
			scope docTabString = new IupString( GLOBAL.fonts[0].fontString );
			IupSetAttribute( GLOBAL.documentTabs, "TABFONT", docTabString.toCString );
			IupRefresh( GLOBAL.documentTabs );
			
			GLOBAL.fileListTree.setTitleFont(); // Change Filelist Title Font
			scope leftsideString = new IupString( GLOBAL.fonts[2].fontString );	IupSetAttribute( GLOBAL.projectViewTabs, "FONT", leftsideString.toCString );// Leftside
			scope fileListString = new IupString( GLOBAL.fonts[3].fontString );	IupSetAttribute( GLOBAL.fileListTree.getTreeHandle, "FONT", fileListString.toCString );// Filelist
			scope prjString = new IupString( GLOBAL.fonts[4].fontString ); 		IupSetAttribute( GLOBAL.projectTree.getTreeHandle, "FONT", prjString.toCString );// Project
			scope messageString = new IupString( GLOBAL.fonts[6].fontString );	IupSetAttribute( GLOBAL.messageWindowTabs, "TABFONT", messageString.toCString );// Bottom
			scope outputString = new IupString( GLOBAL.fonts[7].fontString );	IupSetAttribute( GLOBAL.messagePanel.getOutputPanelHandle, "FONT", outputString.toCString ); //IupSetAttribute( GLOBAL.outputPanel, "FONT", outputString.toCString );// Output
			scope searchString = new IupString( GLOBAL.fonts[8].fontString );	IupSetAttribute( GLOBAL.messagePanel.getSearchOutputPanelHandle, "FONT", searchString.toCString ); //IupSetAttribute( GLOBAL.searchOutputPanel, "FONT", searchString.toCString );// Search
			version(FBIDE)
			{
				scope debugString = new IupString( GLOBAL.fonts[8].fontString );
				IupSetAttribute( GLOBAL.debugPanel.getConsoleHandle, "FONT", debugString.toCString );// Debugger (shared Search)
			}
			scope statusString = new IupString( GLOBAL.fonts[11].fontString );	IupSetAttribute( GLOBAL.statusBar.getLayoutHandle, "FONT", statusString.toCString );// StatusBar
			scope outlineString = new IupString( GLOBAL.fonts[5].fontString );	IupSetAttribute( GLOBAL.outlineTree.getZBoxHandle, "FONT", outlineString.toCString );// Outline	
			version(FBIDE) GLOBAL.debugPanel.setFont();
			
			GLOBAL.manualPath							= IupGetAttribute( IupGetHandle( "textchm" ), "VALUE" );
			GLOBAL.toggleUseManual						= fromStringz(IupGetAttribute( IupGetHandle( "toggleUseManual" ), "VALUE" )).dup;
			
			/*
			// Save Setup to Xml
			IDECONFIG.save();
			*/
			IDECONFIG.saveINI();
			IupRefreshChildren( IupGetHandle( "PreferenceHandle" ) );
		}
		catch( Exception e )
		{
			IupMessage( "CPreferenceDialog_btnOK_cb", toStringz( e.toString ) ); 
		}

		return IUP_DEFAULT;
	}

	private int CPreferenceDialog_colorChoose_cb( Ihandle* ih )
	{
		Ihandle* dlg = IupColorDlg();

		IupSetAttribute( dlg, "VALUE", IupGetAttribute( ih, "BGCOLOR" ) );
		//IupSetAttribute(dlg, "ALPHA", "142");
		IupSetAttribute(dlg, "SHOWHEX", "YES");
		IupSetAttribute(dlg, "SHOWCOLORTABLE", "YES");
		IupSetAttribute(dlg, "TITLE", GLOBAL.languageItems["color"].toCString() );

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
		IupSetAttribute(dlg, "TITLE", GLOBAL.languageItems["color"].toCString() );

		IupPopup( dlg, IUP_CURRENT, IUP_CURRENT );

		if( IupGetInt( dlg, "STATUS" ) )
		{
			IupSetAttribute( ih, "BGCOLOR", IupGetAttribute( dlg, "VALUE" ) );
			
			Ihandle* messageDlg = IupMessageDlg();
			IupSetAttributes( messageDlg, "DIALOGTYPE=QUESTION,BUTTONDEFAULT=2,BUTTONS=YESNO" );
			IupSetAttribute( messageDlg, "VALUE", GLOBAL.languageItems["applycolor"].toCString );
			IupSetAttribute( messageDlg, "TITLE", GLOBAL.languageItems["quest"].toCString() );
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
	
	private int colorTemplateList_VALUECHANGED_CB( Ihandle *ih )
	{
		char[]		templateName = fromStringz( IupGetAttribute( ih, "VALUE" ) );
		char[][]	colors = IDECONFIG.loadColorTemplate( templateName );
		
		if( colors.length != 48 ) return IUP_DEFAULT;
		
		for( int i = 0; i < 48; i ++ )
			if( CPreferenceDialog.kbg[i] is null ) CPreferenceDialog.kbg[i] = new IupString( colors[i] ); else CPreferenceDialog.kbg[i] = colors[i];
		
		if( colors.length == 48 )
		{
			IupSetAttribute( IupGetHandle( "btnCaretLine" ), "BGCOLOR", CPreferenceDialog.kbg[0].toCString );
			IupSetAttribute( IupGetHandle( "btnCursor" ), "BGCOLOR", CPreferenceDialog.kbg[1].toCString );
			IupSetAttribute( IupGetHandle( "btnSelectFore" ), "BGCOLOR", CPreferenceDialog.kbg[2].toCString );
			IupSetAttribute( IupGetHandle( "btnSelectBack" ), "BGCOLOR", CPreferenceDialog.kbg[3].toCString );
			IupSetAttribute( IupGetHandle( "btnLinenumFore" ), "BGCOLOR", CPreferenceDialog.kbg[4].toCString );
			IupSetAttribute( IupGetHandle( "btnLinenumBack" ), "BGCOLOR", CPreferenceDialog.kbg[5].toCString );
			IupSetAttribute( IupGetHandle( "btnFoldingColor" ), "BGCOLOR", CPreferenceDialog.kbg[6].toCString );

			version(Windows)
				IupSetAttribute( IupGetHandle( "textAlpha" ), "SPINVALUE", CPreferenceDialog.kbg[7].toCString );
			else
				IupSetAttribute( IupGetHandle( "textAlpha" ), "VALUE", CPreferenceDialog.kbg[7].toCString );

			IupSetAttribute( IupGetHandle( "btnBrace_FG" ), "BGCOLOR", CPreferenceDialog.kbg[8].toCString );
			IupSetAttribute( IupGetHandle( "btnBrace_BG" ), "BGCOLOR", CPreferenceDialog.kbg[9].toCString );
			IupSetAttribute( IupGetHandle( "btnError_FG" ), "BGCOLOR", CPreferenceDialog.kbg[10].toCString );
			IupSetAttribute( IupGetHandle( "btnError_BG" ), "BGCOLOR", CPreferenceDialog.kbg[11].toCString );
			IupSetAttribute( IupGetHandle( "btnWarning_FG" ), "BGCOLOR", CPreferenceDialog.kbg[12].toCString );
			IupSetAttribute( IupGetHandle( "btnWarning_BG" ), "BGCOLOR", CPreferenceDialog.kbg[13].toCString );


			IupSetAttribute( IupGetHandle( "btn_Scintilla_FG" ), "BGCOLOR", CPreferenceDialog.kbg[14].toCString );
			IupSetAttribute( IupGetHandle( "btn_Scintilla_BG" ), "BGCOLOR", CPreferenceDialog.kbg[15].toCString );

			IupSetAttribute( IupGetHandle( "btnSCE_B_COMMENT_FG" ), "BGCOLOR", CPreferenceDialog.kbg[16].toCString );
			IupSetAttribute( IupGetHandle( "btnSCE_B_COMMENT_BG" ), "BGCOLOR", CPreferenceDialog.kbg[17].toCString );
			IupSetAttribute( IupGetHandle( "btnSCE_B_NUMBER_FG" ), "BGCOLOR", CPreferenceDialog.kbg[18].toCString );
			IupSetAttribute( IupGetHandle( "btnSCE_B_NUMBER_BG" ), "BGCOLOR", CPreferenceDialog.kbg[19].toCString );
			IupSetAttribute( IupGetHandle( "btnSCE_B_STRING_FG" ), "BGCOLOR", CPreferenceDialog.kbg[20].toCString );
			IupSetAttribute( IupGetHandle( "btnSCE_B_STRING_BG" ), "BGCOLOR", CPreferenceDialog.kbg[21].toCString );
			IupSetAttribute( IupGetHandle( "btnSCE_B_PREPROCESSOR_FG" ), "BGCOLOR", CPreferenceDialog.kbg[22].toCString );
			IupSetAttribute( IupGetHandle( "btnSCE_B_PREPROCESSOR_BG" ), "BGCOLOR", CPreferenceDialog.kbg[23].toCString );
			IupSetAttribute( IupGetHandle( "btnSCE_B_OPERATOR_FG" ), "BGCOLOR", CPreferenceDialog.kbg[24].toCString );
			IupSetAttribute( IupGetHandle( "btnSCE_B_OPERATOR_BG" ), "BGCOLOR", CPreferenceDialog.kbg[25].toCString );
			IupSetAttribute( IupGetHandle( "btnSCE_B_IDENTIFIER_FG" ), "BGCOLOR", CPreferenceDialog.kbg[26].toCString );
			IupSetAttribute( IupGetHandle( "btnSCE_B_IDENTIFIER_BG" ), "BGCOLOR", CPreferenceDialog.kbg[27].toCString );
			IupSetAttribute( IupGetHandle( "btnSCE_B_COMMENTBLOCK_FG" ), "BGCOLOR", CPreferenceDialog.kbg[28].toCString );
			IupSetAttribute( IupGetHandle( "btnSCE_B_COMMENTBLOCK_BG" ), "BGCOLOR", CPreferenceDialog.kbg[29].toCString );
			
			IupSetAttribute( IupGetHandle( "btnPrj_FG" ), "BGCOLOR", CPreferenceDialog.kbg[30].toCString );
			IupSetAttribute( IupGetHandle( "btnPrj_BG" ), "BGCOLOR", CPreferenceDialog.kbg[31].toCString );
			IupSetAttribute( IupGetHandle( "btnOutline_FG" ), "BGCOLOR", CPreferenceDialog.kbg[32].toCString );
			IupSetAttribute( IupGetHandle( "btnOutline_BG" ), "BGCOLOR", CPreferenceDialog.kbg[33].toCString );
			IupSetAttribute( IupGetHandle( "btnFilelist_FG" ), "BGCOLOR", CPreferenceDialog.kbg[34].toCString );
			IupSetAttribute( IupGetHandle( "btnFilelist_BG" ), "BGCOLOR", CPreferenceDialog.kbg[35].toCString );
			IupSetAttribute( IupGetHandle( "btnOutput_FG" ), "BGCOLOR", CPreferenceDialog.kbg[36].toCString );
			IupSetAttribute( IupGetHandle( "btnOutput_BG" ), "BGCOLOR", CPreferenceDialog.kbg[37].toCString );
			IupSetAttribute( IupGetHandle( "btnSearch_FG" ), "BGCOLOR", CPreferenceDialog.kbg[38].toCString );
			IupSetAttribute( IupGetHandle( "btnSearch_BG" ), "BGCOLOR", CPreferenceDialog.kbg[39].toCString );
			
			IupSetAttribute( IupGetHandle( "btnPrjTitle" ), "BGCOLOR", CPreferenceDialog.kbg[40].toCString );
			IupSetAttribute( IupGetHandle( "btnSourceTypeFolder" ), "BGCOLOR", CPreferenceDialog.kbg[41].toCString );
			
			IupSetAttribute( IupGetHandle( "btnKeyWord0Color" ), "BGCOLOR", CPreferenceDialog.kbg[42].toCString );
			IupSetAttribute( IupGetHandle( "btnKeyWord1Color" ), "BGCOLOR", CPreferenceDialog.kbg[43].toCString );
			IupSetAttribute( IupGetHandle( "btnKeyWord2Color" ), "BGCOLOR", CPreferenceDialog.kbg[44].toCString );
			IupSetAttribute( IupGetHandle( "btnKeyWord3Color" ), "BGCOLOR", CPreferenceDialog.kbg[45].toCString );
			
			IupSetAttribute( IupGetHandle( "btnIndicator" ), "BGCOLOR", CPreferenceDialog.kbg[46].toCString );
			version(Windows)
				IupSetAttribute( IupGetHandle( "textIndicatorAlpha" ), "SPINVALUE", CPreferenceDialog.kbg[47].toCString );
			else
				IupSetAttribute( IupGetHandle( "textIndicatorAlpha" ), "VALUE", CPreferenceDialog.kbg[47].toCString );			
		}
		
		return IUP_DEFAULT;
	}
	
	private int colorTemplateList_reset_ACTION( Ihandle *ih )
	{
		IupSetAttribute( IupGetHandle( "btnCaretLine" ), "BGCOLOR", toStringz( "255 255 128" ) );
		IupSetAttribute( IupGetHandle( "btnCursor" ), "BGCOLOR", toStringz( "0 0 0" ) );
		IupSetAttribute( IupGetHandle( "btnSelectFore" ), "BGCOLOR", toStringz( "255 255 255" ) );
		IupSetAttribute( IupGetHandle( "btnSelectBack" ), "BGCOLOR", toStringz( "0 0 255" ) );
		IupSetAttribute( IupGetHandle( "btnLinenumFore" ), "BGCOLOR", toStringz( "0 0 0" ) );
		IupSetAttribute( IupGetHandle( "btnLinenumBack" ), "BGCOLOR", toStringz( "200 200 200" ) );
		IupSetAttribute( IupGetHandle( "btnFoldingColor" ), "BGCOLOR", toStringz( "241 243 243" ) );

		version(Windows)
			IupSetAttribute( IupGetHandle( "textAlpha" ), "SPINVALUE", toStringz( "64" ) );
		else
			IupSetAttribute( IupGetHandle( "textAlpha" ), "VALUE", toStringz( "64" ) );

		IupSetAttribute( IupGetHandle( "btnBrace_FG" ), "BGCOLOR", toStringz( "255 0 0" ) );
		IupSetAttribute( IupGetHandle( "btnBrace_BG" ), "BGCOLOR", toStringz( "0 255 0" ) );
		IupSetAttribute( IupGetHandle( "btnError_FG" ), "BGCOLOR", toStringz( "102 69 3" ) );
		IupSetAttribute( IupGetHandle( "btnError_BG" ), "BGCOLOR", toStringz( "255 200 227" ) );
		IupSetAttribute( IupGetHandle( "btnWarning_FG" ), "BGCOLOR", toStringz( "0 0 255" ) );
		IupSetAttribute( IupGetHandle( "btnWarning_BG" ), "BGCOLOR", toStringz( "255 255 157" ) );
		IupSetAttribute( IupGetHandle( "btnManual_FG" ), "BGCOLOR", toStringz( "255 255 255" ) );
		IupSetAttribute( IupGetHandle( "btnManual_BG" ), "BGCOLOR", toStringz( "80 80 80" ) );


		IupSetAttribute( IupGetHandle( "btn_Scintilla_FG" ), "BGCOLOR", toStringz( "0 0 0" ) );
		IupSetAttribute( IupGetHandle( "btn_Scintilla_BG" ), "BGCOLOR", toStringz( "255 255 255" ) );

		IupSetAttribute( IupGetHandle( "btnSCE_B_COMMENT_FG" ), "BGCOLOR", toStringz( "0 128 0" ) );
		IupSetAttribute( IupGetHandle( "btnSCE_B_COMMENT_BG" ), "BGCOLOR", toStringz( "255 255 255" ) );
		IupSetAttribute( IupGetHandle( "btnSCE_B_NUMBER_FG" ), "BGCOLOR", toStringz( "128 128 64" ) );
		IupSetAttribute( IupGetHandle( "btnSCE_B_NUMBER_BG" ), "BGCOLOR", toStringz( "255 255 255" ) );
		IupSetAttribute( IupGetHandle( "btnSCE_B_STRING_FG" ), "BGCOLOR", toStringz( "128 0 0" ) );
		IupSetAttribute( IupGetHandle( "btnSCE_B_STRING_BG" ), "BGCOLOR", toStringz( "255 255 255" ) );
		IupSetAttribute( IupGetHandle( "btnSCE_B_PREPROCESSOR_FG" ), "BGCOLOR", toStringz( "0 0 255" ) );
		IupSetAttribute( IupGetHandle( "btnSCE_B_PREPROCESSOR_BG" ), "BGCOLOR", toStringz( "255 255 255" ) );
		IupSetAttribute( IupGetHandle( "btnSCE_B_OPERATOR_FG" ), "BGCOLOR", toStringz( "160 20 20" ) );
		IupSetAttribute( IupGetHandle( "btnSCE_B_OPERATOR_BG" ), "BGCOLOR", toStringz( "255 255 255" ) );
		IupSetAttribute( IupGetHandle( "btnSCE_B_IDENTIFIER_FG" ), "BGCOLOR", toStringz( "0 0 0" ) );
		IupSetAttribute( IupGetHandle( "btnSCE_B_IDENTIFIER_BG" ), "BGCOLOR", toStringz( "255 255 255" ) );
		IupSetAttribute( IupGetHandle( "btnSCE_B_COMMENTBLOCK_FG" ), "BGCOLOR", toStringz( "0 128 0" ) );
		IupSetAttribute( IupGetHandle( "btnSCE_B_COMMENTBLOCK_BG" ), "BGCOLOR", toStringz( "255 255 255" ) );
		
		IupSetAttribute( IupGetHandle( "btnPrj_FG" ), "BGCOLOR", toStringz( "0 0 0" ) );
		IupSetAttribute( IupGetHandle( "btnPrj_BG" ), "BGCOLOR", toStringz( "255 255 255" ) );
		IupSetAttribute( IupGetHandle( "btnOutline_FG" ), "BGCOLOR", toStringz( "0 0 0" ) );
		IupSetAttribute( IupGetHandle( "btnOutline_BG" ), "BGCOLOR", toStringz( "255 255 255" ) );
		IupSetAttribute( IupGetHandle( "btnFilelist_FG" ), "BGCOLOR", toStringz( "0 0 0" ) );
		IupSetAttribute( IupGetHandle( "btnFilelist_BG" ), "BGCOLOR", toStringz( "255 255 255" ) );
		IupSetAttribute( IupGetHandle( "btnOutput_FG" ), "BGCOLOR", toStringz( "0 0 0" ) );
		IupSetAttribute( IupGetHandle( "btnOutput_BG" ), "BGCOLOR", toStringz( "255 255 255" ) );
		IupSetAttribute( IupGetHandle( "btnSearch_FG" ), "BGCOLOR", toStringz( "0 0 0" ) );
		IupSetAttribute( IupGetHandle( "btnSearch_BG" ), "BGCOLOR", toStringz( "255 255 255" ) );
		
		IupSetAttribute( IupGetHandle( "btnPrjTitle" ), "BGCOLOR", toStringz( "128 0 0" ) );
		IupSetAttribute( IupGetHandle( "btnSourceTypeFolder" ), "BGCOLOR", toStringz( "0 0 255" ) );

		// Keyword Default
		for( int i = 42; i < 46; i ++ )
			if( CPreferenceDialog.kbg[i] is null ) CPreferenceDialog.kbg[i] = new IupString;
			
		CPreferenceDialog.kbg[42] = cast(char[]) "5 91 35";
		CPreferenceDialog.kbg[43] = cast(char[]) "0 0 255";
		CPreferenceDialog.kbg[44] = cast(char[]) "231 144 0";
		CPreferenceDialog.kbg[45] = cast(char[]) "16 108 232";

		IupSetAttribute( IupGetHandle( "btnKeyWord0Color" ), "BGCOLOR", CPreferenceDialog.kbg[42].toCString );
		IupSetAttribute( IupGetHandle( "btnKeyWord1Color" ), "BGCOLOR", CPreferenceDialog.kbg[43].toCString );
		IupSetAttribute( IupGetHandle( "btnKeyWord2Color" ), "BGCOLOR", CPreferenceDialog.kbg[44].toCString );
		IupSetAttribute( IupGetHandle( "btnKeyWord3Color" ), "BGCOLOR", CPreferenceDialog.kbg[45].toCString );
		
		
		IupSetAttribute( IupGetHandle( "btnIndicator" ), "BGCOLOR", toStringz( "0 128 0" ) );
		version(Windows)
			IupSetAttribute( IupGetHandle( "textIndicatorAlpha" ), "SPINVALUE", toStringz( "80" ) );
		else
			IupSetAttribute( IupGetHandle( "textIndicatorAlpha" ), "VALUE", toStringz( "80" ) );			
		
		
		IupSetAttribute( IupGetHandle( "colorTemplateList" ), "VALUE", null );
		GLOBAL.colorTemplate = cast(char[]) "";
	
		return IUP_DEFAULT;
	}
}