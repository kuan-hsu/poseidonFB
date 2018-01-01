module scintilla;

//Callback Function
private
{
	import iup.iup;
	import iup.iup_scintilla;

	import global, actionManager, menu, tools;
	import parser.autocompletion, parser.live;

	import Integer = tango.text.convert.Integer;
	import tango.stdc.stringz;
	import tango.io.FilePath;
	import tango.text.convert.Utf;
}

class CScintilla
{
	private:
	import			images.xpm;
	import			tango.io.UnicodeFile;
	
	Ihandle*		sci;
	IupString		fullPath, title;
	int				selectedMarkerIndex;

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
				
				Bold = Italic = Underline = Strikeout = "NO";
				size = "10";

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

	void init( char[] _fullPath, int insertPos )
	{
		scope mypath = new FilePath( _fullPath );
		fullPath = _fullPath;
		title = mypath.file();
		
		if( GLOBAL.documentTabs != null )
		{
			version(FBIDE)
			{
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
					IupSetAttribute( sci, "TABIMAGE", "icon_txt" );
				}
			}
			version(DIDE)
			{
				if( lowerCase( mypath.ext )== "d" )
				{
					IupSetAttribute( sci, "TABIMAGE", "icon_bas" );
				}
				else if( lowerCase( mypath.ext )== "di" )
				{
					IupSetAttribute( sci, "TABIMAGE", "icon_bi" );
				}
				else
				{
					IupSetAttribute( sci, "TABIMAGE", "icon_txt" );
				}
			}			
			
			IupSetHandle( fullPath.toCString, sci );
			//IupSetAttribute( sci, "TABTITLE", title.toCString );

			if( insertPos == -1 )
			{
				IupAppend( GLOBAL.activeDocumentTabs, sci );
			}
			else
			{
				if( IupGetChildCount( GLOBAL.activeDocumentTabs ) > insertPos )
				{
					Ihandle* refChild = IupGetChild( GLOBAL.activeDocumentTabs, insertPos );
					IupInsert( GLOBAL.activeDocumentTabs, refChild, sci );
				}
			}
			
			IupSetAttribute( sci, "BORDER", "NO" );
			IupMap( sci );
			IupRefresh( GLOBAL.activeDocumentTabs );
			
			int newDocumentPos = IupGetChildPos( GLOBAL.activeDocumentTabs, sci );
			IupSetAttributeId( GLOBAL.activeDocumentTabs , "TABTITLE", newDocumentPos, title.toCString );
			
			// For IupFlatTabs
			IupSetAttributeId( GLOBAL.activeDocumentTabs , "TABTIP", newDocumentPos, fullPath.toCString );
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
		version(Windows) IupSetAttribute( sci, "KEYSUNICODE", "YES" );
		
		fullPath = new IupString();
		title = new IupString();
	}

	this( char[] _fullPath, char[] _text = null, int _encode = Encoding.UTF_8, int insertPos = -1 )
	{
		this();
		/*
		sci = IupScintilla();
		IupSetAttribute( sci, "EXPAND", "YES" );
		version(Windows) IupSetAttribute( sci, "KEYSUNICODE", "YES" );
		
		fullPath = new IupString();
		title = new IupString();
		*/
		IupSetAttribute( sci, "SCROLLBAR", "YES" );
		
		IupSetCallback( sci, "LINESCHANGED_CB",cast(Icallback) &CScintilla_linesChanged_cb );
		IupSetCallback( sci, "MARGINCLICK_CB",cast(Icallback) &marginclick_cb );
		IupSetCallback( sci, "BUTTON_CB",cast(Icallback) &button_cb );
		IupSetCallback( sci, "SAVEPOINT_CB",cast(Icallback) &savePoint_cb );
		IupSetCallback( sci, "K_ANY",cast(Icallback) &CScintilla_keyany_cb );
		IupSetCallback( sci, "ACTION",cast(Icallback) &CScintilla_action_cb );
		IupSetCallback( sci, "CARET_CB",cast(Icallback) &CScintilla_caret_cb );
		IupSetCallback( sci, "AUTOCSELECTION_CB",cast(Icallback) &CScintilla_AUTOCSELECTION_cb );
		IupSetCallback( sci, "DROPFILES_CB",cast(Icallback) &CScintilla_dropfiles_cb );
		IupSetCallback( sci, "ZOOM_CB",cast(Icallback) &CScintilla_zoom_cb );
		
		IupSetCallback( sci, "MOTION_CB",cast(Icallback) &CScintilla_MOTION_CB );
		
		IupSetCallback( sci, "DWELL_CB",cast(Icallback) &CScintilla_DWELL_CB );
		IupSetInt( sci, "MOUSEDWELLTIME", 1500 );

		init( _fullPath, insertPos );
		setText( _text );
		setEncoding( _encode );
		
		if( sci != null )
		{
			char[] _size = fromStringz( IupGetAttribute( sci, "SIZE" ) );
			int crossPos = Util.index( _size, "x" );
			if( crossPos < _size.length ) IupSetAttribute( sci, "SCROLLWIDTH", toStringz( _size[0..crossPos] ) );
		}		
		IupScintillaSendMessage( sci, 2516, 1, 0 ); // SCI_SETSCROLLWIDTHTRACKING 2516
		//IupScintillaSendMessage( sci, 2277, 1, 0 ); // SCI_SETENDATLASTLINE 2277
		

		// Set margin size
		int textWidth = cast(int) IupScintillaSendMessage( sci, 2276, 33, cast(int) "9".ptr ); // SCI_TEXTWIDTH 2276
		if( GLOBAL.editorSetting00.LineMargin == "ON" )
		{
			int lineCount = IupGetInt( sci, "LINECOUNT" );
			char[] lc = Integer.toString( lineCount );
			if( GLOBAL.editorSetting00.FixedLineMargin == "OFF" )
			{
				IupSetInt( sci, "MARGINWIDTH0", ( lc.length + 1 ) * textWidth );
			}
			else
			{
				if( lc.length > 5 ) IupSetInt( sci, "MARGINWIDTH0", ( lc.length + 1 )* textWidth ); else IupSetInt( sci, "MARGINWIDTH0", 6 * textWidth );
			}
		}
		else
		{
			IupSetAttribute( sci, "MARGINWIDTH0", "0" );
		}
	}	

