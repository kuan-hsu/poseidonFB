module global;

private import project;

struct EditorToggleUint
{
	string	LineMargin = "ON", FixedLineMargin = "ON", BookmarkMargin = "ON", FoldMargin = "ON", IndentGuide = "ON", CaretLine = "ON", WordWrap = "OFF", TabUseingSpace = "OFF", AutoIndent = "ON", ShowEOL = "OFF", ShowSpace = "OFF", AutoEnd = "OFF", AutoClose = "OFF", DocStatus = "OFF", ColorBarLine = "OFF", AutoKBLayout = "OFF";
	string	TabWidth = "4", ColumnEdge = "0", EolType = "0", ControlCharSymbol = "32", ColorOutline = "OFF", BoldKeyword = "OFF", BraceMatchHighlight = "ON", MultiSelection = "OFF", LoadPrevDoc = "OFF", HighlightCurrentWord = "OFF", MiddleScroll = "OFF", GUI = "OFF", QBCase = "OFF", NewDocBOM = "ON", SaveAllModified = "OFF";
	string	IconInvert = "OFF", UseDarkMode = "OFF";
}

struct EditorLayoutSize
{
	string USEFULLSCREEN = "OFF", PLACEMENT = "MAXIMIZED", RASTERSIZE = "700x500", ExplorerSplit = "170", MessageSplit = "800", OutlineWindow = "ON", MessageWindow = "ON", OutlineFlat = "OFF", RotateTabs = "OFF", BarSize = "2";
	version(linux) 
		string OutputSci = "ON";
	else
		string OutputSci = "OFF";
		
	string EXTRAASCENT = "0", EXTRADESCENT = "0";
}

struct EditorColorUint
{
	string[6]	keyWord;
	string		caretLine, cursor, selectionFore, selectionBack, linenumFore, linenumBack, fold, bookmark, selAlpha, errorFore, errorBack, warningFore, warningBack, currentWord, currentWordAlpha;
	string		scintillaFore, scintillaBack, braceFore, braceBack, SCE_B_COMMENT_Fore, SCE_B_COMMENT_Back, SCE_B_NUMBER_Fore, SCE_B_NUMBER_Back, SCE_B_STRING_Fore, SCE_B_STRING_Back;
	string		SCE_B_PREPROCESSOR_Fore, SCE_B_PREPROCESSOR_Back, SCE_B_OPERATOR_Fore, SCE_B_OPERATOR_Back;
	string		SCE_B_IDENTIFIER_Fore, SCE_B_IDENTIFIER_Back, SCE_B_COMMENTBLOCK_Fore, SCE_B_COMMENTBLOCK_Back;
	string		projectFore, projectBack, outlineFore, outlineBack, outputFore, outputBack, searchFore, searchBack, prjTitle, prjSourceType, dlgFore, dlgBack, txtFore, txtBack;
	string		callTipFore, callTipBack, callTipHLT, showTypeFore, showTypeBack, showTypeHLT, autoCompleteFore, autoCompleteBack, autoCompleteHLTFore, autoCompleteHLTBack;
	string		searchIndicator, searchIndicatorAlpha, prjViewHLT, prjViewHLTAlpha;
}

struct CompilerSettingUint
{
	string		compilerFullPath, x64compilerFullPath;
	string		debuggerFullPath, x64debuggerFullPath;
	string		useAnootation = "ON";
	string		useResultDlg = "OFF";
	string		useSFX = "ON";
	string		useDelExistExe = "ON";
	string		useConsoleLaunch = "OFF";
	string		useThread = "OFF";
	string		Bit64 = "OFF";
	string		currentCustomCompilerOption, noneCustomCompilerOption;
	string		enableKeywordComplete = "ON";
	string		enableIncludeComplete = "ON";
	string		toggleShowAllMember = "ON";
	string[]	customCompilerOptions;
	int			includeLevel = 3;
	FocusUnit	activeCompiler;
	
}

struct ShortKey
{
	string 	name, title;
	uint	keyValue;
}

struct fontUint
{
	string 	name;
	string	fontString;
}

struct CustomTool
{
	string	name, dir, args, toggleShowConsole = "OFF";
}

struct EditorOpacity
{
	string	findfilesDlg = "255", preferenceDlg = "255", projectDlg = "255", gotoDlg = "255", newfileDlg = "255", autocompleteDlg = "220";
}

struct Monitor
{
	int x, y, w, h, id;
}



struct GLOBAL
{
private:
	import iup.iup;
	import iup.iup_scintilla;
	
	import core.sys.windows.wtypes, core.sys.windows.winnt, core.sys.windows.windef;

	import navcache, tools;
	import scintilla, project, layouts.toolbar, layouts.projectPanel, layouts.outlinePanel, layouts.messagePanel, layouts.statusBar, layouts.debugger, layouts.customMenu;
	import dialogs.searchDlg, dialogs.findFilesDlg, dialogs.helpDlg, dialogs.argOptionDlg, dialogs.preferenceDlg;
	import parser.ast, parser.scanner, parser.parser;
	
public:
	version(Windows)
	{
		extern(C)
		{
			// CHM viewer
			alias static	HWND function( HWND, LPCWSTR, UINT, DWORD_PTR) _htmlHelp;

			// DarkMode
			static		BOOL function() InitDarkMode = null;
			static		HRESULT function( HWND, LPCWSTR, LPCWSTR ) SetWindowTheme = null;
		}
	}
	
	static shared CASTnode[string]			parserManager;
	static __gshared IupString[string]		languageItems;
	static __gshared PROJECT[string]		projectManager;
	static shared string[6]					KEYWORDS;
	
	
	static bool					bCanUseDarkMode = false;
	
	static CPLUGIN[string]		pluginMnager;
	
	static Ihandle*				mainDlg;
	static Ihandle*				documentTabs, documentTabs_Sub, projectViewTabs, messageWindowTabs;
	static Ihandle*				dndDocumentZBox;
	
	static Ihandle*				activeDocumentTabs;
	static Ihandle*				dragDocumentTabs;
	
	static int					tabDocumentPos = -1;	

	// LAYOUT
	static Ihandle* 			documentSplit;
	static int					documentSplit_value = 500;
	static Ihandle* 			documentSplit2;
	static int					documentSplit2_value = 500;
	
	static Ihandle* 			explorerWindow;
	static Ihandle* 			explorerSplit; // which split explorerWindow & editWindow
	static int					explorerSplit_value = 300;

	static CCustomMenubar		menubar;
	static CToolBar	 			toolbar;

	static CProjectTree			projectTree;
	static COutline 			outlineTree;
	static CMessageAndSearch	messagePanel;
	static CDebugger 			debugPanel;

	static Ihandle* 			messageSplit; // which split (explorerWindow + editWindow ) & messageWindow
	static int					messageSplit_value = 800;

	static CPreferenceDialog	preferenceDlg;
	static CSearchExpander		searchExpander;
	static CFindInFilesDialog	serachInFilesDlg;
	static CCompilerHelpDialog	compilerHelpDlg;
	static CStatusBar			statusBar;

	static Ihandle*				scrollICONHandle, scrollTimer;
	static Ihandle*				menuOutlineWindow, menuMessageWindow, menuRotateTabs;
	
	
	// Setting
	static string[string]		EnvironmentVars;
	version(Windows) 
	{
		static _htmlHelp		htmlHelp;
	}
	static string				poseidonPath;			// Include Tail /
	static string				linuxHome = "";
	static string				linuxTermName;
	static string				linuxHtmlAppName;
	static int					keywordCase = 0;
	/+
	static string				compilerFullPath, x64compilerFullPath;
	static string				debuggerFullPath, x64debuggerFullPath;
	static string				compilerAnootation = "ON";
	static string				compilerWindow = "OFF";
	static string				compilerSFX = "ON";
	static string				delExistExe = "ON";
	static string				consoleExe = "OFF";
	static string				toggleCompileAtBackThread = "OFF";
	+/
	static string[]				manuals;
	static string				recentOpenDir;
	static string[]				recentOptions, recentArgs, recentCompilers, prevPrj, prevDoc;
	static int					maxRecentOptions = 15, maxRecentArgs = 15, maxRecentCompilers = 8;
	static IupString[]			recentFiles, recentProjects;
	static EditorToggleUint		editorSetting00;
	static EditorLayoutSize		editorSetting01;
	static EditorOpacity		editorSetting02;
	static EditorColorUint		editColor;
	static CompilerSettingUint	compilerSettings;

