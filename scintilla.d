module scintilla;

//Callback Function
private
{
	import iup.iup;
	import iup.iup_scintilla;

	import global, actionManager, menu, tools;

	import Integer = tango.text.convert.Integer;
	import tango.text.convert.Layout;
	import tango.stdc.stringz;
	import tango.io.Stdout;
	import tango.text.convert.Utf;
}

/*
struct TextToFind 
{
	int start;
	int end; 
	char* searchPattern;
	int startFound; 
	int endFound; 
		
	static TextToFind opCall(char[] searchPattern, int start, int end)
	{
		TextToFind tf;
		tf.searchPattern = toStringz(searchPattern);
		tf.start = start;
		tf.end = end;
		return tf;
	}
}
*/
import		parser.autocompletion, tools;

class CScintilla
{
	private:
	import			global, images.xpm;
	
	import 			tango.io.FilePath;
	import			tango.io.UnicodeFile;
	

	Ihandle*		sci;
	char[]			fullPath;
	CstringConvert	title;

	public:
	int				encoding;
	
	this()
	{
		sci = IupScintilla();
		IupSetAttribute( sci, "EXPAND", "YES" );
	}

	this( char[] _fullPath )
	{
		sci = IupScintilla();
		IupSetAttribute( sci, "EXPAND", "YES" );
		IupSetCallback( sci, "MARGINCLICK_CB",cast(Icallback) &marginclick_cb );
		//IupSetCallback( sci, "VALUECHANGED_CB",cast(Icallback) &CScintilla_valuechanged_cb );
		IupSetCallback( sci, "BUTTON_CB",cast(Icallback) &button_cb );
		IupSetCallback( sci, "SAVEPOINT_CB",cast(Icallback) &savePoint_cb );
		IupSetCallback( sci, "K_ANY",cast(Icallback) &CScintilla_keyany_cb );
		IupSetCallback( sci, "ACTION",cast(Icallback) &CScintilla_action_cb );
		IupSetCallback( sci, "CARET_CB",cast(Icallback) &CScintilla_caret_cb );
		IupSetCallback( sci, "AUTOCSELECTION_CB",cast(Icallback) &CScintilla_AUTOCSELECTION_cb );

		IupSetCallback( sci, "DROPFILES_CB",cast(Icallback) &CScintilla_dropfiles_cb );

		
		init( _fullPath );
	}	

	~this()
	{
		IupSetHandle( GLOBAL.cString.convert( fullPath ), null );
		if( !GLOBAL.debugPanel.isRunning && !GLOBAL.debugPanel.isExecuting )
		{
			int count = IupGetInt( GLOBAL.debugPanel.getBPListHandle, "COUNT" );
			for( int i = count; i > 0; -- i )
			{
				char[] listValue = fromStringz( IupGetAttribute( GLOBAL.debugPanel.getBPListHandle, toStringz( Integer.toString( i ) ) ) ).dup;
				char[] id = Util.trim( listValue[0..6] );
				char[] ln = Util.trim( listValue[6..12] );
				char[] fn = Util.trim( listValue[12..length] );

				if( id == "-1" )
				{
					if( fn == fullPath ) IupSetInt( GLOBAL.debugPanel.getBPListHandle, "REMOVEITEM", i );
				}
			}			
		}

		
		if( title !is null ) delete title;
		if( sci != null ) IupDestroy( sci );
	}

	void init( char[] _fullPath )
	{
		fullPath = _fullPath;
		scope mypath = new FilePath( fullPath );

		title = new CstringConvert( mypath.file() );
		
		if( GLOBAL.documentTabs != null )
		{
			int n = IupGetChildCount( GLOBAL.documentTabs );

			if( lowerCase( mypath.ext )== "bas" )
			{
				IupSetAttribute( sci, "TABIMAGE", "icon_bas" );
			}
			else if( lowerCase( mypath.ext )== "bi" )
			{
				IupSetAttribute( sci, "TABIMAGE", "icon_bi" );
			}
			else
			{
				IupSetAttribute( sci, "TABIMAGE", "icon_document" );
			}
			IupSetAttribute( sci, "TABTITLE", title.toStringz() );
			IupSetHandle( GLOBAL.cString.convert( _fullPath ), sci );

			IupAppend( GLOBAL.documentTabs, sci );
			IupMap( sci );
			IupRefresh( GLOBAL.documentTabs );

			// IupSetAttributeId( GLOBAL.documentTabs , "TABTITLE", n, toStringz( title.dup, GLOBAL.stringzTemp ) ); delete GLOBAL.stringzTemp;
		}		

		IupSetAttribute( sci, "CLEARALL", "" );
		setGlobalSetting();
	}

	void setText( char[] _text )
	{
		IupSetAttribute( sci, "CLEARALL", "" );
		IupSetAttribute( sci, "INSERT0", GLOBAL.cString.convert( _text ) );
		IupSetAttribute( sci, "SAVEDSTATE", "YES" );
		IupScintillaSendMessage( sci, 2175, 0, 0 ); // SCI_EMPTYUNDOBUFFER = 2175
	}

	char[] getText()
	{
		char[] _text = fromStringz( IupGetAttribute( sci, "VALUE" ) );
		return _text;
	}

