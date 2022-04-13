module dialogs.preferenceDlg;

private import iup.iup, iup.iup_scintilla;

private import layouts.table;

private import global, menu, IDE, project, tools, scintilla, actionManager, parser.autocompletion;;
private import dialogs.baseDlg, dialogs.helpDlg, dialogs.fileDlg, dialogs.shortcutDlg;

private import tango.stdc.stringz, tango.io.Stdout, tango.io.FilePath, Util = tango.text.Util;

private struct PreferenceDialogParameters
{
	static		IupString[60]		kbg, stringSC;
	static		CTable				fontTable;
}



class CPreferenceDialog : CBaseDialog
{
	private:

	void createLayout()
	{
		Ihandle* bottom = createDlgButton( "40x12", "aoc" );

		Ihandle* textCompilerPath = IupText( null );
		IupSetAttributes( textCompilerPath, "SIZE=320x,NAME=Compiler-compilerPath" );
		IupSetStrAttribute( textCompilerPath, "VALUE", toStringz( GLOBAL.compilerFullPath ) );
		
		Ihandle* btnOpen = IupButton( null, null );
		IupSetAttribute( btnOpen, "IMAGE", "icon_openfile" );
		IupSetCallback( btnOpen, "ACTION", cast(Icallback) &CPreferenceDialog_OpenAppBinFile_cb );
		
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
				IupSetAttributes( textx64CompilerPath, "SIZE=320x,NAME=Compiler-x64compilerPath" );
				IupSetStrAttribute( textx64CompilerPath, "VALUE", toStringz( GLOBAL.x64compilerFullPath ) );
				
				Ihandle* btnx64Open = IupButton( null, null );
				IupSetAttribute( btnx64Open, "IMAGE", "icon_openfile" );
				IupSetCallback( btnx64Open, "ACTION", cast(Icallback) &CPreferenceDialog_OpenAppBinFile_cb );
				
				Ihandle* _hBox01x64 = IupHbox( textx64CompilerPath, btnx64Open, null );
				IupSetAttributes( _hBox01x64, "ALIGNMENT=ACENTER,MARGIN=5x0" );
				
				hBox01x64 = IupFrame( _hBox01x64 );
				IupSetAttribute( hBox01x64, "TITLE", GLOBAL.languageItems["x64path"].toCString );
				IupSetAttributes( hBox01x64, "EXPANDCHILDREN=YES,SIZE=346x");
				
				
				Ihandle* textx64DebuggerPath = IupText( null );
				IupSetAttributes( textx64DebuggerPath, "SIZE=320x,NAME=Compiler-x64DebuggerPath" );
				IupSetStrAttribute( textx64DebuggerPath, "VALUE", toStringz( GLOBAL.x64debuggerFullPath ) );
				
				Ihandle* btnOpenx64Debugger = IupButton( null, null );
				IupSetAttributes( btnOpenx64Debugger, "IMAGE=icon_openfile,NAME=x64" );
				IupSetCallback( btnOpenx64Debugger, "ACTION", cast(Icallback) &CPreferenceDialog_OpenAppBinFile_cb );
				
				Ihandle* _hBox02x64 = IupHbox( textx64DebuggerPath, btnOpenx64Debugger, null );
				IupSetAttributes( _hBox02x64, "ALIGNMENT=ACENTER,MARGIN=5x0" );
				
				hBox02x64 = IupFrame( _hBox02x64 );
				IupSetAttribute( hBox02x64, "TITLE", GLOBAL.languageItems["debugx64path"].toCString );
				IupSetAttributes( hBox02x64, "EXPANDCHILDREN=YES,SIZE=346x");
			}


			Ihandle* textDebuggerPath = IupText( null );
			IupSetAttributes( textDebuggerPath, "SIZE=320x,NAME=Compiler-debuggerPath" );
			IupSetStrAttribute( textDebuggerPath, "VALUE", toStringz( GLOBAL.debuggerFullPath ) );
			IupSetHandle( "debuggerPath_Handle", textDebuggerPath );
			
			Ihandle* btnOpenDebugger = IupButton( null, null );
			IupSetAttributes( btnOpenDebugger, "IMAGE=icon_openfile,NAME=x86" );
			IupSetCallback( btnOpenDebugger, "ACTION", cast(Icallback) &CPreferenceDialog_OpenAppBinFile_cb );
			
			Ihandle* _hBox02 = IupHbox( textDebuggerPath, btnOpenDebugger, null );
			IupSetAttributes( _hBox02, "ALIGNMENT=ACENTER,MARGIN=5x0" );
			
