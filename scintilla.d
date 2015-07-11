module scintilla;

//Callback Function
private
{
	import iup.iup;
	import iup.iup_scintilla;

	import global, actionManager, menu;

	import Integer = tango.text.convert.Integer;
	import tango.text.convert.Layout;
	import tango.stdc.stringz;

	//import tango.io.Stdout;
}

static bool bEnter;

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

class CScintilla
{
	private:
	import 		tango.io.FilePath;
	import		tango.io.UnicodeFile, tango.text.Ascii;
	import		global;

	Ihandle*	sci;
	char[]		fullPath, title;


	void setAttribs()
	{
		if( sci == null ) return;
		
		IupSetAttribute(sci, "CLEARALL", "");


		setGlobalSetting();
	}

	public:
	int			encoding;
	
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
		IupSetCallback( sci, "CARET_CB",cast(Icallback) &CScintilla_caret_cb );
		
		
		init( _fullPath );
	}	

	~this()
	{
		IupSetHandle( toStringz(fullPath), null );
		//if( sci != null ) IupDestroy( sci );
	}

	void init( char[] _fullPath )
	{
		fullPath = _fullPath;

		scope mypath = new FilePath( fullPath );
		title = mypath.file();
		
		if( GLOBAL.documentTabs != null )
		{
			//IupSetAttribute( sci, "PADDING", "10x0" );
			//IupSetAttribute( sci, "VISIBLELINES", "0" );
			//IupSetAttribute( sci, "VISIBLECOLUMNS", null );
			
			IupSetAttribute( sci, "TABTITLE", toStringz(title) );
			if( toLower( mypath.ext )== "bas" )
			{
				IupSetAttribute( sci, "TABIMAGE", "icon_bas" );
			}
			else if( toLower( mypath.ext )== "bi" )
			{
				IupSetAttribute( sci, "TABIMAGE", "icon_bi" );
			}
			else
			{
				IupSetAttribute( sci, "TABIMAGE", "icon_document" );
			}
			IupSetHandle( toStringz(_fullPath), sci );

			IupAppend( GLOBAL.documentTabs, sci );
			IupMap( sci );
			IupRefresh( GLOBAL.documentTabs );
		}		
		setAttribs();
	}

	void setText( char[] _text )
	{
		IupSetAttribute( sci, "CLEARALL", "" );
		IupSetAttribute(sci, "INSERT0", toStringz(_text) );
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
		return title;
	}

	char[] getFullPath()
	{
		return fullPath;
	}

	void rename( char[] newFullPath )
	{
		// Remove Old Handle
		IupSetHandle( fullPath.ptr, null );
		GLOBAL.scintillaManager.remove( fullPath );

		fullPath = newFullPath;
		
		scope mypath = new FilePath( fullPath );
		title = mypath.file();

		int pos = IupGetChildPos( GLOBAL.documentTabs, sci );
		if( pos > -1 )
		{
			IupSetAttributeId( GLOBAL.documentTabs, "TABTITLE", pos, title.ptr );
		}		
		IupSetHandle( fullPath.ptr, sci );

		GLOBAL.scintillaManager[fullPath] = this;

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
					if( pos > -1 ) IupSetAttributeId( GLOBAL.documentTabs, "TABTITLE", pos, toStringz(title) );
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

		IupSetAttribute(sci, "KEYWORDS0", toStringz(GLOBAL.KEYWORDS[0]) );
		IupSetAttribute(sci, "KEYWORDS1", toStringz(GLOBAL.KEYWORDS[1]) );
		IupSetAttribute(sci, "KEYWORDS2", toStringz(GLOBAL.KEYWORDS[2]) );
		IupSetAttribute(sci, "KEYWORDS3", toStringz(GLOBAL.KEYWORDS[3]) );

		IupSetAttribute( sci, "STYLEFONT32", toStringz(GLOBAL.editFont.name) );
		IupSetAttribute( sci, "STYLEFONTSIZE32", toStringz(GLOBAL.editFont.size) );
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

		// Set Keywords to Bold
		IupSetAttribute(sci, "STYLEBOLD3", "YES");

	
		IupSetAttribute(sci, "STYLEHOTSPOT6", "YES");


		IupSetAttribute( sci, "STYLEBOLD32", GLOBAL.editFont.bold == "ON" ? toStringz("YES") : toStringz("NO") );
		IupSetAttribute( sci, "STYLEITALIC32", GLOBAL.editFont.italic == "ON" ? toStringz("YES") : toStringz("NO") );
		IupSetAttribute( sci, "STYLEUNDERLINE32", GLOBAL.editFont.underline == "ON" ? toStringz("YES") : toStringz("NO") );
		IupSetAttribute( sci, "FGCOLOR", toStringz(GLOBAL.editFont.foreColor) );
		IupSetAttribute( sci, "BGCOLOR", toStringz(GLOBAL.editFont.backColor) );

		int tabSize = Integer.atoi( GLOBAL.editorSetting00.TabWidth );
		GLOBAL.editorSetting00.TabWidth = Integer.toString( tabSize );
		IupSetAttribute( sci, "TABSIZE", toStringz(GLOBAL.editorSetting00.TabWidth) );

		if( GLOBAL.editorSetting00.LineMargin == "ON" )
		{
			int lineCount = IupGetInt( sci, "LINECOUNT" );
			lineCount = ( lineCount / 10  + 1 ) * 12;
			if( lineCount > 50 ) IupSetInt( sci, "MARGINWIDTH0", lineCount );else IupSetInt( sci, "MARGINWIDTH0", 50 );
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

			// Bookmark color
			IupSetAttribute( sci, "MARKERFGCOLOR1", "255 128 0" );
			IupSetAttribute( sci, "MARKERBGCOLOR1", "255 255 0" );
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
		if( GLOBAL.editorSetting00.WordWrap == "ON" ) IupSetAttribute( sci, "WORDWRAP", "YES" ); else IupSetAttribute( sci, "WORDWRAP", "NO" );
		if( GLOBAL.editorSetting00.TabUseingSpace == "ON" ) IupSetAttribute( sci, "USETABS", "NO" ); else IupSetAttribute( sci, "USETABS", "YES" );


		// Color
		IupScintillaSendMessage( sci, 2098, actionManager.ToolAction.convertIupColor( GLOBAL.editColor.caretLine ), 0 ); //SCI_SETCARETLINEBACK = 2098

		// Error, always black......
		/*
		IupScintillaSendMessage( sci, 2067, true, actionManager.ToolAction.convertIupColor( GLOBAL.editColor.selectionFore ) );// SCI_SETSELFORE = 2067,
		IupScintillaSendMessage( sci, 2068, true, actionManager.ToolAction.convertIupColor( GLOBAL.editColor.selectionBack ) );// SCI_SETSELBACK = 2068,
		//IupScintillaSendMessage( sci, 2478, 60, 0 );// SCI_SETSELALPHA   2478
		*/
		IupSetAttribute( sci, "STYLEFGCOLOR33", toStringz(GLOBAL.editColor.linenumFore) );
		IupSetAttribute( sci, "STYLEBGCOLOR33", toStringz(GLOBAL.editColor.linenumBack) );
		// Error, Couldn't change......
		/*
		IupScintillaSendMessage( sci, 2290, 0, 0xffffff ); // SCI_SETFOLDMARGINCOLOUR = 2290,
		*/
		IupScintillaSendMessage( sci, 2069, actionManager.ToolAction.convertIupColor( GLOBAL.editColor.cursor ), 0 ); // SCI_SETCARETFORE = 2069,

		//IupSetAttribute( sci, "FOLDFLAGS", "LEVELNUMBERS" );  
	}


}


