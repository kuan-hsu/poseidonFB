module dialogs.preferenceDlg;

private import iup.iup, iup.iup_scintilla;

private import layouts.table;

private import global, menu, IDE, project, tools, scintilla, actionManager, parser.autocompletion;
private import dialogs.baseDlg, dialogs.helpDlg, dialogs.fileDlg, dialogs.shortcutDlg;
private import std.string, std.file, std.conv, std.format, Path = std.path, Array = std.array, Conv = std.conv;
private import core.memory;

private struct PreferenceDialogParameters
{
	static		string[62]		stringSC;
	static		CTable			fontTable;
}

class CPreferenceDialog : CBaseDialog
{
private:
	import darkmode.darkmode;
	import Array = std.array;
	
	Ihandle* btnOpen, btnx64Open, btnOpenx64Debugger, btnOpenDebugger, colorDefaultRefresh, colorTemplateRemove, colorTemplateSave;
	version(Posix) Ihandle* btnOpenTerminal, btnOpenHtmlApp;
	
	void createLayout()
	{
		Ihandle* bottom = createDlgButton( "40x12", "aoc", "CPreferenceDialog" );

		Ihandle* textCompilerPath = IupText( null );
		IupSetAttributes( textCompilerPath, "SIZE=320x,NAME=Compiler-compilerPath,BORDER=NO" );
		IupSetStrAttribute( textCompilerPath, "VALUE", toStringz( GLOBAL.compilerSettings.compilerFullPath ) );
		
		btnOpen = IupButton( null, null );
		IupSetAttributes( btnOpen, "IMAGE=icon_openfile,FLAT=YES" );
		IupSetCallback( btnOpen, "ACTION", cast(Icallback) &CPreferenceDialog_OpenAppBinFile_cb );
		
		Ihandle* _hBox01 = IupHbox( textCompilerPath, btnOpen, null );
		IupSetAttributes( _hBox01, "ALIGNMENT=ACENTER,MARGIN=5x0" );
		
		Ihandle* hBox01 = IupFrame( _hBox01 );
		IupSetStrAttribute( hBox01, "TITLE", GLOBAL.languageItems["compilerpath"].toCString );
		IupSetAttributes( hBox01, "EXPANDCHILDREN=YES,SIZE=346x");

		Ihandle* hBox02, hBox01x64, hBox02x64;
		
		version(FBIDE)
		{
			version(Windows)
			{
				Ihandle* textx64CompilerPath = IupText( null );
				IupSetAttributes( textx64CompilerPath, "SIZE=320x,NAME=Compiler-x64compilerPath,BORDER=NO" );
				IupSetStrAttribute( textx64CompilerPath, "VALUE", toStringz( GLOBAL.compilerSettings.x64compilerFullPath ) );
				
				btnx64Open = IupButton( null, null );
				IupSetAttributes( btnx64Open, "IMAGE=icon_openfile,FLAT=YES" );
				IupSetCallback( btnx64Open, "ACTION", cast(Icallback) &CPreferenceDialog_OpenAppBinFile_cb );
				
				Ihandle* _hBox01x64 = IupHbox( textx64CompilerPath, btnx64Open, null );
				IupSetAttributes( _hBox01x64, "ALIGNMENT=ACENTER,MARGIN=5x0" );
				
				hBox01x64 = IupFrame( _hBox01x64 );
				IupSetStrAttribute( hBox01x64, "TITLE", GLOBAL.languageItems["x64path"].toCString );
				IupSetAttributes( hBox01x64, "EXPANDCHILDREN=YES,SIZE=346x");
				
				Ihandle* textx64DebuggerPath = IupText( null );
				IupSetAttributes( textx64DebuggerPath, "SIZE=320x,NAME=Compiler-x64DebuggerPath,BORDER=NO" );
				IupSetStrAttribute( textx64DebuggerPath, "VALUE", toStringz( GLOBAL.compilerSettings.x64debuggerFullPath ) );
				
				btnOpenx64Debugger = IupButton( null, null );
				IupSetAttributes( btnOpenx64Debugger, "IMAGE=icon_openfile,NAME=x64,FLAT=YES" );
				IupSetCallback( btnOpenx64Debugger, "ACTION", cast(Icallback) &CPreferenceDialog_OpenAppBinFile_cb );
				
				Ihandle* _hBox02x64 = IupHbox( textx64DebuggerPath, btnOpenx64Debugger, null );
				IupSetAttributes( _hBox02x64, "ALIGNMENT=ACENTER,MARGIN=5x0" );
				
				hBox02x64 = IupFrame( _hBox02x64 );
				IupSetStrAttribute( hBox02x64, "TITLE", GLOBAL.languageItems["debugx64path"].toCString );
				IupSetAttributes( hBox02x64, "EXPANDCHILDREN=YES,SIZE=346x");
			}


			Ihandle* textDebuggerPath = IupText( null );
			IupSetAttributes( textDebuggerPath, "SIZE=320x,NAME=Compiler-debuggerPath,BORDER=NO" );
			IupSetStrAttribute( textDebuggerPath, "VALUE", toStringz( GLOBAL.compilerSettings.debuggerFullPath ) );
			IupSetHandle( "debuggerPath_Handle", textDebuggerPath );
			
			btnOpenDebugger = IupButton( null, null );
			IupSetAttributes( btnOpenDebugger, "IMAGE=icon_openfile,NAME=x86,FLAT=YES" );
			IupSetCallback( btnOpenDebugger, "ACTION", cast(Icallback) &CPreferenceDialog_OpenAppBinFile_cb );
			
			Ihandle* _hBox02 = IupHbox( textDebuggerPath, btnOpenDebugger, null );
			IupSetAttributes( _hBox02, "ALIGNMENT=ACENTER,MARGIN=5x0" );
			
			hBox02 = IupFrame( _hBox02 );
			IupSetStrAttribute( hBox02, "TITLE", GLOBAL.languageItems["debugpath"].toCString );
			IupSetAttributes( hBox02, "EXPANDCHILDREN=YES,SIZE=346x");
		}
		else // DIDE
		{
			version(Windows)
			{
				Ihandle* textx64CompilerPath = IupText( null );
				IupSetAttributes( textx64CompilerPath, "SIZE=320x,NAME=Compiler-x64compilerPath,BORDER=NO" );
				IupSetStrAttribute( textx64CompilerPath, "VALUE", toStringz( GLOBAL.compilerSettings.x64compilerFullPath ) );
				
				btnx64Open = IupButton( null, null );
				IupSetAttributes( btnx64Open, "IMAGE=icon_openfile,FLAT=YES" );
				IupSetCallback( btnx64Open, "ACTION", cast(Icallback) &CPreferenceDialog_OpenAppBinFile_cb );
				
				Ihandle* _hBox01x64 = IupHbox( textx64CompilerPath, btnx64Open, null );
				IupSetAttributes( _hBox01x64, "ALIGNMENT=ACENTER,MARGIN=5x0" );
				
				hBox01x64 = IupFrame( _hBox01x64 );
				IupSetStrAttribute( hBox01x64, "TITLE", GLOBAL.languageItems["x64path"].toCString );
				IupSetAttributes( hBox01x64, "EXPANDCHILDREN=YES,SIZE=346x");
			}
			else
			{
				Ihandle* textDebuggerPath = IupText( null );
				IupSetAttributes( textDebuggerPath, "SIZE=320x,NAME=Compiler-debuggerPath,BORDER=NO" );
				IupSetStrAttribute( textDebuggerPath, "VALUE", toStringz( GLOBAL.compilerSettings.debuggerFullPath ) );
				IupSetHandle( "debuggerPath_Handle", textDebuggerPath );
				
				btnOpenDebugger = IupButton( null, null );
				IupSetAttributes( btnOpenDebugger, "IMAGE=icon_openfile,NAME=x86,FLAT=YES" );
				IupSetCallback( btnOpenDebugger, "ACTION", cast(Icallback) &CPreferenceDialog_OpenAppBinFile_cb );
				
				Ihandle* _hBox02 = IupHbox( textDebuggerPath, btnOpenDebugger, null );
				IupSetAttributes( _hBox02, "ALIGNMENT=ACENTER,MARGIN=5x0" );
				
				hBox02 = IupFrame( _hBox02 );
				IupSetStrAttribute( hBox02, "TITLE", GLOBAL.languageItems["debugpath"].toCString );
				IupSetAttributes( hBox02, "EXPANDCHILDREN=YES,SIZE=346x");			
			}
		}
		
		version(Posix)
		{
			Ihandle* textTerminalPath = IupText( null );
			IupSetAttributes( textTerminalPath, "SIZE=320x,NAME=Compiler-textTerminalPath,BORDER=NO" );
			IupSetStrAttribute( textTerminalPath, "VALUE", toStringz( GLOBAL.linuxTermName ) );
		
			btnOpenTerminal = IupButton( null, null );
			IupSetAttributes( btnOpenTerminal, "IMAGE=icon_openfile,FLAT=YES" );
			IupSetCallback( btnOpenTerminal, "ACTION", cast(Icallback) &CPreferenceDialog_OpenAppBinFile_cb );
			
			Ihandle* _hBox03 = IupHbox( textTerminalPath, btnOpenTerminal, null );
			IupSetAttributes( _hBox03, "ALIGNMENT=ACENTER,MARGIN=5x0" );
			
			Ihandle* hBox03 = IupFrame( _hBox03 );
			IupSetStrAttribute( hBox03, "TITLE", GLOBAL.languageItems["terminalpath"].toCString );
			IupSetAttributes( hBox03, "EXPANDCHILDREN=YES,SIZE=346x");
			
			
			Ihandle* textHtmlAppPath = IupText( null );
			IupSetAttributes( textHtmlAppPath, "SIZE=320x,NAME=Compiler-htmlappPath,BORDER=NO" );
			IupSetStrAttribute( textHtmlAppPath, "VALUE", toStringz( GLOBAL.linuxHtmlAppName ) );
		
			btnOpenHtmlApp = IupButton( null, null );
			IupSetAttributes( btnOpenHtmlApp, "IMAGE=icon_openfile,FLAT=YES" );
			IupSetCallback( btnOpenHtmlApp, "ACTION", cast(Icallback) &CPreferenceDialog_OpenAppBinFile_cb );
			
			Ihandle* _hBox04 = IupHbox( textHtmlAppPath, btnOpenHtmlApp, null );
			IupSetAttributes( _hBox04, "ALIGNMENT=ACENTER,MARGIN=5x0" );
			
			Ihandle* hBox04 = IupFrame( _hBox04 );
			IupSetStrAttribute( hBox04, "TITLE", GLOBAL.languageItems["htmlapppath"].toCString );
			IupSetAttributes( hBox04, "EXPANDCHILDREN=YES,SIZE=346x");			
		}		

		// compiler Setting
		Ihandle* toggleAnnotation = IupFlatToggle( GLOBAL.languageItems["errorannotation"].toCString );
		IupSetStrAttribute( toggleAnnotation, "VALUE", toStringz(GLOBAL.compilerSettings.useAnootation ) );
		IupSetHandle( "toggleAnnotation", toggleAnnotation );

		Ihandle* toggleShowResultWindow = IupFlatToggle( GLOBAL.languageItems["showresultwindow"].toCString );
		IupSetStrAttribute( toggleShowResultWindow, "VALUE", toStringz(GLOBAL.compilerSettings.useResultDlg) );
		IupSetHandle( "toggleShowResultWindow", toggleShowResultWindow );
		
		Ihandle* toggleSFX = IupFlatToggle( GLOBAL.languageItems["usesfx"].toCString );
		IupSetStrAttribute( toggleSFX, "VALUE", toStringz(GLOBAL.compilerSettings.useSFX) );
		IupSetHandle( "toggleSFX", toggleSFX );

		Ihandle* toggleDelPrevEXE = IupFlatToggle( GLOBAL.languageItems["delexistexe"].toCString );
		IupSetStrAttribute( toggleDelPrevEXE, "VALUE", toStringz(GLOBAL.compilerSettings.useDelExistExe) );
		IupSetHandle( "toggleDelPrevEXE", toggleDelPrevEXE );
		
		Ihandle* toggleConsoleExe = IupFlatToggle( GLOBAL.languageItems["consoleexe"].toCString );
		IupSetStrAttribute( toggleConsoleExe, "VALUE", toStringz(GLOBAL.compilerSettings.useConsoleLaunch) );
		IupSetHandle( "toggleConsoleExe", toggleConsoleExe );
		
		Ihandle* toggleCompileAtBackThread = IupFlatToggle( GLOBAL.languageItems["compileatbackthread"].toCString );
		IupSetStrAttribute( toggleCompileAtBackThread, "VALUE", toStringz(GLOBAL.compilerSettings.useThread) );
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
		
		IupSetInt( textMonitorID, "VALUE", GLOBAL.consoleWindow.id + 1 );
		IupSetInt( textConsoleX, "VALUE", GLOBAL.consoleWindow.x );
		IupSetInt( textConsoleY, "VALUE", GLOBAL.consoleWindow.y );
		IupSetInt( textConsoleW, "VALUE", GLOBAL.consoleWindow.w );
		IupSetInt( textConsoleH, "VALUE", GLOBAL.consoleWindow.h );
		
		IupSetAttribute( textMonitorID, "SIZE", "16x" );
		IupSetAttribute( textConsoleX, "SIZE", "24x" );
		IupSetAttribute( textConsoleY, "SIZE", "24x" );
		IupSetAttribute( textConsoleW, "SIZE", "24x" );
		IupSetAttribute( textConsoleH, "SIZE", "24x" );
		
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
		IupSetStrAttribute( frameCompiler, "TITLE", GLOBAL.languageItems["compilersetting"].toCString );
		IupSetAttributes( frameCompiler, "EXPANDCHILDREN=YES,SIZE=346x");
		
		Ihandle* vBoxCompilerSettings;
		version(Posix)
		{
			vBoxCompilerSettings = IupVbox( hBox01, hBox02, hBox03, hBox04, frameCompiler, null );
		}
		else
		{
			version(FBIDE) vBoxCompilerSettings = IupVbox( hBox01, hBox01x64, hBox02, hBox02x64, frameCompiler, null );
			version(DIDE) vBoxCompilerSettings = IupVbox( hBox01, hBox01x64, frameCompiler, null );
		}
		IupSetAttributes( vBoxCompilerSettings, "ALIGNMENT=ALEFT,MARGIN=2x5");
		IupSetAttribute( vBoxCompilerSettings, "EXPANDCHILDREN", "YES");


		// Parser Setting
		Ihandle* toggleKeywordComplete = IupFlatToggle( GLOBAL.languageItems["enablekeyword"].toCString );
		IupSetStrAttribute( toggleKeywordComplete, "VALUE", toStringz(GLOBAL.compilerSettings.enableKeywordComplete) );
		IupSetHandle( "toggleKeywordComplete", toggleKeywordComplete );
		
		Ihandle* toggleIncludeComplete = IupFlatToggle( GLOBAL.languageItems["enableinclude"].toCString );
		IupSetStrAttribute( toggleIncludeComplete, "VALUE", toStringz(GLOBAL.compilerSettings.enableIncludeComplete) );
		IupSetHandle( "toggleIncludeComplete", toggleIncludeComplete );
		
		
		//*******************
		Ihandle* toggleUseParser = IupFlatToggle( GLOBAL.languageItems["enableparser"].toCString );
		IupSetStrAttribute( toggleUseParser, "VALUE", toStringz(GLOBAL.parserSettings.enableParser) );
		IupSetHandle( "toggleUseParser", toggleUseParser );
		
		Ihandle* labelMaxHeight = IupLabel( GLOBAL.languageItems["autocmaxheight"].toCString );
		IupSetAttributes( labelMaxHeight, "SIZE=120x12,ALIGNMENT=ARIGHT:ACENTER" );
		
		Ihandle* textMaxHeight = IupText( null );
		IupSetAttributes( textMaxHeight, "SIZE=48x,MARGIN=0x0,SPIN=YES,SPINMAX=20,SPINMIN=5" );
		IupSetInt( textMaxHeight, "VALUE", GLOBAL.autoCMaxHeight );
		IupSetHandle( "textMaxHeight", textMaxHeight );

		Ihandle* hBoxUseParser = IupHbox( toggleUseParser, IupFill, labelMaxHeight, textMaxHeight, null );
		IupSetAttribute( hBoxUseParser, "ALIGNMENT", "ACENTER" );
		//********************
		
		
		Ihandle* labelTrigger = IupLabel( GLOBAL.languageItems["trigger"].toCString );
		//IupSetAttributes( labelTrigger, "SIZE=120x12" );
		
		Ihandle* textTrigger = IupText( null );
		IupSetAttributes( textTrigger, "SIZE=48x,MARGIN=0x0,SPIN=YES,SPINMAX=6,SPINMIN=0" );
		IupSetStrAttribute( textTrigger, "TIP", GLOBAL.languageItems["triggertip"].toCString );
		IupSetInt( textTrigger, "VALUE", GLOBAL.parserSettings.autoCompletionTriggerWordCount );
		IupSetHandle( "textTrigger", textTrigger );
		
		version(FBIDE)
		{
			Ihandle* labelIncludeLevel = IupLabel( GLOBAL.languageItems["includelevel"].toCString );
			//IupSetAttributes( labelIncludeLevel, "SIZE=120x12,GAP=0" );

			Ihandle* textIncludeLevel = IupText( null );
			IupSetAttributes( textIncludeLevel, "SIZE=48x,MARGIN=0x0,SPIN=YES,SPINMAX=6,SPINMIN=-1" );
			IupSetStrAttribute( textIncludeLevel, "TIP", GLOBAL.languageItems["includeleveltip"].toCString );
			IupSetInt( textIncludeLevel, "VALUE", GLOBAL.compilerSettings.includeLevel );
			IupSetHandle( "textIncludeLevel", textIncludeLevel );
		}
		
		
		
		
		Ihandle* toggleWithParams = IupFlatToggle( GLOBAL.languageItems["showtypeparam"].toCString );
		IupSetStrAttribute( toggleWithParams, "VALUE", toStringz(GLOBAL.parserSettings.showTypeWithParams) );
		IupSetHandle( "toggleWithParams", toggleWithParams );

		Ihandle* toggleIGNORECASE = IupFlatToggle( GLOBAL.languageItems["sortignorecase"].toCString );
		IupSetStrAttribute( toggleIGNORECASE, "VALUE", toStringz(GLOBAL.parserSettings.toggleIgnoreCase) );
		IupSetHandle( "toggleIGNORECASE", toggleIGNORECASE );

		Ihandle* toggleCASEINSENSITIVE = IupFlatToggle( GLOBAL.languageItems["selectcase"].toCString );
		IupSetStrAttribute( toggleCASEINSENSITIVE, "VALUE", toStringz(GLOBAL.parserSettings.toggleCaseInsensitive) );
		IupSetHandle( "toggleCASEINSENSITIVE", toggleCASEINSENSITIVE );
		/*
		Ihandle* toggleSHOWLISTTYPE = IupFlatToggle( GLOBAL.languageItems["showlisttype"].toCString );
		IupSetStrAttribute( toggleSHOWLISTTYPE, "VALUE", toStringz(GLOBAL.toggleShowListType) );
		IupSetHandle( "toggleSHOWLISTTYPE", toggleSHOWLISTTYPE );
		*/
		Ihandle* toggleSHOWALLMEMBER = IupFlatToggle( GLOBAL.languageItems["showallmembers"].toCString );
		IupSetStrAttribute( toggleSHOWALLMEMBER, "VALUE", toStringz(GLOBAL.compilerSettings.toggleShowAllMember) );
		IupSetHandle( "toggleSHOWALLMEMBER", toggleSHOWALLMEMBER );
		
		Ihandle* toggleDWELL = IupFlatToggle( GLOBAL.languageItems["enabledwell"].toCString );
		IupSetStrAttribute( toggleDWELL, "VALUE", toStringz(GLOBAL.parserSettings.toggleEnableDwell) );
		IupSetHandle( "toggleDWELL", toggleDWELL );
		
		Ihandle* labelDWELL = IupLabel( GLOBAL.languageItems["dwelldelay"].toCString );
		Ihandle* valDWELL = IupVal( null );
		IupSetAttributes( valDWELL, "MIN=200,MAX=2200,RASTERSIZE=100x16,STEP=0.05,PAGESTEP=0.05" );
		IupSetStrAttribute( valDWELL, "VALUE", toStringz( GLOBAL.parserSettings.dwellDelay ) );
		IupSetHandle( "valDWELL", valDWELL );
		IupSetCallback( valDWELL, "VALUECHANGED_CB", cast(Icallback) &valDWELL_VALUECHANGED_CB );
		IupSetCallback( valDWELL, "ENTERWINDOW_CB", cast(Icallback) &valDWELL_VALUECHANGED_CB );
		
		
		Ihandle* hBoxDWELL = IupHbox( toggleDWELL, IupFill, labelDWELL, valDWELL, null );
		IupSetAttributes( hBoxDWELL, "ALIGNMENT=ACENTER" );
		

		Ihandle* toggleOverWrite = IupFlatToggle( GLOBAL.languageItems["enableoverwrite"].toCString );
		IupSetStrAttribute( toggleOverWrite, "VALUE", toStringz(GLOBAL.parserSettings.toggleOverWrite) );
		IupSetHandle( "toggleOverWrite", toggleOverWrite );

		Ihandle* toggleBackThread = IupFlatToggle( GLOBAL.languageItems["completeatbackthread"].toCString );
		IupSetStrAttribute( toggleBackThread, "VALUE", toStringz(GLOBAL.parserSettings.toggleCompleteAtBackThread) );
		IupSetHandle( "toggleBackThread", toggleBackThread );
		
		Ihandle* labelTriggerDelay = IupLabel( GLOBAL.languageItems["completedelay"].toCString );
		Ihandle* valTriggerDelay = IupVal( null );
		IupSetAttributes( valTriggerDelay, "MIN=5,MAX=1000,RASTERSIZE=100x16,STEP=0.05265,PAGESTEP=0.1" );
		IupSetStrAttribute( valTriggerDelay, "VALUE", toStringz( GLOBAL.parserSettings.triggerDelay ) );
		IupSetHandle( "valTriggerDelay", valTriggerDelay );
		IupSetCallback( valTriggerDelay, "VALUECHANGED_CB", cast(Icallback) &valTriggerDelay_VALUECHANGED_CB );
		IupSetCallback( valTriggerDelay, "ENTERWINDOW_CB", cast(Icallback) &valTriggerDelay_VALUECHANGED_CB );	
		
		Ihandle* hBoxTriggerDelay = IupHbox( toggleBackThread, IupFill, labelTriggerDelay, valTriggerDelay, null );
		IupSetAttributes( hBoxTriggerDelay, "ALIGNMENT=ACENTER" );
		
		Ihandle* toggleFunctionTitle = IupFlatToggle( GLOBAL.languageItems["showtitle"].toCString );
		IupSetStrAttribute( toggleFunctionTitle, "VALUE", toStringz(GLOBAL.parserSettings.showFunctionTitle) );
		IupSetHandle( "toggleFunctionTitle", toggleFunctionTitle );
		
		Ihandle* toggleExtMacro = IupFlatToggle( GLOBAL.languageItems["enablemacro"].toCString );
		IupSetStrAttribute( toggleExtMacro, "VALUE", toStringz(GLOBAL.parserSettings.toggleExtendMacro) );
		IupSetHandle( "toggleExtMacro", toggleExtMacro );
		
		Ihandle* togglePreLoadPrj = IupFlatToggle( GLOBAL.languageItems["preloadprj"].toCString );
		IupSetStrAttribute( togglePreLoadPrj, "VALUE", toStringz(GLOBAL.parserSettings.togglePreLoadPrj) );
		IupSetHandle( "togglePreLoadPrj", togglePreLoadPrj );		

		Ihandle* labelPreParseLevel = IupLabel( GLOBAL.languageItems["preparselevel"].toCString );
		Ihandle* textPreParseLevel = IupText( null );
		IupSetAttributes( textPreParseLevel, "SIZE=48x,MARGIN=0x0,SPIN=YES,SPINMAX=5,SPINMIN=0" );
		IupSetInt( textPreParseLevel, "VALUE", GLOBAL.parserSettings.preParseLevel );
		IupSetHandle( "textPreParseLevel", textPreParseLevel );


		Ihandle* hBoxPreParseLevel = IupHbox( togglePreLoadPrj, IupFill, labelPreParseLevel, textPreParseLevel, null );
		IupSetAttributes( hBoxPreParseLevel, "ALIGNMENT=ACENTER" );



		Ihandle* toggleLiveNone = IupFlatToggle( GLOBAL.languageItems["none"].toCString );
		IupSetHandle( "toggleLiveNone", toggleLiveNone );

		Ihandle* toggleLiveLight = IupFlatToggle( GLOBAL.languageItems["light"].toCString );
		IupSetHandle( "toggleLiveLight", toggleLiveLight );
		
		Ihandle* toggleLiveFull = IupFlatToggle( GLOBAL.languageItems["full"].toCString );
		IupSetHandle( "toggleLiveFull", toggleLiveFull );

		Ihandle* toggleUpdateOutline = IupFlatToggle( GLOBAL.languageItems["update"].toCString );
		IupSetStrAttribute( toggleUpdateOutline, "VALUE", toStringz(GLOBAL.parserSettings.toggleUpdateOutlineLive) );
		IupSetHandle( "toggleUpdateOutline", toggleUpdateOutline );

		Ihandle* hBoxLive = IupHbox( toggleLiveNone, toggleLiveLight, toggleLiveFull, null );
		IupSetAttributes( hBoxLive, "ALIGNMENT=ACENTER,NORMALIZESIZE=HORIZONTAL,HOMOGENEOUS=YES" );
		Ihandle* radioLive = IupRadio( hBoxLive );

		Ihandle* hBoxLive2 = IupHbox( radioLive, toggleUpdateOutline, null );
		IupSetAttributes( hBoxLive2, "GAP=30,MARGIN=10x,ALIGNMENT=ACENTER" );
		
		Ihandle* frameLive = IupFrame( hBoxLive2 );
		IupSetAttributes( frameLive, "SIZE=346x" );
		IupSetStrAttribute( frameLive, "TITLE", GLOBAL.languageItems["parserlive"].toCString );

		switch( GLOBAL.parserSettings.liveLevel )
		{
			case 1:		IupSetAttribute( toggleLiveLight, "VALUE", "ON" ); break;
			case 2:		IupSetAttribute( toggleLiveFull, "VALUE", "ON" ); break;
			default:	IupSetAttribute( toggleLiveNone, "VALUE", "ON" ); break;
		}
		
		version(FBIDE)
		{
			Ihandle* toggleConditionNone = IupFlatToggle( GLOBAL.languageItems["none"].toCString );
			IupSetHandle( "toggleConditionNone", toggleConditionNone );

			Ihandle* toggleConditionCustom = IupFlatToggle( GLOBAL.languageItems["custom"].toCString );
			IupSetHandle( "toggleConditionCustom", toggleConditionCustom );
			
			Ihandle* toggleConditionFull = IupFlatToggle( GLOBAL.languageItems["full"].toCString );
			IupSetHandle( "toggleConditionFull", toggleConditionFull );

			Ihandle* hBoxCondition = IupHbox( toggleConditionNone, toggleConditionCustom, toggleConditionFull, null );
			IupSetAttributes( hBoxCondition, "ALIGNMENT=ACENTER,HOMOGENEOUS=YES,GAP=30,MARGIN=10x" );
			Ihandle* radioCondition = IupRadio( hBoxCondition );
			
			Ihandle* frameCondition = IupFrame( radioCondition );
			IupSetAttributes( frameCondition, "SIZE=346x" );
			IupSetStrAttribute( frameCondition, "TITLE", GLOBAL.languageItems["conditionalCompilation"].toCString );

			switch( GLOBAL.parserSettings.conditionalCompilation )
			{
				case 0:		IupSetAttribute( toggleConditionNone, "VALUE", "ON" ); break;
				case 2:		IupSetAttribute( toggleConditionFull, "VALUE", "ON" ); break;
				default:	IupSetAttribute( toggleConditionCustom, "VALUE", "ON" ); break;
			}
		}

		version(FBIDE)	Ihandle* hBox00 = IupHbox( labelTrigger, textTrigger, IupFill, labelIncludeLevel, textIncludeLevel, null );
		version(DIDE)	Ihandle* hBox00 = IupHbox( labelTrigger, textTrigger, null );
		IupSetAttributes( hBox00, "ALIGNMENT=ACENTER" ); 
		
		version(DIDE)
		{
			Ihandle* vBox00 = IupVbox( hBoxUseParser, toggleKeywordComplete, toggleIncludeComplete, toggleWithParams, toggleIGNORECASE, toggleCASEINSENSITIVE, toggleSHOWALLMEMBER, hBoxDWELL, toggleOverWrite, hBoxTriggerDelay, hBoxPreParseLevel, toggleFunctionTitle, hBox00, null );
		}
		else
		{
			Ihandle* vBox00 = IupVbox( hBoxUseParser, toggleKeywordComplete, toggleIncludeComplete, toggleWithParams, toggleIGNORECASE, toggleCASEINSENSITIVE, toggleSHOWALLMEMBER, hBoxDWELL, toggleOverWrite, hBoxTriggerDelay, hBoxPreParseLevel, toggleFunctionTitle, toggleExtMacro, hBox00, null );
		}
		IupSetAttributes( vBox00, "GAP=10,MARGIN=0x1,EXPANDCHILDREN=NO" );
	
		Ihandle* frameParser = IupFrame( vBox00 );
		IupSetStrAttribute( frameParser, "TITLE",  GLOBAL.languageItems["parsersetting"].toCString );
		IupSetAttribute( frameParser, "EXPANDCHILDREN", "YES");
		IupSetAttribute( frameParser, "SIZE", "346x");

		version(FBIDE) Ihandle* vBoxParserSettings = IupVbox( frameParser, frameLive, frameCondition, null ); else Ihandle* vBoxParserSettings = IupVbox( frameParser, frameLive, null );
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

		Ihandle* toggleColorBarLine = IupFlatToggle( GLOBAL.languageItems["colorbarline"].toCString );
		IupSetStrAttribute( toggleColorBarLine, "VALUE", toStringz(GLOBAL.editorSetting00.ColorBarLine ) );
		IupSetAttribute( toggleColorBarLine, "ALIGNMENT", "ALEFT:ACENTER" );
		IupSetHandle( "toggleColorBarLine", toggleColorBarLine );
		
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
		IupSetAttribute( textSetControlCharSymbol, "SIZE", "48x" );
		IupSetHandle( "textSetControlCharSymbol", textSetControlCharSymbol );
		Ihandle* hBoxControlChar = IupHbox( labelSetControlCharSymbol, textSetControlCharSymbol, null );
		IupSetAttribute( hBoxControlChar, "ALIGNMENT", "ACENTER" );
		
		Ihandle* labelTabWidth = IupLabel( GLOBAL.languageItems["tabwidth"].toCString );
		Ihandle* textTabWidth = IupText( null );
		IupSetStrAttribute( textTabWidth, "VALUE", toStringz( GLOBAL.editorSetting00.TabWidth ) );
		IupSetAttribute( textTabWidth, "SIZE", "48x" );
		IupSetHandle( "textTabWidth", textTabWidth );
		Ihandle* hBoxTab = IupHbox( labelTabWidth, textTabWidth, null );
		IupSetAttribute( hBoxTab, "ALIGNMENT", "ACENTER" );
		
		Ihandle* labelColumnEdge = IupLabel( GLOBAL.languageItems["columnedge"].toCString );
		Ihandle* textColumnEdge = IupText( null );
		IupSetStrAttribute( textColumnEdge, "VALUE", toStringz( GLOBAL.editorSetting00.ColumnEdge ) );
		IupSetStrAttribute( textColumnEdge, "TIP", GLOBAL.languageItems["triggertip"].toCString );
		IupSetAttribute( textColumnEdge, "SIZE", "48x" );
		IupSetHandle( "textColumnEdge", textColumnEdge );
		Ihandle* hBoxColumn = IupHbox( labelColumnEdge, textColumnEdge, null );
		IupSetAttribute( hBoxColumn, "ALIGNMENT", "ACENTER" );

		Ihandle* labelBarsize = IupLabel( GLOBAL.languageItems["barsize"].toCString );
		Ihandle* textBarSize = IupText( null );
		IupSetAttributes( textBarSize, "SIZE=48x,MARGIN=0x0,SPIN=YES,SPINMAX=5,SPINMIN=2" );
		IupSetStrAttribute( textBarSize, "VALUE", toStringz( GLOBAL.editorSetting01.BarSize ) );
		IupSetStrAttribute( textBarSize, "TIP", GLOBAL.languageItems["barsizetip"].toCString );
		IupSetHandle( "textBarSize", textBarSize );
		Ihandle* hBoxBarSize = IupHbox( labelBarsize, textBarSize, null );
		IupSetAttribute( hBoxBarSize, "ALIGNMENT", "ACENTER" );

		Ihandle* labelAscent = IupLabel( GLOBAL.languageItems["ascent"].toCString );
		Ihandle* textAscent = IupText( null );
		IupSetAttributes( textAscent, "SIZE=48x,MARGIN=0x0,SPIN=YES,SPINMAX=10,SPINMIN=-10" );
		IupSetStrAttribute( textAscent, "VALUE", toStringz( GLOBAL.editorSetting01.EXTRAASCENT ) );
		IupSetHandle( "textAscent", textAscent );
		Ihandle* hBoxAscent = IupHbox( labelAscent, textAscent, null );
		IupSetAttribute( hBoxAscent, "ALIGNMENT", "ACENTER" );

		Ihandle* labelDescent = IupLabel( GLOBAL.languageItems["descent"].toCString );
		Ihandle* textDescent = IupText( null );
		IupSetAttributes( textDescent, "SIZE=48x,MARGIN=0x0,SPIN=YES,SPINMAX=10,SPINMIN=-10" );
		IupSetStrAttribute( textDescent, "VALUE", toStringz( GLOBAL.editorSetting01.EXTRADESCENT ) );
		IupSetHandle( "textDescent", textDescent );
		Ihandle* hBoxDescent = IupHbox( labelDescent, textDescent, null );
		IupSetAttribute( hBoxDescent, "ALIGNMENT", "ACENTER" );

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
					
					toggleColorBarLine,
					IupFill(),
					
					hBoxTab,
					hBoxColumn,

					hBoxBarSize,
					hBoxControlChar,
					
					hBoxAscent,
					hBoxDescent,
					
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
					
					toggleColorBarLine,
					IupFill(),
					
					hBoxTab,
					hBoxColumn,

					hBoxBarSize,
					hBoxControlChar,
					
					hBoxAscent,
					hBoxDescent,
					
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
					toggleColorBarLine,
					
					hBoxTab,
					hBoxColumn,

					hBoxBarSize,
					hBoxControlChar,
					
					hBoxAscent,
					hBoxDescent,
					
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
					toggleColorBarLine,
					
					hBoxTab,
					hBoxColumn,

					hBoxBarSize,
					hBoxControlChar,
					
					hBoxAscent,
					hBoxDescent,
					
					null
				);
			}
		}
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

			Ihandle* radioKeywordCase4 = IupFlatToggle( GLOBAL.languageItems["usercase"].toCString );
			IupSetHandle( "radioKeywordCase4", radioKeywordCase4 );

			Ihandle* hBoxKeywordCase = IupHbox( radioKeywordCase0, radioKeywordCase1, radioKeywordCase2, radioKeywordCase3, radioKeywordCase4, null );
			IupSetAttributes( hBoxKeywordCase, "HOMOGENEOUS=YES,MARGIN=10x,ALIGNMENT=ACENTER" );

			Ihandle* frameKeywordCase = IupFrame( IupRadio( hBoxKeywordCase ) );
			IupSetAttributes( frameKeywordCase, "SIZE=346x,GAP=1" );
			IupSetStrAttribute( frameKeywordCase, "TITLE", GLOBAL.languageItems["autoconvertkeyword"].toCString );
			
			switch( GLOBAL.keywordCase )
			{
				case 0:		IupSetAttribute( radioKeywordCase0, "VALUE", "ON" ); break;
				case 1:		IupSetAttribute( radioKeywordCase1, "VALUE", "ON" ); break;
				case 2:		IupSetAttribute( radioKeywordCase2, "VALUE", "ON" ); break;
				case 3:		IupSetAttribute( radioKeywordCase3, "VALUE", "ON" ); break;
				default:	IupSetAttribute( radioKeywordCase4, "VALUE", "ON" ); break;
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
				string[] strings = Array.split( GLOBAL.fonts[i].fontString, "," );
				if( strings.length == 2 )
				{
					string size, style = " ";
					
					strings[0] = strip( strings[0] );
					auto spacePos = lastIndexOf( strings[1], " " );
					if( spacePos > -1 )
					{
						size = strings[1][spacePos+1..$].dup;
						style = strip( strings[1][0..spacePos] ).dup;
						if( !style.length ) style = " "; else style = " " ~ style ~ " ";
					}				

					PreferenceDialogParameters.fontTable.addItem( [ GLOBAL.languageItems[GLOBAL.fonts[i].name].toDString, strings[0], style, size ] );
				}
			}
		}
		Ihandle* sb = IupScrollBox( PreferenceDialogParameters.fontTable.getMainHandle );
		IupSetAttributes( sb, "ALIGNMENT=ACENTER" );
		
		
		
		version(FBIDE)	Ihandle* vBoxPage02 = IupVbox( gbox, frameKeywordCase, null );
		version(DIDE)	Ihandle* vBoxPage02 = IupVbox( gbox, null );
		IupSetAttributes( vBoxPage02, "MARGIN=4x1,EXPANDCHILDREN=YES" );

		// Color
		Ihandle* colorTemplateList = IupList( null );
		IupSetAttributes( colorTemplateList, "NAME=Color-colorTemplateList,ACTIVE=YES,EDITBOX=YES,EXPAND=HORIZONTAL,DROPDOWN=YES,VISIBLEITEMS=5" );
		IupSetStrAttribute( colorTemplateList, "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
		IupSetStrAttribute( colorTemplateList, "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
		version(Posix)
		{
			for( int i = 0; i < 6; ++i )
				IupSetStrAttributeId( colorTemplateList, "", i, "" ); // Add Dummy for linux
			
			IupSetStrAttributeId( colorTemplateList, "", 1, toStringz( " " ) );
		}		
		IupSetCallback( colorTemplateList, "DROPDOWN_CB",cast(Icallback) &colorTemplateList_DROPDOWN_CB );
		IupSetCallback( colorTemplateList, "ACTION",cast(Icallback) &colorTemplateList_ACTION_CB );

		colorDefaultRefresh = IupButton( null, null );
		IupSetAttributes( colorDefaultRefresh, "FLAT=NO,IMAGE=icon_refresh,FLAT=YES" );
		IupSetStrAttribute( colorDefaultRefresh, "TIP", GLOBAL.languageItems["default"].toCString() );
		IupSetCallback( colorDefaultRefresh, "ACTION", cast(Icallback) &colorTemplateList_reset_ACTION );

		colorTemplateRemove = IupButton( null, null );
		IupSetAttributes( colorTemplateRemove, "FLAT=NO,IMAGE=icon_debug_clear,FLAT=YES" );
		IupSetStrAttribute( colorTemplateRemove, "TIP", GLOBAL.languageItems["remove"].toCString() );
		IupSetCallback( colorTemplateRemove, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			Ihandle* _listHandle = IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-colorTemplateList" );
			if( _listHandle != null )
			{
				string templateName = strip( fSTRz( IupGetAttribute( _listHandle, "VALUE" ) ) );
				if( templateName.length )
				{
					string templatePath = "settings/colorTemplates";
					if( GLOBAL.linuxHome.length ) templatePath = GLOBAL.linuxHome ~ "/" ~ templatePath; // version(Windows) GLOBAL.linuxHome = null						
				
					for( int i = IupGetInt( _listHandle, "COUNT" ); i >= 1; -- i )
					{
						if( fromStringz( IupGetAttributeId( _listHandle, "", i ) ) == templateName )
						{
							string templateFullPath = templatePath ~ "/" ~templateName ~ ".ini";
							if( std.file.exists( templateFullPath ) )
							{
								int w, h;
								tools.splitBySign( fSTRz( IupGetAttribute( _listHandle, "RASTERSIZE" ) ), "x", w, h );
								int result = tools.MessageDlg( GLOBAL.languageItems["alarm"].toDString, GLOBAL.languageItems["suredelete"].toDString, "QUESTION", "YESNO", IupGetInt( _listHandle, "X" ), IupGetInt( _listHandle, "Y" ) + h );
								if( result == 1 )
								{
									std.file.remove( templateFullPath );
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
					tools.MessageDlg( GLOBAL.languageItems["alarm"].toDString, "No Items be Selected!", "WARNING", "", IUP_CENTERPARENT, IUP_CENTERPARENT );
				}
			}
			
			return IUP_DEFAULT;
		});
		
		colorTemplateSave = IupButton( null, null );
		IupSetAttributes( colorTemplateSave, "FLAT=NO,IMAGE=icon_save,FLAT=YES" );
		IupSetStrAttribute( colorTemplateSave, "TIP", GLOBAL.languageItems["save"].toCString );
		IupSetCallback( colorTemplateSave, "ACTION", cast(Icallback) function( Ihandle* ih )
		{
			Ihandle* _listHandle = IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-colorTemplateList" );
			int w, h;
			tools.splitBySign( fSTRz( IupGetAttribute( _listHandle, "RASTERSIZE" ) ), "x", w, h );			
			string templateName = strip( fSTRz( IupGetAttribute( _listHandle, "VALUE" ) ) );
			if( templateName.length )
			{
				try
				{
					IDECONFIG.saveColorTemplateINI( templateName );
					tools.MessageDlg( GLOBAL.languageItems["colorfile"].toDString, GLOBAL.languageItems["save"].toDString() ~ " " ~ GLOBAL.languageItems["ok"].toDString(), "INFORMATION", "", IupGetInt( _listHandle, "X" ), IupGetInt( _listHandle, "Y" ) + h );
				}
				catch( Exception e )
				{
					IupMessage( "ColorTemplate Save", toStringz( e.toString ) );
				}
			}
			else
			{
				tools.MessageDlg( GLOBAL.languageItems["alarm"].toDString, "Color Template Name Is Empty!", "WARNING", "", IupGetInt( _listHandle, "X" ), IupGetInt( _listHandle, "Y" ) + h );
			}
			
			return IUP_DEFAULT;
		});		
		
		
		Ihandle* _hboxColorPath = IupHbox( colorTemplateList, colorDefaultRefresh, colorTemplateRemove, colorTemplateSave, null );
		IupSetAttributes( _hboxColorPath, "ALIGNMENT=ACENTER,MARGIN=0x0,EXPAND=HORIZONTAL,SIZE=x12" );
		

		Ihandle* colorTemplateFrame = IupFrame( _hboxColorPath );
		IupSetStrAttribute( colorTemplateFrame, "TITLE", GLOBAL.languageItems["colorfile"].toCString() );
		IupSetAttributes( colorTemplateFrame, "EXPANDCHILDREN=YES,SIZE=346x");
		
		
		
		Ihandle* labelCaretLine = IupLabel( GLOBAL.languageItems["caretline"].toCString );
		Ihandle* btnCaretLine = IupFlatButton( null );
		IupSetStrAttribute( btnCaretLine, "FGCOLOR", toStringz( GLOBAL.editColor.caretLine ) );
		IupSetAttributes( btnCaretLine, "SIZE=16x8,NAME=Color-btnCaretLine" );
		IupSetCallback( btnCaretLine, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelCursor = IupLabel( GLOBAL.languageItems["cursor"].toCString );
		Ihandle* btnCursor = IupFlatButton( null );
		IupSetStrAttribute( btnCursor, "FGCOLOR", toStringz( GLOBAL.editColor.cursor ) );
		IupSetAttributes( btnCursor, "SIZE=16x8,NAME=Color-btnCursor" );
		IupSetCallback( btnCursor, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelSelectFore = IupLabel( GLOBAL.languageItems["sel"].toCString );
		Ihandle* btnSelectFore = IupFlatButton( null );
		IupSetStrAttribute( btnSelectFore, "FGCOLOR", toStringz( GLOBAL.editColor.selectionFore ) );
		IupSetAttributes( btnSelectFore, "SIZE=16x8,NAME=Color-btnSelectFore" );
		IupSetCallback( btnSelectFore, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* btnSelectBack = IupFlatButton( null );
		IupSetStrAttribute( btnSelectBack, "FGCOLOR", toStringz( GLOBAL.editColor.selectionBack ) );
		IupSetAttributes( btnSelectBack, "SIZE=16x8,NAME=Color-btnSelectBack" );
		IupSetCallback( btnSelectBack, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelLinenumFore = IupLabel( GLOBAL.languageItems["ln"].toCString  );
		Ihandle* btnLinenumFore = IupFlatButton( null );
		IupSetStrAttribute( btnLinenumFore, "FGCOLOR", toStringz( GLOBAL.editColor.linenumFore ) );
		IupSetAttributes( btnLinenumFore, "SIZE=16x8,NAME=Color-btnLinenumFore" );
		IupSetCallback( btnLinenumFore, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* btnLinenumBack = IupFlatButton( null );
		IupSetStrAttribute( btnLinenumBack, "FGCOLOR", toStringz( GLOBAL.editColor.linenumBack ) );
		IupSetAttributes( btnLinenumBack, "SIZE=16x8,NAME=Color-btnLinenumBack" );
		IupSetCallback( btnLinenumBack, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelFoldingColor = IupLabel( GLOBAL.languageItems["foldcolor"].toCString );
		Ihandle* btnFoldingColor = IupFlatButton( null );
		IupSetStrAttribute( btnFoldingColor, "FGCOLOR", toStringz( GLOBAL.editColor.fold ) );
		IupSetAttributes( btnFoldingColor, "SIZE=16x8,NAME=Color-btnFoldingColor" );
		IupSetCallback( btnFoldingColor, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* labelSelAlpha = IupLabel( GLOBAL.languageItems["selalpha"].toCString );
		Ihandle* textAlpha = IupText( null );
		IupSetAttributes( textAlpha, "SIZE=24x10,MARGIN=0x0,SPIN=YES,SPINMAX=255,SPINMIN=50,NAME=Color-textSelAlpha" );
		IupSetStrAttribute( textAlpha, "VALUE", toStringz( GLOBAL.editColor.selAlpha ) );
		IupSetStrAttribute( textAlpha, "TIP", GLOBAL.languageItems["alphatip"].toCString() );
		
		
		// 2017.1.14
		Ihandle* labelPrjTitle = IupLabel( GLOBAL.languageItems["prjtitle"].toCString );
		Ihandle* btnPrjTitle = IupFlatButton( null );
		IupSetStrAttribute( btnPrjTitle, "FGCOLOR", toStringz( GLOBAL.editColor.prjTitle ) );
		IupSetAttributes( btnPrjTitle, "SIZE=16x8,NAME=Color-btnPrjTitle" );
		IupSetCallback( btnPrjTitle, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );		

		Ihandle* labelSourceTypeFolder = IupLabel( GLOBAL.languageItems["sourcefolder"].toCString );
		Ihandle* btnSourceTypeFolder = IupFlatButton( null );
		IupSetStrAttribute( btnSourceTypeFolder, "FGCOLOR", toStringz( GLOBAL.editColor.prjSourceType ) );
		IupSetAttributes( btnSourceTypeFolder, "SIZE=16x8,NAME=Color-btnSourceTypeFolder" );
		IupSetCallback( btnSourceTypeFolder, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );		


		// 2017.7.9
		Ihandle* labelIndicator = IupLabel( GLOBAL.languageItems["hlcurrentword"].toCString );
		Ihandle* btnIndicator = IupFlatButton( null );
		IupSetStrAttribute( btnIndicator, "FGCOLOR", toStringz( GLOBAL.editColor.currentWord ) );
		IupSetAttributes( btnIndicator, "SIZE=16x8,NAME=Color-btnIndicator" );
		IupSetCallback( btnIndicator, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		Ihandle* textIndicatorAlpha = IupText( null );
		version(Windows) IupSetAttributes( textIndicatorAlpha, "SIZE=16x10,MARGIN=0x0,SPIN=YES,SPINMAX=255,SPINMIN=50,NAME=Color-textIndicatorAlpha" ); else IupSetAttributes( textIndicatorAlpha, "SIZE=16x10,MARGIN=0x0,NAME=Color-textIndicatorAlpha" );
		IupSetStrAttribute( textIndicatorAlpha, "VALUE", toStringz( GLOBAL.editColor.currentWordAlpha ) );
		IupSetStrAttribute( textIndicatorAlpha, "TIP", GLOBAL.languageItems["alphatip"].toCString() );




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

			null
		);
		version(Windows) IupSetAttributes( gboxColor, "EXPANDCHILDREN=HORIZONTAL,NUMDIV=4,ALIGNMENTLIN=ACENTER,ALIGNMENTCOL=ALEFT,GAPLIN=6,GAPCOL=30,MARGIN=2x8,SIZELIN=-1" ); else IupSetAttributes( gboxColor, "EXPANDCHILDREN=HORIZONTAL,NUMDIV=4,ALIGNMENTLIN=ACENTER,ALIGNMENTCOL=ALEFT,GAPLIN=10,GAPCOL=30,MARGIN=2x10,SIZELIN=1" );

		Ihandle* frameColor = IupFrame( gboxColor );
		IupSetAttributes( frameColor, "MARGIN=0x0,EXPAND=YES,EXPAND=HORIZONTAL" );
		IupSetAttribute( frameColor, "SIZE", "346x" );
		IupSetStrAttribute( frameColor, "TITLE", GLOBAL.languageItems["color"].toCString );

		
		// Color -1
		Ihandle* label_Scintilla = IupLabel( GLOBAL.languageItems["scintilla"].toCString );
		Ihandle* btn_Scintilla_FG = IupFlatButton( null );
		Ihandle* btn_Scintilla_BG = IupFlatButton( null );
		IupSetStrAttribute( btn_Scintilla_FG, "FGCOLOR", toStringz( GLOBAL.editColor.scintillaFore ) );
		IupSetStrAttribute( btn_Scintilla_BG, "FGCOLOR", toStringz( GLOBAL.editColor.scintillaBack ) );
		IupSetCallback( btn_Scintilla_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_FGcolorChooseScintilla_cb );
		IupSetCallback( btn_Scintilla_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChooseScintilla_cb );
		IupSetAttributes( btn_Scintilla_FG, "SIZE=16x8,NAME=Color-btn_Scintilla_FG" );
		IupSetAttributes( btn_Scintilla_BG, "SIZE=16x8,NAME=Color-btn_Scintilla_BG" );

		Ihandle* labelSCE_B_COMMENT = IupLabel( GLOBAL.languageItems["SCE_B_COMMENT"].toCString );
		Ihandle* btnSCE_B_COMMENT_FG = IupFlatButton( null );
		Ihandle* btnSCE_B_COMMENT_BG = IupFlatButton( null );
		IupSetStrAttribute( btnSCE_B_COMMENT_FG, "FGCOLOR", toStringz( GLOBAL.editColor.SCE_B_COMMENT_Fore ) );
		IupSetStrAttribute( btnSCE_B_COMMENT_BG, "FGCOLOR", toStringz( GLOBAL.editColor.SCE_B_COMMENT_Back ) );
		IupSetCallback( btnSCE_B_COMMENT_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnSCE_B_COMMENT_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnSCE_B_COMMENT_FG, "SIZE=16x8,NAME=Color-btnSCE_B_COMMENT_FG" );
		IupSetAttributes( btnSCE_B_COMMENT_BG, "SIZE=16x8,NAME=Color-btnSCE_B_COMMENT_BG" );
		
		Ihandle* labelSCE_B_NUMBER = IupLabel( GLOBAL.languageItems["SCE_B_NUMBER"].toCString  );
		Ihandle* btnSCE_B_NUMBER_FG = IupFlatButton( null );
		Ihandle* btnSCE_B_NUMBER_BG = IupFlatButton( null );
		IupSetStrAttribute( btnSCE_B_NUMBER_FG, "FGCOLOR", toStringz( GLOBAL.editColor.SCE_B_NUMBER_Fore ) );
		IupSetStrAttribute( btnSCE_B_NUMBER_BG, "FGCOLOR", toStringz( GLOBAL.editColor.SCE_B_NUMBER_Back ) );
		IupSetCallback( btnSCE_B_NUMBER_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnSCE_B_NUMBER_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnSCE_B_NUMBER_FG, "SIZE=16x8,NAME=Color-btnSCE_B_NUMBER_FG" );
		IupSetAttributes( btnSCE_B_NUMBER_BG, "SIZE=16x8,NAME=Color-btnSCE_B_NUMBER_BG" );
		
		Ihandle* labelSCE_B_STRING = IupLabel( GLOBAL.languageItems["SCE_B_STRING"].toCString );
		Ihandle* btnSCE_B_STRING_FG = IupFlatButton( null );
		Ihandle* btnSCE_B_STRING_BG = IupFlatButton( null );
		IupSetStrAttribute( btnSCE_B_STRING_FG, "FGCOLOR", toStringz( GLOBAL.editColor.SCE_B_STRING_Fore ) );
		IupSetStrAttribute( btnSCE_B_STRING_BG, "FGCOLOR", toStringz( GLOBAL.editColor.SCE_B_STRING_Back ) );
		IupSetCallback( btnSCE_B_STRING_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnSCE_B_STRING_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnSCE_B_STRING_FG, "SIZE=16x8,NAME=Color-btnSCE_B_STRING_FG" );
		IupSetAttributes( btnSCE_B_STRING_BG, "SIZE=16x8,NAME=Color-btnSCE_B_STRING_BG" );
		
		Ihandle* labelSCE_B_PREPROCESSOR = IupLabel( GLOBAL.languageItems["SCE_B_PREPROCESSOR"].toCString );
		Ihandle* btnSCE_B_PREPROCESSOR_FG = IupFlatButton( null );
		Ihandle* btnSCE_B_PREPROCESSOR_BG = IupFlatButton( null );
		IupSetStrAttribute( btnSCE_B_PREPROCESSOR_FG, "FGCOLOR", toStringz( GLOBAL.editColor.SCE_B_PREPROCESSOR_Fore ) );
		IupSetStrAttribute( btnSCE_B_PREPROCESSOR_BG, "FGCOLOR", toStringz( GLOBAL.editColor.SCE_B_PREPROCESSOR_Back ) );
		IupSetCallback( btnSCE_B_PREPROCESSOR_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnSCE_B_PREPROCESSOR_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnSCE_B_PREPROCESSOR_FG, "SIZE=16x8,NAME=Color-btnSCE_B_PREPROCESSOR_FG" );
		IupSetAttributes( btnSCE_B_PREPROCESSOR_BG, "SIZE=16x8,NAME=Color-btnSCE_B_PREPROCESSOR_BG" );
		
		Ihandle* labelSCE_B_OPERATOR = IupLabel( GLOBAL.languageItems["SCE_B_OPERATOR"].toCString );
		Ihandle* btnSCE_B_OPERATOR_FG = IupFlatButton( null );
		Ihandle* btnSCE_B_OPERATOR_BG = IupFlatButton( null );
		IupSetStrAttribute( btnSCE_B_OPERATOR_FG, "FGCOLOR", toStringz( GLOBAL.editColor.SCE_B_OPERATOR_Fore ) );
		IupSetStrAttribute( btnSCE_B_OPERATOR_BG, "FGCOLOR", toStringz( GLOBAL.editColor.SCE_B_OPERATOR_Back ) );
		IupSetCallback( btnSCE_B_OPERATOR_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnSCE_B_OPERATOR_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnSCE_B_OPERATOR_FG, "SIZE=16x8,NAME=Color-btnSCE_B_OPERATOR_FG" );
		IupSetAttributes( btnSCE_B_OPERATOR_BG, "SIZE=16x8,NAME=Color-btnSCE_B_OPERATOR_BG" );
		
		Ihandle* labelSCE_B_IDENTIFIER = IupLabel( GLOBAL.languageItems["SCE_B_IDENTIFIER"].toCString  );
		Ihandle* btnSCE_B_IDENTIFIER_FG = IupFlatButton( null );
		Ihandle* btnSCE_B_IDENTIFIER_BG = IupFlatButton( null );
		IupSetStrAttribute( btnSCE_B_IDENTIFIER_FG, "FGCOLOR", toStringz( GLOBAL.editColor.SCE_B_IDENTIFIER_Fore ) );
		IupSetStrAttribute( btnSCE_B_IDENTIFIER_BG, "FGCOLOR", toStringz( GLOBAL.editColor.SCE_B_IDENTIFIER_Back ) );
		IupSetCallback( btnSCE_B_IDENTIFIER_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnSCE_B_IDENTIFIER_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnSCE_B_IDENTIFIER_FG, "SIZE=16x8,NAME=Color-btnSCE_B_IDENTIFIER_FG" );
		IupSetAttributes( btnSCE_B_IDENTIFIER_BG, "SIZE=16x8,NAME=Color-btnSCE_B_IDENTIFIER_BG" );
		
		Ihandle* labelSCE_B_COMMENTBLOCK = IupLabel(  GLOBAL.languageItems["SCE_B_COMMENTBLOCK"].toCString  );
		Ihandle* btnSCE_B_COMMENTBLOCK_FG = IupFlatButton( null );
		Ihandle* btnSCE_B_COMMENTBLOCK_BG = IupFlatButton( null );
		IupSetStrAttribute( btnSCE_B_COMMENTBLOCK_FG, "FGCOLOR", toStringz( GLOBAL.editColor.SCE_B_COMMENTBLOCK_Fore ) );
		IupSetStrAttribute( btnSCE_B_COMMENTBLOCK_BG, "FGCOLOR", toStringz( GLOBAL.editColor.SCE_B_COMMENTBLOCK_Back ) );
		IupSetCallback( btnSCE_B_COMMENTBLOCK_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnSCE_B_COMMENTBLOCK_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnSCE_B_COMMENTBLOCK_FG, "SIZE=16x8,NAME=Color-btnSCE_B_COMMENTBLOCK_FG" );
		IupSetAttributes( btnSCE_B_COMMENTBLOCK_BG, "SIZE=16x8,NAME=Color-btnSCE_B_COMMENTBLOCK_BG" );
		
		
		
		
		Ihandle* labelDlg= IupLabel( GLOBAL.languageItems["dlgcolor"].toCString );
		Ihandle* btnDlg_FG = IupFlatButton( null );
		Ihandle* btnDlg_BG = IupFlatButton( null );
		IupSetStrAttribute( btnDlg_FG, "FGCOLOR", toStringz( GLOBAL.editColor.dlgFore ) );
		IupSetStrAttribute( btnDlg_BG, "FGCOLOR", toStringz( GLOBAL.editColor.dlgBack ) );	
		IupSetCallback( btnDlg_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnDlg_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnDlg_FG, "SIZE=16x8,NAME=Color-btnDlg_FG" );
		IupSetAttributes( btnDlg_BG, "SIZE=16x8,NAME=Color-btnDlg_BG" );
		
		Ihandle* labelTxt= IupLabel( GLOBAL.languageItems["txtcolor"].toCString );
		Ihandle* btnTxt_FG = IupFlatButton( null );
		Ihandle* btnTxt_BG = IupFlatButton( null );
		IupSetStrAttribute( btnTxt_FG, "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
		IupSetStrAttribute( btnTxt_BG, "FGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );	
		IupSetCallback( btnTxt_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnTxt_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnTxt_FG, "SIZE=16x8,NAME=Color-btnTxt_FG" );
		IupSetAttributes( btnTxt_BG, "SIZE=16x8,NAME=Color-btnTxt_BG" );		
		
		Ihandle* labelPrj = IupLabel( GLOBAL.languageItems["caption_prj"].toCString  );
		Ihandle* btnPrj_FG = IupFlatButton( null );
		Ihandle* btnPrj_BG = IupFlatButton( null );
		IupSetStrAttribute( btnPrj_FG, "FGCOLOR", toStringz( GLOBAL.editColor.projectFore ) );
		IupSetStrAttribute( btnPrj_BG, "FGCOLOR", toStringz( GLOBAL.editColor.projectBack ) );	
		IupSetCallback( btnPrj_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnPrj_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnPrj_FG, "SIZE=16x8,NAME=Color-btnPrj_FG" );
		IupSetAttributes( btnPrj_BG, "SIZE=16x8,NAME=Color-btnPrj_BG" );
		
		Ihandle* labelOutline = IupLabel( GLOBAL.languageItems["outline"].toCString );
		Ihandle* btnOutline_FG = IupFlatButton( null );
		Ihandle* btnOutline_BG = IupFlatButton( null );
		IupSetStrAttribute( btnOutline_FG, "FGCOLOR", toStringz( GLOBAL.editColor.outlineFore ) );
		IupSetStrAttribute( btnOutline_BG, "FGCOLOR", toStringz( GLOBAL.editColor.outlineBack ) );	
		IupSetCallback( btnOutline_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnOutline_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnOutline_FG, "SIZE=16x8,NAME=Color-btnOutline_FG" );
		IupSetAttributes( btnOutline_BG, "SIZE=16x8,NAME=Color-btnOutline_BG" );
		
		Ihandle* labelOutput= IupLabel( GLOBAL.languageItems["output"].toCString );
		Ihandle* btnOutput_FG = IupFlatButton( null );
		Ihandle* btnOutput_BG = IupFlatButton( null );
		IupSetStrAttribute( btnOutput_FG, "FGCOLOR", toStringz( GLOBAL.editColor.outputFore ) );
		IupSetStrAttribute( btnOutput_BG, "FGCOLOR", toStringz( GLOBAL.editColor.outputBack ) );	
		IupSetCallback( btnOutput_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnOutput_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnOutput_FG, "SIZE=16x8,NAME=Color-btnOutput_FG" );
		IupSetAttributes( btnOutput_BG, "SIZE=16x8,NAME=Color-btnOutput_BG" );
		
		Ihandle* labelSearch= IupLabel( GLOBAL.languageItems["caption_search"].toCString );
		Ihandle* btnSearch_FG = IupFlatButton( null );
		Ihandle* btnSearch_BG = IupFlatButton( null );
		IupSetStrAttribute( btnSearch_FG, "FGCOLOR", toStringz( GLOBAL.editColor.searchFore ) );
		IupSetStrAttribute( btnSearch_BG, "FGCOLOR", toStringz( GLOBAL.editColor.searchBack ) );	
		IupSetCallback( btnSearch_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnSearch_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnSearch_FG, "SIZE=16x8,NAME=Color-btnSearch_FG" );
		IupSetAttributes( btnSearch_BG, "SIZE=16x8,NAME=Color-btnSearch_BG" );
		
		Ihandle* labelError = IupLabel( GLOBAL.languageItems["manualerrorannotation"].toCString );
		Ihandle* btnError_FG = IupFlatButton( null );
		Ihandle* btnError_BG = IupFlatButton( null );
		IupSetStrAttribute( btnError_FG, "FGCOLOR", toStringz( GLOBAL.editColor.errorFore ) );
		IupSetStrAttribute( btnError_BG, "FGCOLOR", toStringz( GLOBAL.editColor.errorBack ) );	
		IupSetCallback( btnError_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnError_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnError_FG, "SIZE=16x8,NAME=Color-btnError_FG" );
		IupSetAttributes( btnError_BG, "SIZE=16x8,NAME=Color-btnError_BG" );
		
		Ihandle* labelWarning= IupLabel( GLOBAL.languageItems["manualwarningannotation"].toCString );
		Ihandle* btnWarning_FG = IupFlatButton( null );
		Ihandle* btnWarning_BG = IupFlatButton( null );
		IupSetStrAttribute( btnWarning_FG, "FGCOLOR", toStringz( GLOBAL.editColor.warningFore ) );
		IupSetStrAttribute( btnWarning_BG, "FGCOLOR", toStringz( GLOBAL.editColor.warningBack ) );	
		IupSetCallback( btnWarning_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnWarning_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnWarning_FG, "SIZE=16x8,NAME=Color-btnWarning_FG" );
		IupSetAttributes( btnWarning_BG, "SIZE=16x8,NAME=Color-btnWarning_BG" );
		
		Ihandle* labelBrace= IupLabel( GLOBAL.languageItems["bracehighlight"].toCString );
		Ihandle* btnBrace_FG = IupFlatButton( null );
		Ihandle* btnBrace_BG = IupFlatButton( null );
		IupSetStrAttribute( btnBrace_FG, "FGCOLOR", toStringz( GLOBAL.editColor.braceFore ) );
		IupSetStrAttribute( btnBrace_BG, "FGCOLOR", toStringz( GLOBAL.editColor.braceBack ) );	
		IupSetCallback( btnBrace_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnBrace_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnBrace_FG, "SIZE=16x8,NAME=Color-btnBrace_FG" );
		IupSetAttributes( btnBrace_BG, "SIZE=16x8,NAME=Color-btnBrace_BG" );

		
		auto labelLeftViewHLTTitle = new IupString( GLOBAL.languageItems["leftview"].toDString ~ " HLT:" );
		Ihandle* labelLeftViewHLT= IupLabel( labelLeftViewHLTTitle.toCString );
		Ihandle* btnLeftViewHLT = IupFlatButton( null );
		IupSetStrAttribute( btnLeftViewHLT, "FGCOLOR", toStringz( GLOBAL.editColor.prjViewHLT ) );
		IupSetCallback( btnLeftViewHLT, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnLeftViewHLT, "SIZE=16x8,NAME=Color-btnLeftViewHLT" );
		
		Ihandle* labelMessageIndicator = IupLabel( GLOBAL.languageItems["messageindicator"].toCString );
		Ihandle* btnMessageIndicator = IupFlatButton( null );
		IupSetStrAttribute( btnMessageIndicator, "FGCOLOR", toStringz( GLOBAL.editColor.searchIndicator ) );
		IupSetCallback( btnMessageIndicator, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnMessageIndicator, "SIZE=16x8,NAME=Color-btnMessageIndicator" );
		Ihandle* textMessageIndicatorAlpha = IupText( null );
		version(Windows) IupSetAttributes( textMessageIndicatorAlpha, "SIZE=16x10,MARGIN=0x0,SPIN=YES,SPINMAX=255,SPINMIN=50,NAME=Color-textMessageIndicatorAlpha" ); else IupSetAttributes( textMessageIndicatorAlpha, "SIZE=16x10,MARGIN=0x0,NAME=Color-textMessageIndicatorAlpha" );
		IupSetStrAttribute( textMessageIndicatorAlpha, "VALUE", toStringz( GLOBAL.editColor.searchIndicatorAlpha ) );
		
		Ihandle* labelShowType= IupLabel( GLOBAL.languageItems["showtype"].toCString );
		Ihandle* btnShowType_FG = IupFlatButton( null );
		Ihandle* btnShowType_BG = IupFlatButton( null );
		IupSetStrAttribute( btnShowType_FG, "FGCOLOR", toStringz( GLOBAL.editColor.showTypeFore ) );
		IupSetStrAttribute( btnShowType_BG, "FGCOLOR", toStringz( GLOBAL.editColor.showTypeBack ) );	
		IupSetCallback( btnShowType_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnShowType_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnShowType_FG, "SIZE=16x8,NAME=Color-btnShowType_FG" );
		IupSetAttributes( btnShowType_BG, "SIZE=16x8,NAME=Color-btnShowType_BG" );

		auto labelShowTypeHLTTitle = new IupString( GLOBAL.languageItems["showtype"].toDString ~ " HLT:" );
		Ihandle* labelShowTypeHLT= IupLabel( labelShowTypeHLTTitle.toCString );
		Ihandle* btnShowTypeHLT = IupFlatButton( null );
		IupSetStrAttribute( btnShowTypeHLT, "FGCOLOR", toStringz( GLOBAL.editColor.showTypeHLT ) );
		IupSetCallback( btnShowTypeHLT, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnShowTypeHLT, "SIZE=16x8,NAME=Color-btnShowTypeHLT" );		

		Ihandle* labelCallTip= IupLabel( GLOBAL.languageItems["calltip"].toCString );
		Ihandle* btnCallTip_FG = IupFlatButton( null );
		Ihandle* btnCallTip_BG = IupFlatButton( null );
		IupSetStrAttribute( btnCallTip_FG, "FGCOLOR", toStringz( GLOBAL.editColor.callTipFore ) );
		IupSetStrAttribute( btnCallTip_BG, "FGCOLOR", toStringz( GLOBAL.editColor.callTipBack ) );	
		IupSetCallback( btnCallTip_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnCallTip_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnCallTip_FG, "SIZE=16x8,NAME=Color-btnCallTip_FG" );
		IupSetAttributes( btnCallTip_BG, "SIZE=16x8,NAME=Color-btnCallTip_BG" );
		
		auto labelCallTipHLTTitle = new IupString( GLOBAL.languageItems["calltip"].toDString ~ " HLT:" );
		Ihandle* labelCallTipHLT= IupLabel( labelCallTipHLTTitle.toCString );
		Ihandle* btnCallTipHLT = IupFlatButton( null );
		IupSetStrAttribute( btnCallTipHLT, "FGCOLOR", toStringz( GLOBAL.editColor.callTipHLT ) );
		IupSetCallback( btnCallTipHLT, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnCallTipHLT, "SIZE=16x8,NAME=Color-btnCallTipHLT" );
		
		Ihandle* labelAutoComplete= IupLabel( GLOBAL.languageItems["autocomplete"].toCString );
		Ihandle* btnAutoComplete_FG = IupFlatButton( null );
		Ihandle* btnAutoComplete_BG = IupFlatButton( null );
		IupSetStrAttribute( btnAutoComplete_FG, "FGCOLOR", toStringz( GLOBAL.editColor.autoCompleteFore ) );
		IupSetStrAttribute( btnAutoComplete_BG, "FGCOLOR", toStringz( GLOBAL.editColor.autoCompleteBack ) );	
		IupSetCallback( btnAutoComplete_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnAutoComplete_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnAutoComplete_FG, "SIZE=16x8,NAME=Color-btnAutoComplete_FG" );
		IupSetAttributes( btnAutoComplete_BG, "SIZE=16x8,NAME=Color-btnAutoComplete_BG" );
		
		auto labelAutoCompleteHLTTitle = new IupString( GLOBAL.languageItems["autocomplete"].toDString ~ " HLT:" );
		Ihandle* labelAutoCompleteHLT= IupLabel( labelAutoCompleteHLTTitle.toCString );
		Ihandle* btnAutoCompleteHLT_FG = IupFlatButton( null );
		Ihandle* btnAutoCompleteHLT_BG = IupFlatButton( null );
		IupSetStrAttribute( btnAutoCompleteHLT_FG, "FGCOLOR", toStringz( GLOBAL.editColor.autoCompleteHLTFore ) );
		IupSetStrAttribute( btnAutoCompleteHLT_BG, "FGCOLOR", toStringz( GLOBAL.editColor.autoCompleteHLTBack ) );
		IupSetCallback( btnAutoCompleteHLT_FG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetCallback( btnAutoCompleteHLT_BG, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		IupSetAttributes( btnAutoCompleteHLT_FG, "SIZE=16x8,NAME=Color-btnAutoCompleteHLT_FG" );
		IupSetAttributes( btnAutoCompleteHLT_BG, "SIZE=16x8,NAME=Color-btnAutoCompleteHLT_BG" );

		Ihandle* labelProtected = IupLabel( GLOBAL.languageItems["protected"].toCString );
		Ihandle* btnProtected = IupFlatButton( null );
		IupSetStrAttribute( btnProtected, "FGCOLOR", toStringz( GLOBAL.editColor.protectedColor ) );
		IupSetAttributes( btnProtected, "SIZE=16x8,NAME=Color-btnProtected" );
		IupSetCallback( btnProtected, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		
		Ihandle* labelPrivate = IupLabel( GLOBAL.languageItems["private"].toCString );
		Ihandle* btnPrivate = IupFlatButton( null );
		IupSetStrAttribute( btnPrivate, "FGCOLOR", toStringz( GLOBAL.editColor.privateColor ) );
		IupSetAttributes( btnPrivate, "SIZE=16x8,NAME=Color-btnPrivate" );
		IupSetCallback( btnPrivate, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		version(Windows)
		{
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
				
				labelIndicator,
				btnIndicator,
				textIndicatorAlpha,
				IupFill(),
				labelMessageIndicator,
				btnMessageIndicator,
				textMessageIndicatorAlpha,
				
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
				labelLeftViewHLT,
				btnLeftViewHLT,
				IupFill(),
				
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
				
				labelAutoComplete,
				btnAutoComplete_FG,
				btnAutoComplete_BG,
				IupFill(),
				labelAutoCompleteHLT,
				btnAutoCompleteHLT_FG,
				btnAutoCompleteHLT_BG,
				
				labelProtected,
				btnProtected,
				IupFill(),
				IupFill(),
				labelPrivate,
				btnPrivate,
				IupFill(),				
				
				label_Scintilla,
				btn_Scintilla_FG,
				btn_Scintilla_BG,
				IupFill(),
				labelSCE_B_COMMENT,
				btnSCE_B_COMMENT_FG,
				btnSCE_B_COMMENT_BG,

				labelSCE_B_NUMBER,
				btnSCE_B_NUMBER_FG,
				btnSCE_B_NUMBER_BG,
				IupFill(),
				labelSCE_B_STRING,
				btnSCE_B_STRING_FG,
				btnSCE_B_STRING_BG,

				labelSCE_B_PREPROCESSOR,
				btnSCE_B_PREPROCESSOR_FG,
				btnSCE_B_PREPROCESSOR_BG,
				IupFill(),
				labelSCE_B_OPERATOR,
				btnSCE_B_OPERATOR_FG,
				btnSCE_B_OPERATOR_BG,

				labelSCE_B_IDENTIFIER,
				btnSCE_B_IDENTIFIER_FG,
				btnSCE_B_IDENTIFIER_BG,
				IupFill(),
				labelSCE_B_COMMENTBLOCK,
				btnSCE_B_COMMENTBLOCK_FG,
				btnSCE_B_COMMENTBLOCK_BG,

				null
			);
		}
		else
		{
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
				
				labelIndicator,
				btnIndicator,
				textIndicatorAlpha,
				IupFill(),
				labelMessageIndicator,
				btnMessageIndicator,
				textMessageIndicatorAlpha,
				
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
				labelLeftViewHLT,
				btnLeftViewHLT,
				IupFill(),
				
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
				
				labelProtected,
				btnProtected,
				IupFill(),
				IupFill(),
				labelPrivate,
				btnPrivate,
				IupFill(),

				label_Scintilla,
				btn_Scintilla_FG,
				btn_Scintilla_BG,
				IupFill(),
				labelSCE_B_COMMENT,
				btnSCE_B_COMMENT_FG,
				btnSCE_B_COMMENT_BG,

				labelSCE_B_NUMBER,
				btnSCE_B_NUMBER_FG,
				btnSCE_B_NUMBER_BG,
				IupFill(),
				labelSCE_B_STRING,
				btnSCE_B_STRING_FG,
				btnSCE_B_STRING_BG,

				labelSCE_B_PREPROCESSOR,
				btnSCE_B_PREPROCESSOR_FG,
				btnSCE_B_PREPROCESSOR_BG,
				IupFill(),
				labelSCE_B_OPERATOR,
				btnSCE_B_OPERATOR_FG,
				btnSCE_B_OPERATOR_BG,

				labelSCE_B_IDENTIFIER,
				btnSCE_B_IDENTIFIER_FG,
				btnSCE_B_IDENTIFIER_BG,
				IupFill(),
				labelSCE_B_COMMENTBLOCK,
				btnSCE_B_COMMENTBLOCK_FG,
				btnSCE_B_COMMENTBLOCK_BG,
				
				null
			);
		}
		
		IupSetAttributes( gboxColor_1, "SIZELIN =-1,NUMDIV=7,ALIGNMENTLIN=ACENTER,ALIGNMENTCOL=ALEFT,GAPLIN=4,GAPCOL=5,MARGIN=2x8,EXPANDCHILDREN=HORIZONTAL" );
		Ihandle* frameColor_1 = IupFrame( gboxColor_1 );
		IupSetAttributes( frameColor_1, "MARGIN=0x0,EXPAND=YES,EXPAND=HORIZONTAL" );
		IupSetStrAttribute( frameColor_1, "TITLE", GLOBAL.languageItems["colorfgbg"].toCString );
		
		
		// OPACITY
		Ihandle* labelGeneralDlg = IupLabel( GLOBAL.languageItems["general"].toCString );
		Ihandle* textGeneralDlg = IupText( null );
		IupSetAttributes( textGeneralDlg, "SIZE=16x10,MARGIN=0x0,SPIN=YES,SPINMAX=255,SPINMIN=100,NAME=Color-textGeneralDlg" );
		IupSetStrAttribute( textGeneralDlg, "VALUE", toStringz( GLOBAL.editorSetting02.generalDlg ) );
		
		Ihandle* labelMessageDlg = IupLabel( GLOBAL.languageItems["message"].toCString );
		Ihandle* textMessageDlg = IupText( null );
		IupSetAttributes( textMessageDlg, "SIZE=16x10,MARGIN=0x0,SPIN=YES,SPINMAX=255,SPINMIN=100,NAME=Color-textMessageDlg" );
		IupSetStrAttribute( textMessageDlg, "VALUE", toStringz( GLOBAL.editorSetting02.messageDlg ) );
		
		version(Windows)
		{
			Ihandle* labelAutoCompleteDlg = IupLabel( GLOBAL.languageItems["autocomplete"].toCString );
			Ihandle* textAutoCompleteDlg = IupText( null );
			IupSetAttributes( textAutoCompleteDlg, "SIZE=16x10,MARGIN=0x0,SPIN=YES,SPINMAX=255,SPINMIN=100,NAME=Color-textAutoCompleteDlg" );
			IupSetStrAttribute( textAutoCompleteDlg, "SPINVALUE", toStringz( GLOBAL.editorSetting02.autocompleteDlg ) );
		}
		
		version(Windows)
		{
			Ihandle* gboxOPACITY = IupGridBox
			(
				labelGeneralDlg,
				textGeneralDlg,
				IupFill,
				labelMessageDlg,
				textMessageDlg,
				IupFill,
				labelAutoCompleteDlg,
				textAutoCompleteDlg,		
				
				null
			);
		}
		else
		{
			Ihandle* gboxOPACITY = IupGridBox
			(
				labelGeneralDlg,
				textGeneralDlg,
				IupFill,
				IupFill,
				IupFill,
				
				null
			);
		}
		
		version(Windows)
			IupSetAttributes( gboxOPACITY, "SIZELIN =-1,NUMDIV=8,ALIGNMENTLIN=ACENTER,ALIGNMENTCOL=ALEFT,GAPLIN=8,GAPCOL=5,MARGIN=2x8,EXPANDCHILDREN=HORIZONTAL" );
		else
			IupSetAttributes( gboxOPACITY, "SIZELIN =-1,NUMDIV=5,ALIGNMENTLIN=ACENTER,ALIGNMENTCOL=ALEFT,GAPLIN=8,GAPCOL=5,MARGIN=2x8,EXPANDCHILDREN=HORIZONTAL" );
		
		Ihandle* frameOPACITY = IupFrame( gboxOPACITY );
		IupSetAttributes( frameOPACITY, "MARGIN=0x0,EXPAND=YES,EXPAND=HORIZONTAL" );
		IupSetStrAttribute( frameOPACITY, "TITLE", GLOBAL.languageItems["dialogopacity"].toCString );
		
		
		// Bottom
		Ihandle* toggleIcon = IupFlatToggle( GLOBAL.languageItems["no"].toCString );
		IupSetAttributes( toggleIcon, "NAME=Color-toggleIcon" );

		Ihandle* toggleIconInvert = IupFlatToggle( GLOBAL.languageItems["yes"].toCString );
		IupSetAttributes( toggleIconInvert, "NAME=Color-toggleIconInvert" );
		
		Ihandle* toggleIconInvertAll = IupFlatToggle( GLOBAL.languageItems["all"].toCString );
		IupSetAttributes( toggleIconInvertAll, "NAME=Color-toggleIconInvertAll" );

		Ihandle* toggleDarkMode = IupFlatToggle( GLOBAL.languageItems["usedarkmode"].toCString );
		IupSetStrAttribute( toggleDarkMode, "VALUE", toStringz(GLOBAL.editorSetting00.UseDarkMode) );
		IupSetAttributes( toggleDarkMode, "NAME=Color-toggleDarkMode,ALIGNMENT=ALEFT:ACENTER" );

		Ihandle* hBoxIcon = IupHbox( toggleIcon, toggleIconInvert, toggleIconInvertAll, null );
		IupSetAttributes( hBoxIcon, "ALIGNMENT=ACENTER,HOMOGENEOUS=YES,EXPANDCHILDREN=YES" );
		Ihandle* radioIcon = IupRadio( hBoxIcon );

		version(Windows)
			Ihandle* hBoxIcon2 = IupHbox( radioIcon, toggleDarkMode, null );
		else
		{
			//IupSetAttributes( hBoxIcon, "SIZE=346x" );
			Ihandle* hBoxIcon2 = IupHbox( radioIcon, null );
		}
			
		IupSetAttributes( hBoxIcon2, "ALIGNMENT=ACENTER,HOMOGENEOUS=YES,NORMALIZESIZE=HORIZONTAL" );
		
		Ihandle* frameIcon = IupFrame( hBoxIcon2 );
		IupSetAttributes( frameIcon, "SIZE=346x" );
		IupSetStrAttribute( frameIcon, "TITLE", GLOBAL.languageItems["iconinvert"].toCString );
		
		if( GLOBAL.editorSetting00.IconInvert == "OFF" )
			IupSetAttribute( toggleIcon, "VALUE", "ON" );
		else if( GLOBAL.editorSetting00.IconInvert == "ON" )
			IupSetAttribute( toggleIconInvert, "VALUE", "ON" );
		else
			IupSetAttribute( toggleIconInvertAll, "VALUE", "ON" );
		

		// Combine
		Ihandle* vColor = IupVbox( colorTemplateFrame, frameColor, frameColor_1, frameIcon, frameOPACITY, null );
		IupSetAttributes( vColor, "ALIGNMENT=ACENTER,EXPANDCHILDREN=YES,HOMOGENEOUS=NO,GAP=0" );


		// Short Cut
		Ihandle* shortCutList = IupList( null );
		IupSetAttributes( shortCutList, "SIZE=150x200,MULTIPLE=NO,MARGIN=2x10,VISIBLECOLUMNS=YES,EXPAND=YES,AUTOHIDE=YES,SHOWIMAGE=YES" );
		/*
		IupSetStrAttribute( shortCutList, "FONT", toStringz( GLOBAL.fonts[11].fontString ) );
		IupSetAttribute( shortCutList, "FONTSIZE", "10" );
		*/
		version( Windows ) IupSetAttribute( shortCutList, "FONT", "Consolas,10" ); else IupSetAttribute( shortCutList, "FONT", "Monospace, 10" );
		IupSetHandle( "shortCutList", shortCutList );
		IupSetCallback( shortCutList, "DBLCLICK_CB", cast(Icallback) &CPreferenceDialog_shortCutList_DBLCLICK_CB );

		int ID = 0;
		for( int i = 0; i < GLOBAL.shortKeys.length; ++ i )
		{
			ID ++;
			switch( i )
			{
				case 0:
					IupSetStrAttributeId( shortCutList, "", ID, toStringz( "[" ~ GLOBAL.languageItems["file"].toDString ~ "]" ) ); 
					IupSetAttributeId( shortCutList, "IMAGE", ID, "icon_prj_open" ); 
					ID++;
					break;
				case 6:
					IupSetStrAttributeId( shortCutList, "", ID, toStringz( "[" ~ GLOBAL.languageItems["edit"].toDString ~ "]" ) );
					IupSetAttributeId( shortCutList, "IMAGE", ID, "icon_search" ); 
					ID++;
					break;
				case 19:
					IupSetStrAttributeId( shortCutList, "", ID, toStringz( "[" ~ GLOBAL.languageItems["parser"].toDString ~ "]" ) );
					IupSetAttributeId( shortCutList, "IMAGE", ID, "icon_refresh" ); 
					ID++;
					break;
				case 25:
					IupSetStrAttributeId( shortCutList, "", ID, toStringz( "[" ~ GLOBAL.languageItems["build"].toDString ~ "]" ) );
					IupSetAttributeId( shortCutList, "IMAGE", ID, "icon_compile" );
					ID++;
					break;
				case 29:
					IupSetStrAttributeId( shortCutList, "", ID, toStringz( "[" ~ GLOBAL.languageItems["windows"].toDString ~ "]" ) );
					IupSetAttributeId( shortCutList, "IMAGE", ID, "icon_gui" );
					ID++;
					break;
				case 33:
					IupSetStrAttributeId( shortCutList, "", ID, toStringz( "[" ~ GLOBAL.languageItems["setcustomtool"].toDString ~ "]" ) );
					IupSetAttributeId( shortCutList, "IMAGE", ID, "icon_toolitem" );
					ID++;
					break;
				default:
			}
			
			string keyValue = IDECONFIG.convertShortKeyValue2String( GLOBAL.shortKeys[i].keyValue );
			string[] splitWord = Array.split( keyValue, "+" );
			if( splitWord.length == 4 ) 
			{
				if( splitWord[0] == "C" )  splitWord[0] = "Ctrl";
				if( splitWord[1] == "S" )  splitWord[1] = "Shift";
				if( splitWord[2] == "A" )  splitWord[2] = "Alt";
			}
			
			//Stdout.layout.convert( " {,-5} + {,-5} + {,-5} + {,-5} {,-40}", splitWord[0], splitWord[1], splitWord[2], splitWord[3], GLOBAL.shortKeys[i].title )
			auto formatString = format( " %-5s + %-5s + %-5s + %-5s %-40s", splitWord[0], splitWord[1], splitWord[2], splitWord[3], GLOBAL.shortKeys[i].title );
			IupSetStrAttributeId( shortCutList, "",  ID, toStringz( formatString ) );
		}



		Ihandle* keyWordText0 = IupText( null );
		IupSetAttributes( keyWordText0, "MULTILINE=YES,EXPAND=YES,WORDWRAP=YES,AUTOHIDE=YES,SCROLLBAR=YES,PADDING=2x2" );
		IupSetStrAttribute( keyWordText0, "VALUE", toStringz( GLOBAL.parserSettings.KEYWORDS[0] ) );
		IupSetHandle( "keyWordText0", keyWordText0 );
		Ihandle* keyWordText1 = IupText( null );
		IupSetAttributes( keyWordText1, "MULTILINE=YES,EXPAND=YES,WORDWRAP=YES,AUTOHIDE=YES,SCROLLBAR=YES,PADDING=2x2" );
		IupSetStrAttribute( keyWordText1, "VALUE", toStringz( GLOBAL.parserSettings.KEYWORDS[1] ) );
		IupSetHandle( "keyWordText1", keyWordText1 );
		Ihandle* keyWordText2 = IupText( null );
		IupSetAttributes( keyWordText2, "MULTILINE=YES,EXPAND=YES,WORDWRAP=YES,AUTOHIDE=YES,SCROLLBAR=YES,PADDING=2x2" );
		IupSetStrAttribute( keyWordText2, "VALUE", toStringz( GLOBAL.parserSettings.KEYWORDS[2] ) );
		IupSetHandle( "keyWordText2", keyWordText2 );
		Ihandle* keyWordText3 = IupText( null );
		IupSetAttributes( keyWordText3, "MULTILINE=YES,EXPAND=YES,WORDWRAP=YES,AUTOHIDE=YES,SCROLLBAR=YES,PADDING=2x2" );
		IupSetStrAttribute( keyWordText3, "VALUE", toStringz( GLOBAL.parserSettings.KEYWORDS[3] ) );
		IupSetHandle( "keyWordText3", keyWordText3 );
		Ihandle* keyWordText4 = IupText( null );
		IupSetAttributes( keyWordText4, "MULTILINE=YES,EXPAND=YES,WORDWRAP=YES,AUTOHIDE=YES,SCROLLBAR=YES,PADDING=2x2" );
		IupSetStrAttribute( keyWordText4, "VALUE", toStringz( GLOBAL.parserSettings.KEYWORDS[4] ) );
		IupSetHandle( "keyWordText4", keyWordText4 );
		Ihandle* keyWordText5 = IupText( null );
		IupSetAttributes( keyWordText5, "MULTILINE=YES,EXPAND=YES,WORDWRAP=YES,AUTOHIDE=YES,SCROLLBAR=YES,PADDING=2x2" );
		IupSetStrAttribute( keyWordText5, "VALUE", toStringz( GLOBAL.parserSettings.KEYWORDS[5] ) );
		IupSetHandle( "keyWordText5", keyWordText5 );
		
		
		
		Ihandle* btnKeyWord0Color = IupFlatButton( null );
		IupSetStrAttribute( btnKeyWord0Color, "FGCOLOR", toStringz( GLOBAL.editColor.keyWord[0] ) );
		IupSetAttributes( btnKeyWord0Color, "SIZE=36x8,NAME=Color-btnKeyWord0Color" );
		IupSetCallback( btnKeyWord0Color, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* btnKeyWord1Color = IupFlatButton( null );
		IupSetStrAttribute( btnKeyWord1Color, "FGCOLOR", toStringz( GLOBAL.editColor.keyWord[1] ) );
		IupSetAttributes( btnKeyWord1Color, "SIZE=36x8,NAME=Color-btnKeyWord1Color" );
		IupSetCallback( btnKeyWord1Color, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* btnKeyWord2Color = IupFlatButton( null );
		IupSetStrAttribute( btnKeyWord2Color, "FGCOLOR", toStringz( GLOBAL.editColor.keyWord[2] ) );
		IupSetAttributes( btnKeyWord2Color, "SIZE=36x8,NAME=Color-btnKeyWord2Color" );
		IupSetCallback( btnKeyWord2Color, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* btnKeyWord3Color = IupFlatButton( null );
		IupSetStrAttribute( btnKeyWord3Color, "FGCOLOR", toStringz( GLOBAL.editColor.keyWord[3] ) );
		IupSetAttributes( btnKeyWord3Color, "SIZE=36x8,NAME=Color-btnKeyWord3Color" );
		IupSetCallback( btnKeyWord3Color, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* btnKeyWord4Color = IupFlatButton( null );
		IupSetStrAttribute( btnKeyWord4Color, "FGCOLOR", toStringz( GLOBAL.editColor.keyWord[4] ) );
		IupSetAttributes( btnKeyWord4Color, "SIZE=36x8,NAME=Color-btnKeyWord4Color" );
		IupSetCallback( btnKeyWord4Color, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );

		Ihandle* btnKeyWord5Color = IupFlatButton( null );
		IupSetStrAttribute( btnKeyWord5Color, "FGCOLOR", toStringz( GLOBAL.editColor.keyWord[5] ) );
		IupSetAttributes( btnKeyWord5Color, "SIZE=36x8,NAME=Color-btnKeyWord5Color" );
		IupSetCallback( btnKeyWord5Color, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_colorChoose_cb );
		

		Ihandle* vBoxKeyWord0 = IupVbox( btnKeyWord0Color, keyWordText0, null );
		IupSetAttribute( vBoxKeyWord0, "TABTITLE", GLOBAL.languageItems["keyword0"].toCString );
		IupSetAttribute( vBoxKeyWord0, "MARGIN", "0" );

		Ihandle* vBoxKeyWord1 = IupVbox( btnKeyWord1Color, keyWordText1, null );
		IupSetAttribute( vBoxKeyWord1, "TABTITLE", GLOBAL.languageItems["keyword1"].toCString );
		IupSetAttribute( vBoxKeyWord1, "MARGIN", "0" );

		Ihandle* vBoxKeyWord2 = IupVbox( btnKeyWord2Color, keyWordText2, null );
		IupSetAttribute( vBoxKeyWord2, "TABTITLE", GLOBAL.languageItems["keyword2"].toCString );
		IupSetAttribute( vBoxKeyWord2, "MARGIN", "0" );

		Ihandle* vBoxKeyWord3 = IupVbox( btnKeyWord3Color, keyWordText3, null );
		IupSetAttribute( vBoxKeyWord3, "TABTITLE", GLOBAL.languageItems["keyword3"].toCString );
		IupSetAttribute( vBoxKeyWord3, "MARGIN", "0" );

		Ihandle* vBoxKeyWord4 = IupVbox( btnKeyWord4Color, keyWordText4, null );
		IupSetAttribute( vBoxKeyWord4, "TABTITLE", GLOBAL.languageItems["keyword4"].toCString );
		IupSetAttribute( vBoxKeyWord4, "MARGIN", "0" );

		Ihandle* vBoxKeyWord5 = IupVbox( btnKeyWord5Color, keyWordText5, null );
		IupSetAttribute( vBoxKeyWord5, "TABTITLE", GLOBAL.languageItems["keyword5"].toCString );
		IupSetAttribute( vBoxKeyWord5, "MARGIN", "0" );

		version(Windows)
		{
			Ihandle* keywordTabs = IupFlatTabs( vBoxKeyWord0, vBoxKeyWord1, vBoxKeyWord2, vBoxKeyWord3, vBoxKeyWord4, vBoxKeyWord5, null );
			IupSetStrAttribute( keywordTabs, "BGCOLOR", toStringz( GLOBAL.editColor.dlgBack ) );
			IupSetAttribute( keywordTabs, "HIGHCOLOR", "255 0 0" );
			IupSetAttribute( keywordTabs, "TABSPADDING", "3x2" );
		}
		else
			Ihandle* keywordTabs = IupTabs( vBoxKeyWord0, vBoxKeyWord1, vBoxKeyWord2, vBoxKeyWord3, vBoxKeyWord4, vBoxKeyWord5, null );

		IupSetAttribute( keywordTabs, "NAME", "keyword-tabs" );

		IupSetAttribute( vBoxCompilerSettings, "TABTITLE", GLOBAL.languageItems["compiler"].toCString );
		IupSetAttribute( vBoxParserSettings, "TABTITLE", GLOBAL.languageItems["parser"].toCString );
		
		IupSetAttribute( vBoxPage02, "TABTITLE", GLOBAL.languageItems["editor"].toCString );
		IupSetAttribute( sb, "TABTITLE", GLOBAL.languageItems["font"].toCString );
		IupSetAttribute( vColor, "TABTITLE", GLOBAL.languageItems["color"].toCString );
		IupSetAttribute( shortCutList, "TABTITLE", GLOBAL.languageItems["shortcut"].toCString );
		IupSetAttribute( keywordTabs, "TABTITLE", GLOBAL.languageItems["keywords"].toCString );
	
		version(Windows)
		{
			Ihandle* preferenceTabs = IupFlatTabs( vBoxCompilerSettings, vBoxParserSettings, vBoxPage02, sb, vColor, shortCutList, keywordTabs, /*manuFrame,*/ null );
			IupSetStrAttribute( preferenceTabs, "BGCOLOR", toStringz( GLOBAL.editColor.dlgBack ) );
			IupSetAttribute( preferenceTabs, "HIGHCOLOR", "255 0 0" );
			IupSetCallback( preferenceTabs, "TABCHANGEPOS_CB", cast(Icallback) function( Ihandle* ih )
			{
				IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-colorTemplateList" ), "SHOWDROPDOWN", "NO" );
				return IUP_DEFAULT;
			});
		}
		else
			Ihandle* preferenceTabs = IupTabs( vBoxCompilerSettings, vBoxParserSettings, vBoxPage02, sb, vColor, shortCutList, keywordTabs, /*manuFrame,*/ null );
		
		IupSetAttribute( preferenceTabs, "NAME", "preference-tabs" );
		
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

		IupAppend( _dlg, vBox );		
	}
	

public:
	this( int w, int h, string title, bool bResize = true, string parent = "POSEIDON_MAIN_DIALOG" )
	{
		super( w, h, title, bResize, "POSEIDON_MAIN_TOOLBAR" );
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

		// Bottom Button
		IupSetStrAttribute( btnCANCEL, "TITLE", GLOBAL.languageItems["close"].toCString );
		IupSetCallback( btnAPPLY, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_btnApply_cb );
		IupSetCallback( btnOK, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_btnOK_cb );
		IupSetCallback( btnCANCEL, "FLAT_ACTION", cast(Icallback) &CPreferenceDialog_btnCancel_cb );
		IupSetAttribute( _dlg, "DEFAULTENTER", "Preference_btnHiddenOK" );
		IupSetAttribute( _dlg, "DEFAULTESC", "Preference_btnHiddenCANCEL" );
		IupSetCallback( _dlg, "CLOSE_CB", cast(Icallback) function( Ihandle* _ih )
		{
			return IUP_DEFAULT;//CONTINUE;
		});
		
		IupMap( _dlg );
	}

	void show()
	{
		version(Windows) tools.setDarkMode4Dialog( _dlg, GLOBAL.editorSetting00.UseDarkMode == "ON" ? true : false );
		IupShow( _dlg );
	}
	
	override string show( int x, int y )
	{
		// First time call this dialog to show
		version(Windows)
		{
			tools.setCaptionTheme( _dlg, GLOBAL.editorSetting00.UseDarkMode == "ON" ? true : false );
			tools.setDarkMode4Dialog( _dlg, GLOBAL.editorSetting00.UseDarkMode == "ON" ? true : false );
		}
		IupShowXY( _dlg, x, y );
		
		return "OK";
	}
	
	void changeIcon()
	{
		string tail;
		if( GLOBAL.editorSetting00.IconInvert == "ON" ) tail = "_invert";
		
		IupSetStrAttribute( btnOpen, "IMAGE", toStringz( "icon_openfile" ~ tail ) );
		IupSetStrAttribute( btnx64Open, "IMAGE", toStringz( "icon_openfile" ~ tail ) );
		version(FBIDE)
		{
			IupSetStrAttribute( btnOpenx64Debugger, "IMAGE", toStringz( "icon_openfile" ~ tail ) );
			IupSetStrAttribute( btnOpenDebugger, "IMAGE", toStringz( "icon_openfile" ~ tail ) );
		}
		version(Posix)
		{
			IupSetStrAttribute( btnOpenTerminal, "IMAGE", toStringz( "icon_openfile" ~ tail ) );
			IupSetStrAttribute( btnOpenHtmlApp, "IMAGE", toStringz( "icon_openfile" ~ tail ) );
		}
		
		IupSetStrAttribute( colorDefaultRefresh, "IMAGE", toStringz( "icon_refresh" ~ tail ) );
		IupSetStrAttribute( colorTemplateRemove, "IMAGE", toStringz( "icon_debug_clear" ~ tail ) );
		IupSetStrAttribute( colorTemplateSave, "IMAGE", toStringz( "icon_save" ~ tail ) );
	}
	
	void changeColor()
	{
		version(Windows)
		{

			IupSetStrAttribute( getIhandle, "FGCOLOR", toStringz( GLOBAL.editColor.dlgFore ) );
			IupSetStrAttribute( getIhandle, "BGCOLOR", toStringz( GLOBAL.editColor.dlgBack ) );
			
			//List
			IupSetStrAttribute( IupGetDialogChild( getIhandle, "Color-colorTemplateList" ), "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( IupGetDialogChild( getIhandle, "Color-colorTemplateList" ), "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );		
			IupSetStrAttribute( IupGetDialogChild( getIhandle, "keyword-tabs" ), "BGCOLOR", toStringz( GLOBAL.editColor.dlgBack ) );		
			IupSetStrAttribute( IupGetDialogChild( getIhandle, "preference-tabs" ), "BGCOLOR", toStringz( GLOBAL.editColor.dlgBack ) );		
		}

		IupSetStrAttribute( btnOK, "HLCOLOR", null );
		IupSetStrAttribute( btnAPPLY, "HLCOLOR", null );
		IupSetStrAttribute( btnCANCEL, "HLCOLOR", null );

		version(Windows)
		{
			IupSetStrAttribute( IupGetDialogChild( getIhandle, "Compiler-compilerPath" ), "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( IupGetDialogChild( getIhandle, "Compiler-compilerPath" ), "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
		
			version(FBIDE)
			{
				IupSetStrAttribute( IupGetDialogChild( getIhandle, "Compiler-x64compilerPath" ), "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
				IupSetStrAttribute( IupGetDialogChild( getIhandle, "Compiler-x64compilerPath" ), "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );

				IupSetStrAttribute( IupGetDialogChild( getIhandle, "Compiler-x64DebuggerPath" ), "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
				IupSetStrAttribute( IupGetDialogChild( getIhandle, "Compiler-x64DebuggerPath" ), "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
			}
			else
			{
				IupSetStrAttribute( IupGetDialogChild( getIhandle, "Compiler-x64compilerPath" ), "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
				IupSetStrAttribute( IupGetDialogChild( getIhandle, "Compiler-x64compilerPath" ), "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
			}
		}
		else
		{
			/*
			IupSetStrAttribute( IupGetDialogChild( getIhandle, "Compiler-textTerminalPath" ), "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( IupGetDialogChild( getIhandle, "Compiler-textTerminalPath" ), "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
			
			IupSetStrAttribute( IupGetDialogChild( getIhandle, "Compiler-htmlappPath" ), "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( IupGetDialogChild( getIhandle, "Compiler-htmlappPath" ), "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
			*/
		}
		
		version(FBIDE)
		{
			version(Windows)
			{
				IupSetStrAttribute( IupGetDialogChild( getIhandle, "Compiler-debuggerPath" ), "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
				IupSetStrAttribute( IupGetDialogChild( getIhandle, "Compiler-debuggerPath" ), "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
			}
		}
		
		
		version(Windows)
		{
			IupSetStrAttribute( IupGetHandle( "textMaxHeight" ), "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( IupGetHandle( "textMaxHeight" ), "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
			IupSetStrAttribute( IupGetHandle( "textTrigger" ), "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( IupGetHandle( "textTrigger" ), "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
			IupSetStrAttribute( IupGetHandle( "textIncludeLevel" ), "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( IupGetHandle( "textIncludeLevel" ), "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
			IupSetStrAttribute( IupGetHandle( "textSetControlCharSymbol" ), "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( IupGetHandle( "textSetControlCharSymbol" ), "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
			IupSetStrAttribute( IupGetHandle( "textTabWidth" ), "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( IupGetHandle( "textTabWidth" ), "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
			IupSetStrAttribute( IupGetHandle( "textColumnEdge" ), "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( IupGetHandle( "textColumnEdge" ), "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
			IupSetStrAttribute( IupGetHandle( "textBarSize" ), "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( IupGetHandle( "textBarSize" ), "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
			IupSetStrAttribute( IupGetHandle( "textAscent" ), "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( IupGetHandle( "textAscent" ), "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
			IupSetStrAttribute( IupGetHandle( "textDescent" ), "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( IupGetHandle( "textDescent" ), "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );

			IupSetStrAttribute( IupGetDialogChild( getIhandle, "Color-textSelAlpha" ), "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( IupGetDialogChild( getIhandle, "Color-textSelAlpha" ), "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
			IupSetStrAttribute( IupGetDialogChild( getIhandle, "Color-textIndicatorAlpha" ), "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( IupGetDialogChild( getIhandle, "Color-textIndicatorAlpha" ), "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
			IupSetStrAttribute( IupGetDialogChild( getIhandle, "Color-textMessageIndicatorAlpha" ), "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( IupGetDialogChild( getIhandle, "Color-textMessageIndicatorAlpha" ), "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );

			IupSetStrAttribute( IupGetDialogChild( getIhandle, "textMonitorID" ), "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( IupGetDialogChild( getIhandle, "textMonitorID" ), "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
			IupSetStrAttribute( IupGetDialogChild( getIhandle, "textConsoleX" ), "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( IupGetDialogChild( getIhandle, "textConsoleX" ), "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
			IupSetStrAttribute( IupGetDialogChild( getIhandle, "textConsoleY" ), "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( IupGetDialogChild( getIhandle, "textConsoleY" ), "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
			IupSetStrAttribute( IupGetDialogChild( getIhandle, "textConsoleW" ), "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( IupGetDialogChild( getIhandle, "textConsoleW" ), "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
			IupSetStrAttribute( IupGetDialogChild( getIhandle, "textConsoleH" ), "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( IupGetDialogChild( getIhandle, "textConsoleH" ), "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
		}

		IupSetStrAttribute( IupGetHandle( "keyWordText0" ), "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
		IupSetStrAttribute( IupGetHandle( "keyWordText0" ), "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
		IupSetStrAttribute( IupGetHandle( "keyWordText1" ), "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
		IupSetStrAttribute( IupGetHandle( "keyWordText1" ), "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
		IupSetStrAttribute( IupGetHandle( "keyWordText2" ), "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
		IupSetStrAttribute( IupGetHandle( "keyWordText2" ), "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
		IupSetStrAttribute( IupGetHandle( "keyWordText3" ), "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
		IupSetStrAttribute( IupGetHandle( "keyWordText3" ), "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
		IupSetStrAttribute( IupGetHandle( "keyWordText4" ), "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
		IupSetStrAttribute( IupGetHandle( "keyWordText4" ), "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
		IupSetStrAttribute( IupGetHandle( "keyWordText5" ), "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
		IupSetStrAttribute( IupGetHandle( "keyWordText5" ), "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
		
		IupSetStrAttribute( IupGetHandle( "shortCutList" ), "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
		IupSetStrAttribute( IupGetHandle( "shortCutList" ), "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );

		version(Windows)
		{		
			IupSetStrAttribute( IupGetDialogChild( getIhandle, "Color-textGeneralDlg" ), "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( IupGetDialogChild( getIhandle, "Color-textGeneralDlg" ), "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
			IupSetStrAttribute( IupGetDialogChild( getIhandle, "Color-textMessageDlg" ), "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( IupGetDialogChild( getIhandle, "Color-textMessageDlg" ), "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
			IupSetStrAttribute( IupGetDialogChild( getIhandle, "Color-textAutoCompleteDlg" ), "FGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
			IupSetStrAttribute( IupGetDialogChild( getIhandle, "Color-textAutoCompleteDlg" ), "BGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
		}
		
		IupUpdateChildren( getIhandle );
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

		string relatedPath = fSTRz( IupGetAttribute( _textElement, "VALUE" ) );
		scope fileSelectDlg = new CFileDlg( GLOBAL.languageItems["caption_open"].toDString ~ "...", GLOBAL.languageItems["exefile"].toDString() ~ "|*.exe", "OPEN", "NO", relatedPath );

		string fileName = fileSelectDlg.getFileName();
		if( fileName.length ) IupSetStrAttribute( _textElement, "VALUE", toStringz( fileName ) );
		
		return IUP_DEFAULT;	
	}
	

	private int CPreferenceDialog_shortCutList_DBLCLICK_CB( Ihandle *ih, int item, char *text )
	{
		string itemText = fSTRz( text );
		if( itemText.length )
		{
			if( itemText[0] == '[' ) return IUP_DEFAULT;
		}

		scope skDialog = new CShortCutDialog( -1, -1, item, fSTRz( text ) );
		int _x, _y;
		tools.splitBySign( fSTRz( IupGetGlobal( "CURSORPOS" ) ), "x", _x, _y );
		skDialog.show( IupGetInt( GLOBAL.preferenceDlg.getIhandle, "X" ), _y + 8 );

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
			version(Windows) string oldUseDarkMode = GLOBAL.editorSetting00.UseDarkMode;
			
			GLOBAL.parserSettings.KEYWORDS[0] = strip( fromStringz(IupGetAttribute( IupGetHandle( "keyWordText0" ), "VALUE" ))).dup;
			GLOBAL.parserSettings.KEYWORDS[1] = strip( fromStringz(IupGetAttribute( IupGetHandle( "keyWordText1" ), "VALUE" ))).dup;
			GLOBAL.parserSettings.KEYWORDS[2] = strip( fromStringz(IupGetAttribute( IupGetHandle( "keyWordText2" ), "VALUE" ))).dup;
			GLOBAL.parserSettings.KEYWORDS[3] = strip( fromStringz(IupGetAttribute( IupGetHandle( "keyWordText3" ), "VALUE" ))).dup;
			GLOBAL.parserSettings.KEYWORDS[4] = strip( fromStringz(IupGetAttribute( IupGetHandle( "keyWordText4" ), "VALUE" ))).dup;
			GLOBAL.parserSettings.KEYWORDS[5] = strip( fromStringz(IupGetAttribute( IupGetHandle( "keyWordText5" ), "VALUE" ))).dup;
			
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
			GLOBAL.editorSetting00.ColorBarLine				= fromStringz(IupGetAttribute( IupGetHandle( "toggleColorBarLine" ), "VALUE" )).dup;
			GLOBAL.editorSetting00.AutoKBLayout				= fromStringz(IupGetAttribute( IupGetHandle( "toggleAutoKBLayout" ), "VALUE" )).dup;
			version(FBIDE) GLOBAL.editorSetting00.QBCase					= fromStringz(IupGetAttribute( IupGetHandle( "toggleQBCase" ), "VALUE" )).dup;
			version(Windows) GLOBAL.editorSetting00.NewDocBOM				= fromStringz(IupGetAttribute( IupGetHandle( "toggleNewDocBOM" ), "VALUE" )).dup;
			GLOBAL.editorSetting00.SaveAllModified			= fromStringz(IupGetAttribute( IupGetHandle( "toggleSaveAllModified" ), "VALUE" )).dup;

			if( std.string.isNumeric( fSTRz( IupGetAttribute( IupGetHandle( "textSetControlCharSymbol" ), "VALUE" ) ) ) ) GLOBAL.editorSetting00.ControlCharSymbol	= fSTRz( IupGetAttribute( IupGetHandle( "textSetControlCharSymbol" ), "VALUE" ) );
			if( std.string.isNumeric( fSTRz( IupGetAttribute( IupGetHandle( "textTabWidth" ), "VALUE" ) ) ) ) GLOBAL.editorSetting00.TabWidth = fSTRz( IupGetAttribute( IupGetHandle( "textTabWidth" ), "VALUE" ) );
			if( std.string.isNumeric( fSTRz( IupGetAttribute( IupGetHandle( "textColumnEdge" ), "VALUE" ) ) ) ) GLOBAL.editorSetting00.ColumnEdge = fSTRz( IupGetAttribute( IupGetHandle( "textColumnEdge" ), "VALUE" ) );
			if( std.string.isNumeric( fSTRz( IupGetAttribute( IupGetHandle( "textAscent" ), "VALUE" ) ) ) ) GLOBAL.editorSetting01.EXTRAASCENT = fSTRz( IupGetAttribute( IupGetHandle( "textAscent" ), "VALUE" ) );
			if( std.string.isNumeric( fSTRz( IupGetAttribute( IupGetHandle( "textDescent" ), "VALUE" ) ) ) ) GLOBAL.editorSetting01.EXTRADESCENT = fSTRz( IupGetAttribute( IupGetHandle( "textDescent" ), "VALUE" ) );
			if( std.string.isNumeric( fSTRz( IupGetAttribute( IupGetHandle( "textBarSize" ), "VALUE" ) ) ) ) GLOBAL.editorSetting01.BarSize = fSTRz( IupGetAttribute( IupGetHandle( "textBarSize" ), "VALUE" ) );
			
			try
			{
				int _barSize = to!(int)( GLOBAL.editorSetting01.BarSize );
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
			}
			catch( Exception e )
			{
				GLOBAL.editorSetting01.BarSize = "2";
				IupSetStrAttribute( IupGetHandle( "textBarSize" ), "VALUE", "2" );
			}

			// Save Font Style
			GLOBAL.fonts.length = 12;
			for( int i = 1; i <= PreferenceDialogParameters.fontTable.getItemCount; ++ i )
			{
				string[] _values = PreferenceDialogParameters.fontTable.getSelection( i );
				if( _values.length == 4 )
				{
					_values[2] = strip( _values[2] ).dup;
					if( !_values[2].length ) _values[2] = " ";else  _values[2] = " " ~  _values[2] ~ " ";
					int fontID = i - 1;
					if( i >= 4 ) fontID ++;
					GLOBAL.fonts[fontID].fontString = _values[1] ~ "," ~ _values[2] ~ _values[3];
				}			
			}
			

			GLOBAL.editColor.caretLine = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnCaretLine" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.cursor = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnCursor" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.selectionFore = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSelectFore" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.selectionBack = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSelectBack" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.linenumFore = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnLinenumFore" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.linenumBack = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnLinenumBack" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.fold = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnFoldingColor" ), "FGCOLOR" ) ).dup;			
			
			if( std.string.isNumeric( fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-textSelAlpha" ), "VALUE" ) ) ) )
				GLOBAL.editColor.selAlpha = fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-textSelAlpha" ), "VALUE" ) );
			
			GLOBAL.editColor.currentWord = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnIndicator" ), "FGCOLOR" ) ).dup;
			
			if( std.string.isNumeric( fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-textIndicatorAlpha" ), "VALUE" ) ) ) )
				GLOBAL.editColor.currentWordAlpha = fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-textIndicatorAlpha" ), "VALUE" ) );

			GLOBAL.editColor.scintillaFore = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btn_Scintilla_FG" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.scintillaBack = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btn_Scintilla_BG" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.SCE_B_COMMENT_Fore = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_COMMENT_FG" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.SCE_B_COMMENT_Back = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_COMMENT_BG" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.SCE_B_NUMBER_Fore = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_NUMBER_FG" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.SCE_B_NUMBER_Back = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_NUMBER_BG" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.SCE_B_STRING_Fore = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_STRING_FG" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.SCE_B_STRING_Back = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_STRING_BG" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.SCE_B_PREPROCESSOR_Fore = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_PREPROCESSOR_FG" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.SCE_B_PREPROCESSOR_Back = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_PREPROCESSOR_BG" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.SCE_B_OPERATOR_Fore = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_OPERATOR_FG" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.SCE_B_OPERATOR_Back = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_OPERATOR_BG" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.SCE_B_IDENTIFIER_Fore = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_IDENTIFIER_FG" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.SCE_B_IDENTIFIER_Back = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_IDENTIFIER_BG" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.SCE_B_COMMENTBLOCK_Fore = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_COMMENTBLOCK_FG" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.SCE_B_COMMENTBLOCK_Back = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_COMMENTBLOCK_BG" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.prjTitle = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnPrjTitle" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.prjSourceType = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSourceTypeFolder" ), "FGCOLOR" ) ).dup;
			
			GLOBAL.editColor.projectFore = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnPrj_FG" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.projectBack = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnPrj_BG" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.outlineFore = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnOutline_FG" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.outlineBack = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnOutline_BG" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.dlgFore = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnDlg_FG" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.dlgBack = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnDlg_BG" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.txtFore = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnTxt_FG" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.txtBack = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnTxt_BG" ), "FGCOLOR" ) ).dup;
			
			GLOBAL.editColor.outputFore = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnOutput_FG" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.outputBack = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnOutput_BG" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.searchFore = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSearch_FG" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.searchBack = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSearch_BG" ), "FGCOLOR" ) ).dup;

			GLOBAL.editColor.errorFore = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnError_FG" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.errorBack = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnError_BG" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.warningFore = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnWarning_FG" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.warningBack = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnWarning_BG" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.braceFore = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnBrace_FG" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.braceBack = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnBrace_BG" ), "FGCOLOR" ) ).dup;

			GLOBAL.editColor.prjViewHLT = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnLeftViewHLT" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.searchIndicator = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnMessageIndicator" ), "FGCOLOR" ) ).dup;
			
			if( std.string.isNumeric( fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-textMessageIndicatorAlpha" ), "VALUE" ) ) ) )
				GLOBAL.editColor.searchIndicatorAlpha = fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-textMessageIndicatorAlpha" ), "VALUE" ) );
			
			GLOBAL.editColor.callTipFore = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnCallTip_FG" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.callTipBack = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnCallTip_BG" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.callTipHLT = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnCallTipHLT" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.showTypeFore = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnShowType_FG" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.showTypeBack = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnShowType_BG" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.showTypeHLT = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnShowTypeHLT" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.autoCompleteFore = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnAutoComplete_FG" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.autoCompleteBack = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnAutoComplete_BG" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.autoCompleteHLTFore = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnAutoCompleteHLT_FG" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.autoCompleteHLTBack = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnAutoCompleteHLT_BG" ), "FGCOLOR" ) ).dup;
			
			// OPACITY
			if( std.string.isNumeric( fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-textGeneralDlg" ), "VALUE" ) ) ) )
				GLOBAL.editorSetting02.generalDlg = fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-textGeneralDlg" ), "VALUE" ) );
			if( std.string.isNumeric( fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-textMessageDlg" ), "VALUE" ) ) ) )
				GLOBAL.editorSetting02.messageDlg = fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-textMessageDlg" ), "VALUE" ) );
			version(Windows)
			{
				if( std.string.isNumeric( fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-textAutoCompleteDlg" ), "VALUE" ) ) ) )
					GLOBAL.editorSetting02.autocompleteDlg = fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-textAutoCompleteDlg" ), "VALUE" ) );
			}
			if( GLOBAL.serachInFilesDlg !is null ) IupSetStrAttribute( GLOBAL.serachInFilesDlg.getIhandle, "OPACITY", toStringz( GLOBAL.editorSetting02.generalDlg ) );
			if( GLOBAL.preferenceDlg !is null ) IupSetStrAttribute( GLOBAL.preferenceDlg.getIhandle, "OPACITY", toStringz( GLOBAL.editorSetting02.generalDlg ) );

			
			if( GLOBAL.editorSetting00.ColorBarLine == "ON" )
			{
				IupSetAttributes( GLOBAL.documentSplit, "SHOWGRIP=NO" );
				IupSetAttributes( GLOBAL.documentSplit2, "SHOWGRIP=NO" );
				IupSetAttributes( GLOBAL.explorerSplit, "SHOWGRIP=NO" );
				IupSetAttributes( GLOBAL.messageSplit, "SHOWGRIP=NO" );
				IupSetStrAttribute( GLOBAL.documentSplit, "COLOR", toStringz( GLOBAL.editColor.fold ) );
				IupSetStrAttribute( GLOBAL.documentSplit2, "COLOR", toStringz( GLOBAL.editColor.fold ) );
				IupSetStrAttribute( GLOBAL.explorerSplit, "COLOR", toStringz( GLOBAL.editColor.fold ) );
				IupSetStrAttribute( GLOBAL.messageSplit, "COLOR", toStringz( GLOBAL.editColor.fold ) );
			}
			else
			{
				IupSetAttributes( GLOBAL.documentSplit, "SHOWGRIP=LINES" );
				IupSetAttributes( GLOBAL.documentSplit2, "SHOWGRIP=LINES" );
				IupSetAttributes( GLOBAL.explorerSplit, "SHOWGRIP=LINES" );
				IupSetAttributes( GLOBAL.messageSplit, "SHOWGRIP=LINES" );
			}		
			
			// Add for color
			version(Windows)
			{
				IupSetStrGlobal( "DLGFGCOLOR", toStringz( GLOBAL.editColor.dlgFore ) );
				IupSetStrGlobal( "DLGBGCOLOR", toStringz( GLOBAL.editColor.dlgBack ) );
				IupSetStrGlobal( "TXTFGCOLOR", toStringz( GLOBAL.editColor.txtFore ) );
				IupSetStrGlobal( "TXTBGCOLOR", toStringz( GLOBAL.editColor.txtBack ) );
				IupSetStrAttribute( GLOBAL.mainDlg, "FGCOLOR", toStringz( GLOBAL.editColor.dlgFore ) );
				IupSetStrAttribute( GLOBAL.mainDlg, "BGCOLOR", toStringz( GLOBAL.editColor.dlgBack ) );
			}

			IupSetStrAttribute( GLOBAL.documentTabs, "FGCOLOR", toStringz( GLOBAL.editColor.SCE_B_IDENTIFIER_Fore ) );
			IupSetStrAttribute( GLOBAL.documentTabs, "BGCOLOR", toStringz( GLOBAL.editColor.SCE_B_IDENTIFIER_Back ) );
			IupSetStrAttribute( GLOBAL.documentTabs, "TABSFORECOLOR", toStringz( GLOBAL.editColor.dlgFore ) );
			IupSetStrAttribute( GLOBAL.documentTabs, "TABSBACKCOLOR", toStringz( GLOBAL.editColor.dlgBack ) );			
			IupSetStrAttribute( GLOBAL.documentTabs, "TABSLINECOLOR", toStringz( GLOBAL.editColor.linenumBack ) );
			IupSetStrAttribute( GLOBAL.documentTabs_Sub, "FGCOLOR", toStringz( GLOBAL.editColor.SCE_B_IDENTIFIER_Fore ) );
			IupSetStrAttribute( GLOBAL.documentTabs_Sub, "BGCOLOR", toStringz( GLOBAL.editColor.SCE_B_IDENTIFIER_Back ) );
			IupSetStrAttribute( GLOBAL.documentTabs_Sub, "TABSFORECOLOR", toStringz( GLOBAL.editColor.dlgFore ) );
			IupSetStrAttribute( GLOBAL.documentTabs_Sub, "TABSBACKCOLOR", toStringz( GLOBAL.editColor.dlgBack ) );	
			IupSetStrAttribute( GLOBAL.documentTabs_Sub, "TABSLINECOLOR", toStringz( GLOBAL.editColor.linenumBack ) );
			
			IupSetStrAttribute( GLOBAL.explorerSplit, "COLOR", toStringz( GLOBAL.editColor.linenumBack ) );
			IupSetStrAttribute( GLOBAL.messageSplit, "COLOR", toStringz( GLOBAL.editColor.linenumBack ) );
			IupSetInt( GLOBAL.explorerSplit, "BARSIZE", to!(int)( GLOBAL.editorSetting01.BarSize ) );
			IupSetInt( GLOBAL.messageSplit, "BARSIZE", to!(int)( GLOBAL.editorSetting01.BarSize ) );
			/*
			IupSetInt( GLOBAL.documentSplit, "BARSIZE", Integer.atoi( GLOBAL.editorSetting01.BarSize ) );
			IupSetInt( GLOBAL.documentSplit2, "BARSIZE", Integer.atoi( GLOBAL.editorSetting01.BarSize ) );
			*/

			// Set the document empty tab back color
			IupSetStrAttribute( IupGetChild( GLOBAL.dndDocumentZBox, 0 ), "BGCOLOR" , toStringz(GLOBAL.editColor.dlgBack ) );
			IupRedraw( IupGetChild( IupGetChild( GLOBAL.dndDocumentZBox, 0 ), 0 ), 0 );

			GLOBAL.editColor.keyWord[0] = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord0Color" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.keyWord[1] = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord1Color" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.keyWord[2] = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord2Color" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.keyWord[3] = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord3Color" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.keyWord[4] = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord4Color" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.keyWord[5] = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord5Color" ), "FGCOLOR" ) ).dup;
			
			if( std.string.isNumeric( fSTRz( IupGetAttribute( IupGetHandle( "textTrigger" ), "VALUE" ) ) ) ) GLOBAL.parserSettings.autoCompletionTriggerWordCount = IupGetInt( IupGetHandle( "textTrigger" ), "VALUE" );
			if( std.string.isNumeric( fSTRz( IupGetAttribute( IupGetHandle( "textMaxHeight" ), "VALUE" ) ) ) ) GLOBAL.autoCMaxHeight = IupGetInt( IupGetHandle( "textMaxHeight" ), "VALUE" );
			GLOBAL.statusBar.setOriginalTrigger( GLOBAL.parserSettings.autoCompletionTriggerWordCount );
			version(FBIDE) if( std.string.isNumeric( fSTRz( IupGetAttribute( IupGetHandle( "textIncludeLevel" ), "VALUE" ) ) ) ) GLOBAL.compilerSettings.includeLevel = IupGetInt( IupGetHandle( "textIncludeLevel" ), "VALUE" );
			

			// Compiler & Debugger
			GLOBAL.compilerSettings.compilerFullPath = fSTRz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Compiler-compilerPath" ), "VALUE" ) );
			version(Windows)
			{
				version(FBIDE)
				{
					GLOBAL.compilerSettings.debuggerFullPath		= fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Compiler-debuggerPath" ), "VALUE" ) ).dup;
					GLOBAL.compilerSettings.x64compilerFullPath	= fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Compiler-x64compilerPath" ), "VALUE" ) ).dup;
					GLOBAL.compilerSettings.x64debuggerFullPath	= fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Compiler-x64DebuggerPath" ), "VALUE" ) ).dup;
				}
				else
				{
					GLOBAL.compilerSettings.x64compilerFullPath	= fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Compiler-x64compilerPath" ), "VALUE" ) ).dup;
				}
			}
			else
			{
				GLOBAL.compilerSettings.x64compilerFullPath	= GLOBAL.compilerSettings.compilerFullPath;
				GLOBAL.compilerSettings.debuggerFullPath		= fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Compiler-debuggerPath" ), "VALUE" ) ).dup;
				GLOBAL.compilerSettings.x64debuggerFullPath	= GLOBAL.compilerSettings.debuggerFullPath;
				
				GLOBAL.linuxTermName		= fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Compiler-textTerminalPath" ), "VALUE" ) ).dup;
				GLOBAL.linuxHtmlAppName		= fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Compiler-htmlappPath" ), "VALUE" ) ).dup;
			}
			
			GLOBAL.compilerSettings.useAnootation					= fromStringz( IupGetAttribute( IupGetHandle( "toggleAnnotation" ), "VALUE" ) ).dup;
				if( IupGetHandle( "menuUseAnnotation" ) != null ) IupSetStrAttribute( IupGetHandle( "menuUseAnnotation" ), "VALUE", IupGetAttribute( IupGetHandle( "toggleAnnotation" ), "VALUE" ) );
			GLOBAL.compilerSettings.useResultDlg					= fromStringz( IupGetAttribute( IupGetHandle( "toggleShowResultWindow" ), "VALUE" ) ).dup;
			GLOBAL.compilerSettings.useSFX							= fromStringz( IupGetAttribute( IupGetHandle( "toggleSFX" ), "VALUE" ) ).dup;
			
			GLOBAL.compilerSettings.useDelExistExe					= fromStringz( IupGetAttribute( IupGetHandle( "toggleDelPrevEXE" ), "VALUE" ) ).dup;
			GLOBAL.compilerSettings.useConsoleLaunch				= fromStringz( IupGetAttribute( IupGetHandle( "toggleConsoleExe" ), "VALUE" ) ).dup;
				if( IupGetHandle( "menuUseConsoleApp" ) != null ) IupSetStrAttribute( IupGetHandle( "menuUseConsoleApp" ), "VALUE", IupGetAttribute( IupGetHandle( "toggleConsoleExe" ), "VALUE" ) );
			GLOBAL.compilerSettings.useThread						= fromStringz( IupGetAttribute( IupGetHandle( "toggleCompileAtBackThread" ), "VALUE" ) ).dup;
			
			
			try
			{
				Ihandle* _mHandle = IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textMonitorID" );
				if( _mHandle != null )
				{
					if( std.string.isNumeric( fSTRz( IupGetAttribute( _mHandle, "VALUE" ) ) ) )
					{
						GLOBAL.consoleWindow.id = IupGetInt( _mHandle, "VALUE" ) - 1;
						if( GLOBAL.consoleWindow.id < 0 || GLOBAL.consoleWindow.id >= GLOBAL.monitors.length )
						{
							GLOBAL.consoleWindow.id = 0;
							IupSetAttribute( _mHandle, "VALUE", "1" );
						}
					}
				}
				_mHandle = IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textConsoleX" );
				if( _mHandle != null )
				{
					if( std.string.isNumeric( fSTRz( IupGetAttribute( _mHandle, "VALUE" ) ) ) )	GLOBAL.consoleWindow.x = IupGetInt( _mHandle, "VALUE" );
				}
				_mHandle = IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textConsoleY" );
				if( _mHandle != null )
				{
					if( std.string.isNumeric( fSTRz( IupGetAttribute( _mHandle, "VALUE" ) ) ) ) GLOBAL.consoleWindow.y = IupGetInt( _mHandle, "VALUE" );
				}
				_mHandle = IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textConsoleW" );
				if( _mHandle != null )
				{
					if( std.string.isNumeric( fSTRz( IupGetAttribute( _mHandle, "VALUE" ) ) ) ) GLOBAL.consoleWindow.w = IupGetInt( _mHandle, "VALUE" );
				}
				_mHandle = IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textConsoleH" );
				if( _mHandle != null )
				{
					if( std.string.isNumeric( fSTRz( IupGetAttribute( _mHandle, "VALUE" ) ) ) ) GLOBAL.consoleWindow.h = IupGetInt( _mHandle, "VALUE" );
				}
			}
			catch( Exception e )
			{
				GLOBAL.consoleWindow.id = 0;
				GLOBAL.consoleWindow.x = GLOBAL.consoleWindow.y = GLOBAL.consoleWindow.w = GLOBAL.consoleWindow.h = 0;
				Ihandle* _mHandle = IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "textMonitorID" );
				if( _mHandle != null ) IupSetAttribute( _mHandle, "VALUE", "1" );
			}
			
			GLOBAL.compilerSettings.enableKeywordComplete				= fromStringz( IupGetAttribute( IupGetHandle( "toggleKeywordComplete" ), "VALUE" ) ).dup;
			GLOBAL.compilerSettings.enableIncludeComplete				= fromStringz( IupGetAttribute( IupGetHandle( "toggleIncludeComplete" ), "VALUE" ) ).dup;

			GLOBAL.parserSettings.enableParser							= fromStringz( IupGetAttribute( IupGetHandle( "toggleUseParser" ), "VALUE" ) ).dup;
			GLOBAL.parserSettings.togglePreLoadPrj						= fromStringz( IupGetAttribute( IupGetHandle( "togglePreLoadPrj" ), "VALUE" ) ).dup;
			GLOBAL.parserSettings.showFunctionTitle						= fromStringz( IupGetAttribute( IupGetHandle( "toggleFunctionTitle" ), "VALUE" ) ).dup;
				if( IupGetHandle( "menuFunctionTitle" ) != null ) IupSetStrAttribute( IupGetHandle( "menuFunctionTitle" ), "VALUE", IupGetAttribute( IupGetHandle( "toggleFunctionTitle" ), "VALUE" ) );
			
			GLOBAL.parserSettings.toggleExtendMacro						= fromStringz( IupGetAttribute( IupGetHandle( "toggleExtMacro" ), "VALUE" ) ).dup;
			
			GLOBAL.parserSettings.showTypeWithParams					= fromStringz( IupGetAttribute( IupGetHandle( "toggleWithParams" ), "VALUE" ) ).dup;
			GLOBAL.parserSettings.toggleIgnoreCase						= fromStringz( IupGetAttribute( IupGetHandle( "toggleIGNORECASE" ), "VALUE" ) ).dup;
			GLOBAL.parserSettings.toggleCaseInsensitive					= fromStringz( IupGetAttribute( IupGetHandle( "toggleCASEINSENSITIVE" ), "VALUE" ) ).dup;
			GLOBAL.compilerSettings.toggleShowAllMember					= fromStringz( IupGetAttribute( IupGetHandle( "toggleSHOWALLMEMBER" ), "VALUE" ) ).dup;
			GLOBAL.parserSettings.toggleEnableDwell						= fromStringz( IupGetAttribute( IupGetHandle( "toggleDWELL" ), "VALUE" ) ).dup;
			GLOBAL.parserSettings.toggleOverWrite						= fromStringz( IupGetAttribute( IupGetHandle( "toggleOverWrite" ), "VALUE" ) ).dup;
			GLOBAL.parserSettings.toggleCompleteAtBackThread			= fromStringz( IupGetAttribute( IupGetHandle( "toggleBackThread" ), "VALUE" ) ).dup;
			
			if( fromStringz( IupGetAttribute( IupGetHandle( "toggleLiveNone" ), "VALUE" ) ) == "ON" )
				GLOBAL.parserSettings.liveLevel = 0;
			else if( fromStringz( IupGetAttribute( IupGetHandle( "toggleLiveLight" ), "VALUE" ) ) == "ON" )
				GLOBAL.parserSettings.liveLevel = 1;
			else if( fromStringz( IupGetAttribute( IupGetHandle( "toggleLiveFull" ), "VALUE" ) ) == "ON" )
				GLOBAL.parserSettings.liveLevel = 2;
			else
				GLOBAL.parserSettings.liveLevel = 0;

			GLOBAL.parserSettings.toggleUpdateOutlineLive	= fromStringz( IupGetAttribute( IupGetHandle( "toggleUpdateOutline" ), "VALUE" ) ).dup;

			version(FBIDE)
			{
				if( fromStringz( IupGetAttribute( IupGetHandle( "toggleConditionNone" ), "VALUE" ) ) == "ON" )
					GLOBAL.parserSettings.conditionalCompilation = 0;
				else if( fromStringz( IupGetAttribute( IupGetHandle( "toggleConditionFull" ), "VALUE" ) ) == "ON" )
					GLOBAL.parserSettings.conditionalCompilation = 2;
				else 
					GLOBAL.parserSettings.conditionalCompilation = 1;
					
				// Icon Invert
				if( fromStringz( IupGetAttribute( IupGetHandle( "radioKeywordCase0" ), "VALUE" ) ) == "ON" )
					GLOBAL.keywordCase= 0;
				else if( fromStringz( IupGetAttribute( IupGetHandle( "radioKeywordCase1" ), "VALUE" ) ) == "ON" )
					GLOBAL.keywordCase= 1;
				else if( fromStringz( IupGetAttribute( IupGetHandle( "radioKeywordCase2" ), "VALUE" ) ) == "ON" )
					GLOBAL.keywordCase= 2;
				else if( fromStringz( IupGetAttribute( IupGetHandle( "radioKeywordCase3" ), "VALUE" ) ) == "ON" )
					GLOBAL.keywordCase= 3;
				else
					GLOBAL.keywordCase= 4;
			}
			
			// Prot Color
			GLOBAL.editColor.protectedColor = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnProtected" ), "FGCOLOR" ) ).dup;
			GLOBAL.editColor.privateColor = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnPrivate" ), "FGCOLOR" ) ).dup;


			// Icon Invert
			if( fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-toggleIcon" ), "VALUE" ) ) == "ON" )
				GLOBAL.editorSetting00.IconInvert = "OFF";
			else if( fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-toggleIconInvert" ), "VALUE" ) ) == "ON" )
				GLOBAL.editorSetting00.IconInvert = "ON";
			else if( fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-toggleIconInvertAll" ), "VALUE" ) ) == "ON" )
				GLOBAL.editorSetting00.IconInvert = "ALL";
			else
				GLOBAL.editorSetting00.IconInvert = "OFF";
			
			// Use DarkMode
			GLOBAL.editorSetting00.UseDarkMode = fromStringz( IupGetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-toggleDarkMode" ), "VALUE" ) ).dup;
				

			if( GLOBAL.parserSettings.showFunctionTitle == "ON" )
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
				GLOBAL.parserSettings.dwellDelay = to!(string)( value );
			}
			
			_valHandle = IupGetHandle( "valTriggerDelay" );
			if( _valHandle != null )
			{
				int v = IupGetInt( _valHandle, "VALUE" );
				if( v < 50 ) v = 50;
				GLOBAL.parserSettings.triggerDelay = to!(string)( v );
				AutoComplete.setTimer( v );
			}
			
			_valHandle = IupGetHandle( "textPreParseLevel" );
			if( _valHandle != null )
			{
				if( std.string.isNumeric( fSTRz( IupGetAttribute( _valHandle, "VALUE" ) ) ) ) GLOBAL.parserSettings.preParseLevel = IupGetInt( _valHandle, "VALUE" );
			}
			
			//
			//
			// Change Theme
			version(Windows)
			{
				if( oldUseDarkMode != GLOBAL.editorSetting00.UseDarkMode ) // If darkmode setting has be changed, do it...
				{
					tools.setMenuTheme( GLOBAL.editorSetting00.UseDarkMode == "ON" ? true : false );
					tools.setCaptionTheme( GLOBAL.preferenceDlg.getIhandle, GLOBAL.editorSetting00.UseDarkMode == "ON" ? true : false );
					tools.setCaptionTheme( GLOBAL.mainDlg, GLOBAL.editorSetting00.UseDarkMode == "ON" ? true : false );
				}
			}			
			//
			//
			//		
			
			// Message
			GLOBAL.messagePanel.setScintillaColor();

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
			version(Windows) GLOBAL.menubar.setFont( GLOBAL.fonts[0].fontString );
			version(DIDE)
			{
				version(Posix) GLOBAL.debugPanel.setFont();
			}
			else
			{
				GLOBAL.debugPanel.setFont();
			}
			
			version(FBIDE) GLOBAL.toggleUseManual						= fromStringz(IupGetAttribute( IupGetHandle( "toggleUseManual" ), "VALUE" )).dup;


			// Update and change THEME color
			GLOBAL.projectTree.changeColor();
			GLOBAL.outlineTree.changeColor();
			
			if( GLOBAL.toolbar !is null ) GLOBAL.toolbar.changeColor();
			if( GLOBAL.statusBar !is null ) GLOBAL.statusBar.changeColor();
			if( GLOBAL.debugPanel !is null ) GLOBAL.debugPanel.changeColor();
			if( GLOBAL.searchExpander !is null ) GLOBAL.searchExpander.changeColor();
			if( GLOBAL.menubar !is null )  GLOBAL.menubar.changeColor( GLOBAL.editColor.dlgFore, GLOBAL.editColor.dlgBack );
			
			GLOBAL.messagePanel.applyColor(); // Set GLOBAL.messagePanel Color
			IupSetStrAttribute( GLOBAL.projectViewTabs, "TABSFORECOLOR", toStringz( GLOBAL.editColor.outlineFore ) );
			IupSetStrAttribute( GLOBAL.projectViewTabs, "TABSBACKCOLOR", toStringz( GLOBAL.editColor.outlineBack ) );
			IupSetStrAttribute( GLOBAL.projectViewTabs, "TABSLINECOLOR", toStringz( GLOBAL.editColor.linenumBack ) );
			
			if( GLOBAL.serachInFilesDlg !is null ) GLOBAL.serachInFilesDlg.changeColor();
			if( GLOBAL.preferenceDlg !is null )
			{
				GLOBAL.preferenceDlg.changeColor();
				GLOBAL.preferenceDlg.changeIcon();
			}

			// Save Setup to Xml
			//IDECONFIG.save();
			IDECONFIG.saveINI();

			IupRefreshChildren( IupGetHandle( "PreferenceHandle" ) );
			
			// refresh GLOBAL.preferenceDlg CaptionTheme
			version(Windows)
			{
				if( oldUseDarkMode != GLOBAL.editorSetting00.UseDarkMode ) // If darkmode setting has be changed, do it...
				{
					if( ih == IupGetHandle( "CPreferenceDialogbtnAPPLY" ) )
					{
						tools.setDarkMode4Dialog( GLOBAL.preferenceDlg.getIhandle, GLOBAL.editorSetting00.UseDarkMode == "ON" ? true : false );
						IupSetFocus( GLOBAL.mainDlg );
					}
				}
			}			
		}
		catch( Exception e )
		{
			IupMessage( "CPreferenceDialog_btnOK_cb", toStringz( "CPreferenceDialog_btnOK_cb Error\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ to!(string)( e.line ) ) );
		}
		
		return IUP_DEFAULT;
	}

	private int CPreferenceDialog_colorChoose_cb( Ihandle* ih )
	{
		Ihandle* dlg = IupColorDlg();

		IupSetStrAttribute( dlg, "VALUE", IupGetAttribute( ih, "FGCOLOR" ) ); // For IupFlatButton
		IupSetAttribute(dlg, "SHOWHEX", "YES");
		IupSetAttribute(dlg, "SHOWCOLORTABLE", "YES");
		IupSetAttribute(dlg, "TITLE", GLOBAL.languageItems["color"].toCString() );
		
		version(Windows)
		{
			if( GLOBAL.bCanUseDarkMode )
			{
				IupMap( dlg );
				tools.setCaptionTheme( dlg, GLOBAL.editorSetting00.UseDarkMode == "ON" ? true : false );
				if( GLOBAL.editorSetting00.UseDarkMode == "ON" )
				{
					Ihandle* _c = IupGetChild( dlg, 0 ); 
					_c = IupGetChild( _c, 2 ); // hBox, label, hbox
					auto child = IupGetNextChild( _c, null );
					while( child )
					{
						if( fSTRz( IupGetClassName(child) ) == "button" ) tools.setWinTheme( child, "Explorer", true );
						child = IupGetNextChild(null, child);
					}
				}
			}
		}
		IupPopup( dlg, IUP_CURRENT, IUP_CURRENT );

		if( IupGetInt( dlg, "STATUS" ) )
		{
			IupSetStrAttribute( ih, "FGCOLOR", IupGetAttribute( dlg, "VALUE" ) ); // For IupFlatButton
			IupUpdateChildren( GLOBAL.preferenceDlg.getIhandle );
		}
		
		return IUP_DEFAULT;
	}

	private int CPreferenceDialog_FGcolorChooseScintilla_cb( Ihandle* ih )
	{
		Ihandle* dlg = IupColorDlg();

		IupSetStrAttribute( dlg, "VALUE", IupGetAttribute( ih, "FGCOLOR" ) );
		IupSetAttribute( dlg, "SHOWHEX", "YES" );
		IupSetAttribute( dlg, "SHOWCOLORTABLE", "YES" );
		IupSetAttribute( dlg, "TITLE", GLOBAL.languageItems["color"].toCString() );

		IupPopup( dlg, IUP_CURRENT, IUP_CURRENT );

		if( IupGetInt( dlg, "STATUS" ) )
		{
			auto _color = IupGetAttribute( dlg, "VALUE" );
			
			IupSetStrAttribute( ih, "FGCOLOR", _color ); IupSetFocus( ih );
			
			int button = tools.MessageDlg( GLOBAL.languageItems["quest"].toDString(), GLOBAL.languageItems["applycolor"].toDString, "QUESTION", "YESNO", IUP_CENTER, IUP_CENTER );
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

		IupSetStrAttribute( dlg, "VALUE", IupGetAttribute( ih, "FGCOLOR" ) );
		IupSetAttribute(dlg, "SHOWHEX", "YES");
		IupSetAttribute(dlg, "SHOWCOLORTABLE", "YES");
		IupSetAttribute(dlg, "TITLE", GLOBAL.languageItems["color"].toCString() );

		IupPopup( dlg, IUP_CURRENT, IUP_CURRENT );

		if( IupGetInt( dlg, "STATUS" ) )
		{
			auto _color = IupGetAttribute( dlg, "VALUE" );
			
			IupSetStrAttribute( ih, "FGCOLOR", _color ); IupSetFocus( ih );
			
			int button = tools.MessageDlg( GLOBAL.languageItems["quest"].toDString(), GLOBAL.languageItems["applycolor"].toDString, "QUESTION", "YESNO", IUP_CENTER, IUP_CENTER );
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
			string templateFP = GLOBAL.linuxHome.length ? ( GLOBAL.linuxHome ~ "/settings/colorTemplates" ) : "settings/colorTemplates";
			if( std.file.exists( templateFP ) )
			{
				IupSetAttribute( ih, "REMOVEITEM", "ALL" );
				version(Posix) IupSetAttributeId( ih, "", 1, toStringz( " " ) );
				foreach( string filename; dirEntries( GLOBAL.poseidonPath ~ "/settings/colorTemplates", "*.ini", SpanMode.shallow ) )
					IupSetStrAttribute( ih, "APPENDITEM", toStringz( Path.stripExtension( Path.baseName( filename ) ) ) );
			}
		}
		
		return IUP_DEFAULT;
	}
	
	private int colorTemplateList_ACTION_CB( Ihandle *ih, char *text, int item, int state )
	{
		if( state == 1 )
		{
			string		templateName = fSTRz( text );
			if( strip( templateName ).length ) IDECONFIG.loadColorTemplateINI( templateName );
		}

		return IUP_DEFAULT;
	}
	
	private int colorTemplateList_reset_ACTION( Ihandle *ih )
	{
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnCaretLine" ), "FGCOLOR", "255 255 128" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnCursor" ), "FGCOLOR", "0 0 0" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnFoldingColor" ), "FGCOLOR", "241 243 243" );
		version(Windows)
			IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-textSelAlpha" ), "SPINVALUE", "64" );
		else
			IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-textSelAlpha" ), "VALUE", "64" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnPrjTitle" ), "FGCOLOR", "128 0 0" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSourceTypeFolder" ), "FGCOLOR", "0 0 255" );
		

		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnDlg_FG" ), "FGCOLOR", "0 0 0" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnDlg_BG" ), "FGCOLOR", "240 240 240" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnTxt_FG" ), "FGCOLOR", "0 0 0" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnTxt_BG" ), "FGCOLOR", "255 255 255" );
		IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-colorTemplateList" ), "FGCOLOR", "0 0 0" );
		IupSetStrAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-colorTemplateList" ), "BGCOLOR", "255 255 255" );		
		
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnPrj_FG" ), "FGCOLOR", "0 0 0" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnPrj_BG" ), "FGCOLOR", "255 255 255" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnOutline_FG" ), "FGCOLOR", "0 0 0" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnOutline_BG" ), "FGCOLOR", "255 255 255" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnOutput_FG" ), "FGCOLOR", "0 0 0" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnOutput_BG" ), "FGCOLOR", "255 255 255" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSearch_FG" ), "FGCOLOR", "0 0 0" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSearch_BG" ), "FGCOLOR", "255 255 255" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSelectFore" ), "FGCOLOR", "255 255 255" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSelectBack" ), "FGCOLOR", "0 0 255" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnLinenumFore" ), "FGCOLOR", "0 0 0" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnLinenumBack" ), "FGCOLOR", "200 200 200" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnIndicator" ), "FGCOLOR", "0 128 0" );
		version(Windows)
			IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-textIndicatorAlpha" ), "SPINVALUE", "80" );
		else
			IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-textIndicatorAlpha" ), "VALUE", "80" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnMessageIndicator" ), "FGCOLOR", "0 0 255" );
		version(Windows)
			IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-textMessageIndicatorAlpha" ), "SPINVALUE", "128" );
		else
			IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-textMessageIndicatorAlpha" ), "VALUE", "128" );		
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnBrace_FG" ), "FGCOLOR", "255 0 0" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnBrace_BG" ), "FGCOLOR", "0 255 0" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnError_FG" ), "FGCOLOR", "102 69 3" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnError_BG" ), "FGCOLOR", "255 200 227" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnWarning_FG" ), "FGCOLOR", "0 0 255" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnWarning_BG" ), "FGCOLOR", "255 255 157" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnLeftViewHLT" ), "FGCOLOR", "0 0 255" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnShowType_FG" ), "FGCOLOR", "0 0 255" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnShowType_BG" ), "FGCOLOR", "255 255 170" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnShowTypeHLT" ), "FGCOLOR", "0 128 0" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnCallTip_FG" ), "FGCOLOR", "0 0 255" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnCallTip_BG" ), "FGCOLOR", "234 248 192" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnCallTipHLT" ), "FGCOLOR", "200 0 0" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnAutoComplete_FG" ), "FGCOLOR", "0 0 0" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnAutoComplete_BG" ), "FGCOLOR", "240 240 240" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnAutoCompleteHLT_FG" ), "FGCOLOR", "255 255 255" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnAutoCompleteHLT_BG" ), "FGCOLOR", "0 0 200" );

		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btn_Scintilla_FG" ), "FGCOLOR", "0 0 0" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btn_Scintilla_BG" ), "FGCOLOR", "255 255 255" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_COMMENT_FG" ), "FGCOLOR", "0 128 0" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_COMMENT_BG" ), "FGCOLOR", "255 255 255" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_NUMBER_FG" ), "FGCOLOR", "128 128 64" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_NUMBER_BG" ), "FGCOLOR", "255 255 255" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_STRING_FG" ), "FGCOLOR", "128 0 0" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_STRING_BG" ), "FGCOLOR", "255 255 255" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_PREPROCESSOR_FG" ), "FGCOLOR", "0 0 255" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_PREPROCESSOR_BG" ), "FGCOLOR", "255 255 255" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_OPERATOR_FG" ), "FGCOLOR", "160 20 20" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_OPERATOR_BG" ), "FGCOLOR", "255 255 255" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_IDENTIFIER_FG" ), "FGCOLOR", "0 0 0" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_IDENTIFIER_BG" ), "FGCOLOR", "255 255 255" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_COMMENTBLOCK_FG" ), "FGCOLOR", "0 128 0" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnSCE_B_COMMENTBLOCK_BG" ), "FGCOLOR", "255 255 255" );
		
		// Keyword Default
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord0Color" ), "FGCOLOR", "5 91 35" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord1Color" ), "FGCOLOR", "0 0 255" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord2Color" ), "FGCOLOR", "231 144 0" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord3Color" ), "FGCOLOR", "16 108 232" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord4Color" ), "FGCOLOR", "255 0 0" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnKeyWord5Color" ), "FGCOLOR", "0 255 0" );

		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnProtected" ), "FGCOLOR", "255 95 17" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-btnPrivate" ), "FGCOLOR", "255 0 0" );

		// bottom
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-toggleIcon" ), "VALUE", "ON" );
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-toggleDarkMode" ), "VALUE", "OFF" );
		
		IupSetAttribute( IupGetDialogChild( GLOBAL.preferenceDlg.getIhandle, "Color-colorTemplateList" ), "VALUE", "" );

		IupUpdateChildren( GLOBAL.preferenceDlg.getIhandle );
		return IUP_DEFAULT;
	}

	
	private int memberDoubleClick( Ihandle* ih, int item, char* text )
	{
		try
		{
			string[] listString = PreferenceDialogParameters.fontTable.getSelection( item );
			
			if( listString.length == 4 )
			{
				string _font = listString[1] ~ "," ~ listString[2] ~ listString[3];
				Ihandle* dlg = IupFontDlg();
				if( dlg == null )
				{
					IupMessage( "Error", "IupFontDlg created fail!" );
					return IUP_IGNORE;
				}

				IupSetStrAttribute( dlg, "VALUE", toStringz( _font ) );
				IupPopup( dlg, IUP_CURRENT, IUP_CURRENT );			
				
				if( IupGetInt( dlg, "STATUS" ) == 1 )
				{
					string fontInformation = fromStringz( IupGetAttribute( dlg, "VALUE" ) ).dup;
					string size, style;
					string[] strings = Array.split( fontInformation, "," );
					
					if( strings.length == 2 )
					{
						if( !strings[0].length )
						{
							version( Windows ) strings[0] = "Courier New"; else	strings[0] = "Monospace";
						}
						else
						{
							strings[0] = strip( strings[0] ).dup;
						}
						
						auto spacePos = lastIndexOf( strings[1], " " );
						if( spacePos > -1 )
						{
							size = strings[1][spacePos+1..$].dup;
							style = strip( strings[1][0..spacePos] ).dup;
							if( !style.length ) style = " "; else style = " " ~ style ~ " ";
						}
						
						PreferenceDialogParameters.fontTable.setItem( [ listString[0], strings[0], style, size ], item );
					}
					else
					{
						version(Posix)
						{
							auto spaceTailPos = lastIndexOf( fontInformation, " " );
							if( spaceTailPos > 0 )
							{
								size = fontInformation[spaceTailPos+1..$].dup;
								string fontName;
								foreach( s; Array.split( fontInformation[0..spaceTailPos].dup, " " ) )
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
								
								fontName = strip( fontName );
								style = strip( style );
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
		IupSetStrAttribute( ih, "TIP", toStringz( to!(string)( value ) ) );
		
		return IUP_DEFAULT;
	}

	private int valTriggerDelay_VALUECHANGED_CB( Ihandle *ih )
	{
		int value = IupGetInt( ih, "VALUE" );
		//IupSetInt( ih, "VALUE", value );
		IupSetStrAttribute( ih, "TIP", toStringz( to!(string)( value ) ) );
		
		return IUP_DEFAULT;
	}
}