	~this()
	{
		IupSetHandle( fullPath.toCString, null );
		
		version(FBIDE)
		{
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
						if( fn == fullPath.toDString ) IupSetInt( GLOBAL.debugPanel.getBPListHandle, "REMOVEITEM", i );
					}
				}			
			}
		}

		
		if( title !is null ) delete title;
		if( sci != null ) IupDestroy( sci );
		
		delete fullPath;
		delete title;
	}

	void setText( char[] _text )
	{
		IupSetAttribute( sci, "CLEARALL", "" );
		IupSetAttribute( sci, "VALUE", GLOBAL.cString.convert( _text.dup ) );
		
		/*
		Ihandle* clipboard = IupClipboard();
		IupSetAttribute( clipboard, "TEXT", toStringz( _text ) );
		IupSetAttribute( sci, "CLIPBOARD", "PASTE" );
		IupDestroy(clipboard);
		
		IupSetInt( sci, "FIRSTVISIBLELINE", 0 );
		IupSetInt( sci, "CARETPOS", 0 );
		*/	

		IupScintillaSendMessage( sci, 2014, 0, 0 ); // SCI_SETSAVEPOINT = 2014		
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
		return title.toDString;
	}

	IupString getTitleHandle()
	{
		return title;
	}

	char[] getFullPath()
	{
		return fullPath.toDString;
	}

	IupString getFullPath_IupString()
	{
		return fullPath;
	}
	
	void rename( char[] newFullPath )
	{
		// Remove Old Handle
		IupSetHandle( fullPath.toCString, null );
		GLOBAL.scintillaManager.remove( upperCase(fullPath.toDString) );

		fullPath = newFullPath;
		
		scope mypath = new FilePath( fullPath.toDString );
		title = mypath.file();

		int pos = IupGetChildPos( GLOBAL.activeDocumentTabs, sci );
		if( pos > -1 )
		{
			IupSetAttributeId( GLOBAL.activeDocumentTabs, "TABTITLE", pos, title.toCString );
		}		
		IupSetHandle( fullPath.toCString, sci );

		GLOBAL.scintillaManager[upperCase(fullPath.toDString)] = this;
		
		if( upperCase(fullPath.toDString) in GLOBAL.parserManager )
		{
			auto temp = GLOBAL.parserManager[upperCase(fullPath.toDString)];
			delete temp;
			GLOBAL.parserManager.remove( upperCase(fullPath.toDString) );
			GLOBAL.outlineTree.cleanTree( fullPath.toDString );

			GLOBAL.outlineTree.loadFile( newFullPath );
		}
		else
		{
			GLOBAL.outlineTree.loadFile( newFullPath );
		}


		// Change the fileListTree's node
		int nodeCount = IupGetInt( GLOBAL.fileListTree.getTreeHandle, toStringz( "COUNT" ) );
	
		for( int id = 0; id < nodeCount; id++ ) // include Parent "FileList" node
		{
			CScintilla _sci_node = cast(CScintilla) IupGetAttributeId( GLOBAL.fileListTree.getTreeHandle, "USERDATA", id );
			if( _sci_node == this )
			{
				IupSetAttributeId( GLOBAL.fileListTree.getTreeHandle, "TITLE", id, fullPath.toCString );
				break;
			}
		}					
	}

	bool saveFile()
	{
		try
		{
			if( FileAction.saveFile( fullPath.toDString, getText(), cast(Encoding) encoding ) )
			{
				//if( ScintillaAction.getModify( sci ) != 0 )
				if( ScintillaAction.getModifyByTitle( this ) )
				{
					IupScintillaSendMessage( sci, 2014, 0, 0 ); // SCI_SETSAVEPOINT = 2014
					// Auto trigger SAVEPOINT_CB........
				}
			}
		}
		catch
		{
			IupMessage("saveFile","ERROR");
			return false;
		}

		IupSetFocus( sci );
		return true;
	}

	void setGlobalSetting( bool bFirstTime = false )
	{
		scope mypath = new FilePath( fullPath.toDString );
		
		version(FBIDE)
		{
			if( lowerCase( mypath.ext ) == "bas" || lowerCase( mypath.ext ) == "bi" ) IupSetAttribute(sci, "LEXERLANGUAGE", toStringz( GLOBAL.lexer ) );
			IupSetAttribute(sci, "KEYWORDS0", GLOBAL.KEYWORDS[0].toCString );
			IupSetAttribute(sci, "KEYWORDS1", GLOBAL.KEYWORDS[1].toCString );
			IupSetAttribute(sci, "KEYWORDS2", GLOBAL.KEYWORDS[2].toCString );
			IupSetAttribute(sci, "KEYWORDS3", GLOBAL.KEYWORDS[3].toCString );
		}
		version(DIDE)
		{
			if( lowerCase( mypath.ext ) == "d" || lowerCase( mypath.ext ) == "di" ) IupSetAttribute(sci, "LEXERLANGUAGE", "d" );
			IupSetAttribute(sci, "KEYWORDS0", GLOBAL.KEYWORDS[0].toCString );
			IupSetAttribute(sci, "KEYWORDS1", GLOBAL.KEYWORDS[1].toCString );
			IupSetAttribute(sci, "KEYWORDS4", GLOBAL.KEYWORDS[2].toCString );
			IupSetAttribute(sci, "KEYWORDS5", GLOBAL.KEYWORDS[3].toCString );		
		}

		char[] font, size = "10", Bold = "NO", Italic ="NO", Underline = "NO", Strikeout = "NO";
		version( Windows )
		{
			font = "Courier New";
		}
		else
		{
			font = "Ubuntu Mono";
		}

		getFontAndSize( 1, font, Bold, Italic, Underline, Strikeout, size );

		IupSetAttribute( sci, "STYLEFONT32", toStringz( font.dup ) );
		IupSetAttribute( sci, "STYLEFONTSIZE32", toStringz( size.dup ) );
		IupSetAttribute( sci, "STYLEFGCOLOR32", GLOBAL.editColor.scintillaFore.toCString );		// 32
		IupSetAttribute( sci, "STYLEBGCOLOR32", GLOBAL.editColor.scintillaBack.toCString );		// 32
		IupSetAttribute( sci, "STYLEITALIC32", GLOBAL.cString.convert( Bold ) );
		IupSetAttribute( sci, "STYLEITALIC32", GLOBAL.cString.convert( Italic ) );
		IupSetAttribute( sci, "STYLEUNDERLINE32", GLOBAL.cString.convert( Underline ) );

		IupSetAttribute(sci, "STYLECLEARALL", "Yes");  /* sets all styles to have the same attributes as 32 */
		
		/*
		IupSetAttribute( sci, "FGCOLOR", toStringz( GLOBAL.editColor.scintillaFore.dup ) );
		IupSetAttribute( sci, "BGCOLOR", toStringz( GLOBAL.editColor.scintillaBack.dup ) );
		*/
		version(FBIDE)
		{
			IupSetAttribute( sci, "STYLEFGCOLOR1", GLOBAL.editColor.SCE_B_COMMENT_Fore.toCString );		// SCE_B_COMMENT 1
			IupSetAttribute( sci, "STYLEBGCOLOR1", GLOBAL.editColor.SCE_B_COMMENT_Back.toCString );		// SCE_B_COMMENT 1
			IupSetAttribute( sci, "STYLEFGCOLOR2", GLOBAL.editColor.SCE_B_NUMBER_Fore.toCString );		// SCE_B_NUMBER 2
			IupSetAttribute( sci, "STYLEBGCOLOR2", GLOBAL.editColor.SCE_B_NUMBER_Back.toCString );		// SCE_B_NUMBER 2
			IupSetAttribute( sci, "STYLEFGCOLOR4", GLOBAL.editColor.SCE_B_STRING_Fore.toCString );		// SCE_B_STRING 4
			IupSetAttribute( sci, "STYLEBGCOLOR4", GLOBAL.editColor.SCE_B_STRING_Back.toCString );		// SCE_B_STRING 4
			IupSetAttribute( sci, "STYLEFGCOLOR5", GLOBAL.editColor.SCE_B_PREPROCESSOR_Fore.toCString );	// SCE_B_PREPROCESSOR 5
			IupSetAttribute( sci, "STYLEBGCOLOR5", GLOBAL.editColor.SCE_B_PREPROCESSOR_Back.toCString );	// SCE_B_PREPROCESSOR 5
			IupSetAttribute( sci, "STYLEFGCOLOR6", GLOBAL.editColor.SCE_B_OPERATOR_Fore.toCString );		// SCE_B_OPERATOR 6
			IupSetAttribute( sci, "STYLEBGCOLOR6", GLOBAL.editColor.SCE_B_OPERATOR_Back.toCString );		// SCE_B_OPERATOR 6
			IupSetAttribute( sci, "STYLEFGCOLOR7", GLOBAL.editColor.SCE_B_IDENTIFIER_Fore.toCString );	// SCE_B_IDENTIFIER 7
			IupSetAttribute( sci, "STYLEBGCOLOR7", GLOBAL.editColor.SCE_B_IDENTIFIER_Back.toCString );	// SCE_B_IDENTIFIER 7
			IupSetAttribute( sci, "STYLEFGCOLOR19", GLOBAL.editColor.SCE_B_COMMENTBLOCK_Fore.toCString );// SCE_B_COMMENTBLOCK 19
			IupSetAttribute( sci, "STYLEBGCOLOR19", GLOBAL.editColor.SCE_B_COMMENTBLOCK_Back.toCString );// SCE_B_COMMENTBLOCK 19
			
			IupSetAttribute(sci, "STYLEFGCOLOR3", GLOBAL.editColor.keyWord[0].toCString );	// SCE_B_KEYWORD 3
			IupSetAttribute(sci, "STYLEFGCOLOR10", GLOBAL.editColor.keyWord[1].toCString );	// SCE_B_KEYWORD2 10
			IupSetAttribute(sci, "STYLEFGCOLOR11",  GLOBAL.editColor.keyWord[2].toCString );	// SCE_B_KEYWORD3 11
			IupSetAttribute(sci, "STYLEFGCOLOR12",  GLOBAL.editColor.keyWord[3].toCString );	// SCE_B_KEYWORD4 12
		}
		version(DIDE)
		{
			IupSetAttribute( sci, "STYLEFGCOLOR1", GLOBAL.editColor.SCE_B_COMMENT_Fore.toCString );		// SCE_D_COMMENT 1
			IupSetAttribute( sci, "STYLEBGCOLOR1", GLOBAL.editColor.SCE_B_COMMENT_Back.toCString );		// SCE_D_COMMENT 1
			IupSetAttribute( sci, "STYLEFGCOLOR2", GLOBAL.editColor.SCE_B_COMMENT_Fore.toCString );		// SCE_D_COMMENTLINE 2
			IupSetAttribute( sci, "STYLEBGCOLOR2", GLOBAL.editColor.SCE_B_COMMENT_Back.toCString );		// SCE_D_COMMENTLINE 2
			IupSetAttribute( sci, "STYLEFGCOLOR3", GLOBAL.editColor.SCE_B_COMMENT_Fore.toCString );		// SCE_D_COMMENTDOC 3
			IupSetAttribute( sci, "STYLEBGCOLOR3", GLOBAL.editColor.SCE_B_COMMENT_Back.toCString );		// SCE_D_COMMENTDOC 3
			
			IupSetAttribute( sci, "STYLEFGCOLOR4", GLOBAL.editColor.SCE_B_COMMENTBLOCK_Fore.toCString );		// SCE_D_COMMENTNESTED 4
			IupSetAttribute( sci, "STYLEBGCOLOR4", GLOBAL.editColor.SCE_B_COMMENTBLOCK_Back.toCString );		// SCE_D_COMMENTNESTED 4
			
			IupSetAttribute( sci, "STYLEFGCOLOR5", GLOBAL.editColor.SCE_B_NUMBER_Fore.toCString );		// SCE_D_NUMBER 5
			IupSetAttribute( sci, "STYLEBGCOLOR5", GLOBAL.editColor.SCE_B_NUMBER_Back.toCString );		// SCE_D_NUMBER 5
			
			
			IupSetAttribute( sci, "STYLEFGCOLOR10", GLOBAL.editColor.SCE_B_STRING_Fore.toCString );		// SCE_D_STRING 10
			IupSetAttribute( sci, "STYLEBGCOLOR10", GLOBAL.editColor.SCE_B_STRING_Back.toCString );		// SCE_D_STRING 10
			
			IupSetAttribute( sci, "STYLEFGCOLOR12", GLOBAL.editColor.SCE_B_PREPROCESSOR_Fore.toCString );	// SCE_D_CHARACTER 12
			IupSetAttribute( sci, "STYLEBGCOLOR12", GLOBAL.editColor.SCE_B_PREPROCESSOR_Back.toCString );	// SCE_D_CHARACTER 12
			
			IupSetAttribute( sci, "STYLEFGCOLOR13", GLOBAL.editColor.SCE_B_OPERATOR_Fore.toCString );		// SCE_D_OPERATOR 13
			IupSetAttribute( sci, "STYLEBGCOLOR13", GLOBAL.editColor.SCE_B_OPERATOR_Back.toCString );		// SCE_D_OPERATOR 13
			
			IupSetAttribute( sci, "STYLEFGCOLOR14", GLOBAL.editColor.SCE_B_IDENTIFIER_Fore.toCString );	// SCE_D_IDENTIFIER 14
			IupSetAttribute( sci, "STYLEBGCOLOR14", GLOBAL.editColor.SCE_B_IDENTIFIER_Back.toCString );	// SCE_D_IDENTIFIER 14
			
			
			IupSetAttribute(sci, "STYLEFGCOLOR6", GLOBAL.editColor.keyWord[0].toCString );			// SCE_D_WORD 6	
			IupSetAttribute(sci, "STYLEFGCOLOR7", GLOBAL.editColor.keyWord[1].toCString );			// SCE_D_WORD2 7
			IupSetAttribute(sci, "STYLEFGCOLOR20",  GLOBAL.editColor.keyWord[2].toCString );		// SCE_D_WORD5 20
			IupSetAttribute(sci, "STYLEFGCOLOR21",  GLOBAL.editColor.keyWord[3].toCString );		// SCE_D_WORD6 21
		}
		

		// Brace Hightlight
		IupSetAttribute(sci, "STYLEFGCOLOR34", GLOBAL.editColor.braceFore.toCString);	
		IupSetAttribute(sci, "STYLEBGCOLOR34", GLOBAL.editColor.braceBack.toCString);
		IupSetAttribute(sci, "STYLEFGCOLOR35", "255 255 0");
		IupSetAttribute(sci, "STYLEBGCOLOR35", "255 0 255");
		
		IupSetAttribute(sci, "STYLEBOLD34", "YES");
		//IupScintillaSendMessage( sci, 2053, 34, 1 );
		
		
		// Character representations
		// Set Control Character to <space>
		IupScintillaSendMessage( sci, 2388, Integer.atoi( GLOBAL.editorSetting00.ControlCharSymbol ), 0 ); // SCI_SETCONTROLCHARSYMBOL 2388
		//IupSetAttribute(sci, "STYLEFGCOLOR36", "255 255 0");
		//IupSetAttribute(sci, "STYLEBGCOLOR36", "255 255 255");
		//IupSetAttribute(sci, "STYLEFONTSIZE36", "60");		

		// Set Keywords to Bold
		if( GLOBAL.editorSetting00.BoldKeyword == "ON" )
		{
			IupSetAttribute(sci, "STYLEBOLD3", "YES");
			IupSetAttribute(sci, "STYLEBOLD10", "YES");
			IupSetAttribute(sci, "STYLEBOLD11", "YES");
			IupSetAttribute(sci, "STYLEBOLD12", "YES");
		}

		getFontAndSize( 10, font, Bold, Italic, Underline, Strikeout, size );
		IupSetAttribute(sci, "STYLEFGCOLOR40", GLOBAL.editColor.errorFore.toCString);	
		IupSetAttribute(sci, "STYLEBGCOLOR40", GLOBAL.editColor.errorBack.toCString);
		IupSetAttribute(sci, "STYLEFONT40",  toStringz( font.dup ) );
		IupSetAttribute(sci, "STYLEFONTSIZE40",  toStringz( size.dup ) );
		
		IupSetAttribute(sci, "STYLEFGCOLOR41", GLOBAL.editColor.warningFore.toCString);
		IupSetAttribute(sci, "STYLEBGCOLOR41", GLOBAL.editColor.warringBack.toCString);
		IupSetAttribute(sci, "STYLEFONT41",  toStringz( font.dup ) );
		IupSetAttribute(sci, "STYLEFONTSIZE41",  toStringz( size.dup ) );

		int tabSize = Integer.atoi( GLOBAL.editorSetting00.TabWidth );
		GLOBAL.editorSetting00.TabWidth = Integer.toString( tabSize );
		IupSetAttribute( sci, "TABSIZE", GLOBAL.cString.convert( GLOBAL.editorSetting00.TabWidth ) );

		if( !bFirstTime )
		{
			int textWidth = cast(int) IupScintillaSendMessage( sci, 2276, 33, cast(int) "9".ptr ); // SCI_TEXTWIDTH 2276
			if( GLOBAL.editorSetting00.LineMargin == "ON" )
			{
				int lineCount = IupGetInt( sci, "LINECOUNT" );
				char[] lc = Integer.toString( lineCount );
				if( GLOBAL.editorSetting00.FixedLineMargin == "OFF" )
				{
					IupSetInt( sci, "MARGINWIDTH0", ( lc.length + 1 ) * textWidth );
				}
				else
				{
					if( lc.length > 5 ) IupSetInt( sci, "MARGINWIDTH0", ( lc.length + 1 ) * textWidth ); else IupSetInt( sci, "MARGINWIDTH0", 6 * textWidth );
				}
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
			
			IupSetAttribute( sci, "MARKERDEFINE", "5=BACKGROUND" );
			IupSetAttribute( sci, "MARKERSYMBOL5", "BACKGROUND" );
			IupSetAttribute( sci, "MARKERSYMBOL6", "BACKGROUND" );
			IupSetAttribute( sci, "MARKERSYMBOL7", "BACKGROUND" );
			IupSetAttribute( sci, "MARKERSYMBOL8", "BACKGROUND" );			
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
			IupSetAttribute( sci, "FOLDMARGINCOLOR", GLOBAL.editColor.fold.toCString );
			IupSetAttribute( sci, "FOLDMARGINHICOLOR", GLOBAL.editColor.fold.toCString );
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
		if( GLOBAL.editorSetting00.TabUseingSpace == "ON" )
		{
			IupSetAttribute( sci, "USETABS", "NO" );
			IupScintillaSendMessage( sci, 2262, 1, 0 ); // SCI_SETBACKSPACEUNINDENTS 2262
		}
		else
		{
			IupSetAttribute( sci, "USETABS", "YES" );
		}
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
		IupScintillaSendMessage( sci, 2098, actionManager.ToolAction.convertIupColor( GLOBAL.editColor.caretLine.toDString ), 0 ); //SCI_SETCARETLINEBACK = 2098

		uint alpha = Integer.atoi( GLOBAL.editColor.selAlpha.toDString );
		if( alpha > 255 )
			alpha = 255;
		else if( alpha < 0 )
			alpha = 0;

		if( alpha == 255 )
		{
			IupScintillaSendMessage( sci, 2067, true, actionManager.ToolAction.convertIupColor( GLOBAL.editColor.selectionFore.toDString ) );// SCI_SETSELFORE = 2067,
			IupScintillaSendMessage( sci, 2068, true, actionManager.ToolAction.convertIupColor( GLOBAL.editColor.selectionBack.toDString ) );// SCI_SETSELBACK = 2068,
			IupScintillaSendMessage( sci, 2478, 256, 0 );// SCI_SETSELALPHA   2478
		}
		else if( alpha == 0 )
		{
			IupScintillaSendMessage( sci, 2067, false, actionManager.ToolAction.convertIupColor( GLOBAL.editColor.selectionFore.toDString ) );// SCI_SETSELFORE = 2067,
			IupScintillaSendMessage( sci, 2068, true, actionManager.ToolAction.convertIupColor( GLOBAL.editColor.selectionBack.toDString ) );// SCI_SETSELBACK = 2068,
			IupScintillaSendMessage( sci, 2478, 256, 0 );// SCI_SETSELALPHA   2478
		}
		else
		{
			IupScintillaSendMessage( sci, 2067, false, actionManager.ToolAction.convertIupColor( GLOBAL.editColor.selectionFore.toDString ) );// SCI_SETSELFORE = 2067,
			IupScintillaSendMessage( sci, 2068, true, actionManager.ToolAction.convertIupColor( GLOBAL.editColor.selectionBack.toDString ) );// SCI_SETSELBACK = 2068,
			IupScintillaSendMessage( sci, 2478, alpha, 0 );// SCI_SETSELALPHA   2478
		}
		
		IupSetAttribute( sci, "STYLEFGCOLOR33", GLOBAL.editColor.linenumFore.toCString );
		IupSetAttribute( sci, "STYLEBGCOLOR33", GLOBAL.editColor.linenumBack.toCString );
		// Error, Couldn't change......
		/*
		IupScintillaSendMessage( sci, 2290, 0, 0xffffff ); // SCI_SETFOLDMARGINCOLOUR = 2290,
		*/
		IupScintillaSendMessage( sci, 2069, actionManager.ToolAction.convertIupColor( GLOBAL.editColor.cursor.toDString ), 0 ); // SCI_SETCARETFORE = 2069,

		//IupSetAttribute( sci, "FOLDFLAGS", "LEVELNUMBERS" );  

		IupScintillaSendMessage( sci, 2655, 1, 0 ); // SCI_SETCARETLINEVISIBLEALWAYS = 2655,

		// SCI_AUTOCSETIGNORECASE 2115
		if( GLOBAL.toggleIgnoreCase == "ON" ) IupScintillaSendMessage( sci, 2115, 1, 0 ); else IupScintillaSendMessage( sci, 2115, 0, 0 );

		// SCI_AUTOCSETCASEINSENSITIVEBEHAVIOUR 2634
		if(GLOBAL.toggleCaseInsensitive == "ON" ) IupScintillaSendMessage( sci, 2634, 1, 0 ); else IupScintillaSendMessage( sci, 2634, 0, 0 );
		
		//IupScintillaSendMessage( sci, 2118, 0, 0 ); // SCI_AUTOCSETAUTOHIDE 2118
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
		
		IupSetAttribute( sci, "USEPOPUP", "NO" );
		
		if( GLOBAL.editorSetting00.BraceMatchHighlight == "OFF" ) IupSetInt( sci, "BRACEBADLIGHT", -1 );
		if( GLOBAL.editorSetting00.HighlightCurrentWord != "ON" ) IupScintillaSendMessage( sci, 2505, 0, IupGetInt( sci, "COUNT" ) ); // SCI_INDICATORCLEARRANGE = 2505
		
		// SCI_SETMULTIPLESELECTION 2563
		// SCI_SETADDITIONALSELECTIONTYPING 2565
		if( GLOBAL.editorSetting00.MultiSelection == "ON" )
		{
			IupScintillaSendMessage( sci, 2563, 1, 0 ); 
			IupScintillaSendMessage( sci, 2565, 1, 0 ); 
		}
		else
		{
			IupScintillaSendMessage( sci, 2563, 0, 0 );
			IupScintillaSendMessage( sci, 2565, 0, 0 ); 
		}
		
		IupScintillaSendMessage( sci, 2080, 8, GLOBAL.indicatorStyle ); //SCI_INDICSETSTYLE = 2080
		//IupScintillaSendMessage( sci, 2284, 1, 0 ); //SCI_SETTWOPHASEDRAW = 2284		
		//IupScintillaSendMessage( sci, 2510, 8, 1 ); //SCI_INDICSETUNDER = 2510
		IupScintillaSendMessage( sci, 2082, 8, actionManager.ToolAction.convertIupColor( GLOBAL.editColor.currentWord.toDString ) ); // SCI_INDICSETFORE = 2082
		
		alpha = Integer.atoi( GLOBAL.editColor.currentWordAlpha.toDString );
		if( alpha <= 0 )
			alpha = 0;
		else if( alpha > 255 )
			alpha = 255;
		
		IupScintillaSendMessage( sci, 2523, 8, alpha ); // SCI_INDICSETALPHA = 2523
		if( alpha + 64 <= 255 ) 
			IupScintillaSendMessage( sci, 2558, 8, alpha + 64 ); // SCI_INDICSETOUTLINEALPHA 2558
		else
			IupScintillaSendMessage( sci, 2558, 8, 255 ); // SCI_INDICSETOUTLINEALPHA 2558			

		version(FBIDE)
		{
			// Autocompletion XPM Image
			IupScintillaSendMessage( sci, 2624, 16, 0 ); // SCI_RGBAIMAGESETWIDTH 2624
			IupScintillaSendMessage( sci, 2625, 16, 0 ); // SCI_RGBAIMAGESETHEIGHT 2625

			// SCI_REGISTERRGBAIMAGE 2627
			IupScintillaSendMessage( sci, 2627, 0, cast(int) XPM.private_variable_array_rgba.toCString );
			IupScintillaSendMessage( sci, 2627, 1, cast(int) XPM.protected_variable_array_rgba.toCString ); 
			IupScintillaSendMessage( sci, 2627, 2, cast(int) XPM.public_variable_array_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627

			IupScintillaSendMessage( sci, 2627, 3, cast(int) XPM.private_variable_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 4, cast(int) XPM.protected_variable_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 5, cast(int) XPM.public_variable_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			
			//IupScintillaSendMessage( sci, 2627, 6, cast(int) XPM.class_private_obj_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627
			//IupScintillaSendMessage( sci, 2627, 7, cast(int) XPM.class_protected_obj_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 8, cast(int) XPM.class_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			
			IupScintillaSendMessage( sci, 2627, 9, cast(int) XPM.struct_private_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 10, cast(int) XPM.struct_protected_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 11, cast(int) XPM.struct_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			
			//IupScintillaSendMessage( sci, 2627, 12, cast(int) XPM.enum_private_obj_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 13, cast(int) XPM.enum_protected_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 14, cast(int) XPM.enum_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			
			IupScintillaSendMessage( sci, 2627, 15, cast(int) XPM.union_private_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 16, cast(int) XPM.union_protected_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 17, cast(int) XPM.union_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627

			IupScintillaSendMessage( sci, 2627, 18, cast(int) XPM.parameter_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 19, cast(int) XPM.enum_member_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 20, cast(int) XPM.alias_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627

			IupScintillaSendMessage( sci, 2627, 21, cast(int) XPM.normal_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			//IupScintillaSendMessage( sci, 2627, 22, cast(int) XPM.import_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627
			//IupScintillaSendMessage( sci, 2627, 23, cast(int) XPM.autoWord_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627

			IupScintillaSendMessage( sci, 2627, 24, cast(int) XPM.namespace_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627

			IupScintillaSendMessage( sci, 2627, 25, cast(int) XPM.private_sub_rgba.toCString );
			IupScintillaSendMessage( sci, 2627, 26, cast(int) XPM.protected_sub_rgba.toCString ); // SCI_REGISTERIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 27, cast(int) XPM.public_sub_rgba.toCString ); // SCI_REGISTERIMAGE = 2627
			
			IupScintillaSendMessage( sci, 2627, 28, cast(int) XPM.private_fun_rgba.toCString );
			IupScintillaSendMessage( sci, 2627, 29, cast(int) XPM.protected_fun_rgba.toCString ); // SCI_REGISTERIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 30, cast(int) XPM.public_fun_rgba.toCString ); // SCI_REGISTERIMAGE = 2627
			
			IupScintillaSendMessage( sci, 2627, 31, cast(int) XPM.property_rgba.toCString ); // SCI_REGISTERIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 32, cast(int) XPM.property_var_rgba.toCString ); // SCI_REGISTERIMAGE = 2627
			
			IupScintillaSendMessage( sci, 2627, 33, cast(int) XPM.define_var_rgba.toCString ); // SCI_REGISTERIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 34, cast(int) XPM.define_fun_rgba.toCString ); // SCI_REGISTERIMAGE = 2627
			
			IupScintillaSendMessage( sci, 2627, 35, cast(int) XPM.bas_rgba.toCString ); // SCI_REGISTERIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 36, cast(int) XPM.bi_rgba.toCString ); // SCI_REGISTERIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 37, cast(int) XPM.folder_rgba.toCString ); // SCI_REGISTERIMAGE = 2627
			

			// BOOKMARK
			IupScintillaSendMessage( sci, 2626, 1, cast(int) XPM.bookmark_rgba.toCString ); // SCI_MARKERDEFINERGBAIMAGE 2626
		}
		else
		{
			// Autocompletion XPM Image
			IupScintillaSendMessage( sci, 2624, 16, 0 ); // SCI_RGBAIMAGESETWIDTH 2624
			IupScintillaSendMessage( sci, 2625, 16, 0 ); // SCI_RGBAIMAGESETHEIGHT 2625

			// SCI_REGISTERRGBAIMAGE 2627
			IupScintillaSendMessage( sci, 2627, 0, cast(int) XPM.private_variable_array_rgba.toCString );
			IupScintillaSendMessage( sci, 2627, 1, cast(int) XPM.protected_variable_array_rgba.toCString ); 
			IupScintillaSendMessage( sci, 2627, 2, cast(int) XPM.public_variable_array_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627

			IupScintillaSendMessage( sci, 2627, 3, cast(int) XPM.private_variable_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 4, cast(int) XPM.protected_variable_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 5, cast(int) XPM.public_variable_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			
			//IupScintillaSendMessage( sci, 2627, 6, cast(int) XPM.class_private_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			//IupScintillaSendMessage( sci, 2627, 7, cast(int) XPM.class_protected_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 8, cast(int) XPM.class_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			
			IupScintillaSendMessage( sci, 2627, 9, cast(int) XPM.struct_private_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 10, cast(int) XPM.struct_protected_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 11, cast(int) XPM.struct_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			
			//IupScintillaSendMessage( sci, 2627, 12, cast(int) XPM.enum_private_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 13, cast(int) XPM.enum_protected_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 14, cast(int) XPM.enum_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			
			IupScintillaSendMessage( sci, 2627, 15, cast(int) XPM.union_private_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 16, cast(int) XPM.union_protected_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 17, cast(int) XPM.union_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627

			IupScintillaSendMessage( sci, 2627, 18, cast(int) XPM.parameter_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 19, cast(int) XPM.enum_member_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 20, cast(int) XPM.alias_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627

			IupScintillaSendMessage( sci, 2627, 21, cast(int) XPM.normal_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 22, cast(int) XPM.import_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 23, cast(int) XPM.template_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627

			IupScintillaSendMessage( sci, 2627, 24, cast(int) XPM.namespace_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627

			IupScintillaSendMessage( sci, 2627, 25, cast(int) XPM.private_sub_rgba.toCString );
			IupScintillaSendMessage( sci, 2627, 26, cast(int) XPM.protected_sub_rgba.toCString ); // SCI_REGISTERIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 27, cast(int) XPM.public_sub_rgba.toCString ); // SCI_REGISTERIMAGE = 2627
			
			IupScintillaSendMessage( sci, 2627, 28, cast(int) XPM.private_fun_rgba.toCString );
			IupScintillaSendMessage( sci, 2627, 29, cast(int) XPM.protected_fun_rgba.toCString ); // SCI_REGISTERIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 30, cast(int) XPM.public_fun_rgba.toCString ); // SCI_REGISTERIMAGE = 2627
			
			IupScintillaSendMessage( sci, 2627, 31, cast(int) XPM.alias_obj_rgba.toCString ); // SCI_REGISTERIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 32, cast(int) XPM.interface_obj_rgba.toCString ); // SCI_REGISTERIMAGE = 2627


			IupScintillaSendMessage( sci, 2627, 33, cast(int) XPM.define_var_rgba.toCString ); // SCI_REGISTERIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 34, cast(int) XPM.define_fun_rgba.toCString ); // SCI_REGISTERIMAGE = 2627

			// BOOKMARK
			IupScintillaSendMessage( sci, 2626, 1, cast(int) XPM.bookmark_rgba.toCString ); // SCI_MARKERDEFINERGBAIMAGE 2626
		}
	}
}




extern(C)
{
	private int CScintilla_linesChanged_cb( Ihandle* ih, int lin, int num )
	{
		//IupMessage( "", toStringz( "Num=" ~ Integer.toString( num ) ~ "\nLin=" ~ Integer.toString( lin + 1 ) ) );
		
		CScintilla cSci = ScintillaAction.getActiveCScintilla;
		
		if( cSci !is null )
			if( upperCase( cSci.getFullPath ) in GLOBAL.parserManager )
			{
				char[] prevLineText = fromStringz( IupGetAttributeId( ih, "LINE", lin ) );
				if( !Util.trim( prevLineText ).length )
				{
					LiveParser.lineNumberAdd( GLOBAL.parserManager[upperCase( cSci.getFullPath )], lin, num );
					//IupMessage( "", toStringz( "Num=" ~ Integer.toString( num ) ~ "\nLin=" ~ Integer.toString( lin ) ) );
				}
				else
				{
					LiveParser.lineNumberAdd( GLOBAL.parserManager[upperCase( cSci.getFullPath )], lin + 1, num );
				}
			}
		
		return IUP_DEFAULT;
	}
	
	private int marginclick_cb( Ihandle* ih, int margin, int line, char* status )
	{
		char[] statusString = fromStringz( status ).dup;
		
		switch( margin )
		{
			case 1:
				// With control
				if( statusString[1] == 'C' ) 
				{
					version(FBIDE)
					{
						if( GLOBAL.debugPanel.isExecuting() )
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
						}
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
				IupSetInt( ih, "FOLDTOGGLE", line );
				break;
				
			default:
		}

		return IUP_DEFAULT;
	}

	private int savePoint_cb( Ihandle *ih, int status )
	{
		char[]	_title;
		int 	pos = IupGetChildPos( GLOBAL.activeDocumentTabs, ih );
		
		pos = IupGetChildPos( GLOBAL.activeDocumentTabs, ih );
		if( pos > -1 ) _title = fromStringz( IupGetAttributeId( GLOBAL.activeDocumentTabs, "TABTITLE", pos ) ).dup; else return IUP_CONTINUE;
		
		if( status == 0 )
		{
			if( _title.length )
			{
				if( _title[0] != '*' )
				{
					_title = "*" ~ _title;
					auto cSci = ScintillaAction.getCScintilla( ih );
					if( cSci !is null )
					{
						auto titleHandle = cSci.getTitleHandle();
						titleHandle = _title;
						IupSetAttributeId( GLOBAL.activeDocumentTabs, "TABTITLE", pos, titleHandle.toCString );
						//if( fromStringz( IupGetAttribute( ih, "SAVEDSTATE" ) ) == "NO" ) IupSetAttribute( ih, "SAVEDSTATE", "YES" );
					}
					else
					{
						// First time trigger, don't change title
						//IupSetAttributeId( GLOBAL.documentTabs, "TABTITLE", pos, GLOBAL.cString.convert( _title ) );
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
					_title = _title[1..length];
					auto cSci = ScintillaAction.getCScintilla( ih );
					if( cSci !is null )
					{
						auto titleHandle = cSci.getTitleHandle();
						titleHandle = _title;							
						IupSetAttributeId( GLOBAL.activeDocumentTabs, "TABTITLE", pos, titleHandle.toCString );
						//if( fromStringz( IupGetAttribute( ih, "SAVEDSTATE" ) ) == "YES" ) IupSetAttribute( ih, "SAVEDSTATE", "NO" );
					}
					else
					{
						//IupSetAttributeId( GLOBAL.documentTabs, "TABTITLE", pos, GLOBAL.cString.convert( _title ) );
					}						
				}
			}
		}

		return IUP_DEFAULT;
	}

	/*
	private int CScintilla_valuechanged_cb( Ihandle* ih )
	{
		//actionManager.StatusBarAction.update();

		return IUP_DEFAULT;
	}
	*/

	// mouse button
	/*
	IUP_BUTTON1 = 1
	IUP_BUTTON2 = 2
	IUP_BUTTON3 = 3
	IUP_BUTTON4 = 4
	IUP_BUTTON5 = 5	
	*/
	private int button_cb( Ihandle* ih, int button, int pressed, int x, int y, char* status )
	{
		GLOBAL.tabDocumentPos = -1;	GLOBAL.dragDocumentTabs = null;
		
		// Change GLOBAL.activeDocumentTabs
		Ihandle* _documentTabs = IupGetParent( ih );
		if( _documentTabs != null )
		{
			if( GLOBAL.activeDocumentTabs != _documentTabs )
			{
				DocumentTabAction.tabChangePOS( _documentTabs, IupGetInt( _documentTabs, "VALUEPOS" ) );
				DocumentTabAction.setActiveDocumentTabs( _documentTabs );
			}
			else
			{
				auto cSci = ScintillaAction.getCScintilla( ih );
				if( cSci !is null )
				{
					IupSetAttribute( GLOBAL.projectTree.getTreeHandle, "MARK", "CLEARALL" ); // For projectTree MULTIPLE Selection
					ScintillaAction.toTreeMarked( cSci.getFullPath, 2 );
				}
			}
		}
		
		
		// Using IupFlatTabs at Linux, Double Click will trigget BUTTON_CB on IupScintilla, then BUTTON_CB on IupFlatTabs
		version(linux)
		{
			if( pressed == 1 ) // in
			{
				if( button == IUP_BUTTON2 ) return IUP_IGNORE;
			}
		}
	
		char[] statusString = fromStringz( status ).dup;
		if( statusString.length > 6 )
		{
			// Ctrl + Click for Goto Definition / Goto Procedure
			if( statusString[1] == 'C' )
			{
				if( statusString[6] != 'A' && statusString[0] != 'S' )
				{
					int _pos = cast(int) IupScintillaSendMessage( ih, 2022, x, y ); // SCI_POSITIONFROMPOINT
					
					if( button == IUP_BUTTON1 )
					{
						if( GLOBAL.editorSetting00.MultiSelection == "ON" ) return IUP_DEFAULT;
						
						if( pressed == 1 )
						{
							IupScintillaSendMessage( ih, 2025, _pos , 0 );// SCI_GOTOPOS = 2025,
							version(FBIDE) AutoComplete.toDefintionAndType( 1, _pos );
							version(DIDE) AutoComplete.toDefintionAndType( 1 );
						}
						return IUP_IGNORE;
					}
					else if( button == IUP_BUTTON3 )
					{
						if( pressed == 1 )
						{							
							IupScintillaSendMessage( ih, 2025, _pos , 0 );// SCI_GOTOPOS = 2025,
							version(FBIDE) AutoComplete.toDefintionAndType( 2, _pos );
							version(DIDE) AutoComplete.toDefintionAndType( 2 );
						}
						return IUP_IGNORE;
					}
					else if( button == IUP_BUTTON2 )
					{
						for( int i = _pos; i > -1; -- i )
						{
							int close = IupGetIntId( ih, "BRACEMATCH", i );
							if( close > -1 )
							{
								if( close > _pos )
								{
									IupSetAttribute( ih, "SELECTIONPOS", toStringz( Integer.toString( ++i ) ~ ":" ~ Integer.toString( close ) ) );
									break;
								}
							}
						}
						return IUP_IGNORE;
					}					
				}
				else if( statusString[6] == 'A' )
				{
					version(linux)
					{
						if( pressed == 0 )
						{
							if( button == IUP_BUTTON1 )
							{
								auto cacheUnit = GLOBAL.navigation.back();
								if( cacheUnit._line != -1 )	ScintillaAction.openFile( cacheUnit._fullPath, cacheUnit._line );
							}
							else if( button == IUP_BUTTON3 )
							{
								auto cacheUnit = GLOBAL.navigation.forward();
								if( cacheUnit._line != -1 )	ScintillaAction.openFile( cacheUnit._fullPath, cacheUnit._line );
							}
						}
						return IUP_IGNORE;
					}
				}
			}
			else if( statusString[6] == 'A' )
			{
				/+
				// SCI_SETSELECTIONMODE 2422
				// SCI_GETSELECTIONMODE 2423
				//IupMessage("",toStringz( Integer.toString( cast(int) IupScintillaSendMessage( ih, 2423, 0, 0 ))) );
				
				if( pressed == 1 )
				{
					IupScintillaSendMessage( ih, 2422, 3, 0 ); // SCI_SETSELECTIONMODE 2422
					IupMessage("",toStringz( Integer.toString( cast(int) IupScintillaSendMessage( ih, 2423, 0, 0 ))) );
				}
				else
				{
					//IupScintillaSendMessage( ih, 2422, 0, 0 ); // SCI_SETSELECTIONMODE 2422
				}				
				
				+/
				version(Windows)
				{
					if( statusString[1] != 'C' && statusString[0] != 'S' )
					{
						if( pressed == 0 )
						{
							int bSelectEMPTY = cast(int) IupScintillaSendMessage( ih, 2650, 0, 0 ); // SCI_GETSELECTIONEMPTY 2650
							if( bSelectEMPTY == 1 )
							{
								if( button == IUP_BUTTON1 )
								{
									auto cacheUnit = GLOBAL.navigation.back();
									if( cacheUnit._line != -1 )	ScintillaAction.openFile( cacheUnit._fullPath, cacheUnit._line );
								}
								else if( button == IUP_BUTTON3 )
								{
									auto cacheUnit = GLOBAL.navigation.forward();
									if( cacheUnit._line != -1 )	ScintillaAction.openFile( cacheUnit._fullPath, cacheUnit._line );
								}
								return IUP_DEFAULT;
								//return IUP_IGNORE;
							}
							else
							{
								// SELECTIONISRECTANGLE
							}
						}
					}
				}
			}
			else if( statusString[5] == 'D' )
			{
				version(linux) return IUP_IGNORE;
			}
		}			

	
		if( pressed == 0 ) //release
		{
			if( GLOBAL.editorSetting00.MiddleScroll == "ON" )
			{
				if( fromStringz( IupGetAttribute( GLOBAL.scrollICONHandle, "VISIBLE" ) ) == "YES" )
				{
					IupHide( GLOBAL.scrollICONHandle );
					return IUP_DEFAULT;
				}
			}
			
			if( button == IUP_BUTTON3 ) // Right Click
			{
				Ihandle* _undo = IupItem( GLOBAL.languageItems["sc_undo"].toCString, null );
				IupSetAttribute( _undo, "IMAGE", "icon_undo" );
				if( fromStringz(IupGetAttribute( ih, "UNDO" )) != "YES" ) IupSetAttribute( _undo, "ACTIVE", "NO" );
				IupSetCallback( _undo, "ACTION", cast(Icallback) &menu.undo_cb ); // from menu.d

				Ihandle* _redo = IupItem( GLOBAL.languageItems["sc_redo"].toCString, null );
				IupSetAttribute( _redo, "IMAGE", "icon_redo" );
				if( fromStringz(IupGetAttribute( ih, "REDO" )) != "YES" ) IupSetAttribute( _redo, "ACTIVE", "NO" );
				IupSetCallback( _redo, "ACTION", cast(Icallback) &menu.redo_cb ); // from menu.d
				
				Ihandle* _clearBuffer = IupItem( GLOBAL.languageItems["clear"].toCString, null );
				IupSetAttribute( _clearBuffer, "IMAGE", "icon_clear" );
				IupSetCallback( _clearBuffer, "ACTION", cast(Icallback) function( Ihandle* ih )
				{
					auto sci = ScintillaAction.getActiveIupScintilla;
					if( sci != null )
					{
						IupScintillaSendMessage( sci, 2175, 0, 0 ); // SCI_EMPTYUNDOBUFFER 2175
					}
					
					Ihandle* __undo = IupGetDialogChild( GLOBAL.toolbar.getHandle, "toolbar_Undo" );
					if( __undo != null ) IupSetAttribute( __undo, "ACTIVE", "NO" ); // SCI_CANUNDO 2174

					Ihandle* __redo = IupGetDialogChild( GLOBAL.toolbar.getHandle, "toolbar_Redo" );
					if( __redo != null ) IupSetAttribute( __redo, "ACTIVE", "NO" ); // SCI_CANREDO 2016
					
					DocumentTabAction.setFocus( sci );
					return IUP_DEFAULT;
				});					
				

				Ihandle* _cut = IupItem( GLOBAL.languageItems["caption_cut"].toCString, null );
				IupSetAttribute( _cut, "IMAGE", "icon_cut" );
				IupSetCallback( _cut, "ACTION", cast(Icallback) &menu.cut_cb ); // from menu.d

				Ihandle* _copy = IupItem( GLOBAL.languageItems["caption_copy"].toCString, null );
				IupSetAttribute( _copy, "IMAGE", "icon_copy" );
				IupSetCallback( _copy, "ACTION", cast(Icallback) &menu.copy_cb ); // from menu.d

				Ihandle* _paste = IupItem( GLOBAL.languageItems["caption_paste"].toCString, null );
				IupSetAttribute( _paste, "IMAGE", "icon_paste" );
				IupSetCallback( _paste, "ACTION", cast(Icallback) &menu.paste_cb ); // from menu.d

				Ihandle* _delete = IupItem( GLOBAL.languageItems["delete"].toCString, null );
				IupSetAttribute( _delete, "IMAGE", "icon_clear" );
				IupSetCallback( _delete, "ACTION", cast(Icallback) function( Ihandle* ih )
				{
					Ihandle* _sci = actionManager.ScintillaAction.getActiveIupScintilla();
					if( _sci != null ) IupSetAttribute( _sci, "SELECTEDTEXT", "" );
					return IUP_DEFAULT;

				});

				Ihandle* _selectall = IupItem( GLOBAL.languageItems["selectall"].toCString, null );
				IupSetAttribute( _selectall, "IMAGE", "icon_selectall" );
				IupSetCallback( _selectall, "ACTION", cast(Icallback) &menu.selectall_cb ); // from menu.d

				// Annotation
				Ihandle* _showAnnotation = IupItem( GLOBAL.languageItems["showannotation"].toCString, null );
				IupSetAttribute( _showAnnotation, "IMAGE", "icon_annotation" );
				IupSetCallback( _showAnnotation, "ACTION", cast(Icallback) function( Ihandle* ih )
				{
					CScintilla cSci = actionManager.ScintillaAction.getActiveCScintilla();
					IupSetAttribute( cSci.getIupScintilla, "ANNOTATIONVISIBLE", "BOXED" );
					return IUP_DEFAULT;
				});
				
				Ihandle* _hideAnnotation = IupItem( GLOBAL.languageItems["hideannotation"].toCString, null );
				IupSetAttribute( _hideAnnotation, "IMAGE", "icon_annotation_hide" );
				IupSetCallback( _hideAnnotation, "ACTION", cast(Icallback)function( Ihandle* ih )
				{
					CScintilla cSci = actionManager.ScintillaAction.getActiveCScintilla();
					IupSetAttribute( cSci.getIupScintilla, "ANNOTATIONVISIBLE", "HIDDEN" );
					return IUP_DEFAULT;
				});

				Ihandle* _removeAllAnnotation = IupItem( GLOBAL.languageItems["removeannotation"].toCString, null );
				IupSetAttribute( _removeAllAnnotation, "IMAGE", "icon_annotation_remove" );
				IupSetCallback( _removeAllAnnotation, "ACTION", cast(Icallback) function( Ihandle* ih )
				{
					CScintilla cSci = actionManager.ScintillaAction.getActiveCScintilla();
					IupSetAttribute( cSci.getIupScintilla, "ANNOTATIONCLEARALL", "YES" );
					return IUP_DEFAULT;
				});
				
				Ihandle* _tempAnnotationMenu = IupMenu( _showAnnotation, _hideAnnotation, _removeAllAnnotation, null  );
				Ihandle* _AnnotationSubMenu = IupSubmenu( GLOBAL.languageItems["annotation"].toCString ,_tempAnnotationMenu  );
				IupSetAttribute( _AnnotationSubMenu, "IMAGE", "icon_annotation" );
			

				Ihandle* _refresh = IupItem( GLOBAL.languageItems["sc_reparse"].toCString, null );
				IupSetAttribute( _refresh, "IMAGE", "icon_refresh" );
				IupSetCallback( _refresh, "ACTION", cast(Icallback) function( Ihandle* ih )
				{
					CScintilla cSci = actionManager.ScintillaAction.getActiveCScintilla();
					GLOBAL.outlineTree.refresh( cSci );
					return IUP_DEFAULT;
				});

				Ihandle* _goto = IupItem( GLOBAL.languageItems["sc_gotodef"].toCString, null );
				IupSetAttribute( _goto, "IMAGE", "icon_goto" );
				IupSetCallback( _goto, "ACTION", cast(Icallback) function( Ihandle* ih )
				{
					AutoComplete.toDefintionAndType( 1 );
					return IUP_DEFAULT;
				});
				
				/*
				Ihandle* _back = IupItem( GLOBAL.languageItems["sc_backdefinition"].toCString, null );
				IupSetAttribute( _back, "IMAGE", "icon_back" );
				IupSetCallback( _back, "ACTION", cast(Icallback) function( Ihandle* ih )
				{
					//AutoComplete.backDefinition();
					return IUP_DEFAULT;
				});
				*/
				
				Ihandle* _gotoProcedure = IupItem( GLOBAL.languageItems["sc_procedure"].toCString, null );
				IupSetAttribute( _gotoProcedure, "IMAGE", "icon_gotomember" );
				IupSetCallback( _gotoProcedure, "ACTION", cast(Icallback) function( Ihandle* ih )
				{
					AutoComplete.toDefintionAndType( 2 );
					return IUP_DEFAULT;
				});
				
				

				Ihandle* _showType = IupItem( GLOBAL.languageItems["sc_showtype"].toCString, null );
				IupSetAttribute( _showType, "IMAGE", "icon_type" );
				IupSetCallback( _showType, "ACTION", cast(Icallback) function( Ihandle* ih )
				{
					AutoComplete.toDefintionAndType( 0 );
					return IUP_DEFAULT;
				});				
				
				
				// High Light......
				CScintilla	cSci = actionManager.ScintillaAction.getActiveCScintilla();
				ubyte[256]	pixel;
				
				pixel[] = 0;
				Ihandle* pixelImage = IupImage( 16, 16, pixel.ptr );

				//selectedMarkerIndex
				Ihandle* _maker0 = IupItem( GLOBAL.languageItems["maker0"].toCString, null );
				IupSetCallback( _maker0, "ACTION", cast(Icallback) function( Ihandle* ih ){ 
					ScintillaAction.getActiveCScintilla.selectedMarkerIndex = 0;
					return IUP_DEFAULT;
				});
				
				Ihandle* _maker1 = IupItem( GLOBAL.languageItems["maker1"].toCString, null );
				IupSetCallback( _maker1, "ACTION", cast(Icallback) function( Ihandle* ih ){
					ScintillaAction.getActiveCScintilla.selectedMarkerIndex = 1;
					return IUP_DEFAULT;
				});
				
				Ihandle* _maker2 = IupItem( GLOBAL.languageItems["maker2"].toCString, null );
				IupSetCallback( _maker2, "ACTION", cast(Icallback) function( Ihandle* ih ){
					ScintillaAction.getActiveCScintilla.selectedMarkerIndex = 2;
					return IUP_DEFAULT;
				});
				
				Ihandle* _maker3 = IupItem( GLOBAL.languageItems["maker3"].toCString, null );
				IupSetCallback( _maker3, "ACTION", cast(Icallback) function( Ihandle* ih ){
					ScintillaAction.getActiveCScintilla.selectedMarkerIndex = 3;
					return IUP_DEFAULT;
				});
				
				switch( cSci.selectedMarkerIndex )
				{
					case 0:
						IupSetAttribute( _maker0, "VALUE", "ON");
						IupSetAttribute( pixelImage, "0", GLOBAL.editColor.maker[0].toCString );
						break;
					case 1:
						IupSetAttribute( _maker1, "VALUE", "ON");
						IupSetAttribute( pixelImage, "0", GLOBAL.editColor.maker[1].toCString );
						break;
					case 2:
						IupSetAttribute( _maker2, "VALUE", "ON");
						IupSetAttribute( pixelImage, "0", GLOBAL.editColor.maker[2].toCString );
						break;
					case 3:
						IupSetAttribute( _maker3, "VALUE", "ON");
						IupSetAttribute( pixelImage, "0", GLOBAL.editColor.maker[3].toCString );
						break;
					default: 
				}				
				
				Ihandle* _makerSubMenu = IupMenu( _maker0, _maker1, _maker2, _maker3, null  );
				IupSetAttribute( _makerSubMenu, "RADIO", "YES");
				IupSetHandle( "icon_color", pixelImage );
				
				
				ubyte[4][256]	pixels;
				
				pixel[0] = pixel[1] = pixel[2] = pixel[3] = 0;
				Ihandle*[4] pixelsImage;
				for( int i = 0; i < 4; ++ i )
				{
					pixelsImage[i]	= IupImage( 16, 16, pixels[i].ptr );
					IupSetAttribute( pixelsImage[i], "0", GLOBAL.editColor.maker[i].toCString );
				}
				IupSetHandle( "icon_color0", pixelsImage[0] );
				IupSetHandle( "icon_color1", pixelsImage[1] );
				IupSetHandle( "icon_color2", pixelsImage[2] );
				IupSetHandle( "icon_color3", pixelsImage[3] );
				
				IupSetAttribute( _maker0, "TITLEIMAGE", "icon_color0" );
				IupSetAttribute( _maker1, "TITLEIMAGE", "icon_color1" );
				IupSetAttribute( _maker2, "TITLEIMAGE", "icon_color2" );
				IupSetAttribute( _maker3, "TITLEIMAGE", "icon_color3" );

				Ihandle* _highlightLine = IupItem( GLOBAL.languageItems["highlghtlines"].toCString, null );
				IupSetAttribute( _highlightLine, "IMAGE", "icon_color" );
				IupSetCallback( _highlightLine, "ACTION", cast(Icallback) function( )
				{
					CScintilla actSci = ScintillaAction.getActiveCScintilla;
					if( actSci !is null )
					{
						int currentPos			= cast(int) IupScintillaSendMessage( actSci.getIupScintilla, 2008, 0, 0 ); // SCI_GETCURRENTPOS = 2008
						int currentLine  		= cast(int) IupScintillaSendMessage( actSci.getIupScintilla, 2166, currentPos, 0 ); // SCI_LINEFROMPOSITION = 2166
						
						switch( actSci.selectedMarkerIndex )
						{
							case 0:		IupSetAttribute( actSci.getIupScintilla, "MARKERBGCOLOR5",  GLOBAL.editColor.maker[0].toCString ); break;
							case 1:		IupSetAttribute( actSci.getIupScintilla, "MARKERBGCOLOR6",  GLOBAL.editColor.maker[1].toCString ); break;
							case 2:		IupSetAttribute( actSci.getIupScintilla, "MARKERBGCOLOR7",  GLOBAL.editColor.maker[2].toCString ); break;
							case 3:		IupSetAttribute( actSci.getIupScintilla, "MARKERBGCOLOR8",  GLOBAL.editColor.maker[3].toCString ); break;
							default: 
						}							
						
						char[] lines = fromStringz( IupGetAttribute( actSci.getIupScintilla, "SELECTION" ) );
						if( lines.length )
						{
							char[][] splitText = Util.split( lines, "," );
							if( splitText.length > 2 )
							{
								char[][] splitText2 = Util.split( splitText[1], ":" );
								if( splitText2.length > 1 )
								{
									int startLine = Integer.atoi( splitText[0] );
									int tailLine = Integer.atoi( splitText2[1] );
									if( tailLine >= startLine )
									{
										for( int i = startLine; i <= tailLine; ++i )
										{
											for( int j = 5; j < 9; ++ j )
											{
												IupSetIntId( actSci.getIupScintilla, "MARKERDELETE", i, j );
											}
											IupSetIntId( actSci.getIupScintilla, "MARKERADD", i, actSci.selectedMarkerIndex + 5 );
										}
									}
								}
							}
						}
						else
						{
							for( int j = 5; j < 9; ++ j )
							{
								IupSetIntId( actSci.getIupScintilla, "MARKERDELETE", currentLine, j );
							}							
							IupSetIntId( actSci.getIupScintilla, "MARKERADD", currentLine, actSci.selectedMarkerIndex + 5 );
						}
					}
					return IUP_DEFAULT;
				});
				
				Ihandle* _delHighlightLine = IupItem( GLOBAL.languageItems["delhighlghtlines"].toCString, null );
				IupSetAttribute( _delHighlightLine, "IMAGE", "icon_clear" );
				IupSetCallback( _delHighlightLine, "ACTION", cast(Icallback) function( )
				{
					Ihandle* ih = ScintillaAction.getActiveIupScintilla;
					if( ih != null )
					{
						int currentPos			= cast(int) IupScintillaSendMessage( ih, 2008, 0, 0 ); // SCI_GETCURRENTPOS = 2008
						int currentLine  		= cast(int) IupScintillaSendMessage( ih, 2166, currentPos, 0 ); // SCI_LINEFROMPOSITION = 2166
						
						char[] lines = fromStringz( IupGetAttribute( ih, "SELECTION" ) );
						if( lines.length )
						{
							char[][] splitText = Util.split( lines, "," );
							if( splitText.length > 2 )
							{
								char[][] splitText2 = Util.split( splitText[1], ":" );
								if( splitText2.length > 1 )
								{
									int startLine = Integer.atoi( splitText[0] );
									int tailLine = Integer.atoi( splitText2[1] );
									if( tailLine >= startLine )
									{
										
										for( int i = startLine; i <= tailLine; ++i )
										{
											for( int j = 5; j < 9; ++ j )
											{
												IupSetIntId( ih, "MARKERDELETE", i, j );
											}											
										}
									}
								}
							}
						}
						else
						{
							for( int j = 5; j < 9; ++ j )
							{
								IupSetIntId( ih, "MARKERDELETE", currentLine, j );
							}
						}
					}
					return IUP_DEFAULT;
				});					

				Ihandle* itemHighlight = IupSubmenu( GLOBAL.languageItems["colorhighlght"].toCString, _makerSubMenu );
				IupSetAttribute( itemHighlight, "IMAGE", "icon_colormark" );
				Ihandle* temp = IupMenu( _highlightLine, _delHighlightLine, itemHighlight, null );
				Ihandle* itemMainHighlight = IupSubmenu( GLOBAL.languageItems["highlightmaker"].toCString, temp );
				IupSetAttribute( itemMainHighlight, "IMAGE", "icon_colormark" );
				
				Ihandle* popupMenu = IupMenu(
												_undo,
												_redo,
												_clearBuffer,
												IupSeparator(),

												_cut,
												_copy,
												_paste,
												_delete,
												IupSeparator(),

												_selectall,
												IupSeparator(),
												
												itemMainHighlight,
												IupSeparator(),
												
												_AnnotationSubMenu,
												/*
												_showAnnotation,
												_hideAnnotation,
												_removeAllAnnotation,
												*/
												IupSeparator(),
												
												_refresh,
												_goto,
												_gotoProcedure,
												/*
												_back,
												*/
												_showType,
												null
											);


				IupPopup( popupMenu, IUP_MOUSEPOS, IUP_MOUSEPOS );
				IupDestroy( popupMenu );
				IupDestroy( pixelImage );
				for( int i = 0; i < 4; ++ i )
				{
					IupDestroy( pixelsImage[i] );
				}
				
				version(linux) return IUP_IGNORE; // For Linux MOD
			}
			else if( button == IUP_BUTTON2 ) // Middle Click
			{
				if( GLOBAL.editorSetting00.MiddleScroll == "ON" )
				{
					if( fromStringz( IupGetAttribute( GLOBAL.scrollICONHandle, "VISIBLE" ) ) == "NO" )
					{
						int _x, _y;
						char[]	mousePos = fromStringz( IupGetGlobal( "CURSORPOS" ) );
					
						int crossSign = Util.index( mousePos, "x" );
						if( crossSign < mousePos.length )
						{
							_x = Integer.atoi( mousePos[0..crossSign] );
							_y = Integer.atoi( mousePos[crossSign+1..$] );
							_x -= 16;
							_y -= 16;
							if( _x < 0 ) _x = 0;
							if( _y < 0 ) _y = 0;
							
							IupShowXY( GLOBAL.scrollICONHandle, _x, _y );

							IupSetFocus( ih );							
						}
						return IUP_DEFAULT;
					}
				}
	
				if( GLOBAL.editorSetting00.MultiSelection == "ON" )
				{
					int pos = IupConvertXYToPos( ih, x, y );
					IupScintillaSendMessage( ih, 2025, pos , 0 );// SCI_GOTOPOS = 2025,
					
					IupSetFocus( ih );
					char[] _char = Util.trim( fromStringz( IupGetAttributeId( ih, "CHAR", pos ) ) );
					
					if( _char.length )
					{
						IupSetAttribute( ih, "SELECTIONPOS", "NONE" );
						
						char[] word = AutoComplete.getWholeWordDoubleSide( ih, pos );
						word = word.reverse;
						
						char[][] splitWord = Util.split( word, "." );
						if( splitWord.length > 1 ) word = splitWord[$-1];
						
						splitWord = Util.split( word, "->" );
						if( splitWord.length > 1 ) word = splitWord[$-1];
						
						//IupMessage( "", toStringz( word ) );
						if( word.length )
						{
							/*
							SCFIND_WHOLEWORD = 2,
							SCFIND_MATCHCASE = 4,
							SCFIND_WORDSTART = 0x00100000,
							SCFIND_REGEXP = 0x00200000,
							SCFIND_POSIX = 0x00400000,
							*/								
							IupScintillaSendMessage( ih, 2198, 2, 0 ); // SCI_SETSEARCHFLAGS = 2198,
							IupSetInt( ih, "TARGETSTART", 0 );
							IupSetInt( ih, "TARGETEND", -1 );
							
							int count;
							int findPos = cast(int) IupScintillaSendMessage( ih, 2197, word.length, cast(int) GLOBAL.cString.convert( word ) ); //SCI_SEARCHINTARGET = 2197,
							
							while( findPos > -1 )
							{
								if( count++ == 0 ) 
									IupScintillaSendMessage( ih, 2572, cast(int) findPos, cast(int) ( findPos + word.length ) ); // SCI_SETSELECTION 2572
								else
									IupScintillaSendMessage( ih, 2573, cast(int) findPos, cast(int) ( findPos + word.length ) ); // SCI_ADDSELECTION 2573

								IupSetInt( ih, "TARGETSTART", findPos + word.length );
								IupSetInt( ih, "TARGETEND", -1 );
								findPos = cast(int) IupScintillaSendMessage( ih, 2197, word.length, cast(int) GLOBAL.cString.convert( word ) ); //SCI_SEARCHINTARGET = 2197,
							}
						}
					}
				}
			}
		}
		
		return IUP_DEFAULT;
	}
	
	private int CScintilla_DWELL_CB( Ihandle *ih, int state, int pos, int x, int y )
	{
		if( GLOBAL.toggleEnableDwell == "ON" )
		{
			if( state == 1 )
			{
				if( pos != -1 )
				{
					if( cast(int) IupScintillaSendMessage( ih, 2202, 0, 0 ) == 0 )
					{
						version(FBIDE) AutoComplete.toDefintionAndType( 0, pos ); // SCI_CALLTIPACTIVE 2202
						version(DIDE) AutoComplete.toDefintionAndType( 0 ); // SCI_CALLTIPACTIVE 2202
					}
				}
			}
			else
			{
				if( cast(int) IupScintillaSendMessage( ih, 2202, 0, 0 ) == 1 ) IupScintillaSendMessage( ih, 2201, 0, 0 ); // SCI_CALLTIPCANCEL  2201
			}
		}
		
		return IUP_DEFAULT;
	}
	
	private int CScintilla_MOTION_CB( Ihandle *ih, int x, int y, char *status )
	{
		if( GLOBAL.editorSetting00.MiddleScroll == "ON" )
		{
			if( fromStringz( IupGetAttribute( GLOBAL.scrollICONHandle, "VISIBLE" ) ) == "YES" )
			{
				//IupMessage("","");
				char[] cursorString = fromStringz( IupGetGlobal( "CURSORPOS" ) );
				
				int		cursorX, cursorY, iconX, iconY;
				int 	crossSign = Util.index( cursorString, "x" );
				if( crossSign < cursorString.length )
				{
					cursorX = Integer.atoi( cursorString[0..crossSign] );
					cursorY = Integer.atoi( cursorString[crossSign+1..$] );
				}
				
				char[] iconString = fromStringz( IupGetAttribute( GLOBAL.scrollICONHandle, "SCREENPOSITION" ) );
				crossSign = Util.index( iconString, "," );
				if( crossSign < iconString.length )
				{
					iconX = Integer.atoi( iconString[0..crossSign] );
					iconY = Integer.atoi( iconString[crossSign+1..$] );
				}
				
				if( cursorY > iconY )
				{
					int add = ( cursorY - iconY ) / 100 + 1;
					IupScintillaSendMessage( ih, 2168, 0, add ); // SCI_LINESCROLL 2168
					
				}
				else if( cursorY < iconY )
				{
					int minus = ( cursorY - iconY ) / 100 - 1;
					IupScintillaSendMessage( ih, 2168, 0, minus ); // SCI_LINESCROLL 2168
				}
				
				if( cursorX > iconX )
				{
					int add = ( cursorX - iconX ) / 400 + 1;
					IupScintillaSendMessage( ih, 2168, add, 0 ); // SCI_LINESCROLL 2168
					
				}
				else if( cursorX < iconX )
				{
					int minus = ( cursorX - iconX ) / 400 - 1;
					IupScintillaSendMessage( ih, 2168, minus, 0 ); // SCI_LINESCROLL 2168
				}
			}
		}
		
		return IUP_DEFAULT;
	}
	

	private int CScintilla_keyany_cb( Ihandle *ih, int c ) 
	{
		try
		{
			//GLOBAL.messagePanel.printOutputPanel( "Keycode:" ~ Integer.toString( c ) );
			AutoComplete.bAutocompletionPressEnter = false;
			
			if( c == 13 ) AutoComplete.bEnter = true; else AutoComplete.bEnter = false;

			if( c == 65307 ) // ESC
			{
				if( fromStringz( IupGetAttribute( ih, "AUTOCACTIVE" ) ) == "YES" ) IupSetAttribute( ih, "AUTOCCANCEL", "YES" );
			}
			
			if( GLOBAL.editorSetting00.AutoClose == "ON" )
			{
				switch( c )
				{
					case 34: // "
						IupSetAttributeId( ih, "INSERT", -1, toStringz( "\"" ) ); break;
					case 40: // (
						IupSetAttributeId( ih, "INSERT", -1, toStringz( ")" ) ); break;
					case 91: // [
						IupSetAttributeId( ih, "INSERT", -1, toStringz( "]" ) ); break;
					case 123: // {
						IupSetAttributeId( ih, "INSERT", -1, toStringz( "}" ) ); break;
					default:
				}
			}

			foreach( ShortKey sk; GLOBAL.shortKeys )
			{
				switch( sk.name )
				{
					case "find":				
						if( sk.keyValue == c )
						{
							menu.findReplace_cb();
							return IUP_IGNORE;
						}
						break;
					case "findinfile":
						if( sk.keyValue == c )
						{ 
							menu.findReplaceInFiles();
							return IUP_IGNORE;
						}
						break;
					case "findnext":
						if( sk.keyValue == c )
						{
							menu.findNext_cb();
							return IUP_IGNORE;
						}
						break;
					case "findprev":
						if( sk.keyValue == c )
						{
							menu.findPrev_cb();
							return IUP_IGNORE;
						}
						break;
					case "gotoline":
						if( sk.keyValue == c )
						{
							menu.item_goto_cb();
							return IUP_IGNORE;
						}
						break;
					case "undo":
						if( sk.keyValue == c )
						{
							menu.undo_cb();
							return IUP_IGNORE;
						}
						break;
					case "redo":						
						if( sk.keyValue == c )
						{
							menu.redo_cb();
							return IUP_IGNORE;
						}
						break;
					case "defintion":
						if( sk.keyValue == c )
						{
							AutoComplete.toDefintionAndType( 1 );
							return IUP_IGNORE;
						}
						break;
					case "procedure":
						if( sk.keyValue == c )
						{
							AutoComplete.toDefintionAndType( 2 );
							return IUP_IGNORE;
						}
						break;					
					case "quickrun":
						if( sk.keyValue == c )
						{
							menu.quickRun_cb( null );
							return IUP_IGNORE;
						}
						break;
					case "run":
						if( sk.keyValue == c )
						{
							menu.run_cb( null );
							return IUP_IGNORE;
						}
						break;
					case "build":
						if( sk.keyValue == c )
						{
							menu.buildAll_cb( null );
							return IUP_IGNORE;
						}
						break;
					case "outlinewindow":
						if( sk.keyValue == c ) 
						{
							menu.outlineMenuItem_cb( GLOBAL.menuOutlineWindow );
							IupSetFocus( ih );
							return IUP_IGNORE;
						}
						break;
					case "messagewindow":
						if( sk.keyValue == c )
						{
							menu.messageMenuItem_cb( GLOBAL.menuMessageWindow );
							IupSetFocus( ih );
							return IUP_IGNORE;
						}
						break;
					case "showtype":
						if( sk.keyValue == c )
						{
							AutoComplete.toDefintionAndType( 0 );
							return IUP_IGNORE;
						}
						break;
					case "reparse":
						if( sk.keyValue == c )
						{
							CScintilla cSci = actionManager.ScintillaAction.getActiveCScintilla();
							GLOBAL.outlineTree.refresh( cSci );
						}
						break;
					case "save":					
						if( sk.keyValue == c )
						{
							menu.saveFile_cb( null );
							return IUP_IGNORE;
						}
						break;
					case "saveall":
						if( sk.keyValue == c )
						{
							menu.saveAllFile_cb( null );
							return IUP_IGNORE;
						}
						break;
					case "close":
						if( sk.keyValue == c )
						{
							CScintilla cSci = actionManager.ScintillaAction.getActiveCScintilla();
							if( cSci !is null )	actionManager.ScintillaAction.closeDocument( cSci.getFullPath() );
						}
						break;

					case "nexttab":
						if( sk.keyValue == c )
						{
							int count = IupGetChildCount( GLOBAL.activeDocumentTabs );
							if( count > 1 )
							{
								int id = IupGetInt( GLOBAL.activeDocumentTabs, "VALUEPOS" );
								if( id < count - 1 ) ++id; else id = 0;
								//IupSetInt( GLOBAL.activeDocumentTabs, "VALUEPOS", id );
								DocumentTabAction.setFocus( IupGetChild( GLOBAL.activeDocumentTabs, id ) );
								actionManager.DocumentTabAction.tabChangePOS( GLOBAL.activeDocumentTabs, id );
							}
							return IUP_IGNORE;
						}
						break;

					case "prevtab":
						if( sk.keyValue == c )
						{
							int count = IupGetChildCount( GLOBAL.activeDocumentTabs );
							if( count > 1 )
							{
								int id = IupGetInt( GLOBAL.activeDocumentTabs, "VALUEPOS" );
								if( id > 0 ) --id; else id = --count;
								//IupSetInt( GLOBAL.activeDocumentTabs, "VALUEPOS", id );
								DocumentTabAction.setFocus( IupGetChild( GLOBAL.activeDocumentTabs, id ) );
								actionManager.DocumentTabAction.tabChangePOS( GLOBAL.activeDocumentTabs, id );
							}
							return IUP_IGNORE;
						}
						break;
					case "newtab":
						if( sk.keyValue == c )
						{
							menu.newFile_cb( ih );
							return IUP_IGNORE;
						}
						break;
					case "autocomplete":
						if( sk.keyValue == c )
						{
							char[] 	alreadyInput;
							char[]	lastChar;
							int		pos = actionManager.ScintillaAction.getCurrentPos( ih );
							int		dummyHeadPos;

							if( pos > 0 ) lastChar = fromStringz( IupGetAttributeId( ih, "CHAR", pos - 1 ) ).dup; else return IUP_IGNORE;
							
							version(FBIDE)
							{
								if( GLOBAL.enableIncludeComplete == "ON" )
								{
									if( AutoComplete.checkIscludeDeclare( ih, pos - 1 ) )
									{
										alreadyInput = lastChar.dup;
										char[] list = AutoComplete.includeComplete( ih, pos - 1, alreadyInput );
										if( list.length )
										{
											//IupScintillaSendMessage( ih, 2660, 1, 0 ); //SCI_AUTOCSETORDER 2660
											if( !alreadyInput.length ) IupScintillaSendMessage( ih, 2100, alreadyInput.length, cast(int) GLOBAL.cString.convert( list ) ); else IupSetAttributeId( ih, "AUTOCSHOW", alreadyInput.length, GLOBAL.cString.convert( list ) );
											return IUP_IGNORE;
										}
									}
								}	

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
									if( GLOBAL.enableParser != "ON" )
									{
										// Check Keyword Autocomplete
										if( GLOBAL.enableKeywordComplete == "ON" )
										{
											if( alreadyInput.length )
											{
												if( fromStringz( IupGetAttribute( ih, "AUTOCACTIVE\0" ) ) != "YES" )
												{
													char[] list = AutoComplete.getKeywordContainerList( alreadyInput );
													if( list.length ) IupScintillaSendMessage( ih, 2100, alreadyInput.length, cast(int) GLOBAL.cString.convert( list ) );
												}
											}
										}
										
										return IUP_IGNORE;
									}
									
									if( alreadyInput.length ) AutoComplete.callAutocomplete( ih, pos - 1, lastChar, alreadyInput ~ " " );
								}
								catch( Exception e )
								{
									GLOBAL.IDEMessageDlg.print( "callAutocomplete() Error:\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ Integer.toString( e.line ) );
									//debug IupMessage( "ShortCut Error", toStringz( "autocompleten" ~ e.toString ) );
								}
							}
							version(DIDE)
							{
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
									debug IupMessage( "ShortCut Error", toStringz( "autocompleten" ~ e.toString ) );
								}
							}

							return IUP_IGNORE;
						}
						break;
					
					case "compilerun":
						if( sk.keyValue == c )
						{
							menu.buildrun_cb( null );
							return IUP_IGNORE;
						}
						break;
						
					case "comment":
						if( sk.keyValue == c )
						{
							menu.comment_cb();
							return IUP_IGNORE;
						}
						break;
						
					case "backnav":
						if( sk.keyValue == c )
						{
							auto cacheUnit = GLOBAL.navigation.back();
							if( cacheUnit._line != -1 ) ScintillaAction.openFile( cacheUnit._fullPath, cacheUnit._line );
							return IUP_IGNORE;
						}
						break;

					case "forwardnav":
						if( sk.keyValue == c )
						{
							auto cacheUnit = GLOBAL.navigation.forward();
							if( cacheUnit._line != -1 ) ScintillaAction.openFile( cacheUnit._fullPath, cacheUnit._line );
							return IUP_IGNORE;
						}
						break;		
					
					// Custom Tools
					case "customtool1", "customtool2", "customtool3", "customtool4", "customtool5", "customtool6", "customtool7", "customtool8", "customtool9":
						if( sk.keyValue == c )
						{
							char[]	tailChar = sk.name[$-1..$];
							int		tailNum = Integer.atoi( tailChar );
							if( tailNum > 0 && tailNum < 10 )
							{
								if( GLOBAL.customTools[tailNum].name.toDString.length )
								{
									if( GLOBAL.customTools[tailNum].dir.toDString.length )
									{
										CustomToolAction.run( GLOBAL.customTools[tailNum] );
									}
								}
							}

							return IUP_IGNORE;
						}
						break;					
						
					/*
					case "testplugin":
						if( sk.keyValue == c )
						{
							dllHandleClipboardText( ih );
							return IUP_IGNORE;
						}
						break;
					*/
						
					default:
				}
			}
		}
		catch( Exception e )
		{
			GLOBAL.IDEMessageDlg.print( "CScintilla_keyany_cb() Error:\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ Integer.toString( e.line ) );
			//debug IupMessage( "CScintilla_keyany_cb", toStringz( "CScintilla_keyany_cb Error\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ Integer.toString( e.line ) ) );
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
			scope textCovert = new IupString;
			
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
		//if( insert == 0 )IupSetInt( ih, "BRACEBADLIGHT", -1 );
		if( GLOBAL.liveLevel > 0 )
		{
			try
			{
				char[]	dText = fromStringz( _text );
				//auto	cSci = ScintillaAction.getActiveCScintilla();
				int		currentLineNum = cast(int) IupScintillaSendMessage( ih, 2166, pos, 0 ) + 1; //SCI_LINEFROMPOSITION = 2166,				

				if( insert == 1 )
				{
					if( GLOBAL.editorSetting00.FixedLineMargin == "OFF" )
					{
						if( dText == "\n" || dText == "\r\n" )
						{
							if( GLOBAL.editorSetting00.LineMargin == "ON" )
							{
								// Set margin size
								int textWidth = cast(int) IupScintillaSendMessage( ih, 2276, 33, cast(int) "9".ptr ); // SCI_TEXTWIDTH 2276
								int lineCount = IupGetInt( ih, "LINECOUNT" );
								char[] lc = Integer.toString( lineCount + 1 );
								IupSetInt( ih, "MARGINWIDTH0", ( lc.length + 1 ) * textWidth );
							}						
						}
						else
						{
							if( dText.length > 1 )
							{
								int count =  Util.count( dText, "\n" );
								if( count > 0 )
								{
									int textWidth = cast(int) IupScintillaSendMessage( ih, 2276, 33, cast(int) "9".ptr ); // SCI_TEXTWIDTH 2276
									int lineCount = IupGetInt( ih, "LINECOUNT" );
									char[] lc = Integer.toString( lineCount + 1 + count );
									IupSetInt( ih, "MARGINWIDTH0", ( lc.length + 1 ) * textWidth );
								}
							}
						}
					}
				}
				else
				{
					if( GLOBAL.editorSetting00.FixedLineMargin == "OFF" )
					{
						if( GLOBAL.editorSetting00.LineMargin == "ON" )
						{
							// Set margin size
							int textWidth = cast(int) IupScintillaSendMessage( ih, 2276, 33, cast(int) "9".ptr ); // SCI_TEXTWIDTH 2276
							int count;
							
							char[] selText = fromStringz( IupGetAttribute( ih, "SELECTEDTEXT" ) );
							
							if( selText.length )
							{
								count =  Util.count( selText, "\n" );
							}
							else
							{
								char[] prevWord = fromStringz( IupGetAttributeId( ih, "CHAR", pos ) );
								if( prevWord == "\n" || prevWord == "\r" ) count = 1;
							}
							
							if( count > 0 )
							{
								int lineCount = IupGetInt( ih, "LINECOUNT" );
								char[] lc = Integer.toString( lineCount - count );
								IupSetInt( ih, "MARGINWIDTH0", ( lc.length + 1 ) * textWidth );
							}
						}
					}					
				}
			}
			catch( Exception e )
			{
				GLOBAL.IDEMessageDlg.print( "LiveParser lineNumberAdd() Error:\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ Integer.toString( e.line ) );
			}
		}

		
		// If un-release the key, cancel
		//if( !GLOBAL.bKeyUp ) return IUP_DEFAULT;else GLOBAL.bKeyUp = false;
		if( GLOBAL.bKeyUp ) GLOBAL.bKeyUp = false;
		
		// If GLOBAL.autoCompletionTriggerWordCount = 0, cancel
		if( GLOBAL.autoCompletionTriggerWordCount <= 0 ) return IUP_DEFAULT;

		if( AutoComplete.bAutocompletionPressEnter ) return IUP_IGNORE;
		
		if( GLOBAL.bUndoRedoAction )
		{
			if( fromStringz( IupGetAttribute( ih, "REDO" ) ) == "NO" ) GLOBAL.bUndoRedoAction = false;
			if( fromStringz( IupGetAttribute( ih, "AUTOCACTIVE" ) ) == "YES" ) IupSetAttribute( ih, "AUTOCCANCEL", "YES" );
			return IUP_DEFAULT;
		}
		
		if( ScintillaAction.isComment( ih, pos ) ) return IUP_DEFAULT;
		
		version(FBIDE)
		{
			if( GLOBAL.enableIncludeComplete == "ON" )
			{
				if( AutoComplete.checkIscludeDeclare( ih, pos ) )
				{
					char[] alreadyInput = fromStringz( _text );
					char[] list = AutoComplete.includeComplete( ih, pos, alreadyInput );
					if( list.length )
					{
						//IupScintillaSendMessage( ih, 2660, 1, 0 ); //SCI_AUTOCSETORDER 2660
						if( !alreadyInput.length ) IupScintillaSendMessage( ih, 2100, alreadyInput.length - 1, cast(int) GLOBAL.cString.convert( list ) ); else IupSetAttributeId( ih, "AUTOCSHOW", alreadyInput.length - 1, GLOBAL.cString.convert( list ) );
						return IUP_DEFAULT;
					}
				}
			}
		}
		
		if( GLOBAL.enableParser != "ON" )
		{
			// Check Keyword Autocomplete
			if( GLOBAL.enableKeywordComplete == "ON" )
			{
				int dummyHeadPos;
				char[] sKeyin = fromStringz( _text );
				
				switch( sKeyin )
				{
					case " ", "\n", "\t", "\r", ")":
						IupSetAttribute( ih, "AUTOCCANCEL", "YES" );
						break;
						
					default:
						char[] word = AutoComplete.getWholeWordReverse( ih, pos, dummyHeadPos );
						word = ( word.reverse ~ sKeyin ).dup;
						if( word.length )
						{
							if( word.length < GLOBAL.autoCompletionTriggerWordCount ) return IUP_DEFAULT;
							
							char[] list;
							if( fromStringz( IupGetAttribute( ih, "AUTOCACTIVE\0" ) ) != "YES" ) list = AutoComplete.getKeywordContainerList( word );
							
							if( list.length )
								if( !word.length ) IupScintillaSendMessage( ih, 2100, word.length - 1, cast(int) GLOBAL.cString.convert( list ) ); else IupSetAttributeId( ih, "AUTOCSHOW", word.length - 1, GLOBAL.cString.convert( list ) );
						}
				}
			}
			
			return IUP_DEFAULT;
		}		
		
		if( insert == 1 )
		{
			if( length > 1 ) return IUP_DEFAULT;

			int dummyHeadPos;
			// Below code are fixed because of IUP DLL10 and D 1.076
			char[] text = fromStringz( _text );
			//text ~= _text[0];
			
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
						version(FBIDE)
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
					}
					else if( text == "." )
					{
						bDot = true;
					}
					else if( text == "(" )
					{
						bOpenParen = true;
					}
					
					if( !alreadyInput.length ) alreadyInput = AutoComplete.getWholeWordReverse( ih, pos, dummyHeadPos ).reverse ~ text;

					if( !bDot && !bOpenParen )
					{
						if( alreadyInput.length < GLOBAL.autoCompletionTriggerWordCount ) break;
						if( fromStringz( IupGetAttribute( ih, "AUTOCACTIVE\0" ) ) == "YES" ) break;
					}

					try
					{
						version(DIDE)
						{
							char[] options = ExecuterAction.getCustomCompilerOption();
							char[] activePrjName = ProjectAction.getActiveProjectName;
							if( activePrjName.length ) options = Util.trim( options ~ " " ~ GLOBAL.projectManager[activePrjName].compilerOption );
							if( options.length )
							{
								int _versionPos = Util.index( options, "-version=" );
								while( _versionPos < options.length )
								{
									char[] versionName;
									for( int i = _versionPos + 9; i < options.length; ++ i )
									{
										if( options[i] == '\t' || options[i] == ' ' ) break;
										versionName ~= options[i];
									}								
									if( versionName.length ) AutoComplete.VersionCondition ~= versionName;
									
									_versionPos = Util.index( options, "-version=", _versionPos + 9 );
								}
							}
						}
						
						AutoComplete.callAutocomplete( ih, pos, text, alreadyInput );
					}
					catch( Exception e )
					{
						GLOBAL.IDEMessageDlg.print( "callAutocomplete() Error:\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ Integer.toString( e.line ) );
					}
			}
		}
		
		return IUP_DEFAULT;
	}


	// Auto Ident
	private int CScintilla_caret_cb( Ihandle *ih, int lin, int col, int pos )
	{
		try
		{
			//IupSetInt( ih, "BRACEBADLIGHT", -1 );
			// BRACEMATCH
			if( GLOBAL.editorSetting00.BraceMatchHighlight == "ON" )
			{
				IupSetInt( ih, "BRACEBADLIGHT", -1 );
				if( !actionManager.ScintillaAction.isComment( ih, pos ) )
				{
					//int pos = actionManager.ScintillaAction.getCurrentPos( ih );
					int close = IupGetIntId( ih, "BRACEMATCH", pos );
					if( close > -1 )
					{
						IupScintillaSendMessage( ih, 2351, pos, close ); // SCI_BRACEHIGHLIGHT 2351
					}
					else
					{
						if( GLOBAL.editorSetting00.BraceMatchDoubleSidePos == "ON" )
						{
							close = IupGetIntId( ih, "BRACEMATCH", pos - 1 );
							if( close > -1 )
							{
								IupScintillaSendMessage( ih, 2351, pos - 1, close ); // SCI_BRACEHIGHLIGHT 2351
							}
						}
					}
				}
			}		
			
			if( AutoComplete.bEnter )
			{
				AutoComplete.bEnter = false;

				version(FBIDE)
				{
					bool bAutoInsert;
					if( GLOBAL.editorSetting00.AutoEnd == "ON" )
					{			
						if( pos == cast(int) IupScintillaSendMessage( ih, 2136, lin, 0 ) ) bAutoInsert = true; // SCI_GETLINEENDPOSITION 2136
					}
				}

				int lineInd = 0;
				if( GLOBAL.editorSetting00.AutoIndent == "ON" )
				{
					//Now time to deal with auto indenting
					//int lineInd = 0;

					if( lin > 0 ) lineInd = cast(int) IupScintillaSendMessage( ih, 2127, lin - 1, 0 ); // SCI_GETLINEINDENTATION = 2127
				   
					if( lineInd != 0 )   // NOT in the beginning
					{
						IupScintillaSendMessage( ih, 2126, lin, lineInd ); // SCI_SETLINEINDENTATION = 2126
						int changeLinePos = cast(int) IupScintillaSendMessage( ih, 2128, lin, 0 );
						IupScintillaSendMessage( ih, 2025, changeLinePos , 0 );// SCI_GOTOPOS = 2025,
					}
				}

				version(FBIDE)
				{
					if( bAutoInsert )
					{
						char[] insertEndText = AutoComplete.InsertEnd( ih, lin, pos );
						if( insertEndText.length )
						{
							if( insertEndText == "end if" )
							{
								char[] lineText = Util.trim( fromStringz( IupGetAttributeId( ih, "LINE", lin - 1 ) ) ); // 0 BASE
								if( lineText.length > 3 )
								{
									if( lowerCase( Util.trim( lineText[$-4..$] ) ) != "then" ) bAutoInsert = false;
								}
							}
							
							if( bAutoInsert )
							{
								char[] word;
								foreach( char[] s; Util.split( insertEndText, " " ) )
								{
									if( s.length ) word ~= ( tools.convertKeyWordCase( GLOBAL.keywordCase, s ) ~ " " );
								}
								
								IupSetAttributeId( ih, "INSERT", -1, toStringz( Util.trim( word ).dup ) );
								IupSetAttributeId( ih, "INSERT", -1, toStringz( "\n" ) );
								IupScintillaSendMessage( ih, 2126, lin + 1, lineInd ); // SCI_SETLINEINDENTATION = 2126
								IupScintillaSendMessage( ih, 2126, lin, lineInd + Integer.atoi( GLOBAL.editorSetting00.TabWidth ) ); // SCI_SETLINEINDENTATION = 2126
								IupScintillaSendMessage( ih, 2025, cast(int) IupScintillaSendMessage( ih, 2136, lin, 0 ), 0 );// SCI_GOTOPOS = 2025,  SCI_GETLINEENDPOSITION 2136
							}
						}
					}
				}
			}
			
			if( GLOBAL.editorSetting00.HighlightCurrentWord == "ON" )
			{
				IupScintillaSendMessage( ih, 2505, 0, IupGetInt( ih, "COUNT" ) ); // SCI_INDICATORCLEARRANGE = 2505
				HighlightWord( ih, pos );
			}			

			actionManager.StatusBarAction.update();
		}
		catch( Exception e )
		{
			GLOBAL.IDEMessageDlg.print( "CScintilla_caret_cb Error:\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ Integer.toString( e.line ) );
		}
		return IUP_DEFAULT;
	}

	private int CScintilla_dropfiles_cb( Ihandle *ih, char* filename, int num, int x, int y )
	{
		char[] _fn = fromStringz( filename );
		
		version(linux)
		{
			char[] result;
			
			for( int i = 0; i < _fn.length; ++ i )
			{
				if( _fn[i] != '%' )
				{
					result ~= _fn[i];
				}
				else
				{
					if( i + 2 < _fn.length )
					{
						char _a = _fn[i+1];
						char _b = _fn[i+2];
						
						char computeValue;
						
						
						if( _a >= '0' && _a <= '9' )
						{
							computeValue = ( _a - 48 ) * 16;
						}
						else if( _a >= 'A' && _a <= 'F' )
						{
							computeValue = ( _a - 55 ) * 16;
						}
						else
						{
							break;
						}
						
						if( _b >= '0' && _b <= '9' )
						{
							computeValue += ( _b - 48 );
						}
						else if( _b >= 'A' && _b <= 'F' )
						{
							computeValue += ( _b - 55 );
						}
						else
						{
							break;
						}
				
						result ~= cast(char)computeValue;
						
						i += 2;
					}
				}
			}
			
			_fn = result;
		}	
	
		scope f = new FilePath( _fn );

		if( f.exists() )
		{
			if( f.name == ".poseidon" )
			{
				char[] dir = f.path;
				if( dir.length ) dir = dir[0..length-1]; else return IUP_DEFAULT; // Remove tail '/'
				GLOBAL.projectTree.openProject( dir );
			}
			else
			{
				bool bSkip;
				//char[]	documentTabs1_CLIENTSIZE	= fromStringz( IupGetAttribute( GLOBAL.documentTabs, "CLIENTSIZE" ) );
				char[]	documentTabs1_RASTERSIZE	= fromStringz( IupGetAttribute( GLOBAL.documentTabs, "RASTERSIZE" ) );				
				//char[]	documentTabs2_CLIENTSIZE	= fromStringz( IupGetAttribute( GLOBAL.documentTabs_Sub, "CLIENTSIZE" ) );
				char[]	documentTabs2_RASTERSIZE	= fromStringz( IupGetAttribute( GLOBAL.documentTabs_Sub, "RASTERSIZE" ) );				
				char[]	tabs1Pos					= fromStringz( IupGetAttribute( GLOBAL.documentTabs, "SCREENPOSITION" ) );
				//char[]	tabs2Pos					= fromStringz( IupGetAttribute( GLOBAL.documentTabs_Sub, "SCREENPOSITION" ) );
				char[]	screenPos					= fromStringz( IupGetGlobal( "CURSORPOS" ) );
				if( screenPos.length )
				{
					int crossPos = Util.index( screenPos, "x" );
					if( crossPos < screenPos.length )
					{
						int		screenX = Integer.atoi( screenPos[0..crossPos] );
						int		screenY = Integer.atoi( screenPos[crossPos+1..$] );
						int		tabs1X, tabs1Y;
						
						if( tabs1Pos.length )
						{
							int commaPos = Util.index( tabs1Pos, "," );
							if( commaPos < tabs1Pos.length )
							{
								tabs1X = Integer.atoi( tabs1Pos[0..commaPos] );
								tabs1Y = Integer.atoi( tabs1Pos[commaPos+1..$] );
							}
						}						
						
						int		title1_H, RASTER1_W, RASTER1_H, CLIENT1_H; 
						
						//if( documentTabs1_CLIENTSIZE.length && documentTabs1_RASTERSIZE.length )
						if( documentTabs1_RASTERSIZE.length )
						{
							//crossPos = Util.index( documentTabs1_CLIENTSIZE, "x" );
							//if( crossPos < documentTabs1_CLIENTSIZE.length ) CLIENT1_H = Integer.atoi( documentTabs1_CLIENTSIZE[crossPos+1..$] );
							
							crossPos = Util.index( documentTabs1_RASTERSIZE, "x" );
							if( crossPos < documentTabs1_RASTERSIZE.length )
							{
								RASTER1_W = Integer.atoi( documentTabs1_RASTERSIZE[0..crossPos] );
								RASTER1_H = Integer.atoi( documentTabs1_RASTERSIZE[crossPos+1..$] );
								//title1_H = RASTER1_H - CLIENT1_H; 
							}
						}
						
						if( screenX > tabs1X && screenX < tabs1X + RASTER1_W )
						{
							if( screenY > tabs1Y && screenY < tabs1Y + RASTER1_H )
							{
								DocumentTabAction.setActiveDocumentTabs( GLOBAL.documentTabs );
								bSkip = true;
							}
						}

						if( !bSkip )
						{
							if( IupGetInt( GLOBAL.documentSplit, "VALUE" ) != 1000 || IupGetInt( GLOBAL.documentSplit2, "VALUE" ) != 1000 )
							{
								DocumentTabAction.setActiveDocumentTabs( GLOBAL.documentTabs_Sub );
							}
						}
					}
				}
				
				actionManager.ScintillaAction.openFile( f.toString  );
				actionManager.ScintillaAction.updateRecentFiles( f.toString );
				if( IupGetInt( GLOBAL.dndDocumentZBox, "VALUEPOS" ) == 0 ) IupSetInt( GLOBAL.dndDocumentZBox, "VALUEPOS", 1 );
			}
		}
		
		return IUP_DEFAULT;
	}
	
	private int CScintilla_zoom_cb( Ihandle *ih, int zoomInPoints )
	{
		try
		{
			int	fontWidth;
			int commaPos = Util.rindex( GLOBAL.fonts[1].fontString, "," );
			if( commaPos < GLOBAL.fonts[1].fontString.length ) fontWidth = Integer.atoi( Util.trim( GLOBAL.fonts[1].fontString[commaPos+1..$] ) ) - 2;
			
			int lineCount = IupGetInt( ih, "LINECOUNT" );
			char[] lc = Integer.toString( lineCount );

			IupSetInt( ih, "MARGINWIDTH0", ( lc.length + 1 ) * ( fontWidth + zoomInPoints )  );
		}
		catch( Exception e )
		{
			GLOBAL.IDEMessageDlg.print( "CScintilla_zoom_cb Error: " ~ e.toString );
		}
		
		return IUP_DEFAULT;
	}
	
	private void HighlightWord( Ihandle* ih, int pos )
	{
		IupSetFocus( ih );
		char[] _char = Util.trim( fromStringz( IupGetAttributeId( ih, "CHAR", pos ) ) );
		
		if( _char.length )
		{
			char[] word = AutoComplete.getWholeWordDoubleSide( ih, pos );
			word = word.reverse;
			
			char[][] splitWord = Util.split( word, "." );
			if( splitWord.length > 1 ) word = splitWord[$-1];
			
			splitWord = Util.split( word, "->" );
			if( splitWord.length > 1 ) word = splitWord[$-1];
			
			if( word.length ) _HighlightWord( ih, word );
		}
	}
	
	private void _HighlightWord( Ihandle* ih, char[] targetText )
	{
		int targetStart, TargetEnd;

		IupScintillaSendMessage( ih, 2500, 8, 0 ); // SCI_SETINDICATORCURRENT = 2500
		
		// Search Document
		IupSetAttribute( ih, "SEARCHFLAGS", null );
		IupSetInt( ih, "TARGETSTART", 0 );
		IupSetInt( ih, "TARGETEND", -1 );
		int findPos = cast(int) IupScintillaSendMessage( ih, 2197, targetText.length, cast(int) GLOBAL.cString.convert( targetText ) ); // SCI_SEARCHINTARGET = 2197,
		
		while( findPos != -1 )
		{
			targetStart = IupGetInt( ih, "TARGETSTART" );
			TargetEnd = IupGetInt( ih, "TARGETEND" );
			IupScintillaSendMessage( ih, 2504, targetStart, TargetEnd - targetStart ); // SCI_INDICATORFILLRANGE =  2504
			IupSetInt( ih, "TARGETSTART", TargetEnd );
			IupSetInt( ih, "TARGETEND", -1 );
			findPos = cast(int) IupScintillaSendMessage( ih, 2197, targetText.length, cast(int) GLOBAL.cString.convert( targetText ) ); // SCI_SEARCHINTARGET = 2197,
		}
	}
}