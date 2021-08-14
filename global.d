module global;

import tools;

import iup.iup;

/*
typedef extern (C) void function( Ihandle* iih ) _HandleClipboardText;
_HandleClipboardText dllHandleClipboardText;
*/

version(Windows)
{	
	// For chm help
	import tango.sys.win32.Types;
	typedef extern(C) HWND function( HWND, LPCWSTR, UINT, DWORD_PTR) _htmlHelp;
	//typedef extern(C) int function( HWND, LPCSTR, LPSTR, DWORD ) _SevenZip;
}

struct EditorToggleUint
{
	char[] LineMargin = "ON", FixedLineMargin = "ON", BookmarkMargin = "ON", FoldMargin = "ON", IndentGuide = "ON", CaretLine = "ON", WordWrap = "OFF", TabUseingSpace = "OFF", AutoIndent = "ON", ShowEOL = "OFF", ShowSpace = "OFF", AutoEnd = "OFF", AutoClose = "OFF", DocStatus = "OFF", LoadAtBackThread = "OFF", AutoKBLayout = "OFF";
	char[] TabWidth = "4", ColumnEdge = "0", EolType = "0", ControlCharSymbol = "32", ColorOutline = "OFF", BoldKeyword = "OFF", BraceMatchHighlight = "ON", MultiSelection = "OFF", LoadPrevDoc = "OFF", HighlightCurrentWord = "OFF", MiddleScroll = "OFF", GUI = "OFF", Bit64 = "OFF", QBCase = "OFF", NewDocBOM = "ON", SaveAllModified = "OFF";
}

struct EditorLayoutSize
{
	char[] USEFULLSCREEN = "OFF", PLACEMENT = "MAXIMIZED", RASTERSIZE = "700x500", ExplorerSplit = "170", MessageSplit = "800", FileListSplit = "1000", OutlineWindow = "ON", MessageWindow = "ON", FilelistWindow = "ON", RotateTabs = "OFF", BarSize = "2";
	char[] EXTRAASCENT = "0", EXTRADESCENT = "0";
}

struct EditorColorUint
{
	IupString[6]	keyWord;
	IupString		caretLine, cursor, selectionFore, selectionBack, linenumFore, linenumBack, fold, bookmark, selAlpha, errorFore, errorBack, warningFore, warringBack, currentWord, currentWordAlpha;
	IupString		scintillaFore, scintillaBack, braceFore, braceBack, SCE_B_COMMENT_Fore, SCE_B_COMMENT_Back, SCE_B_NUMBER_Fore, SCE_B_NUMBER_Back, SCE_B_STRING_Fore, SCE_B_STRING_Back;
	IupString		SCE_B_PREPROCESSOR_Fore, SCE_B_PREPROCESSOR_Back, SCE_B_OPERATOR_Fore, SCE_B_OPERATOR_Back;
	IupString		SCE_B_IDENTIFIER_Fore, SCE_B_IDENTIFIER_Back, SCE_B_COMMENTBLOCK_Fore, SCE_B_COMMENTBLOCK_Back;
	IupString		projectFore, projectBack, outlineFore, outlineBack, filelistFore, filelistBack, outputFore, outputBack, searchFore, searchBack, prjTitle, prjSourceType;
	IupString[4]	maker;
	IupString		callTip_Fore, callTip_Back, callTip_HLT, showType_Fore, showType_Back, showType_HLT;
	IupString		functionTitle;
	IupString		project_HLT, outline_HLT;
}

struct ShortKey
{
	char[] 	name, title;
	int		keyValue;
}

struct fontUint
{
	char[] 	name;
	char[]	fontString;
}

struct CustomTool
{
	IupString	name, dir, args;
}

struct EditorOpacity
{
	char[]	searchDlg = "255", findfilesDlg = "255", preferenceDlg = "255", projectDlg = "255", gotoDlg = "255", newfileDlg = "255";
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

	import tango.stdc.stringz;

	import navcache;
	import scintilla, project, layouts.toolbar, layouts.projectPanel, layouts.filelistPanel, layouts.outlinePanel, layouts.messagePanel, layouts.statusBar, layouts.debugger;
	import dialogs.searchDlg, dialogs.findFilesDlg, dialogs.helpDlg, dialogs.argOptionDlg, dialogs.preferenceDlg;
	import parser.ast, parser.scanner, parser.parser;
	
	public:
	version(Windows) 	static _htmlHelp		htmlHelp;
	
	static CPLUGIN[char[]]		pluginMnager;
	
	//static float				IUP_VERSION;
	
	static Ihandle*				mainDlg;
	static Ihandle*				documentTabs, documentTabs_Sub, projectViewTabs, messageWindowTabs;
	static Ihandle*				dndDocumentZBox;
	
	static Ihandle*				activeDocumentTabs;
	static Ihandle*				dragDocumentTabs;
	//static char[]				activeSubTabsDirection = "VERTICAL"; // HORIZONTAL, VERTICAL
	
	static int					tabDocumentPos = -1;	

	// LAYOUT
	static Ihandle* 			documentSplit;
	static int					documentSplit_value = 500;
	static Ihandle* 			documentSplit2;
	static int					documentSplit2_value = 500;
	

	static Ihandle* 			fileListSplit;
	static int					fileListSplit_value = 700;
	
	static Ihandle* 			explorerWindow;
	static Ihandle* 			explorerSplit; // which split explorerWindow & editWindow
	static int					explorerSplit_value = 300;

	static CToolBar	 			toolbar;

	static CProjectTree			projectTree;
	static COutline 			outlineTree;
	static CFileList 			fileListTree;
	
	
	//static Ihandle* 			outputPanel;
	//static Ihandle* 			searchOutputPanel;
	static CMessageAndSearch	messagePanel;
	
	static CDebugger 			debugPanel;
	static Ihandle* 			messageSplit; // which split (explorerWindow + editWindow ) & messageWindow
	static int					messageSplit_value = 800;

	static CPreferenceDialog	preferenceDlg;
	//static CSearchDialog		searchDlg;
	static CSearchExpander		searchExpander;
	static CFindInFilesDialog	serachInFilesDlg;
	static CCompilerHelpDialog	compilerHelpDlg;

	static Ihandle*				scrollICONHandle, scrollTimer;

	static CStatusBar			statusBar;

	static Ihandle*				menuOutlineWindow, menuMessageWindow, menuFistlistWindow,menuRotateTabs;
	
	

	// Setting
	version(Windows)	static char[][char[]]	EnvironmentVars;
	
	static char[]				poseidonPath;			// Include Tail /
	static char[]				linuxHome;
	static IupString[6]			KEYWORDS;
	static int					keywordCase = 0;	
	static char[]				compilerFullPath, x64compilerFullPath;
	static char[]				debuggerFullPath, x64debuggerFullPath;
	static char[]				linuxTermName;	
	static char[]				compilerAnootation = "ON";
	static char[]				compilerWindow = "OFF";
	static char[]				compilerSFX = "ON";
	static char[]				delExistExe = "ON";
	static char[]				consoleExe = "OFF";
	static char[]				toggleCompileAtBackThread = "OFF";
	//static IupString			debuggerFullPath, x64debuggerFullPath;
	//static IupString			linuxTermName;	
	static char[][]				manuals;
	//static IupString			colorTemplate;
	//static char[]				maxError = "30";
	//static IupString			defaultOption;
	static char[]				recentOpenDir;
	static char[][]				recentOptions, recentArgs, recentCompilers, prevPrj, prevDoc;
	static int					maxRecentOptions = 15, maxRecentArgs = 15, maxRecentCompilers = 8;
	static IupString[]			recentFiles, recentProjects;
	static EditorToggleUint		editorSetting00;
	static EditorLayoutSize		editorSetting01;
	static EditorOpacity		editorSetting02;
	static EditorColorUint		editColor;
	static char[][]				properties;
	//static Ihandle*			functionTitleHandle;
	static char[]				extraParsableExt = "inc";
	static char[]				enableKeywordComplete = "ON";
	static char[]				enableIncludeComplete = "ON";
	static char[]				enableParser = "ON";
	static char[]				showFunctionTitle = "OFF";
	static char[]				showTypeWithParams = "OFF";
	static char[]				toggleIgnoreCase = "ON";		// SCI_AUTOCSETIGNORECASE
	static char[]				toggleCaseInsensitive = "ON";	// SCI_AUTOCSETCASEINSENSITIVEBEHAVIOUR
	static char[]				toggleShowListType = "OFF";
	static char[]				toggleShowAllMember = "ON";
	static char[]				toggleEnableDwell = "OFF";
	static char[]				toggleOverWrite = "OFF";
	static char[]				toggleCompleteAtBackThread = "ON";
	
	static char[]				toggleUseManual = "OFF", toggleDummy = "ON";
	