	void setEncoding( int _encoding )
	{
		encoding = _encoding;
	}

	Ihandle* getIupScintilla()
	{
		return sci;
	}

	char[] getTitle()
	{
		return fromStringz( title.toStringz ).dup;
	}

	CstringConvert getTitleHandle()
	{
		return title;
	}

	char[] getFullPath()
	{
		return fullPath;
	}

	void rename( char[] newFullPath )
	{
		// Remove Old Handle
		IupSetHandle( GLOBAL.cString.convert( fullPath ), null );
		GLOBAL.scintillaManager.remove( upperCase(fullPath) );

		fullPath = newFullPath;
		
		scope mypath = new FilePath( fullPath );
		title.convert( mypath.file() );

		int pos = IupGetChildPos( GLOBAL.documentTabs, sci );
		if( pos > -1 )
		{
			IupSetAttributeId( GLOBAL.documentTabs, "TABTITLE", pos, title.toStringz );
		}		
		IupSetHandle( fullPath.ptr, sci );

		GLOBAL.scintillaManager[upperCase(fullPath)] = this;

		// Change the fileListTree's node
		int nodeCount = IupGetInt( GLOBAL.fileListTree, "COUNT" );
	
		for( int id = 1; id <= nodeCount; id++ ) // include Parent "FileList" node
		{
			CScintilla _sci_node = cast(CScintilla) IupGetAttributeId( GLOBAL.fileListTree, "USERDATA", id );
			if( _sci_node == this )
			{
				IupSetAttributeId( GLOBAL.fileListTree, "TITLE", id, fullPath.ptr );
				break;
			}
		}					
	}

	bool saveFile()
	{
		try
		{
			if( FileAction.saveFile( fullPath, getText(), Encoding.UTF_8 ) )
			{
				if( fromStringz( IupGetAttribute( sci, "SAVEDSTATE" ) ) == "YES" )
				{
					IupSetAttribute( sci, "SAVEDSTATE", "NO" );

					int pos = IupGetChildPos( GLOBAL.documentTabs, sci );
					if( pos > -1 )
					{
						IupSetAttributeId( GLOBAL.documentTabs, "TABTITLE", pos, title.toStringz );
					}
				}
			}
		}
		catch
		{
			IupMessage("","ERROR");
			return false;
		}

		return true;
	}

