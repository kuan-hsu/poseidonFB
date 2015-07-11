module global;

import tango.text.xml.Document;
import tango.io.UnicodeFile;
//import tango.io.Stdout;

struct EditorToggleUint
{
	char[] LineMargin, BookmarkMargin, FoldMargin, IndentGuide, CaretLine, WordWrap, TabUseingSpace, AutoIndent;
	char[] TabWidth;
}

struct EditorFontUint
{
	char[] name, size, foreColor, backColor, bold, italic, underline;
}

struct EditorColorUint
{
	char[] caretLine, cursor, selectionFore, selectionBack, linenumFore, linenumBack, fold;
}

class CString
{
	char[] text;
	
	this( char[] _t){ text = _t; }
	~this(){}
}


struct GLOBAL
{
	private:
	
	import iup.iup;
	import iup.iup_scintilla;

	//import Integer = tango.text.convert.Integer;
	import tango.stdc.stringz;

	import scintilla, project, layouts.tree;
	import dialogs.searchDlg, dialogs.findFilesDlg, dialogs.helpDlg;
	

	public:

	static Ihandle*				mainDlg;
	static Ihandle*				documentTabs, projectViewTabs, messageWindowTabs;

	// LAYOUT
	static Ihandle* 			explorerWindow;
	static Ihandle* 			explorerSplit; // which split explorerWindow & editWindow
	static char*				explorerSplit_value = "300";
	//static Ihandle* 			projectManagerToolbar;
	//static Ihandle* 			projectManagerTree;

	static CProjectTree			projectTree;

	
	static Ihandle* 			outlineTree;
	static Ihandle* 			fileListTree;
	
	
	static Ihandle* 			outputPanel;
	static Ihandle* 			searchOutputPanel;
	static Ihandle* 			messageSplit; // which split (explorerWindow + editWindow ) & messageWindow
	static char*				messageSplit_value = "800";

	static CSearchDialog		searchDlg;
	static CFindInFilesDialog	serachInFilesDlg;
	static CCompilerHelpDialog	compilerHelpDlg;

	static Ihandle*				statusBar_Line_Col, statusBar_Ins, statusBar_FontType;

	static Ihandle*				menuMessageWindow;
	

	// Setting
	static char[][]				KEYWORDS;
	static char[]				compilerFullPath;// = "D:\\CodingPark\\FreeBASIC-1.02.1-win32\\fbc.exe";
	static char[]				debuggerFullPath;
	static char[]				maxError;
	static char[][]				recentProjects;
	static EditorToggleUint		editorSetting00;		
	static EditorFontUint		editFont;
	static EditorColorUint		editColor;
	


	static CScintilla[char[]]	scintillaManager;


	static PROJECT[char[]]		projectManager;
	//static char[]				activeProjectDirName;


	static char[]				txtCompilerOtions;
}