	static char[]				dwellDelay = "1000";
	static char[]				triggerDelay = "100";
	static int					autoCMaxHeight = 12;
	static int					indicatorStyle = 16;
	

	static CScintilla[char[]]	scintillaManager;
	static int[][char[]]		fileStatusManager;

	static CASTnode[char[]]		parserManager;
	

	static int					autoCompletionTriggerWordCount = 3;
	static int					includeLevel = 2;
	static int					liveLevel = 0;
	static char[]				toggleUpdateOutlineLive = "OFF";

	//Parser
	static Scanner				scanner;
	static CParser				Parser;



	static PROJECT[char[]]		projectManager;
	static char[]				activeProjectPath;
	static char[]				activeFilePath;
	
	static char[]				language;
	static IupString[char[]]	languageItems;


	static IupString			cString;
	
	static ShortKey[]			shortKeys;

	static fontUint[]			fonts;
	
	//static char[][]				stackGotoDefinition;

	static bool					bKeyUp = true;
	static int					KeyNumber;
	
	static CustomTool[13]		customTools;
	
	static char[][]				customCompilerOptions;
	static IupString			currentCustomCompilerOption, noneCustomCompilerOption;

	static CASTnode				objectDefaultParser;
	version(DIDE)
	{
		static char[][]			defaultImportPaths;
		static char[]			toggleSkipUnittest = "ON";
	}
	
	static CNavCache			navigation;
	
	static Monitor[]			monitors;
	static Monitor				consoleWindow;

