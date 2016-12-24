module global;

struct EditorToggleUint
{
	char[] LineMargin = "ON", BookmarkMargin = "ON", FoldMargin = "ON", IndentGuide = "ON", CaretLine = "ON", WordWrap = "OFF", TabUseingSpace = "OFF", AutoIndent = "ON", ShowEOL = "OFF", ShowSpace = "OFF", AutoEnd = "OFF";
	char[] TabWidth = "4", ColumnEdge = "0", EolType = "0", ColorOutline = "OFF", Message = "OFF", BoldKeyword = "OFF";
}

struct EditorLayoutSize
{
	char[] PLACEMENT = "MAXIMIZED", RASTERSIZE = "700x500", ExplorerSplit = "170", MessageSplit = "800", FileListSplit = "1000", OutlineWindow = "ON", MessageWindow = "ON";
}

struct EditorColorUint
{
	char[][4] keyWord = [ "5 91 35", "0 0 255", "231 144 20", "16 108 232" ];
	char[] caretLine = "255 255 128", cursor = "0 0 0", selectionFore = "255 255 255", selectionBack = "0 0 255", linenumFore = "0 0 0", linenumBack = "200 200 200", fold = "200 208 208", selAlpha = "255";
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


struct GLOBAL
{
	private:
	import iup.iup;
	import iup.iup_scintilla;

	import tango.stdc.stringz;

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
	static char[]				lexer = "freebasic";
	static char[][]				KEYWORDS;
	static int					keywordCase = 0;	
	static char[]				compilerFullPath;
	static char[]				compilerAnootation = "ON";
	static char[]				compilerWindow = "ON";
	static char[]				debuggerFullPath;
	//static char[]				maxError = "30";
	static char[]				defaultOption;
	static char[]				recentOpenDir;
	static char[][]				recentFiles, recentProjects, recentOptions, recentArgs;
	static EditorToggleUint		editorSetting00;
	static EditorLayoutSize		editorSetting01;
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
	
	static char[]				language;
	static char[][char[]]		languageItems;


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

		ShortKey sk0 = { "find", "Find/Replace", 536870982 };
		GLOBAL.shortKeys ~= sk0;
		ShortKey sk1 = { "findinfile", "Find/Replace In Files", 805306438 };
		GLOBAL.shortKeys ~= sk1;
		ShortKey sk2 = { "findnext", "Find Next", 65472 };
		GLOBAL.shortKeys ~= sk1;
		ShortKey sk3 = { "findprev", "Find Previous", 536936384 };
		GLOBAL.shortKeys ~= sk3;
		ShortKey sk4 = { "gotoline", "Goto Line", 536870983 };
		GLOBAL.shortKeys ~= sk4;
		ShortKey sk5 = { "undo", "Undo", 536871002 };
		GLOBAL.shortKeys ~= sk5;
		ShortKey sk6 = { "redo", "Redo", 536871000 };
		GLOBAL.shortKeys ~= sk6;
		ShortKey sk7 = { "defintion", "Goto Defintion", 1073741895 };
		GLOBAL.shortKeys ~= sk7;
		ShortKey sk8 = { "quickrun", "Quick Run", 268500930 };
		GLOBAL.shortKeys ~= sk8;
		ShortKey sk9 = { "run", "Run", 65474 };
		GLOBAL.shortKeys ~= sk9;
		ShortKey sk10 = { "build", "Build", 65475 };
		GLOBAL.shortKeys ~= sk10;
		ShortKey sk11 = { "outlinewindow", "On/Off Left-side Window", 65480 };
		GLOBAL.shortKeys ~= sk11;
		ShortKey sk12 = { "messagewindow", "On/Off Bottom-side Window", 65481 };
		GLOBAL.shortKeys ~= sk12;
		ShortKey sk13 = { "showtype", "Show Type", 65470 };
		GLOBAL.shortKeys ~= sk13;
		ShortKey sk14 = { "reparse", "Reparse", 65471 };
		GLOBAL.shortKeys ~= sk14;
		ShortKey sk15 = { "save", "Save File", 536870995 };
		GLOBAL.shortKeys ~= sk15;
		ShortKey sk16 = { "saveall", "Save All", 805306451 };
		GLOBAL.shortKeys ~= sk16;
		ShortKey sk17 = { "close", "Close File", 536870999 };
		GLOBAL.shortKeys ~= sk17;
		ShortKey sk18 = { "nexttab", "Next Tab", 536870921 };
		GLOBAL.shortKeys ~= sk18;
		ShortKey sk19 = { "prevtab","Previous Tab", 805306377 };
		GLOBAL.shortKeys ~= sk19;
		ShortKey sk20 = { "newtab", "New Tab", 536870990 };
		GLOBAL.shortKeys ~= sk20;
		ShortKey sk21 = { "autocomplete", "Autocomplete", 536870993 };
		GLOBAL.shortKeys ~= sk21;
		ShortKey sk22 = { "compilerun", "Compile & Run", 536936386 };
		GLOBAL.shortKeys ~= sk22;
		

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
		
		
		
