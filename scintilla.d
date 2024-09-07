module scintilla;

//Callback Function
private
{
	import iup.iup;
	import iup.iup_scintilla;

	import global, actionManager, menu, tools;
	import parser.ast, parser.autocompletion, parser.live;
	import layouts.debugger;
	import std.string, std.file, std.conv, Array = std.array, Path = std.path, std.encoding, Algorithm = std.algorithm, Uni = std.uni;
}

class CScintilla
{
private:
	import			images.xpm;
	
	Ihandle*		sci;
	string			fullPath, title;
	int				selectedMarkerIndex;

	void getFontAndSize( int index, out string font, out string Bold, out string Italic, out string Underline, out string Strikeout, out string size )
	{
		if( GLOBAL.fonts.length > 2 )
		{
			string[] strings = Array.split( GLOBAL.fonts[index].fontString, "," );
			if( strings.length == 2 )
			{
				if( strings[0].length )
				{
					font = strip( strings[0] );
				}

				strings[1] = strip( strings[1] );
				
				Bold = Italic = Underline = Strikeout = "NO";
				size = "10";

				foreach( s; Array.split( strings[1], " " ) )
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

	void init( string _fullPath, int insertPos )
	{
		fullPath = tools.normalizeSlash( _fullPath );
		title = Path.baseName( fullPath );
		
		if( GLOBAL.documentTabs != null )
		{
			IupSetAttribute( sci, "BORDER", "NO" );
			IupSetStrAttribute( sci, "NAME", toStringz( fullPath ) );

			if( insertPos == -1 )
			{
				if( IupAppend( GLOBAL.activeDocumentTabs, sci ) == null )
				{
					IupMessage( "ERROR", "IUP IupAppend ERROR!" );
					return;
				}
			}
			else
			{
				if( IupGetChildCount( GLOBAL.activeDocumentTabs ) > insertPos )
				{
					Ihandle* refChild = IupGetChild( GLOBAL.activeDocumentTabs, insertPos );
					if( IupInsert( GLOBAL.activeDocumentTabs, refChild, sci ) == null )
					{
						IupMessage( "ERROR", "IUP IupInsert ERROR!" );
						return;
					}
				}
			}
			
			IupMap( sci );
			IupRefresh( GLOBAL.activeDocumentTabs );
			
			int newDocumentPos = IupGetChildPos( GLOBAL.activeDocumentTabs, sci );
			IupSetStrAttributeId( GLOBAL.activeDocumentTabs, "TABTITLE", newDocumentPos, toStringz( title ) );
			DocumentTabAction.setTabItemDocumentImage( GLOBAL.activeDocumentTabs, newDocumentPos, title );
			
			// For IupFlatTabs
			IupSetStrAttributeId( GLOBAL.activeDocumentTabs , "TABTIP", newDocumentPos, toStringz( fullPath ) );
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
	BOM				encoding;
	bool			withBOM;

	this( void* _beCopiedDocument )
	{
		sci = IupScintilla();
		IupScintillaSendMessage( sci, 2358, 0 , cast(ptrdiff_t) _beCopiedDocument ); // SCI_SETDOCPOINTER 2358
	}

	this()
	{
		sci = IupScintilla();
		IupSetAttribute( sci, "EXPAND", "YES" );
		version(Windows) IupSetAttribute( sci, "KEYSUNICODE", "YES" );
	}

	this( string _fullPath, string _text, int _encoding, int _withBom, int insertPos )
	{
		try
		{
			this();

			init( _fullPath, insertPos );
			setText( _text );
			setEncoding( _encoding );
			withBOM = cast(bool) _withBom;
			
			if( sci != null )
			{
				string _size = fSTRz( IupGetAttribute( sci, "SIZE" ) );
				auto crossPos = indexOf( _size, "x" );
				if( crossPos > -1 ) IupSetStrAttribute( sci, "SCROLLWIDTH", toStringz( _size[0..crossPos] ) );
			}		
			IupScintillaSendMessage( sci, 2516, 1, 0 ); // SCI_SETSCROLLWIDTHTRACKING 2516
			//IupScintillaSendMessage( sci, 2277, 1, 0 ); // SCI_SETENDATLASTLINE 2277
			

			// Set margin size
			int textWidth = IupGetInt( sci, "STYLEFONTSIZE32" ) + 1;
			if( GLOBAL.editorSetting00.LineMargin == "ON" )
			{
				int lineCount = IupGetInt( sci, "LINECOUNT" );
				string lc = to!(string)( lineCount );
				if( GLOBAL.editorSetting00.FixedLineMargin == "OFF" )
				{
					IupSetInt( sci, "MARGINWIDTH0", ( cast(int) lc.length ) * textWidth );
				}
				else
				{
					if( lc.length > 5 ) IupSetInt( sci, "MARGINWIDTH0", ( cast(int) lc.length ) * textWidth ); else IupSetInt( sci, "MARGINWIDTH0", 5 * textWidth );
				}
			}
			else
			{
				IupSetAttribute( sci, "MARGINWIDTH0", "0" );
			}
			
			//init( _fullPath, insertPos );
			IupSetAttribute( sci, "DROPFILESTARGET", "YES" );
			IupSetAttribute( sci, "SCROLLBAR", "YES" );
			
			IupSetCallback( sci, "LINESCHANGED_CB",cast(Icallback) &CScintilla_linesChanged_cb );
			IupSetCallback( sci, "MARGINCLICK_CB",cast(Icallback) &marginclick_cb );
			IupSetCallback( sci, "BUTTON_CB",cast(Icallback) &button_cb );
			IupSetCallback( sci, "SAVEPOINT_CB",cast(Icallback) &savePoint_cb );
			IupSetCallback( sci, "K_ANY",cast(Icallback) &CScintilla_keyany_cb );
			IupSetCallback( sci, "ACTION",cast(Icallback) &CScintilla_action_cb );
			IupSetCallback( sci, "VALUECHANGED_CB",cast(Icallback) &CScintilla_VALUECHANGED_cb );
			IupSetCallback( sci, "CARET_CB",cast(Icallback) &CScintilla_caret_cb );
			IupSetCallback( sci, "AUTOCSELECTION_CB",cast(Icallback) &CScintilla_AUTOCSELECTION_cb );
			IupSetCallback( sci, "DROPFILES_CB",cast(Icallback) &CScintilla_dropfiles_cb );
			IupSetCallback( sci, "ZOOM_CB",cast(Icallback) &CScintilla_zoom_cb );
			IupSetCallback( sci, "GETFOCUS_CB",cast(Icallback) function( Ihandle* _ih )
			{
				static Ihandle* prevIHandle;
				if( _ih != prevIHandle ) // prevent double trigger
				{
					if( GLOBAL.parserSettings.enableParser == "ON" )
					{
						GLOBAL.compilerSettings.activeCompiler = tools.getActiveCompilerInformation();
						
						try
						{
							version(DIDE)
							{
								// Reset VersionCondition Container
								( cast(float[string]) AutoComplete.VersionCondition ).clear;
								string options = GLOBAL.compilerSettings.activeCompiler.Option;
								if( options.length )
								{	
									int ComplierVer = tools.DMDversion( GLOBAL.compilerSettings.activeCompiler.Compiler );
									ptrdiff_t	_versionPos;
									int			shift;
									if( ComplierVer == 4 )
									{
										_versionPos = indexOf( options, "-d-version=" );
										shift = 11;
									}
									else
									{
										_versionPos = indexOf( options, "-version=" );
										shift = 9;
									}
										
									while( _versionPos > -1 )
									{
										string versionName;
										for( int i = cast(int) _versionPos + shift; i < options.length; ++ i )
										{
											if( options[i] == '\t' || options[i] == ' ' ) break;
											versionName ~= options[i];
										}								
										
										if( versionName.length ) AutoComplete.VersionCondition[versionName] = 1;

										if( ComplierVer == 4 )
											_versionPos = indexOf( options, "-d-version=", _versionPos + 11 );
										else
											_versionPos = indexOf( options, "-version=", _versionPos + 9 );
									}
								}
							}
							version(FBIDE)
							{
								if( GLOBAL.parserSettings.conditionalCompilation == 1 )
								{
									// Reset VersionCondition Container
									( cast(float[string]) AutoComplete.VersionCondition ).clear;
									string options = GLOBAL.compilerSettings.activeCompiler.Option;
									if( options.length )
									{	
										auto _versionPos = indexOf( options, "-d" );
										while( _versionPos > -1 )
										{
											string	versionName;
											bool	bBeforeSymbol = true;
											for( int i = cast(int) _versionPos + 2; i < options.length; ++ i )
											{
												if( options[i] == '\t' || options[i] == ' ' )
												{
													if( !bBeforeSymbol ) break; else continue;
												}
												else if( options[i] == '=' )
												{
													break;
												}

												versionName ~= options[i];
											}				

											if( versionName.length ) AutoComplete.VersionCondition[Uni.toUpper(versionName)] = 1;
											_versionPos = indexOf( options, "-d", _versionPos + 2 );
										}								
									}							
								}
							}
						}
						catch( Exception e )
						{
							IupMessage( "Scintilla GET_FOCUS Error", toStringz( e.toString ) );
						}
					}
				}
				prevIHandle = _ih;
				
				return IUP_DEFAULT;
			});

			//IupSetCallback( sci, "MAP_CB",cast(Icallback) &scintilla_MAP_CB );
			IupSetCallback( sci, "MOTION_CB",cast(Icallback) &CScintilla_MOTION_CB );
			IupSetCallback( sci, "DWELL_CB",cast(Icallback) &CScintilla_DWELL_CB );
			IupSetInt( sci, "MOUSEDWELLTIME", to!(int)( GLOBAL.parserSettings.dwellDelay ) );
		}
		catch( Exception e )
		{
			IupMessage( "Bug", toStringz( "Scintilla.init() Error:\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ to!(string)( e.line ) ) );
			throw e;
		}
	}	

	~this()
	{
		IupSetHandle( toStringz( fullPath ), null );
		
		if( GLOBAL.debugPanel !is null )
		{
			if( !GLOBAL.debugPanel.isRunning && !GLOBAL.debugPanel.isExecuting )
			{
				for( int i = GLOBAL.debugPanel.getBPTable.getItemCount; i > 0; -- i )
				{
					string[] values = GLOBAL.debugPanel.getBPTable.getSelection( i );
					if( values.length == 3 )
					{
						if( values[0] == "-1" )
						{
							if( values[3] == fullPath )  GLOBAL.debugPanel.getBPTable.removeItem( i );
						}
					}
				}			
			}
		}
		
		if( GLOBAL.editorSetting00.DocStatus == "ON" )
		{
			GLOBAL.fileStatusManager[fullPathByOS(fullPath)].length = 0;
			GLOBAL.fileStatusManager[fullPathByOS(fullPath)] ~= ScintillaAction.getCurrentPos( sci );
			for( int i = 0; i < IupGetInt( sci, "LINECOUNT" ); ++ i )
			{
				if( cast(int) IupScintillaSendMessage( sci, 2230, i, 0 ) == 0 ) // SCI_GETFOLDEXPANDED 2230
				{
					GLOBAL.fileStatusManager[fullPath] ~= i;
				}
			}
		}

		GLOBAL.outlineTree.cleanTree( fullPath );
		if( fullPathByOS(fullPath) in GLOBAL.scintillaManager ) GLOBAL.scintillaManager.remove( fullPathByOS(fullPath) );
		if( sci != null )
		{
			IupDestroy( sci );
			sci = null;
		}
	}

	void setText( string _text )
	{
		IupSetStrAttribute( sci, "VALUE", toStringz( _text ) );		

		IupScintillaSendMessage( sci, 2014, 0, 0 ); // SCI_SETSAVEPOINT = 2014		
		IupScintillaSendMessage( sci, 2175, 0, 0 ); // SCI_EMPTYUNDOBUFFER = 2175
		
		// Reparse Lexer
		version(FBIDE) IupScintillaSendMessage( sci, 4003, 0, -1 ); // SCI_COLOURISE 4003
	}

	string getText()
	{
		return fromStringz( IupGetAttribute( sci, "VALUE" ) ).dup;
	}

	void setEncoding( int _encoding )
	{
		encoding = cast(BOM) _encoding;
	}
	
	int getBOM()
	{
		return encoding;
	}	

	Ihandle* getIupScintilla()
	{
		return sci;
	}

	string getTitle()
	{
		return title;
	}

	string getFullPath()
	{
		return fullPath;
	}

	void rename( string newFullPath )
	{
		// Remove Old Handle
		IupSetHandle( toStringz( fullPath ), null );
		GLOBAL.scintillaManager.remove( fullPathByOS( fullPath ) );

		fullPath = newFullPath;
		title = Path.baseName( newFullPath );

		int pos = IupGetChildPos( GLOBAL.activeDocumentTabs, sci );
		if( pos > -1 )
		{
			IupSetStrAttributeId( GLOBAL.activeDocumentTabs, "TABTITLE", pos, toStringz( title ) );
		}		
		IupSetHandle( toStringz( fullPath ), sci );

		GLOBAL.scintillaManager[fullPathByOS(fullPath)] = this;
		
		if( fullPathByOS( fullPath ) in GLOBAL.parserManager )
		{
			auto temp = GLOBAL.parserManager[fullPathByOS( fullPath )];
			if( temp !is null ) destroy( temp );
			GLOBAL.parserManager.remove( fullPathByOS( fullPath ) );
			GLOBAL.outlineTree.cleanTree( fullPath );

			GLOBAL.outlineTree.loadFile( newFullPath );
		}
		else
		{
			GLOBAL.outlineTree.loadFile( newFullPath );
		}
	}

	bool saveFile()
	{
		try
		{
			if( FileAction.saveFile( fullPath, getText, encoding, withBOM ) )
			{
				//if( ScintillaAction.getModify( sci ) != 0 )
				if( ScintillaAction.getModifyByTitle( this ) )
				{
					IupScintillaSendMessage( sci, 2014, 0, 0 ); // SCI_SETSAVEPOINT = 2014
					// Auto trigger SAVEPOINT_CB........
				}
			}
		}
		catch( Exception e )
		{
			IupMessage( "Scintilla.saveFile", "ERROR" );
			return false;
		}

		IupSetFocus( sci );
		return true;
	}

	void setGlobalSetting( bool bFirstTime = false )
	{
		string _ext = Path.extension( fullPath );
		version(FBIDE)
		{
			if( tools.isParsableExt( _ext, 7 ) ) IupSetAttribute(sci, "LEXERLANGUAGE", "freebasic" );
			for( int i = 0; i < 6; ++ i )
			{
				string _key = strip( GLOBAL.parserSettings.KEYWORDS[i] );
				if( _key.length ) IupSetStrAttribute( sci, toStringz( "KEYWORDS" ~ to!(string)( i ) ), toStringz( Uni.toLower( _key ) ) ); else IupSetStrAttribute( sci, toStringz( "KEYWORDS" ~ to!(string)( i ) ), "" );
			}
		}
		else // version(DIDE)
		{
			if( tools.isParsableExt( _ext, 3 ) ) IupSetAttribute(sci, "LEXERLANGUAGE", "d" );
			if( GLOBAL.parserSettings.KEYWORDS[0].length ) IupSetStrAttribute(sci, "KEYWORDS0", toStringz( GLOBAL.parserSettings.KEYWORDS[0] ) ); else IupSetStrAttribute( sci, "KEYWORDS0", "" );
			if( GLOBAL.parserSettings.KEYWORDS[1].length ) IupSetStrAttribute(sci, "KEYWORDS1", toStringz( GLOBAL.parserSettings.KEYWORDS[1] ) ); else IupSetStrAttribute( sci, "KEYWORDS1", "" );
			if( GLOBAL.parserSettings.KEYWORDS[2].length ) IupSetStrAttribute(sci, "KEYWORDS3", toStringz( GLOBAL.parserSettings.KEYWORDS[2] ) ); else IupSetStrAttribute( sci, "KEYWORDS3", "" );
			if( GLOBAL.parserSettings.KEYWORDS[3].length ) IupSetStrAttribute(sci, "KEYWORDS4", toStringz( GLOBAL.parserSettings.KEYWORDS[3] ) ); else IupSetStrAttribute( sci, "KEYWORDS4", "" );
			if( GLOBAL.parserSettings.KEYWORDS[4].length ) IupSetStrAttribute(sci, "KEYWORDS5", toStringz( GLOBAL.parserSettings.KEYWORDS[4] ) ); else IupSetStrAttribute( sci, "KEYWORDS5", "" );
			if( GLOBAL.parserSettings.KEYWORDS[5].length ) IupSetStrAttribute(sci, "KEYWORDS6", toStringz( GLOBAL.parserSettings.KEYWORDS[5] ) ); else IupSetStrAttribute( sci, "KEYWORDS6", "" );
		}

		string font, size = "10", Bold = "NO", Italic ="NO", Underline = "NO", Strikeout = "NO";
		version( Windows )
		{
			font = "Courier New";
		}
		else
		{
			font = "Monospace";
		}

		getFontAndSize( 1, font, Bold, Italic, Underline, Strikeout, size );

		IupSetStrAttribute( sci, "STYLEFONT32", toStringz( font ) );
		IupSetStrAttribute( sci, "STYLEFONTSIZE32", toStringz( size ) );
		IupSetStrAttribute( sci, "STYLEFGCOLOR32", toStringz( GLOBAL.editColor.scintillaFore ) );		// 32
		IupSetStrAttribute( sci, "STYLEBGCOLOR32", toStringz( GLOBAL.editColor.scintillaBack ) );		// 32
		IupSetStrAttribute( sci, "STYLEBOLD32", toStringz( Bold ) );
		IupSetStrAttribute( sci, "STYLEITALIC32", toStringz( Italic ) );
		IupSetStrAttribute( sci, "STYLEUNDERLINE32", toStringz( Underline ) );

		IupSetAttribute(sci, "STYLECLEARALL", "Yes");  /* sets all styles to have the same attributes as 32 */
		
		/*
		IupSetAttribute( sci, "FGCOLOR", toStringz( GLOBAL.editColor.scintillaFore.dup ) );
		IupSetAttribute( sci, "BGCOLOR", toStringz( GLOBAL.editColor.scintillaBack.dup ) );
		*/
		version(FBIDE)
		{
			IupSetStrAttribute( sci, "STYLEFGCOLOR1", toStringz( GLOBAL.editColor.SCE_B_COMMENT_Fore ) );		// SCE_B_COMMENT 1
			IupSetStrAttribute( sci, "STYLEBGCOLOR1", toStringz( GLOBAL.editColor.SCE_B_COMMENT_Back ) );		// SCE_B_COMMENT 1
			IupSetStrAttribute( sci, "STYLEFGCOLOR2", toStringz( GLOBAL.editColor.SCE_B_NUMBER_Fore ) );		// SCE_B_NUMBER 2
			IupSetStrAttribute( sci, "STYLEBGCOLOR2", toStringz( GLOBAL.editColor.SCE_B_NUMBER_Back ) );		// SCE_B_NUMBER 2
			IupSetStrAttribute( sci, "STYLEFGCOLOR4", toStringz( GLOBAL.editColor.SCE_B_STRING_Fore ) );		// SCE_B_STRING 4
			IupSetStrAttribute( sci, "STYLEBGCOLOR4", toStringz( GLOBAL.editColor.SCE_B_STRING_Back ) );		// SCE_B_STRING 4
			IupSetStrAttribute( sci, "STYLEFGCOLOR5", toStringz( GLOBAL.editColor.SCE_B_PREPROCESSOR_Fore ) );	// SCE_B_PREPROCESSOR 5
			IupSetStrAttribute( sci, "STYLEBGCOLOR5", toStringz( GLOBAL.editColor.SCE_B_PREPROCESSOR_Back ) );	// SCE_B_PREPROCESSOR 5
			IupSetStrAttribute( sci, "STYLEFGCOLOR6", toStringz( GLOBAL.editColor.SCE_B_OPERATOR_Fore ) );		// SCE_B_OPERATOR 6
			IupSetStrAttribute( sci, "STYLEBGCOLOR6", toStringz( GLOBAL.editColor.SCE_B_OPERATOR_Back ) );		// SCE_B_OPERATOR 6
			IupSetStrAttribute( sci, "STYLEFGCOLOR7", toStringz( GLOBAL.editColor.SCE_B_IDENTIFIER_Fore ) );	// SCE_B_IDENTIFIER 7
			IupSetStrAttribute( sci, "STYLEBGCOLOR7", toStringz( GLOBAL.editColor.SCE_B_IDENTIFIER_Back ) );	// SCE_B_IDENTIFIER 7
			IupSetStrAttribute( sci, "STYLEFGCOLOR19", toStringz( GLOBAL.editColor.SCE_B_COMMENTBLOCK_Fore ) );// SCE_B_COMMENTBLOCK 19
			IupSetStrAttribute( sci, "STYLEBGCOLOR19", toStringz( GLOBAL.editColor.SCE_B_COMMENTBLOCK_Back ) );// SCE_B_COMMENTBLOCK 19
			
			IupSetStrAttribute(sci, "STYLEFGCOLOR3", toStringz( GLOBAL.editColor.keyWord[0] ) );	// SCE_B_KEYWORD 3
			IupSetStrAttribute(sci, "STYLEFGCOLOR10", toStringz( GLOBAL.editColor.keyWord[1] ) );	// SCE_B_KEYWORD2 10
			IupSetStrAttribute(sci, "STYLEFGCOLOR11", toStringz( GLOBAL.editColor.keyWord[2] ) );	// SCE_B_KEYWORD3 11
			IupSetStrAttribute(sci, "STYLEFGCOLOR12", toStringz( GLOBAL.editColor.keyWord[3] ) );	// SCE_B_KEYWORD4 12
			IupSetStrAttribute(sci, "STYLEFGCOLOR23", toStringz( GLOBAL.editColor.keyWord[4] ) );	// SCE_B_KEYWORD5 23
			IupSetStrAttribute(sci, "STYLEFGCOLOR24", toStringz( GLOBAL.editColor.keyWord[5] ) );	// SCE_B_KEYWORD6 24
		}
		version(DIDE)
		{
			IupSetStrAttribute( sci, "STYLEFGCOLOR1", toStringz( GLOBAL.editColor.SCE_B_COMMENT_Fore ) );		// SCE_D_COMMENT 1
			IupSetStrAttribute( sci, "STYLEBGCOLOR1", toStringz( GLOBAL.editColor.SCE_B_COMMENT_Back ) );		// SCE_D_COMMENT 1
			IupSetStrAttribute( sci, "STYLEFGCOLOR2", toStringz( GLOBAL.editColor.SCE_B_COMMENT_Fore ) );		// SCE_D_COMMENTLINE 2
			IupSetStrAttribute( sci, "STYLEBGCOLOR2", toStringz( GLOBAL.editColor.SCE_B_COMMENT_Back ) );		// SCE_D_COMMENTLINE 2
			IupSetStrAttribute( sci, "STYLEFGCOLOR3", toStringz( GLOBAL.editColor.SCE_B_COMMENT_Fore ) );		// SCE_D_COMMENTDOC 3
			IupSetStrAttribute( sci, "STYLEBGCOLOR3", toStringz( GLOBAL.editColor.SCE_B_COMMENT_Back ) );		// SCE_D_COMMENTDOC 3
			
			IupSetStrAttribute( sci, "STYLEFGCOLOR4", toStringz( GLOBAL.editColor.SCE_B_COMMENTBLOCK_Fore ) );		// SCE_D_COMMENTNESTED 4
			IupSetStrAttribute( sci, "STYLEBGCOLOR4", toStringz( GLOBAL.editColor.SCE_B_COMMENTBLOCK_Back ) );		// SCE_D_COMMENTNESTED 4
			
			IupSetStrAttribute( sci, "STYLEFGCOLOR5", toStringz( GLOBAL.editColor.SCE_B_NUMBER_Fore ) );		// SCE_D_NUMBER 5
			IupSetStrAttribute( sci, "STYLEBGCOLOR5", toStringz( GLOBAL.editColor.SCE_B_NUMBER_Back ) );		// SCE_D_NUMBER 5
			
			
			IupSetStrAttribute( sci, "STYLEFGCOLOR10", toStringz( GLOBAL.editColor.SCE_B_STRING_Fore ) );		// SCE_D_STRING 10
			IupSetStrAttribute( sci, "STYLEBGCOLOR10", toStringz( GLOBAL.editColor.SCE_B_STRING_Back ) );		// SCE_D_STRING 10
			
			IupSetStrAttribute( sci, "STYLEFGCOLOR12", toStringz( GLOBAL.editColor.SCE_B_PREPROCESSOR_Fore ) );	// SCE_D_CHARACTER 12
			IupSetStrAttribute( sci, "STYLEBGCOLOR12", toStringz( GLOBAL.editColor.SCE_B_PREPROCESSOR_Back ) );	// SCE_D_CHARACTER 12
			
			IupSetStrAttribute( sci, "STYLEFGCOLOR13", toStringz( GLOBAL.editColor.SCE_B_OPERATOR_Fore ) );		// SCE_D_OPERATOR 13
			IupSetStrAttribute( sci, "STYLEBGCOLOR13", toStringz( GLOBAL.editColor.SCE_B_OPERATOR_Back ) );		// SCE_D_OPERATOR 13
			
			IupSetStrAttribute( sci, "STYLEFGCOLOR14", toStringz( GLOBAL.editColor.SCE_B_IDENTIFIER_Fore ) );	// SCE_D_IDENTIFIER 14
			IupSetStrAttribute( sci, "STYLEBGCOLOR14", toStringz( GLOBAL.editColor.SCE_B_IDENTIFIER_Back ) );	// SCE_D_IDENTIFIER 14
			
			
			IupSetStrAttribute(sci, "STYLEFGCOLOR6", toStringz( GLOBAL.editColor.keyWord[0] ) );			// SCE_D_WORD 6	
			IupSetStrAttribute(sci, "STYLEFGCOLOR7", toStringz( GLOBAL.editColor.keyWord[1] ) );			// SCE_D_WORD2 7
			IupSetStrAttribute(sci, "STYLEFGCOLOR9", toStringz( GLOBAL.editColor.keyWord[2] ) );			// SCE_D_TYPEDEF 9
			IupSetStrAttribute(sci, "STYLEFGCOLOR20",  toStringz( GLOBAL.editColor.keyWord[3] ) );		// SCE_D_WORD5 20
			IupSetStrAttribute(sci, "STYLEFGCOLOR21",  toStringz( GLOBAL.editColor.keyWord[4] ) );		// SCE_D_WORD6 21
			IupSetStrAttribute(sci, "STYLEFGCOLOR22",  toStringz( GLOBAL.editColor.keyWord[5] ) );		// SCE_D_WORD7 22
		}
		

		// Brace Hightlight
		IupSetStrAttribute(sci, "STYLEFGCOLOR34", toStringz( GLOBAL.editColor.braceFore ) );	
		IupSetStrAttribute(sci, "STYLEBGCOLOR34", toStringz( GLOBAL.editColor.braceBack ) );
		IupSetAttribute(sci, "STYLEFGCOLOR35", "255 255 0");
		IupSetAttribute(sci, "STYLEBGCOLOR35", "255 0 255");
		
		IupSetAttribute(sci, "STYLEBOLD34", "YES");
		//IupScintillaSendMessage( sci, 2053, 34, 1 );
		version(Windows) tools.setWinTheme( sci, "Explorer", GLOBAL.editorSetting00.UseDarkMode == "ON" ? true : false );
		
		// Character representations
		// Set Control Character to <space>
		IupScintillaSendMessage( sci, 2388, to!(size_t)( GLOBAL.editorSetting00.ControlCharSymbol ), 0 ); // SCI_SETCONTROLCHARSYMBOL 2388
		//IupSetAttribute(sci, "STYLEFGCOLOR36", "255 255 0");
		//IupSetAttribute(sci, "STYLEBGCOLOR36", "255 255 255");
		//IupSetAttribute(sci, "STYLEFONTSIZE36", "60");		

		// Set Keywords to Bold
		if( GLOBAL.editorSetting00.BoldKeyword == "ON" )
		{
			version(FBIDE)
			{
				IupSetAttribute(sci, "STYLEBOLD3", "YES");
				IupSetAttribute(sci, "STYLEBOLD10", "YES");
				IupSetAttribute(sci, "STYLEBOLD11", "YES");
				IupSetAttribute(sci, "STYLEBOLD12", "YES");
				IupSetAttribute(sci, "STYLEBOLD23", "YES");
				IupSetAttribute(sci, "STYLEBOLD24", "YES");
			}
			version(DIDE)
			{
				IupSetAttribute(sci, "STYLEBOLD6", "YES");
				IupSetAttribute(sci, "STYLEBOLD7", "YES");
				IupSetAttribute(sci, "STYLEBOLD9", "YES");				
				IupSetAttribute(sci, "STYLEBOLD20", "YES");
				IupSetAttribute(sci, "STYLEBOLD21", "YES");
				IupSetAttribute(sci, "STYLEBOLD22", "YES");
			}
		}
		

		getFontAndSize( 10, font, Bold, Italic, Underline, Strikeout, size );
		IupSetStrAttribute(sci, "STYLEFGCOLOR40", toStringz( GLOBAL.editColor.errorFore ));	
		IupSetStrAttribute(sci, "STYLEBGCOLOR40", toStringz( GLOBAL.editColor.errorBack ));
		IupSetStrAttribute(sci, "STYLEFONT40",  toStringz( font ) );
		IupSetStrAttribute(sci, "STYLEFONTSIZE40",  toStringz( size ) );

		IupScintillaSendMessage( sci, 2207, cast(size_t) tools.convertIupColor( GLOBAL.editColor.callTipHLT ), 0 ); // SCI_CALLTIPSETFOREHLT 2207
		/*
		IupSetAttribute(sci, "STYLEFONTSIZE38",  "10" );
		IupScintillaSendMessage( sci, 2205, tools.convertIupColor( "210 255 255" ), 0 ); // SCI_CALLTIPSETBACK 2205
		IupScintillaSendMessage( sci, 2206, tools.convertIupColor( "0 0 255" ), 0 ); // SCI_CALLTIPSETFORE 2206
		IupScintillaSendMessage( sci, 2212, 4, 0 );
		//IupSetAttribute(sci, "STYLEBOLD38", "YES");
		*/
		
		IupSetStrAttribute(sci, "STYLEFGCOLOR41", toStringz( GLOBAL.editColor.warningFore ));
		IupSetStrAttribute(sci, "STYLEBGCOLOR41", toStringz( GLOBAL.editColor.warningBack ));
		IupSetStrAttribute(sci, "STYLEFONT41",  toStringz( font ) );
		IupSetStrAttribute(sci, "STYLEFONTSIZE41",  toStringz( size ) );
		
		// Use Stefan Küng's patch, modified iup_scintilla
		// https://groups.google.com/g/scintilla-interest/c/Iov-C9-BUfM
		version(Windows)
		{
			IupSetStrAttribute(sci, "STYLEFGCOLOR99", toStringz( GLOBAL.editColor.autoCompleteFore ));
			IupSetStrAttribute(sci, "STYLEBGCOLOR99", toStringz( GLOBAL.editColor.autoCompleteBack ));
			IupSetStrAttribute(sci, "STYLEFGCOLOR100", toStringz( GLOBAL.editColor.autoCompleteHLTFore ));
			IupSetStrAttribute(sci, "STYLEBGCOLOR100", toStringz( GLOBAL.editColor.autoCompleteHLTBack ));
			IupScintillaSendMessage( sci, 2719, 1, to!(ptrdiff_t)( GLOBAL.editorSetting02.autocompleteDlg ) ); // SCI_AUTOCSETUSESTYLE 2719 (Stefan Küng's patch)
		}

		IupSetStrAttribute( sci, "TABSIZE", toStringz( GLOBAL.editorSetting00.TabWidth ) );

		if( !bFirstTime )
		{
			int textWidth = IupGetInt( sci, "STYLEFONTSIZE32" ) + 1;
			if( GLOBAL.editorSetting00.LineMargin == "ON" )
			{
				int lineCount = IupGetInt( sci, "LINECOUNT" );
				string lc = to!(string)( lineCount );
				if( GLOBAL.editorSetting00.FixedLineMargin == "OFF" )
				{
					IupSetInt( sci, "MARGINWIDTH0", ( cast(int) lc.length ) * textWidth );
				}
				else
				{
					if( lc.length > 5 ) IupSetInt( sci, "MARGINWIDTH0", ( cast(int) lc.length ) * textWidth ); else IupSetInt( sci, "MARGINWIDTH0", 5 * textWidth );
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
			/+
			IupSetAttribute(sci, "PROPERTY", "fold=1");
			IupSetAttribute(sci, "PROPERTY", "fold.basic.comment.explicit=0");
			IupSetAttribute(sci, "PROPERTY", "fold.basic.explicit.anywhere=0");
			IupSetAttribute(sci, "PROPERTY", "fold.basic.explicit.end=1");
			IupSetAttribute(sci, "PROPERTY", "fold.basic.explicit.start=1");
			IupSetAttribute(sci, "PROPERTY", "fold.basic.syntax.based=1");
			IupSetAttribute(sci, "PROPERTY", "fold.compact=0");
			IupSetAttribute(sci, "PROPERTY", "fold.comment=1");
			IupSetAttribute(sci, "PROPERTY", "fold.preprocessor=1");
			+/

			IupSetAttribute( sci, "MARGINWIDTH2", "20" );
			IupSetAttribute( sci, "MARGINMASKFOLDERS2",  "YES" );
			
			IupSetAttribute( sci, "MARKERDEFINE", "FOLDER=PLUS");
			IupSetAttribute( sci, "MARKERDEFINE", "FOLDEROPEN=MINUS" );
			IupSetAttribute( sci, "MARKERDEFINE", "FOLDEREND=EMPTY" );
			IupSetAttribute( sci, "MARKERDEFINE", "FOLDERMIDTAIL=EMPTY" );
			IupSetAttribute( sci, "MARKERDEFINE", "FOLDEROPENMID=EMPTY" );
			IupSetAttribute( sci, "MARKERDEFINE", "FOLDERSUB=EMPTY" );
			IupSetAttribute( sci, "MARKERDEFINE", "FOLDERTAIL=EMPTY" );
			/+
			IupSetAttribute( sci, "MARKERDEFINE", "FOLDER=BOXPLUS");
			IupSetAttribute( sci, "MARKERDEFINE", "FOLDEROPEN=BOXMINUS" );
			IupSetAttribute( sci, "MARKERDEFINE", "FOLDEREND=BOXPLUSCONNECTED" );
			IupSetAttribute( sci, "MARKERDEFINE", "FOLDERMIDTAIL=TCORNER" );
			IupSetAttribute( sci, "MARKERDEFINE", "FOLDEROPENMID=BOXMINUSCONNECTED" );
			IupSetAttribute( sci, "MARKERDEFINE", "FOLDERSUB=VLINE" );
			IupSetAttribute( sci, "MARKERDEFINE", "FOLDERTAIL=TCORNER" );
			+/
			IupSetAttribute( sci, "FOLDFLAGS", "LINEAFTER_CONTRACTED" );
			IupSetAttribute( sci, "MARGINSENSITIVE2", "YES" );
			IupSetStrAttribute( sci, "FOLDMARGINCOLOR", toStringz( GLOBAL.editColor.fold ) );
			IupSetStrAttribute( sci, "FOLDMARGINHICOLOR", toStringz( GLOBAL.editColor.fold ) );
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
		IupScintillaSendMessage( sci, 2106, cast(size_t) '^', 0 ); //#define SCI_AUTOCSETSEPARATOR 2106
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
			IupScintillaSendMessage( sci, 2084, 1, cast(ptrdiff_t) tools.convertIupColor( "177 177 177" ) );
		}
		else
		{
			IupScintillaSendMessage( sci, 2021, 0, 0 );
		}


		// Color
		IupScintillaSendMessage( sci, 2098, cast(size_t) tools.convertIupColor( GLOBAL.editColor.caretLine ), 0 ); //SCI_SETCARETLINEBACK = 2098

		uint alpha = to!(int)( GLOBAL.editColor.selAlpha );
		if( alpha > 255 )
			alpha = 255;
		else if( alpha < 0 )
			alpha = 0;

		if( alpha == 255 )
		{
			IupScintillaSendMessage( sci, 2067, 1, cast(ptrdiff_t) tools.convertIupColor( GLOBAL.editColor.selectionFore ) );// SCI_SETSELFORE = 2067,
			IupScintillaSendMessage( sci, 2068, 1, cast(ptrdiff_t) tools.convertIupColor( GLOBAL.editColor.selectionBack ) );// SCI_SETSELBACK = 2068,
			IupScintillaSendMessage( sci, 2478, 256, 0 );// SCI_SETSELALPHA   2478
		}
		else if( alpha == 0 )
		{
			IupScintillaSendMessage( sci, 2067, 0, cast(ptrdiff_t) tools.convertIupColor( GLOBAL.editColor.selectionFore ) );// SCI_SETSELFORE = 2067,
			IupScintillaSendMessage( sci, 2068, 1, cast(ptrdiff_t) tools.convertIupColor( GLOBAL.editColor.selectionBack ) );// SCI_SETSELBACK = 2068,
			IupScintillaSendMessage( sci, 2478, 256, 0 );// SCI_SETSELALPHA   2478
		}
		else
		{
			IupScintillaSendMessage( sci, 2067, 0, cast(ptrdiff_t) tools.convertIupColor( GLOBAL.editColor.selectionFore ) );// SCI_SETSELFORE = 2067,
			IupScintillaSendMessage( sci, 2068, 1, cast(ptrdiff_t) tools.convertIupColor( GLOBAL.editColor.selectionBack ) );// SCI_SETSELBACK = 2068,
			IupScintillaSendMessage( sci, 2478, alpha, 0 );// SCI_SETSELALPHA   2478
		}
		
		IupSetStrAttribute( sci, "STYLEFGCOLOR33", toStringz( GLOBAL.editColor.linenumFore ) );
		IupSetStrAttribute( sci, "STYLEBGCOLOR33", toStringz( GLOBAL.editColor.linenumBack ) );
		// Error, Couldn't change......
		/*
		IupScintillaSendMessage( sci, 2290, 0, 0xffffff ); // SCI_SETFOLDMARGINCOLOUR = 2290,
		*/
		IupScintillaSendMessage( sci, 2069, cast(size_t) tools.convertIupColor( GLOBAL.editColor.cursor ), 0 ); // SCI_SETCARETFORE = 2069,

		//IupSetAttribute( sci, "FOLDFLAGS", "LEVELNUMBERS" );  

		IupScintillaSendMessage( sci, 2655, 1, 0 ); // SCI_SETCARETLINEVISIBLEALWAYS = 2655,

		// SCI_AUTOCSETIGNORECASE 2115
		if( GLOBAL.parserSettings.toggleIgnoreCase == "ON" ) IupScintillaSendMessage( sci, 2115, 1, 0 ); else IupScintillaSendMessage( sci, 2115, 0, 0 );

		// SCI_AUTOCSETCASEINSENSITIVEBEHAVIOUR 2634
		if(GLOBAL.parserSettings.toggleCaseInsensitive == "ON" ) IupScintillaSendMessage( sci, 2634, 1, 0 ); else IupScintillaSendMessage( sci, 2634, 0, 0 );
		
		//IupScintillaSendMessage( sci, 2118, 0, 0 ); // SCI_AUTOCSETAUTOHIDE 2118
		version(FBIDE) IupScintillaSendMessage( sci, 2660, 1, 0 ); //SCI_AUTOCSETORDER 2660

		IupSetAttribute( sci, "SIZE", "NULL" );
		//IupSetAttribute( sci, "VISIBLELINES", "60" );

		IupSetInt( sci, "AUTOCMAXHEIGHT", GLOBAL.autoCMaxHeight );
		int columnEdge = to!(int)( GLOBAL.editorSetting00.ColumnEdge );
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
		IupSetInt( sci, "MOUSEDWELLTIME", to!(int)( GLOBAL.parserSettings.dwellDelay ) );
		
		if( GLOBAL.editorSetting00.BraceMatchHighlight == "OFF" ) IupScintillaSendMessage( sci, 2351, -1, -1 ); // SCI_BRACEHIGHLIGHT 2351
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
		//IupSetAttributeId( sci, "INDICATORSTYLE", 8, "STRAIGHTBOX" );
		IupScintillaSendMessage( sci, 2080, 8, GLOBAL.indicatorStyle ); //SCI_INDICSETSTYLE = 2080
		//IupScintillaSendMessage( sci, 2284, 1, 0 ); //SCI_SETTWOPHASEDRAW = 2284		
		//IupScintillaSendMessage( sci, 2510, 8, 1 ); //SCI_INDICSETUNDER = 2510
		IupScintillaSendMessage( sci, 2082, 8, cast(ptrdiff_t) tools.convertIupColor( GLOBAL.editColor.currentWord ) ); // SCI_INDICSETFORE = 2082
		
		alpha = to!(int)( GLOBAL.editColor.currentWordAlpha );
		if( alpha <= 0 )
			alpha = 0;
		else if( alpha > 255 )
			alpha = 255;
		
		IupScintillaSendMessage( sci, 2523, 8, alpha ); // SCI_INDICSETALPHA = 2523
		if( alpha + 64 <= 255 ) 
			IupScintillaSendMessage( sci, 2558, 8, alpha + 64 ); // SCI_INDICSETOUTLINEALPHA 2558
		else
			IupScintillaSendMessage( sci, 2558, 8, 255 ); // SCI_INDICSETOUTLINEALPHA 2558
		
		// Scintilla White space
		IupScintillaSendMessage( sci, 2525, cast(size_t) to!(int)( GLOBAL.editorSetting01.EXTRAASCENT ), 0 ); // SCI_SETEXTRAASCENT 2525
		IupScintillaSendMessage( sci, 2527, cast(size_t) to!(int)( GLOBAL.editorSetting01.EXTRADESCENT ), 0 ); // SCI_SETEXTRADESCENT 2527
		
		version(FBIDE)
		{
			// Autocompletion XPM Image
			IupScintillaSendMessage( sci, 2624, 16, 0 ); // SCI_RGBAIMAGESETWIDTH 2624
			IupScintillaSendMessage( sci, 2625, 16, 0 ); // SCI_RGBAIMAGESETHEIGHT 2625


			/+
			// SCI_REGISTERRGBAIMAGE 2627
			IupScintillaSendMessage( sci, 2627, 0, cast(ptrdiff_t) XPM.private_variable_array_rgba.toCString );
			IupScintillaSendMessage( sci, 2627, 1, cast(ptrdiff_t) XPM.protected_variable_array_rgba.toCString ); 
			IupScintillaSendMessage( sci, 2627, 2, cast(ptrdiff_t) XPM.public_variable_array_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627

			IupScintillaSendMessage( sci, 2627, 3, cast(ptrdiff_t) XPM.private_variable_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 4, cast(ptrdiff_t) XPM.protected_variable_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 5, cast(ptrdiff_t) XPM.public_variable_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			
			IupScintillaSendMessage( sci, 2627, 6, cast(ptrdiff_t) XPM.class_private_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 7, cast(ptrdiff_t) XPM.class_protected_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 8, cast(ptrdiff_t) XPM.class_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			
			IupScintillaSendMessage( sci, 2627, 9, cast(ptrdiff_t) XPM.struct_private_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 10, cast(ptrdiff_t) XPM.struct_protected_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 11, cast(ptrdiff_t) XPM.struct_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			+/
			
			IupScintillaSendMessage( sci, 2627, 0, cast(ptrdiff_t) XPM.normal_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			
			IupScintillaSendMessage( sci, 2627, 1, cast(ptrdiff_t) XPM.private_variable_array_rgba.toCString );
			IupScintillaSendMessage( sci, 2627, 2, cast(ptrdiff_t) XPM.protected_variable_array_rgba.toCString ); 
			IupScintillaSendMessage( sci, 2627, 3, cast(ptrdiff_t) XPM.public_variable_array_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627

			IupScintillaSendMessage( sci, 2627, 4, cast(ptrdiff_t) XPM.private_variable_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 5, cast(ptrdiff_t) XPM.protected_variable_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 6, cast(ptrdiff_t) XPM.public_variable_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			
			IupScintillaSendMessage( sci, 2627, 7, cast(ptrdiff_t) XPM.class_private_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 8, cast(ptrdiff_t) XPM.class_protected_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 9, cast(ptrdiff_t) XPM.class_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			
			IupScintillaSendMessage( sci, 2627, 10, cast(ptrdiff_t) XPM.struct_private_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 11, cast(ptrdiff_t) XPM.struct_protected_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 12, cast(ptrdiff_t) XPM.struct_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627


			
			//IupScintillaSendMessage( sci, 2627, 12, cast(ptrdiff_t) XPM.enum_private_obj_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 13, cast(ptrdiff_t) XPM.enum_protected_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 14, cast(ptrdiff_t) XPM.enum_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			
			IupScintillaSendMessage( sci, 2627, 15, cast(ptrdiff_t) XPM.union_private_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 16, cast(ptrdiff_t) XPM.union_protected_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 17, cast(ptrdiff_t) XPM.union_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627

			IupScintillaSendMessage( sci, 2627, 18, cast(ptrdiff_t) XPM.parameter_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 19, cast(ptrdiff_t) XPM.enum_member_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 20, cast(ptrdiff_t) XPM.alias_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627

			IupScintillaSendMessage( sci, 2627, 21, cast(ptrdiff_t) XPM.normal_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			
			IupScintillaSendMessage( sci, 2627, 22, cast(ptrdiff_t) XPM.macro_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			//IupScintillaSendMessage( sci, 2627, 23, cast(ptrdiff_t) XPM.autoWord_rgba.toStringz ); // SCI_REGISTERRGBAIMAGE = 2627

			IupScintillaSendMessage( sci, 2627, 24, cast(ptrdiff_t) XPM.namespace_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627

			IupScintillaSendMessage( sci, 2627, 25, cast(ptrdiff_t) XPM.private_sub_rgba.toCString );
			IupScintillaSendMessage( sci, 2627, 26, cast(ptrdiff_t) XPM.protected_sub_rgba.toCString ); // SCI_REGISTERIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 27, cast(ptrdiff_t) XPM.public_sub_rgba.toCString ); // SCI_REGISTERIMAGE = 2627
			
			IupScintillaSendMessage( sci, 2627, 28, cast(ptrdiff_t) XPM.private_fun_rgba.toCString );
			IupScintillaSendMessage( sci, 2627, 29, cast(ptrdiff_t) XPM.protected_fun_rgba.toCString ); // SCI_REGISTERIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 30, cast(ptrdiff_t) XPM.public_fun_rgba.toCString ); // SCI_REGISTERIMAGE = 2627
			
			IupScintillaSendMessage( sci, 2627, 31, cast(ptrdiff_t) XPM.property_rgba.toCString ); // SCI_REGISTERIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 32, cast(ptrdiff_t) XPM.property_var_rgba.toCString ); // SCI_REGISTERIMAGE = 2627
			
			IupScintillaSendMessage( sci, 2627, 33, cast(ptrdiff_t) XPM.define_var_rgba.toCString ); // SCI_REGISTERIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 34, cast(ptrdiff_t) XPM.define_fun_rgba.toCString ); // SCI_REGISTERIMAGE = 2627
			
			IupScintillaSendMessage( sci, 2627, 35, cast(ptrdiff_t) XPM.bas_rgba.toCString ); // SCI_REGISTERIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 36, cast(ptrdiff_t) XPM.bi_rgba.toCString ); // SCI_REGISTERIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 37, cast(ptrdiff_t) XPM.folder_rgba.toCString ); // SCI_REGISTERIMAGE = 2627
			

			// BOOKMARK
			IupScintillaSendMessage( sci, 2626, 1, cast(ptrdiff_t) XPM.bookmark_rgba.toCString ); // SCI_MARKERDEFINERGBAIMAGE 2626
		}
		version(DIDE)
		{
			// Autocompletion XPM Image
			IupScintillaSendMessage( sci, 2624, 16, 0 ); // SCI_RGBAIMAGESETWIDTH 2624
			IupScintillaSendMessage( sci, 2625, 16, 0 ); // SCI_RGBAIMAGESETHEIGHT 2625

			// SCI_REGISTERRGBAIMAGE 2627
			IupScintillaSendMessage( sci, 2627, 0, cast(ptrdiff_t) XPM.private_variable_array_rgba.toCString );
			IupScintillaSendMessage( sci, 2627, 1, cast(ptrdiff_t) XPM.protected_variable_array_rgba.toCString ); 
			IupScintillaSendMessage( sci, 2627, 2, cast(ptrdiff_t) XPM.public_variable_array_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627

			IupScintillaSendMessage( sci, 2627, 3, cast(ptrdiff_t) XPM.private_variable_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 4, cast(ptrdiff_t) XPM.protected_variable_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 5, cast(ptrdiff_t) XPM.public_variable_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			
			IupScintillaSendMessage( sci, 2627, 6, cast(ptrdiff_t) XPM.class_private_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 7, cast(ptrdiff_t) XPM.class_protected_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 8, cast(ptrdiff_t) XPM.class_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			
			IupScintillaSendMessage( sci, 2627, 9, cast(ptrdiff_t) XPM.struct_private_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 10, cast(ptrdiff_t) XPM.struct_protected_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 11, cast(ptrdiff_t) XPM.struct_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			
			//IupScintillaSendMessage( sci, 2627, 12, cast(ptrdiff_t) XPM.enum_private_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 13, cast(ptrdiff_t) XPM.enum_protected_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 14, cast(ptrdiff_t) XPM.enum_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			
			IupScintillaSendMessage( sci, 2627, 15, cast(ptrdiff_t) XPM.union_private_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 16, cast(ptrdiff_t) XPM.union_protected_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 17, cast(ptrdiff_t) XPM.union_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627

			IupScintillaSendMessage( sci, 2627, 18, cast(ptrdiff_t) XPM.parameter_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 19, cast(ptrdiff_t) XPM.enum_member_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 20, cast(ptrdiff_t) XPM.alias_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627

			IupScintillaSendMessage( sci, 2627, 21, cast(ptrdiff_t) XPM.normal_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 22, cast(ptrdiff_t) XPM.import_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 23, cast(ptrdiff_t) XPM.template_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627

			IupScintillaSendMessage( sci, 2627, 24, cast(ptrdiff_t) XPM.namespace_obj_rgba.toCString ); // SCI_REGISTERRGBAIMAGE = 2627

			IupScintillaSendMessage( sci, 2627, 25, cast(ptrdiff_t) XPM.private_sub_rgba.toCString );
			IupScintillaSendMessage( sci, 2627, 26, cast(ptrdiff_t) XPM.protected_sub_rgba.toCString ); // SCI_REGISTERIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 27, cast(ptrdiff_t) XPM.public_sub_rgba.toCString ); // SCI_REGISTERIMAGE = 2627
			
			IupScintillaSendMessage( sci, 2627, 28, cast(ptrdiff_t) XPM.private_fun_rgba.toCString );
			IupScintillaSendMessage( sci, 2627, 29, cast(ptrdiff_t) XPM.protected_fun_rgba.toCString ); // SCI_REGISTERIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 30, cast(ptrdiff_t) XPM.public_fun_rgba.toCString ); // SCI_REGISTERIMAGE = 2627
			
			IupScintillaSendMessage( sci, 2627, 31, cast(ptrdiff_t) XPM.alias_obj_rgba.toCString ); // SCI_REGISTERIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 32, cast(ptrdiff_t) XPM.interface_obj_rgba.toCString ); // SCI_REGISTERIMAGE = 2627


			IupScintillaSendMessage( sci, 2627, 33, cast(ptrdiff_t) XPM.define_var_rgba.toCString ); // SCI_REGISTERIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 34, cast(ptrdiff_t) XPM.define_fun_rgba.toCString ); // SCI_REGISTERIMAGE = 2627

			IupScintillaSendMessage( sci, 2627, 35, cast(ptrdiff_t) XPM.bas_rgba.toCString ); // SCI_REGISTERIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 36, cast(ptrdiff_t) XPM.bi_rgba.toCString ); // SCI_REGISTERIMAGE = 2627
			IupScintillaSendMessage( sci, 2627, 37, cast(ptrdiff_t) XPM.folder_rgba.toCString ); // SCI_REGISTERIMAGE = 2627

			// BOOKMARK
			IupScintillaSendMessage( sci, 2626, 1, cast(ptrdiff_t) XPM.bookmark_rgba.toCString ); // SCI_MARKERDEFINERGBAIMAGE 2626
		}
		/+
		// Set Custom Properties( Scintilla )
		foreach( char[] p; GLOBAL.properties )
			IupSetStrAttribute(sci, "PROPERTY", toStringz( p ) );
		+/
	}
}




extern(C)
{
	private int CScintilla_linesChanged_cb( Ihandle* ih, int lin, int num )
	{
		//IupMessage( "", toStringz( "Num=" ~ Integer.toString( num ) ~ "\nLin=" ~ Integer.toString( lin + 1 ) ) );
		
		CScintilla cSci = ScintillaAction.getActiveCScintilla;
		
		if( cSci !is null )
			if( fullPathByOS( cSci.getFullPath ) in GLOBAL.parserManager )
			{
				string prevLineText = fSTRz( IupGetAttributeId( ih, "LINE", lin ) );
				if( !strip( prevLineText ).length )
				{
					LiveParser.lineNumberAdd( cast(CASTnode) GLOBAL.parserManager[fullPathByOS( cSci.getFullPath )], lin, num );
					//IupMessage( "", toStringz( "Num=" ~ Integer.toString( num ) ~ "\nLin=" ~ Integer.toString( lin ) ) );
				}
				else
				{
					LiveParser.lineNumberAdd( cast(CASTnode) GLOBAL.parserManager[fullPathByOS( cSci.getFullPath )], lin + 1, num );
				}
			}
		
		return IUP_DEFAULT;
	}
	
	private int marginclick_cb( Ihandle* ih, int margin, int line, char* status )
	{
		string statusString = fSTRz( status );
		switch( margin )
		{
			case 1:
				// With control
				if( statusString[1] == 'C' ) 
				{
					if( GLOBAL.debugPanel !is null )
					{
						if( GLOBAL.debugPanel.isExecuting() )
						{
							uint state = IupGetIntId( ih, "MARKERGET", line );
							if( state & ( 1 << 2 ) )
							{
								IupScintillaSendMessage( ih, 2044, line, 2 ); // #define SCI_MARKERDELETE 2044
								GLOBAL.debugPanel.removeBP( actionManager.ScintillaAction.getActiveCScintilla.getFullPath, to!(string)( ++line ) );
							}
							else
							{
								IupScintillaSendMessage( ih, 2043, line, 2 ); // #define SCI_MARKERADD 2043
								GLOBAL.debugPanel.addBP( actionManager.ScintillaAction.getActiveCScintilla.getFullPath, to!(string)( ++line ) );
							}
						}
					}
					break;
				}
				else
				{
					if( IupGetIntId( ih, "MARKERGET", line ) & 2 )
					{
						IupSetIntId( ih, "MARKERDELETE", line, 1 );
					}
					else
					{
						IupSetIntId( ih, "MARKERADD", line, 1 );
					}
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
		string		_title;
		Ihandle*	_documentTabs = GLOBAL.documentTabs;
		int 		pos = IupGetChildPos( GLOBAL.documentTabs, ih );
		
		if( pos < 0 )
		{
			pos = IupGetChildPos( GLOBAL.documentTabs_Sub, ih );
			_documentTabs = GLOBAL.documentTabs_Sub;
		}

		if( pos > -1 ) _title = fSTRz( IupGetAttributeId( _documentTabs, "TABTITLE", pos ) ); else return IUP_CONTINUE;
		
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
						IupSetStrAttributeId( _documentTabs, "TABTITLE", pos, toStringz( _title ) );
						cSci.title = _title;
						//if( fromStringz( IupGetAttribute( ih, "SAVEDSTATE" ) ) == "NO" ) IupSetAttribute( ih, "SAVEDSTATE", "YES" );
					}
					else
					{
						// First time trigger, don't change title
						//IupSetStrAttributeId( GLOBAL.documentTabs, "TABTITLE", pos, GLOBAL.cString.convert( _title ) );
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
					_title = _title[1..$].dup;
					auto cSci = ScintillaAction.getCScintilla( ih );
					if( cSci !is null )
					{
						IupSetStrAttributeId( _documentTabs, "TABTITLE", pos, toStringz( _title ) );
						cSci.title = _title;
						//if( fromStringz( IupGetAttribute( ih, "SAVEDSTATE" ) ) == "YES" ) IupSetAttribute( ih, "SAVEDSTATE", "NO" );
					}
					else
					{
						//IupSetStrAttributeId( GLOBAL.documentTabs, "TABTITLE", pos, GLOBAL.cString.convert( _title ) );
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
					version(Windows) ProjectAction.clearDarkModeNodesForeColor();
					IupSetAttribute( GLOBAL.projectTree.getTreeHandle, "MARK", "CLEARALL" ); // For projectTree MULTIPLE Selection
					ScintillaAction.toTreeMarked( cSci.getFullPath, 2 );
				}
			}
		}
		
		
		// Using IupFlatTabs at Linux, Double Click will trigget BUTTON_CB on IupScintilla, then BUTTON_CB on IupFlatTabs
		version(Posix)
		{
			if( pressed == 1 ) // in
			{
				if( button == IUP_BUTTON2 ) return IUP_IGNORE;
			}
		}
	
		string statusString = fSTRz( status );
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
						
						//version(linux)
						//{
							int margin0W = IupGetInt( ih, "MARGINWIDTH0" );
							int margin1W = IupGetInt( ih, "MARGINWIDTH1" );
							int margin2W = IupGetInt( ih, "MARGINWIDTH2" );
							int marginSubTotal = margin0W + margin1W + margin2W;
							
							if( x < marginSubTotal ) return IUP_DEFAULT;
						//}
						
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
						int margin0W = IupGetInt( ih, "MARGINWIDTH0" );
						int margin1W = IupGetInt( ih, "MARGINWIDTH1" );
						int margin2W = IupGetInt( ih, "MARGINWIDTH2" );
						int marginSubTotal = margin0W + margin1W + margin2W;
						
						if( x < marginSubTotal ) return IUP_DEFAULT;
						
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
									IupSetStrAttribute( ih, "SELECTIONPOS", toStringz( to!(string)( ++i ) ~ ":" ~ to!(string)( close ) ) );
									break;
								}
							}
						}
						return IUP_IGNORE;
					}					
				}
				else if( statusString[6] == 'A' )
				{
					version(Posix)
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
				version(Posix) return IUP_IGNORE;
			}
		}			

	
		if( pressed == 0 ) //release
		{
			if( GLOBAL.editorSetting00.MiddleScroll == "ON" )
			{
				if( fromStringz( IupGetAttribute( GLOBAL.scrollICONHandle, "VISIBLE" ) ) == "YES" )
				{
					IupHide( GLOBAL.scrollICONHandle );
					IupSetAttribute( GLOBAL.scrollTimer, "RUN", "NO" );
					return IUP_DEFAULT;
				}
			}
			
			if( button == IUP_BUTTON3 ) // Right Click
			{
				int Range0 = IupGetInt( ih, "MARGINWIDTH0" );
				int Range1 = IupGetInt( ih, "MARGINWIDTH1" );
				int Range2 = IupGetInt( ih, "MARGINWIDTH2" );
			
				if( GLOBAL.editorSetting00.BookmarkMargin == "ON" )
				{
					// Click at MARGINWIDTH1
					if( x > Range0 && x < Range0 + Range1 )
					{
						Ihandle* _expand = IupItem( GLOBAL.languageItems["bookmark"].toCString, null );
						IupSetAttribute( _expand, "IMAGE", "icon_mark" );
						IupSetCallback( _expand, "ACTION", cast(Icallback) function( Ihandle* __ih )
						{
							Ihandle* _ih = actionManager.ScintillaAction.getActiveIupScintilla();
							if( _ih != null )
							{
								int currentLine = ScintillaAction.getCurrentLine( _ih ) - 1;
								if( IupGetIntId( _ih, "MARKERGET", currentLine ) & 2 )
								{
									IupSetIntId( _ih, "MARKERDELETE", currentLine, 1 );
								}
								else
								{
									IupSetIntId( _ih, "MARKERADD", currentLine, 1 );
								}
							}
							return IUP_DEFAULT;
						});

						Ihandle* popupMenu;
						if( GLOBAL.debugPanel !is null )
						{
							Ihandle* _contract = IupItem( GLOBAL.languageItems["bp"].toCString, null );
							IupSetAttribute( _contract, "IMAGE", "IUP_variable_private" );
							if( !GLOBAL.debugPanel.isExecuting() ) IupSetAttribute( _contract, "ACTIVE", "NO" );
							IupSetCallback( _contract, "ACTION", cast(Icallback) function( Ihandle* __ih )
							{
								if( GLOBAL.debugPanel.isExecuting() )
								{
									Ihandle* _ih = actionManager.ScintillaAction.getActiveIupScintilla();
									if( _ih != null )
									{
										int line = ScintillaAction.getCurrentLine( _ih ) - 1;
										uint state = IupGetIntId( _ih, "MARKERGET", line );
										if( state & ( 1 << 2 ) )
										{
											IupScintillaSendMessage( _ih, 2044, line, 2 ); // #define SCI_MARKERDELETE 2044
											GLOBAL.debugPanel.removeBP( actionManager.ScintillaAction.getActiveCScintilla.getFullPath, to!(string)( ++line ) );
										}
										else
										{
											IupScintillaSendMessage( _ih, 2043, line, 2 ); // #define SCI_MARKERADD 2043
											GLOBAL.debugPanel.addBP( actionManager.ScintillaAction.getActiveCScintilla.getFullPath, to!(string)( ++line ) );
										}
									}
								}
								return IUP_DEFAULT;
							});
							
							popupMenu = IupMenu(
													_expand,
													_contract,
													null
												);
						}
						else
						{
							popupMenu = IupMenu(
													_expand,
													null
												);
						}

						IupPopup( popupMenu, IUP_MOUSEPOS, IUP_MOUSEPOS );
						IupDestroy( popupMenu );					
					
						return IUP_DEFAULT;
					}
				}
				
					
				if( GLOBAL.editorSetting00.FoldMargin == "ON" )
				{
					// Click at MARGINWIDTH2
					if( x > Range0 + Range1 && x < Range0 + Range1 + Range2 )
					{
						Ihandle* _expand = IupItem( GLOBAL.languageItems["expandall"].toCString, null );
						IupSetAttribute( _expand, "IMAGE", "icon_collapse1" );
						IupSetCallback( _expand, "ACTION", cast(Icallback) function( Ihandle* __ih )
						{
							Ihandle* _sci = actionManager.ScintillaAction.getActiveIupScintilla();
							if( _sci != null ) IupSetAttribute( _sci, "FOLDALL", "EXPAND" );
							return IUP_DEFAULT;
						});

						Ihandle* _contract = IupItem( GLOBAL.languageItems["contractall"].toCString, null );
						IupSetAttribute( _contract, "IMAGE", "icon_collapse" );
						IupSetCallback( _contract, "ACTION", cast(Icallback) function( Ihandle* __ih )
						{
							Ihandle* _sci = actionManager.ScintillaAction.getActiveIupScintilla();
							if( _sci != null ) IupSetAttribute( _sci, "FOLDALL", "CONTRACT" );
							return IUP_DEFAULT;
						});
						
						Ihandle* popupMenu = IupMenu(
														_expand,
														_contract,
														null
													);

						IupPopup( popupMenu, IUP_MOUSEPOS, IUP_MOUSEPOS );
						IupDestroy( popupMenu );					
					
						return IUP_DEFAULT;
					}
				}
			
			
				if( x > Range0 + Range1 + Range2 )
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
						
						Ihandle* __undo = IupGetDialogChild( GLOBAL.toolbar.getHandle, "POSEIDON_TOOLBAR_Undo" );
						if( __undo != null ) IupSetAttribute( __undo, "ACTIVE", "NO" ); // SCI_CANUNDO 2174

						Ihandle* __redo = IupGetDialogChild( GLOBAL.toolbar.getHandle, "POSEIDON_TOOLBAR_Redo" );
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
					
					
					
					// Set KeyWord4/5
					Ihandle* _setKeyWord4 = IupItem( GLOBAL.languageItems["keyword4"].toCString, null );
					IupSetCallback( _setKeyWord4, "ACTION", cast(Icallback) function( Ihandle* ih )
					{
						Ihandle* iupSci = actionManager.ScintillaAction.getActiveIupScintilla();
						if( iupSci != null )
						{
							string targetText = Uni.toLower( fSTRz( IupGetAttribute( iupSci, "SELECTEDTEXT" ) ) );
							if( targetText.length )
							{
								foreach( s; Array.split( GLOBAL.parserSettings.KEYWORDS[4], " " ) )
								{
									if( s == targetText ) return IUP_DEFAULT;
								}
								
								string k4 = strip( GLOBAL.parserSettings.KEYWORDS[4] );
								if( k4.length ) k4 = k4 ~ " " ~ targetText; else k4 = targetText;
								GLOBAL.parserSettings.KEYWORDS[4] = k4;
								IupSetStrAttribute( IupGetHandle( "keyWordText4" ), "VALUE", toStringz( GLOBAL.parserSettings.KEYWORDS[4] ) );
	
								foreach( CScintilla cSci; GLOBAL.scintillaManager )
									if( cSci !is null ) cSci.setGlobalSetting();
							}
						}
						
						return IUP_DEFAULT;
					});
					
					Ihandle* _setKeyWord5 = IupItem( GLOBAL.languageItems["keyword5"].toCString, null );
					IupSetCallback( _setKeyWord5, "ACTION", cast(Icallback) function( Ihandle* ih )
					{
						Ihandle* iupSci = actionManager.ScintillaAction.getActiveIupScintilla();
						if( iupSci != null )
						{
							string targetText = Uni.toLower( fSTRz( IupGetAttribute( iupSci, "SELECTEDTEXT" ) ) );
							if( targetText.length )
							{
								foreach( s; Array.split( GLOBAL.parserSettings.KEYWORDS[5], " " ) )
								{
									if( s == targetText ) return IUP_DEFAULT;
								}
								
								string k5 = strip( GLOBAL.parserSettings.KEYWORDS[5] );
								if( k5.length ) k5 = k5 ~ " " ~ targetText; else k5 = targetText;
								GLOBAL.parserSettings.KEYWORDS[5] = k5;
								IupSetStrAttribute( IupGetHandle( "keyWordText5" ), "VALUE", toStringz( GLOBAL.parserSettings.KEYWORDS[5] ) );
								
								foreach( CScintilla cSci; GLOBAL.scintillaManager )
									if( cSci !is null ) cSci.setGlobalSetting();
							}
						}
						
						return IUP_DEFAULT;
					});					
					
					
					Ihandle* _setKeyWordMenu = IupMenu( _setKeyWord4, _setKeyWord5, null  );
					Ihandle* _SetKeyWordSubMenu = IupSubmenu( GLOBAL.languageItems["setkeyword"].toCString,_setKeyWordMenu  );
					IupSetAttribute( _SetKeyWordSubMenu, "IMAGE", "icon_wholeword" );
					string targetText = Uni.toLower( fSTRz( IupGetAttribute( ih, "SELECTEDTEXT" ) ) );
					if( !targetText.length )
						IupSetAttribute( _SetKeyWordSubMenu, "ACTIVE", "NO" );
					else
					{
						if( indexOf( targetText, " " ) > -1 || indexOf( targetText, "\t" ) > -1 || indexOf( targetText, "\n" ) > -1 ) IupSetAttribute( _SetKeyWordSubMenu, "ACTIVE", "NO" );
					}
					

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
					version(FBIDE)	IupSetAttribute( _goto, "IMAGE", "icon_goto" );
					version(DIDE)	IupSetAttribute( _goto, "IMAGE", "icon_uparrow" );
					IupSetCallback( _goto, "ACTION", cast(Icallback) function( Ihandle* ih )
					{
						AutoComplete.toDefintionAndType( 1 );
						return IUP_DEFAULT;
					});
					
					Ihandle* _gotoProcedure = IupItem( GLOBAL.languageItems["sc_procedure"].toCString, null );
					version(FBIDE)	IupSetAttribute( _gotoProcedure, "IMAGE", "icon_gotomember" );
					version(DIDE)	IupSetAttribute( _gotoProcedure, "IMAGE", "icon_goto" );
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
					
					Ihandle* popupMenu;
					
					if( GLOBAL.debugPanel !is null )
					{
						if( GLOBAL.debugPanel.isRunning )
						{
							Ihandle* itemDebugList = IupItem( toStringz( GLOBAL.languageItems["add"].toDString ~ " " ~ GLOBAL.languageItems["watchlist"].toDString ), null );
							IupSetAttribute( itemDebugList, "IMAGE", "icon_debug_add" );
							IupSetCallback( itemDebugList, "ACTION", cast(Icallback) function( Ihandle* ih ){
							
								CScintilla cSci = actionManager.ScintillaAction.getActiveCScintilla();
								if( cSci !is null )
								{
									string varName = strip( fSTRz( IupGetAttribute( cSci.getIupScintilla, "SELECTEDTEXT" ) ) );
									//if( varName.length ) GLOBAL.debugPanel.sendCommand( "display " ~ upperCase( varName ) ~ "\n", false );

									scope varDlg = new CVarDlg( 260, -1, "Add Display Variable...", "Var Name:", null, varName );
									varName = varDlg.show( IUP_MOUSEPOS, IUP_MOUSEPOS );

									if( varName == "#_close_#" ) return IUP_DEFAULT;

									GLOBAL.debugPanel.sendCommand( "display " ~ Uni.toUpper( strip( varName ) ) ~ "\n", false );
									return IUP_IGNORE;
								}
								return IUP_DEFAULT;
							});
							
							Ihandle* itemBP = IupItem( GLOBAL.languageItems["bp"].toCString, null );
							IupSetAttribute( itemBP, "IMAGE", "IUP_variable_private" );
							IupSetCallback( itemBP, "ACTION", cast(Icallback) function( Ihandle* __ih )
							{
								Ihandle* _ih = actionManager.ScintillaAction.getActiveIupScintilla();
								if( _ih != null )
								{
									int line = ScintillaAction.getCurrentLine( _ih ) - 1;
									uint state = IupGetIntId( _ih, "MARKERGET", line );
									if( state & ( 1 << 2 ) )
									{
										IupScintillaSendMessage( _ih, 2044, line, 2 ); // #define SCI_MARKERDELETE 2044
										GLOBAL.debugPanel.removeBP( actionManager.ScintillaAction.getActiveCScintilla.getFullPath, to!(string)( ++line ) );
									}
									else
									{
										IupScintillaSendMessage( _ih, 2043, line, 2 ); // #define SCI_MARKERADD 2043
										GLOBAL.debugPanel.addBP( actionManager.ScintillaAction.getActiveCScintilla.getFullPath, to!(string)( ++line ) );
									}
								}
								return IUP_DEFAULT;
							});						
						
							popupMenu = IupMenu(
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
													
													_SetKeyWordSubMenu,
													
													IupSeparator(),
													
													_AnnotationSubMenu,
													
													IupSeparator(),
													
													_refresh,
													_goto,
													_gotoProcedure,
													_showType,
													IupSeparator(),
													
													itemDebugList,
													itemBP,
													
													null
												);					
						}
						else
						{
							popupMenu = IupMenu(
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
													
													_SetKeyWordSubMenu,
													
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
						}
					}
					else
					{
						popupMenu = IupMenu(
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
												
												_SetKeyWordSubMenu,
												
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
					}


					IupPopup( popupMenu, IUP_MOUSEPOS, IUP_MOUSEPOS );
					IupDestroy( popupMenu );
				}
				
				version(Posix) return IUP_IGNORE; // For Linux MOD
			}
			else if( button == IUP_BUTTON2 ) // Middle Click
			{
				if( GLOBAL.editorSetting00.MiddleScroll == "ON" )
				{
					if( fromStringz( IupGetAttribute( GLOBAL.scrollICONHandle, "VISIBLE" ) ) == "NO" )
					{
						int _x, _y;
						string mousePos = fSTRz( IupGetGlobal( "CURSORPOS" ) );
					
						auto crossSign = indexOf( mousePos, "x" );
						if( crossSign > 0 )
						{
							_x = to!(int)( mousePos[0..crossSign] );
							_y = to!(int)( mousePos[crossSign+1..$] );
							_x -= 16;
							_y -= 16;
							if( _x < 0 ) _x = 0;
							if( _y < 0 ) _y = 0;
							
							IupShowXY( GLOBAL.scrollICONHandle, _x, _y );
							IupSetAttribute( GLOBAL.scrollTimer, "RUN", "YES" );

							IupSetFocus( ih );							
						}
						version(Posix) return IUP_IGNORE; else return IUP_DEFAULT;
					}
				}
	
				if( GLOBAL.editorSetting00.MultiSelection == "ON" )
				{
					int pos = IupConvertXYToPos( ih, x, y );
					IupScintillaSendMessage( ih, 2025, pos , 0 );// SCI_GOTOPOS = 2025,
					
					IupSetFocus( ih );
					string _char = strip( fSTRz( IupGetAttributeId( ih, "CHAR", pos ) ) );
					
					if( _char.length )
					{
						IupSetAttribute( ih, "SELECTIONPOS", "NONE" );
						
						string word = AutoComplete.getWholeWordDoubleSide( ih, pos );
						word = Algorithm.reverse( word.dup );
						
						string[] splitWord = Array.split( word, "." );
						if( splitWord.length > 1 ) word = splitWord[$-1];
						
						splitWord = Array.split( word, "->" );
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
							scope _t = new IupString( word );
							int findPos = cast(int) IupScintillaSendMessage( ih, 2197, cast(size_t) word.length, cast(ptrdiff_t) _t.toCString ); //SCI_SEARCHINTARGET = 2197,
							
							while( findPos > -1 )
							{
								if( count++ == 0 ) 
									IupScintillaSendMessage( ih, 2572, cast(int) findPos, cast(int) ( findPos + word.length ) ); // SCI_SETSELECTION 2572
								else
									IupScintillaSendMessage( ih, 2573, cast(int) findPos, cast(int) ( findPos + word.length ) ); // SCI_ADDSELECTION 2573

								IupSetInt( ih, "TARGETSTART", findPos + cast(int) word.length );
								IupSetInt( ih, "TARGETEND", -1 );
								findPos = cast(int) IupScintillaSendMessage( ih, 2197, cast(size_t) word.length, cast(ptrdiff_t) _t.toCString ); //SCI_SEARCHINTARGET = 2197,
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
		if( GLOBAL.parserSettings.toggleEnableDwell == "ON" )
		{
			if( state == 1 )
			{
				if( pos != -1 )
				{
					if( cast(int) IupScintillaSendMessage( ih, 2202, 0, 0 ) == 0 )
					{
						if( GLOBAL.debugPanel !is null )
						{
							if( GLOBAL.debugPanel.isRunning && GLOBAL.debugPanel.isExecuting )
							{
								if( !GLOBAL.debugPanel.is64Bit )
								{
									version(Windows)
									{
										version(FBIDE) AutoComplete.toDefintionAndType( -1, pos );
										return IUP_DEFAULT;
									}
								}
							}

							version(FBIDE) AutoComplete.toDefintionAndType( 0, pos ); else AutoComplete.toDefintionAndType( 0 );
						}
						else
						{
							AutoComplete.toDefintionAndType( 0 );
						}
					}
					else
					{
						//IupScintillaSendMessage( ih, 2201, 0, 0 ); // SCI_CALLTIPCANCEL  2201
					}
				}
				else
				{
					if( cast(int) IupScintillaSendMessage( ih, 2202, 0, 0 ) == 1 ) IupScintillaSendMessage( ih, 2201, 0, 0 ); // SCI_CALLTIPCANCEL  2201
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
				string cursorString = fSTRz( IupGetGlobal( "CURSORPOS" ) );
				
				int	cursorX, cursorY, iconX, iconY;
				if( tools.splitBySign( cursorString, "x", cursorX, cursorY ) )
				{
					string iconString = fSTRz( IupGetAttribute( GLOBAL.scrollICONHandle, "SCREENPOSITION" ) );
					if( tools.splitBySign( iconString, ",", iconX, iconY ) )
					{
						if( cursorY > iconY + 16 )
						{
							int add = ( cursorY - iconY - 16 ) / 50 + 1;
							IupScintillaSendMessage( ih, 2168, 0, add ); // SCI_LINESCROLL 2168
							
						}
						else if( cursorY < iconY + 16 )
						{
							int minus = ( cursorY - iconY - 16 ) / 50 - 1;
							IupScintillaSendMessage( ih, 2168, 0, minus ); // SCI_LINESCROLL 2168
						}
						
						if( cursorX > iconX + 16 )
						{
							int add = ( cursorX - iconX - 16 ) / 20 + 1;
							IupScintillaSendMessage( ih, 2168, add, 0 ); // SCI_LINESCROLL 2168
							
						}
						else if( cursorX < iconX + 16 )
						{
							int minus = ( cursorX - iconX - 16 ) / 40 - 1;
							IupScintillaSendMessage( ih, 2168, minus, 0 ); // SCI_LINESCROLL 2168
						}
					}
				}
			}
		}

		return IUP_DEFAULT;
	}
	

	private int CScintilla_keyany_cb( Ihandle *ih, int c ) 
	{
		try
		{
			AutoComplete.bAutocompletionPressEnter = false;
			AutoComplete.bSkipAutoComplete = false;
			if( c == 13 ) AutoComplete.bEnter = true; else AutoComplete.bEnter = false;

			if( c == 65307 ) // ESC
			{
				if( fromStringz( IupGetAttribute( ih, "AUTOCACTIVE" ) ) == "YES" ) IupSetAttribute( ih, "AUTOCCANCEL", "YES" );
				if( cast(int) IupScintillaSendMessage( ih, 2202, 0, 0 ) == 1 ) IupScintillaSendMessage( ih, 2201, 0, 0 ); // SCI_CALLTIPCANCEL  2201
			}
			else if( c == 65379 ) // INS
			{
				if( cast(int) IupScintillaSendMessage( ih, 2187, 0, 0 ) ) GLOBAL.statusBar.setIns( "INS" ); else GLOBAL.statusBar.setIns( "OVR" );
			}
			
			if( GLOBAL.editorSetting00.AutoClose == "ON" )
			{
				switch( c )
				{
					case 34: // "
						IupSetStrAttributeId( ih, "INSERT", -1, toStringz( "\"" ) ); break;
					case 40: // (
						IupSetStrAttributeId( ih, "INSERT", -1, toStringz( ")" ) ); break;
					case 91: // [
						IupSetStrAttributeId( ih, "INSERT", -1, toStringz( "]" ) ); break;
					case 123: // {
						IupSetStrAttributeId( ih, "INSERT", -1, toStringz( "}" ) ); break;

					case 8:		// BS
					case 65535:	// DEL
						int		pos, currentPos = actionManager.ScintillaAction.getCurrentPos( ih );
						string	eraseWord;
						
						if( c == 8 )
						{
							eraseWord = ScintillaAction.getCurrentChar( -1, ih );
							pos = currentPos - 1;
						}
						else
						{
							eraseWord = ScintillaAction.getCurrentChar( 0, ih );
							pos = currentPos;
							currentPos ++;
						}
						
						switch( eraseWord )
						{
							case "(":
								if( fromStringz( IupGetAttributeId( ih, "CHAR", currentPos ) ) == ")" )
								{
									IupSetStrAttribute( ih, "DELETERANGE", toStringz( to!(string)( pos ) ~ ",2" ) );
									//IupScintillaSendMessage( ih, 2160, pos, pos + 2 ); // SCI_SETSEL = 2160
									//IupSetAttribute( ih, "SELECTEDTEXT", "" );
									return IUP_IGNORE;
								}
								break;
								
							case "[":
								if( fromStringz( IupGetAttributeId( ih, "CHAR", currentPos ) ) == "]" )
								{
									IupSetStrAttribute( ih, "DELETERANGE", toStringz( to!(string)( pos ) ~ ",2" ) );
									return IUP_IGNORE;
								}
								break;
								
							case "{":
								if( fromStringz( IupGetAttributeId( ih, "CHAR", currentPos ) ) == "}" )
								{
									IupSetStrAttribute( ih, "DELETERANGE", toStringz( to!(string)( pos ) ~ ",2" ) );
									return IUP_IGNORE;
								}
								break;
								
							case "\"":
								if( fromStringz( IupGetAttributeId( ih, "CHAR", currentPos ) ) == "\"" )
								{
									IupSetStrAttribute( ih, "DELETERANGE", toStringz( to!(string)( pos ) ~ ",2" ) );
									return IUP_IGNORE;
								}
								break;
								
							default:
						}
						break;
						
					default:
				}
			}
			
			version(FBIDE)
			{
				// Nested Function
				void _convertCase()
				{
					int currentPos = actionManager.ScintillaAction.getCurrentPos( ih );
					if( !ScintillaAction.isComment( ih, currentPos ))
					{
						if( cast(int)IupScintillaSendMessage( ih, 2381, 0, 0 ) > 0 ) // SCI_GETFOCUS 2381
						{
							//IupMessage("",toStringz( Integer.toString( c ) ) );
							if( c == 32 || c == 9 || c == 13 || ( c >= 40 && c <= 43 ) || c == 45 || c == 47 )
							{
								int		pos, headPos;
								
								if( c != 13 )
								{
									pos = currentPos;// - 1;
								}
								else
								{
									pos = cast(int) IupScintillaSendMessage( ih, 2136, ScintillaAction.getCurrentLine( ih ) - 1/*2*/, 0 ); // SCI_GETLINEENDPOSITION 2136
								}
								
								string	word = AutoComplete.getKeyWordReverse( ih, pos, headPos );
								if( word.length )
								{
									word = Uni.toLower( Algorithm.reverse( word.dup ) );

									bool bExitFlag;
									foreach( keyword; GLOBAL.parserSettings.KEYWORDS )
									{
										foreach( k; Array.split( keyword, " " ) )
										{	
											if( k.length )
											{
												if( Uni.toLower( k ) == word )
												{
													IupSetStrAttribute( ih, "SELECTIONPOS", toStringz( to!(string)( headPos ) ~ ":" ~ to!(string)( headPos + word.length ) ) );
													word = tools.convertKeyWordCase( GLOBAL.keywordCase, k );
													IupSetStrAttribute( ih, "SELECTEDTEXT", toStringz( word ) );
													IupScintillaSendMessage( ih, 2025, currentPos, 0 ); // sci_gotopos = 2025,
													bExitFlag = true;
													break;
												}
											}
										}
										if( bExitFlag ) break;
									}
								}
							}
						}
					}
				}				
				
				if( GLOBAL.keywordCase > 0 )
				{
					// Auto convert keyword case......
					if( fromStringz( IupGetAttribute( ih, "AUTOCACTIVE" ) ) == "NO" )
					{
						if( GLOBAL.editorSetting00.QBCase == "ON" )
						{
							if( c == 13 )
							{
								int lineNum = actionManager.ScintillaAction.getCurrentLine( ih ) - 1;
								int	lineHead = cast(int) IupScintillaSendMessage( ih, 2167, lineNum, 0 );
								int lineTail = ScintillaAction.getCurrentPos( ih );
								bool bGetMatch;
								
								//IupMessage( "", toStringz( Integer.toString(lineHead)~","~Integer.toString(lineTail) ) );
								
								if( lineTail > lineHead )
								{
									IupScintillaSendMessage( ih, 2198, 2, 0 );		// SCFIND_WHOLEWORD = 2,				// SCI_SETSEARCHFLAGS = 2198
									foreach( _s; GLOBAL.parserSettings.KEYWORDS )
									{
										foreach( targetText; Array.split( _s, " " ) )
										{
											if( targetText.length )
											{
												string replaceText = tools.convertKeyWordCase( GLOBAL.keywordCase, targetText );

												IupSetInt( ih, "TARGETSTART", lineTail );
												IupSetInt( ih, "TARGETEND", lineHead );
												
												scope _t = new IupString( targetText );
												int posHead = cast(int) IupScintillaSendMessage( ih, 2197, cast(size_t) targetText.length, cast(ptrdiff_t) _t.toCString );
												
												while( posHead >= 0 )
												{
													IupSetStrAttribute( ih, "REPLACETARGET", toStringz( replaceText ) );
													bGetMatch = true;
													IupSetInt( ih, "TARGETSTART", posHead );
													IupSetInt( ih, "TARGETEND", lineHead );
													posHead = cast(int) IupScintillaSendMessage( ih, 2197, cast(size_t) targetText.length, cast(ptrdiff_t) _t.toCString );
												}					
											}
										}
									}
									
									if( bGetMatch ) IupScintillaSendMessage( ih, 2025, lineTail, 0 );
								}
							}
						}
						else
						{
							_convertCase();
						}
					}
					else if( c != 13 && c != 9 )
					{
						if( GLOBAL.editorSetting00.QBCase == "OFF" ) _convertCase();
					}
				}
			}			

			foreach( ShortKey sk; GLOBAL.shortKeys )
			{
				switch( sk.name )
				{
					case "dupdown":
						if( sk.keyValue > 0 )
						{
							if( sk.keyValue == c )
							{
								//menu.cut_cb();
								auto iupSci = ScintillaAction.getActiveIupScintilla();
								if( iupSci != null )
								{
									int line = ScintillaAction.getCurrentLine( iupSci ) - 1;
									IupScintillaSendMessage( iupSci, 2404, line, 0 ); // SCI_LINEDUPLICATE 2404
								}								
								return IUP_IGNORE;
							}
						}
						break;
					case "dupup":
						if( sk.keyValue > 0 )
						{
							if( sk.keyValue == c )
							{
								//menu.copy_cb();
								auto iupSci = ScintillaAction.getActiveIupScintilla();
								if( iupSci != null )
								{
									char[] lineText = fromStringz( IupGetAttribute( iupSci, "LINEVALUE" ) );
									int line = ScintillaAction.getCurrentLine( iupSci ) - 1;
									IupScintillaSendMessage( iupSci, 2404, line, 0 ); // SCI_LINEDUPLICATE 2404
									IupScintillaSendMessage( iupSci, 2025, ScintillaAction.getCurrentPos( iupSci ) + cast(ptrdiff_t) lineText.length, 0 ); // SCI_GOTOPOS 2025
								}								
								return IUP_IGNORE;
							}
						}
						break;
					case "find":				
						if( sk.keyValue == c )
						{
							menu.findReplace_cb( ih );
							return IUP_IGNORE;
						}
						break;
					case "findinfile":
						if( sk.keyValue == c )
						{ 
							menu.findReplaceInFiles( ih );
							return IUP_IGNORE;
						}
						break;
					case "findnext":
						if( sk.keyValue == c )
						{
							menu.findNext_cb( ih );
							return IUP_IGNORE;
						}
						break;
					case "findprev":
						if( sk.keyValue == c )
						{
							menu.findPrev_cb( ih );
							return IUP_IGNORE;
						}
						break;
					case "gotoline":
						if( sk.keyValue == c )
						{
							menu.item_goto_cb( ih );
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
					case "outlinesearch":
						if( sk.keyValue == c )
						{
							Ihandle* _expandHandle = IupGetDialogChild( GLOBAL.outlineTree.getLayoutHandle, "Outline_Expander" );
							if( _expandHandle != null )
							{
								Ihandle* _listHandle = IupGetChild( _expandHandle, 1 );
								if( _listHandle != null )
								{
									if( fromStringz( IupGetAttribute( _expandHandle, "STATE" ) ) == "CLOSE" )
									{
										IupSetAttribute( _expandHandle, "STATE", "OPEN" );
										IupSetAttributes( _listHandle, "VISIBLE=YES,ACTIVE=YES" ); // Make outlineTreeNodeList to show
									}
									
									if( IupGetInt( GLOBAL.menuOutlineWindow, "VALUE" ) == 0 ) menu.outlineMenuItem_cb( GLOBAL.menuOutlineWindow );
									IupSetInt( GLOBAL.projectViewTabs, "VALUEPOS", 1 );
									IupSetFocus( _listHandle );
								}
							}
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
					case "leftwindow":
						if( sk.keyValue == c ) 
						{
							if( fromStringz( IupGetAttribute( GLOBAL.menuOutlineWindow, "VALUE" ) ) == "OFF" )
							{
								IupSetAttribute( GLOBAL.menuOutlineWindow, "VALUE", "ON" );
								IupSetInt( GLOBAL.explorerSplit, "BARSIZE", to!(int)( GLOBAL.editorSetting01.BarSize ) );
								IupSetInt( GLOBAL.explorerSplit, "VALUE", GLOBAL.explorerSplit_value );
								IupSetInt( GLOBAL.explorerSplit, "ACTIVE", 1 );
							}
							if( IupGetInt( GLOBAL.projectViewTabs, "VALUEPOS" ) == 0 ) IupSetInt( GLOBAL.projectViewTabs, "VALUEPOS", 1 ); else IupSetInt( GLOBAL.projectViewTabs, "VALUEPOS", 0 );
							IupSetFocus( ih );
							return IUP_IGNORE;
						}
						break;
					case "bottomwindow":
						if( sk.keyValue == c ) 
						{
							if( fromStringz( IupGetAttribute( GLOBAL.menuMessageWindow, "VALUE" ) ) == "OFF" )
							{
								IupSetAttribute( GLOBAL.menuMessageWindow, "VALUE", "ON" );
								IupSetInt( GLOBAL.messageSplit, "BARSIZE", to!(int)( GLOBAL.editorSetting01.BarSize ) );
								IupSetInt( GLOBAL.messageSplit, "VALUE", GLOBAL.messageSplit_value );
								IupSetInt( GLOBAL.messageSplit, "ACTIVE", 1 );
							}
							if( IupGetInt( GLOBAL.messageWindowTabs, "VALUEPOS" ) == 0 ) IupSetInt( GLOBAL.messageWindowTabs, "VALUEPOS", 1 ); else IupSetInt( GLOBAL.messageWindowTabs, "VALUEPOS", 0 );
							IupSetFocus( ih );
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
							return IUP_IGNORE;
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
							string 	alreadyInput;
							string	lastChar;
							int		pos = actionManager.ScintillaAction.getCurrentPos( ih );
							int		dummyHeadPos;

							if( pos > 0 ) lastChar = fSTRz( IupGetAttributeId( ih, "CHAR", pos - 1 ) ); else return IUP_IGNORE;
							
							version(FBIDE)
							{
								if( GLOBAL.compilerSettings.enableIncludeComplete == "ON" )
								{
									if( AutoComplete.checkIscludeDeclare( ih, pos - 1 ) )
									{
										alreadyInput = lastChar.dup;
										string list = AutoComplete.includeComplete( ih, pos - 1, alreadyInput );
										if( list.length )
										{
											//IupScintillaSendMessage( ih, 2660, 1, 0 ); //SCI_AUTOCSETORDER 2660
											scope _result = new IupString( list );
											if( !alreadyInput.length ) IupScintillaSendMessage( ih, 2100, cast(size_t) alreadyInput.length, cast(ptrdiff_t) _result.toCString ); else IupSetStrAttributeId( ih, "AUTOCSHOW", cast(int) alreadyInput.length, _result.toCString );
											return IUP_IGNORE;
										}
									}
								}	

								if( pos > 1 )
								{
									if( lastChar == ">" )
									{
										if( fromStringz( IupGetAttributeId( ih, "CHAR", pos - 2 ) ) == "-" )
										{
											alreadyInput = Algorithm.reverse( AutoComplete.getWholeWordReverse( ih, pos - 2, dummyHeadPos ).dup );
											alreadyInput ~= "->";
										}
									}
								}

								if( lastChar == "(" ) alreadyInput = Algorithm.reverse( AutoComplete.getWholeWordReverse( ih, pos - 1, dummyHeadPos ).dup ); else alreadyInput = Algorithm.reverse( AutoComplete.getWholeWordReverse( ih, pos, dummyHeadPos ).dup );
							
								try
								{
									if( GLOBAL.parserSettings.enableParser != "ON" )
									{
										// Check Keyword Autocomplete
										if( GLOBAL.compilerSettings.enableKeywordComplete == "ON" )
										{
											if( alreadyInput.length )
											{
												if( fromStringz( IupGetAttribute( ih, "AUTOCACTIVE" ) ) != "YES" )
												{
													scope _result = new IupString( AutoComplete.getKeywordContainerList( alreadyInput ) );
													if( _result.toDString.length ) IupScintillaSendMessage( ih, 2100, cast(size_t) alreadyInput.length, cast(ptrdiff_t) _result.toCString );
												}
											}
										}
										
										return IUP_IGNORE;
									}
									
									if( alreadyInput.length )
									{
										if( lastChar == "(" )
										{
											AutoComplete.updateCallTip( ih, pos, alreadyInput );
										}
										else
										{
											if( GLOBAL.parserSettings.toggleCompleteAtBackThread == "ON" ) AutoComplete.callAutocomplete( ih, pos - 1, lastChar, alreadyInput ~ " ", false ); else AutoComplete.callAutocomplete( ih, pos - 1, lastChar, alreadyInput ~ " ", true );
										}
									}
								}
								catch( Exception e )
								{
									debug IupMessage( "ShortCut Error", toStringz( "autocomplete\n" ~ e.toString ) );
								}
							}
							version(DIDE)
							{
								if( GLOBAL.compilerSettings.enableIncludeComplete == "ON" )
								{
									if( AutoComplete.checkIsclmportDeclare( ih, pos - 1 ) )
									{
										alreadyInput = lastChar.dup;
										string list = AutoComplete.includeComplete( ih, pos - 1, alreadyInput );
										if( list.length )
										{
											//IupScintillaSendMessage( ih, 2660, 1, 0 ); //SCI_AUTOCSETORDER 2660
											scope _result = new IupString( list );
											if( !alreadyInput.length ) IupScintillaSendMessage( ih, 2100, cast(size_t) alreadyInput.length, cast(ptrdiff_t) _result.toCString ); else IupSetStrAttributeId( ih, "AUTOCSHOW", cast(int) alreadyInput.length, _result.toCString );
											return IUP_IGNORE;
										}
									}
								}								
							
								if( pos > 1 )
								{
									if( lastChar == ">" )
									{
										if( fSTRz( IupGetAttributeId( ih, "CHAR", pos - 2 ) ) == "-" ) alreadyInput = ( Algorithm.reverse( AutoComplete.getWholeWordReverse( ih, pos - 2, dummyHeadPos ).dup ) ~ "->" ).dup;
									}
								}

								if( lastChar == "(" ) alreadyInput = Algorithm.reverse( AutoComplete.getWholeWordReverse( ih, pos - 1, dummyHeadPos ).dup ); else alreadyInput = Algorithm.reverse( AutoComplete.getWholeWordReverse( ih, pos, dummyHeadPos ).dup );
							
								try
								{
									if( GLOBAL.parserSettings.enableParser != "ON" )
									{
										// Check Keyword Autocomplete
										if( GLOBAL.compilerSettings.enableKeywordComplete == "ON" )
										{
											if( alreadyInput.length )
											{
												if( fromStringz( IupGetAttribute( ih, "AUTOCACTIVE" ) ) != "YES" )
												{
													string list = AutoComplete.getKeywordContainerList( alreadyInput );
													scope _result = new IupString( list );
													if( list.length ) IupScintillaSendMessage( ih, 2100, cast(size_t) alreadyInput.length, cast(ptrdiff_t) _result.toCString );
												}
											}
										}
										
										return IUP_IGNORE;
									}								
								
								
									if( alreadyInput.length )
									{
										if( lastChar == "(" )
										{
											AutoComplete.updateCallTip( ih, pos, alreadyInput );
										}
										else
										{
											if( GLOBAL.parserSettings.toggleCompleteAtBackThread == "ON" ) AutoComplete.callAutocomplete( ih, pos - 1, lastChar, alreadyInput ~ " ", false ); else AutoComplete.callAutocomplete( ih, pos - 1, lastChar, alreadyInput ~ " ", true );
										}									
									}
								}
								catch( Exception e )
								{
									debug IupMessage( "ShortCut Error", toStringz( "autocomplete\n" ~ e.toString ) );
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
							menu.comment_cb( null );
							return IUP_IGNORE;
						}
						break;
						
					case "uncomment":
						if( sk.keyValue == c )
						{
							menu.uncomment_cb( null );
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
					case "customtool1", "customtool2", "customtool3", "customtool4", "customtool5", "customtool6", "customtool7", "customtool8", "customtool9", "customtool10", "customtool11", "customtool12":
						if( sk.keyValue == c )
						{
							string	tailChar = sk.name[10..$];
							int		tailNum = to!(int)( tailChar );
							if( tailNum > 0 && tailNum < 13 )
							{
								if( GLOBAL.customTools[tailNum].name.length )
								{
									if( GLOBAL.customTools[tailNum].dir.length )
									{
										CustomToolAction.run( GLOBAL.customTools[tailNum] );
									}
								}
							}

							return IUP_IGNORE;
						}
						break;					

					default:
				}
			}
			
			// For CallTip
			if( cast(int) IupScintillaSendMessage( ih, 2202, 0, 0 ) == 1 )
			{
				int pos;
				if( c == 65361 ) // LEFT
				{
					pos = ScintillaAction.getCurrentPos( ih ) - 2;
					if( pos > -1 )
					{
						char[] s = fromStringz( IupGetAttributeId( ih, "CHAR", pos ) );
						if( s == "\n" || s == "\r" )
						{
							if( cast(int) IupScintillaSendMessage( ih, 2202, 0, 0 ) == 1 ) IupScintillaSendMessage( ih, 2201, 0, 0 ); //  SCI_CALLTIPCANCEL 2201 , SCI_CALLTIPACTIVE 2202
							AutoComplete.noneListProcedureName = "";
						}
						else
							AutoComplete.updateCallTipByDirectKey( ih, pos );
					}
				}
				else if( c == 65363 ) // RIGHT
				{
					pos = ScintillaAction.getCurrentPos( ih );// + 1;
					if( pos < IupGetInt( ih, "COUNT" ) )
					{
						char[] s = fromStringz( IupGetAttributeId( ih, "CHAR", pos ) );
						if( s == "\n" || s == "\r" )
						{
							if( cast(int) IupScintillaSendMessage( ih, 2202, 0, 0 ) == 1 ) IupScintillaSendMessage( ih, 2201, 0, 0 ); //  SCI_CALLTIPCANCEL 2201 , SCI_CALLTIPACTIVE 2202
							AutoComplete.noneListProcedureName = "";
						}
						else
							AutoComplete.updateCallTipByDirectKey( ih, pos );
					}
				}
				else if( c == 13 || c == 65362 || c == 65364 ) // Enter / UP / DOWN
				{
					AutoComplete.cleanCalltipContainer();
					AutoComplete.noneListProcedureName = "";
				}
				else if( c == 8 ) // BS
				{
					// For Reduce The CallTip window close automatically
					pos = ScintillaAction.getCurrentPos( ih );
					IupScintillaSendMessage( ih, 2160, pos, pos-1 ); // SCI_SETSEL = 2160
					IupSetAttribute( ih , "SELECTEDTEXT", "" );
					AutoComplete.noneListProcedureName = "";
					
					return IUP_IGNORE;
				}
				else if( c == 536936291 || c == 536870979 ) // Ctrl + Ins / Ctrl + C
				{
					string showtype = AutoComplete.getShowTypeContent();
					if( showtype.length )
					{
						int lineNumber = ScintillaAction.getCurrentLine( ih ) - 2;
						if( lineNumber > -1 )
						{
							IupScintillaSendMessage( ih, 2201, 0, 0 ); // SCI_CALLTIPCANCEL  2201
							IupSetStrAttributeId( ih, "ANNOTATIONTEXT", lineNumber, toStringz( showtype ) );
							IupSetIntId( ih, "ANNOTATIONSTYLE", lineNumber, 41 );
							IupSetAttribute( ih, "ANNOTATIONVISIBLE", "BOXED" );
							AutoComplete.clearShowTypeContent(); // Clear ShowType Clipboard
							return IUP_IGNORE;
						}
					}
				}
			}
			
			// TAB || SHIFT+TAB
			if( c == 9 || c == 268435465 ) AutoComplete.bSkipAutoComplete = true;
		}
		catch( Exception e )
		{
			debug IupMessage( "CScintilla_keyany_cb", toStringz( "CScintilla_keyany_cb Error\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ to!(string)( e.line ) ) );
		}
		
		return IUP_DEFAULT;
	}

	private int CScintilla_AUTOCSELECTION_cb( Ihandle *ih, int pos, char* text )
	{
		//Stdout( "CScintilla_AUTOCSELECTION_cb" ).newline;
		
		AutoComplete.bEnter = false;
		AutoComplete.bAutocompletionPressEnter = true;
		
		IupSetAttribute( ih, "AUTOCCANCEL", "YES" );
	
		string _text = fSTRz( text );
		
		auto colonPos = lastIndexOf( _text, "::" );
		if( colonPos > -1 ) _text = _text[0..colonPos].dup;
		_text = strip( _text );
		
		if( _text.length )
		{
			if( _text[$-1] == ')' )
			{
				auto _pos = indexOf( _text, "(" );
				if( _pos > -1 ) _text = _text[0.._pos].dup;
			}
			
			scope textCovert = new IupString( _text.dup );
			if( GLOBAL.parserSettings.toggleOverWrite == "ON" )
			{
				int tail = AutoComplete.getWholeWordTailPos( ih, pos );
				if( tail > pos )
				{
					IupScintillaSendMessage( ih, 2160, pos, tail ); // SCI_SETSEL = 2160
					IupSetStrAttribute( ih, "SELECTEDTEXT", textCovert.toCString );
				}
				else if( tail == pos )
				{
					IupScintillaSendMessage( ih, 2001, cast(size_t) textCovert.toDString.length, cast(ptrdiff_t) textCovert.toCString ); // SCI_ADDTEXT 2001
				}				
			}
			else
			{
				IupScintillaSendMessage( ih, 2026, pos, 0 ); //SCI_SETANCHOR = 2026
				
				textCovert = _text;
				if( IupGetAttribute( ih, "SELECTEDTEXT" ) == null )
				{	
					IupScintillaSendMessage( ih, 2001, cast(size_t) textCovert.toDString.length, cast(ptrdiff_t) textCovert.toCString ); // SCI_ADDTEXT 2001
				}
				else
					IupSetStrAttribute( ih, "SELECTEDTEXT", textCovert.toCString );			
			}
		}

		return IUP_DEFAULT;
	}

	private int CScintilla_action_cb( Ihandle *ih, int insert, int pos, int length, char* _text )
	{
		GLOBAL.scintillaActionInsert = insert;
		GLOBAL.scintillaActionLength = length;
		if( _text == null ) GLOBAL.scintillaActionText = ""; else GLOBAL.scintillaActionText = fSTRz( _text );
		
		/*
		if( AutoComplete.showListThread !is null ) return IUP_DEFAULT;

		AutoComplete.clearShowTypeContent(); // Clear ShowType Clipboard
		*/
		// Modified LineNumber Margin Width
		if( GLOBAL.editorSetting00.FixedLineMargin == "OFF" )
		{
			try
			{
				string	dText = fSTRz( _text );
				//auto	cSci = ScintillaAction.getActiveCScintilla();
				int		currentLineNum = cast(int) IupScintillaSendMessage( ih, 2166, pos, 0 ) + 1; //SCI_LINEFROMPOSITION = 2166,				

				if( insert == 1 )
				{
					/*
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
					*/
					if( dText.length > 2 )
					{
						auto count =  indexOf( dText, "\n" );
						if( count > -1 )
						{
							int textWidth = IupGetInt( ih, "STYLEFONTSIZE32" ) + 1;
							int lineCount = IupGetInt( ih, "LINECOUNT" );
							string lc = to!(string)( lineCount + 1 + count );
							IupSetInt( ih, "MARGINWIDTH0", ( cast(int) lc.length ) * textWidth );
						}
					}
					else
					{
						if( dText == "\n" || dText == "\r\n" )
						{
							if( GLOBAL.editorSetting00.LineMargin == "ON" )
							{
								// Set margin size
								int textWidth = IupGetInt( ih, "STYLEFONTSIZE32" ) + 1;
								int lineCount = IupGetInt( ih, "LINECOUNT" );
								string lc = to!(string)( lineCount + 1 );
								IupSetInt( ih, "MARGINWIDTH0", ( cast(int) lc.length ) * textWidth );
							}						
						}
					}
				}
				else
				{
					if( GLOBAL.editorSetting00.LineMargin == "ON" )
					{
						// Set margin size
						int			textWidth = IupGetInt( ih, "STYLEFONTSIZE32" ) + 1;
						ptrdiff_t	count;
						
						string selText = fSTRz( IupGetAttribute( ih, "SELECTEDTEXT" ) );
						
						if( selText.length )
						{
							count =  Algorithm.count( selText, "\n" );
						}
						else
						{
							string prevWord = fSTRz( IupGetAttributeId( ih, "CHAR", pos ) );
							if( prevWord == "\n" || prevWord == "\r" ) count = 1;
						}
						
						if( count > 0 )
						{
							int lineCount = IupGetInt( ih, "LINECOUNT" );
							string lc = to!(string)( lineCount - count );
							IupSetInt( ih, "MARGINWIDTH0", ( cast(int) lc.length ) * textWidth );
						}
					}
				}
			}
			catch( Exception e )
			{
				IupMessage( "", toStringz( "LiveParser lineNumberAdd() Error:\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ to!(string)( e.line ) ) );
			}
		}

		return IUP_DEFAULT;
	}
	
	
	private int CScintilla_VALUECHANGED_cb( Ihandle *ih )
	{
		if( AutoComplete.showListThread !is null ) return IUP_DEFAULT;

		AutoComplete.clearShowTypeContent(); // Clear ShowType Clipboard
		
		// If un-release the key, cancel
		//if( !GLOBAL.bKeyUp ) return IUP_DEFAULT;else GLOBAL.bKeyUp = false;
		if( GLOBAL.bKeyUp ) GLOBAL.bKeyUp = false;
		
		if( AutoComplete.bAutocompletionPressEnter ) return IUP_IGNORE;
		if( AutoComplete.bSkipAutoComplete )
		{
			if( fromStringz( IupGetAttribute( ih, "AUTOCACTIVE" ) ) == "YES" ) IupSetAttribute( ih, "AUTOCCANCEL", "YES" );
			//if( cast(int) IupScintillaSendMessage( ih, 2202, 0, 0 ) == 1 ) IupScintillaSendMessage( ih, 2201, 0, 0 ); //  SCI_CALLTIPCANCEL 2201 , SCI_CALLTIPACTIVE 2202
			return IUP_DEFAULT;
		}
		
		if( GLOBAL.compilerSettings.enableIncludeComplete != "ON" && GLOBAL.compilerSettings.enableKeywordComplete != "ON" && GLOBAL.parserSettings.autoCompletionTriggerWordCount < 1 ) return IUP_DEFAULT;
		
		bool bCheckString = true;
		version(FBIDE) if( GLOBAL.compilerSettings.enableIncludeComplete == "ON" ) bCheckString = false;

		int pos = ScintillaAction.getCurrentPos( ih );
				
		if( ScintillaAction.isComment( ih, pos, bCheckString ) )
			if( ScintillaAction.isComment( ih, pos - 1, bCheckString ) ) return IUP_DEFAULT;

		
		if( GLOBAL.scintillaActionLength > 2 ) return IUP_DEFAULT; // Prevent insert(paste) too big text to crash

		
		// Include Autocomplete
		if( AutoComplete.showListThread is null )
		{
			if( GLOBAL.parserSettings.autoCompletionTriggerWordCount > 0 )
			{
				if( GLOBAL.compilerSettings.enableIncludeComplete == "ON" )
				{
					bool bCheckDeclare;
					version(FBIDE)	bCheckDeclare = AutoComplete.checkIscludeDeclare( ih, pos );
					version(DIDE)	bCheckDeclare = AutoComplete.checkIsclmportDeclare( ih, pos );

					if( bCheckDeclare )
					{
						string alreadyInput = GLOBAL.scintillaActionText.dup;
						string list = AutoComplete.includeComplete( ih, pos, alreadyInput ); // After calling, alreadyInput be modified
						if( list.length )
						{
							scope _result = new IupString( list );
							ScintillaAction.directSendMessage( ih, 2100, cast(size_t) alreadyInput.length - 1, cast(ptrdiff_t) _result.toCString );
							
							return IUP_DEFAULT;
						}
					}
				}
				
				// Check Keyword Autocomplete
				if( GLOBAL.parserSettings.enableParser != "ON" || ( GLOBAL.parserSettings.enableParser == "ON" && GLOBAL.parserSettings.autoCompletionTriggerWordCount < 1 ) )
				{
					// Check Keyword Autocomplete
					if( GLOBAL.compilerSettings.enableKeywordComplete == "ON" )
					{
						int dummyHeadPos;
						string sKeyin = GLOBAL.scintillaActionText;
						
						switch( sKeyin )
						{
							case " ", "\n", "\t", "\r", ")":
								IupSetAttribute( ih, "AUTOCCANCEL", "YES" );
								break;
								
							default:
								string word = AutoComplete.getWholeWordReverse( ih, pos, dummyHeadPos );
								word = ( Algorithm.reverse( word.dup ) ~ sKeyin ).dup;
								
								if( word.length )
								{
									if( GLOBAL.parserSettings.autoCompletionTriggerWordCount > 0 )
									{
										if( word.length < GLOBAL.parserSettings.autoCompletionTriggerWordCount ) return IUP_DEFAULT;
									}
									else
									{
										if( word.length < 2 ) return IUP_DEFAULT;
									}
									
									string list;
									if( fromStringz( IupGetAttribute( ih, "AUTOCACTIVE" ) ) != "YES" ) list = AutoComplete.getKeywordContainerList( word );
									if( list.length )
									{
										scope _result = new IupString( list );
										ScintillaAction.directSendMessage( ih, 2100, cast(size_t) word.length - 1, cast(ptrdiff_t) _result.toCString );
									}
								}
						}
					}

					return IUP_DEFAULT;
				}
			}
		}
		
		if( GLOBAL.parserSettings.enableParser == "OFF" ) return IUP_DEFAULT;

		// Check CallTip
		if( GLOBAL.parserSettings.autoCompletionTriggerWordCount > 0 ) AutoComplete.updateCallTip( ih, pos, GLOBAL.scintillaActionText ); else AutoComplete.updateCallTipByDirectKey( ih, pos );

		// If GLOBAL.autoCompletionTriggerWordCount = 0, cancel
		if( GLOBAL.parserSettings.autoCompletionTriggerWordCount > 0 )
		{
			if( GLOBAL.scintillaActionInsert == 1 )
			{
				int dummyHeadPos;
				string text = GLOBAL.scintillaActionText;
				
				switch( text )
				{
					case " ", "\n", "\t", "\r", ")":
						IupSetAttribute( ih, "AUTOCCANCEL", "YES" );
						//bWithoutList = false;
						break;

					default:
						string	alreadyInput;
						bool	bDot, bOpenParen;

						if( text == ">" )
						{
							version(FBIDE)
							{
								if( pos > 0 )
								{
									if( fromStringz( IupGetAttributeId( ih, "CHAR", pos - 1 ) ) == "-" )
									{
										alreadyInput = Algorithm.reverse( AutoComplete.getWholeWordReverse( ih, pos - 1, dummyHeadPos ).dup );
										alreadyInput ~= "->";
										bDot = true;
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
						
						if( !alreadyInput.length )
						{
							alreadyInput = Algorithm.reverse( AutoComplete.getWholeWordReverse( ih, pos, dummyHeadPos ).dup );
							alreadyInput ~= text;
						}

						if( !bDot && !bOpenParen )
						{
							if( alreadyInput.length < GLOBAL.parserSettings.autoCompletionTriggerWordCount ) break;
							if( fromStringz( IupGetAttribute( ih, "AUTOCACTIVE" ) ) == "YES" ) break;
						}
						
						try
						{
							if( GLOBAL.parserSettings.toggleCompleteAtBackThread == "ON" )
							{
								AutoComplete.callAutocomplete( ih, pos, text, alreadyInput, false );
							}
							else
								AutoComplete.callAutocomplete( ih, pos, text, alreadyInput, true );
								
							return IUP_DEFAULT;
						}
						catch( Exception e )
						{
							IupMessage( "callAutocomplete() Error", toStringz( e.toString ~"\n" ~ e.file ~ " : " ~ to!(string)( e.line ) ) );
						}
							
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
			// BRACEMATCH
			if( GLOBAL.editorSetting00.BraceMatchHighlight == "ON" )
			{
				// IupSetInt( ih, "BRACEBADLIGHT", -1 );
				if( !actionManager.ScintillaAction.isComment( ih, pos ) )
				{
					int close = IupGetIntId( ih, "BRACEMATCH", pos - 1 );
					if( close > -1 )
					{
						IupScintillaSendMessage( ih, 2351, pos - 1, close ); // SCI_BRACEHIGHLIGHT 2351
					}
					else
					{
						close = IupGetIntId( ih, "BRACEMATCH", pos );
						if( close > -1 ) IupScintillaSendMessage( ih, 2351, pos, close ); else IupScintillaSendMessage( ih, 2351, -1, -1 );
					}
				}
				else
				{
					IupScintillaSendMessage( ih, 2351, -1, -1 ); // SCI_BRACEHIGHLIGHT 2351
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
						string insertEndText = AutoComplete.InsertEnd( ih, lin, pos );
						if( insertEndText.length )
						{
							if( insertEndText == "end if" )
							{
								string lineText = strip( fSTRz( IupGetAttributeId( ih, "LINE", lin - 1 ) ) ); // 0 BASE
								if( lineText.length > 3 )
								{
									if( Uni.toLower( strip( lineText[$-4..$] ) ) != "then" ) bAutoInsert = false;
								}
							}
							
							if( bAutoInsert )
							{
								string word;
								foreach( s; Array.split( insertEndText, " " ) )
								{
									if( s.length ) word ~= ( tools.convertKeyWordCase( GLOBAL.keywordCase, s ) ~ " " );
								}
								
								IupSetStrAttributeId( ih, "INSERT", -1, toStringz( strip( word ) ) );
								IupSetStrAttributeId( ih, "INSERT", -1, toStringz( "\n" ) );
								IupScintillaSendMessage( ih, 2126, lin + 1, lineInd ); // SCI_SETLINEINDENTATION = 2126
								IupScintillaSendMessage( ih, 2126, lin, lineInd + to!(int)( GLOBAL.editorSetting00.TabWidth ) ); // SCI_SETLINEINDENTATION = 2126
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
			IupMessage( "", toStringz( "CScintilla_caret_cb Error:\n" ~ e.toString ~"\n" ~ e.file ~ " : " ~ to!(string)( e.line ) ) );
		}
		return IUP_DEFAULT;
	}

	private int CScintilla_dropfiles_cb( Ihandle *ih, char* filename, int num, int x, int y )
	{
		string _fn = fSTRz( filename );
		version(Posix) _fn = tools.modifyLinuxDropFileName( _fn );
	
		if( std.file.isDir( _fn ) )
		{
			version(FBIDE)	_fn = _fn ~ "/FB.poseidon";
			version(DIDE)	_fn = _fn ~ "/D.poseidon";
		}

		if( std.file.exists( _fn ) )
		{
			bool bIsPrj;
			
			string _baseName = Path.baseName( _fn );
			version(FBIDE)	if( _baseName == "FB.poseidon" )	bIsPrj = true;
			version(DIDE)	if( _baseName == "D.poseidon" )		bIsPrj = true;		
			if( bIsPrj )
			{
				GLOBAL.projectTree.openProject( Path.dirName( _fn ) );
			}
			else
			{
				bool bSkip;
				string	documentTabs1_RASTERSIZE	= fSTRz( IupGetAttribute( GLOBAL.documentTabs, "RASTERSIZE" ) );				
				string	tabs1Pos					= fSTRz( IupGetAttribute( GLOBAL.documentTabs, "SCREENPOSITION" ) );
				string	screenPos					= fSTRz( IupGetGlobal( "CURSORPOS" ) );
				if( screenPos.length )
				{
					int	screenX, screenY, tabs1X, tabs1Y, RASTER1_W, RASTER1_H;
					
					if( tools.splitBySign( screenPos, "x", screenX, screenY ) )
						if( tools.splitBySign( tabs1Pos, ",", tabs1X, tabs1Y ) )
							if( tools.splitBySign( documentTabs1_RASTERSIZE, "x", RASTER1_W, RASTER1_H ) )
							{
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
				
				actionManager.ScintillaAction.openFile( _fn, true );
				actionManager.ScintillaAction.updateRecentFiles( _fn );
				if( IupGetInt( GLOBAL.dndDocumentZBox, "VALUEPOS" ) == 0 ) IupSetInt( GLOBAL.dndDocumentZBox, "VALUEPOS", 1 );
			}
		}
		
		return IUP_DEFAULT;
	}
	
	private int CScintilla_zoom_cb( Ihandle *ih, int zoomInPoints )
	{
		try
		{
			int textWidth = IupGetInt( ih, "STYLEFONTSIZE32" ) + 1;
			int lineCount = IupGetInt( ih, "LINECOUNT" );
			string lc = to!(string)( lineCount );
			IupSetInt( ih, "MARGINWIDTH0", ( 5 ) * ( textWidth + zoomInPoints ) );
			IupSetInt( ih, "MARGINWIDTH1", ( textWidth + zoomInPoints ) );
			IupSetInt( ih, "MARGINWIDTH2", ( textWidth + zoomInPoints ) );
		}
		catch( Exception e )
		{
			IupMessage( "", toStringz( "CScintilla_zoom_cb Error: " ~ e.toString ) );
		}
		
		return IUP_DEFAULT;
	}
	
	private void HighlightWord( Ihandle* ih, int pos )
	{
		IupSetFocus( ih );
		
		int wordStart = cast(int) IupScintillaSendMessage( ih, 2266, pos, 1 ); // SCI_WORDSTARTPOSITION 2266
		int wordEnd = cast(int) IupScintillaSendMessage( ih, 2267, pos, 1 );   // SCI_WORDENDPOSITION 2267
		/*
		struct TextRange{ int start; int end; char* text; }
		TextRange tr = { wordStart, wordEnd, ( new char[wordEnd-wordStart+1] ).ptr };
		IupScintillaSendMessage( ih, 2162, 0, cast(int) &tr ); // SCI_GETTEXTRANGE 2162
		char[] word = fromStringz( tr.text ).dup;
		delete tr.text;
		*/
		string word;
		for( int i = wordStart; i < wordEnd; ++ i )
			word ~= fromStringz( IupGetAttributeId( ih, "CHAR", i ) );

		if( word.length ) _HighlightWord( ih, word );
	}
	
	private void _HighlightWord( Ihandle* ih, string targetText )
	{
		int targetStart, TargetEnd;

		IupScintillaSendMessage( ih, 2500, 8, 0 ); // SCI_SETINDICATORCURRENT = 2500
		
		scope _t = new IupString( targetText );
		
		// Search Document
		IupSetAttribute( ih, "SEARCHFLAGS", "WHOLEWORD" );
		IupSetInt( ih, "TARGETSTART", 0 );
		IupSetInt( ih, "TARGETEND", -1 );
		int findPos = cast(int) IupScintillaSendMessage( ih, 2197, cast(size_t) targetText.length, cast(ptrdiff_t) _t.toCString ); // SCI_SEARCHINTARGET = 2197,
		
		while( findPos != -1 )
		{
			targetStart = IupGetInt( ih, "TARGETSTART" );
			TargetEnd = IupGetInt( ih, "TARGETEND" );
			IupScintillaSendMessage( ih, 2504, targetStart, TargetEnd - targetStart ); // SCI_INDICATORFILLRANGE =  2504
			IupSetInt( ih, "TARGETSTART", TargetEnd );
			IupSetInt( ih, "TARGETEND", -1 );
			findPos = cast(int) IupScintillaSendMessage( ih, 2197, cast(size_t) targetText.length, cast(ptrdiff_t) _t.toCString ); // SCI_SEARCHINTARGET = 2197,
		}
	}
}