	static this()
	{
		// Init EditorColorUint
		GLOBAL.editColor.keyWord[0] = new IupString( cast(char[]) "5 91 35" );
		GLOBAL.editColor.keyWord[1] = new IupString( cast(char[]) "0 0 255" );
		GLOBAL.editColor.keyWord[2] = new IupString( cast(char[]) "231 144 0" );
		GLOBAL.editColor.keyWord[3] = new IupString( cast(char[]) "16 108 232" );
		GLOBAL.editColor.keyWord[4] = new IupString( cast(char[]) "255 0 0" );
		GLOBAL.editColor.keyWord[5] = new IupString( cast(char[]) "0 255 0" );
		
		
		GLOBAL.editColor.maker[0] = new IupString( cast(char[]) "200 255 200" );
		GLOBAL.editColor.maker[1] = new IupString( cast(char[]) "255 200 255" );
		GLOBAL.editColor.maker[2] = new IupString( cast(char[]) "200 255 255" );
		GLOBAL.editColor.maker[3] = new IupString( cast(char[]) "255 200 200" );		
		
		GLOBAL.editColor.caretLine = new IupString( cast(char[]) "255 255 128" );
		GLOBAL.editColor.cursor = new IupString( cast(char[]) "0 0 0" );
		GLOBAL.editColor.selectionFore = new IupString( cast(char[]) "255 255 255" );
		GLOBAL.editColor.selectionBack = new IupString( cast(char[]) "0 0 255" );
		GLOBAL.editColor.linenumFore = new IupString( cast(char[]) "0 0 0" );
		GLOBAL.editColor.linenumBack = new IupString( cast(char[]) "200 200 200" );
		GLOBAL.editColor.fold = new IupString( cast(char[]) "238 238 238" );
		GLOBAL.editColor.bookmark = new IupString( cast(char[]) "238 238 238" );
		GLOBAL.editColor.selAlpha = new IupString( cast(char[]) "255" );
		GLOBAL.editColor.errorFore = new IupString( cast(char[]) "102 69 3" );
		GLOBAL.editColor.errorBack = new IupString( cast(char[]) "255 200 227" );
		GLOBAL.editColor.warningFore = new IupString( cast(char[]) "0 0 255" );
		GLOBAL.editColor.warringBack = new IupString( cast(char[]) "255 255 157" );
		GLOBAL.editColor.currentWord = new IupString( cast(char[]) "0 128 0" );
		GLOBAL.editColor.currentWordAlpha = new IupString( cast(char[]) "80" );
		
		GLOBAL.editColor.braceFore = new IupString( cast(char[]) "255 0 0" );
		GLOBAL.editColor.braceBack = new IupString( cast(char[]) "0 255 0" );
		
		GLOBAL.editColor.scintillaFore = new IupString( cast(char[]) "0 0 0" );
		GLOBAL.editColor.scintillaBack = new IupString( cast(char[]) "255 255 255" );
		GLOBAL.editColor.SCE_B_COMMENT_Fore = new IupString( cast(char[]) "0 128 0" );
		GLOBAL.editColor.SCE_B_COMMENT_Back = new IupString( cast(char[]) "255 255 255" );

		GLOBAL.editColor.SCE_B_NUMBER_Fore = new IupString( cast(char[]) "128 128 64" );
		GLOBAL.editColor.SCE_B_NUMBER_Back = new IupString( cast(char[]) "255 255 255" );
		GLOBAL.editColor.SCE_B_STRING_Fore = new IupString( cast(char[]) "128 0 0" );
		GLOBAL.editColor.SCE_B_STRING_Back = new IupString( cast(char[]) "255 255 255" );

		GLOBAL.editColor.SCE_B_PREPROCESSOR_Fore = new IupString( cast(char[]) "0 0 255" );
		GLOBAL.editColor.SCE_B_PREPROCESSOR_Back = new IupString( cast(char[]) "255 255 255" );
		GLOBAL.editColor.SCE_B_OPERATOR_Fore = new IupString( cast(char[]) "160 20 20" );
		GLOBAL.editColor.SCE_B_OPERATOR_Back = new IupString( cast(char[]) "255 255 255" );

		GLOBAL.editColor.SCE_B_IDENTIFIER_Fore = new IupString( cast(char[]) "0 0 0" );
		GLOBAL.editColor.SCE_B_IDENTIFIER_Back = new IupString( cast(char[]) "255 255 255" );
		GLOBAL.editColor.SCE_B_COMMENTBLOCK_Fore = new IupString( cast(char[]) "0 128 0" );
		GLOBAL.editColor.SCE_B_COMMENTBLOCK_Back = new IupString( cast(char[]) "255 255 255" );

		GLOBAL.editColor.projectFore = new IupString( cast(char[]) "0 0 0" );
		GLOBAL.editColor.projectBack = new IupString( cast(char[]) "255 255 255" );
		GLOBAL.editColor.outlineFore = new IupString( cast(char[]) "0 0 0" );
		GLOBAL.editColor.outlineBack = new IupString( cast(char[]) "255 255 255" );
		GLOBAL.editColor.filelistFore = new IupString( cast(char[]) "0 0 0" );
		GLOBAL.editColor.filelistBack = new IupString( cast(char[]) "255 255 255" );
		GLOBAL.editColor.outputFore = new IupString( cast(char[]) "0 0 0" );
		GLOBAL.editColor.outputBack = new IupString( cast(char[]) "255 255 255" );
		GLOBAL.editColor.searchFore = new IupString( cast(char[]) "0 0 0" );
		GLOBAL.editColor.searchBack = new IupString( cast(char[]) "255 255 255" );

		GLOBAL.editColor.prjTitle = new IupString( cast(char[]) "128 0 0" );
		GLOBAL.editColor.prjSourceType = new IupString( cast(char[]) "0 0 255" );
		
		GLOBAL.editColor.callTip_Fore = new IupString( cast(char[]) "0 0 255" );
		GLOBAL.editColor.callTip_Back = new IupString( cast(char[]) "234 248 192" );
		GLOBAL.editColor.callTip_HLT = new IupString( cast(char[]) "202 0 0" );

		GLOBAL.editColor.showType_Fore = new IupString( cast(char[]) "0xff0000" );
		GLOBAL.editColor.showType_Back = new IupString( cast(char[]) "0xaaffff" );
		GLOBAL.editColor.showType_HLT = new IupString( cast(char[]) "0x008000" );
		
		GLOBAL.editColor.functionTitle = new IupString( cast(char[]) "0 0 0" );
		
		GLOBAL.editColor.project_HLT = new IupString;
		GLOBAL.editColor.outline_HLT = new IupString;
		
		/*
		GLOBAL.debuggerFullPath = new IupString();
		GLOBAL.x64debuggerFullPath = new IupString();
		GLOBAL.linuxTermName = new IupString();
		*/
		//GLOBAL.colorTemplate = new IupString();
		//GLOBAL.defaultOption = new IupString();
		
		GLOBAL.currentCustomCompilerOption = new IupString( cast(char*) "" );
		GLOBAL.noneCustomCompilerOption = new IupString( cast(char*) "None Custom Compile Option" );
		
		GLOBAL.cString = new IupString;
		GLOBAL.Parser = new CParser;
		
		version(FBIDE)
		{
			GLOBAL.KEYWORDS[0] = new IupString( cast(char[]) "__date__ __date_iso__ __fb_64bit__ __fb_argc__ __fb_argv__ __fb_arm__ __fb_asm__ __fb_backend__ __fb_bigendian__ __fb_build_date__ __fb_cygwin__ __fb_darwin__ __fb_debug__ __fb_dos__ __fb_err__ __fb_fpmode__ __fb_fpu__ __fb_freebsd__ __fb_gcc__ __fb_lang__ __fb_linux__ __fb_main__ __fb_min_version__ __fb_mt__ __fb_netbsd__ __fb_openbsd__ __fb_option_byval__ __fb_option_dynamic__ __fb_option_escape__ __fb_option_explicit__ __fb_option_gosub__ __fb_option_private__ __fb_out_dll__ __fb_out_exe__ __fb_out_lib__ __fb_out_obj__ __fb_pcos__ __fb_signature__ __fb_sse__ __fb_unix__ __fb_vectorize__ __fb_ver_major__ __fb_ver_minor__ __fb_ver_patch__ __fb_version__ __fb_win32__ __fb_xbox__ __file__ __file_nq__ __function__ __function_nq__ __line__ __path__ __time__ #assert #define #else #elseif #endif #endmacro #error #if #ifdef #ifndef #inclib #include #lang #libpath #line #macro #pragma #print #undef $dynamic $include $static $lang  abs abstract access acos add alias allocate alpha and andalso any append as assert assertwarn asc asin asm atan2 atn base beep bin binary bit bitreset bitset bload bsave byref byte byval call callocate case cast cbyte cdbl cdecl chain chdir" );
			GLOBAL.KEYWORDS[1] = new IupString( cast(char[]) "chr cint circle class clear clng clngint close cls color command common condbroadcast condcreate conddestroy condsignal condwait const constructor continue cos cptr cshort csign csng csrlin cubyte cuint culng culngint cunsg curdir cushort custom cvd cvi cvl cvlongint cvs cvshort data date dateadd datediff datepart dateserial datevalue day deallocate declare defbyte defdbl defined defint deflng deflongint defshort defsng defstr defubyte defuint defulongint defushort delete destructor dim dir do double draw dylibfree dylibload dylibsymbol else elseif encoding end enum environ eof eqv erase erfn erl ermn err error event exec exepath exit exp export extends extern field fileattr filecopy filedatetime fileexists filelen fix flip for format frac fre freefile function get getjoystick getkey getmouse gosub goto hex hibyte hiword" );
			GLOBAL.KEYWORDS[2] = new IupString( cast(char[]) "hour if iif imageconvertrow imagecreate imagedestroy imageinfo imp implements import inkey inp input instr instrrev int integer is isdate isredirected kill lbound lcase left len let lib line lobyte loc local locate lock lof log long longint loop loword lpos lprint lset ltrim mid minute mkd mkdir mki mkl mklongint mks mkshort mod month monthname multikey mutexcreate mutexdestroy mutexlock mutexunlock naked name namespace next new not now object oct offsetof on once open operator option or orelse out output overload override paint palette pascal pcopy peek pmap point pointcoord pointer poke pos preserve preset print private procptr property protected pset ptr public put random randomize read reallocate redim rem reset restore resume return rgb rgba right rmdir" );
			GLOBAL.KEYWORDS[3] = new IupString( cast(char[]) "rnd rset rtrim run sadd scope screen screencopy screencontrol screenevent screeninfo screenglproc screenlist screenlock screenptr screenres screenset screensync screenunlock second seek select setdate setenviron setmouse settime sgn shared shell shl shr short sin single sizeof sleep space spc sqr static stdcall step stick stop str strig string strptr sub swap system tab tan then this threadcall threadcreate threaddetach threadwait time timeserial timevalue timer to trans trim type typeof ubound ubyte ucase uinteger ulong ulongint union unlock unsigned until ushort using va_arg va_first va_next val vallng valint valuint valulng var varptr view virtual wait wbin wchr weekday weekdayname wend while whex width window windowtitle winput with woct write wspace wstr wstring xor year zstring" );
			GLOBAL.KEYWORDS[4] = new IupString( cast(char[]) "" );
			GLOBAL.KEYWORDS[5] = new IupString( cast(char[]) "" );
		}
		version(DIDE)
		{
			GLOBAL.KEYWORDS[0] = new IupString( cast(char[]) "abstract alias align asm assert auto body bool break byte case cast catch cdouble cent cfloat char class const continue creal dchar debug default delegate delete deprecated do double" );
			GLOBAL.KEYWORDS[1] = new IupString( cast(char[]) "else enum export extern false final finally float for foreach foreach_reverse function goto idouble if ifloat immutable import in inout int interface invariant ireal is lazy long macro mixin module" );
			GLOBAL.KEYWORDS[2] = new IupString( cast(char[]) "new nothrow null out override package pragma private protected public pure real ref return scope shared short static struct super switch synchronized template this throw true try typedef typeid typeof" );
			GLOBAL.KEYWORDS[3] = new IupString( cast(char[]) "ubyte ucent uint ulong union unittest ushort version void volatile wchar while with __FILE__ __FILE_FULL_PATH__ __MODULE__ __LINE__ __FUNCTION__ __PRETTY_FUNCTION__ __gshared __traits __vector __parameters" );
			GLOBAL.KEYWORDS[4] = new IupString( cast(char[]) "" );
			GLOBAL.KEYWORDS[5] = new IupString( cast(char[]) "" );
		}

		for( int i = 0; i < 13; ++i )
		{
			GLOBAL.customTools[i].name = new IupString();
			GLOBAL.customTools[i].dir = new IupString();
			GLOBAL.customTools[i].args = new IupString();
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
		ShortKey sk12 = { "findprev", "Find Previous", 536936419 };
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
		
		ShortKey sk29 = { "outlinewindow", "On/Off Left-side Window", 65480 };
		GLOBAL.shortKeys ~= sk29;
		ShortKey sk30 = { "messagewindow", "On/Off Bottom-side Window", 65481 };
		GLOBAL.shortKeys ~= sk30;

		ShortKey sk31 = { "customtool1", "Custom Tool(1)", 805371838 };
		GLOBAL.shortKeys ~= sk31;
		ShortKey sk32 = { "customtool2", "Custom Tool(2)", 805371839 };
		GLOBAL.shortKeys ~= sk32;
		ShortKey sk33 = { "customtool3", "Custom Tool(3)", 805371840 };
		GLOBAL.shortKeys ~= sk33;
		ShortKey sk34 = { "customtool4", "Custom Tool(4)", 805371841 };
		GLOBAL.shortKeys ~= sk34;
		ShortKey sk35 = { "customtool5", "Custom Tool(5)", 805371842 };
		GLOBAL.shortKeys ~= sk35;
		ShortKey sk36 = { "customtool6", "Custom Tool(6)", 805371843 };
		GLOBAL.shortKeys ~= sk36;
		ShortKey sk37 = { "customtool7", "Custom Tool(7)", 805371844 };
		GLOBAL.shortKeys ~= sk37;
		ShortKey sk38 = { "customtool8", "Custom Tool(8)", 805371845 };
		GLOBAL.shortKeys ~= sk38;
		ShortKey sk39 = { "customtool9", "Custom Tool(9)", 805371846 };		
		GLOBAL.shortKeys ~= sk39;
		ShortKey sk40 = { "customtool10", "Custom Tool(10)", 805371847 };		
		GLOBAL.shortKeys ~= sk40;
		ShortKey sk41 = { "customtool11", "Custom Tool(11)", 805371848 };		
		GLOBAL.shortKeys ~= sk41;
		ShortKey sk42 = { "customtool12", "Custom Tool(12)", 805371849 };		
		GLOBAL.shortKeys ~= sk42;


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
		
		
		
		GLOBAL.languageItems["file"] = new IupString( cast(char[]) "File" );
			GLOBAL.languageItems["new"] = new IupString( cast(char[]) "New" );
			GLOBAL.languageItems["open"] = new IupString( cast(char[]) "Open" );
			GLOBAL.languageItems["save"] = new IupString( cast(char[]) "Save" );
			GLOBAL.languageItems["saveas"] = new IupString( cast(char[]) "Save As" );
			GLOBAL.languageItems["savetabs"] = new IupString( cast(char[]) "Save Tab Files" );
			GLOBAL.languageItems["saveall"] = new IupString( cast(char[]) "Save All" );
			GLOBAL.languageItems["close"] = new IupString( cast(char[]) "Close" );
			GLOBAL.languageItems["closeall"] = new IupString( cast(char[]) "Close All" );
			GLOBAL.languageItems["closealltabs"] = new IupString( cast(char[]) "Close All Tabs" );
			GLOBAL.languageItems["recentfiles"] = new IupString( cast(char[]) "Recent Files" );
			GLOBAL.languageItems["recentprjs"] = new IupString( cast(char[]) "Recent Projects" );
			GLOBAL.languageItems["clearall"] = new IupString( cast(char[]) "Clear All" );
			GLOBAL.languageItems["exit"] = new IupString( cast(char[]) "Exit" );
			
		GLOBAL.languageItems["edit"] = new IupString( cast(char[]) "Edit" );
			GLOBAL.languageItems["redo"] = new IupString( cast(char[]) "Redo" );
			GLOBAL.languageItems["undo"] = new IupString( cast(char[]) "Undo" );
			GLOBAL.languageItems["cut"] = new IupString( cast(char[]) "Cut" );
			GLOBAL.languageItems["copy"] = new IupString( cast(char[]) "Copy" );
			GLOBAL.languageItems["paste"] = new IupString( cast(char[]) "Paste" );
			GLOBAL.languageItems["commentline"] = new IupString( cast(char[]) "Comment Line" );
			GLOBAL.languageItems["uncommentline"] = new IupString( cast(char[]) "UnComment Line" );
			GLOBAL.languageItems["selectall"] = new IupString( cast(char[]) "Select All" );
			GLOBAL.languageItems["selectmulti"] = new IupString( cast(char[]) "Multi-Select By Word" );
			
		GLOBAL.languageItems["search"] = new IupString( cast(char[]) "Search" );
			GLOBAL.languageItems["findreplace"] = new IupString( cast(char[]) "Find/Replace" );
			GLOBAL.languageItems["findnext"] = new IupString( cast(char[]) "Find Next" );
			GLOBAL.languageItems["findprev"] = new IupString( cast(char[]) "Find Previous" );
			GLOBAL.languageItems["findreplacefiles"] = new IupString( cast(char[]) "Find/Replace In Files" );
			GLOBAL.languageItems["goto"] = new IupString( cast(char[]) "Goto Line" );
				GLOBAL.languageItems["line"] = new IupString( cast(char[]) "Line" );

		GLOBAL.languageItems["windows"] = new IupString( cast(char[]) "Windows" );
		GLOBAL.languageItems["view"] = new IupString( cast(char[]) "View" );
			//GLOBAL.languageItems["outline"] = new IupString( cast(char[]) "Outline" );
			GLOBAL.languageItems["message"]= new IupString( cast(char[]) "Message" );
			GLOBAL.languageItems["manual"]= new IupString( cast(char[]) "Manual" );
			GLOBAL.languageItems["fullscreen"]= new IupString( cast(char[]) "Fullscreen" );
			
		GLOBAL.languageItems["prj"] = new IupString( cast(char[]) "Project" );
			GLOBAL.languageItems["newprj"] = new IupString( cast(char[]) "New Project" );
			GLOBAL.languageItems["openprj"] = new IupString( cast(char[]) "Open Project" );
			GLOBAL.languageItems["importprj"] = new IupString( cast(char[]) "Import Fbedit Project" );
			GLOBAL.languageItems["saveprj"] = new IupString( cast(char[]) "Save Project" );
			GLOBAL.languageItems["saveallprj"] = new IupString( cast(char[]) "Save All Projects" );
			GLOBAL.languageItems["closeprj"] = new IupString( cast(char[]) "Close Project" );
			GLOBAL.languageItems["closeallprj"] = new IupString( cast(char[]) "Close All Projects" );
			GLOBAL.languageItems["properties"] = new IupString( cast(char[]) "Properties..." );
			
			GLOBAL.languageItems["importall"] = new IupString( cast(char[]) "Import All Files" );
			GLOBAL.languageItems["openinexplorer"] = new IupString( cast(char[]) "Open In Explorer" );
			GLOBAL.languageItems["removefromprj"] = new IupString( cast(char[]) "Remove From Project" );
			GLOBAL.languageItems["openinposeidon"] = new IupString( cast(char[]) "Open In Poseidon" );
			GLOBAL.languageItems["rename"] = new IupString( cast(char[]) "Rename File" );
			GLOBAL.languageItems["setmainmodule"] = new IupString( cast(char[]) "Set As Main Module" );
			GLOBAL.languageItems["newfile"] = new IupString( cast(char[]) "New File" );
				GLOBAL.languageItems["filename"] = new IupString( cast(char[]) "File Name" );
			GLOBAL.languageItems["newfolder"] = new IupString( cast(char[]) "New Folder" );
				GLOBAL.languageItems["foldername"] = new IupString( cast(char[]) "Folder Name" );
			GLOBAL.languageItems["addfile"] = new IupString( cast(char[]) "Add file(s)" );
		
		GLOBAL.languageItems["build"] = new IupString( cast(char[]) "Build" );
			GLOBAL.languageItems["compile"] = new IupString( cast(char[]) "Compile File" );
			GLOBAL.languageItems["compilerun"]= new IupString( cast(char[]) "Compile File And Run" );
			GLOBAL.languageItems["run"] = new IupString( cast(char[]) "Run" );
			GLOBAL.languageItems["buildprj"] = new IupString( cast(char[]) "Build Project" );
			GLOBAL.languageItems["rebuildprj"] = new IupString( cast(char[]) "ReBuild Project" );
			GLOBAL.languageItems["quickrun"] = new IupString( cast(char[]) "Quick Run" );
			
		GLOBAL.languageItems["debug"] = new IupString( cast(char[]) "Debug" );
			GLOBAL.languageItems["rundebug"] = new IupString( cast(char[]) "Run Debug" );
			GLOBAL.languageItems["compiledebug"] = new IupString( cast(char[]) "Compile With Debug" );
			GLOBAL.languageItems["builddebug"] = new IupString( cast(char[]) "Build Project With Debug" );
			
		GLOBAL.languageItems["options"] = new IupString( cast(char[]) "Options" );
			GLOBAL.languageItems["tools"] = new IupString( cast(char[]) "Tools" );
				GLOBAL.languageItems["unload"] = new IupString( cast(char[]) "Unload" );
				GLOBAL.languageItems["pluginstatus"] = new IupString( cast(char[]) "Plugin Status" );
				GLOBAL.languageItems["seteol"] = new IupString( cast(char[]) "Set Eol Character" );
				GLOBAL.languageItems["converteol"] = new IupString( cast(char[]) "Convert Eol Character" );
				GLOBAL.languageItems["convertencoding"] = new IupString( cast(char[]) "Convert Encoding" );
				GLOBAL.languageItems["convertcase"] = new IupString( cast(char[]) "Convert Keyword Case" );
					GLOBAL.languageItems["uppercase"] = new IupString( cast(char[]) "UPPERCASE" );
					GLOBAL.languageItems["lowercase"] = new IupString( cast(char[]) "lowercase" );
					GLOBAL.languageItems["mixercase"] = new IupString( cast(char[]) "Mixedcase" );
				GLOBAL.languageItems["setcustomtool"] = new IupString( cast(char[]) "Set Custom Tools..." );
					GLOBAL.languageItems["customtool1"] = new IupString( cast(char[]) "Custom Tool(1)" );
					GLOBAL.languageItems["customtool2"] = new IupString( cast(char[]) "Custom Tool(2)" );
					GLOBAL.languageItems["customtool3"] = new IupString( cast(char[]) "Custom Tool(3)" );
					GLOBAL.languageItems["customtool4"] = new IupString( cast(char[]) "Custom Tool(4)" );
					GLOBAL.languageItems["customtool5"] = new IupString( cast(char[]) "Custom Tool(5)" );
					GLOBAL.languageItems["customtool6"] = new IupString( cast(char[]) "Custom Tool(6)" );
					GLOBAL.languageItems["customtool7"] = new IupString( cast(char[]) "Custom Tool(7)" );
					GLOBAL.languageItems["customtool8"] = new IupString( cast(char[]) "Custom Tool(8)" );
					GLOBAL.languageItems["customtool9"] = new IupString( cast(char[]) "Custom Tool(9)" );
					GLOBAL.languageItems["customtool10"] = new IupString( cast(char[]) "Custom Tool(10)" );
					GLOBAL.languageItems["customtool11"] = new IupString( cast(char[]) "Custom Tool(11)" );
					GLOBAL.languageItems["customtool12"] = new IupString( cast(char[]) "Custom Tool(12)" );
				
			GLOBAL.languageItems["preference"] = new IupString( cast(char[]) "Preference" );
				GLOBAL.languageItems["compiler"] = new IupString( cast(char[]) "Compiler" );
					GLOBAL.languageItems["compilerpath"] = new IupString( cast(char[]) "Compiler Path" );
					GLOBAL.languageItems["debugpath"] = new IupString( cast(char[]) "Debugger Path" );
					GLOBAL.languageItems["debugx64path"] = new IupString( cast(char[]) "Debugger x64 Path" );
					GLOBAL.languageItems["terminalpath"] = new IupString( cast(char[]) "Terminal Path" );
					GLOBAL.languageItems["x64path"] = new IupString( cast(char[]) "x64 Path" );
					GLOBAL.languageItems["compileropts"] = new IupString( cast(char[]) "Compiler Opts" );
					GLOBAL.languageItems["compilersetting"] = new IupString( cast(char[]) "Compiler Setting" );
						GLOBAL.languageItems["errorannotation"] = new IupString( cast(char[]) "Show Compiler Errors/Warnings Using Annotation" );
						GLOBAL.languageItems["showresultwindow"] = new IupString( cast(char[]) "Show Compiled Result Window" );
						GLOBAL.languageItems["usesfx"] = new IupString( cast(char[]) "Play Result SFX( When Result Window is OFF )" );
						GLOBAL.languageItems["delexistexe"] = new IupString( cast(char[]) "Before Compile, Delete Existed Execute File" );
						GLOBAL.languageItems["consoleexe"] = new IupString( cast(char[]) "Use Console Launcher To Run Program" );
						GLOBAL.languageItems["compileatbackthread"] = new IupString( cast(char[]) "Enable Compile At Back Thread" );
				GLOBAL.languageItems["parser"] = new IupString( cast(char[]) "Parser" );
					GLOBAL.languageItems["parsersetting"] = new IupString( cast(char[]) "Parser Settings" );
						GLOBAL.languageItems["enablekeyword"] = new IupString( cast(char[]) "Enable Keyword Autocomplete" );
						GLOBAL.languageItems["enableinclude"] = new IupString( cast(char[]) "Enable Include Autocomplete" );
						GLOBAL.languageItems["enableparser"] = new IupString( cast(char[]) "Enable Parser" );
						GLOBAL.languageItems["showtitle"] = new IupString( cast(char[]) "Show Function Title" );
						GLOBAL.languageItems["width"] = new IupString( cast(char[]) "Width" );
						GLOBAL.languageItems["showtypeparam"] = new IupString( cast(char[]) "Show Type With Function Parameters" );
						GLOBAL.languageItems["sortignorecase"] = new IupString( cast(char[]) "Autocomplete List Is Ignore Case" );
						GLOBAL.languageItems["selectcase"] = new IupString( cast(char[]) "Selection Of Autocomplete List Is Case Insensitive" );
						GLOBAL.languageItems["showlisttype"] = new IupString( cast(char[]) "Show Autocomplete List Type" );
						GLOBAL.languageItems["showallmembers"] = new IupString( cast(char[]) "Show All Members( public, protected, private )" );
						GLOBAL.languageItems["enabledwell"] = new IupString( cast(char[]) "Enable Mouse Dwell to Show Type" );
							GLOBAL.languageItems["dwelldelay"] = new IupString( cast(char[]) "Dwell Delay(ms):" );
						GLOBAL.languageItems["enableoverwrite"] = new IupString( cast(char[]) "Overwrite To Non Identifier Character" );
						GLOBAL.languageItems["completeatbackthread"] = new IupString( cast(char[]) "Enable Codecomplete At Back Thread" );
							GLOBAL.languageItems["completedelay"] = new IupString( cast(char[]) "Trigger Delay(ms):" );
						GLOBAL.languageItems["parserlive"] = new IupString( cast(char[]) "ParseLive! Level" );
							GLOBAL.languageItems["none"] = new IupString( cast(char[]) "None" );
							GLOBAL.languageItems["light"] = new IupString( cast(char[]) "Light" );
							GLOBAL.languageItems["full"] = new IupString( cast(char[]) "Full" );
							GLOBAL.languageItems["update"] = new IupString( cast(char[]) "Update Outline" );
						GLOBAL.languageItems["trigger"] = new IupString( cast(char[]) "Autocompletion Trigger" );
							GLOBAL.languageItems["triggertip"] = new IupString( cast(char[]) "Set 0 To Disable" );
							GLOBAL.languageItems["codecompletiononoff"] = new IupString( cast(char[]) "Code Completion On/Off" );
						GLOBAL.languageItems["includelevel"] = new IupString( cast(char[]) "Include Levels" );
							GLOBAL.languageItems["includeleveltip"] = new IupString( cast(char[]) "Set -1 To Unlimited" );
						GLOBAL.languageItems["autocmaxheight"] = new IupString( cast(char[]) "Max Complete List Items" );
					GLOBAL.languageItems["editor"] = new IupString( cast(char[]) "Editor" );
						GLOBAL.languageItems["lnmargin"] = new IupString( cast(char[]) "Show Linenumber Margin" );
						GLOBAL.languageItems["fixedlnmargin"] = new IupString( cast(char[]) "Fixed Linenumber Margin Size" );
						GLOBAL.languageItems["bkmargin"] = new IupString( cast(char[]) "Show Bookmark Margin" );
						GLOBAL.languageItems["fdmargin"] = new IupString( cast(char[]) "Show Folding Margin" );
						GLOBAL.languageItems["indentguide"] = new IupString( cast(char[]) "Show Indentation Guide" );
						GLOBAL.languageItems["showcaretline"] = new IupString( cast(char[]) "Highlight Caret Line" );
						GLOBAL.languageItems["wordwarp"] = new IupString( cast(char[]) "Word Wrap" );
						GLOBAL.languageItems["tabtospace"] = new IupString( cast(char[]) "Replace Tab With Space" );
						GLOBAL.languageItems["autoindent"] = new IupString( cast(char[]) "Automatic Indent" );
						GLOBAL.languageItems["showeol"] = new IupString( cast(char[]) "Show EOL Sign" );
						GLOBAL.languageItems["showspacetab"] = new IupString( cast(char[]) "Show Space/Tab" );
						GLOBAL.languageItems["autoinsertend"] = new IupString( cast(char[]) "Auto Insert Block End" );
						GLOBAL.languageItems["autoclose"] = new IupString( cast(char[]) "Auto Close( quotes... )" );
						GLOBAL.languageItems["coloroutline"] = new IupString( cast(char[]) "Colorize Outline Item" );
						GLOBAL.languageItems["showidemessage"] = new IupString( cast(char[]) "Show IDE Message" );
						GLOBAL.languageItems["boldkeyword"] = new IupString( cast(char[]) "Bold Keywords" );
						GLOBAL.languageItems["bracematchhighlight"] = new IupString( cast(char[]) "Show Brace Match Highlight" );
						GLOBAL.languageItems["bracematchdoubleside"] = new IupString( cast(char[]) "Use Double-Side Brace Match" );
						GLOBAL.languageItems["multiselection"] = new IupString( cast(char[]) "Enable Document Multi Selection" );
						GLOBAL.languageItems["loadprevdoc"] = new IupString( cast(char[]) "Load Previous Documents" );
						GLOBAL.languageItems["middlescroll"] = new IupString( cast(char[]) "Middle Button Scroll" );
						GLOBAL.languageItems["savedocstatus"] = new IupString( cast(char[]) "Save Document Status" );
						GLOBAL.languageItems["loadfileatbackthread"] = new IupString( cast(char[]) "Load File(s) AT Back Thread" );
						GLOBAL.languageItems["autokblayout"] = new IupString( cast(char[]) "Auto en-Keyboard Layout" );
						GLOBAL.languageItems["controlcharsymbol"] = new IupString( cast(char[]) "Set Control Char Symbol" );
						GLOBAL.languageItems["tabwidth"] = new IupString( cast(char[]) "Tab Width" );
						GLOBAL.languageItems["columnedge"] = new IupString( cast(char[]) "Column Edge" );
						GLOBAL.languageItems["barsize"] = new IupString( cast(char[]) "Bar Size" );
							GLOBAL.languageItems["barsizetip"] = new IupString( cast(char[]) "Need Restart Poseidon (2~5)" );
						GLOBAL.languageItems["maker0"] = new IupString( cast(char[]) "Maker0" );
						GLOBAL.languageItems["maker1"] = new IupString( cast(char[]) "Maker1" );
						GLOBAL.languageItems["maker2"] = new IupString( cast(char[]) "Maker2" );
						GLOBAL.languageItems["maker3"] = new IupString( cast(char[]) "Maker3" );
						GLOBAL.languageItems["autoconvertkeyword"] = new IupString( cast(char[]) "Auto Convert Keyword Case" );
						GLOBAL.languageItems["qbcase"] = new IupString( cast(char[]) "Use QB-IDE Convert Case" );
						GLOBAL.languageItems["newdocbom"] = new IupString( cast(char[]) "Create New Doc With BOM" );
						GLOBAL.languageItems["saveallmodified"] = new IupString( cast(char[]) "Save All Documents Before Compile" );
						GLOBAL.languageItems["font"] = new IupString( cast(char[]) "Font" );
							GLOBAL.languageItems["default"] = new IupString( cast(char[]) "Default" );
							//GLOBAL.languageItems["document"] = new IupString( cast(char[]) "Document" );
							GLOBAL.languageItems["leftside"] = new IupString( cast(char[]) "Leftside" );
							//'fistlist=FileList
							//'project=Project
							//'outline=Outline
							GLOBAL.languageItems["bottom"] = new IupString( cast(char[]) "Bottom" );
							//'output=Output
							//'search=Search
							//'debug=Debug
							GLOBAL.languageItems["annotation"] = new IupString( cast(char[]) "Annotation" );
							GLOBAL.languageItems["statusbar"] = new IupString( cast(char[]) "StatusBar" );
							GLOBAL.languageItems["item"] = new IupString( cast(char[]) "Item" );
							GLOBAL.languageItems["face"] = new IupString( cast(char[]) "Face" );
							GLOBAL.languageItems["style"] = new IupString( cast(char[]) "Style" );
							GLOBAL.languageItems["size"] = new IupString( cast(char[]) "Size" );
						GLOBAL.languageItems["color"] = new IupString( cast(char[]) "Color" );
							GLOBAL.languageItems["colorfile"] = new IupString( cast(char[]) "Color Template" );
							GLOBAL.languageItems["caretline"] = new IupString( cast(char[]) "Caret Line" );
							GLOBAL.languageItems["cursor"] = new IupString( cast(char[]) "Cursor" );
							GLOBAL.languageItems["prjtitle"] = new IupString( cast(char[]) "Project Title" );
							GLOBAL.languageItems["sourcefolder"] = new IupString( cast(char[]) "Source Folder" );
							GLOBAL.languageItems["sel"] = new IupString( cast(char[]) "Selection" );
							GLOBAL.languageItems["ln"] = new IupString( cast(char[]) "Linenumber" );
							GLOBAL.languageItems["foldcolor"] = new IupString( cast(char[]) "FoldingMargin Color" );
							GLOBAL.languageItems["selalpha"] = new IupString( cast(char[]) "Selection Alpha" );
								GLOBAL.languageItems["alphatip"] = new IupString( cast(char[]) "Set 255 To Use Fore/BackColor\nSet 0 To Keep ForeColor" );
							GLOBAL.languageItems["hlcurrentword"] = new IupString( cast(char[]) "Highlight Current Word" );								
							GLOBAL.languageItems["hlcurrentwordalpha"] = new IupString( cast(char[]) "Indicator Alpha" );
							
						GLOBAL.languageItems["colorfgbg"] = new IupString( cast(char[]) "Color/Foreground/Background" );
							GLOBAL.languageItems["bracehighlight"] = new IupString( cast(char[]) "Brace Highlight" );
							GLOBAL.languageItems["manualerrorannotation"] = new IupString( cast(char[]) "Error Annotation" );
							GLOBAL.languageItems["manualwarningannotation"] = new IupString( cast(char[]) "Warning Annotation" );
							GLOBAL.languageItems["scintilla"] = new IupString( cast(char[]) "Scintilla" );
							GLOBAL.languageItems["SCE_B_COMMENT"] = new IupString( cast(char[]) "SCE_B_COMMENT" );
							GLOBAL.languageItems["SCE_B_NUMBER"] = new IupString( cast(char[]) "SCE_B_NUMBER" );
							GLOBAL.languageItems["SCE_B_STRING"] = new IupString( cast(char[]) "SCE_B_STRING" );
							GLOBAL.languageItems["SCE_B_PREPROCESSOR"] = new IupString( cast(char[]) "SCE_B_PREPROCESSOR" );
							GLOBAL.languageItems["SCE_B_OPERATOR"] = new IupString( cast(char[]) "SCE_B_OPERATOR" );
							GLOBAL.languageItems["SCE_B_IDENTIFIER"] = new IupString( cast(char[]) "SCE_B_IDENTIFIER" );
							GLOBAL.languageItems["SCE_B_COMMENTBLOCK"] = new IupString( cast(char[]) "SCE_B_COMMENTBLOCK" );
								
					GLOBAL.languageItems["shortcut"] = new IupString( cast(char[]) "Short Cut" );
						GLOBAL.languageItems["sc_findreplace"] = new IupString( cast(char[]) "Find/Replace" );
						GLOBAL.languageItems["sc_findreplacefiles"] = new IupString( cast(char[]) "Find/Replace In Files" );
						GLOBAL.languageItems["sc_findnext"] = new IupString( cast(char[]) "Find Next" );
						GLOBAL.languageItems["sc_findprev"] = new IupString( cast(char[]) "Find Previous" );
						GLOBAL.languageItems["sc_dupdown"] = new IupString( cast(char[]) "Duplication Line Down" );
						GLOBAL.languageItems["sc_dupup"] = new IupString( cast(char[]) "Duplication Line Up" );
						GLOBAL.languageItems["sc_delline"] = new IupString( cast(char[]) "Delete Line" );
						GLOBAL.languageItems["sc_goto"] = new IupString( cast(char[]) "Goto Line" );
						GLOBAL.languageItems["sc_undo"] = new IupString( cast(char[]) "Undo" );
						GLOBAL.languageItems["sc_redo"] = new IupString( cast(char[]) "Redo" );
						GLOBAL.languageItems["sc_gotodef"] = new IupString( cast(char[]) "Goto Definition" );
						version(FBIDE)	GLOBAL.languageItems["sc_procedure"] = new IupString( cast(char[]) "Goto Member Procedure" );
						version(DIDE)	GLOBAL.languageItems["sc_procedure"] = new IupString( cast(char[]) "Goto Top Definition" );
						GLOBAL.languageItems["sc_quickrun"] = new IupString( cast(char[]) "Quick Run" );
						GLOBAL.languageItems["sc_run"] = new IupString( cast(char[]) "Run" );
						GLOBAL.languageItems["sc_compile"] = new IupString( cast(char[]) "Compile" );
						GLOBAL.languageItems["sc_build"] = new IupString( cast(char[]) "Build Project" );
						GLOBAL.languageItems["sc_leftwindow"] = new IupString( cast(char[]) "On/Off Left Window" );
						GLOBAL.languageItems["sc_bottomwindow"] = new IupString( cast(char[]) "On/Off Bottom Window" );
						GLOBAL.languageItems["sc_showtype"] = new IupString( cast(char[]) "Show Type" );
						GLOBAL.languageItems["sc_reparse"] = new IupString( cast(char[]) "Reparse" );
						GLOBAL.languageItems["sc_save"] = new IupString( cast(char[]) "Save File" );
						GLOBAL.languageItems["sc_saveall"] = new IupString( cast(char[]) "Save All" );
						GLOBAL.languageItems["sc_close"] = new IupString( cast(char[]) "Close File" );
						GLOBAL.languageItems["sc_nexttab"] = new IupString( cast(char[]) "Next Tab" );
						GLOBAL.languageItems["sc_prevtab"] = new IupString( cast(char[]) "Previous Tab" );
						GLOBAL.languageItems["sc_newtab"] = new IupString( cast(char[]) "New Tab" );
						GLOBAL.languageItems["sc_autocomplete"] = new IupString( cast(char[]) "Auto Complete" );
						GLOBAL.languageItems["sc_compilerun"] = new IupString( cast(char[]) "Compile File And Run" );
						GLOBAL.languageItems["sc_comment"] = new IupString( cast(char[]) "Comment" );
						GLOBAL.languageItems["sc_uncomment"] = new IupString( cast(char[]) "UnComment" );
						GLOBAL.languageItems["sc_backnav"] = new IupString( cast(char[]) "Backward Navigation" );
						GLOBAL.languageItems["sc_forwardnav"] = new IupString( cast(char[]) "Forward Navigation" );
						GLOBAL.languageItems["sc_backdefinition"] = new IupString( cast(char[]) "Back Definition" );
						
					GLOBAL.languageItems["keywords"] = new IupString( cast(char[]) "Keywords" );
						GLOBAL.languageItems["keyword0"] = new IupString( cast(char[]) "Keyword0" );
						GLOBAL.languageItems["keyword1"] = new IupString( cast(char[]) "Keyword1" );
						GLOBAL.languageItems["keyword2"] = new IupString( cast(char[]) "Keyword2" );
						GLOBAL.languageItems["keyword3"] = new IupString( cast(char[]) "Keyword3" );
						GLOBAL.languageItems["keyword4"] = new IupString( cast(char[]) "Keyword4" );
						GLOBAL.languageItems["keyword5"] = new IupString( cast(char[]) "Keyword5" );
						GLOBAL.languageItems["setkeyword"] = new IupString( cast(char[]) "Selected Text To..." );
					// GLOBAL.languageItems["manual"] = new IupString( cast(char[]) "Manual" );
						GLOBAL.languageItems["manualpath"] = new IupString( cast(char[]) "Manual Path" );
						GLOBAL.languageItems["manualusing"] = new IupString( cast(char[]) "Search Help Manual" );
						GLOBAL.languageItems["name"] = new IupString( cast(char[]) "Name" );
					
			GLOBAL.languageItems["language"] = new IupString( cast(char[]) "Language" );
				GLOBAL.languageItems["openlanguage"] = new IupString( cast(char[]) "Choose Language..." );
			GLOBAL.languageItems["about"] = new IupString( cast(char[]) "About" );
			
			GLOBAL.languageItems["configuration"] = new IupString( cast(char[]) "Configuration..." );
			GLOBAL.languageItems["setcustomoption"] = new IupString( cast(char[]) "Set Custom Compiler Options..." );
			
		GLOBAL.languageItems["bookmark"] = new IupString( cast(char[]) "Bookmark" );
		GLOBAL.languageItems["bookmarkprev"] = new IupString( cast(char[]) "Previous Bookmark" );
		GLOBAL.languageItems["bookmarknext"] = new IupString( cast(char[]) "Next Bookmark" );
		GLOBAL.languageItems["bookmarkclear"] = new IupString( cast(char[]) "Clear Bookmark" );

		GLOBAL.languageItems["outline"] = new IupString( cast(char[]) "Outline" );
			GLOBAL.languageItems["collapse"] = new IupString( cast(char[]) "Collapse" );
			GLOBAL.languageItems["showpr"] = new IupString( cast(char[]) "Change Outline Node Title" );
			GLOBAL.languageItems["showln"] = new IupString( cast(char[]) "Show Line Number" );
			GLOBAL.languageItems["refresh"] = new IupString( cast(char[]) "Refresh" );
			GLOBAL.languageItems["searchanyword"] = new IupString( cast(char[]) "Search Word From Head" );
			GLOBAL.languageItems["hide"] = new IupString( cast(char[]) "Hide" );

		GLOBAL.languageItems["filelist"] = new IupString( cast(char[]) "FileList" );
			GLOBAL.languageItems["fullpath"] = new IupString( cast(char[]) "FullPath" );

		GLOBAL.languageItems["output"] = new IupString( cast(char[]) "Output" );
			GLOBAL.languageItems["clear"] = new IupString( cast(char[]) "Clear" );

		//'tab
		GLOBAL.languageItems["closeothers"] = new IupString( cast(char[]) "Close Others" );
		GLOBAL.languageItems["closeright"] = new IupString( cast(char[]) "Close Right" );
		GLOBAL.languageItems["torighttabs"] = new IupString( cast(char[]) "Send To Secondary View" );
		GLOBAL.languageItems["tolefttabs"] = new IupString( cast(char[]) "Send to Main View" );
		GLOBAL.languageItems["rotatetabs"] = new IupString( cast(char[]) "Split Views Horizontally" );

		//'popup window
		GLOBAL.languageItems["highlightmaker"] = new IupString( cast(char[]) "Highlight Maker..." );
		GLOBAL.languageItems["highlghtlines"] = new IupString( cast(char[]) "Highlight Line(s)" );
		GLOBAL.languageItems["delhighlghtlines"] = new IupString( cast(char[]) "Delete Highlight Line(s)" );
		GLOBAL.languageItems["colorhighlght"] = new IupString( cast(char[]) "Select Color..." );
		GLOBAL.languageItems["delete"] = new IupString( cast(char[]) "Delete" );
		GLOBAL.languageItems["showannotation"] = new IupString( cast(char[]) "Show Annotation" );
		GLOBAL.languageItems["hideannotation"] = new IupString( cast(char[]) "Hide Annotation" );
		GLOBAL.languageItems["removeannotation"] = new IupString( cast(char[]) "Remove All Annotation" );
		GLOBAL.languageItems["expandall"] = new IupString( cast(char[]) "Expand All" );
		GLOBAL.languageItems["contractall"] = new IupString( cast(char[]) "Contract All" );

		//'properties
		GLOBAL.languageItems["prjproperties"] = new IupString( cast(char[]) "Project Properties" );
		GLOBAL.languageItems["general"] = new IupString( cast(char[]) "General" );
			GLOBAL.languageItems["prjname"] = new IupString( cast(char[]) "Project Name" );
			GLOBAL.languageItems["prjtype"] = new IupString( cast(char[]) "Type" );
				GLOBAL.languageItems["console"] = new IupString( cast(char[]) "Console Application" );
				GLOBAL.languageItems["static"] = new IupString( cast(char[]) "Static Library" );
				GLOBAL.languageItems["dynamic"] = new IupString( cast(char[]) "Dynamic Link Library" );
			GLOBAL.languageItems["prjdir"] = new IupString( cast(char[]) "Project Dir" );
			GLOBAL.languageItems["prjmainfile"] = new IupString( cast(char[]) "Main file" );
			GLOBAL.languageItems["prjonefile"] = new IupString( cast(char[]) "Pass One File To Compiler" );
			GLOBAL.languageItems["prjtarget"] = new IupString( cast(char[]) "Target Name" );
			GLOBAL.languageItems["prjfocus"] = new IupString( cast(char[]) "Focus" );
			GLOBAL.languageItems["prjargs"] = new IupString( cast(char[]) "Execute Args:" );
			GLOBAL.languageItems["prjopts"] = new IupString( cast(char[]) "Compile Opts:" );
			GLOBAL.languageItems["prjcomment"] = new IupString( cast(char[]) "Comment" );
			GLOBAL.languageItems["prjcompiler"] = new IupString( cast(char[]) "Compiler Path" );
			GLOBAL.languageItems["nodirmessage"] = new IupString( cast(char[]) "Without Project Dir!!" );
		GLOBAL.languageItems["include"] = new IupString( cast(char[]) "Include..." );
			GLOBAL.languageItems["includepath"] = new IupString( cast(char[]) "Include Paths" );
			GLOBAL.languageItems["librarypath"] = new IupString( cast(char[]) "Libraries Paths" );
		
		// Search Window
		GLOBAL.languageItems["findwhat"] = new IupString( cast(char[]) "Find What" );
		GLOBAL.languageItems["replacewith"] = new IupString( cast(char[]) "Replace With" );
		GLOBAL.languageItems["direction"] = new IupString( cast(char[]) "Direction" );
			GLOBAL.languageItems["forward"] = new IupString( cast(char[]) "Forward" );
			GLOBAL.languageItems["backward"] = new IupString( cast(char[]) "Backward" );
		GLOBAL.languageItems["scope"] = new IupString( cast(char[]) "Scope" );
			GLOBAL.languageItems["all"] = new IupString( cast(char[]) "All" );
			GLOBAL.languageItems["selection"] = new IupString( cast(char[]) "Selection" );
		GLOBAL.languageItems["casesensitive"] = new IupString( cast(char[]) "Case Sensitive" );
		GLOBAL.languageItems["wholeword"] = new IupString( cast(char[]) "Whole Word" );
		GLOBAL.languageItems["find"] = new IupString( cast(char[]) "Find" );
		GLOBAL.languageItems["findall"] = new IupString( cast(char[]) "Find All" );
		GLOBAL.languageItems["replacefind"] = new IupString( cast(char[]) "Find/Replace" );
		GLOBAL.languageItems["replace"] = new IupString( cast(char[]) "Replace" );
		GLOBAL.languageItems["replaceall"] = new IupString( cast(char[]) "Replace All" );
		GLOBAL.languageItems["countall"] = new IupString( cast(char[]) "Count All" );
		GLOBAL.languageItems["bookmarkall"] = new IupString( cast(char[]) "Mark All" );
		GLOBAL.languageItems["document"] = new IupString( cast(char[]) "Document" );
		GLOBAL.languageItems["alldocument"] = new IupString( cast(char[]) "All Document" );
		GLOBAL.languageItems["allproject"] = new IupString( cast(char[]) "All Project" );
		GLOBAL.languageItems["status"] = new IupString( cast(char[]) "Status Bar" );
		
		// shortcut
		GLOBAL.languageItems["shortcutname"] = new IupString( cast(char[]) "ShortCut Name" );
		GLOBAL.languageItems["shortcutkey"] = new IupString( cast(char[]) "Current ShortCut Keys" );
		
		// debug
		GLOBAL.languageItems["runcontinue"] = new IupString( cast(char[]) "Run/Continue" );
		GLOBAL.languageItems["stop"] = new IupString( cast(char[]) "Stop" );
		GLOBAL.languageItems["step"] = new IupString( cast(char[]) "Step" );
		GLOBAL.languageItems["next"] = new IupString( cast(char[]) "Next" );
		GLOBAL.languageItems["return"] = new IupString( cast(char[]) "Return" );
		GLOBAL.languageItems["until"] = new IupString( cast(char[]) "Until" );
		GLOBAL.languageItems["terminate"] = new IupString( cast(char[]) "Terminate" );
		GLOBAL.languageItems["bp"] = new IupString( cast(char[]) "Breakpoints" );
		GLOBAL.languageItems["variable"] = new IupString( cast(char[]) "Variables" );
			GLOBAL.languageItems["watchlist"] = new IupString( cast(char[]) "Watch List" );
				GLOBAL.languageItems["add"] = new IupString( cast(char[]) "Add" );
				GLOBAL.languageItems["remove"] = new IupString( cast(char[]) "Remove" );
				GLOBAL.languageItems["removeall"] = new IupString( cast(char[]) "Remove All" );
			GLOBAL.languageItems["addtowatch"] = new IupString( cast(char[]) "Add To Watchlist" );
			GLOBAL.languageItems["locals"] = new IupString( cast(char[]) "Locals" );
			GLOBAL.languageItems["args"] = new IupString( cast(char[]) "Arguments" );
			GLOBAL.languageItems["shared"] = new IupString( cast(char[]) "Shared" );
			GLOBAL.languageItems["showvalue"] = new IupString( cast(char[]) "Show Value *" );
			GLOBAL.languageItems["showaddress"] = new IupString( cast(char[]) "Show Address @" );
		GLOBAL.languageItems["register"] = new IupString( cast(char[]) "Registers" );
		GLOBAL.languageItems["disassemble"] = new IupString( cast(char[]) "DisAssemble" );
		GLOBAL.languageItems["id"] = new IupString( cast(char[]) "ID" );
		GLOBAL.languageItems["value"] = new IupString( cast(char[]) "Value" );

		// caption
		GLOBAL.languageItems["caption_new"] = new IupString( cast(char[]) "New" );
		GLOBAL.languageItems["caption_open"] = new IupString( cast(char[]) "Open" );
		GLOBAL.languageItems["caption_saveas"] = new IupString( cast(char[]) "Save As" );
		GLOBAL.languageItems["caption_cut"] = new IupString( cast(char[]) "Cut" );
		GLOBAL.languageItems["caption_copy"] = new IupString( cast(char[]) "Copy" );
		GLOBAL.languageItems["caption_paste"] = new IupString( cast(char[]) "Paste" );
		GLOBAL.languageItems["caption_selectall"] = new IupString( cast(char[]) "Select All" );
		GLOBAL.languageItems["caption_about"] = new IupString( cast(char[]) "About" );
		//GLOBAL.languageItems["caption_findreplace"] = new IupString( cast(char[]) "Find / Replace" );
		//GLOBAL.languageItems["caption_findreplacefiles"] = new IupString( cast(char[]) "Find / Replace In Files" );
		//GLOBAL.languageItems["caption_goto"] = new IupString( cast(char[]) "Goto Line" );
		GLOBAL.languageItems["caption_search"] = new IupString( cast(char[]) "Search" );
		GLOBAL.languageItems["caption_prj"] = new IupString( cast(char[]) "Project" );
		GLOBAL.languageItems["caption_openprj"] = new IupString( cast(char[]) "Open Project" );
		GLOBAL.languageItems["caption_importprj"] = new IupString( cast(char[]) "Import Fbedit Project" );
		GLOBAL.languageItems["caption_prjproperties"] = new IupString( cast(char[]) "Project Properties" );
		GLOBAL.languageItems["caption_preference"] = new IupString( cast(char[]) "Preference" );
		GLOBAL.languageItems["caption_argtitle"] = new IupString( cast(char[]) "Compiler Options / EXE Arguments" );
		GLOBAL.languageItems["caption_debug"] = new IupString( cast(char[]) "Debug" );
		GLOBAL.languageItems["caption_optionhelp"] = new IupString( cast(char[]) "Compiler Options" );
		
		// message
		GLOBAL.languageItems["ok"] = new IupString( cast(char[]) "OK" );
		GLOBAL.languageItems["yes"] = new IupString( cast(char[]) "Yes" );
		GLOBAL.languageItems["no"] = new IupString( cast(char[]) "No" );
		GLOBAL.languageItems["cancel"] = new IupString( cast(char[]) "Cancel" );
		GLOBAL.languageItems["apply"] = new IupString( cast(char[]) "Apply" );
		GLOBAL.languageItems["go"] = new IupString( cast(char[]) "Go" );
		GLOBAL.languageItems["bechange"] = new IupString( cast(char[]) "has been changed, save it now?" );
		GLOBAL.languageItems["samekey"] = new IupString( cast(char[]) "The same key value with" );
		GLOBAL.languageItems["needrestart"] = new IupString( cast(char[]) "Need Restart To Change Language" );
		GLOBAL.languageItems["suredelete"] = new IupString( cast(char[]) "Are you sure to delete file?" );
		GLOBAL.languageItems["sureexit"] = new IupString( cast(char[]) "Are you sure exit poseidon?" );
		GLOBAL.languageItems["opened"] = new IupString( cast(char[]) "had already opened!" );
		GLOBAL.languageItems["existed"] = new IupString( cast(char[]) "had already existed!" );
		GLOBAL.languageItems["wrongext"] = new IupString( cast(char[]) "Wrong Ext Name!" );
		GLOBAL.languageItems["filelost"] = new IupString( cast(char[]) "isn't existed!" );
		GLOBAL.languageItems[".poseidonbroken"] = new IupString( cast(char[]) "Project setup file loading error!" );
		GLOBAL.languageItems[".poseidonlost"] = new IupString( cast(char[]) "The directory has lost / no project setup file!" );
		GLOBAL.languageItems["continueimport"] = new IupString( cast(char[]) "The directory has poseidon project setup file, continue import anyway?" );
		GLOBAL.languageItems["compilefailure"] = new IupString( cast(char[]) "Compile Failure!" );
		GLOBAL.languageItems["compilewarning"] = new IupString( cast(char[]) "Compile Done, But Got Warnings!" );
		GLOBAL.languageItems["compileok"] = new IupString( cast(char[]) "Compile Success!" );
		GLOBAL.languageItems["cantundo"] = new IupString( cast(char[]) "This action can't be undo! Continue anyway?" );
		GLOBAL.languageItems["exitdebug1"] = new IupString( cast(char[]) "Exit debug right now?" );
		GLOBAL.languageItems["exitdebug2"] = new IupString( cast(char[]) "No debugging symbols found!! Exit debug!" );
		GLOBAL.languageItems["applycolor"] = new IupString( cast(char[]) "Apply to other scintilla background color settings?" );
		GLOBAL.languageItems["noselect"] = new IupString( cast(char[]) "No Selected!!" );
		GLOBAL.languageItems["nodirandcreate"] = new IupString( cast(char[]) "No This Dir!! Create New One?" );
		GLOBAL.languageItems["quest"] = new IupString( cast(char[]) "Quest" );
		GLOBAL.languageItems["alarm"] = new IupString( cast(char[]) "Alarm" );
		GLOBAL.languageItems["error"] = new IupString( cast(char[]) "Error" );
		GLOBAL.languageItems["foundword"] = new IupString( cast(char[]) "Found Word." );
		GLOBAL.languageItems["foundnothing"] = new IupString( cast(char[]) "Found Nothing!" );
		GLOBAL.languageItems["pluginrunningunload"] = new IupString( cast(char[]) "Plugin Is Running, Unload The Plugin?" );
		GLOBAL.languageItems["onlytools"] = new IupString( cast(char[]) "Only Support 12 Tools!" );
		GLOBAL.languageItems["createnewone"] = new IupString( cast(char[]) "Create new one?" );

		GLOBAL.languageItems["exefile"] = new IupString( cast(char[]) "Execute Files" );
		version(FBIDE)
		{
			GLOBAL.languageItems["basfile"] = new IupString( cast(char[]) "freeBASIC Sources" );
			GLOBAL.languageItems["bifile"] = new IupString( cast(char[]) "freeBASIC Includes" );
		}
		version(DIDE)
		{
			GLOBAL.languageItems["basfile"] = new IupString( cast(char[]) "D Sources" );
			GLOBAL.languageItems["bifile"] = new IupString( cast(char[]) "D Includes" );
		}
		GLOBAL.languageItems["supportfile"] = new IupString( cast(char[]) "All Supported Files" );
		GLOBAL.languageItems["lngfile"] = new IupString( cast(char[]) "Language Files" );
		GLOBAL.languageItems["chmfile"] = new IupString( cast(char[]) "Microsoft Compiled HTML Help" );
		GLOBAL.languageItems["allfile"] = new IupString( cast(char[]) "All Files" );
		GLOBAL.languageItems["fbeditfile"] = new IupString( cast(char[]) "FbEdit Projects" );
	}	
}