		GLOBAL.languageItems["file"] = "File";
			GLOBAL.languageItems["new"] = "New";
			GLOBAL.languageItems["open"] = "Open";
			GLOBAL.languageItems["save"] = "Save";
			GLOBAL.languageItems["saveas"] = "Save As";
			GLOBAL.languageItems["saveall"] = "Save All";
			GLOBAL.languageItems["close"] = "Close";
			GLOBAL.languageItems["closeall"] = "Close All";
			GLOBAL.languageItems["recentfiles"] = "Recent Files";
			GLOBAL.languageItems["recentprjs"] = "Recent Projects";
			GLOBAL.languageItems["clearall"] = "Clear All";
			GLOBAL.languageItems["exit"] = "Exit";
			
		GLOBAL.languageItems["edit"] = "Edit";
			GLOBAL.languageItems["redo"] = "Redo";
			GLOBAL.languageItems["undo"] = "Undo";
			GLOBAL.languageItems["cut"] = "Cut";
			GLOBAL.languageItems["copy"] = "Copy";
			GLOBAL.languageItems["paste"] = "Paste";
			GLOBAL.languageItems["commentline"] = "(Un)Comment Line";
			GLOBAL.languageItems["selectall"] = "Select All";
			
		GLOBAL.languageItems["search"] = "Search";
			GLOBAL.languageItems["findreplace"] = "Find/Replace";
			GLOBAL.languageItems["findnext"] = "Find Next";
			GLOBAL.languageItems["findprev"] = "Find Previous";
			GLOBAL.languageItems["findreplacefiles"] = "Find/Replace In Files";
			GLOBAL.languageItems["goto"] = "Goto Line";
				GLOBAL.languageItems["line"] = "Line";

		GLOBAL.languageItems["view"] = "View";
			GLOBAL.languageItems["outline"] = "Outline";
			GLOBAL.languageItems["message"]= "Message";
			
		GLOBAL.languageItems["prj"] = "Project";
			GLOBAL.languageItems["newprj"] = "New Project";
			GLOBAL.languageItems["openprj"] = "Open Project";
			GLOBAL.languageItems["importprj"] = "Import Fbedit Project";
			GLOBAL.languageItems["saveprj"] = "Save Project";
			GLOBAL.languageItems["saveallprj"] = "Save All Projects";
			GLOBAL.languageItems["closeprj"] = "Close Project";
			GLOBAL.languageItems["closeallprj"] = "Close All Projects";
			GLOBAL.languageItems["properties"] = "Properties...";
			
			GLOBAL.languageItems["openinexplorer"] = "Open In Explorer";
			GLOBAL.languageItems["addinprj"]= "Add File(s)";
			GLOBAL.languageItems["removefromprj"] = "Remove From Project";
			GLOBAL.languageItems["rename"] = "Rename File";
			GLOBAL.languageItems["newfile"] = "New File";
				GLOBAL.languageItems["filename"] = "File Name";
			GLOBAL.languageItems["newfolder"] = "New Folder";
				GLOBAL.languageItems["foldername"] = "Folder Name";
			GLOBAL.languageItems["addfile"] = "Add file(s)";
		
		GLOBAL.languageItems["build"] = "Build";
			GLOBAL.languageItems["compile"] = "Compile File";
			GLOBAL.languageItems["compilerun"]= "Compile File And Run";
			GLOBAL.languageItems["run"] = "Run";
			GLOBAL.languageItems["buildprj"] = "Build Project";
			GLOBAL.languageItems["quickrun"] = "Quick Run";
			
