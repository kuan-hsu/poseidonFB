module global;

struct EditorToggleUint
{
	char[] LineMargin = "ON", BookmarkMargin = "ON", FoldMargin = "ON", IndentGuide = "ON", CaretLine = "ON", WordWrap = "OFF", TabUseingSpace = "OFF", AutoIndent = "ON", ShowEOL = "OFF", ShowSpace = "OFF", AutoEnd = "OFF";
	char[] TabWidth = "4", ColumnEdge = "0", EolType = "0", ColorOutline = "OFF";
}

struct EditorColorUint
{
	char[][4] keyWord = [ "5 91 35", "0 0 255", "231 144 20", "16 108 232" ];
	char[] caretLine = "255 255 128", cursor = "0 0 0", selectionFore = "255 255 255", selectionBack = "0 0 255", linenumFore = "0 0 0", linenumBack = "200 200 200", fold = "200 208 208", selAlpha = "255";
}

struct ShortKey
{
	char[] 	name;
	int		keyValue;
}

struct fontUint
{
	char[] 	name;
	char[]	fontString;
}


struct GLOBAL
{
	private:
	import iup.iup;
	import iup.iup_scintilla;

	import tango.stdc.stringz;
	import tango.io.UnicodeFile;

	import tools;
	import scintilla, project, layouts.toolbar, layouts.projectPanel, layouts.filelistPanel, layouts.outlinePanel, layouts.debugger;
	import dialogs.searchDlg, dialogs.findFilesDlg, dialogs.helpDlg, dialogs.argOptionDlg;
	import parser.ast, parser.scanner, parser.parser;
	

	public:
	static Ihandle*				mainDlg;
	static Ihandle*				documentTabs, projectViewTabs, messageWindowTabs;
	static Ihandle*				dndDocumentZBox;

	// LAYOUT
	static Ihandle* 			fileListSplit;
	
	static Ihandle* 			explorerWindow;
	static Ihandle* 			explorerSplit; // which split explorerWindow & editWindow
	static int					explorerSplit_value = 300;

	static CToolBar	 			toolbar;

	static CProjectTree			projectTree;
	static COutline 			outlineTree;
	static CFileList 			fileListTree;
	
	
	static Ihandle* 			outputPanel;
	static Ihandle* 			searchOutputPanel;
	static CDebugger 			debugPanel;
	static Ihandle* 			messageSplit; // which split (explorerWindow + editWindow ) & messageWindow
	static int					messageSplit_value = 800;

	static CSearchDialog		searchDlg;
	static CFindInFilesDialog	serachInFilesDlg;
	static CCompilerHelpDialog	compilerHelpDlg;
	static CArgOptionDialog		argsDlg;

	static Ihandle*				statusBar_Line_Col, statusBar_Ins, statusBar_EOLType, statusBar_encodingType;

	static Ihandle*				menuOutlineWindow, menuMessageWindow;

	static char[]				linuxTermName;

	// Setting
	static char[][]				KEYWORDS;
	static int					keywordCase = 0;	
	static char[]				compilerFullPath;
	static char[]				compilerAnootation = "ON";
	static char[]				debuggerFullPath;
	static char[]				maxError = "30";
	static char[]				defaultOption;
	static char[][]				recentProjects, recentOptions, recentArgs;
	static EditorToggleUint		editorSetting00;
	static EditorColorUint		editColor;
	//static Ihandle*			functionTitleHandle;
	static char[]				enableKeywordComplete = "ON";
	static char[]				enableParser = "ON";
	static char[]				showFunctionTitle = "OFF";
	static char[]				showTypeWithParams = "OFF";
	static char[]				toggleIgnoreCase = "ON";		// SCI_AUTOCSETIGNORECASE
	static char[]				toggleCaseInsensitive = "ON";	// SCI_AUTOCSETCASEINSENSITIVEBEHAVIOUR
	static char[]				toggleShowListType = "OFF";
	static char[]				toggleShowAllMember = "ON";
	

	static CScintilla[char[]]	scintillaManager;

	static CASTnode[char[]]		parserManager;

	static int					autoCompletionTriggerWordCount = 3;
	static int					includeLevel = 2;
	static int					liveLevel = 0;
	static char[]				toggleUpdateOutlineLive = "OFF";