			hBox02 = IupFrame( _hBox02 );
			IupSetAttribute( hBox02, "TITLE", GLOBAL.languageItems["debugpath"].toCString );
			IupSetAttributes( hBox02, "EXPANDCHILDREN=YES,SIZE=346x");			
		}
		
		version(linux)
		{
			Ihandle* textTerminalPath = IupText( null );
			IupSetAttributes( textTerminalPath, "SIZE=320x,NAME=Compiler-textTerminalPath" );
			IupSetStrAttribute( textTerminalPath, "VALUE", toStringz( GLOBAL.linuxTermName ) );
		
			Ihandle* btnOpenTerminal = IupButton( null, null );
			IupSetAttribute( btnOpenTerminal, "IMAGE", "icon_openfile" );
			IupSetCallback( btnOpenTerminal, "ACTION", cast(Icallback) &CPreferenceDialog_OpenAppBinFile_cb );
			
			Ihandle* _hBox03 = IupHbox( textTerminalPath, btnOpenTerminal, null );
			IupSetAttributes( _hBox03, "ALIGNMENT=ACENTER,MARGIN=5x0" );
			
			Ihandle* hBox03 = IupFrame( _hBox03 );
			IupSetAttribute( hBox03, "TITLE", GLOBAL.languageItems["terminalpath"].toCString );
			IupSetAttributes( hBox03, "EXPANDCHILDREN=YES,SIZE=346x");			
		}		
		
		/+
		// Dummy
		Ihandle* toggleDummy = IupFlatToggle( GLOBAL.languageItems["errorannotation"].toCString );		
		IupSetAttribute( toggleDummy, "VALUE", toStringz(GLOBAL.toggleDummy) );
		IupSetHandle( "toggleDummy", toggleDummy );
		+/

		// compiler Setting
		Ihandle* toggleAnnotation = IupFlatToggle( GLOBAL.languageItems["errorannotation"].toCString );
		IupSetStrAttribute( toggleAnnotation, "VALUE", toStringz(GLOBAL.compilerAnootation) );
		IupSetHandle( "toggleAnnotation", toggleAnnotation );

		Ihandle* toggleShowResultWindow = IupFlatToggle( GLOBAL.languageItems["showresultwindow"].toCString );
		IupSetStrAttribute( toggleShowResultWindow, "VALUE", toStringz(GLOBAL.compilerWindow) );
		IupSetHandle( "toggleShowResultWindow", toggleShowResultWindow );
		
		Ihandle* toggleSFX = IupFlatToggle( GLOBAL.languageItems["usesfx"].toCString );
		IupSetStrAttribute( toggleSFX, "VALUE", toStringz(GLOBAL.compilerSFX) );
		IupSetHandle( "toggleSFX", toggleSFX );

		Ihandle* toggleDelPrevEXE = IupFlatToggle( GLOBAL.languageItems["delexistexe"].toCString );
		IupSetStrAttribute( toggleDelPrevEXE, "VALUE", toStringz(GLOBAL.delExistExe) );
		IupSetHandle( "toggleDelPrevEXE", toggleDelPrevEXE );
		
		Ihandle* toggleConsoleExe = IupFlatToggle( GLOBAL.languageItems["consoleexe"].toCString );
		IupSetStrAttribute( toggleConsoleExe, "VALUE", toStringz(GLOBAL.consoleExe) );
		IupSetHandle( "toggleConsoleExe", toggleConsoleExe );
		
		Ihandle* toggleCompileAtBackThread = IupFlatToggle( GLOBAL.languageItems["compileatbackthread"].toCString );
		IupSetStrAttribute( toggleCompileAtBackThread, "VALUE", toStringz(GLOBAL.toggleCompileAtBackThread) );
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
		
		/*
		PreferenceDialogParameters.stringMonitor[0] = new IupString( Integer.toString( GLOBAL.consoleWindow.id + 1 ) );
		PreferenceDialogParameters.stringMonitor[1] = new IupString( Integer.toString( GLOBAL.consoleWindow.x ) );
		PreferenceDialogParameters.stringMonitor[2] = new IupString( Integer.toString( GLOBAL.consoleWindow.y ) );
		PreferenceDialogParameters.stringMonitor[3] = new IupString( Integer.toString( GLOBAL.consoleWindow.w ) );
		PreferenceDialogParameters.stringMonitor[4] = new IupString( Integer.toString( GLOBAL.consoleWindow.h ) );
		*/
		IupSetStrAttribute( textMonitorID, "VALUE", toStringz( Integer.toString( GLOBAL.consoleWindow.id + 1 ) ) );
		IupSetStrAttribute( textConsoleX, "VALUE", toStringz( Integer.toString( GLOBAL.consoleWindow.x ) ) );
		IupSetStrAttribute( textConsoleY, "VALUE", toStringz( Integer.toString( GLOBAL.consoleWindow.y ) ) );
		IupSetStrAttribute( textConsoleW, "VALUE", toStringz( Integer.toString( GLOBAL.consoleWindow.w ) ) );
		IupSetStrAttribute( textConsoleH, "VALUE", toStringz( Integer.toString( GLOBAL.consoleWindow.h ) ) );
		
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
		Ihandle* toggleKeywordComplete = IupFlatToggle( GLOBAL.languageItems["enablekeyword"].toCString );
		IupSetStrAttribute( toggleKeywordComplete, "VALUE", toStringz(GLOBAL.enableKeywordComplete) );
		IupSetHandle( "toggleKeywordComplete", toggleKeywordComplete );
		
		Ihandle* toggleIncludeComplete = IupFlatToggle( GLOBAL.languageItems["enableinclude"].toCString );
		IupSetStrAttribute( toggleIncludeComplete, "VALUE", toStringz(GLOBAL.enableIncludeComplete) );
		IupSetHandle( "toggleIncludeComplete", toggleIncludeComplete );
		
		
		//*******************
		Ihandle* toggleUseParser = IupFlatToggle( GLOBAL.languageItems["enableparser"].toCString );
		IupSetStrAttribute( toggleUseParser, "VALUE", toStringz(GLOBAL.enableParser) );
		IupSetHandle( "toggleUseParser", toggleUseParser );
		
		Ihandle* labelMaxHeight = IupLabel( GLOBAL.languageItems["autocmaxheight"].toCString );
		IupSetAttributes( labelMaxHeight, "SIZE=120x12,ALIGNMENT=ARIGHT:ACENTER" );
		
		Ihandle* textMaxHeight = IupText( null );
		IupSetAttribute( textMaxHeight, "SIZE", "56x12" );
		IupSetStrAttribute( textMaxHeight, "VALUE", toStringz( Integer.toString( GLOBAL.autoCMaxHeight ) ) );
		IupSetHandle( "textMaxHeight", textMaxHeight );

		Ihandle* hBoxUseParser = IupHbox( toggleUseParser, IupFill, labelMaxHeight, textMaxHeight, null );
		IupSetAttribute( hBoxUseParser, "ALIGNMENT", "ACENTER" );
		//********************
		
		
		Ihandle* labelTrigger = IupLabel( GLOBAL.languageItems["trigger"].toCString );
		IupSetAttributes( labelTrigger, "SIZE=120x12" );
		
		Ihandle* textTrigger = IupText( null );
		IupSetAttribute( textTrigger, "SIZE", "30x12" );
		IupSetAttribute( textTrigger, "TIP", GLOBAL.languageItems["triggertip"].toCString );
		IupSetStrAttribute( textTrigger, "VALUE", toStringz( Integer.toString( GLOBAL.autoCompletionTriggerWordCount ) ) );
		IupSetHandle( "textTrigger", textTrigger );
		
		version(FBIDE)
		{
			Ihandle* labelIncludeLevel = IupLabel( GLOBAL.languageItems["includelevel"].toCString );
			IupSetAttributes( labelIncludeLevel, "SIZE=120x12,GAP=0" );

			Ihandle* textIncludeLevel = IupText( null );
			IupSetAttribute( textIncludeLevel, "SIZE", "30x12" );
			IupSetAttribute( textIncludeLevel, "TIP", GLOBAL.languageItems["includeleveltip"].toCString );
			IupSetStrAttribute( textIncludeLevel, "VALUE", toStringz( Integer.toString( GLOBAL.includeLevel ) ) );
			IupSetHandle( "textIncludeLevel", textIncludeLevel );
		}

		
		Ihandle* toggleWithParams = IupFlatToggle( GLOBAL.languageItems["showtypeparam"].toCString );
		IupSetStrAttribute( toggleWithParams, "VALUE", toStringz(GLOBAL.showTypeWithParams) );
		IupSetHandle( "toggleWithParams", toggleWithParams );

		Ihandle* toggleIGNORECASE = IupFlatToggle( GLOBAL.languageItems["sortignorecase"].toCString );
		IupSetStrAttribute( toggleIGNORECASE, "VALUE", toStringz(GLOBAL.toggleIgnoreCase) );
		IupSetHandle( "toggleIGNORECASE", toggleIGNORECASE );

		Ihandle* toggleCASEINSENSITIVE = IupFlatToggle( GLOBAL.languageItems["selectcase"].toCString );
		IupSetStrAttribute( toggleCASEINSENSITIVE, "VALUE", toStringz(GLOBAL.toggleCaseInsensitive) );
		IupSetHandle( "toggleCASEINSENSITIVE", toggleCASEINSENSITIVE );

		Ihandle* toggleSHOWLISTTYPE = IupFlatToggle( GLOBAL.languageItems["showlisttype"].toCString );
		IupSetStrAttribute( toggleSHOWLISTTYPE, "VALUE", toStringz(GLOBAL.toggleShowListType) );
		IupSetHandle( "toggleSHOWLISTTYPE", toggleSHOWLISTTYPE );

		Ihandle* toggleSHOWALLMEMBER = IupFlatToggle( GLOBAL.languageItems["showallmembers"].toCString );
		IupSetStrAttribute( toggleSHOWALLMEMBER, "VALUE", toStringz(GLOBAL.toggleShowAllMember) );
		IupSetHandle( "toggleSHOWALLMEMBER", toggleSHOWALLMEMBER );
		
		Ihandle* toggleDWELL = IupFlatToggle( GLOBAL.languageItems["enabledwell"].toCString );
		IupSetStrAttribute( toggleDWELL, "VALUE", toStringz(GLOBAL.toggleEnableDwell) );
		IupSetHandle( "toggleDWELL", toggleDWELL );
		
		Ihandle* labelDWELL = IupLabel( GLOBAL.languageItems["dwelldelay"].toCString );
		Ihandle* valDWELL = IupVal( null );
		IupSetAttributes( valDWELL, "MIN=200,MAX=2200,RASTERSIZE=100x16,STEP=0.05,PAGESTEP=0.05" );
		IupSetStrAttribute( valDWELL, "VALUE", toStringz( GLOBAL.dwellDelay ) );
		IupSetHandle( "valDWELL", valDWELL );
		IupSetCallback( valDWELL, "VALUECHANGED_CB", cast(Icallback) &valDWELL_VALUECHANGED_CB );
		IupSetCallback( valDWELL, "ENTERWINDOW_CB", cast(Icallback) &valDWELL_VALUECHANGED_CB );
		
		
		Ihandle* hBoxDWELL = IupHbox( toggleDWELL, IupFill, labelDWELL, valDWELL, null );
		IupSetAttributes( hBoxDWELL, "ALIGNMENT=ACENTER" );
		

		Ihandle* toggleOverWrite = IupFlatToggle( GLOBAL.languageItems["enableoverwrite"].toCString );
		IupSetStrAttribute( toggleOverWrite, "VALUE", toStringz(GLOBAL.toggleOverWrite) );
		IupSetHandle( "toggleOverWrite", toggleOverWrite );

		Ihandle* toggleBackThread = IupFlatToggle( GLOBAL.languageItems["completeatbackthread"].toCString );
		IupSetStrAttribute( toggleBackThread, "VALUE", toStringz(GLOBAL.toggleCompleteAtBackThread) );
		IupSetHandle( "toggleBackThread", toggleBackThread );
		
		Ihandle* labelTriggerDelay = IupLabel( GLOBAL.languageItems["completedelay"].toCString );
		Ihandle* valTriggerDelay = IupVal( null );
		IupSetAttributes( valTriggerDelay, "MIN=1,MAX=1000,RASTERSIZE=100x16,STEP=0.1,PAGESTEP=0.1" );
		IupSetStrAttribute( valTriggerDelay, "VALUE", toStringz( GLOBAL.triggerDelay ) );
		IupSetHandle( "valTriggerDelay", valTriggerDelay );
		IupSetCallback( valTriggerDelay, "VALUECHANGED_CB", cast(Icallback) &valTriggerDelay_VALUECHANGED_CB );
		IupSetCallback( valTriggerDelay, "ENTERWINDOW_CB", cast(Icallback) &valTriggerDelay_VALUECHANGED_CB );	
		
		Ihandle* hBoxTriggerDelay = IupHbox( toggleBackThread, IupFill, labelTriggerDelay, valTriggerDelay, null );
		IupSetAttributes( hBoxTriggerDelay, "ALIGNMENT=ACENTER" );
		
		
		Ihandle* toggleFunctionTitle = IupFlatToggle( GLOBAL.languageItems["showtitle"].toCString );
		IupSetStrAttribute( toggleFunctionTitle, "VALUE", toStringz(GLOBAL.showFunctionTitle) );
		IupSetHandle( "toggleFunctionTitle", toggleFunctionTitle );

		Ihandle* labelPreParseLevel = IupLabel( GLOBAL.languageItems["preparselevel"].toCString );
		Ihandle* valPreParseLevel = IupVal( null );
		IupSetAttributes( valPreParseLevel, "MIN=0,MAX=5,RASTERSIZE=50x16,STEP=0.1,PAGESTEP=0.1" );
		IupSetStrAttribute( valPreParseLevel, "VALUE", toStringz( Integer.toString( GLOBAL.preParseLevel ) ) );
		IupSetHandle( "valPreParseLevel", valPreParseLevel );
		IupSetCallback( valPreParseLevel, "VALUECHANGED_CB", cast(Icallback) &valTriggerDelay_VALUECHANGED_CB );
		IupSetCallback( valPreParseLevel, "ENTERWINDOW_CB", cast(Icallback) &valTriggerDelay_VALUECHANGED_CB );	

		Ihandle* hBoxPreParseLevel = IupHbox( toggleFunctionTitle, IupFill, labelPreParseLevel, valPreParseLevel, null );
		IupSetAttributes( hBoxPreParseLevel, "ALIGNMENT=ACENTER" );



		Ihandle* toggleLiveNone = IupFlatToggle( GLOBAL.languageItems["none"].toCString );
		IupSetHandle( "toggleLiveNone", toggleLiveNone );

		Ihandle* toggleLiveLight = IupFlatToggle( GLOBAL.languageItems["light"].toCString );
		IupSetHandle( "toggleLiveLight", toggleLiveLight );
		
		Ihandle* toggleLiveFull = IupFlatToggle( GLOBAL.languageItems["full"].toCString );
		IupSetHandle( "toggleLiveFull", toggleLiveFull );
		//IupSetAttribute( toggleLiveFull, "ACTIVE", "NO" );

		Ihandle* toggleUpdateOutline = IupFlatToggle( GLOBAL.languageItems["update"].toCString );
		IupSetAttribute( toggleUpdateOutline, "VALUE", toStringz(GLOBAL.toggleUpdateOutlineLive.dup) );
		//IupSetAttribute( toggleUpdateOutline, "ACTIVE", "NO" );
		IupSetHandle( "toggleUpdateOutline", toggleUpdateOutline );

		Ihandle* hBoxLive = IupHbox( toggleLiveNone, toggleLiveLight, toggleLiveFull, null );
		IupSetAttributes( hBoxLive, "ALIGNMENT=ACENTER,NORMALIZESIZE=HORIZONTAL,HOMOGENEOUS=YES" );
		Ihandle* radioLive = IupRadio( hBoxLive );

		Ihandle* hBoxLive2 = IupHbox( radioLive, toggleUpdateOutline, null );
		IupSetAttributes( hBoxLive2, "GAP=30,MARGIN=10x,ALIGNMENT=ACENTER" );
		//IupSetAttributes( hBoxLive2, "ALIGNMENT=ACENTER,NORMALIZESIZE=HORIZONTAL,HOMOGENEOUS=YES,EXPANDCHILDREN=YES" );
		
		Ihandle* frameLive = IupFrame( hBoxLive2 );
		IupSetAttributes( frameLive, "SIZE=346x" );
		IupSetAttribute( frameLive, "TITLE", GLOBAL.languageItems["parserlive"].toCString );

		switch( GLOBAL.liveLevel )
		{
			case 1:		IupSetAttribute( toggleLiveLight, "VALUE", "ON" ); break;
			case 2:		IupSetAttribute( toggleLiveFull, "VALUE", "ON" ); break;
			default:	IupSetAttribute( toggleLiveNone, "VALUE", "ON" ); break;
		}



		version(FBIDE)	Ihandle* hBox00 = IupHbox( labelTrigger, textTrigger, labelIncludeLevel, textIncludeLevel, null );
		version(DIDE)	Ihandle* hBox00 = IupHbox( labelTrigger, textTrigger, null );
		
		Ihandle* vBox00 = IupVbox( hBoxUseParser, toggleKeywordComplete, toggleIncludeComplete, toggleWithParams, toggleIGNORECASE, toggleCASEINSENSITIVE, toggleSHOWLISTTYPE, toggleSHOWALLMEMBER, hBoxDWELL, toggleOverWrite, hBoxTriggerDelay, hBoxPreParseLevel, hBox00, null );
		IupSetAttributes( vBox00, "GAP=10,MARGIN=0x1,EXPANDCHILDREN=NO" );
		
	
		Ihandle* frameParser = IupFrame( vBox00 );
		IupSetAttribute( frameParser, "TITLE",  GLOBAL.languageItems["parsersetting"].toCString );
		IupSetAttribute( frameParser, "EXPANDCHILDREN", "YES");
		IupSetAttribute( frameParser, "SIZE", "346x");


		
		Ihandle* vBoxParserSettings = IupVbox( frameParser, frameLive, null );
		IupSetAttributes( vBoxParserSettings, "ALIGNMENT=ALEFT,MARGIN=2x5");
		IupSetAttribute( vBoxParserSettings, "EXPANDCHILDREN", "YES");
		
		
		
		
		Ihandle* toggleLineMargin = IupFlatToggle( GLOBAL.languageItems["lnmargin"].toCString );
		IupSetStrAttribute( toggleLineMargin, "VALUE", toStringz(GLOBAL.editorSetting00.LineMargin) );
		IupSetAttribute( toggleLineMargin, "ALIGNMENT", "ALEFT:ACENTER" );
		IupSetHandle( "toggleLineMargin", toggleLineMargin );
		
		Ihandle* toggleFixedLineMargin = IupFlatToggle( GLOBAL.languageItems["fixedlnmargin"].toCString );
		IupSetStrAttribute( toggleFixedLineMargin, "VALUE", toStringz(GLOBAL.editorSetting00.FixedLineMargin) );
		IupSetAttribute( toggleFixedLineMargin, "ALIGNMENT", "ALEFT:ACENTER" );
		IupSetHandle( "toggleFixedLineMargin", toggleFixedLineMargin );
		
		Ihandle* toggleBookmarkMargin = IupFlatToggle( GLOBAL.languageItems["bkmargin"].toCString );
		IupSetStrAttribute( toggleBookmarkMargin, "VALUE", toStringz(GLOBAL.editorSetting00.BookmarkMargin) );
		IupSetAttribute( toggleBookmarkMargin, "ALIGNMENT", "ALEFT:ACENTER" );
		IupSetHandle( "toggleBookmarkMargin", toggleBookmarkMargin );
		
		Ihandle* toggleFoldMargin = IupFlatToggle( GLOBAL.languageItems["fdmargin"].toCString );
		IupSetStrAttribute( toggleFoldMargin, "VALUE", toStringz(GLOBAL.editorSetting00.FoldMargin) );
		IupSetAttribute( toggleFoldMargin, "ALIGNMENT", "ALEFT:ACENTER" );
		IupSetHandle( "toggleFoldMargin", toggleFoldMargin );
		
		Ihandle* toggleIndentGuide = IupFlatToggle(  GLOBAL.languageItems["indentguide"].toCString );
		IupSetStrAttribute( toggleIndentGuide, "VALUE", toStringz(GLOBAL.editorSetting00.IndentGuide) );
		IupSetAttribute( toggleIndentGuide, "ALIGNMENT", "ALEFT:ACENTER" );
		IupSetHandle( "toggleIndentGuide", toggleIndentGuide );
		
		Ihandle* toggleCaretLine = IupFlatToggle( GLOBAL.languageItems["showcaretline"].toCString );
		IupSetStrAttribute( toggleCaretLine, "VALUE", toStringz(GLOBAL.editorSetting00.CaretLine) );
		IupSetAttribute( toggleCaretLine, "ALIGNMENT", "ALEFT:ACENTER" );
		IupSetHandle( "toggleCaretLine", toggleCaretLine );
		
		Ihandle* toggleWordWrap = IupFlatToggle( GLOBAL.languageItems["wordwarp"].toCString );
		IupSetStrAttribute( toggleWordWrap, "VALUE", toStringz(GLOBAL.editorSetting00.WordWrap) );
		IupSetAttribute( toggleWordWrap, "ALIGNMENT", "ALEFT:ACENTER" );
		IupSetHandle( "toggleWordWrap", toggleWordWrap );
		
		Ihandle* toggleTabUseingSpace = IupFlatToggle( GLOBAL.languageItems["tabtospace"].toCString );
		IupSetStrAttribute( toggleTabUseingSpace, "VALUE", toStringz(GLOBAL.editorSetting00.TabUseingSpace) );
		IupSetAttribute( toggleTabUseingSpace, "ALIGNMENT", "ALEFT:ACENTER" );
		IupSetHandle( "toggleTabUseingSpace", toggleTabUseingSpace );
		
		Ihandle* toggleAutoIndent = IupFlatToggle( GLOBAL.languageItems["autoindent"].toCString );
		IupSetStrAttribute( toggleAutoIndent, "VALUE", toStringz(GLOBAL.editorSetting00.AutoIndent) );
		IupSetAttribute( toggleAutoIndent, "ALIGNMENT", "ALEFT:ACENTER" );
		IupSetHandle( "toggleAutoIndent", toggleAutoIndent );

		Ihandle* toggleShowEOL = IupFlatToggle( GLOBAL.languageItems["showeol"].toCString );
		IupSetStrAttribute( toggleShowEOL, "VALUE", toStringz(GLOBAL.editorSetting00.ShowEOL) );
		IupSetAttribute( toggleShowEOL, "ALIGNMENT", "ALEFT:ACENTER" );
		IupSetHandle( "toggleShowEOL", toggleShowEOL );

		Ihandle* toggleShowSpace = IupFlatToggle( GLOBAL.languageItems["showspacetab"].toCString );
		IupSetStrAttribute( toggleShowSpace, "VALUE", toStringz(GLOBAL.editorSetting00.ShowSpace) );
		IupSetAttribute( toggleShowSpace, "ALIGNMENT", "ALEFT:ACENTER" );
		IupSetHandle( "toggleShowSpace", toggleShowSpace );

		version(FBIDE)
		{
			Ihandle* toggleAutoEnd = IupFlatToggle( GLOBAL.languageItems["autoinsertend"].toCString );
			IupSetStrAttribute( toggleAutoEnd, "VALUE", toStringz(GLOBAL.editorSetting00.AutoEnd) );
			IupSetAttribute( toggleAutoEnd, "ALIGNMENT", "ALEFT:ACENTER" );
			IupSetHandle( "toggleAutoEnd", toggleAutoEnd );
		}
		
		Ihandle* toggleAutoClose = IupFlatToggle( GLOBAL.languageItems["autoclose"].toCString );
		IupSetStrAttribute( toggleAutoClose, "VALUE", toStringz(GLOBAL.editorSetting00.AutoClose) );
		IupSetAttribute( toggleAutoClose, "ALIGNMENT", "ALEFT:ACENTER" );
		IupSetHandle( "toggleAutoClose", toggleAutoClose );

		Ihandle* toggleColorOutline = IupFlatToggle( GLOBAL.languageItems["coloroutline"].toCString );
		IupSetStrAttribute( toggleColorOutline, "VALUE", toStringz(GLOBAL.editorSetting00.ColorOutline) );
		IupSetAttribute( toggleColorOutline, "ALIGNMENT", "ALEFT:ACENTER" );
		IupSetHandle( "toggleColorOutline", toggleColorOutline );		

		Ihandle* toggleBoldKeyword = IupFlatToggle( GLOBAL.languageItems["boldkeyword"].toCString );
		IupSetStrAttribute( toggleBoldKeyword, "VALUE", toStringz(GLOBAL.editorSetting00.BoldKeyword) );
		IupSetAttribute( toggleBoldKeyword, "ALIGNMENT", "ALEFT:ACENTER" );
		IupSetHandle( "toggleBoldKeyword", toggleBoldKeyword );
		
		Ihandle* toggleBraceMatch = IupFlatToggle( GLOBAL.languageItems["bracematchhighlight"].toCString );
		IupSetStrAttribute( toggleBraceMatch, "VALUE", toStringz(GLOBAL.editorSetting00.BraceMatchHighlight) );
		IupSetAttribute( toggleBraceMatch, "ALIGNMENT", "ALEFT:ACENTER" );
		IupSetHandle( "toggleBraceMatch", toggleBraceMatch );		

		Ihandle* toggleMultiSelection = IupFlatToggle( GLOBAL.languageItems["multiselection"].toCString );
		IupSetStrAttribute( toggleMultiSelection, "VALUE", toStringz(GLOBAL.editorSetting00.MultiSelection) );
		IupSetAttribute( toggleMultiSelection, "ALIGNMENT", "ALEFT:ACENTER" );
		IupSetHandle( "toggleMultiSelection", toggleMultiSelection );			

		Ihandle* toggleLoadprev = IupFlatToggle( GLOBAL.languageItems["loadprevdoc"].toCString );
		IupSetStrAttribute( toggleLoadprev, "VALUE", toStringz(GLOBAL.editorSetting00.LoadPrevDoc) );
		IupSetAttribute( toggleLoadprev, "ALIGNMENT", "ALEFT:ACENTER" );
		IupSetHandle( "toggleLoadprev", toggleLoadprev );			

		Ihandle* toggleCurrentWord = IupFlatToggle( GLOBAL.languageItems["hlcurrentword"].toCString );
		IupSetStrAttribute( toggleCurrentWord, "VALUE", toStringz(GLOBAL.editorSetting00.HighlightCurrentWord) );
		IupSetAttribute( toggleCurrentWord, "ALIGNMENT", "ALEFT:ACENTER" );
		IupSetHandle( "toggleCurrentWord", toggleCurrentWord );			

		Ihandle* toggleMiddleScroll = IupFlatToggle( GLOBAL.languageItems["middlescroll"].toCString );
		IupSetStrAttribute( toggleMiddleScroll, "VALUE", toStringz(GLOBAL.editorSetting00.MiddleScroll) );
		IupSetAttribute( toggleMiddleScroll, "ALIGNMENT", "ALEFT:ACENTER" );
		IupSetHandle( "toggleMiddleScroll", toggleMiddleScroll );
		
		Ihandle* toggleDocStatus = IupFlatToggle( GLOBAL.languageItems["savedocstatus"].toCString );
		IupSetStrAttribute( toggleDocStatus, "VALUE", toStringz(GLOBAL.editorSetting00.DocStatus) );
		IupSetAttribute( toggleDocStatus, "ALIGNMENT", "ALEFT:ACENTER" );
		IupSetHandle( "toggleDocStatus", toggleDocStatus );

		Ihandle* toggleLoadAtBackThread = IupFlatToggle( GLOBAL.languageItems["loadfileatbackthread"].toCString );
		IupSetAttribute( toggleLoadAtBackThread, "ALIGNMENT", "ALEFT:ACENTER" );
		version(BACKTHREAD)
		{
			IupSetStrAttribute( toggleLoadAtBackThread, "VALUE", toStringz(GLOBAL.editorSetting00.LoadAtBackThread) );
		}
		else
		{
			IupSetAttribute( toggleLoadAtBackThread, "VALUE", "OFF" );
			IupSetAttribute( toggleLoadAtBackThread, "ACTIVE", "NO" );
		}

		IupSetHandle( "toggleLoadAtBackThread", toggleLoadAtBackThread );
		
		Ihandle* toggleAutoKBLayout = IupFlatToggle( GLOBAL.languageItems["autokblayout"].toCString );
		IupSetStrAttribute( toggleAutoKBLayout, "VALUE", toStringz(GLOBAL.editorSetting00.AutoKBLayout) );
		IupSetAttribute( toggleAutoKBLayout, "ALIGNMENT", "ALEFT:ACENTER" );
		IupSetHandle( "toggleAutoKBLayout", toggleAutoKBLayout );
		
		version(FBIDE)
		{
			Ihandle* toggleQBCase = IupFlatToggle( GLOBAL.languageItems["qbcase"].toCString );
			IupSetStrAttribute( toggleQBCase, "VALUE", toStringz(GLOBAL.editorSetting00.QBCase) );
			IupSetAttribute( toggleQBCase, "ALIGNMENT", "ALEFT:ACENTER" );
			IupSetHandle( "toggleQBCase", toggleQBCase );
			
			Ihandle* toggleUseManual = IupFlatToggle( GLOBAL.languageItems["manualusing"].toCString() );
			IupSetStrAttribute( toggleUseManual, "VALUE", toStringz(GLOBAL.toggleUseManual) );
			IupSetAttribute( toggleUseManual, "ALIGNMENT", "ALEFT:ACENTER" );
			IupSetHandle( "toggleUseManual", toggleUseManual );
		}

		version(Windows)
		{
			Ihandle* toggleNewDocBOM = IupFlatToggle( GLOBAL.languageItems["newdocbom"].toCString );
			IupSetStrAttribute( toggleNewDocBOM, "VALUE", toStringz(GLOBAL.editorSetting00.NewDocBOM) );
			IupSetAttribute( toggleNewDocBOM, "ALIGNMENT", "ALEFT:ACENTER" );
			IupSetHandle( "toggleNewDocBOM", toggleNewDocBOM );
		}

		Ihandle* toggleSaveAllModified = IupFlatToggle( GLOBAL.languageItems["saveallmodified"].toCString() );
		IupSetStrAttribute( toggleSaveAllModified, "VALUE", toStringz(GLOBAL.editorSetting00.SaveAllModified) );
		IupSetAttribute( toggleSaveAllModified, "ALIGNMENT", "ALEFT:ACENTER" );
		IupSetHandle( "toggleSaveAllModified", toggleSaveAllModified );
		
		
		Ihandle* labelSetControlCharSymbol = IupLabel( GLOBAL.languageItems["controlcharsymbol"].toCString );
		Ihandle* textSetControlCharSymbol = IupText( null );
		IupSetStrAttribute( textSetControlCharSymbol, "VALUE", toStringz( GLOBAL.editorSetting00.ControlCharSymbol ) );
		IupSetHandle( "textSetControlCharSymbol", textSetControlCharSymbol );
		Ihandle* hBoxControlChar = IupHbox( labelSetControlCharSymbol, textSetControlCharSymbol, null );
		IupSetAttribute( hBoxControlChar, "ALIGNMENT", "ACENTER" );
		
		Ihandle* labelTabWidth = IupLabel( GLOBAL.languageItems["tabwidth"].toCString );
		Ihandle* textTabWidth = IupText( null );
		IupSetStrAttribute( textTabWidth, "VALUE", toStringz( GLOBAL.editorSetting00.TabWidth ) );
		IupSetHandle( "textTabWidth", textTabWidth );
		Ihandle* hBoxTab = IupHbox( labelTabWidth, textTabWidth, null );
		IupSetAttribute( hBoxTab, "ALIGNMENT", "ACENTER" );
		
		Ihandle* labelColumnEdge = IupLabel( GLOBAL.languageItems["columnedge"].toCString );
		Ihandle* textColumnEdge = IupText( null );
		IupSetStrAttribute( textColumnEdge, "VALUE", toStringz( GLOBAL.editorSetting00.ColumnEdge ) );
		IupSetAttribute( textColumnEdge, "TIP", GLOBAL.languageItems["triggertip"].toCString );
		IupSetHandle( "textColumnEdge", textColumnEdge );
		Ihandle* hBoxColumn = IupHbox( labelColumnEdge, textColumnEdge, null );
		IupSetAttribute( hBoxColumn, "ALIGNMENT", "ACENTER" );

		Ihandle* labelBarsize = IupLabel( GLOBAL.languageItems["barsize"].toCString );
		Ihandle* textBarSize = IupText( null );
		IupSetStrAttribute( textBarSize, "VALUE", toStringz( GLOBAL.editorSetting01.BarSize ) );
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
					toggleLineMargin,
					toggleFixedLineMargin,
					
					toggleBookmarkMargin,
					toggleFoldMargin,
					
					toggleIndentGuide,
					toggleCaretLine,
					
					toggleWordWrap,
					toggleTabUseingSpace,
					
					toggleShowEOL,
					toggleShowSpace,

					toggleAutoIndent,
					toggleAutoEnd,
					
					toggleAutoClose,
					toggleColorOutline,
					
					toggleBoldKeyword,
					toggleBraceMatch,

					toggleLoadprev,
					toggleMultiSelection,

					toggleCurrentWord,
					toggleMiddleScroll,

					toggleDocStatus,
					toggleNewDocBOM,

					toggleAutoKBLayout,
					toggleQBCase,

					toggleUseManual,
					toggleSaveAllModified,
					
					hBoxTab,
					hBoxColumn,

					hBoxBarSize,
					hBoxControlChar,
					
					null
				);
			}
			else
			{
				Ihandle* gbox = IupGridBox
				(
					toggleLineMargin,
					toggleFixedLineMargin,
					
					toggleBookmarkMargin,
					toggleFoldMargin,
					
					toggleIndentGuide,
					toggleCaretLine,
					
					toggleWordWrap,
					toggleTabUseingSpace,
					
					toggleShowEOL,
					toggleShowSpace,

					toggleAutoIndent,
					toggleAutoEnd,
					
					toggleAutoClose,
					toggleColorOutline,
					
					toggleBoldKeyword,
					toggleBraceMatch,

					toggleLoadprev,
					toggleMultiSelection,

					toggleCurrentWord,
					toggleMiddleScroll,

					toggleDocStatus,
					toggleQBCase,

					toggleUseManual,
					toggleSaveAllModified,
					
					hBoxTab,
					hBoxColumn,

					hBoxBarSize,
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
					toggleLineMargin,
					toggleFixedLineMargin,
					
					toggleBookmarkMargin,
					toggleFoldMargin,
					
					toggleIndentGuide,
					toggleCaretLine,
					
					toggleWordWrap,
					toggleTabUseingSpace,
					
					toggleShowEOL,
					toggleShowSpace,

					toggleAutoIndent,
					toggleAutoClose,
					
					toggleColorOutline,
					toggleBoldKeyword,

					toggleLoadprev,
					toggleBraceMatch,

					toggleMultiSelection,
					toggleCurrentWord,

					toggleMiddleScroll,
					toggleDocStatus,

					toggleAutoKBLayout,
					toggleNewDocBOM,

					toggleSaveAllModified,
					IupFill,
					
					hBoxTab,
					hBoxColumn,

					hBoxBarSize,
					hBoxControlChar,
					
					null
				);
			}
			else
			{
				Ihandle* gbox = IupGridBox
				(
					toggleLineMargin,
					toggleFixedLineMargin,
					
					toggleBookmarkMargin,
					toggleFoldMargin,
					
					toggleIndentGuide,
					toggleCaretLine,
					
					toggleWordWrap,
					toggleTabUseingSpace,
					
					toggleShowEOL,
					toggleShowSpace,

					toggleAutoIndent,
					toggleAutoClose,
					
					toggleColorOutline,
					toggleBoldKeyword,

					toggleLoadprev,
					toggleBraceMatch,

					toggleMultiSelection,
					toggleCurrentWord,

					toggleMiddleScroll,
					toggleDocStatus,

					toggleSaveAllModified,
					IupFill,
					
					hBoxTab,
					hBoxColumn,

					hBoxBarSize,
					hBoxControlChar,
					
					null
				);
			}
		}

		//IupSetAttribute(gbox, "SIZECOL", "1");
		//IupSetAttribute(gbox, "SIZELIN", "4");
		IupSetAttributes( gbox, "NUMDIV=2,ALIGNMENTLIN=ACENTER,GAPLIN=10,EXPANDCHILDREN=HORIZONTAL,MARGIN=0x0" );
		

		
		version(FBIDE)
		{
			Ihandle* radioKeywordCase0 = IupFlatToggle( GLOBAL.languageItems["none"].toCString );
			IupSetHandle( "radioKeywordCase0", radioKeywordCase0 );

			Ihandle* radioKeywordCase1 = IupFlatToggle( GLOBAL.languageItems["lowercase"].toCString );
			IupSetHandle( "radioKeywordCase1", radioKeywordCase1 );
			
			Ihandle* radioKeywordCase2 = IupFlatToggle( GLOBAL.languageItems["uppercase"].toCString );
			IupSetHandle( "radioKeywordCase2", radioKeywordCase2 );

			Ihandle* radioKeywordCase3 = IupFlatToggle( GLOBAL.languageItems["mixercase"].toCString );
			IupSetHandle( "radioKeywordCase3", radioKeywordCase3 );

			Ihandle* hBoxKeywordCase = IupHbox( radioKeywordCase0, radioKeywordCase1, radioKeywordCase2, radioKeywordCase3, null );
			IupSetAttributes( hBoxKeywordCase, "GAP=30,MARGIN=30x,ALIGNMENT=ACENTER" );

			Ihandle* frameKeywordCase = IupFrame( IupRadio( hBoxKeywordCase ) );
			IupSetAttributes( frameKeywordCase, "SIZE=346x,GAP=1" );
			IupSetAttribute( frameKeywordCase, "TITLE", GLOBAL.languageItems["autoconvertkeyword"].toCString );
			
			switch( GLOBAL.keywordCase )
			{
				case 0:		IupSetAttribute( radioKeywordCase0, "VALUE", "ON" ); break;
				case 1:		IupSetAttribute( radioKeywordCase1, "VALUE", "ON" ); break;
				case 2:		IupSetAttribute( radioKeywordCase2, "VALUE", "ON" ); break;
				default:	IupSetAttribute( radioKeywordCase3, "VALUE", "ON" ); break;
			}			
		}
		

		// Font
		PreferenceDialogParameters.fontTable = new CTable();
		PreferenceDialogParameters.fontTable.setDBLCLICK_CB( &memberDoubleClick );
		
		PreferenceDialogParameters.fontTable.addColumn( GLOBAL.languageItems["item"].toDString );
		PreferenceDialogParameters.fontTable.addColumn( GLOBAL.languageItems["face"].toDString );
		PreferenceDialogParameters.fontTable.addColumn( GLOBAL.languageItems["style"].toDString );
		PreferenceDialogParameters.fontTable.setSplitAttribute( "VALUE", "500" );
		PreferenceDialogParameters.fontTable.addColumn( GLOBAL.languageItems["size"].toDString );
		PreferenceDialogParameters.fontTable.setSplitAttribute( "VALUE", "920" );
		
		for( int i = 0; i < GLOBAL.fonts.length; ++ i )
		{
			if( i != 3 ) // Skip abandoned fileList
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
		
		
		
		Ihandle* labelCaretLine = IupLabel( GLOBAL.languageItems["caretline"].toCString );
		Ihandle* btnCaretLine = IupFlatButton( null );
		IupSetStrAttribute( btnCaretLine, "FGCOLOR", GLOBAL.editColor.caretLine.toCString );
		IupSetAttributes( btnCaretLine, "SIZE=16x8,NAME=Color-btnCaretLine" );
		IupSetCallback( btnCaretLine, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelCursor = IupLabel( GLOBAL.languageItems["cursor"].toCString );
		Ihandle* btnCursor = IupFlatButton( null );
		IupSetStrAttribute( btnCursor, "FGCOLOR", GLOBAL.editColor.cursor.toCString );
		IupSetAttributes( btnCursor, "SIZE=16x8,NAME=Color-btnCursor" );
		IupSetCallback( btnCursor, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelSelectFore = IupLabel( GLOBAL.languageItems["sel"].toCString );
		Ihandle* btnSelectFore = IupFlatButton( null );
		IupSetStrAttribute( btnSelectFore, "FGCOLOR", GLOBAL.editColor.selectionFore.toCString );
		IupSetAttributes( btnSelectFore, "SIZE=16x8,NAME=Color-btnSelectFore" );
		IupSetCallback( btnSelectFore, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* btnSelectBack = IupFlatButton( null );
		IupSetStrAttribute( btnSelectBack, "FGCOLOR", GLOBAL.editColor.selectionBack.toCString );
		IupSetAttributes( btnSelectBack, "SIZE=16x8,NAME=Color-btnSelectBack" );
		IupSetCallback( btnSelectBack, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelLinenumFore = IupLabel( GLOBAL.languageItems["ln"].toCString  );
		Ihandle* btnLinenumFore = IupFlatButton( null );
		IupSetStrAttribute( btnLinenumFore, "FGCOLOR", GLOBAL.editColor.linenumFore.toCString );
		IupSetAttributes( btnLinenumFore, "SIZE=16x8,NAME=Color-btnLinenumFore" );
		IupSetCallback( btnLinenumFore, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* btnLinenumBack = IupFlatButton( null );
		IupSetStrAttribute( btnLinenumBack, "FGCOLOR", GLOBAL.editColor.linenumBack.toCString );
		IupSetAttributes( btnLinenumBack, "SIZE=16x8,NAME=Color-btnLinenumBack" );
		IupSetCallback( btnLinenumBack, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelFoldingColor = IupLabel( GLOBAL.languageItems["foldcolor"].toCString );
		Ihandle* btnFoldingColor = IupFlatButton( null );
		IupSetStrAttribute( btnFoldingColor, "FGCOLOR", GLOBAL.editColor.fold.toCString );
		IupSetAttributes( btnFoldingColor, "SIZE=16x8,NAME=Color-btnFoldingColor" );
		IupSetCallback( btnFoldingColor, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelSelAlpha = IupLabel( GLOBAL.languageItems["selalpha"].toCString );
		Ihandle* textAlpha = IupText( null );
		version(Windows)
		{
			IupSetAttributes( textAlpha, "SIZE=24x10,MARGIN=0x0,SPIN=YES,SPINMAX=255,SPINMIN=0,NAME=textAlpha" );
			IupSetStrAttribute( textAlpha, "SPINVALUE", GLOBAL.editColor.selAlpha.toCString );
		}
		else
		{
			IupSetAttributes( textAlpha, "SIZE=24x10,MARGIN=0x0,NAME=textAlpha" );
			IupSetStrAttribute( textAlpha, "VALUE", GLOBAL.editColor.selAlpha.toCString );
		}
		IupSetAttribute( textAlpha, "TIP", GLOBAL.languageItems["alphatip"].toCString() );
		
		
		// 2017.1.14
		Ihandle* labelPrjTitle = IupLabel( GLOBAL.languageItems["prjtitle"].toCString );
		Ihandle* btnPrjTitle = IupFlatButton( null );
		IupSetStrAttribute( btnPrjTitle, "FGCOLOR", GLOBAL.editColor.prjTitle.toCString );
		IupSetAttributes( btnPrjTitle, "SIZE=16x8,NAME=Color-btnPrjTitle" );
		IupSetCallback( btnPrjTitle, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );		

		Ihandle* labelSourceTypeFolder = IupLabel( GLOBAL.languageItems["sourcefolder"].toCString );
		Ihandle* btnSourceTypeFolder = IupFlatButton( null );
		IupSetStrAttribute( btnSourceTypeFolder, "FGCOLOR", GLOBAL.editColor.prjSourceType.toCString );
		IupSetAttributes( btnSourceTypeFolder, "SIZE=16x8,NAME=Color-btnSourceTypeFolder" );
		IupSetCallback( btnSourceTypeFolder, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );		


		// 2017.7.9
		Ihandle* labelIndicator = IupLabel( GLOBAL.languageItems["hlcurrentword"].toCString );
		Ihandle* btnIndicator = IupFlatButton( null );
		IupSetStrAttribute( btnIndicator, "FGCOLOR", GLOBAL.editColor.currentWord.toCString );
		IupSetAttributes( btnIndicator, "SIZE=16x8,NAME=Color-btnIndicator" );
		IupSetCallback( btnIndicator, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelIndicatorAlpha = IupLabel( GLOBAL.languageItems["hlcurrentwordalpha"].toCString );
		Ihandle* textIndicatorAlpha = IupText( null );
		version(Windows)
		{
			IupSetAttributes( textIndicatorAlpha, "SIZE=24x10,MARGIN=0x0,SPIN=YES,SPINMAX=255,SPINMIN=0,NAME=textIndicatorAlpha" );
			IupSetStrAttribute( textIndicatorAlpha, "SPINVALUE", GLOBAL.editColor.currentWordAlpha.toCString );
		}
		else
		{
			IupSetAttributes( textIndicatorAlpha, "SIZE=24x10,MARGIN=0x0,NAME=textIndicatorAlpha" );
			IupSetStrAttribute( textIndicatorAlpha, "VALUE", GLOBAL.editColor.currentWordAlpha.toCString );
		}
		IupSetAttribute( textIndicatorAlpha, "TIP", GLOBAL.languageItems["alphatip"].toCString() );




		Ihandle* gboxColor = IupGridBox
		(
			labelCaretLine,
			btnCaretLine,
			labelCursor,
			btnCursor,

			labelFoldingColor,
			btnFoldingColor,
			labelSelAlpha,
			textAlpha,
			
			labelPrjTitle,
			btnPrjTitle,
			labelSourceTypeFolder,
			btnSourceTypeFolder,
			
			labelIndicator,
			btnIndicator,
			labelIndicatorAlpha,
			textIndicatorAlpha,

			null
		);
		version(Windows) IupSetAttributes( gboxColor, "EXPANDCHILDREN=HORIZONTAL,NUMDIV=4,ALIGNMENTLIN=ACENTER,ALIGNMENTCOL=ALEFT,GAPLIN=6,GAPCOL=30,MARGIN=2x8,SIZELIN=-1" ); else IupSetAttributes( gboxColor, "EXPANDCHILDREN=HORIZONTAL,NUMDIV=4,ALIGNMENTLIN=ACENTER,ALIGNMENTCOL=ALEFT,GAPLIN=10,GAPCOL=30,MARGIN=2x10,SIZELIN=1" );

		Ihandle* frameColor = IupFrame( gboxColor );
		IupSetAttributes( frameColor, "MARGIN=0x0,EXPAND=YES,EXPAND=HORIZONTAL" );
		IupSetAttribute( frameColor, "SIZE", "346x" );//IupGetAttribute( frameFont, "SIZE" ) );
		IupSetAttribute( frameColor, "TITLE", GLOBAL.languageItems["color"].toCString );

		
		// Color -1
		Ihandle* label_Scintilla = IupLabel( GLOBAL.languageItems["scintilla"].toCString );
		Ihandle* btn_Scintilla_FG = IupFlatButton( null );
		Ihandle* btn_Scintilla_BG = IupFlatButton( null );
		IupSetStrAttribute( btn_Scintilla_FG, "FGCOLOR", GLOBAL.editColor.scintillaFore.toCString );
		IupSetStrAttribute( btn_Scintilla_BG, "FGCOLOR", GLOBAL.editColor.scintillaBack.toCString );
		IupSetCallback( btn_Scintilla_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_FGcolorChooseScintilla_cb );
		IupSetCallback( btn_Scintilla_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChooseScintilla_cb );
		IupSetAttributes( btn_Scintilla_FG, "SIZE=16x8,NAME=Color-btn_Scintilla_FG" );
		IupSetAttributes( btn_Scintilla_BG, "SIZE=16x8,NAME=Color-btn_Scintilla_BG" );

		Ihandle* labelSCE_B_COMMENT = IupLabel( GLOBAL.languageItems["SCE_B_COMMENT"].toCString );
		Ihandle* btnSCE_B_COMMENT_FG = IupFlatButton( null );
		Ihandle* btnSCE_B_COMMENT_BG = IupFlatButton( null );
		IupSetStrAttribute( btnSCE_B_COMMENT_FG, "FGCOLOR", GLOBAL.editColor.SCE_B_COMMENT_Fore.toCString );
		IupSetStrAttribute( btnSCE_B_COMMENT_BG, "FGCOLOR", GLOBAL.editColor.SCE_B_COMMENT_Back.toCString );
		IupSetCallback( btnSCE_B_COMMENT_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnSCE_B_COMMENT_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnSCE_B_COMMENT_FG, "SIZE=16x8,NAME=Color-btnSCE_B_COMMENT_FG" );
		IupSetAttributes( btnSCE_B_COMMENT_BG, "SIZE=16x8,NAME=Color-btnSCE_B_COMMENT_BG" );
		
		Ihandle* labelSCE_B_NUMBER = IupLabel( GLOBAL.languageItems["SCE_B_NUMBER"].toCString  );
		Ihandle* btnSCE_B_NUMBER_FG = IupFlatButton( null );
		Ihandle* btnSCE_B_NUMBER_BG = IupFlatButton( null );
		IupSetStrAttribute( btnSCE_B_NUMBER_FG, "FGCOLOR", GLOBAL.editColor.SCE_B_NUMBER_Fore.toCString );
		IupSetStrAttribute( btnSCE_B_NUMBER_BG, "FGCOLOR", GLOBAL.editColor.SCE_B_NUMBER_Back.toCString );
		IupSetCallback( btnSCE_B_NUMBER_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnSCE_B_NUMBER_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnSCE_B_NUMBER_FG, "SIZE=16x8,NAME=Color-btnSCE_B_NUMBER_FG" );
		IupSetAttributes( btnSCE_B_NUMBER_BG, "SIZE=16x8,NAME=Color-btnSCE_B_NUMBER_BG" );
		
		Ihandle* labelSCE_B_STRING = IupLabel( GLOBAL.languageItems["SCE_B_STRING"].toCString );
		Ihandle* btnSCE_B_STRING_FG = IupFlatButton( null );
		Ihandle* btnSCE_B_STRING_BG = IupFlatButton( null );
		IupSetStrAttribute( btnSCE_B_STRING_FG, "FGCOLOR", GLOBAL.editColor.SCE_B_STRING_Fore.toCString );
		IupSetStrAttribute( btnSCE_B_STRING_BG, "FGCOLOR", GLOBAL.editColor.SCE_B_STRING_Back.toCString );
		//IupSetHandle( "btnSCE_B_STRING_FG", btnSCE_B_STRING_FG );
		//IupSetHandle( "btnSCE_B_STRING_BG", btnSCE_B_STRING_BG );
		IupSetCallback( btnSCE_B_STRING_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnSCE_B_STRING_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnSCE_B_STRING_FG, "SIZE=16x8,NAME=Color-btnSCE_B_STRING_FG" );
		IupSetAttributes( btnSCE_B_STRING_BG, "SIZE=16x8,NAME=Color-btnSCE_B_STRING_BG" );
		
		Ihandle* labelSCE_B_PREPROCESSOR = IupLabel( GLOBAL.languageItems["SCE_B_PREPROCESSOR"].toCString );
		Ihandle* btnSCE_B_PREPROCESSOR_FG = IupFlatButton( null );
		Ihandle* btnSCE_B_PREPROCESSOR_BG = IupFlatButton( null );
		IupSetStrAttribute( btnSCE_B_PREPROCESSOR_FG, "FGCOLOR", GLOBAL.editColor.SCE_B_PREPROCESSOR_Fore.toCString );
		IupSetStrAttribute( btnSCE_B_PREPROCESSOR_BG, "FGCOLOR", GLOBAL.editColor.SCE_B_PREPROCESSOR_Back.toCString );
		//IupSetHandle( "btnSCE_B_PREPROCESSOR_FG", btnSCE_B_PREPROCESSOR_FG );
		//IupSetHandle( "btnSCE_B_PREPROCESSOR_BG", btnSCE_B_PREPROCESSOR_BG );
		IupSetCallback( btnSCE_B_PREPROCESSOR_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnSCE_B_PREPROCESSOR_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnSCE_B_PREPROCESSOR_FG, "SIZE=16x8,NAME=Color-btnSCE_B_PREPROCESSOR_FG" );
		IupSetAttributes( btnSCE_B_PREPROCESSOR_BG, "SIZE=16x8,NAME=Color-btnSCE_B_PREPROCESSOR_BG" );
		
		Ihandle* labelSCE_B_OPERATOR = IupLabel( GLOBAL.languageItems["SCE_B_OPERATOR"].toCString );
		Ihandle* btnSCE_B_OPERATOR_FG = IupFlatButton( null );
		Ihandle* btnSCE_B_OPERATOR_BG = IupFlatButton( null );
		IupSetStrAttribute( btnSCE_B_OPERATOR_FG, "FGCOLOR", GLOBAL.editColor.SCE_B_OPERATOR_Fore.toCString );
		IupSetStrAttribute( btnSCE_B_OPERATOR_BG, "FGCOLOR", GLOBAL.editColor.SCE_B_OPERATOR_Back.toCString );
		//IupSetHandle( "btnSCE_B_OPERATOR_FG", btnSCE_B_OPERATOR_FG );
		//IupSetHandle( "btnSCE_B_OPERATOR_BG", btnSCE_B_OPERATOR_BG );
		IupSetCallback( btnSCE_B_OPERATOR_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnSCE_B_OPERATOR_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnSCE_B_OPERATOR_FG, "SIZE=16x8,NAME=Color-btnSCE_B_OPERATOR_FG" );
		IupSetAttributes( btnSCE_B_OPERATOR_BG, "SIZE=16x8,NAME=Color-btnSCE_B_OPERATOR_BG" );
		
		Ihandle* labelSCE_B_IDENTIFIER = IupLabel( GLOBAL.languageItems["SCE_B_IDENTIFIER"].toCString  );
		Ihandle* btnSCE_B_IDENTIFIER_FG = IupFlatButton( null );
		Ihandle* btnSCE_B_IDENTIFIER_BG = IupFlatButton( null );
		IupSetStrAttribute( btnSCE_B_IDENTIFIER_FG, "FGCOLOR", GLOBAL.editColor.SCE_B_IDENTIFIER_Fore.toCString );
		IupSetStrAttribute( btnSCE_B_IDENTIFIER_BG, "FGCOLOR", GLOBAL.editColor.SCE_B_IDENTIFIER_Back.toCString );
		//IupSetHandle( "btnSCE_B_IDENTIFIER_FG", btnSCE_B_IDENTIFIER_FG );
		//IupSetHandle( "btnSCE_B_IDENTIFIER_BG", btnSCE_B_IDENTIFIER_BG );
		IupSetCallback( btnSCE_B_IDENTIFIER_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnSCE_B_IDENTIFIER_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnSCE_B_IDENTIFIER_FG, "SIZE=16x8,NAME=Color-btnSCE_B_IDENTIFIER_FG" );
		IupSetAttributes( btnSCE_B_IDENTIFIER_BG, "SIZE=16x8,NAME=Color-btnSCE_B_IDENTIFIER_BG" );
		
		Ihandle* labelSCE_B_COMMENTBLOCK = IupLabel(  GLOBAL.languageItems["SCE_B_COMMENTBLOCK"].toCString  );
		Ihandle* btnSCE_B_COMMENTBLOCK_FG = IupFlatButton( null );
		Ihandle* btnSCE_B_COMMENTBLOCK_BG = IupFlatButton( null );
		IupSetStrAttribute( btnSCE_B_COMMENTBLOCK_FG, "FGCOLOR", GLOBAL.editColor.SCE_B_COMMENTBLOCK_Fore.toCString );
		IupSetStrAttribute( btnSCE_B_COMMENTBLOCK_BG, "FGCOLOR", GLOBAL.editColor.SCE_B_COMMENTBLOCK_Back.toCString );	
		//IupSetHandle( "btnSCE_B_COMMENTBLOCK_FG", btnSCE_B_COMMENTBLOCK_FG );
		//IupSetHandle( "btnSCE_B_COMMENTBLOCK_BG", btnSCE_B_COMMENTBLOCK_BG );
		IupSetCallback( btnSCE_B_COMMENTBLOCK_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnSCE_B_COMMENTBLOCK_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnSCE_B_COMMENTBLOCK_FG, "SIZE=16x8,NAME=Color-btnSCE_B_COMMENTBLOCK_FG" );
		IupSetAttributes( btnSCE_B_COMMENTBLOCK_BG, "SIZE=16x8,NAME=Color-btnSCE_B_COMMENTBLOCK_BG" );
		
		
		Ihandle* labelPrj = IupLabel( GLOBAL.languageItems["caption_prj"].toCString  );
		//IupSetAttribute( labelPrj, "SIZE", toStringz("100x") );
		Ihandle* btnPrj_FG = IupFlatButton( null );
		Ihandle* btnPrj_BG = IupFlatButton( null );
		IupSetStrAttribute( btnPrj_FG, "FGCOLOR", GLOBAL.editColor.projectFore.toCString );
		IupSetStrAttribute( btnPrj_BG, "FGCOLOR", GLOBAL.editColor.projectBack.toCString );	
		//IupSetHandle( "btnPrj_FG", btnPrj_FG );
		//IupSetHandle( "btnPrj_BG", btnPrj_BG );
		IupSetCallback( btnPrj_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnPrj_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnPrj_FG, "SIZE=16x8,NAME=Color-btnPrj_FG" );
		IupSetAttributes( btnPrj_BG, "SIZE=16x8,NAME=Color-btnPrj_BG" );
		
		Ihandle* labelOutline = IupLabel( GLOBAL.languageItems["outline"].toCString );
		Ihandle* btnOutline_FG = IupFlatButton( null );
		Ihandle* btnOutline_BG = IupFlatButton( null );
		IupSetStrAttribute( btnOutline_FG, "FGCOLOR", GLOBAL.editColor.outlineFore.toCString );
		IupSetStrAttribute( btnOutline_BG, "FGCOLOR", GLOBAL.editColor.outlineBack.toCString );	
		//IupSetHandle( "btnOutline_FG", btnOutline_FG );
		//IupSetHandle( "btnOutline_BG", btnOutline_BG );
		IupSetCallback( btnOutline_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnOutline_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnOutline_FG, "SIZE=16x8,NAME=Color-btnOutline_FG" );
		IupSetAttributes( btnOutline_BG, "SIZE=16x8,NAME=Color-btnOutline_BG" );
		
		Ihandle* labelDlg= IupLabel( GLOBAL.languageItems["dlgcolor"].toCString );
		Ihandle* btnDlg_FG = IupFlatButton( null );
		Ihandle* btnDlg_BG = IupFlatButton( null );
		IupSetStrAttribute( btnDlg_FG, "FGCOLOR", GLOBAL.editColor.dlgFore.toCString );
		IupSetStrAttribute( btnDlg_BG, "FGCOLOR", GLOBAL.editColor.dlgBack.toCString );	
		IupSetCallback( btnDlg_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnDlg_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnDlg_FG, "SIZE=16x8,NAME=Color-btnDlg_FG" );
		IupSetAttributes( btnDlg_BG, "SIZE=16x8,NAME=Color-btnDlg_BG" );
		
		Ihandle* labelTxt= IupLabel( GLOBAL.languageItems["txtcolor"].toCString );
		Ihandle* btnTxt_FG = IupFlatButton( null );
		Ihandle* btnTxt_BG = IupFlatButton( null );
		IupSetStrAttribute( btnTxt_FG, "FGCOLOR", GLOBAL.editColor.txtFore.toCString );
		IupSetStrAttribute( btnTxt_BG, "FGCOLOR", GLOBAL.editColor.txtBack.toCString );	
		IupSetCallback( btnTxt_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnTxt_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnTxt_FG, "SIZE=16x8,NAME=Color-btnTxt_FG" );
		IupSetAttributes( btnTxt_BG, "SIZE=16x8,NAME=Color-btnTxt_BG" );
		
		
		Ihandle* labelOutput= IupLabel( GLOBAL.languageItems["output"].toCString );
		Ihandle* btnOutput_FG = IupFlatButton( null );
		Ihandle* btnOutput_BG = IupFlatButton( null );
		IupSetStrAttribute( btnOutput_FG, "FGCOLOR", GLOBAL.editColor.outputFore.toCString );
		IupSetStrAttribute( btnOutput_BG, "FGCOLOR", GLOBAL.editColor.outputBack.toCString );	
		//IupSetHandle( "btnOutput_FG", btnOutput_FG );
		//IupSetHandle( "btnOutput_BG", btnOutput_BG );
		IupSetCallback( btnOutput_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnOutput_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnOutput_FG, "SIZE=16x8,NAME=Color-btnOutput_FG" );
		IupSetAttributes( btnOutput_BG, "SIZE=16x8,NAME=Color-btnOutput_BG" );
		
		Ihandle* labelSearch= IupLabel( GLOBAL.languageItems["caption_search"].toCString );
		Ihandle* btnSearch_FG = IupFlatButton( null );
		Ihandle* btnSearch_BG = IupFlatButton( null );
		IupSetStrAttribute( btnSearch_FG, "FGCOLOR", GLOBAL.editColor.searchFore.toCString );
		IupSetStrAttribute( btnSearch_BG, "FGCOLOR", GLOBAL.editColor.searchBack.toCString );	
		//IupSetHandle( "btnSearch_FG", btnSearch_FG );
		//IupSetHandle( "btnSearch_BG", btnSearch_BG );
		IupSetCallback( btnSearch_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnSearch_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnSearch_FG, "SIZE=16x8,NAME=Color-btnSearch_FG" );
		IupSetAttributes( btnSearch_BG, "SIZE=16x8,NAME=Color-btnSearch_BG" );
		
		Ihandle* labelError = IupLabel( GLOBAL.languageItems["manualerrorannotation"].toCString );
		Ihandle* btnError_FG = IupFlatButton( null );
		Ihandle* btnError_BG = IupFlatButton( null );
		IupSetStrAttribute( btnError_FG, "FGCOLOR", GLOBAL.editColor.errorFore.toCString );
		IupSetStrAttribute( btnError_BG, "FGCOLOR", GLOBAL.editColor.errorBack.toCString );	
		IupSetCallback( btnError_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnError_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnError_FG, "SIZE=16x8,NAME=Color-btnError_FG" );
		IupSetAttributes( btnError_BG, "SIZE=16x8,NAME=Color-btnError_BG" );
		
		Ihandle* labelWarning= IupLabel( GLOBAL.languageItems["manualwarningannotation"].toCString );
		Ihandle* btnWarning_FG = IupFlatButton( null );
		Ihandle* btnWarning_BG = IupFlatButton( null );
		IupSetStrAttribute( btnWarning_FG, "FGCOLOR", GLOBAL.editColor.warningFore.toCString );
		IupSetStrAttribute( btnWarning_BG, "FGCOLOR", GLOBAL.editColor.warringBack.toCString );	
		IupSetCallback( btnWarning_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnWarning_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnWarning_FG, "SIZE=16x8,NAME=Color-btnWarning_FG" );
		IupSetAttributes( btnWarning_BG, "SIZE=16x8,NAME=Color-btnWarning_BG" );
		
		Ihandle* labelBrace= IupLabel( GLOBAL.languageItems["bracehighlight"].toCString );
		Ihandle* btnBrace_FG = IupFlatButton( null );
		Ihandle* btnBrace_BG = IupFlatButton( null );
		IupSetStrAttribute( btnBrace_FG, "FGCOLOR", GLOBAL.editColor.braceFore.toCString );
		IupSetStrAttribute( btnBrace_BG, "FGCOLOR", GLOBAL.editColor.braceBack.toCString );	
		IupSetCallback( btnBrace_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnBrace_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnBrace_FG, "SIZE=16x8,NAME=Color-btnBrace_FG" );
		IupSetAttributes( btnBrace_BG, "SIZE=16x8,NAME=Color-btnBrace_BG" );
		
		auto labelLeftViewHLTTitle = new IupString( GLOBAL.languageItems["leftview"].toDString ~ " HLT:" );
		Ihandle* labelLeftViewHLT= IupLabel( labelLeftViewHLTTitle.toCString );
		Ihandle* btnLeftViewHLT = IupFlatButton( null );
		IupSetStrAttribute( btnLeftViewHLT, "FGCOLOR", GLOBAL.editColor.prjViewHLT.toCString );
		IupSetCallback( btnLeftViewHLT, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnLeftViewHLT, "SIZE=16x8,NAME=Color-btnLeftViewHLT" );
		Ihandle* textLeftViewHLTAlpha = IupText( null );
		version(Windows)
		{
			IupSetAttributes( textLeftViewHLTAlpha, "SIZE=16x10,MARGIN=0x0,SPIN=YES,SPINMAX=255,SPINMIN=0,NAME=textLeftViewHLTAplha" );
			IupSetStrAttribute( textLeftViewHLTAlpha, "SPINVALUE", GLOBAL.editColor.prjViewHLTAlpha.toCString );
		}
		else
		{
			IupSetAttributes( textLeftViewHLTAlpha, "SIZE=16x10,MARGIN=0x0,NAME=textLeftViewHLTAplha" );
			IupSetStrAttribute( textLeftViewHLTAlpha, "VALUE", GLOBAL.editColor.prjViewHLTAlpha.toCString );
		}		
		
		Ihandle* labelShowType= IupLabel( GLOBAL.languageItems["showtype"].toCString );
		Ihandle* btnShowType_FG = IupFlatButton( null );
		Ihandle* btnShowType_BG = IupFlatButton( null );
		IupSetStrAttribute( btnShowType_FG, "FGCOLOR", GLOBAL.editColor.showTypeFore.toCString );
		IupSetStrAttribute( btnShowType_BG, "FGCOLOR", GLOBAL.editColor.showTypeBack.toCString );	
		IupSetCallback( btnShowType_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnShowType_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnShowType_FG, "SIZE=16x8,NAME=Color-btnShowType_FG" );
		IupSetAttributes( btnShowType_BG, "SIZE=16x8,NAME=Color-btnShowType_BG" );

		auto labelShowTypeHLTTitle = new IupString( GLOBAL.languageItems["showtype"].toDString ~ " HLT:" );
		Ihandle* labelShowTypeHLT= IupLabel( labelShowTypeHLTTitle.toCString );
		Ihandle* btnShowTypeHLT = IupFlatButton( null );
		IupSetStrAttribute( btnShowTypeHLT, "FGCOLOR", GLOBAL.editColor.showTypeHLT.toCString );
		IupSetCallback( btnShowTypeHLT, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnShowTypeHLT, "SIZE=16x8,NAME=Color-btnShowTypeHLT" );		

		Ihandle* labelCallTip= IupLabel( GLOBAL.languageItems["calltip"].toCString );
		Ihandle* btnCallTip_FG = IupFlatButton( null );
		Ihandle* btnCallTip_BG = IupFlatButton( null );
		IupSetStrAttribute( btnCallTip_FG, "FGCOLOR", GLOBAL.editColor.callTipFore.toCString );
		IupSetStrAttribute( btnCallTip_BG, "FGCOLOR", GLOBAL.editColor.callTipBack.toCString );	
		IupSetCallback( btnCallTip_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnCallTip_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnCallTip_FG, "SIZE=16x8,NAME=Color-btnCallTip_FG" );
		IupSetAttributes( btnCallTip_BG, "SIZE=16x8,NAME=Color-btnCallTip_BG" );
		
		auto labelCallTipHLTTitle = new IupString( GLOBAL.languageItems["calltip"].toDString ~ " HLT:" );
		Ihandle* labelCallTipHLT= IupLabel( labelCallTipHLTTitle.toCString );
		Ihandle* btnCallTipHLT = IupFlatButton( null );
		IupSetStrAttribute( btnCallTipHLT, "FGCOLOR", GLOBAL.editColor.callTipHLT.toCString );
		IupSetCallback( btnCallTipHLT, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnCallTipHLT, "SIZE=16x8,NAME=Color-btnCallTipHLT" );

		Ihandle* gboxColor_1 = IupGridBox
		(
			labelDlg,
			btnDlg_FG,
			btnDlg_BG,
			IupFill(),
			labelTxt,
			btnTxt_FG,
			btnTxt_BG,
		
			labelPrj,
			btnPrj_FG,
			btnPrj_BG,
			IupFill(),
			labelOutline,
			btnOutline_FG,
			btnOutline_BG,
			
			labelOutput,
			btnOutput_FG,
			btnOutput_BG,
			IupFill(),
			labelSearch,
			btnSearch_FG,
			btnSearch_BG,
			
			labelSelectFore,
			btnSelectFore,
			btnSelectBack,
			IupFill(),
			labelLinenumFore,
			btnLinenumFore,
			btnLinenumBack,
			
			labelBrace,
			btnBrace_FG,
			btnBrace_BG,
			IupFill(),
			labelError,
			btnError_FG,
			btnError_BG,

			labelWarning,
			btnWarning_FG,
			btnWarning_BG,
			IupFill(),
			label_Scintilla,
			btn_Scintilla_FG,
			btn_Scintilla_BG,
			
			labelSCE_B_COMMENT,
			btnSCE_B_COMMENT_FG,
			btnSCE_B_COMMENT_BG,
			IupFill(),
			labelSCE_B_NUMBER,
			btnSCE_B_NUMBER_FG,
			btnSCE_B_NUMBER_BG,
			
			labelSCE_B_STRING,
			btnSCE_B_STRING_FG,
			btnSCE_B_STRING_BG,
			IupFill(),
			labelSCE_B_PREPROCESSOR,
			btnSCE_B_PREPROCESSOR_FG,
			btnSCE_B_PREPROCESSOR_BG,
			
			labelSCE_B_OPERATOR,
			btnSCE_B_OPERATOR_FG,
			btnSCE_B_OPERATOR_BG,
			IupFill(),
			labelSCE_B_IDENTIFIER,
			btnSCE_B_IDENTIFIER_FG,
			btnSCE_B_IDENTIFIER_BG,
			
			labelSCE_B_COMMENTBLOCK,
			btnSCE_B_COMMENTBLOCK_FG,
			btnSCE_B_COMMENTBLOCK_BG,
			IupFill(),
			labelLeftViewHLT,
			btnLeftViewHLT,
			textLeftViewHLTAlpha,
			
			labelShowType,
			btnShowType_FG,
			btnShowType_BG,
			IupFill(),
			labelShowTypeHLT,
			btnShowTypeHLT,
			IupFill(),
			
			labelCallTip,
			btnCallTip_FG,
			btnCallTip_BG,
			IupFill(),
			labelCallTipHLT,
			btnCallTipHLT,
			IupFill(),

			null
		);
		version(Windows) IupSetAttributes( gboxColor_1, "SIZELIN =-1,NUMDIV=7,ALIGNMENTLIN=ACENTER,ALIGNMENTCOL=ALEFT,GAPLIN=8,GAPCOL=5,MARGIN=2x8,EXPANDCHILDREN=HORIZONTAL" ); else IupSetAttributes( gboxColor_1, "SIZELIN =-1,NUMDIV=7,ALIGNMENTLIN=ACENTER,ALIGNMENTCOL=ALEFT,GAPLIN=10,GAPCOL=5,MARGIN=2x8,EXPANDCHILDREN=HORIZONTAL" );

		
		Ihandle* frameColor_1 = IupFrame( gboxColor_1 );
		IupSetAttributes( frameColor_1, "MARGIN=0x0,EXPAND=YES,EXPAND=HORIZONTAL" );
		//IupSetAttribute( frameColor_1, "SIZE", "288x" );//IupGetAttribute( frameFont, "SIZE" ) );
		IupSetAttribute( frameColor_1, "TITLE", GLOBAL.languageItems["colorfgbg"].toCString );
		
		
		
		// Mark High Light Line
		Ihandle* labelMarker0 = IupLabel( GLOBAL.languageItems["maker0"].toCString );
		IupSetAttribute( labelMarker0, "ALIGNMENT", "ARIGHT" );
		Ihandle* btnMarker0Color = IupFlatButton(  null );
		IupSetStrAttribute( btnMarker0Color, "FGCOLOR",GLOBAL.editColor.maker[0].toCString );
		IupSetAttributes( btnMarker0Color, "SIZE=24x8,NAME=Color-btnMarker0Color" );
		//IupSetHandle( "btnMarker0Color", btnMarker0Color );
		IupSetCallback( btnMarker0Color, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		
		Ihandle* labelMarker1 = IupLabel( GLOBAL.languageItems["maker1"].toCString );
		IupSetAttribute( labelMarker1, "ALIGNMENT", "ARIGHT" );
		Ihandle* btnMarker1Color = IupFlatButton( null );
		IupSetStrAttribute( btnMarker1Color, "FGCOLOR",GLOBAL.editColor.maker[1].toCString );
		IupSetAttributes( btnMarker1Color, "SIZE=24x8,NAME=Color-btnMarker1Color" );
		//IupSetHandle( "btnMarker1Color", btnMarker1Color );
		IupSetCallback( btnMarker1Color, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelMarker2 = IupLabel( GLOBAL.languageItems["maker2"].toCString );
		IupSetAttribute( labelMarker2, "ALIGNMENT", "ARIGHT" );
		Ihandle* btnMarker2Color = IupFlatButton( null );
		IupSetStrAttribute( btnMarker2Color, "FGCOLOR",GLOBAL.editColor.maker[2].toCString );
		IupSetAttributes( btnMarker2Color, "SIZE=24x8,NAME=Color-btnMarker2Color" );
		//IupSetHandle( "btnMarker2Color", btnMarker2Color );
		IupSetCallback( btnMarker2Color, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelMarker3 = IupLabel( GLOBAL.languageItems["maker3"].toCString );
		IupSetAttribute( labelMarker3, "ALIGNMENT", "ARIGHT" );
		Ihandle* btnMarker3Color = IupFlatButton( null );
		IupSetStrAttribute( btnMarker3Color, "FGCOLOR",GLOBAL.editColor.maker[3].toCString );
		IupSetAttributes( btnMarker3Color, "SIZE=24x8,NAME=Color-btnMarker3Color" );
		//IupSetHandle( "btnMarker3Color", btnMarker3Color );
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
		IupSetStrAttribute( btnKeyWord0Color, "FGCOLOR", GLOBAL.editColor.keyWord[0].toCString );
		IupSetAttributes( btnKeyWord0Color, "SIZE=36x8,NAME=Color-btnKeyWord0Color" );
		//IupSetHandle( "btnKeyWord0Color", btnKeyWord0Color );
		IupSetCallback( btnKeyWord0Color, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* btnKeyWord1Color = IupFlatButton( null );
		IupSetStrAttribute( btnKeyWord1Color, "FGCOLOR", GLOBAL.editColor.keyWord[1].toCString );
		IupSetAttributes( btnKeyWord1Color, "SIZE=36x8,NAME=Color-btnKeyWord1Color" );
		//IupSetHandle( "btnKeyWord1Color", btnKeyWord1Color );
		IupSetCallback( btnKeyWord1Color, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* btnKeyWord2Color = IupFlatButton( null );
		IupSetStrAttribute( btnKeyWord2Color, "FGCOLOR", GLOBAL.editColor.keyWord[2].toCString );
		IupSetAttributes( btnKeyWord2Color, "SIZE=36x8,NAME=Color-btnKeyWord2Color" );
		//IupSetHandle( "btnKeyWord2Color", btnKeyWord2Color );
		IupSetCallback( btnKeyWord2Color, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* btnKeyWord3Color = IupFlatButton( null );
		IupSetStrAttribute( btnKeyWord3Color, "FGCOLOR",GLOBAL.editColor.keyWord[3].toCString );
		IupSetAttributes( btnKeyWord3Color, "SIZE=36x8,NAME=Color-btnKeyWord3Color" );
		//IupSetHandle( "btnKeyWord3Color", btnKeyWord3Color );
		IupSetCallback( btnKeyWord3Color, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* btnKeyWord4Color = IupFlatButton( null );
		IupSetStrAttribute( btnKeyWord4Color, "FGCOLOR",GLOBAL.editColor.keyWord[4].toCString );
		IupSetAttributes( btnKeyWord4Color, "SIZE=36x8,NAME=Color-btnKeyWord4Color" );
		//IupSetHandle( "btnKeyWord4Color", btnKeyWord4Color );
		IupSetCallback( btnKeyWord4Color, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* btnKeyWord5Color = IupFlatButton( null );
		IupSetStrAttribute( btnKeyWord5Color, "FGCOLOR",GLOBAL.editColor.keyWord[5].toCString );
		IupSetAttributes( btnKeyWord5Color, "SIZE=36x8,NAME=Color-btnKeyWord5Color" );
		//IupSetHandle( "btnKeyWord5Color", btnKeyWord5Color );
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
		version(Windows)
		{
			IupSetCallback( preferenceTabs, "TABCHANGEPOS_CB", cast(Icallback) function( Ihandle* ih )
			{
				IupSetAttribute( IupGetHandle( "colorTemplateList" ), "SHOWDROPDOWN", "NO" );
				return IUP_DEFAULT;
			});
		}
		
		
		
		
		Ihandle* Preference_btnHiddenOK = IupButton( null, null );
		IupSetAttribute( Preference_btnHiddenOK, "VISIBLE", "NO" );
		IupSetHandle( "Preference_btnHiddenOK", Preference_btnHiddenOK );
		IupSetCallback( Preference_btnHiddenOK, "ACTION", cast(Icallback) &CPreferenceDialog_btnOK_cb );		

		Ihandle* Preference_btnHiddenCANCEL = IupButton( null, null );
		IupSetAttribute( Preference_btnHiddenCANCEL, "VISIBLE", "NO" );
		IupSetHandle( "Preference_btnHiddenCANCEL", Preference_btnHiddenCANCEL );
		IupSetCallback( Preference_btnHiddenCANCEL, "ACTION", cast(Icallback) &CPreferenceDialog_btnCancel_cb );		

		
		Ihandle* vBox = IupVbox( preferenceTabs, IupHbox( Preference_btnHiddenOK, Preference_btnHiddenCANCEL, bottom, null ), null );
		IupSetAttributes( vBox, "ALIGNMENT=ACENTER,MARGIN=2x2,GAP=5,EXPAND=YES" );
		//IupSetAttributes( vBox, "ALIGNMENT=ACENTER,GAP=5" );

		IupAppend( _dlg, vBox );
	}
	
	
	void saveColorTemplateINI( char[] templateName )
	{
		char[] templatePath = "settings/colorTemplates";

		if( GLOBAL.linuxHome.length ) templatePath = GLOBAL.linuxHome ~ "/" ~ templatePath; // version(Windows) GLOBAL.linuxHome = null
		
		scope _fp = new FilePath( templatePath );
		if( !_fp.exists() )	_fp.create();
		

		char[] doc = "[color]\n";
		
		doc ~= setINILineData( "caretLine", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnCaretLine" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "cursor", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnCursor" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "selectionFore", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSelectFore" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "selectionBack", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSelectBack" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "linenumFore", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnLinenumFore" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "linenumBack", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnLinenumBack" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "fold", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnFoldingColor" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "selAlpha", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textAlpha" ), "VALUE" ) ) );
		doc ~= setINILineData( "braceFore", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnBrace_FG" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "braceBack", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnBrace_BG" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "errorFore", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnError_FG" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "errorBack", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnError_BG" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "warningFore", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnWarning_FG" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "warningBack", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnWarning_BG" ), "FGCOLOR" ) ) );
		
		doc ~= setINILineData( "scintillaFore", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btn_Scintilla_FG" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "scintillaBack", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btn_Scintilla_BG" ), "FGCOLOR" ) ) );

		doc ~= setINILineData( "SCE_B_COMMENT_Fore", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_COMMENT_FG" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "SCE_B_COMMENT_Back", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_COMMENT_BG" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "SCE_B_NUMBER_Fore", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_NUMBER_FG" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "SCE_B_NUMBER_Back", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_NUMBER_BG" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "SCE_B_STRING_Fore", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_STRING_FG" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "SCE_B_STRING_Back", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_STRING_BG" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "SCE_B_PREPROCESSOR_Fore", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_PREPROCESSOR_FG" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "SCE_B_PREPROCESSOR_Back", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_PREPROCESSOR_BG" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "SCE_B_OPERATOR_Fore", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_OPERATOR_FG" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "SCE_B_OPERATOR_Back", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_OPERATOR_BG" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "SCE_B_IDENTIFIER_Fore", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_IDENTIFIER_FG" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "SCE_B_IDENTIFIER_Back", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_IDENTIFIER_BG" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "SCE_B_COMMENTBLOCK_Fore", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_COMMENTBLOCK_FG" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "SCE_B_COMMENTBLOCK_Back", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_COMMENTBLOCK_BG" ), "FGCOLOR" ) ) );
		
		doc ~= setINILineData( "projectFore", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnPrj_FG" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "projectBack", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnPrj_BG" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "outlineFore", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnOutline_FG" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "outlineBack", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnOutline_BG" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "dlgFore", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnDlg_FG" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "dlgBack", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnDlg_BG" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "txtFore", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnTxt_FG" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "txtBack", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnTxt_BG" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "outputFore", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnOutput_FG" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "outputBack", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnOutput_BG" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "searchFore", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSearch_FG" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "searchBack", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSearch_BG" ), "FGCOLOR" ) ) );
		
		doc ~= setINILineData( "prjTitle", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnPrjTitle" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "prjSourceType", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSourceTypeFolder" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "keyword0", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord0Color" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "keyword1", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord1Color" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "keyword2", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord2Color" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "keyword3", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord3Color" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "currentword", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnIndicator" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "currentwordAlpha", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textIndicatorAlpha" ), "VALUE" ) ) );
		doc ~= setINILineData( "keyword4", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord4Color" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "keyword5", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord5Color" ), "FGCOLOR" ) ) );

		doc ~= setINILineData( "prjViewHLT", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnLeftViewHLT" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "prjViewHLTAlpha", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textLeftViewHLTAplha" ), "VALUE" ) ) );
		doc ~= setINILineData( "showTypeFore", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnShowType_FG" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "showTypeBack", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnShowType_BG" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "showTypeHLT", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnShowTypeHLT" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "callTipFore", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnCallTip_FG" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "callTipBack", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnCallTip_BG" ), "FGCOLOR" ) ) );
		doc ~= setINILineData( "callTipHLT", fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnCallTipHLT" ), "FGCOLOR" ) ) );

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
		
		//version(Windows) IupSetAttribute( _dlg, "SIZE", "-1x310" ); else IupSetAttribute( _dlg, "SIZE", "-1x360" );
		
		IupSetAttribute( _dlg, "OPACITY", toStringz( GLOBAL.editorSetting02.preferenceDlg ) );
		
		// Bottom Button
		IupSetStrAttribute( btnCANCEL, "TITLE", GLOBAL.languageItems["close"].toCString );
		IupSetCallback( btnAPPLY, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_btnApply_cb );
		IupSetCallback( btnOK, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_btnOK_cb );
		IupSetCallback( btnCANCEL, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_btnCancel_cb );
		IupSetAttribute( _dlg, "DEFAULTENTER", "Preference_btnHiddenOK" );
		IupSetAttribute( _dlg, "DEFAULTESC", "Preference_btnHiddenCANCEL" );
		//IupSetCallback( _dlg, "CLOSE_CB", cast(Icallback) &CPreferenceDialog_btnCancel_cb );
		IupSetCallback( _dlg, "CLOSE_CB", cast(Icallback) function( Ihandle* _ih )
		{
			if( GLOBAL.preferenceDlg !is null ) delete GLOBAL.preferenceDlg;
			return IUP_CONTINUE;
		});
		
		IupMap( _dlg );
	}

	~this()
	{
	}
	
	char[] show( int x, int y )
	{
		/+
		// For Stranger bug, when issue occur, all toggle options are set to not "ON"
		if( fromStringz( IupGetAttribute( IupGetHandle( "toggleDummy" ), "VALUE" ) ) != "ON" )
		{
			GLOBAL.toggleDummy = "ON";
			return null;
		}
		+/
		IupShowXY( _dlg, x, y );
		return "OK";
	}
	
	void changeColor()
	{
		IupSetStrAttribute( GLOBAL.preferenceDlg.getIhandle, "FGCOLOR", GLOBAL.editColor.dlgFore.toCString );
		IupSetStrAttribute( GLOBAL.preferenceDlg.getIhandle, "BGCOLOR", GLOBAL.editColor.dlgBack.toCString );

		IupSetStrAttribute( btnOK, "HLCOLOR", GLOBAL.editColor.dlgBack.toCString );
		IupSetStrAttribute( btnAPPLY, "HLCOLOR", GLOBAL.editColor.dlgBack.toCString );
		IupSetStrAttribute( btnCANCEL, "HLCOLOR", GLOBAL.editColor.dlgBack.toCString );
		
		
		
		IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Compiler-compilerPath" ), "FGCOLOR", GLOBAL.editColor.txtFore.toCString );
		IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Compiler-compilerPath" ), "BGCOLOR", GLOBAL.editColor.txtBack.toCString );
		
		version(Windows)
		{
			version(FBIDE)
			{
				IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Compiler-x64compilerPath" ), "FGCOLOR", GLOBAL.editColor.txtFore.toCString );
				IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Compiler-x64compilerPath" ), "BGCOLOR", GLOBAL.editColor.txtBack.toCString );

				IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Compiler-x64DebuggerPath" ), "FGCOLOR", GLOBAL.editColor.txtFore.toCString );
				IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Compiler-x64DebuggerPath" ), "BGCOLOR", GLOBAL.editColor.txtBack.toCString );
			}
		}
		else
		{
			IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Compiler-textTerminalPath" ), "FGCOLOR", GLOBAL.editColor.txtFore.toCString );
			IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Compiler-textTerminalPath" ), "BGCOLOR", GLOBAL.editColor.txtBack.toCString );
		}
		
		version(FBIDE)
		{
			IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Compiler-debuggerPath" ), "FGCOLOR", GLOBAL.editColor.txtFore.toCString );
			IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Compiler-debuggerPath" ), "BGCOLOR", GLOBAL.editColor.txtBack.toCString );
		}
		
		IupSetStrAttribute( IupGetHandle( "textMaxHeight" ), "FGCOLOR", GLOBAL.editColor.txtFore.toCString );
		IupSetStrAttribute( IupGetHandle( "textMaxHeight" ), "BGCOLOR", GLOBAL.editColor.txtBack.toCString );
		IupSetStrAttribute( IupGetHandle( "textTrigger" ), "FGCOLOR", GLOBAL.editColor.txtFore.toCString );
		IupSetStrAttribute( IupGetHandle( "textTrigger" ), "BGCOLOR", GLOBAL.editColor.txtBack.toCString );
		IupSetStrAttribute( IupGetHandle( "textIncludeLevel" ), "FGCOLOR", GLOBAL.editColor.txtFore.toCString );
		IupSetStrAttribute( IupGetHandle( "textIncludeLevel" ), "BGCOLOR", GLOBAL.editColor.txtBack.toCString );
		IupSetStrAttribute( IupGetHandle( "textSetControlCharSymbol" ), "FGCOLOR", GLOBAL.editColor.txtFore.toCString );
		IupSetStrAttribute( IupGetHandle( "textSetControlCharSymbol" ), "BGCOLOR", GLOBAL.editColor.txtBack.toCString );
		IupSetStrAttribute( IupGetHandle( "textTabWidth" ), "FGCOLOR", GLOBAL.editColor.txtFore.toCString );
		IupSetStrAttribute( IupGetHandle( "textTabWidth" ), "BGCOLOR", GLOBAL.editColor.txtBack.toCString );
		IupSetStrAttribute( IupGetHandle( "textColumnEdge" ), "FGCOLOR", GLOBAL.editColor.txtFore.toCString );
		IupSetStrAttribute( IupGetHandle( "textColumnEdge" ), "BGCOLOR", GLOBAL.editColor.txtBack.toCString );
		IupSetStrAttribute( IupGetHandle( "textBarSize" ), "FGCOLOR", GLOBAL.editColor.txtFore.toCString );
		IupSetStrAttribute( IupGetHandle( "textBarSize" ), "BGCOLOR", GLOBAL.editColor.txtBack.toCString );

		IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textAlpha" ), "FGCOLOR", GLOBAL.editColor.txtFore.toCString );
		IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textAlpha" ), "BGCOLOR", GLOBAL.editColor.txtBack.toCString );
		IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textIndicatorAlpha" ), "FGCOLOR", GLOBAL.editColor.txtFore.toCString );
		IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textIndicatorAlpha" ), "BGCOLOR", GLOBAL.editColor.txtBack.toCString );
		IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textLeftViewHLTAplha" ), "FGCOLOR", GLOBAL.editColor.txtFore.toCString );
		IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textLeftViewHLTAplha" ), "BGCOLOR", GLOBAL.editColor.txtBack.toCString );

		IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textMonitorID" ), "FGCOLOR", GLOBAL.editColor.txtFore.toCString );
		IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textMonitorID" ), "BGCOLOR", GLOBAL.editColor.txtBack.toCString );
		IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textConsoleX" ), "FGCOLOR", GLOBAL.editColor.txtFore.toCString );
		IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textConsoleX" ), "BGCOLOR", GLOBAL.editColor.txtBack.toCString );
		IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textConsoleY" ), "FGCOLOR", GLOBAL.editColor.txtFore.toCString );
		IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textConsoleY" ), "BGCOLOR", GLOBAL.editColor.txtBack.toCString );
		IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textConsoleW" ), "FGCOLOR", GLOBAL.editColor.txtFore.toCString );
		IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textConsoleW" ), "BGCOLOR", GLOBAL.editColor.txtBack.toCString );
		IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textConsoleH" ), "FGCOLOR", GLOBAL.editColor.txtFore.toCString );
		IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textConsoleH" ), "BGCOLOR", GLOBAL.editColor.txtBack.toCString );

		IupSetStrAttribute( IupGetHandle( "keyWordText0" ), "FGCOLOR", GLOBAL.editColor.txtFore.toCString );
		IupSetStrAttribute( IupGetHandle( "keyWordText0" ), "BGCOLOR", GLOBAL.editColor.txtBack.toCString );
		IupSetStrAttribute( IupGetHandle( "keyWordText1" ), "FGCOLOR", GLOBAL.editColor.txtFore.toCString );
		IupSetStrAttribute( IupGetHandle( "keyWordText1" ), "BGCOLOR", GLOBAL.editColor.txtBack.toCString );
		IupSetStrAttribute( IupGetHandle( "keyWordText2" ), "FGCOLOR", GLOBAL.editColor.txtFore.toCString );
		IupSetStrAttribute( IupGetHandle( "keyWordText2" ), "BGCOLOR", GLOBAL.editColor.txtBack.toCString );
		IupSetStrAttribute( IupGetHandle( "keyWordText3" ), "FGCOLOR", GLOBAL.editColor.txtFore.toCString );
		IupSetStrAttribute( IupGetHandle( "keyWordText3" ), "BGCOLOR", GLOBAL.editColor.txtBack.toCString );
		IupSetStrAttribute( IupGetHandle( "keyWordText4" ), "FGCOLOR", GLOBAL.editColor.txtFore.toCString );
		IupSetStrAttribute( IupGetHandle( "keyWordText4" ), "BGCOLOR", GLOBAL.editColor.txtBack.toCString );
		IupSetStrAttribute( IupGetHandle( "keyWordText5" ), "FGCOLOR", GLOBAL.editColor.txtFore.toCString );
		IupSetStrAttribute( IupGetHandle( "keyWordText5" ), "BGCOLOR", GLOBAL.editColor.txtBack.toCString );
		
		IupSetStrAttribute( IupGetHandle( "shortCutList" ), "FGCOLOR", GLOBAL.editColor.txtFore.toCString );
		IupSetStrAttribute( IupGetHandle( "shortCutList" ), "BGCOLOR", GLOBAL.editColor.txtBack.toCString );
	}
}