	void setGlobalSetting()
	{
		IupSetAttribute(sci, "LEXERLANGUAGE", "freebasic");

		IupSetAttribute(sci, "KEYWORDS0", GLOBAL.cString.convert( GLOBAL.KEYWORDS[0] ) );
		IupSetAttribute(sci, "KEYWORDS1", GLOBAL.cString.convert( GLOBAL.KEYWORDS[1] ) );
		IupSetAttribute(sci, "KEYWORDS2", GLOBAL.cString.convert( GLOBAL.KEYWORDS[2] ) );
		IupSetAttribute(sci, "KEYWORDS3", GLOBAL.cString.convert( GLOBAL.KEYWORDS[3] ) );


		char[] font;
		version( Windows )
		{
			font = "Courier New";
		}
		else
		{
			font = "FreeMono";
		}		
		char[] size = "10", Bold = "NO", Italic ="NO", Underline = "NO", Strikeout = "NO";

		if( GLOBAL.fonts.length > 2 )
		{
			char[][] strings = Util.split( GLOBAL.fonts[1].fontString, "," );
			if( strings.length == 2 )
			{
				if( strings[0].length )
				{
					font = Util.trim( strings[0] );
				}

				strings[1] = Util.trim( strings[1] );

				foreach( char[] s; Util.split( strings[1], " " ) )
				{
					switch( s )
					{
						case "Bold":		Bold = "YES";		break;
						case "Italic":		Italic = "YES";		break;
						case "Underline":	Underline = "YES";	break;
						case "Strikeout":	Strikeout = "YES";	break;
						default:
							size = s;
					}
				}
			}
		}

		IupSetAttribute( sci, "STYLEFONT32", GLOBAL.cString.convert( font ) );
		IupSetAttribute( sci, "STYLEFONTSIZE32", GLOBAL.cString.convert( size ) );
		IupSetAttribute(sci, "STYLECLEARALL", "Yes");  /* sets all styles to have the same attributes as 32 */
		
		IupSetAttribute(sci, "STYLEFGCOLOR1", "0 128 0");		// SCE_B_COMMENT 1
		IupSetAttribute(sci, "STYLEFGCOLOR2", "0 128 0");		// SCE_B_NUMBER 2
		IupSetAttribute(sci, "STYLEFGCOLOR3", "5 91 35");		// SCE_B_KEYWORD 3
		IupSetAttribute(sci, "STYLEFGCOLOR4", "128 0 0");		// SCE_B_STRING 4
		IupSetAttribute(sci, "STYLEFGCOLOR5", "0 0 255");		// SCE_B_PREPROCESSOR 5
		IupSetAttribute(sci, "STYLEFGCOLOR6", "160 20 20");		// SCE_B_OPERATOR 6
		/*
		IupSetAttribute(sci, "STYLEFGCOLOR7", "0 0 0");			// SCE_B_IDENTIFIER 7 usually normal color
		IupSetAttribute(sci, "STYLEFGCOLOR8", "128 0 0");		// SCE_B_DATE 8
		IupSetAttribute(sci, "STYLEFGCOLOR9", "16 108 232");	// SCE_B_STRINGEOL 9
		*/
		IupSetAttribute(sci, "STYLEFGCOLOR10", "0 0 255");		// SCE_B_KEYWORD2 10
		IupSetAttribute(sci, "STYLEFGCOLOR11", "231 144 20");	// SCE_B_KEYWORD3 11
		IupSetAttribute(sci, "STYLEFGCOLOR12", "16 108 232");	// SCE_B_KEYWORD4 12
		IupSetAttribute(sci, "STYLEFGCOLOR19", "0 128 0");		// SCE_B_COMMENTBLOCK 19

		// Brace Hightlight
		IupSetAttribute(sci, "STYLEFGCOLOR34", "255 0 0");	
		IupSetAttribute(sci, "STYLEBGCOLOR34", "0 255 0");
		IupSetAttribute(sci, "STYLEFGCOLOR35", "255 255 0");
		IupSetAttribute(sci, "STYLEBGCOLOR35", "255 0 255");
		IupSetAttribute(sci, "STYLEBOLD34", "YES");
		//IupScintillaSendMessage( sci, 2053, 34, 1 );


		// Set Keywords to Bold
		//IupSetAttribute(sci, "STYLEBOLD3", "YES");

		IupSetAttribute( sci, "STYLEBOLD32", GLOBAL.cString.convert( Bold ) );
		IupSetAttribute( sci, "STYLEITALIC32", GLOBAL.cString.convert( Italic ) );
		IupSetAttribute( sci, "STYLEUNDERLINE32", GLOBAL.cString.convert( Underline ) );
		IupSetAttribute( sci, "FGCOLOR", GLOBAL.cString.convert( "0 0 0" ) );
		IupSetAttribute( sci, "BGCOLOR", GLOBAL.cString.convert( "255 255 255" ) );

		int tabSize = Integer.atoi( GLOBAL.editorSetting00.TabWidth );
		GLOBAL.editorSetting00.TabWidth = Integer.toString( tabSize );
		IupSetAttribute( sci, "TABSIZE", GLOBAL.cString.convert( GLOBAL.editorSetting00.TabWidth ) );

		if( GLOBAL.editorSetting00.LineMargin == "ON" )
		{
			int lineCount = IupGetInt( sci, "LINECOUNT" );
			char[] lc = Integer.toString( lineCount );
			IupSetInt( sci, "MARGINWIDTH0", ( lc.length + 2 ) * Integer.atoi( size ) );
		}
		else
		{
			IupSetAttribute(sci, "MARGINWIDTH0", "0" );
		}
		
		if( GLOBAL.editorSetting00.BookmarkMargin == "ON" )
		{
			IupSetAttribute( sci, "MARGINWIDTH1", "16" );
			IupSetAttribute( sci, "MARGINTYPE1",  "SYMBOL" );
			IupSetAttribute( sci, "MARGINSENSITIVE1", "YES" );
			IupSetAttribute( sci, "MARKERDEFINE", "1=CIRCLE" );
			IupSetAttribute( sci, "MARKERSYMBOL1", "CIRCLE" );
			IupSetAttribute( sci, "MARKERFGCOLOR1", "255 128 0" );
			IupSetAttribute( sci, "MARKERBGCOLOR1", "255 255 0" );

			IupSetAttribute( sci, "MARKERDEFINE", "2=LEFTRECT" );
			IupSetAttribute( sci, "MARKERSYMBOL2", "LEFTRECT" );
			IupSetAttribute( sci, "MARKERFGCOLOR2", "0 0 255" );
			IupSetAttribute( sci, "MARKERBGCOLOR2", "255 0 0" );

			IupSetAttribute( sci, "MARKERDEFINE", "3=SHORTARROW" );
			IupSetAttribute( sci, "MARKERSYMBOL3", "SHORTARROW" );
			IupSetAttribute( sci, "MARKERFGCOLOR3", "0 0 0" );
			IupSetAttribute( sci, "MARKERBGCOLOR3", "255 0 0" );

			IupSetAttribute( sci, "MARKERDEFINE", "4=UNDERLINE" );
			IupSetAttribute( sci, "MARKERSYMBOL4", "UNDERLINE" );
			IupSetAttribute( sci, "MARKERFGCOLOR4", "255 0 0" );
			IupSetAttribute( sci, "MARKERBGCOLOR4", "255 0 0" );
		}
		else 
		{
			IupSetAttribute(sci, "MARGINWIDTH1", "0" );
		}

		if( GLOBAL.editorSetting00.FoldMargin == "ON" )
		{
			IupSetAttribute(sci, "PROPERTY", "fold=1");
			IupSetAttribute(sci, "PROPERTY", "fold.compact=0");
			IupSetAttribute(sci, "PROPERTY", "fold.comment=1");
			IupSetAttribute(sci, "PROPERTY", "fold.preprocessor=1");
			
			IupSetAttribute( sci, "MARGINWIDTH2", "20" );
			IupSetAttribute( sci, "MARGINMASKFOLDERS2",  "Yes" );
			IupSetAttribute( sci, "MARKERDEFINE", "FOLDER=PLUS");
			IupSetAttribute( sci, "MARKERDEFINE", "FOLDEROPEN=MINUS" );
			IupSetAttribute( sci, "MARKERDEFINE", "FOLDEREND=EMPTY" );
			IupSetAttribute( sci, "MARKERDEFINE", "FOLDERMIDTAIL=EMPTY" );
			IupSetAttribute( sci, "MARKERDEFINE", "FOLDEROPENMID=EMPTY" );
			IupSetAttribute( sci, "MARKERDEFINE", "FOLDERSUB=EMPTY" );
			IupSetAttribute( sci, "MARKERDEFINE", "FOLDERTAIL=EMPTY" );
			IupSetAttribute( sci, "FOLDFLAGS", "LINEAFTER_CONTRACTED" );
			IupSetAttribute( sci, "MARGINSENSITIVE2", "YES" );
		}
		else
		{
			IupSetAttribute( sci, "MARGINWIDTH2", "0" );
			IupSetAttribute( sci, "MARGINSENSITIVE2", "NO" );
		}

		//IupScintillaSendMessage( sci, 2122, Integer.atoi(GLOBAL.editorSetting00.TabWidth), 0 ); // SCI_SETINDENT = 2122
		if( GLOBAL.editorSetting00.IndentGuide == "ON" ) IupSetAttribute( sci, "INDENTATIONGUIDES", "REAL" ); else IupSetAttribute( sci, "INDENTATIONGUIDES", "NONE" );
		if( GLOBAL.editorSetting00.CaretLine == "ON" ) IupScintillaSendMessage( sci, 2096, 1, 0 ); else IupScintillaSendMessage( sci, 2096, 0, 0 ); // SCI_SETCARETLINEVISIBLE = 2096
		//if( GLOBAL.editorSetting00.WordWrap == "ON" ) IupSetAttribute( sci, "WORDWRAP", "YES" ); else IupSetAttribute( sci, "WORDWRAP", "NO" );
		if( GLOBAL.editorSetting00.WordWrap == "ON" ) IupScintillaSendMessage( sci, 2268, 1, 0 ); else IupScintillaSendMessage( sci, 2268, 0, 0 ); //#define SCI_SETWRAPMODE 2268
		if( GLOBAL.editorSetting00.TabUseingSpace == "ON" ) IupSetAttribute( sci, "USETABS", "NO" ); else IupSetAttribute( sci, "USETABS", "YES" );



		// Color
		IupScintillaSendMessage( sci, 2098, actionManager.ToolAction.convertIupColor( GLOBAL.editColor.caretLine ), 0 ); //SCI_SETCARETLINEBACK = 2098

		SendMessage( sci, 2067, true, actionManager.ToolAction.convertIupColor( GLOBAL.editColor.selectionFore ) );// SCI_SETSELFORE = 2067,
		SendMessage( sci, 2068, true, actionManager.ToolAction.convertIupColor( GLOBAL.editColor.selectionBack ) );// SCI_SETSELBACK = 2068,
		//IupScintillaSendMessage( sci, 2478, 60, 0 );// SCI_SETSELALPHA   2478
		
		IupSetAttribute( sci, "STYLEFGCOLOR33", GLOBAL.cString.convert( GLOBAL.editColor.linenumFore ) );
		IupSetAttribute( sci, "STYLEBGCOLOR33", GLOBAL.cString.convert( GLOBAL.editColor.linenumBack ) );
		// Error, Couldn't change......
		/*
		IupScintillaSendMessage( sci, 2290, 0, 0xffffff ); // SCI_SETFOLDMARGINCOLOUR = 2290,
		*/
		IupScintillaSendMessage( sci, 2069, actionManager.ToolAction.convertIupColor( GLOBAL.editColor.cursor ), 0 ); // SCI_SETCARETFORE = 2069,

		//IupSetAttribute( sci, "FOLDFLAGS", "LEVELNUMBERS" );  

		IupScintillaSendMessage( sci, 2655, 1, 0 ); // SCI_SETCARETLINEVISIBLEALWAYS = 2655,
		IupScintillaSendMessage( sci, 2115, 1, 0 ); // SCI_AUTOCSETIGNORECASE 2115
		IupScintillaSendMessage( sci, 2118, 0, 0 ); // SCI_AUTOCSETAUTOHIDE 2118
		IupScintillaSendMessage( sci, 2660, 1, 0 ); //SCI_AUTOCSETORDER 2660

		IupSetInt( sci, "AUTOCMAXHEIGHT", 15 );


		// Autocompletion XPM Image
		version( Windows )
		{
			IupScintillaSendMessage( sci, 2405, 0, cast(int) XPM.private_method_xpm.ptr );
			IupScintillaSendMessage( sci, 2405, 1, cast(int) XPM.protected_method_xpm.ptr ); // SCI_REGISTERIMAGE = 2405
			IupScintillaSendMessage( sci, 2405, 2, cast(int) XPM.public_method_xpm.ptr ); // SCI_REGISTERIMAGE = 2405

			IupScintillaSendMessage( sci, 2405, 3, cast(int) XPM.private_variable_xpm.ptr ); // SCI_REGISTERIMAGE = 2405
			IupScintillaSendMessage( sci, 2405, 4, cast(int) XPM.protected_variable_xpm.ptr ); // SCI_REGISTERIMAGE = 2405
			IupScintillaSendMessage( sci, 2405, 5, cast(int) XPM.public_variable_xpm.ptr ); // SCI_REGISTERIMAGE = 2405
			
			IupScintillaSendMessage( sci, 2405, 6, cast(int) XPM.class_private_obj_xpm.ptr ); // SCI_REGISTERIMAGE = 2405
			IupScintillaSendMessage( sci, 2405, 7, cast(int) XPM.class_protected_obj_xpm.ptr ); // SCI_REGISTERIMAGE = 2405
			IupScintillaSendMessage( sci, 2405, 8, cast(int) XPM.class_obj_xpm.ptr ); // SCI_REGISTERIMAGE = 2405
			
			IupScintillaSendMessage( sci, 2405, 9, cast(int) XPM.struct_private_obj_xpm.ptr ); // SCI_REGISTERIMAGE = 2405
			IupScintillaSendMessage( sci, 2405, 10, cast(int) XPM.struct_protected_obj_xpm.ptr ); // SCI_REGISTERIMAGE = 2405
			IupScintillaSendMessage( sci, 2405, 11, cast(int) XPM.struct_obj_xpm.ptr ); // SCI_REGISTERIMAGE = 2405
			
			IupScintillaSendMessage( sci, 2405, 12, cast(int) XPM.enum_private_obj_xpm.ptr ); // SCI_REGISTERIMAGE = 2405
			IupScintillaSendMessage( sci, 2405, 13, cast(int) XPM.enum_protected_obj_xpm.ptr ); // SCI_REGISTERIMAGE = 2405
			IupScintillaSendMessage( sci, 2405, 14, cast(int) XPM.enum_obj_xpm.ptr ); // SCI_REGISTERIMAGE = 2405
			
			IupScintillaSendMessage( sci, 2405, 15, cast(int) XPM.union_private_obj_xpm.ptr ); // SCI_REGISTERIMAGE = 2405
			IupScintillaSendMessage( sci, 2405, 16, cast(int) XPM.union_protected_obj_xpm.ptr ); // SCI_REGISTERIMAGE = 2405
			IupScintillaSendMessage( sci, 2405, 17, cast(int) XPM.union_obj_xpm.ptr ); // SCI_REGISTERIMAGE = 2405

			IupScintillaSendMessage( sci, 2405, 18, cast(int) XPM.parameter_xpm.ptr ); // SCI_REGISTERIMAGE = 2405
			IupScintillaSendMessage( sci, 2405, 19, cast(int) XPM.enum_member_obj_xpm.ptr ); // SCI_REGISTERIMAGE = 2405
			IupScintillaSendMessage( sci, 2405, 20, cast(int) XPM.alias_obj_xpm.ptr ); // SCI_REGISTERIMAGE = 2405

			IupScintillaSendMessage( sci, 2405, 21, cast(int) XPM.normal_xpm.ptr ); // SCI_REGISTERIMAGE = 2405
			IupScintillaSendMessage( sci, 2405, 22, cast(int) XPM.import_xpm.ptr ); // SCI_REGISTERIMAGE = 2405
			IupScintillaSendMessage( sci, 2405, 23, cast(int) XPM.autoWord_xpm.ptr ); // SCI_REGISTERIMAGE = 2405

			IupScintillaSendMessage( sci, 2405, 24, cast(int) XPM.namespace_obj_xpm.ptr ); // SCI_REGISTERIMAGE = 2405
		}
		else
		{
			IupScintillaSendMessage( sci, 2624, 16, 0 ); // SCI_RGBAIMAGESETWIDTH 2624
			IupScintillaSendMessage( sci, 2625, 16, 0 ); // SCI_RGBAIMAGESETHEIGHT 2625

			// SCI_REGISTERRGBAIMAGE 2627
			IupScintillaSendMessage( sci, 2627, 0, cast(int) XPM.private_method_rgba.toStringz );
			IupScintillaSendMessage( sci, 2627, 1, cast(int) XPM.protected_method_rgba.toStringz ); 
			IupScintillaSendMessage( sci, 2627, 2, cast(int) XPM.public_method_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627

			IupScintillaSendMessage( sci, 2627, 3, cast(int) XPM.private_variable_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 4, cast(int) XPM.protected_variable_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 5, cast(int) XPM.public_variable_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627
			
			IupScintillaSendMessage( sci, 2627, 6, cast(int) XPM.class_private_obj_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 7, cast(int) XPM.class_protected_obj_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 8, cast(int) XPM.class_obj_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627
			
			IupScintillaSendMessage( sci, 2627, 9, cast(int) XPM.struct_private_obj_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 10, cast(int) XPM.struct_protected_obj_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 11, cast(int) XPM.struct_obj_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627
			
			IupScintillaSendMessage( sci, 2627, 12, cast(int) XPM.enum_private_obj_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 13, cast(int) XPM.enum_protected_obj_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 14, cast(int) XPM.enum_obj_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627
			
			IupScintillaSendMessage( sci, 2627, 15, cast(int) XPM.union_private_obj_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 16, cast(int) XPM.union_protected_obj_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 17, cast(int) XPM.union_obj_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627

			IupScintillaSendMessage( sci, 2627, 18, cast(int) XPM.parameter_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 19, cast(int) XPM.enum_member_obj_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 20, cast(int) XPM.alias_obj_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627

			IupScintillaSendMessage( sci, 2627, 21, cast(int) XPM.normal_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 22, cast(int) XPM.import_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 23, cast(int) XPM.autoWord_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627

			IupScintillaSendMessage( sci, 2627, 24, cast(int) XPM.namespace_obj_xpm.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627
		}
	}
}




extern(C)
{
	int marginclick_cb( Ihandle* ih, int margin, int line, char* status )
	{
		char[] statusString = fromStringz( status ).dup;
		
		switch( margin )
		{
			case 1:
				// With control
				if( statusString[1] == 'C' ) 
				{
					uint state = IupGetIntId( ih, "MARKERGET", line );
					if( state & ( 1 << 2 ) )
					{
						IupScintillaSendMessage( ih, 2044, line, cast(int) 2 ); // #define SCI_MARKERDELETE 2044
						GLOBAL.debugPanel.removeBP( actionManager.ScintillaAction.getActiveCScintilla.getFullPath, Integer.toString( ++line ) );
					}
					else
					{
						IupScintillaSendMessage( ih, 2043, line, cast(int) 2 ); // #define SCI_MARKERADD 2043
						GLOBAL.debugPanel.addBP( actionManager.ScintillaAction.getActiveCScintilla.getFullPath, Integer.toString( ++line ) );
					}
					break;
				}
			
				
				if( IupGetIntId( ih, "MARKERGET", line ) & 2 )
				{
					IupSetIntId( ih, "MARKERDELETE", line, 1 );
				}
				else
				{
					IupSetIntId( ih, "MARKERADD", line, 1 );
				}
				break;
				
			case 2:
				IupSetfAttribute( ih, "FOLDTOGGLE", "%d", line );
				break;
				
			default:
		}

		return IUP_DEFAULT;
	}

	int savePoint_cb( Ihandle *ih, int status )
	{
		char[] _title = fromStringz( IupGetAttribute( ih, "TABTITLE" ) ).dup; 
		if( status == 0 )
		{
			if( _title.length )
			{
				if( _title[0] != '*' )
				{
					int pos = IupGetChildPos( GLOBAL.documentTabs, ih );
					if( pos > -1 )
					{
						_title = "*" ~ _title;
						auto cSci = ScintillaAction.getCScintilla( ih );
						if( cSci !is null )
						{
							IupSetAttributeId( GLOBAL.documentTabs, "TABTITLE", pos, cSci.getTitleHandle().convert( _title ) );
						}
						else
						{
							IupSetAttributeId( GLOBAL.documentTabs, "TABTITLE", pos, GLOBAL.cString.convert( _title ) );
						}
					}
				}
			}
		}
		else
		{
			if( _title.length )
			{
				if( _title[0] == '*' )
				{
					int pos = IupGetChildPos( GLOBAL.documentTabs, ih );
					if( pos > -1 )
					{
						_title = _title[1..length];
						auto cSci = ScintillaAction.getCScintilla( ih );
						if( cSci !is null )
						{
							IupSetAttributeId( GLOBAL.documentTabs, "TABTITLE", pos, cSci.getTitleHandle().convert( _title ) );
						}
						else
						{
							IupSetAttributeId( GLOBAL.documentTabs, "TABTITLE", pos, GLOBAL.cString.convert( _title ) );
						}						
					}
				}
			}
		}

		return IUP_DEFAULT;
	}

	int CScintilla_valuechanged_cb( Ihandle* ih )
	{
		actionManager.StatusBarAction.update();

		return IUP_DEFAULT;
	}

	// mouse button
	int button_cb( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		if( pressed == 0 ) //release
		{
			char[] s = fromStringz( status );

			// "Goto Defintion":
			if( s[1] == 'C' )
			{
				if( button == '1' )	AutoComplete.toDefintionAndType( true );
			}
			
			actionManager.StatusBarAction.update();
		}
		
		return IUP_DEFAULT;
	}

	int CScintilla_keyany_cb( Ihandle *ih, int c ) 
	{
		/*
		Stdout( "Keycode: " );
		Stdout( c ).newline;
		*/

		AutoComplete.bAutocompletionPressEnter = false;
		
		if( c == 13 ) AutoComplete.bEnter = true; else AutoComplete.bEnter = false;

		if( c == 65307 ) // ESC
		{
			if( fromStringz( IupGetAttribute( ih, "AUTOCACTIVE" ) ) == "YES" ) IupSetAttribute( ih, "AUTOCCANCEL", "YES" );
		}

		foreach( ShortKey sk; GLOBAL.shortKeys )
		{
			switch( sk.name )
			{
				case "Find/Replace":				
					if( sk.keyValue == c )
					{
						menu.findReplace_cb();
						return IUP_IGNORE;
					}
					break;
				case "Find/Replace In Files":
					if( sk.keyValue == c )
					{ 
						menu.findReplaceInFiles();
						return IUP_IGNORE;
					}
					break;
				case "Find Next":
					if( sk.keyValue == c )
					{
						menu.findNext_cb();
						return IUP_IGNORE;
					}
					break;
				case "Find Previous":
					if( sk.keyValue == c )
					{
						menu.findPrev_cb();
						return IUP_IGNORE;
					}
					break;
				case "Goto Line":
					if( sk.keyValue == c )
					{
						menu.item_goto_cb();
						return IUP_IGNORE;
					}
					break;
				case "Undo":
					if( sk.keyValue == c )
					{
						menu.undo_cb();
						return IUP_IGNORE;
					}
					break;
				case "Redo":						
					if( sk.keyValue == c )
					{
						menu.redo_cb();
						return IUP_IGNORE;
					}
					break;
				case "Goto Defintion":
					if( sk.keyValue == c )
					{
						AutoComplete.toDefintionAndType( true );
						return IUP_IGNORE;
					}
					break;
				case "Quick Run":
					if( sk.keyValue == c )
					{
						menu.quickRun_cb( null );
						return IUP_IGNORE;
					}
					break;
				case "Run":
					if( sk.keyValue == c )
					{
						menu.run_cb( null );
						return IUP_IGNORE;
					}
					break;
				case "Build":
					if( sk.keyValue == c )
					{
						menu.buildAll_cb( null );
						return IUP_IGNORE;
					}
					break;
				case "On/Off Left-side Window":
					if( sk.keyValue == c ) 
					{
						menu.outline_cb( GLOBAL.menuOutlineWindow );
						IupSetFocus( ih );
						return IUP_IGNORE;
					}
					break;
				case "On/Off Bottom-side Window":
					if( sk.keyValue == c )
					{
						menu.message_cb( GLOBAL.menuMessageWindow );
						IupSetFocus( ih );
						return IUP_IGNORE;
					}
					break;
				case "Show Type":
					if( sk.keyValue == c )
					{
						AutoComplete.toDefintionAndType( false );
						return IUP_IGNORE;
					}
					break;
				case "Reparse":
					if( sk.keyValue == c )
					{
						CScintilla cSci = actionManager.ScintillaAction.getActiveCScintilla();
						actionManager.OutlineAction.refresh( cSci.getFullPath() );
					}
					break;
				case "Save File":					
					if( sk.keyValue == c )
					{
						menu.saveFile_cb( null );
						return IUP_IGNORE;
					}
					break;
				case "Save All":
					if( sk.keyValue == c )
					{
						menu.saveAllFile_cb( null );
						return IUP_IGNORE;
					}
					break;
				case "Close File":
					if( sk.keyValue == c )
					{
						CScintilla cSci = actionManager.ScintillaAction.getActiveCScintilla();
						if( cSci !is null )	actionManager.ScintillaAction.closeDocument( cSci.getFullPath() );
					}
					break;

				case "Next Tab":
					if( sk.keyValue == c )
					{
						int count = IupGetChildCount( GLOBAL.documentTabs );
						if( count > 1 )
						{
							int id = IupGetInt( GLOBAL.documentTabs, "VALUEPOS" );
							if( id < count - 1 ) ++id; else id = 0;
							IupSetInt( GLOBAL.documentTabs, "VALUEPOS", id );
							actionManager.DocumentTabAction.tabChangePOS( GLOBAL.documentTabs, id, -1 );
						}
						return IUP_IGNORE;
					}
					break;

				case "Previous Tab":
					if( sk.keyValue == c )
					{
						int count = IupGetChildCount( GLOBAL.documentTabs );
						if( count > 1 )
						{
							int id = IupGetInt( GLOBAL.documentTabs, "VALUEPOS" );
							if( id > 0 ) --id; else id = --count;
							IupSetInt( GLOBAL.documentTabs, "VALUEPOS", id );
							actionManager.DocumentTabAction.tabChangePOS( GLOBAL.documentTabs, id, -1 );
						}
						return IUP_IGNORE;
					}
					break;

				default:
			}
		}

		return IUP_DEFAULT;
	}

	int CScintilla_AUTOCSELECTION_cb( Ihandle *ih, int pos, char* text )
	{
		//Stdout( "CScintilla_AUTOCSELECTION_cb" ).newline;
		
		AutoComplete.bEnter = false;

		AutoComplete.bAutocompletionPressEnter = true;

		return IUP_DEFAULT;
	}	

	int CScintilla_action_cb(Ihandle *ih, int insert, int pos, int length, char* _text )
	{
		//Stdout( "CScintilla_action_cb" ).newline;

		if( AutoComplete.bAutocompletionPressEnter ) return IUP_IGNORE;
		
		if( insert == 1 )
		{
			//Stdout( "text:" ~ fromStringz( _text ) ).newline;
			
			char[] text = fromStringz( _text ).dup;

			if( text.length > 1 ) return IUP_DEFAULT;
			
			switch( text )
			{
				case " ", "\t", "\n", "\r":
					break;

				default:
					//SendMessage( ih, 2003, pos, cast(int) toStringz("Mountain") ); //SCI_INSERTTEXT = 2003,

					//IupSetAttributeId( ih, "INSERT", pos, _text );
					IupScintillaSendMessage( ih, 2025, pos + text.length, 0 );// SCI_GOTOPOS = 2025,
					
					char[] list = AutoComplete.charAdd( ih, pos, text );
					
					char[] alreadyInput = AutoComplete.getWholeWordReverse( ih, pos ).reverse ~ text;

					char[][] splitWord = Util.split( alreadyInput, "." );
					if( splitWord.length == 1 ) splitWord = Util.split( alreadyInput, "->" );

					alreadyInput = splitWord[length-1];
					if( list.length )
					{
						if( fromStringz( IupGetAttribute( ih, "AUTOCACTIVE" ) ) == "YES" )
						{
							IupSetAttribute( ih, "AUTOCSELECT", GLOBAL.cString.convert( alreadyInput ) );
							if( IupGetInt( ih, "AUTOCSELECTEDINDEX" ) == -1 ) IupSetAttribute( ih, "AUTOCCANCEL", "YES" );
						}
						else
						{
							if( text == "(" )
							{
								if( fromStringz( IupGetAttribute( ih, "AUTOCACTIVE" ) ) == "YES" ) IupSetAttribute( ih, "AUTOCCANCEL", "YES" );

								IupScintillaSendMessage( ih, 2206, 0x707070, 0 ); //SCI_CALLTIPSETFORE 2206
								IupScintillaSendMessage( ih, 2205, 0xFFFFFF, 0 ); //SCI_CALLTIPSETBACK 2205

								IupScintillaSendMessage( ih, 2200, pos, cast(int) GLOBAL.cString.convert( list ) );
							}
							else
							{
								if( text == ">" )
								{
									if( pos > 0 )
									{
										if( fromStringz( IupGetAttributeId( ih, "CHAR", pos - 1 ) ) == "-" )
										{
											alreadyInput = alreadyInput[0..length-1];

											IupScintillaSendMessage( ih, 2100, alreadyInput.length, cast(int) GLOBAL.cString.convert( list ) );
											break;
										}
									}
								}

								IupScintillaSendMessage( ih, 2100, alreadyInput.length, cast(int) GLOBAL.cString.convert( list ) );
							}
						}
					}
			}
		}

		return IUP_DEFAULT;
	}

	// Auto Ident
	int CScintilla_caret_cb( Ihandle *ih, int lin, int col, int pos )
	{
		if( AutoComplete.bEnter )
		{
			AutoComplete.bEnter = false;
			
			//Now time to deal with auto indenting
			int lineInd = 0;
			int currentPos			= IupScintillaSendMessage( ih, 2008, 0, 0 ); // SCI_GETCURRENTPOS = 2008
			int currentLine  		= lin;//IupScintillaSendMessage( ih, 2166, currentPos, 0 ); // SCI_LINEFROMPOSITION = 2166

		   
			if( currentLine > 0 )
			{
				lineInd = IupScintillaSendMessage( ih, 2127, currentLine - 1, 0 ); // SCI_GETLINEINDENTATION = 2127
			}
		   
			if( lineInd != 0 )   // NOT in the beginning
			{
				IupScintillaSendMessage( ih, 2126, currentLine, lineInd ); // SCI_SETLINEINDENTATION = 2126
				int lineBeginPos		= IupScintillaSendMessage( ih, 2167, currentLine, 0 ); //  SCI_POSITIONFROMLINE = 2167

				char[] prevIndentText;
				char[] prevLineText		= fromStringz(IupGetAttributeId( ih, "LINE", currentLine - 1 ));
				int prevIndentPos		= IupScintillaSendMessage( ih, 2128, currentLine - 1, 0 ); // SCI_GETLINEINDENTPOSITION = 2128
				int prevLineBeginPos	= IupScintillaSendMessage( ih, 2167, currentLine - 1, 0 ); //  SCI_POSITIONFROMLINE = 2167
				
				if( prevIndentPos > prevLineBeginPos )
				{
					prevIndentText = prevLineText[0..prevIndentPos-prevLineBeginPos];
				}


				IupSetAttributeId( ih, "INSERT", lineBeginPos, GLOBAL.cString.convert( prevIndentText ) );
				IupScintillaSendMessage( ih, 2025, lineBeginPos + prevIndentText.length , 0 );// SCI_GOTOPOS = 2025,
			}
		}

		//char[] c = fromStringz( IupGetAttributeId( ih, "CHAR", pos ) );
		int close = IupScintillaSendMessage( ih, 2353, pos, 0 ); // SCI_BRACEMATCH = 2353,
		if( close > -1 )
		{
			char[] highlightPos = Integer.toString( pos ) ~ ":" ~ Integer.toString( close );
			IupSetAttribute( ih, "BRACEHIGHLIGHT", toStringz( highlightPos ) );
		}
		else
		{
			IupSetAttribute( ih, "BRACEBADLIGHT", toStringz( "-1" ) );
		}
		

		actionManager.StatusBarAction.update();

		return IUP_DEFAULT;
	}

	int CScintilla_dropfiles_cb( Ihandle *ih, char* filename, int num, int x, int y )
	{
		actionManager.ScintillaAction.openFile( fromStringz( filename ).dup  );
		if( IupGetInt( GLOBAL.dndDocumentZBox, "VALUEPOS" ) == 0 ) IupSetInt( GLOBAL.dndDocumentZBox, "VALUEPOS", 1 );
		return IUP_DEFAULT;
	}	
}