		GLOBAL.languageItems["debug"] = "Debug";
			GLOBAL.languageItems["rundebug"] = "Run Debug";
			GLOBAL.languageItems["compiledebug"] = "Compile With Debug";
			GLOBAL.languageItems["builddebug"] = "Build Project With Debug";
			
		GLOBAL.languageItems["options"] = "Options";
			GLOBAL.languageItems["tools"] = "Tools";
				GLOBAL.languageItems["seteol"] = "Set Eol Character";
				GLOBAL.languageItems["converteol"] = "Convert Eol Character";
				GLOBAL.languageItems["convertencoding"] = "Convert Encoding";
				GLOBAL.languageItems["convertcase"] = "Convert Keyword Case";
					GLOBAL.languageItems["uppercase"] = "UPPERCASE";
					GLOBAL.languageItems["lowercase"] = "lowercase";
					GLOBAL.languageItems["mixercase"] = "Mixedcase";
			GLOBAL.languageItems["preference"] = "Preference";
				GLOBAL.languageItems["compiler"] = "Compiler";
					GLOBAL.languageItems["compilerpath"] = "Compiler Path";
					GLOBAL.languageItems["debugpath"] = "Debugger Path";
					GLOBAL.languageItems["compileropts"] = "Compiler Opts";
					GLOBAL.languageItems["compilersetting"] = "Compiler Setting";
						GLOBAL.languageItems["errorannotation"] = "Show Compiler Errors/Warnings Using Annotation";
						GLOBAL.languageItems["showresultwindow"] = "Show Compiled Result Window";
					GLOBAL.languageItems["parsersetting"] = "Parser Settings";
						GLOBAL.languageItems["enablekeyword"] = "Enable Keyword Autocomplete";
						GLOBAL.languageItems["enableparser"] = "Enable Parser";
						GLOBAL.languageItems["showtitle"] = "Show Function Title";
						GLOBAL.languageItems["showtypeparam"] = "Show Type With Function Parameters";
						GLOBAL.languageItems["sortignorecase"] = "Autocomplete List Is Ignore Case";
						GLOBAL.languageItems["selectcase"] = "Selection Of Autocomplete List Is Case Insensitive";
						GLOBAL.languageItems["showlisttype"] = "Show Autocomplete List Type";
						GLOBAL.languageItems["showallmembers"] = "Show All Members( public, protected, private )";
						GLOBAL.languageItems["parserlive"] = "ParseLive! Level";
							GLOBAL.languageItems["none"] = "None";
							GLOBAL.languageItems["light"] = "Light";
							GLOBAL.languageItems["full"] = "Full";
							GLOBAL.languageItems["update"] = "Update Outline";
						GLOBAL.languageItems["trigger"] = "Autocompletion Trigger";
							GLOBAL.languageItems["triggertip"] = "Set 0 To Disable";
						GLOBAL.languageItems["includelevel"] = "Include Levels";
					GLOBAL.languageItems["editor"] = "Editor";
						GLOBAL.languageItems["lnmargin"] = "Show Linenumber Margin";
						GLOBAL.languageItems["bkmargin"] = "Show Bookmark Margin";
						GLOBAL.languageItems["fdmargin"] = "Show Folding Margin";
						GLOBAL.languageItems["indentguide"] = "Show Indentation Guide";
						GLOBAL.languageItems["showcaretline"] = "Highlight Caret Line";
						GLOBAL.languageItems["wordwarp"] = "Word Wrap";
						GLOBAL.languageItems["tabtospace"] = "Replace Tab With Space";
						GLOBAL.languageItems["autoindent"] = "Automatic Indent";
						GLOBAL.languageItems["showeol"] = "Show EOL Sign";
						GLOBAL.languageItems["showspacetab"] = "Show Space/Tab";
						GLOBAL.languageItems["autoinsertend"] = "Auto Insert Block End";
						GLOBAL.languageItems["coloroutline"] = "Colorize Outline Item";
						GLOBAL.languageItems["showidemessage"] = "Show IDE Message";
						GLOBAL.languageItems["boldkeyword"] = "Bold Keywords";
						GLOBAL.languageItems["tabwidth"] = "Tab Width";
						GLOBAL.languageItems["columnedge"] = "Column Edge";
						GLOBAL.languageItems["autoconvertkeyword"] = "Auto Convert Keyword Case";
						GLOBAL.languageItems["font"] = "Font";
							GLOBAL.languageItems["default"] = "Default";
							GLOBAL.languageItems["document"] = "Document";
							GLOBAL.languageItems["leftside"] = "Leftside";
							//'fistlist=FileList
							//'project=Project
							//'outline=Outline
							GLOBAL.languageItems["bottom"] = "Bottom";
							//'output=Output
							//'search=Search
							//'debug=Debug
							GLOBAL.languageItems["annotation"] = "Annotation";
						GLOBAL.languageItems["color"] = "Color";
							GLOBAL.languageItems["caretline"] = "Caret Line";
							GLOBAL.languageItems["cursor"] = "Cursor";
							GLOBAL.languageItems["selfor"] = "Selection Foreground";
							GLOBAL.languageItems["selback"] = "Selection Background";
							GLOBAL.languageItems["lnfor"] = "Linenumber Foreground";
							GLOBAL.languageItems["lnback"] = "Linenumber Background";
							GLOBAL.languageItems["foldcolor"] = "FoldingMargin Color";
							GLOBAL.languageItems["selalpha"] = "Selection Alpha";
								GLOBAL.languageItems["alphatip"] = "Set 255 To Disable Alpha";
					GLOBAL.languageItems["shortcut"] = "Short Cut";
						GLOBAL.languageItems["sc_findreplace"] = "Find/Replace";
						GLOBAL.languageItems["sc_findreplacefiles"] = "Find/Replace In Files";
						GLOBAL.languageItems["sc_findnext"] = "Find Next";
						GLOBAL.languageItems["sc_finprev"] = "Find Previous";
						GLOBAL.languageItems["sc_goto"] = "Goto Line";
						GLOBAL.languageItems["sc_undo"] = "Undo";
						GLOBAL.languageItems["sc_redo"] = "Redo";
						GLOBAL.languageItems["sc_gotodef"] = "Goto Definition";
						GLOBAL.languageItems["sc_quickrun"] = "Quick Run";
						GLOBAL.languageItems["sc_run"] = "Run";
						GLOBAL.languageItems["sc_compile"] = "Compile";
						GLOBAL.languageItems["sc_build"] = "Build Project";
						GLOBAL.languageItems["sc_leftwindow"] = "On/Off Left Window";
						GLOBAL.languageItems["sc_bottomwindow"] = "On/Off Bottom Window";
						GLOBAL.languageItems["sc_showtype"] = "Show Type";
						GLOBAL.languageItems["sc_reparse"] = "Reparse";
						GLOBAL.languageItems["sc_save"] = "Save File";
						GLOBAL.languageItems["sc_saveall"] = "Save All";
						GLOBAL.languageItems["sc_close"] = "Close File";
						GLOBAL.languageItems["sc_nexttab"] = "Next Tab";
						GLOBAL.languageItems["sc_prevtab"] = "Previous Tab";
						GLOBAL.languageItems["sc_newtab"] ="New Tab";
						GLOBAL.languageItems["sc_autocomplete"] = "Auto Complete";
						GLOBAL.languageItems["sc_compilerun"] = "Compile File And Run";
					GLOBAL.languageItems["keywords"] = "Keywords";
						GLOBAL.languageItems["keyword0"] = "Keyword0";
						GLOBAL.languageItems["keyword1"] = "Keyword1";
						GLOBAL.languageItems["keyword2"] = "Keyword2";
						GLOBAL.languageItems["keyword3"] = "Keyword3";
			GLOBAL.languageItems["language"] = "Language";
				GLOBAL.languageItems["openlanguage"] = "Choose Language...";
			GLOBAL.languageItems["about"] = "About";
		