extern(C)
{
	int marginclick_cb( Ihandle* ih, int margin, int line, char* status )
	{
		switch( margin )
		{
			case 1:
				if( IupGetIntId( ih, "MARKERGET", line ) & 2 )
				{
					IupSetIntId( ih, "MARKERDELETE", line, 1 );
				}
				else
				{
					IupSetIntId( ih, "MARKERADD", line, 1 );
				}
				//IupMessage("MARK",IupGetAttributeId( ih, "MARKERGET", line ) );
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
		char[] _title = fromStringz( IupGetAttribute( ih, "TABTITLE" ) ); 
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
						IupSetAttributeId( GLOBAL.documentTabs, "TABTITLE", pos, toStringz(_title) );
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
						IupSetAttributeId( GLOBAL.documentTabs, "TABTITLE", pos, toStringz(_title) );
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
			actionManager.StatusBarAction.update();
		}
		
		return IUP_DEFAULT;
	}

	int CScintilla_keyany_cb( Ihandle *ih, int c ) 
	{
		if( c == 13 ) bEnter = true; else bEnter = false;

		//Stdout( c ).newline;
		

		// CTRL+F 506870982
		
		//#define K_LCTRL    0xFFE3
		if( c == 536870982 )
			menu.findReplace_cb(); // From menu.d
		else if( c == 0xFFC0 ) //#define K_F3       0xFFC0
		{
			menu.findNext_cb(); // From menu.d
		}
		

		return IUP_DEFAULT;
	}

	// Auto Ident
	int CScintilla_caret_cb( Ihandle *ih, int lin, int col, int pos )
	{
		if( bEnter )
		{
			bEnter = false;
			
			//Now time to deal with auto indenting
			int lineInd = 0;
			int currentPos			= IupScintillaSendMessage( ih, 2008, 0, 0 ); // SCI_GETCURRENTPOS = 2008
			int currentLine  		= lin;//IupScintillaSendMessage( ih, 2166, currentPos, 0 ); // SCI_LINEFROMPOSITION = 2166

		   
			if( currentLine > 0 )
			{
				// lineInd = GetLineIndentation(currentLine - 1);
				lineInd = IupScintillaSendMessage( ih, 2127, currentLine - 1, 0 ); // SCI_GETLINEINDENTATION = 2127

				//IupMessage("lineInd",toStringz( Integer.toString(lineInd) ));
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


				IupSetAttributeId( ih, "INSERT", lineBeginPos, toStringz(prevIndentText) );
				IupScintillaSendMessage( ih, 2025, lineBeginPos + prevIndentText.length , 0 );// SCI_GOTOPOS = 2025,
			}
		}

		actionManager.StatusBarAction.update();

		return IUP_DEFAULT;
	}	
}