	static string				extraParsableExt = "inc";
	static string				enableParser = "ON";
	static string				showFunctionTitle = "OFF";
	static string				togglePreLoadPrj = "OFF";
	static string				showTypeWithParams = "OFF";
	static string				toggleIgnoreCase = "ON";		// SCI_AUTOCSETIGNORECASE
	static string				toggleCaseInsensitive = "ON";	// SCI_AUTOCSETCASEINSENSITIVEBEHAVIOUR
	//static string				toggleShowListType = "OFF";
	static string				toggleEnableDwell = "OFF";
	static string				toggleOverWrite = "OFF";
	static string				toggleCompleteAtBackThread = "ON";
	
	static string				toggleUseManual = "OFF";
	
	static string				dwellDelay = "1000";
	static string				triggerDelay = "100";
	static int					autoCMaxHeight = 12;
	static int					indicatorStyle = 16;
	

	static CScintilla[string]	scintillaManager;
	static int[][string]		fileStatusManager;
	
	

	static int					autoCompletionTriggerWordCount = 3;
	static int 					preParseLevel = 3;
	static int					liveLevel = 1;
	static string				toggleUpdateOutlineLive = "ON";

	//Parser
	static Scanner				scanner;
	static CParser				Parser;


	static string				activeProjectPath;
	static string				activeFilePath;
	
	static string				language;
	


	static ShortKey[]			shortKeys;

	static fontUint[]			fonts;
	
	static bool					bKeyUp = true;
	static int					KeyNumber;
	
	static CustomTool[13]		customTools;
	/*
	static string[]				customCompilerOptions;
	static string				currentCustomCompilerOption, noneCustomCompilerOption;
	*/
	static shared CASTnode		objectDefaultParser;
	/+
	version(DIDE)
	{
		static	string			defaultCompilerPath;
		static	string[]		defaultImportPaths;
		static	string			toggleSkipUnittest = "ON";
	}
	+/
	static CNavCache			navigation;
	
	static Monitor[]			monitors;
	static Monitor				consoleWindow;