		GLOBAL.languageItems["bookmark"] = "Mark Bookmark";
		GLOBAL.languageItems["bookmarkprev"] = "Previous Bookmark";
		GLOBAL.languageItems["bookmarknext"] = "Next Bookmark";
		GLOBAL.languageItems["bookmarkclear"] = "Clear Bookmark";

		GLOBAL.languageItems["outline"] = "Outline";
			GLOBAL.languageItems["collapse"] = "Collapse";
			GLOBAL.languageItems["showpr"] = "Change Outline Node Title";
			GLOBAL.languageItems["refresh"] = "Refresh";
			GLOBAL.languageItems["searchanyword"] = "Search Any Word";
			GLOBAL.languageItems["hide"] = "Hide";

		GLOBAL.languageItems["filelist"] = "FileList";
			GLOBAL.languageItems["fullpath"] = "FullPath";

		GLOBAL.languageItems["output"] = "Output";
			GLOBAL.languageItems["clear"] = "Clear";

		//'tab
		GLOBAL.languageItems["closeothers"] = "Close Others";

		//'popup window
		GLOBAL.languageItems["delete"] = "Delete";
		GLOBAL.languageItems["showannotation"] = "Show Annotation";
		GLOBAL.languageItems["hideannotation"] = "Hide Annotation";
		GLOBAL.languageItems["removeannotation"] = "Remove All Annotation";

