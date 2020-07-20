module dialogs.preferenceDlg;

private import iup.iup, iup.iup_scintilla;

private import layouts.table;

private import global, IDE, project, tools, scintilla, actionManager;
private import dialogs.baseDlg, dialogs.helpDlg, dialogs.fileDlg, dialogs.shortcutDlg;

private import tango.stdc.stringz, tango.io.Stdout, tango.io.FilePath, Util = tango.text.Util;

private struct PreferenceDialogParameters
{
	static		IupString[15]		_stringOfLabel;
	static		IupString[50]		kbg, stringSC;
	static		IupString[5]		stringMonitor;
	static		IupString			stringCharSymbol, stringTabWidth, stringColumnEdge, stringBarSize, stringTrigger, stringLevel;
	
	static		CTable				fontTable;
}



class CPreferenceDialog : CBaseDialog
{
	private:

	void createLayout()
	{
		Ihandle* bottom = createDlgButton( "40x12", "aoc" );

		Ihandle* textCompilerPath = IupText( null );
		IupSetAttribute( textCompilerPath, "SIZE", "320x" );
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

		Ihandle* hBox02, hBox01x64, hBox02x64;
		if( GLOBAL.debugPanel !is null )
		{
			version(Windows)
			{
				Ihandle* textx64CompilerPath = IupText( null );
				IupSetAttribute( textx64CompilerPath, "SIZE", "320x" );
				IupSetAttribute( textx64CompilerPath, "VALUE", GLOBAL.x64compilerFullPath.toCString );
				IupSetHandle( "x64compilerPath_Handle", textx64CompilerPath );
				
				Ihandle* btnx64Open = IupButton( null, null );
				IupSetAttribute( btnx64Open, "IMAGE", "icon_openfile" );
				IupSetCallback( btnx64Open, "ACTION", cast(Icallback) &CPreferenceDialog_Openx64CompileBinFile_cb );
				
				Ihandle* _hBox01x64 = IupHbox( textx64CompilerPath, btnx64Open, null );
				IupSetAttributes( _hBox01x64, "ALIGNMENT=ACENTER,MARGIN=5x0" );
				
				hBox01x64 = IupFrame( _hBox01x64 );
				IupSetAttribute( hBox01x64, "TITLE", GLOBAL.languageItems["x64path"].toCString );
				IupSetAttributes( hBox01x64, "EXPANDCHILDREN=YES,SIZE=346x");
				
				
				Ihandle* textx64DebuggerPath = IupText( null );
				IupSetAttribute( textx64DebuggerPath, "SIZE", "320x" );
				IupSetAttribute( textx64DebuggerPath, "VALUE", GLOBAL.x64debuggerFullPath.toCString );
				IupSetHandle( "x64DebuggerPath_Handle", textx64DebuggerPath );
				
				Ihandle* btnOpenx64Debugger = IupButton( null, null );
				IupSetAttributes( btnOpenx64Debugger, "IMAGE=icon_openfile,NAME=x64" );
				IupSetCallback( btnOpenx64Debugger, "ACTION", cast(Icallback) &CPreferenceDialog_OpenDebuggerBinFile_cb );
				
				Ihandle* _hBox02x64 = IupHbox( textx64DebuggerPath, btnOpenx64Debugger, null );
				IupSetAttributes( _hBox02x64, "ALIGNMENT=ACENTER,MARGIN=5x0" );
				
				hBox02x64 = IupFrame( _hBox02x64 );
				IupSetAttribute( hBox02x64, "TITLE", GLOBAL.languageItems["debugx64path"].toCString );
				IupSetAttributes( hBox02x64, "EXPANDCHILDREN=YES,SIZE=346x");
			}


			Ihandle* textDebuggerPath = IupText( null );
			IupSetAttribute( textDebuggerPath, "SIZE", "320x" );
			IupSetAttribute( textDebuggerPath, "VALUE", GLOBAL.debuggerFullPath.toCString );
			IupSetHandle( "debuggerPath_Handle", textDebuggerPath );
			
			Ihandle* btnOpenDebugger = IupButton( null, null );
			IupSetAttributes( btnOpenDebugger, "IMAGE=icon_openfile,NAME=x86" );
			IupSetCallback( btnOpenDebugger, "ACTION", cast(Icallback) &CPreferenceDialog_OpenDebuggerBinFile_cb );
			
			Ihandle* _hBox02 = IupHbox( textDebuggerPath, btnOpenDebugger, null );
			IupSetAttributes( _hBox02, "ALIGNMENT=ACENTER,MARGIN=5x0" );
			
			hBox02 = IupFrame( _hBox02 );
			IupSetAttribute( hBox02, "TITLE", GLOBAL.languageItems["debugpath"].toCString );
			IupSetAttributes( hBox02, "EXPANDCHILDREN=YES,SIZE=346x");			
		}
		
		version(linux)
		{
			Ihandle* textTerminalPath = IupText( null );
			IupSetAttribute( textTerminalPath, "SIZE", "320x" );
			IupSetAttribute( textTerminalPath, "VALUE", GLOBAL.linuxTermName.toCString );
			IupSetHandle( "textTerminalPath", textTerminalPath );
		
			Ihandle* btnOpenTerminal = IupButton( null, null );
			IupSetAttribute( btnOpenTerminal, "IMAGE", "icon_openfile" );
			IupSetCallback( btnOpenTerminal, "ACTION", cast(Icallback) &CPreferenceDialog_OpenTerminalBinFile_cb );
			
			Ihandle* _hBox03 = IupHbox( textTerminalPath, btnOpenTerminal, null );
			IupSetAttributes( _hBox03, "ALIGNMENT=ACENTER,MARGIN=5x0" );
			
			Ihandle* hBox03 = IupFrame( _hBox03 );
			IupSetAttribute( hBox03, "TITLE", GLOBAL.languageItems["terminalpath"].toCString );
			IupSetAttributes( hBox03, "EXPANDCHILDREN=YES,SIZE=346x");			
		}		
		
		// Dummy
		Ihandle* toggleDummy = IupToggle( GLOBAL.languageItems["errorannotation"].toCString, null );		
		IupSetAttribute( toggleDummy, "VALUE", toStringz(GLOBAL.toggleDummy) );
		IupSetHandle( "toggleDummy", toggleDummy );

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
		
		Ihandle* toggleCompileAtBackThread = IupToggle( GLOBAL.languageItems["compileatbackthread"].toCString, null );
		IupSetAttribute( toggleCompileAtBackThread, "VALUE", toStringz(GLOBAL.toggleCompileAtBackThread.dup) );
		IupSetHandle( "toggleCompileAtBackThread", toggleCompileAtBackThread );		
		
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
		
		
		PreferenceDialogParameters.stringMonitor[0] = new IupString( Integer.toString( GLOBAL.consoleWindow.id + 1 ) );
		PreferenceDialogParameters.stringMonitor[1] = new IupString( Integer.toString( GLOBAL.consoleWindow.x ) );
		PreferenceDialogParameters.stringMonitor[2] = new IupString( Integer.toString( GLOBAL.consoleWindow.y ) );
		PreferenceDialogParameters.stringMonitor[3] = new IupString( Integer.toString( GLOBAL.consoleWindow.w ) );
		PreferenceDialogParameters.stringMonitor[4] = new IupString( Integer.toString( GLOBAL.consoleWindow.h ) );
		
		IupSetAttribute( textMonitorID, "VALUE", PreferenceDialogParameters.stringMonitor[0].toCString );
		IupSetAttribute( textConsoleX, "VALUE", PreferenceDialogParameters.stringMonitor[1].toCString );
		IupSetAttribute( textConsoleY, "VALUE", PreferenceDialogParameters.stringMonitor[2].toCString );
		IupSetAttribute( textConsoleW, "VALUE", PreferenceDialogParameters.stringMonitor[3].toCString );
		IupSetAttribute( textConsoleH, "VALUE", PreferenceDialogParameters.stringMonitor[4].toCString );

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
		

		Ihandle* vBoxCompiler = IupVbox( toggleAnnotation, toggleShowResultWindow, toggleSFX, toggleDelPrevEXE, toggleConsoleExe, toggleCompileAtBackThread, hBoxConsole, null );
		version(FBIDE)	IupSetAttributes( vBoxCompiler, "GAP=10,MARGIN=0x1,EXPANDCHILDREN=NO" );
		version(DIDE)	IupSetAttributes( vBoxCompiler, "GAP=16,MARGIN=0x1,EXPANDCHILDREN=NO" );

		Ihandle* frameCompiler = IupFrame( vBoxCompiler );
		IupSetAttribute( frameCompiler, "TITLE", GLOBAL.languageItems["compilersetting"].toCString );
		IupSetAttributes( frameCompiler, "EXPANDCHILDREN=YES,SIZE=346x");
		
		
		Ihandle* vBoxCompilerSettings;
		if( GLOBAL.debugPanel !is null )
		{
			version(Windows)
				vBoxCompilerSettings = IupVbox( hBox01, hBox01x64, hBox02, hBox02x64, frameCompiler, null );
			else
				vBoxCompilerSettings = IupVbox( hBox01, hBox02, hBox03, frameCompiler, null );
				
			IupSetAttributes( vBoxCompilerSettings, "ALIGNMENT=ALEFT,MARGIN=2x5");
			IupSetAttribute( vBoxCompilerSettings, "EXPANDCHILDREN", "YES");
		}
		else
		{
			vBoxCompilerSettings = IupVbox( hBox01, frameCompiler, /*manuFrame,*/ null );
				
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
		
		PreferenceDialogParameters.stringTrigger = new IupString( Integer.toString( GLOBAL.autoCompletionTriggerWordCount ) );
		Ihandle* textTrigger = IupText( null );
		IupSetAttribute( textTrigger, "SIZE", "30x12" );
		IupSetAttribute( textTrigger, "TIP", GLOBAL.languageItems["triggertip"].toCString );
		IupSetAttribute( textTrigger, "VALUE", PreferenceDialogParameters.stringTrigger.toCString );
		IupSetHandle( "textTrigger", textTrigger );
		
		version(FBIDE)
		{
			Ihandle* labelIncludeLevel = IupLabel( toStringz( GLOBAL.languageItems["includelevel"].toDString ~ ":" ) );
			IupSetAttributes( labelIncludeLevel, "SIZE=120x12,GAP=0" );

			PreferenceDialogParameters.stringLevel = new IupString( Integer.toString( GLOBAL.includeLevel ) );
			Ihandle* textIncludeLevel = IupText( null );
			IupSetAttribute( textIncludeLevel, "SIZE", "30x12" );
			IupSetAttribute( textIncludeLevel, "VALUE", PreferenceDialogParameters.stringLevel.toCString );
			IupSetHandle( "textIncludeLevel", textIncludeLevel );
		}

		
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
		
		Ihandle* labelDWELL = IupLabel( GLOBAL.languageItems["dwelldelay"].toCString );
		Ihandle* valDWELL = IupVal( null );
		IupSetAttributes( valDWELL, "MIN=200,MAX=2200,RASTERSIZE=100x16,STEP=0.05,PAGESTEP=0.05" );
		IupSetAttribute( valDWELL, "VALUE", toStringz( GLOBAL.dwellDelay.dup ) );
		IupSetHandle( "valDWELL", valDWELL );
		IupSetCallback( valDWELL, "VALUECHANGED_CB", cast(Icallback) &valDWELL_VALUECHANGED_CB );
		IupSetCallback( valDWELL, "ENTERWINDOW_CB", cast(Icallback) &valDWELL_VALUECHANGED_CB );
		
		
		Ihandle* hBoxDWELL = IupHbox( toggleDWELL, IupFill, labelDWELL, valDWELL, null );
		IupSetAttributes( hBoxDWELL, "ALIGNMENT=ACENTER" );
		

		Ihandle* toggleOverWrite = IupToggle( GLOBAL.languageItems["enableoverwrite"].toCString, null );
		IupSetAttribute( toggleOverWrite, "VALUE", toStringz(GLOBAL.toggleOverWrite.dup) );
		IupSetHandle( "toggleOverWrite", toggleOverWrite );

		Ihandle* toggleBackThread = IupToggle( GLOBAL.languageItems["completeatbackthread"].toCString, null );
		IupSetAttribute( toggleBackThread, "VALUE", toStringz(GLOBAL.toggleCompleteAtBackThread.dup) );
		IupSetHandle( "toggleBackThread", toggleBackThread );
		
		Ihandle* toggleFunctionTitle = IupToggle( GLOBAL.languageItems["showtitle"].toCString, null );
		IupSetAttribute( toggleFunctionTitle, "VALUE", toStringz(GLOBAL.showFunctionTitle.dup) );
		IupSetHandle( "toggleFunctionTitle", toggleFunctionTitle );
		
		/*
		Ihandle* labelFunctionTitle = IupLabel( GLOBAL.languageItems["width"].toCString );
		IupSetAttributes( labelFunctionTitle, "SIZE=80x12,ALIGNMENT=ARIGHT:ACENTER" ); 
		Ihandle* textFunctionTitle = IupText( null );
		IupSetAttribute( textFunctionTitle, "SIZE", "30x12" );
		IupSetAttribute( textFunctionTitle, "VALUE", GLOBAL.widthFunctionTitle.toCString );
		IupSetHandle( "textFunctionTitle", textFunctionTitle );
		*/
		Ihandle* hBoxFunctionTitle = IupHbox( toggleFunctionTitle, null );
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


		version(FBIDE)	Ihandle* hBox00 = IupHbox( labelTrigger, textTrigger, labelIncludeLevel, textIncludeLevel,null );
		version(DIDE)	Ihandle* hBox00 = IupHbox( labelTrigger, textTrigger, null );
		//Ihandle* hBox00_1 = IupHbox( labelIncludeLevel, textIncludeLevel, null );
		
		Ihandle* vBox00 = IupVbox( toggleUseParser, toggleKeywordComplete, toggleIncludeComplete, toggleWithParams, toggleIGNORECASE, toggleCASEINSENSITIVE, toggleSHOWLISTTYPE, toggleSHOWALLMEMBER, hBoxDWELL, toggleOverWrite, toggleBackThread, hBoxFunctionTitle, hBox00, null );
		IupSetAttributes( vBox00, "GAP=10,MARGIN=0x1,EXPANDCHILDREN=NO" );
		
	
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
		
		Ihandle* toggleDocStatus = IupToggle( GLOBAL.languageItems["savedocstatus"].toCString, null );
		IupSetAttribute( toggleDocStatus, "VALUE", toStringz(GLOBAL.editorSetting00.DocStatus.dup) );
		IupSetHandle( "toggleDocStatus", toggleDocStatus );

		Ihandle* toggleLoadAtBackThread = IupToggle( GLOBAL.languageItems["loadfileatbackthread"].toCString, null );
		version(BACKTHREAD)
		{
			IupSetAttribute( toggleLoadAtBackThread, "VALUE", toStringz(GLOBAL.editorSetting00.LoadAtBackThread.dup) );
		}
		else
		{
			IupSetAttribute( toggleLoadAtBackThread, "VALUE", "OFF" );
			IupSetAttribute( toggleLoadAtBackThread, "ACTIVE", "NO" );
		}

		IupSetHandle( "toggleLoadAtBackThread", toggleLoadAtBackThread );
		
		Ihandle* toggleAutoKBLayout = IupToggle( GLOBAL.languageItems["autokblayout"].toCString, null );
		IupSetAttribute( toggleAutoKBLayout, "VALUE", toStringz(GLOBAL.editorSetting00.AutoKBLayout.dup) );
		IupSetHandle( "toggleAutoKBLayout", toggleAutoKBLayout );
		
		version(FBIDE)
		{
			Ihandle* toggleQBCase = IupToggle( GLOBAL.languageItems["qbcase"].toCString, null );
			IupSetAttribute( toggleQBCase, "VALUE", toStringz(GLOBAL.editorSetting00.QBCase.dup) );
			IupSetHandle( "toggleQBCase", toggleQBCase );
			
			Ihandle* toggleUseManual = IupToggle( GLOBAL.languageItems["manualusing"].toCString(), null );
			IupSetAttribute( toggleUseManual, "VALUE", toStringz(GLOBAL.toggleUseManual.dup) );
			IupSetHandle( "toggleUseManual", toggleUseManual );
			
		}

		version(Windows)
		{
			Ihandle* toggleNewDocBOM = IupToggle( GLOBAL.languageItems["newdocbom"].toCString, null );
			IupSetAttribute( toggleNewDocBOM, "VALUE", toStringz(GLOBAL.editorSetting00.NewDocBOM.dup) );
			IupSetHandle( "toggleNewDocBOM", toggleNewDocBOM );
		}
		
		
		PreferenceDialogParameters.stringCharSymbol = new IupString( GLOBAL.editorSetting00.ControlCharSymbol );
		Ihandle* labelSetControlCharSymbol = IupLabel( toStringz( GLOBAL.languageItems["controlcharsymbol"].toDString ~ ":" ) );
		Ihandle* textSetControlCharSymbol = IupText( null );
		IupSetAttribute( textSetControlCharSymbol, "VALUE", PreferenceDialogParameters.stringCharSymbol.toCString );
		IupSetHandle( "textSetControlCharSymbol", textSetControlCharSymbol );
		Ihandle* hBoxControlChar = IupHbox( labelSetControlCharSymbol, textSetControlCharSymbol, null );
		IupSetAttribute( hBoxControlChar, "ALIGNMENT", "ACENTER" );
		
		PreferenceDialogParameters.stringTabWidth = new IupString( GLOBAL.editorSetting00.TabWidth );
		Ihandle* labelTabWidth = IupLabel( toStringz( GLOBAL.languageItems["tabwidth"].toDString ~ ":" ) );
		Ihandle* textTabWidth = IupText( null );
		IupSetAttribute( textTabWidth, "VALUE", PreferenceDialogParameters.stringTabWidth.toCString );
		IupSetHandle( "textTabWidth", textTabWidth );
		Ihandle* hBoxTab = IupHbox( labelTabWidth, textTabWidth, null );
		IupSetAttribute( hBoxTab, "ALIGNMENT", "ACENTER" );
		
		PreferenceDialogParameters.stringColumnEdge = new IupString( GLOBAL.editorSetting00.ColumnEdge );
		Ihandle* labelColumnEdge = IupLabel( toStringz( GLOBAL.languageItems["columnedge"].toDString ~ ":" ) );
		Ihandle* textColumnEdge = IupText( null );
		IupSetAttribute( textColumnEdge, "VALUE", PreferenceDialogParameters.stringColumnEdge.toCString );
		IupSetAttribute( textColumnEdge, "TIP", GLOBAL.languageItems["triggertip"].toCString );
		IupSetHandle( "textColumnEdge", textColumnEdge );
		Ihandle* hBoxColumn = IupHbox( labelColumnEdge, textColumnEdge, null );
		IupSetAttribute( hBoxColumn, "ALIGNMENT", "ACENTER" );

		PreferenceDialogParameters.stringBarSize = new IupString( GLOBAL.editorSetting01.BarSize );
		Ihandle* labelBarsize = IupLabel( toStringz( GLOBAL.languageItems["barsize"].toDString ~ ":" ) );
		Ihandle* textBarSize = IupText( null );
		IupSetAttribute( textBarSize, "VALUE", PreferenceDialogParameters.stringBarSize.toCString );
		IupSetAttribute( textBarSize, "TIP", GLOBAL.languageItems["barsizetip"].toCString );
		IupSetHandle( "textBarSize", textBarSize );
		Ihandle* hBoxBarSize = IupHbox( labelBarsize, textBarSize, null );
		IupSetAttribute( hBoxBarSize, "ALIGNMENT", "ACENTER" );


		version(FBIDE)
		{
			version(Windows)
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
					IupSetAttributes( toggleDocStatus, "" ),
					
					//IupSetAttributes( toggleLoadAtBackThread, "" ),
					IupSetAttributes( toggleAutoKBLayout, "" ),
					IupSetAttributes( toggleQBCase, "" ),

					IupSetAttributes( toggleNewDocBOM, "" ),
					IupSetAttributes( toggleUseManual, "" ),
					
					IupSetAttributes( hBoxTab, "" ),
					IupSetAttributes( hBoxColumn, "" ),

					IupSetAttributes( hBoxBarSize, "" ),
					hBoxControlChar,
					
					null
				);
			}
			else
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
					IupSetAttributes( toggleDocStatus, "" ),
					
					//IupSetAttributes( toggleLoadAtBackThread, "" ),
					IupSetAttributes( toggleQBCase, "" ),
					IupSetAttributes( toggleUseManual, "" ),
					
					IupSetAttributes( hBoxTab, "" ),
					IupSetAttributes( hBoxColumn, "" ),

					IupSetAttributes( hBoxBarSize, "" ),
					hBoxControlChar,
					
					null
				);
			}
		}
		version(DIDE)
		{
			version(Windows)
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
					
					IupSetAttributes( toggleDocStatus, "" ),
					IupSetAttributes( toggleAutoKBLayout, "" ),
					
					IupSetAttributes( toggleNewDocBOM, "" ),
					IupFill(),
					//IupSetAttributes( toggleLoadAtBackThread, "" ),
					
					IupSetAttributes( hBoxTab, "" ),
					IupSetAttributes( hBoxColumn, "" ),

					IupSetAttributes( hBoxBarSize, "" ),
					hBoxControlChar,
					
					null
				);
			}
			else
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
					
					IupSetAttributes( toggleDocStatus, "" ),
					IupFill(),
					//IupSetAttributes( toggleAutoKBLayout, "" ),
					//IupSetAttributes( toggleLoadAtBackThread, "" ),
					
					IupSetAttributes( hBoxTab, "" ),
					IupSetAttributes( hBoxColumn, "" ),

					IupSetAttributes( hBoxBarSize, "" ),
					hBoxControlChar,
					
					null
				);
			}
		}

		//IupSetAttribute(gbox, "SIZECOL", "1");
		//IupSetAttribute(gbox, "SIZELIN", "4");
		IupSetAttributes( gbox, "NUMDIV=2,ALIGNMENTLIN=ACENTER,GAPLIN=10,EXPANDCHILDREN=HORIZONTAL,MARGIN=0x0" );
		
		/+
		// Mark High Light Line
		Ihandle* labelMarker0 = IupLabel( toStringz( GLOBAL.languageItems["maker0"].toDString ~ ": " ) );
		Ihandle* btnMarker0Color = IupFlatButton(  null );
		IupSetAttribute( btnMarker0Color, "FGCOLOR",GLOBAL.editColor.maker[0].toCString );
		version(Windows) IupSetAttribute( btnMarker0Color, "SIZE", "24x8" ); else IupSetAttribute( btnMarker0Color, "SIZE", "24x10" );
		IupSetHandle( "btnMarker0Color", btnMarker0Color );
		IupSetCallback( btnMarker0Color, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		
		Ihandle* labelMarker1 = IupLabel( toStringz( GLOBAL.languageItems["maker1"].toDString ~ ": " ) );
		Ihandle* btnMarker1Color = IupFlatButton( null );
		IupSetAttribute( btnMarker1Color, "FGCOLOR",GLOBAL.editColor.maker[1].toCString );
		version(Windows) IupSetAttribute( btnMarker1Color, "SIZE", "24x8" ); else IupSetAttribute( btnMarker1Color, "SIZE", "24x10" );
		IupSetHandle( "btnMarker1Color", btnMarker1Color );
		IupSetCallback( btnMarker1Color, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelMarker2 = IupLabel( toStringz( GLOBAL.languageItems["maker2"].toDString ~ ": " ) );
		Ihandle* btnMarker2Color = IupFlatButton( null );
		IupSetAttribute( btnMarker2Color, "FGCOLOR",GLOBAL.editColor.maker[2].toCString );
		version(Windows) IupSetAttribute( btnMarker2Color, "SIZE", "24x8" ); else IupSetAttribute( btnMarker2Color, "SIZE", "24x10" );
		IupSetHandle( "btnMarker2Color", btnMarker2Color );
		IupSetCallback( btnMarker2Color, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelMarker3 = IupLabel( toStringz( GLOBAL.languageItems["maker3"].toDString ~ ": " ) );
		Ihandle* btnMarker3Color = IupFlatButton( null );
		IupSetAttribute( btnMarker3Color, "FGCOLOR",GLOBAL.editColor.maker[3].toCString );
		version(Windows) IupSetAttribute( btnMarker3Color, "SIZE", "24x8" ); else IupSetAttribute( btnMarker3Color, "SIZE", "24x10" );
		IupSetHandle( "btnMarker3Color", btnMarker3Color );
		IupSetCallback( btnMarker3Color, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		
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
		+/
		
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
		

		// Font
		PreferenceDialogParameters.fontTable = new CTable();
		//PreferenceDialogParameters.fontTable.setAction( &memberSelect );
		//version(Windows) PreferenceDialogParameters.fontTable.setBUTTON_CB( &memberButton );
		PreferenceDialogParameters.fontTable.setDBLCLICK_CB( &memberDoubleClick );
		
		PreferenceDialogParameters.fontTable.addColumn( GLOBAL.languageItems["item"].toDString );
		PreferenceDialogParameters.fontTable.addColumn( GLOBAL.languageItems["face"].toDString );
		PreferenceDialogParameters.fontTable.addColumn( GLOBAL.languageItems["style"].toDString );
		PreferenceDialogParameters.fontTable.setSplitAttribute( "VALUE", "500" );
		PreferenceDialogParameters.fontTable.addColumn( GLOBAL.languageItems["size"].toDString );
		PreferenceDialogParameters.fontTable.setSplitAttribute( "VALUE", "920" );
		
		for( int i = 0; i < GLOBAL.fonts.length; ++ i )
		{
			char[][] strings = Util.split( GLOBAL.fonts[i].fontString, "," );
			if( strings.length == 2 )
			{
				char[] size, style = " ";
				
				strings[0] = Util.trim( strings[0] );
				int spacePos = Util.rindex( strings[1], " " );
				if( spacePos < strings[1].length )
				{
					size = strings[1][spacePos+1..$].dup;
					style = Util.trim( strings[1][0..spacePos] ).dup;
					if( !style.length ) style = " "; else style = " " ~ style ~ " ";
				}				

				PreferenceDialogParameters.fontTable.addItem( [ GLOBAL.languageItems[GLOBAL.fonts[i].name].toDString, strings[0], style, size ] );
			}
		}
		Ihandle* sb = IupScrollBox( PreferenceDialogParameters.fontTable.getMainHandle );
		IupSetAttributes( sb, "ALIGNMENT=ACENTER" );
		
		
		
		version(FBIDE)	Ihandle* vBoxPage02 = IupVbox( gbox, /*gboxMarkerColor,*/ frameKeywordCase, null );
		version(DIDE)	Ihandle* vBoxPage02 = IupVbox( gbox, /*gboxMarkerColor,*/ null );
		IupSetAttributes( vBoxPage02, "MARGIN=0x1,EXPANDCHILDREN=YES" );

		// Color
		Ihandle* colorTemplateList = IupList( null );
		IupSetHandle( "colorTemplateList", colorTemplateList );
		IupSetAttributes( colorTemplateList, "ACTIVE=YES,EDITBOX=YES,EXPAND=HORIZONTAL,DROPDOWN=YES,VISIBLEITEMS=5" );
		version(linux)IupSetAttributeId( colorTemplateList, "", 1, toStringz( " " ) );
		//IupSetAttribute( colorTemplateList, "VALUE", GLOBAL.colorTemplate.toCString );
		IupSetCallback( colorTemplateList, "DROPDOWN_CB",cast(Icallback) &colorTemplateList_DROPDOWN_CB );
		IupSetCallback( colorTemplateList, "ACTION",cast(Icallback) &colorTemplateList_ACTION_CB );

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
				if( templateName.length )
				{
					char[] templatePath = "settings/colorTemplates";
					if( GLOBAL.linuxHome.length ) templatePath = GLOBAL.linuxHome ~ "/" ~ templatePath; // version(Windows) GLOBAL.linuxHome = null						
				
					for( int i = IupGetInt( _listHandle, "COUNT" ); i >= 1; -- i )
					{
						if( fromStringz( IupGetAttributeId( _listHandle, "", i ) ).dup == templateName )
						{
							scope templateFP = new FilePath( templatePath ~ "/" ~templateName ~ ".ini" );
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
				else
				{
					int result = IupMessageAlarm( null, GLOBAL.languageItems["alarm"].toCString,"No Items be Selected!", "OK" );
				}
			}
			
			return IUP_DEFAULT;
		});
		
		Ihandle* colorTemplateSave = IupButton( null, null );
		IupSetAttributes( colorTemplateSave, "FLAT=NO,IMAGE=icon_save" );
		IupSetAttribute( colorTemplateSave, "TIP", GLOBAL.languageItems["save"].toCString );
		IupSetCallback( colorTemplateSave, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			char[] templateName = Util.trim( fromStringz( IupGetAttribute( IupGetHandle( "colorTemplateList" ), "VALUE" ) ) ).dup;
			if( templateName.length )
			{
				try
				{
					GLOBAL.preferenceDlg.saveColorTemplateINI( templateName );
					IupMessage( GLOBAL.languageItems["colorfile"].toCString(), toStringz( GLOBAL.languageItems["save"].toDString() ~ " " ~GLOBAL.languageItems["ok"].toDString() ) );
				}
				catch( Exception e )
				{
					IupMessageError( null, toStringz( e.toString ) );
				}
			}
			else
			{
				int result = IupMessageAlarm( null, GLOBAL.languageItems["alarm"].toCString, "Color Template Name Is Empty!", "OK" );
			}
			
			return IUP_DEFAULT;
		});		
		
		
		Ihandle* _hboxColorPath = IupHbox( colorTemplateList, colorDefaultRefresh, colorTemplateRemove, colorTemplateSave, null );
		IupSetAttributes( _hboxColorPath, "ALIGNMENT=ACENTER,MARGIN=0x0,EXPAND=HORIZONTAL,SIZE=x12" );
		

		Ihandle* colorTemplateFrame = IupFrame( _hboxColorPath );
		IupSetAttribute( colorTemplateFrame, "TITLE", GLOBAL.languageItems["colorfile"].toCString() );
		IupSetAttributes( colorTemplateFrame, "EXPANDCHILDREN=YES,SIZE=346x");
		
		
		
		Ihandle* labelCaretLine = IupLabel( toStringz( GLOBAL.languageItems["caretline"].toDString ~ ":" ) );
		Ihandle* btnCaretLine = IupFlatButton( null );
		IupSetAttribute( btnCaretLine, "FGCOLOR", GLOBAL.editColor.caretLine.toCString );
		IupSetAttribute( btnCaretLine, "SIZE", "16x8" );
		IupSetHandle( "btnCaretLine", btnCaretLine );
		IupSetCallback( btnCaretLine, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelCursor = IupLabel( toStringz( GLOBAL.languageItems["cursor"].toDString ~ ":" ) );
		Ihandle* btnCursor = IupFlatButton( null );
		IupSetAttribute( btnCursor, "FGCOLOR", GLOBAL.editColor.cursor.toCString );
		IupSetAttribute( btnCursor, "SIZE", "16x8" );
		IupSetHandle( "btnCursor", btnCursor );
		IupSetCallback( btnCursor, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelSelectFore = IupLabel( toStringz( GLOBAL.languageItems["sel"].toDString ~ ":" ) );
		Ihandle* btnSelectFore = IupFlatButton( null );
		IupSetAttribute( btnSelectFore, "FGCOLOR", GLOBAL.editColor.selectionFore.toCString );
		IupSetAttribute( btnSelectFore, "SIZE", "16x8" );
		IupSetHandle( "btnSelectFore", btnSelectFore );
		IupSetCallback( btnSelectFore, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* btnSelectBack = IupFlatButton( null );
		IupSetAttribute( btnSelectBack, "FGCOLOR", GLOBAL.editColor.selectionBack.toCString );
		IupSetAttribute( btnSelectBack, "SIZE", "16x8" );
		IupSetHandle( "btnSelectBack", btnSelectBack );
		IupSetCallback( btnSelectBack, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelLinenumFore = IupLabel( toStringz( GLOBAL.languageItems["ln"].toDString ~ ":" ) );
		Ihandle* btnLinenumFore = IupFlatButton( null );
		IupSetAttribute( btnLinenumFore, "FGCOLOR", GLOBAL.editColor.linenumFore.toCString );
		IupSetAttribute( btnLinenumFore, "SIZE", "16x8" );
		IupSetHandle( "btnLinenumFore", btnLinenumFore );
		IupSetCallback( btnLinenumFore, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* btnLinenumBack = IupFlatButton( null );
		IupSetAttribute( btnLinenumBack, "FGCOLOR", GLOBAL.editColor.linenumBack.toCString );
		IupSetAttribute( btnLinenumBack, "SIZE", "16x8" );
		IupSetHandle( "btnLinenumBack", btnLinenumBack );
		IupSetCallback( btnLinenumBack, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelFoldingColor = IupLabel( toStringz( GLOBAL.languageItems["foldcolor"].toDString ~ ":" ) );
		Ihandle* btnFoldingColor = IupFlatButton( null );
		IupSetAttribute( btnFoldingColor, "FGCOLOR", GLOBAL.editColor.fold.toCString );
		IupSetAttribute( btnFoldingColor, "SIZE", "16x8" );
		IupSetHandle( "btnFoldingColor", btnFoldingColor );
		IupSetCallback( btnFoldingColor, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

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
		Ihandle* btnPrjTitle = IupFlatButton( null );
		IupSetAttribute( btnPrjTitle, "FGCOLOR", GLOBAL.editColor.prjTitle.toCString );
		IupSetAttribute( btnPrjTitle, "SIZE", "16x8" );
		IupSetHandle( "btnPrjTitle", btnPrjTitle );
		IupSetCallback( btnPrjTitle, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );		

		Ihandle* labelSourceTypeFolder = IupLabel( toStringz( GLOBAL.languageItems["sourcefolder"].toDString ~ ":" ) );
		Ihandle* btnSourceTypeFolder = IupFlatButton( null );
		IupSetAttribute( btnSourceTypeFolder, "FGCOLOR", GLOBAL.editColor.prjSourceType.toCString );
		IupSetAttribute( btnSourceTypeFolder, "SIZE", "16x8" );
		IupSetHandle( "btnSourceTypeFolder", btnSourceTypeFolder );
		IupSetCallback( btnSourceTypeFolder, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );		


		// 2017.7.9
		Ihandle* labelIndicator = IupLabel( toStringz( GLOBAL.languageItems["hlcurrentword"].toDString ~ ":" ) );
		Ihandle* btnIndicator = IupFlatButton( null );
		IupSetAttribute( btnIndicator, "FGCOLOR", GLOBAL.editColor.currentWord.toCString );
		IupSetAttribute( btnIndicator, "SIZE", "16x8" );
		IupSetHandle( "btnIndicator", btnIndicator );
		IupSetCallback( btnIndicator, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

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
		version(Windows) IupSetAttributes( gboxColor, "EXPANDCHILDREN=HORIZONTAL,NUMDIV=4,ALIGNMENTLIN=ACENTER,ALIGNMENTCOL=ALEFT,GAPLIN=6,GAPCOL=30,MARGIN=2x8,SIZELIN=-1" ); else IupSetAttributes( gboxColor, "EXPANDCHILDREN=HORIZONTAL,NUMDIV=4,ALIGNMENTLIN=ACENTER,ALIGNMENTCOL=ALEFT,GAPLIN=10,GAPCOL=30,MARGIN=2x10,SIZELIN=1" );

		Ihandle* frameColor = IupFrame( gboxColor );
		IupSetAttributes( frameColor, "MARGIN=0x0,EXPAND=YES,EXPAND=HORIZONTAL" );
		IupSetAttribute( frameColor, "SIZE", "346x" );//IupGetAttribute( frameFont, "SIZE" ) );
		IupSetAttribute( frameColor, "TITLE", GLOBAL.languageItems["color"].toCString );

		
		// Color -1
		Ihandle* label_Scintilla = IupLabel( toStringz( GLOBAL.languageItems["scintilla"].toDString ~ ":" ) );
		Ihandle* btn_Scintilla_FG = IupFlatButton( null );
		Ihandle* btn_Scintilla_BG = IupFlatButton( null );
		IupSetAttribute( btn_Scintilla_FG, "FGCOLOR", GLOBAL.editColor.scintillaFore.toCString );
		IupSetAttribute( btn_Scintilla_BG, "FGCOLOR", GLOBAL.editColor.scintillaBack.toCString );
		IupSetHandle( "btn_Scintilla_FG", btn_Scintilla_FG );
		IupSetHandle( "btn_Scintilla_BG", btn_Scintilla_BG );
		IupSetCallback( btn_Scintilla_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btn_Scintilla_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChooseScintilla_cb );
		IupSetAttribute( btn_Scintilla_FG, "SIZE", "16x8" );
		IupSetAttribute( btn_Scintilla_BG, "SIZE", "16x8" );

		Ihandle* labelSCE_B_COMMENT = IupLabel( toStringz( GLOBAL.languageItems["SCE_B_COMMENT"].toDString ~ ":" ) );
		Ihandle* btnSCE_B_COMMENT_FG = IupFlatButton( null );
		Ihandle* btnSCE_B_COMMENT_BG = IupFlatButton( null );
		IupSetAttribute( btnSCE_B_COMMENT_FG, "FGCOLOR", GLOBAL.editColor.SCE_B_COMMENT_Fore.toCString );
		IupSetAttribute( btnSCE_B_COMMENT_BG, "FGCOLOR", GLOBAL.editColor.SCE_B_COMMENT_Back.toCString );
		IupSetHandle( "btnSCE_B_COMMENT_FG", btnSCE_B_COMMENT_FG );
		IupSetHandle( "btnSCE_B_COMMENT_BG", btnSCE_B_COMMENT_BG );
		IupSetCallback( btnSCE_B_COMMENT_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnSCE_B_COMMENT_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttribute( btnSCE_B_COMMENT_FG, "SIZE", "16x8" );
		IupSetAttribute( btnSCE_B_COMMENT_BG, "SIZE", "16x8" );
		
		Ihandle* labelSCE_B_NUMBER = IupLabel( toStringz( GLOBAL.languageItems["SCE_B_NUMBER"].toDString ~ ":" ) );
		Ihandle* btnSCE_B_NUMBER_FG = IupFlatButton( null );
		Ihandle* btnSCE_B_NUMBER_BG = IupFlatButton( null );
		IupSetAttribute( btnSCE_B_NUMBER_FG, "FGCOLOR", GLOBAL.editColor.SCE_B_NUMBER_Fore.toCString );
		IupSetAttribute( btnSCE_B_NUMBER_BG, "FGCOLOR", GLOBAL.editColor.SCE_B_NUMBER_Back.toCString );
		IupSetHandle( "btnSCE_B_NUMBER_FG", btnSCE_B_NUMBER_FG );
		IupSetHandle( "btnSCE_B_NUMBER_BG", btnSCE_B_NUMBER_BG );
		IupSetCallback( btnSCE_B_NUMBER_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnSCE_B_NUMBER_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttribute( btnSCE_B_NUMBER_FG, "SIZE", "16x8" );
		IupSetAttribute( btnSCE_B_NUMBER_BG, "SIZE", "16x8" );
		
		Ihandle* labelSCE_B_STRING = IupLabel( toStringz( GLOBAL.languageItems["SCE_B_STRING"].toDString ~ ":" ) );
		Ihandle* btnSCE_B_STRING_FG = IupFlatButton( null );
		Ihandle* btnSCE_B_STRING_BG = IupFlatButton( null );
		IupSetAttribute( btnSCE_B_STRING_FG, "FGCOLOR", GLOBAL.editColor.SCE_B_STRING_Fore.toCString );
		IupSetAttribute( btnSCE_B_STRING_BG, "FGCOLOR", GLOBAL.editColor.SCE_B_STRING_Back.toCString );
		IupSetHandle( "btnSCE_B_STRING_FG", btnSCE_B_STRING_FG );
		IupSetHandle( "btnSCE_B_STRING_BG", btnSCE_B_STRING_BG );
		IupSetCallback( btnSCE_B_STRING_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnSCE_B_STRING_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttribute( btnSCE_B_STRING_FG, "SIZE", "16x8" );
		IupSetAttribute( btnSCE_B_STRING_BG, "SIZE", "16x8" );
		
		Ihandle* labelSCE_B_PREPROCESSOR = IupLabel( toStringz( GLOBAL.languageItems["SCE_B_PREPROCESSOR"].toDString ~ ":" ) );
		Ihandle* btnSCE_B_PREPROCESSOR_FG = IupFlatButton( null );
		Ihandle* btnSCE_B_PREPROCESSOR_BG = IupFlatButton( null );
		IupSetAttribute( btnSCE_B_PREPROCESSOR_FG, "FGCOLOR", GLOBAL.editColor.SCE_B_PREPROCESSOR_Fore.toCString );
		IupSetAttribute( btnSCE_B_PREPROCESSOR_BG, "FGCOLOR", GLOBAL.editColor.SCE_B_PREPROCESSOR_Back.toCString );
		IupSetHandle( "btnSCE_B_PREPROCESSOR_FG", btnSCE_B_PREPROCESSOR_FG );
		IupSetHandle( "btnSCE_B_PREPROCESSOR_BG", btnSCE_B_PREPROCESSOR_BG );
		IupSetCallback( btnSCE_B_PREPROCESSOR_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnSCE_B_PREPROCESSOR_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttribute( btnSCE_B_PREPROCESSOR_FG, "SIZE", "16x8" );
		IupSetAttribute( btnSCE_B_PREPROCESSOR_BG, "SIZE", "16x8" );
		
		Ihandle* labelSCE_B_OPERATOR = IupLabel( toStringz( GLOBAL.languageItems["SCE_B_OPERATOR"].toDString ~ ":" ) );
		Ihandle* btnSCE_B_OPERATOR_FG = IupFlatButton( null );
		Ihandle* btnSCE_B_OPERATOR_BG = IupFlatButton( null );
		IupSetAttribute( btnSCE_B_OPERATOR_FG, "FGCOLOR", GLOBAL.editColor.SCE_B_OPERATOR_Fore.toCString );
		IupSetAttribute( btnSCE_B_OPERATOR_BG, "FGCOLOR", GLOBAL.editColor.SCE_B_OPERATOR_Back.toCString );
		IupSetHandle( "btnSCE_B_OPERATOR_FG", btnSCE_B_OPERATOR_FG );
		IupSetHandle( "btnSCE_B_OPERATOR_BG", btnSCE_B_OPERATOR_BG );
		IupSetCallback( btnSCE_B_OPERATOR_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnSCE_B_OPERATOR_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttribute( btnSCE_B_OPERATOR_FG, "SIZE", "16x8" );
		IupSetAttribute( btnSCE_B_OPERATOR_BG, "SIZE", "16x8" );
		
		Ihandle* labelSCE_B_IDENTIFIER = IupLabel( toStringz( GLOBAL.languageItems["SCE_B_IDENTIFIER"].toDString ~ ":" ) );
		Ihandle* btnSCE_B_IDENTIFIER_FG = IupFlatButton( null );
		Ihandle* btnSCE_B_IDENTIFIER_BG = IupFlatButton( null );
		IupSetAttribute( btnSCE_B_IDENTIFIER_FG, "FGCOLOR", GLOBAL.editColor.SCE_B_IDENTIFIER_Fore.toCString );
		IupSetAttribute( btnSCE_B_IDENTIFIER_BG, "FGCOLOR", GLOBAL.editColor.SCE_B_IDENTIFIER_Back.toCString );
		IupSetHandle( "btnSCE_B_IDENTIFIER_FG", btnSCE_B_IDENTIFIER_FG );
		IupSetHandle( "btnSCE_B_IDENTIFIER_BG", btnSCE_B_IDENTIFIER_BG );
		IupSetCallback( btnSCE_B_IDENTIFIER_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnSCE_B_IDENTIFIER_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttribute( btnSCE_B_IDENTIFIER_FG, "SIZE", "16x8" );
		IupSetAttribute( btnSCE_B_IDENTIFIER_BG, "SIZE", "16x8" );
		
		Ihandle* labelSCE_B_COMMENTBLOCK = IupLabel( toStringz( GLOBAL.languageItems["SCE_B_COMMENTBLOCK"].toDString ~ ":" ) );
		Ihandle* btnSCE_B_COMMENTBLOCK_FG = IupFlatButton( null );
		Ihandle* btnSCE_B_COMMENTBLOCK_BG = IupFlatButton( null );
		IupSetAttribute( btnSCE_B_COMMENTBLOCK_FG, "FGCOLOR", GLOBAL.editColor.SCE_B_COMMENTBLOCK_Fore.toCString );
		IupSetAttribute( btnSCE_B_COMMENTBLOCK_BG, "FGCOLOR", GLOBAL.editColor.SCE_B_COMMENTBLOCK_Back.toCString );	
		IupSetHandle( "btnSCE_B_COMMENTBLOCK_FG", btnSCE_B_COMMENTBLOCK_FG );
		IupSetHandle( "btnSCE_B_COMMENTBLOCK_BG", btnSCE_B_COMMENTBLOCK_BG );
		IupSetCallback( btnSCE_B_COMMENTBLOCK_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnSCE_B_COMMENTBLOCK_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttribute( btnSCE_B_COMMENTBLOCK_FG, "SIZE", "16x8" );
		IupSetAttribute( btnSCE_B_COMMENTBLOCK_BG, "SIZE", "16x8" );
		
		
		Ihandle* labelPrj = IupLabel( toStringz( GLOBAL.languageItems["caption_prj"].toDString ~ ":" ) );
		//IupSetAttribute( labelPrj, "SIZE", toStringz("100x") );
		Ihandle* btnPrj_FG = IupFlatButton( null );
		Ihandle* btnPrj_BG = IupFlatButton( null );
		IupSetAttribute( btnPrj_FG, "FGCOLOR", GLOBAL.editColor.projectFore.toCString );
		IupSetAttribute( btnPrj_BG, "FGCOLOR", GLOBAL.editColor.projectBack.toCString );	
		IupSetHandle( "btnPrj_FG", btnPrj_FG );
		IupSetHandle( "btnPrj_BG", btnPrj_BG );
		IupSetCallback( btnPrj_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnPrj_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttribute( btnPrj_FG, "SIZE", "16x8" );
		IupSetAttribute( btnPrj_BG, "SIZE", "16x8" );
		
		Ihandle* labelOutline = IupLabel( toStringz( GLOBAL.languageItems["outline"].toDString ~ ":" ) );
		Ihandle* btnOutline_FG = IupFlatButton( null );
		Ihandle* btnOutline_BG = IupFlatButton( null );
		IupSetAttribute( btnOutline_FG, "FGCOLOR", GLOBAL.editColor.outlineFore.toCString );
		IupSetAttribute( btnOutline_BG, "FGCOLOR", GLOBAL.editColor.outlineBack.toCString );	
		IupSetHandle( "btnOutline_FG", btnOutline_FG );
		IupSetHandle( "btnOutline_BG", btnOutline_BG );
		IupSetCallback( btnOutline_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnOutline_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttribute( btnOutline_FG, "SIZE", "16x8" );
		IupSetAttribute( btnOutline_BG, "SIZE", "16x8" );
		
		Ihandle* labelFilelist= IupLabel( toStringz( GLOBAL.languageItems["filelist"].toDString ~ ":" ) );
		Ihandle* btnFilelist_FG = IupFlatButton( null );
		Ihandle* btnFilelist_BG = IupFlatButton( null );
		IupSetAttribute( btnFilelist_FG, "FGCOLOR", GLOBAL.editColor.filelistFore.toCString );
		IupSetAttribute( btnFilelist_BG, "FGCOLOR", GLOBAL.editColor.filelistBack.toCString );	
		IupSetHandle( "btnFilelist_FG", btnFilelist_FG );
		IupSetHandle( "btnFilelist_BG", btnFilelist_BG );
		IupSetCallback( btnFilelist_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnFilelist_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttribute( btnFilelist_FG, "SIZE", "16x8" );
		IupSetAttribute( btnFilelist_BG, "SIZE", "16x8" );
		
		Ihandle* labelOutput= IupLabel( toStringz( GLOBAL.languageItems["output"].toDString ~ ":" ) );
		Ihandle* btnOutput_FG = IupFlatButton( null );
		Ihandle* btnOutput_BG = IupFlatButton( null );
		IupSetAttribute( btnOutput_FG, "FGCOLOR", GLOBAL.editColor.outputFore.toCString );
		IupSetAttribute( btnOutput_BG, "FGCOLOR", GLOBAL.editColor.outputBack.toCString );	
		IupSetHandle( "btnOutput_FG", btnOutput_FG );
		IupSetHandle( "btnOutput_BG", btnOutput_BG );
		IupSetCallback( btnOutput_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnOutput_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttribute( btnOutput_FG, "SIZE", "16x8" );
		IupSetAttribute( btnOutput_BG, "SIZE", "16x8" );
		
		Ihandle* labelSearch= IupLabel( toStringz( GLOBAL.languageItems["caption_search"].toDString ~ ":" ) );
		Ihandle* btnSearch_FG = IupFlatButton( null );
		Ihandle* btnSearch_BG = IupFlatButton( null );
		IupSetAttribute( btnSearch_FG, "FGCOLOR", GLOBAL.editColor.searchFore.toCString );
		IupSetAttribute( btnSearch_BG, "FGCOLOR", GLOBAL.editColor.searchBack.toCString );	
		IupSetHandle( "btnSearch_FG", btnSearch_FG );
		IupSetHandle( "btnSearch_BG", btnSearch_BG );
		IupSetCallback( btnSearch_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnSearch_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttribute( btnSearch_FG, "SIZE", "16x8" );
		IupSetAttribute( btnSearch_BG, "SIZE", "16x8" );
		
		Ihandle* labelError= IupLabel( toStringz( GLOBAL.languageItems["manualerrorannotation"].toDString ~ ":" ) );
		Ihandle* btnError_FG = IupFlatButton( null );
		Ihandle* btnError_BG = IupFlatButton( null );
		IupSetAttribute( btnError_FG, "FGCOLOR", GLOBAL.editColor.errorFore.toCString );
		IupSetAttribute( btnError_BG, "FGCOLOR", GLOBAL.editColor.errorBack.toCString );	
		IupSetHandle( "btnError_FG", btnError_FG );
		IupSetHandle( "btnError_BG", btnError_BG );
		IupSetCallback( btnError_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnError_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttribute( btnError_FG, "SIZE", "16x8" );
		IupSetAttribute( btnError_BG, "SIZE", "16x8" );
		
		Ihandle* labelWarning= IupLabel( toStringz( GLOBAL.languageItems["manualwarningannotation"].toDString ~ ":" ) );
		Ihandle* btnWarning_FG = IupFlatButton( null );
		Ihandle* btnWarning_BG = IupFlatButton( null );
		IupSetAttribute( btnWarning_FG, "FGCOLOR", GLOBAL.editColor.warningFore.toCString );
		IupSetAttribute( btnWarning_BG, "FGCOLOR", GLOBAL.editColor.warringBack.toCString );	
		IupSetHandle( "btnWarning_FG", btnWarning_FG );
		IupSetHandle( "btnWarning_BG", btnWarning_BG );
		IupSetCallback( btnWarning_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnWarning_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttribute( btnWarning_FG, "SIZE", "16x8" );
		IupSetAttribute( btnWarning_BG, "SIZE", "16x8" );
		
		Ihandle* labelBrace= IupLabel( toStringz( GLOBAL.languageItems["bracehighlight"].toDString ~ ":" ) );
		Ihandle* btnBrace_FG = IupFlatButton( null );
		Ihandle* btnBrace_BG = IupFlatButton( null );
		IupSetAttribute( btnBrace_FG, "FGCOLOR", GLOBAL.editColor.braceFore.toCString );
		IupSetAttribute( btnBrace_BG, "FGCOLOR", GLOBAL.editColor.braceBack.toCString );	
		IupSetHandle( "btnBrace_FG", btnBrace_FG );
		IupSetHandle( "btnBrace_BG", btnBrace_BG );
		IupSetCallback( btnBrace_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnBrace_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttribute( btnBrace_FG, "SIZE", "16x8" );
		IupSetAttribute( btnBrace_BG, "SIZE", "16x8" );
		
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
		version(Windows) IupSetAttributes( gboxColor_1, "SIZELIN =-1,NUMDIV=7,ALIGNMENTLIN=ACENTER,ALIGNMENTCOL=ALEFT,GAPLIN=8,GAPCOL=5,MARGIN=2x8,EXPANDCHILDREN=HORIZONTAL" ); else IupSetAttributes( gboxColor_1, "SIZELIN =-1,NUMDIV=7,ALIGNMENTLIN=ACENTER,ALIGNMENTCOL=ALEFT,GAPLIN=10,GAPCOL=5,MARGIN=2x8,EXPANDCHILDREN=HORIZONTAL" );

		
		Ihandle* frameColor_1 = IupFrame( gboxColor_1 );
		IupSetAttributes( frameColor_1, "MARGIN=0x0,EXPAND=YES,EXPAND=HORIZONTAL" );
		//IupSetAttribute( frameColor_1, "SIZE", "288x" );//IupGetAttribute( frameFont, "SIZE" ) );
		IupSetAttribute( frameColor_1, "TITLE", GLOBAL.languageItems["colorfgbg"].toCString );
		
		
		
		// Mark High Light Line
		Ihandle* labelMarker0 = IupLabel( toStringz( GLOBAL.languageItems["maker0"].toDString ~ ": " ) );
		IupSetAttribute( labelMarker0, "ALIGNMENT", "ARIGHT" );
		Ihandle* btnMarker0Color = IupFlatButton(  null );
		IupSetAttribute( btnMarker0Color, "FGCOLOR",GLOBAL.editColor.maker[0].toCString );
		IupSetAttribute( btnMarker0Color, "SIZE", "24x8" );
		IupSetHandle( "btnMarker0Color", btnMarker0Color );
		IupSetCallback( btnMarker0Color, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		
		Ihandle* labelMarker1 = IupLabel( toStringz( GLOBAL.languageItems["maker1"].toDString ~ ": " ) );
		IupSetAttribute( labelMarker1, "ALIGNMENT", "ARIGHT" );
		Ihandle* btnMarker1Color = IupFlatButton( null );
		IupSetAttribute( btnMarker1Color, "FGCOLOR",GLOBAL.editColor.maker[1].toCString );
		IupSetAttribute( btnMarker1Color, "SIZE", "24x8" );
		IupSetHandle( "btnMarker1Color", btnMarker1Color );
		IupSetCallback( btnMarker1Color, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelMarker2 = IupLabel( toStringz( GLOBAL.languageItems["maker2"].toDString ~ ": " ) );
		IupSetAttribute( labelMarker2, "ALIGNMENT", "ARIGHT" );
		Ihandle* btnMarker2Color = IupFlatButton( null );
		IupSetAttribute( btnMarker2Color, "FGCOLOR",GLOBAL.editColor.maker[2].toCString );
		IupSetAttribute( btnMarker2Color, "SIZE", "24x8" );
		IupSetHandle( "btnMarker2Color", btnMarker2Color );
		IupSetCallback( btnMarker2Color, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelMarker3 = IupLabel( toStringz( GLOBAL.languageItems["maker3"].toDString ~ ": " ) );
		IupSetAttribute( labelMarker3, "ALIGNMENT", "ARIGHT" );
		Ihandle* btnMarker3Color = IupFlatButton( null );
		IupSetAttribute( btnMarker3Color, "FGCOLOR",GLOBAL.editColor.maker[3].toCString );
		IupSetAttribute( btnMarker3Color, "SIZE", "24x8" );
		IupSetHandle( "btnMarker3Color", btnMarker3Color );
		IupSetCallback( btnMarker3Color, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		
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
		IupSetAttributes( gboxMarkerColor, "SIZELIN=-1,NUMDIV=8,ALIGNMENTLIN=ACENTER,ALIGNMENTCOL=ALEFT,GAPLIN=5,GAPCOL=5,MARGIN=2x8,EXPANDCHILDREN=HORIZONTAL" );
		
		Ihandle* frameColor_2 = IupFrame( gboxMarkerColor );
		IupSetAttributes( frameColor_2, "MARGIN=0x0,EXPAND=YES,EXPAND=HORIZONTAL" );
		
		/+
		Ihandle* labelKeyWord0 = IupLabel( "#0:" );
		IupSetAttribute( labelKeyWord0, "ALIGNMENT", "ARIGHT" );
		Ihandle* btnKeyWord0Color = IupFlatButton( null );
		IupSetAttribute( btnKeyWord0Color, "FGCOLOR", GLOBAL.editColor.keyWord[0].toCString );
		version(Windows) IupSetAttribute( btnKeyWord0Color, "SIZE", "24x8" ); else IupSetAttribute( btnKeyWord0Color, "SIZE", "24x10" );
		IupSetHandle( "btnKeyWord0Color", btnKeyWord0Color );
		IupSetCallback( btnKeyWord0Color, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelKeyWord1 = IupLabel( "#1:" );
		IupSetAttribute( labelKeyWord1, "ALIGNMENT", "ARIGHT" );
		Ihandle* btnKeyWord1Color = IupFlatButton( null );
		IupSetAttribute( btnKeyWord1Color, "FGCOLOR", GLOBAL.editColor.keyWord[1].toCString );
		version(Windows) IupSetAttribute( btnKeyWord1Color, "SIZE", "24x8" ); else IupSetAttribute( btnKeyWord1Color, "SIZE", "24x10" );
		IupSetHandle( "btnKeyWord1Color", btnKeyWord1Color );
		IupSetCallback( btnKeyWord1Color, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelKeyWord2 = IupLabel( "#2:" );
		IupSetAttribute( labelKeyWord2, "ALIGNMENT", "ARIGHT" );
		Ihandle* btnKeyWord2Color = IupFlatButton( null );
		IupSetAttribute( btnKeyWord2Color, "FGCOLOR", GLOBAL.editColor.keyWord[2].toCString );
		version(Windows) IupSetAttribute( btnKeyWord2Color, "SIZE", "24x8" ); else IupSetAttribute( btnKeyWord2Color, "SIZE", "24x10" );
		IupSetHandle( "btnKeyWord2Color", btnKeyWord2Color );
		IupSetCallback( btnKeyWord2Color, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelKeyWord3 = IupLabel( "#3:" );
		IupSetAttribute( labelKeyWord3, "ALIGNMENT", "ARIGHT" );
		Ihandle* btnKeyWord3Color = IupFlatButton( null );
		IupSetAttribute( btnKeyWord3Color, "FGCOLOR",GLOBAL.editColor.keyWord[3].toCString );
		version(Windows) IupSetAttribute( btnKeyWord3Color, "SIZE", "24x8" ); else IupSetAttribute( btnKeyWord3Color, "SIZE", "24x10" );
		IupSetHandle( "btnKeyWord3Color", btnKeyWord3Color );
		IupSetCallback( btnKeyWord3Color, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelKeyWord4 = IupLabel( "#4:" );
		IupSetAttribute( labelKeyWord4, "ALIGNMENT", "ARIGHT" );
		Ihandle* btnKeyWord4Color = IupFlatButton( null );
		IupSetAttribute( btnKeyWord4Color, "FGCOLOR",GLOBAL.editColor.keyWord[4].toCString );
		version(Windows) IupSetAttribute( btnKeyWord4Color, "SIZE", "24x8" ); else IupSetAttribute( btnKeyWord4Color, "SIZE", "24x10" );
		IupSetHandle( "btnKeyWord4Color", btnKeyWord4Color );
		IupSetCallback( btnKeyWord4Color, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelKeyWord5 = IupLabel( "#5:" );//GLOBAL.languageItems["keyword5"].toCString() );
		IupSetAttribute( labelKeyWord5, "ALIGNMENT", "ARIGHT" );
		Ihandle* btnKeyWord5Color = IupFlatButton( null );
		IupSetAttribute( btnKeyWord5Color, "FGCOLOR",GLOBAL.editColor.keyWord[5].toCString );
		version(Windows) IupSetAttribute( btnKeyWord5Color, "SIZE", "24x8" ); else IupSetAttribute( btnKeyWord5Color, "SIZE", "24x10" );
		IupSetHandle( "btnKeyWord5Color", btnKeyWord5Color );
		IupSetCallback( btnKeyWord5Color, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );



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
			
			labelKeyWord4,
			btnKeyWord4Color,
			labelKeyWord5,
			btnKeyWord5Color,
			

			null
		);
		IupSetAttributes( gboxKeyWordColor, "SIZELIN=-1,NUMDIV=12,ALIGNMENTLIN=ACENTER,ALIGNMENTCOL=ALEFT,GAPLIN=5,GAPCOL=5,MARGIN=2x8,EXPANDCHILDREN=HORIZONTAL" );
		Ihandle* frameKeywordColor = IupFrame( gboxKeyWordColor );
		IupSetAttributes( frameKeywordColor, "MARGIN=0x0" );
		IupSetAttribute( frameKeywordColor, "TITLE", GLOBAL.languageItems["keywords"].toCString );		
		+/
		
		/*
		Ihandle* vBoxPage02 = IupVbox( gbox, frameKeywordCase, frameFont, frameColor, null );
		IupSetAttributes( vBoxPage02, "GAP=5,MARGIN=0x1,EXPANDCHILDREN=YES" );
		*/
		Ihandle* vColor = IupVbox( colorTemplateFrame, frameColor, frameColor_1, frameColor_2, /*frameKeywordColor,*/ null );
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
			IupSetAttribute( shortCutList, "FONT", "Monospace, 9" );
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
					if( PreferenceDialogParameters.stringSC[ID-1] is null ) PreferenceDialogParameters.stringSC[ID-1] = new IupString( "[" ~ GLOBAL.languageItems["file"].toDString ~ "]" );
					IupSetAttributeId( shortCutList, "", ID, PreferenceDialogParameters.stringSC[ID-1].toCString ); 
					IupSetAttributeId( shortCutList, "IMAGE", ID, "icon_prj_open" ); 
					ID++;
					break;
				case 6:
					if( PreferenceDialogParameters.stringSC[ID-1] is null ) PreferenceDialogParameters.stringSC[ID-1] = new IupString( "[" ~ GLOBAL.languageItems["edit"].toDString ~ "]" );
					IupSetAttributeId( shortCutList, "", ID, PreferenceDialogParameters.stringSC[ID-1].toCString );
					IupSetAttributeId( shortCutList, "IMAGE", ID, "icon_search" ); 
					ID++;
					break;
				case 20:
					if( PreferenceDialogParameters.stringSC[ID-1] is null ) PreferenceDialogParameters.stringSC[ID-1] = new IupString( "[" ~ GLOBAL.languageItems["parser"].toDString ~ "]" );
					IupSetAttributeId( shortCutList, "", ID, PreferenceDialogParameters.stringSC[ID-1].toCString );
					IupSetAttributeId( shortCutList, "IMAGE", ID, "icon_refresh" ); 
					ID++;
					break;
				case 25:
					if( PreferenceDialogParameters.stringSC[ID-1] is null ) PreferenceDialogParameters.stringSC[ID-1] = new IupString( "[" ~ GLOBAL.languageItems["build"].toDString ~ "]" );
					IupSetAttributeId( shortCutList, "", ID, PreferenceDialogParameters.stringSC[ID-1].toCString );
					IupSetAttributeId( shortCutList, "IMAGE", ID, "icon_compile" );
					ID++;
					break;
				case 29:
					if( PreferenceDialogParameters.stringSC[ID-1] is null ) PreferenceDialogParameters.stringSC[ID-1] = new IupString( "[" ~ GLOBAL.languageItems["windows"].toDString ~ "]" );
					IupSetAttributeId( shortCutList, "", ID, PreferenceDialogParameters.stringSC[ID-1].toCString );
					IupSetAttributeId( shortCutList, "IMAGE", ID, "icon_gui" );
					ID++;
					break;
				case 31:
					if( PreferenceDialogParameters.stringSC[ID-1] is null ) PreferenceDialogParameters.stringSC[ID-1] = new IupString( "[" ~ GLOBAL.languageItems["setcustomtool"].toDString ~ "]" );
					IupSetAttributeId( shortCutList, "", ID, PreferenceDialogParameters.stringSC[ID-1].toCString );
					IupSetAttributeId( shortCutList, "IMAGE", ID, "icon_toolitem" );
					ID++;
					break;
				default:
			}
			
			char[] keyValue = IDECONFIG.convertShortKeyValue2String( GLOBAL.shortKeys[i].keyValue );
			char[][] splitWord = Util.split( keyValue, "+" );

			if( splitWord.length == 4 ) 
			{
				if( splitWord[0] == "C" )  splitWord[0] = "Ctrl";
				if( splitWord[1] == "S" )  splitWord[1] = "Shift";
				if( splitWord[2] == "A" )  splitWord[2] = "Alt";
			}
			
			if( PreferenceDialogParameters.stringSC[ID-1] is null ) PreferenceDialogParameters.stringSC[ID-1] = new IupString( Stdout.layout.convert( " {,-5} + {,-5} + {,-5} + {,-5} {,-40}", splitWord[0], splitWord[1], splitWord[2], splitWord[3], GLOBAL.shortKeys[i].title ) );
			IupSetAttributeId( shortCutList, "",  ID, PreferenceDialogParameters.stringSC[ID-1].toCString );
			
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
		Ihandle* keyWordText4 = IupText( null );
		IupSetAttributes( keyWordText4, "MULTILINE=YES,EXPAND=YES,WORDWRAP=YES,AUTOHIDE=YES,SCROLLBAR=YES,PADDING=2x2" );
		IupSetAttribute( keyWordText4, "VALUE", GLOBAL.KEYWORDS[4].toCString );
		IupSetHandle( "keyWordText4", keyWordText4 );
		Ihandle* keyWordText5 = IupText( null );
		IupSetAttributes( keyWordText5, "MULTILINE=YES,EXPAND=YES,WORDWRAP=YES,AUTOHIDE=YES,SCROLLBAR=YES,PADDING=2x2" );
		IupSetAttribute( keyWordText5, "VALUE", GLOBAL.KEYWORDS[5].toCString );
		IupSetHandle( "keyWordText5", keyWordText5 );
		
		
		
		Ihandle* btnKeyWord0Color = IupFlatButton( null );
		IupSetAttribute( btnKeyWord0Color, "FGCOLOR", GLOBAL.editColor.keyWord[0].toCString );
		IupSetAttribute( btnKeyWord0Color, "SIZE", "36x8" );
		IupSetHandle( "btnKeyWord0Color", btnKeyWord0Color );
		IupSetCallback( btnKeyWord0Color, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* btnKeyWord1Color = IupFlatButton( null );
		IupSetAttribute( btnKeyWord1Color, "FGCOLOR", GLOBAL.editColor.keyWord[1].toCString );
		IupSetAttribute( btnKeyWord1Color, "SIZE", "36x8" );
		IupSetHandle( "btnKeyWord1Color", btnKeyWord1Color );
		IupSetCallback( btnKeyWord1Color, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* btnKeyWord2Color = IupFlatButton( null );
		IupSetAttribute( btnKeyWord2Color, "FGCOLOR", GLOBAL.editColor.keyWord[2].toCString );
		IupSetAttribute( btnKeyWord2Color, "SIZE", "36x8" );
		IupSetHandle( "btnKeyWord2Color", btnKeyWord2Color );
		IupSetCallback( btnKeyWord2Color, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* btnKeyWord3Color = IupFlatButton( null );
		IupSetAttribute( btnKeyWord3Color, "FGCOLOR",GLOBAL.editColor.keyWord[3].toCString );
		IupSetAttribute( btnKeyWord3Color, "SIZE", "36x8" );
		IupSetHandle( "btnKeyWord3Color", btnKeyWord3Color );
		IupSetCallback( btnKeyWord3Color, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* btnKeyWord4Color = IupFlatButton( null );
		IupSetAttribute( btnKeyWord4Color, "FGCOLOR",GLOBAL.editColor.keyWord[4].toCString );
		IupSetAttribute( btnKeyWord4Color, "SIZE", "36x8" );
		IupSetHandle( "btnKeyWord4Color", btnKeyWord4Color );
		IupSetCallback( btnKeyWord4Color, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* btnKeyWord5Color = IupFlatButton( null );
		IupSetAttribute( btnKeyWord5Color, "FGCOLOR",GLOBAL.editColor.keyWord[5].toCString );
		IupSetAttribute( btnKeyWord5Color, "SIZE", "36x8" );
		IupSetHandle( "btnKeyWord5Color", btnKeyWord5Color );
		IupSetCallback( btnKeyWord5Color, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		
		
		
		Ihandle* vBoxKeyWord0 = IupVbox( btnKeyWord0Color, keyWordText0, null );
		IupSetAttribute( vBoxKeyWord0, "TABTITLE", GLOBAL.languageItems["keyword0"].toCString() );
		IupSetAttribute( vBoxKeyWord0, "MARGIN", "0" );

		Ihandle* vBoxKeyWord1 = IupVbox( btnKeyWord1Color, keyWordText1, null );
		IupSetAttribute( vBoxKeyWord1, "TABTITLE", GLOBAL.languageItems["keyword1"].toCString() );
		IupSetAttribute( vBoxKeyWord1, "MARGIN", "0" );

		Ihandle* vBoxKeyWord2 = IupVbox( btnKeyWord2Color, keyWordText2, null );
		IupSetAttribute( vBoxKeyWord2, "TABTITLE", GLOBAL.languageItems["keyword2"].toCString() );
		IupSetAttribute( vBoxKeyWord2, "MARGIN", "0" );

		Ihandle* vBoxKeyWord3 = IupVbox( btnKeyWord3Color, keyWordText3, null );
		IupSetAttribute( vBoxKeyWord3, "TABTITLE", GLOBAL.languageItems["keyword3"].toCString() );
		IupSetAttribute( vBoxKeyWord3, "MARGIN", "0" );

		Ihandle* vBoxKeyWord4 = IupVbox( btnKeyWord4Color, keyWordText4, null );
		IupSetAttribute( vBoxKeyWord4, "TABTITLE", GLOBAL.languageItems["keyword4"].toCString() );
		IupSetAttribute( vBoxKeyWord4, "MARGIN", "0" );

		Ihandle* vBoxKeyWord5 = IupVbox( btnKeyWord5Color, keyWordText5, null );
		IupSetAttribute( vBoxKeyWord5, "TABTITLE", GLOBAL.languageItems["keyword5"].toCString() );
		IupSetAttribute( vBoxKeyWord5, "MARGIN", "0" );

		Ihandle* keywordTabs = IupTabs( vBoxKeyWord0, vBoxKeyWord1, vBoxKeyWord2, vBoxKeyWord3, vBoxKeyWord4, vBoxKeyWord5, null );
		/*
		IupSetAttribute( keyWordText0, "TABTITLE", GLOBAL.languageItems["keyword0"].toCString() );
		IupSetAttribute( keyWordText1, "TABTITLE", GLOBAL.languageItems["keyword1"].toCString() );
		IupSetAttribute( keyWordText2, "TABTITLE", GLOBAL.languageItems["keyword2"].toCString() );
		IupSetAttribute( keyWordText3, "TABTITLE", GLOBAL.languageItems["keyword3"].toCString() );
		IupSetAttribute( keyWordText4, "TABTITLE", GLOBAL.languageItems["keyword4"].toCString() );
		IupSetAttribute( keyWordText5, "TABTITLE", GLOBAL.languageItems["keyword5"].toCString() );
		Ihandle* keywordTabs = IupTabs( vBoxKeyWord0, keyWordText1, keyWordText2, keyWordText3, keyWordText4, keyWordText5, null );
		*/
		IupSetAttribute( keywordTabs, "TABTYPE", "TOP" );
		IupSetAttribute( keywordTabs, "EXPAND", "YES" );
		IupSetAttribute( keywordTabs, "CHILDOFFSET", "0x0" );
		
		 
		
		
		
		




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
	
	void saveColorTemplateINI( char[] templateName )
	{
		char[] templatePath = "settings/colorTemplates";

		if( GLOBAL.linuxHome.length ) templatePath = GLOBAL.linuxHome ~ "/" ~ templatePath; // version(Windows) GLOBAL.linuxHome = null
		
		scope _fp = new FilePath( templatePath );
		if( !_fp.exists() )	_fp.create();
		

		char[] doc = "[color]\n";
			
		// Editor
		doc ~= setINILineData( "caretLine", fromStringz( IupGetAttribute( IupGetHandle( "btnCaretLine" ), "FGCOLOR" ) ).dup );
		doc ~= setINILineData( "cursor", fromStringz( IupGetAttribute( IupGetHandle( "btnCursor" ), "FGCOLOR" ) ).dup );
		doc ~= setINILineData( "selectionFore", fromStringz( IupGetAttribute( IupGetHandle( "btnSelectFore" ), "FGCOLOR" ) ).dup );
		doc ~= setINILineData( "selectionBack", fromStringz( IupGetAttribute( IupGetHandle( "btnSelectBack" ), "FGCOLOR" ) ).dup );
		doc ~= setINILineData( "linenumFore", fromStringz( IupGetAttribute( IupGetHandle( "btnLinenumFore" ), "FGCOLOR" ) ).dup );
		doc ~= setINILineData( "linenumBack", fromStringz( IupGetAttribute( IupGetHandle( "btnLinenumBack" ), "FGCOLOR" ) ).dup );
		doc ~= setINILineData( "fold", fromStringz( IupGetAttribute( IupGetHandle( "btnFoldingColor" ), "FGCOLOR" ) ).dup );
		
		doc ~= setINILineData( "selAlpha", fromStringz( IupGetAttribute( IupGetHandle( "textAlpha" ), "VALUE" ) ).dup );
		doc ~= setINILineData( "braceFore", fromStringz( IupGetAttribute( IupGetHandle( "btnBrace_FG" ), "FGCOLOR" ) ).dup );
		doc ~= setINILineData( "braceBack", fromStringz( IupGetAttribute( IupGetHandle( "btnBrace_BG" ), "FGCOLOR" ) ).dup );
		doc ~= setINILineData( "errorFore", fromStringz( IupGetAttribute( IupGetHandle( "btnError_FG" ), "FGCOLOR" ) ).dup );
		doc ~= setINILineData( "errorBack", fromStringz( IupGetAttribute( IupGetHandle( "btnError_BG" ), "FGCOLOR" ) ).dup );
		doc ~= setINILineData( "warningFore", fromStringz( IupGetAttribute( IupGetHandle( "btnWarning_FG" ), "FGCOLOR" ) ).dup );
		doc ~= setINILineData( "warningBack", fromStringz( IupGetAttribute( IupGetHandle( "btnWarning_BG" ), "FGCOLOR" ) ).dup );
		
		doc ~= setINILineData( "scintillaFore", fromStringz( IupGetAttribute( IupGetHandle( "btn_Scintilla_FG" ), "FGCOLOR" ) ).dup );
		doc ~= setINILineData( "scintillaBack", fromStringz( IupGetAttribute( IupGetHandle( "btn_Scintilla_BG" ), "FGCOLOR" ) ).dup );
		
		doc ~= setINILineData( "SCE_B_COMMENT_Fore", fromStringz( IupGetAttribute( IupGetHandle( "btnSCE_B_COMMENT_FG" ), "FGCOLOR" ) ).dup );
		doc ~= setINILineData( "SCE_B_COMMENT_Back", fromStringz( IupGetAttribute( IupGetHandle( "btnSCE_B_COMMENT_BG" ), "FGCOLOR" ) ).dup );
		doc ~= setINILineData( "SCE_B_NUMBER_Fore", fromStringz( IupGetAttribute( IupGetHandle( "btnSCE_B_NUMBER_FG" ), "FGCOLOR" ) ).dup );
		doc ~= setINILineData( "SCE_B_NUMBER_Back", fromStringz( IupGetAttribute( IupGetHandle( "btnSCE_B_NUMBER_BG" ), "FGCOLOR" ) ).dup );
		doc ~= setINILineData( "SCE_B_STRING_Fore", fromStringz( IupGetAttribute( IupGetHandle( "btnSCE_B_STRING_FG" ), "FGCOLOR" ) ).dup );
		doc ~= setINILineData( "SCE_B_STRING_Back", fromStringz( IupGetAttribute( IupGetHandle( "btnSCE_B_STRING_BG" ), "FGCOLOR" ) ).dup );
		doc ~= setINILineData( "SCE_B_PREPROCESSOR_Fore", fromStringz( IupGetAttribute( IupGetHandle( "btnSCE_B_PREPROCESSOR_FG" ), "FGCOLOR" ) ).dup );
		doc ~= setINILineData( "SCE_B_PREPROCESSOR_Back", fromStringz( IupGetAttribute( IupGetHandle( "btnSCE_B_PREPROCESSOR_BG" ), "FGCOLOR" ) ).dup );
		doc ~= setINILineData( "SCE_B_OPERATOR_Fore", fromStringz( IupGetAttribute( IupGetHandle( "btnSCE_B_OPERATOR_FG" ), "FGCOLOR" ) ).dup );
		doc ~= setINILineData( "SCE_B_OPERATOR_Back", fromStringz( IupGetAttribute( IupGetHandle( "btnSCE_B_OPERATOR_BG" ), "FGCOLOR" ) ).dup );
		doc ~= setINILineData( "SCE_B_IDENTIFIER_Fore", fromStringz( IupGetAttribute( IupGetHandle( "btnSCE_B_IDENTIFIER_FG" ), "FGCOLOR" ) ).dup );
		doc ~= setINILineData( "SCE_B_IDENTIFIER_Back", fromStringz( IupGetAttribute( IupGetHandle( "btnSCE_B_IDENTIFIER_BG" ), "FGCOLOR" ) ).dup );
		doc ~= setINILineData( "SCE_B_COMMENTBLOCK_Fore", fromStringz( IupGetAttribute( IupGetHandle( "btnSCE_B_COMMENTBLOCK_FG" ), "FGCOLOR" ) ).dup );
		doc ~= setINILineData( "SCE_B_COMMENTBLOCK_Back", fromStringz( IupGetAttribute( IupGetHandle( "btnSCE_B_COMMENTBLOCK_BG" ), "FGCOLOR" ) ).dup );
		
		doc ~= setINILineData( "projectFore", fromStringz( IupGetAttribute( IupGetHandle( "btnPrj_FG" ), "FGCOLOR" ) ).dup );
		doc ~= setINILineData( "projectBack", fromStringz( IupGetAttribute( IupGetHandle( "btnPrj_BG" ), "FGCOLOR" ) ).dup );
		doc ~= setINILineData( "outlineFore", fromStringz( IupGetAttribute( IupGetHandle( "btnOutline_FG" ), "FGCOLOR" ) ).dup );
		doc ~= setINILineData( "outlineBack", fromStringz( IupGetAttribute( IupGetHandle( "btnOutline_BG" ), "FGCOLOR" ) ).dup );
		doc ~= setINILineData( "filelistFore", fromStringz( IupGetAttribute( IupGetHandle( "btnFilelist_FG" ), "FGCOLOR" ) ).dup );
		doc ~= setINILineData( "filelistBack", fromStringz( IupGetAttribute( IupGetHandle( "btnFilelist_BG" ), "FGCOLOR" ) ).dup );
		doc ~= setINILineData( "outputFore", fromStringz( IupGetAttribute( IupGetHandle( "btnOutput_FG" ), "FGCOLOR" ) ).dup );
		doc ~= setINILineData( "outputBack", fromStringz( IupGetAttribute( IupGetHandle( "btnOutput_BG" ), "FGCOLOR" ) ).dup );
		doc ~= setINILineData( "searchFore", fromStringz( IupGetAttribute( IupGetHandle( "btnSearch_FG" ), "FGCOLOR" ) ).dup );
		doc ~= setINILineData( "searchBack", fromStringz( IupGetAttribute( IupGetHandle( "btnSearch_BG" ), "FGCOLOR" ) ).dup );
		
		doc ~= setINILineData( "prjTitle", fromStringz( IupGetAttribute( IupGetHandle( "btnPrjTitle" ), "FGCOLOR" ) ).dup );
		doc ~= setINILineData( "prjSourceType", fromStringz( IupGetAttribute( IupGetHandle( "btnSourceTypeFolder" ), "FGCOLOR" ) ).dup );
		doc ~= setINILineData( "keyword0", fromStringz( IupGetAttribute( IupGetHandle( "btnKeyWord0Color" ), "FGCOLOR" ) ).dup );
		doc ~= setINILineData( "keyword1", fromStringz( IupGetAttribute( IupGetHandle( "btnKeyWord1Color" ), "FGCOLOR" ) ).dup );
		doc ~= setINILineData( "keyword2", fromStringz( IupGetAttribute( IupGetHandle( "btnKeyWord2Color" ), "FGCOLOR" ) ).dup );
		doc ~= setINILineData( "keyword3", fromStringz( IupGetAttribute( IupGetHandle( "btnKeyWord3Color" ), "FGCOLOR" ) ).dup );
		doc ~= setINILineData( "currentword", fromStringz( IupGetAttribute( IupGetHandle( "btnIndicator" ), "FGCOLOR" ) ).dup );
		doc ~= setINILineData( "currentwordAlpha", fromStringz( IupGetAttribute( IupGetHandle( "textIndicatorAlpha" ), "VALUE" ) ).dup );
		doc ~= setINILineData( "keyword4", fromStringz( IupGetAttribute( IupGetHandle( "btnKeyWord4Color" ), "FGCOLOR" ) ).dup );
		doc ~= setINILineData( "keyword5", fromStringz( IupGetAttribute( IupGetHandle( "btnKeyWord5Color" ), "FGCOLOR" ) ).dup );
		
		
		if( !actionManager.FileAction.saveFile( templatePath ~ "/" ~ templateName ~ ".ini", doc ) ) throw new Exception( "Save File Error" );
	}	

	public:
	this( int w, int h, char[] title, bool bResize = true, char[] parent = "POSEIDON_MAIN_DIALOG" )
	{
		super( w, h, title, bResize, parent );
		IupSetAttribute( _dlg, "MINBOX", "NO" );
		IupSetAttribute( _dlg, "ICON", "icon_preference" );
		version( Windows )
		{
			IupSetAttribute( _dlg, "FONT", IupGetGlobal( "DEFAULTFONT" ) );
			//IupSetAttribute( _dlg, "FONT", GLOBAL.cString.convert( "Courier New,9" ) );
		}
		else
		{
			IupSetAttribute( _dlg, "FONT", IupGetGlobal( "DEFAULTFONT" ) );
			//IupSetAttribute( _dlg, "FONT", GLOBAL.cString.convert( "Ubuntu Mono, 10" ) );
		}
		
		IupSetHandle( "PreferenceHandle", getIhandle );
		
		createLayout();
		
		//scope size = new IupString( Integer.toString( w ) ~ "x" ~ Integer.toString( h ) );
		version(Windows) IupSetAttribute( _dlg, "SIZE", "-1x310" ); else IupSetAttribute( _dlg, "SIZE", "-1x360" );
		
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
		/+
		IupSetHandle( "compilerPath_Handle", null );
		IupSetHandle( "debuggerPath_Handle", null );
		IupSetHandle( "textTerminalPath", null );
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
		IupSetHandle( "toggleOverWrite", null );
		IupSetHandle( "toggleBackThread", null );
		IupSetHandle( "textCompleteDalay", null );
		IupSetHandle( "toggleLiveNone", null );
		IupSetHandle( "toggleLiveLight", null );
		IupSetHandle( "toggleLiveFull", null );		
		IupSetHandle( "toggleUpdateOutline", null );
	
		IupSetHandle( "toggleAnnotation", null );
		IupSetHandle( "toggleShowResultWindow", null );
		IupSetHandle( "toggleSFX", null );
		IupSetHandle( "toggleDelPrevEXE", null );
		IupSetHandle( "toggleConsoleExe", null );
		IupSetHandle( "toggleCompileAtBackThread", null );
		
		IupSetHandle( "toggleDummy", null );
		
		

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
		IupSetHandle( "toggleDocStatus", null );
		IupSetHandle( "toggleLoadAtBackThread", null );
		IupSetHandle( "toggleAutoKBLayout", null );
		IupSetHandle( "toggleQBCase", null );
		IupSetHandle( "toggleNewDocBOM", null );
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

		IupSetHandle( "keyWordText0", null );
		IupSetHandle( "keyWordText1", null );
		IupSetHandle( "keyWordText2", null );
		IupSetHandle( "keyWordText3", null );
		
		IupSetHandle( "shortCutList", null );
		+/
		
		for( int i = 0; i < 15; ++ i )
			if( PreferenceDialogParameters._stringOfLabel[i] !is null ) delete PreferenceDialogParameters._stringOfLabel[i];
	}
	
	char[] show( int x, int y )
	{
		// For Stranger bug, when issue occur, all toggle options are set to not "ON"
		if( fromStringz( IupGetAttribute( IupGetHandle( "toggleDummy" ), "VALUE" ) ) != "ON" )
		{
			GLOBAL.toggleDummy = "ON";
			return null;
		}
		
		IupShowXY( _dlg, x, y );
		return "OK";
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

		return IUP_DEFAULT;
	}	

	private int CPreferenceDialog_OpenDebuggerBinFile_cb( Ihandle* ih )
	{
		scope fileSecectDlg = new CFileDlg( GLOBAL.languageItems["caption_open"].toDString ~ "..." );
		char[] fileName = fileSecectDlg.getFileName();

		if( fileName.length )
		{
			if( fromStringz( IupGetAttribute( ih, "NAME" ) ).dup == "x64" )
			{
				GLOBAL.x64debuggerFullPath = fileName;
				Ihandle* _debuggerPath_Handle = IupGetHandle( "x64DebuggerPath_Handle" );
				if( _debuggerPath_Handle != null ) IupSetAttribute( _debuggerPath_Handle, "VALUE", GLOBAL.x64debuggerFullPath.toCString );
			}
			else
			{
				GLOBAL.debuggerFullPath = fileName;
				Ihandle* _debuggerPath_Handle = IupGetHandle( "debuggerPath_Handle" );
				if( _debuggerPath_Handle != null ) IupSetAttribute( _debuggerPath_Handle, "VALUE", GLOBAL.debuggerFullPath.toCString );
			}
		}

		return IUP_DEFAULT;
	}
	
	version(linux)
	{
		private int CPreferenceDialog_OpenTerminalBinFile_cb( Ihandle* ih )
		{
			scope fileSecectDlg = new CFileDlg( GLOBAL.languageItems["caption_open"].toDString ~ "..." );
			char[] fileName = fileSecectDlg.getFileName();

			if( fileName.length )
			{
				GLOBAL.linuxTermName = fileName;
				Ihandle* _terminalPath_Handle = IupGetHandle( "textTerminalPath" );
				if( _terminalPath_Handle != null ) IupSetAttribute( _terminalPath_Handle, "VALUE", GLOBAL.linuxTermName.toCString );
			}

			return IUP_DEFAULT;
		}
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
			GLOBAL.KEYWORDS[4] = Util.trim( fromStringz(IupGetAttribute( IupGetHandle( "keyWordText4" ), "VALUE" ))).dup;
			GLOBAL.KEYWORDS[5] = Util.trim( fromStringz(IupGetAttribute( IupGetHandle( "keyWordText5" ), "VALUE" ))).dup;
			
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
			GLOBAL.editorSetting00.DocStatus				= fromStringz(IupGetAttribute( IupGetHandle( "toggleDocStatus" ), "VALUE" )).dup;
			GLOBAL.editorSetting00.LoadAtBackThread			= fromStringz(IupGetAttribute( IupGetHandle( "toggleLoadAtBackThread" ), "VALUE" )).dup;
			GLOBAL.editorSetting00.AutoKBLayout				= fromStringz(IupGetAttribute( IupGetHandle( "toggleAutoKBLayout" ), "VALUE" )).dup;
			GLOBAL.editorSetting00.QBCase					= fromStringz(IupGetAttribute( IupGetHandle( "toggleQBCase" ), "VALUE" )).dup;
			GLOBAL.editorSetting00.NewDocBOM				= fromStringz(IupGetAttribute( IupGetHandle( "toggleNewDocBOM" ), "VALUE" )).dup;
			
			

			
			IupSetAttribute( IupGetHandle( "textSetControlCharSymbol" ), "VALUE", PreferenceDialogParameters.stringCharSymbol << IupGetAttribute( IupGetHandle( "textSetControlCharSymbol" ), "VALUE" ) );
			GLOBAL.editorSetting00.ControlCharSymbol		= PreferenceDialogParameters.stringCharSymbol.toDString;
			
			IupSetAttribute( IupGetHandle( "textTabWidth" ), "VALUE", PreferenceDialogParameters.stringTabWidth << IupGetAttribute( IupGetHandle( "textTabWidth" ), "VALUE" ) );
			GLOBAL.editorSetting00.TabWidth = PreferenceDialogParameters.stringTabWidth.toDString;

			IupSetAttribute( IupGetHandle( "textColumnEdge" ), "VALUE", PreferenceDialogParameters.stringColumnEdge << IupGetAttribute( IupGetHandle( "textColumnEdge" ), "VALUE" ) );
			GLOBAL.editorSetting00.ColumnEdge			= PreferenceDialogParameters.stringColumnEdge.toDString;
			
			IupSetAttribute( IupGetHandle( "textBarSize" ), "VALUE", PreferenceDialogParameters.stringBarSize << IupGetAttribute( IupGetHandle( "textBarSize" ), "VALUE" ) );
			GLOBAL.editorSetting01.BarSize				= PreferenceDialogParameters.stringBarSize.toDString;
			int _barSize = Integer.atoi( GLOBAL.editorSetting01.BarSize );
			if( _barSize < 2 )
			{
				GLOBAL.editorSetting01.BarSize = "2";
				IupSetAttribute( IupGetHandle( "textBarSize" ), "VALUE", "2" );
				IupSetAttribute( IupGetHandle( "textBarSize" ), "VALUE", PreferenceDialogParameters.stringBarSize << IupGetAttribute( IupGetHandle( "textBarSize" ), "VALUE" ) );
			}
			if( _barSize > 5 )
			{
				GLOBAL.editorSetting01.BarSize = "5";
				IupSetAttribute( IupGetHandle( "textBarSize" ), "VALUE", "5" );
				IupSetAttribute( IupGetHandle( "textBarSize" ), "VALUE", PreferenceDialogParameters.stringBarSize << IupGetAttribute( IupGetHandle( "textBarSize" ), "VALUE" ) );
			}

			
			// Save Font Style
			for( int i = 0; i < GLOBAL.fonts.length; ++ i )
			{
				char[][] _values = PreferenceDialogParameters.fontTable.getSelection( i + 1 );
				if( _values.length == 4 )
				{
					_values[2] = Util.trim( _values[2] ).dup;
					if( !_values[2].length ) _values[2] = " ";else  _values[2] = " " ~  _values[2] ~ " ";
					GLOBAL.fonts[i].fontString = _values[1] ~ "," ~ _values[2] ~ _values[3];
				}
			}
			

			//GLOBAL.editColor.caretLine					= IupGetAttribute( IupGetHandle( "btnCaretLine" ), "BGCOLOR" );					IupSetAttribute( IupGetHandle( "btnCaretLine" ), "BGCOLOR", GLOBAL.editColor.caretLine.toCString );
			IupSetAttribute( IupGetHandle( "btnCaretLine" ), "FGCOLOR", GLOBAL.editColor.caretLine << IupGetAttribute( IupGetHandle( "btnCaretLine" ), "FGCOLOR" ) );
			
			//GLOBAL.editColor.cursor						= IupGetAttribute( IupGetHandle( "btnCursor" ), "BGCOLOR" );					IupSetAttribute( IupGetHandle( "btnCursor" ), "BGCOLOR", GLOBAL.editColor.cursor.toCString );
			IupSetAttribute( IupGetHandle( "btnCursor" ), "FGCOLOR", GLOBAL.editColor.cursor << IupGetAttribute( IupGetHandle( "btnCursor" ), "FGCOLOR" ) );

			/*
			GLOBAL.editColor.selectionFore				= IupGetAttribute( IupGetHandle( "btnSelectFore" ), "BGCOLOR" );				IupSetAttribute( IupGetHandle( "btnSelectFore" ), "BGCOLOR", GLOBAL.editColor.selectionFore.toCString );
			GLOBAL.editColor.selectionBack				= IupGetAttribute( IupGetHandle( "btnSelectBack" ), "BGCOLOR" );				IupSetAttribute( IupGetHandle( "btnSelectBack" ), "BGCOLOR", GLOBAL.editColor.selectionBack.toCString );
			GLOBAL.editColor.linenumFore				= IupGetAttribute( IupGetHandle( "btnLinenumFore" ), "BGCOLOR" );				IupSetAttribute( IupGetHandle( "btnLinenumFore" ), "BGCOLOR", GLOBAL.editColor.linenumFore.toCString );
			GLOBAL.editColor.linenumBack				= IupGetAttribute( IupGetHandle( "btnLinenumBack" ), "BGCOLOR" );				IupSetAttribute( IupGetHandle( "btnLinenumBack" ), "BGCOLOR", GLOBAL.editColor.linenumBack.toCString );
			GLOBAL.editColor.fold						= IupGetAttribute( IupGetHandle( "btnFoldingColor" ), "BGCOLOR" );				IupSetAttribute( IupGetHandle( "btnFoldingColor" ), "BGCOLOR", GLOBAL.editColor.fold.toCString );
			*/
			IupSetAttribute( IupGetHandle( "btnSelectFore" ), "FGCOLOR", GLOBAL.editColor.selectionFore << IupGetAttribute( IupGetHandle( "btnSelectFore" ), "FGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnSelectBack" ), "FGCOLOR", GLOBAL.editColor.selectionBack << IupGetAttribute( IupGetHandle( "btnSelectBack" ), "FGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnLinenumFore" ), "FGCOLOR", GLOBAL.editColor.linenumFore << IupGetAttribute( IupGetHandle( "btnLinenumFore" ), "FGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnLinenumBack" ), "FGCOLOR", GLOBAL.editColor.linenumBack << IupGetAttribute( IupGetHandle( "btnLinenumBack" ), "FGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnFoldingColor" ), "FGCOLOR", GLOBAL.editColor.fold << IupGetAttribute( IupGetHandle( "btnFoldingColor" ), "FGCOLOR" ) );
			
			
			version(Windows)
				GLOBAL.editColor.selAlpha				= IupGetAttribute( IupGetHandle( "textAlpha" ), "SPINVALUE" );
			else
				GLOBAL.editColor.selAlpha				= IupGetAttribute( IupGetHandle( "textAlpha" ), "VALUE" );
			
			//GLOBAL.editColor.currentWord				= IupGetAttribute( IupGetHandle( "btnIndicator" ), "BGCOLOR" );				IupSetAttribute( IupGetHandle( "btnIndicator" ), "BGCOLOR", GLOBAL.editColor.currentWord.toCString );
			IupSetAttribute( IupGetHandle( "btnIndicator" ), "FGCOLOR", GLOBAL.editColor.currentWord << IupGetAttribute( IupGetHandle( "btnIndicator" ), "FGCOLOR" ) );
			version(Windows)
				GLOBAL.editColor.currentWordAlpha		= IupGetAttribute( IupGetHandle( "textIndicatorAlpha" ), "SPINVALUE" );
			else
				GLOBAL.editColor.currentWordAlpha		= IupGetAttribute( IupGetHandle( "textIndicatorAlpha" ), "VALUE" );
				

			IupSetAttribute( IupGetHandle( "btn_Scintilla_FG" ), "FGCOLOR", GLOBAL.editColor.scintillaFore << IupGetAttribute( IupGetHandle( "btn_Scintilla_FG" ), "FGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btn_Scintilla_BG" ), "FGCOLOR", GLOBAL.editColor.scintillaBack << IupGetAttribute( IupGetHandle( "btn_Scintilla_BG" ), "FGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnSCE_B_COMMENT_FG" ), "FGCOLOR", GLOBAL.editColor.SCE_B_COMMENT_Fore << IupGetAttribute( IupGetHandle( "btnSCE_B_COMMENT_FG" ), "FGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnSCE_B_COMMENT_BG" ), "FGCOLOR", GLOBAL.editColor.SCE_B_COMMENT_Back << IupGetAttribute( IupGetHandle( "btnSCE_B_COMMENT_BG" ), "FGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnSCE_B_NUMBER_FG" ), "FGCOLOR", GLOBAL.editColor.SCE_B_NUMBER_Fore << IupGetAttribute( IupGetHandle( "btnSCE_B_NUMBER_FG" ), "FGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnSCE_B_NUMBER_BG" ), "FGCOLOR", GLOBAL.editColor.SCE_B_NUMBER_Back << IupGetAttribute( IupGetHandle( "btnSCE_B_NUMBER_BG" ), "FGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnSCE_B_STRING_FG" ), "FGCOLOR", GLOBAL.editColor.SCE_B_STRING_Fore << IupGetAttribute( IupGetHandle( "btnSCE_B_STRING_FG" ), "FGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnSCE_B_STRING_BG" ), "FGCOLOR", GLOBAL.editColor.SCE_B_STRING_Back << IupGetAttribute( IupGetHandle( "btnSCE_B_STRING_BG" ), "FGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnSCE_B_PREPROCESSOR_FG" ), "FGCOLOR", GLOBAL.editColor.SCE_B_PREPROCESSOR_Fore << IupGetAttribute( IupGetHandle( "btnSCE_B_PREPROCESSOR_FG" ), "FGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnSCE_B_PREPROCESSOR_BG" ), "FGCOLOR", GLOBAL.editColor.SCE_B_PREPROCESSOR_Back << IupGetAttribute( IupGetHandle( "btnSCE_B_PREPROCESSOR_BG" ), "FGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnSCE_B_OPERATOR_FG" ), "FGCOLOR", GLOBAL.editColor.SCE_B_OPERATOR_Fore << IupGetAttribute( IupGetHandle( "btnSCE_B_OPERATOR_FG" ), "FGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnSCE_B_OPERATOR_BG" ), "FGCOLOR", GLOBAL.editColor.SCE_B_OPERATOR_Back << IupGetAttribute( IupGetHandle( "btnSCE_B_OPERATOR_BG" ), "FGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnSCE_B_IDENTIFIER_FG" ), "FGCOLOR", GLOBAL.editColor.SCE_B_IDENTIFIER_Fore << IupGetAttribute( IupGetHandle( "btnSCE_B_IDENTIFIER_FG" ), "FGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnSCE_B_IDENTIFIER_BG" ), "FGCOLOR", GLOBAL.editColor.SCE_B_IDENTIFIER_Back << IupGetAttribute( IupGetHandle( "btnSCE_B_IDENTIFIER_BG" ), "FGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnSCE_B_COMMENTBLOCK_FG" ), "FGCOLOR", GLOBAL.editColor.SCE_B_COMMENTBLOCK_Fore << IupGetAttribute( IupGetHandle( "btnSCE_B_COMMENTBLOCK_FG" ), "FGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnSCE_B_COMMENTBLOCK_BG" ), "FGCOLOR", GLOBAL.editColor.SCE_B_COMMENTBLOCK_Back << IupGetAttribute( IupGetHandle( "btnSCE_B_COMMENTBLOCK_BG" ), "FGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnPrjTitle" ), "FGCOLOR", GLOBAL.editColor.prjTitle << IupGetAttribute( IupGetHandle( "btnPrjTitle" ), "FGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnSourceTypeFolder" ), "FGCOLOR", GLOBAL.editColor.prjSourceType << IupGetAttribute( IupGetHandle( "btnSourceTypeFolder" ), "FGCOLOR" ) );
			
			IupSetAttribute( IupGetHandle( "btnPrj_FG" ), "FGCOLOR", GLOBAL.editColor.projectFore << IupGetAttribute( IupGetHandle( "btnPrj_FG" ), "FGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnPrj_BG" ), "FGCOLOR", GLOBAL.editColor.projectBack << IupGetAttribute( IupGetHandle( "btnPrj_BG" ), "FGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnOutline_FG" ), "FGCOLOR", GLOBAL.editColor.outlineFore << IupGetAttribute( IupGetHandle( "btnOutline_FG" ), "FGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnOutline_BG" ), "FGCOLOR", GLOBAL.editColor.outlineBack << IupGetAttribute( IupGetHandle( "btnOutline_BG" ), "FGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnFilelist_FG" ), "FGCOLOR", GLOBAL.editColor.filelistFore << IupGetAttribute( IupGetHandle( "btnFilelist_FG" ), "FGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnFilelist_BG" ), "FGCOLOR", GLOBAL.editColor.filelistBack << IupGetAttribute( IupGetHandle( "btnFilelist_BG" ), "FGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnOutput_FG" ), "FGCOLOR", GLOBAL.editColor.outputFore << IupGetAttribute( IupGetHandle( "btnOutput_FG" ), "FGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnOutput_BG" ), "FGCOLOR", GLOBAL.editColor.outputBack << IupGetAttribute( IupGetHandle( "btnOutput_BG" ), "FGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnSearch_FG" ), "FGCOLOR", GLOBAL.editColor.searchFore << IupGetAttribute( IupGetHandle( "btnSearch_FG" ), "FGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnSearch_BG" ), "FGCOLOR", GLOBAL.editColor.searchBack << IupGetAttribute( IupGetHandle( "btnSearch_BG" ), "FGCOLOR" ) );

			IupSetAttribute( IupGetHandle( "btnError_FG" ), "FGCOLOR", GLOBAL.editColor.errorFore << IupGetAttribute( IupGetHandle( "btnError_FG" ), "FGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnError_BG" ), "FGCOLOR", GLOBAL.editColor.errorBack << IupGetAttribute( IupGetHandle( "btnError_BG" ), "FGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnWarning_FG" ), "FGCOLOR", GLOBAL.editColor.warningFore << IupGetAttribute( IupGetHandle( "btnWarning_FG" ), "FGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnWarning_BG" ), "FGCOLOR", GLOBAL.editColor.warringBack << IupGetAttribute( IupGetHandle( "btnWarning_BG" ), "FGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnBrace_FG" ), "FGCOLOR", GLOBAL.editColor.braceFore << IupGetAttribute( IupGetHandle( "btnBrace_FG" ), "FGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnBrace_BG" ), "FGCOLOR", GLOBAL.editColor.braceBack << IupGetAttribute( IupGetHandle( "btnBrace_BG" ), "FGCOLOR" ) );

			IupSetAttribute( IupGetHandle( "btnMarker0Color" ), "FGCOLOR", GLOBAL.editColor.maker[0] << IupGetAttribute( IupGetHandle( "btnMarker0Color" ), "FGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnMarker1Color" ), "FGCOLOR", GLOBAL.editColor.maker[1] << IupGetAttribute( IupGetHandle( "btnMarker1Color" ), "FGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnMarker2Color" ), "FGCOLOR", GLOBAL.editColor.maker[2] << IupGetAttribute( IupGetHandle( "btnMarker2Color" ), "FGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnMarker3Color" ), "FGCOLOR", GLOBAL.editColor.maker[3] << IupGetAttribute( IupGetHandle( "btnMarker3Color" ), "FGCOLOR" ) );

			GLOBAL.projectTree.changeColor();
			GLOBAL.outlineTree.changeColor();
			GLOBAL.fileListTree.changeColor();
			
			// GLOBAL.editColor.keyWord is IupString class
			IupSetAttribute( IupGetHandle( "btnKeyWord0Color" ), "FGCOLOR", GLOBAL.editColor.keyWord[0] << IupGetAttribute( IupGetHandle( "btnKeyWord0Color" ), "FGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnKeyWord1Color" ), "FGCOLOR", GLOBAL.editColor.keyWord[1] << IupGetAttribute( IupGetHandle( "btnKeyWord1Color" ), "FGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnKeyWord2Color" ), "FGCOLOR", GLOBAL.editColor.keyWord[2] << IupGetAttribute( IupGetHandle( "btnKeyWord2Color" ), "FGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnKeyWord3Color" ), "FGCOLOR", GLOBAL.editColor.keyWord[3] << IupGetAttribute( IupGetHandle( "btnKeyWord3Color" ), "FGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnKeyWord4Color" ), "FGCOLOR", GLOBAL.editColor.keyWord[4] << IupGetAttribute( IupGetHandle( "btnKeyWord4Color" ), "FGCOLOR" ) );
			IupSetAttribute( IupGetHandle( "btnKeyWord5Color" ), "FGCOLOR", GLOBAL.editColor.keyWord[5] << IupGetAttribute( IupGetHandle( "btnKeyWord5Color" ), "FGCOLOR" ) );


			
			// Set GLOBAL.messagePanel Color
			GLOBAL.messagePanel.applyColor();
			
			/*
			char[] templateName = Util.trim( fromStringz( IupGetAttribute( IupGetHandle( "colorTemplateList" ), "VALUE" ) ) ).dup;
			if( templateName.length )
			{
				IDECONFIG.saveColorTemplateINI( templateName );
				//GLOBAL.colorTemplate = templateName.dup;
			}
			*/

			GLOBAL.autoCompletionTriggerWordCount		= Integer.atoi( fromStringz( IupGetAttribute( IupGetHandle( "textTrigger" ), "VALUE" ) ) );
			GLOBAL.statusBar.setOriginalTrigger( GLOBAL.autoCompletionTriggerWordCount );
			
			version(FBIDE)
			{
				GLOBAL.includeLevel			= Integer.atoi( fromStringz( IupGetAttribute( IupGetHandle( "textIncludeLevel" ), "VALUE" ) ) );
				IupSetAttribute( IupGetHandle( "textIncludeLevel" ), "VALUE", PreferenceDialogParameters.stringLevel << IupGetAttribute( IupGetHandle( "textIncludeLevel" ), "VALUE" ) );
			}
			
			IupSetAttribute( IupGetHandle( "textTrigger" ), "VALUE", PreferenceDialogParameters.stringTrigger << IupGetAttribute( IupGetHandle( "textTrigger" ), "VALUE" ) );

			if( GLOBAL.includeLevel < 0 ) GLOBAL.includeLevel = 0;

			GLOBAL.compilerFullPath						= IupGetAttribute( IupGetHandle( "compilerPath_Handle" ), "VALUE" );
			version(Windows) GLOBAL.x64compilerFullPath	= IupGetAttribute( IupGetHandle( "x64compilerPath_Handle" ), "VALUE" );
			GLOBAL.debuggerFullPath						= IupGetAttribute( IupGetHandle( "debuggerPath_Handle" ), "VALUE" );
			version(linux) GLOBAL.linuxTermName			= IupGetAttribute( IupGetHandle( "textTerminalPath" ), "VALUE" );
			GLOBAL.compilerAnootation					= fromStringz( IupGetAttribute( IupGetHandle( "toggleAnnotation" ), "VALUE" ) ).dup;
			GLOBAL.compilerWindow						= fromStringz( IupGetAttribute( IupGetHandle( "toggleShowResultWindow" ), "VALUE" ) ).dup;
			GLOBAL.compilerSFX							= fromStringz( IupGetAttribute( IupGetHandle( "toggleSFX" ), "VALUE" ) ).dup;
			
			GLOBAL.delExistExe							= fromStringz( IupGetAttribute( IupGetHandle( "toggleDelPrevEXE" ), "VALUE" ) ).dup;
			GLOBAL.consoleExe							= fromStringz( IupGetAttribute( IupGetHandle( "toggleConsoleExe" ), "VALUE" ) ).dup;
			GLOBAL.toggleCompileAtBackThread			= fromStringz( IupGetAttribute( IupGetHandle( "toggleCompileAtBackThread" ), "VALUE" ) ).dup;
			
			
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
					
					IupSetAttribute( _mHandle, "VALUE", PreferenceDialogParameters.stringMonitor[0] << IupGetAttribute( _mHandle, "VALUE" ) );
				}
				_mHandle = IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textConsoleX" );
				if( _mHandle != null )
				{
					GLOBAL.consoleWindow.x = Integer.atoi( fromStringz( IupGetAttribute( _mHandle, "VALUE" ) ) );
					IupSetAttribute( _mHandle, "VALUE", PreferenceDialogParameters.stringMonitor[1] << IupGetAttribute( _mHandle, "VALUE" ) );
				}
				_mHandle = IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textConsoleY" );
				if( _mHandle != null )
				{
					GLOBAL.consoleWindow.y = Integer.atoi( fromStringz( IupGetAttribute( _mHandle, "VALUE" ) ) );
					IupSetAttribute( _mHandle, "VALUE", PreferenceDialogParameters.stringMonitor[2] << IupGetAttribute( _mHandle, "VALUE" ) );
				}
				_mHandle = IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textConsoleW" );
				if( _mHandle != null )
				{
					GLOBAL.consoleWindow.w = Integer.atoi( fromStringz( IupGetAttribute( _mHandle, "VALUE" ) ) );
					IupSetAttribute( _mHandle, "VALUE", PreferenceDialogParameters.stringMonitor[3] << IupGetAttribute( _mHandle, "VALUE" ) );
					}
				_mHandle = IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textConsoleH" );
				if( _mHandle != null )
				{
					GLOBAL.consoleWindow.h = Integer.atoi( fromStringz( IupGetAttribute( _mHandle, "VALUE" ) ) );
					IupSetAttribute( _mHandle, "VALUE", PreferenceDialogParameters.stringMonitor[4] << IupGetAttribute( _mHandle, "VALUE" ) );
				}
			}
			catch( Exception e )
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
			//GLOBAL.widthFunctionTitle					= IupGetAttribute( IupGetHandle( "textFunctionTitle" ), "VALUE" );
			
			
			GLOBAL.showTypeWithParams					= fromStringz( IupGetAttribute( IupGetHandle( "toggleWithParams" ), "VALUE" ) ).dup;
			GLOBAL.toggleIgnoreCase						= fromStringz( IupGetAttribute( IupGetHandle( "toggleIGNORECASE" ), "VALUE" ) ).dup;
			GLOBAL.toggleCaseInsensitive				= fromStringz( IupGetAttribute( IupGetHandle( "toggleCASEINSENSITIVE" ), "VALUE" ) ).dup;
			GLOBAL.toggleShowListType					= fromStringz( IupGetAttribute( IupGetHandle( "toggleSHOWLISTTYPE" ), "VALUE" ) ).dup;
			GLOBAL.toggleShowAllMember					= fromStringz( IupGetAttribute( IupGetHandle( "toggleSHOWALLMEMBER" ), "VALUE" ) ).dup;
			GLOBAL.toggleEnableDwell					= fromStringz( IupGetAttribute( IupGetHandle( "toggleDWELL" ), "VALUE" ) ).dup;
			GLOBAL.toggleOverWrite						= fromStringz( IupGetAttribute( IupGetHandle( "toggleOverWrite" ), "VALUE" ) ).dup;
			GLOBAL.toggleCompleteAtBackThread			= fromStringz( IupGetAttribute( IupGetHandle( "toggleBackThread" ), "VALUE" ) ).dup;
			
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
				IupRefresh( GLOBAL.toolbar.getListHandle() );
			}
			else
				IupSetAttribute( GLOBAL.toolbar.getListHandle(), "VISIBLE", "NO" );
				
			
			Ihandle* _valHandle = IupGetHandle( "valDWELL" );
			if( _valHandle != null )
			{
				float valuef = IupGetFloat( _valHandle, "VALUE" );
				int value = ( cast(int) valuef / 100 ) * 100;
			
				IupSetInt( _valHandle, "VALUE", value );
				GLOBAL.dwellDelay = Integer.toString( value ).dup;
			}				

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
								IupSetGlobal( "DEFAULTFONTSIZE", toStringz( ( GLOBAL.fonts[0].fontString[i+1..$] ).dup ) );

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
			scope statusString = new IupString( GLOBAL.fonts[11].fontString );	IupSetAttribute( GLOBAL.statusBar.getLayoutHandle, "FONT", statusString.toCString );// StatusBar
			scope outlineString = new IupString( GLOBAL.fonts[5].fontString );	IupSetAttribute( GLOBAL.outlineTree.getZBoxHandle, "FONT", outlineString.toCString );// Outline	
			
			version(DIDE)
			{
				version(linux) GLOBAL.debugPanel.setFont();
			}
			else
			{
				GLOBAL.debugPanel.setFont();
			}
			
			GLOBAL.toggleUseManual						= fromStringz(IupGetAttribute( IupGetHandle( "toggleUseManual" ), "VALUE" )).dup;
			
			// Save Setup to Xml
			//IDECONFIG.save();
			IDECONFIG.saveINI();

			IupRefreshChildren( IupGetHandle( "PreferenceHandle" ) );
		}
		catch( Exception e )
		{
			//IupMessage( "CPreferenceDialog_btnOK_cb", toStringz( e.toString ) );
			IupMessage( "CPreferenceDialog_btnOK_cb", toStringz( "CPreferenceDialog_btnOK_cb Error\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ Integer.toString( e.line ) ) );
		}

		return IUP_DEFAULT;
	}

	private int CPreferenceDialog_colorChoose_cb( Ihandle* ih )
	{
		Ihandle* dlg = IupColorDlg();

		//IupSetAttribute( dlg, "VALUE", IupGetAttribute( ih, "BGCOLOR" ) );
		IupSetAttribute( dlg, "VALUE", IupGetAttribute( ih, "FGCOLOR" ) ); // For IupFlatButton
		IupSetAttribute(dlg, "SHOWHEX", "YES");
		IupSetAttribute(dlg, "SHOWCOLORTABLE", "YES");
		IupSetAttribute(dlg, "TITLE", GLOBAL.languageItems["color"].toCString() );

		IupPopup( dlg, IUP_CURRENT, IUP_CURRENT );

		//if( IupGetInt( dlg, "STATUS" ) ) IupSetAttribute( ih, "BGCOLOR", IupGetAttribute( dlg, "VALUE" ) );
		if( IupGetInt( dlg, "STATUS" ) )
		{
			IupSetAttribute( ih, "FGCOLOR", IupGetAttribute( dlg, "VALUE" ) ); // For IupFlatButton
			IupSetFocus( GLOBAL.preferenceDlg.getIhandle );
		}

		return IUP_DEFAULT;
	}
	
	private int CPreferenceDialog_colorChooseScintilla_cb( Ihandle* ih )
	{
		Ihandle* dlg = IupColorDlg();

		IupSetAttribute( dlg, "VALUE", IupGetAttribute( ih, "FGCOLOR" ) );
		IupSetAttribute(dlg, "SHOWHEX", "YES");
		IupSetAttribute(dlg, "SHOWCOLORTABLE", "YES");
		IupSetAttribute(dlg, "TITLE", GLOBAL.languageItems["color"].toCString() );

		IupPopup( dlg, IUP_CURRENT, IUP_CURRENT );

		if( IupGetInt( dlg, "STATUS" ) )
		{
			IupSetAttribute( ih, "FGCOLOR", IupGetAttribute( dlg, "VALUE" ) );
			
			Ihandle* messageDlg = IupMessageDlg();
			IupSetAttributes( messageDlg, "DIALOGTYPE=QUESTION,BUTTONDEFAULT=2,BUTTONS=YESNO" );
			IupSetAttribute( messageDlg, "VALUE", GLOBAL.languageItems["applycolor"].toCString );
			IupSetAttribute( messageDlg, "TITLE", GLOBAL.languageItems["quest"].toCString() );
			IupPopup( messageDlg, IUP_CENTER, IUP_CENTER );		
			int button = IupGetInt( messageDlg, "BUTTONRESPONSE" );
			
			if( button == 1 )
			{
				Ihandle* _ih = IupGetHandle( "btnSCE_B_COMMENT_BG" );
				if( ih != null ) IupSetAttribute( _ih, "FGCOLOR", IupGetAttribute( dlg, "VALUE" ) );
				
				_ih = IupGetHandle( "btnSCE_B_NUMBER_BG" );
				if( ih != null ) IupSetAttribute( _ih, "FGCOLOR", IupGetAttribute( dlg, "VALUE" ) );
				
				_ih = IupGetHandle( "btnSCE_B_STRING_BG" );
				if( ih != null ) IupSetAttribute( _ih, "FGCOLOR", IupGetAttribute( dlg, "VALUE" ) );
				
				_ih = IupGetHandle( "btnSCE_B_PREPROCESSOR_BG" );
				if( ih != null ) IupSetAttribute( _ih, "FGCOLOR", IupGetAttribute( dlg, "VALUE" ) );
				
				_ih = IupGetHandle( "btnSCE_B_OPERATOR_BG" );
				if( ih != null ) IupSetAttribute( _ih, "FGCOLOR", IupGetAttribute( dlg, "VALUE" ) );
				
				_ih = IupGetHandle( "btnSCE_B_IDENTIFIER_BG" );
				if( ih != null ) IupSetAttribute( _ih, "FGCOLOR", IupGetAttribute( dlg, "VALUE" ) );
				
				_ih = IupGetHandle( "btnSCE_B_COMMENTBLOCK_BG" );
				if( ih != null ) IupSetAttribute( _ih, "FGCOLOR", IupGetAttribute( dlg, "VALUE" ) );
			}			
			IupSetFocus( GLOBAL.preferenceDlg.getIhandle );
		}

		return IUP_DEFAULT;
	}
	
	private int colorTemplateList_DROPDOWN_CB( Ihandle *ih, int state )
	{
		if( state == 1 )
		{
			scope templateFP = new FilePath( GLOBAL.linuxHome.length ? ( GLOBAL.linuxHome ~ "/settings/colorTemplates" ) : "settings/colorTemplates" );
			if( templateFP.exists() )
			{
				IupSetAttribute( ih, "REMOVEITEM", "ALL" );
				version(linux) IupSetAttributeId( ih, "", 1, toStringz( " " ) );
				foreach( _fp; templateFP.toList )
				{
					if( _fp.ext == "ini" ) IupSetAttribute( ih, "APPENDITEM", toStringz( _fp.name.dup ) );
				}
			}
		}
		
		return IUP_DEFAULT;
	}
	
	private int colorTemplateList_ACTION_CB( Ihandle *ih, char *text, int item, int state )
	{
		if( state == 1 )
		{
			char[]		templateName = fromStringz( text );
			if( !Util.trim( templateName ).length ) return IUP_DEFAULT;
			
			
			char[][]	colors = IDECONFIG.loadColorTemplateINI( templateName );
			
			if( colors.length > 50 ) return IUP_DEFAULT;
			
			for( int i = 0; i < colors.length; i ++ )
				if( PreferenceDialogParameters.kbg[i] is null ) PreferenceDialogParameters.kbg[i] = new IupString( colors[i] ); else PreferenceDialogParameters.kbg[i] = colors[i];
			
			//if( colors.length == 48 )
			//{
				IupSetAttribute( IupGetHandle( "btnCaretLine" ), "FGCOLOR", PreferenceDialogParameters.kbg[0].toCString );					IupSetFocus( IupGetHandle( "btnCaretLine" ) );
				IupSetAttribute( IupGetHandle( "btnCursor" ), "FGCOLOR", PreferenceDialogParameters.kbg[1].toCString );						IupSetFocus( IupGetHandle( "btnCursor" ) );
				IupSetAttribute( IupGetHandle( "btnSelectFore" ), "FGCOLOR", PreferenceDialogParameters.kbg[2].toCString );					IupSetFocus( IupGetHandle( "btnSelectFore" ) );
				IupSetAttribute( IupGetHandle( "btnSelectBack" ), "FGCOLOR", PreferenceDialogParameters.kbg[3].toCString );					IupSetFocus( IupGetHandle( "btnSelectBack" ) );
				IupSetAttribute( IupGetHandle( "btnLinenumFore" ), "FGCOLOR", PreferenceDialogParameters.kbg[4].toCString );				IupSetFocus( IupGetHandle( "btnLinenumFore" ) );
				IupSetAttribute( IupGetHandle( "btnLinenumBack" ), "FGCOLOR", PreferenceDialogParameters.kbg[5].toCString );				IupSetFocus( IupGetHandle( "btnLinenumBack" ) );
				IupSetAttribute( IupGetHandle( "btnFoldingColor" ), "FGCOLOR", PreferenceDialogParameters.kbg[6].toCString );				IupSetFocus( IupGetHandle( "btnFoldingColor" ) );

				version(Windows)
					IupSetAttribute( IupGetHandle( "textAlpha" ), "SPINVALUE", PreferenceDialogParameters.kbg[7].toCString );
				else
					IupSetAttribute( IupGetHandle( "textAlpha" ), "VALUE", PreferenceDialogParameters.kbg[7].toCString );

				IupSetAttribute( IupGetHandle( "btnBrace_FG" ), "FGCOLOR", PreferenceDialogParameters.kbg[8].toCString );					IupSetFocus( IupGetHandle( "btnBrace_FG" ) );
				IupSetAttribute( IupGetHandle( "btnBrace_BG" ), "FGCOLOR", PreferenceDialogParameters.kbg[9].toCString );					IupSetFocus( IupGetHandle( "btnBrace_BG" ) );	
				IupSetAttribute( IupGetHandle( "btnError_FG" ), "FGCOLOR", PreferenceDialogParameters.kbg[10].toCString );					IupSetFocus( IupGetHandle( "btnError_FG" ) );
				IupSetAttribute( IupGetHandle( "btnError_BG" ), "FGCOLOR", PreferenceDialogParameters.kbg[11].toCString );					IupSetFocus( IupGetHandle( "btnError_BG" ) );
				IupSetAttribute( IupGetHandle( "btnWarning_FG" ), "FGCOLOR", PreferenceDialogParameters.kbg[12].toCString );				IupSetFocus( IupGetHandle( "btnWarning_FG" ) );
				IupSetAttribute( IupGetHandle( "btnWarning_BG" ), "FGCOLOR", PreferenceDialogParameters.kbg[13].toCString );				IupSetFocus( IupGetHandle( "btnWarning_BG" ) );


				IupSetAttribute( IupGetHandle( "btn_Scintilla_FG" ), "FGCOLOR", PreferenceDialogParameters.kbg[14].toCString );				IupSetFocus( IupGetHandle( "btn_Scintilla_FG" ) );
				IupSetAttribute( IupGetHandle( "btn_Scintilla_BG" ), "FGCOLOR", PreferenceDialogParameters.kbg[15].toCString );				IupSetFocus( IupGetHandle( "btn_Scintilla_BG" ) );

				IupSetAttribute( IupGetHandle( "btnSCE_B_COMMENT_FG" ), "FGCOLOR", PreferenceDialogParameters.kbg[16].toCString );			IupSetFocus( IupGetHandle( "btnSCE_B_COMMENT_FG" ) );
				IupSetAttribute( IupGetHandle( "btnSCE_B_COMMENT_BG" ), "FGCOLOR", PreferenceDialogParameters.kbg[17].toCString );			IupSetFocus( IupGetHandle( "btnSCE_B_COMMENT_BG" ) );
				IupSetAttribute( IupGetHandle( "btnSCE_B_NUMBER_FG" ), "FGCOLOR", PreferenceDialogParameters.kbg[18].toCString );			IupSetFocus( IupGetHandle( "btnSCE_B_NUMBER_FG" ) );
				IupSetAttribute( IupGetHandle( "btnSCE_B_NUMBER_BG" ), "FGCOLOR", PreferenceDialogParameters.kbg[19].toCString );			IupSetFocus( IupGetHandle( "btnSCE_B_NUMBER_BG" ) );
				IupSetAttribute( IupGetHandle( "btnSCE_B_STRING_FG" ), "FGCOLOR", PreferenceDialogParameters.kbg[20].toCString );			IupSetFocus( IupGetHandle( "btnSCE_B_STRING_FG" ) );
				IupSetAttribute( IupGetHandle( "btnSCE_B_STRING_BG" ), "FGCOLOR", PreferenceDialogParameters.kbg[21].toCString );			IupSetFocus( IupGetHandle( "btnSCE_B_STRING_BG" ) );
				IupSetAttribute( IupGetHandle( "btnSCE_B_PREPROCESSOR_FG" ), "FGCOLOR", PreferenceDialogParameters.kbg[22].toCString );		IupSetFocus( IupGetHandle( "btnSCE_B_PREPROCESSOR_FG" ) );
				IupSetAttribute( IupGetHandle( "btnSCE_B_PREPROCESSOR_BG" ), "FGCOLOR", PreferenceDialogParameters.kbg[23].toCString );		IupSetFocus( IupGetHandle( "btnSCE_B_PREPROCESSOR_BG" ) );
				IupSetAttribute( IupGetHandle( "btnSCE_B_OPERATOR_FG" ), "FGCOLOR", PreferenceDialogParameters.kbg[24].toCString );			IupSetFocus( IupGetHandle( "btnSCE_B_OPERATOR_FG" ) );
				IupSetAttribute( IupGetHandle( "btnSCE_B_OPERATOR_BG" ), "FGCOLOR", PreferenceDialogParameters.kbg[25].toCString );			IupSetFocus( IupGetHandle( "btnSCE_B_OPERATOR_BG" ) );
				IupSetAttribute( IupGetHandle( "btnSCE_B_IDENTIFIER_FG" ), "FGCOLOR", PreferenceDialogParameters.kbg[26].toCString );		IupSetFocus( IupGetHandle( "btnSCE_B_IDENTIFIER_FG" ) );
				IupSetAttribute( IupGetHandle( "btnSCE_B_IDENTIFIER_BG" ), "FGCOLOR", PreferenceDialogParameters.kbg[27].toCString );		IupSetFocus( IupGetHandle( "btnSCE_B_IDENTIFIER_BG" ) );
				IupSetAttribute( IupGetHandle( "btnSCE_B_COMMENTBLOCK_FG" ), "FGCOLOR", PreferenceDialogParameters.kbg[28].toCString );		IupSetFocus( IupGetHandle( "btnSCE_B_COMMENTBLOCK_FG" ) );
				IupSetAttribute( IupGetHandle( "btnSCE_B_COMMENTBLOCK_BG" ), "FGCOLOR", PreferenceDialogParameters.kbg[29].toCString );		IupSetFocus( IupGetHandle( "btnSCE_B_COMMENTBLOCK_BG" ) );
				
				IupSetAttribute( IupGetHandle( "btnPrj_FG" ), "FGCOLOR", PreferenceDialogParameters.kbg[30].toCString );					IupSetFocus( IupGetHandle( "btnPrj_FG" ) );
				IupSetAttribute( IupGetHandle( "btnPrj_BG" ), "FGCOLOR", PreferenceDialogParameters.kbg[31].toCString );					IupSetFocus( IupGetHandle( "btnPrj_BG" ) );
				IupSetAttribute( IupGetHandle( "btnOutline_FG" ), "FGCOLOR", PreferenceDialogParameters.kbg[32].toCString );				IupSetFocus( IupGetHandle( "btnOutline_FG" ) );
				IupSetAttribute( IupGetHandle( "btnOutline_BG" ), "FGCOLOR", PreferenceDialogParameters.kbg[33].toCString );				IupSetFocus( IupGetHandle( "btnOutline_BG" ) );
				IupSetAttribute( IupGetHandle( "btnFilelist_FG" ), "FGCOLOR", PreferenceDialogParameters.kbg[34].toCString );				IupSetFocus( IupGetHandle( "btnFilelist_FG" ) );
				IupSetAttribute( IupGetHandle( "btnFilelist_BG" ), "FGCOLOR", PreferenceDialogParameters.kbg[35].toCString );				IupSetFocus( IupGetHandle( "btnFilelist_BG" ) );
				IupSetAttribute( IupGetHandle( "btnOutput_FG" ), "FGCOLOR", PreferenceDialogParameters.kbg[36].toCString );					IupSetFocus( IupGetHandle( "btnOutput_FG" ) );
				IupSetAttribute( IupGetHandle( "btnOutput_BG" ), "FGCOLOR", PreferenceDialogParameters.kbg[37].toCString );					IupSetFocus( IupGetHandle( "btnOutput_BG" ) );
				IupSetAttribute( IupGetHandle( "btnSearch_FG" ), "FGCOLOR", PreferenceDialogParameters.kbg[38].toCString );					IupSetFocus( IupGetHandle( "btnSearch_FG" ) );
				IupSetAttribute( IupGetHandle( "btnSearch_BG" ), "FGCOLOR", PreferenceDialogParameters.kbg[39].toCString );					IupSetFocus( IupGetHandle( "btnSearch_BG" ) );

				IupSetAttribute( IupGetHandle( "btnPrjTitle" ), "FGCOLOR", PreferenceDialogParameters.kbg[40].toCString );					IupSetFocus( IupGetHandle( "btnPrjTitle" ) );
				IupSetAttribute( IupGetHandle( "btnSourceTypeFolder" ), "FGCOLOR", PreferenceDialogParameters.kbg[41].toCString );			IupSetFocus( IupGetHandle( "btnSourceTypeFolder" ) );
				
				IupSetAttribute( IupGetHandle( "btnKeyWord0Color" ), "FGCOLOR", PreferenceDialogParameters.kbg[42].toCString );				IupSetFocus( IupGetHandle( "btnKeyWord0Color" ) );
				IupSetAttribute( IupGetHandle( "btnKeyWord1Color" ), "FGCOLOR", PreferenceDialogParameters.kbg[43].toCString );				IupSetFocus( IupGetHandle( "btnKeyWord1Color" ) );
				IupSetAttribute( IupGetHandle( "btnKeyWord2Color" ), "FGCOLOR", PreferenceDialogParameters.kbg[44].toCString );				IupSetFocus( IupGetHandle( "btnKeyWord2Color" ) );
				IupSetAttribute( IupGetHandle( "btnKeyWord3Color" ), "FGCOLOR", PreferenceDialogParameters.kbg[45].toCString );				IupSetFocus( IupGetHandle( "btnKeyWord3Color" ) );
				
				IupSetAttribute( IupGetHandle( "btnIndicator" ), "FGCOLOR", PreferenceDialogParameters.kbg[46].toCString );					IupSetFocus( IupGetHandle( "btnIndicator" ) );
				version(Windows)
					IupSetAttribute( IupGetHandle( "textIndicatorAlpha" ), "SPINVALUE", PreferenceDialogParameters.kbg[47].toCString );
				else
					IupSetAttribute( IupGetHandle( "textIndicatorAlpha" ), "VALUE", PreferenceDialogParameters.kbg[47].toCString );			
					
				IupSetAttribute( IupGetHandle( "btnKeyWord4Color" ), "FGCOLOR", PreferenceDialogParameters.kbg[48].toCString );				IupSetFocus( IupGetHandle( "btnKeyWord4Color" ) );
				IupSetAttribute( IupGetHandle( "btnKeyWord5Color" ), "FGCOLOR", PreferenceDialogParameters.kbg[49].toCString );				IupSetFocus( IupGetHandle( "btnKeyWord5Color" ) );
			//}
		}
		
		return IUP_DEFAULT;
	}
	
	private int colorTemplateList_reset_ACTION( Ihandle *ih )
	{
		IupSetAttribute( IupGetHandle( "btnCaretLine" ), "FGCOLOR", "255 255 128" );			IupSetFocus( IupGetHandle( "btnCaretLine" ) );
		IupSetAttribute( IupGetHandle( "btnCursor" ), "FGCOLOR", "0 0 0" );						IupSetFocus( IupGetHandle( "btnCursor" ) );
		IupSetAttribute( IupGetHandle( "btnSelectFore" ), "FGCOLOR", "255 255 255" );			IupSetFocus( IupGetHandle( "btnSelectFore" ) );
		IupSetAttribute( IupGetHandle( "btnSelectBack" ), "FGCOLOR", "0 0 255" );				IupSetFocus( IupGetHandle( "btnSelectBack" ) );
		IupSetAttribute( IupGetHandle( "btnLinenumFore" ), "FGCOLOR", "0 0 0" );				IupSetFocus( IupGetHandle( "btnLinenumFore" ) );
		IupSetAttribute( IupGetHandle( "btnLinenumBack" ), "FGCOLOR", "200 200 200" );			IupSetFocus( IupGetHandle( "btnLinenumBack" ) );
		IupSetAttribute( IupGetHandle( "btnFoldingColor" ), "FGCOLOR", "241 243 243" );			IupSetFocus( IupGetHandle( "btnFoldingColor" ) );

		version(Windows)
			IupSetAttribute( IupGetHandle( "textAlpha" ), "SPINVALUE", "64" );
		else
			IupSetAttribute( IupGetHandle( "textAlpha" ), "VALUE", "64" );

		IupSetAttribute( IupGetHandle( "btnBrace_FG" ), "FGCOLOR", "255 0 0" );					IupSetFocus( IupGetHandle( "btnBrace_FG" ) );
		IupSetAttribute( IupGetHandle( "btnBrace_BG" ), "FGCOLOR", "0 255 0" );					IupSetFocus( IupGetHandle( "btnBrace_BG" ) );
		IupSetAttribute( IupGetHandle( "btnError_FG" ), "FGCOLOR", "102 69 3" );				IupSetFocus( IupGetHandle( "btnError_FG" ) );
		IupSetAttribute( IupGetHandle( "btnError_BG" ), "FGCOLOR", "255 200 227" );				IupSetFocus( IupGetHandle( "btnError_BG" ) );
		IupSetAttribute( IupGetHandle( "btnWarning_FG" ), "FGCOLOR", "0 0 255" );				IupSetFocus( IupGetHandle( "btnWarning_FG" ) );
		IupSetAttribute( IupGetHandle( "btnWarning_BG" ), "FGCOLOR", "255 255 157" );			IupSetFocus( IupGetHandle( "btnWarning_BG" ) );


		IupSetAttribute( IupGetHandle( "btn_Scintilla_FG" ), "FGCOLOR", "0 0 0" );				IupSetFocus( IupGetHandle( "btn_Scintilla_FG" ) );
		IupSetAttribute( IupGetHandle( "btn_Scintilla_BG" ), "FGCOLOR", "255 255 255" );		IupSetFocus( IupGetHandle( "btn_Scintilla_BG" ) );

		IupSetAttribute( IupGetHandle( "btnSCE_B_COMMENT_FG" ), "FGCOLOR", "0 128 0" );			IupSetFocus( IupGetHandle( "btnSCE_B_COMMENT_FG" ) );
		IupSetAttribute( IupGetHandle( "btnSCE_B_COMMENT_BG" ), "FGCOLOR", "255 255 255" );		IupSetFocus( IupGetHandle( "btnSCE_B_COMMENT_BG" ) );
		IupSetAttribute( IupGetHandle( "btnSCE_B_NUMBER_FG" ), "FGCOLOR", "128 128 64" );		IupSetFocus( IupGetHandle( "btnSCE_B_NUMBER_FG" ) );
		IupSetAttribute( IupGetHandle( "btnSCE_B_NUMBER_BG" ), "FGCOLOR", "255 255 255" );		IupSetFocus( IupGetHandle( "btnSCE_B_NUMBER_BG" ) );
		IupSetAttribute( IupGetHandle( "btnSCE_B_STRING_FG" ), "FGCOLOR", "128 0 0" );			IupSetFocus( IupGetHandle( "btnSCE_B_STRING_FG" ) );
		IupSetAttribute( IupGetHandle( "btnSCE_B_STRING_BG" ), "FGCOLOR", "255 255 255" );		IupSetFocus( IupGetHandle( "btnSCE_B_STRING_BG" ) );
		IupSetAttribute( IupGetHandle( "btnSCE_B_PREPROCESSOR_FG" ), "FGCOLOR", "0 0 255" );	IupSetFocus( IupGetHandle( "btnSCE_B_PREPROCESSOR_FG" ) );
		IupSetAttribute( IupGetHandle( "btnSCE_B_PREPROCESSOR_BG" ), "FGCOLOR", "255 255 255" );IupSetFocus( IupGetHandle( "btnSCE_B_PREPROCESSOR_BG" ) );
		IupSetAttribute( IupGetHandle( "btnSCE_B_OPERATOR_FG" ), "FGCOLOR", "160 20 20" );		IupSetFocus( IupGetHandle( "btnSCE_B_OPERATOR_FG" ) );
		IupSetAttribute( IupGetHandle( "btnSCE_B_OPERATOR_BG" ), "FGCOLOR", "255 255 255" );	IupSetFocus( IupGetHandle( "btnSCE_B_OPERATOR_BG" ) );
		IupSetAttribute( IupGetHandle( "btnSCE_B_IDENTIFIER_FG" ), "FGCOLOR", "0 0 0" );		IupSetFocus( IupGetHandle( "btnSCE_B_IDENTIFIER_FG" ) );
		IupSetAttribute( IupGetHandle( "btnSCE_B_IDENTIFIER_BG" ), "FGCOLOR", "255 255 255" );	IupSetFocus( IupGetHandle( "btnSCE_B_IDENTIFIER_BG" ) );
		IupSetAttribute( IupGetHandle( "btnSCE_B_COMMENTBLOCK_FG" ), "FGCOLOR", "0 128 0" );	IupSetFocus( IupGetHandle( "btnSCE_B_COMMENTBLOCK_FG" ) );
		IupSetAttribute( IupGetHandle( "btnSCE_B_COMMENTBLOCK_BG" ), "FGCOLOR", "255 255 255" );IupSetFocus( IupGetHandle( "btnSCE_B_COMMENTBLOCK_BG" ) );
		
		IupSetAttribute( IupGetHandle( "btnPrj_FG" ), "FGCOLOR", "0 0 0" );						IupSetFocus( IupGetHandle( "btnPrj_FG" ) );
		IupSetAttribute( IupGetHandle( "btnPrj_BG" ), "FGCOLOR", "255 255 255" );				IupSetFocus( IupGetHandle( "btnPrj_BG" ) );
		IupSetAttribute( IupGetHandle( "btnOutline_FG" ), "FGCOLOR", "0 0 0" );					IupSetFocus( IupGetHandle( "btnOutline_FG" ) );
		IupSetAttribute( IupGetHandle( "btnOutline_BG" ), "FGCOLOR", "255 255 255" );			IupSetFocus( IupGetHandle( "btnOutline_BG" ) );
		IupSetAttribute( IupGetHandle( "btnFilelist_FG" ), "FGCOLOR", "0 0 0" );				IupSetFocus( IupGetHandle( "btnFilelist_FG" ) );
		IupSetAttribute( IupGetHandle( "btnFilelist_BG" ), "FGCOLOR", "255 255 255" );			IupSetFocus( IupGetHandle( "btnFilelist_BG" ) );
		IupSetAttribute( IupGetHandle( "btnOutput_FG" ), "FGCOLOR", "0 0 0" );					IupSetFocus( IupGetHandle( "btnOutput_FG" ) );
		IupSetAttribute( IupGetHandle( "btnOutput_BG" ), "FGCOLOR", "255 255 255" );			IupSetFocus( IupGetHandle( "btnOutput_BG" ) );
		IupSetAttribute( IupGetHandle( "btnSearch_FG" ), "FGCOLOR", "0 0 0" );					IupSetFocus( IupGetHandle( "btnSearch_FG" ) );
		IupSetAttribute( IupGetHandle( "btnSearch_BG" ), "FGCOLOR", "255 255 255" );			IupSetFocus( IupGetHandle( "btnSearch_BG" ) );
		
		IupSetAttribute( IupGetHandle( "btnPrjTitle" ), "FGCOLOR", "128 0 0" );					IupSetFocus( IupGetHandle( "btnPrjTitle" ) );
		IupSetAttribute( IupGetHandle( "btnSourceTypeFolder" ), "FGCOLOR", "0 0 255" );			IupSetFocus( IupGetHandle( "btnSourceTypeFolder" ) );

		// Keyword Default
		for( int i = 42; i < 46; i ++ )
			if( PreferenceDialogParameters.kbg[i] is null ) PreferenceDialogParameters.kbg[i] = new IupString;
			
		PreferenceDialogParameters.kbg[42] = cast(char[]) "5 91 35";
		PreferenceDialogParameters.kbg[43] = cast(char[]) "0 0 255";
		PreferenceDialogParameters.kbg[44] = cast(char[]) "231 144 0";
		PreferenceDialogParameters.kbg[45] = cast(char[]) "16 108 232";

		IupSetAttribute( IupGetHandle( "btnKeyWord0Color" ), "FGCOLOR", PreferenceDialogParameters.kbg[42].toCString );	IupSetFocus( IupGetHandle( "btnKeyWord0Color" ) );
		IupSetAttribute( IupGetHandle( "btnKeyWord1Color" ), "FGCOLOR", PreferenceDialogParameters.kbg[43].toCString );	IupSetFocus( IupGetHandle( "btnKeyWord1Color" ) );
		IupSetAttribute( IupGetHandle( "btnKeyWord2Color" ), "FGCOLOR", PreferenceDialogParameters.kbg[44].toCString );	IupSetFocus( IupGetHandle( "btnKeyWord2Color" ) );
		IupSetAttribute( IupGetHandle( "btnKeyWord3Color" ), "FGCOLOR", PreferenceDialogParameters.kbg[45].toCString );	IupSetFocus( IupGetHandle( "btnKeyWord3Color" ) );
		
		
		IupSetAttribute( IupGetHandle( "btnIndicator" ), "FGCOLOR", "0 128 0" );				IupSetFocus( IupGetHandle( "btnIndicator" ) );
		version(Windows)
			IupSetAttribute( IupGetHandle( "textIndicatorAlpha" ), "SPINVALUE", "80" );
		else
			IupSetAttribute( IupGetHandle( "textIndicatorAlpha" ), "VALUE", "80" );			


		for( int i = 48; i < 50; i ++ )
			if( PreferenceDialogParameters.kbg[i] is null ) PreferenceDialogParameters.kbg[i] = new IupString;
		PreferenceDialogParameters.kbg[48] = cast(char[]) "255 0 0";
		PreferenceDialogParameters.kbg[49] = cast(char[]) "0 255 0";
		IupSetAttribute( IupGetHandle( "btnKeyWord4Color" ), "FGCOLOR", PreferenceDialogParameters.kbg[48].toCString );	IupSetFocus( IupGetHandle( "btnKeyWord4Color" ) );
		IupSetAttribute( IupGetHandle( "btnKeyWord5Color" ), "FGCOLOR", PreferenceDialogParameters.kbg[49].toCString );	IupSetFocus( IupGetHandle( "btnKeyWord5Color" ) );


		
		
		IupSetAttribute( IupGetHandle( "colorTemplateList" ), "VALUE", "" );
		//GLOBAL.colorTemplate = cast(char[]) "";
	
		return IUP_DEFAULT;
	}

	/*
	version(Windows)
	{
		private int memberButton(Ihandle* ih, int button, int pressed, int x, int y, char* status)//( Ihandle *ih, char *text, int item, int state )
		{
			if( button == IUP_BUTTON1 && pressed == 1 ) // IUP_BUTTON1 = '1' = 49
			{
				if( PreferenceDialogParameters.fontTable !is null )
				{
					int item = IupConvertXYToPos( ih, x, y );
					PreferenceDialogParameters.fontTable.setSelectionID( item );
				}
			}
			
			return IUP_DEFAULT;
		}
	}
	
	
	private int memberSelect( Ihandle *ih, char *text, int item, int state )
	{
		if( PreferenceDialogParameters.fontTable !is null )
			
			PreferenceDialogParameters.fontTable.setSelectionID( item );
		
		return IUP_DEFAULT;
	}
	*/
	
	private int memberDoubleClick( Ihandle* ih, int item, char* text )
	{
		try
		{
			char[][] listString = PreferenceDialogParameters.fontTable.getSelection( item );
			
			if( listString.length == 4 )
			{
				char[] _font = listString[1] ~ "," ~ listString[2] ~ listString[3];
				Ihandle* dlg = IupFontDlg();
				if( dlg == null )
				{
					IupMessage( "Error", toStringz( "IupFontDlg created fail!" ) );
					return IUP_IGNORE;
				}

				IupSetAttribute( dlg, "VALUE", toStringz( _font ) );
				IupPopup( dlg, IUP_CURRENT, IUP_CURRENT );			
				
				if( IupGetInt( dlg, "STATUS" ) == 1 )
				{
					char[] fontInformation = fromStringz( IupGetAttribute( dlg, "VALUE" ) ).dup;
					char[] size, style;
					char[][] strings = Util.split( fontInformation, "," );
					
					if( strings.length == 2 )
					{
						if( !strings[0].length )
						{
							version( Windows ) strings[0] = "Courier New"; else	strings[0] = "Monospace";
						}
						else
						{
							strings[0] = Util.trim( strings[0] ).dup;
						}
						
						int spacePos = Util.rindex( strings[1], " " );
						if( spacePos < strings[1].length )
						{
							size = strings[1][spacePos+1..$].dup;
							style = Util.trim( strings[1][0..spacePos] );
							if( !style.length ) style = " "; else style = " " ~ style ~ " ";
						}
						
						PreferenceDialogParameters.fontTable.setItem( [ listString[0], strings[0], style, size ], item );
					}
					else
					{
						version(linux)
						{
							int spaceTailPos = Util.rindex( fontInformation, " " );
							if( spaceTailPos < fontInformation.length )
							{
								size = fontInformation[spaceTailPos+1..$].dup;
								char[] fontName;
								foreach( char[] s; Util.split( fontInformation[0..spaceTailPos].dup, " " ) )
								{
									switch( s )
									{
										case "Bold":		style ~= "Bold "; break;
										case "Italic":		style ~= "Italic "; break;
										case "Underline":	style ~= "Underline "; break;
										case "Strikeout":	style ~= "Strikeout "; break;
										default:
											fontName = fontName ~ s ~ " ";
									}
								}
								
								fontName = Util.trim( fontName ).dup;
								style = Util.trim( style ).dup;
								if( !style.length ) style = " "; else style = " " ~ style ~ " ";
								PreferenceDialogParameters.fontTable.setItem( [ listString[0], fontName, style, size ], item );
							}
						}					
					}
				}
			}
		}
		catch( Exception e )
		{
			debug IupMessage( "doubleClick", toStringz( e.toString() ) );
		}
	
		return IUP_DEFAULT;
	}
	
	private int valDWELL_VALUECHANGED_CB( Ihandle *ih )
	{
		float valuef = IupGetFloat( ih, "VALUE" );
		int value = ( cast(int) valuef / 100 ) * 100;
		
		//IupSetInt( ih, "VALUE", value );
		IupSetAttribute( ih, "TIP", toStringz( Integer.toString( value ) ) );
		
		return IUP_DEFAULT;
	}
}