	//Parser
	static CScanner				scanner;
	static CParser				parser;



	static PROJECT[char[]]		projectManager;


	static char[]				txtCompilerOptions;
	static CstringConvert		cString;
	
	static ShortKey[]			shortKeys;

	static fontUint[]			fonts;

	static bool					bKeyUp = true;
	static int					KeyNumber;

	static this()
	{
		GLOBAL.cString = new CstringConvert;
		GLOBAL.scanner = new CScanner;
		GLOBAL.parser = new CParser;
		
		GLOBAL.KEYWORDS ~= "__date__ __date_iso__ __fb_64bit__ __fb_argc__ __fb_argv__ __fb_arm__ __fb_asm__ __fb_backend__ __fb_bigendian__ __fb_build_date__ __fb_cygwin__ __fb_darwin__ __fb_debug__ __fb_dos__ __fb_err__ __fb_fpmode__ __fb_fpu__ __fb_freebsd__ __fb_gcc__ __fb_lang__ __fb_linux__ __fb_main__ __fb_min_version__ __fb_mt__ __fb_netbsd__ __fb_openbsd__ __fb_option_byval__ __fb_option_dynamic__ __fb_option_escape__ __fb_option_explicit__ __fb_option_gosub__ __fb_option_private__ __fb_out_dll__ __fb_out_exe__ __fb_out_lib__ __fb_out_obj__ __fb_pcos__ __fb_signature__ __fb_sse__ __fb_unix__ __fb_vectorize__ __fb_ver_major__ __fb_ver_minor__ __fb_ver_patch__ __fb_version__ __fb_win32__ __fb_xbox__ __file__ __file_nq__ __function__ __function_nq__ __line__ __path__ __time__ #assert #define #else #elseif #endif #endmacro #error #if #ifdef #ifndef #inclib #include #lang #libpath #line #macro #pragma #print #undef $dynamic $include $static $lang  abs abstract access acos add alias allocate alpha and andalso any append as assert assertwarn asc asin asm atan2 atn base beep bin binary bit bitreset bitset bload bsave byref byte byval call callocate case cast cbyte cdbl cdecl chain chdir";
		GLOBAL.KEYWORDS ~= "chr cint circle class clear clng clngint close cls color command common condbroadcast condcreate conddestroy condsignal condwait const constructor continue cos cptr cshort csign csng csrlin cubyte cuint culng culngint cunsg curdir cushort custom cvd cvi cvl cvlongint cvs cvshort data date dateadd datediff datepart dateserial datevalue day deallocate declare defbyte defdbl defined defint deflng deflongint defshort defsng defstr defubyte defuint defulongint defushort delete destructor dim dir do double draw dylibfree dylibload dylibsymbol else elseif encoding end enum environ eof eqv erase erfn erl ermn err error event exec exepath exit exp export extends extern field fileattr filecopy filedatetime fileexists filelen fix flip for format frac fre freefile function get getjoystick getkey getmouse gosub goto hex hibyte hiword";
		GLOBAL.KEYWORDS ~= "hour if iif imageconvertrow imagecreate imagedestroy imageinfo imp implements import inkey inp input instr instrrev int integer is isdate isredirected kill lbound lcase left len let lib line lobyte loc local locate lock lof log long longint loop loword lpos lprint lset ltrim mid minute mkd mkdir mki mkl mklongint mks mkshort mod month monthname multikey mutexcreate mutexdestroy mutexlock mutexunlock naked name namespace next new not now object oct offsetof on once open operator option or orelse out output overload override paint palette pascal pcopy peek pmap point pointcoord pointer poke pos preserve preset print private procptr property protected pset ptr public put random randomize read reallocate redim rem reset restore resume return rgb rgba right rmdir";
		GLOBAL.KEYWORDS ~= "rnd rset rtrim run sadd scope screen screencopy screencontrol screenevent screeninfo screenglproc screenlist screenlock screenptr screenres screenset screensync screenunlock second seek select setdate setenviron setmouse settime sgn shared shell shl shr short sin single sizeof sleep space spc sqr static stdcall step stick stop str strig string strptr sub swap system tab tan then this threadcall threadcreate threaddetach threadwait time timeserial timevalue timer to trans trim type typeof ubound ubyte ucase uinteger ulong ulongint union unlock unsigned until ushort using va_arg va_first va_next val vallng valint valuint valulng var varptr view virtual wait wbin wchr weekday weekdayname wend while whex width window windowtitle winput with woct write wspace wstr wstring xor year zstring";

		ShortKey sk0 = { "Find/Replace", 536870982 };
		GLOBAL.shortKeys ~= sk0;
		ShortKey sk1 = { "Find/Replace In Files", 805306438 };
		GLOBAL.shortKeys ~= sk1;
		ShortKey sk2 = { "Find Next", 65472 };
		GLOBAL.shortKeys ~= sk1;
		ShortKey sk3 = { "Find Previous", 536936384 };
		GLOBAL.shortKeys ~= sk3;
		ShortKey sk4 = { "Goto Line", 536870983 };
		GLOBAL.shortKeys ~= sk4;
		ShortKey sk5 = { "Undo", 536871002 };
		GLOBAL.shortKeys ~= sk5;
		ShortKey sk6 = { "Redo", 536871000 };
		GLOBAL.shortKeys ~= sk6;
		ShortKey sk7 = { "Goto Defintion", 1073741895 };
		GLOBAL.shortKeys ~= sk7;
		ShortKey sk8 = { "Quick Run", 268500930 };
		GLOBAL.shortKeys ~= sk8;
		ShortKey sk9 = { "Run", 65474 };
		GLOBAL.shortKeys ~= sk9;
		ShortKey sk10 = { "Build", 65475 };
		GLOBAL.shortKeys ~= sk10;
		ShortKey sk11 = { "On/Off Left-side Window", 65480 };
		GLOBAL.shortKeys ~= sk11;
		ShortKey sk12 = { "On/Off Bottom-side Window", 65481 };
		GLOBAL.shortKeys ~= sk12;
		ShortKey sk13 = { "Show Type", 65470 };
		GLOBAL.shortKeys ~= sk13;
		ShortKey sk14 = { "Reparse", 65471 };
		GLOBAL.shortKeys ~= sk14;
		ShortKey sk15 = { "Save File", 536870995 };
		GLOBAL.shortKeys ~= sk15;
		ShortKey sk16 = { "Save All", 805306451 };
		GLOBAL.shortKeys ~= sk16;
		ShortKey sk17 = { "Close File", 536870999 };
		GLOBAL.shortKeys ~= sk17;
		ShortKey sk18 = { "Next Tab", 536870921 };
		GLOBAL.shortKeys ~= sk18;
		ShortKey sk19 = { "Previous Tab", 805306377 };
		GLOBAL.shortKeys ~= sk19;
		ShortKey sk20 = { "New Tab", 536870990 };
		GLOBAL.shortKeys ~= sk20;
		ShortKey sk21 = { "Autocomplete", 536870993 };
		GLOBAL.shortKeys ~= sk21;
		

		fontUint fu;
		version( Windows )
		{
			fu.name ="Default";
			fu.fontString = "Courier New,10";
		}
		else
		{
			fu.name ="Default";
			fu.fontString = "FreeMono,Bold 10";
		}

		GLOBAL.fonts ~= fu;

		fu.name = "Document";
		GLOBAL.fonts ~= fu;

		fu.name = "Leftside";
		GLOBAL.fonts ~= fu;
		
		fu.name = "Filelist";
		GLOBAL.fonts ~= fu;

		fu.name = "Project";
		GLOBAL.fonts ~= fu;

		fu.name = "Outline";
		GLOBAL.fonts ~= fu;

		fu.name = "Bottom";
		GLOBAL.fonts ~= fu;

		fu.name = "Output";
		GLOBAL.fonts ~= fu;

		fu.name = "Search";
		GLOBAL.fonts ~= fu;	

		fu.name = "Debugger";
		GLOBAL.fonts ~= fu;

		fu.name = "Annotation";
		GLOBAL.fonts ~= fu;

		scope fileCompilerOptions = new UnicodeFile!(char)( "settings/compilerOptions.txt", Encoding.Unknown );
		GLOBAL.txtCompilerOptions = fileCompilerOptions.read.dup;
	}	
}