		//'properties
		GLOBAL.languageItems["prjproperties"] = "Project Properties";
		GLOBAL.languageItems["general"] = "General";
			GLOBAL.languageItems["prjname"] = "Project Name";
			GLOBAL.languageItems["prjtype"] = "Type";
				GLOBAL.languageItems["console"] = "Console Application";
				GLOBAL.languageItems["static"] = "Static Library";
				GLOBAL.languageItems["dynamic"] = "Dynamic Link Library";
			GLOBAL.languageItems["prjdir"] = "Project Dir";
			GLOBAL.languageItems["prjmainfile"] = "Main file";
			GLOBAL.languageItems["prjtarget"] = "Target Name";
			GLOBAL.languageItems["prjargs"] = "Execute Args";
			GLOBAL.languageItems["prjopts"] = "Compile Opt";
			GLOBAL.languageItems["prjcomment"] = "Comment";
			GLOBAL.languageItems["prjcompiler"] = "FBC Path";
		GLOBAL.languageItems["include"] = "Include...";
			GLOBAL.languageItems["includepath"] = "Include Paths";
			GLOBAL.languageItems["librarypath"] = "Libraries Paths";
		
		// Search Window
		GLOBAL.languageItems["findwhat"] = "Find What";
		GLOBAL.languageItems["replacewith"] = "Replace With";
		GLOBAL.languageItems["direction"] = "Direction";
			GLOBAL.languageItems["forward"] = "Forward";
			GLOBAL.languageItems["backward"] = "Backward";
		GLOBAL.languageItems["scope"] = "Scope";
			GLOBAL.languageItems["all"] = "All";
			GLOBAL.languageItems["selection"] = "Selection";
		GLOBAL.languageItems["casesensitive"] = "Case Sensitive";
		GLOBAL.languageItems["wholeword"] = "Whole Word";
		GLOBAL.languageItems["find"] = "Find";
		GLOBAL.languageItems["findall"] = "Find All";
		GLOBAL.languageItems["replacefind"] = "Find/Replace";
		GLOBAL.languageItems["replace"] = "Replace";
		GLOBAL.languageItems["replaceall"] = "Replace All";
		GLOBAL.languageItems["countall"] = "Count All";
		GLOBAL.languageItems["bookmarkall"] = "Mark All";
		GLOBAL.languageItems["document"] = "Document";
		GLOBAL.languageItems["alldocument"] = "All Document";
		GLOBAL.languageItems["allproject"] = "All Project";
		GLOBAL.languageItems["status"] = "Status Bar";
		
		// shortcut
		GLOBAL.languageItems["shortcutname"] = "ShortCut Name";
		GLOBAL.languageItems["shortcutkey"] = "Current ShortCut Keys";
		