	static this()
	{
		// Init EditorColorUint
		GLOBAL.editColor.keyWord[0] = "5 91 35";
		GLOBAL.editColor.keyWord[1] = "0 0 255";
		GLOBAL.editColor.keyWord[2] = "231 144 0";
		GLOBAL.editColor.keyWord[3] = "16 108 232";
		GLOBAL.editColor.keyWord[4] = "255 0 0";
		GLOBAL.editColor.keyWord[5] = "0 255 0";
		
		GLOBAL.editColor.caretLine = "255 255 128";
		GLOBAL.editColor.cursor = "0 0 0";
		GLOBAL.editColor.selectionFore = "255 255 255";
		GLOBAL.editColor.selectionBack = "0 0 255";
		GLOBAL.editColor.linenumFore = "0 0 0";
		GLOBAL.editColor.linenumBack = "200 200 200";
		GLOBAL.editColor.fold = "238 238 238";
		GLOBAL.editColor.bookmark = "238 238 238";
		GLOBAL.editColor.selAlpha = "80";
		GLOBAL.editColor.errorFore = "102 69 3";
		GLOBAL.editColor.errorBack = "255 200 227";
		GLOBAL.editColor.warningFore = "0 0 255";
		GLOBAL.editColor.warningBack = "255 255 157";
		GLOBAL.editColor.currentWord = "0 128 0";
		GLOBAL.editColor.currentWordAlpha = "80";
		
		GLOBAL.editColor.braceFore = "255 0 0";
		GLOBAL.editColor.braceBack = "0 255 0";
		
		GLOBAL.editColor.scintillaFore = "0 0 0";
		GLOBAL.editColor.scintillaBack = "255 255 255";
		GLOBAL.editColor.SCE_B_COMMENT_Fore = "0 128 0";
		GLOBAL.editColor.SCE_B_COMMENT_Back = "255 255 255";

		GLOBAL.editColor.SCE_B_NUMBER_Fore = "128 128 64";
		GLOBAL.editColor.SCE_B_NUMBER_Back = "255 255 255";
		GLOBAL.editColor.SCE_B_STRING_Fore = "128 0 0";
		GLOBAL.editColor.SCE_B_STRING_Back = "255 255 255";

		GLOBAL.editColor.SCE_B_PREPROCESSOR_Fore = "0 0 255";
		GLOBAL.editColor.SCE_B_PREPROCESSOR_Back = "255 255 255";
		GLOBAL.editColor.SCE_B_OPERATOR_Fore = "160 20 20";
		GLOBAL.editColor.SCE_B_OPERATOR_Back = "255 255 255";

		GLOBAL.editColor.SCE_B_IDENTIFIER_Fore = "0 0 0";
		GLOBAL.editColor.SCE_B_IDENTIFIER_Back = "255 255 255";
		GLOBAL.editColor.SCE_B_COMMENTBLOCK_Fore = "0 128 0";
		GLOBAL.editColor.SCE_B_COMMENTBLOCK_Back = "255 255 255";

		GLOBAL.editColor.projectFore = "0 0 0";
		GLOBAL.editColor.projectBack = "255 255 255";
		GLOBAL.editColor.outlineFore = "0 0 0";
		GLOBAL.editColor.outlineBack = "255 255 255";
		GLOBAL.editColor.outputFore = "0 0 0";
		GLOBAL.editColor.outputBack = "255 255 255";
		GLOBAL.editColor.searchFore = "0 0 0";
		GLOBAL.editColor.searchBack = "255 255 255";
		GLOBAL.editColor.dlgFore = "0 0 0";
		GLOBAL.editColor.dlgBack = "240 240 240";
		GLOBAL.editColor.txtFore = "0 0 0";
		GLOBAL.editColor.txtBack = "255 255 255";


		GLOBAL.editColor.prjTitle = "128 0 0";
		GLOBAL.editColor.prjSourceType = "0 0 255";
		
		GLOBAL.editColor.callTipFore = "0 0 255";
		GLOBAL.editColor.callTipBack = "234 248 192";
		GLOBAL.editColor.callTipHLT = "202 0 0";

		GLOBAL.editColor.showTypeFore = "0 0 255";
		GLOBAL.editColor.showTypeBack = "255 255 170";
		GLOBAL.editColor.showTypeHLT = "0 128 0";

		GLOBAL.editColor.autoCompleteFore = "0 0 0";
		GLOBAL.editColor.autoCompleteBack = "255 255 255";
		GLOBAL.editColor.autoCompleteHLTFore = "0 0 0";
		GLOBAL.editColor.autoCompleteHLTBack = "0 188 0";
		
		GLOBAL.editColor.searchIndicator = "0 0 255";
		GLOBAL.editColor.searchIndicatorAlpha = "128";
		GLOBAL.editColor.prjViewHLT = "0 0 128";
		GLOBAL.editColor.prjViewHLTAlpha = "128";
		
		/*
		GLOBAL.debuggerFullPath = new IupString();
		GLOBAL.x64debuggerFullPath = new IupString();
		GLOBAL.linuxTermName = new IupString();
		*/
		//GLOBAL.colorTemplate = new IupString();
		//GLOBAL.defaultOption = new IupString();
		
		GLOBAL.compilerSettings.currentCustomCompilerOption = "";
		GLOBAL.compilerSettings.noneCustomCompilerOption = "None Custom Compile Option";
		
		GLOBAL.Parser = new CParser;
		
		version(FBIDE)
		{
			GLOBAL.KEYWORDS[0] = "__date__ __date_iso__ __fb_64bit__ __fb_argc__ __fb_argv__ __fb_arm__ __fb_asm__ __fb_backend__ __fb_bigendian__ __fb_build_date__ __fb_cygwin__ __fb_darwin__ __fb_debug__ __fb_dos__ __fb_err__ __fb_fpmode__ __fb_fpu__ __fb_freebsd__ __fb_gcc__ __fb_lang__ __fb_linux__ __fb_main__ __fb_min_version__ __fb_mt__ __fb_netbsd__ __fb_openbsd__ __fb_option_byval__ __fb_option_dynamic__ __fb_option_escape__ __fb_option_explicit__ __fb_option_gosub__ __fb_option_private__ __fb_out_dll__ __fb_out_exe__ __fb_out_lib__ __fb_out_obj__ __fb_pcos__ __fb_signature__ __fb_sse__ __fb_unix__ __fb_vectorize__ __fb_ver_major__ __fb_ver_minor__ __fb_ver_patch__ __fb_version__ __fb_win32__ __fb_xbox__ __file__ __file_nq__ __function__ __function_nq__ __line__ __path__ __time__ #assert #define #else #elseif #endif #endmacro #error #if #ifdef #ifndef #inclib #include #lang #libpath #line #macro #pragma #print #undef $dynamic $include $static $lang  abs abstract access acos add alias allocate alpha and andalso any append as assert assertwarn asc asin asm atan2 atn base beep bin binary bit bitreset bitset bload bsave byref byte byval call callocate case cast cbyte cdbl cdecl chain chdir";
			GLOBAL.KEYWORDS[1] = "chr cint circle class clear clng clngint close cls color command common condbroadcast condcreate conddestroy condsignal condwait const constructor continue cos cptr cshort csign csng csrlin cubyte cuint culng culngint cunsg curdir cushort custom cvd cvi cvl cvlongint cvs cvshort data date dateadd datediff datepart dateserial datevalue day deallocate declare defbyte defdbl defined defint deflng deflongint defshort defsng defstr defubyte defuint defulongint defushort delete destructor dim dir do double draw dylibfree dylibload dylibsymbol else elseif encoding end enum environ eof eqv erase erfn erl ermn err error event exec exepath exit exp export extends extern field fileattr filecopy filedatetime fileexists filelen fix flip for format frac fre freefile function get getjoystick getkey getmouse gosub goto hex hibyte hiword";
			GLOBAL.KEYWORDS[2] = "hour if iif imageconvertrow imagecreate imagedestroy imageinfo imp implements import inkey inp input instr instrrev int integer is isdate isredirected kill lbound lcase left len let lib line lobyte loc local locate lock lof log long longint loop loword lpos lprint lset ltrim mid minute mkd mkdir mki mkl mklongint mks mkshort mod month monthname multikey mutexcreate mutexdestroy mutexlock mutexunlock naked name namespace next new not now object oct offsetof on once open operator option or orelse out output overload override paint palette pascal pcopy peek pmap point pointcoord pointer poke pos preserve preset print private procptr property protected pset ptr public put random randomize read reallocate redim rem reset restore resume return rgb rgba right rmdir";
			GLOBAL.KEYWORDS[3] = "rnd rset rtrim run sadd scope screen screencopy screencontrol screenevent screeninfo screenglproc screenlist screenlock screenptr screenres screenset screensync screenunlock second seek select setdate setenviron setmouse settime sgn shared shell shl shr short sin single sizeof sleep space spc sqr static stdcall step stick stop str strig string strptr sub swap system tab tan then this threadcall threadcreate threaddetach threadwait time timeserial timevalue timer to trans trim type typeof ubound ubyte ucase uinteger ulong ulongint union unlock unsigned until ushort using va_arg va_first va_next val vallng valint valuint valulng var varptr view virtual wait wbin wchr weekday weekdayname wend while whex width window windowtitle winput with woct write wspace wstr wstring xor year zstring";
			GLOBAL.KEYWORDS[4] = "";
			GLOBAL.KEYWORDS[5] = "";
		}
		version(DIDE)
		{
			GLOBAL.KEYWORDS[0] = "abstract alias align asm assert auto body bool break byte case cast catch cdouble cent cfloat char class const continue creal dchar debug default delegate delete deprecated do double";
			GLOBAL.KEYWORDS[1] = "else enum export extern false final finally float for foreach foreach_reverse function goto idouble if ifloat immutable import in inout int interface invariant ireal is lazy long macro mixin module";
			GLOBAL.KEYWORDS[2] = "new nothrow null out override package pragma private protected public pure real ref return scope shared short static struct super switch synchronized template this throw true try typedef typeid typeof";
			GLOBAL.KEYWORDS[3] = "ubyte ucent uint ulong union unittest ushort version void volatile wchar while with __FILE__ __FILE_FULL_PATH__ __MODULE__ __LINE__ __FUNCTION__ __PRETTY_FUNCTION__ __gshared __traits __vector __parameters";
			GLOBAL.KEYWORDS[4] = "";
			GLOBAL.KEYWORDS[5] = "";
		}

		ShortKey sk0 = { "save", "Save File", 536870995 };
		GLOBAL.shortKeys ~= sk0;
		ShortKey sk1 = { "saveall", "Save All", 805306451 };
		GLOBAL.shortKeys ~= sk1;
		ShortKey sk2 = { "close", "Close File", 536870999 };
		GLOBAL.shortKeys ~= sk2;
		ShortKey sk3 = { "newtab", "New Tab", 536870990 };
		GLOBAL.shortKeys ~= sk3;
		ShortKey sk4 = { "nexttab", "Next Tab", 536870921 };
		GLOBAL.shortKeys ~= sk4;
		ShortKey sk5 = { "prevtab","Previous Tab", 805306377 };
		GLOBAL.shortKeys ~= sk5;

		ShortKey sk6 = { "dupdown", "Duplication Line Down", 0 };
		GLOBAL.shortKeys ~= sk6;
		ShortKey sk7 = { "dupup", "Duplication Line Up", 0 };
		GLOBAL.shortKeys ~= sk7;
		ShortKey sk8 = { "delline", "Delete Line", 0 };
		GLOBAL.shortKeys ~= sk8;
		ShortKey sk9 = { "find", "Find/Replace", 536870982 };
		GLOBAL.shortKeys ~= sk9;
		ShortKey sk10 = { "findinfile", "Find/Replace In Files", 805306438 };
		GLOBAL.shortKeys ~= sk10;
		ShortKey sk11 = { "findnext", "Find Next", 65472 };
		GLOBAL.shortKeys ~= sk11;
		ShortKey sk12 = { "findprev", "Find Previous", 536936384 };
		GLOBAL.shortKeys ~= sk12;
		ShortKey sk13 = { "gotoline", "Goto Line", 536870983 };
		GLOBAL.shortKeys ~= sk13;
		ShortKey sk14 = { "undo", "Undo", 536871002 };
		GLOBAL.shortKeys ~= sk14;
		ShortKey sk15 = { "redo", "Redo", 805306458 };
		GLOBAL.shortKeys ~= sk15;
		ShortKey sk16 = { "comment", "Comment", 536870994 };
		GLOBAL.shortKeys ~= sk16;
		ShortKey sk17 = { "uncomment", "UnComment", 805306450 };
		GLOBAL.shortKeys ~= sk17;
		ShortKey sk18 = { "backnav", "Backward Navigation", 536870984 };
		GLOBAL.shortKeys ~= sk18;
		ShortKey sk19 = { "forwardnav", "Forkward Navigation", 805306440 };
		GLOBAL.shortKeys ~= sk19;
		
		ShortKey sk20 = { "showtype", "Show Type", 65470 };
		GLOBAL.shortKeys ~= sk20;
		ShortKey sk21 = { "defintion", "Goto Defintion", 1073741895 };
		GLOBAL.shortKeys ~= sk21;
		ShortKey sk22 = { "procedure", "Goto Member Procedure", 536870992 };		
		GLOBAL.shortKeys ~= sk22;
		ShortKey sk23 = { "autocomplete", "Autocomplete", 536870993 };
		GLOBAL.shortKeys ~= sk23;
		ShortKey sk24 = { "reparse", "Reparse", 65471 };
		GLOBAL.shortKeys ~= sk24;

		ShortKey sk25 = { "compilerun", "Compile & Run", 536936386 };
		GLOBAL.shortKeys ~= sk25;
		ShortKey sk26 = { "quickrun", "Quick Run", 268500930 };
		GLOBAL.shortKeys ~= sk26;
		ShortKey sk27 = { "run", "Run", 65474 };
		GLOBAL.shortKeys ~= sk27;
		ShortKey sk28 = { "build", "Build", 65475 };
		GLOBAL.shortKeys ~= sk28;
		
		ShortKey sk29 = { "leftwindow", "Switch Left-side Window", 65477 };
		GLOBAL.shortKeys ~= sk29;
		ShortKey sk30 = { "bottomwindow", "Switch Bottom-side Window", 65478 };
		GLOBAL.shortKeys ~= sk30;
		ShortKey sk31 = { "outlinewindow", "On/Off Left-side Window", 65480 };
		GLOBAL.shortKeys ~= sk31;
		ShortKey sk32 = { "messagewindow", "On/Off Bottom-side Window", 65481 };
		GLOBAL.shortKeys ~= sk32;		

		ShortKey sk33 = { "customtool1", "Custom Tool(1)", 805371838 };
		GLOBAL.shortKeys ~= sk33;
		ShortKey sk34 = { "customtool2", "Custom Tool(2)", 805371839 };
		GLOBAL.shortKeys ~= sk34;
		ShortKey sk35 = { "customtool3", "Custom Tool(3)", 805371840 };
		GLOBAL.shortKeys ~= sk35;
		ShortKey sk36 = { "customtool4", "Custom Tool(4)", 805371841 };
		GLOBAL.shortKeys ~= sk36;
		ShortKey sk37 = { "customtool5", "Custom Tool(5)", 805371842 };
		GLOBAL.shortKeys ~= sk37;
		ShortKey sk38 = { "customtool6", "Custom Tool(6)", 805371843 };
		GLOBAL.shortKeys ~= sk38;
		ShortKey sk39 = { "customtool7", "Custom Tool(7)", 805371844 };
		GLOBAL.shortKeys ~= sk39;
		ShortKey sk40 = { "customtool8", "Custom Tool(8)", 805371845 };
		GLOBAL.shortKeys ~= sk40;
		ShortKey sk41 = { "customtool9", "Custom Tool(9)", 805371846 };		
		GLOBAL.shortKeys ~= sk41;
		ShortKey sk42 = { "customtool10", "Custom Tool(10)", 805371847 };		
		GLOBAL.shortKeys ~= sk42;
		ShortKey sk43 = { "customtool11", "Custom Tool(11)", 805371848 };		
		GLOBAL.shortKeys ~= sk43;
		ShortKey sk44 = { "customtool12", "Custom Tool(12)", 805371849 };		
		GLOBAL.shortKeys ~= sk44;


		fontUint fu;
		version( Windows )
		{
			fu.name ="default";
			fu.fontString = "Courier New,10";
		}
		else
		{
			fu.name ="default";
			fu.fontString = "Monospace, 10";
		}

		GLOBAL.fonts ~= fu;

		fu.name = "document";
		GLOBAL.fonts ~= fu;

		fu.name = "leftside";
		GLOBAL.fonts ~= fu;
		
		fu.name = "filelist";
		GLOBAL.fonts ~= fu;

		fu.name = "caption_prj";
		GLOBAL.fonts ~= fu;

		fu.name = "outline";
		GLOBAL.fonts ~= fu;

		fu.name = "bottom";
		GLOBAL.fonts ~= fu;

		fu.name = "output";
		GLOBAL.fonts ~= fu;

		fu.name = "search";
		GLOBAL.fonts ~= fu;	

		fu.name = "debug";
		GLOBAL.fonts ~= fu;

		fu.name = "annotation";
		GLOBAL.fonts ~= fu;

		fu.name = "statusbar";
		GLOBAL.fonts ~= fu;
		
		
		
		GLOBAL.languageItems["file"] = new IupString( "File" );
			GLOBAL.languageItems["new"] = new IupString( "New" );
			GLOBAL.languageItems["open"] = new IupString( "Open" );
			GLOBAL.languageItems["save"] = new IupString( "Save" );
			GLOBAL.languageItems["saveas"] = new IupString( "Save As" );
			GLOBAL.languageItems["savetabs"] = new IupString( "Save Tab Files" );
			GLOBAL.languageItems["saveall"] = new IupString( "Save All" );
			GLOBAL.languageItems["close"] = new IupString( "Close" );
			GLOBAL.languageItems["closeall"] = new IupString( "Close All" );
			GLOBAL.languageItems["closealltabs"] = new IupString( "Close All Tabs" );
			GLOBAL.languageItems["recentfiles"] = new IupString( "Recent Files" );
			GLOBAL.languageItems["recentprjs"] = new IupString( "Recent Projects" );
			GLOBAL.languageItems["clearall"] = new IupString( "Clear All" );
			GLOBAL.languageItems["exit"] = new IupString( "Exit" );
			
		GLOBAL.languageItems["edit"] = new IupString( "Edit" );
			GLOBAL.languageItems["redo"] = new IupString( "Redo" );
			GLOBAL.languageItems["undo"] = new IupString( "Undo" );
			GLOBAL.languageItems["cut"] = new IupString( "Cut" );
			GLOBAL.languageItems["copy"] = new IupString( "Copy" );
			GLOBAL.languageItems["paste"] = new IupString( "Paste" );
			GLOBAL.languageItems["commentline"] = new IupString( "Comment Line" );
			GLOBAL.languageItems["uncommentline"] = new IupString( "UnComment Line" );
			GLOBAL.languageItems["selectall"] = new IupString( "Select All" );
			
		GLOBAL.languageItems["search"] = new IupString( "Search" );
			GLOBAL.languageItems["findreplace"] = new IupString( "Find/Replace" );
			GLOBAL.languageItems["findnext"] = new IupString( "Find Next" );
			GLOBAL.languageItems["findprev"] = new IupString( "Find Previous" );
			GLOBAL.languageItems["findreplacefiles"] = new IupString( "Find/Replace In Files" );
			GLOBAL.languageItems["goto"] = new IupString( "Goto Line" );
				GLOBAL.languageItems["line"] = new IupString( "Line" );

		GLOBAL.languageItems["windows"] = new IupString( "Windows" );
		GLOBAL.languageItems["view"] = new IupString( "View" );
			GLOBAL.languageItems["toolbar"]= new IupString( "Toolbar" );
			GLOBAL.languageItems["message"]= new IupString( "Message" );
			GLOBAL.languageItems["manual"]= new IupString( "Manual" );
			GLOBAL.languageItems["fullscreen"]= new IupString( "Fullscreen" );
			
		GLOBAL.languageItems["prj"] = new IupString( "Project" );
			GLOBAL.languageItems["newprj"] = new IupString( "New Project" );
			GLOBAL.languageItems["openprj"] = new IupString( "Open Project" );
			GLOBAL.languageItems["importprj"] = new IupString( "Import Fbedit Project" );
			GLOBAL.languageItems["saveprj"] = new IupString( "Save Project" );
			GLOBAL.languageItems["saveallprj"] = new IupString( "Save All Projects" );
			GLOBAL.languageItems["closeprj"] = new IupString( "Close Project" );
			GLOBAL.languageItems["closeallprj"] = new IupString( "Close All Projects" );
			GLOBAL.languageItems["properties"] = new IupString( "Properties..." );
			
			GLOBAL.languageItems["importall"] = new IupString( "Import All Files" );
			GLOBAL.languageItems["openinexplorer"] = new IupString( "Open In Explorer" );
			GLOBAL.languageItems["removefromprj"] = new IupString( "Remove From Project" );
			GLOBAL.languageItems["openinposeidon"] = new IupString( "Open In Poseidon" );
			GLOBAL.languageItems["rename"] = new IupString( "Rename File" );
			GLOBAL.languageItems["setmainmodule"] = new IupString( "Set As Main Module" );
			GLOBAL.languageItems["newfile"] = new IupString( "New File" );
				GLOBAL.languageItems["filename"] = new IupString( "File Name" );
			GLOBAL.languageItems["newfolder"] = new IupString( "New Folder" );
				GLOBAL.languageItems["foldername"] = new IupString( "Folder Name" );
			GLOBAL.languageItems["addfile"] = new IupString( "Add file(s)" );
		
		GLOBAL.languageItems["build"] = new IupString( "Build" );
			GLOBAL.languageItems["compile"] = new IupString( "Compile File" );
			GLOBAL.languageItems["compilerun"]= new IupString( "Compile File And Run" );
			GLOBAL.languageItems["run"] = new IupString( "Run" );
			GLOBAL.languageItems["buildprj"] = new IupString( "Build Project" );
			GLOBAL.languageItems["rebuildprj"] = new IupString( "ReBuild Project" );
			GLOBAL.languageItems["quickrun"] = new IupString( "Quick Run" );
			
		GLOBAL.languageItems["debug"] = new IupString( "Debug" );
			GLOBAL.languageItems["rundebug"] = new IupString( "Run Debug" );
			GLOBAL.languageItems["compiledebug"] = new IupString( "Compile With Debug" );
			GLOBAL.languageItems["builddebug"] = new IupString( "Build Project With Debug" );
			
		GLOBAL.languageItems["options"] = new IupString( "Options" );
			GLOBAL.languageItems["tools"] = new IupString( "Tools" );
				GLOBAL.languageItems["unload"] = new IupString( "Unload" );
				GLOBAL.languageItems["pluginstatus"] = new IupString( "Plugin Status" );
				GLOBAL.languageItems["seteol"] = new IupString( "Set Eol Character" );
				GLOBAL.languageItems["converteol"] = new IupString( "Convert Eol Character" );
				GLOBAL.languageItems["convertencoding"] = new IupString( "Convert Encoding" );
				GLOBAL.languageItems["convertcase"] = new IupString( "Convert Keyword Case" );
					GLOBAL.languageItems["uppercase"] = new IupString( "UPPERCASE" );
					GLOBAL.languageItems["lowercase"] = new IupString( "lowercase" );
					GLOBAL.languageItems["mixercase"] = new IupString( "Mixedcase" );
					GLOBAL.languageItems["usercase"] = new IupString( "User Define" );
				GLOBAL.languageItems["setcustomtool"] = new IupString( "Set Custom Tools..." );
					GLOBAL.languageItems["customtool1"] = new IupString( "Custom Tool(1)" );
					GLOBAL.languageItems["customtool2"] = new IupString( "Custom Tool(2)" );
					GLOBAL.languageItems["customtool3"] = new IupString( "Custom Tool(3)" );
					GLOBAL.languageItems["customtool4"] = new IupString( "Custom Tool(4)" );
					GLOBAL.languageItems["customtool5"] = new IupString( "Custom Tool(5)" );
					GLOBAL.languageItems["customtool6"] = new IupString( "Custom Tool(6)" );
					GLOBAL.languageItems["customtool7"] = new IupString( "Custom Tool(7)" );
					GLOBAL.languageItems["customtool8"] = new IupString( "Custom Tool(8)" );
					GLOBAL.languageItems["customtool9"] = new IupString( "Custom Tool(9)" );
					GLOBAL.languageItems["customtool10"] = new IupString( "Custom Tool(10)" );
					GLOBAL.languageItems["customtool11"] = new IupString( "Custom Tool(11)" );
					GLOBAL.languageItems["customtool12"] = new IupString( "Custom Tool(12)" );
				
			GLOBAL.languageItems["preference"] = new IupString( "Preference" );
				GLOBAL.languageItems["compiler"] = new IupString( "Compiler" );
					GLOBAL.languageItems["compilerpath"] = new IupString( "Compiler Path" );
					GLOBAL.languageItems["debugpath"] = new IupString( "Debugger Path" );
					GLOBAL.languageItems["debugx64path"] = new IupString( "Debugger x64 Path" );
					GLOBAL.languageItems["terminalpath"] = new IupString( "Terminal Path" );
					GLOBAL.languageItems["htmlapppath"] = new IupString( "Html App Path" );
					GLOBAL.languageItems["x64path"] = new IupString( "x64 Path" );
					GLOBAL.languageItems["compileropts"] = new IupString( "Compiler Opts" );
					GLOBAL.languageItems["compilersetting"] = new IupString( "Compiler Setting" );
						GLOBAL.languageItems["errorannotation"] = new IupString( "Show Compiler Errors/Warnings Using Annotation" );
						GLOBAL.languageItems["showresultwindow"] = new IupString( "Show Compiled Result Window" );
						GLOBAL.languageItems["usesfx"] = new IupString( "Play Result SFX( When Result Window is OFF )" );
						GLOBAL.languageItems["delexistexe"] = new IupString( "Before Compile, Delete Existed Execute File" );
						GLOBAL.languageItems["consoleexe"] = new IupString( "Use Console Launcher To Run Program" );
						GLOBAL.languageItems["compileatbackthread"] = new IupString( "Enable Compile At Back Thread" );
				GLOBAL.languageItems["parser"] = new IupString( "Parser" );
					GLOBAL.languageItems["parsersetting"] = new IupString( "Parser Settings" );
						GLOBAL.languageItems["enablekeyword"] = new IupString( "Enable Keyword Autocomplete" );
						GLOBAL.languageItems["enableinclude"] = new IupString( "Enable Include Autocomplete" );
						GLOBAL.languageItems["enableparser"] = new IupString( "Enable Parser" );
						GLOBAL.languageItems["showtitle"] = new IupString( "Show Function Title" );
						GLOBAL.languageItems["preloadprj"] = new IupString( "Project Pre-Parse While Loading" );
						GLOBAL.languageItems["width"] = new IupString( "Width" );
						GLOBAL.languageItems["showtypeparam"] = new IupString( "Show Type With Function Parameters" );
						GLOBAL.languageItems["sortignorecase"] = new IupString( "Autocomplete List Is Ignore Case" );
						GLOBAL.languageItems["selectcase"] = new IupString( "Selection Of Autocomplete List Is Case Insensitive" );
						GLOBAL.languageItems["showlisttype"] = new IupString( "Show Autocomplete List Type" );
						GLOBAL.languageItems["showallmembers"] = new IupString( "Show All Members( public, protected, private )" );
						GLOBAL.languageItems["enabledwell"] = new IupString( "Enable Mouse Dwell to Show Type" );
							GLOBAL.languageItems["dwelldelay"] = new IupString( "Dwell Delay(ms):" );
						GLOBAL.languageItems["enableoverwrite"] = new IupString( "Overwrite To Non Identifier Character" );
						GLOBAL.languageItems["completeatbackthread"] = new IupString( "Enable Codecomplete At Back Thread" );
							GLOBAL.languageItems["completedelay"] = new IupString( "Trigger Delay(ms):" );
							GLOBAL.languageItems["preparselevel"] = new IupString( "Project Pre-Parse Level:" );
						GLOBAL.languageItems["parserlive"] = new IupString( "ParseLive! Level" );
							GLOBAL.languageItems["none"] = new IupString( "None" );
							GLOBAL.languageItems["light"] = new IupString( "Light" );
							GLOBAL.languageItems["full"] = new IupString( "Full" );
							GLOBAL.languageItems["update"] = new IupString( "Update Outline" );
						GLOBAL.languageItems["trigger"] = new IupString( "Autocompletion Trigger:" );
							GLOBAL.languageItems["triggertip"] = new IupString( "Set 0 To Disable" );
							GLOBAL.languageItems["codecompletiononoff"] = new IupString( "Code Completion On/Off" );
						GLOBAL.languageItems["includelevel"] = new IupString( "Include Levels:" );
							GLOBAL.languageItems["includeleveltip"] = new IupString( "Set -1 To Unlimited" );
						GLOBAL.languageItems["autocmaxheight"] = new IupString( "Max Complete List Items:" );
					GLOBAL.languageItems["editor"] = new IupString( "Editor" );
						GLOBAL.languageItems["lnmargin"] = new IupString( "Show Linenumber Margin" );
						GLOBAL.languageItems["fixedlnmargin"] = new IupString( "Fixed Linenumber Margin Size" );
						GLOBAL.languageItems["bkmargin"] = new IupString( "Show Bookmark Margin" );
						GLOBAL.languageItems["fdmargin"] = new IupString( "Show Folding Margin" );
						GLOBAL.languageItems["indentguide"] = new IupString( "Show Indentation Guide" );
						GLOBAL.languageItems["showcaretline"] = new IupString( "Highlight Caret Line" );
						GLOBAL.languageItems["wordwarp"] = new IupString( "Word Wrap" );
						GLOBAL.languageItems["tabtospace"] = new IupString( "Replace Tab With Space" );
						GLOBAL.languageItems["autoindent"] = new IupString( "Automatic Indent" );
						GLOBAL.languageItems["showeol"] = new IupString( "Show EOL Sign" );
						GLOBAL.languageItems["showspacetab"] = new IupString( "Show Space/Tab" );
						GLOBAL.languageItems["autoinsertend"] = new IupString( "Auto Insert Block End" );
						GLOBAL.languageItems["autoclose"] = new IupString( "Auto Close( quotes... )" );
						GLOBAL.languageItems["coloroutline"] = new IupString( "Colorize Outline Item" );
						GLOBAL.languageItems["boldkeyword"] = new IupString( "Bold Keywords" );
						GLOBAL.languageItems["bracematchhighlight"] = new IupString( "Show Brace Match Highlight" );
						GLOBAL.languageItems["bracematchdoubleside"] = new IupString( "Use Double-Side Brace Match" );
						GLOBAL.languageItems["multiselection"] = new IupString( "Enable Document Multi Selection" );
						GLOBAL.languageItems["loadprevdoc"] = new IupString( "Load Previous Documents" );
						GLOBAL.languageItems["middlescroll"] = new IupString( "Middle Button Scroll" );
						GLOBAL.languageItems["savedocstatus"] = new IupString( "Save Document Status" );
						GLOBAL.languageItems["colorbarline"] = new IupString( "Colorize Splitter BarLine" );
						GLOBAL.languageItems["autokblayout"] = new IupString( "Auto en-Keyboard Layout" );
						GLOBAL.languageItems["controlcharsymbol"] = new IupString( "Set Control Char Symbol" );
						GLOBAL.languageItems["tabwidth"] = new IupString( "Tab Width" );
						GLOBAL.languageItems["columnedge"] = new IupString( "Column Edge" );
						GLOBAL.languageItems["barsize"] = new IupString( "Bar Size" );
							GLOBAL.languageItems["barsizetip"] = new IupString( "Need Restart Poseidon (2~5)" );
						GLOBAL.languageItems["maker0"] = new IupString( "Maker0" );
						GLOBAL.languageItems["maker1"] = new IupString( "Maker1" );
						GLOBAL.languageItems["maker2"] = new IupString( "Maker2" );
						GLOBAL.languageItems["maker3"] = new IupString( "Maker3" );
						GLOBAL.languageItems["autoconvertkeyword"] = new IupString( "Auto Convert Keyword Case" );
						GLOBAL.languageItems["qbcase"] = new IupString( "Use QB-IDE Convert Case" );
						GLOBAL.languageItems["newdocbom"] = new IupString( "Create New Doc With BOM" );
						GLOBAL.languageItems["saveallmodified"] = new IupString( "Save All Documents Before Compile" );
						GLOBAL.languageItems["font"] = new IupString( "Font" );
							GLOBAL.languageItems["default"] = new IupString( "Default" );
							//GLOBAL.languageItems["document"] = new IupString( "Document" );
							GLOBAL.languageItems["leftside"] = new IupString( "Leftside" );
							//'fistlist=FileList
							//'project=Project
							//'outline=Outline
							GLOBAL.languageItems["bottom"] = new IupString( "Bottom" );
							//'output=Output
							//'search=Search
							//'debug=Debug
							GLOBAL.languageItems["annotation"] = new IupString( "Annotation" );
							GLOBAL.languageItems["statusbar"] = new IupString( "StatusBar" );
							GLOBAL.languageItems["item"] = new IupString( "Item" );
							GLOBAL.languageItems["face"] = new IupString( "Face" );
							GLOBAL.languageItems["style"] = new IupString( "Style" );
							GLOBAL.languageItems["size"] = new IupString( "Size" );
						GLOBAL.languageItems["color"] = new IupString( "Color" );
							GLOBAL.languageItems["colorfile"] = new IupString( "Color Template" );
							GLOBAL.languageItems["caretline"] = new IupString( "Caret Line" );
							GLOBAL.languageItems["cursor"] = new IupString( "Cursor" );
							GLOBAL.languageItems["prjtitle"] = new IupString( "Project Title" );
							GLOBAL.languageItems["sourcefolder"] = new IupString( "Source Folder" );
							GLOBAL.languageItems["sel"] = new IupString( "Selection" );
							GLOBAL.languageItems["ln"] = new IupString( "Linenumber" );
							GLOBAL.languageItems["foldcolor"] = new IupString( "FoldingMargin Color" );
							GLOBAL.languageItems["selalpha"] = new IupString( "Selection Alpha" );
								GLOBAL.languageItems["alphatip"] = new IupString( "Set 255 To Use Fore/BackColor\nSet 0 To Keep ForeColor" );
							GLOBAL.languageItems["hlcurrentword"] = new IupString( "Current Word Indicator" );
							
						GLOBAL.languageItems["colorfgbg"] = new IupString( "Color/Foreground/Background or Alpha" );
							GLOBAL.languageItems["bracehighlight"] = new IupString( "Brace Highlight" );
							GLOBAL.languageItems["manualerrorannotation"] = new IupString( "Error Annotation" );
							GLOBAL.languageItems["manualwarningannotation"] = new IupString( "Warning Annotation" );
							GLOBAL.languageItems["scintilla"] = new IupString( "Scintilla" );
							version(FBIDE)
							{
								GLOBAL.languageItems["SCE_B_COMMENT"] = new IupString( "SCE_B_COMMENT" );
								GLOBAL.languageItems["SCE_B_NUMBER"] = new IupString( "SCE_B_NUMBER" );
								GLOBAL.languageItems["SCE_B_STRING"] = new IupString( "SCE_B_STRING" );
								GLOBAL.languageItems["SCE_B_PREPROCESSOR"] = new IupString( "SCE_B_PREPROCESSOR" );
								GLOBAL.languageItems["SCE_B_OPERATOR"] = new IupString( "SCE_B_OPERATOR" );
								GLOBAL.languageItems["SCE_B_IDENTIFIER"] = new IupString( "SCE_B_IDENTIFIER" );
								GLOBAL.languageItems["SCE_B_COMMENTBLOCK"] = new IupString( "SCE_B_COMMENTBLOCK" );
							}
							version(DIDE)
							{
								GLOBAL.languageItems["SCE_B_COMMENT"] = new IupString( "SCE_D_COMMENT" );
								GLOBAL.languageItems["SCE_B_NUMBER"] = new IupString( "SCE_D_NUMBER" );
								GLOBAL.languageItems["SCE_B_STRING"] = new IupString( "SCE_D_STRING" );
								GLOBAL.languageItems["SCE_B_PREPROCESSOR"] = new IupString( "SCE_D_PREPROCESSOR" );
								GLOBAL.languageItems["SCE_B_OPERATOR"] = new IupString( "SCE_D_OPERATOR" );
								GLOBAL.languageItems["SCE_B_IDENTIFIER"] = new IupString( "SCE_D_IDENTIFIER" );
								GLOBAL.languageItems["SCE_B_COMMENTBLOCK"] = new IupString( "SCE_D_COMMENTBLOCK" );
							}

					GLOBAL.languageItems["shortcut"] = new IupString( "Short Cut" );
						GLOBAL.languageItems["sc_findreplace"] = new IupString( "Find/Replace" );
						GLOBAL.languageItems["sc_findreplacefiles"] = new IupString( "Find/Replace In Files" );
						GLOBAL.languageItems["sc_findnext"] = new IupString( "Find Next" );
						GLOBAL.languageItems["sc_findprev"] = new IupString( "Find Previous" );
						GLOBAL.languageItems["sc_dupdown"] = new IupString( "Duplication Line Down" );
						GLOBAL.languageItems["sc_dupup"] = new IupString( "Duplication Line Up" );
						GLOBAL.languageItems["sc_delline"] = new IupString( "Delete Line" );
						GLOBAL.languageItems["sc_goto"] = new IupString( "Goto Line" );
						GLOBAL.languageItems["sc_undo"] = new IupString( "Undo" );
						GLOBAL.languageItems["sc_redo"] = new IupString( "Redo" );
						GLOBAL.languageItems["sc_gotodef"] = new IupString( "Goto Definition" );
						version(FBIDE)	GLOBAL.languageItems["sc_procedure"] = new IupString( "Goto Member Procedure" );
						version(DIDE)	GLOBAL.languageItems["sc_procedure"] = new IupString( "Goto Top Definition" );
						GLOBAL.languageItems["sc_quickrun"] = new IupString( "Quick Run" );
						GLOBAL.languageItems["sc_run"] = new IupString( "Run" );
						GLOBAL.languageItems["sc_compile"] = new IupString( "Compile" );
						GLOBAL.languageItems["sc_build"] = new IupString( "Build Project" );
						GLOBAL.languageItems["sc_leftwindowswitch"] = new IupString( "Switch Left Window" );
						GLOBAL.languageItems["sc_bottomwindowswitch"] = new IupString( "Sswitch Bottom Window" );						
						GLOBAL.languageItems["sc_leftwindow"] = new IupString( "On/Off Left Window" );
						GLOBAL.languageItems["sc_bottomwindow"] = new IupString( "On/Off Bottom Window" );
						GLOBAL.languageItems["sc_showtype"] = new IupString( "Show Type" );
						GLOBAL.languageItems["sc_reparse"] = new IupString( "Reparse" );
						GLOBAL.languageItems["sc_save"] = new IupString( "Save File" );
						GLOBAL.languageItems["sc_saveall"] = new IupString( "Save All" );
						GLOBAL.languageItems["sc_close"] = new IupString( "Close File" );
						GLOBAL.languageItems["sc_nexttab"] = new IupString( "Next Tab" );
						GLOBAL.languageItems["sc_prevtab"] = new IupString( "Previous Tab" );
						GLOBAL.languageItems["sc_newtab"] = new IupString( "New Tab" );
						GLOBAL.languageItems["sc_autocomplete"] = new IupString( "Auto Complete" );
						GLOBAL.languageItems["sc_compilerun"] = new IupString( "Compile File And Run" );
						GLOBAL.languageItems["sc_comment"] = new IupString( "Comment" );
						GLOBAL.languageItems["sc_uncomment"] = new IupString( "UnComment" );
						GLOBAL.languageItems["sc_backnav"] = new IupString( "Backward Navigation" );
						GLOBAL.languageItems["sc_forwardnav"] = new IupString( "Forward Navigation" );
						GLOBAL.languageItems["sc_backdefinition"] = new IupString( "Back Definition" );
						
					GLOBAL.languageItems["keywords"] = new IupString( "Keywords" );
						GLOBAL.languageItems["keyword0"] = new IupString( "Keyword0" );
						GLOBAL.languageItems["keyword1"] = new IupString( "Keyword1" );
						GLOBAL.languageItems["keyword2"] = new IupString( "Keyword2" );
						GLOBAL.languageItems["keyword3"] = new IupString( "Keyword3" );
						GLOBAL.languageItems["keyword4"] = new IupString( "Keyword4" );
						GLOBAL.languageItems["keyword5"] = new IupString( "Keyword5" );
						GLOBAL.languageItems["setkeyword"] = new IupString( "Selected Text To..." );
					// GLOBAL.languageItems["manual"] = new IupString( "Manual" );
						GLOBAL.languageItems["manualpath"] = new IupString( "Manual Path" );
						GLOBAL.languageItems["manualusing"] = new IupString( "Search Help Manual" );
						GLOBAL.languageItems["name"] = new IupString( "Name" );
					
			GLOBAL.languageItems["language"] = new IupString( "Language" );
				GLOBAL.languageItems["openlanguage"] = new IupString( "Choose Language..." );
			GLOBAL.languageItems["about"] = new IupString( "About" );
			
			GLOBAL.languageItems["configuration"] = new IupString( "Configuration..." );
			GLOBAL.languageItems["setcustomoption"] = new IupString( "Set Custom Compiler Options..." );
			
		GLOBAL.languageItems["bookmark"] = new IupString( "Bookmark" );
		GLOBAL.languageItems["bookmarkprev"] = new IupString( "Previous Bookmark" );
		GLOBAL.languageItems["bookmarknext"] = new IupString( "Next Bookmark" );
		GLOBAL.languageItems["bookmarkclear"] = new IupString( "Clear Bookmark" );

		GLOBAL.languageItems["outline"] = new IupString( "Outline" );
			GLOBAL.languageItems["collapse"] = new IupString( "Collapse" );
			GLOBAL.languageItems["showpr"] = new IupString( "Change Outline Node Title" );
			GLOBAL.languageItems["showln"] = new IupString( "Show Line Number" );
			GLOBAL.languageItems["refresh"] = new IupString( "Refresh" );
			GLOBAL.languageItems["searchanyword"] = new IupString( "Search Word From Head" );
			GLOBAL.languageItems["hide"] = new IupString( "Hide" );
			GLOBAL.languageItems["hidesearch"] = new IupString( "Click To Show/Hide Search List" );

		GLOBAL.languageItems["dlgcolor"] = new IupString( "DLGCOLOR" );
		GLOBAL.languageItems["txtcolor"] = new IupString( "TXTCOLOR" );
		GLOBAL.languageItems["leftview"] = new IupString( "Left-View" );
		GLOBAL.languageItems["messageindicator"] = new IupString( "Message Indicator" );
		GLOBAL.languageItems["showtype"] = new IupString( "ShowType" );
		GLOBAL.languageItems["calltip"] = new IupString( "CallTip" );
		GLOBAL.languageItems["autocomplete"] = new IupString( "Autocomplete" );
		GLOBAL.languageItems["darkmode"] = new IupString( "DarkMode" );
		GLOBAL.languageItems["usedarkmode"] = new IupString( "Use DarkMode(if available)" );
		GLOBAL.languageItems["iconinvert"] = new IupString( "Icons Color Invert(Need Restart Poseidon)" );
		GLOBAL.languageItems["dialogopacity"] = new IupString( "Set Dialog Opacity" );
			GLOBAL.languageItems["fullpath"] = new IupString( "FullPath" );

		GLOBAL.languageItems["output"] = new IupString( "Output" );
			GLOBAL.languageItems["clear"] = new IupString( "Clear" );

		//'tab
		GLOBAL.languageItems["closeothers"] = new IupString( "Close Others" );
		GLOBAL.languageItems["closeright"] = new IupString( "Close Right" );
		GLOBAL.languageItems["torighttabs"] = new IupString( "Send To Secondary View" );
		GLOBAL.languageItems["tolefttabs"] = new IupString( "Send to Main View" );
		GLOBAL.languageItems["rotatetabs"] = new IupString( "Split Views Horizontally" );

		//'popup window
		GLOBAL.languageItems["highlightmaker"] = new IupString( "Highlight Maker..." );
		GLOBAL.languageItems["highlghtlines"] = new IupString( "Highlight Line(s)" );
		GLOBAL.languageItems["delhighlghtlines"] = new IupString( "Delete Highlight Line(s)" );
		GLOBAL.languageItems["colorhighlght"] = new IupString( "Select Color..." );
		GLOBAL.languageItems["delete"] = new IupString( "Delete" );
		GLOBAL.languageItems["showannotation"] = new IupString( "Show Annotation" );
		GLOBAL.languageItems["hideannotation"] = new IupString( "Hide Annotation" );
		GLOBAL.languageItems["removeannotation"] = new IupString( "Remove All Annotation" );
		GLOBAL.languageItems["expandall"] = new IupString( "Expand All" );
		GLOBAL.languageItems["contractall"] = new IupString( "Contract All" );

		//'properties
		GLOBAL.languageItems["prjproperties"] = new IupString( "Project Properties" );
		GLOBAL.languageItems["general"] = new IupString( "General" );
			GLOBAL.languageItems["prjname"] = new IupString( "Project Name" );
			GLOBAL.languageItems["prjtype"] = new IupString( "Type" );
				GLOBAL.languageItems["console"] = new IupString( "Console Application" );
				GLOBAL.languageItems["static"] = new IupString( "Static Library" );
				GLOBAL.languageItems["dynamic"] = new IupString( "Dynamic Link Library" );
			GLOBAL.languageItems["prjdir"] = new IupString( "Project Dir" );
			GLOBAL.languageItems["prjmainfile"] = new IupString( "Main file" );
			GLOBAL.languageItems["prjonefile"] = new IupString( "Pass One File To Compiler" );
			GLOBAL.languageItems["prjtarget"] = new IupString( "Target Name" );
			GLOBAL.languageItems["prjfocus"] = new IupString( "Focus" );
			GLOBAL.languageItems["prjargs"] = new IupString( "Execute Args:" );
			GLOBAL.languageItems["prjopts"] = new IupString( "Compile Opts:" );
			GLOBAL.languageItems["prjcompiler"] = new IupString( "Compiler Path" );
			GLOBAL.languageItems["nodirmessage"] = new IupString( "Without Project Dir!!" );
		GLOBAL.languageItems["include"] = new IupString( "Include..." );
			GLOBAL.languageItems["includepath"] = new IupString( "Include Paths" );
			GLOBAL.languageItems["librarypath"] = new IupString( "Libraries Paths" );
		
		// Search Window
		GLOBAL.languageItems["findwhat"] = new IupString( "Find What" );
		GLOBAL.languageItems["replacewith"] = new IupString( "Replace With" );
		GLOBAL.languageItems["direction"] = new IupString( "Direction" );
			GLOBAL.languageItems["forward"] = new IupString( "Forward" );
			GLOBAL.languageItems["backward"] = new IupString( "Backward" );
		GLOBAL.languageItems["scope"] = new IupString( "Scope" );
			GLOBAL.languageItems["all"] = new IupString( "All" );
			GLOBAL.languageItems["selection"] = new IupString( "Selection" );
		GLOBAL.languageItems["casesensitive"] = new IupString( "Case Sensitive" );
		GLOBAL.languageItems["wholeword"] = new IupString( "Whole Word" );
		GLOBAL.languageItems["find"] = new IupString( "Find" );
		GLOBAL.languageItems["findall"] = new IupString( "Find All" );
		GLOBAL.languageItems["replacefind"] = new IupString( "Find/Replace" );
		GLOBAL.languageItems["replace"] = new IupString( "Replace" );
		GLOBAL.languageItems["replaceall"] = new IupString( "Replace All" );
		GLOBAL.languageItems["countall"] = new IupString( "Count All" );
		GLOBAL.languageItems["bookmarkall"] = new IupString( "Mark All" );
		GLOBAL.languageItems["document"] = new IupString( "Document" );
		GLOBAL.languageItems["alldocument"] = new IupString( "All Document" );
		GLOBAL.languageItems["allproject"] = new IupString( "All Project" );
		GLOBAL.languageItems["status"] = new IupString( "Status Bar" );
		
		// shortcut
		GLOBAL.languageItems["shortcutname"] = new IupString( "ShortCut Name" );
		GLOBAL.languageItems["shortcutkey"] = new IupString( "Current ShortCut Keys" );
		
		// debug
		GLOBAL.languageItems["runcontinue"] = new IupString( "Run/Continue" );
		GLOBAL.languageItems["stop"] = new IupString( "Stop" );
		GLOBAL.languageItems["step"] = new IupString( "Step" );
		GLOBAL.languageItems["next"] = new IupString( "Next" );
		GLOBAL.languageItems["return"] = new IupString( "Return" );
		GLOBAL.languageItems["until"] = new IupString( "Until" );
		GLOBAL.languageItems["terminate"] = new IupString( "Terminate" );
		GLOBAL.languageItems["bp"] = new IupString( "Breakpoints" );
		GLOBAL.languageItems["variable"] = new IupString( "Variables" );
			GLOBAL.languageItems["watchlist"] = new IupString( "Watch List" );
				GLOBAL.languageItems["add"] = new IupString( "Add" );
				GLOBAL.languageItems["remove"] = new IupString( "Remove" );
				GLOBAL.languageItems["removeall"] = new IupString( "Remove All" );
			GLOBAL.languageItems["addtowatch"] = new IupString( "Add To Watchlist" );
			GLOBAL.languageItems["locals"] = new IupString( "Locals" );
			GLOBAL.languageItems["args"] = new IupString( "Arguments" );
			GLOBAL.languageItems["shared"] = new IupString( "Shared" );
			GLOBAL.languageItems["showvalue"] = new IupString( "Show Value *" );
			GLOBAL.languageItems["showaddress"] = new IupString( "Show Address @" );
		GLOBAL.languageItems["register"] = new IupString( "Registers" );
		GLOBAL.languageItems["disassemble"] = new IupString( "DisAssemble" );
		GLOBAL.languageItems["id"] = new IupString( "ID" );
		GLOBAL.languageItems["value"] = new IupString( "Value" );

		// caption
		GLOBAL.languageItems["caption_new"] = new IupString( "New" );
		GLOBAL.languageItems["caption_open"] = new IupString( "Open" );
		GLOBAL.languageItems["caption_saveas"] = new IupString( "Save As" );
		GLOBAL.languageItems["caption_cut"] = new IupString( "Cut" );
		GLOBAL.languageItems["caption_copy"] = new IupString( "Copy" );
		GLOBAL.languageItems["caption_paste"] = new IupString( "Paste" );
		GLOBAL.languageItems["caption_selectall"] = new IupString( "Select All" );
		GLOBAL.languageItems["caption_about"] = new IupString( "About" );
		GLOBAL.languageItems["caption_search"] = new IupString( "Search" );
		GLOBAL.languageItems["caption_prj"] = new IupString( "Project" );
		GLOBAL.languageItems["caption_openprj"] = new IupString( "Open Project" );
		GLOBAL.languageItems["caption_importprj"] = new IupString( "Import Fbedit Project" );
		GLOBAL.languageItems["caption_prjproperties"] = new IupString( "Project Properties" );
		GLOBAL.languageItems["caption_preference"] = new IupString( "Preference" );
		GLOBAL.languageItems["caption_argtitle"] = new IupString( "Compiler Options / EXE Arguments" );
		GLOBAL.languageItems["caption_debug"] = new IupString( "Debug" );
		GLOBAL.languageItems["caption_optionhelp"] = new IupString( "Compiler Options" );
		
		// message
		GLOBAL.languageItems["ok"] = new IupString( "OK" );
		GLOBAL.languageItems["yes"] = new IupString( "Yes" );
		GLOBAL.languageItems["no"] = new IupString( "No" );
		GLOBAL.languageItems["cancel"] = new IupString( "Cancel" );
		GLOBAL.languageItems["apply"] = new IupString( "Apply" );
		GLOBAL.languageItems["go"] = new IupString( "Go" );
		GLOBAL.languageItems["bechange"] = new IupString( "has been changed, save it now?" );
		GLOBAL.languageItems["samekey"] = new IupString( "The same key value with" );
		GLOBAL.languageItems["needrestart"] = new IupString( "Need Restart To Change Language" );
		GLOBAL.languageItems["suredelete"] = new IupString( "Are you sure to delete file?" );
		GLOBAL.languageItems["sureexit"] = new IupString( "Are you sure exit poseidon?" );
		GLOBAL.languageItems["opened"] = new IupString( "had already opened!" );
		GLOBAL.languageItems["existed"] = new IupString( "had already existed!" );
		GLOBAL.languageItems["wrongext"] = new IupString( "Wrong Ext Name!" );
		GLOBAL.languageItems["filelost"] = new IupString( "isn't existed!" );
		GLOBAL.languageItems[".poseidonbroken"] = new IupString( "Project setup file loading error!" );
		GLOBAL.languageItems[".poseidonlost"] = new IupString( "The directory has lost / no project setup file!" );
		GLOBAL.languageItems["continueimport"] = new IupString( "The directory has poseidon project setup file, continue import anyway?" );
		GLOBAL.languageItems["compilefailure"] = new IupString( "Compile Failure!" );
		GLOBAL.languageItems["compilewarning"] = new IupString( "Compile Done, But Got Warnings!" );
		GLOBAL.languageItems["compileok"] = new IupString( "Compile Success!" );
		GLOBAL.languageItems["cantundo"] = new IupString( "This action can't be undo! Continue anyway?" );
		GLOBAL.languageItems["exitdebug1"] = new IupString( "Exit debug right now?" );
		GLOBAL.languageItems["exitdebug2"] = new IupString( "No debugging symbols found!! Exit debug!" );
		GLOBAL.languageItems["applyfgcolor"] = new IupString( "Apply to other scintilla foreground color settings?" );
		GLOBAL.languageItems["applycolor"] = new IupString( "Apply to other scintilla background color settings?" );
		GLOBAL.languageItems["noselect"] = new IupString( "No Selected!!" );
		GLOBAL.languageItems["nodirandcreate"] = new IupString( "No This Dir!! Create New One?" );
		GLOBAL.languageItems["quest"] = new IupString( "Quest" );
		GLOBAL.languageItems["alarm"] = new IupString( "Alarm" );
		GLOBAL.languageItems["error"] = new IupString( "Error" );
		GLOBAL.languageItems["foundword"] = new IupString( "Found Word." );
		GLOBAL.languageItems["foundnothing"] = new IupString( "Found Nothing!" );
		GLOBAL.languageItems["pluginrunningunload"] = new IupString( "Plugin Is Running, Unload The Plugin?" );
		GLOBAL.languageItems["onlytools"] = new IupString( "Only Support 12 Tools!" );
		GLOBAL.languageItems["createnewone"] = new IupString( "Create new one?" );
		GLOBAL.languageItems["applythisone"] = new IupString( "Apply This One?" );

		GLOBAL.languageItems["exefile"] = new IupString( "Execute Files" );
		version(FBIDE)
		{
			GLOBAL.languageItems["basfile"] = new IupString( "freeBASIC Sources" );
			GLOBAL.languageItems["bifile"] = new IupString( "freeBASIC Includes" );
		}
		version(DIDE)
		{
			GLOBAL.languageItems["basfile"] = new IupString( "D Sources" );
			GLOBAL.languageItems["bifile"] = new IupString( "D Includes" );
		}
		GLOBAL.languageItems["supportfile"] = new IupString( "All Supported Files" );
		GLOBAL.languageItems["lngfile"] = new IupString( "Language Files" );
		GLOBAL.languageItems["chmfile"] = new IupString( "Microsoft Compiled HTML Help" );
		GLOBAL.languageItems["allfile"] = new IupString( "All Files" );
		GLOBAL.languageItems["fbeditfile"] = new IupString( "FbEdit Projects" );
	}	
}