extern(C) // Callback for CPreferenceDialog
{
	private int CPreferenceDialog_OpenAppBinFile_cb( Ihandle* ih )
	{
		auto mother = IupGetParent( ih );
		if( !mother ) return IUP_DEFAULT;
		
		auto _textElement = IupGetNextChild( mother, null );
		if( !_textElement ) return IUP_DEFAULT;

		char[] relatedPath = fromStringz( IupGetAttribute( _textElement, "VALUE" ) );
		scope fileSelectDlg = new CFileDlg( GLOBAL.languageItems["caption_open"].toDString ~ "...", GLOBAL.languageItems["exefile"].toDString() ~ "|*.exe", "OPEN", "NO", relatedPath );

		char[] fileName = fileSelectDlg.getFileName();
		if( fileName.length ) IupSetStrAttribute( _textElement, "VALUE", toStringz( fileName ) );
		
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
	

	private int CPreferenceDialog_btnCancel_cb( Ihandle* ih )
	{
		IupHide( GLOBAL.preferenceDlg.getIhandle );
		if( GLOBAL.preferenceDlg.getIhandle != null ) IupDestroy( GLOBAL.preferenceDlg.getIhandle );
		delete GLOBAL.preferenceDlg;
		return IUP_DEFAULT;
	}


	private int CPreferenceDialog_btnOK_cb( Ihandle* ih )
	{
		CPreferenceDialog_btnApply_cb( ih );
		IupHide( GLOBAL.preferenceDlg.getIhandle );
		if( GLOBAL.preferenceDlg.getIhandle != null ) IupDestroy( GLOBAL.preferenceDlg.getIhandle );
		delete GLOBAL.preferenceDlg;
		return IUP_DEFAULT;
	}


	private int CPreferenceDialog_btnApply_cb( Ihandle* ih )
	{
		try
		{
			if( GLOBAL.editorSetting01.OutlineFlat == "ON" )
			{	
				//IupSetInt( GLOBAL.projectViewTabs, "VISIBLE", 0 );
				IupSetInt( GLOBAL.outlineTree.getZBoxHandle, "VISIBLE", 0 );
				IupSetInt( GLOBAL.projectTree.getTreeHandle, "VISIBLE", 0 );
			}
		
			GLOBAL.KEYWORDS[0] = Util.trim( fromStringz(IupGetAttribute( IupGetHandle( "keyWordText0" ), "VALUE" ))).dup;
			GLOBAL.KEYWORDS[1] = Util.trim( fromStringz(IupGetAttribute( IupGetHandle( "keyWordText1" ), "VALUE" ))).dup;
			GLOBAL.KEYWORDS[2] = Util.trim( fromStringz(IupGetAttribute( IupGetHandle( "keyWordText2" ), "VALUE" ))).dup;
			GLOBAL.KEYWORDS[3] = Util.trim( fromStringz(IupGetAttribute( IupGetHandle( "keyWordText3" ), "VALUE" ))).dup;
			GLOBAL.KEYWORDS[4] = Util.trim( fromStringz(IupGetAttribute( IupGetHandle( "keyWordText4" ), "VALUE" ))).dup;
			GLOBAL.KEYWORDS[5] = Util.trim( fromStringz(IupGetAttribute( IupGetHandle( "keyWordText5" ), "VALUE" ))).dup;
			
			GLOBAL.editorSetting00.LineMargin				= fromStringz(IupGetAttribute( IupGetHandle( "toggleLineMargin" ), "VALUE" )).dup;
				if( IupGetHandle( "menuLineMargin" ) != null ) IupSetStrAttribute( IupGetHandle( "menuLineMargin" ), "VALUE", IupGetAttribute( IupGetHandle( "toggleLineMargin" ), "VALUE" ) );
			GLOBAL.editorSetting00.FixedLineMargin			= fromStringz(IupGetAttribute( IupGetHandle( "toggleFixedLineMargin" ), "VALUE" )).dup;
			GLOBAL.editorSetting00.BookmarkMargin			= fromStringz(IupGetAttribute( IupGetHandle( "toggleBookmarkMargin" ), "VALUE" )).dup;
				if( IupGetHandle( "menuBookmarkMargin" ) != null ) IupSetStrAttribute( IupGetHandle( "menuBookmarkMargin" ), "VALUE", IupGetAttribute( IupGetHandle( "toggleBookmarkMargin" ), "VALUE" ) );
			GLOBAL.editorSetting00.FoldMargin				= fromStringz(IupGetAttribute( IupGetHandle( "toggleFoldMargin" ), "VALUE" )).dup;
				if( IupGetHandle( "menuFoldMargin" ) != null ) IupSetStrAttribute( IupGetHandle( "menuFoldMargin" ), "VALUE", IupGetAttribute( IupGetHandle( "toggleFoldMargin" ), "VALUE" ) );
			GLOBAL.editorSetting00.IndentGuide				= fromStringz(IupGetAttribute( IupGetHandle( "toggleIndentGuide" ), "VALUE" )).dup;
				if( IupGetHandle( "menuIndentGuide" ) != null ) IupSetStrAttribute( IupGetHandle( "menuIndentGuide" ), "VALUE", IupGetAttribute( IupGetHandle( "toggleIndentGuide" ), "VALUE" ) );
			GLOBAL.editorSetting00.CaretLine				= fromStringz(IupGetAttribute( IupGetHandle( "toggleCaretLine" ), "VALUE" )).dup;
				if( IupGetHandle( "menuCaretLine" ) != null ) IupSetStrAttribute( IupGetHandle( "menuCaretLine" ), "VALUE", IupGetAttribute( IupGetHandle( "toggleCaretLine" ), "VALUE" ) );
			GLOBAL.editorSetting00.WordWrap					= fromStringz(IupGetAttribute( IupGetHandle( "toggleWordWrap" ), "VALUE" )).dup;
			GLOBAL.editorSetting00.TabUseingSpace			= fromStringz(IupGetAttribute( IupGetHandle( "toggleTabUseingSpace" ), "VALUE" )).dup;
			GLOBAL.editorSetting00.AutoIndent				= fromStringz(IupGetAttribute( IupGetHandle( "toggleAutoIndent" ), "VALUE" )).dup;
			GLOBAL.editorSetting00.ShowEOL					= fromStringz(IupGetAttribute( IupGetHandle( "toggleShowEOL" ), "VALUE" )).dup;
				if( IupGetHandle( "menuShowEOL" ) != null ) IupSetStrAttribute( IupGetHandle( "menuShowEOL" ), "VALUE", IupGetAttribute( IupGetHandle( "toggleShowEOL" ), "VALUE" ) );
			GLOBAL.editorSetting00.ShowSpace				= fromStringz(IupGetAttribute( IupGetHandle( "toggleShowSpace" ), "VALUE" )).dup;
				if( IupGetHandle( "menuShowSpace" ) != null ) IupSetStrAttribute( IupGetHandle( "menuShowSpace" ), "VALUE", IupGetAttribute( IupGetHandle( "toggleShowSpace" ), "VALUE" ) );
			version(FBIDE)	GLOBAL.editorSetting00.AutoEnd	= fromStringz(IupGetAttribute( IupGetHandle( "toggleAutoEnd" ), "VALUE" )).dup;
			GLOBAL.editorSetting00.AutoClose				= fromStringz(IupGetAttribute( IupGetHandle( "toggleAutoClose" ), "VALUE" )).dup;
			GLOBAL.editorSetting00.ColorOutline				= fromStringz(IupGetAttribute( IupGetHandle( "toggleColorOutline" ), "VALUE" )).dup;
			GLOBAL.editorSetting00.BoldKeyword				= fromStringz(IupGetAttribute( IupGetHandle( "toggleBoldKeyword" ), "VALUE" )).dup;
				if( IupGetHandle( "menuBoldKeyword" ) != null ) IupSetStrAttribute( IupGetHandle( "menuBoldKeyword" ), "VALUE", IupGetAttribute( IupGetHandle( "toggleBoldKeyword" ), "VALUE" ) );
			GLOBAL.editorSetting00.BraceMatchHighlight		= fromStringz(IupGetAttribute( IupGetHandle( "toggleBraceMatch" ), "VALUE" )).dup;
				if( IupGetHandle( "menuBraceMatch" ) != null ) IupSetStrAttribute( IupGetHandle( "menuBraceMatch" ), "VALUE", IupGetAttribute( IupGetHandle( "toggleBraceMatch" ), "VALUE" ) );
			GLOBAL.editorSetting00.MultiSelection			= fromStringz(IupGetAttribute( IupGetHandle( "toggleMultiSelection" ), "VALUE" )).dup;
			GLOBAL.editorSetting00.LoadPrevDoc				= fromStringz(IupGetAttribute( IupGetHandle( "toggleLoadprev" ), "VALUE" )).dup;
			GLOBAL.editorSetting00.HighlightCurrentWord		= fromStringz(IupGetAttribute( IupGetHandle( "toggleCurrentWord" ), "VALUE" )).dup;
				if( IupGetHandle( "menuHighlightCurrentWord" ) != null ) IupSetStrAttribute( IupGetHandle( "menuHighlightCurrentWord" ), "VALUE", IupGetAttribute( IupGetHandle( "toggleCurrentWord" ), "VALUE" ) );
				
			GLOBAL.editorSetting00.MiddleScroll				= fromStringz(IupGetAttribute( IupGetHandle( "toggleMiddleScroll" ), "VALUE" )).dup;
			GLOBAL.editorSetting00.DocStatus				= fromStringz(IupGetAttribute( IupGetHandle( "toggleDocStatus" ), "VALUE" )).dup;
			GLOBAL.editorSetting00.LoadAtBackThread			= fromStringz(IupGetAttribute( IupGetHandle( "toggleLoadAtBackThread" ), "VALUE" )).dup;
			GLOBAL.editorSetting00.AutoKBLayout				= fromStringz(IupGetAttribute( IupGetHandle( "toggleAutoKBLayout" ), "VALUE" )).dup;
			version(FBIDE) GLOBAL.editorSetting00.QBCase					= fromStringz(IupGetAttribute( IupGetHandle( "toggleQBCase" ), "VALUE" )).dup;
			version(Windows) GLOBAL.editorSetting00.NewDocBOM				= fromStringz(IupGetAttribute( IupGetHandle( "toggleNewDocBOM" ), "VALUE" )).dup;
			GLOBAL.editorSetting00.SaveAllModified			= fromStringz(IupGetAttribute( IupGetHandle( "toggleSaveAllModified" ), "VALUE" )).dup;
			
			
			GLOBAL.editorSetting00.ControlCharSymbol	= fromStringz( IupGetAttribute( IupGetHandle( "textSetControlCharSymbol" ), "VALUE" ) ).dup;
			GLOBAL.editorSetting00.TabWidth				= fromStringz( IupGetAttribute( IupGetHandle( "textTabWidth" ), "VALUE" ) ).dup;
			GLOBAL.editorSetting00.ColumnEdge			= fromStringz( IupGetAttribute( IupGetHandle( "textColumnEdge" ), "VALUE" ) ).dup;
			GLOBAL.editorSetting01.BarSize				= fromStringz( IupGetAttribute( IupGetHandle( "textBarSize" ), "VALUE" ) ).dup;
			
			int _barSize = Integer.atoi( GLOBAL.editorSetting01.BarSize );
			if( _barSize < 2 )
			{
				GLOBAL.editorSetting01.BarSize = "2";
				IupSetStrAttribute( IupGetHandle( "textBarSize" ), "VALUE", "2" );
			}
			if( _barSize > 5 )
			{
				GLOBAL.editorSetting01.BarSize = "5";
				IupSetStrAttribute( IupGetHandle( "textBarSize" ), "VALUE", "5" );
			}


			// Save Font Style
			GLOBAL.fonts.length = 12;
			for( int i = 1; i <= PreferenceDialogParameters.fontTable.getItemCount; ++ i )
			{
				char[][] _values = PreferenceDialogParameters.fontTable.getSelection( i );
				if( _values.length == 4 )
				{
					_values[2] = Util.trim( _values[2] ).dup;
					if( !_values[2].length ) _values[2] = " ";else  _values[2] = " " ~  _values[2] ~ " ";
					int fontID = i - 1;
					if( i >= 4 ) fontID ++;
					GLOBAL.fonts[fontID].fontString = _values[1] ~ "," ~ _values[2] ~ _values[3];
				}			
			}
			/+
			for( int i = 0; i < GLOBAL.fonts.length; ++ i )
			{
				int fontID = i + 1;
				
				if( i != 3 )
				{
					if( i > 3 ) fontID ++;
					char[][] _values = PreferenceDialogParameters.fontTable.getSelection( fontID );
					if( _values.length == 4 )
					{
						_values[2] = Util.trim( _values[2] ).dup;
						if( !_values[2].length ) _values[2] = " ";else  _values[2] = " " ~  _values[2] ~ " ";
						GLOBAL.fonts[i].fontString = _values[1] ~ "," ~ _values[2] ~ _values[3];
					}
				}
			}
			+/
			
			GLOBAL.editColor.caretLine = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnCaretLine" ), "FGCOLOR" );
			GLOBAL.editColor.cursor = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnCursor" ), "FGCOLOR" );
			GLOBAL.editColor.selectionFore = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSelectFore" ), "FGCOLOR" );
			GLOBAL.editColor.selectionBack = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSelectBack" ), "FGCOLOR" );
			GLOBAL.editColor.linenumFore = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnLinenumFore" ), "FGCOLOR" );
			GLOBAL.editColor.linenumBack = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnLinenumBack" ), "FGCOLOR" );
			GLOBAL.editColor.fold = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnFoldingColor" ), "FGCOLOR" );			
			
			version(Windows)
				GLOBAL.editColor.selAlpha				= IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textAlpha" ), "SPINVALUE" );			
			else
				GLOBAL.editColor.selAlpha				= IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textAlpha" ), "VALUE" );			
			
			GLOBAL.editColor.currentWord = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnIndicator" ), "FGCOLOR" );
			
			version(Windows)
				GLOBAL.editColor.currentWordAlpha		= IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textIndicatorAlpha" ), "SPINVALUE" );
			else
				GLOBAL.editColor.currentWordAlpha		= IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textIndicatorAlpha" ), "VALUE" );

			GLOBAL.editColor.scintillaFore = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btn_Scintilla_FG" ), "FGCOLOR" );
			GLOBAL.editColor.scintillaBack = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btn_Scintilla_BG" ), "FGCOLOR" );
			GLOBAL.editColor.SCE_B_COMMENT_Fore = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_COMMENT_FG" ), "FGCOLOR" );
			GLOBAL.editColor.SCE_B_COMMENT_Back = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_COMMENT_BG" ), "FGCOLOR" );
			GLOBAL.editColor.SCE_B_NUMBER_Fore = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_NUMBER_FG" ), "FGCOLOR" );
			GLOBAL.editColor.SCE_B_NUMBER_Back = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_NUMBER_BG" ), "FGCOLOR" );
			GLOBAL.editColor.SCE_B_STRING_Fore = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_STRING_FG" ), "FGCOLOR" );
			GLOBAL.editColor.SCE_B_STRING_Back = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_STRING_BG" ), "FGCOLOR" );
			GLOBAL.editColor.SCE_B_PREPROCESSOR_Fore = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_PREPROCESSOR_FG" ), "FGCOLOR" );
			GLOBAL.editColor.SCE_B_PREPROCESSOR_Back = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_PREPROCESSOR_BG" ), "FGCOLOR" );
			GLOBAL.editColor.SCE_B_OPERATOR_Fore = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_OPERATOR_FG" ), "FGCOLOR" );
			GLOBAL.editColor.SCE_B_OPERATOR_Back = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_OPERATOR_BG" ), "FGCOLOR" );
			GLOBAL.editColor.SCE_B_IDENTIFIER_Fore = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_IDENTIFIER_FG" ), "FGCOLOR" );
			GLOBAL.editColor.SCE_B_IDENTIFIER_Back = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_IDENTIFIER_BG" ), "FGCOLOR" );
			GLOBAL.editColor.SCE_B_COMMENTBLOCK_Fore = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_COMMENTBLOCK_FG" ), "FGCOLOR" );
			GLOBAL.editColor.SCE_B_COMMENTBLOCK_Back = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_COMMENTBLOCK_BG" ), "FGCOLOR" );
			GLOBAL.editColor.prjTitle = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnPrjTitle" ), "FGCOLOR" );
			GLOBAL.editColor.prjSourceType = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSourceTypeFolder" ), "FGCOLOR" );
			
			GLOBAL.editColor.projectFore = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnPrj_FG" ), "FGCOLOR" );
			GLOBAL.editColor.projectBack = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnPrj_BG" ), "FGCOLOR" );
			GLOBAL.editColor.outlineFore = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnOutline_FG" ), "FGCOLOR" );
			GLOBAL.editColor.outlineBack = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnOutline_BG" ), "FGCOLOR" );
			GLOBAL.editColor.dlgFore = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnDlg_FG" ), "FGCOLOR" );
			GLOBAL.editColor.dlgBack = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnDlg_BG" ), "FGCOLOR" );
			GLOBAL.editColor.txtFore = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnTxt_FG" ), "FGCOLOR" );
			GLOBAL.editColor.txtBack = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnTxt_BG" ), "FGCOLOR" );
			
			GLOBAL.editColor.outputFore = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnOutput_FG" ), "FGCOLOR" );
			GLOBAL.editColor.outputBack = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnOutput_BG" ), "FGCOLOR" );
			GLOBAL.editColor.searchFore = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSearch_FG" ), "FGCOLOR" );
			GLOBAL.editColor.searchBack = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSearch_BG" ), "FGCOLOR" );

			GLOBAL.editColor.errorFore = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnError_FG" ), "FGCOLOR" );
			GLOBAL.editColor.errorBack = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnError_BG" ), "FGCOLOR" );
			GLOBAL.editColor.warningFore = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnWarning_FG" ), "FGCOLOR" );
			GLOBAL.editColor.warringBack = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnWarning_BG" ), "FGCOLOR" );
			GLOBAL.editColor.braceFore = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnBrace_FG" ), "FGCOLOR" );
			GLOBAL.editColor.braceBack = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnBrace_BG" ), "FGCOLOR" );

			GLOBAL.editColor.maker[0] = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnMarker0Color" ), "FGCOLOR" );
			GLOBAL.editColor.maker[1] = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnMarker1Color" ), "FGCOLOR" );
			GLOBAL.editColor.maker[2] = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnMarker2Color" ), "FGCOLOR" );
			GLOBAL.editColor.maker[3] = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnMarker3Color" ), "FGCOLOR" );
			
			
			GLOBAL.editColor.prjViewHLT = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnLeftViewHLT" ), "FGCOLOR" );
			version(Windows)
				GLOBAL.editColor.prjViewHLTAlpha		= IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textLeftViewHLTAplha" ), "SPINVALUE" );
			else
				GLOBAL.editColor.prjViewHLTAlpha		= IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textLeftViewHLTAplha" ), "VALUE" );
			
			
			GLOBAL.editColor.callTipFore = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnCallTip_FG" ), "FGCOLOR" );
			GLOBAL.editColor.callTipBack = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnCallTip_BG" ), "FGCOLOR" );
			GLOBAL.editColor.callTipHLT = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnCallTipHLT" ), "FGCOLOR" );
			GLOBAL.editColor.showTypeFore = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnShowType_FG" ), "FGCOLOR" );
			GLOBAL.editColor.showTypeBack = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnShowType_BG" ), "FGCOLOR" );
			GLOBAL.editColor.showTypeHLT = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnShowTypeHLT" ), "FGCOLOR" );
			
			
			
			// Add for color
			version(DARKTHEME)
			{
				IupSetStrGlobal( "DLGFGCOLOR", GLOBAL.editColor.dlgFore.toCString );
				IupSetStrGlobal( "DLGBGCOLOR", GLOBAL.editColor.dlgBack.toCString );
				IupSetStrGlobal( "TXTFGCOLOR", GLOBAL.editColor.txtFore.toCString );
				IupSetStrGlobal( "TXTBGCOLOR", GLOBAL.editColor.txtBack.toCString );				
				IupSetStrAttribute( GLOBAL.mainDlg, "FGCOLOR", GLOBAL.editColor.dlgFore.toCString );
				IupSetStrAttribute( GLOBAL.mainDlg, "BGCOLOR", GLOBAL.editColor.dlgBack.toCString );
			}

			IupSetStrAttribute( GLOBAL.documentTabs, "FGCOLOR", GLOBAL.editColor.SCE_B_IDENTIFIER_Fore.toCString );
			IupSetStrAttribute( GLOBAL.documentTabs, "BGCOLOR", GLOBAL.editColor.SCE_B_IDENTIFIER_Back.toCString );
			IupSetStrAttribute( GLOBAL.documentTabs, "TABSFORECOLOR", GLOBAL.editColor.dlgFore.toCString );
			IupSetStrAttribute( GLOBAL.documentTabs, "TABSBACKCOLOR", GLOBAL.editColor.dlgBack.toCString );			
			IupSetStrAttribute( GLOBAL.documentTabs, "TABSLINECOLOR", GLOBAL.editColor.linenumBack.toCString );
			IupSetStrAttribute( GLOBAL.documentTabs_Sub, "FGCOLOR", GLOBAL.editColor.SCE_B_IDENTIFIER_Fore.toCString );
			IupSetStrAttribute( GLOBAL.documentTabs_Sub, "BGCOLOR", GLOBAL.editColor.SCE_B_IDENTIFIER_Back.toCString );
			IupSetStrAttribute( GLOBAL.documentTabs_Sub, "TABSFORECOLOR", GLOBAL.editColor.dlgFore.toCString );
			IupSetStrAttribute( GLOBAL.documentTabs_Sub, "TABSBACKCOLOR", GLOBAL.editColor.dlgBack.toCString );	
			IupSetStrAttribute( GLOBAL.documentTabs_Sub, "TABSLINECOLOR", GLOBAL.editColor.linenumBack.toCString );
			
			IupSetStrAttribute( GLOBAL.explorerSplit, "COLOR", GLOBAL.editColor.linenumBack.toCString );
			IupSetStrAttribute( GLOBAL.messageSplit, "COLOR", GLOBAL.editColor.linenumBack.toCString );
			IupSetInt( GLOBAL.explorerSplit, "BARSIZE", Integer.atoi( GLOBAL.editorSetting01.BarSize ) );
			IupSetInt( GLOBAL.messageSplit, "BARSIZE", Integer.atoi( GLOBAL.editorSetting01.BarSize ) );
			/*
			IupSetInt( GLOBAL.documentSplit, "BARSIZE", Integer.atoi( GLOBAL.editorSetting01.BarSize ) );
			IupSetInt( GLOBAL.documentSplit2, "BARSIZE", Integer.atoi( GLOBAL.editorSetting01.BarSize ) );
			*/

			// Update and change THEME color
			GLOBAL.projectTree.changeColor();
			GLOBAL.outlineTree.changeColor();
			
			GLOBAL.messagePanel.applyColor(); // Set GLOBAL.messagePanel Color
			IupSetStrAttribute( GLOBAL.projectViewTabs, "TABSFORECOLOR", GLOBAL.editColor.outlineFore.toCString );
			IupSetStrAttribute( GLOBAL.projectViewTabs, "TABSBACKCOLOR", GLOBAL.editColor.outlineBack.toCString );
			IupSetStrAttribute( GLOBAL.projectViewTabs, "TABSLINECOLOR", GLOBAL.editColor.linenumBack.toCString );
			
			version(DARKTHEME)
			{
				if( GLOBAL.serachInFilesDlg !is null ) GLOBAL.serachInFilesDlg.changeColor();
				if( GLOBAL.preferenceDlg !is null ) GLOBAL.preferenceDlg.changeColor();
			}

			// Set the document empty tab back color
			IupSetStrAttribute( IupGetChild( GLOBAL.dndDocumentZBox, 0 ), "BGCOLOR" , GLOBAL.editColor.dlgBack.toCString );
			IupRedraw( IupGetChild( IupGetChild( GLOBAL.dndDocumentZBox, 0 ), 0 ), 0 );

			if( GLOBAL.toolbar !is null ) GLOBAL.toolbar.changeColor();
			if( GLOBAL.statusBar !is null ) GLOBAL.statusBar.changeColor();
			if( GLOBAL.debugPanel !is null ) GLOBAL.debugPanel.changeColor();
	
			
			GLOBAL.editColor.keyWord[0] = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord0Color" ), "FGCOLOR" );
			GLOBAL.editColor.keyWord[1] = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord1Color" ), "FGCOLOR" );
			GLOBAL.editColor.keyWord[2] = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord2Color" ), "FGCOLOR" );
			GLOBAL.editColor.keyWord[3] = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord3Color" ), "FGCOLOR" );
			GLOBAL.editColor.keyWord[4] = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord4Color" ), "FGCOLOR" );
			GLOBAL.editColor.keyWord[5] = IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord5Color" ), "FGCOLOR" );
			
			
			
			
			/*
			char[] templateName = Util.trim( fromStringz( IupGetAttribute( IupGetHandle( "colorTemplateList" ), "VALUE" ) ) ).dup;
			if( templateName.length )
			{
				IDECONFIG.saveColorTemplateINI( templateName );
				//GLOBAL.colorTemplate = templateName.dup;
			}
			*/

			GLOBAL.autoCompletionTriggerWordCount		= Integer.atoi( fromStringz( IupGetAttribute( IupGetHandle( "textTrigger" ), "VALUE" ) ) );
			GLOBAL.autoCMaxHeight						= Integer.atoi( fromStringz( IupGetAttribute( IupGetHandle( "textMaxHeight" ), "VALUE" ) ) );
			GLOBAL.statusBar.setOriginalTrigger( GLOBAL.autoCompletionTriggerWordCount );
			version(FBIDE) GLOBAL.includeLevel			= Integer.toInt( fromStringz( IupGetAttribute( IupGetHandle( "textIncludeLevel" ), "VALUE" ) ) );
			
			//if( GLOBAL.includeLevel < 0 ) GLOBAL.includeLevel = 0;


			// Compiler & Debugger
			char[] newCompilerFullPath = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Compiler-compilerPath" ), "VALUE" ) ).dup;
			version(DIDE) if( newCompilerFullPath != GLOBAL.compilerFullPath ) GLOBAL.defaultImportPaths = tools.getImportPath( newCompilerFullPath );
			
			GLOBAL.compilerFullPath	= newCompilerFullPath;
			version(Windows)
			{
				version(FBIDE)
				{
					GLOBAL.debuggerFullPath		= fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Compiler-debuggerPath" ), "VALUE" ) ).dup;
					GLOBAL.x64compilerFullPath	= fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Compiler-x64compilerPath" ), "VALUE" ) ).dup;
					GLOBAL.x64debuggerFullPath	= fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Compiler-x64DebuggerPath" ), "VALUE" ) ).dup;
				}
				else
				{
					GLOBAL.x64compilerFullPath	= GLOBAL.compilerFullPath;
				}
			}
			else
			{
				GLOBAL.x64compilerFullPath	= GLOBAL.compilerFullPath;
				GLOBAL.debuggerFullPath		= fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Compiler-debuggerPath" ), "VALUE" ) ).dup;
				GLOBAL.x64debuggerFullPath	= GLOBAL.debuggerFullPath;
				
				GLOBAL.linuxTermName		= fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Compiler-textTerminalPath" ), "VALUE" ) ).dup;
			}
			
			GLOBAL.compilerAnootation					= fromStringz( IupGetAttribute( IupGetHandle( "toggleAnnotation" ), "VALUE" ) ).dup;
				if( IupGetHandle( "menuUseAnnotation" ) != null ) IupSetStrAttribute( IupGetHandle( "menuUseAnnotation" ), "VALUE", IupGetAttribute( IupGetHandle( "toggleAnnotation" ), "VALUE" ) );
			GLOBAL.compilerWindow						= fromStringz( IupGetAttribute( IupGetHandle( "toggleShowResultWindow" ), "VALUE" ) ).dup;
			GLOBAL.compilerSFX							= fromStringz( IupGetAttribute( IupGetHandle( "toggleSFX" ), "VALUE" ) ).dup;
			
			GLOBAL.delExistExe							= fromStringz( IupGetAttribute( IupGetHandle( "toggleDelPrevEXE" ), "VALUE" ) ).dup;
			GLOBAL.consoleExe							= fromStringz( IupGetAttribute( IupGetHandle( "toggleConsoleExe" ), "VALUE" ) ).dup;
				if( IupGetHandle( "menuUseConsoleApp" ) != null ) IupSetStrAttribute( IupGetHandle( "menuUseConsoleApp" ), "VALUE", IupGetAttribute( IupGetHandle( "toggleConsoleExe" ), "VALUE" ) );
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
						IupSetStrAttribute( _mHandle, "VALUE", "1" );
					}
					
					//IupSetAttribute( _mHandle, "VALUE", PreferenceDialogParameters.stringMonitor[0] << IupGetAttribute( _mHandle, "VALUE" ) );
				}
				_mHandle = IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textConsoleX" );
				if( _mHandle != null )
				{
					GLOBAL.consoleWindow.x = Integer.atoi( fromStringz( IupGetAttribute( _mHandle, "VALUE" ) ) );
					//IupSetStrAttribute( _mHandle, "VALUE", PreferenceDialogParameters.stringMonitor[1] );
				}
				_mHandle = IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textConsoleY" );
				if( _mHandle != null )
				{
					GLOBAL.consoleWindow.y = Integer.atoi( fromStringz( IupGetAttribute( _mHandle, "VALUE" ) ) );
					//IupSetAttribute( _mHandle, "VALUE", PreferenceDialogParameters.stringMonitor[2] << IupGetAttribute( _mHandle, "VALUE" ) );
				}
				_mHandle = IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textConsoleW" );
				if( _mHandle != null )
				{
					GLOBAL.consoleWindow.w = Integer.atoi( fromStringz( IupGetAttribute( _mHandle, "VALUE" ) ) );
					//IupSetAttribute( _mHandle, "VALUE", PreferenceDialogParameters.stringMonitor[3] << IupGetAttribute( _mHandle, "VALUE" ) );
				}
				_mHandle = IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textConsoleH" );
				if( _mHandle != null )
				{
					GLOBAL.consoleWindow.h = Integer.atoi( fromStringz( IupGetAttribute( _mHandle, "VALUE" ) ) );
					//IupSetAttribute( _mHandle, "VALUE", PreferenceDialogParameters.stringMonitor[4] << IupGetAttribute( _mHandle, "VALUE" ) );
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
				if( IupGetHandle( "menuFunctionTitle" ) != null ) IupSetAttribute( IupGetHandle( "menuFunctionTitle" ), "VALUE", IupGetAttribute( IupGetHandle( "toggleFunctionTitle" ), "VALUE" ) );
			
			
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
			
			_valHandle = IupGetHandle( "valTriggerDelay" );
			if( _valHandle != null )
			{
				int v = IupGetInt( _valHandle, "VALUE" );
				if( v < 50 ) v = 50;
				GLOBAL.triggerDelay = Integer.toString( v ).dup;
				AutoComplete.setTimer( v );
			}
			
			_valHandle = IupGetHandle( "valPreParseLevel" );
			if( _valHandle != null )
			{
				int v = IupGetInt( _valHandle, "VALUE" );
				GLOBAL.preParseLevel = v;
			}
			
			

			foreach( CScintilla cSci; GLOBAL.scintillaManager )
			{
				if( cSci !is null ) cSci.setGlobalSetting();
			}
			
			
			
			//=====================FONT=====================
			// Set Default Font
			if(  GLOBAL.fonts[0].fontString.length )
			{
				IupSetStrGlobal( "DEFAULTFONT", toStringz( GLOBAL.fonts[0].fontString ) );
				/*
				if( GLOBAL.fonts[0].fontString.length )
				{
					int comma = Util.index( GLOBAL.fonts[0].fontString, "," );
					if( comma < GLOBAL.fonts[0].fontString.length )
					{
						IupSetStrGlobal( "DEFAULTFONTFACE", toStringz( ( GLOBAL.fonts[0].fontString[0..comma] ).dup ) );

						for( int i = GLOBAL.fonts[0].fontString.length - 1; i > comma; -- i )
						{
							if( GLOBAL.fonts[0].fontString[i] < 48 || GLOBAL.fonts[0].fontString[i] > 57 )
							{
								IupSetStrGlobal( "DEFAULTFONTSIZE", toStringz( ( GLOBAL.fonts[0].fontString[i+1..$] ).dup ) );

								if( ++comma  < i ) IupSetStrGlobal( "DEFAULTFONTSTYLE", toStringz( ( GLOBAL.fonts[0].fontString[comma..i] ).dup ) );
								
								break;
							}
						}
					}
				}
				*/
			}			
			IupSetStrAttribute( GLOBAL.documentTabs, "TABFONT", toStringz( GLOBAL.fonts[0].fontString ) );
			IupSetStrAttribute( GLOBAL.documentTabs_Sub, "TABFONT", toStringz( GLOBAL.fonts[0].fontString ) );
			IupSetStrAttribute( GLOBAL.projectViewTabs, "FONT", toStringz( GLOBAL.fonts[2].fontString ) );// Leftside
			//IupSetStrAttribute( GLOBAL.fileListTree.getTreeHandle, "FONT", toStringz( GLOBAL.fonts[3].fontString ) );// Filelist
			IupSetStrAttribute( GLOBAL.messageWindowTabs, "FONT", toStringz( GLOBAL.fonts[6].fontString ) );// Bottom
			IupSetStrAttribute( GLOBAL.messagePanel.getOutputPanelHandle, "FONT", toStringz( GLOBAL.fonts[7].fontString ) );// Output
			IupSetStrAttribute( GLOBAL.messagePanel.getSearchOutputPanelHandle, "FONT", toStringz( GLOBAL.fonts[8].fontString ) );// Search
			IupSetStrAttribute( GLOBAL.statusBar.getLayoutHandle, "FONT", toStringz( GLOBAL.fonts[11].fontString ) );// StatusBar
			IupSetStrAttribute( GLOBAL.outlineTree.getZBoxHandle, "FONT", toStringz( GLOBAL.fonts[5].fontString ) );// Outline	
			IupSetStrAttribute( GLOBAL.projectTree.getTreeHandle, "FONT", toStringz( GLOBAL.fonts[4].fontString ) );// Project
			IupSetStrAttribute( GLOBAL.projectTree.getTreeHandle, "TITLEFONT0", toStringz( GLOBAL.fonts[4].fontString ) );
			IupSetStrAttribute( GLOBAL.projectTree.getTreeHandle, "TITLEFONTSTYLE0", "Bold" );// Project
			
			version(DIDE)
			{
				version(linux) GLOBAL.debugPanel.setFont();
			}
			else
			{
				GLOBAL.debugPanel.setFont();
			}
			
			version(FBIDE) GLOBAL.toggleUseManual						= fromStringz(IupGetAttribute( IupGetHandle( "toggleUseManual" ), "VALUE" )).dup;
			
			// Save Setup to Xml
			//IDECONFIG.save();
			IDECONFIG.saveINI();

			IupRefreshChildren( IupGetHandle( "PreferenceHandle" ) );
			


			if( GLOBAL.editorSetting01.OutlineFlat == "ON" )
			{
				//IupSetInt( GLOBAL.projectViewTabs, "VISIBLE", 1 );
				IupSetInt( GLOBAL.outlineTree.getZBoxHandle, "VISIBLE", 1 );
				IupSetInt( GLOBAL.projectTree.getTreeHandle, "VISIBLE", 1 );
			}
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

		IupSetAttribute( dlg, "VALUE", IupGetAttribute( ih, "FGCOLOR" ) ); // For IupFlatButton
		IupSetAttribute(dlg, "SHOWHEX", "YES");
		IupSetAttribute(dlg, "SHOWCOLORTABLE", "YES");
		IupSetAttribute(dlg, "TITLE", GLOBAL.languageItems["color"].toCString() );

		IupPopup( dlg, IUP_CURRENT, IUP_CURRENT );

		if( IupGetInt( dlg, "STATUS" ) )
		{
			IupSetStrAttribute( ih, "FGCOLOR", IupGetAttribute( dlg, "VALUE" ) ); // For IupFlatButton
			//IupSetFocus( GLOBAL.preferenceDlg.getIhandle );
			//IupSetFocus( ih );
			IupUpdateChildren( GLOBAL.preferenceDlg.getIhandle );
		}
		
		return IUP_DEFAULT;
	}

	private int CPreferenceDialog_FGcolorChooseScintilla_cb( Ihandle* ih )
	{
		Ihandle* dlg = IupColorDlg();

		IupSetAttribute( dlg, "VALUE", IupGetAttribute( ih, "FGCOLOR" ) );
		IupSetAttribute( dlg, "SHOWHEX", "YES" );
		IupSetAttribute( dlg, "SHOWCOLORTABLE", "YES" );
		IupSetAttribute( dlg, "TITLE", GLOBAL.languageItems["color"].toCString() );

		IupPopup( dlg, IUP_CURRENT, IUP_CURRENT );

		if( IupGetInt( dlg, "STATUS" ) )
		{
			auto _color = IupGetAttribute( dlg, "VALUE" );
			
			IupSetStrAttribute( ih, "FGCOLOR", _color ); IupSetFocus( ih );
			
			Ihandle* messageDlg = IupMessageDlg();
			IupSetAttributes( messageDlg, "DIALOGTYPE=QUESTION,BUTTONDEFAULT=2,BUTTONS=YESNO" );
			IupSetAttribute( messageDlg, "VALUE", GLOBAL.languageItems["applyfgcolor"].toCString );
			IupSetAttribute( messageDlg, "TITLE", GLOBAL.languageItems["quest"].toCString() );
			IupPopup( messageDlg, IUP_CENTER, IUP_CENTER );		
			int button = IupGetInt( messageDlg, "BUTTONRESPONSE" );
			
			if( button == 1 )
			{
				Ihandle* _ih = IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_COMMENT_FG" );
				if( ih != null )
				{
					IupSetStrAttribute( _ih, "FGCOLOR", _color );
					IupSetFocus( _ih );
				}
				
				_ih = IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_NUMBER_FG" );
				if( ih != null )
				{
					IupSetStrAttribute( _ih, "FGCOLOR", _color );
					IupSetFocus( _ih );
				}
				
				_ih = IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_STRING_FG" );
				if( ih != null )
				{
					IupSetStrAttribute( _ih, "FGCOLOR", _color );
					IupSetFocus( _ih );
				}
				
				_ih = IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_PREPROCESSOR_FG" );
				if( ih != null )
				{
					IupSetStrAttribute( _ih, "FGCOLOR", _color );
					IupSetFocus( _ih );
				}
				
				_ih = IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_OPERATOR_FG" );
				if( ih != null )
				{
					IupSetStrAttribute( _ih, "FGCOLOR", _color );
					IupSetFocus( _ih );
				}
				
				_ih = IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_IDENTIFIER_FG" );
				if( ih != null )
				{
					IupSetStrAttribute( _ih, "FGCOLOR", _color );
					IupSetFocus( _ih );
				}
				
				_ih = IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_COMMENTBLOCK_FG" );
				if( ih != null )
				{
					IupSetStrAttribute( _ih, "FGCOLOR", _color );
					IupSetFocus( _ih );
				}
			}
			
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
			auto _color = IupGetAttribute( dlg, "VALUE" );
			
			IupSetStrAttribute( ih, "FGCOLOR", _color ); IupSetFocus( ih );
			
			Ihandle* messageDlg = IupMessageDlg();
			IupSetAttributes( messageDlg, "DIALOGTYPE=QUESTION,BUTTONDEFAULT=2,BUTTONS=YESNO" );
			IupSetAttribute( messageDlg, "VALUE", GLOBAL.languageItems["applycolor"].toCString );
			IupSetAttribute( messageDlg, "TITLE", GLOBAL.languageItems["quest"].toCString() );
			IupPopup( messageDlg, IUP_CENTER, IUP_CENTER );		
			int button = IupGetInt( messageDlg, "BUTTONRESPONSE" );
			
			if( button == 1 )
			{
				Ihandle* _ih = IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_COMMENT_BG" );
				if( ih != null )
				{
					IupSetStrAttribute( _ih, "FGCOLOR", _color );
					IupSetFocus( _ih );
				}
				
				_ih = IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_NUMBER_BG" );
				if( ih != null )
				{
					IupSetStrAttribute( _ih, "FGCOLOR", _color );
					IupSetFocus( _ih );
				}
				
				_ih = IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_STRING_BG" );
				if( ih != null )
				{
					IupSetStrAttribute( _ih, "FGCOLOR", _color );
					IupSetFocus( _ih );
				}
				
				_ih = IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_PREPROCESSOR_BG" );
				if( ih != null )
				{
					IupSetStrAttribute( _ih, "FGCOLOR", _color );
					IupSetFocus( _ih );
				}
				
				_ih = IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_OPERATOR_BG" );
				if( ih != null )
				{
					IupSetStrAttribute( _ih, "FGCOLOR", _color );
					IupSetFocus( _ih );
				}
				
				_ih = IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_IDENTIFIER_BG" );
				if( ih != null )
				{
					IupSetStrAttribute( _ih, "FGCOLOR", _color );
					IupSetFocus( _ih );
				}
				
				_ih = IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_COMMENTBLOCK_BG" );
				if( ih != null )
				{
					IupSetStrAttribute( _ih, "FGCOLOR", _color );
					IupSetFocus( _ih );
				}
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
			
			if( colors.length > 60 ) return IUP_DEFAULT;
			
			for( int i = 0; i < colors.length; i ++ )
				if( PreferenceDialogParameters.kbg[i] is null ) PreferenceDialogParameters.kbg[i] = new IupString( colors[i] ); else PreferenceDialogParameters.kbg[i] = colors[i];
			
			//if( colors.length == 48 )
			//{
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnCaretLine" ), "FGCOLOR", PreferenceDialogParameters.kbg[0].toCString );					//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnCaretLine" ) );				
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnCursor" ), "FGCOLOR", PreferenceDialogParameters.kbg[1].toCString );						//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnCursor" ) );
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSelectFore" ), "FGCOLOR", PreferenceDialogParameters.kbg[2].toCString );					//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSelectFore" ) );
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSelectBack" ), "FGCOLOR", PreferenceDialogParameters.kbg[3].toCString );					//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSelectBack" ) );
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnLinenumFore" ), "FGCOLOR", PreferenceDialogParameters.kbg[4].toCString );					//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnLinenumFore" ) );
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnLinenumBack" ), "FGCOLOR", PreferenceDialogParameters.kbg[5].toCString );					//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnLinenumBack" ) );
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnFoldingColor" ), "FGCOLOR", PreferenceDialogParameters.kbg[6].toCString );				//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnFoldingColor" ) );

				version(Windows)
					IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textAlpha" ), "SPINVALUE", PreferenceDialogParameters.kbg[7].toCString );
				else
					IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textAlpha" ), "VALUE", PreferenceDialogParameters.kbg[7].toCString );

				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnBrace_FG" ), "FGCOLOR", PreferenceDialogParameters.kbg[8].toCString );					//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnBrace_FG" ) );
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnBrace_BG" ), "FGCOLOR", PreferenceDialogParameters.kbg[9].toCString );					//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnBrace_BG" ) );
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnError_FG" ), "FGCOLOR", PreferenceDialogParameters.kbg[10].toCString );					//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnError_FG" ) );
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnError_BG" ), "FGCOLOR", PreferenceDialogParameters.kbg[11].toCString );					//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSelectBack" ) );
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnWarning_FG" ), "FGCOLOR", PreferenceDialogParameters.kbg[12].toCString );					//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnWarning_FG" ) );
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnWarning_BG" ), "FGCOLOR", PreferenceDialogParameters.kbg[13].toCString );					//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnWarning_BG" ) );


				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btn_Scintilla_FG" ), "FGCOLOR", PreferenceDialogParameters.kbg[14].toCString );				//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btn_Scintilla_FG" ) );
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btn_Scintilla_BG" ), "FGCOLOR", PreferenceDialogParameters.kbg[15].toCString );				//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btn_Scintilla_BG" ) );

				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_COMMENT_FG" ), "FGCOLOR", PreferenceDialogParameters.kbg[16].toCString );			//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_COMMENT_FG" ) );
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_COMMENT_BG" ), "FGCOLOR", PreferenceDialogParameters.kbg[17].toCString );			//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_COMMENT_BG" ) );
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_NUMBER_FG" ), "FGCOLOR", PreferenceDialogParameters.kbg[18].toCString );			//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_NUMBER_FG" ) );
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_NUMBER_BG" ), "FGCOLOR", PreferenceDialogParameters.kbg[19].toCString );			//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_NUMBER_BG" ) );
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_STRING_FG" ), "FGCOLOR", PreferenceDialogParameters.kbg[20].toCString );			//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_STRING_FG" ) );
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_STRING_BG" ), "FGCOLOR", PreferenceDialogParameters.kbg[21].toCString );			//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_STRING_BG" ) );
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_PREPROCESSOR_FG" ), "FGCOLOR", PreferenceDialogParameters.kbg[22].toCString );		//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_PREPROCESSOR_FG" ) );
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_PREPROCESSOR_BG" ), "FGCOLOR", PreferenceDialogParameters.kbg[23].toCString );		//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_PREPROCESSOR_BG" ) );
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_OPERATOR_FG" ), "FGCOLOR", PreferenceDialogParameters.kbg[24].toCString );			//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_OPERATOR_FG" ) );
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_OPERATOR_BG" ), "FGCOLOR", PreferenceDialogParameters.kbg[25].toCString );			//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_OPERATOR_BG" ) );
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_IDENTIFIER_FG" ), "FGCOLOR", PreferenceDialogParameters.kbg[26].toCString );		//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_IDENTIFIER_FG" ) );
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_IDENTIFIER_BG" ), "FGCOLOR", PreferenceDialogParameters.kbg[27].toCString );		//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_IDENTIFIER_BG" ) );
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_COMMENTBLOCK_FG" ), "FGCOLOR", PreferenceDialogParameters.kbg[28].toCString );		//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_COMMENTBLOCK_FG" ) );
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_COMMENTBLOCK_BG" ), "FGCOLOR", PreferenceDialogParameters.kbg[29].toCString );		//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_COMMENTBLOCK_BG" ) );
				
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnPrj_FG" ), "FGCOLOR", PreferenceDialogParameters.kbg[30].toCString );						//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnPrj_FG" ) );
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnPrj_BG" ), "FGCOLOR", PreferenceDialogParameters.kbg[31].toCString );						//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnPrj_BG" ) );
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnOutline_FG" ), "FGCOLOR", PreferenceDialogParameters.kbg[32].toCString );					//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnOutline_FG" ) );
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnOutline_BG" ), "FGCOLOR", PreferenceDialogParameters.kbg[33].toCString );					//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnOutline_BG" ) );
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnDlg_FG" ), "FGCOLOR", PreferenceDialogParameters.kbg[34].toCString );				//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnFilelist_FG" ) );
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnDlg_BG" ), "FGCOLOR", PreferenceDialogParameters.kbg[35].toCString );				//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnFilelist_BG" ) );
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnOutput_FG" ), "FGCOLOR", PreferenceDialogParameters.kbg[36].toCString );					//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnOutput_FG" ) );
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnOutput_BG" ), "FGCOLOR", PreferenceDialogParameters.kbg[37].toCString );					//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnOutput_BG" ) );
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSearch_FG" ), "FGCOLOR", PreferenceDialogParameters.kbg[38].toCString );					//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSearch_FG" ) );
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSearch_BG" ), "FGCOLOR", PreferenceDialogParameters.kbg[39].toCString );					//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSearch_BG" ) );

				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnPrjTitle" ), "FGCOLOR", PreferenceDialogParameters.kbg[40].toCString );					//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnPrjTitle" ) );
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSourceTypeFolder" ), "FGCOLOR", PreferenceDialogParameters.kbg[41].toCString );			//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSourceTypeFolder" ) );
				
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord0Color" ), "FGCOLOR", PreferenceDialogParameters.kbg[42].toCString );				//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord0Color" ) );
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord1Color" ), "FGCOLOR", PreferenceDialogParameters.kbg[43].toCString );				//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord1Color" ) );
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord2Color" ), "FGCOLOR", PreferenceDialogParameters.kbg[44].toCString );				//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord2Color" ) );
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord3Color" ), "FGCOLOR", PreferenceDialogParameters.kbg[45].toCString );				//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord3Color" ) );
				
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnIndicator" ), "FGCOLOR", PreferenceDialogParameters.kbg[46].toCString );					//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnIndicator" ) );
				version(Windows)
					IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textIndicatorAlpha" ), "SPINVALUE", PreferenceDialogParameters.kbg[47].toCString );
				else
					IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textIndicatorAlpha" ), "VALUE", PreferenceDialogParameters.kbg[47].toCString );
					
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord4Color" ), "FGCOLOR", PreferenceDialogParameters.kbg[48].toCString );				//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord4Color" ) );
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord5Color" ), "FGCOLOR", PreferenceDialogParameters.kbg[49].toCString );				//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord5Color" ) );
				
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnTxt_FG" ), "FGCOLOR", PreferenceDialogParameters.kbg[50].toCString );				//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnFilelist_FG" ) );
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnTxt_BG" ), "FGCOLOR", PreferenceDialogParameters.kbg[51].toCString );				//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnFilelist_BG" ) );
				
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnLeftViewHLT" ), "FGCOLOR", PreferenceDialogParameters.kbg[52].toCString );
				version(Windows)
					IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textLeftViewHLTAplha" ), "SPINVALUE", PreferenceDialogParameters.kbg[53].toCString );
				else
					IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textLeftViewHLTAplha" ), "VALUE", PreferenceDialogParameters.kbg[53].toCString );
					
				
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnShowType_FG" ), "FGCOLOR", PreferenceDialogParameters.kbg[54].toCString );
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnShowType_BG" ), "FGCOLOR", PreferenceDialogParameters.kbg[55].toCString );
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnShowTypeHLT" ), "FGCOLOR", PreferenceDialogParameters.kbg[56].toCString );
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnCallTip_FG" ), "FGCOLOR", PreferenceDialogParameters.kbg[57].toCString );
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnCallTip_BG" ), "FGCOLOR", PreferenceDialogParameters.kbg[58].toCString );
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnCallTipHLT" ), "FGCOLOR", PreferenceDialogParameters.kbg[59].toCString );
				
				IupUpdateChildren( GLOBAL.preferenceDlg.getIhandle );
			//}
		}
		
		return IUP_DEFAULT;
	}
	
	private int colorTemplateList_reset_ACTION( Ihandle *ih )
	{
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnCaretLine" ), "FGCOLOR", "255 255 128" );		//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnCaretLine" ) );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnCursor" ), "FGCOLOR", "0 0 0" );					//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnCursor" ) );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSelectFore" ), "FGCOLOR", "255 255 255" );		//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSelectFore" ) );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSelectBack" ), "FGCOLOR", "0 0 255" );			//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSelectBack" ) );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnLinenumFore" ), "FGCOLOR", "0 0 0" );			//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnLinenumFore" ) );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnLinenumBack" ), "FGCOLOR", "200 200 200" );		//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnLinenumBack" ) );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnFoldingColor" ), "FGCOLOR", "241 243 243" );		//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnFoldingColor" ) );

		version(Windows)
			IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textAlpha" ), "SPINVALUE", "64" );
		else
			IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textAlpha" ), "VALUE", "64" );

		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnBrace_FG" ), "FGCOLOR", "255 0 0" );					//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnBrace_FG" ) );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnBrace_BG" ), "FGCOLOR", "0 255 0" );					//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnBrace_BG" ) );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnError_FG" ), "FGCOLOR", "102 69 3" );					//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnError_FG" ) );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnError_BG" ), "FGCOLOR", "255 200 227" );				//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnError_BG" ) );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnWarning_FG" ), "FGCOLOR", "0 0 255" );				//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnWarning_FG" ) );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnWarning_BG" ), "FGCOLOR", "255 255 157" );			//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnWarning_BG" ) );


		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btn_Scintilla_FG" ), "FGCOLOR", "0 0 0" );				//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btn_Scintilla_FG" ) );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btn_Scintilla_BG" ), "FGCOLOR", "255 255 255" );			//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btn_Scintilla_BG" ) );

		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_COMMENT_FG" ), "FGCOLOR", "0 128 0" );			//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_COMMENT_FG" ) );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_COMMENT_BG" ), "FGCOLOR", "255 255 255" );		//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_COMMENT_BG" ) );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_NUMBER_FG" ), "FGCOLOR", "128 128 64" );		//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_NUMBER_FG" ) );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_NUMBER_BG" ), "FGCOLOR", "255 255 255" );		//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_NUMBER_BG" ) );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_STRING_FG" ), "FGCOLOR", "128 0 0" );			//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_STRING_FG" ) );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_STRING_BG" ), "FGCOLOR", "255 255 255" );		//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_STRING_BG" ) );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_PREPROCESSOR_FG" ), "FGCOLOR", "0 0 255" );		//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_PREPROCESSOR_FG" ) );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_PREPROCESSOR_BG" ), "FGCOLOR", "255 255 255" );	//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_PREPROCESSOR_BG" ) );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_OPERATOR_FG" ), "FGCOLOR", "160 20 20" );		//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_OPERATOR_FG" ) );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_OPERATOR_BG" ), "FGCOLOR", "255 255 255" );		//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_OPERATOR_BG" ) );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_IDENTIFIER_FG" ), "FGCOLOR", "0 0 0" );			//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_IDENTIFIER_FG" ) );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_IDENTIFIER_BG" ), "FGCOLOR", "255 255 255" );	//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_IDENTIFIER_BG" ) );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_COMMENTBLOCK_FG" ), "FGCOLOR", "0 128 0" );		//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_COMMENTBLOCK_FG" ) );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_COMMENTBLOCK_BG" ), "FGCOLOR", "255 255 255" );	//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_COMMENTBLOCK_BG" ) );
		
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnPrj_FG" ), "FGCOLOR", "0 0 0" );						//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnPrj_FG" ) );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnPrj_BG" ), "FGCOLOR", "255 255 255" );				//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnPrj_BG" ) );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnOutline_FG" ), "FGCOLOR", "0 0 0" );					//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnOutline_FG" ) );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnOutline_BG" ), "FGCOLOR", "255 255 255" );			//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnOutline_BG" ) );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnDlg_FG" ), "FGCOLOR", "0 0 0" );					//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnFilelist_FG" ) );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnDlg_BG" ), "FGCOLOR", "240 240 240" );			//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnFilelist_BG" ) );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnOutput_FG" ), "FGCOLOR", "0 0 0" );					//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnOutput_FG" ) );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnOutput_BG" ), "FGCOLOR", "255 255 255" );				//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnOutput_BG" ) );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSearch_FG" ), "FGCOLOR", "0 0 0" );					//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSearch_FG" ) );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSearch_BG" ), "FGCOLOR", "255 255 255" );				//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSearch_BG" ) );
		
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnPrjTitle" ), "FGCOLOR", "128 0 0" );					//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnPrjTitle" ) );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSourceTypeFolder" ), "FGCOLOR", "0 0 255" );			//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSourceTypeFolder" ) );

		// Keyword Default
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord0Color" ), "FGCOLOR", "5 91 35" );	//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord0Color" ) );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord1Color" ), "FGCOLOR", "0 0 255" );	//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord1Color" ) );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord2Color" ), "FGCOLOR", "231 144 0" );	//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord2Color" ) );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord3Color" ), "FGCOLOR", "16 108 232" );	//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord3Color" ) );
		
		
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnIndicator" ), "FGCOLOR", "0 128 0" );				//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnIndicator" ) );
		version(Windows)
			IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textIndicatorAlpha" ), "SPINVALUE", "80" );
		else
			IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textIndicatorAlpha" ), "VALUE", "80" );


		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord4Color" ), "FGCOLOR", "255 0 0" );	//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord4Color" ) );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord5Color" ), "FGCOLOR", "0 255 0" );	//IupSetFocus( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord5Color" ) );

		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnTxt_FG" ), "FGCOLOR", "0 0 0" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnTxt_BG" ), "FGCOLOR", "255 255 255" ); //51
		
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnLeftViewHLT" ), "FGCOLOR", "255 255 255" ); //52
		version(Windows)
			IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textLeftViewHLTAplha" ), "SPINVALUE", "80" );
		else
			IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textLeftViewHLTAplha" ), "VALUE", "80" );
			
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnShowType_FG" ), "FGCOLOR", "0 0 255" ); //54
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnShowType_BG" ), "FGCOLOR", "255 255 170" ); //55
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnShowTypeHLT" ), "FGCOLOR", "0 128 0" ); //56
	
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnCallTip_FG" ), "FGCOLOR", "0 0 255" ); //57
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnCallTip_BG" ), "FGCOLOR", "234 248 192" ); //58
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnCallTipHLT" ), "FGCOLOR", "200 0 0" ); //59	
		

		IupSetAttribute( IupGetHandle( "colorTemplateList" ), "VALUE", "" );
		//GLOBAL.colorTemplate = cast(char[]) "";
		
		IupUpdateChildren( GLOBAL.preferenceDlg.getIhandle );
		
		//IupSetFocus( GLOBAL.preferenceDlg.getIhandle );
	
		return IUP_DEFAULT;
	}

	
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
											fontName ~= ( s ~ " " );
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

	private int valTriggerDelay_VALUECHANGED_CB( Ihandle *ih )
	{
		int value = IupGetInt( ih, "VALUE" );
		//IupSetInt( ih, "VALUE", value );
		IupSetAttribute( ih, "TIP", toStringz( Integer.toString( value ) ) );
		
		return IUP_DEFAULT;
	}
}