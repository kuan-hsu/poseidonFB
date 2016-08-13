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
	import tango.io.FilePath;
	import tango.io.Stdout;
	import tango.text.convert.Utf;
}

import		parser.autocompletion, parser.live, tools;


class CScintilla
{
	private:
	import			global, images.xpm;
	
	import 			tango.io.FilePath;
	import			tango.io.UnicodeFile;
	

	Ihandle*		sci;
	char[]			fullPath;
	CstringConvert	title;

	void getFontAndSize( int index, out char[] font, out char[] Bold, out char[] Italic, out char[] Underline, out char[] Strikeout, out char[] size )
	{
		if( GLOBAL.fonts.length > 2 )
		{
			char[][] strings = Util.split( GLOBAL.fonts[index].fontString, "," );
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

		//IupSetAttribute( sci, "CLEARALL", "" );
		setGlobalSetting( true );

		switch( GLOBAL.editorSetting00.EolType )
		{
			case "0":	IupScintillaSendMessage( sci, 2031, 0, 0 ); break;
			case "1":	IupScintillaSendMessage( sci, 2031, 1, 0 ); break;
			case "2":	IupScintillaSendMessage( sci, 2031, 2, 0 ); break;
			default:
		}		
		
	}	

	public:
	int				encoding;
	
	this()
	{
		sci = IupScintilla();
		IupSetAttribute( sci, "EXPAND", "YES" );
	}

	this( char[] _fullPath, char[] _text = null, int _encode = Encoding.UTF_8 )
	{
		sci = IupScintilla();
		IupSetAttribute( sci, "EXPAND", "YES" );
		version(Windows) IupSetAttribute( sci, "KEYSUNICODE", "YES" );

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

		setText( _text );
		setEncoding( _encode );

		// Set margin size
		int textWidth = IupScintillaSendMessage( sci, 2276, 33, cast(int) "9".ptr ); // SCI_TEXTWIDTH 2276
		if( GLOBAL.editorSetting00.LineMargin == "ON" )
		{
			int lineCount = IupGetInt( sci, "LINECOUNT" );
			char[] lc = Integer.toString( lineCount );
			if( lc.length > 6 ) IupSetInt( sci, "MARGINWIDTH0", lc.length * textWidth ); else IupSetInt( sci, "MARGINWIDTH0", 6 * textWidth );
		}
		else
		{
			IupSetAttribute( sci, "MARGINWIDTH0", "0" );
		}		
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

	void setText( char[] _text )
	{
		IupSetAttribute( sci, "CLEARALL", "" );
		IupSetAttribute( sci, "VALUE", GLOBAL.cString.convert( _text ) );
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
		
		if( upperCase(fullPath) in GLOBAL.parserManager )
		{
			auto temp = GLOBAL.parserManager[upperCase(fullPath)];
			delete temp;
			GLOBAL.parserManager.remove( upperCase(fullPath) );
			GLOBAL.outlineTree.cleanTree( fullPath );

			GLOBAL.outlineTree.loadFile( newFullPath );
		}
		else
		{
			GLOBAL.outlineTree.loadFile( newFullPath );
		}


		// Change the fileListTree's node
		int nodeCount = IupGetInt( GLOBAL.fileListTree.getTreeHandle, toStringz( "COUNT" ) );
	
		for( int id = 1; id <= nodeCount; id++ ) // include Parent "FileList" node
		{
			CScintilla _sci_node = cast(CScintilla) IupGetAttributeId( GLOBAL.fileListTree.getTreeHandle, "USERDATA", id );
			if( _sci_node == this )
			{
				IupSetAttributeId( GLOBAL.fileListTree.getTreeHandle, "TITLE", id, fullPath.ptr );
				break;
			}
		}					
	}

	bool saveFile()
	{
		try
		{
			if( FileAction.saveFile( fullPath, getText(), cast(Encoding) encoding ) )
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

	void setGlobalSetting( bool bFirstTime = false )
	{
		IupSetAttribute(sci, "LEXERLANGUAGE", "freebasic");

		IupSetAttribute(sci, "KEYWORDS0", GLOBAL.cString.convert( GLOBAL.KEYWORDS[0] ) );
		IupSetAttribute(sci, "KEYWORDS1", GLOBAL.cString.convert( GLOBAL.KEYWORDS[1] ) );
		IupSetAttribute(sci, "KEYWORDS2", GLOBAL.cString.convert( GLOBAL.KEYWORDS[2] ) );
		IupSetAttribute(sci, "KEYWORDS3", GLOBAL.cString.convert( GLOBAL.KEYWORDS[3] ) );

		char[] font, size = "10", Bold = "NO", Italic ="NO", Underline = "NO", Strikeout = "NO";
		version( Windows )
		{
			font = "Courier New";
		}
		else
		{
			font = "FreeMono";
		}

		getFontAndSize( 1, font, Bold, Italic, Underline, Strikeout, size );
		IupSetAttribute( sci, "STYLEFONT32", toStringz( font.dup ) );
		IupSetAttribute( sci, "STYLEFONTSIZE32", toStringz( size.dup ) );
		IupSetAttribute(sci, "STYLECLEARALL", "Yes");  /* sets all styles to have the same attributes as 32 */
		
		IupSetAttribute(sci, "STYLEFGCOLOR1", "0 128 0");		// SCE_B_COMMENT 1
		IupSetAttribute(sci, "STYLEFGCOLOR2", "0 128 0");		// SCE_B_NUMBER 2
		//IupSetAttribute(sci, "STYLEFGCOLOR3", "5 91 35");		// SCE_B_KEYWORD 3
		IupSetAttribute(sci, "STYLEFGCOLOR3", toStringz( GLOBAL.editColor.keyWord[0] ) );		// SCE_B_KEYWORD 3
		IupSetAttribute(sci, "STYLEFGCOLOR4", "128 0 0");		// SCE_B_STRING 4
		IupSetAttribute(sci, "STYLEFGCOLOR5", "0 0 255");		// SCE_B_PREPROCESSOR 5
		IupSetAttribute(sci, "STYLEFGCOLOR6", "160 20 20");		// SCE_B_OPERATOR 6
		/*
		IupSetAttribute(sci, "STYLEFGCOLOR7", "0 0 0");			// SCE_B_IDENTIFIER 7 usually normal color
		IupSetAttribute(sci, "STYLEFGCOLOR8", "128 0 0");		// SCE_B_DATE 8
		IupSetAttribute(sci, "STYLEFGCOLOR9", "16 108 232");	// SCE_B_STRINGEOL 9
		*/
		IupSetAttribute(sci, "STYLEFGCOLOR10", toStringz( GLOBAL.editColor.keyWord[1] ));	// SCE_B_KEYWORD2 10
		IupSetAttribute(sci, "STYLEFGCOLOR11", toStringz( GLOBAL.editColor.keyWord[2] ));	// SCE_B_KEYWORD3 11
		IupSetAttribute(sci, "STYLEFGCOLOR12", toStringz( GLOBAL.editColor.keyWord[3] ));	// SCE_B_KEYWORD4 12
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

		getFontAndSize( 10, font, Bold, Italic, Underline, Strikeout, size );
		IupSetAttribute(sci, "STYLEFGCOLOR40", "102 69 3");	
		IupSetAttribute(sci, "STYLEBGCOLOR40", "255 200 227");
		IupSetAttribute(sci, "STYLEFONT40",  toStringz( font.dup ) );
		IupSetAttribute(sci, "STYLEFONTSIZE40",  toStringz( size.dup ) );
		IupSetAttribute(sci, "STYLEFGCOLOR41", "0 0 255");	
		IupSetAttribute(sci, "STYLEBGCOLOR41", "255 255 157");
		IupSetAttribute(sci, "STYLEFONT41",  toStringz( font.dup ) );
		IupSetAttribute(sci, "STYLEFONTSIZE41",  toStringz( size.dup ) );		

		int tabSize = Integer.atoi( GLOBAL.editorSetting00.TabWidth );
		GLOBAL.editorSetting00.TabWidth = Integer.toString( tabSize );
		IupSetAttribute( sci, "TABSIZE", GLOBAL.cString.convert( GLOBAL.editorSetting00.TabWidth ) );

		if( !bFirstTime )
		{
			int textWidth = IupScintillaSendMessage( sci, 2276, 33, cast(int) "9".ptr ); // SCI_TEXTWIDTH 2276
			if( GLOBAL.editorSetting00.LineMargin == "ON" )
			{
				int lineCount = IupGetInt( sci, "LINECOUNT" );
				char[] lc = Integer.toString( lineCount );
				if( lc.length > 6 ) IupSetInt( sci, "MARGINWIDTH0", lc.length * textWidth ); else IupSetInt( sci, "MARGINWIDTH0", 6 * textWidth );
			}
			else
			{
				IupSetAttribute( sci, "MARGINWIDTH0", "0" );
			}
		}
		
		if( GLOBAL.editorSetting00.BookmarkMargin == "ON" )
		{
			/*
			IupSetAttribute( sci, "MARGINWIDTH1", "16" );
			IupSetAttribute( sci, "MARGINTYPE1",  "SYMBOL" );
			IupSetAttribute( sci, "MARGINSENSITIVE1", "YES" );
			IupSetAttribute( sci, "MARKERDEFINE", "1=CIRCLE" );
			IupSetAttribute( sci, "MARKERSYMBOL1", "CIRCLE" );
			IupSetAttribute( sci, "MARKERFGCOLOR1", "255 128 0" );
			IupSetAttribute( sci, "MARKERBGCOLOR1", "255 255 0" );
			*/
			IupSetAttribute( sci, "MARGINWIDTH1", "16" );
			IupSetAttribute( sci, "MARGINTYPE1",  "SYMBOL" );
			IupSetAttribute( sci, "MARGINSENSITIVE1", "YES" );			

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
		if( GLOBAL.editorSetting00.IndentGuide == "ON" ) IupSetAttribute( sci, "INDENTATIONGUIDES", "LOOKBOTH" ); else IupSetAttribute( sci, "INDENTATIONGUIDES", "NONE" );
		if( GLOBAL.editorSetting00.CaretLine == "ON" ) IupScintillaSendMessage( sci, 2096, 1, 0 ); else IupScintillaSendMessage( sci, 2096, 0, 0 ); // SCI_SETCARETLINEVISIBLE = 2096
		//if( GLOBAL.editorSetting00.WordWrap == "ON" ) IupSetAttribute( sci, "WORDWRAP", "YES" ); else IupSetAttribute( sci, "WORDWRAP", "NO" );
		if( GLOBAL.editorSetting00.WordWrap == "ON" ) IupScintillaSendMessage( sci, 2268, 1, 0 ); else IupScintillaSendMessage( sci, 2268, 0, 0 ); //#define SCI_SETWRAPMODE 2268
		if( GLOBAL.editorSetting00.TabUseingSpace == "ON" ) IupSetAttribute( sci, "USETABS", "NO" ); else IupSetAttribute( sci, "USETABS", "YES" );
		IupScintillaSendMessage( sci, 2106, cast(int) '^', 0 ); //#define SCI_AUTOCSETSEPARATOR 2106
		IupSetAttribute( sci, "APPENDNEWLINE", "NO" );

		/*
		SCI_SETVIEWEOL 2356
		SCI_SETVIEWWS 2021
		SCI_SETWHITESPACEFORE 2084
		SCI_SETWHITESPACEBACK 2085
		SCI_SETWHITESPACESIZE 2086
		*/
		if( GLOBAL.editorSetting00.ShowEOL == "ON" ) IupScintillaSendMessage( sci, 2356, 1, 0 ); else IupScintillaSendMessage( sci, 2356, 0, 0 );
		if( GLOBAL.editorSetting00.ShowSpace == "ON" )
		{
			IupScintillaSendMessage( sci, 2021, 1, 0 );
			IupScintillaSendMessage( sci, 2086, 2, 0 );
			IupScintillaSendMessage( sci, 2084, 1, actionManager.ToolAction.convertIupColor( "177 177 177" ) );
		}
		else
		{
			IupScintillaSendMessage( sci, 2021, 0, 0 );
		}


		// Color
		IupScintillaSendMessage( sci, 2098, actionManager.ToolAction.convertIupColor( GLOBAL.editColor.caretLine ), 0 ); //SCI_SETCARETLINEBACK = 2098

		uint alpha = Integer.atoi( GLOBAL.editColor.selAlpha );
		if( alpha > 255 || alpha <= 0 ) alpha = 255;

		if( alpha == 255 )
		{
			IupScintillaSendMessage( sci, 2067, true, actionManager.ToolAction.convertIupColor( GLOBAL.editColor.selectionFore ) );// SCI_SETSELFORE = 2067,
			IupScintillaSendMessage( sci, 2068, true, actionManager.ToolAction.convertIupColor( GLOBAL.editColor.selectionBack ) );// SCI_SETSELBACK = 2068,
		}
		else
		{
			IupScintillaSendMessage( sci, 2067, false, actionManager.ToolAction.convertIupColor( GLOBAL.editColor.selectionFore ) );// SCI_SETSELFORE = 2067,
			IupScintillaSendMessage( sci, 2068, true, actionManager.ToolAction.convertIupColor( GLOBAL.editColor.selectionBack ) );// SCI_SETSELBACK = 2068,
			IupScintillaSendMessage( sci, 2478, alpha, 0 );// SCI_SETSELALPHA   2478
		}
		
		IupSetAttribute( sci, "STYLEFGCOLOR33", GLOBAL.cString.convert( GLOBAL.editColor.linenumFore ) );
		IupSetAttribute( sci, "STYLEBGCOLOR33", GLOBAL.cString.convert( GLOBAL.editColor.linenumBack ) );
		// Error, Couldn't change......
		/*
		IupScintillaSendMessage( sci, 2290, 0, 0xffffff ); // SCI_SETFOLDMARGINCOLOUR = 2290,
		*/
		IupScintillaSendMessage( sci, 2069, actionManager.ToolAction.convertIupColor( GLOBAL.editColor.cursor ), 0 ); // SCI_SETCARETFORE = 2069,

		//IupSetAttribute( sci, "FOLDFLAGS", "LEVELNUMBERS" );  

		IupScintillaSendMessage( sci, 2655, 1, 0 ); // SCI_SETCARETLINEVISIBLEALWAYS = 2655,

		// SCI_AUTOCSETIGNORECASE 2115
		if( GLOBAL.toggleIgnoreCase == "ON" ) IupScintillaSendMessage( sci, 2115, 1, 0 ); else IupScintillaSendMessage( sci, 2115, 0, 0 );

		// SCI_AUTOCSETCASEINSENSITIVEBEHAVIOUR 2634
		if(GLOBAL.toggleCaseInsensitive == "ON" ) IupScintillaSendMessage( sci, 2634, 1, 0 ); else IupScintillaSendMessage( sci, 2634, 0, 0 );
		
		IupScintillaSendMessage( sci, 2118, 0, 0 ); // SCI_AUTOCSETAUTOHIDE 2118
		IupScintillaSendMessage( sci, 2660, 1, 0 ); //SCI_AUTOCSETORDER 2660

		IupSetAttribute( sci, "SIZE", "NULL" );
		//IupSetAttribute( sci, "VISIBLELINES", "60" );

		IupSetInt( sci, "AUTOCMAXHEIGHT", 15 );
		int columnEdge = Integer.atoi( GLOBAL.editorSetting00.ColumnEdge );
		if( columnEdge > 0 )
		{
			IupScintillaSendMessage( sci, 2363, 1, 0 );  // SCI_SETEDGEMODE 2363
			IupScintillaSendMessage( sci, 2361, columnEdge, 0 ); // SCI_SETEDGECOLUMN 2361
		}
		else
		{
			IupScintillaSendMessage( sci, 2363, 0, 0 );  // SCI_SETEDGEMODE 2363
		}
		

		// Autocompletion XPM Image
		version( none )
		{
			IupScintillaSendMessage( sci, 2405, 0, cast(int) XPM.private_variable_array_xpm.ptr );
			IupScintillaSendMessage( sci, 2405, 1, cast(int) XPM.protected_variable_array_xpm.ptr ); // SCI_REGISTERIMAGE = 2405
			IupScintillaSendMessage( sci, 2405, 2, cast(int) XPM.public_variable_array_xpm.ptr ); // SCI_REGISTERIMAGE = 2405

			IupScintillaSendMessage( sci, 2405, 3, cast(int) XPM.private_variable_xpm.ptr ); // SCI_REGISTERIMAGE = 2405
			IupScintillaSendMessage( sci, 2405, 4, cast(int) XPM.protected_variable_xpm.ptr ); // SCI_REGISTERIMAGE = 2405
			IupScintillaSendMessage( sci, 2405, 5, cast(int) XPM.public_variable_xpm.ptr ); // SCI_REGISTERIMAGE = 2405
			
			//IupScintillaSendMessage( sci, 2405, 6, cast(int) XPM.class_private_obj_xpm.ptr ); // SCI_REGISTERIMAGE = 2405
			//IupScintillaSendMessage( sci, 2405, 7, cast(int) XPM.class_protected_obj_xpm.ptr ); // SCI_REGISTERIMAGE = 2405
			IupScintillaSendMessage( sci, 2405, 8, cast(int) XPM.class_obj_xpm.ptr ); // SCI_REGISTERIMAGE = 2405
			
			IupScintillaSendMessage( sci, 2405, 9, cast(int) XPM.struct_private_obj_xpm.ptr ); // SCI_REGISTERIMAGE = 2405
			IupScintillaSendMessage( sci, 2405, 10, cast(int) XPM.struct_protected_obj_xpm.ptr ); // SCI_REGISTERIMAGE = 2405
			IupScintillaSendMessage( sci, 2405, 11, cast(int) XPM.struct_obj_xpm.ptr ); // SCI_REGISTERIMAGE = 2405
			
			//IupScintillaSendMessage( sci, 2405, 12, cast(int) XPM.enum_private_obj_xpm.ptr ); // SCI_REGISTERIMAGE = 2405
			IupScintillaSendMessage( sci, 2405, 13, cast(int) XPM.enum_protected_obj_xpm.ptr ); // SCI_REGISTERIMAGE = 2405
			IupScintillaSendMessage( sci, 2405, 14, cast(int) XPM.enum_obj_xpm.ptr ); // SCI_REGISTERIMAGE = 2405
			
			IupScintillaSendMessage( sci, 2405, 15, cast(int) XPM.union_private_obj_xpm.ptr ); // SCI_REGISTERIMAGE = 2405
			IupScintillaSendMessage( sci, 2405, 16, cast(int) XPM.union_protected_obj_xpm.ptr ); // SCI_REGISTERIMAGE = 2405
			IupScintillaSendMessage( sci, 2405, 17, cast(int) XPM.union_obj_xpm.ptr ); // SCI_REGISTERIMAGE = 2405

			IupScintillaSendMessage( sci, 2405, 18, cast(int) XPM.parameter_xpm.ptr ); // SCI_REGISTERIMAGE = 2405
			IupScintillaSendMessage( sci, 2405, 19, cast(int) XPM.enum_member_obj_xpm.ptr ); // SCI_REGISTERIMAGE = 2405
			IupScintillaSendMessage( sci, 2405, 20, cast(int) XPM.alias_obj_xpm.ptr ); // SCI_REGISTERIMAGE = 2405

			IupScintillaSendMessage( sci, 2405, 21, cast(int) XPM.normal_xpm.ptr ); // SCI_REGISTERIMAGE = 2405
			//IupScintillaSendMessage( sci, 2405, 22, cast(int) XPM.import_xpm.ptr ); // SCI_REGISTERIMAGE = 2405
			//IupScintillaSendMessage( sci, 2405, 23, cast(int) XPM.autoWord_xpm.ptr ); // SCI_REGISTERIMAGE = 2405

			IupScintillaSendMessage( sci, 2405, 24, cast(int) XPM.namespace_obj_xpm.ptr ); // SCI_REGISTERIMAGE = 2405

			IupScintillaSendMessage( sci, 2405, 25, cast(int) XPM.private_sub_xpm.ptr );
			IupScintillaSendMessage( sci, 2405, 26, cast(int) XPM.protected_sub_xpm.ptr ); // SCI_REGISTERIMAGE = 2405
			IupScintillaSendMessage( sci, 2405, 27, cast(int) XPM.public_sub_xpm.ptr ); // SCI_REGISTERIMAGE = 2405

			IupScintillaSendMessage( sci, 2405, 28, cast(int) XPM.private_fun_xpm.ptr );
			IupScintillaSendMessage( sci, 2405, 29, cast(int) XPM.protected_fun_xpm.ptr ); // SCI_REGISTERIMAGE = 2405
			IupScintillaSendMessage( sci, 2405, 30, cast(int) XPM.public_fun_xpm.ptr ); // SCI_REGISTERIMAGE = 2405

			IupScintillaSendMessage( sci, 2405, 31, cast(int) XPM.property_xpm.ptr ); // SCI_REGISTERIMAGE = 2405
			IupScintillaSendMessage( sci, 2405, 32, cast(int) XPM.property_var_xpm.ptr ); // SCI_REGISTERIMAGE = 2405

			IupScintillaSendMessage( sci, 2405, 33, cast(int) XPM.define_var_xpm.ptr ); // SCI_REGISTERIMAGE = 2405
			IupScintillaSendMessage( sci, 2405, 34, cast(int) XPM.define_fun_xpm.ptr ); // SCI_REGISTERIMAGE = 2405

			// BOOKMARK
			IupScintillaSendMessage( sci, 2049, 1, cast(int) XPM.bookmark_xpm.ptr ); // SCI_MARKERDEFINEPIXMAP 2049
		}
		else
		{
			IupScintillaSendMessage( sci, 2624, 16, 0 ); // SCI_RGBAIMAGESETWIDTH 2624
			IupScintillaSendMessage( sci, 2625, 16, 0 ); // SCI_RGBAIMAGESETHEIGHT 2625

			// SCI_REGISTERRGBAIMAGE 2627
			IupScintillaSendMessage( sci, 2627, 0, cast(int) XPM.private_variable_array_rgba.toStringz );
			IupScintillaSendMessage( sci, 2627, 1, cast(int) XPM.protected_variable_array_rgba.toStringz ); 
			IupScintillaSendMessage( sci, 2627, 2, cast(int) XPM.public_variable_array_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627

			IupScintillaSendMessage( sci, 2627, 3, cast(int) XPM.private_variable_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 4, cast(int) XPM.protected_variable_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 5, cast(int) XPM.public_variable_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627
			
			//IupScintillaSendMessage( sci, 2627, 6, cast(int) XPM.class_private_obj_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627
			//IupScintillaSendMessage( sci, 2627, 7, cast(int) XPM.class_protected_obj_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 8, cast(int) XPM.class_obj_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627
			
			IupScintillaSendMessage( sci, 2627, 9, cast(int) XPM.struct_private_obj_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 10, cast(int) XPM.struct_protected_obj_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 11, cast(int) XPM.struct_obj_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627
			
			//IupScintillaSendMessage( sci, 2627, 12, cast(int) XPM.enum_private_obj_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 13, cast(int) XPM.enum_protected_obj_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 14, cast(int) XPM.enum_obj_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627
			
			IupScintillaSendMessage( sci, 2627, 15, cast(int) XPM.union_private_obj_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 16, cast(int) XPM.union_protected_obj_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 17, cast(int) XPM.union_obj_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627

			IupScintillaSendMessage( sci, 2627, 18, cast(int) XPM.parameter_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 19, cast(int) XPM.enum_member_obj_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 20, cast(int) XPM.alias_obj_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627

			IupScintillaSendMessage( sci, 2627, 21, cast(int) XPM.normal_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627
			//IupScintillaSendMessage( sci, 2627, 22, cast(int) XPM.import_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627
			//IupScintillaSendMessage( sci, 2627, 23, cast(int) XPM.autoWord_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627

			IupScintillaSendMessage( sci, 2627, 24, cast(int) XPM.namespace_obj_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627

			IupScintillaSendMessage( sci, 2627, 25, cast(int) XPM.private_sub_rgba.toStringz );
			IupScintillaSendMessage( sci, 2627, 26, cast(int) XPM.protected_sub_rgba.toStringz ); // SCI_REGISTERIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 27, cast(int) XPM.public_sub_rgba.toStringz ); // SCI_REGISTERIMAGE = 2627
			
			IupScintillaSendMessage( sci, 2627, 28, cast(int) XPM.private_fun_rgba.toStringz );
			IupScintillaSendMessage( sci, 2627, 29, cast(int) XPM.protected_fun_rgba.toStringz ); // SCI_REGISTERIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 30, cast(int) XPM.public_fun_rgba.toStringz ); // SCI_REGISTERIMAGE = 2627
			
			IupScintillaSendMessage( sci, 2627, 31, cast(int) XPM.property_rgba.toStringz ); // SCI_REGISTERIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 32, cast(int) XPM.property_var_rgba.toStringz ); // SCI_REGISTERIMAGE = 2627
			
			IupScintillaSendMessage( sci, 2627, 33, cast(int) XPM.define_var_rgba.toStringz ); // SCI_REGISTERIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 34, cast(int) XPM.define_fun_rgba.toStringz ); // SCI_REGISTERIMAGE = 2627

			// BOOKMARK
			IupScintillaSendMessage( sci, 2626, 1, cast(int) XPM.bookmark_rgba.toStringz ); // SCI_MARKERDEFINERGBAIMAGE 2626
		}
	}
}




extern(C)
{
	private int marginclick_cb( Ihandle* ih, int margin, int line, char* status )
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

	private int savePoint_cb( Ihandle *ih, int status )
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

	private int CScintilla_valuechanged_cb( Ihandle* ih )
	{
		//actionManager.StatusBarAction.update();

		return IUP_DEFAULT;
	}

	// mouse button
	private int button_cb( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		if( pressed == 0 ) //release
		{
			char[] s = fromStringz( status );

			// "Goto Defintion":
			if( s.length > 1 )
			{
				if( s[1] == 'C' )
				{
					if( button == '1' )	AutoComplete.toDefintionAndType( true );
				}
			}
		}
		
		return IUP_DEFAULT;
	}

	private int CScintilla_keyany_cb( Ihandle *ih, int c ) 
	{
		//IupSetAttribute( GLOBAL.outputPanel, "APPEND", GLOBAL.cString.convert( "Keycode:" ~ Integer.toString( c ) ) );
		AutoComplete.bAutocompletionPressEnter = false;
		
		if( c == 13 ) AutoComplete.bEnter = true; else AutoComplete.bEnter = false;

		if( c == 65307 ) // ESC
		{
			if( fromStringz( IupGetAttribute( ih, "AUTOCACTIVE" ) ) == "YES" ) IupSetAttribute( ih, "AUTOCCANCEL", "YES" );
		}
		/+
		else
		{
			if( GLOBAL.liveLevel > 0 )
			{
				try
				{
					int		pos = ScintillaAction.getCurrentPos( ih );
					auto	cSci = ScintillaAction.getActiveCScintilla();
					int		currentLineNum = IupScintillaSendMessage( cSci.getIupScintilla, 2166, ScintillaAction.getCurrentPos( ih ), 0 ) + 1; //SCI_LINEFROMPOSITION = 2166,
					
					if( upperCase( cSci.getFullPath ) in GLOBAL.parserManager )
					{
						switch( c )
						{
							case 13:
								LiveParser.lineNumberAdd( GLOBAL.parserManager[upperCase( cSci.getFullPath )], currentLineNum );
								break;

							case 8: // BS
								int		minusCount = -1;
								char[] selectedLinCol = fromStringz( IupGetAttribute( ih, "SELECTION" ) );
								if( selectedLinCol.length )
								{
									int line1, line2, firstCommaPos = Util.index( selectedLinCol, "," ), secondCommaPos = Util.rindex( selectedLinCol, "," ), colonPos = Util.index( selectedLinCol, ":" );
									if( firstCommaPos < secondCommaPos )
									{
										// Start from 0, so +1
										line1 = Integer.atoi( selectedLinCol[0..firstCommaPos] ) + 1;
										line2 = Integer.atoi( selectedLinCol[colonPos+1..secondCommaPos] ) + 1;
										minusCount = line1 - line2;
										if( minusCount < 0 ) LiveParser.lineNumberAdd( GLOBAL.parserManager[upperCase( cSci.getFullPath )], line1, minusCount );
										break;
									}
								}
							
								int	col = IupScintillaSendMessage( ih, 2129, pos, 0 ); // SCI_GETCOLUMN 2129.
								if( col == 0 )
								{
									if( currentLineNum > 1 ) LiveParser.lineNumberAdd( GLOBAL.parserManager[upperCase( cSci.getFullPath )], currentLineNum - 1, -1 );
								}
								break;

							case 65535: // DEL
								int		minusCount = -1;
								char[] selectedLinCol = fromStringz( IupGetAttribute( ih, "SELECTION" ) );
								if( selectedLinCol.length )
								{
									int line1, line2, firstCommaPos = Util.index( selectedLinCol, "," ), secondCommaPos = Util.rindex( selectedLinCol, "," ), colonPos = Util.index( selectedLinCol, ":" );
									if( firstCommaPos < secondCommaPos )
									{
										// Start from 0, so +1
										line1 = Integer.atoi( selectedLinCol[0..firstCommaPos] ) + 1;
										line2 = Integer.atoi( selectedLinCol[colonPos+1..secondCommaPos] ) + 1;
										//IupMessage( "", toStringz( Integer.toString( line1 ) ~ " : " ~ Integer.toString( line2 ) ) );
										minusCount = line1 - line2;
										if( minusCount < 0 ) LiveParser.lineNumberAdd( GLOBAL.parserManager[upperCase( cSci.getFullPath )], line1, minusCount );
										break;
									}
								}
							
								char[] nextChar = fromStringz( IupGetAttributeId( ih, "CHAR", pos ) );
								if( nextChar == "\n" )
								{
									if( currentLineNum > 1 ) LiveParser.lineNumberAdd( GLOBAL.parserManager[upperCase( cSci.getFullPath )], currentLineNum, -1 );
								}
								break;
								
							default:
						}
					}
				}
				catch( Exception e ){}
			}
		}
		+/
		

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
						GLOBAL.outlineTree.softRefresh( cSci );
						//actionManager.OutlineAction.refresh( cSci.getFullPath() );
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
				case "New Tab":
					if( sk.keyValue == c )
					{
						menu.newFile_cb( ih );
						return IUP_IGNORE;
					}
					break;
				case "Autocomplete":
					if( sk.keyValue == c )
					{
						char[] 	alreadyInput;
						char[]	lastChar;
						int		pos = actionManager.ScintillaAction.getCurrentPos( ih );
						int		dummyHeadPos;

						if( pos > 0 ) lastChar = fromStringz( IupGetAttributeId( ih, "CHAR", pos - 1 ) ).dup; else return IUP_IGNORE;

						if( pos > 1 )
						{
							if( lastChar == ">" )
							{
								if( fromStringz( IupGetAttributeId( ih, "CHAR", pos - 2 ) ) == "-" ) alreadyInput = AutoComplete.getWholeWordReverse( ih, pos - 2, dummyHeadPos ).reverse ~ "->";
							}
						}

						if( lastChar == "(" ) alreadyInput = AutoComplete.getWholeWordReverse( ih, pos - 1, dummyHeadPos ).reverse; else alreadyInput = AutoComplete.getWholeWordReverse( ih, pos, dummyHeadPos ).reverse;
					
						try
						{
							if( alreadyInput.length ) AutoComplete.callAutocomplete( ih, pos - 1, lastChar, alreadyInput ~ " " );
						}
						catch( Exception e )
						{
							debug IupMessage( "Error", toStringz( e.toString ) );
						}

						return IUP_IGNORE;
					}
					break;
					
				default:
			}
		}

		return IUP_DEFAULT;
	}

	private int CScintilla_AUTOCSELECTION_cb( Ihandle *ih, int pos, char* text )
	{
		//Stdout( "CScintilla_AUTOCSELECTION_cb" ).newline;
		
		AutoComplete.bEnter = false;

		AutoComplete.bAutocompletionPressEnter = true;
			
		char[] _text = fromStringz( text ).dup;

		if( GLOBAL.toggleShowListType == "ON" )
		{
			int colonPos = Util.rindex( _text, "::" );
			if( colonPos < _text.length ) _text = _text[0..colonPos];
			_text = Util.trim( _text );
		}
		
		if( _text.length )
		{
			scope textCovert = new CstringConvert;
			
			if( _text[length-1] == ')' )
			{
				int _pos = Util.index( _text, "(" );
				if( _pos < _text.length )
				{
					IupSetAttribute( ih, "AUTOCCANCEL", "YES" );
					IupScintillaSendMessage( ih, 2026, pos, 0 ); //SCI_SETANCHOR = 2026
					IupSetAttribute( ih , "SELECTEDTEXT", textCovert.convert( _text[0.._pos].dup ) );
					return IUP_DEFAULT;
				}
			}

			if( GLOBAL.toggleShowListType == "ON" )
			{
				IupSetAttribute( ih, "AUTOCCANCEL", "YES" );
				IupScintillaSendMessage( ih, 2026, pos, 0 ); //SCI_SETANCHOR = 2026

				if( IupGetAttribute( ih , "SELECTEDTEXT" ) == null )
				{
					IupSetAttribute( ih , "PREPEND", textCovert.convert( _text.dup ) );
				}
				else
				{
					IupSetAttribute( ih , "SELECTEDTEXT", textCovert.convert( _text.dup ) );
				}
			}
		}

		return IUP_DEFAULT;
	}

	private int CScintilla_action_cb( Ihandle *ih, int insert, int pos, int length, char* _text )
	{
		//static bool bWithoutList;
		//static int	prevPos;


		if( GLOBAL.liveLevel > 0 )
		{
			try
			{
				char[]	dText = fromStringz( _text );
				auto	cSci = ScintillaAction.getActiveCScintilla();
				int		currentLineNum = IupScintillaSendMessage( cSci.getIupScintilla, 2166, pos, 0 ) + 1; //SCI_LINEFROMPOSITION = 2166,				

				if( insert == 1 )
				{
					if( upperCase( cSci.getFullPath ) in GLOBAL.parserManager )
					{
						int countNewLine = Util.count( dText, "\n" );
						if( countNewLine > 0 )
						{
							int lineHeadPos = IupScintillaSendMessage( ih, 2167, currentLineNum - 1, 0 ); //SCI_POSITIONFROMLINE 2167


							char[] blockText;
							for( int i = lineHeadPos; i < pos; ++ i )
								blockText = fromStringz( IupGetAttributeId( cSci.getIupScintilla, "CHAR", i ) );
							
							/*
							IupSetInt( ih, "TARGETSTART", lineHeadPos );
							IupSetInt( ih, "TARGETEND", pos );							
							scope blockText = new char[pos-lineHeadPos];
							IupScintillaSendMessage( cSci.getIupScintilla, 2687, 0, cast(int) blockText.ptr );// SCI_GETTARGETTEXT 2687
							*/

							if( !( Util.trim( blockText ).length ) )
							{
								LiveParser.lineNumberAdd( GLOBAL.parserManager[upperCase( cSci.getFullPath )], currentLineNum - 1, countNewLine );
							}
							else
							{
								LiveParser.lineNumberAdd( GLOBAL.parserManager[upperCase( cSci.getFullPath )], currentLineNum, countNewLine );
							}
						}
					}
				}
				else
				{
					if( upperCase( cSci.getFullPath ) in GLOBAL.parserManager )
					{
						int		minusCount = -1;
						char[] selectedLinCol = fromStringz( IupGetAttribute( ih, "SELECTION" ) );
						if( selectedLinCol.length )
						{
							int line1, line2, firstCommaPos = Util.index( selectedLinCol, "," ), secondCommaPos = Util.rindex( selectedLinCol, "," ), colonPos = Util.index( selectedLinCol, ":" );
							if( firstCommaPos < secondCommaPos )
							{
								// Start from 0, so +1
								line1 = Integer.atoi( selectedLinCol[0..firstCommaPos] ) + 1;
								line2 = Integer.atoi( selectedLinCol[colonPos+1..secondCommaPos] ) + 1;
								minusCount = line1 - line2;
								if( minusCount < 0 ) LiveParser.lineNumberAdd( GLOBAL.parserManager[upperCase( cSci.getFullPath )], line1, minusCount );
							}
						}
						else
						{
							if( fromStringz( IupGetAttributeId( ih, "CHAR", pos ) ) == "\n" )
							{
								if( currentLineNum >= 0 ) LiveParser.lineNumberAdd( GLOBAL.parserManager[upperCase( cSci.getFullPath )], currentLineNum, -1 );
							}
						}
					}
				}
			}
			catch( Exception e ){}
		}

		
		// If un-release the key, cancel
		if( !GLOBAL.bKeyUp ) return IUP_DEFAULT;else GLOBAL.bKeyUp = false;
		
		if( GLOBAL.enableParser != "ON" ) return IUP_DEFAULT;
		
		// If GLOBAL.autoCompletionTriggerWordCount = 0, cancel
		if( GLOBAL.autoCompletionTriggerWordCount <= 0 ) return IUP_DEFAULT;

		if( AutoComplete.bAutocompletionPressEnter ) return IUP_IGNORE;

		if( ScintillaAction.isComment( ih, pos ) ) return IUP_DEFAULT;

		if( insert == 1 )
		{
			if( length > 1 ) return IUP_DEFAULT;

			int dummyHeadPos;
			// Below code are fixed because of IUP DLL10 and D 1.076
			char[] text;
			text ~= _text[0];
			
			switch( text )
			{
				case " ", "\n", "\t", "\r", ")":
					IupSetAttribute( ih, "AUTOCCANCEL", "YES" );
					//bWithoutList = false;
					break;

				default:
					char[]	alreadyInput;
					bool	bDot, bOpenParen;

					if( text == ">" )
					{
						if( pos > 0 )
						{
							if( fromStringz( IupGetAttributeId( ih, "CHAR", pos - 1 ) ) == "-" )
							{
								//IupMessage("POINTER","");
								alreadyInput = AutoComplete.getWholeWordReverse( ih, pos - 1, dummyHeadPos ).reverse ~ "->";
								bDot = true;
								//bWithoutList = false;
							}
						}
					}
					else if( text == "." )
					{
						bDot = true;
					}
					else if( text == "(" )
					{
						bOpenParen = true;
					}
					
					/*
					if( bWithoutList )
					{
						if( pos > 0 )
						{
							if( prevPos == pos - 1 )
							{
								break;
							}
							else
							{
								bWithoutList = false;
							}
						}
					}
					*/

					if( !alreadyInput.length ) alreadyInput = AutoComplete.getWholeWordReverse( ih, pos, dummyHeadPos ).reverse ~ text;

					if( !bDot && !bOpenParen )
					{
						if( alreadyInput.length < GLOBAL.autoCompletionTriggerWordCount ) break;
					}

					try
					{
						/*bWithoutList = */AutoComplete.callAutocomplete( ih, pos, text, alreadyInput );
					}
					catch( Exception e )
					{

					}
			}
		}

		//prevPos = pos;
		return IUP_DEFAULT;
	}


	// Auto Ident
	private int CScintilla_caret_cb( Ihandle *ih, int lin, int col, int pos )
	{
		if( AutoComplete.bEnter )
		{
			AutoComplete.bEnter = false;

			bool bAutoInsert;
			if( GLOBAL.editorSetting00.AutoEnd == "ON" )
			{			
				if( pos == IupScintillaSendMessage( ih, 2136, lin, 0 ) ) bAutoInsert = true;// #define SCI_GETLINEENDPOSITION 2136 )
			}

			if( GLOBAL.editorSetting00.AutoIndent == "ON" )
			{
				//Now time to deal with auto indenting
				int lineInd = 0;

				if( lin > 0 ) lineInd = IupScintillaSendMessage( ih, 2127, lin - 1, 0 ); // SCI_GETLINEINDENTATION = 2127
			   
				if( lineInd != 0 )   // NOT in the beginning
				{
					IupScintillaSendMessage( ih, 2126, lin, lineInd ); // SCI_SETLINEINDENTATION = 2126
					int changeLinePos = IupScintillaSendMessage( ih, 2128, lin, 0 );
					IupScintillaSendMessage( ih, 2025, changeLinePos , 0 );// SCI_GOTOPOS = 2025,
				}
			}

			if( bAutoInsert )
			{
				char[] insertEndText = AutoComplete.InsertEnd( ih, lin, pos );
				if( insertEndText.length ) IupSetAttributeId( ih, "INSERT", -1, GLOBAL.cString.convert( insertEndText ) );
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
			close = IupScintillaSendMessage( ih, 2353, pos - 1, 0 ); // SCI_BRACEMATCH = 2353,
			if( close > -1 )
			{
				char[] highlightPos = Integer.toString( pos - 1 ) ~ ":" ~ Integer.toString( close );
				IupSetAttribute( ih, "BRACEHIGHLIGHT", toStringz( highlightPos ) );
			}
			else
			{
				IupSetAttribute( ih, "BRACEBADLIGHT", toStringz( "-1" ) );
			}
		}
		

		actionManager.StatusBarAction.update();

		return IUP_DEFAULT;
	}

	private int CScintilla_dropfiles_cb( Ihandle *ih, char* filename, int num, int x, int y )
	{
		scope f = new FilePath( fromStringz( filename ) );

		if( f.name == ".poseidon" )
		{
			char[] dir = f.path;
			if( dir.length ) dir = dir[0..length-1]; else return IUP_DEFAULT; // Remove tail '/'
			GLOBAL.projectTree.openProject( dir );
		}
		else
		{
			actionManager.ScintillaAction.openFile( fromStringz( filename ).dup  );
			if( IupGetInt( GLOBAL.dndDocumentZBox, "VALUEPOS" ) == 0 ) IupSetInt( GLOBAL.dndDocumentZBox, "VALUEPOS", 1 );
		}
		return IUP_DEFAULT;
	}	
}