		// debug
		GLOBAL.languageItems["runcontinue"] = "Run/Continue";
		GLOBAL.languageItems["stop"] = "Stop";
		GLOBAL.languageItems["step"] = "Step";
		GLOBAL.languageItems["next"] = "Next";
		GLOBAL.languageItems["return"] = "Return";
		GLOBAL.languageItems["until"] = "Until";
		GLOBAL.languageItems["terminate"] = "Terminate";
		GLOBAL.languageItems["bp"] = "Breakpoints";
		GLOBAL.languageItems["variable"] = "Variables";
			GLOBAL.languageItems["watchlist"] = "Watch List";
				GLOBAL.languageItems["add"] = "Add";
				GLOBAL.languageItems["remove"] = "Remove";
				GLOBAL.languageItems["removeall"] = "Remove All";
			GLOBAL.languageItems["addtowatch"] = "Add To Watchlist";
			GLOBAL.languageItems["locals"] = "Locals";
			GLOBAL.languageItems["args"] = "Arguments";
			GLOBAL.languageItems["shared"] = "Shared";
		GLOBAL.languageItems["register"] = "Registers";

		// caption
		GLOBAL.languageItems["caption_new"] = "New";
		GLOBAL.languageItems["caption_open"] = "Open";
		GLOBAL.languageItems["caption_saveas"] = "Save As";
		GLOBAL.languageItems["caption_cut"] = "Cut";
		GLOBAL.languageItems["caption_copy"] = "Copy";
		GLOBAL.languageItems["caption_paste"] = "Paste";
		GLOBAL.languageItems["caption_selectall"] = "Select All";
		GLOBAL.languageItems["caption_about"] = "About";
		//GLOBAL.languageItems["caption_findreplace"] = "Find / Replace";
		//GLOBAL.languageItems["caption_findreplacefiles"] = "Find / Replace In Files";
		//GLOBAL.languageItems["caption_goto"] = "Goto Line";
		GLOBAL.languageItems["caption_openprj"] = "Open Project";
		GLOBAL.languageItems["caption_importprj"] = "Import Fbedit Project";
		GLOBAL.languageItems["caption_prjproperties"] = "Project Properties";
		GLOBAL.languageItems["caption_preference"] = "Preference";
		GLOBAL.languageItems["caption_argtitle"] = "Compiler Options / EXE Arguments";
		GLOBAL.languageItems["caption_debug"] = "Debug";
		GLOBAL.languageItems["caption_optionhelp"] = "Compiler Options";
		
		// message
		GLOBAL.languageItems["ok"] = "OK";
		GLOBAL.languageItems["yes"] = "Yes";
		GLOBAL.languageItems["no"] = "No";
		GLOBAL.languageItems["cancel"] = "Cancel";
		GLOBAL.languageItems["bechange"] = "has been changed, save it now?";
		GLOBAL.languageItems["samekey"] = "The same key value with";
		GLOBAL.languageItems["needrestart"] = "Need Restart To Change Language";
		GLOBAL.languageItems["suredelete"] = "Are you sure to delete file?";
		GLOBAL.languageItems["opened"] = "had already opened!";
		GLOBAL.languageItems["existed"] = "had already existed!";
		GLOBAL.languageItems["wrongext"] = "Wrong Ext Name!";
		GLOBAL.languageItems[".poseidonbroken"] = "Project setup file loading error! Xml format may be broken!";
		GLOBAL.languageItems[".poseidonlost"] = "had lost setting xml file!";
		GLOBAL.languageItems["continueimport"] = "The Dir has poseidonFB Project File, Continue Import Anyway?";
		GLOBAL.languageItems["compilefailure"] = "Compile Failure!";
		GLOBAL.languageItems["compilewarning"] = "Compile Done, But Got Warnings!";
		GLOBAL.languageItems["compileok"] = "Compile Success!";
		GLOBAL.languageItems["cantundo"] = "This action can't be undo! Continue anyway?";
		GLOBAL.languageItems["exitdebug1"] = "Exit debug right now?";
		GLOBAL.languageItems["exitdebug2"] = "No debugging symbols found!! Exit debug!";
		GLOBAL.languageItems["quest"] = "Quest";
		GLOBAL.languageItems["alarm"] = "Alarm";
		GLOBAL.languageItems["error"] = "Error";

		GLOBAL.languageItems["exefile"] = "Execute Files";
		GLOBAL.languageItems["basfile"] = "freeBASIC Sources";
		GLOBAL.languageItems["bifile"] = "freeBASIC Includes";
		GLOBAL.languageItems["lngfile"] = "Language Files";
		GLOBAL.languageItems["allfile"] = "All Files";
		GLOBAL.languageItems["fbeditfile"] = "FbEdit Projects";
	}	
}